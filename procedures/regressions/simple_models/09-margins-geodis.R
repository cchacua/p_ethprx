formula<-"linked ~ ethnic + soc + av_cent + absdif_cent + geodis + (ethnic*geodis)"  

predictprobgeo_plot(sformula=formula, 
                 plotname="ctt_large_logit_",
                 includenas=TRUE, 
                 type="ctt",
                 logit=TRUE, 
                 fpath="../input/reg",
                 confidence=95
)

predictprobgeo_plot(sformula=formula, 
                 plotname="ctt_large_lpm_",
                 includenas=TRUE, 
                 type="ctt",
                 logit=FALSE, 
                 fpath="../input/reg",
                 confidence=95
)
