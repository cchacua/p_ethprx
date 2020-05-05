library(tidyr)
library(dplyr)
library(readr)

data<-read_csv('../input/nationality_all_names.csv')

write_csv(unique(data[order(data$finalID), c("finalID", "full_big", "name.1" )]), "../output/finalid_nameinfo.csv" , row.names=FALSE)

data<-unique(data[order(data$finalID), c(5, 13:51)])
names(data)[23]<-"Hispanic.Portuguese"
write.csv(data.frame(celgr_text=colnames(data[2:40])), "../output/celgroups.csv")

colnames(data)<-c('finalID', as.vector(paste0('X',seq(1,39,1))))
colnames(data)
data<-data %>%
  gather(celgr, prob, 2:40)

write_csv(data[, c("finalID", "celgr", "prob" )], "../output/finalid_cel_prob.csv")