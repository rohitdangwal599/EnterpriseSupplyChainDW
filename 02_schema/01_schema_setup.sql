/*
===============================================================================
Script Name: 01_schema_setup.sql
Author: Rohit Dangwal
Database: EnterpriseSupplyChainDW
Description: Creates fact_inventory table with advanced pre-calculated financial 
             and shrinkage metrics.
===============================================================================
*/

USE EnterpriseSupplyChainDW;
GO

DROP TABLE IF EXISTS fact_inventory;
GO

CREATE TABLE fact_inventory (
    category_code               VARCHAR(255),
    stock_item_ref_id           VARCHAR(100),
    stock_item_name             VARCHAR(255),
    base_units                  VARCHAR(50),
    has_been_counted            VARCHAR(50),
    stock_on_hand               DECIMAL(18, 4),
    quantity_counted            DECIMAL(18, 4),
    stock_difference            DECIMAL(18, 4),
    cost_price                  DECIMAL(18, 4),
    inventory_value             DECIMAL(18, 4),
    -- ==========================================
    -- Pre-calculated Advanced Metrics (Python)
    -- ==========================================
    variance_value              DECIMAL(18, 4),
    counted_inventory_value     DECIMAL(18, 4),
    theoretical_inventory_value DECIMAL(18, 4),
    abs_stock_difference        DECIMAL(18, 4),
    variance_status             VARCHAR(50),
    -- ==========================================
    report_year                 INT,
    report_month_num            INT,
    report_month_name           VARCHAR(10),
    report_period               VARCHAR(255),
    location_name               VARCHAR(100)
);
GO
