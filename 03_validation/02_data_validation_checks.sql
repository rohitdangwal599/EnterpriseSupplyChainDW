/*
------------------------------------------------------------------------------------
Author: Rohit Dangwal
Project: Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)
Script Name: 05_data_validation_checks.sql
Created Date: 2026-09-30
Description: Comprehensive data quality audit and validation suite. Runs automated 
             health checks across the ingestion layer to inspect row distributions, 
             detect structural anomalies, flag negative financial records, and 
             surface enterprise-wide waste drivers.
------------------------------------------------------------------------------------
*/

use EnterpriseSupplyChainDW
go

PRINT '================================================================================';
PRINT 'RUNNING ENTERPRISE CONSUMPTION ETL AUDIT & DATA INTEGRITY CHECKS';
PRINT '================================================================================';
GO

-- --------------------------------------------------------------------------------
-- TEST 1: Row Count & Ingestion Completeness by Outlet and Period
-- Purpose: Ensures all multi-outlet Excel files appended cleanly without missing months.
-- --------------------------------------------------------------------------------

PRINT '--- Test 1: Ingestion Distribution & Completeness ---';

select
    location_name,
    report_year,
    report_month_name,
    count(*) as total_rows_ingested,
    count(distinct ref_id) as unique_items_count
from fact_consumption
group by 
    location_name,
    report_year,
    report_month_name,
    report_month_num
order by
    location_name,
    report_year asc,
    report_month_num asc
go

-- --------------------------------------------------------------------------------
-- TEST 2: Negative Cost or Quantity Anomaly Detection
-- Purpose: Flags any corrupt rows where units or consumption values are negative.
-- --------------------------------------------------------------------------------
PRINT '--- Test 2: Negative Cost & Value Anomalies ---';

select
    location_name,
    item_name,
    unit_cost_actual,
    actual_qty_consumed,
    actual_consumption_value
from fact_consumption
where unit_cost_actual < 0
    or actual_qty_consumed < 0
    or actual_consumption_value < 0

go

    -- --------------------------------------------------------------------------------
-- TEST 3: Top 10 Costliest Waste Drivers Enterprise-Wide
-- Purpose: Pinpoints exact items causing the highest financial waste across all outlets.
-- --------------------------------------------------------------------------------
PRINT '--- Test 3: Top 10 Enterprise Waste Cost Drivers ---';

select top 10
    location_name,
    report_year,
    report_month_name,
    item_name,
    base_unit,
    round(sum(waste_value),2) as total_waste_cost,
    round(avg(waste_cost_percentage),2) as avg_waste_percentage
from fact_consumption
group by 
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    item_name,
    base_unit
order by total_waste_cost asc 
go

-- --------------------------------------------------------------------------------
-- TEST 4: Reconciliation of Native Difference vs. Calculated Variance
-- Purpose: Verifies that the native Excel difference matches our custom metrics.
-- --------------------------------------------------------------------------------
PRINT '--- Test 4: Variance Reconciliation Audit ---';

select
    location_name,
    report_year,
    report_month_name,
    round(sum(qty_variance),2) as calculated_qty_variance,
    round(sum(difference_qty),2) as native_difference_qty,
    round(sum(value_variance),2) as calculated_variance_value,
    round(sum(difference_value),2) as native_difference_value
from fact_consumption
group by
    location_name,
    report_year,
    report_month_name,
    report_month_num
order by
    report_year asc,
    report_month_num asc
go
    
    
