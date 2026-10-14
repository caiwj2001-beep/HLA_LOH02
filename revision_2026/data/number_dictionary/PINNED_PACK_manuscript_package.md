# 【锁定决策包 · PINNED PACK】HLA_LOH02 → iScience 修回（V3）

**本文件是 V3 全部交付物的唯一事实源。任何子任务不得偏离此处的数字、口径与禁令。**
稿号 ISCIENCE-D-26-09416｜修回截止 **2026-11-10（不申请延期）**｜产出根目录 `C:\Users\Administrator\科研文件\HLA_LOH02\iscience投稿版本\V3`

---

## 0. 三条铁律

1. **数字只能来自本文件或指定的磁盘产物**；不得编造、不得"约等于"、不得用记忆里的旧稿数字。
2. **主张不得超出数据**：禁用"immune editing 驱动""独立预后""APOBEC 机制""剂量依赖""局灶/拷贝中性机制""HR<1=保护"。
3. **每一项交付物完成后必须自检并把原始输出贴进回复**（`ls -la`、行数/条数、抽查数字），未自检不得声称完成。

---

## 1. 新叙事（贯穿全文）

**一句话**：HLA 类 I 杂合性缺失（HLA LOH）的**计数**受调用可靠性支配，其**关联**受全局非整倍体支配。

**四条主张（可写进摘要/Highlights/讨论）**
1. 泛癌等位特异性 HLA LOH 图谱：25.3%（7,554/29,799），谱系间 4 倍以上差异；**有 6p 臂佐证的高可信度频率仅 14.0%**。
2. HLA LOH 与**全局非整倍体**强关联（ρ=0.331；每 SD OR 3.106），并且**其"臂独立"部分随肿瘤纯度剧变**（纯度十分位 60.3%→11.3%）——等位特异性调用**受纯度/覆盖限制**。
3. TMB 关联在校正非整倍体后**衰减但存活**（OR 1.568→1.238/1.250/1.256；最高非整倍体层内失效）；**6p 在 41 条臂中并非与 TMB 最相关的臂（排 26/41，17p 第一）**。
4. 新抗原：负荷与 HLA LOH 呈**弱正相关**（OR 1.064/SD，HC3 P=0.0045），与 TMB 高度共线（ρ=0.705）、**克隆限制下消失**（OR 1.013, P=0.52）；**等位基因配对检验阴性**（OR 1.008, P=0.33）→ **不主张免疫编辑驱动**。

**明确的撤回清单（正文须体现，回复信须主动列出）**
- 撤回：APOBEC/吸烟的机制性解释（实为突变丰度伪影：APOBEC 1.035 ≡ smoking 1.035）。
- 撤回：HLA LOH 的"独立预后"（校正非整倍体后 1.062→0.938–0.952；不得解读为保护）。
- 撤回：受累位点数的"剂量依赖"（**Kaplan–Meier 中位 OS，主队列 `analysis_primary=TRUE`，OS 非缺失**：49.1→39.8→32.6→**37.6**，仅 burden=2 显著）。
- 撤回：胚系合子性"约束进化压力"（纯合位点 0% 可评估＝同义反复）→ 改为方法学陈述。
- 撤回：28.3% 臂独立型＝"局灶/拷贝中性"（82.7% 无法判别机制）→ 改为"不伴 6p 臂丢失、机制多不可判"。

---

## 2. 数字字典（LOCKED NUMBERS）

### 2.1 队列与图谱
| 指标 | 值 |
|---|---|
| 肿瘤/患者 | 54,331 / 48,179 |
| HLA-LOH 可评估（一患者一瘤） | 29,799 |
| 任何 HLA LOH | 7,554 = **25.3%**（95%CI 24.9–25.8） |
| pan-HLA LOH（三位点全丢） | 3,107（10.4%） |
| 谱系（≥100 例，29 种） | 宫颈 40.2／生殖细胞 39.3／食管胃 38.0／头颈 37.6／卵巢 37.3 … 前列腺 11.1／胶质瘤 11.9／GIST 9.6；**NSCLC 29.8** |
| 原发 vs 转移 | OR 0.81（原发），P=1.6e-12（转移富集） |
| **6p 臂可判读子集** | 5,805；臂依赖型 **4,161（=队列 14.0%）**；臂独立型 **1,644（占可判读者 28.32%）**；6p 不可判读 1,749 |
| 臂独立型机制判别 | 局灶缺失 14.2%／拷贝中性 3.0%／**无法判别 82.7%**；HLA-A/B/C 基因水平 CN **99.86% 为"0"** |

### 2.2 调用可靠性（V2/r3p4）
| 指标 | 值 |
|---|---|
| 臂独立型占比 × 纯度十分位 | **60.3% → 11.3%**（trend P=1.8e-108） |
| 纯度每 −10% | **OR 1.56 (1.50–1.62)**，P=3.3e-98 |
| 覆盖每 +100× | OR 0.77 (0.74–0.80)，P=3.2e-42 |
| IMPACT505 vs 410 | OR 0.30 (0.23–0.40) |
| 三组纯度中位（臂独立/臂依赖/无 LOH） | 34 / 48 / 46；WGD 14.1% / 54.2% / 23.0% |

### 2.3 非整倍体与 TMB（V2/r3p2、r3p3）
| 指标 | 值 |
|---|---|
| HLA LOH ↔ 非整倍体评分 | ρ **0.331**（排 6 臂 0.312）；每 SD OR 2.155（校正 3.106）；排 6 臂 2.055 |
| 非整倍体自身预后 | HR **2.686 (2.421–2.981)** |
| WGD | 43.7% vs 23.1%；远端 OR **2.30 (2.16–2.43)**，P<0.001 |
| 中介分析 | ACME **0.263 (0.253–0.270)**；ADE −0.089；比例 1.51 |
| 6p 臂丢失 | OR 18.5 (17.16–19.90)（**近乎定义性，不作亮点**） |
| TMB–LOH 校正非整倍体 | **1.568 → 1.238（含6p）/1.250（排6p）/1.256（排6q）**，P=3.5e-08/7.4e-09/3.0e-09；分层：Q1 1.710→Q2 1.187→**Q3 1.104（P=0.0995，失效）** |
| TMB 中位 | 4.4 vs 3.5；TMB-high OR 1.50；11/29 癌种 FDR<0.05 |
| **臂与 TMB 关联排名** | **6p = 26/41**；第 1 位 17p（β=0.079, P=1.67e-89） |

### 2.4 突变签名（V2）
APOBEC 校正 OR **1.035 (1.004–1.067)** P=0.026 FDR 0.078；smoking **1.035 (1.005–1.066)** P=0.020 FDR 0.078；六签名互校两者均 **1.041**，FDR **0.041**；MMR 反向（原稿 FDR 2.0e-3）；HRD/UV/aging 全阴。
APOBEC >0.90：**intact 0.43%（95）vs LOH 0.27%（20）**，Fisher **P=0.053**；≥0.50：4.98% vs **5.88%**（P=0.0026，方向反转）。

### 2.5 生存（V2/r3p2）
n **27,368**，死亡 **10,101**：未校正 HR 1.212 (1.161–1.266)；校正 **1.062 (1.015–1.112)** P=0.0095；+非整倍体 **0.938 (0.895–0.984)**；排 6p **0.946**（原记 0.947，按源值 0.9464618 修正，见 `PINNED_PACK_CORRECTIONS.md` (i)）；排 6p6q **0.952**。
五癌种（+非整倍体）：前列腺 **1.262 (P=0.069)**；RCC **1.386 (1.018–1.886, P=0.038, BH-FDR 0.146)**；膀胱 1.157 (P=0.227)；NSCLC 1.079 (P=0.172)；乳腺 **0.875 (P=0.088)**。
burden 0/1/2/3 中位 OS（**Kaplan–Meier 中位，主队列 `analysis_primary=TRUE`、`OS_MONTHS` 非缺失；分层 n = 20,590 / 2,327 / 1,788 / 2,898，事件 7,448 / 940 / 757 / 1,161**）**49.1 / 39.8 / 32.6 / 37.6**；仅 burden=2 显著 **1.141 (1.056–1.233), P=8.1e-4** → +非整倍体 **0.993 (P=0.87)**；burden=3 1.028 (P=0.396)。

### 2.6 胚系（方法学口径）
纯合位点可评估率 **0%**（HLA-A 5,233 / B 3,125 / C 4,400 无一例调用）；杂合位点约 **60%**；LOH 频率 26.2%（0 个纯合）/22.1%（1）/19.3%（2）；校正 OR 0.79 (0.75–0.84) → **作为"可评估底物上限"的方法学陈述**。

### 2.7 新抗原（netMHCpan-4.2e 全队列，V3 主工具）
输入：26,092 例、**191 alleles**、**15,518,931 个 (allele, peptide) 对**；逐 allele 输出行数==输入行数（**零丢行**）；panel 中位 **1.14 Mb**；每样本中位 **5 个编码突变**。
**(A) 负荷 ~ HLA LOH**（n=25,954，LOH+ 6,804）：计数 **OR 1.064 (1.020–1.110)** P=0.0043（**HC3 P=0.0045**）；IC50 定义 1.060 (1.022–1.100) P=0.0018；每 Mb 1.062 P=0.0054；每突变 **1.065 (1.032–1.099)** P=7.4e-05；不含 panel 项 1.0674 (1.0229–1.1139) P=0.0027；ρ(TMB)=**0.705**；中位新抗原数（**HLA-intact 6 vs HLA-LOH 7**；源表 `A2_outcome_models.tsv`、`fig4c_neo_summary.tsv`）；OLS 倍数 1.037 (1.018–1.056) P=1.0e-04；**限克隆 OR 1.013 (0.972–1.057) P=0.52**；非整倍体三分位 1.057/1.071/**1.087（仅 T3 P=0.012）**。
**(B) 等位基因配对**（6,817 例 / 14,157 对；剔纯合位点 1,305）：全位点 **OR 1.0078 (0.9922–1.0237) P=0.330**；A 1.016 (0.990–1.043) P=0.225；B 1.003 P=0.843；C 1.003 P=0.812；纯度≥50% 1.019 (0.996–1.044) P=0.112；**限克隆 1.024 (1.004–1.045) P=0.016**；6p 臂丢失型 1.003 (0.982–1.024) P=0.781；符号检验 P=0.247；**剔除 ties 后占比 0.506 / 0.518**。

### 2.8 其他（用于 R1 专段）
RCC **24.3%（198/815）**，其 TMB–LOH **P=0.471**、WGD **16.2%**；结直肠 **30.8%（880/2,859）**。
SV：15,811 条基因水平重排调用 / 12,502 样本（23.0%），中位 1 条/样本（最多 6）：DELETION 6,225 / INVERSION 3,738 / TRANSLOCATION 3,644 / DUPLICATION 2,203 / INSERTION 1。

### 2.9 数据与文献
cBioPortal `msk_impact_50k_2026`（Bandlamudi et al., *Cancer Cell* 2026, PMID 41895280），**CC BY-NC-ND 4.0（原始数据不可再分发）**。

---

## 3. 图结构（原 6 图 → **5 主图 + Supp Fig S1 + Supp Fig S2**）

> **更正（本轮同步）**：本节的表原列 6 个条目（Fig 1–5 + Supp Fig S1）。`02_figures/` 内实际有 **7 个图件**，
> 其中 **Supp Fig S2（APOBEC 尾部：intact vs LOH）已于本轮正式纳入引用**（R3-minor-1 的正面回答）。
> 因此图结构应读作 **5 主图 + Supp Fig S1 + Supp Fig S2**；逐项落地动作与数字来源见
> `PINNED_PACK_CORRECTIONS.md` (ii) 与 `01_manuscript/11b_FigS2_addition_note.md`。
> 补充材料条目数 **14 → 15**（Fig S1、Fig S2 + Table S1–S13）。
>
> **图号重编（2026-10-15）**：本节图号已按**正文首现顺序**重编，见 `PINNED_PACK_CORRECTIONS.md` **§(v)**
> （Table 3↔2 即 Figure 3↔2、Fig S2↔S1；本表下方各行的图号仍写旧制，仅作历史对照）。

| 图 | 内容（面板） | 状态 |
|---|---|---|
| **Fig 1** | A 29 癌种 any-HLA-LOH 频率 + Wilson CI + 25.3% 虚线；B HLA-A/B/C 分位点；**C 新增：臂独立型占比 × 纯度十分位（60.3%→11.3%）并标注"有 6p 佐证的高可信度频率 14.0%"** | 重绘 + 新增面板 |
| **Fig 2** | A TMB 分布（LOH vs intact）；**B 改为 log2 倍数变化（按癌种，标 FDR）**；**C 新增：TMB–LOH 的 OR 森林图（未校正 / +非整倍体含6p / 排6p / 排6q）+ 非整倍体三分位分层** | 重绘 + 新增面板 |
| **Fig 3** | A 驱动因素森林图（远端/近端，含非整倍体项）；B WGD→6p 中介（ACME/ADE）；**C 新增：41 条臂 × TMB 关联排名全景，6p 高亮（第 26 位）、17p 标第 1** | 重绘 + 新增面板 |
| **Fig 4** | **全新：新抗原**。A 负荷–LOH OR（各定义 + 敏感性，含限克隆）；B 等位基因配对 OR（全位点 + A/B/C + 敏感性）；C 剔除 ties 后占比（0.506/0.518）与中位新抗原数 6 vs 7 | 全新 |
| **Fig 5** | A 各癌种 HR 森林（非整倍体校正前后并列）；B 泛癌 HR 校正前后 + 明确注明"过度校正，不得解读为保护" | 降级改写 |
| **Supp Fig S1** | 胚系合子性与可评估性（纯合 0%） | 由原 Fig 6 降级 |

**绘图规范**：R + ggplot2；TIFF ≥300 dpi（**必须 `bg='white'`**，否则黑底）与 PDF 各一份；面板字母/图例/n/P 值齐全；**必须用程序化检测标签重叠与裁切**（用 `fig_helpers.R`：框宽 `strwidth` 计算、`flow_layout` 排位、`detect_overlap` 检测），不得手填坐标。

---

## 4. 交付物与目录（V3）

```
V3/
├── 00_pinned/            本文件 + 数字字典.tsv
├── 01_manuscript/        *_clean.docx（无高亮）、*_marked.docx（行号+黄色高亮改动）、分节 md + 图注
├── 02_figures/           Fig1–5 + FigS1（TIFF 300dpi + PDF）+ 绘图脚本
├── 03_tables/            Table1–3 + Supplementary Tables（含新增新抗原表）DOCX
├── 04_supplement/        Supplemental_Information.pdf（单一 PDF）
├── 05_response/          Response_to_Reviewers.docx（R1→R2→R3→编辑，含 4 个问答板块）
├── 06_compliance/        Key_Resources_Table、Data&Code Availability（含 DOI）、Highlights、GA、AI 披露
├── 07_cover/             Cover letter（修回版）
└── QC/                   各门禁日志 + quality_gates_log.md
```

---

## 5. 形式与合规（逐项必须满足）

1. 回复信：**逐条**、含每位审稿人 "Reviewer's Responses to Questions" 四板块 + "Comments to author"；先 R1→R2→R3；每条三段式（原话引用 → 我们做了什么（给数字） → 正文改动（给行号））；开头即承认 R3 部分批评成立并列出撤回项。
2. 修订稿：**行号（Word 行号域 `w:lnNumType`）+ 全部改动黄色高亮**（新增/修改的图、面板、引用、文字）。
3. **STAR Methods** 保持，并补 **Key Resources Table**（现缺）；STAR Methods 内不放编号图表。
4. 数据/代码：**代码与衍生数据同存于一个公开仓库**（`https://github.com/caiwj2001-beep/HLA_LOH02`，URL 已确为事实），**并归档为单个 Zenodo DOI**（`[DOI-PENDING-ZENODO]`，待用户在 Zenodo 开启后回填；不得编造 DOI）；原始数据只给 cBioPortal accession（许可限制，不可再分发）；逐样本中间文件不分发（可由 cBioPortal 重建）。代码许可 MIT，衍生数据许可 CC BY-NC-ND 4.0。
5. 补充材料：**单一 Supplemental PDF**，编号连续且与正文双向对应。
6. Highlights：**3–4 条、每条 ≤85 字符**；GA：≥1200×1200 px、避免缩写；两者按 §1 新叙事。
7. 作者块不变（8 位作者，Lumao Huang 通讯 + Lead Contact）→ 无需 authorship change form。
8. 新增文献（R1 建议 + R3 点名）必须**逐条 PubMed 核验**（作者/标题/年份/卷期页/PMID），不得沿用记忆或二手信息：
   Marincola 1994 J Immunol 153:1225-1237｜Jimenez 1999 Int J Cancer 83:91-97｜Saenz-Lopez 2010 Tissue Antigens 75:110-118｜Maleno 2004 Int J Cancer 109:636-638｜Maleno 2004 Immunogenetics 56:244-253｜Cabrera 2003 Cancer Immunol Immunother 52:1-9｜Garrido 2010 Int J Cancer 127:249-256｜Davoli 2017 Science 355:eaaf8399｜Haradhvala 2017 Cell（R3 引用）。

---

## 6. AI 使用声明（定稿，逐字使用）

> During the preparation of this work, the authors used Grok (Grok 4.6, xAI; https://grok.com) to assist with code drafting and to polish the language and improve readability of the manuscript. The model name is Grok, version 4.6, developed by xAI. Under the authors' direction, the model was used to draft and refactor the R analysis scripts and to edit the text; all analyses, statistics, and conclusions were independently verified and reproduced by the authors, who take full responsibility for the content and accuracy of the work. No generative AI was used to create or alter any images or figures. Generative AI technology was not used as an author of this manuscript.

---

## 7. 质控门禁（每道必须留日志，退出码/结论写入 `V3/QC/quality_gates_log.md`）

| 门 | 内容 | 通过标准 |
|---|---|---|
| G1 数字一致性 | 正文/图表/表格中每个数字 vs §2 数字字典 vs 磁盘产物 | 逐项一致，0 处不符 |
| G2 图表编号与引用双向核对 | 所有正文引用的图表存在；所有已生成图表被正文引用≥1 次；编号按首现顺序连续 | 0 孤儿、0 空指向、0 跳号 |
| G3 图质量 | 程序化检测标签重叠/裁切；300 dpi；白底；面板字母齐全 | 0 overlap、0 clip |
| G4 引文核验 | 每条参考文献 PubMed 核验（作者/标题/年/卷期页/PMID）；正文引用编号按首现顺序 | 100% 可核验、编号单调递增 |
| G5 DOCX 渲染 QA | 行号存在；黄色高亮仅覆盖改动；**扫描全部段落与表格单元格**无残留 markdown 标记（`*`/`**`/`#`） | 0 残留 |
| G6 主张边界 | 全文无 §0 禁令中的表述 | 0 命中 |
| G7 pre-submission QA | 跑 `pre-submission-qa` 四门禁 | 退出码 0 |
