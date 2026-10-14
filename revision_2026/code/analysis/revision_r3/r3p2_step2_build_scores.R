## R3 part2 — step 2: build Davoli-style aneuploidy score from arm-level CNA + rebuild 6 process scores
suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
OUT  <- file.path(ROOT, "iscience投稿版本/V2")

## ---------- A. arm-level CNA ----------
cna <- fread(file.path(ROOT, "msk_impact_50k_2026/data_armlevel_cna.txt"), header=TRUE)
cat("cna dim:", dim(cna), "\n")
arms <- cna$ENTITY_STABLE_ID
arms <- sub("_status$", "", arms)
cat("arms:", paste(arms, collapse=","), "\n")
cat("status values:\n"); print(table(unlist(cna[, 4:ncol(cna), with=FALSE])))

samples <- names(cna)[-(1:3)]
m <- as.matrix(cna[, 4:ncol(cna), with=FALSE])   # 41 x N samples, characters
rownames(m) <- arms
chrom <- suppressWarnings(as.integer(sub("[pq]$", "", arms)))
autosomal <- !is.na(chrom) & chrom <= 22
cat("autosomal arms kept:", sum(autosomal), " (of", length(arms), ")\n")

altered <- (m == "Loss" | m == "Gain")
available <- !is.na(m) & m != "NA" & m != "" & m != "Not Applicable"
cat("total missing cells in all arms:", sum(!available), "of", length(available),
    "=", round(100*sum(!available)/length(available), 2), "%\n")

n_alt_all <- colSums(altered[autosomal, , drop=FALSE])
n_avail   <- colSums(available[autosomal, , drop=FALSE])
stopifnot(all(n_avail > 0))
aneu <- data.table(SAMPLE_ID = samples,
                   aneuploidy_n = as.integer(n_alt_all),
                   n_arms_available = as.integer(n_avail),
                   aneuploidy_frac = n_alt_all / n_avail)
aneu[, arm_6p_loss := (m["6p", ] == "Loss")[match(SAMPLE_ID, samples)]]
aneu[, arm_17p_loss := (m["17p", ] == "Loss")[match(SAMPLE_ID, samples)]]
cat("\naneuploidy_n summary:\n"); print(summary(aneu$aneuploidy_n))
cat("aneuploidy_frac summary:\n"); print(summary(aneu$aneuploidy_frac))
cat("n_arms_available distribution:\n"); print(table(aneu$n_arms_available <= 20, aneu$n_arms_available == 39))

## ---------- B. signatures (COSMIC v2) ----------
sg <- fread(file.path(ROOT, "msk_impact_50k_2026/data_mutational_signatures_contribution_v2.txt"), header=TRUE)
cat("\nsig dim:", dim(sg), "\n")
cat("sig ids:\n"); print(sg$ENTITY_STABLE_ID)
sgnum <- as.integer(sub(".*Signature", "", sg$ENTITY_STABLE_ID))
ssamp <- names(sg)[-(1:4)]
sm <- as.matrix(sg[, 5:ncol(sg), with=FALSE]); rownames(sm) <- paste0("S", sgnum)
cat("sig samples:", length(ssamp), "\n")
mk <- function(ids) if (length(ids) == 1) sm[paste0("S", ids), ] else colSums(sm[paste0("S", ids), , drop=FALSE])
sigs <- data.table(
  SAMPLE_ID = ssamp,
  raw_APOBEC = mk(c(2, 13)),
  raw_HRD    = mk(3),
  raw_MMR    = mk(c(6, 15, 20, 26)),
  raw_smoke  = mk(4),
  raw_UV     = mk(7),
  raw_aging  = mk(1))
cat("\nraw signature score means (all sig samples):\n")
print(sapply(sigs[, -1], mean))

## compare to master_cohort aggregated columns
mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"),
            select=c("SAMPLE_ID","analysis_primary","one_per_patient","any_HLA_LOH","HLA_LOH_burden",
                     "TMB_SCORE","log_TMB","FACETS_WGD","TUMOR_PURITY","FACETS_PURITY","AGE_AT_DX","SEX",
                     "CANCER_TYPE","GENE_PANEL","OS_MONTHS","OS_event","sig_APOBEC","sig_HRD","sig_MMR",
                     "sig_aging","sig_smoke","sig_UV","sig_available"))
cmp <- merge(sigs, mc[, .(SAMPLE_ID, sig_APOBEC, sig_HRD, sig_MMR, sig_smoke, sig_UV, sig_aging, sig_available)],
             by="SAMPLE_ID", all.x=FALSE)
cat("\nmerged with master:", nrow(cmp), "\n")
for (s in c("APOBEC","HRD","MMR","smoke","UV","aging")) {
  a <- cmp[[paste0("raw_", s)]]; b <- cmp[[paste0("sig_", s)]]
  cat(sprintf("%-7s  max|diff|=%.3e  cor=%.6f  matches(<1e-9)=%d/%d\n", s,
              max(abs(a-b), na.rm=TRUE), cor(a, b, use="complete.obs"),
              sum(abs(a-b) < 1e-9, na.rm=TRUE), sum(!is.na(b))))
}

## ---------- C. build analysis file ----------
p <- copy(mc)
p <- merge(aneu, p, by="SAMPLE_ID", all.y=TRUE)
p[, TUMOR_PURITY_num := suppressWarnings(as.numeric(TUMOR_PURITY))]
cat("\nmatched primary to aneuploidy:", sum(!is.na(p$aneuploidy_n) & p$analysis_primary=="TRUE"),
    "of", sum(p$analysis_primary=="TRUE"), "\n")
pp <- p[analysis_primary == "TRUE"]
cat("TUMOR_PURITY_num summary:\n"); print(summary(pp$TUMOR_PURITY_num))
cat("TUMOR_PURITY blank:", sum(pp$TUMOR_PURITY == ""), "\n")
cat("cor(TUMOR_PURITY_num, FACETS_PURITY):",
    cor(pp$TUMOR_PURITY_num, pp$FACETS_PURITY, use="complete.obs"), "\n")
cat("\nWGD vs aneuploidy_n (primary):\n")
print(pp[, .(n=.N, mean_n=mean(aneuploidy_n), med_n=as.numeric(median(aneuploidy_n)),
             mean_frac=mean(aneuploidy_frac)), by=FACETS_WGD])
fwrite(aneu, file.path(OUT, "r3p2_aneuploidy_scores.tsv"), sep="\t")
cat("\nsaved aneuploidy table\n")
