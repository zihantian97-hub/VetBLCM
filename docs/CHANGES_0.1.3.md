# VetBLCM 0.1.3 candidate changes

## Scope

This candidate adds sequential page-level workflow validation and navigation gating. It does not change the BLCM likelihoods, JAGS models, prior parameterization, posterior summaries, diagnostic thresholds or sensitivity-analysis calculations.

## Workflow behaviour

- All 13 pages are ordered. The next page is unlocked only after the current page passes validation.
- Sidebar navigation cannot skip into a page that has not been unlocked with Next.
- Moving forward through previously unlocked pages rechecks all earlier prerequisites; invalidating an earlier step sends the user back to the first failed prerequisite.
- Each page displays a bilingual validation panel with blocking errors and non-blocking warnings.
- Data QC, posterior results and comparator agreement now include explicit user-review acknowledgements.
- Existing confirmations for population design, prior independence, class interpretation, diagnostics and sensitivity review remain mandatory at their respective steps.
- The Export page passes only after the current analysis ID has been saved through the R direct-to-filesystem export route.

## Scientific gates

Hard blockers include missing required metadata; missing or invalid input data; fewer than two populations; incomplete population definitions or study-design confirmations; mixed-specimen or within-herd designs unsupported by the basic likelihood; invalid priors or undocumented informative priors; unsupported dependent-model design; stale or missing model fits; failed MCMC convergence/ESS targets; missing manual diagnostic review; incomplete sensitivity analysis; and failure to save the current fit locally. Valid data warnings such as zero cells or small sample flags remain visible but do not automatically block progression.

## Validation status

Static source/package checks are performed in the build environment. `scripts/test_workflow_gating.R` provides a Shiny server regression for the new gates. Because the current build environment has no Windows R/JAGS runtime, the final interactive Next/sidebar behaviour must be exercised on Windows R 4.4.1/JAGS 4.3.1 before promotion from candidate.
