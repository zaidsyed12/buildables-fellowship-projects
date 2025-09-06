-- Database: buildables_task2

-- DROP DATABASE IF EXISTS buildables_task2;

CREATE DATABASE buildables_task2
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

CREATE TABLE dim_customers(
	customer_sk SERIAL primary key, -- Surrogate key for customer (auto-incremented)
	customer_id varchar(50) NOT NULL, 
	name varchar(100),
	email varchar(100), 
	effective_date date NOT NULL, 
	end_date DATE, 
	is_active CHAR(1) CHECK(is_active IN ('Y','N'))
);

CREATE TABLE dim_products(
	product_sk SERIAL PRIMARY KEY, -- Surrogate key for products (auto-incremented)
	product_id varchar(50) NOT NULL, -- Business key (unique product identifier)
	name varchar(100),
	category varchar(100)
);

-- dim table to store date-related information
CREATE TABLE dim_date(
	date_sk INTEGER PRIMARY KEY, 
	full_date date NOT NULL,
	year INTEGER NOT NULL,
	month INTEGER NOT NULL,
	day_of_week INTEGER NOT NULL
);

-- fact table to store measures
CREATE TABLE fact_orders(
	order_id BIGSERIAL PRIMARY KEY,
	order_date_sk INTEGER,
	customer_sk INTEGER,
	product_sk INTEGER,
	quantity INTEGER,
	price NUMERIC(10,2),
	total_amount NUMERIC(12,2) GENERATED ALWAYS as (quantity * price) STORED,
	CONSTRAINT fk_order_date FOREIGN KEY(order_date_sk) REFERENCES dim_date(date_sk),
	CONSTRAINT fk_customer FOREIGN KEY(customer_sk) REFERENCES dim_customers(customer_sk),
	CONSTRAINT fk_product FOREIGN KEY (product_sk) REFERENCES dim_products(product_sk)
);

INSERT INTO dim_customers (customer_id, name, email, effective_date, end_date, is_active)
VALUES
('C001', 'Ahmed Khan', 'ahmed.khan@abc.com', '2025-01-01', NULL, 'Y'),
('C002', 'Sara Ali', 'sara.ali@abc.com', '2022-01-01', NULL, 'Y'),
('C003', 'Umar Farooq', 'omar.farooq@abc.com', '2023-01-01', NULL, 'Y'),
('C004', 'Aisha Zaidi', 'aisha.zaidi@abc.com', '2025-01-01', NULL, 'Y'),
('C005', 'Yousuf Ali', 'yousuf.ali@abc.com', '2021-01-01', NULL, 'Y');

INSERT INTO dim_products (product_id, name, category)
VALUES
('P001', 'Iphone 15', 'Smartphones'),
('P002', 'Hp Laptop Pro 15', 'Laptops'),
('P003', 'Wireless Earbuds Z', 'Audio'),
('P004', 'Gaming Console GX', 'Gaming'),
('P005', 'Smartwatch Elite', 'Wearables');



INSERT INTO dim_date (date_sk, full_date, year, month, day_of_week)
VALUES
(20250901, '2025-09-01', 2025, 9, EXTRACT(ISODOW FROM DATE '2025-09-01')),
(20250902, '2025-09-02', 2025, 9, EXTRACT(ISODOW FROM DATE '2025-09-02')),
(20250903, '2025-09-03', 2025, 9, EXTRACT(ISODOW FROM DATE '2025-09-03')),
(20250904, '2025-09-04', 2025, 9, EXTRACT(ISODOW FROM DATE '2025-09-04')),
(20250905, '2025-09-05', 2025, 9, EXTRACT(ISODOW FROM DATE '2025-09-05'));

INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
VALUES
(20250901, 1, 1, 2, 999.9),
(20250901, 2, 3, 1, 1099.99),
(20250902, 1, 2, 3, 2250),
(20250902, 3, 4, 1, 12500.0),
(20250903, 4, 5, 5, 1000),
(20250903, 5, 1, 2, 3000),
(20250904, 2, 5, 1, 12000),
(20250904, 3, 2, 2, 12500),
(20250905, 4, 3, 1, 8700),
(20250905, 5, 4, 4, 6700);

-- Example of SCD Type-2: Closing old record for customer C002
-- closing old record
UPDATE dim_customers
SET end_date = '2025-02-09',
    is_active = 'N'
WHERE customer_id = 'C002' AND is_active = 'Y';

-- inserting new record with updated email and new surrogate key
INSERT INTO dim_customers (customer_id, name, email, effective_date, end_date, is_active)
SELECT customer_id, name, 'sara.ali@abc.com', '2025-09-10', NULL, 'Y'
FROM dim_customers
WHERE customer_id = 'C002' AND is_active = 'N'  -- copy name from previous row
LIMIT 1;
-- Select all records for customer C002 to see history with effective dates
SELECT * FROM dim_customers WHERE customer_id = 'C002' ORDER BY effective_date;

-- to calculate total revenue per product category
SELECT p.category, SUM(f.total_amount) AS total_revenue
FROM fact_orders f
JOIN dim_products p ON f.product_sk = p.product_sk
GROUP BY p.category
ORDER BY total_revenue DESC;

--monthly revenue trend
SELECT d.year, d.month, SUM(f.total_amount) AS total_revenue
FROM fact_orders f
JOIN dim_date d ON f.order_date_sk = d.date_sk
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- customers with a history of changes (SCD-2)
SELECT customer_id, COUNT(*) AS history_count
FROM dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY history_count DESC;

-- top 2 customers by total spend in each month
WITH MonthlySpend AS (
    SELECT 
        f.customer_sk, d.year, d.month, SUM(f.total_amount) AS total_spend
    FROM fact_orders f
    JOIN dim_date d ON f.order_date_sk = d.date_sk
    GROUP BY f.customer_sk, d.year, d.month
),
RankedCustomers AS (
    SELECT ms.year, ms.month, ms.customer_sk, ms.total_spend,
        ROW_NUMBER() OVER (PARTITION BY ms.year, ms.month ORDER BY ms.total_spend DESC) AS rank
    FROM MonthlySpend ms
)
SELECT year, month, customer_sk, total_spend
FROM RankedCustomers
WHERE rank <= 2
ORDER BY year, month, total_spend DESC;

-- customer order ranks by date using window function
SELECT f.order_id, f.customer_sk, f.order_date_sk, d.full_date, f.total_amount,
    RANK() OVER (PARTITION BY f.customer_sk ORDER BY d.full_date) AS order_rank
FROM fact_orders f
JOIN dim_date d ON f.order_date_sk = d.date_sk
ORDER BY f.customer_sk, order_rank;


