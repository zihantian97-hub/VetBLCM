testthat::test_that("Local export writes a self-contained run directory without exposing its root", {
  source_fit<-file.path(getOption("vetblcm.root"),"validation","dependent_fit.rds")
  testthat::skip_if_not(file.exists(source_fit))
  f<-readRDS(source_fit);f$metadata$project_name<-"Local export test"
  root<-tempfile("vetblcm-local-");dir.create(root);on.exit(unlink(root,recursive=TRUE,force=TRUE),add=TRUE)
  saved<-save_analysis_local(f,root,all_figures=FALSE)
  testthat::expect_match(basename(dirname(saved$directory)),"^[0-9]{4}-[0-9]{2}-[0-9]{2}$");testthat::expect_match(basename(saved$directory),"^run_")
  testthat::expect_true(dir.exists(saved$directory));testthat::expect_true(file.exists(saved$bundle))
  expected<-c("analysis.rds","posterior_summary.csv","posterior_contrasts.csv","sample_flow.csv","STARD_BLCM_reporting_audit.csv","analysis_summary.json","analysis_summary.csv","model_used.jags","analysis_settings.json","sessionInfo.txt","VetBLCM_results.xlsx","report.html","local_export_manifest.json")
  testthat::expect_true(all(file.exists(file.path(saved$directory,expected))))
  manifest<-jsonlite::read_json(file.path(saved$directory,"local_export_manifest.json"),simplifyVector=TRUE)
  testthat::expect_false(any(grepl(normalizePath(root,winslash="/",mustWork=TRUE),manifest$files$path,fixed=TRUE)))
  entries<-utils::unzip(saved$bundle,list=TRUE)$Name
  testthat::expect_true(all(expected %in% entries));testthat::expect_false(any(grepl("(^/|^[A-Za-z]:|(^|/)\\.\\.(/|$))",entries)))
  saved2<-save_analysis_local(f,root,all_figures=FALSE)
  testthat::expect_true(identical(saved$directory,saved2$directory))
})


testthat::test_that("Windows folder chooser prefers a PowerShell .NET dialog", {
  root<-getOption("vetblcm.root",".")
  code<-paste(readLines(file.path(root,"R","10_local_export.R"),warn=FALSE,encoding="UTF-8"),collapse="\n")
  testthat::expect_match(code,"FolderBrowserDialog",fixed=TRUE)
  testthat::expect_match(code,'-STA',fixed=TRUE)
  testthat::expect_match(code,'utils::choose.dir',fixed=TRUE)
})
