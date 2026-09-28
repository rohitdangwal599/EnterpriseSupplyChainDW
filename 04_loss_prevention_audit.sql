/*
===============================================================================
Script Name: 04_loss_prevention_audit.sql
Author: Rohit Dangwal
Database: EnterpriseSupplyChainDW
Description: Isolates financial shrinkage, shortages, and overages at both the 
             SKU and category level using pre-calculated variance metrics.
===============================================================================
*/

use EnterpriseSupplyChainDW
go

-- ============================================================================
-- Query 1: Top High-Risk Financial Shortages (Shrinkage Audit)
-- Purpose: Ranks the top items bleeding the most capital due to negative variance 
--          (shortages) across all outlet locations and reporting periods.
-- ============================================================================

drop view if exists vw_high_risk_shrinkage_skus
go

create view vw_high_risk_shrinkage_skus as
SELECT 
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    category_code,
    stock_item_ref_id,
    stock_item_name,
    base_units,
    stock_on_hand,
    quantity_counted,
    stock_difference,
    cost_price,
    (stock_difference*cost_price) as variance_value,
    CONCAT('€ ', FORMAT(cost_price, 'N2')) AS formatted_cost_price,
    CONCAT('€ ', FORMAT(variance_value, 'N2')) AS formatted_variance_value,
    variance_status
FROM fact_inventory
WHERE variance_status = 'Shortage / Shrinkage'

go

/*
ORDER BY variance_value ASC;

go
*/

select TOP 25 * from vw_high_risk_shrinkage_skus
order by variance_value asc;

-- ============================================================================
-- Query 2: Net Category Variance & Shrinkage Concentration
-- Purpose: Aggregates financial variances by category code to show executive 
--          leadership which departments (e.g., bar, kitchen, housekeeping) 
--          are experiencing the worst structural shrinkage.
-- ============================================================================


drop view if exists vw_category_shrinkage_audit
go

create view vw_category_shrinkage_audit as
    SELECT 
    location_name,
    report_year,
    report_month_name,
    report_month_num,
    category_code,
    COUNT(CASE WHEN variance_status = 'Shortage / Shrinkage' THEN 1 END) AS shortage_item_count,
    COUNT(CASE WHEN variance_status = 'Surplus / Over-count' THEN 1 END) AS surplus_item_count,
    sum(stock_difference*cost_price) as net_total_variance_value_raw,
    sum(abs(stock_difference*cost_price)) as total_absolute_financial_impact_raw,
    CONCAT('€ ', FORMAT(SUM(variance_value), 'N2')) AS net_total_variance_value,
    CONCAT('€ ', FORMAT(SUM(ABS(variance_value)), 'N2')) AS total_absolute_financial_impact
FROM fact_inventory
GROUP BY 
    location_name,
    report_year,
    report_month_num,
    report_month_name,
    category_code

/*
ORDER BY 
    location_name ASC,
    report_month_num ASC,
    SUM(variance_value) ASC; -- Most negative net variance (highest loss) first
    
go
*/

go

select * from vw_category_shrinkage_audit
ORDER BY 
    location_name ASC,
    report_month_num ASC,
    net_total_variance_value_raw asc
