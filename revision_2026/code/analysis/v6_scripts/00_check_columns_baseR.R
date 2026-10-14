# Base R column name check (no dependencies)
f <- "C:/Users/Administrator/科研文件/HLA_LOH02/msk_impact_50k_2026/data_clinical_sample.txt"
cat("Reading header from:", f, "\n\n")

# Read header only (skip 4 meta lines)
x <- read.delim(f, skip = 4, nrows = 0, check.names = FALSE, stringsAsFactors = FALSE)

cat("=== Total columns:", ncol(x), "===\n\n")

# HLA-related columns
cat("=== HLA-related columns ===\n")
hla_cols <- grep("HLA", names(x), value = TRUE, ignore.case = TRUE)
for (col in hla_cols) cat("  ", col, "\n")

# Key genomic columns
cat("\n=== Key genomic columns ===\n")
key_cols <- grep("TMB|MSI|FACETS|WGD|Purity|Ploidy", names(x), value = TRUE, ignore.case = TRUE)
for (col in key_cols) cat("  ", col, "\n")

# Cancer type columns
cat("\n=== Cancer type columns ===\n")
cancer_cols <- grep("CANCER|ONCOTREE", names(x), value = TRUE, ignore.case = TRUE)
for (col in cancer_cols) cat("  ", col, "\n")

# Write full list
out_dir <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/02_data_inventory"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
out_file <- file.path(out_dir, "clinical_sample_column_names.txt")
writeLines(names(x), out_file)
cat("\n✓ Full column list saved to:", out_file, "\n")
