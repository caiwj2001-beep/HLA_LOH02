suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"; OUT <- file.path(ROOT,"iscience投稿版本/V2")
SCR  <- "C:/Users/Administrator/AppData/Local/hermes/cache/scratch/r3p3"
p <- readRDS(file.path(OUT,"r3p3_p_annot.rds"))
a <- fread(file.path(SCR,"ascna_hla.tsv"), sep="\t")
M <- t(as.matrix(a[,-1,with=FALSE])); rownames(M) <- names(a)[-1]; colnames(M) <- a$Hugo_Symbol
d <- fread(file.path(SCR,"cna_hla.tsv"), sep="\t")
Dm <- t(as.matrix(d[,-1,with=FALSE])); rownames(Dm) <- names(d)[-1]; colnames(Dm) <- d$Hugo_Symbol
ind <- p[grp=="Arm_independent"]
set.seed(1); smp <- sample(ind$SAMPLE_ID, 15)
cat("arm-independent HLA-LOH samples: clinical per-allele vs ascna (a;b) vs discrete\n")
print(data.table(SAMPLE=smp, ploidy=round(ind$ploidy[match(smp,ind$SAMPLE_ID)],2),
  A1=ind$HLA_A1_LOH[match(smp,ind$SAMPLE_ID)], A2=ind$HLA_A2_LOH[match(smp,ind$SAMPLE_ID)],
  B1=ind$HLA_B1_LOH[match(smp,ind$SAMPLE_ID)], C1=ind$HLA_C1_LOH[match(smp,ind$SAMPLE_ID)],
  ascA=M[smp,"HLA-A"], ascB=M[smp,"HLA-B"], ascC=M[smp,"HLA-C"],
  disA=Dm[smp,"HLA-A"], disB=Dm[smp,"HLA-B"], disC=Dm[smp,"HLA-C"]))
cat("\nHow many arm-independent samples have ANY HLA-A/B/C2 gene with clinical Loss?\n")
anyloss <- (ind$HLA_A_LOH=="Loss") | (ind$HLA_B_LOH=="Loss") | (ind$HLA_C_LOH=="Loss")
cat("any locus Loss:", sum(anyloss), "/", nrow(ind), "\n")
cat("HLA_A_LOH:\n"); print(table(ind$HLA_A_LOH))
cat("HLA_B_LOH:\n"); print(table(ind$HLA_B_LOH))
cat("HLA_C_LOH:\n"); print(table(ind$HLA_C_LOH))
# discrete: distribution among indep
cat("\n[arm-indep] discrete HLA-A:\n"); print(table(Dm[ind$SAMPLE_ID,"HLA-A"]))
cat("[arm-indep] discrete HLA-B:\n"); print(table(Dm[ind$SAMPLE_ID,"HLA-B"]))
cat("[arm-indep] discrete HLA-C:\n"); print(table(Dm[ind$SAMPLE_ID,"HLA-C"]))
# region-wide: use all 7 genes
reg <- c("HLA-A","HLA-B","HLA-C","NOTCH4","STK19","TAP1","TAP2")
sub <- M[ind$SAMPLE_ID, reg]
parse <- function(v){sp<-strsplit(v,";");matrix(c(vapply(sp,function(x)suppressWarnings(as.numeric(x[1])),numeric(1)),
                                                 vapply(sp,function(x)suppressWarnings(as.numeric(x[2])),numeric(1))),ncol=2)}
res <- t(apply(sub,1,function(r){
  f1<-f2<-rep(NA,length(r))
  for(i in seq_along(r)){sp<-strsplit(r[i],";")[[1]];f1[i]<-suppressWarnings(as.numeric(sp[1]));f2[i]<-suppressWarnings(as.numeric(sp[2]))}
  c(minminor=min(f2,na.rm=TRUE), mintot=min(f1+f2,na.rm=TRUE))
}))
cat("\n[arm-indep] region(7 genes) min minor distribution:\n"); print(table(res[,"minminor"], useNA="ifany"))
cat("[arm-indep] region min total distribution:\n"); print(table(res[,"mintot"], useNA="ifany"))
