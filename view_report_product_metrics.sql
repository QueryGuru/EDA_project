/*
==================================================================================
-- Product Report
==================================================================================
Purpose: This report consolidates key product metrics and behaviour

-- Highlights:
	1. Gather Essential Fields such as Product name, category, sub-category and cost.
    2. Segment products by revenue to identify high performers, Mid-range or low performers.
    3. Aggregate product level metrics: 
		- total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
	4. Calcualte variable KPIs:
		- recency (months since last order)
        - average order value
        - average monthly revenue
==================================================================================
*/
CREATE VIEW datawarehouseanalytics.report_product AS
WITH base_query AS (
/*
----------------------------------------------------------------------------------
1) Base Query: Rerieves core columns from tables
----------------------------------------------------------------------------------*/
SELECT
	f.order_number,
    f.order_date,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost,
    f.sales_amount,
    f.quantity,
    f.customer_key
FROM
	datawarehouseanalytics.gold_fact_sales f
LEFT JOIN
	datawarehouseanalytics.gold_dim_products p
    ON p.product_key = f.product_key
WHERE order_date IS NOT NULL
),

product_aggregation AS (

-- Product Aggregation: Summarize key metrics at the product level 

SELECT
	product_key,
    product_name,
    category,
    subcategory,
    cost,
	COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    SUM(customer_key) AS total_customers,
    MAX(order_date) AS last_order_date,
    PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM MAX(order_date)), EXTRACT(YEAR_MONTH FROM MIN(order_date))) AS lifespan
FROM
	base_query
GROUP BY
	product_key,
    product_name,
    category,
    subcategory,
    cost
)

SELECT
	product_key,
    product_name,
    category,
    subcategory,
    cost,
    CASE
		WHEN total_sales < 100000 THEN 'Low-Performer'
        WHEN total_sales BETWEEN 100000 AND 1000000 THEN 'Mid_Range'
        ELSE 'High_Performer'
	END AS product_segment,
    last_order_date,
    TIMESTAMPDIFF(month, last_order_date, CURDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    lifespan,
-- Compute Average Order Value(AOV)
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE ROUND(total_sales/total_orders, 2)
	END AS avg_order_value,
-- Compute average monthly spend (AMS)
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE ROUND(total_sales/lifespan, 2)
	END AS avg_monthly_spend
FROM product_aggregation;

SELECT * FROM datawarehouseanalytics.report_product;
    