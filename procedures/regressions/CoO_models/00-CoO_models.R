

formulaone<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + insprox + techprox"  
labels_one<-c("Ethnic proximity",
              "Social distance = 2",
              "Social distance = 3",
              "Social distance = 4",
              "Average centrality",
              "Abs. diff. centrality",
              "Geographic distance", 
              "Institutional proximity",
              "Technological proximity")

# CTT LPM, Small sample, clustered
runmodels(sformula=formulaone, labels_cov=labels_one, ctt=TRUE, includenas=FALSE, logit=FALSE, clustered=TRUE,time_fe=TRUE, flist=files.databases)

# CTT Logit, Small sample, clustered
runmodels(sformula=formulaone, labels_cov=labels_one, ctt=TRUE, includenas=FALSE, logit=TRUE, clustered=TRUE,time_fe=TRUE, flist=files.databases)

# PBOC LPM, Small sample, clustered
runmodels(sformula=formulaone, labels_cov=labels_one, ctt=FALSE, includenas=FALSE, logit=FALSE, clustered=TRUE,time_fe=TRUE, flist=files.databases)

# PBOC Logit, Small sample, clustered
runmodels(sformula=formulaone, labels_cov=labels_one, ctt=FALSE, includenas=FALSE, logit=TRUE, clustered=TRUE,time_fe=TRUE, flist=files.databases)

# CTT LPM, Large sample, clustered
runmodels(sformula=formulaone, labels_cov=labels_one, ctt=TRUE, includenas=TRUE, logit=FALSE, clustered=TRUE,time_fe=TRUE, flist=files.databases)
# PBOC LPM, Large sample, clustered
runmodels(sformula=formulaone, labels_cov=labels_one, ctt=FALSE, includenas=TRUE, logit=FALSE, clustered=TRUE,time_fe=TRUE, flist=files.databases)


formula_two<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + techprox"  
labels_two<-c("Ethnic proximity",
              "Social distance = 2",
              "Social distance = 3",
              "Social distance = 4",
              "Average centrality",
              "Abs. diff. centrality",
              "Geographic distance", 
              "Technological proximity")
# CTT LPM, Large sample, clustered
runmodels(sformula=formula_two, labels_cov=labels_two, ctt=TRUE, includenas=TRUE, logit=FALSE, clustered=TRUE,time_fe=TRUE, flist=files.databases)
# PBOC LPM, Large sample, clustered
runmodels(sformula=formula_two, labels_cov=labels_two, ctt=FALSE, includenas=TRUE, logit=FALSE, clustered=TRUE,time_fe=TRUE, flist=files.databases)


# CTT Logit, Large sample, clustered
runmodels(sformula=formula_two, labels_cov=labels_two, ctt=TRUE, includenas=TRUE, logit=TRUE, clustered=TRUE,time_fe=TRUE, flist=files.databases)
# PBOC Logit, Large sample, clustered
runmodels(sformula=formula_two, labels_cov=labels_two, ctt=FALSE, includenas=TRUE, logit=TRUE, clustered=TRUE,time_fe=TRUE, flist=files.databases)


formula_three<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis"  
labels_three<-c("Ethnic proximity",
                "Social distance = 2",
                "Social distance = 3",
                "Social distance = 4",
                "Average centrality",
                "Abs. diff. centrality",
                "Geographic distance")
# CTT LPM, Large sample, clustered
runmodels(sformula=formula_three, labels_cov=labels_three, ctt=TRUE, includenas=TRUE, logit=FALSE, clustered=TRUE,time_fe=TRUE, flist=files.databases)
# PBOC LPM, Large sample, clustered
runmodels(sformula=formula_three, labels_cov=labels_three, ctt=FALSE, includenas=TRUE, logit=FALSE, clustered=TRUE,time_fe=TRUE, flist=files.databases)


# CTT Logit, Large sample, clustered
runmodels(sformula=formula_three, labels_cov=labels_three, ctt=TRUE, includenas=TRUE, logit=TRUE, clustered=TRUE,time_fe=TRUE, flist=files.databases)
# PBOC Logit, Large sample, clustered
runmodels(sformula=formula_three, labels_cov=labels_three, ctt=FALSE, includenas=TRUE, logit=TRUE, clustered=TRUE,time_fe=TRUE, flist=files.databases)
