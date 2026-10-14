################################################################################
# HLA_LOH02 Project - Data Inventory Script
# Purpose: Systematic exploration of MSK-IMPACT 50K dataset structure
# Output: Data dictionary, sample counts, HLA LOH definitions, QC metrics
# Date: 2026-01-08
################################################################################

# ── Setup ─────────────────────────────────────────────────────────────────────
library(data.table)
library(writexl)

# Paths
data_dir <- "C:/Users/Administrator/科研文件/HLA_LOH02/msk_impact_50k_2026"
out_dir <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/02_data_inventory"
log_dir <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/10_logs"

# Create output directory
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(log_dir, showWarnings = FALSE, recursive = TRUE)

# ── 1. File Inventory ──────────────────────────────────────────────────────────
cat("\n=== MSK-IMPACT 50K Data Inventory ===\n")

files <- c(
  "data_clinical_sample.txt",
  "data_clinical_patient.txt",
  "data_hla_loh.txt",
  "data_mutations.txt",
  "data_cna.txt",
  "data_armlevel_cna.txt",
  "data_CNA.ascna.txt",
  "data_cna_hg19.seg",
  "data_mutational_signatures_contribution_v2.txt",
  "data_sv.txt",
  "data_gene_panel_matrix.txt",
  "meta_study.txt",
  "meta_clinical_sample.txt",
  "meta_hla_loh.txt"
)

file_inventory <- data.frame(
  File = files,
  Exists = file.exists(file.path(data_dir, files)),
  Size_MB = sapply(files, function(f) {
    fp <- file.path(data_dir, f)
    if (file.exists(fp)) round(file.size(fp) / 1024^2, 2) else NA
  }),
  stringsAsFactors = FALSE
)

print(file_inventory)

# ── 2. Read Core Clinical Data ────────────────────────────────────────────────
cat("\n=== Reading Clinical Sample Data ===\n")
clin_sample <- fread(file.path(data_dir, "data_clinical_sample.txt"), 
                     skip = 4, header = TRUE)
cat(sprintf("  Total samples: %d\n", nrow(clin_sample)))
cat(sprintf("  Total columns: %d\n", ncol(clin_sample)))

# Check column names
cat("\n  Key columns present:\n")
key_cols <- c("SAMPLE_ID", "PATIENT_ID", "CANCER_TYPE", "CANCER_TYPE_DETAILED",
              "ONCOTREE_CODE", "SAMPLE_TYPE", "PRIMARY_SITE", "METASTATIC_SITE",
              "TMB_SCORE", "MSI_SCORE", "MSI_TYPE", "FACETS_QC", 
              "FACETS_PURITY", "FACETS_PLOIDY", "FACETS_WGD",
              "HLA_A1_LOH", "HLA_A2_LOH", "HLA_B1_LOH", 
              "HLA_B2_LOH", "HLA_C1_LOH", "HLA_C2_LOH")
for (col in key_cols) {
  cat(sprintf("    %s: %s\n", col, ifelse(col %in% names(clin_sample), "✓", "✗")))
}

# Patient-level data
cat("\n=== Reading Clinical Patient Data ===\n")
clin_patient <- fread(file.path(data_dir, "data_clinical_patient.txt"),
                      skip = 4, header = TRUE)
cat(sprintf("  Total patients: %d\n", nrow(clin_patient)))
cat(sprintf("  Columns: %s\n", paste(names(clin_patient), collapse = ", ")))

# Check for survival/treatment data
survival_cols <- c("OS_STATUS", "OS_MONTHS", "PFS_STATUS", "PFS_MONTHS", 
                   "TREATMENT", "ICI_TREATMENT", "ICI_RESPONSE")
cat("\n  Survival/Treatment columns:\n")
for (col in survival_cols) {
  cat(sprintf("    %s: %s\n", col, ifelse(col %in% names(clin_patient), "✓", "✗")))
}

# ── 3. HLA LOH Matrix Structure ───────────────────────────────────────────────
cat("\n=== HLA LOH Matrix Structure ===\n")
hla_loh <- fread(file.path(data_dir, "data_hla_loh.txt"), nrows = 50)
cat(sprintf("  Matrix dimensions (first 50 rows): %d rows x %d columns\n", 
            nrow(hla_loh), ncol(hla_loh)))
cat(sprintf("  First two columns: %s, %s\n", names(hla_loh)[1], names(hla_loh)[2]))
cat(sprintf("  Sample columns start at: %s\n", names(hla_loh)[3]))

# Unique HLA genes/entities
cat(sprintf("\n  Unique HLA entities: %d\n", length(unique(hla_loh[[2]]))))
cat("  First 10 entities:\n")
print(head(unique(hla_loh[[2]]), 10))

# Check HLA LOH value encoding
hla_values <- unique(unlist(hla_loh[, 3:ncol(hla_loh)]))
cat(sprintf("\n  Unique HLA LOH values: %s\n", 
            paste(hla_values[!is.na(hla_values)], collapse = ", ")))

# ── 4. HLA LOH in Clinical Data ───────────────────────────────────────────────
cat("\n=== HLA LOH Status in Clinical Sample Data ===\n")
hla_cols <- c("HLA_A1_LOH", "HLA_A2_LOH", "HLA_B1_LOH", 
              "HLA_B2_LOH", "HLA_C1_LOH", "HLA_C2_LOH")

for (col in hla_cols) {
  if (col %in% names(clin_sample)) {
    vals <- table(clin_sample[[col]], useNA = "ifany")
    cat(sprintf("\n  %s:\n", col))
    print(vals)
  }
}

# Define evaluable samples
clin_sample[, hla_evaluable := rowSums(!is.na(.SD) & .SD != ""), 
            .SDcols = hla_cols]
cat(sprintf("\n  Samples with ≥1 evaluable HLA allele: %d (%.1f%%)\n",
            sum(clin_sample$hla_evaluable > 0),
            100 * mean(clin_sample$hla_evaluable > 0)))

# Define any HLA LOH
hla_loh_cols_present <- hla_cols[hla_cols %in% names(clin_sample)]
if (length(hla_loh_cols_present) > 0) {
  clin_sample[, any_hla_loh := rowSums(.SD == "Loss", na.rm = TRUE) > 0,
              .SDcols = hla_loh_cols_present]
  cat(sprintf("  Samples with any HLA LOH: %d (%.1f%% of evaluable)\n",
              sum(clin_sample$any_hla_loh, na.rm = TRUE),
              100 * sum(clin_sample$any_hla_loh, na.rm = TRUE) / 
                sum(clin_sample$hla_evaluable > 0)))
}

# ── 5. Cancer Type Distribution ───────────────────────────────────────────────
cat("\n=== Cancer Type Distribution (Top 20) ===\n")
cancer_counts <- clin_sample[, .N, by = CANCER_TYPE][order(-N)]
print(head(cancer_counts, 20))

cat("\n=== Detailed Cancer Types (Top 20) ===\n")
detailed_counts <- clin_sample[, .N, by = CANCER_TYPE_DETAILED][order(-N)]
print(head(detailed_counts, 20))

# Sample type
cat("\n=== Sample Type Distribution ===\n")
print(table(clin_sample$SAMPLE_TYPE, useNA = "ifany"))

# ── 6. TMB, MSI, FACETS QC ─────────────────────────────────────────────────────
cat("\n=== Genomic Features Summary ===\n")

# TMB
cat("\n  TMB Score:\n")
cat(sprintf("    Available: %d (%.1f%%)\n", 
            sum(!is.na(clin_sample$TMB_SCORE)),
            100 * mean(!is.na(clin_sample$TMB_SCORE))))
if (sum(!is.na(clin_sample$TMB_SCORE)) > 0) {
  cat(sprintf("    Median: %.2f | Mean: %.2f | Range: %.2f - %.2f\n",
              median(clin_sample$TMB_SCORE, na.rm = TRUE),
              mean(clin_sample$TMB_SCORE, na.rm = TRUE),
              min(clin_sample$TMB_SCORE, na.rm = TRUE),
              max(clin_sample$TMB_SCORE, na.rm = TRUE)))
}

# MSI
cat("\n  MSI Type:\n")
print(table(clin_sample$MSI_TYPE, useNA = "ifany"))

# FACETS QC
cat("\n  FACETS QC:\n")
print(table(clin_sample$FACETS_QC, useNA = "ifany"))

# Purity
cat("\n  FACETS Purity:\n")
cat(sprintf("    Available: %d (%.1f%%)\n",
            sum(!is.na(clin_sample$FACETS_PURITY)),
            100 * mean(!is.na(clin_sample$FACETS_PURITY))))
if (sum(!is.na(clin_sample$FACETS_PURITY)) > 0) {
  cat(sprintf("    Median: %.2f | Mean: %.2f\n",
              median(clin_sample$FACETS_PURITY, na.rm = TRUE),
              mean(clin_sample$FACETS_PURITY, na.rm = TRUE)))
}

# WGD
cat("\n  Whole Genome Doubling:\n")
print(table(clin_sample$FACETS_WGD, useNA = "ifany"))

# ── 7. Multiple Samples Per Patient ───────────────────────────────────────────
cat("\n=== Sample-Patient Relationship ===\n")
samples_per_patient <- clin_sample[, .N, by = PATIENT_ID]
cat(sprintf("  Unique patients: %d\n", nrow(samples_per_patient)))
cat(sprintf("  Samples per patient distribution:\n"))
print(table(samples_per_patient$N))

multi_sample_patients <- samples_per_patient[N > 1]
cat(sprintf("\n  Patients with >1 sample: %d (%.1f%%)\n",
            nrow(multi_sample_patients),
            100 * nrow(multi_sample_patients) / nrow(samples_per_patient)))

# ── 8. Gene Panel Coverage ─────────────────────────────────────────────────────
cat("\n=== Gene Panel Distribution ===\n")
print(table(clin_sample$GENE_PANEL, useNA = "ifany"))

# ── 9. Export Data Inventory ──────────────────────────────────────────────────
cat("\n=== Exporting Data Inventory ===\n")

# Prepare summary tables
summary_list <- list(
  File_Inventory = file_inventory,
  Sample_Summary = data.frame(
    Metric = c("Total samples", "Total patients", "Samples per patient (median)",
               "Evaluable HLA LOH samples", "Any HLA LOH", 
               "TMB available", "MSI available", "FACETS QC Pass",
               "Primary samples", "Metastatic samples"),
    Value = c(
      nrow(clin_sample),
      nrow(clin_patient),
      median(samples_per_patient$N),
      sum(clin_sample$hla_evaluable > 0),
      sum(clin_sample$any_hla_loh, na.rm = TRUE),
      sum(!is.na(clin_sample$TMB_SCORE)),
      sum(!is.na(clin_sample$MSI_TYPE)),
      sum(clin_sample$FACETS_QC == "Pass", na.rm = TRUE),
      sum(clin_sample$SAMPLE_TYPE == "Primary", na.rm = TRUE),
      sum(clin_sample$SAMPLE_TYPE == "Metastasis", na.rm = TRUE)
    )
  ),
  Cancer_Type_Top20 = head(cancer_counts, 20),
  HLA_LOH_Encoding = data.frame(
    Column = hla_cols[hla_cols %in% names(clin_sample)],
    N_Loss = sapply(hla_cols[hla_cols %in% names(clin_sample)], 
                    function(x) sum(clin_sample[[x]] == "Loss", na.rm = TRUE)),
    N_Unchanged = sapply(hla_cols[hla_cols %in% names(clin_sample)],
                         function(x) sum(clin_sample[[x]] == "Unchanged", na.rm = TRUE)),
    N_NA = sapply(hla_cols[hla_cols %in% names(clin_sample)],
                  function(x) sum(is.na(clin_sample[[x]]) | clin_sample[[x]] == ""))
  )
)

# Export to Excel
write_xlsx(summary_list, file.path(out_dir, "data_inventory.xlsx"))
cat(sprintf("  ✓ Saved: %s\n", file.path(out_dir, "data_inventory.xlsx")))

# Export HLA LOH QC summary
hla_qc <- clin_sample[, .(
  N_samples = .N,
  N_evaluable = sum(hla_evaluable > 0),
  N_any_LOH = sum(any_hla_loh, na.rm = TRUE),
  Pct_LOH = 100 * sum(any_hla_loh, na.rm = TRUE) / sum(hla_evaluable > 0)
), by = CANCER_TYPE][order(-N_samples)]

fwrite(hla_qc, file.path(out_dir, "hla_loh_qc_summary.tsv"), sep = "\t")
cat(sprintf("  ✓ Saved: %s\n", file.path(out_dir, "hla_loh_qc_summary.tsv")))

# ── 10. Session Info ───────────────────────────────────────────────────────────
sink(file.path(log_dir, "sessionInfo_inventory.txt"))
cat("=== R Session Info ===\n")
cat(sprintf("Date: %s\n", Sys.time()))
cat(sprintf("R version: %s\n", R.version.string))
cat("\nLoaded packages:\n")
print(sessionInfo())
sink()

cat("\n=== Data Inventory Complete ===\n")
cat(sprintf("  Output directory: %s\n", out_dir))
cat(sprintf("  Log directory: %s\n", log_dir))
