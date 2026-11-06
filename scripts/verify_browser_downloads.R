# Verify actual files delivered by browser interactions, without refitting.
source("R/load.R",encoding="UTF-8");load_vetblcm()
directory<-"validation/browser_20260920"
analysis<-readRDS(file.path(directory,"VetBLCM_analysis.rds"))
fit<-analysis$fit
stopifnot(identical(fit$id,"20260920T141846.380_73e946ad30"),
  nrow(fit$data)==6000,fit$settings$chains==4,fit$settings$adapt==500,
  fit$settings$burnin==1000,fit$settings$iterations==2000,fit$settings$seed==20260920)
code<-paste(readLines(file.path(directory,"model_used.jags"),warn=FALSE),collapse="\n")
stopifnot(identical(code,fit$model_code),
  isTRUE(all.equal(read.csv(file.path(directory,"posterior_summary.csv")),fit$summary,check.attributes=FALSE)),
  identical(sha256(fit$draws),sha256(analysis$comparison$positive$draws)))
fits<-c(analysis$comparison,analysis$sensitivity$fits)
summary<-do.call(rbind,lapply(names(fits),function(name) {
  f<-fits[[name]];d<-f$diagnostics$table
  data.frame(Run=name,Model=f$model,Analysis_ID=f$id,
    Max_Rhat=max(d$rhat),Min_bulk_ESS=min(d$ess_bulk),Min_tail_ESS=min(d$ess_tail),
    Diagnostics_pass=f$diagnostics$acceptable,Draw_SHA256=sha256(f$draws))
}))
utils::write.csv(summary,file.path(directory,"actual_run_diagnostics.csv"),row.names=FALSE)
for(name in names(fits)) {
  f<-fits[[name]]
  utils::write.csv(f$summary,file.path(directory,paste0(name,"_posterior.csv")),row.names=FALSE)
}
alt<-analysis$sensitivity$fits$Alternative
stopifnot(!is.null(alt))
alt_rows<-alt$priors$table[alt$priors$table$Parameter %in% c("Se2","Sp2"),]
stopifnot(all(alt_rows$Alpha+alt_rows$Beta==200),all(alt_rows$ESS==200))
checks<-list(verified_utc=format(Sys.time(),tz="UTC",usetz=TRUE),
  analysis_id=fit$id,browser_downloads=c("model_used.jags","posterior_summary.csv","VetBLCM_analysis.rds"),
  sample_rows=nrow(fit$data),settings=fit$settings,model_matches=TRUE,
  csv_matches_saved_posterior=TRUE,main_draws_match_positive_comparison=TRUE,
  alternative_comparator_concentration=200,alternative_recorded_ESS_matches=TRUE,
  fits=summary,classification="Short browser workflow fits; not recovery/calibration evidence",
  original_recovery_and_pilot_rerun=FALSE)
jsonlite::write_json(checks,file.path(directory,"download_verification.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA)
print(summary)
cat("ACTUAL BROWSER DOWNLOAD CONTENT CHECKS PASSED\n")

sheet<-as.data.frame(readxl::read_excel(file.path(directory,"VetBLCM_results.xlsx"),sheet="Posterior_Summary"))
stopifnot(is.numeric(sheet$Median),isTRUE(all.equal(sheet$Median,fit$summary$Median)))
html_path<-file.path(directory,paste0("VetBLCM_",fit$id,".html"))
html<-paste(readLines(html_path,warn=FALSE,encoding="UTF-8"),collapse="\n")
stopifnot(grepl("document.documentElement.lang='zh'",html,fixed=TRUE),
  grepl("document.documentElement.lang='en'",html,fixed=TRUE),
  grepl("DO NOT REPORT AS FINAL",html,fixed=TRUE),grepl(fit$id,html,fixed=TRUE))
bundle<-file.path(directory,paste0("VetBLCM_",fit$id,".zip"))
entries<-utils::unzip(bundle,list=TRUE)$Name
stopifnot(all(c("analysis.rds","report.html","model_used.jags","analysis_settings.json",
  "VetBLCM_results.xlsx","figures/diagnostics_all_parameters.pdf") %in% entries),
  !any(grepl("(^/|(^|/)\\.\\.(/|$))",entries)))
unpacked<-tempfile("browser_bundle_");dir.create(unpacked)
utils::unzip(bundle,exdir=unpacked)
nested<-readRDS(file.path(unpacked,"analysis.rds"))
stopifnot(identical(sha256(nested$fit$draws),sha256(fit$draws)))
figure<-png::readPNG(file.path(directory,"density.png"))
stopifnot(all(dim(figure)[1:2]==c(900,1620)))
checks$browser_downloads<-c(checks$browser_downloads,"VetBLCM_results.xlsx",basename(html_path),basename(bundle),"density.png")
checks$excel_posterior_matches<-TRUE
checks$html_bilingual_structure_and_warning<-TRUE
checks$bundle_draws_match<-TRUE
checks$bundle_entries<-entries
checks$density_png_dimensions<-dim(figure)
checks$html_visual_acceptance<-"pending; content checks do not establish visual correctness"
jsonlite::write_json(checks,file.path(directory,"download_verification.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA)
cat("BROWSER EXCEL, HTML, ZIP AND PNG CONTENT CHECKS PASSED\n")
