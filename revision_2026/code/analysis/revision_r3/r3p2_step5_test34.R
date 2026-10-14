## R3 part2 — step 5: TEST 3 (Cox OS + aneuploidy) and TEST 4 (burden Cox + LOH~aneuploidy)
suppressMessages(library(data.table)); suppressMessages(library(survival))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
OUT  <- file.path(ROOT, "iscience投稿版本/V2")
D <- readRDS(file.path(OUT, "r3p2_data.rds")); p <- D$p
p[, OS_MONTHS := suppressWarnings(as.numeric(OS_MONTHS))]
p[, OS_event := suppressWarnings(as.numeric(OS_event))]
p[, AGE_AT_DX := suppressWarnings(as.numeric(AGE_AT_DX))]
p[, SEXf := factor(SEX)]
hr <- function(mod, term) { s <- summary(mod)$coefficients
  if (!term %in% rownames(s)) return(c(est=NA,lo=NA,hi=NA,p=NA))
  b <- s[term,1]; se <- s[term,3]; c(est=exp(b), lo=exp(b-1.96*se), hi=exp(b+1.96*se), p=s[term,5]) }
hrglm <- function(mod, term) { s <- summary(mod)$coefficients
  if (!term %in% rownames(s)) return(c(est=NA,lo=NA,hi=NA,p=NA))
  b <- s[term,1]; se <- s[term,2]; c(est=exp(b), lo=exp(b-1.96*se), hi=exp(b+1.96*se), p=s[term,4]) }
rows <- list(); add <- function(...) rows[[length(rows)+1]] <<- data.table(...)

## ---------- TEST 3 ----------
os <- p[!is.na(OS_MONTHS) & OS_MONTHS > 0 & !is.na(OS_event) & !is.na(AGE_AT_DX) & !is.na(SEXf) &
        !is.na(logTMB) & !is.na(CANCER_TYPE)]
cat("OS base set n:", nrow(os), " deaths:", sum(os$OS_event), "\n")
osA <- os[!is.na(FACETS_WGD) & !is.na(aneuploidy_frac)]
cat("OS set with WGD+aneuploidy n:", nrow(osA), " deaths:", sum(osA$OS_event), "\n")
fit0 <- coxph(Surv(OS_MONTHS, OS_event) ~ LOH + AGE_AT_DX + SEXf + logTMB + FACETS_WGD + CANCER_TYPE, data=osA)
fit1 <- coxph(Surv(OS_MONTHS, OS_event) ~ LOH + AGE_AT_DX + SEXf + logTMB + FACETS_WGD + CANCER_TYPE + aneuploidy_frac, data=osA)
fit2 <- coxph(Surv(OS_MONTHS, OS_event) ~ LOH + AGE_AT_DX + SEXf + logTMB + CANCER_TYPE + aneuploidy_frac, data=osA)
fitU <- coxph(Surv(OS_MONTHS, OS_event) ~ LOH, data=osA)
fitA <- coxph(Surv(OS_MONTHS, OS_event) ~ LOH + aneuploidy_frac, data=osA)
sd_f <- sd(osA$aneuploidy_frac)
cat("\n--- TEST3 ---\n")
for (nm in c("fitU","fitA","fit0","fit1","fit2")) {
  m <- get(nm); r <- hr(m, "LOH")
  cat(sprintf("%-5s n=%d deaths=%d  LOH HR=%.3f (%.3f-%.3f) P=%.3g\n", nm, m$n, m$nevent, r[1],r[2],r[3],r[4]))
  add(Section="T3_survival", Item="HLA_LOH_HR", Stratum=nm, N=m$n,
      Value=sprintf("deaths=%d HR=%.3f (%.3f-%.3f)", m$nevent, r[1],r[2],r[3]), Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4],
      Note=c(fitU="unadjusted", fitA="+aneuploidy only", fit0="age+sex+logTMB+WGD+cancer",
             fit1="age+sex+logTMB+WGD+cancer+aneuploidy", fit2="age+sex+logTMB+cancer+aneuploidy")[nm])
}
r <- hr(fit1, "aneuploidy_frac"); rs <- hr(fit1, "aneuploidy_frac")
cat(sprintf("fit1 aneuploidy_frac per unit HR=%.3f (%.3f-%.3f) P=%.3g | per SD(%.3f) HR=%.3f (%.3f-%.3f)\n",
            r[1],r[2],r[3],r[4], sd_f, r[1]^(1/sd_f), r[2]^(1/sd_f), r[3]^(1/sd_f)))
add(Section="T3_survival", Item="aneuploidy_frac_HR_per_unit", Stratum="fit1", N=fit1$n,
    Value=sprintf("HR=%.3f (%.3f-%.3f)", r[1],r[2],r[3]), Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note="per 1.0 frac")
add(Section="T3_survival", Item="WGD_HR", Stratum="fit1", N=fit1$n,
    Value=sprintf("HR=%.3f (%.3f-%.3f)", hr(fit1,"FACETS_WGDTRUE")[1], hr(fit1,"FACETS_WGDTRUE")[2], hr(fit1,"FACETS_WGDTRUE")[3]),
    Estimate=hr(fit1,"FACETS_WGDTRUE")[1], CI_low=hr(fit1,"FACETS_WGDTRUE")[2], CI_high=hr(fit1,"FACETS_WGDTRUE")[3],
    P_value=hr(fit1,"FACETS_WGDTRUE")[4], Note="")

## per-cancer
cat("\n--- TEST3 per-cancer ---\n")
pc_p <- c(); pc_ct <- c()
for (ct in c("Prostate Cancer","Renal Cell Carcinoma","Bladder Cancer","Non-Small Cell Lung Cancer","Breast Cancer")) {
  ds <- osA[CANCER_TYPE == ct]
  if (nrow(ds) < 100) { cat(ct, ": too small\n"); next }
  f0 <- coxph(Surv(OS_MONTHS, OS_event) ~ LOH + AGE_AT_DX + SEXf + logTMB, data=ds)
  f1 <- coxph(Surv(OS_MONTHS, OS_event) ~ LOH + AGE_AT_DX + SEXf + logTMB + aneuploidy_frac, data=ds)
  r0 <- hr(f0,"LOH"); r1 <- hr(f1,"LOH"); rf <- hr(f1,"aneuploidy_frac")
  cat(sprintf("%-30s n=%d deaths=%d | unadj HR=%.3f (%.3f-%.3f) P=%.3g | +aneu HR=%.3f (%.3f-%.3f) P=%.3g | aneu HR=%.3f P=%.2g\n",
              ct, f0$n, f0$nevent, r0[1],r0[2],r0[3],r0[4], r1[1],r1[2],r1[3],r1[4], rf[1], rf[4]))
  add(Section="T3_per_cancer", Item="HLA_LOH_HR_unadj", Stratum=ct, N=f0$n,
      Value=sprintf("deaths=%d HR=%.3f (%.3f-%.3f)", f0$nevent, r0[1],r0[2],r0[3]), Estimate=r0[1], CI_low=r0[2], CI_high=r0[3], P_value=r0[4], Note="age+sex+TMB")
  add(Section="T3_per_cancer", Item="HLA_LOH_HR_adj_aneuploidy", Stratum=ct, N=f1$n,
      Value=sprintf("deaths=%d HR=%.3f (%.3f-%.3f)", f1$nevent, r1[1],r1[2],r1[3]), Estimate=r1[1], CI_low=r1[2], CI_high=r1[3], P_value=r1[4], Note="age+sex+TMB+aneuploidy_frac")
  add(Section="T3_per_cancer", Item="aneuploidy_frac_HR", Stratum=ct, N=f1$n,
      Value=sprintf("HR=%.3f (%.3f-%.3f)", rf[1],rf[2],rf[3]), Estimate=rf[1], CI_low=rf[2], CI_high=rf[3], P_value=rf[4], Note="per 1.0 frac")
  pc_p <- c(pc_p, r1[4]); pc_ct <- c(pc_ct, ct)
}
fdr_pc <- setNames(p.adjust(pc_p, "BH"), pc_ct)
cat("BH-FDR for HLA-LOH HR (adj aneuploidy) across the 5 cancers:",
    paste(sprintf("%s=%.3f", pc_ct, fdr_pc), collapse=", "), "\n")
for (i in seq_along(pc_ct)) add(Section="T3_per_cancer", Item="HLA_LOH_HR_adj_aneuploidy_BH_FDR", Stratum=pc_ct[i], N=NA,
      Value=sprintf("BH_FDR=%.3f (over 5 cancers)", fdr_pc[i]), Estimate=fdr_pc[i], CI_low=NA, CI_high=NA,
      P_value=pc_p[i], Note="BH across 5 prespecified cancers")

## ---------- TEST 4 ----------
cat("\n--- TEST4 ---\n")
osA[, burden_grp := factor(HLA_LOH_burden, levels=c(0,1,2,3))]
osA[, burden_num := as.numeric(HLA_LOH_burden)]
f4 <- coxph(Surv(OS_MONTHS, OS_event) ~ burden_grp + AGE_AT_DX + SEXf + logTMB + FACETS_WGD + CANCER_TYPE, data=osA)
f4b<- coxph(Surv(OS_MONTHS, OS_event) ~ burden_grp + AGE_AT_DX + SEXf + logTMB + FACETS_WGD + CANCER_TYPE + aneuploidy_frac, data=osA)
for (b in c(1,2,3)) {
  r <- hr(f4, paste0("burden_grp", b)); r2 <- hr(f4b, paste0("burden_grp", b))
  cat(sprintf("burden=%d vs 0: adj HR=%.3f (%.3f-%.3f) P=%.3g | +aneuploidy HR=%.3f (%.3f-%.3f) P=%.3g\n",
              b, r[1],r[2],r[3],r[4], r2[1],r2[2],r2[3],r2[4]))
  add(Section="T4_burden", Item="burden_vs0_adj", Stratum=paste0("burden",b), N=f4$n,
      Value=sprintf("deaths=%d HR=%.3f (%.3f-%.3f)", f4$nevent, r[1],r[2],r[3]), Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4],
      Note="age+sex+logTMB+WGD+cancer")
  add(Section="T4_burden", Item="burden_vs0_adj_aneuploidy", Stratum=paste0("burden",b), N=f4b$n,
      Value=sprintf("HR=%.3f (%.3f-%.3f)", r2[1],r2[2],r2[3]), Estimate=r2[1], CI_low=r2[2], CI_high=r2[3], P_value=r2[4],
      Note="age+sex+logTMB+WGD+cancer+aneuploidy")
}
f4t <- coxph(Surv(OS_MONTHS, OS_event) ~ burden_num + AGE_AT_DX + SEXf + logTMB + FACETS_WGD + CANCER_TYPE, data=osA)
rt <- hr(f4t, "burden_num")
cat(sprintf("burden per-step adj HR=%.4f (%.4f-%.4f) P=%.3g\n", rt[1],rt[2],rt[3],rt[4]))
add(Section="T4_burden", Item="burden_trend_adj", Stratum="continuous 0-3", N=f4t$n,
    Value=sprintf("HR=%.4f (%.4f-%.4f)", rt[1],rt[2],rt[3]), Estimate=rt[1], CI_low=rt[2], CI_high=rt[3], P_value=rt[4],
    Note="age+sex+logTMB+WGD+cancer")

q <- p[!is.na(aneuploidy_frac) & !is.na(LOH)]
rho_f <- cor(q$aneuploidy_frac, q$LOH, method="spearman"); rho_n <- cor(q$aneuploidy_n, q$LOH, method="spearman")
cat(sprintf("Spearman rho aneuploidy_frac vs LOH = %.4f (n=%d); aneuploidy_n vs LOH = %.4f\n", rho_f, nrow(q), rho_n))
add(Section="T4_burden", Item="spearman_rho_aneuploidy_frac_vs_LOH", Stratum="primary", N=nrow(q),
    Value=sprintf("rho=%.4f", rho_f), Estimate=rho_f, CI_low=NA, CI_high=NA, P_value=NA, Note="Spearman")
add(Section="T4_burden", Item="spearman_rho_aneuploidy_n_vs_LOH", Stratum="primary", N=nrow(q),
    Value=sprintf("rho=%.4f", rho_n), Estimate=rho_n, CI_low=NA, CI_high=NA, P_value=NA, Note="Spearman")
mU <- glm(LOH ~ scale(aneuploidy_frac), data=q, family=binomial()); rU <- hrglm(mU, "scale(aneuploidy_frac)")
mA <- glm(LOH ~ scale(aneuploidy_frac) + logTMB + FACETS_WGD + CANCER_TYPE + GENE_PANEL, data=q, family=binomial()); rA <- hrglm(mA, "scale(aneuploidy_frac)")
cat(sprintf("logistic LOH ~ per-SD aneuploidy_frac: unadj OR=%.3f (%.3f-%.3f) | adj(TMB+WGD+cancer+panel) OR=%.3f (%.3f-%.3f) P=%.3g\n",
            rU[1],rU[2],rU[3], rA[1],rA[2],rA[3],rA[4]))
mr <- glm(LOH ~ scale(aneuploidy_frac) + scale(aneuploidy_n), data=q, family=binomial()); rr <- hrglm(mr,"scale(aneuploidy_n)")
cat(sprintf("LOH ~ frac + n: n per SD OR=%.3f (%.3f-%.3f) P=%.3g\n", rr[1],rr[2],rr[3],rr[4]))
add(Section="T4_burden", Item="logistic_OR_perSD_aneuploidy_frac_unadj", Stratum="primary", N=nrow(q),
    Value=sprintf("OR=%.3f (%.3f-%.3f)", rU[1],rU[2],rU[3]), Estimate=rU[1], CI_low=rU[2], CI_high=rU[3], P_value=rU[4], Note="unadjusted")
add(Section="T4_burden", Item="logistic_OR_perSD_aneuploidy_frac_adj", Stratum="primary", N=mA$n,
    Value=sprintf("OR=%.3f (%.3f-%.3f)", rA[1],rA[2],rA[3]), Estimate=rA[1], CI_low=rA[2], CI_high=rA[3], P_value=rA[4], Note="adj logTMB+WGD+cancer+panel")
## sensitivity: restrict to cancer types with n>=100 (avoids infinite-coefficient levels)
big <- osA[, .N, by=CANCER_TYPE][N >= 100]$CANCER_TYPE
osB <- osA[CANCER_TYPE %in% big]
fB0 <- coxph(Surv(OS_MONTHS, OS_event) ~ LOH + AGE_AT_DX + SEXf + logTMB + FACETS_WGD + CANCER_TYPE, data=osB)
fB1 <- coxph(Surv(OS_MONTHS, OS_event) ~ LOH + AGE_AT_DX + SEXf + logTMB + FACETS_WGD + CANCER_TYPE + aneuploidy_frac, data=osB)
cat(sprintf("\n[sens n>=100 per cancer, %d cancer types] LOH HR base=%.3f (%.3f-%.3f) P=%.3g | +aneu=%.3f (%.3f-%.3f) P=%.3g\n",
            length(big), hr(fB0,"LOH")[1], hr(fB0,"LOH")[2], hr(fB0,"LOH")[3], hr(fB0,"LOH")[4],
            hr(fB1,"LOH")[1], hr(fB1,"LOH")[2], hr(fB1,"LOH")[3], hr(fB1,"LOH")[4]))
add(Section="T3_sens", Item="HLA_LOH_HR_base_cancerNge100", Stratum=paste0(length(big)," cancer types"), N=fB0$n,
    Value=sprintf("deaths=%d HR=%.3f (%.3f-%.3f)", fB0$nevent, hr(fB0,"LOH")[1], hr(fB0,"LOH")[2], hr(fB0,"LOH")[3]),
    Estimate=hr(fB0,"LOH")[1], CI_low=hr(fB0,"LOH")[2], CI_high=hr(fB0,"LOH")[3], P_value=hr(fB0,"LOH")[4],
    Note="age+sex+logTMB+WGD+cancer")
add(Section="T3_sens", Item="HLA_LOH_HR_adj_aneuploidy_cancerNge100", Stratum=paste0(length(big)," cancer types"), N=fB1$n,
    Value=sprintf("deaths=%d HR=%.3f (%.3f-%.3f)", fB1$nevent, hr(fB1,"LOH")[1], hr(fB1,"LOH")[2], hr(fB1,"LOH")[3]),
    Estimate=hr(fB1,"LOH")[1], CI_low=hr(fB1,"LOH")[2], CI_high=hr(fB1,"LOH")[3], P_value=hr(fB1,"LOH")[4],
    Note="age+sex+logTMB+WGD+cancer+aneuploidy")

fwrite(rbindlist(rows, fill=TRUE), file.path(OUT, "r3p2_part34_rows.tsv"), sep="\t")
cat("\nSTEP5 done\n")
