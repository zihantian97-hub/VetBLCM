# VetBLCM 0.1.1 candidate changes

Date: 2026-09-22

## Scope

This candidate is an **export/filesystem maintenance release**. The JAGS models, likelihoods, prior parameterization, posterior summaries, sensitivity-analysis logic and diagnostic thresholds are intentionally unchanged from 0.1.0.

## Added

- Primary **Save complete analysis locally** workflow. R writes directly to a user-selected/local path; browser file transfer is not required.
- Per-project, per-run directories: `<root>/<project>/run_<Analysis_ID>/`; repeated saves never overwrite an earlier run.
- Complete local ZIP generated beside the exported files.
- `local_export_manifest.json` containing relative file paths, byte sizes and SHA-256 values without exposing the user's local root path.
- Windows native folder chooser and “open last saved folder” action. Other systems can enter the path directly.
- `VETBLCM_OUTPUT_DIR` environment variable for choosing the default results root.
- `scripts/test_local_export.R` and unit coverage for local export behavior.

## Changed

- Browser result downloads are now a fallback and are hidden when no fitted posterior result exists. Restoring a project JSON therefore no longer presents misleading result-download controls before refitting.
- Browser complete-ZIP fallback now enumerates nested files explicitly.
- XLSX post-processing now corrects worksheet `<dimension>` metadata in addition to the prior unused-drawing relationship repair. This is for strict/streaming reader interoperability and does not alter worksheet values. Packaged templates/examples and the current example results workbook were refreshed with dimension-only XML changes; historical browser-validation downloads were left untouched as provenance evidence.
- Historical local validation receipts were path-redacted; their hashes, timings, exit codes and scientific evidence were not changed.

## Validation status

The 0.1.0 local acceptance remains evidence for the **unchanged statistical core**. The current build environment does not include R or JAGS, therefore the new 0.1.1 R regression tests have not been executed here. Before promoting 0.1.1 from candidate status, run at minimum:

```text
Rscript --vanilla -e "source('R/load.R'); load_vetblcm(); testthat::test_dir('tests/testthat')"
Rscript --vanilla scripts/test_local_export.R
Rscript --vanilla scripts/test_app.R
Rscript --vanilla scripts/test_project_downloads.R
```

Then perform one UI save to a Windows directory and confirm the run directory, Excel, HTML, RDS, ZIP and SHA-256 status line are produced.
