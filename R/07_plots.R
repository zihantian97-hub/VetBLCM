# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 统计图形及完整参数诊断图导出。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# 统一绘图入口，使用保存的拟合结果绘制准确度、患病率、链、先验、PPC 等；语言选择只影响展示。
plot_blcm <- function(fit,type=c("observed","accuracy","density","prevalence","trace","prior","ppc","correlation","autocorrelation","sensitivity","comparison"),parameter="Se1",sensitivity=NULL,comparison=NULL,language="en") {
  need_packages(c("ggplot2","bayesplot","coda"));type<-match.arg(type);ar<-draws_array(fit);m<-draws_matrix(fit);zh<-language=="zh"
  if(type=="trace") return(bayesplot::mcmc_trace(ar,pars=parameter))
  if(type=="autocorrelation") return(bayesplot::mcmc_acf(ar,pars=parameter))
  if(type=="density") return(bayesplot::mcmc_dens(ar,pars=parameter))
  if(type=="accuracy") return(bayesplot::mcmc_dens(ar,pars=c("Se1","Sp1","Se2","Sp2")))
  if(type=="prevalence") return(bayesplot::mcmc_intervals(ar,pars=paste0("Prev[",seq_len(nrow(fit$cross)),"]"),prob=.5,prob_outer=.95))
  if(type=="observed") {
    x<-fit$cross;d<-data.frame(Population=rep(x$Population,each=4),Cell=rep(c("++","+-","-+","--"),nrow(x)),N=as.vector(t(as.matrix(x[2:5]))))
    return(ggplot2::ggplot(d,ggplot2::aes(Population,N,fill=Cell))+ggplot2::geom_col(position="dodge")+ggplot2::labs(title=if(zh) "各群体检测组合" else "Observed test combinations"))
  }
  if(type=="prior") {
    pr<-sample_priors(fit$priors)
    if(parameter %in% c("CovD","CovH")) {
      if(parameter=="CovD") {b<-covariance_bounds(pr[,"Se1"],pr[,"Se2"]);u<-pr[,"uD"]} else {b<-covariance_bounds(1-pr[,"Sp1"],1-pr[,"Sp2"]);u<-pr[,"uH"]}
      pv<-if(fit$model=="positive") u*b[,2] else b[,1]+u*(b[,2]-b[,1])
    } else pv<-pr[,parameter]
    d<-rbind(data.frame(Value=pv,Distribution=if(zh) "先验" else "Prior"),data.frame(Value=m[,parameter],Distribution=if(zh) "后验" else "Posterior"))
    return(ggplot2::ggplot(d,ggplot2::aes(Value,colour=Distribution))+ggplot2::geom_density(linewidth=.8)+ggplot2::labs(title=parameter,y=if(zh) "密度" else "Density"))
  }
  if(type=="ppc") return(ggplot2::ggplot(fit$ppc$table,ggplot2::aes(Cell,Predicted_median))+ggplot2::geom_linerange(ggplot2::aes(ymin=Lower,ymax=Upper),colour="#178575",linewidth=1.2)+ggplot2::geom_point(ggplot2::aes(y=Observed),shape=4,size=3)+ggplot2::facet_wrap(~Population,scales="free_y")+ggplot2::labs(title=if(zh) "预测区间与观察频数（×）" else "Predictive intervals and observed counts (x)",y=if(zh) "频数" else "Count"))
  if(type=="correlation") {
    c<-fit$diagnostics$correlation;d<-as.data.frame(as.table(c));names(d)<-c("A","B","Correlation")
    return(ggplot2::ggplot(d,ggplot2::aes(A,B,fill=Correlation))+ggplot2::geom_tile()+ggplot2::scale_fill_gradient2(limits=c(-1,1),low="#305f91",mid="white",high="#bf5948")+ggplot2::theme(axis.text.x=ggplot2::element_text(angle=60,hjust=1)))
  }
  if(type=="sensitivity") {
    assert(!is.null(sensitivity)&&nrow(sensitivity$table)>0,"Run sensitivity first / 请先运行敏感性分析")
    main<-fit$summary;main$Scenario<-"Main";main$Diagnostics_pass<-fit$diagnostics$acceptable
    cols<-c("Parameter","Median","Lower","Upper","Scenario","Diagnostics_pass")
    d<-rbind(main[,cols],sensitivity$table[,cols]);d<-d[d$Parameter %in% c("Se1","Sp1"),]
    passed<-if(zh)"MCMC指标达标" else "MCMC targets met"
    failed<-if(zh)"MCMC指标未达标" else "MCMC targets failed"
    d$Status<-ifelse(d$Diagnostics_pass,passed,failed)
    return(ggplot2::ggplot(d,ggplot2::aes(Median,Scenario,colour=Status))+
      ggplot2::geom_linerange(ggplot2::aes(xmin=Lower,xmax=Upper))+
      ggplot2::geom_point()+ggplot2::facet_wrap(~Parameter)+
      ggplot2::scale_colour_manual(values=stats::setNames(c("#18796b","#b43b32"),c(passed,failed)))+
      ggplot2::labs(x=if(zh)"后验中位数及95% CrI" else "Posterior median and 95% CrI",colour=NULL,
        caption=if(zh)"未达标情景仅保留供审查，不能作最终推断；数值达标不证明可识别性。" else "Failed runs are retained for audit, not final inference. Numerical targets do not establish identifiability.")+
      ggplot2::theme(legend.position="bottom"))
  }
  assert(!is.null(comparison),"Run both models first / 请先运行两个模型")
  d<-do.call(rbind,lapply(comparison,function(f) {s<-f$summary;s$Model<-f$model;s$Diagnostics_pass<-f$diagnostics$acceptable;s}));d<-d[d$Parameter %in% c("Se1","Sp1","Se2","Sp2"),]
  passed<-if(zh)"MCMC指标达标" else "MCMC targets met";failed<-if(zh)"MCMC指标未达标" else "MCMC targets failed"
  d$Status<-ifelse(d$Diagnostics_pass,passed,failed)
  ggplot2::ggplot(d,ggplot2::aes(Median,Model,colour=Status))+ggplot2::geom_linerange(ggplot2::aes(xmin=Lower,xmax=Upper))+ggplot2::geom_point()+ggplot2::facet_wrap(~Parameter)+
    ggplot2::scale_colour_manual(values=stats::setNames(c("#18796b","#b43b32"),c(passed,failed)))+
    ggplot2::labs(x=if(zh)"后验中位数及95% CrI" else "Posterior median and 95% CrI",colour=NULL)+ggplot2::theme(legend.position="bottom")
}

# 为全部关键参数导出链、密度、先验叠图及自相关页面，支持逐参数人工审阅。
export_diagnostic_pages <- function(fit,path) {
  grDevices::pdf(path,width=9,height=5,onefile=TRUE)
  on.exit(grDevices::dev.off(),add=TRUE)
  for(parameter in parameter_names(fit)) for(type in c("trace","density","prior","autocorrelation")) {
    p<-plot_blcm(fit,type,parameter,language="en")+
      ggplot2::labs(title=paste(parameter,switch(type,trace="Chain traces",density="Posterior density",prior="Prior and posterior",autocorrelation="Autocorrelation")))
    print(p)
  }
  invisible(path)
}
