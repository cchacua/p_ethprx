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
celgr_text VARCHAR(100)
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

-- This can be joined with the directed links table, but it may not be necessary
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

--------------------------
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

ALTER TABLE pethprx.t53_sample ADD COLUMN cntrf_round INT AFTER inv_fid__;

UPDATE pethprx.t53_sample a,
	LATERAL(
	SELECT h.inv_fid
	FROM pethprx.t51_edir b
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	INNER JOIN pethprx.t54_invipc h
	ON c.ipc7_id=h.ipc7_id AND d.EARLIEST_FILING_YEAR=h.EARLIEST_FILING_YEAR 
	LEFT JOIN pethprx.t53_sample y
	ON b.inv_fid=y.inv_fid AND h.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON b.inv_fid_=z.inv_fid AND h.inv_fid=z.inv_fid_
	WHERE a.id=b.sample_id AND d.inv_all_us=1 AND d.eth_comp=1 AND y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL
	ORDER BY RAND() LIMIT 1
	) x
	SET a.inv_fid__=x.inv_fid AND a.cntrf_round=1
	WHERE a.ethnic_focal=1 and a.inv_all_us=1 and a.eth_comp=1;
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

*/

SELECT DISTINCT a.inv_fid, a.inv_fid_, a.EARLIEST_FILING_YEAR , x.inv_fid AS inv_fid__
	FROM pethprx.t53_sample a,
	LATERAL(
	SELECT h.inv_fid
	FROM pethprx.t51_edir b
	INNER JOIN pethprx.t01_samples d
	ON b.pat_id=d.pat_id
	INNER JOIN pethprx.t10_samples c
	ON d.pat_id=c.pat_id
	INNER JOIN pethprx.t54_invipc h
	ON c.ipc7_id=h.ipc7_id AND d.EARLIEST_FILING_YEAR=h.EARLIEST_FILING_YEAR 
	LEFT JOIN pethprx.t53_sample y
	ON b.inv_fid=y.inv_fid AND h.inv_fid=y.inv_fid_
	LEFT JOIN pethprx.t53_sample z
	ON b.inv_fid_=z.inv_fid AND h.inv_fid=z.inv_fid_
	WHERE a.id=b.sample_id AND d.inv_all_us=1 AND d.eth_comp=1 AND y.inv_fid_ IS NULL AND z.inv_fid_ IS NULL
	ORDER BY RAND() LIMIT 1
	) x
	WHERE a.ethnic_focal=1 and a.inv_all_us=1 and a.eth_comp=1
	LIMIT 30;


SELECT DISTINCT a.inv_fid, a.inv_fid_, a.EARLIEST_FILING_YEAR
	FROM pethprx.t53_sample a
	INNER JOIN pethprx.t51_edir b
	ON a.id=b.sample_id
	INNER JOIN pethprx.t10_samples c
	ON b.pat_id=c.pat_id
	WHERE a.ethnic_focal=1 and a.inv_all_us=1 and a.eth_comp=1
	LIMIT 30;

SELECT * FROM pethprx.t53_sample WHERE inv_fid=50063;
SELECT * FROM pethprx.t53_sample WHERE inv_fid=4014766;


SELECT COUNT(*) FROM pethprx.t53_sample a WHERE a.ethnic_focal=1 AND a.inv_all_us=1 AND a.eth_comp=1;

SELECT * FROM pethprx.t53_sample LIMIT 0,10;
SELECT * FROM pethprx.t54_invipc LIMIT 0,10;
SELECT * FROM pethprx.t01_samples LIMIT 0,10;
SELECT * FROM pethprx.t51_edir LIMIT 0,10;

SHOW INDEX FROM pethprx.t54_invipc;

ALTER TABLE pethprx.t51_edir ADD INDEX(sample_id);

-- Main table for the link inventor patent or year
-- At the level of final ID
-- One address per link
-- I take the list from t51_edir, as they are supposed to have collaborated with anyone else
	-- EXPAND IPC codes
	-- JOIN USING IPC AND YEAR ANOTHER NODE IN THE SAME FIELD
	-- LEFT JOIN ON t52_eudir during specific time window and keep only null (links not present)
-- inv_fid->t08 to get pat_id ->t01_sample-to get pat_id and years (on both conditions) -> with that patent list: comparisons
-- Counterfactual for everysingle node no matter if they are ethnic?
---------------------------------------------------------------------------------------------------

mysqldump -u root -p pethprx > '/mnt/hdd2/repositories/christian/p_ethprx/dbdump/pethprx-202005052002.sql'
mysqldump -u root -p riccaboni2017 > '/mnt/hdd2/repositories/christian/p_ethprx/dbdump/riccaboni2017-202005052002.sql'
