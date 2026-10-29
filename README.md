# NorthRiver Data Warehouse

A Databricks ELT warehouse and Power BI reporting project for BrewFlow revenue analytics.

## At a glance

- **Source:** `northriver_oltp` (customers, products, orders, order items)
- **Staging:** `northriver_staging`
- **Warehouse:** `northriver_warehouse` (order-line fact and four dimensions)
- **Orchestration:** scheduled Lakeflow job `northriver_nightly_pipeline`
- **BI:** Power BI revenue by product category, customer region, and sales channel over time

The pipeline runs `03_extract` → `04_transform` → `05_load`. Customer and product history is preserved with SCD Type 2, while fact inserts are idempotent by `order_item_id` and use point-in-time dimension joins for late-arriving orders.

## Documentation

See [Project Report](docs/project-report.md) for the architecture, model choices, job flow, dashboard design, validation evidence, limitations, and Sprint 1–4 progression.

## Validation snapshot

The supplied Sprint 4 walkthrough reports 32 initial fact rows and 35 after a simulation added three order lines. These results are reported from the walkthrough, not independently queried in this repository.
