# Execute in a fresh Rscript process, not after sourcing API functions globally.
stopifnot(!exists("validate_blcm_data",envir=.GlobalEnv,inherits=FALSE))
app_env<-new.env(parent=globalenv())
app<-source("app.R",local=app_env,encoding="UTF-8")$value
stopifnot(inherits(app,"shiny.appobj"),identical(environment(app_env$app_server),app_env))
shiny::testServer(app_env$app_server, {
  session$setInputs(language="en",page="data",example=1)
  session$flushReact()
  stopifnot(nrow(rv$data)==6000,qc()$valid)
})
stopifnot(!exists("validate_blcm_data",envir=.GlobalEnv,inherits=FALSE))
cat("ISOLATED SHINY LAUNCH SCOPE PASSED\n")
