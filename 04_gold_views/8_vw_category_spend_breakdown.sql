/*
------------------------------------------------------------------------------------
Author: Rohit Dangwal
Project: Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)
Script Name: 04_vw_category_spend_breakdown.sql
Created Date: 2026-09-30
Description: Financial breakdown view grouping consumption totals by Main Group 
             and Category for granular category spend analysis.
------------------------------------------------------------------------------------
*/


use EnterpriseSupplyChainDW
go

drop view if exists vw_category_spend_breakdown
go

create view vw_category_spend_breakdown as
select
    location_name,
    main_group,
    category,
    report_year,
    report_month_name,
    report_month_num,
    count(distinct ref_id) as items_in_category,
    round(sum(actual_consumption_value),2) as category_actual_spend,
    round(sum(theoretical_value),2) as category_theoretical_spend,
    round(sum(waste_value),2) as category_waste_value
from fact_consumption
group by 
    location_name,
    main_group,
    category,
    report_year,
    report_month_name,
    report_month_num
/*
order by
    location_name,
    report_year asc,
    report_month_num asc,
    sum(actual_consumption_value) desc
*/

select* from vw_category_spend_breakdown
order by
    location_name,
    report_year asc,
    report_month_num asc,
    category_actual_spend desc

    
