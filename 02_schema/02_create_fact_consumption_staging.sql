/*
------------------------------------------------------------------------------------
Author: Rohit Dangwal
Project: Enterprise Supply Chain Data Warehouse (EnterpriseSupplyChainDW)
Script Name: 01_create_fact_consumption_staging.sql
Created Date: 2026-09-30
Description: Establishes the core fact table structure for multi-outlet consumption 
             reports. Drops and recreates the table to maintain an immutable schema 
             contract for automated Python pandas-to-SQL data ingestion pipelines, 
             including native difference tracking metrics.
------------------------------------------------------------------------------------
*/

-- Ensure correct database context
USE EnterpriseSupplyChainDW;
GO

IF OBJECT_ID('dbo.fact_consumption', 'U') IS NOT NULL
    DROP TABLE dbo.fact_consumption;
GO

CREATE TABLE fact_consumption (
    consumption_id INT IDENTITY(1,1) PRIMARY KEY,
    location_name VARCHAR(50) NOT NULL,
    main_group VARCHAR(100),
    category VARCHAR(100),
    ref_id VARCHAR(50) NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    base_unit VARCHAR(50),
    
    -- Raw Operational Metrics
    opening_stock DECIMAL(18,4) DEFAULT 0,
    stock_movement DECIMAL(18,4) DEFAULT 0,
    total_stock_input DECIMAL(18,4) DEFAULT 0,
    stock_counted DECIMAL(18,4) DEFAULT 0,
    
    -- Actual vs Theoretical (Recipe) & Native Report Metrics
    actual_qty_consumed DECIMAL(18,4) DEFAULT 0,
    actual_consumption_value DECIMAL(18,4) DEFAULT 0,
    theoretical_qty DECIMAL(18,4) DEFAULT 0,
    theoretical_value DECIMAL(18,4) DEFAULT 0,
    waste_qty DECIMAL(18,4) DEFAULT 0,
    waste_value DECIMAL(18,4) DEFAULT 0,
    difference_qty DECIMAL(18,4) DEFAULT 0,          -- Native Report Difference Qty
    difference_value DECIMAL(18,4) DEFAULT 0,        -- Native Report Difference Value
    
    -- Pre-Calculated Row-Level Analytics
    qty_variance DECIMAL(18,4) DEFAULT 0,            -- Calculated Actual minus Theoretical Qty
    value_variance DECIMAL(18,4) DEFAULT 0,          -- Calculated Actual minus Theoretical Value
    unit_cost_actual DECIMAL(18,4) DEFAULT 0,        -- Effective Unit Cost
    stock_utilization_ratio DECIMAL(10,4) DEFAULT 0, -- % of stock used
    waste_cost_percentage DECIMAL(10,4) DEFAULT 0,   -- Waste % of consumption
    
    -- Temporal Metadata
    report_year INT NOT NULL,
    report_month_num INT NOT NULL,
    report_month_name VARCHAR(10) NOT NULL,
    period_start_date DATE,
    period_end_date DATE,
    loaded_at DATETIME DEFAULT GETDATE()
);

PRINT 'Table fact_consumption created successfully with native difference metrics in EnterpriseSupplyChainDW.';
GO
