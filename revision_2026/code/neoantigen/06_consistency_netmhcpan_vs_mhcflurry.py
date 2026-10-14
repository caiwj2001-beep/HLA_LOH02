#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Stage 6: INTERNAL consistency check, netMHCpan-4.2e vs MHCflurry, on the pilot.

!!! INTERNAL USE ONLY !!!
The DTU licence for NetMHCpan forbids publishing benchmark/comparison results
against other predictors.  This output is a private sanity/QA artefact and must
NOT be reported as a tool-vs-tool benchmark in any manuscript.  Every number
that goes into the paper comes from the netMHCpan arm alone.

Metrics
  * sample level   : Spearman rho of neoantigen counts, median/IQR of both arms,
                     Jaccard of the per-sample binder sets
  * allele level   : Spearman rho of per-(sample,slot) binder counts
  * peptide level  : 2x2 concordance of "is a binder for this allele" over the
                     full (sample x allele x mutant peptide) grid -> agreement,
                     Cohen's kappa, MCC
  * continuous     : Spearman of %Rank_EL vs mhcflurry affinity_percentile
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
OUT = PRED / "netmhcpan_pilot" / "consistency"
PCT_THR = 2.0
IC50_THR = 500.0


def log(m):
    print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)


def load(tag, fn):
    d = PRED / tag
    return pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                      for f in sorted(d.glob(fn))], ignore_index=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    man = json.loads((PRED / "pilot" / "manifest.json").read_text())
    samples = [s for b in man["batches"] for s in b]

    nm_smp = load("netmhcpan_pilot", "pred_samples_*.tsv")
    nm_slt = load("netmhcpan_pilot", "pred_slots_*.tsv")
    nm_bnd = load("netmhcpan_pilot", "pred_binders_*.tsv")
    mf_smp = load("pilot", "pred_samples_*.tsv")
    mf_slt = load("pilot", "pred_slots_*.tsv")
    mf_bnd = load("pilot", "pred_binders_*.tsv")

    res = {"_license_note": "INTERNAL QA ONLY - DTU licence forbids publishing "
                            "netMHCpan benchmark comparisons"}

    # ---------- 1. sample level -------------------------------------------
    m = (nm_smp[["SAMPLE_ID", "n_neo_either", "n_neo_ic50", "n_pep"]]
         .merge(mf_smp[["SAMPLE_ID", "n_neo_either", "n_neo_ic50"]],
                on="SAMPLE_ID", suffixes=("_nm", "_mf")))
    m["n_neo_either_nm"] = pd.to_numeric(m.n_neo_either_nm)
    m["n_neo_either_mf"] = pd.to_numeric(m.n_neo_either_mf)
    m["n_neo_ic50_nm"] = pd.to_numeric(m.n_neo_ic50_nm)
    m["n_neo_ic50_mf"] = pd.to_numeric(m.n_neo_ic50_mf)
    rho, p = st.spearmanr(m.n_neo_either_nm, m.n_neo_either_mf)
    rho_i, p_i = st.spearmanr(m.n_neo_ic50_nm, m.n_neo_ic50_mf)
    res["sample_level"] = {
        "n": int(len(m)),
        "spearman_rho_count": float(rho), "spearman_P": float(p),
        "spearman_rho_ic50def": float(rho_i), "spearman_P_ic50def": float(p_i),
        "median_nm": float(m.n_neo_either_nm.median()),
        "iqr_nm": [float(m.n_neo_either_nm.quantile(.25)),
                   float(m.n_neo_either_nm.quantile(.75))],
        "mean_nm": float(m.n_neo_either_nm.mean()),
        "median_mf": float(m.n_neo_either_mf.median()),
        "iqr_mf": [float(m.n_neo_either_mf.quantile(.25)),
                   float(m.n_neo_either_mf.quantile(.75))],
        "mean_mf": float(m.n_neo_either_mf.mean()),
        "mean_ratio_nm_over_mf": float(m.n_neo_either_nm.mean() /
                                       m.n_neo_either_mf.mean()),
        "pearson_r": float(st.pearsonr(m.n_neo_either_nm, m.n_neo_either_mf)[0]),
        "median_diff_nm_minus_mf": float((m.n_neo_either_nm -
                                          m.n_neo_either_mf).median()),
    }
    log(f"[sample] n={res['sample_level']['n']} "
        f"Spearman rho={rho:.3f} (P={p:.2e}) | medians "
        f"{res['sample_level']['median_nm']:.0f} (netMHCpan) vs "
        f"{res['sample_level']['median_mf']:.0f} (MHCflurry)")

    # ---------- 2. allele (sample x slot) level ---------------------------
    a = nm_slt[["SAMPLE_ID", "slot", "allele", "n_bind_either"]].merge(
        mf_slt[["SAMPLE_ID", "slot", "n_bind_either"]], on=["SAMPLE_ID", "slot"],
        suffixes=("_nm", "_mf"))
    a["n_bind_either_nm"] = pd.to_numeric(a.n_bind_either_nm)
    a["n_bind_either_mf"] = pd.to_numeric(a.n_bind_either_mf)
    rho_a, p_a = st.spearmanr(a.n_bind_either_nm, a.n_bind_either_mf)
    res["allele_level"] = {
        "n_slots": int(len(a)), "spearman_rho": float(rho_a),
        "spearman_P": float(p_a),
        "median_nm": float(a.n_bind_either_nm.median()),
        "median_mf": float(a.n_bind_either_mf.median()),
        "mean_nm": float(a.n_bind_either_nm.mean()),
        "mean_mf": float(a.n_bind_either_mf.mean()),
        "pearson_r": float(st.pearsonr(a.n_bind_either_nm,
                                       a.n_bind_either_mf)[0]),
    }
    log(f"[allele] slots={len(a)} rho={rho_a:.3f} means "
        f"{a.n_bind_either_nm.mean():.2f} vs {a.n_bind_either_mf.mean():.2f}")

    # ---------- 3. peptide level over the full grid -----------------------
    # grid = every (sample, allele, mutant peptide) that BOTH tools scored
    frames = []
    for fp in sorted(PEPDIR.glob("peptides_part_*.tsv")):
        d = pd.read_csv(fp, sep="\t", dtype=str,
                        usecols=["SAMPLE_ID", "pep_mut"])
        d = d[d.SAMPLE_ID.isin(set(samples))]
        if len(d):
            frames.append(d)
    pet = pd.concat(frames, ignore_index=True)
    pet = pet.drop_duplicates(subset=["SAMPLE_ID", "pep_mut"])
    log(f"mutant peptides over pilot samples: {len(pet)}")

    nm_b = set(zip(nm_bnd.SAMPLE_ID, nm_bnd.slot, nm_bnd.pep_mut))
    mf_b = set(zip(mf_bnd.SAMPLE_ID, mf_bnd.slot, mf_bnd.pep_mut))
    log(f"binder calls: netMHCpan={len(nm_b)}, MHCflurry={len(mf_b)}")

    g = pet.merge(nm_slt[["SAMPLE_ID", "slot"]], on="SAMPLE_ID", how="inner")
    n_grid = len(g)
    y_nm = np.fromiter(((s, sl, p) in nm_b for s, sl, p in
                        zip(g.SAMPLE_ID.values, g.slot.values,
                            g.pep_mut.values)), dtype=bool, count=n_grid)
    y_mf = np.fromiter(((s, sl, p) in mf_b for s, sl, p in
                        zip(g.SAMPLE_ID.values, g.slot.values,
                            g.pep_mut.values)), dtype=bool, count=n_grid)
    tp = int((y_nm & y_mf).sum())
    fp = int((y_nm & ~y_mf).sum())
    fn = int((~y_nm & y_mf).sum())
    tn = int((~y_nm & ~y_mf).sum())
    n = tp + fp + fn + tn
    po = (tp + tn) / n
    pe = ((tp + fp) * (tp + fn) + (tn + fn) * (tn + fp)) / n ** 2
    kappa = (po - pe) / (1 - pe) if pe < 1 else np.nan
    mcc_den = np.sqrt(float((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn)))
    mcc = (tp * tn - fp * fn) / mcc_den if mcc_den > 0 else np.nan
    prec = tp / (tp + fp) if (tp + fp) else np.nan
    rec = tp / (tp + fn) if (tp + fn) else np.nan
    jac = tp / (tp + fp + fn) if (tp + fp + fn) else np.nan
    # per-sample Jaccard of the binder SETS (union over the sample's alleles)
    nm_set = {}
    for s, p in zip(nm_bnd.SAMPLE_ID, nm_bnd.pep_mut):
        nm_set.setdefault(s, set()).add(p)
    mf_set = {}
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
        "overall_agreement": float(po), "cohens_kappa": float(kappa),
        "mcc": float(mcc), "precision": float(prec), "recall": float(rec),
        "jaccard_peptide_level": float(jac),
        "sample_set_jaccard_median": float(np.nanmedian(jac_s)),
        "sample_set_jaccard_mean": float(np.nanmean(jac_s)),
    }
    log(f"[peptide] grid={n} TP={tp} FP={fp} FN={fn} TN={tn} | "
        f"agree={po:.4f} kappa={kappa:.4f} MCC={mcc:.4f} "
        f"prec={prec:.3f} rec={rec:.3f} | set-Jaccard median="
        f"{np.nanmedian(jac_s):.3f}")

    # ---------- 4. continuous rank correlation ----------------------------
    # join on (allele, peptide) using the per-allele netMHCpan table
    pa = PRED / "netmhcpan_pilot" / "per_allele"
    nm_rows = []
    for f in sorted(pa.glob("*.tsv")):
        d = pd.read_csv(f, sep="\t", dtype=str, header=None,
                        names=["pep", "el_rank", "ba_rank", "aff", "allele"])
        nm_rows.append(d[["allele", "pep", "el_rank"]])
    nmc = pd.concat(nm_rows, ignore_index=True)
    nmc["el_rank"] = pd.to_numeric(nmc.el_rank, errors="coerce")
    mfc = mf_bnd[["allele", "pep_mut", "affinity_percentile"]].rename(
        columns={"pep_mut": "pep"})
    # netMHCpan writes HLA-A02:01, MHCflurry writes HLA-A*02:01 -> normalise
    mfc["allele"] = mfc.allele.astype(str).str.replace("*", "", regex=False)
    mfc["affinity_percentile"] = pd.to_numeric(mfc.affinity_percentile,
                                              errors="coerce")
    # mhcflurry binder table only holds binders; add the non-binder peptide calls
    # is not needed for a rank correlation on the bound fraction, so restrict to
    # the peptides that BOTH tools scored as binders for the same allele
    j = nmc.merge(mfc.drop_duplicates(subset=["allele", "pep"]),
                  on=["allele", "pep"], how="inner")
    if len(j) > 100:
        r_c, p_c = st.spearmanr(j.el_rank, j.affinity_percentile)
        r_p = st.pearsonr(j.el_rank, j.affinity_percentile)
        res["continuous"] = {
            "n_pairs": int(len(j)), "spearman_rho_ELrank_vs_mhcflurry_pct":
            float(r_c), "spearman_P": float(p_c),
            "pearson_r": float(r_p[0]),
            "median_el_rank": float(j.el_rank.median()),
            "median_mf_pct": float(j.affinity_percentile.median())}
        log(f"[continuous] n={len(j)} Spearman(EL_rank, mhcflurry_pct)="
            f"{r_c:.3f}")

    (OUT / "consistency_summary.json").write_text(
        json.dumps(res, indent=2, default=str), encoding="utf-8")
    a.to_csv(OUT / "allele_level_counts.tsv", sep="\t", index=False)
    m.to_csv(OUT / "sample_level_counts.tsv", sep="\t", index=False)
    log(f"written -> {OUT}")


if __name__ == "__main__":
    main()
