# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 后验摘要、链间诊断和后验预测检查，均使用真实保存的抽样。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# 列出当前模型的关键参数；概率 prob 用于 PPC，未列入该参数摘要集合。
parameter_names <- function(fit) c("Se1","Sp1","Se2","Sp2",paste0("Prev[",seq_len(nrow(fit$cross)),"]"),if(fit$model!="independent") c("uD","uH","CovD","CovH"))
# 合并各链便于计算后验分位数等摘要；需要链间诊断时应保留链结构，使用 draws_array。
draws_matrix <- function(fit) {need_packages("coda");as.matrix(fit$draws)}
# 建立 iteration × chain × variable 三维结构，供 posterior 计算链间诊断。
draws_array <- function(fit,parameters=parameter_names(fit)) {
  need_packages(c("coda","posterior"))
  n<-nrow(fit$draws[[1]]);a<-array(NA_real_,c(n,length(fit$draws),length(parameters)),dimnames=list(iteration=NULL,chain=paste0("chain",seq_along(fit$draws)),variable=parameters))
  for(ch in seq_along(fit$draws)) a[,ch,]<-as.matrix(fit$draws[[ch]])[,parameters,drop=FALSE]
  posterior::as_draws_array(a)
}
# 计算后验均值、中位数和等尾 95% 可信区间；这里不是频率学置信区间或最短区间。
summarise_blcm <- function(fit) {
  m<-draws_matrix(fit)[,parameter_names(fit),drop=FALSE]
  data.frame(Parameter=colnames(m),Mean=colMeans(m),Median=apply(m,2,median),Lower=apply(m,2,quantile,.025),Upper=apply(m,2,quantile,.975),row.names=NULL)
}
# 计算 rank-normalized R-hat、bulk/tail ESS、MCSE 及相关/边界提示；数值达标不证明参数可识别或研究假设成立。
diagnose_blcm <- function(fit,rhat_limit=1.01,ess_per_chain=100) {
  ar<-draws_array(fit);d<-as.data.frame(posterior::summarise_draws(ar,"rhat","ess_bulk","ess_tail","mcse_mean"))
  names(d)[1]<-"Parameter";d$Pass<-is.finite(d$rhat)&d$rhat<rhat_limit&is.finite(d$ess_bulk)&d$ess_bulk>=ess_per_chain*length(fit$draws)&is.finite(d$ess_tail)&d$ess_tail>=ess_per_chain*length(fit$draws)
  m<-draws_matrix(fit)[,parameter_names(fit),drop=FALSE];correlation<-stats::cor(m);diag(correlation)<-1
  flags<-character()
  if(!fit$adapted) flags<-c(flags,"JAGS adaptation incomplete / 适应阶段未完成")
  if(any(!d$Pass)) flags<-c(flags,"Convergence/ESS targets not met / 收敛或有效样本量未达目标")
  if(any(abs(correlation[upper.tri(correlation)])>.95,na.rm=TRUE)) flags<-c(flags,"Absolute posterior correlation >0.95 (review flag) / 后验强相关，需复核")
  boundary<-data.frame(Parameter=character(),Fraction=numeric())
  for(p in fit$priors$summary$Parameter) {
    i<-match(p,fit$priors$summary$Parameter);lo<-fit$priors$lower[i];hi<-fit$priors$upper[i];w<-(hi-lo)*.01
    fraction<-mean(m[,p]<lo+w|m[,p]>hi-w)
    boundary<-rbind(boundary,data.frame(Parameter=p,Fraction=fraction))
  }
  if(any(boundary$Fraction>.1)) flags<-c(flags,"More than 10% draws within 1% of a prior support boundary (review flag) / 后验边界累积需复核")
  pv<-m[,paste0("Prev[",seq_len(nrow(fit$cross)),"]"),drop=FALSE];range_prev<-apply(pv,1,function(x) diff(range(x)));separation<-c(Median=median(range_prev),Lower=quantile(range_prev,.025),Upper=quantile(range_prev,.975),Pr_range_under_005=mean(range_prev<.05))
  if(median(range_prev)<.05) flags<-c(flags,"Small posterior prevalence separation (0.05 review threshold) / 群体患病率区分不足提示")
  list(table=d,correlation=correlation,boundary=boundary,separation=separation,flags=unique(flags),acceptable=all(d$Pass)&&isTRUE(fit$adapted),rhat_limit=rhat_limit,ess_per_chain=ess_per_chain,visual_review_required=TRUE)
}
# 从后验四格概率生成重复计数，对照观测与重复数据的 Pearson 型差异；尾概率是 PPC 指标，不是传统检验 P 值。
run_posterior_predictive_check <- function(fit,n_draws=4000,seed=fit$settings$seed+61) {
  m<-draws_matrix(fit);J<-nrow(fit$cross);K<-min(n_draws,nrow(m));denominator_epsilon<-1e-12
  with_seed(seed,function() {
    ids<-sample.int(nrow(m),K);rep<-array(NA_real_,c(K,J,4));expected<-rep;obsdisc<-repdisc<-numeric(K)
    for(i in seq_len(K)) for(j in seq_len(J)) {
      p<-m[ids[i],paste0("prob[",j,",",1:4,"]")];assert(all(p>=0&p<=1)&&abs(sum(p)-1)<1e-8,"Invalid posterior probabilities")
      e<-fit$cross$N[j]*p;y<-as.numeric(fit$cross[j,2:5]);r<-as.numeric(rmultinom(1,fit$cross$N[j],p));rep[i,j,]<-r;expected[i,j,]<-e
      # 极小分母下限只用于差异量数值稳定，不给观测四格计数加伪计数，也不修改模型似然。
      obsdisc[i]<-obsdisc[i]+sum((y-e)^2/pmax(e,denominator_epsilon));repdisc[i]<-repdisc[i]+sum((r-e)^2/pmax(e,denominator_epsilon))
    }
    tab<-do.call(rbind,lapply(seq_len(J),function(j) data.frame(Population=fit$cross$Population[j],Cell=c("++","+-","-+","--"),Observed=as.numeric(fit$cross[j,2:5]),Predicted_median=apply(rep[,j,,drop=FALSE],3,median),Lower=apply(rep[,j,,drop=FALSE],3,quantile,.025),Upper=apply(rep[,j,,drop=FALSE],3,quantile,.975),Mean_expected=apply(expected[,j,,drop=FALSE],3,mean))))
    tab$Residual<-tab$Observed-tab$Mean_expected
    list(table=tab,discrepancy=data.frame(Observed=obsdisc,Replicated=repdisc),tail_probability=mean(repdisc>=obsdisc),n_draws=K,seed=seed,denominator_epsilon=denominator_epsilon)
  })
}
