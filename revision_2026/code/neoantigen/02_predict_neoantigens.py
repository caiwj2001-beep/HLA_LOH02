#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Stage 2: MHCflurry (Class1PresentationPredictor.predict_affinity) per-allele
prediction of the mutant peptides built in stage 1.

Key design points
-----------------
* Per-allele pairing is done with the `sample_names` route of
  `predict_affinity`: a pseudo-sample key "<SAMPLE_ID>|<slot>" is created for
  every germline HLA slot and each peptide copy is tagged with its key.  A
  pseudo-sample holds exactly ONE allele, so the "best allele within the
  sample" logic of mhcflurry cannot silently re-pair peptides with the wrong
  allele (the pitfall documented in neoantigen/README.md).
* `include_affinity_percentile=True` is passed explicitly so IC50 AND
  percentile ranks are both returned.
* Work is done in batches of samples; each batch writes its own part files and
  a `*.done` marker, so the run is resumable: just re-invoke the same command.

Binding definition: IC50 <= 500 nM  OR  affinity_percentile <= 2.

Outputs (neoantigen/output/predictions/<tag>/):
  manifest.json           ordered sample ids per batch (deterministic)
  pred_samples_XXXXX.tsv  one row per sample  (aggregated)
  pred_slots_XXXXX.tsv    one row per sample x HLA slot
  pred_binders_XXXXX.tsv  peptide-level binder records
  XXXXX.done              batch completion marker
"""
import argparse
import json
import os
import pathlib
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
NEO = HERE.parent
PROJ = NEO.parent
os.environ.setdefault("MHCFLURRY_DATA_DIR", str(NEO / "models"))

import numpy as np                      # noqa: E402
import pandas as pd                     # noqa: E402

MASTER = PROJ / "V6" / "04_processed_data" / "master_cohort.tsv"
PEPDIR = NEO / "output" / "peptides"
CLIN_PAT = PROJ / "msk_impact_50k_2026" / "data_clinical_patient.txt"
MUT = PROJ / "msk_impact_50k_2026" / "data_mutations.txt"

SLOTS = [("A", 1, "HLA-A1"), ("A", 2, "HLA-A2"),
         ("B", 1, "HLA-B1"), ("B", 2, "HLA-B2"),
         ("C", 1, "HLA-C1"), ("C", 2, "HLA-C2")]
LOH_COL = {"HLA-A1": "HLA_A1_LOH", "HLA-A2": "HLA_A2_LOH",
           "HLA-B1": "HLA_B1_LOH", "HLA-B2": "HLA_B2_LOH",
           "HLA-C1": "HLA_C1_LOH", "HLA-C2": "HLA_C2_LOH"}

IC50_THR = 500.0
PCT_THR = 2.0
PILOT_CANCERS = ["Prostate Cancer", "Renal Cell Carcinoma", "Bladder Cancer",
                 "Non-Small Cell Lung Cancer", "Breast Cancer"]
CODING_TYPES = ["Missense_Mutation", "Nonsense_Mutation", "Frame_Shift_Del",
                "Frame_Shift_Ins", "In_Frame_Del", "In_Frame_Ins",
                "Splice_Site", "Translation_Start_Site", "Nonstop_Mutation"]


def log(m):
    print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)


def norm_allele(x):
    if x is None:
        return None
    s = str(x).strip().lower()
    if s in ("", "nan", "na", "none", "not reported"):
        return None
    if s.startswith("hla_"):
        s = s[4:]
    p = s.split("_")
    if len(p) < 3:
        return None
    return f"HLA-{p[0].upper()}*{p[1]}:{p[2]}"


def load_patient_alleles():
    pat = pd.read_csv(CLIN_PAT, sep="\t", comment="#", dtype=str)
    out = {}
    for r in pat.itertuples(index=False):
        d = r._asdict() if hasattr(r, "_asdict") else None
        pid = r[0]
        vals = {}
        # columns 6..11 are HLA-A1,A2,B1,B2,C1,C2 (0-based)
        for i, (_, _, sname) in enumerate(SLOTS):
            vals[sname] = norm_allele(r[6 + i])
        out[pid] = vals
    log(f"patient germline HLA loaded: {len(out)} patients")
    return out


def load_mut_counts(sample_ids):
    """coding mutation count per sample (denominator for the per-Mb rate)."""
    m = pd.read_csv(MUT, sep="\t", dtype=str, low_memory=False,
                    usecols=["Tumor_Sample_Barcode", "Variant_Classification"])
    m = m[m.Variant_Classification.isin(CODING_TYPES)]
    m = m[m.Tumor_Sample_Barcode.isin(sample_ids)]
    return m.Tumor_Sample_Barcode.value_counts().to_dict()


def load_peptides(sample_ids):
    """dict SAMPLE_ID -> dict(peps=np.array, wt=..., ln=..., gene=...)"""
    need = set(sample_ids)
    frames = []
    for fp in sorted(PEPDIR.glob("peptides_part_*.tsv")):
        d = pd.read_csv(fp, sep="\t", dtype=str)
        d = d[d.SAMPLE_ID.isin(need)]
        if len(d):
            frames.append(d)
    pet = pd.concat(frames, ignore_index=True) if frames else pd.DataFrame(
        columns=["SAMPLE_ID", "GENE", "RefSeq", "HGVSp_Short", "pep_mut",
                 "pep_wt", "pep_len", "is_CLONAL"])
    log(f"peptide rows for selected samples: {len(pet)} "
        f"({pet.SAMPLE_ID.nunique()} samples)")
    out = {}
    for sid, g in pet.groupby("SAMPLE_ID", sort=False):
        g = g.drop_duplicates(subset=["pep_mut"])
        out[sid] = {
            "peps": g.pep_mut.values,
            "wt": g.pep_wt.values,
            "ln": g.pep_len.values,
            "gene": g.GENE.values,
            "clon": g.is_CLONAL.values,
        }
    return out


def build_sample_table(mode, cap, seed, predictor_ok):
    mc = pd.read_csv(MASTER, sep="\t", dtype=str, low_memory=False)
    main = mc[mc.analysis_primary == "TRUE"].copy()
    main = main[main.HLA_GENOTYPE_AVAILABLE == "TRUE"]
    peps = load_peptides(main.SAMPLE_ID.values)
    covered = set(peps)
    main = main[main.SAMPLE_ID.isin(covered)].copy()
    log(f"main cohort with HLA genotype AND peptides: {len(main)}")

    if mode == "pilot":
        loh = main[(main.any_HLA_LOH == "TRUE") &
                   (main.CANCER_TYPE.isin(PILOT_CANCERS))].copy()
        ctl = main[(main.any_HLA_LOH == "FALSE") &
                   (main.CANCER_TYPE.isin(PILOT_CANCERS))].copy()
        rng = np.random.default_rng(seed)
        keep_l, keep_c = [], []
        for ct in PILOT_CANCERS:
            a = loh[loh.CANCER_TYPE == ct]
            b = ctl[ctl.CANCER_TYPE == ct]
            na = min(len(a), cap)
            nb = min(len(b), na)
            if na == 0:
                continue
            keep_l.append(a.sample(n=na, random_state=seed))
            keep_c.append(b.sample(n=nb, random_state=seed))
            log(f"  {ct}: LOH avail={len(a)} -> {na}, ctl avail={len(b)} -> {nb}")
        sel = pd.concat(keep_l + keep_c, ignore_index=True)
        sel = sel.sample(frac=1.0, random_state=seed).reset_index(drop=True)
    else:
        sel = main.reset_index(drop=True)
    log(f"mode={mode}: {len(sel)} samples selected "
        f"(LOH+ {int((sel.any_HLA_LOH=='TRUE').sum())})")
    return sel, peps


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["pilot", "full"], default="pilot")
    ap.add_argument("--tag", default=None)
    ap.add_argument("--batch", type=int, default=200)
    ap.add_argument("--cap", type=int, default=300,
                    help="max LOH samples per cancer type (pilot)")
    ap.add_argument("--seed", type=int, default=20261013)
    ap.add_argument("--limit", type=int, default=0, help="debug: only N samples")
    ap.add_argument("--time-budget", type=float, default=0,
                    help="stop after this many seconds (0 = no limit)")
    ap.add_argument("--restart", action="store_true",
                    help="ignore existing .done markers")
    args = ap.parse_args()

    tag = args.tag or args.mode
    OD = NEO / "output" / "predictions" / tag
    OD.mkdir(parents=True, exist_ok=True)

    t0 = time.time()
    sel, pepmap = build_sample_table(args.mode, args.cap, args.seed, True)
    if args.limit:
        sel = sel.head(args.limit)
    pat_alleles = load_patient_alleles()
    mut_counts = load_mut_counts(set(sel.SAMPLE_ID))

    samples = list(sel.SAMPLE_ID)
    batches = [samples[i:i + args.batch] for i in range(0, len(samples), args.batch)]
    (OD / "manifest.json").write_text(json.dumps(
        {"mode": args.mode, "n_samples": len(samples), "batch_size": args.batch,
         "batches": batches}, indent=1), encoding="utf-8")

    from mhcflurry import Class1PresentationPredictor
    tl = time.time()
    predictor = Class1PresentationPredictor.load()
    log(f"predictor loaded in {time.time()-tl:.1f}s")

    meta = sel.set_index("SAMPLE_ID")

    n_done = n_skip = 0
    for bi, batch in enumerate(batches):
        marker = OD / f"{bi:05d}.done"
        if marker.exists() and not args.restart:
            n_skip += 1
            continue
        if args.time_budget and (time.time() - t0) > args.time_budget:
            log(f"time budget {args.time_budget}s reached, stopping after "
                f"{n_done} batches")
            break

        s_rows, slot_rows, binder_rows = [], [], []
        for sid in batch:
            row = meta.loc[sid]
            pv = pepmap.get(sid)
            if pv is None or len(pv["peps"]) == 0:
                continue
            pat = row.PATIENT_ID
            keys, alleles_d, slot_info = [], {}, []
            for locus, num, sname in SLOTS:
                al = pat_alleles.get(pat, {}).get(sname)
                if al is None:
                    continue
                key = f"{sid}|{sname}"
                keys.append(key)
                alleles_d[key] = [al]
                slot_info.append((sname, locus, al, str(row[LOH_COL[sname]])))
            if not keys:
                continue
            peps = list(pv["peps"])
            # ONE call for the whole sample: every HLA slot becomes a
            # pseudo-sample holding exactly one allele.  With sample_names=None
            # mhcflurry runs a single chunked cartesian prediction over the
            # sample's distinct alleles, which is the fast path (~3.4k pairs/s),
            # and each returned row keeps the allele it was paired with.
            df = predictor.predict_affinity(
                peptides=peps, alleles=alleles_d, sample_names=None,
                include_affinity_percentile=True, verbose=0)
            assert df.best_allele.notna().all()
            df["pep"] = df.peptide
            df["ic50"] = df.affinity
            df["pct"] = df.affinity_percentile
            # peptide metadata lookup
            pmeta = {}
            for pm_, pw_, ln_, gn_, cl_ in zip(pv["peps"], pv["wt"], pv["ln"],
                                               pv["gene"], pv["clon"]):
                pmeta.setdefault(pm_, (pw_, ln_, gn_, cl_))
            # per-slot aggregation
            n_pep = len(peps)
            for key, (sname, locus, al, loh) in zip(keys, slot_info):
                sub = df[df.sample_name == key]
                nb_ic50 = int((sub.ic50 <= IC50_THR).sum())
                nb_pct = int((sub.pct <= PCT_THR).sum())
                bind = sub[(sub.ic50 <= IC50_THR) | (sub.pct <= PCT_THR)]
                nb_either = int(len(bind))
                hom = False
                for l2, n2, s2 in SLOTS:
                    if l2 == locus and s2 != sname:
                        if pat_alleles.get(pat, {}).get(s2) == al:
                            hom = True
                slot_rows.append((sid, sname, locus, al, loh, hom, n_pep,
                                  nb_ic50, nb_pct, nb_either))
                for r in bind.itertuples(index=False):
                    pw_, ln_, gn_, cl_ = pmeta.get(r.pep, ("", "", "", ""))
                    binder_rows.append((sid, sname, locus, al, loh, r.pep,
                                        pw_, ln_, gn_, cl_,
                                        round(float(r.ic50), 3),
                                        round(float(r.pct), 4)))
            # sample level union across slots
            g = df.groupby("pep").agg(min_ic50=("ic50", "min"),
                                      min_pct=("pct", "min"))
            n_neo_ic50 = int((g.min_ic50 <= IC50_THR).sum())
            n_neo_pct = int((g.min_pct <= PCT_THR).sum())
            n_neo_either = int(((g.min_ic50 <= IC50_THR) |
                               (g.min_pct <= PCT_THR)).sum())
            nmut = int(mut_counts.get(sid, 0))
            s_rows.append((sid, row.PATIENT_ID, row.CANCER_TYPE,
                           row.any_HLA_LOH, row.HLA_LOH_burden, n_pep,
                           len(keys), n_neo_ic50, n_neo_pct, n_neo_either,
                           nmut, row.TMB_SCORE, row.FACETS_PURITY,
                           row.FACETS_PLOIDY, row.FACETS_WGD))

        pd.DataFrame(s_rows, columns=[
            "SAMPLE_ID", "PATIENT_ID", "CANCER_TYPE", "any_HLA_LOH",
            "HLA_LOH_burden", "n_pep", "n_alleles", "n_neo_ic50", "n_neo_pct",
            "n_neo_either", "n_mut_coding", "TMB_SCORE", "FACETS_PURITY",
            "FACETS_PLOIDY", "FACETS_WGD"]).to_csv(
            OD / f"pred_samples_{bi:05d}.tsv", sep="\t", index=False)
        pd.DataFrame(slot_rows, columns=[
            "SAMPLE_ID", "slot", "locus", "allele", "loh", "is_hom",
            "n_pep", "n_bind_ic50", "n_bind_pct", "n_bind_either"]).to_csv(
            OD / f"pred_slots_{bi:05d}.tsv", sep="\t", index=False)
        pd.DataFrame(binder_rows, columns=[
            "SAMPLE_ID", "slot", "locus", "allele", "loh", "pep_mut",
            "pep_wt", "pep_len", "gene", "is_CLONAL", "ic50",
            "affinity_percentile"]).to_csv(
            OD / f"pred_binders_{bi:05d}.tsv", sep="\t", index=False)
        marker.write_text("ok")
        n_done += 1
        if n_done % 5 == 0 or bi == len(batches) - 1:
            el = time.time() - t0
            rate = len(batch) / (el / max(n_done, 1))
            log(f"batch {bi+1}/{len(batches)} done | {n_done} processed, "
                f"{n_skip} skipped | elapsed {el/60:.1f} min | "
                f"~{rate:.1f} samples/batch-slot")

    el = time.time() - t0
    log(f"FINISHED mode={tag}: batches processed={n_done}, skipped={n_skip}, "
        f"wall={el/60:.1f} min")
    # projected full-cohort time
    try:
        n_sel = len(samples)
        if n_done:
            per_sample = el / max(n_done * args.batch, 1)
            log(f"measured {per_sample*1000:.1f} ms/sample -> full cohort "
                f"(~26k samples) est {per_sample*26000/3600:.2f} h")
    except Exception:
        pass


if __name__ == "__main__":
    main()
