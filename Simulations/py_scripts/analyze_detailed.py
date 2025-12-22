from pathlib import Path
import re
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

def parse_dfise_plt(path: Path) -> pd.DataFrame:
    text = path.read_text()
    m_ds = re.search(r"datasets\s*=\s*\[(.*?)\]", text, re.S)
    dataset_block = m_ds.group(1)
    names = re.findall(r"\"([^\"]+)\"", dataset_block)
    
    m_data = re.search(r"Data\s*{(.*?)}", text, re.S)
    tokens = m_data.group(1).split()
    values = np.array([float(tok) for tok in tokens], dtype=float)
    data = values.reshape((-1, len(names)))
    return pd.DataFrame(data, columns=names)

# Read the data
df = parse_dfise_plt(Path("../1e6.plt"))

# Extract relevant columns
gate_col = "gate_contact OuterVoltage"
drain_col = "drain_contact TotalCurrent"
time_col = "time"

print("=" * 80)
print("DETAILED SIMULATION ANALYSIS")
print("=" * 80)
print(f"\nTotal data points: {len(df)}")
print(f"\nTime range: {df[time_col].min():.2e} to {df[time_col].max():.2e} seconds")
print(f"Gate voltage range: {df[gate_col].min():.4f} to {df[gate_col].max():.4f} V")
print(f"Drain current range: {df[drain_col].min():.4e} to {df[drain_col].max():.4e} A")

print(f"\n{'='*80}")
print("FIRST 10 DATA POINTS (Initial equilibrium):")
print(f"{'='*80}")
print(df[[time_col, gate_col, drain_col]].head(10).to_string(index=False))

print(f"\n{'='*80}")
print("MIDDLE SECTION (Gate voltage sweep):")
print(f"{'='*80}")
mid_point = len(df) // 2
print(df[[time_col, gate_col, drain_col]].iloc[mid_point-5:mid_point+5].to_string(index=False))

print(f"\n{'='*80}")
print("LAST 10 DATA POINTS (Final state):")
print(f"{'='*80}")
print(df[[time_col, gate_col, drain_col]].tail(10).to_string(index=False))

# Analyze current vs gate voltage
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

# Plot 1: Current vs Time
ax1.semilogy(df[time_col], np.abs(df[drain_col]))
ax1.set_xlabel('Time (s)')
ax1.set_ylabel('|Drain Current| (A)')
ax1.set_title('Drain Current vs Time')
ax1.grid(True, alpha=0.3)

# Plot 2: Current vs Gate Voltage
ax2.semilogy(df[gate_col], np.abs(df[drain_col]), 'o-', markersize=3)
ax2.set_xlabel('Gate Voltage (V)')
ax2.set_ylabel('|Drain Current| (A)')
ax2.set_title('Id-Vg Characteristic')
ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('../output_curves/detailed_analysis.png', dpi=300)
print(f"\n{'='*80}")
print("Plot saved to: output_curves/detailed_analysis.png")
print(f"{'='*80}")

# Check for hysteresis
gate_up = df[df[gate_col].diff() > 0]
gate_down = df[df[gate_col].diff() < 0]

if len(gate_up) > 0 and len(gate_down) > 0:
    print(f"\nHysteresis detected:")
    print(f"  Forward sweep points: {len(gate_up)}")
    print(f"  Reverse sweep points: {len(gate_down)}")
else:
    print(f"\nNo clear hysteresis - gate voltage monotonic")
