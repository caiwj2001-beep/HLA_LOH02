#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""run_revision_docx_v4.py — 用 V4/QC/make_revision_docx.py 的**同一算法**构建 V4 的两个 DOCX。

为什么需要这一层：`QC/make_revision_docx.py` 是从 V3 目录原样复制的，模块级常量仍指向 V3
（ROOT/V3/MS/BASELINE_DOCX/OUT_*），直接运行会把产物写进冻结的 V3。本 runner 在 import 之后
把这些模块级常量重绑到 V4，再调用 build()——算法、阈值、Mode C 规则一行不改。

用法：
  python run_revision_docx_v4.py --baseline specified --outdir ../../01_manuscript \
      --decisions _docx_decisions_v4.json
  python run_revision_docx_v4.py --baseline old --outdir _baseline_old
"""
import argparse, importlib.util, json, os, sys, pathlib

HERE = pathlib.Path(__file__).resolve().parent          # V4/QC/P2
V4 = HERE.parent.parent                                 # V4
SCRIPT = V4 / "QC" / "make_revision_docx.py"

BASELINES = {
    # 用户指定稿（本轮正式基准）：仅与 manuscript.docx 差 ¶48 Data-and-code 段
    "specified": V4.parent / "投稿版本" / "HLA_LOH02_manuscript.docx",
    # 此前使用的基准
    "old":       V4.parent / "投稿版本" / "manuscript.docx",
}


def load_module():
    spec = importlib.util.spec_from_file_location("make_revision_docx_v3alg", str(SCRIPT))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--baseline", choices=sorted(BASELINES), default="specified")
    ap.add_argument("--outdir", default=str(V4 / "01_manuscript"))
    ap.add_argument("--decisions", default="_docx_decisions_v4.json")
    ap.add_argument("--tag", default="")
    a = ap.parse_args()

    outdir = pathlib.Path(a.outdir)
    if not outdir.is_absolute():
        outdir = (HERE / outdir).resolve()
    outdir.mkdir(parents=True, exist_ok=True)
    base = BASELINES[a.baseline]
    assert base.exists(), base

    mod = load_module()
    # —— 把模块级常量重绑到 V4（算法不动）——
    mod.V3 = str(V4)
    mod.MS = str(V4 / "01_manuscript")
    mod.BASELINE_DOCX = str(base)
    mod.OUT_MARKED = str(outdir / ("HLA_LOH02_revision_MARKED%s.docx" % a.tag))
    mod.OUT_CLEAN = str(outdir / ("HLA_LOH02_revision_CLEAN%s.docx" % a.tag))
    dec = pathlib.Path(a.decisions)
    mod.DEC_PATH = str(dec if dec.is_absolute() else (HERE / dec).resolve())

    print("runner: V4     =", mod.V3)
    print("runner: MS     =", mod.MS)
    print("runner: BASE   =", mod.BASELINE_DOCX)
    print("runner: MARKED =", mod.OUT_MARKED)
    print("runner: CLEAN  =", mod.OUT_CLEAN)
    overall = mod.build()
    summary = {"baseline": a.baseline, "baseline_path": mod.BASELINE_DOCX,
               "total_paras": overall["total_paras"],
               "highlight_paras": overall["highlight_paras"],
               "pct_paras": overall["pct"],
               "highlight_chars": overall["highlight_chars"],
               "total_chars": overall["total_chars"],
               "char_pct": overall["char_pct"],
               "highlight_chars_full_mode": overall["highlight_chars_full_mode"],
               "char_pct_full_mode": overall["char_pct_full_mode"],
               "marked": overall["stats"]["marked"],
               "clean": overall["stats"]["clean"],
               "tiers": overall["tiers"]}
    p = HERE / ("_coverage_%s%s.json" % (a.baseline, a.tag))
    p.write_text(json.dumps(summary, ensure_ascii=False, indent=1), encoding="utf-8")
    print("coverage json ->", p)


if __name__ == "__main__":
    main()
