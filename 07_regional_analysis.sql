-- ============================================================
-- e-commerce sales & customer analytics
-- 07 - Regional Analysis
-- Purpose: evaluate regional/state performance and customer
--          sales contribution by geography.
-- Database: MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- 1. Region-wise performance
SELECT
    region,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY region
ORDER BY Total_Profit DESC;

-- 2. State-wise performance
SELECT
    state,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY state
ORDER BY Total_Profit DESC;

-- 3. Loss-making states
SELECT
    state,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY state
HAVING SUM(profit) < 0
ORDER BY Total_Profit ASC;

-- 4. Top 3 customers by sales in each region
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

-- 5. Customer contribution to regional sales
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

-- 6. Highest-selling customer(s) in each month
-- DENSE_RANK returns all customers tied for first place.
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

-- 7. Customers above their region's average customer sales
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

-- 8. Customers above the overall average customer sales
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
