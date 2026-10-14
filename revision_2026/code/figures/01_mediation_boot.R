###############################################################################
# 01_mediation_boot.R —— WGD→6p→HLA LOH 中介的 bootstrap CI（B=200, seed=42）
#   与 V6/03_scripts/13_sensitivity_mediation.R 同一估计量与同一 seed
#   产出 intermediate/fig3b_mediation_boot.tsv（仅在有需要时覆盖已有 CI）
###############################################################################
suppressPackageStartupMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
IMD  <- file.path(ROOT, "iscience投稿版本/V3/02_figures/intermediate")
set.seed(42)
m <- readRDS(file.path(ROOT, "V6/04_processed_data/master_cohort.rds"))
D <- m[analysis_primary == TRUE]
D[, WGD := FACETS_WGD == "TRUE"][, cancer_f := factor(CANCER_TYPE)]
Dm <- D[!is.na(WGD) & !is.na(arm_6p_loss) & !is.na(any_HLA_LOH)]
cat("mediation cohort N:", nrow(Dm), "\n")
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
  TOT <- ACME + ADE
  c(ACME = ACME, ADE = ADE, Total = TOT, PropMed = ACME / TOT)
}
pt <- mediate_once(Dm)
cat("point:", round(pt, 4), "\n")
B <- 200
boot <- matrix(NA, B, 4, dimnames = list(NULL, c("ACME", "ADE", "Total", "PropMed")))
idx <- seq_len(nrow(Dm)); t0 <- Sys.time()
for (b in 1:B) {
  bi <- sample(idx, replace = TRUE)
  boot[b, ] <- tryCatch(mediate_once(Dm[bi]), error = function(e) rep(NA, 4))
  if (b %% 20 == 0) cat(sprintf("  bootstrap %d/%d (%.0fs)\n", b, B,
                                as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}
ci <- function(x) quantile(x, c(.025, .975), na.rm = TRUE)
out <- data.table(
  Quantity = c("ACME (indirect, via 6p)", "ADE (direct)", "Total effect", "Proportion mediated"),
  Estimate = round(pt, 4),
  CI_low = round(c(ci(boot[, 1])[1], ci(boot[, 2])[1], ci(boot[, 3])[1], ci(boot[, 4])[1]), 4),
  CI_high = round(c(ci(boot[, 1])[2], ci(boot[, 2])[2], ci(boot[, 3])[2], ci(boot[, 4])[2]), 4),
  B = B, seed = 42, n = nrow(Dm))
fwrite(out, file.path(IMD, "fig3b_mediation_boot.tsv"), sep = "\t")
print(out)
cat("01_mediation_boot.R DONE\n")
