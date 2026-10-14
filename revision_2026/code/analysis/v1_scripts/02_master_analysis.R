#!/usr/bin/env Rscript
# HLA_LOH02 — Master Analysis Pipeline v1.0
# ===========================================
# Pan-Cancer HLA Class I LOH Landscape
# Data: MSK-IMPACT 50K Clinical Sequencing Cohort

.libPaths(c("/home/caiwj2001/R/library", .libPaths()))

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(survival)
})

setwd("/home/caiwj2001/HLA_LOH02")
DATA_DIR <- "msk_impact_50k_2026"
RESULTS_DIR <- "results"

cat(sprintf("=== HLA_LOH02 Master Analysis (run: %s) ===\n", Sys.time()))

# =============================================
# 1. LOAD DATA
# =============================================
cat("\n[1/8] Loading data...\n")

# HLA LOH (allele-level)
hla_raw <- fread(file.path(DATA_DIR, "data_hla_loh.txt"), sep = "\t")
cat(sprintf("  HLA LOH: %d rows x %d cols\n", nrow(hla_raw), ncol(hla_raw)))

# Sample clinical data
clin_sample <- fread(file.path(DATA_DIR, "data_clinical_sample.txt"), sep = "\t", skip = 4)
cat(sprintf("  Sample clinical: %d rows x %d cols\n", nrow(clin_sample), ncol(clin_sample)))

# Patient clinical data
clin_patient <- fread(file.path(DATA_DIR, "data_clinical_patient.txt"), sep = "\t", skip = 4)
cat(sprintf("  Patient clinical: %d patients\n", nrow(clin_patient)))

# =============================================
# 2. AGGREGATE HLA LOH TO GENE LEVEL
# =============================================
cat("\n[2/8] Aggregating HLA LOH to gene level...\n")

# Convert from wide allele format to long format (VECTORIZED - much faster)
cat("  Melting to long format...\n")
hla_long <- melt(hla_raw, id.vars = c("ENTITY_STABLE_ID", "HLA_GENE"), 
                 variable.name = "SAMPLE_ID", value.name = "STATUS")
cat(sprintf("  Long format: %d rows\n", nrow(hla_long)))

# Filter to informative calls
hla_long <- hla_long[STATUS %in% c("Loss", "Unchanged")]
hla_long[, IS_LOSS := STATUS == "Loss"]

# Aggregate to gene level: ANY Loss per sample-gene
cat("  Aggregating to gene level...\n")
hla_gene <- hla_long[, .(HAS_LOSS = any(IS_LOSS, na.rm = TRUE)), 
                     by = .(SAMPLE_ID, HLA_GENE)]

# Pivot to wide: one row per sample
hla_wide <- dcast(hla_gene, SAMPLE_ID ~ HLA_GENE, value.var = "HAS_LOSS", fill = FALSE)
hla_wide[, HLA_ANY_LOH := `HLA-A` | `HLA-B` | `HLA-C`]
hla_wide[, HLA_N_LOH := as.integer(`HLA-A`) + as.integer(`HLA-B`) + as.integer(`HLA-C`)]

cat(sprintf("  Samples with HLA data: %d\n", nrow(hla_wide)))
cat(sprintf("  Any HLA LOH: %d (%.1f%%)\n", 
    sum(hla_wide$HLA_ANY_LOH), 100*mean(hla_wide$HLA_ANY_LOH)))

# =============================================
# 3. MERGE WITH CLINICAL DATA
# =============================================
cat("\n[3/8] Merging with clinical data...\n")

# Merge with sample clinical
merged <- merge(clin_sample, hla_wide, by = "SAMPLE_ID", all.x = TRUE)
# Fill missing HLA status
merged[is.na(HLA_ANY_LOH), HLA_ANY_LOH := FALSE]
merged[is.na(`HLA-A`), `HLA-A` := FALSE]
merged[is.na(`HLA-B`), `HLA-B` := FALSE]
merged[is.na(`HLA-C`), `HLA-C` := FALSE]
merged[is.na(HLA_N_LOH), HLA_N_LOH := 0]

cat(sprintf("  Merged: %d samples\n", nrow(merged)))

# =============================================
# 4. PAN-CANCER HLA LOH FREQUENCY
# =============================================
cat("\n[4/8] Pan-cancer HLA LOH frequencies...\n")

# By cancer type (minimum 50 samples)
cancer_freq <- merged[, .(
  N = .N,
  HLA_A_LOH = sum(`HLA-A`, na.rm = TRUE),
  HLA_B_LOH = sum(`HLA-B`, na.rm = TRUE),
  HLA_C_LOH = sum(`HLA-C`, na.rm = TRUE),
  HLA_ANY_LOH = sum(HLA_ANY_LOH, na.rm = TRUE),
  Mean_N_LOH = mean(HLA_N_LOH, na.rm = TRUE),
  Median_TMB = median(as.numeric(TMB_SCORE), na.rm = TRUE),
  WGD_Rate = mean(FACETS_WGD == "TRUE", na.rm = TRUE)
), by = CANCER_TYPE]

cancer_freq[, `:=`(
  HLA_A_Rate = 100 * HLA_A_LOH / N,
  HLA_B_Rate = 100 * HLA_B_LOH / N,
  HLA_C_Rate = 100 * HLA_C_LOH / N,
  HLA_ANY_Rate = 100 * HLA_ANY_LOH / N
)]

# Filter to cancer types with >= 50 samples with HLA data
cancer_freq <- cancer_freq[N >= 50][order(-HLA_ANY_Rate)]

cat(sprintf("  Cancer types (>=50 samples): %d\n", nrow(cancer_freq)))
cat("\n  Top 10 by HLA LOH rate:\n")
print(cancer_freq[1:10, .(CANCER_TYPE, N, HLA_ANY_Rate, HLA_A_Rate, HLA_B_Rate, HLA_C_Rate, Median_TMB, WGD_Rate)])

# Write results
fwrite(cancer_freq, file.path(RESULTS_DIR, "tables/cancer_type_hla_loh.csv"))

# =============================================
# 5. HLA LOH x GENOMIC FEATURES
# =============================================
cat("\n[5/8] HLA LOH associations with genomic features...\n")

# 5a. TMB
tmb_loh <- merged[HLA_ANY_LOH == TRUE, as.numeric(TMB_SCORE)]
tmb_noloh <- merged[HLA_ANY_LOH == FALSE, as.numeric(TMB_SCORE)]
tmb_test <- wilcox.test(tmb_loh, tmb_noloh)
cat(sprintf("  TMB: LOH+ median=%.1f vs LOH- median=%.1f, p=%.2e\n",
    median(tmb_loh, na.rm=TRUE), median(tmb_noloh, na.rm=TRUE), tmb_test$p.value))

# 5b. WGD
wgd_table <- table(merged$HLA_ANY_LOH, merged$FACETS_WGD)
cat("  WGD association:\n")
print(wgd_table)
wgd_test <- fisher.test(wgd_table)
cat(sprintf("  Fisher p=%.2e\n", wgd_test$p.value))

# 5c. MSI
msi_table <- table(merged$HLA_ANY_LOH, merged$MSI_TYPE)
cat("  MSI association:\n")
print(msi_table)

# 5d. Sample type (Primary vs Metastasis)
sample_type_table <- table(merged$HLA_ANY_LOH, merged$SAMPLE_TYPE)
cat("  Sample type:\n")
print(sample_type_table)

# =============================================
# 6. SURVIVAL ANALYSIS
# =============================================
cat("\n[6/8] Survival analysis...\n")

# Merge with patient survival data
merged_surv <- merge(merged, clin_patient[, .(PATIENT_ID, OS_STATUS, OS_MONTHS)], 
                     by = "PATIENT_ID", all.x = TRUE)

# Convert OS
merged_surv[, OS_STATUS_BIN := fifelse(OS_STATUS == "DECEASED", 1, 0)]
merged_surv[, OS_MONTHS_NUM := as.numeric(OS_MONTHS)]

# Filter: one primary sample per patient, complete OS data
surv_data <- merged_surv[SAMPLE_TYPE == "Primary" & !is.na(OS_MONTHS_NUM) & OS_MONTHS_NUM >= 0]

cat(sprintf("  Survival analysis set: %d patients\n", nrow(surv_data)))
cat(sprintf("  Events: %d\n", sum(surv_data$OS_STATUS_BIN)))

# Kaplan-Meier
surv_fit <- survfit(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH, data = surv_data)
surv_diff <- survdiff(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH, data = surv_data)
cat(sprintf("  Log-rank p = %.4f\n", 1 - pchisq(surv_diff$chisq, 1)))

# Cox regression
cox_model <- coxph(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH, data = surv_data)
cox_summary <- summary(cox_model)
cat(sprintf("  Cox HR = %.3f (95%% CI: %.3f-%.3f), p = %.4f\n",
    coef(cox_model), confint(cox_model)[1], confint(cox_model)[2],
    cox_summary$coefficients[1,5]))

# =============================================
# 7. FIGURE GENERATION
# =============================================
cat("\n[7/8] Generating figures...\n")

# Figure 1: Pan-cancer HLA LOH bar plot
top_cancers <- cancer_freq[1:20]
p1 <- ggplot(top_cancers, aes(x = reorder(CANCER_TYPE, HLA_ANY_Rate), y = HLA_ANY_Rate)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Pan-Cancer HLA Class I LOH Frequency",
       subtitle = "MSK-IMPACT 50K Cohort (n=54,331 samples)",
       x = "", y = "HLA LOH Rate (%)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11, color = "grey40"))

ggsave(file.path(RESULTS_DIR, "figures/Fig1_pancancer_hla_loh.pdf"), p1, width = 10, height = 7)
ggsave(file.path(RESULTS_DIR, "figures/Fig1_pancancer_hla_loh.png"), p1, width = 10, height = 7, dpi = 300)
cat("  Figure 1 saved\n")

# Figure 2: TMB by HLA LOH status
p2 <- ggplot(merged[!is.na(TMB_SCORE) & TMB_SCORE > 0], 
       aes(x = HLA_ANY_LOH, y = log10(as.numeric(TMB_SCORE)), fill = HLA_ANY_LOH)) +
  geom_violin(alpha = 0.6) +
  geom_boxplot(width = 0.15, alpha = 0.8) +
  scale_fill_manual(values = c("FALSE" = "#66c2a5", "TRUE" = "#fc8d62"),
                    labels = c("FALSE" = "HLA LOH-", "TRUE" = "HLA LOH+")) +
  labs(title = "Tumor Mutational Burden by HLA LOH Status",
       x = "", y = expression(log[10]~(TMB))) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(file.path(RESULTS_DIR, "figures/Fig2_tmb_by_loh.pdf"), p2, width = 6, height = 6)
ggsave(file.path(RESULTS_DIR, "figures/Fig2_tmb_by_loh.png"), p2, width = 6, height = 6, dpi = 300)
cat("  Figure 2 saved\n")

# Figure 3: KM survival curve
surv_fit_df <- survfit(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH, data = surv_data)

p3_data <- data.frame(
  time = surv_fit_df$time,
  surv = surv_fit_df$surv,
  strata = rep(c("HLA LOH-", "HLA LOH+"), surv_fit_df$strata)
)

p3 <- ggplot(p3_data, aes(x = time, y = surv, color = strata)) +
  geom_step(size = 1) +
  scale_color_manual(values = c("HLA LOH-" = "#66c2a5", "HLA LOH+" = "#fc8d62")) +
  labs(title = "Overall Survival by HLA LOH Status",
       subtitle = sprintf("Log-rank P = %.3f, HR = %.2f (%.2f-%.2f)", 
          1-pchisq(surv_diff$chisq,1), coef(cox_model), confint(cox_model)[1], confint(cox_model)[2]),
       x = "Months", y = "Overall Survival Probability",
       color = "") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(RESULTS_DIR, "figures/Fig3_survival.pdf"), p3, width = 8, height = 6)
ggsave(file.path(RESULTS_DIR, "figures/Fig3_survival.png"), p3, width = 8, height = 6, dpi = 300)
cat("  Figure 3 saved\n")

# =============================================
# 8. SUMMARY TABLE
# =============================================
cat("\n[8/8] Writing summary...\n")

summary_stats <- data.table(
  Metric = c("Total samples", "Unique patients", "Cancer types", 
             "HLA A LOH rate", "HLA B LOH rate", "HLA C LOH rate",
             "Any HLA LOH rate", "3-locus LOH rate",
             "Median TMB (LOH+)", "Median TMB (LOH-)", 
             "WGD rate (LOH+)", "WGD rate (LOH-)",
             "MSI-H rate",
             "Cox HR (HLA LOH vs no LOH)", "Log-rank P"),
  Value = c(nrow(merged), length(unique(merged$PATIENT_ID)), length(unique(merged$CANCER_TYPE)),
            sprintf("%.1f%%", 100*mean(merged$`HLA-A`)), sprintf("%.1f%%", 100*mean(merged$`HLA-B`)),
            sprintf("%.1f%%", 100*mean(merged$`HLA-C`)), sprintf("%.1f%%", 100*mean(merged$HLA_ANY_LOH)),
            sprintf("%.1f%%", 100*mean(merged$HLA_N_LOH == 3)),
            sprintf("%.1f", median(tmb_loh, na.rm=TRUE)), sprintf("%.1f", median(tmb_noloh, na.rm=TRUE)),
            sprintf("%.1f%%", 100*mean(merged[HLA_ANY_LOH==TRUE]$FACETS_WGD == "TRUE", na.rm=TRUE)),
            sprintf("%.1f%%", 100*mean(merged[HLA_ANY_LOH==FALSE]$FACETS_WGD == "TRUE", na.rm=TRUE)),
            sprintf("%.1f%%", 100*mean(merged$MSI_TYPE == "Instable", na.rm=TRUE)),
            sprintf("%.2f (%.2f-%.2f)", coef(cox_model), confint(cox_model)[1], confint(cox_model)[2]),
            sprintf("%.4f", 1-pchisq(surv_diff$chisq,1)))
)

fwrite(summary_stats, file.path(RESULTS_DIR, "tables/summary_statistics.csv"))
print(summary_stats)

cat(sprintf("\n=== Analysis Complete (elapsed: %s) ===\n", Sys.time()))
cat(sprintf("Results saved to: %s/\n", RESULTS_DIR))
