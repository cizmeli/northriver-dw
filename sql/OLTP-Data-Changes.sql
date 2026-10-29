-- New customer
INSERT INTO northriver_oltp.customers
  (customer_id, first_name, last_name, email, region, segment, updated_at)
VALUES
  (1019, 'David', 'Osei', 'd.osei@gh.net', 'West', 'Gold', '2024-05-01');

-- Elena moves region: North → South (OLTP system updated her record)
UPDATE northriver_oltp.customers
SET region = 'South',
    updated_at = '2024-05-10'
WHERE customer_id = 1005;

-- New orders
INSERT INTO northriver_oltp.orders
  (order_id, customer_id, order_date, channel, updated_at)
VALUES
  (2030, 1019, '2024-05-05', 'Online', '2024-05-05'),  -- new customer's first order
  (2031, 1005, '2024-05-10', 'Retail', '2024-05-10'),  -- Elena's first order after moving
  (2032, 1005, '2023-03-10', 'Online', '2024-05-12');  -- late-arriving order for Elena, 14 months late!

-- Order items
INSERT INTO northriver_oltp.order_items
  (order_item_id, order_id, product_id, quantity, unit_price, updated_at)
VALUES
  (3033, 2030, 102, 1, 189.00, '2024-05-05'),
  (3034, 2031, 101, 1, 120.00, '2024-05-10'),
  (3035, 2032, 109, 2,  95.00, '2024-05-12');

SELECT customer_id, first_name, last_name, region FROM northriver_oltp.customers
WHERE customer_id IN (1005, 1019);
-- Elena should now show region = 'South'; David Osei should appear

SELECT COUNT(*) FROM northriver_oltp.orders;       -- 32
SELECT COUNT(*) FROM northriver_oltp.order_items;  -- 35

SELECT customer_sk, first_name, last_name, region, effective_from, effective_to, is_current
FROM northriver_warehouse.dim_customer
WHERE customer_id = 1005
ORDER BY effective_from;

SELECT COUNT(*) FROM northriver_warehouse.fact_orders;
-- Expected: 35 (was 32 — three new order items added)

SELECT COUNT(*) FROM northriver_warehouse.dim_customer;
-- Expected: 20 (was 18 — Elena now has 2 rows, David Osei is new)

SELECT
  fo.order_id,
  dd.full_date AS order_date,
  dc.first_name,
  dc.last_name,
  dc.region,
  dc.effective_from,
  dc.effective_to,
  dc.is_current
FROM northriver_warehouse.fact_orders fo
JOIN northriver_warehouse.dim_customer dc
  ON fo.customer_sk = dc.customer_sk
JOIN northriver_warehouse.dim_date dd
  ON fo.date_sk = dd.date_sk
WHERE fo.order_id = 2032;