------------------------------ Part 1: Write SQL queries to retrieve the following data
--All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
-- 1. We filter films by release year and rental rate to meet the conditions.
-- 2. We use INNER JOINs to connect films with categories.
-- 3. We ensure that only "Animation" category films are included.
-- 4. Sorting is done alphabetically using ORDER BY title.
SELECT f.title, f.release_year, f.rating 
FROM public.film f  
INNER JOIN public.film_category fc ON f.film_id = fc.film_id  
INNER JOIN public.category c ON fc.category_id = c.category_id  
WHERE f.release_year BETWEEN 2017 AND 2019  
  AND f.rental_rate > 1  
  AND c.name = 'Animation'
ORDER BY f.title;
--
--The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
-- 1. We concatenate address fields to display them as one.
-- 2. We sum up payments made after March 2017 to calculate revenue.
-- 3. We group by store address to get total revenue per store.
-- 4. Sorting is done in descending order to show highest revenue stores first.
SELECT 
    CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS store_address,
    SUM(p.amount) AS revenue
FROM rental r
INNER JOIN payment p ON r.rental_id = p.rental_id
INNER JOIN customer c ON r.customer_id = c.customer_id
INNER JOIN store s ON c.store_id = s.store_id
INNER JOIN address a ON s.address_id = a.address_id
WHERE p.payment_date > '2017-03-31'
GROUP BY store_address
ORDER BY revenue DESC;
--
--Top-5 actors by number of movies (released after 2015) they took part 
--in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
-- 1. We filter movies released after 2015.
-- 2. We use COUNT() to determine the number of movies each actor has been in.
-- 3. We group by actor to ensure we count per individual.
-- 4. We order results in descending order and limit to top 5.
WITH ActorMovieCount AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(f.film_id) AS number_of_movies
    FROM actor a
    INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN film f ON fa.film_id = f.film_id
    WHERE f.release_year > 2015
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT first_name, last_name, number_of_movies
FROM ActorMovieCount
ORDER BY number_of_movies DESC
LIMIT 5;
--
--Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, 
--number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. 
--Dealing with NULL values is encouraged)
-- 1. We use conditional aggregation (COUNT CASE) to count movies per genre.
-- 2. We filter only relevant categories.
-- 3. We group by release year and sort results in descending order.
--
SELECT 
    f.release_year,
    COUNT(CASE WHEN c.name = 'Drama' THEN f.film_id END) AS number_of_drama_movies,
    COUNT(CASE WHEN c.name = 'Travel' THEN f.film_id END) AS number_of_travel_movies,
    COUNT(CASE WHEN c.name = 'Documentary' THEN f.film_id END) AS number_of_documentary_movies
FROM film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY f.release_year
ORDER BY f.release_year DESC;

------------------------------ Part 2: Solve the following problems using SQL
-- Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance.
-- 1. We filter payments from 2017.
-- 2. We sum payments per staff to calculate revenue.
-- 3. We determine the last store of each employee.
-- 4. Sorting by total revenue in descending order to get the top 3.
--
WITH StaffRevenue AS (
    SELECT 
        p.staff_id,
        s.first_name,
        s.last_name,
        st.store_id AS last_store,
        SUM(p.amount) AS total_revenue
    FROM payment p
    INNER JOIN staff s ON p.staff_id = s.staff_id
    INNER JOIN store st ON s.store_id = st.store_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY p.staff_id, s.first_name, s.last_name, st.store_id
)
SELECT staff_id, first_name, last_name, last_store, total_revenue
FROM StaffRevenue
ORDER BY total_revenue DESC
LIMIT 3;

--Which 5 movies were rented more than others (number of rentals), and what's the expected 
--age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system
-- 1. We count rentals per movie.
-- 2. We classify movies based on Motion Picture Association film rating system.
-- 3. We order by rental count and limit to top 5.
WITH MovieRentals AS (
    SELECT 
        f.film_id,
        f.title,
        f.rating,
        COUNT(r.rental_id) AS rental_count
    FROM rental r
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON i.film_id = f.film_id
    GROUP BY f.film_id, f.title, f.rating
)
SELECT 
    title, 
    rental_count,
    rating,
    CASE 
        WHEN rating = 'G' THEN 'All ages'
        WHEN rating = 'PG' THEN '10+ years'
        WHEN rating = 'PG-13' THEN '13+ years'
        WHEN rating = 'R' THEN '17+ years'
        WHEN rating = 'NC-17' THEN '18+ years'
        ELSE 'Unknown'
    END AS expected_age
FROM MovieRentals
ORDER BY rental_count DESC
LIMIT 5;

------------------------------ Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
--V1: gap between the latest release_year and current year per each actor;
WITH LastMovie AS (
    SELECT 
        fa.actor_id, 
        a.first_name, 
        a.last_name, 
        MAX(f.release_year) AS last_movie_year
    FROM film_actor fa
    INNER JOIN actor a ON fa.actor_id = a.actor_id
    INNER JOIN film f ON fa.film_id = f.film_id
    GROUP BY fa.actor_id, a.first_name, a.last_name
)
SELECT 
    lm.actor_id, 
    lm.first_name, 
    lm.last_name, 
    lm.last_movie_year, 
    EXTRACT(YEAR FROM CURRENT_DATE) - lm.last_movie_year AS years_since_last_movie
FROM LastMovie lm
ORDER BY years_since_last_movie DESC
LIMIT 10;
--
/*Finds the latest movie release year for each actor.
Computes the gap between the latest movie and the current year.
Sorts actors by the longest inactive period.
 */
--V2: gaps between sequential films per each actor;
WITH MovieYears AS (
    SELECT DISTINCT fa.actor_id, f.release_year
    FROM film_actor fa
    INNER JOIN film f ON fa.film_id = f.film_id
),
Gaps AS (
    SELECT 
        m1.actor_id, 
        a.first_name, 
        a.last_name, 
        m1.release_year AS year_1, 
        MIN(m2.release_year) AS year_2,
        MIN(m2.release_year) - m1.release_year AS gap
    FROM MovieYears m1
   INNER JOIN MovieYears m2 
        ON m1.actor_id = m2.actor_id 
        AND m2.release_year > m1.release_year
    JOIN actor a ON m1.actor_id = a.actor_id
    GROUP BY m1.actor_id, a.first_name, a.last_name, m1.release_year
)
SELECT 
    actor_id, 
    first_name, 
    last_name, 
    MAX(gap) AS longest_gap
FROM Gaps
GROUP BY actor_id, first_name, last_name
ORDER BY longest_gap DESC
LIMIT 10;
--
/*MovieYears CTE: Gets the distinct movie release years for each actor.
Self-Join (Gaps CTE):
Joins the table to itself to find the next movie year for each actor.
Computes the gap (year_2 - year_1), but ensures year_2 > year_1.
MIN(m2.release_year) to find the closest next movie year.
Finds the Maximum Gap Per Actor and sorts by the longest break.
 */

