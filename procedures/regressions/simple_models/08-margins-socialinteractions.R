formula_two<-"linked ~ ethnic + soc + av_cent + absdif_cent + geodis"  
formula_two<-"linked ~ ethnic + soc + av_cent + absdif_cent + geodis + (ethnic*soc)"  

predictprob_plot(sformula=formula_two, 
                 plotname="ctt_large_logit_",
                 includenas=TRUE, 
                 type="ctt",
                 logit=TRUE, 
                 fpath="../input/reg",
                 confidence=95
)

predictprob_plot(sformula=formula_two, 
                 plotname="ctt_large_lpm_",
                 includenas=TRUE, 
                 type="ctt",
                 logit=FALSE, 
                 fpath="../input/reg",
                 confidence=95
)


predictprob_plot(sformula=formula_two, 
                 plotname="pboc_large_lpm_",
                 includenas=TRUE, 
                 type="pboc",
                 logit=FALSE, 
                 fpath="../input/reg",
                 confidence=95
)
