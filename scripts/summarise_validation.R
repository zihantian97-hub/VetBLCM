# Rebuild summaries from recorded runs without rerunning MCMC.
d<-read.csv("validation/simulation_all_runs.csv",stringsAsFactors=FALSE,check.names=FALSE)
summary<-do.call(rbind,lapply(split(d,paste(d$Scenario,d$Parameter)),function(x) {
  completed<-is.finite(x$Median);covered<-x$Covered[completed];bias<-x$Median[completed]-x$Truth[completed]
  n<-length(covered);ci<-if(n)stats::binom.test(sum(covered),n)$conf.int else c(NA,NA)
  converged<-completed & x$Convergence
  data.frame(Scenario=x$Scenario[1],Parameter=x$Parameter[1],Replicates=nrow(x),Successful_fits=sum(completed),Converged_fits=sum(converged),Convergence_rate=mean(x$Convergence),Coverage_among_completed=if(n)mean(covered)else NA,Coverage_MCSE=if(n)sqrt(mean(covered)*(1-mean(covered))/n)else NA,Coverage_binomial_lower=ci[1],Coverage_binomial_upper=ci[2],Coverage_among_converged=if(any(converged))mean(x$Covered[converged])else NA,Covered_over_all_runs=sum(covered)/nrow(x),Bias=if(n)mean(bias)else NA,RMSE=if(n)sqrt(mean(bias^2))else NA,Mean_CrI_width=if(n)mean(x$Upper[completed]-x$Lower[completed])else NA)
}))
write.csv(summary,"validation/simulation_summary.csv",row.names=FALSE)
runs<-unique(d[c("Scenario","Replicate","Convergence","Error","Zero_cell")])
write.csv(runs[!runs$Convergence,],"validation/nonconverged_runs.csv",row.names=FALSE)
print(aggregate(Convergence~Scenario,runs,sum))
cat(nrow(runs),"attempted fits;",sum(runs$Convergence),"met numerical diagnostic targets.\n")
