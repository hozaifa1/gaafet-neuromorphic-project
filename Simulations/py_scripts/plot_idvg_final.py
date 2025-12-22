#!/usr/bin/env python3
"""
Final Id-Vg plotting script for FeFET simulations.
Generates linear and log plots with V_SG axis (matching paper Figure 7).

Usage: python plot_idvg_final.py <plt_file>
Example: python plot_idvg_final.py ../1e6.plt
"""

import sys
import re
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def parse_plt(plt_file):
    """Parse Sentaurus .plt file and return DataFrame."""
    text = Path(plt_file).read_text()
    
    m_ds = re.search(r"datasets\s*=\s*\[(.*?)\]", text, re.S)
    if not m_ds:
        raise ValueError("Could not find datasets in .plt file")
    
    dataset_block = m_ds.group(1)
    column_names = re.findall(r"\"([^\"]+)\"", dataset_block)
    
    m_data = re.search(r"Data\s*{(.*?)}", text, re.S)
    if not m_data:
        raise ValueError("Could not find Data block in .plt file")
    
    tokens = m_data.group(1).split()
    values = np.array([float(tok) for tok in tokens], dtype=float)
    
    num_cols = len(column_names)
    data = values.reshape((-1, num_cols))
    
    return pd.DataFrame(data, columns=column_names)

def extract_hysteresis_branches(df, vg_col, id_col):
    """
    Separate forward and reverse sweep branches from hysteresis data.
    Returns (vsg_forward, id_forward, vsg_reverse, id_reverse)
    """
    vg = df[vg_col].values
    id_drain = df[id_col].values
    
    # Find turning point (where gate voltage stops increasing and starts decreasing)
    vg_diff = np.diff(vg)
    
    # Forward sweep: Vg increasing (diff > 0)
    # Reverse sweep: Vg decreasing (diff < 0)
    forward_idx = np.where(vg_diff > 1e-6)[0]
    reverse_idx = np.where(vg_diff < -1e-6)[0]
    
    if len(forward_idx) == 0 or len(reverse_idx) == 0:
        # No hysteresis - just plot all data
        vsg = -vg  # Convert V_GS to V_SG
        return vsg, np.abs(id_drain), None, None
    
    # Extract branches
    vg_forward = vg[forward_idx]
    id_forward = id_drain[forward_idx]
    
    vg_reverse = vg[reverse_idx]
    id_reverse = id_drain[reverse_idx]
    
    # Convert to V_SG (negate) and take absolute current
    vsg_forward = -vg_forward
    vsg_reverse = -vg_reverse
    
    return vsg_forward, np.abs(id_forward), vsg_reverse, np.abs(id_reverse)

def plot_idvg(plt_file, output_dir=None):
    """
    Create Id-Vg plots (linear and log) from .plt file.
    V_SG axis: decreases from left to right (positive to negative)
    """
    df = parse_plt(plt_file)
    
    # Column names
    vg_col = "gate_contact OuterVoltage"
    id_col = "drain_contact TotalCurrent"
    
    if vg_col not in df.columns or id_col not in df.columns:
        print(f"Available columns: {df.columns.tolist()}")
        raise ValueError(f"Required columns not found: {vg_col}, {id_col}")
    
    # Extract hysteresis branches
    vsg_fwd, id_fwd, vsg_rev, id_rev = extract_hysteresis_branches(df, vg_col, id_col)
    
    # Determine output directory
    if output_dir is None:
        output_dir = Path(plt_file).parent / "output_curves"
    output_dir = Path(output_dir)
    output_dir.mkdir(exist_ok=True)
    
    # Base filename
    base_name = Path(plt_file).stem
    
    # Create figure with 2 subplots
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))
    
    # Plot 1: Linear scale
    if vsg_rev is not None:
        ax1.plot(vsg_fwd, id_fwd, 'b-', linewidth=2, label='Forward')
        ax1.plot(vsg_rev, id_rev, 'r--', linewidth=2, label='Reverse')
        ax1.legend()
    else:
        ax1.plot(vsg_fwd, id_fwd, 'b-', linewidth=2)
    
    ax1.set_xlabel('$V_{SG}$ (V)', fontsize=12)
    ax1.set_ylabel('$|I_D|$ (A)', fontsize=12)
    ax1.set_title(f'Id-Vg Linear Scale - {base_name}', fontsize=13, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    ax1.set_xlim([min(vsg_fwd), max(vsg_fwd)])
    
    # Plot 2: Log scale
    if vsg_rev is not None:
        ax2.semilogy(vsg_fwd, id_fwd, 'b-', linewidth=2, label='Forward')
        ax2.semilogy(vsg_rev, id_rev, 'r--', linewidth=2, label='Reverse')
        ax2.legend()
    else:
        ax2.semilogy(vsg_fwd, id_fwd, 'b-', linewidth=2)
    
    ax2.set_xlabel('$V_{SG}$ (V)', fontsize=12)
    ax2.set_ylabel('$|I_D|$ (A)', fontsize=12)
    ax2.set_title(f'Id-Vg Log Scale - {base_name}', fontsize=13, fontweight='bold')
    ax2.grid(True, alpha=0.3, which='both')
    ax2.set_xlim([min(vsg_fwd), max(vsg_fwd)])
    
    plt.tight_layout()
    
    # Save
    output_file = output_dir / f"{base_name}_idvg.png"
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Saved: {output_file}")
    
    plt.close()
    
    # Calculate metrics
    i_on = np.max(id_fwd)
    i_off = np.min(id_fwd)
    ratio = i_on / i_off if i_off > 0 else np.inf
    
    print(f"\n{'='*60}")
    print(f"Device Metrics for {base_name}:")
    print(f"{'='*60}")
    print(f"I_ON:  {i_on:.3e} A")
    print(f"I_OFF: {i_off:.3e} A")
    print(f"I_ON/I_OFF: {ratio:.2e}")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python plot_idvg_final.py <plt_file>")
        print("Example: python plot_idvg_final.py ../1e6.plt")
        sys.exit(1)
    
    plt_file = sys.argv[1]
    
    if not Path(plt_file).exists():
        print(f"Error: File not found: {plt_file}")
        sys.exit(1)
    
    plot_idvg(plt_file)
