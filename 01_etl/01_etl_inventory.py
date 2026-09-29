import os
import re
import calendar
import pandas as pd
import numpy as np  # <-- Added for the variance_status categorical logic
from sqlalchemy import create_engine

# --- Configuration & Paths ---
SOURCE_DIR = r"F:\Desktop\Report\To Append Variance Reports"
PROCESSED_DIR = r"F:\Desktop\Report\enterprise_inventory_dw\data\processed"
os.makedirs(PROCESSED_DIR, exist_ok=True)

SERVER = r"localhost"
DATABASE = "EnterpriseSupplyChainDW"
DRIVER = "ODBC Driver 17 for SQL Server"
connection_string = f"mssql+pyodbc://@{SERVER}/{DATABASE}?driver={DRIVER}&trusted_connection=yes"

outlet_mapping = {
    "Mainstore": "Mainstore",
    "Cockerel Bar": "Outlet_CB",
    "Housekeeping": "Outlet_HK",
    "Merill Restaurant": "Outlet_MR",
    "Porto Bar": "Outlet_PB",
    "Porto Kitchen": "Outlet_PK"
}

all_data = []

print("--- Starting ETL Pipeline with Advanced Pre-calculated Metrics ---")

for folder_name, anonymized_name in outlet_mapping.items():
    folder_path = os.path.join(SOURCE_DIR, folder_name, "2025")
    
    if os.path.exists(folder_path):
        files = [os.path.join(folder_path, f) for f in os.listdir(folder_path) if f.lower().endswith(('.xlsx', '.xls'))]
        print(f"Processing {folder_name}: {len(files)} files found")
        
        for file in files:
            file_name = os.path.basename(file)
            try:
                # 1. Dynamically find header row
                raw_df = pd.read_excel(file, header=None)
                header_row = 0
                for idx, row in raw_df.iterrows():
                    row_vals = [str(val).strip().lower() for val in row.values]
                    if any('stock item' in val or 'item code' in val or 'description' in val for val in row_vals):
                        header_row = idx
                        break
                
                # 2. Re-read with correct header
                df = pd.read_excel(file, header=header_row)
                df = df.dropna(how='all')
                
                # Standardize column names
                df.columns = [str(col).strip().lower().replace(' ', '_').replace('-', '_') for col in df.columns]
                df = df.loc[:, ~df.columns.astype(str).str.contains('^unnamed', case=False, na=False)]
                
                # 3. Purge summary/total rows safely
                df_str = df.astype(str)
                mask_keep = ~df_str.apply(lambda col: col.str.lower().str.contains('total|inventory status|committed|rvc name', na=False)).any(axis=1)
                df = df[mask_keep]
                
                # 4. Forward-fill category column
                if len(df.columns) > 0:
                    cat_col = df.columns[0]
                    for col in df.columns:
                        if 'cat' in col:
                            cat_col = col
                            break
                    df[cat_col] = df[cat_col].ffill()
                
                # 5. Automatically extract Year, Month Number, and Month Name
                match = re.search(r'IR(\d{4})-(\d{2})-(\d{2})', file_name)
                if match:
                    df['report_year'] = int(match.group(1))
                    month_num = int(match.group(2))
                    df['report_month_num'] = month_num
                    df['report_month_name'] = calendar.month_abbr[month_num]
                else:
                    df['report_year'] = None
                    df['report_month_num'] = None
                    df['report_month_name'] = None
                
                # 6. Type Casting for numeric values
                numeric_cols = ['stock_on_hand', 'quantity_counted', 'stock_difference', 'cost_price', 'inventory_value']
                for col in numeric_cols:
                    if col in df.columns:
                        df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0.0)
                
                # 7. Pre-calculate ALL advanced row-level metrics
                df['variance_value'] = df['stock_difference'] * df['cost_price']
                df['counted_inventory_value'] = df['quantity_counted'] * df['cost_price']
                df['theoretical_inventory_value'] = df['stock_on_hand'] * df['cost_price']
                df['abs_stock_difference'] = df['stock_difference'].abs()
                
                # Categorical status flag
                conditions = [
                    df['stock_difference'] < 0,
                    df['stock_difference'] > 0
                ]
                choices = ['Shortage / Shrinkage', 'Surplus / Over-count']
                df['variance_status'] = np.select(conditions, choices, default='Balanced')
                
                # Metadata tracking
                df['report_period'] = file_name
                df['location_name'] = anonymized_name
                
                all_data.append(df)
            except Exception as e:
                print(f"Error in file {file_name}: {e}")

# --- Combine & Load to SQL Server ---
if all_data:
    master_df = pd.concat(all_data, ignore_index=True)
    master_df = master_df.drop_duplicates()
    
    output_file = os.path.join(PROCESSED_DIR, "all_locations_inventory.csv")
    master_df.to_csv(output_file, index=False)
    
    print(f"Loading data into SQL Server [{DATABASE}]...")
    try:
        engine = create_engine(connection_string)
        master_df.to_sql(name="fact_inventory", con=engine, if_exists='append', index=False, chunksize=10000)
        print("Success! Data loaded with all advanced pre-calculated metrics.")
    except Exception as sql_err:
        print(f"SQL Load Error: {sql_err}")
else:
    print("Warning: No data collected.")

print("--- Pipeline Complete ---")
