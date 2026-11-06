source("R/load.R");load_vetblcm()
dir.create("validation",showWarnings=FALSE)
testthat::test_dir("tests/testthat",reporter="summary")
truth<-c(Se1=.9,Sp1=.97,Se2=.84,Sp2=.95,`Prev[1]`=.06,`Prev[2]`=.30,`Prev[3]`=.70)
d<-simulate_blcm(rep(2500,3),truth[5:7],truth[1],truth[2],truth[3],truth[4],seed=684,populations=c("Low","Medium","High"))
p<-prior_template(d$Population);p$Lower[1:2]<-.5;p$Rationale[1:2]<-"SIMULATED VALIDATION: explicit class orientation assumption"
f<-run_blcm(d,p,mode="aggregated",model="independent",settings=mcmc_settings("final",adapt=2000,burnin=4000,iterations=10000),metadata=list(grouping_independent=TRUE,procedures_comparable="yes",independent_sampling=TRUE),populations=data.frame(Population=d$Population,Definition="SIMULATED EXAMPLE ONLY"))
s<-f$summary;s$Truth<-truth[s$Parameter];s$Covered<-s$Lower<=s$Truth&s$Upper>=s$Truth;s$Bias<-s$Median-s$Truth
write.csv(s,"validation/independent_recovery.csv",row.names=FALSE)
write.csv(f$diagnostics$table,"validation/independent_diagnostics.csv",row.names=FALSE)
saveRDS(f,"validation/independent_fit.rds")
print(s);print(f$diagnostics$table)
stopifnot(all(s$Covered),all(abs(s$Bias)<.06),f$diagnostics$acceptable)
cat("INDEPENDENT RECOVERY CHECK PASSED; one replicate, NOT an empirical coverage study\n")
