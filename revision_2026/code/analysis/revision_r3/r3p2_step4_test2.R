## R3 part2 — step 4: signature provenance check + TEST 2 (all six signatures, unified adjustment)
suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
OUT  <- file.path(ROOT, "iscience投稿版本/V2")

## ---- resolve MMR signature composition (brute force vs master column) ----
sg <- fread(file.path(ROOT, "msk_impact_50k_2026/data_mutational_signatures_contribution_v2.txt"), header=TRUE)
sgnum <- as.integer(sub(".*Signature", "", sg$ENTITY_STABLE_ID))
sm <- as.matrix(sg[, 5:ncol(sg), with=FALSE]); rownames(sm) <- paste0("S", sgnum); ssamp <- names(sg)[-(1:4)]
mc0 <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"),
             select=c("SAMPLE_ID","sig_MMR","sig_APOBEC","sig_HRD","sig_smoke","sig_UV","sig_aging","sig_available"))
idx <- match(ssamp, mc0$SAMPLE_ID)
keep <- !is.na(idx)
target <- mc0$sig_MMR[idx[keep]]
cands <- c(6,14,15,20,21,26)
best <- NULL
for (k in 1:5) {
  cmb <- combn(cands, k)
  for (j in seq_len(ncol(cmb))) {
    ids <- paste0("S", cmb[, j])
    v <- if (length(ids)==1) sm[ids, ][keep] else colSums(sm[ids, , drop=FALSE])[keep]
    if (all(abs(v - target) < 1e-9, na.rm=TRUE)) best <- c(best, list(cmb[, j]))
  }
}
cat("MMR combos that reproduce master sig_MMR exactly:\n"); print(best)
mmr_ids <- if (length(best) > 0) best[[1]] else c(6,15,20,26)
cat("using MMR =", paste0("S", mmr_ids, collapse="+"), "\n")

mk <- function(ids) if (length(ids)==1) sm[paste0("S",ids), ] else colSums(sm[paste0("S",ids), , drop=FALSE])
sigs <- data.table(SAMPLE_ID=ssamp, raw_APOBEC=mk(c(2,13)), raw_HRD=mk(3), raw_MMR=mk(mmr_ids),
                   raw_smoke=mk(4), raw_UV=mk(7), raw_aging=mk(1))
for (s in c("APOBEC","HRD","MMR","smoke","UV","aging")) {
  a <- sigs[[paste0("raw_",s)]]; b <- mc0[[paste0("sig_",s)]][idx]
  cat(sprintf("%-7s matches(<1e-9)=%d/%d cor=%.6f\n", s, sum(abs(a-b)<1e-9, na.rm=TRUE), sum(!is.na(b)),
              cor(a,b,use="complete.obs")))
}

## ---- analysis set ----
D <- readRDS(file.path(OUT, "r3p2_data.rds")); p <- D$p
d2 <- merge(p[sig_available == "TRUE"], sigs, by="SAMPLE_ID")
d2 <- d2[!is.na(LOH) & !is.na(logTMB) & !is.na(FACETS_WGD) & !is.na(CANCER_TYPE) & !is.na(GENE_PANEL) &
         !is.na(raw_APOBEC) & !is.na(raw_HRD) & !is.na(raw_MMR) & !is.na(raw_smoke) & !is.na(raw_UV) & !is.na(raw_aging)]
cat("\nsig analysis set n:", nrow(d2), " LOH+:", sum(d2$LOH), "\n")
zs <- c("APOBEC","HRD","MMR","smoke","UV","aging")
for (s in zs) d2[[paste0("z_",s)]] <- as.numeric(scale(d2[[paste0("raw_",s)]]))
cat("raw means:", paste(sprintf("%s=%.4f", zs, sapply(zs, function(s) mean(d2[[paste0("raw_",s)]]))), collapse=" "), "\n")

orr <- function(mod, term) { s <- summary(mod)$coefficients
  if (!term %in% rownames(s)) return(c(est=NA,lo=NA,hi=NA,p=NA))
  b <- s[term,1]; se <- s[term,2]; c(est=exp(b), lo=exp(b-1.96*se), hi=exp(b+1.96*se), p=s[term,4]) }

rows <- list(); add <- function(...) rows[[length(rows)+1]] <<- data.table(...)
res <- data.table()
for (s in zs) {
  mu <- glm(as.formula(paste0("LOH ~ z_", s)), data=d2, family=binomial())
  ma <- glm(as.formula(paste0("LOH ~ z_", s, " + logTMB + FACETS_WGD + CANCER_TYPE + GENE_PANEL + TUMOR_PURITY_num")),
            data=d2, family=binomial())
  rb <- orr(mu, paste0("z_", s)); ra <- orr(ma, paste0("z_", s))
  n_a <- nrow(model.frame(ma))
  cat(sprintf("%-7s unadj OR=%.3f (%.3f-%.3f) P=%.3g | adj OR=%.3f (%.3f-%.3f) P=%.3g  (n=%d)\n",
              s, rb[1],rb[2],rb[3],rb[4], ra[1],ra[2],ra[3],ra[4], n_a))
  res <- rbind(res, data.table(sig=s, unadj_OR=rb[1], unadj_lo=rb[2], unadj_hi=rb[3], unadj_P=rb[4],
                               adj_OR=ra[1], adj_lo=ra[2], adj_hi=ra[3], adj_P=ra[4], n=n_a))
}
res[, unadj_FDR := p.adjust(unadj_P, "BH")]
res[, adj_FDR := p.adjust(adj_P, "BH")]
cat("\nBH-FDR results:\n"); print(res[, .(sig, adj_OR=round(adj_OR,3), adj_P=signif(adj_P,3), adj_FDR=signif(adj_FDR,3),
                                          unadj_OR=round(unadj_OR,3), unadj_P=signif(unadj_P,3), unadj_FDR=signif(unadj_FDR,3))])
fwrite(res, file.path(OUT, "r3p2_part2_signatures.tsv"), sep="\t")

for (i in seq_len(nrow(res))) {
  r <- res[i]
  add(Section="T2_signatures", Item="per_SD_OR_unadjusted", Stratum=r$sig, N=r$n,
      Value=sprintf("OR=%.3f (%.3f-%.3f) P=%.3g FDR=%.3g", r$unadj_OR, r$unadj_lo, r$unadj_hi, r$unadj_P, r$unadj_FDR),
      Estimate=r$unadj_OR, CI_low=r$unadj_lo, CI_high=r$unadj_hi, P_value=r$unadj_P, Note=paste0("BH_FDR=",signif(r$unadj_FDR,3)))
  add(Section="T2_signatures", Item="per_SD_OR_adjusted", Stratum=r$sig, N=r$n,
      Value=sprintf("OR=%.3f (%.3f-%.3f) P=%.3g FDR=%.3g", r$adj_OR, r$adj_lo, r$adj_hi, r$adj_P, r$adj_FDR),
      Estimate=r$adj_OR, CI_low=r$adj_lo, CI_high=r$adj_hi, P_value=r$adj_P,
      Note=paste0("adj logTMB+WGD+cancer+panel+purity; BH_FDR=", signif(r$adj_FDR,3)))
}
## all six in ONE model (mutually adjusted) as extra sensitivity
mall <- glm(LOH ~ z_APOBEC + z_HRD + z_MMR + z_smoke + z_UV + z_aging + logTMB + FACETS_WGD + CANCER_TYPE + GENE_PANEL + TUMOR_PURITY_num,
            data=d2, family=binomial())
cat("\nmutually adjusted (all 6 in one model):\n")
for (s in zs) { r <- orr(mall, paste0("z_", s)); cat(sprintf("%-7s OR=%.3f (%.3f-%.3f) P=%.3g\n", s, r[1],r[2],r[3],r[4])) }
mres <- data.table(sig=zs, OR=sapply(zs, function(s) orr(mall, paste0("z_",s))[1]),
                   lo=sapply(zs, function(s) orr(mall, paste0("z_",s))[2]),
                   hi=sapply(zs, function(s) orr(mall, paste0("z_",s))[3]),
                   P=sapply(zs, function(s) orr(mall, paste0("z_",s))[4]))
mres[, FDR := p.adjust(P,"BH")]
print(mres)
fwrite(mres, file.path(OUT, "r3p2_part2_signatures_mutual.tsv"), sep="\t")
for (i in seq_len(nrow(mres))) { r <- mres[i]
  add(Section="T2_signatures_mutual", Item="per_SD_OR_all6_in_model", Stratum=r$sig, N=nrow(model.frame(mall)),
      Value=sprintf("OR=%.3f (%.3f-%.3f) P=%.3g FDR=%.3g", r$OR,r$lo,r$hi,r$P,r$FDR), Estimate=r$OR, CI_low=r$lo,
      CI_high=r$hi, P_value=r$P, Note="mutually adjusted + logTMB+WGD+cancer+panel+purity") }
fwrite(rbindlist(rows, fill=TRUE), file.path(OUT, "r3p2_part2_rows.tsv"), sep="\t")
cat("\nSTEP4 done\n")
