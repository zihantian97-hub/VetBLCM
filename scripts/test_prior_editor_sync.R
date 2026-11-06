# Regression: unchanged parameter selection must still show newly loaded priors.
Sys.unsetenv("LC_ALL")
source("R/load.R",encoding="UTF-8");load_vetblcm()
source("modules/mod_layout.R",encoding="UTF-8")
source("modules/mod_server.R",encoding="UTF-8")
shiny::testServer(app_server, {
  updates<-list()
  session$sendInputMessage<-function(inputId,message) {
    if("value" %in% names(message)) updates[[inputId]]<<-message$value
  }
  session$setInputs(language="zh",prior_parameter="Se1",prior_type="mean_ess",
    prior_mean=.5,prior_ess=2,prior_alpha=1,prior_beta=1,prior_lower=0,prior_upper=1)
  session$setInputs(example=1);session$flushReact()
  stopifnot(identical(input$prior_parameter,"Se1"),
    identical(as.numeric(updates$prior_lower),.5),
    identical(updates$prior_type,"alpha_beta"),
    grepl("SIMULATED EXAMPLE",updates$prior_rationale,fixed=TRUE))
  cat("SAME-SELECTION EXAMPLE LOAD: existing truncation and provenance reached editor.\n")

  p<-rv$priors;p$Alpha[1]<-27;p$Beta[1]<-3;p$Lower[1]<-.2
  p$Source[1]<-"Simulated upload source";p$Rationale[1]<-"Simulated upload rationale"
  file<-tempfile(fileext=".csv");utils::write.csv(p,file,row.names=FALSE)
  updates<-list()
  session$setInputs(prior_upload=list(datapath=file));session$flushReact()
  stopifnot(identical(input$prior_parameter,"Se1"),
    identical(as.numeric(updates$prior_alpha),27),
    identical(as.numeric(updates$prior_beta),3),
    identical(as.numeric(updates$prior_lower),.2),
    identical(updates$prior_source,"Simulated upload source"))
  unlink(file)
  cat("SAME-SELECTION PRIOR IMPORT: updated distribution and source reached editor.\n")

  p$Alpha[1]<-18;p$Beta[1]<-2;p$Lower[1]<-.4
  p$Source[1]<-"Simulated saved-project source"
  updates<-list()
  restore_analyte(list(data=rv$data,mode=rv$mode,priors=p,populations=rv$populations,
    metadata=list(),scenarios=list(),review=list()))
  session$flushReact()
  stopifnot(identical(input$prior_parameter,"Se1"),
    identical(as.numeric(updates$prior_alpha),18),
    identical(as.numeric(updates$prior_lower),.4),
    identical(updates$prior_source,"Simulated saved-project source"))
  cat("SAME-SELECTION PROJECT RESTORE: saved prior replaced editor values.\n")

  # Alpha/Beta editing must not persist stale inactive Mean/ESS fields.
  session$setInputs(prior_type="alpha_beta",prior_alpha=27,prior_beta=3,
    prior_mean=.5,prior_ess=400,prior_lower=.4,prior_upper=1,
    prior_source_type="simulation",prior_source="Simulated editor test",
    prior_rationale="Simulation only",prior_source_pop="Simulated",
    prior_uncertainty="Not empirical")
  session$setInputs(save_prior=1);session$flushReact()
  stopifnot(rv$priors$Alpha[1]==27,rv$priors$Beta[1]==3,
    rv$priors$Mean[1]==.9,rv$priors$ESS[1]==30,
    as.numeric(updates$prior_ess)==30)
  cat("ALPHA/BETA SAVE: mean and ESS derive from the saved distribution, not stale inactive fields.\n")

  updates<-list();session$setInputs(use_weak=1);session$flushReact()
  stopifnot(identical(as.numeric(updates$prior_alpha),1),
    identical(as.numeric(updates$prior_beta),1),
    identical(as.numeric(updates$prior_lower),.4),
    identical(updates$prior_source_type,"weak/reference"),
    identical(updates$prior_source,""))
  cat("WEAK PRIOR: provenance cleared and explicit support preserved in editor.\n")
})
cat("PRIOR EDITOR SYNCHRONIZATION REGRESSION PASSED\n")
