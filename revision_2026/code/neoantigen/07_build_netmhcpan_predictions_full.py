#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Stage 5 (FULL cohort): turn the raw netMHCpan-4.2e per-allele output into the SAME
three-file schema that stage 2 produced for MHCflurry, so that 03_stats.py can be
re-run with --tag netmhcpan_full and the definition/model are byte-for-byte identical.

Full-cohort sibling of scripts/05_build_netmhcpan_predictions.py.  The ONLY differences:
  * tag defaults to netmhcpan_full;
  * sample universe = the whole peptide/cohort set (peptides_part_*.tsv), not the pilot manifest;
  * per-sample metadata read from V6/04_processed_data/master_cohort.tsv restricted to
    analysis_primary==TRUE & HLA_GENOTYPE_AVAILABLE==TRUE -- exactly the columns stage 2
    copied out of master_cohort, so the metadata is equivalent;
  * the 15.5M (peptide,allele) predictions are consumed ONE ALLELE AT A TIME (streaming),
    not held in RAM at once.

Binding definition (netMHCpan arm)   : %Rank_EL <= 2 %
Secondary definition (reported only) : IC50 (Aff nM) <= 500

Outputs (output/predictions/<tag>/): pred_samples / pred_slots / pred_binders + manifest.json
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
CLIN_PAT = PROJ / "msk_impact_50k_2026" / "data_clinical_patient.txt"
MUT = PROJ / "msk_impact_50k_2026" / "data_mutations.txt"
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


def stem_to_allele(stem):
    """'HLA-A01_01' -> 'HLA-A*01:01'  (inverse of file_stem in stage 1b)."""
    head, tail = stem.split("_")          # 'HLA-A01', '01'
    return f"{head[:-2]}*{head[-2:]}:{tail}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", default="netmhcpan_full")
    ap.add_argument("--batch", type=int, default=200)
    args = ap.parse_args()
    t0 = time.time()

    OD = NEO / "output" / "predictions" / args.tag
    PA = OD / "per_allele"
    OD.mkdir(parents=True, exist_ok=True)

    # ---- 1. master cohort metadata ---------------------------------------
    mcols = ["SAMPLE_ID", "PATIENT_ID", "CANCER_TYPE", "any_HLA_LOH",
             "HLA_LOH_burden", "TMB_SCORE", "FACETS_PURITY", "FACETS_PLOIDY",
             "FACETS_WGD", "analysis_primary", "HLA_GENOTYPE_AVAILABLE"] + list(LOH_COL.values())
    mc = pd.read_csv(MASTER, sep="\t", dtype=str, low_memory=False, usecols=mcols)
    mc = mc.set_index("SAMPLE_ID")
    main_ids = set(mc.index[mc.analysis_primary.eq("TRUE") &
                            mc.HLA_GENOTYPE_AVAILABLE.eq("TRUE")])
    log(f"master_cohort: {len(mc)} rows ; analysis_primary&HLA_GT = {len(main_ids)}")

    # ---- 2. peptide table (frozen stage-1) --------------------------------
    frames = []
    for fp in sorted(PEPDIR.glob("peptides_part_*.tsv")):
        d = pd.read_csv(fp, sep="\t", dtype=str,
                        usecols=["SAMPLE_ID", "GENE", "pep_mut", "pep_wt",
                                 "pep_len", "is_CLONAL"])
        frames.append(d)
    pet = pd.concat(frames, ignore_index=True)
    pet = pet[pet.SAMPLE_ID.isin(main_ids)]
    pet = pet.drop_duplicates(subset=["SAMPLE_ID", "pep_mut"])
    log(f"peptide rows for main cohort (dedup sample x pep_mut): {len(pet)} "
        f"over {pet.SAMPLE_ID.nunique()} samples")

    # ---- 3. germline HLA genotype -----------------------------------------
    pat = pd.read_csv(CLIN_PAT, sep="\t", comment="#", dtype=str)
    pat_alleles = {r[0]: {sname: norm_allele(r[6 + i])
                          for i, (_, _, sname) in enumerate(SLOTS)}
                   for r in pat.itertuples(index=False)}

    # ---- 4. per-sample peptide arrays + slot table ------------------------
    samples = list(pet.SAMPLE_ID.drop_duplicates())

    slots_by_sample = {}     # sid -> list of (sname, locus, al, loh, is_hom)
    pet_arrays = {}          # sid -> (peps, wt, len, gene, clon)
    allele2slots = {}        # allele -> list of (sid, sname)
    missing_gt = 0
    for sid, g in pet.groupby("SAMPLE_ID", sort=False):
        pet_arrays[sid] = (g.pep_mut.values, g.pep_wt.values, g.pep_len.values,
                           g.GENE.values, g.is_CLONAL.values)
        pid = mc.PATIENT_ID.get(sid)
        als = pat_alleles.get(pid)
        if not als or not any(als.values()):
            missing_gt += 1
            continue
        sl = []
        for locus, num, sname in SLOTS:
            al = als.get(sname)
            if al is None:
                continue
            loh = str(mc[LOH_COL[sname]].get(sid, ""))
            hom = any(als.get(s2) == al for l2, n2, s2 in SLOTS
                      if l2 == locus and s2 != sname)
            sl.append((sname, locus, al, loh, hom))
        if not sl:
            continue
        slots_by_sample[sid] = sl
        for sname, locus, al, loh, hom in sl:
            allele2slots.setdefault(al, []).append((sid, sname))
    del pat_alleles, pet
    log(f"sample universe={len(samples)} ; no genotype={missing_gt} ; "
        f"with slots={len(slots_by_sample)} ; distinct alleles used={len(allele2slots)}")

    # ---- 5. coding mutation counts ----------------------------------------
    m = pd.read_csv(MUT, sep="\t", dtype=str, low_memory=False,
                    usecols=["Tumor_Sample_Barcode", "Variant_Classification"])
    m = m[m.Variant_Classification.isin(CODING_TYPES)]
    m = m[m.Tumor_Sample_Barcode.isin(set(slots_by_sample))]
    mut_counts = m.Tumor_Sample_Barcode.value_counts().to_dict()
    log(f"coding-mutation counts loaded for {len(mut_counts)} samples")

    # ---- 6. running per-sample best-rank record (union across the sample's
    #         own alleles) -- identical semantics to 05/stage 2: for each
    #         peptide the "best" allele is the one with the LOWEST %Rank_EL
    #         (strict <, first wins), and the reported IC50 is that allele's.
    best_el = {sid: np.full(len(pet_arrays[sid][0]), np.inf, dtype=np.float32)
               for sid in slots_by_sample}
    best_af = {sid: np.full(len(pet_arrays[sid][0]), np.nan, dtype=np.float32)
               for sid in slots_by_sample}

    # ---- 7. stream the per-allele netMHCpan output ------------------------
    slot_rows, binder_rows = [], []
    n_bind_total = 0
    tsv_files = sorted(PA.glob("*.tsv"))
    seen_alleles = set()
    for ai, f in enumerate(tsv_files):
        al_star = stem_to_allele(f.stem)
        seen_alleles.add(al_star)
        df = pd.read_csv(f, sep="\t", header=None, dtype=str,
                         names=["pep", "el", "ba", "aff", "allele"],
                         usecols=[0, 1, 3])
        if df.empty:
            continue
        el_arr = pd.to_numeric(df.el, errors="coerce").to_numpy(dtype=np.float32)
        af_arr = pd.to_numeric(df.aff, errors="coerce").to_numpy(dtype=np.float32)
        pep_arr = df.pep.to_numpy()
        d_el = dict(zip(pep_arr, el_arr))
        d_af = dict(zip(pep_arr, af_arr))
        targets = allele2slots.get(al_star, [])
        for sid, sname in targets:
            peps, wt, ln, gene, clon = pet_arrays[sid]
            locus = loh = ""
            hom = False
            for s2, l2, a2, lo2, h2 in slots_by_sample[sid]:
                if s2 == sname:
                    locus, loh, hom = l2, lo2, h2
                    break
            el = np.array([d_el.get(p, np.nan) for p in peps], dtype=np.float32)
            af = np.array([d_af.get(p, np.nan) for p in peps], dtype=np.float32)
            nb_pct = int(np.nansum(el <= PCT_THR))
            nb_ic50 = int(np.nansum(af <= IC50_THR))
            slot_rows.append((sid, sname, locus, al_star, loh, hom, len(peps),
                              nb_ic50, nb_pct, nb_pct))
            be = best_el[sid]
            m = el < be
            be[m] = el[m]
            best_af[sid][m] = af[m]
            for i in np.where(el <= PCT_THR)[0]:
                binder_rows.append((sid, sname, locus, al_star, loh, peps[i],
                                    wt[i], ln[i], gene[i], clon[i],
                                    round(float(af[i]), 3), round(float(el[i]), 4)))
                n_bind_total += 1
        if ai % 25 == 0:
            log(f"allele {ai+1}/{len(tsv_files)} {al_star} -> slots={len(slot_rows)} "
                f"binders={n_bind_total}")
        del df, el_arr, af_arr, pep_arr, d_el, d_af

    missing = sorted(set(allele2slots) - seen_alleles)
    log(f"all {len(tsv_files)} allele files streamed: slots={len(slot_rows)} "
        f"binders={n_bind_total} ; alleles in slots but no prediction file: {missing}")

    # ---- 8. sample-level rows ---------------------------------------------
    s_rows = []
    for sid in samples:
        if sid not in slots_by_sample:
            continue
        peps = pet_arrays[sid][0]
        n_neo_pct = int(np.nansum(best_el[sid] <= PCT_THR))
        n_neo_ic50 = int(np.nansum(best_af[sid] <= IC50_THR))
        s_rows.append((sid, mc.PATIENT_ID.get(sid), mc.CANCER_TYPE.get(sid),
                       mc.any_HLA_LOH.get(sid), mc.HLA_LOH_burden.get(sid),
                       len(peps), len(slots_by_sample[sid]), n_neo_ic50,
                       n_neo_pct, n_neo_pct, int(mut_counts.get(sid, 0)),
                       mc.TMB_SCORE.get(sid), mc.FACETS_PURITY.get(sid),
                       mc.FACETS_PLOIDY.get(sid), mc.FACETS_WGD.get(sid)))
    smp = pd.DataFrame(s_rows, columns=[
        "SAMPLE_ID", "PATIENT_ID", "CANCER_TYPE", "any_HLA_LOH",
        "HLA_LOH_burden", "n_pep", "n_alleles", "n_neo_ic50", "n_neo_pct",
        "n_neo_either", "n_mut_coding", "TMB_SCORE", "FACETS_PURITY",
        "FACETS_PLOIDY", "FACETS_WGD"])
    slt = pd.DataFrame(slot_rows, columns=[
        "SAMPLE_ID", "slot", "locus", "allele", "loh", "is_hom",
        "n_pep", "n_bind_ic50", "n_bind_pct", "n_bind_either"])
    bnd = pd.DataFrame(binder_rows, columns=[
        "SAMPLE_ID", "slot", "locus", "allele", "loh", "pep_mut",
        "pep_wt", "pep_len", "gene", "is_CLONAL", "ic50", "affinity_percentile"])
    log(f"compiled: samples={len(smp)} slots={len(slt)} binders={len(bnd)}")

    # ---- 9. write in batches (same layout as stage 2) ---------------------
    order = list(smp.SAMPLE_ID)
    batches = [order[i:i + args.batch] for i in range(0, len(order), args.batch)]
    (OD / "manifest.json").write_text(json.dumps(
        {"source": "netMHCpan-4.2e", "binding_rule": "%Rank_EL <= 2",
         "metadata_source": "V6/04_processed_data/master_cohort.tsv",
         "n_samples": len(order), "batch_size": args.batch,
         "batches": batches}, indent=1), encoding="utf-8")

    pos = {s: i for i, s in enumerate(order)}
    smp = smp.copy(); smp["_o"] = smp.SAMPLE_ID.map(pos)
    slt = slt.copy(); slt["_o"] = slt.SAMPLE_ID.map(pos)
    bnd = bnd.copy(); bnd["_o"] = bnd.SAMPLE_ID.map(pos)
    for bi, batch in enumerate(batches):
        bset = set(batch)
        a = smp[smp.SAMPLE_ID.isin(bset)].sort_values("_o").drop(columns="_o")
        b = slt[slt.SAMPLE_ID.isin(bset)].sort_values("_o").drop(columns="_o")
        c = bnd[bnd.SAMPLE_ID.isin(bset)].sort_values("_o").drop(columns="_o")
        a.to_csv(OD / f"pred_samples_{bi:05d}.tsv", sep="\t", index=False)
        b.to_csv(OD / f"pred_slots_{bi:05d}.tsv", sep="\t", index=False)
        c.to_csv(OD / f"pred_binders_{bi:05d}.tsv", sep="\t", index=False)
        (OD / f"{bi:05d}.done").write_text("ok")
        if bi % 20 == 0 or bi == len(batches) - 1:
            log(f"batch {bi+1}/{len(batches)} written")
    log(f"DONE in {time.time()-t0:.1f}s -> {OD}")


if __name__ == "__main__":
    main()
