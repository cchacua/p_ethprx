-----------------------------------------------------------------------------------------------
-- t01_APPLNID
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Round 1: First round of matches
-- This is the table that I used in the original version of the paper

SHOW INDEX FROM riccaboni2017.t01; 
SHOW INDEX FROM oecd_cit201907.EP_CIT_COUNTS;
SHOW INDEX FROM oecd_cit201907.US_CIT_COUNTS;
SHOW INDEX FROM oecd_cit201907.WO_CITATIONS;

DROP TABLE IF EXISTS riccaboni2017.t01_APPLNID; 
CREATE TABLE riccaboni2017.t01_APPLNID AS
SELECT DISTINCT a.pat_id, b.ep_appln_id AS APPLN_ID
    FROM riccaboni2017.t01 a
    INNER JOIN oecd_cit201907.EP_CIT_COUNTS b
    ON a.pat=b.ep_pub_nbr
UNION
SELECT DISTINCT a.pat_id, b.us_appln_id AS APPLN_ID
    FROM riccaboni2017.t01 a
    INNER JOIN oecd_cit201907.US_CIT_COUNTS b
    ON a.pat=CONCAT(LEFT(b.us_pub_nbr,2), LPAD(RIGHT(b.us_pub_nbr, CHAR_LENGTH(b.us_pub_nbr)-2), 8, '0'))
    WHERE CHAR_LENGTH(b.us_pub_nbr)<=10
UNION
SELECT DISTINCT a.pat_id, c.citing_appln_id AS APPLN_ID
    FROM riccaboni2017.t01 a
    INNER JOIN oecd_cit201907.WO_CITATIONS c
    ON  a.pat=c.citing_pub_nbr;   

/*
Query OK, 8794464 rows affected (3 min 57,75 sec)
Records: 8794464  Duplicates: 0  Warnings: 0
*/

SHOW INDEX FROM riccaboni2017.t01_APPLNID; 
ALTER TABLE riccaboni2017.t01_APPLNID ADD INDEX(pat_id);
ALTER TABLE riccaboni2017.t01_APPLNID ADD INDEX(APPLN_ID);
ALTER TABLE riccaboni2017.t01_APPLNID ADD COLUMN mround INT(2) UNSIGNED AFTER APPLN_ID;
UPDATE riccaboni2017.t01_APPLNID SET mround=1;
ALTER TABLE riccaboni2017.t01_APPLNID ADD INDEX(mround);
/*
Query OK, 8794464 rows affected (4 min 36,35 sec)
Rows matched: 8794464  Changed: 8794464  Warnings: 0
*/
SHOW WARNINGS;

-----------------------------------------------------------------------------------------------
-- Round 2

SHOW INDEX FROM riccaboni2017.t01; 
-- ALTER TABLE riccaboni2017.t01 ADD INDEX(yr);
SHOW INDEX FROM patstat2018b.TLS211_PAT_PUBLN;
SHOW INDEX FROM patstat2018b.TLS201_APPLN; 
-- ALTER TABLE patstat2018b.TLS201_APPLN ADD INDEX(APPLN_FILING_YEAR);

INSERT INTO riccaboni2017.t01_APPLNID(pat_id, APPLN_ID, mround)
SELECT DISTINCT a.pat_id, c.APPLN_ID, 2 AS mround
	FROM riccaboni2017.t01 a
	LEFT JOIN riccaboni2017.t01_APPLNID b
	ON a.pat_id=b.pat_id
	INNER JOIN patstat2018b.TLS211_PAT_PUBLN c
	ON a.pat=CONCAT(c.PUBLN_AUTH, LPAD(c.PUBLN_NR, 8, 0))
	INNER JOIN patstat2018b.TLS201_APPLN d
	ON c.APPLN_ID=d.APPLN_ID AND a.yr=d.APPLN_FILING_YEAR
	WHERE b.pat_id IS NULL AND c.PUBLN_AUTH='US';
/*
Query OK, 234145 rows affected (8 min 24,46 sec)
Records: 234145  Duplicates: 0  Warnings: 0
*/

SHOW INDEX FROM riccaboni2017.t01_APPLNID; 


-----------------------------------------------------------------------------------------------
-- Counts
SELECT * FROM riccaboni2017.t01_APPLNID LIMIT 0,10; 
SELECT COUNT(*) FROM riccaboni2017.t01_APPLNID WHERE APPLN_ID>900000000;
SELECT COUNT(DISTINCT pat_id) FROM riccaboni2017.t01_APPLNID; 
/*
+------------------------+
| COUNT(DISTINCT pat_id) |
+------------------------+
|                9028609 |
+------------------------+
1 row in set (4,57 sec)
*/

SELECT COUNT(DISTINCT pat_id) FROM riccaboni2017.t01; 
/*
+------------------------+
| COUNT(DISTINCT pat_id) |
+------------------------+
|                9290268 |
+------------------------+
1 row in set (5,91 sec)
*/

