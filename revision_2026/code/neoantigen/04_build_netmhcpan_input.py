#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Stage 1b (netMHCpan input): build per-allele de-duplicated peptide lists for
the netMHCpan-4.2e re-run of the pilot neoantigen analysis.

* Pilot sample set == EXACTLY the sample set of output/predictions/pilot
  (read from that directory's manifest.json -> 2,460 samples).
* Sample -> germline HLA genotype  : msk_impact_50k_2026/data_clinical_patient.txt
  (hla_a_26_01_01_01 -> HLA-A*26:01), same normalisation as 02_predict_neoantigens.py.
* Peptides come from the frozen stage-1 table output/peptides/peptides_part_*.tsv
  (NOT rebuilt, NOT modified).

For every distinct allele we emit two files:
  mut/<allele>.pep   distinct MUTANT peptides of all samples carrying the allele
  wt/<allele>.pep    distinct WILD-TYPE peptides of all samples carrying the allele
plus a JSON manifest with the exact counts.

Outputs: neoantigen/output/netmhcpan_input/
  mut/*.pep  wt/*.pep  alleles.json  input_manifest.json
"""
import argparse
import json
import pathlib
import time

import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent
NEO = HERE.parent
PROJ = NEO.parent

PEPDIR = NEO / "output" / "peptides"
PILOT_DIR = NEO / "output" / "predictions" / "pilot"
CLIN_PAT = PROJ / "msk_impact_50k_2026" / "data_clinical_patient.txt"
OUT = NEO / "output" / "netmhcpan_input"

SLOTS = [("A", 1, "HLA-A1"), ("A", 2, "HLA-A2"),
         ("B", 1, "HLA-B1"), ("B", 2, "HLA-B2"),
         ("C", 1, "HLA-C1"), ("C", 2, "HLA-C2")]


def log(m):
    print(f"[{time.strftime('%H:%M:%S')}] {m}", flush=True)


def norm_allele(x):
    """hla_a_26_01_01 -> HLA-A*26:01  (identical to stage 2)."""
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


def nm_allele(a):
    """HLA-A*26:01 -> HLA-A26:01 (netMHCpan command-line form; '*' globs in tcsh)."""
    return a.replace("*", "") if a else None


def file_stem(a):
    """Filename-safe stem.  ':' is ILLEGAL in an NTFS filename: writing
    'HLA-A01:01.pep' on Windows silently creates a file named 'HLA-A01' plus an
    alternate data stream ':01.pep', i.e. a 0-byte visible file.  Use '_'."""
    return a.replace("*", "").replace(":", "_")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["pilot", "full"], default="pilot",
                    help="pilot = the 2,460-sample pilot arm; full = whole cohort")
    ap.add_argument("--count-only", action="store_true",
                    help="only report the (allele,peptide) counts, write nothing")
    args = ap.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "mut").mkdir(exist_ok=True)
    (OUT / "wt").mkdir(exist_ok=True)
    (OUT / "all").mkdir(exist_ok=True)

    # ---- pilot sample set (authoritative: the pilot manifest) -------------
    if args.mode == "pilot":
        man = json.loads((PILOT_DIR / "manifest.json").read_text())
        pilot_ids = [s for b in man["batches"] for s in b]
        log(f"pilot manifest: mode={man['mode']} n_samples={len(pilot_ids)}")
        # cross-check against the pilot prediction outputs actually on disk
        smp = pd.concat([pd.read_csv(f, sep="\t", dtype=str)
                         for f in sorted(PILOT_DIR.glob("pred_samples_*.tsv"))],
                        ignore_index=True)
        on_disk = set(smp.SAMPLE_ID)
        log(f"pilot pred_samples on disk: {len(on_disk)} "
            f"(manifest-only: {len(set(pilot_ids)-on_disk)}, extra: {len(on_disk-set(pilot_ids))})")
        pilot_ids = [s for s in pilot_ids if s in on_disk] or list(smp.SAMPLE_ID)
    else:
        # whole cohort: every sample that has both HLA genotype and peptides,
        # i.e. exactly the sample universe of output/peptides
        frames = []
        for fp in sorted(PEPDIR.glob("peptides_part_*.tsv")):
            d = pd.read_csv(fp, sep="\t", dtype=str, usecols=["SAMPLE_ID"])
            frames.append(d)
        pilot_ids = sorted(set(pd.concat(frames, ignore_index=True).SAMPLE_ID))
        smp = pd.DataFrame({"SAMPLE_ID": pilot_ids,
                            "PATIENT_ID": [s.split("-T")[0] for s in pilot_ids]})
        log(f"mode=full: {len(pilot_ids)} samples with HLA genotype AND peptides")
    log(f"working set: {len(pilot_ids)} samples")

    # ---- peptides ---------------------------------------------------------
    frames = []
    for fp in sorted(PEPDIR.glob("peptides_part_*.tsv")):
        d = pd.read_csv(fp, sep="\t", dtype=str,
                        usecols=["SAMPLE_ID", "pep_mut", "pep_wt", "pep_len",
                                 "is_CLONAL"])
        d = d[d.SAMPLE_ID.isin(set(pilot_ids))]
        if len(d):
            frames.append(d)
    pet = pd.concat(frames, ignore_index=True)
    pet = pet.drop_duplicates(subset=["SAMPLE_ID", "pep_mut"])
    log(f"pilot peptide rows (dedup by sample x pep_mut): {len(pet)} "
        f"over {pet.SAMPLE_ID.nunique()} samples")

    # ---- germline genotype ------------------------------------------------
    pat = pd.read_csv(CLIN_PAT, sep="\t", comment="#", dtype=str)
    pat_alleles = {}
    for r in pat.itertuples(index=False):
        pid = r[0]
        pat_alleles[pid] = {sname: norm_allele(r[6 + i])
                            for i, (_, _, sname) in enumerate(SLOTS)}

    sid_pid = smp.set_index("SAMPLE_ID").PATIENT_ID.to_dict()

    # ---- group peptides by allele ----------------------------------------
    mut_by_al, wt_by_al = {}, {}
    pairs_mut = pairs_wt = 0
    n_no_gt = 0
    for sid, g in pet.groupby("SAMPLE_ID", sort=False):
        pid = sid_pid.get(sid)
        als = pat_alleles.get(pid)
        if not als:
            n_no_gt += 1
            continue
        uniq = {a for a in als.values() if a}
        if not uniq:
            n_no_gt += 1
            continue
        m = g.pep_mut.dropna().unique()
        w = g.pep_wt.dropna().unique()
        for a in uniq:
            dm = mut_by_al.setdefault(a, set())
            dw = wt_by_al.setdefault(a, set())
            dm.update(m.tolist())
            dw.update(w.tolist())
            pairs_mut += len(m)
            pairs_wt += len(w)
    log(f"samples without usable genotype: {n_no_gt}")
    log(f"distinct alleles in pilot: {len(mut_by_al)}")
    log(f"peptide-allele pairs: mut={pairs_mut}, wt={pairs_wt}")

    stats = []
    for a in sorted(mut_by_al):
        stem = file_stem(a)
        pm = OUT / "mut" / f"{stem}.pep"
        pw = OUT / "wt" / f"{stem}.pep"
        pu = OUT / "all" / f"{stem}.pep"
        ml = sorted(mut_by_al[a])
        wl = sorted(wt_by_al[a])
        ul = sorted(set(ml) | set(wl))
        if not args.count_only:
            # NOTE: open() in text mode translates '\n' to os.linesep on Windows,
            # which silently turns every 9-mer into a 10-char string ending in
            # '\r' and makes netMHCpan predict the wrong thing.  Always write
            # with newline='\n'.
            for path, seqs in ((pm, ml), (pw, wl), (pu, ul)):
                with open(path, "w", encoding="utf-8", newline="\n") as fh:
                    fh.write("\n".join(seqs) + "\n")
        stats.append({"allele": a, "nm_allele": nm_allele(a),
                      "n_mut_unique": len(ml), "n_wt_unique": len(wl),
                      "n_union_unique": len(ul),
                      "n_overlap_mut_wt": len(ml) + len(wl) - len(ul),
                      "file_mut": str(pm.relative_to(NEO)),
                      "file_wt": str(pw.relative_to(NEO)),
                      "file_union": str(pu.relative_to(NEO))})
    sfx = f"_countonly_{args.mode}" if args.count_only else ""
    (OUT / f"alleles{sfx}.json").write_text(json.dumps(stats, indent=1),
                                            encoding="utf-8")
    tot_m = sum(s["n_mut_unique"] for s in stats)
    tot_w = sum(s["n_wt_unique"] for s in stats)
    tot_u = sum(s["n_union_unique"] for s in stats)
    (OUT / f"input_manifest{sfx}.json").write_text(json.dumps(
        {"mode": args.mode, "count_only": args.count_only,
         "pilot_samples": len(pilot_ids), "n_alleles": len(stats),
         "pairs_mut": pairs_mut, "pairs_wt": pairs_wt,
         "unique_pairs_mut": tot_m, "unique_pairs_wt": tot_w,
         "unique_pairs_union": tot_u,
         "overlap_mut_wt": tot_m + tot_w - tot_u,
         "dedup_reduction_mut": 1 - tot_m / pairs_mut if pairs_mut else None,
         "samples_without_genotype": n_no_gt}, indent=1), encoding="utf-8")
    log(f"unique pairs after per-allele dedup: mut={tot_m}, wt={tot_w}, "
        f"union={tot_u} (overlap {tot_m + tot_w - tot_u})")
    log(f"-> {OUT}")


if __name__ == "__main__":
    main()
