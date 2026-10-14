suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
mc <- readRDS(file.path(ROOT,"iscience投稿版本/V2/r3p3_mc_explore.rds"))
p <- mc[analysis_primary=="TRUE"]
cat("germ_hom_A:\n"); print(table(p$germ_hom_A, useNA="ifany"))
cat("germ_hom_B:\n"); print(table(p$germ_hom_B, useNA="ifany"))
cat("germ_hom_C:\n"); print(table(p$germ_hom_C, useNA="ifany"))
cat("germ_fully_het:\n"); print(table(p$germ_fully_het, useNA="ifany"))
cat("n_eval_alleles:\n"); print(table(p$n_eval_alleles, useNA="ifany"))
cat("hla_evaluable:\n"); print(table(p$hla_evaluable, useNA="ifany"))
cat("SAMPLE_TYPE:\n"); print(table(p$SAMPLE_TYPE, useNA="ifany"))
cat("\nsig_HRD summary primary with sig_available:\n")
print(summary(p[sig_available=="TRUE"]$sig_HRD))
cat("sig_MMR:\n"); print(summary(p[sig_available=="TRUE"]$sig_MMR))
# check germ cols are per-locus homozygous flags
cat("\nhead germ cols:\n"); print(head(p[,.(SAMPLE_ID,germ_hom_A,germ_hom_B,germ_hom_C,germ_fully_het,n_eval_alleles,any_HLA_LOH)],10))
