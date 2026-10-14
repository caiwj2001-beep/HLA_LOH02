suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"; OUT <- file.path(ROOT,"iscience投稿版本/V2")
SCR  <- "C:/Users/Administrator/AppData/Local/hermes/cache/scratch/r3p3"
p <- readRDS(file.path(OUT,"r3p3_p_annot.rds"))
a <- fread(file.path(SCR,"ascna_hla.tsv"), sep="\t")
M <- t(as.matrix(a[,-1,with=FALSE])); rownames(M) <- names(a)[-1]; colnames(M) <- a$Hugo_Symbol
reg <- c("HLA-A","HLA-B","HLA-C","NOTCH4","STK19","TAP1","TAP2")
pl <- setNames(p$ploidy, p$SAMPLE_ID)
ind <- p[grp=="Arm_independent"]$SAMPLE_ID; dep <- p[grp=="Arm_dependent"]$SAMPLE_ID
gx <- function(ids, genes) {
  m <- M[ids, genes]; tot <- matrix(NA_real_, length(ids), length(genes), dimnames=list(ids,genes))
  mn  <- tot
  for (j in seq_along(genes)) { sp<-strsplit(m[,j],";")
    f1<-vapply(sp,function(x)suppressWarnings(as.numeric(x[1])),numeric(1))
    f2<-vapply(sp,function(x)suppressWarnings(as.numeric(x[2])),numeric(1))
    tot[,j]<-f1+f2; mn[,j]<-pmin(f1,f2) }
  list(tot=tot, mn=mn)
}
for (nm in c("ind","dep")) {
  ids <- get(nm); g <- gx(ids, reg)
  rep_tot <- apply(g$tot,1,function(x) suppressWarnings(min(x,na.rm=TRUE)))
  rep_min <- apply(g$mn, 1,function(x) suppressWarnings(min(x,na.rm=TRUE)))
  rep_tot[!is.finite(rep_tot)] <- NA; rep_min[!is.finite(rep_min)] <- NA
  delta <- rep_tot - pl[ids]
  cat("\n=====", nm, "(n=", length(ids), ") =====\n")
  cat("rep_minor (min over region) table:\n"); print(table(rep_min, useNA="ifany"))
  cat("delta = rep_total - ploidy table:\n"); print(table(cut(delta, c(-Inf,-1.5,-0.5,0.5,1.5,Inf),
        labels=c("<=-1.5","-1 to -0.5","-0.5 to 0.5","0.5 to 1.5",">1.5")), useNA="ifany"))
  cat("2D: rep_minor(0 vs >0) x delta band:\n")
  print(table(rep_min=ifelse(rep_min==0,"minor0","minor>0"),
              delta=cut(delta, c(-Inf,-0.5,0.5,Inf), labels=c("loss","neutral","gain")), useNA="ifany"))
}
