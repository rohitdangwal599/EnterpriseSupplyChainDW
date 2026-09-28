/*
===============================================================================
Script Name: 03_abc_inventory_analysis.sql
Author: Rohit Dangwal
Database: EnterpriseSupplyChainDW
Description: 
    EXECUTE-LEVEL PURPOSE:
    Implements ABC / Pareto Analysis (80/20 Rule) on enterprise inventory assets 
    using pre-calculated counted_inventory_value from fact_inventory.
    
    BUSINESS VALUE & LAYMAN DEFINITION:
    - Segments inventory into Class A (Top 80% capital value - requires strict control), 
      Class B (Next 15% - standard monitoring), and Class C (Final 5% - bulk management).
    - Outputs SKU-level granularity (~198k rows across historical monthly audits) to 
      enable precise filtering in Power BI, Excel, or downstream reporting layers 
      by outlet location and reporting period.
===============================================================================
*/

use EnterpriseSupplyChainDW
go

-- ============================================================================
-- ABC Classification Query (Pareto Principle: Class A, B, C Tiers)
-- ============================================================================

drop view if exists vw_abc_inventory_analysis
go

create view vw_abc_inventory_analysis as
 with item_valuation as (
-- Step 1: Aggregate total counted valuation per SKU per outlet and month
select
    location_name,
    report_year,
    report_month_num,
    report_month_name,
    stock_item_ref_id,
    stock_item_name,
    category_code,
    sum(counted_inventory_value) as total_item_value
from fact_inventory
group by 
    location_name,
    report_year,
    report_month_num,
    report_month_name,
    stock_item_ref_id,
    stock_item_name,
    category_code
),
running_total as (
-- Step 2: Compute running cumulative totals and grand totals partition by outlet and month
select
    location_name,
    report_year,
    report_month_num,
    report_month_name,
    stock_item_ref_id,
    stock_item_name,
    category_code,
    total_item_value,
    sum(total_item_value) over (partition by location_name, report_year, report_month_num order by total_item_value desc, stock_item_ref_id asc rows between unbounded preceding and current row) as cumulative_value,
    sum(total_item_value) over (partition by location_name, report_year, report_month_num ) as grand_total_value
from item_valuation
)
-- Step 3: Assign ABC Classifications and format output for executive reporting
select
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    stock_item_ref_id,
    stock_item_name,
    category_code,
    concat('€ ',format(total_item_value,'N2')) as item_value,
    cast((cumulative_value *100/ grand_total_value) as decimal (5,2)) as cumulative_percentage,
    case
        when cumulative_value / grand_total_value <= 0.80 then 'Class A (High Value - Top 80%)'
        when cumulative_value / grand_total_value <= 0.95 then 'Class B (High Value - Next 15%)'
        else 'Class C (Low Value - Final 5%)'
    end as abc_classification
from running_total
/*
order by
    location_name asc,
    report_year asc,
    report_month_num asc,
    total_item_value desc;
    
go
*/
go

select * from vw_abc_inventory_analysis
order by 
    location_name asc,
    report_year asc,
    report_month_num asc,
    cumulative_percentage asc;