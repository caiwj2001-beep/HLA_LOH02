suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"; OUT <- file.path(ROOT,"iscience投稿版本/V2")
SCR  <- "C:/Users/Administrator/AppData/Local/hermes/cache/scratch/r3p3"
p <- readRDS(file.path(OUT,"r3p3_p_annot.rds"))
a <- fread(file.path(SCR,"ascna_hla.tsv"), sep="\t")
M <- t(as.matrix(a[,-1,with=FALSE])); rownames(M) <- names(a)[-1]; colnames(M) <- a$Hugo_Symbol
pl <- p$ploidy[match(rownames(M), p$SAMPLE_ID)]
parse <- function(g) {
  v <- M[,g]; sp <- strsplit(v,";")
  f1 <- vapply(sp, function(x) suppressWarnings(as.numeric(x[1])), numeric(1))
  f2 <- vapply(sp, function(x) suppressWarnings(as.numeric(x[2])), numeric(1))
  data.table(f1=f1, f2=f2, sum=f1+f2)
}
z <- parse("HLA-A"); z[, ploidy := pl]
z[, ploidy_bin := cut(ploidy, c(0,2.05,2.6,3.2,Inf), labels=c("~2","2.05-2.6","2.6-3.2",">3.2"))]
cat("=== HLA-A: modal value by ploidy bin ===\n")
for (b in levels(z$ploidy_bin)) {
  sub <- z[ploidy_bin==b]
  cat(sprintf("\nploidy %s (n=%d): top ascna values\n", b, nrow(sub)))
  print(head(sort(table(paste0(sub$f1,";",sub$f2)), decreasing=TRUE), 8))
}
cat("\n=== mean sum / mean f1 / mean f2 by ploidy bin ===\n")
print(z[, .(n=.N, mean_sum=mean(sum,na.rm=TRUE), med_sum=as.numeric(median(sum,na.rm=TRUE)),
            mean_f1=mean(f1,na.rm=TRUE), mean_f2=mean(f2,na.rm=TRUE)), by=ploidy_bin])
# correlation of sum with ploidy among non-LOH region
cat("\ncor(sum, ploidy) =", cor(z$sum, z$ploidy, use="complete.obs"), "\n")
cat("cor(f1, ploidy)  =", cor(z$f1, z$ploidy, use="complete.obs"), "\n")
cat("cor(f2, ploidy)  =", cor(z$f2, z$ploidy, use="complete.obs"), "\n")
