#!/usr/bin/env Rscript
# HLA_LOH02 — Refined Analysis Pipeline v2.0
# Fixes: proper denominators, survival analysis, WGD integration

.libPaths(c("/home/caiwj2001/R/library", .libPaths()))

suppressPackageStartupMessages({
  library(data.table)
  library(survival)
})

setwd("/home/caiwj2001/HLA_LOH02")
DATA_DIR <- "msk_impact_50k_2026"
RES <- "results/tables"

dir.create(RES, showWarnings = FALSE, recursive = TRUE)

cat(sprintf("=== HLA_LOH02 v2.0 [%s] ===\n", Sys.time()))

# ── 1. Load ────────────────────────────────────
cat("\n── 1. Loading data ──\n")
hla_raw <- fread(file.path(DATA_DIR, "data_hla_loh.txt"), sep = "\t")
clin_s <- fread(file.path(DATA_DIR, "data_clinical_sample.txt"), sep = "\t", skip = 4)
clin_p <- fread(file.path(DATA_DIR, "data_clinical_patient.txt"), sep = "\t", skip = 4)

cat(sprintf("HLA LOH allele rows: %d, samples: %d\n", nrow(hla_raw), ncol(hla_raw)-2))
cat(sprintf("Sample clinical: %d\n", nrow(clin_s)))
cat(sprintf("Patient clinical: %d\n", nrow(clin_p)))

# ── 2. HLA LOH gene-level aggregation ─────────
cat("\n── 2. HLA LOH aggregation ──\n")
hla_long <- melt(hla_raw, id.vars = c("ENTITY_STABLE_ID", "HLA_GENE"),
                 variable.name = "SAMPLE_ID", value.name = "STATUS")
hla_long <- hla_long[STATUS %in% c("Loss", "Unchanged")]

hla_gene <- hla_long[, .(HAS_LOSS = any(STATUS == "Loss")),
                     by = .(SAMPLE_ID, HLA_GENE)]

hla_wide <- dcast(hla_gene, SAMPLE_ID ~ HLA_GENE, value.var = "HAS_LOSS")
hla_wide[, `:=`(
  HLA_ANY_LOH = (!is.na(`HLA-A`) & `HLA-A`) | (!is.na(`HLA-B`) & `HLA-B`) | (!is.na(`HLA-C`) & `HLA-C`),
  HLA_HAS_DATA = TRUE
)]

# Replace NA with FALSE for HLA columns in hla_wide
for (col in c("HLA-A", "HLA-B", "HLA-C")) {
  if (col %in% names(hla_wide)) {
    set(hla_wide, i = which(is.na(hla_wide[[col]])), j = col, value = FALSE)
  } else {
    hla_wide[, (col) := FALSE]
  }
}
hla_wide[, HLA_N_LOH := as.integer(`HLA-A`) + as.integer(`HLA-B`) + as.integer(`HLA-C`)]

n_hla_samples <- nrow(hla_wide)
cat(sprintf("Samples with HLA data: %d\n", n_hla_samples))
cat(sprintf("HLA-A LOH: %d (%.1f%%)\n", sum(hla_wide$`HLA-A`), 100*mean(hla_wide$`HLA-A`)))
cat(sprintf("HLA-B LOH: %d (%.1f%%)\n", sum(hla_wide$`HLA-B`), 100*mean(hla_wide$`HLA-B`)))
cat(sprintf("HLA-C LOH: %d (%.1f%%)\n", sum(hla_wide$`HLA-C`), 100*mean(hla_wide$`HLA-C`)))
cat(sprintf("Any LOH: %d (%.1f%%)\n", sum(hla_wide$HLA_ANY_LOH), 100*mean(hla_wide$HLA_ANY_LOH)))
cat(sprintf("3-locus LOH: %d (%.1f%%)\n", sum(hla_wide$HLA_N_LOH == 3), 100*mean(hla_wide$HLA_N_LOH == 3)))

# ── 3. Merge datasets ─────────────────────────
cat("\n── 3. Merging datasets ──\n")
m <- merge(clin_s, hla_wide, by = "SAMPLE_ID", all.x = TRUE)
m[, HLA_HAS_DATA := !is.na(HLA_HAS_DATA)]

# For samples without HLA data, set all to FALSE
for (col in c("HLA-A", "HLA-B", "HLA-C", "HLA_ANY_LOH")) {
  set(m, i = which(is.na(m[[col]])), j = col, value = FALSE)
}
m[is.na(HLA_N_LOH), HLA_N_LOH := 0]

# Merge patient survival
m <- merge(m, clin_p[, .(PATIENT_ID, OS_STATUS, OS_MONTHS, ANCESTRY_LABEL, AGE_AT_DX, SEX)],
           by = "PATIENT_ID", all.x = TRUE)

# Clean OS
m[, OS_STATUS_BIN := fifelse(OS_STATUS == "DECEASED", 1L, 0L)]
m[, OS_MONTHS_NUM := suppressWarnings(as.numeric(OS_MONTHS))]

cat(sprintf("Total samples: %d (HLA data: %d)\n", nrow(m), sum(m$HLA_HAS_DATA)))

# ── 4. Pan-cancer frequencies (correct denominator: HLA data only) ──
cat("\n── 4. Cancer-type frequencies ──\n")
m_hla <- m[HLA_HAS_DATA == TRUE]

cancer_freq <- m_hla[, .(
  N_total = .N,
  N_loh = sum(HLA_ANY_LOH),
  Pct_LOH = 100 * mean(HLA_ANY_LOH),
  Pct_A = 100 * mean(`HLA-A`),
  Pct_B = 100 * mean(`HLA-B`),
  Pct_C = 100 * mean(`HLA-C`),
  Pct_3loci = 100 * mean(HLA_N_LOH == 3),
  Med_TMB = median(as.numeric(TMB_SCORE), na.rm = TRUE),
  Pct_WGD = 100 * mean(FACETS_WGD == "TRUE", na.rm = TRUE)
), by = CANCER_TYPE]

cancer_freq <- cancer_freq[N_total >= 50][order(-Pct_LOH)]
cat(sprintf("Cancer types (>=50 HLA samples): %d\n", nrow(cancer_freq)))
cat("\nTop 10 by HLA LOH:\n")
print(cancer_freq[1:10, .(CANCER_TYPE, N_total, Pct_LOH, Pct_3loci, Med_TMB, Pct_WGD)], 
      class = FALSE, row.names = FALSE)

fwrite(cancer_freq, file.path(RES, "cancer_type_hla_loh_v2.csv"))

# ── 5. TMB analysis ───────────────────────────
cat("\n── 5. TMB by HLA LOH ──\n")
m_hla[, TMB_NUM := as.numeric(TMB_SCORE)]
tmb_loh   <- m_hla[HLA_ANY_LOH == TRUE & !is.na(TMB_NUM) & TMB_NUM > 0, TMB_NUM]
tmb_noloh <- m_hla[HLA_ANY_LOH == FALSE & !is.na(TMB_NUM) & TMB_NUM > 0, TMB_NUM]

cat(sprintf("LOH+: N=%d, median=%.2f, IQR=[%.2f, %.2f]\n",
    length(tmb_loh), median(tmb_loh), quantile(tmb_loh, 0.25), quantile(tmb_loh, 0.75)))
cat(sprintf("LOH-: N=%d, median=%.2f, IQR=[%.2f, %.2f]\n",
    length(tmb_noloh), median(tmb_noloh), quantile(tmb_noloh, 0.25), quantile(tmb_noloh, 0.75)))

wt <- wilcox.test(tmb_loh, tmb_noloh)
cat(sprintf("Wilcoxon p = %.2e\n", wt$p.value))

# ── 6. WGD analysis ───────────────────────────
cat("\n── 6. WGD association ──\n")
m_hla_wgd <- m_hla[!is.na(FACETS_WGD) & FACETS_WGD != "NA"]
wgd_tab <- table(HLA_LOH = m_hla_wgd$HLA_ANY_LOH, WGD = m_hla_wgd$FACETS_WGD)
cat(sprintf("WGD+ in LOH+: %.1f%%\n", 100*wgd_tab["TRUE","TRUE"]/sum(wgd_tab["TRUE",])))
cat(sprintf("WGD+ in LOH-: %.1f%%\n", 100*wgd_tab["FALSE","TRUE"]/sum(wgd_tab["FALSE",])))
cat(sprintf("Fisher p = %.2e\n", fisher.test(wgd_tab)$p.value))

# ── 7. Survival (careful) ─────────────────────
cat("\n── 7. Survival analysis ──\n")
# Use primary samples with complete OS and HLA data
surv <- m_hla[SAMPLE_TYPE == "Primary" & !is.na(OS_MONTHS_NUM) & OS_MONTHS_NUM >= 0 & !is.na(OS_STATUS_BIN)]
cat(sprintf("Primary samples with survival: %d\n", nrow(surv)))
cat(sprintf("  LOH+ : %d\n", sum(surv$HLA_ANY_LOH)))
cat(sprintf("  Events (LOH+): %d/%d\n", sum(surv$HLA_ANY_LOH & surv$OS_STATUS_BIN==1), sum(surv$HLA_ANY_LOH)))
cat(sprintf("  Events (LOH-): %d/%d\n", sum(!surv$HLA_ANY_LOH & surv$OS_STATUS_BIN==1), sum(!surv$HLA_ANY_LOH)))

# KM
fit <- survfit(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH, data = surv)
sdiff <- survdiff(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH, data = surv)
cat(sprintf("Log-rank chi2=%.2f, p=%.4f\n", sdiff$chisq, 1-pchisq(sdiff$chisq, 1)))

# Cox univariate
cox1 <- coxph(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH, data = surv)
s1 <- summary(cox1)
cat(sprintf("Cox (univariate) HR=%.3f [%.3f-%.3f], p=%.4f\n",
    coef(cox1), confint(cox1)[1], confint(cox1)[2], s1$coefficients[1,5]))

# Cox multivariate (HLA LOH + TMB + WGD + Age + Sex)
surv_mv <- surv[!is.na(TMB_NUM) & !is.na(FACETS_WGD) & FACETS_WGD != "NA" & !is.na(AGE_AT_DX)]
surv_mv[, `:=`(
  logTMB = log10(TMB_NUM + 0.01),
  WGD_TRUE = FACETS_WGD == "TRUE",
  AGE_NUM = as.numeric(AGE_AT_DX),
  SEX_MALE = SEX == "Male"
)]

cox_mv <- coxph(Surv(OS_MONTHS_NUM, OS_STATUS_BIN) ~ HLA_ANY_LOH + logTMB + WGD_TRUE + AGE_NUM + SEX_MALE, 
                data = surv_mv)
s_mv <- summary(cox_mv)
cat(sprintf("\nCox (multivariate): N=%d, events=%d\n", nrow(surv_mv), sum(surv_mv$OS_STATUS_BIN==1)))
print(s_mv$coefficients)

# ── 8. Write summary ──────────────────────────
cat("\n── 8. Summary table ──\n")
summary_dt <- data.table(
  Metric = c(
    "Total tumor samples", "Unique patients", "Cancer types",
    "HLA data available", 
    "HLA-A LOH rate", "HLA-B LOH rate", "HLA-C LOH rate",
    "Any HLA LOH rate", "3-locus LOH rate",
    "Median TMB (LOH+)", "Median TMB (LOH-)",
    "WGD rate (LOH+)", "WGD rate (LOH-)",
    "Cox univariate HR", "Cox multivariate HR",
    "MSI-H rate"
  ),
  Value = c(
    nrow(m), length(unique(m$PATIENT_ID)), 
    length(unique(m_hla$CANCER_TYPE)),
    nrow(m_hla),
    sprintf("%.1f%%", 100*mean(m_hla$`HLA-A`)),
    sprintf("%.1f%%", 100*mean(m_hla$`HLA-B`)),
    sprintf("%.1f%%", 100*mean(m_hla$`HLA-C`)),
    sprintf("%.1f%% (n=%d)", 100*mean(m_hla$HLA_ANY_LOH), sum(m_hla$HLA_ANY_LOH)),
    sprintf("%.1f%%", 100*mean(m_hla$HLA_N_LOH == 3)),
    sprintf("%.2f", median(tmb_loh)), sprintf("%.2f", median(tmb_noloh)),
    sprintf("%.1f%%", 100*mean(m_hla[HLA_ANY_LOH==TRUE]$FACETS_WGD=="TRUE", na.rm=TRUE)),
    sprintf("%.1f%%", 100*mean(m_hla[HLA_ANY_LOH==FALSE]$FACETS_WGD=="TRUE", na.rm=TRUE)),
    sprintf("%.3f [%.3f-%.3f]", coef(cox1), confint(cox1)[1], confint(cox1)[2]),
    sprintf("%.3f [%.3f-%.3f]", s_mv$coefficients["HLA_ANY_LOHTRUE","exp(coef)"],
            s_mv$conf.int["HLA_ANY_LOHTRUE","lower .95"],
            s_mv$conf.int["HLA_ANY_LOHTRUE","upper .95"]),
    sprintf("%.1f%%", 100*mean(m_hla$MSI_TYPE=="Instable", na.rm=TRUE))
  )
)
fwrite(summary_dt, file.path(RES, "summary_v2.csv"))
print(summary_dt, class=FALSE, row.names=FALSE)

cat(sprintf("\n=== Done [%s] ===\n", Sys.time()))
