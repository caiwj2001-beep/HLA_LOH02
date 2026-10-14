################################################################################
# HLA_LOH02 - Script 03: Build Master Analysis Cohort
# Merges sample clinical + patient (germline HLA, ancestry, OS) + arm-level CNA
# (6p) + mutational signatures. Defines HLA LOH phenotypes & QC-passed cohort.
# Output: master_cohort.rds + master_cohort.tsv + cohort QC report
################################################################################
suppressMessages({library(data.table)})

DD  <- "C:/Users/Administrator/科研文件/HLA_LOH02/msk_impact_50k_2026"
OUT <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/04_processed_data"
LOG <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/10_logs"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

msg <- function(...) cat(sprintf(...), "\n")

# ── 1. Clinical sample ─────────────────────────────────────────────────────────
s <- fread(file.path(DD,"data_clinical_sample.txt"), skip = 4, header = TRUE,
           na.strings = c("NA",""))
msg("Sample rows: %d", nrow(s))

hla <- c("HLA_A1_LOH","HLA_A2_LOH","HLA_B1_LOH","HLA_B2_LOH","HLA_C1_LOH","HLA_C2_LOH")

# Numeric coercions
s[, TMB_SCORE     := as.numeric(TMB_SCORE)]
s[, MSI_SCORE     := as.numeric(MSI_SCORE)]
s[, FACETS_PURITY := as.numeric(FACETS_PURITY)]
s[, FACETS_PLOIDY := as.numeric(FACETS_PLOIDY)]

# ── 2. HLA LOH phenotypes ──────────────────────────────────────────────────────
# Per-locus LOH = either allele lost
s[, HLA_A_LOH := (HLA_A1_LOH=="Loss") | (HLA_A2_LOH=="Loss")]
s[, HLA_B_LOH := (HLA_B1_LOH=="Loss") | (HLA_B2_LOH=="Loss")]
s[, HLA_C_LOH := (HLA_C1_LOH=="Loss") | (HLA_C2_LOH=="Loss")]

# Evaluability: at least one allele has a non-NA call
s[, n_eval_alleles := rowSums(!is.na(.SD)), .SDcols = hla]
s[, hla_evaluable  := n_eval_alleles > 0]

# Any LOH & LOH burden (0-3 loci)
s[, any_HLA_LOH := rowSums(.SD == "Loss", na.rm = TRUE) > 0, .SDcols = hla]
s[, HLA_LOH_burden := (HLA_A_LOH %in% TRUE) + (HLA_B_LOH %in% TRUE) + (HLA_C_LOH %in% TRUE)]

# Pan-HLA LOH (all three loci lost) - strongest immune-escape phenotype
s[, pan_HLA_LOH := HLA_LOH_burden == 3 & hla_evaluable]

# TMB-high (per-sample) — pan-cancer 10 mut/Mb threshold (FDA/Marabelle)
s[, TMB_high := TMB_SCORE >= 10]
s[, log_TMB  := log10(pmax(TMB_SCORE, 0) + 0.1)]

# MSI status simplified
s[, MSI_status := fifelse(MSI_TYPE=="Instable","MSI-H",
                   fifelse(MSI_TYPE=="Stable","MSS", NA_character_))]

# ── 3. Patient-level: germline HLA, ancestry, OS ──────────────────────────────
p <- fread(file.path(DD,"data_clinical_patient.txt"), skip = 4, header = TRUE,
           na.strings = c("NA",""))
msg("Patient rows: %d", nrow(p))

# germline homozygosity per locus
for (loc in c("A","B","C")) {
  a1 <- p[[paste0("HLA-",loc,"1")]]; a2 <- p[[paste0("HLA-",loc,"2")]]
  p[[paste0("germ_hom_",loc)]] <- (!is.na(a1) & !is.na(a2) & a1==a2)
}
p[, germ_hom_any := germ_hom_A | germ_hom_B | germ_hom_C]
p[, germ_fully_het := HLA_GENOTYPE_AVAILABLE=="TRUE" & !germ_hom_A & !germ_hom_B & !germ_hom_C]
p[, OS_MONTHS := as.numeric(OS_MONTHS)]
p[, OS_event  := fifelse(OS_STATUS=="DECEASED",1L, fifelse(OS_STATUS=="LIVING",0L,NA_integer_))]
p[, AGE_AT_DX := as.numeric(AGE_AT_DX)]

pcols <- c("PATIENT_ID","SEX","ANCESTRY_LABEL","HLA_GENOTYPE_AVAILABLE","AGE_AT_DX",
           "OS_MONTHS","OS_event","germ_hom_A","germ_hom_B","germ_hom_C",
           "germ_hom_any","germ_fully_het")
m <- merge(s, p[, ..pcols], by = "PATIENT_ID", all.x = TRUE)
msg("After patient merge: %d rows", nrow(m))

# ── 4. Arm-level CNA: extract 6p status (HLA LOH mechanism) ────────────────────
arm <- fread(file.path(DD,"data_armlevel_cna.txt"), header = TRUE)
arm_id_col <- names(arm)[1]
get_arm <- function(tag) {
  row <- arm[get(arm_id_col)==tag]
  if (nrow(row)==0) return(NULL)
  v <- unlist(row[1, -1, with=FALSE]); data.table(SAMPLE_ID=names(v), val=as.character(v))
}
a6p <- get_arm("6p_status")
if (!is.null(a6p)) {
  setnames(a6p, "val", "arm_6p")
  m <- merge(m, a6p, by="SAMPLE_ID", all.x=TRUE)
  m[, arm_6p_loss := arm_6p=="Loss"]
  msg("6p arm merged: %d with 6p call | 6p Loss=%d",
      sum(!is.na(m$arm_6p)), sum(m$arm_6p_loss, na.rm=TRUE))
}
a9p <- get_arm("9p_status")   # 9p21 IFN cluster — comparator locus
if (!is.null(a9p)) {
  setnames(a9p, "val", "arm_9p"); m <- merge(m, a9p, by="SAMPLE_ID", all.x=TRUE)
  m[, arm_9p_loss := arm_9p=="Loss"]
}

# ── 5. Mutational signatures: dominant signature + APOBEC/HRD flags ────────────
sig <- fread(file.path(DD,"data_mutational_signatures_contribution_v2.txt"), header = TRUE)
sig_names <- sig$NAME
sig_mat <- as.matrix(sig[, 5:ncol(sig)])          # rows=signatures, cols=samples
rownames(sig_mat) <- sig_names
sig_t <- t(sig_mat)                               # rows=samples
sig_dt <- data.table(SAMPLE_ID=rownames(sig_t), sig_t, check.names=TRUE)

# check.names=TRUE mangled signature names in sig_dt; map raw NAME -> mangled col
mangled <- make.names(sig_names)               # aligns 1:1 with sig_names order
find_sig <- function(pattern) mangled[grepl(pattern, sig_names, ignore.case=TRUE)]
apobec_cols <- find_sig("APOBEC")
hrd_cols    <- find_sig("\\(HRD\\)")           # only the true HRD signature, not Unknown
mmr_cols    <- find_sig("\\(MMR\\)")
aging_cols  <- find_sig("Aging")
smoke_cols  <- find_sig("Smoking")
uv_cols     <- find_sig("\\(UV\\)")
msg("Signature groups -> APOBEC:%s | HRD:%s | MMR:%s",
    paste(apobec_cols,collapse=","), paste(hrd_cols,collapse=","),
    paste(mmr_cols,collapse=","))

sumcols <- function(dt, cols) { cols <- cols[cols %in% names(dt)]
  if (!length(cols)) return(rep(NA_real_, nrow(dt))); rowSums(dt[, ..cols], na.rm=TRUE) }
sig_dt[, sig_APOBEC := sumcols(sig_dt, apobec_cols)]
sig_dt[, sig_HRD    := sumcols(sig_dt, hrd_cols)]
sig_dt[, sig_MMR    := sumcols(sig_dt, mmr_cols)]
sig_dt[, sig_aging  := sumcols(sig_dt, aging_cols)]
sig_dt[, sig_smoke  := sumcols(sig_dt, smoke_cols)]
sig_dt[, sig_UV     := sumcols(sig_dt, uv_cols)]

# dominant signature label per sample (use mangled cols, relabel with raw names)
sig_only <- as.matrix(sig_dt[, ..mangled][, lapply(.SD, as.numeric)])
sig_only[is.na(sig_only)] <- 0
sig_dt[, dominant_sig := sig_names[max.col(sig_only, ties.method="first")]]

keep_sig <- c("SAMPLE_ID","sig_APOBEC","sig_HRD","sig_MMR","sig_aging","sig_smoke","sig_UV","dominant_sig")
m <- merge(m, sig_dt[, ..keep_sig], by="SAMPLE_ID", all.x=TRUE)
m[, APOBEC_dominant := sig_APOBEC > 0.5]
m[, sig_available := !is.na(sig_APOBEC)]
msg("Signatures merged: %d samples with signature data", sum(m$sig_available, na.rm=TRUE))

# ── 6. Analysis flags ──────────────────────────────────────────────────────────
m[, FACETS_pass := FACETS_QC=="Pass"]
# Primary analysis cohort: HLA evaluable + FACETS pass
m[, analysis_primary := hla_evaluable & FACETS_pass]
# For cross-sample independence: one sample per patient (prefer primary tumor, then highest purity)
m[, stype_rank := match(SAMPLE_TYPE, c("Primary","Metastasis","Local Recurrence","Unknown"))]
m[is.na(stype_rank), stype_rank := 99L]
setorder(m, PATIENT_ID, -analysis_primary, stype_rank, -FACETS_PURITY)
m[, one_per_patient := seq_len(.N)==1, by=PATIENT_ID]

msg("\n=== COHORT FLAGS ===")
msg("HLA evaluable: %d", sum(m$hla_evaluable, na.rm=TRUE))
msg("FACETS pass:   %d", sum(m$FACETS_pass, na.rm=TRUE))
msg("Primary analysis (evaluable & QC pass): %d", sum(m$analysis_primary, na.rm=TRUE))
msg("One-per-patient & analysis_primary: %d",
    sum(m$one_per_patient & m$analysis_primary, na.rm=TRUE))
msg("Any HLA LOH (primary cohort): %d (%.1f%%)",
    sum(m$any_HLA_LOH & m$analysis_primary, na.rm=TRUE),
    100*sum(m$any_HLA_LOH & m$analysis_primary,na.rm=TRUE)/sum(m$analysis_primary,na.rm=TRUE))

# ── 7. Save ────────────────────────────────────────────────────────────────────
saveRDS(m, file.path(OUT,"master_cohort.rds"))
fwrite(m, file.path(OUT,"master_cohort.tsv"), sep="\t")
msg("\nSaved master_cohort.rds/.tsv (%d rows x %d cols)", nrow(m), ncol(m))

# QC report
qc <- data.table(
  Metric = c("Total samples","HLA evaluable","FACETS pass","Primary analysis cohort",
             "One-per-patient primary","Any HLA LOH (primary)","pan-HLA LOH (primary)",
             "6p Loss (primary)","APOBEC dominant (primary)","MSI-H (primary)",
             "TMB-high (primary)","OS available (primary)"),
  N = c(nrow(m), sum(m$hla_evaluable,na.rm=T), sum(m$FACETS_pass,na.rm=T),
        sum(m$analysis_primary,na.rm=T),
        sum(m$one_per_patient & m$analysis_primary,na.rm=T),
        sum(m$any_HLA_LOH & m$analysis_primary,na.rm=T),
        sum(m$pan_HLA_LOH & m$analysis_primary,na.rm=T),
        sum(m$arm_6p_loss & m$analysis_primary,na.rm=T),
        sum(m$APOBEC_dominant & m$analysis_primary,na.rm=T),
        sum(m$MSI_status=="MSI-H" & m$analysis_primary,na.rm=T),
        sum(m$TMB_high & m$analysis_primary,na.rm=T),
        sum(!is.na(m$OS_MONTHS) & m$analysis_primary,na.rm=T))
)
fwrite(qc, file.path(OUT,"cohort_qc_report.tsv"), sep="\t")
print(qc)
msg("\n=== MASTER COHORT BUILD COMPLETE ===")
