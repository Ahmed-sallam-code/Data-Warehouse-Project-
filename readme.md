# End-to-End SQL Data Warehouse Project

An end-to-end data engineering and analytics solution built in **SQL Server** using the **Medallion Architecture** (`Bronze`, `Silver`, `Gold`). This project consolidates raw CRM and ERP sales data into a clean, business-ready Star Schema designed for analytical reporting, BI workloads, and strategic decision-making.

---

## 📋 Table of Contents

1. [Project Overview & Business Requirements](#-project-overview--business-requirements)
2. [Data Architecture & Data Flow](#-data-architecture--data-flow)
3. [Source Integration Model](#-source-integration-model)
4. [Repository Structure](#-repository-structure)
5. [ETL Pipeline & Engineering Highlights](#-etl-pipeline--engineering-highlights)
6. [Naming Conventions](#-naming-conventions)
7. [Gold Layer Data Catalog (Star Schema)](#-gold-layer-data-catalog-star-schema)
8. [How to Run](#-how-to-run)

---

## 🎯 Project Overview & Business Requirements

### Objective
Build a modern data warehouse in **SQL Server** to consolidate sales data from multiple source systems, enabling downstream SQL-based analytics into:
- **Customer Behavior**
- **Product Performance**
- **Sales Trends**

### Project Specifications & Scope
- **Data Sources:** Ingest raw data from two source systems (**CRM** and **ERP**) provided as flat CSV files.
- **Data Quality:** Cleanse, standardize, and resolve data quality issues prior to analytical modeling.
- **Integration:** Combine both sources into a single, user-friendly Star Schema model optimized for analytical queries.
- **Scope:** Focus on the latest dataset only (full-refresh pattern; historical SCD tracking is out of scope).
- **Documentation:** Maintain clear architectural and data catalog documentation for both business stakeholders and analytics teams.

---

## 🏗️ Data Architecture & Data Flow

![Data Flow Diagram](docs/Data%20Flow.png)

The warehouse implements a three-tier **Medallion Architecture** to enforce a clean separation of concerns between raw ingestion, data cleansing, and business logic:

1. **Bronze Layer (Raw Ingestion):**
   - Stores raw data extracted from CRM and ERP source CSV files with zero transformations (`crm_cust_info`, `crm_prd_info`, `crm_sales_details`, `erp_cust_az12`, `erp_loc_a101`, `erp_px_cat_g1v2`).
   - Uses a `TRUNCATE` and `BULK INSERT` pattern to maintain an exact mirror of source files.
2. **Silver Layer (Cleansed & Standardized):**
   - Handles data cleansing, normalization, type casting, deduplication, and missing value imputation across all six source entities.
   - Adds system metadata columns (`dwh_create_date`) to track warehouse load timestamps.
3. **Gold Layer (Business-Ready Star Schema):**
   - Exposes business-aligned analytical views (`dim_customers`, `dim_products`, `fact_sales`) structured into Dimensions and Facts for fast querying and reporting.

---

## 🔗 Source Integration Model

![Integration Model Diagram](docs/Integration%20Model.png)

The diagram above illustrates how CRM and ERP entities relate and join together across systems to form the unified Gold layer dimensions and fact table:

- **Customer Integration:** `crm_cust_info` (`cst_id` / `cst_key`) joins with `erp_cust_az12` (`CID`) and `erp_loc_a101` (`CID`) to enrich customer profiles with birthdates, gender, and country attributes in `gold.dim_customers`.
- **Product Integration:** `crm_prd_info` (`prd_key`) joins with `erp_px_cat_g1v2` (`ID`) to attach product categories, subcategories, and maintenance flags in `gold.dim_products`.
- **Sales Transactions:** `crm_sales_details` (`sls_prd_key`, `sls_cst_id`) links to both dimension views via surrogate keys in `gold.fact_sales`.

---

## 📂 Repository Structure

```text
Data-Warehouse-Project-/
│
├── datasets/                   # Source CSV files (CRM & ERP extracts)
│   ├── source_crm/             # Customer info, product info, sales details
│   └── source_erp/             # Customer demographics, location, product categories
│
├── scripts/                    # T-SQL scripts organized by pipeline stage
│   ├── init_database.sql       # Database & schema initialization (bronze, silver, gold)
│   ├── bronze/                 # DDL & bronze.load_bronze stored procedure (BULK INSERT)
│   ├── silver/                 # DDL & silver.load_silver stored procedure (ETL transformations)
│   └── gold/                   # DDL views for Star Schema (Dimensions & Fact)
│
├── docs/                       # Architecture diagrams & modeling documentation
│   ├── Data Flow.png           # End-to-end Medallion data flow diagram
│   ├── Integration Model.png   # CRM & ERP entity relationship diagram
│   ├── data_catalog.md         # Metadata and column definitions for the Gold layer
│   ├── naming_conventions.md   # Standardized rules for schemas, tables, keys, and procs
│   └── requirements.md         # Business requirements and project scope
│
└── README.md
```

---

## ⚙️ ETL Pipeline & Engineering Highlights

Rather than relying on black-box GUI tools, the entire ETL pipeline is engineered from scratch in **T-SQL** with production-style observability and defensive error handling:

- **Idempotent Execution:** Database initialization and table loads safely reset or truncate target tables before loading, allowing repeatable full-refresh runs without duplicate records.
- **High-Precision Execution Logging:** Stored procedures (`bronze.load_bronze`, `silver.load_silver`) and Gold view deployments instrument step-by-step `PRINT` diagnostics alongside millisecond-level execution timers (`DATETIME2` / `SYSDATETIME()`) to measure latency per table and across the entire batch.
- **Structured Error Handling:** Wrapped in `TRY...CATCH` blocks that surface exact error messages, error numbers, and state details immediately upon failure.
- **Cross-System Data Integration:**
  - Resolves mismatched keys and formatting inconsistencies between CRM and ERP extracts.
  - Standardizes categorical attributes (e.g., gender, marital status, country codes) and handles malformed dates or null values.
  - Generates surrogate keys (`_key`) in the Gold layer to decouple analytical queries from source-system primary keys.

---

## 📐 Naming Conventions

All database objects adhere to strict `snake_case` naming rules in English, avoiding SQL reserved words:

| Layer / Object Type | Naming Pattern | Example | Description |
| :--- | :--- | :--- | :--- |
| **Bronze Tables** | `<sourcesystem>_<entity>` | `crm_cust_info` | Exact entity name prefixed with source (`crm` or `erp`). |
| **Silver Tables** | `<sourcesystem>_<entity>` | `crm_cust_info` | Mirrors Bronze table names after cleansing & standardization. |
| **Gold Dimensions** | `dim_<entity>` | `dim_customers` | Business-aligned dimension views. |
| **Gold Facts** | `fact_<entity>` | `fact_sales` | Business-aligned transactional fact views. |
| **Gold Reports** | `report_<entity>` | `report_sales_monthly` | Aggregated reporting views/tables. |
| **Surrogate Keys** | `<table_name>_key` | `customer_key` | Primary keys generated for dimension tables. |
| **Technical Columns** | `dwh_<column_name>` | `dwh_create_date` | System-generated warehouse metadata columns. |
| **Stored Procedures** | `load_<layer>` | `load_bronze`, `load_silver` | ETL batch loading procedures per layer. |

---

## 🌟 Gold Layer Data Catalog (Star Schema)

The presentation layer consists of three core views designed for BI and analytical reporting:

### 1. `gold.dim_customers`
*Stores customer details enriched with ERP demographic and geographic data.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `customer_key` | `INT` | Surrogate key uniquely identifying each customer record in the dimension table. |
| `customer_id` | `INT` | Unique numerical identifier assigned to each customer. |
| `customer_number` | `NVARCHAR(50)` | Alphanumeric identifier representing the customer for tracking and referencing. |
| `first_name` | `NVARCHAR(50)` | Customer's first name as recorded in the system. |
| `last_name` | `NVARCHAR(50)` | Customer's last name or family name. |
| `country` | `NVARCHAR(50)` | Country of residence for the customer (e.g., `'Australia'`). |
| `marital_status` | `NVARCHAR(50)` | Marital status of the customer (e.g., `'Married'`, `'Single'`). |
| `gender` | `NVARCHAR(50)` | Gender of the customer (e.g., `'Male'`, `'Female'`, `'n/a'`). |
| `birthdate` | `DATE` | Customer's date of birth formatted as `YYYY-MM-DD` (e.g., `1971-10-06`). |
| `create_date` | `DATE` | Date when the customer record was created in the system. |

### 2. `gold.dim_products`
*Provides information about active products, pricing, and ERP category hierarchies.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `product_key` | `INT` | Surrogate key uniquely identifying each product record in the dimension table. |
| `product_id` | `INT` | Unique identifier assigned to the product for internal tracking. |
| `product_number` | `NVARCHAR(50)` | Structured alphanumeric code used for product categorization and inventory. |
| `product_name` | `NVARCHAR(50)` | Descriptive name of the product including type, color, and size. |
| `category_id` | `NVARCHAR(50)` | Unique identifier linking the product to its high-level classification. |
| `category` | `NVARCHAR(50)` | Broader product classification (e.g., `'Bikes'`, `'Components'`). |
| `subcategory` | `NVARCHAR(50)` | Detailed classification within the category (e.g., product type). |
| `maintenance` | `NVARCHAR(50)` | Indicates whether the product requires maintenance (`'Yes'`, `'No'`). |
| `cost` | `INT` | Base cost or price of the product in whole monetary units. |
| `product_line` | `NVARCHAR(50)` | Specific product series (e.g., `'Road'`, `'Mountain'`). |
| `start_date` | `DATE` | Date when the product became available for sale or use. |

### 3. `gold.fact_sales`
*Stores granular transactional sales line items linked to customer and product dimensions.*

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `order_number` | `NVARCHAR(50)` | Unique alphanumeric identifier for each sales order (e.g., `'SO54496'`). |
| `product_key` | `INT` | Foreign surrogate key linking the order to `gold.dim_products`. |
| `customer_key` | `INT` | Foreign surrogate key linking the order to `gold.dim_customers`. |
| `order_date` | `DATE` | Date when the order was placed. |
| `shipping_date` | `DATE` | Date when the order was shipped to the customer. |
| `due_date` | `DATE` | Date when the order payment was due. |
| `sales_amount` | `INT` | Total monetary value of the line item in whole currency units (e.g., `25`). |
| `quantity` | `INT` | Number of units ordered for the line item (e.g., `1`). |
| `price` | `INT` | Unit price of the product for the line item in whole currency units (e.g., `25`). |

---

## 🚀 How to Run

1. **Initialize the Database & Schemas:**
   Execute `scripts/init_database.sql` in SQL Server Management Studio (SSMS) or Azure Data Studio to create the database and initialize the `bronze`, `silver`, and `gold` schemas.

2. **Create Tables & Load the Bronze Layer:**
   - Run the Bronze DDL script to create raw staging tables.
   - Update the local file paths inside `bronze.load_bronze` to point to your local `datasets/` directory, then execute:
     ```sql
     EXEC bronze.load_bronze;
     ```

3. **Transform & Load the Silver Layer:**
   - Run the Silver DDL script to create the cleansed tables.
   - Execute the transformation stored procedure:
     ```sql
     EXEC silver.load_silver;
     ```

4. **Deploy Gold Layer Views:**
   - Run the Gold DDL script to create `gold.dim_customers`, `gold.dim_products`, and `gold.fact_sales`.