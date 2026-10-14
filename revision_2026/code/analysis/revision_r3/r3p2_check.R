p <- c(0.0693,0.0379,0.227,0.172,0.0877)
cat("BH:", signif(p.adjust(p,"BH"),3), "\n")
cat("attn M0->M1:", round(100*(1-log(1.2417)/log(1.5749)),1), "%\n")
cat("MMR match pct:", round(100*45579/53232,2), "%\n")
