#--- Run simple models function ---#
#'@title Run simple models function 
#'@description Computes the four simple models for the whole database: both with and without time-fixed effects, for both CTT and PBOC technological fields.
#'@author Christian Chacua \email{christian-mauricio.chacua-delgado@u-bordeaux.fr}
#'@param sformula String. A formula with the linear regression. It should be a string.
#'@param labels_cov List. A list with the strings of the variable labels. It should include the dependent variable and should follow the same order as the formula.
#'@param includenas Logical. TRUE if large database. FALSE if small or robust database Default value is TRUE. 
#'@param logit Logical. TRUE if Logit model, FALSE if LPM. Default value is FALSE.
#'@param clustered Logical. TRUE if clustered standard errors. Default value is TRUE.
#'@param fpath String. Path to the folder that contains the four databases.
#'@param onlyt Logical. If TRUE, only the time-fixed effects models will be estimated. As a consequence, the table will only contain two models.
#'@return It prints the table to export to latex and it returns a list with the two fixed effects estimated models (a model per each of the CTT and PBOC fields).
#'@examples
#' 
#' formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + insprox + techprox"  
#' labels_one<-c("Ethnic similarity",
#'              "Social distance = 2",
#'              "Social distance = 3",
#'              "Social distance = 4",
#'              "Average centrality",
#'              "Abs. diff. centrality",
#'              "Geographic distance", 
#'              "Institutional proximity",
#'              "Technological proximity")
#' # Logit with clustered errors, only for the large sample
#' logitlarge<-simmodels(sformula=formula, labels_cov=labels_two, includenas=TRUE, logit=TRUE, clustered=TRUE, fpath="../input/reg")
#' # LPM with clustered errors, only for the large sample
#' lpmlarge<-simmodels(sformula=formula_two, labels_cov=labels_two, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg")
#'@importFrom miceadds stargazer
#'@export 
#'

simmodels<-function(sformula, 
                    labels_cov, 
                    includenas=TRUE, 
                    logit=FALSE, 
                    clustered=TRUE, 
                    fpath="../input/reg",
                    onlyt=FALSE){
  
  flist<-list.files(path=fpath, full.names=TRUE)
  if(includenas==TRUE){
    database_ctt<-data.table::as.data.table(read.csv(flist[1]))
    database_pboc<-data.table::as.data.table(read.csv(flist[2]))
  }
  else{
    database_ctt<-data.table::as.data.table(read.csv(flist[3]))
    database_pboc<-data.table::as.data.table(read.csv(flist[4]))
  }
  
  database_ctt$geodis<-as.numeric(database_ctt$geodis/10000)
  database_ctt$EARLIEST_FILING_YEAR<-factor(database_ctt$EARLIEST_FILING_YEAR)
  
  database_pboc$geodis<-as.numeric(database_pboc$geodis/10000)
  database_pboc$EARLIEST_FILING_YEAR<-factor(database_pboc$EARLIEST_FILING_YEAR)
  
  sformula_t<-as.formula(paste0(sformula, " + EARLIEST_FILING_YEAR"))
  sformula<-as.formula(sformula)
  
  if(logit==TRUE){
    tittle_table<-"Logit Models, 1980-2012"
    if(onlyt==FALSE){
      reg_ctt<-glm(sformula, family=binomial(link='logit'), data = database_ctt)
      reg_pboc<-glm(sformula, family=binomial(link='logit'), data = database_pboc)
    }
    reg_t_ctt<-glm(sformula_t, family=binomial(link='logit'), data = database_ctt)
    reg_t_pboc<-glm(sformula_t, family=binomial(link='logit'), data = database_pboc)
    
    if(onlyt==FALSE){
    print(paste("Pseudo-R2", round(logit_pseudor2(reg_ctt),4), 
                round(logit_pseudor2(reg_t_ctt),4), round(logit_pseudor2(reg_pboc),4),
                paste0(round(logit_pseudor2(reg_t_pboc),4), " \\"), sep = " & "))
    }
    else{
      print(paste("Pseudo-R2", round(logit_pseudor2(reg_t_ctt),4),
                  paste0(round(logit_pseudor2(reg_t_pboc),4), " \\"), sep = " & "))
    }
    
    if(clustered==TRUE){
      if(onlyt==FALSE){
      reg_ctt_c<-miceadds::glm.cluster(data = database_ctt, sformula, cluster = "fcfinv", family=binomial(link='logit'))
      reg_pboc_c<-miceadds::glm.cluster(data = database_pboc, sformula, cluster = "fcfinv", family=binomial(link='logit'))
      reg_ctt_c_s<-sqrt(diag(as.matrix(reg_ctt_c$vcov)))
      reg_pboc_c_s<-sqrt(diag(as.matrix(reg_pboc_c$vcov)))
      }
      reg_t_ctt_c<-miceadds::glm.cluster(data = database_ctt, sformula_t, cluster = "fcfinv", family=binomial(link='logit'))
      reg_t_pboc_c<-miceadds::glm.cluster(data = database_pboc, sformula_t, cluster = "fcfinv", family=binomial(link='logit'))
      reg_t_ctt_c_s<-sqrt(diag(as.matrix(reg_t_ctt_c$vcov)))
      reg_t_pboc_c_s<-sqrt(diag(as.matrix(reg_t_pboc_c$vcov)))
      
      #rm(reg_ctt_c,reg_pboc_c,reg_t_ctt_c,reg_t_pboc_c)
    }
  }
  else{
    tittle_table<-"Linear Probability Models, 1980-2012"
    
    if(clustered==TRUE){
      if(onlyt==FALSE){
      reg_ctt_c<-miceadds::lm.cluster(data = database_ctt, sformula, cluster = "fcfinv")
      reg_pboc_c<-miceadds::lm.cluster(data = database_pboc, sformula, cluster = "fcfinv")
      reg_ctt_c_s<-sqrt(diag(as.matrix(reg_ctt_c$vcov)))
      reg_pboc_c_s<-sqrt(diag(as.matrix(reg_pboc_c$vcov)))
      }
      reg_t_ctt_c<-miceadds::lm.cluster(data = database_ctt, sformula_t, cluster = "fcfinv")
      reg_t_pboc_c<-miceadds::lm.cluster(data = database_pboc, sformula_t, cluster = "fcfinv")
      reg_t_ctt_c_s<-sqrt(diag(as.matrix(reg_t_ctt_c$vcov)))
      reg_t_pboc_c_s<-sqrt(diag(as.matrix(reg_t_pboc_c$vcov)))
      
      #rm(reg_ctt_c,reg_pboc_c,reg_t_ctt_c,reg_t_pboc_c)
    }
    
    if(onlyt==FALSE){
    reg_ctt<-lm(formula=sformula, data = database_ctt)
    reg_pboc<-lm(formula=sformula, data = database_pboc)
    }
    reg_t_ctt<-lm(sformula_t, data = database_ctt)
    reg_t_pboc<-lm(sformula_t, data = database_pboc)
    
  }
  
  if(clustered==TRUE){
    if(onlyt==FALSE){
    stargazer::stargazer(reg_ctt, reg_t_ctt, reg_pboc, reg_t_pboc, title=tittle_table,
                         type = "latex", 
                         align=TRUE, 
                         column.labels=c("CTT", "PBOC"), 
                         column.separate=c(2,2),
                         column.sep.width="-20pt", 
                         digits=4,
                         notes.label="", 
                         header=FALSE,
                         omit="EARLIEST_FILING_YEAR",
                         omit.labels = "Time fixed effects",
                         omit.yes.no = c("Yes","No"),
                         dep.var.labels=" ",
                         dep.var.labels.include=TRUE,
                         dep.var.caption="Co-invention",
                         se=list(reg_ctt_c_s,reg_t_ctt_c_s,reg_pboc_c_s,reg_t_pboc_c_s),
                         covariate.labels=labels_cov,
                         omit.stat=c("ser","f"), no.space=TRUE)
    }
    else{
      stargazer::stargazer(reg_t_ctt, reg_t_pboc, title=tittle_table,
                           type = "latex", 
                           align=TRUE, 
                           column.labels=c("CTT", "PBOC"), 
                           column.separate=c(1,1),
                           column.sep.width="-20pt", 
                           digits=4,
                           notes.label="", 
                           header=FALSE,
                           omit="EARLIEST_FILING_YEAR",
                           omit.labels = "Time fixed effects",
                           omit.yes.no = c("Yes","No"),
                           dep.var.labels=" ",
                           dep.var.labels.include=TRUE,
                           dep.var.caption="Co-invention",
                           se=list(reg_t_ctt_c_s,reg_t_pboc_c_s),
                           covariate.labels=labels_cov,
                           omit.stat=c("ser","f"), no.space=TRUE)
    }
    
    return(list(reg_t_ctt_c, reg_t_pboc_c))
  }
  else{
    if(onlyt==FALSE){
    stargazer::stargazer(reg_ctt, reg_t_ctt, reg_pboc, reg_t_pboc, title=tittle_table,
                         type = "latex",
              align=TRUE, column.labels=c("CTT", "PBOC"), column.separate=c(2,2),
              column.sep.width="-20pt", digits=4,
              notes.label="", header=FALSE,
              omit        = "EARLIEST_FILING_YEAR",
              omit.labels = "Time fixed effects",
              omit.yes.no = c("Yes","No"),
              dep.var.labels=" ",
              dep.var.labels.include=TRUE,
              dep.var.caption="Co-invention",
              covariate.labels=labels_cov,
              omit.stat=c("ser","f"), no.space=TRUE)
    }
    else{
      stargazer::stargazer(reg_t_ctt, reg_t_pboc, title=tittle_table,
                           type = "latex",
                           align=TRUE, column.labels=c("CTT", "PBOC"), column.separate=c(1,1),
                           column.sep.width="-20pt", digits=4,
                           notes.label="", header=FALSE,
                           omit        = "EARLIEST_FILING_YEAR",
                           omit.labels = "Time fixed effects",
                           omit.yes.no = c("Yes","No"),
                           dep.var.labels=" ",
                           dep.var.labels.include=TRUE,
                           dep.var.caption="Co-invention",
                           covariate.labels=labels_cov,
                           omit.stat=c("ser","f"), no.space=TRUE)
    }
    return(list(reg_t_ctt, reg_t_pboc))
  }
  
}
