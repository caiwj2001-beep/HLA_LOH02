# Structural-variant class analysis (alternative to COSMIC structural-variant signatures)

**Purpose.** Reviewer 3 asked why COSMIC structural-variant (rearrangement) signatures were not used. The short answer is that the available structural-variant table cannot support signature-level decomposition. This document reports the alternative analysis we can run - structural-variant class burden against HLA LOH - and documents why the signature analysis is not identifiable.

## 1. Input data

- File: `msk_impact_50k_2026/data_sv.txt` (gene-level rearrangement calls, provided by the data source)
- Calls: **15811** rows
- Samples with at least one call: **12502** (23% of the 54,331-sample cohort)
- Calls per sample: median **1**, mean 1.26, maximum 6
- Distinct partner-gene combinations: 5211

Class totals (these reproduce the locked number dictionary exactly):

| Class | Calls |
|---|---|
| DELETION | 6225 |
| INVERSION | 3738 |
| TRANSLOCATION | 3644 |
| DUPLICATION | 2203 |
| INSERTION | 1 |

## 2. Models for HLA LOH

Logistic regression of `any_HLA_LOH` on the structural-variant term plus cancer type, gene panel and FACETS tumour purity; the last two models additionally adjust for the global aneuploidy score. All models use the 29,799-tumour primary analysis cohort.

| Model | Term | OR (95% CI) | P | n |
|---|---|---|---|---|
| SV present (≥1 call) + cancer + panel + purity | sv_any | 1.249 (1.172–1.331) | 6.47e-12 | 29799 |
| SV count (per additional call) + cancer + panel + purity | sv_n | 1.157 (1.108–1.208) | 4.90e-11 | 29799 |
| SV present + cancer + panel + purity + aneuploidy | sv_any | 1.068 (0.999–1.142) | 0.0533 | 29799 |
| SV count + cancer + panel + purity + aneuploidy | sv_n | 1.028 (0.981–1.076) | 0.2462 | 29799 |

**Reading of the result.** Structural-variant presence is associated with HLA LOH before aneuploidy adjustment (OR 1.249 (1.172–1.331), P = 6.47e-12) and the association attenuates to the null once the global aneuploidy score is included (OR 1.068 (0.999–1.142), P = 0.0533). The count-based specification behaves identically (1.157 (1.108–1.208), P = 4.90e-11 versus 1.028 (0.981–1.076), P = 0.2462). Structural-variant burden therefore appears to be another expression of the same genome-wide instability captured by the aneuploidy score, not an independent determinant of HLA LOH.

## 3. HLA LOH frequency by structural-variant class

| Class | n with | LOH % with | n without | LOH % without | P |
|---|---|---|---|---|---|
| deletion | 3239 | 25.35 | 3927 | 29.13 | 0.0004 |
| duplication | 1189 | 31.62 | 5977 | 26.59 | 0.0004 |
| insertion | 7166 | 27.42 | 22633 | 24.69 | <0.001 |
| inversion | 1938 | 30.44 | 5228 | 26.3 | 0.0005 |
| translocation | 1937 | 26.17 | 5229 | 27.88 | 0.1586 |

## 4. Calls per tumour

| Calls per tumour | Samples | % of primary cohort |
|---|---|---|
| 0 | 22633 | 75.95 |
| 1 | 5626 | 18.88 |
| 2 | 1229 | 4.12 |
| 3+ | 311 | 1.04 |

## 5. Why COSMIC structural-variant signatures were not used

- **Annotation granularity** - Gene-level rearrangement calls only (Site1_Hugo_Symbol / Site2_Hugo_Symbol + Class); junctions are not reported base-pair-resolved for most rows
- **Calls per sample** - Median 1 (maximum 6) across the 12502 samples carrying any call; 77.0% of the 50K cohort has no SV call at all
- **Distinct partner-gene combinations** - 5211 combinations across 15811 calls — highly heterogeneous, so per-class counts are dominated by singletons
- **Read support reported** - Paired-end and split-read support plus confidence class are given, but no copy-number-neutral/double-minute or clustered-junction annotation
- **Usable for COSMIC SV signature decomposition?** - No. Signature-level SV analysis needs base-pair-resolved junctions and an appreciable number of calls per tumour; with a median of 1 gene-level call per sample and 76.9% of samples empty, COSMIC SV (rearrangement) signature fitting is not identifiable in this table. We therefore report SV class burden only, as evidence of why that analysis is not feasible, and as an association with HLA LOH.

## 6. Source files

- `V3/03_tables/build/s_sv1_sample_counts.tsv` - per-sample call counts and per-class counts
- `V3/03_tables/build/s_sv1_summary.tsv`, `s_sv1_class_totals.tsv`
- `V3/03_tables/build/s_sv1_models.tsv`, `s_sv1_class_cross.tsv`, `s_sv1_distribution.tsv`, `s_sv1_limitations.tsv`
- Analysis script: `V3/06_compliance/deposit/code/01_build_tables_V3.R` (section S-sv1)
