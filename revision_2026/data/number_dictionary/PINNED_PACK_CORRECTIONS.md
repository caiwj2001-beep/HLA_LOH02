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
