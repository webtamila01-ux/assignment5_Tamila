
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

#
Explanation:
UNION ALL combines customers, suppliers, and employees
from the UK without removing duplicate rows.



-- Task 2a

SELECT country
FROM customers
WHERE country IS NOT NULL
INTERSECT
SELECT country
FROM suppliers
WHERE country IS NOT NULL
ORDER BY country;

#
Explanation:
INTERSECT returns countries that appear in both tables.



-- Task 2b

SELECT country
FROM customers
WHERE country IS NOT NULL
EXCEPT
SELECT country
FROM suppliers
WHERE country IS NOT NULL
ORDER BY country;

#
Explanation:
EXCEPT returns countries with customers but no suppliers.



-- Task 2c

SELECT city
FROM customers
WHERE city IS NOT NULL
UNION
SELECT city
FROM suppliers
WHERE city IS NOT NULL
ORDER BY city;

#
Explanation:
UNION combines cities and removes duplicates.


-- Task 2d

SELECT city
FROM customers
WHERE city IS NOT NULL
UNION ALL
SELECT city
FROM suppliers
WHERE city IS NOT NULL
ORDER BY city;

#
Explanation:
UNION ALL combines cities and preserves duplicates.



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

#
Explanation:
EXCEPT identifies customers who ordered in 1997
but did not order in 1998.



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

#Explanation:
ROLLUP calculates quarterly totals, yearly subtotals,
and the grand total.


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
# Explanation:
CUBE calculates revenue by category and year, including
subtotals. GROUPING identifies subtotal rows.



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

#Explanation:
GROUPING SETS calculates product counts and average prices
by category, supplier country, and overall.
