#!/usr/bin/env Rscript
# Fix Fig3 — replace confusing violin+box+log with a cleaner design
.libPaths(c("/home/caiwj2001/R/library", .libPaths()))

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

setwd("/home/caiwj2001/HLA_LOH02")
DATA_DIR <- "msk_impact_50k_2026"
FIG_DIR <- "results/figures"

theme_nm <- theme_bw(base_size = 11) + theme(
  panel.grid.minor = element_blank(),
  panel.grid.major = element_line(size = 0.2),
  plot.title = element_text(face = "bold", size = 13, family = "sans"),
  plot.subtitle = element_text(size = 10, color = "grey40", family = "sans"),
  axis.text = element_text(family = "sans", size = 9),
  axis.title = element_text(family = "sans", size = 10)
)

# Load and merge data (same as before)
hla_raw <- fread(file.path(DATA_DIR, "data_hla_loh.txt"), sep = "\t")
clin_s <- fread(file.path(DATA_DIR, "data_clinical_sample.txt"), sep = "\t", skip = 4)
clin_p <- fread(file.path(DATA_DIR, "data_clinical_patient.txt"), sep = "\t", skip = 4)

hla_long <- melt(hla_raw, id.vars = c("ENTITY_STABLE_ID", "HLA_GENE"),
                 variable.name = "SAMPLE_ID", value.name = "STATUS")
hla_long <- hla_long[STATUS %in% c("Loss", "Unchanged")]
hla_gene <- hla_long[, .(HAS_LOSS = any(STATUS == "Loss")),
                     by = .(SAMPLE_ID, HLA_GENE)]
hla_wide <- dcast(hla_gene, SAMPLE_ID ~ HLA_GENE, value.var = "HAS_LOSS")
for (col in c("HLA-A", "HLA-B", "HLA-C")) {
  if (!(col %in% names(hla_wide))) hla_wide[, (col) := FALSE]
  set(hla_wide, i = which(is.na(hla_wide[[col]])), j = col, value = FALSE)
}
hla_wide[, HLA_ANY_LOH := `HLA-A` | `HLA-B` | `HLA-C`]

m <- merge(clin_s, hla_wide, by = "SAMPLE_ID", all.x = TRUE)
m_hla <- m[!is.na(HLA_ANY_LOH)]
m_hla[, TMB_NUM := as.numeric(TMB_SCORE)]

# Filter: valid TMB
tmb_data <- m_hla[!is.na(TMB_NUM) & TMB_NUM > 0]
tmb_data[, LOH_GROUP := factor(HLA_ANY_LOH, 
  levels = c(FALSE, TRUE), labels = c("HLA LOH\u2212", "HLA LOH+"))]

# ── Fig 3a: Clean boxplot (linear scale, truncated at 30) ──
cat("Generating Fig 3a (clean boxplot)...\n")

med_pos <- median(tmb_data[HLA_ANY_LOH == TRUE, TMB_NUM], na.rm = TRUE)
med_neg <- median(tmb_data[HLA_ANY_LOH == FALSE, TMB_NUM], na.rm = TRUE)
wt <- wilcox.test(tmb_data[HLA_ANY_LOH == TRUE, TMB_NUM],
                  tmb_data[HLA_ANY_LOH == FALSE, TMB_NUM])

p3a <- ggplot(tmb_data, aes(x = LOH_GROUP, y = TMB_NUM, fill = LOH_GROUP)) +
  geom_boxplot(outlier.size = 0.5, outlier.alpha = 0.3, width = 0.5, alpha = 0.85) +
  scale_fill_manual(values = c("HLA LOH\u2212" = "#4575b4", "HLA LOH+" = "#d73027"), guide = "none") +
  annotate("text", x = 1.5, y = 28, 
           label = sprintf("Wilcoxon P = %.1e", wt$p.value), size = 3.5, fontface = "italic") +
  annotate("text", x = 1, y = med_neg + 2, label = sprintf("Median\n%.1f", med_neg), 
           size = 3.5, color = "#4575b4", fontface = "bold") +
  annotate("text", x = 2, y = med_pos + 2, label = sprintf("Median\n%.1f", med_pos), 
           size = 3.5, color = "#d73027", fontface = "bold") +
  coord_cartesian(ylim = c(0, 30)) +
  labs(title = "Tumor Mutational Burden by HLA LOH Status",
       subtitle = sprintf("Box plot (linear scale, truncated at 30 mut/Mb). n = %d (LOH+) + %d (LOH\u2212)",
           sum(tmb_data$HLA_ANY_LOH), sum(!tmb_data$HLA_ANY_LOH)),
       x = "", y = expression(TMB~(mutations/Mb))) +
  theme_nm

for (fmt in c("pdf", "png", "tiff")) {
  fn <- file.path(FIG_DIR, paste0("Fig3_TMB_by_LOH", ".", if(fmt=="tiff") "tif" else fmt))
  if (fmt == "tiff") {
    ggsave(fn, p3a, width = 6, height = 5.5, dpi = 600, device = "tiff", compression = "lzw")
  } else if (fmt == "png") {
    ggsave(fn, p3a, width = 6, height = 5.5, dpi = 300)
  } else {
    ggsave(fn, p3a, width = 6, height = 5.5)
  }
  cat(sprintf("  Saved: %s\n", fn))
}

cat("Done! Fig3 replaced with clean boxplot version.\n")
