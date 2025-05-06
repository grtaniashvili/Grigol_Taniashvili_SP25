--TASK 1
-- CREATE VIEW 
--
CREATE OR REPLACE VIEW new_table AS
SELECT 
	ROW_NUMBER () OVER (PARTITION BY year ORDER BY country_region, channel_desc) AS row_num,
	country_region,
	channel_desc,
	year,
	amount_sold,
	SUM(amount_sold) OVER (PARTITION BY country_region, year) AS total_year_region
FROM (
	SELECT 
		c.country_region,
		ch.channel_desc,
		EXTRACT (YEAR FROM s.time_id) AS year,
		--WHOLE TABLE SUM AMOUNTS GROUP BY YEAR, COUNTRY_REGION, CHANNEL_DESC
		ROUND(SUM(s.amount_sold), 0) AS amount_sold
	FROM 
		sh.sales s
		INNER JOIN sh.channels ch ON s.channel_id = ch.channel_id
		INNER JOIN sh.customers cust ON s.cust_id = cust.cust_id
		INNER JOIN sh.countries c ON c.country_id = cust.country_id
	WHERE 
		country_region IN ('Americas', 'Asia', 'Europe') AND 
		EXTRACT (YEAR FROM s.time_id) IN (1998, 1999, 2000, 2001) AND channel_desc != 'Tele Sales'
	GROUP BY c.country_region, ch.channel_desc, EXTRACT (YEAR FROM s.time_id)
	ORDER BY year
) AS subquery
ORDER BY year, country_region, channel_desc;
--

--QUERY FOR GET ANSWER
SELECT
	country_region,
	channel_desc,
	year,
	amount_sold,
	"% by channels",
	--PRECENT FOR EACH COUNTRY_REGION, CHANNEL_DESC AND YEAR FROM SALES TO TOTAL SALE OF THAT GROUP
	CONCAT(ROUND(100 * prev_amount_sold / prev_total_year_region, 2), '%') AS "% previous period",
	--DIFFERENCE BETWEEN PERCENTS
	CONCAT(ROUND((ROUND(100 * amount_sold / total_year_region, 2) - ROUND(100 * prev_amount_sold / prev_total_year_region, 2)), 2), '%') AS "% diff"
FROM (
	SELECT 
		row_num,
		country_region,
		channel_desc,
		year,
		amount_sold,
		total_year_region,
		CONCAT(ROUND(100 * amount_sold / total_year_region, 2), '%') AS "% by channels",
		--PUT VALUES IN ANOTHERS CELLS FOR FUTURE COUNTINGS
		LAG(amount_sold, 9) OVER (ORDER BY year) AS prev_amount_sold,
		LAG(total_year_region, 9) OVER (ORDER BY year) AS prev_total_year_region
	FROM new_table
) AS subquery
WHERE year IN (1999, 2000, 2001);
--
--TASK 2
--
SELECT
	*,
	CASE
		WHEN week_day = 'monday' THEN ROUND(AVG(cum_sum) OVER (ORDER BY time_id ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING), 2)
		WHEN week_day = 'friday' THEN ROUND(AVG(cum_sum) OVER (ORDER BY time_id ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING), 2)
		ELSE ROUND(AVG(cum_sum) OVER (ORDER BY time_id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2)
	END AS centered_3_day_avg
FROM (
	SELECT 
		EXTRACT(WEEK FROM time_id) AS week_number,
		time_id, 
		--ADDED FOR GET WEEK DAY AND 'FMDAY' FOR GETING DAY OF WEEK WITHOUT SPACES
		TO_CHAR (time_id, 'FMDAY') AS week_day,
		SUM(amount_sold) AS cum_sum,
		SUM(SUM(amount_sold)) OVER (PARTITION BY EXTRACT(WEEK FROM time_id) ORDER BY time_id RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales
	FROM sh.sales s 
	WHERE EXTRACT (YEAR FROM time_id) = 1999 AND EXTRACT(WEEK FROM time_id) IN (49, 50, 51)
	GROUP BY time_id
);
--

--TASK 3

CREATE TABLE IF NOT EXISTS example (
	country VARCHAR, date DATE, sales INTEGER
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_triplet
ON example (country, date, sales);

INSERT INTO example (country, date, sales)
VALUES
	('usa', '2025-04-09', 100),
	('usa', '2025-04-09', 100),
	('usa', '2025-04-10', 100),
	('usa', '2025-04-11', 100),
	('usa', '2025-04-13', 100),
	('uk', '2025-04-15', 100),
	('uk', '2025-04-16', 100),
	('uk', '2025-04-16', 100)
ON CONFLICT DO NOTHING;

--USING ROWS
--REASON FOR CHOOSING ROWS: THE ROWS FRAME IS USEFUL WHEN YOU WANT TO INCLUDE A SPECIFIC NUMBER OF ROWS BEFORE AND AFTER THE CURRENT ROW.
--IN THIS EXAMPLE, IT SUMS THE SALES FOR EACH COUNTRY INCLUDING THE CURRENT ROW, THE ROW BEFORE, AND THE ROW AFTER. THIS IS HELPFUL WHEN
--YOU WANT TO CONSIDER A FIXED NUMBER OF ROWS AROUND THE CURRENT ROW.
SELECT 
	country,
	date,
	sales,
	SUM(sales) OVER (PARTITION BY country ORDER BY date ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS rows_sum_sales
FROM example
ORDER BY date;

--USING RANGE
--REASON FOR CHOOSING RANGE: THE RANGE FRAME IS USEFUL WHEN YOU WANT TO INCLUDE ALL ROWS WITHIN A SPECIFIC RANGE OF VALUES. IN THIS CASE,
--IT SUMS THE SALES FOR EACH COUNTRY WITHIN A 1 DAY RANGE BEFORE AND AFTER THE CURRENT DATE. THIS IS HELPFUL WHEN YOU WANT TO ACCOUNT 
--FOR ALL SALES WITHIN A CERTAIN TIME WINDOW, REGARDLESS OF THE NUMBER OF ROWS.

SELECT 
	country,
	date,
	sales,
	SUM(sales) OVER (PARTITION BY country ORDER BY date RANGE BETWEEN INTERVAL '1' DAY PRECEDING AND INTERVAL '1' DAY FOLLOWING) AS range_sum_sales
FROM example
ORDER BY date;

--USING GROUPS
--REASON FOR CHOOSING GROUPS: THE GROUPS FRAME IS USEFUL WHEN YOU WANT TO INCLUDE GROUPS OF ROWS THAT HAVE THE SAME VALUES IN THE
--ORDERING COLUMN. IN THIS EXAMPLE, IT SUMS THE SALES FOR EACH COUNTRY INCLUDING THE CURRENT GROUP OF ROWS, THE GROUP BEFORE, AND
--THE GROUP AFTER. THIS IS HELPFUL WHEN YOU WANT TO CONSIDER GROUPS OF ROWS WITH THE SAME DATE VALUE

SELECT 
	country,
	date,
	sales,
	SUM(sales) OVER (PARTITION BY country ORDER BY date GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS groups_sum_sales
FROM example
ORDER BY date;
