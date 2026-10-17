#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_gates_v4.py — Phase 2b-1 门禁（全部对 V4 执行，不碰 V3）

G1  段落数 / 条目数 == 174（不增删段落）
G2  数字 token 多重集证据：文件级数字差异 == 16 处编辑区间内数字差异之和
    （即"除声明处外，任何数字 token 都没有变"）
G3  verify_anchors（28 个锚点，md + 两个 DOCX）
G4  scan_markdown_residue（两个 DOCX，残留 markdown == 0）
G5  MARKED 与 CLEAN 逐段文本全等 + CLEAN 高亮 run == 0 + DOCX 段落数 == 174
G6  16 处编辑的"新串"必须逐字出现在 MARKED/CLEAN 的段落文本中
"""
import importlib.util, json, os, re, sys, pathlib
from collections import Counter

from docx import Document
from docx.oxml.ns import qn

HERE = pathlib.Path(__file__).resolve().parent
V4 = HERE.parent.parent
MS = V4 / "01_manuscript"
NUM_RE = re.compile(r"\d+(?:[.,]\d+)*")


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, str(path))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def nums(t):
    return Counter(m.group(0).replace(",", "") for m in NUM_RE.finditer(t))


def signed_diff(after_txt, before_txt):
    """signed multiset difference: +n for tokens gained, -n for tokens lost."""
    a, b = nums(after_txt), nums(before_txt)
    d = {}
    for k in set(a) | set(b):
        v = a[k] - b[k]
        if v:
            d[k] = v
    return d


def addinto(acc, d, sign=1):
    for k, v in d.items():
        acc[k] = acc.get(k, 0) + sign * v


def g1_items(make_mod):
    items = make_mod.iter_manuscript_items()
    print("G1 manuscript items (paragraphs/headings/bullets written to DOCX):", len(items))
    ok = len(items) == 174
    print("G1 174 paragraphs preserved:", "PASS" if ok else "FAIL")
    return ok


def g2_numbers():
    meta = json.load(open(HERE / "MANUSCRIPT_EDITS.json", encoding="utf-8"))
    files = sorted(meta["sha256_after"])
    tot_file, tot_edit = {}, {}
    print("G2 numeric-token multiset proof (numbers normalised: thousands separators removed)")
    print("   %-22s %6s %6s %10s" % ("file", "before", "after", "signed delta"))
    for f in files:
        before = open(HERE / "_backup_writer_before" / f, encoding="utf-8").read()
        after = open(MS / f, encoding="utf-8").read()
        d = signed_diff(after, before)
        addinto(tot_file, d)
        pos = sum(v for v in d.values() if v > 0)
        neg = -sum(v for v in d.values() if v < 0)
        print("   %-22s %6d %6d   +%d / -%d" %
              (f, sum(nums(before).values()), sum(nums(after).values()), pos, neg))
    for e in meta["edits"]:
        addinto(tot_edit, signed_diff(e["new"], e["old"]))
    resid = {}
    for k in set(tot_file) | set(tot_edit):
        v = tot_file.get(k, 0) - tot_edit.get(k, 0)
        if v:
            resid[k] = v
    print("\n   signed numeric delta, file level (all 5 files):")
    for k, v in sorted(tot_file.items(), key=lambda x: (len(x[0]), x[0])):
        print("      %-12s %+d" % (k, v))
    print("   signed numeric delta, edit level (16 declared edits):")
    for k, v in sorted(tot_edit.items(), key=lambda x: (len(x[0]), x[0])):
        print("      %-12s %+d" % (k, v))
    ok = not resid
    print("   file-level delta == edit-level delta:", "PASS" if ok else "FAIL")
    if not ok:
        print("   residual:", resid)
    return ok


def g3_anchors():
    mod = load(V4 / "05_response" / "verify_anchors.py", "va_v4")
    mod.V3 = V4
    mod.MS = MS
    mod.MAP = V4 / "05_response" / "ANCHOR_MAP.tsv"
    print("G3 verify_anchors (V4 paths: MS=%s, MAP=%s)" % (mod.MS, mod.MAP))
    try:
        mod.main()
        return False           # main() exits 0 only on success; reaching here means odd
    except SystemExit as e:
        print("G3 exit code:", e.code)
        return e.code == 0


def g4_residue():
    mod = load(V4 / "QC" / "scan_markdown_residue.py", "smr_v4")
    mod.MS = str(MS)
    mod.FILES = [("MARKED", str(MS / "HLA_LOH02_revision_MARKED.docx")),
                 ("CLEAN", str(MS / "HLA_LOH02_revision_CLEAN.docx"))]
    print("G4 scan_markdown_residue (V4 DOCX)")
    try:
        mod.main()
        rc = 0
    except SystemExit as e:
        rc = e.code
    print("G4 exit code:", rc)
    return rc == 0


def g5_parity():
    m = Document(MS / "HLA_LOH02_revision_MARKED.docx")
    c = Document(MS / "HLA_LOH02_revision_CLEAN.docx")
    tm = [p.text for p in m.paragraphs]
    tc = [p.text for p in c.paragraphs]
    same = (tm == tc)
    xml_m = m.element.body.xml
    xml_c = c.element.body.xml
    hl_m = xml_m.count('<w:highlight w:val="yellow"')
    hl_c = xml_c.count('<w:highlight w:val="yellow"')
    print("G5 paragraphs: MARKED=%d CLEAN=%d" % (len(tm), len(tc)))
    print("G5 paragraph texts identical:", same)
    print("G5 highlight runs: MARKED=%d CLEAN=%d" % (hl_m, hl_c))
    ok = same and len(tm) == 174 and len(tc) == 174 and hl_c == 0 and hl_m > 0
    print("G5 PASS" if ok else "G5 FAIL")
    return ok


SUBMAP = {"₀":"0","₁":"1","₂":"2","₃":"3","₄":"4","₅":"5","₆":"6","₇":"7","₈":"8","₉":"9",
          "₊":"+","₋":"-","⁻":"-","⁰":"0","¹":"1","²":"2","³":"3","⁴":"4","⁵":"5","⁶":"6",
          "⁷":"7","⁸":"8","⁹":"9","ⁿ":"n"}


def norm_marks(t):
    """把 md/DOCX 两侧的行内标记与上下标编码抹平，便于逐字比对：
    `**`/`` ` `` 去掉；Unicode 上下标按 make_revision_docx.tokenize 的同一映射还原为普通字符。"""
    t = t.replace("**", "").replace("`", "")
    t = "".join(SUBMAP.get(c, c) for c in t)
    return t


def g6_strings():
    meta = json.load(open(HERE / "MANUSCRIPT_EDITS.json", encoding="utf-8"))
    m = Document(MS / "HLA_LOH02_revision_MARKED.docx")
    full = norm_marks("\n".join(p.text for p in m.paragraphs))
    bad = []
    for e in meta["edits"]:
        probe = norm_marks(e["new"])[:120]
        if probe not in full:
            bad.append(e["id"])
    print("G6 edited strings present in MARKED docx: %d/%d" %
          (len(meta["edits"]) - len(bad), len(meta["edits"])))
    if bad:
        print("G6 missing:", bad)
    print("G6 PASS" if not bad else "G6 FAIL")
    return not bad


if __name__ == "__main__":
    make_mod = load(V4 / "QC" / "make_revision_docx.py", "mrd_v4")
    make_mod.MS = str(MS)
    make_mod.V3 = str(V4)
    make_mod.BASELINE_DOCX = str(V4.parent / "投稿版本" / "HLA_LOH02_manuscript.docx")
    results = {}
    results["G1"] = g1_items(make_mod)
    print()
    results["G2"] = g2_numbers()
    print()
    results["G3"] = g3_anchors()
    print()
    results["G4"] = g4_residue()
    print()
    results["G5"] = g5_parity()
    print()
    results["G6"] = g6_strings()
    print()
    print("=" * 60)
    print("GATE SUMMARY:", " ".join("%s=%s" % (k, "PASS" if v else "FAIL")
                                    for k, v in sorted(results.items())))
    sys.exit(0 if all(results.values()) else 1)
