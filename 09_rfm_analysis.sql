-- ============================================================
-- e-commerce sales & customer analytics
-- 09 - RFM Analysis
-- Purpose: customer revenue contribution, Pareto analysis,
--          RFM scoring, segment performance, and at-risk customers.
-- Database: MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- 1. Customer sales contribution and cumulative contribution
WITH Customer_Sales AS (
    SELECT
        customer_id,
        customer_name,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name
),
Customer_Contribution AS (
    SELECT
        customer_id,
        customer_name,
        Total_Sales,
        SUM(Total_Sales) OVER () AS Overall_Sales,
        SUM(Total_Sales) OVER (
            ORDER BY Total_Sales DESC, customer_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Sales
    FROM Customer_Sales
)
SELECT
    customer_id,
    customer_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(Overall_Sales, 2) AS Overall_Sales,
    ROUND(Cumulative_Sales, 2) AS Cumulative_Sales,
    ROUND(Total_Sales / NULLIF(Overall_Sales, 0) * 100, 2) AS Sales_Contribution_Pct,
    ROUND(Cumulative_Sales / NULLIF(Overall_Sales, 0) * 100, 2) AS Cumulative_Sales_Pct
FROM Customer_Contribution
ORDER BY Total_Sales DESC, customer_id;

-- 2. Customer Pareto analysis: customers contributing to approximately
-- the first 80% of company sales. Includes the customer crossing 80%.
WITH Customer_Sales AS (
    SELECT
        customer_id,
        customer_name,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name
),
Ranked_Customers AS (
    SELECT
        customer_id,
        customer_name,
        Total_Sales,
        ROW_NUMBER() OVER (
            ORDER BY Total_Sales DESC, customer_id
        ) AS Customer_Rank,
        SUM(Total_Sales) OVER (
            ORDER BY Total_Sales DESC, customer_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Sales,
        SUM(Total_Sales) OVER () AS Overall_Sales
    FROM Customer_Sales
),
Customer_Pareto AS (
    SELECT
        customer_id,
        customer_name,
        Total_Sales,
        Customer_Rank,
        ROUND(Cumulative_Sales / NULLIF(Overall_Sales, 0) * 100, 2) AS Cumulative_Sales_Pct,
        LAG(
            ROUND(Cumulative_Sales / NULLIF(Overall_Sales, 0) * 100, 2)
        ) OVER (ORDER BY Customer_Rank) AS Previous_Cumulative_Sales_Pct
    FROM Ranked_Customers
)
SELECT
    customer_id,
    customer_name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Customer_Rank,
    Cumulative_Sales_Pct
FROM Customer_Pareto
WHERE Cumulative_Sales_Pct <= 80
   OR COALESCE(Previous_Cumulative_Sales_Pct, 0) < 80
ORDER BY Customer_Rank;

-- 3. Product Pareto analysis: products contributing to approximately
-- the first 80% of company sales. Includes the product crossing 80%.
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
            ORDER BY Total_Sales DESC, product_id
        ) AS Product_Rank,
        SUM(Total_Sales) OVER (
            ORDER BY Total_Sales DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Sales,
        SUM(Total_Sales) OVER () AS Overall_Sales
    FROM Product_Sales
),
Product_Pareto AS (
    SELECT
        product_id,
        product_name,
        category,
        Total_Sales,
        Product_Rank,
        ROUND(Cumulative_Sales / NULLIF(Overall_Sales, 0) * 100, 2) AS Cumulative_Sales_Pct,
        LAG(
            ROUND(Cumulative_Sales / NULLIF(Overall_Sales, 0) * 100, 2)
        ) OVER (ORDER BY Product_Rank) AS Previous_Cumulative_Sales_Pct
    FROM Ranked_Products
)
SELECT
    product_id,
    product_name,
    category,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Product_Rank,
    Cumulative_Sales_Pct
FROM Product_Pareto
WHERE Cumulative_Sales_Pct <= 80
   OR COALESCE(Previous_Cumulative_Sales_Pct, 0) < 80
ORDER BY Product_Rank;

-- 4. RFM scoring and customer segmentation
-- Recency: more recent purchases receive higher scores.
-- Frequency and Monetary: more orders/spending receive higher scores.
WITH RFM_Base AS (
    SELECT
        customer_id,
        customer_name,
        MAX(order_date) AS Last_Purchase_Date,
        COUNT(DISTINCT order_id) AS Total_Orders,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name
),
Reference_Date AS (
    SELECT MAX(order_date) AS Latest_Date
    FROM ecommerce_clean
),
RFM_Metrics AS (
    SELECT
        r.customer_id,
        r.customer_name,
        r.Last_Purchase_Date,
        r.Total_Orders,
        r.Total_Sales,
        DATEDIFF(d.Latest_Date, r.Last_Purchase_Date) AS Recency_Days
    FROM RFM_Base AS r
    CROSS JOIN Reference_Date AS d
),
RFM_Scoring AS (
    SELECT
        customer_id,
        customer_name,
        Last_Purchase_Date,
        Total_Orders,
        Total_Sales,
        Recency_Days,
        6 - NTILE(5) OVER (ORDER BY Recency_Days ASC, customer_id) AS R_Score,
        NTILE(5) OVER (ORDER BY Total_Orders ASC, customer_id) AS F_Score,
        NTILE(5) OVER (ORDER BY Total_Sales ASC, customer_id) AS M_Score
    FROM RFM_Metrics
),
RFM_Total AS (
    SELECT
        customer_id,
        customer_name,
        Last_Purchase_Date,
        Total_Orders,
        Total_Sales,
        Recency_Days,
        R_Score,
        F_Score,
        M_Score,
        R_Score + F_Score + M_Score AS RFM_Total_Score
    FROM RFM_Scoring
)
SELECT
    customer_id,
    customer_name,
    Last_Purchase_Date,
    Total_Orders,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Recency_Days,
    R_Score,
    F_Score,
    M_Score,
    RFM_Total_Score,
    CASE
        WHEN RFM_Total_Score BETWEEN 13 AND 15 THEN 'Champions'
        WHEN RFM_Total_Score BETWEEN 10 AND 12 THEN 'Loyal Customers'
        WHEN RFM_Total_Score BETWEEN 7 AND 9 THEN 'Potential Customers'
        WHEN RFM_Total_Score BETWEEN 4 AND 6 THEN 'At Risk'
        ELSE 'Lost Customers'
    END AS Customer_Segment
FROM RFM_Total
ORDER BY RFM_Total_Score DESC, Total_Sales DESC;

-- 5. RFM segment summary: customer count, revenue, average revenue,
-- and percentage contribution to total customer revenue.
WITH RFM_Base AS (
    SELECT
        customer_id,
        customer_name,
        MAX(order_date) AS Last_Purchase_Date,
        COUNT(DISTINCT order_id) AS Total_Orders,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name
),
Reference_Date AS (
    SELECT MAX(order_date) AS Latest_Date
    FROM ecommerce_clean
),
RFM_Metrics AS (
    SELECT
        r.customer_id,
        r.customer_name,
        r.Last_Purchase_Date,
        r.Total_Orders,
        r.Total_Sales,
        DATEDIFF(d.Latest_Date, r.Last_Purchase_Date) AS Recency_Days
    FROM RFM_Base AS r
    CROSS JOIN Reference_Date AS d
),
RFM_Scoring AS (
    SELECT
        customer_id,
        customer_name,
        Last_Purchase_Date,
        Total_Orders,
        Total_Sales,
        Recency_Days,
        6 - NTILE(5) OVER (ORDER BY Recency_Days ASC, customer_id) AS R_Score,
        NTILE(5) OVER (ORDER BY Total_Orders ASC, customer_id) AS F_Score,
        NTILE(5) OVER (ORDER BY Total_Sales ASC, customer_id) AS M_Score
    FROM RFM_Metrics
),
Customer_Segment AS (
    SELECT
        customer_id,
        customer_name,
        Total_Orders,
        Total_Sales,
        R_Score + F_Score + M_Score AS RFM_Total_Score,
        CASE
            WHEN R_Score + F_Score + M_Score BETWEEN 13 AND 15 THEN 'Champions'
            WHEN R_Score + F_Score + M_Score BETWEEN 10 AND 12 THEN 'Loyal Customers'
            WHEN R_Score + F_Score + M_Score BETWEEN 7 AND 9 THEN 'Potential Customers'
            WHEN R_Score + F_Score + M_Score BETWEEN 4 AND 6 THEN 'At Risk'
            ELSE 'Lost Customers'
        END AS Customer_Segment
    FROM RFM_Scoring
),
Segment_Analysis AS (
    SELECT
        Customer_Segment,
        COUNT(*) AS Customer_Count,
        SUM(Total_Sales) AS Total_Sales,
        AVG(Total_Sales) AS Avg_Sales_Per_Customer,
        SUM(Total_Sales) / NULLIF(SUM(SUM(Total_Sales)) OVER (), 0) * 100 AS Sales_Contribution_Pct
    FROM Customer_Segment
    GROUP BY Customer_Segment
)
SELECT
    Customer_Segment,
    Customer_Count,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(Avg_Sales_Per_Customer, 2) AS Avg_Sales_Per_Customer,
    ROUND(Sales_Contribution_Pct, 2) AS Sales_Contribution_Pct
FROM Segment_Analysis
ORDER BY Total_Sales DESC;

-- 6. High-value at-risk customers.
-- "At Risk" is defined here as RFM total score 4-6; high value means
-- customer sales exceed the average sales across all customers.
WITH RFM_Base AS (
    SELECT
        customer_id,
        customer_name,
        MAX(order_date) AS Last_Purchase_Date,
        COUNT(DISTINCT order_id) AS Total_Orders,
        SUM(sales) AS Total_Sales
    FROM ecommerce_clean
    GROUP BY customer_id, customer_name
),
Reference_Date AS (
    SELECT MAX(order_date) AS Latest_Date
    FROM ecommerce_clean
),
RFM_Metrics AS (
    SELECT
        r.customer_id,
        r.customer_name,
        r.Last_Purchase_Date,
        r.Total_Orders,
        r.Total_Sales,
        DATEDIFF(d.Latest_Date, r.Last_Purchase_Date) AS Recency_Days
    FROM RFM_Base AS r
    CROSS JOIN Reference_Date AS d
),
RFM_Scoring AS (
    SELECT
        customer_id,
        customer_name,
        Last_Purchase_Date,
        Total_Orders,
        Total_Sales,
        Recency_Days,
        6 - NTILE(5) OVER (ORDER BY Recency_Days ASC, customer_id) AS R_Score,
        NTILE(5) OVER (ORDER BY Total_Orders ASC, customer_id) AS F_Score,
        NTILE(5) OVER (ORDER BY Total_Sales ASC, customer_id) AS M_Score
    FROM RFM_Metrics
),
Customer_Segment AS (
    SELECT
        customer_id,
        customer_name,
        Last_Purchase_Date,
        Total_Orders,
        Total_Sales,
        Recency_Days,
        R_Score + F_Score + M_Score AS RFM_Total_Score,
        CASE
            WHEN R_Score + F_Score + M_Score BETWEEN 13 AND 15 THEN 'Champions'
            WHEN R_Score + F_Score + M_Score BETWEEN 10 AND 12 THEN 'Loyal Customers'
            WHEN R_Score + F_Score + M_Score BETWEEN 7 AND 9 THEN 'Potential Customers'
            WHEN R_Score + F_Score + M_Score BETWEEN 4 AND 6 THEN 'At Risk'
            ELSE 'Lost Customers'
        END AS Customer_Segment,
        AVG(Total_Sales) OVER () AS Overall_Avg_Customer_Sales
    FROM RFM_Scoring
)
SELECT
    customer_id,
    customer_name,
    Last_Purchase_Date,
    Total_Sales,
    Total_Orders,
    Recency_Days,
    RFM_Total_Score,
    Customer_Segment
FROM Customer_Segment
WHERE Customer_Segment = 'At Risk'
  AND Total_Sales > Overall_Avg_Customer_Sales
ORDER BY Total_Sales DESC;
