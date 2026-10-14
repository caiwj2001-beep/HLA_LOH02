###############################################################################
# 70_figS2.R — Supplementary Figure S2: 修订版 APOBEC 面板（回答 R3 minor point 1）
#   A APOBEC SBS 占比分布（HLA intact vs LOH，log10 x 轴，散点+箱线）
#   B 尾部对比（分组点图 + Wilson 95%CI + 每组 n + Fisher P）：
#       >0.90 intact 0.43% (95) vs LOH 0.27% (20)，P=0.053（不显著）
#       >=0.50 intact 4.98% vs LOH 5.88%，P=0.0026（方向反转）
#   C 组间差异效应量 log2（比例比）+ 95%CI —— 直观显示无实质差异
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))

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
nbS2 <- note_box(c("Both thresholds: the CI includes (or nearly",
                   "touches) 0 and the absolute difference is",
                   "<0.91 percentage points \u2014 no material",
                   "APOBEC enrichment in HLA-LOH tumours."),
                 plot_w_in = 3.6, plot_h_in = 1.9, xlim = XLC, ylim = c(0.4, 2.9),
                 x_center_norm = 30, y_top_norm = 74, fontsize = 5.0)
p2sc <- ggplot(ef, aes(y = thr_f, x = log2_ratio)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.12, colour = PAL[["teal"]], linewidth = 0.5) +
  geom_point(size = 1.8, colour = PAL[["teal"]]) +
  geom_text(aes(x = 0.80, label = sprintf("%.2f\u00d7 (%.2f\u2013%.2f)", ratio,
                                          2^lo, 2^hi)),
            hjust = 1, size = 4.9 / 2.845, colour = "grey20") +
  geom_text(aes(x = 0.80, y = as.integer(thr_f) - 0.34,
                label = sprintf("%d/%s vs %d/%s", n_LOH_hit, format(n_LOH, big.mark = ","),
                                n_intact_hit, format(n_intact, big.mark = ","))),
            hjust = 1, size = 4.6 / 2.845, colour = "grey45") +
  scale_x_continuous(limits = XLC, breaks = seq(-1.5, 0.5, 0.5)) +
  nbS2$rect + nbS2$text +
  labs(title = "C  Effect size of the group difference (HLA LOH / HLA intact)",
       subtitle = "log2 ratio of group proportions with 95% CI (delta method); 0 = no difference",
       x = "log2 (proportion ratio)", y = NULL) +
  theme_pub() + theme(panel.grid.major.y = element_blank())


# 标题/副标题按可用宽度自动折行（防溢出画布）
p2sa <- wrap_headers(p2sa, S2W)
p2sb <- wrap_headers(p2sb, S2W * 0.52)
p2sc <- wrap_headers(p2sc, S2W * 0.48)

figS2 <- p2sa / (p2sb | p2sc) + plot_layout(heights = c(1, 1.08))
cat("FigS2C note-box layout (flow_layout):\n"); print(nbS2$layout)
qa_emit("FigureS2", p2sa, S2W, S2H * 1 / 2.08, tag = "FigS2A", fs = 4.9)
qa_emit("FigureS2", p2sb, S2W * 0.52, S2H * 1.08 / 2.08, tag = "FigS2B", fs = 4.9)
qa_emit("FigureS2", p2sc, S2W * 0.48, S2H * 1.08 / 2.08, tag = "FigS2C", fs = 4.9)
save_pub2(figS2, "SupplementaryFigureS2_apobec", S2W, S2H)
