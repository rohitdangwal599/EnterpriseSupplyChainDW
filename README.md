# Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)

## 🏗️ Architecture & Overview
An enterprise-grade, Medallion-style Data Warehouse built for multi-outlet supply chain and inventory operations. Designed to automate data pipelines, eliminate calculation errors, and deliver executive-level financial shrinkage and ABC Pareto analytics.

## 📂 Repository Structure
- **`01_etl/`**: Python SQLAlchemy ingestion pipeline automating multi-outlet data loading.
- **`02_schema/`**: DDL table definitions with strict typing and pre-calculated metrics.
- **`03_validation/`**: Automated post-load data quality and parity audits.
- **`04_gold_views/`**: Executive BI reporting views (ABC Analysis, Loss Prevention, MoM Trends, Benchmarking).

## 🛠️ Tech Stack
- **Database**: Microsoft SQL Server (T-SQL)
- **ETL**: Python, Pandas, SQLAlchemy, ODBC
- **BI / Analytics**: Advanced Window Functions, Pareto Stratification# EnterpriseSupplyChainDW
Enterprise Data Warehouse for Multi-Domain Inventory &amp; Supply Chain Analytics
