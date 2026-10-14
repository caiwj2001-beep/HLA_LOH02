## R3 part4 — step 4: assemble the curated key-number table (TSV)
suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"; OUT <- file.path(ROOT, "iscience投稿版本/V2")
d   <- readRDS(file.path(OUT, "r3p4_data.rds"))
sen <- readRDS(file.path(OUT, "r3p4_sens.rds"))
strat <- fread(file.path(OUT, "r3p4_purity_strata_sensitivity.tsv"))
d3 <- d$d3
num <- function(x) suppressWarnings(as.numeric(x))
d3[, pur_f := num(FACETS_PURITY) * 100]

rows <- list()
add <- function(block, metric, group, n = NA, value = NA, ci_lo = NA, ci_hi = NA, p = NA, note = "") {
  rows[[length(rows) + 1]] <<- data.table(block = block, metric = metric, group_or_term = group,
    n = n, value = value, ci_lo = ci_lo, ci_hi = ci_hi, p = p, note = note)
}

## groups
gs <- d3[, .N, by = grp]
for (i in 1:nrow(gs)) add("groups", "n_samples_by_group", gs$grp[i], gs$N[i])
add("groups", "arm_independent_share_among_judgeable_6p_LOH", "1644/5805", 5805, 28.32, note = "1,644/(1,644+4,161)")

## T1 continuous
qt <- d$qtab
for (i in 1:nrow(qt)) add("T1_continuous", qt$variable[i], qt$grp[i], qt$n_nonmiss[i], qt$median[i],
  ci_lo = qt$q1[i], ci_hi = qt$q3[i], p = NA,
  note = paste0("p10=", qt$p10[i], ";p90=", qt$p90[i], ";mean=", round(qt$mean[i], 2), ";n_miss=", qt$n_miss[i]))
for (i in 1:nrow(d$ktab)) add("T1_continuous", paste0("KruskalWallis_", d$ktab$variable[i]), "3-group", NA, d$ktab$statistic[i], p = d$ktab$p[i])
for (i in 1:nrow(d$wt)) add("T1_continuous", paste0("Wilcoxon_", d$wt$variable[i]), d$wt$contrast[i],
  NA, d$wt$median_test[i], note = paste0("median_ref=", d$wt$median_ref[i]), p = d$wt$p[i])

## T1 categorical
gp <- d$gp
for (i in 1:nrow(gp)) add("T1_categorical", "GENE_PANEL_pct", paste0(gp$grp[i], ":", gp$GENE_PANEL[i]), gp$N[i], round(gp$pct[i], 3))
ms <- d$ms
for (i in 1:nrow(ms)) add("T1_categorical", "MSI_TYPE_pct", paste0(ms$grp[i], ":", ifelse(ms$MSI_TYPE[i] == "", "(blank)", ms$MSI_TYPE[i])), ms$N[i], round(ms$pct[i], 3))
for (g in G3 <- c("No_LOH", "Arm_independent", "Arm_dependent")) {
  sub <- d3[grp == g]
  add("T1_categorical", "FACETS_WGD_pct_TRUE", g, nrow(sub), round(100 * mean(sub$wgd == "TRUE", na.rm = TRUE), 3))
  add("T1_categorical", "FACETS_QC_pass_rate_pct", g, nrow(sub), round(100 * mean(sub$FACETS_QC == "Pass", na.rm = TRUE), 3), note = "cohort pre-filtered; 100% by design")
  add("T1_categorical", "pct_purity_lt30", g, nrow(sub), round(100 * mean(sub$pur_f < 30, na.rm = TRUE), 2))
  add("T1_categorical", "pct_purity_ge50", g, nrow(sub), round(100 * mean(sub$pur_f >= 50, na.rm = TRUE), 2))
}
add("T1_categorical", "chisq_GENE_PANEL", "3-group", NA, 21.568, p = 0.00024423)
add("T1_categorical", "chisq_MSI_TYPE", "3-group", NA, 220.528, p = 8.0307e-45)
add("T1_categorical", "chisq_FACETS_WGD", "3-group", NA, 1887.394, p = 0, note = "p underflow; massively significant")
add("T1_categorical", "chisq_FACETS_QC", "3-group", NA, NA, note = "NOT testable: 100% Pass in every group (cohort pre-filtered on FACETS_pass)")

## T2 model
r2 <- d$r2
for (i in 1:nrow(r2)) add("T2_model_armind_vs_armdep", "logistic_OR", r2$term[i], d$d2n, r2$OR[i], r2$lo[i], r2$hi[i], r2$p[i], r2$note[i])
sc <- d$scal
for (i in 1:nrow(sc)) add("T2_model_armind_vs_armdep", "logistic_OR_scaled", sc$term[i], d$d2n, round(sc$OR[i], 3), round(sc$lo[i], 3), round(sc$hi[i], 3), sc$p[i])
tr <- d$tr
for (i in 1:nrow(tr)) add("T2_purity_decile_trend", "armind_pct", paste0(tr$variable[i], "_D", tr$dec[i]), tr$n[i], round(tr$pct_ind[i], 2), round(tr$lo[i], 2), round(tr$hi[i], 2), tr$trend_p[i])

## T3 model
r3m <- d$r3m
for (i in 1:nrow(r3m)) add("T3_model_armind_vs_NoLOH", "logistic_OR", r3m$term[i], d$d3n, r3m$OR[i], r3m$lo[i], r3m$hi[i], r3m$p[i], r3m$note[i])
sc3 <- d$scal3
for (i in 1:nrow(sc3)) add("T3_model_armind_vs_NoLOH", "logistic_OR_scaled", sc3$term[i], d$d3n, round(sc3$OR[i], 3), round(sc3$lo[i], 3), round(sc3$hi[i], 3), sc3$p[i])

## T4
ct4 <- d$ct4
for (i in 1:nrow(ct4)) add("T4_HLA_genecna", "pct_call", paste0(ct4$grp[i], ":", ct4$Hugo_Symbol[i], ":", ct4$call[i]), ct4$N[i], round(ct4$pct[i], 4))
s4 <- d$s4
for (i in 1:nrow(s4)) add("T4_HLA_genecna", "pct_samples_any_HLA_deepdel", s4$grp[i], s4$n[i], round(s4$any_deepdel_pct[i], 3),
  note = paste0("n_deepdel=", s4$any_deepdel_n[i]))
add("T4_HLA_genecna", "allcohort_value_distribution", "0=diploid", 162761, round(100 * 162761 / (162761 + 151 + 81), 3))
add("T4_HLA_genecna", "allcohort_value_distribution", "2=amp", 151, round(100 * 151 / (162761 + 151 + 81), 4))
add("T4_HLA_genecna", "allcohort_value_distribution", "-2=deepdel", 81, round(100 * 81 / (162761 + 151 + 81), 4))

## sensitivity
for (i in 1:nrow(strat)) {
  add("S1_purity_strata", "model2_WGD_OR", paste0("purity_ge", strat$purity_ge[i]), strat$n[i], round(strat$wgd_OR[i], 3), p = strat$wgd_p[i])
  add("S1_purity_strata", "model2_purity_per10pct_OR", paste0("purity_ge", strat$purity_ge[i]), strat$n[i], round(strat$pur_per10_OR[i], 3), p = strat$pur_p[i])
  add("S1_purity_strata", "model2_coverage_per100x_OR", paste0("purity_ge", strat$purity_ge[i]), strat$n[i], round(strat$cov_per100_OR[i], 3), p = strat$cov_p[i])
}
tb <- sen$tab
for (i in 1:nrow(tb)) add("S2_variance_explained", tb$model[i], "model2_armind_vs_armdep", d$d2n, tb$McFaddenR2[i], note = paste0("AUC=", tb$AUC[i]))
add("S2_variance_explained", "model3_technical_only", "armind_vs_NoLOH", d$d3n, 0.0418, note = "AUC=0.6621")
add("S2_variance_explained", "model3_full", "armind_vs_NoLOH", d$d3n, 0.0688, note = "AUC=0.7084")
add("S2_variance_explained", "model2_technical_only", "armind_vs_armdep", d$d2n, 0.0926, note = "AUC=0.7060")
add("S2_variance_explained", "model2_full", "armind_vs_armdep", d$d2n, 0.2668, note = "AUC=0.8367")
add("S2_variance_explained", "model2_biomarkers_only", "armind_vs_armdep", d$d2n, 0.1920, note = "AUC=0.7668; cancer type + WGD")
for (thr in c(0, 20, 30, 40, 50, 60)) {
  sub <- d3[grp %in% c("Arm_independent", "Arm_dependent") & !is.na(pur_f) & pur_f >= thr]
  add("S2_variance_explained", "armind_fraction_purity_stratum", paste0("purity_ge", thr), nrow(sub),
      round(100 * mean(sub$grp == "Arm_independent"), 2), note = paste0("n_armind=", sum(sub$grp == "Arm_independent")))
}

res <- rbindlist(rows, fill = TRUE)
fwrite(res, file.path(OUT, "REVIEWER3_part4_armindependent_QC.tsv"), sep = "\t")
cat("wrote", nrow(res), "rows\n"); print(res[, .N, by = block])
