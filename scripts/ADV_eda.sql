
/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: EXTRACT(), DATE_TRUNC(), TO_CHAR()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/

-- Analyse sales performance over time
-- Quick Date Functions
SELECT
    EXTRACT(YEAR from order_date) AS order_year,
    EXTRACT(MONTH from order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(YEAR from order_date),EXTRACT(MONTH from order_date)
ORDER BY EXTRACT(YEAR from order_date),EXTRACT(MONTH from order_date);

-- DATE_TRUNC()
SELECT
    DATE_TRUNC('month', order_date) AS order_date,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date);

-- TO_CHAR()
SELECT
    TO_CHAR(order_date, 'yyyy-MM') AS order_date,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY TO_CHAR(order_date, 'yyyy-MM')
ORDER BY TO_CHAR(order_date, 'yyyy-MM');


/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
===============================================================================
*/
-- Calculate the total sales per month 
-- and the running total of sales over time 
SELECT
    order_month,
    total_sales,   
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,   
    AVG(avg_price) OVER (ORDER BY order_month) AS cumulative_avg_price
FROM (
    SELECT 
        DATE_TRUNC('month', order_date) AS order_month,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY order_month
) t
ORDER BY order_month;


/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */
WITH yearly_products_sales AS (
SELECT 
EXTRACT(YEAR FROM f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p 
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM f.order_date), p.product_name
)
SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name):: INT AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name):: INT AS diffavg,
CASE 
    WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name):: INT > 0 THEN 'Above avg'
    WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name):: INT < 0 THEN 'below avg'
    ELSE 'avg' 
END AS avg_change,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS yoydiff,
--ROUND((current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)) * 100.0 / NULLIF(LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year), 0), 2) AS percent_change,
CASE 
    WHEN LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) IS NULL THEN '0%'
    ELSE ROUND((current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)) * 100.0 / NULLIF(LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year), 0), 2) || '%'
END AS percent_change_label
FROM yearly_products_sales
ORDER BY product_name, order_year;

/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

/*Segment products into cost ranges and 
count how many products fall into each segment*/
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
        END AS cost_range
    FROM gold.dim_products
)
SELECT 
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
    	EXTRACT(YEAR FROM AGE(MAX(order_date),MIN(order_date)))*12 +
   		EXTRACT(MONTH FROM AGE(MAX(order_date),MIN(order_date))) AS lifespan
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
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
    FROM customer_spending
) AS segmented_customers
GROUP BY customer_segment
ORDER BY total_customers DESC;

/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/
-- Which categories contribute the most to overall sales?
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2)||'%' AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;


