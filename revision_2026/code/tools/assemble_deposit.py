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
    with open(os.path.join(cd, "README_CODE.md"), "w", encoding="utf-8", newline="") as f:
        f.write(r"""# `revision_2026/code/` — code for the iScience revision

Manuscript **ISCIENCE-D-26-09416**. Every script that produces a number or a figure in the
revision is here. The R analysis scripts hard-code their `ROOT` at the top of the file; point that
constant at your checkout.

This directory is the code half of the **single public snapshot** promised in *Data and Code
Availability*: the same tree is deposited as `06_compliance/deposit/code.zip` (see
`../data/FINAL_MANIFEST.md` for the frozen-package manifest).

**This file is shipped in two places, and the two copies are byte-identical**: the repository copy
(`revision_2026/code/README_CODE.md`) and the deposit copy inside `code.zip`
(`code/README_CODE.md`). That is a deliberate and verified property — see §6.

---

## 1. Layout

| Path | Contents |
|---|---|
| `build_tables/` | `01_build_tables_V3.R` — recomputes **every** Table 1–3 and supplementary table S1–S13 number from the raw cBioPortal files, writes `build/*.tsv`, and asserts each headline value against `PINNED_PACK.md` (80 assertions; the script reports the count and lists any mismatch, and exits non-zero on any mismatch). `build_tables_docx.py`, `build_supplement_pdf.py`, `dump_docx.py` render the DOCX/PDF deliverables from those TSVs (`build_tables_docx.py` also renders the Key Resources Table and `Data_and_Code_Availability.md`, and scans every paragraph and table cell for stray markdown markers). |
| `analysis/v1_scripts/` | Original v1 pipeline (`01`–`07`), kept for provenance. |
| `analysis/v6_scripts/` | Cohort build and core analysis (`03_build_cohort.R`, `04_core_analysis.R`, `06_table_data.R`, `13_sensitivity_mediation.R`, `15_germline_zygosity.R`, …). |
| `analysis/revision_r3/` | Reviewer-3 revision analyses: aneuploidy-score construction and modelling (`r3p2_*`), arm-independent mechanism and 41-arm ranking (`r3p3_*`), purity/coverage/panel reliability models (`r3p4_*`). |
| `figures/` | Figure script set: `00_recompute_inputs.R` builds every input table, `10_fig1.R`…`70_figS2.R` draw Figures 1–5, S1 and S2, `90_qa_overlap.R` programmatically checks label overlap/clipping, `99_run_all.R` runs the set, `fig_common.R` holds shared helpers; `01_mediation_boot.R` and `02_recompute_apobec.R` recompute the mediated effect and the APOBEC tail statistics used in Figures 2 and S1. |
| `neoantigen/` | netMHCpan-4.2e (primary) and MHCflurry (secondary) pipelines: peptide construction, prediction, statistics and consistency checks. `run_netmhcpan_*_host.sh` and `vm_full_runner.sh` drive the Linux guest that runs netMHCpan. |
| `tools/` | Deposit-package build scripts (from the project's `.tools/`): `assemble_deposit.py` builds `code.zip` / `derived_data.zip` and their READMEs, `surgical_zip_rebuild_one.py` / `surgical_zip_rebuild_raw.py` replace individual zip members without rebuilding the archive (copying each untouched member's raw local record byte-for-byte), `_sync_readme_template.py` syncs the upload-steps README into the deposit. |
| `env/` | `env_lock_R.txt` (R 4.6.1 session, package-by-package), `requirements.txt` (Python rendering deps), `renv.lock` (v1, R 4.3.3; also kept at the repository root). |
| `PINNED_PACK.md` | The locked number dictionary — the only permitted source of reported numbers; byte-identical to the copy inside both deposit archives. |
| `PINNED_PACK_CORRECTIONS.md` | Corrections and audit record for the locked pack; **§(v) is the authoritative figure-renumbering record**, §(vi) the pre-submission blocker fixes, §(vii) the closing-round fixes and their honest deviations. |
| `README_CODE.md` | This file (also shipped as `code/README_CODE.md` inside `code.zip`). |

Files that the round-trip needs but that live with the submission package rather than in this
directory, because they render package deliverables from the manuscript markdown or operate on the
deposit archives: `V3/QC/make_revision_docx.py` (builds `HLA_LOH02_revision_CLEAN.docx` and
`HLA_LOH02_revision_MARKED.docx` from `V3/01_manuscript/*.md`),
`V3/05_response/build_response_docx.py` (response letter), `V3/07_cover/build_cover_docx.py`
(cover letter), and — as submission-package tooling — `V3/QC/tools/surgical_zip.py` (replace
individual archive members without recompressing the rest) and `V3/QC/tools/fill_doi.py`
(one-click, idempotent back-fill of the single `[DOI-PENDING-ZENODO]` placeholder in all nine
delivery positions, with `--dry-run`; see `V3/QC/DOI_FILLIN_CHECKLIST.md`). None of them is a member
of `code.zip`; §3 records the interpreter the DOCX builders must be run with.

## 2. Order of execution

```bash
# --- 0. inputs (not redistributed; see ../README.md) ---
#   <ROOT>/msk_impact_50k_2026/*.txt                 from cBioPortal
#   <ROOT>/V6/04_processed_data/master_cohort.tsv    built by analysis/v6_scripts/03_build_cohort.R

# --- 1. tables: recompute every reported number + run the 80 assertions ---
Rscript build_tables/01_build_tables_V3.R

# --- 2. render the DOCX/PDF deliverables from build/*.tsv ---
<PY_DOCX> build_tables/build_tables_docx.py        # Table1-3, Supplementary_Tables, KRT, Data&Code.md
<PY_DOCX> build_tables/build_supplement_pdf.py     # single supplementary PDF (two-pass page numbers)

# --- 3. figures: recompute inputs, then draw, then QA ---
Rscript figures/00_recompute_inputs.R
Rscript figures/99_run_all.R          # runs 10_fig1.R … 70_figS2.R and 90_qa_overlap.R

# --- 4. neoantigen (optional; needs netMHCpan-4.2e and a reference proteome) ---
python neoantigen/01_build_peptides.py
python neoantigen/04_build_netmhcpan_input.py --mode full
bash   neoantigen/run_netmhcpan_full_host.sh      # netMHCpan-4.2e, in a VM
python neoantigen/08_stats_full_extended.py

# --- 5. manuscript / response / cover DOCX (submission-package scripts; see §1) ---
<PY_DOCX> V3/QC/make_revision_docx.py              # CLEAN + MARKED manuscripts (line numbers on)
<PY_DOCX> V3/05_response/build_response_docx.py
<PY_DOCX> V3/07_cover/build_cover_docx.py
```

Steps 1–3 need only R 4.6.1 and, for step 2, Python 3.12 with `python-docx`/`pypdf`. Step 4 needs
netMHCpan-4.2e (see `../env/`) and is the only long-running step. `python` (plain, any 3.10+) is
fine for the neoantigen scripts; `<PY_DOCX>` is **not** interchangeable with `python` — see §3.

## 3. Required interpreters and versions

| Purpose | Interpreter | Version | Packages |
|---|---|---|---|
| every DOCX this revision ships (manuscripts, response, cover, Key Resources Table, tables, supplementary tables) | `<ROOT>/.tools/docxenv/Scripts/python.exe` | **CPython 3.12.13** (MSC v.1944, 64-bit) | `python-docx` 1.2.0, `pypdf` 6.20.1 |
| rendering the supplementary PDF and the assembly/QA scripts | any CPython ≥ 3.10 | 3.12–3.14 all work | `pypdf`, `PyMuPDF`, `Pillow` |
| all statistical analysis and every figure | `Rscript` | **R 4.6.1** | see `env/env_lock_R.txt` (data.table, survival, boot, readxl, ggplot2) |
| neoantigen prediction | netMHCpan-4.2e; MHCflurry (secondary) | see `../env/` | — |

**The DOCX builder is not interpreter-neutral.** `python-docx` writes a different OOXML container
under different CPython versions, so a DOCX built with the wrong interpreter is *the same text in
different bytes*. Measured on this revision, from the identical markdown sources:

| Build | `HLA_LOH02_revision_CLEAN.docx` | `HLA_LOH02_revision_MARKED.docx` |
|---|---|---|
| `.tools/docxenv` CPython **3.12.13** (correct) | **62,632 B** — equals the shipped file | **62,934 B** — equals the shipped file |
| system CPython **3.14.7** | 61,381 B | 61,678 B |

Re-run with the wrong interpreter and the deliverables silently stop matching the package. The
frozen bytes are reproduced exactly by CPython 3.12.13: all **17** OOXML members of the rebuilt
file are content-identical to the shipped one (same per-member CRC and same per-member sha256) and
the file size is identical.

Whole-file sha256 reproducibility caveat: `python-docx` stamps every zip entry with the **local
wall-clock time** of the build, so a rebuild seconds later has the same members and the same size
but a different whole-file sha256. Verify a DOCX build by member content, not by file hash:

```bash
# per-member content comparison: same 17 members, same CRC32 and same member sha256
python - <<'PY'
import zipfile, hashlib, sys
def mem(p):
    z = zipfile.ZipFile(p)
    return {i.filename: (i.CRC, i.file_size, hashlib.sha256(z.read(i.filename)).hexdigest())
            for i in z.infolist()}
a, b = mem(sys.argv[1]), mem(sys.argv[2])
print("members:", len(a), len(b), "identical content:", a == b)
PY
# then:  python cmp_docx_members.py <rebuilt.docx> <shipped.docx>      -> identical content: True
```

## 4. Deterministic figure rendering — fixed jitter seeds

`geom_jitter()` is random by default, so two runs of the same script used to land the scatter points
differently and the figures could not be reproduced. Two mutually independent constants are now set
at the top of the affected scripts and passed to `set.seed()` immediately before the jittered layer:

| Script | Seed constant | Value |
|---|---|---|
| `figures/30_fig3.R` | `JITTER_SEED_FIG3` | `20261015L` |
| `figures/60_figS1.R` | `JITTER_SEED_FIGS1` | `20261016L` |

The seed pins **only the sub-pixel jitter offset** of the panel-A scatter points; no number, label,
panel bounding box or other layer changes. With the seeds in place two consecutive runs of each
script produce byte-identical TIFFs (the PDFs differ only in `/CreationDate` and its two encoding
consequences — 0 pixels difference after rasterisation). Determinism evidence, the old-vs-new
figure comparison and the ink connected-component QA are recorded in `QC/seed_determinism/` of the
submission package (`DETERMINISM_PROOF.json`, `COMPARE_REPORT.json`, `COMPARE_VECTOR.json`).

## 5. Figure numbering

Figure numbers follow the 2026-10-15 renumbering to **first-appearance order** — see
`PINNED_PACK_CORRECTIONS.md` §(v). Figure 1 = pan-cancer atlas, Figure 2 = mechanism / arm
landscape, Figure 3 = TMB × HLA LOH, Figure 4 = neoantigen, Figure 5 = survival, Supplementary
Figure S1 = high-APOBEC tail, Supplementary Figure S2 = germline zygosity. The script file-name
number prefixes (`20_fig2.R` … `70_figS2.R`) match the new numbers; the associated TIFF/PDF
deliverables were renamed with **byte-identical content**.

## 6. Byte fidelity: repository copy == deposit copy

The submission package advertises this repository as a byte-reproducible snapshot of the deposit
archives, so the repository must store the **same bytes** as the archives, not just the same text.
Windows checkouts, however, will silently rewrite line endings (`core.autocrlf`) and turn CRLF into
LF in the blob while the working file keeps CRLF — "same content, different bytes" (a real
incident: `derived_data/figure_source_data/fig2a_tmb_dist.tsv`, 1,299,133 B on disk vs a 1,269,355 B
blob).

The repository therefore disables all text/EOL conversion in `.gitattributes`:

```
* -text
```

`* -text` turns conversion off for every path, present and future, so `git cat-file blob` returns
exactly the bytes that were committed. Verified for all **100** members of `code.zip` (9 files) and
`derived_data.zip` (91 files): **100/100 are byte-identical to a file in this repository**. At the
previous repository commit (`ff872f9`) the match was 99/100 — the single exception was this file,
which existed only as a shorter, deposit-only summary (1,882 B against the 9,194 B repository
copy). That exception is now closed: `code/README_CODE.md` inside `code.zip` and
`revision_2026/code/README_CODE.md` here carry the **same bytes and the same length**.

Verify the property for yourself, for any member:

```bash
# 1. bytes as committed by git (no normalisation applied)
git cat-file blob HEAD:revision_2026/data/tables_v3/table3_survival.tsv | sha256sum

# 2. bytes as shipped inside the deposit archive
unzip -p 06_compliance/deposit/derived_data.zip derived_data/tables_v3/table3_survival.tsv | sha256sum

# 3. bytes of this file, in both places
sha256sum revision_2026/code/README_CODE.md
unzip -p 06_compliance/deposit/code.zip code/README_CODE.md | sha256sum
```

Each pair must print the same digest. (Do this on a fresh clone *after* checking out
`.gitattributes`, or the old normalisation rules apply to the checkout.) The whole property is
enforced mechanically for every member at once by `tools/check_repo_vs_zip.py`:

```bash
python revision_2026/code/tools/check_repo_vs_zip.py --repo revision_2026 \
    <package>/06_compliance/deposit/code.zip \
    <package>/06_compliance/deposit/derived_data.zip
# -> members: 100   byte-identical to a repository file: 100   mismatches: 0   (exit 0)
```

## 7. Expected output — sha256 index

Digests of the frozen deliverables this code produces, as shipped at freeze time, and reproduced
verbatim in the submission package's `QC/FINAL_MANIFEST.md`. Artifact paths are relative to the
delivery tree `iscience投稿版本/V3/`.

### Figures — `02_figures/`

| Artifact | Bytes | sha256 |
|---|---:|---|
| `Figure1_pancancer_and_reliability.tiff` | 605,148 | `53e2ad70038bf7653343387ebeedc89657cf897f9b6ff338ab5c19c44d6c4bf8` |
| `Figure1_pancancer_and_reliability.pdf` | 61,844 | `c1a32e8d2c507f98741d3a05d8bfb1be6c5413d2dc5c9cf20d5d0527c594a52f` |
| `Figure2_mechanism_armlandscape.tiff` | 321,874 | `998dc8def28fd6181a8aef9a9895e52128df6e3f6fa82c14c5cb5e484ed48593` |
| `Figure2_mechanism_armlandscape.pdf` | 58,135 | `8c67f4d93e80f83019db0ae8e1d9a942e651d5e0113dd2155522f61417acb97a` |
| `Figure3_TMB_aneuploidy.tiff` | 430,952 | `34e73bf01c84cd7ca4f38066c671007c98017c82228feb5e92d48d4d2baa1328` |
| `Figure3_TMB_aneuploidy.pdf` | 922,032 | `be31a2c852ad140a3501c319ae58ab899ba19c6f512a395ab241efb57c797a09` |
| `Figure4_neoantigen.tiff` | 292,246 | `9798967b5ac9b1b1a135229e2017d97c02d18042c4d57238207246759b7fb180` |
| `Figure4_neoantigen.pdf` | 55,406 | `dd1ffb32d9169e6417db509a48ff2777e3fb820df446a3a28a20c4418d01009f` |
| `Figure5_survival.tiff` | 202,986 | `df12972b30e236b0a36b34d43306de73f2db2e61ab50cd01bf9356fc7b5ef817` |
| `Figure5_survival.pdf` | 46,563 | `4764a8bfa6d14a46a875e71492e431197c8afc8dd0363c7c75ccea7123563738` |
| `SupplementaryFigureS1_apobec.tiff` | 392,574 | `0058dc0f2b1771da98d46534f4c4391772ac18516411e7888d2573b10bd2cc29` |
| `SupplementaryFigureS1_apobec.pdf` | 391,731 | `9bf3ae8766823007fc44dfe8793b28cdbbbed316d3c5401b622d453ad91285c0` |
| `SupplementaryFigureS2_germline.tiff` | 179,822 | `01f4c16c79c5dc2abcdbe549835670de01ab7e2a9dcb5489c9dfa4d8925b5d32` |
| `SupplementaryFigureS2_germline.pdf` | 44,310 | `af7cb68da76198e0038433f58c8208c696e34607c01ee68dc588bb8e70e008fa` |
| `QA_figure_check.md` (programmatic QA; all gates 0) | 19,539 | `b14947a7ff5e92236e9f2e020b9f24d1124b5905cb526dd5e486ecd8616291b0` |

### Manuscript and submission DOCX

Whole-file sha256 depends on the zip timestamps `python-docx` writes (see §3), so treat these as
*the frozen shipped bytes*, and verify a rebuild by member content.

| Artifact | Bytes | sha256 (frozen bytes as shipped) |
|---|---:|---|
| `01_manuscript/HLA_LOH02_revision_CLEAN.docx` | 62,652 | `66c2dca47169458ddda4bd42c98dff14fa62ed7142eff85aed120b7a2e0db1b2` |
| `01_manuscript/HLA_LOH02_revision_MARKED.docx` | 62,954 | `a2987113faffe43e4fc45a70b963efa802c365fea8542740b0343c11ba88c1c9` |
| `05_response/Response_to_Reviewers.docx` | 63,730 | `ac860045b799e89d1f1c11078832c023064c134684dd3fa1f4e0f3aac6a93dfc` |
| `07_cover/Cover_Letter.docx` | 40,860 | `9a64a7e2606687dfedc88c5e8aa6402c3d314028cc351a7f63d474d221c173f9` |
| `06_compliance/Key_Resources_Table.docx` | 38,913 | `1beafe5a83b0445e2c56b8d379a58a01b53635e39dc3f9471f10622aaa8b5a5e` |
| `03_tables/Table1_baseline.docx` | 38,735 | `84971fc8a7821c5f369cae14b5c29ee0b841e4fef933e32edadd64002cc6c4b0` |
| `03_tables/Table2_drivers.docx` | 38,330 | `4bea5e52838547b09992035150e603fda343b977596376eee834495c17b558b9` |
| `03_tables/Table3_survival.docx` | 38,478 | `98029ae48b2e0dd2cb722a2550ca879a58d51f88474e2c2f9857886390b2272b` |
| `03_tables/Supplementary_Tables.docx` | 629,929 | `1d23636643c1a3e0690117f71ba063f3bf6660e85b486b1ab102bba8a760b300` |
| `04_supplement/Supplemental_Information.pdf` | 1,510,270 | `a17d21b9f45de59f7e83b4adb9746c2c790596444792a595e2475a6d6d8f4f7a` |
| `06_compliance/Graphical_Abstract/Graphical_Abstract.tiff` | 463,738 | `4ea81270e6ac7ffe737c7d2ceed01c1604991f97357f890cd3f5dca931f41b16` |

### Deposit archives — `06_compliance/deposit/`

| Artifact | Bytes | sha256 |
|---|---:|---|
| `derived_data.zip` (91 members) | 623,468 | `55b1ce8de375ed073c66024f08597f43fad85ece5becf77ecf793762a7da6986` |
| `code.zip` (9 members) | see note | **self-referential** — `code.zip` contains this very file, so recording its digest here would change it. Its digest is recorded in `QC/FINAL_MANIFEST.md` of the submission package and is reproducible only from the archive itself: `sha256sum 06_compliance/deposit/code.zip`. Everything the archive contains is byte-identical to this directory (§6). |

### Number dictionary

| Artifact | Bytes | sha256 |
|---|---:|---|
| `PINNED_PACK.md` (this directory; the copy shipped in both archives) | 15,179 | `96063bb8d84f9e3c2ece3df406bd0f28fa76c493851661e0b483f64a0a3de6f5` |
| `PINNED_PACK_CORRECTIONS.md` (§(v) figure-renumbering record, §(vi) blocker fixes, §(vii) closing-round fixes, §(viii) sentence-split round) | 54,238 | `8da532085f103251509fc56544fc3c5df9a33fe6f07d0f9402c00ae16f5fb179` |
| `00_pinned/PINNED_PACK.md` in the submission package (same bytes) | 15,179 | `96063bb8d84f9e3c2ece3df406bd0f28fa76c493851661e0b483f64a0a3de6f5` |

## 8. Notes

- The revision analyses do **not** change any number in `../data/tables_v3/` or
  `../data/figure_source_data/` except the single authorised rounding correction recorded in
  `PINNED_PACK.md` §2.5.
- `PINNED_PACK.md` is shipped **once** as bytes: the deposit copy inside `code.zip` /
  `derived_data.zip` and the submission-package copy `00_pinned/PINNED_PACK.md` are byte-identical
  (`96063bb8…`, 15,179 B). The earlier behaviour — a second, byte-distinct "manuscript-package"
  copy that carried an extra figure-renumbering note — is recorded and superseded in
  `PINNED_PACK_CORRECTIONS.md` §(v)/(vi).
- Figure scripts must run with `bg = "white"` (otherwise the TIFF panels come out black) and are
  checked for label overlap by `90_qa_overlap.R` rather than by eye.
- Intermediate binaries (`*.rds`), R session dumps (`Rplots.pdf`), `__pycache__` and scratch/debug
  scripts are not part of this package; see `../../.gitignore`.
- The manuscript-rendering scripts listed at the end of §1 are **not** members of `code.zip`; they
  live in the submission package (`V3/QC/`, `V3/05_response/`, `V3/07_cover/`) because they consume
  the manuscript markdown rather than the derived tables.
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
