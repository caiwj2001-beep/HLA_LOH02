# Environment — exact software versions used for the revision

Recorded from the sessions that actually produced the revision numbers, figures and predictions.

| Component | Version | Where it is used |
|---|---|---|
| R | **4.6.1** (2026-06-24, ucrt) | all table/statistics/figure scripts (`revision_2026/code/`) |
| R packages | data.table 1.18.4, survival 3.8-6, boot 1.3-32, readxl 1.5.0 | see `R_sessionInfo.txt` |
| Python (rendering) | CPython **3.12.13** | DOCX/PDF rendering (`build_tables_docx.py`, `build_supplement_pdf.py`) |
| python-docx | 1.2.0 | DOCX rendering |
| pypdf | 6.20.1 | PDF page-number pass |
| Python (neoantigen) | CPython **3.12.13** (`neoantigen/env`) | `revision_2026/code/neoantigen/` |
| MHCflurry | 2.3.14 (models 2.3.0, offline) | secondary neoantigen predictions |
| PyTorch | 2.14.1+cpu | MHCflurry backend |
| statsmodels | 0.15.0 | neoantigen statistics |
| netMHCpan | **4.2e** | primary neoantigen predictions (binding call: `%Rank_EL ≤ 2 %`) |
| netMHCpan host | VirtualBox VM `netmhcpan`, headless, 4 vCPU / 8 GB | netMHCpan run environment |

## Notes

- The revision was run under a newer R than the v1 repository lock (`renv.lock`, R 4.3.3). The lock
  that must be restored to reproduce the revision is `revision_2026/code/env_lock_R.txt`; the root
  `renv.lock` is retained unchanged for the v1 pipeline.
- The Python side performs **no statistics** — it only writes DOCX/PDF from the TSVs that the R
  scripts produce.
- netMHCpan-4.2e is licensed software obtained from DTU Health Tech and is **not** redistributed here;
  only the scripts that drive it are, in `revision_2026/code/neoantigen/`.

Per-component detail: `R_sessionInfo.txt`, `python_versions.txt`, `netmhcpan_4.2e.txt`.
