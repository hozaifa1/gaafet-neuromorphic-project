import os
import sys
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from analyze_metrics import parse_plt_file, extract_vth, get_current_at_voltage

def plot_results(sim_dir, run_label="Run_01"):
    output_dir = os.path.join(sim_dir, "output_curves", run_label)
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Generating plots for {run_label} in {output_dir}...")
    
    # Load Data
    file_base = "read_leg{}_n5_des.plt"
    legs = [1, 2, 3]
    
    data = {}
    for leg in legs:
        fpath = os.path.join(sim_dir, file_base.format(leg))
        if os.path.exists(fpath):
            v, i, p = parse_plt_file(fpath)
            data[leg] = {"v": np.array(v), "i": np.array(i), "p": np.array(p)}
        else:
            print(f"Warning: Missing Leg {leg} at {fpath}")
            return

    # Extract Metrics for Annotation
    vgs_fwd = data[2]["v"]
    ids_fwd = data[2]["i"]
    vgs_rev = data[3]["v"]
    ids_rev = data[3]["i"]
    
    vth_fwd = extract_vth(list(vgs_fwd), list(ids_fwd))
    vth_rev = extract_vth(list(vgs_rev), list(ids_rev))
    mw = abs(vth_fwd - vth_rev)
    ion = get_current_at_voltage(list(vgs_fwd), list(ids_fwd), 0.5)
    
    metrics_text = (
        f"Vth (Fwd): {vth_fwd*1000:.0f} mV\n"
        f"Vth (Rev): {vth_rev*1000:.0f} mV\n"
        f"MW: {mw*1000:.0f} mV\n"
        f"Ion: {ion*1e6:.1f} uA"
    )

    # Plot 1: Id-Vg (Log Scale) - Transfer Characteristics
    plt.figure(figsize=(10, 6))
    plt.semilogy(data[2]["v"], data[2]["i"], 'b-', label='Forward (-6V -> +6V)', linewidth=2)
    plt.semilogy(data[3]["v"], data[3]["i"], 'r--', label='Reverse (+6V -> -6V)', linewidth=2)
    plt.title(f"Id-Vg Characteristics ({run_label})")
    plt.xlabel("Gate Voltage (V)")
    plt.ylabel("Drain Current (A)")
    plt.grid(True, which="both", linestyle='--', alpha=0.5)
    plt.legend()
    plt.text(0.05, 0.95, metrics_text, transform=plt.gca().transAxes, 
             verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    plt.savefig(os.path.join(output_dir, "IdVg_Log.png"))
    plt.close()

    # Plot 2: Id-Vg (Linear Scale)
    plt.figure(figsize=(10, 6))
    plt.plot(data[2]["v"], data[2]["i"], 'b-', label='Forward', linewidth=2)
    plt.plot(data[3]["v"], data[3]["i"], 'r--', label='Reverse', linewidth=2)
    plt.title(f"Id-Vg Linear ({run_label})")
    plt.xlabel("Gate Voltage (V)")
    plt.ylabel("Drain Current (A)")
    plt.grid(True)
    plt.legend()
    plt.savefig(os.path.join(output_dir, "IdVg_Lin.png"))
    plt.close()

    # Plot 3: Polarization-Vg (Hysteresis Loop)
    plt.figure(figsize=(8, 8))
    # Combine Leg 2 and Leg 3 for full loop
    plt.plot(data[2]["v"], data[2]["p"]*1e6, 'b-', label='Forward', linewidth=2) # Convert to uC/cm2
    plt.plot(data[3]["v"], data[3]["p"]*1e6, 'r--', label='Reverse', linewidth=2)
    plt.title(f"Ferroelectric Hysteresis ({run_label})")
    plt.xlabel("Gate Voltage (V)")
    plt.ylabel("Polarization (uC/cm^2)")
    plt.grid(True)
    plt.legend()
    plt.savefig(os.path.join(output_dir, "Polarization_Hysteresis.png"))
    plt.close()

    print(f"Plots saved successfully.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        run_label = sys.argv[1]
    else:
        run_label = "Run_01"
        
    plot_results("Simulations", run_label)
