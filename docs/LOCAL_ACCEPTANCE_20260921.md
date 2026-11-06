# Local acceptance / 本地验收

**PASS / 通过 — 2026-09-21.** The user explicitly directed “本地测试即可”. Browser extension permission changes and actual chooser/standalone-HTML visual checks are no longer prerequisites for this local acceptance. They remain unperformed, not silently marked as passed.

The candidate ZIP was extracted into a new workspace directory, and all 304 manifest entries were SHA-256 verified before execution. The exact tested archive SHA-256 is `5c9ed8297866997826d5f5dad9606dc5be4379f09cafc2fc07b856e14ace33ed`. Subsequent packaging adds these receipts and changes documentation/status only; this tested hash identifies the test input, not the final ZIP.

| Executed check / 检查 | Result / 结果 |
|---|---|
| Unit suite / 单元测试 | 59 assertions passed |
| Isolated app launch scope / 独立应用环境加载 | Fresh R process loaded Shiny in its private environment and imported the 6,000-row example |
| Identifier parsing / 编号导入 | CSV/TSV retained leading zeros, long IDs, population/herd labels and literal #; numeric priors remained usable |
| Server upload handlers / 服务端上传处理 | Sample/aggregated counts agreed; groups 01/1 remained separate; invalid T1=2 rejected; language change preserved data |
| Prior editor / 先验编辑 | Same-selection import/restore synchronized shape, support and provenance; Alpha/Beta save recomputed Mean/ESS |
| Shiny state / 应用状态 | Example, language change, scenario save, prior edit and data reset passed |
| Project restore and exports / 项目恢复和导出 | Two analytes retained separate priors, settings, scenarios and leading-zero IDs; review flags reset; model/CSV/Excel/RDS values and draw hashes matched; bilingual HTML controls/warnings and ZIP contents checked |

All seven R processes exited with code 0. The project/export regression reused previously saved actual posterior draws and performed no new model fit. Its nonfatal bayesplot/ggplot2 line-aesthetic deprecation warning is retained in the log. No numerical diagnostic failure was hidden or upgraded to a valid scientific result.

Receipts and complete logs are under `validation/local_acceptance_20260921/`. The extraction and original logs remain under workspace `work/local_acceptance_20260921_163012/`. The candidate packaging process separately verifies the final ZIP CRC and every included file hash.

## Scope and remaining source requirement

This verifies local software behavior on the installed R 4.4.1 / JAGS 4.3.1 environment. It does not test fresh dependency installation, browser file delivery, standalone HTML rendering/buttons, or a real diagnostic assay. Previous visual evidence and statistical validation limits remain in QA_STATUS.md and MODEL_VALIDATION.md.

本地程序验收已通过。用户此前明确要求的 Toft et al. (2005), DOI `10.1016/j.prevetmed.2005.01.006` 全文核验仍未完成；公开书目与摘要不能替代原文。正式版状态仍保留为候选版，等待合法可获取的全文完成逐页核验。软件中的统计限制继续适用。

The prior browser tab and temporary local QA server were stopped. The existing continuation automation was found PAUSED and remains PAUSED; its prompt now follows local-only acceptance and avoids repeated browser-permission requests or unchanged literature searches.
