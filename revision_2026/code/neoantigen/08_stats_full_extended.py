#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Stage 8 (FULL cohort, extended/diagnostic): addresses the four issues that block the
full-cohort numbers from being publication-ready.

  (1) The unmodified 03_stats.py fails the allele-paired CONDITIONAL LOGISTIC on the
      full cohort -- statsmodels ConditionalLogit uses a Python recursion whose depth
      equals the stratum size (up to 2*n_pep ~ 2.6k peptides), so it raises
      "maximum recursion depth exceeded".  Here we compute the SAME conditional
      likelihood exactly and non-recursively:
          L_i(b) = exp(b*a_i) / sum_j C(n_i,j) C(n_i,n1_i-j) exp(b*j)
      with n_i = n_pep peptides per arm, n1_i = #binders in the stratum, a_i = #binders
      on the LOST arm.  The sum over j runs to n1_i (small), so it is O(n1_i) per
      stratum -- exact, fast, no recursion.  Reported: OR = exp(b_hat), Wald & LRT P.
      As an independent, model-free cross-check we also report the MANTEL-HAENSZEL
      pooled OR with the Robins-Breslow-Greenland CI.

  (2) The (A) logistic models warn "MLE failed to converge" (statsmodels default
      maxiter=35 with ~67 parameters).  Here every (A) model is refitted with
      maxiter=1000 and with Firth (Jeffreys-prior penalised) likelihood, and robust
      HC3 standard errors are reported alongside the model-based ones.

  (3) (C) sensitivity: FACETS purity >= 50 %, CLONAL mutations only, and the
      arm-dependent "6p arm loss" subset; plus (A) re-run within aneuploidy tertiles.

  (4) Everything written to output/stats/netmhcpan_full/ (extended_*).

03_stats.py is NOT modified; this is the equivalent reproduction script.
"""
import argparse
import json
import pathlib
import time

import numpy as np
import pandas as pd
from scipy import stats as st
from scipy.optimize import minimize_scalar
from scipy.special import expit, gammaln, logsumexp

HERE = pathlib.Path(__file__).resolve().parent
NEO = HERE.parent
PROJ = NEO.parent
PRED = NEO / "output" / "predictions"
MASTER = PROJ / "V6" / "04_processed_data" / "master_cohort.tsv"
PEPDIR = NEO / "output" / "peptides"


def log(m):
    print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)


# ---------------------------------------------------------------- exact conditional
def exact_cond_logit(n_lost, n_kept, n_pep, label=""):
    """Exact conditional-likelihood MLE for one binary covariate (is_lost).

    Each stratum i contributes a 2 x n_i table (n_i peptides per arm).  With
    x=1 on the lost arm and x=0 on the kept arm the conditional denominator given
    n1_i binders in the stratum is  sum_j C(n,j) C(n,n1-j) exp(b j).
    """
    n = np.asarray(n_pep, dtype=np.int64)
    a = np.asarray(n_lost, dtype=np.int64)
    n1 = (np.asarray(n_lost) + np.asarray(n_kept)).astype(np.int64)
    keep = n1 > 0                      # strata with no binders are uninformative
    n, a, n1 = n[keep], a[keep], n1[keep]
    ns = len(n)
    if ns == 0:
        return None
    # precompute (js, log C(n,j)+log C(n,n1-j)) per stratum -- independent of beta
    pre = []
    for i in range(ns):
        ni, n1i = int(n[i]), int(n1[i])
        jmin = max(0, n1i - ni)
        jmax = min(ni, n1i)
        js = np.arange(jmin, jmax + 1, dtype=np.float64)
        lnCn_j = gammaln(ni + 1) - gammaln(js + 1) - gammaln(ni - js + 1)
        m2 = n1i - js
        lnCn_m = gammaln(ni + 1) - gammaln(m2 + 1) - gammaln(ni - m2 + 1)
        pre.append((a[i], js, lnCn_j + lnCn_m))

    def negloglik(b):
        tot = 0.0
        for ai, js, lw in pre:
            tot -= ai * b - logsumexp(lw + b * js)
        return tot

    def score(b):
        s = 0.0
        for ai, js, lw in pre:
            p = np.exp(lw + b * js - logsumexp(lw + b * js))
            s += ai - np.sum(js * p)
        return s

    def info(b):
        I = 0.0
        for ai, js, lw in pre:
            p = np.exp(lw + b * js - logsumexp(lw + b * js))
            mj = np.sum(js * p)
            I += np.sum(js * js * p) - mj * mj
        return I

    r = minimize_scalar(negloglik, bounds=(-3.0, 3.0), method="bounded",
                        options={"xatol": 1e-8})
    b = float(r.x)
    I = info(b)
    se = 1.0 / np.sqrt(I) if I > 0 else np.nan
    ll1 = -negloglik(b)
    ll0 = -negloglik(0.0)
    lrt = 2.0 * (ll1 - ll0)
    out = {"test": label, "test_type": "exact_conditional_logit",
           "n_strata_informative": int(ns),
           "beta": b, "se": float(se),
           "OR_lost_vs_kept": float(np.exp(b)),
           "ci_lo": float(np.exp(b - 1.96 * se)),
           "ci_hi": float(np.exp(b + 1.96 * se)),
           "P_wald": float(2 * st.norm.sf(abs(b / se))) if se == se else np.nan,
           "P_LRT": float(st.chi2.sf(lrt, 1)),
           "n_binders_lost": int(a.sum()),
           "n_binders_kept": int((n1 - a).sum())}
    log(f"(B-exact) {label}: strata={ns} OR={out['OR_lost_vs_kept']:.3f} "
        f"({out['ci_lo']:.3f}-{out['ci_hi']:.3f}) P_wald={out['P_wald']:.3g} "
        f"P_LRT={out['P_LRT']:.3g}")
    return out


def mantel_haenszel(n_lost, n_kept, n_pep, label=""):
    """MH pooled OR + Robins-Breslow-Greenland CI (model-free cross-check)."""
    n = np.asarray(n_pep, dtype=np.float64)
    a = np.asarray(n_lost, dtype=np.float64)
    c = np.asarray(n_kept, dtype=np.float64)
    b_ = n - a
    d_ = n - c
    nt = a + b_ + c + d_
    with np.errstate(divide="ignore", invalid="ignore"):
        R = np.nansum(a * d_ / nt)
        S = np.nansum(b_ * c / nt)
        P = np.nansum((a + d_) / nt)
        Q = np.nansum((b_ + c) / nt)
        PR = np.nansum((a + d_) * a * d_ / nt ** 2)
        PS = np.nansum((a + d_) * b_ * c / nt ** 2)
        QR = np.nansum((b_ + c) * a * d_ / nt ** 2)
        QS = np.nansum((b_ + c) * b_ * c / nt ** 2)
    if R <= 0 or S <= 0:
        return None
    ormh = R / S
    var = (PR / (2 * R ** 2) + PS / (2 * R * S) + QR / (2 * R * S)
           + QS / (2 * S ** 2))
    se = np.sqrt(var)
    out = {"test": label, "test_type": "mantel_haenszel",
           "MH_OR": float(ormh),
           "ci_lo": float(np.exp(np.log(ormh) - 1.96 * se)),
           "ci_hi": float(np.exp(np.log(ormh) + 1.96 * se)),
           "log_OR": float(np.log(ormh)), "se_log_OR": float(se),
           "P": float(2 * st.norm.sf(abs(np.log(ormh) / se)))}
    # statsmodels cross-check (if available)
    try:
        from statsmodels.stats.contingency_tables import StratifiedTable
        tabs = []
        for al, bl, cl, dl in zip(a, b_, c, d_):
            t = np.array([[al, bl], [cl, dl]], dtype=np.float64)
            if t.sum(axis=0).min() > 0 and t.sum(axis=1).min() > 0:
                tabs.append(t)
        if len(tabs) >= 5:
            stt = StratifiedTable(np.array(tabs))
            out["sm_OR_pooled"] = float(stt.oddsratio_pooled)
            ci = stt.oddsratio_pooled_confint()
            out["sm_ci"] = [float(ci[0]), float(ci[1])]
            out["sm_n_tables_used"] = len(tabs)
    except Exception as e:                                        # pragma: no cover
        out["sm_error"] = str(e)
    log(f"(B-MH)    {label}: MH-OR={out['MH_OR']:.3f} "
        f"({out['ci_lo']:.3f}-{out['ci_hi']:.3f}) P={out['P']:.3g}")
    return out


# ---------------------------------------------------------------- Firth logistic
def firth_logit(X, y, maxiter=120, tol=1e-8):
    X = np.asarray(X, dtype=np.float64)
    y = np.asarray(y, dtype=np.float64)
    n, p = X.shape
    beta = np.zeros(p)
    Iinv = np.eye(p)
    # ---- warm start: plain IRLS MLE (converges in a handful of Newton steps) ----
    for _ in range(30):
        pi = expit(X @ beta)
        W = np.clip(pi * (1 - pi), 1e-12, None)
        I = X.T @ (X * W[:, None])
        try:
            Iinv = np.linalg.inv(I)
        except np.linalg.LinAlgError:
            Iinv = np.linalg.pinv(I)
        step = Iinv @ (X.T @ (y - pi))
        s = 1.0
        for _ in range(30):
            if np.all(np.isfinite(step * s)) and np.max(np.abs(step * s)) < 1e6:
                break
            s *= 0.5
        beta = beta + s * step
        if np.max(np.abs(s * step)) < 1e-9:
            break
    # ---- Firth (Jeffreys-prior penalised) iterations ----
    conv = False
    for _ in range(maxiter):
        eta = X @ beta
        pi = expit(eta)
        W = np.clip(pi * (1 - pi), 1e-12, None)
        XW = X * W[:, None]
        I = X.T @ XW
        try:
            Iinv = np.linalg.inv(I)
        except np.linalg.LinAlgError:
            Iinv = np.linalg.pinv(I)
        U = X.T @ (y - pi)
        H = np.einsum("ij,jk,ik->i", XW, Iinv, X)          # W_i x_i' Iinv x_i
        adj = 0.5 * (X.T @ (H * (1 - 2 * pi)))
        step = Iinv @ (U + adj)
        s = 1.0
        for _ in range(30):
            bn = beta + s * step
            if np.all(np.isfinite(bn)):
                break
            s *= 0.5
        if np.max(np.abs(s * step)) < tol:
            beta = bn
            conv = True
            break
        beta = bn
    cov = Iinv
    se = np.sqrt(np.abs(np.diag(cov)))
    ll = np.sum(y * eta - np.logaddexp(0, eta))
    return beta, se, ll, conv


def design_matrix(d, xcol, extra_cols):
    """Build X (with intercept) for a logistic model.  extra_cols = list of
    (name, is_categorical)."""
    parts = [np.ones((len(d), 1))]
    names = ["Intercept"]
    parts.append(d[[xcol]].to_numpy(dtype=float))
    names.append(xcol)
    for name, is_cat in extra_cols:
        if is_cat:
            dm = pd.get_dummies(d[name].astype(str), prefix=name, drop_first=True)
            parts.append(dm.to_numpy(dtype=float))
            names += list(dm.columns)
        else:
            parts.append(d[[name]].to_numpy(dtype=float))
            names.append(name)
    return np.hstack(parts), names


def fit_A(df, label, xcol, extra_cat=True, panel=True):
    import statsmodels.formula.api as smf
    d = df.dropna(subset=[xcol, "log10TMB", "frac_all", "FACETS_PURITY",
                          "any_LOH", "CANCER_TYPE"]).copy()
    d = d[np.isfinite(d[xcol])]
    d["Z"] = (d[xcol] - d[xcol].mean()) / d[xcol].std()
    cols = ["Z", "log10TMB", "frac_all", "FACETS_PURITY"]
    extra = ["C(CANCER_TYPE)"] + (["C(GENE_PANEL)"] if panel else [])
    formula = "any_LOH ~ " + " + ".join(cols + extra)
    out = {"model": label, "n": int(len(d)), "n_LOH": int(d.any_LOH.sum()),
           "formula": formula}
    # --- default (reproduce 03_stats) ---
    try:
        res0 = smf.logit(formula, data=d).fit(disp=0)
        out["default_converged"] = bool(res0.mle_retvals.get("converged", False))
        out["default_OR"] = float(np.exp(res0.params["Z"]))
        out["default_P"] = float(res0.pvalues["Z"])
    except Exception as e:
        out["default_error"] = str(e)
    # --- maxiter=1000, model-based + HC3 ---
    res = smf.logit(formula, data=d).fit(disp=0, maxiter=1000)
    resr = smf.logit(formula, data=d).fit(disp=0, maxiter=1000, cov_type="HC3")
    ci = res.conf_int()
    cir = resr.conf_int()
    out.update({
        "maxiter_converged": bool(res.mle_retvals.get("converged", False)),
        "OR_per_SD": float(np.exp(res.params["Z"])),
        "ci_lo": float(np.exp(ci.loc["Z", 0])),
        "ci_hi": float(np.exp(ci.loc["Z", 1])),
        "P": float(res.pvalues["Z"]),
        "OR_HC3": float(np.exp(resr.params["Z"])),
        "ci_lo_HC3": float(np.exp(cir.loc["Z", 0])),
        "ci_hi_HC3": float(np.exp(cir.loc["Z", 1])),
        "P_HC3": float(resr.pvalues["Z"])})
    # --- Firth on the same design (Z + covariates + cancer-type dummies) ---
    X, names = design_matrix(d, "Z", [("log10TMB", False), ("frac_all", False),
                                      ("FACETS_PURITY", False),
                                      ("CANCER_TYPE", True),
                                      ("GENE_PANEL", panel)])
    y = d.any_LOH.to_numpy(dtype=float)
    beta, se, _, conv = firth_logit(X, y)
    zi = names.index("Z")
    z = beta[zi] / se[zi]
    out.update({"firth_converged": bool(conv),
                "OR_Firth": float(np.exp(beta[zi])),
                "ci_lo_Firth": float(np.exp(beta[zi] - 1.96 * se[zi])),
                "ci_hi_Firth": float(np.exp(beta[zi] + 1.96 * se[zi])),
                "P_Firth": float(2 * st.norm.sf(abs(z)))})
    log(f"(A-ext) {label}: n={out['n']} LOH+={out['n_LOH']} | "
        f"MLE(maxiter1000,conv={out['maxiter_converged']}) OR={out['OR_per_SD']:.3f} "
        f"({out['ci_lo']:.3f}-{out['ci_hi']:.3f}) P={out['P']:.3g} | "
        f"HC3 OR={out['OR_HC3']:.3f} P={out['P_HC3']:.3g} | "
        f"Firth OR={out['OR_Firth']:.3f} "
        f"({out['ci_lo_Firth']:.3f}-{out['ci_hi_Firth']:.3f}) "
        f"P={out['P_Firth']:.3g}")
    return out, d


# ---------------------------------------------------------------- pairing (copy of 03_stats)
def build_pairs(smp_df, slt_df):
    loh_ids = set(smp_df[smp_df.any_LOH == 1].SAMPLE_ID)
    s = slt_df[slt_df.SAMPLE_ID.isin(loh_ids)].copy()
    s["is_hom"] = s.is_hom.astype(str).str.lower() == "true"
    s["n_bind"] = pd.to_numeric(s.n_bind_either, errors="coerce")
    s["n_pepv"] = pd.to_numeric(s.n_pep, errors="coerce")
    diag = {"loh_samples_considered": len(loh_ids), "homozygous_loci_excluded": 0,
            "loci_missing_slot": 0, "loci_no_loh_call": 0, "loci_both_lost": 0,
            "loci_no_loss": 0, "loci_paired": 0, "samples_with_pair": 0}
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
        l1, l2 = str(r1.loh).strip().lower(), str(r2.loh).strip().lower()
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
        pairs.append({"SAMPLE_ID": sid, "locus": locus, "loh_slot": lost,
                      "kept_slot": kept, "loh_allele": g.loc[lost, "allele"],
                      "kept_allele": g.loc[kept, "allele"],
                      "n_pep": float(g.loc[lost, "n_pepv"]),
                      "n_bind_lost": float(g.loc[lost, "n_bind"]),
                      "n_bind_kept": float(g.loc[kept, "n_bind"]),
                      "d_bind": float(g.loc[lost, "n_bind"]) - float(g.loc[kept, "n_bind"])})
        diag["loci_paired"] += 1
    pairs = pd.DataFrame(pairs)
    diag["samples_with_pair"] = int(pairs.SAMPLE_ID.nunique()) if len(pairs) else 0
    return pairs, diag


def paired_tests(pairs, label, out_rows):
    if len(pairs) == 0:
        return
    pos = int((pairs.d_bind > 0).sum()); neg = int((pairs.d_bind < 0).sum())
    tie = int((pairs.d_bind == 0).sum())
    bt = st.binomtest(pos, pos + neg, 0.5) if (pos + neg) > 0 else None
    w = (st.wilcoxon(pairs.n_bind_lost, pairs.n_bind_kept, zero_method="wilcox")
         if (pairs.d_bind != 0).any() else None)
    tot = pairs.groupby("SAMPLE_ID")[["n_bind_lost", "n_bind_kept"]].sum()
    tot["d"] = tot.n_bind_lost - tot.n_bind_kept
    frac_more = float((tot.d > 0).mean())
    w2 = (st.wilcoxon(tot.n_bind_lost, tot.n_bind_kept, zero_method="wilcox")
          if (tot.d != 0).any() else None)
    out_rows.append({"test": label, "test_type": "paired_loci",
                     "n_locus_pairs": int(len(pairs)),
                     "n_samples": int(pairs.SAMPLE_ID.nunique()),
                     "lost_gt_kept": pos, "lost_lt_kept": neg, "ties": tie,
                     "sign_test_P": float(bt.pvalue) if bt else np.nan,
                     "wilcoxon_P": float(w.pvalue) if w else np.nan,
                     "median_bind_lost": float(pairs.n_bind_lost.median()),
                     "median_bind_kept": float(pairs.n_bind_kept.median()),
                     "mean_bind_lost": round(float(pairs.n_bind_lost.mean()), 4),
                     "mean_bind_kept": round(float(pairs.n_bind_kept.mean()), 4),
                     "frac_samples_lost_more": frac_more,
                     "sample_level_wilcoxon_P": float(w2.pvalue) if w2 else np.nan})
    log(f"(B) {label}: pairs={len(pairs)} samples={pairs.SAMPLE_ID.nunique()} | "
        f"lost>kept {pos}/lost<kept {neg} (ties {tie}) | sign P="
        f"{(float(bt.pvalue) if bt else np.nan):.3g} | Wilcoxon P="
        f"{(float(w.pvalue) if w else np.nan):.3g} | frac lost-more={frac_more:.3f}")


def run_B(pairs, label, B_rows):
    if len(pairs) == 0:
        return
    paired_tests(pairs, label, B_rows)
    e = exact_cond_logit(pairs.n_bind_lost.values, pairs.n_bind_kept.values,
                         pairs.n_pep.values, label)
    if e:
        B_rows.append(e)
    mh = mantel_haenszel(pairs.n_bind_lost.values, pairs.n_bind_kept.values,
                         pairs.n_pep.values, label)
    if mh:
        B_rows.append(mh)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="netmhcpan_full")
    args = ap.parse_args()
    out = NEO / "output" / "stats" / args.tag
    out.mkdir(parents=True, exist_ok=True)
    t0 = time.time()

    df = pd.read_csv(out / "analysis_frame.tsv", sep="\t", dtype=str)
    for c in ["n_pep", "n_neo_ic50", "n_neo_pct", "n_neo_either", "n_mut_coding",
              "TMB_SCORE", "FACETS_PURITY", "FACETS_PLOIDY", "frac_all",
              "frac_ex6", "HLA_LOH_burden", "panel_mb", "neo_per_Mb",
              "neo_per_mut", "log10TMB", "any_LOH"]:
        df[c] = pd.to_numeric(df[c], errors="coerce")
    # arm_6p_loss from master_cohort (arm-level sensitivity)
    mc6 = pd.read_csv(MASTER, sep="\t", dtype=str, low_memory=False,
                      usecols=["SAMPLE_ID", "arm_6p_loss", "arm_6p", "arm_9p_loss"])
    df = df.merge(mc6, on="SAMPLE_ID", how="left")
    log(f"analysis frame: {len(df)} samples, LOH+={int(df.any_LOH.sum())}, "
        f"arm_6p_loss TRUE={int((df.arm_6p_loss=='TRUE').sum())}")

    slt = pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                     for f in sorted((PRED / args.tag).glob("pred_slots_*.tsv"))],
                    ignore_index=True)

    # ================= (A) main + Firth + robust SE =======================
    A_rows = []
    for label, xcol, panel in [
            ("neo_count", "n_neo_either", True),
            ("neo_count_ic50_def", "n_neo_ic50", True),
            ("neo_per_Mb", "neo_per_Mb", True),
            ("neo_per_mut", "neo_per_mut", True),
            ("neo_count_no_panel_term", "n_neo_either", False)]:
        try:
            r, _ = fit_A(df, label, xcol, panel=panel)
            A_rows.append(r)
        except Exception as e:
            log(f"(A-ext) {label} failed: {e}")
    pd.DataFrame(A_rows).to_csv(out / "extended_A_logistic_firth.tsv", sep="\t",
                                index=False)

    # ================= (A) by aneuploidy tertile ==========================
    T_rows = []
    df["aneu_tertile"] = pd.qcut(df.frac_all, 3, labels=["T1_low", "T2_mid", "T3_high"])
    for t in ["T1_low", "T2_mid", "T3_high"]:
        sub = df[df.aneu_tertile == t].copy()
        if len(sub) < 100:
            continue
        try:
            r, _ = fit_A(sub, f"A_neo_count_{t}", "n_neo_either", panel=True)
            r["tertile"] = t
            r["frac_all_range"] = [float(sub.frac_all.min()), float(sub.frac_all.max())]
            T_rows.append(r)
        except Exception as e:
            log(f"(A-tertile) {t} failed: {e}")
    pd.DataFrame(T_rows).to_csv(out / "extended_A_by_aneuploidy_tertile.tsv",
                                sep="\t", index=False)

    # ================= (B) allele-paired, fixed ===========================
    B_rows = []
    pairs, diag = build_pairs(df, slt)
    log(f"(B) pairing diagnostics: {json.dumps(diag)}")
    pairs.to_csv(out / "extended_B_pairs.tsv", sep="\t", index=False)
    run_B(pairs, "all_loci", B_rows)
    for loc in ["A", "B", "C"]:
        run_B(pairs[pairs.locus == loc], f"locus_{loc}", B_rows)
    # sample-level fraction
    tot = pairs.groupby("SAMPLE_ID")[["n_bind_lost", "n_bind_kept"]].sum()
    (out / "extended_B_sample_level_fraction.json").write_text(json.dumps({
        "n_samples_with_pair": int(len(tot)),
        "lost_more": int((tot.n_bind_lost > tot.n_bind_kept).sum()),
        "kept_more": int((tot.n_bind_lost < tot.n_bind_kept).sum()),
        "equal": int((tot.n_bind_lost == tot.n_bind_kept).sum()),
        "frac_lost_more": float((tot.n_bind_lost > tot.n_bind_kept).mean())},
        indent=1), encoding="utf-8")

    # ---- (C) sensitivities -------------------------------------------------
    C_rows = []
    # (C1) purity >= 50
    sub50 = df[df.FACETS_PURITY >= 0.5].copy()
    if len(sub50) >= 30:
        r, _ = fit_A(sub50, "sens_purity_ge50", "n_neo_either", panel=True)
        C_rows.append(r)
        p50, d50 = build_pairs(sub50, slt)
        if len(p50):
            run_B(p50, "sens_purity_ge50", C_rows)
    # (C2) clonal only: rebuild slot table with clonal binder counts
    bnd = pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                     for f in sorted((PRED / args.tag).glob("pred_binders_*.tsv"))],
                    ignore_index=True)
    bcl = bnd[bnd.is_CLONAL.astype(str) == "CLONAL"]
    nc = bcl.groupby("SAMPLE_ID").pep_mut.nunique().rename("n_neo_clonal")
    dfc = df.merge(nc, on="SAMPLE_ID", how="left")
    dfc["n_neo_clonal"] = dfc.n_neo_clonal.fillna(0)
    clon_sets = {}
    frames = []
    for fp in sorted(PEPDIR.glob("peptides_part_*.tsv")):
        frames.append(pd.read_csv(fp, sep="\t", dtype=str, usecols=["SAMPLE_ID", "pep_mut", "is_CLONAL"]))
    pp = pd.concat(frames, ignore_index=True)
    clon_sets = (pp[pp.is_CLONAL == "CLONAL"].groupby("SAMPLE_ID").pep_mut
                 .apply(set).to_dict())
    dfc["n_pep_clonal"] = dfc.SAMPLE_ID.map(lambda s: len(clon_sets.get(s, [])))
    try:
        dc = dfc[dfc.n_pep_clonal >= 1].copy()
        if len(dc) >= 30:
            r, _ = fit_A(dc, "sens_clonal_only", "n_neo_clonal", panel=True)
            C_rows.append(r)
    except Exception as e:
        log(f"(C) clonal logistic failed: {e}")
    slot_cl = (bcl.groupby(["SAMPLE_ID", "slot"]).pep_mut.nunique()
               .rename("n_bind_cl").reset_index())
    sltc = slt.drop(columns=["n_bind_either"]).merge(
        slot_cl, on=["SAMPLE_ID", "slot"], how="left")
    sltc["n_bind_either"] = sltc.n_bind_cl.fillna(0)
    pcl, _ = build_pairs(df, sltc)
    if len(pcl):
        run_B(pcl, "sens_clonal_only", C_rows)
        pcl.to_csv(out / "extended_C_pairs_clonal_only.tsv", sep="\t", index=False)
    # (C3) 6p arm-loss (arm-dependent) subset
    sub6p = df[df.arm_6p_loss == "TRUE"].copy()
    if len(sub6p) >= 100:
        r, _ = fit_A(sub6p, "sens_arm6p_loss", "n_neo_either", panel=True)
        r["n_arm6p_loss"] = int(len(sub6p))
        C_rows.append(r)
        p6, d6 = build_pairs(sub6p, slt)
        if len(p6):
            run_B(p6, "sens_arm6p_loss", C_rows)
    pd.DataFrame(C_rows).to_csv(out / "extended_C_sensitivity.tsv", sep="\t",
                               index=False)

    summary = {"tag": args.tag,
               "B_diagnostics": diag,
               "A_extended": A_rows, "A_tertile": T_rows,
               "B_extended": B_rows, "C_extended": C_rows}
    (out / "extended_summary.json").write_text(
        json.dumps(summary, indent=2, default=str), encoding="utf-8")
    log(f"extended stats written to {out} in {time.time()-t0:.1f}s")


if __name__ == "__main__":
    main()
