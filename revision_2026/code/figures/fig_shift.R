###############################################################################
# fig_shift.R — 用户指定「N 个字符宽度 / 高度」级精确位移（图 3/4/5 修回专用）
#
# 严格按 figure-layout-qa §5「精确位移测量」流程：
#   ① 量测：从投稿 PDF 的矢量层/文本层反解 —— 面板矩形（pt）与数值标签 bbox（pt）
#        char_w = 标签 bbox 宽 / 可见字符数（去换行）
#        char_h = 单行文本 bbox 高
#      量测文件由 QC_user_adjust_round1/qc_shift_measure.py 生成；本脚本内**不含手填坐标**。
#   ② 换算：pt → 坐标轴尺度单位（pt_per_unit = 面板 pt / ggplot panel range）
#   ③ 施加：改写驱动该 geom_text 图层的映射列/映射常量（= 真实 artist）；其它图层零改动
#   ④ 复测：重绘后由 qc_shift_measure.py 从新 PDF 复测实测位移（字符数与 pt）
#
# 说明：panel_dims()（图件既有 QA 用）在设备外求 null 单位宽，实测系统性高估 panel 宽
#       （Fig3C 报 4.854 in，PDF 矢量层真值 4.018 in）。位移换算是绝对量，必须用真值，
#       故此处以 PDF 反解的面板矩形为准。
#
# 参数约定：pid = 面板编号（"Fig3C"/"Fig4A"/"Fig4B"/"Fig5A"/"Fig5B"）；tag = 量测阶段
#          （before = 位移前投稿 PDF 的量测，即换算基准）。
###############################################################################

SHIFT_DIR <- file.path(FIGDIR, "QC_user_adjust_round1")
SHIFT_OFFSETS <- file.path(SHIFT_DIR, "shift_offsets_pt.tsv")

.shift_read <- function(f) as.data.table(read.delim(f, check.names = FALSE, fileEncoding = "UTF-8"))

## ---- ① 量测读取：面板矩形 / 数值标签 bbox --------------------------------
shift_geom <- function(pid = NULL, tag = "before") {
  G <- .shift_read(file.path(SHIFT_DIR, sprintf("panel_geom_%s.tsv", tag)))
  if (!is.null(pid)) G <- G[G[["panel_id"]] %in% pid]
  G
}
shift_labels <- function(pid = NULL, tag = "before") {
  L <- .shift_read(file.path(SHIFT_DIR, sprintf("labels_%s.tsv", tag)))
  if (!is.null(pid)) L <- L[L[["panel_id"]] %in% pid]
  L
}
char_w_pt <- function(pid, idx = NULL, tag = "before") {
  L <- shift_labels(pid, tag)
  if (!is.null(idx)) L <- L[L$idx %in% idx]
  stopifnot(nrow(L) >= 1)
  stopifnot(length(unique(L$char_w_pt)) == 1)     # 同面板目标标签字符宽须一致
  L$char_w_pt[1]
}
char_h_pt <- function(pid, tag = "before") {
  L <- shift_labels(pid, tag)
  stopifnot(nrow(L) >= 1)
  lh <- unique(round(L$h_pt, 2))
  stopifnot(length(lh) == 1)                      # 同面板目标标签行高须一致
  lh[1]
}
target_text <- function(pid, idx, tag = "before") {
  L <- shift_labels(pid, tag)
  L$text[match(idx, L$idx)]
}

## ---- ② 换算：pt ↔ 坐标轴尺度单位 ----------------------------------------
pt_per_unit <- function(p, pid, tag = "before") {
  g <- shift_geom(pid, tag)
  stopifnot(nrow(g) == 1)
  pp <- ggplot_build(p)$layout$panel_params[[1]]
  c(x = g$w_pt / diff(pp$x.range), y = g$h_pt / diff(pp$y.range))
}

## ---- 定位承载"数值标签"的 geom_text 图层 ---------------------------------
.find_text_layer <- function(p, x_col = NULL, const_x = NULL) {
  for (i in seq_along(p$layers)) {
    m <- p$layers[[i]]$mapping
    if (is.null(m) || is.null(m$x)) next
    xl <- tryCatch(rlang::as_label(m$x), error = function(e) NA_character_)
    if (!is.null(x_col) && identical(xl, x_col)) return(i)
    if (!is.null(const_x) && !is.na(suppressWarnings(as.numeric(xl))) &&
        abs(as.numeric(xl) - const_x) < 1e-9) return(i)
  }
  NA_integer_
}

## ---- 换算基准自检：解析预测值 vs PDF 实测值 ------------------------------
##   hjust=0 标签 → 预测 x0 vs 实测 bbox 左缘；vjust=0.5 → 预测 y 中心 vs 实测 bbox 中心
shift_model_check <- function(p, pid, x_col = NULL, const_x = NULL, logx = TRUE,
                              tag = "before") {
  g <- shift_geom(pid, tag); L <- shift_labels(pid, tag)
  pp <- ggplot_build(p)$layout$panel_params[[1]]
  i <- .find_text_layer(p, x_col, const_x)
  stopifnot(!is.na(i))
  if (!is.null(x_col)) stopifnot(nrow(L) == length(p$data[[x_col]]))
  xv <- if (!is.null(x_col)) p$data[[x_col]] else rep(const_x, nrow(L))
  xv <- xv[seq_len(nrow(L))]
  xr <- pp$x.range; yr <- pp$y.range
  tt <- if (logx) log10(xv) else xv
  pred_x0 <- g$x0 + (tt - xr[1]) / diff(xr) * g$w_pt
  yv <- if ("y" %in% names(p$data)) p$data$y[seq_len(nrow(L))] else rep(NA_real_, nrow(L))
  pred_yc <- g$y0 + (yr[2] - yv) / diff(yr) * g$h_pt
  meas_yc <- L$y0 + L$h_pt / 2
  res <- data.table(pid = pid, idx = L$idx, text = L$text,
                    x_pred_pt = round(pred_x0, 2), x_meas_pt = round(L$x0, 2),
                    x_resid_pt = round(pred_x0 - L$x0, 2),
                    yc_pred_pt = round(pred_yc, 2), yc_meas_pt = round(meas_yc, 2),
                    yc_resid_pt = round(pred_yc - meas_yc, 2))
  cat(sprintf("  [换算自检] %s：x 残差 %.2f…%.2f pt；y 中心残差 %.2f…%.2f pt（判据 < 0.5 pt）\n",
              pid, min(res$x_resid_pt), max(res$x_resid_pt),
              min(res$yc_resid_pt, na.rm = TRUE), max(res$yc_resid_pt, na.rm = TRUE)))
  fwrite(res, file.path(SHIFT_DIR, sprintf("model_check_%s_%s.tsv", pid, tag)), sep = "\t")
  res
}

## ---- ③ 施加位移 ----------------------------------------------------------
.log_shift <- function(pid, idx, text, axis, chars, char_pt, dx_pt, dy_pt) {
  row <- data.table(panel_id = pid, idx = idx, text = text, axis = axis,
                    chars = chars, char_unit_pt = round(char_pt, 4),
                    dx_pt = round(dx_pt, 4), dy_pt = round(dy_pt, 4))
  hdr <- !file.exists(SHIFT_OFFSETS)
  fwrite(row, SHIFT_OFFSETS, sep = "\t", append = !hdr, col.names = hdr)
  invisible(row)
}

## 横向位移：改写驱动 x 映射的列
shift_text_x <- function(p, pid, col = "tx_pos", rows, d_chars, logx = TRUE, tag = "before") {
  i <- .find_text_layer(p, x_col = col)
  stopifnot(!is.na(i))
  ppu <- pt_per_unit(p, pid, tag)[["x"]]
  cw  <- char_w_pt(pid, rows, tag)
  d_tr <- d_chars * cw / ppu                      # 尺度单位偏移
  v <- p$data[[col]]
  p$data[[col]][rows] <- if (logx) v[rows] * 10^(d_tr) else v[rows] + d_tr
  cat(sprintf("  [位移] %s 行 %s：%s\n    = %g 字符宽 × %.4f pt/字符 = %.3f pt（%.5f %s）\n",
              pid, paste(rows, collapse = ","),
              paste(target_text(pid, rows, tag), collapse = " / "),
              d_chars, cw, d_chars * cw, d_tr, if (logx) "对数十年，x 对数轴" else "数据单位，x 线性轴"))
  for (k in seq_along(rows))
    .log_shift(pid, rows[k], target_text(pid, rows[k], tag), "x", d_chars, cw, d_chars * cw, 0)
  p
}

## 横向位移：改写映射里的常数 x（Fig5A 用 aes(x = 1.72)；该图有"未校正/校正"两个文本图层，
## 必须对**全部**匹配该常数的图层施加，否则只移一半，"整体"位移不成立）
shift_text_const_x <- function(p, pid, const_x, d_chars, logx = TRUE, tag = "before") {
  idx <- integer(0)
  for (i in seq_along(p$layers)) {
    m <- p$layers[[i]]$mapping
    if (is.null(m) || is.null(m$x)) next
    xl <- tryCatch(rlang::as_label(m$x), error = function(e) NA_character_)
    if (!is.na(suppressWarnings(as.numeric(xl))) && abs(as.numeric(xl) - const_x) < 1e-9) idx <- c(idx, i)
  }
  stopifnot(length(idx) >= 1)
  ppu <- pt_per_unit(p, pid, tag)[["x"]]
  cw  <- char_w_pt(pid, tag = tag)
  d_tr <- d_chars * cw / ppu
  newx <- if (logx) const_x * 10^(d_tr) else const_x + d_tr
  L <- shift_labels(pid, tag)
  nlab <- 0
  for (i in idx) {
    p$layers[[i]]$mapping$x <- newx
    tt <- as.character(p$layers[[i]]$data$ann %||% character(0))
    nlab <- nlab + length(tt)
    for (t in tt) {
      k <- which(L$text == t)
      .log_shift(pid, if (length(k)) L$idx[k[1]] else NA_integer_, t, "x", d_chars, cw, d_chars * cw, 0)
    }
  }
  cat(sprintf("  [位移] %s 共 %d 个含该常数 x 的文本图层、%d 个数值标签全部平移：常数 x %.4f → %.4f\n    = %g 字符宽 × %.4f pt/字符 = %.3f pt（%.5f %s）\n",
              pid, length(idx), nlab, const_x, newx, d_chars, cw, d_chars * cw, d_tr,
              if (logx) "对数十年，x 对数轴" else "数据单位，x 线性轴"))
  p
}

## 纵向位移：仅数值标签图层上移（新增 y_ann 列并改该层 y 映射；误差棒/数据点不动）
shift_text_y <- function(p, pid, rows, d_chars, tag = "before") {
  i <- .find_text_layer(p, x_col = "tx_pos")
  stopifnot(!is.na(i))
  ppu <- pt_per_unit(p, pid, tag)[["y"]]
  ch  <- char_h_pt(pid, tag)
  d_tr <- d_chars * ch / ppu                      # y 为线性尺度 → 直接相加
  yy <- p$data$y
  yy[rows] <- yy[rows] + d_tr
  p$data$y_ann <- yy
  p$layers[[i]]$mapping$y <- aes(y = y_ann)$y
  cat(sprintf("  [位移] %s 行 %s（%d 个数值标签）：向上 %g 字符高 × %.4f pt/字符 = %.3f pt（%.5f 数据单位）\n",
              pid, paste(rows, collapse = ","), length(rows), d_chars, ch, d_chars * ch, d_tr))
  for (k in seq_along(rows))
    .log_shift(pid, rows[k], target_text(pid, rows[k], tag), "y", d_chars, ch, 0, d_chars * ch)
  p
}
