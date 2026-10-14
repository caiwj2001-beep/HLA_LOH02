"""
MHCflurry 2.3.x smoke test for the HLA_LOH02 neoantigen pipeline.

Runs:
  1) Known positive / negative peptide-MHC pairs through Class1PresentationPredictor
     (one sample per peptide-allele pair -> true pairwise predictions)
  2) A batch timing benchmark -> extrapolation to 30-40M predictions

Self-locating: forces MHCFLURRY_DATA_DIR to ../models (offline, no network needed).
Usage:  env/Scripts/python.exe scripts/smoke_test.py
"""
import os
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent  # .../neoantigen
os.environ.setdefault("MHCFLURRY_DATA_DIR", str(HERE / "models"))

import numpy as np
import pandas as pd
import mhcflurry
from mhcflurry import Class1PresentationPredictor

np.random.seed(0)
pd.set_option("display.width", 220)
pd.set_option("display.max_columns", 50)


def banner(t):
    print("\n" + "=" * 78)
    print(t)
    print("=" * 78)


banner("ENVIRONMENT")
print("python   :", sys.version.split()[0], f"({sys.executable})")
print("mhcflurry:", mhcflurry.__version__)
print("numpy    :", np.__version__)
print("pandas   :", pd.__version__)
import torch
print("torch    :", torch.__version__, "| cuda:", torch.cuda.is_available())
print("data dir :", os.environ["MHCFLURRY_DATA_DIR"])
import mhcflurry.downloads as _d
print("resolved downloads dir:", _d.get_downloads_dir())
print("(models resolved from local disk only; offline)")

banner("LOAD MODELS (offline)")
t0 = time.time()
predictor = Class1PresentationPredictor.load()
print("Class1PresentationPredictor loaded in %.2f s" % (time.time() - t0))
print("supported alleles:", len(predictor.supported_alleles))

banner("SMOKE TEST: KNOWN PAIRS (one sample per pair)")
pairs = [
    # (label, peptide, allele, expected)
    ("pos_A0201_SIINFEKL",   "SIINFEKL",  "HLA-A*02:01", "positive (requested)"),
    ("pos_A0201_NLVPMVATV",  "NLVPMVATV", "HLA-A*02:01", "canonical strong A*02:01 (CMV pp65)"),
    ("pos_A0201_GILGFVFTL",  "GILGFVFTL", "HLA-A*02:01", "canonical strong A*02:01 (Flu M1)"),
    ("neg_B0702_SIINFEKL",   "SIINFEKL",  "HLA-B*07:02", "negative (requested)"),
    ("neg_A0201_polyA",      "AAAAAAAAA", "HLA-A*02:01", "negative poly-Ala"),
    ("neg_A0201_random9mer", "LSAQWTDRK", "HLA-A*02:01", "negative random 9mer"),
]
peptides = [p for _, p, _, _ in pairs]
alleles = [a for _, _, a, _ in pairs]
sample_names = ["s%d" % i for i in range(len(pairs))]
allele_map = {name: [a] for name, a in zip(sample_names, alleles)}
t0 = time.time()
res = predictor.predict(
    peptides=peptides, alleles=allele_map, sample_names=sample_names,
    include_affinity_percentile=True, verbose=0)
dt = time.time() - t0
res = res.reset_index(drop=True)
res.insert(0, "label", [l for l, _, _, _ in pairs])
res.insert(4, "expected", [e for _, _, _, e in pairs])
cols = [c for c in ["label", "peptide", "best_allele", "expected",
                    "affinity", "affinity_percentile",
                    "presentation_score", "presentation_percentile",
                    "processing_score"] if c in res.columns]
print(res[cols].to_string(index=False))
print("\n(raw, all columns):")
print(res.to_string(index=False))
print("\nelapsed for %d pairs: %.3f s (%.4f s/pair incl. per-sample overhead)" % (len(pairs), dt, dt / len(pairs)))

banner("BINDER CALLS")
print("criteria: affinity_binder = affinity_percentile<2 ; presentation_binder = presentation_percentile<2")
print("(MHCflurry's standard 'presentation' cutoff is presentation_percentile < 2, commonly < 0.5)\n")
for _, row in res.iterrows():
    ap = row.get("affinity_percentile", float("nan"))
    pp = row.get("presentation_percentile", float("nan"))
    print("%-22s %-11s %-11s IC50=%10.1f nM  aff%%=%7.3f  pres%%=%8.3f  -> aff_binder=%-5s pres_binder=%s"
          % (row["label"], row["peptide"], row["best_allele"],
             row["affinity"], ap, pp, ap < 2.0, pp < 2.0))

banner("TIMING BENCHMARK (throughput, best of 3)")
rng = np.random.default_rng(0)
AA = np.array(list("ACDEFGHIKLMNPQRSTVWY"))


def time_batch(n_pep, alleles_for_sample, label, reps=3):
    peps = ["".join(rng.choice(AA, size=9)) for _ in range(n_pep)]
    smp = ["s0"] * n_pep
    amap = {"s0": list(alleles_for_sample)}
    predictor.predict(peptides=peps[:50], alleles=amap,
                      sample_names=smp[:50], verbose=0)  # warmup
    times = []
    for _ in range(reps):
        t0 = time.time()
        predictor.predict(peptides=peps, alleles=amap,
                          sample_names=smp, verbose=0)
        times.append(time.time() - t0)
    el = min(times)
    pairs = n_pep * len(alleles_for_sample)
    per = el / pairs
    print("%-18s n_pep=%5d  alleles/sample=%d  pairs=%6d  best=%.3f s  min..max=%.3f..%.3f s"
          % (label, n_pep, len(alleles_for_sample), pairs, el, el, max(times)))
    print("%-18s -> %.1f pairs/s   %.6f s/pair (%.4f ms/pair)"
          % ("", pairs / el, per, per * 1000))
    return per


per_1 = time_batch(5000, ["HLA-A*02:01"], "1-allele sample")
per_6 = time_batch(5000, ["HLA-A*02:01", "HLA-A*01:01", "HLA-B*07:02",
                          "HLA-B*44:02", "HLA-C*05:01", "HLA-C*07:02"],
                   "6-allele sample")

banner("EXTRAPOLATION (CPU-only, no GPU)")
print("Definitions: 1 'prediction' = 1 peptide-allele pair.")
print("Realistic MSK-IMPACT patient = <=6 HLA-I alleles, so 30-40M pairs corresponds to")
print("  30-40M / ~6 alleles = ~5-6.7M distinct peptides scored.\n")
for name, per in (("1-allele/sample", per_1), ("6-allele/sample", per_6)):
    for total in (30_000_000, 40_000_000):
        hours = total * per / 3600.0
        print("  %-16s %s pairs x %.6f s = %8.2f h = %5.2f days  (rate %.0f pairs/s)"
              % (name, f"{total:,}", per, hours, hours / 24, 1 / per))
print("\nFormula: hours = N_pairs * (s/pair) / 3600")
print("Conclusion: a full 30-40M-pair run is on the order of ~1 working day on this")
print("            CPU-only box; comfortably feasible to parallelise across samples.")


banner("DONE")
