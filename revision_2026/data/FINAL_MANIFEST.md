# FINAL_MANIFEST - frozen submission package (V4, revision round 2)

Manuscript **ISCIENCE-D-26-09416** (iScience revision) . directory `iscience投稿版本/V4` . generated 2026-10-17 10:56:47

Every file below is byte-frozen: `sha256` and `bytes` are of the file as it stands on disk at
generation time. Repository snapshot referenced by the manuscript and by the Key Resources
Table: `https://github.com/caiwj2001-beep/HLA_LOH02` at commit `08fe6775ad9548472177a97bf1a9458a743f5fc0`, which carries both the
analysis code and the derived data; the two deposit archives are byte-reproducible from it
(`revision_2026/code/tools/check_repo_vs_zip.py`: 100/100 members byte-identical).

- **files listed: 127**
- **missing on disk: none**
- **total bytes: 9965364 (10.0 MB)**
- **this file: 242 lines**

---

## 00_pinned/ - locked number dictionary and correction record

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `00_pinned/PINNED_PACK.md` | 15238 | `39ce8ee318aec44ede4f4dd91086949ec72e1caac102850ee708c19750d7b31c` | The locked number dictionary: the single permitted source of every reported number |
| `00_pinned/PINNED_PACK_CORRECTIONS.md` | 142084 | `e1687beda2594342a0c72ea821bd0e2465e0d9d4336b4491117b3f3dc2aa446b` | Corrections and audit record; sections (v)-(xiii) as before, plus (xiv) the 2026-10-17 V4/P3 freeze: the 16 manuscript edits, the five systemic corrections, S14, the deposit/commit record, word counts, highlight coverage and the known residuals |

---

## 01_manuscript/ - manuscript sources and the two manuscript DOCX

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `01_manuscript/01_TitlePage.md` | 974 | `93b912f479996a99281bbbd7b20468cc4c63ff73017b263930f6d6b4e837074a` | Title page (title, authors, affiliations, corresponding author) |
| `01_manuscript/02_Summary.md` | 1122 | `c1ce6c461009fca3a39b0df08612769ce76951156f5605e5591764686457e9e7` | Summary / abstract |
| `01_manuscript/03_Highlights.md` | 339 | `df220e033cbaeb61ce57621c6c334ceeaf8e532a19c2dc902a4c2cf4dad6116a` | Highlights (4 bullets, <=85 characters each) |
| `01_manuscript/04_eTOC.md` | 460 | `d7014957caf6768dafbe8239918f6a25f7348d703614ab9d6d32ecc51f4703c5` | eTOC blurb (one-sentence teaser) |
| `01_manuscript/05_Introduction.md` | 4729 | `23ba9e85ac73ccede2f2bb830b91941f1a6fcb6422806185cab2ba15b3b9dbfe` | Introduction |
| `01_manuscript/06_Results.md` | 15749 | `9045154ef5ab3924af9d87874a96fe14a4071743a15762b10a121db2ff476c9f` | Results (figure numbers in first-appearance order) |
| `01_manuscript/07_Discussion.md` | 10821 | `0c7331ef5a3c3678ac29b5513295a89c9db497423ed3124d5d7e64bd65e7d782` | Discussion |
| `01_manuscript/08_StarMethods.md` | 17020 | `760bc77cde8839205c8ef7a2599b8e08e5a44264216cecdc7f65ad58d9c2ebc5` | STAR Methods incl. Data and code availability (carries the repository commit) |
| `01_manuscript/09_BackMatter.md` | 2691 | `2a2ca99b342427d9ba9940d907cb2782faaa57b84c2ff79ea6ff1639bbbefbbe` | Back matter incl. the Data and code availability declaration (carries the repository commit) |
| `01_manuscript/10_FigureLegends.md` | 8818 | `a6d1200f4f8f397a88007623ab4fae3df6491fa4ba3553ab415681b004507d92` | Figure legends, Figures 1-5 and S1-S2 |
| `01_manuscript/11_References.md` | 10482 | `e4da6ae142ee07dfbe0151ae95ac335ce768b4801dff93db8e51bdfb703d8b46` | Reference list |
| `01_manuscript/HLA_LOH02_revision_MARKED.docx` | 68685 | `fb6cf97faf7fe0aabba57ba18073906d883e5a9cb11bf1e30fc409804debcace` | Revised manuscript, changes highlighted in yellow (Mode C substantive-change rule; 29.30% of characters, 101/174 paragraphs) |
| `01_manuscript/HLA_LOH02_revision_CLEAN.docx` | 63888 | `f18234898cface44e92c2f991a6156c1b41825c13f6604da579eae57dfe1f348` | Revised manuscript, clean copy (no markup) - the file the editor typesets from |
| `01_manuscript/Change_Summary.md` | 118705 | `cef3cdaf071251de3049868a04f45e3dcf18ddaaceabfe76a640901ea2929f83` | Editor-facing section-by-section change list (copy of 05_response/Change_Summary.md) |
| `01_manuscript/HLA_LOH02_revision_HIGHLIGHT_SUMMARY.md` | 17596 | `4d0ca8ccf5e4eba3afdff09292efc1f514b652e3a7d0db57958d132dd2fa2a88` | Revision highlight summary (Mode C rule; superseded rules marked obsolete) |
| `01_manuscript/REF_VERIFICATION.md` | 13042 | `fd96b89e08d6c1147c85a568363cec4ff5662fdeaf2760d0b4ef09a269963c9d` | Reference verification report |
| `01_manuscript/SENTENCE_STATS.md` | 15070 | `7aa8ad1a53bcaa6de79616df321fc399ce9fce9128317784de0300eeaa42605e` | Sentence-length / readability statistics of the revised manuscript |
| `01_manuscript/11b_FigS2_addition_note.md` | 7382 | `d9ad070318824d6cfcae7f3456fdc45ad054c9784317194200183a32f191859c` | Working note on how Supplementary Figure S2 entered the reference list |
| `01_manuscript/_alternative/HLA_LOH02_revision_MARKED_full.docx` | 69550 | `b8aab7477c48a0e5f1f8b04c7faded45567f8d243063571ada6c748d09ed5ec9` | Alternative (superseded) full-mode build at 62.5% coverage, kept as the rollback pair |
| `01_manuscript/_alternative/HLA_LOH02_revision_CLEAN_full.docx` | 63888 | `b04f16973e216a0210856b2e53582a1576e29918d420e83bb37caad44119c30d` | Clean twin of the alternative full-mode build |

---

## 02_figures/ - the 14 figure files and the figure QA report

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `02_figures/Figure1_pancancer_and_reliability.tiff` | 605466 | `b5b60038df6dd615d7fb61b6f630398cb0c6500b939c1fe2a7e945ba85f5d470` | Figure 1 - 300 dpi TIFF, white background |
| `02_figures/Figure1_pancancer_and_reliability.pdf` | 61871 | `5ceb56e4222386803d60768fa01963c45f690100e5879ce33eb524a36c4073af` | Figure 1 - vector PDF twin |
| `02_figures/Figure2_mechanism_armlandscape.tiff` | 327454 | `8af788faacc687d26531c4144e3a70d86b9f9740a76996afc2550725fe68d9ec` | Figure 2 - 300 dpi TIFF, white background |
| `02_figures/Figure2_mechanism_armlandscape.pdf` | 58468 | `70b2b1605b513a0d9339361e0a1d8f9bd9d11ba4e357c6521a8afc89b5a5a0b7` | Figure 2 - vector PDF twin |
| `02_figures/Figure3_TMB_aneuploidy.tiff` | 430792 | `60935ae13037d5e00db871e8be482c30521627dfb9af8d0ee5d90c757c4e1e48` | Figure 3 - 300 dpi TIFF, white background |
| `02_figures/Figure3_TMB_aneuploidy.pdf` | 922047 | `dc508c6d8557cd689e630b5855c6e4f06a841cff4640abcb42f5efba55c6f8b1` | Figure 3 - vector PDF twin |
| `02_figures/Figure4_neoantigen.tiff` | 291004 | `17606ab091f0bdae160f6c4223c99a84909bb3e159b8ea3676356ff699d71b79` | Figure 4 - 300 dpi TIFF, white background |
| `02_figures/Figure4_neoantigen.pdf` | 55416 | `147d58ed83c4f3d732fb7737fda466108b2c9759ff9a843e91376811df0bd5b3` | Figure 4 - vector PDF twin |
| `02_figures/Figure5_survival.tiff` | 202070 | `7ece4183dee2de95bac1e494b21fc6fda4aca078e5ae232a1bfc39134ebe6500` | Figure 5 - 300 dpi TIFF, white background |
| `02_figures/Figure5_survival.pdf` | 46576 | `c7257f42c291b6f0ec9d878a2fcb65a2de5970b8ae03a6b368724a45ac380a40` | Figure 5 - vector PDF twin |
| `02_figures/SupplementaryFigureS1_apobec.tiff` | 391582 | `a0b43ab03ddbed09a9ffca4e4d13292997ea74a4a04057bbde121efde5c245b2` | Supplementary Figure c - 300 dpi TIFF, white background |
| `02_figures/SupplementaryFigureS1_apobec.pdf` | 391411 | `3814e8501c644bc075327e5b85ad3dc3c7bff0c124d6023b3e7bc9d2134d586f` | Supplementary Figure c - vector PDF twin |
| `02_figures/SupplementaryFigureS2_germline.tiff` | 178352 | `92f2f27b1238277f90fe3e5e75c84fa4758a8f64187309ede25410002088bf24` | Supplementary Figure e - 300 dpi TIFF, white background |
| `02_figures/SupplementaryFigureS2_germline.pdf` | 44301 | `297b012d8c2c85ad941fd909392abcd707e576b371a3ad2e8e4a69d908c66130` | Supplementary Figure e - vector PDF twin |
| `02_figures/QA_figure_check.md` | 20282 | `0d1e32929b311e00c366681fe0fe1b7aaeecd034cf2d3c0291ddcadfa5e7ca16` | Programmatic figure QA (overlap / out-of-frame / axis-label / raster gates); all gates 0 |

---

## 03_tables/ - main tables, the supplementary-tables DOCX and the source TSVs cited by S11/S14

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `03_tables/Table1_baseline.docx` | 38750 | `ed04e88c16dcacca52096aec18028aa98bf285b6a269b0216eea215cd8314fb9` | Table 1 - cohort baseline characteristics (incl. the global aneuploidy score rows) |
| `03_tables/Table2_drivers.docx` | 38796 | `45ebd83322d2b19da9d5f95faf066506fa5e45f232cf9b53892820f97836f890` | Table 2 - multivariable drivers of HLA LOH; footnote attenuation endpoints (WGD 2.30->0.35, log10 TMB 1.45->1.23) are read from table2_drivers.tsv at build time |
| `03_tables/Table3_survival.docx` | 38495 | `b3eff2458bc055254519613c29799748fac44a75f7450c2a78d347b4c2b88b59` | Table 3 - HLA LOH and overall survival across model specifications |
| `03_tables/Supplementary_Tables.docx` | 629436 | `13ec2ed3c202c91d92f6c8c30fff728d44f133b10ae203689486081808265bed` | Supplementary Tables S1-S14 as one DOCX, contents table page-mapped to the supplement PDF |
| `03_tables/SV_class_analysis.md` | 4551 | `14b805eef8b444adb125c11f5d8f43648df342e904917ed21b386a4a1878b71c` | Structural-variant class analysis against HLA LOH (source narrative for S13) |
| `03_tables/build/s14_vif.tsv` | 2161 | `f6dd1f7d7ebd92193e9b437de6387e5874daba8a860f62eec71a0e1988799991` | S14 source data: variance inflation factors, GVIF, adjusted GVIF and tolerances per model and covariate |
| `03_tables/build/s14_model_key.tsv` | 553 | `244360494a7b7aa658c71d10704aa0d154bd61144d04f3d42e099f9fe747c0a8` | S14 model key: the specification each VIF model corresponds to |
| `03_tables/build/s_neo1_models.tsv` | 2144 | `a0ff1ca821cc707545d3755942c6deba0ffebf0858c558da9ec93b2bab73bf4e` | S11 source data: the clonal-restriction and purity>=50% rows carry the primary-specification values and the provenance file that produced them |

---

## 04_supplement/ - the single supplementary PDF

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `04_supplement/Supplemental_Information.pdf` | 1591181 | `1058220f28c4063eaafede8861370469f79d6dc4427b17bf9b34d3da63a3c9eb` | The single supplementary PDF: Figures S1-S2 then Tables S1-S14; 21 pages, 16/16 contents anchors resolved, S14 on the last page |

---

## 05_response/ - response to reviewers, anchors and verifiers

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `05_response/Response_to_Reviewers.docx` | 60448 | `f7cad0a866b5f8ad85eda896320a23d59d0600a789b2f0609bede03bfebbfb4a` | Point-by-point response to all reviewers (9,477 words incl. the restored compliance table) |
| `05_response/Response_to_Reviewers.md` | 65503 | `310271164bd08a428d39348def959bd9389d70ccd01102164d89f949f4ef85dc` | Markdown source of the point-by-point response |
| `05_response/ANCHOR_MAP.tsv` | 3180 | `9ea2fdeb874d37cfe0f0e886a50d316ddba30ed5cd57a14126a942f78f444ce4` | Machine-readable map of every response point to its manuscript anchor (28 rows) |
| `05_response/ANCHOR_INVENTORY.tsv` | 86045 | `e8a136214284c760a1da14b9ebb2cef2e3b3fd12a6fd8becb0427743eae364f6` | Inventory of the manuscript sentences the response points cite |
| `05_response/COVERAGE_CHECK.md` | 37459 | `0b9adb8163f4ce0760f41fa79c8208972f1ddf5ce1b87258d777f3b208c3ccda` | Coverage audit that every reviewer point is answered |
| `05_response/Change_Summary.md` | 118705 | `cef3cdaf071251de3049868a04f45e3dcf18ddaaceabfe76a640901ea2929f83` | Editor-facing section-by-section change list |
| `05_response/verify_anchors.py` | 4871 | `fe8fd7efd5382f3ae05ca711ea8e5786f93984a9fef9490eb4477c6c8b134227` | Anchor verifier: 28 anchors must match in the markdown and in both manuscript DOCX |
| `05_response/verify_response.py` | 8731 | `db857bef15ea9d1cd2c228326834dd1287f2e1d64097ea81e307fc35d9e19e7e` | Response-letter verifier (no fabricated line references, anchor rows consistent) |

---

## 06_compliance/ - compliance, deposits and graphical abstract

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `06_compliance/Data_and_Code_Availability.md` | 3782 | `ffa06912cf7813c1813763f7aaf39dddec877352c8a5a8ec0763cc0d80fdec17` | Data and Code Availability statement (public GitHub repository at commit 08fe6775ad9548472177a97bf1a9458a743f5fc0 is the single and complete route) |
| `06_compliance/Key_Resources_Table.docx` | 38961 | `adefae3e2f4fb308b716e0a21c8fc06b0758d8d56f5c696814aa166c095a5e66` | Key Resources Table; the Derived data / Code rows carry the repository commit 08fe6775ad9548472177a97bf1a9458a743f5fc0 |
| `06_compliance/deposit/code.zip` | 116148 | `ddcf9d119fc90b9557b204ea2f7bcbfb916aeeafb2d7b38409829bc26dc7935a` | Code deposit (9 members): the R analysis script, the DOCX/PDF rendering scripts with the P3 guards, env lock, requirements, README_CODE.md and the number dictionary |
| `06_compliance/deposit/derived_data.zip` | 656372 | `743559495df484910f427411a0a3229effde6c63292d8c2823a026273a54e2a3` | Derived-data deposit (91 members): figure source data, supplementary source data incl. the rebuilt Table1_baseline.tsv, the table build inputs and the number dictionary |
| `06_compliance/deposit/README_upload_steps.md` | 3054 | `aadfce89e849e92b7ba6e2ce7b59f4ef7c7f9c64d56395dff1ee39be7d2985cb` | Author-facing upload runbook (GitHub only; no archival identifier) |
| `06_compliance/Graphical_Abstract/Graphical_Abstract.tiff` | 463738 | `4ea81270e6ac7ffe737c7d2ceed01c1604991f97357f890cd3f5dca931f41b16` | Graphical abstract, 300 dpi raster (uploaded to EM) |
| `06_compliance/Graphical_Abstract/Graphical_Abstract.pdf` | 74540 | `39429eded22087434795a8212e8c7192f2a37fca11002c85fd2c9ee8983e7742` | Graphical abstract, vector PDF |
| `06_compliance/Graphical_Abstract/Graphical_Abstract.pptx` | 35277 | `09c5e29547229511a432e49355185ee0f58a0910703dc24e31d3b1a841faee4a` | Graphical abstract, editable PPTX |
| `06_compliance/Graphical_Abstract/Graphical_Abstract.svg` | 65780 | `cc464020fdb92c77aefe6f0f952593277d1cf671c8ea9ff5c0ef5b93e24db1e0` | Graphical abstract, editable SVG |
| `06_compliance/Graphical_Abstract/GA_TEXT.md` | 8810 | `02326129fc7b5960239ef7a0d90c55e04ccfa4d6ffed5059ba43a4207f39c573` | Graphical-abstract caption text |
| `06_compliance/Graphical_Abstract/GA_QA.md` | 8999 | `97eaa5d26c149221210cd87d842fdb65235d7b68633be2c8fe7c6af638ac1509` | Graphical-abstract QA record |

---

## 07_cover/ - cover letter

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `07_cover/Cover_Letter.docx` | 40750 | `8a1409d937125f0f66d5c94090c4ea45e27eed42c7406ef9cd76e4cb2a4790cd` | Cover letter to the editor |
| `07_cover/Cover_Letter.md` | 7779 | `96dbd3fb8ffecbd26a771822fcca959c1c873c726afd5e0b1b7bbdbc32c91b90` | Markdown source of the cover letter |

---

## QC/ and QC/P2/ - reports and machine-readable evidence for this round

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `QC/FINAL_QC_REPORT.md` | 34606 | `8ed6c775f3349046e36bf5f4f483a3f4548daefca23b49fbaaf58f91a9e41d7e` | Final QC report (gate battery, numbers, deviations) |
| `QC/quality_gates_log.md` | 22529 | `55585f302b8cb9bc82b0092718cac5225d276149cf146c279b2bb3ffccf3e4a0` | Quality-gate log |
| `QC/SUBMIT_READINESS_REPORT.md` | 46723 | `4d26c1bb596bbc0dc90b93ce42687ca548184b078189c94ddf60c1e2baaf937a` | Submission-readiness report |
| `QC/HIGHLIGHT_VERIFY_MODE_C.md` | 13137 | `b45dfa9ebba0959462c59516abcf0a54cfe8bac0abe7a1b1aedca6932b2c7c40` | Mode C highlight verification (ALL GATES PASS) |
| `QC/HIGHLIGHT_VERIFY.md` | 7072 | `e1f32a6995ff58647aeda790a78e48c453599b0b5bd31da90969ce4cb83187f1` | Earlier three-tier highlight verification |
| `QC/docx_build_report.md` | 21897 | `3161f50a599e42d70d68ec60badcbac3a0422787bf61d1db98df4c11629635e7` | DOCX build report |
| `QC/DOI_FILLIN_CHECKLIST.md` | 7406 | `e9235dfdae97476597c498637a642016496245076de57a34980420f9b7f56679` | DOI fill-in checklist |
| `QC/RENUMBER_TO_FIGURE_ORDER_REPORT.md` | 39718 | `06326eb16e335e6cb16b51a333fb9ca22df1ac11b2ed77f823466c20840c2833` | Figure renumbering report |
| `QC/P2/VIF_REPORT.md` | 25338 | `7f6589a261c5d17cccf01ff889d7aff5bebb10d9be88af8eccd51646c3aa9441` | VIF / near-collinearity analysis report (S14 basis) |
| `QC/P2/S14_AND_SUPP_REPORT.md` | 29452 | `5eb663e3ceee0fe224a40f633bf8790057d6321d7dd386c7b94a3751849ad868` | S14 addition and supplement rebuild report |
| `QC/P2/TABLE_FIX_REPORT.md` | 22176 | `ffbdf35083c62a299ced671f24577bd00171fb505d195344813a6bf135884aaa` | Table defect-fix report (Table 1 rebuild, Table 2 footnote, S11 rows) |
| `QC/P2/PURITY_PANEL_REPORT.md` | 24784 | `c55a208efb629d2ba2c73b59d00f455991fc36fce40deab5e1fd5f8606b80eca` | Purity / coverage / panel-version analysis report |
| `QC/P2/MANUSCRIPT_EDIT_REPORT.md` | 43577 | `831e81df5a81e3993c98b07d80242b0ae64a5dad4009de0354ae69282849360a` | The 16 manuscript edits of this round, with location and rationale |
| `QC/P2/RESPONSE_REVISION_REPORT.md` | 21618 | `6ff96593e7f342f1c35fa38df15e75d772be65aa1e667481152d5afd05aea485` | Response-letter revision report |
| `QC/P2/RESPONSE_TABLE_RESTORE_REPORT.md` | 27173 | `92e6d1642a19265e7e0f55109c0b3153fd50a56ab043e84534fafbc43257a568` | Compliance-table restoration report (word count back to 9,477) |
| `QC/P2/supp_pdf_verify.json` | 2039 | `e4fddfccd25e863ce5f42b0d23f80fdbdba3208852028dd4bb083a9eedc69d1a` | Machine-readable supplement verification (anchor pages, TOC vs actual, zero-P scan) |
| `QC/P2/s11_purity_finalize.tsv` | 578 | `a437dc7aeff23330b03a84b5fb479f53003e8b5f458659de6a636e4e378e5091` | S11 purity>=50% re-derivation: legacy vs primary specification, with the IRLS check against A_logistic.tsv |
| `QC/P2/clonal_or_definitive.tsv` | 1535 | `6d5765bc1a92be3c8028286c02f5fc3813f8bba60ff1cf0569757b962a27ebd5` | Clonal-restriction neoantigen OR with the full adjustment set |
| `QC/P2/purity_and_panel.tsv` | 6741 | `4e6ae20e314bb5b1522499bfa64e9b5dc967ed81ee7c591a8b12ecc0c9f1d336` | Purity-decile / coverage / panel models |
| `QC/P2/vif_diagnostics.tsv` | 174593 | `f657b148358528f665bf1b27b6c90aebcf0d1868c07d57e333d798f206889450` | Full VIF diagnostics table (all specifications, all covariates) |
| `QC/P2/_p3_zip_surgical.json` | 47556 | `7736a5d512becf0eb9a5daf080ab7e85473276f345487e2f79a5224c5c066be8` | Member-by-member record of the surgical deposit rebuild (old/new sha256) |

---

## QC/P2/ - the scripts that produced this round

| file | bytes | sha256 | purpose |
|---|---:|---|---|
| `QC/P2/_editengine.py` | 987 | `29d314acb836edbfec7b69b40d88405326d34bd18a43b56e317a9c300906812a` | P3 QC script |
| `QC/P2/_p3_zip_surgical.py` | 9310 | `dee542bf7ba6c52f2227bc6da66a349e75a2ae6cf61bad93ce782b7e43640360` | P3 QC script |
| `QC/P2/_scan000.py` | 1012 | `eb27e9b7855a349cb303f82b1505a3a6c2a95173d6b58b9768a7d427abbbca1f` | P3 QC script |
| `QC/P2/_scan000ctx.py` | 530 | `7aa3b82e31089957306c5a7af1bd77bb184c55110e074ac6abd70d09f26b418b` | P3 QC script |
| `QC/P2/abbrev_changes.py` | 4067 | `3fe2caf9f147f28556c28362914d43f7b2732f016f87cb966d9d261d0eb08589` | P3 QC script |
| `QC/P2/apply_edits.py` | 3799 | `1f7b205e6ae0486627fa05bd717303fa2ab6ab61fae1d178405f7863c0895836` | P3 QC script |
| `QC/P2/apply_final.py` | 3512 | `9bd883a398cfd97722d73bfae49bd883a5f0601f02e2d2d4e0c235740de5e0db` | P3 QC script |
| `QC/P2/apply_v2.py` | 3259 | `29969ee31fb5d75318d50908631bc6ad1ebf2f43cc6e6be193fb712e01f5a88a` | P3 QC script |
| `QC/P2/apply_v3.py` | 3591 | `6a5ad1ecc960b9756f7475509ca459c67d1d007b5bf2d31feb124fab431e3900` | P3 QC script |
| `QC/P2/apply_writer_edits.py` | 10736 | `18f7bcc1d4661e56a1bce2010c8178de1c4e2814968b2551d6721783a5330510` | P3 QC script |
| `QC/P2/edits_part1.py` | 22056 | `6d480fdd496a352bcbbcd9d5b65c6263f3bb419793d40badf5db94ecc1e54182` | P3 QC script |
| `QC/P2/edits_part2.py` | 26450 | `8e703b89a601f737ae83dcd63c7437459f772f4c0b058084cf8d7f7a23b23d13` | P3 QC script |
| `QC/P2/edits_part3a.py` | 22086 | `41f2a6fed7510603eb5b056de00f34b95f2c52c7fc9253b794b9e2aa2e4714ad` | P3 QC script |
| `QC/P2/edits_part3b.py` | 16806 | `354d6a73e4ca09c1dd2834de482d5bd07113b6213fa8cae003d1d50a8ac017d8` | P3 QC script |
| `QC/P2/edits_part4.py` | 26420 | `a9a141268771b55dd64cca0beaca349851c532620a82fdc93d749da61cd43022` | P3 QC script |
| `QC/P2/edits_part5.py` | 25095 | `50aafaf809617179bcfb5dc859f954cbd278b1e8ba155f5f199257d3947832cb` | P3 QC script |
| `QC/P2/edits_part6.py` | 8013 | `d4eed34a631796f997abd81c08f7c62f3907a02ad16c6908f291bdbb4404d94f` | P3 QC script |
| `QC/P2/final_polish.py` | 12477 | `b0a6ec27637cc1e7e6a695e9cb46212584aa8a8779fb1964812f234f962c4933` | P3 QC script |
| `QC/P2/final_polish2.py` | 12066 | `8953050569f07829e86a4d3faa939d72c57f85ea080abaa2794cd601107c86b1` | P3 QC script |
| `QC/P2/fix_s11_provenance.py` | 4111 | `7b514279241827077c3ce3780a159d3c0b1122a150ac090695dc7e26f1926bf4` | P3 QC script |
| `QC/P2/gen_p2_evidence.py` | 3520 | `81f0270c68f08a256d56ab6125d51dbfc325ac322ddb7dc4db5c5ac9f8f96100` | P3 QC script |
| `QC/P2/gen_response_report.py` | 13612 | `4d57036477013b2bf039a44050aa50ea051d5ee10f41c71e1447738bd31f57da` | P3 QC script |
| `QC/P2/make_edit_report.py` | 23980 | `844fd98de2f67ff960a50154ee8c8ee9f79f6da21d5452fc63314ae4363af0ad` | P3 QC script |
| `QC/P2/make_final_manifest_p3.py` | 15720 | `c4a60c34c355c3b66daf06a28b0fc299a5ec06aa6f67b91c33ef98e4fb339a1c` | P3 QC script |
| `QC/P2/make_s14_vif.py` | 5449 | `8fb6c50d5f65ebaf40cfc538d86207b96b80228a68c03a61ed9d419d79755e5b` | P3 QC script |
| `QC/P2/rebuild_compliance_v4.py` | 1711 | `a193b49a7575ce023d91936abbdb353fac21ffccd2c1963723d20b2cad2cc164` | P3 QC script |
| `QC/P2/rebuild_deposit_table1.py` | 2467 | `02369ac95b410e4dd84c87eb1a3be378d06390229f337d2facba8d8729c24bbf` | P3 QC script |
| `QC/P2/rebuild_supplement_pdf_v4.py` | 2582 | `083ec25c30eb2d1086014f7a8e5eb7a1f1de3c006918e4a6d31305cebb04d501` | P3 QC script |
| `QC/P2/rebuild_tables_v4.py` | 2372 | `52133d3e662a3fa2969b765ab694bc6e5a643d6895955484806793d5df69cebf` | P3 QC script |
| `QC/P2/run_gates_v4.py` | 6988 | `abd29e28060e3d2af29243be3b26ad5dc6d1dbd3462e0b618def1562e2ef8c62` | P3 QC script |
| `QC/P2/run_revision_docx_v4.py` | 3869 | `d174dac34c3df7fdfbccd8fbf8c9bf2f93ba1d79dc1a82efe5fb262143caadf9` | P3 QC script |
| `QC/P2/s11_purity_finalize.py` | 6874 | `026d5b41ea13cda73e79de0b6a0ac7da14b1243006c37a8114b30bc33c08f330` | P3 QC script |
| `QC/P2/table_text_crosscheck.py` | 22983 | `b9764cdc794fafc6454c4cc1a69e0f066ef758c922fef9a8b602644da51c9e2c` | P3 QC script |
| `QC/P2/verify_docx_residue.py` | 1903 | `156573ce89109bb2573f607a7333908e4ccff443aacbcbafe8ded209c86ded39` | P3 QC script |
| `QC/P2/verify_numeric_invariant.py` | 4467 | `d136b36e26fa7ee8c28245337052d1f6ca45500abcf922caf5e8e1e85b64aae2` | P3 QC script |
| `QC/P2/verify_supp_v4.py` | 6112 | `c45769edd8e709e6a0074e24e15228a3664118f4e7e235017ae065998a156522` | P3 QC script |
| `QC/P2/clonal_or_definitive.R` | 12496 | `b3b2d9f2d6277ef2e80d7cfed5b93cbd5c92286e71eca9a997fe974161b48393` | P3 analysis script (R) |
| `QC/P2/purity_and_panel.R` | 16881 | `e415e3e9c495d002c1218dd43df0faf122d708f487dfb8a1e6f786b60c0b962a` | P3 analysis script (R) |
| `QC/P2/vif_diagnostics.R` | 24323 | `c8981809376a9ade224f0ed3d237affd08a27e9538e1bd3c6fba8d316c5c9b41` | P3 analysis script (R) |

---

## Submission package - what is uploaded to Editorial Manager, under which item

| upload order | file | Editorial Manager item | why / note |
|---:|---|---|---|
| 1 | `02_figures/Figure1_pancancer_and_reliability.tiff` | Figure 1 - Figure file (TIFF) | 605466 bytes |
| 2 | `02_figures/Figure1_pancancer_and_reliability.pdf` | Figure 1 - Figure file (PDF) | 61871 bytes |
| 3 | `02_figures/Figure2_mechanism_armlandscape.tiff` | Figure 2 - Figure file (TIFF) | 327454 bytes |
| 4 | `02_figures/Figure2_mechanism_armlandscape.pdf` | Figure 2 - Figure file (PDF) | 58468 bytes |
| 5 | `02_figures/Figure3_TMB_aneuploidy.tiff` | Figure 3 - Figure file (TIFF) | 430792 bytes |
| 6 | `02_figures/Figure3_TMB_aneuploidy.pdf` | Figure 3 - Figure file (PDF) | 922047 bytes |
| 7 | `02_figures/Figure4_neoantigen.tiff` | Figure 4 - Figure file (TIFF) | 291004 bytes |
| 8 | `02_figures/Figure4_neoantigen.pdf` | Figure 4 - Figure file (PDF) | 55416 bytes |
| 9 | `02_figures/Figure5_survival.tiff` | Figure 5 - Figure file (TIFF) | 202070 bytes |
| 10 | `02_figures/Figure5_survival.pdf` | Figure 5 - Figure file (PDF) | 46576 bytes |
| 11 | `02_figures/SupplementaryFigureS1_apobec.tiff` | Supplementary Figure c - Figure file (TIFF) | 391582 bytes |
| 12 | `02_figures/SupplementaryFigureS1_apobec.pdf` | Supplementary Figure c - Figure file (PDF) | 391411 bytes |
| 13 | `02_figures/SupplementaryFigureS2_germline.tiff` | Supplementary Figure e - Figure file (TIFF) | 178352 bytes |
| 14 | `02_figures/SupplementaryFigureS2_germline.pdf` | Supplementary Figure e - Figure file (PDF) | 44301 bytes |
| 15 | `03_tables/Table1_baseline.docx` | Table - Table1 | 38750 bytes |
| 16 | `03_tables/Table2_drivers.docx` | Table - Table2 | 38796 bytes |
| 17 | `03_tables/Table3_survival.docx` | Table - Table3 | 38495 bytes |
| 18 | `03_tables/Supplementary_Tables.docx` | Supplementary Material - supplementary tables | 629436 bytes |
| 19 | `04_supplement/Supplemental_Information.pdf` | Supplementary Material - single supplement file | 1591181 bytes |
| 20 | `05_response/Response_to_Reviewers.docx` | Response to Reviewers | 60448 bytes |
| 21 | `06_compliance/Key_Resources_Table.docx` | Key Resources Table | 38961 bytes |
| 22 | `06_compliance/Graphical_Abstract/Graphical_Abstract.tiff` | Graphical Abstract | 463738 bytes |
| 23 | `07_cover/Cover_Letter.docx` | Cover Letter | 40750 bytes |

