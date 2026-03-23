import numpy as np
from pathlib import Path

SAMPLES_PER_STEP = 29

# Column indices from the PLT header
COL_TIME = 0
COL_DRAIN_V = 1        # drain_contact OuterVoltage
COL_DRAIN_ECUR = 5     # drain_contact eCurrent
COL_DRAIN_HCUR = 6     # drain_contact hCurrent
COL_DRAIN_TOTAL = 7    # drain_contact TotalCurrent
COL_SOURCE_V = 9       # source_contact OuterVoltage
COL_SOURCE_ECUR = 13   # source_contact eCurrent
COL_SOURCE_HCUR = 14   # source_contact hCurrent
COL_SOURCE_TOTAL = 15  # source_contact TotalCurrent
COL_GATE_V = 17        # gate_contact OuterVoltage
COL_GATE_TOTAL = 23    # gate_contact TotalCurrent
COL_POL_Y = 26         # Polarization/y

def parse_plt(path):
    values = []
    records = []
    data_started = False
    with path.open("r", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not data_started:
                if line.startswith("Data"):
                    data_started = True
                continue
            if not line:
                continue
            if line.startswith("}"):
                break
            for tok in line.split():
                try:
                    values.append(float(tok))
                except ValueError:
                    pass
            while len(values) >= SAMPLES_PER_STEP:
                records.append(values[:SAMPLES_PER_STEP])
                values = values[SAMPLES_PER_STEP:]
    if not records:
        return None
    return np.array(records)

def analyze_run(run_dir, run_label, d0_label):
    rise_path = run_dir / "fire_rise_n5_des.plt"
    hold_path = run_dir / "fire_hold_n5_des.plt"
    
    if not rise_path.exists() or not hold_path.exists():
        print(f"  Missing files in {run_dir}")
        return None
    
    rise = parse_plt(rise_path)
    hold = parse_plt(hold_path)
    
    if rise is None or hold is None:
        print(f"  No data parsed for {run_label}")
        return None
    
    print(f"\n{'='*70}")
    print(f"  {run_label}: {d0_label}")
    print(f"{'='*70}")
    
    # Rise phase
    t_rise = rise[:, COL_TIME]
    id_rise = rise[:, COL_DRAIN_TOTAL]
    id_e_rise = rise[:, COL_DRAIN_ECUR]
    src_h_rise = rise[:, COL_SOURCE_HCUR]
    vg_rise = rise[:, COL_GATE_V]
    vs_rise = rise[:, COL_SOURCE_V]
    vd_rise = rise[:, COL_DRAIN_V]
    pol_rise = rise[:, COL_POL_Y]
    
    # Hold phase
    t_hold = hold[:, COL_TIME]
    id_hold = hold[:, COL_DRAIN_TOTAL]
    id_e_hold = hold[:, COL_DRAIN_ECUR]
    src_h_hold = hold[:, COL_SOURCE_HCUR]
    vg_hold = hold[:, COL_GATE_V]
    vs_hold = hold[:, COL_SOURCE_V]
    vd_hold = hold[:, COL_DRAIN_V]
    pol_hold = hold[:, COL_POL_Y]
    gate_total_hold = hold[:, COL_GATE_TOTAL]
    
    vgs_end = vg_hold[-1] - vs_hold[-1]
    vds_end = vd_hold[-1] - vs_hold[-1]
    
    print(f"\n  Bias Conditions:")
    print(f"    V_G = {vg_hold[-1]:.4f} V, V_S = {vs_hold[-1]:.4f} V, V_D(end) = {vd_hold[-1]:.4f} V")
    print(f"    V_GS = {vgs_end:.4f} V, V_DS = {vds_end:.4f} V")
    
    print(f"\n  Rise Phase: {t_rise[0]*1e9:.1f} ns -> {t_rise[-1]*1e9:.1f} ns ({len(t_rise)} pts)")
    print(f"  Hold Phase: {t_hold[0]*1e9:.1f} ns -> {t_hold[-1]*1e6:.1f} us ({len(t_hold)} pts)")
    
    # Drain current analysis
    id_start = abs(id_rise[0])
    id_end_rise = abs(id_rise[-1])
    id_hold_start = abs(id_hold[0])
    id_hold_end = abs(id_hold[-1])
    id_hold_max = np.max(np.abs(id_hold))
    id_hold_min = np.min(np.abs(id_hold[10:]))  # skip first few transient points
    
    print(f"\n  Drain Current (Total):")
    print(f"    Start (VDS=0):     {id_start*1e9:.4f} nA")
    print(f"    End of rise:       {id_end_rise*1e9:.2f} nA  ({id_end_rise*1e6:.4f} uA)")
    print(f"    Hold start:        {id_hold_start*1e9:.2f} nA  ({id_hold_start*1e6:.4f} uA)")
    print(f"    Hold end (5us):    {id_hold_end*1e9:.2f} nA  ({id_hold_end*1e6:.4f} uA)")
    print(f"    Hold MAX:          {id_hold_max*1e9:.2f} nA")
    print(f"    Hold MIN (skip 10):{id_hold_min*1e9:.2f} nA")
    print(f"    Hold variation:    {(id_hold_max - id_hold_min)/id_hold_start*100:.2f}%")
    
    # Gate leakage
    gate_leak = abs(gate_total_hold[-1])
    print(f"    Gate leakage:      {gate_leak*1e9:.4f} nA")
    
    # Channel current (drain total - gate leakage)
    id_channel = id_hold_end - gate_leak
    print(f"    Channel current:   {id_channel*1e9:.2f} nA")
    
    # Source hole current (II indicator)
    src_h_end_rise = src_h_rise[-1]
    src_h_hold_max = np.min(src_h_hold)  # most negative = most hole current (conventional sign)
    
    # For hold phase, find the absolute max hole current
    src_h_abs = np.abs(src_h_hold)
    src_h_max_abs = np.max(src_h_abs)
    src_h_end_hold = src_h_hold[-1]
    
    print(f"\n  Source Hole Current (Impact Ionization Indicator):")
    print(f"    End of rise:       {src_h_end_rise:.4e} A  ({abs(src_h_end_rise)*1e15:.2f} fA)")
    print(f"    Hold peak (abs):   {src_h_max_abs:.4e} A  ({src_h_max_abs*1e15:.2f} fA)")
    print(f"    Hold end (5us):    {src_h_end_hold:.4e} A  ({abs(src_h_end_hold)*1e15:.2f} fA)")
    
    # II Multiplication factor
    if id_channel > 0 and src_h_max_abs > 0:
        M = src_h_max_abs / abs(id_channel)
        print(f"    M (II mult):       {M:.4e}")
    else:
        M = 0
        print(f"    M (II mult):       N/A")
    
    # Spiking detection: look for >2x variation in drain current during hold
    id_hold_abs = np.abs(id_hold)
    id_hold_std = np.std(id_hold_abs[10:])
    id_hold_mean = np.mean(id_hold_abs[10:])
    variation_pct = id_hold_std / id_hold_mean * 100 if id_hold_mean > 0 else 0
    
    # Check for any transient spike (max/min ratio)
    ratio = id_hold_max / id_hold_min if id_hold_min > 0 else 1
    
    print(f"\n  Spiking Analysis:")
    print(f"    Hold I_D std/mean: {variation_pct:.4f}%")
    print(f"    Hold max/min:      {ratio:.4f}")
    if ratio > 2.0:
        print(f"    *** POSSIBLE SPIKING DETECTED! ***")
    elif ratio > 1.1:
        print(f"    ** Marginal variation — check waveform **")
    else:
        print(f"    No spiking (flat current)")
    
    # Polarization
    print(f"\n  Ferroelectric Polarization (P_y):")
    print(f"    Start:     {pol_rise[0]:.4e} C/cm2")
    print(f"    End rise:  {pol_rise[-1]:.4e} C/cm2")
    print(f"    End hold:  {pol_hold[-1]:.4e} C/cm2")
    
    # Check if current EVER crosses 200nA target during hold
    above_200nA = np.any(id_hold_abs > 200e-9)
    print(f"\n  Target Check:")
    print(f"    I_D ever > 200 nA during hold: {above_200nA}")
    print(f"    I_D ever > 1 uA during hold:   {np.any(id_hold_abs > 1e-6)}")
    
    return {
        'label': run_label,
        'd0': d0_label,
        'id_steady': id_hold_end,
        'id_channel': id_channel,
        'src_h_max': src_h_max_abs,
        'M': M,
        'variation': variation_pct,
        'ratio': ratio,
        'spiking': ratio > 2.0
    }

def main():
    base = Path(r"f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations\spiking_runs")
    
    runs = [
        ("Run 8a", "d0_e=7.1e5, d0_h=2.08e6 (Si defaults)"),
        ("Run 8b", "d0_e=5e5, d0_h=5e5 (moderate boost)"),
        ("Run 8c", "d0_e=1e5, d0_h=1e5 (strong boost)"),
    ]
    
    results = []
    for folder, d0_label in runs:
        run_dir = base / folder
        r = analyze_run(run_dir, folder, d0_label)
        if r:
            results.append(r)
    
    # Summary comparison table
    print(f"\n\n{'='*90}")
    print(f"  COMPARISON TABLE")
    print(f"{'='*90}")
    print(f"{'Run':<10} {'d0 params':<35} {'I_D (nA)':<12} {'I_hole (fA)':<14} {'M':<14} {'Spike?':<8}")
    print(f"{'-'*90}")
    
    # Include Run 8 (original) for reference
    print(f"{'Run 8':<10} {'d0_e=1e6, d0_h=1e6 (paper)':<35} {'183.4':<12} {'9.15':<14} {'4.99e-8':<14} {'No':<8}")
    
    for r in results:
        spike_str = "YES!" if r['spiking'] else "No"
        print(f"{r['label']:<10} {r['d0']:<35} {r['id_steady']*1e9:<12.2f} {r['src_h_max']*1e15:<14.2f} {r['M']:<14.4e} {spike_str:<8}")
    
    print(f"\n  Key Question: Did reducing d0 significantly increase M and produce spiking?")
    
    if any(r['spiking'] for r in results):
        print(f"  >>> SPIKING OBSERVED in at least one run!")
    else:
        print(f"  >>> NO SPIKING in any run. II parameter tuning alone is insufficient.")
        print(f"  >>> The fundamental issue is likely the device structure/calibration, not II parameters.")

if __name__ == "__main__":
    main()
