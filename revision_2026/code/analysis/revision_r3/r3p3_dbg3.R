suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"; OUT <- file.path(ROOT,"iscience投稿版本/V2")
SCR  <- "C:/Users/Administrator/AppData/Local/hermes/cache/scratch/r3p3"
p <- readRDS(file.path(OUT,"r3p3_p_annot.rds"))
a <- fread(file.path(SCR,"ascna_hla.tsv"), sep="\t")
M <- t(as.matrix(a[,-1,with=FALSE])); rownames(M) <- names(a)[-1]; colnames(M) <- a$Hugo_Symbol
d <- fread(file.path(SCR,"cna_hla.tsv"), sep="\t")
Dm <- t(as.matrix(d[,-1,with=FALSE])); rownames(Dm) <- names(d)[-1]; colnames(Dm) <- d$Hugo_Symbol
ids <- p$SAMPLE_ID
ascA <- M[ids,"HLA-A"]; disA <- Dm[ids,"HLA-A"]
tab <- data.table(LOH_A=p$HLA_A1_LOH, asc=ascA, dis=disA)
cat("HLA-A ascna vs discrete:\n"); print(table(tab$asc, tab$dis, useNA="ifany"))
cat("\nHLA-A ascna vs per-allele LOH status (Loss/Unchanged):\n")
print(table(tab$asc, tab$LOH_A, useNA="ifany"))
# focus: within arm-independent group
sub <- tab[ids %in% p[grp=="Arm_independent"]$SAMPLE_ID]
cat("\n[arm-independent] ascna vs discrete:\n"); print(table(sub$asc, sub$dis))
cat("[arm-independent] ascna vs LOH_A:\n"); print(table(sub$asc, sub$LOH_A))
# 6p-arm-dependent
sub2 <- tab[ids %in% p[grp=="Arm_dependent"]$SAMPLE_ID]
cat("\n[arm-dependent] ascna vs discrete:\n"); print(table(sub2$asc, sub2$dis))
# what fraction of indep have HLA_A1_LOH==Loss?
cat("\nindep HLA_A1_LOH:\n"); print(table(p[grp=="Arm_independent"]$HLA_A1_LOH))
cat("indep HLA_A2_LOH:\n"); print(table(p[grp=="Arm_independent"]$HLA_A2_LOH))
# per-allele: which allele
cat("\nFor indep rows with A1 Loss: asc values:\n"); print(table(ascA[p$grp %in% "Arm_independent" & p$HLA_A1_LOH=="Loss"]))
