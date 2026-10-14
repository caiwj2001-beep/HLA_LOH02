derived_data - derived tables for ISCIENCE-D-26-09416 (revision)
====================================================================

CONTENTS
  README_DATA.md             column-level data dictionary: every column, its meaning,
                             its units and the script that produced the table
  number_dictionary/         PINNED_PACK.md      the locked number dictionary for the revision
                             number_dictionary.tsv  machine-readable form (variable -> value)
                             pin_audit.tsv       the assertion log: 80 checks, every
                                                 recomputed value against the locked value
  tables_v3/                 34 tables: every main and supplementary table as delivered, as TSV
  figure_source_data/        26 source-data tables behind Figures 1 to 5 and Figures S1 and S2
  supplementary_source_data/ 24 earlier derived summary tables retained for traceability
  SV_class_analysis.md       the structural-variant alternative analysis (reviewer R3-4)

WHAT IS DELIBERATELY NOT INCLUDED
  Sample-level derived files are NOT in this archive. Excluded here:
    - master_cohort.tsv   the per-tumour analysis frame
    - the per-sample aneuploidy score files (r3p2_/r3p3_aneuploidy_scores.tsv)
    - the per-sample structural-variant call table behind the SV-CLASS analysis
      (tables_v3/s_sv1_sample_counts.tsv; the aggregate SV-class tables ARE included)
  Two reasons. (1) They carry the sample identifiers of the source cohort, which is
  distributed under CC BY-NC-ND 4.0 (NoDerivatives), so redistributing modified copies
  here would breach the source licence. (2) They are regenerated verbatim from the
  cBioPortal source files by the deposited code. The deposited code is the exact code
  that produced every table in tables_v3/.

TABLES ARE DELIVERED AS DOCX in the manuscript package; the TSV copies here are the
machine-readable origin, and every number in a DOCX is read directly from these files.

SOURCE COHORT
  cBioPortal study msk_impact_50k_2026 (Bandlamudi et al., Cancer Cell 2026, PMID 41895280),
  licence CC BY-NC-ND 4.0. Obtain the raw data from cBioPortal; nothing from that cohort is
  redistributed here.
