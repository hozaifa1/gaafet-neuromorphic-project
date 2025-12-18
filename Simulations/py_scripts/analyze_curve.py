
import re
import pandas as pd
import numpy as np

def parse_dfise_plt(path):
    with open(path, 'r') as f:
        text = f.read()
    
    m_ds = re.search(r"datasets\s*=\s*\[(.*?)\]", text, re.S)
    if not m_ds: raise ValueError("datasets not found")
    names = re.findall(r"\"([^\"]+)\"", m_ds.group(1))
    
    m_data = re.search(r"Data\s*{(.*?)}", text, re.S)
    if not m_data: raise ValueError("Data not found")
    
    values = np.array([float(x) for x in m_data.group(1).split()])
    data = values.reshape((-1, len(names)))
    return pd.DataFrame(data, columns=names)

df = parse_dfise_plt('Simulations/n2_des.plt')
x_col = "gate_contact OuterVoltage"
y_col = "drain_contact TotalCurrent"

if x_col not in df.columns or y_col not in df.columns:
    print("Columns not found. Available:", df.columns)
    exit()

# Sort by Gate Voltage
df = df.sort_values(by=x_col)
vg = df[x_col].values
id = df[y_col].abs().values

# Metrics
i_off = id.min()
i_on = id.max()
max_gm = np.gradient(id, vg).max()

# Simple Vth extraction (Constant Current Method @ 1e-7 W/L approx, let's just find Vg @ 1e-7 for now or similar)
# Workflow mentions Ith = 94 nA = 9.4e-8 A
target_ith = 94e-9
# Find Vg closest to target_ith
idx = (np.abs(id - target_ith)).argmin()
vth_est = vg[idx]
curr_at_vth = id[idx]

print(f"Analysis of {y_col} vs {x_col}:")
print(f"Range Vg: {vg.min():.2f} V to {vg.max():.2f} V")
print(f"I_off (min current): {i_off:.2e} A")
print(f"I_on (max current): {i_on:.2e} A")
print(f"Vth (approx @ 94nA): {vth_est:.4f} V (Current: {curr_at_vth:.2e} A)")
print(f"Max Transconductance (gm): {max_gm:.2e} S")

# Check for hysteresis (if loop)
if vg[0] == vg[-1]: # Closed loop
    print("Loop detected.")
else:
    print("Single sweep detected.")
