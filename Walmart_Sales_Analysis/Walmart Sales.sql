CREATE DATABASE sales_walmart;
SET SQL_SAFE_UPDATES = 0;

CREATE TABLE Sales_data(
              invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
              branch VARCHAR(5) NOT NULL,
              city VARCHAR(30) NOT NULL,
              customer_type VARCHAR(30) NOT NULL,
              gender VARCHAR(10) NOT NULL,
              product_line VARCHAR(100) NOT NULL,
              unit_price DECIMAL(10,2) NOT NULL,
              quantity INT NOT NULL,
              VAT FLOAT NOT NULL,
              total DECIMAL(12,4) NOT NULL,
              date DATETIME NOT NULL,
              time TIME NOT NULL,
              payment_method VARCHAR(15) NOT NULL,
			  cogs DECIMAL(10,2) NOT NULL,
              gross_margin_pct FLOAT,
              gross_income DECIMAL(12,4) NOT NULL,
              rating FLOAT
);

select * from Sales_data;

-- FEATURE ENGINEERING 
-- ADD COLUMN - time_of_day

SELECT 
      time,
      (CASE 
          WHEN 'time' BETWEEN '00:00:00' AND '12:00:00' THEN "Morning"
          WHEN 'time' BETWEEN '12:01:00' AND '16:00:00' THEN "Afternoon"
		  ELSE "Evening" 
      END
      ) AS time_of_day
FROM Sales_data;

#ALTER TABLE 
ALTER TABLE Sales_data ADD COLUMN time_of_day VARCHAR(20);

#UPDATE THIS COLUMN
UPDATE Sales_data 
SET time_of_day = (
                   CASE 
          WHEN 'time' BETWEEN '00:00:00' AND '12:00:00' THEN "Morning"
          WHEN 'time' BETWEEN '12:01:00' AND '16:00:00' THEN "Afternoon"
		  ELSE "Evening" 
      END
);

-- ADD COLUMN - DAY_NAME
SELECT 
	date,
    dayname(date)
FROM Sales_data;

-- ALTER TABLE 
ALTER TABLE Sales_data ADD COLUMN day_name VARCHAR(10);

#UPDATE THE TABLE 
UPDATE Sales_data
SET day_name = dayname(date);

#ADD COLUMN - MONTH NAME 
SELECT 
     date,
     monthname(date)
from Sales_data;

#ALTER TABLE 
ALTER TABLE Sales_data ADD COLUMN month_name VARCHAR(10);

#UPDATE THE TABLE 
UPDATE Sales_data
SET month_name = monthname(date);

-- BASIC BUSINESS QUESTIONS 

-- ANALYSIS ON DATA ------

-- How many unique cities does the data have?
SELECT DISTINCT city FROM Sales_data;

-- In which city is each branch?
SELECT DISTINCT city, branch FROM Sales_data;

-- How many unique product lines does the data have
SELECT DISTINCT product_line from Sales_data;

--  PRODUCT ANALYSIS -----

-- What is the most selling product line
SELECT product_line,
	   sum(quantity) as quantity
from Sales_data
group by product_line
order by quantity desc;

-- What is the total revenue for product line by month
SELECT month_name AS Month,
       product_line,
       sum(total) AS Total_Revenue
from Sales_data
group by month_name,product_line
order by Total_Revenue;

-- What month had the largest COGS?
SELECT month_name AS Month,
       sum(cogs) as COGS 
FROM  Sales_data 
group by Month 
order by COGS desc;
    
-- What product line had the largest revenue?
SELECT product_line,
       SUM(ROUND(total,2)) AS Total_Revenue
FROM Sales_data
group by product_line
order by Total_Revenue desc;

-- What is the city with the largest revenue?
SELECT city,
	   branch,
       SUM(ROUND(total,2)) AS Total_Revenue
FROM Sales_data
GROUP BY city, branch
ORDER BY Total_Revenue;

-- What product line had the largest VAT?
SELECT product_line,
       ROUND(SUM(VAT),2) AS VAT
FROM Sales_data
group by product_line
order by VAT desc;

-- Fetch each product line and add a column to those product 
-- line showing "Good", "Bad". Good if its greater than average sales 

SELECT 
      product_line,
      ROUND(SUM(total),2) as total,
      ROUND(AVG(total),2) as Avg,
      CASE WHEN AVG(total)<SUM(total) THEN "GOOD" ELSE "BAD" END  AS Status
FROM Sales_data
GROUP BY product_line;

-- Which branch sold more products than average product sold?
SELECT branch,
       SUM(quantity) AS QTY
FROM Sales_data
GROUP BY branch
HAVING SUM(quantity) > (select AVG(quantity) FROM Sales_data)
ORDER BY QTY DESC;
      
-- What is the most common product line by gender
SELECT
	gender,
    product_line,
    COUNT(gender) AS total_cnt
FROM Sales_data
GROUP BY gender, product_line
ORDER BY total_cnt DESC;

-- What is the average rating of each product line
SELECT
	ROUND(AVG(rating), 2) as avg_rating,
    product_lin
FROM Sales_data
GROUP BY product_line
ORDER BY avg_rating DESC;

-- CUSTOMER ANALSYIS ------
-- How many unique customer types does the data have?
SELECT
	DISTINCT customer_type
FROM Sales_data;

-- How many unique payment methods does the data have?
SELECT
	DISTINCT payment
FROM Sales_data;

-- What is the most common customer type?
SELECT
	customer_type,
	count(*) as count
FROM Sales_data
GROUP BY customer_type
ORDER BY count DESC;

-- What is the gender of most of the customers?
SELECT
	gender,
	COUNT(*) as gender_cnt
FROM Sales_data
GROUP BY gender
ORDER BY gender_cnt DESC;

-- What is the gender distribution per branch?
SELECT
	gender, branch,
	COUNT(*) as gender_cnt
FROM Sales_data
GROUP BY gender,branch
ORDER BY gender_cnt,branch DESC;

-- Which time of the day do customers give most ratings?
SELECT
	time_of_day,
	AVG(rating) AS avg_rating
FROM Sales_data
GROUP BY time_of_day
ORDER BY avg_rating DESC;

-- Which time of the day do customers give most ratings per branch?
SELECT
	time_of_day,
	AVG(rating) AS avg_rating
FROM Sales_data
WHERE branch = "A"
GROUP BY time_of_day
ORDER BY avg_rating DESC;

-- Which day fo the week has the best avg ratings?
SELECT
	day_name,
	ROUND(AVG(rating),2) AS avg_rating
FROM Sales_data
GROUP BY day_name 
ORDER BY avg_rating DESC;

-- -----SALES ANALYSIS -----
-- Number of sales made in each time of the day per weekday 
SELECT
	time_of_day,
	COUNT(*) AS total_sales
FROM Sales_data
WHERE day_name = "Sunday"
GROUP BY time_of_day 
ORDER BY total_sales DESC;

-- Which of the customer types brings the most revenue?
SELECT
	customer_type,
	SUM(total) AS total_revenue
FROM Sales_data
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- Which customer type pays the most in VAT?
SELECT
	customer_type,
	AVG(VAT) AS total_tax
FROM Sales_data
GROUP BY customer_type
ORDER BY total_tax;

-- What is the highest and lowest total sales recorded?
SELECT 
    MAX(total) AS highest_sales, 
    MIN(total) AS lowest_sales 
FROM 
    sales_data;

-- Which branch generates the highest total revenue?
SELECT 
    branch, 
    SUM(total) AS total_revenue 
FROM sales_data
GROUP BY branch
ORDER BY total_revenue DESC
LIMIT 1; 

-- How many invoices were generated for customer_type "Member" and "Non-Member"?
SELECT 
    customer_type, 
    COUNT(invoice_id) AS number_of_invoices 
FROM sales_data
GROUP BY customer_type;

-- Average Rating Provided by Male vs. Female Customers

SELECT 
    gender, 
    AVG(rating) AS average_rating 
FROM sales_data
GROUP BY gender;

-- Proportion of Sales Between "Member" and "Non-Member" Customers
SELECT 
    customer_type, 
    SUM(total) AS total_sales,
    SUM(total) * 100 / (SELECT SUM(total) FROM sales_data) AS sales_proportion_percentage
FROM sales_data
GROUP BY customer_type;

-- ---- Advanced Analysis -----

-- Branch with the Highest Number of Transactions for "Members"
SELECT 
    branch, 
    COUNT(invoice_id) AS number_of_transactions 
FROM sales_data
WHERE customer_type = 'Member'
GROUP BY branch
ORDER BY number_of_transactions DESC
LIMIT 1;

-- Count payment methods and number of transactions by payment method
SELECT 
    payment_method,
    COUNT(*) AS no_payments
FROM Sales_data
GROUP BY payment_method;

-- Find different payment methods, number of transactions, and quantity sold by payment method
SELECT 
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM Sales_data
GROUP BY payment_method;

-- Identify the highest-rated category in each branch
-- Display the branch, product line, and avg rating
SELECT branch, product_line , avg_rating
FROM (
    SELECT 
        branch,
        product_line,
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rnk
    FROM Sales_data
    GROUP BY branch, product_line
) AS ranked
WHERE rnk = 1;

-- Identify the busiest day for each branch based on the number of transactions
SELECT branch, day_name, no_transactions
FROM (
    SELECT 
        branch,
		day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM sales_data
    GROUP BY branch, day_name
) AS ranked
WHERE rnk = 1;

-- Calculate the total quantity of items sold per payment method
SELECT 
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM Sales_data
GROUP BY payment_method;

-- Determine the average, minimum, and maximum rating of categories for each city
SELECT 
    city,
    product_line,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM Sales_data
GROUP BY city, product_line;

-- Calculate the total profit for each product_line
SELECT 
    product_line,
    SUM(unit_price * quantity * gross_income) AS total_profit
FROM sales_data
GROUP BY product_line
ORDER BY total_profit DESC;

 -- Determine the most common payment method for each branch
WITH cte AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM Sales_data
    GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM cte
WHERE rnk = 1;

-- Categorize sales into Morning, Afternoon, and Evening shifts
SELECT
    branch,
    CASE 
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM Sales_data
GROUP BY branch, shift
ORDER BY branch, num_invoices DESC;

