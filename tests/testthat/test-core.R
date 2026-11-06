testthat::test_that("Beta mean/ESS and truncation represent actual prior", {
  p<-make_beta_prior(mean=.8,ess=20);testthat::expect_equal(p$alpha,16);testthat::expect_equal(p$beta,4)
  p<-make_beta_prior(1,1,lower=.5);testthat::expect_equal(p$mean,.75);testthat::expect_equal(p$q025,.5125)
  testthat::expect_error(make_beta_prior(0,1));testthat::expect_error(make_beta_prior(mean=1,ess=20))
})
testthat::test_that("Full Bernoulli bounds preserve four cells across all margins", {
  with_seed(17,function() {
    p<-c(runif(100000),0,0,1,1,.1,.9);q<-c(runif(100000),0,1,0,1,.2,.8);b<-covariance_bounds(p,q)
    for(c in list(b[,1],b[,2],b[,1]+runif(length(p))*(b[,2]-b[,1]),rep(0,length(p)))) {
      z<-joint_probabilities(p,q,c)
      testthat::expect_true(all(z>=-1e-14&z<=1+1e-14));testthat::expect_true(max(abs(rowSums(z)-1))<1e-12)
      testthat::expect_equal(z[,1]+z[,2],p,tolerance=1e-12);testthat::expect_equal(z[,1]+z[,3],q,tolerance=1e-12)
    }
  })
  testthat::expect_error(joint_probabilities(.1,.2,-.1))
})
testthat::test_that("Data QC does not silently discard observations", {
  d<-data.frame(Sample_ID=letters[1:8],Population=rep(c("A","B"),each=4),T1=rep(c(1,1,0,0),2),T2=rep(c(1,0,1,0),2))
  x<-build_cross_tables(d);testthat::expect_equal(unname(as.matrix(x[2:5])),matrix(1,2,4))
  a<-agreement_analysis(x);testthat::expect_equal(a$PPA,c(.5,.5));testthat::expect_equal(a$Kappa,c(0,0))
  d$T1[1]<-NA;testthat::expect_false(validate_blcm_data(d)$valid)
  d$T1[1]<-2;testthat::expect_false(validate_blcm_data(d)$valid)
  d$T1[1]<-1;d$Sample_ID[2]<-d$Sample_ID[1];testthat::expect_false(validate_blcm_data(d)$valid)
  x$n11[1]<-1.5;testthat::expect_false(validate_blcm_data(x,"aggregated")$valid)
  x<-data.frame(Population="A",n11=0,n10=0,n01=0,n00=10,N=10);a<-agreement_analysis(x);testthat::expect_true(is.na(a$PPA));testthat::expect_true(is.na(a$Kappa))
})
