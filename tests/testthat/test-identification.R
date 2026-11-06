testthat::test_that("Distinct dependent parameters can yield exactly the same population tables", {
  D<-as.numeric(joint_probabilities(.9,.84,.04));H<-as.numeric(joint_probabilities(.03,.05,.015));v<-D-H
  prev<-c(.1,.3,.7,.8);H2<-H+.02*v;D2<-H+.98*v;prev2<-(prev-.02)/.96
  p1<-outer(prev,D)+outer(1-prev,H);p2<-outer(prev2,D2)+outer(1-prev2,H2)
  testthat::expect_equal(p1,p2,tolerance=1e-12)
  testthat::expect_true(all(H2>0&D2>0));testthat::expect_true(abs(sum(D[1:2])-sum(D2[1:2]))>.001)
})
