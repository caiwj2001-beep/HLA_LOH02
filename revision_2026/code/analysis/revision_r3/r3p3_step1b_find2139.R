## find what equals ~2139 / 28.3%
suppressMessages(library(data.table))
ROOT <- "C:/Users/Administrator/科研文件/HLA_LOH02"
mc <- readRDS(file.path(ROOT,"iscience投稿版本/V2/r3p3_mc_explore.rds"))
mc[, LOH := any_HLA_LOH=="TRUE"]
cat("all samples:", nrow(mc), " LOH all:", sum(mc$LOH, na.rm=TRUE), "\n")
p <- mc[analysis_primary=="TRUE"]
cat("primary:", nrow(p), " LOH:", sum(p$LOH), "\n")

cand <- function(x, label) cat(sprintf("%-70s n=%d  (%.2f%%)\n", label, x, 100*0))
sink <- function(...) NULL

# candidate definitions of "no 6p loss"
a <- p[LOH==TRUE]
cat("\n--- within primary HLA LOH (n=", nrow(a), ") ---\n", sep="")
cat("arm_6p_loss FALSE:", sum(a$arm_6p_loss=="FALSE"), "\n")
cat("arm_6p_loss FALSE (as logical):", sum(a$arm_6p_loss==FALSE, na.rm=TRUE), "\n")
cat("arm_6p_loss not TRUE (FALSE+NA):", sum(a$arm_6p_loss!="TRUE"), "\n")
cat("arm_6p != 'Loss' (any):", sum(a$arm_6p != "Loss"), "\n")
cat("arm_6p in Unchanged/Gain:", sum(a$arm_6p %in% c("Unchanged","Gain")), "\n")
cat("arm_6p == 'Unchanged':", sum(a$arm_6p=="Unchanged"), "\n")
cat("arm_6p == 'Gain':", sum(a$arm_6p=="Gain"), "\n")
cat("arm_6p available (not blank):", sum(a$arm_6p != ""), "\n")

cat("\n--- within ALL HLA LOH ---\n")
b <- mc[LOH==TRUE]
cat("n LOH all:", nrow(b), "\n")
cat("arm_6p_loss FALSE:", sum(b$arm_6p_loss=="FALSE"), "\n")
cat("arm_6p available and != Loss:", sum(b$arm_6p %in% c("Unchanged","Gain")), "\n")
cat("arm_6p available & not Loss, denominator=n available:\n")
nav <- sum(b$arm_6p %in% c("Unchanged","Gain","Loss"))
cat("  n available (Unchanged/Gain/Loss):", nav, " nonloss:", sum(b$arm_6p %in% c("Unchanged","Gain")),
    " pct:", round(100*sum(b$arm_6p %in% c("Unchanged","Gain"))/nav,2), "\n")

cat("\n--- primary, denominator = 6p available ---\n")
navp <- sum(p$arm_6p %in% c("Unchanged","Gain","Loss"))
cat("  6p available:", navp, " nonloss:", sum(p$arm_6p %in% c("Unchanged","Gain")),
    " pct:", round(100*sum(p$arm_6p %in% c("Unchanged","Gain"))/navp,2), "\n")

cat("\n--- within primary LOH: nonloss / 6p available ---\n")
cat("  ", sum(a$arm_6p %in% c("Unchanged","Gain")), "/", sum(a$arm_6p %in% c("Unchanged","Gain","Loss")),
    "=", round(100*sum(a$arm_6p %in% c("Unchanged","Gain"))/sum(a$arm_6p %in% c("Unchanged","Gain","Loss")),2), "%\n")

# (a / 6p available) primary LOH =  ??
# search 2139
for (v in c(sum(a$arm_6p %in% c("Unchanged","Gain")), sum(a$arm_6p_loss=="FALSE"),
            sum(a$arm_6p_loss!="TRUE"), sum(a$arm_6p!="Loss"))) cat(v, " ")
cat("\n")

# maybe fishers of 2139 in another table? print arm_6p x any_HLA_LOH in primary
cat("\narm_6p x LOH (primary):\n"); print(table(p$arm_6p, p$LOH, useNA="ifany"))
cat("\nburden among LOH no6ploss:\n"); print(table(a[arm_6p %in% c("Unchanged","Gain")]$HLA_LOH_burden))
