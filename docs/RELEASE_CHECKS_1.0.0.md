# Version 1.0.0 release checks

Checked on 2026-11-06 using local R 4.4.1 and JAGS 4.3.1.

- Complete simulated example (`scripts/run_example.R`): completed; independent and positive-dependence fits, two prior-sensitivity scenarios and report export ran successfully.
- Independent and dependent simulated parameter recovery scripts: passed their programmed checks. These are single simulated recovery checks, not coverage studies or evidence of identifiability.
- `scripts/run_tests.R`: 179 expectations passed, 0 failures, 0 warnings, 0 skips in the final unit-test run.
- The separate historical `scripts/test_app.R` Shiny mock-session script failed at its expectation that a server-side input update immediately changes `input$project_name`. The Shiny UI has not been visually validated for this archival release. This script is retained unchanged as an outstanding verification item.
- An initial run inherited the unsupported Windows locale `LC_ALL=C.UTF-8`, causing UTF-8 source loading to fail. Clearing that inherited variable before launching R resolved source loading; application/model source files were not changed.
- All 18 files under `R/`, `modules/` and `models/` match the supplied 0.1.10 files byte for byte.

This release changes distribution metadata, documentation and the test/package entry points. It does not change statistical calculations. Historical audit documents retain their original dates and scope.
