-- Use the correct database
USE datawarehouseanalytics;

-- CTE to calculate total sales by category
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold_fact_sales f
    LEFT JOIN gold_dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)

-- Final query to calculate part-to-whole percentage
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2) AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;
