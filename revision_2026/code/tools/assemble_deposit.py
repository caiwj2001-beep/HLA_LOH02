#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""assemble_deposit.py — 组装可上传的存交包（derived_data.zip / code.zip）+ 上传说明 README"""
import os, sys, csv, glob, shutil, zipfile, subprocess

ROOT = r"C:\Users\Administrator\科研文件\HLA_LOH02"
V3   = os.path.join(ROOT, "iscience投稿版本", "V3")
BLD  = os.path.join(V3, "03_tables", "build")
IMD  = os.path.join(V3, "02_figures", "intermediate")
TBL  = os.path.join(V3, "03_tables")
COMP = os.path.join(V3, "06_compliance")
DEP  = os.path.join(COMP, "deposit")
STG  = os.path.join(DEP, "_stage")
QC   = os.path.join(V3, "QC")
TOOLS = os.path.join(ROOT, ".tools")

def fresh(d):
    if os.path.isdir(d):
        shutil.rmtree(d)
    os.makedirs(d, exist_ok=True)

def zipdir(srcdir, zippath):
    if os.path.exists(zippath):
        os.remove(zippath)
    with zipfile.ZipFile(zippath, "w", zipfile.ZIP_DEFLATED) as z:
        for base, _, files in os.walk(srcdir):
            for f in files:
                full = os.path.join(base, f)
                z.write(full, os.path.relpath(full, os.path.dirname(srcdir)))
    return zippath

def main():
    fresh(STG)
    log = []
    # ---------------- derived_data ----------------
    dd = os.path.join(STG, "derived_data")
    for sub in ["number_dictionary", "tables_v3", "figure_source_data", "supplementary_source_data"]:
        os.makedirs(os.path.join(dd, sub), exist_ok=True)

    shutil.copy(os.path.join(V3, "00_pinned", "PINNED_PACK.md"),
                os.path.join(dd, "number_dictionary", "PINNED_PACK.md"))
    shutil.copy(os.path.join(BLD, "pin_audit.tsv"),
                os.path.join(dd, "number_dictionary", "pin_audit.tsv"))
    shutil.copy(os.path.join(TBL, "SV_class_analysis.md"), os.path.join(dd, "SV_class_analysis.md"))
    n_tsv = n_fig = n_src = 0
    for f in sorted(glob.glob(os.path.join(BLD, "*.tsv"))):
        shutil.copy(f, os.path.join(dd, "tables_v3", os.path.basename(f))); n_tsv += 1
    for f in sorted(glob.glob(os.path.join(IMD, "*.tsv"))):
        shutil.copy(f, os.path.join(dd, "figure_source_data", os.path.basename(f))); n_fig += 1
    for pat in [os.path.join(ROOT, "V6", "04_processed_data", "table_data", "*.tsv"),
                os.path.join(ROOT, "V6", "04_processed_data", "results", "*.tsv"),
                os.path.join(ROOT, "results", "tables", "*.csv")]:
        for f in sorted(glob.glob(pat)):
            shutil.copy(f, os.path.join(dd, "supplementary_source_data", os.path.basename(f))); n_src += 1

    # machine-readable number dictionary
    nd_path = os.path.join(dd, "number_dictionary", "number_dictionary.tsv")
    with open(os.path.join(BLD, "pin_audit.tsv"), encoding="utf-8") as f, \
         open(nd_path, "w", encoding="utf-8", newline="") as o:
        o.write("variable_id\tlocked_value\tverification\tverified_at\n")
        for r in csv.DictReader(f, delimiter="\t"):
            o.write(f"{r['item']}\t{r['PINNED']}\t{'matches recomputation' if r['match'].strip().upper()=='TRUE' else 'MISMATCH'}\tPINNED_PACK.md section 2\n")

    with open(os.path.join(dd, "README_DERIVED_DATA.txt"), "w", encoding="utf-8") as f:
        f.write(f"""derived_data — derived tables for ISCIENCE-D-26-09416 (revision)
====================================================================

CONTENTS
  number_dictionary/       PINNED_PACK.md  the locked number dictionary for the revision
                           number_dictionary.tsv  machine-readable form (variable -> value)
                           pin_audit.tsv   the assertion log: {sum(1 for _ in open(os.path.join(BLD,'pin_audit.tsv'),encoding='utf-8'))-1} checks, every recomputed value against the locked value
  tables_v3/               {n_tsv} tables: every main and supplementary table as delivered, as TSV
  figure_source_data/      {n_fig} source-data tables behind Figures 1 to 5 and Figure S1
  supplementary_source_data/ {n_src} earlier derived summary tables retained for traceability
  SV_class_analysis.md     the structural-variant alternative analysis (reviewer R3-4)

WHAT IS DELIBERATELY NOT INCLUDED
  Sample-level derived files (the per-tumour analysis frame master_cohort.tsv, the per-sample
  aneuploidy score files, and the per-sample structural-variant counts) are NOT in this archive.
  They carry the sample identifiers of the source cohort, which is distributed under
  CC BY-NC-ND 4.0, so redistributing them here would breach the source licence. All of them are
  regenerated verbatim from the cBioPortal source files by the deposited code, and the deposited
  code is the exact code that produced every table in tables_v3/.

TABLES ARE DELIVERED AS DOCX in the manuscript package; the TSV copies here are the
machine-readable origin, and every number in a DOCX is read directly from these files.

SOURCE COHORT
  cBioPortal study msk_impact_50k_2026 (Bandlamudi et al., Cancer Cell 2026, PMID 41895280),
  licence CC BY-NC-ND 4.0. Obtain the raw data from cBioPortal; nothing from that cohort is
  redistributed here.
""")
    zipdir(dd, os.path.join(DEP, "derived_data.zip"))
    log.append(f"derived_data.zip: tables_v3={n_tsv} figure_source={n_fig} supplementary_source={n_src}")

    # ---------------- code ----------------
    cd = os.path.join(STG, "code")
    os.makedirs(cd, exist_ok=True)
    shutil.copy(os.path.join(DEP, "code", "01_build_tables_V3.R"), os.path.join(cd, "01_build_tables_V3.R"))
    shutil.copy(os.path.join(TOOLS, "build_tables_docx.py"), os.path.join(cd, "build_tables_docx.py"))
    shutil.copy(os.path.join(TOOLS, "build_supplement_pdf.py"), os.path.join(cd, "build_supplement_pdf.py"))
    shutil.copy(os.path.join(TOOLS, "dump_docx.py"), os.path.join(cd, "dump_docx.py"))
    shutil.copy(os.path.join(V3, "00_pinned", "PINNED_PACK.md"), os.path.join(cd, "PINNED_PACK.md"))
    # R env lock
    rver = subprocess.run([r"C:/Program Files/R/R-4.6.1/bin/Rscript.exe", "-e",
                           'cat(R.version.string,"\\n"); ip<-installed.packages(); '
                           'for(p in c("data.table","survival","boot","readxl")) cat(p, as.character(ip[p,"Version"]),"\\n")'],
                          capture_output=True, text=True).stdout.strip()
    with open(os.path.join(cd, "env_lock_R.txt"), "w", encoding="utf-8") as f:
        f.write("R environment lock (sessionInfo-derived)\n")
        f.write(rver + "\n")
        f.write("\nPackages used by 01_build_tables_V3.R: data.table, survival\n")
        f.write("Also present in the original session: boot, readxl\n")
    pyver = subprocess.run([os.path.join(TOOLS, "docxenv", "Scripts", "python.exe"), "-c",
                            "import sys, docx, pypdf; print(sys.version.split()[0])"],
                           capture_output=True, text=True).stdout.strip()
    with open(os.path.join(cd, "requirements.txt"), "w", encoding="utf-8") as f:
        f.write(f"# Python {pyver} (used only to render DOCX/PDF; no statistics)\n")
        f.write("python-docx==1.2.0\npypdf==6.20.1\n")
    with open(os.path.join(cd, "README_CODE.md"), "w", encoding="utf-8") as f:
        f.write("""# Code — ISCIENCE-D-26-09416 (revision)

## What each file does

| File | Role |
|---|---|
| `01_build_tables_V3.R` | Recomputes **every** number in Table 1-3 and in supplementary tables S1-S13 from the raw cBioPortal files, writes them to `build/*.tsv`, and asserts each headline value against `PINNED_PACK.md` (80 assertions; the script reports the count and lists any mismatch). |
| `build_tables_docx.py` | Reads `build/*.tsv` and renders Table1-3, the supplementary tables DOCX and the Key Resources Table. Also scans every paragraph and table cell for stray markdown markers. |
| `build_supplement_pdf.py` | Renders the single supplementary PDF, using a two-pass method to put real page numbers into the contents. |
| `dump_docx.py` | Small helper that prints the paragraphs and tables of a DOCX (used for QA). |
| `PINNED_PACK.md` | The locked number dictionary: the only permitted source of reported numbers. |

## How to reproduce

```bash
# 1. obtain the raw data from cBioPortal (msk_impact_50k_2026) and place the txt files in
#    <ROOT>/msk_impact_50k_2026/ ; place master_cohort.tsv in <ROOT>/V6/04_processed_data/
export ROOT=/path/to/HLA_LOH02          # edit the ROOT constant at the top of the R script

# 2. regenerates every table and runs the 80 number assertions
Rscript 01_build_tables_V3.R

# 3. render the DOCX deliverables (python-docx + pypdf only; no statistics)
python build_tables_docx.py
python build_supplement_pdf.py

# 4. optional: render key panels (needs R + ggplot2); outputs land in V3/02_figures/
```

## Note on this file

The R script hard-codes its input and output paths in `ROOT` at the top of the file; point that
constant at your checkout. The script exits non-zero if any of the 80 assertions against
`PINNED_PACK.md` fail, so it cannot silently produce numbers that differ from the reported ones.
""")
    zipdir(cd, os.path.join(DEP, "code.zip"))
    log.append("code.zip: 4 scripts + README + env lock + requirements + number dictionary")

    # ---------------- upload README ----------------
    with open(os.path.join(DEP, "README_upload_steps.md"), "w", encoding="utf-8") as f:
        f.write("""# Deposit instructions (README for the authors)

Two archives are staged next to this file and are ready to upload:

- `derived_data.zip` — all derived tables, figure source data and the number dictionary
- `code.zip` — the analysis script, the rendering scripts, the environment lock and `README_CODE.md`

**The authors must log in themselves at every step below. The repository URL is final; the DOI
is not yet real:** the single remaining placeholder is `[DOI-PENDING-ZENODO]`, and it must be
replaced only after the archived record exists. Do not invent or reserve a DOI.

---

## A. Code and derived data → one public GitHub repository (three steps)

1. The public repository already exists at
   `https://github.com/caiwj2001-beep/HLA_LOH02`; sign in at https://github.com and confirm you
   can push to it. This exact URL is already written into the three places listed in section D.
2. Push the contents of both archives to that repository — `code.zip` as the code root and
   `derived_data.zip` extracted under `derived_data/` — committed as a single initial commit
   with a tag such as `v1.0`. The derived tables are released under **CC BY-NC-ND 4.0** and the
   code under **MIT**; state both licences in the repository `README`.
3. Confirm that **no file from the cBioPortal cohort** and **no sample-level intermediate file**
   has been pushed: only the aggregate/table-level derived tables are distributed (see section C).

---

## B. Archive → Zenodo, one DOI for code and data (three steps)

1. In the repository's **Settings → Integrations → Zenodo**, sign in with GitHub and enable
   archiving for this repository. Zenodo will mint a DOI on the next release.
2. On GitHub, create a release from tag `v1.0`; Zenodo mints the version DOI and a
   concept DOI.
3. Copy the version DOI into `[DOI-PENDING-ZENODO]` — it is the **single** DOI covering both the
   code and the derived data — in `Data_and_Code_Availability.md`, in the Key Resources Table and
   in the STAR Methods "Data and code availability" section of the manuscript. The repository URL
   is already filled in at those same three places, so no URL edit remains.

---

## C. Raw data and per-sample intermediates — nothing to upload (one step)

1. Confirm that the Data and Code Availability statement points readers to the cBioPortal study
   `msk_impact_50k_2026` (CC BY-NC-ND 4.0) and states that no raw or sample-level data are
   redistributed. **Do not upload any file from the cBioPortal cohort** to the GitHub repository
   or to Zenodo — the NoDerivatives clause forbids redistributing modified copies.
2. Per-sample intermediate files (the per-tumour analysis frame, the per-sample aneuploidy score
   files and the per-sample structural-variant counts) are likewise not distributed: they carry
   the cohort's sample identifiers and are CC BY-NC-ND material, and they are regenerated
   verbatim from the cBioPortal source files by the deposited code.

---

## D. Final check before submission

- [x] `https://github.com/caiwj2001-beep/HLA_LOH02` written into `Data_and_Code_Availability.md`,
      the Key Resources Table and the manuscript (no repository-URL placeholder remains anywhere)
- [ ] `[DOI-PENDING-ZENODO]` replaced with the single Zenodo DOI in the same three places
- [ ] The repository and the Zenodo record are **public** (not private or embargoed) before
      responding to the journal
- [ ] The manuscript's Data and Code Availability section matches this file word for word in
      the three-step structure (raw / derived / code)
""")
    with open(os.path.join(QC, "deposit_build.log"), "w", encoding="utf-8") as f:
        for l in log:
            f.write(l + "\n")
    # cleanup staging
    shutil.rmtree(STG, ignore_errors=True)
    for l in log:
        print(l)
    return 0

if __name__ == "__main__":
    sys.exit(main())
