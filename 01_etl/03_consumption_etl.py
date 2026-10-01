"""
Enterprise Consumption ETL Pipeline
Automates ingestion of multi-outlet POS usage reports from source directory, 
performs row-level theoretical vs. actual variance calculations, cleans floating-point artifacts, 
and safely loads clean facts into SQL Server with automatic schema recreation.
"""

import os
import re
import glob
import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text
from sqlalchemy.types import String, Float, Integer, Date

# --- Configuration & Paths ---
SOURCE_DIR = r"F:\Desktop\Report\To Append Consumption Reports"

# Reliable connection structure proven by inventory.py
SERVER = r"localhost"
DATABASE = "EnterpriseSupplyChainDW"
DRIVER = "ODBC Driver 17 for SQL Server"
DB_CONN_STR = f"mssql+pyodbc://@{SERVER}/{DATABASE}?driver={DRIVER}&trusted_connection=yes"

# Updated Department / Location Mapping
DEPT_MAPPING = {
    "Breakfast": "Breakfast",
    "Cockerel Bar": "Outlet_CB",
    "Housekeeping": "Outlet_HK",
    "Merill Restaurant": "Outlet_MR",
    "Porto Bar": "Outlet_PB",
    "Porto Kitchen": "Outlet_PK",
    "Kitchen": "Kitchen",
    "Staff Meal": "Staff Meal"
}

def parse_filename_metadata(filename):
    """Extracts report year, month number, and name from standardized file naming convention."""
    base_name = os.path.basename(filename)
    match = re.search(r'(\d{4})-(\d{2})-\d{2}', base_name)
    if match:
        year = int(match.group(1))
        month_num = int(match.group(2))
        month_name = pd.to_datetime(f"{year}-{month_num:02d}-01").strftime('%b')
        return year, month_num, month_name
    return 2025, 1, 'Jan'

def find_header_row(file_path):
    """Dynamically finds the header row containing key column identifiers."""
    xls = pd.ExcelFile(file_path)
    df_raw = pd.read_excel(file_path, sheet_name=xls.sheet_names[0], header=None)
    
    for idx, row in df_raw.iterrows():
        row_str = str(row.values).lower()
        if 'ref id' in row_str or 'item name' in row_str:
            return idx
    return 13 # Default fallback based on structure analysis

def process_consumption_file(file_path):
    """Reads, cleans, and transforms a single consumption Excel report."""
    header_idx = find_header_row(file_path)
    xls = pd.ExcelFile(file_path)
    df = pd.read_excel(file_path, sheet_name=xls.sheet_names[0], header=header_idx)
    
    # Identify location name from file path or name based on mapping values
    location_name = "Unknown"
    for key, mapped_val in DEPT_MAPPING.items():
        if key.lower() in file_path.lower():
            location_name = mapped_val
            break
            
    # Clean up column names (strip whitespaces/newlines)
    df.columns = [str(col).replace('\n', ' ').strip() for col in df.columns]
    
    # Standardize column mappings based on position/names
    col_map = {}
    for col in df.columns:
        c_low = col.lower()
        if 'maingroup' in c_low or 'main group' in c_low: col_map[col] = 'main_group'
        elif 'category' in c_low: col_map[col] = 'category'
        elif 'ref id' in c_low: col_map[col] = 'ref_id'
        elif 'item name' in c_low: col_map[col] = 'item_name'
        elif 'base unit' in c_low: col_map[col] = 'base_unit'
        elif 'opening' in c_low and 'stock' in c_low: col_map[col] = 'opening_stock'
        elif 'stock movement' in c_low: col_map[col] = 'stock_movement'
        elif 'counted' in c_low: col_map[col] = 'stock_counted'
        
    df = df.rename(columns=col_map)
    
    # Drop rows missing critical item identifiers
    if 'ref_id' in df.columns:
        df = df.dropna(subset=['ref_id'])
    
    # Purge summary/total rows
    if 'main_group' in df.columns:
        df = df[~df['main_group'].astype(str).str.contains('Total|Summary|Status', case=False, na=False)]
    if 'item_name' in df.columns:
        df = df[~df['item_name'].astype(str).str.contains('Total|Summary', case=False, na=False)]
        
    # Forward fill hierarchical dimensions
    if 'main_group' in df.columns:
        df['main_group'] = df['main_group'].ffill()
    if 'category' in df.columns:
        df['category'] = df['category'].ffill()
        
    raw_vals = df.values
    processed_rows = []
    
    for row in raw_vals:
        try:
            mg = str(row[2]) if len(row) > 2 and pd.notna(row[2]) else 'Unassigned'
            cat = str(row[3]) if len(row) > 3 and pd.notna(row[3]) else 'Unassigned'
            ref = str(row[4]) if len(row) > 4 and pd.notna(row[4]) else ''
            item = str(row[6]) if len(row) > 6 and pd.notna(row[6]) else ''
            unit = str(row[7]) if len(row) > 7 and pd.notna(row[7]) else 'Each'
            
            if not ref or 'Total' in mg or 'Total' in item:
                continue
                
            op_stock = float(row[9]) if len(row) > 9 and pd.notna(row[9]) else 0.0
            stk_move = float(row[10]) if len(row) > 10 and pd.notna(row[10]) else 0.0
            stk_count = float(row[12]) if len(row) > 12 and pd.notna(row[12]) else 0.0
            
            act_qty = float(row[14]) if len(row) > 14 and pd.notna(row[14]) else 0.0
            act_val = float(row[15]) if len(row) > 15 and pd.notna(row[15]) else 0.0
            
            theo_qty = float(row[17]) if len(row) > 17 and pd.notna(row[17]) else 0.0
            theo_val = float(row[18]) if len(row) > 18 and pd.notna(row[18]) else 0.0
            
            waste_qty = float(row[19]) if len(row) > 19 and pd.notna(row[19]) else 0.0
            waste_val = float(row[20]) if len(row) > 20 and pd.notna(row[20]) else 0.0
            
            processed_rows.append({
                'location_name': location_name,
                'main_group': mg,
                'category': cat,
                'ref_id': ref,
                'item_name': item,
                'base_unit': unit,
                'opening_stock': op_stock,
                'stock_movement': stk_move,
                'stock_counted': stk_count,
                'actual_qty_consumed': act_qty,
                'actual_consumption_value': act_val,
                'theoretical_qty': theo_qty,
                'theoretical_value': theo_val,
                'waste_qty': waste_qty,
                'waste_value': waste_val
            })
        except Exception:
            continue
            
    clean_df = pd.DataFrame(processed_rows)
    if clean_df.empty:
        return clean_df
        
    # --- Row-Level Calculations ---
    clean_df['total_stock_input'] = clean_df['opening_stock'] + clean_df['stock_movement']
    clean_df['qty_variance'] = clean_df['actual_qty_consumed'] - clean_df['theoretical_qty']
    clean_df['value_variance'] = clean_df['actual_consumption_value'] - clean_df['theoretical_value']
    
    clean_df['unit_cost_actual'] = np.where(
        clean_df['actual_qty_consumed'] > 0,
        clean_df['actual_consumption_value'] / clean_df['actual_qty_consumed'],
        0.0
    )
    
    clean_df['stock_utilization_ratio'] = np.where(
        clean_df['total_stock_input'] > 0,
        clean_df['actual_qty_consumed'] / clean_df['total_stock_input'],
        0.0
    )
    
    clean_df['waste_cost_percentage'] = np.where(
        clean_df['actual_consumption_value'] > 0,
        (clean_df['waste_value'] / clean_df['actual_consumption_value']) * 100,
        0.0
    )
    
    # Metadata Enrichment
    yr, m_num, m_name = parse_filename_metadata(file_path)
    clean_df['report_year'] = yr
    clean_df['report_month_num'] = m_num
    clean_df['report_month_name'] = m_name
    clean_df['period_start_date'] = f"{yr}-{m_num:02d}-01"
    clean_df['period_end_date'] = pd.to_datetime(clean_df['period_start_date']) + pd.offsets.MonthEnd(0)
    
    # --- Clean Floating-Point Artifacts to Prevent SQL Overflow ---
    numeric_cols_to_clean = [
        'opening_stock', 'stock_movement', 'stock_counted', 
        'actual_qty_consumed', 'actual_consumption_value', 
        'theoretical_qty', 'theoretical_value', 'waste_qty', 'waste_value',
        'total_stock_input', 'qty_variance', 'value_variance', 
        'unit_cost_actual', 'stock_utilization_ratio', 'waste_cost_percentage'
    ]
    
    for col in numeric_cols_to_clean:
        if col in clean_df.columns:
            clean_df[col] = pd.to_numeric(clean_df[col], errors='coerce').fillna(0.0).round(4)
            clean_df[col] = np.where(clean_df[col].abs() < 1e-5, 0.0, clean_df[col])

    return clean_df

def run_consumption_etl():
    engine = create_engine(DB_CONN_STR)
    
    # Drop existing table to clear out old restrictive column schemas once and for all
    print("Resetting 'fact_consumption' table schema in SQL Server...")
    with engine.begin() as conn:
        conn.execute(text("DROP TABLE IF EXISTS fact_consumption"))

    # Explicit SQL Type mapping to force clean FLOAT definitions
    sql_dtypes = {
        'location_name': String(100),
        'main_group': String(100),
        'category': String(100),
        'ref_id': String(50),
        'item_name': String(255),
        'base_unit': String(50),
        'opening_stock': Float(),
        'stock_movement': Float(),
        'stock_counted': Float(),
        'actual_qty_consumed': Float(),
        'actual_consumption_value': Float(),
        'theoretical_qty': Float(),
        'theoretical_value': Float(),
        'waste_qty': Float(),
        'waste_value': Float(),
        'total_stock_input': Float(),
        'qty_variance': Float(),
        'value_variance': Float(),
        'unit_cost_actual': Float(),
        'stock_utilization_ratio': Float(),
        'waste_cost_percentage': Float(),
        'report_year': Integer(),
        'report_month_num': Integer(),
        'report_month_name': String(20),
        'period_start_date': Date(),
        'period_end_date': Date()
    }

    search_pattern = os.path.join(SOURCE_DIR, "**", "*.xlsx")
    files = glob.glob(search_pattern, recursive=True)
    
    print(f"Found {len(files)} consumption report files to process in {SOURCE_DIR}.")
    total_loaded_rows = 0
    
    for file_path in files:
        print(f"Processing: {os.path.basename(file_path)}")
        df_transformed = process_consumption_file(file_path)
        
        if not df_transformed.empty:
            row_count = len(df_transformed)
            df_transformed.to_sql(
                'fact_consumption', 
                con=engine, 
                if_exists='append', 
                index=False, 
                dtype=sql_dtypes,
                chunksize=500
            )
            total_loaded_rows += row_count
            print(f" -> Successfully loaded {row_count} rows.")
        else:
            print(" -> Warning: File yielded 0 valid rows.")
            
    print(f"\nETL Pipeline Complete. Total rows loaded across all files: {total_loaded_rows}")

if __name__ == "__main__":
    run_consumption_etl()
