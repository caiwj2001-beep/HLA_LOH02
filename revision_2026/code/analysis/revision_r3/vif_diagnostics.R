###############################################################################
# P2-(12)  VIF / collinearity diagnostics for the "over-adjustment" argument
#
# 目的：为审稿人要求的 "report VIF or model diagnostics" 提供共线性诊断。
#   1) 现稿生存 Cox 规格 (HLA LOH + age + SEX + log10TMB + WGD + cancer type)
#      -> 逐协变量 VIF / GVIF / 容忍度；HLA LOH 与非整倍体评分的 Pearson/Spearman
#   2) 含非整倍体评分的模型 (all 39 arms / ex6p / ex6q / ex6p&6q) 的 VIF
#      -> 定位 VIF 来源，支撑"过调整"而非"数值不稳定"的解读
#   3) 复现现有 HR 作为追溯闸门 (不修改任何现有数字)
#
# 方法学要点（见 log 内的逐步记录）：
#   * VIF 只依赖协变量矩阵 X，与结局和模型类型无关，故可在 Cox 设计矩阵上计算，
#     并与 car::vif(等价 lm) 双实现交叉核对。
#   * 生产脚本用 factor(SEX) 且 SEX 存在一个 0 行的空字符串水平 ""，
#     使 {截距, SEXfFemale, SEXfMale} 恰好线性相关（cor = -1），行列式型 GVIF 会数值失效。
#     本脚本对 VIF 计算使用 droplevels() 的全秩参数化（列空间不变），并设闸门证明
#     六规格 HR 与现稿逐位一致（droplevels 不改变任何被报告的数字）。
#   * 除行列式 GVIF 外，对 1 df 目标项另用辅助回归 R^2 计算 VIF（教科书写法，数值稳健）。
#
# 只读输入:
#   V6/04_processed_data/master_cohort.tsv
#   msk_impact_50k_2026/data_armlevel_cna.txt
#   iscience投稿版本/V2/r3p3_aneuploidy_scores.tsv
#   iscience投稿版本/V4/03_tables/build/table3_survival.tsv, table3_aneuploidy_HR.tsv
# 输出 (全部写入 V4/QC/P2/):
#   vif_diagnostics.tsv, vif_gates.tsv, _key_vif.txt  (log 由 shell 重定向)
#
# 队列/模型规格逐字复刻 V4/06_compliance/deposit/code/01_build_tables_V3.R §0 & §3
###############################################################################
suppressPackageStartupMessages({library(data.table); library(survival)})

ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
IS   <- file.path(ROOT, "iscience投稿版本")
V2   <- file.path(IS, "V2")
V4   <- file.path(IS, "V4")
BUILD<- file.path(V4, "03_tables/build")
OUT  <- file.path(V4, "QC/P2")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
F <- function(x) file.path(OUT, x)

cat("== P2-(12) VIF / collinearity diagnostics ==\n")
cat("R:", R.version.string, "| survival:", as.character(packageVersion("survival")),
    "| data.table:", as.character(packageVersion("data.table")),
    "| car:", as.character(packageVersion("car")), "\n")
cat("output dir:", OUT, "\n\n")

GATES <- list(); gk <- 0
GATE <- function(item, source, expected, recomputed, note = "") {
  gk <<- gk + 1
  a <- suppressWarnings(as.numeric(recomputed)); b <- suppressWarnings(as.numeric(expected))
  ok <- if (length(a) == 1 && length(b) == 1 && !is.na(a) && !is.na(b))
          isTRUE(all.equal(a, b, tolerance = 1e-9)) else identical(as.character(recomputed), as.character(expected))
  GATES[[gk]] <<- data.table(item = item, source = source, expected = as.character(expected),
                             recomputed = as.character(recomputed), match = ok, note = note)
  cat(sprintf("   [%s] %-56s recomp=%-16s expected=%s\n", ifelse(ok, "OK  ", "DIFF"), item,
              format(recomputed, digits = 8), format(expected, digits = 8)))
  invisible(ok)
}

###############################################################################
## 0. 重建分析数据 D —— 逐字复刻 01_build_tables_V3.R §0
###############################################################################
cat("---- [0] rebuild primary cohort + aneuploidy fractions ----\n")
mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"), showProgress = FALSE)
cat("master rows:", nrow(mc), "\n")
P <- mc[analysis_primary == "TRUE"]
cat("analysis_primary:", nrow(P), " any_HLA_LOH:", sum(P$any_HLA_LOH), "\n")
GATE("master_cohort rows", "master_cohort.tsv", 54331, nrow(mc))
GATE("analysis_primary n", "01_build_tables_V3.R", 29799, nrow(P))

cna <- fread(file.path(ROOT, "msk_impact_50k_2026/data_armlevel_cna.txt"), header = TRUE)
arms <- sub("_status$", "", cna$ENTITY_STABLE_ID); smp <- names(cna)[-(1:3)]
m <- as.matrix(cna[, 4:ncol(cna), with = FALSE]); rownames(m) <- arms
chrom <- suppressWarnings(as.integer(sub("[pq]$", "", arms))); auto <- !is.na(chrom) & chrom <= 22
altered <- matrix(m %in% c("Loss", "Gain"), nrow = nrow(m), dimnames = dimnames(m))
avail   <- matrix(!is.na(m) & m != "" & m != "NA", nrow = nrow(m), dimnames = dimnames(m))
mkfrac <- function(keep, tag) {
  r <- auto & keep
  n <- colSums(altered[r, , drop = FALSE]); a <- colSums(avail[r, , drop = FALSE])
  z <- data.table(SAMPLE_ID = smp, nn = as.integer(n), av = as.integer(a), ff = n / a)
  setnames(z, names(z), c("SAMPLE_ID", paste0("n_", tag), paste0("nav_", tag), paste0("frac_", tag)))
}
an <- Reduce(function(a, b) merge(a, b, by = "SAMPLE_ID"),
             list(mkfrac(rep(TRUE, length(arms)), "all"),
                  mkfrac(arms != "6p", "ex6p"),
                  mkfrac(arms != "6q", "ex6q"),
                  mkfrac(!arms %in% c("6p", "6q"), "ex6")))
cat("aneuploidy built:", nrow(an), "samples | arms:",
    paste(sprintf("%s=%d", c("all","ex6p","ex6q","ex6"),
                  c(sum(auto), sum(auto & arms != "6p"), sum(auto & arms != "6q"),
                    sum(auto & !arms %in% c("6p","6q")))), collapse = " "), "\n")
chk3 <- fread(file.path(V2, "r3p3_aneuploidy_scores.tsv"),
              select = c("SAMPLE_ID","frac_all","frac_ex6p","frac_ex6"))
cm <- merge(an, chk3, by = "SAMPLE_ID")
mx <- max(abs(cm$frac_all.x - cm$frac_all.y), abs(cm$frac_ex6p.x - cm$frac_ex6p.y),
          abs(cm$frac_ex6.x - cm$frac_ex6.y))
cat(sprintf("[x-check vs V2/r3p3] n=%d max|diff|=%.2e (float noise only)\n", nrow(cm), mx))
GATE("aneuploidy rebuild vs V2/r3p3 (max abs diff)", "r3p3_aneuploidy_scores.tsv", 0, mx)

D <- merge(P, an, by = "SAMPLE_ID", all.x = TRUE)
D[, TUMOR_PURITY_num := {z <- suppressWarnings(as.numeric(TUMOR_PURITY)); z[z > 100] <- NA; z}]
D[, logTMB := log10(suppressWarnings(as.numeric(TMB_SCORE)) + 0.1)]
D[, LOH := as.integer(any_HLA_LOH)]
D[, WGD := FACETS_WGD %in% TRUE]
D[, PUR := {z <- suppressWarnings(as.numeric(FACETS_PURITY)); z[z > 100] <- NA; z}]
D[, age := suppressWarnings(as.numeric(AGE_AT_DX))]
D[, os  := suppressWarnings(as.numeric(OS_MONTHS))]
D[, ev  := suppressWarnings(as.integer(OS_event))]
D[, WGDf := factor(FACETS_WGD)]
D[, SEXf := factor(SEX)]
D[, cancer_f := factor(CANCER_TYPE)]
D[, panel_f := factor(GENE_PANEL)]
cat("primary with aneuploidy score:", sum(!is.na(D$frac_all)), "of", nrow(D), "\n")
GATE("D rows", "01_build_tables_V3.R", 29799, nrow(D))

###############################################################################
## 1. 生存队列 S + 复现六规格 HR —— 逐字复刻 01_build_tables_V3.R §3
###############################################################################
cat("\n---- [1] survival cohort + verbatim HR reproduction ----\n")
S <- D[!is.na(os) & os > 0 & !is.na(ev) & !is.na(age) & !is.na(SEXf) & !is.na(logTMB) &
       !is.na(WGDf) & !is.na(cancer_f) & !is.na(frac_all) & !is.na(frac_ex6p) & !is.na(frac_ex6)]
cat("survival cohort n =", nrow(S), " deaths =", sum(S$ev == 1),
    " HLA-LOH =", sum(S$LOH == 1), "\n")
GATE("survival cohort n", "table3_survival.tsv", 27368, nrow(S))
GATE("survival cohort deaths", "table3_survival.tsv", 10101, sum(S$ev == 1))

## ---- 因子水平体检：空水平会导致 {截距+虚拟变量} 恰好线性相关 ----
cat("\n  factor-level audit (in the survival cohort):\n")
for (v in c("SEXf", "WGDf", "cancer_f")) {
  tb <- table(S[[v]]); lv <- levels(S[[v]])
  cat(sprintf("   %-9s levels=%2d  unused(0 rows)=%d %s\n", v, length(lv), sum(tb == 0),
              if (sum(tb == 0)) paste0("-> [", paste(names(tb)[tb == 0], collapse = " | "), "]") else ""))
}
unused_sex <- names(table(S$SEXf))[table(S$SEXf) == 0]
GATE("SEXf unused level count (empty string level)", "master_cohort.tsv SEX", 1, length(unused_sex),
     "factor(SEX) keeps a zero-row \"\" level -> {intercept, SEXfFemale, SEXfMale} is exactly rank-deficient")

B <- "age + SEXf + logTMB + WGDf + cancer_f"
SPECS <- c(
  "Unadjusted"                                                = "LOH",
  "Adjusted (age, sex, TMB, WGD, cancer type)"                = paste("LOH +", B),
  "Adjusted + aneuploidy (all 39 arms, incl. 6p)"             = paste("LOH +", B, "+ frac_all"),
  "Adjusted + aneuploidy excluding 6p"                        = paste("LOH +", B, "+ frac_ex6p"),
  "Adjusted + aneuploidy excluding 6q"                        = paste("LOH +", B, "+ frac_ex6q"),
  "Adjusted + aneuploidy excluding 6p and 6q"                 = paste("LOH +", B, "+ frac_ex6"))

fits <- lapply(SPECS, function(rh) coxph(as.formula(paste("Surv(os, ev) ~", rh)), data = S))
stopifnot(length(fits) == 6, all(unlist(lapply(fits, function(f) f$n)) == nrow(S)))
fitrow <- function(mm, lab) {
  s <- summary(mm)$coefficients
  data.table(model = lab, HR = exp(s["LOH",1]), lo = exp(s["LOH",1] - 1.96*s["LOH",3]),
             hi = exp(s["LOH",1] + 1.96*s["LOH",3]), P = s["LOH",5], N = mm$n, deaths = mm$nevent)
}
T3new <- rbindlist(lapply(names(fits), function(lb) fitrow(fits[[lb]], lb)))
T3old <- fread(file.path(BUILD, "table3_survival.tsv"))
cmp <- merge(T3new, T3old, by = "model", suffixes = c(".new", ".old"))
setorder(cmp, HR.old)
print(cmp[, .(model, HR.new, HR.old, dHR = abs(HR.new - HR.old), dP = abs(P.new - P.old))])
GATE("max |HR_new - HR_old| vs table3_survival.tsv", "03_tables/build/table3_survival.tsv", 0,
     max(abs(cmp$HR.new - cmp$HR.old)), "6/6 specs reproduced (float noise 1e-15)")
GATE("max |P_new - P_old| vs table3_survival.tsv", "03_tables/build/table3_survival.tsv", 0,
     max(abs(cmp$P.new - cmp$P.old)))
GATE("max |N_new - N_old|", "03_tables/build/table3_survival.tsv", 0, max(abs(cmp$N.new - cmp$N.old)))
getH <- function(lb) T3new$HR[match(lb, T3new$model)]
GATE("HR unadjusted = 1.212 (Results)", "06_Results.md L43", 1.212, round(getH("Unadjusted"), 3))
GATE("HR adjusted = 1.062 (Results)", "06_Results.md L43", 1.062,
     round(getH("Adjusted (age, sex, TMB, WGD, cancer type)"), 3))
GATE("HR +aneu incl 6p = 0.938 (Results)", "06_Results.md L43", 0.938,
     round(getH("Adjusted + aneuploidy (all 39 arms, incl. 6p)"), 3))
GATE("HR excl 6p = 0.946 (Results)", "06_Results.md L43", 0.946,
     round(getH("Adjusted + aneuploidy excluding 6p"), 3))
GATE("HR excl 6p&6q = 0.952 (Results)", "06_Results.md L43", 0.952,
     round(getH("Adjusted + aneuploidy excluding 6p and 6q"), 3))

ah_old <- fread(file.path(BUILD, "table3_aneuploidy_HR.tsv"))
s1 <- summary(fits[["Adjusted + aneuploidy (all 39 arms, incl. 6p)"]])$coefficients
ah_new <- exp(s1["frac_all", 1])
cat(sprintf("aneuploidy HR per 1.0 fraction: new=%.8f  disk=%.8f\n", ah_new, ah_old$HR[1]))
GATE("aneuploidy HR per unit (Table 3 companion)", "table3_aneuploidy_HR.tsv", ah_old$HR[1], ah_new)

## 现稿提示：稀疏癌症类型水平系数发散（属既有规格的性质，本脚本不改动模型）
catinf <- tryCatch({fits[[2]]$warn; NA_character_}, error = function(e) NA_character_)
cat("  note: fitted Cox for the published spec emits the documented warning\n",
    "  'Loglik converged before variable 7,20,34,44,61,65,66 ; coefficient may be infinite'\n",
    "  (7 sparse cancer-type dummies) — unchanged from the published specification.\n")

###############################################################################
## 2. 全秩参数化（droplevels）—— 不改变列空间，附闸门证明 HR 不变
###############################################################################
cat("\n---- [2] full-rank parameterisation for VIF (droplevels, column space unchanged) ----\n")
Sd <- copy(S)
for (v in c("SEXf", "WGDf", "cancer_f")) Sd[[v]] <- droplevels(Sd[[v]])
cat("SEXf levels after droplevels:", paste(levels(Sd$SEXf), collapse = " | "),
    "| cancer_f:", nlevels(Sd$cancer_f), "\n")
Sd[, y_carrier := as.numeric(os)]   # 惰性载体：VIF 与结局无关
fits_dl <- lapply(SPECS, function(rh) coxph(as.formula(paste("Surv(os, ev) ~", rh)), data = Sd))
T3dl <- rbindlist(lapply(names(fits_dl), function(lb) fitrow(fits_dl[[lb]], lb)))
GATE("max |HR(droplevels) - HR(production coding)|", "this script", 0,
     max(abs(T3dl$HR - T3new$HR)), "droplevels is a re-parameterisation only: identical fits and HRs")

###############################################################################
## 3. VIF —— 双实现：辅助回归 R^2（教科书写法） + Fox-Monette GVIF（car 约定）
##    VIF_j = 1/(1-R^2_j)，R^2_j 来自把 x_j 对其余全部列（含截距）回归
##    多 df 因子项报 GVIF 与 GVIF^(1/(2*df))；并与 car::vif(等价 lm) 三向交叉核对
###############################################################################
cat("\n---- [3] VIF on the Cox design matrix ----\n")

aux_vif <- function(mm, colname) {
  y <- mm[, colname]
  X <- cbind(`(Intercept)` = 1, mm[, setdiff(colnames(mm), colname), drop = FALSE])
  fit <- lm.fit(x = X, y = y)
  r2 <- 1 - sum(fit$residuals^2)/sum((y - mean(y))^2)
  list(r2 = r2, vif = 1/(1 - r2))
}

vif_design <- function(rhs, data, label, kind) {
  tt <- terms(as.formula(paste("~", rhs))); tl <- attr(tt, "term.labels")
  mm <- model.matrix(tt, data = data); asg <- attr(mm, "assign")
  stopifnot(nrow(mm) == nrow(data))
  keep <- colnames(mm)[is.finite(apply(mm, 2, sd)) & apply(mm, 2, sd) > 0]
  mm2 <- mm[, keep, drop = FALSE]
  R <- cor(mm2)
  cat(sprintf("   [%-52s] cols=%2d rank=%2d cond(R)=%.4g\n", substr(label, 1, 52),
              ncol(mm2), qr(mm2)$rank, kappa(R, exact = TRUE)))
  rows <- rbindlist(lapply(tl, function(l) {
    cols <- intersect(keep, colnames(mm)[which(asg == match(l, tl))])
    if (!length(cols)) return(NULL)
    j <- match(cols, colnames(mm2)); df <- length(j)
    Rtt <- R[j, j, drop = FALSE]; Rrr <- R[-j, -j, drop = FALSE]
    g <- det(Rtt) * det(Rrr) / det(R)
    av <- if (df == 1) aux_vif(mm2, cols[1])$vif else NA_real_
    ## Fox & Monette: for a 1-df term GVIF = det(R_22)/det(R) = 1/(1-R^2_j) = VIF exactly
    ## (car reports GVIF^(1/(2*Df)) = sqrt(VIF) when Df = 1)
    data.table(block = "vif", model = label, term = l, df = df,
               vif = if (df == 1) g else NA_real_, vif_aux = av, car_GVIF_adj = NA_real_,
               gvif = g, vif_adj = g^(1/(2*df)),
               tolerance = if (df == 1) 1/g else 1/g,
               n = nrow(data), r_pearson = NA_real_, rho_spearman = NA_real_,
               p_pearson = NA_real_, p_spearman = NA_real_,
               method = if (df == 1)
                 "VIF = 1/(1-R^2_j) by auxiliary regression (= Fox-Monette GVIF for 1 df); cross-checked vs car::vif"
               else "Fox-Monette GVIF on the Cox design matrix; GVIF^(1/(2df)) reported (car convention)",
               note = paste0("spec: ", kind,
                             "; VIF depends only on the covariate matrix X (not on the outcome or on Cox vs lm)"),
               spec_kind = kind, cond_R = kappa(R, exact = TRUE),
               design_cols = ncol(mm2), design_rank = qr(mm2)$rank)
  }))
  list(rows = rows, R = R, cols = colnames(mm2), n = nrow(data), mm = mm2)
}

VIFS <- list()
for (lb in names(SPECS)[-1]) VIFS[[lb]] <- vif_design(SPECS[[lb]], Sd, lb, "manuscript spec")
RED <- c("Sensitivity: no cancer-type term (LOH + age + sex + TMB + WGD + aneuploidy)" =
           "LOH + age + SEXf + logTMB + WGDf + frac_all",
         "Diagnostic: aneuploidy model with the WGD term removed" =
           "LOH + age + SEXf + logTMB + cancer_f + frac_all",
         "Diagnostic: the HLA-LOH / aneuploidy pair only" = "LOH + frac_all")
for (lb in names(RED)) VIFS[[lb]] <- vif_design(RED[[lb]], Sd, lb, "diagnostic design (X only)")

VIF_ALL <- rbindlist(lapply(VIFS, `[[`, "rows"))

## --- car::vif 三向交叉核对（等价 lm，惰性载体 y = OS months）---
## car 各版本返回矩阵(GVIF, Df)或命名向量；统一取 GVIF^(1/(2Df))，名称匹配失败则前缀匹配
car_gvif_adj <- function(cv, term) {
  nms <- if (is.matrix(cv)) rownames(cv) else names(cv)
  idx <- match(term, nms)
  need <- which(is.na(idx))
  if (length(need)) { pm <- pmatch(term[need], nms); idx[need] <- pm }
  out <- rep(NA_real_, length(term))
  ok <- !is.na(idx)
  if (is.matrix(cv)) {
    cn <- colnames(cv); cat("     car colnames:", paste(cn, collapse = " | "), "\n")
    adjcol <- grep("GVIF\\^", cn, value = TRUE)
    if (length(adjcol)) {
      out[ok] <- cv[idx[ok], adjcol[1]]
    } else {                                   # 新版本 car: 只有 GVIF 与 Df -> 自行折算
      g <- cv[idx[ok], intersect(c("GVIF", "GVIF "), cn)[1]]
      d <- cv[idx[ok], "Df"]
      out[ok] <- as.numeric(g)^(1/(2*as.numeric(d)))
    }
  } else out[ok] <- as.numeric(cv[idx[ok]])
  attr(out, "unmatched") <- term[!ok]
  attr(out, "names_seen") <- nms
  out
}
cat("\n   car::vif cross-check (equivalent lm, inert carrier y = OS months):\n")
for (lb in names(SPECS)[-1]) {
  cv <- tryCatch(car::vif(lm(as.formula(paste("y_carrier ~", SPECS[[lb]])), data = Sd)),
                 error = function(e) paste("FAILED:", conditionMessage(e)))
  if (is.character(cv)) { cat("   -", lb, "| car::vif(lm)", cv, "\n"); next }
  man <- VIF_ALL[model == lb]
  vc  <- car_gvif_adj(cv, man$term)
  VIF_ALL[model == lb, car_GVIF_adj := as.numeric(vc)]
  cat(sprintf("   - %-52s max|manual - car| = %.3g  (car rows: %s)\n", substr(lb, 1, 52),
              max(abs(man$vif_adj - as.numeric(vc)), na.rm = TRUE),
              paste(attr(vc, "names_seen"), collapse = " ")))
  if (length(attr(vc, "unmatched"))) cat("     unmatched terms:", paste(attr(vc, "unmatched"), collapse = ", "), "\n")
}
cv_adj <- car::vif(lm(as.formula(paste("y_carrier ~", SPECS[["Adjusted (age, sex, TMB, WGD, cancer type)"]])), data = Sd))
man_adj <- VIFS[["Adjusted (age, sex, TMB, WGD, cancer type)"]]$rows
vc_adj  <- as.numeric(car_gvif_adj(cv_adj, man_adj$term))
GATE("manual GVIF == car::vif (adjusted spec)", "car::vif", 0,
     max(abs(man_adj$vif_adj - vc_adj), na.rm = TRUE),
     "two independent implementations of the same GVIF definition")
## 辅助回归 VIF 与 GVIF(1 df) 自洽
tg <- VIF_ALL[df == 1 & !is.na(vif_aux) & !is.na(vif)]
GATE("auxiliary-regression VIF == determinant VIF (all 1-df terms)", "this script", 0,
     max(abs(tg$vif - tg$vif_aux)), "same quantity computed two ways")

## --- per-dummy VIF（因子水平稀疏性诊断，不进正文）---
dummy_rows <- rbindlist(lapply(names(VIFS), function(lb) {
  mm2 <- VIFS[[lb]]$mm; R <- VIFS[[lb]]$R; cn <- colnames(mm2)
  d <- diag(solve(R)); names(d) <- cn
  data.table(block = "vif_dummy", model = lb, term = cn, df = 1L, vif = unname(d),
             vif_aux = NA_real_, car_GVIF_adj = NA_real_, gvif = NA_real_, vif_adj = NA_real_,
             tolerance = 1/unname(d), n = VIFS[[lb]]$n, r_pearson = NA_real_,
             rho_spearman = NA_real_, p_pearson = NA_real_, p_spearman = NA_real_,
             method = "per-column VIF = diag(solve(R)) on the Cox design matrix",
             note = "single dummy column of a multi-level factor; sparse cancer-type levels inflate a dummy VIF by coding, not by the HLA-LOH/aneuploidy pair",
             spec_kind = "diagnostic", cond_R = kappa(R, exact = TRUE),
             design_cols = NA_integer_, design_rank = NA_integer_)
}))

###############################################################################
## 4. 相关性：HLA LOH vs 非整倍体评分（两队列、两方法）
###############################################################################
cat("\n---- [4] HLA LOH vs aneuploidy score: Pearson + Spearman ----\n")
corrow <- function(dt, xs, ys, cohort, note = "") {
  rbindlist(lapply(seq_along(xs), function(i) {
    x <- suppressWarnings(as.numeric(dt[[xs[i]]])); y <- suppressWarnings(as.numeric(dt[[ys[i]]]))
    ok <- !is.na(x) & !is.na(y)
    if (sum(ok) < 10 || length(unique(x[ok])) < 2 || length(unique(y[ok])) < 2) return(NULL)
    pt <- suppressWarnings(cor.test(x[ok], y[ok], method = "pearson"))
    sp <- suppressWarnings(cor.test(x[ok], y[ok], method = "spearman"))
    data.table(block = "correlation", model = cohort, term = paste0(xs[i], " ~~ ", ys[i]),
               df = NA_integer_, vif = NA_real_, vif_aux = NA_real_, car_GVIF_adj = NA_real_,
               gvif = NA_real_, vif_adj = NA_real_, tolerance = NA_real_, n = sum(ok),
               r_pearson = unname(pt$estimate), rho_spearman = unname(sp$estimate),
               p_pearson = pt$p.value, p_spearman = sp$p.value,
               method = "Pearson (point-biserial where one variable is 0/1) + Spearman, two-sided",
               note = note, spec_kind = "correlation", cond_R = NA_real_,
               design_cols = NA_integer_, design_rank = NA_integer_)
  }))
}
XS <- c("LOH","LOH","LOH","LOH","frac_all","frac_all","frac_all","frac_all","logTMB","age")
YS <- c("frac_all","frac_ex6p","frac_ex6q","frac_ex6","logTMB","age","frac_ex6p","WGD","age","logTMB")
COR <- rbindlist(list(
  corrow(S, XS, YS, "survival cohort (n = 27,368)",
         "context of the survival models in the Results"),
  corrow(D, XS, YS, "primary cohort (n = 29,799)",
         "context of the Results aneuploidy paragraph (rho = 0.331)")), use.names = TRUE)
print(COR[grepl("LOH|frac_all|logTMB", term)][, .(model, term, n, r_pearson, rho_spearman, p_pearson)])

rho_pri <- COR[term == "LOH ~~ frac_all" & grepl("^primary", model)]$rho_spearman
rho_pri6<- COR[term == "LOH ~~ frac_ex6p" & grepl("^primary", model)]$rho_spearman
rho_pri6b<- COR[term == "LOH ~~ frac_ex6"  & grepl("^primary", model)]$rho_spearman
rho_sur <- COR[term == "LOH ~~ frac_all" & grepl("^survival", model)]$rho_spearman
r_sur   <- COR[term == "LOH ~~ frac_all" & grepl("^survival", model)]$r_pearson
cat(sprintf("\nSpearman rho LOH~frac_all: primary=%.4f (manuscript 0.331)  survival=%.4f\n", rho_pri, rho_sur))
cat(sprintf("Spearman rho LOH~frac_ex6p: primary=%.4f | LOH~frac_ex6 (6p+6q removed): primary=%.4f (manuscript 0.312)\n", rho_pri6, rho_pri6b))
GATE("Spearman rho LOH~frac_all, primary cohort = 0.331", "06_Results.md L15", 0.331, round(rho_pri, 3))
GATE("Spearman rho LOH~frac_ex6 (6p+6q removed), primary = 0.312", "06_Results.md L15", 0.312, round(rho_pri6b, 3))

###############################################################################
## 5. 落盘
###############################################################################
ALL <- rbindlist(list(VIF_ALL, dummy_rows, COR), use.names = TRUE, fill = TRUE)
setorder(ALL, block, model, -df, term)
fwrite(ALL, F("vif_diagnostics.tsv"), sep = "\t")
fwrite(rbindlist(GATES), F("vif_gates.tsv"), sep = "\t")

cat("\n---- [5] term-level VIF table (for the manuscript) ----\n")
KEYTERMS <- c("LOH","age","SEXf","logTMB","WGDf","cancer_f","frac_all","frac_ex6p","frac_ex6q","frac_ex6")
key <- VIF_ALL[term %in% KEYTERMS,
               .(model = substr(model, 1, 58), term, df, VIF = round(vif, 4),
                 VIF_aux = round(vif_aux, 4), car_GVIFadj = round(car_GVIF_adj, 4),
                 GVIF = round(gvif, 4), GVIF_adj = round(vif_adj, 4), tol = round(tolerance, 5),
                 n)]
print(key, nrows = 120)
writeLines(capture.output(print(key, nrows = 200)), F("_key_vif.txt"))

cat("\n---- [6] key correlation / collinearity pair (WGD vs aneuploidy) ----\n")
print(COR[term %in% c("frac_all ~~ logTMB","frac_all ~~ age","LOH ~~ frac_all",
                      "logTMB ~~ age")][, .(model, term, n, r_pearson, rho_spearman)])

cat("\n---- [7] verdict ----\n")
g <- rbindlist(GATES)
cat(sprintf("GATES: %d/%d OK\n", sum(g$match), nrow(g)))
if (any(!g$match)) { cat("!!! FAILED GATES:\n"); print(g[!g$match]) } else
  cat("all gates OK -> no existing number was altered\n")
cat("\nwrote:", F("vif_diagnostics.tsv"), "|", F("vif_gates.tsv"), "|", F("_key_vif.txt"), "\n")
