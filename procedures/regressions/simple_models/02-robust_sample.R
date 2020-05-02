################################################################################
# Robust models for the small sample
################################################################################

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + insprox + techprox"  
labels<-c("Ethnic proximity",
              "Social distance = 2",
              "Social distance = 3",
              "Social distance = 4",
              "Average centrality",
              "Abs. diff. centrality",
              "Geographic distance", 
              "Institutional proximity",
              "Technological proximity")
# Logit with clustered errors, only for the small sample
logitshor<-simmodels(sformula=formula, labels_cov=labels, includenas=FALSE, logit=TRUE, clustered=TRUE, fpath="../input/reg_uniqueid", onlyt = TRUE)
logitshor<-simmodels(sformula=formula, labels_cov=labels, includenas=FALSE, logit=TRUE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)

# LPM with clustered errors, only for the small sample
lpmshort<-simmodels(sformula=formula, labels_cov=labels, includenas=FALSE, logit=FALSE, clustered=TRUE, fpath="../input/reg_uniqueid", onlyt = TRUE)
lpmshort<-simmodels(sformula=formula, labels_cov=labels, includenas=FALSE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)
