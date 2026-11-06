# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 应用入口：配置临时缓存、加载统计 API 与界面模块，最后创建 Shiny 应用。运行时需将工作目录设为本文件所在目录。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

cache_dir <- file.path(tempdir(),"VetBLCM-cache")
dir.create(cache_dir,recursive=TRUE,showWarnings=FALSE)
Sys.setenv(R_USER_CACHE_DIR=cache_dir)
source("R/load.R",local=TRUE,encoding="UTF-8")
load_vetblcm()
need_packages(c("shiny","bslib","DT","ggplot2","bayesplot","rjags","posterior","coda","readxl","openxlsx","digest","jsonlite","htmltools","base64enc","zip"))
options(shiny.maxRequestSize=50*1024^2)
source("modules/mod_layout.R",local=TRUE,encoding="UTF-8")
source("modules/mod_server.R",local=TRUE,encoding="UTF-8")
shiny::shinyApp(app_ui(),app_server)
