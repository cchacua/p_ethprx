#--- Test of equality of the social distance coefficients ---#
#'@title Run simple models function 
#'@description Computes the t-tests of "soc_2 = soc_3", "soc_3 = soc_4", "soc_2 = soc_4"
#'@author Christian Chacua \email{christian-mauricio.chacua-delgado@u-bordeaux.fr}
#'@param model Object. The object with the model
#'@return It prints the results for each of the tests.
#' 
#' formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + insprox + techprox"  
#' labels_one<-c("Ethnic proximity",
#'              "Social distance = 2",
#'              "Social distance = 3",
#'              "Social distance = 4",
#'              "Average centrality",
#'              "Abs. diff. centrality",
#'              "Geographic distance", 
#'              "Institutional proximity",
#'              "Technological proximity")
#' # LPM with clustered errors, only for the large sample
#' lpmlarge<-simmodels(sformula=formula_two, labels_cov=labels_two, includenas=TRUE, logit=FALSE, clustered=TRUE, fpath="../input/reg")
#' differences_social(logitlarge[[1]])
#' differences_social(logitlarge[[2]])
#'@importFrom car
#'@export 
#'

diffsocial<-function(model){
  print(car::linearHypothesis(model, "soc_2 = soc_3"))
  print(car::linearHypothesis(model, "soc_3 = soc_4"))
  print(car::linearHypothesis(model, "soc_2 = soc_4"))
}