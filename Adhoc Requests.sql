# Request 1 : the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region
SELECT DISTINCT(market) FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";

# Request 2: percentage of unique product increase in 2021 vs. 2020
SELECT x.count_2020 AS unique_product_2020, y.count_2021 AS unique_product_2021, 
round((count_2021 - count_2020)*100/count_2020 ,2) AS percentage_of_change 
FROM
((SELECT COUNT(DISTINCT(product_code)) AS count_2020 
FROM fact_sales_monthly 
WHERE fiscal_year = 2020) x,
(SELECT COUNT(DISTINCT(product_code)) AS count_2021 
FROM fact_sales_monthly 
WHERE fiscal_year = 2021) y
);

# Request 3: the unique product counts for each segment and sort them in descending order of product counts.

SELECT p.segment, COUNT(DISTINCT(p.product_code)) AS product_count 
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
GROUP BY p.segment
ORDER BY product_count DESC;

# Request 4: Which segment had the most increase in unique products in 2021 vs 2020? 
# The final output contains these fields, segment, product_count_2020, product_count_2021, difference 

WITH prod_segment_2020 AS (
SELECT p.segment, COUNT(DISTINCT(p.product_code)) AS product_count 
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
GROUP BY s.fiscal_year,p.segment
HAVING s.fiscal_year = 2020),
prod_segment_2021 AS (
SELECT p.segment, COUNT(DISTINCT(p.product_code)) AS product_count 
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
GROUP BY s.fiscal_year, p.segment
HAVING s.fiscal_year = 2021)

SELECT p_2020.segment, p_2020.product_count AS unique_product_count_2020,
p_2021.product_count AS unique_product_count_2021, 
(p_2021.product_count - p_2020.product_count) AS difference
FROM prod_segment_2020 AS p_2020
JOIN prod_segment_2021 AS p_2021
ON p_2020.segment = p_2021.segment
ORDER BY difference DESC;

# Request 5: the products that have the highest and lowest manufacturing costs.

SELECT p.product, m.product_code, m.manufacturing_cost FROM fact_manufacturing_cost m
JOIN dim_product p
ON p.product_code = m.product_code
WHERE manufacturing_cost IN (
SELECT max(manufacturing_cost) FROM fact_manufacturing_cost
UNION
SELECT min(manufacturing_cost) FROM fact_manufacturing_cost);

#Request 6: the top 5 customers who received an average high  pre_invoice_discount_pct 
#for the  fiscal  year 2021  and in the #Indian  market. 

WITH avg_pre AS (
SELECT customer_code, AVG(pre_invoice_discount_pct) AS avg_pre_inv_disc
 FROM fact_pre_invoice_deductions
WHERE fiscal_year=2021
GROUP BY customer_code)
SELECT c.customer_code, c.customer, a.avg_pre_inv_disc AS average_discount_percentage 
FROM dim_customer c
JOIN avg_pre a
ON a.customer_code = c.customer_code
WHERE c.market = "India"
ORDER BY a.avg_pre_inv_disc DESC
LIMIT 5;

#Request 7: the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month 

SELECT monthname(x.date) AS Month, year(x.date) AS Year, x.gross_sales AS Gross_Sales_Amount 
FROM (
SELECT date, sum(s.sold_quantity * g.gross_price) AS gross_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON s.product_code = g.product_code AND s.fiscal_year = g.fiscal_year
JOIN dim_customer c
ON s.customer_code = c.customer_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY date) x
ORDER BY Year;

#Request 8 :In which quarter of 2020, got the maximum total_sold_quantity

SELECT fiscal_quarter(date) AS qr, SUM(sold_quantity) AS sum_qnt
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY qr
ORDER BY sum_qnt DESC;

#Request 9:channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution

WITH gs AS
(SELECT c.channel, SUM(s.sold_quantity * g.gross_price) AS gross_sales 
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON s.product_code = g.product_code AND s.fiscal_year = g.fiscal_year
JOIN dim_customer c
ON c.customer_code = s.customer_code
WHERE s.fiscal_year = 2021
GROUP BY c.channel
)

SELECT gs.channel AS Channel, gs.gross_sales AS Gross_Sales,
ROUND(gross_sales/(SELECT SUM(gross_sales) FROM gs) * 100, 2) AS percentage_contribution
FROM gs
ORDER BY gross_sales DESC;

#Request 10:Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021

WITH total_sales AS (
SELECT s.product_code, p.division,p.product, sum(s.sold_quantity) as total_sold_quantity 
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
WHERE fiscal_year=2021
GROUP BY s.product_code, p.division,p.product), 
ranking as (
SELECT product_code, product, division, total_sold_quantity,
RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_n
FROM total_sales)
SELECT division, product_code, product, total_sold_quantity, rank_n AS rank_order
FROM ranking
WHERE rank_n <=3;

