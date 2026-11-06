# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 会话状态和操作流程；读取、拟合、敏感性分析、恢复、导出之间通过保存对象传递信息。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# Shiny 服务端：rv 保存会话状态，reactive 派生界面结果，observeEvent 响应明确操作；fit 是冻结的分析记录。
app_server <- function(input,output,session) {
  # data/priors 是编辑状态；fit/comparison/sensitivity 是已运行结果。数据变动时需清除不再对应的结果。
  rv<-shiny::reactiveValues(data=NULL,mode="sample",priors=NULL,populations=NULL,fit=NULL,comparison=NULL,sensitivity=NULL,scenarios=list(),project=list(),status="",pending_settings=NULL,local_save_status="",last_save_dir=NULL,last_save_id=NULL,current_page="project")
  lang<-shiny::reactive(input$language %||% "zh");tr<-function(zh,en) if(lang()=="zh") zh else en
  message_error<-function(e) {rv$status<-conditionMessage(e);shiny::showNotification(conditionMessage(e),type="error",duration=NULL)}
  safe<-function(fun) tryCatch(fun(),error=message_error)
  preset_placeholder<-function(x) any(grepl("请填写|请补充|请选择|enter exact|provide specific|select a|replace with",as.character(x),ignore.case=TRUE))
  replicate_rule_text<-function(which_test){
    code<-input[[paste0(which_test,"_replicate_rule")]] %||% ""
    if(code=="1of2")return(tr("至少1/2个技术重复孔满足阳性标准","at least 1 of 2 technical replicates meets the positivity rule"))
    if(code=="2of2")return(tr("2/2个技术重复孔均满足阳性标准","both 2 of 2 technical replicates meet the positivity rule"))
    if(code=="2of3")return(tr("至少2/3个技术重复孔满足阳性标准","at least 2 of 3 technical replicates meet the positivity rule"))
    if(code=="3of3")return(tr("3/3个技术重复孔均满足阳性标准","all 3 of 3 technical replicates meet the positivity rule"))
    if(code=="custom"){
      z<-trimws(input[[paste0(which_test,"_replicate_custom")]] %||% "")
      return(if(nzchar(z))z else tr("[请填写自定义重复孔规则]","[provide the custom replicate rule]"))
    }
    tr("[请选择重复孔规则]","[select a replicate rule]")
  }
  test_rule_template<-function(code,which_test){
    cutoff<-trimws(input[[paste0(which_test,"_ct_cutoff")]] %||% "");op<-input[[paste0(which_test,"_ct_operator")]] %||% "<=";op_text<-if(op=="<")"<"else"≤"
    cutoff_txt<-if(nzchar(cutoff))cutoff else tr("[请填写具体Ct阈值]","[enter exact Ct cutoff]")
    if(code=="qpcr_curve") return(tr(paste0("qPCR判阳：Ct ",op_text," ",cutoff_txt,"，且扩增曲线符合预设有效曲线标准。"),paste0("qPCR positive: Ct ",op_text," ",cutoff_txt," with a valid amplification curve according to the prespecified rule.")))
    if(code=="qpcr_replicate") {rr<-replicate_rule_text(which_test);return(tr(paste0("qPCR判阳：Ct ",op_text," ",cutoff_txt,"，扩增曲线有效，并且",rr,"。"),paste0("qPCR positive: Ct ",op_text," ",cutoff_txt,", with a valid amplification curve, and ",rr,".")))}
    if(code=="sop") return(tr("按研究开始前已确定并验证的SOP/试剂盒说明书算法判阳；具体版本和判定条件记录于研究资料。","Positive according to the validated SOP/kit algorithm prespecified before analysis; the exact version and decision criteria are documented in the study record."))
    if(code=="reference") {ref<-if(which_test=="t2")trimws(input$comparator_reference %||% "")else trimws(input$t1_rule_reference %||% "");return(if(nzchar(ref))paste0(tr("严格按已引用标准/论文/SOP规定的阳性判定规则执行：","Positive exactly according to the cited standard/publication/SOP: "),ref) else tr("严格按已引用标准/论文/SOP规定的阳性判定规则执行；[请填写具体来源]。","Positive exactly according to the cited standard/publication/SOP; [provide specific source]."))}
    ""
  }
  rationale_by_risk<-function(level){
    if(level=="lower")return(tr("基于独立于当前T1/T2结果的预先流行病学信息，预期该群体真实患病率/感染概率低于其他研究群体；该分层仅用于提供患病率差异，不对Se/Sp施加顺序约束。","Based on prespecified epidemiologic information independent of current T1/T2 results, this population is expected to have a lower true prevalence/infection probability than the other study populations; this stratification supplies prevalence contrast and does not impose ordering on Se/Sp."))
    if(level=="intermediate")return(tr("基于独立于当前T1/T2结果的预先流行病学信息，预期该群体真实患病率/感染概率处于研究群体的中间水平；该分层仅用于提供患病率差异，不对Se/Sp施加顺序约束。","Based on prespecified epidemiologic information independent of current T1/T2 results, this population is expected to have an intermediate true prevalence/infection probability; this stratification supplies prevalence contrast and does not impose ordering on Se/Sp."))
    if(level=="higher")return(tr("基于独立于当前T1/T2结果的预先流行病学信息，预期该群体真实患病率/感染概率高于其他研究群体；该分层仅用于提供患病率差异，不对Se/Sp施加顺序约束。","Based on prespecified epidemiologic information independent of current T1/T2 results, this population is expected to have a higher true prevalence/infection probability than the other study populations; this stratification supplies prevalence contrast and does not impose ordering on Se/Sp."))
    tr("该群体依据独立于当前T1/T2结果的预设流行病学特征分层；不预设患病率顺序，仅要求研究设计中存在合理的患病率差异来源。","This population is stratified using prespecified epidemiologic features independent of current T1/T2 results; no prevalence ordering is imposed, but the design should provide a plausible source of prevalence contrast.")
  }
  population_detail_choices<-function(basis){
    common<-c("请选择 / Select"="")
    x<-switch(basis,
      composite=c("按≥2项预设流行病学因素形成综合风险层级 / Composite stratum from >=2 prespecified epidemiological factors"="composite_multi","按预设风险评分/算法分层 / Prespecified risk score/algorithm"="custom"),
      geography=c("来自预先指定的本地区/本体系来源 / Prespecified local/within-system source"="geo_local","来自预先指定的外地区/外体系来源 / Prespecified external/outside-system source"="geo_external","其他具体地区/来源 / Other geography/source"="custom"),
      clinical=c("无目标疾病相关临床/繁殖异常史 / No relevant clinical/reproductive history"="clinical_absent","存在目标疾病相关临床/繁殖异常史 / Relevant clinical/reproductive history present"="clinical_present","有流产/繁殖障碍史 / History of abortion/reproductive disorder"="abortion_history","其他临床标准 / Other clinical criterion"="custom"),
      herd_history=c("既往监测无阳性/无已知感染史 / No previous positive surveillance or known infection"="history_negative","既往监测阳性或有已知感染/暴露史 / Previous positive surveillance or known infection/exposure"="history_positive","既往状态未知 / Previous status unknown"="history_unknown","其他既往状态 / Other herd-history criterion"="custom"),
      exposure=c("无已知高风险暴露 / No known high-risk exposure"="exposure_none","存在预先定义的高风险暴露 / Prespecified high-risk exposure present"="exposure_present","生物安全水平较高/无预设缺口 / Higher biosecurity/no prespecified gap"="biosecurity_higher","存在预设生物安全缺口 / Prespecified biosecurity gap present"="biosecurity_gap","其他暴露/生物安全标准 / Other exposure/biosecurity criterion"="custom"),
      management=c("封闭或自繁自养体系 / Closed or self-replacing system"="management_closed","开放体系或存在外源引入 / Open system or external introductions"="management_open","按预先指定生产类型分层 / Prespecified production type"="custom"),
      temporal=c("预先指定研究时期/监测批次 / Prespecified study period/surveillance round"="temporal_round","其他时间分层 / Other temporal criterion"="custom"),
      custom=c("其他/自定义 / Other/custom"="custom"),character())
    c(common,x)
  }
  population_detail_text<-function(code){
    switch(code,
      composite_multi=tr("由至少两项在查看T1/T2结果前预先确定的流行病学因素组合定义。","Defined by a combination of at least two epidemiological factors prespecified before reviewing T1/T2 results."),
      geo_local=tr("来自研究方案预先指定的本地区/本体系来源。","Originates from the local/within-system source category prespecified in the study protocol."),
      geo_external=tr("来自研究方案预先指定的外地区/外体系来源。","Originates from the external/outside-system source category prespecified in the study protocol."),
      clinical_absent=tr("在分组时无预先定义的目标疾病相关临床或繁殖异常史。","No prespecified target-disease-related clinical or reproductive history at grouping."),
      clinical_present=tr("在分组时存在预先定义的目标疾病相关临床或繁殖异常史。","A prespecified target-disease-related clinical or reproductive history was present at grouping."),
      abortion_history=tr("在分组时有预先定义的流产或繁殖障碍史。","A prespecified history of abortion or reproductive disorder was present at grouping."),
      history_negative=tr("分组前既往监测无阳性记录且无已知感染史。","Before grouping, previous surveillance had no positive record and there was no known infection history."),
      history_positive=tr("分组前存在既往监测阳性记录或已知感染/暴露史。","Before grouping, there was a previous positive surveillance record or known infection/exposure history."),
      history_unknown=tr("分组前既往感染/监测状态未知，并作为预先定义的独立层级保留。","Previous infection/surveillance status was unknown and retained as a prespecified independent stratum."),
      exposure_none=tr("分组前无研究方案预先定义的高风险暴露。","No high-risk exposure prespecified by the study protocol was present before grouping."),
      exposure_present=tr("分组前存在研究方案预先定义的高风险暴露。","A high-risk exposure prespecified by the study protocol was present before grouping."),
      biosecurity_higher=tr("按研究方案定义为较高生物安全水平，且无预先定义的关键生物安全缺口。","Classified by protocol as higher biosecurity with no prespecified key biosecurity gap."),
      biosecurity_gap=tr("存在研究方案预先定义的关键生物安全缺口。","A key biosecurity gap prespecified by the study protocol was present."),
      management_closed=tr("按研究方案定义为封闭或自繁自养管理体系。","Classified by protocol as a closed or self-replacing management system."),
      management_open=tr("按研究方案定义为开放管理体系或存在外源动物/繁殖投入品引入。","Classified by protocol as an open management system or one receiving external animals/reproductive inputs."),
      temporal_round=tr("属于研究方案预先指定的研究时期或监测批次。","Belongs to a study period or surveillance round prespecified in the study protocol."),"")
  }
  page_ids<-c("project","data","qc","populations","priors","model","run","diagnostics","results","sensitivity","agreement","publication","export","help")
  page_zh<-c("1 研究信息","2 导入数据","3 数据检查","4 群体定义","5 先验","6 模型设置","7 运行","8 诊断","9 结果","10 敏感性","11 一致性","12 论文输出","13 导出","14 方法与帮助")
  page_en<-c("1 Project","2 Import data","3 Data QC","4 Populations","5 Priors","6 Model setup","7 Run models","8 Diagnostics","9 Results","10 Sensitivity","11 Agreement","12 Publication outputs","13 Export","14 Methods & help")
  page_index<-function(x) match(x,page_ids)
  nonblank<-function(x) length(x)>0&&all(!is.na(x)&nzchar(trimws(as.character(x))))
  validation_result<-function(errors=character(),warnings=character()) list(valid=!length(errors),errors=unique(errors),warnings=unique(warnings))
  page_hard_blockers<-function(page) tryCatch({
    blockers<-character()
    data_ready<-function(){
      if(is.null(rv$data)) return(FALSE)
      q<-tryCatch(validate_blcm_data(rv$data,rv$mode),error=function(e)NULL)
      !is.null(q)&&isTRUE(q$valid)
    }
    if(page%in%c("data","qc","populations")) {
      if(!data_ready()) blockers<-c(blockers,tr("需要先成功导入并解析有效的检测数据，才能继续后续数据流程。","Valid test data must be imported and parsed successfully before continuing the data workflow."))
    } else if(identical(page,"priors")) {
      if(!data_ready()) blockers<-c(blockers,tr("没有可用于建立先验参数表的有效数据。","No valid data are available to establish the prior table."))
      if(is.null(rv$priors)) blockers<-c(blockers,tr("先验参数表尚不存在。请先成功导入数据以建立参数表。","The prior table does not exist yet. Import valid data first to create it."))
    } else if(identical(page,"model")) {
      if(!data_ready()) blockers<-c(blockers,tr("没有有效数据，无法进入可运行的模型流程。","No valid data are available for a runnable model workflow."))
      if(is.null(rv$priors)) blockers<-c(blockers,tr("没有先验参数表，模型无法运行。","No prior table is available, so the model cannot run."))
    } else if(page%in%c("run","diagnostics","results","sensitivity","publication","export")) {
      if(is.null(rv$fit)) blockers<-c(blockers,tr("当前没有任何成功拟合的模型结果。请先在第7页运行模型。","No successfully fitted model result is available. Run a model on Page 7 first."))
    } else if(identical(page,"agreement")) {
      if(!data_ready()) blockers<-c(blockers,tr("没有有效的成对检测数据，无法计算一致性。","No valid paired test data are available for agreement analysis."))
    }
    unique(blockers)
  },error=function(e)conditionMessage(e))
  page_validation<-function(page) tryCatch({
    errors<-warnings<-character()
    if(identical(page,"project")) {
      req<-c(project_name="项目名称 / Project name",pathogen="病原/分析物 / Pathogen/analyte",t1="T1待评价检测 / T1 new assay",t2="T2对照检测 / T2 comparator",comparator_reference="T2文献或标准 / Comparator reference",specimen="样品类型 / Specimen",target_population="目标群体 / Target population",source_population="来源群体 / Source population",case_definition="潜在目标状态定义 / Latent target definition",t1_positive_rule="T1判阳规则 / T1 positivity rule",t2_positive_rule="T2判阳规则 / T2 positivity rule",equivocal_handling="可疑结果处理 / Equivocal handling",invalid_handling="无效结果处理 / Invalid handling",missing_handling="缺失结果处理 / Missing handling")
      missing<-names(req)[!vapply(names(req),function(k)nonblank(input[[k]] %||% ""),logical(1))]
      if(length(missing)) errors<-c(errors,paste0(tr("请填写：","Complete: "),paste(unname(req[missing]),collapse=", ")))
      if(!nonblank(input$unit %||% "")) errors<-c(errors,tr("请选择分析单位。","Select the unit of analysis."))
      if(!nonblank(input$purpose %||% "")) errors<-c(errors,tr("请选择研究目的。","Select the study purpose."))
      for(k in c("case_definition","t1_positive_rule","t2_positive_rule")) if(nonblank(input[[k]] %||% "")&&preset_placeholder(input[[k]])) errors<-c(errors,tr("检测/目标状态模板中仍有待补充占位内容，请填写具体阈值、重复孔规则或来源。","A target/test-rule template still contains placeholders; enter the exact cutoff, replicate rule, or source."))
    } else if(identical(page,"data")) {
      if(is.null(rv$data)) errors<-c(errors,tr("请先导入逐样品数据或四格表。","Import sample-level data or an aggregated cross table first.")) else {
        q<-validate_blcm_data(rv$data,rv$mode);if(!q$valid)errors<-c(errors,q$errors);warnings<-c(warnings,q$warnings)
        if(q$valid&&nrow(build_cross_tables(rv$data,rv$mode))<2) errors<-c(errors,tr("至少需要两个群体。","At least two populations are required."))
        if(q$valid){final_n<-sum(build_cross_tables(rv$data,rv$mode)$N);assessed<-suppressWarnings(as.numeric(input$samples_assessed %||% NA_real_));if(!is.finite(assessed)||assessed!=floor(assessed)||assessed<final_n)errors<-c(errors,paste0(tr("进入筛选的样本总数必须不小于最终可分析样本数：","Total samples assessed must be at least the final analysable sample size: "),final_n))}
      }
      if(!nonblank(input$exclusion_notes %||% ""))errors<-c(errors,tr("请记录排除数量及原因；如果没有排除，也请明确写“无”。","Record exclusions and reasons; if none, state this explicitly."))
      if(!nonblank(input$sample_size_rationale %||% ""))errors<-c(errors,tr("请记录样本量确定依据。","Record the sample-size rationale.")) else if(preset_placeholder(input$sample_size_rationale))errors<-c(errors,tr("样本量依据模板中仍有待补充占位内容，请填写具体计算方法/方案。","The sample-size rationale still contains template placeholders; provide the specific calculation method or protocol."))
    } else if(identical(page,"qc")) {
      if(is.null(rv$data)) errors<-c(errors,tr("没有可检查的数据。","No data are available for QC.")) else {
        q<-validate_blcm_data(rv$data,rv$mode);if(!q$valid)errors<-c(errors,q$errors);warnings<-c(warnings,q$warnings)
        if(q$valid&&nrow(build_cross_tables(rv$data,rv$mode))<2)errors<-c(errors,tr("至少需要两个群体。","At least two populations are required."))
      }
      if(!isTRUE(input$qc_reviewed))errors<-c(errors,tr("请勾选已查看数据质量检查、四格表和警告。","Confirm that you reviewed the QC checks, cross table and warnings."))
    } else if(identical(page,"populations")) {
      if(is.null(rv$populations)||!nrow(rv$populations)) errors<-c(errors,tr("群体定义尚未建立。","Population definitions are not available.")) else {
        fields<-c("Definition","Rationale","Prior_source")
        if(!all(fields%in%names(rv$populations))) errors<-c(errors,tr("群体定义表缺少必要字段。","The population table is missing required fields.")) else {
          bad<-which(!apply(rv$populations[,fields,drop=FALSE],1,function(z)all(nzchar(trimws(as.character(z))))))
          if(length(bad))errors<-c(errors,paste0(tr("请完整填写以下群体的定义、流行病学理由和先验来源：","Complete definition, epidemiological rationale and prior source for: "),paste(rv$populations$Population[bad],collapse=", ")))
          ph<-which(apply(rv$populations[,fields,drop=FALSE],1,function(z)preset_placeholder(z)))
          if(length(ph))errors<-c(errors,paste0(tr("以下群体仍包含模板占位内容，请补充具体可复现分组标准或证据来源：","These populations still contain template placeholders; add reproducible grouping criteria or the specific evidence source: "),paste(rv$populations$Population[ph],collapse=", ")))
          weak_src<-which(grepl("无量化外部证据|No quantitative external evidence",rv$populations$Prior_source,ignore.case=TRUE))
          if(length(weak_src))warnings<-c(warnings,paste0(tr("以下群体仅有预设分层、无量化外部证据；可以分析，但应在论文中说明该限制：","The following groups use prespecified stratification without quantitative external evidence; analysis is allowed but this limitation should be reported: "),paste(rv$populations$Population[weak_src],collapse=", ")))
        }
      }
      if(!isTRUE(input$grouping_independent))errors<-c(errors,tr("必须确认群体分组独立于当前T1/T2结果。","Confirm that population grouping is independent of current T1/T2 results."))
      if(!identical(input$procedures_comparable,"yes"))errors<-c(errors,tr("必须确认群体间样品和检测程序可比；若不能确认，基础模型不应继续。","Specimen and test procedures must be confirmed comparable across populations before using the basic model."))
      if(!is.null(rv$data)) {
        q<-validate_blcm_data(rv$data,rv$mode);warnings<-c(warnings,q$warnings)
        if(any(grepl("Mixed specimen",q$warnings,fixed=TRUE)))errors<-c(errors,tr("检测到混合样品类型，基础模型不支持正式合并推断。","Mixed specimen types were detected; the basic model does not support final pooled inference."))
        if(rv$mode=="sample") {h<-herd_summary(rv$data);if(isTRUE(h$clustered))errors<-c(errors,tr("检测到群内聚集；基础似然未校正群内相关，不能继续正式推断。","Within-herd clustering was detected; the basic likelihood does not adjust for it."));if(!isTRUE(h$known)&&!isTRUE(input$independent_sampling))errors<-c(errors,tr("Herd_ID不完整时必须确认分析单位独立抽样。","When Herd_ID is incomplete, confirm independent sampling of analytical units."))}
      }
    } else if(identical(page,"priors")) {
      if(is.null(rv$data)||is.null(rv$priors)) errors<-c(errors,tr("请先完成数据导入并建立先验表。","Import data and establish the prior table first.")) else {
        pop<-build_cross_tables(rv$data,rv$mode)$Population
        prior_check_model<-if(all(c("uD","uH")%in%rv$priors$Parameter))"positive" else "independent"
        z<-tryCatch(resolve_priors(rv$priors,pop,prior_check_model),error=function(e)e)
        if(inherits(z,"error")) errors<-c(errors,conditionMessage(z)) else {
          p<-z$table;informative<-abs(p$Alpha-1)>1e-12|abs(p$Beta-1)>1e-12|p$Lower>0|p$Upper<1
          if(any(informative)) {
            essential_bad<-which(informative&(!nzchar(trimws(p$Source_type))|!nzchar(trimws(p$Rationale))))
            if(length(essential_bad))errors<-c(errors,paste0(tr("以下信息性先验至少需要来源类型和理由：","Informative priors require at least a source type and rationale: "),paste(p$Parameter[essential_bad],collapse=", ")))
            cited<-informative&p$Source_type%in%c("literature","external data");missing_source<-which(cited&!nzchar(trimws(p$Source)))
            if(length(missing_source))errors<-c(errors,paste0(tr("以下文献/外部数据先验缺少具体引用或来源：","Literature/external-data priors are missing a citation/source: "),paste(p$Parameter[missing_source],collapse=", ")))
            provenance<-c("Source_population","Specimen","Assay","Estimate","Uncertainty","Applicability","Discount")
            if(all(provenance%in%names(p))){incomplete<-which(informative&!apply(p[,provenance,drop=FALSE],1,function(z)all(nzchar(trimws(as.character(z))))));if(length(incomplete))warnings<-c(warnings,paste0(tr("以下信息性先验尚有完整来源/适用性字段未填写；正式报告清单仍会提示：","Some full provenance/applicability fields remain incomplete for informative priors; the final-report checklist will still flag: "),paste(p$Parameter[incomplete],collapse=", ")))}
          }
        }
      }
      if(!isTRUE(input$priors_independent))errors<-c(errors,tr("必须确认先验来源独立于当前研究数据。","Confirm that prior sources are independent of the current study data."))
    } else if(identical(page,"model")) {
      if(is.null(rv$data)||is.null(rv$priors)) errors<-c(errors,tr("请先完成数据、群体和先验步骤。","Complete data, population and prior steps first.")) else {
        design<-tryCatch(check_blcm_design(rv$data,rv$mode,input$model_type,metadata(),rv$populations),error=function(e)e)
        if(inherits(design,"error"))errors<-c(errors,conditionMessage(design)) else {errors<-c(errors,design$blockers);warnings<-c(warnings,design$warnings)}
        rp<-tryCatch(resolve_priors(rv$priors,build_cross_tables(rv$data,rv$mode)$Population,input$model_type),error=function(e)e)
        if(inherits(rp,"error"))errors<-c(errors,paste0(tr("当前模型所需先验未通过：","Priors required by the selected model failed validation: "),conditionMessage(rp)))
      }
      if(!isTRUE(input$label_confirmed)||!nonblank(input$label_rationale %||% ""))errors<-c(errors,tr("请确认潜在感染类别解释，并填写外部证据或限制依据。","Confirm the latent infection-class interpretation and document its external evidence or restrictions."))
      if(identical(input$mcmc_mode,"final")&&(is.null(input$chains)||input$chains<4))errors<-c(errors,tr("Final模式至少使用4条链。","Final mode requires at least four chains."))
      s<-tryCatch(settings(),error=function(e)e);if(inherits(s,"error"))errors<-c(errors,conditionMessage(s))
    } else if(identical(page,"run")) {
      if(is.null(rv$fit)) errors<-c(errors,tr("尚未成功运行模型。请运行主模型或独立+正依赖模型。","No model has been fitted successfully. Run the primary model or the independent + positive models.")) else {
        if(!identical(rv$fit$model,input$model_type))errors<-c(errors,tr("当前显示的拟合结果与所选主模型不一致，请重新运行。","The fitted result does not match the selected primary model; rerun the model."))
        cs<-tryCatch(settings(),error=function(e)e);if(inherits(cs,"error"))errors<-c(errors,conditionMessage(cs)) else if(!isTRUE(all.equal(cs,rv$fit$settings,check.attributes=FALSE)))errors<-c(errors,tr("当前MCMC设置与该拟合使用的设置不一致，请重新运行。","The current MCMC settings differ from those used for this fit; rerun it."))
        if(!identical(rv$fit$provenance$input_sha256,sha256(rv$data)))errors<-c(errors,tr("当前数据与该拟合使用的数据不一致，请重新运行。","The current data differ from those used for this fit; rerun it."))
        if(!isTRUE(all.equal(metadata(),rv$fit$metadata,check.attributes=FALSE)))errors<-c(errors,tr("研究信息或设计确认在拟合后发生变化，请重新运行模型。","Study metadata or design confirmations changed after fitting; rerun the model."))
        if(!isTRUE(all.equal(rv$populations,rv$fit$populations,check.attributes=FALSE)))errors<-c(errors,tr("群体定义在拟合后发生变化，请重新运行模型。","Population definitions changed after fitting; rerun the model."))
        cp<-tryCatch(resolve_priors(rv$priors,rv$fit$cross$Population,rv$fit$model)$table,error=function(e)e);if(inherits(cp,"error"))errors<-c(errors,conditionMessage(cp)) else if(!isTRUE(all.equal(cp,rv$fit$priors$table,check.attributes=FALSE)))errors<-c(errors,tr("主分析先验在拟合后发生变化，请重新运行主模型；第10页Alternative应直接上传情景文件，不要修改Main先验。","Main-analysis priors changed after fitting; rerun the main model. Upload Alternative scenario files directly on page 10 instead of altering Main priors."))
      }
    } else if(identical(page,"diagnostics")) {
      if(is.null(rv$fit)) errors<-c(errors,tr("没有可诊断的拟合结果。","No fitted result is available for diagnostics.")) else {
        if(!isTRUE(rv$fit$diagnostics$acceptable))errors<-c(errors,c(tr("MCMC收敛/ESS目标未通过，不能进入正式结果解释。","MCMC convergence/ESS targets were not met; do not proceed to final interpretation."),rv$fit$diagnostics$flags))
        if(!isTRUE(input$review_visual))errors<-c(errors,tr("请完成人工链、密度、边界和多峰检查。","Complete the manual trace, density, boundary and multimodality review."))
        if(!isTRUE(input$review_ppc))errors<-c(errors,tr("请审阅PPC拟合及其局限。","Review posterior predictive fit and its limitations."))
        if(rv$fit$model!="independent"&&!isTRUE(input$review_identifiability))errors<-c(errors,tr("依赖模型必须审阅结构不可识别性和外部信息。","Dependent models require review of structural non-identifiability and external information."))
        if(!nonblank(input$review_notes %||% ""))errors<-c(errors,tr("请填写科学审阅记录。","Enter scientific review notes."))
      }
    } else if(identical(page,"results")) {
      if(is.null(rv$fit))errors<-c(errors,tr("没有后验结果。","No posterior result is available."))
      if(!isTRUE(input$review_results))errors<-c(errors,tr("请确认已审阅后验估计、可信区间和当前警告。","Confirm that you reviewed posterior estimates, credible intervals and current warnings."))
    } else if(identical(page,"sensitivity")) {
      if(is.null(rv$fit))errors<-c(errors,tr("没有主模型结果。","No primary fit is available.")) else if(is.null(rv$sensitivity)||!identical(rv$sensitivity$main_id,rv$fit$id))errors<-c(errors,tr("尚未针对当前主模型完成先验敏感性分析。","Prior sensitivity analysis has not been completed for the current primary fit.")) else {
        sf<-rv$sensitivity$fits %||% list();sp<-rv$sensitivity$priors %||% list();requested<-rv$sensitivity$requested %||% character()
        if(length(requested)<2)errors<-c(errors,tr("至少需要运行Weak和一个非弱Alternative情景。","Run at least the Weak scenario and one non-weak Alternative scenario."))
        failures<-rv$sensitivity$failures %||% data.frame()
        if(nrow(failures))errors<-c(errors,paste0(tr("以下敏感性情景未完成计算，必须修复后重跑：","The following sensitivity scenarios did not complete computationally and must be fixed and rerun: "),paste(failures$Message,collapse="; ")))
        weak_present<-length(sp)&&any(vapply(sp,function(pp)is_weak_prior_scenario(pp,rv$fit),logical(1)))
        alternative_present<-length(sp)&&any(vapply(sp,function(pp){main<-rv$fit$priors$table;z<-pp[match(main$Parameter,pp$Parameter),,drop=FALSE];changed<-!isTRUE(all.equal(z[c("Alpha","Beta","Lower","Upper")],main[c("Alpha","Beta","Lower","Upper")],check.attributes=FALSE));nonweak<-!is_weak_prior_scenario(pp,rv$fit);changed&&nonweak},logical(1)))
        if(!weak_present)errors<-c(errors,tr("敏感性分析需要包含Weak弱先验情景。","Sensitivity analysis must include a Weak-prior scenario."))
        if(!alternative_present)errors<-c(errors,tr("敏感性分析需要包含一个直接上传并有依据的非弱Alternative先验情景。","Sensitivity analysis must include a justified non-weak Alternative scenario uploaded directly on this page."))
        bad<-if(length(sf))names(sf)[!vapply(sf,function(x)isTRUE(x$diagnostics$acceptable),logical(1))]else character()
        if(length(bad)){
          warnings<-c(warnings,paste0(tr("以下情景已完成计算但未通过MCMC诊断；保留用于敏感性审查，不作为有效参数估计解释：","The following scenarios completed but failed MCMC diagnostics; retain them for sensitivity review but do not interpret their parameter estimates as valid inference: "),paste(bad,collapse=", ")))
          if(!isTRUE(input$review_sensitivity_failed))errors<-c(errors,tr("请确认已审阅未通过MCMC诊断的情景，并理解其仅作为敏感性/识别性证据。","Confirm that you reviewed the scenarios that failed MCMC diagnostics and understand that they are retained only as sensitivity/identifiability evidence."))
        }
      }
      if(!isTRUE(input$review_sensitivity))errors<-c(errors,tr("请确认已审阅所有情景的先验变化、估计变化和诊断结果。","Confirm that you reviewed prior changes, estimate changes and diagnostics across all scenarios."))
    } else if(identical(page,"agreement")) {
      if(is.null(rv$data))errors<-c(errors,tr("没有可计算一致性的检测数据。","No test data are available for agreement analysis."))
      if(!isTRUE(input$review_agreement))errors<-c(errors,tr("请确认已审阅一致性结果，并不会将PPA/NPA解释为DSe/DSp。","Confirm that agreement results were reviewed and PPA/NPA will not be interpreted as DSe/DSp."))
    } else if(identical(page,"publication")) {
      if(is.null(rv$fit))errors<-c(errors,tr("没有可生成论文输出的拟合结果。","No fitted result is available for publication outputs.")) else {
        final_n<-sum(rv$fit$cross$N);assessed<-suppressWarnings(as.numeric(input$samples_assessed %||% NA_real_))
        if(!is.finite(assessed)||assessed!=floor(assessed)||assessed<final_n)errors<-c(errors,paste0(tr("进入筛选的样本总数必须不小于最终BLCM样本数：","Total samples assessed must be at least the final BLCM sample size: "),final_n))
        if(!nonblank(input$exclusion_notes %||% ""))errors<-c(errors,tr("请记录排除数量及原因；如果没有排除，也请明确写“无”。","Record exclusions and reasons; if none, state this explicitly."))
        if(!nonblank(input$sample_size_rationale %||% ""))errors<-c(errors,tr("请记录样本量确定依据。","Record the sample-size rationale.")) else if(preset_placeholder(input$sample_size_rationale))errors<-c(errors,tr("样本量依据模板中仍有待补充占位内容，请填写具体计算方法/方案。","The sample-size rationale still contains template placeholders; provide the specific calculation method or protocol."))
      }
      if(!isTRUE(input$review_publication))errors<-c(errors,tr("请确认已审阅论文输出及其解释边界。","Confirm that the publication outputs and their interpretation limits were reviewed."))
    } else if(identical(page,"export")) {
      if(is.null(rv$fit))errors<-c(errors,tr("没有可导出的拟合结果。","No fitted result is available for export."))
      if(is.null(rv$last_save_id)||is.null(rv$last_save_dir)||!dir.exists(rv$last_save_dir)||is.null(rv$fit)||!identical(rv$last_save_id,rv$fit$id))errors<-c(errors,tr("请先使用“保存完整分析到本地”保存当前分析。","Save the current analysis with 'Save complete analysis locally' before continuing."))
    }
    validation_result(errors,warnings)
  },error=function(e)validation_result(conditionMessage(e)))
  validation_message<-function(v){
    if(v$valid&&length(v$warnings))tr("本页存在需记录的警告；除技术性阻断外可以继续。","This page has warnings that should be documented; you may continue unless a technical blocker is present.") else if(v$valid)tr("本页当前未发现需要提示的问题，可以继续。","No current issues require attention on this page; you may continue.") else tr("本页存在未完成或需审阅项目；这些项目会保留提示，但不再单独锁死流程。","This page has incomplete or review items; they remain visible as advisories but do not by themselves lock the workflow.")
  }
  reset_results<-function(){rv$fit<-NULL;rv$comparison<-NULL;rv$sensitivity<-NULL;rv$last_save_id<-NULL;rv$status<-tr("数据已更新，请运行模型。","Data updated. Run a model.");for(k in c("qc_reviewed","review_visual","review_ppc","review_sensitivity","review_sensitivity_failed","review_identifiability","review_results","review_agreement","review_publication"))shiny::updateCheckboxInput(session,k,value=FALSE)}
  set_data<-function(d,mode,priors=NULL,populations=NULL) {
    q<-validate_blcm_data(d,mode);rv$data<-d;rv$mode<-mode;rv$scenarios<-list();reset_results()
    if(q$valid) {
      pop<-build_cross_tables(d,mode)$Population
      rv$priors<-priors %||% prior_template(pop)
      rv$populations<-populations %||% data.frame(Population=pop,Definition="",Rationale="",Prior_source="",stringsAsFactors=FALSE)
      shiny::updateSelectInput(session,"prior_parameter",choices=rv$priors$Parameter)
      shiny::updateSelectInput(session,"pop_edit_population",choices=pop,selected=pop[1])
      # Screening totals are study metadata, not derivable from included records.
    }
  }
  # 从界面收集研究描述；筛选总数由研究记录提供，不可根据最终纳入人数反推。
  metadata<-shiny::reactive({
    keys<-c("project_name","pathogen","t1","t2","specimen","target_population","source_population","unit","purpose","case_definition","comparator_reference","t1_positive_rule","t2_positive_rule","equivocal_handling","invalid_handling","missing_handling","samples_assessed","exclusion_notes","sample_size_rationale","grouping_independent","procedures_comparable","independent_sampling","priors_independent","label_confirmed","label_rationale","expert_override","override_rationale")
    stats::setNames(lapply(keys,function(k)input[[k]]),keys)
  })
  review<-shiny::reactive(list(visual=isTRUE(input$review_visual),ppc=isTRUE(input$review_ppc),sensitivity=isTRUE(input$review_sensitivity),sensitivity_failed=isTRUE(input$review_sensitivity_failed),identifiability=isTRUE(input$review_identifiability),results=isTRUE(input$review_results),agreement=isTRUE(input$review_agreement),publication=isTRUE(input$review_publication),qc=isTRUE(input$qc_reviewed),notes=input$review_notes %||% ""))
  settings<-shiny::reactive(mcmc_settings(input$mcmc_mode,input$chains,input$adapt,input$burnin,input$iterations,input$thin,input$seed))
  qc<-shiny::reactive({shiny::req(rv$data);validate_blcm_data(rv$data,rv$mode)})
  cross<-shiny::reactive({shiny::req(rv$data);build_cross_tables(rv$data,rv$mode)})
  current_fit<-shiny::reactive({shiny::req(rv$fit);rv$fit})
  table_render<-function(expr) {
    quoted <- substitute(expr)
    evaluation_env <- parent.frame()
    DT::renderDT({
      value <- eval(quoted, envir=evaluation_env)
      table_language<-if(lang()=="zh")list(lengthMenu="每页 _MENU_ 条",search="搜索：",info="第 _START_–_END_ 条，共 _TOTAL_ 条",infoEmpty="无记录",zeroRecords="未找到记录",emptyTable="暂无数据",paginate=list(first="首页",previous="上一页",`next`="下一页",last="末页"))else list()
      table<-DT::datatable(value,rownames=FALSE,options=list(pageLength=10,scrollX=TRUE,autoWidth=TRUE,language=table_language),escape=TRUE)
      numeric_columns<-names(value)[vapply(value,is.numeric,logical(1))]
      count_columns<-intersect(numeric_columns,c("N","T1","T2","n11","n10","n01","n00","ess_bulk","ess_tail","Observed","Predicted_median"))
      if(length(setdiff(numeric_columns,count_columns)))table<-DT::formatRound(table,setdiff(numeric_columns,count_columns),digits=4)
      if(length(count_columns))table<-DT::formatRound(table,count_columns,digits=0)
      table
    })
  }
  shiny::observeEvent(input$language,{
    session$sendCustomMessage("setLanguage",lang())
    shiny::updateSelectInput(session,"page",choices=setNames(page_ids,if(lang()=="zh")page_zh else page_en),selected=input$page %||% rv$current_page)
  })
  navigate_to<-function(page){rv$current_page<-page;shiny::updateSelectInput(session,"page",selected=page)}
  shiny::observeEvent(input$page,{
    requested<-input$page %||% "project";idx<-page_index(requested)
    if(is.na(idx))return()
    rv$current_page<-requested
  },ignoreInit=TRUE)
  output$workflow_gate<-shiny::renderUI({
    page<-input$page %||% rv$current_page;v<-page_validation(page);hard<-page_hard_blockers(page)
    cls<-if(length(hard))"workflow-gate fail" else if(!v$valid)"workflow-gate fail" else if(length(v$warnings))"workflow-gate warn" else "workflow-gate pass"
    heading<-if(length(hard)) tr("存在技术性阻断，暂时不能进入下一步。","A technical blocker prevents continuing to the next step.") else if(!v$valid) tr("本页存在未完成或需审阅的项目；这些项目会被保留为红色提示，但原则上仍可继续。","This page has incomplete or review items. They remain visible as red advisories, but you may generally continue.") else if(length(v$warnings)) tr("本页存在需要记录的警告；可以继续。","This page has warnings that should be documented; you may continue.") else tr("本页当前未发现需要提示的问题，可以继续。","No current issues require attention on this page; you may continue.")
    advisory<-unique(c(v$errors,v$warnings))
    shiny::div(class=cls,shiny::strong(heading),
      if(length(hard))shiny::tagList(shiny::p(shiny::strong(tr("技术性阻断：","Technical blocker:"))),shiny::tags$ul(lapply(hard,shiny::tags$li))) else NULL,
      if(length(advisory))shiny::tagList(shiny::p(shiny::strong(tr("提示/审阅项目：","Advisory/review items:"))),shiny::tags$ul(lapply(advisory,shiny::tags$li))) else NULL,
      if(page!="help")shiny::div(class="workflow-lock",if(length(hard))ui_text("解决上述技术性阻断后即可继续；其余提示不会锁死流程。","Resolve the technical blocker to continue; other advisories do not lock the workflow.") else ui_text("“下一步”保持可用；请在正式解释或导出前处理并记录红/黄提示。","Next remains available; address and document red/yellow advisories before final interpretation or export.")))
  })
  output$workflow_nav<-shiny::renderUI({
    page<-input$page %||% rv$current_page;idx<-page_index(page);hard<-page_hard_blockers(page)
    prev<-if(idx>1)shiny::actionButton("page_prev",ui_text("← 上一步","← Previous"),class="btn btn-default") else shiny::span()
    if(idx<length(page_ids)){
      nxt<-shiny::actionButton("page_next",ui_text("下一步 →","Next →"),class="btn btn-primary",disabled=length(hard)>0)
    } else nxt<-shiny::span(class="workflow-lock",ui_text("工作流程已到最后一页。","End of workflow."))
    shiny::div(class="workflow-nav",prev,nxt)
  })
  shiny::observeEvent(input$page_prev,{
    idx<-page_index(input$page %||% rv$current_page);if(!is.na(idx)&&idx>1)navigate_to(page_ids[idx-1L])
  })
  shiny::observeEvent(input$page_next,{
    page<-input$page %||% rv$current_page;idx<-page_index(page);hard<-page_hard_blockers(page)
    if(length(hard)){shiny::showNotification(paste(hard,collapse="\n"),type="error",duration=8);return()}
    if(idx<length(page_ids))navigate_to(page_ids[idx+1L])
  })
  output$runtime<-shiny::renderText({if(!requireNamespace("rjags",quietly=TRUE)) return(tr("JAGS/rjags不可用，请见README。","JAGS/rjags unavailable; see README."));paste("R",getRversion(),"/ JAGS",rjags::jags.version())})
  shiny::observeEvent(input$load_file,safe(function(){shiny::req(input$data_file);d<-read_blcm_data(input$data_file$datapath,sheet=input$sheet);set_data(d,input$data_mode)}))
  shiny::observeEvent(input$import_counts,safe(function(){txt<-input$counts_paste;sep<-if(grepl("\t",txt))"\t" else ",";d<-utils::read.table(text=txt,sep=sep,header=TRUE,check.names=FALSE,stringsAsFactors=FALSE);set_data(d,"aggregated");shiny::updateSelectInput(session,"data_mode",selected="aggregated")}))
  # 只有“模拟示例”允许自动填已知的模拟研究说明；真实研究不能套用示例先验和理由。
  shiny::observeEvent(input$example,safe(function(){
    d<-utils::read.csv("examples/simulated_validation_data.csv",check.names=FALSE,stringsAsFactors=FALSE)
    p<-utils::read.csv("examples/simulated_priors.csv",check.names=FALSE,stringsAsFactors=FALSE,na.strings="NA")
    # Complete every descriptive prior field so the built-in example demonstrates a fully documented project.
    p$Mean<-ifelse(is.na(p$Mean),p$Alpha/(p$Alpha+p$Beta),p$Mean);p$ESS<-ifelse(is.na(p$ESS),p$Alpha+p$Beta,p$ESS)
    p$Source[is.na(p$Source)|!nzchar(trimws(p$Source))]<-"SIMULATED EXAMPLE ONLY — no empirical source"
    p$Rationale[is.na(p$Rationale)|!nzchar(trimws(p$Rationale))]<-"SIMULATED EXAMPLE ONLY: prespecified simulation prior; not transferable to real diagnostic inference."
    p$Source_population[is.na(p$Source_population)|!nzchar(trimws(p$Source_population))]<-"Synthetic Low/Medium/High data-generating populations"
    p$Specimen[is.na(p$Specimen)|!nzchar(trimws(p$Specimen))]<-"Simulated specimen"
    p$Estimate[is.na(p$Estimate)|!nzchar(trimws(p$Estimate))]<-sprintf("Beta(%g,%g), support [%g,%g]",p$Alpha,p$Beta,p$Lower,p$Upper)
    p$Uncertainty[is.na(p$Uncertainty)|!nzchar(trimws(p$Uncertainty))]<-"Defined by the displayed simulated prior distribution"
    p$Applicability[is.na(p$Applicability)|!nzchar(trimws(p$Applicability))]<-"Software demonstration only; do not use as evidence for a real pathogen, assay, specimen or population"
    p$Discount[is.na(p$Discount)|!nzchar(trimws(p$Discount))]<-"Not applicable — simulated example"
    p$Notes[is.na(p$Notes)|!nzchar(trimws(p$Notes))]<-"SIMULATED EXAMPLE ONLY"
    missing_assay<-is.na(p$Assay)|!nzchar(trimws(p$Assay))
    p$Assay[missing_assay]<-ifelse(grepl("^(Se|Sp)1$",p$Parameter[missing_assay]),"T1",ifelse(grepl("^(Se|Sp)2$",p$Parameter[missing_assay]),"T2","Not assay-specific"))
    pop<-data.frame(
      Population=c("Low","Medium","High"),
      Definition=c(
        "SIMULATED EXAMPLE ONLY: prespecified lower-risk stratum in the data-generating design, defined before T1/T2 outcomes.",
        "SIMULATED EXAMPLE ONLY: prespecified intermediate-risk stratum in the data-generating design, defined before T1/T2 outcomes.",
        "SIMULATED EXAMPLE ONLY: prespecified higher-risk stratum in the data-generating design, defined before T1/T2 outcomes."),
      Rationale=c(
        "SIMULATED EXAMPLE ONLY: the generating design prespecifies a lower true prevalence to provide prevalence contrast; no Se/Sp ordering is imposed.",
        "SIMULATED EXAMPLE ONLY: the generating design prespecifies an intermediate true prevalence to provide prevalence contrast; no Se/Sp ordering is imposed.",
        "SIMULATED EXAMPLE ONLY: the generating design prespecifies a higher true prevalence to provide prevalence contrast; no Se/Sp ordering is imposed."),
      Prior_source=rep("SIMULATED data-generating design; no empirical source",3),stringsAsFactors=FALSE)
    set_data(d,"sample",p,pop);shiny::updateSelectInput(session,"data_mode",selected="sample")
    # Page 1: all study-description fields are explicitly populated.
    vals<-list(project_name="SIMULATED EXAMPLE ONLY",pathogen="Simulated analyte",t1="Simulated assay T1",t2="Simulated comparator T2",specimen="Simulated specimen",target_population="Synthetic target population used for software validation",source_population="Synthetic Low/Medium/High data-generating populations",comparator_reference="SIMULATED external-information scenario; no empirical publication or standard")
    for(k in names(vals))shiny::updateTextInput(session,k,value=vals[[k]])
    shiny::updateSelectInput(session,"specimen_preset",selected="custom")
    shiny::updateSelectInput(session,"case_definition_preset",selected="custom")
    shiny::updateTextAreaInput(session,"case_definition",value="SIMULATED EXAMPLE ONLY: D=1 is the true binary data-generating latent state; it is not defined by either T1 or T2 alone.")
    shiny::updateSelectInput(session,"t1_rule_preset",selected="custom");shiny::updateTextAreaInput(session,"t1_positive_rule",value="SIMULATED EXAMPLE ONLY: T1=1 exactly when the simulated binary generator assigns a positive T1 result; there is no empirical Ct threshold.")
    shiny::updateSelectInput(session,"t2_rule_preset",selected="custom");shiny::updateTextAreaInput(session,"t2_positive_rule",value="SIMULATED EXAMPLE ONLY: T2=1 exactly when the simulated binary generator assigns a positive T2 result; there is no empirical Ct threshold.")
    shiny::updateSelectInput(session,"equivocal_preset",selected="none");shiny::updateTextInput(session,"equivocal_handling",value="SIMULATED EXAMPLE ONLY: the binary generator has no equivocal category.")
    shiny::updateSelectInput(session,"invalid_preset",selected="none");shiny::updateTextInput(session,"invalid_handling",value="SIMULATED EXAMPLE ONLY: the binary generator has no invalid category.")
    shiny::updateSelectInput(session,"missing_preset",selected="paired_exclude");shiny::updateTextInput(session,"missing_handling",value="SIMULATED EXAMPLE ONLY: paired T1/T2 analysis; units with either result missing would be excluded, and missing is never coded negative.")
    shiny::updateSelectInput(session,"unit",selected="sample");shiny::updateSelectInput(session,"purpose",selected="research")
    # Page 2: sample-flow fields and presets are filled, not only the hidden narrative values.
    shiny::updateNumericInput(session,"samples_assessed",value=nrow(d))
    shiny::updateSelectInput(session,"exclusion_preset",selected="none");shiny::updateTextAreaInput(session,"exclusion_notes",value="SIMULATED EXAMPLE ONLY: no exclusions; all generated observations have complete paired T1/T2 results.")
    shiny::updateSelectInput(session,"sample_size_preset",selected="simulation");shiny::updateTextAreaInput(session,"sample_size_rationale",value="SIMULATED EXAMPLE ONLY: the fixed sample size is defined by the validation dataset to exercise the software workflow and is not a sample-size justification for a real diagnostic study.")
    # Page 4: the table is complete and the guided editor is also populated for the selected Low group.
    shiny::updateSelectInput(session,"pop_edit_population",choices=pop$Population,selected="Low")
    shiny::updateSelectInput(session,"pop_definition_basis",selected="composite")
    shiny::updateSelectInput(session,"pop_definition_detail_preset",choices=population_detail_choices("composite"),selected="composite_multi")
    shiny::updateSelectInput(session,"pop_expected_risk",selected="lower")
    shiny::updateSelectInput(session,"pop_evidence_type",selected="design")
    shiny::updateSelectInput(session,"pop_rationale_preset",selected="auto")
    shiny::updateCheckboxInput(session,"grouping_independent",value=TRUE);shiny::updateSelectInput(session,"procedures_comparable",selected="yes");shiny::updateCheckboxInput(session,"independent_sampling",value=TRUE)
    # Page 5: example priors carry complete simulated provenance; editor is populated by the priors observer.
    shiny::updateCheckboxInput(session,"priors_independent",value=TRUE);shiny::updateSelectInput(session,"prior_rationale_preset",selected="simulation")
    # Page 6: choose and document the simulated model setup explicitly.
    shiny::updateSelectInput(session,"model_type",selected="positive");shiny::updateCheckboxInput(session,"label_confirmed",value=TRUE);shiny::updateSelectInput(session,"label_rationale_preset",selected="simulation")
    shiny::updateTextAreaInput(session,"label_rationale",value="SIMULATED EXAMPLE ONLY: latent-class labels are fixed by the data-generating mechanism and prespecified simulation parameters; this rationale cannot be transferred to real data.")
    shiny::updateCheckboxInput(session,"expert_override",value=FALSE);shiny::updateTextAreaInput(session,"override_rationale",value="Not applicable in the simulated example because three prespecified populations are available.")
    shiny::updateSelectInput(session,"mcmc_mode",selected="preview");shiny::updateNumericInput(session,"chains",value=4);shiny::updateNumericInput(session,"adapt",value=500);shiny::updateNumericInput(session,"burnin",value=1000);shiny::updateNumericInput(session,"iterations",value=2000);shiny::updateNumericInput(session,"thin",value=1);shiny::updateNumericInput(session,"seed",value=20260914)
    # Later pages contain review actions or fit-dependent outputs. Populate narrative controls without falsely auto-confirming review.
    shiny::updateTextAreaInput(session,"review_notes",value="SIMULATED EXAMPLE ONLY: manual diagnostic review is pending until a model has been run.")
    shiny::updateTextInput(session,"scenario_name",value="Alternative_demo")
    rv$scenarios<-list();shiny::showNotification(tr("已载入完整模拟项目：所有可预填研究内容均已填写；人工审阅勾选和拟合后结果仍需按流程完成。","Complete simulated project loaded: all prefillable study fields are populated; manual review acknowledgements and fit-dependent results still require the workflow."),duration=12)
  }))
  output$raw_table<-table_render({shiny::req(rv$data);rv$data})
  output$qc_status<-shiny::renderText({q<-qc();paste(c(if(q$valid)tr("编码检查通过。","Coding checks passed.") else tr("数据不能进入模型。","Data cannot enter the model."),q$errors,q$warnings),collapse="\n")})
  output$cross_table<-table_render(cross())
  output$herd_table<-shiny::renderTable({
    shiny::req(rv$data);if(rv$mode=="aggregated")return(data.frame(Status=tr("聚集情况未知","Clustering unknown")))
    h<-herd_summary(rv$data);if(!nrow(h$sizes))return(data.frame(Status=tr("无可用Herd_ID","No usable herd IDs")))
    sizes<-h$sizes$N
    data.frame(Statistic=if(lang()=="zh")c("群数","最大群样本数","最小群样本数","群样本数中位数","群样本数95%分位数","多样本群数","缺失群编号的样本")else c("Herds","Maximum cluster size","Minimum cluster size","Median cluster size","95th percentile cluster size","Herds with >1 sample","Samples missing herd ID"),Value=c(h$n_herds,h$max_size,min(sizes),median(sizes),unname(quantile(sizes,.95)),sum(sizes>1),h$missing))
  })
  output$observed_qc<-shiny::renderPlot({x<-cross();fake<-list(cross=x);d<-data.frame(Population=rep(x$Population,each=4),Cell=rep(c("++","+-","-+","--"),nrow(x)),Count=as.vector(t(as.matrix(x[2:5]))));ggplot2::ggplot(d,ggplot2::aes(Population,Count,fill=Cell))+ggplot2::geom_col(position="dodge")+ggplot2::theme_minimal()})
  shiny::observeEvent(input$comparator_reference,{if(identical(input$t2_rule_preset,"reference"))refresh_test_rule("t2")},ignoreInit=TRUE)
  shiny::observeEvent(input$specimen_preset,{v<-input$specimen_preset %||% "";if(!nzchar(v)||v=="custom")return();shiny::updateTextInput(session,"specimen",value=v)},ignoreInit=TRUE)
  shiny::observeEvent(input$case_definition_preset,{
    code<-input$case_definition_preset %||% "";if(!nzchar(code)||code=="custom")return()
    val<-switch(code,infection=tr("D=1表示采样时分析单位真实感染目标病原；该潜在状态不由T1或T2任一检测单独定义。","D=1 denotes true infection with the target pathogen at sampling; this latent state is not defined by either T1 or T2 alone."),specimen_presence=tr("D=1表示采样时该样品中真实存在目标病原/目标核酸；该潜在状态不由T1或T2任一检测单独定义。","D=1 denotes true presence of the target pathogen/target nucleic acid in the specimen at sampling; this latent state is not defined by either T1 or T2 alone."),protocol=tr("D=1表示研究方案预先定义的真实目标状态；该状态作为潜变量处理，不等同于T1或T2任一检测结果。","D=1 denotes the true target condition prespecified in the study protocol; it is treated as latent and is not identical to either T1 or T2."),"")
    shiny::updateTextAreaInput(session,"case_definition",value=val)
  },ignoreInit=TRUE)
  refresh_test_rule<-function(ii){code<-input[[paste0(ii,"_rule_preset")]] %||% "";if(!nzchar(code)||code=="custom")return(invisible(NULL));shiny::updateTextAreaInput(session,paste0(ii,"_positive_rule"),value=test_rule_template(code,ii))}
  for(id in c("t1","t2")) local({ii<-id
    shiny::observeEvent(input[[paste0(ii,"_rule_preset")]],refresh_test_rule(ii),ignoreInit=TRUE)
    shiny::observeEvent(input[[paste0(ii,"_ct_cutoff")]],refresh_test_rule(ii),ignoreInit=TRUE)
    shiny::observeEvent(input[[paste0(ii,"_ct_operator")]],refresh_test_rule(ii),ignoreInit=TRUE)
    shiny::observeEvent(input[[paste0(ii,"_replicate_rule")]],refresh_test_rule(ii),ignoreInit=TRUE)
    shiny::observeEvent(input[[paste0(ii,"_replicate_custom")]],refresh_test_rule(ii),ignoreInit=TRUE)
  })
  shiny::observeEvent(input$t1_rule_reference,refresh_test_rule("t1"),ignoreInit=TRUE)
  shiny::observeEvent(input$equivocal_preset,{code<-input$equivocal_preset %||% "";if(!nzchar(code)||code=="custom")return();v<-switch(code,repeat_exclude=tr("按预设SOP复检；仍为可疑/临界的结果排除出成对BLCM数据，不自动编码为阴性。","Repeat according to the prespecified SOP; unresolved equivocal/borderline results are excluded from the paired BLCM dataset and are not automatically recoded as negative."),confirm_exclude=tr("按预设确认算法处理；仍未解决的可疑/临界结果排除出成对BLCM数据。","Resolve using the prespecified confirmatory algorithm; unresolved equivocal/borderline results are excluded from the paired BLCM dataset."),none=tr("该检测按预设判定算法不存在单独的可疑/临界类别。","The prespecified interpretation algorithm for this assay has no separate equivocal/borderline category."),"");shiny::updateTextInput(session,"equivocal_handling",value=v)},ignoreInit=TRUE)
  shiny::observeEvent(input$invalid_preset,{code<-input$invalid_preset %||% "";if(!nzchar(code)||code=="custom")return();v<-switch(code,retest_exclude=tr("重新提取并复检；仍无效的分析单位排除出BLCM数据。","Re-extract and retest; units remaining invalid are excluded from the BLCM dataset."),repeat_exclude=tr("按预设SOP复检；仍无效的分析单位排除出BLCM数据。","Repeat according to the prespecified SOP; units remaining invalid are excluded from the BLCM dataset."),none=tr("该检测的预设算法无单独的无效类别。","The prespecified algorithm for this assay has no separate invalid category."),"");shiny::updateTextInput(session,"invalid_handling",value=v)},ignoreInit=TRUE)
  shiny::observeEvent(input$missing_preset,{code<-input$missing_preset %||% "";if(!nzchar(code)||code=="custom")return();v<-switch(code,paired_exclude=tr("采用成对分析；T1或T2任一结果缺失时，该分析单位不进入BLCM，缺失不编码为阴性。","Use paired analysis; if either T1 or T2 is missing, the analytical unit is excluded from BLCM and missing is not recoded as negative."),recover_exclude=tr("优先补测获得缺失结果；无法补齐时从成对BLCM数据中排除，不将缺失编码为阴性。","Recover the missing test result when possible; otherwise exclude the unit from paired BLCM and do not recode missing as negative."),"");shiny::updateTextInput(session,"missing_handling",value=v)},ignoreInit=TRUE)
  shiny::observeEvent(input$exclusion_preset,{code<-input$exclusion_preset %||% "";if(!nzchar(code)||code=="custom")return();v<-switch(code,none=tr("无排除；所有满足纳入标准且T1/T2成对结果完整的分析单位均进入BLCM。","No exclusions; all eligible analytical units with complete paired T1/T2 results entered BLCM."),missing=tr("仅排除T1/T2结果未成对或缺失且无法补齐的分析单位；缺失不编码为阴性。","Excluded only analytical units with unpaired/missing T1/T2 results that could not be recovered; missing was not recoded as negative."),invalid=tr("排除按预设SOP复检后仍无法解决的无效或可疑结果；其余符合条件的分析单位进入BLCM。","Excluded unresolved invalid or equivocal results after the prespecified retesting algorithm; all other eligible units entered BLCM."),"");shiny::updateTextAreaInput(session,"exclusion_notes",value=v)},ignoreInit=TRUE)
  shiny::observeEvent(input$sample_size_preset,{code<-input$sample_size_preset %||% "";if(!nzchar(code)||code=="custom")return();v<-switch(code,all_eligible=tr("纳入预设研究期间所有满足纳入标准且具有完整成对T1/T2结果的连续/可获得样品；未基于当前检测结果选择样本。","Included all eligible consecutive/available specimens in the prespecified study period with complete paired T1/T2 results; sample selection was not based on current test results."),precision=tr("样本量依据预先设定的精度/可信区间目标确定：[请填写具体参数、目标精度和计算方法]。","Sample size was determined from a prespecified precision/credible-interval target: [provide specific parameters, target precision, and calculation method]."),archive=tr("样本量由研究期内符合预设纳入标准的可用归档样品数量决定；所有符合条件且成对结果完整的样品均纳入。","Sample size was determined by the number of archived specimens meeting prespecified eligibility criteria; all eligible specimens with complete paired results were included."),feasibility=tr("本研究为探索/可行性评价，样本量受可获得样品和资源限制；结果精度通过后验95%CrI明确呈现，不把该样本量视为正式校准保证。","This was an exploratory/feasibility evaluation constrained by specimen availability and resources; precision is reported through posterior 95% CrIs and the sample size is not treated as a formal calibration guarantee."),protocol=tr("样本量按预先确定的法规/方法验证方案执行；[请填写具体方案或标准]。","Sample size followed a prespecified regulatory/method-validation protocol: [provide specific protocol or standard]."),simulation=tr("固定模拟样本量仅用于验证软件工作流和输出，不构成真实诊断研究的样本量依据。","The fixed simulated sample size is used only to exercise the software workflow and outputs and is not a sample-size justification for a real diagnostic study."),"");shiny::updateTextAreaInput(session,"sample_size_rationale",value=v)},ignoreInit=TRUE)
  shiny::observeEvent(input$prior_rationale_preset,{code<-input$prior_rationale_preset %||% "";if(!nzchar(code)||code=="custom")return();v<-switch(code,weak=tr("未找到可辩护且与当前目标群体、样品和检测充分可比的独立外部证据，因此使用明确标记的弱/参考先验，避免人为赋予较高性能。","No defensible independent evidence sufficiently comparable to the current target population, specimen, and assay was identified; an explicitly labelled weak/reference prior is therefore used to avoid imposing high performance."),literature_direct=tr("先验来自独立同行评议文献，其目标群体、样品类型、检测原理和判定规则与当前研究具有较高可比性，因此用于构建信息性先验。","The prior is based on independent peer-reviewed literature with close comparability in target population, specimen, assay principle, and interpretation rule, supporting an informative prior."),literature_discount=tr("先验来自独立文献，但与当前研究在群体、样品或检测实施上仅部分可比，因此保留中心估计并降低ESS以反映可迁移性不确定性。","The prior is based on independent literature but is only partially comparable in population, specimen, or assay implementation; the central estimate is retained while ESS is discounted to reflect transportability uncertainty."),external=tr("先验来自独立于当前研究的外部数据，且其群体、样品与检测实施具有可比性；不使用当前研究T1/T2结果构建该先验。","The prior is based on external data independent of the current study with comparable population, specimen, and assay implementation; current T1/T2 results are not used to construct it."),expert=tr("先验来自独立的专家征询/判断，并记录征询对象、问题、汇总方法及不确定性；该先验不由当前研究数据反推。","The prior is based on an independent expert elicitation/judgement with the experts, questions, aggregation method, and uncertainty documented; it is not reverse-engineered from current study data."),simulation=tr("该先验仅用于模拟或软件验证，不代表真实病原、检测或群体的外部证据，不得用于真实论文推断。","This prior is for simulation/software validation only and is not external evidence for a real pathogen, assay, or population; it must not be used for real-study inference."),"");shiny::updateTextAreaInput(session,"prior_rationale",value=v)},ignoreInit=TRUE)
  shiny::observeEvent(input$label_rationale_preset,{code<-input$label_rationale_preset %||% "";if(!nzchar(code)||code=="custom")return();v<-switch(code,t2_evidence=tr("T2具有独立外部DSe/DSp证据及明确先验来源，用于支持潜在类别的感染/非感染解释；这并不消除结构不可识别性，因此仍进行依赖模型和先验敏感性审阅。","T2 has independent external DSe/DSp evidence with documented prior provenance that helps anchor interpretation of the latent classes as infected/non-infected; this does not remove structural non-identifiability, so dependence and prior-sensitivity review remain required."),priors=tr("潜在类别解释由独立外部证据结合预先设定的信息性准确性先验或明确限制支持；这些限制作为科学假设记录，并通过敏感性分析检验。","Latent-class interpretation is supported by independent external evidence together with prespecified informative accuracy priors or explicit restrictions; these are documented as scientific assumptions and examined in sensitivity analysis."),multiple=tr("多项独立于当前T1/T2结果的流行病学、检测性能及研究设计证据共同支持潜在类别解释；仍不把MCMC收敛等同于模型可识别。","Multiple epidemiologic, assay-performance, and design evidence sources independent of current T1/T2 results jointly support latent-class interpretation; MCMC convergence is still not treated as proof of identifiability."),simulation=tr("仅用于模拟示例：潜在类别标签由模拟生成机制和预设参数定义；该理由不能用于真实数据分析。","Simulation example only: latent-class labels are defined by the simulation-generating mechanism and prespecified parameters; this rationale cannot be used for real-data analysis."),"");shiny::updateTextAreaInput(session,"label_rationale",value=v)},ignoreInit=TRUE)
  shiny::observeEvent(input$pop_definition_basis,{
    ch<-population_detail_choices(input$pop_definition_basis %||% "");cur<-isolate(input$pop_definition_detail_preset %||% "");sel<-if(nzchar(cur)&&cur%in%unname(ch))cur else ""
    shiny::updateSelectInput(session,"pop_definition_detail_preset",choices=ch,selected=sel)
  },ignoreInit=TRUE)
  shiny::observeEvent(input$pop_edit_population,{
    z<-tolower(trimws(input$pop_edit_population %||% ""));risk<-if(grepl("(^|[^a-z])low([^a-z]|$)|低",z))"lower" else if(grepl("medium|middle|中",z))"intermediate" else if(grepl("high|高",z))"higher" else NULL
    if(!is.null(risk))shiny::updateSelectInput(session,"pop_expected_risk",selected=risk)
  },ignoreInit=TRUE)
  shiny::observeEvent(input$apply_population_guidance,safe(function(){
    shiny::req(rv$populations);pop<-input$pop_edit_population %||% "";assert(nzchar(pop),tr("请选择群体。","Select a population."));basis<-input$pop_definition_basis %||% "";assert(nzchar(basis),tr("请选择分组依据。","Select a definition basis."));ev<-input$pop_evidence_type %||% "";assert(nzchar(ev),tr("请选择分层依据/证据来源。","Select the stratification evidence/source."))
    basis_label<-switch(basis,composite=tr("预先定义的综合流行病学风险层级","Prespecified composite epidemiological risk stratum"),geography=tr("地区/来源","Geography/source"),clinical=tr("临床或繁殖史","Clinical/reproductive history"),herd_history=tr("牛群既往感染/监测状态","Herd infection/surveillance history"),exposure=tr("暴露或生物安全因素","Exposure/biosecurity factors"),management=tr("生产类型或管理方式","Production/management type"),temporal=tr("时间/监测批次","Temporal/surveillance cohort"),custom=tr("其他自定义依据","Other custom basis"),basis)
    dcode<-input$pop_definition_detail_preset %||% "";assert(nzchar(dcode),tr("请选择具体分组标准；只有无合适选项时才选自定义。","Select an operational criterion; use custom only when no preset applies."));detail<-if(dcode=="custom")trimws(input$pop_definition_detail %||% "") else population_detail_text(dcode);if(dcode=="custom")assert(nzchar(detail),tr("请填写自定义具体分组标准。","Enter the custom operational definition."));definition<-paste0(basis_label,"：",detail)
    rmode<-input$pop_rationale_preset %||% "auto";rationale<-if(rmode=="custom")trimws(input$pop_rationale_custom %||% "") else if(rmode=="no_order")rationale_by_risk("unknown") else rationale_by_risk(input$pop_expected_risk %||% "unknown");if(!nzchar(rationale))rationale<-tr("[请补充Rationale]","[provide rationale]")
    ev_label<-switch(ev,surveillance=tr("既往监测或外部数据","Previous surveillance/external data"),literature=tr("同行评议文献","Peer-reviewed literature"),records=tr("牛群/临床历史记录","Herd/clinical records"),design=tr("预设研究设计/专家依据","Prespecified study design/expert rationale"),none=tr("无量化外部证据；仅预设分层","No quantitative external evidence; prespecified stratification only"),custom=tr("其他自定义来源","Other custom source"),ev);ed<-trimws(input$pop_evidence_detail %||% "");need_detail<-ev%in%c("surveillance","literature","records","custom");prior_source<-if(nzchar(ed))paste0(ev_label,"：",ed) else if(need_detail)paste0(ev_label,"：",tr("[请填写具体来源]","[provide specific source]")) else ev_label
    i<-match(pop,rv$populations$Population);assert(!is.na(i),"Population not found");rv$populations$Definition[i]<-definition;rv$populations$Rationale[i]<-rationale;rv$populations$Prior_source[i]<-prior_source
  }))
  output$population_table<-DT::renderDT({shiny::req(rv$populations);DT::datatable(rv$populations,rownames=FALSE,editable=list(target="cell",disable=list(columns=0)),options=list(dom="t",scrollX=TRUE),escape=TRUE)})
  shiny::observeEvent(input$population_table_cell_edit,{e<-input$population_table_cell_edit;d<-rv$populations;d[e$row,e$col+1]<-e$value;rv$populations<-d})
  output$prior_table<-table_render({shiny::req(rv$priors);rv$priors})
  shiny::observeEvent(input$prior_upload,safe(function(){shiny::req(rv$data);p<-read_blcm_data(input$prior_upload$datapath);resolve_priors(p,cross()$Population,"positive");rv$priors<-p;shiny::updateSelectInput(session,"prior_parameter",choices=p$Parameter)}))
  shiny::observeEvent(list(input$prior_parameter,rv$priors),{
    shiny::req(rv$priors);p<-rv$priors[rv$priors$Parameter==input$prior_parameter,,drop=FALSE];shiny::req(nrow(p)==1)
    shiny::updateSelectInput(session,"prior_type",selected=p$Prior_type)
    for(k in c("alpha","beta","lower","upper")) shiny::updateNumericInput(session,paste0("prior_",k),value=p[[paste0(toupper(substr(k,1,1)),substring(k,2))]])
    if(p$Prior_type=="mean_ess") {shiny::updateNumericInput(session,"prior_mean",value=p$Mean);shiny::updateNumericInput(session,"prior_ess",value=p$ESS)} else {shiny::updateNumericInput(session,"prior_mean",value=p$Alpha/(p$Alpha+p$Beta));shiny::updateNumericInput(session,"prior_ess",value=p$Alpha+p$Beta)}
    shiny::updateSelectInput(session,"prior_source_type",selected=p$Source_type %||% "subjective/expert");shiny::updateTextInput(session,"prior_source",value=p$Source %||% "");shiny::updateTextAreaInput(session,"prior_rationale",value=p$Rationale %||% "");shiny::updateTextInput(session,"prior_source_pop",value=p$Source_population %||% "");shiny::updateTextInput(session,"prior_uncertainty",value=p$Uncertainty %||% "")
    for(k in c("specimen","assay","estimate","discount")) shiny::updateTextInput(session,paste0("prior_",k),value=p[[paste0(toupper(substr(k,1,1)),substring(k,2))]] %||% "")
  })
  editing_prior<-shiny::reactive({if(input$prior_type=="mean_ess")make_beta_prior(mean=input$prior_mean,ess=input$prior_ess,lower=input$prior_lower,upper=input$prior_upper) else make_beta_prior(input$prior_alpha,input$prior_beta,lower=input$prior_lower,upper=input$prior_upper)})
  output$prior_stats<-shiny::renderTable(as.data.frame(editing_prior()),digits=4)
  output$prior_preview<-shiny::renderPlot({p<-editing_prior();x<-seq(p$lower+1e-7,p$upper-1e-7,length.out=500);plot(x,dbeta(x,p$alpha,p$beta)/p$mass,type="l",col="#18796b",lwd=2,xlab=input$prior_parameter,ylab=tr("先验密度","Prior density"))})
  shiny::observeEvent(input$save_prior,safe(function(){
    shiny::req(rv$priors);z<-editing_prior();p<-rv$priors;i<-match(input$prior_parameter,p$Parameter)
    assert(!is.na(i),"Unknown parameter");p$Prior_type[i]<-input$prior_type;p$Mean[i]<-z$alpha/(z$alpha+z$beta);p$ESS[i]<-z$alpha+z$beta;p$Alpha[i]<-z$alpha;p$Beta[i]<-z$beta;p$Lower[i]<-z$lower;p$Upper[i]<-z$upper
    p$Source_type[i]<-if(!nzchar(input$prior_source)&&input$prior_source_type %in% c("literature","external data"))"subjective/expert" else input$prior_source_type
    p$Source[i]<-input$prior_source;p$Rationale[i]<-input$prior_rationale;p$Applicability[i]<-input$prior_rationale;p$Source_population[i]<-input$prior_source_pop;p$Uncertainty[i]<-input$prior_uncertainty
    for(k in c("specimen","assay","estimate","discount")) {field<-paste0(toupper(substr(k,1,1)),substring(k,2));if(!field %in% names(p))p[[field]]<-"";p[[field]][i]<-input[[paste0("prior_",k)]] %||% ""}
    rv$priors<-p
    shiny::showNotification(tr("先验已保存。","Prior saved."),duration=3)
  }))
  shiny::observeEvent(input$use_weak,safe(function(){p<-rv$priors;i<-match(input$prior_parameter,p$Parameter);p$Prior_type[i]<-"alpha_beta";p$Alpha[i]<-1;p$Beta[i]<-1;p$Mean[i]<-.5;p$ESS[i]<-2;p$Source_type[i]<-"weak/reference";p$Source[i]<-"";p$Rationale[i]<-"Uniform over the explicitly recorded support";rv$priors<-p;shiny::updateSelectInput(session,"prior_type",selected="alpha_beta");shiny::updateNumericInput(session,"prior_alpha",value=1);shiny::updateNumericInput(session,"prior_beta",value=1)}))
  update_mcmc_fields<-function(s) for(k in c("chains","adapt","burnin","iterations","thin","seed")) shiny::updateNumericInput(session,k,value=s[[k]])
  shiny::observeEvent(input$mcmc_mode,{
    if(!is.null(rv$pending_settings)&&identical(rv$pending_settings$mode,input$mcmc_mode)) {update_mcmc_fields(rv$pending_settings);rv$pending_settings<-NULL}
    else {final<-input$mcmc_mode=="final";shiny::updateNumericInput(session,"adapt",value=if(final)2000 else 500);shiny::updateNumericInput(session,"burnin",value=if(final)5000 else 1000);shiny::updateNumericInput(session,"iterations",value=if(final)10000 else 2000)}
  })
  run_models<-function(both=FALSE) safe(function(){
    shiny::req(rv$data,rv$priors);assert(qc()$valid,paste(qc()$errors,collapse="\n"));mods<-if(both)c("independent","positive") else input$model_type
    fits<-list();shiny::withProgress(message=tr("运行Bayesian模型","Running Bayesian model"),value=0,{
      for(i in seq_along(mods)) {fits[[mods[i]]]<-run_blcm(rv$data,rv$priors,rv$mode,mods[i],settings(),metadata(),rv$populations,progress=function(msg)shiny::setProgress(value=(i-1)/length(mods),detail=msg));shiny::setProgress(value=i/length(mods))}
    })
    rv$comparison<-if(both)fits else NULL;rv$fit<-fits[[if(both) if(input$model_type=="independent")"independent" else "positive" else input$model_type]];rv$sensitivity<-NULL;rv$scenarios<-list()
    rv$status<-paste(tr("MCMC运行完成，下一步检查诊断。","MCMC completed. Review diagnostics next."),rv$fit$id)
  })
  # 按钮启动实际计算；页面跳转或切换语言不会重新拟合。
  shiny::observeEvent(input$run_primary,run_models(FALSE));shiny::observeEvent(input$run_both,run_models(TRUE))
  shiny::observeEvent(rv$fit,{if(!is.null(rv$fit)){rv$last_save_id<-NULL;shiny::updateSelectInput(session,"plot_parameter",choices=parameter_names(rv$fit));for(k in c("review_visual","review_ppc","review_sensitivity","review_sensitivity_failed","review_identifiability","review_results","review_agreement"))shiny::updateCheckboxInput(session,k,value=FALSE)}})
  output$run_status<-shiny::renderText(rv$status)
  output$reliability<-shiny::renderUI({f<-current_fit();s<-analysis_status(f,rv$comparison,rv$sensitivity,review(),lang());shiny::div(class=paste("alert-box",paste0("status-",s$level)),shiny::strong(paste(toupper(s$level),s$label)),shiny::tags$ul(lapply(unique(c(f$diagnostics$flags,f$design$blockers,f$design$warnings)),shiny::tags$li)))})
  output$diagnostic_table<-table_render(current_fit()$diagnostics$table)
  output$diagnostic_plot<-shiny::renderPlot(plot_blcm(current_fit(),input$plot_type,input$plot_parameter,language=lang()))
  output$separation<-shiny::renderTable({d<-current_fit()$diagnostics$separation;data.frame(Metric=names(d),Value=unname(d))})
  output$ppc_table<-table_render(current_fit()$ppc$table)
  output$posterior_table<-table_render(current_fit()$summary)
  output$result_narrative<-shiny::renderUI({f<-current_fit();s<-analysis_status(f,rv$comparison,rv$sensitivity,review(),lang());shiny::div(class=paste("alert-box",paste0("status-",s$level)),shiny::strong(s$label),shiny::p(results_text(f,lang(),all(s$checks$Pass[s$checks$Required]))))})
  output$result_plot<-shiny::renderPlot(plot_blcm(current_fit(),"accuracy",language=lang()))
  output$comparison_table<-table_render({shiny::req(rv$comparison);compare_models(rv$comparison$independent,rv$comparison$positive)})
  output$checklist<-table_render(review_checklist(current_fit(),rv$comparison,rv$sensitivity,review()))
  scenario_upload_info<-shiny::reactive({
    shiny::req(input$scenario_upload,rv$fit);f<-rv$fit
    out<-tryCatch({raw<-read_blcm_data(input$scenario_upload$datapath);rp<-resolve_priors(raw,f$cross$Population,f$model);p<-rp$table;main<-f$priors$table;z<-p[match(main$Parameter,p$Parameter),,drop=FALSE]
      same<-isTRUE(all.equal(z[c("Alpha","Beta","Lower","Upper")],main[c("Alpha","Beta","Lower","Upper")],check.attributes=FALSE));weak<-is_weak_prior_scenario(p,f)
      changed<-which(vapply(seq_len(nrow(z)),function(i)!isTRUE(all.equal(as.numeric(z[i,c("Alpha","Beta","Lower","Upper")]),as.numeric(main[i,c("Alpha","Beta","Lower","Upper")]),check.attributes=FALSE)),logical(1)))
      errs<-warns<-character();if(same)errs<-c(errs,tr("上传先验与Main完全相同，不能作为Alternative。","Uploaded priors are identical to Main and cannot serve as an Alternative."));if(weak)errs<-c(errs,tr("上传文件是全弱先验；请使用“添加/刷新Weak情景”按钮。","The uploaded file is an all-weak prior; use the Add/refresh Weak scenario button."));if(length(changed)&&any(!nzchar(trimws(z$Rationale[changed]))))errs<-c(errs,tr("所有发生改变的信息性先验都必须填写Rationale。","Every changed informative prior must include a rationale."));if(any(preset_placeholder(z$Rationale[changed])))errs<-c(errs,tr("Alternative先验Rationale仍含模板占位内容。","Alternative-prior rationale still contains template placeholders."));miss_source<-changed[z$Source_type[changed]%in%c("literature","external data")&!nzchar(trimws(z$Source[changed]))];if(length(miss_source))errs<-c(errs,tr("文献/外部数据先验必须填写具体Source。","Literature/external-data priors require a specific Source."));if(any(!nzchar(trimws(z$Source[changed]))))warns<-c(warns,tr("部分改变的先验没有具体引用；若为专家/主观先验，应在Rationale中明确独立征询依据。","Some changed priors have no specific citation; for expert/subjective priors, document the independent elicitation basis in the rationale."));list(valid=!length(errs),errors=errs,warnings=warns,priors=p,changed=main$Parameter[changed])},error=function(e)list(valid=FALSE,errors=conditionMessage(e),warnings=character(),priors=NULL,changed=character()))
    out
  })
  output$scenario_upload_validation<-shiny::renderUI({shiny::req(input$scenario_upload);z<-scenario_upload_info();cls<-if(z$valid&&length(z$warnings))"workflow-gate warn"else if(z$valid)"workflow-gate pass"else"workflow-gate fail";shiny::div(class=cls,shiny::strong(if(z$valid)tr("上传情景先验校验通过。","Uploaded scenario priors passed validation.")else tr("上传情景先验未通过校验。","Uploaded scenario priors failed validation.")),if(length(c(z$errors,z$warnings)))shiny::tags$ul(lapply(c(z$errors,z$warnings),shiny::tags$li)),if(z$valid&&length(z$changed))shiny::p(paste0(tr("相对Main发生变化的参数：","Parameters changed from Main: "),paste(z$changed,collapse=", "))))})
  output$scenario_upload_preview<-table_render({shiny::req(input$scenario_upload);z<-scenario_upload_info();shiny::req(!is.null(z$priors));keep<-intersect(c("Parameter","Population","Alpha","Beta","Mean","ESS","Lower","Upper","Source_type","Source","Rationale"),names(z$priors));z$priors[,keep,drop=FALSE]})
  scenario_registry<-shiny::reactive({if(!length(rv$scenarios))return(data.frame());f<-rv$fit;do.call(rbind,lapply(names(rv$scenarios),function(nm){p<-rv$scenarios[[nm]];main<-if(!is.null(f))f$priors$table else p;z<-p[match(main$Parameter,p$Parameter),,drop=FALSE];isweak<-!is.null(f)&&is_weak_prior_scenario(p,f);changed<-sum(vapply(seq_len(nrow(z)),function(i)!isTRUE(all.equal(as.numeric(z[i,c("Alpha","Beta","Lower","Upper")]),as.numeric(main[i,c("Alpha","Beta","Lower","Upper")]),check.attributes=FALSE)),logical(1)));data.frame(Scenario=nm,Type=if(isweak)"Weak"else"Alternative",Changed_parameters=changed,stringsAsFactors=FALSE)}))})
  output$scenario_list<-table_render(scenario_registry())
  shiny::observeEvent(rv$scenarios,{shiny::updateSelectInput(session,"scenario_remove_name",choices=names(rv$scenarios),selected=if(length(rv$scenarios))names(rv$scenarios)[1]else character())},ignoreInit=FALSE)
  invalidate_sensitivity<-function(){rv$sensitivity<-NULL;shiny::updateCheckboxInput(session,"review_sensitivity",value=FALSE);shiny::updateCheckboxInput(session,"review_sensitivity_failed",value=FALSE)}
  shiny::observeEvent(input$add_uploaded_scenario,safe(function(){f<-current_fit();z<-scenario_upload_info();assert(isTRUE(z$valid),paste(z$errors,collapse="; "));name<-trimws(input$scenario_name %||% "");assert(nzchar(name),tr("请输入情景名称。","Enter a scenario name."));assert(!tolower(name)%in%c("main","weak"),tr("Alternative情景不能命名为Main或Weak。","An Alternative scenario cannot be named Main or Weak."));assert(!name%in%names(rv$scenarios),tr("该情景名称已存在；请先移除旧情景或使用新名称。","That scenario name already exists; remove the old scenario or use a new name."));s<-rv$scenarios;s[[name]]<-z$priors;rv$scenarios<-s;invalidate_sensitivity();shiny::showNotification(paste0(tr("已加入敏感性情景：","Sensitivity scenario added: "),name),duration=4)}))
  shiny::observeEvent(input$add_weak,safe(function(){f<-current_fit();s<-rv$scenarios;s$Weak<-weak_prior_scenario(f);rv$scenarios<-s;invalidate_sensitivity();shiny::showNotification(tr("Weak情景已从当前主模型先验生成/刷新。","Weak scenario generated/refreshed from the current main fit."),duration=4)}))
  shiny::observeEvent(input$remove_scenario,safe(function(){name<-input$scenario_remove_name %||% "";assert(nzchar(name)&&name%in%names(rv$scenarios),tr("请选择要移除的情景。","Select a scenario to remove."));s<-rv$scenarios;s[[name]]<-NULL;rv$scenarios<-s;invalidate_sensitivity()}))
  shiny::observeEvent(input$run_sensitivity,safe(function(){f<-current_fit();assert(length(rv$scenarios)>0,"Add prior scenarios first");shiny::withProgress(message=tr("先验敏感性分析","Prior sensitivity analysis"),{rv$sensitivity<-run_prior_sensitivity(f,rv$scenarios,progress=function(msg)shiny::setProgress(detail=msg))});shiny::updateCheckboxInput(session,"review_sensitivity",value=FALSE);shiny::updateCheckboxInput(session,"review_sensitivity_failed",value=FALSE)}))
  sensitivity_bad_names<-shiny::reactive({if(is.null(rv$sensitivity)||!length(rv$sensitivity$fits))return(character());names(rv$sensitivity$fits)[!vapply(rv$sensitivity$fits,function(x)isTRUE(x$diagnostics$acceptable),logical(1))]})
  output$sensitivity_failure_review_ui<-shiny::renderUI({bad<-sensitivity_bad_names();if(!length(bad))return(NULL);shiny::div(class="workflow-gate warn",shiny::strong(tr("存在MCMC诊断未达标的敏感性情景。","Some sensitivity scenarios did not meet MCMC diagnostic targets.")),shiny::p(paste0(tr("情景：","Scenarios: "),paste(bad,collapse=", "))),shiny::checkboxInput("review_sensitivity_failed",ui_text("我已审阅这些失败情景，并理解其仅用于提示先验依赖/识别不足，不作为有效参数估计解释","I reviewed these failed scenarios and understand that they are retained only as evidence of prior sensitivity/weak identification, not as valid parameter estimates"),FALSE))})
  output$sensitivity_table<-table_render({shiny::req(rv$sensitivity);rv$sensitivity$table})
  # The UI note wraps with the page width; exports retain the plot caption.
  output$sensitivity_plot<-shiny::renderPlot({shiny::req(rv$sensitivity);plot_blcm(current_fit(),"sensitivity",sensitivity=rv$sensitivity,language=lang())+ggplot2::labs(caption=NULL)})
  output$agreement_table<-table_render(agreement_analysis(cross()))
  output$discordant_table<-table_render({shiny::req(rv$data,rv$mode=="sample",qc()$valid);d<-qc()$data;d[d$T1!=d$T2,intersect(c("Sample_ID","Population","T1","T2","Ct_T1","Ct_T2","Sample_type","Note"),names(d)),drop=FALSE]})
  publication_fit<-shiny::reactive({shiny::req(rv$fit);rv$fit})
  output$sample_flow_plot<-shiny::renderPlot({plot_sample_flow(publication_fit(),lang())})
  output$sample_flow_table<-table_render(sample_flow_table(publication_fit()))
  output$posterior_contrast_table<-table_render(posterior_contrasts(publication_fit()))
  output$stard_audit_table<-table_render(stard_blcm_reporting_audit(publication_fit(),rv$comparison,rv$sensitivity,review()))
  save_current_analyte<-function(){m<-metadata();assert(nzchar(m$pathogen %||% ""),"Analyte name required");p<-rv$project;p[[m$pathogen]]<-list(metadata=m,data=rv$data,mode=rv$mode,priors=rv$priors,populations=rv$populations,model=input$model_type,settings=settings(),scenarios=rv$scenarios,review=review(),summary=if(!is.null(rv$fit))rv$fit$summary else NULL,fit=rv$fit,comparison=rv$comparison,sensitivity=rv$sensitivity);rv$project<-p;shiny::updateSelectInput(session,"saved_analyte",choices=names(p),selected=m$pathogen)}
  shiny::observeEvent(input$save_analyte,safe(save_current_analyte))
  restore_analyte<-function(a){
    set_data(a$data,a$mode,a$priors,a$populations);shiny::updateSelectInput(session,"data_mode",selected=a$mode)
    for(k in names(a$metadata)) {v<-a$metadata[[k]];if(k %in% c("unit","purpose","procedures_comparable"))shiny::updateSelectInput(session,k,selected=v) else if(k=="samples_assessed")shiny::updateNumericInput(session,k,value=as.numeric(v)) else if(is.logical(v))shiny::updateCheckboxInput(session,k,value=v) else if(k %in% c("case_definition","label_rationale","override_rationale","t1_positive_rule","t2_positive_rule","exclusion_notes","sample_size_rationale"))shiny::updateTextAreaInput(session,k,value=v) else shiny::updateTextInput(session,k,value=v)}
    rv$fit<-a$fit;rv$comparison<-a$comparison;rv$sensitivity<-a$sensitivity;rv$scenarios<-a$scenarios %||% list()
    if(!is.null(a$model)) shiny::updateSelectInput(session,"model_type",selected=a$model)
    if(!is.null(a$settings)) {s<-do.call(mcmc_settings,a$settings);if(identical(input$mcmc_mode,s$mode)) update_mcmc_fields(s) else {rv$pending_settings<-s;shiny::updateSelectInput(session,"mcmc_mode",selected=s$mode)}}
    for(k in c("review_visual","review_ppc","review_sensitivity","review_sensitivity_failed","review_identifiability","review_results","review_agreement","review_publication","qc_reviewed")) shiny::updateCheckboxInput(session,k,value=FALSE)
    shiny::updateTextAreaInput(session,"review_notes",value=a$review$notes %||% "")
  }
  shiny::observeEvent(input$load_analyte,safe(function(){shiny::req(input$saved_analyte);restore_analyte(rv$project[[input$saved_analyte]])}))
  output$project_download<-shiny::downloadHandler(filename=function()"VetBLCM_project.json",content=function(file){save_current_analyte();p<-lapply(rv$project,function(a){a$fit<-NULL;a$comparison<-NULL;a$sensitivity<-NULL;a});jsonlite::write_json(list(schema_version=2,type="VetBLCM configuration for saved single-analyte workflows; posterior draws are not embedded and analyses must be refit after restore",analytes=p),file,pretty=TRUE,auto_unbox=TRUE,na="null",digits=NA)})
  shiny::observeEvent(input$project_upload,safe(function(){z<-jsonlite::read_json(input$project_upload$datapath,simplifyVector=TRUE);assert((identical(z$schema_version,1L)||identical(z$schema_version,1)||identical(z$schema_version,2L)||identical(z$schema_version,2)),"Unsupported project schema");assert(is.list(z$analytes)&&length(z$analytes)>0,"Empty project");rv$project<-z$analytes;shiny::updateSelectInput(session,"saved_analyte",choices=names(z$analytes));restore_analyte(z$analytes[[1]])}))
  output$input_template<-shiny::downloadHandler(filename="VetBLCM_input_template.xlsx",content=function(file)file.copy("examples/VetBLCM_input_template.xlsx",file,overwrite=TRUE))
  output$prior_template_file<-shiny::downloadHandler(filename="VetBLCM_prior_template.xlsx",content=function(file)file.copy("examples/VetBLCM_prior_template.xlsx",file,overwrite=TRUE))
  output$export_controls<-shiny::renderUI({
    if(is.null(rv$fit)) return(ui_note("当前没有可导出的拟合结果。请先运行模型；从项目JSON恢复后也必须重新拟合。","No fitted result is available for export. Run a model first; a project restored from JSON must also be refitted."))
    shiny::tagList(
      shiny::downloadButton("report_download",ui_text("双语HTML报告","Bilingual HTML report")),
      shiny::downloadButton("excel_download",ui_text("结果Excel","Results Excel")),
      shiny::downloadButton("bundle_download",ui_text("完整分析包ZIP","Complete analysis ZIP")),
      shiny::downloadButton("model_download",ui_text("实际JAGS代码","Actual JAGS code")),
      shiny::downloadButton("rds_download",ui_text("完整分析RDS","Full analysis RDS")),
      shiny::downloadButton("csv_download",ui_text("后验汇总CSV","Posterior summary CSV")),
      shiny::hr(),shiny::selectInput("figure_format",ui_text("图形格式","Figure format"),c("png","svg","pdf")),
      shiny::downloadButton("figure_download",ui_text("下载当前诊断图","Download current diagnostic plot"))
    )
  })
  output$output_path_preview<-shiny::renderText({
    root<-path.expand(input$local_output_root %||% default_local_output_root())
    analyte<-sanitize_path_component(input$pathogen %||% "analyte","analyte",32L)
    paste0(tr("保存结构预览：","Save structure preview: "),file.path(root,format(Sys.Date(),"%Y-%m-%d"),paste0("run_HHMMSS_",analyte,"_<analysis-id>")))
  })
  output$selected_output_root<-shiny::renderText({paste0(tr("当前结果根目录：","Current results root: "),path.expand(input$local_output_root %||% default_local_output_root()))})
  output$local_save_status<-shiny::renderText(rv$local_save_status)
  shiny::observeEvent(input$choose_output_root,{
    safe(function(){
      if(.Platform$OS.type!="windows") {shiny::showNotification(tr("当前系统请直接在路径框中填写结果目录。","On this system, enter the results directory directly in the path box."),duration=6);return(invisible(NULL))}
      chosen<-select_local_output_directory(input$local_output_root %||% default_local_output_root())
      if(!is.null(chosen)) shiny::updateTextInput(session,"local_output_root",value=chosen)
    })
  })
  shiny::observeEvent(input$open_output_root,safe(function(){
    root<-prepare_local_output_root(input$local_output_root %||% default_local_output_root())
    if(!open_local_directory(root)) shiny::showNotification(paste(tr("当前系统不支持自动打开目录。位置：","Automatic folder opening is unavailable on this system. Location:"),root),duration=NULL)
  }))
  shiny::observeEvent(input$save_local_analysis,{
    tryCatch({
      assert(!is.null(rv$fit),tr("当前没有可保存的拟合结果，请先运行模型。","No fitted result is available to save; run a model first."));f<-rv$fit;rv$local_save_status<-tr("正在由R直接生成并保存完整分析……","R is generating and saving the complete analysis directly...")
      result<-shiny::withProgress(message=tr("保存完整分析到本地","Saving complete analysis locally"),value=0,{shiny::incProgress(.1,detail=tr("生成报告、Excel和复现文件","Generating report, Excel and reproducibility files"));z<-save_analysis_local(f,input$local_output_root,rv$comparison,rv$sensitivity,review(),lang(),all_figures=TRUE);shiny::incProgress(.9,detail=tr("完成","Complete"));z})
      rv$last_save_dir<-result$directory
      rv$last_save_id<-f$id
      save_current_analyte()
      rv$local_save_status<-paste0(tr("保存成功：","Saved successfully: "),result$directory,"\nSHA-256 (ZIP): ",result$bundle_sha256)
      shiny::showNotification(tr("完整分析已直接保存到本地文件夹；同时导出标准化单病原analysis_summary.csv/json。","Complete analysis saved locally, including standardized single-analyte analysis_summary.csv/json files."),type="message",duration=8)
    },error=function(e){rv$local_save_status<-paste0(tr("保存失败：","Save failed: "),conditionMessage(e));message_error(e)})
  })
  shiny::observeEvent(input$open_last_save,safe(function(){
    assert(!is.null(rv$last_save_dir)&&dir.exists(rv$last_save_dir),"No saved analysis directory yet / 尚无已保存的分析目录")
    if(!open_local_directory(rv$last_save_dir)) shiny::showNotification(paste(tr("当前系统不支持自动打开目录。位置：","Automatic folder opening is unavailable on this system. Location:"),rv$last_save_dir),duration=NULL)
  }))
  output$report_download<-shiny::downloadHandler(filename=function()paste0("VetBLCM_",current_fit()$id,".html"),content=function(file)export_blcm_report(current_fit(),file,rv$comparison,rv$sensitivity,review(),lang()))
  output$excel_download<-shiny::downloadHandler(filename="VetBLCM_results.xlsx",content=function(file)write_results_excel(current_fit(),file,rv$comparison,rv$sensitivity,review()))
  output$model_download<-shiny::downloadHandler(filename="model_used.jags",content=function(file)writeLines(current_fit()$model_code,file,useBytes=TRUE))
  output$rds_download<-shiny::downloadHandler(filename="VetBLCM_analysis.rds",content=function(file)saveRDS(list(fit=current_fit(),comparison=rv$comparison,sensitivity=rv$sensitivity,review=review()),file))
  output$csv_download<-shiny::downloadHandler(filename="posterior_summary.csv",content=function(file)utils::write.csv(current_fit()$summary,file,row.names=FALSE,fileEncoding="UTF-8"))
  output$figure_download<-shiny::downloadHandler(filename=function()paste0(input$plot_type,".",input$figure_format),content=function(file){ext<-input$figure_format;ggplot2::ggsave(file,plot_blcm(current_fit(),input$plot_type,input$plot_parameter,language="en"),width=9,height=5,dpi=180,device=switch(ext,svg=grDevices::svg,pdf=grDevices::pdf,png="png"))})
  output$bundle_download<-shiny::downloadHandler(filename=function()paste0("VetBLCM_",current_fit()$id,".zip"),content=function(file){dir<-tempfile("vetblcm_export_");dir.create(dir);on.exit(unlink(dir,recursive=TRUE,force=TRUE),add=TRUE);export_analysis(current_fit(),dir,rv$comparison,rv$sensitivity,review(),lang());files<-list.files(dir,recursive=TRUE,all.files=TRUE,no..=TRUE,include.dirs=FALSE);zip::zipr(file,files=files,root=dir,mode="mirror",include_directories=FALSE)})
  output$help_content<-shiny::renderUI(shiny::tagList(shiny::p(ui_text("DSe为真实感染条件下阳性的概率；DSp为真实未感染条件下阴性的概率。BLCM依据潜在状态及明确假设进行推断，不能给每个样品确认感染状态。","DSe is the probability of a positive test given true infection; DSp is the probability of a negative test given no infection. BLCM inference relies on latent states and explicit assumptions; it does not confirm individual infection status.")),shiny::p(ui_text("95% CrI表示在所用模型、数据和先验条件下，参数落入该区间的后验概率为95%。这是模型条件下的陈述。","A 95% CrI contains 95% of posterior parameter probability conditional on the specified model, data and priors.")),shiny::tags$ul(lapply(known_limitations(),shiny::tags$li))))
  output$help_document<-shiny::renderText({file<-file.path("docs",input$help_doc);if(file.exists(file))paste(readLines(file,warn=FALSE,encoding="UTF-8"),collapse="\n") else tr("文档待完善。","Documentation pending.")})
}
