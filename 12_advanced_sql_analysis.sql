-- ============================================================
-- e-commerce sales & customer analytics
-- 12 - Advanced SQL Analysis
-- Database: MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- Assumptions: ecommerce_clean contains cleaned, typed data; discount is stored
-- as a fraction (0.30 = 30%). Queries use the latest order_date in the dataset
-- as the reference date for inactivity checks, not the current calendar date.

-- Scalar Subquery (customers total sales > avg total sales per customer)

SELECT 
   customer_id,
   customer_name,
   ROUND(SUM(sales),2) AS Total_sales
FROM ecommerce_clean
GROUP BY customer_id,
         customer_name
HAVING SUM(sales) >

(SELECT AVG(Total_Sales) 
FROM 
  (SELECT
	customer_id,
	customer_name,
	ROUND(SUM(sales),2) AS Total_sales
	FROM ecommerce_clean
	GROUP BY customer_id,
			 customer_name) x )
ORDER BY Total_Sales DESC;

-- Multi-Row Subquery(Customers purchased from Home category)

SELECT
  customer_id,
  customer_name,
  ROUND(SUM(sales),2) AS Total_sales
FROM ecommerce_clean
WHERE customer_id IN
	(
	 SELECT 
		customer_id
	 FROM ecommerce_clean
	 WHERE category = 'Home'
	)
GROUP BY   
  customer_id,
  customer_name
ORDER BY 
  Total_sales DESC;

-- Correlated Subquery (customers total sales > avg sales of customers in their own region)

SELECT 
  e.customer_id,
  e.customer_name,
  e.region,
  ROUND(SUM(e.sales),2) AS Total_sales
FROM ecommerce_clean e
GROUP BY 
  e.customer_id,
  e.customer_name,
  e.region
HAVING SUM(e.sales) > 
(
  SELECT AVG(Customer_Sales) 
  FROM 
  ( 
    SELECT 
      customer_id,
      region,
      SUM(sales) AS Customer_Sales
	FROM ecommerce_clean 
    GROUP BY 
      customer_id,
      region
   ) x
    WHERE e.region = x.region
)
ORDER BY Total_Sales DESC;

-- EXISTS(customer have at least 1 order with discount > 30%)

SELECT
  e1.customer_id,
  e1.customer_name,
  ROUND(SUM(e1.sales),2) AS Total_sales
FROM ecommerce_clean e1
WHERE EXISTS 
(
  SELECT 1 
  FROM ecommerce_clean e2
  WHERE e1.customer_id = e2.customer_id AND  
      e2.discount > 0.30
)
GROUP BY 
  e1.customer_id,
  e1.customer_name
ORDER BY Total_Sales DESC;

-- NOT EXISTS(customers never purchased product with negative profit)

SELECT 
   e1.customer_id,
   e1.customer_name,
   ROUND(SUM(e1.sales),2) AS Total_sales
FROM ecommerce_clean e1
WHERE NOT EXISTS 
( 
   SELECT 1
   FROM ecommerce_clean e2
   WHERE e1.customer_id = e2.customer_id AND 
         e2.profit < 0
)
GROUP BY 
   e1.customer_id,
   e1.customer_name
ORDER BY 
   Total_Sales DESC;

-- ANY (products whose total_sales > sales of ANY product in "HOME" category)

SELECT 
  product_id,
  product_name,
  ROUND(SUM(sales),2) AS Total_Sales
FROM ecommerce_clean
GROUP BY 
  product_id,
  product_name
HAVING SUM(sales) > ANY
(
 SELECT 
   SUM(sales)
 FROM ecommerce_clean
 WHERE category = 'Home'
 GROUP BY 
   product_id,
   product_name
 )
 ORDER BY Total_Sales DESC;
   
-- ALL(products whose total sales > sales of ALL products in 'Home' category)

SELECT 
  product_id,
  product_name,
  ROUND(SUM(sales),2) AS Total_Sales
FROM ecommerce_clean
GROUP BY 
  product_id,
  product_name
HAVING SUM(sales) > ALL
(
 SELECT 
   SUM(sales)
 FROM ecommerce_clean
 WHERE category = 'Home'
 GROUP BY 
   product_id,
   product_name
 )
 ORDER BY Total_Sales DESC;

-- Business Problem: Products Above Category Average(products whose total_sales > avg product sales within their own category

SELECT 
   e.category,
   e.product_id,
   e.product_name,
   ROUND(SUM(e.sales),2) AS Total_Sales
FROM ecommerce_clean e
GROUP BY 
   e.category,
   e.product_id,
   e.product_name
HAVING SUM(e.sales) > 
(
 SELECT AVG(Product_Sales)
 FROM 
 ( 
  SELECT 
    product_id,
    category,
    SUM(sales) AS Product_Sales
  FROM ecommerce_clean
  GROUP BY
	product_id,
	category
  ) x 
WHERE e.category = x.category
GROUP BY e.category
) 
ORDER BY Total_Sales DESC;

-- Correlated NOT EXISTS  Business Problem(Customers purchased from every category available in the dataset)

SELECT DISTINCT
  e1.customer_id,
  e1.customer_name
FROM ecommerce_clean e1
WHERE NOT EXISTS 
( 
 SELECT 1 
 FROM ecommerce_clean e2
 WHERE NOT EXISTS
 (
    SELECT 1 
    FROM ecommerce_clean e3 
    WHERE e3.customer_id = e1.customer_id AND 
          e3.category = e2.category
  )
);

-- Correlated Exists(customers who purchased at least one product from every category in which they have purchased ,but received 
-- a discount > 20 % on at least one order in each of those categories)

SELECT DISTINCT
  e1.customer_id,
  e1.customer_name
FROM ecommerce_clean e1
WHERE NOT EXISTS
( 
  SELECT 1 
  FROM ecommerce_clean e2
  WHERE e1.customer_id = e2.customer_id 
  AND NOT EXISTS
  (
    SELECT 1
    FROM ecommerce_clean e3
    WHERE e3.customer_id = e1.customer_id AND 
    e2.category = e3.category AND e3.discount > 0.20
  )
);

-- Correlated NOT EXISTS (customers who have never purchased from category where the category's average discount > 25%)

SELECT DISTINCT
  e1.customer_id,
  e1.customer_name
FROM  ecommerce_clean e1
WHERE NOT EXISTS 
( 
 SELECT 1 
 FROM ecommerce_clean e2
 WHERE e1.customer_id = e2.customer_id AND 
 e2.category IN 
  (
    SELECT category
    FROM ecommerce_clean
    GROUP BY category
    HAVING AVG(discount) > 0.25
    )
)
ORDER BY e1.customer_id;

-- Correlated subquery(customers whose total sales > avg total sales of customers in their region and who have placed at least 3 distinct orders)

SELECT 
  e.customer_id,
  e.customer_name,
  e.region,
  ROUND(SUM(e.sales),2) AS Total_Sales,
  COUNT( DISTINCT e.order_id) AS Total_Orders
FROM ecommerce_clean e
GROUP BY 
  e.customer_id,
  e.customer_name,
  e.region
HAVING SUM(e.sales) > 
(
 SELECT 
   AVG(Customer_Sales)
 FROM 
  (
   SELECT 
      customer_id,
      region,
      SUM(sales) AS Customer_Sales
   FROM ecommerce_clean
   GROUP BY 
      customer_id,
      region
   ) x
   WHERE e.region = x.region
  )
AND COUNT(DISTINCT e.order_id) >=3
ORDER BY Total_Sales DESC;
      
-- NOT EXISTS(customers with at least 3 orders, never has negative profit order and purchased from at least 2 different categories)

SELECT 
  e1.customer_id,
  e1.customer_name,
  COUNT(DISTINCT e1.order_id) AS Total_Orders,
  ROUND(SUM(e1.sales),2) AS Total_Sales
FROM ecommerce_clean e1
GROUP BY 
  e1.customer_id,
  e1.customer_name
HAVING 
   COUNT(DISTINCT e1.order_id) >= 3 AND 
   NOT EXISTS 
   ( 
     SELECT 1
	 FROM ecommerce_clean e2
     WHERE e1.customer_id = e2.customer_id AND 
     e2.profit < 0
	) AND 
    COUNT(DISTINCT e1.category) >= 2
ORDER BY Total_Sales DESC;
    
-- Business problem (customers have at least 3 orders, total sales > overall avg customer sales and never purchased a product with negative profit

SELECT 
  e1.customer_id,
  e1.customer_name,
  COUNT(DISTINCT order_id) AS Total_Orders,
  ROUND(SUM(e1.sales),2) AS Total_Sales
FROM ecommerce_clean e1
GROUP BY 
  e1.customer_id,
  e1.customer_name
HAVING 
   COUNT(DISTINCT e1.order_id) >= 3 AND 
   NOT EXISTS
    (
     SELECT 1 
     FROM ecommerce_clean e2
     WHERE e1.customer_id = e2.customer_id AND 
     e2.profit < 0
     ) AND 
    SUM(e1.sales) > 
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
	)
ORDER BY Total_Sales DESC;
     
-- Busines problem(customers who have sales >avg customer sales,orders at least 3,not purchased anything from last 90 days of the dataset and no (-) profit.

SELECT 
  e1.customer_id,
  e1.customer_name,
  COUNT(DISTINCT e1.order_id) AS Total_Orders,
  ROUND(SUM(e1.sales),2) AS Total_Sales,
  MAX(e1.order_date) AS Last_Purchase_Date
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
                SUM(sales) AS Customer_Sales
			   FROM ecommerce_clean 
               GROUP BY customer_id
             )x
          ) 
	AND 
    COUNT(DISTINCT e1.order_id) >=3 
    AND 
   NOT EXISTS 
           (
            SELECT 1 
            FROM ecommerce_clean e2
            WHERE e1.customer_id = e2.customer_id AND 
            e2.profit < 0
            ) 
	AND 
    DATEDIFF((SELECT Max(order_date) FROM ecommerce_clean),
    MAX(e1.order_date)) > 90
ORDER BY Total_Sales DESC;

-- Customer Revenue and Retention Risk (high-value inactive customers whose last recorded purchase was more than 90 days before the dataset reference date)

SELECT 
  e1.customer_id,
  e1.customer_name,
  COUNT(DISTINCT e1.order_id) AS Total_Orders,
  ROUND(SUM(e1.sales),2) AS Total_Sales,
  ROUND(SUM(e1.sales) / NULLIF(COUNT(DISTINCT e1.order_id), 0), 2) AS Average_Order_Value,
  MAX(e1.order_date) AS Last_Purchase_Date
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
                SUM(sales) AS Customer_Sales
			   FROM ecommerce_clean 
               GROUP BY customer_id
             )x
          ) AND
  COUNT(DISTINCT e1.order_id) >=3   AND
  DATEDIFF((SELECT Max(order_date) FROM ecommerce_clean),
  MAX(e1.order_date)) > 90
    AND 
  NOT EXISTS 
           (
            SELECT 1 
            FROM ecommerce_clean e2
            WHERE e1.customer_id = e2.customer_id AND 
            e2.profit < 0
            )  AND
   SUM(e1.sales)/COUNT( DISTINCT e1.order_id) > 
		   (
            SELECT 
              SUM(sales)/COUNT(DISTINCT order_id)
			FROM ecommerce_clean
            )
ORDER BY Total_Sales DESC;
											
-- Customer whose total sales above overall average customer sales,at least 5 orders,purchased from at least 3 
-- categories,purchased within last 60 days of dataset never had a negative profit order

SELECT 
  e1.customer_id,
  e1.customer_name,
  ROUND(SUM(e1.sales),2) AS Total_Sales,
  COUNT(DISTINCT e1.order_id) AS Total_Orders,
  COUNT(DISTINCT e1.category) AS Category_Count,
  MAX(e1.order_date) AS Last_Purchase_Date
FROM ecommerce_clean e1 
GROUP BY 
  e1.customer_id,
  e1.customer_name
HAVING
   SUM(e1.sales) > 
	 (
      SELECT 
          AVG(Customer_Sales)
	  FROM
	   (
        SELECT 
          customer_id,
          SUM(sales) AS Customer_Sales
		FROM ecommerce_clean
        GROUP BY customer_id
        ) x
	  )  AND 
	COUNT(DISTINCT e1.order_id) >= 5 AND 
    COUNT(DISTINCT e1.category) >=3 AND 
    DATEDIFF(
             (
              SELECT MAX(order_date)
              FROM ecommerce_clean
              ), MAX(e1.order_date)
			)  <= 60 AND 
	NOT EXISTS 
            (
             SELECT 1
             FROM ecommerce_clean e2
             WHERE e1.customer_id = e2.customer_id AND 
             e2.profit < 0
             )
ORDER BY Total_Sales DESC;
