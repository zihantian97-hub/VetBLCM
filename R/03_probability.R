# 中文注释版 / Annotated source — VetBLCM 0.1.10
# 独立于 JAGS 的概率函数；供模拟与概率合法性检查使用。
# 本次仅增加说明；统计行为与已验证的 0.1.10 相同。

# Bernoulli 协方差的完整可行范围：L=max(-p1*p2,-(1-p1)*(1-p2))，U=min(p1*(1-p2),(1-p1)*p2)。
covariance_bounds <- function(p1,p2) {
  assert(length(p1)==length(p2)&&all(is.finite(p1))&&all(is.finite(p2))&&all(p1>=0&p1<=1&p2>=0&p2<=1),"Invalid Bernoulli margins")
  cbind(lower=pmax(-p1*p2,-(1-p1)*(1-p2)),upper=pmin(p1*(1-p2),(1-p1)*p2))
}
# 构造 11/10/01/00 四格概率；协方差按 +、-、-、+ 加入，保持给定边际，并验证非负性和总和为 1。
joint_probabilities <- function(p1,p2,covariance=0) {
  b<-covariance_bounds(p1,p2);assert(length(covariance) %in% c(1,length(p1)),"Covariance dimensions differ")
  assert(all(is.finite(covariance))&&all(covariance>=b[,1]-1e-14&covariance<=b[,2]+1e-14),"Covariance outside feasible Bernoulli bounds / 协方差超出可行界限")
  q<-cbind(n11=p1*p2+covariance,n10=p1*(1-p2)-covariance,n01=(1-p1)*p2-covariance,n00=(1-p1)*(1-p2)+covariance)
  assert(all(q>=-1e-14&q<=1+1e-14)&&all(abs(rowSums(q)-1)<1e-12),"Invalid joint probabilities")
  q
}
# 观测概率 = prevalence*感染类概率 + (1-prevalence)*非感染类概率；非感染类阳性概率是 1-Sp。
blcm_probabilities <- function(Se1,Sp1,Se2,Sp2,prevalence,CovD=0,CovH=0) {
  assert(length(Se1)==1&&length(Sp1)==1&&length(Se2)==1&&length(Sp2)==1,"Scalar accuracies required")
  assert(all(is.finite(prevalence)&prevalence>=0&prevalence<=1),"Invalid prevalence")
  d<-joint_probabilities(Se1,Se2,CovD);h<-joint_probabilities(1-Sp1,1-Sp2,CovH)
  q<-outer(prevalence,as.numeric(d))+outer(1-prevalence,as.numeric(h));colnames(q)<-colnames(d);q
}
# 按给定真值和群体样本量生成多项分布计数，仅供模拟验证；此处参数不能作为真实研究的现成先验。
simulate_blcm <- function(n,prevalence,Se1,Sp1,Se2,Sp2,CovD=0,CovH=0,seed=2301,populations=paste0("Population_",seq_along(n))) {
  assert(length(n)==length(prevalence)&&length(n)==length(populations)&&all(n>0&n==floor(n)),"Invalid sample sizes")
  p<-blcm_probabilities(Se1,Sp1,Se2,Sp2,prevalence,CovD,CovH)
  y<-with_seed(seed,function() t(vapply(seq_along(n),function(j) as.integer(rmultinom(1,n[j],p[j,])),integer(4))))
  d<-data.frame(Population=populations,y,check.names=FALSE);names(d)[2:5]<-colnames(p);attr(d,"simulated")<-TRUE;d
}

