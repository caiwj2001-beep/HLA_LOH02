#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""fix_s11_provenance.py - 修正 S11 两行 sensitivity 的取值与 provenance（P3 / A-2+A-3）。

问题（A-3）：
  `03_tables/build/s_neo1_models.tsv` 的 `Sensitivity: sens_purity_ge50` 与
  `Sensitivity: sens_clonal_only` 两行，`source` 列写的是 `extended_C_sensitivity.tsv`，
  但两行实际存的 OR/P 是 legacy `C_sensitivity.tsv` 的值（03_stats.py 的 (C) 块，
  该块漏了 C(GENE_PANEL) 项）。表与时序对不上：source 说的是 A 文件，数字来自 B 文件。

修法：
  既然 S11 表注与 primary 模型都声明"调整癌症类型、基因面板、纯度、log10 TMB 与
  全局非整倍体评分"，两行就应当取自 extended 规格（含 C(GENE_PANEL)）。本脚本把两行
  的 OR/lo/hi/P/OR_CI/P_fmt 一律按 extended_C_sensitivity.tsv 重写（n / n_LOH 保持一致，
  并断言），于是 source 列写的文件就是数字真正来自的文件——标签与取值同时为真。

  其中 purity 行由 A-2 独立重算确认（QC/P2/s11_purity_finalize.py：
  OR=1.093263698，P=0.01040550，与 extended 行逐位一致）。

被替换的 legacy 值（保留在此备查）：
  purity_ge50 : 1.092 (1.020-1.169)  P=0.0113   <- C_sensitivity.tsv / 03_stats.py
  clonal_only : 1.014 (0.974-1.057)  P=0.4904   <- C_sensitivity.tsv / 03_stats.py

用法：
  .tools/docxenv/Scripts/python.exe fix_s11_provenance.py [--dry-run]
"""
import csv
import os
import shutil
import sys

V4 = r"C:\Users\Administrator\科研文件\HLA_LOH02\iscience投稿版本\V4"
BLD = os.path.join(V4, "03_tables", "build")
TSV = os.path.join(BLD, "s_neo1_models.tsv")
EXT = r"C:\Users\Administrator\科研文件\HLA_LOH02\neoantigen\output\stats\netmhcpan_full\extended_C_sensitivity.tsv"
LEGACY_EXPECT = {
    "Sensitivity: sens_purity_ge50": ("1.092 (1.020\u20131.169)", "0.0113", "11259", "2776"),
    "Sensitivity: sens_clonal_only": ("1.014 (0.974\u20131.057)", "0.4904", "22440", "5964"),
}

dry = "--dry-run" in sys.argv

ext = {}
with open(EXT, encoding="utf-8") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        if r.get("model") in ("sens_purity_ge50", "sens_clonal_only") and r.get("OR_per_SD"):
            ext[r["model"]] = r
assert set(ext) == {"sens_purity_ge50", "sens_clonal_only"}, sorted(ext)

with open(TSV, encoding="utf-8", newline="") as f:
    rd = csv.DictReader(f, delimiter="\t")
    fields = rd.fieldnames
    rows = list(rd)

changed = []
for r in rows:
    key = r["definition"].strip()
    model = {"Sensitivity: sens_purity_ge50": "sens_purity_ge50",
             "Sensitivity: sens_clonal_only": "sens_clonal_only"}.get(key)
    if not model:
        continue
    e = ext[model]
    assert str(r["n"]).strip() == str(int(float(e["n"]))), (key, r["n"], e["n"])
    assert str(r["n_LOH"]).strip() == str(int(float(e["n_LOH"]))), (key, r["n_LOH"], e["n_LOH"])
    old = (r["OR_CI"], r["P_fmt"], str(r["n"]).strip(), str(r["n_LOH"]).strip())
    assert old == LEGACY_EXPECT[key], ("legacy display changed unexpectedly", key, old)
    OR = float(e["OR_per_SD"]); lo = float(e["ci_lo"]); hi = float(e["ci_hi"]); P = float(e["P"])
    r["OR"] = repr(OR)
    r["lo"] = repr(lo)
    r["hi"] = repr(hi)
    r["P"] = repr(P)
    r["source"] = "extended_C_sensitivity.tsv"
    r["OR_CI"] = "%.3f (%.3f\u2013%.3f)" % (OR, lo, hi)
    r["P_fmt"] = ("<0.001" if P < 1e-3 else "%.4f" % P)
    changed.append((key, old[0], r["OR_CI"], old[1], r["P_fmt"], r["source"]))

assert len(changed) == 2, changed
for c in changed:
    print("[FIX] %-32s %s -> %s | P %s -> %s | source=%s" % c)

if dry:
    print("[DRY-RUN] no file written")
    sys.exit(0)

bak = os.path.join(V4, "QC", "P2", "_backup_before", "P3_s_neo1_models.tsv")
os.makedirs(os.path.dirname(bak), exist_ok=True)
if not os.path.exists(bak):
    shutil.copy2(TSV, bak)
    print("[BAK]", bak)

with open(TSV, "w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields, delimiter="\t",
                       lineterminator="\r\n")
    w.writeheader()
    w.writerows(rows)
print("[WROTE]", TSV)
