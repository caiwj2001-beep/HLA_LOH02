suppressMessages(library(data.table))
OUT <- "C:/Users/Administrator/科研文件/HLA_LOH02/iscience投稿版本/V2"
t1 <- fread(file.path(OUT,"r3p3_task1_rows.tsv"))
t2 <- fread(file.path(OUT,"r3p3_task2_rows.tsv"))
t1[, Source := "TASK1_chr6excluded_aneuploidy"]; t2[, Source := "TASK2_arm_independent"]
comb <- rbindlist(list(t1, t2), fill=TRUE)
setcolorder(comb, c("Source","Section","Item"))
fwrite(comb, file.path(OUT,"REVIEWER3_part3_spec_and_armindependent.tsv"), sep="\t")
cat("combined rows:", nrow(comb), " sections:\n"); print(table(comb$Source, comb$Section))
