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

    
    

