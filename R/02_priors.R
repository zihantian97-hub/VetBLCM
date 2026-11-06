# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 先验参数转换、截断分布及证据字段整理。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# 将 alpha/beta 或 mean/ESS 转为 Beta 先验，计算截断后的实际均值、标准差及分位数。ESS 在这里采用 alpha+beta 的浓度约定。
make_beta_prior <- function(alpha=NULL,beta=NULL,mean=NULL,ess=NULL,lower=0,upper=1) {
  if(!is.null(mean)||!is.null(ess)) {
    assert(is.null(alpha)&&is.null(beta),"Specify shapes OR mean/ESS, not both / 两种输入方式不可混用")
    check_number(mean,"mean",0,1);assert(mean>0&&mean<1,"Prior mean must be strictly between 0 and 1")
    check_number(ess,"ESS",.Machine$double.eps);alpha<-mean*ess;beta<-(1-mean)*ess
  }
  check_number(alpha,"alpha",.Machine$double.eps);check_number(beta,"beta",.Machine$double.eps)
  check_number(lower,"lower",0,1);check_number(upper,"upper",0,1);assert(lower<upper,"lower must be below upper")
  # 截断分布需除以保留区间的概率质量；输入 mean 是未截断 Beta 的均值，截断后的实际均值由 em 单独计算。
  mass<-pbeta(upper,alpha,beta)-pbeta(lower,alpha,beta);assert(mass>1e-12,"Truncation leaves negligible prior mass / 截断区间先验质量过小")
  q<-function(p) qbeta(pbeta(lower,alpha,beta)+p*mass,alpha,beta)
  em<-alpha/(alpha+beta)*(pbeta(upper,alpha+1,beta)-pbeta(lower,alpha+1,beta))/mass
  e2<-alpha*(alpha+1)/((alpha+beta)*(alpha+beta+1))*(pbeta(upper,alpha+2,beta)-pbeta(lower,alpha+2,beta))/mass
  list(alpha=alpha,beta=beta,ess=alpha+beta,lower=lower,upper=upper,mean=em,median=q(.5),sd=sqrt(max(0,e2-em^2)),q025=q(.025),q975=q(.975),mass=mass)
}
# 生成各检测 Se/Sp、各群体 Prev 及依赖位置参数 uD/uH 的先验模板；空证据字段需研究者填写。
prior_template <- function(populations) {
  data.frame(Parameter=c("Se1","Sp1","Se2","Sp2",paste0("Prev[",seq_along(populations),"]"),"uD","uH"),Population=c(rep("",4),populations,"",""),Assay=c("T1","T1","T2","T2",rep("",length(populations)+2)),Prior_type="alpha_beta",Mean=NA_real_,ESS=NA_real_,Alpha=1,Beta=1,Lower=0,Upper=1,Source_type="weak/reference",Source="",Rationale="",Source_population="",Specimen="",Estimate="",Uncertainty="",Applicability="",Discount="",Notes="",stringsAsFactors=FALSE)
}
# 依模型筛选并排序参数，验证 Prev 与群体名称一一对应；返回 JAGS 所需的形状、上下界及可审计先验表。
resolve_priors <- function(priors,populations,model="independent") {
  need<-c("Se1","Sp1","Se2","Sp2",paste0("Prev[",seq_along(populations),"]"),if(model!="independent") c("uD","uH"))
  assert(is.data.frame(priors)&&all(c("Parameter","Prior_type") %in% names(priors)),"Invalid prior table / 先验表格式错误")
  assert(!anyDuplicated(priors$Parameter),"Duplicate prior parameters / 先验参数重复")
  assert(all(need %in% priors$Parameter),paste("Missing priors:",paste(setdiff(need,priors$Parameter),collapse=",")))
  p<-priors[match(need,priors$Parameter),,drop=FALSE]
  for(v in c("Alpha","Beta","Mean","ESS","Lower","Upper")) if(!v %in% names(p)) p[[v]]<-if(v=="Lower") 0 else if(v=="Upper") 1 else NA_real_
  for(v in c("Population","Assay","Source_type","Source","Rationale","Source_population","Specimen","Estimate","Uncertainty","Applicability","Discount","Notes")) {
    if(!v %in% names(p)) p[[v]]<-""
    p[[v]]<-as.character(p[[v]]);p[[v]][is.na(p[[v]])]<-""
  }
  ix<-5:(4+length(populations));assert(all(!is.na(p$Population[ix])&p$Population[ix]==populations),"Prevalence prior population names/order mismatch / 患病率先验与群体未正确匹配")
  summaries<-lapply(seq_len(nrow(p)),function(i) {
    type<-p$Prior_type[i];assert(type %in% c("alpha_beta","mean_ess"),"Unknown prior input type")
    z<-if(type=="mean_ess") make_beta_prior(mean=p$Mean[i],ess=p$ESS[i],lower=p$Lower[i],upper=p$Upper[i]) else make_beta_prior(alpha=p$Alpha[i],beta=p$Beta[i],lower=p$Lower[i],upper=p$Upper[i])
    as.data.frame(z)
  })
  s<-do.call(rbind,summaries);p$Alpha<-s$alpha;p$Beta<-s$beta
  unsupported_source<-p$Source_type %in% c("literature","external data") & !nzchar(trimws(p$Source))
  p$Source_type[unsupported_source]<-"subjective/expert"
  list(table=p,summary=cbind(Parameter=p$Parameter,Population=p$Population,s),alpha=s$alpha,beta=s$beta,lower=s$lower,upper=s$upper)
}
# 在截断范围对应的累积概率区间均匀抽样，再使用逆 CDF 得到截断 Beta 抽样。
sample_beta_prior <- function(prior,n) {
  qbeta(runif(n,pbeta(prior$lower,prior$alpha,prior$beta),pbeta(prior$upper,prior$alpha,prior$beta)),prior$alpha,prior$beta)
}
# 按固定种子生成先验抽样，仅用于显示和检查；不会把这些值作为观测数据。
sample_priors <- function(priors,n=4000,seed=817) {
  with_seed(seed,function() {
    p<-priors$summary;out<-sapply(seq_len(nrow(p)),function(i) sample_beta_prior(as.list(p[i,]),n));colnames(out)<-p$Parameter;out
  })
}
