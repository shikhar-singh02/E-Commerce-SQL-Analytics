-- ============================================================
-- e-commerce sales & customer analytics
-- 05 - Product Analysis
-- Purpose: evaluate category, sub-category and product performance
-- Database: MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- 1. Category Performance
SELECT
    category,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY category
ORDER BY Total_Sales DESC;

-- 2. Sub-category Performance
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY category, sub_category
ORDER BY Total_Profit DESC;

-- 3. Top 10 Products by Sales, with profitability metrics
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    SUM(quantity) AS Total_Quantity,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY product_id, product_name, category, sub_category
ORDER BY Total_Sales DESC
LIMIT 10;

-- 4. Products with high sales but negative total profit
-- The 3000 sales threshold is a project-specific business rule.
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY product_id, product_name, category, sub_category
HAVING SUM(sales) >= 3000
   AND SUM(profit) < 0
ORDER BY Total_Profit ASC;

-- 5. Top-selling product in each category
-- Product ID is included so separate products with the same display name are not merged.
WITH Product_Sales AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY product_id, product_name, category
),
Ranked_Products AS (
    SELECT
        product_id,
        product_name,
        category,
        Total_Sales,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY Total_Sales DESC, product_id
        ) AS Sales_Rank
    FROM Product_Sales
)
SELECT
    category,
    product_id,
    product_name,
    ROUND(Total_Sales, 2) AS Total_Sales
FROM Ranked_Products
WHERE Sales_Rank = 1
ORDER BY Total_Sales DESC;

-- 6. Top 3 products within each category
WITH Product_Sales AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY product_id, product_name, category
),
Ranked_Products AS (
    SELECT
        product_id,
        product_name,
        category,
        Total_Sales,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY Total_Sales DESC, product_id
        ) AS Sales_Rank
    FROM Product_Sales
)
SELECT
    category,
    product_id,
    product_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Sales_Rank
FROM Ranked_Products
WHERE Sales_Rank <= 3
ORDER BY category, Sales_Rank;

-- 7. Pareto Analysis: products contributing to approximately the first 80% of sales.
-- This includes the product that crosses the 80% threshold.
WITH Product_Sales AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY product_id, product_name, category
),
Ranking_Products AS (
    SELECT
        product_id,
        product_name,
        category,
        Total_Sales,
        ROW_NUMBER() OVER (
            ORDER BY Total_Sales DESC, product_id
        ) AS Product_Rank,
        SUM(Total_Sales) OVER (
            ORDER BY Total_Sales DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Sales,
        SUM(Total_Sales) OVER () AS Overall_Sales
    FROM Product_Sales
),
Cumulative_Sales_Pct AS (
    SELECT
        product_id,
        product_name,
        category,
        Total_Sales,
        Product_Rank,
        Cumulative_Sales,
        Overall_Sales,
        ROUND(Cumulative_Sales / NULLIF(Overall_Sales, 0) * 100, 2) AS Cumulative_Sales_Pct,
        LAG(
            ROUND(Cumulative_Sales / NULLIF(Overall_Sales, 0) * 100, 2)
        ) OVER (ORDER BY Product_Rank) AS Previous_Cumulative_Sales_Pct
    FROM Ranking_Products
)
SELECT
    product_id,
    product_name,
    category,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Product_Rank,
    Cumulative_Sales_Pct
FROM Cumulative_Sales_Pct
WHERE Cumulative_Sales_Pct <= 80
   OR COALESCE(Previous_Cumulative_Sales_Pct, 0) < 80
ORDER BY Product_Rank;
