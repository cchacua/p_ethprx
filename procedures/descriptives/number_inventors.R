# Load MySQL connector
source("~/christian/conf/connection.R")


#######################################################################################
# Celtic vs all other ethnicities By field
#######################################################################################
# Only inventors who have filed collaborative patents and all the team is located in the US.
# I am chosing the highest probability to classify an inventor in a particular ethnic group 
# Here I am counting single patent inventors as well
inventors<-dbGetQuery(christian2019,
                      "SELECT 'Celtic English' AS 'CEL Group', 
COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN c.inv_fid END)) AS CTT,
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN c.inv_fid END)) AS PBOC
                      FROM pethprx.t51_edir a
                      INNER JOIN pethprx.t01_samples b
                      ON b.inv_all_us=1 AND b.eth_comp=1  AND a.pat_id=b.pat_id
                      INNER JOIN pethprx.t30_inv_name c
                      ON a.inv_fid=c.inv_fid
                      WHERE c.celgr_id_max=34
                      UNION
                      SELECT 'Foreign ethnic groups' AS 'CEL Group', 
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN c.inv_fid END)) AS CTT,
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN c.inv_fid END)) AS PBOC
                      FROM pethprx.t51_edir a
                      INNER JOIN pethprx.t01_samples b
                      ON b.inv_all_us=1 AND b.eth_comp=1  AND a.pat_id=b.pat_id
                      INNER JOIN pethprx.t30_inv_name c
                      ON a.inv_fid=c.inv_fid
                      WHERE c.celgr_id_max!=34
                      UNION
                      SELECT 'Total' AS 'CEL Group', 
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN c.inv_fid END)) AS CTT,
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN c.inv_fid END)) AS PBOC
                      FROM pethprx.t51_edir a
                      INNER JOIN pethprx.t01_samples b
                      ON b.inv_all_us=1 AND b.eth_comp=1  AND a.pat_id=b.pat_id
                      INNER JOIN pethprx.t30_inv_name c
                      ON a.inv_fid=c.inv_fid;")

stargazer::stargazer(inventors, summary=FALSE, rownames=FALSE)

#######################################################################################
# Celtic vs all other ethnicities By field, more than one patent
#######################################################################################
# Only inventors who have filed collaborative patents and all the team is located in the US.
# I am chosing the highest probability to classify an inventor in a particular ethnic group 
# Here I am NOT counting single patent inventors
inventors<-dbGetQuery(christian2019,
                      "SELECT 'Celtic English' AS 'CEL Group', 
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN c.inv_fid END)) AS CTT,
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN c.inv_fid END)) AS PBOC
                      FROM pethprx.t51_edir a
                      INNER JOIN pethprx.t01_samples b
                      ON b.inv_all_us=1 AND b.eth_comp=1  AND a.pat_id=b.pat_id
                      INNER JOIN pethprx.t30_inv_name c
                      ON a.inv_fid=c.inv_fid
                      WHERE c.celgr_id_max=34 AND (c.pat_np>1 OR c.pat_nc>1)
                      UNION
                      SELECT 'Foreign ethnic groups' AS 'CEL Group', 
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN c.inv_fid END)) AS CTT,
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN c.inv_fid END)) AS PBOC
                      FROM pethprx.t51_edir a
                      INNER JOIN pethprx.t01_samples b
                      ON b.inv_all_us=1 AND b.eth_comp=1  AND a.pat_id=b.pat_id
                      INNER JOIN pethprx.t30_inv_name c
                      ON a.inv_fid=c.inv_fid
                      WHERE c.celgr_id_max!=34 AND (c.pat_np>1 OR c.pat_nc>1)
                      UNION
                      SELECT 'Total' AS 'CEL Group', 
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN c.inv_fid END)) AS CTT,
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN c.inv_fid END)) AS PBOC
                      FROM pethprx.t51_edir a
                      INNER JOIN pethprx.t01_samples b
                      ON b.inv_all_us=1 AND b.eth_comp=1  AND a.pat_id=b.pat_id
                      INNER JOIN pethprx.t30_inv_name c
                      ON a.inv_fid=c.inv_fid
                      WHERE c.pat_np>1 OR c.pat_nc>1;")

stargazer::stargazer(inventors, summary=FALSE, rownames=FALSE)


#######################################################################################
# Distribution of 12 ethnic groups by field, more than one patent
#######################################################################################
# Only inventors who have filed collaborative patents and all the team is located in the US.
# I am chosing the highest probability to classify an inventor in a particular ethnic group 
# Here I am not counting single patent inventors
inventors<-dbGetQuery(christian2019,
                      "SELECT d.label AS 'CEL Group', 
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN c.inv_fid END)) AS CTT,
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN c.inv_fid END)) AS PBOC
                      FROM pethprx.t51_edir a
                      INNER JOIN pethprx.t01_samples b
                      ON b.inv_all_us=1 AND b.eth_comp=1  AND a.pat_id=b.pat_id
                      INNER JOIN pethprx.t30_inv_name c
                      ON a.inv_fid=c.inv_fid
                      INNER JOIN pethprx.t39_celgr d
                      ON c.celgr_id_max=d.id
                      WHERE c.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39) AND (c.pat_np>1 OR c.pat_nc>1)
                      GROUP BY c.celgr_id_max
                      UNION
                      SELECT 'Other foreign ethnic groups' AS 'CEL Group', 
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN c.inv_fid END)) AS CTT,
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN c.inv_fid END)) AS PBOC
                      FROM pethprx.t51_edir a
                      INNER JOIN pethprx.t01_samples b
                      ON b.inv_all_us=1 AND b.eth_comp=1  AND a.pat_id=b.pat_id
                      INNER JOIN pethprx.t30_inv_name c
                      ON a.inv_fid=c.inv_fid
                      WHERE c.celgr_id_max NOT IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39, 34) AND (c.pat_np>1 OR c.pat_nc>1)
                      UNION
                      SELECT 'Total' AS 'CEL Group', 
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN c.inv_fid END)) AS CTT,
                      COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN c.inv_fid END)) AS PBOC
                      FROM pethprx.t51_edir a
                      INNER JOIN pethprx.t01_samples b
                      ON b.inv_all_us=1 AND b.eth_comp=1  AND a.pat_id=b.pat_id
                      INNER JOIN pethprx.t30_inv_name c
                      ON a.inv_fid=c.inv_fid
                      WHERE c.celgr_id_max!=34 AND (c.pat_np>1 OR c.pat_nc>1);")

inventors2<-inventors[order(inventors$CTT, decreasing = TRUE),]
inventors2$CTT<-inventors2$CTT/81146*100
inventors2$PBOC<-inventors2$PBOC/68236*100
sum(inventors2$CTT)
sum(inventors2$PBOC)

stargazer::stargazer(inventors2, summary=FALSE, rownames=FALSE, digits=2)



s3<-dbGetQuery(christian2019,
                      "SELECT * FROM pethprx.t73_s3c  ;")
s3_row<-s3[s3$id %in% c(2354,
            12490,
            2409,
            12545,
            2410,
            12546), c("linked", "inv_fid", "inv_fid_", "EARLIEST_FILING_YEAR", "ethnic", "socialdist", "same_appl")]
stargazer::stargazer(s3_row, summary=FALSE, rownames=FALSE, digits=2)

write.csv(s3, paste0("../output/s3.csv"))
# formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + insprox + techprox + same_appl"  

formula<-"linked ~ ethnic + soc_2 + soc_3 + soc_4 + av_cent + absdif_cent + geodis + same_appl"  
s3_ctt<-lm(formula, data = s3)
summary(s3_ctt)

stargazer::stargazer(s3, summary=TRUE)
summary(s3)
