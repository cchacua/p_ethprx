################################################################################
# Simple models models for the large sample, using social proximity
################################################################################

formula<-"linked ~ ethnic + (1/socialdist) + av_cent + absdif_cent + geodis"  
labels<-c("Ethnic proximity",
              "Social proximity",
              "Average centrality",
              "Abs. diff. centrality",
              "Geographic distance")

# Logit with clustered errors, only for the large sample
logitlarge<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=TRUE, clustered=TRUE, fpath="../input/reg")
# LPM with clustered errors, only for the large sample
lpmlarge<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg")

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