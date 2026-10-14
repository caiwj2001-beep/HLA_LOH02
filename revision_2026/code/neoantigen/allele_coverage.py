"""
Allele coverage preflight for the HLA_LOH02 neoantigen pipeline.

Reads MSK-IMPACT clinical HLA genotype columns (HLA-A1/A2/B1/B2/C1/C2),
standardises them (hla_a_01_01_01_01 -> HLA-A*01:01, first 2 fields),
and reports how many unique alleles (and how many patients) MHCflurry 2.3.14
can actually score.

Outputs:
  output/allele_coverage.tsv   (allele, locus, n_occurrences, supported)
  output/coverage_summary.md   (human-readable summary)

Usage: env/Scripts/python.exe scripts/allele_coverage.py
"""
import os
import sys
import re
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent  # .../neoantigen
os.environ.setdefault("MHCFLURRY_DATA_DIR", str(HERE / "models"))

CLINICAL = Path("C:/Users/Administrator/科研文件/HLA_LOH02/msk_impact_50k_2026/data_clinical_patient.txt")
OUT_TSV = HERE / "output" / "allele_coverage.tsv"
OUT_MD = HERE / "output" / "coverage_summary.md"
HLA_COLS = ["HLA-A1", "HLA-A2", "HLA-B1", "HLA-B2", "HLA-C1", "HLA-C2"]


def banner(t):
    print("\n" + "=" * 78 + "\n" + t + "\n" + "=" * 78)


def is_missing(v):
    return v is None or v.strip() == "" or v.strip().upper() in {"NA", "N/A", "NAN", "NULL", "."}


def standardize_2field(raw):
    """hla_a_01_01_01_01 -> HLA-A*01:01 ; also handles 'HLA-A*01:01' and 'A*01:01'."""
    s = raw.strip()
    if "_" in s:
        toks = s.split("_")
        if len(toks) >= 4 and toks[0].lower() == "hla":
            locus = toks[1].upper()
            f1, f2 = toks[2], toks[3]
            return locus, "HLA-%s*%s:%s" % (locus, f1, f2)
        return None, None
    m = re.match(r"^(?:HLA-)?([A-Za-z0-9]+)\*(\d+):(\d+)", s)
    if m:
        locus = m.group(1).upper()
        return locus, "HLA-%s*%s:%s" % (locus, m.group(2), m.group(3))
    return None, None


def norm_supported(a):
    """Normalise a MHCflurry supported-allele string to 2-field 'HLA-L*ff:ff'."""
    s = a.strip()
    m = re.match(r"^([A-Za-z0-9]+)\*(\d+):(\d+)", s)
    if m:
        return "%s*%s:%s" % (m.group(1), m.group(2), m.group(3))
    return s


# ---------------------------------------------------------------- read clinical
banner("READ CLINICAL FILE")
print("file:", CLINICAL)
raw_rows = []
header = None
with open(CLINICAL, "r", encoding="utf-8", errors="replace") as fh:
    for line in fh:
        line = line.rstrip("\n").rstrip("\r")
        if not line:
            continue
        if line.startswith("#"):
            continue
        fields = line.split("\t")
        if header is None:
            if "PATIENT_ID" in fields:
                header = fields
            continue
        raw_rows.append(fields)
print("header:", header)
print("data rows:", len(raw_rows))

idx = {name: header.index(name) for name in HLA_COLS + ["PATIENT_ID"]}

# ---------------------------------------------------------------- standardise
banner("STANDARDISE ALLELES")
occ = Counter()                       # allele -> occurrences across patient columns
bad_format = Counter()
locus_of = {}
patients = []                         # list of dict locus->[alleles] and patient id
n_with_hla = 0
for row in raw_rows:
    pid = row[idx["PATIENT_ID"]] if idx["PATIENT_ID"] < len(row) else None
    per_locus = defaultdict(list)
    has_any = False
    for col in HLA_COLS:
        j = idx[col]
        if j >= len(row):
            continue
        v = row[j]
        if is_missing(v):
            continue
        locus, std = standardize_2field(v)
        if std is None:
            bad_format[v] += 1
            continue
        occ[std] += 1
        locus_of[std] = locus
        per_locus[locus.split("*")[0]].append(std)
        has_any = True
    if has_any:
        n_with_hla += 1
    patients.append({"pid": pid, "loci": per_locus, "has_any": has_any})

print("patients with >=1 non-NA HLA allele:", n_with_hla, "/", len(raw_rows))
print("total allele occurrences (patient-columns):", sum(occ.values()))
print("unique alleles:", len(occ))
if bad_format:
    print("UNPARSED values (top 10):", bad_format.most_common(10))
else:
    print("unparsed values: none")

# ---------------------------------------------------------------- supported set
banner("MHCflurry SUPPORTED SET")
from mhcflurry import Class1PresentationPredictor
pred = Class1PresentationPredictor.load()
supported_raw = set(pred.supported_alleles)
supported_norm = set(norm_supported(a) for a in supported_raw)
print("supported alleles (raw count):", len(supported_raw), "| normalised:", len(supported_norm))
multi = [a for a in supported_norm if a.count(":") > 1]
print("supported entries with >2 fields:", len(multi))

# ---------------------------------------------------------------- coverage
banner("COVERAGE")
unique = sorted(occ, key=lambda a: (-occ[a], a))
supported_hit = [a for a in unique if a in supported_norm]
unsupported = [a for a in unique if a not in supported_norm]
n_occ_supported = sum(occ[a] for a in supported_hit)
n_occ_total = sum(occ.values())
print("unique alleles          :", len(unique))
print("  supported by MHCflurry:", len(supported_hit), "(%.2f%%)" % (100.0 * len(supported_hit) / len(unique)))
print("  NOT supported         :", len(unsupported), "(%.2f%%)" % (100.0 * len(unsupported) / len(unique)))
print("allele-occurrences supported: %d/%d = %.2f%%" % (n_occ_supported, n_occ_total, 100.0 * n_occ_supported / n_occ_total))

# per locus
banner("PER-LOCUS COVERAGE")
locus_u = defaultdict(set)
locus_hit = defaultdict(set)
for a in unique:
    L = locus_of[a]
    locus_u[L].add(a)
    if a in supported_norm:
        locus_hit[L].add(a)
for L in sorted(locus_u):
    tot = len(locus_u[L]); hit = len(locus_hit[L])
    print("  locus %-2s : %3d unique, %3d supported (%.1f%%)" % (L, tot, hit, 100.0 * hit / tot))

banner("UNSUPPORTED ALLELES (top 20 by occurrence)")
print("%-16s %6s %6s" % ("allele", "n", "rank"))
for a in unsupported[:20]:
    print("%-16s %6d" % (a, occ[a]))

# ---------------------------------------------------------------- per-patient
banner("PER-PATIENT EVALUABILITY")
all_ok = 0
for p in patients:
    if not p["has_any"]:
        continue
    flat = [a for v in p["loci"].values() for a in v]
    if flat and all(a in supported_norm for a in flat):
        all_ok += 1
print("patients with HLA data                 :", n_with_hla)
print("patients with ALL alleles supported    : %d / %d = %.2f%%"
      % (all_ok, n_with_hla, 100.0 * all_ok / n_with_hla if n_with_hla else 0))
for L in ("A", "B", "C"):
    both = 0
    tot = 0
    for p in patients:
        al = p["loci"].get(L, [])
        if len(al) == 2:
            tot += 1
            if all(a in supported_norm for a in al):
                both += 1
    print("  locus %s: both alleles present in %5d patients; both supported: %5d (%.2f%%)"
          % (L, tot, both, 100.0 * both / tot if tot else 0))

# ---------------------------------------------------------------- write tsv
with open(OUT_TSV, "w", encoding="utf-8", newline="") as fh:
    fh.write("allele\tlocus\tn_occurrences\tfreq_pct\tsupported\n")
    for a in unique:
        fh.write("%s\t%s\t%d\t%.4f\t%s\n" % (
            a, locus_of[a], occ[a], 100.0 * occ[a] / n_occ_total,
            "yes" if a in supported_norm else "no"))
print("\nwrote", OUT_TSV)

# ---------------------------------------------------------------- write summary
with open(OUT_MD, "w", encoding="utf-8") as fh:
    w = fh.write
    w("# MHCflurry allele-coverage preflight (MSK-IMPACT 50K HLA genotypes)\n\n")
    w("Input: `%s`\n\n" % CLINICAL)
    w("Columns: %s\n\n" % ", ".join(HLA_COLS))
    w("MHCflurry version: %s (Class1PresentationPredictor.supported_alleles = %d entries)\n\n"
      % (__import__("mhcflurry").__version__, len(supported_raw)))
    w("Standardisation: `hla_a_01_01_01_01` -> 2-field `HLA-A*01:01` (extra fields dropped, as agreed).\n\n")
    w("## Headline\n\n")
    w("| metric | value |\n|---|---|\n")
    w("| patients in file | %d |\n" % len(raw_rows))
    w("| patients with >=1 non-NA HLA allele | %d |\n" % n_with_hla)
    w("| unique alleles (2-field) | %d |\n" % len(unique))
    w("| unique alleles supported by MHCflurry | %d (%.2f%%) |\n" % (len(supported_hit), 100.0 * len(supported_hit) / len(unique)))
    w("| unique alleles NOT supported | %d (%.2f%%) |\n" % (len(unsupported), 100.0 * len(unsupported) / len(unique)))
    w("| allele occurrences supported | %d/%d (%.2f%%) |\n" % (n_occ_supported, n_occ_total, 100.0 * n_occ_supported / n_occ_total))
    w("| patients with ALL alleles supported | %d/%d (%.2f%%) |\n" % (all_ok, n_with_hla, 100.0 * all_ok / n_with_hla if n_with_hla else 0))
    w("\n## Per-locus unique-allele coverage\n\n| locus | unique | supported | coverage |\n|---|---|---|---|\n")
    for L in sorted(locus_u):
        tot = len(locus_u[L]); hit = len(locus_hit[L])
        w("| %s | %d | %d | %.2f%% |\n" % (L, tot, hit, 100.0 * hit / tot))
    w("\n## Per-patient (both alleles of a locus supported)\n\n")
    for L in ("A", "B", "C"):
        both = tot = 0
        for p in patients:
            al = p["loci"].get(L, [])
            if len(al) == 2:
                tot += 1
                if all(a in supported_norm for a in al):
                    both += 1
        w("- locus %s: %d/%d patients with both alleles supported (%.2f%%)\n"
          % (L, both, tot, 100.0 * both / tot if tot else 0))
    w("\n## Top 20 unsupported alleles (by occurrence)\n\n| allele | occurrences |\n|---|---|\n")
    for a in unsupported[:20]:
        w("| %s | %d |\n" % (a, occ[a]))
    w("\nFull per-allele table: `allele_coverage.tsv`.\n")
print("wrote", OUT_MD)

banner("DONE")
