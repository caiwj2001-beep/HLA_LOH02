###############################################################################
# 30_fig3.R — Figure 3: 机制（远端/近端驱动因素、WGD→6p 中介、41 臂 × TMB 排名）
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))

F3W <- 6.85; F3H <- 7.4

## ---------- A 驱动因素森林图 ----------
d3a <- fread(file.path(IMD, "fig3a_drivers.tsv"))
dtA <- data.table(
  label = c("WGD (\u2192 distal driver)",
            "Germline HLA homozygosity (distal driver)",
            "log10 TMB (distal driver)",
            "6p arm loss (proximal, near-definitional)"),
  est = d3a$OR, lo = d3a$lo, hi = d3a$hi, P = d3a$P,
  group = c("Distal model: WGD + germline + TMB + purity + panel + cancer type",
            "Distal model: WGD + germline + TMB + purity + panel + cancer type",
            "Distal model: WGD + germline + TMB + purity + panel + cancer type",
            "Proximal model: 6p loss + cancer type"))
dtA[, is_null := FALSE]
p3a <- forest_panel(dtA, xlim = c(0.5, 400), vline = 1, logx = TRUE, txt_cex = 5.2, lab_size = 5.6,
                    col_map = c("Distal model: WGD + germline + TMB + purity + panel + cancer type" = PAL[["navy"]],
                                "Proximal model: 6p loss + cancer type" = PAL[["red"]]),
                    title = "A  Drivers of HLA LOH: distal (upstream biology) versus proximal (6p21.3) models",
                    xlab = "Odds ratio for HLA LOH (log scale; 6p is near-definitional)")

## ---------- B WGD → 6p → HLA LOH 中介 ----------
md <- fread(file.path(IMD, "fig3b_mediation.tsv"))
md[, ord := match(Quantity, c("ACME (indirect, via 6p)", "ADE (direct)", "Total effect"))]
md <- md[!is.na(ord)]
setorder(md, ord)
dtB <- data.table(label = c("ACME: indirect effect via 6p arm loss",
                            "ADE: direct effect of WGD",
                            "Total effect of WGD"),
                  est = md$Estimate[1:3], lo = md$CI_low[1:3], hi = md$CI_high[1:3],
                  P = NA_real_, group = "Mediation decomposition",
                  is_null = FALSE)
dtB[, y := rev(seq_len(.N))]
XL3B <- c(-0.14, 0.34); YL3B <- c(0.4, 5.2)
nbB <- note_box(c(sprintf("Proportion mediated = %.2f (>1 indicates suppression:",
                          md[Quantity == "Proportion mediated"]$Estimate),
                  "the direct and indirect paths act in opposite directions)"),
                plot_w_in = 5.0, plot_h_in = 1.6, xlim = XL3B, ylim = YL3B,
                x_center_norm = 55, y_top_norm = 94, fontsize = 5.2)
p3b <- forest_panel(dtB, xlim = XL3B, vline = 0, logx = FALSE, txt_cex = 5.2, lab_size = 5.6,
                    col_map = c("Mediation decomposition" = PAL[["teal"]]),
                    title = "B  WGD acts on HLA LOH mainly through 6p arm loss (mediation on the probability scale)",
                    xlab = "Effect size (difference in probability of HLA LOH)") +
  scale_y_continuous(breaks = dtB$y, labels = dtB$label, limits = YL3B) +
  nbB$rect + nbB$text

## ---------- C 41 条臂 × TMB 关联排名 ----------
d3c <- fread(file.path(IMD, "fig3c_arm_tmb_rank.tsv"))
setorder(d3c, rank_tmb)
d3c[, arm_f := factor(arm, levels = arm)]
d3c[, hl := ifelse(arm == "6p", "6p (rank 26/41)", ifelse(rank_tmb == 1, "17p (rank 1/41)", "other arms"))]
p3c <- ggplot(d3c, aes(x = arm_f, y = beta_loss, colour = hl)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  geom_segment(aes(xend = arm_f, yend = 0), linewidth = 0.3, colour = "grey75") +
  geom_point(size = 1.25) +
  annotate("text", x = 1, y = 0.132, hjust = 0, size = 5.2 / 2.845, colour = PAL[["red"]],
           label = "17p: strongest arm\u2013TMB association (rank 1/41)") +
  annotate("text", x = 26, y = 0.105, hjust = 1, size = 5.2 / 2.845, colour = PAL[["navy"]],
           label = "6p: rank 26/41 \u2014 not the arm most associated with TMB") +
  scale_colour_manual(values = c("6p (rank 26/41)" = PAL[["navy"]],
                                 "17p (rank 1/41)" = PAL[["red"]],
                                 "other arms" = PAL[["grey"]]), name = NULL) +
  scale_y_continuous(limits = c(-0.01, 0.145), breaks = seq(0, 0.12, 0.03)) +
  labs(title = "C  All 41 chromosome arms ranked by their association with TMB",
       subtitle = "Linear model: log10(TMB + 0.1) ~ arm loss + cancer type; arms ordered by P value",
       x = "Chromosome arm (ordered by association rank)", y = "beta (log10 TMB per arm loss)") +
  theme_pub() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 5.4),
        legend.position = "top", legend.text = element_text(size = 5.4),
        legend.key.size = unit(0.24, "cm"))


# 标题/副标题按可用宽度自动折行（防溢出画布）
p3a <- wrap_headers(p3a, F3W)
p3b <- wrap_headers(p3b, F3W)
p3c <- wrap_headers(p3c, F3W)

fig3 <- p3a / p3b / p3c + plot_layout(heights = c(0.95, 0.85, 1.15))
cat("Fig3B note-box layout (flow_layout):\n"); print(nbB$layout)
qa_emit("Figure3", p3a, F3W, F3H * 0.95 / 2.95, tag = "Fig3A", fs = 5.2)
qa_emit("Figure3", p3b, F3W, F3H * 0.85 / 2.95, tag = "Fig3B", fs = 5.2)
qa_emit("Figure3", p3c, F3W, F3H * 1.15 / 2.95, tag = "Fig3C", fs = 5.4)
save_pub2(fig3, "Figure3_mechanism_armlandscape", F3W, F3H)
