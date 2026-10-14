###############################################################################
# 40_fig4.R — Figure 4（全新）: 新抗原负荷 × HLA LOH
#   A 负荷–LOH OR 森林（5 定义 + 限克隆敏感性）
#   B 等位基因配对条件 logistic OR（全位点 + A/B/C + 敏感性）
#   C 剔除 ties 后“丢失侧更多”占比（0.506/0.518）+ 中位新抗原数 6 vs 7
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))

F4W <- 6.85; F4H <- 7.8

## ---------- A ----------
a4 <- fread(file.path(IMD, "fig4a_neo_or.tsv"))
setorder(a4, -is_null, -OR)
dtA <- data.table(label = a4$label, est = a4$OR, lo = a4$lo, hi = a4$hi, P = a4$P,
                  group = ifelse(a4$is_null, "Restricted to clonal mutations (null)",
                                 "Load \u2013 HLA LOH models (per +1 SD)"),
                  is_null = a4$is_null)
p4a <- forest_panel(dtA, xlim = c(0.95, 1.20), vline = 1, logx = TRUE, txt_cex = 5.2, lab_size = 5.6,
                    col_map = c("Load \u2013 HLA LOH models (per +1 SD)" = PAL[["navy"]],
                                "Restricted to clonal mutations (null)" = PAL[["grey"]]),
                    title = "A  Predicted neoantigen load versus HLA LOH (n = 25,954; HLA LOH+ 6,804)",
                    xlab = "Odds ratio for HLA LOH per +1 SD of neoantigen load (log scale)")

## ---------- B ----------
b4 <- fread(file.path(IMD, "fig4b_neo_pair_or.tsv"))
setorder(b4, -OR)
dtB <- data.table(label = b4$label, est = b4$OR, lo = b4$lo, hi = b4$hi, P = b4$P,
                  group = ifelse(b4$is_null, "All loci (primary, null)",
                                 "Locus-specific / sensitivity analyses"),
                  is_null = b4$is_null)
p4b <- forest_panel(dtB, xlim = c(0.97, 1.065), vline = 1, logx = FALSE, txt_cex = 5.2, lab_size = 5.6,
                    col_map = c("All loci (primary, null)" = PAL[["grey"]],
                                "Locus-specific / sensitivity analyses" = PAL[["teal"]]),
                    title = "B  Allele-resolved, internally paired conditional logistic models (6,817 tumours / 14,157 locus pairs)",
                    xlab = "Odds ratio: binders on the LOST versus the KEPT allele (95% CI)")

## ---------- C ----------
c4 <- fread(file.path(IMD, "fig4c_neo_summary.tsv"))
g <- function(i) c4$value[i]
# 字号下限 6 pt（修回：原 Fig4C 文字为 4.8–5.6 pt，低于 6 pt 下限）
C6 <- 6.0 / 2.845
dc1 <- data.table(
  item = factor(c("All loci", "Clonal mutations only"), levels = c("All loci", "Clonal mutations only")),
  frac = c(g(1), g(2)), n = c(c4$n[1], c4$n[2]))
p4c1 <- ggplot(dc1, aes(x = item, y = 100 * frac)) +
  geom_col(fill = c(PAL[["teal"]], PAL[["grey"]]), width = 0.5) +
  geom_hline(yintercept = 50, linetype = "dashed", colour = PAL[["red"]], linewidth = 0.4) +
  # 参考线标签置于面板上方空白带（原 x=0.72/y=54 与柱顶 "50.6%" 真实墨迹相撞）
  annotate("text", x = 0.55, y = 58.8, hjust = 0, vjust = 0.5, size = C6, colour = PAL[["red"]],
           label = "50% = no asymmetry") +
  geom_text(aes(label = sprintf("%.1f%%", 100 * frac)), vjust = -0.7, size = C6,
            colour = "grey10") +
  geom_text(aes(y = 2, label = sprintf("n = %s", format(n, big.mark = ","))), vjust = 0,
            size = C6, colour = "white") +
  scale_y_continuous(limits = c(0, 62), breaks = seq(0, 60, 20)) +
  labs(title = "C  Direction of the paired comparison (ties excluded)",
       subtitle = "Samples with more predicted binders on the lost allele",
       x = NULL, y = "% of samples with a direction") +
  theme_pub() + theme(axis.text.x = element_text(size = 6))

dc2 <- data.table(
  grp = factor(c("HLA LOH\u2212", "HLA LOH+"), levels = c("HLA LOH\u2212", "HLA LOH+")),
  med = c(g(4), g(5)), n = c(c4$n[4], c4$n[5]))
p4c2 <- ggplot(dc2, aes(x = grp, y = med, fill = grp)) +
  geom_col(width = 0.5) +
  geom_text(aes(label = sprintf("%.0f", med)), vjust = -0.7, size = C6, colour = "grey10") +
  geom_text(aes(y = 0.3, label = sprintf("n = %s", format(n, big.mark = ","))), vjust = 0,
            size = C6, colour = "white") +
  scale_fill_manual(values = c("HLA LOH\u2212" = PAL[["grey"]], "HLA LOH+" = PAL[["navy"]]),
                    guide = "none") +
  scale_y_continuous(limits = c(0, 9), breaks = seq(0, 8, 2)) +
  labs(title = "Median predicted neoantigens", subtitle = "per tumour (all alleles)",
       x = NULL, y = "Median neoantigen count") +
  theme_pub() + theme(axis.text.x = element_text(size = 5.6))


# 标题/副标题按可用宽度自动折行（防溢出画布）
p4a <- wrap_headers(p4a, F4W)
p4b <- wrap_headers(p4b, F4W)
p4c1 <- wrap_headers(p4c1, F4W / 2)
p4c2 <- wrap_headers(p4c2, F4W / 2)

fig4 <- p4a / p4b / (p4c1 | p4c2) + plot_layout(heights = c(1, 1.05, 0.78))
qa_emit("Figure4", p4a, F4W, F4H * 1 / 2.83, tag = "Fig4A", fs = 5.2)
qa_emit("Figure4", p4b, F4W, F4H * 1.05 / 2.83, tag = "Fig4B", fs = 5.2)
qa_emit("Figure4", p4c1, F4W / 2, F4H * 0.78 / 2.83, tag = "Fig4C-left", fs = 5.0)
qa_emit("Figure4", p4c2, F4W / 2, F4H * 0.78 / 2.83, tag = "Fig4C-right", fs = 5.2)
save_pub2(fig4, "Figure4_neoantigen", F4W, F4H)
