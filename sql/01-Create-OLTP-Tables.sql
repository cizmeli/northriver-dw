CREATE SCHEMA IF NOT EXISTS northriver_oltp
  COMMENT 'NorthRiver source data — simulates the OLTP database in this training environment';


CREATE TABLE IF NOT EXISTS northriver_oltp.customers (
    customer_id   INT PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) UNIQUE,
    region        VARCHAR(50),
    segment       VARCHAR(50),
    updated_at    TIMESTAMP    NOT NULL DEFAULT now()
)
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported');

CREATE TABLE IF NOT EXISTS northriver_oltp.products (
    product_id    INT PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    brand         VARCHAR(50),
    category      VARCHAR(50),
    subcategory   VARCHAR(50),
    unit_cost     NUMERIC(10, 2),
    updated_at    TIMESTAMP    NOT NULL DEFAULT now()
)
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported');

CREATE TABLE IF NOT EXISTS northriver_oltp.orders (
    order_id      INT PRIMARY KEY,
    customer_id   INTEGER NOT NULL REFERENCES northriver_oltp.customers(customer_id),
    order_date    DATE    NOT NULL,
    channel       VARCHAR(50),
    updated_at    TIMESTAMP NOT NULL DEFAULT now()
)
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported');

CREATE TABLE IF NOT EXISTS northriver_oltp.order_items (
    order_item_id INT PRIMARY KEY,
    order_id      INTEGER        NOT NULL REFERENCES northriver_oltp.orders(order_id),
    product_id    INTEGER        NOT NULL REFERENCES northriver_oltp.products(product_id),
    quantity      INTEGER        NOT NULL,
    unit_price    NUMERIC(10, 2) NOT NULL,
    updated_at    TIMESTAMP      NOT NULL DEFAULT now()
)
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported');

INSERT INTO northriver_oltp.customers VALUES
(1001, 'Lena',   'Müller',    'lena.m@email.de',   'North', 'Gold',   TIMESTAMP '2022-01-15'),
(1002, 'James',  'Okafor',    'j.okafor@mail.com', 'South', 'Silver', TIMESTAMP '2022-02-03'),
(1003, 'Sofia',  'Andersson', 'sofia.a@post.se',   'East',  'Bronze', TIMESTAMP '2022-02-20'),
(1004, 'Carlos', 'Ramírez',   'c.ram@correo.mx',   'West',  'Gold',   TIMESTAMP '2022-03-08'),
(1005, 'Emma',   'Svensson',  'emma.s@post.se',    'North', 'Silver', TIMESTAMP '2022-03-22'),
(1006, 'Kwame',  'Asante',    'kwame.a@gha.net',   'East',  'Bronze', TIMESTAMP '2022-04-10'),
(1007, 'Anna',   'Kovác',     'anna.k@email.cz',   'South', 'Gold',   TIMESTAMP '2022-05-05'),
(1008, 'Raj',    'Patel',     'raj.p@in.net',      'West',  'Silver', TIMESTAMP '2022-05-19'),
(1009, 'Marie',  'Dubois',    'marie.d@fr.net',    'North', 'Bronze', TIMESTAMP '2022-06-14'),
(1010, 'Björn',  'Larsson',   'bjorn.l@se.net',    'East',  'Gold',   TIMESTAMP '2022-07-02'),
(1011, 'Yuki',   'Tanaka',    'y.tanaka@jp.net',   'West',  'Silver', TIMESTAMP '2022-07-28'),
(1012, 'Amara',  'Diallo',    'amara.d@sn.net',    'South', 'Bronze', TIMESTAMP '2022-08-15'),
(1013, 'Tom',    'Fischer',   'tom.f@de.net',      'North', 'Gold',   TIMESTAMP '2022-09-03'),
(1014, 'Priya',  'Sharma',    'priya.s@in.net',    'East',  'Silver', TIMESTAMP '2022-09-20'),
(1015, 'Lucas',  'Bernard',   'lucas.b@fr.net',    'West',  'Bronze', TIMESTAMP '2022-10-08'),
(1016, 'Ingrid', 'Holm',      'ingrid.h@no.net',   'North', 'Gold',   TIMESTAMP '2022-11-02'),
(1017, 'Chen',   'Wei',       'chen.w@cn.net',     'South', 'Silver', TIMESTAMP '2022-11-25'),
(1018, 'Maria',  'Santos',    'maria.s@br.net',    'East',  'Bronze', TIMESTAMP '2022-12-10');

INSERT INTO northriver_oltp.products (product_id, product_name, brand, category, subcategory, unit_cost) VALUES
(101, 'Trail Boot Pro',      'Nordwear',   'Footwear',    'Hiking',       48.00),
(102, 'Summit Jacket',       'Alpine Co',  'Outerwear',   'Insulated',    75.00),
(103, 'Trek Pole Set',       'TrailFlex',  'Equipment',   'Walking Aids', 22.00),
(104, 'Thermal Base Layer',  'Nordwear',   'Clothing',    'Base Layer',   18.00),
(105, 'River Sandal',        'Alpine Co',  'Footwear',    'Water',        30.00),
(106, 'Camp Lantern',        'TrailFlex',  'Equipment',   'Lighting',     12.00),
(107, 'Waterproof Trousers', 'Nordwear',   'Clothing',    'Outerwear',    35.00),
(108, 'Dry Bag 20L',         'TrailFlex',  'Equipment',   'Storage',      10.00),
(109, 'Alpine Fleece',       'Alpine Co',  'Outerwear',   'Fleece',       40.00),
(110, 'Trail Glove',         'Nordwear',   'Accessories', 'Gloves',        8.00),
(111, 'Headlamp Xtreme',     'TrailFlex',  'Equipment',   'Lighting',     15.00),
(112, 'Merino Sock Pack',    'Nordwear',   'Accessories', 'Socks',         6.00),
(113, 'Packable Daypack',    'TrailFlex',  'Equipment',   'Packs',        20.00),
(114, 'Sun Hat Wide Brim',   'Alpine Co',  'Accessories', 'Hats',          9.00);

INSERT INTO northriver_oltp.orders VALUES
(2001, 1001, '2023-01-10', 'Online',    TIMESTAMP '2023-01-10'),
(2002, 1005, '2023-01-22', 'Retail',    TIMESTAMP '2023-01-22'),
(2003, 1008, '2023-02-05', 'Online',    TIMESTAMP '2023-02-05'),
(2004, 1012, '2023-02-18', 'Wholesale', TIMESTAMP '2023-02-18'),
(2005, 1003, '2023-03-02', 'Retail',    TIMESTAMP '2023-03-02'),
(2006, 1007, '2023-03-15', 'Online',    TIMESTAMP '2023-03-15'),
(2007, 1010, '2023-04-01', 'Wholesale', TIMESTAMP '2023-04-01'),
(2008, 1002, '2023-04-20', 'Online',    TIMESTAMP '2023-04-20'),
(2009, 1015, '2023-05-08', 'Retail',    TIMESTAMP '2023-05-08'),
(2010, 1018, '2023-05-25', 'Online',    TIMESTAMP '2023-05-25'),
(2011, 1004, '2023-06-12', 'Wholesale', TIMESTAMP '2023-06-12'),
(2012, 1009, '2023-07-03', 'Retail',    TIMESTAMP '2023-07-03'),
(2013, 1013, '2023-07-19', 'Online',    TIMESTAMP '2023-07-19'),
(2014, 1006, '2023-08-05', 'Online',    TIMESTAMP '2023-08-05'),
(2015, 1016, '2023-08-22', 'Wholesale', TIMESTAMP '2023-08-22'),
(2016, 1011, '2023-09-08', 'Retail',    TIMESTAMP '2023-09-08'),
(2017, 1014, '2023-09-25', 'Online',    TIMESTAMP '2023-09-25'),
(2018, 1017, '2023-10-11', 'Wholesale', TIMESTAMP '2023-10-11'),
(2019, 1001, '2023-10-28', 'Online',    TIMESTAMP '2023-10-28'),
(2020, 1005, '2023-11-14', 'Retail',    TIMESTAMP '2023-11-14'),
(2021, 1003, '2023-11-30', 'Online',    TIMESTAMP '2023-11-30'),
(2022, 1008, '2023-12-15', 'Wholesale', TIMESTAMP '2023-12-15'),
(2023, 1012, '2024-01-08', 'Online',    TIMESTAMP '2024-01-08'),
(2024, 1007, '2024-01-25', 'Retail',    TIMESTAMP '2024-01-25'),
(2025, 1010, '2024-02-10', 'Online',    TIMESTAMP '2024-02-10'),
(2026, 1004, '2024-02-27', 'Wholesale', TIMESTAMP '2024-02-27'),
(2027, 1015, '2024-03-15', 'Retail',    TIMESTAMP '2024-03-15'),
(2028, 1018, '2024-03-30', 'Online',    TIMESTAMP '2024-03-30'),
(2029, 1002, '2024-04-16', 'Online',    TIMESTAMP '2024-04-16');

INSERT INTO northriver_oltp.order_items VALUES
(3001, 2001, 101, 1, 120.00, TIMESTAMP '2023-01-10'),
(3002, 2001, 112, 2,  18.00, TIMESTAMP '2023-01-10'),
(3003, 2002, 102, 1, 189.00, TIMESTAMP '2023-01-22'),
(3004, 2003, 104, 2,  45.00, TIMESTAMP '2023-02-05'),
(3005, 2004, 109, 3,  95.00, TIMESTAMP '2023-02-18'),
(3006, 2005, 103, 1,  55.00, TIMESTAMP '2023-03-02'),
(3007, 2005, 110, 1,  22.00, TIMESTAMP '2023-03-02'),
(3008, 2006, 105, 1,  75.00, TIMESTAMP '2023-03-15'),
(3009, 2007, 108, 5,  28.00, TIMESTAMP '2023-04-01'),
(3010, 2008, 101, 1, 120.00, TIMESTAMP '2023-04-20'),
(3011, 2009, 107, 1,  88.00, TIMESTAMP '2023-05-08'),
(3012, 2010, 106, 2,  32.00, TIMESTAMP '2023-05-25'),
(3013, 2011, 113, 4,  55.00, TIMESTAMP '2023-06-12'),
(3014, 2012, 114, 2,  25.00, TIMESTAMP '2023-07-03'),
(3015, 2013, 111, 1,  40.00, TIMESTAMP '2023-07-19'),
(3016, 2013, 112, 3,  18.00, TIMESTAMP '2023-07-19'),
(3017, 2014, 102, 1, 189.00, TIMESTAMP '2023-08-05'),
(3018, 2015, 108,10,  28.00, TIMESTAMP '2023-08-22'),
(3019, 2016, 104, 1,  45.00, TIMESTAMP '2023-09-08'),
(3020, 2017, 101, 1, 120.00, TIMESTAMP '2023-09-25'),
(3021, 2018, 109, 2,  95.00, TIMESTAMP '2023-10-11'),
(3022, 2019, 103, 1,  55.00, TIMESTAMP '2023-10-28'),
(3023, 2020, 107, 1,  88.00, TIMESTAMP '2023-11-14'),
(3024, 2021, 105, 2,  75.00, TIMESTAMP '2023-11-30'),
(3025, 2022, 113, 3,  55.00, TIMESTAMP '2023-12-15'),
(3026, 2023, 110, 2,  22.00, TIMESTAMP '2024-01-08'),
(3027, 2024, 102, 1, 189.00, TIMESTAMP '2024-01-25'),
(3028, 2025, 111, 1,  40.00, TIMESTAMP '2024-02-10'),
(3029, 2026, 108, 8,  28.00, TIMESTAMP '2024-02-27'),
(3030, 2027, 114, 1,  25.00, TIMESTAMP '2024-03-15'),
(3031, 2028, 101, 1, 120.00, TIMESTAMP '2024-03-30'),
(3032, 2029, 104, 3,  45.00, TIMESTAMP '2024-04-16');

SELECT 'customers'  AS tbl, COUNT(*) AS rows FROM northriver_oltp.customers  UNION ALL
SELECT 'products',          COUNT(*)         FROM northriver_oltp.products   UNION ALL
SELECT 'orders',            COUNT(*)         FROM northriver_oltp.orders     UNION ALL
SELECT 'order_items',       COUNT(*)         FROM northriver_oltp.order_items
ORDER BY tbl;