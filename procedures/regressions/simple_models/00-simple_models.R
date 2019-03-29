################################################################################
# Function to run models
################################################################################
    
  source("./procedures/regressions/simple_models/fun_simmodels.R")
  source("./procedures/regressions/simple_models/fun_diffsocial.R")

################################################################################
# Baseline models models for the large sample
################################################################################

  source("./procedures/regressions/simple_models/01-large_sample.R")  

################################################################################
# Robust models for the small sample
################################################################################

  source("./procedures/regressions/simple_models/02-robust_sample.R")  

################################################################################
# Test of equality of coefficients for the social distances
################################################################################

  diffsocial(logitlarge[[1]])
  diffsocial(logitlarge[[2]])
  
  diffsocial(lpmlarge[[1]])
  diffsocial(lpmlarge[[2]])
  
  diffsocial(logitshor[[1]])
  diffsocial(logitshor[[2]])
  
  diffsocial(lpmshort[[1]])
  diffsocial(lpmshort[[2]])
