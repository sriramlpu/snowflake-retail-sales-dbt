# Retail Sales Analytics with Snowflake + dbt

Dimensional data model on the Kaggle Sample Superstore dataset with Snowflake SQL and dbt.

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=flat&logo=snowflake&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-FF694B?style=flat&logo=dbt&logoColor=white)

## Dataset
Kaggle Sample Superstore: ~10k retail orders, 4 years of US superstore data.
Fields: Order ID, dates, segment, region, product category, sales, profit, discount.

## Project Structure
```
snowflake-retail-sales-dbt/
├── setup/snowflake_setup.sql
├── dbt_project/
│   ├── dbt_project.yml
│   └── models/
│       ├── staging/stg_orders.sql
│       └── marts/
│           ├── core/dim_customers.sql
│           ├── core/dim_products.sql
│           ├── core/fct_sales.sql
│           └── marketing/rfm_segmentation.sql
└── analyses/business_questions.sql
```

## Business Questions & Answers

### Q1. Which product categories are most profitable?
See: [analyses/business_questions.sql](analyses/business_questions.sql)
Technology leads with ~17% margin. Furniture (Tables sub-category) has negative profit.

### Q2. What is the quarterly sales and profit trend?
See: [analyses/business_questions.sql](analyses/business_questions.sql)
LAG() window function shows QoQ growth. Q4 consistently peaks (+30% vs average).

### Q3. Which customers are high-value? (RFM Segmentation)
See: [dbt_project/models/marts/marketing/rfm_segmentation.sql](dbt_project/models/marts/marketing/rfm_segmentation.sql)
NTILE(5) scoring on Recency, Frequency, Monetary. Champions = R5+F5+M5.

### Q4. What discount levels erode profitability?
See: [analyses/business_questions.sql](analyses/business_questions.sql)
Discounts above 30% yield negative average profit across all categories.

### Q5. Which states have high revenue but poor margins?
See: [analyses/business_questions.sql](analyses/business_questions.sql)
Texas: $170k revenue, negative profit. Classic margin-leak identification.

### Q6. Impact of ship mode on profitability?
See: [analyses/business_questions.sql](analyses/business_questions.sql)
Same Day is 2x more profitable per order vs. Standard Class.

### Q7. Rolling 3-month average profit by region?
See: [analyses/business_questions.sql](analyses/business_questions.sql)
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW window function per region.

### Q8. Top 10 customers by Customer Lifetime Value
See: [analyses/business_questions.sql](analyses/business_questions.sql)
RANK() OVER (ORDER BY SUM(profit) DESC) identifies top CLV customers.

## Snowflake Features Used
- Clustering keys on ORDER_DATE for micro-partition pruning
- - QUALIFY + ROW_NUMBER() for deduplication
  - - PIVOT for category-to-column transformation
    - - CLONE for zero-copy dev environments
     
      - ## dbt Concepts
      - - Star schema: dim_customers, dim_products, fct_sales
        - - Incremental models with unique_key
          - - Generic tests: not_null, unique, accepted_values
            - - Custom macros for fiscal year logic
