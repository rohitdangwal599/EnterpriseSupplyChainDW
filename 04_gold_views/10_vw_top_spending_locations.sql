/*
------------------------------------------------------------------------------------
Author: Rohit Dangwal
Project: Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)
Script Name: 07_vw_top_spending_locations.sql
Created Date: 2026-09-30
Description: Executive ranking view ordering outlets by overall spend and financial 
             variance impact across reporting periods.
------------------------------------------------------------------------------------
*/

use EnterpriseSupplyChainDW
go

drop view if exists vw_top_spending_locations
go

create view vw_top_spending_locations as
with total_spending as (
select
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    count(ref_id) as total_skus,
    round(sum(actual_consumption_value),2) as total_spending,
    ROUND(SUM(theoretical_value), 2) AS total_theoretical_spend,
    ROUND(SUM(value_variance), 2) AS total_value_variance, -- mapping check
    ROUND(SUM(waste_value), 2) AS total_waste_value
from fact_consumption
group by 
    location_name,
    report_year,
    report_month_name,
    report_month_num
),
spending_rnk as(
select
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    total_spending,
    total_theoretical_spend,
    total_value_variance,
    total_waste_value,
    total_skus,
    row_number () over (
                        partition by report_year,report_month_name, report_month_num
                        order by total_spending desc
                  ) as monthly_spending_rank
 from total_spending
)
 select
   location_name,
    report_year,
    report_month_name,
    report_month_num,
    total_spending,
    total_theoretical_spend,
    total_value_variance,
    total_waste_value,
    total_skus,
    monthly_spending_rank
 from spending_rnk
 where monthly_spending_rank <= 5
 /* order by 
    report_year asc,
    report_month_num asc,
    total_spending desc
*/
go



select * from vw_top_spending_locations
order by 
    report_year asc,
    report_month_num asc,
    total_spending desc


