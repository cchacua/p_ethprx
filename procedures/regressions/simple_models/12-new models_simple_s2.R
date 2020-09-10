################################################################################
# New models for the S2
################################################################################
database_ctt<-data.table::as.data.table(read.csv("../input/reg/s2c.csv"))
database_pboc<-data.table::as.data.table(read.csv("../input/reg/s2p.csv"))

# database_ctt[is.na(database_ctt)] <- 0
# + insprox "Institutional proximity",
# 


formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis  + techprox + same_appl "  
labels<-c("Ethnic similarity",
          "Social distance = 2",
          "Social distance = 3",
          "Social distance = 4",
          "Average centrality",
          "Abs. diff. centrality",
          "Geographic distance", 
          "Technological proximity",
          "Same applicant")
# LPM with clustered errors, only for the Large sample
lpmshort<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)


################################################################################
# Simple models models for the large sample
################################################################################

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis  + techprox + same_appl +  (ethnic*soc_2) + (ethnic*soc_3) + (ethnic*soc_4) "  
labels<-c("Ethnic proximity",
          "Social distance = 2",
          "Social distance = 3",
          "Social distance = 4",
          "Average centrality",
          "Abs. diff. centrality",
          "Geographic distance",
          "Technological proximity",
          "Same applicant",
          "ethnic*soc2", 
          "ethnic*soc3", 
          "ethnic*soc4")

# LPM with clustered errors, only for the large sample
lpmlarge<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)

################################################################################
# Simple models models for the large sample, with geographic distance interactions
################################################################################

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + techprox + same_appl + (ethnic*geodis)"  
labels<-c("Ethnic proximity",
          "Social distance = 2",
          "Social distance = 3",
          "Social distance = 4",
          "Average centrality",
          "Abs. diff. centrality",
          "Geographic distance",
          "Technological proximity",
          "Same applicant",
          "ethnic*geodis")

# LPM with clustered errors, only for the large sample
lpmlarge<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)

################################################################################
# Simple models models for the large sample, with geographic distance interactions
################################################################################

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + techprox + same_appl + (ethnic*same_appl)"  
labels<-c("Ethnic proximity",
          "Social distance = 2",
          "Social distance = 3",
          "Social distance = 4",
          "Average centrality",
          "Abs. diff. centrality",
          "Geographic distance",
          "Technological proximity",
          "Same applicant",
          "ethnic*same_appl")

# LPM with clustered errors, only for the large sample
lpmlarge<-simmodels(sformula=formula, labels_cov=labels, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg", onlyt = TRUE)














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

