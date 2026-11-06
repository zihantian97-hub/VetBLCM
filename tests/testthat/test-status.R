testthat::test_that("Scientific blockers prevent a numerically converged result appearing final", {
  path<-file.path(getOption("vetblcm.root"),"validation","dependent_fit.rds")
  testthat::skip_if_not(file.exists(path))
  f<-readRDS(path)
  testthat::expect_true(f$diagnostics$acceptable)
  f$design$blockers<-character()
  testthat::expect_identical(analysis_status(f)$level,"yellow")
  f$design$blockers<-"Population grouping was based on current test results"
  testthat::expect_identical(analysis_status(f)$level,"red")
  testthat::expect_match(analysis_status(f)$label,"DO NOT REPORT AS FINAL",fixed=TRUE)
  f$design$blockers<-character();f$diagnostics$acceptable<-FALSE
  testthat::expect_identical(analysis_status(f)$level,"red")
})

testthat::test_that("Missing source evidence cannot be labelled as literature-derived", {
  p<-prior_template(c("A","B"));p$Source_type[1]<-"literature";p$Source[1]<-""
  z<-resolve_priors(p,c("A","B"),"positive")
  testthat::expect_identical(z$table$Source_type[1],"subjective/expert")
})
