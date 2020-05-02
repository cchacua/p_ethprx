
###############################


database<-predictprob_plot(sformula=formula_two, 
                           plotname="ctt_large_logit99",
                           includenas=TRUE, 
                           type="ctt",
                           logit=TRUE, 
                           fpath="../input/reg",
                           confidence=99
)

reg_t<-glm(linked ~ ethnic + soc + av_cent + absdif_cent + geodis + EARLIEST_FILING_YEAR, family=binomial(link="logit"), data = database)

# Join of the two artificial samples
ndata<-with(database, data.frame(ethnic=as.numeric(as.character(factor(rep(0:1, each =4)))), 
                                 soc = as.factor(rep(c(0,2,3,4),2)),
                                 av_cent=rep(mean(av_cent), 8),
                                 absdif_cent=rep(mean(absdif_cent), 8), 
                                 geodis=rep(mean(geodis),8), 
                                 EARLIEST_FILING_YEAR=rep(as.factor(2000),8))
)

unique(database$soc)
# rep(seq(from = 0, to = 25, length.out = 5),66),
# Artificial sample + predictions
ndata <- cbind(ndata, predict(reg_t, newdata = ndata, type = "link", se = TRUE))

confidence_<-1.96

# Confidence interval
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
ndata_<-ndata_[ndata_$soc>0,]

tikzDevice::tikz(file = paste0("../output/predicted_prob/", plotname,".tex"), width = 5.5, height = 2)

measure.plot<-ggplot(ndata_, aes(x = soc, y = PredictedProb)) + 
                      scale_color_aaas() + theme_bw()  +
                      geom_ribbon(aes(ymin = LL,
                                      ymax = UL, fill = ethnic), alpha = 1) +
   geom_line(aes(colour = ethnic), size = 0.5) + scale_x_continuous(breaks=c(2,3,4)) +
   theme(legend.title=element_blank()) +ylab("Predicted Prob.") + xlab("Social distance")
measure.plot

print(measure.plot)
#Necessary to close or the tikxDevice .tex file will not be written
dev.off()





##################################

  


  
}

###############################3


# Artificial sample when the social distance is >4 (which takes the value of 0, as it is the reference case)
ndata1 <- with(database, data.frame(ethnic=as.numeric(as.character(factor(rep(0:1, each =165)))), 
                                    soc = as.factor(0),
                                    av_cent=mean(av_cent),
                                    absdif_cent=mean(absdif_cent), 
                                    geodis=rep(seq(from = 0, to = 25, length.out = 5),66),
                                    EARLIEST_FILING_YEAR=factor(rep(1980:2012, each = 5))
))
# Artificial sample when social distance is 3
ndata2 <- with(database, data.frame(ethnic=as.numeric(as.character(factor(rep(0:1, each =165)))), 
                                    soc = as.factor(3),
                                    av_cent=mean(av_cent),
                                    absdif_cent=mean(absdif_cent), 
                                    geodis=rep(seq(from = 0, to = 25, length.out = 5),66),
                                    EARLIEST_FILING_YEAR=factor(rep(1980:2012, each = 5))
))

# Join of the two artificial samples
ndata<-rbind(ndata1,ndata2)
# Artificial sample + predictions
ndata <- cbind(ndata, predict(reg_t, newdata = ndata, type = "link", se = TRUE))

if(confidence==99){
  confidence_<-2.576
}
if(confidence==95){
  confidence_<-1.96
}
# Confidence interval
ndata <- within(ndata, {
  PredictedProb <- plogis(fit)
  LL <- plogis(fit - (confidence_ * se.fit))
  UL <- plogis(fit + (confidence_ * se.fit))
})

# Only plot one year
ndata_<-unique(ndata[ndata$EARLIEST_FILING_YEAR==2000,c("PredictedProb","geodis", "ethnic", "soc", "LL","UL")])
ndata_$ethnic<-as.numeric(as.character(ndata_$ethnic))

ndata_$ethnic[ndata_$ethnic==0]<-"$e_{ij}=0$"
ndata_$ethnic[ndata_$ethnic!="$e_{ij}=0$"]<-"$e_{ij}=1$"
ndata_$ethnic<-as.factor(ndata_$ethnic)
ndata_$soc<-as.numeric(as.character(ndata_$soc))
ndata_$soc[ndata_$soc==0]<-"$s_{ij}>4$"
ndata_$soc[ndata_$soc!="$s_{ij}>4$"]<-"$s_{ij}=3$"
ndata_$soc<-factor(ndata_$soc)

tikzDevice::tikz(file = paste0("../output/predicted_prob/", plotname,".tex"), width = 5.5, height = 2)

measure.plot<-ggplot(ndata_, aes(x = geodis, y = PredictedProb)) + 
  scale_color_aaas() + theme_bw()  + 
  geom_ribbon(aes(ymin = LL,
                  ymax = UL, fill = ethnic), alpha = 1) +
  geom_line(aes(colour = ethnic), size = 0.5) +
  theme(legend.title=element_blank()) + facet_grid(. ~ soc) +ylab("Predicted Prob.") + xlab("Geographic distance")

#measure.plot

#ggplot(sizes, aes(Year, Measure, colour=type)) + scale_color_aaas() + theme_bw() + geom_line(size=1)+ geom_point(size=2)+xlab("Year") + ylab(legend.t) + scale_x_continuous(minor_breaks = seq(1979 , 2013, 5), breaks = seq(1979 , 2013, 10)) + theme(legend.title=element_blank())
print(measure.plot)
#Necessary to close or the tikxDevice .tex file will not be written
dev.off()

formula_two<-"linked ~ linked ~ ethnic + soc + av_cent + absdif_cent + geodis"  

predictprob_plot(sformula=formula_two, 
                 plotname="ctt_large_logit99",
                           includenas=TRUE, 
                           type="ctt",
                           logit=TRUE, 
                           fpath="../input/reg",
                           confidence=99
)



# LPM with clustered errors, only for the large sample
lpmlarge_ctt<-runmodels(sformula=formula_two, labels_cov=labels_two, includenas=TRUE, logit=FALSE, clustered=TRUE, flist=files.databases, ctt=TRUE)
