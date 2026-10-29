-- 04_transform
-- Second step of the NorthRiver nightly pipeline (extract -> transform -> load).
-- Builds change-flagged dimension data and natural-keyed fact rows in northriver_staging,
-- ready for 05_load to merge into the warehouse:
--   xform_dim_customer - customers flagged NEW / CHANGED / UNCHANGED; CHANGED means the
--                        region or segment differs from the current warehouse row
--   xform_dim_product  - same flagging with CHANGED detected on category changes
--   xform_dim_channel  - distinct channel names from stg_orders flagged NEW / UNCHANGED
--   xform_dim_date     - static calendar 2020-2030 with date_sk as yyyyMMdd BIGINT
--   xform_fact_orders  - one row per order line item with natural keys only
--                        (order_id, order_item_id, order_date, customer_id,
--                        product_id, channel, quantity, unit_price); surrogate keys
--                        are resolved later in 05_load
-- Change detection compares against the current (is_current = TRUE) warehouse row.
-- The final statements return change-type counts per dimension plus a fact row count
-- (expected 32 rows) for quick validation of the transform output.
-- Source: northriver_staging | Target: northriver_staging (xform_* tables)
-- Run after: 03_extract
CREATE OR REPLACE TABLE northriver_staging.xform_dim_customer AS
SELECT
  s.customer_id,
  s.first_name,
  s.last_name,
  s.email,
  s.region,
  s.segment,
  CASE
    WHEN c.customer_id IS NULL THEN 'NEW'
    WHEN c.region <> s.region OR c.segment <> s.segment THEN 'CHANGED'
    ELSE 'UNCHANGED'
  END AS change_type
FROM northriver_staging.stg_customers s
LEFT JOIN northriver_warehouse.dim_customer c
  ON s.customer_id = c.customer_id AND c.is_current = TRUE;

CREATE OR REPLACE TABLE northriver_staging.xform_dim_product AS
SELECT
  s.product_id,
  s.product_name,
  s.brand,
  s.category,
  s.subcategory,
  s.unit_cost,
  CASE
    WHEN p.product_id IS NULL THEN 'NEW'
    WHEN p.category <> s.category THEN 'CHANGED'
    ELSE 'UNCHANGED'
  END AS change_type
FROM northriver_staging.stg_products s
LEFT JOIN northriver_warehouse.dim_product p
  ON s.product_id = p.product_id AND p.is_current = TRUE;

CREATE OR REPLACE TABLE northriver_staging.xform_dim_channel AS
SELECT
  s.channel_name,
  CASE
    WHEN c.channel_name IS NULL THEN 'NEW'
    ELSE 'UNCHANGED'
  END AS change_type
FROM (SELECT DISTINCT channel AS channel_name FROM northriver_staging.stg_orders) s
LEFT JOIN northriver_warehouse.dim_channel c
  ON s.channel_name = c.channel_name;



CREATE OR REPLACE TABLE northriver_staging.xform_dim_date AS
SELECT
  CAST(date_format(full_date, 'yyyyMMdd') AS BIGINT) AS date_sk,
  full_date,
  year(full_date)    AS year,
  quarter(full_date) AS quarter,
  month(full_date)   AS month,
  date_format(full_date, 'EEEE') AS day_of_week
FROM (
  SELECT explode(sequence(DATE '2020-01-01', DATE '2030-12-31', INTERVAL 1 DAY)) AS full_date
);

CREATE OR REPLACE TABLE northriver_staging.xform_fact_orders AS
SELECT
  oi.order_id,
  oi.order_item_id,
  o.order_date,
  o.customer_id,
  oi.product_id,
  o.channel,
  oi.quantity,
  oi.unit_price
FROM northriver_staging.stg_order_items oi
JOIN northriver_staging.stg_orders o
  ON oi.order_id = o.order_id;

SELECT change_type, COUNT(*) FROM northriver_staging.xform_dim_customer GROUP BY change_type;
SELECT change_type, COUNT(*) FROM northriver_staging.xform_dim_product  GROUP BY change_type;
SELECT change_type, COUNT(*) FROM northriver_staging.xform_dim_channel  GROUP BY change_type;
SELECT COUNT(*) FROM northriver_staging.xform_fact_orders; -- expected 32 rows