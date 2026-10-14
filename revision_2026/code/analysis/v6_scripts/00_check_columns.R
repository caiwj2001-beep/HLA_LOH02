# Quick column name check for data_clinical_sample.txt
library(data.table)

f <- "C:/Users/Administrator/科研文件/HLA_LOH02/msk_impact_50k_2026/data_clinical_sample.txt"
cat("Reading header from:", f, "\n")

# Read just the header (skip 4 meta lines, read 0 data rows)
x <- fread(f, skip = 4, nrows = 0)

cat("\n=== Column Names (first 30) ===\n")
print(head(names(x), 30))

cat("\n=== HLA-related columns ===\n")
hla_cols <- grep("HLA", names(x), value = TRUE, ignore.case = TRUE)
print(hla_cols)

# Write full column list
out_file <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/02_data_inventory/clinical_sample_column_names.txt"
dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
writeLines(names(x), out_file)
cat("\n✓ Full column list saved to:", out_file, "\n")
