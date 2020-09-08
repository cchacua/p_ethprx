source("~/input/conf/connection.R")
source("./procedures/networks/fun_socialdistance.R")
library("igraph")
library("data.table")


ugraphinv_dis <-function(endyear, withplot, sector, sample) tryCatch(ugraphinv_dis_bulk(endyear, withplot, sector, sample), error = function(e) NULL)
ynumbers<-seq(1975, 2012, 1)

lapply(ynumbers, ugraphinv_dis, sector="p", sample="t72_s2")
lapply(ynumbers, ugraphinv_dis , sector="c", sample="t72_s2")

# ugraphinv_dis_bulk(2005, sector="p", sample="t72_s2") 


# Merge multiple files (takes too much ram)
# merge.csv = function(mypath){
#   filenames=list.files(path=mypath, full.names=TRUE)
#   datalist = lapply(filenames, read.csv, stringsAsFactors = FALSE)
#   datalist = do.call("rbind", datalist)  
#   datalist<-unique(datalist)
#   #datalist[datalist== ""] <- NA
#   datalist
# }
# 
# 
# socialdis_ctt<-merge.csv("../output/graphs/distance_list/c/")
# fwrite(socialdis_ctt, "../output/graphs/distance_list/c_list.csv")
