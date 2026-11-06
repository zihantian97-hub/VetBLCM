# VetBLCM

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24002146.svg)](https://doi.org/10.5281/zenodo.24002146)

Archived release: [Version 1.0.0](https://github.com/zihantian97-hub/VetBLCM/releases/tag/v1.0.0) · [Zenodo record](https://zenodo.org/records/24002146). The DOI identifies the fixed release; the main branch may receive documentation updates.

Bayesian Latent Class Analysis for Veterinary Diagnostic Test Validation

本地 R + Shiny + JAGS 软件，支持中英文界面和可切换语言的 HTML 报告。用于无完美金标准情况下，两种检测在多个群体中的诊断评价。每个分析物分别估计，数据不会发送到云端。

Local R + Shiny + JAGS software with switchable Chinese/English UI and HTML reports. Each analyte is analysed separately. No study data are sent to a cloud service.

**Version 1.0.0** · Authors: Tian Zihan; Aizhen Guo; Yingyu Chen · License: MIT

本版本将既有 0.1.10 代码整理为公开存档版本 1.0.0；R、Shiny 和 JAGS 模型源码未变更。包含完整应用源码、运行说明、依赖锁文件、模拟输入和自动化测试；不含论文实测数据、已保存后验抽样或历史生成报告。复现论文数值结果还需相应研究数据、先验、群体定义及运行配置。

This public archival release packages the existing 0.1.10 implementation as version 1.0.0. The R/Shiny and JAGS model sources are unchanged. It includes application source, instructions, the dependency lock file, simulated inputs and automated tests. Empirical study data, saved posterior draws and historical generated reports are not included. Reproducing a study's numerical results additionally requires its data, priors, population definitions and run configuration.

See [REPRODUCIBILITY.md](REPRODUCIBILITY.md), [CHANGELOG.md](CHANGELOG.md), and [CITATION.cff](CITATION.cff). Historical version numbers in source comments and dated audit documents describe the implementation's provenance.

## 启动 / Start

Windows 日常使用：**双击 `VetBLCM.exe`**。正常情况下只会出现一个独立的 VetBLCM 应用窗口，不显示浏览器地址栏或标签页。启动器会自动：

1. 从 PATH 或 R 官方注册表项寻找 `Rscript.exe`；
2. 在空闲的 localhost 端口静默启动 R/Shiny/JAGS；
3. 使用本机 Microsoft Edge（优先）或 Google Chrome 的 App 模式作为界面渲染器；
4. 关闭 VetBLCM 窗口后自动停止对应 R 后端。

`VetBLCM.exe` 本身不包含 R 或 JAGS，因此电脑仍需先安装 R 4.4+、JAGS 4.x 及项目依赖。Edge/Chrome 只作为本地渲染引擎；核心计算和“保存完整分析到本地”均由 R 完成。

若桌面壳在某台电脑上不能启动，可使用兼容启动方式 `launch_app.bat`，或运行：

```powershell
.\launch_app.ps1 -Port 7828
# 如需明确指定R路径 / Specify an R installation:
.\launch_app.ps1 -RscriptPath 'C:\Program Files\R\R-4.4.1\bin\Rscript.exe'
```

RStudio：打开项目目录后运行：

```r
shiny::runApp(".", host = "127.0.0.1")
```

当前验证环境 / Tested environment: R 4.4.1, JAGS 4.3.1, rjags 4-16, posterior 1.6.1. Exact dependencies are recorded in `renv.lock`. JAGS is separate from the R package rjags.

在新电脑安装时，需要先安装 R 和 [JAGS 4.x](https://mcmc-jags.sourceforge.io/)，再在项目目录执行 `source("scripts/setup.R")`。`renv::restore()` 从锁文件恢复 R 包。首次安装需要网络；正常分析离线运行。旧版本包在 CRAN 不再提供匹配的 Windows 二进制时，可能需要对应 Rtools。不得把未运行过的环境称为已验证环境。

## 工作流程 / Workflow

1. 填写研究和目标状态定义 / Enter study metadata and define the latent target condition.
2. 导入逐样品 Excel/CSV 或分群体四格表 / Import sample data or grouped counts.
3. 检查编码、重复、缺失、零格、群内聚集和样品类型 / Review QC and design.
4. 记录群体定义和独立来源的先验 / Document populations and independently sourced priors.
5. 运行独立与正依赖主模型；在第10页直接上传 Alternative 并运行 Weak/Alternative 敏感性情景 / Fit the primary models, then upload Alternative priors directly on Page 10 and run Weak/Alternative sensitivity scenarios.
6. 检查诊断、PPC、后验形态及科学解释 / Review diagnostics, fit and interpretation.
7. 优先由R直接保存完整分析到本地项目目录；网页下载仅作备用 / Prefer direct R-to-filesystem saving; browser downloads are fallback.

`Load simulated example` 仅用于熟悉软件，其先验和参数不能用于真实病原研究。示例中显式限制了 T1 的 DSe/DSp >0.5，这是一项模拟假设，不是软件对真实检测的默认科学判断。


## 论文输出 / Publication outputs

第12页“论文输出”针对当前已完成的单病原分析自动生成：样本纳入流程表与流程图、`Delta_DSe = DSe(T1)-DSe(T2)`、`Delta_DSp = DSp(T1)-DSp(T2)`、各差值的后验中位数和95% CrI，以及 `Pr(T1>T2)`。这些概率直接由同一 MCMC 后验抽样逐次相减计算，不是频率学 P 值。

STARD-BLCM 表是软件对 2017 STARD-BLCM 报告主题的映射审计，帮助发现研究信息、判定阈值、样本流程、先验、依赖结构、诊断和敏感性分析等是否有记录。它不是官方 checklist 的逐字复制，投稿前仍需核对原始 STARD-BLCM 论文及期刊要求。

每次“保存完整分析到本地”会同时写出标准化 `analysis_summary.csv` 和 `analysis_summary.json`，其中包含当前单病原的DSe/DSp及95% CrI、T1/T2后验差异、模型与诊断状态。软件不再扫描历史run，也不自动生成多病原汇总；如需多病原森林图，可直接使用这些标准化summary在Excel、R、GraphPad等软件中制作。

## 本地直接保存 / Direct local save

结果根目录现在在**第1页**统一选择，默认建议为 `Documents/VetBLCM`。完成一个模型运行后，在“导出与复现”页点击“保存完整分析到本地”，R 会按该次模型运行的 Analysis ID 直接建立：

```text
<结果根目录>/
└── YYYY-MM-DD/
    └── run_HHMMSS_<病原>_<Analysis-ID>/
        ├── analysis.rds
        ├── posterior_summary.csv
        ├── posterior_contrasts.csv
        ├── sample_flow.csv
        ├── STARD_BLCM_reporting_audit.csv
        ├── analysis_summary.csv
        ├── analysis_summary.json
        ├── VetBLCM_results.xlsx
        ├── report.html
        ├── model_used.jags
        ├── analysis_settings.json
        ├── sessionInfo.txt
        ├── figures/
        ├── local_export_manifest.json
        └── VetBLCM_<Analysis_ID>.zip
```

不同模型运行拥有不同 Analysis ID，因此进入不同的 `run_...` 文件夹。同一次模型运行若再次完整保存，则更新其原有 run 文件夹，而不是再制造重复副本。保存链不通过浏览器 HTTP 下载。Windows 可在首页“选择文件夹”并打开结果根目录；环境变量 `VETBLCM_OUTPUT_DIR` 仍可设置默认根目录。网页 HTML/Excel/ZIP/RDS/CSV 下载按钮保留为备用。

The results root is chosen on Page 1. R writes each model run to `root/YYYY-MM-DD/run_HHMMSS_analyte_analysisID/`. Different fit IDs create separate run folders; re-saving the same fit refreshes the same run folder. No browser transfer is required for the primary local-save path.

## 独立 R API / Standalone R API

```r
source("R/load.R")
load_vetblcm()
d <- read_blcm_data("examples/example_sample_level.xlsx")
p <- read.csv("examples/simulated_priors.csv", check.names = FALSE)
result <- run_blcm(d, p, mode = "sample", model = "positive",
                   settings = mcmc_settings("preview"))
result$summary
result$diagnostics$table
export_analysis(result, "my_analysis")
```

This example deliberately leaves study metadata incomplete, so it must remain exploratory. Real final reporting requires all scientific inputs and review checks.

## 重要解释 / Interpretation

- PPA、NPA、overall agreement、kappa是对照一致性指标，不是真实DSe/DSp。
- 两种依赖检测即使有≥3个群体，仍可能结构不可识别。MCMC收敛不代表参数已由数据识别。
- Preview不用于正式报告。Final只表示计算设置，不自动认证结果。
- 高级有符号依赖允许负协方差，但试点模拟显示部分负协方差覆盖不足，必须进行充分的先验和设计审阅。
- 简单模型不校正群内聚集、样品异质性或抽样权重；有这些问题时应调整研究设计或使用另外验证的方法。
- 项目JSON保存配置和已保存摘要；恢复后需重新拟合。每次完整分析包内的RDS保存实际draws和敏感性运行，可原样读取复核。

See `docs/USER_GUIDE.md`, `docs/STATISTICAL_SPECIFICATION.md`, `docs/METHOD_PROVENANCE.md` and `docs/MODEL_VALIDATION.md`.

## 验证 / Validation

```r
source("scripts/run_tests.R", encoding = "UTF-8")
# CLI: Rscript scripts/run_validation.R 20
```

以下为保留的历史回归脚本；本版本运行结果及未通过项见 `docs/RELEASE_CHECKS_1.0.0.md`。
Historical regression scripts (see the release-check document for current results and outstanding checks):

```text
Rscript --vanilla scripts/test_app.R
Rscript --vanilla scripts/test_prior_editor_sync.R
Rscript --vanilla scripts/test_launch_scope.R
Rscript --vanilla scripts/test_project_downloads.R
Rscript --vanilla scripts/test_local_export.R
Rscript --vanilla scripts/test_publication_outputs.R
Rscript --vanilla scripts/test_workflow_gating.R
Rscript --vanilla scripts/test_workflow.R
```

The last command performs four short JAGS fits to check the Shiny workflow. Short-run convergence failures are expected to be displayed and retained; passing this integration test does not mean those estimates are suitable for reporting. The full recovery/pilot evidence remains separate.

The repeated simulation is a pilot: 7 scenarios × 20 replicates. Failed convergence and weak estimation are retained in `validation/simulation_all_runs.csv`. Empirical interval coverage at a fixed generating parameter is not guaranteed to equal nominal posterior credibility. Do not interpret 20 replicates as a precise calibration study.

## 文件 / Files

- `R/`: standalone statistics, validation, diagnostics, plotting and export.
- `models/`: readable JAGS likelihoods.
- `modules/`: UI and server calls to the analysis API.
- `examples/`: two Excel templates and clearly labelled simulated datasets.
- `reports/example_analysis/`: generated by `scripts/run_example.R`; not included in the source archive.
- `tests/`, `validation/`: actual tests and simulation evidence.
- `docs/RELEASE_CHECKS_1.0.0.md`: current release checks and outstanding verification.

MVP scope excludes clustering models, Ct likelihoods, forced prevalence ordering, T3 models and simulation-based sample-size planning. CmdStanR cross-validation is optional and is not a required dependency. No regulatory endorsement or automatic publication approval is claimed.
