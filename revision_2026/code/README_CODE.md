# `revision_2026/code/` — code for the iScience revision

Every script that produces a number or a figure in the revision is here. The R analysis scripts
hard-code their `ROOT` at the top of the file; point that constant at your checkout.

## Layout

| Path | Contents |
|---|---|
| `build_tables/` | `01_build_tables_V3.R` — recomputes **every** Table 1–3 and supplementary table S1–S13 number from the raw cBioPortal files, writes `build/*.tsv`, and asserts each headline value against `PINNED_PACK.md` (80 assertions; exits non-zero on any mismatch). `build_tables_docx.py`, `build_supplement_pdf.py`, `dump_docx.py` render the DOCX/PDF deliverables from those TSVs. |
| `analysis/v1_scripts/` | Original v1 pipeline (`01`–`07`), kept for provenance. |
| `analysis/v6_scripts/` | Cohort build and core analysis (`03_build_cohort.R`, `04_core_analysis.R`, `06_table_data.R`, `13_sensitivity_mediation.R`, `15_germline_zygosity.R`, …). |
| `analysis/revision_r3/` | Reviewer-3 revision analyses: aneuploidy-score construction and modelling (`r3p2_*`), arm-independent mechanism and 41-arm ranking (`r3p3_*`), purity/coverage/panel reliability models (`r3p4_*`). |
| `figures/` | Figure script set: `00_recompute_inputs.R` builds every input table, `10_fig1.R`…`70_figS2.R` draw Figures 1–5, S1 and S2, `90_qa_overlap.R` programmatically checks label overlap/clipping, `99_run_all.R` runs the set, `fig_common.R` holds shared helpers. |
| `neoantigen/` | netMHCpan-4.2e (primary) and MHCflurry (secondary) pipelines: peptide construction, prediction, statistics and consistency checks. |
| `PINNED_PACK.md` | A copy of the locked number dictionary (the canonical copy lives in the manuscript package). |
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

## Notes

- The revision analyses do **not** change any number in `data/tables_v3/` or `data/figure_source_data/`
  except the single authorised rounding correction recorded in `PINNED_PACK.md` §2.5.
- Figure scripts must run with `bg = "white"` (otherwise the TIFF panels come out black) and are
  checked for label overlap by `90_qa_overlap.R` rather than by eye.
