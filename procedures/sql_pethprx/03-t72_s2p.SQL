SHOW VARIABLES LIKE "local_infile";
SET GLOBAL local_infile = 'ON';
SET UNIQUE_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_LOG_BIN=0;

--------------------------
-- t72_s2p Sample 2, PBOC ready to run regressions 
/*
Attention: Here the relevant variable is collaborations
*/
DROP TABLE IF EXISTS pethprx.t72_s2p;
CREATE TABLE pethprx.t72_s2p AS 
SELECT DISTINCT 1 AS linked, b.eudir_id, NULL AS eudir_id_cc, c.inv_fid, c.inv_fid_, c.EARLIEST_FILING_YEAR
FROM pethprx.t62_s2 a
INNER JOIN pethprx.t53_sample  b
ON a.sample_id=b.id
INNER JOIN pethprx.t55_invyear d
ON d.tyr_p>0 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
INNER JOIN  pethprx.t52_eudir c
ON b.eudir_id=c.id
UNION
SELECT DISTINCT 0 AS linked, c.id AS eudir_id, b.eudir_id AS eudir_id_cc, c.inv_fid, c.inv_fid_, c.EARLIEST_FILING_YEAR 
FROM pethprx.t62_s2 a
INNER JOIN pethprx.t53_sample  b
ON a.sample_id=b.id
INNER JOIN pethprx.t55_invyear d
ON d.tyr_p>0 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR
INNER JOIN  pethprx.t52_eudir c
ON a.eudir_id=c.id;
/*
Query OK, 222025 rows affected (1 min 38.16 sec)
Records: 222025  Duplicates: 0  Warnings: 0
*/
ALTER TABLE pethprx.t72_s2p ADD INDEX(eudir_id);
ALTER TABLE pethprx.t72_s2p ADD INDEX(eudir_id_cc);
ALTER TABLE pethprx.t72_s2p ADD INDEX(inv_fid);
ALTER TABLE pethprx.t72_s2p ADD INDEX(inv_fid_);
ALTER TABLE pethprx.t72_s2p ADD INDEX(EARLIEST_FILING_YEAR);

ALTER TABLE pethprx.t72_s2p
	ADD COLUMN id SERIAL FIRST,
	ADD COLUMN ethnic BOOL, 
	ADD COLUMN socialdist INT,
	ADD COLUMN av_cent FLOAT,
	ADD COLUMN absdif_cent INT,
	ADD COLUMN geodis FLOAT,
	ADD COLUMN insprox BOOL,
	ADD COLUMN techprox BOOL,
	ADD COLUMN same_appl BOOL,
	ADD COLUMN same_msa BOOL;

-- av_cent, absdif_cent, geodis
UPDATE pethprx.t72_s2p a
	INNER JOIN pethprx.t55_invyear b
	ON a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	INNER JOIN riccaboni2017.t20_addr f
	ON b.addr_id=f.id
	INNER JOIN pethprx.t55_invyear c
	ON a.inv_fid_=c.inv_fid AND a.EARLIEST_FILING_YEAR=c.EARLIEST_FILING_YEAR
	INNER JOIN riccaboni2017.t20_addr g
	ON c.addr_id=g.id
	SET a.av_cent=((b.dg_p+c.dg_p)/2), a.absdif_cent=ABS(CAST(b.dg_p AS SIGNED)-CAST(c.dg_p AS SIGNED)), a.geodis=ST_Distance(f.geom, g.geom);
/*
Query OK, 222025 rows affected (2 min 39.01 sec)
Rows matched: 222025  Changed: 222025  Warnings: 0

UPDATE pethprx.t72_s2p a
SET a.av_cent=0, a.absdif_cent=0;

UPDATE pethprx.t72_s2p a
	INNER JOIN pethprx.t55_invyear b
	ON a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	INNER JOIN pethprx.t55_invyear c
	ON a.inv_fid_=c.inv_fid AND a.EARLIEST_FILING_YEAR=c.EARLIEST_FILING_YEAR
	SET a.av_cent=((b.dg_p+c.dg_p)/2), a.absdif_cent=ABS(CAST(b.dg_p AS SIGNED)-CAST(c.dg_p AS SIGNED));

Query OK, 221953 rows affected (10.57 sec)
Rows matched: 222025  Changed: 221953  Warnings: 0

*/

-- Ethnic
UPDATE pethprx.t72_s2p a
SET a.ethnic=NULL;

UPDATE pethprx.t72_s2p a
	INNER JOIN pethprx.t30_inv_name b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t30_inv_name c
	ON a.inv_fid_=c.inv_fid
SET a.ethnic=1
WHERE b.celgr_id_max=c.celgr_id_max AND b.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 19184 rows affected (2.72 sec)
Rows matched: 19184  Changed: 19184  Warnings: 0
*/

UPDATE pethprx.t72_s2p a
	INNER JOIN pethprx.t30_inv_name b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t30_inv_name c
	ON a.inv_fid_=c.inv_fid
SET a.ethnic=0
WHERE b.celgr_id_max!=c.celgr_id_max;
/*
Query OK, 202841 rows affected (6.83 sec)
Rows matched: 202841  Changed: 202841  Warnings: 0
*/

-- Technological
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2p
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2p
	)
	SELECT DISTINCT a.inv_fid, a.EARLIEST_FILING_YEAR, d.ipc7_id
	FROM t2 a
	INNER JOIN pethprx.t50_id_pat b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t01_samples c
	ON b.pat_id=c.pat_id AND (CAST(a.EARLIEST_FILING_YEAR AS SIGNED)-CAST(c.EARLIEST_FILING_YEAR AS SIGNED)) BETWEEN 1 AND 5
	INNER JOIN pethprx.t10_samples d
	ON c.pat_id=d.pat_id
	)
UPDATE pethprx.t72_s2p x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.ipc7_id=z.ipc7_id
SET x.techprox=1;
/*
Query OK, 162273 rows affected (5 min 38.97 sec)
Rows matched: 162273  Changed: 162273  Warnings: 0
*/

UPDATE pethprx.t72_s2p x
SET x.techprox=0
WHERE x.techprox IS NULL;
/*
Query OK, 59752 rows affected (1.37 sec)
Rows matched: 59752  Changed: 59752  Warnings: 0
*/

-- Same applicant
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2p
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2p
	)
	SELECT DISTINCT a.inv_fid, a.EARLIEST_FILING_YEAR, d.app_id
	FROM t2 a
	INNER JOIN pethprx.t50_id_pat b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t01_samples c
	ON b.pat_id=c.pat_id AND (CAST(a.EARLIEST_FILING_YEAR AS SIGNED)-CAST(c.EARLIEST_FILING_YEAR AS SIGNED)) BETWEEN 1 AND 5
	INNER JOIN riccaboni2017.t07 d
	ON c.pat_id=d.pat_id
	)
UPDATE pethprx.t72_s2p x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.app_id=z.app_id
SET x.same_appl=1;
/*
Query OK, 71787 rows affected (4 min 38.86 sec)
Rows matched: 71787  Changed: 71787  Warnings: 0
*/

UPDATE pethprx.t72_s2p x
SET x.same_appl=0
WHERE x.same_appl IS NULL;
/*
Query OK, 150238 rows affected (3.04 sec)
Rows matched: 150238  Changed: 150238  Warnings: 0
*/



-- Social distance
-- https://stackoverflow.com/questions/2370876/find-path-between-nodes-with-sql
-- https://stackoverflow.com/questions/59506079/mysql-shortest-path-between-two-nodes
-- https://stackoverflow.com/questions/45933491/path-finding-via-sql-query
DROP TABLE IF EXISTS pethprx.t72_s2p_sd;
CREATE TABLE IF NOT EXISTS pethprx.t72_s2p_sd
(
inv_fid BIGINT UNSIGNED,
inv_fid_ BIGINT UNSIGNED,
socialdist INT,
EARLIEST_FILING_YEAR INT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;


LOAD DATA LOCAL INFILE '/var/lib/mysql-files/output/graphs/distance_list/t72_s2p/*.csv' INTO TABLE pethprx.t72_s2p_sd
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'  ESCAPED BY ''
lines terminated by '\n'
IGNORE 1 LINES ;
SHOW WARNINGS;
/*

*/
ALTER TABLE pethprx.t72_s2p_sd ADD INDEX(inv_fid);
ALTER TABLE pethprx.t72_s2p_sd ADD INDEX(inv_fid_);
ALTER TABLE pethprx.t72_s2p_sd ADD INDEX(EARLIEST_FILING_YEAR);




SELECT * FROM pethprx.t72_s2p_sd LIMIT 0,10;

UPDATE pethprx.t72_s2p x
	INNER JOIN pethprx.t72_s2p_sd y
	ON x.inv_fid=y.inv_fid AND x.inv_fid_=y.inv_fid_ AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
SET x.socialdist=y.socialdist;
/*
Query OK, 154793 rows affected (8.91 sec)
Rows matched: 154793  Changed: 154793  Warnings: 0
*/

UPDATE pethprx.t72_s2p x
SET x.socialdist=999 WHERE x.socialdist IS NULL;
/*
Query OK, 67232 rows affected (4.28 sec)
Rows matched: 67232  Changed: 67232  Warnings: 0
*/

ALTER TABLE pethprx.t72_s2p
	ADD COLUMN soc_2 BOOL,
	ADD COLUMN soc_3 BOOL,
	ADD COLUMN soc_4 BOOL,
	ADD COLUMN soc_5m BOOL;

UPDATE pethprx.t72_s2p x
SET x.soc_2=(CASE WHEN x.socialdist=2 THEN 1 ELSE 0 END),
    x.soc_3=(CASE WHEN x.socialdist=3 THEN 1 ELSE 0 END),
    x.soc_4=(CASE WHEN x.socialdist=4 THEN 1 ELSE 0 END),
    x.soc_5m=(CASE WHEN  x.socialdist>4 THEN 1 ELSE 0 END);
/*
Query OK, 222025 rows affected (2.90 sec)
Rows matched: 222025  Changed: 222025  Warnings: 0
*/
































-- TO DO: RE-RUN THIS, BY UPDATING THE MSA AND STATE TO INCLUDE EVERYTHING
ALTER TABLE pethprx.t72_s2p
	ADD COLUMN same_state BOOL;

-- same_msa, same_state
UPDATE pethprx.t72_s2p a
	INNER JOIN pethprx.t55_invyear b
	ON a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	INNER JOIN pethprx.t20_addr_us_msa f
	ON b.addr_id=f.addr_id
	INNER JOIN pethprx.t55_invyear c
	ON a.inv_fid_=c.inv_fid AND a.EARLIEST_FILING_YEAR=c.EARLIEST_FILING_YEAR
	INNER JOIN pethprx.t20_addr_us_msa g
	ON c.addr_id=g.addr_id
	SET a.same_msa=1
	WHERE f.msa=g.msa;
/*
Query OK, 41890 rows affected (13.56 sec)
Rows matched: 41890  Changed: 41890  Warnings: 0
*/

UPDATE pethprx.t72_s2p a
	SET a.same_msa=0
	WHERE a.same_msa IS NULL;
/*
Query OK, 180135 rows affected (3.92 sec)
Rows matched: 180135  Changed: 180135  Warnings: 0
*/

UPDATE pethprx.t72_s2p a
	INNER JOIN pethprx.t55_invyear b
	ON a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	INNER JOIN pethprx.t20_addr_us_msa f
	ON b.addr_id=f.addr_id
	INNER JOIN pethprx.t55_invyear c
	ON a.inv_fid_=c.inv_fid AND a.EARLIEST_FILING_YEAR=c.EARLIEST_FILING_YEAR
	INNER JOIN pethprx.t20_addr_us_msa g
	ON c.addr_id=g.addr_id
	SET a.same_state=1
	WHERE f.state=g.state;
/*
Query OK, 56377 rows affected (11.62 sec)
Rows matched: 56377  Changed: 56377  Warnings: 0
*/

UPDATE pethprx.t72_s2p a
	SET a.same_state=0
	WHERE a.same_state IS NULL;
/*
Query OK, 165648 rows affected (9.19 sec)
Rows matched: 165648  Changed: 165648  Warnings: 0
*/











-- This is to compute the focal inventor, but this only makes sense for s3. Here it is difficult to node which one is the focal node
ALTER TABLE pethprx.t72_s2p
	ADD COLUMN fcfinv BIGINT UNSIGNED,
	ADD COLUMN celgr_id_max_fcfinv INT UNSIGNED;


UPDATE pethprx.t72_s2p a
SET a.fcfinv=NULL;
UPDATE pethprx.t72_s2p b
	INNER JOIN pethprx.t55_invyear d
	ON d.tyr_p>0 AND b.inv_fid_=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
	INNER JOIN pethprx.t30_inv_name c
	ON b.inv_fid_=c.inv_fid
SET b.fcfinv=b.inv_fid_
WHERE c.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 15521 rows affected (4,02 sec)
Rows matched: 15521  Changed: 15521  Warnings: 0
*/
UPDATE pethprx.t72_s2p b
	INNER JOIN pethprx.t55_invyear d
	ON d.tyr_p>0 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
	INNER JOIN pethprx.t30_inv_name c
	ON b.inv_fid=c.inv_fid
SET b.fcfinv=b.inv_fid
WHERE c.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 17861 rows affected (2,17 sec)
Rows matched: 17861  Changed: 17861  Warnings: 0
*/

-- Ethnicity focal node
UPDATE pethprx.t72_s2p a
SET a.celgr_id_max_fcfinv=NULL;

UPDATE pethprx.t72_s2p a
	INNER JOIN pethprx.t30_inv_name b
	ON a.fcfinv=b.inv_fid
SET a.celgr_id_max_fcfinv=b.celgr_id_max
WHERE b.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 33006 rows affected (0,78 sec)
Rows matched: 33006  Changed: 33006  Warnings: 0
*/


-- Institutional
/*
TO DO:
Clean categories in the future
+---------------------------+----------+
| PSN_SECTOR                | COUNT(*) |
+---------------------------+----------+

*/
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2p
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2p
	)
	SELECT DISTINCT a.inv_fid, a.EARLIEST_FILING_YEAR, f.PSN_SECTOR
	FROM t2 a
	INNER JOIN pethprx.t50_id_pat b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t01_samples c
	ON b.pat_id=c.pat_id AND (CAST(a.EARLIEST_FILING_YEAR AS SIGNED)-CAST(c.EARLIEST_FILING_YEAR AS SIGNED)) BETWEEN 1 AND 5
	INNER JOIN patstat2018b.TLS201_APPLN d
	ON c.appln_id=d.appln_id
	INNER JOIN patstat2018b.TLS207_PERS_APPLN e
	ON d.appln_id=e.appln_id AND e.APPLT_SEQ_NR>0 AND e.INVT_SEQ_NR=0 
	INNER JOIN patstat2018b.TLS206_PERSON f
	ON e.PERSON_ID=f.PERSON_ID AND f.PSN_SECTOR NOT IN ('', 'UNKNOWN', 'INDIVIDUAL')
	)
UPDATE pethprx.t72_s2p x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.PSN_SECTOR=z.PSN_SECTOR
SET x.insprox=1;
/*

*/

UPDATE pethprx.t72_s2p x
SET x.insprox=0
WHERE x.insprox IS NULL;
/*

*/
