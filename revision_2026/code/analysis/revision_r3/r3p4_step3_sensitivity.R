## R3 part4 — step 3: how much of "arm-independent" is explained by technical
## factors? variance explained, AUC, and high-purity sensitivity analysis.
suppressMessages({library(data.table)})
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
OUT  <- file.path(ROOT, "iscience投稿版本/V2")
d <- readRDS(file.path(OUT, "r3p4_data.rds"))
d3 <- d$d3
num <- function(x) suppressWarnings(as.numeric(x))
d3[, pur_f := num(FACETS_PURITY) * 100]
d3[, cov := num(SAMPLE_COVERAGE)]

prep <- function(dt) {
  dt <- copy(dt)
  dt[, CANCER_TYPE := as.character(CANCER_TYPE)]
  freq <- dt[, .N, by = CANCER_TYPE][order(-N)]
  dt[!(CANCER_TYPE %in% freq[N >= 50]$CANCER_TYPE), CANCER_TYPE := "Other"]
  dt[, CANCER_TYPE := relevel(factor(CANCER_TYPE), ref = "Non-Small Cell Lung Cancer")]
  dt[, GENE_PANEL := relevel(factor(GENE_PANEL), ref = "IMPACT468")]
  dt[, wgd_f := factor(ifelse(is.na(wgd), NA, as.character(wgd)), levels = c("FALSE", "TRUE"))]
  dt
}
auc <- function(m) { p <- fitted(m); y <- m$y
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  as.numeric(wilcox.test(p[y == 1], p[y == 0])$statistic) / (n1 * n0) }
mcf <- function(m, dat) { ll <- as.numeric(logLik(m))
  ll0 <- as.numeric(logLik(glm(m$y ~ 1, data = dat, family = binomial())))
  1 - ll / ll0 }

## ---------- Model 2 data: Arm_independent vs Arm_dependent --------------
d2 <- prep(d3[grp %in% c("Arm_independent", "Arm_dependent")])
d2[, y := as.integer(grp == "Arm_independent")]
m_tech <- glm(y ~ pur_f + cov + GENE_PANEL, d2, family = binomial())
m_bio  <- glm(y ~ pur_f + cov + GENE_PANEL + CANCER_TYPE + wgd_f, d2, family = binomial())
m_bio_only <- glm(y ~ CANCER_TYPE + wgd_f, d2, family = binomial())
cat("=== Model 2 (arm-independent vs arm-dependent), n =", nrow(d2), " ===\n")
tab <- data.table(
  model = c("technical only (purity+coverage+panel)", "full (+ cancer type + WGD)",
            "biological residual (cancer type + WGD only)"),
  McFaddenR2 = round(c(mcf(m_tech, d2), mcf(m_bio, d2),
                       1 - as.numeric(logLik(m_bio)) / as.numeric(logLik(m_tech))), 4),
  AUC = round(c(auc(m_tech), auc(m_bio), auc(m_bio_only)), 4))
print(tab)

## ---------- low-purity share ------------------------------------------
cat("\n=== share with low purity (FACETS < 30%) by group ===\n")
sh <- d3[grp %in% c("No_LOH", "Arm_independent", "Arm_dependent"),
         .(n = .N, pct_lt30 = 100 * mean(pur_f < 30, na.rm = TRUE),
           pct_lt20 = 100 * mean(pur_f < 20, na.rm = TRUE),
           pct_ge50 = 100 * mean(pur_f >= 50, na.rm = TRUE)), by = grp]
print(sh)

## ---------- arm-independent fraction within high-purity strata --------
cat("\n=== arm-independent fraction among HLA-LOH by purity stratum ===\n")
dl <- d3[grp %in% c("Arm_independent", "Arm_dependent")]
dl[, y := as.integer(grp == "Arm_independent")]
for (thr in c(0, 20, 30, 40, 50, 60)) {
  sub <- dl[pur_f >= thr]
  cat(sprintf("  purity >= %2d%% : n_LOH=%5d, arm-independent=%4d (%.1f%%)\n",
              thr, nrow(sub), sum(sub$y), 100 * mean(sub$y)))
}

## ---------- sensitivity: refit full model in purity>=30% and >=50% ---
cat("\n=== sensitivity: full Model 2 refit within purity strata ===\n")
sens_strat <- rbindlist(list())
for (thr in c(0, 30, 50)) {
  sub <- prep(dl[pur_f >= thr])
  sub[, y := as.integer(grp == "Arm_independent")]
  mm <- tryCatch(glm(y ~ pur_f + cov + GENE_PANEL + CANCER_TYPE + wgd_f, sub, family = binomial()),
                 error = function(e) NULL, warning = function(w) NULL)
  if (!is.null(mm)) {
    s <- summary(mm)$coefficients
    cat(sprintf("  purity>=%2d%% (n=%d, y=%d): WGD OR=%.3f (p=%.2e) ; purity/10%% OR=%.3f (p=%.2e) ; cov/100x OR=%.3f (p=%.2e)\n",
        thr, nrow(sub), sum(sub$y),
        exp(s["wgd_fTRUE", 1]), s["wgd_fTRUE", 4],
        exp(-10 * s["pur_f", 1]), s["pur_f", 4],
        exp(100 * s["cov", 1]), s["cov", 4]))
    sens_strat <- rbind(sens_strat, data.table(
      purity_ge = thr, n = nrow(sub), y = sum(sub$y),
      wgd_OR = exp(s["wgd_fTRUE", 1]), wgd_p = s["wgd_fTRUE", 4],
      pur_per10_OR = exp(-10 * s["pur_f", 1]), pur_p = s["pur_f", 4],
      cov_per100_OR = exp(100 * s["cov", 1]), cov_p = s["cov", 4]))
  }
}
fwrite(sens_strat, file.path(OUT, "r3p4_purity_strata_sensitivity.tsv"), sep = "\t")

## ---------- Model 3 variance explained (arm-ind vs No_LOH) ------------
d3b <- prep(d3[grp %in% c("Arm_independent", "No_LOH")])
d3b[, y := as.integer(grp == "Arm_independent")]
m3t <- glm(y ~ pur_f + cov + GENE_PANEL, d3b, family = binomial())
m3f <- glm(y ~ pur_f + cov + GENE_PANEL + CANCER_TYPE + wgd_f, d3b, family = binomial())
cat("\n=== Model 3 (arm-independent vs No_LOH), n =", nrow(d3b), " ===\n")
print(data.table(model = c("technical only", "full"), McFaddenR2 = round(c(mcf(m3t, d3b), mcf(m3f, d3b)), 4),
                 AUC = round(c(auc(m3t), auc(m3f)), 4)))

## ---------- save a compact sensitivity tsv ---------------------------
sens <- data.table(
  item = c("model2_mcfadden_technical_only", "model2_mcfadden_full",
           "model2_auc_technical_only", "model2_auc_full", "model2_auc_bio_only",
           paste0("model2_wgd_OR_purity_ge", c(0, 30, 50)),
           "model3_mcfadden_technical_only", "model3_mcfadden_full",
           "model3_auc_technical_only", "model3_auc_full",
           paste0("pct_purity_lt30_", c("No_LOH", "Arm_independent", "Arm_dependent"))),
  value = c(tab$McFaddenR2[1], tab$McFaddenR2[2], tab$AUC[1], tab$AUC[2], tab$AUC[3],
            round(sens_strat$wgd_OR, 3),
            round(mcf(m3t, d3b), 4), round(mcf(m3f, d3b), 4), round(auc(m3t), 4), round(auc(m3f), 4),
            round(sh$pct_lt30[sh$grp == "No_LOH"], 2), round(sh$pct_lt30[sh$grp == "Arm_independent"], 2),
            round(sh$pct_lt30[sh$grp == "Arm_dependent"], 2)))
fwrite(sens, file.path(OUT, "r3p4_sensitivity.tsv"), sep = "\t")
saveRDS(list(tab = tab, sh = sh), file.path(OUT, "r3p4_sens.rds"))
cat("\nDONE sensitivity\n")
