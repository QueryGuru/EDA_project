-- Use the correct database
USE datawarehouseanalytics;

-- =======================================
-- 1. Product Segmentation by Cost Ranges
-- =======================================
WITH product_base AS (
    SELECT
        product_key,
        product_name,
        cost
    FROM gold_dim_products
),
product_segments AS (
    SELECT
        product_key,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM product_base
),
product_summary AS (
    SELECT 
        cost_range,
        COUNT(product_key) AS total_products
    FROM product_segments
    GROUP BY cost_range
)

SELECT * FROM product_summary
ORDER BY total_products DESC;


-- ====================================================
-- 2. Customer Segmentation by Lifespan and Spending
-- ====================================================
WITH customer_base AS (
    SELECT
        c.customer_key,
        f.order_date,
        f.sales_amount
    FROM gold_fact_sales f
    LEFT JOIN gold_dim_customers c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
),
customer_spending AS (
    SELECT
        customer_key,
        SUM(sales_amount) AS total_spending,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM customer_base
    GROUP BY customer_key
),
segmented_customers AS (
    SELECT 
        customer_key,
        CASE 
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
),
segment_summary AS (
    SELECT 
        customer_segment,
        COUNT(customer_key) AS total_customers
    FROM segmented_customers
    GROUP BY customer_segment
)

SELECT * FROM segment_summary
ORDER BY total_customers DESC;
