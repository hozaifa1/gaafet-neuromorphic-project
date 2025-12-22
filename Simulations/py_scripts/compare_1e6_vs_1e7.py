#!/usr/bin/env python3
"""
Compare 1e6_final vs 1e7_final to verify d0 parameter effects.
Creates clear, readable comparison plots.
"""

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

def extract_forward_sweep(df, vg_col, id_col):
    vg = df[vg_col].values
    id_drain = df[id_col].values
    
    # Find forward sweep (Vg increasing)
    forward_idx = np.where(np.diff(vg) > 1e-6)[0]
    
    if len(forward_idx) == 0:
        vsg = -vg
        return vsg, np.abs(id_drain)
    
    vg_forward = vg[forward_idx]
    id_forward = id_drain[forward_idx]
    
    vsg = -vg_forward  # Convert to V_SG
    return vsg, np.abs(id_forward)

# Parse both files
vg_col = "gate_contact OuterVoltage"
id_col = "drain_contact TotalCurrent"

df_1e6 = parse_plt("../1e6_final.plt")
df_1e7 = parse_plt("../1e7_final.plt")

vsg_1e6, id_1e6 = extract_forward_sweep(df_1e6, vg_col, id_col)
vsg_1e7, id_1e7 = extract_forward_sweep(df_1e7, vg_col, id_col)

# Calculate metrics
i_on_1e6 = np.max(id_1e6)
i_off_1e6 = np.min(id_1e6)
i_on_1e7 = np.max(id_1e7)
i_off_1e7 = np.min(id_1e7)

print("\n" + "="*70)
print("COMPARISON: 1e6_final vs 1e7_final")
print("="*70)
print(f"\n1e6_final (d0=1e6):")
print(f"  I_ON:  {i_on_1e6:.3e} A")
print(f"  I_OFF: {i_off_1e6:.3e} A")
print(f"  I_ON/I_OFF: {i_on_1e6/i_off_1e6:.2e}")

print(f"\n1e7_final (d0=1e7):")
print(f"  I_ON:  {i_on_1e7:.3e} A")
print(f"  I_OFF: {i_off_1e7:.3e} A")
print(f"  I_ON/I_OFF: {i_on_1e7/i_off_1e7:.2e}")

print(f"\nDIFFERENCES:")
diff_pct = ((i_on_1e7 - i_on_1e6) / i_on_1e6) * 100
print(f"  I_ON difference: {diff_pct:+.1f}% (1e7 vs 1e6)")
print(f"  I_OFF ratio: {i_off_1e6/i_off_1e7:.1f}x (1e6 is higher)")

# Check if results are actually different
if np.allclose(id_1e6, id_1e7, rtol=1e-3):
    print("\n⚠️  WARNING: Results are nearly IDENTICAL!")
    print("    → d0 parameter is NOT having expected effect")
else:
    print("\n✓ CONFIRMED: Results are DIFFERENT")
    print("    → d0 parameter is working correctly")

print("="*70)

# Create comparison plot - 3 subplots
fig, axes = plt.subplots(1, 3, figsize=(18, 5))

# Subplot 1: Linear scale
ax1 = axes[0]
ax1.plot(vsg_1e6, id_1e6, 'b-', linewidth=3, label='d0=1e6 (weaker impact ionization)', marker='o', markersize=3, markevery=20)
ax1.plot(vsg_1e7, id_1e7, 'r-', linewidth=3, label='d0=1e7 (stronger impact ionization)', marker='s', markersize=3, markevery=20)
ax1.set_xlabel('$V_{SG}$ (V)', fontsize=14, fontweight='bold')
ax1.set_ylabel('$|I_D|$ (A)', fontsize=14, fontweight='bold')
ax1.set_title('Linear Scale Comparison', fontsize=15, fontweight='bold')
ax1.legend(fontsize=11, loc='upper left')
ax1.grid(True, alpha=0.3, linewidth=1.2)
ax1.tick_params(labelsize=11)

# Subplot 2: Log scale
ax2 = axes[1]
ax2.semilogy(vsg_1e6, id_1e6, 'b-', linewidth=3, label='d0=1e6', marker='o', markersize=3, markevery=20)
ax2.semilogy(vsg_1e7, id_1e7, 'r-', linewidth=3, label='d0=1e7', marker='s', markersize=3, markevery=20)
ax2.set_xlabel('$V_{SG}$ (V)', fontsize=14, fontweight='bold')
ax2.set_ylabel('$|I_D|$ (A)', fontsize=14, fontweight='bold')
ax2.set_title('Log Scale Comparison', fontsize=15, fontweight='bold')
ax2.legend(fontsize=11, loc='upper left')
ax2.grid(True, alpha=0.3, which='both', linewidth=1.2)
ax2.tick_params(labelsize=11)

# Subplot 3: Normalized comparison (to see shape difference)
ax3 = axes[2]
# Normalize to I_ON for shape comparison
id_1e6_norm = id_1e6 / i_on_1e6
id_1e7_norm = id_1e7 / i_on_1e7
ax3.plot(vsg_1e6, id_1e6_norm, 'b-', linewidth=3, label='d0=1e6 (normalized)', marker='o', markersize=3, markevery=20)
ax3.plot(vsg_1e7, id_1e7_norm, 'r-', linewidth=3, label='d0=1e7 (normalized)', marker='s', markersize=3, markevery=20)
ax3.set_xlabel('$V_{SG}$ (V)', fontsize=14, fontweight='bold')
ax3.set_ylabel('$I_D / I_{ON}$ (Normalized)', fontsize=14, fontweight='bold')
ax3.set_title('Normalized Comparison (Shape)', fontsize=15, fontweight='bold')
ax3.legend(fontsize=11, loc='upper left')
ax3.grid(True, alpha=0.3, linewidth=1.2)
ax3.tick_params(labelsize=11)

plt.tight_layout()
plt.savefig('../output_curves/1e6_vs_1e7_comparison.png', dpi=300, bbox_inches='tight')
print("\nSaved: ../output_curves/1e6_vs_1e7_comparison.png")
print("="*70)
