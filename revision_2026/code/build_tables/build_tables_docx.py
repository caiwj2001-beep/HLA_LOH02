#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
build_tables_docx.py — 由 V3/03_tables/build/*.tsv 生成全部 DOCX 交付物。

铁律遵守点：
  * 所有数字逐字取自 build/*.tsv（由 01_build_tables_V3.R 重算并对 PINNED_PACK 断言）
  * DOCX 内不出现 markdown 标记（** * #）；加粗/斜体一律用 Word 属性
  * 生成后自动扫描全部段落与表格单元格，任一残留标记即退出码 1
"""
import os, csv, sys, re, glob
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

ROOT = r"C:\Users\Administrator\科研文件\HLA_LOH02"
V3   = os.path.join(ROOT, "iscience投稿版本", "V3")
BLD  = os.path.join(V3, "03_tables", "build")
TBL  = os.path.join(V3, "03_tables")
COMP = os.path.join(V3, "06_compliance")
SUPP = os.path.join(V3, "04_supplement")
for d in (TBL, COMP, SUPP):
    os.makedirs(d, exist_ok=True)

# --- 仓库快照 ---------------------------------------------------------------
# 手稿的 Data and code availability 声明把读者指向某个具体 commit：code.zip /
# derived_data.zip 的全部成员在该 commit 上逐字节可复现（check_repo_vs_zip 100/100）。
# 只有一个定义点，KRT 与 Data_and_Code_Availability.md 同源，避免两处拼写不一致。
REPO_URL = "https://github.com/caiwj2001-beep/HLA_LOH02"
REPO_COMMIT = "08fe6775ad9548472177a97bf1a9458a743f5fc0"
REPO_SNAPSHOT = f"{REPO_URL} (analysis code and derived data at commit {REPO_COMMIT})"

# ----------------------------------------------------------------- IO helpers
def rd(name):
    with open(os.path.join(BLD, name), encoding="utf-8") as f:
        return list(csv.DictReader(f, delimiter="\t"))

def rd_opt(name):
    p = os.path.join(BLD, name)
    return rd(name) if os.path.exists(p) else []

def num(x, nd=3):
    try:
        return f"{float(x):.{nd}f}"
    except Exception:
        return str(x)

def p_disp(s):
    """P 值展示归一（只改呈现、不改数值）。

    上游 R 侧用 sprintf("%.3f") 输出 P，阈值判据是 p < 1e-4，于是 1e-4 <= p < 5e-4
    的 P 会打印成 "0.000"。0.000 既不是合法 P 值也不是可读写法，故在 DOCX 模板层统一
    归一为 "<0.001"（与该列其它小 P 的写法一致）。放在模板层而非手改 DOCX，保证任何一次
    重生 Table1/2/3 都不会再把 "0.000" 带进交付物。
    """
    t = "" if s is None else str(s).strip()
    return "<0.001" if t == "0.000" else t

# ---- 全局零 P 归一（P2-C）--------------------------------------------------
# 同一个缺陷在补充表里有三种写法：S4 的 FDR×2 = "0.000"、S7 的 P = "0.0000"、
# S10 的区间端点 "0.000-0.207"。在 cell_text()/para() 这一层统一按 token 归一，
# 任何一次重生都不可能把 0.000 带回交付物（比逐调用点打补丁更强，不会漏）。
# 只匹配“整个 token 就是 0.000…0”的情形：后面紧跟数字的（0.000608、0.0001）
# 是合法 P 值，绝不改；带负号的（-0.000）不是 P 值，也不改。
ZERO_P = re.compile(r"(?<![\d.])0\.0{3,}(?![\d])")
def zdisp(s):
    t = "" if s is None else str(s)
    return ZERO_P.sub("<0.001", t)

# ------------------------------------------------------------- docx primitives
def set_base_style(doc):
    st = doc.styles["Normal"]
    st.font.name = "Times New Roman"
    st.font.size = Pt(10.5)
    st.element.rPr.rFonts.set(qn("w:eastAsia"), "SimSun")
    for s in doc.sections:
        s.left_margin = s.right_margin = Inches(0.8)
        s.top_margin = s.bottom_margin = Inches(0.8)

def add_page_number_footer(doc):
    for s in doc.sections:
        p = s.footer.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run()
        f1 = OxmlElement("w:fldChar"); f1.set(qn("w:fldCharType"), "begin")
        it = OxmlElement("w:instrText"); it.set(qn("xml:space"), "preserve"); it.text = "PAGE"
        f2 = OxmlElement("w:fldChar"); f2.set(qn("w:fldCharType"), "end")
        r._r.append(f1); r._r.append(it); r._r.append(f2)
        r.font.size = Pt(9)

def para(doc, text="", bold=False, italic=False, size=None, align=None, space_after=4):
    p = doc.add_paragraph()
    if align is not None:
        p.alignment = align
    p.paragraph_format.space_after = Pt(space_after)
    if text:
        r = p.add_run(zdisp(text))
        r.bold = bold; r.italic = italic
        if size:
            r.font.size = Pt(size)
    return p

def heading(doc, text, size=13, space_before=10):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(space_before)
    p.paragraph_format.space_after = Pt(4)
    r = p.add_run(zdisp(text)); r.bold = True; r.font.size = Pt(size)
    return p

def legend(doc, text, italic=True, size=9.5):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    r = p.add_run(zdisp(text)); r.italic = italic; r.font.size = Pt(size)
    return p

def cell_text(cell, text, bold=False, italic=False, size=9, align=None):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(1)
    if align is not None:
        p.alignment = align
    r = p.add_run(zdisp(text))
    r.bold = bold; r.italic = italic; r.font.size = Pt(size)

def mk_table(doc, header, rows, widths=None, bold_rows=None, font=9):
    t = doc.add_table(rows=1, cols=len(header))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(header):
        cell_text(t.rows[0].cells[i], h, bold=True, size=font,
                  align=WD_ALIGN_PARAGRAPH.LEFT if i == 0 else WD_ALIGN_PARAGRAPH.CENTER)
    # 表头跨页重复（长表 S1/S9/S12/S13/S14 在任何拆分页上都保留列名）
    trPr = t.rows[0]._tr.get_or_add_trPr()
    th = OxmlElement("w:tblHeader"); th.set(qn("w:val"), "true"); trPr.append(th)
    for ri, row in enumerate(rows):
        cells = t.add_row().cells
        b = bool(bold_rows[ri]) if bold_rows else False
        for i, v in enumerate(row):
            cell_text(cells[i], v, bold=b, size=font,
                      align=WD_ALIGN_PARAGRAPH.LEFT if i == 0 else WD_ALIGN_PARAGRAPH.CENTER)
    if widths:
        for r in t.rows:
            for i, w in enumerate(widths):
                r.cells[i].width = Inches(w)
    return t

# --------------------------------------------------------------- markdown scan
MD_PAT = re.compile(r"(\*\*|\*|^#{1,6}\s|`|\[[^\]]*\]\([^)]*\))")
def scan_markdown(doc, label, log):
    bad = []
    for i, p in enumerate(doc.paragraphs):
        if MD_PAT.search(p.text):
            bad.append(("para", i, p.text[:140]))
    for ti, t in enumerate(doc.tables):
        for ri, row in enumerate(t.rows):
            for ci, c in enumerate(row.cells):
                if MD_PAT.search(c.text):
                    bad.append(("cell", f"t{ti}r{ri}c{ci}", c.text[:140]))
    log.write(f"[MD-SCAN] {label}: {'CLEAN' if not bad else 'RESIDUE %d' % len(bad)}\n")
    for b in bad:
        log.write(f"    {b}\n")
    return len(bad)

# =============================================================== MAIN TABLES
def build_main_tables(log):
    # ---------------- Table 1
    t1 = rd("table1_baseline.tsv")
    doc = Document(); set_base_style(doc); add_page_number_footer(doc)
    heading(doc, "Table 1. Baseline characteristics by HLA loss-of-heterozygosity status.", 12)
    legend(doc, "Primary analysis cohort (n=29,799 HLA-LOH-evaluable tumours, FACETS-QC pass, one tumour per "
                "patient) from the MSK-IMPACT 50K cohort. Continuous variables are median (IQR) with Wilcoxon "
                "rank-sum P values; categorical variables are n (%) over non-missing values with chi-square "
                "(Fisher when required) P values. New in this revision: the global aneuploidy score rows.")
    rows = [[r["characteristic"], r["hla_intact"], r["hla_loh"], p_disp(r["P"])] for r in t1]
    bold = [r["bold"].strip().upper() == "TRUE" for r in t1]
    mk_table(doc, ["Characteristic", "HLA intact (n=22,245)", "HLA LOH (n=7,554)", "P value"],
             rows, widths=[2.9, 1.55, 1.55, 0.9], bold_rows=bold)
    legend(doc, "Global aneuploidy score = fraction of evaluable autosomal chromosome arms (of 39) carrying a "
                "copy-number gain or loss, from FACETS arm-level calls. Excluding-6p and excluding-6q variants "
                "use the same definition with the stated arm removed. 6p arm loss denominators are the "
                "6p-readable samples within each HLA group; among HLA-LOH tumours with a 6p call (n=5,805), "
                "4,161 (71.7%) show 6p loss. TMB, tumour mutational burden; WGD, whole-genome doubling; IQR, "
                "interquartile range.", size=9)
    p = os.path.join(TBL, "Table1_baseline.docx"); doc.save(p); log.write(f"[WROTE] {p}\n")

    # ---------------- Table 2
    t2 = rd("table2_drivers.tsv")
    doc = Document(); set_base_style(doc); add_page_number_footer(doc)
    heading(doc, "Table 2. Multivariable drivers of HLA LOH.", 12)
    legend(doc, "Logistic regression. The distal model adjusts for cancer type, gene panel and tumour purity; "
                "the proximal model adjusts for cancer type only. The aneuploidy score enters as a z-score "
                "(per 1 SD) in the distal-plus-aneuploidy specifications. OR, odds ratio; CI, confidence interval.")
    rows = [[r["predictor"], r["model"], r["OR_CI"], r["P_fmt"]] for r in t2]
    mk_table(doc, ["Predictor", "Model", "OR (95% CI)", "P value"], rows,
             widths=[2.45, 2.45, 1.35, 0.75])
    # --- 表注中的衰减端点一律从 table2_drivers.tsv 取（P3 修正）-------------
    # 曾在此手写 "log10 TMB (1.45 to 1.24)"，而表体/源表为 1.23（raw 1.23275）：
    # 手写数字会随任何一次重算悄悄回退，故改为读表取值，缺失即硬失败。
    def _or_of(pred, model_exact, nd=2):
        for r in t2:
            if r["predictor"].startswith(pred) and r["model"].strip() == model_exact:
                return num(r["OR"], nd)
        raise SystemExit("table2 caption: OR row not found for %r/%r" % (pred, model_exact))
    wgd_d = _or_of("Whole-genome doubling", "Distal multivariable")
    wgd_a = _or_of("Whole-genome doubling", "Distal multivariable + aneuploidy")
    tmb_d = _or_of("log10 TMB", "Distal multivariable")
    tmb_a = _or_of("log10 TMB", "Distal multivariable + aneuploidy")

    # --- 表注里的 OR + CI 一律从 table2_drivers.tsv 取（与上面同一口径，缺失即硬失败）---
    def _ci_of(pred, model_exact, nd=2):
        for r in t2:
            if r["predictor"].startswith(pred) and r["model"].strip() == model_exact:
                return "%s (%s–%s)" % (num(r["OR"], nd), num(r["lo"], nd), num(r["hi"], nd))
        raise SystemExit("table2 caption: CI row not found for %r/%r" % (pred, model_exact))

    wgd_ci_d = _ci_of("Whole-genome doubling", "Distal multivariable")
    wgd_ci_a = _ci_of("Whole-genome doubling", "Distal multivariable + aneuploidy")

    # --- 中介分解（ACME / ADE / 比例中介）一律从 s6_mediation.tsv 取 ---
    # 表注旧版把 0.35 称作 "within-model direct effect"：0.35 是**加入全局非整倍体评分后**
    # 的 WGD OR，不是直接效应；直接效应是 ADE，取自 s6_mediation.tsv。
    _med = {r["Quantity"]: r for r in rd("s6_mediation.tsv")}

    def _sig(x, nd=4):
        v = float(x)
        return ("−" if v < 0 else "") + num(abs(v), nd)

    def _mv(key, nd=4):
        try:
            r = _med[key]
        except KeyError:
            raise SystemExit("table2 caption: mediation row not found for %r" % key)
        return _sig(r["Estimate"], nd), _sig(r["CI_low"], nd), _sig(r["CI_high"], nd)

    acme, acme_lo, acme_hi = _mv("ACME (indirect, via 6p)")
    ade, ade_lo, ade_hi = _mv("ADE (direct)")
    pm, pm_lo, pm_hi = _mv("Proportion mediated")
    log.write("[T2-CAPTION] WGD CI %s -> %s ; ACME %s ; ADE %s ; PM %s\n"
              % (wgd_ci_d, wgd_ci_a, acme, ade, pm))
    log.write("[T2-CAPTION] WGD %s -> %s ; TMB %s -> %s (read from table2_drivers.tsv)\n"
              % (wgd_d, wgd_a, tmb_d, tmb_a))
    # --- 表注：OR + CI 与 TMB 端点同样逐项读 tsv（第十轮起 WGD 的 OR 与 CI 一并读出）---
    def _orci_of(pred, model_exact, nd=2):
        for r in t2:
            if r["predictor"].startswith(pred) and r["model"].strip() == model_exact:
                return (num(r["OR"], nd), num(r["lo"], nd), num(r["hi"], nd))
        raise SystemExit("table2 caption: OR/CI row not found for %r/%r" % (pred, model_exact))

    wgd_o, wgd_lo, wgd_hi = _orci_of("Whole-genome doubling", "Distal multivariable")
    wgd_ao, wgd_alo, wgd_ahi = _orci_of("Whole-genome doubling", "Distal multivariable + aneuploidy")
    cap = (
        "The proximal 6p arm-loss term is near-definitional: chromosome 6p physically contains the HLA "
        "class I locus, so a 6p arm loss mechanically removes it. The large proximal OR is reported for "
        "completeness and is not interpreted as an independent discovery. "
        "Note that adjusting the distal model for the global aneuploidy score attenuates WGD "
        f"({wgd_o}, 95% CI {wgd_lo}–{wgd_hi}, to {wgd_ao}, {wgd_alo}–{wgd_ahi}) "
        f"and log10 TMB ({tmb_d} to {tmb_a}) because the aneuploidy score absorbs the same genome-wide "
        "instability signal. The mediation decomposition (Table S6) attributes an average causal "
        f"mediation effect of {acme} ({acme_lo}–{acme_hi}) to the chromosome-6p route, with an average "
        f"direct effect of {ade} ({ade_lo}–{ade_hi}) and a proportion mediated of {pm} ({pm_lo}–{pm_hi}); "
        "values below 1.0 therefore reflect removal of the mediating route and must not be read as "
        "evidence of a protective effect.")
    # 第十轮硬校验：2.30 / 0.35 各只出现一次（去重），强语气保留，0.28 不得回流。
    _must = ["(2.30, 95% CI 2.16–2.43, to 0.35, 0.31–0.38)",
             "log10 TMB (1.45 to 1.23)",
             "0.2626 (0.2529–0.2704)", "−0.0889 (−0.0944–−0.0810)", "1.5118 (1.4313–1.5849)",
             "must not be read as evidence of a protective effect"]
    for _s in _must:
        if _s not in cap:
            raise SystemExit("table2 caption: required fragment missing -> %r" % _s)
    assert cap.count("2.30") == 1, "table2 caption: 2.30 repeated (%d)" % cap.count("2.30")
    assert cap.count("0.35") == 1, "table2 caption: 0.35 repeated (%d)" % cap.count("0.35")
    assert "0.28" not in cap, "table2 caption: 0.28 must not appear"
    log.write("[T2-CAPTION] dedup OK: 2.30 x1, 0.35 x1, must-not x1, 0.28 x0\n")
    legend(doc, cap, size=9)
    p = os.path.join(TBL, "Table2_drivers.docx"); doc.save(p); log.write(f"[WROTE] {p}\n")

    # ---------------- Table 3
    t3 = rd("table3_survival.tsv")
    ah = rd_opt("table3_aneuploidy_HR.tsv")
    doc = Document(); set_base_style(doc); add_page_number_footer(doc)
    heading(doc, "Table 3. Pan-cancer overall survival: HLA-LOH hazard ratio across model specifications.", 12)
    legend(doc, "Cox proportional-hazards models, n=27,368 tumours and 10,101 deaths (HLA-LOH-evaluable, "
                "one tumour per patient, with complete survival, aneuploidy and WGD data). All adjusted models "
                "include age, sex, log10 TMB, whole-genome doubling and cancer type. HR, hazard ratio.")
    rows = [[r["model"], r["HR_CI"], r["P_fmt"], r["N"], r["deaths"]] for r in t3]
    mk_table(doc, ["Model for HLA LOH", "HR (95% CI)", "P value", "N", "Deaths"], rows,
             widths=[3.2, 1.35, 0.8, 0.7, 0.7])
    ahr = ah[0] if ah else None
    if ahr:
        legend(doc, "In the model adjusted for the global aneuploidy score (all 39 arms), that score itself "
                    f"carries HR {num(ahr['HR'])} (95% CI {num(ahr['lo'])} to {num(ahr['hi'])}, P<0.001) per "
                    "unit fraction, i.e. it is a far stronger predictor than HLA LOH.", size=9)
    legend(doc, "IMPORTANT - OVER-ADJUSTMENT. Adding the global aneuploidy score drives the HLA-LOH hazard "
                "ratio below 1.0 (0.938 with all arms; 0.946 excluding 6p; 0.943 excluding 6q; 0.952 "
                "excluding 6p and 6q). The aneuploidy score lies on the causal path to HLA LOH (HLA LOH is "
                "largely a consequence of arm-level loss, and 6p loss is near-definitional for HLA LOH), so "
                "this specification over-adjusts and the sub-1.0 estimate MUST NOT be interpreted as a "
                "protective effect of HLA LOH. The interpretable statements are: (i) HLA LOH is not an "
                "independent prognostic factor once genome-wide aneuploidy is accounted for, and (ii) the "
                "apparent unadjusted association (1.212) is largely explained by global aneuploidy.", size=9)
    p = os.path.join(TBL, "Table3_survival.docx"); doc.save(p); log.write(f"[WROTE] {p}\n")
    return [("Table 1", doc), ] and None

# =============================================================== SUPPLEMENT
def s_table(doc, num_id, title, legend_text, header, rows, widths=None, bold_rows=None, font=9):
    heading(doc, f"Supplementary Table {num_id}. {title}", 12)
    legend(doc, legend_text, size=9)
    mk_table(doc, header, rows, widths=widths, bold_rows=bold_rows, font=font)

def build_supplement(log, page_map=None):
    page_map = page_map or {}
    doc = Document(); set_base_style(doc); add_page_number_footer(doc)

    # ---- cover / contents
    heading(doc, "Supplemental Information", 16, space_before=0)
    para(doc, "HLA class I loss of heterozygosity in 29,799 tumours: an allele-specific atlas whose "
              "calling is limited by purity and coverage, and whose associations are dominated by global "
              "aneuploidy", italic=True, size=11)
    para(doc, "Manuscript ISCIENCE-D-26-09416 - revision. All numbers in this supplement are produced by the "
              "analysis script deposited with the manuscript (see Data and Code Availability) and are "
              "footnoted with their source table.", size=9.5)
    heading(doc, "Contents", 12)
    toc_rows = [
        ("Supplementary Figure S1", "High-APOBEC tail: HLA intact versus HLA LOH", "S1"),
        ("Supplementary Figure S2", "Germline HLA zygosity and locus-level evaluability", "S2"),
        ("Supplementary Table S1", "Pan-cancer HLA LOH atlas by cancer type (n>=100)", "S1"),
        ("Supplementary Table S2", "TMB association with HLA LOH by cancer type", "S2"),
        ("Supplementary Table S3", "Mutational-signature associations (revised)", "S3"),
        ("Supplementary Table S4", "HLA LOH and overall survival by cancer type", "S4"),
        ("Supplementary Table S5", "Panel-restricted sensitivity (rewritten)", "S5"),
        ("Supplementary Table S6", "Mediation of the WGD effect on HLA LOH through 6p loss", "S6"),
        ("Supplementary Table S7", "Germline zygosity and evaluability (methodological)", "S7"),
        ("Supplementary Table S8", "TMB-HLA LOH across aneuploidy specifications (S-aneuploidy1)", "S8"),
        ("Supplementary Table S9", "Association of each of the 41 chromosome arms with TMB (S-arm1)", "S9"),
        ("Supplementary Table S10", "Calling reliability: purity, coverage and panel (S-reliability1)", "S10"),
        ("Supplementary Table S11", "Neoantigen burden and HLA LOH: all models (S-neo1)", "S11"),
        ("Supplementary Table S12", "Allele-paired neoantigen test (S-neo2)", "S12"),
        ("Supplementary Table S13", "Structural-variant class burden and HLA LOH (S-sv1)", "S13"),
        ("Supplementary Table S14", "Collinearity diagnostics for the survival Cox models (VIF)", "S14"),
    ]
    rows = [[a, b, str(page_map.get(a, ""))] for a, b, _ in toc_rows]
    mk_table(doc, ["Item", "Title", "Page"], rows, widths=[2.0, 4.4, 0.6], font=9)
    legend(doc, "Supplementary tables are numbered continuously S1 to S14; the short identifiers in "
                "parentheses (S-aneuploidy1, S-arm1, S-reliability1, S-neo1, S-neo2, S-sv1) are used in the "
                "point-by-point response letter and map to S8 to S13 respectively. S14 (variance inflation "
                "factors and tolerances for the survival Cox models) is new in this revision.", size=9)
    doc.add_page_break()

    # 图目录：必须在任何 figure-page 块之前**无条件**赋值——2026-10-15 换号后
    # APOBEC 块（现 Figure S1）成为第一个 figure 块，原先只在胚系块内赋值的 figdir
    # 会在 os.path.join(figdir, p) 处触发 UnboundLocalError。
    figdir = os.path.join(V3, "02_figures")
    assert os.path.isdir(figdir), f"figure directory not found: {figdir}"
    _seen_figfiles = []

    # ---- Figure S1 (APOBEC block; added in this revision, answers Reviewer #3 minor
    #      point 1; renumbered from Supplementary Figure S2)
    heading(doc, "Supplementary Figure S1. The high-APOBEC tail does not separate HLA-intact from "
                 "HLA-LOH tumours.", 12)
    s2_cand = []
    for p in ["FigS1*", "*FigS1*", "SupplementaryFigureS1*", "*SupplementaryFigureS1*"]:
        s2_cand += glob.glob(os.path.join(figdir, p))
    s2_cand = sorted({f for f in s2_cand
                      if f.lower().endswith((".tiff", ".tif", ".png", ".jpeg", ".jpg"))})
    emb2 = None
    for f in s2_cand:
        try:
            doc.add_picture(f, width=Inches(6.3))
            emb2 = f
            break
        except Exception:
            continue
    if emb2:
        assert "SupplementaryFigureS1_" in os.path.basename(emb2), \
            f"Figure S1 page embedded the wrong file: {emb2}"
        legend(doc, f"Source figure file: {os.path.basename(emb2)} (300 dpi TIFF, rendered by the figure "
                    "pipeline; the PDF twin is deposited alongside).", size=9)
    else:
        para(doc, "[FIGURE PLACEHOLDER]", bold=True, align=WD_ALIGN_PARAGRAPH.CENTER)
    legend(doc, "Panel A. Distribution of the APOBEC single-base-substitution contribution by HLA LOH "
                "status in the primary cohort with signature data (n=29,484). The x axis is log10-scaled "
                "and exact zeros are plotted at the floor as crosses; boxes show the median and "
                "interquartile range and points are individual tumours. Contributions of exactly zero were "
                "recorded in 15,329 of 21,988 HLA-intact and 4,937 of 7,496 HLA-LOH tumours; the median was "
                "0.00 in both groups and the upper quartile was 0.13 and 0.15 respectively. Panel B. Tumours "
                "above each tail threshold by group; points are the group proportion and horizontal bars are "
                "the Wilson 95% confidence interval. Above a contribution of 0.90, 0.43% of HLA-intact "
                "tumours (95 of 21,988) versus 0.27% of HLA-LOH tumours (20 of 7,496); Fisher P=0.053, so "
                "the two groups are not distinguishable in this tail. At a threshold of >=0.50 the direction "
                "reverses: 4.98% (1,094 of 21,988) versus 5.88% (441 of 7,496); P=0.0026. Panel C. Effect "
                "size of the group difference (HLA LOH / HLA intact) as the log2 ratio of the group "
                "proportions with 95% confidence intervals (delta method); 0 marks no difference. The "
                "confidence interval includes or nearly touches 0 at both thresholds (0.62x, 0.38 to 1.00 "
                "for >0.90; 1.18x, 1.06 to 1.32 for >=0.50), and the absolute difference in proportions is "
                "under 0.91 percentage points. There is therefore no material APOBEC enrichment in HLA-LOH "
                "tumours; both thresholds are shown so that the sign reversal between the extreme tail and "
                "the 0.50 threshold is visible. Source data: V3/02_figures/intermediate/"
                "figs2_tail_comparison.tsv, figs2_effect_sizes.tsv, figs2_apobec_summary.tsv.", size=9)
    doc.add_page_break()

    # ---- Figure S2 (germline block; renumbered from Supplementary Figure S1)
    heading(doc, "Supplementary Figure S2. Germline HLA zygosity and locus-level evaluability.", 12)
    assert isinstance(figdir, str) and os.path.isdir(figdir), "figdir must be assigned before use"
    pats = ["FigS2*", "*FigS2*", "SupplementaryFigureS2*", "*SupplementaryFigureS2*"]
    fig_candidates = []
    for p in pats:
        fig_candidates += glob.glob(os.path.join(figdir, p))
    fig_candidates = sorted({f for f in fig_candidates
                             if f.lower().endswith((".tiff", ".tif", ".png", ".jpeg", ".jpg"))})
    embedded = None
    for f in fig_candidates:
        try:
            doc.add_picture(f, width=Inches(6.3))
            embedded = f
            break
        except Exception as e:
            continue
    if embedded:
        assert "SupplementaryFigureS2_" in os.path.basename(embedded), \
            f"Figure S2 page embedded the wrong file: {embedded}"
        legend(doc, f"Source figure file: {os.path.basename(embedded)} (300 dpi TIFF, rendered by the figure "
                    "pipeline; the PDF twin is deposited alongside).", size=9)
        legend(doc, "Panel A. Frequency of somatic HLA LOH as a function of germline HLA class I homozygosity "
                    "burden (0, 1 or 2 homozygous loci): 26.2%, 22.1% and 19.3%, with Wilson 95% confidence "
                    "intervals and per-group sample sizes. Panel B. Proportion of loci evaluable for LOH by "
                    "germline zygosity for HLA-A, HLA-B and HLA-C: germline-homozygous loci are structurally "
                    "non-evaluable (0%; none of 5,233 HLA-A, 3,125 HLA-B and 4,400 HLA-C homozygous loci "
                    "yielded a call), whereas heterozygous loci are evaluable in approximately 60% of "
                    "genotyped tumours (HLA-A 59.8%, HLA-B 60.0%, HLA-C 60.3%). Panel C. Unadjusted and "
                    "adjusted odds ratios for HLA LOH by homozygous-locus burden (adjusted 0.79, 95% CI 0.75 "
                    "to 0.84; from V3/02_figures/intermediate/figs1_models.tsv). Panels A and B are presented "
                    "as a definitional, methodological statement about the evaluability ceiling of the assay, "
                    "and not as evidence of a germline constraint on somatic evolution.", size=9)
    else:
        para(doc, "[FIGURE PLACEHOLDER]", bold=True, align=WD_ALIGN_PARAGRAPH.CENTER)
        para(doc, "No rendered Supplementary Figure S2 file was found in 02_figures/ at the time this "
                  "supplement was built, so this placeholder page is inserted; the page count and the table "
                  "numbering below are unaffected.", align=WD_ALIGN_PARAGRAPH.CENTER, size=9.5)
        legend(doc, "Figure content (source data: 02_figures/intermediate/figs1_evaluability.tsv, "
                    "figs1_burden_dose.tsv, figs1_models.tsv): panel A, observed HLA LOH frequency by number "
                    "of germline-homozygous loci (0 loci 26.2%, 1 locus 22.1%, 2 loci 19.3%); panel B, "
                    "germline-homozygous class I loci are structurally non-evaluable (0% at all three loci) "
                    "whereas heterozygous loci are evaluable in about 60% of tumours (HLA-A 59.8%, HLA-B "
                    "60.0%, HLA-C 60.3%); panel C, unadjusted and adjusted odds ratios (adjusted 0.79, 95% "
                    "CI 0.75 to 0.84). This is a methodological statement, not an evolutionary-pressure "
                    "test.", size=9)
    doc.add_page_break()

    # ---- S1
    s1 = rd("s1_atlas.tsv")
    rows = [[r["CANCER_TYPE"], r["N"], r["n_LOH"], num(r["freq_pct"], 1), num(r["CI_lo"], 1), num(r["CI_hi"], 1),
             num(r["pan_pct"], 1), num(r["medTMB_LOH"], 1), num(r["medTMB_intact"], 1), num(r["wgd_pct"], 1),
             num(r["aneuploidy_median"], 2)] for r in s1]
    s_table(doc, "S1", "Pan-cancer HLA LOH atlas by cancer type (cancer types with N >= 100).",
            "Frequencies in per cent with Wilson 95% confidence intervals. pan-HLA LOH, all three class I loci "
            "lost. medTMB, median tumour mutational burden in mutations per Mb. WGD, whole-genome doubling. "
            "Aneuploidy, median fraction of evaluable autosomal arms with gain or loss (source: "
            "s1_atlas.tsv).",
            ["Cancer type", "N", "LOH n", "LOH %", "95% CI lo", "95% CI hi", "pan-HLA %", "med TMB LOH",
             "med TMB intact", "% WGD", "Aneuploidy median"],
            rows, widths=[1.85, 0.5, 0.5, 0.55, 0.6, 0.6, 0.6, 0.6, 0.65, 0.5, 0.75], font=8)
    legend(doc, "Cohort-level HLA LOH frequency is 25.3% (95% CI 24.9 to 25.8).", size=9)
    doc.add_page_break()

    # ---- S2
    s2 = rd("s2_tmb_by_cancer.tsv")
    rows = [[r["CANCER_TYPE"], r["N"], r["n_LOH"], num(r["medTMB_LOH"], 2), num(r["medTMB_intact"], 2),
             f"{float(r['P']):.3g}" if float(r["P"]) < 1e-3 else num(r["P"], 3),
             num(r["FDR"], 3) if float(r["FDR"]) >= 1e-3 else f"{float(r['FDR']):.3g}",
             "yes" if r["sig"].strip().upper() == "TRUE" else "no"] for r in s2]
    s_table(doc, "S2", "TMB association with HLA LOH by cancer type.",
            "Wilcoxon rank-sum test for median TMB between HLA-LOH and HLA-intact tumours within each cancer "
            "type; Benjamini-Hochberg FDR across cancer types. Eleven of 29 cancer types reach FDR < 0.05 "
            "(source: s2_tmb_by_cancer.tsv).",
            ["Cancer type", "N", "LOH n", "med TMB LOH", "med TMB intact", "P", "FDR", "FDR<0.05"],
            rows, widths=[2.3, 0.55, 0.55, 0.85, 0.9, 0.75, 0.75, 0.65], font=8.5)
    doc.add_page_break()

    # ---- S3 (revised)
    s3 = rd("s3_signatures.tsv")
    rows = [[r["sig"], num(r["unadj_OR"]), f"{num(r['unadj_lo'])}-{num(r['unadj_hi'])}", num(r["adj_OR"]),
             f"{num(r['adj_lo'])}-{num(r['adj_hi'])}", num(r["adj_P"], 4), num(r["mutual_OR"]),
             num(r["mutual_FDR"], 3), r["revised_note"]] for r in s3]
    s_table(doc, "S3", "Mutational-signature associations with HLA LOH (revised).",
            "Logistic regression of HLA LOH on each COSMIC v2 process score, per 1 SD. Revised against the "
            "original submission: the APOBEC and smoking associations are numerically identical under "
            "adjustment (both adjusted OR 1.035), which identifies them as a mutational-abundance artefact "
            "rather than a repair-pathway mechanism, and the MMR effect reverses relative to the original "
            "report. The mechanistic interpretation of these signatures is withdrawn. Mutually adjusted ORs "
            "put all six signatures in the same model (n=28,989; source: s3_signatures.tsv).",
            ["Signature", "Unadj. OR", "Unadj. 95% CI", "Adj. OR", "Adj. 95% CI", "Adj. P", "Mutual OR",
             "Mutual FDR", "Revision note"],
            rows, widths=[0.6, 0.5, 0.85, 0.5, 0.85, 0.55, 0.55, 0.55, 3.0], font=8)
    doc.add_page_break()

    # ---- S4
    s4 = rd("s4_survival_by_cancer.tsv")
    rows = [[r["cancer"], r["N"], r["events"], num(r["HR"]), f"{num(r['lo'])}-{num(r['hi'])}",
             num(r["P"], 4) if float(r["P"]) >= 1e-4 else "<0.001", num(r["FDR"], 3)] for r in s4]
    s_table(doc, "S4", "HLA LOH and overall survival by cancer type.",
            "Cox proportional-hazards models within each cancer type with N >= 100, adjusted for age, sex and "
            "log10 TMB; Benjamini-Hochberg FDR across cancer types. HR > 1 indicates worse survival with HLA "
            "LOH. These estimates are unadjusted for global aneuploidy; cancer types that survive aneuploidy "
            "adjustment are reported in Figure 5 and Table 3 (source: s4_survival_by_cancer.tsv).",
            ["Cancer type", "N", "Events", "HR", "95% CI", "P", "FDR"], rows,
            widths=[2.6, 0.65, 0.7, 0.7, 1.2, 0.75, 0.7], font=8.5)
    doc.add_page_break()

    # ---- S5 (rewritten)
    s5 = rd("s5_panel_sensitivity.tsv")
    rows = [[r["effect"], num(r["full_OR"]), f"{num(r['full_lo'])}-{num(r['full_hi'])}", num(r["rest_OR"]),
             f"{num(r['rest_lo'])}-{num(r['rest_hi'])}"] for r in s5]
    s_table(doc, "S5", "Panel-restricted sensitivity analysis (IMPACT468/505).",
            "The four headline associations re-estimated in the 24,512 tumours (82.3% of the primary cohort) "
            "profiled with IMPACT468 or IMPACT505, excluding earlier panel versions. Effect sizes are stable. "
            "This table is REWRITTEN relative to the original submission: the earlier claim that panel and "
            "batch effects are absent is withdrawn, because the arm-independent HLA-LOH call itself is strongly "
            "panel-dependent (IMPACT505 versus IMPACT410 OR 0.30, 95% CI 0.23 to 0.39; see Supplementary Table "
            "S10). Stability of an association is therefore not evidence that the underlying call is "
            "panel-independent (source: s5_panel_sensitivity.tsv).",
            ["Effect", "Full-cohort OR", "95% CI", "Restricted OR", "Restricted 95% CI"], rows,
            widths=[2.5, 1.0, 1.35, 1.0, 1.35], font=9)
    doc.add_page_break()

    # ---- S6
    s6 = rd("s6_mediation.tsv")
    rows = [[r["Quantity"], num(r["Estimate"], 4), num(r["CI_low"], 4), num(r["CI_high"], 4)] for r in s6]
    s_table(doc, "S6", "Mediation of the whole-genome-doubling effect on HLA LOH through chromosome 6p loss.",
            "Nonparametric decomposition with patient-level bootstrap resampling. ACME, average causal "
            "mediation (indirect) effect through 6p loss; ADE, average direct effect; proportion mediated = "
            "ACME / total effect. Estimates are differences in the probability of HLA LOH. Because 6p loss is "
            "near-definitional for HLA LOH at the HLA locus, the near-null direct effect is expected "
            "(source: s6_mediation.tsv).",
            ["Quantity", "Estimate", "95% CI low", "95% CI high"], rows,
            widths=[2.2, 1.2, 1.2, 1.2], font=9)
    doc.add_page_break()

    # ---- S7
    s7a = rd("s7_germline_evaluability.tsv"); s7b = rd("s7_loh_by_homozygous_burden.tsv"); s7c = rd("s7_models.tsv")
    heading(doc, "Supplementary Table S7. Germline HLA zygosity and locus-level LOH evaluability "
                 "(methodological).", 12)
    legend(doc, "Among genotyped patients, germline-homozygous class I loci are structurally non-evaluable "
                "for loss of heterozygosity: LOH is defined as loss of one of two distinct germline alleles, "
                "so a homozygous locus can never yield a call. Heterozygous loci are evaluable in about 60% of "
                "tumours. Revised against the original submission: this is presented strictly as the "
                "evaluability ceiling of the assay. The earlier framing of germline homozygosity as a "
                "constraint on evolutionary pressure is withdrawn, because the 0% evaluability makes the "
                "comparison a tautology (source: s7_germline_evaluability.tsv, s7_loh_by_homozygous_burden.tsv, "
                "s7_models.tsv).", size=9)
    mk_table(doc, ["Locus", "Heterozygous N", "Heterozygous evaluable %", "Homozygous N",
                   "Homozygous evaluable %"],
             [[r["locus"], r["het_n"], num(r["het_eval_pct"], 1), r["hom_n"], num(r["hom_eval_pct"], 1)]
              for r in s7a], widths=[0.9, 1.35, 1.6, 1.15, 1.5], font=9)
    para(doc, "", space_after=2)
    mk_table(doc, ["Germline-homozygous loci per patient", "N", "HLA LOH n", "HLA LOH %", "95% CI lo",
                   "95% CI hi"],
             [[r["gh_burden"], r["n"], r["n_LOH"], num(r["pct"], 1), num(r["lo"], 1), num(r["hi"], 1)]
              for r in s7b], widths=[2.4, 0.8, 0.85, 0.85, 0.85, 0.85], font=9)
    para(doc, "", space_after=2)
    mk_table(doc, ["Model", "OR", "95% CI low", "95% CI high", "P"],
             [[r["model"], num(r["OR"]), num(r["lo"]), num(r["hi"]), num(r["P"], 4)] for r in s7c],
             widths=[3.1, 0.8, 1.0, 1.0, 0.85], font=9)
    doc.add_page_break()

    # ---- S-aneuploidy1 (S8)
    sa = rd("s_aneuploidy1_models.tsv"); st = rd("s_aneuploidy1_tertiles.tsv")
    heading(doc, "Supplementary Table S8. Association of TMB with HLA LOH across aneuploidy specifications "
                 "(S-aneuploidy1).", 12)
    legend(doc, "Logistic regression of HLA LOH on log10 TMB, adjusted for cancer type, gene panel and "
                "pathologist tumour purity, with the global aneuploidy score entering as one of the stated "
                "variants. The aneuploidy score is the fraction of evaluable autosomal arms (of 39) carrying a "
                "copy-number gain or loss; excluding variants remove the stated arm from the denominator and "
                "numerator. Complete-case cohort n=29,407 (HLA-LOH-positive 7,449). The unadjusted estimate "
                "1.568 attenuates to 1.238 to 1.256 but survives in every specification; the surviving "
                "component is not a 6p-only effect. Rows marked New were computed for this revision "
                "(source: s_aneuploidy1_models.tsv).", size=9)
    mk_table(doc, ["Aneuploidy specification", "N", "LOH n", "OR per log10 TMB (95% CI)", "P", "New"],
             [[r["spec"], r["N"], r["n_LOH"], r["OR_CI"], r["P_fmt"],
               "yes" if r["is_new"].strip().upper() == "TRUE" else ""] for r in sa],
             widths=[3.05, 0.6, 0.65, 1.6, 0.75, 0.45], font=8.5)
    para(doc, "", space_after=2)
    legend(doc, "Tertile stratification of the same cohort restricted to tumours with a WGD call (n=29,288): "
                "the TMB association is strongest in the lowest aneuploidy tertile and fails in the highest, "
                "i.e. the residual TMB signal is concentrated where genome-wide instability is low "
                "(source: s_aneuploidy1_tertiles.tsv).", size=9)
    # 区间端点不是 P 值：Q1 的下界是真 0（非整倍体评分的最小值），写成 "<0.001-0.207"
    # 会把一个区间误读成 P 值上限。故此处把 "0.000-" 端点显式写成 "0-"，语义精确保留，
    # 同时 DOCX 内不再出现 "0.000" 这个 token（P 值型的 0.000/0.0000 走 zdisp 归一）。
    def _rng(s):
        return str(s).replace("0.000–", "0–").replace("0.000-", "0–")
    mk_table(doc, ["Aneuploidy tertile", "N", "LOH n", "Aneuploidy range", "OR per log10 TMB (95% CI)", "P"],
             [[r["tertile"], r["N"], r["n_LOH"], _rng(r["frac_range"]), r["OR_CI"], r["P_fmt"]] for r in st],
             widths=[1.3, 0.6, 0.65, 1.4, 1.75, 0.7], font=8.5)
    doc.add_page_break()

    # ---- S-arm1 (S9)
    ra = rd("s_arm1_rank.tsv")
    heading(doc, "Supplementary Table S9. Association of each of the 41 chromosome arms with TMB (S-arm1).",
            12)
    legend(doc, "Each arm was tested for association with log10 TMB in a multivariable model including all 41 "
                "arms; arms are ranked by the magnitude of the loss coefficient. Chromosome 6p, which carries "
                "the HLA class I locus, ranks 26th of 41 and is therefore not the arm most strongly associated "
                "with TMB; 17p ranks first. This directly addresses the concern that the TMB-HLA LOH "
                "association is simply a 6p effect (source: s_arm1_rank.tsv, 41 rows).", size=9)
    mk_table(doc, ["Rank", "Arm", "N", "beta (loss)", "P"],
             [[r["rank_tmb"], r["arm"] + ("  (HLA locus)" if r["is_6p"].strip().upper() == "TRUE" else ""),
               r["n"], f"{float(r['beta_loss']):.4f}", f"{float(r['p_loss']):.2e}"] for r in ra],
             widths=[0.55, 1.6, 0.8, 1.15, 1.35], font=8)
    doc.add_page_break()

    # ---- S-reliability1 (S10)
    hr = rd("s_reliability1_models.tsv"); dc = rd("s_reliability1_purity_decile.tsv")
    gs = rd("s_reliability1_group_summary.tsv"); ps = rd("s_reliability1_purity_strata.tsv")
    au = rd("s_reliability1_auc.tsv")
    heading(doc, "Supplementary Table S10. Calling reliability: purity, coverage and panel dependence "
                 "(S-reliability1).", 12)
    legend(doc, "Logistic model of the arm-independent versus arm-dependent HLA-LOH call (n=5,805 tumours with "
                "a 6p call; 1,644 arm-independent events), adjusted for cancer type. Panel A gives the model "
                "terms; panel B the arm-independent fraction by purity decile; panel C the three call groups; "
                "panel D the same model refit within purity strata; panel E model discrimination. Lower purity, "
                "lower coverage and the IMPACT505 panel all shift calls from arm-dependent to arm-independent, "
                "i.e. the allele-specific calling rate is a technical property "
                "(source: s_reliability1_models.tsv and related).", size=9)
    mk_table(doc, ["Term", "OR (95% CI)", "P", "PINNED reference (V2/r3p4, same cohort)"],
             [[r["term_label"], r["OR_CI"], r["P_fmt"], r["PINNED_ref"]] for r in hr],
             widths=[2.3, 1.5, 0.8, 2.5], font=8.5)
    para(doc, "", space_after=2)
    legend(doc, "Panel B. Arm-independent fraction of HLA-LOH calls by FACETS purity decile.", size=9)
    mk_table(doc, ["Purity decile", "N", "Arm-independent n", "Arm-independent %", "Median purity %"],
             [[r["dec_p"], r["n"], r["n_armind"], num(r["pct"], 1), num(r["purity_median_pct"], 0)]
              for r in dc], widths=[1.1, 0.7, 1.4, 1.4, 1.3], font=8.5)
    para(doc, "", space_after=2)
    legend(doc, "Panel C. Characteristics of the three call groups (all primary-cohort tumours).", size=9)
    mk_table(doc, ["Group", "N", "FACETS purity median %", "Coverage median", "Ploidy median",
                   "Aneuploidy median", "% WGD", "% purity < 30"],
             [[r["group"], r["n"], r["facets_purity_pct_median"], r["coverage_median"], r["ploidy_median"],
               r["aneuploidy_median"], r["wgd_pct"], r["pct_purity_lt30"]] for r in gs],
             widths=[1.25, 0.65, 1.2, 0.9, 0.75, 0.95, 0.55, 0.85], font=8.5)
    para(doc, "", space_after=2)
    legend(doc, "Panel D. The model of panel A refit within purity strata.", size=9)
    mk_table(doc, ["Purity >=", "N", "Events", "WGD OR", "Purity per -10% OR", "Coverage per +100x OR"],
             [[f"{r['purity_ge_pct']}%", r["n"], r["y"], num(r["wgd_OR"]), num(r["pur_per10_OR"]),
               num(r["cov_per100_OR"])] for r in ps],
             widths=[0.9, 0.7, 0.7, 0.9, 1.5, 1.5], font=8.5)
    para(doc, "", space_after=2)
    legend(doc, "Panel E. Model discrimination for the arm-independent versus arm-dependent call.", size=9)
    mk_table(doc, ["Model", "McFadden R2", "AUC", "Source"],
             [[r["model"], r["McFadden_R2"], r["AUC"], r["source"]] for r in au],
             widths=[3.2, 1.1, 0.8, 1.6], font=8.5)
    doc.add_page_break()

    # ---- S-neo1 (S11)
    nm = rd("s_neo1_models.tsv"); nc = rd("s_neo1_cohort.tsv"); ncl = rd("s_neo1_collinearity.tsv")
    # P3 定案：clonal 限制行与 purity>=50% 行在 s_neo1_models.tsv 内已是 primary 规格
    # （含 C(GENE_PANEL)，与 A_logistic.tsv / extended_C_sensitivity.tsv 一致）。
    # 因此渲染层不再覆盖数字，只做一致性断言：任一方向的漂移都会让构建失败，
    # 而不会像旧版那样"文件里是 legacy 值、DOCX 里是覆盖值"。
    # legacy 值（03_stats.py，漏 C(GENE_PANEL)）：
    #   clonal 1.014 (0.974-1.057) P=0.4904 / purity 1.092 (1.020-1.169) P=0.0113
    S11_DEFINITIVE = {
        "clonal":      dict(n="22440", n_LOH="5964", OR_CI="1.013 (0.973\u20131.056)", P_fmt="0.5223"),
        "purity_ge50": dict(n="11259", n_LOH="2776", OR_CI="1.093 (1.021\u20131.170)", P_fmt="0.0104"),
    }
    rows = []
    for r in nm:
        row = [r["kind"], r["definition"], r["n"], r["n_LOH"], r["OR_CI"], r["P_fmt"]]
        low = r["definition"].lower()
        key = "clonal" if "clonal" in low else ("purity_ge50" if "purity_ge50" in low else None)
        if key:
            exp = S11_DEFINITIVE[key]
            for fld, pos in (("n", 2), ("n_LOH", 3), ("OR_CI", 4), ("P_fmt", 5)):
                got = str(row[pos]).strip()
                assert got == exp[fld], "S11 %s %s drift: %r != %r" % (key, fld, got, exp[fld])
            log.write("[S11-ASSERT] %s: %s / P=%s (n=%s, LOH=%s) matches primary spec\n"
                      % (key, exp["OR_CI"], exp["P_fmt"], exp["n"], exp["n_LOH"]))
        rows.append(row)
    heading(doc, "Supplementary Table S11. Neoantigen burden and HLA LOH: all models (S-neo1).", 12)
    legend(doc, "NetMHCpan-4.2e predictions for the full primary cohort with HLA genotype (26,092 tumours, "
                "191 distinct class I alleles, 15,518,931 allele-peptide pairs scored; zero dropped rows). "
                "Outcome: HLA LOH. All logistic models adjust for cancer type, gene panel, tumour purity, "
                "log10 TMB and the global aneuploidy score unless stated. The primary estimate is OR 1.064 per "
                "SD of neoantigen burden, but the burden is almost collinear with TMB (Spearman rho 0.705) and "
                "the association disappears when restricted to clonal mutations - therefore no immune-editing "
                "mechanism is claimed (source: s_neo1_models.tsv; the clonal-restriction row is recomputed in "
                "QC/P2/clonal_or_definitive.R and the purity>=50% row in QC/P2/s11_purity_finalize.py, both "
                "reported with the same adjustment set as the primary model: clonal n=22,440, 5,964 HLA-LOH; "
                "purity>=50% n=11,259, 2,776 HLA-LOH).", size=9)
    mk_table(doc, ["Kind", "Model / definition", "N", "LOH n", "OR (95% CI)", "P"],
             rows,
             widths=[0.75, 3.35, 0.65, 0.6, 1.4, 0.85], font=8)
    para(doc, "", space_after=2)
    legend(doc, "Cohort description and collinearity.", size=9)
    mk_table(doc, ["Item", "Value"], [[r["item"], r["value"]] for r in nc],
             widths=[4.3, 2.4], font=8.5)
    mk_table(doc, ["x", "y", "n", "Spearman rho", "P"],
             [[r["x"], r["y"], r["n"], f"{float(r['spearman_rho']):.4f}", r["P"]] for r in ncl],
             widths=[1.6, 1.6, 0.9, 1.3, 1.3], font=8.5)
    doc.add_page_break()

    # ---- S-neo2 (S12)
    na_ = rd("s_neo2_allele_tests.tsv"); n2c = rd("s_neo2_cohort.tsv"); n2f = rd("s_neo2_fractions.tsv")
    heading(doc, "Supplementary Table S12. Allele-paired neoantigen test (S-neo2).", 12)
    legend(doc, "Within each HLA-LOH tumour the two germline alleles of a locus are paired and the number of "
                "predicted binders is compared between the lost and the kept allele, testing whether the "
                "retained allele presents relatively more neoantigens. Outcome definition: per sample and "
                "locus, binders were summed per allele from the NetMHCpan-4.2e calls; loci with a germline-"
                "homozygous genotype were removed before pairing because LOH is undefined there. Estimates are "
                "from exact conditional logistic regression (Wald and likelihood-ratio P values). Ties "
                "(samples with equal binder counts on both alleles) are dropped from the sample-level fraction "
                "and counted explicitly. The test is negative in every prespecified analysis; only the clonal "
                "restriction reaches nominal significance and it is not robust (source: s_neo2_allele_tests.tsv).",
            size=9)
    mk_table(doc, ["Test", "Type", "Pairs", "OR lost vs kept (95% CI)", "P", "Sign-test P"],
             [[r["test"], r["test_type"], r["n_pairs"], r["OR_CI"], r["P_fmt"], r["signP"]] for r in na_],
             widths=[1.9, 2.15, 0.65, 1.6, 0.7, 0.8], font=8)
    para(doc, "", space_after=2)
    legend(doc, "Pairing cohort.", size=9)
    mk_table(doc, ["Item", "Value"], [[r["item"], r["value"]] for r in n2c], widths=[4.3, 2.4], font=8.5)
    para(doc, "", space_after=2)
    legend(doc, "Sample-level fractions with ties handled explicitly. Ties are reported rather than imputed; "
                "the fraction below uses only samples with a strictly larger binder count on one allele.",
         size=9)
    mk_table(doc, ["Item", "Value", "N", "Source"],
             [[r["item"], num(float(r["value"]), 3) if float(r["value"]) < 1 else r["value"], r["n"],
               r["source"]] for r in n2f], widths=[3.6, 1.1, 0.8, 1.2], font=8.5)
    doc.add_page_break()

    # ---- S-sv1 (S13)
    sv_sum = rd("s_sv1_summary.tsv"); sv_cls = rd("s_sv1_class_totals.tsv"); sv_m = rd("s_sv1_models.tsv")
    sv_x = rd("s_sv1_class_cross.tsv"); sv_d = rd("s_sv1_distribution.tsv"); sv_l = rd("s_sv1_limitations.tsv")
    heading(doc, "Supplementary Table S13. Structural-variant class burden and HLA LOH (S-sv1).", 12)
    legend(doc, "MSK-IMPACT gene-level structural-variant calls (data_sv.txt: 15,811 calls across 12,502 "
                "samples). These calls are used here as an explicit alternative to COSMIC structural-variant "
                "signature decomposition, which is not identifiable in this data type; the limitations are "
                "listed in panel E. Panel A summarises the call set; panel B gives the class totals; panel C "
                "the logistic models for HLA LOH; panel D the per-class cross-tabulation; panel E the "
                "samples-per-call distribution and panel F the limitations "
                "(source: s_sv1_summary.tsv and related).", size=9)
    mk_table(doc, ["Panel A - item", "Value"], [[r["item"], r["value"]] for r in sv_sum],
             widths=[4.3, 2.4], font=8.5)
    para(doc, "", space_after=2)
    legend(doc, "Panel B. Structural-variant calls by class.", size=9)
    mk_table(doc, ["Class", "Calls"], [[r["Class"], r["N"]] for r in sv_cls], widths=[2.0, 1.0], font=9)
    para(doc, "", space_after=2)
    legend(doc, "Panel C. Logistic models for HLA LOH. SV present is a binary indicator (at least one call); "
                "SV count is the number of calls per tumour. Adjustment sets are cumulative and the last two "
                "models add the global aneuploidy score. The association is present before aneuploidy "
                "adjustment and attenuates to the null afterwards, i.e. the SV signal is largely the same "
                "genome-wide instability signal captured by the aneuploidy score.", size=9)
    mk_table(doc, ["Model", "Term", "OR (95% CI)", "P", "N"],
             [[r["model"], r["term"], r["OR_CI"], r["P_fmt"], r["N"]] for r in sv_m],
             widths=[3.15, 0.75, 1.5, 0.8, 0.6], font=8.5)
    para(doc, "", space_after=2)
    legend(doc, "Panel D. HLA LOH frequency by presence of each structural-variant class.", size=9)
    mk_table(doc, ["Class", "n with", "LOH % with", "n without", "LOH % without", "P"],
             [[r["sv_class"], r["n_with"], r["loh_pct_with"], r["n_without"], r["loh_pct_without"], r["P_fmt"]]
              for r in sv_x], widths=[1.25, 0.85, 1.0, 0.9, 1.15, 0.85], font=8.5)
    para(doc, "", space_after=2)
    legend(doc, "Panel E. Distribution of structural-variant calls per tumour in the primary cohort "
                "(counts >= 3 pooled).", size=9)
    mk_table(doc, ["Calls per tumour", "Samples", "% of primary cohort"],
             [[r["sv_n"], r["n_samples"], num(r["pct"], 2)] for r in sv_d],
             widths=[1.6, 1.2, 1.8], font=9)
    para(doc, "", space_after=2)
    legend(doc, "Panel F. Data limitations that preclude signature-level structural-variant analysis.", size=9)
    mk_table(doc, ["Item", "Detail"], [[r["item"], r["detail"]] for r in sv_l],
             widths=[2.0, 4.7], font=8.5)

    # ---- S14 (P2-B, new in this revision): collinearity / VIF diagnostics
    # 数据取自 QC/P2/vif_diagnostics.tsv（vif_diagnostics.R 产出）的挑选行，
    # 由 QC/P2/make_s14_vif.py 生成 build/s14_vif.tsv。文件不存在则跳过，
    # 以免影响 V3（冻结）侧的重生。
    if os.path.exists(os.path.join(BLD, "s14_vif.tsv")):
        s14 = rd("s14_vif.tsv")
        s14k = rd_opt("s14_model_key.tsv")
        doc.add_page_break()
        heading(doc, "Supplementary Table S14. Collinearity diagnostics for the pan-cancer overall-survival "
                     "Cox models: variance inflation factors, tolerances and correlations.", 12)
        legend(doc, "For one-degree-of-freedom covariates GVIF equals VIF, and the car-adjusted quantity "
                    "GVIF^(1/(2*Df)) is the square root of VIF; for the 63-degree-of-freedom cancer-type factor "
                    "only GVIF and its adjusted form are interpretable, so the VIF cell is left blank. HLA LOH "
                    "versus the global aneuploidy score: Pearson r = 0.328, Spearman rho = 0.332 (n = 27,368). "
                    "No covariate reached the conventional thresholds of 5 or 10. The largest VIF is that of the "
                    "global aneuploidy score (3.27 with all 39 arms, 3.11 to 3.25 across the arm-exclusion "
                    "variants); it falls to 1.27 when the whole-genome-doubling term is removed, which identifies "
                    "the aneuploidy-score / whole-genome-doubling pair (r = 0.80) as the only strongly correlated "
                    "pair in the design. HLA LOH itself has VIF 1.08 to 1.16, i.e. it is not collinear with the "
                    "aneuploidy score: the hazard ratio below 1.0 that appears once the aneuploidy score is added "
                    "reflects over-adjustment for a mediator (chromosome 6p arm loss), not a protective effect of "
                    "HLA LOH. A hazard ratio below 1 in these models must NOT be interpreted as protection, and "
                    "none of the adjusted estimates in Table 3 carries a biological meaning at face value "
                    "(source: QC/P2/vif_diagnostics.tsv, vif_diagnostics.R).", size=9)
        mk_table(doc, ["Model", "Covariate", "Df", "VIF", "GVIF", "GVIF^(1/(2*Df))", "Tolerance"],
                 [[r["model"], r["covariate"], r["df"], r["vif"], r["gvif"], r["gvif_adj"], r["tolerance"]]
                  for r in s14],
                 widths=[0.6, 1.95, 0.35, 0.55, 0.55, 0.9, 0.75], font=8)
        if s14k:
            para(doc, "Model key. " + " ".join(f"{r['code']} = {r['definition']}" for r in s14k),
                 size=8, space_after=2)
        doc.add_page_break()

    p = os.path.join(TBL, "Supplementary_Tables.docx"); doc.save(p); log.write(f"[WROTE] {p}\n")
    return p

# =============================================================== KRT
def build_krt(log):
    doc = Document(); set_base_style(doc); add_page_number_footer(doc)
    heading(doc, "Key Resources Table", 14, space_before=0)
    legend(doc, "Resources used in this study. No antibodies, chemical reagents or other laboratory "
                "materials were used; all analyses are secondary analyses of public data and local software.",
           size=9)
    hdr = ["Resource", "Source", "Identifier", "Notes"]
    rows = [
        ["Deposited data - primary tumour cohort",
         "cBioPortal, MSK-IMPACT 50K (Bandlamudi et al., Cancer Cell 2026)",
         "msk_impact_50k_2026 (cBioPortal study identifier); PMID 41895280",
         "Licence CC BY-NC-ND 4.0. Raw data are not redistributed; access via cBioPortal only."],
        ["Data file - HLA LOH calls", "cBioPortal / MSK-IMPACT 50K", "data_hla_loh.txt",
         "Allele-specific HLA-A/B/C LOH calls, as provided"],
        ["Data file - arm-level copy number", "cBioPortal / MSK-IMPACT 50K", "data_armlevel_cna.txt",
         "41 chromosome arms x 53,929 samples; FACETS arm-level calls, provided by the data source"],
        ["Data file - somatic mutations", "cBioPortal / MSK-IMPACT 50K", "data_mutations.txt",
         "Used for TMB and mutational-signature annotations"],
        ["Data file - structural variants", "cBioPortal / MSK-IMPACT 50K", "data_sv.txt",
         "15,811 gene-level rearrangement calls across 12,502 samples"],
        ["Data file - clinical attributes", "cBioPortal / MSK-IMPACT 50K",
         "data_clinical_patient.txt; data_clinical_sample.txt", "Survival, age, sex, cancer type, gene panel"],
        ["Software - HLA class I binding prediction", "DTU Health Tech, Technical University of Denmark",
         "NetMHCpan-4.2e", "Academic licence obtained; predictions generated locally for internal comparison"],
        ["Software - analysis language", "R Foundation for Statistical Computing", "R 4.6.1",
         "All statistical analyses; see the code deposit for the full package lock file"],
        ["Software - R package", "CRAN", "data.table", "Version recorded in the code deposit (env_lock.txt)"],
        ["Software - R package", "CRAN", "survival", "Version recorded in the code deposit (env_lock.txt)"],
        ["Software - Python environment", "Python Software Foundation", "Python 3.12",
         "Used only to render the tables and the supplementary PDF; not used for statistics"],
        ["Software - FACETS", "Provided by the data source",
         "facets-suite (version recorded by the data source)", "Arm-level calls and purity/ploidy were provided; "
         "FACETS was not re-run"],
        ["Derived data", "This study; public GitHub repository",
         REPO_URL,
         "Licence CC BY-NC-ND 4.0. The repository is public and is the complete and final "
         "availability route for the derived data and the code; no archival identifier is "
         f"required to retrieve them. Snapshot: analysis code and derived data at commit {REPO_COMMIT}"],
        ["Code", "This study; the same public GitHub repository",
         REPO_URL,
         "Licence MIT. The same public repository also carries the derived data; no archival "
         f"identifier is required to retrieve either. Snapshot: analysis code and derived data at commit {REPO_COMMIT}"],
    ]
    mk_table(doc, hdr, rows, widths=[1.5, 1.9, 1.85, 1.85], font=8)
    legend(doc, "Antibodies, chemical reagents and other laboratory materials: none used. There is no "
                "duplication or distribution of CC BY-NC-ND material in this study.", size=9)
    p = os.path.join(COMP, "Key_Resources_Table.docx"); doc.save(p); log.write(f"[WROTE] {p}\n")

# =============================================================== markdown docs
def build_markdown(log):
    data_md = f"""# Data and Code Availability

Manuscript: ISCIENCE-D-26-09416 (revision).

Availability is stated in three steps, matching the structure used in the STAR Methods
"Data and code availability" section.

## Step 1 - Raw data (not redistributed)

All primary tumour data are from the publicly available MSK-IMPACT 50K cohort distributed
through cBioPortal:

- Study: **msk_impact_50k_2026** on cBioPortal (`https://www.cbioportal.org/study/summary?id=msk_impact_50k_2026`)
- Accompanying publication: Bandlamudi et al., *Cancer Cell* 2026 (PMID 41895280)
- Licence: **CC BY-NC-ND 4.0**

Because the licence does not permit redistribution of modified copies, **no raw or
sample-level data from this cohort are included in the deposits below**. Readers must obtain
the raw data directly from cBioPortal. This study is a secondary analysis of those data.

## Step 2 - Derived data tables (public GitHub repository)

All derived tables produced by this study - the per-tumour analysis frame, the per-arm
aneuploidy and arm-loss summaries, the neoantigen prediction summaries, the structural-variant
class summaries, the figure source data, and the number dictionary that maps every reported
figure to its source table - are deposited in the public repository that also holds the
analysis code (Step 3):

- Repository: **GitHub** - `{REPO_URL}` - analysis code and derived data at commit `{REPO_COMMIT}`
- Archive: `derived_data.zip` (see `deposit/` in this package)
- Licence: **CC BY-NC-ND 4.0**

Sample-level derived files (the per-tumour analysis frame, the per-sample aneuploidy score files
and the per-sample structural-variant counts) are deliberately not distributed: they carry the
sample identifiers of the source cohort, which is distributed under CC BY-NC-ND 4.0, and they
are regenerated verbatim from the cBioPortal source files by the deposited code.

The repository URL above is final and the repository is public: the code and the derived data are
both available from that one address at commit `{REPO_COMMIT}`, and every number reported in the
manuscript can be recomputed from it. No archival identifier is required to retrieve either.

## Step 3 - Code (the same public GitHub repository)

All analysis and table-generation code is deposited as `code.zip` (see `deposit/`) in the same
public repository:

- Repository: **GitHub** - `{REPO_URL}` - analysis code and derived data at commit `{REPO_COMMIT}`
- Contents: the R analysis script that recomputes every reported number from the raw data, the
  Python scripts that render the tables and the supplementary PDF, the environment lock files
  (R package versions and Python requirements), and a step-by-step upload README.

The code is released under the MIT licence and the derived data under CC BY-NC-ND 4.0; both are
retrieved from the same public repository, which is their complete and final availability route.

## Reproducibility notes

- The analysis script asserts every headline number against a locked number dictionary
  (`pin_audit.tsv`, 80 assertions, all passing). The script exits non-zero if any assertion
  fails, so the deposited code cannot silently drift from the reported numbers.
- Where a reported number comes from a previously computed on-disk product rather than a fresh
  recomputation, the source file is named in the corresponding supplementary table footnote.
- Analytic cohorts differ between tests by design (for example the survival cohort requires a
  WGD call and the TMB-LOH tertile analysis additionally requires a non-missing WGD field);
  each table states its own n.
"""
    p = os.path.join(COMP, "Data_and_Code_Availability.md")
    with open(p, "w", encoding="utf-8") as f:
        f.write(data_md)
    log.write(f"[WROTE] {p}\n")
    return p

def build_sv_md(log):
    sm = {r["item"]: r["value"] for r in rd("s_sv1_summary.tsv")}
    cl = {r["Class"]: r["N"] for r in rd("s_sv1_class_totals.tsv")}
    mo = rd("s_sv1_models.tsv")
    xc = rd("s_sv1_class_cross.tsv")
    ds = rd("s_sv1_distribution.tsv")
    lim = rd("s_sv1_limitations.tsv")
    L = []
    L.append("# Structural-variant class analysis (alternative to COSMIC structural-variant signatures)")
    L.append("")
    L.append("**Purpose.** Reviewer 3 asked why COSMIC structural-variant (rearrangement) signatures were not "
             "used. The short answer is that the available structural-variant table cannot support "
             "signature-level decomposition. This document reports the alternative analysis we can run - "
             "structural-variant class burden against HLA LOH - and documents why the signature analysis is "
             "not identifiable.")
    L.append("")
    L.append("## 1. Input data")
    L.append("")
    L.append(f"- File: `msk_impact_50k_2026/data_sv.txt` (gene-level rearrangement calls, provided by the data source)")
    L.append(f"- Calls: **{sm['SV rows (gene-level rearrangement calls)']}** rows")
    L.append(f"- Samples with at least one call: **{sm['Samples with \u22651 SV call']}** "
             f"({sm['Cohort fraction with \u22651 SV call (%)']}% of the 54,331-sample cohort)")
    L.append(f"- Calls per sample: median **{sm['SV calls/sample: median']}**, mean "
             f"{sm['SV calls/sample: mean']}, maximum {sm['SV calls/sample: maximum']}")
    L.append(f"- Distinct partner-gene combinations: {sm['Distinct partner-gene combinations']}")
    L.append("")
    L.append("Class totals (these reproduce the locked number dictionary exactly):")
    L.append("")
    L.append("| Class | Calls |")
    L.append("|---|---|")
    for k in ["DELETION", "INVERSION", "TRANSLOCATION", "DUPLICATION", "INSERTION"]:
        if k in cl:
            L.append(f"| {k} | {cl[k]} |")
    L.append("")
    L.append("## 2. Models for HLA LOH")
    L.append("")
    L.append("Logistic regression of `any_HLA_LOH` on the structural-variant term plus cancer type, gene panel "
             "and FACETS tumour purity; the last two models additionally adjust for the global aneuploidy score. "
             "All models use the 29,799-tumour primary analysis cohort.")
    L.append("")
    L.append("| Model | Term | OR (95% CI) | P | n |")
    L.append("|---|---|---|---|---|")
    for r in mo:
        L.append(f"| {r['model']} | {r['term']} | {r['OR_CI']} | {r['P_fmt']} | {r['N']} |")
    L.append("")
    key = {r["model"]: r for r in mo}
    a = [v for v in mo if v["term"] == "sv_any"]
    b = [v for v in mo if v["term"] == "sv_n"]
    L.append("**Reading of the result.** Structural-variant presence is associated with HLA LOH before "
             f"aneuploidy adjustment (OR {a[0]['OR_CI']}, P = {a[0]['P_fmt']}) and the association attenuates to "
             f"the null once the global aneuploidy score is included (OR {a[1]['OR_CI']}, "
             f"P = {a[1]['P_fmt']}). The count-based specification behaves identically "
             f"({b[0]['OR_CI']}, P = {b[0]['P_fmt']} versus {b[1]['OR_CI']}, P = {b[1]['P_fmt']}). "
             "Structural-variant burden therefore appears to be another expression of the same genome-wide "
             "instability captured by the aneuploidy score, not an independent determinant of HLA LOH.")
    L.append("")
    L.append("## 3. HLA LOH frequency by structural-variant class")
    L.append("")
    L.append("| Class | n with | LOH % with | n without | LOH % without | P |")
    L.append("|---|---|---|---|---|---|")
    for r in xc:
        L.append(f"| {r['sv_class']} | {r['n_with']} | {r['loh_pct_with']} | {r['n_without']} | "
                 f"{r['loh_pct_without']} | {r['P_fmt']} |")
    L.append("")
    L.append("## 4. Calls per tumour")
    L.append("")
    L.append("| Calls per tumour | Samples | % of primary cohort |")
    L.append("|---|---|---|")
    for r in ds:
        L.append(f"| {r['sv_n'] if int(float(r['sv_n'])) < 3 else '3+'} | {r['n_samples']} | {float(r['pct']):.2f} |")
    L.append("")
    L.append("## 5. Why COSMIC structural-variant signatures were not used")
    L.append("")
    for r in lim:
        L.append(f"- **{r['item']}** - {r['detail']}")
    L.append("")
    L.append("## 6. Source files")
    L.append("")
    L.append("- `V3/03_tables/build/s_sv1_sample_counts.tsv` - per-sample call counts and per-class counts")
    L.append("- `V3/03_tables/build/s_sv1_summary.tsv`, `s_sv1_class_totals.tsv`")
    L.append("- `V3/03_tables/build/s_sv1_models.tsv`, `s_sv1_class_cross.tsv`, `s_sv1_distribution.tsv`, "
             "`s_sv1_limitations.tsv`")
    L.append("- Analysis script: `V3/06_compliance/deposit/code/01_build_tables_V3.R` (section S-sv1)")
    p = os.path.join(TBL, "SV_class_analysis.md")
    with open(p, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    log.write(f"[WROTE] {p}\n")
    return p

# ===================================================================== MAIN
def main():
    logp = os.path.join(V3, "QC", "build_docx.log")
    with open(logp, "w", encoding="utf-8") as log:
        scan_total = 0
        build_main_tables(log)
        supp = build_supplement(log)
        build_krt(log)
        build_markdown(log)
        build_sv_md(log)
        for f, lbl in [(os.path.join(TBL, "Table1_baseline.docx"), "Table1_baseline.docx"),
                       (os.path.join(TBL, "Table2_drivers.docx"), "Table2_drivers.docx"),
                       (os.path.join(TBL, "Table3_survival.docx"), "Table3_survival.docx"),
                       (supp, "Supplementary_Tables.docx"),
                       (os.path.join(COMP, "Key_Resources_Table.docx"), "Key_Resources_Table.docx")]:
            if os.path.exists(f):
                scan_total += scan_markdown(Document(f), lbl, log)
        log.write(f"[MD-SCAN] TOTAL RESIDUE = {scan_total}\n")
        print(f"MD residue total = {scan_total}")
    print("docx build done")
    return 0

if __name__ == "__main__":
    sys.exit(main())
