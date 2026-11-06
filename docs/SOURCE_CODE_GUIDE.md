# VetBLCM 0.1.10 注释源码说明 / Annotated source guide

本目录是 VetBLCM 0.1.10 的注释源码版。注释解释每个模块的职责、关键统计假设、数据顺序、输出边界和可追溯字段；未改变已经验证的统计计算行为。

## 目录结构

- `R/00_utilities.R`：断言、依赖检查、随机种子和哈希。
- `R/01_data.R`：Excel/CSV/TSV 读取、0/1 数据检查、四格表构建、群内聚集提示。
- `R/02_priors.R`：Beta 先验、截断、均值/ESS 转换及先验证据字段。
- `R/03_probability.R`：独立于 JAGS 的四格概率、Bernoulli 协方差边界和模拟函数。
- `R/04_run_jags.R`：将数据和先验传给 JAGS，执行适应、预热、MCMC，冻结模型与来源信息。
- `R/05_diagnostics.R`：后验摘要、R-hat、bulk/tail ESS、相关性、边界提示和 PPC。
- `R/06_sensitivity.R`：模型比较、先验敏感性、报告完整性检查和状态颜色。
- `R/07_plots.R`：诊断图及诊断 PDF。
- `R/08_reporting.R`：Excel、HTML 和完整分析目录导出。
- `R/09_workbook.R`：XLSX 工作表范围与读取器兼容性处理。
- `R/10_local_export.R`：本地运行目录、ZIP、相对路径清单及 SHA256。
- `R/11_publication_outputs.R`：后验差值、样本流程和 STARD-BLCM 主题映射辅助表。
- `models/*.jags`：条件独立、正协方差和有符号协方差模型。
- `modules/mod_layout.R`：中英文 Shiny 界面。
- `modules/mod_server.R`：会话状态、输入事件、拟合、敏感性分析和导出流程。
- `tests/`、`scripts/`：回归测试和复现脚本。
- `docs/FUNCTION_INDEX_ZH.json`：主要函数的中文注释索引。

## 关键数据顺序

所有模型固定四格顺序为 `11, 10, 01, 00`，在 R 中对应 `n11, n10, n01, n00`。感染类的阳性边际为 `Se1, Se2`；非感染类的阳性边际为 `1-Sp1, 1-Sp2`。观测概率为：

`P_j = Prev[j] * Q_D + (1 - Prev[j]) * Q_H`。

依赖模型的 `uD/uH` 是可行协方差区间的位置参数，不是 Pearson 相关系数。允许自由类内协方差的两检测模型不能仅凭增加群体保证结构可识别；先验敏感性和科学依据仍是必要审阅内容。

## 本地运行

需要 R 4.4.x、JAGS 4.x 和 DESCRIPTION 中列出的 R 包。首次安装可在项目根目录运行：

```powershell
F:\R-4.4.1\bin\Rscript.exe --vanilla scripts/setup.R
```

日常启动：

```powershell
F:\R-4.4.1\bin\Rscript.exe --vanilla scripts/launch.R
```

或双击 `VetBLCM.exe` / `launch_app.bat`。源码 API（不启动 Shiny）示例：

```r
source("R/load.R", encoding = "UTF-8")
load_vetblcm()
data <- read_blcm_data("examples/example_sample_level.xlsx")
```

分析前必须提供真实研究的样本流程、检测判定规则、群体定义、先验证据及模型假设。示例数据和模拟先验只用于软件验证，不能直接替代真实研究依据。

## 注释与版本边界

源码注释版只增加解释性注释和本说明文件。核心八个文件（`R/01_data.R` 至 `R/05_diagnostics.R` 及三个 JAGS 模型）与已验证的 0.1.10 核心保持相同 SHA256。最近一次验证结果为 24 个测试用例、179 个断言通过、0 失败、0 错误；剩余一条绘图弃用警告来自第三方 bayesplot，不影响统计计算。

本源码包不宣称完成浏览器上传交互验收或独立 HTML 视觉验收，也不包含病原实验操作内容。它是诊断评价统计软件源码。
