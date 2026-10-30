# E-Commerce Sales & Customer Analytics

## Project Overview

This project uses MySQL to analyze e-commerce sales, customer behaviour, product performance, regional performance, discounts, and business trends.

The project contains 13 SQL scripts covering data cleaning, data validation, business KPIs, customer analytics, and advanced SQL analysis.

## Project Objectives

- Clean and validate raw e-commerce data.
- Analyze sales and profitability.
- Evaluate product and customer performance.
- Analyze regional and discount performance.
- Perform RFM, cohort, and ABC analysis.
- Investigate business questions using SQL.

## Project Structure

```text
E-Commerce-SQL-Analytics/
├── data/
│   └── ecommerce.csv
├── screenshots/
│   ├── executive_kpis.png
│   ├── Monthly_Sales_Profit_Trend.png
│   ├── Category_Performance.png
│   ├── Customer_Sales_and_Cumulative_Contribution.png
│   ├── High_Value_Inactive_Customers.png
│   ├── Month_1_3_6_12_Retention_by_Cohort.png
│   ├── One_Time_VS_Repeat_Customers.png
│   └── Region_Wise_Performance.png
├── 01_data_cleaning.sql
├── 02_data_validation.sql
├── 03_executive_kpis.sql
├── 04_sales_analysis.sql
├── 05_product_analysis.sql
├── 06_customer_analysis.sql
├── 07_regional_analysis.sql
├── 08_discount_analysis.sql
├── 09_rfm_analysis.sql
├── 10_cohort_analysis.sql
├── 11_abc_analysis.sql
├── 12_advanced_sql_analysis.sql
├── 13_business_investigation.sql
└── README.md
```

## SQL Topics Covered

- Data cleaning and validation
- Executive KPIs
- Sales analysis and trends
- Product analysis
- Customer analysis
- Regional analysis
- Discount analysis
- RFM customer segmentation
- Cohort analysis
- ABC analysis
- Advanced SQL analysis
- Business investigation

## Project Screenshots

### 1. Executive KPIs

![Executive KPIs](screenshots/executive_kpis.png)

### 2. Monthly Sales and Profit Trend

![Monthly Sales Profit Trend](screenshots/Monthly_Sales_Profit_Trend.png)

### 3. Category Performance

![Category Performance](screenshots/Category_Performance.png)

### 4. Customer Sales and Cumulative Contribution

![Customer Sales and Cumulative Contribution](screenshots/Customer_Sales_and_Cumulative_Contribution.png)

### 5. High Value Inactive Customers

![High Value Inactive Customers](screenshots/High_Value_Inactive_Customers.png)

### 6. Customer Retention by Cohort

![Customer Retention by Cohort](screenshots/Month_1_3_6_12_Retention_by_Cohort.png)

### 7. One-Time vs Repeat Customers

![One-Time vs Repeat Customers](screenshots/One_Time_VS_Repeat_Customers.png)

### 8. Regional Performance

![Regional Performance](screenshots/Region_Wise_Performance.png)

## Database Setup

1. Install MySQL 8.0 or a compatible version and open MySQL Workbench.
2. Create or use the database:

   `e-commerce sales & customer analytics`

3. Import `data/ecommerce.csv` into a raw table named `ecommerce` using MySQL Table Data Import Wizard.
4. Open the SQL scripts in MySQL Workbench.
5. Run the scripts in a suitable order, starting with data cleaning and validation.
6. Review the outputs and business findings.

The tables used during development are:

- `ecommerce`
- `ecommerce_clean`

Review scripts before execution, especially statements that create, drop, or modify tables.

## Data Quality Note

During validation, the source table showed inconsistent product-to-category and product-to-subcategory mappings. Each of the 350 product IDs appeared with multiple categories and multiple subcategories, while each product ID was associated with only one product name.

No verified product master table was available to confirm the intended mapping. Therefore, category-wise product rankings should be treated cautiously. Product-category mappings have not been manually invented or changed to make the results appear consistent.

This limitation was observed in both the source and cleaned datasets. The checks do not establish the original cause of the inconsistency.

## Important Notes

- SQL scripts were executed in MySQL Workbench during project development.
- Results depend on the dataset and database environment used.
- The CSV dataset included in this repository is the source used for this SQL project.
- Review SQL statements before running them against any database.

## Project Status

All 13 SQL scripts have been run by the project author, who reported that all queries execute successfully in the current environment. This confirms query execution in that environment; it does not independently verify every business interpretation or the quality of the source data.
The 13 SQL scripts have been run by the project author, and the author
reported that all queries execute successfully in the current
environment. This confirms query execution in that environment; it does
not independently verify every business interpretation or the quality of
the source data.
