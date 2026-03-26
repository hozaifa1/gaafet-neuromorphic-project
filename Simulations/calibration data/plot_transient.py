import os
import sys
import matplotlib.pyplot as plt
import numpy as np
from analyze_metrics import parse_full_plt

def plot_transient(sim_dir, run_label="Run_04"):
    output_dir = os.path.join(sim_dir, "output_curves", run_label)
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Generating transient plots for {run_label} in {output_dir}...")
    
    # Load Data
    # Updated to look for "fire_hold_" which contains the latency phase
    fpath = os.path.join(sim_dir, "read_fire_hold_n5_des.plt")
    
    if not os.path.exists(fpath):
        # Fallback check for local runs or different naming conventions
        fpath = os.path.join(sim_dir, "fire_hold_n5_des.plt")
        
    if not os.path.exists(fpath):
         # Try the rise file just in case
        fpath = os.path.join(sim_dir, "read_fire_rise_n5_des.plt")
        if os.path.exists(fpath):
             print("Warning: Only found Rise file. Simulation might have crashed before Hold.")
        else:
             print(f"Error: Could not find transient output file (checked fire_hold and fire_rise)")
        return

    # Use the generic parser
    time, values, variables = parse_full_plt(fpath)
    
    if not variables:
        print("Error: Failed to parse PLT file.")
        return
    
    # Identify indices
    idx_gate_v = -1
    idx_drain_i = -1
    
    for i, var in enumerate(variables):
        if "gate_contact" in var and "OuterVoltage" in var:
            idx_gate_v = i
        if "drain_contact" in var and "TotalCurrent" in var:
            idx_drain_i = i
            
    if idx_gate_v == -1 or idx_drain_i == -1:
        print("Error: Could not find Gate Voltage or Drain Current in PLT file.")
        print(f"Available variables: {variables}")
        return

    t = np.array(time) * 1e9 # Convert to ns
    vg = np.array(values[idx_gate_v])
    id_current = np.array(values[idx_drain_i]) * 1e6 # Convert to uA
    
    # Plotting
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True, figsize=(10, 8))
    
    # Input Pulse (Gate)
    ax1.plot(t, vg, 'g-', linewidth=2, label="Gate Voltage")
    ax1.set_ylabel("Voltage (V)")
    ax1.set_title(f"LIF Neuron Transient Response ({run_label})")
    ax1.grid(True)
    ax1.legend()
    
    # Output Response (Drain Current)
    ax2.plot(t, id_current, 'b-', linewidth=2, label="Drain Current")
    ax2.set_ylabel("Current (uA)")
    ax2.set_xlabel("Time (ns)")
    ax2.grid(True)
    ax2.legend()
    
    # Annotation: Time to Fire
    # Find time where Current crosses threshold (e.g., 10uA)
    threshold = 10.0
    fire_idx = np.where(id_current > threshold)[0]
    
    if len(fire_idx) > 0:
        t_fire = t[fire_idx[0]]
        # Find time of input step (approx 0)
        # Assuming step starts at t=0
        latency = t_fire
        
        ax2.axvline(x=t_fire, color='r', linestyle='--', alpha=0.5)
        ax2.text(t_fire + 0.5, max(id_current)/2, f"Latency: {latency:.2f} ns", color='r')
        print(f"Estimated Latency: {latency:.2f} ns")
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, "Transient_Firing.png"))
    plt.close()
    print("Transient plot saved.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        run_label = sys.argv[1]
    else:
        run_label = "Run_04"
        
    plot_transient("Simulations", run_label)
