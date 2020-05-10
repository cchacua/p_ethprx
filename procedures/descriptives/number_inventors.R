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
                      SELECT 'Other ethnicities' AS 'CEL Group', 
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
# Here I am not counting single patent inventors as well
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
                      SELECT 'Other ethnicities' AS 'CEL Group', 
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
