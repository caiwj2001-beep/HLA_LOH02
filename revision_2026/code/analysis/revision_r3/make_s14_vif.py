#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""make_s14_vif.py — build V4/03_tables/build/s14_vif.tsv (the rows of Table S14)
from QC/P2/vif_diagnostics.tsv.

Selects the 23 (model, term) rows flagged for publication in VIF_REPORT.md §5,
shortens labels for display, rounds to two decimals, and asserts that every
selected row exists in vif_diagnostics.tsv (fail-closed: no invented numbers).

Run with the DOCX environment interpreter (.tools/docxenv/Scripts/python.exe) or
any python3 — it only uses the stdlib.
"""
import csv, os, sys, collections

P2   = r"C:\Users\Administrator\科研文件\HLA_LOH02\iscience投稿版本\V4\QC\P2"
SRC  = os.path.join(P2, "vif_diagnostics.tsv")
BLD  = r"C:\Users\Administrator\科研文件\HLA_LOH02\iscience投稿版本\V4\03_tables\build"
OUT  = os.path.join(BLD, "s14_vif.tsv")

# display model label -> exact model string in vif_diagnostics.tsv
MODELS = [
    ("M1", "Adjusted (age, sex, TMB, WGD, cancer type)"),
    ("M2", "Adjusted + aneuploidy (all 39 arms, incl. 6p)"),
    ("M3", "Adjusted + aneuploidy excluding 6p"),
    ("M4", "Adjusted + aneuploidy excluding 6q"),
    ("M5", "Adjusted + aneuploidy excluding 6p and 6q"),
    ("M6", "Diagnostic: aneuploidy model with the WGD term removed"),
    ("M7", "Diagnostic: the HLA-LOH / aneuploidy pair only"),
]

# full definitions rendered as a legend under the table (so the table stays one page wide)
MODEL_KEY = {
    "M1": "Adjusted for age, sex, log10 TMB, whole-genome doubling and cancer type.",
    "M2": "M1 plus the global aneuploidy score over all 39 evaluable autosomal arms (6p included).",
    "M3": "M1 plus the aneuploidy score recomputed with chromosome 6p removed.",
    "M4": "M1 plus the aneuploidy score recomputed with chromosome 6q removed.",
    "M5": "M1 plus the aneuploidy score recomputed with 6p and 6q both removed.",
    "M6": "Diagnostic refit of M2 with the whole-genome-doubling term removed.",
    "M7": "Diagnostic model containing HLA LOH and the global aneuploidy score only.",
}

TERM_LABEL = {
    "LOH":      "HLA LOH",
    "frac_all": "Aneuploidy score, 39 arms",
    "frac_ex6p":"Aneuploidy score, 6p excluded",
    "frac_ex6q":"Aneuploidy score, 6q excluded",
    "frac_ex6": "Aneuploidy score, 6p+6q excluded",
    "age":      "Age, per year",
    "SEXf":     "Sex",
    "logTMB":   "log10 TMB",
    "WGDf":     "Whole-genome doubling",
    "cancer_f": "Cancer type",
}

# rows per model, in publication order (aneuploidy term is model-specific)
ROWS = {
    "Adjusted (age, sex, TMB, WGD, cancer type)":
        ["LOH", "age", "SEXf", "logTMB", "WGDf", "cancer_f"],
    "Adjusted + aneuploidy (all 39 arms, incl. 6p)":
        ["LOH", "frac_all", "age", "SEXf", "logTMB", "WGDf", "cancer_f"],
    "Adjusted + aneuploidy excluding 6p":  ["LOH", "frac_ex6p"],
    "Adjusted + aneuploidy excluding 6q":  ["LOH", "frac_ex6q"],
    "Adjusted + aneuploidy excluding 6p and 6q": ["LOH", "frac_ex6"],
    "Diagnostic: aneuploidy model with the WGD term removed": ["LOH", "frac_all"],
    "Diagnostic: the HLA-LOH / aneuploidy pair only": ["LOH", "frac_all"],
}


def f2(x):
    return "" if x in (None, "", "NA") else f"{float(x):.2f}"


def main():
    with open(SRC, encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f, delimiter="\t"))
    idx = {}
    for r in rows:
        if r["block"] != "vif":
            continue
        idx[(r["model"], r["term"])] = r

    out, missing = [], []
    for disp, src_model in MODELS:
        for term in ROWS[src_model]:
            r = idx.get((src_model, term))
            if r is None:
                missing.append((src_model, term))
                continue
            df = str(int(float(r["df"])))
            adj = r["vif_adj"]
            car = r["car_GVIF_adj"]
            if car not in ("", "NA") and adj not in ("", "NA"):
                assert abs(float(car) - float(adj)) < 1e-6, (src_model, term, car, adj)
            out.append({
                "model": disp,
                "source_model": src_model,
                "covariate": TERM_LABEL[term],
                "term": term,
                "df": df,
                "vif": f2(r["vif"]) if df == "1" else "",
                "gvif": f2(r["gvif"]),
                "gvif_adj": f2(adj),
                "tolerance": f2(r["tolerance"]),
            })
    if missing:
        print("FATAL: rows not found in vif_diagnostics.tsv:", missing)
        return 2

    os.makedirs(BLD, exist_ok=True)
    cols = ["model", "covariate", "df", "vif", "gvif", "gvif_adj", "tolerance",
            "source_model", "term"]
    with open(OUT, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols, delimiter="\t", lineterminator="\r\n")
        w.writeheader()
        w.writerows(out)

    print(f"[WROTE] {OUT}  rows={len(out)}")
    keyp = os.path.join(BLD, "s14_model_key.tsv")
    with open(keyp, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\r\n")
        w.writerow(["code", "definition"])
        for code, _ in MODELS:
            w.writerow([code, MODEL_KEY[code]])
    print(f"[WROTE] {keyp}  models={len(MODEL_KEY)}")
    print(f"source rows scanned: {len(idx)} (model,term) pairs in block='vif'")
    bym = collections.Counter(o["model"] for o in out)
    for k, v in bym.items():
        print(f"   {v:2d}  {k}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
