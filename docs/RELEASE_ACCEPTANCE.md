# Release acceptance / 正式版验收

Updated 2026-09-21. **Candidate; formal release is not approved. / 当前为候选版，尚未通过正式版验收。**

**Latest scope update:** the user subsequently directed “本地测试即可”. Local acceptance has passed all seven extracted-package test processes; see `LOCAL_ACCEPTANCE_20260921.md`. Browser upload delivery and independent HTML visual interaction remain unperformed and are excluded from the accepted local gate, superseding their historical BLOCKED rows below. No extension permission change is requested. The explicitly requested Toft full-text audit remains outstanding; no waiver of that source requirement is inferred.

This register maps the original request, section 101, and the user's latest explicit acceptance requirements to evidence. A runnable interface, a passed unit suite and a successful numerical fit are different claims.

| Gate / 验收项 | Evidence / 证据 | Status / 状态 |
|---|---|---|
| Statistical equations and feasible probabilities / 公式及概率约束 | STATISTICAL_SPECIFICATION.md; METHOD_PROVENANCE.md; covariance quadrature and probability tests | Implemented and checked, with the normalized-prior distinction recorded |
| Simulation recovery and pilot / 模拟恢复及试验 | MODEL_VALIDATION.md; independent/positive recovery; 140-fit pilot | Executed; four pilot diagnostic failures retained, weak-design bias and coverage limitations explicit |
| MCMC diagnostics and prior sensitivity / 诊断及敏感性分析 | Saved diagnostics, Weak/Alternative fits, actual browser workflow | Implemented and exercised; failed fits remain unsuitable for inference |
| UI and bilingual state / 界面及双语切换 | BROWSER_QA_20260920.md; responsive-note evidence | Main workflow checked; upload delivery still pending |
| Reproducible exports / 可复现导出 | Seven browser downloads; RDS/ZIP hashes and numeric CSV/Excel checks | Checked; standalone HTML visual interaction remains pending |
| Traceable sources / 来源可追溯 | source_manifest.json; SOURCE_VERIFICATION.md; SOURCE_AUDIT_20260921.md | Core derivations documented; Toft 2005 full text still pending |
| Actual browser uploads / 浏览器实际上传 | Server tests and prepared fixtures only | BLOCKED: IAB chooser timeout; native tool initialization fails |
| Standalone HTML visual and language controls / 独立报告视觉与语言按钮 | Structural checks: ten embedded PNGs, no external resources, bilingual controls | BLOCKED: prior file-URL policy restriction; permitted file-panel request queued but not observed |
| Toft full-text audit / Toft 全文核验 | Publisher, author-institution and bibliographic searches | BLOCKED: no accessible full text obtained; metadata/abstract are not full-text evidence |
| Final package integrity / 最终包完整性 | package_release.py; ZIP SHA-256 and verification sidecars | Rebuild and verify after changes; keep candidate designation until gates close |

## Upload fixtures ready for browser acceptance

All fixture data are synthetic and too small for model validation. Do not run MCMC on these merely to accept upload delivery.

1. Upload `validation/upload_fixtures/sample_identifiers.csv` in sample mode, then activate the load/import button. Require exactly three rows; IDs `001`, `1`, `9007199254740993`; separate populations `01` and `1`, with N = 2 and 1. Switch Chinese/English and confirm values remain unchanged.
2. Upload `validation/upload_fixtures/aggregated_identifiers.csv` in aggregated mode. Require the same population counts and four-cell counts (1,1,0,0) and (0,0,0,1), in 11/10/01/00 order.
3. Upload `validation/upload_fixtures/invalid_test_value.csv` in sample mode. Require a visible T1 validation error for value 2; do not silently discard or recode the row.
4. Upload the existing `examples/example_sample_level.xlsx` and `examples/example_aggregated.xlsx`; reconcile with the existing 6,000-observation evidence, without refitting.
5. Exercise the existing prior upload and project JSON restore controls. Check restored values and provenance in the editor against the selected files. Do not substitute loading the built-in example for actual upload.

For every case record browser, timestamp, selected filename, observed UI result and any error. Current scripts `test_upload_identifiers.R` and `test_upload_delivery_server.R` verify parsing/server behavior only; neither is browser acceptance.

## Independent HTML acceptance still required

Inspect `reports/example_analysis/report.html` on an allowed preview surface. Check all sections and figures, wide/narrow layout, Chinese/English toggles, unchanged numerical tables, visible failure/identifiability warnings, and offline embedded assets. Structural checks and diagnostic-PDF inspection do not close this gate. Do not evade the recorded file-URL policy restriction using a different URL or renderer.

## Toft audit still required

The exact target is Toft, Jørgensen & Højsgaard (2005), *Preventive Veterinary Medicine* 68(1), 19–33, DOI [10.1016/j.prevetmed.2005.01.006](https://doi.org/10.1016/j.prevetmed.2005.01.006). The [Aarhus institutional record](https://pure.au.dk/portal/en/publications/diagnosing-diagnostic-tests-evaluating-the-assumptions-underlying/) confirms the bibliographic identity, but did not supply full text in this audit. The similarly titled 2002 conference paper is a different work.

Once lawful full-text access is available: archive privately with SHA-256, verify title/authors/pages, read the methodological assumptions and reported simulation results, record page-specific claim support and limits, and reconcile with the implemented models. Do not infer article-specific claims from abstracts or other papers' reference lists.

## Import correction completed in this continuation

CSV/TSV type guessing previously collapsed leading-zero sample/population/herd labels and could round long numeric-looking identifiers. The regression failed before the correction. The reader now retains these columns as character strings while allowing numerical prior columns to keep their existing types. A literal `#` in a CSV/TSV identifier is now treated as data, not a comment. The source-file hash is preserved. Numeric cells already stored without zeros in Excel cannot have those original zeros reconstructed by the reader.

Evidence: `validation/upload_identifiers_before_20260921.log` (expected historical failure), `upload_identifiers_after_20260921.log`, `upload_server_20260921.log`, `prior_editor_import_20260921.log`, and `unit_tests_import_20260921.log` (59 existing assertions passed). No likelihood, JAGS model, saved posterior or simulation result was changed or rerun.

## Environment follow-up

Later Sep21 update: the user approved Chrome after Edge was unavailable. Chrome connected and rendered the app, but its supported file-chooser flow timed out and the page retained `No file selected`. Browser-specific troubleshooting and the [official upload guidance](https://learn.chatgpt.com/docs/chrome-extension#upload-files) identify the extension's Details > Allow access to file URLs setting as a prerequisite. The user has been asked to check/enable it; its current value was not observed and no permission was changed by the agent. Chrome is now the selected browser; the earlier browser-choice question is resolved. The upload gate remains open. This does not itself authorize bypassing the earlier standalone-HTML restriction.

The documented Windows native tool failed before execution with `failed to write kernel assets: 系统找不到指定的路径。 (os error 3)`; one supported reset and retry produced the same failure. No native window/picker was inspected. The permitted Codex file-panel open request returned `queued`, which does not prove rendering or interaction. A question asking the user to select Edge or Chrome for the remaining upload acceptance is pending. No browser choice or successful upload is inferred from silence.

Fresh-computer dependency restoration remains explicitly untested; Stan, additional tests, hierarchical models and sample-size design remain deferred extensions. Formal software release would not certify any empirical diagnostic estimate or remove the stated statistical limitations.
