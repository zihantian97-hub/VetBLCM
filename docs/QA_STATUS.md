# QA status

Updated 2026-09-28: **0.1.10 reporting-integrity maintenance release**. Local test evidence and scope: docs/CHANGES_0.1.10.md and validation/repair_0.1.10/. Statistical core unchanged. Unknown sample flow preserved; prior documentation decisions unified. Toft user-supplied full text was reviewed in the 2026-09-28 principle audit; no new paper simulation or browser visual acceptance claimed. Older entries below are historical, not current release status.

---

# QA status / 验收状态

Updated 2026-09-22. Status: **0.1.9 candidate; historical primary-model acceptance retained; 0.1.1–0.1.9 Windows runtime regression pending; Toft full text pending**.

Latest user direction: “本地测试即可”. Seven test processes passed on a fresh extracted package; full receipts are in `validation/local_acceptance_20260921/` and `LOCAL_ACCEPTANCE_20260921.md`. Browser upload delivery and standalone HTML visual interaction remain unperformed and are no longer required for the accepted local scope. Earlier browser-blocker notes below are historical. No model was refit and no assay-level validation is claimed.

统计模型、数据处理、服务端流程及实际下载处理程序已有可复核测试；当前不宣称已完成全部浏览器交互验收。此说明区分软件运行成功、MCMC数值达标、科学解释适用性和视觉检查，四者不能互相替代。




### 0.1.9 help/autofill delta

Non-action explanatory notes were moved to hover/focus `?` help tips; warnings and errors remain persistent. The built-in simulated example now fills all prefillable study fields and complete simulated prior provenance. Manual review acknowledgements and fit-dependent outputs remain intentionally unfilled until the user performs those actions. Statistical likelihood/JAGS/MCMC code is unchanged. Windows UI regression remains pending.

### 0.1.8 navigation/folder-dialog delta

Validation issues are now advisory by default. A separate minimal `page_hard_blockers()` layer blocks Next only for missing/invalid foundational data, missing essential data/prior objects, or absence of any fitted result where a result-dependent page cannot function. `max_unlocked` and prerequisite-page redirect logic were removed; direct sidebar viewing is permitted. Page-1 folder selection now uses a PowerShell STA `.NET FolderBrowserDialog` first and falls back to `utils::choose.dir()`. These are workflow/UI changes only; likelihood/JAGS/MCMC computation is unchanged. Windows interaction remains pending.

### 0.1.7 output-location simplification delta

Page 12 is single-analyte only: local historical-run scanning, automatic multi-analyte summary tables and panel forest plots were removed. Complete exports retain standardized `analysis_summary.csv/json` files so users can combine selected analytes externally. The results root moved to Page 1. Local saves use `root/YYYY-MM-DD/run_HHMMSS_analyte_analysisID/`; different fits create separate run folders, while re-saving the same fit refreshes that fit's folder atomically. Likelihood/JAGS/prior-resolution/MCMC diagnostic formulas are unchanged. Windows UI and filesystem runtime regression remain pending.


### 0.1.6 sensitivity-workflow delta

Alternative priors are uploaded and validated directly on Page 10 against the frozen Main fit. MCMC diagnostic failure of a completed sensitivity scenario is advisory: the scenario is retained, explicitly acknowledged, and excluded from valid parameter interpretation. Invalid/missing scenarios and computational failures remain hard blockers. Main JAGS likelihoods, prior/probability formulas, fitting loop and MCMC diagnostic formulas are unchanged; only sensitivity review/checklist and reporting-readiness semantics changed. New runtime regression `scripts/test_sensitivity_upload_gate.R` must pass on Windows R/JAGS before formal release.

### 0.1.5 guided-entry delta

Version 0.1.5 changes UI/server metadata-entry logic only. Presets populate existing auditable metadata fields and do not enter the BLCM likelihood. Placeholder detection prevents generic qPCR thresholds, replicate rules, population criteria or evidence citations from being mistaken for completed scientific inputs. The guided population editor does not order prevalence or modify priors. Statistical JAGS models and core likelihood/MCMC files remain unchanged.


### 0.1.4 publication-output delta

Version 0.1.4 changes reporting/documentation and derived-output code only. New inputs record positivity rules, handling of non-binary outcomes, source population, sample flow and sample-size rationale before modelling. New outputs derive paired posterior DSe/DSp contrasts from existing draws, generate a sample-flow figure, create a STARD-BLCM reporting audit and write one compact summary JSON per completed single-analyte run. Project-level tables/forest plots display the latest completed run for each analyte without pooling. Statistical JAGS models and core likelihood/MCMC code remain unchanged. Static checks are complete in the build environment; R/Windows interaction and output generation remain pending final local regression.

### 0.1.3 sequential workflow-gate delta

Version 0.1.3 adds gated page navigation only. Every workflow page now returns a bilingual pass/fail/warning status; Next is disabled until the current page passes, and sidebar navigation cannot skip beyond the highest unlocked page. Forward navigation revalidates prerequisites so an earlier edit can invalidate downstream progression. QC, posterior-results and agreement pages add explicit user-review acknowledgements. Diagnostics require acceptable MCMC diagnostics plus the existing manual reviews; sensitivity requires at least two successful scenarios including a weak-prior and a justified non-weak alternative, with acceptable diagnostics and explicit review. Export requires the current fit to have been saved through the direct local-save path before Help unlocks. Statistical likelihoods, priors, posterior computation and diagnostics are unchanged. Static/source checks are complete; Windows Shiny interaction regression remains pending.

### 0.1.2 desktop-shell delta

Version 0.1.2 adds `VetBLCM.exe` and `launch_desktop.ps1` only around the existing local application. The native executable is a 64-bit Windows GUI PE with no static import table; it resolves Windows process APIs at runtime, locates its own directory, and invokes the PowerShell desktop launcher. The PowerShell launcher finds R, starts the existing `scripts/launch.R` with browser autolaunch disabled, waits for localhost readiness, and opens Edge/Chrome in App mode. Closing the tracked App-mode session stops the R backend. This is a presentation/lifecycle change, not a statistical-model change. Static checks passed in the current environment; actual Windows double-click, renderer lifecycle and end-to-end local save remain pending.

### 0.1.1 export/filesystem delta

Version 0.1.1 does not change JAGS likelihoods, priors, posterior summarisation, sensitivity logic or diagnostics. It adds direct local filesystem export and XLSX dimension repair. New regression coverage is in `tests/testthat/test-local-export.R`, the added workbook test, and `scripts/test_local_export.R`. These tests have been source-reviewed in the current build environment but cannot be executed here because R/JAGS are unavailable. They must be run on the validated Windows environment before 0.1.1 can inherit the “local acceptance passed” label as a whole.

## Executed checks

| Check | Evidence | Result |
|---|---|---|
| Unit/regression assertions | `validation/unit_tests_20260919.log` | 59 assertions passed: core 32, identification 3, reporting 15, status 6, workbook 3; no warnings in this suite |
| Isolated application environment | `scripts/test_launch_scope.R`; `validation/launch_scope_tests_20260919.log` | Fresh R process loaded the app in a private environment and imported 6,000 example rows successfully |
| Shiny server state | `scripts/test_app.R`; `validation/app_state_tests_20260919.log` | Example import, language/data invariance, prior editing, scenario save and data reset passed |
| Multi-analyte project restoration | `scripts/test_project_downloads.R`; `validation/project_download_tests_20260919.log` | Two analytes retained separate data, priors, models, custom settings and scenarios; leading-zero IDs and Chinese names survived JSON; review boxes reset and notes remained |
| Actual download handlers | Same project/download test | Model text, CSV values, numeric Excel cells, RDS draw hashes, bilingual HTML structure and complete nested ZIP entries passed |
| Shiny-to-JAGS workflow | `scripts/test_workflow.R`; `validation/workflow_tests_20260919.log` | Uploaded Excel/priors, ran both models and Weak/Alternative scenarios, rendered selected parameter plots, preserved draws on language change |
| Probability/recovery/pilot | `docs/MODEL_VALIDATION.md`; `validation/` | Real JAGS runs; 140 pilot fits completed, 136 met numerical targets; failed/weak cases retained |
| Windows launcher and HTTP | `launch_app.ps1`; `validation/launcher_http_20260919.json` | Automatically found the installed R without an explicit path; served HTTP 200 on localhost, with both language labels and switching code present |
| Frozen example refresh | `validation/export_refresh_20260919.log` | Excel/HTML and affected plots refreshed without changing original numeric draws |
| Actual browser journey | `docs/BROWSER_QA_20260920.md`; `validation/browser_20260920/` | QC, priors, settings, both models, parameter plots, two sensitivity runs, agreement, language switching and seven actual file downloads completed |
| Prior-editor fixes | `validation/prior_editor_before_fix_20260920.log`; `validation/prior_editor_sync_20260920.log` | Before-fix failure retained; same-selection reload/import/restore and saved Mean/ESS regression passed; both fixes verified in restarted browser |
| Current state regression | `validation/app_state_tests_20260920.log` | Passed after both prior fixes |
| Delivered browser file content | `scripts/verify_browser_downloads.R`; `validation/browser_download_checks_20260920.log` | Model, CSV/Excel summaries, RDS/ZIP posterior identity, scenario concentration, bilingual HTML controls/warning and PNG dimensions passed |

The workflow test uses 4 chains, 500 adaptation, 1,000 burn-in and 2,000 sampling iterations. Its independent fit met numerical targets; positive, Weak and Alternative fits did not. These are **workflow checks**, distinct from the longer recorded recovery and pilot simulations. The unsuccessful short-run diagnostics are in `validation/workflow_runs_20260919.csv`. No additional recovery or calibration claim is made from these runs.

Plot-generating tests emit a nonfatal upstream bayesplot warning about the deprecated ggplot2 `size` line aesthetic. They completed and generated plots; the warning is preserved in the logs. This is separate from MCMC convergence warnings. Package versions are frozen in `renv.lock`.

## Visual checks

- All 44 pages of the main example's `figures/diagnostics_all_parameters.pdf` were rendered and inspected across two development sessions. Labels, chain panels, density/prior overlays and autocorrelation panels were readable. This was visual layout review, not approval of scientific assumptions.
- All ten main example PNG figure types were inspected. The sensitivity figure now marks runs that fail numerical diagnostics explicitly; failed estimates remain for audit only. Density curves can show smoothing bias near support boundaries, as stated in the report and guide.
- The four Excel templates/examples and results workbook were imported with a separate strict spreadsheet reader. Bounded views of template instructions, data, priors, posterior estimates and MCMC diagnostics were rendered and inspected. All 6,000 raw rows were checked through import/count reconciliation, not individually inspected visually.
- On Sep20 the supported browser environment recovered. The actual model/sensitivity/download journey completed with 6,000 simulated records. Chinese/English switching preserved the 17 displayed numerical rows checked; CovH density PNG downloaded and was visually inspected. The earlier Sep19 initialization failure is historical, not a current general browser blocker.
- **Browser file upload remains unverified.** Supported file chooser calls timed out twice; direct CDP assignment was unsupported. Server upload/restore checks passed, but do not replace actual browser delivery acceptance.
- The narrow sensitivity caption clipping was fixed in the Sep20 follow-up: the UI now places the same bilingual text in a wrapping HTML note outside the plot. Both languages were visually inspected at 635 x 850; the note's clientWidth and scrollWidth were both 383 pixels. Export captions and saved figures are unchanged. Evidence: `validation/responsive_note_20260920.json`; fresh app-state regression passed. This follow-up inspected the note without refitting the model; earlier saved-fit browser checks remain the numerical evidence.
- Standalone HTML has passed structural/content and generation checks. Its local-file visual inspection was blocked by the browser tool's file-URL policy in an earlier session. No alternative URL was used to evade that policy; HTML visual acceptance remains incomplete.

## Environment and scientific limits

Tested locally: R 4.4.1, JAGS 4.3.1, rjags 4-16, posterior 1.6.1, Shiny 1.9.1. In the agent's restricted filesystem, Shiny's parent-directory lookup encountered EPERM; the normally authorized launcher outside that restriction served the application successfully. This is not evidence that a newly installed computer has been tested.

Fresh-computer `renv::restore()` remains untested. It requires R and separately installed JAGS; historical source packages may require Rtools. The lockfile records the actual development versions, not a guarantee of binary availability forever.

Dendukuri & Joseph 2001 local PDF archival and selected equation-image checks are complete, recorded 2026-09-21. The distinction between its printed kernel and the normalized conditional prior is explicit in SOURCE_AUDIT_20260921.md; 12 numerical quadrature checks passed. No fitting code or existing posterior changed. Toft et al. 2005 full text remains `PENDING_VERIFICATION`. See `SOURCE_AUDIT_20260920.md` and `SOURCE_VERIFICATION.md`. Core equations continue to use the previously verified sources and documented derivation. This documentation update does not replace statistical tests or visual acceptance.

The worked example's long Weak-prior run failed numerical targets (maximum R-hat 1.0248, minimum bulk ESS about 134). The example remains exploratory. No release status, graphical check or software test upgrades it into a reliable empirical result. Two-test models with free class-specific covariances remain structurally nonidentified without additional information.

## Remaining acceptance steps

The Sep21 follow-up and exact browser fixture expectations are in `RELEASE_ACCEPTANCE.md`. Import parsing/server/prior-editor checks passed after fixing CSV/TSV identifier preservation; the existing 59-assertion suite passed again (`unit_tests_import_20260921.log`). These tests do not close actual browser upload acceptance. Native file-picker fallback failed tool initialization even after reset, and the standalone report's file-panel request was only queued. The latest user request also explicitly requires completion of the Toft 2005 full-text audit; it remains pending.

1. On Windows R 4.4.1/JAGS 4.3.1, double-click `VetBLCM.exe`; verify the standalone App-mode window opens, run one example fit, save one complete analysis locally, close the window, and confirm the R backend exits. Then run the 0.1.1 unit suite plus `scripts/test_local_export.R`, `scripts/test_app.R` and `scripts/test_project_downloads.R`.
2. Obtain legitimate full-text access to Toft 2005 and finish the explicitly requested page-specific audit. Metadata/abstract and the similarly titled 2002 conference work do not satisfy this requirement.
3. Preserve the unperformed browser upload/standalone HTML visual limitations; do not request permissions or repeat those checks under the user's latest local-only direction.
4. Rebuild package/hash receipts after changes and keep the candidate label until the outstanding full-text requirement is satisfied. The continuation automation is PAUSED.

Fresh-computer restore and the optional Stan backend remain separately labelled, not silently claimed as completed. No new scientific input is currently required to finish this generic software candidate.
