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
