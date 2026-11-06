Sys.unsetenv("LC_ALL")
source("R/load.R");load_vetblcm();need_packages("openxlsx")
dir.create("examples",showWarnings=FALSE)
f<-readRDS("validation/dependent_fit.rds");c<-f$cross
d<-do.call(rbind,lapply(seq_len(nrow(c)),function(j) {
 code<-rep(c("11","10","01","00"),as.integer(c[j,2:5]));data.frame(Sample_ID=paste0("SIM_",j,"_",seq_along(code)),Population=c$Population[j],T1=as.integer(substr(code,1,1)),T2=as.integer(substr(code,2,2)),Ct_T1=NA_real_,Ct_T2=NA_real_,Sample_type="Simulated specimen",Herd_ID=paste0("SIM_HERD_",j,"_",seq_along(code)),Collection_date="",Location="",Note="SIMULATED EXAMPLE ONLY",stringsAsFactors=FALSE)
}))
write.csv(d,"examples/simulated_validation_data.csv",row.names=FALSE)
p<-f$priors$table;p$Rationale[1:2]<-"SIMULATED EXAMPLE: explicit restriction Se1 and Sp1 >0.5"
write.csv(p,"examples/simulated_priors.csv",row.names=FALSE,na="NA")
style<-openxlsx::createStyle(fgFill="#163F4A",fontColour="white",textDecoration="bold",wrapText=TRUE,halign="center",valign="center")
savebook<-function(tabs,path) {
 w<-openxlsx::createWorkbook()
 for(n in names(tabs)) {openxlsx::addWorksheet(w,n,gridLines=FALSE);openxlsx::writeData(w,n,excel_display_data(tabs[[n]]),headerStyle=style);openxlsx::setColWidths(w,n,cols=seq_len(ncol(tabs[[n]])),widths=if(n=="README")c(25,90)else 22);openxlsx::setRowHeights(w,n,rows=1,heights=32);openxlsx::freezePane(w,n,firstRow=TRUE);if(n=="README")openxlsx::addStyle(w,n,openxlsx::createStyle(wrapText=TRUE,valign="top"),rows=2:(nrow(tabs[[n]])+1),cols=1:2,gridExpand=TRUE)}
 save_vetblcm_workbook(w,path)
}
readme<-data.frame(Field=names(d),Description=c("Required / 必填. Unique specimen ID, preserve leading zeros / 唯一编号，保留前导零","Required / 必填. Group defined independently of current results / 独立于当前结果分组","Required / 必填. 1=positive 阳性; 0=negative 阴性; no missing/equivocal / 不得缺失或不确定","Required / 必填. Same coding as T1 / 与T1同样编码","Optional descriptive Ct; not in likelihood / 可选描述值，不进入模型","Optional descriptive Ct; not in likelihood / 可选描述值，不进入模型","Specimen type; separate heterogeneous types / 样品类型，异质类型应分别分析","Herd ID for clustering audit; blank means unknown / 用于群内聚集检查，空白表示未知","Optional ISO date YYYY-MM-DD / 可选日期","Optional location / 可选地点","Optional notes / 可选备注"))
blank<-d[FALSE,];priorblank<-prior_template(c("Low","Medium","High"));priorblank$Alpha<-NA_real_;priorblank$Beta<-NA_real_
prnote<-data.frame(Field=c("Parameter","Population","Prior_type","Mean / ESS","Alpha / Beta","Source / Rationale","Lower / Upper","No automatic x/n"),Description=c("Se1, Sp1, Se2, Sp2, Prev[j], uD, uH; u is support position, not Pearson correlation / u是可行区间位置，不是相关系数","For Prev[j], must match exact data group order shown by app / 必须匹配应用显示的群体顺序","mean_ess or alpha_beta / 两种输入方式","0 < Mean < 1; ESS > 0; ESS means alpha+beta / ESS指形状参数之和","Both strictly positive / 二者均须大于0","Independent source and applicability rationale / 独立来源及适用理由","Optional explicit truncation 0 <= Lower < Upper <= 1 / 可选显式截断","Apparent prevalence x/n is not automatically true prevalence / 不自动将表观阳性率用作真实患病率先验"))
savebook(list(Data=blank,README=readme),"examples/VetBLCM_input_template.xlsx")
savebook(list(Priors=priorblank,README=prnote),"examples/VetBLCM_prior_template.xlsx")
savebook(list(Data=d,README=data.frame(Item="Example",Description="SIMULATED EXAMPLE ONLY / 仅为模拟示例，不是真实研究数据")),"examples/example_sample_level.xlsx")
savebook(list(Data=c[1:5],README=data.frame(Item="Example",Description="SIMULATED EXAMPLE ONLY / 仅为模拟示例；列顺序Population,n11,n10,n01,n00")),"examples/example_aggregated.xlsx")
x<-build_cross_tables(d)
stopifnot(identical(x$Population,c$Population),all(as.matrix(x[2:5])==as.matrix(c[2:5])))
for(file in list.files("examples",pattern="xlsx$",full.names=TRUE)) stopifnot(length(openxlsx::getSheetNames(file))==2)
cat("Examples/templates written and reopened; cross tables reconcile exactly.\n")

