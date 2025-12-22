#!/usr/bin/env python3
"""Compare old vs new simulation results to see changes."""

import sys
import re
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def parse_plt(plt_file):
    text = Path(plt_file).read_text()
    m_ds = re.search(r"datasets\s*=\s*\[(.*?)\]", text, re.S)
    dataset_block = m_ds.group(1)
    column_names = re.findall(r"\"([^\"]+)\"", dataset_block)
    m_data = re.search(r"Data\s*{(.*?)}", text, re.S)
    tokens = m_data.group(1).split()
    values = np.array([float(tok) for tok in tokens], dtype=float)
    num_cols = len(column_names)
    data = values.reshape((-1, num_cols))
    return pd.DataFrame(data, columns=column_names)

# Parse both files
df_old = parse_plt("../1e7.plt")
df_new = parse_plt("../1e7_final.plt")

vg_col = "gate_contact OuterVoltage"
id_col = "drain_contact TotalCurrent"

# Extract forward sweep (Vg increasing)
vg_old = df_old[vg_col].values
id_old = np.abs(df_old[id_col].values)

vg_new = df_new[vg_col].values
id_new = np.abs(df_new[id_col].values)

# Find forward sweep
old_fwd_idx = np.where(np.diff(vg_old) > 1e-6)[0]
new_fwd_idx = np.where(np.diff(vg_new) > 1e-6)[0]

vg_old_fwd = vg_old[old_fwd_idx]
id_old_fwd = id_old[old_fwd_idx]

vg_new_fwd = vg_new[new_fwd_idx]
id_new_fwd = id_new[new_fwd_idx]

# Convert to V_SG
vsg_old = -vg_old_fwd
vsg_new = -vg_new_fwd

# Create comparison plot
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

# Linear scale
ax1.plot(vsg_old, id_old_fwd, 'b-', linewidth=2.5, label='Old (d0=1e7, Vds=1.0V, b=1.5e6/2e6)')
ax1.plot(vsg_new, id_new_fwd, 'r--', linewidth=2.5, label='New (d0=1e7, Vds=1.5V, b=8e5/1e6)')
ax1.set_xlabel('$V_{SG}$ (V)', fontsize=13)
ax1.set_ylabel('$|I_D|$ (A)', fontsize=13)
ax1.set_title('Linear Scale Comparison', fontsize=14, fontweight='bold')
ax1.legend(fontsize=10)
ax1.grid(True, alpha=0.3)
ax1.invert_xaxis()

# Log scale
ax2.semilogy(vsg_old, id_old_fwd, 'b-', linewidth=2.5, label='Old')
ax2.semilogy(vsg_new, id_new_fwd, 'r--', linewidth=2.5, label='New')
ax2.set_xlabel('$V_{SG}$ (V)', fontsize=13)
ax2.set_ylabel('$|I_D|$ (A)', fontsize=13)
ax2.set_title('Log Scale Comparison', fontsize=14, fontweight='bold')
ax2.legend(fontsize=10)
ax2.grid(True, alpha=0.3, which='both')
ax2.invert_xaxis()

plt.tight_layout()
plt.savefig('../output_curves/old_vs_new_comparison.png', dpi=300, bbox_inches='tight')
print("Saved: ../output_curves/old_vs_new_comparison.png")

# Calculate metrics
print("\n" + "="*70)
print("COMPARISON ANALYSIS")
print("="*70)
print(f"\nOLD (1e7.plt):")
print(f"  I_ON:  {np.max(id_old_fwd):.3e} A")
print(f"  I_OFF: {np.min(id_old_fwd):.3e} A")
print(f"  I_ON/I_OFF: {np.max(id_old_fwd)/np.min(id_old_fwd):.2e}")

print(f"\nNEW (1e7_final.plt):")
print(f"  I_ON:  {np.max(id_new_fwd):.3e} A")
print(f"  I_OFF: {np.min(id_new_fwd):.3e} A")
print(f"  I_ON/I_OFF: {np.max(id_new_fwd)/np.min(id_new_fwd):.2e}")

print(f"\nCHANGES:")
print(f"  I_ON change: {((np.max(id_new_fwd) - np.max(id_old_fwd))/np.max(id_old_fwd)*100):.1f}%")
print(f"  I_OFF improvement: {np.min(id_old_fwd)/np.min(id_new_fwd):.1e}x lower")
print("="*70)

# Check for kink effect (abrupt slope change)
# Calculate d(log I)/d(Vsg) - should show spike if kink present
if len(vsg_new) > 10:
    log_id = np.log10(id_new_fwd + 1e-30)
    d_log_id = np.gradient(log_id, vsg_new)
    
    # Find maximum slope change
    slope_std = np.std(d_log_id)
    slope_max = np.max(np.abs(d_log_id))
    slope_mean = np.mean(np.abs(d_log_id))
    
    print(f"\nKINK EFFECT ANALYSIS:")
    print(f"  Slope variability (std): {slope_std:.2f}")
    print(f"  Max slope magnitude: {slope_max:.2f}")
    print(f"  Mean slope magnitude: {slope_mean:.2f}")
    
    if slope_std > 5 or slope_max > 20:
        print("  >>> KINK EFFECT DETECTED: High slope variation!")
    else:
        print("  >>> NO KINK: Smooth exponential transition")
    print("="*70)
