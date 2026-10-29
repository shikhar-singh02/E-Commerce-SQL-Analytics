-- ============================================================
-- e-commerce sales & customer analytics
-- 13 - Business Investigation
-- MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- Assumptions: ecommerce_clean contains cleaned data; discount is stored as a fraction
-- (0.10 = 10%). Inactivity checks use the latest order_date in the dataset as reference.

-- EXECUTIVE BUSINESS INVESTIGATION

-- Total_Sales,Total_Profit,Total_Orders,Total_Customers,Total_Quantity, Average_Order_Value,Profit_Margin_Pct

WITH KPIs AS (
     SELECT 
        ROUND(SUM(sales), 2 ) AS Total_Sales,
        ROUND(SUM(profit) , 2 ) AS Total_Profit,
        COUNT(DISTINCT order_id) AS Total_Orders,
        COUNT(DISTINCT(customer_id)) AS Total_Customers,
        SUM(Quantity) AS Total_Quantity,
        ROUND(SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS Average_Order_Value,
        ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
	FROM ecommerce_clean
    )
SELECT *
FROM KPIs;

-- Categories above average category sales with profit margin below 15%

SELECT 
  category,
  ROUND(SUM(sales), 2 ) AS Total_Sales,
  ROUND(SUM(profit) , 2 ) AS Total_Profit,
  ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY
  category
HAVING 
  SUM(sales) > 
   (
    SELECT AVG(Category_Sales)
    FROM
     ( 
      SELECT 
        category,
        SUM(sales) AS Category_Sales
	  FROM ecommerce_clean
      GROUP BY category
      ) x
	) AND
  SUM(profit) / NULLIF(SUM(sales), 0) * 100 < 15
ORDER BY Total_Sales DESC;

-- Subcategories above average subcategory sales with profit margin below 10%
 
SELECT 
  category,
  sub_category,
  ROUND(SUM(sales), 2 ) AS Total_Sales,
  ROUND(SUM(profit) , 2 ) AS Total_Profit,
  ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY
  category,
  sub_category
HAVING 
  SUM(sales) > 
   (
    SELECT AVG(Sub_Category_Sales)
    FROM
     ( 
      SELECT 
        sub_category,
        SUM(sales) AS Sub_Category_Sales
	  FROM ecommerce_clean
      GROUP BY sub_category
      ) x
	) AND
  SUM(profit) / NULLIF(SUM(sales), 0) * 100 < 10
ORDER BY Total_Sales DESC;

-- products where subcategories total_sales are > avg subcategories sales,product profit margin below 10%

SELECT 
   e1.category,
   e1.sub_category,
   e1.product_id,
   e1.product_name,
   ROUND(SUM(e1.sales), 2 ) AS Total_Sales,
   ROUND(SUM(e1.profit) , 2 ) AS Total_Profit,
   ROUND(SUM(e1.profit) / NULLIF(SUM(e1.sales), 0) * 100 , 2 ) AS Profit_Margin_Pct
FROM ecommerce_clean e1
GROUP BY 
   e1.category,
   e1.sub_category,
   e1.product_id,
   e1.product_name
HAVING 
  (
   SELECT
     SUM(e2.sales)
	FROM ecommerce_clean e2 
    WHERE
     e1.sub_category = e2.sub_category) > 
    (
     SELECT 
	   AVG(Sub_Category_Sales)
	 FROM 
        (
		 SELECT
          sub_category,
          SUM(sales) AS Sub_Category_Sales
	     FROM ecommerce_clean
         GROUP BY sub_category
         ) x
	) AND 
   SUM(e1.profit) / NULLIF(SUM(e1.sales), 0) * 100 < 10
ORDER BY Total_Sales DESC;
    
-- products satisfy both(avg discount > overall avg product discount and total profit is negative)

SELECT 
   e1.product_id,
   e1.product_name,
   e1.category,
   ROUND(AVG(discount),2) AS Avg_Discount,
   ROUND(SUM(e1.sales), 2 ) AS Total_Sales,
   ROUND(SUM(e1.profit) , 2 ) AS Total_Profit
FROM ecommerce_clean e1
GROUP BY 
  product_id,
  product_name,
  category
HAVING AVG(e1.discount) >
   (
    SELECT
      AVG(Product_Avg_Discount)
	FROM 
      ( 
       SELECT 
         product_id,
         AVG(Discount) AS Product_Avg_Discount
       FROM ecommerce_clean 
       GROUP BY product_id
       ) x
	) AND 
    SUM(e1.profit) < 0
ORDER BY Total_Profit;

-- Regions where (total sales > avg regional sales, profit margin < 10% and total orders)

SELECT 
  e1.region,
  ROUND(SUM(e1.sales), 2 ) AS Total_Sales,
  ROUND(SUM(e1.profit) , 2 ) AS Total_Profit,
  ROUND(SUM(e1.profit) / NULLIF(SUM(e1.sales), 0) * 100 , 2 ) AS Profit_Margin_Pct,
  COUNT(DISTINCT e1.order_id) AS Total_Orders
FROM ecommerce_clean e1
GROUP BY 
   e1.region
HAVING SUM(e1.sales) >
  (
   SELECT AVG(Regional_Sales)
   FROM 
     (
      SELECT 
        region,
        SUM(sales) AS Regional_Sales
	  FROM ecommerce_clean 
      GROUP BY region
	 ) x 
   ) AND 
   SUM(e1.profit) / NULLIF(SUM(e1.sales), 0) * 100 < 10 
ORDER BY Total_Sales DESC;
   
-- Months below average monthly sales with profit margin below 15%

SELECT 
  YEAR(order_date) AS Year,
  MONTH(order_date) AS Month,
  ROUND(SUM(sales), 2 ) AS Total_Sales,
  ROUND(SUM(profit) , 2 ) AS Total_Profit,
  ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM ecommerce_clean
GROUP BY 
   Year,
   Month
HAVING SUM(sales) < 
  (
   SELECT AVG(Monthly_Sales)
   FROM 
     (
      SELECT 
        YEAR(order_date) AS Year,
        MONTH(order_date) AS Month,
        SUM(sales) AS Monthly_Sales
	  FROM ecommerce_clean
      GROUP BY  Year, Month
      ) x
	) AND 
   SUM(profit) / NULLIF(SUM(sales), 0) * 100  < 15
ORDER BY 
   Year,
   Month ;

-- Customers above average sales with negative total profit and at least 2 orders

SELECT 
   e1.customer_id,
   e1.customer_name,
   ROUND(SUM(e1.sales), 2 ) AS Total_Sales,
   ROUND(SUM(e1.profit) , 2 ) AS Total_Profit,
   COUNT(DISTINCT e1.order_id) AS Total_Orders,
   ROUND(SUM(e1.profit) / NULLIF(SUM(e1.sales), 0) * 100 , 2 ) AS Profit_Margin_Pct
FROM ecommerce_clean e1
GROUP BY 
   e1.customer_id,
   e1.customer_name
HAVING 
   SUM(e1.sales) > 
     ( 
      SELECT AVG(Customer_Sales)
      FROM 
         (
          SELECT 
            customer_id,
            customer_name,
            SUM(sales) AS Customer_Sales
		  FROM ecommerce_clean
          GROUP BY 
             customer_id,
             customer_name
		 ) x
	 ) AND 
	SUM(e1.profit) < 0 AND 
    COUNT(DISTINCT e1.order_id) >=2
ORDER BY Total_Sales DESC;

-- Customers above average sales with negative total profit, above-average discount, and at least 3 orders

SELECT 
  e1.customer_id,
  e1.customer_name,
  ROUND(SUM(e1.sales), 2 ) AS Total_Sales,
  ROUND(SUM(e1.profit) , 2 ) AS Total_Profit,
  ROUND(AVG(e1.discount)*  100 , 2 ) AS Avg_Discount_Pct,
  COUNT(DISTINCT e1.order_id) AS Total_Orders,
  ROUND(SUM(e1.profit) / NULLIF(SUM(e1.sales), 0) * 100 , 2 ) AS Profit_Margin_Pct
FROM ecommerce_clean e1
GROUP BY 
  e1.customer_id,
  e1.customer_name
HAVING SUM(e1.sales) > 
  (
   SELECT AVG(Customer_Sales) 
   FROM 
	 (
      SELECT 
        customer_id,
        customer_name,
        SUM(sales) AS Customer_Sales
	  FROM ecommerce_clean 
      GROUP BY 
        customer_id,
        customer_name
	 ) x 
   ) AND 
   SUM(e1.profit) < 0 AND 
   COUNT(DISTINCT e1.order_id) >=3 AND 
   AVG(e1.discount) > 
     (
      SELECT AVG(Product_Avg_Discount)
      FROM 
         (
          SELECT 
            product_id,
            product_name,
            AVG(discount) AS Product_Avg_Discount
		  FROM ecommerce_clean 
          GROUP BY 
			product_id,
            product_name
		  ) x
	  )
ORDER BY Total_Sales DESC;

-- High-value inactive customers: above-average sales, at least 3 orders, last purchase > 90 days ago, and no negative-profit records

SELECT 
  e1.customer_id,
  e1.customer_name,
  ROUND(SUM(e1.sales), 2 ) AS Total_Sales,
  ROUND(SUM(e1.profit) , 2 ) AS Total_Profit,
  COUNT(DISTINCT e1.order_id) AS Total_Orders,
  ROUND(SUM(e1.profit) / NULLIF(SUM(e1.sales), 0) * 100 , 2 ) AS Profit_Margin_Pct,
  MAX(e1.order_date) AS Last_Purchase_Date
FROM ecommerce_clean e1
GROUP BY 
  e1.customer_id,
  e1.customer_name
HAVING SUM(e1.sales) >
	(
     SELECT AVG(Total_Sales)
     FROM 
        (
         SELECT 
          customer_id,
          SUM(sales) AS Total_Sales
         FROM ecommerce_clean
         GROUP BY customer_id
		) x
	) AND 
    COUNT(DISTINCT e1.order_id) >= 3 AND
    DATEDIFF(
	  (
       SELECT MAX(order_date) 
       FROM ecommerce_clean 
	   ), MAX(e1.order_date) ) > 90 AND 
	NOT EXISTS 
       (
        SELECT 1 
        FROM ecommerce_clean e2
        WHERE e1.customer_id = e2.customer_id AND 
              e2.profit < 0
		)
ORDER BY Total_Sales DESC;
        
SELECT
  e1.customer_id,
  e1.customer_name,
  ROUND(SUM(e1.sales), 2 ) AS Total_Sales,
  COUNT(DISTINCT e1.order_id) AS Total_Orders,
  COUNT(DISTINCT e1.category) AS Total_Category,
  MAX(e1.order_date) AS Last_Purchase_Date,
  ROUND(AVG(e1.discount)*  100 , 2 ) AS Avg_Discount_Pct,
  ROUND(SUM(e1.profit) / NULLIF(SUM(e1.sales), 0) * 100 , 2 ) AS Profit_Margin_Pct
FROM 
  ecommerce_clean e1
GROUP BY 
  e1.customer_id,
  e1.customer_name
HAVING SUM(e1.sales) >
	(
     SELECT AVG(Customer_Sales)
     FROM 
        (
         SELECT 
          customer_id,
          SUM(sales) AS Customer_Sales
         FROM ecommerce_clean
         GROUP BY customer_id
		) x
	) AND 
    COUNT(DISTINCT e1.order_id) >= 5 AND
    COUNT(DISTINCT e1.category) >=3 AND
    DATEDIFF(
	  (
       SELECT MAX(order_date) 
       FROM ecommerce_clean 
	   ), MAX(e1.order_date) ) > 60 AND
     SUM(e1.profit) / NULLIF(SUM(e1.sales), 0) * 100  < 10 AND
     AVG(e1.discount) >
        (
          SELECT AVG(Product_Discount) 
          FROM 
            (
             SELECT 
               product_id,
               AVG(discount) AS Product_Discount
			 FROM ecommerce_clean
             GROUP BY product_id
             ) x
		)
ORDER BY Total_Sales DESC;         

SELECT 
   ROUND(SUM(sales), 2 ) AS Total_Sales,
   ROUND(SUM(profit) , 2 ) AS Total_Profit,
   COUNT(DISTINCT order_id) AS Total_Orders,
   COUNT(DISTINCT customer_id) AS Total_Customers,
   SUM(quantity) AS Total_Quantity,
   ROUND(SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS AOV,
   ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS Profit_Margin_Pct,
   ROUND(AVG(discount)*  100 , 2 ) AS Avg_Discount_Pct
FROM ecommerce_clean;