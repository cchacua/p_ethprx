CREATE DATABASE pethprx;
GRANT ALL PRIVILEGES ON pethprx.* TO 'christian';	



-- 
CREATE TABLE pethprx.t01_applnidsamples AS
SELECT DISTINCT a.APPLN_ID, 1 AS ctt
FROM riccaboni.t01 a 
INNER JOIN riccaboni2017.t01_APPLNID b
ON a.pat=b.pat
WHERE b.round=1 AND CONCAT(',', a.classes, ',') REGEXP ',4,|,9,|,3,'
UNION 
SELECT DISTINCT a.APPLN_ID, 0 AS ctt
FROM riccaboni.t01 a 
INNER JOIN riccaboni2017.t01_APPLNID b
ON a.pat=b.pat
WHERE b.round=1 AND WHERE CONCAT(',', a.classes, ',') REGEXP ',13,|,29,';
/*
-- ATTENTION: 
APPLN_ID: Here I am only keeping the appln_ids of round 1 of matches from t01_APPLNID
CTT or PBOC: Here ctt=1 if the pat should be included in the ctt sample and 0 otherwise
Time span: Only between 1975 and 2010
Location All US-


---------------------------------------------------------------------------------------------------
-- CLASSES
0 - Pharmaceuticals, biotechnology and organic fine chemistry
| Pharmaceuticals                         | 4  |
| Biotechnology                           | 9  |
| Organic fine chemistry                  | 3  |
1 - Computer technology and telecommunications
| Computer technology                     | 13 |
| Telecommunications                      | 29 |

*/



