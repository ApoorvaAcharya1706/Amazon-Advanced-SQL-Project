--AMAZON Advanced SQL Project

--CREATON OF TABLES

--category table

CREATE TABLE category
(
category_id INT PRIMARY KEY,
category_name VARCHAR(20)
);

--customers table

CREATE TABLE customers
(
customer_id	INT PRIMARY KEY,
first_name VARCHAR(20),
last_name VARCHAR(20),
state VARCHAR(20),
address VARCHAR(5) DEFAULT ('xxxx')
);

--sellers table

CREATE TABLE sellers
(
seller_id INT PRIMARY KEY,
seller_name	VARCHAR(25),
origin VARCHAR(5)
);

--update data type

ALTER TABLE sellers
ALTER COLUMN origin VARCHAR(10);

--products table

CREATE TABLE products
(
product_id INT PRIMARY KEY,
product_name VARCHAR(50),
price FLOAT,
cogs FLOAT,
category_id INT, --FK
CONSTRAINT products_fk_category FOREIGN KEY(category_id) REFERENCES category(category_id)
);

--orders table

CREATE TABLE orders
(
order_id INT PRIMARY KEY,
order_date date,
customer_id INT, --FK
seller_id INT, --FK
order_status VARCHAR(15),
CONSTRAINT orders_fk_customers FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
CONSTRAINT orders_fk_sellers FOREIGN KEY(seller_id) REFERENCES sellers(seller_id)
);

--order items table

CREATE TABLE order_items
(
order_item_id INT PRIMARY KEY,
order_id INT, --FK
product_id INT, --FK
quantity INT,
price_per_unit FLOAT,
CONSTRAINT order_items_fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id),
CONSTRAINT order_items_fk_products FOREIGN KEY(product_id) REFERENCES products(product_id)
);

--payments table

CREATE TABLE payments
(
payment_id INT PRIMARY KEY,
order_id INT, --FK
payment_date date,
payment_status VARCHAR(20),
CONSTRAINT payments_fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id)
);


--shipping table

CREATE TABLE shipping
(
shipping_id INT PRIMARY KEY,
order_id INT, --FK
shipping_date date,
return_date	date,
shipping_providers VARCHAR(30),
delivery_status VARCHAR(20),
CONSTRAINT shipping_fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id)
);


/* SQL Server treats empty date fields as 1900-01-01 when the column is of type DATE or DATETIME and
no explicit NULL handling is specified */

UPDATE shipping
SET return_date = NULL
WHERE return_date = '1900-01-01';

--inventory table

CREATE TABLE inventory
(
inventory_id INT PRIMARY KEY,
product_id INT, --FK
stock INT,
warehouse_id INT,
last_stock_date date,
CONSTRAINT inventory_fk_products FOREIGN KEY(product_id) REFERENCES products(product_id)
);


