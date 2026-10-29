-- ============================================================
-- e-commerce sales & customer analytics
-- 10 - Cohort Analysis
-- Database: MySQL 8.0+
-- Purpose: cohort assignment, activity, retention, and revenue.
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- 1. Assign each customer to their first-purchase cohort month.
WITH First_Purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL
      AND order_date IS NOT NULL
    GROUP BY customer_id
)
SELECT
    customer_id,
    First_Purchase_Date,
    DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
FROM First_Purchase
ORDER BY Cohort_Month, customer_id;

-- 2. Customer activity by cohort month and activity month.
WITH First_Purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL
      AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT
        customer_id,
        First_Purchase_Date,
        DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Customer_Activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS Activity_Month
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL
      AND order_date IS NOT NULL
)
SELECT
    c.customer_id,
    c.Cohort_Month,
    a.Activity_Month
FROM Customer_Cohort AS c
JOIN Customer_Activity AS a
    ON c.customer_id = a.customer_id
ORDER BY c.Cohort_Month, c.customer_id, a.Activity_Month;

-- 3. Active customers for each cohort/activity-month combination.
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT customer_id, DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Customer_Activity AS (
    SELECT DISTINCT customer_id, DATE_FORMAT(order_date, '%Y-%m') AS Activity_Month
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
)
SELECT
    c.Cohort_Month,
    a.Activity_Month,
    COUNT(DISTINCT c.customer_id) AS Active_Customers
FROM Customer_Cohort AS c
JOIN Customer_Activity AS a
    ON c.customer_id = a.customer_id
GROUP BY c.Cohort_Month, a.Activity_Month
ORDER BY c.Cohort_Month, a.Activity_Month;

-- 4. Cohort retention percentage by activity month.
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT
        customer_id,
        DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Customer_Activity AS (
    SELECT DISTINCT customer_id, DATE_FORMAT(order_date, '%Y-%m') AS Activity_Month
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
),
Cohort_Size AS (
    SELECT Cohort_Month, COUNT(*) AS Cohort_Size
    FROM Customer_Cohort
    GROUP BY Cohort_Month
),
Active_Customers AS (
    SELECT
        c.Cohort_Month,
        a.Activity_Month,
        COUNT(DISTINCT c.customer_id) AS Active_Customers
    FROM Customer_Cohort AS c
    JOIN Customer_Activity AS a
        ON c.customer_id = a.customer_id
    GROUP BY c.Cohort_Month, a.Activity_Month
)
SELECT
    a.Cohort_Month,
    a.Activity_Month,
    a.Active_Customers,
    cs.Cohort_Size,
    ROUND(a.Active_Customers / NULLIF(cs.Cohort_Size, 0) * 100, 2) AS Retention_Pct
FROM Active_Customers AS a
JOIN Cohort_Size AS cs
    ON a.Cohort_Month = cs.Cohort_Month
ORDER BY a.Cohort_Month, a.Activity_Month;

-- 5. Retention activity indexed by Month_Number.
-- Month 0 is the first-purchase cohort month.
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT
        customer_id,
        First_Purchase_Date,
        DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Customer_Activity AS (
    SELECT DISTINCT
        customer_id,
        STR_TO_DATE(DATE_FORMAT(order_date, '%Y-%m-01'), '%Y-%m-%d') AS Activity_Month_Start,
        DATE_FORMAT(order_date, '%Y-%m') AS Activity_Month
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
),
Cohort_Activity AS (
    SELECT
        c.customer_id,
        c.Cohort_Month,
        a.Activity_Month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c.Cohort_Month, '-01'), '%Y-%m-%d'),
            a.Activity_Month_Start
        ) AS Month_Number
    FROM Customer_Cohort AS c
    JOIN Customer_Activity AS a
        ON c.customer_id = a.customer_id
)
SELECT
    Cohort_Month,
    Activity_Month,
    Month_Number,
    COUNT(DISTINCT customer_id) AS Active_Customers
FROM Cohort_Activity
WHERE Month_Number >= 0
GROUP BY Cohort_Month, Activity_Month, Month_Number
ORDER BY Cohort_Month, Month_Number;

-- 6. Cohort retention matrix in long format, Month 0 to Month 12.
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT
        customer_id,
        DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Customer_Activity AS (
    SELECT DISTINCT
        customer_id,
        STR_TO_DATE(DATE_FORMAT(order_date, '%Y-%m-01'), '%Y-%m-%d') AS Activity_Month_Start
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
),
Cohort_Size AS (
    SELECT Cohort_Month, COUNT(*) AS Cohort_Size
    FROM Customer_Cohort
    GROUP BY Cohort_Month
),
Cohort_Activity AS (
    SELECT
        c.customer_id,
        c.Cohort_Month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c.Cohort_Month, '-01'), '%Y-%m-%d'),
            a.Activity_Month_Start
        ) AS Month_Number
    FROM Customer_Cohort AS c
    JOIN Customer_Activity AS a
        ON c.customer_id = a.customer_id
),
Retention AS (
    SELECT
        Cohort_Month,
        Month_Number,
        COUNT(DISTINCT customer_id) AS Active_Customers
    FROM Cohort_Activity
    WHERE Month_Number BETWEEN 0 AND 12
    GROUP BY Cohort_Month, Month_Number
)
SELECT
    r.Cohort_Month,
    r.Month_Number,
    r.Active_Customers,
    cs.Cohort_Size,
    ROUND(r.Active_Customers / NULLIF(cs.Cohort_Size, 0) * 100, 2) AS Retention_Pct
FROM Retention AS r
JOIN Cohort_Size AS cs
    ON r.Cohort_Month = cs.Cohort_Month
ORDER BY r.Cohort_Month, r.Month_Number;

-- 7. Average retention by cohort across observed months 1 to 12.
-- Recent cohorts may have fewer observable months; compare cautiously.
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT customer_id, DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Customer_Activity AS (
    SELECT DISTINCT
        customer_id,
        STR_TO_DATE(DATE_FORMAT(order_date, '%Y-%m-01'), '%Y-%m-%d') AS Activity_Month_Start
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
),
Cohort_Size AS (
    SELECT Cohort_Month, COUNT(*) AS Cohort_Size
    FROM Customer_Cohort
    GROUP BY Cohort_Month
),
Retention_By_Month AS (
    SELECT
        c.Cohort_Month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c.Cohort_Month, '-01'), '%Y-%m-%d'),
            a.Activity_Month_Start
        ) AS Month_Number,
        COUNT(DISTINCT c.customer_id) / NULLIF(cs.Cohort_Size, 0) * 100 AS Retention_Pct
    FROM Customer_Cohort AS c
    JOIN Customer_Activity AS a
        ON c.customer_id = a.customer_id
    JOIN Cohort_Size AS cs
        ON c.Cohort_Month = cs.Cohort_Month
    GROUP BY c.Cohort_Month, Month_Number, cs.Cohort_Size
)
SELECT
    Cohort_Month,
    ROUND(AVG(Retention_Pct), 2) AS Avg_Retention_Pct,
    COUNT(*) AS Observed_Retention_Months
FROM Retention_By_Month
WHERE Month_Number BETWEEN 1 AND 12
GROUP BY Cohort_Month
ORDER BY Avg_Retention_Pct DESC;

-- 8. Month 1, Month 3, Month 6, and Month 12 retention by cohort.
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT
        customer_id,
        DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Customer_Activity AS (
    SELECT DISTINCT
        customer_id,
        STR_TO_DATE(DATE_FORMAT(order_date, '%Y-%m-01'), '%Y-%m-%d') AS Activity_Month_Start
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
),
Cohort_Size AS (
    SELECT Cohort_Month, COUNT(*) AS Cohort_Size
    FROM Customer_Cohort
    GROUP BY Cohort_Month
),
Cohort_Activity AS (
    SELECT
        c.customer_id,
        c.Cohort_Month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c.Cohort_Month, '-01'), '%Y-%m-%d'),
            a.Activity_Month_Start
        ) AS Month_Number
    FROM Customer_Cohort AS c
    JOIN Customer_Activity AS a
        ON c.customer_id = a.customer_id
),
Retention AS (
    SELECT
        Cohort_Month,
        Month_Number,
        COUNT(DISTINCT customer_id) AS Active_Customers
    FROM Cohort_Activity
    WHERE Month_Number IN (1, 3, 6, 12)
    GROUP BY Cohort_Month, Month_Number
)
SELECT
    cs.Cohort_Month,
    MAX(cs.Cohort_Size) AS Cohort_Size,
    MAX(CASE WHEN r.Month_Number = 1 THEN ROUND(r.Active_Customers / NULLIF(cs.Cohort_Size, 0) * 100, 2) END) AS M1_Retention_Pct,
    MAX(CASE WHEN r.Month_Number = 3 THEN ROUND(r.Active_Customers / NULLIF(cs.Cohort_Size, 0) * 100, 2) END) AS M3_Retention_Pct,
    MAX(CASE WHEN r.Month_Number = 6 THEN ROUND(r.Active_Customers / NULLIF(cs.Cohort_Size, 0) * 100, 2) END) AS M6_Retention_Pct,
    MAX(CASE WHEN r.Month_Number = 12 THEN ROUND(r.Active_Customers / NULLIF(cs.Cohort_Size, 0) * 100, 2) END) AS M12_Retention_Pct
FROM Cohort_Size AS cs
LEFT JOIN Retention AS r
    ON cs.Cohort_Month = r.Cohort_Month
GROUP BY cs.Cohort_Month
ORDER BY cs.Cohort_Month;

-- 9. Cohort revenue by activity month.
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT customer_id, DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Monthly_Customer_Sales AS (
    SELECT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS Activity_Month,
        SUM(sales) AS Monthly_Sales
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id, DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    c.Cohort_Month,
    m.Activity_Month,
    ROUND(SUM(m.Monthly_Sales), 2) AS Cohort_Revenue
FROM Customer_Cohort AS c
JOIN Monthly_Customer_Sales AS m
    ON c.customer_id = m.customer_id
GROUP BY c.Cohort_Month, m.Activity_Month
ORDER BY c.Cohort_Month, m.Activity_Month;

-- 10. Total cohort revenue and revenue per customer over all observed data.
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT customer_id, DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Customer_Sales AS (
    SELECT customer_id, SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    c.Cohort_Month,
    COUNT(*) AS Customers,
    ROUND(SUM(s.Total_Sales), 2) AS Total_Cohort_Revenue,
    ROUND(AVG(s.Total_Sales), 2) AS Revenue_Per_Customer
FROM Customer_Cohort AS c
JOIN Customer_Sales AS s
    ON c.customer_id = s.customer_id
GROUP BY c.Cohort_Month
ORDER BY Revenue_Per_Customer DESC;

-- 11. Cumulative cohort revenue by relative month (Month 0 to Month 12).
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT
        customer_id,
        DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Monthly_Sales AS (
    SELECT
        customer_id,
        STR_TO_DATE(DATE_FORMAT(order_date, '%Y-%m-01'), '%Y-%m-%d') AS Activity_Month_Start,
        SUM(sales) AS Monthly_Sales
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id, STR_TO_DATE(DATE_FORMAT(order_date, '%Y-%m-01'), '%Y-%m-%d')
),
Cohort_Revenue AS (
    SELECT
        c.Cohort_Month,
        c.customer_id,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c.Cohort_Month, '-01'), '%Y-%m-%d'),
            m.Activity_Month_Start
        ) AS Month_Number,
        m.Monthly_Sales
    FROM Customer_Cohort AS c
    JOIN Monthly_Sales AS m
        ON c.customer_id = m.customer_id
),
Monthly_Cohort_Revenue AS (
    SELECT
        Cohort_Month,
        Month_Number,
        SUM(Monthly_Sales) AS Monthly_Revenue
    FROM Cohort_Revenue
    WHERE Month_Number BETWEEN 0 AND 12
    GROUP BY Cohort_Month, Month_Number
)
SELECT
    Cohort_Month,
    Month_Number,
    ROUND(Monthly_Revenue, 2) AS Monthly_Revenue,
    ROUND(
        SUM(Monthly_Revenue) OVER (
            PARTITION BY Cohort_Month
            ORDER BY Month_Number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Cumulative_Revenue
FROM Monthly_Cohort_Revenue
ORDER BY Cohort_Month, Month_Number;

-- 12. Compare cohorts by average observed Month 1-12 retention
-- and total revenue. Recent cohorts may have fewer observed months.
WITH First_Purchase AS (
    SELECT customer_id, MIN(order_date) AS First_Purchase_Date
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
    GROUP BY customer_id
),
Customer_Cohort AS (
    SELECT
        customer_id,
        DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Cohort_Month
    FROM First_Purchase
),
Cohort_Size AS (
    SELECT Cohort_Month, COUNT(*) AS Cohort_Size
    FROM Customer_Cohort
    GROUP BY Cohort_Month
),
Customer_Activity AS (
    SELECT DISTINCT
        customer_id,
        STR_TO_DATE(DATE_FORMAT(order_date, '%Y-%m-01'), '%Y-%m-%d') AS Activity_Month_Start
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL AND order_date IS NOT NULL
),
Cohort_Activity AS (
    SELECT
        c.Cohort_Month,
        c.customer_id,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(c.Cohort_Month, '-01'), '%Y-%m-%d'),
            a.Activity_Month_Start
        ) AS Month_Number
    FROM Customer_Cohort AS c
    JOIN Customer_Activity AS a
        ON c.customer_id = a.customer_id
),
Retention_By_Month AS (
    SELECT
        ca.Cohort_Month,
        ca.Month_Number,
        COUNT(DISTINCT ca.customer_id) / NULLIF(cs.Cohort_Size, 0) * 100 AS Retention_Pct
    FROM Cohort_Activity AS ca
    JOIN Cohort_Size AS cs
        ON ca.Cohort_Month = cs.Cohort_Month
    WHERE ca.Month_Number BETWEEN 1 AND 12
    GROUP BY ca.Cohort_Month, ca.Month_Number, cs.Cohort_Size
),
Retention_Summary AS (
    SELECT
        Cohort_Month,
        AVG(Retention_Pct) AS Avg_Retention_Pct,
        COUNT(*) AS Observed_Retention_Months
    FROM Retention_By_Month
    GROUP BY Cohort_Month
),
Cohort_Revenue AS (
    SELECT
        c.Cohort_Month,
        SUM(e.sales) AS Total_Revenue
    FROM Customer_Cohort AS c
    JOIN ecommerce_clean AS e
        ON c.customer_id = e.customer_id
    GROUP BY c.Cohort_Month
),
Cohort_Performance AS (
    SELECT
        cs.Cohort_Month,
        rs.Avg_Retention_Pct,
        COALESCE(rs.Observed_Retention_Months, 0) AS Observed_Retention_Months,
        cr.Total_Revenue
    FROM Cohort_Size AS cs
    LEFT JOIN Retention_Summary AS rs
        ON cs.Cohort_Month = rs.Cohort_Month
    LEFT JOIN Cohort_Revenue AS cr
        ON cs.Cohort_Month = cr.Cohort_Month
)
SELECT
    Cohort_Month,
    ROUND(Avg_Retention_Pct, 2) AS Avg_Retention_Pct,
    Observed_Retention_Months,
    ROUND(Total_Revenue, 2) AS Total_Revenue,
    RANK() OVER (ORDER BY Avg_Retention_Pct DESC) AS Retention_Rank,
    RANK() OVER (ORDER BY Total_Revenue DESC) AS Revenue_Rank
FROM Cohort_Performance
ORDER BY Retention_Rank, Revenue_Rank;
