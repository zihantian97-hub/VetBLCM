# Regression for the 0.1.1 direct-to-filesystem export path. Reuses saved draws; no model refit.
Sys.unsetenv("LC_ALL")
source("R/load.R",encoding="UTF-8");load_vetblcm()
f<-readRDS("validation/dependent_fit.rds");f$metadata$project_name<-"Local export regression"
root<-tempfile("vetblcm_local_export_");dir.create(root);on.exit(unlink(root,recursive=TRUE,force=TRUE),add=TRUE)
z<-save_analysis_local(f,root,all_figures=FALSE)
parts<-strsplit(normalizePath(z$directory,winslash="/",mustWork=TRUE),"/",fixed=TRUE)[[1]];stopifnot(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",parts[length(parts)-1]),grepl("^run_",basename(z$directory)))
stopifnot(dir.exists(z$directory),file.exists(z$bundle),nchar(z$bundle_sha256)==64)
needed<-c("analysis.rds","posterior_summary.csv","posterior_contrasts.csv","sample_flow.csv","STARD_BLCM_reporting_audit.csv","analysis_summary.json","analysis_summary.csv","model_used.jags","analysis_settings.json","sessionInfo.txt","VetBLCM_results.xlsx","report.html","local_export_manifest.json")
stopifnot(all(file.exists(file.path(z$directory,needed))))
manifest<-jsonlite::read_json(file.path(z$directory,"local_export_manifest.json"),simplifyVector=TRUE)
stopifnot(!any(grepl(normalizePath(root,winslash="/",mustWork=TRUE),manifest$files$path,fixed=TRUE)))
entries<-utils::unzip(z$bundle,list=TRUE)$Name
stopifnot(all(needed %in% entries),!any(grepl("(^/|^[A-Za-z]:|(^|/)\\.\\.(/|$))",entries)))
con<-unz(file.path(z$directory,"VetBLCM_results.xlsx"),"xl/worksheets/sheet6.xml",open="rb");xml<-rawToChar(readBin(con,"raw",n=1e6));close(con)
stopifnot(grepl('<dimension\\s+ref="A1:[A-Z]+(?:[2-9]|[1-9][0-9]+)"\\s*/>',xml,perl=TRUE))
z2<-save_analysis_local(f,root,all_figures=FALSE);stopifnot(identical(z$directory,z2$directory))
cat("DIRECT LOCAL EXPORT REGRESSION PASSED\n")
