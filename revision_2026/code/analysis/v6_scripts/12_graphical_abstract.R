################################################################################
# HLA_LOH02 - Graphical Abstract (Cancer Cell style) — v2 layout fix
# Fixes: (1) vertical arrow no longer pierces the APOBEC box (routed via center x=50)
#        (2) frequency-box bar labels moved to the RIGHT of bars (no text overlap)
#        (3) bottom band taller + 2-line shorter text that stays inside the band
################################################################################
suppressMessages({library(ggplot2); library(grid); library(data.table)})

OUT <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/04_processed_data"
RES <- file.path(OUT,"results")
PNG <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/06_figures_png"
TIF <- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/07_figures_tiff"

NAVY<-"#003366"; RED<-"#C0392B"; TEAL<-"#1F8A70"; GOLD<-"#D4A017"; GREY<-"#7F8C8D"
LNAVY<-"#5B7FA6"; BG<-"#F0F5FA"

q1 <- fread(file.path(RES,"Q1_pancancer_atlas.tsv"))
sv <- fread(file.path(RES,"Survival_by_cancer.tsv"))

gp <- ggplot() + xlim(0,100) + ylim(0,100) + theme_void() +
  theme(plot.background=element_rect(fill="white",colour=NA), plot.margin=margin(4,4,4,4))

box <- function(g,x,y,w,h,fill,label,sub=NULL,tcol="white",cex=4.4,scex=3.1){
  g <- g + annotate("rect", xmin=x-w/2, xmax=x+w/2, ymin=y-h/2, ymax=y+h/2, fill=fill, colour=NA)
  if(nzchar(label))
    g <- g + annotate("text", x=x, y=y+(if(!is.null(sub)) 2.0 else 0), label=label,
                      colour=tcol, fontface=2, size=cex, lineheight=0.9)
  if(!is.null(sub))
    g <- g + annotate("text", x=x, y=y-2.8, label=sub, colour=tcol, size=scex, lineheight=0.9)
  g
}
arrow_h <- function(g,x0,x1,y,col,lab=NULL){
  g <- g + annotate("segment", x=x0, xend=x1, y=y, yend=y, colour=col, linewidth=1.5,
                    arrow=arrow(length=unit(0.28,"cm"),type="closed"))
  if(!is.null(lab)) g <- g + annotate("text", x=(x0+x1)/2, y=y+3.2, label=lab,
                                       colour=col, size=2.9, fontface=3)
  g
}

g <- gp
# ── Title ──────────────────────────────────────────────────────────────────────
g <- g + annotate("text", x=50, y=97.5,
  label="A genome-doubling–driven, chromosome-6p–mediated pathway to HLA loss of heterozygosity",
  fontface=2, colour=NAVY, size=4.0)
g <- g + annotate("text", x=50, y=93,
  label="54,331 tumors · MSK-IMPACT 50K · pan-cancer", fontface=3, colour=GREY, size=3.1)

# ── Row 1: cascade (centers y=77, boxes h=14 -> y[70,84]) ──────────────────────
yc <- 77
g <- box(g, 15, yc, 22, 14, NAVY, "Whole-genome\ndoubling", "43.7% of LOH tumors")
g <- arrow_h(g, 26.5, 32.5, yc, TEAL, "drives")
g <- box(g, 44, yc, 22, 14, TEAL, "Chromosome\n6p loss", "6p21.3 harbors HLA")
g <- arrow_h(g, 55.5, 67.5, yc, RED, "produces")
g <- box(g, 81, yc, 24, 14, RED,  "HLA LOH", "loss of class I allele")
g <- g + annotate("text", x=44, y=67.5,
  label="Formal mediation: 6p loss carries the entire WGD effect (ACME 0.26, 95% CI 0.25–0.27)",
  colour=GREY, size=2.8, fontface=3)

# ── Row 2: modulators (centers y=53, boxes h=11 -> y[47.5,58.5]) ───────────────
g <- box(g, 18, 53, 28, 11, GOLD, "Germline HLA homozygosity", "constrains loss · OR 0.79/locus",
         tcol="white", cex=3.2, scex=2.7)
g <- box(g, 82, 53, 26, 11, LNAVY, "APOBEC + tobacco\nmutagenesis", "co-occur · high TMB",
         tcol="white", cex=3.1, scex=2.6)
# germline -> HLA LOH (dashed, routed through empty upper corridor, clears APOBEC top=58.5)
g <- g + annotate("segment", x=32, xend=72, y=58, yend=70, colour=GOLD, linewidth=1.1,
                  linetype="22", arrow=arrow(length=unit(0.22,"cm")))
# APOBEC -> HLA LOH (straight up into box bottom at y=70, clear of everything)
g <- g + annotate("segment", x=82, xend=82, y=58.5, yend=69.6, colour=LNAVY, linewidth=1.2,
                  arrow=arrow(length=unit(0.24,"cm"),type="closed"))

# ── Cascade -> consequences: single arrow down the CENTER corridor (x=50) ───────
g <- g + annotate("segment", x=50, xend=50, y=64, yend=40.5, colour=NAVY, linewidth=1.5,
                  arrow=arrow(length=unit(0.30,"cm"),type="closed"))
g <- g + annotate("text", x=50, y=38.2, label="CONSEQUENCES", fontface=2, colour=NAVY, size=3.4)

# ── Row 3: consequences (centers y=23, boxes h=22 -> y[12,34]) ─────────────────
# (1) pan-cancer frequency — labels to the RIGHT of bars (no overlap)
g <- box(g, 18, 23, 32, 22, BG, "")
g <- g + annotate("text", x=18, y=32, label="Pan-cancer 25.3%", fontface=2, colour=NAVY, size=3.2)
top5 <- q1[order(-freq)][1:5]
yy <- 28
for(i in 1:5){
  r <- top5[i]
  g <- g + annotate("rect", xmin=5, xmax=5+18*r$freq, ymin=yy-0.9, ymax=yy+0.9, fill=NAVY) +
    annotate("text", x=5+18*r$freq+1, y=yy,
             label=sprintf("%s %.0f%%", gsub(" Cancer","",r$CANCER_TYPE), 100*r$freq),
             hjust=0, size=2.2, colour="grey20")
  yy <- yy-3.2
}

# (2) immune escape
g <- box(g, 50, 23, 26, 22, BG, "")
g <- g + annotate("text", x=50, y=31, label="Immune escape", fontface=2, colour=RED, size=3.2)
g <- g + annotate("text", x=50, y=23,
                  label="↓ presentable neoantigens\n↑ T-cell evasion\n↑ tumor mutational burden",
                  colour="grey20", size=2.8, lineheight=1.1)

# (3) survival
g <- box(g, 82, 23, 30, 22, BG, "")
g <- g + annotate("text", x=82, y=32, label="Worse survival", fontface=2, colour=NAVY, size=3.2)
sig <- sv[FDR<0.05][order(-HR)][1:5]
yy <- 28
for(i in 1:nrow(sig)){
  r <- sig[i]
  g <- g + annotate("text", x=69, y=yy,
       label=sprintf("%s  HR %.2f", gsub(" Cancer| Carcinoma","",r$CANCER_TYPE), r$HR),
       hjust=0, size=2.2, colour="grey20")
  yy <- yy-3.2
}

# ── Bottom takeaway band (taller; 2 short lines that stay inside the band) ──────
g <- g + annotate("rect", xmin=3, xmax=97, ymin=1.5, ymax=10.5, fill=NAVY)
g <- g + annotate("text", x=50, y=7.4,
  label="HLA LOH is not an isolated lesion but the readout of a definable genomic cascade —",
  colour="white", fontface=2, size=2.7)
g <- g + annotate("text", x=50, y=4.0,
  label="resolving its upstream drivers, mutational context, and clinical impact across human cancer",
  colour="white", fontface=2, size=2.7)

ggsave(file.path(PNG,"Graphical_Abstract.png"), g, width=9, height=8, dpi=300, bg="white")
ggsave(file.path(TIF,"Graphical_Abstract.tiff"), g, width=9, height=8, dpi=300, bg="white",
       compression="lzw", device="tiff")
cat("Saved Graphical Abstract v2 (PNG + TIFF, 9x8in @300dpi)\n")
