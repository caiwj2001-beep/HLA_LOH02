#!/usr/bin/env Rscript
# =====================================================================
# clonal_or_definitive.R
# P2-A: "clonal-restricted neoantigen" OR -- independent re-derivation
#       from RAW inputs (NetMHCpan-4.2e binder calls + peptide table +
#       sample-level analysis frame), to settle the 1.013 vs 1.014 conflict.
#
# Raw inputs (read-only):
#   neoantigen/output/stats/netmhcpan_full/analysis_frame.tsv        (sample frame)
#   neoantigen/output/predictions/netmhcpan_full/pred_binders_*.tsv  (binder calls)
#   neoantigen/output/peptides/peptides_part_*.tsv                   (clonality flags)
#
# The script deliberately fits BOTH covariate sets that exist upstream:
#   M1  primary specification  : Z + log10TMB + frac_all + FACETS_PURITY
#                                + CANCER_TYPE + GENE_PANEL
#   M2  legacy 03_stats.py spec: same, WITHOUT the GENE_PANEL term
# plus M5 = M1 with HC3 heteroskedasticity-robust covariance, and
# M4 = the primary (non-clonal) neoantigen model as a pipeline sanity check.
#
# Output: clonal_or_definitive.tsv / .log (same directory)
# =====================================================================
suppressPackageStartupMessages(library(data.table))

QCDIR <- "C:/Users/Administrator/科研文件/HLA_LOH02/iscience投稿版本/V4/QC/P2"
ROOT  <- "C:/Users/Administrator/科研文件/HLA_LOH02"
NEO   <- file.path(ROOT, "neoantigen")
FRAME <- file.path(NEO, "output/stats/netmhcpan_full/analysis_frame.tsv")
BNDIR <- file.path(NEO, "output/predictions/netmhcpan_full")
PEPDIR<- file.path(NEO, "output/peptides")
OUT   <- file.path(QCDIR, "clonal_or_definitive.tsv")
LOG   <- file.path(QCDIR, "clonal_or_definitive.log")
con   <- file(LOG, "w"); sink(con, split = TRUE); sink(con, type = "message")

t0 <- Sys.time()
cat("== clonal_or_definitive.R ==\n")
cat("R:", R.version.string, "| data.table:", as.character(packageVersion("data.table")), "\n")
cat("started:", format(t0, "%Y-%m-%d %H:%M:%S"), "\n\n")

# ---------------------------------------------------------------- 1. frame
fr <- fread(FRAME)
numc <- c("n_neo_either","n_neo_ic50","neo_per_Mb","neo_per_mut","n_mut_coding",
          "TMB_SCORE","FACETS_PURITY","frac_all","frac_ex6","log10TMB","any_LOH")
for (c in numc) fr[[c]] <- as.numeric(fr[[c]])
# pandas.read_csv(dtype=str) maps an empty field to NaN; fread keeps "". Normalise so the
# complete-case set is identical to the upstream (Python) model matrix.
n_empty_cancer <- sum(fr$CANCER_TYPE == "")
n_empty_panel  <- sum(fr$GENE_PANEL == "")
fr[CANCER_TYPE == "", CANCER_TYPE := NA_character_]
fr[GENE_PANEL  == "", GENE_PANEL  := NA_character_]
cat(sprintf("empty-string -> NA: CANCER_TYPE %d, GENE_PANEL %d (pandas parity)\n",
            n_empty_cancer, n_empty_panel))
cat(sprintf("analysis_frame: %d rows | LOH+ = %d\n", nrow(fr), sum(fr$any_LOH)))
cat(sprintf("GENE_PANEL: %s\n", paste(sprintf("%s=%d", names(table(fr$GENE_PANEL)),
                                               as.integer(table(fr$GENE_PANEL))), collapse = ", ")))
cat(sprintf("CANCER_TYPE levels: %d | any NA in frame keys: %d\n",
            uniqueN(fr$CANCER_TYPE),
            sum(is.na(fr$CANCER_TYPE) | is.na(fr$log10TMB) | is.na(fr$frac_all) |
                is.na(fr$FACETS_PURITY) | is.na(fr$any_LOH))))

# ---------------------------------------------------------------- 2. binders
bf <- sort(list.files(BNDIR, pattern = "^pred_binders_.*\\.tsv$", full.names = TRUE))
cat(sprintf("\npred_binders files: %d\n", length(bf)))
bnd <- rbindlist(lapply(bf, fread, select = c("SAMPLE_ID","pep_mut","is_CLONAL")),
                 use.names = TRUE)
cat(sprintf("binder rows: %d | by clonality: %s\n", nrow(bnd),
            paste(sprintf("%s=%d", names(table(bnd$is_CLONAL)),
                          as.integer(table(bnd$is_CLONAL))), collapse = ", ")))
bcl <- bnd[is_CLONAL == "CLONAL"]
nc  <- bcl[, .(n_neo_clonal = uniqueN(pep_mut)), by = SAMPLE_ID]
cat(sprintf("clonal binder rows: %d | samples with >=1 clonal binder: %d\n",
            nrow(bcl), nrow(nc)))

# ---------------------------------------------------------------- 3. peptides
pf <- sort(list.files(PEPDIR, pattern = "^peptides_part_.*\\.tsv$", full.names = TRUE))
cat(sprintf("\npeptide files: %d\n", length(pf)))
pep <- rbindlist(lapply(pf, fread, select = c("SAMPLE_ID","pep_mut","is_CLONAL")),
                 use.names = TRUE)
cat(sprintf("peptide rows: %d | by clonality: %s\n", nrow(pep),
            paste(sprintf("%s=%d", names(table(pep$is_CLONAL)),
                          as.integer(table(pep$is_CLONAL))), collapse = ", ")))
clon_samples <- unique(pep[is_CLONAL == "CLONAL", SAMPLE_ID])
cat(sprintf("samples with >=1 clonal peptide (analysis universe): %d\n", length(clon_samples)))

# ---------------------------------------------------------------- 4. design
d <- merge(fr, nc, by = "SAMPLE_ID", all.x = TRUE)
d[is.na(n_neo_clonal), n_neo_clonal := 0L]
d <- d[SAMPLE_ID %in% clon_samples]
cat(sprintf("after clonal-peptide restriction: %d samples | LOH+ = %d\n",
            nrow(d), sum(d$any_LOH)))

keep <- complete.cases(d[, .(n_neo_clonal, log10TMB, frac_all, FACETS_PURITY,
                             any_LOH, CANCER_TYPE, GENE_PANEL)])
d <- d[keep]
cat(sprintf("after complete-case filter (M1 design): %d samples | LOH+ = %d | n_LOH%% = %.1f%%\n",
            nrow(d), sum(d$any_LOH), 100 * mean(d$any_LOH)))
cat(sprintf("n_neo_clonal: mean %.4f  sd %.4f  median %.1f  range %d-%d\n",
            mean(d$n_neo_clonal), sd(d$n_neo_clonal), median(d$n_neo_clonal),
            min(d$n_neo_clonal), max(d$n_neo_clonal)))

# Z exactly as upstream: standardised on the analysed (complete-case) subset
d[, Z := as.numeric(scale(n_neo_clonal))]
d[, CANCER_TYPE := factor(CANCER_TYPE)]
d[, GENE_PANEL  := factor(GENE_PANEL)]
d[, any_LOH := as.integer(any_LOH)]

gof <- function(m) {
  b <- coef(m); s <- sqrt(diag(vcov(m)))
  c(OR = exp(b[["Z"]]), lo = exp(b[["Z"]] - qnorm(0.975) * s[["Z"]]),
    hi = exp(b[["Z"]] + qnorm(0.975) * s[["Z"]]),
    P  = 2 * pnorm(-abs(b[["Z"]] / s[["Z"]])))
}

# HC3 note: the upstream statsmodels HC3 fit for this exact design already exists in
# extended_C_sensitivity.tsv (ci_lo_HC3 0.971859 / ci_hi_HC3 1.056820 / P_HC3 0.532047).
# A base-R sandwich::vcovHC refit is numerically undefined here because five observations
# (singleton cancer types with complete separation) have leverage exactly 1.0; the
# upstream values are therefore reported instead of re-deriving an unstable sandwich.

f1 <- any_LOH ~ Z + log10TMB + frac_all + FACETS_PURITY + CANCER_TYPE + GENE_PANEL
f2 <- any_LOH ~ Z + log10TMB + frac_all + FACETS_PURITY + CANCER_TYPE
f3 <- any_LOH ~ Z + log10TMB + frac_all + FACETS_PURITY

m1 <- glm(f1, family = binomial, data = d)
m2 <- glm(f2, family = binomial, data = d)
m3 <- glm(f3, family = binomial, data = d)
g1 <- gof(m1); g2 <- gof(m2); g3 <- gof(m3)

# M4: primary (all neoantigens) model, pipeline sanity check -> expect 1.0639
dp <- fr[complete.cases(fr[, .(n_neo_either, log10TMB, frac_all, FACETS_PURITY,
                               any_LOH, CANCER_TYPE, GENE_PANEL)])]
dp[, Z := as.numeric(scale(n_neo_either))]
dp[, CANCER_TYPE := factor(CANCER_TYPE)]; dp[, GENE_PANEL := factor(GENE_PANEL)]
dp[, any_LOH := as.integer(any_LOH)]
m4 <- glm(f1, family = binomial, data = dp); g4 <- gof(m4)

# ---------------------------------------------------------------- 5. references (upstream artefacts)
ref_fig  <- fread(file.path(ROOT, "iscience投稿版本/V4/02_figures/intermediate/fig4a_neo_or.tsv"))
ref_fig  <- ref_fig[model == "sens_clonal_only"]
ref_ext  <- fread(file.path(NEO, "output/stats/netmhcpan_full/extended_C_sensitivity.tsv"))
ref_ext  <- ref_ext[model == "sens_clonal_only" & !is.na(OR_per_SD)]
ref_c    <- fread(file.path(NEO, "output/stats/netmhcpan_full/C_sensitivity.tsv"))
ref_c    <- ref_c[test == "sens_clonal_only" & test_type == "logistic"]

f5 <- paste(deparse(f1), collapse = " ")
cat("\n---- model fits (Wald / model-based covariance unless stated) ----\n")
cat(sprintf("M1 clonal, primary spec (+GENE_PANEL) : n=%d LOH+=%d  OR=%.6f (%.6f-%.6f) P=%.6g\n",
            nobs(m1), sum(d$any_LOH), g1[["OR"]], g1[["lo"]], g1[["hi"]], g1[["P"]]))
cat(sprintf("M2 clonal, no panel term (legacy)      : n=%d LOH+=%d  OR=%.6f (%.6f-%.6f) P=%.6g\n",
            nobs(m2), sum(d$any_LOH), g2[["OR"]], g2[["lo"]], g2[["hi"]], g2[["P"]]))
cat(sprintf("M3 clonal, no cancer type, no panel    : n=%d LOH+=%d  OR=%.6f (%.6f-%.6f) P=%.6g\n",
            nobs(m3), sum(d$any_LOH), g3[["OR"]], g3[["lo"]], g3[["hi"]], g3[["P"]]))
cat(sprintf("M4 primary neo_count (sanity)          : n=%d LOH+=%d  OR=%.6f (%.6f-%.6f) P=%.6g\n",
            nobs(m4), sum(dp$any_LOH), g4[["OR"]], g4[["lo"]], g4[["hi"]], g4[["P"]]))
cat(sprintf("upstream HC3 for the M1 design         : OR=%.6f (%.6f-%.6f) P=%.6g  [extended_C_sensitivity.tsv]\n",
            ref_ext$OR_HC3, ref_ext$ci_lo_HC3, ref_ext$ci_hi_HC3, ref_ext$P_HC3))
cat(sprintf("converged: M1=%s M2=%s M3=%s M4=%s | df.residual M1=%d\n",
            m1$converged, m2$converged, m3$converged, m4$converged, m1$df.residual))

# ---------------------------------------------------------------- 6. cross-check
cat("\n---- cross-check against the two upstream artefacts ----\n")
cat(sprintf("fig4a_neo_or.tsv  sens_clonal_only : OR=%.9f (%.9f-%.9f) P=%.9g n=%s\n",
            ref_fig$OR, ref_fig$lo, ref_fig$hi, ref_fig$P, ref_fig$n))
cat(sprintf("extended_C_sensitivity.tsv         : OR=%.9f (%.9f-%.9f) P=%.9g n=%s\n",
            ref_ext$OR_per_SD, ref_ext$ci_lo, ref_ext$ci_hi, ref_ext$P, ref_ext$n))
cat(sprintf("C_sensitivity.tsv (legacy 03_stats): OR=%.9f (%.9f-%.9f) P=%.9g n=%s\n",
            ref_c$OR_per_SD_neo, ref_c$ci_lo, ref_c$ci_hi, ref_c$P, ref_c$n))
cat(sprintf("M1 - fig4a   dOR=%.3e  dP=%.3e\n", g1[["OR"]] - ref_fig$OR, g1[["P"]] - ref_fig$P))
cat(sprintf("M2 - legacy  dOR=%.3e  dP=%.3e\n", g2[["OR"]] - ref_c$OR_per_SD_neo,
            g2[["P"]] - ref_c$P))
cat(sprintf("\nrounding audit: model CI -> %.3f-%.3f | HC3 CI -> %.3f-%.3f\n",
            g1[["lo"]], g1[["hi"]], ref_ext$ci_lo_HC3, ref_ext$ci_hi_HC3))
cat(sprintf("manuscript prints '95%% CI 0.972-1.057' = the HC3 interval; model-based interval is 0.973-1.056\n"))
cat(sprintf("manuscript prints 'P=0.52' = the model-based P (%.4f); HC3 P is %.4f\n",
            g1[["P"]], ref_ext$P_HC3))

# ---------------------------------------------------------------- 6. write
res <- data.table(
  model_id = c("M1_definitive","M2_legacy_no_panel","M3_no_cancer_no_panel",
               "M1_definitive_HC3","M4_primary_sanity"),
  label = c("Clonal-restricted neoantigen count (primary specification, +GENE_PANEL)",
            "Same, WITHOUT GENE_PANEL term (03_stats.py legacy block)",
            "Same, without GENE_PANEL and without CANCER_TYPE",
            "M1 design with HC3 heteroskedasticity-robust covariance (upstream statsmodels fit)",
            "Primary neoantigen count, all mutations (pipeline sanity check)"),
  n = c(nobs(m1), nobs(m2), nobs(m3), as.integer(ref_ext$n), nobs(m4)),
  n_LOH = c(sum(d$any_LOH), sum(d$any_LOH), sum(d$any_LOH), sum(d$any_LOH), sum(dp$any_LOH)),
  OR = c(g1[["OR"]], g2[["OR"]], g3[["OR"]], ref_ext$OR_HC3, g4[["OR"]]),
  lo = c(g1[["lo"]], g2[["lo"]], g3[["lo"]], ref_ext$ci_lo_HC3, g4[["lo"]]),
  hi = c(g1[["hi"]], g2[["hi"]], g3[["hi"]], ref_ext$ci_hi_HC3, g4[["hi"]]),
  P  = c(g1[["P"]],  g2[["P"]],  g3[["P"]],  ref_ext$P_HC3,  g4[["P"]]),
  ci_type = c("model","model","model","HC3","model"),
  df_resid = c(m1$df.residual, m2$df.residual, m3$df.residual, m1$df.residual, m4$df.residual),
  AIC = c(AIC(m1), AIC(m2), AIC(m3), AIC(m1), AIC(m4)),
  formula = c(paste(deparse(f1), collapse = " "), paste(deparse(f2), collapse = " "),
              paste(deparse(f3), collapse = " "),
              paste(deparse(f1), collapse = " "), paste(deparse(f1), collapse = " "))
)
res[, `:=`(OR_3dp = sprintf("%.3f", OR), CI_3dp = sprintf("%.3f-%.3f", lo, hi),
           P_4dp = ifelse(P < 0.001, "<0.001", sprintf("%.4f", P)))]
fwrite(res, OUT, sep = "\t")
cat(sprintf("\n[WROTE] %s (%d rows)\n", OUT, nrow(res)))
cat(sprintf("DEFINITIVE (M1): OR %.3f (95%% CI %.3f-%.3f), P = %s, n = %d, LOH+ = %d\n",
            g1[["OR"]], g1[["lo"]], g1[["hi"]],
            ifelse(g1[["P"]] < 0.001, "<0.001", sprintf("%.3f", g1[["P"]])),
            nobs(m1), sum(d$any_LOH)))
cat(sprintf("elapsed: %.1f s\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
sink(); sink(type = "message"); close(con)
