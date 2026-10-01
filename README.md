# Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)

## 🏗️ Architecture & Overview
An enterprise-grade, Medallion-style Data Warehouse built for multi-outlet supply chain, inventory management, and consumption operations. Designed to automate multi-source Python ETL pipelines, enforce strict data typing, eliminate manual calculation errors, and deliver executive-level insights including ABC Pareto stratification, financial waste tracking, and Month-over-Month spend velocity.

---

## 📂 Repository Structure

```text
EnterpriseSupplyChainDW/
│
├── 01_etl/                     # Python Automation Ingestion Pipelines
│   ├── inventory_etl.py        # Ingests and cleans multi-outlet stock movement files
│   └── consumption_etl.py      # Ingests multi-outlet consumption & recipe usage reports
│
├── 02_schema/                  # Database DDL & Staging Contracts
│   ├── 01_schema_setup.sql     # Inventory staging table schema definitions
│   └── 01_create_fact_consumption_staging.sql # Consumption fact table schema definitions
│
├── 03_validation/              # Automated Data Quality & Parity Audits
│   ├── 01_inventory_validation.sql # Inventory stock audit checks
│   └── 05_data_validation_checks.sql # Consumption row counts, negative anomaly & variance audits
│
└── 04_gold_views/              # Executive BI & Analytical Reporting Views
    ├── 01_abc_inventory_analysis.sql # Inventory ABC Pareto stratification analysis
    ├── 02_loss_prevent_audit.sql # Loss prevention tracking and audit views
    ├── 03_mom_variance_trends.sql # Month-over-month inventory variance trends
    ├── 04_outlet_benchmarking.sql # Multi-outlet operational performance benchmarking
    ├── 05_category_risk_matrix.sql # Inventory risk categorization matrix
    ├── 06_vw_outlet_consumption_performance.sql # Executive actual vs. theoretical spend & waste rollup
    ├── 07_vw_item_variance_alerts.sql # Operational leakage & high quantity variance item flags
    ├── 08_vw_category_spend_breakdown.sql # Departmental spend breakdown by main group & category
    ├── 09_vw_top_items_by_category_monthly.sql # Top 5 consumed items per category (ROW_NUMBER ranking)
    ├── 10_vw_top_spending_locations.sql # Outlet spend and variance ranking (DENSE_RANK)
    ├── 11_vw_outlet_mom_spend_trend.sql # Month-over-Month spend and waste growth velocity (LAG functions)
    └── 12_vw_high_risk_waste_outliers.sql # High-risk waste threshold alerts (>= 15% waste ratios)
