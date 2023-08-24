-- EXERCISE 1 --
-- Using a CTE, find out the total number of films rented for each rating (like 'PG', 'G', etc.) in the year 2005.
-- List the ratings that had more than 50 rentals.
WITH CTE_TOTAL_FILMS_RENTED AS
(
SELECT
	f.rating,
	COUNT(DISTINCT r.rental_id) AS total_rentals
FROM public.rental r
INNER JOIN public.inventory i
	ON r.inventory_id = i.inventory_id
INNER JOIN public.film f
	ON f.film_id = i.film_id
WHERE EXTRACT(YEAR FROM r.rental_date) = 2005
GROUP BY f.rating
)
SELECT rating
FROM CTE_TOTAL_FILMS_RENTED
WHERE total_rentals > 50
----------------------------------------------------------------------------------------------------------------------------
-- EXERCISE 2 --
-- Identify the categories of films that have an average rental duration greater than 5 days. Only consider films rated 'PG' or 'G'.
WITH CTE_AVG_RENTAL_DURATION AS
(
SELECT DISTINCT
	f.film_id,
	f.rating,
	ROUND(AVG(EXTRACT(DAY FROM (r.return_date - r.rental_date))),2) AS avg_rental_duration
FROM public.inventory i
INNER JOIN public.rental r
	ON i.inventory_id = r.inventory_id
INNER JOIN public.film f
	ON f.film_id = i.film_id
WHERE LOWER(CAST(f.rating AS TEXT)) = 'pg'
	OR LOWER(CAST(f.rating AS TEXT)) = 'g'
GROUP BY
	f.rating,
	f.film_id	
HAVING ROUND(AVG(EXTRACT(DAY FROM (r.return_date - r.rental_date))),2) > 5
)	
SELECT
	DISTINCT ca.name
FROM public.film_category fc
INNER JOIN public.category ca
	ON fc.category_id = ca.category_id
INNER JOIN CTE_AVG_RENTAL_DURATION
	ON CTE_AVG_RENTAL_DURATION.film_id = fc.film_id
----------------------------------------------------------------------------------------------------------------------------	
-- EXERCISE 3 --
-- Determine the total rental amount collected from each customer. List only those customers who have spent more than $100 in total.
SELECT
	cu.customer_id,
	cu.first_name,
	cu.last_name,
	SUM(p.amount) AS total_payment
FROM public.payment p
INNER JOIN public.customer cu
	ON cu.customer_id = p.customer_id
GROUP BY
	cu.customer_id,
	cu.first_name,
	cu.last_name
HAVING SUM(p.amount) > 100
----------------------------------------------------------------------------------------------------------------------------
-- EXERCISE 4 -- 
-- Create a temporary table containing the names and email addresses of customers who have rented more than 10 films.
DROP TABLE IF EXISTS temp_more_than10;
CREATE TEMPORARY TABLE temp_more_than10 AS
(
SELECT
	cu.first_name,
	cu.last_name,
	cu.email,
	COUNT(r.rental_id) AS total_rentals
FROM public.customer cu
INNER JOIN public.rental r
	ON r.customer_id = cu.customer_id
INNER JOIN public.inventory i
	ON i.inventory_id = r.inventory_id
GROUP BY 
	cu.first_name,
	cu.last_name,
	cu.email
HAVING COUNT(r.rental_id) > 10
);
CREATE INDEX idx_temp_more_than10 ON temp_more_than10(first_name,last_name);
SELECT * FROM temp_more_than10
----------------------------------------------------------------------------------------------------------------------------
-- EXERCISE 5 --
-- From the temporary table created in Task 3.1, identify customers who have a Gmail email address (i.e., their email ends with '@gmail.com').
SELECT
	first_name,
	last_name
FROM temp_more_than10 
WHERE LOWER(email) ILIKE '%gmail.com'
----------------------------------------------------------------------------------------------------------------------------
-- EXERCISE 6 -- 
-- 6.1. Start by creating a CTE that finds the total number of films rented for each category.
-- 6.2. Create a temporary table from this CTE.
-- 6.3. Using the temporary table, list the top 5 categories with the highest number of rentals. Ensure the results are in descending order.
DROP TABLE IF EXISTS temp_CTE;
CREATE TEMPORARY TABLE TEMPORARY_CTE AS 
	WITH CTE_TOTAL_FILMS_RENTED_PER_CAT AS
	(
	SELECT
		ca.name AS category_name,
		COUNT(DISTINCT r.rental_id) total_rentals_percat
	FROM public.rental r
	INNER JOIN public.inventory i
		ON i.inventory_id = r.inventory_id
	INNER JOIN public.film f
		ON f.film_id = i.film_id
	INNER JOIN public.film_category fc
		ON fc.film_id = f.film_id
	INNER JOIN public.category ca
		ON ca.category_id = fc.category_id
	GROUP BY ca.name
	)
SELECT * FROM CTE_TOTAL_FILMS_RENTED_PER_CAT;

CREATE INDEX idx_TEMPORARY_CTE ON TEMPORARY_CTE(category_name);

SELECT category_name
FROM TEMPORARY_CTE
ORDER BY total_rentals_percat DESC
LIMIT 5
----------------------------------------------------------------------------------------------------------------------------
-- EXERCISE 7 --
-- Identify films that have never been rented out. Use a combination of CTE and LEFT JOIN for this task.
WITH CTE_ALL_FILMS AS
(
SELECT
	f.film_id,
	i.inventory_id,
	f.title
FROM public.film f
LEFT JOIN public.inventory i
	ON f.film_id = i.film_id
)
SELECT DISTINCT
	cte.film_id,
	cte.title
FROM CTE_ALL_FILMS cte
LEFT JOIN rental r
	ON cte.inventory_id = r.inventory_id
WHERE r.rental_id is NULL
-- NOTE: We considered films that are also not available in the inventory.
----------------------------------------------------------------------------------------------------------------------------
-- EXERCISE 8 --
-- (INNER JOIN): Find the names of customers who rented films
-- with a replacement cost greater than $20 and which belong to the 'Action' or 'Comedy' categories.
SELECT DISTINCT
	cu.customer_id,
	cu.first_name,
	cu.last_name
FROM public.customer cu
INNER JOIN public.rental r
	ON cu.customer_id = r.customer_id
INNER JOIN public.inventory i
	ON i.inventory_id = r.inventory_id
INNER JOIN public.film f
	ON f.film_id = i.film_id
INNER JOIN public.film_category fc
	ON fc.film_id = f.film_id
INNER JOIN public.category ca
	ON ca.category_id = fc.category_id
WHERE f.replacement_cost > 20
	AND ca.name IN ('Comedy','Action')
----------------------------------------------------------------------------------------------------------------------------
-- EXERCISE 9 --
-- (LEFT JOIN): List all actors who haven't appeared in a film with a rating of 'R'.
WITH CTE_ACTOR_RATING_R AS
(
	SELECT fc.actor_id
	FROM public.film_actor fc
	LEFT JOIN public.film f
		ON f.film_id = fc.film_id
	WHERE f.rating = 'R'
)
SELECT
	act2.first_name,
	act2.last_name
FROM public.actor act2
LEFT OUTER JOIN CTE_ACTOR_RATING_R
	ON CTE_ACTOR_RATING_R.actor_id = act2.actor_id
WHERE CTE_ACTOR_RATING_R.actor_id IS NULL
----------------------------------------------------------------------------------------------------------------------------
-- EXERCISE 10 --
-- (Combination of INNER JOIN and LEFT JOIN): Identify customers who have never rented a film from the 'Horror' category.
WITH CTE_CUSTOMERS_RENTED_HORROR AS
(
SELECT
	ca.name,
	r.customer_id
FROM public.rental r
INNER JOIN public.inventory i
	ON r.inventory_id = i.inventory_id
INNER JOIN public.film_category fc
	ON fc.film_id = i.film_id
INNER JOIN public.category ca
	ON ca.category_id = fc.category_id
WHERE ca.name = 'Horror'
)
SELECT
	cu.first_name,
	cu.last_name
FROM public.customer cu
LEFT OUTER JOIN CTE_CUSTOMERS_RENTED_HORROR
	ON CTE_CUSTOMERS_RENTED_HORROR.customer_id = cu.customer_id
WHERE CTE_CUSTOMERS_RENTED_HORROR.name IS NULL
----------------------------------------------------------------------------------------------------------------------------
-- EXERCISE 11 --
-- (Multiple INNER JOINs): Find the names and email addresses of customers who rented films directed by a specific actor
-- (let's say, for the sake of this task,that the actor's first name is 'Nick' and last name is 'Wahlberg',
-- although this might not match actual data in the DVD Rental database).
WITH CTE_FILMS_NICK_IS_IN AS
(
SELECT fa.film_id
FROM public.actor act
INNER JOIN public.film_actor fa
	ON act.actor_id = fa.actor_id
WHERE act.first_name = 'Nick'
	AND act.last_name = 'Wahlberg'
)
SELECT
	cu.first_name,
	cu.last_name,
	cu.email
FROM public.customer cu
INNER JOIN public.rental r
	ON r.customer_id = cu.customer_id
INNER JOIN public.inventory i
	ON i.inventory_id = r.inventory_id
INNER JOIN CTE_FILMS_NICK_IS_IN
	ON CTE_FILMS_NICK_IS_IN.film_id = i.film_id







