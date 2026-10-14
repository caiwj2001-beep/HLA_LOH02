################################################################################
# HLA_LOH02 - Script 04: Core Statistical Analysis (Q1-Q4 + Survival)
# Uses master_cohort.rds. Primary cohort = analysis_primary (29,799).
# All p-values BH-FDR corrected where multiple testing applies.
# Outputs: results/*.tsv for tables & figures.
################################################################################
suppressMessages({library(data.table); library(survival)})

OUT <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/04_processed_data"
RES <- file.path(OUT, "results"); dir.create(RES, showWarnings = FALSE, recursive = TRUE)
set.seed(42)
msg <- function(...) cat(sprintf(...), "\n")

m <- readRDS(file.path(OUT,"master_cohort.rds"))
D <- m[analysis_primary == TRUE]                 # primary cohort
msg("Primary cohort N = %d", nrow(D))
wilson <- function(x,n){ if(n==0) return(c(NA,NA,NA)); p<-x/n; z<-1.96
  d<-1+z^2/n; c(p, (p+z^2/(2*n)-z*sqrt(p*(1-p)/n+z^2/(4*n^2)))/d,
                   (p+z^2/(2*n)+z*sqrt(p*(1-p)/n+z^2/(4*n^2)))/d) }

################################################################################
# Q1. PAN-CANCER HLA LOH ATLAS
################################################################################
msg("\n===== Q1: Pan-cancer atlas =====")
q1 <- D[, {
  n <- .N
  x <- sum(any_HLA_LOH, na.rm=TRUE)
  ci <- wilson(x, n)
  .(N=n, n_LOH=x, freq=ci[1], lo=ci[2], hi=ci[3],
    n_panHLA=sum(pan_HLA_LOH,na.rm=TRUE), freq_pan=mean(pan_HLA_LOH,na.rm=TRUE),
    freq_A=mean(HLA_A_LOH,na.rm=TRUE), freq_B=mean(HLA_B_LOH,na.rm=TRUE),
    freq_C=mean(HLA_C_LOH,na.rm=TRUE),
    med_TMB=median(TMB_SCORE,na.rm=TRUE), med_purity=median(FACETS_PURITY,na.rm=TRUE),
    pct_WGD=mean(FACETS_WGD=="TRUE",na.rm=TRUE))
}, by=CANCER_TYPE][order(-freq)]
q1 <- q1[N>=100]
fwrite(q1, file.path(RES,"Q1_pancancer_atlas.tsv"), sep="\t")
msg("Cancer types (N>=100): %d | LOH freq range %.1f%%-%.1f%%",
    nrow(q1), 100*min(q1$freq), 100*max(q1$freq))
print(q1[, .(CANCER_TYPE,N,n_LOH,freq=round(100*freq,1),
             lo=round(100*lo,1),hi=round(100*hi,1))][1:15])

# Overall pan-cancer freq + heterogeneity test across cancer types
tab <- D[!is.na(any_HLA_LOH), .(loh=sum(any_HLA_LOH), n=.N), by=CANCER_TYPE][n>=100]
chisq_ct <- chisq.test(as.matrix(tab[,.(loh, n-loh)]))
msg("Cross-cancer heterogeneity chi-sq p = %.3e", chisq_ct$p.value)
overall_ci <- wilson(sum(D$any_HLA_LOH,na.rm=TRUE), sum(!is.na(D$any_HLA_LOH)))
msg("Overall pan-cancer HLA LOH: %.1f%% (95%% CI %.1f-%.1f)",
    100*overall_ci[1],100*overall_ci[2],100*overall_ci[3])

# Primary vs Metastasis (paired at cohort level)
pm <- D[SAMPLE_TYPE %in% c("Primary","Metastasis")]
pm_test <- glm(any_HLA_LOH ~ SAMPLE_TYPE + CANCER_TYPE, data=pm, family=binomial)
pm_coef <- summary(pm_test)$coefficients["SAMPLE_TYPEPrimary",]
msg("Primary vs Met (adj cancer): OR=%.2f p=%.3e",
    exp(pm_coef[1]), pm_coef[4])
q1_pm <- D[, .(freq_LOH=mean(any_HLA_LOH,na.rm=TRUE), N=.N), by=.(CANCER_TYPE, SAMPLE_TYPE)]
fwrite(q1_pm, file.path(RES,"Q1_primary_vs_met.tsv"), sep="\t")

################################################################################
# Q2. HLA LOH vs TMB / genomic immune features
################################################################################
msg("\n===== Q2: HLA LOH vs TMB =====")
# TMB by LOH status (Wilcoxon, overall)
w <- wilcox.test(TMB_SCORE ~ any_HLA_LOH, data=D)
msg("TMB by HLA LOH (Wilcoxon) p=%.3e | median LOH=%.2f vs noLOH=%.2f",
    w$p.value, median(D[any_HLA_LOH==TRUE]$TMB_SCORE,na.rm=T),
    median(D[any_HLA_LOH==FALSE]$TMB_SCORE,na.rm=T))

# Adjusted logistic: does higher TMB associate with HLA LOH?
D[, cancer_f := factor(CANCER_TYPE)]
D[, panel_f  := factor(GENE_PANEL)]
fit_tmb <- glm(any_HLA_LOH ~ log_TMB + FACETS_PURITY + panel_f + cancer_f,
               data=D, family=binomial)
ct <- summary(fit_tmb)$coefficients["log_TMB",]
msg("Adjusted OR per log10-TMB: %.2f (p=%.3e)", exp(ct[1]), ct[4])

# Per-cancer TMB association (FDR)
q2 <- D[, {
  if (.N>=100 && length(unique(any_HLA_LOH))==2) {
    wt <- suppressWarnings(wilcox.test(TMB_SCORE ~ any_HLA_LOH))
    .(N=.N, med_TMB_LOH=median(TMB_SCORE[any_HLA_LOH==TRUE],na.rm=T),
      med_TMB_noLOH=median(TMB_SCORE[any_HLA_LOH==FALSE],na.rm=T), p=wt$p.value)
  } else .(N=.N, med_TMB_LOH=NA_real_, med_TMB_noLOH=NA_real_, p=NA_real_)
}, by=CANCER_TYPE][!is.na(p)]
q2[, FDR := p.adjust(p, "BH")]
q2 <- q2[order(FDR)]
fwrite(q2, file.path(RES,"Q2_TMB_by_cancer.tsv"), sep="\t")
msg("Per-cancer TMB assoc: %d significant (FDR<0.05)", sum(q2$FDR<0.05))

# WGD and TMB-high association with LOH (contingency)
for (v in c("TMB_high")) {
  tt <- table(D[[v]], D$any_HLA_LOH)
  ft <- fisher.test(tt)
  msg("%s vs HLA LOH: OR=%.2f p=%.3e", v, ft$estimate, ft$p.value)
}

################################################################################
# Q3. MECHANISTIC DRIVERS: 6p Loss, WGD, germline homozygosity
################################################################################
msg("\n===== Q3: Mechanistic drivers =====")
# 6p loss <-> HLA LOH
t6p <- table(D$arm_6p_loss, D$any_HLA_LOH)
f6p <- fisher.test(t6p)
msg("6p Loss vs HLA LOH: OR=%.2f (95%%CI %.2f-%.2f) p=%.3e",
    f6p$estimate, f6p$conf.int[1], f6p$conf.int[2], f6p$p.value)

# WGD <-> HLA LOH
D[, WGD := FACETS_WGD=="TRUE"]
twgd <- table(D$WGD, D$any_HLA_LOH); fwgd <- fisher.test(twgd)
msg("WGD vs HLA LOH: OR=%.2f p=%.3e", fwgd$estimate, fwgd$p.value)

# germline homozygosity <-> somatic LOH (at matched locus, patient-level)
# HLA-A: among germline-het, LOH more possible; test any germ hom vs LOH burden
gh <- D[!is.na(germ_hom_any)]
tgh <- table(gh$germ_hom_any, gh$any_HLA_LOH); fgh <- fisher.test(tgh)
msg("Germline homozygosity(any) vs somatic HLA LOH: OR=%.2f p=%.3e",
    fgh$estimate, fgh$p.value)

# Multivariable model — HLA lies on 6p21.3, so 6p arm loss is the PROXIMAL
# cytogenetic mechanism (near-tautological). We therefore fit two models:
#  (A) DISTAL drivers of HLA LOH, excluding 6p (upstream biology):
fit_distal <- glm(any_HLA_LOH ~ WGD + germ_hom_any + log_TMB +
                    FACETS_PURITY + panel_f + cancer_f, data=D, family=binomial)
sd <- summary(fit_distal)$coefficients
distal <- c("WGDTRUE","germ_hom_anyTRUE","log_TMB")
q3 <- data.table(model="distal", term=distal,
  OR=exp(sd[distal,1]), lo=exp(sd[distal,1]-1.96*sd[distal,2]),
  hi=exp(sd[distal,1]+1.96*sd[distal,2]), p=sd[distal,4])

#  (B) PROXIMAL: 6p loss alone (bivariable, adjusted for cancer only)
fit_6p <- glm(any_HLA_LOH ~ arm_6p_loss + cancer_f, data=D, family=binomial)
s6 <- summary(fit_6p)$coefficients["arm_6p_lossTRUE",]
q3 <- rbind(q3, data.table(model="proximal", term="arm_6p_loss",
  OR=exp(s6[1]), lo=exp(s6[1]-1.96*s6[2]), hi=exp(s6[1]+1.96*s6[2]), p=s6[4]))
fwrite(q3, file.path(RES,"Q3_multivariable_drivers.tsv"), sep="\t")
print(q3)

# Mediation check: WGD effect on HLA LOH should attenuate when 6p is added
wgd_uni  <- exp(coef(glm(any_HLA_LOH ~ WGD + cancer_f, data=D, family=binomial))["WGDTRUE"])
wgd_adj6 <- exp(coef(glm(any_HLA_LOH ~ WGD + arm_6p_loss + cancer_f, data=D, family=binomial))["WGDTRUE"])
msg("WGD->HLA LOH OR: %.2f (alone) -> %.2f (adj 6p)  [mediation via 6p]",
    wgd_uni, wgd_adj6)
# 6p-independent HLA LOH: focal / copy-neutral fraction
ci_ind <- D[any_HLA_LOH==TRUE & !is.na(arm_6p_loss)]
msg("HLA LOH that is 6p-arm-INDEPENDENT (focal/CN-LOH): %.1f%%",
    100*mean(!ci_ind$arm_6p_loss))

# 6p-loss vs HLA-LOH concordance metric
conc <- D[!is.na(arm_6p_loss) & !is.na(any_HLA_LOH)]
msg("Among HLA LOH+: %.1f%% also have 6p arm Loss",
    100*mean(conc[any_HLA_LOH==TRUE]$arm_6p_loss))
msg("Among 6p Loss+: %.1f%% have HLA LOH",
    100*mean(conc[arm_6p_loss==TRUE]$any_HLA_LOH))

################################################################################
# Q4. MUTATIONAL PROCESSES: APOBEC / HRD / MMR signatures
################################################################################
msg("\n===== Q4: Mutational processes =====")
S <- D[sig_available==TRUE]
msg("With signature data: %d", nrow(S))
q4_list <- list()
for (sg in c("sig_APOBEC","sig_HRD","sig_MMR","sig_smoke","sig_UV","sig_aging")) {
  wt <- suppressWarnings(wilcox.test(S[[sg]] ~ S$any_HLA_LOH))
  q4_list[[sg]] <- data.table(signature=sg,
    med_LOH=median(S[[sg]][S$any_HLA_LOH==TRUE],na.rm=T),
    med_noLOH=median(S[[sg]][S$any_HLA_LOH==FALSE],na.rm=T),
    mean_LOH=mean(S[[sg]][S$any_HLA_LOH==TRUE],na.rm=T),
    mean_noLOH=mean(S[[sg]][S$any_HLA_LOH==FALSE],na.rm=T), p=wt$p.value)
}
q4 <- rbindlist(q4_list); q4[, FDR := p.adjust(p,"BH")]
fwrite(q4, file.path(RES,"Q4_signatures_vs_LOH.tsv"), sep="\t")
print(q4)

# APOBEC-dominant enrichment for HLA LOH (adjusted)
fit_apo <- glm(any_HLA_LOH ~ sig_APOBEC + log_TMB + WGD + panel_f + cancer_f,
               data=S, family=binomial)
ca <- summary(fit_apo)$coefficients["sig_APOBEC",]
msg("APOBEC contribution -> HLA LOH (adj): OR per unit=%.2f p=%.3e",
    exp(ca[1]), ca[4])

################################################################################
# SURVIVAL: HLA LOH and OS
################################################################################
msg("\n===== Survival: HLA LOH & OS =====")
Sv <- D[!is.na(OS_MONTHS) & !is.na(OS_event) & OS_MONTHS>0]
msg("Survival cohort N=%d, events=%d", nrow(Sv), sum(Sv$OS_event))
Sv[, ancestry_f := factor(ANCESTRY_LABEL)]

# Univariable
cox_uni <- coxph(Surv(OS_MONTHS,OS_event) ~ any_HLA_LOH, data=Sv)
hr_uni <- summary(cox_uni)$coefficients
msg("Univariable HLA LOH HR=%.2f (p=%.3e)", exp(hr_uni[1]), hr_uni[5])

# Multivariable
cox_mv <- coxph(Surv(OS_MONTHS,OS_event) ~ any_HLA_LOH + AGE_AT_DX + SEX +
                  log_TMB + WGD + cancer_f, data=Sv)
sm_cox <- summary(cox_mv)$coefficients
q_surv <- data.table(term=rownames(sm_cox), HR=exp(sm_cox[,1]),
  lo=exp(sm_cox[,1]-1.96*sm_cox[,3]), hi=exp(sm_cox[,1]+1.96*sm_cox[,3]),
  p=sm_cox[,5])
fwrite(q_surv, file.path(RES,"Survival_multivariable.tsv"), sep="\t")
msg("Adjusted HLA LOH HR=%.2f (95%%CI %.2f-%.2f) p=%.3e",
    q_surv[term=="any_HLA_LOHTRUE"]$HR, q_surv[term=="any_HLA_LOHTRUE"]$lo,
    q_surv[term=="any_HLA_LOHTRUE"]$hi, q_surv[term=="any_HLA_LOHTRUE"]$p)

# Per-cancer HR (FDR)
surv_ct <- Sv[, {
  if (.N>=150 && sum(OS_event)>=20 && length(unique(any_HLA_LOH))==2) {
    cx <- tryCatch(coxph(Surv(OS_MONTHS,OS_event) ~ any_HLA_LOH + AGE_AT_DX + SEX + log_TMB),
                   error=function(e) NULL)
    if (!is.null(cx)) { s<-summary(cx)$coefficients
      .(N=.N, events=sum(OS_event), HR=exp(s["any_HLA_LOHTRUE",1]),
        lo=exp(s["any_HLA_LOHTRUE",1]-1.96*s["any_HLA_LOHTRUE",3]),
        hi=exp(s["any_HLA_LOHTRUE",1]+1.96*s["any_HLA_LOHTRUE",3]),
        p=s["any_HLA_LOHTRUE",5])
    } else .(N=.N,events=sum(OS_event),HR=NA_real_,lo=NA_real_,hi=NA_real_,p=NA_real_)
  } else .(N=.N,events=sum(OS_event),HR=NA_real_,lo=NA_real_,hi=NA_real_,p=NA_real_)
}, by=CANCER_TYPE][!is.na(HR)]
surv_ct[, FDR := p.adjust(p,"BH")][order(HR)]
fwrite(surv_ct, file.path(RES,"Survival_by_cancer.tsv"), sep="\t")
msg("Per-cancer survival: %d types, %d with FDR<0.05", nrow(surv_ct), sum(surv_ct$FDR<0.05,na.rm=T))
print(surv_ct[order(HR)])

# Save KM data (LOH burden strata) for figure
km_dat <- Sv[, .(OS_MONTHS, OS_event, any_HLA_LOH, HLA_LOH_burden, CANCER_TYPE)]
fwrite(km_dat, file.path(RES,"km_data.tsv"), sep="\t")

saveRDS(list(q1=q1,q2=q2,q3=q3,q4=q4,surv=q_surv,surv_ct=surv_ct,
             overall_ci=overall_ci, f6p=f6p, fwgd=fwgd, fapo=ca),
        file.path(RES,"analysis_results.rds"))
msg("\n=== CORE ANALYSIS COMPLETE ===")
