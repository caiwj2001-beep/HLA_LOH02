###############################################################################
# 70_figS2.R — Supplementary Figure S2: 胚系合子性与 HLA LOH 可评估性
#   （修回重编号：原 60_figS1.R / Supplementary Figure S1 —— 胚系图在正文首现晚于 APOBEC 图，
#     改挂 Supplementary Figure S2。面板 A/B/C 与全部数字不变。）
#   A 位点 × 合子性的可评估率（纯合位点 0%）
#   B 合子性负担（0/1/2 个纯合位点）与体细胞 HLA LOH 频率
#   C 每增加一个纯合位点的 OR（未校正/校正）—— 方法学下限陈述
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))

SW <- 6.85; SH <- 5.4
ev <- fread(file.path(IMD, "figs1_evaluability.tsv"))
dose <- fread(file.path(IMD, "figs1_burden_dose.tsv"))
mod <- fread(file.path(IMD, "figs1_models.tsv"))

eva <- melt(ev, id.vars = "locus",
            measure.vars = list(pct = c("het_eval_pct", "hom_eval_pct"),
                                n = c("het_n", "hom_n")))
eva[, zyg := c("heterozygous", "homozygous")[variable]]
eva[, zyg := factor(zyg, levels = c("heterozygous", "homozygous"))]
eva[, lab := ifelse(variable == 1,
                    sprintf("%.1f%%\n(n=%s)", pct, format(n, big.mark = ",")),
                    sprintf("%.0f%%\n(n=%s)", pct, format(n, big.mark = ",")))]
pS1a <- ggplot(eva, aes(x = locus, y = pct, fill = zyg)) +
  geom_col(position = position_dodge(0.7), width = 0.6) +
  geom_text(aes(y = pmax(pct, 2.5) + 2.0, label = lab), position = position_dodge(0.7),
            vjust = 0.1, size = 4.6 / 2.845, colour = "grey15", lineheight = 0.9) +
  scale_fill_manual(values = c("heterozygous" = PAL[["navy"]], "homozygous" = PAL[["grey"]]),
                    name = "Germline zygosity") +
  scale_y_continuous(limits = c(0, 88), breaks = seq(0, 80, 20)) +
  labs(title = "A  Evaluability of somatic HLA LOH",
       subtitle = "Homozygous loci are never callable (tautological, not biological)",
       x = NULL, y = "Evaluable for HLA LOH (%)") +
  theme_pub() +
  theme(legend.position = "top", legend.text = element_text(size = 5.2),
        legend.key.size = unit(0.22, "cm"), legend.title = element_text(size = 5.2))

pS1b <- ggplot(dose, aes(x = factor(gh_burden), y = pct)) +
  geom_col(fill = PAL[["teal"]], width = 0.5) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.16, colour = "grey30", linewidth = 0.35) +
  geom_text(aes(label = sprintf("%.1f%%\nn=%s", pct, format(n, big.mark = ","))),
            vjust = -0.35, size = 4.8 / 2.845, colour = "grey15", lineheight = 0.9) +
  scale_y_continuous(limits = c(0, 36), breaks = seq(0, 30, 10)) +
  labs(title = "B  Somatic HLA LOH by germline homozygosity burden",
       subtitle = "One tumour per patient; bars = Wilson 95% CI",
       x = "Homozygous germline HLA class I loci (0/1/2)", y = "HLA LOH frequency (%)") +
  theme_pub()

dtC <- data.table(label = c("Unadjusted", "Adjusted (TMB, WGD,\nage, sex, cancer)"),
                  est = mod$OR, lo = mod$lo, hi = mod$hi, P = mod$P,
                  group = c("Unadjusted", "Adjusted"), is_null = FALSE)
pS1c <- forest_panel(dtC, xlim = c(0.70, 1.0), vline = 1, logx = TRUE, txt_cex = 4.8,
                     lab_size = 5.0,
                     col_map = c("Unadjusted" = PAL[["navy"]], "Adjusted" = PAL[["teal"]]),
                     title = "C  Odds ratio per homozygous locus",
                     xlab = "Odds ratio for HLA LOH (log scale)") +
  theme(axis.text.y = element_text(size = 5.0))


# 标题/副标题按可用宽度自动折行（防溢出画布）
pS1a <- wrap_headers(pS1a, SW / 2 * 1.02)
pS1b <- wrap_headers(pS1b, SW / 2 * 0.98)
pS1c <- wrap_headers(pS1c, SW)

figS1 <- (pS1a | pS1b) / pS1c + plot_layout(heights = c(1, 0.62))
qa_emit("FigureS2", pS1a, SW / 2 * 1.02, SH * 1 / 1.62, tag = "FigS2A", fs = 4.8)
qa_emit("FigureS2", pS1b, SW / 2 * 0.98, SH * 1 / 1.62, tag = "FigS2B", fs = 4.8)
qa_emit("FigureS2", pS1c, SW, SH * 0.62 / 1.62, tag = "FigS2C", fs = 4.8)
save_pub2(figS1, "SupplementaryFigureS2_germline", SW, SH)
