-- Adjusting settings for the session
SET GLOBAL net_read_timeout = 600;
SET GLOBAL net_write_timeout = 600;
SET GLOBAL max_allowed_packet = 64M;

# GETTING FAMILIAR WITH DATA 
--  how many customers are there? 
select count(distinct customer) as No_of_customers from dim_customer;

# how many products are there?
select count(distinct product) as No_of_products from dim_product;

# how many markets are there?
select count(distinct market) as No_of_market from dim_customer;

#how many unique region are there?
select distinct region from dim_customer;

# how many divisions are there ?
select distinct division from dim_product;

# product categories, segment and variant 
select distinct segment from dim_product;
select distinct category from dim_product;
select distinct variant from dim_product;

# unique platforms and channels of atliq hardware 
select distinct platform from dim_customer;
select distinct channel from dim_customer;

#what are the fiscal year this data have?
select distinct fiscal_year from fact_sales_monthly;


#GENERIC QuESTIONS 
# 1. yearly sales & How does the monthly gross sales trend over the last two fiscal years?
select 
       fiscal_month,
       round(sum(total_gross_price)/1000000,2) as gross_price
from net_sales
where fiscal_year in (2021,2022)
group by fiscal_month;

# What is the region-wise contribution to total sales revenue?
select c.region,n.fiscal_year,
	   round(sum(net_sales)/1000000,2) as total_net_sales 
from net_sales n
join dim_customer c
on c.customer_code = n.customer_code
group by c.region, n.fiscal_year
order by c.region, n.fiscal_year desc;

# get cogs 
with cte1 as (
select 
	   mc.manufacturing_cost as manufacturing_cost,
       (n.total_gross_price * fc.freight_pct/100) as freight_cost,
       round((n.total_gross_price * fc.other_cost_pct/100),2) as other_cost
from net_sales n
join fact_manufacturing_cost mc
on mc.product_code = n.product_code and 
   mc.cost_year = n.fiscal_year
join fact_freight_cost fc
on fc.fiscal_year = n.fiscal_year
)
select *,
	   manufacturing_cost + freight_cost + other_cost as cogs
 from cte1;
 
 # yearly total sales 
SELECT 
      get_fiscal_year(date) as fiscal_year,
      round(sum(g.gross_price * s.sold_quantity),2) as yearly_sales
FROM fact_sales_monthly s
join fact_gross_price g 
on 
     g.product_code = s.product_code and 
     g.fiscal_year = get_fiscal_year(s.date)
where customer_code = '90002002'
group by get_fiscal_year(date)
order by fiscal_year;

/** as a product owner, i want to generate a report of a individual product sales (aggregated on a 
monthly basis at the product level) for croma india fy = 2021 so that i can track 
 individual product sales and run further product analytics 

the report should have this following columns
 1. month
2. product name 
3. variant
4. sold quantity
5. gross price per item
6. gross price total**/

select 
	 s.date, 
     s.fiscal_year, 
     s.customer_code,
     c.market,
     p.product_code, p.product, p.variant,
     s.sold_quantity, 
     g.gross_price as gross_price_per_item,
     round(g.gross_price * s.sold_quantity,2) as total_gross_price,
     pre.pre_invoice_discount_pct
from fact_sales_monthly s 
join dim_customer c 
   on c.customer_code = s.customer_code
join dim_product p 
   on p.product_code=s.product_code 
join fact_gross_price g 
   on g.product_code = s.product_code and 
   g.fiscal_year = s.fiscal_year
join fact_pre_invoice_deductions pre
   on pre.customer_code = s.customer_code and 
   pre.fiscal_year = s.fiscal_year
where 
     get_fiscal_year(s.date) = 2021 and 
     s.customer_code = 90002002;

#gross sales report monthly
select s.date, 
       sum(round(g.gross_price * s.sold_quantity,2)) as total_gross_price 
from fact_sales_monthly s 
join fact_gross_price g 
on g.product_code = s.product_code and 
   g.fiscal_year = get_fiscal_year(s.date)
where s.customer_code = 90002002 
group by s.date; 

# TOP 5 MARKETS IN THE YEAR 2021 
SELECT market,
	   round(sum(net_sales)/1000000,2) as net_sales
FROM gdb0041.net_sales
where fiscal_year = 2021
group by market
order by net_sales desc limit 5;

#TOP 5 CUSTOMERS BY NETSALES
select c.customer,
	  round(sum(net_sales)/1000000,2) as net_sales_mln
from dim_customer c 
join net_sales n 
on n.customer_code = c.customer_code
where n.fiscal_year = 2021 and c.market = "india"
group by c.customer
order by net_sales_mln desc limit 5 ;

#TOP 5 PRODUCT BY NETSALES 
select product,
	   round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales n 
join dim_customer c 
on c.customer_code = n.customer_code
where n.fiscal_year = 2021 and c.market = "india"
group by product
order by net_sales_mln desc 
limit 5 ;

#want to see a report for fy = 2021 for top 10 customers by % netsales 
with cte1 as (
select c.customer,
	  round(sum(net_sales)/1000000,2) as net_sales_mln
from dim_customer c 
join net_sales n 
on n.customer_code = c.customer_code
where fiscal_year = 2021 
group by c.customer)
select *,
	    net_sales_mln*100/sum(net_sales_mln) over() as pct 
from cte1
order by net_sales_mln desc ;

/**want to see region wise % by netsales by customers in a respective region 
so that i can perform by regional analysis on financial performance of the company **/
with cte1 as(
select c.customer, c.region,
	   round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales n 
join dim_customer c 
on c.customer_code = n.customer_code 
where fiscal_year = 2021 
group by c.region, c.customer
)
select *,
       net_sales_mln*100/sum(net_sales_mln) over(partition by region) as pct 
from cte1
order by region,net_sales_mln desc;

# get top n products n each division by their quantity sold (another way)
with cte1 as (
              select division, product,
                     sum(sold_quantity) as total_qty
		      from net_sales 
              where fiscal_year = 2021
              group by division, product
			),
     cte2 as(           
              select *,
					dense_rank() over(partition by division order by total_qty desc) as drnk
			  from cte1
			 )
select * from cte2 where drnk <=3;

/**as a product owner, i want to generate a report of a individual product sales (aggregated on a 
monthly basis at the product level) for croma india fy = 2021 so that i can track  individual product sales and run further product analytics **/
with cte1 as(
            select 
                  n.market, c.region,
				  round(sum(total_gross_price)/1000000,2)as gross_sales_mln
			from net_sales n 
			join dim_customer c 
                  on c.customer_code = n.customer_code
            where n.fiscal_year = 2021
            group by n.market, c.region
			),
    cte2 as(        
select *, 
	   dense_rank() over(partition by region order by gross_sales_mln desc) as drnk
from cte1 
		    )
	select * from cte2 where drnk <= 2;


