#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""s11_purity_finalize.py - 定案 S11 `sens_purity_ge50` 行（P3 / A-2）。

背景：
  s_neo1_models.tsv 的 `Sensitivity: sens_purity_ge50` 行沿用 legacy 值
  1.092 (1.020-1.169), P=0.0113（来源 03_stats.py 的 (C1) 块）；
  extended_C_sensitivity.tsv 同一子集给出 1.093 (1.021-1.170), P=0.0104。
  差别不在数据，在**协变量集**：
    03_stats.py      : any_LOH ~ Z + log10TMB + frac_all + FACETS_PURITY + C(CANCER_TYPE)
    08_..._extended  : 上式 + C(GENE_PANEL)          <- 与 primary/S11 表注声明一致

本脚本从 analysis_frame.tsv 直接重算，两种规格并列输出：
  1) 证明 n / n_LOH / 点估计 / CI / P 的差异完全由 GENE_PANEL 项解释；
  2) 为定案值（primary 一致规格，含 GENE_PANEL）留下原始证据。

统计核心用 numpy IRLS（Fisher scoring）自行实现，不依赖 statsmodels 的 formula/
patsy 层（该层在本机 statsmodels 0.15 + pandas 3.0 下对 C(CANCER_TYPE) 会挂死）。
为证明 IRLS 与原始 statsmodels 结果一致，脚本先复算 primary 模型（n=25,954）
并与 A_logistic.tsv 的 neo_count 行比对。

用法：
  neoantigen/env/Scripts/python.exe s11_purity_finalize.py
"""
import os
import numpy as np
import pandas as pd
from scipy import stats as st

NEO = r"C:\Users\Administrator\科研文件\HLA_LOH02\neoantigen"
FRAME = os.path.join(NEO, "output", "stats", "netmhcpan_full", "analysis_frame.tsv")
ALOG = os.path.join(NEO, "output", "stats", "netmhcpan_full", "A_logistic.tsv")
HERE = os.path.dirname(os.path.abspath(__file__))

NUM = ["n_neo_either", "log10TMB", "frac_all", "FACETS_PURITY", "any_LOH"]


def dummies(s):
    """treatment 编码，首个（排序后）水平为参照 —— 与 patsy C() 默认一致。"""
    cats = sorted(pd.unique(s.astype(str)))[1:]
    if not cats:
        return np.zeros((len(s), 0)), []
    return (np.column_stack([(s.astype(str) == c).to_numpy(dtype=float) for c in cats]),
            cats)


def logit_irls(y, X, maxit=200, tol=1e-12):
    """二项 logit 的 Fisher scoring。返回 beta, 标准误, 迭代数。"""
    beta = np.zeros(X.shape[1])
    it = 0
    for it in range(maxit):
        eta = np.clip(X @ beta, -35, 35)
        p = 1.0 / (1.0 + np.exp(-eta))
        w = np.maximum(p * (1 - p), 1e-12)
        # 注意：不要写 (X.T * w) @ X —— 在本机 numpy 2.5.4 上该写法会退化为
        # 慢路径（26k x 64 的加权 Gram 要 16 s）；einsum 同一运算 0.13 s。
        H = np.einsum("ni,n,nj->ij", X, w, X)
        g = X.T @ (y - p)
        try:
            step = np.linalg.solve(H, g)
        except np.linalg.LinAlgError:
            step = np.linalg.lstsq(H, g, rcond=None)[0]
        cur = -np.sum(y * np.log(np.clip(p, 1e-300, 1)) +
                      (1 - y) * np.log(np.clip(1 - p, 1e-300, 1)))
        t = 1.0
        nb = beta + step
        for _ in range(40):                       # 步长减半保护
            neta = np.clip(X @ (beta + t * step), -35, 35)
            np_ = 1.0 / (1.0 + np.exp(-neta))
            new = -np.sum(y * np.log(np.clip(np_, 1e-300, 1)) +
                          (1 - y) * np.log(np.clip(1 - np_, 1e-300, 1)))
            if new <= cur + 1e-12:
                nb = beta + t * step
                break
            t *= 0.5
        delta = np.max(np.abs(nb - beta))
        beta = nb
        if delta < tol:
            break
    eta = np.clip(X @ beta, -35, 35)
    p = 1.0 / (1.0 + np.exp(-eta))
    w = np.maximum(p * (1 - p), 1e-12)
    H = np.einsum("ni,n,nj->ij", X, w, X)
    se = np.sqrt(np.diag(np.linalg.pinv(H)))
    return beta, se, it + 1


def fit(d, xcol, panel, label):
    d = d.dropna(subset=[xcol, "log10TMB", "frac_all", "FACETS_PURITY",
                         "any_LOH", "CANCER_TYPE"]).copy()
    d = d[np.isfinite(d[xcol])]
    Z = (d[xcol] - d[xcol].mean()) / d[xcol].std()
    cols = [np.ones(len(d)), Z.to_numpy(dtype=float),
            d.log10TMB.to_numpy(dtype=float), d.frac_all.to_numpy(dtype=float),
            d.FACETS_PURITY.to_numpy(dtype=float)]
    names = ["Intercept", "Z", "log10TMB", "frac_all", "FACETS_PURITY"]
    cd, cnames = dummies(d.CANCER_TYPE)
    cols.append(cd); names += ["CANCER_TYPE[%s]" % c for c in cnames]
    if panel:
        pdd, pnames = dummies(d.GENE_PANEL)
        cols.append(pdd); names += ["GENE_PANEL[%s]" % c for c in pnames]
    X = np.column_stack(cols)
    y = d.any_LOH.to_numpy(dtype=float)
    beta, se, nit = logit_irls(y, X)
    zi = names.index("Z")
    OR = float(np.exp(beta[zi]))
    lo = float(np.exp(beta[zi] - 1.96 * se[zi]))
    hi = float(np.exp(beta[zi] + 1.96 * se[zi]))
    P = float(2 * st.norm.sf(abs(beta[zi] / se[zi])))
    return {"spec": label, "panel_term": bool(panel), "n": int(len(d)),
            "n_LOH": int(d.any_LOH.sum()), "k": int(X.shape[1]), "iters": int(nit),
            "OR": OR, "lo": lo, "hi": hi, "P": P, "se_Z": float(se[zi]),
            "OR_CI": "%.3f (%.3f-%.3f)" % (OR, lo, hi),
            "P_fmt": ("<0.001" if P < 1e-3 else "%.4f" % P)}


df = pd.read_csv(FRAME, sep="\t", dtype=str)
for c in NUM:
    df[c] = pd.to_numeric(df[c], errors="coerce")
df["CANCER_TYPE"] = df.CANCER_TYPE.astype(str)
df["GENE_PANEL"] = df.GENE_PANEL.astype(str)
print("analysis frame: n=%d, LOH+=%d" % (len(df), int(df.any_LOH.sum())))

# ---------- 0) 校验：用同一 IRLS 复算 primary 模型 ----------
chk = fit(df, "n_neo_either", True, "CHECK_primary_neo_count")
ref = pd.read_csv(ALOG, sep="\t").query("model=='neo_count'").iloc[0]
print("[CHECK] primary neo_count  IRLS : n=%d OR=%.12f CI %.12f-%.12f P=%.12e"
      % (chk["n"], chk["OR"], chk["lo"], chk["hi"], chk["P"]))
print("[CHECK] primary neo_count  ref  : n=%d OR=%.12f CI %.12f-%.12f P=%.12e"
      % (int(ref.n), float(ref.OR_per_SD), float(ref.ci_lo), float(ref.ci_hi), float(ref.P)))
print("[CHECK] |dOR|=%.3e |dlo|=%.3e |dhi|=%.3e |dP|=%.3e"
      % (abs(chk["OR"] - float(ref.OR_per_SD)), abs(chk["lo"] - float(ref.ci_lo)),
         abs(chk["hi"] - float(ref.ci_hi)), abs(chk["P"] - float(ref.P))))

# ---------- 1) purity >= 50% 子集，两种规格 ----------
sub = df[df.FACETS_PURITY >= 0.5]
print("purity>=0.50 subset: n=%d, LOH+=%d, cancer types=%d, panels=%s"
      % (len(sub), int(sub.any_LOH.sum()), sub.CANCER_TYPE.nunique(),
         sorted(sub.GENE_PANEL.unique())))
rows = [fit(sub, "n_neo_either", False, "legacy_no_panel_term"),
        fit(sub, "n_neo_either", True, "primary_with_panel_term")]
for r in rows:
    print("[%s] n=%d n_LOH=%d k=%d OR=%.12f CI %.12f-%.12f P=%.12e -> %s / P=%s"
          % (r["spec"], r["n"], r["n_LOH"], r["k"], r["OR"], r["lo"], r["hi"], r["P"],
             r["OR_CI"], r["P_fmt"]))

out = pd.DataFrame([chk] + rows)
p = os.path.join(HERE, "s11_purity_finalize.tsv")
out.to_csv(p, sep="\t", index=False)
print("wrote", p)
