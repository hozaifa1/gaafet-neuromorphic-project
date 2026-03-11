import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

SAMPLES_PER_STEP = 29

def parse_plt_file(path: Path):
    """Return Time, VGS, and Id arrays extracted from a Sentaurus DF-ISE PLT file."""
    values = []
    records = []
    data_started = False

    with path.open("r", errors="ignore") as handle:
        for raw_line in handle:
            line = raw_line.strip()

            if not data_started:
                if line.startswith("Data"):
                    data_started = True
                continue

            if not line:
                continue

            if line.startswith("}"):
                break

            for token in line.split():
                try:
                    values.append(float(token))
                except ValueError:
                    continue

            while len(values) >= SAMPLES_PER_STEP:
                records.append(values[:SAMPLES_PER_STEP])
                values = values[SAMPLES_PER_STEP:]

    if not records:
        print(f"No data records found in {path}")
        return np.array([]), np.array([]), np.array([]), np.array([]), np.array([])
        
    data = np.array(records)
    time = data[:, 0]
    gate_voltage = data[:, 17]
    source_voltage = data[:, 9]
    drain_current = data[:, 7]
    polarization_y = data[:, 26]
    electric_field_y = data[:, 28]

    vgs = gate_voltage - source_voltage
    return time, vgs, drain_current, polarization_y, electric_field_y

def main():
    runs_dir = Path("../spiking_runs")
    
    # Only parse transient files (NOT init_bias which uses Quasistationary parameter, not real time)
    rise_path = runs_dir / "fire_rise_n5_des.plt"
    hold_path = runs_dir / "fire_hold_n5_des.plt"
    
    for p in [rise_path, hold_path]:
        if not p.exists():
            print(f"File not found: {p}")
            return
    
    print("Parsing fire_rise_n5_des.plt...")
    t_rise, vgs_rise, id_rise, pol_rise, ef_rise = parse_plt_file(rise_path)
    print("Parsing fire_hold_n5_des.plt...")
    t_hold, vgs_hold, id_hold, pol_hold, ef_hold = parse_plt_file(hold_path)
    
    # Concatenate rise + hold (time is already continuous: rise 0->10ns, hold 10ns->5us)
    all_time = np.concatenate([t_rise, t_hold])
    all_vgs = np.concatenate([vgs_rise, vgs_hold])
    all_id = np.abs(np.concatenate([id_rise, id_hold]))
    all_pol = np.concatenate([pol_rise, pol_hold])
    
    # Convert time to microseconds for readability
    all_time_us = all_time * 1e6
    t_rise_us = t_rise * 1e6
    t_hold_us = t_hold * 1e6
    
    # --- Print numerical summary ---
    print(f"\n{'='*60}")
    print(f"NUMERICAL SUMMARY")
    print(f"{'='*60}")
    print(f"Rise phase: {t_rise[0]*1e9:.1f} ns -> {t_rise[-1]*1e9:.1f} ns ({len(t_rise)} points)")
    print(f"Hold phase: {t_hold[0]*1e9:.1f} ns -> {t_hold[-1]*1e6:.1f} us ({len(t_hold)} points)")
    print(f"")
    print(f"Gate Voltage:")
    print(f"  Start of rise: VGS = {vgs_rise[0]:.4f} V")
    print(f"  End of rise:   VGS = {vgs_rise[-1]:.4f} V")
    print(f"  During hold:   VGS = {vgs_hold[-1]:.4f} V")
    print(f"")
    print(f"Drain Current:")
    print(f"  Start (VGS=0V):    ID = {abs(id_rise[0])*1e6:.2f} uA")
    print(f"  End of rise:       ID = {abs(id_rise[-1])*1e6:.2f} uA")
    print(f"  Hold start (10ns): ID = {abs(id_hold[0])*1e6:.2f} uA")
    print(f"  Hold end (5us):    ID = {abs(id_hold[-1])*1e6:.2f} uA")
    print(f"  Hold ID change:    {(abs(id_hold[-1]) - abs(id_hold[0]))*1e6:.4f} uA")
    print(f"")
    print(f"Polarization (Py at HZO center):")
    print(f"  Start:    {pol_rise[0]:.4e} C/cm2")
    print(f"  End rise: {pol_rise[-1]:.4e} C/cm2")
    print(f"  End hold: {pol_hold[-1]:.4e} C/cm2")
    print(f"  P_r (par file): 1.6e-5 C/cm2")
    print(f"  Fraction switched: {abs(pol_hold[-1]) / 1.6e-5 * 100:.3f}%")
    print(f"{'='*60}")
    
    # === FIGURE 1: Full transient (3 panels) ===
    fig, axes = plt.subplots(3, 1, figsize=(12, 10), sharex=True)
    
    # Panel 1: Gate Voltage
    axes[0].plot(all_time_us, all_vgs, 'r-', linewidth=2)
    axes[0].set_ylabel('V_GS (V)', fontsize=12)
    axes[0].set_ylim(-0.1, max(1.4, max(all_vgs)+0.2))
    axes[0].axhline(y=0.263, color='gray', linestyle='--', alpha=0.7, label='V_th = 0.263V')
    axes[0].legend(fontsize=10)
    axes[0].grid(True, alpha=0.3)
    vgs_final = vgs_hold[-1] if len(vgs_hold) > 0 else vgs_rise[-1]
    axes[0].set_title(f'GAA-FeFET LIF Neuron: Transient Response (VGS={vgs_final:.2f}V, VDS pulsed 0->1.0V)', fontsize=13)
    
    # Panel 2: Drain Current
    axes[1].plot(all_time_us, all_id * 1e6, 'b-', linewidth=2)
    axes[1].set_ylabel('I_D (uA)', fontsize=12)
    axes[1].grid(True, alpha=0.3)
    id_final = abs(id_hold[-1]) * 1e6
    axes[1].axhline(y=id_final, color='gray', linestyle=':', alpha=0.5)
    axes[1].annotate(f'Steady state: {id_final:.1f} uA', 
                     xy=(all_time_us[-1]*0.5, id_final), fontsize=10, color='blue')
    
    # Panel 3: Polarization
    axes[2].plot(all_time_us, all_pol * 1e5, 'm-', linewidth=2)
    axes[2].set_ylabel('Polarization (x1e-5 C/cm2)', fontsize=12)
    axes[2].set_xlabel('Time (us)', fontsize=12)
    axes[2].grid(True, alpha=0.3)
    axes[2].axhline(y=1.6, color='gray', linestyle='--', alpha=0.5, label='P_r = 1.6e-5')
    axes[2].legend(fontsize=10)
    
    fig.tight_layout()
    output1 = "spiking_results.png"
    plt.savefig(output1, dpi=300)
    print(f"\nPlot saved to {output1}")
    
    # === FIGURE 2: Zoomed rise phase ===
    fig2, axes2 = plt.subplots(2, 1, figsize=(10, 7), sharex=True)
    t_rise_ns = t_rise * 1e9
    
    axes2[0].plot(t_rise_ns, vgs_rise, 'r-', linewidth=2)
    axes2[0].set_ylabel('V_GS (V)', fontsize=12)
    axes2[0].axhline(y=0.263, color='gray', linestyle='--', alpha=0.7, label='V_th')
    axes2[0].legend()
    axes2[0].grid(True, alpha=0.3)
    axes2[0].set_title('Drain Pulse Rise Phase Detail (0 -> 10 ns)', fontsize=13)
    
    axes2[1].plot(t_rise_ns, np.abs(id_rise) * 1e6, 'b-', linewidth=2)
    axes2[1].set_ylabel('I_D (uA)', fontsize=12)
    axes2[1].set_xlabel('Time (ns)', fontsize=12)
    axes2[1].grid(True, alpha=0.3)
    
    fig2.tight_layout()
    output2 = "rise_phase_detail.png"
    plt.savefig(output2, dpi=300)
    print(f"Plot saved to {output2}")
    
    # === FIGURE 3: Hold phase (check for any spiking) ===
    fig3, ax3 = plt.subplots(figsize=(10, 5))
    ax3.plot(t_hold_us, np.abs(id_hold) * 1e6, 'b-', linewidth=2)
    ax3.set_ylabel('I_D (uA)', fontsize=12)
    ax3.set_xlabel('Time (us)', fontsize=12)
    vgs_val = vgs_hold[-1] if len(vgs_hold) > 0 else 0
    ax3.set_title(f'Hold Phase (VGS={vgs_val:.2f}V, VDS=1.0V): ID at {abs(id_hold[-1])*1e6:.1f} uA', fontsize=13)
    ax3.grid(True, alpha=0.3)
    
    fig3.tight_layout()
    output3 = "hold_phase_detail.png"
    plt.savefig(output3, dpi=300)
    print(f"Plot saved to {output3}")
    
    plt.close('all')

if __name__ == "__main__":
    main()
