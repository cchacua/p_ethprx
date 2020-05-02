library(ggplot2)
library(ggsci)
library(rms)
# This function only computes models with time fixed effects

predictprob_plot<-function(sformula, 
                           plotname,
                           includenas=TRUE, 
                           type="ctt",
                           logit=FALSE, 
                           fpath="../input/reg",
                           confidence=99
                           
){
  
  # Open file and organize
  flist<-list.files(path=fpath, full.names=TRUE)
  if(includenas==TRUE){
    if(type=="ctt"){
      database<-data.table::as.data.table(read.csv(flist[2]))
    }
    if(type=="pboc"){
      database<-data.table::as.data.table(read.csv(flist[4]))
    }
  }
  else{
    if(type=="ctt"){
      database<-data.table::as.data.table(read.csv(flist[1]))
    }
    if(type=="pboc"){
      database<-data.table::as.data.table(read.csv(flist[3]))
    }
  }
  
  database$geodis<-as.numeric(as.character(database$geodis))
  database$EARLIEST_FILING_YEAR<-factor(database$EARLIEST_FILING_YEAR)
  database$soc<-database$socialdist
  database$soc[database$soc>4]<-"0"
  database$soc<-factor(database$soc)
  
  sformula_t<-as.formula(paste0(sformula, " + EARLIEST_FILING_YEAR"))
  
  ndata<-with(database, data.frame(ethnic=as.numeric(as.character(factor(rep(0:1, each =4)))), 
                                   soc = as.factor(rep(c(0,2,3,4),2)),
                                   av_cent=rep(mean(av_cent), 8),
                                   absdif_cent=rep(mean(absdif_cent), 8), 
                                   geodis=rep(mean(geodis),8), 
                                   EARLIEST_FILING_YEAR=rep(as.factor(2000),8))
  )
  
  if(logit==TRUE){
    #reg_t<-glm(linked ~ ethnic + soc + av_cent + absdif_cent + geodis + EARLIEST_FILING_YEAR, family=binomial(link="logit"), data = database)
    reg_t<-glm(sformula_t, family=binomial(link='logit'), data = database)
    ndata <- cbind(ndata, predict(reg_t, newdata = ndata, type = "link", se = TRUE))
    
    }
  else{
    reg_t<-lm(sformula_t, data = database)
    #reg_t<-miceadds::lm.cluster(data = database, sformula_t, cluster = "finalID")
    
    ndata <- cbind(ndata, predict(reg_t, newdata = ndata, se = TRUE))
    
  }
  print(summary(reg_t))
  # Artificial Sample to predict data
  
  
  # Artificial sample + predictions
  
  # Confidence interval
  if(confidence==99){
    confidence_<-2.576
  }
  if(confidence==95){
    confidence_<-1.96
  }
  
  ndata <- within(ndata, {
    PredictedProb <- plogis(fit)
    LL <- plogis(fit - (confidence_ * se.fit))
    UL <- plogis(fit + (confidence_ * se.fit))
  })
  
  ndata_<-unique(ndata[ndata$EARLIEST_FILING_YEAR==2000,c("PredictedProb","geodis", "ethnic", "soc", "LL","UL")])
  ndata_$ethnic<-as.numeric(as.character(ndata_$ethnic))
  
  ndata_$ethnic[ndata_$ethnic==0]<-"$e_{ij}=0$"
  ndata_$ethnic[ndata_$ethnic!="$e_{ij}=0$"]<-"$e_{ij}=1$"
  ndata_$ethnic<-as.factor(ndata_$ethnic)
  ndata_$soc<-as.numeric(as.character(ndata_$soc))
  #ndata_$soc[ndata_$soc==0]<-5
  ndata_<-ndata_[ndata_$soc>0,]
  
  tikzDevice::tikz(file = paste0("../output/predicted_prob/", plotname, confidence, ".tex"), width = 5.5, height = 2)
  
  measure.plot<-ggplot(ndata_, aes(x = soc, y = PredictedProb)) + 
    scale_color_aaas() + theme_bw()  +
    # geom_ribbon(aes(ymin = LL,
    #                 ymax = UL, fill = ethnic), alpha = 1) +
    geom_line(aes(colour = ethnic), size = 0.5) + scale_x_continuous(breaks=c(2,3,4)) +
    theme(legend.title=element_blank()) +ylab("Predicted Prob.") + xlab("Social distance")
  
  print(measure.plot)
  #Necessary to close or the tikxDevice .tex file will not be written
  dev.off()
}
