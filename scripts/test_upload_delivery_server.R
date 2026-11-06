# Server-side import regression. This does not emulate browser file delivery.
source("R/load.R",encoding="UTF-8");load_vetblcm()
source("modules/mod_layout.R",encoding="UTF-8")
source("modules/mod_server.R",encoding="UTF-8")
shiny::testServer(app_server, {
  session$setInputs(language="zh",sheet=1,data_mode="sample")
  session$setInputs(data_file=list(datapath="validation/upload_fixtures/sample_identifiers.csv"),load_file=1)
  session$flushReact()
  stopifnot(qc()$valid,identical(rv$data$Sample_ID,c("001","1","9007199254740993")),
    identical(cross()$Population,c("01","1")),identical(cross()$N,c(2,1)))
  before <- sha256(rv$data)
  session$setInputs(language="en");session$flushReact()
  stopifnot(identical(sha256(rv$data),before))
  cat("Sample upload observer: exact IDs, group counts and language invariance passed\n")
  session$setInputs(data_mode="aggregated",
    data_file=list(datapath="validation/upload_fixtures/aggregated_identifiers.csv"),load_file=2)
  session$flushReact()
  stopifnot(qc()$valid,identical(cross()$Population,c("01","1")),identical(cross()$N,c(2,1)))
  cat("Aggregated upload observer: numeric-looking groups remained separate\n")
})
invalid <- validate_blcm_data(read_blcm_data("validation/upload_fixtures/invalid_test_value.csv"),"sample")
stopifnot(!invalid$valid,any(grepl("T1",invalid$errors)))
cat("Invalid binary value rejected; no observation discarded\n")
cat("SERVER UPLOAD REGRESSION PASSED; BROWSER DELIVERY NOT TESTED\n")
