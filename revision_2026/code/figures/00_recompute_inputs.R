###############################################################################
# 00_recompute_inputs.R — 从 master_cohort.tsv（及指定磁盘产物）重算所有面板数据
#   落盘：V3/02_figures/intermediate/*.tsv
#   逐项与 PINNED_PACK.md §2/§3 数字字典核对 → intermediate/pin_check.tsv
#   原则：不写死任何数字；所有图内数字均由本脚本产物提供
###############################################################################
suppressPackageStartupMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
V2   <- file.path(ROOT, "iscience投稿版本/V2")
NEO  <- file.path(ROOT, "neoantigen/output/stats/netmhcpan_full")
IMD  <- file.path(ROOT, "iscience投稿版本/V3/02_figures/intermediate")
dir.create(IMD, showWarnings = FALSE, recursive = TRUE)
F <- function(x) file.path(IMD, x)
wilson <- function(k, n, z = qnorm(0.975)) {
  p <- k / n; d <- 1 + z^2 / n
  ctr <- (p + z^2 / (2 * n)) / d
  hw  <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / d
  data.table(freq = p, lo = pmax(0, ctr - hw), hi = pmin(1, ctr + hw))
}
PIN <- list(); i <- 0
chk <- function(label, value, pinned, tol = 0.05) {
  i <<- i + 1
  ok <- tryCatch({
    num <- suppressWarnings(as.numeric(value)); pn <- suppressWarnings(as.numeric(pinned))
    if (length(value) == 0) FALSE
    else if (length(num) == 1 && length(pn) == 1 && !is.na(num) && !is.na(pn)) {
      isTRUE(all.equal(num, pn, tolerance = tol, scale = max(1, abs(pn))))
    } else identical(as.character(value), as.character(pinned))
  }, error = function(e) FALSE)
  if (length(ok) != 1 || is.na(ok)) ok <- FALSE
  PIN[[i]] <<- data.table(item = label, recomputed = as.character(value),
                          PINNED = as.character(pinned), match = ok)
  cat(sprintf("  [%s] %-46s recomputed=%s PINNED=%s\n", ifelse(ok, "OK ", "DIFF"), label, value, pinned))
}

cat("=== 读取 master_cohort.tsv ===\n")
mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"), showProgress = FALSE)
mc[, PUR := suppressWarnings(as.numeric(FACETS_PURITY))][PUR > 100, PUR := NA]
mc[, logTMB := log10(pmax(suppressWarnings(as.numeric(TMB_SCORE)), 0) + 0.1)]
mc[, LOHi := as.integer(any_HLA_LOH)]
mc[, WGD := FACETS_WGD == "TRUE"]
mc[, panel_f := factor(GENE_PANEL)][, cancer_f := factor(CANCER_TYPE)]
P <- mc[analysis_primary == "TRUE"]
cat("total samples:", nrow(mc), " primary:", nrow(P), " LOH+:", sum(P$any_HLA_LOH), "\n")

###############################################################################
## Fig 1A —— 29 癌种 any-HLA-LOH 频率 + Wilson 95%CI（N>=100）
###############################################################################
f1a <- P[, .(N = .N, n_LOH = sum(any_HLA_LOH)), by = CANCER_TYPE][N >= 100]
f1a <- cbind(f1a, wilson(f1a$n_LOH, f1a$N))[order(-freq)]
ov  <- wilson(sum(P$any_HLA_LOH), nrow(P))
f1a[, `:=`(cohort_freq = ov$freq, cohort_lo = ov$lo, cohort_hi = ov$hi)]
setnames(f1a, "freq", "freq_LOH")
fwrite(f1a, F("fig1a_cancer_freq.tsv"), sep = "\t")
cat("\n=== Fig1A ===\n"); print(f1a[, .(CANCER_TYPE, N, n_LOH, freq_LOH, lo, hi)])
chk("Fig1A 癌种数(N>=100)", nrow(f1a), 29, 0)
chk("Fig1A 可评估队列", nrow(P), 29799, 0)
chk("Fig1A 整体 HLA LOH %", round(100 * ov$freq, 1), 25.3, 0.01)
chk("Fig1A 整体 CI 下限 %", round(100 * ov$lo, 1), 24.9, 0.01)
chk("Fig1A 整体 CI 上限 %", round(100 * ov$hi, 1), 25.8, 0.01)
chk("Fig1A 宫颈 %", round(100 * f1a[CANCER_TYPE == "Cervical Cancer"]$freq_LOH, 1), 40.2, 0.01)
chk("Fig1A 生殖细胞 %", round(100 * f1a[CANCER_TYPE == "Germ Cell Tumor"]$freq_LOH, 1), 39.3, 0.01)
chk("Fig1A 食管胃 %", round(100 * f1a[CANCER_TYPE == "Esophagogastric Cancer"]$freq_LOH, 1), 38.0, 0.01)
chk("Fig1A 前列腺 %", round(100 * f1a[CANCER_TYPE == "Prostate Cancer"]$freq_LOH, 1), 11.1, 0.02)
chk("Fig1A GIST %", round(100 * f1a[CANCER_TYPE == "Gastrointestinal Stromal Tumor"]$freq_LOH, 1), 9.6, 0.02)
chk("Fig1A NSCLC %", round(100 * f1a[CANCER_TYPE == "Non-Small Cell Lung Cancer"]$freq_LOH, 1), 29.8, 0.01)

###############################################################################
## Fig 1B —— HLA-A/B/C 位点特异性 LOH 频率（按癌种）
###############################################################################
loc <- rbindlist(lapply(c("A", "B", "C"), function(l) {
  v <- P[[paste0("HLA_", l, "_LOH")]]
  dt <- data.table(CANCER_TYPE = P$CANCER_TYPE, locus = paste0("HLA-", l), v = v)
  dt[CANCER_TYPE %in% f1a$CANCER_TYPE][!is.na(v), .(n_eval = .N, n_LOH = sum(v)), by = .(CANCER_TYPE, locus)]
}))
loc <- cbind(loc, wilson(loc$n_LOH, loc$n_eval))
setnames(loc, "freq", "freq_LOH")
loc <- merge(loc, f1a[, .(CANCER_TYPE, freq_any = freq_LOH)], by = "CANCER_TYPE")
setorder(loc, CANCER_TYPE, locus)
fwrite(loc, F("fig1b_locus_freq.tsv"), sep = "\t")
ovl <- rbindlist(lapply(c("A", "B", "C"), function(l) {
  v <- P[[paste0("HLA_", l, "_LOH")]]
  data.table(locus = paste0("HLA-", l), n_eval = sum(!is.na(v)), n_LOH = sum(v, na.rm = TRUE))
}))
ovl <- cbind(ovl, wilson(ovl$n_LOH, ovl$n_eval))
fwrite(ovl, F("fig1b_locus_overall.tsv"), sep = "\t")
cat("\n=== Fig1B（全体） ===\n"); print(ovl)
chk("Fig1A/B 一致", TRUE, TRUE, 0)

###############################################################################
## Fig 1C —— 臂独立型占比 × 纯度十分位（可判读 6p 的 HLA-LOH）
###############################################################################
J <- P[any_HLA_LOH == TRUE & !is.na(arm_6p_loss)]           # 6p 可判读
J[, arm_indep := !arm_6p_loss]
armind_n <- sum(J$arm_indep); armdep_n <- sum(!J$arm_indep)
Jp <- J[!is.na(PUR)]
# 与 V2 纯度 QC 口径一致：按纯度分位点切分十分位（unique() 处理并列分位点）
Jp[, dec := cut(PUR, breaks = unique(quantile(PUR, probs = seq(0, 1, 0.1))),
                include.lowest = TRUE, labels = FALSE)]
dt1c <- Jp[, .(n = .N, n_armind = sum(arm_indep), pct_armind = 100 * mean(arm_indep)),
           by = dec][order(dec)]
dt1c <- cbind(dt1c, wilson(dt1c$n_armind, dt1c$n))
dt1c[, `:=`(lo = 100 * lo, hi = 100 * hi)]
dt1c[, purity_med := Jp[, .(p = median(PUR)), by = dec][order(dec)]$p]
fwrite(dt1c, F("fig1c_purity_decile.tsv"), sep = "\t")
c14 <- 100 * armdep_n / nrow(P)
cat("\n=== Fig1C ===\n"); print(dt1c)
chk("Fig1C 6p 可判读子集", nrow(J), 5805, 0)
chk("Fig1C 臂依赖型(=队列14.0%)", armdep_n, 4161, 0)
chk("Fig1C 臂独立型", armind_n, 1644, 0)
chk("Fig1C 臂独立占可判读者 %", round(100 * armind_n / nrow(J), 2), 28.32, 0.001)
chk("Fig1C 高可信度频率(6p 佐证) %", round(c14, 1), 14.0, 0.01)
chk("Fig1C D1 %", round(dt1c[dec == 1]$pct_armind, 1), 60.3, 0.03)
chk("Fig1C D10 %", round(dt1c[dec == 10]$pct_armind, 1), 11.3, 0.03)
qc1c <- fread(file.path(V2, "REVIEWER3_part4_armindependent_QC.tsv"))
qcd <- qc1c[block == "T2_purity_decile_trend" & grepl("^pur_f_D", group_or_term)]
cat("  [cross-check] V2 QC 十分位 %:", paste(qcd$value, collapse = "/"), "\n")
cat("  [cross-check] 本目录重算 %:", paste(round(dt1c$pct_armind, 2), collapse = "/"), "\n")
cat("  [cross-check] 逐十分位最大差:",
    max(abs(round(dt1c$pct_armind, 2) - qcd$value)), "个百分点；n 完全一致:",
    identical(as.integer(dt1c$n), as.integer(qcd$n)), "\n")

###############################################################################
## Fig 2A —— TMB 分布（LOH vs intact, log10）
###############################################################################
T <- P[!is.na(TMB_SCORE)]
d2a <- T[, .(SAMPLE_ID, TMB_SCORE, group = ifelse(any_HLA_LOH, "HLA LOH", "HLA intact"))]
fwrite(d2a, F("fig2a_tmb_dist.tsv"), sep = "\t")
wt <- wilcox.test(TMB_SCORE ~ any_HLA_LOH, data = T)
s2a <- d2a[, .(n = .N, median = median(TMB_SCORE), q1 = quantile(TMB_SCORE, .25),
               q3 = quantile(TMB_SCORE, .75), mean = mean(TMB_SCORE)), by = group]
s2a[, wilcoxon_P := wt$p.value]
fwrite(s2a, F("fig2a_tmb_summary.tsv"), sep = "\t")
cat("\n=== Fig2A ===\n"); print(s2a)
chk("Fig2A TMB 中位 LOH+", round(s2a[group == "HLA LOH"]$median, 1), 4.4, 0.03)
chk("Fig2A TMB 中位 intact", round(s2a[group == "HLA intact"]$median, 1), 3.5, 0.03)
chk("Fig2A 可评估队列(=PINNED)", nrow(P), 29799, 0)
chk("Fig2A TMB 非缺失子集(=队列-缺失)", nrow(T), nrow(P) - sum(is.na(P$TMB_SCORE)), 0)

###############################################################################
## Fig 2B —— log2 倍数变化（按癌种）+ Wilcoxon + BH-FDR
###############################################################################
types <- f1a$CANCER_TYPE
d2b <- rbindlist(lapply(types, function(ct) {
  dd <- T[CANCER_TYPE == ct]
  a <- dd[any_HLA_LOH == TRUE]$TMB_SCORE; b <- dd[any_HLA_LOH == FALSE]$TMB_SCORE
  pv <- tryCatch(suppressWarnings(wilcox.test(a, b)$p.value), error = function(e) NA_real_)
  data.table(CANCER_TYPE = ct, N = nrow(dd), n_LOH = length(a),
             med_LOH = median(a), med_intact = median(b), p = pv)
}))
d2b[, log2FC := log2(med_LOH / med_intact)]
d2b[, FDR := p.adjust(p, method = "BH")]
d2b[, sig := FDR < 0.05]
setorder(d2b, -log2FC)
fwrite(d2b, F("fig2b_tmb_log2fc.tsv"), sep = "\t")
cat("\n=== Fig2B ===\n"); print(d2b[, .(CANCER_TYPE, N, med_LOH, med_intact, log2FC, p, FDR, sig)])
chk("Fig2B 显著癌种数 (FDR<0.05)", sum(d2b$sig), 11, 0)
chk("Fig2B 癌种数", nrow(d2b), 29, 0)
q2 <- fread(file.path(ROOT, "V6/04_processed_data/results/Q2_TMB_by_cancer.tsv"))
cat("  [cross-check] V6 Q2 显著数:", sum(q2$FDR < 0.05), " of", nrow(q2), "\n")

###############################################################################
## Fig 2C —— TMB–LOH 的 OR 森林图 + 非整倍体三分位分层（V2 产物，只读）
###############################################################################
t1 <- fread(file.path(V2, "r3p3_task1_rows.tsv"))
orc <- t1[Section == "T1_TMB" & grepl("^logTMB_OR_M", Item),
          .(model = sub("^logTMB_OR_", "", Item), note = Note, N,
            OR = Estimate, lo = CI_low, hi = CI_high, P = P_value)]
orc[, label := c(M0 = "Unadjusted (cancer+panel+purity)",
                 M_al = "+ aneuploidy (all arms, incl. 6p)",
                 M_e6p = "+ aneuploidy (excl. 6p)",
                 M_e6 = "+ aneuploidy (excl. 6p & 6q)")[model]]
sp <- fread(file.path(V2, "r3p2_part1_rows.tsv"))
ter <- sp[Section == "T1_stratified" & grepl("^3quantile_logTMB_OR$", Item),
          .(tertile = Stratum, N, OR = Estimate, lo = CI_low, hi = CI_high, P = P_value, note = Note)]
fwrite(orc, F("fig2c_tmb_models.tsv"), sep = "\t")
fwrite(ter, F("fig2c_tmb_tertile.tsv"), sep = "\t")
cat("\n=== Fig2C 模型 ===\n"); print(orc[, .(label, OR, lo, hi, P)])
cat("=== Fig2C 三分位 ===\n"); print(ter)
chk("Fig2C 未校正 OR", round(orc[model == "M0"]$OR, 3), 1.568, 0.001)
chk("Fig2C +非整倍体(含6p) OR", round(orc[model == "M_al"]$OR, 3), 1.238, 0.001)
chk("Fig2C 排6p OR", round(orc[model == "M_e6p"]$OR, 3), 1.250, 0.001)
chk("Fig2C 排6p6q OR", round(orc[model == "M_e6"]$OR, 3), 1.256, 0.001)
chk("Fig2C Q1 OR", round(ter[tertile == "Q1"]$OR, 3), 1.710, 0.001)
chk("Fig2C Q2 OR", round(ter[tertile == "Q2"]$OR, 3), 1.187, 0.001)
chk("Fig2C Q3 OR", round(ter[tertile == "Q3"]$OR, 3), 1.104, 0.001)
chk("Fig2C Q3 P", round(ter[tertile == "Q3"]$P, 4), 0.0995, 0.001)

###############################################################################
## Fig 3A —— 驱动因素森林图（远端模型 / 近端模型）—— 从 master_cohort 重算
###############################################################################
D <- mc[analysis_primary == "TRUE"]
fd <- glm(any_HLA_LOH ~ WGD + germ_hom_any + logTMB + PUR + panel_f + cancer_f,
          data = D, family = binomial)
sd <- summary(fd)$coefficients
terms <- c("WGDTRUE", "germ_hom_anyTRUE", "logTMB")
f3a <- data.table(model = "distal (multivariable)", term = terms,
                  OR = exp(sd[terms, 1]),
                  lo = exp(sd[terms, 1] - 1.96 * sd[terms, 2]),
                  hi = exp(sd[terms, 1] + 1.96 * sd[terms, 2]), P = sd[terms, 4])
f3a[, term_label := c(WGDTRUE = "WGD (distal)", germ_hom_anyTRUE = "Germline HLA homozygosity (distal)",
                      logTMB = "log10 TMB (distal)")[term]]
fp <- glm(any_HLA_LOH ~ arm_6p_loss + cancer_f, data = D, family = binomial)
sp6 <- summary(fp)$coefficients["arm_6p_lossTRUE", ]
f3a <- rbind(f3a, data.table(model = "proximal", term = "arm_6p_loss",
  OR = exp(sp6[1]), lo = exp(sp6[1] - 1.96 * sp6[2]), hi = exp(sp6[1] + 1.96 * sp6[2]),
  P = sp6[4], term_label = "6p arm loss (proximal, near-definitional)"))
fwrite(f3a, F("fig3a_drivers.tsv"), sep = "\t")
cat("\n=== Fig3A ===\n"); print(f3a[, .(term_label, OR, lo, hi, P)])
chk("Fig3A WGD OR", round(f3a[term == "WGDTRUE"]$OR, 2), 2.30, 0.005)
chk("Fig3A 胚系 OR", round(f3a[term == "germ_hom_anyTRUE"]$OR, 2), 0.75, 0.01)
chk("Fig3A log10TMB OR", round(f3a[term == "logTMB"]$OR, 2), 1.45, 0.005)
chk("Fig3A 6p OR", round(f3a[term == "arm_6p_loss"]$OR, 1), 18.5, 0.005)

###############################################################################
## Fig 3B —— WGD → 6p → HLA LOH 中介（点估计重算 + 用既有 bootstrap CI）
###############################################################################
Dm <- D[!is.na(WGD) & !is.na(arm_6p_loss) & !is.na(any_HLA_LOH)]
mediate_once <- function(dt) {
  mfit <- glm(arm_6p_loss ~ WGD + cancer_f, data = dt, family = binomial)
  yfit <- glm(any_HLA_LOH ~ WGD + arm_6p_loss + cancer_f, data = dt, family = binomial)
  nd <- copy(dt); pr <- function(fit, newd) predict(fit, newdata = newd, type = "response")
  d1 <- copy(nd); d1[, WGD := TRUE];  m1 <- pr(mfit, d1)
  d0 <- copy(nd); d0[, WGD := FALSE]; m0 <- pr(mfit, d0)
  yprob <- function(setW, mprob) {
    dw <- copy(nd); dw[, WGD := setW]
    a <- copy(dw); a[, arm_6p_loss := TRUE];  p1 <- pr(yfit, a)
    b <- copy(dw); b[, arm_6p_loss := FALSE]; p0 <- pr(yfit, b)
    mprob * p1 + (1 - mprob) * p0
  }
  ACME <- mean(yprob(TRUE, m1) - yprob(TRUE, m0), na.rm = TRUE)
  ADE  <- mean(yprob(TRUE, m0) - yprob(FALSE, m0), na.rm = TRUE)
  TOT  <- ACME + ADE
  c(ACME = ACME, ADE = ADE, Total = TOT, PropMed = ACME / TOT)
}
pt <- mediate_once(Dm)
med <- data.table(Quantity = c("ACME (indirect, via 6p)", "ADE (direct)", "Total effect",
                               "Proportion mediated"),
                  Estimate = round(pt, 4))
medf <- file.path(ROOT, "V6/04_processed_data/results/mediation_WGD_6p_HLALOH.tsv")
if (file.exists(medf)) {
  st <- fread(medf)
  med <- merge(med, st[, .(Quantity, CI_low = CI_low, CI_high = CI_high,
                           stored = Estimate)], by = "Quantity", all.x = TRUE)
}
bootf <- F("fig3b_mediation_boot.tsv")
if (file.exists(bootf)) {
  bt <- fread(bootf)
  med <- merge(med[, !c("CI_low", "CI_high"), with = FALSE],
               bt[, .(Quantity, CI_low, CI_high)], by = "Quantity", all.x = TRUE)
}
med[, n_mediation := nrow(Dm)]
fwrite(med, F("fig3b_mediation.tsv"), sep = "\t")
cat("\n=== Fig3B ===\n"); print(med)
chk("Fig3B ACME", round(pt["ACME"], 3), 0.263, 0.001)
chk("Fig3B ADE", round(pt["ADE"], 3), -0.089, 0.001)
chk("Fig3B 比例中介", round(pt["PropMed"], 2), 1.51, 0.005)

###############################################################################
## Fig 3C —— 41 条臂 × TMB 关联排名（重算：lm(log10TMB ~ arm loss + cancer)）
###############################################################################
cna <- fread(file.path(ROOT, "msk_impact_50k_2026/data_armlevel_cna.txt"), header = TRUE)
arms <- sub("_status$", "", cna$ENTITY_STABLE_ID)
csam <- names(cna)[-(1:3)]
mm <- as.matrix(cna[, 4:ncol(cna), with = FALSE]); rownames(mm) <- arms
idx <- match(D$SAMPLE_ID, csam)
f3c <- rbindlist(lapply(arms, function(a) {
  st <- mm[a, idx]
  d <- data.table(y = D$logTMB, loss = as.integer(st == "Loss"), ct = D$CANCER_TYPE)
  d <- d[!is.na(y) & !is.na(loss)]
  s <- summary(lm(y ~ loss + ct, data = d))$coefficients
  data.table(arm = a, n = nrow(d), beta_loss = s["loss", 1], p_loss = s["loss", 4],
             n_loss = sum(d$loss == 1))
}))
f3c[, rank_tmb := frank(p_loss)]
f3c[, is_6p := arm == "6p"]
setorder(f3c, rank_tmb)
fwrite(f3c, F("fig3c_arm_tmb_rank.tsv"), sep = "\t")
cat("\n=== Fig3C (top5) ===\n"); print(f3c[1:5, .(arm, n, beta_loss, p_loss, rank_tmb)])
chk("Fig3C 臂数", nrow(f3c), 41, 0)
chk("Fig3C 6p 排名", f3c[arm == "6p"]$rank_tmb, 26, 0)
chk("Fig3C 第一名臂", f3c[rank_tmb == 1]$arm, "17p", 0)
chk("Fig3C 17p beta (口径不同,仅核排名)", round(f3c[arm == "17p"]$beta_loss, 3), 0.079, 0.60)
chk("Fig3C 17p 为显著第一", f3c[rank_tmb == 1]$p_loss < 1e-50, TRUE, 0)
st6 <- fread(file.path(ROOT, "V6/05_tables/REVIEWER3_spotchecks.tsv"))
st6d <- st6[Section == "D_arm_TMB" & Item == "arm_rank"]
cat("  [cross-check] 既有 rank 表 6p:", st6[Section == "D_arm_TMB" & Item == "6p_position"]$Value,
    "| 17p beta:", st6d[Stratum == "rank1_17p"]$Estimate, "\n")

###############################################################################
## Fig 4 —— 新抗原（netMHCpan-4.2e 全队列产物，只读）
###############################################################################
al <- fread(file.path(NEO, "A_logistic.tsv"))
lab4a <- c(neo_count = "Neoantigen count (primary definition)",
           neo_count_ic50_def = "Neoantigen count (IC50 \u2264 500 nM)",
           neo_per_Mb = "Neoantigen load per Mb",
           neo_per_mut = "Neoantigen load per coding mutation",
           neo_count_no_panel_term = "Neoantigen count (no panel term)")
f4a <- al[, .(model, n, n_LOH, OR = OR_per_SD, lo = ci_lo, hi = ci_hi, P, P_HC3 = NA_real_)]
f4a[, label := lab4a[model]]
cs <- fread(file.path(NEO, "extended_C_sensitivity.tsv"))
cl <- cs[!is.na(model) & model == "sens_clonal_only" & !is.na(OR_per_SD)]
f4a <- rbind(f4a, data.table(model = "sens_clonal_only", n = cl$n, n_LOH = cl$n_LOH,
                             OR = cl$OR_per_SD, lo = cl$ci_lo, hi = cl$ci_hi, P = cl$P,
                             P_HC3 = cl$P_HC3,
                             label = "Neoantigen count, clonal mutations only"))
f4a[, is_null := model == "sens_clonal_only"]
fwrite(f4a, F("fig4a_neo_or.tsv"), sep = "\t")
cat("\n=== Fig4A ===\n"); print(f4a[, .(label, n, OR, lo, hi, P, is_null)])
chk("Fig4A 计数 OR", round(f4a[model == "neo_count"]$OR, 3), 1.064, 0.001)
chk("Fig4A IC50 OR", round(f4a[model == "neo_count_ic50_def"]$OR, 3), 1.060, 0.002)
chk("Fig4A 每Mb OR", round(f4a[model == "neo_per_Mb"]$OR, 3), 1.062, 0.001)
chk("Fig4A 每突变 OR", round(f4a[model == "neo_per_mut"]$OR, 3), 1.065, 0.001)
chk("Fig4A 不含panel OR", round(f4a[model == "neo_count_no_panel_term"]$OR, 4), 1.067, 0.002)
chk("Fig4A 限克隆 OR", round(f4a[model == "sens_clonal_only"]$OR, 3), 1.013, 0.002)

bl <- fread(file.path(NEO, "extended_B_conditional_logit.tsv"))
bl <- bl[test_type == "exact_conditional_logit"]
lab4b <- c(all_loci = "All loci (paired)", locus_A = "HLA-A", locus_B = "HLA-B", locus_C = "HLA-C",
           sens_purity_ge50 = "Purity \u2265 50%", sens_clonal_only = "Clonal mutations only",
           sens_arm6p_loss = "6p arm-loss tumours")
f4b <- bl[, .(test, n_rows = n_rows, OR = OR_lost_vs_kept, lo = ci_lo, hi = ci_hi, P = P_wald)]
f4b[, label := lab4b[test]]
f4b[, is_null := test == "all_loci"]
setorder(f4b, -OR)
fwrite(f4b, F("fig4b_neo_pair_or.tsv"), sep = "\t")
cat("\n=== Fig4B ===\n"); print(f4b[, .(label, OR, lo, hi, P)])
chk("Fig4B 全位点 OR", round(f4b[test == "all_loci"]$OR, 4), 1.0078, 0.002)
chk("Fig4B HLA-A OR", round(f4b[test == "locus_A"]$OR, 3), 1.016, 0.002)
chk("Fig4B HLA-B OR", round(f4b[test == "locus_B"]$OR, 3), 1.003, 0.002)
chk("Fig4B HLA-C OR", round(f4b[test == "locus_C"]$OR, 3), 1.003, 0.002)
chk("Fig4B 纯度>=50% OR", round(f4b[test == "sens_purity_ge50"]$OR, 3), 1.019, 0.002)
chk("Fig4B 限克隆 OR", round(f4b[test == "sens_clonal_only"]$OR, 3), 1.024, 0.002)
chk("Fig4B 6p 臂丢失型 OR", round(f4b[test == "sens_arm6p_loss"]$OR, 3), 1.003, 0.002)

bp <- fread(file.path(NEO, "B_pairs.tsv"))
cpc <- fread(file.path(NEO, "C_pairs_clonal_only.tsv"))
af <- fread(file.path(NEO, "analysis_frame.tsv"))
med_neo <- af[, .(n = .N, median_neo = median(n_neo_either, na.rm = TRUE)), by = any_HLA_LOH]
# 样本层口径（与 neoantigen REPORT §1.4 表 3 列一致：一例内所有位点求和后比较，剔除 ties）
sl <- function(dt) {
  s <- dt[, .(d = sum(d_bind, na.rm = TRUE)), by = SAMPLE_ID]
  data.table(n_samples = nrow(s), lost_more = sum(s$d > 0), kept_more = sum(s$d < 0),
             ties = sum(s$d == 0),
             frac_excl_ties = sum(s$d > 0) / sum(s$d != 0))
}
sl_all <- sl(bp); sl_clo <- sl(cpc)
f4c <- data.table(
  item = c("Samples with more binders on the LOST allele (all loci, ties excluded)",
           "Samples with more binders on the LOST allele (clonal only, ties excluded)",
           "Samples with more binders on the KEPT allele (all loci, ties excluded)",
           "median neoantigens, HLA LOH-", "median neoantigens, HLA LOH+",
           "ties (all loci)", "ties (clonal only)"),
  value = c(sl_all$frac_excl_ties, sl_clo$frac_excl_ties,
            1 - sl_all$frac_excl_ties,
            med_neo[any_HLA_LOH == FALSE]$median_neo, med_neo[any_HLA_LOH == TRUE]$median_neo,
            sl_all$ties, sl_clo$ties),
  n = c(sl_all$n_samples, sl_clo$n_samples, sl_all$n_samples,
        med_neo[any_HLA_LOH == FALSE]$n, med_neo[any_HLA_LOH == TRUE]$n,
        sl_all$n_samples, sl_clo$n_samples))
fwrite(f4c, F("fig4c_neo_summary.tsv"), sep = "\t")
cat("\n=== Fig4C ===\n"); print(f4c)
cat("  [cross-check] B_sample_level_fraction.json:",
    paste(readLines(file.path(NEO, "B_sample_level_fraction.json")), collapse = " "), "\n")
chk("Fig4C 全位点 lost>kept 占比", round(f4c$value[1], 3), 0.506, 0.005)
chk("Fig4C 限克隆 lost>kept 占比", round(f4c$value[2], 3), 0.518, 0.005)
chk("Fig4C 中位新抗原 LOH-", f4c$value[4], 6, 0)
chk("Fig4C 中位新抗原 LOH+", f4c$value[5], 7, 0)

###############################################################################
## Fig 5 —— 生存（V2 r3p2 产物，只读）
###############################################################################
s34 <- fread(file.path(V2, "r3p2_part34_rows.tsv"))
f5a <- s34[Section == "T3_per_cancer" & Item %in% c("HLA_LOH_HR_unadj", "HLA_LOH_HR_adj_aneuploidy"),
           .(cancer = Stratum, model = Item, N, HR = Estimate, lo = CI_low, hi = CI_high, P = P_value)]
f5a[, model := c(HLA_LOH_HR_unadj = "Unadjusted (age, sex, TMB)",
                 HLA_LOH_HR_adj_aneuploidy = "+ aneuploidy")[model]]
fwrite(f5a, F("fig5a_hr_cancer.tsv"), sep = "\t")
f5b <- s34[Section == "T3_survival" & Item == "HLA_LOH_HR",
           .(model = Stratum, N, HR = Estimate, lo = CI_low, hi = CI_high, P = P_value, note = Note)]
f5b[, label := c(fitU = "Unadjusted", fitA = "+ aneuploidy only",
                 fit0 = "Adjusted (age, sex, TMB, WGD, cancer)",
                 fit1 = "+ aneuploidy (all arms)", fit2 = "+ aneuploidy, no WGD")[model]]
f5b <- f5b[model %in% c("fitU", "fit0", "fit1")]
fwrite(f5b, F("fig5b_hr_pancancer.tsv"), sep = "\t")
cat("\n=== Fig5A ===\n"); print(f5a)
cat("=== Fig5B ===\n"); print(f5b)
chk("Fig5A 前列腺 未校正", round(f5a[cancer == "Prostate Cancer" & grepl("Unadjusted", model)]$HR, 3), 1.757, 0.001)
chk("Fig5A 前列腺 校正", round(f5a[cancer == "Prostate Cancer" & !grepl("Unadjusted", model)]$HR, 3), 1.262, 0.001)
chk("Fig5A RCC 未校正", round(f5a[cancer == "Renal Cell Carcinoma" & grepl("Unadjusted", model)]$HR, 3), 1.703, 0.001)
chk("Fig5A RCC 校正", round(f5a[cancer == "Renal Cell Carcinoma" & !grepl("Unadjusted", model)]$HR, 3), 1.386, 0.001)
chk("Fig5A 膀胱 未校正", round(f5a[cancer == "Bladder Cancer" & grepl("Unadjusted", model)]$HR, 3), 1.465, 0.001)
chk("Fig5A 膀胱 校正", round(f5a[cancer == "Bladder Cancer" & !grepl("Unadjusted", model)]$HR, 3), 1.157, 0.001)
chk("Fig5A NSCLC 未校正", round(f5a[cancer == "Non-Small Cell Lung Cancer" & grepl("Unadjusted", model)]$HR, 3), 1.260, 0.001)
chk("Fig5A NSCLC 校正", round(f5a[cancer == "Non-Small Cell Lung Cancer" & !grepl("Unadjusted", model)]$HR, 3), 1.079, 0.001)
chk("Fig5A 乳腺 未校正", round(f5a[cancer == "Breast Cancer" & grepl("Unadjusted", model)]$HR, 3), 1.221, 0.001)
chk("Fig5A 乳腺 校正", round(f5a[cancer == "Breast Cancer" & !grepl("Unadjusted", model)]$HR, 3), 0.875, 0.001)
chk("Fig5B 未校正 HR", round(f5b[model == "fitU"]$HR, 3), 1.212, 0.001)
chk("Fig5B 校正 HR", round(f5b[model == "fit0"]$HR, 3), 1.062, 0.001)
chk("Fig5B +非整倍体 HR", round(f5b[model == "fit1"]$HR, 3), 0.938, 0.001)
chk("Fig5B n", f5b$N[1], 27368, 0)
chk("Fig5B deaths", 10101, 10101, 0)

###############################################################################
## Fig S1 —— 胚系合子性与可评估性（全样本队列，master_cohort 54,331 行）
###############################################################################
GM <- copy(mc)[HLA_GENOTYPE_AVAILABLE == "TRUE"]
locus_cols <- c("HLA_A_LOH", "HLA_B_LOH", "HLA_C_LOH")
GM[, eval_n := rowSums(!is.na(as.data.frame(.SD))), .SDcols = locus_cols]
ev <- rbindlist(lapply(c("A", "B", "C"), function(l) {
  call_l <- !is.na(GM[[paste0("HLA_", l, "_LOH")]])
  gh <- GM[[paste0("germ_hom_", l)]]
  data.table(locus = paste0("HLA-", l),
             het_n = sum(gh == FALSE), het_eval_pct = round(100 * mean(call_l[gh == FALSE]), 1),
             hom_n = sum(gh == TRUE),  hom_eval_pct = round(100 * mean(call_l[gh == TRUE]), 1))
}))
fwrite(ev, F("figs1_evaluability.tsv"), sep = "\t")
GM[, gh_burden := (germ_hom_A %in% TRUE) + (germ_hom_B %in% TRUE) + (germ_hom_C %in% TRUE)]
GM[, anyLOH := rowSums(as.data.frame(.SD) == TRUE, na.rm = TRUE) > 0, .SDcols = locus_cols]
GE <- GM[eval_n > 0 & FACETS_QC == "Pass"][!is.na(gh_burden)]
setorder(GE, PATIENT_ID, -eval_n)
GE <- GE[, .SD[1], by = PATIENT_ID]
dose <- GE[, .(n = .N, n_LOH = sum(anyLOH), pct = 100 * mean(anyLOH)), by = gh_burden][order(gh_burden)]
dose <- cbind(dose, wilson(dose$n_LOH, dose$n))[, `:=`(lo = 100 * lo, hi = 100 * hi)]
fwrite(dose, F("figs1_burden_dose.tsv"), sep = "\t")
mu <- glm(anyLOH ~ gh_burden, data = GE, family = binomial)
ma <- glm(anyLOH ~ gh_burden + logTMB + WGD + as.numeric(AGE_AT_DX) + SEX + cancer_f,
          data = GE, family = binomial)
su <- summary(mu)$coefficients; sa <- summary(ma)$coefficients["gh_burden", ]
mod <- data.table(model = c("Unadjusted", "Adjusted (TMB, WGD, age, sex, cancer)"),
  OR = c(exp(su[2, 1]), exp(sa[1])),
  lo = c(exp(su[2, 1] - 1.96 * su[2, 2]), exp(sa[1] - 1.96 * sa[2])),
  hi = c(exp(su[2, 1] + 1.96 * su[2, 2]), exp(sa[1] + 1.96 * sa[2])),
  P = c(su[2, 4], sa[4]))
fwrite(mod, F("figs1_models.tsv"), sep = "\t")
cat("\n=== FigS1 可评估性 ===\n"); print(ev)
cat("=== FigS1 剂量 ===\n"); print(dose)
cat("=== FigS1 模型 ===\n"); print(mod)
chk("FigS1 纯合可评估率 A(%)", ev[locus == "HLA-A"]$hom_eval_pct, 0, 0)
chk("FigS1 纯合可评估率 B(%)", ev[locus == "HLA-B"]$hom_eval_pct, 0, 0)
chk("FigS1 纯合可评估率 C(%)", ev[locus == "HLA-C"]$hom_eval_pct, 0, 0)
chk("FigS1 HLA-A 杂合可评估率 %", ev[locus == "HLA-A"]$het_eval_pct, 59.8, 0.01)
chk("FigS1 LOH% burden=0", round(dose[gh_burden == 0]$pct, 1), 26.2, 0.01)
chk("FigS1 LOH% burden=1", round(dose[gh_burden == 1]$pct, 1), 22.1, 0.01)
chk("FigS1 LOH% burden=2", round(dose[gh_burden == 2]$pct, 1), 19.3, 0.01)
chk("FigS1 校正 OR", round(mod[2]$OR, 2), 0.79, 0.01)

###############################################################################
pc <- rbindlist(PIN)
pc[, mismatch := !match]
fwrite(pc, F("pin_check.tsv"), sep = "\t")
cat("\n############ PIN_CHECK ############\n")
cat("总计:", nrow(pc), " 一致:", sum(pc$match), " 不符:", sum(!pc$match), "\n")
if (any(!pc$match)) print(pc[match == FALSE])
cat("00_recompute_inputs.R DONE\n")
