# HLA_LOH02: Pan-Cancer Atlas of HLA Class I Loss of Heterozygosity

Analysis code for the manuscript:

**"HLA Class I Loss of Heterozygosity Across 66 Cancer Types Reveals Mechanistic Coupling with Whole-Genome Doubling and Independent Prognostic Value"**

Cai W, Lin K. Department of Radiation Oncology, First Hospital of Quanzhou Affiliated to Fujian Medical University.

## Data Source

All genomic and clinical data were obtained from the MSK-IMPACT 50K Clinical Sequencing Cohort, publicly available through the cBioPortal for Cancer Genomics:

https://www.cbioportal.org/study?id=msk_impact_50k_2026

Data accessed: June 12, 2026. Distributed under Creative Commons BY-NC-ND 4.0 license.

## Repository Contents

```
scripts/
├── 01_explore_data.R          # Initial data exploration and quality checks
├── 02_master_analysis.R       # Primary pan-cancer HLA LOH analysis
├── 03_refined_analysis.R      # Refined statistical analyses (Cox, sensitivity)
├── 04_generate_figures.R      # Main figure generation (Figures 1-8)
├── 05_extended_data_figures.R # Extended Data figure generation
├── 06_format_citations.py     # Citation formatting utility
└── 07_fix_fig3.R              # Figure 3 refinement

results/
└── tables/                    # Source data for all figures
    ├── cancer_type_hla_loh.csv
    ├── cancer_type_hla_loh_v2.csv
    ├── summary_statistics.csv
    └── summary_v2.csv
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
