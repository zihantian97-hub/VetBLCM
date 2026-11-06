# VetBLCM 0.1.4 candidate changes

## Scope

Version 0.1.4 adds publication-oriented documentation and derived summaries. It does **not** change the BLCM likelihoods, JAGS model files, prior parameterization, MCMC sampler, posterior summaries, diagnostic thresholds or sensitivity-analysis refits.

## New study documentation

- T1 and T2 positivity rules are required study metadata.
- Handling of equivocal/borderline, invalid and missing results is required and retained in exports.
- The data-import step records total samples assessed, exclusion counts/reasons and the sample-size rationale before modelling.
- Source population is now required study metadata.

## Single-analyte publication outputs

- Sample-flow table and flow diagram are generated from recorded sample counts and population sizes. The software never invents exclusion reasons.
- Posterior contrasts are calculated from paired posterior draws: `Delta_DSe = Se1-Se2` and `Delta_DSp = Sp1-Sp2`, with posterior mean, median, 95% credible interval and `Pr(T1>T2)`.
- A STARD-BLCM reporting audit maps available VetBLCM records to high-level reporting topics from Kostoulas et al. (2017). It is explicitly labelled as a software mapping aid and is not a verbatim reproduction of the official checklist.
- Excel/HTML/local-export bundles include test rules, sample flow, posterior contrasts, the reporting audit and a compact `analysis_summary.json`.

## Multi-analyte project summary

Each analyte continues to be fitted separately. Every completed local run writes `analysis_summary.json`. The Publication page can scan prior runs under the same project directory, retain the latest saved run for each analyte, and produce a project-level table plus a DSe/DSp forest plot. These outputs are display summaries only: no cross-analyte likelihood, meta-analysis, pooling or overall panel DSe/DSp is calculated.

## Validation status

Static source/package checks can be performed in the build environment. `scripts/test_publication_outputs.R` and `tests/testthat/test-publication-outputs.R` exercise the new derived-output functions without refitting JAGS. Final Windows R 4.4.1/JAGS 4.3.1 interactive regression remains required before promotion from candidate.
