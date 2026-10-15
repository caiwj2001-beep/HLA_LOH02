###############################################################################
# 30_fig3.R — Figure 3: TMB × HLA LOH
#   （修回重编号：原 20_fig2.R / Figure 2 —— TMB 图在正文首现晚于机制图，改挂 Figure 3）
#   A TMB 分布（LOH vs intact, log10, 箱线+散点）
#   B 癌种层面 log2 倍数变化（FDR<0.05 着色，注明不显著癌种数）
#   C TMB–LOH 的 OR 森林图（未校正 / +非整倍体含6p / 排6p / 排6q）+ 非整倍体三分位
###############################################################################
## ---- 抖动点可复现性（2026-10-15 补丁）---------------------------------------
##   geom_jitter() 默认从全局 RNG 取偏移，故同一脚本每次重跑的散点落点都不同，
##   图件无法字节级复现（仅 A 面板的亚像素级别，不影响任何数值/统计量）。
##   此处固定种子，使 Fig3 与 FigS1 各自可重复渲染；两个脚本使用**互相独立**的常量，
##   改其一不会影响另一图。种子只决定抖动偏移，不改动数据、图层、文本或统计量。
JITTER_SEED_FIG3 <- 20261015L
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))
## 用户指定「字符宽度/高度」级精确位移工具（量测 → 换算 → 施加到真实 artist）
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_shift.R"))

F2W <- 6.85; F2H <- 8.6
AXT <- 5.4; ANNT <- 5.2

## ---------- A ----------
d2a <- fread(file.path(IMD, "fig2a_tmb_dist.tsv"))
s2a <- fread(file.path(IMD, "fig2a_tmb_summary.tsv"))
d2a[, group := factor(group, levels = c("HLA intact", "HLA LOH"))]
s2a[, group := factor(group, levels = c("HLA intact", "HLA LOH"))]
setkey(s2a, group)
set.seed(JITTER_SEED_FIG3)   # 固定 A 面板 geom_jitter() 的抖动偏移（见文件顶部说明）
p2a <- ggplot(d2a, aes(x = group, y = TMB_SCORE, fill = group)) +
  geom_boxplot(width = 0.5, outlier.shape = NA, linewidth = 0.35, alpha = 0.9,
               colour = "grey25") +
  geom_jitter(width = 0.16, size = 0.12, alpha = 0.10, colour = "grey20") +
  annotate("text", x = 1.5, y = 60, hjust = 0.5,
           label = sprintf("median %.1f vs %.1f mut/Mb", s2a["HLA intact"]$median,
                           s2a["HLA LOH"]$median), size = ANNT / 2.845, colour = "grey5") +
  annotate("text", x = 1.5, y = 33, hjust = 0.5,
           label = sprintf("Wilcoxon P = %.1e", s2a[1]$wilcoxon_P),
           size = ANNT / 2.845, colour = "grey25") +
  annotate("text", x = 1.5, y = 18, hjust = 0.5,
           label = sprintf("n = %s vs %s", format(s2a["HLA intact"]$n, big.mark = ","),
                           format(s2a["HLA LOH"]$n, big.mark = ",")),
           size = ANNT / 2.845, colour = "grey25") +
  scale_y_log10(limits = c(0.05, 120), breaks = c(0.1, 1, 10, 100),
                labels = c("0.1", "1", "10", "100")) +
  scale_fill_manual(values = c("HLA intact" = PAL[["grey"]], "HLA LOH" = PAL[["navy"]])) +
  labs(title = "A  Tumour mutational burden by HLA LOH status",
       subtitle = sprintf("%s evaluable tumours (one per patient); box = IQR, points jittered",
                          format(nrow(d2a), big.mark = ",")),
       x = NULL, y = "TMB (mutations/Mb, log10)") +
  theme_pub() + theme(legend.position = "none")

## ---------- B ----------
d2b <- fread(file.path(IMD, "fig2b_tmb_log2fc.tsv"))
d2b[, sig := ifelse(FDR < 0.05, "FDR < 0.05", "not significant")]
d2b[, CANCER_TYPE := factor(CANCER_TYPE, levels = CANCER_TYPE[order(log2FC)])]
d2b[, nlab := sprintf("%.2f", log2FC)]
p2b <- ggplot(d2b, aes(x = log2FC, y = CANCER_TYPE, colour = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  geom_point(size = 1.7) +
  geom_text(aes(x = log2FC + 0.04, label = nlab), hjust = 0, size = 4.8 / 2.845,
            colour = "grey25", show.legend = FALSE) +
  scale_colour_manual(values = c("FDR < 0.05" = PAL[["red"]], "not significant" = PAL[["grey"]]),
                      name = NULL) +
  scale_x_continuous(limits = c(-0.35, 1.15), breaks = c(-0.3, 0, 0.3, 0.6, 0.9)) +
  labs(title = "B  TMB elevation with HLA LOH by cancer type",
       subtitle = sprintf("log2 fold-change of median TMB (HLA LOH / intact); %d/%d cancer types FDR<0.05, %d not significant",
                          sum(d2b$FDR < 0.05), nrow(d2b), sum(d2b$FDR >= 0.05)),
       x = "log2 fold-change of median TMB", y = NULL) +
  theme_pub() +
  theme(axis.text.y = element_text(size = AXT),
        legend.position = "top", legend.text = element_text(size = 5.4),
        legend.key.size = unit(0.24, "cm"))

## ---------- C ----------
mdl <- fread(file.path(IMD, "fig2c_tmb_models.tsv"))
ter <- fread(file.path(IMD, "fig2c_tmb_tertile.tsv"))
dtc <- rbind(
  data.table(label = mdl$label, est = mdl$OR, lo = mdl$lo, hi = mdl$hi, P = mdl$P,
             group = "TMB odds ratio (per log10 TMB)"),
  data.table(label = sprintf("Aneuploidy tertile %s (n = %s)", ter$tertile, format(ter$N, big.mark = ",")),
             est = ter$OR, lo = ter$lo, hi = ter$hi, P = ter$P,
             group = "Stratified by aneuploidy tertile"))
dtc[grepl("Q3", label), label := paste0(label, " \u2014 effect lost")]
dtc[, is_null := FALSE]
p2c <- forest_panel(dtc, xlim = c(1.0, 2.3), vline = 1, logx = TRUE, txt_cex = 5.2, lab_size = 5.6,
                    col_map = c("TMB odds ratio (per log10 TMB)" = PAL[["navy"]],
                                "Stratified by aneuploidy tertile" = PAL[["teal"]]),
                    title = "C  TMB\u2013HLA LOH association after adjusting for global aneuploidy",
                    xlab = "Odds ratio for HLA LOH per log10 TMB (log scale)") +
  theme(legend.position = "none")

## ---- 用户指定精确位移（QC_user_adjust_round1 item 5）------------------------
##  Fig3C 森林图右侧 OR 数值标签：第 1 个（Unadjusted …）与第 5 个（Aneuploidy tertile Q1 …）
##  各向左移动 20 个字符宽度。
##  字符宽 char_w = 标签 bbox 宽 / 可见字符数，面板实际尺寸取自投稿 PDF 矢量层实测
##  （qc_shift_measure.py，见 fig_shift.R 头注）；偏移经 pt → 对数十年换算后写入
##  驱动该 geom_text 图层的映射列 tx_pos，未手填任何坐标、未改动其它图层。
stopifnot(nrow(dtc) == nrow(shift_labels("Fig3C")))
shift_model_check(p2c, "Fig3C", x_col = "tx_pos", logx = TRUE)   # 换算基准自检（< 0.5 pt）
p2c <- shift_text_x(p2c, "Fig3C", col = "tx_pos", rows = c(1, 5), d_chars = -20, logx = TRUE)


# 标题/副标题按可用宽度自动折行（防溢出画布）
# Fig3B 的 header grob 绘制在 **panel 列**（宽 = 子图宽 − y 轴标签列 − y 轴标题列 − 边距），
# 而 gtable 子 viewport 为 clip="off"，溢出 panel 列的部分不会被父级裁掉；Fig3B 位于画布右缘，
# 溢出即触及画布右边界被栅格裁切（70 个非白边缘像素）。因此 header 必须按 panel 宽折行。
F2TOP_H <- F2H * 1 / 1.78
p2b_panel_w   <- panel_dims(p2b, F2W * 0.55, F2TOP_H)[["panel_w_in"]]
p2b_hdr_avail <- p2b_panel_w - 0.12   # 12 pt 安全余量
p2b$labels$title    <- wrap_txt(p2b$labels$title,    p2b_hdr_avail, 7.7, ink_factor = 1.06)
p2b$labels$subtitle <- wrap_txt(p2b$labels$subtitle, p2b_hdr_avail, 6.4, ink_factor = 1.06)
p2a <- wrap_headers(p2a, F2W * 0.45)
p2c <- wrap_headers(p2c, F2W)

fig2 <- (p2a | p2b) / p2c + plot_layout(heights = c(1, 0.78), widths = c(0.45, 0.55))
qa_emit("Figure3", p2a, F2W * 0.45, F2H * 1 / 1.78, tag = "Fig3A", fs = ANNT)
qa_emit("Figure3", p2b, F2W * 0.55, F2H * 1 / 1.78, tag = "Fig3B", fs = AXT)
qa_emit("Figure3", p2c, F2W, F2H * 0.78 / 1.78, tag = "Fig3C", fs = 5.2)
save_pub2(fig2, "Figure3_TMB_aneuploidy", F2W, F2H)
