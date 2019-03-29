mosamnat<-function(ethnic_row, sformulaa=sformula, logitt=logit, clusteredd=clustered, database){
  sample<-database[database$nation==ethnic_row,]
  
  if(logitt==TRUE){
    reg<-glm(sformulaa, family=binomial(link='logit'), data = sample)
    reg_pseudo<-(reg$null.deviance - reg$deviance)/reg$null.deviance
    #reg<-rms::lrm(sformulaa, data = sample)
    if(clusteredd==TRUE){
      reg_s<-miceadds::glm.cluster(data = sample, sformulaa, cluster = "finalID", family=binomial(link='logit'))
      reg_s<-sqrt(diag(as.matrix(reg_s$vcov)))
    }
    else{
      reg_s<-"NULL"
    }
  }
  else{
    reg<-lm(formula=sformulaa, data = sample)
    reg_pseudo<-"NULL"
    if(clusteredd==TRUE){
      reg_s<-miceadds::lm.cluster(data = sample, sformulaa, cluster = "finalID")
      reg_s<-sqrt(diag(as.matrix(reg_s$vcov)))
    } 
    else{
      reg_s<-"NULL"
    }
  }
  return(list(regre=reg, se=reg_s, pseudo=reg_pseudo))
}
