
--Task 2
--
-- Create the 'table_to_delete' table and fill it with 10 million rows
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;

--

SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
--
--a
-- Measure the execution time of the DELETE operation
EXPLAIN ANALYZE
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;
--b
SELECT
    table_name,
    pg_size_pretty(total_bytes) AS total_size,
    pg_size_pretty(index_bytes) AS index_size,
    pg_size_pretty(toast_bytes) AS toast_size,
    pg_size_pretty(table_bytes) AS table_size
FROM (
    SELECT
        c.relname AS table_name,
        pg_total_relation_size(c.oid) AS total_bytes,
        pg_indexes_size(c.oid) AS index_bytes,
        pg_total_relation_size(c.reltoastrelid) AS toast_bytes,
        pg_total_relation_size(c.oid) - pg_indexes_size(c.oid) - COALESCE(pg_total_relation_size(c.reltoastrelid), 0) AS table_bytes
    FROM
        pg_class c
    LEFT JOIN
        pg_namespace n ON n.oid = c.relnamespace
    WHERE
        c.relkind = 'r'
        AND c.relname = 'table_to_delete'
) AS size_info;
--c
-- Perform VACUUM FULL VERBOSE to reclaim space
VACUUM FULL VERBOSE table_to_delete;
--d
SELECT
    table_name,
    pg_size_pretty(total_bytes) AS total_size,
    pg_size_pretty(index_bytes) AS index_size,
    pg_size_pretty(toast_bytes) AS toast_size,
    pg_size_pretty(table_bytes) AS table_size
FROM (
    SELECT
        c.relname AS table_name,
        pg_total_relation_size(c.oid) AS total_bytes,
        pg_indexes_size(c.oid) AS index_bytes,
        pg_total_relation_size(c.reltoastrelid) AS toast_bytes,
        pg_total_relation_size(c.oid) - pg_indexes_size(c.oid) - COALESCE(pg_total_relation_size(c.reltoastrelid), 0) AS table_bytes
    FROM
        pg_class c
    LEFT JOIN
        pg_namespace n ON n.oid = c.relnamespace
    WHERE
        c.relkind = 'r'
        AND c.relname = 'table_to_delete'
) AS size_info;

--e
-- Recreate 'table_to_delete' table
DROP TABLE IF EXISTS table_to_delete;

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;  
--5
--a
--before delete
SELECT
    table_name,
    pg_size_pretty(total_bytes) AS total_size,
    pg_size_pretty(index_bytes) AS index_size,
    pg_size_pretty(toast_bytes) AS toast_size,
    pg_size_pretty(table_bytes) AS table_size
FROM (
    SELECT
        c.relname AS table_name,
        pg_total_relation_size(c.oid) AS total_bytes,
        pg_indexes_size(c.oid) AS index_bytes,
        pg_total_relation_size(c.reltoastrelid) AS toast_bytes,
        pg_total_relation_size(c.oid) - pg_indexes_size(c.oid) - COALESCE(pg_total_relation_size(c.reltoastrelid), 0) AS table_bytes
    FROM
        pg_class c
    LEFT JOIN
        pg_namespace n ON n.oid = c.relnamespace
    WHERE
        c.relkind = 'r'
        AND c.relname = 'table_to_delete'
) AS size_info;

-- delete
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;
-- after delete

SELECT
    table_name,
    pg_size_pretty(total_bytes) AS total_size,
    pg_size_pretty(index_bytes) AS index_size,
    pg_size_pretty(toast_bytes) AS toast_size,
    pg_size_pretty(table_bytes) AS table_size
FROM (
    SELECT
        c.relname AS table_name,
        pg_total_relation_size(c.oid) AS total_bytes,
        pg_indexes_size(c.oid) AS index_bytes,
        pg_total_relation_size(c.reltoastrelid) AS toast_bytes,
        pg_total_relation_size(c.oid) - pg_indexes_size(c.oid) - COALESCE(pg_total_relation_size(c.reltoastrelid), 0) AS table_bytes
    FROM
        pg_class c
    LEFT JOIN
        pg_namespace n ON n.oid = c.relnamespace
    WHERE
        c.relkind = 'r'
        AND c.relname = 'table_to_delete'
) AS size_info;
--VACUUM FULL VERBOSE table_to_delete;

VACUUM FULL VERBOSE table_to_delete;

SELECT
    table_name,
    pg_size_pretty(total_bytes) AS total_size,
    pg_size_pretty(index_bytes) AS index_size,
    pg_size_pretty(toast_bytes) AS toast_size,
    pg_size_pretty(table_bytes) AS table_size
FROM (
    SELECT
        c.relname AS table_name,
        pg_total_relation_size(c.oid) AS total_bytes,
        pg_indexes_size(c.oid) AS index_bytes,
        pg_total_relation_size(c.reltoastrelid) AS toast_bytes,
        pg_total_relation_size(c.oid) - pg_indexes_size(c.oid) - COALESCE(pg_total_relation_size(c.reltoastrelid), 0) AS table_bytes
    FROM
        pg_class c
    LEFT JOIN
        pg_namespace n ON n.oid = c.relnamespace
    WHERE
        c.relkind = 'r'
        AND c.relname = 'table_to_delete'
) AS size_info;
--
--b
EXPLAIN ANALYZE
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;


TRUNCATE table_to_delete;


-- Declare variables for start and end timestamps
DO $$ 
DECLARE 
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    runtime INTERVAL;
BEGIN
    start_time := CURRENT_TIMESTAMP;
    DELETE FROM table_to_delete;
    end_time := CURRENT_TIMESTAMP;
    runtime := end_time - start_time;
    RAISE NOTICE 'Operation started at: %, ended at: %, duration: %', start_time, end_time, runtime;
END $$;
-- in this part i tried to calculate run time, using start and end times, actually delete operations delets data row by row and takes much more time than truncate, 
--bacause trancate just clears all data from existing table.
--here we have to drop table drop table table_to_delete using this command and recreate again tu trancate.

DO $$ 
DECLARE 
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    runtime INTERVAL;
BEGIN
    start_time := CURRENT_TIMESTAMP;
    truncate table_to_delete;
    end_time := CURRENT_TIMESTAMP;
    runtime := end_time - start_time;
    RAISE NOTICE 'Operation started at: %, ended at: %, duration: %', start_time, end_time, runtime;
END $$;

--
select * from table_to_delete;

