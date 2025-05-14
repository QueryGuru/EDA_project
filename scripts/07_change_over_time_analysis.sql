-- Use the correct database
USE datawarehouseanalytics;

-- 🔹 Analyze sales performance by year and month
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold_fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);

-- 🔹 Grouping by Month (MySQL equivalent of DATETRUNC)
SELECT
    DATE_FORMAT(order_date, '%Y-%m-01') AS month_start_date,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold_fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
ORDER BY month_start_date;

-- 🔹 Monthly Label View (MySQL equivalent of FORMAT 'yyyy-MMM')
SELECT
    DATE_FORMAT(order_date, '%Y-%b') AS month_label,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold_fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%b')
ORDER BY STR_TO_DATE(month_label, '%Y-%b');
