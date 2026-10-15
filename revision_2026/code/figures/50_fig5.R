###############################################################################
# 50_fig5.R — Figure 5: 生存
#   A 五癌种 HR 森林（非整倍体校正前后并列）
#   B 泛癌 HR（未校正 / 校正 / +非整倍体），图内注明过度校正、不得解读为保护
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))
## 用户指定「字符宽度/高度」级精确位移工具（量测 → 换算 → 施加到真实 artist）
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_shift.R"))

F5W <- 6.85; F5H <- 6.4

## ---------- A ----------
a5 <- fread(file.path(IMD, "fig5a_hr_cancer.tsv"))
a5[, model := factor(model, levels = c("Unadjusted (age, sex, TMB)", "+ aneuploidy"))]
ord <- c("Prostate Cancer", "Renal Cell Carcinoma", "Bladder Cancer",
         "Non-Small Cell Lung Cancer", "Breast Cancer")
a5 <- a5[cancer %in% ord]
a5[, cancer := factor(cancer, levels = rev(ord))]
XLA <- c(0.7, 3.6)
a5[, row := as.integer(cancer)]
a5[model == "Unadjusted (age, sex, TMB)", ypos := row + 0.16]
a5[model == "+ aneuploidy", ypos := row - 0.16]
a5[, ann := sprintf("%.3f (%.3f\u2013%.3f)", HR, lo, hi)]
p5a <- ggplot(a5, aes(y = ypos)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  geom_errorbarh(aes(xmin = lo, xmax = hi, colour = model), height = 0.17, linewidth = 0.4) +
  geom_point(aes(x = HR, colour = model), size = 1.5) +
  geom_text(data = a5[model == "Unadjusted (age, sex, TMB)"],
            aes(x = 1.72, label = ann), hjust = 0, size = 5.0 / 2.845, colour = "grey15") +
  geom_text(data = a5[model == "+ aneuploidy"],
            aes(x = 1.72, label = ann), hjust = 0, size = 5.0 / 2.845, colour = PAL[["teal"]]) +
  scale_x_log10(limits = XLA, breaks = c(0.8, 1, 1.5, 2, 3)) +
  scale_y_continuous(breaks = 1:5, labels = rev(ord),
                     limits = c(0.45, 5.55), expand = c(0, 0)) +
  scale_colour_manual(values = c("Unadjusted (age, sex, TMB)" = PAL[["navy"]],
                                 "+ aneuploidy" = PAL[["teal"]]), name = NULL) +
  labs(title = "A  HLA LOH and overall survival by cancer type",
       subtitle = "Cox models: unadjusted for aneuploidy (filled, upper row) versus + aneuploidy fraction (lower row)",
       x = "Hazard ratio for overall survival (log scale)", y = NULL) +
  theme_pub() +
  theme(legend.position = "top", legend.text = element_text(size = 5.4),
        legend.key.size = unit(0.24, "cm"), axis.text.y = element_text(size = 5.6),
        panel.grid.major.y = element_blank())

## ---- 用户指定精确位移（QC_user_adjust_round1 item 7）------------------------
##  Fig5A 的 HR 数值标签**整体向右移动 25 个字符宽度**。
##  字符宽 char_w = 标签 bbox 宽 / 可见字符数（PDF 文本层实测）；面板实际尺寸取自
##  PDF 矢量层实测。偏移改写该 geom_text 图层映射里的常数 x（原 1.72），
##  未手填坐标、未改动误差棒/数据点/轴等任何其它图层。
stopifnot(nrow(shift_labels("Fig5A")) == 10)
shift_model_check(p5a, "Fig5A", const_x = 1.72, logx = TRUE)
p5a <- shift_text_const_x(p5a, "Fig5A", const_x = 1.72, d_chars = 25, logx = TRUE)

## ---------- B ----------
b5 <- fread(file.path(IMD, "fig5b_hr_pancancer.tsv"))
b5[, ord := match(model, c("fitU", "fit0", "fit1"))]
setorder(b5, ord)
dtB <- data.table(label = c("Unadjusted",
                            "Adjusted (age, sex, TMB, WGD, cancer type)",
                            "+ aneuploidy fraction (over-adjusted)"),
                  est = b5$HR, lo = b5$lo, hi = b5$hi, P = b5$P,
                  group = c("Unadjusted", "Adjusted", "Over-adjusted"),
                  is_null = FALSE)
dtB[, y := rev(seq_len(.N))]
XL5B <- c(0.80, 1.32); YL5B <- c(0.4, 4.9)
ng <- b5$N[1]
nbB <- note_box(c("Over-adjustment: aneuploidy lies on the",
                  "causal path and is collinear with HLA LOH.",
                  "HR < 1 must NOT be read as protection."),
                plot_w_in = 4.6, plot_h_in = 2.4, xlim = XL5B, ylim = YL5B,
                x_center_norm = 55, y_top_norm = 94, fontsize = 5.0)
p5b <- forest_panel(dtB, xlim = XL5B, vline = 1, logx = FALSE, txt_cex = 5.0, lab_size = 5.4,
                    col_map = c("Unadjusted" = PAL[["navy"]], "Adjusted" = PAL[["teal"]],
                                "Over-adjusted" = PAL[["red"]]),
                    title = sprintf("B  Pan-cancer overall survival (n = %s; %s deaths)",
                                    format(ng, big.mark = ","), format(10101, big.mark = ",")),
                    xlab = "Hazard ratio for overall survival") +
  scale_y_continuous(breaks = dtB$y, labels = dtB$label, limits = YL5B) +
  nbB$rect + nbB$text

## ---- 用户指定精确位移（QC_user_adjust_round1 item 8）------------------------
##  Fig5B 的 HR 数值标签**第 2 个（自上而下）向右移动 32 个字符宽度**。
##  序号与逐字文本见 QC_user_adjust_round1/target_labels_report_before.md：
##    第 1 个 = `1.212 (1.161–1.266)`（Unadjusted）
##    第 2 个 = `1.062 (1.015–1.112)`（Adjusted (age, sex, TMB, WGD, cancer type)）← 本次移动对象
##    第 3 个 = `0.938 (0.895–0.984)`（+ aneuploidy fraction (over-adjusted)）
##  偏移经 pt → 数据单位换算后写入驱动该 geom_text 图层的映射列 tx_pos（线性 x 轴）。
stopifnot(nrow(dtB) == nrow(shift_labels("Fig5B")))
shift_model_check(p5b, "Fig5B", x_col = "tx_pos", logx = FALSE)
p5b <- shift_text_x(p5b, "Fig5B", col = "tx_pos", rows = 2, d_chars = 32, logx = FALSE)


# 标题/副标题按可用宽度自动折行（防溢出画布）
p5a <- wrap_headers(p5a, F5W)
p5b <- wrap_headers(p5b, F5W)

fig5 <- p5a / p5b + plot_layout(heights = c(1, 1.05))
cat("Fig5B note-box layout (flow_layout):\n"); print(nbB$layout)
qa_emit("Figure5", p5a, F5W, F5H * 1 / 2.05, tag = "Fig5A", fs = 5.0)
qa_emit("Figure5", p5b, F5W, F5H * 1.05 / 2.05, tag = "Fig5B", fs = 5.0)
save_pub2(fig5, "Figure5_survival", F5W, F5H)
