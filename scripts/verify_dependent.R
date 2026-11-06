Sys.unsetenv("LC_ALL")
source("R/load.R");load_vetblcm()
dir.create("validation",showWarnings=FALSE)
truth<-c(Se1=.90,Sp1=.97,Se2=.84,Sp2=.95,`Prev[1]`=.06,`Prev[2]`=.30,`Prev[3]`=.70,CovD=.04,CovH=.015)
truth<-c(truth,uD=unname(truth["CovD"]/covariance_bounds(.90,.84)[,2]),uH=unname(truth["CovH"]/covariance_bounds(.03,.05)[,2]))
d<-simulate_blcm(rep(2000,3),truth[5:7],truth[1],truth[2],truth[3],truth[4],truth[8],truth[9],seed=1485,populations=c("Low","Medium","High"))
p<-prior_template(d$Population);p$Lower[1:2]<-.5
p$Alpha[3:4]<-truth[3:4]*400;p$Beta[3:4]<-(1-truth[3:4])*400
p$Source[3:4]<-"SIMULATED external-information scenario, not a scientific recommendation";p$Source_type[3:4]<-"simulation";p$Rationale[3:4]<-"Controlled recovery experiment with correctly centred informative comparator priors"
f<-run_blcm(d,p,mode="aggregated",model="positive",settings=mcmc_settings("final",adapt=3000,burnin=8000,iterations=24000),metadata=list(grouping_independent=TRUE,procedures_comparable="yes",independent_sampling=TRUE),populations=data.frame(Population=d$Population,Definition="SIMULATED EXAMPLE ONLY"))
s<-f$summary;s$Truth<-truth[s$Parameter];s$Covered<-s$Lower<=s$Truth&s$Upper>=s$Truth;s$Bias<-s$Median-s$Truth
write.csv(s,"validation/dependent_recovery.csv",row.names=FALSE);write.csv(f$diagnostics$table,"validation/dependent_diagnostics.csv",row.names=FALSE);saveRDS(f,"validation/dependent_fit.rds")
print(s);print(f$diagnostics$table)
stopifnot(all(s$Covered),all(abs(s$Bias[s$Parameter %in% c("Se1","Sp1","Se2","Sp2")])<.1),f$diagnostics$acceptable)
cat("DEPENDENT RECOVERY CHECK PASSED; conditional on simulated informative priors; not identification proof or coverage study\n")
