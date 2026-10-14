################################################################################
# HLA_LOH02 - Script 06: Export table data for DOCX (Table 1 baseline + supp)
################################################################################
suppressMessages(library(data.table))
OUT <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/04_processed_data"
RES <- file.path(OUT,"results"); TAB <- file.path(OUT,"table_data")
dir.create(TAB, showWarnings=FALSE, recursive=TRUE)
m <- readRDS(file.path(OUT,"master_cohort.rds"))
D <- m[analysis_primary==TRUE]
D[, WGD := FACETS_WGD=="TRUE"]

pctn <- function(x) sprintf("%d (%.1f%%)", sum(x,na.rm=TRUE), 100*mean(x,na.rm=TRUE))
medi <- function(x) sprintf("%.1f (%.1f-%.1f)", median(x,na.rm=TRUE),
                            quantile(x,.25,na.rm=TRUE), quantile(x,.75,na.rm=TRUE))

# ── Table 1: baseline by HLA LOH status ────────────────────────────────────────
D[, grp := fifelse(any_HLA_LOH,"HLA LOH","HLA intact")]
mk_row <- function(label, expr_intact, expr_loh, p="") 
  data.table(Characteristic=label, `HLA intact`=expr_intact, `HLA LOH`=expr_loh, P=p)

I <- D[grp=="HLA intact"]; L <- D[grp=="HLA LOH"]
p_age  <- wilcox.test(AGE_AT_DX~grp, D)$p.value
p_tmb  <- wilcox.test(TMB_SCORE~grp, D)$p.value
p_sex  <- chisq.test(table(D$SEX, D$grp))$p.value
p_wgd  <- chisq.test(table(D$WGD, D$grp))$p.value
p_met  <- chisq.test(table(D$SAMPLE_TYPE=="Metastasis", D$grp))$p.value
p_6p   <- fisher.test(table(D$arm_6p_loss, D$grp))$p.value
fmtp <- function(p) if(p<0.001) "<0.001" else sprintf("%.3f",p)

t1 <- rbindlist(list(
  mk_row("N", format(nrow(I),big.mark=","), format(nrow(L),big.mark=",")),
  mk_row("Age at diagnosis, median (IQR)", medi(I$AGE_AT_DX), medi(L$AGE_AT_DX), fmtp(p_age)),
  mk_row("Female sex", pctn(I$SEX=="Female"), pctn(L$SEX=="Female"), fmtp(p_sex)),
  mk_row("Metastatic sample", pctn(I$SAMPLE_TYPE=="Metastasis"), pctn(L$SAMPLE_TYPE=="Metastasis"), fmtp(p_met)),
  mk_row("TMB (mut/Mb), median (IQR)", medi(I$TMB_SCORE), medi(L$TMB_SCORE), fmtp(p_tmb)),
  mk_row("TMB-high (>=10)", pctn(I$TMB_high), pctn(L$TMB_high)),
  mk_row("Whole-genome doubling", pctn(I$WGD), pctn(L$WGD), fmtp(p_wgd)),
  mk_row("6p arm loss", pctn(I$arm_6p_loss), pctn(L$arm_6p_loss), fmtp(p_6p)),
  mk_row("Germline HLA homozygosity (any)", pctn(I$germ_hom_any), pctn(L$germ_hom_any)),
  mk_row("FACETS purity, median (IQR)", medi(I$FACETS_PURITY), medi(L$FACETS_PURITY))
))
fwrite(t1, file.path(TAB,"Table1_baseline.tsv"), sep="\t")
cat("Table 1 rows:", nrow(t1), "\n")

# ── Table 2: multivariable drivers + survival (key effect sizes) ───────────────
q3 <- fread(file.path(RES,"Q3_multivariable_drivers.tsv"))
sv <- fread(file.path(RES,"Survival_multivariable.tsv"))
fwrite(q3, file.path(TAB,"Table2_drivers.tsv"), sep="\t")
fwrite(sv, file.path(TAB,"Table2_survival.tsv"), sep="\t")

# ── Supp tables ────────────────────────────────────────────────────────────────
file.copy(file.path(RES,"Q1_pancancer_atlas.tsv"), file.path(TAB,"SuppTable1_atlas.tsv"), overwrite=TRUE)
file.copy(file.path(RES,"Q2_TMB_by_cancer.tsv"),   file.path(TAB,"SuppTable2_TMB.tsv"), overwrite=TRUE)
file.copy(file.path(RES,"Q4_signatures_vs_LOH.tsv"),file.path(TAB,"SuppTable3_signatures.tsv"), overwrite=TRUE)
file.copy(file.path(RES,"Survival_by_cancer.tsv"), file.path(TAB,"SuppTable4_survival_bycancer.tsv"), overwrite=TRUE)
cat("Table data exported to", TAB, "\n")
