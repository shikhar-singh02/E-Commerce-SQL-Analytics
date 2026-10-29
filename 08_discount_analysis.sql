-- ============================================================
-- e-commerce sales & customer analytics
-- 08 - Discount Analysis
-- Purpose: assess discount bands and identify high-discount,
--          loss-making products.
-- Database: MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- 1. Discount-band performance
-- Assumes discount is stored as a fraction (e.g. 0.10 = 10%).
SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount > 0 AND discount <= 0.10 THEN 'Low Discount'
        WHEN discount > 0.10 AND discount <= 0.30 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS Discount_Band,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY Discount_Band
ORDER BY
    CASE Discount_Band
        WHEN 'No Discount' THEN 1
        WHEN 'Low Discount' THEN 2
        WHEN 'Medium Discount' THEN 3
        WHEN 'High Discount' THEN 4
        ELSE 5
    END;

-- 2. Products whose average discount is above the overall average
-- product-level average discount and whose total profit is negative.
WITH Product_Discount AS (
    SELECT
        product_id,
        AVG(discount) AS Avg_Product_Discount
    FROM ecommerce_clean
    WHERE product_id IS NOT NULL
    GROUP BY product_id
),
Overall_Product_Discount AS (
    SELECT AVG(Avg_Product_Discount) AS Overall_Avg_Product_Discount
    FROM Product_Discount
),
Product_Performance AS (
    SELECT
        product_id,
        product_name,
        category,
        AVG(discount) AS Avg_Discount,
        SUM(sales) AS Total_Sales,
        SUM(profit) AS Total_Profit
    FROM ecommerce_clean
    GROUP BY product_id, product_name, category
)
SELECT
    p.product_id,
    p.product_name,
    p.category,
    ROUND(p.Avg_Discount, 4) AS Avg_Discount,
    ROUND(p.Total_Sales, 2) AS Total_Sales,
    ROUND(p.Total_Profit, 2) AS Total_Profit
FROM Product_Performance AS p
CROSS JOIN Overall_Product_Discount AS o
WHERE p.Avg_Discount > o.Overall_Avg_Product_Discount
  AND p.Total_Profit < 0
ORDER BY p.Total_Profit ASC;
