testthat::test_that("Reports use frozen run settings and escape supplied content", {
  fpath<-file.path(getOption("vetblcm.root"),"validation","dependent_fit.rds")
  testthat::skip_if_not(file.exists(fpath))
  f<-readRDS(fpath);f$metadata$pathogen<-"<script>alert(1)</script>";f$settings$chains<-3
  text<-methods_text(f);testthat::expect_match(text,"3 chains",fixed=TRUE)
  path<-tempfile(fileext=".html");export_blcm_report(f,path,figures=FALSE);x<-paste(readLines(path,warn=FALSE,encoding="UTF-8"),collapse="\n")
  testthat::expect_false(grepl("<script>alert(1)</script>",x,fixed=TRUE));testthat::expect_true(grepl("&lt;script&gt;",x,fixed=TRUE))
  testthat::expect_match(x,"DO NOT REPORT AS FINAL",fixed=TRUE);testthat::expect_match(x,"document.documentElement.lang='zh'",fixed=TRUE);unlink(path)
})
testthat::test_that("Saved MCMC output can be analysed without an already loaded engine", {
  path<-file.path(getOption("vetblcm.root"),"validation","dependent_fit.rds");testthat::skip_if_not(file.exists(path));f<-readRDS(path)
  testthat::expect_true(all(is.finite(summarise_blcm(f)$Median)))
  a<-run_posterior_predictive_check(f,n_draws=60,seed=8);b<-run_posterior_predictive_check(f,n_draws=60,seed=8)
  testthat::expect_equal(a,b);testthat::expect_equal(nrow(a$table),nrow(f$cross)*4)
  testthat::expect_true(all(a$table$Lower>=0));testthat::expect_true(all(a$table$Upper<=rep(f$cross$N,each=4)))
})
testthat::test_that("Prior population matching prevents silently swapped prevalence priors", {
  p<-prior_template(c("A","B"));p$Population[5:6]<-c("B","A")
  testthat::expect_error(resolve_priors(p,c("A","B")),"mismatch")
})
testthat::test_that("Incomplete sensitivity or absent human review never passes final checks", {
  path<-file.path(getOption("vetblcm.root"),"validation","dependent_fit.rds");testthat::skip_if_not(file.exists(path));f<-readRDS(path)
  ch<-review_checklist(f);testthat::expect_false(all(ch$Pass));testthat::expect_false(ch$Pass[ch$Check=="Sensitivity_completed"]);testthat::expect_false(ch$Pass[ch$Check=="Visual_pathology_review"])
  f$adapted<-FALSE;testthat::expect_false(diagnose_blcm(f)$acceptable)
})
