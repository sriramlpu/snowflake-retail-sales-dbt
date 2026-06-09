-- rfm_segmentation.sql: RFM Customer Scoring for Superstore

{{ config(materialized='table') }}

WITH customer_metrics AS (
      SELECT
          customer_id,
          customer_name,
          segment,
          region,
          state,
          DATEDIFF('day', MAX(order_date), CURRENT_DATE())  AS recency_days,
          COUNT(DISTINCT order_id)                          AS frequency,
          ROUND(SUM(sales), 2)                              AS monetary,
          ROUND(SUM(profit), 2)                             AS total_profit,
          MIN(order_date)                                   AS first_order_date,
          MAX(order_date)                                   AS last_order_date
      FROM {{ ref('fct_sales') }}
      GROUP BY 1, 2, 3, 4, 5
  ),

rfm_scores AS (
      SELECT
          *,
          NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,
          NTILE(5) OVER (ORDER BY frequency DESC)     AS f_score,
          NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
      FROM customer_metrics
  ),

rfm_combined AS (
      SELECT
          *,
          (r_score + f_score + m_score)               AS rfm_total,
          CONCAT(r_score::VARCHAR, f_score::VARCHAR, m_score::VARCHAR) AS rfm_string,
          CASE
              WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
              WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
              WHEN r_score >= 4 AND f_score <= 2                  THEN 'New Customers'
              WHEN r_score >= 3 AND f_score >= 3 AND m_score <= 2 THEN 'Potential Loyalists'
              WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
              WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Cannot Lose Them'
              WHEN r_score = 1  AND f_score = 1                   THEN 'Lost'
              ELSE 'Needs Attention'
          END AS rfm_segment
      FROM rfm_scores
  )

SELECT
    customer_id, customer_name, segment AS customer_type,
    region, state, recency_days, frequency, monetary, total_profit,
    r_score, f_score, m_score, rfm_total, rfm_string, rfm_segment,
    first_order_date, last_order_date,
    CURRENT_TIMESTAMP() AS _loaded_at
FROM rfm_combined
ORDER BY rfm_total DESC
