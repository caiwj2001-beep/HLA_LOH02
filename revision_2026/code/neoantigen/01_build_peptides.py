#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Stage 1: build the mutation-peptide table for the main cohort.

Steps
  1. Load main cohort (analysis_primary == TRUE) from V6 master_cohort.tsv.
  2. Load MSK-IMPACT mutations, keep only main-cohort samples, count every
     Variant_Classification, keep Missense_Mutation for peptide generation.
  3. Map RefSeq NM_ (version stripped) -> NP_ via nm_to_np_gene2refseq_raw.tsv,
     then pull only the needed NP_ sequences out of the 15 human.*.protein.faa.gz.
  4. Validate the HGVSp_Short reference residue against the NP_ sequence
     (mandatory QC).  Mismatches are logged separately.
  5. Emit every 9-mer and 10-mer spanning the mutated residue (mutant + WT),
     de-duplicated per sample, written as chunked TSV.

Outputs (all under neoantigen/output/peptides/):
  peptides_part_XXXXX.tsv     chunked peptide table
  validation_fail.tsv         per-mutation QC failures
  stage1_summary.json         all headline numbers
"""
import gzip
import json
import pathlib
import re
import sys
import time

import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent          # neoantigen/scripts
NEO = HERE.parent                                        # neoantigen/
PROJ = NEO.parent                                        # HLA_LOH02/
OUT = NEO / "output" / "peptides"
REF = pathlib.Path("E:/数据库汇总/refseq_human_protein")

MASTER = PROJ / "V6" / "04_processed_data" / "master_cohort.tsv"
MUT = PROJ / "msk_impact_50k_2026" / "data_mutations.txt"
NM2NP = REF / "nm_to_np_gene2refseq_raw.tsv"

CHUNK_SAMPLES = 2000
COLS = ["SAMPLE_ID", "GENE", "RefSeq", "HGVSp_Short", "pep_mut", "pep_wt",
        "pep_len", "is_CLONAL"]

AA3 = {
    'Ala': 'A', 'Arg': 'R', 'Asn': 'N', 'Asp': 'D', 'Cys': 'C', 'Gln': 'Q',
    'Glu': 'E', 'Gly': 'G', 'His': 'H', 'Ile': 'I', 'Leu': 'L', 'Lys': 'K',
    'Met': 'M', 'Phe': 'F', 'Pro': 'P', 'Ser': 'S', 'Thr': 'T', 'Trp': 'W',
    'Tyr': 'Y', 'Val': 'V', 'Ter': '*', 'Sec': 'U', 'Pyl': 'O',
}
MISSENSE_RE = re.compile(r'^p\.([A-Z])(\d+)([A-Z])$')

# every classification we treat as "coding" for the counting report
CODING_TYPES = [
    'Missense_Mutation', 'Nonsense_Mutation', 'Frame_Shift_Del',
    'Frame_Shift_Ins', 'In_Frame_Del', 'In_Frame_Ins', 'Splice_Site',
    'Translation_Start_Site', 'Nonstop_Mutation',
]


def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def load_master():
    mc = pd.read_csv(MASTER, sep="\t", dtype=str, low_memory=False)
    main = mc[mc.analysis_primary == "TRUE"].copy()
    log(f"main cohort: {len(main)} samples (of {len(mc)} rows)")
    return main


def build_nm2np():
    m = {}
    with open(NM2NP, encoding="utf-8") as fh:
        for line in fh:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 4:
                nm = p[2].split(".")[0]
                if nm not in m:
                    m[nm] = p[3]
    log(f"NM->NP mapping loaded: {len(m)} unique NM_ accessions")
    return m


def load_proteins(needed_np):
    """stream all 15 faa.gz, keep only needed NP_ -> sequence."""
    needed = set(needed_np)
    seqs = {}
    files = sorted(REF.glob("human.*.protein.faa.gz"),
                   key=lambda p: int(p.name.split('.')[1]))
    total_seen = 0
    for fp in files:
        with gzip.open(fp, "rt", encoding="utf-8") as fh:
            acc = None
            buf = []
            for line in fh:
                if line.startswith(">"):
                    if acc is not None and acc in needed:
                        seqs[acc] = "".join(buf)
                    acc = line[1:].split()[0]
                    buf = []
                    total_seen += 1
                else:
                    buf.append(line.strip())
            if acc is not None and acc in needed:
                seqs[acc] = "".join(buf)
        log(f"  {fp.name}: scanned, running total proteins={total_seen}, "
            f"wanted-seqs-found={len(seqs)}/{len(needed)}")
        if len(seqs) == len(needed):
            break
    log(f"protein scan done: {total_seen} sequences seen, "
        f"{len(seqs)}/{len(needed)} needed NP_ recovered")
    return seqs


def windows(seq, pos, alt, extra_residue_ok=True):
    """Return list of (pep_mut, pep_wt, length) spanning 1-based `pos`.

    seq is the WT protein sequence, pos the mutated residue (1-based),
    alt the mutant residue."""
    i = pos - 1
    wt = seq
    mut = seq[:i] + alt + seq[i + 1:]
    n = len(seq)
    out = []
    for L in (9, 10):
        for s in range(max(0, i - L + 1), min(i, n - L) + 1):
            pm = mut[s:s + L]
            pw = wt[s:s + L]
            if len(pm) != L or len(pw) != L:
                continue
            out.append((pm, pw, L))
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    t0 = time.time()

    main_df = load_master()
    main_ids = set(main_df.SAMPLE_ID)
    nm2np = build_nm2np()

    log("reading mutations ...")
    mut = pd.read_csv(MUT, sep="\t", dtype=str, low_memory=False,
                      usecols=["Tumor_Sample_Barcode", "Hugo_Symbol",
                               "Variant_Classification", "RefSeq",
                               "HGVSp_Short", "Protein_position",
                               "ASCN.CLONAL"])
    # NOTE: pandas returns usecols in FILE order, not in the order given here.
    # Rename the dotted column so every access below is by name, never by index.
    mut = mut.rename(columns={"ASCN.CLONAL": "ASCN_CLONAL"})
    log(f"mutation columns (file order): {list(mut.columns)}")
    mut = mut[mut.Tumor_Sample_Barcode.isin(main_ids)].copy()
    log(f"mutations in main cohort: {len(mut)} rows, "
        f"{mut.Tumor_Sample_Barcode.nunique()} samples")

    vc_counts = mut.Variant_Classification.value_counts().to_dict()
    log("Variant_Classification counts: " + json.dumps(vc_counts))

    mm = mut[mut.Variant_Classification == "Missense_Mutation"].copy()
    log(f"missense rows: {len(mm)}")

    # parse HGVSp_Short
    parsed = mm.HGVSp_Short.fillna("").str.match(MISSENSE_RE)
    n_unparsed = int((~parsed).sum())
    mm = mm[parsed].copy()
    mm["nm"] = mm.RefSeq.str.replace(r"\..*$", "", regex=True)
    n_refseq_null = int(mm.nm.isna().sum())
    mm = mm[mm.nm.notna()].copy()
    mm["np"] = mm.nm.map(nm2np)
    n_nomap = int(mm.np.isna().sum())
    mm = mm[mm.np.notna()].copy()
    mm["NP_ver"] = mm.np
    mm["np_base"] = mm.np.str.split(".").str[0]
    log(f"after parse/map: {len(mm)} missense (unparsed={n_unparsed}, "
        f"refseq_na={n_refseq_null}, nm_wo_np={n_nomap})")
    log(f"unique NP_ needed: {mm.NP_ver.nunique()}")

    seqs = load_proteins(mm.NP_ver.unique())

    # ---- validate + generate ----
    fail_rows = []
    recs = []
    n_pass = 0
    n_fail_mismatch = 0
    n_fail_range = 0
    n_fail_noseq = 0
    n_val_attempt = 0
    n_peps = 0
    per_sample = {}

    m = MISSENSE_RE
    for row in mm.itertuples(index=False):
        npv = row.NP_ver
        seq = seqs.get(npv)
        if seq is None:
            n_fail_noseq += 1
            continue
        g = m.match(row.HGVSp_Short)
        ref, pos, alt = g.group(1), int(g.group(2)), g.group(3)
        n_val_attempt += 1
        if pos < 1 or pos > len(seq):
            n_fail_range += 1
            if len(fail_rows) < 5000:
                fail_rows.append((row.Tumor_Sample_Barcode, row.Hugo_Symbol,
                                  row.RefSeq, row.HGVSp_Short, npv, "out_of_range",
                                  f"len={len(seq)}"))
            continue
        obs = seq[pos - 1]
        if obs != ref:
            n_fail_mismatch += 1
            if len(fail_rows) < 5000:
                fail_rows.append((row.Tumor_Sample_Barcode, row.Hugo_Symbol,
                                  row.RefSeq, row.HGVSp_Short, npv, "ref_mismatch",
                                  f"hgvsp_ref={ref} np_res={obs}"))
            continue
        n_pass += 1
        clonal = ("CLONAL" if str(row.ASCN_CLONAL) == "CLONAL" else
                  ("SUBCLONAL" if str(row.ASCN_CLONAL) == "SUBCLONAL"
                   else "INDETERMINATE"))
        for pm, pw, L in windows(seq, pos, alt):
            recs.append((row.Tumor_Sample_Barcode, row.Hugo_Symbol, row.RefSeq,
                         row.HGVSp_Short, pm, pw, L, clonal))
            n_peps += 1

    log(f"validation: attempted={n_val_attempt} pass={n_pass} "
        f"mismatch={n_fail_mismatch} out_of_range={n_fail_range} "
        f"no_seq={n_fail_noseq}")
    pass_rate = n_pass / n_val_attempt * 100 if n_val_attempt else 0.0
    log(f"reference-residue validation pass rate = {pass_rate:.2f}%")

    # ---- dedupe per sample & write chunks ----
    pet = pd.DataFrame(recs, columns=COLS)
    del recs
    log(f"raw peptide rows: {len(pet)}")
    log("is_CLONAL distribution (raw): "
        + json.dumps(pet.is_CLONAL.value_counts().to_dict()))
    before = len(pet)
    # keep one row per (sample, peptide); a peptide counts as CLONAL when ANY
    # generating mutation is clonal (CLONAL > SUBCLONAL > INDETERMINATE)
    rank = {"CLONAL": 2, "SUBCLONAL": 1, "INDETERMINATE": 0}
    pet["_r"] = pet.is_CLONAL.map(rank).fillna(0)
    pet = (pet.sort_values("_r", ascending=False)
              .drop_duplicates(subset=["SAMPLE_ID", "pep_mut", "pep_len"])
              .drop(columns="_r"))
    log(f"after per-sample peptide dedupe: {len(pet)} ({before - len(pet)} dropped)")
    log("is_CLONAL distribution (deduped): "
        + json.dumps(pet.is_CLONAL.value_counts().to_dict()))

    samples = sorted(pet.SAMPLE_ID.unique())
    n_files = 0
    total_bytes = 0
    for ci in range(0, len(samples), CHUNK_SAMPLES):
        sub_ids = set(samples[ci:ci + CHUNK_SAMPLES])
        sub = pet[pet.SAMPLE_ID.isin(sub_ids)]
        fp = OUT / f"peptides_part_{ci // CHUNK_SAMPLES:05d}.tsv"
        sub.to_csv(fp, sep="\t", index=False)
        n_files += 1
        total_bytes += fp.stat().st_size
    log(f"wrote {n_files} chunk files, total {total_bytes/1e6:.1f} MB")

    if fail_rows:
        pd.DataFrame(fail_rows, columns=[
            "SAMPLE_ID", "GENE", "RefSeq", "HGVSp_Short", "NP", "reason",
            "detail"]).to_csv(OUT / "validation_fail.tsv", sep="\t", index=False)

    summary = {
        "main_cohort_samples": int(len(main_df)),
        "samples_with_mutations": int(mut.Tumor_Sample_Barcode.nunique()),
        "mutations_in_main_cohort": int(len(mut)),
        "variant_classification_counts": {k: int(v) for k, v in vc_counts.items()},
        "coding_mutation_counts": {k: int(vc_counts.get(k, 0)) for k in CODING_TYPES},
        "missense_rows": int(len(mm) + n_unparsed + n_refseq_null + n_nomap),
        "missense_unparsed_hgvsp": n_unparsed,
        "missense_refseq_null": n_refseq_null,
        "missense_nm_without_np": n_nomap,
        "unique_NP_used": int(mm.NP_ver.nunique()),
        "validation_attempted": n_val_attempt,
        "validation_pass": n_pass,
        "validation_fail_ref_mismatch": n_fail_mismatch,
        "validation_fail_out_of_range": n_fail_range,
        "validation_fail_no_sequence": n_fail_noseq,
        "validation_pass_rate_pct": round(pass_rate, 4),
        "peptide_rows_raw": int(before),
        "peptide_rows_dedup": int(len(pet)),
        "peptide_rows_dropped_by_dedupe": int(before - len(pet)),
        "samples_covered_by_peptide_table": int(pet.SAMPLE_ID.nunique()),
        "peptide_chunk_files": n_files,
        "peptide_table_bytes": int(total_bytes),
        "wall_seconds": round(time.time() - t0, 1),
    }
    (NEO / "output" / "peptides" / "stage1_summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    log("stage1_summary.json written")
    print(json.dumps(summary, indent=2, ensure_ascii=False))

    if pass_rate < 90:
        log("!! PASS RATE < 90% -- STOPPING as instructed")
        sys.exit(3)


if __name__ == "__main__":
    main()
