# NorthRiver Data Warehouse

A Databricks ELT warehouse and Power BI reporting project for BrewFlow revenue analytics.

## At a glance

- **Source:** `northriver_oltp` (customers, products, orders, order items)
- **Staging:** `northriver_staging`
- **Warehouse:** `northriver_warehouse` (order-line fact and four dimensions)
- **Orchestration:** scheduled Lakeflow job `northriver_nightly_pipeline`
- **BI:** Power BI revenue by product category, customer region, and sales channel over time

The pipeline runs `03_extract` → `04_transform` → `05_load`. Customer and product history is preserved with SCD Type 2, while fact inserts are idempotent by `order_item_id` and use point-in-time dimension joins for late-arriving orders.

## SQL source

All six SQL scripts are in [`sql/`](sql/):

1. [Create OLTP tables](sql/01-Create-OLTP-Tables.sql)
2. [Simulate OLTP data changes](sql/OLTP-Data-Changes.sql)
3. [Create warehouse tables](sql/02-Create-Warehouse-Tables.sql)
4. [Extract](sql/03-extract.sql)
5. [Transform](sql/04-transform.sql)
6. [Load](sql/05-load.sql)

## Documentation

See the [Project Report](docs/project-report.md) for architecture, the visual Lakeflow job flow, model choices, dashboard design, validation evidence, limitations, and Sprint 1–4 progression.
