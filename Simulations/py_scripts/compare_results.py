from __future__ import annotations

from pathlib import Path
import re
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

def parse_dfise_plt(path: Path) -> pd.DataFrame:
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
        raise ValueError(f"value count {values.size} not divisible by column count {n_cols}")
    data = values.reshape((-1, n_cols))
    return pd.DataFrame(data, columns=names)

def analyze_kink(df: pd.DataFrame, vg_col: str, id_col: str, label: str):
    vg = df[vg_col].values
    id = df[id_col].values
    
    id_abs = np.abs(id)
    id_abs_nz = id_abs[id_abs > 1e-15]
    
    if len(id_abs_nz) < 5:
        print(f"{label}: Insufficient non-zero current data")
        return None
    
    log_id = np.log10(id_abs_nz)
    vg_nz = vg[id_abs > 1e-15]
    
    if len(vg_nz) < 5:
        print(f"{label}: Insufficient voltage points")
        return None
    
    mid = len(log_id) // 2
    dlog_dv = np.gradient(log_id, vg_nz)
    
    ss_inv = np.median(dlog_dv[mid:]) if mid < len(dlog_dv) else np.median(dlog_dv)
    ss = 1.0 / ss_inv if ss_inv != 0 else np.inf
    ss_mv = ss * 1000
    
    curvature = np.gradient(dlog_dv, vg_nz)
    kink_metric = np.max(np.abs(curvature)) if len(curvature) > 0 else 0
    
    nonlinearity = np.std(dlog_dv)
    
    ion_ioff = id_abs_nz[-1] / id_abs_nz[0] if id_abs_nz[0] > 0 else 0
    
    print(f"\n{label}:")
    print(f"  I_ON: {id_abs_nz[-1]:.3e} A")
    print(f"  I_OFF: {id_abs_nz[0]:.3e} A")
    print(f"  I_ON/I_OFF: {ion_ioff:.2e}")
    print(f"  Subthreshold Swing: {ss_mv:.1f} mV/dec")
    print(f"  Kink Metric (curvature): {kink_metric:.3f}")
    print(f"  Slope Nonlinearity (std): {nonlinearity:.3f}")
    
    return {
        "ion": id_abs_nz[-1],
        "ioff": id_abs_nz[0],
        "ratio": ion_ioff,
        "ss": ss_mv,
        "kink_metric": kink_metric,
        "nonlinearity": nonlinearity
    }

def plot_comparison(old_files: list[Path], new_files: list[Path], output_dir: Path):
    fig, axes = plt.subplots(2, 3, figsize=(18, 10))
    
    for idx, (old_f, new_f) in enumerate(zip(old_files, new_files)):
        row = idx // 3
        col = idx % 3
        ax = axes[row, col]
        
        df_old = parse_dfise_plt(old_f)
        df_new = parse_dfise_plt(new_f)
        
        vg_col = None
        id_col = None
        for c in df_old.columns:
            if 'gate' in c.lower() and 'voltage' in c.lower():
                vg_col = c
            if 'drain' in c.lower() and 'current' in c.lower():
                id_col = c
        
        if not vg_col or not id_col:
            print(f"Warning: Could not find voltage/current columns in {old_f.name}")
            continue
        
        vg_old = -df_old[vg_col].values
        id_old = np.abs(df_old[id_col].values)
        
        vg_new = -df_new[vg_col].values
        id_new = np.abs(df_new[id_col].values)
        
        ax.semilogy(vg_old, id_old, 'b-o', label=f'Old (a0/a1)', markersize=4, linewidth=1.5)
        ax.semilogy(vg_new, id_new, 'r-s', label=f'New (B0/B1/ħω)', markersize=4, linewidth=1.5)
        
        ax.set_xlabel('V_SG (V)', fontsize=10)
        ax.set_ylabel('|I_D| (A)', fontsize=10)
        ax.set_title(f'Comparison: {old_f.stem.replace("a0a1_", "")}', fontsize=11)
        ax.grid(True, which='both', alpha=0.3, linestyle='--')
        ax.legend(fontsize=9)
        
        print(f"\n{'='*60}")
        print(f"Analyzing: {old_f.stem} vs {new_f.stem}")
        print(f"{'='*60}")
        analyze_kink(df_old, vg_col, id_col, f"OLD {old_f.stem}")
        analyze_kink(df_new, vg_col, id_col, f"NEW {new_f.stem}")
    
    fig.tight_layout()
    output_dir.mkdir(parents=True, exist_ok=True)
    out_path = output_dir / "comparison_all.png"
    fig.savefig(out_path, dpi=300)
    plt.close(fig)
    print(f"\n\nSaved comparison plot to {out_path}")

if __name__ == "__main__":
    base_dir = Path(__file__).parent.parent
    
    old_files = [
        base_dir / "a0a1_1e6.plt",
        base_dir / "a0a1_5e6.plt",
        base_dir / "a0a1_1e7.plt",
    ]
    
    new_files = [
        base_dir / "1e6.plt",
        base_dir / "5e6.plt",
        base_dir / "1e7.plt",
    ]
    
    output_dir = base_dir / "output_curves"
    
    plot_comparison(old_files, new_files, output_dir)
