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


ugraphinv_dis_bulk<-function(endyear, withplot=FALSE, sector="c", sample="t73_s3"){
  print("Sector should be pboc or ctt")
  inityear<-endyear-4
  linkyear<-endyear+1
  print(paste("Beginning year (t-5):", inityear))
  print(paste("Ending year (t-1):", endyear))
  print(paste("Link year (t0):", linkyear))
  uedges<-as.data.table(dbGetQuery(christian2019, paste0(
    "SELECT DISTINCT CAST(a.inv_fid AS CHAR)  AS finalID_, CAST(a.inv_fid_ AS CHAR) AS finalID__
    FROM pethprx.t51_edir a
    INNER JOIN pethprx.t01_samples b
    ON a.pat_id=b.pat_id AND b.EARLIEST_FILING_YEAR>=",inityear," AND b.EARLIEST_FILING_YEAR<=",endyear," AND b.field IN ('i', '", sector, "')
    ;")))
  
  dedges<-as.data.table(dbGetQuery(christian2019, paste0("SELECT DISTINCT CAST(inv_fid AS CHAR) AS finalID_,  CAST(inv_fid_ AS CHAR) AS finalID__, id AS undid
                                                         FROM pethprx.", sample, sector, 
                                                         " WHERE EARLIEST_FILING_YEAR=",linkyear)))
  print("Data has been loaded")
  print(paste("Number of total edges",nrow(uedges)))
  print(paste("Number of edges to find",nrow(dedges), nrow(dedges)/nrow(uedges)))
  graph<-graph_from_data_frame(uedges, directed = FALSE)
  #rm(uedges)
  #save(graph, file=paste0("/home/rstudio/output/graphs/networks/",sample,sector, "_", inityear,"-",endyear, "_network", ".RData"))
  print("Graph has been done")
  
  nodesdegree<-unique(rbind(data.frame(v1=dedges$finalID_),data.frame(v1=dedges$finalID__)))
  list.vertex.attributes(graph)
  vdegree<-V(graph)[V(graph)$name %in% nodesdegree$v1]
  vdegree<-degree(graph, v =vdegree)
  vdegree<-as.data.frame(vdegree)
  vdegree$finalID<-rownames(vdegree)
  vdegree$lyear<-linkyear
  vdegree$yfinalID<-paste0(linkyear,vdegree$finalID)
  # fwrite(vdegree, paste0("/home/rstudio/output/graphs/degree/d",sample,sector, "_", inityear,"-",endyear, "_list", ".csv"))
  vdegree<-as.data.table(vdegree)
  
  setkey(dedges,finalID_)
  setkey(vdegree,finalID)
  dedges<-dedges[vdegree, nomatch=0]
  # Test the other side
  setkey(dedges,finalID__)
  dedges<-dedges[vdegree, nomatch=0]
  
  vfrom<-V(graph)[V(graph)$name  %in% dedges$finalID_]
  vto<-V(graph)[V(graph)$name %in% dedges$finalID__]
  dline<-distances(graph, v=vfrom, to=vto, weights = NULL)
  dline<-melt(dline)
  dline<-dline[dline$value!=0 & dline$value!="Inf",]
  dline$year<-linkyear
  print("Distances have been computed")
  gc()
  fwrite(dline, paste0("/home/rstudio/output/graphs/distance_list/",sample,sector, "_", inityear,"-",endyear, "_list", ".csv"))
  
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
