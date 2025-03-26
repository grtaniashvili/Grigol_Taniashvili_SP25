--Task 1
 -- Insert favorite movies into the film table, avoid duplicates using ON CONFLICT DO NOTHING
INSERT INTO film (title, description, release_year, language_id, rental_rate, rental_duration, last_update)  
SELECT 'The Dark Knight', 'A superhero film directed by Christopher Nolan', 2008, 1, 4.99, 1, current_date  
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'The Dark Knight')  
RETURNING film_id;

INSERT INTO film (title, description, release_year, language_id, rental_rate, rental_duration, last_update)  
SELECT 'Inception', 'A mind-bending thriller directed by Christopher Nolan', 2010, 1, 9.99, 2, current_date  
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Inception')  
RETURNING film_id;

INSERT INTO film (title, description, release_year, language_id, rental_rate, rental_duration, last_update)  
SELECT 'The Godfather', 'A crime film directed by Francis Ford Coppola', 1972, 1, 19.99, 3, current_date  
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'The Godfather')  
RETURNING film_id;
--

--
-- Add actors to the actor table if they don't already exist
INSERT INTO actor (first_name, last_name, last_update)  
SELECT 'Christian', 'Bale', current_date  
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Christian' AND last_name = 'Bale')  
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)  
SELECT 'Leonardo', 'DiCaprio', current_date  
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio')  
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)  
SELECT 'Marlon', 'Brando', current_date  
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Marlon' AND last_name = 'Brando')  
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)  
SELECT 'Heath', 'Ledger', current_date  
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Heath' AND last_name = 'Ledger')  
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)  
SELECT 'Joseph', 'Gordon-Levitt', current_date  
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Joseph' AND last_name = 'Gordon-Levitt')  
RETURNING actor_id;

INSERT INTO actor (first_name, last_name, last_update)  
SELECT 'Al', 'Pacino', current_date  
WHERE NOT EXISTS (SELECT 1 FROM actor WHERE first_name = 'Al' AND last_name = 'Pacino')  
RETURNING actor_id;

-- Link actors to films (Christian Bale and Heath Ledger to 'The Dark Knight', etc.)
INSERT INTO film_actor (film_id, actor_id, last_update)  
SELECT (SELECT film_id FROM film WHERE title = 'The Dark Knight'), actor_id, current_date  
FROM actor WHERE first_name = 'Christian' AND last_name = 'Bale'
ON CONFLICT DO NOTHING  
RETURNING *;

INSERT INTO film_actor (film_id, actor_id, last_update)  
SELECT (SELECT film_id FROM film WHERE title = 'The Dark Knight'), actor_id, current_date  
FROM actor WHERE first_name = 'Heath' AND last_name = 'Ledger'  
ON CONFLICT DO NOTHING  
RETURNING *;

INSERT INTO film_actor (film_id, actor_id, last_update)  
SELECT (SELECT film_id FROM film WHERE title = 'Inception'), actor_id, current_date  
FROM actor WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio'  
ON CONFLICT DO NOTHING  
RETURNING *;

INSERT INTO film_actor (film_id, actor_id, last_update)  
SELECT (SELECT film_id FROM film WHERE title = 'The Godfather'), actor_id, current_date  
FROM actor WHERE first_name = 'Al' AND last_name = 'Pacino'  
ON CONFLICT DO NOTHING  
RETURNING *;
--
INSERT INTO inventory (film_id, store_id)  
VALUES  
    ((SELECT film_id FROM film WHERE title = 'The Dark Knight'), 1),  
    ((SELECT film_id FROM film WHERE title = 'The Dark Knight'), 2),  
    ((SELECT film_id FROM film WHERE title = 'Inception'), 1),  
    ((SELECT film_id FROM film WHERE title = 'Inception'), 2),  
    ((SELECT film_id FROM film WHERE title = 'The Godfather'), 1),  
    ((SELECT film_id FROM film WHERE title = 'The Godfather'), 2);  
--
SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS rental_count, COUNT(p.payment_id) AS payment_count  
FROM customer c  
JOIN rental r ON c.customer_id = r.customer_id  
JOIN payment p ON c.customer_id = p.customer_id  
GROUP BY c.customer_id, c.first_name, c.last_name  
HAVING COUNT(r.rental_id) >= 43 AND COUNT(p.payment_id) >= 43  
LIMIT 1;  

UPDATE customer  
SET first_name = 'Grigol',  
    last_name = 'Taniashvili',  
    email = 'gr.taniashvili@gmail.com',  
    address_id = (SELECT address_id FROM address ORDER BY RANDOM() LIMIT 1)  
WHERE customer_id = (SELECT customer_id  
                     FROM (  
                         SELECT c.customer_id  
                         FROM customer c  
                         JOIN rental r ON c.customer_id = r.customer_id  
                         JOIN payment p ON c.customer_id = p.customer_id  
                         GROUP BY c.customer_id  
                         HAVING COUNT(r.rental_id) >= 43 AND COUNT(p.payment_id) >= 43  
                         LIMIT 1  
                     ) AS subquery)
 RETURNING *;

--
SELECT customer_id FROM customer  
WHERE first_name = 'Grigol' AND last_name = 'Taniashvili';

DELETE FROM payment  
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili');

DELETE FROM rental  
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili');  
--

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)  
VALUES  
    ('2017-01-10 10:00:00', (SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = 'The Dark Knight') AND store_id = 1 LIMIT 1), (SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili'), '2017-01-17 10:00:00', 1),  

    ('2017-01-12 14:30:00', (SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = 'Inception') AND store_id = 1 LIMIT 1), (SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili'), '2017-01-19 14:30:00', 1),  

    ('2017-01-15 18:45:00', (SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = 'The Godfather') AND store_id = 1 LIMIT 1), (SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili'), '2017-01-22 18:45:00', 1);  

    
 INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)  
VALUES  
    ((SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili'),  
     1,  
     (SELECT rental_id FROM rental WHERE inventory_id = (SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = 'The Dark Knight') AND store_id = 1 LIMIT 1) AND customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili') LIMIT 1),  
     4.99, '2017-01-10 10:05:00'),  

    ((SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili'),  
     1,  
     (SELECT rental_id FROM rental WHERE inventory_id = (SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = 'Inception') AND store_id = 1 LIMIT 1) AND customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili') LIMIT 1),  
     9.99, '2017-01-12 14:35:00'),  

    ((SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili'),  
     1,  
     (SELECT rental_id FROM rental WHERE inventory_id = (SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = 'The Godfather') AND store_id = 1 LIMIT 1) AND customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Grigol' AND last_name = 'Taniashvili') LIMIT 1),  
     19.99, '2017-01-15 18:50:00');  
-----------------------------------------

    
    

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

select 
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

