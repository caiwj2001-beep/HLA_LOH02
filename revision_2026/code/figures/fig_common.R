###############################################################################
# fig_common.R — V3 主图公共工具（主题 / 调色板 / Wilson CI / 保存 / 程序化 QA）
# 依赖：fig_helpers.R（项目根），见 PINNED_PACK §3 绘图规范
###############################################################################
suppressPackageStartupMessages({
  library(ggplot2); library(data.table); library(grid); library(gridExtra)
  library(patchwork); library(ggrepel); library(scales)
})

ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
FH <- c(file.path(ROOT, "fig_helpers.R"),
        "C:/Users/Administrator/科研文件/fig_helpers.R",
        "C:/Users/Administrator/科研文件/SMARCA4铂类敏感耐药矛盾解析/results/fig_helpers.R")
FH <- FH[file.exists(FH)][1]
stopifnot(!is.na(FH))
cat("using fig_helpers.R:", FH, "\n")
suppressPackageStartupMessages(source(FH))
FIGDIR <- file.path(ROOT, "iscience投稿版本/V3/02_figures")
V2     <- file.path(ROOT, "iscience投稿版本/V2")
NEO    <- file.path(ROOT, "neoantigen/output/stats/netmhcpan_full")
IMD    <- file.path(FIGDIR, "intermediate")
dir.create(IMD, showWarnings = FALSE, recursive = TRUE)

PAL <- c(navy = "#1F3B73", teal = "#2A9D8F", gold = "#E9A100",
         red = "#C0392B", grey = "#9AA0A6", lblue = "#5B8DB8",
         purple = "#6A4C93", dgreen = "#3D6B35")

theme_pub <- function(base = 7) {
  theme_bw(base_size = base, base_family = "sans") +
    theme(
      panel.background   = element_rect(fill = "white", colour = NA),
      plot.background    = element_rect(fill = "white", colour = NA),
      legend.background  = element_rect(fill = "white", colour = NA),
      legend.key         = element_blank(),
      panel.grid.minor   = element_blank(),
      panel.grid.major   = element_line(colour = "grey92", linewidth = 0.25),
      panel.border       = element_rect(colour = "grey25", linewidth = 0.4, fill = NA),
      axis.text          = element_text(colour = "grey15", size = base - 0.5),
      axis.title         = element_text(colour = "grey10", size = base),
      axis.ticks         = element_line(colour = "grey25", linewidth = 0.3),
      strip.background   = element_rect(fill = "grey94", colour = "grey25", linewidth = 0.3),
      strip.text         = element_text(size = base - 0.3, colour = "grey10"),
      plot.title         = element_text(size = base + 0.7, face = "bold", colour = "grey5"),
      plot.subtitle      = element_text(size = base - 0.6, colour = "grey35"),
      plot.caption       = element_text(size = base - 1.4, colour = "grey35", hjust = 0),
      plot.margin        = margin(5, 14, 5, 5)
    )
}

# Wilson 95% CI（比例）
wilson <- function(k, n, z = qnorm(0.975)) {
  p <- k / n
  d <- 1 + z^2 / n
  ctr <- (p + z^2 / (2 * n)) / d
  hw  <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / d
  data.table(freq = p, lo = pmax(0, ctr - hw), hi = pmin(1, ctr + hw))
}

fmt_p <- function(p) ifelse(is.na(p), "NA",
                     ifelse(p < 1e-4, sprintf("%.1e", p), sprintf("%.3f", p)))
fmt_or <- function(est, lo, hi, d = 2)
  sprintf(paste0("%.", d, "f (%.", d, "f\u2013%.", d, "f)"), est, lo, hi)

# ---- 白底 TIFF(300dpi, ragg) + PDF 双导出 ----------------------------------
#  说明：patchwork 组装时各子图的 plot.margin 不能保证画布外缘留白，
#        因此统一在 save 前用 wrap_elements 再包一层 16pt 外边距，
#        保证内容不触画布边缘（栅格级裁切检测要求 0 非白边缘像素）。
save_pub2 <- function(p, name, w_in, h_in, dpi = 300, pad_frac = 0.03, margin_in = 0.10,
                      max_iter = 5) {
  tif <- file.path(FIGDIR, paste0(name, ".tiff"))
  pdf <- file.path(FIGDIR, paste0(name, ".pdf"))
  gt <- tryCatch(patchwork::patchworkGrob(p), error = function(e) ggplotGrob(p))
  W <- round(w_in * dpi); H <- round(h_in * dpi)
  m <- round(margin_in * dpi)
  draw_vp <- function(vw, vh, cx = 0.5, cy = 0.5) {
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(x = unit(cx, "npc"), y = unit(cy, "npc"),
                                      width = unit(vw, "npc"), height = unit(vh, "npc")))
    grid::grid.draw(gt)
    grid::popViewport()
  }
  bbox_of <- function(f) {
    a <- magick::image_data(magick::image_read(f))
    g <- matrix(as.integer(a[1, , ]), nrow = dim(a)[2], ncol = dim(a)[3])
    d <- g < 250
    xs <- which(rowSums(d) > 0); ys <- which(colSums(d) > 0)
    if (!length(xs)) return(c(0, W - 1, 0, H - 1))
    c(min(xs), max(xs), min(ys), max(ys))
  }
  vw <- 1 - 2 * pad_frac; vh <- 1 - 2 * pad_frac
  cx <- 0.5; cy <- 0.5
  tmp <- file.path(tempdir(), paste0(name, "_probe.tiff"))
  for (it in seq_len(max_iter)) {
    ragg::agg_tiff(tmp, width = w_in, height = h_in, units = "in", res = dpi,
                   background = "white", compression = "none")
    draw_vp(vw, vh, cx, cy); dev.off()
    bb <- bbox_of(tmp)
    ok_x <- (bb[1] >= m) && (bb[2] <= W - 1 - m)
    ok_y <- (bb[3] >= m) && (bb[4] <= H - 1 - m)
    if (ok_x && ok_y) break
    # 先等比缩小到目标框内（留 margin），再按 bbox 重新居中
    span_x <- bb[2] - bb[1] + 1; span_y <- bb[4] - bb[3] + 1
    s <- min((W - 2 * m) / span_x, (H - 2 * m) / span_y, 1)
    vw <- vw * s; vh <- vh * s
    # 图像 y 轴向下的（行号增大=向下），而 npc y 向上（增大=向上），故 y 分量符号相反
    cx <- cx - ((bb[1] + bb[2]) / 2 - (W - 1) / 2) / W * s
    cy <- cy + ((bb[3] + bb[4]) / 2 - (H - 1) / 2) / H * s
    cx <- min(max(cx, 0.2), 0.8); cy <- min(max(cy, 0.2), 0.8)
  }
  ragg::agg_tiff(tif, width = w_in, height = h_in, units = "in", res = dpi,
                 background = "white", compression = "lzw")
  draw_vp(vw, vh, cx, cy); dev.off()
  cairo_pdf(pdf, width = w_in, height = h_in, bg = "white"); draw_vp(vw, vh, cx, cy); dev.off()
  bb <- bbox_of(tif)
  edge <- tryCatch({
    a <- magick::image_data(magick::image_read(tif))
    g <- matrix(as.integer(a[1, , ]), nrow = dim(a)[2], ncol = dim(a)[3]); d <- g < 250
    sum(d[1:3, ]) + sum(d[(W - 2):W, ]) + sum(d[, 1:3]) + sum(d[, (H - 2):H])
  }, error = function(e) NA)
  cat(sprintf("  saved: %s / %s | viewport %.3fx%.3f | content bbox x %d-%d y %d-%d | edge nonwhite=%d\n",
              basename(tif), basename(pdf), vw, vh, bb[1], bb[2], bb[3], bb[4], edge))
  invisible(c(tif, pdf))
}

# ---- panel 物理尺寸（英寸）解析：与渲染像素真值一致（误差 < 0.01 in）-------
panel_dims <- function(p, fig_w, fig_h) {
  gt <- ggplotGrob(p)
  cv <- function(u, kind) tryCatch(
    if (kind == "w") convertWidth(u, "in", valueOnly = TRUE) else convertHeight(u, "in", valueOnly = TRUE),
    error = function(e) NA_real_)
  pdf(NULL, width = fig_w, height = fig_h)
  wd <- sapply(gt$widths, cv, "w"); ht <- sapply(gt$heights, cv, "h")
  dev.off()
  c(panel_w_in = fig_w - sum(wd, na.rm = TRUE), panel_h_in = fig_h - sum(ht, na.rm = TRUE))
}

# ---- 程序化 QA：面板内文字-文字重叠 / 文字越框 / 离散轴标签挤压 ------------
# 返回 data.table（每个面板若干行）；overlap_pairs>0 或 clip_n>0 即不合格
qa_panel <- function(p, fig_w, fig_h, tag, base = 7, fs = NULL) {
  if (is.null(fs)) fs <- base
  pd <- panel_dims(p, fig_w, fig_h); pw <- pd[["panel_w_in"]]; ph <- pd[["panel_h_in"]]
  gb <- ggplot_build(p)
  flipped <- inherits(p$coordinates, "CoordFlip")
  out <- list(); k <- 0
  for (pi in seq_along(gb$layout$panel_params)) {
    pp <- gb$layout$panel_params[[pi]]
    xr0 <- if (!is.null(pp$x.range)) pp$x.range else c(0, 1)
    yr0 <- if (!is.null(pp$y.range)) pp$y.range else c(0, 1)
    # coord_flip 下 panel_params 的 x/y.range 已互换，而 layer data 仍是原坐标
    xr <- if (flipped) yr0 else xr0
    yr <- if (flipped) xr0 else yr0
    pwx <- if (flipped) ph else pw
    phx <- if (flipped) pw else ph
    for (li in seq_along(p$layers)) {
      geo <- class(p$layers[[li]]$geom)[1]
      if (!geo %in% c("GeomText", "GeomLabel", "GeomTextRepel")) next
      d <- tryCatch(gb$data[[li]], error = function(e) NULL)
      if (is.null(d) || !nrow(d)) next
      if (!is.null(d$PANEL) && any(d$PANEL != pi)) d <- d[d$PANEL == pi, ]
      if (!nrow(d) || !all(c("x", "y") %in% names(d))) next
      lab <- if (!is.null(d$label)) as.character(d$label) else rep("", nrow(d))
      hj <- if (!is.null(d$hjust)) as.numeric(d$hjust) else rep(0.5, nrow(d))
      vj <- if (!is.null(d$vjust)) as.numeric(d$vjust) else rep(0.5, nrow(d))
      m <- measure_text(lab, fontsize = fs)
      nl <- vapply(strsplit(lab, "\n", fixed = TRUE), length, 1L)
      for (r in seq_len(nrow(d))) {
        # 宽度用 grid grobWidth（含字侧承托）；高度用真实行高 1.15×字号
        # （grobHeight 返回字体度量框 ≈1.7×字号，对行距判定过于保守）
        W <- m$w[r] / pwx; H <- (nl[r] * fs * 1.15 / 72) / phx
        nx <- (d$x[r] - xr[1]) / diff(xr); ny <- (d$y[r] - yr[1]) / diff(yr)
        # coord_flip：data-x 方向在屏幕上是竖直的，width/height 与 hjust/vjust 需互换
        ext_x <- if (flipped) H else W; ext_y <- if (flipped) W else H
        hx    <- if (flipped) vj[r] else hj[r]; vy <- if (flipped) hj[r] else vj[r]
        x0 <- nx - hx * ext_x; x1 <- nx + (1 - hx) * ext_x
        y0 <- ny - (1 - vy) * ext_y; y1 <- ny + vy * ext_y
        out[[length(out) + 1]] <- data.table(
          tag = tag, panel = pi, layer = li, row = r, label = lab[r],
          x = nx, y = ny, x0 = x0, x1 = x1, y0 = y0, y1 = y1, hw = W / 2, hh = H / 2,
          clip = (x0 < -0.002) | (x1 > 1.002) | (y0 < -0.002) | (y1 > 1.002))
      }
    }
    # 离散轴标签挤压：刻度间距 vs 标签尺寸（考虑旋转角）
    bp <- tryCatch(pp$y$get_breaks(), error = function(e) NULL)
    bx <- tryCatch(pp$x$get_breaks(), error = function(e) NULL)
    ang_x <- tryCatch({ a <- p$theme$axis.text.x$angle; if (is.null(a)) 0 else if (inherits(a, "waiver")) 0 else as.numeric(a) }, error = function(e) 0)
    ang_y <- tryCatch({ a <- p$theme$axis.text.y$angle; if (is.null(a)) 0 else if (inherits(a, "waiver")) 0 else as.numeric(a) }, error = function(e) 0)
    if (length(ang_x) != 1 || is.na(ang_x)) ang_x <- 0
    if (length(ang_y) != 1 || is.na(ang_y)) ang_y <- 0
    chk <- function(vals, labs, span_in, axis, ang = 0) {
      if (is.null(vals) || length(vals) < 2 || any(is.na(vals))) return(NULL)
      sp <- span_in / (length(vals) - 1)
      m <- measure_text(labs, fontsize = base - 0.5)
      # 旋转 90 度时，"占位宽度" 由文本高度决定；行高按 1.15×字号
      lh <- 1.15 * (base - 0.5) / 72
      used <- if (axis == "y") if (abs(ang) > 45) max(m$w) else lh
              else if (abs(ang) > 45) lh else max(m$w)
      gap <- sp - used
      data.table(tag = tag, panel = pi, axis = axis, n_lab = length(vals),
                 spacing_in = round(sp, 4), max_label_in = round(used, 4),
                 gap_in = round(gap, 4))
    }
    if (!is.null(bp)) {
      labs <- tryCatch(pp$y$get_labels(), error = function(e) NULL)
      r <- chk(bp, labs, if (flipped) pw else ph, "y", ang_y); if (!is.null(r)) out[[length(out) + 1]] <- r
    }
    if (!is.null(bx)) {
      labs <- tryCatch(pp$x$get_labels(), error = function(e) NULL)
      r <- chk(bx, labs, if (flipped) ph else pw, "x", ang_x); if (!is.null(r)) out[[length(out) + 1]] <- r
    }
  }
  dt <- rbindlist(out, fill = TRUE)
  # ---- 标题/副标题/图注宽度检查（防止文本溢出画布被裁切）----
  tt <- c(title = p$labels$title, subtitle = p$labels$subtitle, caption = p$labels$caption)
  tt <- tt[!vapply(tt, is.null, TRUE)]
  tsizes <- c(title = base + 0.7, subtitle = base - 0.6, caption = base - 1.4)
  hdr <- rbindlist(lapply(names(tt), function(k) {
    txt <- as.character(tt[[k]])
    if (!nzchar(txt)) return(NULL)
    lines <- unlist(strsplit(txt, "\n", fixed = TRUE))
    m <- measure_text(lines, fontsize = tsizes[k])
    data.table(tag = tag, kind = k, max_line_in = round(max(m$w), 3),
               avail_in = round(fig_w - 0.22, 3),
               overflow = max(m$w) > (fig_w - 0.22),
               longest = substr(lines[which.max(m$w)], 1, 60))
  }))
  attr(dt, "header_check") <- hdr
  if (nrow(dt) && "label" %in% names(dt)) {
    tx <- dt[!is.na(label) & !is.na(x0) & !is.na(x)]
    pairs <- 0; det <- list()
    if (nrow(tx) > 1) for (i in 1:(nrow(tx) - 1)) for (j in (i + 1):nrow(tx)) {
      if (tx$panel[i] != tx$panel[j]) next
      ox <- min(tx$x1[i], tx$x1[j]) - max(tx$x0[i], tx$x0[j])
      oy <- min(tx$y1[i], tx$y1[j]) - max(tx$y0[i], tx$y0[j])
      if (ox > 0.004 && oy > 0.004) {
        pairs <- pairs + 1
        det[[length(det) + 1]] <- data.table(tag = tag, panel = tx$panel[i],
          a = tx$label[i], b = tx$label[j], overlap_npc = round(min(ox, oy), 4))
      }
    }
    attr(dt, "overlap_pairs") <- pairs
    attr(dt, "overlap_detail") <- if (length(det)) rbindlist(det) else NULL
    attr(dt, "clip_n") <- sum(tx$clip)
    attr(dt, "squeeze_n") <- sum(dt$gap_in < 0, na.rm = TRUE)
  } else {
    attr(dt, "overlap_pairs") <- 0L; attr(dt, "clip_n") <- 0L
    attr(dt, "squeeze_n") <- 0L; attr(dt, "overlap_detail") <- NULL
  }
  dt
}

# 全局 QA 行累积
QA_CSV <- file.path(IMD, "qa_rows.csv")
qa_emit <- function(fig, p, fig_w, fig_h, tag = NULL, fs = NULL) {
  dt <- qa_panel(p, fig_w, fig_h, tag %||% fig, fs = fs)
  row <- data.table(figure = fig, tag = tag %||% fig,
                    text_n = if ("label" %in% names(dt)) sum(!is.na(dt$label)) else 0L,
                    overlap_pairs = attr(dt, "overlap_pairs"),
                    clip_n = attr(dt, "clip_n"),
                    squeeze_n = attr(dt, "squeeze_n"),
                    panel_w_in = round(panel_dims(p, fig_w, fig_h)[["panel_w_in"]], 3),
                    panel_h_in = round(panel_dims(p, fig_w, fig_h)[["panel_h_in"]], 3))
  fwrite(row, QA_CSV, sep = ",", append = file.exists(QA_CSV), col.names = !file.exists(QA_CSV))
  od <- attr(dt, "overlap_detail")
  if (!is.null(od)) fwrite(od, file.path(IMD, "qa_overlap_detail.csv"), sep = ",", append = TRUE)
  if ("label" %in% names(dt)) {
    cl <- dt[!is.na(label) & !is.na(clip) & clip == TRUE, .(figure = fig, tag = tag, label, x0, x1, y0, y1)]
    if (nrow(cl)) fwrite(cl, file.path(IMD, "qa_clip_detail.csv"), sep = ",", append = TRUE)
  }
  hc <- attr(dt, "header_check")
  if (!is.null(hc)) {
    hc[, figure := fig]
    fwrite(hc, file.path(IMD, "qa_header_check.csv"), sep = ",", append = TRUE)
  }
  print(row)
  invisible(row)
}

# ---------------------------------------------------------------------------
# 自动折行：把标题/副标题/图注按可用宽度折行，避免文本超出画布被裁切
#   宽度用 measure_text（grid grobWidth）量测，并乘 1.12 保险系数
#   （实测渲染宽度比 grobWidth 大 ~10–14%）
# ---------------------------------------------------------------------------
wrap_txt <- function(txt, avail_in, fs, ink_factor = 1.12) {
  if (is.null(txt) || length(txt) == 0) return(txt)
  txt <- as.character(txt)
  if (!nzchar(txt)) return(txt)
  if (grepl("\n", txt, fixed = TRUE)) {
    parts <- unlist(strsplit(txt, "\n", fixed = TRUE))
    return(paste(vapply(parts, function(x) wrap_txt(x, avail_in, fs, ink_factor), character(1)),
                 collapse = "\n"))
  }
  words <- unlist(strsplit(txt, " ", fixed = TRUE))
  words <- words[nzchar(words)]
  if (!length(words)) return(txt)
  lim <- avail_in / ink_factor
  out <- character(0); cur <- ""
  for (w in words) {
    cand <- if (nzchar(cur)) paste(cur, w) else w
    if (measure_text(cand, fontsize = fs)$w > lim && nzchar(cur)) {
      out <- c(out, cur); cur <- w
    } else cur <- cand
  }
  paste(c(out, cur), collapse = "\n")
}

wrap_headers <- function(p, fig_w_in, base = 7, pad_in = 0.60, ink_factor = 1.25) {
  avail <- fig_w_in - pad_in
  if (!is.null(p$labels$title))
    p$labels$title <- wrap_txt(p$labels$title, avail, base + 0.7, ink_factor)
  if (!is.null(p$labels$subtitle))
    p$labels$subtitle <- wrap_txt(p$labels$subtitle, avail, base - 0.6, ink_factor)
  if (!is.null(p$labels$caption))
    p$labels$caption <- wrap_txt(p$labels$caption, avail, base - 1.4, ink_factor)
  p
}

# 栅格级裁切检测：最终 TIFF 四周 3px 必须全白（内容触边=被裁切）
qa_raster <- function(tif, border_px = 3) {
  img <- magick::image_read(tif); inf <- magick::image_info(img)
  arr <- magick::image_data(img)
  W <- dim(arr)[2]; H <- dim(arr)[3]
  g <- matrix(as.integer(arr[1, , ]), nrow = W, ncol = H)
  edge <- c(g[1:border_px, , drop = FALSE], g[(W - border_px + 1):W, , drop = FALSE],
            g[, 1:border_px], g[, (H - border_px + 1):H])
  edge <- unlist(edge)
  data.table(file = basename(tif), px_w = inf$width, px_h = inf$height,
             dpi = inf$density, nonwhite_edge_px = sum(edge < 250),
             white_bg = mean(g > 250) > 0.5)
}

# ---------------------------------------------------------------------------
# 森林图通用面板：dt = data.frame(label, est, lo, hi, P, group, is_null)
#   右侧注释列通过 hjust=0 的文本实现，位置由 xlim 推导（非手填坐标）
# ---------------------------------------------------------------------------
forest_panel <- function(dt, xlim, title, xlab = NULL, vline = 1, logx = TRUE,
                         col_map = NULL, txt_cex = 5.6, lab_size = 6.2,
                         extra_note = NULL, note_y_frac = 0.97, ann_shift_t = 0) {
  ## [Round1 扩展] ann_shift_t：右侧数值标注列（ann）在**变换后坐标轴**上的整体位移
  ##   logx=TRUE 时单位为 log10（施加为 tx_pos × 10^ann_shift_t）；否则为 data 单位。
  ##   位移量由调用方按「实测字符宽 × 要求字符数 / 实测 panel 宽 × 轴跨度」算出（非手填）。
  dt <- as.data.table(dt)
  dt[, y := rev(seq_len(.N))]
  dt[, ann := sprintf("%.3f (%.3f\u2013%.3f)", est, lo, hi)]
  dt[, pann := ifelse(is.na(P), "", ifelse(P < 1e-4, sprintf("%.1e", P), sprintf("%.3f", P)))]
  dt[, pcol := ifelse(is.na(P), "grey60", ifelse(P < 0.05, "grey5", "grey50"))]
  rx <- xlim[2]
  if (logx) {
    dt[, tx_pos := exp(log(xlim[2]) - 0.58 * (log(xlim[2]) - log(xlim[1])))]
    dt[, tp_pos := exp(log(xlim[2]) - 0.01 * (log(xlim[2]) - log(xlim[1])))]
    if (ann_shift_t != 0) dt[, tx_pos := tx_pos * 10^ann_shift_t]
  } else {
    dt[, tx_pos := xlim[2] - 0.58 * diff(xlim)]
    dt[, tp_pos := xlim[2] - 0.01 * diff(xlim)]
    if (ann_shift_t != 0) dt[, tx_pos := tx_pos + ann_shift_t]
  }
  g <- ggplot(dt, aes(y = y)) +
    geom_vline(xintercept = vline, linetype = "dashed", colour = "grey45", linewidth = 0.3) +
    geom_errorbarh(aes(xmin = lo, xmax = hi, colour = group), height = 0.18, linewidth = 0.45) +
    geom_point(aes(x = est, colour = group, shape = is_null), size = 1.5, fill = "white") +
    geom_text(aes(x = tx_pos, label = ann), hjust = 0, size = txt_cex / 2.845, colour = "grey10") +
    geom_text(aes(x = tp_pos, label = pann), hjust = 1, size = txt_cex / 2.845, colour = dt$pcol) +
    scale_y_continuous(breaks = dt$y, labels = dt$label, limits = c(0.4, max(dt$y) + 0.6)) +
    labs(title = title, x = xlab, y = NULL) +
    theme_pub() +
    theme(axis.text.y = element_text(size = lab_size), legend.position = "none",
          panel.grid.major.y = element_blank())
  if (logx) g <- g + scale_x_log10(limits = xlim, breaks = pretty(xlim))
  else g <- g + scale_x_continuous(limits = xlim)
  if (!is.null(col_map)) g <- g + scale_colour_manual(values = col_map, na.value = "grey40")
  else g <- g + scale_colour_manual(values = c(navy, teal, gold, red, grey))
  g + scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 24))
}

# ---------------------------------------------------------------------------
# 用 fig_helpers::flow_layout 生成注释框（位置由布局引擎计算，非手填）
#   返回 list(rect = geom_rect layer, text = geom_text layer, layout = data.table)
#   注意：flow_layout 坐标为 0-100 归一化，映射到数据坐标需给出 xlim/ylim
# ---------------------------------------------------------------------------
note_box <- function(lines, plot_w_in, plot_h_in, xlim, ylim, x_center_norm = 50,
                     y_top_norm = 95, fontsize = 5.6, spacing_in = 0.06,
                     max_chars_per_line = NULL, box_w_in = NULL, box_h_in = NULL,
                     fix_fontsize = FALSE, ink_factor = 1.0) {
  ## [Round1 扩展，默认行为不变]
  ##   ① max_chars_per_line：按「每行 ≤ N 字符」重排（词边界，不丢内容）；
  ##      若同时给定 box_w_in，则叠加「实测行宽 × ink_factor ≤ box_w_in」约束
  ##      （两条约束同时满足；行数可变）。
  ##   ② box_w_in / box_h_in：显式指定框的物理尺寸（英寸），覆盖由文字反推的框大小；
  ##      框顶仍锚在 y_top_norm（沿用 flow_layout 语义：y_top_norm = 框顶 npc）。
  ##   ③ fix_fontsize：TRUE 时不做 fit_fontsize 收缩（要求按指定字号出图；
  ##      若内容装不下 → 由调用方报告冲突，而不是静默缩字号）。
  if (!is.null(max_chars_per_line)) {
    lines <- wrap_chars(lines, max_chars = max_chars_per_line, fontsize = fontsize,
                        max_w_in = box_w_in, ink_factor = ink_factor)
  }
  txt <- paste(lines, collapse = "\n")
  base <- box_size_from_text(txt, fontsize = fontsize, text_pad_in = 0.12,
                             line_height_in = 0.16, ink_factor = 1.0)
  w_in <- if (is.null(box_w_in)) base[["width_in"]] else box_w_in
  h_in <- if (is.null(box_h_in)) base[["height_in"]] else box_h_in
  ## 单框布局：x = 框心 npc；y = 框心 npc（框顶 = y_top_norm）——与 flow_layout() 同式
  lay <- data.frame(x = x_center_norm,
                    y = y_top_norm - to_norm(h_in / 2, plot_h_in),
                    w = to_norm(w_in, plot_w_in), h = to_norm(h_in, plot_h_in),
                    label = txt)
  fs <- if (isTRUE(fix_fontsize)) fontsize else
    fit_fontsize(txt, w_in, h_in, target_fontsize = fontsize, min_fontsize = 4.2)
  d2x <- function(v) xlim[1] + v / 100 * diff(xlim)
  d2y <- function(v) ylim[1] + v / 100 * diff(ylim)
  rect <- annotate("rect", xmin = d2x(lay$x - lay$w / 2), xmax = d2x(lay$x + lay$w / 2),
                   ymin = d2y(lay$y - lay$h / 2), ymax = d2y(lay$y + lay$h / 2),
                   fill = "white", colour = "grey40", linewidth = 0.25, alpha = 0.95)
  txtl <- annotate("text", x = d2x(lay$x), y = d2y(lay$y), label = txt,
                   size = fs / 2.845, colour = "grey15", lineheight = 0.95)
  list(rect = rect, text = txtl, layout = lay, fontsize = fs,
       lines = lines, w_in = w_in, h_in = h_in,
       rect_data = c(x0 = d2x(lay$x - lay$w / 2), x1 = d2x(lay$x + lay$w / 2),
                     y0 = d2y(lay$y - lay$h / 2), y1 = d2y(lay$y + lay$h / 2)))
}

# ===========================================================================
# [Round1 新增] 精确位移 / 框尺寸的「量测 → 换算 → 施加到真实 artist → 复测」工具
# ===========================================================================
# 陷阱记录（本机实测）：pdf() 设备会把小字号钳位并使 grobWidth 与 fontsize 脱钩
#   （实测 fs=4.6 与 5.0 返回值完全相同），故所有文本度量必须在**交付口径**的
#   ragg 设备上进行（与 save_pub2() 的 agg_tiff 一致）。
measure_text_dev <- function(labels, fontsize, fontfamily = "sans",
                             w_in = 6.85, h_in = 7.4, dpi = 300) {
  f <- tempfile(fileext = ".tiff")
  ragg::agg_tiff(f, width = w_in, height = h_in, units = "in", res = dpi, background = "white")
  on.exit({grDevices::dev.off(); unlink(f)}, add = TRUE)
  measure_text(labels, fontsize = fontsize, fontfamily = fontfamily)
}

# 字符宽（英寸）= Σ(各行 grobWidth) / Σ(各行可见字符数)   —— skill §5 口径（多行取平均）
char_w_in <- function(text, fontsize, fontfamily = "sans") {
  m <- measure_text_dev(text, fontsize, fontfamily)
  n <- nchar(gsub("\n", "", as.character(text), fixed = TRUE))
  sum(m$w) / max(1, sum(n))
}
# 字符高（英寸）= 单行行高（满行高）= k × fontsize；默认 k = 1.15（本项目 QA 的行高口径）
char_h_in <- function(fontsize, k = 1.15) k * fontsize / 72

# 文本块高（英寸）：多行文本实际占高 —— 取「n × fs × lineheight」与 grid grobHeight 的较大者
text_block_h_in <- function(label, fontsize, lineheight = 0.95, fontfamily = "sans") {
  n <- length(strsplit(as.character(label), "\n", fixed = TRUE)[[1]])
  h_conv <- n * fontsize * lineheight / 72
  h_grid <- convertHeight(grobHeight(textGrob(as.character(label),
                                              gp = gpar(fontsize = fontsize, fontfamily = fontfamily))),
                          "inch", valueOnly = TRUE)
  max(h_conv, h_grid)
}

# 按「每行 ≤ max_chars 字符」重排（词边界，不丢任何词），可叠加实测行宽约束
wrap_chars <- function(lines, max_chars, fontsize, max_w_in = NULL,
                       ink_factor = 1.0, fontfamily = "sans") {
  f <- tempfile(fileext = ".tiff")
  ragg::agg_tiff(f, width = 6.85, height = 7.4, units = "in", res = 300, background = "white")
  on.exit({grDevices::dev.off(); unlink(f)}, add = TRUE)
  wfun <- function(s) measure_text(s, fontsize = fontsize, fontfamily = fontfamily)$w[1]
  words <- unlist(strsplit(paste(lines, collapse = " "), "[ \t]+"))
  words <- words[nzchar(words)]
  fits <- function(s) {
    if (nchar(s) > max_chars) return(FALSE)
    if (is.null(max_w_in)) return(TRUE)
    wfun(s) * ink_factor <= max_w_in
  }
  long <- words[nchar(words) > max_chars | (!is.null(max_w_in) & wfun(words) * ink_factor > max_w_in)]
  if (length(long)) warning("wrap_chars: 单个词超限，无法在不丢内容前提下满足约束: ",
                            paste(long, collapse = "; "))
  out <- character(0); cur <- ""
  for (w in words) {
    cand <- if (nzchar(cur)) paste(cur, w) else w
    if (nzchar(cur) && !fits(cand)) { out <- c(out, cur); cur <- w } else cur <- cand
  }
  if (nzchar(cur)) out <- c(out, cur)
  out
}

# 交付口径真实 panel 物理尺寸（英寸）：栅格反解
#   patchwork 拼版后每个 panel 的真实尺寸 ≠ 单图 gtable 推算值
#   （实测 FigS1C：单图推算 2.736 in，拼版真实 2.123 in），且 save_pub2() 的 viewport
#   缩放只缩几何、不缩字号 → 英寸↔data 换算必须用「交付口径渲染」反解的真实 panel 尺寸。
#   方法：与 save_pub2() 相同路径（patchworkGrob + viewport(1-2*pad) + 300dpi 白底），
#        检出 panel 边框（图内唯一的超长灰25 直线）→ 组合成矩形。
raster_panel_boxes <- function(p, w_in, h_in, dpi = 300, pad_frac = 0.03,
                               min_run_pt = 55, border_max = 150) {
  f <- file.path(tempdir(), "qc_panel_probe.tiff")
  gt <- tryCatch(patchwork::patchworkGrob(p), error = function(e) ggplotGrob(p))
  ragg::agg_tiff(f, width = w_in, height = h_in, units = "in", res = dpi,
                 background = "white", compression = "none")
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(x = 0.5, y = 0.5,
                                    width = 1 - 2 * pad_frac, height = 1 - 2 * pad_frac))
  grid::grid.draw(gt); grid::popViewport(); grDevices::dev.off()
  a <- magick::image_data(magick::image_read(f))
  g <- matrix(as.integer(a[1, , ]), nrow = dim(a)[2], ncol = dim(a)[3])   # g[x, y]
  dark <- g < border_max
  min_run <- round(min_run_pt * dpi / 72)
  lr <- function(v) { r <- rle(v); if (!length(r$lengths)) 0L else max(c(0L, r$lengths[r$values])) }
  vline_px <- which(apply(dark, 1, lr) >= min_run)   # 竖边框：固定 x、沿 y 长游程
  hline_px <- which(apply(dark, 2, lr) >= min_run)   # 横边框：固定 y、沿 x 长游程
  grp <- function(v) { if (!length(v)) return(list()); split(v, cumsum(c(1L, diff(v) > 2L))) }
  V <- lapply(grp(vline_px), range); H <- lapply(grp(hline_px), range)
  res <- list()
  for (v1 in V) for (v2 in V) for (h1 in H) for (h2 in H) {
    x0 <- v1[1]; x1 <- v2[2]; y0 <- h1[1]; y1 <- h2[2]
    if (x1 - x0 < min_run || y1 - y0 < min_run) next
    e <- c(mean(dark[x0, y0:y1]), mean(dark[x1, y0:y1]),
           mean(dark[x0:x1, y0]), mean(dark[x0:x1, y1]))
    if (min(e) < 0.9) next
    res[[length(res) + 1]] <- data.frame(x0_in = x0 / dpi, y0_in = y0 / dpi,
                                         x1_in = x1 / dpi, y1_in = y1 / dpi,
                                         w_in = (x1 - x0 + 1) / dpi, h_in = (y1 - y0 + 1) / dpi)
  }
  if (!length(res)) return(NULL)
  out <- unique(do.call(rbind, res))
  out <- out[order(out$y0_in, out$x0_in), ]
  rownames(out) <- NULL
  out
}

# 选取目标 panel（栅格反解结果 → 目标面板）：按行（上/下）与 x0（左/右）选取
#   过滤：宽 ≥ 2.0 in（真正的 panel 都很宽；注释文本框 ~0.83 in、图例键 ~0.09 in 均被滤除）
pick_panel <- function(bx, row = c("top", "bottom"), side = c("left", "right"),
                       min_w_in = 2.0, min_h_in = 0.6) {
  row <- match.arg(row); side <- match.arg(side)
  bx <- as.data.frame(bx)
  bx <- bx[bx$w_in >= min_w_in & bx$h_in >= min_h_in, , drop = FALSE]
  if (!nrow(bx)) stop("pick_panel: 无满足尺寸阈值的候选 panel")
  bx <- bx[order(bx$y0_in, bx$x0_in), , drop = FALSE]
  top_y <- min(bx$y0_in)
  grp <- if (row == "top") bx[abs(bx$y0_in - top_y) < 0.25, , drop = FALSE]
         else bx[bx$y0_in > top_y + 0.25, , drop = FALSE]
  if (!nrow(grp)) stop("pick_panel: 目标行无候选（row=", row, "）")
  grp <- grp[order(grp$x0_in), , drop = FALSE]
  if (side == "left") grp[1, ] else grp[nrow(grp), ]
}

# 文本框包含性 + 框尺寸量测（英寸 / 字符 / pt 三种口径一次给出）
metric_box_check <- function(lines, box_w_in, box_h_in, fontsize,
                             char_w_in_v, char_h_in_v, lineheight = 0.95,
                             ink_factor = 1.05, tag = "") {
  lines <- unlist(strsplit(paste(lines, collapse = "\n"), "\n", fixed = TRUE))
  m <- measure_text_dev(lines, fontsize)
  blk <- text_block_h_in(paste(lines, collapse = "\n"), fontsize, lineheight)
  dt <- data.table(
    tag = tag,
    n_lines = length(lines),
    per_line_chars = paste(nchar(lines), collapse = ","),
    max_chars_per_line = max(nchar(lines)),
    longest_line = lines[which.max(m$w)],
    longest_line_chars = max(nchar(lines)),
    longest_line_w_in = round(max(m$w) * ink_factor, 4),
    box_w_in = round(box_w_in, 4), box_h_in = round(box_h_in, 4),
    box_w_chars = round(box_w_in / char_w_in_v, 3),
    box_h_chars = round(box_h_in / char_h_in_v, 3),
    margin_x_in = round(box_w_in - max(m$w) * ink_factor, 4),
    margin_y_in = round(box_h_in - blk, 4),
    text_block_h_in = round(blk, 4),
    chars_limit_ok = max(nchar(lines)) <= 26L,
    inside = (max(m$w) * ink_factor <= box_w_in) && (blk <= box_h_in))
  dt
}
