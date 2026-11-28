/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema).

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS 
SELECT 
      ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- Surrogate key
      ci.cst_id                              AS customer_id,
      ci.cst_key                             AS customer_num,
      ci.cst_firstname                       AS first_name,
      ci.cst_lastname                        AS last_name,
      -- Standardize gender: prioritize CRM data, fallback to normalized ERP data
      CASE 
          WHEN ci.cst_gndr IN ('Male', 'Female') THEN ci.cst_gndr
          WHEN ec.gen IN ('FEMALE', 'MALE') THEN SUBSTRING(ec.gen, 1, 1) + LOWER(SUBSTRING(ec.gen, 2, LEN(ec.gen)))
          ELSE 'n/a' 
      END                                    AS gender,
      loc.CNTRY                              AS country,
      ec.bdate                               AS birthdate,
      ci.cst_marital_status                  AS marital_status,
      ci.cst_create_date                     AS create_date 
FROM silver.crm_cust_info AS ci 
LEFT JOIN silver.erp_cust_az12 AS ec
    ON ci.cst_key = ec.cid 
LEFT JOIN silver.erp_loc_a101 AS loc
    ON ci.cst_key = loc.CID;
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS 
SELECT 
      ROW_NUMBER() OVER (ORDER BY pr.prd_start_dt, pr.prd_key) AS product_key, -- Surrogate key
      pr.prd_id                                                AS product_id,
      pr.prd_key                                               AS product_num,
      pr.cat_id                                                AS category_id,
      pr.prd_nm                                                AS product_name,
      ca.CAT                                                   AS category,
      ca.SUBCAT                                                AS sub_category,
      pr.prd_line                                              AS product_line,
      pr.prd_cost                                              AS product_cost,
      ca.MAINTENANCE                                           AS maintenance,
      pr.prd_start_dt                                          AS product_start_date 
FROM silver.crm_prd_info AS pr
LEFT JOIN silver.erp_px_cat_g1v2 AS ca
    ON pr.cat_id = ca.ID
WHERE pr.prd_end_dt IS NULL; -- Filter out historical/inactive product versions
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,  -- Foreign key to gold.dim_products
    cu.customer_key AS customer_key, -- Foreign key to gold.dim_customers
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_num
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
GO
