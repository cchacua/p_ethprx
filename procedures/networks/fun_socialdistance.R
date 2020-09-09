#--- Compute social distance ---#
#'@title Compute social distance
#'@description Computes the social distance taking a list of nodes in time t and a temporal network in time t-5 to t-1
#'@author Christian Chacua \email{christian-mauricio.chacua-delgado@u-bordeaux.fr}
#'@param endyear Numeric. The year t
#'@param withplot Boolean. Should we plot the network. Default is False
#'@param sector String. It can be c for CTT or p for PBOC field
#'@param sample String. Prefix of the table name. Default is t73_s3
#'@return It saves some output files
#'@examples
#' 
#'@importFrom igraph data.table
#'@export 
#'


# print("Sector should be pboc or ctt")
# endyear=1990
# withplot=FALSE
# sector="c"
# sample="t73_s3"


ugraphinv_dis_bulk<-function(endyear, withplot=FALSE, sector="c", sample="t73_s3"){

  inityear<-endyear-4
  linkyear<-endyear+1
  print(paste("Beginning year (t-5):", inityear))
  print(paste("Ending year (t-1):", endyear))
  print(paste("Link year (t0):", linkyear))
  edges_net<-as.data.table(dbGetQuery(christian2019, paste0(
    "SELECT DISTINCT CAST(a.inv_fid AS CHAR)  AS finalID_, CAST(a.inv_fid_ AS CHAR) AS finalID__
    FROM pethprx.t51_edir a
    INNER JOIN pethprx.t01_samples b
    ON a.pat_id=b.pat_id AND b.EARLIEST_FILING_YEAR>=",inityear," AND b.EARLIEST_FILING_YEAR<=",endyear," AND b.field IN ('i', '", sector, "')
    ;")))
  
  edges_reg<-as.data.table(dbGetQuery(christian2019, paste0("SELECT DISTINCT CAST(inv_fid AS CHAR) AS finalID_,  CAST(inv_fid_ AS CHAR) AS finalID__, id AS undid
                                                         FROM pethprx.", sample, sector, 
                                                         " WHERE EARLIEST_FILING_YEAR=",linkyear)))
  print("Data has been loaded")
  print(paste("Number of total edges",nrow(edges_net)))
  print(paste("Number of edges to find",nrow(edges_reg), nrow(edges_reg)/nrow(edges_net)))
  graph<-graph_from_data_frame(edges_net, directed = FALSE)
  #rm(edges_net)
  #save(graph, file=paste0("/home/rstudio/output/graphs/networks/",sample,sector, "_", inityear,"-",endyear, "_network", ".RData"))
  print("Graph has been done")
  
  nodesdegree<-unique(rbind(data.frame(v1=edges_reg$finalID_),data.frame(v1=edges_reg$finalID__)))
  list.vertex.attributes(graph)
  vdegree<-V(graph)[V(graph)$name %in% nodesdegree$v1]
  vdegree<-degree(graph, v =vdegree)
  vdegree<-as.data.frame(vdegree)
  vdegree$finalID<-rownames(vdegree)
  vdegree$lyear<-linkyear
  vdegree$yfinalID<-paste0(linkyear,vdegree$finalID)
  # fwrite(vdegree, paste0("/home/rstudio/output/graphs/degree/d",sample,sector, "_", inityear,"-",endyear, "_list", ".csv"))
  vdegree<-as.data.table(vdegree)
  
  setkey(edges_reg,finalID_)
  setkey(vdegree,finalID)
  edges_reg<-edges_reg[vdegree, nomatch=0]
  # Test the other side
  setkey(edges_reg,finalID__)
  edges_reg<-edges_reg[vdegree, nomatch=0]
  
  datalist<-apply(edges_reg, 1, FUN=function(x){
    x<-as.data.frame(t(x))
    dline<-distances(graph, v=V(graph)[V(graph)$name  %in% x$finalID_],
                     to=V(graph)[V(graph)$name %in% x$finalID__], weights = NULL)
    dline<-melt(dline)
    dline
  })

  big_data <- data.table::rbindlist(datalist)
  big_data<-big_data[big_data$value!=0 & big_data$value!="Inf",]
  big_data$year<-linkyear
  print("Distances have been computed")
  gc()
  fwrite(big_data, paste0("/home/rstudio/output/graphs/distance_list/",sample,sector, "_", inityear,"-",endyear, "_list", ".csv"))
  
  if(withplot==TRUE){
    graph.l<-layout_with_drl(graph, options=list(simmer.attraction=0))
    print("Layout has been done")
    pdf(paste0("/home/rstudio/output/graphs/images/",inityear,"-",endyear, "_plot", ".pdf"))
    plot(graph, layout=graph.l, vertex.label=NA, vertex.frame.color=NA, vertex.size=0.7, edge.width=0.4)
    dev.off()
    print("Plot has been done")
  }
  gc()
  return("done")
}
