###############################################################################
# 70_figS2.R — Supplementary Figure S2: 胚系合子性与 HLA LOH 可评估性
#   （修回重编号：原 60_figS1.R / Supplementary Figure S1 —— 胚系图在正文首现晚于 APOBEC 图，
#     改挂 Supplementary Figure S2。面板 A/B/C 与全部数字不变。）
#   A 位点 × 合子性的可评估率（纯合位点 0%）
#   B 合子性负担（0/1/2 个纯合位点）与体细胞 HLA LOH 频率
#   C 每增加一个纯合位点的 OR（未校正/校正）—— 方法学下限陈述
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))

QCDIR <- file.path(FIGDIR, "QC_user_adjust_round1")
dir.create(QCDIR, showWarnings = FALSE, recursive = TRUE)

SW <- 6.85; SH <- 5.4
ev <- fread(file.path(IMD, "figs1_evaluability.tsv"))
dose <- fread(file.path(IMD, "figs1_burden_dose.tsv"))
mod <- fread(file.path(IMD, "figs1_models.tsv"))

eva <- melt(ev, id.vars = "locus",
            measure.vars = list(pct = c("het_eval_pct", "hom_eval_pct"),
                                n = c("het_n", "hom_n")))
eva[, zyg := c("heterozygous", "homozygous")[variable]]
eva[, zyg := factor(zyg, levels = c("heterozygous", "homozygous"))]
eva[, lab := ifelse(variable == 1,
                    sprintf("%.1f%%\n(n=%s)", pct, format(n, big.mark = ",")),
                    sprintf("%.0f%%\n(n=%s)", pct, format(n, big.mark = ",")))]
pS1a <- ggplot(eva, aes(x = locus, y = pct, fill = zyg)) +
  geom_col(position = position_dodge(0.7), width = 0.6) +
  geom_text(aes(y = pmax(pct, 2.5) + 2.0, label = lab), position = position_dodge(0.7),
            vjust = 0.1, size = 4.6 / 2.845, colour = "grey15", lineheight = 0.9) +
  scale_fill_manual(values = c("heterozygous" = PAL[["navy"]], "homozygous" = PAL[["grey"]]),
                    name = "Germline zygosity") +
  scale_y_continuous(limits = c(0, 88), breaks = seq(0, 80, 20)) +
  labs(title = "A  Evaluability of somatic HLA LOH",
       subtitle = "Homozygous loci are never callable (tautological, not biological)",
       x = NULL, y = "Evaluable for HLA LOH (%)") +
  theme_pub() +
  theme(legend.position = "top", legend.text = element_text(size = 5.2),
        legend.key.size = unit(0.22, "cm"), legend.title = element_text(size = 5.2))

## ---- [Round1] 用户精确位移要求（只改位置，不改任何数字/统计量）---------------
## 10. 图 S2B：第 2、3 列的数字向上移动 3 个字符高度。
##     本面板 x 轴为 0/1/2 三个离散列（左→右 = 第 1、2、3 列）→ 被移动的是
##     gh_burden = 1 与 gh_burden = 2 两组柱顶的数值标签（"22.1%\nn= 3,978"、
##     "19.3%\nn= 1,230"）。列号口径由 FIGS2B_MOVE_COLS 单一变量控制。
##     图 S2C：OR（森林图数值列，即面板中的「HR 值」）全部向右移动 25 个字符宽度。
## 字符宽/高量测必须在交付口径 ragg 设备上进行（见 fig_common.R::measure_text_dev）。
FIGS2B_MOVE_COLS  <- c(2L, 3L)   # 第 2、3 列（x 轴 0/1/2 自左向右计数）
FIGS2B_N_CHAR_UP  <- 3           # 上移 3 个字符高度
FIGS2B_LABEL_FS   <- 4.8         # 图 S2B 数值标签字号（pt，未改动）
FIGS2C_N_CHAR_R   <- 25          # 图 S2C OR 数值列右移 25 个字符宽度
FIGS2C_TXT_CEX    <- 4.8         # forest_panel 中数值列字号（pt，未改动）
###############################################################################

pS1b <- ggplot(dose, aes(x = factor(gh_burden), y = pct)) +
  geom_col(fill = PAL[["teal"]], width = 0.5) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.16, colour = "grey30", linewidth = 0.35) +
  geom_text(aes(label = sprintf("%.1f%%\nn=%s", pct, format(n, big.mark = ","))),
            vjust = -0.35, size = 4.8 / 2.845, colour = "grey15", lineheight = 0.9) +
  scale_y_continuous(limits = c(0, 36), breaks = seq(0, 30, 10)) +
  labs(title = "B  Somatic HLA LOH by germline homozygosity burden",
       subtitle = "One tumour per patient; bars = Wilson 95% CI",
       x = "Homozygous germline HLA class I loci (0/1/2)", y = "HLA LOH frequency (%)") +
  theme_pub()

dtC <- data.table(label = c("Unadjusted", "Adjusted (TMB, WGD,\nage, sex, cancer)"),
                  est = mod$OR, lo = mod$lo, hi = mod$hi, P = mod$P,
                  group = c("Unadjusted", "Adjusted"), is_null = FALSE)
## 数值标签（OR 列）的实际文本 —— 用于字符宽量测（与 forest_panel 内部一致）
FIGS2C_LAB <- sprintf("%.3f (%.3f\u2013%.3f)", dtC$est, dtC$lo, dtC$hi)

# 标题/副标题按可用宽度自动折行（防溢出画布）
pS1a <- wrap_headers(pS1a, SW / 2 * 1.02)
pS1b <- wrap_headers(pS1b, SW / 2 * 0.98)

## ============================================================================
## [Round1] 量测 → 换算 → 施加到真实 artist（所有数值来自量测，无手填坐标）
## ============================================================================
## ① 交付口径真实 panel 尺寸（栅格反解）：拼版后的真实 panel ≠ 单图 gtable 推算值
pS1c_base <- wrap_headers(forest_panel(dtC, xlim = c(0.70, 1.0), vline = 1, logx = TRUE,
                                       txt_cex = 4.8, lab_size = 5.0,
                                       col_map = c("Unadjusted" = PAL[["navy"]],
                                                   "Adjusted" = PAL[["teal"]]),
                                       title = "C  Odds ratio per homozygous locus",
                                       xlab = "Odds ratio for HLA LOH (log scale)") +
                            theme(axis.text.y = element_text(size = 5.0)), SW)
figS2_probe <- (pS1a | pS1b) / pS1c_base + plot_layout(heights = c(1, 0.62))
PBX <- raster_panel_boxes(figS2_probe, SW, SH, dpi = 300, pad_frac = 0.03)
cat("\n[FigS2] 交付口径真实 panel 尺寸（栅格反解，英寸）：\n"); print(PBX, row.names = FALSE)
if (is.null(PBX) || nrow(PBX) < 1) stop("panel 边框反解失败：未检出任何 panel")
PANEL_S2A <- pick_panel(PBX, "top", "left")
PANEL_S2B <- pick_panel(PBX, "top", "right")    # 上排右侧 = FigS2B
PANEL_S2C <- pick_panel(PBX, "bottom", "left")  # 下排 = FigS2C
cat(sprintf("[FigS2] FigS2B panel 实测 %.4f x %.4f in | FigS2C panel 实测 %.4f x %.4f in\n",
            PANEL_S2B$w_in, PANEL_S2B$h_in, PANEL_S2C$w_in, PANEL_S2C$h_in))

## ② 字符宽/高（交付口径 ragg 设备量测）
CHAR_H_S2B <- char_h_in(FIGS2B_LABEL_FS)
CHAR_W_S2C <- char_w_in(FIGS2C_LAB, FIGS2C_TXT_CEX)
cat(sprintf("[FigS2] 字符量测：S2B 标签 fs=%.1f → 字符高 %.4f in (%.3f pt) | S2C 数值列 fs=%.1f → 平均字符宽 %.4f in (%.3f pt)\n",
            FIGS2B_LABEL_FS, CHAR_H_S2B, CHAR_H_S2B * 72, FIGS2C_TXT_CEX,
            CHAR_W_S2C, CHAR_W_S2C * 72))

## ③ 真实 data 范围
PP_B <- ggplot_build(pS1b)$layout$panel_params[[1]]
PP_C <- ggplot_build(pS1c_base)$layout$panel_params[[1]]
YR_B <- PP_B$y.range
cat(sprintf("[FigS2] S2B y 范围=(%.4f, %.4f) span=%.4f | S2C x 范围(log10 空间)=(%.5f, %.5f) span=%.5f\n",
            YR_B[1], YR_B[2], diff(YR_B), PP_C$x.range[1], PP_C$x.range[2], diff(PP_C$x.range)))
cat("[FigS2] S2B 各列（自左向右）逐字标签：\n")
for (i in seq_len(nrow(dose)))
  cat(sprintf("       第 %d 列 | gh_burden=%s | '%.1f%%\\nn=%s'%s\n", i, dose$gh_burden[i], dose$pct[i],
              format(dose$n[i], big.mark = ","),
              ifelse(i %in% FIGS2B_MOVE_COLS, "   <== 需上移", "")))
cat("[FigS2] S2C OR（「HR 值」）数值列逐字：\n")
for (i in seq_len(nrow(dtC)))
  cat(sprintf("       %-32s | %s\n", gsub("\n", " / ", dtC$label[i]), FIGS2C_LAB[i]))

## ④ 10（S2B）：第 2、3 列数字上移 3 个字符高度 → y 方向 data 位移
DY_S2B <- FIGS2B_N_CHAR_UP * CHAR_H_S2B / PANEL_S2B$h_in * diff(YR_B)
cat(sprintf("[FigS2] 10(S2B) 上移量：%d × %.4f in = %.4f in（= panel 高的 %.3f%%）→ Δy = %.4f data（y span %.1f）\n",
            FIGS2B_N_CHAR_UP, CHAR_H_S2B, FIGS2B_N_CHAR_UP * CHAR_H_S2B,
            100 * FIGS2B_N_CHAR_UP * CHAR_H_S2B / PANEL_S2B$h_in, DY_S2B, diff(YR_B)))
dose[, y_lab := pct + ifelse(seq_len(.N) %in% FIGS2B_MOVE_COLS, DY_S2B, 0)]
pS1b <- ggplot(dose, aes(x = factor(gh_burden), y = pct)) +
  geom_col(fill = PAL[["teal"]], width = 0.5) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.16, colour = "grey30", linewidth = 0.35) +
  geom_text(aes(y = y_lab, label = sprintf("%.1f%%\nn=%s", pct, format(n, big.mark = ","))),
            vjust = -0.35, size = FIGS2B_LABEL_FS / 2.845, colour = "grey15", lineheight = 0.9) +
  scale_y_continuous(limits = c(0, 36), breaks = seq(0, 30, 10)) +
  labs(title = "B  Somatic HLA LOH by germline homozygosity burden",
       subtitle = "One tumour per patient; bars = Wilson 95% CI",
       x = "Homozygous germline HLA class I loci (0/1/2)", y = "HLA LOH frequency (%)") +
  theme_pub()
pS1b <- wrap_headers(pS1b, SW / 2 * 0.98)
cat(sprintf("       位移后各列标签 y（data）：%s\n",
            paste(sprintf("%.3f", dose$y_lab), collapse = ", ")))

## ⑤ 10（S2C）：OR 数值列整体右移 25 个字符宽度 → 换算成 log10 空间位移
SHIFT_T <- FIGS2C_N_CHAR_R * CHAR_W_S2C / PANEL_S2C$w_in * diff(PP_C$x.range)
cat(sprintf("[FigS2] 10(S2C) 右移量：%d × %.4f in = %.4f in（= panel 宽的 %.3f%%）→ Δlog10 = %.6f（x log10 span %.5f）\n",
            FIGS2C_N_CHAR_R, CHAR_W_S2C, FIGS2C_N_CHAR_R * CHAR_W_S2C,
            100 * FIGS2C_N_CHAR_R * CHAR_W_S2C / PANEL_S2C$w_in, SHIFT_T, diff(PP_C$x.range)))
pS1c <- forest_panel(dtC, xlim = c(0.70, 1.0), vline = 1, logx = TRUE, txt_cex = FIGS2C_TXT_CEX,
                     lab_size = 5.0,
                     col_map = c("Unadjusted" = PAL[["navy"]], "Adjusted" = PAL[["teal"]]),
                     title = "C  Odds ratio per homozygous locus",
                     xlab = "Odds ratio for HLA LOH (log scale)",
                     ann_shift_t = SHIFT_T) +
  theme(axis.text.y = element_text(size = 5.0))
pS1c <- wrap_headers(pS1c, SW)
TX_OLD <- exp(log(1.0) - 0.58 * (log(1.0) - log(0.70)))
cat(sprintf("       位移后 OR 数值列 x（data）：%s（原 %.4f）\n",
            paste(sprintf("%.4f", TX_OLD * 10^SHIFT_T), collapse = ", "), TX_OLD))

fwrite(data.table(
  item = c("FigS2B_move_cols", "FigS2B_move_chars_required", "FigS2B_label_fontsize",
           "FigS2B_char_h_in", "FigS2B_panel_w_in", "FigS2B_panel_h_in", "FigS2B_dy_data",
           "FigS2B_moved_labels",
           "FigS2C_move_chars_required", "FigS2C_label_fontsize", "FigS2C_char_w_in",
           "FigS2C_panel_w_in", "FigS2C_panel_h_in", "FigS2C_dlog10", "FigS2C_panel_log10_span",
           "FigS2C_shift_in"),
  value = c(paste(FIGS2B_MOVE_COLS, collapse = ","), as.character(FIGS2B_N_CHAR_UP),
            sprintf("%.2f", FIGS2B_LABEL_FS), sprintf("%.6f", CHAR_H_S2B),
            sprintf("%.6f", PANEL_S2B$w_in), sprintf("%.6f", PANEL_S2B$h_in), sprintf("%.6f", DY_S2B),
            paste(sprintf("col%d[gh=%s]'%.1f%%\\nn=%s'", FIGS2B_MOVE_COLS, dose$gh_burden[FIGS2B_MOVE_COLS],
                          dose$pct[FIGS2B_MOVE_COLS], format(dose$n[FIGS2B_MOVE_COLS], big.mark = ",")),
                  collapse = " | "),
            as.character(FIGS2C_N_CHAR_R), sprintf("%.2f", FIGS2C_TXT_CEX),
            sprintf("%.6f", CHAR_W_S2C), sprintf("%.6f", PANEL_S2C$w_in),
            sprintf("%.6f", PANEL_S2C$h_in), sprintf("%.6f", SHIFT_T),
            sprintf("%.6f", diff(PP_C$x.range)), sprintf("%.6f", FIGS2C_N_CHAR_R * CHAR_W_S2C))),
  file.path(QCDIR, "S2_measure_steps.tsv"))
fwrite(PBX, file.path(QCDIR, "S2_panel_boxes_raster.tsv"), sep = "\t")
fwrite(data.table(panel = c(rep("FigS2B", nrow(dose)), rep("FigS2C", nrow(dtC))),
                  col_left_to_right = c(seq_len(nrow(dose)), seq_len(nrow(dtC))),
                  x_or_axis = c(paste0("gh_burden=", dose$gh_burden, " (x=", seq_len(nrow(dose)), ")"),
                                paste0("OR row ", seq_len(nrow(dtC)))),
                  label = c(sprintf("%.1f%% / n=%s", dose$pct, format(dose$n, big.mark = ",")),
                            FIGS2C_LAB),
                  moved = c(seq_len(nrow(dose)) %in% FIGS2B_MOVE_COLS, rep(TRUE, nrow(dtC)))),
       file.path(QCDIR, "S2_labels.tsv"), sep = "\t")

## ---------- 组装 FigS2（施加位移）----------
figS1 <- (pS1a | pS1b) / pS1c + plot_layout(heights = c(1, 0.62))
qa_emit("FigureS2", pS1a, SW / 2 * 1.02, SH * 1 / 1.62, tag = "FigS2A", fs = 4.8)
qa_emit("FigureS2", pS1b, SW / 2 * 0.98, SH * 1 / 1.62, tag = "FigS2B", fs = 4.8)
qa_emit("FigureS2", pS1c, SW, SH * 0.62 / 1.62, tag = "FigS2C", fs = 4.8)
save_pub2(figS1, "SupplementaryFigureS2_germline", SW, SH)
