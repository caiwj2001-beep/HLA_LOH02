################################################################################
# HLA_LOH02 - Deep Data Exploration (decisive for study design)
# Focus: patient-level HLA genotype/OS, mutational signatures, arm-level CNA (chr6p)
################################################################################
suppressMessages(library(data.table))

data_dir <- "C:/Users/Administrator/科研文件/HLA_LOH02/msk_impact_50k_2026"
out_dir  <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/02_data_inventory"

# ── 1. Patient-level data: HLA genotype, ancestry, OS ─────────────────────────
cat("========== PATIENT-LEVEL DATA ==========\n")
pat <- fread(file.path(data_dir, "data_clinical_patient.txt"), skip = 4, header = TRUE)
cat(sprintf("Patients: %d | Columns: %s\n\n", nrow(pat), paste(names(pat), collapse=", ")))

cat("--- SEX ---\n"); print(table(pat$SEX, useNA="ifany"))
cat("\n--- OS_STATUS ---\n"); print(table(pat$OS_STATUS, useNA="ifany"))
cat("\n--- OS_MONTHS summary ---\n")
os <- suppressWarnings(as.numeric(pat$OS_MONTHS))
cat(sprintf("  Available: %d (%.1f%%) | Median: %.1f | Range: %.1f-%.1f\n",
            sum(!is.na(os)), 100*mean(!is.na(os)),
            median(os,na.rm=TRUE), min(os,na.rm=TRUE), max(os,na.rm=TRUE)))

cat("\n--- ANCESTRY_LABEL ---\n"); print(table(pat$ANCESTRY_LABEL, useNA="ifany"))
cat("\n--- HLA_GENOTYPE_AVAILABLE ---\n"); print(table(pat$HLA_GENOTYPE_AVAILABLE, useNA="ifany"))

cat("\n--- AGE_AT_DX summary ---\n")
age <- suppressWarnings(as.numeric(pat$AGE_AT_DX))
cat(sprintf("  Available: %d | Median: %.0f | Range: %.0f-%.0f\n",
            sum(!is.na(age)), median(age,na.rm=TRUE), min(age,na.rm=TRUE), max(age,na.rm=TRUE)))

# HLA-A/B/C genotype homozygosity (germline) - relevant for LOH interpretation
cat("\n--- HLA GERMLINE GENOTYPE (first patient rows) ---\n")
hla_geno_cols <- c("HLA-A1","HLA-A2","HLA-B1","HLA-B2","HLA-C1","HLA-C2")
print(head(pat[, ..hla_geno_cols], 5))

# Germline homozygosity rate at each locus
cat("\n--- Germline HLA homozygosity (allele1 == allele2) ---\n")
for (locus in c("A","B","C")) {
  a1 <- pat[[paste0("HLA-",locus,"1")]]; a2 <- pat[[paste0("HLA-",locus,"2")]]
  valid <- !is.na(a1) & !is.na(a2) & a1!="" & a2!=""
  homoz <- sum(a1[valid]==a2[valid])
  cat(sprintf("  HLA-%s: %d/%d homozygous (%.1f%%)\n", locus, homoz, sum(valid),
              100*homoz/sum(valid)))
}

# ── 2. Mutational signatures ──────────────────────────────────────────────────
cat("\n\n========== MUTATIONAL SIGNATURES ==========\n")
sig <- fread(file.path(data_dir, "data_mutational_signatures_contribution_v2.txt"),
             header = TRUE)
cat(sprintf("Dimensions: %d rows x %d cols\n", nrow(sig), ncol(sig)))
cat(sprintf("First col: %s\n", names(sig)[1]))
cat("Signature columns (all):\n")
print(names(sig))
cat("\nFirst 3 rows, first 6 cols:\n")
print(sig[1:3, 1:min(6,ncol(sig))])

# ── 3. Arm-level CNA (chr6p critical for HLA LOH mechanism) ────────────────────
cat("\n\n========== ARM-LEVEL CNA ==========\n")
arm <- fread(file.path(data_dir, "data_armlevel_cna.txt"), header = TRUE)
cat(sprintf("Dimensions: %d rows x %d cols\n", nrow(arm), ncol(arm)))
cat(sprintf("First col: %s\n", names(arm)[1]))
cat("First column values (arm identifiers):\n")
print(head(arm[[1]], 50))
cat("\nUnique CNA values (sample of matrix):\n")
arm_vals <- unique(unlist(arm[1:min(45,nrow(arm)), 2:min(200,ncol(arm))]))
print(arm_vals[!is.na(arm_vals)])

# ── 4. Mutations file structure (for driver gene analysis) ────────────────────
cat("\n\n========== MUTATIONS (structure only) ==========\n")
mut_head <- fread(file.path(data_dir, "data_mutations.txt"), nrows = 5, header = TRUE)
cat(sprintf("Columns (%d): %s\n", ncol(mut_head), 
            paste(head(names(mut_head), 25), collapse=", ")))

# ── 5. Save patient-level survival/HLA summary for downstream use ──────────────
pat_summary <- data.frame(
  Metric = c("Total patients","OS available","OS events (Deceased)",
             "HLA genotype available","Median age","Female","Male",
             "European ancestry","Median OS months"),
  Value = c(
    nrow(pat),
    sum(!is.na(os)),
    sum(pat$OS_STATUS %in% c("1:DECEASED","DECEASED"), na.rm=TRUE),
    sum(pat$HLA_GENOTYPE_AVAILABLE %in% c("TRUE","Yes","YES",TRUE), na.rm=TRUE),
    round(median(age,na.rm=TRUE)),
    sum(pat$SEX=="Female", na.rm=TRUE),
    sum(pat$SEX=="Male", na.rm=TRUE),
    sum(grepl("EUR|European", pat$ANCESTRY_LABEL, ignore.case=TRUE), na.rm=TRUE),
    round(median(os,na.rm=TRUE),1)
  )
)
fwrite(pat_summary, file.path(out_dir, "patient_level_summary.tsv"), sep="\t")
cat("\n✓ Saved patient_level_summary.tsv\n")
cat("\n========== DEEP EXPLORATION COMPLETE ==========\n")
