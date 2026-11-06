# Actual browser acceptance / 浏览器实测记录

Date: 2026-09-20. Local application at 127.0.0.1:7827, supported in-app browser. All data in this check are simulated. This record distinguishes observed UI behavior, downloaded content and uncompleted checks.

## Completed journey

- Loaded the 6,000-row simulated example; QC four-cell counts were Low 138/51/48/1763, Medium 472/92/87/1349 and High 1139/150/81/630. Each population had N=2,000. Population description editing was exercised.
- Checked prior selection, explicit support/provenance and saved edits. Two real UI defects were fixed as described below.
- Set four chains, adaptation 500, burn-in 1,000, sampling 2,000, thinning 1, seed 20260920. Ran independent and positive models using the button that runs both.
- Viewed numerical diagnostic warnings and Se1, Prev[2] and CovH-specific plots. Downloaded and visually inspected the CovH density PNG; its label and curve correspond to the selected parameter.
- Switched results from Chinese to English. Seventeen displayed numerical rows (ten posterior rows and seven model comparison rows) were exactly unchanged after the reactive update. This is a bounded display check, not a claim that every paginated row or every figure label was translated.
- Saved Alternative with comparator Beta(168,32) / Beta(190,10), concentration 200 each, and a Weak scenario. Both actually ran. Their failing numerical diagnostics and audit-only interpretation remained visible. Manual scientific-review boxes were not checked.
- Viewed agreement results with explicit PPA/NPA versus DSe/DSp distinction and descriptive-only Ct language. These outputs do not establish true accuracy or causality.

## Saved actual runs

| Run | Maximum R-hat | Minimum bulk ESS | Minimum tail ESS | Numerical targets |
|---|---:|---:|---:|---|
| Independent | 1.002326 | 2551.38 | 3598.56 | Pass |
| Positive | 1.021844 | 201.31 | 421.78 | Fail |
| Alternative | 1.024590 | 135.31 | 192.07 | Fail |
| Weak | 1.375480 | 9.02 | 40.51 | Fail |

Positive analysis ID: `20260920T141846.380_73e946ad30`. Exact values, IDs and posterior SHA-256 hashes are in `validation/browser_20260920/actual_run_diagnostics.csv`. Short browser runs are workflow evidence. They neither replace the longer recovery/pilot runs nor support a new calibration claim.

## Defects found and verified

1. Import/reload with an unchanged selected parameter left editor fields stale. The observer now responds to both parameter selection and the prior table. Before-fix regression failed; after-fix checks cover example loading, prior upload, project restore and weak-prior reset. A restarted actual browser showed the correct example support and rationale.
2. Saving Alpha/Beta retained inactive Mean/ESS input values. Saved metadata now derives from the actual alpha/beta. Targeted and state regressions passed. In a restarted browser, Se2 initially showed 336/64 with ESS 400; editing to 27/3 and saving once produced Mean 0.9, ESS 30 and the matching saved table. The mean refers to the underlying Beta; the separate summary calculates any truncated distribution's actual mean.

Evidence: `scripts/test_prior_editor_sync.R`, `validation/prior_editor_before_fix_20260920.log`, `validation/prior_editor_sync_20260920.log`, `validation/app_state_tests_20260920.log`. No core probability formula changed.

## Actual download delivery

Seven download links were clicked and files arrived: model JAGS, posterior CSV, full RDS, results Excel, bilingual HTML, complete analysis ZIP and selected diagnostic PNG. Copies are retained under `validation/browser_20260920/`. The ZIP required about 25 seconds; an initial 20-second event wait timed out, then a 60-second wait succeeded. A timeout alone was not classified as an application defect.

`scripts/verify_browser_downloads.R` checks the delivered files without refitting: model text, posterior CSV/Excel, main/comparison draw identity, alternative concentration metadata, HTML language controls and warning, safe required ZIP entries, nested RDS draw identity and PNG dimensions (1620 x 900). Results: `validation/browser_download_checks_20260920.log` and `validation/browser_20260920/download_verification.json`.

## Remaining limits

- Actual browser file upload remains unaccepted: the supported file chooser timed out on both the associated button and actual file input; direct CDP file assignment was unsupported. No file assignment was achieved. Passing server upload observers is not browser upload acceptance.
- Standalone HTML visual/language-button interaction review remains pending because the file preview was policy-blocked. Structural checks and successful download do not replace it; no alternate URL was used to evade the policy.
- The initial narrow-viewport sensitivity caption clipping was fixed in a later Sep20 follow-up. The UI removes only the plot caption and displays the identical bilingual text in a wrapping note; exports retain the caption. At 635 x 850, Chinese used two lines and English three, with no note overflow (clientWidth = scrollWidth = 383 pixels). Both were visually inspected. `validation/responsive_note_20260920.json` records the bounded check; no model was refit and no existing download was regenerated.
- No screenshots were saved to disk through an undocumented API. The record above is based on actual DOM observations and inline screenshots; downloaded numerical and image artifacts provide separate durable evidence.
- Fresh-computer restore and Toft full-text verification remain separately pending. Dendukuri selected equation-image review was completed subsequently; see SOURCE_AUDIT_20260921.md. Candidate status is retained.
