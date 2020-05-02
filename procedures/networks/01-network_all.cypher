-- Get headers of the table
CALL apoc.load.jdbc("tkcserver", "SELECT * FROM riccaboni2017.t08 LIMIT 0,10") YIELD row return keys(row) limit 1;

-- Delete all nodes
MATCH (n)
DETACH DELETE n;

-- Confirm that the MYSQL tables have index
CALL apoc.load.jdbc("tkcserver", "SHOW INDEX FROM riccaboni2017.t08");
CALL apoc.load.jdbc("tkcserver", "SHOW INDEX FROM riccaboni2017.t09");


-- Create contraint
CALL db.constraints;
# Neo4j 4
CREATE CONSTRAINT InventorlocalID ON (i:inventor) ASSERT i.localID IS UNIQUE
# Neo4j 3.5
CREATE CONSTRAINT ON (i:inventor) ASSERT i.localID IS UNIQUE


-- Load nodes
CALL apoc.periodic.iterate(
'CALL apoc.load.jdbc("tkcserver", "SELECT DISTINCT IFNULL(b.mobileID, a.localID) AS finalID FROM riccaboni2017.t08 a INNER JOIN riccaboni2017.t09 b ON a.localID=b.localID LIMIT 0,100") 
YIELD row',
'CREATE (i:Inventor) SET i=row',
{batchSize:10000, iterateList:true, parallel:true}
)




CALL apoc.load.jdbc("tkcserver", "SELECT DISTINCT IFNULL(b.mobileID, a.localID) AS finalID FROM riccaboni2017.t08 a INNER JOIN riccaboni2017.t09 b ON a.localID=b.localID LIMIT 0,10") 
YIELD row 
CREATE (i:Inventor) SET i=row;



MATCH (n) RETURN count(*);
MATCH (n) RETURN (n);
