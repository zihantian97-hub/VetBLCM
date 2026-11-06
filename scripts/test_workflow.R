# Exercise the actual Shiny observers and JAGS backend on simulated data.
# Short runs validate wiring, not statistical recovery or final convergence.
Sys.unsetenv("LC_ALL")
source("R/load.R",encoding="UTF-8");load_vetblcm()
source("modules/mod_layout.R",encoding="UTF-8")
source("modules/mod_server.R",encoding="UTF-8")
shiny::testServer(app_server, {
  session$setInputs(language="en",page="data",prior_parameter="Se1",
    prior_type="alpha_beta",prior_alpha=1,prior_beta=1,prior_lower=0,prior_upper=1,
    prior_mean=.5,prior_ess=2,mcmc_mode="preview",chains=4,adapt=500,
    burnin=1000,iterations=2000,thin=1,seed=1919,model_type="positive",
    plot_type="density",plot_parameter="Se1",figure_format="png",
    unit="sample",purpose="research",procedures_comparable="yes")
  # Import through the same file-upload observer used by the interface.
  session$setInputs(data_file=list(datapath=normalizePath("examples/example_sample_level.xlsx")),
    sheet="Data",data_mode="sample",load_file=1)
  session$flushReact()
  stopifnot(qc()$valid,nrow(rv$data)==6000,nrow(cross())==3)
  session$setInputs(prior_upload=list(datapath=normalizePath("examples/simulated_priors.csv")))
  session$flushReact()
  stopifnot(rv$priors$Alpha[3]>1)
  session$setInputs(run_both=1);session$flushReact()
  stopifnot(all(c("independent","positive") %in% names(rv$comparison)),
    all(vapply(rv$comparison,inherits,logical(1),"vetblcm_fit")),
    current_fit()$model=="positive",nrow(current_fit()$summary)==11,
    identical(rv$comparison$independent$provenance$input_sha256,
      rv$comparison$positive$provenance$input_sha256))
  stopifnot(nrow(compare_models(rv$comparison$independent,rv$comparison$positive))==7)
  cat("WORKFLOW: Excel/prior uploads and independent/positive JAGS runs passed.\n")
  original_hash<-sha256(current_fit()$draws)
  for(parameter in c("Se1","Prev[2]","CovH")) {
    session$setInputs(plot_parameter=parameter);session$flushReact()
    result<-output$diagnostic_plot
    stopifnot(is.list(result),!is.null(result$src))
    path<-output$figure_download
    stopifnot(file.exists(path),file.info(path)$size>1000)
  }
  session$setInputs(language="zh");session$flushReact()
  stopifnot(identical(sha256(current_fit()$draws),original_hash),
    !is.null(output$reliability),!is.null(output$result_narrative),
    !is.null(output$agreement_table),!is.null(output$comparison_table))
  cat("WORKFLOW: selected-parameter plots, result/diagnostic tables and language invariance passed.\n")
  session$setInputs(add_weak=1);session$flushReact()
  alternative<-rv$priors
  alternative$Alpha[3:4]<-alternative$Alpha[3:4]/2
  alternative$Beta[3:4]<-alternative$Beta[3:4]/2
  alternative$Rationale[3:4]<-"SIMULATED workflow test: halve external information"
  rv$scenarios<-c(rv$scenarios,list(Alternative=alternative))
  session$setInputs(run_sensitivity=1);session$flushReact()
  stopifnot(identical(rv$sensitivity$main_id,current_fit()$id),
    length(rv$sensitivity$fits)==2,nrow(rv$sensitivity$failures)==0,
    nrow(rv$sensitivity$table)==22,
    all(c("Weak","Alternative") %in% names(rv$sensitivity$fits)))
  checks<-review_checklist(current_fit(),rv$comparison,rv$sensitivity)
  stopifnot(!checks$Pass[checks$Check=="Final_mode"],!all(checks$Pass))
  cat("WORKFLOW: Weak/Alternative refits passed; preview analysis remains exploratory.\n")
  summary<-do.call(rbind,lapply(c(rv$comparison,rv$sensitivity$fits),function(f)
    data.frame(Model=f$model,Mode=f$settings$mode,Chains=f$settings$chains,
      Iterations=f$settings$iterations,Seed=f$settings$seed,
      Rhat_max=max(f$diagnostics$table$rhat),ESS_min=min(f$diagnostics$table$ess_bulk,f$diagnostics$table$ess_tail),
      Diagnostics_pass=f$diagnostics$acceptable)))
  print(summary)
  write.csv(summary,file.path("validation",paste0("workflow_runs_",format(Sys.Date(),"%Y%m%d"),".csv")),row.names=TRUE)
})
cat("SHINY/JAGS WORKFLOW SERVER REGRESSION PASSED\n")
