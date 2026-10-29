-- 03_extract
-- First step of the NorthRiver nightly pipeline (extract -> transform -> load).
-- Extract: copies all four NorthRiver OLTP source tables into the northriver_staging
-- schema, renaming them to the stg_* convention:
--   northriver_oltp.customers    -> northriver_staging.stg_customers
--   northriver_oltp.products     -> northriver_staging.stg_products
--   northriver_oltp.orders       -> northriver_staging.stg_orders
--   northriver_oltp.order_items  -> northriver_staging.stg_order_items
-- Each table is rebuilt with CREATE OR REPLACE, so staging is fully refreshed on
-- every run. TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported') is set
-- on each table so column DEFAULTs remain usable downstream.
-- The final statement returns a row-count summary per staging table so you can
-- quickly validate that the extract loaded the expected data.
-- Run first in the pipeline sequence, before 04_transform and 05_load.

CREATE SCHEMA IF NOT EXISTS northriver_staging
  COMMENT 'NorthRiver source data — simulates the Staging database in this training environment';

CREATE OR REPLACE TABLE northriver_staging.stg_customers
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported') AS  
SELECT * FROM northriver_oltp.customers;
CREATE OR REPLACE TABLE northriver_staging.stg_products
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported') AS   
SELECT * FROM northriver_oltp.products;
CREATE OR REPLACE TABLE northriver_staging.stg_orders
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported') AS     
SELECT * FROM northriver_oltp.orders;
CREATE OR REPLACE TABLE northriver_staging.stg_order_items
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported') AS
SELECT * FROM northriver_oltp.order_items;

SELECT 'stg_customers'   AS tbl, COUNT(*) AS rows FROM northriver_staging.stg_customers   UNION ALL
SELECT 'stg_products',           COUNT(*)         FROM northriver_staging.stg_products    UNION ALL
SELECT 'stg_orders',             COUNT(*)         FROM northriver_staging.stg_orders      UNION ALL
SELECT 'stg_order_items',        COUNT(*)         FROM northriver_staging.stg_order_items
ORDER BY tbl;