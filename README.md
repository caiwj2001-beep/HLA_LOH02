# HLA_LOH02: Pan-Cancer Atlas of HLA Class I Loss of Heterozygosity

Analysis code for the manuscript:

**"HLA Class I Loss of Heterozygosity Across 66 Cancer Types Reveals Mechanistic Coupling with Whole-Genome Doubling and Independent Prognostic Value"**

Cai W, Li K. Department of Radiation Oncology, First Hospital of Quanzhou Affiliated to Fujian Medical University.

## Data Source

All genomic and clinical data were obtained from the MSK-IMPACT 50K Clinical Sequencing Cohort, publicly available through the cBioPortal for Cancer Genomics:

https://www.cbioportal.org/study?id=msk_impact_50k_2026

Data accessed: June 12, 2026. Distributed under Creative Commons BY-NC-ND 4.0 license.

## Repository Contents

```
scripts/

├── 04_generate_figures.R      # Main figure generation (Figures 1-8)
├── 05_extended_data_figures.R # Extended Data figure generation
├── 


```

## Software Requirements

- R version 4.3.3
- Package versions are recorded in `renv.lock`

Key R packages:
| Package | Version |
|---------|---------|
| data.table | 1.15.0 |
| dplyr | 1.1.4 |
| tidyr | 1.3.0 |
| ggplot2 | 3.4.4 |
| survival | 3.5-7 |
| RColorBrewer | 1.1-3 |
| gridExtra | 2.3 |

## Reproducibility

To reproduce the analysis:

1. Download the MSK-IMPACT 50K data from cBioPortal (link above) into `msk_impact_50k_2026/`
2. Install required R packages: `renv::restore()`
3. Run scripts in numerical order:
   ```r
   source("scripts/01_explore_data.R")
   source("scripts/02_master_analysis.R")
   source("scripts/03_refined_analysis.R")
   source("scripts/04_generate_figures.R")
   source("scripts/05_extended_data_figures.R")
   ```

## License

Code: MIT License

Data: Creative Commons BY-NC-ND 4.0 (as distributed by MSK)

---

## v2 — iScience revision (2026) — `revision_2026/`

> The section above documents v1 and is kept for provenance. **The v2 revision changes the
> interpretation of the data**: the claims of mechanistic coupling with whole-genome doubling and of
> independent prognostic value were withdrawn, and the analysis was re-scoped. Read this section
> for the current state of the work.

**Manuscript:** ISCIENCE-D-26-09416 (in revision).
**Revision code and derived data:** [`revision_2026/`](revision_2026/) — see
[`revision_2026/README.md`](revision_2026/README.md) for a walk-through.

### What the revision changed

- **HLA LOH *counts* are governed by call reliability** — the apparent frequency depends strongly on
  tumour purity and coverage (the arm-independent share runs from 60.3 % to 11.3 % across purity
  deciles), so a high-confidence frequency of 14.0 % is reported alongside the 25.3 % raw figure.
- **HLA LOH *associations* are governed by global aneuploidy** — the TMB association attenuates but
  survives aneuploidy adjustment (OR 1.568 → 1.238/1.250/1.256), and it fails in the highest
  aneuploidy tertile.
- **Withdrawn:** the mechanistic coupling with WGD as a *reported highlight*, the independent
  prognostic role, the "dose dependence" on the number of affected loci, the germline
  "pruning pressure" interpretation, and the APOBEC/smoking mechanistic explanation (an abundance
  artefact). The revised neoantigen analysis does **not** support immune-editing as a driver.
- Figure structure: five main figures plus Supplementary Figures S1 and S2.

### Layout

```
revision_2026/
├── README.md      this revision: what changed, how to reproduce, licence, citation
├── code/          analysis, figure and neoantigen code + environment locks (README_CODE.md)
├── data/          derived tables, number dictionary, column-level data dictionary (README_DATA.md)
└── env/           exact software versions used (R, Python, MHCflurry, netMHCpan)
```

### Data and code availability

- **Code** — MIT licence, see [`LICENSE`](LICENSE). Everything under `revision_2026/code/`.
- **Derived data** — CC BY-NC-ND 4.0, see [`LICENSE-DATA`](LICENSE-DATA). Everything under
  `revision_2026/data/`.
- **Raw data** — *not redistributed.* All genomic and clinical data come from the cBioPortal study
  [`msk_impact_50k_2026`](https://www.cbioportal.org/study?id=msk_impact_50k_2026)
  (Bandlamudi et al., *Cancer Cell* 2026, PMID 41895280). That cohort is distributed under
  **CC BY-NC-ND 4.0** (the *NoDerivatives* clause), so neither the raw files nor any
  sample-level derived file is included here; download them from cBioPortal and regenerate
  everything with `revision_2026/code/`. Sample-level files deliberately excluded are listed in
  the data dictionary.
- The repository is archived to Zenodo on release; the DOI will be added here once the article is
  accepted.

### How to cite

Until the article is published, please cite the manuscript number together with this repository:

> Cai W, Li K, et al. *HLA class I loss of heterozygosity in 29,799 tumours: the count is governed by
> call reliability, the association by global aneuploidy.* 2026; manuscript ISCIENCE-D-26-09416;
> code and derived data: https://github.com/caiwj2001-beep/HLA_LOH02 (tag `v2-isiScience-revision`).

### Reproducibility (short form)

1. Download `msk_impact_50k_2026` from cBioPortal into `<ROOT>/msk_impact_50k_2026/`.
2. Restore the environment recorded in `revision_2026/code/env_lock_R.txt` (R 4.6.1) and
   `revision_2026/code/requirements.txt`; `revision_2026/env/` lists the prediction-tool versions.
3. Run `revision_2026/code/build_tables/01_build_tables_V3.R`; it recomputes every reported number
   and asserts each against the locked number dictionary, exiting non-zero on any mismatch.
