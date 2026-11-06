# Real server handlers exercised with Shiny's supported mock session.
# This tests the R side; it does not substitute for browser visual acceptance.
Sys.unsetenv("LC_ALL")
source("R/load.R",encoding="UTF-8");load_vetblcm()
source("modules/mod_layout.R",encoding="UTF-8")
source("modules/mod_server.R",encoding="UTF-8")
shiny::testServer(app_server, {
  # Deliver server input-update messages as a browser normally would.
  messages<-list()
  numeric_inputs<-c("chains","adapt","burnin","iterations","thin","seed","samples_assessed",
    "prior_alpha","prior_beta","prior_mean","prior_ess","prior_lower","prior_upper")
  session$sendInputMessage<-function(inputId,message) {
    if("value" %in% names(message)) {
      value<-message$value
      if(inputId %in% numeric_inputs) value<-as.numeric(value)
      messages[[inputId]]<<-value
    }
  }
  settle<-function() {
    for(i in seq_len(20)) {
      session$flushReact()
      if(!length(messages)) return(invisible(NULL))
      next_inputs<-messages;messages<<-list()
      do.call(session$setInputs,next_inputs)
    }
    stop("Input updates failed to settle")
  }
  session$setInputs(language="zh",page="project",prior_parameter="Se1",
    prior_type="alpha_beta",prior_alpha=1,prior_beta=1,prior_lower=0,prior_upper=1,
    prior_mean=.5,prior_ess=2,prior_source_type="weak/reference",prior_source="",
    mcmc_mode="preview",chains=4,adapt=300,burnin=500,iterations=1000,thin=1,
    seed=33,model_type="positive",unit="sample",purpose="research")
  session$setInputs(example=1);settle()
  stopifnot(nrow(rv$data)==6000,qc()$valid)
  session$setInputs(pathogen="模拟分析物 A",mcmc_mode="final");settle()
  session$setInputs(adapt=2222,burnin=3333,iterations=7777,seed=781,
    review_visual=TRUE,review_ppc=TRUE,review_sensitivity=TRUE,
    review_identifiability=TRUE,review_notes="Saved review note")
  rv$scenarios[["Alternative A"]]<-rv$priors;settle()
  original_data<-rv$data;original_priors<-rv$priors
  original_settings<-settings();save_current_analyte();settle()

  d2<-data.frame(Sample_ID=c("001","002","003","004"),Population=c("A","A","B","B"),T1=c(0,1,0,1),T2=c(0,1,1,1))
  set_data(d2,"sample");settle()
  session$setInputs(pathogen="Simulated analyte B",model_type="independent",mcmc_mode="preview");settle()
  session$setInputs(iterations=1234,seed=91)
  project_file<-output$project_download
  stopifnot(file.exists(project_file))
  z<-jsonlite::read_json(project_file,simplifyVector=TRUE)
  stopifnot(length(z$analytes)==2,z$analytes[[1]]$settings$iterations==7777,
    identical(z$analytes[[2]]$data$Sample_ID,c("001","002","003","004")),
    is.null(z$analytes[[1]]$fit))
  rv$project<-list()
  session$setInputs(project_upload=list(datapath=project_file));settle()
  stopifnot(length(rv$project)==2,input$pathogen=="模拟分析物 A",
    isTRUE(all.equal(rv$data,original_data,check.attributes=FALSE)),
    isTRUE(all.equal(rv$priors,original_priors,check.attributes=FALSE)),
    isTRUE(all.equal(settings(),original_settings)),input$model_type=="positive",
    "Alternative A" %in% names(rv$scenarios),is.null(rv$fit),
    !input$review_visual,!input$review_ppc,!input$review_sensitivity,
    !input$review_identifiability,input$review_notes=="Saved review note")
  session$setInputs(saved_analyte="Simulated analyte B",load_analyte=1);settle()
  stopifnot(input$model_type=="independent",input$mcmc_mode=="preview",
    input$iterations==1234,input$seed==91,nrow(rv$data)==4,
    identical(rv$data$Sample_ID,c("001","002","003","004")),length(rv$scenarios)==0)
  cat("PROJECT ROUNDTRIP: two analytes, leading-zero IDs, priors, custom settings, scenarios and review reset passed.\n")

  # Reuse real saved posterior draws for export regression; no new fitting.
  f<-readRDS("validation/dependent_fit.rds")
  rv$fit<-f;rv$comparison<-NULL;rv$sensitivity<-NULL;settle()
  original_draw_hash<-sha256(f$draws)
  session$setInputs(language="en");settle()
  stopifnot(identical(sha256(current_fit()$draws),original_draw_hash))
  model_file<-output$model_download
  stopifnot(identical(paste(readLines(model_file,warn=FALSE,encoding="UTF-8"),collapse="\n"),f$model_code))
  csv_file<-output$csv_download
  stopifnot(isTRUE(all.equal(read.csv(csv_file),f$summary,check.attributes=FALSE)))
  excel_file<-output$excel_download
  sheet<-as.data.frame(readxl::read_excel(excel_file,sheet="Posterior_Summary"))
  stopifnot(is.numeric(sheet$Median),isTRUE(all.equal(sheet$Median,f$summary$Median)))
  rds_file<-output$rds_download
  stopifnot(identical(sha256(readRDS(rds_file)$fit$draws),original_draw_hash))
  cat("DOWNLOAD HANDLERS: model, CSV, numeric Excel, RDS and language invariance passed.\n")
  html_file<-output$report_download
  html<-paste(readLines(html_file,warn=FALSE,encoding="UTF-8"),collapse="\n")
  stopifnot(grepl("document.documentElement.lang='zh'",html,fixed=TRUE),
    grepl("document.documentElement.lang='en'",html,fixed=TRUE),
    grepl("DO NOT REPORT AS FINAL",html,fixed=TRUE))
  bundle_file<-output$bundle_download
  entries<-utils::unzip(bundle_file,list=TRUE)$Name
  stopifnot(all(c("analysis.rds","report.html","model_used.jags","analysis_settings.json",
    "posterior_contrasts.csv","sample_flow.csv","STARD_BLCM_reporting_audit.csv","analysis_summary.json",
    "VetBLCM_results.xlsx","figures/sample_flow.png","figures/diagnostics_all_parameters.pdf") %in% entries),
    any(grepl("^figures/.+\\.png$",entries)),
    !any(grepl("(^/|(^|/)\\.\\.(/|$))",entries)))
  cat("DOWNLOAD HANDLERS: bilingual HTML structure and complete ZIP paths passed.\n")
})
cat("PROJECT AND DOWNLOAD SERVER REGRESSION PASSED\n")
