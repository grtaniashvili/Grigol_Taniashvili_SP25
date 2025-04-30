--Task 1
with new_table as (
	select ch.channel_desc, s.amount_sold, s.cust_id, c.cust_first_name, c.cust_last_name
	from sh.sales s
	inner join sh.channels ch on s.channel_id = ch.channel_id
	inner join sh.customers c on s.cust_id = c.cust_id
	),
	ranked_table as (
	select
		cust_id,
		cust_first_name,
		cust_last_name,
		channel_desc,
		sum(amount_sold) as cust_sold,
		sum(sum(amount_sold)) over (partition by channel_desc) as total_sold_channel,
		row_number() over (partition by channel_desc order by sum(amount_sold) desc) as row_num
	from new_table
	group by channel_desc, cust_id, cust_first_name, cust_last_name
	)
--
select 
	cust_id,
	cust_first_name || ' ' || cust_last_name as cust_full_name,
	channel_desc,
	to_char(round(cust_sold, 2), 'FM999999999.00') as customer_sold,
	-- count procents with five decimal places and % sign
	concat(round((cust_sold/total_sold_channel)*100, 5), '%') as sales_percent,
	to_char(round(total_sold_channel, 2), 'FM999999999.00') as total_sol_channel
from ranked_table
where row_num <=5
order by channel_desc, row_num;

--task 2

create extension if not exists tablefunc;

--create view
create or replace view temp_ranked as
	select 
		prod_name,
		country_name,
		round(sum(amount_sold), 2) as total_amount
	from (
		select 
			p.prod_name,
			p.prod_category,
			c.country_name, 
			c.country_region, 
			s.amount_sold, 
			s.time_id
		from sh.sales s
		inner join sh.products p on s.prod_id = p.prod_id
		inner join sh.customers cust on s.cust_id = cust.cust_id
		inner join sh.countries c on c.country_id = cust.country_id
	) as subquery
	where extract(year from time_id) = 2000 and country_region = 'Asia' and prod_category = 'Photo'
	group by prod_name, country_name;

--create answer table sales by countries
select 
	prod_name,
	Japan,
	Singapore,
	--
	to_char(round(sum(coalesce(japan, 0) + coalesce(singapore, 0)) over (partition by prod_name), 2),'FM999999999.00') as year_sum
from (
-- used function crosstab for create cross table
	select *
	from crosstab (
		'select prod_name, country_name, total_amount from temp_ranked order by 1, 2',
		'select distinct country_name from temp_ranked order by 1'
	) as ct(prod_name varchar(50), Japan numeric, Singapore numeric)
) as subquery;


--Task 3


--create CTE   
with ranking_table as(
select 
    cus.cust_id,
    cus.cust_last_name,
    cus.cust_first_name,
    c.channel_desc,
    extract (year from time_id) as years,  --extract years from dates
    sum(s.amount_sold) as amount_sold,  --sum by grouping by customer, channel, year
    dense_rank() over(partition by c.channel_desc, extract (year from time_id) order by sum(s.amount_sold) desc) as rnk  -- ranking without gaps
from 
    sh.sales s 
    inner join sh.customers cus on cus.cust_id = s.cust_id 
    inner join sh.channels c on c.channel_id = s.channel_id
where 
    extract (year from time_id) in (1998, 1999, 2001) --customer be in top300 for one time in 1998 or/and 1999 or/and 2001
group by 
    cus.cust_id,
    c.channel_desc,
    extract (year from time_id)
)
--query from ranking_table    
select 
    cust_id,
    cust_last_name,
    cust_first_name,
    channel_desc,
    to_char(sum(amount_sold), '999999999.99') as amount_sold --sum by grouping customer, channel and format to text with nice two decimals after point
from 
    ranking_table
where 
    rnk <= 300
group by 
    cust_id,
    cust_last_name,
    cust_first_name,
    channel_desc
having 
    count(years) = 3  --customers must be in all 1998 and 1999 and 2001 years 
order by 
    amount_sold desc;


-- it is no needed in this Task, but I hold it for future
--create func for get top300 by channel specified
create or replace function sh.channel_top300_cust (channel_desc_in varchar(20))
returns table (
    row_number bigint,
    channel_desc varchar(20),
    full_name varchar,
    amount_sold numeric   
) as $$
begin
    return query
    select
        subquery.row_number,
        ch.channel_desc,
        cast(subquery.cust_last_name || ' ' || subquery.cust_first_name as varchar) as full_name,  -- cast full_name to varchar
        subquery.amount_sold        
    from (
        select 
            extract(year from time_id) as years,
            ch.channel_desc,
            c.cust_last_name,
            c.cust_first_name,
            s.amount_sold,
			--divide by channel and sort desc by amount
            row_number() over (partition by ch.channel_desc order by s.amount_sold desc) as row_number
        from sh.sales s
        inner join sh.channels ch on s.channel_id = ch.channel_id
        inner join sh.customers c on s.cust_id = c.cust_id
        
        where extract(year from time_id) in (1998, 1999, 2001) 
        and ch.channel_desc = channel_desc_in
    ) as subquery
    inner join sh.channels ch on ch.channel_desc = subquery.channel_desc
	-- how many rows needed	
    where subquery.row_number <= 300;
end;
$$ language plpgsql;
	
-- call func	
select * from sh.channel_top300_cust('Internet');	
select * from sh.channel_top300_cust('Direct Sales');	
	
	
--Task 4

create or replace view prod_region_date as
	select 
		extract (year from s.time_id) || '-' || extract (month from s.time_id) as year_month,
		prod_category,
		country_region as region,
		sum(amount_sold) as total_sale
	from 
		sh.sales as s
		inner join sh.customers cust on s.cust_id = cust.cust_id 
		inner join sh.countries c on c.country_id = cust.country_id
		inner join sh.products p on p.prod_id = s.prod_id
	where 
		extract (year from s.time_id) = 2000 and
		extract (month from s.time_id) in (1, 2, 3) and
		country_region in ('Europe', 'Americas')
	group by
		extract (year from s.time_id),
		extract (month from s.time_id),
		country_region,
		prod_category;
	
--use query with subquery ... renaiming columns and show only is not null	
	select *
	from (
	select 
		year_month,
		prod_category,	
		lag(total_sale) over (partition by year_month, prod_category order by region) as americas,
		total_sale as europa,
		sum(total_sale) over (partition by year_month, prod_category order by region) as total
	from prod_region_date
) as subquery
where americas is not null;
	
	
	
--2 variant. here I did it with crosstab 

with 
	prod_region_date as (
		select 
			extract (year from s.time_id) || '-' || extract (month from s.time_id) as year_month,
			prod_category,
			country_region as region,
			sum(amount_sold) as total_sale
		from 
			sh.sales as s
			inner join sh.customers cust on s.cust_id = cust.cust_id 
			inner join sh.countries c on c.country_id = cust.country_id
			inner join sh.products p on p.prod_id = s.prod_id
		where 
			extract (year from s.time_id) = 2000 and
			extract (month from s.time_id) in (1, 2, 3) and
			country_region in ('Europe', 'Americas')
		group by
			extract (year from s.time_id),
			extract (month from s.time_id),
			country_region,
			prod_category
),
	crosstab_null as (
		select *
		from 
			crosstab(
			--in first query we need all column from result table ... using ORDER BY ensures that the distinct products are listed in alphabetical order
			'SELECT year_month, prod_category, region, total_sale FROM prod_region_date ORDER BY prod_category, region, year_month',
			--in second query we choose columns for new table
			'SELECT DISTINCT region FROM prod_region_date ORDER BY region'
			) as ct(year_month varchar, prod_category varchar, Americas numeric(10, 2), Europe numeric(10, 2))
)
select 
	year_month,
	prod_category,
	sum(coalesce(Americas, 0)) as Americas,
	sum(coalesce(Europe, 0)) as Europe
from 
	crosstab_null
group by year_month, prod_category
order by year_month, prod_category;
