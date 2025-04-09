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

    -- Query for films containing the partial title, with related customer and rental info
    RETURN QUERY
    SELECT
        CAST(ROW_NUMBER() OVER (ORDER BY f.film_id) AS INT) AS row_num,  -- Generate row numbers automatically
        f.title AS film_title,
        l.name AS language,  -- Return language as TEXT (assuming `l.name` is TEXT or VARCHAR)
        c.first_name || ' ' || c.last_name AS customer_name,
        r.rental_date::timestamptz AS rental_date  -- Ensure rental_date is returned as timestamptz
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id   -- Join with inventory to link to rentals
    INNER JOIN rental r ON i.inventory_id = r.inventory_id  -- Join with rentals using inventory_id
    INNER JOIN customer c ON r.customer_id = c.customer_id  -- Join with customers to get customer info
    INNER JOIN language l ON f.language_id = l.language_id  -- Join with language table to get language info
    WHERE LOWER(f.title) LIKE title_pattern  -- Match the title pattern
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
	
   IF EXISTS (SELECT 1 FROM film WHERE LOWER(title) = LOWER(film_title)) THEN
        RAISE EXCEPTION 'A film with the title "%" already exists.', film_title;
    END IF;
    -- Insert a new film into the film table
    INSERT INTO film (title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
    VALUES (film_title, release_year, lan_id, 4.99, 3, 19.99);
    
    -- Confirm success message (optional)
    RAISE NOTICE 'New movie "%" added successfully with ID %.', film_title, currval(pg_get_serial_sequence('film', 'film_id'));
SELECT film_id INTO f_id
FROM film  
WHERE LOWER(title) = LOWER(film_title);
RETURN f_id;
END;
$$ LANGUAGE plpgsql;

SELECT new_movie('Star Trek2', 2025, 'English');



--6
/*### 1. **Operations Performed by Functions**

Let's break down the expected operations of each function in the `dvd_rental` database. However, without access to the actual database or function definitions, the following operations are deduced based on typical naming conventions:

1. **`film_in_stock`**: 
   - Likely returns a list of films that are currently available in the inventory (i.e., films that have stock).
   - It would probably query the `inventory` table, checking the number of items available for each film.

2. **`film_not_in_stock`**: 
   - Likely returns a list of films that are currently not available in the inventory (i.e., films that are out of stock).
   - It would likely query the `inventory` table, checking for films where the stock count is 0 or unavailable.

3. **`inventory_in_stock`**:
   - Likely returns a list of all items in the `inventory` table that are available for rent. This might check if items have been rented or if the inventory is active.
   - It would query the `inventory` table with conditions such as "quantity > 0" or "inventory status = available."

4. **`get_customer_balance`**:
   - This function most likely calculates and returns the balance for a customer, considering various factors like unpaid rentals, late fees, or pre-paid amounts.
   - It would likely query tables such as `payment`, `rental`, and `customer` to compute the balance.

5. **`inventory_held_by_customer`**:
   - This function would likely return a list of films that a customer currently has rented, based on the `rental` table.
   - It might query for `rental` records that are not yet returned, joining `inventory` and `customer` to filter by a specific customer.

6. **`rewards_report`**:
   - Likely generates a report of rewards or loyalty points earned by customers based on their rental history.
   - It would query `payment`, `customer`, and possibly `rental` and `reward` tables.

7. **`last_day`**:
   - Likely returns the last date of a specific time period (such as the last day of the current month, quarter, or year).
   - This function would likely use date/time functions to calculate the last day of the relevant period.

---

### 2. **Why does the `rewards_report` function return 0 rows?**

The function `rewards_report` likely returns 0 rows because the dynamic SQL (possibly within `EXECUTE`) isn't correctly fetching the data or doesn't match the expected conditions.

To fix this, you would need to check the following:
- Ensure the correct `WHERE` conditions are used in the dynamic query.
- Check if the `tmpSQL` variable is correctly defined and used to query the correct tables.
- Ensure that there is data matching the query criteria.

You can modify the function to ensure it's fetching the correct data. Here's an example of how to improve the function:

*/
CREATE OR REPLACE FUNCTION rewards_report()
RETURNS TABLE (
    customer_id INT,
    customer_name TEXT,
    reward_points INT
) AS $$
DECLARE
    tmpSQL TEXT;
BEGIN
    -- Build dynamic SQL to calculate rewards
    tmpSQL := 'SELECT 
    c.customer_id, 
    c.first_name || '' '' || c.last_name AS customer_name, 
    SUM(rw.reward_points) AS reward_points
FROM rental r
INNER JOIN customer c ON r.customer_id = c.customer_id
LEFT JOIN rewards rw ON r.rental_id = rw.rental_id  -- Assuming rewards are linked to rentals
GROUP BY c.customer_id;';


    -- Execute the query
    RETURN QUERY EXECUTE tmpSQL;
END;
$$ LANGUAGE plpgsql;

select * from rewards_report()
/*
### 3. **Potential Function for Removal**

Without access to the specific function definitions, it would be challenging to determine if any function can be removed. However, you could consider removing any function that is:
- Not used in the codebase (unused functions).
- Duplicating the functionality of other functions.
- Inactive due to changes in the database schema or business requirements.

For example, if `film_not_in_stock` and `inventory_in_stock` are providing redundant information (e.g., one just returns the inverse of the other), you could potentially remove one of them.

---

### 4. **Modifications to `get_customer_balance`**

The function likely calculates customer balances but doesn't fully implement all the business requirements. To adjust it, you'd need to:
- Ensure that it accounts for late fees, payment history, and any applicable discounts.
- Modify the query to include all relevant `payment`, `rental`, and `fee` tables.
  
Here’s an example of an enhanced function:

*/
CREATE OR REPLACE FUNCTION get_customer_balance(customer_id INT)
RETURNS NUMERIC AS $$
DECLARE
    balance NUMERIC;
BEGIN
    -- Calculate balance, including payments and rental fees
    SELECT SUM(p.amount) - COALESCE(SUM(f.fee), 0) INTO balance
    FROM payment p
    LEFT JOIN rental r ON p.rental_id = r.rental_id
    LEFT JOIN fee f ON r.rental_id = f.rental_id
    WHERE r.customer_id = customer_id
    GROUP BY r.customer_id;

    RETURN balance;
END;
$$ LANGUAGE plpgsql;

select * from get_customer_balance(79)
/*
---

### 5. **How do `group_concat` and `_group_concat` work?**

The `group_concat` function (or `_group_concat` in some databases) is used to concatenate multiple values from rows into a single string. It is commonly used in databases like MySQL.

In PostgreSQL, `string_agg` is often used instead. Here’s an example of how they work:

```sql
SELECT string_agg(column_name, ', ') FROM table_name GROUP BY some_column;
```

This function concatenates all values of `column_name` into a single string, separated by a comma.

---

### 6. **What does the `last_updated` function do?**

The `last_updated` function likely returns the last modification timestamp of a table or record. It could check the `updated_at` column in a table and return the most recent value.

Example:
*/
CREATE OR REPLACE FUNCTION last_updated(table_name TEXT)
RETURNS TIMESTAMPTZ AS $$
DECLARE
    last_update TIMESTAMPTZ;
BEGIN
    EXECUTE format('SELECT MAX(last_update) FROM %I', table_name) INTO last_update;
    RETURN last_update;
END;
$$ LANGUAGE plpgsql;

select * from last_updated('staff')
/*
---

### 7. **Purpose of `tmpSQL` in `rewards_report` Function**

The `tmpSQL` variable holds the dynamically constructed SQL query that is executed using `EXECUTE`. This is often necessary when the structure of the query depends on variables or when table/column names need to be determined at runtime.

Can the function be recreated without dynamic SQL? 
- Yes, but only if the structure of the query can be statically defined. If the query requires runtime calculation of table names or conditions, then dynamic SQL is required.

---

### Conclusion

Each function plays a critical role in handling various business logic related to rentals, 
sales, and customer data in the DVD rental system. If the `rewards_report` function is returning 0 rows,
 it may require an adjustment to its dynamic query. You can remove redundant functions 
 if their functionality overlaps with others, and ensuring that business logic is correctly implemented in 
 functions like `get_customer_balance` is essential.
*/