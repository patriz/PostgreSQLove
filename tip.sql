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
