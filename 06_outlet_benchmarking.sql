/*
===============================================================================
Script Name: 06_outlet_benchmarking.sql
Author: Rohit Dangwal
Database: EnterpriseSupplyChainDW
Description: Evaluates and benchmarks the operational and financial health of 
             all 6 hospitality outlets side-by-side by aggregating scale, 
             valuation, counting compliance, and absolute error rates.
===============================================================================
*/

use EnterpriseSupplyChainDW
go

-- ============================================================================
-- Cross-Outlet Performance Benchmarking Matrix
-- ============================================================================

drop view if exists vw_outlet_benchmarking
go

create view vw_outlet_benchmarking as
select
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    count(distinct report_period) as audit_files_processed,
    count(stock_item_ref_id) as total_skus_managed,
    --Capital Valuations
    concat('€ ' ,format(sum(theoretical_inventory_value),'N2')) as total_theoretical_valuation,
    concat('€ ' ,format(sum(counted_inventory_value),'N2')) as total_counted_valuation,
    --Financial Variances
    concat('€ ' ,format(sum(variance_value),'N2')) as net_financial_variance,
    concat('€ ' ,format(sum(abs(variance_value)),'N2')) as total_absolute_financial_error,
    --Counting compliance ratio (% of items physically counted vs uncounted)
    cast(
        sum(case when has_been_counted = 'Y' then 1 else 0 end)*100 / count(*) as decimal (5,2)
        ) as counting_complaiance_percentage
    from fact_inventory
    group by 
        location_name,
        report_year,
        report_month_name,
        report_month_num
 /*   order by
        report_year asc,
        report_month_num asc,
        sum(abs(variance_value)) desc;  ---Hidhest absolute error risk ranked first */

go

select * from vw_outlet_benchmarking
order by
    location_name,
    report_year,
    report_month_num asc