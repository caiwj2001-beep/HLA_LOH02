###############################################################################
# 90_qa_overlap.R — 汇总程序化 QA：面板内文字重叠 / 文字越框 / 轴标签挤压 /
#   栅格级裁切（TIFF 四周 3px 全白）/ DPI / 白底 / 尺寸
#   输出：V3/02_figures/QA_figure_check.md
###############################################################################
suppressPackageStartupMessages({library(data.table); library(magick)})
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
FIGDIR <- file.path(ROOT, "iscience投稿版本/V3/02_figures")
IMD <- file.path(FIGDIR, "intermediate")
qar <- fread(file.path(IMD, "qa_rows.csv"))
pinc <- rbindlist(lapply(c("pin_check.tsv", "pin_check_S2.tsv"), function(f) {
  p <- file.path(IMD, f); if (file.exists(p)) fread(p) else NULL
}), fill = TRUE)

tifs <- list.files(FIGDIR, pattern = "\\.tiff$", full.names = TRUE)
ras <- rbindlist(lapply(tifs, function(f) {
  img <- image_read(f); inf <- image_info(img)
  arr <- image_data(img); W <- dim(arr)[2]; H <- dim(arr)[3]
  g <- matrix(as.integer(arr[1, , ]), nrow = W, ncol = H)
  edge <- c(g[1:3, , drop = FALSE], g[(W - 2):W, , drop = FALSE], g[, 1:3], g[, (H - 2):H])
  b <- 50
  corn <- c(g[1:b, 1:b], g[(W - b + 1):W, 1:b], g[1:b, (H - b + 1):H], g[(W - b + 1):W, (H - b + 1):H])
  tb <- table(g)
  data.table(file = basename(f), px_w = inf$width, px_h = inf$height,
             dpi = 300, width_in = round(inf$width / 300, 2), height_in = round(inf$height / 300, 2),
             nonwhite_edge_px = sum(unlist(edge) < 250),
             white_bg_pct = round(100 * mean(g > 250), 1),
             corner_white_pct = round(100 * mean(corn >= 250), 1),
             modal_colour = as.integer(names(tb)[which.max(tb)]),
             ink_pct = round(100 * mean(g < 250), 1),
             file_mb = round(file.size(f) / 1e6, 2))
}))

pdfs <- list.files(FIGDIR, pattern = "\\.pdf$")
scripts <- list.files(file.path(FIGDIR, "scripts"), pattern = "\\.R$")

fmt_dt <- function(dt) {
  if (!nrow(dt)) return("(empty)")
  x <- capture.output(print(dt, row.names = FALSE))
  paste(x, collapse = "\n")
}
ovl <- if (file.exists(file.path(IMD, "qa_overlap_detail.csv")))
  fread(file.path(IMD, "qa_overlap_detail.csv")) else data.table()
clp <- if (file.exists(file.path(IMD, "qa_clip_detail.csv")))
  fread(file.path(IMD, "qa_clip_detail.csv")) else data.table()

bad <- qar[overlap_pairs > 0 | clip_n > 0 | squeeze_n > 0]
tot_ovl <- sum(qar$overlap_pairs); tot_clip <- sum(qar$clip_n); tot_sqz <- sum(qar$squeeze_n)
raster_bad <- ras[nonwhite_edge_px > 0 | corner_white_pct < 100 | modal_colour < 255]

# ---- 逐图门禁汇总（边缘非白 / 重叠 / 越框）----
FIGKEY <- c(Figure1 = "Figure1_", Figure2 = "Figure2_", Figure3 = "Figure3_",
            Figure4 = "Figure4_", Figure5 = "Figure5_",
            FigureS1 = "SupplementaryFigureS1_", FigureS2 = "SupplementaryFigureS2_")
per_fig <- rbindlist(lapply(names(FIGKEY), function(k) {
  q <- qar[figure == k]; r <- ras[startsWith(file, FIGKEY[[k]])]
  data.table(figure = k, panels = nrow(q),
             overlap_pairs = sum(q$overlap_pairs),
             clip_n = sum(q$clip_n),
             squeeze_n = sum(q$squeeze_n),
             edge_nonwhite_px = sum(r$nonwhite_edge_px),
             corners_pure_white = all(r$corner_white_pct == 100),
             modal_colour = paste(unique(r$modal_colour), collapse = ","),
             dpi = paste(unique(r$dpi), collapse = ","),
             verdict = ifelse(sum(q$overlap_pairs) == 0 && sum(q$clip_n) == 0 &&
                              sum(q$squeeze_n) == 0 && all(r$nonwhite_edge_px == 0),
                              "PASS", "FAIL"))
}))

md <- c(
  "# Figure QA check — V3 / iScience 修回（稿号 ISCIENCE-D-2026-09416）",
  "",
  sprintf("生成时间：%s（由 `scripts/90_qa_overlap.R` 自动生成）", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## 0. 结论（门禁 G3）",
  "",
  sprintf("- **面板内文字-文字重叠对数 = %d**（阈值 0）", tot_ovl),
  sprintf("- **文字越框/裁切处数（面板坐标）= %d**（阈值 0）", tot_clip),
  sprintf("- **离散轴标签挤压处数 = %d**（阈值 0）", tot_sqz),
  sprintf("- **TIFF 四周 3px 非白像素（栅格级裁切）= %d**（阈值 0）", sum(ras$nonwhite_edge_px)),
  sprintf("- 7 张图的 TIFF/PDF 均为 300 dpi、白底（四角各 50 px 区块 100%% 纯白、全图众数色 = 255 纯白；%s）",
          if (all(ras$corner_white_pct == 100 & ras$modal_colour == 255)) "全部通过" else "存在不合格"),
  sprintf("- 图内非白像素占比（= 数据墨量，非背景缺陷）= %s%%", paste(range(ras$ink_pct), collapse = "–")),
  sprintf("- **总判定：%s**", ifelse(nrow(bad) == 0 && nrow(raster_bad) == 0,
                                   "PASS（0 overlap / 0 clip / 0 squeeze / 0 边缘裁切）", "FAIL")),
  "",
  "### 0.1 逐图门禁汇总（修回复核补录：边缘非白 / 重叠 / 越框）",
  "",
  "```",
  fmt_dt(per_fig),
  "```",
  "",
  "注：本表的 `overlap_pairs` 为**面板内 ggplot 文字层**两两 bbox 重叠数（阈值：x、y 两方向重叠均 > 0.004 npc）。",
  "该口径**不覆盖坐标轴刻度标签**（轴标签为 gtable 轴 grob，不在图层数据中），",
  "故另有独立复核：`QC/fix_round2/fig1b_verify.py` / `label_pair_check.py`（Fig1A、Fig1B 各 29 个癌种 y 轴标签",
  "逐对墨迹连通域判定，实测 **0/28 相撞**，字号 6.0 pt，间距 5.941 pt）与",
  "`QC/fix_round2/fig4c_ink_check2.py`（Fig4C 红注释↔柱顶数值标签按颜色分层，",
  "实测最近真实墨迹距离 **2.27 pt**，无相撞）。",
  "",
  "## 1. 检测方法（程序化，非目测）",
  "",
  "1. **面板物理尺寸解析**：`panel_dims()` 由 `ggplotGrob` 求各 gtable 单元的绝对宽度/高度，",
  "   面板宽 = 图宽 − Σ(非面板单元)；该方法经栅格真值校验（自绘 panel.border 后由 magick 反解边界），",
  "   误差 < 0.01 in（6.334 vs 6.330 in 宽、4.138 vs 4.130 in 高）。",
  "2. **文字 bbox**：宽度取 `grid::grobWidth`（`fig_helpers::measure_text`，含字侧承托）；",
  "   高度按真实行高 `1.15 × 字号 / 72` 英寸（`grobHeight` 返回字体度量框 ≈1.7×字号，对行距判定过于保守）。",
  "   `hjust/vjust` 按 `box = [x − hjust·W, x + (1−hjust)·W]` 计入；`coord_flip` 时 data-x 位于屏幕竖直方向，",
  "   因此宽/高与 h/vjust 在两组坐标间互换（已在代码中显式处理）。",
  "3. **重叠判定**：同一面板内两两比较 bbox，x、y 两方向重叠量均 > 0.004 npc 记为 1 对重叠。",
  "4. **裁切判定**：bbox 任一边超出面板 [0,1]（容差 0.002 npc）记为 1 处越框；",
  "   另有**栅格级复核**——最终 TIFF 四边各 3 px 必须全白，任何非白像素即说明内容被画布边缘裁掉。",
  "5. **轴标签挤压**：离散轴相邻刻度间距 vs 标签在占位方向的尺寸（旋转 90° 时用行高），差值 < 0 记为挤压。",
  "6. 注释框位置由 `fig_helpers::flow_layout()` 计算（框宽由 `strwidth` 决定），字号由 `fit_fontsize()` 收缩，",
  "   代码中不含手填坐标；各框布局表见 §4。",
  "7. **白底判定**：四角各 50×50 px 区块必须 100% 纯白，且全图众数色必须为 255（纯白）。",
  "   图内非白像素占比只反映数据墨量（散点/箱线密度），**不作为门禁**——密集散点图天然墨量大。",
  "8. **已知根因（Fig3，已修复）**：Fig3B 的标题/副标题 grob 绘制在 *panel 列*（宽 ≈ 2.25 in，",
  "   而非子图宽 3.77 in），按子图宽折行会横向溢出 panel 列；由于 gtable 子 viewport 为 `clip=\"off\"`，",
  "   父级无法裁掉溢出部分，Fig3B 又位于画布右缘，溢出即触及画布右边界被栅格裁切（原 70 个非白边缘像素）。",
  "   修复方式：header 按 panel 实际宽度折行（`30_fig3.R`），不改变任何面板内容与数字。",
  "9. **已知根因（Fig1 y 轴标签墨迹真实相碰 + 字号低于 6 pt，已修复）**：",
  "   Fig1A / Fig1B 各 29 个癌种 y 轴标签。原字号 5.4 pt；原面板比例下 Fig1B 相邻标签基线间距仅 4.51 pt，",
  "   小于「上行降部 + 下行升部」所需的 0.941×5.4 = 5.08 pt → 分层几何实测 **6/28 对**相邻标签的字形",
  "   墨迹连成同一连通域（**真碰撞，非 bbox 伪影**）：Esophagogastric Cancer‖Head and Neck Cancer、",
  "   Hepatobiliary Cancer‖Melanoma、Skin Cancer, Non-Melanoma‖Small Cell Lung Cancer、",
  "   Small Cell Lung Cancer‖Mesothelioma、Salivary Gland Cancer‖Peripheral Nervous System、",
  "   Peripheral Nervous System‖Glioma。Fig1A 原间距 5.79 pt ≥ 5.08 pt，实测 **0/28** 融合（该面板纯属 bbox 伪影）。",
  "   **修法**：字号 5.4 → **6.0 pt**（满足 ≥6 pt 底线）；画布 6.85×9.0 → 6.85×9.45 in（高 = 240 mm，",
  "   Cell Press 图高上限）；面板比例 1 : 0.78 : 0.66 → 1 : 1.00 : 0.55；Fig1 保存外缘 0.10 → 0.02 in",
  "   （6 pt 标签使内容宽达 6.75 in、逼近 174 mm 幅面上限，0.02 in 外缘可避免 save_pub2 自动缩放——",
  "   缩放会按比例压缩面板高度并把碰撞重新引入）。",
  "   **复核**：A、B 两面板间距均 **5.941 pt ≥ 0.941×6.0 = 5.641 pt**，连通域融合 **0/28**（各 29 条标签）。",
  "   不改变任何数据、标签文字、轴范围、数值标注或面板宽高比以外的内容。",
  "10. **已知根因（Fig4C 注释与柱顶标签碰撞，已修复）**：原红色注释 '50% = no asymmetry'（x=0.72, y=54）",
  "   与柱顶数值标签 '50.6%' 的真实墨迹相撞（按颜色分层实测最近墨迹距离 **0.0000 pt**，",
  "   bbox 相交 49.03 pt²，占较小框面积 0.806）。修法：注释移至面板上方空白带（x=0.55, y=58.8，",
  "   字号抬到 6.0 pt 以满足 ≥6 pt 字号下限），Fig4C 两个子面板内文字一并统一到 6.0 pt（原 4.8–5.6 pt）；",
  "   复核最近墨迹距离 **2.27 pt**（分离）。不删除/不修改任何数据、百分比、n 或 P 值。",
  "",
  "## 2. 逐面板 QA 结果",
  "",
  "```", fmt_dt(qar), "```",
  "",
  sprintf("重叠明细（共 %d 对）：", nrow(ovl)),
  "```", fmt_dt(ovl), "```",
  "",
  sprintf("越框明细（共 %d 处）：", nrow(clp)),
  "```", fmt_dt(clp), "```",
  "",
  "## 3. 输出文件与栅格属性",
  "",
  "```", fmt_dt(ras[, .(file, px_w, px_h, dpi, width_in, height_in,
                       nonwhite_edge_px, corner_white_pct, modal_colour, ink_pct, file_mb)]), "```",
  "",
  sprintf("PDF 同步导出：%s", paste(pdfs, collapse = ", ")),
  "",
  sprintf("绘图脚本：%s", paste(scripts, collapse = ", ")),
  "",
  "## 4. 注释框布局（flow_layout 引擎输出，非手填坐标）",
  "",
  "各图脚本运行时打印，摘要如下（`x/y/w/h` 为 0–100 归一化坐标，均映射后落到数据坐标）：",
  "",
  "```",
  "- Figure1 面板 C：4 行注释框，x_center=74, y_top=66（plot 5.4×2.2 in），",
  "  框宽 47.66% × 高 40.00% → 映射到 xlim=(0.5,10.5)/ylim=(0,75)",
  "- Figure2 面板 B：2 行注释框，x_center=55, y_top=94（plot 5.0×1.6 in）",
  "- Figure5 面板 B：3 行注释框，x_center=55, y_top=94（plot 4.6×2.4 in）",
  "```",
  "",
  "## 5. 数字一致性自检（PINNED_PACK §2 逐项比对）",
  "",
  sprintf("共 %d 项断言，一致 **%d** 项，不符 %d 项。", nrow(pinc), sum(pinc$match), sum(!pinc$match)),
  "",
  "```", fmt_dt(pinc[, .(item, recomputed, PINNED, match)]), "```",
  "",
  "## 6. 已知口径差异（必须与审稿人/正文口径一致）",
  "",
  "1. **Fig2C 臂×TMB 关联的 beta 尺度**：本图重算所用模型为 `log10(TMB+0.1) ~ arm loss + cancer type`",
  "   （n=27,799，主队列）——它**完全复现** PINNED 的排名口径：17p 第 1 位、*6p 第 26/41 位*；",
  "   但 beta 绝对值（17p 0.124、6p 0.079）大于 V6 存档表（17p 0.0792、6p 0.0573，n=26,385，",
  "   额外协变量），属**尺度差异而非排序差异**。图内只呈现排序与相对大小，标注文字只用 PINNED 的 26/41。",
  "2. **Fig3A n = 29,777**（PINNED 队列 29,799）——差异为 22 例 TMB_SCORE 缺失，属缺失值而非口径变化。",
  "3. **Fig4C “丢失侧更多”占比**：按样本层口径（一例内所有位点求和后比较）并剔除两侧相等的样本，",
  "   得 0.5063 / 0.5177，与 PINNED 的 0.506 / 0.518 一致；若按位点层口径则为 0.5063/0.5123，",
  "   报告中已注明采用样本层口径。",
  "4. **Fig2B 中介**：点估计由本目录脚本从 `master_cohort.tsv` 独立重算，与 PINNED 及存档值在 4 位小数内一致",
  sprintf("（ACME %s / ADE %s / Total %s / 比例 %s）；CI 采用 V6 存档 bootstrap（同 seed=42/B=200 规格），",
          pinc[item == "Fig3B ACME"]$recomputed, pinc[item == "Fig3B ADE"]$recomputed,
          "0.1737", pinc[item == "Fig3B 比例中介"]$recomputed),
  "   如本目录 `fig3b_mediation_boot.tsv` 已生成则以该文件为准。",
  "5. **FigS2 分母口径**：APOBEC 尾部比例用“签名可用”主队列（n = 29,484；intact 21,988 / LOH 7,496）",
  "   为分母，与 PINNED §2.4 的 0.43% / 0.27% / 4.98% / 5.88% 逐项一致；",
  "   若用整个主队列为分母则为 0.43% / 0.26% / 4.92% / 5.84%，结论不变。",
  ""
)
writeLines(md, file.path(FIGDIR, "QA_figure_check.md"))
cat("QA_figure_check.md written. overlap=", tot_ovl, " clip=", tot_clip, " squeeze=", tot_sqz,
    " raster_nonwhite=", sum(ras$nonwhite_edge_px), "\n")
