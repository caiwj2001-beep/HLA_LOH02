## R3 part4 — step 1: explore technical/QC variables in 3 groups
suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"))
cat("dim:", dim(mc), "\n")
p <- mc[analysis_primary == "TRUE"]
cat("primary n:", nrow(p), "\n")

cat("\n--- SAMPLE_COVERAGE summary (primary) ---\n"); print(summary(as.numeric(p$SAMPLE_COVERAGE)))
cat("\n--- FACETS_QC values ---\n"); print(table(p$FACETS_QC, useNA="ifany"))
cat("\n--- MSI_TYPE values ---\n"); print(table(p$MSI_TYPE, useNA="ifany"))
cat("\n--- GENE_PANEL values ---\n"); print(table(p$GENE_PANEL, useNA="ifany"))
cat("\n--- FACETS_WGD ---\n"); print(table(p$FACETS_WGD, useNA="ifany"))
cat("\n--- TUMOR_PURITY summary ---\n"); print(summary(as.numeric(p$TUMOR_PURITY)))
cat("\n--- FACETS_PURITY summary ---\n"); print(summary(as.numeric(p$FACETS_PURITY)))
cat("\n--- FACETS_PLOIDY summary ---\n"); print(summary(as.numeric(p$FACETS_PLOIDY)))

## groups
p[, grp := fifelse(any_HLA_LOH=="TRUE" & arm_6p_loss=="TRUE", "Arm_dependent",
            fifelse(any_HLA_LOH=="TRUE" & arm_6p_loss=="FALSE", "Arm_independent",
            fifelse(any_HLA_LOH=="FALSE", "No_LOH", "LOH_6p_missing")))]
cat("\n--- group table ---\n"); print(table(p$grp, useNA="ifany"))

cat("\n--- coverage by group ---\n"); print(p[, .(n=.N, med=median(as.numeric(SAMPLE_COVERAGE),na.rm=T)), by=grp])
cat("\n--- FACETS_QC by group ---\n"); print(table(p$grp, p$FACETS_QC, useNA="ifany"))
cat("\n--- MSI_TYPE by group ---\n"); print(table(p$grp, p$MSI_TYPE, useNA="ifany"))
cat("\n--- GENE_PANEL by group ---\n"); print(table(p$grp, p$GENE_PANEL, useNA="ifany"))
cat("\n--- FACETS_WGD by group ---\n"); print(table(p$grp, p$FACETS_WGD, useNA="ifany"))
cat("\n--- ploidy by group ---\n"); print(p[!is.na(as.numeric(FACETS_PLOIDY)), .(n=.N, med=median(as.numeric(FACETS_PLOIDY))), by=grp])
