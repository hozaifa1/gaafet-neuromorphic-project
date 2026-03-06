import os
import re
import pandas as pd

def parse_ise_text(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    # Find datasets definition
    datasets_start = -1
    datasets_end = -1
    data_start = -1
    
    for i, line in enumerate(lines):
        if 'datasets  = [' in line:
            datasets_start = i
        if ']' in line and datasets_start != -1 and datasets_end == -1:
            datasets_end = i
        if 'Data {' in line:
            data_start = i
            break
            
    if datasets_start == -1 or data_start == -1:
        print(f"Error parsing structure in {filepath}")
        return None

    # Parse column names
    # Join lines between datasets_start and datasets_end
    dataset_str = "".join(lines[datasets_start:datasets_end+1])
    # Remove 'datasets = [' and ']'
    dataset_str = dataset_str.replace('datasets  = [', '').replace(']', '').strip()
    # Split by quotes
    columns = re.findall(r'"([^"]+)"', dataset_str)
    
    # Parse data
    # Data values are just a stream of numbers after "Data {"
    # We need to skip "Data {" line and read until "}"
    
    data_values = []
    # Combine all lines after data_start
    data_content = "".join(lines[data_start+1:]).replace('}', '').strip()
    # Split by whitespace
    data_values = data_content.split()
    
    # Convert to floats
    try:
        data_values = [float(x) for x in data_values]
    except ValueError as e:
        print(f"Error converting data to float: {e}")
        return None
        
    # Reshape
    num_cols = len(columns)
    num_rows = len(data_values) // num_cols
    
    if len(data_values) % num_cols != 0:
        print(f"Warning: Data length {len(data_values)} not divisible by columns {num_cols}")
        # Truncate to fit
        data_values = data_values[:num_rows * num_cols]
        
    # Create DataFrame
    data_matrix = []
    for i in range(num_rows):
        row = data_values[i*num_cols : (i+1)*num_cols]
        data_matrix.append(row)
        
    df = pd.DataFrame(data_matrix, columns=columns)
    return df

def main():
    base_dir = r"f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations\calibration outputs"
    files = ["read_leg1_n5_des.txt", "read_leg2_n5_des.txt", "read_leg3_n5_des.txt"]
    
    dfs = []
    for file in files:
        path = os.path.join(base_dir, file)
        if os.path.exists(path):
            print(f"Processing {file}...")
            df = parse_ise_text(path)
            if df is not None:
                dfs.append(df)
        else:
            print(f"File not found: {path}")

    if not dfs:
        print("No data found.")
        return

    full_df = pd.concat(dfs, ignore_index=True)
    
    # Identify columns
    # We look for Gate Voltage, Drain Current, Polarization
    
    # Columns likely names:
    # "gate_contact OuterVoltage"
    # "drain_contact TotalCurrent"
    # "Pos(0,0.0145) Polarization/y" (Assuming Y is the direction, or we check magnitude)
    
    cols = full_df.columns.tolist()
    print("Columns found:", cols)
    
    gate_v_col = next((c for c in cols if "gate_contact OuterVoltage" in c), None)
    drain_i_col = next((c for c in cols if "drain_contact TotalCurrent" in c), None)
    
    # Find polarization columns
    pol_cols = [c for c in cols if "Polarization" in c]
    print("Polarization columns:", pol_cols)
    
    # Assuming the user wants the total magnitude or the dominant component. 
    # Usually Y is dominant in vertical stacks. Let's calculate magnitude just in case? 
    # Or just export all found polarization columns.
    # The request says "y-axis: polarization".
    # We will assume Polarization/y is the main one if it exists, otherwise check values.
    
    pol_y_col = next((c for c in pol_cols if "/y" in c), None)
    if not pol_y_col and pol_cols:
        pol_y_col = pol_cols[0]
        
    if not gate_v_col or not drain_i_col or not pol_y_col:
        print("Could not identify required columns.")
        return

    # Extract File 1: Voltage vs Polarization
    # Units: Voltage (V), Polarization (uC/cm^2)
    # Sentaurus Pol is usually C/cm^2.
    # Convert to uC/cm^2 by multiplying by 1e6.
    
    df_pol = pd.DataFrame()
    df_pol["Voltage"] = full_df[gate_v_col]
    
    # Check if we should use X or Y or Magnitude
    # Let's inspect the means
    pol_x_col = next((c for c in pol_cols if "/x" in c), None)
    
    if pol_x_col:
        val_x = full_df[pol_x_col].abs().mean()
        val_y = full_df[pol_y_col].abs().mean()
        print(f"Mean Abs Pol X: {val_x}, Mean Abs Pol Y: {val_y}")
        if val_x > val_y * 10:
             target_pol_col = pol_x_col
        else:
             target_pol_col = pol_y_col
    else:
        target_pol_col = pol_y_col
        
    df_pol["Polarization"] = full_df[target_pol_col] * 1e6 # Convert to uC/cm^2
    
    pol_file = os.path.join(base_dir, "polarization_vs_voltage.csv")
    df_pol.to_csv(pol_file, index=False)
    print(f"Written {pol_file}")

    # Extract File 2: Hysteresis (Id vs Vg)
    # y-axis: drain current, x-axis: gate voltage (Wait, standard hysteresis is Id-Vg)
    # The prompt says "hysteresis (drain current and gate voltage) curve"
    # Usually X=Vg, Y=Id.
    
    df_hyst = pd.DataFrame()
    df_hyst["Gate Voltage"] = full_df[gate_v_col]
    df_hyst["Drain Current"] = full_df[drain_i_col]
    
    hyst_file = os.path.join(base_dir, "hysteresis_id_vg.csv")
    df_hyst.to_csv(hyst_file, index=False)
    print(f"Written {hyst_file}")

if __name__ == "__main__":
    main()
