#!/usr/bin/env Rscript
###############################################################################
# qa_tiff_edges_reconstructed.R
# ---------------------------------------------------------------------------
# 【重建件 · 非原文 —— 事故恢复三分类中的第 2 类】
#
#   本文件是 2026-10-16 误删事故后的**重建件（reconstruction）**，不是原文。
#   原脚本 `02_figures/scripts/_p17.R`（611 B，2026-10-14 生成，用 magick 对
#   `02_figures/*.tiff` 做边缘/墨色 QA）在本轮仓库镜像清理中被误删，全盘无副本，
#   **不可恢复（unrecoverable）**。
#
#   三分类如实标注（本项目规矩）：
#     (1) 完整恢复：否 —— 原文不可恢复；
#     (2) 明确标注的重建件：**是** —— 即本文件；
#     (3) 无法重建：原 `_p17.R` 本身。
#
#   等价物（既有，优先指向）：`02_figures/QC_user_adjust_round1/m8_qa_tiff.py`
#     （PIL 实现，同样的判据：300 dpi / 白底 / 四边 3 px 非白 = 0 / 四角 50x50 纯白 /
#      全图众数色 = 255）。本重建件用 R 的 `magick` 包（ImageMagick 绑定）复现同类检查。
#
#   本脚本**不改动任何图件、不产生任何交付物**，只读取并报告。
#   事故与处置记录：`00_pinned/PINNED_PACK_CORRECTIONS.md` §(xiii.10)。
#
#   用法:  Rscript qa_tiff_edges_reconstructed.R
###############################################################################
suppressMessages(library(magick))

FIG_DIR <- "C:/Users/Administrator/科研文件/HLA_LOH02/iscience投稿版本/V3/02_figures"
OUT_TSV <- file.path(dirname(sub("^--file=", "",
              grep("^--file=", commandArgs(FALSE), value = TRUE)[1])),
              "qa_tiff_edges_reconstructed.tsv")

FILES <- c("Figure1_pancancer_and_reliability.tiff",
           "Figure2_mechanism_armlandscape.tiff",
           "Figure3_TMB_aneuploidy.tiff",
           "Figure4_neoantigen.tiff",
           "Figure5_survival.tiff",
           "SupplementaryFigureS1_apobec.tiff",
           "SupplementaryFigureS2_germline.tiff")

BAND <- 3    # edge band width (px), matching the figure-QA criterion
COR  <- 50   # corner block size (px)
THR  <- 250  # "< 250" == non-white

gray_vals <- function(img) as.integer(image_data(image_convert(img, colorspace = "gray"),
                                                 channels = "gray"))

check <- function(f) {
  p <- file.path(FIG_DIR, f)
  img <- image_read(p)
  inf <- image_info(img)
  W <- inf$width; H <- inf$height
  dpi <- inf$density
  # --- four edge bands (crop geometry is unambiguous: x0,y0 + w x h) ---
  bands <- list(image_crop(img, geometry_area(width = BAND, height = H, x = 0,        y = 0)),
                image_crop(img, geometry_area(width = BAND, height = H, x = W - BAND, y = 0)),
                image_crop(img, geometry_area(width = W,    height = BAND, x = 0,      y = 0)),
                image_crop(img, geometry_area(width = W,    height = BAND, x = 0,      y = H - BAND)))
  edge_nonwhite <- sum(vapply(bands, function(b) sum(gray_vals(b) < THR), numeric(1)))
  # --- four corner 50x50 blocks ---
  corners <- list(image_crop(img, geometry_area(COR, COR, 0,     0)),
                  image_crop(img, geometry_area(COR, COR, W - COR, 0)),
                  image_crop(img, geometry_area(COR, COR, 0,     H - COR)),
                  image_crop(img, geometry_area(COR, COR, W - COR, H - COR)))
  corner_white <- all(vapply(corners, function(c) all(gray_vals(c) >= THR), logical(1)))
  # --- modal colour and ink coverage over the whole raster ---
  g    <- gray_vals(img)
  modal <- which.max(tabulate(g + 1L, nbins = 256L)) - 1L
  ink   <- 100 * mean(g < THR)
  data.frame(file = f, px_w = W, px_h = H, dpi = dpi,
             edge_nonwhite_px = edge_nonwhite, corners_pure_white = corner_white,
             modal = modal, ink_pct = round(ink, 2),
             file_mb = round(file.info(p)$size / 1e6, 3),
             row.names = NULL)
}

cat("== TIFF 边缘/墨色 QA（重建件 qa_tiff_edges_reconstructed.R）==\n")
cat("== 判据: 四边各 3px 非白 = 0 / 四角 50x50 纯白 / 众数色 = 255 / 300 dpi ==\n\n")
rows <- do.call(rbind, lapply(FILES, check))
for (i in seq_len(nrow(rows))) {
  r <- rows[i, ]
  cat(sprintf("  %-42s %4dx%-5d dpi=%s  四边3px非白=%d  四角50x50纯白=%-5s  众数色=%d  墨量=%.2f%%  %.2f MB\n",
              r$file, r$px_w, r$px_h, r$dpi, r$edge_nonwhite_px,
              as.character(r$corners_pure_white), r$modal, r$ink_pct, r$file_mb))
}
bad <- rows[rows$edge_nonwhite_px != 0 | !rows$corners_pure_white | rows$modal != 255, ]
cat(sprintf("\n  → 不合格文件数 = %d ; 总判定 = %s\n", nrow(bad),
            if (nrow(bad) == 0) "PASS" else "FAIL"))

if (!is.na(OUT_TSV)) {
  write.table(rows, OUT_TSV, sep = "\t", row.names = FALSE, quote = FALSE)
  cat(sprintf("  → 逐文件结果已写入 %s\n", OUT_TSV))
}
quit(status = if (nrow(bad) == 0) 0 else 1)
