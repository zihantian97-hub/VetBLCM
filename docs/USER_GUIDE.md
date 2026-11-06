# 使用指南 / User guide


从 0.1.9 起，纯解释性说明优先收纳在小型“？”帮助图标中，悬停或键盘聚焦时显示，以减少页面长期文字占用；错误、警告和审阅提示仍常显。`载入模拟示例` 会填满所有可预填研究字段，但不会自动勾选人工审阅确认，也不会伪造尚未运行模型才能产生的结果。模拟内容均明确标记为示例，不得作为真实病原研究依据。

From 0.1.9, purely explanatory prose is preferentially placed in compact `?` help tips shown on hover/focus to reduce persistent visual clutter; errors, warnings and review advisories remain visible. `Load simulated example` fills every prefillable study field, but does not auto-check manual review confirmations or fabricate fit-dependent results. All simulated content remains explicitly labelled and must not be used as evidence for real-pathogen inference.

## Navigation and validation / 导航与验证

从 0.1.8 起，页面验证主要用于提示而不是锁死流程。缺少说明字段、未完成审阅确认、先验来源/适用性记录不完整、MCMC诊断未达目标等会继续以红色或黄色显示，但“下一步”原则上仍可使用。只有技术上无法继续时才阻断，例如没有成功导入并解析有效数据、必要的数据/先验对象尚不存在，或结果/诊断/敏感性/论文输出页面没有任何成功拟合结果。红色提示不等于结果无效，也不等于可以忽略；正式解释和导出前仍应逐项审阅和记录。侧栏可直接查看任意页面。

From 0.1.8, page validation is primarily advisory rather than a navigation lock. Missing narrative fields, unchecked review acknowledgements, incomplete prior provenance/applicability records, and unmet MCMC diagnostic targets remain visible as red/yellow advisories, while Next generally remains available. Progression is blocked only when continuation is technically impossible, such as no successfully parsed valid data, missing essential data/prior objects, or no fitted result on result-dependent pages. A red advisory is neither proof of invalidity nor permission to ignore the issue; it should be addressed and documented before final interpretation/export. Sidebar pages may be viewed directly.


## 中文

### 1. 先确定要估计的状态

Gold standard是能可靠判定目标状态的参考方法。对照检测不完美时，不能把T2阳性、阴性直接当作真实感染和未感染。先填写目标群体、来源群体、分析单位、检测用途，以及“潜在感染/目标状态”的定义。核酸检出与真实感染的对应关系须由研究者根据研究目的解释，软件不会确认每个个体感染。

DSe=P(检测阳性|真实目标状态阳性)，DSp=P(检测阴性|真实目标状态阴性)。BLCM用多个不完美检测的联合结果和明确假设，对这些参数及患病率进行推断。能够计算后验不代表所有参数都可由数据识别。

### 2. 准备数据

在导入0/1结果前，先记录 T1 和 T2 的预先判阳规则，包括 qPCR 的 Ct/曲线/重复孔判定规则（如适用），并明确 equivocal、invalid 和 missing 如何处理。软件只接受最终二元编码，不会根据 Ct 自动把样品判成阳性或阴性。论文输出会原样保留这些判定规则。

导入后填写“进入筛选的样本总数”“排除数量及原因”和“样本量确定依据”。进入筛选总数不能小于最终进入 BLCM 的样本数。若无排除也必须明确记录“无”，而不是留空。软件据此生成样本纳入流程图；它不会猜测研究者没有提供的排除原因。

逐样品表以Sample_ID、Population、T1、T2为核心列；T1/T2使用数字0和1。ID应保持文本格式以保留前导零。同一ID重复、缺失或不确定检测结果会阻止进入模型。软件不自动删除样品，也不把不确定结果改为阴性。无效结果的处理规则须在研究方案中事先规定。

直接四格表使用Population,n11,n10,n01,n00，分别对应++、+-、-+、--，频数必须是非负整数，每群体样本量>0。每个分析物单独导入，支持任意数量J≥2的群体。增加群体请在数据中增加相应Population记录，再填写定义；底层模型不固定Low/Medium/High。

不同样品类型原则上分别评价。Herd_ID用于检查聚集；空白表示未知，不表示无聚集。Ct列仅用于不一致样品的描述性复核，不能仅据Ct推断抑制、检出限或不一致原因。

### 3. 定义群体

第4页优先使用“选择范围 + 必要时自定义”的群体向导。先选择 Population，再选择分组依据（综合流行病学风险、地区/来源、临床/繁殖史、既往监测/感染史、暴露/生物安全、生产管理、时间/监测批次或其他）、具体分组标准、预期风险层级和证据来源。软件可根据风险层级生成默认 Rationale，但它只说明“为什么预期患病率存在差异”，不会替代真实 Definition。若选择的分组标准仍需要具体阈值、地区、时间窗或文献来源，必须补充后才能通过质量门。

分组须依据当前检测结果以外的信息，不能按T1/T2阳性率反过来划分高低风险组。默认 Rationale 不会对 DSe/DSp 或患病率强制排序，只记录预期风险差异。勾选独立分组确认，并回答群体间样品和程序是否可比。基础模型假定DSe、DSp和条件协方差在群体间恒定。

### 4. 填写先验

选择参数后，用Mean+ESS或Alpha+Beta输入，点击保存。预览图和统计量显示实际分布。ESS在本软件指alpha+beta，与MCMC有效样本量不同。默认Beta(1,1)仅表示明确标记的弱先验，不代表任何病原的已知性能。

每项信息先验记录引用、原估计、不确定性、来源群体、样品、检测方法、ESS折扣依据及适用理由。无来源的判断应标记为subjective/expert，不能伪称文献证据。不能用本次T1/T2数据反过来构造先验。外部调查的表观阳性率x/n也不自动等于真实患病率。

Lower/Upper是可选的显式截断。Beta(1,1)截断为0.5–1后，实际均值是0.75，而不是0.5。限制DSe与DSp都>0.5强于只要求Youden指数为正，可能排除某些合理的筛查检测；必须给出理由。默认不施加患病率顺序约束。

uD/uH表示协方差在当前边界中的位置。正依赖下0表示独立；有符号模型下独立的位置随敏感度、特异度而变。它们不是Pearson相关系数。CovD/CovH的先验由准确度和u联合产生，叠加图据此模拟。密度线为平滑显示，边界附近可能存在平滑偏差；实际分布以先验表中的参数和截断为准，可信区间直接从样本计算。

### 5. 运行和诊断

先Preview检查流程，再使用Final进行充分计算。默认四条链、thin=1。适应、预热和采样长度可调整，没有固定迭代数可以保证收敛。运行两种主模型时，界面分别拟合独立与正依赖模型。

R-hat应<1.01；bulk/tail ESS目标至少为每条链100。必须同时检查所有关键参数的trace、density、autocorrelation、相关矩阵、边界行为、先验后验对比和患病率区分。低R-hat不能发现所有多峰，也不能证明识别性。边界比例和相关系数阈值仅为软件筛查提示。

PPC把观察四格频数与后验模拟频数比较。图中的预测区间考虑了参数不确定性。良好PPC只说明模型能再现所检查的数据特征，不能证明潜在状态含义正确。

### 6. 敏感性与审阅

主模型拟合完成后，Main 先验被冻结。第10页直接上传一份 Alternative 先验 Excel/CSV，软件先按当前群体和模型验证参数完整性、与 Main 的差异、Rationale 和文献/外部数据 Source，再将其加入情景；不需要也不应返回第5页覆盖 Main 先验。Weak 情景由软件从 Main 自动生成。至少运行 Weak 和一个有科学依据的非弱 Alternative，并比较中位数变化、95% CrI 宽度及诊断变化。

敏感性情景“完成计算但 MCMC 诊断未达标”不是页面未完成：该情景保留并标为重要警告，可用于说明弱识别或先验依赖，但其参数估计不能作为有效 DSe/DSp 推断。用户必须勾选已审阅这些失败情景后才能继续。只有情景文件/先验无效、Weak/Alternative 缺失或计算本身报错时才硬性阻断。软件不会因为 Main 与 Alternative 接近就自动称结果 robust。

在Diagnostics中记录人工审阅，在Results中查看所有未满足检查项。两个依赖检测的结构不可识别性始终保留；≥3群体仅是设计审阅要求。少于三个群体的专家覆盖必须记录理由和信息先验依据，不能把勾选当作数学证明。

### 7. 论文输出

当前单病原分析完成后，软件自动计算 T1 与 T2 的配对后验差值：Delta DSe 和 Delta DSp，并给出后验中位数、95% CrI 和 Pr(T1>T2)。这些量从同一后验抽样逐次相减得到，不能解释为传统显著性检验的 P 值。

STARD-BLCM 报告审计用于检查研究设计、样本流程、判定规则、先验、条件依赖、MCMC/PPC、结果和敏感性分析是否有可追溯记录。该表是软件映射辅助，不是官方清单的逐字复制。

每个单病原 run 保存标准化 `analysis_summary.csv/json`。多个病原继续分别拟合；VetBLCM不再扫描历史run或自动生成多病原综合图。若需要多病原展示，可在外部软件中使用各单病原summary自行汇总，不估计“8-plex总体DSe/DSp”，也不进行跨病原Meta分析。

### 8. 保存与导出

优先使用“保存完整分析到本地”。该按钮由 R 直接写入指定结果根目录，不经过浏览器下载。每次保存建立独立的 `<项目名称>/run_<Analysis_ID>/`，不会覆盖旧分析。目录中包含实际模型代码、数据、先验、设置、版本、种子、初始值、数据/模型哈希、后验 draws、已运行的模型比较与敏感性情景、Excel、图形、双语 HTML、RDS、相对路径哈希清单以及完整 ZIP。Windows 可用原生文件夹选择器和“打开最近保存目录”；其他系统可直接填写路径。

网页下载仍保留为备用，而且只有在当前会话存在有效拟合结果时才显示。项目 JSON 仅保存配置与摘要，恢复后必须重新拟合；不要把项目 JSON 当作实际 posterior 的备份。

语言切换只改变显示，不改数据或已运行模型。已有结果使用运行时冻结的信息；改变科学输入后应重新运行。完整实际分析应保存本地 run 目录或其完整 ZIP/RDS。HTML 顶部可切换中文和 English，离线可读。数值表内部为比例单位，文字默认显示一位小数百分比。

## English

Define the target condition, source/target populations, analytical unit and assay purpose before fitting. An imperfect T2 comparator cannot define truth. DSe and DSp refer to the latent condition under stated assumptions; the app does not establish individual infection status.

Import one analyte at a time. Sample files require unique Sample_ID, Population and binary T1/T2. Aggregated files require Population,n11,n10,n01,n00 in ++,+-,-+,-- order. Missing/equivocal results and duplicate IDs are rejected without silent deletion. Keep specimen types separate. Herd IDs identify possible clustering; the basic likelihood does not adjust for it. Ct is descriptive only.

Define populations independently of current results. Document definitions, epidemiological rationale and prior source. The model assumes constant test accuracy and conditional covariance across populations. More groups do not by themselves identify a two-test dependent model.

Enter prior mean and ESS, or Beta shapes, and save each parameter. Prior ESS means alpha+beta. Document external information and applicability. Weak Beta(1,1) priors are not pathogen-specific evidence. Explicit truncation changes the distribution and must be justified. Do not reuse current observations as priors or automatically turn external apparent prevalence into true-prevalence priors.

Use Preview for workflow checks and Final for longer computation. Inspect every parameter's trace, density, autocorrelation, R-hat, bulk/tail ESS, prior/posterior overlay and correlations. Examine predictive checks and the scientific meaning of the latent classes. Diagnostics are necessary but cannot prove identification, exclude all multimodality or certify the study.

Refit the independent and positive-dependence primary models. After the main fit, keep Main priors frozen. On Page 10 upload a separately justified Alternative prior file directly, validate it against the current populations/model, and add it as a scenario; generate Weak from Main. Run at least Weak and one non-weak Alternative. A sensitivity scenario that completes but fails MCMC diagnostic targets is retained as warning-level evidence of prior sensitivity/weak identification, not as valid parameter inference; explicit review acknowledgement is required. Invalid/missing scenarios or computational failures remain hard blockers. Advanced signed dependence is especially sensitive to feasible-support and prior assumptions; inspect the pilot validation results before use.

Record prespecified T1/T2 positivity rules and the handling of equivocal, invalid and missing results before final analysis. Record total samples assessed, exclusions/reasons and the sample-size rationale. Publication outputs include a sample-flow diagram, paired posterior contrasts (Delta DSe/Delta DSp with 95% CrI and Pr[T1>T2]), and a STARD-BLCM reporting audit. Each analyte remains a separate BLCM. The app no longer scans historical runs or creates project-level multi-analyte tables/forest plots; complete exports provide standardized single-analyte summary.csv/json files for optional aggregation in external software.

Set the results root on Page 1, then prefer **Save complete analysis locally**. R writes the current fit to `root/YYYY-MM-DD/run_HHMMSS_analyte_analysisID/` directly to the filesystem, without browser download transfer. Different model runs have different run folders; re-saving the same fit refreshes its existing run folder. It contains the actual draws, settings, models, Excel/HTML outputs, figures, a relative-path hash manifest and a complete ZIP. Browser downloads remain a fallback and are shown only when a fitted result exists. Project JSON retains configuration and saved summaries but not posterior draws; refit after restoration. The reporting checklist is a review aid, not automatic approval for publication.

Density curves are smoothed displays of samples and can show boundary bias. Read the recorded Beta parameters and truncation bounds for the actual prior; credible intervals use posterior draws directly. Record the source assay, specimen, original estimate, uncertainty, source population, applicability and ESS discount rationale for every informative prior.


## Guided-entry presets (0.1.5)

Where a common scientifically neutral recording pattern exists, VetBLCM now offers a preset that writes into the same editable metadata field used in reports. A preset is not evidence and does not change the statistical model. Exact Ct cutoffs, replicate criteria, reproducible population definitions and evidence citations remain study-specific. Templates containing explicit placeholders cannot pass the workflow gate until completed.

On the population page, the guided editor separates: (1) **Definition basis** — how membership is operationally defined; (2) **Expected prevalence level** — descriptive lower/intermediate/higher/unspecified, with no model ordering constraint; (3) **Rationale** — why true prevalence may differ independently of current T1/T2 results; and (4) **Prior_source** — the external or prespecified basis for the risk stratification, distinct from the Se/Sp prior table on the next page.
