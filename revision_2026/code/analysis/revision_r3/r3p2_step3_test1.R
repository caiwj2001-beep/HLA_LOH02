## R3 part2 — step 3: build analysis dataset (fixed aneuploidy) + TEST 1 (TMB-LOH adj aneuploidy)
suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
OUT  <- file.path(ROOT, "iscience投稿版本/V2")

## ---------- aneuploidy (fixed: %in% gives FALSE for NA) ----------
cna <- fread(file.path(ROOT, "msk_impact_50k_2026/data_armlevel_cna.txt"), header=TRUE)
arms <- sub("_status$", "", cna$ENTITY_STABLE_ID)
samples <- names(cna)[-(1:3)]
m <- as.matrix(cna[, 4:ncol(cna), with=FALSE]); rownames(m) <- arms
chrom <- suppressWarnings(as.integer(sub("[pq]$", "", arms)))
autosomal <- !is.na(chrom) & chrom <= 22
cat("autosomal arms:", sum(autosomal), "|", paste(arms[autosomal], collapse=","), "\n")
altered <- matrix(m %in% c("Loss","Gain"), nrow=nrow(m), dimnames=dimnames(m))
available <- matrix(!is.na(m) & m != "" & m != "NA", nrow=nrow(m), dimnames=dimnames(m))
cat("missing cells:", sum(!available), "/", length(available), "=", round(100*mean(!available),2), "%\n")
n_alt  <- colSums(altered[autosomal,,drop=FALSE])
n_av   <- colSums(available[autosomal,,drop=FALSE])
aneu <- data.table(SAMPLE_ID=samples, aneuploidy_n=as.integer(n_alt), n_arms_available=as.integer(n_av),
                   aneuploidy_frac=as.numeric(n_alt/n_av),
                   arm_6p_loss=as.logical(m["6p",]) & m["6p",]=="Loss",
                   arm_17p_loss=as.logical(m["17p",]) & m["17p",]=="Loss")
cat("aneuploidy_n:"); print(summary(aneu$aneuploidy_n))
cat("aneuploidy_frac:"); print(summary(aneu$aneuploidy_frac))
fwrite(aneu, file.path(OUT, "r3p2_aneuploidy_scores.tsv"), sep="\t")

## ---------- master cohort ----------
mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"))
p <- mc[analysis_primary == "TRUE"]
p <- merge(p, aneu, by="SAMPLE_ID", all.x=TRUE, suffixes=c("",".aneu"))
cat("primary matched to aneuploidy:", sum(!is.na(p$aneuploidy_n)), "of", nrow(p), "\n")
p[, TUMOR_PURITY_num := suppressWarnings(as.numeric(TUMOR_PURITY))]
cat("TUMOR_PURITY junk (>100):", sum(p$TUMOR_PURITY_num > 100, na.rm=TRUE), "\n")
p[TUMOR_PURITY_num > 100, TUMOR_PURITY_num := NA]
p[, logTMB := log10(TMB_SCORE + 0.1)]
cat("max|logTMB - log_TMB| =", max(abs(p$logTMB - p$log_TMB), na.rm=TRUE), "\n")
p[, LOH := as.integer(any_HLA_LOH)]
p[, WGD := factor(FACETS_WGD)]
p[, CANCER_TYPE := factor(CANCER_TYPE)]; p[, GENE_PANEL := factor(GENE_PANEL)]
p[, SEXf := factor(SEX)]
cat("WGD vs aneuploidy_n:\n")
print(p[, .(n=.N, mean_n=round(mean(aneuploidy_n),2), med_n=as.numeric(median(aneuploidy_n)),
            mean_frac=round(mean(aneuploidy_frac),3)), by=FACETS_WGD])
cat("t-test WGD+ vs WGD- aneuploidy_n: ")
print(t.test(aneuploidy_n ~ FACETS_WGD, data=p[!is.na(FACETS_WGD)]))

## ---------- common complete-case set for Test 1 ----------
cc <- p[!is.na(LOH) & !is.na(logTMB) & !is.na(TUMOR_PURITY_num) & !is.na(aneuploidy_frac) &
        !is.na(FACETS_WGD) & !is.na(CANCER_TYPE) & !is.na(GENE_PANEL)]
cat("Test1 complete-case n:", nrow(cc), " LOH+:", sum(cc$LOH), "\n")
cat("maximal (no purity/WGD requirement) n:",
    nrow(p[!is.na(LOH) & !is.na(logTMB) & !is.na(aneuploidy_frac) & !is.na(CANCER_TYPE) & !is.na(GENE_PANEL)]), "\n")
sd_f <- sd(cc$aneuploidy_frac); sd_n <- sd(cc$aneuploidy_n)
cat("sd(aneuploidy_frac)=", sd_f, " sd(aneuploidy_n)=", sd_n, "\n")
saveRDS(list(p=p, cc=cc, sd_f=sd_f, sd_n=sd_n), file.path(OUT, "r3p2_data.rds"))

orr <- function(mod, term, mult=1) {
  s <- summary(mod)$coefficients
  if (!term %in% rownames(s)) return(c(est=NA,lo=NA,hi=NA,p=NA))
  b <- s[term,1]; se <- s[term,2]
  c(est=exp(b*mult), lo=exp((b-1.96*se)*mult), hi=exp((b+1.96*se)*mult), p=s[term,4])
}
rows <- list(); add <- function(...) rows[[length(rows)+1]] <<- data.table(...)

M0 <- glm(LOH ~ logTMB + CANCER_TYPE + GENE_PANEL + TUMOR_PURITY_num, data=cc, family=binomial())
M1 <- glm(LOH ~ logTMB + CANCER_TYPE + GENE_PANEL + TUMOR_PURITY_num + aneuploidy_frac, data=cc, family=binomial())
M2 <- glm(LOH ~ logTMB + CANCER_TYPE + GENE_PANEL + TUMOR_PURITY_num + aneuploidy_frac + WGD, data=cc, family=binomial())
M2b<- glm(LOH ~ logTMB + CANCER_TYPE + GENE_PANEL + TUMOR_PURITY_num + aneuploidy_n + WGD, data=cc, family=binomial())
M3 <- glm(LOH ~ logTMB + CANCER_TYPE + GENE_PANEL + TUMOR_PURITY_num + WGD, data=cc, family=binomial())
cat("\n--- TEST1 ---\n")
for (nm in c("M0","M1","M2","M2b","M3")) {
  m <- get(nm); r <- orr(m, "logTMB")
  cat(sprintf("%-4s n=%d  logTMB OR=%.3f (%.3f-%.3f) P=%.3g\n", nm, nrow(model.frame(m)), r[1], r[2], r[3], r[4]))
  add(Section="T1_TMB_aneuploidy", Item=paste0("logTMB_OR_", nm), Stratum="complete-case", N=nrow(model.frame(m)),
      Value=sprintf("log10(TMB+0.1) OR=%.3f (%.3f-%.3f)", r[1], r[2], r[3]), Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4],
      Note=c(M0="cancer+panel+purity", M1="+aneuploidy_frac", M2="+aneuploidy_frac+WGD", M2b="+aneuploidy_n+WGD", M3="+WGD only")[nm])
}
r <- orr(M1, "aneuploidy_frac"); rs <- orr(M1, "aneuploidy_frac", 1/sd_f)
cat(sprintf("M1 aneuploidy_frac: OR=%.3f (%.3f-%.3f) P=%.3g | per SD(%.3f): OR=%.3f (%.3f-%.3f) P=%.3g\n",
            r[1],r[2],r[3],r[4], sd_f, rs[1],rs[2],rs[3],rs[4]))
add(Section="T1_TMB_aneuploidy", Item="aneuploidy_frac_OR_per_SD", Stratum="complete-case", N=nrow(model.frame(M1)),
    Value=sprintf("per SD=%.3f OR=%.3f (%.3f-%.3f)", sd_f, rs[1],rs[2],rs[3]), Estimate=rs[1], CI_low=rs[2], CI_high=rs[3], P_value=rs[4], Note="M1")
r <- orr(M2, "aneuploidy_frac")
add(Section="T1_TMB_aneuploidy", Item="aneuploidy_frac_OR_per_unit", Stratum="complete-case(+WGD)", N=nrow(model.frame(M2)),
    Value=sprintf("OR=%.3f (%.3f-%.3f)", r[1],r[2],r[3]), Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note="M2")
r <- orr(M2, "WGDTRUE")
add(Section="T1_TMB_aneuploidy", Item="WGD_OR", Stratum="complete-case", N=nrow(model.frame(M2)),
    Value=sprintf("OR=%.3f (%.3f-%.3f)", r[1],r[2],r[3]), Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note="M2")
r <- orr(M2b, "aneuploidy_n")
add(Section="T1_TMB_aneuploidy", Item="aneuploidy_n_OR_per_arm", Stratum="complete-case(+WGD)", N=nrow(model.frame(M2b)),
    Value=sprintf("per arm OR=%.4f (%.4f-%.4f)", r[1],r[2],r[3]), Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note="M2b")
r <- orr(M3, "logTMB")
add(Section="T1_TMB_aneuploidy", Item="logTMB_OR_M3_WGDonly", Stratum="complete-case", N=nrow(model.frame(M3)),
    Value=sprintf("OR=%.3f (%.3f-%.3f)", r[1],r[2],r[3]), Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note="existing model + WGD")

## ---------- stratified: tertiles / quartiles of aneuploidy_frac ----------
cat("\n--- TEST1 stratified by aneuploidy_frac ---\n")
for (k in c(3,4)) {
  qs <- quantile(cc$aneuploidy_frac, probs=seq(0,1,length.out=k+1))
  qs[1] <- -Inf; qs[k+1] <- Inf
  cc[, strat := cut(aneuploidy_frac, breaks=qs, labels=paste0("Q", 1:k), include.lowest=TRUE)]
  for (g in levels(cc$strat)) {
    dsub <- cc[strat == g]
    if (nrow(dsub) < 200) next
    mm <- glm(LOH ~ logTMB + CANCER_TYPE + GENE_PANEL + TUMOR_PURITY_num, data=dsub, family=binomial())
    r <- orr(mm, "logTMB")
    cat(sprintf("%d-quantile %s: n=%d LOH+=%d range=[%.3f,%.3f] logTMB OR=%.3f (%.3f-%.3f) P=%.3g\n",
                k, g, nrow(dsub), sum(dsub$LOH), min(dsub$aneuploidy_frac), max(dsub$aneuploidy_frac), r[1],r[2],r[3],r[4]))
    add(Section="T1_stratified", Item=paste0(k,"quantile_logTMB_OR"), Stratum=g, N=nrow(dsub),
        Value=sprintf("LOH+=%d frac=[%.3f,%.3f] OR=%.3f (%.3f-%.3f)", sum(dsub$LOH), min(dsub$aneuploidy_frac), max(dsub$aneuploidy_frac), r[1],r[2],r[3]),
        Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note=paste0("tertile"=ifelse(k==3,"tertile","quartile")))
    ## without purity (purity missing could bias small strata)
    mm2 <- glm(LOH ~ logTMB + CANCER_TYPE + GENE_PANEL, data=dsub, family=binomial())
    r2 <- orr(mm2, "logTMB")
    cat(sprintf("    (no purity) OR=%.3f (%.3f-%.3f) P=%.3g\n", r2[1],r2[2],r2[3],r2[4]))
    add(Section="T1_stratified", Item=paste0(k,"quantile_logTMB_OR_nopurity"), Stratum=g, N=nrow(dsub),
        Value=sprintf("OR=%.3f (%.3f-%.3f)", r2[1],r2[2],r2[3]), Estimate=r2[1], CI_low=r2[2], CI_high=r2[3], P_value=r2[4], Note="cancer+panel only")
  }
  cc[, strat := NULL]
}
fwrite(rbindlist(rows, fill=TRUE), file.path(OUT, "r3p2_part1_rows.tsv"), sep="\t")
cat("\nSTEP3 done\n")
