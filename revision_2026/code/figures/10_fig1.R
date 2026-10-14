###############################################################################
# 10_fig1.R — Figure 1: 泛癌 HLA LOH 图谱 + 调用可靠性
#   A 29 癌种 any-HLA-LOH 频率 + Wilson 95%CI + 25.3% 虚线
#   B HLA-A/B/C 位点特异性频率
#   C 臂独立型占比 × 纯度十分位（60.3%→11.3%）+ 6p 佐证的高可信度频率 14.0%
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))

F1W <- 6.85; F1H <- 9.0
AXT <- 5.4
d <- fread(file.path(IMD, "fig1a_cancer_freq.tsv"))
d[, CANCER_TYPE := factor(CANCER_TYPE, levels = CANCER_TYPE[order(freq_LOH)])]
ov <- d[1]
d[, nlab := sprintf("%d/%d", n_LOH, N)]
d[, plab := sprintf("%.1f", 100 * freq_LOH)]
p1a <- ggplot(d, aes(x = CANCER_TYPE, y = 100 * freq_LOH)) +
  geom_col(fill = PAL[["navy"]], width = 0.68) +
  geom_errorbar(aes(ymin = 100 * lo, ymax = 100 * hi), width = 0.3,
                colour = "grey30", linewidth = 0.35) +
  geom_hline(yintercept = 100 * ov$cohort_freq, linetype = "dashed",
             colour = PAL[["red"]], linewidth = 0.45) +
  geom_text(aes(y = 42, label = nlab), hjust = 0, size = AXT / 2.845, colour = "grey35") +
  geom_text(aes(y = 53, label = plab), hjust = 0, size = AXT / 2.845, colour = "grey5") +
  coord_flip() +
  scale_y_continuous(limits = c(0, 62), breaks = seq(0, 50, 10)) +
  labs(title = "A  Pan-cancer landscape of HLA loss of heterozygosity",
       subtitle = sprintf("%d evaluable tumours across %d cancer types (N\u2265100).  Dashed line: pan-cancer %.1f%% (95%% CI %.1f\u2013%.1f).  Right columns: events/n and frequency (%%)",
                          sum(d$N), nrow(d), 100 * ov$cohort_freq, 100 * ov$cohort_lo, 100 * ov$cohort_hi),
       x = NULL, y = "HLA LOH frequency (%)") +
  theme_pub() + theme(axis.text.y = element_text(size = AXT))

l <- fread(file.path(IMD, "fig1b_locus_freq.tsv"))
l[, CANCER_TYPE := factor(CANCER_TYPE, levels = levels(d$CANCER_TYPE))]
l[, locus := factor(locus, levels = c("HLA-A", "HLA-B", "HLA-C"))]
ovl <- fread(file.path(IMD, "fig1b_locus_overall.tsv"))
p1b <- ggplot(l, aes(x = CANCER_TYPE, y = 100 * freq_LOH, fill = locus)) +
  geom_col(position = position_dodge(0.78), width = 0.72) +
  geom_errorbar(aes(ymin = 100 * lo, ymax = 100 * hi), position = position_dodge(0.78),
                width = 0.22, linewidth = 0.25, colour = "grey30") +
  coord_flip() +
  scale_fill_manual(values = c("HLA-A" = PAL[["navy"]], "HLA-B" = PAL[["teal"]],
                               "HLA-C" = PAL[["gold"]]), name = "Locus") +
  scale_y_continuous(limits = c(0, 52), breaks = seq(0, 50, 10)) +
  labs(title = "B  Locus-specific HLA LOH",
       subtitle = sprintf("Frequency among samples evaluable at that locus (cohort-wide HLA-A %.1f%%, HLA-B %.1f%%, HLA-C %.1f%%); bars = Wilson 95%% CI",
                          100 * ovl[locus == "HLA-A"]$freq, 100 * ovl[locus == "HLA-B"]$freq,
                          100 * ovl[locus == "HLA-C"]$freq),
       x = NULL, y = "Locus-specific LOH (%)") +
  theme_pub() +
  theme(axis.text.y = element_text(size = AXT),
        legend.position = "top", legend.direction = "horizontal",
        legend.text = element_text(size = 5.2), legend.title = element_text(size = 5.4),
        legend.key.size = unit(0.24, "cm"))

dc <- fread(file.path(IMD, "fig1c_purity_decile.tsv"))
XL <- c(0.5, 10.5); YL <- c(0, 75)
qcd <- fread(file.path(V2, "REVIEWER3_part4_armindependent_QC.tsv"))
trend_p <- unique(qcd[block == "T2_purity_decile_trend" & grepl("^pur_f_", group_or_term)]$p)
nb <- note_box(c(sprintf("Arm-independent HLA LOH: 1,644/5,805 = %.1f%% of 6p-judgeable tumours",
                         100 * 1644 / 5805),
                 "6p-supported high-confidence frequency across the cohort:",
                 "14.0% (4,161/29,799)",
                 sprintf("Purity-decile trend P = %.1e (decreasing)", trend_p)),
               plot_w_in = 5.4, plot_h_in = 2.2, xlim = XL, ylim = YL,
               x_center_norm = 74, y_top_norm = 66, fontsize = 5.2)
p1c <- ggplot(dc, aes(x = dec, y = pct_armind)) +
  geom_line(colour = PAL[["grey"]], linewidth = 0.45) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.2, colour = "grey45", linewidth = 0.32) +
  geom_point(size = 1.6, colour = PAL[["navy"]]) +
  geom_hline(yintercept = 100 * 4161 / 29799, linetype = "dashed",
             colour = PAL[["red"]], linewidth = 0.45) +
  annotate("text", x = 1, y = 16.6, hjust = 0, vjust = 0.5,
           label = "dashed line: 6p-supported frequency 14.0%",
           size = 5.0 / 2.845, colour = PAL[["red"]]) +
  annotate("text", x = 1.2, y = 60.4, hjust = 0, vjust = 0.5,
           label = sprintf("D1: %.1f%%", dc[dec == 1]$pct_armind),
           size = 5.0 / 2.845, colour = "grey10") +
  annotate("text", x = 9.9, y = 5.0, hjust = 1, vjust = 0.5,
           label = sprintf("D10: %.1f%%", dc[dec == 10]$pct_armind),
           size = 5.0 / 2.845, colour = "grey10") +
  scale_x_continuous(breaks = 1:10,
                     labels = sprintf("D%d\n%.0f%%", dc$dec, 100 * dc$purity_med)) +
  coord_cartesian(xlim = XL, ylim = YL, clip = "off") +
  labs(title = "C  The \u201Carm-independent\u201D HLA LOH fraction collapses with tumour purity",
       x = "Tumour purity decile (median FACETS purity below)",
       y = "Arm-independent HLA LOH (% of judgeable)",
       subtitle = "Judging whether an allele-specific call is explained by 6p arm loss is only possible where 6p is callable (5,805/7,554 HLA-LOH tumours)") +
  nb$rect + nb$text +
  theme_pub()


# 标题/副标题按可用宽度自动折行（防溢出画布）
p1a <- wrap_headers(p1a, F1W)
p1b <- wrap_headers(p1b, F1W)
p1c <- wrap_headers(p1c, F1W)

fig1 <- p1a / p1b / p1c + plot_layout(heights = c(1, 0.78, 0.66))
cat("Figure 1 note-box layout (flow_layout):\n"); print(nb$layout)
cat(sprintf("  note fontsize = %.2f pt\n", nb$fontsize))

qa_emit("Figure1", p1a, F1W, F1H * 1 / 2.44, tag = "Fig1A", fs = AXT)
qa_emit("Figure1", p1b, F1W, F1H * 0.78 / 2.44, tag = "Fig1B", fs = AXT)
qa_emit("Figure1", p1c, F1W, F1H * 0.66 / 2.44, tag = "Fig1C", fs = 5.2)
save_pub2(fig1, "Figure1_pancancer_and_reliability", F1W, F1H)
