################################################################################
# HLA_LOH02 - Script 13: Sensitivity analyses
#  (A) Panel restriction to IMPACT468/505 (batch-effect robustness)
#  (B) Formal causal mediation: WGD -> 6p loss -> HLA LOH, bootstrapped ACME/ADE
# Outputs to results/ ; feeds a new Supplementary Table + one Results sentence.
################################################################################
suppressMessages({library(data.table)})
OUT <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/04_processed_data"
RES <- file.path(OUT,"results")
set.seed(42)
msg <- function(...) cat(sprintf(...),"\n")

m <- readRDS(file.path(OUT,"master_cohort.rds"))
D <- m[analysis_primary==TRUE]
D[, WGD := FACETS_WGD=="TRUE"]
D[, cancer_f := factor(CANCER_TYPE)]
D[, panel_f  := factor(GENE_PANEL)]
D[, log_TMB  := log10(pmax(TMB_SCORE,0)+0.1)]

################################################################################
# (A) PANEL RESTRICTION 468/505
################################################################################
msg("===== (A) Panel-restricted sensitivity (IMPACT468/505) =====")
Dp <- D[GENE_PANEL %in% c("IMPACT468","IMPACT505")]
msg("Full cohort N=%d | 468/505 N=%d (%.1f%%)", nrow(D), nrow(Dp), 100*nrow(Dp)/nrow(D))

# Re-estimate the four headline effects in the restricted cohort
est <- function(dat, form, term){
  f <- glm(as.formula(form), data=dat, family=binomial)
  s <- summary(f)$coefficients
  if(!term %in% rownames(s)) return(c(NA,NA,NA,NA))
  c(OR=exp(s[term,1]), lo=exp(s[term,1]-1.96*s[term,2]),
    hi=exp(s[term,1]+1.96*s[term,2]), p=s[term,4])
}
rows <- list()
add <- function(label, full_or, r){
  rows[[label]] <<- data.table(Effect=label, Full_cohort=full_or,
    Restricted_OR=r[1], Restricted_lo=r[2], Restricted_hi=r[3], Restricted_p=r[4])
}
# TMB
add("HLA LOH per log10 TMB", 1.58,
    est(Dp,"any_HLA_LOH ~ log_TMB + FACETS_PURITY + panel_f + cancer_f","log_TMB"))
# WGD (distal, excl 6p)
add("HLA LOH ~ WGD (distal)", 2.30,
    est(Dp,"any_HLA_LOH ~ WGD + FACETS_PURITY + panel_f + cancer_f","WGDTRUE"))
# 6p (proximal)
add("HLA LOH ~ 6p loss (proximal)", 18.5,
    est(Dp,"any_HLA_LOH ~ arm_6p_loss + cancer_f","arm_6p_lossTRUE"))
# germline homozygosity
add("HLA LOH ~ germline homozygosity", 0.75,
    est(Dp,"any_HLA_LOH ~ germ_hom_any + FACETS_PURITY + panel_f + cancer_f","germ_hom_anyTRUE"))
panelSens <- rbindlist(rows)
panelSens[, `:=`(Full_cohort=round(Full_cohort,2), Restricted_OR=round(Restricted_OR,2),
                 Restricted_lo=round(Restricted_lo,2), Restricted_hi=round(Restricted_hi,2))]
fwrite(panelSens, file.path(RES,"SuppTable5_panel_sensitivity.tsv"), sep="\t")
print(panelSens)
msg("Overall HLA LOH: full=%.1f%% | 468/505=%.1f%%",
    100*mean(D$any_HLA_LOH), 100*mean(Dp$any_HLA_LOH))

################################################################################
# (B) FORMAL MEDIATION: WGD (X) -> 6p loss (M) -> HLA LOH (Y)
#     Nonparametric bootstrap of ACME / ADE / proportion mediated.
#     Binary M and Y -> difference-in-probability decomposition (Imai-style),
#     computed by hand to avoid heavy deps; CI by patient-resampling bootstrap.
################################################################################
msg("\n===== (B) Formal mediation WGD -> 6p loss -> HLA LOH =====")
Dm <- D[!is.na(WGD) & !is.na(arm_6p_loss) & !is.na(any_HLA_LOH)]
msg("Mediation cohort N=%d", nrow(Dm))
Dm[, cancer_i := as.integer(cancer_f)]

# Mediator model: P(6p loss | WGD, C) ; Outcome: P(HLA LOH | WGD, 6p, C)
mediate_once <- function(dt){
  mfit <- glm(arm_6p_loss ~ WGD + cancer_f, data=dt, family=binomial)
  yfit <- glm(any_HLA_LOH ~ WGD + arm_6p_loss + cancer_f, data=dt, family=binomial)
  nd <- copy(dt)
  pr <- function(fit,newd) predict(fit,newdata=newd,type="response")
  # potential mediator under WGD=1/0
  d1<-copy(nd); d1[,WGD:=TRUE];  m1<-pr(mfit,d1)
  d0<-copy(nd); d0[,WGD:=FALSE]; m0<-pr(mfit,d0)
  # outcome as function of (WGD, mediatorProb): integrate over Bernoulli(m)
  yprob <- function(setW, mprob){
    dw<-copy(nd); dw[,WGD:=setW]
    dw1<-copy(dw); dw1[,arm_6p_loss:=TRUE];  p1<-pr(yfit,dw1)
    dw0<-copy(dw); dw0[,arm_6p_loss:=FALSE]; p0<-pr(yfit,dw0)
    mprob*p1 + (1-mprob)*p0
  }
  # ACME = E[ Y(1,M(1)) - Y(1,M(0)) ] ; ADE = E[ Y(1,M(0)) - Y(0,M(0)) ]
  # na.rm drops the few cases in rare cancer strata with non-estimable predictions
  ACME <- mean(yprob(TRUE,m1) - yprob(TRUE,m0), na.rm=TRUE)
  ADE  <- mean(yprob(TRUE,m0) - yprob(FALSE,m0), na.rm=TRUE)
  TOT  <- ACME + ADE
  c(ACME=ACME, ADE=ADE, Total=TOT, PropMed=ACME/TOT)
}

pt <- mediate_once(Dm)
# bootstrap (patient-level resample); 200 reps give stable percentile CIs for mediation
B <- 200
boot <- matrix(NA, B, 4, dimnames=list(NULL,c("ACME","ADE","Total","PropMed")))
idx_all <- seq_len(nrow(Dm))
t0 <- Sys.time()
for(b in 1:B){
  bi <- sample(idx_all, replace=TRUE)
  boot[b,] <- tryCatch(mediate_once(Dm[bi]), error=function(e) rep(NA,4))
  if(b %% 50 == 0) msg("  bootstrap %d/%d (%.0fs elapsed)", b, B,
                       as.numeric(difftime(Sys.time(),t0,units="secs")))
}
ci <- function(x) quantile(x, c(.025,.975), na.rm=TRUE)
med_res <- data.table(
  Quantity=c("ACME (indirect, via 6p)","ADE (direct)","Total effect","Proportion mediated"),
  Estimate=round(pt,4),
  CI_low = round(c(ci(boot[,1])[1],ci(boot[,2])[1],ci(boot[,3])[1],ci(boot[,4])[1]),4),
  CI_high= round(c(ci(boot[,1])[2],ci(boot[,2])[2],ci(boot[,3])[2],ci(boot[,4])[2]),4)
)
fwrite(med_res, file.path(RES,"mediation_WGD_6p_HLALOH.tsv"), sep="\t")
print(med_res)
msg("Proportion of WGD effect on HLA LOH mediated by 6p loss: %.1f%% (95%% CI %.1f-%.1f)",
    100*pt["PropMed"], 100*ci(boot[,4])[1], 100*ci(boot[,4])[2])
msg("\n=== SENSITIVITY ANALYSES COMPLETE ===")
