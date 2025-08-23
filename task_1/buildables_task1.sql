-- Step 1: Setup (Data Modeling & Table Creation)

CREATE TABLE customers (
customer_id SERIAL PRIMARY KEY,
name        VARCHAR(100),
email       VARCHAR(100) UNIQUE NOT NULL,
created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE products (
product_id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
category VARCHAR(100),
price NUMERIC(10,2) CHECK (price > 0)
);

CREATE TABLE IF NOT EXISTS orders (
order_id    SERIAL PRIMARY KEY,
customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
product_id  INT REFERENCES products(product_id) ON DELETE RESTRICT,
quantity    INT CHECK (quantity > 0),
order_date  TIMESTAMP DEFAULT NOW()
);

-- Insert Data into Tables

INSERT INTO customers (name, email) VALUES
('Muhammad Ali', 'm.ali@example.com'),
('Sara Ali', 'sara.ali@example.com'),
('Hamza Ahmed', 'hamza.ahmed@example.com'),
('Ayesha Siddiqui', 'ayesha.siddiqui@example.com'),
('Mutahir Qureshi', 'mutahir.qureshi@example.com'),
('Muntaha Noor', 'muntaha.noor@example.com'),
('Bilal Hussain', 'bilal.hussain@example.com'),
('Ahmed Khan', 'ahmed.khan@example.com'),
('Ahsan Khan', 'ahsan.khan@example.com'),
('Mariam Syed', 'mariam.syed@example.com');

INSERT INTO products (name, category, price) 
VALUES ('Wireless Mouse', 'Electronics', 2000),
	('Mechanical Keyboard', 'Electronics', 6000),
	('Padel racket', 'Sports', 15000),
	('American Eagle Jeans', 'Fashion', 20000),
	('Nurpur Milk 1-litre', 'Grocery', 350),
	('Choco Cookies', 'Food', 750);

Truncate Table orders;

INSERT INTO orders (customer_id, product_id, quantity, order_date) VALUES
-- Muhammad Ali
((SELECT customer_id FROM customers WHERE email='m.ali@example.com'),
 (SELECT product_id FROM products  WHERE name='Wireless Mouse'),
 1, NOW() - INTERVAL '20 days'),

((SELECT customer_id FROM customers WHERE email='m.ali@example.com'),
 (SELECT product_id FROM products  WHERE name='Nurpur Milk 1-litre'),
 3, NOW() - INTERVAL '19 days'),

((SELECT customer_id FROM customers WHERE email='m.ali@example.com'),
 (SELECT product_id FROM products  WHERE name='Mechanical Keyboard'),
 1, NOW() - INTERVAL '2 days'),

-- Sara Ali
((SELECT customer_id FROM customers WHERE email='sara.ali@example.com'),
 (SELECT product_id FROM products  WHERE name='Mechanical Keyboard'),
 1, NOW() - INTERVAL '18 days'),

((SELECT customer_id FROM customers WHERE email='sara.ali@example.com'),
 (SELECT product_id FROM products  WHERE name='American Eagle Jeans'),
 1, NOW() - INTERVAL '17 days'),

((SELECT customer_id FROM customers WHERE email='sara.ali@example.com'),
 (SELECT product_id FROM products  WHERE name='Wireless Mouse'),
 1, NOW() - INTERVAL '2 days'),

-- Hamza Ahmed
((SELECT customer_id FROM customers WHERE email='hamza.ahmed@example.com'),
 (SELECT product_id FROM products  WHERE name='Padel racket'),
 1, NOW() - INTERVAL '16 days'),

((SELECT customer_id FROM customers WHERE email='hamza.ahmed@example.com'),
 (SELECT product_id FROM products  WHERE name='Nurpur Milk 1-litre'),
 2, NOW() - INTERVAL '15 days'),

((SELECT customer_id FROM customers WHERE email='hamza.ahmed@example.com'),
 (SELECT product_id FROM products  WHERE name='American Eagle Jeans'),
 1, NOW() - INTERVAL '2 days'),
 
-- Ayesha Siddiqui
((SELECT customer_id FROM customers WHERE email='ayesha.siddiqui@example.com'),
 (SELECT product_id FROM products  WHERE name='Wireless Mouse'),
 2, NOW() - INTERVAL '14 days'),

((SELECT customer_id FROM customers WHERE email='ayesha.siddiqui@example.com'),
 (SELECT product_id FROM products  WHERE name='Mechanical Keyboard'),
 1, NOW() - INTERVAL '13 days'),

-- Mutahir Qureshi
((SELECT customer_id FROM customers WHERE email='mutahir.qureshi@example.com'),
 (SELECT product_id FROM products  WHERE name='American Eagle Jeans'),
 1, NOW() - INTERVAL '12 days'),

((SELECT customer_id FROM customers WHERE email='mutahir.qureshi@example.com'),
 (SELECT product_id FROM products  WHERE name='Padel racket'),
 1, NOW() - INTERVAL '11 days'),

-- Muntaha Noor
((SELECT customer_id FROM customers WHERE email='muntaha.noor@example.com'),
 (SELECT product_id FROM products  WHERE name='Nurpur Milk 1-litre'),
 4, NOW() - INTERVAL '10 days'),

((SELECT customer_id FROM customers WHERE email='muntaha.noor@example.com'),
 (SELECT product_id FROM products  WHERE name='Wireless Mouse'),
 1, NOW() - INTERVAL '9 days'),

-- Bilal Hussain
((SELECT customer_id FROM customers WHERE email='bilal.hussain@example.com'),
 (SELECT product_id FROM products  WHERE name='Padel racket'),
 2, NOW() - INTERVAL '8 days'),

((SELECT customer_id FROM customers WHERE email='bilal.hussain@example.com'),
 (SELECT product_id FROM products  WHERE name='Mechanical Keyboard'),
 1, NOW() - INTERVAL '7 days'),

-- Ahmed Khan
((SELECT customer_id FROM customers WHERE email='ahmed.khan@example.com'),
 (SELECT product_id FROM products  WHERE name='American Eagle Jeans'),
 1, NOW() - INTERVAL '6 days'),

((SELECT customer_id FROM customers WHERE email='ahmed.khan@example.com'),
 (SELECT product_id FROM products  WHERE name='Nurpur Milk 1-litre'),
 2, NOW() - INTERVAL '5 days'),

-- Ahsan Khan
((SELECT customer_id FROM customers WHERE email='ahsan.khan@example.com'),
 (SELECT product_id FROM products  WHERE name='Mechanical Keyboard'),
 1, NOW() - INTERVAL '4 days'),

((SELECT customer_id FROM customers WHERE email='ahsan.khan@example.com'),
 (SELECT product_id FROM products  WHERE name='Wireless Mouse'),
 1, NOW() - INTERVAL '3 days'),

-- Mariam Syed
((SELECT customer_id FROM customers WHERE email='mariam.syed@example.com'),
 (SELECT product_id FROM products  WHERE name='Nurpur Milk 1-litre'),
 5, NOW() - INTERVAL '2 days'),

((SELECT customer_id FROM customers WHERE email='mariam.syed@example.com'),
 (SELECT product_id FROM products  WHERE name='American Eagle Jeans'),
 1, NOW() - INTERVAL '1 day');


SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;

---------- Queries (Analytics)

--1: Customers who ordered > 2 different products 
-- counting distinct product_ids per customer filter with HAVING.
SELECT c.customer_id, c.name, COUNT(DISTINCT o.product_id) AS distinct_products
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT o.product_id) > 2;

--2: Top 3 most ordered products by total quantity
-- aggregating quantity per product, join for names, sort, limit 3
SELECT p.product_id, p.name, x.total_qty
FROM (
  SELECT product_id, SUM(quantity) AS total_qty
  FROM orders
  GROUP BY product_id
) x
JOIN products p ON p.product_id = x.product_id
ORDER BY x.total_qty DESC
LIMIT 3;

--3: Each customer’s total spending
-- join orders n products for price, sum per customer, then attaching name
SELECT c.customer_id, c.name, x.total_spend
FROM (
  SELECT o.customer_id, SUM(p.price * o.quantity) AS total_spend
  FROM orders o
  JOIN products p ON p.product_id = o.product_id
  GROUP BY o.customer_id
) x
JOIN customers c ON c.customer_id = x.customer_id
ORDER BY x.total_spend DESC;

--4: Customers with no orders 
SELECT c.customer_id, c.name, c.email
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL;

--5: Products never ordered
-- LEFT JOIN orders, keep rows where no match (o.product_id IS NULL)
SELECT p.product_id, p.name, p.category, p.price
FROM products p
LEFT JOIN orders o ON o.product_id = p.product_id
WHERE o.product_id IS NULL;

--6: Latest order date per customer (including customers with no orders)
-- aggregating MAX(order_date) in a subquery, LEFT JOIN back to customers
SELECT c.customer_id, c.name, t.latest_order_date
FROM customers c LEFT JOIN (SELECT customer_id, MAX(order_date) AS latest_order_date
  							FROM orders
  							GROUP BY customer_id) t 
ON t.customer_id = c.customer_id
ORDER BY t.latest_order_date DESC NULLS LAST, c.customer_id;

--7: View of total spend per customer (0 for no orders)
CREATE VIEW customer_spend_summary AS
SELECT c.customer_id, c.name, COALESCE(SUM(p.price * o.quantity), 0) AS total_spend
FROM customers c
LEFT JOIN orders   o ON o.customer_id  = c.customer_id
LEFT JOIN products p ON p.product_id   = o.product_id
GROUP BY c.customer_id, c.name;

-- to view the result of saved query(view)
SELECT * 
FROM customer_spend_summary
ORDER BY total_spend DESC;

--8
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
--Index on orders.customer_id to speed up joins/filters 
--By creating index on customer_id, it lets postgres jump straight to matching rows instead of scanning the whole orders table, 
--speeding up joins, filters, and cascades. 

--9: Top 2 customers by spend in each product category 
-- compute spend per (customer, category). rank within category and keeping top 2.
WITH spend_per_cat AS (
  SELECT
    p.category, c.customer_id, c.name, SUM(p.price * o.quantity) AS spend
  FROM orders o JOIN products p 
  ON p.product_id = o.product_id
  JOIN customers c ON c.customer_id = o.customer_id
  GROUP BY p.category, c.customer_id, c.name
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY category ORDER BY spend DESC) AS rn
  FROM spend_per_cat
)
SELECT category, customer_id, name, spend
FROM ranked
WHERE rn <= 2
ORDER BY category, spend DESC;

--10: Monthly sales trend (total revenue per month)
-- using CTE, DATE_TRUNC to month, sum revenue, order chronologically
WITH monthly AS (
  SELECT DATE_TRUNC('month', o.order_date) AS month_start, SUM(p.price * o.quantity) AS revenue
  FROM orders o JOIN products p ON p.product_id = o.product_id
  GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT month_start, revenue
FROM monthly
ORDER BY month_start;

--11: Rank each customer’s orders by recency
-- ROW_NUMBER() partitioned by customer, ordered by order_date desc
SELECT o.customer_id, c.name, o.order_id, o.order_date,
	ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC, o.order_id DESC) AS recency_rank
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.customer_id, recency_rank;

--12: Cumulative spending over time per customer
-- SUM(price*quantity) as a window function ordered by time
SELECT o.customer_id, c.name, o.order_id, o.order_date, (p.price * o.quantity) AS order_value,
  SUM(p.price * o.quantity) OVER (PARTITION BY o.customer_id ORDER BY o.order_date, o.order_id
  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_spend
FROM orders o
JOIN products p ON p.product_id = o.product_id
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.customer_id, o.order_date, o.order_id;

--13: Product with highest revenue in its category (ties allowed via RANK)
-- computing revenue per product, rank within category by revenue desc, pick rnk = 1.
WITH product_rev AS (
  SELECT p.category, p.product_id, p.name, COALESCE(SUM(o.quantity * p.price), 0) AS revenue
  FROM products p LEFT JOIN orders o 
  ON o.product_id = p.product_id
  GROUP BY p.category, p.product_id, p.name
),
ranked AS (
  SELECT *, RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
  FROM product_rev
)
SELECT category, product_id, name, revenue
FROM ranked
WHERE rnk = 1
ORDER BY category, revenue DESC;