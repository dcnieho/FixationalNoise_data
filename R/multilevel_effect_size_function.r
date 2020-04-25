multilevel.effect.size<-function(lmer.model){
  #Information of the measures can be found in LaHuis, Hartman, Hakoyama, and Clark (2014).
  #This function will produce Multiple R squared measures for multilevel models based 
  #on lmer models from lme4 package in R.
  #This function should be used for research and education (and/or entertainment) purposes only.
  #contact shotaro.hakoyama@gmail.com for bugs, suggestions, and comments. 
  
  require(lme4);
  #extracting the name of the data frame from the lmer object import them to use within the function.
  data<-lmer.model@frame
  
  #extracting pieces of the lmer model syntax.
  fml <- paste(as.character(formula(lmer.model))[c(2,1,3)], collapse = ' ')
  model<-strsplit(fml, split=" + (", fixed=T)
  criterion<-names(data)[1]
  group.id<-names(data)[length(names(data))]
  #computing null model needed for R2 approx and R2 S&B
  null<-update(lmer.model,as.formula(paste(criterion, " ~ 1 + (1 | ", group.id,")", sep="")))
  
  #extracting variance components and coefficients from the models. 
  null.var<-lme4::VarCorr(null)
  null.tau00<-attr(null.var[[group.id]],"stddev")^2
  null.sigma<-attr(null.var,'sc')^2
  
  fixed.model<-update(lmer.model,as.formula(paste(model[[1]][1], " + ( 1 | ", group.id,")" ,sep="")))
  fixed.model.fixef<-fixef(fixed.model)
  fixed.model.var<-lme4::VarCorr(fixed.model)
  fixed.model.tau00<-attr(fixed.model.var[[group.id]],"stddev")^2
  fixed.model.sigma<-attr(fixed.model.var,'sc')^2
  
  lmer.model.fixef<-fixef(lmer.model)
  lmer.model.var<-lme4::VarCorr(lmer.model)
  tau<-diag(lmer.model.var[[group.id]][,])
  lmer.model.sigma<-attr(lmer.model.var,'sc')^2
  
  slope.var<-NULL
  for ( zz in 2:length(tau)){
  slope.var<-append(slope.var, tau[zz]*var(data[names(tau)[zz]]))
  }
  
  if(is.na(tau["(Intercept)"])){
    tau.int<-fixed.model.tau00 }else {
    tau.int<-tau["(Intercept)"]
     }
  
  tau.sigma = tau.int+lmer.model.sigma+sum(slope.var)
  
  r2.approx.level1<-(null.sigma-fixed.model.sigma)/null.sigma
  r2.approx.level2<-(null.tau00-fixed.model.tau00)/null.tau00
  r2.s.b<-1-(tau.sigma)/(null.sigma+null.tau00)
  r2.ols<-summary(lm(as.formula(model[[1]][1]), data=data))$r.squared
  
  predicted.y<-predict(lmer.model, re.form=NA)
  r2.mvp<-var(predicted.y)/(var(predicted.y)+tau.sigma)
  
  R.squared<-data.frame(r2.approx.level1, r2.approx.level2, r2.s.b, r2.ols,r2.mvp)
  names(R.squared)<-c("R^2 Approx Level1", "R^2 Approx Level2", "R^2 Snijders & Bosker", "R^2 OLS","R^2 MVP")
  rownames(R.squared)<-NULL

  return(R.squared)
}