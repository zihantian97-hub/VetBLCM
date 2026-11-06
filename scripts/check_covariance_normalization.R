# Independent numerical integration audit; no fitting or posterior modification.
cases<-expand.grid(U=c(.02,.15,.24),a=c(1,2),b=c(1,3))
cases$normalized_mass<-NA_real_;cases$printed_kernel_mass<-NA_real_
cases$analytic_kernel_mass<-NA_real_
for(i in seq_len(nrow(cases))) {
  U<-cases$U[i];a<-cases$a[i];b<-cases$b[i]
  cases$normalized_mass[i]<-integrate(function(c) dbeta(c/U,a,b)/U,0,U)$value
  cases$printed_kernel_mass[i]<-integrate(function(c)c^(a-1)*(U-c)^(b-1),0,U)$value
  cases$analytic_kernel_mass[i]<-U^(a+b-1)*beta(a,b)
}
stopifnot(max(abs(cases$normalized_mass-1))<1e-10,
  max(abs(cases$printed_kernel_mass-cases$analytic_kernel_mass))<1e-10)
write.csv(cases,"validation/covariance_normalization_20260921.csv",row.names=FALSE)
print(cases)
cat("NORMALIZED CONDITIONAL DENSITY: all 12 integrals equal 1 within 1e-10.\n")
cat("UNNORMALIZED KERNEL: integrals depend on U; these are algebra checks, not calibration tests.\n")
