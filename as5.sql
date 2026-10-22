
-- ============================================
-- Assignment 5. Window Functions
-- Database: Store_db
-- DBMS: PostgreSQL
-- ============================================


-- Task 1. Price position inside each category

SELECT
    c.category_name,
    p.product_name,
    p.unit_price,
    ROW_NUMBER() OVER (
        PARTITION BY p.category_id
        ORDER BY p.unit_price DESC, p.product_name ASC
    ) AS price_position
FROM products p
JOIN categories c
    ON p.category_id = c.category_id
ORDER BY c.category_name, price_position;


-- Task 2. RANK vs DENSE_RANK

SELECT
    product_name,
    unit_price,
    price_rank,
    price_dense_rank
FROM (
    SELECT
        product_name,
        unit_price,
        RANK() OVER (
            ORDER BY unit_price DESC
        ) AS price_rank,
        DENSE_RANK() OVER (
            ORDER BY unit_price DESC
        ) AS price_dense_rank
    FROM products
) AS ranked_products
WHERE price_dense_rank <= 15
ORDER BY price_rank, product_name;

-- Explanation:
-- The result contains more than 15 rows because products
-- with equal prices receive the same DENSE_RANK.
-- RANK skips numbers after ties, while DENSE_RANK does not.


-- Task 3. Top 3 best-selling products in each category

SELECT
    category_name,
    product_name,
    units_sold,
    position
FROM (
    SELECT
        c.category_name,
        p.product_name,
        SUM(od.quantity) AS units_sold,
        ROW_NUMBER() OVER (
            PARTITION BY p.category_id
            ORDER BY SUM(od.quantity) DESC, p.product_name ASC
        ) AS position
    FROM products p
    JOIN categories c
        ON p.category_id = c.category_id
    JOIN order_details od
        ON p.product_id = od.product_id
    GROUP BY
        p.category_id,
        c.category_name,
        p.product_id,
        p.product_name
) AS ranked_products
WHERE position <= 3
ORDER BY category_name, position;


-- Task 4. Each product compared with its category

SELECT
    p.product_name,
    c.category_name,
    p.unit_price,
    COUNT(*) OVER (
        PARTITION BY p.category_id
    ) AS products_in_category,
    ROUND(
        AVG(p.unit_price) OVER (
            PARTITION BY p.category_id
        )::numeric,
        2
    ) AS category_avg,
    ROUND(
        (
            p.unit_price
            - AVG(p.unit_price) OVER (
                PARTITION BY p.category_id
            )
        )::numeric,
        2
    ) AS diff_from_avg
FROM products p
JOIN categories c
    ON p.category_id = c.category_id
ORDER BY c.category_name, diff_from_avg DESC;


-- Task 5. Running total of revenue in 1997

SELECT
    TO_CHAR(
        DATE_TRUNC('month', o.order_date),
        'YYYY-MM'
    ) AS month,
    ROUND(
        SUM(
            od.unit_price * od.quantity * (1 - od.discount)
        )::numeric,
        2
    ) AS revenue,
    ROUND(
        SUM(
            SUM(
                od.unit_price * od.quantity * (1 - od.discount)
            )
        ) OVER (
            ORDER BY DATE_TRUNC('month', o.order_date)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )::numeric,
        2
    ) AS running_total
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
WHERE o.order_date >= DATE '1997-01-01'
  AND o.order_date < DATE '1998-01-01'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY DATE_TRUNC('month', o.order_date);


-- Task 6. Employees' share of 1997 revenue

SELECT
    e.first_name || ' ' || e.last_name AS employee,
    ROUND(
        SUM(
            od.unit_price * od.quantity * (1 - od.discount)
        )::numeric,
        2
    ) AS revenue_1997,
    ROUND(
        (
            SUM(
                od.unit_price * od.quantity * (1 - od.discount)
            )
            / SUM(
                SUM(
                    od.unit_price * od.quantity * (1 - od.discount)
                )
            ) OVER ()
            * 100
        )::numeric,
        1
    ) AS share_pct,
    RANK() OVER (
        ORDER BY SUM(
            od.unit_price * od.quantity * (1 - od.discount)
        ) DESC
    ) AS revenue_rank
FROM employees e
JOIN orders o
    ON e.employee_id = o.employee_id
JOIN order_details od
    ON o.order_id = od.order_id
WHERE o.order_date >= DATE '1997-01-01'
  AND o.order_date < DATE '1998-01-01'
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name
ORDER BY revenue_rank;


-- Task 7. Month-over-month change in orders in 1997

SELECT
    month,
    orders_cnt,
    prev_orders,
    orders_cnt - prev_orders AS change
FROM (
    SELECT
        DATE_TRUNC('month', order_date) AS month_date,
        TO_CHAR(
            DATE_TRUNC('month', order_date),
            'YYYY-MM'
        ) AS month,
        COUNT(*) AS orders_cnt,
        LAG(COUNT(*)) OVER (
            ORDER BY DATE_TRUNC('month', order_date)
        ) AS prev_orders
    FROM orders
    WHERE order_date >= DATE '1997-01-01'
      AND order_date < DATE '1998-01-01'
    GROUP BY DATE_TRUNC('month', order_date)
) AS monthly_orders
ORDER BY month_date;


-- Task 8. Order history of Mexican customers

SELECT
    company_name,
    order_id,
    order_date,
    order_number,
    order_date - prev_order_date AS days_since_prev
FROM (
    SELECT
        c.company_name,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id
            ORDER BY o.order_date, o.order_id
        ) AS order_number,
        LAG(o.order_date) OVER (
            PARTITION BY c.customer_id
            ORDER BY o.order_date, o.order_id
        ) AS prev_order_date
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE c.country = 'Mexico'
) AS customer_orders
ORDER BY company_name, order_number;


-- Task 9. Three-month moving average

SELECT
    month,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY month_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::numeric,
        2
    ) AS moving_avg_3m
FROM (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_date,
        TO_CHAR(
            DATE_TRUNC('month', o.order_date),
            'YYYY-MM'
        ) AS month,
        ROUND(
            SUM(
                od.unit_price * od.quantity * (1 - od.discount)
            )::numeric,
            2
        ) AS revenue
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
) AS monthly_revenue
ORDER BY month_date;

-- Explanation:
-- The first month uses one available month.
-- The second month uses two available months.
-- Starting from the third month, the average uses
-- the current month and the two preceding months.


-- Task 10. Top customers by revenue

SELECT
    company_name,
    country,
    ROUND(revenue::numeric, 2) AS revenue,
    revenue_quartile,
    best_in_country,
    ROUND(
        (revenue / country_revenue * 100)::numeric,
        1
    ) AS pct_of_country
FROM (
    SELECT
        customer_id,
        company_name,
        country,
        revenue,
        NTILE(4) OVER (
            ORDER BY revenue DESC
        ) AS revenue_quartile,
        FIRST_VALUE(company_name) OVER (
            PARTITION BY country
            ORDER BY revenue DESC, company_name ASC
        ) AS best_in_country,
        SUM(revenue) OVER (
            PARTITION BY country
        ) AS country_revenue
    FROM (
        SELECT
            c.customer_id,
            c.company_name,
            c.country,
            SUM(
                od.unit_price * od.quantity * (1 - od.discount)
            ) AS revenue
        FROM customers c
        JOIN orders o
            ON c.customer_id = o.customer_id
        JOIN order_details od
            ON o.order_id = od.order_id
        GROUP BY
            c.customer_id,
            c.company_name,
            c.country
    ) AS customer_revenue
) AS ranked_customers
WHERE revenue_quartile = 1
ORDER BY revenue DESC;
