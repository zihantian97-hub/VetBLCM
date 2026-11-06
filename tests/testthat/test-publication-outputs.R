testthat::test_that("posterior contrasts use paired posterior draws", {
  set.seed(1)
  n <- 500
  m1 <- cbind(Se1=rbeta(n,.9*50,.1*50),Sp1=rbeta(n,.97*50,.03*50),Se2=rbeta(n,.85*50,.15*50),Sp2=rbeta(n,.95*50,.05*50))
  m2 <- cbind(Se1=rbeta(n,.9*50,.1*50),Sp1=rbeta(n,.97*50,.03*50),Se2=rbeta(n,.85*50,.15*50),Sp2=rbeta(n,.95*50,.05*50))
  fit <- list(draws=coda::mcmc.list(coda::mcmc(m1),coda::mcmc(m2)))
  z <- posterior_contrasts(fit)
  testthat::expect_equal(z$Measure,c("Delta_DSe","Delta_DSp"))
  allm <- rbind(m1,m2)
  testthat::expect_equal(z$Median[1],stats::median(allm[,"Se1"]-allm[,"Se2"]),tolerance=1e-12)
  testthat::expect_equal(z$Pr_T1_greater[2],mean(allm[,"Sp1"]-allm[,"Sp2"]>0),tolerance=1e-12)
})

testthat::test_that("sample flow never invents exclusions", {
  fit <- list(cross=data.frame(Population=c("Low","High"),n11=c(1,2),n10=c(1,1),n01=c(0,1),n00=c(8,5),N=c(10,9)),metadata=list(samples_assessed=20,source_population="Source",exclusion_notes="1 excluded",specimen="Specimen"))
  d <- sample_flow_table(fit)
  testthat::expect_equal(d$N[d$Stage=="Included in BLCM"],19)
  testthat::expect_equal(d$N[d$Stage=="Excluded before binary BLCM"],1)
})

testthat::test_that("single-analyte publication summary is one standardized row", {
  testthat::skip_if_not(file.exists(file.path(getOption("vetblcm.root"),"reports","example_analysis","analysis.rds")))
  z<-readRDS(file.path(getOption("vetblcm.root"),"reports","example_analysis","analysis.rds"))
  d<-analysis_publication_summary(z$fit,z$comparison,z$sensitivity,z$review)
  testthat::expect_equal(nrow(d),1L)
  testthat::expect_true(all(c("Analyte","DSe1_Median","DSe1_Lower","DSe1_Upper","DSp1_Median","DSp1_Lower","DSp1_Upper") %in% names(d)))
})
