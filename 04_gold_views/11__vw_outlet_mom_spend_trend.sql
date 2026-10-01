/*
------------------------------------------------------------------------------------
Author: Rohit Dangwal
Project: Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)
Script Name: 08_vw_outlet_mom_spend_trend.sql
Created Date: 2026-09-30
Description: Advanced analytical view using window functions (LAG) to compute 
             Month-over-Month (MoM) changes in actual spend and waste value per outlet.
------------------------------------------------------------------------------------
*/

USE EnterpriseSupplyChainDW;
GO

DROP VIEW IF EXISTS vw_outlet_mom_spend_trend
GO

CREATE VIEW vw_outlet_mom_spend_trend AS
WITH MonthlyOutletSpend AS (
    SELECT 
        location_name,
        report_year,
        report_month_num,
        report_month_name,
        SUM(actual_consumption_value) AS current_actual_spend,
        SUM(waste_value) AS current_waste_value
    FROM dbo.fact_consumption
    GROUP BY location_name, report_year, report_month_num, report_month_name
)
SELECT 
    location_name,
    report_year,
    report_month_name,
    ROUND(current_actual_spend, 2) AS current_actual_spend,
    ROUND(LAG(current_actual_spend, 1) OVER (PARTITION BY location_name ORDER BY report_year, report_month_num), 2) AS prior_month_spend,
    ROUND(current_actual_spend - LAG(current_actual_spend, 1) OVER (PARTITION BY location_name ORDER BY report_year, report_month_num), 2) AS spend_variance_mom,
    ROUND(
        CASE 
            WHEN LAG(current_actual_spend, 1) OVER (PARTITION BY location_name ORDER BY report_year, report_month_num) > 0 
            THEN ((current_actual_spend - LAG(current_actual_spend, 1) OVER (PARTITION BY location_name ORDER BY report_year, report_month_num)) / LAG(current_actual_spend, 1) OVER (PARTITION BY location_name ORDER BY report_year, report_month_num)) * 100
            ELSE 0 
        END, 2) AS spend_growth_pct_mom
FROM MonthlyOutletSpend;
GO

SELECT * FROM vw_outlet_mom_spend_trend
