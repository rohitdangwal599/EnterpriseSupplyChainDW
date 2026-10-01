/*
------------------------------------------------------------------------------------
Author: Rohit Dangwal
Project: Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)
Script Name: 03_vw_item_variance_alerts.sql
Created Date: 2026-09-30
Description: Operational alert view identifying items with high positive quantity and 
             value variances across individual outlets to catch shrinkage or spillage.
------------------------------------------------------------------------------------
*/

use EnterpriseSupplyChainDW
go

drop view if exists vw_item_positive_consumption_variance_alerts
go

create view vw_item_positive_consumption_variance_alerts as
select
    location_name,
    report_month_name,
    report_month_num,
    category,
    item_name,
    base_unit,
    round(sum(actual_qty_consumed),2) as total_actual_qty,
    round(sum(theoretical_qty),2) as total_theoretical_qty,
    round(sum(qty_variance),2) as total_variance_qty,
    round(sum(value_variance),2) as total_value_variance,
    round(sum(difference_value),2) as total_difference_value
from fact_consumption
where qty_variance > 0 and location_name in ('Outlet_PK', 'Outlet_CB', 'Outlet_PB')
group by
    location_name,
    report_month_name,
    report_month_num,
    category,
    item_name,
    base_unit
/*
order by 
    report_month_name asc,
    report_month_num asc,
    sum(difference_value) desc
*/
go

select * from vw_item_positive_consumption_variance_alerts
order by
    report_month_num asc,
    total_difference_value desc




/*
------------------------------------------------------------------------------------
Script Name: 03_vw_item_variance_alerts.sql
Created Date: 2026-09-30
Description: Operational alert view identifying items with high negative quantity and 
             value variances across individual outlets to catch shrinkage or spillage.
------------------------------------------------------------------------------------
*/

use EnterpriseSupplyChainDW
go

drop view if exists vw_item_negative_consumption_variance_alerts
go

create view vw_item_negative_consumption_variance_alerts as
select
    location_name,
    report_month_name,
    report_month_num,
    category,
    item_name,
    base_unit,
    round(sum(actual_qty_consumed),2) as total_actual_qty,
    round(sum(theoretical_qty),2) as total_theoretical_qty,
    round(sum(qty_variance),2) as total_variance_qty,
    round(sum(value_variance),2) as total_value_variance,
    round(sum(difference_value),2) as total_difference_value
from fact_consumption
where qty_variance < 0 and location_name in ('Outlet_PK', 'Outlet_CB', 'Outlet_PB')
group by
    location_name,
    report_month_name,
    report_month_num,
    category,
    item_name,
    base_unit
/*
order by 
    report_month_name asc,
    report_month_num asc,
    sum(difference_value) asc
*/
go

select * from vw_item_negative_consumption_variance_alerts
order by 
    report_month_name asc,
    report_month_num asc,
    total_difference_value asc

    
    
