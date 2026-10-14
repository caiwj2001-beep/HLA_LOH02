## R3 part3 — step 1: exploration
suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"),
            select=c("SAMPLE_ID","PATIENT_ID","analysis_primary","any_HLA_LOH","HLA_LOH_burden",
                     "arm_6p","arm_6p_loss","arm_9p","arm_9p_loss","CANCER_TYPE","GENE_PANEL",
                     "TMB_SCORE","log_TMB","FACETS_WGD","TUMOR_PURITY","FACETS_PURITY","FACETS_PLOIDY",
                     "AGE_AT_DX","SEX","OS_MONTHS","OS_event","sig_HRD","sig_MMR","sig_available",
                     "SAMPLE_TYPE","HLA_A1_LOH","HLA_A2_LOH","HLA_B1_LOH","HLA_B2_LOH","HLA_C1_LOH","HLA_C2_LOH",
                     "germ_hom_A","germ_hom_B","germ_hom_C","germ_fully_het","n_eval_alleles","hla_evaluable",
                     "MSI_status"))
cat("dim:", dim(mc), "\n")
p <- mc[analysis_primary == "TRUE"]
cat("primary n:", nrow(p), "\n")
cat("arm_6p values:\n"); print(table(p$arm_6p, useNA="ifany"))
cat("arm_6p_loss values:\n"); print(table(p$arm_6p_loss, useNA="ifany"))
cat("any_HLA_LOH:\n"); print(table(p$any_HLA_LOH, useNA="ifany"))

loh <- p[any_HLA_LOH == "TRUE"]
cat("any-LOH n:", nrow(loh), "\n")
cat("arm_6p among LOH:\n"); print(table(loh$arm_6p, useNA="ifany"))
cat("arm_6p_loss among LOH:\n"); print(table(loh$arm_6p_loss, useNA="ifany"))
# 28.3% check: no 6p loss
nol6p <- loh[arm_6p_loss == "FALSE"]
cat("LOH with arm_6p_loss==FALSE:", nrow(nol6p), "=", round(100*nrow(nol6p)/nrow(loh),2), "%\n")

cat("\nSAMPLE_TYPE values:\n"); print(table(p$SAMPLE_TYPE, useNA="ifany"))
cat("\nMSI_status among LOH:\n"); print(table(loh$MSI_status, useNA="ifany"))
cat("\nsig_available among LOH:\n"); print(table(loh$sig_available, useNA="ifany"))
cat("\nFACETS_PLOIDY summary (LOH):\n"); print(summary(as.numeric(loh$FACETS_PLOIDY)))
cat("\nFACETS_WGD among LOH:\n"); print(table(loh$FACETS_WGD, useNA="ifany"))

# HLA per-allele LOH: number of alleles lost
for (c in c("HLA_A1_LOH","HLA_A2_LOH","HLA_B1_LOH","HLA_B2_LOH","HLA_C1_LOH","HLA_C2_LOH")) {
  cat(c, ": "); print(table(p[[c]], useNA="ifany"))
}
saveRDS(mc, file.path(ROOT,"iscience投稿版本/V2/r3p3_mc_explore.rds"))
cat("saved explore rds\n")
