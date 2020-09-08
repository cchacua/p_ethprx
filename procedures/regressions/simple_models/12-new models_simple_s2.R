################################################################################
# New models for the S2
################################################################################

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + insprox + techprox"  
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
lpmshort<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + same_appl "  
labels<-c("Ethnic similarity",
          "Social distance = 2",
          "Social distance = 3",
          "Social distance = 4",
          "Average centrality",
          "Abs. diff. centrality",
          "Geographic distance", 
          "Same applicant")
# LPM with clustered errors, only for the Large sample
lpmshort<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + techprox + same_appl "  
labels<-c("Ethnic similarity",
          "Social distance = 2",
          "Social distance = 3",
          "Social distance = 4",
          "Average centrality",
          "Abs. diff. centrality",
          "Geographic distance", 
          "Technological proximity",
          "Same applicant")
# LPM with clustered errors, only for the small sample
lpmshort<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)



formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + same_appl + same_state + same_msa "  
labels<-c("Ethnic similarity",
          "Social distance = 2",
          "Social distance = 3",
          "Social distance = 4",
          "Average centrality",
          "Abs. diff. centrality",
          "Geographic distance", 
          "Same applicant",
          "Same State", 
          "Same MSA")
# LPM with clustered errors, only for the small sample
lpmshort<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)


formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + same_appl + same_state + same_msa "  
labels<-c("Ethnic similarity",
          "Social distance = 2",
          "Social distance = 3",
          "Social distance = 4",
          "Average centrality",
          "Abs. diff. centrality",
          "Geographic distance", 
          "Same applicant",
          "Same State", 
          "Same MSA")
# LPM with clustered errors, only for the small sample
lpmshort<-simmodels_german(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)

