## R3 part2 — step 6: assemble final TSV
suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"; OUT <- file.path(ROOT, "iscience投稿版本/V2")
aneu <- fread(file.path(OUT, "r3p2_aneuploidy_scores.tsv"))
D <- readRDS(file.path(OUT, "r3p2_data.rds")); p <- D$p
a <- merge(p[, .(SAMPLE_ID, FACETS_WGD, LOH)], aneu, by="SAMPLE_ID")
s0 <- list(); ad <- function(...) s0[[length(s0)+1]] <<- data.table(...)
ad(Section="S0_aneuploidy", Item="armlevel_file", Stratum="41 arms x 53929 samples", N=53929,
   Value="39 autosomal arms used; X (23p/23q) excluded", Estimate=NA, CI_low=NA, CI_high=NA, P_value=NA,
   Note="data_armlevel_cna.txt")
ad(Section="S0_aneuploidy", Item="missing_cells", Stratum="all arms", N=53929,
   Value="246353 / 2211089 = 11.14%", Estimate=NA, CI_low=NA, CI_high=NA, P_value=NA, Note="normalised by available arms")
ad(Section="S0_aneuploidy", Item="primary_match_rate", Stratum="primary cohort", N=29799,
   Value="29799 / 29799 = 100%", Estimate=NA, CI_low=NA, CI_high=NA, P_value=NA, Note="SAMPLE_ID merge")
ad(Section="S0_aneuploidy", Item="aneuploidy_n_stats", Stratum="primary", N=29799,
   Value=sprintf("mean=%.2f median=%.0f range=%d-%d IQR=%.0f-%.0f", mean(p$aneuploidy_n), median(p$aneuploidy_n),
                 min(p$aneuploidy_n), max(p$aneuploidy_n), quantile(p$aneuploidy_n,.25), quantile(p$aneuploidy_n,.75)),
   Estimate=mean(p$aneuploidy_n), CI_low=NA, CI_high=NA, P_value=NA, Note="count of altered autosomal arms")
ad(Section="S0_aneuploidy", Item="aneuploidy_frac_stats", Stratum="primary", N=29799,
   Value=sprintf("mean=%.4f median=%.4f sd=%.4f IQR=%.3f-%.3f", mean(p$aneuploidy_frac), median(p$aneuploidy_frac),
                 sd(p$aneuploidy_frac), quantile(p$aneuploidy_frac,.25), quantile(p$aneuploidy_frac,.75)),
   Estimate=mean(p$aneuploidy_frac), CI_low=NA, CI_high=NA, P_value=NA, Note="n_altered / n_available autosomal arms")
ad(Section="S0_aneuploidy", Item="arms_available_median", Stratum="primary", N=29799,
   Value=sprintf("median=%.0f; >=30/39 in %.1f%%; =39/39 in %.1f%%", median(p$n_arms_available),
                 100*mean(p$n_arms_available>=30), 100*mean(p$n_arms_available==39)),
   Estimate=median(p$n_arms_available), CI_low=NA, CI_high=NA, P_value=NA, Note="missingness is per-sample")
ad(Section="S0_aneuploidy", Item="VALIDATION_WGDplus_vs_minus", Stratum="WGD+=TRUE", N=sum(a$FACETS_WGD=="TRUE", na.rm=TRUE),
   Value=sprintf("mean aneuploidy_n=%.2f median=%.0f", mean(a$aneuploidy_n[a$FACETS_WGD=="TRUE"], na.rm=TRUE),
                 median(a$aneuploidy_n[a$FACETS_WGD=="TRUE"], na.rm=TRUE)),
   Estimate=mean(a$aneuploidy_n[a$FACETS_WGD=="TRUE"], na.rm=TRUE), CI_low=NA, CI_high=NA, P_value=NA, Note="prior spotcheck: 27.6")
ad(Section="S0_aneuploidy", Item="VALIDATION_WGDplus_vs_minus", Stratum="WGD-=FALSE", N=sum(a$FACETS_WGD=="FALSE", na.rm=TRUE),
   Value=sprintf("mean aneuploidy_n=%.2f median=%.0f", mean(a$aneuploidy_n[a$FACETS_WGD=="FALSE"], na.rm=TRUE),
                 median(a$aneuploidy_n[a$FACETS_WGD=="FALSE"], na.rm=TRUE)),
   Estimate=mean(a$aneuploidy_n[a$FACETS_WGD=="FALSE"], na.rm=TRUE), CI_low=NA, CI_high=NA, P_value=2.2e-16,
   Note="prior spotcheck: 9.3; Welch t=-220.1")
ad(Section="S0_aneuploidy", Item="cor_logTMB_vs_aneuploidy_frac", Stratum="primary", N=nrow(p),
   Value=sprintf("Pearson r=%.4f (log10(TMB+0.1) vs frac); Spearman rho=%.4f",
                 cor(p$logTMB, p$aneuploidy_frac, use="complete.obs"),
                 cor(p$logTMB, p$aneuploidy_frac, method="spearman", use="complete.obs")),
   Estimate=cor(p$logTMB, p$aneuploidy_frac, use="complete.obs"), CI_low=NA, CI_high=NA, P_value=NA, Note="key confounder")
ad(Section="S0_aneuploidy", Item="TUMOR_PURITY_QC", Stratum="primary", N=29799,
   Value=sprintf("pathologist purity: median=%.0f; blanks=%d; values>100 (source data-entry errors, set NA)=%d",
                 median(as.numeric(p$TUMOR_PURITY[p$TUMOR_PURITY != ""]), na.rm=TRUE),
                 sum(p$TUMOR_PURITY == ""),
                 sum(suppressWarnings(as.numeric(p$TUMOR_PURITY)) > 100, na.rm=TRUE)),
   Estimate=NA, CI_low=NA, CI_high=NA, P_value=NA,
   Note=sprintf("cor(TUMOR_PURITY, FACETS_PURITY)=%.3f", cor(as.numeric(p$TUMOR_PURITY[p$TUMOR_PURITY!=""]),
       p$FACETS_PURITY[p$TUMOR_PURITY!=""], use="complete.obs")))

all <- rbindlist(list(
  rbindlist(s0, fill=TRUE),
  fread(file.path(OUT, "r3p2_part1_rows.tsv")),
  fread(file.path(OUT, "r3p2_part2_rows.tsv")),
  fread(file.path(OUT, "r3p2_part34_rows.tsv"))), fill=TRUE)
fwrite(all, file.path(OUT, "REVIEWER3_spotchecks_part2.tsv"), sep="\t")
cat("rows written:", nrow(all), "\n"); print(table(all$Section))
