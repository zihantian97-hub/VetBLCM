# Regression for direct Page-10 alternative-prior upload and warning-only MCMC failure handling.
# No JAGS fit is performed; a minimal current-fit object and fake sensitivity results are used.
Sys.unsetenv("LC_ALL")
source("R/load.R",encoding="UTF-8");load_vetblcm()
source("modules/mod_layout.R",encoding="UTF-8")
source("modules/mod_server.R",encoding="UTF-8")

shiny::testServer(app_server, {
  session$setInputs(language="zh",page="sensitivity",model_type="positive",unit="sample",purpose="research",
    prior_type="alpha_beta",prior_parameter="Se1",prior_alpha=1,prior_beta=1,prior_lower=0,prior_upper=1,
    prior_mean=.5,prior_ess=2,mcmc_mode="final",chains=4,adapt=2000,burnin=5000,iterations=10000,thin=1,seed=33,
    review_sensitivity=FALSE,review_sensitivity_failed=FALSE)
  pop<-c("Low","Medium","High")
  main_raw<-prior_template(pop)
  main_raw$Rationale<-ifelse(main_raw$Source_type=="weak/reference","Weak/reference prior","Independent external prior")
  main<-resolve_priors(main_raw,pop,"positive")$table
  rv$fit<-list(id="fake-main",model="positive",cross=data.frame(Population=pop),priors=list(table=main),diagnostics=list(acceptable=TRUE))

  alt<-main
  i<-match("Se2",alt$Parameter);alt$Alpha[i]<-16;alt$Beta[i]<-4;alt$Mean[i]<-NA_real_;alt$ESS[i]<-NA_real_
  alt$Source_type[i]<-"literature";alt$Source[i]<-"Independent external demonstration source"
  alt$Rationale[i]<-"Independent alternative evidence used only for sensitivity regression testing"
  tmp<-tempfile(fileext=".csv");utils::write.csv(alt,tmp,row.names=FALSE,fileEncoding="UTF-8")
  upload<-data.frame(name="Alternative.csv",size=file.info(tmp)$size,type="text/csv",datapath=tmp,stringsAsFactors=FALSE)
  session$setInputs(scenario_upload=upload,scenario_name="Alternative");session$flushReact()
  z<-scenario_upload_info();stopifnot(isTRUE(z$valid),"Se2"%in%z$changed)
  session$setInputs(add_uploaded_scenario=1);session$flushReact();stopifnot("Alternative"%in%names(rv$scenarios))
  session$setInputs(add_weak=1);session$flushReact();stopifnot(all(c("Weak","Alternative")%in%names(rv$scenarios)))

  fake_fit<-function(ok)list(diagnostics=list(acceptable=ok))
  rv$sensitivity<-list(main_id="fake-main",requested=c("Alternative","Weak"),priors=rv$scenarios,
    fits=list(Alternative=fake_fit(TRUE),Weak=fake_fit(FALSE)),table=data.frame(Parameter="Se1",Scenario=c("Alternative"),Diagnostics_pass=TRUE),failures=data.frame())
  session$flushReact()
  v<-page_validation("sensitivity");stopifnot(!v$valid,any(grepl("审阅未通过MCMC|reviewed the scenarios",v$errors)))
  session$setInputs(review_sensitivity=TRUE,review_sensitivity_failed=TRUE);session$flushReact()
  v<-page_validation("sensitivity");stopifnot(v$valid,length(v$warnings)>0,any(grepl("未通过MCMC|failed MCMC",v$warnings)))
})
cat("DIRECT SENSITIVITY-UPLOAD AND WARNING-GATE REGRESSION PASSED\n")
