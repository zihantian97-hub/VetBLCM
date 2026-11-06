# 中文注释版 / Annotated source — VetBLCM 0.1.10
# R 与 JAGS 的桥接层；本文件决定传入数据、初始化、抽样与结果冻结。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# 集中验证链数、适应、预热、采样、稀疏间隔及种子；preview/final 是计算配置，不是结论可靠性的自动认证。
mcmc_settings <- function(mode=c("preview","final"),chains=4,adapt=NULL,burnin=NULL,iterations=NULL,thin=1,seed=20260914) {
  mode<-match.arg(mode)
  s<-list(mode=mode,chains=chains,adapt=adapt %||% if(mode=="final") 2000 else 500,burnin=burnin %||% if(mode=="final") 5000 else 1000,iterations=iterations %||% if(mode=="final") 10000 else 2000,thin=thin,seed=seed)
  for(v in c("chains","adapt","burnin","iterations","thin","seed")) check_number(s[[v]],v,if(v=="burnin") 0 else 1,if(v=="seed") .Machine$integer.max-10000 else 1e8,TRUE)
  assert(chains>=2&&chains<=16,"Use 2–16 chains; four required for final review")
  assert(s$iterations>=10*s$thin,"Too few retained draws")
  s
}
# 主计算入口：数据/设计检查 → 先验排序 → JAGS 多链采样 → 后验摘要/诊断/PPC。输出 vetblcm_fit，冻结本次输入、配置、模型文本和来源。
run_blcm <- function(data,priors,mode=c("sample","aggregated"),model=c("independent","positive","signed"),settings=mcmc_settings(),metadata=list(),populations=NULL,root=getOption("vetblcm.root","."),progress=function(message) invisible(NULL)) {
  mode<-match.arg(mode);model<-match.arg(model);need_packages(c("rjags","coda","posterior","digest"))
  settings<-do.call(mcmc_settings,settings)
  design<-check_blcm_design(data,mode,model,metadata,populations);cross<-design$cross;J<-nrow(cross);assert(J>=2,"At least two populations required")
  prior<-resolve_priors(priors,cross$Population,model)
  file<-file.path(root,"models",switch(model,independent="hw_independent.jags",positive="dependent_positive.jags",signed="dependent_signed.jags"));assert(file.exists(file),"Requested model is not yet installed")
  code<-paste(readLines(file,warn=FALSE,encoding="UTF-8"),collapse="\n")
  # alpha/beta/lower/upper 顺序固定：Se1、Sp1、Se2、Sp2、各群体 Prev，最后为 uD、uH（依赖模型）。
  dat<-list(J=J,Y=unname(as.matrix(cross[2:5])),N=as.integer(cross$N),alpha=prior$alpha,beta=prior$beta,lower=prior$lower,upper=prior$upper)
  # Distinct, recorded seeds and dispersed prior-quantile starts; never initialized from truth.
  # 使用不同链的先验分位数分散起点；不得用模拟真值作为拟合初值，以免掩盖混合问题。
  inits<-with_seed(settings$seed,function() lapply(seq_len(settings$chains),function(ch) {
    ps<-prior$summary;pr<-((ch-.5)/settings$chains+seq_len(nrow(ps))*.173) %% .9+.05
    vals<-vapply(seq_len(nrow(ps)),function(i) qbeta(pbeta(ps$lower[i],ps$alpha[i],ps$beta[i])+pr[i]*(pbeta(ps$upper[i],ps$alpha[i],ps$beta[i])-pbeta(ps$lower[i],ps$alpha[i],ps$beta[i])),ps$alpha[i],ps$beta[i]),numeric(1))
    z<-list(accuracy=vals[1:4],Prev=vals[5:(J+4)],.RNG.name=c("base::Wichmann-Hill","base::Marsaglia-Multicarry","base::Super-Duper","base::Mersenne-Twister")[(ch-1)%%4+1],.RNG.seed=as.integer(settings$seed+ch*101))
    if(model!="independent") {z$uD<-vals[J+5];z$uH<-vals[J+6]};z
  }))
  start<-Sys.time();progress("Compiling JAGS / 编译模型")
  con<-textConnection(code);on.exit(close(con),add=TRUE)
  jm<-rjags::jags.model(con,data=dat,inits=inits,n.chains=settings$chains,n.adapt=0,quiet=TRUE)
  progress("Adaptation / 适应阶段")
  # 适应、预热与保留后验抽样分开；适应失败会进入诊断状态，不因后续能输出数字而忽略。
  adapted<-rjags::adapt(jm,n.iter=settings$adapt,end.adaptation=TRUE,progress.bar="none")
  if(settings$burnin>0) {progress("Burn-in / 预热阶段");stats::update(jm,n.iter=settings$burnin,progress.bar="none")}
  progress("Posterior sampling / 后验采样")
  monitor<-c("Se1","Sp1","Se2","Sp2","Prev","prob",if(model!="independent") c("uD","uH","CovD","CovH"))
  draws<-rjags::coda.samples(jm,variable.names=monitor,n.iter=settings$iterations,thin=settings$thin,na.rm=FALSE,progress.bar="none")
  versions<-vapply(c("rjags","coda","posterior","digest"),function(p) as.character(utils::packageVersion(p)),character(1))
  # 保存实际使用的模型文本、参数、初值和软件版本；修改界面输入不会追溯改写已完成的拟合。
  result<-structure(list(id=analysis_id(),data=data,mode=mode,model=model,cross=cross,priors=prior,settings=settings,metadata=metadata,populations=populations,design=design,agreement=agreement_analysis(cross),draws=draws,adapted=adapted,model_code=code,initial_values=inits,started=as.character(start),elapsed_seconds=as.numeric(difftime(Sys.time(),start,units="secs")),provenance=list(R=R.version.string,JAGS=as.character(rjags::jags.version()),packages=versions,model_sha256=sha256(code,FALSE),input_sha256=sha256(data),import_file_sha256=attr(data,"file_sha256"),session_info=capture.output(sessionInfo()))),class="vetblcm_fit")
  result$summary<-summarise_blcm(result);result$diagnostics<-diagnose_blcm(result);result$ppc<-run_posterior_predictive_check(result)
  result
}
# 条件独立模型的快捷入口，其他参数原样传给 run_blcm。
fit_blcm_independent <- function(...) run_blcm(...,model="independent")
# 依赖模型的快捷入口；signed=FALSE 限非负依赖，TRUE 使用完整有符号协方差范围。
fit_blcm_dependent <- function(...,signed=FALSE) run_blcm(...,model=if(signed) "signed" else "positive")
