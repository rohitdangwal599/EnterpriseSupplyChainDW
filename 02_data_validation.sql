/*
===============================================================================
Script Name: 02_data_validation.sql
Author: Rohit Dangwal
Database: EnterpriseSupplyChainDW
Description: Post-load data quality checks to verify row counts, missing 
             references, and audit ingestion completeness.
===============================================================================
*/

use EnterpriseSupplyChainDW;
go

--==============================================================================
--Check 1: Master Volume Check (Total rows & outlets Loaded)
--==============================================================================
select
	location_name,
	report_year,
	count(*) as total_rows_loaded,
	count(distinct report_period) as total_files_proccessed
from fact_inventory
group by location_name, report_year
order by location_name

go

-- ============================================================================
-- Check 2: Data Integrity & Null Check (Ensuring critical keys aren't missing)
-- ============================================================================
select
	'Missing Item Reference IDs' as check_type,
	count(*) as anomaly_count
from fact_inventory
where stock_item_ref_id is null or LTRIM(RTRIM(stock_item_ref_id)) = ''

union all

select
	'Negative Inventory Values' as check_type,
	count(*) as anomaly_count
from fact_inventory
where inventory_value < 0

union all

select
	'Negative Cost Price' as check_type,
	count(*) as anomaly_count
from fact_inventory
where cost_price < 0;


go

-- ============================================================================
-- Check 3: File-Level Ingestion Breakdown (Tracking individual file volume)
-- ============================================================================

select
	location_name,
	report_period,
	report_month_name,
	count(*) as rows_in_file
from fact_inventory
group by location_name, report_period, report_month_name, report_month_num
order by report_month_num asc, location_name asc;

go
	

-- ============================================================================
-- Check 4: Duplicate Row Detection (Catching double-logged items in same file)
-- ============================================================================

select
	location_name,
	report_period,
	stock_item_ref_id,
	count(*) as duplicate_occurence
from fact_inventory
group by location_name, report_period, stock_item_ref_id
having count(*) > 1;

go

-- ============================================================================
-- Check 5: Corrected Mathematical Consistency Audit 
-- (Verifying if Inventory Value matches Quantity Counted * Cost Price)
-- ============================================================================

select
	location_name,
	report_period,
	stock_item_name,
	quantity_counted,
	cost_price,
	inventory_value,
	(cost_price * quantity_counted) as calculated_counted_value,
	abs(inventory_value-(cost_price * quantity_counted)) as valuation_discrepancy
from fact_inventory
where abs(inventory_value-(cost_price * quantity_counted)) > 0.50 --allow for rounding
order by report_year asc, report_month_num asc

go

-- ============================================================================
-- ChecK 6: Excel Reconciliation Summary (Location & Month Wise Totals)
-- Purpose: Aggregates total inventory valuation, counted valuation, and 
--          variance value by month and location. Match these numbers 
--          directly against our raw source Excel sheets or summary pivots.
-- ============================================================================

select
	location_name,
	report_year,
	report_month_name,
	count(distinct report_period) as file_in_month,
	sum(theoretical_inventory_value) as total_theoretical_value,
	sum(counted_inventory_value) as total_counted_value,
	sum(variance_value) as net_total_variance_value
from fact_inventory
group by
	location_name,
	report_year,
	report_month_name,
	report_month_num
order by
	location_name asc,
	report_month_num asc;

go

-- ============================================================================
-- ChecK 7: ETL Pipeline Logic Audit (Python vs SQL Parity)
-- ============================================================================

select
	location_name,
	report_period,
	report_month_name,
	sum(variance_value) as python_calculated_variance,
	sum(stock_difference * cost_price) as sql_expected_variance,
	sum(abs(variance_value-(stock_difference * cost_price))) as discrepancy_delta
from fact_inventory
group by location_name, report_period, report_month_num,report_month_name
having sum(abs(variance_value-(stock_difference * cost_price))) > 1.5
order by report_month_num asc, discrepancy_delta desc

go

-- ============================================================================
-- ChecK 8: Loss Prevention & High-Variance Financial Audit
-- ============================================================================

select Top 20
	location_name,
	report_year,
	report_month_name,
	category_code,
	stock_item_name,
	base_units,
	stock_on_hand,
	quantity_counted,
	stock_difference,
	cost_price,
	variance_value
from fact_inventory
where abs(variance_value)>500
order by abs(variance_value) desc