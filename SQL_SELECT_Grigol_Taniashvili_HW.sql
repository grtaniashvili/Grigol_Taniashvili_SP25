------------------------------ Part 1: Write SQL queries to retrieve the following data
--All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
-- 1. We filter films by release year and rental rate to meet the conditions.
-- 2. We use INNER JOINs to connect films with categories.
-- 3. We ensure that only "Animation" category films are included.
-- 4. Sorting is done alphabetically using ORDER BY title.
SELECT 
    film.title, 
    film.release_year, 
    film.rating 
FROM public.film AS film  
INNER JOIN public.film_category AS film_category ON film.film_id = film_category.film_id  
INNER JOIN public.category AS category ON film_category.category_id = category.category_id  
WHERE film.release_year BETWEEN 2017 AND 2019 AND 
    film.rental_rate > 1 AND 
    UPPER(category.name) = 'ANIMATION'
ORDER BY film.title;
--
--The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
-- 1. We concatenate address fields to display them as one.
-- 2. We sum up payments made after March 2017 to calculate revenue.
-- 3. We group by store address to get total revenue per store.
-- 4. Sorting is done in descending order to show highest revenue stores first.
SELECT 
    CONCAT(addr.address, ' ', addr.address2) AS store_address,
    SUM(pay.amount) AS total_revenue
FROM rental r
INNER JOIN payment pay ON r.rental_id = pay.rental_id
INNER JOIN inventory inv ON r.inventory_id = inv.inventory_id
INNER JOIN store s ON inv.store_id = s.store_id
INNER JOIN address addr ON s.address_id = addr.address_id
WHERE pay.payment_date >= '2017-04-01 00:00:00' 
GROUP BY addr.address, addr.address2 
ORDER BY total_revenue DESC;
--Top-5 actors by number of movies (released after 2015) they took part 
--in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
-- 1. We filter movies released after 2015.
-- 2. We use COUNT() to determine the number of movies each actor has been in.
-- 3. We group by actor to ensure we count per individual.
-- 4. We order results in descending order and limit to top 5.
WITH ActorMovieCount AS (
    SELECT 
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
    COUNT(CASE WHEN c.name = 'Drama' THEN 1 END) AS number_of_drama_movies,
    COUNT(CASE WHEN c.name = 'Travel' THEN 1 END) AS number_of_travel_movies,
    COUNT(CASE WHEN c.name = 'Documentary' THEN 1 END) AS number_of_documentary_movies
FROM film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE UPPER(c.name) IN ('DRAMA', 'TRAVEL', 'DOCUMENTARY')
GROUP BY f.release_year
ORDER BY f.release_year DESC;

------------------------------ Part 2: Solve the following problems using SQL
-- Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance.
-- 1. We filter payments from 2017.
-- 2. We sum payments per staff to calculate revenue.
-- 3. We determine the last store of each employee.
-- 4. Sorting by total revenue in descending order to get the top 3.
--
WITH last_store_per_staff AS (
    SELECT 
        payment.staff_id,
        staff.first_name,
        staff.last_name,
        s.store_id AS last_store_id, 
        ROW_NUMBER() OVER (PARTITION BY payment.staff_id ORDER BY payment.payment_date DESC) AS rn
    FROM payment AS payment
    INNER JOIN staff AS staff ON payment.staff_id = staff.staff_id
    INNER JOIN store s on s.store_id = staff.store_id 
    WHERE EXTRACT(YEAR FROM payment.payment_date) = 2017
)
SELECT 
    payment.staff_id,
    laststore.first_name,
    laststore.last_name,
    laststore.last_store_id,
    SUM(payment.amount) AS total_revenue
FROM payment AS payment
INNER JOIN last_store_per_staff AS laststore ON payment.staff_id = laststore.staff_id
WHERE laststore.rn = 1
AND EXTRACT(YEAR FROM payment.payment_date) = 2017
GROUP BY payment.staff_id, laststore.first_name, laststore.last_name, laststore.last_store_id
ORDER BY total_revenue DESC
LIMIT 3;

--Which 5 movies were rented more than others (number of rentals), and what's the expected 
--age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system
-- 1. We count rentals per movie.
-- 2. We classify movies based on Motion Picture Association film rating system.
-- 3. We order by rental count and limit to top 5.
-- https://en.wikipedia.org/wiki/Motion_Picture_Association_film_rating_system?utm_source=chatgpt.com source
--https://www.bunkamura.co.jp/english/faq/cinema/q10_350.html
-- Parental guidance is required for children under the age of 12.
SELECT 
    film.title, 
    COUNT(rental.rental_id) AS rental_count,
    film.rating,
    CASE 
        WHEN film.rating = 'G' THEN 'All ages'
        WHEN film.rating = 'PG' THEN '12+ years'
        WHEN film.rating = 'PG-13' THEN '13+ years'
        WHEN film.rating = 'R' THEN '17+ years'
        WHEN film.rating = 'NC-17' THEN '18+ years'
        ELSE 'Unknown'
    END AS expected_age
FROM 
    rental AS rental
INNER JOIN 
    inventory AS inventory 
    ON rental.inventory_id = inventory.inventory_id
INNER JOIN 
    film AS film 
    ON inventory.film_id = film.film_id
GROUP BY 
    film.title, film.rating
ORDER BY 
    rental_count DESC
LIMIT 5;

------------------------------ Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
--V1: gap between the latest release_year and current year per each actor;
WITH LastMovie AS (
    SELECT 
        filmactor.actor_id, 
        actor.first_name, 
        actor.last_name, 
        MAX(film.release_year) AS last_movie_year
    FROM film_actor filmactor
    INNER JOIN actor actor ON filmactor.actor_id = actor.actor_id
    INNER JOIN film film ON filmactor.film_id = film.film_id
    GROUP BY filmactor.actor_id, actor.first_name, actor.last_name
)
SELECT 
    lastmovie.actor_id, 
    lastmovie.first_name, 
    lastmovie.last_name, 
    lastmovie.last_movie_year, 
    EXTRACT(YEAR FROM CURRENT_DATE) - lastmovie.last_movie_year AS years_since_last_movie
FROM LastMovie lastmovie
ORDER BY years_since_last_movie DESC
LIMIT 10;
--
/*Finds the latest movie release year for each actor.
Computes the gap between the latest movie and the current year.
Sorts actors by the longest inactive period.
 */
--V2: gaps between sequential films per each actor;
WITH MovieYears AS (
    SELECT DISTINCT filmactor.actor_id, film.release_year
    FROM film_actor filmactor
    INNER JOIN film film ON filmactor.film_id = film.film_id
),
Gaps AS (
    SELECT 
        movieyears1.actor_id, 
        actor.first_name, 
        actor.last_name, 
        movieyears1.release_year AS year_1, 
        MIN(movieyears2.release_year) AS year_2,
        MIN(movieyears2.release_year) - movieyears1.release_year AS gap
    FROM MovieYears movieyears1
   INNER JOIN MovieYears movieyears2 
        ON movieyears1.actor_id = movieyears2.actor_id 
        AND movieyears2.release_year > movieyears1.release_year
    JOIN actor actor ON movieyears1.actor_id = actor.actor_id
    GROUP BY movieyears1.actor_id, actor.first_name, actor.last_name, movieyears1.release_year
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

