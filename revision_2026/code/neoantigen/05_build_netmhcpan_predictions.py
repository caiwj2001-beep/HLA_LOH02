#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Stage 5: turn the raw netMHCpan-4.2e per-allele output into the SAME three-file
schema that stage 2 produced for MHCflurry, so that 03_stats.py can be re-run
with --tag netmhcpan_pilot and the definition/model are byte-for-byte identical.

Binding definition (netMHCpan arm)   : %Rank_EL <= 2 %
Secondary definition (reported only) : IC50 (Aff nM) <= 500

Inputs
  output/predictions/netmhcpan_pilot/per_allele/<HLA-A01_01>.tsv
        columns: Peptide  EL_rank  BA_rank  Aff_nM  Allele   (one row per peptide)
  output/predictions/pilot/pred_samples_*.tsv   (metadata columns reused verbatim)
  output/peptides/peptides_part_*.tsv           (frozen stage-1 peptide table)

Outputs (output/predictions/netmhcpan_pilot/)
  pred_samples_XXXXX.tsv   / pred_slots_XXXXX.tsv / pred_binders_XXXXX.tsv
"""
import argparse
import json
import pathlib
import time

import numpy as np
import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent
NEO = HERE.parent
PROJ = NEO.parent

PEPDIR = NEO / "output" / "peptides"
PILOT = NEO / "output" / "predictions" / "pilot"
MUT = PROJ / "msk_impact_50k_2026" / "data_mutations.txt"
CLIN_PAT = PROJ / "msk_impact_50k_2026" / "data_clinical_patient.txt"
MASTER = PROJ / "V6" / "04_processed_data" / "master_cohort.tsv"

SLOTS = [("A", 1, "HLA-A1"), ("A", 2, "HLA-A2"),
         ("B", 1, "HLA-B1"), ("B", 2, "HLA-B2"),
         ("C", 1, "HLA-C1"), ("C", 2, "HLA-C2")]
LOH_COL = {"HLA-A1": "HLA_A1_LOH", "HLA-A2": "HLA_A2_LOH",
           "HLA-B1": "HLA_B1_LOH", "HLA-B2": "HLA_B2_LOH",
           "HLA-C1": "HLA_C1_LOH", "HLA-C2": "HLA_C2_LOH"}
IC50_THR = 500.0
PCT_THR = 2.0
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


def load_per_allele(d):
    """allele(colon form) -> dict(pep -> (EL_rank, BA_rank, Aff))"""
    out, nrows = {}, 0
    for f in sorted(d.glob("*.tsv")):
        df = pd.read_csv(f, sep="\t", dtype=str, header=None,
                         names=["pep", "el_rank", "ba_rank", "aff", "allele"])
        df["el_rank"] = pd.to_numeric(df.el_rank, errors="coerce")
        df["ba_rank"] = pd.to_numeric(df.ba_rank, errors="coerce")
        df["aff"] = pd.to_numeric(df.aff, errors="coerce")
        al = str(df.allele.iloc[0]) if len(df) else None
        if al is None:
            continue
        out[al.replace("*", "")] = {p: (e, b, a) for p, e, b, a in
                                    zip(df.pep, df.el_rank, df.ba_rank, df.aff)}
        nrows += len(df)
    log(f"loaded {len(out)} alleles / {nrows} peptide predictions")
    return out, nrows


def load_mut_counts(sample_ids):
    m = pd.read_csv(MUT, sep="\t", dtype=str, low_memory=False,
                    usecols=["Tumor_Sample_Barcode", "Variant_Classification"])
    m = m[m.Variant_Classification.isin(CODING_TYPES)]
    m = m[m.Tumor_Sample_Barcode.isin(sample_ids)]
    return m.Tumor_Sample_Barcode.value_counts().to_dict()


def load_peptides(sample_ids):
    need = set(sample_ids)
    frames = []
    for fp in sorted(PEPDIR.glob("peptides_part_*.tsv")):
        d = pd.read_csv(fp, sep="\t", dtype=str)
        d = d[d.SAMPLE_ID.isin(need)]
        if len(d):
            frames.append(d)
    pet = pd.concat(frames, ignore_index=True)
    out = {}
    for sid, g in pet.groupby("SAMPLE_ID", sort=False):
        g = g.drop_duplicates(subset=["pep_mut"])     # same rule as stage 2
        out[sid] = g
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="netmhcpan_pilot")
    ap.add_argument("--batch", type=int, default=200)
    args = ap.parse_args()

    OD = NEO / "output" / "predictions" / args.tag
    PA = OD / "per_allele"
    t0 = time.time()

    pred, nrows = load_per_allele(PA)

    # metadata columns are taken verbatim from the MHCflurry pilot run so that
    # every covariate is identical between the two arms
    smp = pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                     for f in sorted(PILOT.glob("pred_samples_*.tsv"))],
                    ignore_index=True)
    man = json.loads((PILOT / "manifest.json").read_text())
    samples = [s for b in man["batches"] for s in b]
    log(f"pilot samples from manifest: {len(samples)}")

    pat = pd.read_csv(CLIN_PAT, sep="\t", comment="#", dtype=str)
    pat_alleles = {r[0]: {sname: norm_allele(r[6 + i])
                          for i, (_, _, sname) in enumerate(SLOTS)}
                   for r in pat.itertuples(index=False)}
    mut_counts = load_mut_counts(set(samples))
    peps = load_peptides(samples)
    meta = smp.set_index("SAMPLE_ID")
    # per-slot LOH calls live in master_cohort (stage 2 read them from there too)
    mc = pd.read_csv(MASTER, sep="\t", dtype=str, low_memory=False,
                     usecols=["SAMPLE_ID"] + list(LOH_COL.values()))
    loh_by_sample = mc.set_index("SAMPLE_ID").to_dict("index")
    log(f"master_cohort LOH columns loaded for {len(loh_by_sample)} samples")

    missing_allele = {}
    batches = [samples[i:i + args.batch] for i in range(0, len(samples), args.batch)]
    (OD / "manifest.json").write_text(json.dumps(
        {"source": "netMHCpan-4.2e", "binding_rule": "%Rank_EL <= 2",
         "n_samples": len(samples), "batch_size": args.batch,
         "batches": batches}, indent=1), encoding="utf-8")

    n_bind_total = 0
    for bi, batch in enumerate(batches):
        s_rows, slot_rows, binder_rows = [], [], []
        for sid in batch:
            g = peps.get(sid)
            row = meta.loc[sid]
            if g is None or len(g) == 0:
                continue
            pid = row.PATIENT_ID
            keys, slot_info = [], []
            lohrow = loh_by_sample.get(sid, {})
            for locus, num, sname in SLOTS:
                al = pat_alleles.get(pid, {}).get(sname)
                if al is None:
                    continue
                keys.append((sname, locus, al, str(lohrow.get(LOH_COL[sname], ""))))
            if not keys:
                continue
            pp = g.pep_mut.values
            n_pep = len(pp)
            # peptide -> (wt, len, gene, clonal) ; g is already deduped on pep_mut
            pmeta = {p: (w, l, gn, cl) for p, w, l, gn, cl in
                     zip(g.pep_mut, g.pep_wt, g.pep_len, g.GENE, g.is_CLONAL)}
            # per-slot
            slot_bind = {}
            for sname, locus, al, loh in keys:
                m = pred.get(al.replace("*", ""))
                if m is None:
                    missing_allele[al] = missing_allele.get(al, 0) + 1
                    m = {}
                el = np.array([m.get(p, (np.nan, np.nan, np.nan))[0] for p in pp],
                              dtype=float)
                af = np.array([m.get(p, (np.nan, np.nan, np.nan))[2] for p in pp],
                              dtype=float)
                nb_pct = int(np.nansum(el <= PCT_THR))
                nb_ic50 = int(np.nansum(af <= IC50_THR))
                hom = False
                for l2, n2, s2 in SLOTS:
                    if l2 == locus and s2 != sname:
                        if pat_alleles.get(pid, {}).get(s2) == al:
                            hom = True
                slot_rows.append((sid, sname, locus, al, loh, hom, n_pep,
                                  nb_ic50, nb_pct, nb_pct))
                slot_bind[sname] = set(np.array(pp)[el <= PCT_THR].tolist())
                for i in np.where(el <= PCT_THR)[0]:
                    p = pp[i]
                    w, ln, gn, cl = pmeta.get(p, ("", "", "", ""))
                    binder_rows.append((sid, sname, locus, al, loh, p,
                                        w, ln, gn, cl,
                                        round(float(af[i]), 3),
                                        round(float(el[i]), 4)))
                    n_bind_total += 1
            # sample-level union across the sample's own alleles
            best = {}
            for sname, locus, al, loh in keys:
                m = pred.get(al.replace("*", ""))
                if not m:
                    continue
                for p in pp:
                    v = m.get(p)
                    if v is None:
                        continue
                    if p not in best or v[0] < best[p][0]:
                        best[p] = v
            if best:
                elmin = np.array([v[0] for v in best.values()], dtype=float)
                afmin = np.array([v[2] for v in best.values()], dtype=float)
            else:
                elmin = afmin = np.array([])
            n_neo_pct = int(np.nansum(elmin <= PCT_THR))
            n_neo_ic50 = int(np.nansum(afmin <= IC50_THR))
            s_rows.append((sid, pid, row.CANCER_TYPE, row.any_HLA_LOH,
                           row.HLA_LOH_burden, n_pep, len(keys), n_neo_ic50,
                           n_neo_pct, n_neo_pct, int(mut_counts.get(sid, 0)),
                           row.TMB_SCORE, row.FACETS_PURITY, row.FACETS_PLOIDY,
                           row.FACETS_WGD))
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
        (OD / f"{bi:05d}.done").write_text("ok")
        if bi % 4 == 0 or bi == len(batches) - 1:
            log(f"batch {bi+1}/{len(batches)} written")

    log(f"binder rows (peptide x allele, %Rank_EL<=2): {n_bind_total}")
    if missing_allele:
        log(f"WARNING alleles absent from netMHCpan output: {missing_allele}")
    else:
        log("all sample alleles were covered by netMHCpan output")
    log(f"done in {time.time()-t0:.1f}s -> {OD}")


if __name__ == "__main__":
    main()
