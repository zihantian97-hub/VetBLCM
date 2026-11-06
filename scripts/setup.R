# 新环境的依赖恢复入口；需要联网并由用户确认，JAGS 须独立安装。
# Run manually in a new installation. Network is needed only for installation.
repos<-c(CRAN="https://cran.r-project.org")
if(!requireNamespace("renv",quietly=TRUE)) install.packages("renv",repos=repos)
if(!file.exists("renv/activate.R")) local({
  # scaffold can create a bare lock; preserve the shipped, verified lock exactly.
  backup<-tempfile(fileext=".lock");stopifnot(file.copy("renv.lock",backup))
  on.exit({file.copy(backup,"renv.lock",overwrite=TRUE);unlink(backup)},add=TRUE)
  renv::scaffold(project=".",repos=repos)
})
renv::restore(project=".",prompt=TRUE)
message("R package restore complete. JAGS 4.x is installed separately: https://mcmc-jags.sourceforge.io/")
