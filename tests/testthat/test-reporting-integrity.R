testthat::test_that("Unknown screening totals remain unknown in tables and bilingual figures", {
  fit <- list(cross=data.frame(Population=c("A","B"),N=c(10,9)),metadata=list())
  for(value in list(NULL,NA_real_,"")) {
    fit$metadata$samples_assessed <- value
    d <- sample_flow_table(fit)
    testthat::expect_true(all(is.na(d$N[1:2])))
    testthat::expect_equal(d$N[3],19)
    testthat::expect_false(sample_flow_documented(fit))
  }
  for(lang in c("zh","en")) {
    p <- plot_sample_flow(fit,lang)
    labels <- p$layers[[2]]$data$label
    testthat::expect_true(any(grepl(if(lang=="zh")"未提供" else "Not provided",labels,fixed=TRUE)))
    testthat::expect_false(any(grepl("N = 0",labels,fixed=TRUE)))
  }
})

testthat::test_that("Inconsistent screening counts are rejected without silent correction", {
  fit <- list(cross=data.frame(Population=c("A","B"),N=c(10,9)),metadata=list())
  for(value in list(18,-1,19.5,Inf,"invalid",c(19,20))) {
    fit$metadata$samples_assessed <- value
    testthat::expect_error(sample_flow_table(fit),"whole number")
    testthat::expect_false(sample_flow_documented(fit))
  }
  fit$metadata$samples_assessed <- 19
  testthat::expect_equal(sample_flow_table(fit)$N[1:3],c(19,0,19))
  fit$metadata$samples_assessed <- 21
  testthat::expect_equal(sample_flow_table(fit)$N[1:3],c(21,2,19))
})

testthat::test_that("Prior documentation decisions agree across reporting checklists", {
  z <- readRDS(file.path(getOption("vetblcm.root"),"reports/example_analysis/analysis.rds"))
  f <- z$fit
  fields <- c("Source_type","Source","Rationale","Source_population","Specimen","Assay","Estimate","Uncertainty","Applicability","Discount")
  for(k in fields) f$priors$table[[k]] <- "Documented for regression fixture"
  for(field in c("none",fields)) {
    g <- f
    if(field!="none") g$priors$table[[field]] <- ""
    checks <- review_checklist(g)
    audit <- stard_blcm_reporting_audit(g)
    expected <- identical(field,"none")
    testthat::expect_identical(checks$Pass[checks$Check=="Priors_documented"],expected)
    testthat::expect_identical(audit$Status[audit$Section=="Priors"],if(expected)"Complete"else"Review")
    testthat::expect_identical(audit$Status[audit$Section=="Title/Abstract"],"Review")
  }
  testthat::expect_false(priors_documented(NULL))
  testthat::expect_false(priors_documented(data.frame()))
  p<-resolve_priors(prior_template(c("A","B")),c("A","B"))$table
  testthat::expect_true(priors_documented(p)) # unchanged rule for unrestricted uniform priors
})

testthat::test_that("Missing or invalid flow counts cannot pass final reporting review", {
  f <- readRDS(file.path(getOption("vetblcm.root"),"validation/dependent_fit.rds"))
  for(value in list(NULL,NA_real_,sum(f$cross$N)-1,sum(f$cross$N)+.5)) {
    f$metadata$samples_assessed <- value
    checks <- review_checklist(f)
    testthat::expect_false(checks$Pass[checks$Check=="Sample_flow_documented"])
    testthat::expect_true(checks$Required[checks$Check=="Sample_flow_documented"])
    audit <- stard_blcm_reporting_audit(f)
    testthat::expect_identical(audit$Status[audit$Section=="Sampling"],"Review")
  }
})

testthat::test_that("Unknown flow and missing prior sources survive Excel and HTML export honestly", {
  f <- readRDS(file.path(getOption("vetblcm.root"),"validation/dependent_fit.rds"))
  f$metadata$samples_assessed <- NULL
  f$priors$table$Source <- ""
  x <- tempfile(fileext=".xlsx"); h <- tempfile(fileext=".html")
  write_results_excel(f,x)
  d<-readxl::read_excel(x,sheet="Sample_Flow")
  testthat::expect_true(all(is.na(d$N[1:2])))
  a<-readxl::read_excel(x,sheet="STARD_BLCM_Audit")
  testthat::expect_identical(a$Status[a$Section=="Priors"],"Review")
  export_blcm_report(f,h,figures=FALSE)
  html<-paste(readLines(h,encoding="UTF-8",warn=FALSE),collapse="\n")
  testthat::expect_match(html,"Prior documentation missing",fixed=TRUE)
  testthat::expect_match(html,"Sample_flow_documented",fixed=TRUE)
  f$metadata$samples_assessed <- sum(f$cross$N)-1
  testthat::expect_error(write_results_excel(f,x),"whole number")
  testthat::expect_error(export_blcm_report(f,h,figures=FALSE),"whole number")
  unlink(c(x,h))
})
