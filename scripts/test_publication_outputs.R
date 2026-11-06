source("R/load.R", local=TRUE, encoding="UTF-8")
load_vetblcm()
fit_path <- file.path("reports","example_analysis","analysis.rds")
stopifnot(file.exists(fit_path))
z <- readRDS(fit_path)
fit <- z$fit
fit$metadata$t1_positive_rule <- "Simulated binary positivity rule"
fit$metadata$t2_positive_rule <- "Simulated binary positivity rule"
fit$metadata$equivocal_handling <- "None in simulated example"
fit$metadata$invalid_handling <- "None in simulated example"
fit$metadata$missing_handling <- "None in simulated example"
fit$metadata$samples_assessed <- sum(fit$cross$N)
fit$metadata$exclusion_notes <- "No exclusions in simulated example"
fit$metadata$sample_size_rationale <- "Fixed simulated validation dataset"
fit$metadata$source_population <- fit$metadata$source_population %||% "Simulation"
contrasts <- posterior_contrasts(fit)
stopifnot(nrow(contrasts)==2, all(c("Delta_DSe","Delta_DSp") %in% contrasts$Measure))
flow <- sample_flow_table(fit)
stopifnot(sum(fit$cross$N)==flow$N[flow$Stage=="Included in BLCM"])
audit <- stard_blcm_reporting_audit(fit,z$comparison,z$sensitivity,z$review)
stopifnot(nrow(audit)>=15, all(audit$Status %in% c("Complete","Review")))
tmp <- tempfile("publication_outputs_");dir.create(tmp)
d<-write_analysis_publication_summary(fit,file.path(tmp,"analysis_summary.json"),z$comparison,z$sensitivity,z$review)
utils::write.csv(d,file.path(tmp,"analysis_summary.csv"),row.names=FALSE)
stopifnot(file.exists(file.path(tmp,"analysis_summary.json")),file.exists(file.path(tmp,"analysis_summary.csv")),nrow(d)==1L)
p <- plot_sample_flow(fit,"en")
ggplot2::ggsave(file.path(tmp,"sample_flow.png"),p,width=8,height=5,dpi=96)
stopifnot(file.exists(file.path(tmp,"sample_flow.png")))
cat("publication output regression passed\n")
