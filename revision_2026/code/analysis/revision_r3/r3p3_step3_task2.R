## R3 part3 — step 3: TASK 2 arm-independent HLA LOH — mechanism (ascna) + characterisation + survival
suppressMessages(library(data.table)); suppressMessages(library(survival))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
OUT  <- file.path(ROOT, "iscience投稿版本/V2")
SCR  <- "C:/Users/Administrator/AppData/Local/hermes/cache/scratch/r3p3"

## ---------- HLA-region allele-specific CN (chr6:29.9-33.5Mb hg19 = 6p21.3) ----------
parse_cn <- function(f) {
  a <- fread(f, sep="\t"); samp <- names(a)[-1]; gl <- a$Hugo_Symbol
  M <- t(as.matrix(a[, -1, with=FALSE]))          # samples x genes (character)
  rownames(M) <- samp; colnames(M) <- gl
  tot <- minor <- matrix(NA_real_, nrow=length(samp), ncol=length(gl), dimnames=list(samp, gl))
  for (j in seq_along(gl)) {
    sp <- strsplit(M[, j], ";")
    f1 <- vapply(sp, function(x) suppressWarnings(as.numeric(x[1])), numeric(1))
    f2 <- vapply(sp, function(x) suppressWarnings(as.numeric(x[2])), numeric(1))
    tot[, j] <- f1 + f2; minor[, j] <- pmin(f1, f2)   # total = a+b, minor = min(a,b)
  }
  list(tot=tot, minor=minor)
}
asc <- parse_cn(file.path(SCR, "ascna_hla.tsv"))
dis <- fread(file.path(SCR, "cna_hla.tsv"), sep="\t"); dgenes <- dis$Hugo_Symbol
dmat <- t(as.matrix(dis[, -1, with=FALSE])); rownames(dmat) <- names(dis)[-1]; colnames(dmat) <- dgenes
cat("ascna genes:", colnames(asc$tot), "| discrete genes:", colnames(dmat), "\n")

## ---------- analysis set ----------
D <- readRDS(file.path(OUT, "r3p3_data.rds")); p <- D$p
p <- p[analysis_primary == "TRUE"]
p[, ploidy := suppressWarnings(as.numeric(FACETS_PLOIDY))]
p[, germ_het_loci := 3L - (as.integer(germ_hom_A) + as.integer(germ_hom_B) + as.integer(germ_hom_C))]
p[, arm6p := fifelse(arm_6p == "", "Missing", arm_6p)]
p[, grp := fifelse(any_HLA_LOH == "FALSE", "No_LOH",
            fifelse(arm6p == "Loss", "Arm_dependent",
             fifelse(arm6p %in% c("Unchanged","Gain"), "Arm_independent", "LOH_6p_missing")))]
cat("group counts (primary):\n"); print(table(p$grp))
n_ind <- sum(p$grp == "Arm_independent"); n_dep <- sum(p$grp == "Arm_dependent")
cat(sprintf("Arm_independent n=%d ; Arm_dependent n=%d ; ratio indep/dep=%.3f\n",
            n_ind, n_dep, n_ind/n_dep))

## ---------- classify arm-independent by mechanism ----------
hla3 <- c("HLA-A","HLA-B","HLA-C")
reg_all <- c("HLA-A","HLA-B","HLA-C","NOTCH4","STK19","TAP1","TAP2")
classify <- function(s) {
  pl <- p$ploidy[match(s, p$SAMPLE_ID)]
  if (is.na(pl)) return("Indeterminate")
  to <- asc$tot[s, hla3]; mi <- asc$minor[s, hla3]
  ok <- !is.na(to); if (sum(ok) == 0) return("Indeterminate")
  tot_min <- suppressWarnings(min(to[ok]))
  lost <- ok & mi == 0
  if (sum(lost) > 0) {                       # allelic loss visible at an HLA gene
    dt <- to[lost] - pl
    if (any(dt <= -0.5)) return("Focal_deletion")        # total CN below ploidy
    if (all(abs(dt) <= 0.5)) return("Copy_neutral_LOH")  # total ~ ploidy, minor ~ 0
    return("Indeterminate")                              # allelic loss but total > ploidy (gain-LOH)
  }
  if (tot_min - pl <= -0.5) return("Focal_deletion")     # region copy loss, allelic state het
  return("Indeterminate")                                # het / copy-neutral, LOH not corroborated at gene level
}
ind_ids <- p[grp == "Arm_independent"]$SAMPLE_ID
dep_ids <- p[grp == "Arm_dependent"]$SAMPLE_ID
p[grp == "Arm_independent", mech := vapply(SAMPLE_ID, classify, character(1))]
p[grp == "Arm_dependent",  mech := vapply(SAMPLE_ID, classify, character(1))]
cat("\n--- mechanism among arm-independent (n=", n_ind, ") ---\n", sep="")
tb_ind <- table(p[grp=="Arm_independent"]$mech); print(tb_ind)
cat(sprintf("  pct: %s\n", paste(sprintf("%s=%.2f%%", names(tb_ind), 100*tb_ind/sum(tb_ind)), collapse="  ")))
cat("\n--- mechanism among arm-dependent (6p loss, n=", n_dep, ") [sanity] ---\n", sep="")
tb_dep <- table(p[grp=="Arm_dependent"]$mech); print(tb_dep)
cat(sprintf("  pct: %s\n", paste(sprintf("%s=%.2f%%", names(tb_dep), 100*tb_dep/sum(tb_dep)), collapse="  ")))
## discrete cross-check for arm-independent
mi3 <- asc$minor[ind_ids, hla3]; to3 <- asc$tot[ind_ids, hla3]
hasna <- rowSums(!is.na(mi3)); cat("\narm-indep: ascna HLA-A/B/C non-NA cells per sample:\n"); print(table(hasna))
dl_low <- NULL
## extra metric: representative (min) total & delta
rep_tot <- apply(to3, 1, function(x) suppressWarnings(min(x, na.rm=TRUE)))
rep_tot[!is.finite(rep_tot)] <- NA
rep_delta <- rep_tot - p$ploidy[match(ind_ids, p$SAMPLE_ID)]
cat("arm-indep representative min HLA total (ascna):\n"); print(table(rep_tot, useNA="ifany"))

## ---------- 2.2 comparisons indep vs dep ----------
cmp <- p[grp %in% c("Arm_independent","Arm_dependent")]
cmp[, grp := factor(grp, levels=c("Arm_dependent","Arm_independent"))]
cmp[, TUMOR_PURITY_num := suppressWarnings(as.numeric(TUMOR_PURITY))]
cmp[TUMOR_PURITY_num > 100, TUMOR_PURITY_num := NA]
cmp[, FACETS_PLOIDY := suppressWarnings(as.numeric(FACETS_PLOIDY))]
cmp[, TMB_SCORE := suppressWarnings(as.numeric(TMB_SCORE))]
cmp[, sig_HRD := suppressWarnings(as.numeric(sig_HRD))]
cmp[, sig_MMR := suppressWarnings(as.numeric(sig_MMR))]
cmp[, is_met := SAMPLE_TYPE %in% c("Metastasis")]
cmp[, WGD_bin := FACETS_WGD == "TRUE"]
rows <- list(); add <- function(...) rows[[length(rows)+1]] <<- data.table(...)

## ---- 2.1 supporting: minor status x delta(total-ploidy), 3 HLA genes ----
supp_2d <- function(ids, nm) {
  to <- asc$tot[ids, hla3]; mi <- asc$minor[ids, hla3]; pl <- p$ploidy[match(ids, p$SAMPLE_ID)]
  rep_min <- apply(mi,1,function(x){x<-x[!is.na(x)]; if(length(x)) min(x) else NA})
  rep_tot <- apply(to,1,function(x){x<-x[!is.na(x)]; if(length(x)) min(x) else NA})
  delta <- rep_tot - pl
  cat("\n[",nm,"] min_minor x delta(total-ploidy):\n", sep="")
  t2 <- table(minminor=ifelse(rep_min==0,"minor0",ifelse(is.na(rep_min),"NA","minor>0")),
              delta=cut(delta, c(-Inf,-0.5,0.5,Inf), labels=c("loss<-0.5","neutral","gain>0.5")), useNA="ifany")
  print(t2); invisible(t2)
}
supp_2d(p[grp=="Arm_independent"]$SAMPLE_ID, "Arm_independent")
supp_2d(p[grp=="Arm_dependent"]$SAMPLE_ID, "Arm_dependent")
rw <- asc$minor[p[grp=="Arm_independent"]$SAMPLE_ID, reg_all]
rwmin <- apply(rw,1,function(x){x<-x[!is.na(x)]; if(length(x)) min(x) else NA})
cat("\n[arm-indep, 7-gene region] min minor distribution:\n"); print(table(rwmin, useNA="ifany"))
for (k in names(tb_ind)) add(Section="T2_1_mechanism", Item="Arm_independent", Class=k, N=as.integer(tb_ind[k]),
      Proportion=round(as.numeric(tb_ind[k]/sum(tb_ind)),4), Value=sprintf("%d (%.2f%%)", tb_ind[k], 100*tb_ind[k]/sum(tb_ind)))
for (k in names(tb_dep)) add(Section="T2_1_mechanism", Item="Arm_dependent", Class=k, N=as.integer(tb_dep[k]),
      Proportion=round(as.numeric(tb_dep[k]/sum(tb_dep)),4), Value=sprintf("%d (%.2f%%)", tb_dep[k], 100*tb_dep[k]/sum(tb_dep)))

cont <- c(TMB_SCORE="TMB_SCORE", FACETS_PLOIDY="FACETS_PLOIDY (ploidy)", TUMOR_PURITY_num="TUMOR_PURITY",
          sig_HRD="sig_HRD", sig_MMR="sig_MMR", germ_het_loci="germline_HET_loci")
cat("\n=== continuous comparisons (indep vs dep): median [IQR], Wilcoxon P ===\n")
for (v in names(cont)) {
  sub <- cmp[!is.na(get(v))]
  x <- sub[grp=="Arm_dependent"][[v]]; y <- sub[grp=="Arm_independent"][[v]]
  wt <- suppressWarnings(wilcox.test(y, x))
  cat(sprintf("%-22s dep(n=%d) med=%.3f [%.3f-%.3f] | indep(n=%d) med=%.3f [%.3f-%.3f] | P=%.3g\n",
              cont[v], length(x), median(x), quantile(x,.25), quantile(x,.75),
              length(y), median(y), quantile(y,.25), quantile(y,.75), wt$p.value))
  add(Section="T2_char", Item=v, Sub="median", Dep_med=median(x), Dep_IQR=paste0(round(quantile(x,.25),3),"-",round(quantile(x,.75),3)),
      Dep_n=length(x), Indep_med=median(y), Indep_IQR=paste0(round(quantile(y,.25),3),"-",round(quantile(y,.75),3)),
      Indep_n=length(y), P_value=wt$p.value, Note="Wilcoxon rank-sum")
}
cat("\n=== categorical comparisons ===\n")
bi <- function(v, lab) {
  tb <- table(cmp$grp, cmp[[v]], useNA="no"); if (ncol(tb) < 2) return(invisible())
  ct <- suppressWarnings(chisq.test(tb))
  pp <- sweep(tb, 1, rowSums(tb), "/")
  cat(sprintf("%-16s dep: %s | indep: %s | P=%.3g\n", lab,
      paste(sprintf("%s=%.1f%%", colnames(tb), 100*pp[1,]), collapse=" "),
      paste(sprintf("%s=%.1f%%", colnames(tb), 100*pp[2,]), collapse=" "), ct$p.value))
  add(Section="T2_char", Item=v, Sub="proportion", Dep_prop=paste(sprintf("%s=%.1f%%", colnames(tb), 100*pp[1,]),collapse=" "),
      Indep_prop=paste(sprintf("%s=%.1f%%", colnames(tb), 100*pp[2,]),collapse=" "),
      Dep_n=sum(tb[1,]), Indep_n=sum(tb[2,]), P_value=ct$p.value, Note="chi-square")
}
bi("WGD_bin", "FACETS_WGD")
bi("is_met", "Primary/Met")
bi("SAMPLE_TYPE", "SAMPLE_TYPE")

## cancer type top 10
cat("\n=== top-10 cancer types ===\n")
ti <- cmp[, .N, by=.(grp, CANCER_TYPE)][order(-N)]
for (g in c("Arm_independent","Arm_dependent")) {
  tt <- ti[grp==g][1:10]; cat(g, ":\n"); print(tt[, .(CANCER_TYPE, N, pct=round(100*N/sum(ti[grp==g]$N),1))])
}
w <- dcast(ti, CANCER_TYPE ~ grp, value.var="N", fill=0)
w[, tot := Arm_dependent + Arm_independent][order(-tot)]
ct_tb <- as.matrix(w[order(-tot)][1:12, .(Arm_dependent, Arm_independent)])
ct_p <- suppressWarnings(chisq.test(ct_tb)$p.value)
cat("chi-square (top-12 cancer types) P=", signif(ct_p,3), "\n")
add(Section="T2_char", Item="CANCER_TYPE_top10", Sub="list",
    Dep_prop=paste(w[order(-tot)][1:10]$CANCER_TYPE, collapse="; "), P_value=ct_p)

## ---------- 2.3 survival: three-way ----------
os <- p[!is.na(OS_MONTHS) & OS_MONTHS > 0 & !is.na(OS_event) & !is.na(AGE_AT_DX) & !is.na(SEX) &
        !is.na(logTMB) & !is.na(CANCER_TYPE) & grp %in% c("No_LOH","Arm_independent","Arm_dependent")]
os[, grp3 := factor(grp, levels=c("No_LOH","Arm_independent","Arm_dependent"))]
os[, SEXf := factor(SEX)]
cat("\nOS three-way n:", nrow(os), " deaths:", sum(os$OS_event), "\n"); print(table(os$grp3))
hr <- function(mod, term) { s <- summary(mod)$coefficients
  if (!term %in% rownames(s)) return(c(est=NA,lo=NA,hi=NA,p=NA))
  b <- s[term,1]; se <- s[term,3]; c(est=exp(b), lo=exp(b-1.96*se), hi=exp(b+1.96*se), p=s[term,5]) }
fit3 <- coxph(Surv(OS_MONTHS, OS_event) ~ grp3 + AGE_AT_DX + SEXf + logTMB + CANCER_TYPE, data=os)
cat("\n=== Cox OS (ref = No_LOH), adj age+sex+logTMB+cancer ===\n")
for (lv in c("Arm_independent","Arm_dependent")) {
  r <- hr(fit3, paste0("grp3", lv))
  cat(sprintf("%-16s HR=%.3f (%.3f-%.3f) P=%.3g\n", lv, r[1],r[2],r[3],r[4]))
  add(Section="T2_OS", Item=paste0("HR_",lv), Sub="vs No_LOH", N=fit3$n,
      Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note="age+sex+logTMB+cancer")
}
## sensitivity: + aneuploidy_frac, + WGD, no-6p aneuploidy
os[, WGD := factor(FACETS_WGD)]
f3b <- coxph(Surv(OS_MONTHS, OS_event) ~ grp3 + AGE_AT_DX + SEXf + logTMB + WGD + CANCER_TYPE, data=os)
cat("\n=== sensitivity +WGD ===\n")
for (lv in c("Arm_independent","Arm_dependent")) { r <- hr(f3b, paste0("grp3",lv))
  cat(sprintf("%-16s HR=%.3f (%.3f-%.3f) P=%.3g\n", lv, r[1],r[2],r[3],r[4]))
  add(Section="T2_OS_sens", Item=paste0("HR_",lv), Sub="vs No_LOH, +WGD", N=f3b$n,
      Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note="age+sex+logTMB+WGD+cancer") }
osA <- os[!is.na(frac_ex6)]
f3c <- coxph(Surv(OS_MONTHS, OS_event) ~ grp3 + AGE_AT_DX + SEXf + logTMB + WGD + CANCER_TYPE + frac_ex6, data=osA)
cat("\n=== sensitivity +WGD +aneuploidy_frac_ex6 ===\n")
for (lv in c("Arm_independent","Arm_dependent")) { r <- hr(f3c, paste0("grp3",lv))
  cat(sprintf("%-16s HR=%.3f (%.3f-%.3f) P=%.3g\n", lv, r[1],r[2],r[3],r[4]))
  add(Section="T2_OS_sens", Item=paste0("HR_",lv), Sub="vs No_LOH, +WGD+aneu(ex6)", N=f3c$n,
      Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note="age+sex+logTMB+WGD+cancer+frac_ex6") }

## mechanism x survival (within arm-independent)
osmi <- os[grp=="Arm_independent" & mech %in% c("Focal_deletion","Copy_neutral_LOH")]
if (nrow(osmi) > 50) {
  osmi[, mech := factor(mech, levels=c("Copy_neutral_LOH","Focal_deletion"))]
  fmi <- coxph(Surv(OS_MONTHS, OS_event) ~ mech + AGE_AT_DX + SEXf + logTMB + CANCER_TYPE, data=osmi)
  r <- hr(fmi, "mechFocal_deletion")
  cat(sprintf("\n[within arm-indep] Focus-deletion vs cnLOH HR=%.3f (%.3f-%.3f) P=%.3g (n=%d)\n", r[1],r[2],r[3],r[4], fmi$n))
  add(Section="T2_OS", Item="HR_FocalDel_vs_cnLOH", Sub="within Arm_independent", N=fmi$n,
      Estimate=r[1], CI_low=r[2], CI_high=r[3], P_value=r[4], Note="age+sex+logTMB+cancer")
}

## ---------- write mechanism per-sample table (arm-independent) ----------
mi_out <- p[grp=="Arm_independent", .(SAMPLE_ID, mech, arm_6p, ploidy=ploidy,
             HLA_A_tot=asc$tot[SAMPLE_ID, "HLA-A"], HLA_A_min=asc$minor[SAMPLE_ID, "HLA-A"],
             HLA_B_tot=asc$tot[SAMPLE_ID, "HLA-B"], HLA_B_min=asc$minor[SAMPLE_ID, "HLA-B"],
             HLA_C_tot=asc$tot[SAMPLE_ID, "HLA-C"], HLA_C_min=asc$minor[SAMPLE_ID, "HLA-C"])]
fwrite(mi_out, file.path(OUT, "r3p3_armindependent_mechanism.tsv"), sep="\t")
fwrite(rbindlist(rows, fill=TRUE), file.path(OUT, "r3p3_task2_rows.tsv"), sep="\t")
saveRDS(p, file.path(OUT, "r3p3_p_annot.rds"))
cat("\nSTEP3 (task2) done\n")
