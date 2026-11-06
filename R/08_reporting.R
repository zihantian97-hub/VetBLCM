# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 可追溯 Excel/HTML/完整分析导出；方法与结果从保存的 fit 生成。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# 转义用户提供的文本，避免研究名称或说明被报告浏览器当作 HTML/脚本执行。
escape_html <- function(x) as.character(htmltools::htmlEscape(as.character(x)))
# 把数据框转换为可滚动的 HTML 表格；显示精度不改变保存在拟合对象中的数值。
html_table <- function(data,digits=4) {
  if(is.null(data)||!nrow(data)) return("<p>Not available / 暂无</p>")
  d<-as.data.frame(data);d[]<-lapply(d,function(x) if(is.numeric(x)) format(x,digits=digits,trim=TRUE) else as.character(x))
  head<-paste0("<th>",escape_html(names(d)),"</th>",collapse="")
  rows<-apply(d,1,function(x) paste0("<tr>",paste0("<td>",escape_html(x),"</td>",collapse=""),"</tr>"))
  paste0("<div class='table-wrap'><table><thead><tr>",head,"</tr></thead><tbody>",paste(rows,collapse=""),"</tbody></table></div>")
}
# 生成中英文文本节点，交由报告语言开关显示；统计数值不随语言改变。
language_span <- function(zh,en) paste0("<span class='zh'>",escape_html(zh),"</span><span class='en'>",escape_html(en),"</span>")
# 仅从保存的 fit/settings/provenance 生成方法草稿，避免当前界面设置与实际运行设置混淆。
methods_text <- function(fit,language="en") {
  s<-fit$settings;m<-fit$metadata
  if(language=="zh") return(sprintf("鉴于缺乏完美参考标准，对 %s 的两种检测结果采用贝叶斯潜类别模型进行评价。分析包含 %d 个群体，以四格计数的多项分布为似然，采用 %s 模型，假设群体间检测性能和条件协方差恒定。使用 JAGS %s，经 rjags %s 运行 %d 条链，每链适应 %d 次、预热 %d 次、后验采样 %d 次，间隔 %d 保留样本。下表列出实际先验及截断条件。报告后验中位数及等尾95%%可信区间，采用posterior计算R-hat、bulk/tail ESS，并进行后验预测检验。条件依赖模型的结构不可识别性仍需外部信息支持；收敛与拟合检查不能证明可识别性。",m$pathogen %||% "[未填写]",nrow(fit$cross),fit$model,fit$provenance$JAGS,fit$provenance$packages[["rjags"]],s$chains,s$adapt,s$burnin,s$iterations,s$thin))
  sprintf("Because no perfect reference standard was available, results from two tests for %s were analysed using a Bayesian latent class model across %d populations. A multinomial likelihood was fitted to cross-classified counts using the %s model, assuming constant test accuracy and within-class covariance across populations. JAGS %s through rjags %s ran %d chains, each with %d adaptation iterations, %d burn-in iterations and %d sampling iterations, retaining every %d iteration(s). Actual priors and truncation bounds are listed below. Posterior medians and equal-tailed 95%% credible intervals are reported. Rank-normalized R-hat and bulk/tail ESS were calculated with posterior, and replicated multinomial counts were used for posterior predictive checks. For dependent models, structural non-identifiability requires external information; acceptable convergence and predictive fit do not establish identifiability. Methods follow Branscum et al. (2005) and the recorded WOAH guidance.",m$pathogen %||% "[not provided]",nrow(fit$cross),fit$model,fit$provenance$JAGS,fit$provenance$packages[["rjags"]],s$chains,s$adapt,s$burnin,s$iterations,s$thin)
}
# 用保存的后验摘要生成结果草稿；审阅条件未满足时保留探索性声明。
results_text <- function(fit,language="en",review_ready=FALSE) {
  s<-fit$summary;a<-s[s$Parameter=="Se1",];b<-s[s$Parameter=="Sp1",]
  prefix<-if(!review_ready) if(language=="zh") "仅供探索；尚未满足正式解释条件。" else "Exploratory estimates; criteria for final interpretation are not satisfied. " else if(language=="zh") "以下估计仍须科学审阅。" else "These estimates remain subject to scientific review. "
  paste0(prefix,if(language=="zh") sprintf("T1的DSe后验中位数为%.1f%%（95%% CrI %.1f–%.1f%%），DSp为%.1f%%（95%% CrI %.1f–%.1f%%）。",100*a$Median,100*a$Lower,100*a$Upper,100*b$Median,100*b$Lower,100*b$Upper) else sprintf("The posterior median DSe of T1 was %.1f%% (95%% CrI %.1f–%.1f%%), and DSp was %.1f%% (95%% CrI %.1f–%.1f%%).",100*a$Median,100*a$Lower,100*a$Upper,100*b$Median,100*b$Lower,100*b$Upper))
}
# 集中记录基础模型的统计边界，供界面和导出报告重复使用。
known_limitations <- function() c("No perfect gold standard; latent class meaning requires a defensible case definition / 无完美金标准，潜在状态需要合理的病例定义","Priors and test dependence can materially influence posterior estimates / 先验和检测依赖可显著影响后验","Constant accuracy and dependence across populations are assumptions / 群体间性能和依赖恒定属于假设","Prevalence separation and representative sampling are not guaranteed by risk labels / 风险标签不保证患病率区分或代表性","Clustering and specimen heterogeneity are not corrected by the basic model / 基础模型不校正群内聚集与样品异质性","Two-test dependent models remain structurally non-identifiable without additional information / 两种依赖检测没有额外信息时结构不可识别","Automated diagnostics cannot exclude all multimodality, bias or prior dominance / 自动诊断不能排除所有多峰、偏倚或先验主导","Agreement statistics are not diagnostic accuracy against a perfect reference / 一致性指标不能当作真实DSe和DSp")
# 导出冻结数据、先验、结果、诊断及审阅表到多个工作表；样本流程矛盾会阻止误导性输出。
write_results_excel <- function(fit,path,comparison=NULL,sensitivity=NULL,review=list()) {
  need_packages("openxlsx");s<-fit$summary
  md<-data.frame(Field=names(fit$metadata),Value=vapply(fit$metadata,function(x)paste(x,collapse="; "),character(1)))
  checks<-review_checklist(fit,comparison,sensitivity,review)
  rules<-data.frame(Field=c("T1 positivity rule","T2 positivity rule","Equivocal handling","Invalid handling","Missing handling","Sample size rationale","Exclusion notes"),Value=c(fit$metadata$t1_positive_rule %||% "",fit$metadata$t2_positive_rule %||% "",fit$metadata$equivocal_handling %||% "",fit$metadata$invalid_handling %||% "",fit$metadata$missing_handling %||% "",fit$metadata$sample_size_rationale %||% "",fit$metadata$exclusion_notes %||% ""),stringsAsFactors=FALSE)
  tabs<-list(Project=md,Analysis_Summary=analysis_publication_summary(fit,comparison,sensitivity,review),Test_Rules=rules,Sample_Flow=sample_flow_table(fit),Raw_Data=fit$data,QC=data.frame(Message=c(fit$design$blockers,fit$design$warnings)),Cross_Tables=fit$cross,Priors=fit$priors$table,Posterior_Summary=s,Posterior_Contrasts=posterior_contrasts(fit),Prevalence=s[grepl("^Prev",s$Parameter),],Dependence=s[s$Parameter %in% c("CovD","CovH","uD","uH"),],Agreement=fit$agreement,MCMC_Diagnostics=fit$diagnostics$table,Prior_Sensitivity=sensitivity$table %||% data.frame(),Model_Comparison=if(!is.null(comparison)&&all(c("independent","positive") %in% names(comparison))) compare_models(comparison$independent,comparison$positive) else data.frame(),STARD_BLCM_Audit=stard_blcm_reporting_audit(fit,comparison,sensitivity,review),Warnings=data.frame(Message=unique(c(fit$design$blockers,fit$design$warnings,fit$diagnostics$flags,known_limitations()))),PPC=fit$ppc$table,Review_Checklist=checks,Model_Settings=data.frame(Setting=names(fit$settings),Value=unlist(fit$settings)),Analysis_Metadata=data.frame(Field=c("Analysis_ID","Started","R","JAGS","Input_SHA256","Model_SHA256"),Value=c(fit$id,fit$started,fit$provenance$R,fit$provenance$JAGS,fit$provenance$input_sha256,fit$provenance$model_sha256)))
  wb<-openxlsx::createWorkbook()
  for(n in names(tabs)) {
    openxlsx::addWorksheet(wb,n,gridLines=FALSE);d<-tabs[[n]];if(!ncol(d))d<-data.frame(Status="Not run / 未运行")
    openxlsx::writeData(wb,n,excel_display_data(d),headerStyle=openxlsx::createStyle(fgFill="#143D4D",fontColour="#FFFFFF",textDecoration="bold",halign="center",valign="center",wrapText=TRUE))
    openxlsx::freezePane(wb,n,firstRow=TRUE);openxlsx::setColWidths(wb,n,cols=seq_len(ncol(d)),widths=22);openxlsx::setRowHeights(wb,n,rows=1,heights=28)
    if(nrow(d)) {
      numeric_columns<-which(vapply(d,is.numeric,logical(1)))
      if(length(numeric_columns))openxlsx::addStyle(wb,n,openxlsx::createStyle(numFmt="0.000",halign="right"),rows=2:(nrow(d)+1),cols=numeric_columns,gridExpand=TRUE,stack=TRUE)
      count_columns<-which(names(d) %in% c("N","n11","n10","n01","n00","T1","T2","ess_bulk","ess_tail","Observed","Predicted_median","Lower","Upper") & n %in% c("Raw_Data","Cross_Tables","MCMC_Diagnostics","PPC"))
      if(length(count_columns))openxlsx::addStyle(wb,n,openxlsx::createStyle(numFmt="0"),rows=2:(nrow(d)+1),cols=count_columns,gridExpand=TRUE,stack=TRUE)
      if(n=="MCMC_Diagnostics") {
        openxlsx::addStyle(wb,n,openxlsx::createStyle(numFmt="0.0000"),rows=2:(nrow(d)+1),cols=which(names(d)=="rhat"),gridExpand=TRUE,stack=TRUE)
        openxlsx::addStyle(wb,n,openxlsx::createStyle(numFmt="0.00E+00"),rows=2:(nrow(d)+1),cols=which(names(d)=="mcse_mean"),gridExpand=TRUE,stack=TRUE)
      }
      if(n=="Priors") {
        source_columns<-which(names(d) %in% c("Source","Rationale","Source_population","Specimen","Estimate","Uncertainty","Applicability","Discount","Notes"))
        openxlsx::setColWidths(wb,n,cols=source_columns,widths=44)
        openxlsx::addStyle(wb,n,openxlsx::createStyle(wrapText=TRUE,valign="top"),rows=2:(nrow(d)+1),cols=seq_len(ncol(d)),gridExpand=TRUE,stack=TRUE)
        openxlsx::setRowHeights(wb,n,rows=2:(nrow(d)+1),heights=60)
      }
      if(n %in% c("Project","Test_Rules","STARD_BLCM_Audit","Analysis_Metadata","Warnings","QC")) {
        openxlsx::setColWidths(wb,n,cols=seq_len(ncol(d)),widths=if(ncol(d)==2)c(30,95)else 120)
        openxlsx::addStyle(wb,n,openxlsx::createStyle(wrapText=TRUE,valign="top"),rows=2:(nrow(d)+1),cols=seq_len(ncol(d)),gridExpand=TRUE,stack=TRUE)
        openxlsx::setRowHeights(wb,n,rows=2:(nrow(d)+1),heights=36)
      }
    }
  }
  save_vetblcm_workbook(wb,path);invisible(path)
}
# 生成可切换中英文的独立 HTML，嵌入图像及来源；状态来自实际审阅清单，不从文件是否成功导出推断。
export_blcm_report <- function(fit,path,comparison=NULL,sensitivity=NULL,review=list(),language="zh",figures=TRUE) {
  need_packages(c("htmltools","base64enc"));checks<-review_checklist(fit,comparison,sensitivity,review);ready<-all(checks$Pass[checks$Required]);advisory<-any(!checks$Pass&!checks$Required)
  section<-function(zh,en,body)paste0("<section><h2>",language_span(zh,en),"</h2>",body,"</section>")
  para<-function(zh,en)paste0("<p>",language_span(zh,en),"</p>")
  status<-if(ready&&advisory) language_span("必需检查已满足，但仍存在需保留解释的重要警告","Required checks complete, with important advisory warnings retained for interpretation") else if(ready) language_span("检查项目已满足，仍需科学审阅","Checklist complete; scientific review remains required") else language_span("探索性结果：不可作为最终DSe/DSp报告","EXPLORATORY — DO NOT REPORT AS FINAL DSe/DSp")
  body<-paste0("<h1>VetBLCM</h1><p>",language_span("兽医诊断试验贝叶斯潜类别评价","Bayesian Latent Class Analysis for Veterinary Diagnostic Test Validation"),"</p><div class='status'>",status,"</div>",para(analysis_status(fit,comparison,sensitivity,review,"zh")$label,analysis_status(fit,comparison,sensitivity,review,"en")$label),"<p>Analysis ID: ",escape_html(fit$id),"</p>")
  test_rules<-data.frame(Field=c("T1 positivity rule","T2 positivity rule","Equivocal handling","Invalid handling","Missing handling"),Value=c(fit$metadata$t1_positive_rule %||% "",fit$metadata$t2_positive_rule %||% "",fit$metadata$equivocal_handling %||% "",fit$metadata$invalid_handling %||% "",fit$metadata$missing_handling %||% ""),stringsAsFactors=FALSE)
  body<-paste0(body,section("研究信息","Study information",html_table(data.frame(Field=names(fit$metadata),Value=vapply(fit$metadata,function(x)paste(x,collapse="; "),character(1))))),section("检测判定规则","Test interpretation rules",html_table(test_rules)),section("样本纳入流程","Sample flow",html_table(sample_flow_table(fit))),section("结果草稿","Results draft",para(results_text(fit,"zh",ready),results_text(fit,"en",ready))),section("方法草稿","Methods draft",para(methods_text(fit,"zh"),methods_text(fit,"en"))),section("群体及四格数据","Populations and cross tables",paste0(html_table(fit$populations),html_table(fit$cross))),section("先验及实际分布","Priors and actual distributions",paste0(html_table(fit$priors$table),html_table(fit$priors$summary))),section("后验估计（比例单位）","Posterior estimates (proportion scale)",html_table(fit$summary)),section("T1与T2后验差异","Posterior contrasts: T1 versus T2",html_table(posterior_contrasts(fit))),section("MCMC诊断","MCMC diagnostics",html_table(fit$diagnostics$table)),section("后验预测检查","Posterior predictive checks",paste0(html_table(fit$ppc$table),"<p>P(Trep &gt;= Tobs | data) = ",format(fit$ppc$tail_probability,digits=3),"</p>")),section("一致性：不等于真实DSe/DSp","Agreement: not true DSe/DSp",html_table(fit$agreement)))
  if(!is.null(comparison)&&all(c("independent","positive") %in% names(comparison))) body<-paste0(body,section("独立与依赖模型比较","Independent/dependent model comparison",html_table(compare_models(comparison$independent,comparison$positive))))
  body<-paste0(body,section("先验敏感性","Prior sensitivity",paste0(html_table(sensitivity$table),html_table(sensitivity$failures))),section("STARD-BLCM报告审计","STARD-BLCM reporting audit",paste0(para("此表是VetBLCM对STARD-BLCM报告主题的映射辅助，不是对官方清单的逐字复制；投稿前仍应核对原始STARD-BLCM文件。","This is a VetBLCM mapping aid for STARD-BLCM reporting topics, not a verbatim reproduction of the official checklist. Consult the original STARD-BLCM publication before submission."),html_table(stard_blcm_reporting_audit(fit,comparison,sensitivity,review)))),section("审阅清单","Review checklist",html_table(checks)),section("已知限制与警告","Known limitations and warnings",paste0("<ul>",paste0("<li>",escape_html(unique(c(fit$design$blockers,fit$design$warnings,fit$diagnostics$flags,known_limitations()))),"</li>",collapse=""),"</ul>")))
  if(figures) {
    body<-paste0(body,para("以下链和先验示例图展示Se1。完整分析ZIP内的diagnostics_all_parameters.pdf包含全部关键参数的链、后验密度、先验对比和自相关；也可在软件中逐参数查看。","The trace and prior illustrations below show Se1. The complete analysis ZIP includes diagnostics_all_parameters.pdf with traces, posterior densities, prior overlays and autocorrelations for every key parameter; these are also available individually in the app."))
    body<-paste0(body,para("密度线为样本的平滑显示，边界附近可能出现平滑偏差；先验表列出实际分布和截断范围，区间估计直接由样本计算。","Density curves smooth sampled values and may show boundary bias. The prior table specifies the actual distributions and truncation bounds; interval estimates are calculated directly from draws."))
    flow_tmp<-tempfile(fileext=".png");ggplot2::ggsave(flow_tmp,plot_sample_flow(fit,"en"),width=9,height=5,dpi=130,bg="white")
    body<-paste0(body,"<figure><figcaption>sample flow</figcaption><img alt='sample flow' src='",base64enc::dataURI(file=flow_tmp,mime="image/png"),"'></figure>");unlink(flow_tmp)
    types<-c("observed","accuracy","prevalence","trace","prior","ppc","correlation","autocorrelation",if(!is.null(sensitivity)&&nrow(sensitivity$table))"sensitivity",if(!is.null(comparison))"comparison")
    for(type in types) {
      p<-plot_blcm(fit,type,parameter="Se1",sensitivity=sensitivity,comparison=comparison,language="en")
      tmp<-tempfile(fileext=".png");ggplot2::ggsave(tmp,p,width=9,height=5,dpi=130,bg="white")
      body<-paste0(body,"<figure><figcaption>",escape_html(type),"</figcaption><img alt='",escape_html(type),"' src='",base64enc::dataURI(file=tmp,mime="image/png"),"'></figure>");unlink(tmp)
    }
  }
  references<-paste(readLines(file.path(getOption("vetblcm.root","."),"docs","REFERENCES.md"),warn=FALSE,encoding="UTF-8"),collapse="\n")
  body<-paste0(body,section("模型和可复现信息","Model and reproducibility",paste0("<pre>",escape_html(fit$model_code),"</pre><pre>",escape_html(paste(fit$provenance$session_info,collapse="\n")),"</pre>")),section("参考资料","References",paste0("<pre>",escape_html(references),"</pre>")))
  html<-paste0("<!doctype html><html lang='",language,"'><meta charset='utf-8'><meta name='viewport' content='width=device-width'><title>VetBLCM report</title><style>body{font:16px/1.65 system-ui,'Microsoft YaHei',sans-serif;color:#17313c;max-width:1160px;margin:35px auto;padding:0 24px;background:#f5f8fa}section,figure{background:white;padding:22px;margin:20px 0;border-radius:12px}h1{font-size:36px}h2{font-size:23px}table{border-collapse:collapse;width:100%;font-size:13px}th,td{padding:8px;border-bottom:1px solid #dce5e9;text-align:left;vertical-align:top}th{background:#e9f0f3}.table-wrap{overflow:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:13px}.status{padding:20px;background:#fff0d9;border-left:5px solid #ba720f;font-weight:700}img{max-width:100%}html[lang=en] .zh,html[lang=zh] .en{display:none}button{padding:10px 18px;cursor:pointer}nav{position:sticky;top:0;background:#f5f8fa;padding:10px;z-index:1}</style><nav><button onclick=\"document.documentElement.lang='zh'\">中文</button> <button onclick=\"document.documentElement.lang='en'\">English</button></nav>",body,"</html>")
  writeLines(enc2utf8(html),path,useBytes=TRUE);invisible(path)
}
# 导出可恢复分析对象、模型、配置、CSV、Excel、HTML 和诊断图；这些文件共同构成运行证据。
export_analysis <- function(fit,directory,comparison=NULL,sensitivity=NULL,review=list(),language="zh",all_figures=TRUE) {
  need_packages(c("jsonlite","openxlsx"));dir.create(directory,recursive=TRUE,showWarnings=FALSE)
  saveRDS(list(fit=fit,comparison=comparison,sensitivity=sensitivity,review=review),file.path(directory,"analysis.rds"))
  utils::write.csv(fit$summary,file.path(directory,"posterior_summary.csv"),row.names=FALSE,fileEncoding="UTF-8")
  utils::write.csv(posterior_contrasts(fit),file.path(directory,"posterior_contrasts.csv"),row.names=FALSE,fileEncoding="UTF-8")
  utils::write.csv(sample_flow_table(fit),file.path(directory,"sample_flow.csv"),row.names=FALSE,fileEncoding="UTF-8")
  utils::write.csv(stard_blcm_reporting_audit(fit,comparison,sensitivity,review),file.path(directory,"STARD_BLCM_reporting_audit.csv"),row.names=FALSE,fileEncoding="UTF-8")
  analysis_summary<-write_analysis_publication_summary(fit,file.path(directory,"analysis_summary.json"),comparison,sensitivity,review)
  utils::write.csv(analysis_summary,file.path(directory,"analysis_summary.csv"),row.names=FALSE,fileEncoding="UTF-8")
  writeLines(fit$model_code,file.path(directory,"model_used.jags"),useBytes=TRUE)
  jsonlite::write_json(list(analysis_id=fit$id,metadata=fit$metadata,populations=fit$populations,settings=fit$settings,priors=fit$priors$table,initial_values=fit$initial_values,provenance=fit$provenance,review=review),file.path(directory,"analysis_settings.json"),pretty=TRUE,auto_unbox=TRUE,na="null",digits=NA)
  writeLines(fit$provenance$session_info,file.path(directory,"sessionInfo.txt"))
  write_results_excel(fit,file.path(directory,"VetBLCM_results.xlsx"),comparison,sensitivity,review)
  export_blcm_report(fit,file.path(directory,"report.html"),comparison,sensitivity,review,language)
  for(kind in names(comparison)) {dir.create(file.path(directory,kind),showWarnings=FALSE);writeLines(comparison[[kind]]$model_code,file.path(directory,kind,"model_used.jags"));jsonlite::write_json(list(settings=comparison[[kind]]$settings,priors=comparison[[kind]]$priors$table,initial_values=comparison[[kind]]$initial_values,provenance=comparison[[kind]]$provenance),file.path(directory,kind,"settings.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA)}
  if(!is.null(sensitivity)) for(i in seq_along(sensitivity$fits)) {sf<-sensitivity$fits[[i]];folder<-file.path(directory,paste0("scenario_",i));dir.create(folder,showWarnings=FALSE);writeLines(sf$model_code,file.path(folder,"model_used.jags"));jsonlite::write_json(list(name=names(sensitivity$fits)[i],settings=sf$settings,priors=sf$priors$table,initial_values=sf$initial_values,provenance=sf$provenance),file.path(folder,"settings.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA)}
  if(all_figures) {
    folder<-file.path(directory,"figures");dir.create(folder,showWarnings=FALSE)
    types<-c("observed","accuracy","prevalence","trace","prior","ppc","correlation","autocorrelation",if(!is.null(sensitivity)&&nrow(sensitivity$table))"sensitivity",if(!is.null(comparison))"comparison")
    for(type in types) for(ext in c("png","svg","pdf")) {
      p<-plot_blcm(fit,type,parameter="Se1",sensitivity=sensitivity,comparison=comparison,language="en")
      target<-file.path(folder,paste0(type,".",ext));ggplot2::ggsave(target,p,width=9,height=5,dpi=180,bg="white",device=switch(ext,svg=grDevices::svg,pdf=grDevices::pdf,png="png"))
    }
    flow_plot<-plot_sample_flow(fit,"en")
    for(ext in c("png","svg","pdf"))ggplot2::ggsave(file.path(folder,paste0("sample_flow.",ext)),flow_plot,width=9,height=5,dpi=180,bg="white",device=switch(ext,svg=grDevices::svg,pdf=grDevices::pdf,png="png"))
    export_diagnostic_pages(fit,file.path(folder,"diagnostics_all_parameters.pdf"))
  }
  invisible(directory)
}
