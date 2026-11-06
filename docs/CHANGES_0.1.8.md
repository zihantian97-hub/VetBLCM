# VetBLCM 0.1.8 changes

## Scope

This release changes navigation/validation semantics and the Windows folder-selection mechanism. It does not change the BLCM likelihood, JAGS models, prior resolution, posterior sampling, or MCMC diagnostic formulas.

## Changes

- Replaced sequential pass-to-unlock navigation with an advisory-first workflow.
- Red/yellow validation findings remain visible but no longer disable Next by themselves.
- Added a small explicit technical-blocker layer for conditions where the next stage cannot function (for example no valid parsed data, missing required data/prior objects, or no fitted result on result-dependent pages).
- Removed `max_unlocked` and prerequisite-page redirect logic; sidebar pages can be inspected directly.
- Replaced the primary Windows folder chooser with a PowerShell STA `.NET FolderBrowserDialog` owned by an invisible top-most form; `utils::choose.dir()` remains fallback only.
- Direct path entry on Page 1 remains available regardless of dialog support.

## Interpretation

An advisory-first workflow improves usability but does not turn red warnings into scientific approval. Users remain responsible for resolving/documenting design, prior, diagnostic and reporting concerns before final inference.

## Validation status

Static/package checks are performed during packaging. The current environment cannot execute the Windows desktop UI or R/JAGS runtime, so the new native folder dialog and end-to-end interaction require Windows regression before formal release.
