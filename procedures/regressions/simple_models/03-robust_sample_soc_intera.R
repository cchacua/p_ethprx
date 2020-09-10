################################################################################
# Robust models for the small sample, with social interactions
################################################################################

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + insprox + techprox + (ethnic*soc_2) + (ethnic*soc_3) + (ethnic*soc_4) "  
# formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + insprox + techprox + (ethnic:soc_2) + (ethnic:soc_3) + (ethnic:soc_4) "  

labels<-c("Ethnic similarity",
              "Social distance = 2",
              "Social distance = 3",
              "Social distance = 4",
              "Average centrality",
              "Abs. diff. centrality",
              "Geographic distance", 
              "Institutional proximity",
              "Technological proximity")

# LPM with clustered errors, only for the small sample
lpmshort<-simmodels(sformula=formula, labels_cov=labels, includenas=FALSE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)

# Logit with clustered errors, only for the small sample
logitshor<-simmodels(sformula=formula, labels_cov=labels, includenas=FALSE, logit=TRUE, clustered=TRUE, fpath="../input/reg")
