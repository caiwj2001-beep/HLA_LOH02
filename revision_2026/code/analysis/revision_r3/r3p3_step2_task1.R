## R3 part3 — step 2: build aneuploidy scores (all-arms / ex-6p / ex-6p&6q) + TEST 1 (TMB-LOH) + TEST 3 (Cox OS) + burden
suppressMessages(library(data.table)); suppressMessages(library(survival))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
OUT  <- file.path(ROOT, "iscience投稿版本/V2")

## ---------- A. arm-level CNA ----------
cna <- fread(file.path(ROOT, "msk_impact_50k_2026/data_armlevel_cna.txt"), header=TRUE)
arms <- sub("_status$", "", cna$ENTITY_STABLE_ID)
samples <- names(cna)[-(1:3)]
m <- as.matrix(cna[, 4:ncol(cna), with=FALSE]); rownames(m) <- arms
chrom <- suppressWarnings(as.integer(sub("[pq]$", "", arms)))
autosomal <- !is.na(chrom) & chrom <= 22
all_arms  <- arms[autosomal]
ex6p_arms <- setdiff(all_arms, "6p")
ex6_arms  <- setdiff(all_arms, c("6p","6q"))
cat("arms all:", length(all_arms), " ex6p:", length(ex6p_arms), " ex6:", length(ex6_arms), "\n")

altered   <- matrix(m %in% c("Loss","Gain"), nrow=nrow(m), dimnames=dimnames(m))
available <- matrix(!is.na(m) & m != "" & m != "NA", nrow=nrow(m), dimnames=dimnames(m))

build <- function(as_, tag) {
  n_alt <- colSums(altered[as_, , drop=FALSE]); n_av <- colSums(available[as_, , drop=FALSE])
  setnames(data.table(SAMPLE_ID=samples,
                      n=as.integer(n_alt), av=as.integer(n_av),
                      frac=as.numeric(n_alt/n_av)), c("n","av","frac"),
           c(paste0("n_",tag), paste0("av_",tag), paste0("frac_",tag)))
}
A <- Reduce(function(a,b) merge(a,b,by="SAMPLE_ID"),
            list(build(all_arms,"all"), build(ex6p_arms,"ex6p"), build(ex6_arms,"ex6")))
A[, arm_6p_status := m["6p", ]]; A[, arm_6q_status := m["6q", ]]
A[, arm_6p_loss := m["6p", ] == "Loss"]; A[, arm_6q_loss := m["6q", ] == "Loss"]
cat("built A:", dim(A), "\n")
cat(summary(A[, .(frac_all, frac_ex6p, frac_ex6)]), "\n")
fwrite(A, file.path(OUT, "r3p3_aneuploidy_scores.tsv"), sep="\t")

## ---------- B. master cohort ----------
p <- readRDS(file.path(OUT, "r3p3_mc_explore.rds"))
p <- p[analysis_primary == "TRUE"]
p <- merge(p, A[, .(SAMPLE_ID, frac_all, frac_ex6p, frac_ex6, n_all, av_all, arm_6q_status, arm_6q_loss)],
           by="SAMPLE_ID", all.x=TRUE)
p[, TUMOR_PURITY_num := suppressWarnings(as.numeric(TUMOR_PURITY))]
p[TUMOR_PURITY_num > 100, TUMOR_PURITY_num := NA]
p[, logTMB := log10(TMB_SCORE + 0.1)]
p[, LOH := as.integer(any_HLA_LOH)]
p[, WGD := factor(FACETS_WGD)]
p[, CANCER_TYPE := factor(CANCER_TYPE)]; p[, GENE_PANEL := factor(GENE_PANEL)]
p[, SEXf := factor(SEX)]
p[, OS_MONTHS := suppressWarnings(as.numeric(OS_MONTHS))]
p[, OS_event := suppressWarnings(as.numeric(OS_event))]
p[, AGE_AT_DX := suppressWarnings(as.numeric(AGE_AT_DX))]
cat("primary n:", nrow(p), " matched aneu:", sum(!is.na(p$frac_all)), "\n")

orr <- function(mod, term, mult=1) { s <- summary(mod)$coefficients
  if (!term %in% rownames(s)) return(c(est=NA,lo=NA,hi=NA,p=NA))
  b <- s[term,1]; se <- s[term,2]; c(est=exp(b*mult), lo=exp((b-1.96*se)*mult), hi=exp((b+1.96*se)*mult), p=s[term,4]) }
hr <- function(mod, term) { s <- summary(mod)$coefficients
  if (!term %in% rownames(s)) return(c(est=NA,lo=NA,hi=NA,p=NA))
  b <- s[term,1]; se <- s[term,3]; c(est=exp(b), lo=exp(b-1.96*se), hi=exp(b+1.96*se), p=s[term,5]) }
rows <- list(); add <- function(...) rows[[length(rows)+1]] <<- data.table(...)

## ================= TEST 1: logistic TMB ~ LOH =================
cc <- p[!is.na(LOH) & !is.na(logTMB) & !is.na(TUMOR_PURITY_num) &
        !is.na(frac_all) & !is.na(frac_ex6p) & !is.na(frac_ex6) &
        !is.na(CANCER_TYPE) & !is.na(GENE_PANEL)]
cat("\nTest1 complete-case n:", nrow(cc), " LOH+:", sum(cc$LOH), "\n")
cat("TUMOR_PURITY_num blank after conv:", sum(is.na(cc$TUMOR_PURITY_num)), "\n")

sd_all <- sd(cc$frac_all); sd_ex6p <- sd(cc$frac_ex6p); sd_ex6 <- sd(cc$frac_ex6)
cat(sprintf("sd frac_all=%.4f ex6p=%.4f ex6=%.4f\n", sd_all, sd_ex6p, sd_ex6))

f_base <- LOH ~ logTMB + CANCER_TYPE + GENE_PANEL + TUMOR_PURITY_num
M0  <- glm(f_base, data=cc, family=binomial())
M_al<- glm(update(f_base, . ~ . + frac_all),          data=cc, family=binomial())
M_e6p<- glm(update(f_base, . ~ . + frac_ex6p),        data=cc, family=binomial())
M_e6 <- glm(update(f_base, . ~ . + frac_ex6),         data=cc, family=binomial())
cat("\n--- TEST1: logTMB OR by aneuploidy-score adjustment ---\n")
for (nm in c("M0","M_al","M_e6p","M_e6")) {
  mm <- get(nm); r <- orr(mm, "logTMB")
  cat(sprintf("%-6s n=%d  logTMB OR=%.4f (%.4f-%.4f) P=%.3g\n", nm, nrow(model.frame(mm)), r[1],r[2],r[3],r[4]))
  add(Section="T1_TMB", Item=paste0("logTMB_OR_",nm), Model=nm, N=nrow(model.frame(mm)),
      Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4],
      Note=c(M0="base: cancer+panel+purity", M_al="+aneuploidy_frac(all arms)",
             M_e6p="+aneuploidy_frac(ex 6p)", M_e6="+aneuploidy_frac(ex 6p&6q)")[nm])
}
for (nm in c("M_al","M_e6p","M_e6")) {
  mm <- get(nm); v <- c(M_al="frac_all",M_e6p="frac_ex6p",M_e6="frac_ex6")[nm]
  sdv <- c(M_al=sd_all,M_e6p=sd_ex6p,M_e6=sd_ex6)[nm]
  ru <- orr(mm, v); rs <- orr(mm, v, 1/sdv)
  cat(sprintf("%-6s score %s: per-unit OR=%.3f (%.3f-%.3f) P=%.3g | per-SD(%.3f) OR=%.3f (%.3f-%.3f) P=%.3g\n",
              nm, v, ru[1],ru[2],ru[3],ru[4], sdv, rs[1],rs[2],rs[3],rs[4]))
  add(Section="T1_TMB", Item=paste0("score_OR_",v,"_perunit"), Model=nm, N=nrow(model.frame(mm)),
      Estimate=ru[1], CI_low=ru[2], CI_high=ru[3], P_value=ru[4], Note=paste0("per 1.0 ",v))
  add(Section="T1_TMB", Item=paste0("score_OR_",v,"_perSD"), Model=nm, N=nrow(model.frame(mm)),
      Estimate=rs[1], CI_low=rs[2], CI_high=rs[3], P_value=rs[4], Note=sprintf("per SD=%.4f",sdv))
}

## ================= TEST 3: Cox OS ~ LOH =================
os <- p[!is.na(OS_MONTHS) & OS_MONTHS > 0 & !is.na(OS_event) & !is.na(AGE_AT_DX) & !is.na(SEXf) &
        !is.na(logTMB) & !is.na(CANCER_TYPE) & !is.na(FACETS_WGD) &
        !is.na(frac_all) & !is.na(frac_ex6p) & !is.na(frac_ex6)]
os[, SEXf := droplevels(SEXf)]
cat("\nOS set n:", nrow(os), " deaths:", sum(os$OS_event), "\n")
fC <- Surv(OS_MONTHS, OS_event) ~ LOH + AGE_AT_DX + SEXf + logTMB + WGD + CANCER_TYPE
C0  <- coxph(fC, data=os)
C_al<- coxph(update(fC, . ~ . + frac_all),  data=os)
C_e6p<-coxph(update(fC, . ~ . + frac_ex6p), data=os)
C_e6 <-coxph(update(fC, . ~ . + frac_ex6),  data=os)
cat("\n--- TEST3: HLA LOH HR by aneuploidy-score adjustment ---\n")
for (nm in c("C0","C_al","C_e6p","C_e6")) {
  mm <- get(nm); r <- hr(mm, "LOH")
  cat(sprintf("%-6s n=%d deaths=%d  LOH HR=%.4f (%.4f-%.4f) P=%.3g\n", nm, mm$n, mm$nevent, r[1],r[2],r[3],r[4]))
  add(Section="T3_OS", Item=paste0("LOH_HR_",nm), Model=nm, N=mm$n,
      Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4],
      Note=c(C0="base: age+sex+logTMB+WGD+cancer", C_al="+aneuploidy_frac(all arms)",
             C_e6p="+aneuploidy_frac(ex 6p)", C_e6="+aneuploidy_frac(ex 6p&6q)")[nm])
}
for (nm in c("C_al","C_e6p","C_e6")) {
  mm <- get(nm); v <- c(C_al="frac_all",C_e6p="frac_ex6p",C_e6="frac_ex6")[nm]
  r <- hr(mm, v)
  cat(sprintf("%-6s score %s HR/unit=%.4f (%.4f-%.4f) P=%.3g\n", nm, v, r[1],r[2],r[3],r[4]))
  add(Section="T3_OS", Item=paste0("score_HR_",v), Model=nm, N=mm$n,
      Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note=paste0("per 1.0 ",v))
}

## ================= TEST 4: burden=2/3 vs 0 adjusted Cox =================
os[, burden_grp := factor(HLA_LOH_burden, levels=c(0,1,2,3))]
fB <- Surv(OS_MONTHS, OS_event) ~ burden_grp + AGE_AT_DX + SEXf + logTMB + WGD + CANCER_TYPE
B0  <- coxph(fB, data=os)
B_al<- coxph(update(fB, . ~ . + frac_all),  data=os)
B_e6p<-coxph(update(fB, . ~ . + frac_ex6p), data=os)
B_e6 <-coxph(update(fB, . ~ . + frac_ex6),  data=os)
cat("\n--- TEST4: burden vs 0 ---\n")
for (b in c(1,2,3)) {
  line <- sprintf("burden=%d vs 0:", b)
  for (nm in c("B0","B_al","B_e6p","B_e6")) {
    r <- hr(get(nm), paste0("burden_grp",b)); line <- paste0(line, sprintf("  %s %.3f(%.3f-%.3f)P=%.2g", nm, r[1],r[2],r[3],r[4]))
    add(Section="T4_burden", Item=paste0("burden",b,"_vs0_",nm), Model=nm, N=get(nm)$n,
        Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4],
        Note=c(B0="base", B_al="+frac_all", B_e6p="+frac_ex6p", B_e6="+frac_ex6")[nm])
  }
  cat(line, "\n")
}

## ================= correlations =================
q <- p[!is.na(frac_all) & !is.na(LOH)]
cat("\n--- correlation of aneuploidy scores with HLA LOH ---\n")
for (v in c("frac_all","frac_ex6p","frac_ex6")) {
  rho <- cor(q[[v]], q$LOH, method="spearman")
  mU <- glm(as.formula(paste0("LOH ~ scale(",v,")")), data=q, family=binomial())
  rU <- orr(mU, paste0("scale(",v,")"))
  cat(sprintf("%-9s Spearman rho=%.4f (n=%d) | per-SD logistic OR=%.3f (%.3f-%.3f) P=%.3g\n",
              v, rho, nrow(q), rU[1],rU[2],rU[3],rU[4]))
  add(Section="Corr", Item=paste0("spearman_rho_",v), N=nrow(q), Estimate=rho, Note="vs any_HLA_LOH")
  add(Section="Corr", Item=paste0("logistic_OR_perSD_",v,"_unadj"), N=nrow(q), Estimate=rU[1], CI_low=rU[2], CI_high=rU[3], P_value=rU[4])
}
## LOH vs 6p arm loss
q2 <- p[!is.na(arm_6p) & arm_6p != "" & !is.na(LOH)]
cat(sprintf("\n6p-arm-loss (Loss) vs LOH: n Loss=%d/%d of LOH; LOH rate Loss=%.1f%% NonLoss=%.1f%%\n",
            sum(q2$arm_6p_loss & q2$LOH), sum(q2$LOH),
            100*mean(q2$LOH[q2$arm_6p_loss]), 100*mean(q2$LOH[!q2$arm_6p_loss])))
add(Section="Corr", Item="LOH_rate_by_6p_loss", Note="cohort",
    Estimate=100*mean(q2$LOH[q2$arm_6p_loss]), CI_low=100*mean(q2$LOH[!q2$arm_6p_loss]))
## correlation between frac_all and frac_ex6
cat(sprintf("cor(frac_all, frac_ex6)=%.4f ; cor(frac_all, frac_ex6p)=%.4f\n",
            cor(q$frac_all, q$frac_ex6), cor(q$frac_all, q$frac_ex6p)))

fwrite(rbindlist(rows, fill=TRUE), file.path(OUT, "r3p3_task1_rows.tsv"), sep="\t")
saveRDS(list(p=p, os=os), file.path(OUT, "r3p3_data.rds"))
cat("\nSTEP2 (task1) done\n")
