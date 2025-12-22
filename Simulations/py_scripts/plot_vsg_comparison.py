import re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path


def parse_dfise_plt(path: Path) -> pd.DataFrame:
    text = path.read_text()
    m_ds = re.search(r"datasets\s*=\s*\[(.*?)\]", text, re.S)
    if not m_ds:
        raise ValueError(f"datasets block not found in {path}")
    dataset_block = m_ds.group(1)
    names = re.findall(r"\"([^\"]+)\"", dataset_block)
    
    m_data = re.search(r"Data\s*{(.*?)}", text, re.S)
    if not m_data:
        raise ValueError(f"Data block not found in {path}")
    
    tokens = m_data.group(1).split()
    values = np.array([float(tok) for tok in tokens], dtype=float)
    n_cols = len(names)
    data = values.reshape((-1, n_cols))
    return pd.DataFrame(data, columns=names)


def find_threshold_voltage_vsg(vsg, id_abs, i_threshold=94e-9):
    """Find V_th in V_SG coordinates where current crosses threshold."""
    idx = np.where(id_abs >= i_threshold)[0]
    if len(idx) == 0:
        return None
    return vsg[idx[0]]


def detect_kink_vsg(vsg, id_abs):
    """Detect kink effect in V_SG coordinates."""
    if len(vsg) < 3:
        return None, None
    
    log_id = np.log10(id_abs + 1e-30)
    d_log_id = np.diff(log_id)
    d_vsg = np.diff(vsg)
    slope = d_log_id / (d_vsg + 1e-10)
    
    kink_threshold = 8.0
    kink_indices = np.where(np.abs(slope) > kink_threshold)[0]
    
    if len(kink_indices) > 0:
        idx = kink_indices[0]
        kink_vsg = vsg[idx]
        current_jump = id_abs[idx+1] / (id_abs[idx] + 1e-30)
        return kink_vsg, current_jump
    
    return None, None


def main():
    base_dir = Path(__file__).parent.parent
    
    files = {
        "1e6": base_dir / "a0a1_1e6.plt",
        "5e6": base_dir / "a0a1_5e6.plt",
        "1e7": base_dir / "a0a1_1e7.plt",
    }
    
    print("="*90)
    print("V_SG CONVENTION ANALYSIS - C1, C2 Experiments")
    print("="*90)
    print("\nNote: V_SG = V_source - V_gate = -V_gate (since source is grounded)")
    print("Paper plots V_SG on x-axis ranging from -0.5V to 0V")
    print("Our simulation sweeps V_gate from 0V to 0.5V → V_SG from 0V to -0.5V")
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    colors = {'1e6': 'blue', '5e6': 'orange', '1e7': 'green'}
    all_results = []
    
    for label, file_path in files.items():
        if not file_path.exists():
            print(f"\n⚠️ WARNING: {file_path.name} not found. Skipping.")
            continue
        
        df = parse_dfise_plt(file_path)
        vg = df["gate_contact OuterVoltage"].values
        id_drain = df["drain_contact TotalCurrent"].values
        id_abs = np.abs(id_drain)
        
        vsg = -vg
        
        i_off = np.min(id_abs)
        i_on = np.max(id_abs)
        
        vth_vsg = find_threshold_voltage_vsg(vsg, id_abs, 94e-9)
        kink_vsg, kink_jump = detect_kink_vsg(vsg, id_abs)
        
        results = {
            "d0": label,
            "I_off (A)": f"{i_off:.2e}",
            "I_on (A)": f"{i_on:.2e}",
            "V_th @ 94nA (V_SG)": f"{vth_vsg:.3f}" if vth_vsg else "N/A",
            "Kink Detected": "YES" if kink_vsg else "NO",
            "Kink V_SG (V)": f"{kink_vsg:.3f}" if kink_vsg else "N/A",
            "Current Jump": f"{kink_jump:.1f}x" if kink_jump else "N/A",
        }
        all_results.append(results)
        
        ax1.semilogy(vsg, id_abs, label=f'd0 = {label}', linewidth=2, color=colors[label])
        ax2.plot(vsg, id_abs * 1e6, label=f'd0 = {label}', linewidth=2, color=colors[label])
        
        print(f"\n{label}: V_SG range = [{vsg.min():.3f}, {vsg.max():.3f}]V")
        print(f"       Current range = [{i_off:.2e}, {i_on:.2e}]A")
        if vth_vsg:
            print(f"       V_th @ 94nA = {vth_vsg:.3f}V (V_SG)")
        if kink_vsg:
            print(f"       Kink at V_SG = {kink_vsg:.3f}V with {kink_jump:.1f}x jump")
    
    ax1.axhline(94e-9, color='red', linestyle='--', linewidth=1.5, label='I_th = 94 nA (target)')
    ax1.axvline(-0.244, color='purple', linestyle='--', linewidth=1.5, label='V_th = -0.244 V (target)')
    ax1.set_xlabel('V_SG (V)', fontsize=12, fontweight='bold')
    ax1.set_ylabel('Drain Current I_D (A)', fontsize=12, fontweight='bold')
    ax1.set_title('Log-Scale I_D vs V_SG', fontsize=13, fontweight='bold')
    ax1.grid(True, which='both', alpha=0.3)
    ax1.legend(fontsize=9)
    ax1.set_xlim([-0.5, 0])
    
    ax2.axhline(0.094, color='red', linestyle='--', linewidth=1.5, label='I_th = 94 nA (target)')
    ax2.axvline(-0.244, color='purple', linestyle='--', linewidth=1.5, label='V_th = -0.244 V (target)')
    ax2.set_xlabel('V_SG (V)', fontsize=12, fontweight='bold')
    ax2.set_ylabel('Drain Current I_D (µA)', fontsize=12, fontweight='bold')
    ax2.set_title('Linear-Scale I_D vs V_SG', fontsize=13, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    ax2.legend(fontsize=9)
    ax2.set_xlim([-0.5, 0])
    
    plt.tight_layout()
    output_path = base_dir / "output_curves" / "VSG_comparison.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"\n✅ V_SG comparison plot saved to: {output_path}")
    plt.close()
    
    print("\n" + "="*90)
    print("QUANTITATIVE RESULTS (V_SG Convention)")
    print("="*90)
    df_results = pd.DataFrame(all_results)
    print(df_results.to_string(index=False))
    
    print("\n" + "="*90)
    print("TARGET COMPARISON")
    print("="*90)
    print("Target V_th:       -0.244 V (V_SG)")
    print("Target I_th:       94 nA")
    print("Target V_SG range: -0.5 V to 0 V")
    print("Expected kink:     Sharp current jump from Impact Ionization")
    
    print("\n" + "="*90)


if __name__ == "__main__":
    main()
