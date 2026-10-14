#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
build_supplement_pdf.py — 把补充图与补充表合并为单一 Supplemental_Information.pdf
  两遍法：第一遍渲染 → 用 pypdf 读每页文本定位各条目的页码 → 第二遍把真实页码写入目录 → 再渲染
"""
import os, sys, subprocess, shutil, re
from pypdf import PdfReader
from docx import Document
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_tables_docx as B

SOFFICE = r"C:/Program Files/LibreOffice/program/soffice.exe"
V3   = B.V3
SUPP = B.SUPP
TBL  = B.TBL
QC   = os.path.join(V3, "QC")
os.makedirs(QC, exist_ok=True)
PDF_OUT = os.path.join(SUPP, "Supplemental_Information.pdf")
TMP_DOCX = os.path.join(QC, "_supp_tmp.docx")

def to_pdf(docx_path, outdir):
    for f in os.listdir(outdir):
        if f.lower().endswith(".pdf") and f.startswith(os.path.splitext(os.path.basename(docx_path))[0]):
            os.remove(os.path.join(outdir, f))
    # 复制成临时名，避免覆盖目标
    r = subprocess.run([SOFFICE, "--headless", "--norestore", "--convert-to", "pdf",
                        "--outdir", outdir, docx_path],
                       capture_output=True, text=True, timeout=600)
    base = os.path.splitext(os.path.basename(docx_path))[0] + ".pdf"
    pdf = os.path.join(outdir, base)
    if not os.path.exists(pdf):
        raise RuntimeError(f"soffice failed: rc={r.returncode}\n{r.stdout}\n{r.stderr}")
    return pdf

ANCHORS = [
    ("Supplementary Figure S1", "Supplementary Figure S1."),
    ("Supplementary Figure S2", "Supplementary Figure S2."),
    ("Supplementary Table S1", "Supplementary Table S1."),
    ("Supplementary Table S2", "Supplementary Table S2."),
    ("Supplementary Table S3", "Supplementary Table S3."),
    ("Supplementary Table S4", "Supplementary Table S4."),
    ("Supplementary Table S5", "Supplementary Table S5."),
    ("Supplementary Table S6", "Supplementary Table S6."),
    ("Supplementary Table S7", "Supplementary Table S7."),
    ("Supplementary Table S8", "Supplementary Table S8."),
    ("Supplementary Table S9", "Supplementary Table S9."),
    ("Supplementary Table S10", "Supplementary Table S10."),
    ("Supplementary Table S11", "Supplementary Table S11."),
    ("Supplementary Table S12", "Supplementary Table S12."),
    ("Supplementary Table S13", "Supplementary Table S13."),
]

def page_map_from_pdf(pdf, log):
    rd = PdfReader(pdf)
    pages = [(rd.pages[i].extract_text() or "") for i in range(len(rd.pages))]
    pm = {}
    for key, anchor in ANCHORS:
        for i, t in enumerate(pages):
            if anchor in t:
                pm[key] = i + 1
                break
    log.write(f"[PASS1] pdf pages={len(pages)}; anchored {len(pm)}/{len(ANCHORS)}\n")
    for k, _ in ANCHORS:
        log.write(f"    {k} -> page {pm.get(k, 'NOT FOUND')}\n")
    return pm, len(pages)

def main():
    logp = os.path.join(QC, "build_supplement_pdf.log")
    with open(logp, "w", encoding="utf-8") as log:
        # 迭代定位：反复渲染直到目录页码收敛（一般 2 遍即收敛；加入 Figure S2 后可能需
        # 第 3 遍，因为目录行数变化会改变首页块高，从而改变后续条目页码）
        pm, n = {}, None
        stable = False
        for it in range(1, 6):
            log.write(f"\n===== ITERATION {it} =====\n")
            B.build_supplement(log, page_map=pm)
            shutil.copy(os.path.join(TBL, "Supplementary_Tables.docx"), TMP_DOCX)
            pdf = to_pdf(TMP_DOCX, QC)
            log.write(f"[ITER {it}] rendered {pdf}\n")
            pm2, n = page_map_from_pdf(pdf, log)
            drift = {k: (pm.get(k), pm2.get(k)) for k in pm if pm.get(k) != pm2.get(k)}
            log.write(f"[ITER {it}] drift vs previous table: {'NONE' if not drift else drift}\n")
            if pm2 == pm:
                log.write(f"[ITER {it}] page map CONVERGED ({len(pm2)}/{len(ANCHORS)} anchored)\n")
                stable = True
                break
            pm = pm2
        if not stable:
            log.write("[WARN] page map did not converge in 5 iterations\n")
        shutil.copy(pdf, PDF_OUT)
        log.write(f"[WROTE] {PDF_OUT} ({n} pages)\n")
        missing = [k for k, _ in ANCHORS if k not in pm]
        log.write(f"[CHECK] anchored {len(pm)}/{len(ANCHORS)}; missing={missing or 'none'}\n")
        print(f"PDF written: {PDF_OUT} pages={n} anchored={len(pm)}/{len(ANCHORS)} "
              f"converged={stable} missing={missing or 'none'}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
