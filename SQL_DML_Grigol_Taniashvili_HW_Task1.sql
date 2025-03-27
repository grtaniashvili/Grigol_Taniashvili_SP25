--Task 1
 -- Insert favorite movies into the film table, avoid duplicates using ON CONFLICT DO NOTHING

INSERT INTO public.film (title, description, release_year, language_id, rental_rate, rental_duration, last_update)  
SELECT 
    'The Dark Knight', 
    'A superhero film directed by Christopher Nolan', 
    2008, 
    (SELECT language_id FROM public.language WHERE UPPER(name) = 'ENGLISH' LIMIT 1), 
    4.99, 
    7,  
    current_date  
WHERE NOT EXISTS 
    (SELECT 1 FROM public.film WHERE UPPER(title) = 'THE DARK KNIGHT')  
RETURNING film_id;


INSERT INTO public.film (title, description, release_year, language_id, rental_rate, rental_duration, last_update)  
SELECT 
    'Inception', 
    'A mind-bending thriller directed by Christopher Nolan', 
    2010, 
    (SELECT language_id FROM public.language WHERE UPPER(name) = 'ENGLISH' LIMIT 1), 
    9.99, 
    14,  
    current_date  
WHERE NOT EXISTS 
    (SELECT 1 FROM public.film WHERE UPPER(title) = 'INCEPTION')  
RETURNING film_id;


INSERT INTO public.film (title, description, release_year, language_id, rental_rate, rental_duration, last_update)  
SELECT 
    'The Godfather', 
    'A crime film directed by Francis Ford Coppola', 
    1972, 
    (SELECT language_id FROM public.language WHERE UPPER(name) = 'ENGLISH' LIMIT 1), 
    19.99, 
    21,  
    current_date  
WHERE NOT EXISTS 
    (SELECT 1 FROM public.film WHERE UPPER(title) = 'THE GODFATHER')  
RETURNING film_id;

--

--
-- Add actors to the actor table if they don't already exist
-- Insert actors into the actor table with case-insensitive checks
INSERT INTO public.actor (first_name, last_name, last_update)  
SELECT 'Christian', 'Bale', current_date  
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE UPPER(first_name) = 'CHRISTIAN' AND UPPER(last_name) = 'BALE')  
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)  
SELECT 'Leonardo', 'DiCaprio', current_date  
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE UPPER(first_name) = 'LEONARDO' AND UPPER(last_name) = 'DICAPRIO')  
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)  
SELECT 'Marlon', 'Brando', current_date  
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE UPPER(first_name) = 'MARLON' AND UPPER(last_name) = 'BRANDO')  
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)  
SELECT 'Heath', 'Ledger', current_date  
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE UPPER(first_name) = 'HEATH' AND UPPER(last_name) = 'LEDGER')  
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)  
SELECT 'Joseph', 'Gordon-Levitt', current_date  
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE UPPER(first_name) = 'JOSEPH' AND UPPER(last_name) = 'GORDON-LEVITT')  
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)  
SELECT 'Al', 'Pacino', current_date  
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE UPPER(first_name) = 'AL' AND UPPER(last_name) = 'PACINO')  
RETURNING actor_id;

-- Link actors to films with case-insensitive checks for actor names and film titles
-- Insert film_actor records, linking films and actors (Christian Bale and Heath Ledger to 'The Dark Knight', etc.)
INSERT INTO public.film_actor (film_id, actor_id, last_update)  
SELECT (SELECT film_id FROM public.film WHERE UPPER(title) = 'THE DARK KNIGHT'), actor_id, current_date  
FROM public.actor WHERE UPPER(first_name) = 'CHRISTIAN' AND UPPER(last_name) = 'BALE'
ON CONFLICT DO NOTHING  
RETURNING *;

INSERT INTO public.film_actor (film_id, actor_id, last_update)  
SELECT (SELECT film_id FROM public.film WHERE UPPER(title) = 'THE DARK KNIGHT'), actor_id, current_date  
FROM public.actor WHERE UPPER(first_name) = 'HEATH' AND UPPER(last_name) = 'LEDGER'  
ON CONFLICT DO NOTHING  
RETURNING *;

INSERT INTO public.film_actor (film_id, actor_id, last_update)  
SELECT (SELECT film_id FROM public.film WHERE UPPER(title) = 'INCEPTION'), actor_id, current_date  
FROM public.actor WHERE UPPER(first_name) = 'LEONARDO' AND UPPER(last_name) = 'DICAPRIO'  
ON CONFLICT DO NOTHING  
RETURNING *;

INSERT INTO public.film_actor (film_id, actor_id, last_update)  
SELECT (SELECT film_id FROM public.film WHERE UPPER(title) = 'THE GODFATHER'), actor_id, current_date  
FROM public.actor WHERE UPPER(first_name) = 'AL' AND UPPER(last_name) = 'PACINO'  
ON CONFLICT DO NOTHING  
RETURNING *;

--
INSERT INTO public.inventory (film_id, store_id)  
VALUES  
    ((SELECT film_id FROM film WHERE UPPER(title) = 'THE DARK KNIGHT'), 1),   
    ((SELECT film_id FROM film WHERE UPPER(title) = 'INCEPTION'), 1),  
    ((SELECT film_id FROM film WHERE UPPER(title) = 'THE GODFATHER'), 2);  
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

    
    

