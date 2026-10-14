# `revision_2026/code/` — code for the iScience revision

Manuscript **ISCIENCE-D-26-09416**. Every script that produces a number or a figure in the
revision is here. The R analysis scripts hard-code their `ROOT` at the top of the file; point that
constant at your checkout.

This directory is the code half of the **single public snapshot** promised in *Data and Code
Availability*: the same tree is deposited as `06_compliance/deposit/code.zip` (see
`../data/FINAL_MANIFEST.md` for the frozen-package manifest).

## Layout

| Path | Contents |
|---|---|
| `build_tables/` | `01_build_tables_V3.R` — recomputes **every** Table 1–3 and supplementary table S1–S13 number from the raw cBioPortal files, writes `build/*.tsv`, and asserts each headline value against `PINNED_PACK.md` (80 assertions; exits non-zero on any mismatch). `build_tables_docx.py`, `build_supplement_pdf.py`, `dump_docx.py` render the DOCX/PDF deliverables from those TSVs. |
| `analysis/v1_scripts/` | Original v1 pipeline (`01`–`07`), kept for provenance. |
| `analysis/v6_scripts/` | Cohort build and core analysis (`03_build_cohort.R`, `04_core_analysis.R`, `06_table_data.R`, `13_sensitivity_mediation.R`, `15_germline_zygosity.R`, …). |
| `analysis/revision_r3/` | Reviewer-3 revision analyses: aneuploidy-score construction and modelling (`r3p2_*`), arm-independent mechanism and 41-arm ranking (`r3p3_*`), purity/coverage/panel reliability models (`r3p4_*`). |
| `figures/` | Figure script set: `00_recompute_inputs.R` builds every input table, `10_fig1.R`…`70_figS2.R` draw Figures 1–5, S1 and S2, `90_qa_overlap.R` programmatically checks label overlap/clipping, `99_run_all.R` runs the set, `fig_common.R` holds shared helpers. |
| `neoantigen/` | netMHCpan-4.2e (primary) and MHCflurry (secondary) pipelines: peptide construction, prediction, statistics and consistency checks. |
| `tools/` | Deposit-package build scripts (from the project's `.tools/`): `assemble_deposit.py` builds `code.zip` / `derived_data.zip`, `surgical_zip_rebuild_one.py` / `surgical_zip_rebuild_raw.py` replace individual zip members without rebuilding the archive, `_sync_readme_template.py` syncs this README into the deposit. |
| `PINNED_PACK.md` | The locked number dictionary, byte-identical to the copy inside `code.zip` / `derived_data.zip`. |
| `PINNED_PACK_CORRECTIONS.md` | Corrections and audit record for the locked pack; **§(v) is the authoritative figure-renumbering record**. |
| `env_lock_R.txt`, `requirements.txt` | Environment locks (R 4.6.1 session; Python rendering deps). `renv.lock` (v1, R 4.3.3) is kept at the repository root. |

## Order of execution

```bash
# --- 0. inputs (not redistributed; see ../README.md) ---
#   <ROOT>/msk_impact_50k_2026/*.txt        from cBioPortal
#   <ROOT>/V6/04_processed_data/master_cohort.tsv    built by analysis/v6_scripts/03_build_cohort.R

# --- 1. tables: recompute every reported number + run the 80 assertions ---
Rscript build_tables/01_build_tables_V3.R

# --- 2. render the DOCX/PDF deliverables from build/*.tsv (python-docx + pypdf only) ---
python build_tables/build_tables_docx.py
python build_tables/build_supplement_pdf.py

# --- 3. figures: recompute inputs, then draw, then QA ---
Rscript figures/00_recompute_inputs.R
Rscript figures/99_run_all.R          # runs 10_fig1.R … 70_figS2.R and 90_qa_overlap.R

# --- 4. neoantigen (optional; needs netMHCpan-4.2e and a reference proteome) ---
python neoantigen/01_build_peptides.py
python neoantigen/04_build_netmhcpan_input.py --mode full
bash   neoantigen/run_netmhcpan_full_host.sh      # netMHCpan-4.2e, in a VM
python neoantigen/08_stats_full_extended.py
```

Steps 1–3 need only R 4.6.1 and, for step 2, Python 3.12 with `python-docx`/`pypdf`. Step 4 needs
netMHCpan-4.2e (see `../env/`) and is the only long-running step.

## Deterministic figure rendering — fixed jitter seeds

`geom_jitter()` is random by default, so two runs of the same script used to land the scatter points
differently and the figures could not be reproduced byte-for-byte. Two mutually independent
constants are now set at the top of the affected scripts and passed to `set.seed()` immediately
before the jittered layer:

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

## Figure numbering

Figure numbers follow the 2026-10-15 renumbering to **first-appearance order** — see
`PINNED_PACK_CORRECTIONS.md` §(v). Figure 1 = pan-cancer atlas, Figure 2 = mechanism / arm
landscape, Figure 3 = TMB × HLA LOH, Figure 4 = neoantigen, Figure 5 = survival, Supplementary
Figure S1 = high-APOBEC tail, Supplementary Figure S2 = germline zygosity. The script file-name
number prefixes (`20_fig2.R` … `70_figS2.R`) match the new numbers; the associated TIFF/PDF
deliverables were renamed with **byte-identical content**.

## Expected output — sha256 index

Expected digests of the frozen deliverables this code produces. Figure digests are of the files in
`V3/02_figures/` at freeze time and are reproduced verbatim in `../data/FINAL_MANIFEST.md`.

### Figures (`V3/02_figures/`)

| Artifact | sha256 |
|---|---|
| `Figure1_pancancer_and_reliability.tiff` | `53e2ad70038bf7653343387ebeedc89657cf897f9b6ff338ab5c19c44d6c4bf8` |
| `Figure1_pancancer_and_reliability.pdf` | `c1a32e8d2c507f98741d3a05d8bfb1be6c5413d2dc5c9cf20d5d0527c594a52f` |
| `Figure2_mechanism_armlandscape.tiff` | `998dc8def28fd6181a8aef9a9895e52128df6e3f6fa82c14c5cb5e484ed48593` |
| `Figure2_mechanism_armlandscape.pdf` | `8c67f4d93e80f83019db0ae8e1d9a942e651d5e0113dd2155522f61417acb97a` |
| `Figure3_TMB_aneuploidy.tiff` | `34e73bf01c84cd7ca4f38066c671007c98017c82228feb5e92d48d4d2baa1328` |
| `Figure3_TMB_aneuploidy.pdf` | `be31a2c852ad140a3501c319ae58ab899ba19c6f512a395ab241efb57c797a09` |
| `Figure4_neoantigen.tiff` | `9798967b5ac9b1b1a135229e2017d97c02d18042c4d57238207246759b7fb180` |
| `Figure4_neoantigen.pdf` | `dd1ffb32d9169e6417db509a48ff2777e3fb820df446a3a28a20c4418d01009f` |
| `Figure5_survival.tiff` | `df12972b30e236b0a36b34d43306de73f2db2e61ab50cd01bf9356fc7b5ef817` |
| `Figure5_survival.pdf` | `4764a8bfa6d14a46a875e71492e431197c8afc8dd0363c7c75ccea7123563738` |
| `SupplementaryFigureS1_apobec.tiff` | `0058dc0f2b1771da98d46534f4c4391772ac18516411e7888d2573b10bd2cc29` |
| `SupplementaryFigureS1_apobec.pdf` | `9bf3ae8766823007fc44dfe8793b28cdbbbed316d3c5401b622d453ad91285c0` |
| `SupplementaryFigureS2_germline.tiff` | `01f4c16c79c5dc2abcdbe549835670de01ab7e2a9dcb5489c9dfa4d8925b5d32` |
| `SupplementaryFigureS2_germline.pdf` | `af7cb68da76198e0038433f58c8208c696e34607c01ee68dc588bb8e70e008fa` |
| `QA_figure_check.md` (programmatic QA; all gates 0) | `b14947a7ff5e92236e9f2e020b9f24d1124b5905cb526dd5e486ecd8616291b0` |

### Number dictionary (`../data/number_dictionary/`)

| Artifact | sha256 |
|---|---|
| `PINNED_PACK.md` (deposit copy, as shipped in both zips) | `3f27f3d7ff7170bde4f2c5393d46c95c8b66df13b7214b3d369b00d8b1ee91cd` |
| `PINNED_PACK_CORRECTIONS.md` (§(v) figure-renumbering record) | `177fb79c10728c8f0a233d879a8dc633ff1535f418621ad8662b8be71afa151b` |
| `PINNED_PACK_manuscript_package.md` (manuscript-package copy; carries the §(v) cross-reference note) | `96063bb8d84f9e3c2ece3df406bd0f28fa76c493851661e0b483f64a0a3de6f5` |

### Deposit archives (`06_compliance/deposit/`)

| Artifact | sha256 |
|---|---|
| `code.zip` | `8a5d74383337fe58f0d2f7573b750f8956e7406feb7f7f4bb417b20e80c61d8a` |
| `derived_data.zip` | `f23793abd68c12955c23a6bd70a8ba2b5f1243799729c58d220b033f34d48759` |

## Notes

- The revision analyses do **not** change any number in `../data/tables_v3/` or
  `../data/figure_source_data/` except the single authorised rounding correction recorded in
  `PINNED_PACK.md` §2.5.
- `PINNED_PACK.md` exists in two byte-distinct copies in the submission package, both shipped here:
  the **deposit copy** (`PINNED_PACK.md`, inside `code.zip`/`derived_data.zip`) and the
  **manuscript-package copy** (`PINNED_PACK_manuscript_package.md`, which adds the
  "图号重编（2026-10-15）" note pointing at §(v)). They differ only in that note, the clarified
  Table-3/burden median-OS provenance sentences, and the deposit-statement paragraph.
- Figure scripts must run with `bg = "white"` (otherwise the TIFF panels come out black) and are
  checked for label overlap by `90_qa_overlap.R` rather than by eye.
- Intermediate binaries (`*.rds`), R session dumps (`Rplots.pdf`), `__pycache__` and scratch/debug
  scripts are not part of this package; see `../../.gitignore`.
