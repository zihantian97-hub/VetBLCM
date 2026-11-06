Sys.unsetenv("LC_ALL")
source("R/load.R");load_vetblcm()
args<-commandArgs(TRUE);reps<-if(length(args))as.integer(args[1]) else 20L
dir.create("validation",showWarnings=FALSE);dir.create("validation/runs",showWarnings=FALSE)
root<-normalizePath(".")
scenarios<-list(independence=list(model="independent",n=1000,p=c(.06,.30,.70),cD=0,cH=0),positive=list(model="positive",n=1000,p=c(.06,.30,.70),cD=.04,cH=.015),low_prevalence=list(model="positive",n=1000,p=c(.005,.02,.06),cD=.04,cH=.015),weak_separation=list(model="positive",n=1000,p=c(.18,.20,.22),cD=.04,cH=.015),small_sample=list(model="positive",n=60,p=c(.06,.30,.70),cD=.04,cH=.015),zero_cell=list(model="positive",n=40,p=c(.002,.01,.03),cD=.04,cH=.015),signed=list(model="signed",n=1000,p=c(.06,.30,.70),cD=-.005,cH=-.001))
tasks<-expand.grid(Scenario=names(scenarios),Replicate=seq_len(reps),stringsAsFactors=FALSE)
worker<-function(i) {
  task<-tasks[i,];s<-scenarios[[task$Scenario]];seed<-10000+i*137
  truth<-c(Se1=.9,Sp1=.97,Se2=.84,Sp2=.95,`Prev[1]`=s$p[1],`Prev[2]`=s$p[2],`Prev[3]`=s$p[3],CovD=s$cD,CovH=s$cH)
  dat<-simulate_blcm(rep(s$n,3),s$p,.9,.97,.84,.95,s$cD,s$cH,seed=seed,populations=c("A","B","C"))
  pri<-prior_template(dat$Population);pri$Lower[1:2]<-.5
  if(s$model!="independent") {pri$Alpha[3:4]<-c(.84,.95)*400;pri$Beta[3:4]<-(1-c(.84,.95))*400;pri$Source_type[3:4]<-"simulation";pri$Source[3:4]<-"Simulated external prior";pri$Rationale[3:4]<-"Known generating scenario, not an application default"}
  t<-Sys.time()
  f<-tryCatch(run_blcm(dat,pri,"aggregated",s$model,settings=mcmc_settings("final",adapt=1500,burnin=4000,iterations=12000,seed=seed+9)),error=function(e)e)
  if(inherits(f,"error")) out<-data.frame(Scenario=task$Scenario,Replicate=task$Replicate,Parameter=names(truth),Truth=truth,Median=NA_real_,Lower=NA_real_,Upper=NA_real_,Covered=NA,Convergence=FALSE,Rhat_max=NA_real_,ESS_min=NA_real_,Error=conditionMessage(f),Zero_cell=any(as.matrix(dat[2:5])==0),Seconds=as.numeric(difftime(Sys.time(),t,units="secs"))) else {
    x<-f$summary[f$summary$Parameter %in% names(truth),];out<-data.frame(Scenario=task$Scenario,Replicate=task$Replicate,Parameter=x$Parameter,Truth=unname(truth[x$Parameter]),Median=x$Median,Lower=x$Lower,Upper=x$Upper,Covered=x$Lower<=truth[x$Parameter]&x$Upper>=truth[x$Parameter],Convergence=f$diagnostics$acceptable,Rhat_max=max(f$diagnostics$table$rhat),ESS_min=min(f$diagnostics$table$ess_bulk,f$diagnostics$table$ess_tail),Error="",Zero_cell=any(as.matrix(dat[2:5])==0),Seconds=f$elapsed_seconds)
  }
  write.csv(out,file.path(root,"validation","runs",paste0(task$Scenario,"_",task$Replicate,".csv")),row.names=FALSE)
  out
}
cl<-parallel::makePSOCKcluster(2,outfile=file.path(root,"validation","worker.log"))
parallel::clusterExport(cl,c("root","scenarios","tasks","worker"),envir=environment())
parallel::clusterEvalQ(cl,{Sys.unsetenv("LC_ALL");setwd(root);source("R/load.R");load_vetblcm();NULL})
out<-tryCatch(parallel::parLapplyLB(cl,seq_len(nrow(tasks)),worker),finally=parallel::stopCluster(cl))
d<-do.call(rbind,out);write.csv(d,"validation/simulation_all_runs.csv",row.names=FALSE)
summary<-do.call(rbind,lapply(split(d,paste(d$Scenario,d$Parameter)),function(x) {
  valid<-is.finite(x$Median);cv<-x$Covered[valid];bias<-x$Median[valid]-x$Truth[valid]
  data.frame(Scenario=x$Scenario[1],Parameter=x$Parameter[1],Replicates=nrow(x),Successful_fits=sum(valid),Convergence_rate=mean(x$Convergence),Coverage_among_completed=if(length(cv))mean(cv) else NA,Coverage_MCSE=if(length(cv))sqrt(mean(cv)*(1-mean(cv))/length(cv))else NA,Covered_over_all_runs=sum(cv)/nrow(x),Bias=if(length(bias))mean(bias)else NA,RMSE=if(length(bias))sqrt(mean(bias^2))else NA,Mean_CrI_width=mean(x$Upper-x$Lower,na.rm=TRUE))
}))
write.csv(summary,"validation/simulation_summary.csv",row.names=FALSE)
# Apply the same uncertainty and failure accounting as the shipped evidence.
source("scripts/summarise_validation.R",encoding="UTF-8")
print(unique(d[c("Scenario","Replicate","Convergence","Error")]))
cat("Repeated simulation completed. Inspect failures and Monte Carlo uncertainty; do not call a small simulation proof of 95% coverage.\n")
