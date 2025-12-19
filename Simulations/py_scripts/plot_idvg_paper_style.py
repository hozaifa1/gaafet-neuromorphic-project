"""
Plot I_D vs V_SG in paper style (flipped x-axis) to match Figure 7 from Bhatawdekar et al.

Paper convention: V_SG (source-to-gate) on x-axis, ranging from negative to 0
Your simulation: V_GS (gate-to-source) on x-axis

Relationship: V_SG = -V_GS

This script flips the x-axis so your curves look like the paper's Figure 7.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def parse_dfise_plt(path: Path) -> pd.DataFrame:
    """Parse a DF-ISE text .plt file into a DataFrame."""
    text = path.read_text()
    m_ds = re.search(r"datasets\s*=\s*\[(.*?)\]", text, re.S)
    if not m_ds:
        raise ValueError(f"datasets block not found in {path}")
    dataset_block = m_ds.group(1)
    names = re.findall(r"\"([^\"]+)\"", dataset_block)
    if not names:
        raise ValueError(f"no dataset names found in {path}")

    m_data = re.search(r"Data\s*{(.*?)}", text, re.S)
    if not m_data:
        raise ValueError(f"Data block not found in {path}")

    tokens = m_data.group(1).split()
    values = np.array([float(tok) for tok in tokens], dtype=float)
    n_cols = len(names)
    if values.size % n_cols != 0:
        raise ValueError(
            f"value count {values.size} not divisible by column count {n_cols} for {path}"
        )
    data = values.reshape((-1, n_cols))
    return pd.DataFrame(data, columns=names)


def plot_paper_style(df: pd.DataFrame, out_path: Path, linear: bool = False,
                     vsg_min: float = -0.5, vsg_max: float = 0.0) -> None:
    """
    Plot I_D vs V_SG in paper style.
    
    - X-axis: V_SG = -V_GS (flipped), limited to [vsg_min, vsg_max]
    - Y-axis: I_D (in µA for linear, log scale for log plot)
    
    Paper Figure 7 uses V_SG from -0.5V to 0V.
    """
    vg_col = "gate_contact OuterVoltage"
    id_col = "drain_contact TotalCurrent"
    
    if vg_col not in df.columns or id_col not in df.columns:
        print(f"Available columns: {list(df.columns)}")
        raise KeyError(f"Required columns not found")
    
    # Convert V_GS to V_SG (flip sign)
    v_sg = -df[vg_col].values
    i_d = df[id_col].values
    
    # Sort by V_SG for clean plotting
    sort_idx = np.argsort(v_sg)
    v_sg = v_sg[sort_idx]
    i_d = i_d[sort_idx]
    
    # Filter to specified V_SG range (matching paper Figure 7)
    mask = (v_sg >= vsg_min) & (v_sg <= vsg_max)
    v_sg = v_sg[mask]
    i_d = i_d[mask]
    
    if len(v_sg) == 0:
        print(f"WARNING: No data points in V_SG range [{vsg_min}, {vsg_max}]")
        return
    
    fig, ax = plt.subplots(figsize=(8, 6))
    
    if linear:
        # Linear scale (like paper Fig 7a) - convert to µA
        i_d_ua = np.abs(i_d) * 1e6  # Convert A to µA
        ax.plot(v_sg, i_d_ua, 'b-', linewidth=2, label=f'V_D = 1.0 V (a0=a1=1e6)')
        ax.set_ylabel(r'$I_{DS}$ (µA)', fontsize=12)
        ax.set_ylim(bottom=0)
    else:
        # Log scale
        i_d_abs = np.abs(i_d)
        i_d_abs[i_d_abs < 1e-20] = 1e-20  # Floor for log
        ax.semilogy(v_sg, i_d_abs, 'b-', linewidth=2, label=f'V_D = 1.0 V (a0=a1=1e6)')
        ax.set_ylabel(r'$|I_{DS}|$ (A)', fontsize=12)
    
    ax.set_xlabel(r'$V_{SG}$ (V)', fontsize=12)
    ax.set_xlim(vsg_min, vsg_max)
    ax.set_title(f'Transfer Characteristic (Paper Style)\nV_SG range: [{vsg_min}V, {vsg_max}V] — Compare with Figure 7', fontsize=11)
    ax.grid(True, which='both', linestyle='--', alpha=0.5)
    ax.legend(fontsize=10)
    
    # Add annotation explaining the kink
    if vsg_min <= -0.3 <= vsg_max:
        ax.annotate('Kink region should appear here\n(sharp slope change due to II)',
                    xy=(-0.3, 1e-6 if not linear else 10),
                    fontsize=9, color='red', ha='center',
                    bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    
    fig.tight_layout()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300)
    plt.close(fig)
    print(f"Saved: {out_path}")


def analyze_kink(df: pd.DataFrame) -> None:
    """Analyze the curve for kink characteristics."""
    vg_col = "gate_contact OuterVoltage"
    id_col = "drain_contact TotalCurrent"
    
    v_sg = -df[vg_col].values
    i_d = np.abs(df[id_col].values)
    
    # Sort
    sort_idx = np.argsort(v_sg)
    v_sg = v_sg[sort_idx]
    i_d = i_d[sort_idx]
    
    # Find key metrics
    i_max = np.max(i_d)
    i_min = np.min(i_d[i_d > 1e-20])
    
    # Find threshold region (where current crosses 94 nA = 9.4e-8 A)
    i_th_target = 94e-9  # 94 nA from paper
    crossings = np.where(np.diff(np.sign(i_d - i_th_target)))[0]
    
    print("\n" + "="*60)
    print("CURVE ANALYSIS (Paper Style: V_SG axis)")
    print("="*60)
    print(f"V_SG range: {v_sg.min():.2f} V to {v_sg.max():.2f} V")
    print(f"I_D range: {i_min:.2e} A to {i_max:.2e} A")
    print(f"I_D max in µA: {i_max*1e6:.2f} µA")
    
    if len(crossings) > 0:
        v_th_measured = v_sg[crossings[0]]
        print(f"\nThreshold (@ I_th=94nA): V_SG ≈ {v_th_measured:.3f} V")
        print(f"Paper target: V_th = -0.244 V")
        print(f"Difference: {v_th_measured - (-0.244):.3f} V")
    else:
        print(f"\nWARNING: Current never crosses I_th=94nA threshold!")
        print(f"  -> Check if impact ionization is activating")
    
    # Check for kink by looking at derivative changes
    log_id = np.log10(i_d + 1e-20)
    d_log_id = np.gradient(log_id, v_sg)
    
    # Find sudden slope changes (kink indicator)
    d2_log_id = np.gradient(d_log_id, v_sg)
    max_curvature_idx = np.argmax(np.abs(d2_log_id[10:-10])) + 10
    
    print(f"\nKINK ANALYSIS:")
    print(f"  Max curvature at V_SG ≈ {v_sg[max_curvature_idx]:.3f} V")
    print(f"  Paper shows kink around V_SG ≈ -0.3 to -0.4 V")
    
    # Subthreshold swing estimation
    # SS = dV_G / d(log10(I_D)) in mV/decade
    subthreshold_region = (i_d > 1e-12) & (i_d < 1e-6)
    if np.sum(subthreshold_region) > 10:
        v_sub = v_sg[subthreshold_region]
        log_i_sub = log_id[subthreshold_region]
        # Linear fit
        coeffs = np.polyfit(log_i_sub, v_sub, 1)
        ss = abs(coeffs[0]) * 1000  # mV/decade
        print(f"\nSubthreshold Swing: ~{ss:.1f} mV/decade")
        print(f"  (Ideal: 60 mV/dec, with kink effect should be < 60)")
    
    print("="*60)


def main():
    parser = argparse.ArgumentParser(description="Plot I_D-V_SG in paper style (flipped axis)")
    parser.add_argument("--input", type=Path, default=Path("../a0a1_1e6.plt"),
                        help="Input .plt file")
    parser.add_argument("--output", type=Path, default=Path("../output_curves/IdVsg_paper_style.png"),
                        help="Output image path")
    parser.add_argument("--linear", action="store_true", help="Use linear y-axis (like Fig 7a)")
    args = parser.parse_args()
    
    print(f"Reading: {args.input}")
    df = parse_dfise_plt(args.input)
    
    # Analyze
    analyze_kink(df)
    
    # Plot both linear and log versions
    plot_paper_style(df, args.output, linear=args.linear)
    
    # Paper-matched range: V_SG from -0.5V to 0V
    vsg_min, vsg_max = -0.5, 0.0
    
    # Save log version (paper-matched range)
    log_output = args.output.parent / (args.output.stem + "_log.png")
    plot_paper_style(df, log_output, linear=False, vsg_min=vsg_min, vsg_max=vsg_max)
    
    # Save linear version (paper-matched range)
    lin_output = args.output.parent / (args.output.stem + "_linear.png")
    plot_paper_style(df, lin_output, linear=True, vsg_min=vsg_min, vsg_max=vsg_max)
    
    # Also save full-range versions for reference
    full_log_output = args.output.parent / (args.output.stem + "_fullrange_log.png")
    plot_paper_style(df, full_log_output, linear=False, vsg_min=-2.0, vsg_max=2.0)
    
    full_lin_output = args.output.parent / (args.output.stem + "_fullrange_linear.png")
    plot_paper_style(df, full_lin_output, linear=True, vsg_min=-2.0, vsg_max=2.0)


if __name__ == "__main__":
    main()
