-- ============================================================
-- e-commerce sales & customer analytics
-- 01 - Data Cleaning
-- Purpose: profile raw data and create ecommerce_clean for analysis
-- Database: MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS `e-commerce sales & customer analytics`;
USE `e-commerce sales & customer analytics`;

-- Run this script after importing the source CSV into the raw table: ecommerce.
-- Keep ecommerce as the untouched raw/staging copy.
-- If you need to rebuild the clean table, this statement replaces the previous clean copy.
DROP TABLE IF EXISTS ecommerce_clean;
CREATE TABLE ecommerce_clean AS
SELECT * FROM ecommerce;

-- ============================================================
-- 1. RAW DATA PROFILE
-- ============================================================

SELECT COUNT(*) AS raw_total_rows
FROM ecommerce;

SELECT COUNT(*) AS raw_total_columns
FROM information_schema.columns
WHERE table_schema = 'e-commerce sales & customer analytics'
  AND table_name = 'ecommerce';

DESCRIBE ecommerce;

SELECT
    COUNT(DISTINCT NULLIF(TRIM(customer_id), '')) AS unique_customer_ids,
    COUNT(DISTINCT NULLIF(TRIM(product_id), '')) AS unique_product_ids
FROM ecommerce;

SELECT
    SUM(order_id IS NULL) AS order_id_nulls,
    SUM(order_date IS NULL) AS order_date_nulls,
    SUM(customer_id IS NULL) AS customer_id_nulls,
    SUM(customer_name IS NULL) AS customer_name_nulls,
    SUM(product_id IS NULL) AS product_id_nulls,
    SUM(product_name IS NULL) AS product_name_nulls,
    SUM(category IS NULL) AS category_nulls,
    SUM(sub_category IS NULL) AS sub_category_nulls,
    SUM(region IS NULL) AS region_nulls,
    SUM(state IS NULL) AS state_nulls,
    SUM(quantity IS NULL) AS quantity_nulls,
    SUM(sales IS NULL) AS sales_nulls,
    SUM(discount IS NULL) AS discount_nulls,
    SUM(profit IS NULL) AS profit_nulls,
    SUM(ship_mode IS NULL) AS ship_mode_nulls
FROM ecommerce;

SELECT
    SUM(TRIM(COALESCE(order_id, '')) = '') AS order_id_blanks,
    SUM(TRIM(COALESCE(order_date, '')) = '') AS order_date_blanks,
    SUM(TRIM(COALESCE(customer_id, '')) = '') AS customer_id_blanks,
    SUM(TRIM(COALESCE(customer_name, '')) = '') AS customer_name_blanks,
    SUM(TRIM(COALESCE(product_id, '')) = '') AS product_id_blanks,
    SUM(TRIM(COALESCE(product_name, '')) = '') AS product_name_blanks,
    SUM(TRIM(COALESCE(category, '')) = '') AS category_blanks,
    SUM(TRIM(COALESCE(sub_category, '')) = '') AS sub_category_blanks,
    SUM(TRIM(COALESCE(region, '')) = '') AS region_blanks,
    SUM(TRIM(COALESCE(state, '')) = '') AS state_blanks,
    SUM(TRIM(COALESCE(quantity, '')) = '') AS quantity_blanks,
    SUM(TRIM(COALESCE(sales, '')) = '') AS sales_blanks,
    SUM(TRIM(COALESCE(discount, '')) = '') AS discount_blanks,
    SUM(TRIM(COALESCE(profit, '')) = '') AS profit_blanks,
    SUM(TRIM(COALESCE(ship_mode, '')) = '') AS ship_mode_blanks
FROM ecommerce;

-- Exact duplicate rows: inspect before deleting anything.
SELECT
    order_id, order_date, customer_id, customer_name, product_id, product_name,
    category, sub_category, region, state, quantity, sales, discount, profit, ship_mode,
    COUNT(*) AS duplicate_count
FROM ecommerce
GROUP BY
    order_id, order_date, customer_id, customer_name, product_id, product_name,
    category, sub_category, region, state, quantity, sales, discount, profit, ship_mode
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Inspect order IDs with multiple rows; these may be valid multi-product orders.
SELECT order_id, COUNT(*) AS row_count
FROM ecommerce
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

-- ============================================================
-- 2. NORMALIZE TEXT AND HANDLE DOCUMENTED BLANKS
-- ============================================================

UPDATE ecommerce_clean
SET
    order_id = NULLIF(TRIM(order_id), ''),
    order_date = NULLIF(TRIM(order_date), ''),
    customer_id = NULLIF(TRIM(customer_id), ''),
    customer_name = NULLIF(TRIM(customer_name), ''),
    product_id = NULLIF(TRIM(product_id), ''),
    product_name = NULLIF(TRIM(product_name), ''),
    category = CASE LOWER(TRIM(category))
        WHEN 'home' THEN 'Home'
        WHEN 'fashion' THEN 'Fashion'
        WHEN 'electronics' THEN 'Electronics'
        ELSE NULLIF(TRIM(category), '')
    END,
    sub_category = CASE LOWER(TRIM(sub_category))
        WHEN 'decor' THEN 'Decor'
        WHEN 'men' THEN 'Men'
        ELSE NULLIF(TRIM(sub_category), '')
    END,
    region = CASE LOWER(TRIM(region))
        WHEN 'west' THEN 'West'
        WHEN 'south' THEN 'South'
        ELSE NULLIF(TRIM(region), '')
    END,
    state = CASE LOWER(TRIM(state))
        WHEN 'karnataka' THEN 'Karnataka'
        WHEN 'maharashtra' THEN 'Maharashtra'
        WHEN 'delhi' THEN 'Delhi'
        WHEN 'odisha' THEN 'Odisha'
        ELSE NULLIF(TRIM(state), '')
    END,
    ship_mode = CASE LOWER(TRIM(ship_mode))
        WHEN 'standard' THEN 'Standard'
        ELSE NULLIF(TRIM(ship_mode), '')
    END;

-- Documented business treatment: unknown state/customer name and blank discount.
-- Blank discount is treated as 0 for this project; this is a business assumption.
UPDATE ecommerce_clean
SET state = 'Unknown'
WHERE state IS NULL OR TRIM(state) = '';

UPDATE ecommerce_clean
SET customer_name = 'Unknown'
WHERE customer_name IS NULL OR TRIM(customer_name) = '';

UPDATE ecommerce_clean
SET discount = '0'
WHERE discount IS NULL OR TRIM(discount) = '';

-- ============================================================
-- 3. VALIDATE CONVERSION INPUTS BEFORE ALTERING DATA TYPES
-- ============================================================

-- Expected date format is DD-MM-YYYY. Any rows returned here need review.
SELECT order_id, order_date
FROM ecommerce_clean
WHERE NULLIF(TRIM(order_date), '') IS NOT NULL
  AND STR_TO_DATE(TRIM(order_date), '%d-%m-%Y') IS NULL;

-- Numeric text checks. Review returned rows before proceeding to type conversion.
SELECT order_id, quantity
FROM ecommerce_clean
WHERE NULLIF(TRIM(quantity), '') IS NOT NULL
  AND TRIM(quantity) NOT REGEXP '^[+-]?[0-9]+$';

SELECT order_id, sales
FROM ecommerce_clean
WHERE NULLIF(TRIM(sales), '') IS NOT NULL
  AND TRIM(sales) NOT REGEXP '^[+-]?[0-9]+([.][0-9]+)?$';

SELECT order_id, discount
FROM ecommerce_clean
WHERE NULLIF(TRIM(discount), '') IS NOT NULL
  AND TRIM(discount) NOT REGEXP '^[+-]?[0-9]+([.][0-9]+)?$';

SELECT order_id, profit
FROM ecommerce_clean
WHERE NULLIF(TRIM(profit), '') IS NOT NULL
  AND TRIM(profit) NOT REGEXP '^[+-]?[0-9]+([.][0-9]+)?$';

-- If any diagnostic query above returns rows, resolve those values before conversion.
-- This project retains rows with negative sales/profit for later business analysis.

-- ============================================================
-- 4. CONVERT ORDER DATE
-- ============================================================

ALTER TABLE ecommerce_clean
ADD COLUMN order_date_new DATE;

UPDATE ecommerce_clean
SET order_date_new = STR_TO_DATE(TRIM(order_date), '%d-%m-%Y')
WHERE NULLIF(TRIM(order_date), '') IS NOT NULL;

-- Confirm conversion failures before replacing the source text column.
SELECT order_id, order_date
FROM ecommerce_clean
WHERE NULLIF(TRIM(order_date), '') IS NOT NULL
  AND order_date_new IS NULL;

-- After confirming there are no unresolved invalid nonblank dates, replace the column.
ALTER TABLE ecommerce_clean
DROP COLUMN order_date;

ALTER TABLE ecommerce_clean
CHANGE COLUMN order_date_new order_date DATE;

-- ============================================================
-- 5. CONVERT NUMERIC COLUMNS
-- ============================================================
-- Blank quantity/sales/profit values are kept as NULL; decide their treatment
-- based on business rules. MySQL numeric conversion should only proceed after
-- the diagnostic queries above have been reviewed and invalid strings resolved.

-- Convert blank numeric text to NULL so conversion does not silently turn it into 0.
UPDATE ecommerce_clean
SET quantity = NULL
WHERE TRIM(COALESCE(quantity, '')) = '';

UPDATE ecommerce_clean
SET sales = NULL
WHERE TRIM(COALESCE(sales, '')) = '';

UPDATE ecommerce_clean
SET profit = NULL
WHERE TRIM(COALESCE(profit, '')) = '';

ALTER TABLE ecommerce_clean
    MODIFY COLUMN quantity INT,
    MODIFY COLUMN sales DECIMAL(12,2),
    MODIFY COLUMN discount DECIMAL(6,4),
    MODIFY COLUMN profit DECIMAL(12,2);

-- Keep text columns wide enough to reduce risk of truncation.
ALTER TABLE ecommerce_clean
    MODIFY COLUMN order_id VARCHAR(50),
    MODIFY COLUMN customer_id VARCHAR(50),
    MODIFY COLUMN customer_name VARCHAR(100),
    MODIFY COLUMN product_id VARCHAR(50),
    MODIFY COLUMN product_name VARCHAR(255),
    MODIFY COLUMN category VARCHAR(50),
    MODIFY COLUMN sub_category VARCHAR(100),
    MODIFY COLUMN region VARCHAR(50),
    MODIFY COLUMN state VARCHAR(100),
    MODIFY COLUMN ship_mode VARCHAR(50);

-- ============================================================
-- 6. FINAL SNAPSHOT
-- ============================================================

SELECT COUNT(*) AS raw_rows FROM ecommerce;
SELECT COUNT(*) AS clean_rows FROM ecommerce_clean;
DESCRIBE ecommerce_clean;

SELECT
    MIN(order_date) AS min_order_date,
    MAX(order_date) AS max_order_date,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS unique_products
FROM ecommerce_clean;
