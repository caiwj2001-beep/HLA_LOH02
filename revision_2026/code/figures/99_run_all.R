###############################################################################
# 99_run_all.R — 一键重建全部中间结果 + 7 张图 + QA 报告
#   用法：Rscript 99_run_all.R       （工作目录任意）
###############################################################################
HERE <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
R <- function(f) file.path(HERE, f)
steps <- c("02_recompute_apobec.R", "10_fig1.R", "20_fig2.R", "30_fig3.R",
           "40_fig4.R", "50_fig5.R", "60_figS1.R", "70_figS2.R", "90_qa_overlap.R")
dir.create(file.path(HERE, "..", "intermediate"), showWarnings = FALSE)
# qa_emit() 为追加写入：先清掉上一轮的 QA 累积文件，否则重复运行会把旧行计入 QA 报告
for (f in c("qa_rows.csv", "qa_overlap_detail.csv", "qa_clip_detail.csv", "qa_header_check.csv"))
  unlink(file.path(HERE, "..", "intermediate", f))
for (s in steps) {
  cat("\n##########", s, "##########\n")
  st <- system2("C:/Program Files/R/R-4.6.1/bin/Rscript.exe", R(s), stdout = TRUE, stderr = TRUE)
  cat(paste(tail(st, 6), collapse = "\n"), "\n")
}
cat("\n全部完成。若需从零重算与 PINNED 字典的比对，请先运行 00_recompute_inputs.R\n")
