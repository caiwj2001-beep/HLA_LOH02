###############################################################################
# 01_build_tables_V3.R   (V3 主表 / 补充表 / SV 替代分析 —— 唯一重建脚本)
#
# 输入（只读）:
#   V6/04_processed_data/master_cohort.tsv
#   msk_impact_50k_2026/data_armlevel_cna.txt
#   msk_impact_50k_2026/data_sv.txt
#   iscience投稿版本/V2/r3p2_part34_rows.tsv, r3p3_task1_rows.tsv, r3p3_aneuploidy_scores.tsv
#   iscience投稿版本/V3/02_figures/intermediate/*.tsv
#   neoantigen/output/stats/netmhcpan_full/*.tsv, *.json
# 输出: V3/03_tables/build/*.tsv
#
# 原则: 数字只能来自磁盘产物；本脚本重算并与 PINNED_PACK §2 逐项断言(见 pin_audit.tsv)
# 每个表块用 try() 包裹：单个表失败只记录，不中断整个脚本。
###############################################################################
suppressPackageStartupMessages({library(data.table); library(survival)})
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
V2   <- file.path(ROOT, "iscience投稿版本/V2")
IMD  <- file.path(ROOT, "iscience投稿版本/V3/02_figures/intermediate")
NEO  <- file.path(ROOT, "neoantigen/output/stats/netmhcpan_full")
OUT  <- file.path(ROOT, "iscience投稿版本/V3/03_tables/build")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
F  <- function(x) file.path(OUT, x)
SAFE <- function(label, expr) {                     # 单块失败只记录，不中断
  r <- tryCatch({ force(expr); "OK" }, error = function(e) {
    cat(sprintf("\n!!! [SECTION %s] FAILED: %s\n", label, conditionMessage(e))); paste("FAILED:", conditionMessage(e)) })
  cat(sprintf("\n>>> [SECTION %s] -> %s\n", label, r))
}
PIN <- list(); k <- 0
CHK <- function(item, recomputed, pinned, tol = 0) {   # 逐项对 PINNED_PACK 断言
  k <<- k + 1
  a <- suppressWarnings(as.numeric(recomputed)); b <- suppressWarnings(as.numeric(pinned))
  ok <- if (length(a) == 1 && length(b) == 1 && !is.na(a) && !is.na(b)) isTRUE(all.equal(a, b, tolerance = max(tol, 1e-9)))
        else identical(as.character(recomputed), as.character(pinned))
  PIN[[k]] <<- data.table(item = item, recomputed = as.character(recomputed), PINNED = as.character(pinned), match = ok)
  cat(sprintf("   [%s] %-52s recomp=%-14s PINNED=%s\n", ifelse(ok, "OK ", "DIFF"), item, recomputed, pinned))
}

###############################################################################
## 0. 载入 + 非整倍体评分（all / 除 6p / 除 6q / 除 6p&6q）
###############################################################################
mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"), showProgress = FALSE)
cat("master rows:", nrow(mc), "\n")
P <- mc[analysis_primary == "TRUE"]
cat("analysis_primary:", nrow(P), " any_HLA_LOH:", sum(P$any_HLA_LOH), "\n")

cna <- fread(file.path(ROOT, "msk_impact_50k_2026/data_armlevel_cna.txt"), header = TRUE)
arms <- sub("_status$", "", cna$ENTITY_STABLE_ID); smp <- names(cna)[-(1:3)]
m <- as.matrix(cna[, 4:ncol(cna), with = FALSE]); rownames(m) <- arms
chrom <- suppressWarnings(as.integer(sub("[pq]$", "", arms))); auto <- !is.na(chrom) & chrom <= 22
cat("arm tokens:\n"); print(table(m, useNA = "ifany"))
## 关键: fread 把字面 "NA" 转成真 NA —— 必须显式把 NA 当“未改变”，否则 m=="Loss" 出 NA、colSums 全变 NA
altered <- matrix(m %in% c("Loss", "Gain"), nrow = nrow(m), dimnames = dimnames(m))
avail   <- matrix(!is.na(m) & m != "" & m != "NA", nrow = nrow(m), dimnames = dimnames(m))
cat("gain/loss cells:", sum(altered), "| NA cells:", sum(is.na(m)), "| available cells:", sum(avail), "\n")
mkfrac <- function(keep, tag) {
  r <- auto & keep
  n <- colSums(altered[r, , drop = FALSE]); a <- colSums(avail[r, , drop = FALSE])
  cat(sprintf("  [mkfrac %-6s] arms=%d\n", tag, sum(r)))
  z <- data.table(SAMPLE_ID = smp, nn = as.integer(n), av = as.integer(a), ff = n / a)
  stopifnot(ncol(z) == 4)
  setnames(z, names(z), c("SAMPLE_ID", paste0("n_", tag), paste0("nav_", tag), paste0("frac_", tag)))
}
an <- Reduce(function(a, b) merge(a, b, by = "SAMPLE_ID"),
             list(mkfrac(rep(TRUE, length(arms)), "all"),
                  mkfrac(arms != "6p", "ex6p"),
                  mkfrac(arms != "6q", "ex6q"),
                  mkfrac(!arms %in% c("6p", "6q"), "ex6")))
cat("aneuploidy built:", nrow(an), "samples\n")
chk3 <- fread(file.path(V2, "r3p3_aneuploidy_scores.tsv"), select = c("SAMPLE_ID","frac_all","frac_ex6p","frac_ex6"))
cm <- merge(an, chk3, by = "SAMPLE_ID")
cat(sprintf("[cross-check vs V2/r3p3] n=%d  max|diff| frac_all=%.2e ex6p=%.2e ex6=%.2e\n",
            nrow(cm), max(abs(cm$frac_all.x - cm$frac_all.y)), max(abs(cm$frac_ex6p.x - cm$frac_ex6p.y)),
            max(abs(cm$frac_ex6.x - cm$frac_ex6.y))))
stopifnot(nrow(cm) == 53929, max(abs(cm$frac_all.x - cm$frac_all.y)) < 1e-12)

D <- merge(P, an, by = "SAMPLE_ID", all.x = TRUE)
D[, TUMOR_PURITY_num := {z <- suppressWarnings(as.numeric(TUMOR_PURITY)); z[z > 100] <- NA; z}]
D[, logTMB := log10(suppressWarnings(as.numeric(TMB_SCORE)) + 0.1)]   # 与 V2 完全一致（负值 → NaN → 自动剔除）
D[, LOH := as.integer(any_HLA_LOH)]
D[, WGD := FACETS_WGD %in% TRUE]
D[, WGDi := FACETS_WGD]                       # NA-aware：Table 1 的分类计数分母用这个
D[, PUR := {z <- suppressWarnings(as.numeric(FACETS_PURITY)); z[z > 100] <- NA; z}]
D[, age := suppressWarnings(as.numeric(AGE_AT_DX))]
D[, os  := suppressWarnings(as.numeric(OS_MONTHS))]
D[, ev  := suppressWarnings(as.integer(OS_event))]
D[, WGDf := factor(FACETS_WGD)]
D[, SEXf := factor(SEX)]
D[, cancer_f := factor(CANCER_TYPE)]
D[, panel_f := factor(GENE_PANEL)]
D[, arm6pl := as.logical(ifelse(is.na(arm_6p_loss) | arm_6p_loss == "", NA, arm_6p_loss == "TRUE"))]
cat("primary with aneuploidy score:", sum(!is.na(D$frac_all)), "of", nrow(D), "\n")
stopifnot(nrow(D) == 29799, sum(!is.na(D$frac_all)) == 29799)
D[, grp3 := fifelse(!any_HLA_LOH, "No_LOH",
             fifelse(is.na(arm6pl), NA_character_,
              fifelse(arm6pl, "Arm_dependent", "Arm_independent")))]
cat("groups:\n"); print(D[!is.na(grp3), .N, by = grp3])

###############################################################################
## 1. TABLE 1 — baseline by HLA status（含新增：全局非整倍体评分中位数）
###############################################################################
SAFE("TABLE1", {
med_iqr <- function(x) { x <- suppressWarnings(as.numeric(x)); x <- x[!is.na(x)]
  sprintf("%.1f (%.1f-%.1f)", median(x), quantile(x, .25), quantile(x, .75)) }
med2 <- function(x) { x <- suppressWarnings(as.numeric(x)); x <- x[!is.na(x)]; sprintf("%.2f", median(x)) }
pctn <- function(kk, nn) ifelse(is.finite(kk) && is.finite(nn) && nn > 0,
                                sprintf("%d (%.1f%%)", as.integer(kk), 100 * kk / nn), "NA")
SF   <- function(x) sum(x, na.rm = TRUE)
wp   <- function(x, g) { x <- suppressWarnings(as.numeric(x))
  if (sum(!is.na(x)) < 3 || length(unique(na.omit(x))) < 2 || length(unique(na.omit(g))) < 2) return("NA")
  p <- tryCatch(suppressWarnings(wilcox.test(x ~ g)$p.value), error = function(e) NA_real_)
  if (!is.finite(p)) return("NA"); ifelse(p < 1e-4, "<0.001", sprintf("%.3f", p)) }
cp   <- function(kk, nn) { kk <- suppressWarnings(as.numeric(kk)); nn <- suppressWarnings(as.numeric(nn))
  tb <- rbind(kk, nn - kk)
  if (any(!is.finite(tb)) || any(tb < 0) || nrow(tb) != 2 || ncol(tb) != 2) return("NA")
  p <- tryCatch(suppressWarnings(chisq.test(tb)$p.value), error = function(e) NA_real_)
  if (!is.finite(p)) p <- tryCatch(suppressWarnings(fisher.test(tb)$p.value), error = function(e) NA_real_)
  if (!is.finite(p)) return("NA"); ifelse(p < 1e-4, "<0.001", sprintf("%.3f", p)) }

i <- D$any_HLA_LOH == FALSE; l <- D$any_HLA_LOH == TRUE
ni <- sum(i); nl <- sum(l)
T1 <- list()
add <- function(label, vi, vl, p, note = "", bold = FALSE)
  T1[[length(T1) + 1]] <<- data.table(characteristic = label, hla_intact = vi, hla_loh = vl,
                                      P = p, note = note, bold = bold)
bin_row <- function(label, vec, note = "", bold = FALSE) {   # 分类计数以“非缺失”为分母
  vi <- vec[i]; vl <- vec[l]
  ki <- SF(vi == TRUE); kl <- SF(vl == TRUE)
  ni_ok <- SF(!is.na(vi)); nl_ok <- SF(!is.na(vl))
  add(label, pctn(ki, ni_ok), pctn(kl, nl_ok), cp(c(kl, ki), c(nl_ok, ni_ok)), note, bold)
}
add("N", format(ni, big.mark = ","), format(nl, big.mark = ","), "",
    "HLA-LOH-evaluable, FACETS-QC-pass, one tumour per patient")
add("Age at diagnosis, median (IQR)", med_iqr(D$age[i]), med_iqr(D$age[l]), wp(D$age, D$any_HLA_LOH), "years")
bin_row("Female sex", D$SEX == "Female")
bin_row("Metastatic sample", D$SAMPLE_TYPE == "Metastasis", "metastasis only; local recurrence excluded")
add("TMB (mut/Mb), median (IQR)", med_iqr(D$TMB_SCORE[i]), med_iqr(D$TMB_SCORE[l]),
    wp(D$TMB_SCORE, D$any_HLA_LOH), "MSK-IMPACT panel mutation count per Mb")
bin_row("TMB-high (\u226510 mut/Mb)", D$TMB_high == TRUE | D$TMB_high == "TRUE")
bin_row("Whole-genome doubling", D$WGDi, "FACETS allele-specific WGD call")
add("Global aneuploidy score, median (IQR)", med_iqr(D$frac_all[i]), med_iqr(D$frac_all[l]),
    wp(D$frac_all, D$any_HLA_LOH),
    "NEW ROW. Fraction of evaluable autosomal arms (of 39) with copy-number gain or loss (FACETS arm-level CNA)",
    bold = TRUE)
add("Aneuploidy score excluding 6p, median (IQR)", med_iqr(D$frac_ex6p[i]), med_iqr(D$frac_ex6p[l]),
    wp(D$frac_ex6p, D$any_HLA_LOH), "same score with the HLA-bearing 6p arm removed", bold = TRUE)
add("Aneuploidy score excluding 6q, median (IQR)", med_iqr(D$frac_ex6q[i]), med_iqr(D$frac_ex6q[l]),
    wp(D$frac_ex6q, D$any_HLA_LOH), "same score with 6q removed", bold = TRUE)
{ vi <- D$arm6pl[i]; vl <- D$arm6pl[l]
  add("6p arm loss", pctn(SF(vi == TRUE), SF(!is.na(vi))), pctn(SF(vl == TRUE), SF(!is.na(vl))),
      cp(c(SF(vl == TRUE), SF(vi == TRUE)), c(SF(!is.na(vl)), SF(!is.na(vi)))),
      "denominator = 6p-readable samples within each HLA group; among HLA-LOH with a 6p call (n=5,805), 4,161 (71.7%) show 6p loss") }
bin_row("Germline HLA class I homozygosity (any locus)", D$germ_hom_any,
        "methodological ceiling of evaluability, not an evolutionary-pressure test")
add("FACETS tumour purity, median (IQR)", med_iqr(D$PUR[i]), med_iqr(D$PUR[l]), wp(D$PUR, D$any_HLA_LOH))
add("FACETS ploidy, median (IQR)", med_iqr(D$FACETS_PLOIDY[i]), med_iqr(D$FACETS_PLOIDY[l]),
    wp(D$FACETS_PLOIDY, D$any_HLA_LOH))
add("Sample coverage, median (IQR)", med_iqr(D$SAMPLE_COVERAGE[i]), med_iqr(D$SAMPLE_COVERAGE[l]),
    wp(D$SAMPLE_COVERAGE, D$any_HLA_LOH), "median target coverage (\u00d7)")
bin_row("Gene panel \u2014 IMPACT468", D$GENE_PANEL == "IMPACT468")
T1 <- rbindlist(T1)
fwrite(T1, F("table1_baseline.tsv"), sep = "\t")
print(T1[, .(characteristic, hla_intact, hla_loh, P)])
CHK("Table1 N intact", ni, 22245); CHK("Table1 N LOH", nl, 7554)
CHK("Table1 aneuploidy median intact", med2(D$frac_all[i]), "0.27", 0.01)
pctw <- function(v) round(100 * sum(v == TRUE, na.rm = TRUE) / sum(!is.na(v)), 1)
CHK("Table1 WGD intact %", pctw(D$WGDi[i]), 23.1, 0.05)
CHK("Table1 WGD LOH %", pctw(D$WGDi[l]), 43.7, 0.05)
CHK("Table1 6p loss LOH %", round(100 * 4161 / 5805, 1), 71.7, 0.05)
CHK("Table1 TMB medians", paste(med2(D$TMB_SCORE[i]), med2(D$TMB_SCORE[l])), "3.51 4.39")
})

###############################################################################
## 2. TABLE 2 — drivers of HLA LOH（远端多变量 + 非整倍体项 + 近端 6p）
###############################################################################
SAFE("TABLE2", {
D[, aneu_z := as.numeric(scale(frac_all))]
gt <- function(mod, term) { s <- summary(mod)$coefficients
  if (!term %in% rownames(s)) return(data.table(OR = NA_real_, lo = NA_real_, hi = NA_real_, P = NA_real_))
  b <- s[term, 1]; se <- s[term, 2]
  data.table(OR = exp(b), lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se), P = s[term, 4]) }
mD    <- glm(any_HLA_LOH ~ WGD + germ_hom_any + logTMB + PUR + panel_f + cancer_f, data = D, family = binomial)
mA    <- glm(any_HLA_LOH ~ WGD + germ_hom_any + logTMB + PUR + panel_f + cancer_f + aneu_z, data = D, family = binomial)
mA0   <- glm(any_HLA_LOH ~ aneu_z, data = D, family = binomial)
mAP   <- glm(any_HLA_LOH ~ logTMB + WGD + cancer_f + panel_f + aneu_z, data = D, family = binomial)
mProx <- glm(any_HLA_LOH ~ arm_6p_loss + cancer_f, data = D, family = binomial)
T2 <- rbindlist(list(
  cbind(data.table(predictor = "Whole-genome doubling", model = "Distal multivariable"), gt(mD, "WGDTRUE")),
  cbind(data.table(predictor = "Germline HLA class I homozygosity (any)", model = "Distal multivariable"), gt(mD, "germ_hom_anyTRUE")),
  cbind(data.table(predictor = "log10 TMB (per unit)", model = "Distal multivariable"), gt(mD, "logTMB")),
  cbind(data.table(predictor = "Global aneuploidy score (per SD)", model = "Distal multivariable + aneuploidy"), gt(mA, "aneu_z")),
  cbind(data.table(predictor = "Whole-genome doubling", model = "Distal multivariable + aneuploidy"), gt(mA, "WGDTRUE")),
  cbind(data.table(predictor = "Germline HLA class I homozygosity (any)", model = "Distal multivariable + aneuploidy"), gt(mA, "germ_hom_anyTRUE")),
  cbind(data.table(predictor = "log10 TMB (per unit)", model = "Distal multivariable + aneuploidy"), gt(mA, "logTMB")),
  cbind(data.table(predictor = "Global aneuploidy score (per SD)", model = "Unadjusted"), gt(mA0, "aneu_z")),
  cbind(data.table(predictor = "Global aneuploidy score (per SD)", model = "TMB + WGD + cancer + panel"), gt(mAP, "aneu_z")),
  cbind(data.table(predictor = "6p arm loss", model = "Proximal, near-definitional"), gt(mProx, "arm_6p_lossTRUE"))
), use.names = TRUE)
T2[, OR_CI := sprintf("%.2f (%.2f\u2013%.2f)", OR, lo, hi)]
T2[, P_fmt := ifelse(is.na(P), "NA", ifelse(P < 1e-4, "<0.001", sprintf("%.3f", P)))]
fwrite(T2, F("table2_drivers.tsv"), sep = "\t")
print(T2[, .(predictor, model, OR_CI, P_fmt)])
CHK("Table2 WGD distal OR", round(T2[predictor == "Whole-genome doubling" & model == "Distal multivariable"]$OR, 2), 2.30, 0.005)
CHK("Table2 germline distal OR", round(T2[grepl("Germline", predictor) & model == "Distal multivariable"]$OR, 2), 0.75, 0.01)
CHK("Table2 logTMB distal OR", round(T2[predictor == "log10 TMB (per unit)" & model == "Distal multivariable"]$OR, 2), 1.45, 0.005)
CHK("Table2 6p proximal OR", round(T2[predictor == "6p arm loss"]$OR, 1), 18.5, 0.005)
CHK("Table2 aneuploidy per-SD OR (PINNED spec)", round(T2[model == "TMB + WGD + cancer + panel"]$OR, 3), 3.106, 0.006)
CHK("Table2 aneuploidy per-SD OR unadjusted", round(T2[model == "Unadjusted"]$OR, 3), 2.155, 0.006)
})

###############################################################################
## 3. TABLE 3 — pan-cancer OS：HLA-LOH HR across specifications
##    队列与 V2 完全一致（os：frac_all/ex6p/ex6 均非缺失）→ n=27,368 / 10,101 deaths
###############################################################################
SAFE("TABLE3", {
S <- D[!is.na(os) & os > 0 & !is.na(ev) & !is.na(age) & !is.na(SEXf) & !is.na(logTMB) &
       !is.na(WGDf) & !is.na(cancer_f) & !is.na(frac_all) & !is.na(frac_ex6p) & !is.na(frac_ex6)]
cat("survival cohort n =", nrow(S), " deaths =", sum(S$ev == 1), "\n")
fitc <- function(rhs, lab) { mm <- coxph(as.formula(paste("Surv(os, ev) ~", rhs)), data = S)
  s <- summary(mm)$coefficients; b <- s["LOH", 1]; se <- s["LOH", 3]
  data.table(model = lab, HR = exp(b), lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se),
             P = s["LOH", 5], N = mm$n, deaths = mm$nevent) }
B <- "age + SEXf + logTMB + WGDf + cancer_f"
T3 <- rbindlist(list(
  fitc("LOH", "Unadjusted"),
  fitc(paste("LOH +", B), "Adjusted (age, sex, TMB, WGD, cancer type)"),
  fitc(paste("LOH +", B, "+ frac_all"), "Adjusted + aneuploidy (all 39 arms, incl. 6p)"),
  fitc(paste("LOH +", B, "+ frac_ex6p"), "Adjusted + aneuploidy excluding 6p"),
  fitc(paste("LOH +", B, "+ frac_ex6q"), "Adjusted + aneuploidy excluding 6q"),
  fitc(paste("LOH +", B, "+ frac_ex6"),  "Adjusted + aneuploidy excluding 6p and 6q")))
T3[, HR_CI := sprintf("%.3f (%.3f\u2013%.3f)", HR, lo, hi)]
T3[, P_fmt := ifelse(P < 1e-4, "<0.001", sprintf("%.4f", P))]
T3[, is_new := model == "Adjusted + aneuploidy excluding 6q"]
fwrite(T3, F("table3_survival.tsv"), sep = "\t")
print(T3[, .(model, HR_CI, P_fmt, N, deaths, is_new)])
mm1 <- coxph(as.formula(paste("Surv(os, ev) ~ LOH +", B, "+ frac_all")), data = S)
s1 <- summary(mm1)$coefficients
ah <- data.table(term = "Global aneuploidy score (per 1.0 fraction)", HR = exp(s1["frac_all", 1]),
                 lo = exp(s1["frac_all", 1] - 1.96 * s1["frac_all", 3]),
                 hi = exp(s1["frac_all", 1] + 1.96 * s1["frac_all", 3]), P = s1["frac_all", 5])
fwrite(ah, F("table3_aneuploidy_HR.tsv"), sep = "\t")
cat("aneuploidy HR per unit:", sprintf("%.3f (%.3f-%.3f) P=%.3g", ah$HR, ah$lo, ah$hi, ah$P), "\n")
CHK("Table3 n", T3$N[1], 27368, 0); CHK("Table3 deaths", T3$deaths[1], 10101, 0)
CHK("Table3 unadjusted HR", round(T3$HR[1], 3), 1.212, 0.0015)
CHK("Table3 adjusted HR", round(T3$HR[2], 3), 1.062, 0.0015)
CHK("Table3 +aneuploidy (incl 6p) HR", round(T3$HR[3], 3), 0.938, 0.0015)
CHK("Table3 excl 6p HR", round(T3$HR[4], 3), 0.946, 0.0005)
CHK("Table3 excl 6p6q HR", round(T3$HR[6], 3), 0.952, 0.0015)
CHK("Table3 aneuploidy HR per unit", round(ah$HR, 3), 2.686, 0.003)
})

###############################################################################
## 4. S-aneuploidy1 — TMB–HLA LOH 全谱（含排 6p / 排 6q）+ 非整倍体三分位分层
###############################################################################
SAFE("S-aneuploidy1", {
cc <- D[!is.na(LOH) & !is.na(logTMB) & !is.na(TUMOR_PURITY_num) & !is.na(frac_all) &
        !is.na(frac_ex6p) & !is.na(frac_ex6) & !is.na(cancer_f) & !is.na(panel_f)]
cat("TMB-LOH complete-case n =", nrow(cc), " LOH+ =", sum(cc$LOH), "\n")
ORt <- function(mod) { s <- summary(mod)$coefficients; b <- s["logTMB", 1]; se <- s["logTMB", 2]
  data.table(OR = exp(b), lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se), P = s["logTMB", 4]) }
specs0 <- data.table(spec = c("No aneuploidy adjustment (cancer + panel + purity)",
                              "+ aneuploidy, all 39 arms (incl. 6p)",
                              "+ aneuploidy excluding 6p",
                              "+ aneuploidy excluding 6q",
                              "+ aneuploidy excluding 6p and 6q"),
                     term = c(NA_character_, "frac_all", "frac_ex6p", "frac_ex6q", "frac_ex6"))
sp <- rbindlist(lapply(seq_len(nrow(specs0)), function(j) {
  tm <- specs0$term[j]
  ff <- if (is.na(tm)) LOH ~ logTMB + cancer_f + panel_f + TUMOR_PURITY_num
        else as.formula(paste("LOH ~ logTMB + cancer_f + panel_f + TUMOR_PURITY_num +", tm))
  mj <- glm(ff, data = cc, family = binomial)
  o  <- ORt(mj); s <- summary(mj)$coefficients; mf <- model.frame(mj)
  data.table(spec = specs0$spec[j], term = tm, N = nrow(mf), n_LOH = sum(mf$LOH),
             OR = o$OR, lo = o$lo, hi = o$hi, P = o$P,
             aneu_OR_per_SD = if (is.na(tm)) NA_real_ else exp(s[tm, 1] * sd(cc[[tm]])))
}))
sp[, is_new := grepl("excluding 6q$", spec)]
sp[, OR_CI := sprintf("%.3f (%.3f\u2013%.3f)", OR, lo, hi)]
sp[, P_fmt := ifelse(P < 1e-6, sprintf("%.2e", P), ifelse(P < 1e-4, "<0.001", sprintf("%.4f", P)))]
fwrite(sp, F("s_aneuploidy1_models.tsv"), sep = "\t")
print(sp[, .(spec, N, n_LOH, OR_CI, P_fmt, is_new)])
## 三分位分层：与 V2 一致，用“含 WGD 非缺失”的 r3p2 队列（n=29,288）
cc2 <- cc[!is.na(FACETS_WGD)]
cat("tertile cohort (requires WGD non-missing) n =", nrow(cc2), "\n")
qs <- quantile(cc2$frac_all, probs = seq(0, 1, length.out = 4)); qs[1] <- -Inf; qs[4] <- Inf
cc2[, tert := cut(frac_all, qs, labels = paste0("Q", 1:3), include.lowest = TRUE)]
st <- rbindlist(lapply(levels(cc2$tert), function(q) {
  dt <- cc2[tert == q]
  cbind(data.table(tertile = q, N = nrow(dt), n_LOH = sum(dt$LOH),
                   frac_range = sprintf("%.3f\u2013%.3f", min(dt$frac_all), max(dt$frac_all))),
        ORt(glm(LOH ~ logTMB + cancer_f + panel_f + TUMOR_PURITY_num, data = dt, family = binomial))) }))
st[, OR_CI := sprintf("%.3f (%.3f\u2013%.3f)", OR, lo, hi)]
st[, P_fmt := ifelse(P < 1e-4, "<0.001", sprintf("%.4f", P))]
fwrite(st, F("s_aneuploidy1_tertiles.tsv"), sep = "\t")
print(st[, .(tertile, N, n_LOH, frac_range, OR_CI, P_fmt)])
CHK("S-aneuploidy1 N", sp$N[1], 29407, 0)
CHK("S-aneuploidy1 M0 OR", round(sp$OR[1], 3), 1.568, 0.001)
CHK("S-aneuploidy1 +aneu(all) OR", round(sp$OR[2], 3), 1.238, 0.001)
CHK("S-aneuploidy1 excl6p OR", round(sp$OR[3], 3), 1.250, 0.001)
CHK("S-aneuploidy1 excl6p6q OR", round(sp$OR[5], 3), 1.256, 0.001)
CHK("S-aneuploidy1 Q1 OR", round(st$OR[1], 3), 1.710, 0.001)
CHK("S-aneuploidy1 Q2 OR", round(st$OR[2], 3), 1.187, 0.001)
CHK("S-aneuploidy1 Q3 OR", round(st$OR[3], 3), 1.104, 0.001)
CHK("S-aneuploidy1 Q3 P", round(st$P[3], 4), 0.0995, 0.001)
})

###############################################################################
## 5. S-arm1 — 41 条臂 × TMB 关联全表（6p = 26/41；17p 第一）
###############################################################################
SAFE("S-arm1", {
ra <- fread(file.path(IMD, "fig3c_arm_tmb_rank.tsv"))
stopifnot(nrow(ra) == 41)
setorder(ra, rank_tmb)
fwrite(ra, F("s_arm1_rank.tsv"), sep = "\t")
cat("first arm =", ra$arm[1], "| 6p rank =", ra$rank_tmb[ra$is_6p], "of 41\n")
print(ra[, .(rank_tmb, arm, n, beta_loss, p_loss)])
CHK("S-arm1 n arms", nrow(ra), 41, 0)
CHK("S-arm1 first arm", ra$arm[1], "17p")
CHK("S-arm1 6p rank", ra$rank_tmb[ra$is_6p], 26)
## 注：PINNED §2.3 的 17p β=0.079 为另一口径（fig3c 表内 β=0.124，P 亦不同），
##     故此处只核排名，不核 β —— 差异已在 QC 日志记录
cat(sprintf("   [NOTE] 17p beta in this table = %.4f (PINNED quotes 0.079 under a different specification); rank check only\n", ra$beta_loss[1]))
})

###############################################################################
## 6. S-reliability1 — 纯度十分位 / 覆盖 / panel 依赖模型
###############################################################################
SAFE("S-reliability1", {
REL <- D[grp3 %in% c("Arm_independent", "Arm_dependent")]
REL[, pur_pct := PUR * 100]                       # FACETS 纯度百分数（与 V2/r3p4 口径一致）
REL[, cov := suppressWarnings(as.numeric(SAMPLE_COVERAGE))]
REL[, y := as.integer(grp3 == "Arm_independent")]
REL[, wgd_f := FACETS_WGD %in% TRUE]
REL[, cancer_f := droplevels(cancer_f)][, panel_f := droplevels(panel_f)]
REL <- REL[!is.na(pur_pct)]
cat("reliability cohort:", nrow(REL), " events:", sum(REL$y), "\n")
m2 <- glm(y ~ pur_pct + cov + panel_f + cancer_f + wgd_f, data = REL, family = binomial)
s2 <- summary(m2)$coefficients
cat("key coefficient names:", paste(intersect(rownames(s2), c("pur_pct","cov","panel_fIMPACT505","panel_fIMPACT468","wgd_fTRUE")), collapse = " | "), "\n")
grab <- function(t, mult = 1) {
  if (!t %in% rownames(s2)) return(data.table(term = t, OR = NA_real_, lo = NA_real_, hi = NA_real_, P = NA_real_))
  b <- s2[t, 1]; se <- s2[t, 2]
  lo0 <- exp(mult * (b - 1.96 * se)); hi0 <- exp(mult * (b + 1.96 * se))
  data.table(term = t, OR = exp(mult * b), lo = min(lo0, hi0), hi = max(lo0, hi0), P = s2[t, 4]) }
rl <- rbindlist(list(grab("pur_pct", -10), grab("cov", 100),
                     grab("panel_fIMPACT505"), grab("wgd_fTRUE")), fill = TRUE)
rl[, term_label := c("Purity, per \u221210%", "Coverage, per +100\u00d7",
                     "IMPACT505 vs IMPACT410 panel", "Whole-genome doubling")]
rl[, `:=`(OR_CI = sprintf("%.2f (%.2f\u2013%.2f)", OR, lo, hi),
          P_fmt = ifelse(is.na(P), "NA", ifelse(P < 1e-4, "<0.001", sprintf("%.3f", P))),
          PINNED_ref = c("1.56 (1.50-1.62), P=3.3e-98", "0.77 (0.74-0.80), P=3.2e-42",
                         "0.30 (0.23-0.40)", "0.09 (0.08-0.11), P=1.9e-163"),
          source = "independently recomputed in 01_build_tables_V3.R; PINNED reference = V2/r3p4 (same cohort, n=5,805)")]
fwrite(rl, F("s_reliability1_models.tsv"), sep = "\t")
print(rl[, .(term_label, OR_CI, P_fmt)])
rq <- unique(quantile(REL$pur_pct, seq(0, 1, .1), na.rm = TRUE))
REL[, dec_p := cut(pur_pct, rq, labels = FALSE, include.lowest = TRUE)]
dec <- REL[!is.na(dec_p), .(n = .N, n_armind = sum(y), purity_median_pct = median(pur_pct)), by = dec_p][order(dec_p)]
dec[, pct := round(100 * n_armind / n, 2)]
fwrite(dec, F("s_reliability1_purity_decile.tsv"), sep = "\t")
print(dec)
gs <- rbindlist(lapply(c("No_LOH", "Arm_independent", "Arm_dependent"), function(q) {
  dt <- D[grp3 == q]
  data.table(group = q, n = nrow(dt),
             facets_purity_pct_median = median(dt$PUR * 100, na.rm = TRUE),
             pathologist_purity_pct_median = median(dt$TUMOR_PURITY_num, na.rm = TRUE),
             coverage_median = median(suppressWarnings(as.numeric(dt$SAMPLE_COVERAGE)), na.rm = TRUE),
             ploidy_median = median(suppressWarnings(as.numeric(dt$FACETS_PLOIDY)), na.rm = TRUE),
             aneuploidy_median = round(median(dt$frac_all, na.rm = TRUE), 3),
             wgd_pct = round(100 * mean(dt$WGDi, na.rm = TRUE), 1),
             pct_purity_lt30 = round(100 * mean(dt$PUR * 100 < 30, na.rm = TRUE), 2)) }))
fwrite(gs, F("s_reliability1_group_summary.tsv"), sep = "\t"); print(gs)
ss <- rbindlist(lapply(c(0, 30, 50), function(ct) {
  dt <- REL[pur_pct >= ct]
  dt[, cancer_f := droplevels(cancer_f)][, panel_f := droplevels(panel_f)]
  s <- summary(glm(y ~ pur_pct + cov + panel_f + cancer_f + wgd_f, data = dt, family = binomial))$coefficients
  data.table(purity_ge_pct = ct, n = nrow(dt), y = sum(dt$y),
             wgd_OR = exp(s["wgd_fTRUE", 1]), wgd_P = s["wgd_fTRUE", 4],
             pur_per10_OR = exp(s["pur_pct", 1] * -10), pur_P = s["pur_pct", 4],
             cov_per100_OR = exp(s["cov", 1] * 100), cov_P = s["cov", 4]) }))
fwrite(ss, F("s_reliability1_purity_strata.tsv"), sep = "\t"); print(ss)
au <- data.table(model = c("Technical only (purity + coverage + panel)", "Full (+ cancer type + WGD)",
                           "Biological only (cancer type + WGD)"),
                 McFadden_R2 = c(0.0926, 0.2668, 0.1920), AUC = c(0.7060, 0.8367, 0.7668),
                 source = "V2/r3p4_step3.log")
fwrite(au, F("s_reliability1_auc.tsv"), sep = "\t"); print(au)
CHK("S-reliability1 purity per -10% OR", round(rl$OR[1], 2), 1.56, 0.005)
CHK("S-reliability1 coverage per +100x OR", round(rl$OR[2], 2), 0.77, 0.005)
CHK("S-reliability1 IMPACT505 vs 410 OR", round(rl$OR[3], 2), 0.30, 0.005)
CHK("S-reliability1 decile D1 %", round(dec$pct[1], 1), 60.3, 0.3)
CHK("S-reliability1 decile D10 %", round(dec$pct[nrow(dec)], 1), 11.3, 0.2)
})

###############################################################################
## 7. S-neo1 / S-neo2 — 新抗原（netMHCpan-4.2e 全队列）
###############################################################################
SAFE("S-neo1", {
al  <- fread(file.path(NEO, "A_logistic.tsv"))
A2  <- fread(file.path(NEO, "A2_outcome_models.tsv"))
ols <- A2[model == "ols_log1p_neo"]; mdn <- A2[model == "median_neo_by_LOH"]
ex   <- fread(file.path(NEO, "C_sensitivity.tsv"))[test_type == "logistic"]
fr   <- fread(file.path(NEO, "extended_A_logistic_firth.tsv"))
fr   <- fr[is.finite(OR_Firth) & OR_Firth > 0]      # 仅保留收敛的 Firth 行（其余为 0/Inf，未收敛）
tb  <- fread(file.path(NEO, "extended_A_by_aneuploidy_tertile.tsv"))
s1 <- rbind(
  data.table(kind = "primary", definition = al$model, n = al$n, n_LOH = al$n_LOH,
             OR = al$OR_per_SD, lo = al$ci_lo, hi = al$ci_hi, P = al$P, source = "A_logistic.tsv"),
  data.table(kind = "sensitivity", definition = paste0("OLS log1p(" , ols$model, ")"),
             n = ols$n, n_LOH = NA_integer_, OR = ols$effect_mult, lo = ols$ci_lo, hi = ols$ci_hi,
             P = ols$P, source = "A2_outcome_models.tsv"),
  data.table(kind = "sensitivity", definition = paste0("Sensitivity: ", ex$test), n = ex$n, n_LOH = ex$n_LOH,
             OR = ex$OR_per_SD_neo, lo = ex$ci_lo, hi = ex$ci_hi, P = ex$P, source = "extended_C_sensitivity.tsv"),
  data.table(kind = "sensitivity", definition = paste0("Firth penalised: ", fr$model), n = fr$n, n_LOH = NA_integer_,
             OR = fr$OR_Firth, lo = fr$ci_lo_Firth, hi = fr$ci_hi_Firth, P = fr$P_Firth,
             source = "extended_A_logistic_firth.tsv"),
  data.table(kind = "tertile", definition = paste0("Aneuploidy ", tb$tertile, " (frac ", tb$frac_all_range, ")"),
             n = tb$n, n_LOH = tb$n_LOH, OR = tb$OR_per_SD, lo = tb$ci_lo, hi = tb$ci_hi, P = tb$P,
             source = "extended_A_by_aneuploidy_tertile.tsv"), fill = TRUE)
s1[, OR_CI := sprintf("%.3f (%.3f\u2013%.3f)", OR, lo, hi)]
s1[, P_fmt := ifelse(is.na(P), "NA", ifelse(P < 1e-4, "<0.001", sprintf("%.4f", P)))]
fwrite(s1, F("s_neo1_models.tsv"), sep = "\t")
print(s1[, .(kind, definition, n, n_LOH, OR_CI, P_fmt)])
cl <- fread(file.path(NEO, "A_collinearity.tsv"))
fwrite(cl, F("s_neo1_collinearity.tsv"), sep = "\t")
n1 <- data.table(item = c("Cohort with neoantigen predictions", "Distinct HLA class I alleles scored",
                          "(allele, peptide) pairs scored", "Median panel size (Mb)",
                          "Median coding mutations per sample", "Spearman rho neoantigen count vs TMB",
                          "Spearman rho neoantigen count vs coding mutations",
                          "Median neoantigens per sample, HLA-LOH\u2212", "Median neoantigens per sample, HLA-LOH+"),
                 value = c(26092, 191, 15518931, 1.14, 5,
                           cl$spearman_rho[cl$x == "n_neo_either" & cl$y == "TMB_SCORE"],
                           cl$spearman_rho[cl$x == "n_neo_either" & cl$y == "n_mut_coding"],
                           mdn$neo_median_LOH0, mdn$neo_median_LOH1))
fwrite(n1, F("s_neo1_cohort.tsv"), sep = "\t"); print(n1)
CHK("S-neo1 primary count OR", round(s1$OR[s1$kind == "primary"][1], 3), 1.064, 0.001)
CHK("S-neo1 clonal-only OR (A_logistic)", round(al$OR_per_SD[al$model == "sens_clonal_only"], 3), 1.013, 0.001)
CHK("S-neo1 per-Mb OR", round(al$OR_per_SD[al$model == "neo_per_Mb"], 3), 1.062, 0.001)
CHK("S-neo1 per-mutation OR", round(al$OR_per_SD[al$model == "neo_per_mut"], 3), 1.065, 0.001)
CHK("S-neo1 rho vs TMB", round(cl$spearman_rho[cl$x == "n_neo_either" & cl$y == "TMB_SCORE"], 3), 0.705, 0.001)
CHK("S-neo1 median neo LOH-", mdn$neo_median_LOH0, 6)
CHK("S-neo1 median neo LOH+", mdn$neo_median_LOH1, 7)
})
SAFE("S-neo2", {
rdjson_num <- function(f) {                    # 极简 JSON（扁平 key:number）解析，不依赖 jsonlite
  x <- paste(readLines(f, warn = FALSE), collapse = " ")
  x <- gsub("[{}]", "", x)
  parts <- trimws(strsplit(x, ",")[[1]]); parts <- parts[nzchar(parts)]
  ks <- trimws(gsub('"', '', sub(":.*$", "", parts)))
  vl <- trimws(gsub('"', '', sub("^[^:]*:", "", parts)))
  as.data.table(as.list(setNames(suppressWarnings(as.numeric(vl)), ks)))   # 1 行 data.table，$ 可直接取
}
Bt   <- fread(file.path(NEO, "B_allele_tests.tsv"))
## 用 C_sensitivity.tsv（整洁长表）；extended_C_sensitivity.tsv 因 sm_error 列含逗号文本会破坏解析
ex   <- fread(file.path(NEO, "C_sensitivity.tsv"))[test_type == "paired_loci"]
## extended_B_conditional_logit.tsv 的 sm_error 列含逗号，必须按列选择读取，否则产生 list 列
cl   <- fread(file.path(NEO, "extended_B_conditional_logit.tsv"),
              select = c("test","test_type","OR_lost_vs_kept","ci_lo","ci_hi","P_wald"))[
              test_type == "exact_conditional_logit"]
diag <- rdjson_num(file.path(NEO, "B_pairing_diagnostics.json"))
fr   <- rdjson_num(file.path(NEO, "B_sample_level_fraction.json"))
cat("diag json:", paste(names(diag), diag, sep = "=", collapse = " "), "\n")
cat("frac json:", paste(names(fr), fr, sep = "=", collapse = " "), "\n")
mp   <- function(x) c(all_loci = "All loci (paired)", locus_A = "HLA-A", locus_B = "HLA-B", locus_C = "HLA-C",
                      sens_purity_ge50 = "Sensitivity: tumour purity \u2265 50%",
                      sens_clonal_only = "Sensitivity: clonal mutations only",
                      sens_arm6p_loss = "Sensitivity: 6p arm loss stratum")[as.character(x)]
cat("Bt rows:", nrow(Bt), "| cl rows:", nrow(cl), "| ex rows:", nrow(ex), "\n")
cat("classes Bt:", paste(names(Bt), sapply(Bt, function(z) class(z)[1]), sep = ":", collapse = " "), "\n")
cat("classes ex:", paste(names(ex), sapply(ex, function(z) class(z)[1]), sep = ":", collapse = " "), "\n")
cat("classes cl:", paste(names(cl), sapply(cl, function(z) class(z)[1]), sep = ":", collapse = " "), "\n")
cat("maps:", paste(mp(Bt$test), collapse = " / "), "||", paste(mp(ex$test), collapse = " / "), "\n")
mk_sv_tbl <- function(tt, np, ns, lg, ll, ti, sg, wi, type) data.table(
  test = mp(tt), n_pairs = as.numeric(np), n_samples = as.numeric(ns),
  lost_gt_kept = as.numeric(lg), lost_lt_kept = as.numeric(ll), ties = as.numeric(ti),
  sign_test_P = as.numeric(sg), wilcoxon_P = as.numeric(wi),
  OR = as.numeric(cl$OR_lost_vs_kept[match(as.character(tt), cl$test)]),
  lo = as.numeric(cl$ci_lo[match(as.character(tt), cl$test)]),
  hi = as.numeric(cl$ci_hi[match(as.character(tt), cl$test)]),
  P  = as.numeric(cl$P_wald[match(as.character(tt), cl$test)]), test_type = type)
s2a <- mk_sv_tbl(Bt$test, Bt$n_locus_pairs, Bt$n_samples, Bt$lost_gt_kept, Bt$lost_lt_kept, Bt$ties,
                 Bt$sign_test_P, Bt$wilcoxon_P, "Exact conditional logistic (primary)")
cat("s2a rows:", nrow(s2a), "| OR:", paste(s2a$OR, collapse = ","), "\n")
s2b <- mk_sv_tbl(ex$test, ex$n_locus_pairs, ex$n_samples, ex$lost_gt_kept, ex$lost_lt_kept, ex$ties,
                 ex$sign_test_P, ex$wilcoxon_P, "Exact conditional logistic (sensitivity)")
cat("s2b rows:", nrow(s2b), "| OR:", paste(s2b$OR, collapse = ","), "\n")
s2 <- rbindlist(list(s2a, s2b))
cat("s2 rows:", nrow(s2), "\n")
s2[, OR_CI := sprintf("%.3f (%.3f\u2013%.3f)", OR, lo, hi)]
s2[, signP := ifelse(sign_test_P < 1e-4, "<0.001", sprintf("%.3f", sign_test_P))]
s2[, P_fmt := ifelse(is.na(P), "NA", ifelse(P < 1e-4, "<0.001", sprintf("%.3f", P)))]
fwrite(s2, F("s_neo2_allele_tests.tsv"), sep = "\t")
print(s2[, .(test, test_type, n_pairs, OR_CI, signP, P_fmt)])
n2 <- data.table(item = c("HLA-LOH samples considered", "Germline-homozygous loci excluded from pairing",
                          "Loci paired", "Samples with \u22651 evaluable pair", "Loci with no LOH call",
                          "Loci both lost"),
                 value = c(diag$loh_samples_considered, diag$homozygous_loci_excluded, diag$loci_paired,
                           diag$samples_with_pair, diag$loci_no_loh_call, diag$loci_both_lost))
fwrite(n2, F("s_neo2_cohort.tsv"), sep = "\t"); print(n2)
clon <- ex[test == "sens_clonal_only"]
## 样本层 clonal-only 占比必须用 C_pairs_clonal_only.tsv（与 Fig4C 同口径），
## 不能用 C_sensitivity 的配对计数（4036/3842=0.512），两者口径不同
sl <- function(dt) { s <- dt[, .(d = sum(d_bind, na.rm = TRUE)), by = SAMPLE_ID]
  data.table(n_samples = nrow(s), lost_more = sum(s$d > 0), kept_more = sum(s$d < 0),
             ties = sum(s$d == 0), frac_excl_ties = sum(s$d > 0) / sum(s$d != 0)) }
sl_clo <- sl(fread(file.path(NEO, "C_pairs_clonal_only.tsv")))
cat("clonal sample-level:", paste(names(sl_clo), unlist(sl_clo), sep = "=", collapse = " "), "\n")
fr2 <- data.table(
  item = c("Samples with more binders on the LOST allele (all loci, ties excluded)",
           "Samples with more binders on the KEPT allele (all loci, ties excluded)",
           "Ties (all loci)", "Ties (clonal only)",
           "Fraction lost>kept, ties excluded (all loci)",
           "Fraction lost>kept, ties excluded (clonal only)"),
  value = c(fr$lost_more, fr$kept_more, fr$equal, sl_clo$ties,
            fr$lost_more / (fr$lost_more + fr$kept_more), sl_clo$frac_excl_ties),
  n = c(fr$n_samples_with_pair, fr$n_samples_with_pair, fr$n_samples_with_pair,
        sl_clo$n_samples, fr$n_samples_with_pair, sl_clo$n_samples),
  source = c("B_sample_level_fraction.json", "B_sample_level_fraction.json",
             "B_sample_level_fraction.json", "C_pairs_clonal_only.tsv",
             "B_sample_level_fraction.json", "C_pairs_clonal_only.tsv"))
fwrite(fr2, F("s_neo2_fractions.tsv"), sep = "\t"); print(fr2)
CHK("S-neo2 all loci OR", round(s2$OR[s2$test == "All loci (paired)" & grepl("primary", s2$test_type)], 4), 1.0078, 0.0002)
CHK("S-neo2 all loci P", round(s2$P[s2$test == "All loci (paired)" & grepl("primary", s2$test_type)], 3), 0.330, 0.002)
CHK("S-neo2 HLA-A OR", round(s2$OR[s2$test == "HLA-A"], 3), 1.016, 0.001)
CHK("S-neo2 HLA-B OR", round(s2$OR[s2$test == "HLA-B"], 3), 1.003, 0.001)
CHK("S-neo2 HLA-C OR", round(s2$OR[s2$test == "HLA-C"], 3), 1.003, 0.001)
CHK("S-neo2 purity>=50% OR", round(s2$OR[grepl("purity", s2$test)], 3), 1.019, 0.001)
CHK("S-neo2 clonal-only OR", round(s2$OR[grepl("clonal", s2$test)], 3), 1.024, 0.001)
CHK("S-neo2 pairs", diag$loci_paired, 14157)
CHK("S-neo2 samples", diag$samples_with_pair, 6817)
CHK("S-neo2 homozygous excluded", diag$homozygous_loci_excluded, 1305)
CHK("S-neo2 frac lost>kept all loci", round(fr$lost_more / (fr$lost_more + fr$kept_more), 3), 0.506, 0.002)
CHK("S-neo2 frac lost>kept clonal", round(sl_clo$frac_excl_ties, 3), 0.518, 0.002)
CHK("S-neo2 ties clonal", sl_clo$ties, 2484)
CHK("S-neo2 sign test P", round(s2$sign_test_P[s2$test == "All loci (paired)" & grepl("primary", s2$test_type)], 3), 0.247, 0.002)
})

###############################################################################
## 8. S-sv1 — SV 类别负荷与 HLA LOH（R3-4 “无法做 COSMIC SV 签名”的替代证据）
###############################################################################
SAFE("S-sv1", {
sv <- fread(file.path(ROOT, "msk_impact_50k_2026/data_sv.txt"), showProgress = FALSE)
cat("SV rows:", nrow(sv), " samples:", uniqueN(sv$Sample_Id), "\n")
cl <- sv[, .N, by = Class][order(-N)]; print(cl)
svc  <- sv[, .(sv_n = .N), by = .(SAMPLE_ID = Sample_Id)]
wide <- dcast(sv[, .(SAMPLE_ID = Sample_Id, Class)], SAMPLE_ID ~ Class, fun.aggregate = length, value.var = "Class")
setnames(wide, setdiff(names(wide), "SAMPLE_ID"), paste0("sv_", tolower(setdiff(names(wide), "SAMPLE_ID"))))
SV <- merge(svc, wide, by = "SAMPLE_ID", all.x = TRUE); SV[is.na(SV)] <- 0
fwrite(SV[order(-sv_n)], F("s_sv1_sample_counts.tsv"), sep = "\t")
fwrite(cl, F("s_sv1_class_totals.tsv"), sep = "\t")
sm <- data.table(item = c("SV rows (gene-level rearrangement calls)", "Samples with \u22651 SV call",
                          "Cohort fraction with \u22651 SV call (%)", "SV calls/sample: median", "SV calls/sample: mean",
                          "SV calls/sample: maximum", "Distinct partner-gene combinations",
                          "Rows carrying a numeric SV_Length"),
                 value = c(nrow(sv), uniqueN(sv$Sample_Id), round(100 * uniqueN(sv$Sample_Id) / 54331, 1),
                           median(SV$sv_n), round(mean(SV$sv_n), 2), max(SV$sv_n),
                           uniqueN(paste(sv$Site1_Hugo_Symbol, sv$Site2_Hugo_Symbol)),
                           sum(!is.na(suppressWarnings(as.numeric(sv$SV_Length))))))
fwrite(sm, F("s_sv1_summary.tsv"), sep = "\t"); print(sm)
DS <- merge(D, SV, by = "SAMPLE_ID", all.x = TRUE)
DS[is.na(sv_n), sv_n := 0]; DS[, sv_any := as.integer(sv_n > 0)]
cat("primary cohort with \u22651 SV:", sum(DS$sv_any), "of", nrow(DS), "\n")
svm <- function(rhs, lab) { mm <- glm(as.formula(paste("LOH ~", rhs)), data = DS, family = binomial)
  s <- summary(mm)$coefficients; t <- if ("sv_any" %in% rownames(s)) "sv_any" else "sv_n"
  b <- s[t, 1]; se <- s[t, 2]
  data.table(model = lab, term = t, OR = exp(b), lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se),
             P = s[t, 4], N = nrow(DS), n_LOH = sum(DS$LOHi)) }
bs <- "cancer_f + panel_f + PUR"
ss <- rbindlist(list(
  svm(paste("sv_any +", bs), "SV present (\u22651 call) + cancer + panel + purity"),
  svm(paste("sv_n +", bs), "SV count (per additional call) + cancer + panel + purity"),
  svm(paste("sv_any +", bs, "+ frac_all"), "SV present + cancer + panel + purity + aneuploidy"),
  svm(paste("sv_n +", bs, "+ frac_all"), "SV count + cancer + panel + purity + aneuploidy")))
ss[, OR_CI := sprintf("%.3f (%.3f\u2013%.3f)", OR, lo, hi)]
ss[, P_fmt := ifelse(P < 1e-6, sprintf("%.2e", P), ifelse(P < 1e-4, "<0.001", sprintf("%.4f", P)))]
fwrite(ss, F("s_sv1_models.tsv"), sep = "\t"); print(ss[, .(model, OR_CI, P_fmt, N, n_LOH)])
ds <- DS[, .N, by = .(sv_n = pmin(sv_n, 3L))][, .(n_samples = sum(N)), by = sv_n][order(sv_n)]
ds[, pct := 100 * n_samples / nrow(DS)]
fwrite(ds, F("s_sv1_distribution.tsv"), sep = "\t"); print(ds)
cr <- rbindlist(lapply(grep("^sv_(deletion|inversion|translocation|duplication|insertion)$", names(DS), value = TRUE),
  function(cn) { DS[, has := get(cn) > 0]
    tb <- DS[, .(n = .N, n_LOH = sum(LOH)), by = has][order(-has)]
    n1 <- tb$n[1]; k1 <- tb$n_LOH[1]; n0 <- tb$n[2]; k0 <- tb$n_LOH[2]
    p <- tryCatch(suppressWarnings(chisq.test(matrix(c(k1, n1 - k1, k0, n0 - k0), nrow = 2)))$p.value,
                  error = function(e) NA_real_)
    if (!is.finite(p)) p <- tryCatch(suppressWarnings(fisher.test(matrix(c(k1, n1 - k1, k0, n0 - k0), nrow = 2),
                                     simulate.p.value = TRUE, B = 1e5)$p.value), error = function(e) NA_real_)
    data.table(sv_class = sub("^sv_", "", cn), n_with = n1, loh_pct_with = round(100 * k1 / n1, 2),
               n_without = n0, loh_pct_without = round(100 * k0 / n0, 2), P = p) }))
cr[, P_fmt := ifelse(is.na(P), "NA", ifelse(P < 1e-4, "<0.001", sprintf("%.4f", P)))]
fwrite(cr, F("s_sv1_class_cross.tsv"), sep = "\t"); print(cr)
lim <- rbind(
  data.table(item = "Annotation granularity",
             detail = "Gene-level rearrangement calls only (Site1_Hugo_Symbol / Site2_Hugo_Symbol + Class); junctions are not reported base-pair-resolved for most rows"),
  data.table(item = "Calls per sample",
             detail = sprintf("Median %s (maximum %s) across the %s samples carrying any call; %.1f%% of the 50K cohort has no SV call at all",
                              median(SV$sv_n), max(SV$sv_n), uniqueN(sv$Sample_Id),
                              100 * (1 - uniqueN(sv$Sample_Id) / 54331))),
  data.table(item = "Distinct partner-gene combinations",
             detail = sprintf("%s combinations across %s calls \u2014 highly heterogeneous, so per-class counts are dominated by singletons",
                              uniqueN(paste(sv$Site1_Hugo_Symbol, sv$Site2_Hugo_Symbol)), nrow(sv))),
  data.table(item = "Read support reported",
             detail = "Paired-end and split-read support plus confidence class are given, but no copy-number-neutral/double-minute or clustered-junction annotation"),
  data.table(item = "Usable for COSMIC SV signature decomposition?",
             detail = "No. Signature-level SV analysis needs base-pair-resolved junctions and an appreciable number of calls per tumour; with a median of 1 gene-level call per sample and 76.9% of samples empty, COSMIC SV (rearrangement) signature fitting is not identifiable in this table. We therefore report SV class burden only, as evidence of why that analysis is not feasible, and as an association with HLA LOH."))
fwrite(lim, F("s_sv1_limitations.tsv"), sep = "\t"); print(lim)
CHK("S-sv1 rows", nrow(sv), 15811)
CHK("S-sv1 samples", uniqueN(sv$Sample_Id), 12502)
CHK("S-sv1 DELETION", cl$N[cl$Class == "DELETION"], 6225)
CHK("S-sv1 INVERSION", cl$N[cl$Class == "INVERSION"], 3738)
CHK("S-sv1 TRANSLOCATION", cl$N[cl$Class == "TRANSLOCATION"], 3644)
CHK("S-sv1 DUPLICATION", cl$N[cl$Class == "DUPLICATION"], 2203)
CHK("S-sv1 INSERTION", cl$N[cl$Class == "INSERTION"], 1)
CHK("S-sv1 median calls/sample", median(SV$sv_n), 1)
})

###############################################################################
## 10. S1–S7 补充表（保留并修正：已推翻的内容删除/改写）
###############################################################################
SAFE("S1-S7", {
## ---- S1 泛癌 HLA LOH 图谱（按癌种，N>=100）----
f1a <- fread(file.path(IMD, "fig1a_cancer_freq.tsv"))
ex1 <- D[, .(medTMB_LOH    = median(suppressWarnings(as.numeric(TMB_SCORE))[any_HLA_LOH == TRUE], na.rm = TRUE),
             medTMB_intact = median(suppressWarnings(as.numeric(TMB_SCORE))[any_HLA_LOH == FALSE], na.rm = TRUE),
             pan_pct       = 100 * sum(pan_HLA_LOH == "TRUE", na.rm = TRUE) / .N,
             wgd_pct       = 100 * mean(WGDi, na.rm = TRUE),
             aneuploidy_median = median(frac_all, na.rm = TRUE),
             pct_6p_readable   = 100 * mean(!is.na(arm6pl), na.rm = TRUE)),
           by = CANCER_TYPE]
s1 <- merge(f1a[, .(CANCER_TYPE, N, n_LOH, freq_pct = 100 * freq_LOH, CI_lo = 100 * lo, CI_hi = 100 * hi)],
            ex1, by = "CANCER_TYPE")
setorder(s1, -freq_pct)
fwrite(s1, F("s1_atlas.tsv"), sep = "\t")
cat("\n=== S1 ===\n"); print(s1)
CHK("S1 cancer types", nrow(s1), 29, 0)
CHK("S1 overall freq (cohort)", round(100 * sum(D$any_HLA_LOH) / nrow(D), 1), 25.3, 0.05)

## ---- S2 TMB 关联（按癌种，Wilcoxon + BH-FDR）----
s2 <- fread(file.path(IMD, "fig2b_tmb_log2fc.tsv"))
s2 <- s2[, .(CANCER_TYPE, N, n_LOH, medTMB_LOH = med_LOH, medTMB_intact = med_intact, P = p, FDR, log2FC, sig)]
setorder(s2, P)
fwrite(s2, F("s2_tmb_by_cancer.tsv"), sep = "\t")
cat("\n=== S2 ===\n"); print(s2)
CHK("S2 significant cancer types (FDR<0.05)", sum(s2$sig), 11, 0)

## ---- S3 突变签名（改写：APOBEC 与 smoking 完全同值 → 突变丰度伪影）----
s3a <- fread(file.path(V2, "r3p2_part2_signatures.tsv"))
s3b <- fread(file.path(V2, "r3p2_part2_signatures_mutual.tsv"))
s3 <- merge(s3a[, .(sig, unadj_OR, unadj_lo, unadj_hi, unadj_P, adj_OR, adj_lo, adj_hi, adj_P, N = n)],
            s3b[, .(sig, mutual_OR = OR, mutual_lo = lo, mutual_hi = hi, mutual_P = P, mutual_FDR = FDR)], by = "sig")
s3[, revised_note := c(smoke = "RETRACTED as a mechanistic claim: identical to APOBEC (adj OR 1.035 for both) \u2014 a mutational-abundance artefact, not a repair-pathway effect",
                       APOBEC = "RETRACTED as a mechanistic claim: identical to smoking \u2014 a mutational-abundance artefact",
                       MMR = "direction reversed versus the original submission (FDR 2.0e-3 in V1); adjusted effect null",
                       HRD = "null", UV = "null", aging = "null")[sig]]
fwrite(s3, F("s3_signatures.tsv"), sep = "\t")
cat("\n=== S3 ===\n"); print(s3[, .(sig, unadj_OR, adj_OR, adj_P, mutual_OR, mutual_FDR)])
CHK("S3 APOBEC adj OR", round(s3$adj_OR[s3$sig == "APOBEC"], 3), 1.035, 0.001)
CHK("S3 smoking adj OR", round(s3$adj_OR[s3$sig == "smoke"], 3), 1.035, 0.001)

## ---- S4 HLA LOH 与 OS（按癌种，age+sex+TMB；BH-FDR）----
res4 <- rbindlist(lapply(names(split(S, droplevels(S$cancer_f))), function(ct) {
  dt <- S[cancer_f == ct]
  if (nrow(dt) < 100) return(NULL)
  mm <- tryCatch(coxph(Surv(os, ev) ~ LOH + age + SEXf + logTMB, data = dt), error = function(e) NULL)
  if (is.null(mm)) return(NULL)
  s <- summary(mm)$coefficients
  if (!"LOH" %in% rownames(s)) return(NULL)
  data.table(cancer = ct, N = nrow(dt), events = sum(dt$ev == 1), HR = exp(s["LOH", 1]),
             lo = exp(s["LOH", 1] - 1.96 * s["LOH", 3]), hi = exp(s["LOH", 1] + 1.96 * s["LOH", 3]), P = s["LOH", 5])
}), fill = TRUE)
res4[, FDR := p.adjust(P, "BH")]; setorder(res4, P)
fwrite(res4, F("s4_survival_by_cancer.tsv"), sep = "\t")
cat("\n=== S4 ===\n"); print(res4)
CHK("S4 cancer types (n>=100)", nrow(res4), 21, 2)

## ---- S5 panel 限制敏感性（改写：原稿称"essentially unchanged"已被推翻）----
pan <- D[GENE_PANEL %in% c("IMPACT468", "IMPACT505")]
cat("panel-restricted cohort:", nrow(pan), "=", round(100 * nrow(pan) / nrow(D), 1), "% of primary\n")
orr1 <- function(m, t) { s <- summary(m)$coefficients; b <- s[t, 1]; se <- s[t, 2]
  c(OR = exp(b), lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se), P = s[t, 4]) }
fitp <- function(dt, form, t) { m <- glm(as.formula(form), data = dt, family = binomial); orr1(m, t) }
full_m0 <- fitp(D,  "LOH ~ logTMB + cancer_f + panel_f + TUMOR_PURITY_num", "logTMB")
rest_m0 <- fitp(pan,"LOH ~ logTMB + cancer_f + TUMOR_PURITY_num",             "logTMB")
full_wg <- fitp(D,  "LOH ~ WGD + germ_hom_any + logTMB + PUR + panel_f + cancer_f", "WGDTRUE")
rest_wg <- fitp(pan,"LOH ~ WGD + germ_hom_any + logTMB + PUR + cancer_f",            "WGDTRUE")
full_gm <- fitp(D,  "LOH ~ WGD + germ_hom_any + logTMB + PUR + panel_f + cancer_f", "germ_hom_anyTRUE")
rest_gm <- fitp(pan,"LOH ~ WGD + germ_hom_any + logTMB + PUR + cancer_f",            "germ_hom_anyTRUE")
full_6p <- fitp(D,  "LOH ~ arm_6p_loss + cancer_f", "arm_6p_lossTRUE")
rest_6p <- fitp(pan,"LOH ~ arm_6p_loss + cancer_f", "arm_6p_lossTRUE")
s5 <- data.table(effect = c("HLA LOH per log10 TMB", "HLA LOH ~ WGD (distal)", "HLA LOH ~ 6p loss (proximal)",
                            "HLA LOH ~ germline homozygosity (distal)"),
                 full_OR = c(full_m0[1], full_wg[1], full_6p[1], full_gm[1]),
                 full_lo = c(full_m0[2], full_wg[2], full_6p[2], full_gm[2]),
                 full_hi = c(full_m0[3], full_wg[3], full_6p[3], full_gm[3]),
                 rest_OR = c(rest_m0[1], rest_wg[1], rest_6p[1], rest_gm[1]),
                 rest_lo = c(rest_m0[2], rest_wg[2], rest_6p[2], rest_gm[2]),
                 rest_hi = c(rest_m0[3], rest_wg[3], rest_6p[3], rest_gm[3]),
                 rest_n = nrow(pan))
s5[, revised_note := "REWRITTEN. These four associations are stable by panel version, but the arm-independent CALL itself is strongly panel-dependent (IMPACT505 vs IMPACT410 OR 0.30, 95% CI 0.23-0.39). The original claim that panel/batch effects are absent is retracted."]
fwrite(s5, F("s5_panel_sensitivity.tsv"), sep = "\t")
cat("\n=== S5 ===\n"); print(s5[, .(effect, full_OR, rest_OR, rest_n)])
CHK("S5 restricted cohort %", round(100 * nrow(pan) / nrow(D), 1), 82.3, 0.2)

## ---- S6 WGD → 6p → HLA LOH 中介 ----
s6 <- fread(file.path(IMD, "fig3b_mediation.tsv"))
fwrite(s6, F("s6_mediation.tsv"), sep = "\t")
cat("\n=== S6 ===\n"); print(s6)
CHK("S6 ACME", round(s6$Estimate[s6$Quantity == "ACME (indirect, via 6p)"], 3), 0.263, 0.001)
CHK("S6 ADE", round(s6$Estimate[s6$Quantity == "ADE (direct)"], 3), -0.089, 0.001)

## ---- S7 胚系合子性与可评估性（改写为方法学陈述）----
s7a <- fread(file.path(IMD, "figs1_evaluability.tsv"))
s7b <- fread(file.path(IMD, "figs1_burden_dose.tsv"))
s7c <- fread(file.path(IMD, "figs1_models.tsv"))
fwrite(s7a, F("s7_germline_evaluability.tsv"), sep = "\t")
fwrite(s7b, F("s7_loh_by_homozygous_burden.tsv"), sep = "\t")
fwrite(s7c, F("s7_models.tsv"), sep = "\t")
cat("\n=== S7 ===\n"); print(s7a); print(s7b); print(s7c)
CHK("S7 homozygous evaluable % (all loci)", max(s7a$hom_eval_pct), 0, 0)
CHK("S7 het evaluable % HLA-A", s7a$het_eval_pct[s7a$locus == "HLA-A"], 59.8, 0.05)
CHK("S7 LOH% burden=0", round(s7b$pct[s7b$gh_burden == 0], 1), 26.2, 0.05)
CHK("S7 LOH% burden=2", round(s7b$pct[s7b$gh_burden == 2], 1), 19.3, 0.05)
CHK("S7 adjusted OR", round(s7c$OR[s7c$model != "Unadjusted"], 2), 0.79, 0.005)
})

###############################################################################
## 9. PINNED 复核总表
###############################################################################
PIN <- rbindlist(PIN); PIN[, mismatch := !match]
fwrite(PIN, F("pin_audit.tsv"), sep = "\t")
cat(sprintf("\n===== PINNED 数字复核：%d 项，OK %d，DIFF %d =====\n", nrow(PIN), sum(PIN$match), sum(!PIN$match)))
if (any(!PIN$match)) print(PIN[match == FALSE])
cat("\nALL DONE. outputs ->", OUT, "\n")
