# `revision_2026/` — iScience revision (ISCIENCE-D-26-09416)

This directory holds everything added for the **iScience revision** of the manuscript on HLA class I
loss of heterozygosity (HLA LOH) in the MSK-IMPACT 50K cohort. The original repository files
(`README.md`, `renv.lock`, `.gitignore`, `scripts/`) are left untouched; all new material is here.

| Path | What it is |
|---|---|
| `code/` | Analysis, figure-generation and neoantigen-prediction code, plus the environment locks. Start at `code/README_CODE.md`. |
| `data/` | The derived tables the paper's numbers are read from, the number dictionary, and the column-level data dictionary `data/README_DATA.md`. |
| `env/` | The exact software versions the revision was run with (R, Python, MHCflurry, netMHCpan). |

## How to reproduce

1. **Get the raw data.** cBioPortal study `msk_impact_50k_2026`
   (<https://www.cbioportal.org/study?id=msk_impact_50k_2026>), licence CC BY-NC-ND 4.0. Place the
   downloaded text files in `<ROOT>/msk_impact_50k_2026/`. Nothing from that cohort is redistributed
   here, and no file in `data/` is at the individual-sample level.
2. **Restore the environment.** `code/env_lock_R.txt` records the exact R build and package versions
   used (R 4.6.1; data.table, survival, boot, readxl). `code/requirements.txt` covers the Python
   side, which is used only to render DOCX/PDF. `env/` records the neoantigen-prediction versions.
3. **Run in the order given in `code/README_CODE.md`.** `01_build_tables_V3.R` recomputes every
   reported number and *asserts* each of them against `code/PINNED_PACK.md`; it exits non-zero if any
   assertion fails, so it cannot silently produce numbers that differ from those in the paper.
4. **Check against `data/`.** The TSV files in `data/tables_v3/` and `data/figure_source_data/` are
   the machine-readable origin of every delivered table and figure.

## Licence and citation

- **Code** — MIT licence (`../LICENSE`).
- **Derived data** (`data/`) — CC BY-NC-ND 4.0 (`../LICENSE-DATA`), matching the upstream cohort.
- **Raw data** — not redistributed; obtain from cBioPortal.

If you use this code or the derived tables, please cite the manuscript:

> Cai W, Li K, et al. *HLA class I loss of heterozygosity across 29,799 tumours: the association is
> governed by global aneuploidy, the count by call reliability.* (2026, in revision; manuscript
> ISCIENCE-D-26-09416).

Until the article is published, cite this repository together with the manuscript number.
