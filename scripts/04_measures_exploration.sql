-- Use the correct database
USE datawarehouseanalytics;

-- Find the Total Sales
SELECT SUM(sales_amount) AS total_sales FROM gold_fact_sales;

-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity FROM gold_fact_sales;

-- Find the average selling price
SELECT AVG(price) AS avg_price FROM gold_fact_sales;

-- Find the total number of orders
SELECT COUNT(order_number) AS total_orders FROM gold_fact_sales;

-- Find the distinct number of orders (to avoid duplicates)
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold_fact_sales;

-- Find the total number of products
SELECT COUNT(DISTINCT product_name) AS total_products FROM gold_dim_products;

-- Find the total number of customers
SELECT COUNT(customer_key) AS total_customers FROM gold_dim_customers;

-- Find the total number of customers that have placed an order
SELECT COUNT(DISTINCT customer_key) AS active_customers FROM gold_fact_sales;

-- Generate a report that shows all key metrics of the business
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold_fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold_fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold_fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold_fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_name) FROM gold_dim_products
UNION ALL
SELECT 'Total Customers', COUNT(customer_key) FROM gold_dim_customers
UNION ALL
SELECT 'Active Customers', COUNT(DISTINCT customer_key) FROM gold_fact_sales;
