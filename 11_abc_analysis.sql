-- ============================================================
-- e-commerce sales & customer analytics
-- 11 - ABC Analysis
-- Database: MySQL 8.0+
-- Purpose: classify products by sales contribution.
--
-- Method:
--   A = cumulative sales contribution up to 80%
--   B = above 80% and up to 95%
--   C = above 95%
-- A product that crosses a threshold is assigned to the next band
-- under these rules. This is a threshold-based ABC convention.
-- Classic Pareto interpretation assumes sales are non-negative.
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- 1. Overall ABC classification by product.
WITH Product_Sales AS (
    SELECT
        product_id,
        product_name,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY product_id, product_name
),
Product_Contribution AS (
    SELECT
        product_id,
        product_name,
        Total_Sales,
        SUM(Total_Sales) OVER () AS Overall_Sales,
        SUM(Total_Sales) OVER (
            ORDER BY Total_Sales DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Sales
    FROM Product_Sales
),
Product_ABC AS (
    SELECT
        product_id,
        product_name,
        Total_Sales,
        ROUND(Total_Sales / NULLIF(Overall_Sales, 0) * 100, 2) AS Sales_Contribution_Pct,
        ROUND(Cumulative_Sales / NULLIF(Overall_Sales, 0) * 100, 2) AS Cumulative_Sales_Pct
    FROM Product_Contribution
)
SELECT
    product_id,
    product_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Sales_Contribution_Pct,
    Cumulative_Sales_Pct,
    CASE
        WHEN Cumulative_Sales_Pct <= 80 THEN 'A'
        WHEN Cumulative_Sales_Pct <= 95 THEN 'B'
        ELSE 'C'
    END AS ABC_Category
FROM Product_ABC
ORDER BY Total_Sales DESC, product_id;

-- 2. Overall ABC category summary: product count, sales, and
-- contribution to company sales.
WITH Product_Sales AS (
    SELECT
        product_id,
        product_name,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY product_id, product_name
),
Product_Contribution AS (
    SELECT
        product_id,
        product_name,
        Total_Sales,
        SUM(Total_Sales) OVER () AS Overall_Sales,
        SUM(Total_Sales) OVER (
            ORDER BY Total_Sales DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Sales
    FROM Product_Sales
),
Product_ABC AS (
    SELECT
        product_id,
        product_name,
        Total_Sales,
        ROUND(Cumulative_Sales / NULLIF(Overall_Sales, 0) * 100, 2) AS Cumulative_Sales_Pct
    FROM Product_Contribution
),
ABC_Category AS (
    SELECT
        product_id,
        product_name,
        Total_Sales,
        CASE
            WHEN Cumulative_Sales_Pct <= 80 THEN 'A'
            WHEN Cumulative_Sales_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Category
    FROM Product_ABC
)
SELECT
    ABC_Category,
    COUNT(*) AS Product_Count,
    ROUND(SUM(Total_Sales), 2) AS Category_Sales,
    ROUND(
        SUM(Total_Sales) / NULLIF(SUM(SUM(Total_Sales)) OVER (), 0) * 100,
        2
    ) AS Sales_Contribution_Pct
FROM ABC_Category
GROUP BY ABC_Category
ORDER BY Category_Sales DESC;

-- 3. ABC classification within each product category.
-- Each category has its own cumulative sales percentage.
WITH Product_Sales AS (
    SELECT
        category,
        product_id,
        product_name,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY category, product_id, product_name
),
Product_Contribution AS (
    SELECT
        category,
        product_id,
        product_name,
        Total_Sales,
        SUM(Total_Sales) OVER (PARTITION BY category) AS Category_Total_Sales,
        SUM(Total_Sales) OVER (
            PARTITION BY category
            ORDER BY Total_Sales DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Category_Sales
    FROM Product_Sales
),
Product_ABC AS (
    SELECT
        category,
        product_id,
        product_name,
        Total_Sales,
        ROUND(Total_Sales / NULLIF(Category_Total_Sales, 0) * 100, 2) AS Sales_Contribution_Pct,
        ROUND(Cumulative_Category_Sales / NULLIF(Category_Total_Sales, 0) * 100, 2) AS Cumulative_Sales_Pct
    FROM Product_Contribution
)
SELECT
    category,
    product_id,
    product_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Sales_Contribution_Pct,
    Cumulative_Sales_Pct,
    CASE
        WHEN Cumulative_Sales_Pct <= 80 THEN 'A'
        WHEN Cumulative_Sales_Pct <= 95 THEN 'B'
        ELSE 'C'
    END AS ABC_Category
FROM Product_ABC
ORDER BY category, Total_Sales DESC, product_id;

-- 4. Summary of ABC classes within each product category.
-- Category_Sales_Contribution_Pct is each ABC class's share
-- of its own category's sales, not company-wide sales.
WITH Product_Sales AS (
    SELECT
        category,
        product_id,
        product_name,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY category, product_id, product_name
),
Product_Contribution AS (
    SELECT
        category,
        product_id,
        product_name,
        Total_Sales,
        SUM(Total_Sales) OVER (PARTITION BY category) AS Category_Total_Sales,
        SUM(Total_Sales) OVER (
            PARTITION BY category
            ORDER BY Total_Sales DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Category_Sales
    FROM Product_Sales
),
Product_ABC AS (
    SELECT
        category,
        product_id,
        product_name,
        Total_Sales,
        ROUND(
            Cumulative_Category_Sales / NULLIF(Category_Total_Sales, 0) * 100,
            2
        ) AS Cumulative_Sales_Pct
    FROM Product_Contribution
),
ABC_Category AS (
    SELECT
        category,
        product_id,
        product_name,
        Total_Sales,
        CASE
            WHEN Cumulative_Sales_Pct <= 80 THEN 'A'
            WHEN Cumulative_Sales_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Category
    FROM Product_ABC
)
SELECT
    category,
    ABC_Category,
    COUNT(*) AS Product_Count,
    ROUND(SUM(Total_Sales), 2) AS Category_Sales,
    ROUND(
        SUM(Total_Sales) /
        NULLIF(SUM(SUM(Total_Sales)) OVER (PARTITION BY category), 0) * 100,
        2
    ) AS Category_Sales_Contribution_Pct
FROM ABC_Category
GROUP BY category, ABC_Category
ORDER BY category, ABC_Category;
