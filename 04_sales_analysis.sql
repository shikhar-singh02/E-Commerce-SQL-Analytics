-- ============================================================
-- e-commerce sales & customer analytics
-- 04 - Sales Analysis
-- Purpose: analyze sales/profit trends, performance, growth and running totals
-- Database: MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- 1. Monthly Sales and Profit Trend
SELECT
    YEAR(order_date) AS Year,
    MONTH(order_date) AS Month,
    ROUND(SUM(sales), 2) AS Monthly_Sales,
    ROUND(SUM(profit), 2) AS Monthly_Profit,
    COUNT(DISTINCT order_id) AS Monthly_Unique_Orders
FROM ecommerce_clean
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY Year, Month;

-- 2. Category Performance
SELECT
    category,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY category
ORDER BY Total_Sales DESC;

-- 3. Sub-category Performance
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

-- 4. Region-Wise Performance
SELECT
    region,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY region
ORDER BY Total_Profit DESC;

-- 5. State-Wise Performance (lowest profit first)
SELECT
    state,
    ROUND(SUM(sales), 2) AS Total_Sales,
    ROUND(SUM(profit), 2) AS Total_Profit,
    COUNT(DISTINCT order_id) AS Total_Orders,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY state
ORDER BY Total_Profit ASC;

-- 6. Loss-Making States
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

-- 7. Discount-Band Profitability
-- Assumes discount is stored as a fraction (0.10 = 10%).
SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount > 0 AND discount <= 0.10 THEN 'Low Discount'
        WHEN discount > 0.10 AND discount <= 0.30 THEN 'Medium Discount'
        WHEN discount > 0.30 THEN 'High Discount'
        ELSE 'Unknown Discount'
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

-- 8. Month-over-Month (MoM) Sales Growth
WITH Monthly_Sales AS (
    SELECT
        YEAR(order_date) AS Year,
        MONTH(order_date) AS Month,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date), MONTH(order_date)
),
Previous_Month_Sales AS (
    SELECT
        Year,
        Month,
        Total_Sales,
        LAG(Total_Sales) OVER (ORDER BY Year, Month) AS Previous_Month_Sales
    FROM Monthly_Sales
)
SELECT
    Year,
    Month,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(Previous_Month_Sales, 2) AS Previous_Month_Sales,
    ROUND(Total_Sales - Previous_Month_Sales, 2) AS Sales_Change,
    CASE
        WHEN Previous_Month_Sales IS NULL OR Previous_Month_Sales = 0 THEN NULL
        ELSE ROUND((Total_Sales - Previous_Month_Sales) / Previous_Month_Sales * 100, 2)
    END AS Growth_Pct
FROM Previous_Month_Sales
ORDER BY Year, Month;

-- 9. Year-over-Year (YoY) Sales Growth
-- Matches each month with the same calendar month in the prior year.
-- Unlike LAG(..., 12), this still works if one or more months are missing.
WITH Monthly_Sales AS (
    SELECT
        YEAR(order_date) AS Year,
        MONTH(order_date) AS Month,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date), MONTH(order_date)
),
YoY_Comparison AS (
    SELECT
        current_year.Year,
        current_year.Month,
        current_year.Total_Sales,
        previous_year.Total_Sales AS Previous_Year_Sales
    FROM Monthly_Sales AS current_year
    LEFT JOIN Monthly_Sales AS previous_year
        ON previous_year.Year = current_year.Year - 1
       AND previous_year.Month = current_year.Month
)
SELECT
    Year,
    Month,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(Previous_Year_Sales, 2) AS Previous_Year_Sales,
    ROUND(Total_Sales - Previous_Year_Sales, 2) AS Sales_Change,
    CASE
        WHEN Previous_Year_Sales IS NULL OR Previous_Year_Sales = 0 THEN NULL
        ELSE ROUND((Total_Sales - Previous_Year_Sales) / Previous_Year_Sales * 100, 2)
    END AS Growth_Pct
FROM YoY_Comparison
ORDER BY Year, Month;

-- 10. Running Total of Sales Across the Available Timeline
WITH Monthly_Sales AS (
    SELECT
        YEAR(order_date) AS Year,
        MONTH(order_date) AS Month,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT
    Year,
    Month,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(
        SUM(Total_Sales) OVER (
            ORDER BY Year, Month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Running_Total_Sales
FROM Monthly_Sales
ORDER BY Year, Month;
