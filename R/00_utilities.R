# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 通用检查、随机状态管理和来源哈希。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

`%||%` <- function(x,y) if(is.null(x)) y else x
# 条件必须明确为 TRUE；失败时抛出可直接展示给用户的错误，避免继续产生无效结果。
assert <- function(ok,message) if(!isTRUE(ok)) stop(message,call.=FALSE)
# 只检查依赖是否存在，不在分析过程中自动联网安装软件包。
need_packages <- function(packages) {
  missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
  assert(!length(missing),paste("Missing R packages / 缺少R包:",paste(missing,collapse=", ")))
}
# 验证单个数值的有限性、上下界和整数要求；用于 MCMC 参数等输入。
check_number <- function(x,name,low=-Inf,high=Inf,integer=FALSE) {
  assert(is.numeric(x)&&length(x)==1L&&is.finite(x)&&x>=low&&x<=high&&(!integer||x==floor(x)),paste("Invalid / 无效:",name))
  invisible(x)
}
# 临时设置随机种子，结束后恢复调用前的随机数状态；使重复检查可复现且不污染其他随机过程。
with_seed <- function(seed,fun) {
  old <- if(exists(".Random.seed",.GlobalEnv,inherits=FALSE)) get(".Random.seed",.GlobalEnv) else NULL
  on.exit(if(is.null(old)) { if(exists(".Random.seed",.GlobalEnv,inherits=FALSE)) rm(".Random.seed",envir=.GlobalEnv) } else assign(".Random.seed",old,.GlobalEnv))
  set.seed(seed); fun()
}
# 为输入对象或文本生成 SHA256 摘要，用于来源追溯；serialize=FALSE 适合原始模型文本。
sha256 <- function(x,serialize=TRUE) { need_packages("digest"); digest::digest(x,algo="sha256",serialize=serialize) }
# 建立统一的空消息表，便于把错误或警告与非空结果使用同一导出接口。
empty_df <- function() data.frame(Message=character(),stringsAsFactors=FALSE)
# 生成运行标识，供项目保存与敏感性分析绑定使用；标识本身不是科学结果。
analysis_id <- function() paste0(format(Sys.time(),"%Y%m%dT%H%M%OS3"),"_",substr(sha256(list(Sys.time(),Sys.getpid(),tempfile())),1,10))

