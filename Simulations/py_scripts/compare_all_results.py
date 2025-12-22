#!/usr/bin/env python3
"""
Compare ALL simulation results showing old identical files vs new results.
Creates clear visualization of differences.
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

# Parse all files
files = {
    'Old 1e6': '../1e6.plt',
    'Old 5e6': '../5e6.plt', 
    'Old 1e7': '../1e7.plt',
    'New 1e7': '../1e7_final.plt'
}

data = {}
vg_col = "gate_contact OuterVoltage"
id_col = "drain_contact TotalCurrent"

for label, fname in files.items():
    try:
        df = parse_plt(fname)
        vsg, id_abs = extract_forward_sweep(df, vg_col, id_col)
        data[label] = (vsg, id_abs)
        print(f"Loaded {label}: I_ON={np.max(id_abs):.2e} A, I_OFF={np.min(id_abs):.2e} A")
    except Exception as e:
        print(f"Warning: Could not load {label} - {e}")

if len(data) == 0:
    print("ERROR: No data files found!")
    exit(1)

# Create figure with 2 rows, 2 columns
fig = plt.figure(figsize=(16, 10))

# --- Row 1: Linear scale ---
ax1 = plt.subplot(2, 2, 1)
ax1.plot(data['Old 1e6'][0], data['Old 1e6'][1], 'gray', linewidth=3, alpha=0.7, label='Old (1e6/5e6/1e7 - identical)')
ax1.plot(data['New 1e7'][0], data['New 1e7'][1], 'r-', linewidth=2.5, label='New 1e7 (FIXED)', zorder=10)
ax1.set_xlabel('$V_{SG}$ (V)', fontsize=13, fontweight='bold')
ax1.set_ylabel('$|I_D|$ (A)', fontsize=13, fontweight='bold')
ax1.set_title('Linear Scale: Old vs New', fontsize=14, fontweight='bold')
ax1.legend(fontsize=11)
ax1.grid(True, alpha=0.3)

# --- Row 1: Log scale ---
ax2 = plt.subplot(2, 2, 2)
ax2.semilogy(data['Old 1e6'][0], data['Old 1e6'][1], 'gray', linewidth=3, alpha=0.7, label='Old (identical)')
ax2.semilogy(data['New 1e7'][0], data['New 1e7'][1], 'r-', linewidth=2.5, label='New 1e7', zorder=10)
ax2.set_xlabel('$V_{SG}$ (V)', fontsize=13, fontweight='bold')
ax2.set_ylabel('$|I_D|$ (A)', fontsize=13, fontweight='bold')
ax2.set_title('Log Scale: Old vs New', fontsize=14, fontweight='bold')
ax2.legend(fontsize=11)
ax2.grid(True, alpha=0.3, which='both')

# --- Row 2: Zoomed comparison showing kink region ---
ax3 = plt.subplot(2, 2, 3)
# Zoom into the region where differences are visible
vsg_old, id_old = data['Old 1e6']
vsg_new, id_new = data['New 1e7']

# Find indices for V_SG between -0.5 and -0.3 (where kink appears)
mask_old = (vsg_old >= -0.5) & (vsg_old <= -0.2)
mask_new = (vsg_new >= -0.5) & (vsg_new <= -0.2)

ax3.plot(vsg_old[mask_old], id_old[mask_old], 'b-', linewidth=3, marker='o', markersize=4, label='Old (smooth)')
ax3.plot(vsg_new[mask_new], id_new[mask_new], 'r-', linewidth=3, marker='s', markersize=4, label='New (kink)')
ax3.set_xlabel('$V_{SG}$ (V)', fontsize=13, fontweight='bold')
ax3.set_ylabel('$|I_D|$ (A)', fontsize=13, fontweight='bold')
ax3.set_title('ZOOMED: Kink Region (-0.5V to -0.2V)', fontsize=14, fontweight='bold')
ax3.legend(fontsize=11)
ax3.grid(True, alpha=0.3)

# --- Row 2: Derivative to show kink clearly ---
ax4 = plt.subplot(2, 2, 4)
# Calculate dI/dV to highlight kink
dvsg_new = np.diff(vsg_new)
did_new = np.diff(id_new)
deriv_new = did_new / (dvsg_new + 1e-30)
vsg_mid_new = (vsg_new[:-1] + vsg_new[1:]) / 2

dvsg_old = np.diff(vsg_old)
did_old = np.diff(id_old)
deriv_old = did_old / (dvsg_old + 1e-30)
vsg_mid_old = (vsg_old[:-1] + vsg_old[1:]) / 2

ax4.plot(vsg_mid_old, deriv_old, 'b-', linewidth=2, label='Old (smooth dI/dV)')
ax4.plot(vsg_mid_new, deriv_new, 'r-', linewidth=2, label='New (KINK = sharp dI/dV spike)')
ax4.set_xlabel('$V_{SG}$ (V)', fontsize=13, fontweight='bold')
ax4.set_ylabel('$dI_D/dV_{SG}$ (A/V)', fontsize=13, fontweight='bold')
ax4.set_title('Derivative: Shows Kink as Sharp Spike', fontsize=14, fontweight='bold')
ax4.legend(fontsize=11)
ax4.grid(True, alpha=0.3)
ax4.set_ylim([0, np.percentile(deriv_new, 95)])  # Clip extreme values for visibility

plt.tight_layout()
plt.savefig('../output_curves/comprehensive_comparison.png', dpi=300, bbox_inches='tight')
print("\n" + "="*70)
print("SAVED: ../output_curves/comprehensive_comparison.png")
print("="*70)
print("\nKey Differences:")
print("  Top-left: Linear scale full range")
print("  Top-right: Log scale full range")
print("  Bottom-left: ZOOMED into kink region (you can SEE the difference)")
print("  Bottom-right: Derivative plot (kink appears as SHARP SPIKE)")
print("="*70)
