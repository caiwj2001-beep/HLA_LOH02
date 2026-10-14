################################################################################
# HLA_LOH02 - Script 15: Germline HLA zygosity constrains somatic HLA LOH
#  Two linked findings from REAL data:
#   (1) Methodological: locus-specific germline homozygosity -> that locus is
#       non-evaluable for LOH (0% evaluable), because LOH requires heterozygosity.
#   (2) Biological: germline homozygosity BURDEN (0/1/2 loci) shows a dose-dependent
#       inverse association with somatic HLA LOH -> germline sets the escape substrate.
# Outputs: SuppTable7 (evaluability x zygosity), results tsv, Figure 6 (PNG+TIFF).
################################################################################
suppressMessages({library(data.table); library(ggplot2)})
DD <- "C:/Users/Administrator/科研文件/HLA_LOH02/msk_impact_50k_2026"
OUT<- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/04_processed_data"
RES<- file.path(OUT,"results")
PNG<- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/06_figures_png"
TIF<- "C:/Users/Administrator/科研文件/HLA_LOH02/V6/07_figures_tiff"
set.seed(42); msg<-function(...)cat(sprintf(...),"\n")
NAVY<-"#003366"; RED<-"#C0392B"; TEAL<-"#1F8A70"; GOLD<-"#D4A017"; GREY<-"#7F8C8D"

s<-fread(file.path(DD,"data_clinical_sample.txt"),skip=4,header=TRUE,na.strings=c("NA",""))
p<-fread(file.path(DD,"data_clinical_patient.txt"),skip=4,header=TRUE,na.strings=c("NA",""))
for(loc in c("A","B","C")){
  a1<-p[[paste0("HLA-",loc,"1")]]; a2<-p[[paste0("HLA-",loc,"2")]]
  p[[paste0("gh_",loc)]]<-(!is.na(a1)&!is.na(a2)&a1==a2)
}
p[, AGE_AT_DX:=as.numeric(AGE_AT_DX)]
pk<-p[,.(PATIENT_ID,gh_A,gh_B,gh_C,HLA_GENOTYPE_AVAILABLE,SEX,AGE_AT_DX,ANCESTRY_LABEL)]
D<-merge(s,pk,by="PATIENT_ID",all.x=TRUE)
D[, callA:=!is.na(HLA_A1_LOH)|!is.na(HLA_A2_LOH)]
D[, callB:=!is.na(HLA_B1_LOH)|!is.na(HLA_B2_LOH)]
D[, callC:=!is.na(HLA_C1_LOH)|!is.na(HLA_C2_LOH)]

# ── Finding 1: evaluability x zygosity (locus-level) ──────────────────────────
ev_tab<-rbindlist(lapply(c("A","B","C"),function(loc){
  gh<-paste0("gh_",loc); cl<-paste0("call",loc)
  sub<-D[HLA_GENOTYPE_AVAILABLE=="TRUE"&!is.na(get(gh))]
  data.table(Locus=paste0("HLA-",loc),
    Heteroz_N=sum(!sub[[gh]]), Heteroz_evaluable_pct=round(100*mean(sub[!get(gh)==TRUE][[cl]]),1),
    Homoz_N=sum(sub[[gh]]), Homoz_evaluable_pct=round(100*mean(sub[get(gh)==TRUE][[cl]]),1))
}))
fwrite(ev_tab, file.path(RES,"SuppTable7_zygosity_evaluability.tsv"), sep="\t")
msg("=== Finding 1: locus zygosity x evaluability ==="); print(ev_tab)

# ── Finding 2: homozygosity burden vs somatic LOH (dose-response) ──────────────
hla<-c("HLA_A1_LOH","HLA_A2_LOH","HLA_B1_LOH","HLA_B2_LOH","HLA_C1_LOH","HLA_C2_LOH")
D[, eval:=rowSums(!is.na(.SD))>0,.SDcols=hla]
D[, anyLOH:=rowSums(.SD=="Loss",na.rm=TRUE)>0,.SDcols=hla]
D[, TMB_SCORE:=as.numeric(TMB_SCORE)]; D[, log_TMB:=log10(pmax(TMB_SCORE,0)+0.1)]
D[, WGD:=FACETS_WGD=="TRUE"]; D[, gh_burden:=(gh_A%in%TRUE)+(gh_B%in%TRUE)+(gh_C%in%TRUE)]
E<-D[eval==TRUE & HLA_GENOTYPE_AVAILABLE=="TRUE" & FACETS_QC=="Pass"]
setorder(E,PATIENT_ID,-eval); E<-E[,.SD[1],by=PATIENT_ID]
E[, cancer_f:=factor(CANCER_TYPE)]

dose<-E[,.(N=.N, LOH_n=sum(anyLOH), LOH_pct=round(100*mean(anyLOH),1)),by=gh_burden][order(gh_burden)]
# Wilson CI
wil<-function(x,n){p<-x/n;z<-1.96;d<-1+z^2/n
  c((p+z^2/(2*n)-z*sqrt(p*(1-p)/n+z^2/(4*n^2)))/d,(p+z^2/(2*n)+z*sqrt(p*(1-p)/n+z^2/(4*n^2)))/d)}
dose[, `:=`(lo=100*mapply(function(x,n)wil(x,n)[1],LOH_n,N),
            hi=100*mapply(function(x,n)wil(x,n)[2],LOH_n,N))]
fwrite(dose, file.path(RES,"germline_burden_dose_response.tsv"), sep="\t")
msg("\n=== Finding 2: homozygosity burden dose-response ==="); print(dose)

# univariable + adjusted trend
uni<-glm(anyLOH~gh_burden,data=E,family=binomial); su<-summary(uni)$coefficients
adj<-glm(anyLOH~gh_burden+log_TMB+WGD+AGE_AT_DX+SEX+cancer_f,data=E,family=binomial)
sa<-summary(adj)$coefficients["gh_burden",]
res_stat<-data.table(
  Model=c("Unadjusted","Adjusted (TMB, WGD, age, sex, cancer)"),
  OR_per_homoz_locus=round(c(exp(su[2,1]),exp(sa[1])),3),
  CI_low=round(c(exp(su[2,1]-1.96*su[2,2]),exp(sa[1]-1.96*sa[2])),3),
  CI_high=round(c(exp(su[2,1]+1.96*su[2,2]),exp(sa[1]+1.96*sa[2])),3),
  P=c(su[2,4],sa[4]))
fwrite(res_stat, file.path(RES,"germline_burden_models.tsv"), sep="\t")
msg("\n=== Trend models ==="); print(res_stat)
msg("Adjusted OR per homozygous locus: %.3f (p=%.2e)", exp(sa[1]), sa[4])

# ── Figure 6 ──────────────────────────────────────────────────────────────────
theme_pub<-function(base=12) theme_classic(base_size=base)+
  theme(axis.title=element_text(face="bold",colour=NAVY),
        plot.title=element_text(face="bold",colour=NAVY,size=base+1),
        plot.subtitle=element_text(colour="grey40",size=base-2),
        legend.position="none")
dose[, lab:=factor(gh_burden,levels=0:2,labels=c("0 loci","1 locus","2 loci"))]
f6a<-ggplot(dose,aes(x=lab,y=LOH_pct))+
  geom_col(fill=NAVY,width=0.62)+
  geom_errorbar(aes(ymin=lo,ymax=hi),width=0.2,colour=GREY)+
  geom_text(aes(label=sprintf("%.1f%%\n(n=%s)",LOH_pct,format(N,big.mark=","))),
            vjust=-0.3,size=3.2,colour="grey20")+
  labs(x="Germline HLA homozygosity burden",y="Somatic HLA LOH (%)",
       title="A  Germline zygosity constrains somatic HLA LOH",
       subtitle="Dose-dependent: OR 0.81 per homozygous locus (adjusted)")+
  ylim(0,32)+theme_pub()

# panel B: evaluability bar (methodological finding)
evm<-melt(ev_tab[,.(Locus,Heterozygous=Heteroz_evaluable_pct,Homozygous=Homoz_evaluable_pct)],
          id.vars="Locus",variable.name="Germline",value.name="pct")
f6b<-ggplot(evm,aes(x=Locus,y=pct,fill=Germline))+
  geom_col(position="dodge",width=0.68)+
  scale_fill_manual(values=c("Heterozygous"=TEAL,"Homozygous"=GOLD))+
  labs(x=NULL,y="Locus evaluable for LOH (%)",
       title="B  Homozygous loci are non-evaluable",
       subtitle="LOH requires heterozygosity: homozygous loci yield no call")+
  theme_classic(base_size=12)+
  theme(axis.title=element_text(face="bold",colour=NAVY),
        plot.title=element_text(face="bold",colour=NAVY,size=13),
        plot.subtitle=element_text(colour="grey40",size=10),
        legend.position="top",legend.title=element_text(face="bold",colour=NAVY))

suppressMessages(library(patchwork))
F6<-f6a+f6b+plot_layout(widths=c(1,1))
ggsave(file.path(PNG,"Figure6_germline_zygosity.png"),F6,width=12,height=5.5,dpi=300,bg="white")
ggsave(file.path(TIF,"Figure6_germline_zygosity.tiff"),F6,width=12,height=5.5,dpi=300,bg="white",compression="lzw",device="tiff")
msg("\nSaved Figure6 (PNG+TIFF)")
msg("=== GERMLINE ZYGOSITY ANALYSIS COMPLETE ===")
