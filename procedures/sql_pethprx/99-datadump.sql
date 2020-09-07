/*
LOAD MYSQL DUMP
docker exec -ti p_ethprx_db_1 mysql -h "localhost" -u "root" --local-infile -p 
*/

CREATE DATABASE pethprx;

/*
docker exec -it p_ethprx_db_1 /bin/bash
mysql -h "localhost" -u "root" -p pethprx < '/var/lib/mysql-files/input/dbdump/pethprx-202005120957.sql'
*/

SHOW DATABASES;



/*
Not required
CREATE SCHEMA pethprx DEFAULT CHARACTER SET UTF8MB4 ;
USE pethprx;
SHOW VARIABLES LIKE "local_infile";
SET GLOBAL local_infile = 'ON';
SET UNIQUE_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_LOG_BIN=0;
*/
