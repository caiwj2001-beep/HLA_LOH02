#!/usr/bin/env python3
"""HLA_LOH02 - Build submission DOCX tables (main + supplementary), editable format."""
import csv, os
from docx import Document
from docx.shared import Pt, RGBColor, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

TAB = "C:/Users/Administrator/科研文件/HLA_LOH02/V6/04_processed_data/table_data"
OUT = "C:/Users/Administrator/科研文件/HLA_LOH02/V6/05_tables"
os.makedirs(OUT, exist_ok=True)
NAVY = RGBColor(0x00, 0x33, 0x66)

def load(f):
    with open(os.path.join(TAB, f), encoding="utf-8") as fh:
        return list(csv.reader(fh, delimiter="\t"))

def shade(cell, hexc):
    tcPr = cell._tc.get_or_add_tcPr()
    sh = OxmlElement("w:shd"); sh.set(qn("w:val"),"clear")
    sh.set(qn("w:color"),"auto"); sh.set(qn("w:fill"),hexc)
    tcPr.append(sh)

def set_cell(cell, text, bold=False, white=False, size=9, align="left"):
    cell.text = ""
    p = cell.paragraphs[0]
    p.alignment = {"left":WD_ALIGN_PARAGRAPH.LEFT,"center":WD_ALIGN_PARAGRAPH.CENTER,
                   "right":WD_ALIGN_PARAGRAPH.RIGHT}[align]
    r = p.add_run(str(text).strip().strip('"'))
    r.font.size = Pt(size); r.font.name = "Arial"; r.bold = bold
    if white: r.font.color.rgb = RGBColor(0xFF,0xFF,0xFF)
    elif bold: r.font.color.rgb = NAVY

def make_table(doc, rows, title, caption, colwidths=None, fontsize=9):
    h = doc.add_paragraph(); rr = h.add_run(title)
    rr.bold=True; rr.font.color.rgb=NAVY; rr.font.size=Pt(11); rr.font.name="Arial"
    if caption:
        cp = doc.add_paragraph(); cr = cp.add_run(caption)
        cr.italic=True; cr.font.size=Pt(8.5); cr.font.name="Arial"
    hdr, body = rows[0], rows[1:]
    t = doc.add_table(rows=1, cols=len(hdr)); t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.style = "Table Grid"
    for j,c in enumerate(hdr):
        set_cell(t.rows[0].cells[j], c, bold=True, white=True, size=fontsize, align="center")
        shade(t.rows[0].cells[j], "003366")
    for i,row in enumerate(body):
        cells = t.add_row().cells
        for j,c in enumerate(row):
            set_cell(cells[j], c, size=fontsize, align="left" if j==0 else "center")
        if i%2==1:
            for c in cells: shade(c, "EAF0F6")
    if colwidths:
        for j,w in enumerate(colwidths):
            for row in t.rows: row.cells[j].width = Inches(w)
    doc.add_paragraph()
    return t

# ══ MAIN TABLES ═══════════════════════════════════════════════════════════════
doc = Document()
style = doc.styles["Normal"]; style.font.name="Arial"; style.font.size=Pt(10)
ti = doc.add_paragraph(); tr = ti.add_run("HLA_LOH02 — Main Tables")
tr.bold=True; tr.font.size=Pt(14); tr.font.color.rgb=NAVY

make_table(doc, load("Table1_baseline.tsv"),
  "Table 1. Baseline characteristics by HLA loss-of-heterozygosity status.",
  "Primary analysis cohort (n=29,799 HLA-LOH-evaluable, FACETS-QC-pass, one tumor per patient) "
  "from the MSK-IMPACT 50K cohort. P values: Wilcoxon rank-sum (continuous) or chi-square/Fisher "
  "(categorical). IQR, interquartile range; TMB, tumor mutational burden.",
  colwidths=[2.6,1.9,1.9,0.9])

# Table 2 combined: drivers + survival
q3 = load("Table2_drivers.tsv")
# reformat q3 to OR (95% CI) p
hdr2 = ["Predictor","Model","OR (95% CI)","P value"]
body2 = []
lbl = {"WGDTRUE":"Whole-genome doubling","germ_hom_anyTRUE":"Germline HLA homozygosity",
       "log_TMB":"log10 TMB","arm_6p_loss":"6p arm loss"}
for r in q3[1:]:
    model, term, OR, lo, hi, p = r
    OR,lo,hi,p = float(OR),float(lo),float(hi),float(p)
    pv = "<0.001" if p<0.001 else f"{p:.3f}"
    body2.append([lbl.get(term,term), model, f"{OR:.2f} ({lo:.2f}–{hi:.2f})", pv])
make_table(doc, [hdr2]+body2,
  "Table 2. Multivariable genomic drivers of HLA LOH.",
  "Logistic regression. Distal model adjusts for cancer type, gene panel, and tumor purity "
  "(excluding 6p, which physically contains the HLA locus); the proximal 6p effect is adjusted "
  "for cancer type. OR, odds ratio; CI, confidence interval.",
  colwidths=[2.4,1.3,2.2,1.1])

# survival table
sv = load("Table2_survival.tsv")
hdr3=["Variable","HR (95% CI)","P value"]; body3=[]
svlbl={"any_HLA_LOHTRUE":"HLA LOH","AGE_AT_DX":"Age (per year)","SEXMale":"Male sex",
       "log_TMB":"log10 TMB","WGDTRUE":"Whole-genome doubling"}
for r in sv[1:]:
    term,HR,lo,hi,p = r[0],float(r[1]),float(r[2]),float(r[3]),float(r[4])
    if term.startswith("cancer_f"): continue
    pv="<0.001" if p<0.001 else f"{p:.3f}"
    body3.append([svlbl.get(term,term), f"{HR:.2f} ({lo:.2f}–{hi:.2f})", pv])
make_table(doc, [hdr3]+body3,
  "Table 3. Multivariable Cox model for overall survival (pan-cancer).",
  "Cox proportional-hazards model (n=27,378; 10,101 deaths) adjusted for age, sex, TMB, "
  "whole-genome doubling, and cancer type (cancer-type coefficients omitted). HR, hazard ratio.",
  colwidths=[2.6,2.4,1.2])

doc.save(os.path.join(OUT,"Main_Tables.docx"))
print("Saved Main_Tables.docx")

# ══ SUPPLEMENTARY TABLES ══════════════════════════════════════════════════════
sdoc = Document()
st = sdoc.styles["Normal"]; st.font.name="Arial"; st.font.size=Pt(9)
si = sdoc.add_paragraph(); sr = si.add_run("HLA_LOH02 — Supplementary Tables")
sr.bold=True; sr.font.size=Pt(14); sr.font.color.rgb=NAVY

# Supp Table 1: full atlas
atlas = load("SuppTable1_atlas.tsv")
h = atlas[0]
keep_idx = [h.index(c) for c in ["CANCER_TYPE","N","n_LOH","freq","lo","hi","freq_pan","med_TMB","pct_WGD"]]
hdr = ["Cancer type","N","LOH n","LOH freq","95% lo","95% hi","pan-HLA","med TMB","%WGD"]
rows=[hdr]
for r in atlas[1:]:
    vals=[r[i] for i in keep_idx]
    for k in (3,4,5,6,8):
        try: vals[k]=f"{100*float(vals[k]):.1f}"
        except: pass
    try: vals[7]=f"{float(vals[7]):.1f}"
    except: pass
    rows.append(vals)
make_table(sdoc, rows,
  "Supplementary Table 1. Pan-cancer HLA LOH atlas (all cancer types, n>=100).",
  "Frequencies in %. Wilson 95% CI. pan-HLA, all three loci lost; med TMB in mut/Mb.",
  fontsize=8)

# Supp Table 2: TMB by cancer
tmb=load("SuppTable2_TMB.tsv"); h=tmb[0]
ki=[h.index(c) for c in ["CANCER_TYPE","N","med_TMB_LOH","med_TMB_noLOH","p","FDR"]]
hdr=["Cancer type","N","med TMB (LOH)","med TMB (intact)","P","FDR"]; rows=[hdr]
for r in tmb[1:]:
    v=[r[i] for i in ki]
    for k in (2,3):
        try:v[k]=f"{float(v[k]):.2f}"
        except:pass
    for k in (4,5):
        try:v[k]="<0.001" if float(v[k])<0.001 else f"{float(v[k]):.3f}"
        except:pass
    rows.append(v)
make_table(sdoc, rows,
  "Supplementary Table 2. TMB association with HLA LOH by cancer type.",
  "Wilcoxon rank-sum test; BH-FDR corrected.", fontsize=8)

# Supp Table 3: signatures
sig=load("SuppTable3_signatures.tsv"); h=sig[0]
ki=[h.index(c) for c in ["signature","mean_LOH","mean_noLOH","p","FDR"]]
hdr=["Signature","mean (LOH)","mean (intact)","P","FDR"]; rows=[hdr]
nm={"sig_APOBEC":"APOBEC","sig_HRD":"HRD","sig_MMR":"MMR","sig_smoke":"Smoking","sig_UV":"UV","sig_aging":"Aging"}
for r in sig[1:]:
    v=[r[i] for i in ki]; v[0]=nm.get(v[0],v[0])
    for k in (1,2):
        try:v[k]=f"{float(v[k]):.4f}"
        except:pass
    for k in (3,4):
        try:v[k]="<0.001" if float(v[k])<0.001 else f"{float(v[k]):.3f}"
        except:pass
    rows.append(v)
make_table(sdoc, rows,
  "Supplementary Table 3. Mutational signature contributions by HLA LOH status.",
  "COSMIC v2 signatures; Wilcoxon rank-sum; BH-FDR.", fontsize=8)

# Supp Table 4: survival by cancer
scv=load("SuppTable4_survival_bycancer.tsv"); h=scv[0]
ki=[h.index(c) for c in ["CANCER_TYPE","N","events","HR","lo","hi","p","FDR"]]
hdr=["Cancer type","N","Events","HR","95% lo","95% hi","P","FDR"]; rows=[hdr]
for r in scv[1:]:
    v=[r[i] for i in ki]
    for k in (3,4,5):
        try:v[k]=f"{float(v[k]):.2f}"
        except:pass
    for k in (6,7):
        try:v[k]="<0.001" if float(v[k])<0.001 else f"{float(v[k]):.3f}"
        except:pass
    rows.append(v)
make_table(sdoc, rows,
  "Supplementary Table 4. HLA LOH and overall survival by cancer type.",
  "Cox models adjusted for age, sex, TMB; BH-FDR corrected. HR>1 indicates worse survival with HLA LOH.",
  fontsize=8)

sdoc.save(os.path.join(OUT,"Supplementary_Tables.docx"))
print("Saved Supplementary_Tables.docx")
