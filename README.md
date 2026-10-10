# Enterprise Supply Chain Data Warehouse & Analytics Platform

An end-to-end senior-level supply chain analytics solution bridging robust **SQL Data Engineering**, **Python automation pipelines**, and an executive-level **4-Page Power BI Command Center**. Designed for high-frequency inventory tracking, shrinkage auditing, working capital optimization, and operational waste detection.

---

## 🏗️ Technical Architecture & Data Pipeline
- **Data Engineering (SQL)**: Built upon 7+ clean Gold-tier analytical views, ensuring explicit separation between inventory valuation (`fact_inventory`) and operational consumption (`fact_consumption`) without cross-view data leakage.
- **Data Pipeline (Python)**: Automated orchestration scripts handling extraction, schema definition, data validation checks, and staging consistency.
- **Visualization (Power BI)**: A responsive, executive-grade command center optimized for high-density whitespace, clean visual hierarchy, and dynamic performance metrics.

---

## 📊 Executive Power BI Command Center

### Page 1: Inventory & Valuation Control
* **Focus**: Asset visibility, working capital distribution, and top-tier inventory ranking.
* **Features**: ABC Pareto classification donuts, category capital concentration tracking, and high-value SKU analysis.
![Page 1 Inventory and Valuation](Page%201%20Inventory%20and%20Valuation.png)

### Page 2: Loss Prevention & Shrinkage Audit
* **Focus**: Isolating financial bleed, structural shortages, and high-risk variance exceptions.
* **Features**: Shrinkage breakdown across outlets, month-over-month stock variance trajectories, and negative variance item ranking.
![Page 2 Loss Prevention](Page%202%20Loss%20Prevention.png)

### Page 3: Outlet Benchmarking & Performance Trends
* **Focus**: Multi-location comparison, counting compliance, and historical month-over-month trajectory.
* **Features**: Cross-outlet valuation matrix and historical operational trend analysis.
![Page 3 Outlet Benchmarking](Page%203%20Outlet%20Benchmarking.png)

### Page 4: Operational Consumption & Variance Analysis
* **Focus**: Actual vs. theoretical recipe consumption, waste tracking, and spillage detection.
* **Features**: Outlet consumption performance summaries, waste valuation trends, and item-level recipe leakage lists.
![Page 4 Consumption and Waste](Page%204%20Consumption%20and%20Waste.png)

---

## 🛠️ Repository Structure
- `01_etl/`: Python pipeline scripts for data ingestion and processing.
- `02_schema/`: Database staging and table creation schemas.
- `03_validation/`: Data quality and integrity check scripts.
- `04_gold_views/`: Production-ready Gold SQL analytical views.
- `EnterpriseSupplyChainDW.pbix`: The final, optimized Power BI enterprise reporting model.

Note: Due to enterprise size constraints (12+ months across 120+ ERP nodes), raw data files are excluded from this public repository. The repository demonstrates the end-to-end architecture, transformation code, validation logic, and executive reporting layer.
