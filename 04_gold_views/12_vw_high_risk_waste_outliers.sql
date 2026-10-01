/*
------------------------------------------------------------------------------------
Author: Rohit Dangwal
Project: Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)
Script Name: 09_vw_high_risk_waste_outliers.sql
Created Date: 2026-09-30
Description: Operational risk view highlighting items with severe waste percentages 
             or high waste financial exposure across outlets.
------------------------------------------------------------------------------------
*/

select
    location_name,
    report_month_name,
    report_month_num,
    ref_id,
    item_name,
    base_unit,
    round(actual_qty_consumed,2) as actual_qty_consumed,
    round(actual_consumption_value,2) as actual_consumption_value,
    round(waste_qty,2) as waste_qty,
    round(waste_value,2) as waste_value,
    round(waste_cost_percentage,2) as waste_cost_percentage
from fact_consumption
where waste_cost_percentage >= 0.15  -- Flags items with 15% or higher waste ratio
or waste_value >= 100 -- Or items where single-month waste exceeds currency unit threshold

go
