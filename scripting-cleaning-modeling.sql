
CREATE TABLE dim_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE dim_products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,               
    product_description_lenght INT,        
    product_photos_qty INT,
    product_weight_g DECIMAL(10,2),
    product_length_cm DECIMAL(10,2),
    product_height_cm DECIMAL(10,2),
    product_width_cm DECIMAL(10,2)
);

CREATE TABLE dim_sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(20),
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

CREATE TABLE dim_customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(20),
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

CREATE TABLE dim_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

CREATE TABLE dim_geolocations (
    geolocation_zip_code_prefix VARCHAR(20),
    geolocation_lat DECIMAL(10,6),
    geolocation_lng DECIMAL(10,6),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);


CREATE TABLE dim_reviews (
    review_id VARCHAR(200) PRIMARY KEY,
    order_id VARCHAR(200),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

CREATE TABLE dim_items (
    order_id VARCHAR(50),                  
    order_item_id VARCHAR(250),
    product_id VARCHAR(50),                
    seller_id VARCHAR(50),                 
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);


CREATE TABLE fact_sales (
    sales_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    order_item_id VARCHAR(250),
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    payment_value DECIMAL(10,2),
    review_score INT,
    purchase_timestamp DATETIME,
    delivery_timestamp DATETIME
);

INSERT INTO dim_payments (order_id, payment_sequential, payment_type, payment_installments, payment_value)
SELECT
    TRIM(UPPER(order_id)) AS order_id,
    payment_sequential, 
    CASE WHEN payment_type = 'not_defined' THEN 'Unknown' ELSE payment_type END AS payment_type,
    payment_installments,
    payment_value 
FROM raw_payments;

INSERT INTO dim_reviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
SELECT
    TRIM(UPPER(review_id)) AS review_id,
    MAX(TRIM(UPPER(order_id))) AS order_id,
    MAX(review_score) AS review_score,
    MAX(COALESCE(NULLIF(review_comment_title, ''), 'Unknown')) AS review_comment_title,
    MAX(COALESCE(NULLIF(review_comment_message, ''), 'Unknown')) AS review_comment_message,
    MAX(review_creation_date) AS review_creation_date,
    MAX(review_answer_timestamp) AS review_answer_timestamp
FROM raw_reviews
GROUP BY review_id; 

INSERT INTO dim_customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT 
    TRIM(UPPER(customer_id)) AS customer_id,
    TRIM(UPPER(customer_unique_id)) AS customer_unique_id,
    customer_zip_code_prefix,
    CASE WHEN customer_city = 'sao paulo' THEN 'são paulo' ELSE customer_city END AS customer_city,
    customer_state
FROM raw_customers; 

INSERT INTO dim_products (product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
SELECT 
    TRIM(UPPER(product_id)) AS product_id,
    COALESCE(NULLIF(product_category_name, ''), 'Unknown') AS product_category_name, 
    COALESCE(NULLIF(product_name_lenght, 0), 0) AS product_name_lenght,
    COALESCE(NULLIF(product_description_lenght, 0), 0) AS product_description_lenght,
    COALESCE(NULLIF(product_photos_qty, 0), 0) AS product_photos_qty,
    COALESCE(NULLIF(product_weight_g, 0), 0) AS product_weight_g,
    COALESCE(NULLIF(product_length_cm, 0), 0) AS product_length_cm,
    COALESCE(NULLIF(product_height_cm, 0), 0) AS product_height_cm,
    COALESCE(NULLIF(product_width_cm, 0), 0) AS product_width_cm
FROM raw_products;
 
INSERT INTO dim_sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state)
SELECT DISTINCT
    TRIM(UPPER(seller_id)) AS seller_id,
    seller_zip_code_prefix,
    CASE WHEN seller_city = 'sao paulo' THEN 'são paulo' ELSE seller_city END AS seller_city,
    seller_state
FROM raw_sellers;

INSERT INTO dim_items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
SELECT
    TRIM(UPPER(order_id)) AS order_id,
    order_item_id,
    TRIM(UPPER(product_id)) AS product_id,
    TRIM(UPPER(seller_id)) AS seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM raw_items;

INSERT INTO dim_orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
SELECT 
    TRIM(UPPER(order_id)) AS order_id,
    TRIM(UPPER(customer_id)) AS customer_id,
    order_status,
    NULLIF(order_purchase_timestamp, '') AS order_purchase_timestamp,
    NULLIF(order_approved_at, '') AS order_approved_at,
    NULLIF(order_delivered_carrier_date, '') AS order_delivered_carrier_date,
    NULLIF(order_delivered_customer_date, '') AS order_delivered_customer_date,
    NULLIF(order_estimated_delivery_date, '') AS order_estimated_delivery_date
FROM raw_orders;

INSERT INTO dim_geolocations (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
SELECT 
    geolocation_zip_code_prefix,
    geolocation_lat,                     
    geolocation_lng,                      
    CASE WHEN geolocation_city = 'sao paulo' THEN 'são paulo' ELSE geolocation_city END AS geolocation_city,
    geolocation_state
FROM raw_geolocations;


INSERT INTO fact_sales (
    order_id,
    customer_id,
    product_id,
    seller_id,
    order_item_id,
    price,
    freight_value,
    purchase_timestamp,
    delivery_timestamp
)
SELECT
    UPPER(TRIM(i.order_id)),
    UPPER(TRIM(o.customer_id)),
    UPPER(TRIM(i.product_id)),
    UPPER(TRIM(i.seller_id)),
    i.order_item_id,
    i.price,
    i.freight_value,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date
FROM dim_items i
JOIN dim_orders o ON i.order_id = o.order_id;
