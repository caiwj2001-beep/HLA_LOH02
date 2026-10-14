suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
aneu <- fread(file.path(ROOT, "iscience投稿版本/V2/r3p2_aneuploidy_scores.tsv"))
cat("aneu dim:", dim(aneu), "\n"); print(head(aneu))
mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"),
            select=c("SAMPLE_ID","analysis_primary","TUMOR_PURITY","FACETS_PURITY","SAMPLE_TYPE"))
pp <- mc[analysis_primary=="TRUE"]
cat("primary n:", nrow(pp), "\n")
cat("in aneu:", sum(pp$SAMPLE_ID %in% aneu$SAMPLE_ID), "\n")
cat("n aneu ids:", length(unique(aneu$SAMPLE_ID)), "\n")
cat("sample of aneu ids not in primary:\n"); print(head(setdiff(aneu$SAMPLE_ID, pp$SAMPLE_ID), 5))
cat("sample of primary ids not in aneu:\n"); print(head(setdiff(pp$SAMPLE_ID, aneu$SAMPLE_ID), 5))
cat("n_avail table:\n"); print(table(aneu$n_arms_available))
cat("aneuploidy_n summary:\n"); print(summary(aneu$aneuploidy_n))
cat("\nTUMOR_PURITY top values (primary):\n"); print(head(sort(table(pp$TUMOR_PURITY), decreasing=TRUE), 40))
cat("non-numeric TUMOR_PURITY:\n"); print(unique(grep("^[0-9]+$", pp$TUMOR_PURITY, value=TRUE, invert=TRUE))[1:20])
