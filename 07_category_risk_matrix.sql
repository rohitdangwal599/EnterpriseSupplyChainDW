/*
===============================================================================
Script Name: 07_category_risk_matrix.sql
Author: Rohit Dangwal
Database: EnterpriseSupplyChainDW
Description: Evaluates capital concentration, percentage share of total stock, 
             and financial shrinkage risks grouped by category code and outlet.
===============================================================================
*/

use EnterpriseSupplyChainDW
go

-- ============================================================================
-- Category Capital Concentration & Risk Analysis
-- ============================================================================

DROP VIEW IF EXISTS vw_category_risk_matrix;
GO


CREATE VIEW vw_category_risk_matrix AS
with category_aggregates as (
select
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    category_code,
    count(distinct stock_item_ref_id) as total_skus_in_category,
    sum(counted_inventory_value) as category_counted_value,
    sum(variance_value) as category_net_variance,
    sum(abs(variance_value))as category_absolute_error
from fact_inventory
group by
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    category_code
),
location_total as (
select
    location_name,
    report_year,
    report_month_num,
    sum(category_counted_value) as outlet_total_valuation
from category_aggregates
group by
    location_name,
    report_year,
    report_month_num
)
select
    c.location_name,
    c.report_year,
    c.report_month_name,
    c.report_month_num,
    c.category_code,
    c.total_skus_in_category,
    concat('€',format(c.category_counted_value,'N2')) as formatted_category_value,
    --percentage share of total  outlet inventory capital
    cast(
        (c.category_counted_value*100 / nullif (lt.outlet_total_valuation,0))
        as decimal(5,2)
        ) as capital_percentage_share,
    concat('€',format(c.category_net_variance,'N2')) as formatted_category_net_variance,
    concat('€',format(c.category_absolute_error,'N2')) as formatted_category_absolute_error
from category_aggregates c
inner join location_total lt
    on c.location_name = lt.location_name
    and c.report_year = lt.report_year
    and c.report_month_num = lt.report_month_num

/* order by
    c.location_name,
    c.report_year asc,
    c.report_month_num asc,
    c.category_counted_value desc;

go
*/

go

select* from vw_category_risk_matrix
order by
    location_name,
    report_year asc,
    report_month_num asc,
    capital_percentage_share desc;
go