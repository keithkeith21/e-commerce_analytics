
CREATE TABLE dim_orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE dim_products (
    product_id VARCHAR(50),
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
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(20),
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

CREATE TABLE dim_customers (
    customer_id VARCHAR(50),
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

create table raw_reviews (
review_id varchar(200),
order_id varchar(200),
review_score int,
review_comment_title varchar(255),
review_comment_message TEXT,
review_creation_date datetime,
review_answer_timestamp datetime
);

create table dim_items (
order_id varchar(250),
order_item_id varchar (250),
product_id varchar (250),
seller_id varchar (250),
shipping_limit_date datetime,
price decimal(10,2),
freight_value decimal (10,2) );

CREATE TABLE fact_sales (
    sales_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    order_item_id INT,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    payment_value DECIMAL(10,2),
    review_score INT,
    purchase_timestamp DATETIME,
    delivery_timestamp DATETIME
);
insert into dim_payments (order_id, payment_sequential, payment_type, payment_installments, payment_value)
SELECT
  trim(upper(order_id)) as order_id,
  payment_sequential, 
  CASE WHEN payment_type = 'not_defined' THEN 'Unknown' ELSE payment_type END AS payment_type,
  payment_installments,
  payment_value 
FROM raw_payments;


insert into dim_reviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
SELECT
    trim(upper(review_id)) as review_id,
    MAX(trim(upper((order_id)))) AS order_id,
    MAX(review_score) AS review_score,
    MAX(COALESCE(NULLIF(review_comment_title, ''), 'unknown')) AS review_comment_title,
    MAX(COALESCE(NULLIF(review_comment_message, ''), 'unknown')) AS review_comment_message,
    MAX(review_creation_date) AS review_creation_date,
    MAX(review_answer_timestamp) AS review_answer_timestamp
FROM raw_reviews
GROUP BY review_id; 

insert into dim_customers (customer_id, customer_unique_id,  customer_zip_code_prefix, customer_city, customer_state)
select 
trim(upper(customer_id)) as customer_id,
trim(upper(customer_unique_id)) as customer_unique_id,
customer_zip_code_prefix,
case when customer_city = 'sao paulo' then 'são paulo' else customer_city end  as customer_city,
customer_state
from raw_customers; 

insert into dim_products (product_id, product_category_name, product_name_lenght,  product_description_lenght,
product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
select 
trim(upper(product_id)) as product_id,
coalesce(nullif (product_category_name, ''),'unkown') as product_category_name,
coalesce(nullif (product_name_lenght, 0), 0) as product_name_lenght,
coalesce(nullif (product_description_lenght, 0),0)as product_description_lenght,
coalesce(nullif (product_photos_qty, 0),0) as product_photos_qty,
coalesce(nullif (product_weight_g, 0),0) as product_weight_g,
coalesce(nullif (product_length_cm, 0),0) as product_length_cm,
coalesce(nullif (product_height_cm, 0),0) as product_height_cm,
coalesce(nullif (product_width_cm, 0),0) as product_width_cm
 from raw_products;
 
insert into dim_sellers  (seller_id, seller_zip_code_prefix, seller_city, seller_state)
select distinct
trim(upper(seller_id)) as seller_id,
seller_zip_code_prefix,
case when seller_city = 'sao paulo' then 'são paulo' else seller_city end as seller_city,
seller_state
from raw_sellers
;

insert into dim_items (order_id,order_item_id,product_id,seller_id,shipping_limit_date,price,freight_value)
select
trim(upper(order_id)) as order_id,
order_item_id,
product_id,
seller_id ,
shipping_limit_date,
price,
freight_value
from raw_items;

insert into dim_orders (order_id,
customer_id,
order_status,
order_purchase_timestamp,
order_approved_at,
order_delivered_carrier_date,
order_delivered_customer_date,
order_estimated_delivery_date)
select 
trim(upper(order_id)) as order_id,
trim(upper(customer_id)) as customer_id,
order_status,
nullif (order_purchase_timestamp, '') as order_purchase_timestamp,
nullif (order_approved_at,'') as order_approved_at,
nullif (order_delivered_carrier_date,'') as order_delivered_carrier_date,
nullif (order_delivered_customer_date,'') as order_delivered_customer_date,
nullif (order_estimated_delivery_date,'') as order_estimated_delivery_date
from raw_orders;

insert into dim_geolocations (geolocation_zip_code_prefix,geolocation_lat,geolocation_lng,geolocation_city,geolocation_state)
select 
geolocation_zip_code_prefix,
cast(geolocation_lat as decimal (10,2)),
cast(geolocation_lng as decimal (10,2)),
case when geolocation_city = 'sao paulo' then 'são paulo' else geolocation_city end as geolocation_city,
geolocation_state
from raw_geolocations;

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
JOIN dim_orders o
    ON i.order_id = o.order_id;
