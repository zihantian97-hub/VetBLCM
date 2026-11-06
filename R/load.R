# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 模块加载器；可用于只运行分析 API 而不启动界面。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# Source this file from the project root; the analysis API has no Shiny dependency.
# 按文件名顺序加载 R/ 中的函数；envir 控制作用域，使 Shiny 启动和脚本调用可使用同一套计算 API。
load_vetblcm <- function(root = ".", envir = parent.frame()) {
  root <- normalizePath(root, mustWork = TRUE)
  files <- setdiff(list.files(file.path(root,"R"),pattern="\\.R$",full.names=TRUE),file.path(root,"R","load.R"))
  for (f in sort(files)) source(f, local=envir, encoding="UTF-8")
  options(vetblcm.root=root)
  invisible(root)
}
