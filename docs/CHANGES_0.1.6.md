# VetBLCM 0.1.6 changes

Updated 2026-09-22. Candidate release.

## Sensitivity workflow

- Page 10 now accepts an Alternative prior scenario file directly (XLSX/XLS/CSV/TSV), validates it against the current fitted model/populations, previews the resolved priors, records which parameters changed from Main, and adds it under a user-supplied scenario name.
- Main priors are frozen after fitting. If Page-5 Main priors change, the primary model must be refit. Alternative sensitivity scenarios must no longer be created by overwriting Main priors.
- Weak remains generated from the fitted Main priors. At least Weak plus one changed non-weak Alternative are required for the standard sensitivity workflow.
- A sensitivity scenario that completes computation but fails MCMC diagnostic targets is now a warning, not an automatic permanent blocker. The failed scenario remains visible for sensitivity/identifiability interpretation and may not be used as valid parameter inference. Explicit reviewer acknowledgement is required before proceeding.
- Invalid prior files, missing required scenarios, or computational failures remain hard blockers.

## Guided entry

- The 0.1.5 bounded-entry approach is retained and tightened. Common qPCR positivity rules use explicit Ct operator/cutoff and optional replicate rules; templates never invent a Ct value.
- Page 4 offers bounded grouping bases, common reproducible criterion templates, expected-risk categories, evidence-source categories, and automatically generated rationale text. Study-specific thresholds/citations remain mandatory when relevant.
- Preset rationales are audit templates, not scientific evidence. Placeholders and unspecified study-specific values remain workflow blockers.

## Statistical scope

- No JAGS model file, primary likelihood, prior-resolution formula, probability formula, JAGS fitting routine, MCMC diagnostic formula, or posterior plotting formula was changed.
- `R/06_sensitivity.R` changes only review/checklist semantics around sensitivity completion; the `run_prior_sensitivity()` fitting loop is unchanged.
- `R/08_reporting.R` changes report-readiness logic so advisory sensitivity-diagnostic warnings do not masquerade as hard failures.
- Windows R 4.4.1/JAGS 4.3.1 runtime regression for these new UI/server paths remains required before dropping the candidate label.
