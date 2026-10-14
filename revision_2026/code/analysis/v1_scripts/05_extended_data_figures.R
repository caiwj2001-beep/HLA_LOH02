#!/usr/bin/env Rscript
# HLA_LOH02 — Extended Data Figures (ED Fig 1-3)
# ED Fig 1: Mutational signatures by HLA LOH status
# ED Fig 2: Sample type / structural variant analysis  
# ED Fig 3: Sensitivity analyses (ancestry subgroups, cancer type exclusions)

.libPaths(c("/home/caiwj2001/R/library", .libPaths()))

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(survival)
})

setwd("/home/caiwj2001/HLA_LOH02")
DATA_DIR <- "msk_impact_50k_2026"
FIG_DIR <- "results/figures"
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

theme_nm <- theme_bw(base_size = 9) + theme(
  panel.grid.minor = element_blank(),
  panel.grid.major = element_line(size = 0.15),
  plot.title = element_text(face = "bold", size = 11, family = "sans"),
  plot.subtitle = element_text(size = 9, color = "grey40", family = "sans"),
  legend.position = "bottom",
  axis.text = element_text(family = "sans", size = 7),
  axis.title = element_text(family = "sans", size = 9)
)

save_edfig <- function(p, name, w = 7, h = 6) {
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
  cat(sprintf("  Saved: %s\n", name))
}

# ── Load data ──
cat("Loading data...\n")
hla_raw <- fread(file.path(DATA_DIR, "data_hla_loh.txt"), sep = "\t")
clin_s <- fread(file.path(DATA_DIR, "data_clinical_sample.txt"), sep = "\t", skip = 4)
clin_p <- fread(file.path(DATA_DIR, "data_clinical_patient.txt"), sep = "\t", skip = 4)
sig_data <- fread(file.path(DATA_DIR, "data_mutational_signatures_contribution_v2.txt"), sep = "\t")

# HLA LOH aggregation (vectorized)
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
m[, `:=`(OS_STATUS_BIN = fifelse(OS_STATUS == "DECEASED", 1L, 0L),
         OS_MONTHS_NUM = as.numeric(OS_MONTHS),
         TMB_NUM = as.numeric(TMB_SCORE))]
m_hla <- m[!is.na(HLA_ANY_LOH)]

cat(sprintf("Merged: %d samples with HLA data\n", nrow(m_hla)))

# ═══════════════════════════════════════════
# ED FIG 1: Mutational signatures by HLA LOH
# ═══════════════════════════════════════════
cat("\nED Fig 1: Mutational signatures by HLA LOH\n")

# Process signature data
sig_long <- melt(sig_data, id.vars = c("ENTITY_STABLE_ID", "NAME", "DESCRIPTION", "URL"),
                 variable.name = "SAMPLE_ID", value.name = "CONTRIBUTION")
sig_long <- sig_long[CONTRIBUTION > 0 & !is.na(CONTRIBUTION)]

# Merge with HLA status
sig_merged <- merge(sig_long, m_hla[, .(SAMPLE_ID, HLA_ANY_LOH)], 
                    by = "SAMPLE_ID", all.x = TRUE)
sig_merged <- sig_merged[!is.na(HLA_ANY_LOH)]

# Signature categories
sig_categories <- list(
  "APOBEC" = c("Signature2 (APOBEC)", "Signature13 (APOBEC)"),
  "Aging" = c("Signature1 (Aging)"),
  "MMR" = c("Signature6 (MMR)", "Signature15 (MMR)", "Signature20 (MMR)", "Signature21 (MMR)"),
  "Smoking" = c("Signature4 (Smoking)", "Signature29 (Tobacco)"),
  "UV" = c("Signature7 (UV)"),
  "HRD" = c("Signature3 (HRD)"),
  "POLE" = c("Signature10 (POLE)")
)

sig_merged[, CATEGORY := NA_character_]
for (cat_name in names(sig_categories)) {
  sig_merged[NAME %in% sig_categories[[cat_name]], CATEGORY := cat_name]
}
sig_merged <- sig_merged[!is.na(CATEGORY)]

# Compute frequency by HLA LOH status
sig_freq <- sig_merged[, .(
  Pct_LOH_pos = 100 * sum(HLA_ANY_LOH == TRUE) / sum(m_hla$HLA_ANY_LOH == TRUE),
  Pct_LOH_neg = 100 * sum(HLA_ANY_LOH == FALSE) / sum(m_hla$HLA_ANY_LOH == FALSE)
), by = CATEGORY]

sig_freq_long <- melt(sig_freq, id.vars = "CATEGORY", 
                       variable.name = "Group", value.name = "Prevalence")
sig_freq_long[, Group := fifelse(Group == "Pct_LOH_pos", "HLA LOH+", "HLA LOH-")]
sig_freq_long[, CATEGORY := factor(CATEGORY, 
  levels = sig_freq[order(-Pct_LOH_pos), CATEGORY])]

p_ed1 <- ggplot(sig_freq_long, aes(x = CATEGORY, y = Prevalence, fill = Group)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("HLA LOH+" = "#d73027", "HLA LOH-" = "#4575b4")) +
  labs(title = "Extended Data Figure 1 | Mutational Signature Prevalence by HLA LOH Status",
       subtitle = "MSK-IMPACT 50K cohort. Prevalence = proportion of tumors with detectable signature contribution.",
       x = "Mutational Signature Category", y = "Prevalence (%)", fill = "") +
  theme_nm

save_edfig(p_ed1, "ED_Fig1_signatures", 9, 5)

# ═══════════════════════════════════════════
# ED FIG 2: Sample type and WGD x HLA LOH
# ═══════════════════════════════════════════
cat("ED Fig 2: Sample type analysis\n")

# HLA LOH by sample type
sample_type_data <- m_hla[SAMPLE_TYPE %in% c("Primary", "Metastasis"), 
  .(Pct_LOH = 100 * mean(HLA_ANY_LOH), N = .N), 
  by = .(SAMPLE_TYPE, CANCER_TYPE)][N >= 30]

# Top cancer types comparison
top_ct <- m_hla[, .N, by = CANCER_TYPE][order(-N)][1:8, CANCER_TYPE]
st_sub <- sample_type_data[CANCER_TYPE %in% top_ct]
st_sub[, CANCER_TYPE := factor(CANCER_TYPE, levels = top_ct)]

p_ed2a <- ggplot(st_sub, aes(x = CANCER_TYPE, y = Pct_LOH, fill = SAMPLE_TYPE)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("Primary" = "#4575b4", "Metastasis" = "#d73027")) +
  labs(title = "Extended Data Figure 2a | HLA LOH in Primary vs Metastatic Tumors",
       subtitle = "Top 8 cancer types by sample count. Error bars omitted for clarity.",
       x = "", y = "HLA LOH Rate (%)", fill = "") +
  theme_nm + theme(axis.text.x = element_text(angle = 30, hjust = 1))

# WGD by ploidy in LOH+ tumors
m_wgd <- m_hla[!is.na(FACETS_WGD) & FACETS_WGD != "NA" & !is.na(FACETS_PLOIDY)]
p_ed2b <- ggplot(m_wgd[FACETS_PLOIDY < 8], 
  aes(x = factor(HLA_ANY_LOH, labels = c("HLA LOH-", "HLA LOH+")), 
      y = FACETS_PLOIDY, fill = HLA_ANY_LOH)) +
  geom_violin(alpha = 0.5, draw_quantiles = 0.5) +
  geom_boxplot(width = 0.1, alpha = 0.8, outlier.size = 0.3) +
  scale_fill_manual(values = c("FALSE" = "#4575b4", "TRUE" = "#d73027"), guide = "none") +
  labs(title = "Extended Data Figure 2b | Tumor Ploidy by HLA LOH Status",
       subtitle = "FACETS-estimated ploidy; WGD+ tumors restricted to ploidy < 8",
       x = "", y = "Tumor Ploidy") +
  theme_nm

save_edfig(p_ed2a, "ED_Fig2a_sample_type", 8, 5)
save_edfig(p_ed2b, "ED_Fig2b_ploidy", 6, 5)

# ═══════════════════════════════════════════
# ED FIG 3: Sensitivity analyses
# ═══════════════════════════════════════════
cat("ED Fig 3: Sensitivity analyses\n")

surv_primary <- m_hla[SAMPLE_TYPE == "Primary" & !is.na(OS_MONTHS_NUM) & OS_MONTHS_NUM >= 0]

# ED Fig 3a: Ancestry subgroup analysis
ancestry_groups <- surv_primary[ANCESTRY_LABEL %in% c("nonASJ-EUR", "ASJ-EUR", "AFR", "EAS", "ADMIX_OTHER")]
ancestry_groups <- ancestry_groups[!is.na(TMB_NUM)]

ancestry_hr <- data.table()
for (anc in unique(ancestry_groups$ANCESTRY_LABEL)) {
  sub <- ancestry_groups[ANCESTRY_LABEL == anc]
  if (nrow(sub) >= 100 && sum(sub$OS_STATUS_BIN) >= 20) {
    tryCatch({
      cox <- coxph(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH + log10(TMB_NUM + 0.01) + AGE_AT_DX + SEX, data = sub)
      hr <- exp(coef(cox)["HLA_ANY_LOHTRUE"])
      ci <- exp(confint(cox)["HLA_ANY_LOHTRUE", ])
      ancestry_hr <- rbind(ancestry_hr, data.table(
        Ancestry = anc, HR = hr, Lower = ci[1], Upper = ci[2],
        N = nrow(sub), Events = sum(sub$OS_STATUS_BIN)
      ))
    }, error = function(e) NULL)
  }
}

# Add overall
cox_all <- coxph(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH + log10(TMB_NUM + 0.01) + AGE_AT_DX + SEX, 
                 data = ancestry_groups)
ancestry_hr <- rbind(data.table(
  Ancestry = "All ancestries", 
  HR = exp(coef(cox_all)["HLA_ANY_LOHTRUE"]),
  Lower = exp(confint(cox_all)["HLA_ANY_LOHTRUE", 1]),
  Upper = exp(confint(cox_all)["HLA_ANY_LOHTRUE", 2]),
  N = nrow(ancestry_groups), Events = sum(ancestry_groups$OS_STATUS_BIN)
), ancestry_hr)

p_ed3a <- ggplot(ancestry_hr, aes(x = HR, y = reorder(Ancestry, HR))) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
  geom_point(size = 2, color = "#d73027") +
  geom_errorbarh(aes(xmin = Lower, xmax = Upper), height = 0.2, color = "#d73027") +
  labs(title = "Extended Data Figure 3a | HLA LOH Survival Effect by Ancestry",
       subtitle = "Cox model adjusted for TMB, age, sex. Primary tumors only.",
       x = "Hazard Ratio (HLA LOH+ vs LOH-)", y = "") +
  theme_nm

save_edfig(p_ed3a, "ED_Fig3a_ancestry", 7, 5)

# ED Fig 3b: Leave-one-out cancer type analysis
cat("  Leave-one-out cancer type analysis...\n")
cancer_types_large <- m_hla[, .N, by = CANCER_TYPE][N >= 500, CANCER_TYPE]

loo_results <- data.table()
for (ct_exclude in cancer_types_large) {
  sub <- surv_primary[CANCER_TYPE != ct_exclude & !is.na(TMB_NUM)]
  if (nrow(sub) >= 1000) {
    tryCatch({
      cox <- coxph(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH + log10(TMB_NUM + 0.01) + AGE_AT_DX + SEX, data = sub)
      loo_results <- rbind(loo_results, data.table(
        Excluded = ct_exclude, HR = exp(coef(cox)["HLA_ANY_LOHTRUE"]), N = nrow(sub)
      ))
    }, error = function(e) NULL)
  }
}

loo_results[, Excluded := factor(Excluded, levels = loo_results[order(HR), Excluded])]

p_ed3b <- ggplot(loo_results, aes(x = HR, y = Excluded)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = exp(coef(cox_all)["HLA_ANY_LOHTRUE"]), linetype = "dotted", color = "#d73027") +
  geom_point(size = 2, color = "#4575b4") +
  labs(title = "Extended Data Figure 3b | Leave-One-Out Cancer Type Sensitivity",
       subtitle = sprintf("Red dotted line = overall HR (%.2f). Each point = HR excluding one cancer type.",
           exp(coef(cox_all)["HLA_ANY_LOHTRUE"])),
       x = "Hazard Ratio (HLA LOH+ vs LOH-)", y = "Excluded Cancer Type") +
  theme_nm

save_edfig(p_ed3b, "ED_Fig3b_LOO", 7, 5)

cat(sprintf("\n=== All Extended Data figures saved to %s/ ===\n", FIG_DIR))
