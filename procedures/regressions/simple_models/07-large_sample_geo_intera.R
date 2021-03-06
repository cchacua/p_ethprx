################################################################################
# Simple models models for the large sample, with geographic distance interactions
################################################################################

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + (ethnic*geodis)"  
labels<-c("Ethnic similarity",
          "Social distance = 2",
          "Social distance = 3",
          "Social distance = 4",
          "Average centrality",
          "Abs. diff. centrality",
          "Geographic distance")

# LPM with clustered errors, only for the large sample
lpmlarge<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)

# Logit with clustered errors, only for the large sample
logitlarge<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=TRUE, clustered=TRUE, fpath="../input/reg")
