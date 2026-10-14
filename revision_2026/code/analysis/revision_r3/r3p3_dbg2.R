suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"; OUT <- file.path(ROOT,"iscience投稿版本/V2")
SCR  <- "C:/Users/Administrator/AppData/Local/hermes/cache/scratch/r3p3"
p <- readRDS(file.path(OUT,"r3p3_p_annot.rds"))
a <- fread(file.path(SCR,"ascna_hla.tsv"), sep="\t")
M <- t(as.matrix(a[,-1,with=FALSE])); rownames(M) <- names(a)[-1]; colnames(M) <- a$Hugo_Symbol
ind <- p[grp=="Arm_independent"]
dep <- p[grp=="Arm_dependent"]
cat("HLA-A cells for 8 arm-independent samples:\n")
print(M[ind$SAMPLE_ID[1:8], c("HLA-A","HLA-B","HLA-C")])
cat("\nHLA-A cells for 8 arm-DEPENDENT (6p loss) samples:\n")
print(M[dep$SAMPLE_ID[1:8], c("HLA-A","HLA-B","HLA-C")])
# parse
minor0 <- function(ids, g) {
  v <- M[ids, g]; sp <- strsplit(v, ";")
  minor <- vapply(sp, function(x) suppressWarnings(as.numeric(x[2])), numeric(1))
  tot   <- vapply(sp, function(x) suppressWarnings(as.numeric(x[1])), numeric(1))
  list(tot=tot, minor=minor)
}
for (g in c("HLA-A","HLA-B","HLA-C")) {
  z <- minor0(ind$SAMPLE_ID, g)
  cat(sprintf("\n[indep] %s: minor==0 in %d/%d (%.1f%%); minor dist:\n", g, sum(z$minor==0,na.rm=TRUE), sum(!is.na(z$minor)), 100*mean(z$minor==0,na.rm=TRUE)))
  print(table(z$minor, useNA="ifany"))
}
for (g in c("HLA-A","HLA-B","HLA-C")) {
  z <- minor0(dep$SAMPLE_ID, g)
  cat(sprintf("\n[dep] %s: minor==0 in %d/%d (%.1f%%)\n", g, sum(z$minor==0,na.rm=TRUE), sum(!is.na(z$minor)), 100*mean(z$minor==0,na.rm=TRUE)))
}
# among indep: per-sample min minor
mm <- sapply(ind$SAMPLE_ID, function(s) {
  v <- M[s, c("HLA-A","HLA-B","HLA-C")]; sp <- strsplit(v,";")
  mi <- vapply(sp, function(x) suppressWarnings(as.numeric(x[2])), numeric(1))
  if (all(is.na(mi))) NA else min(mi, na.rm=TRUE)
})
cat("\n[indep] per-sample min(minor) across HLA-A/B/C:\n"); print(table(mm, useNA="ifany"))
md <- sapply(dep$SAMPLE_ID, function(s) {
  v <- M[s, c("HLA-A","HLA-B","HLA-C")]; sp <- strsplit(v,";")
  mi <- vapply(sp, function(x) suppressWarnings(as.numeric(x[2])), numeric(1))
  if (all(is.na(mi))) NA else min(mi, na.rm=TRUE)
})
cat("\n[dep] per-sample min(minor) across HLA-A/B/C:\n"); print(table(md, useNA="ifany"))
