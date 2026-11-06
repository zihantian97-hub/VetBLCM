# Regression for the 0.1.8 advisory-first workflow. No JAGS fit is required.
Sys.unsetenv("LC_ALL")
source("R/load.R",encoding="UTF-8");load_vetblcm()
source("modules/mod_layout.R",encoding="UTF-8")
source("modules/mod_server.R",encoding="UTF-8")
shiny::testServer(app_server, {
  session$setInputs(language="zh",page="project",unit="sample",purpose="research",
    prior_type="alpha_beta",prior_parameter="Se1",prior_alpha=1,prior_beta=1,
    prior_lower=0,prior_upper=1,prior_mean=.5,prior_ess=2,
    mcmc_mode="preview",chains=4,adapt=500,burnin=1000,iterations=2000,thin=1,seed=33,
    model_type="positive",grouping_independent=FALSE,procedures_comparable="uncertain",
    independent_sampling=FALSE,priors_independent=FALSE,label_confirmed=FALSE,
    expert_override=FALSE,label_rationale="",override_rationale="",qc_reviewed=FALSE)
  session$flushReact()
  stopifnot(!page_validation("project")$valid, length(page_hard_blockers("project"))==0L)
  stopifnot(length(page_hard_blockers("data"))>0L)

  d<-data.frame(Population=c("Low","Medium","High"),n11=c(5,15,30),n10=c(2,3,4),n01=c(1,4,6),n00=c(92,78,60))
  set_data(d,"aggregated");session$setInputs(samples_assessed=300);session$flushReact()
  stopifnot(length(page_hard_blockers("data"))==0L)
  stopifnot(!page_validation("data")$valid) # missing narrative fields are advisory, not blockers
  stopifnot(!page_validation("qc")$valid, length(page_hard_blockers("qc"))==0L) # unchecked review remains advisory
  stopifnot(length(page_hard_blockers("run"))>0L) # no fit is a true technical blocker
})
cat("ADVISORY-FIRST WORKFLOW REGRESSION PASSED\n")
