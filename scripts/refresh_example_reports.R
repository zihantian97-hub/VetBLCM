# Refresh presentation artifacts from archived posterior draws; never refit or alter the saved analysis.
source("R/load.R",encoding="UTF-8");load_vetblcm()
folder<-file.path("reports","example_analysis")
saved<-file.path(folder,"analysis.rds")
before<-sha256_file(saved)
z<-readRDS(saved)
write_results_excel(z$fit,file.path(folder,"VetBLCM_results.xlsx"),z$comparison,z$sensitivity,z$review)
export_blcm_report(z$fit,file.path(folder,"report.html"),z$comparison,z$sensitivity,z$review)
write.csv(sample_flow_table(z$fit),file.path(folder,"sample_flow.csv"),row.names=FALSE,na="NA")
write.csv(stard_blcm_reporting_audit(z$fit,z$comparison,z$sensitivity,z$review),file.path(folder,"STARD_BLCM_reporting_audit.csv"),row.names=FALSE)
stopifnot(identical(before,sha256_file(saved)))
jsonlite::write_json(list(saved_analysis_sha256=before,posterior_unchanged=TRUE,new_mcmc_fits=0),
  "validation/repair_0.1.10/example_refresh.json",pretty=TRUE,auto_unbox=TRUE)
cat("EXAMPLE REPORTS REFRESHED; SAVED ANALYSIS UNCHANGED\n")
