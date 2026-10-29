CREATE SCHEMA IF NOT EXISTS northriver_warehouse
  COMMENT 'NorthRiver OLAP star schema — dimensions and fact tables for retail analytics';

-- Dimension tables (create first — fact table has FK constraints)

CREATE TABLE IF NOT EXISTS northriver_warehouse.dim_date (
    date_sk       BIGINT,
    full_date     DATE,
    year          INT,
    quarter       INT,
    month         INT,
    day_of_week   STRING,
    PRIMARY KEY (date_sk)
);

CREATE TABLE IF NOT EXISTS northriver_warehouse.dim_channel (
    channel_sk    BIGINT GENERATED ALWAYS AS IDENTITY,
    channel_name  STRING NOT NULL,
    PRIMARY KEY (channel_sk)
);

CREATE TABLE IF NOT EXISTS northriver_warehouse.dim_customer (
    customer_sk   BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id    INT,
    first_name     STRING,
    last_name      STRING,
    email          STRING,
    region         STRING,
    segment        STRING,
    effective_from DATE,
    effective_to   DATE,
    is_current     BOOLEAN,
    PRIMARY KEY (customer_sk)
);

CREATE TABLE IF NOT EXISTS northriver_warehouse.dim_product (
    product_sk    BIGINT GENERATED ALWAYS AS IDENTITY,
    product_id     INT,
    product_name   STRING,
    brand          STRING,
    category       STRING,
    subcategory    STRING,
    unit_cost      DECIMAL(10, 2),
    effective_from DATE,
    effective_to   DATE,
    is_current     BOOLEAN,
    PRIMARY KEY (product_sk)
);

-- Fact table (FK constraints to all dimensions)

CREATE TABLE IF NOT EXISTS northriver_warehouse.fact_orders (
    order_id       INT,
    order_item_id  BIGINT,
    customer_sk    BIGINT,
    product_sk     BIGINT,
    channel_sk     BIGINT,
    date_sk        BIGINT,
    quantity       INT,
    unit_price     DECIMAL(10, 2),
    revenue        DECIMAL(10, 2) GENERATED ALWAYS AS (CAST(quantity * unit_price AS DECIMAL(10, 2))),
    PRIMARY KEY (order_item_id),
    FOREIGN KEY (customer_sk) REFERENCES northriver_warehouse.dim_customer (customer_sk),
    FOREIGN KEY (product_sk)  REFERENCES northriver_warehouse.dim_product  (product_sk),
    FOREIGN KEY (channel_sk)  REFERENCES northriver_warehouse.dim_channel  (channel_sk),
    FOREIGN KEY (date_sk)     REFERENCES northriver_warehouse.dim_date     (date_sk)
);