# Brazilian E-commerce Platform: Advanced Data Engineering & Star Schema Warehousing
**By:** Jasfher Pantoja  
**Role:** Data Engineer / Database Architect  
**Tools:** MySQL

 (Advanced ETL, Data Modeling, Schema Design)

---

## 1. Project Overview
This project delivers a robust backend data warehousing solution for a massive Brazilian e-commerce dataset (comprising over 100k+ multi-table retail transactions). I developed a fully optimized **Data Warehouse** from messy, unstructured "flat" staging files and structured them into a high-performance **Star Schema** architecture using advanced SQL ETL pipelines to ensure data integrity and ready-to-query tables.

---

## 2. The Problem Statement & "Dirty" Kaggle Data Challenge
The raw Olist dataset from Kaggle presented several data quality and design issues that make reporting inaccurate and query speeds sluggish:
* **Inconsistent Text Formatting & Casing:** IDs contained trailing spaces and random text casing, destroying data integrity during table joins.
* **Geographical Data Anomalies:** Critical cities like São Paulo were formatted inconsistently (e.g., `sao paulo` vs `são paulo`), leading to fragmented regional analysis.
* **Duplicate Review Identifiers:** The `raw_reviews` table contained duplicated `review_id` keys with conflicting entries.
* **Unmanaged Missing Data:** Critical fields contained strings like `'not_defined'` or blank values instead of true database flags.

---

## 3. Advanced ETL & Star Schema Warehouse Architecture (MySQL)
I designed and executed an advanced ETL (Extract, Transform, Load) pipeline using MySQL to normalize the data into **1 Fact Table (`fact_sales`)** and **8 Dimension Tables**. 

### Critical Data Cleaning Implementations:
* **String Standardization:** Applied `TRIM(UPPER())` to all Primary and Foreign keys to guarantee flawless entity resolution.
* **Deduplication Strategy:** Handled duplicate review entries by aggregating the `raw_reviews` table using `GROUP BY review_id` combined with windowing logic (`MAX()`).
* **Text Encoding & Data Cleansing:** Standardized Portuguese geographical names using `CASE WHEN` conditions to unify regional sales boundaries (e.g., merging `'sao paulo'` into `'são paulo'`).
* **Null & Faulty Value Handling:** Utilized `COALESCE()` and `NULLIF()` to translate empty metrics or strings like `'not_defined'` into readable categories like `'Unknown'`.

### Data Warehouse Structure:
* **Fact Table:** `fact_sales` (Aggregates sales performance, metrics, and grain identifiers).
* **Dimension Tables:** `dim_orders`, `dim_products`, `dim_sellers`, `dim_customers`, `dim_payments`, `dim_geolocations`, `dim_reviews`, and `dim_items`.

---

## 4. Analytical Insights & Business Value (Sample Queries)

Once the schema was built and the data warehouse was populated, I executed advanced analytical queries to extract critical business metrics directly from the backend:

### Query 1: Top 5 Product Categories by Revenue
*This query aggregates sales volume to find out which categories generate the highest total revenue.*
```sql
SELECT 
    p.product_category_name, 
    SUM(f.price) AS total_revenue
FROM fact_sales f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 5;
```

### Query 2: Most Preferred Payment Methods
*Analyzing consumer behavior based on how orders are settled.*
```sql
SELECT 
    payment_type, 
    COUNT(*) AS usage_count,
    SUM(payment_value) AS total_payment_value
FROM dim_payments
GROUP BY payment_type
ORDER BY usage_count DESC;
```

### Query 3: Regional Sales Performance (Top 5 States)
*Identifying which Brazilian states drive the most sales volume.*
```sql
SELECT 
    c.customer_state, 
    COUNT(f.order_id) AS total_orders,
    SUM(f.price) AS total_sales
FROM fact_sales f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_sales DESC
LIMIT 5;
```

---

## 5. Database Visual Model
<img width="951" height="662" alt="Screenshot 2026-06-24 102352" src="https://github.com/user-attachments/assets/ec777cfd-afe3-4430-a4e9-b6a5e72cc10d" />



---

## 6. Conclusion
By decoupling the messy staging datasets and crafting a strict Star Schema, this project demonstrates how backend data engineering optimizes query performance and ensures data accuracy across sales values, payment distributions, and seller performance metrics. The architecture is fully prepared for seamless integration into business intelligence tools like Power BI or Tableau.
