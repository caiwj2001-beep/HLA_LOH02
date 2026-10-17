#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""rebuild_deposit_table1.py - 重建存交包里的 Table1_baseline.tsv（P3 / B）。

问题：
  `deposit/derived_data.zip` 内 `derived_data/supplementary_source_data/Table1_baseline.tsv`
  仍是修订前的快照：Female sex 写 54.4% / 55.2%（P=0.279），且**缺少**修订版新增的
  三行非整倍体评分行。而同一存交包内的 `derived_data/tables_v3/table1_baseline.tsv`
  是当前的 16 行版本——两个副本互相矛盾。

修法：
  以 `V4/03_tables/build/table1_baseline.tsv`（Table 1 DOCX 的唯一数据源）为准，
  按 `README_DATA.md` 里声明的 schema（`Characteristic` · `HLA intact` · `HLA LOH` · `P`）
  重写该文件；P 一律按 DOCX 同一规则归一（"0.000" -> "<0.001"），不引入任何新数字。

用法：
  .tools/docxenv/Scripts/python.exe rebuild_deposit_table1.py [--repo <repo_stage>]
"""
import argparse
import csv
import os

V4 = r"C:\Users\Administrator\科研文件\HLA_LOH02\iscience投稿版本\V4"
SRC = os.path.join(V4, "03_tables", "build", "table1_baseline.tsv")
DEFAULT_REPO = r"C:\Users\Administrator\AppData\Local\hermes\cache\scratch\repo_stage\revision_2026"
REL = os.path.join("data", "supplementary_source_data", "Table1_baseline.tsv")

ap = argparse.ArgumentParser()
ap.add_argument("--repo", default=DEFAULT_REPO)
ap.add_argument("--dry-run", action="store_true")
a = ap.parse_args()
dst = os.path.join(a.repo, REL)

rows = list(csv.DictReader(open(SRC, encoding="utf-8"), delimiter="\t"))
assert len(rows) == 16, len(rows)


def pdisp(s):
    s = ("" if s is None else str(s)).strip()
    return "<0.001" if s == "0.000" else s


out = [["Characteristic", "HLA intact", "HLA LOH", "P"]]
for r in rows:
    out.append([r["characteristic"].strip(), r["hla_intact"].strip(),
                r["hla_loh"].strip(), pdisp(r["P"])])

print("rows written: %d (16 characteristics + header)" % (len(out) - 1))
for line in out:
    print("   ", " | ".join(line))
old = open(dst, "rb").read() if os.path.exists(dst) else b""
new = ("\r\n".join("\t".join(line) for line in out) + "\r\n").encode("utf-8")
print("\nold bytes=%d new bytes=%d ; identical=%s" % (len(old), len(new), old == new))
if a.dry_run:
    print("[DRY-RUN] not written ->", dst)
else:
    import hashlib
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    open(dst, "wb").write(new)
    print("[WROTE]", dst, "sha256=", hashlib.sha256(new).hexdigest())
