-- ============================================================
-- e-commerce sales & customer analytics
-- 03 - Executive KPIs
-- Purpose: calculate core management KPIs from ecommerce_clean
-- MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

SELECT
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Unique_Orders,
    SUM(quantity) AS Total_Quantity,
    ROUND(SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS Average_Order_Value
FROM ecommerce_clean;
