-----------------------------------------------------------------------------------------------
-- COUNTS
-----------------------------------------------------------------------------------------------

SELECT COUNT(DISTINCT a.pat), LEFT(a.pat,2)
	FROM riccaboni2017.t01 a
	INNER JOIN riccaboni2017.t01_APPLNID b
	ON a.pat_id=b.pat_id
	GROUP BY LEFT(a.pat,2);
/*

*/

SELECT COUNT(DISTINCT a.pat), LEFT(a.pat,2)
	FROM riccaboni2017.t01 a
	LEFT JOIN riccaboni2017.t01_APPLNID b
	ON a.pat_id=b.pat_id
	WHERE b.pat_id IS NULL
	GROUP BY LEFT(a.pat,2);
/*
+-----------------------+---------------+
| COUNT(DISTINCT a.pat) | LEFT(a.pat,2) |
+-----------------------+---------------+
|                     5 | EP            |
|                261636 | US            |
|                    18 | WO            |
+-----------------------+---------------+
3 rows in set (37,25 sec)
*/


SELECT COUNT(DISTINCT a.pat_id) 
	FROM riccaboni2017.t01 a
	INNER JOIN riccaboni2017.t01_APPLNID c
	ON a.pat_id=c.pat_id
	INNER JOIN patstat2018b.TLS201_APPLN d
	ON c.APPLN_ID=d.APPLN_ID AND a.yr=d.APPLN_FILING_YEAR;
/*
+--------------------------+
| COUNT(DISTINCT a.pat_id) |
+--------------------------+
|                  8723989 |
+--------------------------+
1 row in set (59,29 sec)

8794464-8723989= 70475 patents have a different date
The second round by constraint requires having the same filing year
*/

SELECT COUNT(DISTINCT a.pat), LEFT(a.pat,2)
	FROM riccaboni2017.t01 a
	INNER JOIN riccaboni2017.t01_APPLNID c
	ON a.pat_id=c.pat_id
	INNER JOIN patstat2018b.TLS201_APPLN d
	ON c.APPLN_ID=d.APPLN_ID AND a.yr=d.APPLN_FILING_YEAR
	GROUP BY LEFT(a.pat,2);
/*
+-----------------------+---------------+
| COUNT(DISTINCT a.pat) | LEFT(a.pat,2) |
+-----------------------+---------------+
|               2683467 | EP            |
|               3679040 | US            |
|               2361482 | WO            |
+-----------------------+---------------+
3 rows in set (56,32 sec)
*/


SELECT * FROM oecd_cit201907.US_CIT_COUNTS WHERE us_pub_nbr='US3858241';
SELECT * FROM oecd_cit201907.US_CIT_COUNTS LIMIT 0,10;

SELECT * FROM oecd_cit201907.US_EQUIVALENTS WHERE cited_appln_id='US03858241';

SELECT * FROM patstat2018b.TLS202_APPLN_TITLE WHERE APPLN_TITLE='SHOCK ABSORBENT COLLAR FOR ARMOR PLATE' LIMIT 0,30;

SELECT * FROM oecd_cit201907.US_CIT_COUNTS WHERE us_appln_id=51017751 LIMIT 0,30;

SELECT * FROM patstat2018b.TLS211_PAT_PUBLN WHERE APPLN_ID=51017751 LIMIT 0,30;

SELECT TRIM(LEADING '0' FROM myfield) 
	FROM riccaboni2017.t01 a
	INNER JOIN 
	ON a.=b.;

-----------------------------------------------------------------------------------------------
-- ALTER TABLE patstat2018b.TLS201_APPLN ADD INDEX(pat_id);





+-----------------------+---------------+
| COUNT(DISTINCT a.pat) | LEFT(a.pat,2) |
+-----------------------+---------------+
|                     5 | EP            |
|                261636 | US            |
|                    18 | WO            |
+-----------------------+---------------+
3 rows in set (19,99 sec)


SELECT COUNT(DISTINCT pat_id) FROM riccaboni2017.t01_APPLNID_ WHERE APPLN_ID<900000000; 
/*
+------------------------+
| COUNT(DISTINCT pat_id) |
+------------------------+
|                 234145 |
+------------------------+
1 row in set (0,20 sec)
*/

SELECT a.*
	FROM riccaboni2017.t01 a
	LEFT JOIN riccaboni2017.t01_APPLNID b
	ON a.pat_id=b.pat_id
	WHERE b.pat_id IS NULL AND LEFT(a.pat,2)='US'
	LIMIT 0,30;

US3861032A
US3861032 1973
SELECT * FROM patstat2018b.TLS202_APPLN_TITLE WHERE APPLN_TITLE='Method of manufacturing and testing thermal fuses' LIMIT 0,30;

SELECT * FROM patstat2018b.TLS211_PAT_PUBLN WHERE APPLN_ID IN (4002922, 50661178) LIMIT 0,30;

SELECT * FROM patstat2018b.TLS201_APPLN WHERE APPLN_ID IN (4002922, 50661178) LIMIT 0,30;




SELECT a.*
	FROM riccaboni2017.t01 a
	LEFT JOIN riccaboni2017.t01_APPLNID b
	ON a.pat_id=b.pat_id
	WHERE b.pat_id IS NULL AND LEFT(a.pat,2)='US'
	LIMIT 0,10;

-----------------------------------------------
SELECT * FROM patstat2018b.TLS202_APPLN_TITLE WHERE APPLN_TITLE='Method for Removing Nitric Oxide from Combustion Gases' LIMIT 0,30;
/*
+----------+----------------+--------------------------------------------------------+
| APPLN_ID | APPLN_TITLE_LG | APPLN_TITLE                                            |
+----------+----------------+--------------------------------------------------------+
| 49266606 | en             | Method for Removing Nitric Oxide from Combustion Gases |
+----------+----------------+--------------------------------------------------------+
1 row in set (1 min 16,04 sec)
*/
SELECT * FROM patstat2018b.TLS211_PAT_PUBLN WHERE APPLN_ID IN (49266606) LIMIT 0,30;
/*
+--------------+------------+----------+-------------------+------------+----------+------------+----------+-------------------+--------------+
| PAT_PUBLN_ID | PUBLN_AUTH | PUBLN_NR | PUBLN_NR_ORIGINAL | PUBLN_KIND | APPLN_ID | PUBLN_DATE | PUBLN_LG | PUBLN_FIRST_GRANT | PUBLN_CLAIMS |
+--------------+------------+----------+-------------------+------------+----------+------------+----------+-------------------+--------------+
|    313456039 | US         | 3864451  |                   | A          | 49266606 | 1975-02-04 |          | Y                 | 3            |
+--------------+------------+----------+-------------------+------------+----------+------------+----------+-------------------+--------------+
1 row in set (0,02 sec)
*/

SELECT * FROM patstat2018b.TLS201_APPLN WHERE APPLN_ID IN (49266606) LIMIT 0,30;
/*
*/

SELECT b.*
	FROM riccaboni2017.t01 a
	LEFT JOIN riccaboni2017.t08 b
	ON a.pat_id=b.pat_id
	WHERE b.pat_id=2690968
	LIMIT 0,10;


SELECT COUNT(DISTINCT a.pat_id), a.yr
    FROM riccaboni2017.t01 a
    LEFT JOIN riccaboni2017.t01_APPLNID c 
    ON  a.pat_id=c.pat_id
    WHERE LEFT(a.pat,2)='US' AND c.pat_id IS NULL
    GROUP BY a.yr;  

SELECT COUNT(DISTINCT a.pat_id)
    FROM  riccaboni2017.t01_APPLNID a;

SELECT COUNT(DISTINCT b.pat), CHAR_LENGTH(b.pat) AS Nchar
	FROM riccaboni2017.t01 b
	WHERE LEFT(b.pat,2)='US'
	GROUP BY CHAR_LENGTH(b.pat);


-----------------------------------------------------------------------------------------------
ALTER TABLE riccaboni2017.t01_APPLNID ADD COLUMN DOCDB_FAMILY_ID INT(11) UNSIGNED AFTER APPLN_ID;
UPDATE riccaboni2017.t01_APPLNID a INNER JOIN patstat2018b.TLS201_APPLN b ON a.APPLN_ID=b.APPLN_ID SET a.DOCDB_FAMILY_ID=b.DOCDB_FAMILY_ID;
ALTER TABLE riccaboni2017.t01_APPLNID ADD INDEX(DOCDB_FAMILY_ID);

