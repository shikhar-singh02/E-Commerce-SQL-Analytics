-- ============================================================
-- e-commerce sales & customer analytics
-- 06 - Customer Analysis
-- Purpose: analyze customer value, order behavior, contribution,
--          purchase history, recency, and frequency.
-- Database: MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- 1. Top 10 customers by sales
SELECT
    customer_id,
    customer_name,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    SUM(quantity) AS Total_Quantity,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY customer_id, customer_name
ORDER BY Total_Sales DESC
LIMIT 10;

-- 2. One-time vs repeat customers
-- Assumes each customer_id represents one customer and order_id identifies an order.
WITH Customer_Order_Count AS (
    SELECT
        customer_id,
        customer_name,
        COUNT(DISTINCT order_id) AS Total_Orders
    FROM ecommerce_clean
    WHERE customer_id IS NOT NULL
      AND TRIM(CAST(customer_id AS CHAR)) <> ''
    GROUP BY customer_id, customer_name
),
Customer_Type AS (
    SELECT
        customer_id,
        customer_name,
        Total_Orders,
        CASE
            WHEN Total_Orders = 1 THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS Customer_Type
    FROM Customer_Order_Count
)
SELECT
    Customer_Type,
    COUNT(*) AS Customer_Count
FROM Customer_Type
GROUP BY Customer_Type
ORDER BY Customer_Count DESC;

-- 3. Top 10 customers by total profit
SELECT
    customer_id,
    customer_name,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY customer_id, customer_name
ORDER BY Total_Profit DESC
LIMIT 10;

-- 4. Customers with high sales but low profit margin
-- The sales threshold (6000) and margin threshold (5%) are project-specific rules.
SELECT
    customer_id,
    customer_name,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY customer_id, customer_name
HAVING SUM(sales) >= 6000
   AND SUM(profit) / NULLIF(SUM(sales), 0) * 100 < 5
ORDER BY Total_Sales DESC;

-- 5. Top 3 customers by sales in each region
WITH Customer_Sales AS (
    SELECT
        customer_id,
        customer_name,
        region,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name, region
),
Ranked_Customers AS (
    SELECT
        customer_id,
        customer_name,
        region,
        Total_Sales,
        ROW_NUMBER() OVER (
            PARTITION BY region
            ORDER BY Total_Sales DESC, customer_id
        ) AS Sales_Rank
    FROM Customer_Sales
)
SELECT
    region,
    customer_id,
    customer_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Sales_Rank
FROM Ranked_Customers
WHERE Sales_Rank <= 3
ORDER BY region, Sales_Rank;

-- 6. Customer contribution to regional sales
WITH Customer_Sales AS (
    SELECT
        customer_id,
        customer_name,
        region,
        SUM(sales) AS Customer_Sales
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name, region
),
Regional_Sales AS (
    SELECT
        customer_id,
        customer_name,
        region,
        Customer_Sales,
        SUM(Customer_Sales) OVER (PARTITION BY region) AS Regional_Sales
    FROM Customer_Sales
)
SELECT
    region,
    customer_id,
    customer_name,
    ROUND(Customer_Sales, 2) AS Customer_Sales,
    ROUND(Regional_Sales, 2) AS Regional_Sales,
    ROUND(Customer_Sales / NULLIF(Regional_Sales, 0) * 100, 2) AS Sales_Contribution_Pct
FROM Regional_Sales
ORDER BY region, Sales_Contribution_Pct DESC;

-- 7. Highest-selling customer(s) in each month
-- DENSE_RANK preserves ties for first place.
WITH Monthly_Sales AS (
    SELECT
        YEAR(order_date) AS Sales_Year,
        MONTH(order_date) AS Sales_Month,
        customer_id,
        customer_name,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY
        YEAR(order_date),
        MONTH(order_date),
        customer_id,
        customer_name
),
Ranked_Customers AS (
    SELECT
        Sales_Year,
        Sales_Month,
        customer_id,
        customer_name,
        Total_Sales,
        DENSE_RANK() OVER (
            PARTITION BY Sales_Year, Sales_Month
            ORDER BY Total_Sales DESC
        ) AS Sales_Rank
    FROM Monthly_Sales
)
SELECT
    Sales_Year,
    Sales_Month,
    customer_id,
    customer_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Sales_Rank
FROM Ranked_Customers
WHERE Sales_Rank = 1
ORDER BY Sales_Year, Sales_Month, customer_id;

-- 8. Customers whose sales are above their region's average customer sales
WITH Customer_Sales AS (
    SELECT
        customer_id,
        customer_name,
        region,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name, region
),
Regional_Average AS (
    SELECT
        customer_id,
        customer_name,
        region,
        Total_Sales,
        AVG(Total_Sales) OVER (PARTITION BY region) AS Regional_Avg_Sales
    FROM Customer_Sales
)
SELECT
    region,
    customer_id,
    customer_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(Regional_Avg_Sales, 2) AS Regional_Avg_Sales,
    ROUND(Total_Sales - Regional_Avg_Sales, 2) AS Difference_From_Avg
FROM Regional_Average
WHERE Total_Sales > Regional_Avg_Sales
ORDER BY region, Difference_From_Avg DESC;

-- 9. Customers whose sales are above the overall average customer sales
WITH Customer_Sales AS (
    SELECT
        customer_id,
        customer_name,
        region,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name, region
),
Overall_Average AS (
    SELECT
        customer_id,
        customer_name,
        region,
        Total_Sales,
        AVG(Total_Sales) OVER () AS Overall_Avg_Customer_Sales
    FROM Customer_Sales
)
SELECT
    region,
    customer_id,
    customer_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(Overall_Avg_Customer_Sales, 2) AS Overall_Avg_Customer_Sales,
    ROUND(Total_Sales - Overall_Avg_Customer_Sales, 2) AS Difference_From_Avg
FROM Overall_Average
WHERE Total_Sales > Overall_Avg_Customer_Sales
ORDER BY Difference_From_Avg DESC;

-- 10. Each customer's monthly sales and rank within that month
WITH Monthly_Sales AS (
    SELECT
        YEAR(order_date) AS Sales_Year,
        MONTH(order_date) AS Sales_Month,
        customer_id,
        customer_name,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY
        YEAR(order_date),
        MONTH(order_date),
        customer_id,
        customer_name
),
Ranked_Sales AS (
    SELECT
        Sales_Year,
        Sales_Month,
        customer_id,
        customer_name,
        Total_Sales,
        DENSE_RANK() OVER (
            PARTITION BY Sales_Year, Sales_Month
            ORDER BY Total_Sales DESC
        ) AS Monthly_Sales_Rank
    FROM Monthly_Sales
)
SELECT
    Sales_Year,
    Sales_Month,
    customer_id,
    customer_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Monthly_Sales_Rank
FROM Ranked_Sales
ORDER BY Sales_Year, Sales_Month, Monthly_Sales_Rank, customer_id;

-- 11. Customer first/last purchase dates and observed customer lifetime
-- This is the span between first and last recorded purchases, not customer age.
WITH Customer_Purchase_Dates AS (
    SELECT
        customer_id,
        customer_name,
        MIN(order_date) AS First_Purchase_Date,
        MAX(order_date) AS Last_Purchase_Date
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name
)
SELECT
    customer_id,
    customer_name,
    First_Purchase_Date,
    Last_Purchase_Date,
    DATEDIFF(Last_Purchase_Date, First_Purchase_Date) AS Customer_Lifetime_Days
FROM Customer_Purchase_Dates
ORDER BY Customer_Lifetime_Days DESC;

-- 12. Customer recency and status
-- Reference date is the latest order date in this dataset, not the current date.
WITH Customer_Last_Purchase AS (
    SELECT
        customer_id,
        customer_name,
        MAX(order_date) AS Last_Purchase_Date
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name
),
Reference_Date AS (
    SELECT MAX(order_date) AS Latest_Date
    FROM ecommerce_clean
),
Customer_Recency AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.Last_Purchase_Date,
        DATEDIFF(r.Latest_Date, c.Last_Purchase_Date) AS Days_Since_Last_Purchase
    FROM Customer_Last_Purchase AS c
    CROSS JOIN Reference_Date AS r
),
Customer_Status AS (
    SELECT
        customer_id,
        customer_name,
        Last_Purchase_Date,
        Days_Since_Last_Purchase,
        CASE
            WHEN Days_Since_Last_Purchase <= 90 THEN 'Active'
            WHEN Days_Since_Last_Purchase <= 180 THEN 'Recent'
            WHEN Days_Since_Last_Purchase <= 365 THEN 'At Risk'
            ELSE 'Inactive'
        END AS Customer_Status
    FROM Customer_Recency
)
SELECT
    customer_id,
    customer_name,
    Last_Purchase_Date,
    Days_Since_Last_Purchase,
    Customer_Status
FROM Customer_Status
ORDER BY Days_Since_Last_Purchase DESC;

-- 13. Customer order-frequency segments
WITH Customer_Orders AS (
    SELECT
        customer_id,
        customer_name,
        COUNT(DISTINCT order_id) AS Total_Orders
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name
),
Customer_Order_Segments AS (
    SELECT
        customer_id,
        customer_name,
        Total_Orders,
        CASE
            WHEN Total_Orders = 1 THEN 'One-Time'
            WHEN Total_Orders BETWEEN 2 AND 3 THEN 'Occasional'
            WHEN Total_Orders BETWEEN 4 AND 6 THEN 'Frequent'
            ELSE 'Loyal'
        END AS Customer_Segment
    FROM Customer_Orders
)
SELECT
    customer_id,
    customer_name,
    Total_Orders,
    Customer_Segment
FROM Customer_Order_Segments
ORDER BY Total_Orders DESC, customer_id;
