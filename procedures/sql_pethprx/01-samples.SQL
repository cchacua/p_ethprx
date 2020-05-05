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
-- Main table for sample at the patent level
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
-- Main table for sample at the inventor level
---------------------------------------------------------------------------------------------------


