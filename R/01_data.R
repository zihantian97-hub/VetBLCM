# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 输入数据 → 质量检查 → 四格表 → 研究设计检查。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# 读取 Excel/CSV/TSV；Sample_ID、Population、Herd_ID 按标签保留，避免前导零丢失，并记录输入文件哈希。
read_blcm_data <- function(path,sheet=1) {
  ext <- tolower(tools::file_ext(path))
  d <- if(ext %in% c("xlsx","xls")) {need_packages("readxl");as.data.frame(readxl::read_excel(path,sheet=sheet,.name_repair="minimal"))} else {
    assert(ext %in% c("csv","tsv"),"Use XLSX/XLS/CSV/TSV / 请使用数据模板格式")
    sep <- if(ext=="tsv") "\t" else ","
    header <- names(utils::read.table(path,header=TRUE,sep=sep,nrows=0,colClasses="character",check.names=FALSE,comment.char="",fileEncoding="UTF-8-BOM"))
    # Identifiers are labels: type guessing can collapse 001/1 or round long IDs.
    classes <- rep(NA_character_,length(header))
    classes[sub("\\*$","",header) %in% c("Sample_ID","Population","Herd_ID")] <- "character"
    utils::read.table(path,header=TRUE,sep=sep,colClasses=classes,check.names=FALSE,stringsAsFactors=FALSE,comment.char="",fileEncoding="UTF-8-BOM")
  }
  attr(d,"file_sha256") <- digest::digest(file=path,algo="sha256")
  d
}
# 检查必需列、重复标识、缺失和取值范围；逐样品检测只接受 0/1，不把无效或缺失自动改为阴性。返回 valid/errors/warnings/data。
validate_blcm_data <- function(data,mode=c("sample","aggregated")) {
  mode <- match.arg(mode); errors <- warnings <- character()
  if(!is.data.frame(data)||!nrow(data)) return(list(valid=FALSE,errors="Empty data / 数据为空",warnings=warnings,data=data))
  d <- data; names(d) <- sub("\\*$","",names(d))
  if(anyDuplicated(names(d))) errors <- c(errors,"Duplicate column names / 列名重复")
  core <- if(mode=="sample") c("Sample_ID","Population","T1","T2") else c("Population","n11","n10","n01","n00")
  miss <- setdiff(core,names(d))
  if(length(miss)) return(list(valid=FALSE,errors=paste("Missing columns / 缺少列:",paste(miss,collapse=", ")),warnings=warnings,data=d))
  for(v in intersect(c("Sample_ID","Population"),core)) {
    d[[v]] <- trimws(as.character(d[[v]]))
    bad <- which(is.na(d[[v]])|!nzchar(d[[v]]))
    if(length(bad)) errors <- c(errors,paste(v,"missing rows / 缺失行",paste(bad,collapse=",")))
  }
  vals <- if(mode=="sample") c("T1","T2") else c("n11","n10","n01","n00")
  for(v in vals) {
    raw <- d[[v]]; z <- suppressWarnings(as.numeric(as.character(raw)))
    bad <- which(!is.finite(z)|z<0|z!=floor(z)|(mode=="sample" & !(z %in% 0:1)))
    if(length(bad)) errors <- c(errors,paste(v,"invalid/missing rows / 非法或缺失行",paste(bad,collapse=",")))
    d[[v]] <- z
  }
  id <- if(mode=="sample") "Sample_ID" else "Population"
  if(anyDuplicated(d[[id]])) errors <- c(errors,paste("Duplicate / 重复",id, paste(unique(d[[id]][duplicated(d[[id]])]),collapse=", ")))
  if(mode=="aggregated"&&!length(errors)&&any(rowSums(d[vals])<=0)) errors <- c(errors,"Population with zero samples / 存在零样本群体")
  if(mode=="sample") {
    if("Sample_type" %in% names(d)) {
      types <- unique(na.omit(trimws(as.character(d$Sample_type))));types <- types[nzchar(types)]
      if(length(types)>1) warnings <- c(warnings,"Mixed specimen types: analyse separately / 样品类型混杂，建议分别分析")
      if(anyNA(d$Sample_type)||any(!nzchar(trimws(as.character(d$Sample_type))))) warnings <- c(warnings,"Some specimen types missing / 部分样品类型缺失")
    }
    for(v in intersect(c("Ct_T1","Ct_T2"),names(d))) {
      raw<-d[[v]]; z<-suppressWarnings(as.numeric(as.character(raw)))
      if(any(!is.na(raw)&nzchar(as.character(raw))&(!is.finite(z)|z<0))) warnings<-c(warnings,paste("Check descriptive Ct values / 检查Ct值:",v))
    }
  }
  list(valid=!length(errors),errors=errors,warnings=unique(warnings),data=d,mode=mode,file_sha256=attr(data,"file_sha256"))
}
# 将逐样品数据聚合或读取已有计数；列顺序固定为 n11、n10、n01、n00，与所有 JAGS 模型保持一致。
build_cross_tables <- function(data,mode=c("sample","aggregated")) {
  mode<-match.arg(mode);qc<-validate_blcm_data(data,mode);assert(qc$valid,paste(qc$errors,collapse="\n"));d<-qc$data
  if(mode=="aggregated") out<-d[c("Population","n11","n10","n01","n00")] else {
    pop<-unique(d$Population)
    mat<-t(vapply(pop,function(p) {x<-d[d$Population==p,];tabulate(match(paste0(x$T1,x$T2),c("11","10","01","00")),nbins=4)},integer(4)))
    out<-data.frame(Population=pop,mat,check.names=FALSE);names(out)[2:5]<-c("n11","n10","n01","n00")
  }
  out$N<-rowSums(out[2:5]);rownames(out)<-NULL;out
}
# 计算阳性率、PPA/NPA、总体一致率及 Kappa；PPA/NPA 以 T2 结果作参照，不代表针对真实感染状态的 DSe/DSp。
agreement_analysis <- function(cross) {
  ratio<-function(a,b) ifelse(b>0,a/b,NA_real_)
  a<-cross$n11;b<-cross$n10;c<-cross$n01;d<-cross$n00;n<-cross$N
  po<-ratio(a+d,n);pe<-ratio((a+b)*(a+c)+(c+d)*(b+d),n*n)
  data.frame(Population=cross$Population,N=n,T1_positivity=ratio(a+b,n),T2_positivity=ratio(a+c,n),PPA=ratio(a,a+c),NPA=ratio(d,b+d),Overall_agreement=po,Kappa=ratio(po-pe,1-pe))
}
# 识别 Herd_ID 的重复与缺失，为潜在群内相关提供提示；此函数没有拟合牧场随机效应。
herd_summary <- function(data) {
  if(!"Herd_ID" %in% names(data)) return(list(known=FALSE,clustered=NA,sizes=empty_df()))
  id<-trimws(as.character(data$Herd_ID));valid<-!is.na(id)&nzchar(id);s<-table(id[valid])
  list(known=all(valid),clustered=any(s>1),n_herds=length(s),missing=sum(!valid),max_size=if(length(s)) max(s) else NA_integer_,sizes=data.frame(Herd_ID=names(s),N=as.integer(s)))
}
# 汇总研究设计假设、群体定义和数据质量问题；blockers 阻止正式解释，不代表探索性计算永远不能启动。
check_blcm_design <- function(data,mode,model,metadata=list(),populations=NULL) {
  q<-validate_blcm_data(data,mode);assert(q$valid,paste(q$errors,collapse="\n"));x<-build_cross_tables(data,mode);J<-nrow(x)
  warnings<-q$warnings; blockers<-character();h<-if(mode=="sample") herd_summary(data) else list(known=FALSE,clustered=NA,sizes=empty_df())
  if(J<2) blockers<-c(blockers,"At least two populations required / 至少两个群体")
  if(any(as.matrix(x[2:5])==0)) warnings<-c(warnings,"Zero cells present / 存在零频数格")
  if(any(x$N<50)) warnings<-c(warnings,"Small population sample (screening flag N<50) / 小样本提示")
  if(!isTRUE(metadata$grouping_independent)) blockers<-c(blockers,"Study-design assumption not confirmed: grouping independent of current test results / 尚未确认分组独立于当前检测结果")
  if(!identical(metadata$procedures_comparable,"yes")) blockers<-c(blockers,"Specimen/procedure comparability not confirmed / 样品及程序可比性未确认")
  if(any(grepl("Mixed specimen",warnings))) blockers<-c(blockers,"Mixed specimen types are unsupported for final pooled inference / 基础模型不支持混合样品的正式合并推断")
  if(isTRUE(h$clustered)) blockers<-c(blockers,"Potential within-herd correlation; basic likelihood assumes independent observations / 存在群内聚集，基础模型未校正")
  if(!isTRUE(h$known)&&!isTRUE(metadata$independent_sampling)) blockers<-c(blockers,"Sampling independence not confirmed / 未确认抽样独立性")
  if(model!="independent") {
    warnings<-c(warnings,"Two dependent tests are structurally non-identifiable without additional information, regardless of population count / 两种依赖检测无额外信息时结构不可识别，增加群体不能消除此问题")
    if(J<3 && !(isTRUE(metadata$expert_override)&&nzchar(metadata$override_rationale %||% ""))) blockers<-c(blockers,"Dependent model with <3 populations: expert review and documented prior justification required / 少于三个群体需记录专家复核及先验依据")
  }
  if(is.null(populations)||!all(x$Population %in% populations$Population)) blockers<-c(blockers,"Population definitions missing / 群体定义缺失")
  list(warnings=unique(warnings),blockers=unique(blockers),herds=h,cross=x)
}
