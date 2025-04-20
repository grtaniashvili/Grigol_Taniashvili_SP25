--Task 2. Implement role-based authentication model for dvd_rental database
--Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability to connect to the database but no other permissions.
DO $ $ BEGIN IF NOT EXISTS (
    SELECT
        1
    FROM
        pg_roles
    WHERE
        rolname = 'rentaluser'
) THEN CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

END IF;

END $ $;

--Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this permission works correctly—write a SQL query to select all customers.
GRANT
SELECT
    ON TABLE customer TO rentaluser;

--change user
SET
    ROLE rentaluser;

--check select permission on renatluser
SELECT
    first_name,
    last_name
FROM
    customer;

RESET ROLE;

--Create a new user group called "rental" and add "rentaluser" to the group. 
DO $ $ BEGIN IF NOT EXISTS (
    SELECT
        1
    FROM
        pg_roles
    WHERE
        rolname = 'rental'
) THEN CREATE ROLE rental;

END IF;

END $ $;

ALTER group rental
ADD
    user rentaluser;

--Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one existing row in the "rental" table under that role. 
GRANT
INSERT
,
UPDATE
    ON TABLE rental TO rental;

SET
    ROLE rental;

INSERT INTO
    rental (
        customer_id,
        inventory_id,
        staff_id,
        rental_date,
        return_date
    )
VALUES
    (101, 202, 1, '2024-11-25', '2024-12-02');

UPDATE
    rental
SET
    return_date = '2024-11-07'
WHERE
    customer_id = 2;

RESET ROLE;

--Revoke the "rental" group's INSERT permission for the "rental" table. Try to insert new rows into the "rental" table make sure this action is denied.
REVOKE
INSERT
    ON rental
FROM
    rental
SET
    ROLE rental;

INSERT INTO
    rental (
        customer_id,
        inventory_id,
        staff_id,
        rental_date,
        return_date
    )
VALUES
    (102, 203, 3, '2024-11-25', '2024-12-02');

RESET ROLE;

--Create a personalized role for any customer already existing in the dvd_rental database. The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). The customer's payment and rental history must not be empty. 
DO $ $ DECLARE customer_record RECORD;

role_name TEXT;

BEGIN -- Find the first customer with rental and payment history
SELECT
    customer_id,
    first_name,
    last_name INTO customer_record
FROM
    customer c
WHERE
    EXISTS (
        SELECT
            1
        FROM
            rental r
        WHERE
            r.customer_id = c.customer_id
    )
    AND EXISTS (
        SELECT
            1
        FROM
            payment p
        WHERE
            p.customer_id = c.customer_id
    )
ORDER BY
    c.customer_id
LIMIT
    1;

-- If a matching customer is found
IF customer_record IS NOT NULL THEN -- Construct the role name
role_name := 'client_' || LOWER(customer_record.first_name) || '_' || LOWER(customer_record.last_name);

-- Create the role
EXECUTE 'CREATE ROLE ' || role_name;

-- add permision for customer for next task
EXECUTE 'GRANT SELECT on table rental, payment, customer to ' || role_name;

RAISE NOTICE 'Role % created for customer % %.',
role_name,
customer_record.first_name,
customer_record.last_name;

ELSE -- Output a message if no customer with rental and payment history is found
RAISE NOTICE 'No customer with rental and payment history found.';

END IF;

END $ $;

--
--
--
--Task 3. Implement row-level security
--Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
--Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. Write a query to make sure this user sees only their own data.
-- Enable ROW LEVEL SECURITY on the payment table
ALTER TABLE
    rental ENABLE ROW LEVEL SECURITY;

ALTER TABLE
    payment ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rental_customer_policy ON rental;

CREATE POLICY rental_customer_policy ON rental FOR
SELECT
    USING (
        EXISTS (
            SELECT
                1
            FROM
                customer c
            WHERE
                c.customer_id = rental.customer_id
                AND 'client_' || LOWER(c.first_name) || '_' || LOWER(c.last_name) = current_user
        )
    );

-- Create or replace the policy for the payment table
DROP POLICY IF EXISTS PAYMENT_CUSTOMER_POLICY ON PAYMENT;

CREATE POLICY payment_customer_policy ON payment FOR
SELECT
    USING (
        EXISTS (
            SELECT
                1
            FROM
                customer c
            WHERE
                c.customer_id = payment.customer_id
                AND 'client_' || LOWER(c.first_name) || '_' || LOWER(c.last_name) = current_user
        )
    );

-- Enable the policy on the table
ALTER TABLE
    rental ENABLE always rental_customer_policy;

ALTER TABLE
    payment ENABLE always payment_customer_policy;

SET
    role client_miłosz_czapla;

-- change it to your role
SELECT
    *
FROM
    rental
WHERE
    customer_id = 1;

-- customer id of client_miłosz_czapla 
SELECT
    *
FROM
    rental
WHERE
    customer_id = 2;

-- some other id
SELECT
    *
FROM
    payment
WHERE
    customer_id = 1;

SELECT
    *
FROM
    payment
WHERE
    customer_id = 2;

RESET role;

--DROP ROLE client_miłosz_czapla;
--
--REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM client_miłosz_czapla;