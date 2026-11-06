-- Task 1

SELECT
    'Customer' AS contact_type,
    company_name AS organization,
    contact_name AS person,
    city
FROM customers
WHERE country = 'UK'

UNION ALL

SELECT
    'Supplier',
    company_name,
    contact_name,
    city
FROM suppliers
WHERE country = 'UK'

UNION ALL

SELECT
    'Employee',
    'Northwind Traders',
    first_name || ' ' || last_name,
    city
FROM employees
WHERE country = 'UK'
ORDER BY contact_type, city, person;

/*
Explanation:
UNION ALL combines customers, suppliers, and employees
from the UK without removing duplicate rows.
*/


-- Task 2a

SELECT country
FROM customers
WHERE country IS NOT NULL
INTERSECT
SELECT country
FROM suppliers
WHERE country IS NOT NULL
ORDER BY country;

/*
Explanation:
INTERSECT returns countries that appear in both tables.
*/


-- Task 2b

SELECT country
FROM customers
WHERE country IS NOT NULL
EXCEPT
SELECT country
FROM suppliers
WHERE country IS NOT NULL
ORDER BY country;

/*
Explanation:
EXCEPT returns countries with customers but no suppliers.
*/


-- Task 2c

SELECT city
FROM customers
WHERE city IS NOT NULL
UNION
SELECT city
FROM suppliers
WHERE city IS NOT NULL
ORDER BY city;

/*
Explanation:
UNION combines cities and removes duplicates.
*/


-- Task 2d

SELECT city
FROM customers
WHERE city IS NOT NULL
UNION ALL
SELECT city
FROM suppliers
WHERE city IS NOT NULL
ORDER BY city;

/*
Explanation:
UNION ALL combines cities and preserves duplicates.
*/


-- Task 3

SELECT
    c.customer_id,
    c.company_name,
    c.country,
    c.phone
FROM customers c
WHERE c.customer_id IN (
    SELECT customer_id
    FROM orders
    WHERE order_date >= DATE '1997-01-01'
      AND order_date < DATE '1998-01-01'

    EXCEPT

    SELECT customer_id
    FROM orders
    WHERE order_date >= DATE '1998-01-01'
      AND order_date < DATE '1999-01-01'
)
ORDER BY c.company_name;

/*
Explanation:
EXCEPT identifies customers who ordered in 1997
but did not order in 1998.
*/


-- Task 4

SELECT
    EXTRACT(YEAR FROM order_date)::integer AS order_year,
    EXTRACT(QUARTER FROM order_date)::integer AS order_quarter,
    COUNT(*) AS orders_cnt,
    ROUND(SUM(freight)::numeric, 2) AS total_freight
FROM orders
GROUP BY ROLLUP (
    EXTRACT(YEAR FROM order_date),
    EXTRACT(QUARTER FROM order_date)
)
ORDER BY
    GROUPING(EXTRACT(YEAR FROM order_date)),
    EXTRACT(YEAR FROM order_date) NULLS LAST,
    GROUPING(EXTRACT(QUARTER FROM order_date)),
    EXTRACT(QUARTER FROM order_date) NULLS LAST;

/*
Explanation:
ROLLUP calculates quarterly totals, yearly subtotals,
and the grand total.
*/


-- Task 5

SELECT
    CASE
        WHEN GROUPING(c.category_name) = 1
            THEN 'All categories'
        ELSE c.category_name
    END AS category,
    CASE
        WHEN GROUPING(EXTRACT(YEAR FROM o.order_date)) = 1
            THEN 'All years'
        ELSE EXTRACT(YEAR FROM o.order_date)::integer::text
    END AS order_year,
    ROUND(
        SUM(
            od.unit_price * od.quantity * (1 - od.discount)
        )::numeric,
        2
    ) AS revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
JOIN products p
    ON od.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id
GROUP BY CUBE (
    c.category_name,
    EXTRACT(YEAR FROM o.order_date)
)
ORDER BY
    GROUPING(c.category_name),
    c.category_name,
    GROUPING(EXTRACT(YEAR FROM o.order_date)),
    EXTRACT(YEAR FROM o.order_date);

/*
Explanation:
CUBE calculates revenue by category and year, including
subtotals. GROUPING identifies subtotal rows.
*/


-- Task 6

SELECT
    c.category_name,
    s.country AS supplier_country,
    COUNT(p.product_id) AS products_cnt,
    ROUND(AVG(p.unit_price)::numeric, 2) AS avg_price
FROM products p
JOIN categories c
    ON p.category_id = c.category_id
JOIN suppliers s
    ON p.supplier_id = s.supplier_id
GROUP BY GROUPING SETS (
    (c.category_name),
    (s.country),
    ()
)
ORDER BY
    GROUPING(c.category_name),
    c.category_name NULLS LAST,
    s.country NULLS LAST;

/*
Explanation:
GROUPING SETS calculates product counts and average prices
by category, supplier country, and overall.
*/


-- Task 7a

CREATE VIEW v_order_totals AS
SELECT
    o.order_id,
    o.customer_id,
    o.employee_id,
    o.order_date,
    ROUND(
        COALESCE(
            SUM(
                od.unit_price * od.quantity * (1 - od.discount)
            ),
            0
        )::numeric,
        2
    ) AS order_total
FROM orders o
LEFT JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY
    o.order_id,
    o.customer_id,
    o.employee_id,
    o.order_date;


-- Task 7b

SELECT
    c.company_name,
    COUNT(v.order_id) AS orders_1997,
    ROUND(SUM(v.order_total)::numeric, 2) AS revenue_1997
FROM customers c
JOIN v_order_totals v
    ON c.customer_id = v.customer_id
WHERE v.order_date >= DATE '1997-01-01'
  AND v.order_date < DATE '1998-01-01'
GROUP BY
    c.customer_id,
    c.company_name
ORDER BY revenue_1997 DESC
LIMIT 5;

/*
Q:
A regular view does not store a separate copy of the data.
It stores the query definition and executes the query when
the view is accessed.

When a new order is added, the result of the view changes
automatically because the view reads the current data from
the underlying tables.
*/


-- Task 8a

CREATE VIEW v_uk_customers AS
SELECT
    customer_id,
    company_name,
    contact_name,
    city,
    country,
    phone
FROM customers
WHERE country = 'UK'
WITH CHECK OPTION;


-- Task 8b

UPDATE v_uk_customers
SET phone = '(171) 555-0000'
WHERE customer_id = 'AROUT';

SELECT
    customer_id,
    company_name,
    phone
FROM customers
WHERE customer_id = 'AROUT';


-- Task 8c

INSERT INTO v_uk_customers (
    customer_id,
    company_name,
    city,
    country
)
VALUES (
    'AITU1',
    'AITU Test Ltd',
    'London',
    'UK'
);


-- expected error

INSERT INTO v_uk_customers (
    customer_id,
    company_name,
    city,
    country
)
VALUES (
    'AITU2',
    'AITU Paris',
    'Paris',
    'France'
);


-- Task 8d

-- expected error

UPDATE v_uk_customers
SET country = 'Kazakhstan'
WHERE customer_id = 'AITU1';


/*
Q:
The INSERT of AITU2 produces an error because the new row does
not satisfy the condition of the view: country must be 'UK'.

WITH CHECK OPTION protects the view from inserting or updating
rows that would not satisfy the view's WHERE condition.

PostgreSQL can automatically update v_uk_customers because it is
a simple view based on one table without grouping or aggregation.

v_order_totals cannot be automatically updated because it contains
a join and an aggregate function.
*/


-- Task 9a

CREATE MATERIALIZED VIEW mv_category_sales AS
SELECT
    c.category_name,
    COUNT(DISTINCT o.order_id) AS orders_cnt,
    SUM(od.quantity) AS units_sold,
    ROUND(
        SUM(
            od.unit_price * od.quantity * (1 - od.discount)
        )::numeric,
        2
    ) AS revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
JOIN products p
    ON od.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name;


SELECT
    category_name,
    orders_cnt,
    units_sold,
    revenue
FROM mv_category_sales
ORDER BY revenue DESC;


-- Task 9b

BEGIN;

INSERT INTO order_details (
    order_id,
    product_id,
    unit_price,
    quantity,
    discount
)
VALUES (
    10248,
    1,
    18,
    100,
    0
);

SELECT
    units_sold
FROM mv_category_sales
WHERE category_name = 'Beverages';

REFRESH MATERIALIZED VIEW mv_category_sales;

SELECT
    units_sold
FROM mv_category_sales
WHERE category_name = 'Beverages';

ROLLBACK;


/*
Q:
Before REFRESH, the materialized view shows the old units_sold
value because a materialized view stores a snapshot of the query
result.

After REFRESH, the materialized view is rebuilt from the current
table data, so the inserted 100 units are included.

A materialized view is useful when a query is expensive and the
result does not need to be completely up to date after every
change.

The price is that the stored result can become stale and must
be refreshed.
*/


-- Create large table for Task 10 and Task 11

CREATE TABLE orders_big AS
SELECT
    g.n * 100000 + o.order_id AS order_id,
    o.customer_id,
    o.employee_id,
    o.order_date + (g.n % 365) AS order_date,
    o.ship_country,
    o.ship_city,
    o.freight
FROM orders o
CROSS JOIN generate_series(1, 1000) AS g(n);

ANALYZE orders_big;


-- Task 10a

EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE customer_id = 'ALFKI';


-- Task 10b

CREATE INDEX idx_orders_big_customer
ON orders_big (customer_id);

EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE customer_id = 'ALFKI';


-- Task 10c

EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE customer_id >= 'B';

SELECT
    COUNT(*) AS matching_rows,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM orders_big),
        2
    ) AS percentage
FROM orders_big
WHERE customer_id >= 'B';


/*
Q:
In Task 10a the query normally uses a sequential scan because
there is no index on customer_id.

After creating idx_orders_big_customer, PostgreSQL can use an
index-based plan for the highly selective condition
customer_id = 'ALFKI'.

In Task 10c, the condition customer_id >= 'B' returns a large
part of the table. Therefore, a sequential scan can be cheaper
than using the index.

Selectivity describes how much of the table is selected by a
condition. A highly selective condition returns relatively few
rows, while a low-selectivity condition returns many rows.
*/


-- Task 11a

EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE ship_country = 'Germany'
  AND order_date BETWEEN DATE '1997-01-01'
                     AND DATE '1997-01-31';


CREATE INDEX idx_orders_big_country_date
ON orders_big (ship_country, order_date);


EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE ship_country = 'Germany'
  AND order_date BETWEEN DATE '1997-01-01'
                     AND DATE '1997-01-31';


EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE order_date BETWEEN DATE '1997-01-01'
                     AND DATE '1997-01-31';


-- Task 11b

EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE freight > 500;


CREATE INDEX idx_orders_big_heavy
ON orders_big (freight)
WHERE freight > 500;


EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE freight > 500;


-- Task 11c

EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE LOWER(ship_city) = 'london';


CREATE INDEX idx_orders_big_city_lower
ON orders_big (LOWER(ship_city));


EXPLAIN ANALYZE
SELECT *
FROM orders_big
WHERE LOWER(ship_city) = 'london';


-- Task 11d

SELECT
    indexname,
    pg_size_pretty(
        pg_relation_size(indexname::regclass)
    ) AS index_size
FROM pg_indexes
WHERE tablename = 'orders_big';

SELECT
    pg_size_pretty(
        pg_relation_size('orders_big')
    ) AS table_size;


/*
Q:

1. The composite index is created on (ship_country, order_date).
It can efficiently use the first column ship_country and then
order_date. A query filtering only by order_date cannot efficiently
use the index because it does not restrict the leading column.

2. The partial index is much smaller because it contains only rows
where freight > 500 rather than all rows of orders_big.

3. An ordinary index on ship_city would not directly help much
with LOWER(ship_city) = 'london' because the query applies the
LOWER() function. The expression index on LOWER(ship_city) matches
the expression used in the query.

4. Two costs of having many indexes are additional disk space and
slower INSERT, UPDATE and DELETE operations because the indexes
must also be maintained.
*/


-- Task 12a

SELECT
    product_id,
    units_in_stock
FROM products
WHERE product_id IN (11, 42)
ORDER BY product_id;


-- Task 12b

BEGIN;

INSERT INTO orders (
    order_id,
    customer_id,
    employee_id,
    order_date,
    required_date,
    ship_via,
    freight,
    ship_country
)
VALUES (
    11078,
    'ALFKI',
    1,
    DATE '1998-05-07',
    DATE '1998-06-04',
    1,
    25.00,
    'Germany'
);

INSERT INTO order_details (
    order_id,
    product_id,
    unit_price,
    quantity,
    discount
)
VALUES (
    11078,
    11,
    21.00,
    5,
    0
);

UPDATE products
SET units_in_stock = units_in_stock - 5
WHERE product_id = 11;


-- expected error

INSERT INTO order_details (
    order_id,
    product_id,
    unit_price,
    quantity,
    discount
)
VALUES (
    11078,
    999,
    10.00,
    1,
    0
);


UPDATE products
SET units_in_stock = units_in_stock - 1
WHERE product_id = 42;

COMMIT;


SELECT
    order_id
FROM orders
WHERE order_id = 11078;

SELECT
    product_id,
    units_in_stock
FROM products
WHERE product_id = 11;


/*
Q:
After the error caused by product_id = 999, PostgreSQL marks the
whole transaction as aborted.

The following UPDATE and COMMIT cannot successfully continue the
transaction. The changes made before the error are rolled back.

Therefore order 11078 does not remain in the database and the
stock of product 11 returns to its original value.

This demonstrates atomicity: the transaction is treated as one
unit, so either all required changes succeed or none of them are
committed.
*/


-- Task 12c

BEGIN;

INSERT INTO orders (
    order_id,
    customer_id,
    employee_id,
    order_date,
    required_date,
    ship_via,
    freight,
    ship_country
)
VALUES (
    11078,
    'ALFKI',
    1,
    DATE '1998-05-07',
    DATE '1998-06-04',
    1,
    25.00,
    'Germany'
);

INSERT INTO order_details (
    order_id,
    product_id,
    unit_price,
    quantity,
    discount
)
VALUES (
    11078,
    11,
    21.00,
    5,
    0
);

UPDATE products
SET units_in_stock = units_in_stock - 5
WHERE product_id = 11;


SAVEPOINT before_second_item;


-- expected error

INSERT INTO order_details (
    order_id,
    product_id,
    unit_price,
    quantity,
    discount
)
VALUES (
    11078,
    999,
    10.00,
    1,
    0
);


ROLLBACK TO SAVEPOINT before_second_item;


INSERT INTO order_details (
    order_id,
    product_id,
    unit_price,
    quantity,
    discount
)
VALUES (
    11078,
    42,
    14.00,
    1,
    0
);

UPDATE products
SET units_in_stock = units_in_stock - 1
WHERE product_id = 42;

COMMIT;


SELECT
    order_id,
    product_id,
    unit_price,
    quantity,
    discount
FROM order_details
WHERE order_id = 11078
ORDER BY product_id;

SELECT
    product_id,
    units_in_stock
FROM products
WHERE product_id IN (11, 42)
ORDER BY product_id;


/*
Q:
In Task 12b, after the error PostgreSQL reported that the current
transaction was aborted, so subsequent commands could not be
executed normally. COMMIT did not commit the failed transaction.

The ACID property observed was Atomicity: the incomplete
transaction was not partially committed.

In Task 12c, SAVEPOINT allowed us to roll back only the failed
part of the transaction. The order and the first valid order line
remained, while the failed second item was removed. Then the
correct line for product 42 was inserted and the transaction was
committed.
*/


-- Task 13a

ALTER TABLE products
ADD CONSTRAINT chk_units_in_stock
CHECK (units_in_stock >= 0);


BEGIN;

-- expected error

UPDATE products
SET units_in_stock = units_in_stock - 100
WHERE product_id = 42;

ROLLBACK;


/*
Q:
The UPDATE produces a CHECK constraint violation because the
resulting units_in_stock value would be less than 0.

This demonstrates consistency because the database rejects a
change that would violate the defined integrity rule.
*/


-- Task 13b

-- Session A
-- Step 1

BEGIN;

SELECT units_in_stock
FROM products
WHERE product_id = 1;


-- Step 3

SELECT units_in_stock
FROM products
WHERE product_id = 1;

COMMIT;


-- Step 4

BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT units_in_stock
FROM products
WHERE product_id = 1;


-- Step 6

SELECT units_in_stock
FROM products
WHERE product_id = 1;


-- Step 7

UPDATE products
SET units_in_stock = units_in_stock - 1
WHERE product_id = 1;

ROLLBACK;


-- Session B
-- Step 2

UPDATE products
SET units_in_stock = units_in_stock - 10
WHERE product_id = 1;


-- Step 5

UPDATE products
SET units_in_stock = units_in_stock + 10
WHERE product_id = 1;


/*
Q:

1. Task 13a produced a CHECK constraint violation because the
UPDATE would make units_in_stock negative. This demonstrates
consistency because the database prevents invalid data from being
stored.

2. Under READ COMMITTED, each SELECT sees data committed before
that particular SELECT starts.

Under REPEATABLE READ, the transaction uses a consistent snapshot.
Therefore the SELECT in step 6 sees the same snapshot as the
SELECT in step 4 and does not see the later committed change from
Session B.

3. In step 7, the UPDATE is performed and then ROLLBACK is issued.
Therefore the change made by Session A is not committed and the
stock returns to its previous value.

4. Durability is provided by PostgreSQL's write-ahead log (WAL).
Changes are written to the WAL before the corresponding data pages
are considered safely committed, allowing committed data to survive
a server crash.
*/


-- Clean-up

DELETE FROM order_details
WHERE order_id = 11078;

DELETE FROM orders
WHERE order_id = 11078;

UPDATE products
SET units_in_stock = units_in_stock + 5
WHERE product_id = 11;

UPDATE products
SET units_in_stock = units_in_stock + 1
WHERE product_id = 42;

DELETE FROM customers
WHERE customer_id = 'AITU1';

ALTER TABLE products
DROP CONSTRAINT IF EXISTS chk_units_in_stock;

DROP MATERIALIZED VIEW IF EXISTS mv_category_sales;

DROP VIEW IF EXISTS v_uk_customers, v_order_totals;

DROP TABLE IF EXISTS orders_big;

UPDATE customers
SET phone = '(171) 555-7788'
WHERE customer_id = 'AROUT';
