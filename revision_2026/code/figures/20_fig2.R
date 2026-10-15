###############################################################################
# 20_fig2.R — Figure 2: 机制（远端/近端驱动因素、WGD→6p 中介、41 臂 × TMB 排名）
#   （修回重编号：原 30_fig3.R / Figure 3 —— 机制图在正文首现早于 TMB 图，改挂 Figure 2）
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))

## ===========================================================================
## Round1 用户微调（量测 → 换算 → 施加到真实 artist）
##   量测基准：QC_user_adjust_round1/measured_constants.tsv（由 m5_measure.py 用
##   pymupdf 从现行成品 PDF 反解；char_w_pt = 渲染 bbox 宽 / 可见字符数，
##   pt_per_data(_x) / pt_per_lnunit 由刻度标签中心或已知锚点最小二乘得到）。
##   位移 = 字符数 × 实测字宽 ÷ 实测 pt-per-data（绝对不做手填坐标/目测缩放）。
## ===========================================================================
UA_DIR  <- file.path(FIGDIR, "QC_user_adjust_round1")
UA_FILE <- file.path(UA_DIR, "measured_constants.tsv")
if (!file.exists(UA_FILE)) stop("Round1: missing measured constants file: ", UA_FILE)
ua_const <- fread(UA_FILE)
ua_get <- function(it, ky) {
  v <- ua_const[ua_const$item == it & ua_const$key == ky, ]$value
  stopifnot(length(v) == 1L, is.finite(v))
  as.numeric(v)
}
ua_log <- list()
ua_rec <- function(item, key, value, unit, note = "")
  ua_log[[length(ua_log) + 1L]] <<- data.table(item = item, qkey = key,
                                               value = value, unit = unit, note = note)

F3W <- 6.85; F3H <- 7.4

## ---------- A 驱动因素森林图 ----------
d3a <- fread(file.path(IMD, "fig3a_drivers.tsv"))
dtA <- data.table(
  label = c("WGD (\u2192 distal driver)",
            "Germline HLA homozygosity (distal driver)",
            "log10 TMB (distal driver)",
            "6p arm loss (proximal, near-definitional)"),
  est = d3a$OR, lo = d3a$lo, hi = d3a$hi, P = d3a$P,
  group = c("Distal model: WGD + germline + TMB + purity + panel + cancer type",
            "Distal model: WGD + germline + TMB + purity + panel + cancer type",
            "Distal model: WGD + germline + TMB + purity + panel + cancer type",
            "Proximal model: 6p loss + cancer type"))
dtA[, is_null := FALSE]
p3a <- forest_panel(dtA, xlim = c(0.5, 400), vline = 1, logx = TRUE, txt_cex = 5.2, lab_size = 5.6,
                    col_map = c("Distal model: WGD + germline + TMB + purity + panel + cancer type" = PAL[["navy"]],
                                "Proximal model: 6p loss + cancer type" = PAL[["red"]]),
                    title = "A  Drivers of HLA LOH: distal (upstream biology) versus proximal (6p21.3) models",
                    xlab = "Odds ratio for HLA LOH (log scale; 6p is near-definitional)")

## ---- ③ Fig2A：右侧 HR(OR) 估计值列整体左移 14 个字符宽 ---------------------
##  x 轴为 log10：屏幕左移 L pt ≡ 乘以 exp(-L / pt_per_lnunit)（实测 pt-per-ln-unit）
ua_lA <- ua_get("Fig2A", "n_chars_requested") * ua_get("Fig2A", "char_w_pt")
ua_kA <- exp(-ua_lA / ua_get("Fig2A", "pt_per_lnunit"))
stopifnot("tx_pos" %in% names(p3a$data))
p3a$data$tx_pos_orig <- p3a$data$tx_pos                 # 留档：原锚点（数据坐标）
p3a$data$tx_pos      <- p3a$data$tx_pos * ua_kA        # 施加到真实 artist 的映射列
ua_rec("Fig2A", "dln_lnunit", -ua_lA / ua_get("Fig2A", "pt_per_lnunit"), "ln-unit",
       sprintf("-%d x char_w(%.5f pt) / pt_per_lnunit(%.5f)", ua_get("Fig2A", "n_chars_requested"),
               ua_get("Fig2A", "char_w_pt"), ua_get("Fig2A", "pt_per_lnunit")))
ua_rec("Fig2A", "x_factor", ua_kA, "ratio", "tx_pos_new = tx_pos_old * x_factor")
ua_rec("Fig2A", "dx_pt", ua_lA, "pt", "requested 14 char widths to the left")
ua_rec("Fig2A", "labels_moved", paste(p3a$data$ann, collapse = " | "), "text",
       paste(p3a$data$label, collapse = " | "))
cat(sprintf("[UA-3] Fig2A: char_w=%.5f pt/char, pt_per_lnunit=%.5f -> dx=%.4f pt left; x %.5f -> %.5f\n",
            ua_get("Fig2A", "char_w_pt"), ua_get("Fig2A", "pt_per_lnunit"), ua_lA,
            p3a$data$tx_pos_orig[1], p3a$data$tx_pos[1]))
cat(sprintf("        moved labels (est (lo-hi)): %s\n", paste(p3a$data$ann, collapse = " | ")))

## ---------- B WGD → 6p → HLA LOH 中介 ----------
md <- fread(file.path(IMD, "fig3b_mediation.tsv"))
## [缺陷修复 §4.1] “Proportion mediated” 行会被下面的 ord 过滤丢弃（既有缺陷：脚本先过滤
##   再取数 → numeric(0) → sprintf 返回 character(0) → 注释框只剩 1 行，第 1 行从未渲染）。
##   修法：在过滤前先取该行的 Estimate（不改数字、不改其它行）。恢复后 note_box 因 lines 由
##   1 行变 2 行，框高自动由 25% 增至 35%（框顶锚定不变，向下增高）。
ua_pmd <- md[Quantity == "Proportion mediated"]$Estimate
stopifnot(length(ua_pmd) == 1L, is.finite(ua_pmd))
md[, ord := match(Quantity, c("ACME (indirect, via 6p)", "ADE (direct)", "Total effect"))]
md <- md[!is.na(ord)]
setorder(md, ord)
dtB <- data.table(label = c("ACME: indirect effect via 6p arm loss",
                            "ADE: direct effect of WGD",
                            "Total effect of WGD"),
                  est = md$Estimate[1:3], lo = md$CI_low[1:3], hi = md$CI_high[1:3],
                  P = NA_real_, group = "Mediation decomposition",
                  is_null = FALSE)
dtB[, y := rev(seq_len(.N))]
XL3B <- c(-0.14, 0.34); YL3B <- c(0.4, 5.2)
nbB <- note_box(c(sprintf("Proportion mediated = %.2f (>1 indicates suppression:", ua_pmd),
                  "the direct and indirect paths act in opposite directions)"),
                plot_w_in = 5.0, plot_h_in = 1.6, xlim = XL3B, ylim = YL3B,
                x_center_norm = 55, y_top_norm = 94, fontsize = 5.2)
## ---- ④ Fig2B：注释框左右各扩 5 个字符宽（总宽 +10 字符；文字不重排/不丢内容）--
ua_dxB <- ua_get("Fig2B", "n_chars_requested") * ua_get("Fig2B", "char_w_pt") /
          ua_get("Fig2B", "pt_per_data_x")               # 线性 x 轴 → 直接换算 data 单位
nbB$rect$data$xmin <- nbB$rect$data$xmin - ua_dxB
nbB$rect$data$xmax <- nbB$rect$data$xmax + ua_dxB
## 记录「加宽前」的 snug 基准框（note_box 由文字反推的框，未含 ④ 的 ±5 字符），供复测
##   把「④ 施加的加宽量」与「恢复第 1 行后基准框自身的变化」分开，避免混淆（第 1 行字形
##   比第 2 行宽，恢复后基准框会随之变宽 ~0.6 pt，这不是 ④ 的加宽）。
ua_rec("Fig2B", "rect_x_before_widening",
       sprintf("%.8f .. %.8f", nbB$rect_data[["x0"]], nbB$rect_data[["x1"]]), "data-unit",
       "snug base box from note_box BEFORE the +/-5-char widening")
ua_pan_lo <- XL3B[1] - 0.05 * diff(XL3B)                 # ggplot 默认 5% 扩展
ua_pan_hi <- XL3B[2] + 0.05 * diff(XL3B)
ua_rec("Fig2B", "dx_data_units_each_side", ua_dxB, "data-unit",
       sprintf("5 x char_w(%.5f pt) / pt_per_data_x(%.5f pt/unit)", ua_get("Fig2B", "char_w_pt"),
               ua_get("Fig2B", "pt_per_data_x")))
ua_rec("Fig2B", "dx_pt_each_side", 5 * ua_get("Fig2B", "char_w_pt"), "pt",
       "requested 5 char widths per side (total +10 char)")
ua_rec("Fig2B", "rect_x_after", sprintf("%.6f .. %.6f", nbB$rect$data$xmin, nbB$rect$data$xmax),
       "data-unit", "widened note-box rect")
ua_rec("Fig2B", "inside_panel", as.character(nbB$rect$data$xmin >= ua_pan_lo &
                                            nbB$rect$data$xmax <= ua_pan_hi), "bool",
       sprintf("panel x range %.4f .. %.4f (xlim + 5%% expansion)", ua_pan_lo, ua_pan_hi))
cat(sprintf("[UA-4] Fig2B: char_w=%.5f pt, pt_per_data_x=%.5f -> dx=%.6f data units/侧 (=%.4f pt); rect x %.6f..%.6f (panel %.4f..%.4f) 在框内=%s\n",
            ua_get("Fig2B", "char_w_pt"), ua_get("Fig2B", "pt_per_data_x"), ua_dxB,
            5 * ua_get("Fig2B", "char_w_pt"), nbB$rect$data$xmin, nbB$rect$data$xmax,
            ua_pan_lo, ua_pan_hi,
            nbB$rect$data$xmin >= ua_pan_lo & nbB$rect$data$xmax <= ua_pan_hi))
p3b <- forest_panel(dtB, xlim = XL3B, vline = 0, logx = FALSE, txt_cex = 5.2, lab_size = 5.6,
                    col_map = c("Mediation decomposition" = PAL[["teal"]]),
                    title = "B  WGD acts on HLA LOH mainly through 6p arm loss (mediation on the probability scale)",
                    xlab = "Effect size (difference in probability of HLA LOH)") +
  scale_y_continuous(breaks = dtB$y, labels = dtB$label, limits = YL3B) +
  nbB$rect + nbB$text

## ---------- C 41 条臂 × TMB 关联排名 ----------
d3c <- fread(file.path(IMD, "fig3c_arm_tmb_rank.tsv"))
setorder(d3c, rank_tmb)
d3c[, arm_f := factor(arm, levels = arm)]
d3c[, hl := ifelse(arm == "6p", "6p (rank 26/41)", ifelse(rank_tmb == 1, "17p (rank 1/41)", "other arms"))]
p3c <- ggplot(d3c, aes(x = arm_f, y = beta_loss, colour = hl)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45", linewidth = 0.35) +
  geom_segment(aes(xend = arm_f, yend = 0), linewidth = 0.3, colour = "grey75") +
  geom_point(size = 1.25) +
  annotate("text", x = 1, y = 0.132, hjust = 0, size = 5.2 / 2.845, colour = PAL[["red"]],
           label = "17p: strongest arm\u2013TMB association (rank 1/41)") +
  annotate("text", x = 26, y = 0.105, hjust = 1, size = 5.2 / 2.845, colour = PAL[["navy"]],
           label = "6p: rank 26/41 \u2014 not the arm most associated with TMB") +
  scale_colour_manual(values = c("6p (rank 26/41)" = PAL[["navy"]],
                                 "17p (rank 1/41)" = PAL[["red"]],
                                 "other arms" = PAL[["grey"]]), name = NULL) +
  scale_y_continuous(limits = c(-0.01, 0.145), breaks = seq(0, 0.12, 0.03)) +
  labs(title = "C  All 41 chromosome arms ranked by their association with TMB",
       subtitle = "Linear model: log10(TMB + 0.1) ~ arm loss + cancer type; arms ordered by P value",
       x = "Chromosome arm (ordered by association rank)", y = "beta (log10 TMB per arm loss)") +
  theme_pub() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 5.4),
        legend.position = "top", legend.text = element_text(size = 5.4),
        legend.key.size = unit(0.24, "cm"))


# 标题/副标题按可用宽度自动折行（防溢出画布）
p3a <- wrap_headers(p3a, F3W)
p3b <- wrap_headers(p3b, F3W)
p3c <- wrap_headers(p3c, F3W)

fig3 <- p3a / p3b / p3c + plot_layout(heights = c(0.95, 0.85, 1.15))
cat("Fig2B note-box layout (flow_layout):\n"); print(nbB$layout)
## ---- Round1：落地施加的位移与几何，供复测脚本核对 ---------------------------
fwrite(rbindlist(ua_log, fill = TRUE), file.path(UA_DIR, "applied_offsets_Figure2.tsv"), sep = "\t")
fwrite(data.table(kind = c("fig2a_tx_pos_old_first", "fig2a_tx_pos_new_first"),
                  value = c(p3a$data$tx_pos_orig[1], p3a$data$tx_pos[1])),
       file.path(UA_DIR, "fig2a_tx_after.tsv"), sep = "\t")
fwrite(p3a$data[, .(label, ann, pann, tx_pos_orig, tx_pos)], 
       file.path(UA_DIR, "fig2a_ann_after.tsv"), sep = "\t")
fwrite(data.table(kind = c("rect_xmin", "rect_xmax", "rect_ymin", "rect_ymax", "text_x", "text_y",
                           "dx_units_each_side", "panel_xlim_lo", "panel_xlim_hi"),
                  value = c(nbB$rect$data$xmin, nbB$rect$data$xmax, nbB$rect$data$ymin,
                            nbB$rect$data$ymax, nbB$text$data$x, nbB$text$data$y, ua_dxB,
                            XL3B[1], XL3B[2])),
       file.path(UA_DIR, "note_box_geometry_after_Figure2.tsv"), sep = "\t")
qa_emit("Figure2", p3a, F3W, F3H * 0.95 / 2.95, tag = "Fig2A", fs = 5.2)
qa_emit("Figure2", p3b, F3W, F3H * 0.85 / 2.95, tag = "Fig2B", fs = 5.2)
qa_emit("Figure2", p3c, F3W, F3H * 1.15 / 2.95, tag = "Fig2C", fs = 5.4)
save_pub2(fig3, "Figure2_mechanism_armlandscape", F3W, F3H)
