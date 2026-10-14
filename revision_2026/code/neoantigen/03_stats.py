#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Stage 3: statistics on the MHCflurry neoantigen predictions.

(A) R3 literal request  : logistic  any_HLA_LOH ~ z(neoantigen burden)
                          + log10(TMB) + aneuploidy_frac + CANCER_TYPE
                          + purity (+ gene panel)
    plus Spearman(neoantigen count, TMB) as the collinearity diagnostic.
(B) allele-paired test  : for every HLA-LOH sample and every heterozygous lost
    locus, binder load of the LOST allele vs the RETAINED allele
    -> sign test, Wilcoxon signed-rank (locus level and sample level) and a
       strata = sample|locus conditional logistic on peptide-level binding.
(C) sensitivity         : FACETS purity >= 50 % ; CLONAL mutations only.

Usage:
  python 03_stats.py --tag pilot
"""
import argparse
import json
import pathlib
import time

import numpy as np
import pandas as pd
from scipy import stats as st

HERE = pathlib.Path(__file__).resolve().parent
NEO = HERE.parent
PROJ = NEO.parent

PRED_ROOT = NEO / "output" / "predictions"
PEPDIR = NEO / "output" / "peptides"
MASTER = PROJ / "V6" / "04_processed_data" / "master_cohort.tsv"
ANEU = PROJ / "iscience投稿版本" / "V2" / "r3p3_aneuploidy_scores.tsv"


def log(m):
    print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)


def load_pred(tag):
    d = PRED_ROOT / tag
    smp = pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                     for f in sorted(d.glob("pred_samples_*.tsv"))],
                    ignore_index=True)
    slt = pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                     for f in sorted(d.glob("pred_slots_*.tsv"))],
                    ignore_index=True)
    bnd = pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                     for f in sorted(d.glob("pred_binders_*.tsv"))],
                    ignore_index=True)
    log(f"loaded tag={tag}: samples={len(smp)}, slots={len(slt)}, "
        f"binders={len(bnd)}")
    return smp, slt, bnd


def load_pep_sets():
    """sample -> list of peptide strings, and sample -> set of clonal peptides"""
    frames = []
    for fp in sorted(PEPDIR.glob("peptides_part_*.tsv")):
        frames.append(pd.read_csv(fp, sep="\t", dtype=str,
                                  usecols=["SAMPLE_ID", "pep_mut", "is_CLONAL"]))
    p = pd.concat(frames, ignore_index=True)
    allp = p.groupby("SAMPLE_ID").pep_mut.unique().apply(list).to_dict()
    clon = (p[p.is_CLONAL == "CLONAL"].groupby("SAMPLE_ID").pep_mut
            .unique().apply(set).to_dict())
    log(f"peptide sets loaded: {len(allp)} samples, "
        f"{len(clon)} with >=1 clonal peptide")
    return allp, clon


def logistic(df, ycol, xcols, extra=None):
    import statsmodels.formula.api as smf
    d = df.dropna(subset=[ycol] + list(xcols)).copy()
    d[ycol] = d[ycol].astype(float)
    for c in xcols:
        d[c] = d[c].astype(float)
    formula = f"{ycol} ~ " + " + ".join(xcols)
    if extra:
        formula += " + " + " + ".join(extra)
    res = smf.logit(formula, data=d).fit(disp=0)
    return res, d, formula


def build_pairs(smp_df, slt_df):
    """Return (pairs_df, diagnostics). smp_df needs SAMPLE_ID + any_LOH."""
    loh_ids = set(smp_df[smp_df.any_LOH == 1].SAMPLE_ID)
    s = slt_df[slt_df.SAMPLE_ID.isin(loh_ids)].copy()
    s["is_hom"] = s.is_hom.astype(str).str.lower() == "true"
    s["n_bind"] = pd.to_numeric(s.n_bind_either, errors="coerce")
    s["n_pepv"] = pd.to_numeric(s.n_pep, errors="coerce")
    diag = {"loh_samples_considered": len(loh_ids),
            "homozygous_loci_excluded": 0, "loci_missing_slot": 0,
            "loci_no_loh_call": 0, "loci_both_lost": 0, "loci_no_loss": 0,
            "loci_paired": 0, "samples_with_pair": 0}
    pairs = []
    for (sid, locus), g in s.groupby(["SAMPLE_ID", "locus"], sort=False):
        g = g.set_index("slot")
        if len(g) != 2:
            diag["loci_missing_slot"] += 1
            continue
        s1, s2 = list(g.index)[0], list(g.index)[1]
        r1, r2 = g.loc[s1], g.loc[s2]
        if bool(r1.is_hom) or bool(r2.is_hom):
            diag["homozygous_loci_excluded"] += 1
            continue
        l1 = str(r1.loh).strip().lower()
        l2 = str(r2.loh).strip().lower()
        if l1 not in ("loss", "unchanged") or l2 not in ("loss", "unchanged"):
            diag["loci_no_loh_call"] += 1
            continue
        if l1 == "loss" and l2 == "loss":
            diag["loci_both_lost"] += 1
            continue
        if l1 == "unchanged" and l2 == "unchanged":
            diag["loci_no_loss"] += 1
            continue
        lost = s1 if l1 == "loss" else s2
        kept = s2 if l1 == "loss" else s1
        pairs.append({"SAMPLE_ID": sid, "locus": locus,
                      "loh_slot": lost, "kept_slot": kept,
                      "loh_allele": g.loc[lost, "allele"],
                      "kept_allele": g.loc[kept, "allele"],
                      "n_pep": float(g.loc[lost, "n_pepv"]),
                      "n_bind_lost": float(g.loc[lost, "n_bind"]),
                      "n_bind_kept": float(g.loc[kept, "n_bind"]),
                      "d_bind": float(g.loc[lost, "n_bind"]) -
                                float(g.loc[kept, "n_bind"])})
        diag["loci_paired"] += 1
    pairs = pd.DataFrame(pairs)
    diag["samples_with_pair"] = int(pairs.SAMPLE_ID.nunique()) if len(pairs) else 0
    return pairs, diag


def paired_tests(pairs, label, out_rows):
    if len(pairs) == 0:
        return None
    pos = int((pairs.d_bind > 0).sum())
    neg = int((pairs.d_bind < 0).sum())
    tie = int((pairs.d_bind == 0).sum())
    bt = st.binomtest(pos, pos + neg, 0.5) if (pos + neg) > 0 else None
    w = (st.wilcoxon(pairs.n_bind_lost, pairs.n_bind_kept, zero_method="wilcox")
         if (pairs.d_bind != 0).any() else None)
    tot = pairs.groupby("SAMPLE_ID")[["n_bind_lost", "n_bind_kept"]].sum()
    tot["d"] = tot.n_bind_lost - tot.n_bind_kept
    frac_more = float((tot.d > 0).mean())
    w2 = (st.wilcoxon(tot.n_bind_lost, tot.n_bind_kept, zero_method="wilcox")
          if (tot.d != 0).any() else None)
    rec = {"test": label, "test_type": "paired_loci",
           "n_locus_pairs": int(len(pairs)),
           "n_samples": int(pairs.SAMPLE_ID.nunique()),
           "lost_gt_kept": pos, "lost_lt_kept": neg, "ties": tie,
           "sign_test_P": float(bt.pvalue) if bt else np.nan,
           "wilcoxon_P": float(w.pvalue) if w else np.nan,
           "wilcoxon_stat": float(w.statistic) if w else np.nan,
           "median_bind_lost": float(pairs.n_bind_lost.median()),
           "median_bind_kept": float(pairs.n_bind_kept.median()),
           "mean_bind_lost": round(float(pairs.n_bind_lost.mean()), 4),
           "mean_bind_kept": round(float(pairs.n_bind_kept.mean()), 4),
           "frac_samples_lost_more": frac_more,
           "sample_level_wilcoxon_P": float(w2.pvalue) if w2 else np.nan}
    out_rows.append(rec)
    log(f"(B) {label}: pairs={len(pairs)} samples={rec['n_samples']} | "
        f"lost>kept {pos} / lost<kept {neg} (ties {tie}) | "
        f"sign P={rec['sign_test_P']:.3g} | Wilcoxon P={rec['wilcoxon_P']:.3g} | "
        f"frac samples lost-more={frac_more:.3f} | sample-level Wilcoxon "
        f"P={rec['sample_level_wilcoxon_P']:.3g}")
    return rec


def conditional_logit(pairs, binder_sets, pep_lists, label):
    """strata = SAMPLE_ID|locus; event = peptide is a predicted binder;
    covariate = is_lost.  All of the sample's peptides enter as controls."""
    try:
        from statsmodels.discrete.conditional_models import ConditionalLogit
    except Exception as e:                                   # pragma: no cover
        log(f"conditional logit unavailable: {e}")
        return None
    rows, strata = [], []
    for r in pairs.itertuples(index=False):
        peps = pep_lists.get(r.SAMPLE_ID)
        if not peps:
            continue
        bl = binder_sets.get((r.SAMPLE_ID, r.loh_slot), set())
        bk = binder_sets.get((r.SAMPLE_ID, r.kept_slot), set())
        key = f"{r.SAMPLE_ID}|{r.locus}"
        for p in peps:
            rows.append((1, p in bl))
            rows.append((0, p in bk))
            strata.append(key)
            strata.append(key)
    L = pd.DataFrame(rows, columns=["is_lost", "y"])
    L["grp"] = strata
    L = L[L.groupby("grp").y.transform("sum") > 0]      # informative strata only
    if len(L) == 0:
        log(f"(B-condlogit) {label}: no informative strata")
        return None
    disc = L[L.y == 1].groupby(["grp", "is_lost"]).size().unstack(fill_value=0)
    d_lo = int((disc[1] > disc[0]).sum()) if (1 in disc.columns and 0 in disc.columns) else 0
    d_ke = int((disc[0] > disc[1]).sum()) if (1 in disc.columns and 0 in disc.columns) else 0
    try:
        m = ConditionalLogit(L.y.values, L[["is_lost"]].values.astype(float),
                             groups=L.grp.values)
        res = m.fit(disp=0)
        coef, se = float(res.params[0]), float(res.bse[0])
        rec = {"test": label, "test_type": "conditional_logit",
               "n_strata": int(L.grp.nunique()), "n_rows": int(len(L)),
               "OR_lost_vs_kept": float(np.exp(coef)),
               "ci_lo": float(np.exp(coef - 1.96 * se)),
               "ci_hi": float(np.exp(coef + 1.96 * se)),
               "P": float(res.pvalues[0]),
               "discordant_lost_only": d_lo, "discordant_kept_only": d_ke}
        log(f"(B-condlogit) {label}: strata={rec['n_strata']} "
            f"OR={rec['OR_lost_vs_kept']:.3f} "
            f"({rec['ci_lo']:.3f}-{rec['ci_hi']:.3f}) P={rec['P']:.3g} | "
            f"discordant lost-only {d_lo} vs kept-only {d_ke}")
        return rec
    except Exception as e:
        log(f"conditional logit failed ({label}): {e}")
        return None


def binder_sets_from(bnd):
    bs = {}
    for sid, slot, pep in zip(bnd.SAMPLE_ID.values, bnd.slot.values,
                              bnd.pep_mut.values):
        bs.setdefault((sid, slot), set()).add(pep)
    return bs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="pilot")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    out = (pathlib.Path(args.out) if args.out
           else NEO / "output" / "stats" / args.tag)
    out.mkdir(parents=True, exist_ok=True)

    smp, slt, bnd = load_pred(args.tag)
    pep_lists, clon_sets = load_pep_sets()
    mc = pd.read_csv(MASTER, sep="\t", dtype=str, low_memory=False)
    mc = mc[["SAMPLE_ID", "CANCER_TYPE", "any_HLA_LOH", "HLA_LOH_burden",
             "TMB_SCORE", "log_TMB", "FACETS_PURITY", "FACETS_PLOIDY",
             "FACETS_WGD", "GENE_PANEL", "SAMPLE_TYPE"]]
    an = pd.read_csv(ANEU, sep="\t", dtype=str)[["SAMPLE_ID", "frac_all", "frac_ex6"]]

    df = smp.merge(mc, on="SAMPLE_ID", how="left", suffixes=("", "_mc"))
    df = df.merge(an, on="SAMPLE_ID", how="left")
    for c in ["n_pep", "n_neo_ic50", "n_neo_pct", "n_neo_either", "n_mut_coding",
              "TMB_SCORE", "FACETS_PURITY", "FACETS_PLOIDY", "frac_all",
              "frac_ex6", "HLA_LOH_burden"]:
        df[c] = pd.to_numeric(df[c], errors="coerce")
    df["any_LOH"] = (df.any_HLA_LOH == "TRUE").astype(int)
    df["log10TMB"] = np.log10(df.TMB_SCORE.clip(lower=0) + 0.01)
    df["panel_mb"] = df.n_mut_coding / df.TMB_SCORE.replace(0, np.nan)
    df["neo_per_Mb"] = (df.n_neo_either * df.TMB_SCORE /
                        df.n_mut_coding.replace(0, np.nan))
    df["neo_per_mut"] = df.n_neo_either / df.n_mut_coding.replace(0, np.nan)

    log(f"analysis frame: {len(df)} samples, LOH+={int(df.any_LOH.sum())}, "
        f"controls={int((1 - df.any_LOH).sum())}")
    log(f"implied panel size (median) = {df.panel_mb.median():.3f} Mb "
        f"[IQR {df.panel_mb.quantile(.25):.2f}-{df.panel_mb.quantile(.75):.2f}]")
    df.to_csv(out / "analysis_frame.tsv", sep="\t", index=False)

    # ---------------- (A) logistic ----------------
    A_rows = []
    for label, xcol, extra in [
            ("neo_count", "n_neo_either", True),
            ("neo_count_ic50_def", "n_neo_ic50", True),
            ("neo_per_Mb", "neo_per_Mb", True),
            ("neo_per_mut", "neo_per_mut", True),
            ("neo_count_no_panel_term", "n_neo_either", False)]:
        d = df[df[xcol].notna()].copy()
        d["Z"] = (d[xcol] - d[xcol].mean()) / d[xcol].std()
        cols = ["Z", "log10TMB", "frac_all", "FACETS_PURITY"]
        ex = ["C(CANCER_TYPE)", "C(GENE_PANEL)"] if extra else ["C(CANCER_TYPE)"]
        try:
            res, dd, formula = logistic(d, "any_LOH", cols, extra=ex)
        except Exception as e:
            log(f"(A) {label} failed: {e}")
            continue
        ci = res.conf_int()
        rec = {"model": label, "n": int(res.nobs),
               "n_LOH": int(dd.any_LOH.sum()), "formula": formula,
               "OR_per_SD": float(np.exp(res.params["Z"])),
               "ci_lo": float(np.exp(ci.loc["Z", 0])),
               "ci_hi": float(np.exp(ci.loc["Z", 1])),
               "P": float(res.pvalues["Z"]),
               "OR_log10TMB": float(np.exp(res.params["log10TMB"])),
               "P_log10TMB": float(res.pvalues["log10TMB"]),
               "OR_aneuploidy": float(np.exp(res.params["frac_all"])),
               "P_aneuploidy": float(res.pvalues["frac_all"]),
               "OR_purity": float(np.exp(res.params["FACETS_PURITY"])),
               "P_purity": float(res.pvalues["FACETS_PURITY"])}
        A_rows.append(rec)
        log(f"(A) {label}: n={rec['n']} LOH+={rec['n_LOH']} "
            f"OR/SD={rec['OR_per_SD']:.3f} ({rec['ci_lo']:.3f}-{rec['ci_hi']:.3f})"
            f" P={rec['P']:.3g} | TMB OR={rec['OR_log10TMB']:.3f} | "
            f"aneuploidy OR={rec['OR_aneuploidy']:.3f}")
    A = pd.DataFrame(A_rows)
    A.to_csv(out / "A_logistic.tsv", sep="\t", index=False)

    cc = []
    for a, b in [("n_neo_either", "TMB_SCORE"), ("n_neo_either", "n_mut_coding"),
                 ("n_neo_pct", "TMB_SCORE"), ("n_pep", "n_mut_coding"),
                 ("n_pep", "TMB_SCORE"), ("neo_per_Mb", "TMB_SCORE")]:
        s = df[[a, b]].dropna()
        rho, p = st.spearmanr(s[a], s[b])
        cc.append({"x": a, "y": b, "n": len(s), "spearman_rho": float(rho),
                   "P": float(p)})
    CC = pd.DataFrame(cc)
    CC.to_csv(out / "A_collinearity.tsv", sep="\t", index=False)
    for _, r in CC.iterrows():
        log(f"(A-collinearity) {r.x} ~ {r.y}: rho={r.spearman_rho:.3f} "
            f"(n={r.n}, P={r.P:.3g})")

    # complementary direction: neoantigen burden as the OUTCOME
    A2_rows = []
    try:
        import statsmodels.formula.api as smf
        d = df.dropna(subset=["n_neo_either", "log10TMB", "frac_all",
                              "FACETS_PURITY", "any_LOH"]).copy()
        d["log1p_neo"] = np.log1p(d.n_neo_either)
        m = smf.ols("log1p_neo ~ any_LOH + log10TMB + frac_all + "
                    "FACETS_PURITY + C(CANCER_TYPE)", data=d).fit()
        ci = m.conf_int()
        A2_rows.append({"model": "ols_log1p_neo", "n": int(m.nobs),
                        "effect_mult": float(np.exp(m.params["any_LOH"])),
                        "ci_lo": float(np.exp(ci.loc["any_LOH", 0])),
                        "ci_hi": float(np.exp(ci.loc["any_LOH", 1])),
                        "P": float(m.pvalues["any_LOH"])})
        m2 = smf.ols("log1p_neo ~ any_LOH + log10TMB + frac_all + "
                     "FACETS_PURITY + C(CANCER_TYPE)", data=d).fit(
                     cov_type="HC3")
        log(f"(A2) OLS log1p(neo) ~ LOH: ratio={A2_rows[-1]['effect_mult']:.3f} "
            f"({A2_rows[-1]['ci_lo']:.3f}-{A2_rows[-1]['ci_hi']:.3f}) "
            f"P={A2_rows[-1]['P']:.3g} [HC3 P={float(m2.pvalues['any_LOH']):.3g}]")
        # unadjusted medians
        med = d.groupby("any_LOH").n_neo_either.median()
        A2_rows.append({"model": "median_neo_by_LOH", "n": int(len(d)),
                        "neo_median_LOH0": float(med.get(0, np.nan)),
                        "neo_median_LOH1": float(med.get(1, np.nan))})
        log(f"(A2) median neoantigens: LOH-={med.get(0):.1f} vs "
            f"LOH+={med.get(1):.1f}")
    except Exception as e:
        log(f"(A2) failed: {e}")
    pd.DataFrame(A2_rows).to_csv(out / "A2_outcome_models.tsv", sep="\t",
                                 index=False)

    # ---------------- (B) allele-paired ----------------
    bs_all = binder_sets_from(bnd)
    B_rows = []
    pairs, diag = build_pairs(df, slt)
    log(f"(B) pairing diagnostics: {json.dumps(diag)}")
    if len(pairs):
        pairs.to_csv(out / "B_pairs.tsv", sep="\t", index=False)
        paired_tests(pairs, "all_loci", B_rows)
        r = conditional_logit(pairs, bs_all, pep_lists, "all_loci")
        if r:
            B_rows.append(r)
        for loc in ["A", "B", "C"]:
            p = pairs[pairs.locus == loc]
            if len(p):
                paired_tests(p, f"locus_{loc}", B_rows)
                r2 = conditional_logit(p, bs_all, pep_lists, f"locus_{loc}")
                if r2:
                    B_rows.append(r2)
        tot = pairs.groupby("SAMPLE_ID")[["n_bind_lost", "n_bind_kept"]].sum()
        n_more = int((tot.n_bind_lost > tot.n_bind_kept).sum())
        n_less = int((tot.n_bind_lost < tot.n_bind_kept).sum())
        n_eq = int((tot.n_bind_lost == tot.n_bind_kept).sum())
        (out / "B_sample_level_fraction.json").write_text(json.dumps(
            {"n_samples_with_pair": int(len(tot)), "lost_more": n_more,
             "kept_more": n_less, "equal": n_eq,
             "frac_lost_more": n_more / len(tot)}, indent=1), encoding="utf-8")
        log(f"(B) sample level: lost-more {n_more} / kept-more {n_less} / "
            f"equal {n_eq} -> frac_lost_more={n_more/len(tot):.3f}")
    else:
        (out / "B_sample_level_fraction.json").write_text("{}", encoding="utf-8")
    B = pd.DataFrame(B_rows)
    B.to_csv(out / "B_allele_tests.tsv", sep="\t", index=False)
    (out / "B_pairing_diagnostics.json").write_text(json.dumps(diag, indent=1),
                                                   encoding="utf-8")

    # ---------------- (C) sensitivity ----------------
    C_rows = []
    sub50 = df[df.FACETS_PURITY >= 0.5].copy()
    if len(sub50) >= 30:
        sub50["Z"] = ((sub50.n_neo_either - sub50.n_neo_either.mean()) /
                      sub50.n_neo_either.std())
        try:
            res, dd, _ = logistic(sub50, "any_LOH",
                                  ["Z", "log10TMB", "frac_all", "FACETS_PURITY"],
                                  extra=["C(CANCER_TYPE)"])
            ci = res.conf_int()
            C_rows.append({"test": "sens_purity_ge50", "test_type": "logistic",
                           "n": int(res.nobs), "n_LOH": int(dd.any_LOH.sum()),
                           "OR_per_SD_neo": float(np.exp(res.params["Z"])),
                           "ci_lo": float(np.exp(ci.loc["Z", 0])),
                           "ci_hi": float(np.exp(ci.loc["Z", 1])),
                           "P": float(res.pvalues["Z"])})
            log(f"(C) purity>=50 logistic: n={int(res.nobs)} "
                f"OR={float(np.exp(res.params['Z'])):.3f} "
                f"P={float(res.pvalues['Z']):.3g}")
        except Exception as e:
            log(f"(C) purity>=50 logistic failed: {e}")
        p50, d50 = build_pairs(sub50, slt)
        if len(p50):
            paired_tests(p50, "sens_purity_ge50", C_rows)
            r = conditional_logit(p50, bs_all, pep_lists, "sens_purity_ge50")
            if r:
                C_rows.append(r)

    bcl = bnd[bnd.is_CLONAL.astype(str) == "CLONAL"]
    bs_cl = binder_sets_from(bcl)
    nc = bcl.groupby("SAMPLE_ID").pep_mut.nunique().rename("n_neo_clonal")
    dfc = df.merge(nc, on="SAMPLE_ID", how="left")
    dfc["n_neo_clonal"] = dfc.n_neo_clonal.fillna(0)
    dfc["n_pep_clonal"] = dfc.SAMPLE_ID.map(lambda s: len(clon_sets.get(s, [])))
    try:
        d = dfc[dfc.n_pep_clonal >= 1].copy()
        if len(d) >= 30:
            d["Z"] = (d.n_neo_clonal - d.n_neo_clonal.mean()) / d.n_neo_clonal.std()
            res, dd, _ = logistic(d, "any_LOH",
                                  ["Z", "log10TMB", "frac_all", "FACETS_PURITY"],
                                  extra=["C(CANCER_TYPE)"])
            ci = res.conf_int()
            C_rows.append({"test": "sens_clonal_only", "test_type": "logistic",
                           "n": int(res.nobs), "n_LOH": int(dd.any_LOH.sum()),
                           "OR_per_SD_neo": float(np.exp(res.params["Z"])),
                           "ci_lo": float(np.exp(ci.loc["Z", 0])),
                           "ci_hi": float(np.exp(ci.loc["Z", 1])),
                           "P": float(res.pvalues["Z"])})
            log(f"(C) clonal-only logistic: n={int(res.nobs)} "
                f"OR={float(np.exp(res.params['Z'])):.3f} "
                f"P={float(res.pvalues['Z']):.3g}")
    except Exception as e:
        log(f"(C) clonal-only logistic failed: {e}")
    pcl, dcl = build_pairs(df, slt)
    if len(pcl):
        # rebuild the slot table with CLONAL-only binder counts so the
        # sign / Wilcoxon tests are restricted to clonal mutations too
        slot_cl = (bcl.groupby(["SAMPLE_ID", "slot"]).pep_mut.nunique()
                   .rename("n_bind_cl").reset_index())
        sltc = slt.drop(columns=["n_bind_either"]).merge(
            slot_cl, on=["SAMPLE_ID", "slot"], how="left")
        sltc["n_bind_either"] = sltc.n_bind_cl.fillna(0)
        pcl, dcl = build_pairs(df, sltc)
        paired_tests(pcl, "sens_clonal_only", C_rows)
        r = conditional_logit(pcl, bs_cl, clon_sets, "sens_clonal_only")
        if r:
            C_rows.append(r)
        pcl.to_csv(out / "C_pairs_clonal_only.tsv", sep="\t", index=False)
    C = pd.DataFrame(C_rows)
    C.to_csv(out / "C_sensitivity.tsv", sep="\t", index=False)

    summary = {"tag": args.tag, "n_samples": int(len(df)),
               "n_LOH": int(df.any_LOH.sum()),
               "A_logistic": A.to_dict("records"),
               "A_collinearity": CC.to_dict("records"),
               "B_diagnostics": diag, "B_tests": B_rows,
               "C_sensitivity": C_rows}
    (out / "stats_summary.json").write_text(
        json.dumps(summary, indent=2, default=str), encoding="utf-8")
    log(f"stats written to {out}")


if __name__ == "__main__":
    main()
