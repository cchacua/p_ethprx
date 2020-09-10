################################################################################
# Simple models models for the large sample
################################################################################

formula_two<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis"  
labels_two<-c("Ethnic similarity",
              "Social distance = 2",
              "Social distance = 3",
              "Social distance = 4",
              "Average centrality",
              "Abs. diff. centrality",
              "Geographic distance")

# Logit with clustered errors, only for the large sample
logitlarge<-simmodels(sformula=formula_two, labels_cov=labels_two, includenas=TRUE, logit=TRUE, clustered=TRUE, fpath="../input/reg")
# LPM with clustered errors, only for the large sample
lpmlarge<-simmodels(sformula=formula_two, labels_cov=labels_two, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg")
lpmlarge<-simmodels(sformula=formula_two, labels_cov=labels_two, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg_uniqueid")


################################################################################
# Proportion of predicted probabilites in the range (0.2;0.8), for the LPM
# Only for the large sample  
################################################################################

lpmlarge1_predict<-predict(lpmlarge[[1]], se.fit = 1)
length(lpmlarge1_predict$fit[lpmlarge1_predict$fit<0.2])/length(lpmlarge1_predict$fit)
length(lpmlarge1_predict$fit[lpmlarge1_predict$fit>0.8])/length(lpmlarge1_predict$fit)

lpmlarge2_predict<-predict(lpmlarge[[2]], se.fit = 1)
length(lpmlarge2_predict$fit[lpmlarge2_predict$fit<0.2])/length(lpmlarge2_predict$fit)
length(lpmlarge2_predict$fit[lpmlarge2_predict$fit>0.8])/length(lpmlarge2_predict$fit)

margins_1<-summary(margins(lpmlarge[[1]], lpmlarge[[1]]$model))