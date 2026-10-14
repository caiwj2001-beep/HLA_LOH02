################################################################################
# HLA_LOH02 - Script 05: Publication Figures (Fig 1-5)
# Outputs PNG (300 dpi) + TIFF (300 dpi, LZW) to 06_figures_png / 07_figures_tiff
################################################################################
suppressMessages({
  library(data.table); library(ggplot2); library(scales)
  library(ggrepel); library(patchwork); library(survival); library(survminer)
})

OUT <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/04_processed_data"
RES <- file.path(OUT,"results")
PNG <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/06_figures_png"
TIF <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/07_figures_tiff"
dir.create(PNG, showWarnings=FALSE, recursive=TRUE)
dir.create(TIF, showWarnings=FALSE, recursive=TRUE)

# ── House style ────────────────────────────────────────────────────────────────
NAVY <- "#003366"; RED <- "#C0392B"; TEAL <- "#1F8A70"; GOLD <- "#D4A017"; GREY <- "#7F8C8D"
theme_pub <- function(base=11) theme_classic(base_size=base) +
  theme(axis.title=element_text(face="bold", colour=NAVY),
        axis.text=element_text(colour="grey20"),
        plot.title=element_text(face="bold", colour=NAVY, size=base+2),
        plot.subtitle=element_text(colour="grey40", size=base-1),
        legend.title=element_text(face="bold", colour=NAVY),
        strip.background=element_rect(fill="#EAF0F6", colour=NA),
        strip.text=element_text(face="bold", colour=NAVY))
save_fig <- function(p, name, w, h) {
  ggsave(file.path(PNG,paste0(name,".png")), p, width=w, height=h, dpi=300, bg="white")
  ggsave(file.path(TIF,paste0(name,".tiff")), p, width=w, height=h, dpi=300,
         bg="white", compression="lzw", device="tiff")
  cat("  saved", name, "\n")
}

m  <- readRDS(file.path(OUT,"master_cohort.rds"))
D  <- m[analysis_primary==TRUE]
D[, WGD := FACETS_WGD=="TRUE"]          # derive (only existed in analysis scope)
q1 <- fread(file.path(RES,"Q1_pancancer_atlas.tsv"))
q3 <- fread(file.path(RES,"Q3_multivariable_drivers.tsv"))
q4 <- fread(file.path(RES,"Q4_signatures_vs_LOH.tsv"))
sv <- fread(file.path(RES,"Survival_by_cancer.tsv"))
km <- fread(file.path(RES,"km_data.tsv"))

################################################################################
# FIGURE 1 — Pan-cancer atlas of HLA LOH
################################################################################
cat("Figure 1...\n")
q1[, CANCER_TYPE := factor(CANCER_TYPE, levels=CANCER_TYPE[order(freq)])]
f1a <- ggplot(q1, aes(x=CANCER_TYPE, y=100*freq)) +
  geom_col(fill=NAVY, width=0.7) +
  geom_errorbar(aes(ymin=100*lo, ymax=100*hi), width=0.3, colour=GREY) +
  geom_hline(yintercept=100*0.253, linetype="dashed", colour=RED) +
  annotate("text", x=3, y=28, label="Pan-cancer 25.3%", colour=RED, size=3, hjust=0) +
  coord_flip() +
  labs(x=NULL, y="HLA LOH frequency (%)",
       title="A  Pan-cancer landscape of HLA loss of heterozygosity",
       subtitle=sprintf("%d evaluable tumors across %d cancer types", nrow(D), nrow(q1))) +
  theme_pub()

# Per-locus stacked
loc <- melt(q1[, .(CANCER_TYPE, `HLA-A`=100*freq_A, `HLA-B`=100*freq_B, `HLA-C`=100*freq_C)],
            id.vars="CANCER_TYPE", variable.name="Locus", value.name="freq")
f1b <- ggplot(loc, aes(x=CANCER_TYPE, y=freq, fill=Locus)) +
  geom_col(position="dodge", width=0.75) +
  scale_fill_manual(values=c("HLA-A"=NAVY,"HLA-B"=TEAL,"HLA-C"=GOLD)) +
  coord_flip() +
  labs(x=NULL, y="Locus-specific LOH (%)", title="B  Locus-specific HLA LOH") +
  theme_pub() + theme(legend.position="top")

F1 <- f1a + f1b + plot_layout(widths=c(1.15,1))
save_fig(F1, "Figure1_pancancer_atlas", 13, 8)

################################################################################
# FIGURE 2 — HLA LOH vs TMB
################################################################################
cat("Figure 2...\n")
# 2A: TMB distribution by LOH status (top cancers)
topc <- q1[order(-N)][1:9]$CANCER_TYPE
d2 <- D[CANCER_TYPE %in% as.character(topc) & !is.na(TMB_SCORE)]
d2[, LOH := factor(fifelse(any_HLA_LOH,"HLA LOH","HLA intact"), levels=c("HLA intact","HLA LOH"))]
f2a <- ggplot(d2, aes(x=LOH, y=TMB_SCORE, fill=LOH)) +
  geom_boxplot(outlier.size=0.3, alpha=0.85) +
  scale_y_log10(labels=comma) +
  scale_fill_manual(values=c("HLA intact"=GREY,"HLA LOH"=NAVY), guide="none") +
  facet_wrap(~CANCER_TYPE, nrow=3) +
  labs(x=NULL, y="TMB (mut/Mb, log scale)",
       title="A  Tumor mutational burden by HLA LOH status") +
  theme_pub()

# 2B: forest of per-cancer TMB odds (from Q2 table freq diff → use OR proxy via medians)
q2 <- fread(file.path(RES,"Q2_TMB_by_cancer.tsv"))
q2[, sig := fifelse(FDR<0.05,"FDR<0.05","n.s.")]
q2[, delta := med_TMB_LOH - med_TMB_noLOH]
q2 <- q2[order(delta)]
q2[, CANCER_TYPE := factor(CANCER_TYPE, levels=CANCER_TYPE)]
f2b <- ggplot(q2, aes(x=delta, y=CANCER_TYPE, colour=sig)) +
  geom_vline(xintercept=0, linetype="dashed", colour=GREY) +
  geom_point(size=2.4) +
  scale_colour_manual(values=c("FDR<0.05"=RED,"n.s."=GREY), name=NULL) +
  labs(x="Δ median TMB (LOH − intact)", y=NULL,
       title="B  TMB elevation with HLA LOH by cancer") +
  theme_pub() + theme(legend.position="top")

F2 <- f2a + f2b + plot_layout(widths=c(1.4,1))
save_fig(F2, "Figure2_TMB_association", 13, 7.5)

################################################################################
# FIGURE 3 — Mechanistic drivers (the core)
################################################################################
cat("Figure 3...\n")
# 3A: driver forest (distal + proximal)
q3[, label := c("WGD (distal)","Germline HLA homozygosity","log10 TMB","6p arm loss (proximal)")[match(term, c("WGDTRUE","germ_hom_anyTRUE","log_TMB","arm_6p_loss"))]]
q3[, label := factor(label, levels=label[order(OR)])]
f3a <- ggplot(q3, aes(x=OR, y=label, colour=model)) +
  geom_vline(xintercept=1, linetype="dashed", colour=GREY) +
  geom_errorbarh(aes(xmin=lo, xmax=hi), height=0.2) +
  geom_point(size=3) +
  scale_x_log10() +
  scale_colour_manual(values=c("distal"=NAVY,"proximal"=RED), name="Driver class") +
  labs(x="Odds ratio for HLA LOH (log scale)", y=NULL,
       title="A  Genomic drivers of HLA LOH",
       subtitle="Multivariable logistic regression (adj. cancer type, panel, purity)") +
  theme_pub() + theme(legend.position="top")

# 3B: WGD mediation via 6p (grouped bars)
med <- D[!is.na(arm_6p_loss) & !is.na(WGD)]
med[, grp := fifelse(WGD, "WGD+", "WGD-")]
med2 <- med[, .(freq_LOH=mean(any_HLA_LOH), freq_6p=mean(arm_6p_loss)), by=grp]
med2m <- melt(med2, id.vars="grp", variable.name="event", value.name="freq")
med2m[, event := factor(event, levels=c("freq_6p","freq_LOH"),
                        labels=c("6p arm loss","HLA LOH"))]
f3b <- ggplot(med2m, aes(x=grp, y=100*freq, fill=event)) +
  geom_col(position="dodge", width=0.7) +
  scale_fill_manual(values=c("6p arm loss"=TEAL,"HLA LOH"=NAVY), name=NULL) +
  labs(x=NULL, y="Frequency (%)",
       title="B  WGD acts through 6p loss",
       subtitle="WGD→HLA LOH OR 2.36 → 0.28 after 6p adjustment") +
  theme_pub() + theme(legend.position="top")

# 3C: overlap of HLA LOH and 6p loss (concordance)
conc <- D[!is.na(arm_6p_loss)]
conc[, cat := fifelse(any_HLA_LOH & arm_6p_loss,"Both",
              fifelse(any_HLA_LOH & !arm_6p_loss,"HLA LOH only (focal/CN-LOH)",
              fifelse(!any_HLA_LOH & arm_6p_loss,"6p loss only","Neither")))]
cc <- conc[, .N, by=cat][, pct := 100*N/sum(N)]
cc[, cat := factor(cat, levels=c("Neither","6p loss only","HLA LOH only (focal/CN-LOH)","Both"))]
f3c <- ggplot(cc, aes(x="", y=pct, fill=cat)) +
  geom_col(width=1) + coord_polar("y") +
  scale_fill_manual(values=c("Neither"="grey85","6p loss only"=TEAL,
      "HLA LOH only (focal/CN-LOH)"=GOLD,"Both"=NAVY), name=NULL) +
  labs(title="C  HLA LOH vs 6p arm loss", 
       subtitle="28.3% of HLA LOH is 6p-independent") +
  theme_void(base_size=11) +
  theme(plot.title=element_text(face="bold", colour=NAVY),
        plot.subtitle=element_text(colour="grey40", size=10),
        legend.position="right", legend.text=element_text(size=8))

F3 <- (f3a + f3b) / f3c + plot_layout(heights=c(1,1))
save_fig(F3, "Figure3_mechanism", 12, 9)

################################################################################
# FIGURE 4 — Mutational processes
################################################################################
cat("Figure 4...\n")
q4[, proc := c("APOBEC","HRD","MMR","Smoking","UV","Aging")[match(signature,
    c("sig_APOBEC","sig_HRD","sig_MMR","sig_smoke","sig_UV","sig_aging"))]]
q4[, log2fc := log2((mean_LOH+1e-3)/(mean_noLOH+1e-3))]
q4[, sig := fifelse(FDR<0.05, "FDR<0.05","n.s.")]
q4[, proc := factor(proc, levels=proc[order(log2fc)])]
f4a <- ggplot(q4, aes(x=log2fc, y=proc, fill=sig)) +
  geom_vline(xintercept=0, linetype="dashed", colour=GREY) +
  geom_col(width=0.65) +
  scale_fill_manual(values=c("FDR<0.05"=RED,"n.s."=GREY), name=NULL) +
  labs(x="log2 fold-change (LOH / intact)", y=NULL,
       title="A  Mutational processes enriched with HLA LOH") +
  theme_pub() + theme(legend.position="top")

# 4B: APOBEC contribution distribution
d4 <- D[sig_available==TRUE]
d4[, LOH := factor(fifelse(any_HLA_LOH,"HLA LOH","HLA intact"), levels=c("HLA intact","HLA LOH"))]
f4b <- ggplot(d4[sig_APOBEC>0.01], aes(x=LOH, y=sig_APOBEC, fill=LOH)) +
  geom_violin(alpha=0.8) + geom_boxplot(width=0.15, outlier.shape=NA, alpha=0.9) +
  scale_fill_manual(values=c("HLA intact"=GREY,"HLA LOH"=NAVY), guide="none") +
  labs(x=NULL, y="APOBEC signature contribution",
       title="B  APOBEC mutagenesis and HLA LOH",
       subtitle="Adjusted OR 1.22 per unit (p=0.02)") +
  theme_pub()

F4 <- f4a + f4b + plot_layout(widths=c(1.1,1))
save_fig(F4, "Figure4_mutational_processes", 12, 6)

################################################################################
# FIGURE 5 — Survival
################################################################################
cat("Figure 5...\n")
# 5A: per-cancer HR forest
sv[, CANCER_TYPE := factor(CANCER_TYPE, levels=CANCER_TYPE[order(HR)])]
sv[, sig := fifelse(FDR<0.05,"FDR<0.05","n.s.")]
f5a <- ggplot(sv, aes(x=HR, y=CANCER_TYPE, colour=sig)) +
  geom_vline(xintercept=1, linetype="dashed", colour=GREY) +
  geom_errorbarh(aes(xmin=lo, xmax=hi), height=0.25) +
  geom_point(size=2.4) +
  scale_x_log10() +
  scale_colour_manual(values=c("FDR<0.05"=RED,"n.s."=GREY), name=NULL) +
  labs(x="Hazard ratio for overall survival (log scale)", y=NULL,
       title="A  HLA LOH and survival by cancer type",
       subtitle="Cox models adj. age, sex, TMB") +
  theme_pub() + theme(legend.position="top")

# 5B: pan-cancer KM by LOH burden
km[, burden := factor(HLA_LOH_burden, levels=0:3,
     labels=c("No LOH","1 locus","2 loci","3 loci (pan-HLA)"))]
fit_km <- survfit(Surv(OS_MONTHS, OS_event) ~ burden, data=km)
g5b <- ggsurvplot(fit_km, data=km, palette=c(GREY,GOLD,TEAL,NAVY),
    conf.int=FALSE, censor=FALSE, risk.table=FALSE, legend.title="HLA LOH burden",
    legend.labs=levels(km$burden), xlab="Months", ylab="Overall survival",
    ggtheme=theme_pub())
f5b <- g5b$plot + labs(title="B  Survival by HLA LOH burden (pan-cancer)") +
  theme(legend.position="right")

F5 <- f5a + f5b + plot_layout(widths=c(1,1.15))
save_fig(F5, "Figure5_survival", 13, 7)

cat("\n=== ALL FIGURES COMPLETE ===\n")
cat("PNG dir:", PNG, "\nTIFF dir:", TIF, "\n")
