SELECT COUNT(*), LEFT(a.pat,2)
      FROM riccaboni2017.t01 a
      GROUP BY LEFT(a.pat,2);
/*
+----------+---------------+
| COUNT(*) | LEFT(a.pat,2) |
+----------+---------------+
|  2684761 | EP            |
|  4.243.972 | US            |
|  2361535 | WO            |
+----------+---------------+
3 rows in set (5,76 sec)
*/

SELECT COUNT(*), RIGHT(a.pat,1)
      FROM riccaboni2017.t01 a
      GROUP BY RIGHT(a.pat,1);
