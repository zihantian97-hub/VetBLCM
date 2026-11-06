# 0.1.10：报告真实性修复 / Reporting integrity fixes

2026-09-28。基于用户提供的 0.1.9。此次修复不改变似然、先验数值转换、JAGS 模型、MCMC、PPC 或后验抽样。

## 修复内容

1. 未知筛选总数保留为缺失值；中文/英文流程图分别显示“未提供”/“Not provided”，CSV 使用 NA，Excel 使用空值。导入数据不再根据纳入人数自动填筛选总数。已明确提供且等于纳入人数时，才计算排除人数为 0。非整数、非有限值或小于纳入人数的总数报错，不静默修正。
2. 正式审阅增加 `Sample_flow_documented` 必需项；缺失或不合法的筛选总数不能使完整报告审阅通过。探索性查看仍可进行；矛盾人数不能导出误导性样本流程。
3. 两张检查表统一使用 `priors_documented()` 检查。信息性或截断先验缺失来源、依据、不确定性、适用性等字段时，STARD 辅助表显示 `Review`，不再因先验表存在就标为 `Complete`。字段齐全仍不等于证据在科学上充分。
4. 软件未检查论文标题/摘要，因此该项保留作者审阅状态，不自动认证完成。
5. 修正模拟示例的 Assay 子集赋值，保留已有 T1/T2 标记，患病率及依赖参数标为 `Not assay-specific`。
6. 修正 Windows 下测试脚本通过 ZIP 文本连接读取 XML 的执行错误；改为二进制读取。流程图使用当前 ggplot2 线宽参数。

## 验证

本地运行环境：Windows、R 4.4.1、JAGS 4.3.1。24 个测试用例，179 个断言通过，0 失败、0 错误、0 跳过。剩余 1 个警告来自 bayesplot 使用已弃用的 ggplot2 线宽写法，不影响本次检查结果；未为消除该第三方提示改动统计绘图依赖。

实际服务端/导出脚本覆盖：筛选人数不自动补值、模拟示例字段、隔离启动、建议式流程、敏感性先验上传与警告、论文输出、本地导出。测试日志在 `validation/repair_0.1.10/`。Shiny 状态测试中的模拟对象不作为新 MCMC 验证。

Excel 与 HTML 导出回归检查覆盖缺失样本人数和不完整先验来源；错误筛选人数明确拒绝导出。随附示例报告从原保存抽样重新生成，保存的 analysis.rds 校验和不变。没有新拟合或改写既有统计结果。8 个统计核心文件与 0.1.9 的 SHA256 比较见 `core_integrity.json`。

## 更新与旧项目

从新目录中的 `VetBLCM.exe` 或 `launch_app.bat` 启动。原版保留，避免覆盖已有工作。

旧项目中已经保存的筛选总数可能曾由旧版自动填入，无法从该数值判断是否人工确认。请根据原始研究记录核实“筛选总数、排除人数及原因”，再用新版重新导出。新版不会为了迁移而自动改写旧项目数据。

此次是已知缺陷修复，不包括先验误设或群体准确度异质性的新模拟研究，也不宣称完成浏览器文件上传或独立 HTML 视觉验收。此前已取得的 Toft 全文审查结论见本次原理审查记录；本修复不以摘要替代全文、不宣称复现论文模拟。

## English

Unknown screening totals are no longer inferred from included records. Missing values remain missing, impossible totals are rejected, and sample-flow completeness is a required reporting check. Both prior-documentation checklists now share one validation function. Manuscript title/abstract compliance requires author review. Simulated-example assay metadata and Windows ZIP-based tests are corrected. The statistical engine and saved posterior draws are unchanged. Verify screening metadata in legacy projects before re-exporting. See the saved local test logs for scope and results; no browser visual acceptance or new misspecification simulation is claimed.
