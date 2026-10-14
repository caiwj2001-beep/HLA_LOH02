#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 10 (FULL cohort) -- fix the allele-paired CONDITIONAL LOGISTIC (B).

The unmodified 03_stats.py feeds statsmodels ConditionalLogit *string* group keys
on the full cohort and dies with "maximum recursion depth exceeded".  The fix
applied here:

  1. sys.setrecursionlimit(2_000_000);
  2. group keys as integer codes (0..k-1) instead of "SAMPLE|locus" strings;
  3. fit(method="bfgs", maxiter=2000) instead of the default newton/maxiter=35.

For every subset we report independent estimates of the SAME quantity (binder
load on the LOST vs the RETAINED allele):

  * condlogit_statsmodels   : statsmodels ConditionalLogit (preferred method)
  * exact_conditional_logit : exact conditional-likelihood MLE from
                              08_stats_full_extended.py (non-recursive; for a
                              single binary covariate it is the same estimator --
                              an independent implementation)
  * mantel_haenszel         : model-free stratified OR (RBG CI)

Strata universe = the sample's FULL mutated-peptide list (peptides_part_*.tsv),
exactly as 03_stats.py does; binder sets come from pred_binders_*.tsv.
Nothing in 01/02/03/08 is modified; this file only imports 08.
"""
import argparse
import importlib.util
import json
import pathlib
import sys
import time

import numpy as np
import pandas as pd

sys.setrecursionlimit(2_000_000)

HERE = pathlib.Path(__file__).resolve().parent
NEO = HERE.parent
PRED = NEO / "output" / "predictions" / "netmhcpan_full"
PEPDIR = NEO / "output" / "peptides"
OUT = NEO / "output" / "stats" / "netmhcpan_full"


def log(m):
    print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)


def _load_ext08():
    spec = importlib.util.spec_from_file_location(
        "ext08", HERE / "08_stats_full_extended.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


E08 = _load_ext08()


def build_L(pairs, binder_sets, pep_lists):
    """Peptide-level strata rows: 2 rows per peptide (is_lost=1 lost arm, 0 kept
    arm); grp = integer code per (SAMPLE_ID, locus) stratum."""
    is_lost_l, y_l, grp_l = [], [], []
    gi = -1
    for r in pairs.itertuples(index=False):
        peps = pep_lists.get(r.SAMPLE_ID)
        if not peps:
            continue
        gi += 1
        bl = binder_sets.get((r.SAMPLE_ID, r.loh_slot), set())
        bk = binder_sets.get((r.SAMPLE_ID, r.kept_slot), set())
        n = len(peps)
        is_lost_l.append(np.concatenate([np.ones(n, np.float64),
                                         np.zeros(n, np.float64)]))
        y_l.append(np.fromiter((1.0 if p in bl else 0.0 for p in peps), float, n))
        y_l.append(np.fromiter((1.0 if p in bk else 0.0 for p in peps), float, n))
        grp_l.append(np.full(2 * n, gi, dtype=np.int64))
    if not is_lost_l:
        return None
    return (np.concatenate(is_lost_l), np.concatenate(y_l), np.concatenate(grp_l))


def condlogit_sm(L, label):
    from statsmodels.discrete.conditional_models import ConditionalLogit
    is_lost, y, grp = L
    s = pd.DataFrame({"grp": grp, "y": y, "is_lost": is_lost})
    s = s[s.groupby("grp").y.transform("sum") > 0]
    s = s[s.groupby("grp").is_lost.transform("nunique") > 1]
    if s.grp.nunique() < 5:
        return None
    t1 = time.time()
    m = ConditionalLogit(s.y.values.astype(float),
                         s[["is_lost"]].values.astype(float),
                         groups=s.grp.values)
    res = m.fit(disp=0, method="bfgs", maxiter=2000)
    coef, se = float(res.params[0]), float(res.bse[0])
    try:
        conv = bool(res.mle_retvals.get("converged", False))
    except Exception:
        conv = bool(getattr(res, "converged", True))
    out = {"test": label, "test_type": "condlogit_statsmodels",
           "n_strata": int(s.grp.nunique()), "n_rows": int(len(s)),
           "OR_lost_vs_kept": float(np.exp(coef)),
           "ci_lo": float(np.exp(coef - 1.96 * se)),
           "ci_hi": float(np.exp(coef + 1.96 * se)),
           "P": float(res.pvalues[0]),
           "converged": conv,
           "fit_seconds": round(time.time() - t1, 1)}
    log(f"(B-sm) {label}: strata={out['n_strata']} rows={out['n_rows']} "
        f"OR={out['OR_lost_vs_kept']:.4f} ({out['ci_lo']:.4f}-{out['ci_hi']:.4f}) "
        f"P={out['P']:.4g} conv={out['converged']} {out['fit_seconds']}s")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sm", default="all_loci",
                    help="comma list of subsets to fit with statsmodels "
                         "ConditionalLogit (others use exact+MH only)")
    args = ap.parse_args()
    sm_subsets = {x.strip() for x in args.sm.split(",") if x.strip()}
    t0 = time.time()

    df = pd.read_csv(OUT / "analysis_frame.tsv", sep="\t", dtype=str)
    for c in ["n_pep", "n_neo_either", "any_LOH", "FACETS_PURITY", "frac_all",
              "log10TMB"]:
        df[c] = pd.to_numeric(df[c], errors="coerce")
    slt = pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                     for f in sorted(PRED.glob("pred_slots_*.tsv"))], ignore_index=True)
    bnd = pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                     for f in sorted(PRED.glob("pred_binders_*.tsv"))], ignore_index=True)
    log(f"loaded {len(df)} samples, {len(slt)} slots, {len(bnd)} binder rows")

    frames = [pd.read_csv(fp, sep="\t", dtype=str,
                          usecols=["SAMPLE_ID", "pep_mut", "is_CLONAL"])
              for fp in sorted(PEPDIR.glob("peptides_part_*.tsv"))]
    pp = pd.concat(frames, ignore_index=True)
    pep_lists = pp.groupby("SAMPLE_ID").pep_mut.apply(list).to_dict()
    log(f"peptide universe: {len(pep_lists)} samples, "
        f"{pp.pep_mut.nunique()} distinct peptides")

    bnd["is_CLONAL"] = bnd.is_CLONAL.astype(str)
    bs_all, bs_cl = {}, {}
    for sid, slot, pep, cl in zip(bnd.SAMPLE_ID.values, bnd.slot.values,
                                  bnd.pep_mut.values, bnd.is_CLONAL.values):
        bs_all.setdefault((sid, slot), set()).add(pep)
        if cl == "CLONAL":
            bs_cl.setdefault((sid, slot), set()).add(pep)

    pairs, diag = E08.build_pairs(df, slt)
    log(f"(B) pairing diagnostics: {json.dumps(diag)}")

    slot_cl = (bnd[bnd.is_CLONAL == "CLONAL"].groupby(["SAMPLE_ID", "slot"])
               .pep_mut.nunique().rename("n_bind_cl").reset_index())
    sltc = slt.drop(columns=["n_bind_either"]).merge(
        slot_cl, on=["SAMPLE_ID", "slot"], how="left")
    sltc["n_bind_either"] = sltc.n_bind_cl.fillna(0)
    pairs_cl, _ = E08.build_pairs(df, sltc)
    pairs_50, _ = E08.build_pairs(df[df.FACETS_PURITY >= 0.5], slt)

    jobs = [("all_loci", pairs, bs_all),
            ("locus_A", pairs[pairs.locus == "A"], bs_all),
            ("locus_B", pairs[pairs.locus == "B"], bs_all),
            ("locus_C", pairs[pairs.locus == "C"], bs_all),
            ("sens_purity_ge50", pairs_50, bs_all),
            ("sens_clonal_only", pairs_cl, bs_cl)]

    tsv = OUT / "extended_B_conditional_logit.tsv"
    rows = []

    def flush():
        pd.DataFrame(rows).to_csv(tsv, sep="\t", index=False)

    for label, ppairs, bs in jobs:
        if len(ppairs) == 0:
            continue
        log(f"--- {label}: {len(ppairs)} pairs ---")
        # fast exact path first so partial results always persist
        ex = E08.exact_cond_logit(ppairs.n_bind_lost.values,
                                  ppairs.n_bind_kept.values,
                                  ppairs.n_pep.values, label)
        if ex:
            rows.append(ex)
        mh = E08.mantel_haenszel(ppairs.n_bind_lost.values,
                                 ppairs.n_bind_kept.values,
                                 ppairs.n_pep.values, label)
        if mh:
            rows.append(mh)
        flush()
        if label in sm_subsets:
            L = build_L(ppairs, bs, pep_lists)
            if L is not None:
                sm = condlogit_sm(L, label)
                if sm:
                    rows.append(sm)
                    flush()

    (OUT / "extended_B_conditional_logit.json").write_text(
        json.dumps({"diagnostics": diag, "sm_subsets": sorted(sm_subsets),
                    "rows": rows}, indent=2, default=str), encoding="utf-8")
    log(f"stage10 done in {time.time()-t0:.1f}s -> {OUT}")


if __name__ == "__main__":
    main()
