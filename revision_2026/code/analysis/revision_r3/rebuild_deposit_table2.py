#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""rebuild_deposit_table2.py - 重建存交包里的 Table2_drivers.tsv（P3 遗留修补 / A）。

问题：
  `deposit/derived_data.zip` 内 `derived_data/supplementary_source_data/Table2_drivers.tsv`
  仍是修订前的快照：只有 4 行（distal WGD / germ_hom_any / log_TMB + proximal 6p），
  且数值来自旧的模型拟合（WGD 2.295032...，与现行表 2 的 2.295388... 不同）。
  现行 Table 2 已是 10 行（含 global aneuploidy score 的 unadjusted / +aneuploidy /
  TMB+WGD+cancer+panel 三行，以及 distal multivariable + aneuploidy 的三行）。
  同一存交包内的 `derived_data/tables_v3/table2_drivers.tsv` 是现行的 10 行版本
  （= `V4/03_tables/build/table2_drivers.tsv`，即 Table 2 DOCX 的唯一数据源）——
  两个副本互相矛盾，审稿人一比对即可发现。

修法：
  以 `V4/03_tables/build/table2_drivers.tsv` 为准，按 `README_DATA.md` 为该文件声明的
  schema（`model` · `term` · `OR` · `lo` · `hi` · `p`）重写：
    model ← 表 2 的 model 列（拟合名称）
    term  ← 表 2 的 predictor 列（该拟合中的项）
    OR/lo/hi/p ← 原值照抄（不做任何四舍五入、不引入任何新数字）
  行序与表 2 的呈现顺序一致；CRLF、UTF-8 无 BOM，与同目录其它 source-data 文件一致。

用法：
  .tools/docxenv/Scripts/python.exe rebuild_deposit_table2.py [--repo <repo_stage>] [--dry-run]
"""
import argparse
import csv
import hashlib
import os

V4 = r"C:\Users\Administrator\科研文件\HLA_LOH02\iscience投稿版本\V4"
SRC = os.path.join(V4, "03_tables", "build", "table2_drivers.tsv")
DEFAULT_REPO = r"C:\Users\Administrator\AppData\Local\hermes\cache\scratch\repo_stage\revision_2026"
REL = os.path.join("data", "supplementary_source_data", "Table2_drivers.tsv")

ap = argparse.ArgumentParser()
ap.add_argument("--repo", default=DEFAULT_REPO)
ap.add_argument("--dry-run", action="store_true")
a = ap.parse_args()
dst = os.path.join(a.repo, REL)

rows = list(csv.DictReader(open(SRC, encoding="utf-8"), delimiter="\t"))
assert len(rows) == 10, len(rows)
assert list(rows[0].keys()) == ["predictor", "model", "OR", "lo", "hi", "P", "OR_CI", "P_fmt"], list(rows[0].keys())

out = [["model", "term", "OR", "lo", "hi", "p"]]
for r in rows:
    for k in ("OR", "lo", "hi", "P"):
        assert r[k].strip() != "", ("empty cell", k, r)
    out.append([r["model"].strip(), r["predictor"].strip(),
                r["OR"].strip(), r["lo"].strip(), r["hi"].strip(), r["P"].strip()])

print("rows written: %d (10 table-2 rows + header)" % (len(out) - 1))
for line in out:
    print("   ", " | ".join(line))
old = open(dst, "rb").read() if os.path.exists(dst) else b""
new = ("\r\n".join("\t".join(line) for line in out) + "\r\n").encode("utf-8")
print("\nold bytes=%d sha256=%s" % (len(old), hashlib.sha256(old).hexdigest()))
print("new bytes=%d sha256=%s" % (len(new), hashlib.sha256(new).hexdigest()))
print("identical=%s" % (old == new))
if a.dry_run:
    print("[DRY-RUN] not written ->", dst)
else:
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    open(dst, "wb").write(new)
    print("[WROTE]", dst, "sha256=", hashlib.sha256(open(dst, "rb").read()).hexdigest())
