# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 模型比较、先验敏感性和报告审阅；不会用检查表修改后验结果。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# 先核对输入哈希，再并列独立与依赖模型摘要；中位数差与区间重叠是描述性比较，不是模型优劣的自动判决。
compare_models <- function(independent,dependent) {
  assert(identical(independent$provenance$input_sha256,dependent$provenance$input_sha256),"Models use different data / 两个模型数据不同")
  a<-independent$summary;b<-dependent$summary
  z<-merge(a,b,by="Parameter",suffixes=c("_independent","_dependent"),sort=FALSE)
  z$Median_difference<-z$Median_dependent-z$Median_independent
  z$CrI_overlap<-pmax(0,pmin(z$Upper_independent,z$Upper_dependent)-pmax(z$Lower_independent,z$Lower_dependent))
  z
}
# 构建参考情景：Beta(1,1) 但保留已记录的截断范围，因此不等同于取消所有先验限制。
weak_prior_scenario <- function(fit) {
  p<-fit$priors$table;p$Prior_type<-"alpha_beta";p$Alpha<-1;p$Beta<-1;p$Mean<-NA_real_;p$ESS<-NA_real_;p$Source_type<-"weak/reference";p$Source<-"Weak-prior sensitivity scenario";p$Rationale<-"Uniform over recorded support; label restrictions retained";p
}
# 同时核对形状和截断上下界，防止把改变类别限制的先验误标为同一弱先验情景。
is_weak_prior_scenario <- function(priors,fit,tol=1e-12) {
  if(is.null(priors)||is.null(fit$priors$table)) return(FALSE)
  main<-fit$priors$table;z<-priors[match(main$Parameter,priors$Parameter),,drop=FALSE]
  if(nrow(z)!=nrow(main)||anyNA(match(main$Parameter,priors$Parameter))) return(FALSE)
  all(abs(z$Alpha-1)<tol&abs(z$Beta-1)<tol) &&
    isTRUE(all.equal(as.numeric(z$Lower),as.numeric(main$Lower),tolerance=tol,check.attributes=FALSE)) &&
    isTRUE(all.equal(as.numeric(z$Upper),as.numeric(main$Upper),tolerance=tol,check.attributes=FALSE))
}
# 逐个情景重拟合；使用独立可复现种子，保留计算失败和数值诊断不通过的结果，不筛掉不利情景。
run_prior_sensitivity <- function(fit,scenarios,progress=function(message) invisible(NULL)) {
  assert(is.list(scenarios)&&length(scenarios)&&!is.null(names(scenarios))&&all(nzchar(names(scenarios)))&&!anyDuplicated(names(scenarios)),"Named distinct prior scenarios required")
  results<-list();tables<-list();failures<-empty_df()
  for(i in seq_along(scenarios)) {
    name<-names(scenarios)[i];progress(paste("Scenario / 情景:",name));s<-fit$settings;s$seed<-s$seed+1000*i
    r<-tryCatch(run_blcm(fit$data,scenarios[[i]],mode=fit$mode,model=fit$model,settings=s,metadata=fit$metadata,populations=fit$populations,progress=progress),error=function(e)e)
    if(inherits(r,"error")) {failures<-rbind(failures,data.frame(Message=paste(name,conditionMessage(r))));next}
    results[[name]]<-r;tab<-r$summary;tab$Scenario<-name;tab$Diagnostics_pass<-r$diagnostics$acceptable;tab$Median_change<-tab$Median-fit$summary$Median[match(tab$Parameter,fit$summary$Parameter)];tab$Width_change<-(tab$Upper-tab$Lower)-(fit$summary$Upper-fit$summary$Lower)[match(tab$Parameter,fit$summary$Parameter)];tables[[name]]<-tab
  }
  list(main_id=fit$id,requested=names(scenarios),priors=scenarios,fits=results,table=if(length(tables)) do.call(rbind,tables) else data.frame(),failures=failures)
}
# 两张报告检查表共用的来源检查：信息性或截断先验需完整证据字段；字段非空不能替代对证据质量的科学判断。
priors_documented <- function(p) {
  if(!is.data.frame(p)||!nrow(p)||!all(c("Alpha","Beta","Lower","Upper") %in% names(p))) return(FALSE)
  shapes <- p[c("Alpha","Beta","Lower","Upper")]
  if(!all(vapply(shapes,function(x)is.numeric(x)&&all(is.finite(x)),logical(1)))) return(FALSE)
  informative <- abs(p$Alpha-1)>1e-12|abs(p$Beta-1)>1e-12|p$Lower>0|p$Upper<1
  fields <- c("Source_type","Source","Rationale","Source_population","Specimen","Assay","Estimate","Uncertainty","Applicability","Discount")
  !any(informative) || (all(fields %in% names(p)) && all(vapply(p[informative,fields,drop=FALSE],function(x)all(!is.na(x)&nzchar(trimws(as.character(x)))),logical(1))))
}

# 筛选总数未知则返回 NA；不合法、非整数或小于纳入数时抛错。只有合法已知总数才能计算排除人数。
sample_flow_counts <- function(value, final_n) {
  missing <- is.null(value)||!length(value)||(length(value)==1L&&(is.na(value)||!nzchar(trimws(as.character(value)))))
  if(missing) return(list(assessed=NA_real_,excluded=NA_real_))
  assessed <- suppressWarnings(as.numeric(value))
  assert(length(assessed)==1L&&is.finite(assessed)&&assessed==floor(assessed)&&assessed>=final_n,
    "Total samples assessed must be a whole number at least as large as the included sample size / 筛选总数必须是整数，且不得小于纳入样本数")
  list(assessed=assessed,excluded=assessed-final_n)
}

# 用于审阅状态的无异常接口：缺失或矛盾样本流程均返回 FALSE，不静默修改研究记录。
sample_flow_documented <- function(fit) {
  isTRUE(tryCatch(is.finite(sample_flow_counts(fit$metadata$samples_assessed,sum(fit$cross$N))$assessed),error=function(e)FALSE))
}

# 组合元数据、设计、先验、MCMC、模型比较、敏感性及人工审阅要求；Required 列区分必需项与需保留的提示。
review_checklist <- function(fit,comparison=NULL,sensitivity=NULL,review=list()) {
  m<-fit$metadata;p<-fit$priors$table
  nonblank<-function(x) all(!is.na(x)&nzchar(trimws(as.character(x))))
  prior_documented<-priors_documented(p)
  prior_independent<-isTRUE(m$priors_independent)
  sensitivity_current<-!is.null(sensitivity)&&identical(sensitivity$main_id,fit$id)
  sf<-if(sensitivity_current) sensitivity$fits %||% list() else list()
  sp<-if(sensitivity_current) sensitivity$priors %||% list() else list()
  requested<-if(sensitivity_current) sensitivity$requested %||% character() else character()
  failures<-if(sensitivity_current) sensitivity$failures %||% data.frame() else data.frame()
  sensitivity_completed<-sensitivity_current&&length(requested)>=2&&!nrow(failures)&&isTRUE(review$sensitivity)
  sensitivity_diagnostics_all_pass<-length(sf)>0&&all(vapply(sf,function(x)isTRUE(x$diagnostics$acceptable),logical(1)))
  bad_sensitivity<-if(length(sf))names(sf)[!vapply(sf,function(x)isTRUE(x$diagnostics$acceptable),logical(1))]else character()
  sensitivity_failed_reviewed<-!length(bad_sensitivity)||isTRUE(review$sensitivity_failed)
  weak_present<-length(sp)>0&&any(vapply(sp,function(pp)is_weak_prior_scenario(pp,fit),logical(1)))
  alternative_present<-length(sp)>0&&any(vapply(sp,function(pp) {
    main<-fit$priors$table;z<-pp[match(main$Parameter,pp$Parameter),,drop=FALSE]
    changed<-!isTRUE(all.equal(z[c("Alpha","Beta","Lower","Upper")],main[c("Alpha","Beta","Lower","Upper")],check.attributes=FALSE))
    nonweak<-!is_weak_prior_scenario(pp,fit)
    changed&&nonweak&&all(nzchar(trimws(z$Rationale[abs(z$Alpha-main$Alpha)>1e-12|abs(z$Beta-main$Beta)>1e-12|abs(z$Lower-main$Lower)>1e-12|abs(z$Upper-main$Upper)>1e-12])))
  },logical(1)))
  compar_ok<-!is.null(comparison)&&all(vapply(comparison,function(x) inherits(x,"vetblcm_fit")&&identical(x$provenance$input_sha256,fit$provenance$input_sha256)&&x$settings$mode=="final"&&x$diagnostics$acceptable,logical(1)))&&all(c("independent","positive") %in% names(comparison))
  req<-c("project_name","pathogen","t1","t2","specimen","target_population","source_population","unit","purpose","case_definition","comparator_reference","t1_positive_rule","t2_positive_rule","equivocal_handling","invalid_handling","missing_handling","exclusion_notes","sample_size_rationale")
  metadata_ok<-all(vapply(req,function(k) nonblank(m[[k]] %||% ""),logical(1)))
  pop_ok<-!is.null(fit$populations)&&all(c("Definition","Rationale","Prior_source") %in% names(fit$populations))&&all(vapply(fit$populations[c("Definition","Rationale","Prior_source")],nonblank,logical(1)))
  checks<-c(Metadata=metadata_ok,Population_definitions=pop_ok,Design_assumptions=!length(fit$design$blockers),Priors_independent=prior_independent,Priors_documented=prior_documented,Final_mode=fit$settings$mode=="final",Four_chains=length(fit$draws)>=4,Adaptation=fit$adapted,Rhat_ESS=fit$diagnostics$acceptable,Class_interpretation=isTRUE(m$label_confirmed)&&nonblank(m$label_rationale %||% ""),Independent_and_dependent=compar_ok,Sensitivity_completed=sensitivity_completed,Weak_scenario=weak_present,Plausible_alternative=alternative_present,Sensitivity_failed_scenarios_reviewed=sensitivity_failed_reviewed,Sensitivity_all_diagnostics_pass=sensitivity_diagnostics_all_pass,PPC_completed=!is.null(fit$ppc),Visual_pathology_review=isTRUE(review$visual)&&nonblank(review$notes %||% ""),Prior_sensitivity_review=isTRUE(review$sensitivity),PPC_review=isTRUE(review$ppc),Dependent_prior_justification=fit$model=="independent"||(isTRUE(review$identifiability)&&nonblank(review$notes %||% "")),Sources_and_model_code=nzchar(fit$model_code)&&nzchar(fit$provenance$model_sha256))
  checks<-c(checks,Sample_flow_documented=sample_flow_documented(fit))
  required<-rep(TRUE,length(checks));names(required)<-names(checks);required["Sensitivity_all_diagnostics_pass"]<-FALSE
  data.frame(Check=names(checks),Pass=unname(checks),Required=unname(required),stringsAsFactors=FALSE)
}

# 根据设计阻断、数值诊断和审阅完成度生成红/黄/绿提示；颜色不代替研究者对假设的判断。
analysis_status <- function(fit,comparison=NULL,sensitivity=NULL,review=list(),language="en") {
  checks<-review_checklist(fit,comparison,sensitivity,review)
  severe<-!fit$diagnostics$acceptable || length(fit$design$blockers)>0
  caution<-length(fit$diagnostics$flags)>0 || fit$model!="independent" || !all(checks$Pass)
  level<-if(severe)"red" else if(caution)"yellow" else "green"
  zh<-language=="zh"
  label<-switch(level,
    red=if(zh)"当前数据/模型配置不支持可靠的最终DSe/DSp解释。不可作为最终结果报告。" else "The current data/model configuration does not support reliable final DSe/DSp interpretation. DO NOT REPORT AS FINAL DSe/DSp.",
    yellow=if(zh)"MCMC指标达标；先验、识别性或尚未完成的审阅仍需关注。" else "MCMC targets met; priors, identifiability or incomplete review still require attention.",
    green=if(zh)"MCMC诊断和审阅清单已满足；结论仍以记录的假设为条件。" else "MCMC diagnostics and review checklist complete; conclusions remain conditional on recorded assumptions.")
  list(level=level,label=label,checks=checks)
}
