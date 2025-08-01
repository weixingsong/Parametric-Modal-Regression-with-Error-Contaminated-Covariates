# Simulation stuy for the paper  "Parametric Modal Regression with Error Contaminated Covariates"


rm(list=ls())
ts=Sys.time()



set.seed(6666)
# Load packages
 library(MASS)
 library(smoothmest)
 library(pracma) #complex number
 library(readxl)  # 载入readxl包

# mode-link function
 
 g=function(x){exp(x)}
 d1g=function(x){exp(x)}

 data<- read.csv("wishreg.csv", header=T)

 y=scale(data$ffq,center=F,scale=T)
 Z=scale(data[2:7],center=T,scale=T)
 Zrep=c(t(Z))


 n=length(y)   # sample size
 B=50   # B-size
 nj=ncol(Z)    # replication at each (X1,X2)



 Zmean=rep(0,n)  # container of mean of Z's at each X1
 Zsd=rep(0,n) # container of sd of Z's at each X1
 
 for(j in seq(n))
   {
    Zmean[j]=mean(Zrep[(nj*(j-1)+1):(nj*j)])
    # Spectral decomposition of covariance
    Zsd[j]=sqrt(var(Zrep[(nj*(j-1)+1):(nj*j)]))
   }


########################Naive#############

 Naivmccl=function(bet)
   {
    Wb=Zmean*bet[2]+bet[1]
    logg=log(g(Wb))
    invg=1/(g(Wb))
    phi=bet[3]
    out1=n*(1+phi)*log(phi)-n*log(gamma(phi+1))+phi*sum(log(y))
    out2=-(1+phi)*sum(logg)-phi*sum(y*invg)
    MCCL=out1+out2
    return(-MCCL/n)
   }

 Naivmcov=function(bet)
   {
    Wb01=Zmean
    Wb=Zmean*bet[2]+bet[1]
    phi=bet[3]
    
    Psi0= -(1+phi)*d1g(Wb)/g(Wb)+phi*y*d1g(Wb)/(g(Wb))^2
    Psi11= -(1+phi)*Wb01*d1g(Wb)/g(Wb)+phi*y*Wb01*d1g(Wb)/(g(Wb))^2
    Psi3= 1+log(phi)-digamma(phi)+log(y)-log(g(Wb))-y/g(Wb)
   
    Psi=cbind(Psi0,Psi11,Psi3)
    return((t(Psi)%*%Psi)/n)
   }

 Nresult=optim(c(-1.58,0.27,5),Naivmccl)$par
 
 An=hessian(Naivmccl,Nresult)
 Bn=Naivmcov(Nresult)
 invAn=solve(An)
 NBcov=sqrt(diag(invAn%*%Bn%*%invAn/n))



#######################MCCL###########

 ZmB=rep(Zmean,each=B) # repeat each row of Zmean B times  
 ZvB=rep(Zsd,each =B)  # repeat each row of Zcov B times 
 
 Tpm=mvrnorm(n*B,rep(0,nj-1),diag(nj-1))      # Generating Tp-values 
 Tpf=function(vv){vv[1:1]/sqrt(sum(vv^2))}
 Tp=t(apply(Tpm,1,Tpf))        
   
 Tp=ZvB*Tp          # Compute S*Tp
 
 impart=sqrt((nj-1)/nj)*Tp   # compute the imaginary part 
 realpart=ZmB                           # extract the real part
 
 
 
 #  Monte-Carlo Corrected Log-Likelihood 
 
 mccl=function(bet)
  {
   rp=ZmB*bet[2]+bet[1]
   ip=impart*bet[2]
   Wb=complex(real=rp,imaginary=ip)
   logg=Re(apply(matrix(log(g(Wb)),nrow=B),2,mean))
   invg=Re(apply(matrix(1/(g(Wb)),nrow=B),2,mean))
   phi=bet[3]
   out1=n*(1+phi)*log(phi)-n*log(gamma(phi+1))+phi*sum(log(y))
   out2=-(1+phi)*sum(logg)-phi*sum(y*invg)
   MCCL=out1+out2
   return(-MCCL/n)
  }
 
 mcov=function(bet)
  {
    Wb01=complex(real=realpart,imaginary=impart)
    rp=ZmB*bet[2]+bet[1]
    ip=impart*bet[2]
    Wb=complex(real=rp,imaginary=ip)
    phi=bet[3]
    yrep=kronecker(y,rep(1,B),"*")
    
    P0seq= -(1+phi)*d1g(Wb)/g(Wb)+phi*yrep*d1g(Wb)/(g(Wb))^2
    P1seq1= -(1+phi)*Wb01*d1g(Wb)/g(Wb)+phi*yrep*Wb01*d1g(Wb)/(g(Wb))^2
    P3seq= 1+log(phi)-digamma(phi)+log(yrep)-log(g(Wb))-yrep/g(Wb)
    
    Psi0=Re(apply(matrix(P0seq,nrow=B),2,mean))
    Psi11=Re(apply(matrix(P1seq1,nrow=B),2,mean))
    Psi3=Re(apply(matrix(P3seq,nrow=B),2,mean))
    Psi=rbind(Psi0,Psi11,Psi3)
    return((Psi%*%t(Psi))/n)
  }
   
 
 result=optim(c(-1.58,0.27,5),mccl)$par
 
 An=hessian(mccl,result)
 Bn=mcov(result)
 invAn=solve(An)
 Bcov=sqrt(diag(invAn%*%Bn%*%invAn/n))

result
Nresult 
Bcov
NBcov 

library(latex2exp)
plot(Zmean,y,type="p",xlab=TeX(r"(Long Term Intake $\{\bar{Z}_{j}\}_{j=1}^{271}$)"),ylab="Scaled FFQ Intake")
#plot(Zmean,y,type="p",main="dietary",xlab="Long Term Intake",ylab="Scaled FFQ Intake")
Zmean=sort(Zmean)
Mode.mccl=(g(result[1]+Zmean*result[2]))
Mode.naive=(g(Nresult[1]+Zmean*Nresult[2]))
lines(Zmean,Mode.mccl,lty=2,lwd=2)
lines(Zmean,Mode.naive,lty=3,lwd=2)
#lines(Zmean,Mode.mccl,type="l",col="red")
#lines(Zmean,Mode.naive,type="l",col="black")

te=Sys.time()
time=te-ts

