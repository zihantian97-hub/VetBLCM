# 从启动器传入环境变量读取端口与浏览器设置，仅在本机运行 Shiny。
# --vanilla intentionally avoids unrelated user startup code. Activate only this
# project's dependency library after it has been initialized by scripts/setup.R.
if(file.exists("renv/activate.R")) source("renv/activate.R",encoding="UTF-8")
pkgs<-c("shiny","bslib","DT","rjags","coda","posterior","readxl","openxlsx","digest","jsonlite","ggplot2","bayesplot","htmltools","base64enc","zip")
missing<-pkgs[!vapply(pkgs,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop(paste("Missing packages / 缺少R包:",paste(missing,collapse=", "),"\nSee README or scripts/setup.R"),call.=FALSE)
tryCatch(rjags::jags.version(),error=function(e)stop("JAGS could not load. Install JAGS 4.x from its official project, then restart R. See README.",call.=FALSE))
port<-as.integer(Sys.getenv("VETBLCM_PORT","7827"))
shiny::runApp(".",host="127.0.0.1",port=port,launch.browser=identical(Sys.getenv("VETBLCM_BROWSER","true"),"true"))
