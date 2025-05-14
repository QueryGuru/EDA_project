/*
==================================================================================
-- Customer Report
==================================================================================
Purpose: This report consolidates key customer metrics and behaviour

-- Highlights:
	1. Gather Essential Fields such as names, ages and transaction details.
    2. Segment customers into categories (VIP, Regular, New) and age groups.
    3. Aggregate customer level metrics: 
		- total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
	4. Calcualte variable KPIs:
		- recency (months since last order)
        - average order value
        - average monthly spends
==================================================================================
*/
CREATE VIEW datawarehouseanalytics.report_customer AS 
WITH base_query AS (
/*
----------------------------------------------------------------------------------
1) Base Query: Rerieves core columns from tables
----------------------------------------------------------------------------------*/
SELECT
	f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    TIMESTAMPDIFF(year, c.birthdate, CURDATE()) AS age
FROM
	datawarehouseanalytics.gold_fact_sales f
LEFT JOIN
	datawarehouseanalytics.gold_dim_customers c
    ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL
),

customer_aggregation AS (

-- Customer Aggregation: Summarize key metrics at the customer level 

SELECT
	customer_key,
    customer_number,
    customer_name,
	age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM MAX(order_date)), EXTRACT(YEAR_MONTH FROM MIN(order_date))) AS lifespan
FROM
	base_query
GROUP BY
	customer_key,
    customer_number,
    customer_name,
	age
)

SELECT
	customer_key,
    customer_number,
    customer_name,
	age,
    CASE
		WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
	END AS age_group,
	CASE
		WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
    last_order_date,
    TIMESTAMPDIFF(month, last_order_date, CURDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,
-- Compute average order value (AOV)
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE total_sales/total_orders 
	END AS avg_order_value,
-- Compute average monthly spend (AMS)
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales/lifespan 
	END AS avg_monthly_spend
FROM
	customer_aggregation;
    
SELECT * FROM datawarehouseanalytics.report_customer;
