# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 论文辅助输出：后验差值、样本流程、报告规范映射和标准化摘要。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# Publication-oriented outputs derived from completed single-analyte fits.
# These functions do not alter the fitted BLCM, priors, likelihood or MCMC draws.

# 在同一次后验抽样内计算 T1-T2，保留联合后验依赖；报告差值区间与 Pr(T1>T2)。
posterior_contrasts <- function(fit) {
  assert(!is.null(fit), "A completed fit is required / 需要已完成的拟合")
  m <- draws_matrix(fit)
  needed <- c("Se1", "Sp1", "Se2", "Sp2")
  assert(all(needed %in% colnames(m)), "Accuracy draws are unavailable / 缺少准确性后验抽样")
  summarize_difference <- function(values, measure, t1, t2) {
    data.frame(
      Measure = measure,
      T1_parameter = t1,
      T2_parameter = t2,
      Mean = mean(values),
      Median = stats::median(values),
      Lower = unname(stats::quantile(values, .025)),
      Upper = unname(stats::quantile(values, .975)),
      Pr_T1_greater = mean(values > 0),
      stringsAsFactors = FALSE
    )
  }
  rbind(
    summarize_difference(m[, "Se1"] - m[, "Se2"], "Delta_DSe", "Se1", "Se2"),
    summarize_difference(m[, "Sp1"] - m[, "Sp2"], "Delta_DSp", "Sp1", "Sp2")
  )
}

# 只根据明确记录的筛选人数生成流程表；未知保持 NA，禁止用最终纳入数虚构零排除。
sample_flow_table <- function(fit) {
  assert(!is.null(fit), "A completed fit is required / 需要已完成的拟合")
  final_n <- sum(fit$cross$N)
  counts <- sample_flow_counts(fit$metadata$samples_assessed,final_n)
  assessed <- counts$assessed
  excluded <- counts$excluded
  populations <- data.frame(
    Stage = paste0("Population: ", fit$cross$Population),
    N = fit$cross$N,
    Detail = fit$cross$Population,
    stringsAsFactors = FALSE
  )
  rbind(
    data.frame(Stage = "Assessed for eligibility", N = assessed, Detail = fit$metadata$source_population %||% "", stringsAsFactors = FALSE),
    data.frame(Stage = "Excluded before binary BLCM", N = excluded, Detail = fit$metadata$exclusion_notes %||% "", stringsAsFactors = FALSE),
    data.frame(Stage = "Included in BLCM", N = final_n, Detail = fit$metadata$specimen %||% "", stringsAsFactors = FALSE),
    populations
  )
}

# 绘制筛选、排除、纳入及群体分配；NA 在图上明确显示“未提供”或“Not provided”。
plot_sample_flow <- function(fit, language = "en") {
  need_packages("ggplot2")
  d <- sample_flow_table(fit)
  assessed <- d$N[d$Stage == "Assessed for eligibility"][[1]]
  excluded <- d$N[d$Stage == "Excluded before binary BLCM"][[1]]
  included <- d$N[d$Stage == "Included in BLCM"][[1]]
  pops <- d[grepl("^Population: ", d$Stage), , drop = FALSE]
  zh <- identical(language, "zh")
  count_label <- function(x) if(is.na(x)) if(zh) "未提供" else "Not provided" else as.character(x)
  assessed <- count_label(assessed)
  excluded <- count_label(excluded)
  assessed_node <- data.frame(x=0,y=3,label=paste0(if(zh) "进入筛选\n" else "Assessed\n","N = ",assessed))
  branch_nodes <- data.frame(
    x=c(-1,0.6),y=c(2,2),
    label=c(paste0(if(zh) "排除\n" else "Excluded\n","N = ",excluded),paste0(if(zh) "纳入BLCM\n" else "Included in BLCM\n","N = ",included))
  )
  if(nrow(pops)) {
    xs <- seq(-(nrow(pops)-1)/2, (nrow(pops)-1)/2, length.out=nrow(pops)) + .6
    pdat <- data.frame(x=xs,y=1,label=paste0(pops$Detail,"\nN = ",pops$N),stringsAsFactors=FALSE)
  } else pdat <- data.frame(x=numeric(),y=numeric(),label=character())
  nodes <- rbind(assessed_node,branch_nodes,pdat)
  segments <- rbind(
    data.frame(x=0,y=2.75,xend=-1,yend=2.25),
    data.frame(x=0,y=2.75,xend=.6,yend=2.25),
    if(nrow(pdat)) data.frame(x=rep(.6,nrow(pdat)),y=rep(1.75,nrow(pdat)),xend=pdat$x,yend=rep(1.25,nrow(pdat))) else data.frame(x=numeric(),y=numeric(),xend=numeric(),yend=numeric())
  )
  xspan <- max(1.7, max(abs(c(nodes$x,0)),na.rm=TRUE)+.6)
  ggplot2::ggplot() +
    ggplot2::geom_segment(data=segments,ggplot2::aes(x=x,y=y,xend=xend,yend=yend),linewidth=.6) +
    ggplot2::geom_label(data=nodes,ggplot2::aes(x=x,y=y,label=label),size=4,linewidth=.35,label.padding=grid::unit(.35,"lines")) +
    ggplot2::coord_cartesian(xlim=c(-xspan,xspan),ylim=c(.5,3.5),clip="off") +
    ggplot2::labs(title=if(zh) "样本纳入与分组流程" else "Sample inclusion and population flow") +
    ggplot2::theme_void(base_size=12) + ggplot2::theme(plot.title=ggplot2::element_text(hjust=.5,face="bold"))
}

# 生成 STARD-BLCM 主题映射辅助表；不是逐字官方清单，也不是自动认证。先验检查与正式审阅共用函数。
stard_blcm_reporting_audit <- function(fit, comparison = NULL, sensitivity = NULL, review = list()) {
  m <- fit$metadata
  nonblank_value <- function(x) length(x) && !all(is.na(x)) && nzchar(trimws(paste(x, collapse=" ")))
  final_n <- sum(fit$cross$N)
  add <- function(section, topic, status, evidence, source="STARD-BLCM 2017; DOI 10.1016/j.prevetmed.2017.01.006")
    data.frame(Section=section, Reporting_topic=topic, Status=if(isTRUE(status))"Complete" else "Review", Evidence=evidence, Source=source, stringsAsFactors=FALSE)
  out <- list(
    add("Title/Abstract", "Identify diagnostic-accuracy study and Bayesian latent class approach", FALSE, "Manuscript not inspected; author review required / 未检查论文，需作者审核。"),
    add("Objectives", "State diagnostic-accuracy objective and analyte", nonblank_value(m$pathogen), paste("Analyte:",m$pathogen %||% "")),
    add("Population", "Describe source and target populations", nonblank_value(m$source_population)&&nonblank_value(m$target_population), paste("Source:",m$source_population %||% "","; Target:",m$target_population %||% "")),
    add("Sampling", "Report eligibility, exclusions and final sample flow", sample_flow_documented(fit)&&nonblank_value(m$exclusion_notes), paste("Assessed:",m$samples_assessed %||% "Not provided / 未提供","; Included:",final_n,"; Exclusions:",m$exclusion_notes %||% "")),
    add("Sample size", "Explain how sample size was determined", nonblank_value(m$sample_size_rationale), m$sample_size_rationale %||% ""),
    add("Index test", "Describe T1 and prespecified positivity rule", nonblank_value(m$t1)&&nonblank_value(m$t1_positive_rule), paste(m$t1 %||% "",";",m$t1_positive_rule %||% "")),
    add("Comparator", "Describe T2 and prespecified positivity rule/reference", nonblank_value(m$t2)&&nonblank_value(m$t2_positive_rule)&&nonblank_value(m$comparator_reference), paste(m$t2 %||% "",";",m$t2_positive_rule %||% "",";",m$comparator_reference %||% "")),
    add("Indeterminate results", "Report handling of equivocal, invalid and missing results", all(vapply(c("equivocal_handling","invalid_handling","missing_handling"),function(k)nonblank_value(m[[k]]),logical(1))), paste("Equivocal:",m$equivocal_handling %||% "","; Invalid:",m$invalid_handling %||% "","; Missing:",m$missing_handling %||% "")),
    add("Latent condition", "Define the latent target condition independently of T1/T2", nonblank_value(m$case_definition), m$case_definition %||% ""),
    add("Populations", "Define populations independently of current test results", isTRUE(m$grouping_independent)&&!is.null(fit$populations)&&nrow(fit$populations)>=2, paste(fit$cross$Population,collapse=", ")),
    add("Model", "Report likelihood, conditional-dependence assumptions and constant-accuracy assumptions", nonblank_value(fit$model), paste("Model:",fit$model,"; populations:",nrow(fit$cross))),
    add("Priors", "Report priors, sources, uncertainty and applicability", priors_documented(fit$priors$table), if(priors_documented(fit$priors$table)) "Required prior documentation fields recorded; scientific adequacy requires author review / 必需先验说明字段已记录，科学合理性仍需审核。" else "Prior documentation missing or incomplete; review required / 先验说明缺失或不完整，需审核。"),
    add("Computation", "Report software, MCMC settings and convergence diagnostics", !is.null(fit$settings)&&!is.null(fit$diagnostics), paste(fit$provenance$R,"; JAGS",fit$provenance$JAGS)),
    add("Accuracy results", "Report DSe/DSp and 95% credible intervals", all(c("Se1","Sp1","Se2","Sp2")%in%fit$summary$Parameter), "Posterior summary exported."),
    add("Prevalence", "Report latent prevalence by population with uncertainty", any(grepl("^Prev",fit$summary$Parameter)), paste(sum(grepl("^Prev",fit$summary$Parameter)),"population prevalence estimates")),
    add("Dependence", "Report dependence parameters when dependence is modelled", fit$model=="independent"||all(c("CovD","CovH")%in%fit$summary$Parameter), if(fit$model=="independent")"Conditional-independence model" else "CovD/CovH exported"),
    add("Model checking", "Report convergence and posterior predictive/model-fit assessment", isTRUE(fit$diagnostics$acceptable)&&!is.null(fit$ppc), paste("MCMC acceptable:",fit$diagnostics$acceptable,"; PPC draws:",fit$ppc$n_draws)),
    add("Sensitivity analysis", "Assess sensitivity to priors/model assumptions", {
      current<-!is.null(sensitivity)&&identical(sensitivity$main_id,fit$id);failures<-if(current)sensitivity$failures %||% data.frame()else data.frame();requested<-if(current)sensitivity$requested %||% character()else character();current&&length(requested)>=2&&!nrow(failures)&&isTRUE(review$sensitivity)
    }, if(is.null(sensitivity))"Not run" else {bad<-if(length(sensitivity$fits %||% list()))names(sensitivity$fits)[!vapply(sensitivity$fits,function(x)isTRUE(x$diagnostics$acceptable),logical(1))]else character();paste0(length(sensitivity$requested %||% character())," scenarios requested; diagnostic warnings: ",if(length(bad))paste(bad,collapse=", ")else"none")}),
    add("Model comparison", "When scientifically relevant, compare dependence assumptions", !is.null(comparison)&&all(c("independent","positive")%in%names(comparison)), if(is.null(comparison))"Not run" else paste(names(comparison),collapse=", ")),
    add("Limitations", "Discuss non-identifiability, prior dependence, clustering and generalisability", isTRUE(review$identifiability)||fit$model=="independent", paste(known_limitations(),collapse=" | "))
  )
  do.call(rbind,out)
}

# 从单次、单分析物的保存拟合提取标准化汇总；同时保留敏感性计算失败与诊断状态。
analysis_publication_summary <- function(fit, comparison = NULL, sensitivity = NULL, review = list()) {
  s <- fit$summary
  getrow <- function(p) s[s$Parameter==p,,drop=FALSE]
  se1<-getrow("Se1");sp1<-getrow("Sp1");se2<-getrow("Se2");sp2<-getrow("Sp2")
  ctab <- posterior_contrasts(fit)
  dse <- ctab[ctab$Measure=="Delta_DSe",,drop=FALSE]; dsp <- ctab[ctab$Measure=="Delta_DSp",,drop=FALSE]
  sensitivity_current <- !is.null(sensitivity) && identical(sensitivity$main_id, fit$id)
  sensitivity_requested <- if(sensitivity_current) sensitivity$requested %||% character() else character()
  sensitivity_failures <- if(sensitivity_current) sensitivity$failures %||% data.frame() else data.frame()
  sensitivity_fits <- if(sensitivity_current) sensitivity$fits %||% list() else list()
  sensitivity_bad <- if(length(sensitivity_fits)) names(sensitivity_fits)[!vapply(sensitivity_fits,function(x)isTRUE(x$diagnostics$acceptable),logical(1))] else character()
  sensitivity_completed <- sensitivity_current && length(sensitivity_requested)>=2 && !nrow(sensitivity_failures) && isTRUE(review$sensitivity) && (!length(sensitivity_bad) || isTRUE(review$sensitivity_failed))
  data.frame(
    Project = as.character(fit$metadata$project_name %||% ""),
    Analyte = as.character(fit$metadata$pathogen %||% ""),
    T1 = as.character(fit$metadata$t1 %||% ""),
    T2 = as.character(fit$metadata$t2 %||% ""),
    Specimen = as.character(fit$metadata$specimen %||% ""),
    Analysis_ID = fit$id,
    Started = fit$started,
    Model = fit$model,
    N = sum(fit$cross$N),
    Populations = nrow(fit$cross),
    DSe1_Median=se1$Median,DSe1_Lower=se1$Lower,DSe1_Upper=se1$Upper,
    DSp1_Median=sp1$Median,DSp1_Lower=sp1$Lower,DSp1_Upper=sp1$Upper,
    DSe2_Median=se2$Median,DSe2_Lower=se2$Lower,DSe2_Upper=se2$Upper,
    DSp2_Median=sp2$Median,DSp2_Lower=sp2$Lower,DSp2_Upper=sp2$Upper,
    Delta_DSe_Median=dse$Median,Delta_DSe_Lower=dse$Lower,Delta_DSe_Upper=dse$Upper,Pr_DSe1_gt_DSe2=dse$Pr_T1_greater,
    Delta_DSp_Median=dsp$Median,Delta_DSp_Lower=dsp$Lower,Delta_DSp_Upper=dsp$Upper,Pr_DSp1_gt_DSp2=dsp$Pr_T1_greater,
    MCMC_pass=isTRUE(fit$diagnostics$acceptable),
    Sensitivity_completed=sensitivity_completed,
    Sensitivity_all_diagnostics_pass=sensitivity_current&&length(sensitivity_fits)>0&&all(vapply(sensitivity_fits,function(x)isTRUE(x$diagnostics$acceptable),logical(1))),
    Sensitivity_failed_scenarios=if(length(sensitivity_bad))paste(sensitivity_bad,collapse="; ")else"",
    Sensitivity_computational_failures=if(nrow(sensitivity_failures))paste(sensitivity_failures$Message,collapse="; ")else"",
    stringsAsFactors=FALSE
  )
}

# 将标准化摘要写为 JSON，记录模式版本和导出时间，便于与 CSV 交叉核对。
write_analysis_publication_summary <- function(fit, path, comparison=NULL, sensitivity=NULL, review=list()) {
  need_packages("jsonlite")
  record <- analysis_publication_summary(fit, comparison, sensitivity, review)
  payload <- as.list(record[1,,drop=FALSE])
  payload$schema_version <- 1L
  payload$exported_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  jsonlite::write_json(payload,path,pretty=TRUE,auto_unbox=TRUE,na="null",digits=NA)
  invisible(record)
}
