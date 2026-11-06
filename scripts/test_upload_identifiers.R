source("R/load.R");load_vetblcm()
task_dir <- tempfile("vetblcm-import-");dir.create(task_dir)
on.exit_cleanup <- function() unlink(task_dir,recursive=TRUE)
tryCatch({
  for(ext in c("csv","tsv")) {
    path <- file.path(task_dir,paste0("identifiers.",ext))
    sep <- if(ext=="tsv") "\t" else ","
    rows <- c("Sample_ID,Population,Herd_ID,T1,T2",
              "001,01,0001,1,1","1,1,1,0,0",
              "9007199254740993,01,0002,1,0")
    writeLines(gsub(",",sep,rows,fixed=TRUE),path,useBytes=TRUE)
    d <- read_blcm_data(path)
    stopifnot(identical(d$Sample_ID,c("001","1","9007199254740993")),
              identical(d$Population,c("01","1","01")),
              identical(d$Herd_ID,c("0001","1","0002")))
    q <- validate_blcm_data(d,"sample");stopifnot(q$valid)
    counts <- build_cross_tables(d,"sample")
    stopifnot(identical(counts$Population,c("01","1")),identical(counts$N,c(2,1)))
    stopifnot(identical(attr(d,"file_sha256"),digest::digest(file=path,algo="sha256")))
    cat(toupper(ext)," identifiers, distinct groups, counts and source hash passed\n")
  }
  hash_path <- file.path(task_dir,"literal-hash.csv")
  writeLines(c("Sample_ID,Population,T1,T2","A#1,01,1,0"),hash_path)
  hashed <- read_blcm_data(hash_path)
  stopifnot(identical(hashed$Sample_ID,"A#1"),validate_blcm_data(hashed,"sample")$valid)
  cat("Literal hash in an unquoted identifier preserved\n")
  p <- read_blcm_data("examples/simulated_priors.csv")
  populations <- unique(read_blcm_data("examples/simulated_validation_data.csv")$Population)
  resolved <- resolve_priors(p,populations,"positive")
  stopifnot(all(is.finite(resolved$alpha)),all(is.finite(resolved$beta)))
  cat("Existing numeric prior import passed\n")
},finally=on.exit_cleanup())
cat("UPLOAD IDENTIFIER REGRESSION PASSED\n")
