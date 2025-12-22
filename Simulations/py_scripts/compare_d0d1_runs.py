#!/usr/bin/env python3
"""
Compare d0d1_1e6 vs d0d1_1e7 to verify if d0/d1 parameters have any effect.
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
    forward_idx = np.where(np.diff(vg) > 1e-6)[0]
    if len(forward_idx) == 0:
        vsg = -vg
        return vsg, np.abs(id_drain)
    vg_forward = vg[forward_idx]
    id_forward = id_drain[forward_idx]
    vsg = -vg_forward
    return vsg, np.abs(id_forward)

# Parse files
vg_col = "gate_contact OuterVoltage"
id_col = "drain_contact TotalCurrent"

df_1e6 = parse_plt("../d0d1_1e6.plt")
df_1e7 = parse_plt("../d0d1_1e7.plt")

vsg_1e6, id_1e6 = extract_forward_sweep(df_1e6, vg_col, id_col)
vsg_1e7, id_1e7 = extract_forward_sweep(df_1e7, vg_col, id_col)

# Calculate metrics
i_on_1e6 = np.max(id_1e6)
i_off_1e6 = np.min(id_1e6)
i_on_1e7 = np.max(id_1e7)
i_off_1e7 = np.min(id_1e7)

print("\n" + "="*70)
print("CRITICAL TEST: d0/d1 Parameter Effect")
print("="*70)
print(f"\nd0d1_1e6.plt (d0=d1=1e6):")
print(f"  I_ON:  {i_on_1e6:.3e} A")
print(f"  I_OFF: {i_off_1e6:.3e} A")
print(f"  I_ON/I_OFF: {i_on_1e6/i_off_1e6:.2e}")

print(f"\nd0d1_1e7.plt (d0=d1=1e7):")
print(f"  I_ON:  {i_on_1e7:.3e} A")
print(f"  I_OFF: {i_off_1e7:.3e} A")
print(f"  I_ON/I_OFF: {i_on_1e7/i_off_1e7:.2e}")

# Check identity
max_diff = np.max(np.abs(id_1e6 - id_1e7))
print(f"\nMaximum absolute difference: {max_diff:.3e} A")

if np.allclose(id_1e6, id_1e7, rtol=1e-10, atol=1e-30):
    print("\n" + "="*70)
    print("⚠️  RESULT: FILES ARE IDENTICAL")
    print("="*70)
    print("\n❌ d0/d1 parameters have ZERO effect (just like a0/a1 and b0/b1)")
    print("❌ All UniBo avalanche model parameters are INERT in this build")
    print("\nCONCLUSION:")
    print("  → The only working knob is V_DS voltage")
    print("  → Sentaurus is using hardcoded internal avalanche coefficients")
    print("  → User-specified a_*, b_*, d_* parameters are being IGNORED")
    print("="*70)
else:
    print("\n✓ CONFIRMED: Files are DIFFERENT")
    print("✓ d0/d1 parameters ARE working")
    diff_pct = ((i_on_1e7 - i_on_1e6) / i_on_1e6) * 100
    print(f"  I_ON difference: {diff_pct:+.1f}%")
    print("="*70)

# Create comparison plot
fig, axes = plt.subplots(1, 3, figsize=(18, 5))

ax1 = axes[0]
ax1.plot(vsg_1e6, id_1e6, 'b-', linewidth=3, label='d0=d1=1e6', marker='o', markersize=3, markevery=20)
ax1.plot(vsg_1e7, id_1e7, 'r--', linewidth=3, label='d0=d1=1e7', marker='s', markersize=3, markevery=20)
ax1.set_xlabel('$V_{SG}$ (V)', fontsize=14, fontweight='bold')
ax1.set_ylabel('$|I_D|$ (A)', fontsize=14, fontweight='bold')
ax1.set_title('Linear Scale', fontsize=15, fontweight='bold')
ax1.legend(fontsize=11)
ax1.grid(True, alpha=0.3)

ax2 = axes[1]
ax2.semilogy(vsg_1e6, id_1e6, 'b-', linewidth=3, label='d0=d1=1e6', marker='o', markersize=3, markevery=20)
ax2.semilogy(vsg_1e7, id_1e7, 'r--', linewidth=3, label='d0=d1=1e7', marker='s', markersize=3, markevery=20)
ax2.set_xlabel('$V_{SG}$ (V)', fontsize=14, fontweight='bold')
ax2.set_ylabel('$|I_D|$ (A)', fontsize=14, fontweight='bold')
ax2.set_title('Log Scale', fontsize=15, fontweight='bold')
ax2.legend(fontsize=11)
ax2.grid(True, alpha=0.3, which='both')

ax3 = axes[2]
diff = id_1e7 - id_1e6
ax3.plot(vsg_1e6, diff, 'g-', linewidth=3)
ax3.set_xlabel('$V_{SG}$ (V)', fontsize=14, fontweight='bold')
ax3.set_ylabel('$\Delta I_D$ (1e7 - 1e6) [A]', fontsize=14, fontweight='bold')
ax3.set_title('Absolute Difference', fontsize=15, fontweight='bold')
ax3.grid(True, alpha=0.3)
ax3.axhline(y=0, color='k', linestyle='--', alpha=0.5)

plt.tight_layout()
plt.savefig('../output_curves/d0d1_comparison.png', dpi=300, bbox_inches='tight')
print("\nSaved: ../output_curves/d0d1_comparison.png")
print("="*70)
