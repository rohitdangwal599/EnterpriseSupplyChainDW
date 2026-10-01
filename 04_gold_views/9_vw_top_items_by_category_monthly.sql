/*
------------------------------------------------------------------------------------
Author: Rohit Dangwal
Project: Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)
Script Name: 06_vw_top_items_by_category_monthly.sql
Created Date: 2026-09-30
Description: Analytical ranking view that isolates the top 5 consumed items per 
             location on a monthly basis using window ranking functions.
------------------------------------------------------------------------------------
*/

use EnterpriseSupplyChainDW
go

drop view if exists vw_top_items_by_location_monthly
go

create view vw_top_items_by_location_monthly as
with ranked_items as(
    select
        location_name,
        report_year,
        report_month_name,
        report_month_num,
        main_group,
        category,
        ref_id,
        item_name,
        base_unit,
        round(sum(actual_qty_consumed),2) as total_actual_qty,
        round(sum(actual_consumption_value),2) as total_actual_value,
        row_number() over (
                        partition by location_name, report_year, report_month_num 
                        order by sum(actual_consumption_value) desc
                        ) as consumption_rank
      from fact_consumption
      group by
        location_name,
        report_year,
        report_month_name,
        report_month_num,
        main_group,
        category,
        ref_id,
        item_name,
        base_unit
)
            
 select   
        location_name,
        report_year,
        report_month_name,
        report_month_num,
        main_group,
        category,
        ref_id,
        item_name,
        base_unit,
        total_actual_qty,
        total_actual_value,
        consumption_rank
from  ranked_items
where consumption_rank <= 5
/*
order by
        location_name asc,
        report_year asc,
        report_month_num asc,
        total_actual_value desc
*/

go

select * from vw_top_items_by_location_monthly
order by
        location_name asc,
        report_year asc,
        report_month_num asc,
        total_actual_value desc
