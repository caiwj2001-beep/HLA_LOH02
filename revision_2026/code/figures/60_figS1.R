###############################################################################
# 60_figS1.R — Supplementary Figure S1: 修订版 APOBEC 面板（回答 R3 minor point 1）
#   （修回重编号：原 70_figS2.R / Supplementary Figure S2 —— APOBEC 图在正文首现早于胚系图，
#     改挂 Supplementary Figure S1。面板 A/B/C 与全部数字不变。）
#   A APOBEC SBS 占比分布（HLA intact vs LOH，log10 x 轴，散点+箱线）
#   B 尾部对比（分组点图 + Wilson 95%CI + 每组 n + Fisher P）：
#       >0.90 intact 0.43% (95) vs LOH 0.27% (20)，P=0.053（不显著）
#       >=0.50 intact 4.98% vs LOH 5.88%，P=0.0026（方向反转）
#   C 组间差异效应量 log2（比例比）+ 95%CI —— 直观显示无实质差异
###############################################################################
## ---- 抖动点可复现性（2026-10-15 补丁）---------------------------------------
##   geom_jitter() 默认从全局 RNG 取偏移，故同一脚本每次重跑的散点落点都不同，
##   图件无法字节级复现（仅 A 面板的亚像素级别，不影响任何数值/统计量）。
##   此处固定种子，使 FigS1 可重复渲染；Fig3 与 FigS1 各自使用**互相独立**的常量，
##   改其一不会影响另一图。种子只决定抖动偏移，不改动数据、图层、文本或统计量。
JITTER_SEED_FIGS1 <- 20261016L
###############################################################################
## ---- [Round1] 用户精确位移 / 框尺寸要求（只改位置与框尺寸，不改任何数字/统计量）----
## 9. 图 S1C：
##   ① 「第 1 个 HR 值」向上移动 3 个字符高度。
##      本面板 y 轴自上而下为 ≥0.50（上）→ >0.90（下），图内阅读顺序第 1 个 = ≥0.50 行，
##      即数值标签「1.18× (1.06–1.32)」。若用户口径是数据表第 1 行（>0.90 行），
##      只需把 FIGS1C_MOVE_ROW 改成 ">0.90"，位移量算法完全相同（均为实测字符高换算）。
##   ② 注释文本框高度 = 10 个字符高度；
##   ③ 文本框宽度只能容纳 26 个字符 → 框内文字重排为每行 ≤ 26 字符
##      （叠加「实测行宽 × 墨迹系数 ≤ 框宽」约束），确保文字完全在框内。
## 字符宽/高的量测必须在**交付口径** ragg 设备上进行：pdf() 设备会把小字号钳位，
## 使 grobWidth 与 fontsize 脱钩（实测 fs=4.6 与 fs=5.0 返回值完全相同）——
## 见 fig_common.R::measure_text_dev 注释。
FIGS1C_MOVE_ROW  <- "\u22650.50"   # 被上移的那一行（= 图内自上而下第 1 行）
FIGS1C_N_CHAR_UP <- 3              # 上移 3 个字符高度
FIGS1C_LABEL_FS  <- 4.9            # 该面板数值标签字号（pt，未改动）
NB_FS            <- 5.0            # 注释文本框字号（pt，未改动）
NB_MAXCHARS      <- 26L            # 框宽只能容纳的字符数
NB_BOX_H_CHARS   <- 10             # 框高 = 10 个字符高度
NB_X_CENTER_NORM <- 30; NB_Y_TOP_NORM <- 74      # 原锚点（Round1 不移动文本框）
NB_XLIM_ASSUMED  <- c(-1.6, 0.85)                # 原调用传给 note_box 的 xlim（未展开）
NB_YLIM_ASSUMED  <- c(0.4, 2.9)                  # 原调用传给 note_box 的 ylim（未展开）
NB_SRC_LINES <- c("Both thresholds: the CI includes (or nearly",
                  "touches) 0 and the absolute difference is",
                  "<0.91 percentage points \u2014 no material",
                  "APOBEC enrichment in HLA-LOH tumours.")
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))

QCDIR <- file.path(FIGDIR, "QC_user_adjust_round1")
dir.create(QCDIR, showWarnings = FALSE, recursive = TRUE)

S2W <- 6.85; S2H <- 7.4
GRP <- c("HLA intact" = PAL[["grey"]], "HLA LOH" = PAL[["navy"]])

## ---------- A 分布 ----------
dis <- fread(file.path(IMD, "figs2_apobec_dist.tsv"))
summ <- fread(file.path(IMD, "figs2_apobec_summary.tsv"))
FLOOR <- 0.01
dis[, x := pmax(pct, FLOOR)]
dis[, is_zero := pct == 0]
FLOOR_Y <- 0.35
dA <- copy(dis); dA[is_zero == TRUE, group_y := "zero panel"]
set.seed(JITTER_SEED_FIGS1)   # 固定 A 面板 geom_jitter() 的抖动偏移（见文件顶部说明）
p2sa <- ggplot(dis[is_zero == FALSE], aes(y = factor(group, levels = c("HLA LOH", "HLA intact")),
                                  x = x, colour = group)) +
  geom_jitter(height = 0.16, width = 0, size = 0.18, alpha = 0.10) +
  geom_boxplot(width = 0.34, outlier.shape = NA, fill = NA, colour = "grey20",
               linewidth = 0.4, position = position_nudge(y = 0.0)) +
  annotate("point", x = FLOOR, y = 1, size = 1.4, colour = PAL[["navy"]], shape = 4, stroke = 1) +
  annotate("point", x = FLOOR, y = 2, size = 1.4, colour = PAL[["grey"]], shape = 4, stroke = 1) +
  geom_label(data = summ, aes(x = 0.012, y = ifelse(group == "HLA LOH", 0.62, 1.62),
                              label = sprintf("n = %s | zeros = %s | median = %.2f | Q3 = %.2f",
                                              format(n, big.mark = ","), format(n_zero, big.mark = ","),
                                              median, q3), colour = group),
             hjust = 0, size = 4.9 / 2.845, label.size = NA, fill = "white", alpha = 0.82,
             inherit.aes = FALSE) +
  scale_x_log10(limits = c(0.008, 100), breaks = c(0.01, 0.1, 1, 10, 100),
                labels = c("0", "0.1", "1", "10", "100")) +
  scale_colour_manual(values = GRP, guide = "none") +
  scale_y_discrete(labels = c("HLA intact", "HLA LOH")) +
  labs(title = "A  Distribution of the APOBEC SBS proportion by HLA LOH status",
       subtitle = sprintf("Primary cohort with signature data (n = %s); log10 axis, exact zeros plotted at the floor (cross)",
                          format(nrow(dis), big.mark = ",")),
       x = "APOBEC SBS proportion of all substitutions (%)", y = NULL) +
  theme_pub() + theme(panel.grid.major.y = element_blank())

## ---------- B 尾部对比 ----------
tb <- fread(file.path(IMD, "figs2_tail_comparison.tsv"))
tb[, grp := factor(group, levels = c("HLA intact", "HLA LOH"))]
tb[, thr_f := factor(threshold, levels = c(">0.90", "\u22650.50"))]
tb[, nlab := sprintf("%.2f%%\n(%d/%s)", pct, k, format(n, big.mark = ","))]
XL2B <- c(0, 8.2)
tb[, ypos := as.integer(thr_f) + ifelse(group == "HLA LOH", -0.17, 0.17)]
p2sb <- ggplot(tb, aes(y = ypos, colour = grp)) +
  geom_segment(aes(x = lo, xend = hi, yend = ypos), linewidth = 0.45) +
  geom_point(aes(x = pct), size = 1.7) +
  geom_text(aes(x = pct + 0.22, label = nlab, colour = grp), hjust = 0, size = 4.9 / 2.845,
            lineheight = 0.92) +
  geom_text(data = unique(tb[, .(thr_f, P, threshold)]),
            aes(x = XL2B[2] - 0.1, y = as.integer(thr_f) + 0.52,
                label = sprintf("Fisher P = %s", ifelse(P < 0.01, sprintf("%.4f", P), sprintf("%.3f", P)))),
            hjust = 1, size = 5.0 / 2.845, colour = "grey15", inherit.aes = FALSE) +
  scale_y_continuous(breaks = 1:2, labels = c("APOBEC proportion > 0.90", "APOBEC proportion \u2265 0.50"),
                     limits = c(0.5, 2.6)) +
  scale_x_continuous(limits = XL2B, breaks = seq(0, 8, 2)) +
  scale_colour_manual(values = GRP, name = NULL) +
  labs(title = "B  High-APOBEC tails in HLA intact versus HLA LOH tumours",
       subtitle = "Points = group proportion, bars = Wilson 95% CI; the >0.90 tail is not significantly different",
       x = "Tumours above threshold (%)", y = NULL) +
  theme_pub() +
  theme(legend.position = "top", legend.text = element_text(size = 5.4),
        legend.key.size = unit(0.24, "cm"), panel.grid.major.y = element_blank())

## ---------- C 效应量 ----------
ef <- fread(file.path(IMD, "figs2_effect_sizes.tsv"))
ef[, thr_f := factor(threshold, levels = c(">0.90", "\u22650.50"))]
XLC <- c(-1.6, 0.85)
## 数值标签图层的位置列 y_ann（真实 artist 的 aes(y=...)）：dy_first=0 时与原图完全一致
build_p2sc <- function(dy_first = 0) {
  d <- copy(ef)
  d[, y_ann := as.integer(thr_f) + ifelse(as.character(thr_f) == FIGS1C_MOVE_ROW, dy_first, 0)]
  ggplot(d, aes(y = thr_f, x = log2_ratio)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
    geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.12, colour = PAL[["teal"]], linewidth = 0.5) +
    geom_point(size = 1.8, colour = PAL[["teal"]]) +
    geom_text(aes(x = 0.80, y = y_ann,
                  label = sprintf("%.2f\u00d7 (%.2f\u2013%.2f)", ratio, 2^lo, 2^hi)),
              hjust = 1, size = FIGS1C_LABEL_FS / 2.845, colour = "grey20") +
    geom_text(aes(x = 0.80, y = as.integer(thr_f) - 0.34,
                  label = sprintf("%d/%s vs %d/%s", n_LOH_hit, format(n_LOH, big.mark = ","),
                                  n_intact_hit, format(n_intact, big.mark = ","))),
              hjust = 1, size = 4.6 / 2.845, colour = "grey45") +
    scale_x_continuous(limits = XLC, breaks = seq(-1.5, 0.5, 0.5)) +
    labs(title = "C  Effect size of the group difference (HLA LOH / HLA intact)",
         subtitle = "log2 ratio of group proportions with 95% CI (delta method); 0 = no difference",
         x = "log2 (proportion ratio)", y = NULL) +
    theme_pub() + theme(panel.grid.major.y = element_blank())
}
p2sc_base <- build_p2sc(0)

# 标题/副标题按可用宽度自动折行（防溢出画布）
p2sa <- wrap_headers(p2sa, S2W)
p2sb <- wrap_headers(p2sb, S2W * 0.52)
p2sc_base <- wrap_headers(p2sc_base, S2W * 0.48)

## ============================================================================
## [Round1] 量测 → 换算 → 施加到真实 artist（所有数值来自量测，无手填坐标）
## ============================================================================
## ① 交付口径真实 panel 尺寸（栅格反解）：拼版后 FigS1C 的真实 panel ≠ 单图 gtable 推算值
figS1_probe <- p2sa / (p2sb | p2sc_base) + plot_layout(heights = c(1, 1.08))
PBX <- raster_panel_boxes(figS1_probe, S2W, S2H, dpi = 300, pad_frac = 0.03)
cat("\n[FigS1] 交付口径真实 panel 尺寸（栅格反解，英寸）：\n"); print(PBX, row.names = FALSE)
if (is.null(PBX) || nrow(PBX) < 1) stop("panel 边框反解失败：未检出任何 panel")
PANEL_S1A <- pick_panel(PBX, "top", "left"); PANEL_S1B <- pick_panel(PBX, "bottom", "left")
PANEL_S1C <- pick_panel(PBX, "bottom", "right")   # 右下 = FigS1C
cat(sprintf("[FigS1] FigS1C panel 实测 %.4f x %.4f in（%.3f x %.3f pt）\n",
            PANEL_S1C$w_in, PANEL_S1C$h_in, PANEL_S1C$w_in * 72, PANEL_S1C$h_in * 72))

## ② 字符宽/高（交付口径 ragg 设备量测）
CHAR_W_NB  <- char_w_in(NB_SRC_LINES, NB_FS)     # = Σ行宽 / Σ可见字符（英寸）
CHAR_H_NB  <- char_h_in(NB_FS)                   # = 1.15 × 字号（本项目 QA 行高口径）
CHAR_H_LAB <- char_h_in(FIGS1C_LABEL_FS)
LAB_TXT <- sprintf("%.2f\u00d7 (%.2f\u2013%.2f)", ef$ratio, 2^ef$lo, 2^ef$hi)
CHAR_W_LAB <- char_w_in(LAB_TXT, FIGS1C_LABEL_FS)
cat(sprintf("[FigS1] 字符量测：框内文字 fs=%.1f → 平均字符宽 %.4f in (%.3f pt)、字符高 %.4f in (%.3f pt)\n",
            NB_FS, CHAR_W_NB, CHAR_W_NB * 72, CHAR_H_NB, CHAR_H_NB * 72))
cat(sprintf("[FigS1] 字符量测：数值标签 fs=%.1f → 平均字符宽 %.4f in (%.3f pt)、字符高 %.4f in (%.3f pt)\n",
            FIGS1C_LABEL_FS, CHAR_W_LAB, CHAR_W_LAB * 72, CHAR_H_LAB, CHAR_H_LAB * 72))

## ③ real panel 的真实 data 范围（ggplot_build 展开后的范围，而非未展开 limits）
PP_S1C <- ggplot_build(p2sc_base)$layout$panel_params[[1]]
XR_S1C <- PP_S1C$x.range; YR_S1C <- PP_S1C$y.range
cat(sprintf("[FigS1] FigS1C 真实 data 范围：x=(%.5f, %.5f) span=%.5f | y=(%.5f, %.5f) span=%.5f\n",
            XR_S1C[1], XR_S1C[2], diff(XR_S1C), YR_S1C[1], YR_S1C[2], diff(YR_S1C)))
cat("[FigS1] FigS1C 数值标签（图内自上而下）逐字：\n")
for (i in rev(seq_len(nrow(ef))))
  cat(sprintf("       第 %d 个 | threshold=%-6s | %s\n", nrow(ef) - i + 1, ef$threshold[i], LAB_TXT[i]))
cat(sprintf("[FigS1] 被移动的是第 1 个：'%s'（对应 threshold %s）\n",
            LAB_TXT[which(as.character(ef$thr_f) == FIGS1C_MOVE_ROW)],
            ef$threshold[which(as.character(ef$thr_f) == FIGS1C_MOVE_ROW)]))

## ④ 9①：第 1 个数值标签上移 3 个字符高度 → 换算为 y 方向 data 位移
DY_MOVE <- FIGS1C_N_CHAR_UP * CHAR_H_LAB / PANEL_S1C$h_in * diff(YR_S1C)
cat(sprintf("[FigS1] 9① 上移量：%d × %.4f in = %.4f in（= panel 高的 %.3f%%）→ Δy = %.5f data\n",
            FIGS1C_N_CHAR_UP, CHAR_H_LAB, FIGS1C_N_CHAR_UP * CHAR_H_LAB,
            100 * FIGS1C_N_CHAR_UP * CHAR_H_LAB / PANEL_S1C$h_in, DY_MOVE))

## ⑤ 9②③：文本框 = 26 字符宽 × 10 字符高（英寸）；文字按每行 ≤ 26 字符 + 实测行宽重排
BOX_W_IN <- NB_MAXCHARS * CHAR_W_NB
BOX_H_IN <- NB_BOX_H_CHARS * CHAR_H_NB
cat(sprintf("[FigS1] 9②③ 目标框：%d 字符宽 × %d 字符高 = %.4f in × %.4f in (%.2f pt × %.2f pt)\n",
            NB_MAXCHARS, NB_BOX_H_CHARS, BOX_W_IN, BOX_H_IN, BOX_W_IN * 72, BOX_H_IN * 72))
## 框锚点（框顶中心）在 data 坐标上与改动前完全一致：旧调用的 npc→data 映射用的是未展开
## 的 xlim/ylim，新映射改用真实展开范围 → 反解出等价的 npc（文本框位置本身不移动）
x_anchor_keep <- NB_XLIM_ASSUMED[1] + NB_X_CENTER_NORM / 100 * diff(NB_XLIM_ASSUMED)
y_anchor_keep <- NB_YLIM_ASSUMED[1] + NB_Y_TOP_NORM / 100 * diff(NB_YLIM_ASSUMED)
NB_X_NORM_KEEP <- (x_anchor_keep - XR_S1C[1]) / diff(XR_S1C) * 100
NB_Y_NORM_KEEP <- (y_anchor_keep - YR_S1C[1]) / diff(YR_S1C) * 100
cat(sprintf("[FigS1] 框锚点（框顶中心）保持不动：data (x=%.4f, y_top=%.4f) → npc (%.3f, %.3f)\n",
            x_anchor_keep, y_anchor_keep, NB_X_NORM_KEEP, NB_Y_NORM_KEEP))
nbS2 <- note_box(NB_SRC_LINES, plot_w_in = PANEL_S1C$w_in, plot_h_in = PANEL_S1C$h_in,
                 xlim = XR_S1C, ylim = YR_S1C,
                 x_center_norm = NB_X_NORM_KEEP, y_top_norm = NB_Y_NORM_KEEP,
                 fontsize = NB_FS, max_chars_per_line = NB_MAXCHARS,
                 box_w_in = BOX_W_IN, box_h_in = BOX_H_IN,
                 fix_fontsize = TRUE, ink_factor = 1.05)

## ⑥ 文本框包含性量测（框内文字是否完全落在框内；不满足则报冲突，绝不擅自缩减要求）
BOXCHK <- metric_box_check(nbS2$lines, box_w_in = nbS2$w_in, box_h_in = nbS2$h_in,
                           fontsize = nbS2$fontsize, char_w_in_v = CHAR_W_NB, char_h_in_v = CHAR_H_NB,
                           lineheight = 0.95, ink_factor = 1.05, tag = "FigS1C_note_box")
BOXCHK[, `:=`(req_box_w_chars = NB_MAXCHARS, req_box_h_chars = NB_BOX_H_CHARS)]
cat("\n[FigS1] 9②③ 文本框实测（框内文字包含性）：\n"); print(BOXCHK, row.names = FALSE)
cat("[FigS1] 重排后框内文字逐行：\n")
for (i in seq_along(nbS2$lines)) cat(sprintf("   L%d (%2d 字符) |%s|\n", i, nchar(nbS2$lines[i]), nbS2$lines[i]))
cat(sprintf("[FigS1] 内容完整性：原 %d 词 → 重排后 %d 词；词序列逐字一致 = %s\n",
            length(strsplit(paste(NB_SRC_LINES, collapse = " "), " ")[[1]]),
            length(strsplit(paste(nbS2$lines, collapse = " "), " ")[[1]]),
            identical(strsplit(paste(NB_SRC_LINES, collapse = " "), " ")[[1]],
                      strsplit(paste(nbS2$lines, collapse = " "), " ")[[1]])))
if (!isTRUE(BOXCHK$inside[1]) || !isTRUE(BOXCHK$chars_limit_ok[1])) {
  cat("\n!!!!!!!! [CONFLICT] 26 字符宽 × 10 字符高的框装不下重排后的文字：\n")
  cat(sprintf("   文字块高 %.4f in > 框高 %.4f in ? %s ; 最长行宽(含墨迹系数) %.4f in > 框宽 %.4f in ? %s\n",
              BOXCHK$text_block_h_in[1], BOXCHK$box_h_in[1],
              BOXCHK$text_block_h_in[1] > BOXCHK$box_h_in[1],
              BOXCHK$longest_line_w_in[1], BOXCHK$box_w_in[1],
              BOXCHK$longest_line_w_in[1] > BOXCHK$box_w_in[1]))
  cat(sprintf("   最小可行方案（不缩减要求、不改数字/字号）：行数 %d 需框高 ≥ %.4f in（= %.2f 字符高）；或框宽 ≥ %.4f in（= %.2f 字符宽）\n",
              BOXCHK$n_lines[1], BOXCHK$text_block_h_in[1],
              BOXCHK$text_block_h_in[1] / CHAR_H_NB,
              BOXCHK$longest_line_w_in[1], BOXCHK$longest_line_w_in[1] / CHAR_W_NB))
} else {
  cat(sprintf("   -> 文字完全落在框内：最长行 %d 字符（≤ %d），x 余量 %.4f in、y 余量 %.4f in\n",
              BOXCHK$longest_line_chars[1], NB_MAXCHARS, BOXCHK$margin_x_in[1], BOXCHK$margin_y_in[1]))
}

BUILD_R1 <- data.table(
  item = c("FigS1C_move_row", "FigS1C_move_chars_required", "FigS1C_label_fontsize",
           "FigS1C_char_w_label_in", "FigS1C_char_h_label_in",
           "FigS1C_panel_w_in", "FigS1C_panel_h_in", "FigS1C_dy_data",
           "FigS1C_note_fontsize", "FigS1C_char_w_note_in", "FigS1C_char_h_note_in",
           "FigS1C_box_w_in", "FigS1C_box_h_in", "FigS1C_box_w_chars", "FigS1C_box_h_chars",
           "FigS1C_note_lines", "FigS1C_note_max_chars_per_line",
           "FigS1C_note_per_line_chars", "FigS1C_note_longest_line",
           "FigS1C_note_x_margin_in", "FigS1C_note_y_margin_in", "FigS1C_note_inside"),
  value = c(FIGS1C_MOVE_ROW, as.character(FIGS1C_N_CHAR_UP), sprintf("%.2f", FIGS1C_LABEL_FS),
            sprintf("%.6f", CHAR_W_LAB), sprintf("%.6f", CHAR_H_LAB),
            sprintf("%.6f", PANEL_S1C$w_in), sprintf("%.6f", PANEL_S1C$h_in), sprintf("%.6f", DY_MOVE),
            sprintf("%.2f", NB_FS), sprintf("%.6f", CHAR_W_NB), sprintf("%.6f", CHAR_H_NB),
            sprintf("%.6f", BOX_W_IN), sprintf("%.6f", BOX_H_IN),
            sprintf("%.4f", BOX_W_IN / CHAR_W_NB), sprintf("%.4f", BOX_H_IN / CHAR_H_NB),
            as.character(BOXCHK$n_lines[1]), as.character(NB_MAXCHARS),
            BOXCHK$per_line_chars[1], BOXCHK$longest_line[1],
            sprintf("%.6f", BOXCHK$margin_x_in[1]), sprintf("%.6f", BOXCHK$margin_y_in[1]),
            as.character(BOXCHK$inside[1])))
fwrite(BUILD_R1, file.path(QCDIR, "S1_measure_steps.tsv"), sep = "\t")
fwrite(BOXCHK, file.path(QCDIR, "S1_box_check.tsv"), sep = "\t")
fwrite(PBX, file.path(QCDIR, "S1_panel_boxes_raster.tsv"), sep = "\t")
fwrite(data.table(
  panel = "FigS1C",
  kind = c(rep("value_label", nrow(ef)), rep("sub_label", nrow(ef)), rep("note_box_line", length(nbS2$lines))),
  row_display_order_top_down = c(rev(seq_len(nrow(ef))), rev(seq_len(nrow(ef))), seq_along(nbS2$lines)),
  text = c(LAB_TXT,
           sprintf("%d/%s vs %d/%s", ef$n_LOH_hit, format(ef$n_LOH, big.mark = ","),
                   ef$n_intact_hit, format(ef$n_intact, big.mark = ",")),
           nbS2$lines)),
  file.path(QCDIR, "S1_labels.tsv"), sep = "\t")

## ---------- 组装 FigS1（施加位移 + 新文本框）----------
p2sc <- build_p2sc(DY_MOVE) + nbS2$rect + nbS2$text
p2sc <- wrap_headers(p2sc, S2W * 0.48)

figS2 <- p2sa / (p2sb | p2sc) + plot_layout(heights = c(1, 1.08))
cat("FigS1C note-box layout (flow_layout):\n"); print(nbS2$layout)
qa_emit("FigureS1", p2sa, S2W, S2H * 1 / 2.08, tag = "FigS1A", fs = 4.9)
qa_emit("FigureS1", p2sb, S2W * 0.52, S2H * 1.08 / 2.08, tag = "FigS1B", fs = 4.9)
qa_emit("FigureS1", p2sc, S2W * 0.48, S2H * 1.08 / 2.08, tag = "FigS1C", fs = 4.9)
save_pub2(figS2, "SupplementaryFigureS1_apobec", S2W, S2H)
