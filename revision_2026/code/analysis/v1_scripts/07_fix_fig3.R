1|1|1|#!/usr/bin/env Rscript
2|2|2|# Fix Fig4 (TMB — matches manuscript Fig. 4) — replace confusing violin+box+log with cleaner boxplot
3|3|3|.libPaths(c("/home/caiwj2001/R/library", .libPaths()))
4|4|4|
5|5|5|suppressPackageStartupMessages({
6|6|6|  library(data.table)
7|7|7|  library(ggplot2)
8|8|8|})
9|9|9|
10|10|10|setwd("/home/caiwj2001/HLA_LOH02")
11|11|11|DATA_DIR <- "msk_impact_50k_2026"
12|12|12|FIG_DIR <- "results/figures"
13|13|13|
14|14|14|theme_nm <- theme_bw(base_size = 11) + theme(
15|15|15|  panel.grid.minor = element_blank(),
16|16|16|  panel.grid.major = element_line(size = 0.2),
17|17|17|  plot.title = element_text(face = "bold", size = 13, family = "sans"),
18|18|18|  plot.subtitle = element_text(size = 10, color = "grey40", family = "sans"),
19|19|19|  axis.text = element_text(family = "sans", size = 9),
20|20|20|  axis.title = element_text(family = "sans", size = 10)
21|21|21|)
22|22|22|
23|23|23|# Load and merge data (same as before)
24|24|24|hla_raw <- fread(file.path(DATA_DIR, "data_hla_loh.txt"), sep = "\t")
25|25|25|clin_s <- fread(file.path(DATA_DIR, "data_clinical_sample.txt"), sep = "\t", skip = 4)
26|26|26|clin_p <- fread(file.path(DATA_DIR, "data_clinical_patient.txt"), sep = "\t", skip = 4)
27|27|27|
28|28|28|hla_long <- melt(hla_raw, id.vars = c("ENTITY_STABLE_ID", "HLA_GENE"),
29|29|29|                 variable.name = "SAMPLE_ID", value.name = "STATUS")
30|30|30|hla_long <- hla_long[STATUS %in% c("Loss", "Unchanged")]
31|31|31|hla_gene <- hla_long[, .(HAS_LOSS = any(STATUS == "Loss")),
32|32|32|                     by = .(SAMPLE_ID, HLA_GENE)]
33|33|33|hla_wide <- dcast(hla_gene, SAMPLE_ID ~ HLA_GENE, value.var = "HAS_LOSS")
34|34|34|for (col in c("HLA-A", "HLA-B", "HLA-C")) {
35|35|35|  if (!(col %in% names(hla_wide))) hla_wide[, (col) := FALSE]
36|36|36|  set(hla_wide, i = which(is.na(hla_wide[[col]])), j = col, value = FALSE)
37|37|37|}
38|38|38|hla_wide[, HLA_ANY_LOH := `HLA-A` | `HLA-B` | `HLA-C`]
39|39|39|
40|40|40|m <- merge(clin_s, hla_wide, by = "SAMPLE_ID", all.x = TRUE)
41|41|41|m_hla <- m[!is.na(HLA_ANY_LOH)]
42|42|42|m_hla[, TMB_NUM := as.numeric(TMB_SCORE)]
43|43|43|
44|44|44|# Filter: valid TMB
45|45|45|tmb_data <- m_hla[!is.na(TMB_NUM) & TMB_NUM > 0]
46|46|46|tmb_data[, LOH_GROUP := factor(HLA_ANY_LOH, 
47|47|47|  levels = c(FALSE, TRUE), labels = c("HLA LOH\u2212", "HLA LOH+"))]
48|48|48|
49|49|49|# ── Fig 4a: Clean boxplot (linear scale, truncated at 30) ──
50|50|50|cat("Generating Fig 4a (clean boxplot)...\n")
51|51|51|
52|52|52|med_pos <- median(tmb_data[HLA_ANY_LOH == TRUE, TMB_NUM], na.rm = TRUE)
53|53|53|med_neg <- median(tmb_data[HLA_ANY_LOH == FALSE, TMB_NUM], na.rm = TRUE)
54|54|54|wt <- wilcox.test(tmb_data[HLA_ANY_LOH == TRUE, TMB_NUM],
55|55|55|                  tmb_data[HLA_ANY_LOH == FALSE, TMB_NUM])
56|56|56|
57|57|57|p3a <- ggplot(tmb_data, aes(x = LOH_GROUP, y = TMB_NUM, fill = LOH_GROUP)) +
58|58|58|  geom_boxplot(outlier.size = 0.5, outlier.alpha = 0.3, width = 0.5, alpha = 0.85) +
59|59|59|  scale_fill_manual(values = c("HLA LOH\u2212" = "#4575b4", "HLA LOH+" = "#d73027"), guide = "none") +
60|60|60|  annotate("text", x = 1.5, y = 28, 
61|61|61|           label = sprintf("Wilcoxon P = %.1e", wt$p.value), size = 3.5, fontface = "italic") +
62|62|62|  annotate("text", x = 1, y = med_neg + 2, label = sprintf("Median\n%.1f", med_neg), 
63|63|63|           size = 3.5, color = "#4575b4", fontface = "bold") +
64|64|64|  annotate("text", x = 2, y = med_pos + 2, label = sprintf("Median\n%.1f", med_pos), 
65|65|65|           size = 3.5, color = "#d73027", fontface = "bold") +
66|66|66|  coord_cartesian(ylim = c(0, 30)) +
67|67|67|  labs(title = "Tumor Mutational Burden by HLA LOH Status",
68|68|68|       subtitle = sprintf("Box plot (linear scale, truncated at 30 mut/Mb). n = %d (LOH+) + %d (LOH\u2212)",
69|69|69|           sum(tmb_data$HLA_ANY_LOH), sum(!tmb_data$HLA_ANY_LOH)),
70|70|70|       x = "", y = expression(TMB~(mutations/Mb))) +
71|71|71|  theme_nm
72|72|72|
73|73|73|for (fmt in c("pdf", "png", "tiff")) {
74|74|74|  fn <- file.path(FIG_DIR, paste0("Fig4_TMB_by_LOH", ".", if(fmt=="tiff") "tif" else fmt))
75|75|75|  if (fmt == "tiff") {
76|76|76|    ggsave(fn, p3a, width = 6, height = 5.5, dpi = 600, device = "tiff", compression = "lzw")
77|77|77|  } else if (fmt == "png") {
78|78|78|    ggsave(fn, p3a, width = 6, height = 5.5, dpi = 300)
79|79|79|  } else {
80|80|80|    ggsave(fn, p3a, width = 6, height = 5.5)
81|81|81|  }
82|82|82|  cat(sprintf("  Saved: %s\n", fn))
83|83|83|}
84|84|84|
85|85|85|cat("Done! Fig4 replaced with clean boxplot version.\n")
86|86|86|