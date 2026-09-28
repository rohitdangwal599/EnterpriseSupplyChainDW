/*
===============================================================================
Script Name: 05_mom_variance_trends.sql
Author: Rohit Dangwal
Database: EnterpriseSupplyChainDW
Description: Evaluates Month-over-Month (MoM) performance trends, tracking changes 
             in audit counts, counted asset values, and net variance deltas per outlet.
===============================================================================
*/

use EnterpriseSupplyChainDW
go

-- ============================================================================
-- Monthly Outlet Trend & Variance Delta Analysis
-- ============================================================================
drop view if exists vw_mom_variance_trends
go

create view vw_mom_variance_trends as
with monthly_outlet_performance as (
select
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    count(distinct report_period) as audits_conducted,
    count(stock_item_ref_id) as total_sku_tracked,
    sum(inventory_value) as total_valuation,
    sum(variance_value) as total_net_variace_value,
    sum(abs(variance_value)) as total_absolute_fianancial_impact
from fact_inventory
group by 
    location_name,
    report_year,
    report_month_name,
    report_month_num
)
select
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    audits_conducted,
    total_sku_tracked,
    concat('€ ', format(total_valuation, 'N2')) as formatted_total_valuation,
    concat('€ ', format(total_net_variace_value,'N2')) as formatted_net_variance_value,
    concat('€ ', format(
                 isnull (total_net_variace_value-lag(total_net_variace_value,1) over(
                    partition by location_name
                    order by report_year asc, report_month_num asc
                    ),0),'N2'))
    as mom_net_variance_delta,
    concat('€ ', format(total_absolute_fianancial_impact,'N2')) as formatted_absolute_impact
 from monthly_outlet_performance
/* 
 order by
    location_name,
    report_year asc,
    report_month_num asc;

go
*/
go

select * from vw_mom_variance_trends
order by
    location_name,
    report_year asc,
    report_month_num asc;
go