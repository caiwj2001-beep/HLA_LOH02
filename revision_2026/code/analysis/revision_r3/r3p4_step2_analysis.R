## R3 part4 — step 2: is the "arm-independent" HLA-LOH subgroup an artifact of
## low purity / low coverage / panel version?  Build 3-group stratification,
## logistic models, purity-decile trend, and HLA gene-level CNA check.
suppressMessages({library(data.table); library(survival)})
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
OUT  <- file.path(ROOT, "iscience投稿版本/V2")
options(stringsAsFactors = FALSE)

mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"))
p  <- mc[analysis_primary == "TRUE"]
cat("primary n:", nrow(p), "\n")

## ---- cleaned numeric fields ------------------------------------------------
num <- function(x) suppressWarnings(as.numeric(x))
p[, cov  := num(SAMPLE_COVERAGE)]                    # sequencing coverage (x)
p[, pur_f := num(FACETS_PURITY) * 100]               # FACETS purity -> percent
p[, ploidy := num(FACETS_PLOIDY)]
p[, pur_p := num(TUMOR_PURITY)]                      # pathologist purity (%)
p[pur_p < 0 | pur_p > 100, pur_p := NA]              # drop malformed (1000-9000)
p[, wgd := FACETS_WGD]

## ---- 3 groups --------------------------------------------------------------
p[, grp := fifelse(any_HLA_LOH == "TRUE" & arm_6p_loss == "TRUE", "Arm_dependent",
            fifelse(any_HLA_LOH == "TRUE" & arm_6p_loss == "FALSE", "Arm_independent",
            fifelse(any_HLA_LOH == "FALSE", "No_LOH", "LOH_6p_missing")))]
cat("\n== group sizes ==\n"); print(table(p$grp, useNA = "ifany"))

G3 <- c("No_LOH", "Arm_independent", "Arm_dependent")
d3 <- p[grp %in% G3]
d3[, grp := factor(grp, levels = G3)]

## ---- helpers ---------------------------------------------------------------
fmt <- function(x, d = 3) formatC(round(x, d), format = "f", digits = d)
fmtp <- function(x) ifelse(is.na(x), "NA",
             ifelse(x < 1e-4, formatC(x, format = "e", digits = 2), formatC(x, format = "f", digits = 4)))

qrow <- function(v, g) {
  q <- quantile(v, probs = c(0, .1, .25, .5, .75, .9, 1), na.rm = TRUE)
  data.table(grp = g, n_nonmiss = sum(!is.na(v)), n_miss = sum(is.na(v)),
             min = q[1], p10 = q[2], q1 = q[3], median = q[4], q3 = q[5], p90 = q[6], max = q[7],
             mean = mean(v, na.rm = TRUE), sd = sd(v, na.rm = TRUE))
}

rows <- list()   # tidy result rows: (section, item, group/level, value, extra)
add <- function(...) rows[[length(rows) + 1]] <<- data.table(...)

## ===========================================================================
## TASK 1 — three-group stratification of technical / QC variables
## ===========================================================================
cat("\n########## TASK 1 ##########\n")

dvals  <- c("pur_f", "pur_p", "cov", "ploidy")
dlab   <- c(pur_f = "FACETS_PURITY_pct", pur_p = "Pathologist_purity_pct",
            cov = "SAMPLE_COVERAGE", ploidy = "FACETS_PLOIDY")
qtab <- rbindlist(lapply(dvals, function(v) {
  vv <- d3[[v]]
  rbindlist(lapply(G3, function(g) qrow(vv[d3$grp == g], g)))[, variable := dlab[v]]
}), use.names = TRUE)
setcolorder(qtab, c("variable", "grp"))
print(qtab)
add(section = "T1_distribution", item = "quantiles_by_variable_group",
    group = qtab$grp, value = qtab$median, extra = paste0("var=", qtab$variable))

## deciles of purity per group
dec_tab <- rbindlist(lapply(c("pur_f", "pur_p", "cov"), function(vv) {
  rbindlist(lapply(G3, function(g) {
    x <- d3[grp == g][[vv]]
    qd <- quantile(x, probs = seq(0, 1, .1), na.rm = TRUE)
    data.table(variable = vv, grp = g,
               decile = 1:10,
               upper = qd[2:11])
  }))
}))
add(section = "T1_deciles", item = "purity_coverage_decile_upper_bounds",
    group = paste(dec_tab$variable, dec_tab$grp), value = dec_tab$upper)

## Kruskal-Wallis for continuous
ktab <- rbindlist(lapply(dvals, function(v) {
  vv <- d3[[v]]; ok <- !is.na(vv)
  k <- kruskal.test(vv[ok], d3$grp[ok])
  data.table(variable = dlab[v], test = "Kruskal-Wallis", statistic = unname(k$statistic),
             df = unname(k$parameter), p = k$p.value)
}))
print(ktab)
add(section = "T1_kruskal", item = "kruskal_p", group = ktab$variable, value = ktab$p)

## pairwise Wilcoxon vs No_LOH (reference group)
wt <- rbindlist(lapply(dvals, function(v) {
  vv <- d3[[v]]
  rbindlist(lapply(c("Arm_independent", "Arm_dependent"), function(g) {
    a <- vv[d3$grp == g]; b <- vv[d3$grp == "No_LOH"]
    w <- suppressWarnings(wilcox.test(a, b))
    data.table(variable = dlab[v], contrast = paste0(g, "_vs_No_LOH"),
               median_test = median(a, na.rm = TRUE), median_ref = median(b, na.rm = TRUE),
               p = w$p.value)
  }))
}))
add(section = "T1_wilcox", item = "pairwise_wilcoxon", group = paste(wt$variable, wt$contrast), value = wt$p)

## categorical: GENE_PANEL, MSI_TYPE, FACETS_WGD, FACETS_QC ; chi-square
cat_vars <- c("GENE_PANEL", "MSI_TYPE", "wgd", "FACETS_QC")
ctab <- list()
for (v in cat_vars) {
  tb <- table(d3$grp, d3[[v]], useNA = "ifany")
  ch <- suppressWarnings(chisq.test(tb))
  ct <- data.table(variable = v, level = colnames(tb), t(tb))
  ct[, pct_by_group := NA]
  ctab[[v]] <- ct
  add(section = "T1_chisq", item = paste0("chisq_", v), group = v,
      value = ch$p.value, extra = paste0("stat=", fmt(ch$statistic)))
  cat("\n--", v, "-- chisq p =", fmtp(ch$p.value), "\n"); print(tb)
}
## GENE_PANEL composition % by group
gp <- d3[, .N, by = .(grp, GENE_PANEL)]
gp[, pct := 100 * N / sum(N), by = grp]
print(gp)
add(section = "T1_genepanel_pct", item = "GENE_PANEL_pct_by_group",
    group = paste(gp$grp, gp$GENE_PANEL), value = gp$pct)
## MSI_TYPE proportions %
ms <- d3[, .N, by = .(grp, MSI_TYPE)]; ms[, pct := 100 * N / sum(N), by = grp]
add(section = "T1_msi_pct", item = "MSI_TYPE_pct_by_group",
    group = paste(ms$grp, ms$MSI_TYPE), value = ms$pct)

## ===========================================================================
## TASK 2 — logistic: Arm_independent vs Arm_dependent
## ===========================================================================
cat("\n########## TASK 2 ##########\n")
set.seed(1)
prep <- function(dt) {
  dt <- copy(dt)
  ## collapse rare CANCER_TYPE
  dt[, CANCER_TYPE := as.character(CANCER_TYPE)]
  freq <- dt[, .N, by = CANCER_TYPE][order(-N)]
  keep <- freq[N >= 50]$CANCER_TYPE
  dt[!(CANCER_TYPE %in% keep), CANCER_TYPE := "Other"]
  dt[, CANCER_TYPE := factor(CANCER_TYPE)]
  dt[, GENE_PANEL := factor(GENE_PANEL)]
  dt[, wgd_f := factor(ifelse(is.na(wgd), NA, as.character(wgd)), levels = c("FALSE", "TRUE"))]
  dt[, pur_f := pur_f]                       # FACETS purity %
  dt[, cov := cov]
  dt
}
extract <- function(m, scale_note) {
  s <- summary(m)$coefficients
  ci <- suppressMessages(confint(m))
  out <- data.table(term = rownames(s), beta = s[, 1], se = s[, 2],
                    OR = exp(s[, 1]), lo = exp(ci[, 1]), hi = exp(ci[, 2]),
                    p = s[, 4], note = scale_note)
  out[, `:=`(OR = round(OR, 3), lo = round(lo, 3), hi = round(hi, 3), p = signif(p, 3))]
  out
}

## --- Model 2A: Arm_independent (1) vs Arm_dependent (0)
d2 <- prep(d3[grp %in% c("Arm_independent", "Arm_dependent")])
d2[, y := as.integer(grp == "Arm_independent")]
cat("n model2 =", nrow(d2), " events(arm_ind) =", sum(d2$y), "\n")
m2 <- glm(y ~ pur_f + cov + GENE_PANEL + CANCER_TYPE + wgd_f,
          data = d2, family = binomial())
r2 <- extract(m2, "purity per +1%; coverage per +1x")
cat("\n== Model 2: Arm_independent vs Arm_dependent ==\n")
print(r2[term %in% c("pur_f", "cov", "GENE_PANELIMPACT410", "GENE_PANELIMPACT505",
                     "wgd_fTRUE", "CANCER_TYPEBreast Cancer", "CANCER_TYPEColorectal Cancer",
                     "CANCER_TYPENon-Small Cell Lung Cancer", "CANCER_TYPEPancreatic Cancer",
                     "CANCER_TYPEMelanoma"), ])
add(section = "T2_model", item = "logit_armind_vs_armdep", group = r2$term,
    value = r2$OR, extra = paste0("lo=", r2$lo, " hi=", r2$hi, " p=", r2$p))
## scaled versions: purity per -10% (1 SD-ish), coverage per +100x
b <- coef(m2); se <- summary(m2)$coefficients[, 2]
scal <- data.table(
  term = c("pur_f_per_minus10pct", "cov_per_plus100x"),
  OR = exp(c(-10 * b["pur_f"], 100 * b["cov"])),
  lo = exp(c(-10 * b["pur_f"] - 1.96 * 10 * se["pur_f"], 100 * b["cov"] - 1.96 * 100 * se["cov"])),
  hi = exp(c(-10 * b["pur_f"] + 1.96 * 10 * se["pur_f"], 100 * b["cov"] + 1.96 * 100 * se["cov"])),
  p  = c(summary(m2)$coefficients["pur_f", 4], summary(m2)$coefficients["cov", 4]))
cat("\n== Model 2 scaled ==\n"); print(scal)
add(section = "T2_model_scaled", item = "logit_armind_vs_armdep_scaled", group = scal$term,
    value = round(scal$OR, 3), extra = paste0("lo=", round(scal$lo, 3), " hi=", round(scal$hi, 3), " p=", signif(scal$p, 3)))

## --- purity-decile trend of arm-independent fraction
tr <- rbindlist(lapply(c("pur_f", "pur_p", "cov"), function(vv) {
  x <- d2[[vv]]
  qd <- unique(quantile(x, probs = seq(0, 1, .1), na.rm = TRUE))
  d2[, dec := cut(x, breaks = qd, include.lowest = TRUE, labels = FALSE, dig.lab = 6)]
  t <- d2[!is.na(dec), .(n = .N, n_ind = sum(y),
                          pct_ind = 100 * mean(y),
                          lo = 100 * mean(y) - 1.96 * 100 * sqrt(mean(y) * (1 - mean(y)) / .N),
                          hi = 100 * mean(y) + 1.96 * 100 * sqrt(mean(y) * (1 - mean(y)) / .N)),
           by = dec][order(dec)]
  t[, variable := vv]
  ## Cochran-Armitage trend test
  ca <- suppressWarnings(prop.trend.test(t$n_ind, t$n, score = t$dec))
  t[, trend_p := ca$p.value]
  t
}))
cat("\n== purity/coverage decile trend of arm-independent fraction ==\n"); print(tr)
add(section = "T2_decile_trend", item = "armind_pct_by_decile",
    group = paste(tr$variable, "D", tr$dec), value = round(tr$pct_ind, 2),
    extra = paste0("n=", tr$n, " trend_p=", signif(tr$trend_p, 3)))

## ===========================================================================
## TASK 3 — logistic: Arm_independent (1) vs No_LOH (0)
## ===========================================================================
cat("\n########## TASK 3 ##########\n")
d3b <- prep(d3[grp %in% c("Arm_independent", "No_LOH")])
d3b[, y := as.integer(grp == "Arm_independent")]
cat("n model3 =", nrow(d3b), " events(arm_ind) =", sum(d3b$y), "\n")
m3 <- glm(y ~ pur_f + cov + GENE_PANEL + CANCER_TYPE + wgd_f, data = d3b, family = binomial())
r3m <- extract(m3, "per +1% / +1x")
cat("\n== Model 3: Arm_independent vs No_LOH ==\n")
print(r3m[term %in% c("pur_f", "cov", "GENE_PANELIMPACT410", "GENE_PANELIMPACT505", "wgd_fTRUE"), ])
add(section = "T3_model", item = "logit_armind_vs_NoLOH", group = r3m$term,
    value = r3m$OR, extra = paste0("lo=", r3m$lo, " hi=", r3m$hi, " p=", r3m$p))
b3 <- coef(m3); se3 <- summary(m3)$coefficients[, 2]
scal3 <- data.table(term = c("pur_f_per_minus10pct", "cov_per_plus100x", "wgd_TRUE"),
  OR = exp(c(-10 * b3["pur_f"], 100 * b3["cov"], b3["wgd_fTRUE"])),
  lo = exp(c(-10 * b3["pur_f"] - 19.6 * se3["pur_f"], 100 * b3["cov"] - 196 * se3["cov"], b3["wgd_fTRUE"] - 1.96 * se3["wgd_fTRUE"])),
  hi = exp(c(-10 * b3["pur_f"] + 19.6 * se3["pur_f"], 100 * b3["cov"] + 196 * se3["cov"], b3["wgd_fTRUE"] + 1.96 * se3["wgd_fTRUE"])),
  p  = c(summary(m3)$coefficients["pur_f", 4], summary(m3)$coefficients["cov", 4], summary(m3)$coefficients["wgd_fTRUE", 4]))
cat("\n== Model 3 scaled ==\n"); print(scal3)
add(section = "T3_model_scaled", item = "logit_armind_vs_NoLOH_scaled", group = scal3$term,
    value = round(scal3$OR, 3), extra = paste0("lo=", round(scal3$lo, 3), " hi=", round(scal3$hi, 3), " p=", signif(scal3$p, 3)))

## compare arm-independent fraction among ALL LOH vs among HLA-LOH irrespective of 6p
cat("\n== among HLA-LOH (any), arm-independent fraction by purity decile ==\n")
dl <- d3[grp %in% c("Arm_independent", "Arm_dependent")]
dl[, y := as.integer(grp == "Arm_independent")]
qd <- unique(quantile(dl$pur_f, probs = seq(0, 1, .1), na.rm = TRUE))
dl[, dec := cut(pur_f, breaks = qd, include.lowest = TRUE, labels = FALSE, dig.lab = 6)]
tt <- dl[!is.na(dec), .(n = .N, pct_ind = 100 * mean(y)), by = dec][order(dec)]
print(tt)
add(section = "T3_alt", item = "armind_fraction_by_purity_decile_among_LOH",
    group = paste0("D", tt$dec), value = round(tt$pct_ind, 2), extra = paste0("n=", tt$n))

## ===========================================================================
## TASK 4 — HLA-A/B/C gene-level CNA (GISTIC discrete) vs group
## ===========================================================================
cat("\n########## TASK 4 ##########\n")
hla_f <- "C:/Users/Administrator/AppData/Local/hermes/cache/scratch/hla_cna_rows.tsv"
cna <- fread(hla_f)
cat("HLA rows found:", nrow(cna), "cols:", ncol(cna), "\n")
long <- melt(cna, id.vars = "Hugo_Symbol", variable.name = "SAMPLE_ID", value.name = "cn")
long[, cn := as.character(cn)]
cat("value classes (all samples):\n"); print(table(long$cn, useNA = "ifany"))
long[, call := fifelse(cn %in% c("NA", "", "-", "nan"), "missing",
               fifelse(cn == "0", "diploid",
               fifelse(cn == "-2", "deep_del",
               fifelse(cn == "-1", "shallow_del", "amp"))))]
cc <- merge(d3[, .(SAMPLE_ID, grp)], long, by = "SAMPLE_ID", all.x = TRUE)
cc <- cc[!is.na(Hugo_Symbol)]
cat("\nmerged rows (sample x HLA gene):", nrow(cc), "\n")

## per group x gene call distribution
ct4 <- cc[, .N, by = .(grp, Hugo_Symbol, call)]
ct4[, pct := 100 * N / sum(N), by = .(grp, Hugo_Symbol)]
print(ct4[order(grp, Hugo_Symbol, call)])
add(section = "T4_call", item = "HLA_genecall_pct",
    group = paste(ct4$grp, ct4$Hugo_Symbol, ct4$call), value = round(ct4$pct, 3))

## per-sample aggregates
agg <- cc[, .(n_deepdel = sum(call == "deep_del"),
              n_amp = sum(call == "amp"),
              n_diploid = sum(call == "diploid")), by = .(SAMPLE_ID, grp)]
agg[, any_deepdel := n_deepdel > 0]
s4 <- agg[, .(n = .N, any_deepdel_n = sum(any_deepdel),
              any_deepdel_pct = 100 * mean(any_deepdel),
              n_genes_deepdel_total = sum(n_deepdel)), by = grp]
print(s4)
add(section = "T4_anysample", item = "pct_samples_with_any_HLA_gene_deepdel",
    group = s4$grp, value = round(s4$any_deepdel_pct, 3),
    extra = paste0("n_deepdel_samples=", s4$any_deepdel_n, " / ", s4$n))
for (g in G3) {
  a <- agg[grp == g]$any_deepdel; b <- agg[grp == "No_LOH"]$any_deepdel
  ft <- tryCatch(fisher.test(matrix(c(sum(a), length(a) - sum(a), sum(b), length(b) - sum(b)), 2)),
                 error = function(e) NULL)
  if (!is.null(ft))
    add(section = "T4_fisher", item = paste0("deepdel_", g, "_vs_NoLOH"),
        group = g, value = signif(ft$p.value, 3),
        extra = paste0("OR=", round(unname(ft$estimate), 3), " ; n_del=", sum(a), "/", length(a)))
}
## among HLA-LOH (arm-ind vs arm-dep) Fisher
a <- agg[grp == "Arm_independent"]$any_deepdel; b <- agg[grp == "Arm_dependent"]$any_deepdel
ft <- fisher.test(matrix(c(sum(a), length(a) - sum(a), sum(b), length(b) - sum(b)), 2))
cat("\n[Fisher] deep deletion Arm_independent vs Arm_dependent: p =", signif(ft$p.value, 3),
    " OR =", round(unname(ft$estimate), 3),
    " (", sum(a), "/", length(a), " vs ", sum(b), "/", length(b), ")\n")
add(section = "T4_fisher", item = "deepdel_Arm_independent_vs_Arm_dependent",
    group = "Arm_independent_vs_Arm_dependent", value = signif(ft$p.value, 3),
    extra = paste0("OR=", round(unname(ft$estimate), 3), " ; ", sum(a), "/", length(a),
                   " vs ", sum(b), "/", length(b)))

## ===========================================================================
## save tidy outputs
## ===========================================================================
res <- rbindlist(rows, fill = TRUE)
fwrite(res, file.path(OUT, "r3p4_stats_rows.tsv"), sep = "\t")

## save an object for later assembly
saveRDS(list(p = p, d3 = d3, qtab = qtab, dec_tab = dec_tab, ktab = ktab, wt = wt,
             gp = gp, ms = ms, m2 = m2, r2 = r2, scal = scal, tr = tr,
             m3 = m3, r3m = r3m, scal3 = scal3, ct4 = ct4, s4 = s4, agg = agg,
             G3 = G3, d2n = nrow(d2), d3n = nrow(d3b)),
        file.path(OUT, "r3p4_data.rds"))
cat("\nDONE. rows:", nrow(res), "\n")
