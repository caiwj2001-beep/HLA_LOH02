# README_DATA — data dictionary for `derived_data/`

**Manuscript:** ISCIENCE-D-26-09416 (revision) — *HLA class I loss of heterozygosity in 29,799 tumours*
**Source cohort:** cBioPortal study `msk_impact_50k_2026` (Bandlamudi et al., *Cancer Cell* 2026, PMID 41895280), licence **CC BY-NC-ND 4.0**.
**This archive:** derived tables only. No raw or sample-level data are redistributed (see §6).

Every table here is machine-readable TSV/CSV. The DOCX tables in the manuscript package are rendered
byte-for-byte from these files. Folder `number_dictionary/` holds the locked number dictionary that the
analysis script asserts against; if an assertion fails the script exits non-zero, so a table here cannot
silently disagree with the reported numbers.

---

## 0. Which script produced which folder

| Folder in this archive | Produced by (script in `revision_2026/code/` — same files as the `code.zip` deposit) |
|---|---|
| `tables_v3/` | `build_tables/01_build_tables_V3.R` (writes `build/*.tsv`; runs 80 assertions vs `PINNED_PACK.md`) |
| `figure_source_data/` | `figures/00_recompute_inputs.R`, `figures/01_mediation_boot.R`, `figures/02_recompute_apobec.R`, `figures/10_fig1.R` … `figures/70_figS2.R`, `figures/90_qa_overlap.R` |
| `supplementary_source_data/` | `analysis/04_core_analysis.R`, `analysis/06_table_data.R`, `analysis/13_sensitivity_mediation.R`, `analysis/15_germline_zygosity.R`, and the v1-era `analysis/02_master_analysis.R` / `03_refined_analysis.R` |
| `number_dictionary/number_dictionary.tsv` | generated from `tables_v3/pin_audit.tsv` (`PINNED` column = locked value) |
| `number_dictionary/PINNED_PACK.md`, `tables_v3/pin_audit.tsv` | `00_pinned/PINNED_PACK.md` + the assertion block at the end of `01_build_tables_V3.R` |

Column types: `N`/`n` = integer count, `freq`/`pct`/`OR`/`HR`/`beta`/`rho` = numeric, `P`/`FDR` = p-value (FDR = Benjamini–Hochberg), `lo`/`hi` = 95 % confidence-interval bounds, `CI_lo`/`CI_hi` = same in another table's naming convention.

---

## 1. `tables_v3/` — the 34 delivered tables (TSV)

### Main tables

| File | Columns |
|---|---|
| `table1_baseline.tsv` | `characteristic` (covariate label) · `hla_intact` (value in HLA-intact group) · `hla_loh` (value in HLA-LOH group) · `P` (group comparison) · `note` · `bold` (render flag) |
| `table2_drivers.tsv` | `predictor` · `model` (distal / proximal) · `OR` · `lo` · `hi` · `P` · `OR_CI` (formatted "OR (lo–hi)") · `P_fmt` |
| `table3_survival.tsv` | `model` (unadjusted → adjusted → +aneuploidy → exclusions) · `HR` · `lo` · `hi` · `P` · `N` · `deaths` · `HR_CI` · `P_fmt` · `is_new` (flag: model newly added this revision) |
| `table3_aneuploidy_HR.tsv` | `term` · `HR` · `lo` · `hi` · `P` (prognostic HR of the aneuploidy score itself) |

### Cancer-type frequency tables (Figure 1 / Table S1–S2)

| File | Columns |
|---|---|
| `s1_atlas.tsv` | `CANCER_TYPE` · `N` · `n_LOH` · `freq_pct` (any HLA LOH, %) · `CI_lo` · `CI_hi` (Wilson) · `medTMB_LOH` · `medTMB_intact` · `pan_pct` (pan-HLA LOH, %) · `wgd_pct` · `aneuploidy_median` · `pct_6p_readable` |
| `s2_tmb_by_cancer.tsv` | `CANCER_TYPE` · `N` · `n_LOH` · `medTMB_LOH` · `medTMB_intact` · `P` · `FDR` · `log2FC` (median TMB ratio) · `sig` (FDR<0.05 flag) |
| `s3_signatures.tsv` | `sig` (mutational signature) · `unadj_OR/lo/hi/P` · `adj_OR/lo/hi/P` (adjusted for aneuploidy) · `N` · `mutual_OR/lo/hi/P` (APOBEC vs smoking mutually adjusted) · `mutual_FDR` · `revised_note` |
| `s4_survival_by_cancer.tsv` | `cancer` · `N` · `events` · `HR` · `lo` · `hi` · `P` · `FDR` |

### Reliability / panel-dependence models (Figures 1C, 2; Table S5)

| File | Columns |
|---|---|
| `s_reliability1_models.tsv` | `term` (purity per −10 %, coverage per +100×, IMPACT505 vs 410, WGD) · `OR` · `lo` · `hi` · `P` · `term_label` · `OR_CI` · `P_fmt` · `PINNED_ref` (locked reference value) · `source` (recomputed value) |
| `s_reliability1_group_summary.tsv` | `group` (arm-independent / arm-dependent / no LOH) · `n` · `facets_purity_pct_median` · `pathologist_purity_pct_median` · `coverage_median` · `ploidy_median` · `aneuploidy_median` · `wgd_pct` · `pct_purity_lt30` |
| `s_reliability1_purity_decile.tsv` | `dec_p` (purity decile 1–10) · `n` · `n_armind` · `purity_median_pct` · `pct` (share arm-independent, %) — Figure 1C |
| `s_reliability1_purity_strata.tsv` | `purity_ge_pct` (stratum floor) · `n` · `y` (events) · `wgd_OR` · `wgd_P` · `pur_per10_OR` · `pur_P` · `cov_per100_OR` · `cov_P` |
| `s_reliability1_auc.tsv` | `model` · `McFadden_R2` · `AUC` · `source` |
| `s5_panel_sensitivity.tsv` | `effect` · `full_OR/lo/hi` (full cohort) · `rest_OR/lo/hi/n` (restricted cohort) · `revised_note` |

### Aneuploidy-score models (Figure 2C; Table S8)

| File | Columns |
|---|---|
| `s_aneuploidy1_models.tsv` | `spec` (model spec) · `term` · `N` · `n_LOH` · `OR` · `lo` · `hi` · `P` · `aneu_OR_per_SD` (aneuploidy term, per SD) · `is_new` · `OR_CI` · `P_fmt` |
| `s_aneuploidy1_tertiles.tsv` | `tertile` (Q1–Q3) · `N` · `n_LOH` · `frac_range` · `OR` · `lo` · `hi` · `P` · `OR_CI` · `P_fmt` |
| `s6_mediation.tsv` | `Quantity` (ACME / ADE / proportion mediated) · `Estimate` · `CI_low` · `CI_high` · `stored` (locked value) · `n_mediation` |

### 41-arm ranking (Figure 3C)

| File | Columns |
|---|---|
| `s_arm1_rank.tsv` | `arm` (chromosome arm) · `n` · `beta_loss` (arm-loss effect on log10 TMB) · `p_loss` · `n_loss` · `rank_tmb` (rank 1–41 by \|effect\|) · `is_6p` (flag) |

### Neoantigen results — (A) burden and (B) allele-paired (Figure 4; Table S9–S12)

| File | Columns |
|---|---|
| `s_neo1_cohort.tsv` | `item` · `value` (cohort descriptives for the burden analysis) |
| `s_neo1_models.tsv` | `kind` · `definition` (neoantigen definition / sensitivity) · `n` · `n_LOH` · `OR` · `lo` · `hi` · `P` · `source` · `OR_CI` · `P_fmt` |
| `s_neo1_collinearity.tsv` | `x` · `y` (variable pair) · `n` · `spearman_rho` · `P` (e.g. neoantigen count vs TMB) |
| `s_neo2_cohort.tsv` | `item` · `value` (allele-paired design descriptives) |
| `s_neo2_allele_tests.tsv` | `test` · `n_pairs` · `n_samples` · `lost_gt_kept` · `lost_lt_kept` · `ties` · `sign_test_P` · `wilcoxon_P` · `OR` · `lo` · `hi` · `P` · `test_type` · `OR_CI` · `signP` · `P_fmt` |
| `s_neo2_fractions.tsv` | `item` · `value` · `n` · `source` |

### Structural-variant class analysis (reviewer R3-4; `SV_class_analysis.md`)

| File | Columns |
|---|---|
| `s_sv1_summary.tsv` | `item` · `value` (calls, samples, calls/sample) |
| `s_sv1_class_totals.tsv` | `Class` (DELETION / INVERSION / TRANSLOCATION / DUPLICATION / INSERTION) · `N` |
| `s_sv1_class_cross.tsv` | `sv_class` · `n_with` · `loh_pct_with` · `n_without` · `loh_pct_without` · `P` · `P_fmt` |
| `s_sv1_models.tsv` | `model` · `term` · `OR` · `lo` · `hi` · `P` · `N` · `n_LOH` · `OR_CI` · `P_fmt` |
| `s_sv1_distribution.tsv` | `sv_n` (calls per sample) · `n_samples` · `pct` |
| `s_sv1_limitations.tsv` | `item` · `detail` (why signature-level decomposition is not identifiable) |

### Germline / evaluability (Figure S1; Table S7)

| File | Columns |
|---|---|
| `s7_germline_evaluability.tsv` | `locus` · `het_n` · `het_eval_pct` · `hom_n` · `hom_eval_pct` |
| `s7_loh_by_homozygous_burden.tsv` | `gh_burden` (germline homozygous-locus burden 0–2) · `n` · `n_LOH` · `pct` · `freq` · `lo` · `hi` |
| `s7_models.tsv` | `model` · `OR` · `lo` · `hi` · `P` |

### Number-dictionary assertion log

| File | Columns |
|---|---|
| `pin_audit.tsv` | `item` (asserted quantity) · `recomputed` (value recomputed from source) · `PINNED` (locked value) · `match` (TRUE/FALSE) · `mismatch` (TRUE/FALSE) — 80 checks |

---

## 2. `figure_source_data/` — source data behind Figures 1–5, S1, S2

| Figure | File(s) | Columns |
|---|---|---|
| **Fig 1A** | `fig1a_cancer_freq.tsv` | `CANCER_TYPE` · `N` · `n_LOH` · `freq_LOH` · `lo` · `hi` (Wilson) · `cohort_freq` · `cohort_lo` · `cohort_hi` |
| **Fig 1B** | `fig1b_locus_freq.tsv` | `CANCER_TYPE` · `locus` (HLA-A/B/C) · `n_eval` · `n_LOH` · `freq_LOH` · `lo` · `hi` · `freq_any` |
| **Fig 1B** | `fig1b_locus_overall.tsv` | `locus` · `n_eval` · `n_LOH` · `freq` · `lo` · `hi` (pan-cancer per locus) |
| **Fig 1C** | `fig1c_purity_decile.tsv` | `dec` (purity decile) · `n` · `n_armind` · `pct_armind` · `freq` · `lo` · `hi` · `purity_med` |
| **Fig 2A** | `fig2a_tmb_dist.tsv` | `SAMPLE_ID` (de-identified cohort ID, e.g. `P-0000067-T02-IM5`) · `TMB_SCORE` · `group` (HLA LOH / HLA intact) |
| **Fig 2A** | `fig2a_tmb_summary.tsv` | `group` · `n` · `median` · `q1` · `q3` · `mean` · `wilcoxon_P` |
| **Fig 2B** | `fig2b_tmb_log2fc.tsv` | `CANCER_TYPE` · `N` · `n_LOH` · `med_LOH` · `med_intact` · `p` · `log2FC` · `FDR` · `sig` |
| **Fig 2C** | `fig2c_tmb_models.tsv` | `model` · `note` · `N` · `OR` · `lo` · `hi` · `P` · `label` |
| **Fig 2C** | `fig2c_tmb_tertile.tsv` | `tertile` (Q1–Q3 of aneuploidy score) · `N` · `OR` · `lo` · `hi` · `P` · `note` |
| **Fig 3A** | `fig3a_drivers.tsv` | `model` · `term` · `OR` · `lo` · `hi` · `P` · `term_label` |
| **Fig 3B** | `fig3b_mediation.tsv` | `Quantity` · `Estimate` · `CI_low` · `CI_high` · `stored` · `n_mediation` |
| **Fig 3C** | `fig3c_arm_tmb_rank.tsv` | `arm` · `n` · `beta_loss` · `p_loss` · `n_loss` · `rank_tmb` · `is_6p` |
| **Fig 4A** | `fig4a_neo_or.tsv` | `model` · `n` · `n_LOH` · `OR` · `lo` · `hi` · `P` · `P_HC3` (heteroskedasticity-robust P) · `label` · `is_null` |
| **Fig 4B** | `fig4b_neo_pair_or.tsv` | `test` · `n_rows` · `OR` · `lo` · `hi` · `P` · `label` · `is_null` |
| **Fig 4C** | `fig4c_neo_summary.tsv` | `item` · `value` · `n` |
| **Fig 5A** | `fig5a_hr_cancer.tsv` | `cancer` · `model` · `N` · `HR` · `lo` · `hi` · `P` |
| **Fig 5B** | `fig5b_hr_pancancer.tsv` | `model` · `N` · `HR` · `lo` · `hi` · `P` · `note` · `label` |
| **Fig S1** | `figs1_burden_dose.tsv` | `gh_burden` · `n` · `n_LOH` · `pct` · `freq` · `lo` · `hi` |
| **Fig S1** | `figs1_evaluability.tsv` | `locus` · `het_n` · `het_eval_pct` · `hom_n` · `hom_eval_pct` |
| **Fig S1** | `figs1_models.tsv` | `model` · `OR` · `lo` · `hi` · `P` |
| **Fig S2** | `figs2_apobec_dist.tsv` | `SAMPLE_ID` (de-identified) · `group` · `apobec` (APOBEC signature fraction) · `pct` |
| **Fig S2** | `figs2_apobec_summary.tsv` | `group` · `n` · `n_zero` · `median` · `q1` · `q3` · `max` · `n_gt50` · `n_gt90` |
| **Fig S2** | `figs2_effect_sizes.tsv` | `threshold` · `log2_ratio` · `lo` · `hi` · `ratio` · `P` · `n_LOH` · `n_intact` · `n_LOH_hit` · `n_intact_hit` |
| **Fig S2** | `figs2_tail_comparison.tsv` | `group` · `n` · `k` · `pct` · `freq` · `lo` · `hi` · `threshold` · `P` |
| QA | `pin_check.tsv` | `item` · `recomputed` · `PINNED` · `match` · `mismatch` (per-figure number checks) |
| QA | `pin_check_S2.tsv` | `item` · `recomputed` · `PINNED` · `match` (Figure S2 checks) |

`fig2a_tmb_dist.tsv` and `figs2_apobec_dist.tsv` are per-tumour distributions; they carry **only the
de-identified cBioPortal sample barcode** (e.g. `P-0000067-T02-IM5`) and the two plotted variables — no
personal identifiers.

---

## 3. `supplementary_source_data/` — earlier derived summaries retained for traceability

These predate `tables_v3/` and are kept so that every number quoted in earlier drafts can be traced.
Names beginning `Q1–Q4`, `SuppTable*` come from the v1 pipeline (`analysis/04_core_analysis.R`,
`06_table_data.R`); the `Table*`, `Survival_*`, `germline_*`, `mediation_*`, `km_data` files are the
v1-era as-delivered tables.

| File | Columns |
|---|---|
| `SuppTable1_atlas.tsv`, `Q1_pancancer_atlas.tsv` | `CANCER_TYPE` · `N` · `n_LOH` · `freq` · `lo` · `hi` · `n_panHLA` · `freq_pan` · `freq_A` · `freq_B` · `freq_C` · `med_TMB` · `med_purity` · `pct_WGD` |
| `SuppTable2_TMB.tsv`, `Q2_TMB_by_cancer.tsv` | `CANCER_TYPE` · `N` · `med_TMB_LOH` · `med_TMB_noLOH` · `p` · `FDR` |
| `SuppTable3_signatures.tsv`, `Q4_signatures_vs_LOH.tsv` | `signature` · `med_LOH` · `med_noLOH` · `mean_LOH` · `mean_noLOH` · `p` · `FDR` |
| `SuppTable4_survival_bycancer.tsv`, `Survival_by_cancer.tsv` | `CANCER_TYPE` · `N` · `events` · `HR` · `lo` · `hi` · `p` · `FDR` |
| `SuppTable5_panel_sensitivity.tsv` | `Effect` · `Full_cohort` · `Restricted_OR` · `Restricted_lo` · `Restricted_hi` · `Restricted_p` |
| `SuppTable7_zygosity_evaluability.tsv` | `Locus` · `Heteroz_N` · `Heteroz_evaluable_pct` · `Homoz_N` · `Homoz_evaluable_pct` |
| `Table1_baseline.tsv` | `Characteristic` · `HLA intact` · `HLA LOH` · `P` |
| `Table2_drivers.tsv`, `Q3_multivariable_drivers.tsv` | `model` · `term` · `OR` · `lo` · `hi` · `p` |
| `Table2_survival.tsv`, `Survival_multivariable.tsv` | `term` · `HR` · `lo` · `hi` · `p` |
| `Q1_primary_vs_met.tsv` | `CANCER_TYPE` · `SAMPLE_TYPE` (primary/metastasis) · `freq_LOH` · `N` |
| `germline_burden_dose_response.tsv` | `gh_burden` · `N` · `LOH_n` · `LOH_pct` · `lo` · `hi` |
| `germline_burden_models.tsv` | `Model` · `OR_per_homoz_locus` · `CI_low` · `CI_high` · `P` |
| `mediation_WGD_6p_HLALOH.tsv` | `Quantity` · `Estimate` · `CI_low` · `CI_high` |
| `km_data.tsv` | `OS_MONTHS` · `OS_event` · `any_HLA_LOH` · `HLA_LOH_burden` · `CANCER_TYPE` (survival curve input; no identifiers) |
| `cancer_type_hla_loh.csv` | `CANCER_TYPE` · `N` · `HLA_A_LOH` · `HLA_B_LOH` · `HLA_C_LOH` · `HLA_ANY_LOH` · `Mean_N_LOH` · `Median_TMB` · `WGD_Rate` · `HLA_A_Rate` · `HLA_B_Rate` · `HLA_C_Rate` · `HLA_ANY_Rate` |
| `cancer_type_hla_loh_v2.csv` | `CANCER_TYPE` · `N_total` · `N_loh` · `Pct_LOH` · `Pct_A` · `Pct_B` · `Pct_C` · `Pct_3loci` · `Med_TMB` · `Pct_WGD` |
| `summary_statistics.csv`, `summary_v2.csv` | `Metric` · `Value` (cohort-level headline counts) |

---

## 4. `number_dictionary/`

| File | Contents |
|---|---|
| `PINNED_PACK.md` | The locked number dictionary (single source of truth for every reported number). It carries one authorised rounding correction, for the survival HR with the class I arms (6p) excluded: the superseded original is retained **in-line in §2.5** for traceability and is labelled there as the corrected-away value; the locked value is **0.946**. |
| `number_dictionary.tsv` | `variable_id` · `locked_value` · `verification` · `verified_at` — machine-readable form, one row per asserted quantity, generated from `pin_audit.tsv`. |
| `pin_audit.tsv` | `item` · `recomputed` · `PINNED` · `match` · `mismatch` — the 80-check assertion log. `recomputed` is read from source, `PINNED` is the locked value. |

---

## 5. Provenance and integrity

- Every `tables_v3/*.tsv` is written by `build_tables/01_build_tables_V3.R` and asserted against
  `number_dictionary/PINNED_PACK.md`; the script exits non-zero on any mismatch.
- Every `figure_source_data/*.tsv` is written by the corresponding `figures/*.R` script.
- `SV_class_analysis.md` documents the structural-variant alternative analysis requested by reviewer 3.
- Genuine pre-correction numerics are absent from this archive; the only occurrence of a superseded
  value is inside the explanatory text of the correction record, where it is labelled as the superseded
  original.

---

## 6. What is deliberately **not** in this archive

Excluded because the source cohort is **CC BY-NC-ND 4.0** (the NoDerivatives clause forbids redistributing
modified copies) **and** because each file is regenerated verbatim by the deposited code:

| Excluded | Reason |
|---|---|
| `master_cohort.tsv` — per-tumour analysis frame | sample-level; carries cohort sample identifiers; rebuildable |
| `r3p2_aneuploidy_scores.tsv`, `r3p3_aneuploidy_scores.tsv` — per-sample aneuploidy scores | sample-level; rebuildable |
| `s_sv1_sample_counts.tsv` — per-sample structural-variant call counts | sample-level; the aggregate SV-class tables ARE included |
| `r3p2_data.rds`, `r3p3_data.rds`, `r3p4_data.rds` — intermediate R binaries (3–15 MB) | intermediate binaries (>10 MB), not necessary and not redistributable |

**Raw data:** nothing from the cBioPortal cohort is redistributed. Obtain it directly from cBioPortal
(study `msk_impact_50k_2026`). The deposited code and the accession are sufficient to rebuild every table.
