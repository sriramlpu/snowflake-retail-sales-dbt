-- Superstore Business Questions SQL

-- Q1. Most profitable product categories
SELECT category, sub_category,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2)     AS total_sales,
    ROUND(SUM(profit), 2)    AS total_profit,
    ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100, 2) AS profit_margin_pct
FROM RETAIL_DB.MARTS.fct_sales
GROUP BY 1, 2 ORDER BY profit_margin_pct DESC;

-- Q2. Quarterly sales and profit trend
SELECT DATE_TRUNC('quarter', order_date) AS order_quarter,
    ROUND(SUM(sales), 2)  AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0*(SUM(sales)-LAG(SUM(sales)) OVER (ORDER BY DATE_TRUNC('quarter',order_date)))
          /NULLIF(LAG(SUM(sales)) OVER (ORDER BY DATE_TRUNC('quarter',order_date)),0),2) AS qoq_pct
FROM RETAIL_DB.MARTS.fct_sales
GROUP BY 1 ORDER BY 1;

-- Q4. Discount buckets causing profit erosion
SELECT
    CASE WHEN discount=0 THEN '0% None'
         WHEN discount<=0.10 THEN '1-10%'
         WHEN discount<=0.20 THEN '11-20%'
         WHEN discount<=0.30 THEN '21-30%'
         WHEN discount<=0.50 THEN '31-50%'
         ELSE '51%+' END AS discount_bucket,
    COUNT(*) AS rows,
    ROUND(SUM(profit),2) AS total_profit,
    ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM RETAIL_DB.MARTS.fct_sales
GROUP BY 1;

-- Q5. States: high revenue, negative margin
SELECT state, region,
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(SUM(profit),2) AS total_profit,
    ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM RETAIL_DB.MARTS.fct_sales
GROUP BY 1, 2
HAVING SUM(sales)>10000
ORDER BY total_profit ASC;

-- Q6. Ship mode impact on profit
SELECT ship_mode,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(AVG(DATEDIFF('day', order_date, ship_date)),1) AS avg_ship_days,
    ROUND(AVG(profit),2) AS avg_profit_per_order
FROM RETAIL_DB.MARTS.fct_sales
GROUP BY 1 ORDER BY avg_profit_per_order DESC;

-- Q7. Rolling 3-month avg profit by region
WITH mp AS (
      SELECT region, DATE_TRUNC('month', order_date) AS m,
          ROUND(SUM(profit),2) AS monthly_profit
      FROM RETAIL_DB.MARTS.fct_sales GROUP BY 1,2
  )
SELECT region, m AS order_month, monthly_profit,
    ROUND(AVG(monthly_profit) OVER (
          PARTITION BY region ORDER BY m
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3m_avg
FROM mp ORDER BY region, m;

-- Q8. Top 10 customers by lifetime profit (QUALIFY + RANK)
SELECT customer_id, customer_name, segment,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(sales),2) AS lifetime_sales,
    ROUND(SUM(profit),2) AS lifetime_profit,
    RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank
FROM RETAIL_DB.MARTS.fct_sales
GROUP BY 1, 2, 3
QUALIFY RANK() OVER (ORDER BY SUM(profit) DESC) <= 10
ORDER BY profit_rank;
