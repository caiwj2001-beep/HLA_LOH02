# PINNED_PACK_CORRECTIONS — 对锁定包的修正与已知小偏差复核记录

**对象**：`V3/00_pinned/PINNED_PACK.md`（V3 全部交付物的唯一事实源）
**触发**：本轮"同步与收尾"（正文同步 / 拆句精简 / 回复信同步 / 补充材料重生）
**原则**：本文件只记录**修正与复核结论**；除第 (i) 条（已获授权的 0.947→0.946 舍入修正）外，
**未改动任何已核实数字**；`02_figures/`、`03_tables/`、`06_compliance/` 内的数字**零改动**。

---

## (i) 舍入修正：生存 HR"排 6p" **0.947 → 0.946**

| 项目 | 内容 |
|---|---|
| 原值（错） | `0.947` |
| 新值（对） | `0.946` |
| 源值（真值） | `0.94646184501041` |
| 源文件 · 行号 ①（交付表） | `V3/03_tables/build/table3_survival.tsv` **第 5 行**（`model = "Adjusted + aneuploidy excluding 6p"`，列 `HR`） |
| 源文件 · 行号 ②（上游重算） | `V2/r3p3_task1_rows.tsv` **第 14 行**（`Section=T3_OS`、`Item=LOH_HR_C_e6p`、`Model=C_e6p`、`Estimate=0.946461845010421`） |
| 源文件 · 行号 ③（数字字典） | `V3/00_pinned/PINNED_PACK.md` **第 75 行**（§2.5 生存行，原写 `排 6p **0.947**`） |
| 修正位置 1 | `V3/01_manuscript/06_Results.md` → `## Survival associations of HLA LOH are explained by the aneuploidy background` 第 1 段 |
| 修正位置 2 | `V3/01_manuscript/10_FigureLegends.md` → Figure 5B 图注 |
| 修正位置 3 | `V3/05_response/Response_to_Reviewers.md` —— **共 3 处**：R3-B5、开篇"四、撤回清单"第 2 项、R2-A1 的 7 项子点清单（0.938/0.947/0.952 三联值） |
| 修正位置 4 | `V3/00_pinned/PINNED_PACK.md` 第 75 行（本轮同步，原位保留说明） |
| 说明 | 0.9464618 的三位小数取整为 **0.946**；原值 `0.947` 在**任何**小数位都不是该源值的取整结果，属笔误。差异 0.0005，不影响任何结论。 |

**同段另两个数值的复核（按源值重新计算，结论：无误）**

| 正文/图注值 | 源值 | 源文件 · 行号 | 结论 |
|---|---|---|---|
| 0.938 | `0.938162478670826` | `table3_survival.tsv` 第 4 行；`r3p3_task1_rows.tsv`（`C`） | ✔ 三位小数正确 |
| 0.952 | `0.951876943945006` | `table3_survival.tsv` 第 7 行；`r3p3_task1_rows.tsv`（`C_e6p6q`） | ✔ 三位小数正确 |
| 0.946 | `0.94646184501041` | `table3_survival.tsv` 第 5 行 | ✘→✔ 本轮修正 |

> 另：`table3_survival.tsv` 第 6 行有 `0.943 (0.900–0.988)`（排 6q，`is_new=TRUE`），正文与图注**未**引用该值，
> 本轮不改动。

---

## (ii) Figure S2 正式纳入 —— 图结构由"6 图"记为"**5 主图 + S1 + S2**"

**PINNED 原文**：§3 标题为"图结构（6 图 → 5 图 + 补充图）"，表内只列 **Fig 1–5 + Supp Fig S1**（共 6 条目）。

**实际情况**：`02_figures/` 内已有 **7 个图件**（Fig1–5 + SupplementaryFigureS1_germline + **SupplementaryFigureS2_apobec**），
其中 FigS2 由本轮决策 **保留并纳入正式引用**（它是 R3 minor point 1 的正面回答）。

**因此 PINNED §3 应读作**：

| 图 | 内容 | 状态 |
|---|---|---|
| Fig 1–5 | 主图（5 张） | 同 §3 原表 |
| **Supp Fig S1** | 胚系合子性与可评估性（原 Fig 6 降级） | 同 §3 原表 |
| **Supp Fig S2** | **高 APOBEC 尾部：HLA intact vs HLA LOH（新增纳入）** | 由原 Fig 4B 面板重建；回答 R3-minor-1 |

**纳入的四项落地动作**（详细记录见 `01_manuscript/11b_FigS2_addition_note.md`）：

1. `01_manuscript/10_FigureLegends.md` 新增 Figure S2 完整图注（数字全部取自图件流水线产物：
   `figs2_tail_comparison.tsv` / `figs2_effect_sizes.tsv` / `figs2_apobec_summary.tsv`，与 `QA_figure_check.md` §5 一致）。
2. `01_manuscript/06_Results.md` 突变签名段新增 **1 句**正文引用 Figure S2，并显式给出分母
   （HLA-intact 21,988 vs HLA-LOH 7,496），回答 R3-minor-1："intact 富集"是**分母效应**而非组间分离。
3. `05_response/Response_to_Reviewers.md` 的 **R3-C1** 两段改写为指向 Supplementary Figure S2。
4. `04_supplement/Supplemental_Information.pdf` 重生：FigS2 嵌入第 3 页（图注续第 4 页），
   目录 **15/15** 条目、页码迭代收敛（drift = NONE），S1–S13 编号连续、无孤儿。页数 18 → 20。

**图件本体零改动**：`02_figures/` 下所有文件（TIFF/PDF/中间表/脚本）**未做任何修改**。
**连带影响**：`V3/QC/quality_gates_log.md` §G2 原写"共 14 个条目"应读作 **15 个条目**（Fig S1、Fig S2 + Table S1–S13）。

---

## (iii) 其余 3 处已知小偏差的复核结论

### 3.1 S-arm1 内 17p 的 β 与 PINNED §2.3 所引 β 口径不同 —— **复核结论：排序一致，绝对值不可跨口径比较；正文仍按 PINNED 书写，属正确**

| 项目 | 值 |
|---|---|
| `03_tables/build/s_arm1_rank.tsv` 第 2 行（17p） | `beta_loss = 0.123586521172144`，`P = 8.58388849891734e-125`，`rank_tmb = 1`，`n = 27799` |
| `s_arm1_rank.tsv` 第 3 行（6p，`is_6p=TRUE`） | `beta_loss = 0.0786589162496653`，`P = 5.92477440229265e-39`，`rank_tmb = 26`，`n = 25784` |
| PINNED §2.3 所引 | "第 1 位 17p（β=0.079, P=1.67e-89）；6p = 26/41" |
| 复核结论 | **排名完全一致**（17p 第 1、6p 第 26，共 41 臂，`rows=41`）；**β 绝对值不同**是因为模型规格不同（本表 `log10(TMB+0.1) ~ arm + cancer type`，n=27,799；PINNED 引的是 V6 存档口径 n=26,385 含额外协变量）。正文与 Figure 3C 图注均只引 PINNED 的 `β=0.079, P=1.67×10⁻⁸⁹`（17p）与"26/41"（6p），**与锁定包一致，无需改动**。 |
| 附加观察（供编辑知情） | `s_arm1_rank.tsv` 中 **6p 自身**的 β = 0.0787，与本表 17p 的 0.1236 不同；PINNED 所引 0.079 恰与另一口径下 17p 的 β 数值接近，属**不同模型规格的数值巧合**，不构成矛盾。表中数值只用于核排名（该表已内嵌 `PINNED_ref` 说明列）。 |

### 3.2 S-reliability1 四个模型系数与 PINNED/V2 参考值的差异 —— **复核结论：结论一致，但原"≤0.003"的表述偏松，实际 max|diff| = 0.0061**

| 系数 | 本轮重算（`s_reliability1_models.tsv`） | PINNED/V2 (r3p4) 参考 | \|diff\| |
|---|---|---|---|
| Purity, per −10% | 1.5560700 | 1.5585 | **0.0024** |
| Coverage, per +100× | 0.7670386 | 0.7686 | **0.0016** |
| IMPACT505 vs IMPACT410 panel | 0.2979059 | 0.3040 | **0.0061** |
| Whole-genome doubling | 0.0909647 | 0.0913 | **0.0003** |

- 同队列（n=5,805），差异来自独立重算的数值收敛/协变量处理顺序，**四舍五入到两位小数后四个值全部相同**
  （1.56 / 0.77 / 0.30 / 0.09），与正文 §"调用可靠性"段及 Figure 1C 引用值一致。
- **修正表述**：`QC/quality_gates_log.md` §已知偏差/待办 4 原文写"一致到 ≤0.003"，应读作
  **"一致到 ≤0.0061（最大差异出现在 panel 项），两位小数下完全相同"**。这是**表述精度问题**，
  不涉及任何交付数字的改动。
- 表中 `PINNED_ref` 与 `source` 两列并列展示了参考值与重算值，可逐项复核。

### 3.3 队列 **对齐（N）差异** —— **复核结论：全部为缺失值/可得性驱动，非口径改变；正文未引用这些 N，故不产生矛盾**

各交付物内部的样本量（均取自各自的磁盘产物）：

| 用途 | N | 来源文件 | 与主队列 29,799 的差异及原因 |
|---|---|---|---|
| 主分析队列（一患者一瘤、HLA-LOH 可评估） | **29,799** | PINNED §2.1；`s_aneuploidy1_models.tsv` 之外的队列构建 | — |
| 非整倍体校正的 TMB–LOH 模型（S8/Fig 2C） | **29,407**（LOH 7,449） | `s_aneuploidy1_models.tsv`（全部 5 个 spec 一致） | −392 例：非整倍体评分缺失 |
| TMB 非缺失子集（Fig 2A，按癌种 TMB 分布） | **29,777** | `QA_figure_check.md` §6.2 | −22 例：`TMB_SCORE` 缺失 |
| 按癌种 TMB 表（Table S2） | 28,878（29 癌种求和） | `s2_tmb_by_cancer.tsv` | 仅 N ≥ 100 的 29 个癌种 |
| 泛癌图集（Table S1） | 28,900（29 癌种求和） | `s1_atlas.tsv` | 同上 |
| 突变签名可用 | **29,484**（intact 21,988 / LOH 7,496） | `figs2_tail_comparison.tsv`；`QA_figure_check.md` §6.5 | 签名数据缺失 |
| 新抗原负荷分析 | 25,954（LOH 6,804） | `s_neo1_models.tsv` | 新抗原/panel 可得性 |
| 生存分析 | **27,368**（死亡 10,101） | `table3_survival.tsv` | 生存数据可得性 |
| 等位配对设计 | 6,817 例 / 14,157 对 | `s_neo2_*` | 需杂合位点可判读 |
| 6p 可判读子集 | 5,805 | PINNED §2.1 | 需 6p 臂状态可判读 |

- **结论**：差异全部由缺失值掩膜造成，**不是**重新定义队列。QC §G1 已记录队列重建与既有产物交叉核对：
  非整倍体评分对 `V2/r3p3_aneuploidy_scores.tsv` 全 53,929 例 `max|diff| = 5.6e-16`、NA 掩膜零差异；
  生存队列复现 V2 的 n=27,368 / 10,101。**正文（05/06/07）未引用 29,407 / 29,777 这类中间 N**，
  仅在补充表与图内出现，且各表已在表注写明自身 N，故不存在前后矛盾。
- **无需改动**；如需在 STAR Methods 增加一句 N 对齐说明，属作者决策，本轮不擅自加入。

---

## 本轮对 PINNED_PACK.md 的唯一编辑（**后经终检修正 —— 见 (iv)**）

- **第 75 行（§2.5 生存行）**：`排 6p **0.947**` → `排 6p **0.946**`，并在括号内保留原值说明
  （`原记 0.947，按源值 0.9464618 修正`），使锁定包与三项交付物（正文 / 图注 / 回复信）一致。
- 其余内容**逐字未改**。

## 自检

| 检查 | 结果 |
|---|---|
| 三项交付物与本文件数值一致性 | 0.946（正文 / Fig 5B 图注 / R3-B5 / PINNED §2.5）四处一致 |
| 受保护目录（`02_figures/`、`03_tables/`、`06_compliance/`）数字改动 | **0 处** |
| 图件本体（TIFF/PDF/脚本/中间表）改动 | **0 处** |
| 补充材料编号连续性 | Fig S1 → Fig S2 → Table S1 → … → Table S13，15 条目，无跳号、无孤儿 |
| `verify_sentence_edit.py` 数值守恒 | 退出码 0；删除的数值 token = 空集（授权修正除外） |

---

## (iv) 终检定案：BLOCKER-1 新抗原中位数方向 + BLOCKER-2 burden 中位 OS「不可复算」

**定案依据**：`V3/QC/A1_A2_fix/`（脚本 + 原始输出，全部实跑，非引用任何既有报告）
`A1_recompute_median_OS.R` / `A1_console.log` / `A1_caliber_grid.tsv` / `A1_target_match.tsv`；
`A1b_exact_caliber.R` / `A1b_console.log` / `A1b_exact_caliber.tsv` / `A1b_variants.tsv`；
`A1c_reproduce_oneliner.R` / `A1c_oneliner.txt`（单条标准调用复现）。

### (iv.1) BLOCKER-1 —— 新抗原中位数方向：**确为错值（方向写反），已修正 3 处**

| # | 位置（文件 · 行号） | 原值（错） | 新值（对） | 源文件 · 行号 |
|---|---|---|---|---|
| 1 | `01_manuscript/06_Results.md` · L31（新抗原节 ¶3） | "Median predicted neoantigen counts were **6 in HLA-LOH and 7 in HLA-intact** tumours." | "…were **7 in HLA-LOH and 6 in HLA-intact** tumours." | `neoantigen/output/stats/netmhcpan_full/A2_outcome_models.tsv`（`median_neo_by_LOH` → `neo_median_LOH0=6.0`、`neo_median_LOH1=7.0`）；`02_figures/intermediate/fig4c_neo_summary.tsv`（LOH− 6 / LOH+ 7）；重算 `A1c_oneliner.txt`（LOH+ 7 / intact 6） |
| 2 | `01_manuscript/10_FigureLegends.md` · L33（Figure 4C 图注） | "…HLA-LOH **(6)** and HLA-intact **(7)** tumours." | "…HLA-LOH **(7)** and HLA-intact **(6)** tumours." | 同上；Fig4C 图件绘制源码 `02_figures/scripts/40_fig4.R` L59–61 `grp=c("HLA LOH−","HLA LOH+")`、`med=c(g(4),g(5))`＝(6,7) → **图本体正确** |
| 3 | `05_response/Response_to_Reviewers.md` · L263（R3-B2(iii)「Burden-level」段） | "Median predicted counts were **6 in HLA-LOH and 7 in HLA-intact** tumours." | "…were **7 in HLA-LOH and 6 in HLA-intact** tumours." | 同上 |

- **错因（明写）**：源表与图件统一用 "LOH− = 6 / LOH+ = 7" 标记，写作时对位到 "HLA-LOH / HLA-intact" 时错序，形成**方向相反**的技术性笔误；**不是**数据、图件或统计错误。
- **内部一致性佐证**：正文同段主张弱**正**相关（OR 1.064 > 1），正相关下 LOH 组中位必须更高（= 7），与旧写法自相矛盾。
- **影响范围**：仅上述 3 处叙述文字；**源数据、Fig4C 图件、补充表 S11、`QA_figure_check.md` 全部正确，零改动**（见 (iv.3)）。图件与表格**不需要改**。

### (iv.2) BLOCKER-2 —— burden 中位 OS：**旧值不是错值；属「另一套合法口径而报告未交代」。数字不改，把口径写进正文**

**A1 结论：49.1 / 39.8 / 32.6 / 37.6 可完整复现，且复现它的口径是唯一自然的那个**（单条标准调用，无任何额外过滤）：

```r
survfit(Surv(OS_MONTHS, OS_event) ~ HLA_LOH_burden,
        data = master_cohort[analysis_primary == "TRUE"])   # n = 29,799；survfit 内部自动剔除 2,196 例 OS 缺失
#  ->  49.118 / 39.814 / 32.581 / 37.611     max |diff| = 0.019 月
```

| burden | KM 中位 OS（月） | 95% CI | n | 事件（死亡） |
|---|---|---|---|---|
| 0 | **49.1** | 47.2–50.9 | 20,590 | 7,448 |
| 1 | **39.8** | 36.0–46.4 | 2,327 | 940 |
| 2 | **32.6** | 30.2–37.5 | 1,788 | 757 |
| 3 | **37.6** | 33.6–41.4 | 2,898 | 1,161 |

- 形状 **0 > 1 > 3 > 2（非单调）**，与 V2 规划文档独立记录的「图 5B 实际次序 0>1>3>2」一致 → 正文 "non-monotonic" 表述**成立，予以保留**。
- **`FINAL_QC_REPORT.md` §2.3 G1-F2 的 18.4 / 17.6 / 16.1 / 15.7 系口径错误，不予采用**：那是 `median(OS_MONTHS)`——即**观测时间列的中位数**（忽略删失、也不是生存中位），且限定在协变量完整子集（n=27,368）。本队列删失率 ≈ 63%（27,368 中仅 10,101 死亡），故"时间列中位数"≈18 月而 KM 中位≈49 月。**该 4 值不是"正确可复现值"，不得替换旧值。**
- 口径对照全表（`A1_target_match.tsv` / `A1b_variants.tsv`）：KM 主队列 = **0.019**（**复现**）；KM 主队列 os>0 = 49.8/40.2/33.0/38.2（+0.708）；KM 协变量完整子集 = 49.7/40.2/33.0/38.2；全 master 行 KM = 45.8/40.2/33.0/38.2；**任何 `median(OS_MONTHS)` 口径 = 15–20 月（不复现）**。

**A2 修正动作 —— 数字不变，只补口径 + 收紧撤回口径（同段句级，未增删段落）**：

| 位置（文件 · 行号） | 原句 | 新句 |
|---|---|---|
| `06_Results.md` · L47（生存节 ¶3） | "…was 49.1, 39.8, 32.6 and 37.6 months — non-monotonic…" | "…was 49.1, 39.8, 32.6 and 37.6 months **by the Kaplan–Meier estimate in the primary cohort** — non-monotonic…" |
| 同上（该段末句） | "We therefore withdraw the earlier claim of a **dose-dependent relationship between the number of lost loci and survival**." | "We therefore withdraw the earlier claim that HLA-LOH burden carries an **independent, graded (dose-dependent) prognostic effect on survival**." |
| `05_response/Response_to_Reviewers.md` · L21（「四、撤回清单」第 3 项） | "…37.6 months — non-monotonic…" | "…37.6 months **by the Kaplan–Meier estimate in the primary cohort** — non-monotonic…" |
| `05_response/Response_to_Reviewers.md` · L305（R3-B6 作答） | "…37.6 months — non-monotonic…The sentence claiming dose dependence has been deleted and replaced by a statement that the effect was not dose-dependent, with the non-monotonic pattern reported as it stands." | "…37.6 months **by the Kaplan–Meier estimate in the primary cohort** — non-monotonic… The sentence claiming dose dependence has been deleted; **what we withdraw is the claim of an independent, graded (dose-dependent) prognostic effect**, and the non-monotonic pattern is reported as it stands." |

- **保留的三个事实**（均由 `V2/r3p2_part34_rows.tsv`（`T4_burden` 段）支持、本轮独立复算吻合）：校正非整倍体后关联消失 **0.993 (P=0.87)**；仅 burden=2 达显著 **1.141 (95% CI 1.056–1.233；P=8.1×10⁻⁴)**；burden=3 **1.028 (P=0.396)**。
- **`07_Discussion.md`：全文检索（`grep -in "dose|graded|loci|burden of 0|monotonic|49.1"`）无对应句 → 无需修改**（撤回口径只落在 Results 与回复信）。
- `07_cover/Cover_Letter.md`：仅写 "burden curve is non-monotonic … sentence claiming dose dependence has been deleted"，与数据一致 → **未改**（不在本任务授权范围，记录备查）。
- **锚点**：Results 生存节 ¶3 首 8 词 "The clinical effect did not scale with the" **未变**。

### (iv.3) 未改而经核查的交付物（只标注、不改数）

| 交付物 | 检查项 | 结论 |
|---|---|---|
| `03_tables/Table3_survival.docx` | 是否含中位 OS 四值 | **不含**（仅 6 个 HR 模型行）；对应 `03_tables/build/table3_survival.tsv` 亦无中位 OS → **无错值，无需改** |
| `03_tables/Supplementary_Tables.docx` | 新抗原中位数方向 | 表 S11 写 "Median neoantigens per sample, **HLA-LOH− 6 / HLA-LOH+ 7**" → **正确**（用 −/+ 标记，未发生方向混淆） |
| `04_supplement/Supplemental_Information.pdf` | 同上 | 内嵌同一表 S11 文字，**正确**；PDF 内**无** "6 in HLA-LOH"、也无中位 OS 句 → **无需重生** |
| `02_figures/QA_figure_check.md` | Fig4C 中位新抗原 | "Fig4C 中位新抗原 LOH− 6 **TRUE** / LOH+ 7 **TRUE**" → **正确**，与源数据一致 → **不改** |
| `02_figures/`（TIFF/PDF/脚本/中间表） | — | **零改动** |
| `03_tables/`（Table1/2、S 表） | — | **零改动** |

`03_tables` 内出现的 39.8 / 37.6 属"卵巢癌 CI 上界 / 头颈癌频率(%)"等**无关数字巧合**，非旧中位 OS 残值。

### (iv.4) 复验原始输出（改动后重跑，原始文件见 `QC/A1_A2_fix/`）

- `QC/make_revision_docx.py` → `manuscript paragraphs written: 174`；MARKED 高亮 **218 run**；CLEAN **0**；EXIT=**0**（`rebuild_manuscript_docx.log`）
- `05_response/build_response_docx.py` → `paragraphs=194 tables=1`；EXIT=**0**（`rebuild_response_docx.log`）
- `05_response/verify_anchors.py` → **anchors: 28   matched in md AND both DOCX: 28   mismatched: 0**；EXIT=**0**（`verify_anchors_out.txt`）
- `QC/scan_markdown_residue.py` → MARKED/CLEAN **TOTAL residue = 0**、行号域存在；**GATE G5 PASS**；EXIT=**0**（`scan_markdown_residue_out.txt`）
- `05_response/verify_response.py` → `UNFLAGGED CLAIM OCCURRENCES: 0`；`[LINE-REF-TBD]`=0；假行号=0；ANCHOR_MAP 28 行；`'**Anchor:**' 28`；EXIT=**0**（`verify_response_out.txt`）
- 附加：`QC/final_qc/final_qc_G6_claims.py` 重扫 EXIT=**0**；本轮新增句被判为 **compliant (negated)**（NEG 命中 "withdraw"）（`G6_claims_rescan.log`）
- 注：`01_manuscript/_pre_edit/` 为改动前的快照备份（非交付物、不被 DOCX 构建读取），其中仍含旧方向文字，属预期。

### (iv.5) 本轮改动/重建文件 sha256

见 `QC/A1_A2_fix/sha256_edited_artifacts.txt`（含 `PINNED_PACK.md`、`PINNED_PACK_CORRECTIONS.md` 追加行）。

---

## (v) 图号重编 —— 所有图号改按**正文首现顺序**（2026-10-15）

**授权**：本轮"图号重编"（v2）。**除图号 token 外零改动**：14 个图件文件重命名后逐字节相同
（sha256 对照见 `QC/RENUMBER_TO_FIGURE_ORDER_REPORT.md` §3）；全部面板字母、数字、百分比、P 值、
n、图层与结论均未改动。

> ⚠ 本节**取代 (ii) 中 Supp Fig S1 / S2 的对应关系**：(ii) 写的 "Supp Fig S1 = 胚系、Supp Fig S2 = APOBEC"
> 是重编前的旧制；重编后 **S1 = APOBEC、S2 = 胚系**。

### (v.1) 完整映射表

| # | 内容 | 旧号 | **新号** | 旧文件 | **新文件** |
|---|---|---|---|---|---|
| 1 | 泛癌图谱 + 调用可靠性 | Figure 1 | **Figure 1** | `Figure1_pancancer_and_reliability.*` | 不变 |
| 2 | 机制 / 非整倍体 / 臂全景 | Figure 3 | **Figure 2** | `Figure3_mechanism_armlandscape.*` | `Figure2_mechanism_armlandscape.*` |
| 3 | TMB × HLA LOH（非整倍体校正） | Figure 2 | **Figure 3** | `Figure2_TMB_aneuploidy.*` | `Figure3_TMB_aneuploidy.*` |
| 4 | 新抗原 | Figure 4 | **Figure 4** | `Figure4_neoantigen.*` | 不变 |
| 5 | 生存 | Figure 5 | **Figure 5** | `Figure5_survival.*` | 不变 |
| 6 | 高 APOBEC 尾部 | Figure S2 | **Figure S1** | `SupplementaryFigureS2_apobec.*` | `SupplementaryFigureS1_apobec.*` |
| 7 | 胚系合子性 / 可评估性 | Figure S1 | **Figure S2** | `SupplementaryFigureS1_germline.*` | `SupplementaryFigureS2_germline.*` |

主图集合 1–5 不变；补充图集合 S1、S2 不变（即重编只是一次**对调**：正文首现更早的 TMB 图升为 Figure 2、
APOBEC 图升为 Figure S1）。条目数仍为 **5 主图 + 2 补充图 + Table S1–S13 = 15 个补充条目**（与 (ii) 一致）。

### (v.2) 生效文件清单

**图件（重命名，内容逐字节相同）**：`02_figures/` 内 `Figure2/Figure3` 与 `SupplementaryFigureS1/S2`
共 4 组 × (tiff + pdf) = 8 个文件的文件名互换；其余 6 个图件（Figure1/4/5、Graphical Abstract 无关）文件名与字节均不变。

**图流水线（文件名数字前缀与图号对齐，仅图代号字符串互换）**：
`02_figures/scripts/{20_fig2.R, 30_fig3.R, 60_figS1.R, 70_figS2.R}` 与 `90_qa_overlap.R`；
`10_fig1.R`、`40_fig4.R`、`50_fig5.R`、`fig_common.R`、`99_run_all.R`、`00_recompute_inputs.R`、
`02_recompute_apobec.R` 未变。

**正文/投稿文件**：`01_manuscript/06_Results.md`（7 处图号）、`01_manuscript/10_FigureLegends.md`
（4 个图题重编 + 图注块顺序改为 Figure 2 在 Figure 3 前、S1 在 S2 前）、
`05_response/Response_to_Reviewers.md`（12 处）、`07_cover/Cover_Letter.md`（1 个数字 + 2 个补充图文件名）。

**重建产物**：`01_manuscript/HLA_LOH02_revision_{MARKED,CLEAN}.docx`、
`05_response/Response_to_Reviewers.docx`、`03_tables/Supplementary_Tables.docx`
（目录行顺序 + 图页顺序；29 张数据表文字逐字未变）、`04_supplement/Supplemental_Information.pdf`。

**工具**：`.tools/build_tables_docx.py`（图页块互换并重编；`figdir` 提到条件分支之外，并加
`os.path.isdir` 与"错文件"断言）、`QC/final_qc/final_qc_G2_numbering.py` 与
`QC/g2_independent_crosscheck.py`（首现序门禁逻辑修正）、`QC/final_qc/final_qc_G3_figures.py`（图件路径更新）。

### (v.3) 对图表引用与补充 PDF 页序的影响

- **正文引用**：`Figure 2A/2B/2C` 现在指 TMB 图（原 Figure 2）；`Figure 3A/3B/3C` 现在指机制/臂全景图（原 Figure 3）；
  `Figure S1` 现指高-APOBEC 尾部图，`Figure S2` 现指胚系图。Table 1–3 与 Table S1–S13 **编号完全未动**。
- **补充 PDF 页序**：`04_supplement/Supplemental_Information.pdf` 目录表首两行为
  `Supplementary Figure S1 = High-APOBEC tail`、`Supplementary Figure S2 = Germline HLA zygosity`；
  正文页序 Figure S1 在 Figure S2 之前。重编后实测（`QC/seed_determinism/verify_supplement.py`）：
  **20 页、15/15 锚点无缺失、页码收敛**，Figure S1 → 第 2 页、Figure S2 → 第 4 页、
  Table S1→5、S2→7、S3→9、S4→10、S5→11、S6→12、S7→13、S8→14、S9→15、S10→16、S11→17、S12→18、S13→19。
- **首现序门禁**：修复了旧门禁"先按标签排序再查逆序"造成的**空判**（该 bug 使重编前的违规状态无法被报告）；
  修正后正对照成立（改前状态被判 FAIL，当前状态 PASS）。原始输出见
  `QC/RENUMBER_TO_FIGURE_ORDER_REPORT.md` §5.1。

### (v.4) 同一轮内的一项图流水线改动（非编号，单独记录）

`02_figures/scripts/30_fig3.R`（TMB 图）与 `60_figS1.R`（APOBEC 图）的 `geom_jitter()` 原先未固定随机种子，
同一脚本两次重跑的散点落点不同，图件无法字节级复现。本轮在两个脚本顶部各加**互相独立**的常量
（`JITTER_SEED_FIG3 = 20261015L`、`JITTER_SEED_FIGS1 = 20261016L`）并在 `geom_jitter()` 前 `set.seed()`。
**该种子只决定散点的亚像素抖动偏移**：逐字节/逐对象复核显示，重跑后 TIFF 两次连跑**完全逐字节相同**，
PDF 仅 `/CreationDate` 时间戳及其两项编码层后果不同（光栅化后 0 像素差异）；与旧件的差异仅限于
A 面板散点的平移，图内文字层、图内全部数字、面板 bbox 与其余图层零变化。全部证据与原始输出见
`QC/seed_determinism/`（`DETERMINISM_PROOF.json`、`COMPARE_REPORT.json`、`COMPARE_VECTOR.json`、
`docx_media_diff.py` 输出）。同时把此前滞后的 `06_compliance/deposit/code.zip → code/build_tables_docx.py`
外科式替换为现行版本（只改该 1 个成员，`derived_data.zip` 未重建）；
见 `QC/_unify_zip_rebuild.json → update_2026-10-15_jitter_seed`。

---

## (vi) 提交前终检三项阻塞的整改（B1 臂口径 / B2 DOI 占位符 / B3 数字字典）—— 2026-10-15

**授权**：`QC/SUBMIT_READINESS_REPORT.md` §0「不可直接投稿：3 项阻塞」。
**范围硬约束**：本轮**只改字词与占位符字串**——数字、统计量、结论、图表内容**零改动**；段落结构不变
（`05_response/verify_anchors.py` 28 个锚点未动，见 (vi.5)）。

### (vi.1) 代码事实（全部逐条回读源文件，非引用任何既有报告）

`06_compliance/deposit/code/01_build_tables_V3.R` L56–68：

```
mkfrac(rep(TRUE, length(arms)), "all")                       # all      = 39 臂
mkfrac(arms != "6p",            "ex6p")                      # ex6p     = 38 臂（仅排 6p）
mkfrac(arms != "6q",            "ex6q")                      # ex6q     = 38 臂（仅排 6q）
mkfrac(!arms %in% c("6p","6q"), "ex6")                       # ex6      = 37 臂（排 6p 与 6q）
```

原始输出 `QC/build_tables.log` L8–11：`[mkfrac all] arms=39` / `[mkfrac ex6p] arms=38` /
`[mkfrac ex6q] arms=38` / `[mkfrac ex6] arms=37`。
数值与规格的对应（`V2/r3p3_step2.log` L62–64；`QC/build_tables.log` L106/108/152–155）：

| 规格 | ρ（Spearman） | 每 SD OR | 其他 |
|---|---|---|---|
| `frac_all`（39 臂，含 6p） | 0.3312 | 2.155 | 校正 3.106 |
| `frac_ex6p`（**仅排 6p**） | 0.3193 | 2.093 | Table 3 排 6p HR **0.946**；S-aneuploidy1 **1.250** |
| `frac_ex6`（**排 6p 与 6q**） | 0.3117 | **2.055** | Table 3 排 6p&6q HR **0.952**；S-aneuploidy1 **1.256** |

→ 正文原写 "the six arms around the class I locus" 与代码直接冲突（实为**两条臂**，6p 与 6q）；
另有 5 处把 \"仅排 6p\"（ex6p）的模型写成复数 "the class I arms" / "the arms around the class I locus"。

### (vi.2) 逐处修改（文件 / 行 / 旧 → 新；**每处仅改字词**）

| # | 文件 | 行 | 旧 | 新 |
|---|---|---|---|---|
| B1-A | `01_manuscript/06_Results.md` | 15 | after excluding the **six arms around the class I locus** left ρ=0.312 | after excluding the **two chromosome-6 arms (6p and 6q)** left ρ=0.312 |
| B1′-B | `01_manuscript/06_Results.md` | 23 | 1.250 excluding the **arms around the class I locus**, and 1.256 additionally excluding 6q | 1.250 excluding the **chromosome-6p arm**, and 1.256 additionally excluding 6q |
| B1′-C | `01_manuscript/06_Results.md` | 43 | with the **class I arms** excluded (0.946) | with the **chromosome-6p arm** excluded (0.946) |
| B1-D | `01_manuscript/07_Discussion.md` | 9 | Excluding the **six chromosome arms around the class I locus** barely changes the association | Excluding the **two chromosome-6 arms (6p and 6q)** barely changes the association |
| B1′-E | `05_response/Response_to_Reviewers.md` | 20 | (0.946 with the **class I arms** excluded; 0.952 with 6p and 6q excluded) | (0.946 with the **chromosome-6p arm** excluded; 0.952 with 6p and 6q excluded) |
| B1-F | `05_response/Response_to_Reviewers.md` | 144 | …0.312 when the **six arms flanking the class I locus** are removed from the score; … and 2.055 in the **6p-excluded** specification | …0.312 when the **two chromosome-6 arms (6p and 6q)** are removed from the score; … and 2.055 in the same **two-arm-excluded** specification |
| B1′-G | `05_response/Response_to_Reviewers.md` | 245 | 1.250 with the **arms around the class I locus** excluded (P=7.4×10⁻⁰⁹) | 1.250 with the **chromosome-6p arm** excluded (P=7.4×10⁻⁰⁹) |
| B1′-H | `05_response/Response_to_Reviewers.md` | 297 | with the **class I arms** excluded from the score (0.946) | with the **chromosome-6p arm** excluded from the score (0.946) |

**B1″（同一句内新发现的同类错，同轮一并修正）**：B1-F 所在括号原本把 ρ=0.312/OR 2.055 描述为
"the 6p-excluded specification"，但 `frac_ex6p` 的对应值是 0.3193/2.093，**2.055 属 `frac_ex6`（排 6p 与 6q）**。
若不改，B1-F 的新措辞会与同句内的旧标签**自相矛盾**，故改写为 "in the same two-arm-excluded specification"
（仅换词，未增删任何数字；如作者认为该标签另有他指，回退该 1 个字串即可）。

**数值零改动证明（机器口径，非目测）**：本轮改动脚本对 11 个替换逐条断言
(a) 旧字串在文件中**恰好出现 1 次**；(b) **统计数字多重集相等**（染色体名计为**名称**、臂标签 6p/6q 单列一类）；
(c) **引文标记多重集相等**（`[n]` 与上标）。原始输出 `QC/_b1_b2_edits.json`。
该口径下 11 处**全部** `statistical-numeral delta = {}`、`citation-marker delta = {}`；
新增 token 仅 `6p`/`6q`/染色体名中的 `6`。
**独立脚本交叉印证**：`01_manuscript/verify_sentence_edit.py`（非本轮编写）对三节逐文件报
`number tokens REMOVED (must be empty) = {}`（**零删除**）；本轮改动归因的新增数值 token 恰为
Results **+5**（`chromosome-6`、`6p`、`6q`、`chromosome-6p`×2）、Discussion **+3**（`chromosome-6`、`6p`、`6q`），
即全部为染色体/臂标识符本身（原始输出 `QC/_b1_b2_verify_sentence_edit_PRE/POST.out`）。

### (vi.3) B2 —— DOI 占位符统一为唯一许可字串 `[DOI-PENDING-ZENODO]`

| 文件 | 行 | 旧 | 新 |
|---|---|---|---|
| `01_manuscript/08_StarMethods.md` | 12 | …a single Zenodo DOI **(DOI to be inserted at submission)**. | …a single Zenodo DOI **[DOI-PENDING-ZENODO]**. |
| `01_manuscript/08_StarMethods.md` | 13 | …the same single Zenodo DOI as the derived data **(DOI to be inserted at submission)**. | …the same single Zenodo DOI as the derived data **[DOI-PENDING-ZENODO]**. |
| `01_manuscript/09_BackMatter.md` | 29 | …and archived under a single Zenodo DOI **(DOI to be inserted at submission)**. | …and archived under a single Zenodo DOI **[DOI-PENDING-ZENODO]**. |

两个 manuscript DOCX 各 1 处（源自 `09_BackMatter.md` ¶3，即 Back matter「Resource availability」；
`08_StarMethods.md` 的 2 处在 `## Resource availability` 块内，按既定构建口径**不进入** DOCX）随 DOCX 重建一并统一。
全包**唯一许可占位符**仍为 `[DOI-PENDING-ZENODO]`；**无 DOI 被编造**。待回填位清单见同目录
`QC/DOI_FILLIN_CHECKLIST.md`。

### (vi.4) B3 —— 两个存交包数字字典同步（外科式重建）

- `deposit/code.zip → code/PINNED_PACK.md`：14607 B / `3f27f3d7…`（旧）→ **15179 B / `96063bb8…`**（冻结版）。
- `deposit/derived_data.zip → derived_data/number_dictionary/PINNED_PACK.md`：同上一并替换为冻结版。
- **新增成员**：`code/PINNED_PACK_CORRECTIONS.md` 与
  `derived_data/number_dictionary/PINNED_PACK_CORRECTIONS.md`（即本文件，含 §(v) 图号重编指引与本节 §(vi)）。
- 其余成员**逐字节不变**：重建采用"原始局部记录整段拷贝"（local header + 压缩流原样搬运），
  只对被替换/新增成员重写记录；非改动成员的 raw local record 与解压后 sha256 双重比对一致。
  新旧 sha256、变更成员清单见 `QC/_b3_zip_rebuild.json`。

### (vi.5) 复验原始输出（改动后实跑，退出码与关键行原文）

- `QC/make_revision_docx.py` → `manuscript paragraphs written: 174`；MARKED 高亮 **218 run**、CLEAN **0**；EXIT=**0**（`QC/_b1_b2_make_revision_docx.out`）
- `05_response/verify_anchors.py` → **`anchors: 28   matched in md AND both DOCX: 28   mismatched: 0`**；EXIT=**0**
- `05_response/build_response_docx.py` → `paragraphs=194 tables=1`；EXIT=**0**
- `05_response/verify_response.py` → `UNFLAGGED CLAIM OCCURRENCES: 0`；`[LINE-REF-TBD]`=0；假行号=0；`ANCHOR_MAP.tsv rows 28`；`'**Anchor:**' 28`；EXIT=**0**
- `QC/scan_markdown_residue.py` → 两版 **TOTAL residue = 0**、行号域存在、subscript 38 / superscript 9；**GATE G5 PASS**；EXIT=**0**
- `QC/g2_independent_crosscheck.py` → 主表 `[1,2,3]`、补充表 `[1..13]`、主图 `[1,2,3,4,5]`、补充图 `[1,2]`；
  `T3 ORPHAN / REF-NO-FILE / FILE-ORPHAN / ORDER differences: 0`；EXIT=**0**

### (vi.6) 本轮改动/重建文件与已知偏差声明（不美化）

**改动文件 sha256（旧 → 新）**：见 `QC/_b1_b2_edits.json` 与 `QC/FINAL_MANIFEST.md`（已按本轮状态重生）。

**三条必须如实说明的偏差**：

1. **构建 DOCX 必须用 `.tools/docxenv` 解释器**（python 3.12.13 + python-docx 1.2.0）。用 Hermes 侧
   python 3.14.7 构建得到的是**同样文本、不同字节**的 DOCX（61,371 B vs 62,624 B）。本轮已用 docxenv
   重建，并以前置状态回放验证：**用 docxenv + 改动前 markdown 重建，得到逐字节等于改动前 62624/62928 B 的结果**，
   即 DOCX 在正确解释器下是字节可复现的；此条对第三方复现是必要的。
2. **`05_response/ANCHOR_INVENTORY.tsv` 在本轮之前已滞后**：其 `10_FigureLegends.md` 共 12 行的
   (节 / 段序 / 首 8 词) 仍是图号重编**前**的旧制；本轮因 B2 需同步该文件，**已一并重生**，现已与现行
   markdown 一致（全文 175 行，`first8` 列与旧件逐行一致，仅 `10_FigureLegends.md` 的图注块顺序与
   图号 token 归位）。
3. **`01_manuscript/SENTENCE_STATS.md` 未重算，且其在本轮之前即已滞后**：该表"after"列为 R2-C1 拆句轮
   的实测值（Results 2077 词），而现行 `06_Results.md` 实测 **2205 词**（差 128 词，来自其后各轮新增，
   主要为 Table S1–S13 索引句）；本轮字词修正使 Discussion 实测词数 **1450 → 1448**（−2）。
   依"统计量零改动"约束**未重生该表**（其数值为脚本实测、重生会使表内数字变动）。如需一致，
   在 `01_manuscript/` 内依次运行 `python sentence_stats.py after` 与 `python make_sentence_stats_md.py`
   即可，但**会改动该交付物内的统计数字**，故留待作者决定。

---

## (vii) 收尾四项瑕疵的整改与终稿重验 —— 2026-10-15（终稿状态 v2）

**授权**：本任务「四个收尾瑕疵」。**范围硬约束**：不改任何科学数字/结论/图表；不增删段落
（`05_response/verify_anchors.py` 复验 28/28 锚点命中 md 与两版 DOCX）；只做**字词**与
**QC 度量/报告**层面的修正。

### (vii.1) 均句长与回复信 R2-C1 对齐（A）

`01_manuscript/SENTENCE_STATS.md` 在 §(vi) 之前即已陈旧（其 "after" Results = 2077 词，而现行
`06_Results.md` 为 2205 词）。本轮按「以脚本对**现行字节**重测为准」重生该表，并把回复信 R2-C1
段内引用的数字逐项改为实测值。实测（`01_manuscript/sentence_stats.py after`）：

| 节 | total_words (`wc -w`) | prose_words | 句数 | 平均句长 | 最长句 | >45 词句数 | >40 词句数 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Introduction | 763 → **669** | 761 → **667** | 21 → **32** | 36.24 → **20.84** | 79 → **38** | 8 → **0** | 10 → **0** |
| Results | 2205 → **2205** | 2117 → **2117** | 64 → **85** | 33.08 → **24.91** | 71 → **98** | 14 → **1** | 21 → **4** |
| Discussion | 1676 → **1448** | 1674 → **1446** | 55 → **65** | 30.44 → **22.25** | 63 → **44** | 8 → **0** | 14 → **2** |
| **合计** | **4644 → 4322** | 4552 → **4230** | 140 → **182** | 32.51 → **23.24** | — | **30 → 1** | — |

回复信 `R2-C1` 的改动（**仅改数字 token，加一处为保真所需的定语**）：Discussion 平均句长
**22.28 → 22.25**；三节合计 **22.67 → 23.24**；句数 **181 → 182**；三节总词数
**4,196 → 4,322**；>45 词句数 **0 → 1**（见下）。重生后的 `SENTENCE_STATS.md` 在**表首**（第 3 行，标题与之相邻）标注
「**数值口径：基于 v2 终稿重测（含本次词级修正）**」。

**两条如实说明的偏差（不美化）**：

1. **>45 词句数实测为 1，不是 0。** 唯一残留句是 Results 首段的补充表索引句（98 词：
   *"Complete model outputs at every step are collected in the supplementary tables and are indexed
   as follows: … (Table S13)."*）。该句是拆句轮之后为回填 Table S1–S13 引用而新增的（+128 词），
   它同时是 Results 回到 2205 词、三节总词数 4,322 词**高于 4,200 目标 122 词**的唯一原因。
   因本轮**禁止改动正文**（保 28 锚点、不增删段落、不动任何数字），故**未拆此句**，而是把回复信该句
   由 `No sentence … exceeds 45 words` 改为如实表述 `One sentence … exceeds 45 words — the 98-word
   sentence that indexes the supplementary tables in the first Results paragraph`，并在
   `SENTENCE_STATS.md` §1 的达标判定中对两项未达标判据**如实标 ✘ 并注明原因**（原生成器对这两项
   恒打 ✔）。**是否拆句留待作者决定**：拆该句是纯字词操作（不改任何数字、结论、图），拆后 >45 词句数
   归 0、三节总词数不变，但需同步重建两版 manuscript DOCX 并重跑门禁。
2. **`verify_sentence_edit.py` 的数值白名单已扩充**（属 QC 度量层修正，非放宽统计量校验）：新增
   token `1…13`（Table S1–S13 的**表号标签**）与 `6`（chromosome-6 / 6p / 6q **染色体标识符**）
   来自 §(vi) 的臂口径修正与补充表引用回填。扩充后该脚本
   `=== RESULT: ALL CONSERVED ===`（EXIT=0，原始输出 `01_manuscript/_verify_out.txt`）；
   对统计量仍**零删除**（`number tokens REMOVED = {}`），C1/C2/C3 判定逻辑未动。

### (vii.2) 存交包与仓库的 `README_CODE.md` 统一（B）

| | 路径 | 字节 | sha256 | 行尾 |
|---|---|---:|---|---|
| 旧（存交包） | `code.zip → code/README_CODE.md` | 1,882 | `6a2d3b0a98919ec616a0290193871035862e96bff621513e18333a3d7f6f9845` | CRLF |
| 旧（仓库） | `revision_2026/code/README_CODE.md` | 9,194 | `63c11a3ec0b44111cf82dcfbd5ba1a7a2d734b6bb6ad57a8c5328fc870f82591` | LF |
| **新（两处同字节）** | 同上两处 | **18,377** | **`ff6f297465426e569db5e3b1fb42cb0d6f9d345c43ccf5470579c83901b89875`** | LF |
| 新（后续两次增补后，最终） | 同上两处 | **18,859** | 见 `QC/_b4_final_digests.txt`（该文件是本清单的成员，其自身 sha256 会随本表 sha 同步而变，故不自引） | LF |

新版是**一份囊括两者**的完整版：运行顺序、依赖、解释器与版本、**docxenv DOCX 构建器与证据**、
固定抖动种子、图号重编指引、**字节保真事实与验证命令**、产物 sha256 索引（14 图件 + 两版
manuscript DOCX + 回复信/封面/KRT/三表/补充 PDF/GA + `derived_data.zip` + 数字字典；`code.zip`
自指，故其摘要记录在 `QC/FINAL_MANIFEST.md`）。

- **生成源同改**：`.tools/assemble_deposit.py` 内的模板字面量已替换为同一份内容，并把该文件的
  `open(…, "w", encoding="utf-8")` 改为 `newline=""`（否则渲染成 CRLF，与仓库件不同字节）。
  已用 `ast` 取出模板字面量并与仓库件逐字节比对：`generator literal == repo bytes : True`。
- **成员一致性（机械核验）**：`code.zip` 9 + `derived_data.zip` 91 = **100 成员，100/100** 与仓库树中
  某个文件**逐字节相同**（新增 `revision_2026/code/tools/check_repo_vs_zip.py`，EXIT=0，原始输出
  `QC/_b4_repo_vs_zip.txt`）。修复前为 99/100，唯一例外即本文件。
- `code.zip`：**62,088 B / `86e6adb8074f4c4ba4600fef269de556cfdad5a0be456fb6b2773c51c35bbe6a`**
  → **（见 `QC/FINAL_MANIFEST.md` 的最终值）**；外科式重建（其余成员原始局部记录逐字节搬运，
  成员表与顺序不变），明细 `QC/_b4_zip_swaps.json`，算法与验收在 `QC/tools/surgical_zip.py`。

### (vii.3) DOCX 解释器依赖的复证（C）

以**现行** `01_manuscript/*.md` 分别用两个解释器重建两版 manuscript（`QC/make_revision_docx.py`；
高亮/行号逻辑未改，`highlighted paragraphs 118/174`、`marked highlight runs 218`、`clean 0` 三值
两解释器完全一致）：

| 构建解释器 | CLEAN | MARKED |
|---|---:|---:|
| **`.tools/docxenv/Scripts/python.exe`，CPython 3.12.13 + python-docx 1.2.0**（正确） | **62,632 B**（== 交付件） | **62,934 B**（== 交付件） |
| 系统 CPython 3.14.7 | 61,381 B | 61,678 B |

**并如实修正 §(vi.6) 第 1 条的一处表述**：该条写「用 docxenv 从改动前 markdown 重跑可得到
**逐字节**等于旧件的结果」。实测**不成立**——`python-docx` 会给每个 zip 成员写入构建时刻的本地
时间戳，因此同一解释器连续两次构建得到的是**成员内容完全相同、文件大小相同、整文件 sha256 不同**
的 DOCX（已实测两次构建 D1 ≠ D2，而两者逐成员 CRC 与解压后 sha256 全等，也与交付件全等）。
正确的可复现口径是：**成员级内容可复现 + 文件大小可复现；整文件 sha256 不可复现**。
方法与逐成员比对脚本见 `revision_2026/code/README_CODE.md` §3（并已同步进根 README 的 v2 节）。

### (vii.4) 一键 DOI 回填工具（D，本轮只交付工具、未填 DOI）

新增 `QC/tools/fill_doi.py`（幂等、支持 `--dry-run`、遇到槽位不是 `[DOI-PENDING-ZENODO]` 时
非 0 退出）。按 `QC/DOI_FILLIN_CHECKLIST.md` 的 **9 个真回填位**逐位替换，随后自动：用 docxenv
重建两版 manuscript DOCX 与 KRT/Cover/回复信 DOCX → 外科式重建两个 zip → 重跑验证电池
（锚点 28/28、markdown 残留 0、G2 首现序、回复信校验）→ 打印逐位 diff 与新 sha256 →
重生 `QC/FINAL_MANIFEST.md`。**本轮只跑 `--dry-run`**（未写入任何交付物），完整输出见
`QC/_fill_doi_dryrun.out`。真实 DOI 待用户在 Zenodo 发布后提供。

### (vii.5) 终稿重验与清单重生（E）

`QC/FINAL_MANIFEST.md` 已按本轮终稿状态重生。四项独立复验的原始输出：
锚点与回复信 `05_response/_rerun_verify_anchors_out.txt`、`05_response/_rerun_verify_response_out.txt`；
markdown 残留与 G2 首现序 `QC/_final_rerun_all.log`；句数守恒 `01_manuscript/_verify_out.txt`；
仓库↔存交包成员一致性 `QC/_b4_repo_vs_zip.txt`。

---

## (viii) 拆句轮：Results 首段补充表索引句拆句 + 回复信/统计同步 + 全门禁重跑 —— 2026-10-15

**授权**：把 `06_Results.md` 首段的补充表索引句（原 **1 句 98 词**）拆为 **3 个短句**，
使三节 **>45 词句数归 0**（≈Reviewer #2 "long, multi-clause sentences" 的直接诉求）。
**范围硬约束**：只改**句子边界与连接词**；数字 / 表号 / 图号 / 引文编号 / 限制与撤回语句
**零增删**；不增删段落（两版 DOCX 仍 **174 段**、`verify_anchors.py` 仍 **28/28**）。

### (viii.1) 拆句前后逐字对照

**拆前（1 句，98 词）**

```text
Complete model outputs at every step are collected in the supplementary tables and are indexed as follows: the pan-cancer HLA-LOH atlas by cancer type (Table S1); the within-cancer-type tumour-mutational-burden association (Table S2); the mutational-signature models (Table S3); overall survival by cancer type (Table S4); the panel-restricted sensitivity analysis (Table S5); the whole-genome-doubling mediation (Table S6); the germline-zygosity evaluability analysis (Table S7); the tumour-mutational-burden association across aneuploidy specifications (Table S8); the arm-level mutational-burden ranking (Table S9); the calling-reliability models (Table S10); the neoantigen-burden models (Table S11); the allele-paired neoantigen test (Table S12); and the structural-variant class burden (Table S13).
```

**拆后（3 句，38 / 37 / 33 词）**

```text
Complete model outputs at every step are collected in the supplementary tables and are indexed as follows: the pan-cancer HLA-LOH atlas by cancer type (Table S1); the within-cancer-type tumour-mutational-burden association (Table S2); and the mutational-signature models (Table S3). The remaining tables index overall survival by cancer type (Table S4); the panel-restricted sensitivity analysis (Table S5); the whole-genome-doubling mediation (Table S6); the germline-zygosity evaluability analysis (Table S7); and the tumour-mutational-burden association across aneuploidy specifications (Table S8). The last group indexes the arm-level mutational-burden ranking (Table S9); the calling-reliability models (Table S10); the neoantigen-burden models (Table S11); the allele-paired neoantigen test (Table S12); and the structural-variant class burden (Table S13).
```

- Table S1→S13 的**首现升序**不变；13 个表号仍**各出现一次**；分隔符与全文一致
  （`;` 分项 + 末项 `and`，句间用 `.` + 大写起句）。新增词仅为连接成分：
  `and`（第 1 句末项）、`The remaining tables index`、`and`（第 2 句末项）、`The last group indexes`，共 **+10 词**。
- **逐处守恒**（`01_manuscript/verify_split_conservation.py`，EXIT=**0**）：该片段数字 token **13→13**、
  表号 **13→13**、图号 **0→0**、引文标记 **0→0**，**删除集全部为空**、新增集亦为空；
  全文件口径（含既有的授权改动）四类**删除集同样为空**、新增数字 token 全部在白名单内。

### (viii.2) 句长实测（同一脚本口径，拆前 → 拆后）

| 节 | 词数 (`wc -w`) | 句数 | 平均句长 | 最长句 | >45 词句数 | >40 词句数 |
|---|---:|---:|---:|---:|---:|---:|
| Introduction | 669 → 669 | 32 → 32 | 20.84 → 20.84 | 38 → 38 | 0 → **0** | 0 → 0 |
| Results | 2205 → **2215** | 85 → **87** | 24.91 → **24.45** | 98 → **44** | 1 → **0** | 4 → **3** |
| Discussion | 1448 → 1448 | 65 → 65 | 22.25 → 22.25 | 44 → 44 | 0 → **0** | 2 → 2 |
| **合计** | **4322 → 4332** | **182 → 184** | **23.24 → 23.04** | — | **1 → 0** | **6 → 5** |

- 三节 **>45 词句数 = 0**（原 1）；**>40 词句数 = 5**（原 6——被拆的 98 词句移出该档，3 个新句
  38/37/33 词**均未**进入该档）。
- 三节总词数 4322 → **4332**（+10 全部为新连接词）；高于自设 4,200 目标 132 词——**期刊无此硬限**，
  回复信与 `SENTENCE_STATS.md` 均已如实标注 ✘。

### (viii.3) 受影响文件与哈希（拆前 → 拆后）

| 文件 | bytes 拆前 → 拆后 | sha256 拆前 → 拆后 | 说明 |
|---|---|---|---|
| `01_manuscript/06_Results.md` | 15,081 → **15,139** | `9cae2ebd43b1ade0da5ae292cbdb675759ecc5df80137edcfe72aa867ceac5a7` → `06d4dc26c4b6afd9ecb5e55be72bc7f50cdcdd45ef34ef24e960ce3b051919d0` | 拆句所在文件（唯一正文改动） |
| `01_manuscript/HLA_LOH02_revision_CLEAN.docx` | 62,632 → **62,652** | `2f71ddaecf4dd235cd603ae71816f7c33e4ef12e27bd38b6a0e878c52ccc5d2a` → `66c2dca47169458ddda4bd42c98dff14fa62ed7142eff85aed120b7a2e0db1b2` | docxenv 重建；仍 174 段、高亮 0 run |
| `01_manuscript/HLA_LOH02_revision_MARKED.docx` | 62,934 → **62,954** | `7b9e2a691e85971f06826842ee53fcd49a48b90836a66442cf05138631012e42` → `a2987113faffe43e4fc45a70b963efa802c365fea8542740b0343c11ba88c1c9` | docxenv 重建；仍 174 段、高亮 118/174 段、218 run |
| `01_manuscript/SENTENCE_STATS.md` | 13,287 → **15,070** | `6e7a430831f86dfa6a09cd567c11d9076e1d62b66f15f8f81420479ee3ddc83d` → `7aa8ad1a53bcaa6de79616df321fc399ce9fce9128317784de0300eeaa42605e` | 重生（含 §1b 拆前/拆后对照表 + 逐字对照） |
| `01_manuscript/make_sentence_stats_md.py` | 10,843 → **12,649** | n/a → `9e4667a7301b78d62e4551528ed7c19e2da8655dbd537e622c13630534c23d8c` | 表生成器：口径说明/达标判定/§1b 同步（非清单件，旧 sha 未记录） |
| `01_manuscript/verify_split_conservation.py` | 0 → **5,587** | n/a → `c04daaadb0202b5fd8a5000a1e19d84d581f57d49f3bf42fc4dd7a4d7fd8531e` | **新增**：拆句逐处守恒 + >45=0 校验（EXIT=0） |
| `01_manuscript/_verify_out.txt` | 2,451 → **2,451** | n/a → `9cb05aa2b851c4300b01c116d724deda9bdf5714c9deabdb5ceb50ea3f646c3a` | verify_sentence_edit.py 现行原始输出（RESULT: ALL CONSERVED / EXIT=0） |
| `05_response/Response_to_Reviewers.md` | 76,436 → **76,338** | `b55f66e4c04a429edd79a17bd6783d47e3acb13ea76413b575db64a6ea9f7cee` → `3ddfdb03c1c6910f71e05b0bec1eaf63c1f3b81ee02cc0af25c40b6acca12adc` | R2-C1 数值改实测值 + 旧披露句删除 |
| `05_response/Response_to_Reviewers.docx` | 63,770 → **63,730** | `da032f68a5f3c79f71aa04e7c0d5e4cfe0cc29709d5355ed072152bf9abd9223` → `ac860045b799e89d1f1c11078832c023064c134684dd3fa1f4e0f3aac6a93dfc` | docxenv 重建；verify_response.py EXIT=0 |
| `05_response/COVERAGE_CHECK.md` | 37,311 → **37,422** | `4c861e24d1d7c769030bd3f75299e5f9c176f1833d9603b27f1a7a0269d678f4` → `18054935cc0fb6b0a3128da9a1273225010873c6e88be64ede94cfb983248a32` | 三处 R2-C1 句长数值同步 |
| `QC/quality_gates_log.md` | 20,109 → **22,066** | `abe235fee0855fdaf0a16cc0dcbcca5bf3740b8f8368d3b705fb94d16748988d` → `e1799e79dfb635b95db1c075cd33e66f5d575e8c60450e62aefb3bcbe46cc3f7` | 追加「拆句轮更新（2026-10-15）」小节（append-only） |
| `05_response/ANCHOR_INVENTORY.tsv` | 85,776 → **85,834** | `3b6b5a631f72fce0aada6e21946d8aef2421293f20587e1036cc236fcbf123fc` → `26f2625ea6595f59d15a6c9d6a8b0502f63bcb518010877c0058e974c4a05979` | 重生（`anchor_inventory.py`）：176 行中**仅** Results ¶1 的 `full_text` 行变化，cols 1–5（file/section/kind/¶/首8词）**逐行不变** |

> `00_pinned/PINNED_PACK_CORRECTIONS.md`（本文件）与 `QC/FINAL_MANIFEST.md` 为**自指件**：
> 本文件同时是 `code.zip::code/PINNED_PACK_CORRECTIONS.md` 与
> `derived_data.zip::derived_data/number_dictionary/PINNED_PACK_CORRECTIONS.md` 的成员，
> 故其自身摘要由 `QC/FINAL_MANIFEST.md` 记录；两个 zip 的新摘要同样见该清单
> （§`06_compliance/`）。两处成员以**外科式重建**替换（`QC/tools/surgical_zip.py`，
> 其余成员原始 local record 逐字节搬运、成员表与顺序不变）。
> 本轮**未新增也未删除任何段落**：`md items total = 174`、两版 DOCX 均 **174 段**
> （`verify_anchors.py` / `scan_markdown_residue.py` 原始输出）。

### (viii.4) 回复信 R2-C1 同步（只改数字 token + 删旧披露）

- 均句长（三节合计）**32.51 → 23.04** 词/句；句数 **140 → 184**；总词数（`wc -w`）
  **4,644 → 4,332**；Discussion 均句长 **30.44 → 22.25**（不变）。
- **删除**原披露句 `**One sentence in the three sections now exceeds 45 words** — the 98-word
  sentence that indexes the supplementary tables in the first Results paragraph —`
  （已达标，**不得保留旧披露**），改为 `**No sentence in the three sections now exceeds 45 words**`。
- 同源表述一并同步：`01_manuscript/SENTENCE_STATS.md`（重生，含 §1b 拆前/拆后对照）、
  `05_response/COVERAGE_CHECK.md`（3 处）、`QC/quality_gates_log.md`（追加小节）。
  `10_FigureLegends.md` 及其余文件**无相关表述**，未改。

### (viii.5) 全门禁重跑（逐项原始输出，`QC/_split_rerun_all.log`）

| 门禁 | 命令 | 结果 |
|---|---|---|
| 1 DOCX 重建 | `QC/make_revision_docx.py`（docxenv 3.12.13） | `manuscript paragraphs written: 174`；高亮 118/174 段、218 run；CLEAN 62,652 B / MARKED 62,954 B；EXIT=0 |
| 2 锚点 | `05_response/verify_anchors.py` | `anchors: 28   matched in md AND both DOCX: 28   mismatched: 0`；EXIT=0 |
| 3 回复信 | `build_response_docx.py` + `verify_response.py` | docx 194 段 / 1 表；`anchors checked: 49 verbatim-present: 49 MISSING: 0`、`UNFLAGGED CLAIM OCCURRENCES: 0`；EXIT=0 |
| 4 残留 | `QC/scan_markdown_residue.py` | 两版 `TOTAL_residue 0`、`paragraphs 174`、行号域存在；GATE G5 PASS；EXIT=0 |
| 5 图表首现序 | `QC/g2_independent_crosscheck.py` | Figure `[1,2,3,4,5]` / FigureS `[1,2]` / Table `[1,2,3]` / TableS `[1..13]` 全 OK；`T3 … differences: 0`；EXIT=0 |
| 6 内容守恒 | `01_manuscript/verify_sentence_edit.py` | `=== RESULT: ALL CONSERVED ===`；EXIT=0 |
| 7 拆句守恒 | `01_manuscript/verify_split_conservation.py` | 局部/全文件四类多重集**删除集为空**；`ASSERT >45 == 0 : True`；EXIT=0 |
| 8 清单 | `QC/tools/verify_manifest.py` | `manifest rows parsed 58`、`sha256+bytes OK 58 MISMATCH 0 MISSING 0`；EXIT=0 |
| 9 入仓成员一致性 | `revision_2026/code/tools/check_repo_vs_zip.py` | `members: 100  byte-identical to a repository file: 100  mismatches: 0`；EXIT=0 |
| 10 DOI 回填演练 | `QC/tools/fill_doi.py 10.5281/zenodo.9999999 --dry-run` | `total: 12 slot(s); placeholder present 18; DOI present 0`；`DRY RUN complete: nothing was written`；EXIT=0 |

### (viii.6) 补充 PDF 与图件：**未受影响，无需重建**

`04_supplement/Supplemental_Information.pdf` = **1,510,270 B /
`a17d21b9f45de59f7e83b4adb9746c2c790596444792a595e2475a6d6d8f4f7a`**（与 §(vii) 逐个字节相同）；
`02_figures/` 14 个图件全部与 `QC/FINAL_MANIFEST.md` 的记录逐字节相同。核验命令：

```bash
sha256sum 04_supplement/Supplemental_Information.pdf      # a17d21b9…（不变）
python QC/g2_independent_crosscheck.py                    # 补充 PDF 页序 S1,S2,Table S1..S13 = OK
```

---

## (ix) 高亮口径改版：段落级 → 句级（+替换句词级）—— 2026-10-15

**触发**：`01_manuscript/HLA_LOH02_revision_MARKED.docx` 的旧高亮方案被驳回。编辑在决定信中的
原话是 *"Kindly use line numbering and **highlight all changes** made to the manuscript
(including added figures, revised panels, new references added, and text modifications)"*。
旧口径为"归一化段落相似度 < 0.75 → **整段**高亮"，会把整段（**含其中与投稿版逐字相同的句子**）
一并染色：218 高亮 run、**87.2%** 字符、118/174 段，其中 **58 句与投稿版逐字相同的句子**落在
高亮区间内——从读者视角等于把"未改过的内容"也标成了改动。

**授权范围（硬约束，全部遵守）**：只改**高亮的判定与切分方式**。正文文字 / 数字 / 图表号 /
引文编号**零改动**；**不增删段落**（两版 DOCX 仍 **174 段**、`verify_anchors.py` 仍 **28/28**）；
CLEAN 版保持 **0 高亮 run**；两个 Docx 逐段文本全等（仅高亮属性不同）。

### (ix.1) 新口径（已写入 `QC/make_revision_docx.py` 文档串，参数集中可复算）

1. 归一化（大小写 / 上标・下标 Unicode / `^n` / 标点 / 空白）后与投稿版**全部 115 个非空段落**
   做词级 `difflib.SequenceMatcher`，取**最佳匹配段**。
2. 在最佳匹配对内**按句子拆分**后作序列对齐（`SequenceMatcher` on sentence lists）：
   - `equal`（归一化完全相同的句子）→ **不上高亮**（本次修复的核心）；
   - `replace`（被修改的句子）→ 句内再做**词级 diff**，只高亮变更词串；
   - `insert`（新增句子）→ 整句高亮；若与配对段内某句词级相似度 ≥ `MOD_SENT=0.50`
     （实为"被改写"而非全新，如 §(viii) 拆句轮的产物）→ 退化为词级高亮；
   - `delete`（投稿版独有的句子）→ 新侧无对应文字，不产生高亮。
3. 词级 opcode 口径（`a`=新稿 / `b`=投稿版）：`replace` 与 `delete`（**新侧** text）→ 高亮；
   `insert`（**旧侧** text）→ 新侧没有对应字符，不产生高亮；`equal` → 不高亮。
4. 段落最佳词级相似度 < `NEW_PARA=0.15`（或长度不足以对齐）＝ 新增段落 / 新增章节 → 整段高亮。
5. 参考文献按 **PMID**：新增 9 条 → 整段高亮；保留 25 条 → 不高亮（与旧口径一致）。
6. 图注：新增图注（无可信匹配）→ 整条高亮；**实质改写**（词级高亮面积 ≥ `LEG_WHOLE=0.60`）
   → 整条高亮；**仅图号 token 变化**等小改 → 只高亮真正变化的词串。
7. 标题页字段标签（`**Title**`/`**Authors**`/…）与分块标题（`Title page`/`Back matter`）
   属转排脚手架 → 不高亮。
8. **反证守卫（硬约束）**：任何归一化后与投稿版某句逐字相同的句子，其字符区间内的高亮一律清除；
   由 `QC/verify_highlight_sentence_level.py` 直接读 DOCX 与投稿版独立复核（不依赖建构器内部状态）。

### (ix.2) 量化对照（`QC/HIGHLIGHT_VERIFY.md`，独立复核脚本实跑）

| 指标 | 旧口径（段落级） | 新口径（句级 + 词级） |
|---|---:|---:|
| 高亮 run 数 | 218 | **464** |
| 高亮段落数 | 118 / 174 = 67.8% | **111 / 174 = 63.8%** |
| 高亮字符数 | 59,084 / 67,799 | **48,263 / 67,799** |
| **高亮字符覆盖率** | **87.2%** | **71.2%** |
| 与投稿版**逐字相同**的句子中、被高亮的句数 | **58** | **0** |

**原始断言输出**（`QC/verify_highlight_sentence_level.py`，EXIT=0）：

```text
baseline sentences (submitted version) : 372
manuscript sentences (revised)         : 574
  verbatim-identical to a baseline sentence : 154 (26.8%)
------------------------------------------------------------------------------
ASSERT  verbatim-identical sentence carrying ANY highlight  (must be 0)
        observed = 0   ->  PASS
        (same assertion on the OLD paragraph-level build: observed = 58)
------------------------------------------------------------------------------
COVERAGE   old rule : 59084/67799 chars = 87.2%  (118 paras, 218 runs)
COVERAGE   new rule : 48263/67799 chars = 71.2%  (111 paras, 464 runs)
------------------------------------------------------------------------------
CLEAN highlight runs (must be 0)       : 0 -> PASS
MARKED vs CLEAN text equal per para    : PASS (0 diffs)
==============================================================================
RESULT: ALL GATES PASS
```

> **覆盖率为何仍是 71.2% 而非更低——不是判定过宽**：修订稿 574 句中仅 **154 句（26.8%）**
> 与投稿版逐字相同，其余 420 句确实是改写或新增。可与审稿意见逐条对应：R3-1 要求
> *"re-write the Discussion section … with minimal use of AI"*；R1 要求补入 1990s/2000s 的
> HLA-I 文献段（即新增文献 1–7）；R3-2/3/4 要求新增"校正非整倍体后的 TMB 关联"、"新抗原
> 负荷关联（NetMHCpan）"、"结构化变异签名"与"等位基因配对设计"。新口径保证**被染色的每一处
> 都确有改动**，且"逐字相同句带高亮 = 0"。

### (ix.3) 本轮改动 / 新增文件（bytes + sha256）

| 文件 | bytes | sha256 | 说明 |
|---|---:|---|---|
| `QC/make_revision_docx.py` | 28,098 | `8b015a4d4e21e8d7727f0e6621554ef934f7ed97e8aff9a9aa1163cb98df8604` | 高亮判定重写（句级 + 词级）；`add_par` 改为按**高亮掩码**切分 run，两版共用同一掩码 |
| `QC/verify_highlight_sentence_level.py` | 19,353 | `44d3560dac768ed1b768c7a5dfddfee838954842a10e45cf8086d2308def5337` | **新增**：独立复核（新旧覆盖率 / 反证断言 / 逐节表 / 10 段抽查表） |
| `QC/gen_highlight_summary.py` | 11,026 | `84705bbdd4b3a843f5f2bb71af47fe27e26996aca3e9813890291dbb253696e4` | **新增**：HIGHLIGHT_SUMMARY 生成器（数值全部程序化） |
| `QC/gen_docx_reports.py` | 28,574 | `8017c01a342fac993257366e50695c6d0216f18de38932cdfa5a06ddf9c1abb6` | §1 改为委托新生成器，防止旧口径被重新写出 |
| `01_manuscript/HLA_LOH02_revision_MARKED.docx` | 66,154 | `defefe4b5b7953f8a65889fc0e6f559646383b2404614a50363f0fd4438c2226` | 重建：174 段、行号域在、464 高亮 run |
| `01_manuscript/HLA_LOH02_revision_CLEAN.docx` | 62,887 | `b30a9ca26ff4de4198268a10e93c3ffc3c9f3cf89852f91c1d556c5ba4965c43` | 重建：174 段、0 高亮 run |
| `01_manuscript/HLA_LOH02_revision_HIGHLIGHT_SUMMARY.md` | 10,565 | `b5ecbad4ad0819aae938b5f24265e774b4361256c18b71cbdaba6ad385a31839` | 重生；文首注明"旧版段落级规则已废弃" |

> **DOCX 字节稳定性说明（不美化）**：`python-docx` 写 zip 时对成员使用**当前时刻**作为 DOS
> 时间戳，故两版 DOCX 的 **sha256 每次重建都会变**（字节数恒定 66,154 / 62,887 不变，逐段文本
> 与高亮掩码不变）。`FINAL_MANIFEST.md` 记录的是生成时刻的哈希。
>
> 本文件与两个 zip 为**自指件**：本文件同时是 `code.zip::code/PINNED_PACK_CORRECTIONS.md` 与
> `derived_data.zip::derived_data/number_dictionary/PINNED_PACK_CORRECTIONS.md` 的成员，故其
> 自身摘要与两个 zip 的摘要同由 `QC/FINAL_MANIFEST.md` 记录（成员以 `QC/tools/surgical_zip.py`
> 外科式替换，其余成员逐字节搬运）。

### (ix.4) 门禁重跑（原始输出见 `QC/_highlight_round/GATES.log`）

| 门禁 | 命令 | 结果 |
|---|---|---|
| 1 DOCX 重建 | `QC/make_revision_docx.py` | `manuscript paragraphs written: 174`；高亮 111/174 段、48263/67799 字符 = 71.20%、464 run；CLEAN 0 run；EXIT=0 |
| 2 句级高亮复核 | `QC/verify_highlight_sentence_level.py` | `verbatim-identical sentence carrying ANY highlight: observed = 0 → PASS`；`RESULT: ALL GATES PASS`；EXIT=0 |
| 3 锚点 | `05_response/verify_anchors.py` | `anchors: 28   matched in md AND both DOCX: 28   mismatched: 0`；EXIT=0 |
| 4 残留标记 | `QC/scan_markdown_residue.py` | 两版 `TOTAL_residue 0`、`paragraphs 174`、行号域存在；`GATE G5 … PASS`；EXIT=0 |
| 5 汇总重生 | `QC/gen_highlight_summary.py` | `wrote …HIGHLIGHT_SUMMARY.md (10565 bytes)`；EXIT=0 |
| 6 清单 | `QC/tools/verify_manifest.py` | `manifest rows parsed 58`、`sha256+bytes OK 58 MISMATCH 0 MISSING 0`；EXIT=0 |
| 7 入仓成员一致性 | `revision_2026/code/tools/check_repo_vs_zip.py` | 成员与仓库文件逐字节一致；EXIT=0 |

### (ix.5) 回滚点

改版前的产物与建构器已按字节保存，可直接回滚：

| 回滚文件 | bytes | sha256 |
|---|---:|---|
| `QC/_highlight_round/old/HLA_LOH02_revision_MARKED.docx` | 62,954 | `a2987113faffe43e4fc45a70b963efa802c365fea8542740b0343c11ba88c1c9` |
| `QC/_highlight_round/old/HLA_LOH02_revision_CLEAN.docx` | 62,652 | `66c2dca47169458ddda4bd42c98dff14fa62ed7142eff85aed120b7a2e0db1b2` |
| `QC/_highlight_round/old/HLA_LOH02_revision_HIGHLIGHT_SUMMARY.md` | 13,341 | `aebb09601105df76b2839261c5faa63747718caf1c7391392012ffbd92248b59` |
| `QC/_highlight_round/old/make_revision_docx.OLD.py`（旧建档器） | 15,435 | `978af1b6ec2736cf0fae979105c444152345b5bb5aebb406b75b3e11b16da986` |

旧口径产物的"未变句子带高亮"基线（复核脚本产出）= **58 句**；新口径 = **0 句**。

---

## (x) 高亮口径第三轮：**三层最小单位**（Tier 1 整块 / Tier 2 不染色 / Tier 3 只染变动的词串）—— 2026-10-15

### (x.1) 为什么再改一轮

第 (ix) 轮的"句级"口径已保证"逐字相同的句子带高亮 = 0"，但**重写句仍是整句涂黄**。
本次修订是**叙事重建**而非句级润色，故整句染色的面积必然很大（71.2% 字符、111/174 段），
从编辑视角读起来仍近似"几乎全篇高亮"。第 (x) 轮把最小单位从"句"下沉到"**变动的词串**"：
重写句内**只染真正改动或新增的词**，其余词保持白色；整块黄只保留在**确实新增**的内容上。

修订规模的客观量度（与投稿版 `iscience投稿版本/投稿版本/manuscript.docx` 逐段比对）：

- 投稿版 **6,161 个实词 / 115 个非空段落 / 372 句**；修回稿 **11,177 个实词 / 174 段 / 574 句**（实词 ＋81%）。
- 修回稿 574 句中仅 **154 句（26.8%）**与投稿版逐字相同；其余 420 句为改写或新增。
- 差异最大的若干段落（如 Results 的等位基因配对段、STAR Methods 的新抗原方法段）与投稿版**任何**
  单段的词级相似度均 < 0.15，说明其为**新写内容**而非旧句重排。

### (x.2) 现行规则（三层，`QC/make_revision_docx.py`，参数全部显式）

| 层 | 含义 | 判定 |
|---|---|---|
| **Tier 1a** | 整段黄：新增段落/新增章节 | 无可信配对段（最佳词级相似度 < NEW_PARA=0.15）**且**强复用（≥MINRUN=2 连续词的对齐块）占该段词数 < NEW_FRAC=0.15 |
| **Tier 1b** | 整句黄：新增句子 | 句级序列对齐判为 `insert`，且与投稿版任一句的词级相似度均 < MOD_SENT=0.40 |
| **Tier 1c** | 整条黄：新增参考文献 | PMID 不在投稿版 28 条中（本轮 9 条） |
| **Tier 1d** | 整条黄：新增/实质改写图注 | 无对应图注，或词级改动面积 ≥ LEG_WHOLE=0.60 |
| **Tier 2** | 不染色 | 归一化后与投稿版某段/某句逐字相同（含反证守卫强制清零） |
| **Tier 3** | 只染变动的词串 | 段落级词对齐中只高亮新稿侧未对齐的词串；`replace` 块再做字符级回退（公共前后缀 ≥ CHARMIN=6 字符留白） |
| scaffold | 不染色 | 标题页字段标签 / 文章类型取值 / 字数行 / 分块标题（转排脚手架） |

对齐与归一化沿用既有逻辑（`norm()`），并将词对齐的"词"做 token 级归一化 `tn()`，使
`tumours,`/`tumours`、`(LOH)`/`LOH`、`allele-specific`/`allele specific` 不被误判为改动；
孤立单字对齐块仅当该词是实词（非 the/of/we/not 一类功能词）时才计为复用，避免句中"单字白洞"。
**本轮不再整句涂黄。**

### (x.3) 三套口径对照（同一修回稿、同一投稿版基准）

| 指标 | ① 段落级（<0.75 整段高亮） | ② 句级（整句高亮） | ③ **本轮三层最小单位** |
|---|---:|---:|---:|
| 高亮字符覆盖率 | 87.2% (59,084/67,799) | 71.2% (48,263/67,799) | **61.2% (41,524/67,799)** |
| 高亮段落数 | 118 / 174 = 67.8% | 111 / 174 = 63.8% | **109 / 174 = 62.6%** |
| 高亮 run 数 | 218 | 464 | **655** |
| 逐字相同句带高亮（硬断言，要求 0） | 58 | 0 | **0** |

本轮档位构成：

| 档位 | 段落 | 高亮段 | 字符 | 高亮字符 |
|---|---:|---:|---:|---:|
| Tier 3（只染变动的词串） | 83 | 78 | 45,647 | 28,576 |
| Tier 1a（整段黄：新增段/章节） | 16 | 16 | 9,799 | 9,711 |
| Tier 1c（整条黄：新增文献） | 9 | 9 | 2,760 | 2,736 |
| Tier 1d（整条黄：新增/改写图注） | 6 | 6 | 537 | 501 |
| scaffold（转排脚手架） | 11 | 0 | 185 | 0 |
| Tier 2（逐字相同，不染色） | 49 | 0 | 8,871 | 0 |

逐节覆盖率（本轮）：Title page 33.7%、Summary 66.2%、Highlights 44.8%、eTOC 79.2%、
Introduction 68.7%、Results 79.5%、Discussion 81.2%、STAR Methods 49.0%、Back matter 40.1%、
Figure legends 73.5%、References 26.5%。

> **为什么仍是 61.2% 而不是更低**：整块黄（Tier 1）只占 9,711+2,736+501 = 12,948 字符（19.1%），
> 其余 28,576 字符（42.2%）是 Tier 3 的**逐词串**染色——这些词在投稿版中确实没有对应（或只在
> 不同语境中出现）。若改为"**无序**词表口径"（只要该词在投稿版出现过就不染色），覆盖率可降到
> 24.5%，但那会把"同一批词被重新组织成相反结论"的改写**隐藏掉**（例如极性反转、
> 关联方向反转），对审稿人反而是危险的不透明，故不采用。
> 另附一份**逐节改动清单** `05_response/Change_Summary.md`（并在 `01_manuscript/` 放同目录副本），
> 逐节列出新增分析、新图新表、数字改动、否证/下调语气的句子与新增文献，便于只看要点。

### (x.4) 本轮改动 / 新增文件（bytes + sha256，取值时刻见 `QC/FINAL_MANIFEST.md`）

| 文件 | bytes | sha256 | 说明 |
|---|---:|---|---|
| `QC/make_revision_docx.py` | 34,052 | `bb6ea0fb7a30e264074589b9bb7fdb1478b9d4660d7dba3387f8466a30a933ab` | 高亮判定重写为**三层最小单位**；新增 token 归一化 `tn()`、`PAIR_OK/NEW_FRAC/MINRUN/CHARMIN` 参数与档位记录 |
| `QC/verify_highlight_three_tier.py` | 23,723 | `934015e0f488d69bad70231cbda34bb0527640f5ae83cc0e0abd626cdd4a85cf` | **新增**：独立复核脚本（三口径对照 / 反证断言 / 逐节覆盖率 / 10 段抽查表 / CLEAN 与两版一致性） |
| `QC/gen_change_summary.py` | 13,163 | `ae95ea66750c38fe0aca5ab300925d7efd3f563e70dcf1dd965b0e118e98d350` | **新增**：逐节改动清单生成器（新交付物 `Change_Summary.md` 的两份副本由它写出） |
| `QC/gen_highlight_summary.py` | 12,921 | `ac688ed3fdbad2f8074a16e93b94407ac5f8383d0c158b94d9584eadb53c189a` | 改写叙述为三层口径（数值仍全部程序化取自两个 JSON） |
| `QC/verify_highlight_sentence_level.py` | 19,644 | `869def3e606f00abc6cb0aa43b58ac3406f23512234dd2b034d8f50ec4af0d07` | 第二轮复核脚本保留为历史件，输出改到 `QC/_highlight_round/sentence/`，不再覆盖现行报告 |
| `01_manuscript/HLA_LOH02_revision_MARKED.docx` | 68,500 | `d21308a29dfd0ac1e9fc0fb2867300384fc83df5a242095a0ccfac0811e2bc2c` | 重建：174 段、行号域在、655 高亮 run、109/174 段有染色 |
| `01_manuscript/HLA_LOH02_revision_CLEAN.docx` | 62,888 | `ab67e4435690e625ae4b3f9fdbfd1aed590997104e4abcffeca8cc75cec3956c` | 重建：174 段、0 高亮 run |
| `01_manuscript/HLA_LOH02_revision_HIGHLIGHT_SUMMARY.md` | 10,408 | `afadf0cb0b45b926a9109610a6b47b5d996bbdac2405b010f43ae36a79450310` | 重生：文首注明段落级与句级两轮口径均已废弃 |
| `05_response/Change_Summary.md` | 18,539 | `b6988c236475b14a2f5208824e274261f00a01332cdb6a10075a85d6552bc218` | **新增交付物**：逐节改动清单（给编辑） |
| `01_manuscript/Change_Summary.md` | 18,539 | `b6988c236475b14a2f5208824e274261f00a01332cdb6a10075a85d6552bc218` | 同上文件的同目录副本（与两份 DOCX 放在一起） |
| `QC/HIGHLIGHT_VERIFY.md` | 6,358 | `f8d04d9b01fbdd070019e7372135f321214e354c0bb5abd55e1f0491f8ea3066` | 本轮复核报告（三口径对照 / 断言原始输出 / 逐节表 / 抽查表） |

> **提交清单由 58 → 60 项**：`FINAL_MANIFEST.md` 新增两行——`05_response/Change_Summary.md`（新交付物，可随回复信附给编辑）与`01_manuscript/Change_Summary.md`（同目录副本）。除此两行外清单构成不变。

> **DOCX 字节稳定性（不美化，同 §(ix)）**：`python-docx` 写 zip 时对成员使用当前时刻作为 DOS
> 时间戳，故两版 DOCX 的 **sha256 每次重建都会变**（逐段文本、run 切分与高亮掩码不变）。
> `FINAL_MANIFEST.md` 记录的是生成时刻的哈希。本文件亦为两个 zip 的成员，成员以
> `QC/tools/surgical_zip.py` 外科式替换，其余成员逐字节搬运。

### (x.5) 门禁重跑（原始输出见 `QC/_highlight_round/GATES.md`）

| 门禁 | 命令 | 结果 |
|---|---|---|
| 1 DOCX 重建 | `QC/make_revision_docx.py` | `manuscript paragraphs written: 174`；高亮 109/174 段、41,524/67,799 字符 = 61.20%、655 run；CLEAN 0 run；EXIT=0 |
| 2 三层高亮复核 | `QC/verify_highlight_three_tier.py` | `ASSERT verbatim-identical sentence carrying ANY highlight -> observed = 0 -> PASS`；三口径 87.2% / 71.2% / 61.2%；`RESULT: ALL GATES PASS`；EXIT=0 |
| 3 高亮汇总重生 | `QC/gen_highlight_summary.py` | `wrote …HIGHLIGHT_SUMMARY.md`；EXIT=0 |
| 4 逐节改动清单 | `QC/gen_change_summary.py` | `wrote 05_response/Change_Summary.md` + `01_manuscript/Change_Summary.md`；EXIT=0 |
| 5 锚点 | `05_response/verify_anchors.py` | `anchors: 28   matched in md AND both DOCX: 28   mismatched: 0`；EXIT=0 |
| 6 残留标记 | `QC/scan_markdown_residue.py` | 两版 `TOTAL_residue 0`、`paragraphs 174`、行号域存在；`GATE G5 … PASS`；EXIT=0 |
| 7 清单 | `QC/tools/verify_manifest.py` | 见该命令的原始输出（清单行数 58 → 60） |

### (x.6) 回滚点（第二轮"句级整句高亮"产物，按字节保存）

| 回滚文件 | bytes | sha256 |
|---|---:|---|
| `QC/_highlight_round/sentence/make_revision_docx.SENTENCE.py`（第二轮建构器） | 28,098 | `8b015a4d4e21e8d7727f0e6621554ef934f7ed97e8aff9a9aa1163cb98df8604` |
| `QC/_highlight_round/sentence/MARKED.sentence.docx`（第二轮 MARKED（71.2% 口径）） | 66,154 | `defefe4b5b7953f8a65889fc0e6f559646383b2404614a50363f0fd4438c2226` |
| `QC/_highlight_round/sentence/CLEAN.sentence.docx`（第二轮 CLEAN） | 62,887 | `b30a9ca26ff4de4198268a10e93c3ffc3c9f3cf89852f91c1d556c5ba4965c43` |
| `QC/_highlight_round/sentence/HIGHLIGHT_VERIFY.md`（第二轮复核报告） | 5,745 | `e7f14a670f1e5ff712f6b49950f642b11b3f2e47ff736f5d96be02b5bc1106e0` |
| `QC/_highlight_round/sentence/HLA_LOH02_revision_HIGHLIGHT_SUMMARY.md`（第二轮高亮汇总） | 10,565 | `b5ecbad4ad0819aae938b5f24265e774b4361256c18b71cbdaba6ad385a31839` |
| `QC/_highlight_round/old/HLA_LOH02_revision_MARKED.docx`（第一轮 MARKED（段落级 87.2% 口径）） | 62,954 | `a2987113faffe43e4fc45a70b963efa802c365fea8542740b0343c11ba88c1c9` |

三段口径的"未变句子带高亮"基线依次为 **58 → 0 → 0**；本轮在保持该硬断言为 0 的前提下，
把覆盖率由 71.2% 降到 61.2%，并**取消了重写句的整句涂黄**。

---

## (xi) 高亮口径第四轮：**Mode C 实质改动口径**（Tier 3 内只染数字 / 图表号 / 文献号 / 主张限定词）—— 2026-10-15

### (xi.1) 为什么再改一轮

第 (x) 轮把最小单位下沉到"变动的词串"后，字符覆盖率降到 **61.2%**、且"逐字相同句带高亮 = 0"
成立。但事实底数是：修回稿与投稿版**逐句比对**只有 154/574 句（26.8%）逐字相同，
其余 420 句确为改写或新增；**逐句标黄必然面积大**。编辑视角下 61.2% 仍近似"基本全是黄的"。

因此第 (xi) 轮改为**"实质改动口径"（Mode C）**：Tier 1（真正新增的整段/整句/图注/文献）
保持整块黄不变；Tier 3 内部**再加一层语义筛选**，只把标记落在**有意义的改动**上，
纯文体性改写（同义替换 / 词序 / 连接词 / 单复数）**不再染色**，但逐条记入
`05_response/Change_Summary.md`（§15 全量、§16 代表例）——即"**不染色 ≠ 不交代**"。

### (xi.2) Mode C 规则（`QC/make_revision_docx.py`，`--mode substantive` 为默认值）

在 Tier 3 得到"新稿侧未对齐词串"（= 第三轮全口径结果）之后，**只保留**下列四类：

| 类别 | 内容 | 实现 |
|---|---|---|
| **(a) 数字 token** | 数字、百分比、CI、P 值、n、区间 | 改动区内 `\d` 命中的 token 即染；向右吃进 `%`，向左吃进 `=` `<` `>` `≈` `≤` `≥` `±` |
| **(b) 图表号 / 参考文献号** | `Figure S1`、`Fig. 3B`、`Table 2`、`Data S4`、`PMID: 26806129` | 正则 `\b(?:fig(?:ure)?s?\.?\|tables?\|data)\s*S?\d+[A-Za-z]?\b` 与 `\bpmid:?\s*\d+`，命中即染所在 token |
| **(c) 主张与限定词的新增/删除** | withdraw / no longer / do not claim / not independent / must not be read / attenuated / over-adjusted / descriptive / reliability / callable / arm-independent / aneuploidy / global / reversed / negative / null / constraint / limitation 等 | **51 个单 token**（`tn()` 归一化，故 `arm-independent`/`arm independent` 等价，含中文对应）＋**31 条多词短语**；改动块**新旧任一侧**命中即染新侧对应 token |
| **(d) 整段/整句新增** | 走 Tier 1，与全口径判定**完全一致**（不因 Mode 变化） | Tier 1a / 1b / 1c / 1d 判定逻辑逐字未改；图注 Tier 1d 的面积阈值仍按**全口径**改动面积算 |

另加**句级数字补丁**：对每一句取投稿版最相似句（≥0.30）重做词对齐，凡数字/图表号不同的 token
一律补染，使"数字/图表号/文献号变更覆盖率 = 100%"在句级口径下也成立。

**反证守卫的一处界定修订（本轮唯一的口径外修订）**：句子 = 归一化后 **≥4 字符且含字母**的句段
（新增 `is_real_sentence()`）。`1.` `2.` 之类**编号残片**（参考文献条目号，norm 后是纯数字）
不再视为"句子"，因此不再被投稿版同号条目"逐字相同"清掉 —— 否则 9 条新增文献的**条目号全部漏染**
（本轮实测：修订前新增文献整条染色 283/285，修订后 285/285）。

### (xi.3) 四套口径对照（同一修回稿、同一投稿版基准、同一归一化）

| 指标 | ① 段落级 | ② 句级 | ③ 词/字符级全口径（**备选**） | ④ **Mode C 实质改动（正式交付）** |
|---|---:|---:|---:|---:|
| 高亮字符覆盖率 | 87.2% (59,084/67,799) | 71.2% (48,263/67,799) | 61.2% (41,524/67,799) | **28.8% (19,537/67,799)** |
| 高亮段落数 | 118 / 174 = 67.8% | 111 / 174 = 63.8% | 109 / 174 = 62.6% | **101 / 174 = 58.0%** |
| 高亮 run 数 | 218 | 464 | 655 | **589** |
| 逐字相同句带高亮（硬断言，要求 0） | 58 → **42**（见下） | 0 | 0 | **0** |
| 数字/图表号/文献号变更覆盖率（硬断言，要求 100%） | 未测 | 未测 | 未测 | **100.0%（821 实例，0 漏染）** |

> ① 列的 58 → 42 是 §(xi.2) 末尾那处界定修订所致（同一条断言现在只在**真句子**上判定，
> 排除了段落级口径下被整段染色的编号残片），**不是口径变化**。

Mode C 档位构成：

| 档位 | 段落 | 高亮段 | 字符 | 高亮字符 |
|---|---:|---:|---:|---:|
| Tier 1a（整段黄：新增段/章节） | 16 | 16 | 9,799 | 9,711 |
| Tier 3（只染实质改动 token/短语） | 83 | 70 | 45,647 | 6,565 |
| Tier 1c（整条黄：新增文献） | 9 | 9 | 2,760 | 2,760 |
| Tier 1d（整条黄：新增/改写图注） | 6 | 6 | 537 | 501 |
| scaffold（转排脚手架） | 11 | 0 | 185 | 0 |
| Tier 2（逐字相同，不染色） | 49 | 0 | 8,871 | 0 |

字符分解（分母 67,799）：**Mode C 实质改动 19,537（28.8%）**
＝ Tier 1 整块黄 12,972（19.1%）＋ Tier 3 实质改动 token 6,565（9.7%）；
**纯文体改写（不染色）22,210（32.8%）**（独立量算：直接比较两份 DOCX 高亮掩码，全口径有而 Mode C 无）；
Mode C 有而全口径无 223 字符（句级数字补丁 ＋ 新增文献条目号）；逐字未变/脚手架 9,056（13.4%）。
**整块无任何实质改动 token 的纯文体改写块：600 块 / 11,542 字符**（逐节列于 `Change_Summary.md` §15）。

实质改动标记（token/短语级 span）**954 处**；句级数字补丁用的最相似句相似度下限 `SEG_NUM_MIN_SIM=0.30`。

逐节覆盖率（Mode C）：Title page 9.8%、Summary 17.0%、Highlights 15.1%、eTOC 10.7%、
Introduction 6.5%、Results 33.6%、Discussion 29.0%、STAR Methods 16.8%、Back matter 9.7%、
Figure legends 66.6%、References 26.7%。

### (xi.4) 备选文件位置与口径切换（一条命令 / 一个参数）

| 口径 | 文件 | 说明 |
|---|---|---|
| **Mode C（正式交付）** | `01_manuscript/HLA_LOH02_revision_MARKED.docx` / `HLA_LOH02_revision_CLEAN.docx` | 默认 `python QC/make_revision_docx.py` |
| **全口径（备选，不用于投稿）** | `01_manuscript/_alternative/HLA_LOH02_revision_MARKED_full.docx`（68,500 B，sha256 `d21308a2…`）＋ `HLA_LOH02_revision_CLEAN_full.docx`（62,888 B，`ab67e443…`） | `python QC/make_revision_docx.py --mode full`（或 `HLA_HL_MODE=full`）；判据记录在 `_alternative/_docx_decisions_full.json`，第三轮独立复核 JSON 为 `_alternative/_highlight_verify_full.json` |

切换方式：`make_revision_docx.py --mode full|substantive`（默认 `substantive`）；
两模式共用同一套 Tier 1/Tier 2 判定与全部参数（`QC/_docx_decisions.json` 的 `params` 中记录 `MODE`）。
备选文件为**第三轮构建快照**（61.2%）；因 (xi.2) 的守卫界定修订，同一脚本重跑 `--mode full`
现得 **41,550 字符 = 61.3%**（差 26 字符 = 9 条新增文献的条目号），Mode C 重跑得 19,537 = 28.8%。

### (xi.5) 本轮改动 / 新增文件（bytes + sha256，取值时刻为本节生成时）

| 文件 | bytes | sha256 | 说明 |
|---|---:|---|---|
| `QC/make_revision_docx.py` | 49,004 | `f6e3e0414b175d5b70387a7c57e46a0e5e3dc23138a61f93fd6e76b189c771e2` | 新增 `MODE`（full/substantive）、`QUAL_TOKENS/QUAL_PHRASES/FIGTAB_RE/REF_PMID_RE`、`_substantive_spans()`、`_mode_c_filter()`、`_sentence_numeric_spans()`、`is_real_sentence()`、`resolve_outputs()`；`--mode full` 产物落 `_alternative/`，并输出全口径对照与纯文体改写块记录 |
| `QC/verify_highlight_mode_c.py` | 44,278 | `cc9359fd06082691dd64a9040c6550715a8409817915a1e48098a0989c8902c8` | **新增**：Mode C 独立复核（四口径对照 / 两个硬断言 / 四套独立覆盖率审计 / 逐节表 / 10 段抽查 / 纯文体改写代表例 / 两模式掩码集合差） |
| `QC/HIGHLIGHT_VERIFY_MODE_C.md` | 13,132 | `125b8bcba20386c839b42edfd97a175f8a9c3d2b21bc799aa3bca02223bed303` | **新增**：复核报告（含两个硬断言的原始输出） |
| `QC/_highlight_verify_mode_c.json` | — | `712aad07bae155ba53c7e70e1422f9a3e053291408fa2069b8e2816d756d00cd` | **新增**：机器可读复核结果 |
| `QC/_docx_decisions.json` | — | `29e6d9a098309f2733777ca2d94af9d26a649e3b35d20c058ecf42229ba58562` | 重生：新增 `hl_chars_full_mode` / `stylistic_chars` / `subst_reasons` / `stylistic_blocks` 等字段；`params.MODE=substantive` |
| `QC/gen_change_summary.py` | 19,291 | `f7abf0c67f8aacb9180e6a1bc69fc7631aaf459cdb65f506486a86d154967bb6` | 扩展：四口径表 ＋ 逐节"纯文体改写（不染色）"清单 ＋ **§15 全量清单（600 块）**＋ §16 代表例；数据源改为 Mode C 复核 JSON |
| `QC/gen_highlight_summary.py` | 21,696 | `b9e85bc4bd884932c6eb6268c96752e6133dbeb3715b471571fe3c569e0cfc25` | 改写：文首给出四口径数字与**切换命令**，§2 增 Mode C 规则，§7 增纯文体改写代表例 |
| `QC/HIGHLIGHT_VERIFY.md` | 6,975 | `e1f32a6995ff58647aeda790a78e48c453599b0b5bd31da90969ce4cb83187f1` | 文首加横幅：本文件为**第三轮全口径（备选）** 报告，正式口径见 `HIGHLIGHT_VERIFY_MODE_C.md` |
| `01_manuscript/HLA_LOH02_revision_MARKED.docx` | 67,509 | `d38c9536655ea34b32ff65728ef9bd590aa053c81888030addb63efcd1cc6bdb` | 重建（Mode C）：174 段、行号域在、589 高亮 run、101/174 段有染色、28.8% |
| `01_manuscript/HLA_LOH02_revision_CLEAN.docx` | 62,888 | `308510748c72591af40856163bcef0c7f602f17899f9b9e7c159afad3183709e` | 重建：174 段、0 高亮 run（逐段文本与 MARKED 全等） |
| `01_manuscript/HLA_LOH02_revision_HIGHLIGHT_SUMMARY.md` | 17,596 | `4d0ca8ccf5e4eba3afdff09292efc1f514b652e3a7d0db57958d132dd2fa2a88` | 重生：文首四口径表 ＋ 切换方法；§7 纯文体改写 |
| `05_response/Change_Summary.md` | 118,705 | `cef3cdaf071251de3049868a04f45e3dcf18ddaaceabfe76a640901ea2929f83` | 重生：四口径 ＋ 逐节纯文体清单 ＋ §15 全量（600 块 / 11,542 字符）＋ §16 代表例 |
| `01_manuscript/Change_Summary.md` | 118,705 | `cef3cdaf071251de3049868a04f45e3dcf18ddaaceabfe76a640901ea2929f83` | 同目录副本 |

### (xi.6) 门禁重跑（原始输出）

| 门禁 | 命令 | 结果 |
|---|---|---|
| 1 DOCX 重建（Mode C） | `QC/make_revision_docx.py` | 174 段；`highlighted characters 19,537 / 67,799 = 28.80%`；`full-mode reference 41,550 = 61.30%`；`stylistic-only 22,210 = 32.80% (600 blocks)`；`substantive marks 954`；`marked highlight runs 589`；`clean highlight runs 0`；EXIT=0（`QC/_modec_build.out`） |
| 2 Mode C 复核 | `QC/verify_highlight_mode_c.py` | `ASSERT A ... observed = 0 -> PASS`；`ASSERT B instances = 849 (excluded as Tier-2 sentence = 28) uncovered = 0 -> PASS`；审计 A 552/552、B0.30 184/184、B0.55 51/51、C 34/34 全部 100.0%；`CLEAN highlight runs 0 -> PASS`；`MARKED vs CLEAN text equal per para PASS (0 diffs)`；`paragraphs 174 / 174 / 174`；`RESULT: ALL GATES PASS`；EXIT=0（`QC/_modec_verify.out`） |
| 3 高亮汇总重生 | `QC/gen_highlight_summary.py` | `wrote …HIGHLIGHT_SUMMARY.md (17596 bytes)`；EXIT=0 |
| 4 逐节改动清单 | `QC/gen_change_summary.py` | `wrote 05_response/Change_Summary.md (118705 bytes)` ＋ 同目录副本；EXIT=0 |
| 5 锚点 | `05_response/verify_anchors.py` | `anchors: 28   matched in md AND both DOCX: 28   mismatched: 0`；EXIT=0（`QC/_modec_verify_anchors.out`） |
| 6 残留标记 | `QC/scan_markdown_residue.py` | 两版 `TOTAL_residue 0`、`paragraphs 174`、行号域存在、MARKED `highlight_runs 589`、CLEAN `0`；`GATE G5 … PASS`；EXIT=0（`QC/_modec_scan_residue.out`） |
| 7 全口径回归 | `QC/make_revision_docx.py --mode full` | 与第三轮结果**逐项一致**：109/174 段、41,524 字符按备选快照计（当前脚本重跑 41,550）、655 run、档位构成相同；EXIT=0（`QC/_fullmode_regress.out`） |

> **未做（按本轮约束）**：未重生 `QC/FINAL_MANIFEST.md`、未推送仓库、未重建补充 PDF 与
> `Supplementary_Tables.docx` —— 留给图形微调轮结束后的整合步骤统一处理。
> 本轮亦**未改动任何正文文字/数字/图表号**，段落数仍为 174；CLEAN 仍零高亮。

### (xi.7) 回滚点

| 回滚文件 | 位置 | 说明 |
|---|---|---|
| 第三轮全口径 MARKED/CLEAN（61.2%） | `01_manuscript/_alternative/*_full.docx`（sha256 `d21308a2…` / `ab67e443…`） | 由 `--mode full` 或直接复制使用；不用于投稿 |
| 第三轮 `_docx_decisions.json`（改前快照） | `QC/_highlight_round/mode_c_backup/_docx_decisions.json` | 本轮改前的判据记录 |
| 第三轮两份 DOCX 字节快照 | `QC/_highlight_round/mode_c_backup/`（`HLA_LOH02_revision_MARKED.docx` / `_CLEAN.docx`） | 与上表 sha256 一致 |
| 改前的 `gen_highlight_summary.py` | `QC/_highlight_round/mode_c_backup/gen_highlight_summary.OLD.py` | 第三轮汇总生成器 |
| 第一/二轮产物 | `QC/_highlight_round/old/`、`QC/_highlight_round/sentence/` | 同 §(x.6) |

四段口径的"未变句子带高亮"基线依次为 **58 → 0 → 0 → 0**；
本轮在把覆盖率由 61.2% 降到 **28.8%** 的同时，新增并满足第二个硬断言
（**数字/图表号/文献号变更覆盖率 = 100%**，821 个实例全部覆盖）。



---

## (xii) 整合轮：用户图形微调落地 + 两处既有图缺陷修复 + 补充 PDF 重建 + Mode C 高亮定稿 + 冻结入仓 —— 2026-10-15

### (xii.1) 本轮范围与铁律

- 范围：`02_figures/`（7 图）、`04_supplement/Supplemental_Information.pdf`、`QC/`、仓库 `revision_2026/`、两个存交包；`03_tables/Supplementary_Tables.docx`（只读，未改）、`01_manuscript/`、`05_response/` 正文与表格**未改**。
- **三条铁律**（用户明令）：① 不改任何数字/结论；② 不改变已确认的位移量（所有微调读数一律取自 `02_figures/QC_user_adjust_round1/measured_constants.tsv`，脚本缺该文件即 `stop()`）；③ 图件只允许「两处既有缺陷的修复」与必要重绘。
- 本轮**唯一**触碰图件绘制逻辑的两处改动见 §(xii.3)；Fig3/4/5/S1/S2 五张图、两份高亮 DOCX、正文 md、表格、投稿信**均未改动**。

### (xii.2) 用户 10 项图形位移 —— 逐项实测值（容差 ±0.25 字符）

量测对象 = **重出后成品 PDF 的真实文本层/矢量层**（`QC_user_adjust_round1/m6_verify.py`、`verify_after.py`、`m7_qa_ink2.py`），非目测、非脚本自报。

| 用户项 | 面板 | 用户要求 | 实测位移（pt） | 实测（字符） | 残差（字符） | 判定 |
|---|---|---|---|---|---|---|
| 1 | Fig1A | 最后两行数字（`217/1958`、`11.1`、`34/354`、`9.6`）整体右移 10 字符宽 | +29.7144…+29.7147 | +10.0001…+10.0002 | ≤ +0.0002 | PASS |
| 2 | Fig1C | 注释框（含文字）整体上移 3 字符高；每行重排 ≤54 字符 | +17.7977（文字块）/ +17.8549（框） | 3.0021 / 3.012 | +0.0021 / +0.012 | PASS |
| 3 | Fig2A | HR(OR) 估计值列整体左移 14 字符宽（4 行） | −34.7145（4 行同值，极差 0.0000） | 14.0002 | +0.0002 | PASS |
| 4 | Fig2B | 注释框左右各扩 5 字符宽（总 +10） | 10.9046 / 10.9046 / 21.8091 | 5.001 / 5.001 / 10.002 | +0.001 / +0.001 / +0.002 | PASS |
| 5 | Fig3C | 第 1、5 个 OR 值左移 20 字符宽 | −49.301 | −20.000 | −0.000 | PASS |
| 6 | Fig4A | 全部 6 个 OR 值上移 1 字符高 | −5.801 | 0.999 | −0.001 | PASS |
| 6 | Fig4B | 全部 6 个 OR 值上移 1 字符高 | −5.797…−5.801 | 0.999 | −0.001 | PASS |
| 7 | Fig5A | 全部 10 个 HR 值（未校正+校正两系列）右移 25 字符宽 | +59.254 | +25.000 | −0.000 | PASS |
| 8 | Fig5B | 第 2 个 HR 值右移 32 字符宽 | +75.844 | +31.999 | −0.001 | PASS |
| 9 | FigS1C | 第 1 个数值标签上移 3 字符高；文本框 10 字符高 × 26 字符宽（每行 ≤26） | −16.875 / 57.398 / 60.086 | 2.994 / 9.981 / 26.00 | ≤ 0.019 | PASS |
| 10 | FigS2B、FigS2C | 第 2、3 列数字上移 3 字符高；OR 数值列右移 25 字符宽 | −16.527…−16.531 / +56.883 | 2.994–2.995 / 24.999 | ≤ 0.006 / 0.001 | PASS |

> 源报告把 Fig4A 与 Fig4B 同标为第 6 项、FigS1/FigS2 分别标为第 9/10 项，故 10 个用户项对应上表 11 个面板行。
> 全部 11 行均在容差内（最大残差 +0.012 字符）。未点名标签的位移恒为 0.000 pt（逐字表见 `QC_user_adjust_round1/TABLES_index_to_value.md`）。
> 正效应证据：位移前 Fig3C/Fig4A/Fig4B/Fig5A/Fig5B 共 19/32 个数值标签与误差棒真实墨迹融合，位移后 0/32。

### (xii.3) 两处既有图缺陷的修复（本轮唯一两处图件改动）

#### (a) Fig2B 注释框第 1 行「Proportion mediated = 1.51 (>1 indicates suppression:」从未渲染（既有缺陷）

- 症状：成品该框只有 1 行；文本层搜 `Proportion`/`mediated`/`suppression` 全为空；600 dpi 栅格在 y 196.2–205.1 pt 无任何字形墨迹；框高 22.3 pt = 单行框高。
- 根因（代码级）：`20_fig2.R` 先 `md <- md[!is.na(ord)]`（只留 ACME/ADE/Total 三行）**再**取 `md[Quantity == "Proportion mediated"]$Estimate` → `numeric(0)` → `sprintf()` 返回 `character(0)` → `c(character(0), "the direct…")` 只剩 1 个元素。
- 修法（只改取数顺序，**未改任何数字**）：过滤前先取 `ua_pmd <- md[Quantity == "Proportion mediated"]$Estimate` 并 `stopifnot(length(ua_pmd) == 1L, is.finite(ua_pmd))`；注释框第 1 行改用 `ua_pmd`（`fig3b_mediation.tsv` 原值 1.5118 → `%.2f` → `1.51`，与既有意图一致）。
- 几何后果（`flow_layout` 语义自动发生，无手填坐标）：框由 1 行→2 行，`h_norm` **25% → 35%**（0.40→0.56 in）；框顶锚定 y=195.87 pt **不动**，框底 218.17 → **227.08 pt**（向下增高 8.91 pt），与 ACME 行数值标签 y0=228.56 余量 1.48 pt；两行文字均在框内（左/右余量 2.231/2.247 与 2.524/2.536 pt）。

#### (b) Fig1C 注释框比正文窄（既有缺陷；本轮「越框 3 处」全部来自此）

- 症状：框宽 99.85 pt，而正文最长行 120.41 pt → 每侧越出 9.3–10.3 pt（pre-round1 基线 17.25/17.24 pt）。
- 根因：`note_box(plot_w_in = 5.4)` 用的是**名义**面板宽；Figure1C 面板**实测宽** = 317.68 pt = **4.4122 in**。
- 修法：`plot_w_in = ua_get("Fig1C", "panel_w_in")`；实测常数 4.4122 in 写入 `measured_constants.tsv`（键 `Fig1C/panel_w_in`，来源 = 成品 PDF 面板边框反解 `m2_probe_geom.out`）。**未改任何文字/数字，未改竖向位移量。**
- 结果：框宽 99.85 → **122.199 pt** ≥ 最长行 120.402 pt（余量 0.898 pt/侧）→ **越框 = 0（三处归零）**。
- 如实记录的副作用：框变宽后其左缘由 297.50 → 286.32 pt，遮住 D6 上侧 CI 帽 **5.78 pt**（pre-round1 基线 23.10 pt；位移轮 0.00 pt；D6 数据点本身不再被遮）。该遮盖不在本轮四项硬门槛内（重叠/越框/四边非白/融合仍全 0），但如实报出。

### (xii.4) 补充 PDF 两遍法重建（拾取新 FigS1/S2）

- 源 = `03_tables/Supplementary_Tables.docx`（**未改动**，sha256 `613c23dd…`，624,779 B）；其 `word/media/image1.tiff` / `image2.tiff` 与交付 TIFF `a0b43ab0…` / `92f2f27b…` **逐字节相同**。
- pass1：20 页、anchored **15/15**；docx 目录页码（2,4,5,7,9,10,11,12,13,14,15,16,17,18,19）与 pass1 实际页码 **IDENTICAL**（= 已收敛，故无需重写目录）。
- pass2：同页码表，且两次渲染的 PDF **逐字节相同**（本机 soffice 确定）。
- 交付：`04_supplement/Supplemental_Information.pdf`，**20 页**，1,510,708 B，sha256 `82acb636…`（上一版 `a17d21b9…`，1,510,270 B）。
- 目录页码随条目严格递增 = True；补充 PDF 页序 Figure S1(2) → S2(4) → Table S1(5) … S13(19) 由 G2 独立脚本复核 OK。
- 图页内容为新图：LibreOffice 会把内嵌 TIFF 重编码为 JPEG（不能按字节比），故按内容比对 —— 第 2 页绘制图与 S1 TIFF 相关系数 **0.99980**、第 4 页与 S2 **0.99995**（MAE 0.10 灰度）。

### (xii.5) 重渲染可复现性（交付件 = 当前脚本可复现）

- 用**最终共享** `fig_common.R`（`90af8744…`）重跑 `02_recompute_apobec.R` + `10…70_fig*.R`，再 `99_run_all.R` 全链。
- **7 张 TIFF 全部逐字节相同**（两轮重跑均如此）。
- 7 张 PDF 非逐字节相同（cairo 写入 `/CreationDate`，并连带 `/ID` 与 XRef 流）；但**文本层逐词+坐标+字号全同、矢量层逐条绘图指令全同、@300 dpi 栅格差异像素 = 0**。

### (xii.6) 项目级重叠 QA（`90_qa_overlap.R`，先清空累计 `qa_rows.csv` 以避开并发冲突）

- `QA_figure_check.md`：**总判定 PASS** —— `overlap = 0  clip = 0  squeeze = 0  raster_nonwhite = 0`。
- 逐图 7 行全 PASS（`edge_nonwhite_px = 0` / `modal_colour = 255`）；21 个面板行的 overlap/clip/squeeze 全 0。

### (xii.7) 高亮定稿：Mode C（28.8%）为正式交付

- 正式交付 = **Mode C 实质改动口径**：`HLA_LOH02_revision_MARKED.docx`（67,509 B，`d38c9536…`；174 段 / **589** 高亮 run / 101 段染色 / 19,537 字符 = **28.80%**）与 `HLA_LOH02_revision_CLEAN.docx`（62,888 B，`30851074…`；0 高亮 run，逐段文本与 MARKED 全等）。
- 备选（第三轮**全口径 61.2%**）：`01_manuscript/_alternative/HLA_LOH02_revision_MARKED_full.docx`（68,500 B，`d21308a2…`）/ `_CLEAN_full.docx`（62,888 B，`ab67e443…`）；本轮**未改动**，仅随清单归档。
- `Change_Summary.md` ×2（`01_manuscript/` 与 `05_response/` 同字节 `cef3cdaf…`，118,705 B）。

### (xii.8) 本轮改动 / 新增文件（bytes + sha256）

| 文件 | bytes | sha256 | 说明 |
|---|---:|---|---|
| `02_figures/scripts/10_fig1.R` | 14,244 | `098bfb3432509cf2f916f029b8db7d352de9b86656e7df6832b9334a869d9b01` | 缺陷修复 (b)：`plot_w_in` 5.4 → 实测面板宽 `ua_get("Fig1C","panel_w_in")`；旧 `13fb26be…`（13,695 B） |
| `02_figures/scripts/20_fig2.R` | 12,151 | `7c31079dceabf5f17c3b7f3bf7bd6552727e54c60dad2ca04e7bf720172a7f0e` | 缺陷修复 (a)：过滤前先取 `Proportion mediated` 的 Estimate；旧 `cfaf01d2…`（11,100 B） |
| `02_figures/QC_user_adjust_round1/measured_constants.tsv` | 1,681 | `8b9148b538abc07b46ca2c0b473579204308f0bae7fec73e11335b610234e735` | 新增键 `Fig1C/panel_w_in = 4.4122`（in）；其余键值一字未改 |
| `02_figures/QC_user_adjust_round1/m6_verify.py` | 18,626 | `1697796f43555983149d9db3f93c2fbcac88b99f74a310e5d41aa33596d1443d` | 复测脚本：④ 的参考框由 pre-round1 基线框改为「加宽前 snug 基准框（2 行）」 |
| `02_figures/QC_user_adjust_round1/REPORT_round2_defectfix.md` | 9,611 | `f8ea2ddba9d27f1eebaa7281ab3f6f021075a85f55acab9643478f2de8b8b082` | 本报告 §(xii) 的图件侧原始输出汇编（新增） |
| `02_figures/Figure1_pancancer_and_reliability.tiff` | 605,964 | `4a9bf25ee99a2a092e4c47524fc2fa19b3427cec24518d95407c9441d287703a` | 重出（白底 300 dpi）；旧 `0befdeec…`（605,148 B） |
| `02_figures/Figure1_pancancer_and_reliability.pdf` | 61,869 | `7d736c598299b90a34ee23ed38556f29710b9412ad73896e3cda70ee3643566d` | 重出（矢量）；旧 `ba549b81…`（61,844 B） |
| `02_figures/Figure2_mechanism_armlandscape.tiff` | 327,454 | `8af788faacc687d26531c4144e3a70d86b9f9740a76996afc2550725fe68d9ec` | 重出；旧 `2457009f…`（321,874 B） |
| `02_figures/Figure2_mechanism_armlandscape.pdf` | 58,468 | `70b2b1605b513a0d9339361e0a1d8f9bd9d11ba4e357c6521a8afc89b5a5a0b7` | 重出；旧 `b8217a90…`（58,135 B） |
| `02_figures/QA_figure_check.md` | 19,552 | `9332f835b2750e5c6c1f17727bfb63e693539d3eb6b6daa2c86ce4b2e1b85cf3` | 重生（`90_qa_overlap.R`）；旧 `b14947a7…`（19,539 B） |
| `04_supplement/Supplemental_Information.pdf` | 1,510,708 | `82acb6364f3d4eebbf447b965479e96d79582186f37fb99e53203e373eaed72c` | 两遍法重建；旧 `a17d21b9…`（1,510,270 B） |

> `03_tables/Supplementary_Tables.docx`（`613c23dd…`）、`01_manuscript/*.docx`、`05_response/*`、`03_tables/Table*.docx`、`06_compliance/**`、Fig3/4/5/S1/S2 的 TIFF+PDF **本轮未改动**。

### (xii.9) 门禁重跑（原始输出，`QC/_final_round2/`）

| # | 门禁 | 命令（解释器） | 原始结果 | 退出码 |
|---|---|---|---|---|
| 1 | 锚点 | `05_response/verify_anchors.py`（docxenv） | `anchors: 28   matched in md AND both DOCX: 28   mismatched: 0` | 0 |
| 2 | 残留标记 | `QC/scan_markdown_residue.py`（docxenv） | MARKED/CLEAN `TOTAL residue 0`、`paras 174`、行号域在；`GATE G5 … PASS` | 0 |
| 3 | 图表双向核对 | `QC/g2_independent_crosscheck.py`（pdfenv，含 fitz） | `T1 in-text 23  T2 files 19  T3 …: 0`；`PASS - T3 empty`；补充 PDF 页序 `OK` | 0 |
| 4 | 回复信 | `05_response/verify_response.py`（docxenv） | `[LINE-REF-TBD] in letter 0`、`fabricated 'line N' 0`、`ANCHOR_MAP rows 28`、`'**Anchor:**' 28` | 0 |
| 5 | Mode C 高亮 | `QC/verify_highlight_mode_c.py`（docxenv） | `ASSERT A observed = 0 -> PASS`；`ASSERT B instances = 849 uncovered = 0 -> PASS`；`CLEAN highlight runs 0 -> PASS`；`RESULT: ALL GATES PASS` | 0 |
| 6 | 清单自校验 | `QC/tools/verify_manifest.py` | 见 §(xii.10) | 0 |
| 7 | 仓库 ↔ 存交包 | `revision_2026/code/tools/check_repo_vs_zip.py` | `members: 100   byte-identical to a repository file: 100   mismatches: 0` | 0 |

> 说明：门禁 3 必须在**装了 pymupdf（fitz）**的解释器下运行；用 `docxenv` 运行会打印 `supplement PDF check skipped: No module named 'fitz'` 并把该项记成 1 条差异（非真实差异）。

### (xii.10) 仓库同步、清单与冻结

- `QC/FINAL_MANIFEST.md` 重生（含图件新哈希、Mode C 两份 DOCX、`_alternative` 备选件、`Change_Summary`×2、`QC_user_adjust_round1/` 关键产物）；`verify_manifest.py` 全部行通过。
- 仓库 `revision_2026/code/README_CODE.md` 的图件摘要表更新为新哈希；`revision_2026/code/figures/` 同步本轮脚本（`10…70`、`fig_common.R`、`fig_shift.R`）并新增 `measured_constants.tsv`（第三方重跑否则即 `stop()`）；`revision_2026/data/FINAL_MANIFEST.md` 与 `QC/FINAL_MANIFEST.md` 同字节。
- `PINNED_PACK_CORRECTIONS.md` 的四处副本（`V3/00_pinned/`、仓库 `code/`、仓库 `data/number_dictionary/`、两个存交包内各一）统一为本文件的字节。
- 两个存交包用**外科式重建**（逐成员 raw local record 复制）替换改动成员，其余成员字节不变 → `check_repo_vs_zip.py` **100/100**。

### (xii.11) 未做与已知偏差（如实）

- **未打 git tag**（按用户要求）。
- Fig1C 注释框加宽后遮住 D6 上侧 CI 帽 5.78 pt（§(xii.3b)）——四项硬门槛不受影响，如实报出。
- 补充 PDF 的两遍法在本轮表现为「源 docx 目录页码已 = 实际页码」，故**未重写 docx**（保持其字节不变）；两遍渲染的页码表与 PDF 字节均一致。
- 四张本应交由第三方复算的输入（`msk_impact_50k_2026/*.txt` 等）不在包内，重跑 `00_recompute_inputs.R` 不可行；本轮可复现性证明的是**从现有中间结果到交付图件**这一段。
