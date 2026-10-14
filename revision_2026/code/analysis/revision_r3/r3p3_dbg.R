library(data.table)
SCR <- "C:/Users/Administrator/AppData/Local/hermes/cache/scratch/r3p3"
a <- fread(file.path(SCR,"ascna_hla.tsv"), sep="\t")
cat("dim:", dim(a), "\n")
cat("ncol:", ncol(a), " names[1..3]:", names(a)[1:3], "\n")
v <- a[[2]]
cat("len v:", length(v), "\n")
sp <- strsplit(v, ";")
cat("strsplit lens:", paste(head(sapply(sp, length), 20), collapse=","), "\n")
cat("cells:", v[1], "|", v[7], "\n")
cat("all lens unique:", unique(sapply(sp, length)), "\n")
