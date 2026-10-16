###############################################################################
# 10_fig1.R — Figure 1: 泛癌 HLA LOH 图谱 + 调用可靠性
#   A 29 癌种 any-HLA-LOH 频率 + Wilson 95%CI + 25.3% 虚线
#   B HLA-A/B/C 位点特异性频率
#   C 臂独立型占比 × 纯度十分位（60.3%→11.3%）+ 6p 佐证的高可信度频率 14.0%
###############################################################################
source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
                 "fig_common.R"))

## ===========================================================================
## Round1 用户微调（量测 → 换算 → 施加到真实 artist）
##   量测基准：QC_user_adjust_round1/measured_constants.tsv —— 由 m5_measure.py 用
##   pymupdf 从**现行成品 PDF** 反解：char_w_pt = 渲染 bbox 宽 / 可见字符数；
##   char_h_pt = 实测行基线间距；pt_per_data = 刻度标签中心最小二乘。
##   本脚本不手填任何坐标：位移 = 字符数 × 实测字宽(高) ÷ 实测 pt-per-data。
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

F1W <- 6.85; F1H <- 9.45
AXT <- 6.0
d <- fread(file.path(IMD, "fig1a_cancer_freq.tsv"))
d[, CANCER_TYPE := factor(CANCER_TYPE, levels = CANCER_TYPE[order(freq_LOH)])]
ov <- d[1]
d[, nlab := sprintf("%d/%d", n_LOH, N)]
d[, plab := sprintf("%.1f", 100 * freq_LOH)]
## ---- ① Fig1A：最后两行数字整体右移 10 个字符宽 --------------------------------
##  "最后两行" = coord_flip 后离散轴最底部两层（level 1/2 = 频率最低的两层）
d[, ua_level := as.integer(CANCER_TYPE)]
d[, ua_last2 := ua_level %in% c(1L, 2L)]
stopifnot(identical(sort(as.character(d$CANCER_TYPE[d$ua_last2])),
                    c("Gastrointestinal Stromal Tumor", "Prostate Cancer")))
ua_dxA <- ua_get("Fig1A", "n_chars_requested") * ua_get("Fig1A", "char_w_pt") /
          ua_get("Fig1A", "pt_per_data")                      # 频率轴（flip 后为屏幕水平方向）
d[, ua_y_nlab := 42 + ifelse(ua_last2, ua_dxA, 0)]
d[, ua_y_plab := 53 + ifelse(ua_last2, ua_dxA, 0)]
ua_rec("Fig1A", "dx_data_units", ua_dxA, "data-unit",
       sprintf("10 x char_w(%.5f pt) / pt_per_data(%.5f pt/unit)", ua_get("Fig1A", "char_w_pt"),
               ua_get("Fig1A", "pt_per_data")))
ua_rec("Fig1A", "dx_pt", 10 * ua_get("Fig1A", "char_w_pt"), "pt", "requested 10 char widths")
ua_rec("Fig1A", "moved_rows", "Prostate Cancer (217/1958, 11.1) + Gastrointestinal Stromal Tumor (34/354, 9.6)",
       "text", "bottom two rows of the flipped discrete axis (level 1 and 2)")
cat(sprintf("[UA-1] Fig1A: char_w=%.5f pt/char, pt_per_data=%.5f pt/unit -> dx=%.5f data units = %.4f pt\n",
            ua_get("Fig1A", "char_w_pt"), ua_get("Fig1A", "pt_per_data"), ua_dxA,
            10 * ua_get("Fig1A", "char_w_pt")))
p1a <- ggplot(d, aes(x = CANCER_TYPE, y = 100 * freq_LOH)) +
  geom_col(fill = PAL[["navy"]], width = 0.68) +
  geom_errorbar(aes(ymin = 100 * lo, ymax = 100 * hi), width = 0.3,
                colour = "grey30", linewidth = 0.35) +
  geom_hline(yintercept = 100 * ov$cohort_freq, linetype = "dashed",
             colour = PAL[["red"]], linewidth = 0.45) +
  geom_text(aes(y = ua_y_nlab, label = nlab), hjust = 0, size = AXT / 2.845, colour = "grey35") +
  geom_text(aes(y = ua_y_plab, label = plab), hjust = 0, size = AXT / 2.845, colour = "grey5") +
  coord_flip() +
  scale_y_continuous(limits = c(0, 62), breaks = seq(0, 50, 10)) +
  labs(title = "A  Pan-cancer landscape of HLA loss of heterozygosity",
       subtitle = sprintf("%d evaluable tumours across %d cancer types (N\u2265100).  Dashed line: pan-cancer %.1f%% (95%% CI %.1f\u2013%.1f).  Right columns: events/n and frequency (%%)",
                          sum(d$N), nrow(d), 100 * ov$cohort_freq, 100 * ov$cohort_lo, 100 * ov$cohort_hi),
       x = NULL, y = "HLA LOH frequency (%)") +
  theme_pub() + theme(axis.text.y = element_text(size = AXT))

l <- fread(file.path(IMD, "fig1b_locus_freq.tsv"))
l[, CANCER_TYPE := factor(CANCER_TYPE, levels = levels(d$CANCER_TYPE))]
l[, locus := factor(locus, levels = c("HLA-A", "HLA-B", "HLA-C"))]
ovl <- fread(file.path(IMD, "fig1b_locus_overall.tsv"))
p1b <- ggplot(l, aes(x = CANCER_TYPE, y = 100 * freq_LOH, fill = locus)) +
  geom_col(position = position_dodge(0.78), width = 0.72) +
  geom_errorbar(aes(ymin = 100 * lo, ymax = 100 * hi), position = position_dodge(0.78),
                width = 0.22, linewidth = 0.25, colour = "grey30") +
  coord_flip() +
  scale_fill_manual(values = c("HLA-A" = PAL[["navy"]], "HLA-B" = PAL[["teal"]],
                               "HLA-C" = PAL[["gold"]]), name = "Locus") +
  scale_y_continuous(limits = c(0, 52), breaks = seq(0, 50, 10)) +
  labs(title = "B  Locus-specific HLA LOH",
       subtitle = sprintf("Frequency among samples evaluable at that locus (cohort-wide HLA-A %.1f%%, HLA-B %.1f%%, HLA-C %.1f%%); bars = Wilson 95%% CI",
                          100 * ovl[locus == "HLA-A"]$freq, 100 * ovl[locus == "HLA-B"]$freq,
                          100 * ovl[locus == "HLA-C"]$freq),
       x = NULL, y = "Locus-specific LOH (%)") +
  theme_pub() +
  theme(axis.text.y = element_text(size = AXT),
        legend.position = "top", legend.direction = "horizontal",
        legend.text = element_text(size = 5.2), legend.title = element_text(size = 5.4),
        legend.key.size = unit(0.24, "cm"))

dc <- fread(file.path(IMD, "fig1c_purity_decile.tsv"))
XL <- c(0.5, 10.5); YL <- c(0, 75)
qcd <- fread(file.path(V2, "REVIEWER3_part4_armindependent_QC.tsv"))
trend_p <- unique(qcd[block == "T2_purity_decile_trend" & grepl("^pur_f_", group_or_term)]$p)
## ---- ② Fig1C：注释框（含文字）整体上移 3 个字符高 + 每行重排为 ≤54 字符 --------
ua_maxch <- as.integer(ua_get("Fig1C", "max_chars_per_line"))
ua_nb_orig <- c(sprintf("Arm-independent HLA LOH: 1,644/5,805 = %.1f%% of 6p-judgeable tumours",
                        100 * 1644 / 5805),
                "6p-supported high-confidence frequency across the cohort:",
                "14.0% (4,161/29,799)",
                sprintf("Purity-decile trend P = %.1e (decreasing)", trend_p))
ua_wrap <- function(txt, width) {                 # 贪心按词折行：不截断、不改词序
  ws <- unlist(strsplit(txt, " ", fixed = TRUE)); ws <- ws[nzchar(ws)]
  if (!length(ws)) return(txt)
  out <- character(0); cur <- ""
  for (w in ws) {
    cand <- if (nzchar(cur)) paste(cur, w) else w
    if (nchar(cand) > width && nzchar(cur)) { out <- c(out, cur); cur <- w } else cur <- cand
  }
  c(out, cur)
}
ua_nb_lines <- unlist(lapply(ua_nb_orig, ua_wrap, width = ua_maxch))
stopifnot(all(nchar(ua_nb_lines) <= ua_maxch))                       # 每行 ≤54 字符
stopifnot(identical(gsub("[[:space:]]+", " ", paste(ua_nb_lines, collapse = " ")),
                    gsub("[[:space:]]+", " ", paste(ua_nb_orig, collapse = " "))))  # 不丢内容
cat(sprintf("[UA-2] Fig1C note box: %d 行 -> %d 行 (≤%d 字符), 最长行 %d 字符\n",
            length(ua_nb_orig), length(ua_nb_lines), ua_maxch, max(nchar(ua_nb_lines))))
for (i in seq_along(ua_nb_lines)) cat(sprintf("        line %d (%2d chars): %s\n",
                                              i, nchar(ua_nb_lines[i]), ua_nb_lines[i]))
## [缺陷修复 §4.2] 原 plot_w_in = 5.4 用的是「名义」面板宽，而 Figure1C 面板**实测宽**仅
##   4.4122 in（317.68 pt；measured_constants.tsv 的 Fig1C/panel_w_in，由成品 PDF 的 panel
##   边框反解）→ 框宽系统性偏窄约 18%，正文最长行比框宽（每侧越出 9.3–10.3 pt）。
##   改用实测面板宽后框宽 ≈122.2 pt ≥ 最长行 120.41 pt，越框归零。
##   不放宽任何文字、不改位移量、不改其它任何几何。
ua_panel_w <- ua_get("Fig1C", "panel_w_in")
nb <- note_box(ua_nb_lines,
               plot_w_in = ua_panel_w, plot_h_in = 2.2, xlim = XL, ylim = YL,
               x_center_norm = 74, y_top_norm = 66, fontsize = 5.2)
# 位移：3 × 实测单行行高 ÷ 实测 y 轴 pt-per-data（向上 = data y 增大）
ua_dyC <- ua_get("Fig1C", "n_chars_requested") * ua_get("Fig1C", "char_h_pt") /
          abs(ua_get("Fig1C", "pt_per_data_y"))
nb$rect$data$ymin <- nb$rect$data$ymin + ua_dyC
nb$rect$data$ymax <- nb$rect$data$ymax + ua_dyC
nb$text$data$y    <- nb$text$data$y + ua_dyC
ua_rec("Fig1C", "dy_data_units", ua_dyC, "data-unit",
       sprintf("3 x char_h(%.5f pt) / |pt_per_data_y|(%.5f pt/unit)", ua_get("Fig1C", "char_h_pt"),
               abs(ua_get("Fig1C", "pt_per_data_y"))))
ua_rec("Fig1C", "dy_pt", 3 * ua_get("Fig1C", "char_h_pt"), "pt", "requested 3 line heights")
ua_rec("Fig1C", "n_lines_before_after", sprintf("%d -> %d", length(ua_nb_orig), length(ua_nb_lines)),
       "lines", sprintf("rewrapped to <= %d chars/line, content preserved", ua_maxch))
cat(sprintf("[UA-2] Fig1C: char_h=%.5f pt, |pt_per_data_y|=%.5f pt/unit -> dy=%.5f data units = %.4f pt up\n",
            ua_get("Fig1C", "char_h_pt"), abs(ua_get("Fig1C", "pt_per_data_y")), ua_dyC,
            3 * ua_get("Fig1C", "char_h_pt")))
## ---- ③ Fig1C（Round2 追加）：在 Round1 的 3 字符高之上再整体上移 1 个字符高 ----------
##   用户第二轮裁定：注释框（含文字）再向上整体移动 1 个字符高度。
##   口径与 Round1 完全一致：位移 = 字符数 × 实测字高 ÷ 实测 |pt-per-data|（无手填坐标），
##   施加到同一批真实 artist（rect 的 ymin/ymax 与 text 的 y）；Round1 的 +3 字符高原值保留。
ua_dyC2 <- ua_get("Fig1C", "n_chars_requested_round2") * ua_get("Fig1C", "char_h_pt") /
           abs(ua_get("Fig1C", "pt_per_data_y"))
nb$rect$data$ymin <- nb$rect$data$ymin + ua_dyC2
nb$rect$data$ymax <- nb$rect$data$ymax + ua_dyC2
nb$text$data$y    <- nb$text$data$y + ua_dyC2
ua_dyC_tot <- ua_dyC + ua_dyC2
ua_rec("Fig1C", "dy_data_units_round2", ua_dyC2, "data-unit",
       sprintf("1 x char_h(%.5f pt) / |pt_per_data_y|(%.5f pt/unit)", ua_get("Fig1C", "char_h_pt"),
               abs(ua_get("Fig1C", "pt_per_data_y"))))
ua_rec("Fig1C", "dy_pt_round2", 1 * ua_get("Fig1C", "char_h_pt"), "pt",
       "round2: further 1 line height, on top of round1")
ua_rec("Fig1C", "dy_data_units_total", ua_dyC_tot, "data-unit",
       "round1 3 + round2 1 line heights (cumulative vs the original baseline)")
ua_rec("Fig1C", "dy_pt_total", 4 * ua_get("Fig1C", "char_h_pt"), "pt",
       "cumulative 4 line heights vs the original baseline")
ua_rec("Fig1C", "n_chars_requested_total", ua_get("Fig1C", "n_chars_requested_total"), "char",
       "cumulative request 3 + 1")
cat(sprintf("[UA-3] Fig1C round2: +%.5f data units = %.4f pt up (cumulative %.5f data units = %.4f pt = 4 line heights)\n",
            ua_dyC2, 1 * ua_get("Fig1C", "char_h_pt"), ua_dyC_tot,
            4 * ua_get("Fig1C", "char_h_pt")))
p1c <- ggplot(dc, aes(x = dec, y = pct_armind)) +
  geom_line(colour = PAL[["grey"]], linewidth = 0.45) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.2, colour = "grey45", linewidth = 0.32) +
  geom_point(size = 1.6, colour = PAL[["navy"]]) +
  geom_hline(yintercept = 100 * 4161 / 29799, linetype = "dashed",
             colour = PAL[["red"]], linewidth = 0.45) +
  annotate("text", x = 1, y = 16.6, hjust = 0, vjust = 0.5,
           label = "dashed line: 6p-supported frequency 14.0%",
           size = 5.0 / 2.845, colour = PAL[["red"]]) +
  annotate("text", x = 1.2, y = 60.4, hjust = 0, vjust = 0.5,
           label = sprintf("D1: %.1f%%", dc[dec == 1]$pct_armind),
           size = 5.0 / 2.845, colour = "grey10") +
  annotate("text", x = 9.9, y = 5.0, hjust = 1, vjust = 0.5,
           label = sprintf("D10: %.1f%%", dc[dec == 10]$pct_armind),
           size = 5.0 / 2.845, colour = "grey10") +
  scale_x_continuous(breaks = 1:10,
                     labels = sprintf("D%d\n%.0f%%", dc$dec, 100 * dc$purity_med)) +
  coord_cartesian(xlim = XL, ylim = YL, clip = "off") +
  labs(title = "C  The \u201Carm-independent\u201D HLA LOH fraction collapses with tumour purity",
       x = "Tumour purity decile (median FACETS purity below)",
       y = "Arm-independent HLA LOH (% of judgeable)",
       subtitle = "Judging whether an allele-specific call is explained by 6p arm loss is only possible where 6p is callable (5,805/7,554 HLA-LOH tumours)") +
  nb$rect + nb$text +
  theme_pub()


# 标题/副标题按可用宽度自动折行（防溢出画布）
p1a <- wrap_headers(p1a, F1W)
p1b <- wrap_headers(p1b, F1W)
p1c <- wrap_headers(p1c, F1W)

fig1 <- p1a / p1b / p1c + plot_layout(heights = c(1, 1.00, 0.55))
# 说明（修回）：
#  ① Fig1A/Fig1B 各 29 个癌种 y 轴标签。原字号 5.4 pt，且原 heights 下相邻标签基线间距
#     Fig1B 仅 4.51 pt < 「上行降部 + 下行升部」所需 0.941×5.4 = 5.08 pt，分层几何实测
#     **6/28 对**相邻标签字形墨迹连成同一连通域（真碰撞，非 bbox 伪影）——例如
#     "Esophagogastric Cancer" 的 g 降部 与 "Head and Neck Cancer" 的 d 升部。
#  ② 同时把 29 条标签字号由 5.4 pt 提升到 **6.0 pt**（≥6 pt 底线），所需间距升至 0.941×6.0 = 5.65 pt。
#  修法：画布高度 9.0 → 9.45 in（= 240 mm，Cell Press 图高上限），面板比例 1 : 0.78 : 0.66
#        → 1 : 1.00 : 0.55，把 A/B 面板的标签间距提到 ≈5.8 pt；不改变任何数据、标签文字、
#        轴范围或数值标注。
cat("Figure 1 note-box layout (flow_layout):\n"); print(nb$layout)
cat(sprintf("  note fontsize = %.2f pt\n", nb$fontsize))

## ---- Round1：把"施加的位移"与"新布局实测值"落地，供复测脚本逐项核对 ----------
dir.create(UA_DIR, showWarnings = FALSE, recursive = TRUE)
fwrite(rbindlist(ua_log, fill = TRUE), file.path(UA_DIR, "applied_offsets_Figure1.tsv"), sep = "\t")
fwrite(data.table(kind = "note_box_layout_after", x = nb$layout$x, y = nb$layout$y,
                  w = nb$layout$w, h = nb$layout$h, note_fontsize = nb$fontsize),
       file.path(UA_DIR, "layout_after_Figure1.tsv"), sep = "\t")
fwrite(data.table(kind = c("rect_xmin", "rect_xmax", "rect_ymin", "rect_ymax", "text_x", "text_y",
                           "dy_units", "dy_pt", "panel_xlim_lo", "panel_xlim_hi",
                           "panel_ylim_lo", "panel_ylim_hi"),
                  value = c(nb$rect$data$xmin, nb$rect$data$xmax, nb$rect$data$ymin,
                            nb$rect$data$ymax, nb$text$data$x, nb$text$data$y, ua_dyC_tot,
                            4 * ua_get("Fig1C", "char_h_pt"), XL[1], XL[2], YL[1], YL[2])),
       file.path(UA_DIR, "note_box_geometry_after_Figure1.tsv"), sep = "\t")
fwrite(d[ua_last2 == TRUE, .(CANCER_TYPE, level = ua_level, nlab, plab,
                             y_nlab = ua_y_nlab, y_plab = ua_y_plab)],
       file.path(UA_DIR, "fig1a_moved_labels_after.tsv"), sep = "\t")

qa_emit("Figure1", p1a, F1W, F1H * 1 / 2.55, tag = "Fig1A", fs = AXT)
qa_emit("Figure1", p1b, F1W, F1H * 1.00 / 2.55, tag = "Fig1B", fs = AXT)
qa_emit("Figure1", p1c, F1W, F1H * 0.55 / 2.55, tag = "Fig1C", fs = 5.2)
save_pub2(fig1, "Figure1_pancancer_and_reliability", F1W, F1H, margin_in = 0.02)
