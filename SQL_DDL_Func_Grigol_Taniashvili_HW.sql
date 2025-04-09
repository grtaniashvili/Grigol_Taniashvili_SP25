--1
DROP VIEW IF EXISTS sales_revenue_by_category_qtr;

CREATE VIEW public.sales_revenue_by_category_qtr AS
    WITH current_qtr AS (
        SELECT 
            EXTRACT(YEAR FROM CURRENT_DATE)::INT AS this_year,
            EXTRACT(QUARTER FROM CURRENT_DATE)::INT AS this_qtr
    ),
    category_sales AS (
        SELECT
            c.name AS category,
            SUM(p.amount) AS total_sales,
            EXTRACT(YEAR FROM p.payment_date) AS year,
            EXTRACT(QUARTER FROM p.payment_date) AS quarter
        FROM payment p
        INNER JOIN rental r ON p.rental_id = r.rental_id
        INNER JOIN inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN film f ON i.film_id = f.film_id
        INNER JOIN film_category fc ON f.film_id = fc.film_id
        INNER JOIN category c ON fc.category_id = c.category_id
        GROUP BY c.name, year, quarter
    )
    SELECT
        cs.category,
        cs.total_sales
    FROM category_sales cs
    INNER JOIN current_qtr cq ON cs.year = cq.this_year AND cs.quarter = cq.this_qtr
    WHERE cs.total_sales > 0;

select *
from sales_revenue_by_category_qtr

--2
DROP FUNCTION IF EXISTS get_sales_revenue_by_category_qtr(INT, INT);

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(qtr_year TEXT)
RETURNS TABLE (
    category TEXT,
    total_sales NUMERIC
) AS $$
DECLARE
    input_year INT;
    input_quarter INT;
BEGIN
    -- Validate and parse input
    IF qtr_year !~ '^\d{4}-[1-4]$' THEN
        RAISE EXCEPTION 'Invalid input format. Use format: YYYY-Q (e.g., 2025-2)';
    END IF;

    input_year := SPLIT_PART(qtr_year, '-', 1)::INT;
    input_quarter := SPLIT_PART(qtr_year, '-', 2)::INT;

    RETURN QUERY
    SELECT
        c.name AS category,
        SUM(p.amount) AS total_sales
    FROM payment p
    INNER JOIN rental r ON p.rental_id = r.rental_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON i.film_id = f.film_id
    INNER JOIN film_category fc ON f.film_id = fc.film_id
    INNER JOIN category c ON fc.category_id = c.category_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = input_year
      AND EXTRACT(QUARTER FROM p.payment_date) = input_quarter
    GROUP BY c.name
    HAVING SUM(p.amount) > 0;

END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_sales_revenue_by_category_qtr('2017-2');


--3
CREATE SCHEMA IF NOT EXISTS core;
DROP FUNCTION IF EXISTS core.most_popular_films_by_countries(TEXT);

CREATE OR REPLACE FUNCTION core.most_popular_films_by_countries(country_input TEXT)
RETURNS TABLE (
    country TEXT,
    film TEXT,
    rating public."mpaa_rating",
    language bpchar(20),
    length INT2,
    release_year public."year"
) AS $$
BEGIN
    -- Validate input
    IF country_input IS NULL OR LENGTH(TRIM(country_input)) = 0 THEN
        RAISE EXCEPTION 'Country input cannot be null or empty';
    END IF;

    RETURN QUERY
    SELECT
        sub.country,
        sub.film,
        sub.rating,
        sub.language,
        sub.length,
        sub.release_year
    FROM (
        SELECT
            co.country,
            f.title AS film,
            f.rating,
            l.name AS language,
            f.length,
            f.release_year,
            COUNT(*) AS rental_count,
            RANK() OVER (PARTITION BY co.country ORDER BY COUNT(*) DESC) AS rank
        FROM rental r
        INNER JOIN inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN film f ON i.film_id = f.film_id
        INNER JOIN language l ON f.language_id = l.language_id
        INNER JOIN customer c ON r.customer_id = c.customer_id
        INNER JOIN address a ON c.address_id = a.address_id
        INNER JOIN city ci ON a.city_id = ci.city_id
        INNER JOIN country co ON ci.country_id = co.country_id
        WHERE LOWER(co.country) = LOWER(country_input)
        GROUP BY co.country, f.title, f.rating, l.name, f.length, f.release_year
    ) sub
    WHERE sub.rank = 1;

END;
$$ LANGUAGE plpgsql;



SELECT * FROM core.most_popular_films_by_countries('Argentina');
SELECT * FROM core.most_popular_films_by_countries('BRAZIL');



--4
DROP FUNCTION IF EXISTS get_movies_by_title(TEXT);

CREATE OR REPLACE FUNCTION get_movies_by_title(partial_title TEXT)
RETURNS TABLE(row_num INT, film_title TEXT, language bpchar(20), customer_name TEXT, rental_date timestamptz) AS
$$
DECLARE
    title_pattern TEXT := '%' || LOWER(partial_title) || '%';  -- Generate the pattern for the LIKE clause
BEGIN
    -- Check if the title parameter is provided
    IF partial_title IS NULL OR length(partial_title) = 0 THEN
        RAISE EXCEPTION 'Title pattern cannot be empty or NULL.';
    END IF;


    RETURN QUERY
    SELECT
        CAST(ROW_NUMBER() OVER (ORDER BY f.film_id) AS INT) AS row_num,  
        f.title AS film_title,
        l.name AS language,  
        c.first_name || ' ' || c.last_name AS customer_name,
        r.rental_date::timestamptz AS rental_date  
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id   
    INNER JOIN rental r ON i.inventory_id = r.inventory_id  
    INNER JOIN customer c ON r.customer_id = c.customer_id  
    INNER JOIN language l ON f.language_id = l.language_id  
    WHERE LOWER(f.title) LIKE title_pattern  
    ORDER BY f.film_id;

    -- Check if any results were found, if not, raise an exception
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No films found with the partial title: %', partial_title;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error occurred while fetching films: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;



SELECT * FROM get_movies_by_title('video');


--5
DROP FUNCTION IF EXISTS new_movie(TEXT, INT, bpchar(20));


CREATE OR REPLACE FUNCTION new_movie(film_title TEXT, release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT, lang_name bpchar(20) DEFAULT 'Klingon')
RETURNS INT AS
$$
DECLARE
	f_id INT;
    lan_id INT2;
BEGIN
    -- Check if the language exists in the language table
    SELECT language_id INTO lan_id
    FROM language
    WHERE LOWER(name) = LOWER(lang_name);
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language "%" does not exist in the language table.', lang_name;
    END IF;
 -- Check if this film alredy exists, not to dublicate
   IF EXISTS (SELECT 1 FROM film WHERE LOWER(title) = LOWER(film_title)) THEN
        RAISE EXCEPTION 'A film with the title "%" already exists.', film_title;
    END IF;
    -- Insert a new film into the film table
    INSERT INTO film (title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
    VALUES (film_title, release_year, lan_id, 4.99, 3, 19.99);
    
    -- Confirm success message
    RAISE NOTICE 'New movie "%" added successfully with ID %.', film_title, currval(pg_get_serial_sequence('film', 'film_id'));
SELECT film_id INTO f_id
FROM film  
WHERE LOWER(title) = LOWER(film_title);
RETURN f_id;
END;
$$ LANGUAGE plpgsql;

SELECT new_movie('Star Trek2', 2025, 'English');
