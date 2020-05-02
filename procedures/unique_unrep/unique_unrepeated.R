# Unique and unrepeated ID
# Create unique id that is undirected
undid_unrep<-function(row){
  row<-as.data.frame(t(row))
  value<-paste0(row$EARLIEST_FILING_YEAR, min(as.character(row$finalID),as.character(row$finalID_)), max(as.character(row$finalID),as.character(row$finalID_)))
  return(value)
}

minfinalID<-function(row){
  row<-as.data.frame(t(row))
  value<-min(as.character(row$finalID),as.character(row$finalID_))
  return(value)
}

maxfinalID<-function(row){
  row<-as.data.frame(t(row))
  value<-max(as.character(row$finalID),as.character(row$finalID_))
  return(value)
}

fpath="../input/reg"
flist<-list.files(path=fpath, full.names=TRUE)
for (i in 1:length(flist)){
  data<-data.table::as.data.table(read.csv(flist[i]))
  
  data$undid_unrep<-apply(data[,c("EARLIEST_FILING_YEAR", "finalID", "finalID_")], 1, undid_unrep)
  data$minfinalID<-apply(data[,c("finalID", "finalID_")], 1, minfinalID)
  data$maxfinalID<-apply(data[,c("finalID", "finalID_")], 1, maxfinalID)
  print(nrow(data) - length(unique(data$undid_unrep)))
  print(length(unique(data$undid_unrep)))
  data<-unique(data[,-c("counterof","undidcc","finalID", "finalID_","nation","nation_","idnodes", "undid")])
  colnames(data)[colnames(data)=="maxfinalID"] <- "finalID_"
  colnames(data)[colnames(data)=="minfinalID"] <- "finalID"
  write.csv(data, paste0('../input/reg_uniqueid/', 
                         stringr::str_extract(flist[i], '[a-zA-Z_]+\\.csv')))
}
