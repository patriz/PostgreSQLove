-- Get the stuck process id
SELECT * FROM pg_stat_activity WHERE waiting;

-- Figure out what lock it's waiting on
SELECT * FROM pg_locks WHERE pid = ? AND NOT granted;

-- Find who holds that lock
SELECT *
FROM pg_locks l
INNER JOIN pg_stat_activity s ON (l.pid = s.pid)
WHERE locktype = 'relation'
AND   relation = ?;

-- Drop all connections to the database
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'Database Name'
	AND pid <> pg_backend_pid()
	AND state in ('idle', 'idle in transaction', 'idle in transaction (aborted)', 'disabled')
	AND state_change < current_timestamp - INTERVAL '15' MINUTE;


-- Transpose rows to columns: looks silly to transpose a thousands of rows to columns)
SET @sql = NULL;
SET SESSION group_concat_max_len = 1000000;
SELECT
    GROUP_CONCAT(
        DISTINCT CONCAT('(case when R.id = ''',
            id,
            ''' then R.rating else ''0''  end) as `',
            id, '`'
        )
    )
INTO @sql
FROM (
    select id from book where category = 'programming'
) T;

SET @sql = CONCAT('SELECT R.user_id, ', @sql, '
    FROM book_review R
    LEFT JOIN book H ON B.id = R.book_id
    LEFT JOIN user U ON U.id = R.user_id
    WHERE S.last_visited_at >= NOW() - INTERVAL 3 MONTH
    GROUP BY R.user_id;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;

-- MySQL Table Space Usage and Extension
-- InnoDB system tablespace 
select FILE_NAME, TABLESPACE_NAME, TABLE_NAME, ENGINE, INDEX_LENGTH, TOTAL_EXTENTS, EXTENT_SIZE 
from INFORMATION_SCHEMA.FILES 
where file_name 
like '%ibdata%'; 

-- InnoDB temporary tablespace 
select FILE_NAME, TABLESPACE_NAME, TABLE_NAME, ENGINE, INDEX_LENGTH, TOTAL_EXTENTS, EXTENT_SIZE 
from INFORMATION_SCHEMA.FILES 
where file_name 
like '%ibtmp%'; 

-- Database Space Usage Report 
SELECT s.schema_name, IFNULL(ROUND((SUM(t.data_length)+SUM(t.index_length))/1024/1024,2),0.00) total_size 
FROM INFORMATION_SCHEMA.SCHEMATA s, INFORMATION_SCHEMA.TABLES t 
WHERE s.schema_name = t.table_schema 
GROUP BY s.schema_name 
ORDER BY total_size DESC; 

-- Database Space Usage Report (data_used, data_free and pct_used)
SELECT s.schema_name,
CONCAT(IFNULL(ROUND((SUM(t.data_length)+SUM(t.index_length))/1024/1024,2),0.00),"Mb") total_size,
CONCAT(IFNULL(ROUND(((SUM(t.data_length)+SUM(t.index_length))-SUM(t.data_free))/1024/1024,2),0.00),"Mb") data_used,
CONCAT(IFNULL(ROUND(SUM(data_free)/1024/1024,2),0.00),"Mb") data_free,
IFNULL(ROUND((((SUM(t.data_length)+SUM(t.index_length))-SUM(t.data_free))/((SUM(t.data_length)+SUM(t.index_length)))*100),2),0) pct_used
FROM INFORMATION_SCHEMA.SCHEMATA s, INFORMATION_SCHEMA.TABLES t
WHERE s.schema_name = t.table_schema
GROUP BY s.schema_name
ORDER BY total_size DESC;

-- Table Space Usage Report
SELECT s.schema_name, table_name,
CONCAT(IFNULL(ROUND((SUM(t.data_length)+SUM(t.index_length))/1024/1024,2),0.00),"Mb") total_size,
CONCAT(IFNULL(ROUND(((SUM(t.data_length)+SUM(t.index_length))-SUM(t.data_free))/1024/1024,2),0.00),"Mb") data_used,
CONCAT(IFNULL(ROUND(SUM(data_free)/1024/1024,2),0.00),"Mb") data_free,
IFNULL(ROUND((((SUM(t.data_length)+SUM(t.index_length))-SUM(t.data_free))/((SUM(t.data_length)+SUM(t.index_length)))*100),2),0) pct_used
FROM INFORMATION_SCHEMA.SCHEMATA s, INFORMATION_SCHEMA.TABLES t
WHERE s.schema_name = t.table_schema
GROUP BY s.schema_name, table_name
ORDER BY total_size DESC;

-- Check for Tables that have Free Space
SELECT s.schema_name, table_name,
IFNULL(ROUND(SUM(data_free)/1024,2),0.00) data_free
FROM INFORMATION_SCHEMA.SCHEMATA s, INFORMATION_SCHEMA.TABLES t
WHERE s.schema_name = t.table_schema
GROUP BY s.schema_name, table_name
HAVING data_free > 100
ORDER BY data_free DESC;
