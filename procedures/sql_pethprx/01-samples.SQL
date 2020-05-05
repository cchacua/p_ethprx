CREATE DATABASE pethprx;
GRANT ALL PRIVILEGES ON pethprx.* TO 'christian';	

---------------------------------------------------------------------------------------------------
-- LOAD TABLE WITH POINTS INSIDE THE US
---------------------------------------------------------------------------------------------------
-- ATTENTION: THIS TABLE CAN BE CHANGED AFTER COMPUTING THE COUNTRY FOR THE WHOLE DATABASE. The main goal is to reduce all of this to a WHERE country='US' condition
-- Here we know from a previous excercise that all these points belong to the relevant categories, and that isin is always true
-- ATTENTION: USE loc AS KEY INSTEAD OF lat, lon WHEN MAKING JOINS, AS lat, lon are double approximations
DROP TABLE IF EXISTS pethprx.pointsinus;
CREATE TABLE IF NOT EXISTS pethprx.pointsinus
(
nrow INT,
nrowd INT,
loc varchar(50),
lat DOUBLE,
lon DOUBLE,
isin varchar(5)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;


LOAD DATA LOCAL INFILE '/mnt/hdd2/repositories/christian/p_ethprx/input/points.output.usa.csv' INTO TABLE pethprx.pointsinus
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'  ESCAPED BY ''
lines terminated by '\n'
IGNORE 1 LINES ;
SHOW WARNINGS;
/*
Query OK, 301751 rows affected (1,94 sec)
Records: 301751  Deleted: 0  Skipped: 0  Warnings: 0
*/

ALTER TABLE pethprx.pointsinus ADD INDEX(loc);
ALTER TABLE pethprx.pointsinus DROP nrow, DROP nrowd, DROP isin;

SELECT DISTINCT isin FROM pethprx.pointsinus LIMIT 0,10;
SELECT COUNT(DISTINCT lat,lon) FROM pethprx.pointsinus;
SELECT * FROM pethprx.pointsinus LIMIT 0,10;

SHOW INDEX FROM pethprx.pointsinus; 
SHOW INDEX FROM riccaboni2017.t20_addr; 
DROP TABLE IF EXISTS pethprx.t20_addr_us;
CREATE TABLE IF NOT EXISTS pethprx.t20_addr_us AS
SELECT DISTINCT a.id AS addr_id FROM riccaboni2017.t20_addr a INNER JOIN pethprx.pointsinus b ON a.loc=b.loc;
/*
Query OK, 301751 rows affected (15,11 sec)
Records: 301751  Duplicates: 0  Warnings: 0
*/

ALTER TABLE pethprx.t20_addr_us ADD INDEX(addr_id);
SELECT * FROM pethprx.t20_addr_us LIMIT 0,10;

DROP TABLE IF EXISTS pethprx.pointsinus;

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Main table for sample at the patent level
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
/*
-- ATTENTION: 
APPLN_ID: Here I am only keeping the appln_ids of round 1 of matches from t01_APPLNID
field: c:CTT, p:PBOC, i:intersection CTT and PBOC (to add in both cases)
Time span: Only between 1975 and 2010
inv_par_us: Partial US-located team (at least one inventor in a pat_id has a US address) according to riccaboni's database
inv_all_us: Full US-located team (all the inventors in a pat_id have US addresses) according to riccaboni's database

TO DO: 
- TO REPLACE IN THE FUTURE t20_addr_us by t20_addr AND WHERE CONDITION, when reverse geocoding is completed
- Double check addresses-countries with Patstat (specially when multiple addresses for a single inventor-patent pair)
- Here I am computing inv_par_us and inv_all_us before choosing a single address for an inventor-patent pair. I may redo this choosing one, but in principle my results should be more robust now. 
- Use t01 as t08, but then addresses should be assigned to the ids, which may not improve the accuracy of the sample at the end


-- CLASSES
0 - Pharmaceuticals, biotechnology and organic fine chemistry
| Pharmaceuticals                         | 4  |
| Biotechnology                           | 9  |
| Organic fine chemistry                  | 3  |
1 - Computer technology and telecommunications
| Computer technology                     | 13 |
| Telecommunications                      | 29 |
*/

DROP TABLE IF EXISTS pethprx.t01_samples;
CREATE TABLE pethprx.t01_samples (
id SERIAL,
pat_id BIGINT UNSIGNED,
APPLN_ID INT(10) UNSIGNED,
field CHAR(1),
EARLIEST_FILING_YEAR INT(4) UNSIGNED,
inv_par_us BOOLEAN,
inv_all_us BOOLEAN);
ALTER TABLE pethprx.t01_samples ADD INDEX(pat_id);
ALTER TABLE pethprx.t01_samples ADD INDEX(APPLN_ID);
ALTER TABLE pethprx.t01_samples ADD INDEX(EARLIEST_FILING_YEAR);

--------------------------
-- APPLNID and EARLIEST_FILING_YEAR
INSERT INTO pethprx.t01_samples(pat_id, APPLN_ID, EARLIEST_FILING_YEAR) 
SELECT DISTINCT a.pat_id, b.APPLN_ID, c.EARLIEST_FILING_YEAR
FROM riccaboni2017.t01 a 
INNER JOIN riccaboni2017.t01_APPLNID b
ON a.pat_id=b.pat_id
INNER JOIN patstat2018b.TLS201_APPLN c
ON b.APPLN_ID=c.APPLN_ID
WHERE b.mround=1 AND CONCAT(',', a.classes, ',') REGEXP ',4,|,9,|,3,|,13,|,29,' AND c.EARLIEST_FILING_YEAR>=1975 AND c.EARLIEST_FILING_YEAR<=2012 AND b.APPLN_ID<900000000;
/*
Query OK, 2375028 rows affected (2 min 20,51 sec)
Records: 2375028  Duplicates: 0  Warnings: 0
*/

--------------------------
-- field
UPDATE pethprx.t01_samples a INNER JOIN riccaboni2017.t01 b
	ON a.pat_id = b.pat_id
	SET a.field='p'
	WHERE CONCAT(',', b.classes, ',') REGEXP ',4,|,9,|,3,';
/*
Query OK, 1138976 rows affected (53,53 sec)
Rows matched: 1138976  Changed: 1138976  Warnings: 0
*/

UPDATE pethprx.t01_samples a INNER JOIN riccaboni2017.t01 b
	ON a.pat_id = b.pat_id
	SET a.field='i'
	WHERE CONCAT(',', b.classes, ',') REGEXP ',13,|,29,' AND a.field IS NOT NULL;
/*
Query OK, 6332 rows affected (9,58 sec)
Rows matched: 6332  Changed: 6332  Warnings: 0
*/

UPDATE pethprx.t01_samples a INNER JOIN riccaboni2017.t01 b
	ON a.pat_id = b.pat_id
	SET a.field='c'
	WHERE CONCAT(',', b.classes, ',') REGEXP ',13,|,29,' AND a.field IS NULL;
/*
Query OK, 1236052 rows affected (1 min 6,80 sec)
Rows matched: 1236052  Changed: 1236052  Warnings: 0
*/

--------------------------
-- inv_par_us
UPDATE pethprx.t01_samples a 
	INNER JOIN riccaboni2017.t08 b
	ON a.pat_id = b.pat_id
	INNER JOIN pethprx.t20_addr_us c
	ON b.addr_id=c.addr_id 
	SET a.inv_par_us=1;
/*
Query OK, 1126107 rows affected (2 min 48,70 sec)
Rows matched: 1126107  Changed: 1126107  Warnings: 0
*/
UPDATE pethprx.t01_samples a 
	SET a.inv_par_us=0
	WHERE a.inv_par_us IS NULL;
/*
Query OK, 1248921 rows affected (1 min 35,63 sec)
Rows matched: 1248921  Changed: 1248921  Warnings: 0
*/

--------------------------
-- inv_all_us
UPDATE pethprx.t01_samples a 
	INNER JOIN riccaboni2017.t08 b
	ON a.pat_id = b.pat_id
	LEFT JOIN pethprx.t20_addr_us c
	ON b.addr_id=c.addr_id 
	SET a.inv_all_us=0
	WHERE a.inv_par_us=1 and c.addr_id IS NULL;
/*
Query OK, 123904 rows affected (35,70 sec)
Rows matched: 123904  Changed: 123904  Warnings: 0
*/

UPDATE pethprx.t01_samples a 
	SET a.inv_all_us=1
	WHERE a.inv_all_us IS NULL AND a.inv_par_us=1 ;
/*
Query OK, 1002203 rows affected (23,58 sec)
Rows matched: 1002203  Changed: 1002203  Warnings: 0
*/

UPDATE pethprx.t01_samples a 
	SET a.inv_all_us=0
	WHERE a.inv_all_us IS NULL AND a.inv_par_us=0;
/*
Query OK, 1248921 rows affected (25,95 sec)
Rows matched: 1248921  Changed: 1248921  Warnings: 0
*/

--------------------------

SELECT COUNT(DISTINCT pat_id), inv_all_us FROM pethprx.t01_samples GROUP BY inv_all_us;
SELECT * FROM pethprx.t01_samples WHERE inv_par_us=1 LIMIT 0,10;

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Info on nationalities t3#
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
/*
-- TO RUN AFTER ../Nationality/01-prepare_nationalities_file.R
It requires the following files inside the folder output:
celgroups.csv           
finalid_cel_prob.csv    
finalid_nameinfo.csv    
*/

--------------------------
-- t39_celgr taxonomy
DROP TABLE IF EXISTS pethprx.t39_celgr;
CREATE TABLE pethprx.t39_celgr (
id INT UNSIGNED PRIMARY KEY,
celgr_text VARCHAR(100)
);

LOAD DATA LOCAL INFILE '/mnt/hdd2/repositories/christian/p_ethprx/output/celgroups.csv' INTO TABLE pethprx.t39_celgr
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'  ESCAPED BY ''
lines terminated by '\n'
IGNORE 1 LINES ;
SHOW WARNINGS;

SELECT * FROM pethprx.t39_celgr LIMIT 10;

--------------------------
-- t31_inv_cel
DROP TABLE IF EXISTS pethprx.t31_inv_cel;
CREATE TABLE pethprx.t31_inv_cel (
finalid VARCHAR(15),
celgr_id VARCHAR(3),
prob DOUBLE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;
ALTER TABLE pethprx.t31_inv_cel ADD INDEX(finalid);

LOAD DATA LOCAL INFILE '/mnt/hdd2/repositories/christian/p_ethprx/output/finalid_cel_prob.csv' INTO TABLE pethprx.t31_inv_cel 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'  ESCAPED BY ''
lines terminated by '\n'
IGNORE 1 LINES;
SHOW WARNINGS;
/*
Query OK, 26084097 rows affected (1 min 52,42 sec)
Records: 26084097  Deleted: 0  Skipped: 0  Warnings: 0
*/

ALTER TABLE pethprx.t31_inv_cel ADD COLUMN id SERIAL FIRST, ADD COLUMN inv_fid BIGINT UNSIGNED AFTER finalid;

UPDATE pethprx.t31_inv_cel a 
	SET a.celgr_id=SUBSTRING(a.celgr_id, 2); 
ALTER TABLE pethprx.t31_inv_cel MODIFY celgr_id INT UNSIGNED;
ALTER TABLE pethprx.t31_inv_cel ADD INDEX(celgr_id);

UPDATE pethprx.t31_inv_cel a INNER JOIN riccaboni2017.t09_inv b 
	ON a.finalid=b.finalid
	SET a.inv_fid=b.fid;
/*
Query OK, 26084097 rows affected (17 min 8,56 sec)
Rows matched: 26084097  Changed: 26084097  Warnings: 0
*/

SELECT * FROM pethprx.t31_inv_cel WHERE prob>0.5 LIMIT 10;
SELECT COUNT(a.finalid) FROM (SELECT b.finalid, SUM(b.prob) FROM pethprx.t31_inv_cel b GROUP BY b.finalid HAVING SUM(b.prob)>1) a;
/*
+------------------+
| COUNT(a.finalid) |
+------------------+
|           120603 |
+------------------+
1 row in set (1 min 23,99 sec)
*/
SELECT COUNT(a.finalid) FROM (SELECT b.finalid, SUM(b.prob) FROM pethprx.t31_inv_cel b GROUP BY b.finalid HAVING SUM(b.prob)>1.1) a;
--------------------------
-- t30_inv_name

DROP TABLE IF EXISTS pethprx.t30_inv_name;
CREATE TABLE pethprx.t30_inv_name (
finalid VARCHAR(15),
fname VARCHAR(100),
name VARCHAR(255)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;

ALTER TABLE pethprx.t30_inv_name ADD INDEX(finalid);
LOAD DATA LOCAL INFILE '/mnt/hdd2/repositories/christian/p_ethprx/output/finalid_nameinfo.csv' INTO TABLE pethprx.t30_inv_name 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'  ESCAPED BY ''
lines terminated by '\n'
IGNORE 1 LINES;
SHOW WARNINGS;
/*
Query OK, 668823 rows affected (8,89 sec)
Records: 668823  Deleted: 0  Skipped: 0  Warnings: 0
*/

ALTER TABLE pethprx.t30_inv_name ADD COLUMN id SERIAL FIRST, ADD COLUMN inv_fid BIGINT UNSIGNED AFTER finalid;

UPDATE pethprx.t30_inv_name a INNER JOIN riccaboni2017.t09_inv b 
	ON a.finalid=b.finalid
	SET a.inv_fid=b.fid;
/*
Query OK, 668823 rows affected (25,49 sec)
Rows matched: 668823  Changed: 668823  Warnings: 0
*/


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Networks t5# 
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
/*
-- Only for the patents
*/

SHOW INDEX FROM pethprx.t01_samples;
SHOW INDEX FROM riccaboni2017.t08;
SHOW INDEX FROM riccaboni2017.t08_inv;

--------------------------
-- List of final inventor ids (fid_id, after using the mobility links) and patents pat_id
-- All patents in the studied classes, not at least one or full (to select later when linking with pat)
DROP TABLE IF EXISTS pethprx.t50_id_pat;
CREATE TABLE  pethprx.t50_id_pat AS
SELECT DISTINCT c.inv_fid, a.pat_id
	FROM pethprx.t01_samples a
	INNER JOIN riccaboni2017.t08 b
	ON a.pat_id=b.pat_id
	INNER JOIN riccaboni2017.t08_inv c
	ON b.inv_id=c.id;
/*
Query OK, 6787539 rows affected (1 min 35,38 sec)
Records: 6787539  Duplicates: 0  Warnings: 0
*/

ALTER TABLE pethprx.t50_id_pat ADD INDEX(inv_fid);
ALTER TABLE pethprx.t50_id_pat ADD INDEX(pat_id);
SHOW INDEX FROM pethprx.t50_id_pat;                                     


SELECT * FROM pethprx.t50_id_pat LIMIT 0,10;
-- To count number of inventor-patent pairs when at least one member of a team is in the US
SELECT COUNT(*) FROM pethprx.t50_id_pat a INNER JOIN pethprx.t01_samples b ON a.pat_id=b.pat_id WHERE b.inv_par_us=1;
/*
+----------+
| COUNT(*) |
+----------+
|  3225641 |
+----------+
1 row in set (6,16 sec)
*/

--------------------------
--List of directed links at the patent level
/*
-- This table can be used to create networks:
- by field or collapsing by year, when joined with t01_samples
- selecting ethnic focal inventors, when joined with table (TO CREATE WITH DIFFERENT DEFINITIONS OF ETHNIC INVENTORS)
- CREATE COLUMN IN t01_samples tagging patents when there is at least one ethnic inventor
*/

DROP TABLE IF EXISTS pethprx.t51_edir;
CREATE TABLE pethprx.t51_edir AS
SELECT DISTINCT a.inv_fid, b.inv_fid AS inv_fid_, a.pat_id
      FROM pethprx.t50_id_pat a
      INNER JOIN pethprx.t50_id_pat b
      ON a.pat_id=b.pat_id
      WHERE a.inv_fid!=b.inv_fid;
/*
WHERE a.ID!=b.ID IS TO AVOID LINKS TO THEMSELVES
Query OK, 23129974 rows affected (3 min 40,01 sec)
Records: 23129974  Duplicates: 0  Warnings: 0
*/

SHOW INDEX FROM pethprx.t51_edir;                                     
ALTER TABLE pethprx.t51_edir ADD INDEX(pat_id);
ALTER TABLE pethprx.t51_edir ADD INDEX(inv_fid);
ALTER TABLE pethprx.t51_edir ADD INDEX(inv_fid_);

SELECT * FROM pethprx.t51_edir LIMIT 0,30;





-- Main table for the link inventor patent or year
-- At the level of final ID
-- One address per link
-

-- inv_fid->t08 to get pat_id ->t01_sample-to get pat_id and years (on both conditions) -> with that patent list: comparisons
-- Counterfactual for everysingle node no matter if they are ethnic?
---------------------------------------------------------------------------------------------------


