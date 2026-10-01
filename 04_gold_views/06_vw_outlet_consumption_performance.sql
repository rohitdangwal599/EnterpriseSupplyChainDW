/*
------------------------------------------------------------------------------------
Author: Rohit Dangwal
Project: Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)
Script Name: 02_vw_outlet_consumption_performance.sql
Created Date: 2026-09-30
Description: Executive management view aggregating actual vs. theoretical spend, 
             waste metrics, and native differences by outlet and monthly reporting period.
------------------------------------------------------------------------------------
*/

use EnterpriseSupplyChainDW
go

drop view if exists vw_outlet_consumption_performance
go

create view vw_outlet_consumption_performance as
select
    location_name,
    report_year,
    report_month_num,
    count(ref_id) as total_items_tracked,
    round(sum(actual_consumption_value),2) as total_actual_spend,
    round(sum(theoretical_value),2) as total_theoretical_spend,
    round(sum(waste_value),2) as total_waste_value,
    round(sum(value_variance),2) as total_variance_value,
    round(sum(difference_value),2) as total_difference_value,
    concat(round(avg(waste_cost_percentage)*100,2),'%') as avg_waste_cost_percentage

from fact_consumption
group by
    location_name,
    report_year,
    report_month_num

/*
order by
    report_year asc,
    report_month_num asc
  */  
  go

  select * from vw_outlet_consumption_performance
  order by 
        report_year asc,
        report_month_num asc
