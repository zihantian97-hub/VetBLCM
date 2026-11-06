# Actual server regression; no new MCMC fitting.
source("R/load.R",encoding="UTF-8");load_vetblcm()
source("modules/mod_layout.R",encoding="UTF-8")
source("modules/mod_server.R",encoding="UTF-8")
shiny::testServer(app_server, {
  updates<-list()
  original_send<-session$sendInputMessage
  session$sendInputMessage<-function(inputId,message) {
    updates[[length(updates)+1L]]<<-list(id=inputId,message=message)
    original_send(inputId,message)
  }
  session$setInputs(language="en",page="data")
  d<-data.frame(Population=c("A","B"),n11=c(1,1),n10=c(1,1),n01=c(1,1),n00=c(7,6))
  for(value in list(NA_real_,18,19.5,21)) {
    session$setInputs(samples_assessed=value)
    updates<-list();set_data(d,"aggregated");session$flushReact()
    stopifnot(!any(vapply(updates,function(x)identical(x$id,"samples_assessed"),logical(1))))
    stopifnot(identical(input$samples_assessed,value))
  }
  withCallingHandlers({session$setInputs(example=1);session$flushReact()},warning=function(w)stop(conditionMessage(w)))
  stopifnot(all(rv$priors$Assay[grepl("^(Se|Sp)1$",rv$priors$Parameter)]=="T1"))
  stopifnot(all(rv$priors$Assay[grepl("^(Se|Sp)2$",rv$priors$Parameter)]=="T2"))
  stopifnot(all(rv$priors$Assay[!grepl("^(Se|Sp)[12]$",rv$priors$Parameter)]=="Not assay-specific"))
})
cat("REPORTING INTEGRITY SERVER REGRESSION PASSED\n")
