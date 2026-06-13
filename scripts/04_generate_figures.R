#!/usr/bin/env Rscript
# HLA_LOH02 — Publication Figure Generation
# Target: 8 main figures + Extended Data
# Output: PDF, PNG, and TIFF at 300-600 dpi

.libPaths(c("/home/caiwj2001/R/library", .libPaths()))

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(survival)
  library(RColorBrewer)
})

setwd("/home/caiwj2001/HLA_LOH02")
DATA_DIR <- "msk_impact_50k_2026"
FIG_DIR <- "results/figures"
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

# Load pre-processed data (from earlier analysis)
hla_raw <- fread(file.path(DATA_DIR, "data_hla_loh.txt"), sep = "\t")
clin_s <- fread(file.path(DATA_DIR, "data_clinical_sample.txt"), sep = "\t", skip = 4)
clin_p <- fread(file.path(DATA_DIR, "data_clinical_patient.txt"), sep = "\t", skip = 4)

# Aggregate HLA LOH
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
hla_wide[, `:=`(
  HLA_ANY_LOH = `HLA-A` | `HLA-B` | `HLA-C`,
  HLA_N_LOH = as.integer(`HLA-A`) + as.integer(`HLA-B`) + as.integer(`HLA-C`)
)]

# Merge
m <- merge(clin_s, hla_wide, by = "SAMPLE_ID", all.x = TRUE)
m <- merge(m, clin_p[, .(PATIENT_ID, OS_STATUS, OS_MONTHS, ANCESTRY_LABEL, AGE_AT_DX, SEX)],
           by = "PATIENT_ID", all.x = TRUE)
m[, OS_STATUS_BIN := fifelse(OS_STATUS == "DECEASED", 1L, 0L)]
m[, OS_MONTHS_NUM := as.numeric(OS_MONTHS)]
m[, TMB_NUM := as.numeric(TMB_SCORE)]
m_hla <- m[!is.na(HLA_ANY_LOH)]

# Theme
theme_nm <- theme_bw(base_size = 11) + theme(
  panel.grid.minor = element_blank(),
  panel.grid.major = element_line(size = 0.2),
  plot.title = element_text(face = "bold", size = 13),
  plot.subtitle = element_text(size = 10, color = "grey40"),
  legend.position = "bottom",
  strip.background = element_rect(fill = "grey95"),
  strip.text = element_text(size = 9)
)

# Palette
pal_loh <- c("FALSE" = "#4575b4", "TRUE" = "#d73027")

save_fig <- function(p, name, w = 8, h = 6) {
  for (fmt in c("pdf", "png", "tiff")) {
    fn <- file.path(FIG_DIR, paste0(name, ".", if(fmt=="tiff") "tif" else fmt))
    if (fmt == "tiff") {
      ggsave(fn, p, width = w, height = h, dpi = 600, device = "tiff", compression = "lzw")
    } else if (fmt == "png") {
      ggsave(fn, p, width = w, height = h, dpi = 300)
    } else {
      ggsave(fn, p, width = w, height = h)
    }
  }
  cat(sprintf("  Saved: %s.{pdf,png,tif}\n", name))
}

# ═══════════════════════════════════════
# FIGURE 1: Pan-Cancer HLA LOH Frequency
# ═══════════════════════════════════════
cat("Figure 1: Pan-cancer HLA LOH landscape\n")

cancer_freq <- m_hla[, .(
  N = .N,
  Pct_LOH = 100 * mean(HLA_ANY_LOH),
  Pct_A = 100 * mean(`HLA-A`),
  Pct_B = 100 * mean(`HLA-B`),
  Pct_C = 100 * mean(`HLA-C`)
), by = CANCER_TYPE][N >= 50][order(-Pct_LOH)]

# Top 25
top25 <- cancer_freq[1:25]
top25[, CANCER_TYPE := factor(CANCER_TYPE, levels = rev(top25$CANCER_TYPE))]

p1 <- ggplot(top25, aes(x = CANCER_TYPE, y = Pct_LOH)) +
  geom_bar(stat = "identity", fill = "#d73027", alpha = 0.85, width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", Pct_LOH)), hjust = -0.1, size = 2.8) +
  coord_flip(ylim = c(0, 65)) +
  labs(title = "Pan-Cancer Frequency of HLA Class I LOH",
       subtitle = "MSK-IMPACT 50K Cohort — 29,799 tumors with HLA LOH data",
       x = "", y = "HLA Class I LOH (%)") +
  theme_nm

save_fig(p1, "Fig1_pancancer_landscape", 10, 7)

# ═══════════════════════════════════════
# FIGURE 2: Locus-specific LOH patterns
# ═══════════════════════════════════════
cat("Figure 2: Locus-specific patterns\n")

locus_long <- melt(m_hla, id.vars = "CANCER_TYPE", 
                    measure.vars = c("HLA-A", "HLA-B", "HLA-C"),
                    variable.name = "Locus", value.name = "LOH")

locus_summary <- locus_long[, .(Pct_LOH = 100 * mean(LOH)), 
                             by = .(CANCER_TYPE, Locus)]

# Filter to top cancers and reshape
locus_wide <- dcast(locus_summary, CANCER_TYPE ~ Locus, value.var = "Pct_LOH")
locus_wide <- locus_wide[CANCER_TYPE %in% top25$CANCER_TYPE]
locus_long2 <- melt(locus_wide, id.vars = "CANCER_TYPE", variable.name = "Locus", value.name = "Pct_LOH")
locus_long2[, CANCER_TYPE := factor(CANCER_TYPE, levels = rev(levels(top25$CANCER_TYPE)))]

p2 <- ggplot(locus_long2, aes(x = CANCER_TYPE, y = Pct_LOH, fill = Locus)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  coord_flip() +
  scale_fill_manual(values = c("HLA-A" = "#d73027", "HLA-B" = "#4575b4", "HLA-C" = "#fee090"),
                    labels = c("HLA-A", "HLA-B", "HLA-C")) +
  labs(title = "HLA LOH Frequency by Locus Across Cancer Types",
       x = "", y = "LOH Rate (%)", fill = "") +
  theme_nm

save_fig(p2, "Fig2_locus_specific", 10, 7)

# ═══════════════════════════════════════
# FIGURE 3: TMB by HLA LOH Status
# ═══════════════════════════════════════
cat("Figure 3: TMB association\n")

p3 <- ggplot(m_hla[!is.na(TMB_NUM) & TMB_NUM > 0 & TMB_NUM < 100], 
       aes(x = factor(HLA_ANY_LOH, labels = c("HLA LOH\u2212", "HLA LOH+")), 
           y = TMB_NUM + 0.01, fill = HLA_ANY_LOH)) +
  geom_violin(alpha = 0.5, draw_quantiles = 0.5) +
  geom_boxplot(width = 0.12, alpha = 0.8, outlier.size = 0.5) +
  scale_y_log10() +
  scale_fill_manual(values = pal_loh, guide = "none") +
  labs(title = "Tumor Mutational Burden by HLA LOH Status",
       subtitle = sprintf("Wilcoxon P = %.1e; median: LOH+ %.1f vs LOH\u2212 %.1f mut/Mb", 
           7.77e-55, median(m_hla[HLA_ANY_LOH==TRUE]$TMB_NUM, na.rm=TRUE),
           median(m_hla[HLA_ANY_LOH==FALSE]$TMB_NUM, na.rm=TRUE)),
       x = "", y = expression(TMB~(mutations/Mb))) +
  theme_nm

save_fig(p3, "Fig3_TMB_by_LOH", 7, 6)

# ═══════════════════════════════════════
# FIGURE 4: LOH locus count distribution
# ═══════════════════════════════════════
cat("Figure 4: Locus count distribution\n")

locus_dist <- m_hla[, .N, by = HLA_N_LOH][order(HLA_N_LOH)]
locus_dist[, Pct := 100 * N / sum(N)]
locus_dist[, Label := paste0(N, "\n(", sprintf("%.1f", Pct), "%)")]

p4 <- ggplot(locus_dist, aes(x = factor(HLA_N_LOH), y = Pct)) +
  geom_bar(stat = "identity", fill = c("#4575b4", "#91bfdb", "#fc8d59", "#d73027"), width = 0.6) +
  geom_text(aes(label = Label), vjust = -0.2, size = 3.5) +
  labs(title = "Distribution of HLA LOH Locus Count",
       subtitle = "Among 29,799 tumors with HLA data",
       x = "Number of HLA Loci with LOH", y = "% of Tumors") +
  theme_nm + theme(panel.grid.major.x = element_blank())

save_fig(p4, "Fig4_locus_distribution", 6, 5)

# ═══════════════════════════════════════
# FIGURE 5: WGD Association
# ═══════════════════════════════════════
cat("Figure 5: WGD association\n")

m_wgd <- m_hla[!is.na(FACETS_WGD) & FACETS_WGD != "NA"]
wgd_data <- m_wgd[, .(
  WGD_Rate = 100 * mean(FACETS_WGD == "TRUE"),
  N = .N
), by = .(HLA_LOH = factor(HLA_ANY_LOH, labels = c("HLA LOH\u2212", "HLA LOH+")))]

# Also by cancer type
wgd_cancer <- m_wgd[, .(
  WGD_LOH_pos = 100 * mean(FACETS_WGD[HLA_ANY_LOH == TRUE] == "TRUE"),
  WGD_LOH_neg = 100 * mean(FACETS_WGD[HLA_ANY_LOH == FALSE] == "TRUE"),
  Delta = 100 * mean(FACETS_WGD[HLA_ANY_LOH == TRUE] == "TRUE") - 
          100 * mean(FACETS_WGD[HLA_ANY_LOH == FALSE] == "TRUE"),
  N_LOH = sum(HLA_ANY_LOH)
), by = CANCER_TYPE][N_LOH >= 20][order(-Delta)]

p5a <- ggplot(wgd_data, aes(x = HLA_LOH, y = WGD_Rate, fill = HLA_LOH)) +
  geom_bar(stat = "identity", width = 0.5) +
  geom_text(aes(label = sprintf("%.1f%%", WGD_Rate)), vjust = -0.3, size = 4.5) +
  scale_fill_manual(values = pal_loh, guide = "none") +
  labs(title = "WGD Rate by HLA LOH Status",
       subtitle = sprintf("Fisher P = %.0e", 2.00e-245),
       x = "", y = "Whole Genome Doubling (%)") +
  theme_nm

p5b <- ggplot(wgd_cancer[abs(Delta) > 0][1:15], 
       aes(x = reorder(CANCER_TYPE, Delta), y = Delta)) +
  geom_bar(stat = "identity", fill = ifelse(wgd_cancer$Delta[1:15] > 0, "#d73027", "#4575b4"), width = 0.7) +
  coord_flip() +
  labs(title = "WGD Enrichment in HLA LOH+ Tumors by Cancer Type",
       x = "", y = expression(Delta~WGD~Rate~(LOH^"+" - LOH^"-")~"(pp)")) +
  theme_nm

p5 <- gridExtra::grid.arrange(p5a, p5b, ncol = 2, widths = c(2, 3))
save_fig(p5, "Fig5_WGD_association", 12, 6)

# ═══════════════════════════════════════
# FIGURE 6: Kaplan-Meier Survival Curves
# ═══════════════════════════════════════
cat("Figure 6: Survival curves\n")

surv_primary <- m_hla[SAMPLE_TYPE == "Primary" & !is.na(OS_MONTHS_NUM) & OS_MONTHS_NUM >= 0]

fit <- survfit(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH, data = surv_primary)

# Extract KM data for ggplot
km_data <- data.frame(
  time = fit$time,
  surv = fit$surv,
  lower = fit$lower,
  upper = fit$upper,
  strata = rep(c("HLA LOH\u2212", "HLA LOH+"), fit$strata)
)

# Log-rank p-value
sdiff <- survdiff(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH, data = surv_primary)
pval_km <- 1 - pchisq(sdiff$chisq, 1)

# Risk table
risk_table <- data.frame()
for (t in c(0, 12, 24, 36, 48, 60)) {
  for (grp in c("HLA LOH\u2212", "HLA LOH+")) {
    sub <- surv_primary[(grp == "HLA LOH+") == HLA_ANY_LOH]
    n_risk <- sum(sub$OS_MONTHS_NUM >= t)
    risk_table <- rbind(risk_table, data.frame(time = t, strata = grp, n_risk = n_risk))
  }
}

p6 <- ggplot(km_data, aes(x = time, y = surv, color = strata, fill = strata)) +
  geom_step(size = 1) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.15, color = NA) +
  scale_color_manual(values = c("HLA LOH\u2212" = "#4575b4", "HLA LOH+" = "#d73027")) +
  scale_fill_manual(values = c("HLA LOH\u2212" = "#4575b4", "HLA LOH+" = "#d73027")) +
  annotate("text", x = max(km_data$time)*0.7, y = 0.85, 
           label = sprintf("Log-rank P = %.3f", pval_km), size = 4) +
  labs(title = "Overall Survival by HLA LOH Status (Primary Tumors)",
       x = "Time (months)", y = "Overall Survival Probability",
       color = "", fill = "") +
  scale_x_continuous(breaks = seq(0, 72, 12)) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  theme_nm

save_fig(p6, "Fig6_KM_survival", 8, 6)

# ═══════════════════════════════════════
# FIGURE 7: Forest Plot — Cox by Cancer Type
# ═══════════════════════════════════════
cat("Figure 7: Forest plot\n")

# Cox HR per cancer type
forest_data <- data.table()
for (ct in cancer_freq[N >= 100, CANCER_TYPE]) {
  sub <- surv_primary[CANCER_TYPE == ct]
  if (nrow(sub) >= 50 && sum(sub$HLA_ANY_LOH) >= 10 && sum(sub$OS_STATUS_BIN) >= 20) {
    tryCatch({
      cox <- coxph(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH + TMB_NUM, data = sub)
      hr <- exp(coef(cox)["HLA_ANY_LOHTRUE"])
      ci <- exp(confint(cox)["HLA_ANY_LOHTRUE", ])
      forest_data <- rbind(forest_data, data.table(
        CANCER_TYPE = ct, HR = hr, Lower = ci[1], Upper = ci[2],
        N = nrow(sub), Events = sum(sub$OS_STATUS_BIN)
      ))
    }, error = function(e) NULL)
  }
}

forest_data <- forest_data[order(HR)]

p7 <- ggplot(forest_data, aes(x = HR, y = reorder(CANCER_TYPE, HR))) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
  geom_point(size = 2, color = "#d73027") +
  geom_errorbarh(aes(xmin = Lower, xmax = Upper), height = 0.2, color = "#d73027") +
  scale_x_log10(breaks = c(0.3, 0.5, 1, 2, 3, 5)) +
  labs(title = "HLA LOH Effect on Overall Survival (TMB-adjusted)",
       subtitle = "Hazard Ratios by Cancer Type",
       x = "Hazard Ratio (HLA LOH+ vs LOH\u2212)", y = "") +
  theme_nm

save_fig(p7, "Fig7_forest_plot", 8, 7)

# ═══════════════════════════════════════
# FIGURE 8: Combined Biomarker Model
# ═══════════════════════════════════════
cat("Figure 8: Combined biomarker\n")

surv_comb <- surv_primary[!is.na(TMB_NUM) & !is.na(FACETS_WGD) & FACETS_WGD != "NA"]
surv_comb[, `:=`(
  Group4 = paste0(
    fifelse(HLA_ANY_LOH, "HLA LOH+", "HLA LOH\u2212"), ", ",
    fifelse(TMB_NUM >= 10, "TMB-H", "TMB-L")
  )
)]

fit4 <- survfit(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ Group4, data = surv_comb)
groups4 <- sort(unique(surv_comb$Group4))

km4_data <- data.frame(
  time = fit4$time,
  surv = fit4$surv,
  lower = fit4$lower,
  upper = fit4$upper,
  strata = rep(groups4, fit4$strata)
)

pal4 <- c("HLA LOH\u2212, TMB-L" = "#91bfdb", "HLA LOH\u2212, TMB-H" = "#4575b4",
          "HLA LOH+, TMB-L" = "#fc8d59", "HLA LOH+, TMB-H" = "#d73027")

p8 <- ggplot(km4_data, aes(x = time, y = surv, color = strata)) +
  geom_step(size = 1) +
  scale_color_manual(values = pal4) +
  labs(title = "Combined HLA LOH and TMB Stratification",
       x = "Time (months)", y = "Overall Survival Probability",
       color = "") +
  scale_x_continuous(breaks = seq(0, 72, 12)) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  theme_nm

save_fig(p8, "Fig8_combined_biomarker", 8, 6)

cat(sprintf("\n=== All figures saved to %s/ ===\n", FIG_DIR))
cat(sprintf("Formats: PDF + PNG (300dpi) + TIFF (600dpi LZW)\n"))
