import os
import pandas as pd

SOURCE_DIR = r"F:\Desktop\Report\To Append Variance Reports"
PROCESSED_FILE = r"F:\Desktop\Report\enterprise_inventory_dw\data\processed\all_locations_inventory.csv"

outlet_mapping = {
    "Mainstore": "Mainstore",
    "Cockerel Bar": "Outlet_CB",
    "Housekeeping": "Outlet_HK",
    "Merill Restaurant": "Outlet_MR",
    "Porto Bar": "Outlet_PR",
    "Porto Kitchen": "Outlet_PK"
}

print("--- Starting Full Multi-Department Trust Audit ---\n")

if not os.path.exists(PROCESSED_FILE):
    print("Error: Master dataset not found.")
    exit()

master_df = pd.read_csv(PROCESSED_FILE)
audit_summary = []

for folder_name, anonymized_name in outlet_mapping.items():
    folder_path = os.path.join(SOURCE_DIR, folder_name, "2025")
    
    if os.path.exists(folder_path):
        files = [f for f in os.listdir(folder_path) if f.lower().endswith(('.xlsx', '.xls'))]
        if files:
            # Pick a sample file (e.g., January) for this department
            test_file = files[0]
            test_path = os.path.join(folder_path, test_file)
            
            try:
                # 1. Dynamically read raw and find header
                raw_df = pd.read_excel(test_path, header=None)
                header_idx = 0
                for idx, row in raw_df.iterrows():
                    row_vals = [str(val).strip().lower() for val in row.values]
                    if any('stock item' in val or 'item code' in val or 'description' in val for val in row_vals):
                        header_idx = idx
                        break
                
                # 2. Extract clean expected count
                clean_raw = pd.read_excel(test_path, header=header_idx).dropna(how='all')
                clean_raw_str = clean_raw.astype(str)
                mask = ~clean_raw_str.apply(lambda col: col.str.lower().str.contains('total|inventory status|committed|rvc name', na=False)).any(axis=1)
                expected_count = len(clean_raw[mask])
                
                # 3. Check master dataset count for this specific file & location
                actual_count = len(master_df[(master_df['location_name'] == anonymized_name) & (master_df['report_period'] == test_file)])
                
                status = "MATCH PERFECT ✅" if expected_count == actual_count else "MISMATCH ❌"
                audit_summary.append({
                    "Department": folder_name,
                    "Expected Rows": expected_count,
                    "Actual Rows": actual_count,
                    "Status": status
                })
            except Exception as e:
                audit_summary.append({
                    "Department": folder_name,
                    "Expected Rows": "Error",
                    "Actual Rows": "Error",
                    "Status": f"Failed: {e}"
                })

# Print clean audit report table
audit_df = pd.DataFrame(audit_summary)
print(audit_df.to_string(index=False))
print("\n--- Full Audit Complete ---")
