#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Stage 9: INTERNAL consistency check, netMHCpan-4.2e vs MHCflurry, on the FULL-cohort
overlap (the MHCflurry `full` arm is only complete for the first 37 batches =
7,400 samples; all of them are inside the 26,092-sample netMHCpan full arm).

!!! INTERNAL USE ONLY !!!
The DTU licence for NetMHCpan forbids publishing benchmark/comparison results against
other predictors.  This is a private QA artefact; every number that goes into the paper
comes from the netMHCpan arm alone.
"""
import json
import pathlib
import time

import numpy as np
import pandas as pd
from scipy import stats as st

HERE = pathlib.Path(__file__).resolve().parent
NEO = HERE.parent
PRED = NEO / "output" / "predictions"
PEPDIR = NEO / "output" / "peptides"
OUT = PRED / "netmhcpan_full" / "consistency"
PCT_THR = 2.0


def log(m):
    print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)


def load(tag, fn):
    d = PRED / tag
    return pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                      for f in sorted(d.glob(fn))], ignore_index=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    nm_smp = load("netmhcpan_full", "pred_samples_*.tsv")
    mf_smp = load("full", "pred_samples_*.tsv")
    nm_slt = load("netmhcpan_full", "pred_slots_*.tsv")
    mf_slt = load("full", "pred_slots_*.tsv")
    nm_bnd = load("netmhcpan_full", "pred_binders_*.tsv")
    mf_bnd = load("full", "pred_binders_*.tsv")

    samples = list(mf_smp.SAMPLE_ID)            # 7,400 overlap samples
    log(f"netMHCpan-full samples={len(nm_smp)} ; MHCflurry-full samples={len(mf_smp)}")
    res = {"_license_note": "INTERNAL QA ONLY - DTU licence forbids publishing "
                            "netMHCpan benchmark comparisons",
           "n_overlap_samples": len(samples)}

    # ---------- 1. sample level ----------
    m = (nm_smp[["SAMPLE_ID", "n_neo_either", "n_neo_ic50", "n_pep"]]
         .merge(mf_smp[["SAMPLE_ID", "n_neo_either", "n_neo_ic50"]],
                on="SAMPLE_ID", suffixes=("_nm", "_mf")))
    for c in ["n_neo_either_nm", "n_neo_either_mf", "n_neo_ic50_nm", "n_neo_ic50_mf"]:
        m[c] = pd.to_numeric(m[c])
    rho, p = st.spearmanr(m.n_neo_either_nm, m.n_neo_either_mf)
    rho_i, p_i = st.spearmanr(m.n_neo_ic50_nm, m.n_neo_ic50_mf)
    res["sample_level"] = {
        "n": int(len(m)), "spearman_rho_count": float(rho), "spearman_P": float(p),
        "spearman_rho_ic50def": float(rho_i), "spearman_P_ic50def": float(p_i),
        "median_nm": float(m.n_neo_either_nm.median()),
        "iqr_nm": [float(m.n_neo_either_nm.quantile(.25)), float(m.n_neo_either_nm.quantile(.75))],
        "mean_nm": float(m.n_neo_either_nm.mean()),
        "median_mf": float(m.n_neo_either_mf.median()),
        "iqr_mf": [float(m.n_neo_either_mf.quantile(.25)), float(m.n_neo_either_mf.quantile(.75))],
        "mean_mf": float(m.n_neo_either_mf.mean()),
        "mean_ratio_nm_over_mf": float(m.n_neo_either_nm.mean() / m.n_neo_either_mf.mean()),
        "pearson_r": float(st.pearsonr(m.n_neo_either_nm, m.n_neo_either_mf)[0]),
        "median_diff_nm_minus_mf": float((m.n_neo_either_nm - m.n_neo_either_mf).median())}
    log(f"[sample] n={len(m)} rho={rho:.3f} medians {m.n_neo_either_nm.median():.0f}(nm) "
        f"vs {m.n_neo_either_mf.median():.0f}(mf) ratio={res['sample_level']['mean_ratio_nm_over_mf']:.3f}")

    # ---------- 2. allele level ----------
    a = nm_slt[["SAMPLE_ID", "slot", "n_bind_either"]].merge(
        mf_slt[["SAMPLE_ID", "slot", "n_bind_either"]], on=["SAMPLE_ID", "slot"],
        suffixes=("_nm", "_mf"))
    a["n_bind_either_nm"] = pd.to_numeric(a.n_bind_either_nm)
    a["n_bind_either_mf"] = pd.to_numeric(a.n_bind_either_mf)
    rho_a, p_a = st.spearmanr(a.n_bind_either_nm, a.n_bind_either_mf)
    res["allele_level"] = {"n_slots": int(len(a)), "spearman_rho": float(rho_a),
                           "spearman_P": float(p_a),
                           "mean_nm": float(a.n_bind_either_nm.mean()),
                           "mean_mf": float(a.n_bind_either_mf.mean())}
    log(f"[allele] slots={len(a)} rho={rho_a:.3f} means {a.n_bind_either_nm.mean():.2f} "
        f"vs {a.n_bind_either_mf.mean():.2f}")

    # ---------- 3. peptide level over the overlap grid ----------
    frames = []
    sset = set(samples)
    for fp in sorted(PEPDIR.glob("peptides_part_*.tsv")):
        d = pd.read_csv(fp, sep="\t", dtype=str, usecols=["SAMPLE_ID", "pep_mut"])
        d = d[d.SAMPLE_ID.isin(sset)]
        if len(d):
            frames.append(d)
    pet = pd.concat(frames, ignore_index=True).drop_duplicates(subset=["SAMPLE_ID", "pep_mut"])
    nm_b = set(zip(nm_bnd.SAMPLE_ID, nm_bnd.slot, nm_bnd.pep_mut))
    mf_b = set(zip(mf_bnd.SAMPLE_ID, mf_bnd.slot, mf_bnd.pep_mut))
    g = pet.merge(nm_slt[["SAMPLE_ID", "slot"]], on="SAMPLE_ID", how="inner")
    n_grid = len(g)
    y_nm = np.fromiter(((s, sl, p) in nm_b for s, sl, p in
                        zip(g.SAMPLE_ID.values, g.slot.values, g.pep_mut.values)),
                       dtype=bool, count=n_grid)
    y_mf = np.fromiter(((s, sl, p) in mf_b for s, sl, p in
                        zip(g.SAMPLE_ID.values, g.slot.values, g.pep_mut.values)),
                       dtype=bool, count=n_grid)
    tp = int((y_nm & y_mf).sum()); fp = int((y_nm & ~y_mf).sum())
    fn = int((~y_nm & y_mf).sum()); tn = int((~y_nm & ~y_mf).sum())
    n = tp + fp + fn + tn
    po = (tp + tn) / n
    pe = ((tp + fp) * (tp + fn) + (tn + fn) * (tn + fp)) / n ** 2
    kappa = (po - pe) / (1 - pe) if pe < 1 else np.nan
    mcc_den = np.sqrt(float((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn)))
    mcc = (tp * tn - fp * fn) / mcc_den if mcc_den > 0 else np.nan
    nm_set, mf_set = {}, {}
    for s, p in zip(nm_bnd.SAMPLE_ID, nm_bnd.pep_mut):
        nm_set.setdefault(s, set()).add(p)
    for s, p in zip(mf_bnd.SAMPLE_ID, mf_bnd.pep_mut):
        mf_set.setdefault(s, set()).add(p)
    jac_s = []
    for s in samples:
        A, B = nm_set.get(s, set()), mf_set.get(s, set())
        u = len(A | B)
        jac_s.append(len(A & B) / u if u else np.nan)
    res["peptide_level"] = {
        "n_grid": int(n), "tp": tp, "fp": fp, "fn": fn, "tn": tn,
        "pos_rate_nm": float(y_nm.mean()), "pos_rate_mf": float(y_mf.mean()),
        "overall_agreement": float(po), "cohens_kappa": float(kappa), "mcc": float(mcc),
        "precision": float(tp / (tp + fp)) if (tp + fp) else np.nan,
        "recall": float(tp / (tp + fn)) if (tp + fn) else np.nan,
        "sample_set_jaccard_median": float(np.nanmedian(jac_s)),
        "sample_set_jaccard_mean": float(np.nanmean(jac_s))}
    log(f"[peptide] grid={n} agree={po:.4f} kappa={kappa:.4f} MCC={mcc:.4f} "
        f"prec={res['peptide_level']['precision']:.3f} rec={res['peptide_level']['recall']:.3f}")

    (OUT / "consistency_summary_full.json").write_text(
        json.dumps(res, indent=2, default=str), encoding="utf-8")
    a.to_csv(OUT / "allele_level_counts_full.tsv", sep="\t", index=False)
    m.to_csv(OUT / "sample_level_counts_full.tsv", sep="\t", index=False)
    log(f"written -> {OUT}")


if __name__ == "__main__":
    main()
