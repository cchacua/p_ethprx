#--- Run models by Country of Origin function ---#
#'@title Run simple models function 
#'@description Computes the four simple models for the whole database: both with and without time-fixed effects, for both CTT and PBOC technological fields.
#'@author Christian Chacua \email{christian-mauricio.chacua-delgado@u-bordeaux.fr}
#'@param sformula String. A formula with the linear regression. It should be a string.
#'@param labels_cov List. A list with the strings of the variable labels. It should include the dependent variable and should follow the same order as the formula.
#'@param ctt Logical. TRUE if all the models should be estimated for the CTT field. FALSE all the models should be estimated for the PBOC field.
#'@param includenas Logical. TRUE if large database. FALSE if small or robust database Default value is TRUE. 
#'@param logit Logical. TRUE if Logit model, FALSE if LPM. Default value is FALSE.
#'@param clustered Logical. TRUE if clustered standard errors. Default value is TRUE.
#'@param time_fe Logical. TRUE if the time fixed effects dummies should be included. FALSE otherwise.
#'@param fpath String. Path to the folder that contains the four databases.
#'@return It prints the table to export to latex and it returns a list with the two fixed effects estimated models (a model per each of the CTT and PBOC fields).
#'@examples
#' 
#'
#'@importFrom miceadds stargazer
#'@export 
#'

coomodels<-function(sformula, 
                      labels_cov, 
                      ctt=TRUE, 
                      includenas=TRUE,
                      logit=FALSE, 
                      clustered=TRUE,
                      time_fe=TRUE, 
                      fpath="../input/reg"){
    flist<-list.files(path=fpath, full.names=TRUE)
    if(includenas==TRUE){
      if(ctt==TRUE){
        database<-as.data.table(read.csv(flist[2]))
      }
      else{
        database<-as.data.table(read.csv(flist[4]))
      }
    }
    else{
      if(ctt==TRUE){
        database<-as.data.table(read.csv(flist[1]))
      }
      else{
        database<-as.data.table(read.csv(flist[3]))
      }
    }
    
    database$geodis<-as.numeric(database$geodis)
    database$EARLIEST_FILING_YEAR<-factor(database$EARLIEST_FILING_YEAR)
    
    if(time_fe==TRUE){
      sformula<-as.formula(paste0(sformula, " + EARLIEST_FILING_YEAR"))}
    else{
      sformula<-as.formula(sformula)
    }
    
    ethnics<-c("European.EastEuropean",      
               "European.French",
               "European.German",            
               "European.Italian.Italy",
               "European.Russian", 
               "EastAsian.Chinese",
               "EastAsian.Indochina.Vietnam",
               "EastAsian.Japan",
               "EastAsian.Malay.Indonesia",  
               "EastAsian.South.Korea",
               "Muslim.Persian",
               "SouthAsian")
    ethnics_label<-c("East European",      
                     "French",
                     "German",            
                     "Italy",
                     "Russian",
                     "Chinese",
                     "Vietnam",
                     "Japan",
                     "Indonesia",  
                     "Korea",         
                     "Persian",
                     "South Asian")
    mbycoo<-lapply(ethnics, mosamnat, sformulaa=sformula, logitt=logit, clusteredd=clustered, database)
    
    if(logit==TRUE){
      print(paste(round(mbycoo[[1]]$pseudo, 4), round(mbycoo[[2]]$pseudo, 4), round(mbycoo[[3]]$pseudo, 4),
                  round(mbycoo[[4]]$pseudo, 4), round(mbycoo[[5]]$pseudo, 4), round(mbycoo[[6]]$pseudo, 4),
                  round(mbycoo[[7]]$pseudo, 4), round(mbycoo[[8]]$pseudo, 4), round(mbycoo[[9]]$pseudo, 4),
                  round(mbycoo[[10]]$pseudo, 4), round(mbycoo[[11]]$pseudo, 4), round(mbycoo[[12]]$pseudo, 4), sep = " fff "))
      
      if(ctt==TRUE){
        tittle_table<-"CTT Logit Models by CEL group, 1980-2012"
      }
      else{
        tittle_table<-"PBOC Logit Models by CEL group, 1980-2012"
      }
    }
    else{
      if(ctt==TRUE){
        tittle_table<-"CTT Linear Probability Models by CEL group, 1980-2012"
      }
      else{
        tittle_table<-"PBOC Linear Probability Models by CEL group, 1980-2012"
      }
      
    }
    
    stargazer(mbycoo[[1]]$regre, mbycoo[[2]]$regre, mbycoo[[3]]$regre,
              mbycoo[[4]]$regre, mbycoo[[5]]$regre, mbycoo[[6]]$regre,
              mbycoo[[7]]$regre, mbycoo[[8]]$regre, mbycoo[[9]]$regre,
              mbycoo[[10]]$regre, mbycoo[[11]]$regre, mbycoo[[12]]$regre,
              title=tittle_table,
              align=TRUE,
              column.sep.width="-20pt", digits=4,
              notes.label="", header=FALSE, column.labels=ethnics_label,
              omit        = "EARLIEST_FILING_YEAR",
              omit.labels = "Time fixed effects",
              omit.yes.no = c("Yes","No"),
              dep.var.labels=" ",
              dep.var.labels.include=TRUE,
              dep.var.caption="Co-invention",
              se=list(mbycoo[[1]]$se, mbycoo[[2]]$se, mbycoo[[3]]$se,
                      mbycoo[[4]]$se, mbycoo[[5]]$se, mbycoo[[6]]$se,
                      mbycoo[[7]]$se, mbycoo[[8]]$se, mbycoo[[9]]$se,
                      mbycoo[[10]]$se, mbycoo[[11]]$se, mbycoo[[12]]$se),
              covariate.labels=labels_cov,
              omit.stat=c("ser","f"), no.space=TRUE)
  }