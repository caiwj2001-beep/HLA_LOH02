## P2-13 / P1-6 : purity-by-group, purity-decile arm-support, shallow-panel footprint
## Purpose: recompute three numbers from raw / intermediate tables on disk.
##   (1) median purity + IQR + n by call group (arm-independent / arm-dependent / no LOH)
##   (2) arm-independent vs arm-support(arm-dependent) share in purity deciles D1 and D10
##   (3) median coding mutations per sample and implied panel footprint (Mb)
## READ-ONLY on all existing deliverables. Writes only into V4/QC/P2/.
suppressMessages({library(data.table)})
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
OUT  <- file.path(ROOT, "iscience投稿版本/V4/QC/P2")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

MASTER <- file.path(ROOT, "V6/04_processed_data/master_cohort.tsv")
MAF    <- file.path(ROOT, "msk_impact_50k_2026/data_mutations.txt")
NEOCLIN<- file.path(ROOT, "msk_impact_50k_2026/data_clinical_sample.txt")
FRAME  <- file.path(ROOT, "neoantigen/output/stats/netmhcpan_full/analysis_frame.tsv")

rows <- list()
add <- function(section, item, group, n = NA, value = NA, extra = "") {
  rows[[length(rows) + 1L]] <<- data.table(section = section, item = item,
    group = group, n = n, value = value, extra = extra)
}
p3 <- function(x, d = 4) formatC(round(x, d), format = "f", digits = d)

cat("=====================================================================\n")
cat(" P2-13 / P1-6  purity + panel footprint recomputation\n")
cat(" R:", R.version.string, " | started:", format(Sys.time()), "\n")
cat("=====================================================================\n\n")

## ------------------------------------------------------------------ (0) cohort
mc <- fread(MASTER)
cat("--- master_cohort.tsv ---\n")
cat("rows (all samples)        :", nrow(mc), "\n")
cat("cols                      :", ncol(mc), "\n")
cat("analysis_primary == TRUE  :", sum(mc$analysis_primary == "TRUE"), "\n")
cat("HLA_GENOTYPE_AVAILABLE    :", sum(mc$HLA_GENOTYPE_AVAILABLE == "TRUE"), "\n\n")

num <- function(x) suppressWarnings(as.numeric(x))
p <- mc[analysis_primary == "TRUE"]
p[, pur_f  := num(FACETS_PURITY) * 100]   # FACETS purity -> percent
p[, pur_p  := num(TUMOR_PURITY)]          # pathologist purity (%)
p[pur_p < 0 | pur_p > 100, pur_p := NA]
p[, cov    := num(SAMPLE_COVERAGE)]
p[, ploidy := num(FACETS_PLOIDY)]
p[, wgd    := FACETS_WGD]

## EXACT group rule copied from V2/r3p4_step2_analysis.R lines 23-25
p[, grp := fifelse(any_HLA_LOH == "TRUE" & arm_6p_loss == "TRUE",  "Arm_dependent",
            fifelse(any_HLA_LOH == "TRUE" & arm_6p_loss == "FALSE", "Arm_independent",
            fifelse(any_HLA_LOH == "FALSE",                          "No_LOH",
                                                                     "LOH_6p_missing")))]
G3 <- c("No_LOH", "Arm_independent", "Arm_dependent")
cat("--- group sizes (analysis_primary) ---\n")
print(table(p$grp, useNA = "ifany"))
add("00_cohort", "n_analysis_primary", "all", nrow(p))
for (g in c(G3, "LOH_6p_missing")) add("00_cohort", "n_by_group", g, sum(p$grp == g))

d3 <- p[grp %in% G3]
d3[, grp := factor(grp, levels = G3)]

## ------------------------------------------------- (1) purity medians by group
cat("\n########## (1) purity by call group ##########\n")
qrow <- function(v, g) {
  q <- quantile(v, probs = c(.25, .5, .75), na.rm = TRUE)
  data.table(grp = g, n_total = length(v), n_nonmiss = sum(!is.na(v)),
             n_miss = sum(is.na(v)), q1 = q[1], median = q[2], q3 = q[3],
             mean = mean(v, na.rm = TRUE), min = min(v, na.rm = TRUE),
             max = max(v, na.rm = TRUE))
}
qtab <- rbindlist(lapply(G3, function(g) qrow(d3[grp == g]$pur_f, g)))
qp   <- rbindlist(lapply(G3, function(g) qrow(d3[grp == g]$pur_p, g)))
setnames(qtab, "grp", "group"); setnames(qp, "grp", "group")
cat("\nFACETS purity (%) by group:\n");     print(qtab)
cat("\nPathologist purity (%) by group:\n"); print(qp)
for (i in seq_len(nrow(qtab)))
  add("01_purity_by_group", "FACETS_purity_pct", as.character(qtab$group[i]),
      qtab$n_nonmiss[i], p3(qtab$median[i], 1),
      paste0("IQR=", p3(qtab$q1[i], 1), "-", p3(qtab$q3[i], 1),
             "; n_total=", qtab$n_total[i], "; n_missing=", qtab$n_miss[i]))
for (i in seq_len(nrow(qp)))
  add("01_purity_by_group", "Pathologist_purity_pct", as.character(qp$group[i]),
      qp$n_nonmiss[i], p3(qp$median[i], 1),
      paste0("IQR=", p3(qp$q1[i], 1), "-", p3(qp$q3[i], 1),
             "; n_missing=", qp$n_miss[i]))
kt <- kruskal.test(d3$pur_f, d3$grp)
cat(sprintf("\nKruskal-Wallis FACETS purity (3 groups): chi2=%.3f df=%d p=%.4g\n",
            unname(kt$statistic), unname(kt$parameter), kt$p.value))
add("01_purity_by_group", "KruskalWallis_FACETS_purity", "3-group", nrow(d3),
    signif(kt$p.value, 4), paste0("chi2=", round(unname(kt$statistic), 3)))
for (g in c("Arm_independent", "Arm_dependent")) {
  a <- d3[grp == g]$pur_f; b <- d3[grp == "No_LOH"]$pur_f
  w <- suppressWarnings(wilcox.test(a, b))
  cat(sprintf("Wilcoxon %s vs No_LOH: p=%.4g (medians %.0f vs %.0f)\n",
              g, w$p.value, median(a, na.rm = TRUE), median(b, na.rm = TRUE)))
  add("01_purity_by_group", paste0("Wilcoxon_", g, "_vs_No_LOH"), "3-group",
      NA, signif(w$p.value, 4))
}
wgd_tab <- d3[, .(n = .N, n_wgd = sum(wgd == "TRUE", na.rm = TRUE),
                  pct = 100 * mean(wgd == "TRUE", na.rm = TRUE)), by = grp]
cat("\nWGD TRUE share by group (manuscript quotes 14.1 / 54.2 / 23.0):\n"); print(wgd_tab)
for (i in seq_len(nrow(wgd_tab)))
  add("01_purity_by_group", "pct_WGD_TRUE", as.character(wgd_tab$grp[i]),
      wgd_tab$n[i], p3(wgd_tab$pct[i], 1), paste0("n_wgd=", wgd_tab$n_wgd[i]))

## ------------------------------------- (2) purity deciles: arm-indep vs arm-support
cat("\n########## (2) purity deciles of the LOH cohort ##########\n")
## same construction as r3p4_step2_analysis.R: deciles of pur_f WITHIN LOH only
dl <- d3[grp %in% c("Arm_independent", "Arm_dependent")]
dl[, y := as.integer(grp == "Arm_independent")]
cat("LOH cohort n =", nrow(dl), " (arm-independent =", sum(dl$y),
    ", arm-dependent =", sum(1 - dl$y), ")\n")

qd <- unique(quantile(dl$pur_f, probs = seq(0, 1, .1), na.rm = TRUE))
cat("decile breakpoints used (quantile, probs = 0,.1,...,1 ; unique):\n")
print(qd)
dl[, dec := cut(pur_f, breaks = qd, include.lowest = TRUE, labels = FALSE, dig.lab = 6)]
tr <- dl[!is.na(dec), .(n = .N,
                        n_armind = sum(y),
                        n_support = sum(1L - y),
                        pct_armind = 100 * mean(y),
                        pct_support = 100 * mean(1L - y),
                        lo_pur = min(pur_f), hi_pur = max(pur_f),
                        med_pur = median(pur_f)), by = dec][order(dec)]
cat("\nArm-independent share by FACETS-purity decile (LOH cohort):\n")
print(tr)
for (i in seq_len(nrow(tr)))
  add("02_purity_decile_LOH", "arm_independent_share_pct", paste0("D", tr$dec[i]),
      tr$n[i], p3(tr$pct_armind[i], 2),
      paste0("n_armind=", tr$n_armind[i], "; n_armsupport=", tr$n_support[i],
             "; arm_support_pct=", p3(tr$pct_support[i], 2),
             "; purity_range=", p3(tr$lo_pur[i], 1), "-", p3(tr$hi_pur[i], 1),
             "; med_purity=", p3(tr$med_pur[i], 1)))
ca <- suppressWarnings(prop.trend.test(tr$n_armind, tr$n, score = tr$dec))
cat(sprintf("\nCochran-Armitage trend (score = decile index): chi2=%.4g p=%.4g\n",
            unname(ca$statistic), ca$p.value))
add("02_purity_decile_LOH", "CochranArmitage_trend", "D1..D10", sum(tr$n),
    signif(ca$p.value, 4), paste0("chi2=", signif(unname(ca$statistic), 6)))

## cross-check with exactly equal-sized deciles (rank based)
dl <- dl[!is.na(pur_f)]
dl[, dec_eq := pmin(10L, ceiling(rank(pur_f, ties.method = "first") / (.N / 10)))]
tr2 <- dl[!is.na(dec_eq), .(n = .N, n_armind = sum(y), pct_armind = 100 * mean(y)),
          by = dec_eq][order(dec_eq)]
cat("\ncross-check, exactly equal-count deciles (ntile):\n"); print(tr2)
for (i in seq_len(nrow(tr2)))
  add("02_purity_decile_LOH_xcheck_ntile", "arm_independent_share_pct",
      paste0("neq", tr2$dec_eq[i]), tr2$n[i], p3(tr2$pct_armind[i], 2),
      paste0("n_armind=", tr2$n_armind[i]))

## headline numbers
d1 <- tr[dec == 1]; d10 <- tr[dec == max(dec)]
cat("\n>>> D1 (lowest purity) : arm-independent ", p3(d1$pct_armind, 2),
    "% (", d1$n_armind, "/", d1$n, ")  | arm-support ", p3(d1$pct_support, 2), "%\n", sep = "")
cat(">>> D10 (highest purity): arm-independent ", p3(d10$pct_armind, 2),
    "% (", d10$n_armind, "/", d10$n, ")  | arm-support ", p3(d10$pct_support, 2), "%\n", sep = "")

## binomial CI on D10 support share
bi <- binom.test(d10$n_support, d10$n)
cat(sprintf("    D10 arm-support 95%% CI = %.2f%% - %.2f%% (n=%d)\n",
            100 * bi$conf.int[1], 100 * bi$conf.int[2], d10$n))
add("02_purity_decile_LOH", "D10_arm_support_pct", "D10", d10$n,
    p3(d10$pct_support, 2),
    paste0("n_support=", d10$n_support, "/", d10$n, "; 95%CI=",
           p3(100 * bi$conf.int[1], 2), "-", p3(100 * bi$conf.int[2], 2),
           "; = 100 - ", p3(d10$pct_armind, 2), "% arm-independent"))
add("02_purity_decile_LOH", "D1_arm_support_pct", "D1", d1$n,
    p3(d1$pct_support, 2), paste0("n_support=", d1$n_support, "/", d1$n))

## sensitivity: deciles over the FULL analysis_primary cohort (not LOH-only)
pa <- p[!is.na(pur_f)]
qdF <- unique(quantile(pa$pur_f, probs = seq(0, 1, .1), na.rm = TRUE))
pa[, dec := cut(pur_f, breaks = qdF, include.lowest = TRUE, labels = FALSE, dig.lab = 6)]
trF <- pa[!is.na(dec), .(n = .N, n_loh = sum(any_HLA_LOH == "TRUE", na.rm = TRUE),
                         n_armind = sum(any_HLA_LOH == "TRUE" &
                                        arm_6p_loss == "FALSE", na.rm = TRUE),
                         n_armdep = sum(any_HLA_LOH == "TRUE" &
                                        arm_6p_loss == "TRUE", na.rm = TRUE),
                         n_LOH_6p_known = sum(any_HLA_LOH == "TRUE" &
                                              arm_6p_loss %in% c("TRUE", "FALSE"))),
          by = dec][order(dec)]
trF[, pct_armind_among_LOH := 100 * n_armind / n_LOH_6p_known]
trF[, pct_armdep_among_LOH := 100 * n_armdep / n_LOH_6p_known]
cat("\nalternative definition: deciles over ALL evaluable tumours ---\n"); print(trF)
for (i in seq_len(nrow(trF)))
  add("02_purity_decile_ALLCROSS_SECTION", "arm_independent_share_of_LOH_pct",
      paste0("D", trF$dec[i]), trF$n_LOH_6p_known[i], p3(trF$pct_armind_among_LOH[i], 2),
      paste0("n_armind=", trF$n_armind[i], "/", trF$n_LOH_6p_known[i],
             "; n_armdep=", trF$n_armdep[i],
             "; arm_support_pct=", p3(trF$pct_armdep_among_LOH[i], 2),
             "; decile_n=", trF$n[i]))

## ------------------------------------------------- (3) panel footprint + mutation load
cat("\n########## (3) coding mutation load and panel footprint ##########\n")
fr <- fread(FRAME)
cat("analysis_frame.tsv rows:", nrow(fr), " cols:", ncol(fr), "\n")
nmc <- num(fr$n_mut_coding); pmb <- num(fr$panel_mb); tmb <- num(fr$TMB_SCORE)
cat("\nmedian n_mut_coding  (input samples frame) :", median(nmc, na.rm = TRUE), "\n")
cat("median panel_mb      (>n_mut_coding/TMB)   :", p3(median(pmb, na.rm = TRUE), 4),
    " IQR", p3(quantile(pmb, .25, na.rm = TRUE), 4), "-",
    p3(quantile(pmb, .75, na.rm = TRUE), 4), "\n")
cat("median TMB_SCORE                           :", median(tmb, na.rm = TRUE), "\n")
add("03_panel_footprint", "median_n_mut_coding_per_sample", "analysis_frame", sum(!is.na(nmc)),
    median(nmc, na.rm = TRUE),
    paste0("IQR(unweighted)=raw quantiles ", quantile(nmc, .25, na.rm = TRUE), "-",
           quantile(nmc, .75, na.rm = TRUE), "; mean=",
           p3(mean(nmc, na.rm = TRUE), 2)))
add("03_panel_footprint", "median_implied_panel_Mb", "analysis_frame", sum(!is.na(pmb)),
    p3(median(pmb, na.rm = TRUE), 4),
    paste0("IQR=", p3(quantile(pmb, .25, na.rm = TRUE), 3), "-",
           p3(quantile(pmb, .75, na.rm = TRUE), 3),
           "; = n_mut_coding / TMB_SCORE"))
cat("\nGENE_PANEL composition of the neoantigen analysis frame:\n")
print(fr[, .(n = .N, median_n_mut_coding = median(num(n_mut_coding), na.rm = TRUE),
             median_panel_mb = round(median(num(panel_mb), na.rm = TRUE), 4)),
         by = GENE_PANEL][order(-n)])
gp <- fr[, .(n = .N, median_n_mut_coding = median(num(n_mut_coding), na.rm = TRUE),
             median_panel_mb = median(num(panel_mb), na.rm = TRUE)), by = GENE_PANEL][order(-n)]
for (i in seq_len(nrow(gp)))
  add("03_panel_footprint", "panel_composition", as.character(gp$GENE_PANEL[i]), gp$n[i],
      p3(gp$median_panel_mb[i], 4),
      paste0("median_n_mut_coding=", gp$median_n_mut_coding[i]))

## ---- independent recomputation of n_mut_coding straight from the raw MAF ----
cat("\nreading raw MAF (data_mutations.txt) for the coding-mutation counts ...\n")
t0 <- Sys.time()
maf <- fread(MAF, sep = "\t", select = c("Tumor_Sample_Barcode", "Variant_Classification"),
             showProgress = FALSE)
cat("MAF rows:", nrow(maf), " elapsed:",
    round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "s\n")
CODING <- c("Missense_Mutation", "Nonsense_Mutation", "Frame_Shift_Del",
            "Frame_Shift_Ins", "In_Frame_Del", "In_Frame_Ins",
            "Splice_Site", "Translation_Start_Site", "Nonstop_Mutation")
cat("MAF Variant_Classification table (top 12):\n")
print(head(sort(table(maf$Variant_Classification), decreasing = TRUE), 12))

mc_coding <- maf[Variant_Classification %in% CODING, .(n_mut_coding_maf = .N),
                 by = .(SAMPLE_ID = Tumor_Sample_Barcode)]
fr2 <- merge(fr[, .(SAMPLE_ID, n_mut_coding, TMB_SCORE, GENE_PANEL, FACETS_PURITY)],
             mc_coding, by = "SAMPLE_ID", all.x = TRUE)
fr2[is.na(n_mut_coding_maf), n_mut_coding_maf := 0L]
fr2[, n_mut_ok := num(n_mut_coding) == n_mut_coding_maf]
cat(sprintf("\nMAF-recomputed counts agree with analysis_frame n_mut_coding: %d / %d (%.4f%%)\n",
            sum(fr2$n_mut_ok, na.rm = TRUE), nrow(fr2),
            100 * mean(fr2$n_mut_ok, na.rm = TRUE)))
if (any(!fr2$n_mut_ok, na.rm = TRUE))
  print(head(fr2[!n_mut_ok == TRUE, .(SAMPLE_ID, n_mut_coding, n_mut_coding_maf)], 10))
add("03_panel_footprint", "MAF_recompute_agreement_n_mut_coding", "analysis_frame",
    nrow(fr2), p3(100 * mean(fr2$n_mut_ok, na.rm = TRUE), 4),
    paste0("agreeing=", sum(fr2$n_mut_ok, na.rm = TRUE)))

fr2[, tmb_num := num(TMB_SCORE)]
fr2[, panel_mb_maf := n_mut_coding_maf / tmb_num]
cat("\nmedian n_mut_coding (MAF recompute):", median(fr2$n_mut_coding_maf, na.rm = TRUE), "\n")
cat("median panel_Mb   (n_mut_maf / TMB) :",
    p3(median(fr2$panel_mb_maf, na.rm = TRUE), 4), "[IQR",
    p3(quantile(fr2$panel_mb_maf, .25, na.rm = TRUE), 3), "-",
    p3(quantile(fr2$panel_mb_maf, .75, na.rm = TRUE), 3), "]\n")
add("03_panel_footprint", "median_n_mut_coding_per_sample", "MAF_recompute",
    sum(!is.na(fr2$n_mut_coding_maf)), median(fr2$n_mut_coding_maf, na.rm = TRUE), "")
add("03_panel_footprint", "median_implied_panel_Mb", "MAF_recompute",
    sum(!is.na(fr2$panel_mb_maf)), p3(median(fr2$panel_mb_maf, na.rm = TRUE), 4), "")

## aggregate (ratio-of-totals) estimator, robust to TMB rounding
agg <- fr2[tmb_num > 0, .(mut_tot = sum(n_mut_coding_maf), tmb_tot = sum(tmb_num)), by = GENE_PANEL]
agg[, panel_Mb_agg := mut_tot / tmb_tot]
cat("\nper-panel aggregate footprint (sum coding muts / sum TMB):\n"); print(agg)
for (i in seq_len(nrow(agg)))
  add("03_panel_footprint", "panel_Mb_aggregate", as.character(agg$GENE_PANEL[i]),
      NA, p3(agg$panel_Mb_agg[i], 4),
      paste0("n_mut_total=", agg$mut_tot[i], "; TMB_total=", round(agg$tmb_tot[i], 1)))
add("03_panel_footprint", "panel_Mb_aggregate_ALL", "all panels", NA,
    p3(sum(agg$mut_tot) / sum(agg$tmb_tot), 4),
    paste0("n_mut_total=", sum(agg$mut_tot), "; TMB_total=", round(sum(agg$tmb_tot), 1)))

## whole analysis_primary cohort mutation load (same MAF definition)
ids <- p$SAMPLE_ID
mc_all <- maf[Variant_Classification %in% CODING & Tumor_Sample_Barcode %in% ids,
              .(n = .N), by = .(SAMPLE_ID = Tumor_Sample_Barcode)]
cat("\nanalysis_primary cohort (n =", nrow(p), "): samples with >=1 MAF coding mutation:",
    nrow(mc_all), "; median coding mutations per sample =", median(mc_all$n), "\n")
cat("(zero-mutation samples would sit below this median; share with 0 =",
    p3(100 * (nrow(p) - nrow(mc_all)) / nrow(p), 2), "%)\n")
add("03_panel_footprint", "median_n_mut_coding_per_sample", "analysis_primary_with_mutations",
    nrow(mc_all), median(mc_all$n),
    paste0("samples_with_zero_coding_mut=", nrow(p) - nrow(mc_all), " / ", nrow(p)))

cat("\nfinished:", format(Sys.time()), "\n")

## ------------------------------------------------------------------- write out
res <- rbindlist(rows, fill = TRUE)
fwrite(res, file.path(OUT, "purity_and_panel.tsv"), sep = "\t")
cat("wrote", file.path(OUT, "purity_and_panel.tsv"), "rows =", nrow(res), "\n")
print(res[, .N, by = section])
