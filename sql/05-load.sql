-- 05_load
-- Final step of the NorthRiver nightly pipeline (extract -> transform -> load).
-- Loads the northriver_warehouse star schema from northriver_staging (xform_* tables):
--   dim_customer - SCD Type 2 on region & segment: CHANGED rows close the current
--                  record (effective_to = yesterday, is_current = FALSE) and insert a
--                  new version effective today; NEW rows insert directly.
--   dim_product  - SCD Type 2 on category, same close-then-insert pattern.
--   dim_channel  - stable lookup, inserts NEW channel names only (no SCD).
--   dim_date     - static 2020-2030 calendar, inserts missing date_sk rows (no SCD).
--   fact_orders  - idempotent insert-only MERGE keyed on order_item_id; customer_sk and
--                  product_sk are resolved with point-in-time joins on order_date,
--                  channel_sk via direct channel_name lookup, and date_sk via direct
--                  full_date lookup. revenue is computed by the table's generated column.
-- Each load is followed by a verification SELECT; the final counts validate that
-- fact_orders matches the transform output (32 rows and the Sprint 2 revenue total).
-- Source: northriver_staging (xform_* tables) | Target: northriver_warehouse
-- Run after: 04_transform

-- ============================================================
-- Load dim_customer (SCD Type 2 on region & segment)
-- ============================================================

/*UPDATE workspace.northriver_warehouse.dim_customer
SET effective_from = DATE '1900-01-01'
WHERE is_current = TRUE;

UPDATE workspace.northriver_warehouse.dim_product
SET effective_from = DATE '1900-01-01'
WHERE is_current = TRUE;*/

MERGE INTO workspace.northriver_warehouse.dim_customer AS t
USING (
  -- CHANGED rows: close out the existing current record
  SELECT customer_id, first_name, last_name, email, region, segment, 'CLOSE' AS action
  FROM workspace.northriver_staging.xform_dim_customer
  WHERE change_type = 'CHANGED'

  UNION ALL

  -- NEW + CHANGED rows: insert the new version
  SELECT customer_id, first_name, last_name, email, region, segment, 'INSERT' AS action
  FROM workspace.northriver_staging.xform_dim_customer
  WHERE change_type IN ('NEW', 'CHANGED')
) AS s
ON t.customer_id = s.customer_id
   AND t.is_current = TRUE
   AND s.action = 'CLOSE'
WHEN MATCHED THEN
  UPDATE SET
    t.effective_to = current_date() - INTERVAL 1 DAY,
    t.is_current   = FALSE
WHEN NOT MATCHED AND s.action = 'INSERT' THEN
  INSERT (customer_id, first_name, last_name, email, region, segment, effective_from, effective_to, is_current)
  VALUES (s.customer_id, s.first_name, s.last_name, s.email, s.region, s.segment, current_date(), NULL, TRUE);

-- Verify SCD Type 2 history
SELECT customer_id, first_name, region, segment, effective_from, effective_to, is_current
FROM workspace.northriver_warehouse.dim_customer
ORDER BY customer_id, effective_from;

-- ============================================================
-- Load dim_product (SCD Type 2 on category)
-- ============================================================

MERGE INTO workspace.northriver_warehouse.dim_product AS t
USING (
  -- CHANGED rows: close out the existing current record
  SELECT product_id, product_name, brand, category, subcategory, unit_cost, 'CLOSE' AS action
  FROM workspace.northriver_staging.xform_dim_product
  WHERE change_type = 'CHANGED'

  UNION ALL

  -- NEW + CHANGED rows: insert the new version
  SELECT product_id, product_name, brand, category, subcategory, unit_cost, 'INSERT' AS action
  FROM workspace.northriver_staging.xform_dim_product
  WHERE change_type IN ('NEW', 'CHANGED')
) AS s
ON t.product_id = s.product_id
   AND t.is_current = TRUE
   AND s.action = 'CLOSE'
WHEN MATCHED THEN
  UPDATE SET
    t.effective_to = current_date() - INTERVAL 1 DAY,
    t.is_current   = FALSE
WHEN NOT MATCHED AND s.action = 'INSERT' THEN
  INSERT (product_id, product_name, brand, category, subcategory, unit_cost, effective_from, effective_to, is_current)
  VALUES (s.product_id, s.product_name, s.brand, s.category, s.subcategory, s.unit_cost, current_date(), NULL, TRUE);

-- Verify SCD Type 2 history
SELECT product_id, product_name, brand, category, effective_from, effective_to, is_current
FROM workspace.northriver_warehouse.dim_product
ORDER BY product_id, effective_from;

-- ============================================================
-- Load dim_channel (stable lookup — no SCD)
-- ============================================================

MERGE INTO workspace.northriver_warehouse.dim_channel AS t
USING (
  SELECT channel_name
  FROM workspace.northriver_staging.xform_dim_channel
  WHERE change_type = 'NEW'
) AS s
ON t.channel_name = s.channel_name
WHEN NOT MATCHED THEN
  INSERT (channel_name)
  VALUES (s.channel_name);

-- Verify channels
SELECT channel_sk, channel_name
FROM workspace.northriver_warehouse.dim_channel
ORDER BY channel_sk;

-- ============================================================
-- Load dim_date (static calendar — no SCD)
-- ============================================================

MERGE INTO workspace.northriver_warehouse.dim_date AS t
USING (
  SELECT date_sk, full_date, year, quarter, month, day_of_week
  FROM workspace.northriver_staging.xform_dim_date
) AS s
ON t.date_sk = s.date_sk
WHEN NOT MATCHED THEN
  INSERT (date_sk, full_date, year, quarter, month, day_of_week)
  VALUES (s.date_sk, s.full_date, s.year, s.quarter, s.month, s.day_of_week);

-- Verify date dimension
SELECT COUNT(*) AS row_count, MIN(full_date) AS min_date, MAX(full_date) AS max_date
FROM workspace.northriver_warehouse.dim_date;

-- ============================================================
-- Load fact_orders (idempotent insert on order_item_id)
-- ============================================================

--TRUNCATE TABLE workspace.northriver_warehouse.fact_orders ;

MERGE INTO workspace.northriver_warehouse.fact_orders AS t
USING (
  SELECT
    f.order_id,
    CAST(f.order_item_id AS BIGINT) AS order_item_id,
    dc.customer_sk,
    dp.product_sk,
    dch.channel_sk,
    dd.date_sk,
    f.quantity,
    f.unit_price
  FROM workspace.northriver_staging.xform_fact_orders AS f
  -- Point-in-time join: customer_sk
  LEFT JOIN workspace.northriver_warehouse.dim_customer AS dc
    ON dc.customer_id = f.customer_id
   AND f.order_date BETWEEN dc.effective_from AND COALESCE(dc.effective_to, DATE '9999-12-31')
  -- Point-in-time join: product_sk
  LEFT JOIN workspace.northriver_warehouse.dim_product AS dp
    ON dp.product_id = f.product_id
   AND f.order_date BETWEEN dp.effective_from AND COALESCE(dp.effective_to, DATE '9999-12-31')
  -- Direct lookup: channel_sk (no date condition — not Type 2)
  LEFT JOIN workspace.northriver_warehouse.dim_channel AS dch
    ON dch.channel_name = f.channel
  -- Direct lookup: date_sk
  LEFT JOIN workspace.northriver_warehouse.dim_date AS dd
    ON dd.full_date = f.order_date
) AS s
ON t.order_item_id = s.order_item_id
WHEN NOT MATCHED THEN
  INSERT (order_id, order_item_id, customer_sk, product_sk, channel_sk, date_sk, quantity, unit_price)
  VALUES (s.order_id, s.order_item_id, s.customer_sk, s.product_sk, s.channel_sk, s.date_sk, s.quantity, s.unit_price);

-- Verify fact table (revenue is auto-computed by generated column)
SELECT order_id, order_item_id, customer_sk, product_sk, channel_sk, date_sk, quantity, unit_price, revenue
FROM workspace.northriver_warehouse.fact_orders
ORDER BY order_item_id;

SELECT COUNT(*)     FROM northriver_warehouse.fact_orders;  -- 32
SELECT SUM(revenue) FROM northriver_warehouse.fact_orders;  -- should match Sprint 2 total