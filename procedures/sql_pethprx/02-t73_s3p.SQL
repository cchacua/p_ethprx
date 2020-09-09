
--------------------------
-- t73_s3p Sample 3, PBOC ready to run regressions 
/*
Attention: Here the relevant variable is collaborations
*/
DROP TABLE IF EXISTS pethprx.t73_s3p;
CREATE TABLE pethprx.t73_s3p AS 
SELECT DISTINCT 1 AS linked, b.eudir_id, NULL AS eudir_id_cc, c.inv_fid, c.inv_fid_, c.EARLIEST_FILING_YEAR
FROM pethprx.t63_s3 a
INNER JOIN pethprx.t53_sample  b
ON a.sample_id=b.id
INNER JOIN pethprx.t55_invyear d
ON d.tyr_p>0 AND d.pc_p_10>=0.9 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
INNER JOIN  pethprx.t52_eudir c
ON b.eudir_id=c.id
UNION
SELECT DISTINCT 0 AS linked, c.id AS eudir_id, b.eudir_id AS eudir_id_cc, c.inv_fid, c.inv_fid_, c.EARLIEST_FILING_YEAR 
FROM pethprx.t63_s3 a
INNER JOIN pethprx.t53_sample  b
ON a.sample_id=b.id
INNER JOIN pethprx.t55_invyear d
ON d.tyr_p>0 AND d.pc_p_10>=0.9 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR
INNER JOIN  pethprx.t52_eudir c
ON a.eudir_id=c.id;
/*
Query OK, 33006 rows affected (3,94 sec)
Records: 33006  Duplicates: 0  Warnings: 0
*/
ALTER TABLE pethprx.t73_s3p ADD INDEX(eudir_id);
ALTER TABLE pethprx.t73_s3p ADD INDEX(eudir_id_cc);
ALTER TABLE pethprx.t73_s3p ADD INDEX(inv_fid);
ALTER TABLE pethprx.t73_s3p ADD INDEX(inv_fid_);
ALTER TABLE pethprx.t73_s3p ADD INDEX(EARLIEST_FILING_YEAR);

ALTER TABLE pethprx.t73_s3p
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
UPDATE pethprx.t73_s3p a
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
UPDATE pethprx.t73_s3p a
SET a.av_cent=0, a.absdif_cent=0;
UPDATE pethprx.t73_s3p a
	INNER JOIN pethprx.t55_invyear b
	ON a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	INNER JOIN pethprx.t55_invyear c
	ON a.inv_fid_=c.inv_fid AND a.EARLIEST_FILING_YEAR=c.EARLIEST_FILING_YEAR
	SET a.av_cent=((b.dg_p+c.dg_p)/2), a.absdif_cent=ABS(CAST(b.dg_p AS SIGNED)-CAST(c.dg_p AS SIGNED));
Query OK, 33006 rows affected (2.70 sec)
Rows matched: 33006  Changed: 33006  Warnings: 0
*/

-- Ethnic
UPDATE pethprx.t73_s3p a
SET a.ethnic=NULL;

UPDATE pethprx.t73_s3p a
	INNER JOIN pethprx.t30_inv_name b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t30_inv_name c
	ON a.inv_fid_=c.inv_fid
SET a.ethnic=1
WHERE b.celgr_id_max=c.celgr_id_max AND b.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 3850 rows affected (1,39 sec)
Rows matched: 3850  Changed: 3850  Warnings: 0
*/

UPDATE pethprx.t73_s3p a
	INNER JOIN pethprx.t30_inv_name b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t30_inv_name c
	ON a.inv_fid_=c.inv_fid
SET a.ethnic=0
WHERE b.celgr_id_max!=c.celgr_id_max;
/*
Query OK, 29156 rows affected (1,04 sec)
Rows matched: 29156  Changed: 29156  Warnings: 0
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
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3p
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3p
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
UPDATE pethprx.t73_s3p x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.PSN_SECTOR=z.PSN_SECTOR
SET x.insprox=1;
/*
Query OK, 29753 rows affected (52,92 sec)
Rows matched: 29753  Changed: 29753  Warnings: 0
*/

UPDATE pethprx.t73_s3p x
SET x.insprox=0
WHERE x.insprox IS NULL;
/*
Query OK, 3253 rows affected (0,12 sec)
Rows matched: 3253  Changed: 3253  Warnings: 0
*/

-- Technological
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3p
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3p
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
UPDATE pethprx.t73_s3p x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.ipc7_id=z.ipc7_id
SET x.techprox=1;
/*
Query OK, 27102 rows affected (39,66 sec)
Rows matched: 27102  Changed: 27102  Warnings: 0
*/

UPDATE pethprx.t73_s3p x
SET x.techprox=0
WHERE x.techprox IS NULL;
/*
Query OK, 5904 rows affected (0,26 sec)
Rows matched: 5904  Changed: 5904  Warnings: 0
*/

-- Same applicant
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3p
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3p
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
UPDATE pethprx.t73_s3p x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.app_id=z.app_id
SET x.same_appl=1;
/*
Query OK, 12563 rows affected (21,81 sec)
Rows matched: 12563  Changed: 12563  Warnings: 0
*/

UPDATE pethprx.t73_s3p x
SET x.same_appl=0
WHERE x.same_appl IS NULL;
/*
Query OK, 20443 rows affected (1,03 sec)
Rows matched: 20443  Changed: 20443  Warnings: 0
*/


-- Social distance
-- https://stackoverflow.com/questions/2370876/find-path-between-nodes-with-sql
-- https://stackoverflow.com/questions/59506079/mysql-shortest-path-between-two-nodes
-- https://stackoverflow.com/questions/45933491/path-finding-via-sql-query
DROP TABLE IF EXISTS pethprx.t73_s3p_sd;
CREATE TABLE IF NOT EXISTS pethprx.t73_s3p_sd
(
inv_fid BIGINT UNSIGNED,
inv_fid_ BIGINT UNSIGNED,
socialdist INT,
EARLIEST_FILING_YEAR INT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE pethprx.t73_s3p_sd ADD INDEX(inv_fid);
ALTER TABLE pethprx.t73_s3p_sd ADD INDEX(inv_fid_);
ALTER TABLE pethprx.t73_s3p_sd ADD INDEX(EARLIEST_FILING_YEAR);



LOAD DATA LOCAL INFILE '/mnt/hdd2/repositories/christian/p_ethprx/output/graphs/distance_list/p/.csv' INTO TABLE pethprx.t73_s3p_sd
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'  ESCAPED BY ''
lines terminated by '\n'
IGNORE 1 LINES ;
SHOW WARNINGS;
/*

*/

SELECT * FROM pethprx.t73_s3p_sd LIMIT 0,10;

UPDATE pethprx.t73_s3p x
	INNER JOIN pethprx.t73_s3p_sd y
	ON x.inv_fid=y.inv_fid AND x.inv_fid_=y.inv_fid_ AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
SET x.socialdist=y.socialdist;
/*
Query OK, 26801 rows affected (2 min 41,11 sec)
Rows matched: 26801  Changed: 26801  Warnings: 0
*/

UPDATE pethprx.t73_s3p x
	INNER JOIN pethprx.t73_s3p_sd y
	ON x.inv_fid=y.inv_fid_ AND x.inv_fid_=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
SET x.socialdist=y.socialdist;
/*
Query OK, 0 rows affected (1 min 49,56 sec)
Rows matched: 4325  Changed: 0  Warnings: 0
*/

UPDATE pethprx.t73_s3p x
SET x.socialdist=999 WHERE x.socialdist IS NULL;
/*
Query OK, 6205 rows affected (0,26 sec)
Rows matched: 6205  Changed: 6205  Warnings: 0
*/

ALTER TABLE pethprx.t73_s3p
	ADD COLUMN soc_2 BOOL,
	ADD COLUMN soc_3 BOOL,
	ADD COLUMN soc_4 BOOL,
	ADD COLUMN soc_5m BOOL;

UPDATE pethprx.t73_s3p x
SET x.soc_2=1 WHERE x.socialdist=2;

UPDATE pethprx.t73_s3p x
SET x.soc_3=1 WHERE x.socialdist=3;

UPDATE pethprx.t73_s3p x
SET x.soc_4=1 WHERE x.socialdist=4;

UPDATE pethprx.t73_s3p x
SET x.soc_5m=1 WHERE x.socialdist>4;

UPDATE pethprx.t73_s3p x
SET x.soc_2=0 WHERE x.socialdist!=2;

UPDATE pethprx.t73_s3p x
SET x.soc_3=0 WHERE x.socialdist!=3;

UPDATE pethprx.t73_s3p x
SET x.soc_4=0 WHERE x.socialdist!=4;

UPDATE pethprx.t73_s3p x
SET x.soc_5m=0 WHERE x.socialdist<4;

/*
mysql> UPDATE pethprx.t73_s3p x
    -> SET x.soc_2=1 WHERE x.socialdist=2;
Query OK, 3623 rows affected (0,10 sec)
Rows matched: 3623  Changed: 3623  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3p x
    -> SET x.soc_3=1 WHERE x.socialdist=3;
Query OK, 1793 rows affected (0,05 sec)
Rows matched: 1793  Changed: 1793  Warnings: 0

UPDATE pethprx.t73_s3p x
SET x.soc_4=1 WHERE x.socialdist=4;
Query OK, 1229 rows affected (0,05 sec)
Rows matched: 1229  Changed: 1229  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3p x
    -> SET x.soc_5m=1 WHERE x.socialdist>4;
Query OK, 13628 rows affected (0,25 sec)
Rows matched: 13628  Changed: 13628  Warnings: 0

mysql> UPDATE pethprx.t73_s3p x
    -> SET x.soc_2=0 WHERE x.socialdist!=2;
Query OK, 16650 rows affected (0,28 sec)
Rows matched: 16650  Changed: 16650  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3p x
    -> SET x.soc_3=0 WHERE x.socialdist!=3;
Query OK, 18480 rows affected (0,32 sec)
Rows matched: 18480  Changed: 18480  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3p x
    -> SET x.soc_4=0 WHERE x.socialdist!=4;
Query OK, 19044 rows affected (0,32 sec)
Rows matched: 19044  Changed: 19044  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3p x
    -> SET x.soc_5m=0 WHERE x.socialdist<4;
Query OK, 5416 rows affected (0,12 sec)
Rows matched: 5416  Changed: 5416  Warnings: 0
*/

ALTER TABLE pethprx.t73_s3p
	ADD COLUMN fcfinv BIGINT UNSIGNED,
	ADD COLUMN celgr_id_max_fcfinv INT UNSIGNED;


UPDATE pethprx.t73_s3p a
SET a.fcfinv=NULL;
UPDATE pethprx.t73_s3p b
	INNER JOIN pethprx.t55_invyear d
	ON d.tyr_p>0 AND d.pc_p_10>=0.9 AND b.inv_fid_=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
	INNER JOIN pethprx.t30_inv_name c
	ON b.inv_fid_=c.inv_fid
SET b.fcfinv=b.inv_fid_
WHERE c.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 15521 rows affected (4,02 sec)
Rows matched: 15521  Changed: 15521  Warnings: 0
*/
UPDATE pethprx.t73_s3p b
	INNER JOIN pethprx.t55_invyear d
	ON d.tyr_p>0 AND d.pc_p_10>=0.9 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
	INNER JOIN pethprx.t30_inv_name c
	ON b.inv_fid=c.inv_fid
SET b.fcfinv=b.inv_fid
WHERE c.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 17861 rows affected (2,17 sec)
Rows matched: 17861  Changed: 17861  Warnings: 0
*/

-- Ethnicity focal node
UPDATE pethprx.t73_s3p a
SET a.celgr_id_max_fcfinv=NULL;

UPDATE pethprx.t73_s3p a
	INNER JOIN pethprx.t30_inv_name b
	ON a.fcfinv=b.inv_fid
SET a.celgr_id_max_fcfinv=b.celgr_id_max
WHERE b.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 33006 rows affected (0,78 sec)
Rows matched: 33006  Changed: 33006  Warnings: 0
*/

ALTER TABLE pethprx.t73_s3p
	ADD COLUMN same_state BOOL;

-- same_msa, same_state
UPDATE pethprx.t73_s3p a
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
Query OK, 10877 rows affected (1,81 sec)
Rows matched: 10877  Changed: 10877  Warnings: 0
*/

UPDATE pethprx.t73_s3p a
	SET a.same_msa=0
	WHERE a.same_msa IS NULL;
/*
Query OK, 22129 rows affected (0,40 sec)
Rows matched: 22129  Changed: 22129  Warnings: 0
*/

UPDATE pethprx.t73_s3p a
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
Query OK, 15141 rows affected (1,92 sec)
Rows matched: 15141  Changed: 15141  Warnings: 0
*/

UPDATE pethprx.t73_s3p a
	SET a.same_state=0
	WHERE a.same_state IS NULL;
/*
Query OK, 17865 rows affected (0,38 sec)
Rows matched: 17865  Changed: 17865  Warnings: 0
*/

