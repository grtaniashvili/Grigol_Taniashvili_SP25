--TASK 1. WINDOW FUNCTIONS
--CREATE A QUERY TO GENERATE A REPORT THAT IDENTIFIES FOR EACH CHANNEL AND THROUGHOUT THE ENTIRE PERIOD, THE REGIONS WITH THE HIGHEST 
--QUANTITY OF PRODUCTS SOLD (QUANTITY_SOLD). 

--THE RESULTING REPORT SHOULD INCLUDE THE FOLLOWING COLUMNS:
--*CHANNEL_DESC
--*COUNTRY_REGION
--*SALES: THIS COLUMN WILL DISPLAY THE NUMBER OF PRODUCTS SOLD (QUANTITY_SOLD) WITH TWO DECIMAL PLACES.
--*SALES %: THIS COLUMN WILL SHOW THE PERCENTAGE OF MAXIMUM SALES IN THE REGION (AS DISPLAYED IN THE SALES COLUMN) COMPARED TO THE TOTAL SALES FOR THAT CHANNEL. THE SALES PERCENTAGE SHOULD BE DISPLAYED WITH TWO DECIMAL PLACES AND INCLUDE THE PERCENT SIGN (%) AT THE END.
--DISPLAY THE RESULT IN DESCENDING ORDER OF SALES

WITH 
sales_channel AS (
	SELECT 
		channel_desc,
		SUM(quantity_sold) AS sale_channel
	FROM
		sh.sales s
		INNER JOIN sh.channels ch USING (channel_id)
	GROUP BY channel_desc
),
sales_channel_region AS (
	SELECT 
		channel_desc,
		country_region,
		SUM(quantity_sold) AS total_sales_ch_region,
		MAX(SUM(quantity_sold)) OVER (PARTITION BY channel_desc) AS max_sales_region
	FROM 
		sh.sales s
		INNER JOIN sh.channels ch USING (channel_id)
		INNER JOIN sh.customers cust USING (cust_id)
		INNER JOIN sh.countries c USING (country_id)
	GROUP BY channel_desc, country_region	
)	
SELECT	
	scr.channel_desc,
	scr.country_region,
	TO_CHAR(ROUND(max_sales_region, 2), 'FM9,999,999,999,999,999.00') AS sales,
	TO_CHAR(ROUND(100 * max_sales_region/sale_channel, 2), 'FM9,999,999,999,999,999.00') || '%' AS "sales %"
FROM 
	sales_channel_region scr
	INNER JOIN sales_channel sc USING (channel_desc)
WHERE max_sales_region = total_sales_ch_region
ORDER BY max_sales_region DESC;	
	
	
	
--TASK 2. WINDOW FUNCTIONS
--IDENTIFY THE SUBCATEGORIES OF PRODUCTS WITH CONSISTENTLY HIGHER SALES FROM 1998 TO 2001 COMPARED TO THE PREVIOUS YEAR. 

--*DETERMINE THE SALES FOR EACH SUBCATEGORY FROM 1998 TO 2001.
--*CALCULATE THE SALES FOR THE PREVIOUS YEAR FOR EACH SUBCATEGORY.
--*IDENTIFY SUBCATEGORIES WHERE THE SALES FROM 1998 TO 2001 ARE CONSISTENTLY HIGHER THAN THE PREVIOUS YEAR.
--*GENERATE A DATASET WITH A SINGLE COLUMN CONTAINING THE IDENTIFIED PROD_SUBCATEGORY VALUES.

SELECT 
	prod_subcategory_desc
FROM (
	SELECT 
		prod_subcategory_desc,
		EXTRACT (YEAR FROM time_id) AS year,
		SUM(amount_sold),
		RANK () OVER(PARTITION BY prod_subcategory_desc ORDER BY SUM(amount_sold)) AS rank_num
	FROM 
		sh.sales s
		INNER JOIN sh.products p USING (prod_id)
	WHERE EXTRACT (YEAR FROM time_id) IN (1998, 1999, 2000, 2001)	
	GROUP BY prod_subcategory_desc, EXTRACT (YEAR FROM time_id)
) AS subquery
GROUP BY prod_subcategory_desc
HAVING 
	SUM(CASE WHEN year = 1998 AND rank_num = 1 THEN 1 ELSE 0 END) > 0 AND
	SUM(CASE WHEN year = 1999 AND rank_num = 2 THEN 1 ELSE 0 END) > 0 AND
	SUM(CASE WHEN year = 2000 AND rank_num = 3 THEN 1 ELSE 0 END) > 0 AND
	SUM(CASE WHEN year = 2001 AND rank_num = 4 THEN 1 ELSE 0 END) > 0;



--TASK 3. WINDOW FRAMES
--CREATE A QUERY TO GENERATE A SALES REPORT FOR THE YEARS 1999 AND 2000, FOCUSING ON QUARTERS AND PRODUCT CATEGORIES. IN THE REPORT
--YOU HAVE TO  ANALYZE THE SALES OF PRODUCTS FROM THE CATEGORIES 'ELECTRONICS,' 'HARDWARE,' AND 'SOFTWARE/OTHER,' ACROSS THE
--DISTRIBUTION CHANNELS 'PARTNERS' AND 'INTERNET'.

--THE RESULTING REPORT SHOULD INCLUDE THE FOLLOWING COLUMNS:
--*CALENDAR_YEAR: THE CALENDAR YEAR
--*CALENDAR_QUARTER_DESC: THE QUARTER OF THE YEAR
--*PROD_CATEGORY: THE PRODUCT CATEGORY
--*SALES$: THE SUM OF SALES (AMOUNT_SOLD) FOR THE PRODUCT CATEGORY AND QUARTER WITH TWO DECIMAL PLACES
--*DIFF_PERCENT: INDICATES THE PERCENTAGE BY WHICH SALES INCREASED OR DECREASED COMPARED TO THE FIRST QUARTER OF THE YEAR. FOR THE 
--FIRST QUARTER, THE COLUMN VALUE IS 'N/A.' THE PERCENTAGE SHOULD BE DISPLAYED WITH TWO DECIMAL PLACES AND INCLUDE THE PERCENT SIGN (%)
--AT THE END.
--*CUM_SUM$: THE CUMULATIVE SUM OF SALES BY QUARTERS WITH TWO DECIMAL PLACES
--*THE FINAL RESULT SHOULD BE SORTED IN ASCENDING ORDER BASED ON TWO CRITERIA: FIRST BY 'CALENDAR_YEAR,' THEN BY 'CALENDAR_QUARTER_DESC';
-- AND FINALLY BY 'SALES' DESCENDING

WITH 
new_table AS (	
	SELECT 
		EXTRACT (YEAR FROM time_id) AS calendar_year,
		EXTRACT (QUARTER FROM time_id) AS calendar_quarter_desc,
		prod_category,
		SUM(amount_sold) AS sales$,
		SUM(SUM(amount_sold)) OVER (PARTITION BY EXTRACT (YEAR FROM time_id) ORDER BY EXTRACT (QUARTER FROM time_id) 
		GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum$
	FROM 
		sh.sales s
		INNER JOIN sh.products p USING (prod_id)
		INNER JOIN sh.channels ch USING (channel_id)
	WHERE 
		EXTRACT (YEAR FROM time_id) IN (1999, 2000) 
		AND prod_category IN ('Electronics', 'Hardware', 'Software/Other') 
		AND channel_desc IN ('Partners', 'Internet') 
	GROUP BY 
		EXTRACT (YEAR FROM time_id),
		EXTRACT (QUARTER FROM time_id),
		prod_category
),
table_for_final_calculation AS (
	SELECT 
		calendar_year,
		calendar_quarter_desc,
		prod_category,
		sales$,
		FIRST_VALUE(sales$) OVER (PARTITION BY prod_category, calendar_year ORDER BY calendar_quarter_desc) AS first_quarter_sales$,
		cum_sum$
	FROM
		new_table
)	
SELECT 
	TO_CHAR(calendar_year, '9999') AS calendar_year,
	calendar_year || '-0' || calendar_quarter_desc AS calendar_quarter_desc,
	prod_category,
	TO_CHAR(ROUND(sales$, 2), '9,999,999,999.99') AS sales$,
	CASE 
		WHEN calendar_quarter_desc = 1 THEN 'N/A'
		ELSE TO_CHAR(100* (sales$ - first_quarter_sales$)/first_quarter_sales$, '9999999999.99') || '%'
	END AS diff_percent,
	cum_sum$
FROM table_for_final_calculation
ORDER BY calendar_year ASC, calendar_quarter_desc ASC, sales$ DESC;
