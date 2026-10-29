-- ============================================================
-- e-commerce sales & customer analytics
-- 02 - Data Validation
-- Purpose: validate ecommerce_clean after 01_data_cleaning.sql
-- MySQL 8.0+
-- ============================================================

USE `e-commerce sales & customer analytics`;

-- 1. NULL checks
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
FROM ecommerce_clean;

-- 2. Blank checks for text columns only
SELECT
    SUM(TRIM(COALESCE(order_id, '')) = '') AS order_id_blanks,
    SUM(TRIM(COALESCE(customer_id, '')) = '') AS customer_id_blanks,
    SUM(TRIM(COALESCE(customer_name, '')) = '') AS customer_name_blanks,
    SUM(TRIM(COALESCE(product_id, '')) = '') AS product_id_blanks,
    SUM(TRIM(COALESCE(product_name, '')) = '') AS product_name_blanks,
    SUM(TRIM(COALESCE(category, '')) = '') AS category_blanks,
    SUM(TRIM(COALESCE(sub_category, '')) = '') AS sub_category_blanks,
    SUM(TRIM(COALESCE(region, '')) = '') AS region_blanks,
    SUM(TRIM(COALESCE(state, '')) = '') AS state_blanks,
    SUM(TRIM(COALESCE(ship_mode, '')) = '') AS ship_mode_blanks
FROM ecommerce_clean;

-- 3. Quantity checks
SELECT order_id, product_id, quantity
FROM ecommerce_clean
WHERE quantity <= 0;

-- 4. Negative/zero sales and negative profit are flagged for investigation,
-- not automatically deleted; these may represent returns or adjustments.
SELECT order_id, sales, profit
FROM ecommerce_clean
WHERE sales <= 0 OR profit < 0;

-- 5. Discount range check.
-- Confirm project convention: discount is stored as a fraction from 0 to 1.
SELECT order_id, discount
FROM ecommerce_clean
WHERE discount < 0 OR discount > 1;

-- 6. Category/sub-category/region/shipping-mode capitalization checks
SELECT DISTINCT category, sub_category, region, ship_mode
FROM ecommerce_clean
WHERE
    (category IS NOT NULL AND NOT REGEXP_LIKE(category, '^[A-Z][a-z]*([[:space:]][A-Z][a-z]*)*$', 'c'))
 OR (sub_category IS NOT NULL AND NOT REGEXP_LIKE(sub_category, '^[A-Z][a-z]*([[:space:]][A-Z][a-z]*)*$', 'c'))
 OR (region IS NOT NULL AND NOT REGEXP_LIKE(region, '^[A-Z][a-z]*([[:space:]][A-Z][a-z]*)*$', 'c'))
 OR (ship_mode IS NOT NULL AND NOT REGEXP_LIKE(ship_mode, '^[A-Z][a-z]*([[:space:]][A-Z][a-z]*)*$', 'c'));

-- 7. State capitalization checks
SELECT DISTINCT state
FROM ecommerce_clean
WHERE state IS NOT NULL
  AND NOT REGEXP_LIKE(state, '^[A-Z][a-z]*([[:space:]][A-Z][a-z]*)*$', 'c');

-- 8. Order date and datatype checks
SELECT
    MIN(order_date) AS min_order_date,
    MAX(order_date) AS max_order_date,
    SUM(order_date IS NULL) AS missing_order_dates
FROM ecommerce_clean;

DESCRIBE ecommerce_clean;

-- 9. Row-count comparison
SELECT 'raw' AS table_name, COUNT(*) AS row_count FROM ecommerce
UNION ALL
SELECT 'clean' AS table_name, COUNT(*) AS row_count FROM ecommerce_clean;
