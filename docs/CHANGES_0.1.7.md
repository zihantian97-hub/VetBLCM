# VetBLCM 0.1.7 changes

## Scope

This release simplifies publication/output management without changing the BLCM likelihood, JAGS models, prior resolution, posterior sampling, or diagnostic formulas.

## Changes

- Removed Page-12 local scanning of completed analyses and automatic multi-analyte summary/forest-plot generation.
- Retained single-analyte publication outputs only: sample flow, posterior T1-vs-T2 contrasts, and the STARD-BLCM reporting audit.
- Added standardized `analysis_summary.csv` alongside `analysis_summary.json` for every complete single-analyte export.
- Moved the local-results root selector to Page 1. The default root is `Documents/VetBLCM` when available.
- Local complete saves now use `root/YYYY-MM-DD/run_HHMMSS_analyte_analysisID/`. Different fit IDs create separate run folders; re-saving the same fit atomically refreshes that run folder instead of creating duplicates.
- Page 13 displays the Page-1 root rather than asking the user to choose a path again.
- Historical multi-analyte aggregation remains a documented 0.1.4 feature but is removed from the current UI/API.

## Validation status

Static/package checks are performed during packaging. Windows R 4.4.1/JAGS 4.3.1 runtime interaction for the new Page-1 path selector and revised run-directory layout remains pending.
