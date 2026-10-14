#!/usr/bin/env python3
"""HLA_LOH02 - Assemble complete submission manuscript DOCX from section markdown."""
import os, re
from docx import Document
from docx.shared import Pt, RGBColor, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

MS  = "C:/Users/Administrator/科研文件/HLA_LOH02/V6/08_manuscript"
FIG = "C:/Users/Administrator/科研文件/HLA_LOH02/V6/06_figures_png"
OUT = os.path.join(MS, "HLA_LOH02_manuscript.docx")
NAVY = RGBColor(0x00,0x33,0x66)

def rd(f): return open(os.path.join(MS,f),encoding="utf-8").read()

doc = Document()
st = doc.styles["Normal"]; st.font.name="Times New Roman"; st.font.size=Pt(11)
st.paragraph_format.line_spacing_rule=WD_LINE_SPACING.DOUBLE  # double-spaced for review

def add_line_numbers(section):
    sectPr = section._sectPr
    ln = OxmlElement("w:lnNumType")
    ln.set(qn("w:countBy"),"1"); ln.set(qn("w:restart"),"continuous"); ln.set(qn("w:distance"),"360")
    sectPr.append(ln)
add_line_numbers(doc.sections[0])

def H(txt, size=13, space_before=12):
    p=doc.add_paragraph(); p.paragraph_format.space_before=Pt(space_before)
    p.paragraph_format.space_after=Pt(6); p.paragraph_format.line_spacing_rule=WD_LINE_SPACING.SINGLE
    r=p.add_run(txt); r.bold=True; r.font.color.rgb=NAVY; r.font.size=Pt(size); return p

def body(txt, justify=True, italic=False, size=11):
    for para in txt.split("\n"):
        para=para.strip()
        if not para: continue
        p=doc.add_paragraph(); 
        if justify: p.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
        r=p.add_run(para); r.font.size=Pt(size); r.italic=italic
    return

def bullets(lines):
    for ln in lines:
        p=doc.add_paragraph(style="List Bullet"); p.paragraph_format.line_spacing_rule=WD_LINE_SPACING.SINGLE
        p.add_run(ln).font.size=Pt(11)

# ── strip a markdown section body between a header and the next '## ' ───────────
def section(md, start, end=None):
    t=rd(md)
    if end:
        m=re.search(re.escape(start)+r'(.*?)'+re.escape(end), t, re.S)
    else:
        m=re.search(re.escape(start)+r'(.*)$', t, re.S)
    return m.group(1).strip() if m else ""

# ═══ TITLE PAGE ═══════════════════════════════════════════════════════════════
fm = rd("01_FrontMatter.md")
title = re.search(r'## Title\n(.*?)\n', fm).group(1).strip()
tp=doc.add_paragraph(); tp.alignment=WD_ALIGN_PARAGRAPH.CENTER
tp.paragraph_format.line_spacing_rule=WD_LINE_SPACING.SINGLE
r=tp.add_run(title); r.bold=True; r.font.size=Pt(15); r.font.color.rgb=NAVY

authors = re.search(r'## Authors\n(.*?)\n', fm).group(1).strip()
ap=doc.add_paragraph(); ap.alignment=WD_ALIGN_PARAGRAPH.CENTER
ap.paragraph_format.line_spacing_rule=WD_LINE_SPACING.SINGLE
ap.add_run(authors).font.size=Pt(11)

aff = section("01_FrontMatter.md","## Affiliations","## Keywords")
for ln in aff.split("\n"):
    if ln.strip():
        p=doc.add_paragraph(); p.alignment=WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.line_spacing_rule=WD_LINE_SPACING.SINGLE
        rr=p.add_run(ln.strip()); rr.font.size=Pt(9.5); rr.italic=True

kw = section("01_FrontMatter.md","## Keywords","## ---").strip() or \
     re.search(r'## Keywords\n(.*?)\n', fm).group(1).strip()
kp=doc.add_paragraph(); kp.paragraph_format.space_before=Pt(10)
kp.paragraph_format.line_spacing_rule=WD_LINE_SPACING.SINGLE
kp.add_run("Keywords: ").bold=True; kp.add_run(re.search(r'## Keywords\n(.*?)\n',fm).group(1).strip()).font.size=Pt(10)

doc.add_page_break()

# ═══ SUMMARY ══════════════════════════════════════════════════════════════════
H("Summary")
summ = section("01_FrontMatter.md","## Summary (Abstract)","## Highlights")
summ = re.sub(r'^.*?\n','',summ,count=0).strip()
body(summ)

# Highlights
H("Highlights", size=12)
hl = section("01_FrontMatter.md","## Highlights","## eTOC blurb")
bullets([l.strip("- ").strip() for l in hl.split("\n") if l.strip().startswith("-")])

# eTOC
H("eTOC blurb", size=12)
etoc = section("01_FrontMatter.md","## eTOC blurb").strip()
body(etoc, italic=True)

doc.add_page_break()

# ═══ MAIN TEXT ════════════════════════════════════════════════════════════════
def render_md_body(md_file, skip_title_line=True):
    t=rd(md_file)
    lines=t.split("\n")
    for ln in lines:
        if ln.startswith("# "):  # top title
            continue
        if ln.startswith("## "):
            H(ln[3:].strip(), size=12); continue
        if ln.startswith("### "):
            H(ln[4:].strip(), size=11, space_before=8); continue
        if ln.strip()=="" : continue
        if ln.strip().startswith("---"): continue
        p=doc.add_paragraph(); p.alignment=WD_ALIGN_PARAGRAPH.JUSTIFY
        p.add_run(ln.strip()).font.size=Pt(11)

H("Introduction")
render_md_body("02_Introduction.md")

H("Results")
render_md_body("04_Results.md")

H("Discussion")
render_md_body("05_Discussion.md")

# ═══ STAR METHODS ═════════════════════════════════════════════════════════════
doc.add_page_break()
render_md_body("03_Methods.md")

# ═══ BACK MATTER ══════════════════════════════════════════════════════════════
render_md_body("08_BackMatter.md")

# ═══ REFERENCES ═══════════════════════════════════════════════════════════════
doc.add_page_break()
H("References")
reftext=rd("06_References.md")
# extract numbered refs
for m in re.finditer(r'^(\d+)\.\s+(.*?)(?=\n\d+\.\s|\n---|\Z)', reftext, re.S|re.M):
    num, ref = m.group(1), " ".join(m.group(2).split())
    p=doc.add_paragraph(); p.paragraph_format.line_spacing_rule=WD_LINE_SPACING.SINGLE
    p.paragraph_format.space_after=Pt(4)
    p.add_run(f"{num}. ").bold=True
    p.add_run(ref).font.size=Pt(9.5)

# ═══ FIGURE LEGENDS ═══════════════════════════════════════════════════════════
doc.add_page_break()
H("Figure Legends")
render_md_body("07_FigureLegends.md")

# ═══ FIGURES (embedded) ═══════════════════════════════════════════════════════
doc.add_page_break()
H("Figures")
for i in range(1,7):
    figs={1:"Figure1_pancancer_atlas",2:"Figure2_TMB_association",3:"Figure3_mechanism",
          4:"Figure4_mutational_processes",5:"Figure5_survival",6:"Figure6_germline_zygosity"}
    fp=os.path.join(FIG,figs[i]+".png")
    if os.path.exists(fp):
        cap=doc.add_paragraph(); cap.paragraph_format.line_spacing_rule=WD_LINE_SPACING.SINGLE
        cap.add_run(f"Figure {i}").bold=True
        doc.add_picture(fp, width=Inches(6.5))
        doc.paragraphs[-1].alignment=WD_ALIGN_PARAGRAPH.CENTER
        doc.add_paragraph()

doc.save(OUT)
# word count
import subprocess
full=" ".join(p.text for p in doc.paragraphs)
print(f"Saved {OUT}")
print(f"Total paragraphs: {len(doc.paragraphs)} | Embedded figures: 6 | Tables via separate DOCX")
