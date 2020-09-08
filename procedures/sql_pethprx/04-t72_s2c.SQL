--------------------------
-- t72_s2c Sample 2, PBOC ready to run regressions 
/*
Attention: Here the relevant variable is collaborations
*/
DROP TABLE IF EXISTS pethprx.t72_s2c;
CREATE TABLE pethprx.t72_s2c AS 
SELECT DISTINCT 1 AS linked, b.eudir_id, NULL AS eudir_id_cc, c.inv_fid, c.inv_fid_, c.EARLIEST_FILING_YEAR
FROM pethprx.t62_s2 a
INNER JOIN pethprx.t53_sample  b
ON a.sample_id=b.id
INNER JOIN pethprx.t55_invyear d
ON d.tyr_c>0 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
INNER JOIN  pethprx.t52_eudir c
ON b.eudir_id=c.id
UNION
SELECT DISTINCT 0 AS linked, c.id AS eudir_id, b.eudir_id AS eudir_id_cc, c.inv_fid, c.inv_fid_, c.EARLIEST_FILING_YEAR 
FROM pethprx.t62_s2 a
INNER JOIN pethprx.t53_sample  b
ON a.sample_id=b.id
INNER JOIN pethprx.t55_invyear d
ON d.tyr_c>0 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR
INNER JOIN  pethprx.t52_eudir c
ON a.eudir_id=c.id;
/*
Query OK, 160988 rows affected (54.97 sec)
Records: 160988  Duplicates: 0  Warnings: 0
*/
ALTER TABLE pethprx.t72_s2c ADD INDEX(eudir_id);
ALTER TABLE pethprx.t72_s2c ADD INDEX(eudir_id_cc);
ALTER TABLE pethprx.t72_s2c ADD INDEX(inv_fid);
ALTER TABLE pethprx.t72_s2c ADD INDEX(inv_fid_);
ALTER TABLE pethprx.t72_s2c ADD INDEX(EARLIEST_FILING_YEAR);

ALTER TABLE pethprx.t72_s2c
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
UPDATE pethprx.t72_s2c a
	INNER JOIN pethprx.t55_invyear b
	ON a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	INNER JOIN riccaboni2017.t20_addr f
	ON b.addr_id=f.id
	INNER JOIN pethprx.t55_invyear c
	ON a.inv_fid_=c.inv_fid AND a.EARLIEST_FILING_YEAR=c.EARLIEST_FILING_YEAR
	INNER JOIN riccaboni2017.t20_addr g
	ON c.addr_id=g.id
	SET a.av_cent=((b.dg_c+c.dg_c)/2), a.absdif_cent=ABS(CAST(b.dg_c AS SIGNED)-CAST(c.dg_c AS SIGNED)), a.geodis=ST_Distance(f.geom, g.geom);
/*
Query OK, 160988 rows affected (2 min 48.42 sec)
Rows matched: 160988  Changed: 160988  Warnings: 0
*/

-- Ethnic
UPDATE pethprx.t72_s2c a
SET a.ethnic=NULL;

UPDATE pethprx.t72_s2c a
	INNER JOIN pethprx.t30_inv_name b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t30_inv_name c
	ON a.inv_fid_=c.inv_fid
SET a.ethnic=1
WHERE b.celgr_id_max=c.celgr_id_max AND b.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 14842 rows affected (35.67 sec)
Rows matched: 14842  Changed: 14842  Warnings: 0
*/

UPDATE pethprx.t72_s2c a
	INNER JOIN pethprx.t30_inv_name b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t30_inv_name c
	ON a.inv_fid_=c.inv_fid
SET a.ethnic=0
WHERE b.celgr_id_max!=c.celgr_id_max;
/*
Query OK, 146146 rows affected (5.80 sec)
Rows matched: 146146  Changed: 146146  Warnings: 0
*/

-- Technological
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2c
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2c
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
UPDATE pethprx.t72_s2c x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.ipc7_id=z.ipc7_id
SET x.techprox=1;
/*
Query OK, 106590 rows affected (4 min 46.80 sec)
Rows matched: 106590  Changed: 106590  Warnings: 0
*/

UPDATE pethprx.t72_s2c x
SET x.techprox=0
WHERE x.techprox IS NULL;
/*
Query OK, 54398 rows affected (2.85 sec)
Rows matched: 54398  Changed: 54398  Warnings: 0
*/

-- Same applicant
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2c
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t72_s2c
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
UPDATE pethprx.t72_s2c x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.app_id=z.app_id
SET x.same_appl=1;
/*
Query OK, 62107 rows affected (4 min 45.30 sec)
Rows matched: 62107  Changed: 62107  Warnings: 0
*/

UPDATE pethprx.t72_s2c x
SET x.same_appl=0
WHERE x.same_appl IS NULL;
/*
Query OK, 98881 rows affected (9.30 sec)
Rows matched: 98881  Changed: 98881  Warnings: 0
*/
