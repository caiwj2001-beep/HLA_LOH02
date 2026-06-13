#!/usr/bin/env Rscript
# HLA_LOH02 — Phase 1b: Data Structure Exploration
# ================================================

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

setwd("/home/caiwj2001/HLA_LOH02")
DATA_DIR <- file.path(getwd(), "msk_impact_50k_2026")

cat("========================================\n")
cat("HLA_LOH02 Data Exploration — Phase 1b\n")
cat("Date:", as.character(Sys.time()), "\n")
cat("========================================\n\n")

# 1. HLA LOH data — most critical
cat("--- 1. HLA LOH data ---\n")
hla <- fread(file.path(DATA_DIR, "data_hla_loh.txt"), sep = "\t", nThread = 4)
cat(sprintf("Dimensions: %d rows x %d columns\n", nrow(hla), ncol(hla)))
cat("Columns:", paste(colnames(hla)[1:min(10, ncol(hla))], collapse=", "), "...\n")

# First 2 columns are ENTITY_STABLE_ID and HLA_GENE
cat("\nHLA genes:", unique(hla$HLA_GENE), "\n")
cat("Sample count:", ncol(hla) - 2, "\n")

# LOH frequency per gene
for (g in unique(hla$HLA_GENE)) {
  vals <- as.matrix(hla[HLA_GENE == g, -c(1,2)])
  n_total <- sum(!is.na(vals) & vals != "NA")
  n_loh <- sum(vals == "LOH", na.rm = TRUE)
  n_het <- sum(vals == "HET", na.rm = TRUE)
  n_hom <- sum(vals == "HOM", na.rm = TRUE)
  cat(sprintf("  %s: LOH=%d, HET=%d, HOM=%d, NA=%d (LOH rate=%.1f%%)\n",
      g, n_loh, n_het, n_hom, 
      ncol(hla)-2 - n_total,
      100 * n_loh / (n_loh + n_het)))
}

# Any sample with any HLA LOH
sample_ids <- colnames(hla)[-c(1,2)]
loh_matrix <- as.matrix(hla[, -c(1,2)])
rownames(loh_matrix) <- hla$HLA_GENE
any_loh <- apply(loh_matrix, 2, function(x) sum(x == "LOH", na.rm = TRUE) > 0)
cat(sprintf("\nAny HLA LOH: %d / %d samples (%.1f%%)\n",
    sum(any_loh, na.rm=TRUE), length(any_loh), 100*sum(any_loh, na.rm=TRUE)/length(any_loh)))

# Number of loci affected
n_loci_loh <- apply(loh_matrix, 2, function(x) sum(x == "LOH", na.rm = TRUE))
cat("Locus distribution:\n")
print(table(n_loci_loh))

# 2. Clinical data
cat("\n\n--- 2. Clinical data ---\n")
clin <- fread(file.path(DATA_DIR, "data_clinical_patient.txt"), sep = "\t", skip = 4)
cat(sprintf("Dimensions: %d rows x %d columns\n", nrow(clin), ncol(clin)))
cat("Columns:", paste(colnames(clin), collapse=", "), "\n")
cat("Cancer types:", length(unique(clin$CANCER_TYPE)), "\nsome types:\n")
print(head(sort(table(clin$CANCER_TYPE), decreasing=TRUE), 20))
cat(sprintf("\nOS events: %d / %d (%.1f%%)\n", 
    sum(clin$OS_STATUS == "1:DECEASED", na.rm=TRUE), 
    sum(!is.na(clin$OS_STATUS)), 
    100*sum(clin$OS_STATUS=="1:DECEASED",na.rm=TRUE)/sum(!is.na(clin$OS_STATUS))))
cat(sprintf("Median OS: %.1f months\n", median(clin$OS_MONTHS, na.rm=TRUE)))

# 3. Mutations summary
cat("\n\n--- 3. Mutations — counting lines ---\n")
cmd <- sprintf("wc -l %s", file.path(DATA_DIR, "data_mutations.txt"))
system(cmd)

# Read header only
mut_header <- fread(file.path(DATA_DIR, "data_mutations.txt"), sep = "\t", nrows = 5)
cat("Mutation columns:", paste(colnames(mut_header), collapse=", "), "\n")

# 4. Mutational signatures
cat("\n\n--- 4. Mutational signatures ---\n")
sig <- fread(file.path(DATA_DIR, "data_mutational_signatures_contribution_v2.txt"), sep = "\t")
cat(sprintf("Dimensions: %d rows x %d columns\n", nrow(sig), ncol(sig)))
cat("Signature names:", paste(sig$NAME[1:min(20,nrow(sig))], collapse=", "), "...\n")

# 5. CNA data
cat("\n\n--- 5. CNA data ---\n")
cmd <- sprintf("wc -l %s", file.path(DATA_DIR, "data_cna.txt"))
system(cmd)

cat("\n\nExploration complete.\n")
