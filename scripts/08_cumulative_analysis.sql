-- Use the correct database
USE datawarehouseanalytics;

-- CTE version for cumulative sales and moving average by year
WITH yearly_summary AS (
    SELECT 
        YEAR(order_date) AS order_year,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold_fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date)
)

SELECT
    order_year,
    total_sales,
    AVG(avg_price) OVER (ORDER BY order_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS moving_average_price,
    SUM(total_sales) OVER (ORDER BY order_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM yearly_summary;
