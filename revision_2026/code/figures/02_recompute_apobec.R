###############################################################################
# 02_recompute_apobec.R — Supplementary Fig S2 的中间结果（全部从 master_cohort 重算）
#   A 分布：APOBEC SBS 占比（HLA intact vs LOH，主队列，签名可用子集）
#   B 尾部对比：>0.90 与 >=0.50 两组比例 + Wilson 95%CI + Fisher P
#   C 组间差异效应量：log2(比例比) + 95%CI（delta 法）
#   口径核对：PINNED_PACK §2.4
###############################################################################
suppressPackageStartupMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
IMD <- file.path(ROOT, "iscience投稿版本/V3/02_figures/intermediate")
F <- function(x) file.path(IMD, x)
PIN <- list(); i <- 0
chk <- function(label, value, pinned, tol = 0.05) {
  i <<- i + 1
  ok <- tryCatch({
    num <- suppressWarnings(as.numeric(value)); pn <- suppressWarnings(as.numeric(pinned))
    if (length(value) == 0) FALSE
    else if (length(num) == 1 && length(pn) == 1 && !is.na(num) && !is.na(pn))
      isTRUE(all.equal(num, pn, tolerance = tol, scale = max(1, abs(pn))))
    else identical(as.character(value), as.character(pinned))
  }, error = function(e) FALSE)
  if (length(ok) != 1 || is.na(ok)) ok <- FALSE
  PIN[[i]] <<- data.table(item = label, recomputed = as.character(value),
                          PINNED = as.character(pinned), match = ok)
  cat(sprintf("  [%s] %-42s recomputed=%s PINNED=%s\n", ifelse(ok, "OK ", "DIFF"), label, value, pinned))
}
wilson <- function(k, n, z = qnorm(0.975)) {
  p <- k / n; d <- 1 + z^2 / n
  ctr <- (p + z^2 / (2 * n)) / d
  hw <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / d
  data.table(freq = p, lo = pmax(0, ctr - hw), hi = pmin(1, ctr + hw))
}

mc <- fread(file.path(ROOT, "V6/04_processed_data/master_cohort.tsv"), showProgress = FALSE)
P <- mc[analysis_primary == "TRUE"]
P[, apobec := suppressWarnings(as.numeric(sig_APOBEC))]
S <- P[sig_available == TRUE & !is.na(apobec)]
S[, group := ifelse(any_HLA_LOH, "HLA LOH", "HLA intact")]
cat("签名可用主队列 n =", nrow(S), "（intact", sum(S$group == "HLA intact"),
    "/ LOH", sum(S$group == "HLA LOH"), "）\n")

## A 分布
dis <- S[, .(SAMPLE_ID, group, apobec)]
dis[, pct := 100 * apobec]
fwrite(dis, F("figs2_apobec_dist.tsv"), sep = "\t")
summ <- S[, .(n = .N, n_zero = sum(apobec == 0), median = median(apobec),
              q1 = quantile(apobec, .25), q3 = quantile(apobec, .75),
              max = max(apobec), n_gt50 = sum(apobec >= 0.50),
              n_gt90 = sum(apobec > 0.90)), by = group]
fwrite(summ, F("figs2_apobec_summary.tsv"), sep = "\t")
cat("\n=== A 分布摘要 ===\n"); print(summ)

## B 尾部对比 + Fisher
tab <- function(thr, op) {
  k <- S[, .(k = if (op == ">") sum(apobec > thr) else sum(apobec >= thr)), by = group]
  n <- S[, .(n = .N), by = group]
  m <- merge(n, k, by = "group")
  m[, pct := 100 * k / n]
  m <- cbind(m, wilson(m$k, m$n))
  m[, `:=`(lo = 100 * lo, hi = 100 * hi)]
  m[, threshold := ifelse(op == ">", sprintf(">%.2f", thr), sprintf("\u2265%.2f", thr))]
  m
}
b90 <- tab(0.90, ">"); b50 <- tab(0.50, ">=")
fisher_p <- function(thr, op) {
  g <- S$group; v <- S$apobec
  hit <- if (op == ">") v > thr else v >= thr
  t <- table(factor(g, levels = c("HLA intact", "HLA LOH")), factor(hit, c(FALSE, TRUE)))
  fisher.test(t)$p.value
}
b90[, P := fisher_p(0.90, ">")]; b50[, P := fisher_p(0.50, ">=")]
b <- rbind(b90, b50)
fwrite(b, F("figs2_tail_comparison.tsv"), sep = "\t")
cat("\n=== B 尾部对比 ===\n"); print(b)

## C log2 比例比 + 95% CI（delta 法）
eff <- b[, .(threshold, group, k, n, pct)]
mk <- function(thr) {
  a <- b[threshold == thr & group == "HLA LOH"]; z <- b[threshold == thr & group == "HLA intact"]
  lr <- log((a$k / a$n) / (z$k / z$n))
  se <- sqrt(1 / a$k - 1 / a$n + 1 / z$k - 1 / z$n)
  data.table(threshold = thr, log2_ratio = lr / log(2),
             lo = (lr - 1.96 * se) / log(2), hi = (lr + 1.96 * se) / log(2),
             ratio = exp(lr), P = b[threshold == thr]$P[1],
             n_LOH = a$n, n_intact = z$n, n_LOH_hit = a$k, n_intact_hit = z$k)
}
ce <- rbind(mk(">0.90"), mk("\u22650.50"))
fwrite(ce, F("figs2_effect_sizes.tsv"), sep = "\t")
cat("\n=== C 效应量 ===\n"); print(ce)

## 口径核对
cat("\n=== PINNED §2.4 核对 ===\n")
chk("S2 签名可用主队列 n", nrow(S), 29484, 0)
chk("S2 >0.90 intact %", sprintf("%.2f", b90[group == "HLA intact"]$pct), "0.43", 0.02)
chk("S2 >0.90 intact 例数", b90[group == "HLA intact"]$k, 95, 0)
chk("S2 >0.90 LOH %", sprintf("%.2f", b90[group == "HLA LOH"]$pct), "0.27", 0.02)
chk("S2 >0.90 LOH 例数", b90[group == "HLA LOH"]$k, 20, 0)
chk("S2 >0.90 Fisher P", sprintf("%.3f", b90$P[1]), "0.053", 0.05)
chk("S2 >=0.50 intact %", sprintf("%.2f", b50[group == "HLA intact"]$pct), "4.98", 0.01)
chk("S2 >=0.50 LOH %", sprintf("%.2f", b50[group == "HLA LOH"]$pct), "5.88", 0.01)
chk("S2 >=0.50 Fisher P", sprintf("%.4f", b50$P[1]), "0.0026", 0.20)
pc <- rbindlist(PIN)
fwrite(pc, F("pin_check_S2.tsv"), sep = "\t")
cat("\nS2 PIN_CHECK: 总计", nrow(pc), " 一致", sum(pc$match), " 不符", sum(!pc$match), "\n")
if (any(!pc$match)) print(pc[match == FALSE])
cat("02_recompute_apobec.R DONE\n")
