# `revision_2026/code/` — code for the iScience revision

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
| `PINNED_PACK_CORRECTIONS.md` | Corrections and audit record for the locked pack; **§(v) is the authoritative figure-renumbering record**, §(vi) the pre-submission blocker fixes, §(vii) the closing-round fixes and their honest deviations, §(viii) the sentence-split round, §(ix) the sentence-level revision-highlighting round. |
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
| `Figure1_pancancer_and_reliability.tiff` | 605,964 | `4a9bf25ee99a2a092e4c47524fc2fa19b3427cec24518d95407c9441d287703a` |
| `Figure1_pancancer_and_reliability.pdf` | 61,869 | `7d736c598299b90a34ee23ed38556f29710b9412ad73896e3cda70ee3643566d` |
| `Figure2_mechanism_armlandscape.tiff` | 327,454 | `8af788faacc687d26531c4144e3a70d86b9f9740a76996afc2550725fe68d9ec` |
| `Figure2_mechanism_armlandscape.pdf` | 58,468 | `70b2b1605b513a0d9339361e0a1d8f9bd9d11ba4e357c6521a8afc89b5a5a0b7` |
| `Figure3_TMB_aneuploidy.tiff` | 430,792 | `60935ae13037d5e00db871e8be482c30521627dfb9af8d0ee5d90c757c4e1e48` |
| `Figure3_TMB_aneuploidy.pdf` | 922,047 | `dc508c6d8557cd689e630b5855c6e4f06a841cff4640abcb42f5efba55c6f8b1` |
| `Figure4_neoantigen.tiff` | 291,004 | `17606ab091f0bdae160f6c4223c99a84909bb3e159b8ea3676356ff699d71b79` |
| `Figure4_neoantigen.pdf` | 55,416 | `147d58ed83c4f3d732fb7737fda466108b2c9759ff9a843e91376811df0bd5b3` |
| `Figure5_survival.tiff` | 202,070 | `7ece4183dee2de95bac1e494b21fc6fda4aca078e5ae232a1bfc39134ebe6500` |
| `Figure5_survival.pdf` | 46,576 | `c7257f42c291b6f0ec9d878a2fcb65a2de5970b8ae03a6b368724a45ac380a40` |
| `SupplementaryFigureS1_apobec.tiff` | 391,582 | `a0b43ab03ddbed09a9ffca4e4d13292997ea74a4a04057bbde121efde5c245b2` |
| `SupplementaryFigureS1_apobec.pdf` | 391,411 | `3814e8501c644bc075327e5b85ad3dc3c7bff0c124d6023b3e7bc9d2134d586f` |
| `SupplementaryFigureS2_germline.tiff` | 178,352 | `92f2f27b1238277f90fe3e5e75c84fa4758a8f64187309ede25410002088bf24` |
| `SupplementaryFigureS2_germline.pdf` | 44,301 | `297b012d8c2c85ad941fd909392abcd707e576b371a3ad2e8e4a69d908c66130` |
| `QA_figure_check.md` (programmatic QA; all gates 0) | 19,552 | `9332f835b2750e5c6c1f17727bfb63e693539d3eb6b6daa2c86ce4b2e1b85cf3` |

### Manuscript and submission DOCX

Whole-file sha256 depends on the zip timestamps `python-docx` writes (see §3), so treat these as
*the frozen shipped bytes*, and verify a rebuild by member content.

| Artifact | Bytes | sha256 (frozen bytes as shipped) |
|---|---:|---|
| `01_manuscript/HLA_LOH02_revision_CLEAN.docx` | 62,888 | `308510748c72591af40856163bcef0c7f602f17899f9b9e7c159afad3183709e` |
| `01_manuscript/HLA_LOH02_revision_MARKED.docx` | 67,509 | `d38c9536655ea34b32ff65728ef9bd590aa053c81888030addb63efcd1cc6bdb` |
| `05_response/Response_to_Reviewers.docx` | 63,730 | `ac860045b799e89d1f1c11078832c023064c134684dd3fa1f4e0f3aac6a93dfc` |
| `07_cover/Cover_Letter.docx` | 40,860 | `9a64a7e2606687dfedc88c5e8aa6402c3d314028cc351a7f63d474d221c173f9` |
| `06_compliance/Key_Resources_Table.docx` | 38,913 | `1beafe5a83b0445e2c56b8d379a58a01b53635e39dc3f9471f10622aaa8b5a5e` |
| `03_tables/Table1_baseline.docx` | 38,735 | `84971fc8a7821c5f369cae14b5c29ee0b841e4fef933e32edadd64002cc6c4b0` |
| `03_tables/Table2_drivers.docx` | 38,330 | `4bea5e52838547b09992035150e603fda343b977596376eee834495c17b558b9` |
| `03_tables/Table3_survival.docx` | 38,478 | `98029ae48b2e0dd2cb722a2550ca879a58d51f88474e2c2f9857886390b2272b` |
| `03_tables/Supplementary_Tables.docx` | 624,779 | `613c23dda25951b73bd3dafcbc7487023efcfba81fdf63e18d5f82f74711261c` |
| `04_supplement/Supplemental_Information.pdf` | 1,510,708 | `82acb6364f3d4eebbf447b965479e96d79582186f37fb99e53203e373eaed72c` |
| `06_compliance/Graphical_Abstract/Graphical_Abstract.tiff` | 463,738 | `4ea81270e6ac7ffe737c7d2ceed01c1604991f97357f890cd3f5dca931f41b16` |

### Deposit archives — `06_compliance/deposit/`

| Artifact | Bytes | sha256 |
|---|---:|---|
| `derived_data.zip` (91 members) | 629,767 | `b080aa482408df6b642a1c4dc84ce62edd69c2cc2c389d7c9c38c70f34ee9341` |
| `code.zip` (9 members) | see note | **self-referential** — `code.zip` contains this very file, so recording its digest here would change it. Its digest is recorded in `QC/FINAL_MANIFEST.md` of the submission package and is reproducible only from the archive itself: `sha256sum 06_compliance/deposit/code.zip`. Everything the archive contains is byte-identical to this directory (§6). |

### Number dictionary

| Artifact | Bytes | sha256 |
|---|---:|---|
| `PINNED_PACK.md` (this directory; the copy shipped in both archives) | 15,179 | `96063bb8d84f9e3c2ece3df406bd0f28fa76c493851661e0b483f64a0a3de6f5` |
| `PINNED_PACK_CORRECTIONS.md` (\u00a7(v) figure-renumbering record, \u00a7(vi) blocker fixes, \u00a7(vii) closing-round fixes, \u00a7(viii) sentence-split round, \u00a7(ix) sentence-level revision-highlighting round, \u00a7(x) three-tier minimal-unit round, \u00a7(xi) Mode C substantive-change round, \u00a7(xii) integration round: user figure micro-adjustments, the two figure defect fixes, the supplement-PDF rebuild and the freeze) | 100,829 | `59bf4b42174053a1e637b92a0d56c83026626c5f99ef35d21be250491ce66f9a` |
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
- **Revision-highlighting rule (2026-10-15, third round — §(x) of `PINNED_PACK_CORRECTIONS.md`).**
  The marked manuscript `01_manuscript/HLA_LOH02_revision_MARKED.docx` is produced by
  `V3/QC/make_revision_docx.py` under a **three-tier minimal-unit rule**: Tier 1 = whole-block
  yellow for genuinely new paragraphs / sections / sentences / figure legends / references;
  Tier 2 = never highlighted when the text is verbatim-identical to the submitted manuscript
  (hard assertion: 0 counter-examples); Tier 3 = inside rewritten text only the **changed word
  strings** are highlighted (`replace` runs are further trimmed at character level). Whole-sentence
  highlighting is no longer used. Coverage went 87.2% (paragraph-level rule) → 71.2%
  (sentence-level rule) → **61.2%**, always with the "verbatim-identical sentence carrying any
  highlight = 0" assertion holding.
  **Superseded:** the delivered revision markup is now the **Mode C** substantive-change
  rule (28.8% coverage — 19,537/67,799 characters, 589 highlight runs, 101 of 174 paragraphs),
  verified independently by `V3/QC/verify_highlight_mode_c.py` → `V3/QC/HIGHLIGHT_VERIFY_MODE_C.md`
  (`ASSERT A observed = 0 -> PASS`; `ASSERT B instances = 849 uncovered = 0 -> PASS`; `RESULT: ALL
  GATES PASS`). The three-tier full-mode build (61.2%) is kept as the rollback pair
  `01_manuscript/_alternative/HLA_LOH02_revision_{MARKED,CLEAN}_full.docx`; see
  `PINNED_PACK_CORRECTIONS.md` §(xi)–§(xii).
 Verification lives in `V3/QC/HIGHLIGHT_VERIFY.md`, produced by
  the independent verifier `V3/QC/verify_highlight_three_tier.py`. A new editor-facing
  **section-by-section change list** ships with the submission package as
  `05_response/Change_Summary.md` (a second copy sits next to the two manuscript DOCX as
  `01_manuscript/Change_Summary.md`). Neither the change list nor the rendering touches the
  manuscript text, numbers or figure/table numbers.
