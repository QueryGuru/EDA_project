select * from datawarehouseanalytics.gold_dim_customers
limit 1000;

-- Change Over Time Trends

SELECT
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM
	datawarehouseanalytics.gold_fact_sales
WHERE
	order_date IS NOT NULL
GROUP BY
	YEAR(order_date), MONTH(order_date)
ORDER BY
	YEAR(order_date), MONTH(order_date);
    
-- Cumulative Analysis

-- Calculate total sales per month
-- and the running total sales over time

 SELECT
	MONTH(order_date) AS order_month,
    COUNT(customer_key) AS total_customers,
    SUM(quantity) AS total_quantity,
    SUM(sales_amount) AS total_sales,
    SUM(sales_amount) OVER (ORDER BY MONTH(order_date)) AS running_total_sales
FROM
	datawarehouseanalytics.gold_fact_sales
WHERE
	order_date IS NOT NULL
GROUP BY
	MONTH(order_date)
ORDER BY
	MONTH(order_date);

WITH monthly_sales AS (
	SELECT
		YEAR(order_date) AS order_year,
		MONTH(order_date) AS order_month,
		COUNT(DISTINCT customer_key) AS total_customers,
		SUM(quantity) AS total_quantity,
		SUM(sales_amount) AS total_sales
	FROM
		datawarehouseanalytics.gold_fact_sales
	WHERE
		order_date IS NOT NULL
	GROUP BY
		YEAR(order_date), MONTH(order_date)
)

SELECT
	order_year,
	order_month,
	total_customers,
    SUM(total_customers) OVER (ORDER BY order_year, order_month) AS running_total_customers,
	total_quantity,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_year, order_month) AS running_total_sales
FROM
	monthly_sales
ORDER BY
	order_year, order_month;

-- Performance Analysis

/* Analyze the yearly performance of products by comparing each products sales to 
both its average sales performance and the previous years sales */

WITH yearly_product_sales AS (
	SELECT
		YEAR(f.order_date) AS order_year,
		p.product_name,
		SUM(f.sales_amount) AS current_sales
	FROM
		datawarehouseanalytics.gold_fact_sales f
	LEFT JOIN
		datawarehouseanalytics.gold_dim_products p
		ON f.product_key = p.product_key
	WHERE
		f.order_date IS NOT NULL
	GROUP BY
		YEAR(f.order_date), p.product_name
)

SELECT
	order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
    CASE
		WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
	END avg_change,
-- YOY Analysis
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
	CASE
		WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increasing'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decreasing'
        ELSE 'No Change'
	END py_change
FROM
	yearly_product_sales
ORDER BY
	product_name, order_year;
    
-- Part to whole analysis 

-- which categories contribute the most to overall sales

WITH category_sales AS (
SELECT
	category,
    SUM(sales_amount) AS total_sales
FROM
	datawarehouseanalytics.gold_fact_sales f
LEFT JOIN
	datawarehouseanalytics.gold_dim_products p
	ON p.product_key = f.product_key
GROUP BY
	category
)

SELECT
	category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND((total_sales/SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM
	category_sales
ORDER BY
	total_sales DESC;
    
-- Data Segmentation 
/* Group the data based on a specific range*/
/* Helps Understand the correlation between two measures */

-- Problem Statement

/* Segment products into cost ranges and 
count how many products fall into each segment */

WITH product_segments AS (
SELECT
	product_key,
    product_name,
    cost,
    CASE
		WHEN cost < 100 THEN 'Below 100'
        WHEN cost BETWEEN 100 AND 500 THEN '100-500'
        WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
        ELSE 'Above 1000'
	END cost_range
FROM
	datawarehouseanalytics.gold_dim_products
)

SELECT
	cost_range,
    COUNT(product_key) AS total_products
FROM
	product_segments
GROUP BY
	cost_range
ORDER BY
	total_products DESC;
    
/* Group customers into three segments based on their spending behaviour:

 - VIP: at least 12 months of history and spending more than 5000 euro
 - Regular: at least 12 month of history and spending 5000 euro or less
 - New: lifespan less than 12 months.
 
 and find the total numbers of customers by each group */
 
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date) AS first_order,
        MAX(f.order_date) AS last_order,
        PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM MAX(f.order_date)), EXTRACT(YEAR_MONTH FROM MIN(f.order_date))) AS lifespan
    FROM
        datawarehouseanalytics.gold_fact_sales f
    LEFT JOIN
        datawarehouseanalytics.gold_dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_key
)

SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT
        customer_key,
        CASE
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM
        customer_spending
) AS t
GROUP BY
    customer_segment
ORDER BY	
    total_customers DESC;

