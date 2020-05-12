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
-- t10_samples IPC Codes inv_all_us=1
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
/*
Attention: this file is intended to be used when doing the joins required for building the counterfactual
It only covers the patents from t01_samples where all the inventors are located in the US (inv_all_us=1)
and IPC codes, that have been shortened to 7 characters maximum
*/
DROP TABLE IF EXISTS pethprx.t10_samples;
CREATE TABLE pethprx.t10_samples (
id SERIAL,
pat_id BIGINT UNSIGNED,
class VARCHAR(7),
CONSTRAINT UNIQUE (pat_id, class)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;
ALTER TABLE pethprx.t10_samples ADD INDEX(pat_id);
ALTER TABLE pethprx.t10_samples ADD INDEX(class);

INSERT INTO pethprx.t10_samples(pat_id, class) 
SELECT DISTINCT a.pat_id, LEFT(a.class, 7) 
FROM riccaboni2017.t10 a
INNER JOIN pethprx.t01_samples b
ON a.pat_id=b.pat_id
WHERE a.class_type IN ('i', 'm') AND b.inv_all_us=1;
/*
Query OK, 4076456 rows affected (5 min 1,47 sec)
Records: 4076456  Duplicates: 0  Warnings: 0
*/

--------------------------
-- t10_ipc7
DROP TABLE IF EXISTS pethprx.t10_ipc7;
CREATE TABLE pethprx.t10_ipc7 (
id SERIAL,
class VARCHAR(7),
CONSTRAINT UNIQUE(class)
)
ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;
ALTER TABLE pethprx.t10_ipc7 ADD INDEX(class);
INSERT INTO pethprx.t10_ipc7(class) 
SELECT DISTINCT a.class
FROM pethprx.t10_samples a;
/*
Query OK, 5876 rows affected (0,27 sec)
Records: 5876  Duplicates: 0  Warnings: 0
*/

ALTER TABLE pethprx.t10_samples ADD COLUMN ipc7_id BIGINT UNSIGNED AFTER class;
UPDATE pethprx.t10_samples a INNER JOIN pethprx.t10_ipc7 b 
	ON a.class=b.class
	SET a.ipc7_id=b.id;
/*
Query OK, 4076456 rows affected (2 min 22,21 sec)
Rows matched: 4076456  Changed: 4076456  Warnings: 0
*/
ALTER TABLE pethprx.t10_samples ADD INDEX(ipc7_id);

--------------------------
-- t10_ipc4
DROP TABLE IF EXISTS pethprx.t10_ipc4;
CREATE TABLE pethprx.t10_ipc4 (
id SERIAL,
class VARCHAR(4),
CONSTRAINT UNIQUE(class)
)
ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;
ALTER TABLE pethprx.t10_ipc4 ADD INDEX(class);
INSERT INTO pethprx.t10_ipc4(class) 
SELECT DISTINCT LEFT(a.class, 4)
FROM pethprx.t10_samples a;
/*
Query OK, 620 rows affected (11,00 sec)
Records: 620  Duplicates: 0  Warnings: 0
*/

ALTER TABLE pethprx.t10_samples ADD COLUMN ipc4_id BIGINT UNSIGNED AFTER class;
UPDATE pethprx.t10_samples a INNER JOIN pethprx.t10_ipc4 b 
	ON LEFT(a.class, 4)=b.class
	SET a.ipc4_id=b.id;
/*
Query OK, 4076456 rows affected (3 min 34,20 sec)
Rows matched: 4076456  Changed: 4076456  Warnings: 0
*/
ALTER TABLE pethprx.t10_samples ADD INDEX(ipc4_id);


ALTER TABLE pethprx.t10_ipc7 ADD COLUMN ipc4_id BIGINT UNSIGNED AFTER class;
UPDATE pethprx.t10_ipc7 a INNER JOIN pethprx.t10_ipc4 b 
	ON LEFT(a.class, 4)=b.class
	SET a.ipc4_id=b.id;
/*
Query OK, 5876 rows affected (0,24 sec)
Rows matched: 5876  Changed: 5876  Warnings: 0
*/

ALTER TABLE pethprx.t10_ipc7 ADD INDEX(ipc4_id);

SELECT * FROM pethprx.t10_samples LIMIT 10;

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- t3# Info on nationalities 
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
celgr_text VARCHAR(100),
label VARCHAR(100)
);

LOAD DATA LOCAL INFILE '/mnt/hdd2/repositories/christian/p_ethprx/output/celgroups.csv' INTO TABLE pethprx.t39_celgr
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'  ESCAPED BY ''
lines terminated by '\n'
IGNORE 1 LINES ;
SHOW WARNINGS;

SELECT * FROM pethprx.t39_celgr LIMIT 50;

SELECT * FROM pethprx.t39_celgr WHERE celgr_text IN('EastAsian.Chinese','SouthAsian','Muslim.Persian','EastAsian.Japan','EastAsian.South.Korea',
'European.French','European.German','European.Italian.Italy','European.EastEuropean',
'European.Russian','EastAsian.Indochina.Vietnam','EastAsian.Malay.Indonesia');

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
ALTER TABLE pethprx.t31_inv_cel ADD INDEX(inv_fid);

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
/*
id 
finalid: final inventor id
inv_fid: final inventor id (numeric)
fname: Final cleaned name used when running name prism (attention, only one per inv_fid)
name: Original name string without cleaning (attention, only one per inv_fid)
ethnic: dummy variable if ethnic inventor (minimal criteria: Max probability belongs to any of the 12 studied groups)
pat_np: Total number of PBOC patents between 1975 and 2012, no matter location (even outside the US)
pat_nc: Total number of CTT patents between 1975 and 2012, no matter location (even outside the US)

- Despite the fact that this table has more ids than the ones after matching with the all-us sample, there are 10157 inv_fid should be also analyzed in Nameprism 
-- https://stackoverflow.com/questions/12102200/get-records-with-max-value-for-each-group-of-grouped-sql-results
*/
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
ALTER TABLE pethprx.t30_inv_name ADD INDEX(inv_fid);

SHOW INDEX FROM pethprx.t30_inv_name ;
SELECT * FROM pethprx.t30_inv_name LIMIT 0,10;
SELECT COUNT(DISTINCT inv_fid) FROM pethprx.t30_inv_name;

ALTER TABLE pethprx.t30_inv_name ADD COLUMN ethnic BOOL, ADD COLUMN pat_np INT UNSIGNED, ADD COLUMN pat_nc INT UNSIGNED;

ALTER TABLE pethprx.t30_inv_name ADD COLUMN celgr_id_max INT UNSIGNED AFTER ethnic, ADD COLUMN prob_max DOUBLE AFTER celgr_id_max;

UPDATE pethprx.t30_inv_name a 
	INNER JOIN (
	SELECT o.inv_fid, o.celgr_id, o.prob
	FROM pethprx.t31_inv_cel o         
	LEFT JOIN pethprx.t31_inv_cel b
	ON o.inv_fid = b.inv_fid AND (o.prob < b.prob OR (o.prob = b.prob AND o.id<b.id))
	WHERE b.prob is NULL) c 
	ON a.inv_fid=c.inv_fid
	SET a.celgr_id_max=c.celgr_id, a.prob_max=c.prob;
/*
Query OK, 668823 rows affected (29 min 53,17 sec)
Rows matched: 668823  Changed: 668823  Warnings: 0
*/

UPDATE pethprx.t30_inv_name a 
	SET a.ethnic=1
	WHERE a.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 246026 rows affected (10 min 52,30 sec)
Rows matched: 246026  Changed: 246026  Warnings: 0
*/

UPDATE pethprx.t30_inv_name a 
	SET a.ethnic=0
	WHERE a.celgr_id_max NOT IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 422797 rows affected (6,11 sec)
Rows matched: 422797  Changed: 422797  Warnings: 0
*/

-- ATTENTION: pat_np AND pat_nc ARE COMPUTED AFTER CREATING pethprx.t50_id_pat

-- t01_sample add variable: eth_comp: the ethnic identify of all the inventors in the patent have been found
ALTER TABLE pethprx.t01_samples ADD COLUMN eth_comp BOOL;
UPDATE pethprx.t01_samples a 
	INNER JOIN riccaboni2017.t08 b
	ON a.pat_id = b.pat_id
	INNER JOIN riccaboni2017.t08_inv c
	ON b.inv_id = c.id
	LEFT JOIN pethprx.t30_inv_name d
	ON c.inv_fid=d.inv_fid 
	SET a.eth_comp=0
	WHERE d.inv_fid IS NULL; 
/*
Query OK, 1151401 rows affected (4 min 7,07 sec)
Rows matched: 1151401  Changed: 1151401  Warnings: 0
*/

UPDATE pethprx.t01_samples a 
	SET a.eth_comp=1	
	WHERE a.eth_comp IS NULL;
/*
Query OK, 1223627 rows affected (20,11 sec)
Rows matched: 1223627  Changed: 1223627  Warnings: 0
*/

SELECT * FROM pethprx.t30_inv_name LIMIT 10;


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
 
UPDATE pethprx.t30_inv_name a 
	INNER JOIN (
	SELECT b.inv_fid, COUNT(DISTINCT b.pat_id) AS pat_np
	FROM pethprx.t50_id_pat b
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	WHERE d.field IN ('p', 'i')
	GROUP BY b.inv_fid
	) d
	ON a.inv_fid=d.inv_fid
	SET a.pat_np=d.pat_np;
/*
Query OK, 281349 rows affected (1 min 6,60 sec)
Rows matched: 281349  Changed: 281349  Warnings: 0
*/

UPDATE pethprx.t30_inv_name a 
	INNER JOIN (
	SELECT b.inv_fid, COUNT(DISTINCT b.pat_id) AS pat_nc
	FROM pethprx.t50_id_pat b
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	WHERE d.field IN ('c', 'i')
	GROUP BY b.inv_fid
	) d
	ON a.inv_fid=d.inv_fid
	SET a.pat_nc=d.pat_nc;

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
SELECT COUNT(DISTINCT inv_fid) FROM pethprx.t50_id_pat;
/*
+-------------------------+
| COUNT(DISTINCT inv_fid) |
+-------------------------+
|                 1479424 |
+-------------------------+
1 row in set (4,57 sec)
*/
SELECT COUNT(DISTINCT a.inv_fid) FROM pethprx.t50_id_pat a INNER JOIN pethprx.t01_samples b ON a.pat_id=b.pat_id WHERE b.inv_all_us=1;
/*
+---------------------------+
| COUNT(DISTINCT a.inv_fid) |
+---------------------------+
|                    570956 |
+---------------------------+
1 row in set (8,64 sec)
*/
SELECT COUNT(DISTINCT a.inv_fid) 
	FROM pethprx.t50_id_pat a 
	INNER JOIN pethprx.t01_samples b ON a.pat_id=b.pat_id 
	INNER JOIN pethprx.t30_inv_name c ON a.inv_fid=c.inv_fid	
	WHERE b.inv_all_us=1;
/*
+---------------------------+
| COUNT(DISTINCT a.inv_fid) |
+---------------------------+
|                    560799 |
+---------------------------+
1 row in set (13,55 sec)
So, with this new sample, around 10157 inv_fid should be also analyzed in Nameprism 
*/

--------------------------
--List of directed links at the patent level
/*
-- This table can be used to create networks:
- by field or collapsing by year, when joined with t01_samples
- selecting ethnic focal inventors, when joined with table (TO CREATE WITH DIFFERENT DEFINITIONS OF ETHNIC INVENTORS)
- ATTENTION: Column sample_id is created after filling up table t53 
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


--------------------------
--List of undirected links at the year level
/*
id
inv_fid  Minimun inv_fid between the pair ij, so min(i,j)
inv_fid_ Maximum inv_fid between the pair ij, so max(i,j)
EARLIEST_FILING_YEAR 
cntrf Counterfactual link? 1 yes, 0: no, so real id
*/
DROP TABLE IF EXISTS pethprx.t52_eudir;
CREATE TABLE pethprx.t52_eudir (
id SERIAL,
inv_fid  BIGINT UNSIGNED,
inv_fid_  BIGINT UNSIGNED,
EARLIEST_FILING_YEAR INT(4) UNSIGNED,
cntrf BOOL
)
ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;
ALTER TABLE pethprx.t52_eudir ADD INDEX(inv_fid);
ALTER TABLE pethprx.t52_eudir ADD INDEX(inv_fid_);
ALTER TABLE pethprx.t52_eudir ADD INDEX(EARLIEST_FILING_YEAR);
ALTER TABLE pethprx.t52_eudir ADD UNIQUE (inv_fid, inv_fid_, EARLIEST_FILING_YEAR);

INSERT INTO pethprx.t52_eudir (inv_fid, inv_fid_, EARLIEST_FILING_YEAR, cntrf) 
SELECT DISTINCT LEAST(a.inv_fid, a.inv_fid_), GREATEST(a.inv_fid, a.inv_fid_), b.EARLIEST_FILING_YEAR, 0
FROM pethprx.t51_edir a
INNER JOIN pethprx.t01_samples b
ON a.pat_id=b.pat_id;
/*
Query OK, 5237244 rows affected (5 min 9,62 sec)
Records: 5237244  Duplicates: 0  Warnings: 0
*/

ALTER TABLE pethprx.t51_edir ADD COLUMN eudir_id BIGINT UNSIGNED AFTER pat_id;
UPDATE pethprx.t51_edir a 
	INNER JOIN pethprx.t01_samples c
	ON a.pat_id=c.pat_id
	INNER JOIN pethprx.t52_eudir b
	ON LEAST(a.inv_fid, a.inv_fid_)=b.inv_fid AND GREATEST(a.inv_fid, a.inv_fid_)= b.inv_fid_ AND c.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	SET a.eudir_id=b.id
	WHERE cntrf=0;


--------------------------
-- t53_sample
-- Table of directed edges, first collaborations ever with the columns: all inventors in the US and focal inventor is ethnic
/*
id
inv_fid  
inv_fid_
EARLIEST_FILING_YEAR 
eudir_id Undirected Edge id from table t52
inv_all_us This link in that year is found in at least one patent in which all the inventors were located in the US
ethnic_focal The focal inventor belongs to any of the considered cel groups. Attention: there are a few missing ids, as we only get the cel group for the inventors belonging to a team with a least one inventor in the US, so they are assumed as non-ethnic
- This can be joined with the directed links table
- Constraint on inv_fid,inv_fid_, so first link ever

TO DO: 
- ADD COLUMN IDENTIFYING TOP MIGRANT INVENTORS
*/
DROP TABLE IF EXISTS pethprx.t53_sample;
CREATE TABLE pethprx.t53_sample (
id SERIAL,
inv_fid  BIGINT UNSIGNED,
inv_fid_  BIGINT UNSIGNED,
EARLIEST_FILING_YEAR INT(4) UNSIGNED,
inv_fid__ BIGINT UNSIGNED,
eudir_id BIGINT UNSIGNED,
inv_all_us BOOLEAN,
ethnic_focal BOOLEAN,
CONSTRAINT UNIQUE (inv_fid,inv_fid_)
)
ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;
ALTER TABLE pethprx.t53_sample ADD INDEX(inv_fid);
ALTER TABLE pethprx.t53_sample ADD INDEX(inv_fid_);
ALTER TABLE pethprx.t53_sample ADD INDEX(EARLIEST_FILING_YEAR);
ALTER TABLE pethprx.t53_sample ADD INDEX(inv_fid__);
ALTER TABLE pethprx.t53_sample ADD INDEX(eudir_id);

INSERT INTO pethprx.t53_sample (inv_fid, inv_fid_, EARLIEST_FILING_YEAR) 
	SELECT DISTINCT o.inv_fid, o.inv_fid_, o.EARLIEST_FILING_YEAR
	FROM (
	SELECT DISTINCT a.inv_fid, a.inv_fid_, c.EARLIEST_FILING_YEAR
	FROM pethprx.t51_edir a
	INNER JOIN pethprx.t01_samples c
	ON a.pat_id=c.pat_id) o         
	LEFT JOIN (
	SELECT DISTINCT a.inv_fid, a.inv_fid_, c.EARLIEST_FILING_YEAR
	FROM pethprx.t51_edir a
	INNER JOIN pethprx.t01_samples c
	ON a.pat_id=c.pat_id) b
	ON o.inv_fid = b.inv_fid AND o.inv_fid_= b.inv_fid_ AND o.EARLIEST_FILING_YEAR > b.EARLIEST_FILING_YEAR
	WHERE b.EARLIEST_FILING_YEAR IS NULL;
/*
Query OK, 8440498 rows affected (18 min 50,78 sec)
Records: 8440498  Duplicates: 0  Warnings: 0
*/

ALTER TABLE pethprx.t51_edir ADD COLUMN sample_id BIGINT UNSIGNED;
UPDATE pethprx.t51_edir a 
	INNER JOIN pethprx.t01_samples c
	ON a.pat_id=c.pat_id
	INNER JOIN pethprx.t53_sample b
	ON a.inv_fid=b.inv_fid AND a.inv_fid_= b.inv_fid_ AND c.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	SET a.sample_id=b.id;
/*
Query OK, 17104918 rows affected (15 min 36,13 sec)
Rows matched: 17104918  Changed: 17104918  Warnings: 0
*/
ALTER TABLE pethprx.t51_edir ADD INDEX(sample_id);

UPDATE pethprx.t53_sample a 
	INNER JOIN pethprx.t51_edir b
	ON a.id=b.sample_id
	INNER JOIN pethprx.t01_samples c
	ON b.pat_id=c.pat_id
	SET a.inv_all_us=1	
	WHERE c.inv_all_us=1;
/*
Query OK, 2929718 rows affected (2 min 15,52 sec)
Rows matched: 2929718  Changed: 2929718  Warnings: 0
*/

UPDATE pethprx.t53_sample a 
	SET a.inv_all_us=0	
	WHERE a.inv_all_us IS NULL;
/*
Query OK, 5510780 rows affected (2 min 38,57 sec)
Rows matched: 5510780  Changed: 5510780  Warnings: 0
*/

UPDATE pethprx.t53_sample a 
	INNER JOIN pethprx.t30_inv_name b
	ON a.inv_fid=b.inv_fid
	SET a.ethnic_focal=1	
	WHERE b.ethnic=1;
/*
Query OK, 1895781 rows affected (1 min 17,71 sec)
Rows matched: 1895781  Changed: 1895781  Warnings: 0
*/

UPDATE pethprx.t53_sample a 
	SET a.ethnic_focal=0	
	WHERE a.ethnic_focal IS NULL;
/*
Query OK, 6544717 rows affected (3 min 54,76 sec)
Rows matched: 6544717  Changed: 6544717  Warnings: 0
*/

UPDATE pethprx.t53_sample a 
	INNER JOIN pethprx.t52_eudir b
	ON LEAST(a.inv_fid, a.inv_fid_)=b.inv_fid AND GREATEST(a.inv_fid, a.inv_fid_)=b.inv_fid_ AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	SET a.eudir_id=b.id;
/*
Query OK, 8440498 rows affected (13 min 20,58 sec)
Rows matched: 8440498  Changed: 8440498  Warnings: 0
*/

ALTER TABLE pethprx.t53_sample ADD COLUMN eth_comp BOOL;

UPDATE pethprx.t53_sample a 
	INNER JOIN pethprx.t51_edir b
	ON a.id=b.sample_id
	INNER JOIN pethprx.t01_samples c
	ON b.pat_id=c.pat_id
	SET a.eth_comp=1	
	WHERE c.eth_comp=1;
/*
Query OK, 3864146 rows affected (3 min 37,34 sec)
Rows matched: 3864146  Changed: 3864146  Warnings: 
*/

UPDATE pethprx.t53_sample a 
	SET a.eth_comp=0	
	WHERE a.eth_comp IS NULL;
/*
Query OK, 4576352 rows affected (2 min 17,92 sec)
Rows matched: 4576352  Changed: 4576352  Warnings: 0
*/

--------------------------
-- Table of of inventors, year and ipc codes for counterfactual
DROP TABLE IF EXISTS pethprx.t54_invipc;
CREATE TABLE pethprx.t54_invipc AS
SELECT DISTINCT d.inv_fid, e.EARLIEST_FILING_YEAR, f.ipc7_id 
	FROM pethprx.t51_edir d
	INNER JOIN pethprx.t01_samples e
	ON d.pat_id=e.pat_id
	INNER JOIN pethprx.t10_samples f
	ON e.pat_id=f.pat_id
	WHERE e.inv_all_us=1 AND e.eth_comp=1;
/*
Query OK, 5491194 rows affected (4 min 38,90 sec)
Records: 5491194  Duplicates: 0  Warnings: 0
*/
-- TO RUN FROM HERE ON
ALTER TABLE pethprx.t54_invipc ADD INDEX(inv_fid);
ALTER TABLE pethprx.t54_invipc ADD INDEX(EARLIEST_FILING_YEAR);
ALTER TABLE pethprx.t54_invipc ADD INDEX(ipc7_id);

--------------------------
-- t55_invyear
/*
tyr_c: Number of times (years) an inventor has patented in the last five years (t-5 to t-1) (unit: number of years, not of patents) in the CTT field
tyr_p: Number of times (years) an inventor has patented in the last five years (t-5 to t-1) (unit: number of years, not of patents) in the PBOC field
dg_c: degree centrality for the CTT sample, no matter geographical location, undirected measure (computed from one side of a directed network), for the network between t-5 and t-1
dg_p: degree centrality for the PBOC sample, no matter geographical location, undirected measure (computed from one side of a directed network),  for the network between t-5 and t-1
dg_c_10: degree centrality for the CTT sample, no matter geographical location, undirected measure (computed from one side of a directed network), for the network between t-10 and t-1
dg_p_10: degree centrality for the PBOC sample, no matter geographical location, undirected measure (computed from one side of a directed network),  for the network between t-10 and t-1
addr_id: Most common address in that year for every inv_fid (if multiple ones)
addr_id_type: 1: only high quality addresses, 2: low quality, 3: unlocated
Null values in degree measures are explained by non-collaborative patents (single-author patents)
This table is relevant to identify the sample that includes inventors who have already patented
-- ATTENTION: SEPARATE COUNTINGS BY SAMPLE
*/
DROP TABLE IF EXISTS pethprx.t55_invyear;
CREATE TABLE pethprx.t55_invyear AS
WITH t1 AS (SELECT DISTINCT d.inv_fid, e.EARLIEST_FILING_YEAR, e.field
	FROM pethprx.t50_id_pat d
	INNER JOIN pethprx.t01_samples e
	ON d.pat_id=e.pat_id)
SELECT a.inv_fid, a.EARLIEST_FILING_YEAR, COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN b.EARLIEST_FILING_YEAR END)) AS tyr_c, COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN b.EARLIEST_FILING_YEAR END)) AS tyr_p
	FROM t1 a
	LEFT JOIN t1 b
	ON a.inv_fid=b.inv_fid AND (CAST(a.EARLIEST_FILING_YEAR AS SIGNED)-CAST(b.EARLIEST_FILING_YEAR AS SIGNED)) BETWEEN 1 AND 5
	GROUP BY a.inv_fid, a.EARLIEST_FILING_YEAR;
/*
Query OK, 2794108 rows affected (1 min 1,22 sec)
Records: 2794108  Duplicates: 0  Warnings: 0
*/
ALTER TABLE pethprx.t55_invyear ADD INDEX(inv_fid);
ALTER TABLE pethprx.t55_invyear ADD INDEX(EARLIEST_FILING_YEAR);

-- Degree centralities t-1 to t-5
ALTER TABLE pethprx.t55_invyear ADD COLUMN dg_c INT UNSIGNED, ADD COLUMN dg_p INT UNSIGNED;
WITH t2 AS (SELECT DISTINCT d.inv_fid, d.inv_fid_,  e.EARLIEST_FILING_YEAR, e.field
	FROM pethprx.t51_edir d
	INNER JOIN pethprx.t01_samples e
	ON d.pat_id=e.pat_id)
UPDATE pethprx.t55_invyear x
INNER JOIN (
	SELECT a.inv_fid, a.EARLIEST_FILING_YEAR, 
	COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN b.inv_fid_ END)) AS dg_c, 
	COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN b.inv_fid_ END)) AS dg_p
	FROM  pethprx.t55_invyear a
	INNER JOIN t2 b
	ON a.inv_fid=b.inv_fid AND (CAST(a.EARLIEST_FILING_YEAR AS SIGNED)-CAST(b.EARLIEST_FILING_YEAR AS SIGNED)) BETWEEN 1 AND 5
	GROUP BY a.inv_fid, a.EARLIEST_FILING_YEAR) y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	SET x.dg_c=y.dg_c, x.dg_p=y.dg_p;
/*
Query OK, 1111057 rows affected (4 min 49,21 sec)
Rows matched: 1111057  Changed: 1111057  Warnings: 0
*/

-- Degree centralities t-10 to t-1
ALTER TABLE pethprx.t55_invyear ADD COLUMN dg_c_10 INT UNSIGNED, ADD COLUMN dg_p_10 INT UNSIGNED;
WITH t2 AS (SELECT DISTINCT d.inv_fid, d.inv_fid_,  e.EARLIEST_FILING_YEAR, e.field
	FROM pethprx.t51_edir d
	INNER JOIN pethprx.t01_samples e
	ON d.pat_id=e.pat_id)
UPDATE pethprx.t55_invyear x
INNER JOIN (
	SELECT a.inv_fid, a.EARLIEST_FILING_YEAR, 
	COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'c') THEN b.inv_fid_ END)) AS dg_c_10, 
	COUNT(DISTINCT (CASE WHEN b.field IN ('i', 'p') THEN b.inv_fid_ END)) AS dg_p_10
	FROM  pethprx.t55_invyear a
	INNER JOIN t2 b
	ON a.inv_fid=b.inv_fid AND (CAST(a.EARLIEST_FILING_YEAR AS SIGNED)-CAST(b.EARLIEST_FILING_YEAR AS SIGNED)) BETWEEN 1 AND 10
	GROUP BY a.inv_fid, a.EARLIEST_FILING_YEAR) y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	SET x.dg_c_10=y.dg_c_10, x.dg_p_10=y.dg_p_10;
/*
Query OK, 1211855 rows affected (4 min 33,71 sec)
Rows matched: 1211855  Changed: 1211855  Warnings: 0
*/

-- Percentile distributions for each field, by year (the share correspond to the share by year)
ALTER TABLE pethprx.t55_invyear ADD COLUMN pc_c FLOAT, ADD COLUMN pc_p FLOAT,ADD COLUMN pc_c_10 FLOAT, ADD COLUMN pc_p_10 FLOAT;

UPDATE pethprx.t55_invyear x
	SET pc_c=NULL, pc_p=NULL, pc_c_10=NULL, pc_p_10=NULL;


UPDATE pethprx.t55_invyear x
	INNER JOIN (SELECT inv_fid, EARLIEST_FILING_YEAR,
	ROUND( PERCENT_RANK() OVER (
        PARTITION BY EARLIEST_FILING_YEAR
        ORDER BY dg_c
	),4) pc_c
	FROM pethprx.t55_invyear
	WHERE dg_c IS NOT NULL AND dg_c>0) y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	SET x.pc_c=y.pc_c;
/*
Query OK, 499344 rows affected (19,23 sec)
Rows matched: 499344  Changed: 499344  Warnings: 0
*/

UPDATE pethprx.t55_invyear x
	SET pc_p=NULL;

UPDATE pethprx.t55_invyear x
	INNER JOIN (SELECT inv_fid, EARLIEST_FILING_YEAR,
	ROUND( PERCENT_RANK() OVER (
        PARTITION BY EARLIEST_FILING_YEAR
        ORDER BY dg_p
	),4) pc_p
	FROM pethprx.t55_invyear
	WHERE dg_p IS NOT NULL AND dg_p>0) y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	SET x.pc_p=y.pc_p;
/*
Query OK, 645240 rows affected (24,14 sec)
Rows matched: 645240  Changed: 645240  Warnings: 0
*/

UPDATE pethprx.t55_invyear x
	INNER JOIN (SELECT inv_fid, EARLIEST_FILING_YEAR,
	ROUND( PERCENT_RANK() OVER (
        PARTITION BY EARLIEST_FILING_YEAR
        ORDER BY dg_c_10
	),4) pc_c_10
	FROM pethprx.t55_invyear
	WHERE dg_c_10 IS NOT NULL AND dg_c_10>0) y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	SET x.pc_c_10=y.pc_c_10;
/*
Query OK, 555921 rows affected (21,33 sec)
Rows matched: 555921  Changed: 555921  Warnings: 0
*/

UPDATE pethprx.t55_invyear x
	INNER JOIN (SELECT inv_fid, EARLIEST_FILING_YEAR,
	ROUND( PERCENT_RANK() OVER (
        PARTITION BY EARLIEST_FILING_YEAR
        ORDER BY dg_p_10
	),4) pc_p_10
	FROM pethprx.t55_invyear
	WHERE dg_p_10 IS NOT NULL AND dg_p_10>0) y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	SET x.pc_p_10=y.pc_p_10;
/*
Query OK, 703612 rows affected (27,93 sec)
Rows matched: 703612  Changed: 703612  Warnings: 0
*/

-- Location by year
--As in Riccaboni's geocoding does not provide a single coordinate point by address, I have to chosse a single location per year
-- I only choose the location if all the team was inside the US

ALTER TABLE pethprx.t55_invyear ADD COLUMN id SERIAL FIRST, ADD COLUMN addr_id BIGINT UNSIGNED, ADD COLUMN addr_id_type INT UNSIGNED;


UPDATE pethprx.t55_invyear k 
	SET k.addr_id=NULL;
/*
Query OK, 2710761 rows affected (43,58 sec)
Rows matched: 2794108  Changed: 2710761  Warnings: 0
*/

WITH t1 AS (SELECT a.id, c.addr_id, COUNT(DISTINCT d.pat_id) AS npat
	FROM pethprx.t55_invyear a
	INNER JOIN riccaboni2017.t08_inv b
	ON a.inv_fid=b.inv_fid
	INNER JOIN riccaboni2017.t08 c
	ON c.loctype='high' AND b.id=c.inv_id
	INNER JOIN pethprx.t01_samples d
	ON c.pat_id=d.pat_id AND a.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR AND d.inv_all_us=1
	GROUP BY a.id, c.addr_id)
UPDATE pethprx.t55_invyear k 
	INNER JOIN (
	SELECT x.id, x.addr_id
	FROM t1 x
	LEFT JOIN t1 y
	ON x.id = y.id AND (x.npat < y.npat OR (x.npat = y.npat AND x.addr_id<y.addr_id))
	WHERE y.npat is NULL) l
	ON k.id=l.id
	SET k.addr_id=l.addr_id, k.addr_id_type=1;
/*
Query OK, 397198 rows affected (1 min 38,90 sec)
Rows matched: 397198  Changed: 397198  Warnings: 0


Query OK, 899841 rows affected (1 min 58,90 sec)
Rows matched: 899841  Changed: 899841  Warnings: 0
*/

WITH t1 AS (SELECT a.id, c.addr_id, COUNT(DISTINCT d.pat_id) AS npat
	FROM pethprx.t55_invyear a
	INNER JOIN riccaboni2017.t08_inv b
	ON a.addr_id IS NULL AND a.inv_fid=b.inv_fid
	INNER JOIN riccaboni2017.t08 c
	ON c.loctype IN ('high', 'low') AND b.id=c.inv_id
	INNER JOIN pethprx.t01_samples d
	ON c.pat_id=d.pat_id AND a.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR AND d.inv_all_us=1
	WHERE a.addr_id IS NULL
	GROUP BY a.id, c.addr_id)
UPDATE pethprx.t55_invyear k 
	INNER JOIN (
	SELECT x.id, x.addr_id
	FROM t1 x
	LEFT JOIN t1 y
	ON x.id = y.id AND (x.npat < y.npat OR (x.npat = y.npat AND x.addr_id<y.addr_id))
	WHERE y.npat is NULL) l
	ON k.id=l.id
	SET k.addr_id=l.addr_id, k.addr_id_type=2
	WHERE k.addr_id IS NULL ;
/*
Query OK, 683001 rows affected (6 min 59,23 sec)
Rows matched: 683001  Changed: 683001  Warnings: 0



Query OK, 1723607 rows affected (5 min 35,04 sec)
Rows matched: 1723607  Changed: 1723607  Warnings: 0
*/


WITH t1 AS (SELECT a.id, c.addr_id, COUNT(DISTINCT d.pat_id) AS npat
	FROM pethprx.t55_invyear a
	INNER JOIN riccaboni2017.t08_inv b
	ON a.addr_id IS NULL AND a.inv_fid=b.inv_fid
	INNER JOIN riccaboni2017.t08 c
	ON b.id=c.inv_id
	INNER JOIN pethprx.t01_samples d
	ON c.pat_id=d.pat_id AND a.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR AND d.inv_all_us=1
	WHERE a.addr_id IS NULL
	GROUP BY a.id, c.addr_id)
UPDATE pethprx.t55_invyear k 
	INNER JOIN (
	SELECT x.id, x.addr_id
	FROM t1 x
	LEFT JOIN t1 y
	ON x.id = y.id AND (x.npat < y.npat OR (x.npat = y.npat AND x.addr_id<y.addr_id))
	WHERE y.npat is NULL) l
	ON k.id=l.id
	SET k.addr_id=l.addr_id, k.addr_id_type=3
	WHERE k.addr_id IS NULL ;
/*
Query OK, 3901 rows affected (4 min 54,29 sec)
Rows matched: 3901  Changed: 3901  Warnings: 0


Query OK, 170660 rows affected (24,12 sec)
Rows matched: 170660  Changed: 170660  Warnings: 0
*/


SELECT COUNT(*) FROM pethprx.t55_invyear WHERE addr_id IS NULL LIMIT 0,10;
/*
+----------+
| COUNT(*) |
+----------+
|    83347 |
+----------+
1 row in set (0,64 sec)
There are still some inventors withouth add_id for some years
*/
SELECT * FROM pethprx.t55_invyear WHERE addr_id IS NULL LIMIT 0,10;

SELECT * FROM pethprx.t55_invyear LIMIT 0,10;
SELECT DISTINCT d.inv_fid, d.inv_fid_,  e.EARLIEST_FILING_YEAR, e.field
	FROM pethprx.t51_edir d
	INNER JOIN pethprx.t01_samples e
	ON d.pat_id=e.pat_id
	WHERE d.inv_fid=8 ORDER BY e.EARLIEST_FILING_YEAR LIMIT 0,50;

SELECT * FROM pethprx.t55_invyear WHERE pc_c>0.9 LIMIT 0,10;

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Counterfactual samples t6# 
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

ALTER TABLE pethprx.t54_invipc DROP COLUMN tyr, DROP COLUMN  pc_10 BOOL;


-- Prepare table t54_invipc
ALTER TABLE pethprx.t54_invipc ADD COLUMN tyr BOOL, ADD COLUMN  pc_10 BOOL;
-- tyr: inventor active either on the field c or p, in the time window t-5 to t-1
-- pc_10: Is inventor in the percentile 10%, computed in the time window t-10, t-1
UPDATE pethprx.t54_invipc a
	INNER JOIN pethprx.t55_invyear b
	ON (b.tyr_c>0 OR b.tyr_p>0) AND a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR 
	SET a.tyr=1;
/*
Query OK, 2841064 rows affected (2 min 5,53 sec)
Rows matched: 2841064  Changed: 2841064  Warnings: 0
*/
UPDATE pethprx.t54_invipc a
	SET a.tyr=0
	WHERE a.tyr IS NULL;
/*
Query OK, 2650130 rows affected (57,81 sec)
Rows matched: 2650130  Changed: 2650130  Warnings: 0
*/
UPDATE pethprx.t54_invipc a
	INNER JOIN pethprx.t55_invyear b
	ON (b.tyr_c>0 OR b.tyr_p>0) AND (b.pc_c_10<0.9 OR b.pc_p_10<0.9) AND a.inv_fid=b.inv_fid 
	AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR 
	SET a.pc_10=0;
/*
Query OK, 2397894 rows affected (2 min 22,43 sec)
Rows matched: 2397894  Changed: 2397894  Warnings: 0
*/
UPDATE pethprx.t54_invipc a
	SET a.pc_10=1
	WHERE a.pc_10 IS NULL;
/*
Query OK, 3093300 rows affected (2 min 35,50 sec)
Rows matched: 3093300  Changed: 3093300  Warnings: 0

*/

SELECT pc_10, COUNT(*) FROM pethprx.t54_invipc GROUP BY pc_10 LIMIT 10;

--------------------------
-- t61_s1 Sample 1
/*
Big sample, all inventors located in the US, only pairs when the focal inventor is ethnic and the information is available
Attention: this table includes both senior, non senior and single-patent ever inventors

Notes: to compute, as it takes a lot of time.
*/

DROP TABLE IF EXISTS pethprx.t61_s1;
CREATE TABLE pethprx.t61_s1 (
id SERIAL,
sample_id BIGINT UNSIGNED,
inv_fid__  BIGINT UNSIGNED,
cntrf_round INT
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;
ALTER TABLE pethprx.t61_s1 ADD INDEX(sample_id);
ALTER TABLE pethprx.t61_s1 ADD INDEX(inv_fid__);

INSERT INTO pethprx.t61_s1 (sample_id)
SELECT a.id FROM pethprx.t53_sample a WHERE a.ethnic_focal=1 and a.inv_all_us=1 and a.eth_comp=1;
/*
Query OK, 1027815 rows affected (16,79 sec)
Records: 1027815  Duplicates: 0  Warnings: 0
*/
SELECT * FROM pethprx.t61_s1 LIMIT 10;

WITH t1 AS (SELECT l.id, h.inv_fid
	FROM (SELECT * FROM pethprx.t61_s1 LIMIT 100) l
	INNER JOIN pethprx.t51_edir b
	ON l.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON d.inv_all_us=1 AND d.eth_comp=1 AND b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	INNER JOIN pethprx.t54_invipc h
	ON c.ipc7_id=h.ipc7_id AND d.EARLIEST_FILING_YEAR=h.EARLIEST_FILING_YEAR
	LEFT JOIN pethprx.t53_sample y
	ON b.inv_fid=y.inv_fid AND h.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON b.inv_fid_=z.inv_fid AND h.inv_fid=z.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL
)
UPDATE pethprx.t61_s1 aa, LATERAL(
	SELECT m.inv_fid
	FROM t1 m
	WHERE aa.id=m.id
	ORDER BY RAND()
	LIMIT 1
	) x
	SET aa.inv_fid__=x.inv_fid, aa.cntrf_round=1;

UPDATE pethprx.t61_s1 a,
	LATERAL(
	SELECT h.inv_fid
	FROM (SELECT * FROM pethprx.t61_s1 LIMIT 100) l
	INNER JOIN pethprx.t51_edir b
	ON l.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON d.inv_all_us=1 AND d.eth_comp=1 AND b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	INNER JOIN pethprx.t54_invipc h
	ON c.ipc7_id=h.ipc7_id AND d.EARLIEST_FILING_YEAR=h.EARLIEST_FILING_YEAR
	LEFT JOIN pethprx.t53_sample y
	ON b.inv_fid=y.inv_fid AND h.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON b.inv_fid_=z.inv_fid AND h.inv_fid=z.inv_fid_
	WHERE a.sample_id=b.sample_id AND y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL 
	ORDER BY RAND()
	LIMIT 1
	) x
	SET a.inv_fid__=x.inv_fid, a.cntrf_round=1;
/*
For getting the counterfactual node h:

- From table pethprx.t53_sample, I only take the sample of ij links that belong to patents in which the focal inventor is ethnic, all the inventors are located in the US and I have complete ethnic information for all the people listed in a patent; ethnic_focal=1 and inv_all_us=1 nd a.eth_comp=1
- Then I do a lateral join where I define the characteristics of the counterfactual nodes and the number of counterfactuals (1 in this case, as I am still keeping the directed network):
	- I beging with t51_edir, to get the pat_id and the IPC clases
	- Then I match all nodes who have collaborated in the same year with anyone else and who have patented in the same technological class of the collaboration ij
	- Then I do two lateral joins with table t53 without the year to eliminate the collaborations that have ever occur (so ih and jh have never collaborated in the whole sample).

When creating the final sample:
- Only the undirected id should be used 

-- https://dev.mysql.com/doc/refman/8.0/en/lateral-derived-tables.html
-- https://jan.kneschke.de/projects/mysql/order-by-rand/
https://federico-razzoli.com/how-to-return-random-rows-from-a-table
*/





WITH t1 AS (SELECT ROW_NUMBER() OVER(PARTITION BY l.id) AS row_num, l.id AS sample_id, h.inv_fid
	FROM (SELECT * FROM pethprx.t61_s1 LIMIT 100) l
	INNER JOIN pethprx.t51_edir b
	ON l.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON d.inv_all_us=1 AND d.eth_comp=1 AND b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	INNER JOIN pethprx.t54_invipc h
	ON c.ipc7_id=h.ipc7_id AND d.EARLIEST_FILING_YEAR=h.EARLIEST_FILING_YEAR
	LEFT JOIN pethprx.t53_sample y
	ON b.inv_fid=y.inv_fid AND h.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON b.inv_fid_=z.inv_fid AND h.inv_fid=z.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL
)
SELECT DISTINCT a.id, x.inv_fid AS inv_fid__
	FROM pethprx.t61_s1 a,
	LATERAL(
	SELECT m.inv_fid
	FROM t1 m
	WHERE a.id=m.sample_id
	LIMIT 1
	) x
	LIMIT 100;
-- a.inv_fid, a.inv_fid_, a.EARLIEST_FILING_YEAR ,

	WITH t3 AS (	
	SELECT row_num, m.inv_fid
	FROM t1 m
	WHERE a.id=m.sample_id)
	SELECT xx.inv_fid
	FROM t3 xx
	JOIN (SELECT CEIL(RAND() * (SELECT MAX(row_num) FROM  t3)) AS row_num ) AS r2
	USING (row_num)




-- To select for a single row
WITH t1 AS (SELECT ROW_NUMBER() OVER() AS row_num, l.id AS sample_id, h.inv_fid
	FROM (SELECT * FROM pethprx.t61_s1 ww WHERE ww.id=1) l
	INNER JOIN pethprx.t51_edir b
	ON l.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON d.inv_all_us=1 AND d.eth_comp=1 AND b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	INNER JOIN pethprx.t54_invipc h
	ON c.ipc7_id=h.ipc7_id AND d.EARLIEST_FILING_YEAR=h.EARLIEST_FILING_YEAR
	LEFT JOIN pethprx.t53_sample y
	ON b.inv_fid=y.inv_fid AND h.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON b.inv_fid_=z.inv_fid AND h.inv_fid=z.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL
)
SELECT x.inv_fid
	FROM t1 x
	JOIN (SELECT CEIL(RAND() * (SELECT MAX(row_num) FROM  t1)) AS row_num ) AS r2
	USING (row_num);


WITH t1 AS (SELECT l.id AS sample_id, h.inv_fid
	FROM (SELECT * FROM pethprx.t61_s1 LIMIT 100) l
	INNER JOIN pethprx.t51_edir b
	ON l.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON d.inv_all_us=1 AND d.eth_comp=1 AND b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	INNER JOIN pethprx.t54_invipc h
	ON c.ipc7_id=h.ipc7_id AND d.EARLIEST_FILING_YEAR=h.EARLIEST_FILING_YEAR
	LEFT JOIN pethprx.t53_sample y
	ON b.inv_fid=y.inv_fid AND h.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON b.inv_fid_=z.inv_fid AND h.inv_fid=z.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL
)
SELECT DISTINCT a.id, x.inv_fid AS inv_fid__
	FROM pethprx.t61_s1 a,
	LATERAL(
	SELECT m.inv_fid
	FROM t1 m
	WHERE a.id=m.sample_id
	ORDER BY RAND()
	LIMIT 1
	) x
	LIMIT 100;




--------------------------
-- t62_s2 Sample 2
/*
Intermediate sample, 
Same as t61 + only inventors who have also patented in the period t-5, t-1 (so to be able to compute other measures)
Same as t61 means (all inventors located in the US, only pairs when the focal inventor is ethnic and the information is available)
Attention: this table includes both senior, non senior. It excludes single-patent ever inventors

Notes: to compute, as it takes a lot of time.
*/

DROP TABLE IF EXISTS pethprx.t62_s2;
CREATE TABLE pethprx.t62_s2 (
id SERIAL,
sample_id BIGINT UNSIGNED,
inv_fid__  BIGINT UNSIGNED,
cntrf_round INT
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;
ALTER TABLE pethprx.t62_s2 ADD INDEX(sample_id);
ALTER TABLE pethprx.t62_s2 ADD INDEX(inv_fid__);

INSERT INTO pethprx.t62_s2 (sample_id)
SELECT a.id 
FROM pethprx.t53_sample a 
INNER JOIN pethprx.t55_invyear b
ON (b.tyr_c>0 OR b.tyr_p>0) AND a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR 
INNER JOIN pethprx.t55_invyear c
ON (c.tyr_c>0 OR c.tyr_p>0) AND a.inv_fid_=c.inv_fid AND a.EARLIEST_FILING_YEAR=c.EARLIEST_FILING_YEAR
WHERE a.ethnic_focal=1 AND a.inv_all_us=1 AND a.eth_comp=1;
/*
Query OK, 207660 rows affected (23,30 sec)
Records: 207660  Duplicates: 0  Warnings: 0
*/

-- Round 1 (run as a .sh script by groups of 50-100 rows)
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT a.inv_fid, a.ipc7_id, a.EARLIEST_FILING_YEAR
	FROM pethprx.t54_invipc a
	WHERE a.tyr=1 
	),
	t3 AS (
	WITH t4 AS (SELECT * FROM pethprx.t62_s2 LIMIT 0, 50)
	SELECT DISTINCT a.id, b.inv_fid, b.inv_fid_, c.ipc7_id, d.EARLIEST_FILING_YEAR
	FROM t4 a
	INNER JOIN pethprx.t51_edir b
	ON a.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	)	
	SELECT DISTINCT l.id, e.inv_fid
	FROM t3 l
	INNER JOIN t2 e
	ON l.EARLIEST_FILING_YEAR=e.EARLIEST_FILING_YEAR AND l.ipc7_id=e.ipc7_id
	LEFT JOIN pethprx.t53_sample y
	ON l.inv_fid=y.inv_fid AND e.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON l.inv_fid_=z.inv_fid AND e.inv_fid=z.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL)
UPDATE pethprx.t62_s2 aa
	INNER JOIN LATERAL (
	SELECT m.inv_fid
	FROM t1 m
	WHERE aa.id=m.id
	ORDER BY RAND()
	LIMIT 1
	) x
	ON TRUE
	SET aa.inv_fid__=x.inv_fid, aa.cntrf_round=1;
/*
Query OK, 100 rows affected (16,30 sec)
Rows matched: 100  Changed: 100  Warnings: 0
*/

-- Round 2: to correct 61 rows for which I couldn't find a counterfactual in IPC7, so find it at IPC4
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT a.inv_fid, g.ipc4_id, a.EARLIEST_FILING_YEAR
	FROM pethprx.t54_invipc a
	INNER JOIN pethprx.t10_ipc7 g
	ON a.ipc7_id=g.id
	WHERE a.tyr=1 
	),
	t3 AS (
	WITH t4 AS (SELECT * FROM pethprx.t62_s2 WHERE inv_fid__=1 LIMIT 80)
	SELECT DISTINCT a.id, b.inv_fid, b.inv_fid_, c.ipc4_id, d.EARLIEST_FILING_YEAR
	FROM t4 a
	INNER JOIN pethprx.t51_edir b
	ON a.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	)	
	SELECT DISTINCT l.id, e.inv_fid
	FROM t3 l
	INNER JOIN t2 e
	ON l.EARLIEST_FILING_YEAR=e.EARLIEST_FILING_YEAR AND l.ipc4_id=e.ipc4_id
	LEFT JOIN pethprx.t53_sample y
	ON l.inv_fid=y.inv_fid AND e.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON l.inv_fid_=z.inv_fid AND e.inv_fid=z.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL)
UPDATE pethprx.t62_s2 aa
	INNER JOIN LATERAL (
	SELECT m.inv_fid
	FROM t1 m
	WHERE aa.id=m.id
	ORDER BY RAND()
	LIMIT 1
	) x
	ON TRUE
	SET aa.inv_fid__=x.inv_fid, aa.cntrf_round=2;
/*
Query OK, 61 rows affected (12,03 sec)
Rows matched: 61  Changed: 61  Warnings: 0
*/


-- Delete repeated counterfactuals
WITH t3 AS (
WITH t2 AS (
WITH t1 AS (
SELECT LEAST(a.inv_fid, b.inv_fid__) AS inv_fid_f, GREATEST(a.inv_fid, b.inv_fid__) AS inv_fid__f, a.EARLIEST_FILING_YEAR, COUNT(DISTINCT b.id) AS ncount
FROM pethprx.t53_sample a
INNER JOIN pethprx.t62_s2 b
ON a.id=b.sample_id
GROUP BY inv_fid_f, inv_fid__f, a.EARLIEST_FILING_YEAR
HAVING ncount>1
ORDER BY ncount DESC)
SELECT b.id, a.inv_fid, b.inv_fid__, c.ncount
	FROM pethprx.t53_sample a
	INNER JOIN pethprx.t62_s2 b
	ON a.id=b.sample_id
	INNER JOIN t1 c
	ON LEAST(a.inv_fid, b.inv_fid__)=c.inv_fid_f AND GREATEST(a.inv_fid, b.inv_fid__)=c.inv_fid__f)
SELECT DISTINCT x.id
	FROM t2 x
	LEFT JOIN t2 y
	ON x.inv_fid=y.inv_fid AND x.inv_fid__=y.inv_fid__ AND x.id<y.id
	WHERE y.id IS NOT NULL)
UPDATE pethprx.t62_s2 aa
	INNER JOIN t3 bb
	ON aa.id=bb.id
	SET aa.inv_fid__=NULL, aa.cntrf_round=NULL;
/*
Query OK, 366 rows affected (23,88 sec)
Rows matched: 366  Changed: 366  Warnings: 0
*/

-- Run again for assign new values to repeated ones
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT a.inv_fid, a.ipc7_id, a.EARLIEST_FILING_YEAR
	FROM pethprx.t54_invipc a
	WHERE a.tyr=1 
	),
	t3 AS (
	WITH t4 AS (SELECT * FROM pethprx.t62_s2 WHERE inv_fid__ IS NULL LIMIT 100)
	SELECT DISTINCT a.id, b.inv_fid, b.inv_fid_, c.ipc7_id, d.EARLIEST_FILING_YEAR
	FROM t4 a
	INNER JOIN pethprx.t51_edir b
	ON a.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	),
	t5 AS (
	SELECT DISTINCT a.inv_fid, b.inv_fid__ AS inv_fid_
	FROM pethprx.t53_sample a
	INNER JOIN pethprx.t62_s2 b
	ON a.id=b.sample_id
	WHERE b.inv_fid__ IS NOT NULL
	)	
	SELECT DISTINCT l.id, e.inv_fid
	FROM t3 l
	INNER JOIN t2 e
	ON l.EARLIEST_FILING_YEAR=e.EARLIEST_FILING_YEAR AND l.ipc7_id=e.ipc7_id
	LEFT JOIN pethprx.t53_sample y
	ON l.inv_fid=y.inv_fid AND e.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON l.inv_fid_=z.inv_fid AND e.inv_fid=z.inv_fid_
	LEFT JOIN t5 yy 
	ON l.inv_fid=yy.inv_fid AND e.inv_fid=yy.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL AND yy.inv_fid_ IS NULL)
UPDATE pethprx.t62_s2 aa
	INNER JOIN LATERAL (
	SELECT m.inv_fid
	FROM t1 m
	WHERE aa.id=m.id
	ORDER BY RAND()
	LIMIT 1
	) x
	ON TRUE
	SET aa.inv_fid__=x.inv_fid, aa.cntrf_round=3;
/*
Loop delete and update batch as many times as necessary and when there are not more rows that can be updated, move to IPC4
*/

-- Do matching using IPC4
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT a.inv_fid, g.ipc4_id, a.EARLIEST_FILING_YEAR
	FROM pethprx.t54_invipc a
	INNER JOIN pethprx.t10_ipc7 g
	ON a.ipc7_id=g.id
	WHERE a.tyr=1 
	),
	t3 AS (
	WITH t4 AS (SELECT * FROM pethprx.t62_s2 WHERE inv_fid__ IS NULL LIMIT 100)
	SELECT DISTINCT a.id, b.inv_fid, b.inv_fid_, c.ipc4_id, d.EARLIEST_FILING_YEAR
	FROM t4 a
	INNER JOIN pethprx.t51_edir b
	ON a.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	),
	t5 AS (
	SELECT DISTINCT a.inv_fid, b.inv_fid__ AS inv_fid_
	FROM pethprx.t53_sample a
	INNER JOIN pethprx.t62_s2 b
	ON a.id=b.sample_id
	WHERE b.inv_fid__ IS NOT NULL
	)	
	SELECT DISTINCT l.id, e.inv_fid
	FROM t3 l
	INNER JOIN t2 e
	ON l.EARLIEST_FILING_YEAR=e.EARLIEST_FILING_YEAR AND l.ipc4_id=e.ipc4_id
	LEFT JOIN pethprx.t53_sample y
	ON l.inv_fid=y.inv_fid AND e.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON l.inv_fid_=z.inv_fid AND e.inv_fid=z.inv_fid_
	LEFT JOIN t5 yy 
	ON l.inv_fid=yy.inv_fid AND e.inv_fid=yy.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL AND yy.inv_fid_ IS NULL)
UPDATE pethprx.t62_s2 aa
	INNER JOIN LATERAL (
	SELECT m.inv_fid
	FROM t1 m
	WHERE aa.id=m.id
	ORDER BY RAND()
	LIMIT 1
	) x
	ON TRUE
	SET aa.inv_fid__=x.inv_fid, aa.cntrf_round=4;
/*
Query OK, 13 rows affected (12,70 sec)
Rows matched: 13  Changed: 13  Warnings: 0
*/

SELECT SUM(ncount) FROM (
SELECT LEAST(a.inv_fid, b.inv_fid__) AS inv_fid_f, GREATEST(a.inv_fid, b.inv_fid__) AS inv_fid__f, a.EARLIEST_FILING_YEAR, COUNT(DISTINCT b.id) AS ncount
FROM pethprx.t53_sample a
INNER JOIN pethprx.t62_s2 b
ON a.id=b.sample_id
GROUP BY inv_fid_f, inv_fid__f, a.EARLIEST_FILING_YEAR
HAVING ncount>1
ORDER BY ncount DESC) a
LIMIT 100;

SELECT COUNT(*) FROM pethprx.t62_s2 WHERE inv_fid__ IS NULL;
SELECT inv_fid__, COUNT(*) FROM pethprx.t62_s2 GROUP BY inv_fid__ ORDER BY COUNT(*) DESC LIMIT 10;

SELECT * FROM pethprx.t62_s2 WHERE inv_fid__=1 LIMIT 100;
SELECT * FROM pethprx.t53_sample WHERE EARLIEST_FILING_YEAR IS NULL LIMIT 0,10;

-- Remember: in t54_invipc, all inventors have e.inv_all_us=1 AND e.eth_comp=1
-- The join with  pethprx.t55_invyear is to ensure the counterfactual node has also at least one patent 

SELECT * FROM pethprx.t62_s2 LIMIT 10;
SELECT * FROM pethprx.t53_sample LIMIT 10;
SELECT * FROM pethprx.t10_samples LIMIT 10;

--------------------------
-- t63_s3 Sample 3
/*
Small size sample, 
Same as t62 + the focal inventor should be a senior inventor and the non-focal non senior
Senior inventor means being at thetop 10% in the degree distribution t-10, t-1 before the patent t
Non senior meas not being at the top 10%
Same as t62 means (all inventors located in the US, only pairs when the focal inventor is ethnic and the information is available + only inventors who have also patented in the period t-5, t-1 (so to be able to compute other measures)
Attention: this table includes both senior (only in the focal side), non senior (in the non-focal side). It excludes single-patent ever inventors

Notes: to compute, as it takes a lot of time.
*/

DROP TABLE IF EXISTS pethprx.t63_s3;
CREATE TABLE pethprx.t63_s3 (
id SERIAL,
sample_id BIGINT UNSIGNED,
inv_fid__  BIGINT UNSIGNED,
cntrf_round INT
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;
ALTER TABLE pethprx.t63_s3 ADD INDEX(sample_id);
ALTER TABLE pethprx.t63_s3 ADD INDEX(inv_fid__);

INSERT INTO pethprx.t63_s3 (sample_id)
SELECT a.id 
FROM pethprx.t53_sample a 
INNER JOIN pethprx.t55_invyear b
ON (b.tyr_c>0 OR b.tyr_p>0) AND (b.pc_c_10>=0.9 OR b.pc_p_10>=0.9) AND a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR 
INNER JOIN pethprx.t55_invyear c
ON (c.tyr_c>0 OR c.tyr_p>0) AND (c.pc_c_10<0.9 OR c.pc_p_10<0.9) AND a.inv_fid_=c.inv_fid AND a.EARLIEST_FILING_YEAR=c.EARLIEST_FILING_YEAR
WHERE a.ethnic_focal=1 AND a.inv_all_us=1 AND a.eth_comp=1;
/*
Query OK, 26394 rows affected (16,96 sec)
Records: 26394  Duplicates: 0  Warnings: 0

26394 when focal is at the top 10% of the t-10,t-1 degree distribution and the non-focal below the top 10% 
36307 when focal is at the top 10% of the t-10,t-1 degree distribution and the non-focal can be at any position in the distibution
36307 Query OK,  rows affected (17,73 sec)
Records: 36307  Duplicates: 0  Warnings: 0
*/


WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT a.inv_fid, a.ipc7_id, a.EARLIEST_FILING_YEAR
	FROM pethprx.t54_invipc a
	WHERE a.pc_10=0 
	)	
	SELECT DISTINCT l.id, e.inv_fid
	FROM (SELECT * FROM pethprx.t63_s3 LIMIT 101, 100) l
	INNER JOIN pethprx.t51_edir b
	ON l.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	INNER JOIN t2 e
	ON c.ipc7_id=e.ipc7_id AND d.EARLIEST_FILING_YEAR=e.EARLIEST_FILING_YEAR 
	LEFT JOIN pethprx.t53_sample y
	ON b.inv_fid=y.inv_fid AND e.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON b.inv_fid_=z.inv_fid AND e.inv_fid=z.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL)
UPDATE pethprx.t63_s3 aa, LATERAL(
	SELECT m.inv_fid
	FROM t1 m
	WHERE aa.id=m.id
	ORDER BY RAND()
	LIMIT 1
	) x
	SET aa.inv_fid__=x.inv_fid, aa.cntrf_round=1;


-- Remember: in t54_invipc, all inventors have e.inv_all_us=1 AND e.eth_comp=1
-- The join with  pethprx.t55_invyear is to ensure the counterfactual node has also at least one patent 

-- Delete repeated counterfactuals
WITH t3 AS (
WITH t2 AS (
WITH t1 AS (
SELECT LEAST(a.inv_fid, b.inv_fid__) AS inv_fid_f, GREATEST(a.inv_fid, b.inv_fid__) AS inv_fid__f, a.EARLIEST_FILING_YEAR, COUNT(DISTINCT b.id) AS ncount
FROM pethprx.t53_sample a
INNER JOIN pethprx.t63_s3 b
ON a.id=b.sample_id
GROUP BY inv_fid_f, inv_fid__f, a.EARLIEST_FILING_YEAR
HAVING ncount>1
ORDER BY ncount DESC)
SELECT b.id, a.inv_fid, b.inv_fid__, c.ncount
	FROM pethprx.t53_sample a
	INNER JOIN pethprx.t63_s3 b
	ON a.id=b.sample_id
	INNER JOIN t1 c
	ON LEAST(a.inv_fid, b.inv_fid__)=c.inv_fid_f AND GREATEST(a.inv_fid, b.inv_fid__)=c.inv_fid__f)
SELECT DISTINCT x.id
	FROM t2 x
	LEFT JOIN t2 y
	ON x.inv_fid=y.inv_fid AND x.inv_fid__=y.inv_fid__ AND x.id<y.id
	WHERE y.id IS NOT NULL)
UPDATE pethprx.t63_s3 aa
	INNER JOIN t3 bb
	ON aa.id=bb.id
	SET aa.inv_fid__=NULL, aa.cntrf_round=NULL;
/*
Query OK, 36 rows affected (21,15 sec)
Rows matched: 36  Changed: 36  Warnings: 0
*/

UPDATE pethprx.t63_s3 aa
	SET aa.inv_fid__=NULL, aa.cntrf_round=NULL
	WHERE aa.cntrf_round=3;


-- Run again for assign new values to repeated ones
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT a.inv_fid, a.ipc7_id, a.EARLIEST_FILING_YEAR
	FROM pethprx.t54_invipc a
	WHERE a.pc_10=0 
	),
	t3 AS (
	WITH t4 AS (SELECT * FROM pethprx.t63_s3 WHERE inv_fid__ IS NULL)
	SELECT DISTINCT a.id, b.inv_fid, b.inv_fid_, c.ipc7_id, d.EARLIEST_FILING_YEAR
	FROM t4 a
	INNER JOIN pethprx.t51_edir b
	ON a.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	),
	t5 AS (
	SELECT DISTINCT a.inv_fid, b.inv_fid__ AS inv_fid_
	FROM pethprx.t53_sample a
	INNER JOIN pethprx.t63_s3 b
	ON a.id=b.sample_id
	WHERE b.inv_fid__ IS NOT NULL
	)	
	SELECT DISTINCT l.id, e.inv_fid
	FROM t3 l
	INNER JOIN t2 e
	ON l.EARLIEST_FILING_YEAR=e.EARLIEST_FILING_YEAR AND l.ipc7_id=e.ipc7_id
	LEFT JOIN pethprx.t53_sample y
	ON l.inv_fid=y.inv_fid AND e.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON l.inv_fid_=z.inv_fid AND e.inv_fid=z.inv_fid_
	LEFT JOIN t5 yy 
	ON l.inv_fid=yy.inv_fid AND e.inv_fid=yy.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL AND yy.inv_fid_ IS NULL)
UPDATE pethprx.t63_s3 aa
	INNER JOIN LATERAL (
	SELECT m.inv_fid
	FROM t1 m
	WHERE aa.id=m.id
	ORDER BY RAND()
	LIMIT 1
	) x
	ON TRUE
	SET aa.inv_fid__=x.inv_fid, aa.cntrf_round=3;
/*
Query OK, 36 rows affected (15,87 sec)
Rows matched: 36  Changed: 36  Warnings: 0
*/


-- Do matching using IPC4
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT a.inv_fid, g.ipc4_id, a.EARLIEST_FILING_YEAR
	FROM pethprx.t54_invipc a
	INNER JOIN pethprx.t10_ipc7 g
	ON a.ipc7_id=g.id
	WHERE a.pc_10=0
	),
	t3 AS (
	WITH t4 AS (SELECT * FROM pethprx.t63_s3 WHERE inv_fid__ IS NULL LIMIT 100)
	SELECT DISTINCT a.id, b.inv_fid, b.inv_fid_, c.ipc4_id, d.EARLIEST_FILING_YEAR
	FROM t4 a
	INNER JOIN pethprx.t51_edir b
	ON a.sample_id=b.sample_id
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	),
	t5 AS (
	SELECT DISTINCT a.inv_fid, b.inv_fid__ AS inv_fid_
	FROM pethprx.t53_sample a
	INNER JOIN pethprx.t63_s3 b
	ON a.id=b.sample_id
	WHERE b.inv_fid__ IS NOT NULL
	)	
	SELECT DISTINCT l.id, e.inv_fid
	FROM t3 l
	INNER JOIN t2 e
	ON l.EARLIEST_FILING_YEAR=e.EARLIEST_FILING_YEAR AND l.ipc4_id=e.ipc4_id
	LEFT JOIN pethprx.t53_sample y
	ON l.inv_fid=y.inv_fid AND e.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON l.inv_fid_=z.inv_fid AND e.inv_fid=z.inv_fid_
	LEFT JOIN t5 yy 
	ON l.inv_fid=yy.inv_fid AND e.inv_fid=yy.inv_fid_
	WHERE y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL AND yy.inv_fid_ IS NULL)
UPDATE pethprx.t63_s3 aa
	INNER JOIN LATERAL (
	SELECT m.inv_fid
	FROM t1 m
	WHERE aa.id=m.id
	ORDER BY RAND()
	LIMIT 1
	) x
	ON TRUE
	SET aa.inv_fid__=x.inv_fid, aa.cntrf_round=4;
/*
Query OK, 2 rows affected (9,88 sec)
Rows matched: 2  Changed: 2  Warnings: 0
*/

SELECT COUNT(*) FROM pethprx.t63_s3 WHERE inv_fid__ IS NULL;


-- And run again the delete repeated values to check (in this case there were not more repeated values, so it was fine)

-- Insert counterfactual undirected links into t52_eudir to create eudir ids. In principle, all rows from t63_s3 should appear in t52_eudir 
INSERT INTO pethprx.t52_eudir (inv_fid, inv_fid_, EARLIEST_FILING_YEAR, cntrf)
WITH t1 AS (
SELECT DISTINCT LEAST(a.inv_fid, b.inv_fid__) AS inv_fid, GREATEST(a.inv_fid, b.inv_fid__) AS inv_fid_, a.EARLIEST_FILING_YEAR
FROM pethprx.t53_sample a
INNER JOIN pethprx.t63_s3 b
ON a.id=b.sample_id
)
SELECT a.inv_fid, a.inv_fid_ , a.EARLIEST_FILING_YEAR, 1
	FROM t1 a
	LEFT JOIN pethprx.t52_eudir b
	ON a.inv_fid=b.inv_fid AND a.inv_fid_=b.inv_fid_ AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	WHERE b.inv_fid IS NULL OR b.inv_fid_ IS NULL OR b.EARLIEST_FILING_YEAR IS NULL;
/*
Query OK, 26394 rows affected (3,84 sec)
Records: 26394  Duplicates: 0  Warnings: 0
*/

ALTER TABLE pethprx.t63_s3 ADD COLUMN eudir_id BIGINT UNSIGNED;
UPDATE pethprx.t63_s3 x
	INNER JOIN pethprx.t53_sample a
	ON x.sample_id=a.id
	INNER JOIN pethprx.t52_eudir b
	ON LEAST(a.inv_fid, x.inv_fid__)=b.inv_fid AND GREATEST(a.inv_fid, x.inv_fid__)=b.inv_fid_ AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	SET x.eudir_id=b.id
	WHERE b.cntrf=1;
/*
Query OK, 26394 rows affected (0,99 sec)
Rows matched: 26394  Changed: 26394  Warnings: 0
*/
ALTER TABLE pethprx.t63_s3 ADD INDEX(eudir_id);

SELECT * FROM pethprx.t63_s3 WHERE eudir_id IS NULL LIMIT 10;

SELECT a.* 
	FROM pethprx.t63_s3 x
	INNER JOIN pethprx.t53_sample a
	ON x.sample_id=a.id
	WHERE x.eudir_id IS NULL LIMIT 10;

SELECT * FROM pethprx.t63_s3 LIMIT 98, 10;
SELECT inv_fid__, COUNT(*) FROM pethprx.t63_s3 GROUP BY inv_fid__ ORDER BY COUNT(*) DESC LIMIT 10;

--------------------------
-- t73_s3c Sample 3 ready to run regressions 
/*
Attention: Here the relevant variable is collaborations
*/
DROP TABLE IF EXISTS pethprx.t73_s3c;
CREATE TABLE pethprx.t73_s3c AS 
SELECT DISTINCT 1 AS linked, b.eudir_id, NULL AS eudir_id_cc, c.inv_fid, c.inv_fid_, c.EARLIEST_FILING_YEAR
FROM pethprx.t63_s3 a
INNER JOIN pethprx.t53_sample  b
ON a.sample_id=b.id
INNER JOIN pethprx.t55_invyear d
ON d.tyr_c>0 AND d.pc_c_10>=0.9 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
INNER JOIN  pethprx.t52_eudir c
ON b.eudir_id=c.id
UNION
SELECT DISTINCT 0 AS linked, c.id AS eudir_id, b.eudir_id AS eudir_id_cc, c.inv_fid, c.inv_fid_, c.EARLIEST_FILING_YEAR 
FROM pethprx.t63_s3 a
INNER JOIN pethprx.t53_sample  b
ON a.sample_id=b.id
INNER JOIN pethprx.t55_invyear d
ON d.tyr_c>0 AND d.pc_c_10>=0.9 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR
INNER JOIN  pethprx.t52_eudir c
ON a.eudir_id=c.id;
/*
Query OK, 20273 rows affected (1,91 sec)
Records: 20273  Duplicates: 0  Warnings: 0
*/
ALTER TABLE pethprx.t73_s3c ADD INDEX(eudir_id);
ALTER TABLE pethprx.t73_s3c ADD INDEX(eudir_id_cc);
ALTER TABLE pethprx.t73_s3c ADD INDEX(inv_fid);
ALTER TABLE pethprx.t73_s3c ADD INDEX(inv_fid_);
ALTER TABLE pethprx.t73_s3c ADD INDEX(EARLIEST_FILING_YEAR);

ALTER TABLE pethprx.t73_s3c
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
UPDATE pethprx.t73_s3c a
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
Query OK, 20273 rows affected (2,29 sec)
Rows matched: 20273  Changed: 20273  Warnings: 0
*/

UPDATE pethprx.t73_s3c a
	SET a.geodis=NULL;
UPDATE pethprx.t73_s3c a
	INNER JOIN pethprx.t55_invyear b
	ON a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	INNER JOIN riccaboni2017.t20_addr f
	ON b.addr_id=f.id
	INNER JOIN pethprx.t55_invyear c
	ON a.inv_fid_=c.inv_fid AND a.EARLIEST_FILING_YEAR=c.EARLIEST_FILING_YEAR
	INNER JOIN riccaboni2017.t20_addr g
	ON c.addr_id=g.id
	SET a.geodis=ST_Distance(f.geom, g.geom);
/*
Query OK, 20273 rows affected (4,10 sec)
Rows matched: 20273  Changed: 20273  Warnings: 0
*/

-- Ethnic
UPDATE pethprx.t73_s3c a
SET a.ethnic=NULL;

UPDATE pethprx.t73_s3c a
	INNER JOIN pethprx.t30_inv_name b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t30_inv_name c
	ON a.inv_fid_=c.inv_fid
SET a.ethnic=1
WHERE b.celgr_id_max=c.celgr_id_max AND b.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 2457 rows affected (0,26 sec)
Rows matched: 2457  Changed: 2457  Warnings: 0
*/

UPDATE pethprx.t73_s3c a
	INNER JOIN pethprx.t30_inv_name b
	ON a.inv_fid=b.inv_fid
	INNER JOIN pethprx.t30_inv_name c
	ON a.inv_fid_=c.inv_fid
SET a.ethnic=0
WHERE b.celgr_id_max!=c.celgr_id_max;
/*
Query OK, 17816 rows affected (0,50 sec)
Rows matched: 17816  Changed: 17816  Warnings: 0
*/

-- Institutional
/*
TO DO:
Clean categories in the future
+---------------------------+----------+
| PSN_SECTOR                | COUNT(*) |
+---------------------------+----------+
| COMPANY                   |   233760 |
| INDIVIDUAL                |     2712 |
| UNIVERSITY                |     3456 |
| GOV NON-PROFIT            |      822 |
| COMPANY GOV NON-PROFIT    |      178 |
| HOSPITAL                  |       64 |
| GOV NON-PROFIT UNIVERSITY |       20 |
+---------------------------+----------+
7 rows in set (9,88 sec)
*/
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3c
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3c
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
UPDATE pethprx.t73_s3c x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.PSN_SECTOR=z.PSN_SECTOR
SET x.insprox=1;
/*
Query OK, 19571 rows affected (9,79 sec)
Rows matched: 19571  Changed: 19571  Warnings: 0
*/

UPDATE pethprx.t73_s3c x
SET x.insprox=0
WHERE x.insprox IS NULL;
/*
Query OK, 702 rows affected (0,06 sec)
Rows matched: 702  Changed: 702  Warnings: 0
*/

-- Technological
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3c
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3c
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
UPDATE pethprx.t73_s3c x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.ipc7_id=z.ipc7_id
SET x.techprox=1;
/*
Query OK, 15762 rows affected (16,10 sec)
Rows matched: 15762  Changed: 15762  Warnings: 0
*/

UPDATE pethprx.t73_s3c x
SET x.techprox=0
WHERE x.techprox IS NULL;
/*
Query OK, 4511 rows affected (0,13 sec)
Rows matched: 4511  Changed: 4511  Warnings: 0
*/

-- Same applicant
WITH t1 AS (
	WITH t2 AS (
	SELECT DISTINCT inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3c
	UNION	
	SELECT DISTINCT inv_fid_  AS inv_fid, EARLIEST_FILING_YEAR FROM pethprx.t73_s3c
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
UPDATE pethprx.t73_s3c x
	INNER JOIN t1 y
	ON x.inv_fid=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
	INNER JOIN t1 z
	ON x.inv_fid_=z.inv_fid AND x.EARLIEST_FILING_YEAR=z.EARLIEST_FILING_YEAR AND y.app_id=z.app_id
SET x.same_appl=1;
/*
Query OK, 9640 rows affected (9,40 sec)
Rows matched: 9640  Changed: 9640  Warnings: 0
*/

UPDATE pethprx.t73_s3c x
SET x.same_appl=0
WHERE x.same_appl IS NULL;
/*
Query OK, 10633 rows affected (0,18 sec)
Rows matched: 10633  Changed: 10633  Warnings: 0
*/


-- Social distance
-- https://stackoverflow.com/questions/2370876/find-path-between-nodes-with-sql
-- https://stackoverflow.com/questions/59506079/mysql-shortest-path-between-two-nodes
-- https://stackoverflow.com/questions/45933491/path-finding-via-sql-query
DROP TABLE IF EXISTS pethprx.t73_s3c_sd;
CREATE TABLE IF NOT EXISTS pethprx.t73_s3c_sd
(
inv_fid BIGINT UNSIGNED,
inv_fid_ BIGINT UNSIGNED,
socialdist INT,
EARLIEST_FILING_YEAR INT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE pethprx.t73_s3c_sd ADD INDEX(inv_fid);
ALTER TABLE pethprx.t73_s3c_sd ADD INDEX(inv_fid_);
ALTER TABLE pethprx.t73_s3c_sd ADD INDEX(EARLIEST_FILING_YEAR);

LOAD DATA LOCAL INFILE '/mnt/hdd2/repositories/christian/p_ethprx/output/graphs/distance_list/c_list.csv' INTO TABLE pethprx.t73_s3c_sd
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'  ESCAPED BY ''
lines terminated by '\n'
IGNORE 1 LINES ;
SHOW WARNINGS;
/*
Query OK, 5722198 rows affected (21,34 sec)
Records: 5722198  Deleted: 0  Skipped: 0  Warnings: 0
*/
UPDATE pethprx.t73_s3c x
	INNER JOIN pethprx.t73_s3c_sd y
	ON x.inv_fid=y.inv_fid AND x.inv_fid_=y.inv_fid_ AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
SET x.socialdist=y.socialdist;
/*
Query OK, 13623 rows affected (44,04 sec)
Rows matched: 13623  Changed: 13623  Warnings: 0
*/

UPDATE pethprx.t73_s3c x
	INNER JOIN pethprx.t73_s3c_sd y
	ON x.inv_fid=y.inv_fid_ AND x.inv_fid_=y.inv_fid AND x.EARLIEST_FILING_YEAR=y.EARLIEST_FILING_YEAR
SET x.socialdist=y.socialdist;
/*
Query OK, 0 rows affected (42,55 sec)
Rows matched: 1080  Changed: 0  Warnings: 0
*/

UPDATE pethprx.t73_s3c x
SET x.socialdist=999 WHERE x.socialdist IS NULL;
/*
Query OK, 6650 rows affected (0,11 sec)
Rows matched: 6650  Changed: 6650  Warnings: 0
*/

ALTER TABLE pethprx.t73_s3c
	ADD COLUMN soc_2 BOOL,
	ADD COLUMN soc_3 BOOL,
	ADD COLUMN soc_4 BOOL,
	ADD COLUMN soc_5m BOOL;

UPDATE pethprx.t73_s3c x
SET x.soc_2=1 WHERE x.socialdist=2;

UPDATE pethprx.t73_s3c x
SET x.soc_3=1 WHERE x.socialdist=3;

UPDATE pethprx.t73_s3c x
SET x.soc_4=1 WHERE x.socialdist=4;

UPDATE pethprx.t73_s3c x
SET x.soc_5m=1 WHERE x.socialdist>4;

UPDATE pethprx.t73_s3c x
SET x.soc_2=0 WHERE x.socialdist!=2;

UPDATE pethprx.t73_s3c x
SET x.soc_3=0 WHERE x.socialdist!=3;

UPDATE pethprx.t73_s3c x
SET x.soc_4=0 WHERE x.socialdist!=4;

UPDATE pethprx.t73_s3c x
SET x.soc_5m=0 WHERE x.socialdist<4;

/*
mysql> UPDATE pethprx.t73_s3c x
    -> SET x.soc_2=1 WHERE x.socialdist=2;
Query OK, 3623 rows affected (0,10 sec)
Rows matched: 3623  Changed: 3623  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3c x
    -> SET x.soc_3=1 WHERE x.socialdist=3;
Query OK, 1793 rows affected (0,05 sec)
Rows matched: 1793  Changed: 1793  Warnings: 0

UPDATE pethprx.t73_s3c x
SET x.soc_4=1 WHERE x.socialdist=4;
Query OK, 1229 rows affected (0,05 sec)
Rows matched: 1229  Changed: 1229  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3c x
    -> SET x.soc_5m=1 WHERE x.socialdist>4;
Query OK, 13628 rows affected (0,25 sec)
Rows matched: 13628  Changed: 13628  Warnings: 0

mysql> UPDATE pethprx.t73_s3c x
    -> SET x.soc_2=0 WHERE x.socialdist!=2;
Query OK, 16650 rows affected (0,28 sec)
Rows matched: 16650  Changed: 16650  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3c x
    -> SET x.soc_3=0 WHERE x.socialdist!=3;
Query OK, 18480 rows affected (0,32 sec)
Rows matched: 18480  Changed: 18480  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3c x
    -> SET x.soc_4=0 WHERE x.socialdist!=4;
Query OK, 19044 rows affected (0,32 sec)
Rows matched: 19044  Changed: 19044  Warnings: 0

mysql>
mysql> UPDATE pethprx.t73_s3c x
    -> SET x.soc_5m=0 WHERE x.socialdist<4;
Query OK, 5416 rows affected (0,12 sec)
Rows matched: 5416  Changed: 5416  Warnings: 0
*/

ALTER TABLE pethprx.t73_s3c
	ADD COLUMN fcfinv BIGINT UNSIGNED,
	ADD COLUMN celgr_id_max_fcfinv INT UNSIGNED;


UPDATE pethprx.t73_s3c a
SET a.fcfinv=NULL;
UPDATE pethprx.t73_s3c b
	INNER JOIN pethprx.t55_invyear d
	ON d.tyr_c>0 AND d.pc_c_10>=0.9 AND b.inv_fid_=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
	INNER JOIN pethprx.t30_inv_name c
	ON b.inv_fid_=c.inv_fid
SET b.fcfinv=b.inv_fid_
WHERE c.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 8230 rows affected (0,55 sec)
Rows matched: 8230  Changed: 8230  Warnings: 0
*/
UPDATE pethprx.t73_s3c b
	INNER JOIN pethprx.t55_invyear d
	ON d.tyr_c>0 AND d.pc_c_10>=0.9 AND b.inv_fid=d.inv_fid AND b.EARLIEST_FILING_YEAR=d.EARLIEST_FILING_YEAR 
	INNER JOIN pethprx.t30_inv_name c
	ON b.inv_fid=c.inv_fid
SET b.fcfinv=b.inv_fid
WHERE c.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 12134 rows affected (0,67 sec)
Rows matched: 12134  Changed: 12134  Warnings: 0
*/

-- Ethnicity focal node
UPDATE pethprx.t73_s3c a
SET a.celgr_id_max_fcfinv=NULL;

UPDATE pethprx.t73_s3c a
	INNER JOIN pethprx.t30_inv_name b
	ON a.fcfinv=b.inv_fid
SET a.celgr_id_max_fcfinv=b.celgr_id_max
WHERE b.celgr_id_max IN (3, 8, 10, 17, 23, 26, 27, 28, 29, 36, 38, 39);
/*
Query OK, 20273 rows affected (0,51 sec)
Rows matched: 20273  Changed: 20273  Warnings: 0
*/




SELECT * FROM pethprx.t73_s3c WHERE celgr_id_max_fcfinv IS NULL LIMIT 0,10;
SELECT linked, COUNT(*) FROM pethprx.t73_s3c WHERE celgr_id_max_fcfinv IS NULL GROUP BY linked; 

WITH t1 AS (
	SELECT DISTINCT a.inv_fid__ AS inv_fid, c.EARLIEST_FILING_YEAR  
	FROM pethprx.t63_s3 a
	INNER JOIN pethprx.t53_sample c
	ON a.sample_id=c.id
	UNION
	SELECT DISTINCT c.inv_fid AS inv_fid, c.EARLIEST_FILING_YEAR FROM pethprx.t63_s3 b
	INNER JOIN pethprx.t53_sample c
	ON b.sample_id=c.id
	UNION
	SELECT DISTINCT c.inv_fid_ AS inv_fid, c.EARLIEST_FILING_YEAR FROM pethprx.t63_s3 b
	INNER JOIN pethprx.t53_sample c
	ON b.sample_id=c.id
	)
SELECT DISTINCT b.addr_id, c.loc, c.lat, c.lon 
	FROM t1 a
	INNER JOIN pethprx.t55_invyear b
	ON a.inv_fid=b.inv_fid AND a.EARLIEST_FILING_YEAR=b.EARLIEST_FILING_YEAR
	INNER JOIN riccaboni2017.t20_addr c
	ON b.addr_id=c.id 
INTO OUTFILE '/var/lib/mysql-files/ernest_addr_id_new.csv'
            FIELDS TERMINATED BY ','
            ENCLOSED BY '"'
            LINES TERMINATED BY '\n';
/*
Query OK, 22795 rows affected (3,15 sec)
*/


SELECT COUNT(*) FROM pethprx.t73_s3c; 
SELECT linked, COUNT(*) FROM pethprx.t73_s3c GROUP BY linked; 
SELECT * FROM pethprx.t73_s3c_sd LIMIT 0,10;
SELECT * FROM pethprx.t73_s3c LIMIT 0,10;
SHOW INDEX FROM pethprx.t54_invipc;


---------------------------------------------------------------------------------------------------

mysqldump -u root -p pethprx > '/mnt/hdd2/repositories/christian/p_ethprx/dbdump/pethprx-202005052002.sql'
mysqldump -u root -p riccaboni2017 > '/mnt/hdd2/repositories/christian/p_ethprx/dbdump/riccaboni2017-202005052002.sql'
