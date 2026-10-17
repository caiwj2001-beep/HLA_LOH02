#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""rebuild_supplement_pdf_v4.py — 在 V4 上重建补充 DOCX + 补充 PDF（两遍法）。

为什么需要这个 runner：
  * `.tools/build_tables_docx.py` 的 ROOT/V3 常量写死指向 V3（冻结只读）；
  * `.tools/build_supplement_pdf.py` 在 import 时从 build_tables_docx 取 V3/SUPP/TBL/QC，
    并把锚点表 ANCHORS 写死为 S1..S13。

本 runner 只做三件事：
  1) 把 build_tables_docx 的 BLD/TBL/COMP/SUPP/V3 重定向到 V4；
  2) import build_supplement_pdf，重定向它的 QC/PDF_OUT/TMP_DOCX，并把 ANCHORS 扩到 S1..S14；
  3) 调它的 main()——即官方的两遍法（渲染→读页码→回写目录→再渲染，直到收敛）。

用法：
  .tools/docxenv/Scripts/python.exe rebuild_supplement_pdf_v4.py
"""
import os
import sys
import importlib.util

TOOLS = r"C:\Users\Administrator\科研文件\HLA_LOH02\.tools"
V4    = r"C:\Users\Administrator\科研文件\HLA_LOH02\iscience投稿版本\V4"


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


def main():
    sys.path.insert(0, TOOLS)
    B = load("build_tables_docx", os.path.join(TOOLS, "build_tables_docx.py"))
    B.V3   = V4
    B.BLD  = os.path.join(V4, "03_tables", "build")
    B.TBL  = os.path.join(V4, "03_tables")
    B.COMP = os.path.join(V4, "06_compliance")
    B.SUPP = os.path.join(V4, "04_supplement")
    for d in (B.TBL, B.SUPP):
        os.makedirs(d, exist_ok=True)

    P = load("build_supplement_pdf", os.path.join(TOOLS, "build_supplement_pdf.py"))
    P.V3       = V4
    P.SUPP     = B.SUPP
    P.TBL      = B.TBL
    P.QC       = os.path.join(V4, "QC", "P2")
    P.PDF_OUT  = os.path.join(B.SUPP, "Supplemental_Information.pdf")
    P.TMP_DOCX = os.path.join(P.QC, "_supp_tmp.docx")
    os.makedirs(P.QC, exist_ok=True)
    # 锚点：S1..S14 + 两张补充图
    P.ANCHORS = [(f"Supplementary Figure S{i}", f"Supplementary Figure S{i}.") for i in (1, 2)] \
              + [(f"Supplementary Table S{i}",  f"Supplementary Table S{i}.")  for i in range(1, 15)]

    print(f"[V4] V3 redirect      -> {B.V3}")
    print(f"[V4] BLD              -> {B.BLD}")
    print(f"[V4] TBL              -> {B.TBL}")
    print(f"[V4] SUPP             -> {B.SUPP}")
    print(f"[V4] QC (tmp+log)     -> {P.QC}")
    print(f"[V4] anchors          -> {len(P.ANCHORS)}")
    rc = P.main()
    return rc


if __name__ == "__main__":
    sys.exit(main())
