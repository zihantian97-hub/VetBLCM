# Run from the project root. Generate simulated fixtures when absent.
source("R/load.R", encoding = "UTF-8")
load_vetblcm()
if (!file.exists("validation/dependent_fit.rds")) source("scripts/verify_dependent.R", encoding = "UTF-8")
if (!file.exists("reports/example_analysis/analysis.rds")) source("scripts/run_example.R", encoding = "UTF-8")
if (!file.exists("validation/independent_fit.rds")) source("scripts/verify_independent.R", encoding = "UTF-8")
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
