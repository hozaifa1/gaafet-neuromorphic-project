import pandas as pd
import matplotlib.pyplot as plt
import os
import sys

def generate_plots(sim_dir, run_id, params):
    csv_path = os.path.join(sim_dir, "hysteresis_data.csv")
    if not os.path.exists(csv_path):
        print(f"Error: {csv_path} not found.")
        return

    # Read Data
    df = pd.read_csv(csv_path)
    
    # Split Segments
    fwd = df[df['Leg'] == 'Fwd']
    rev = df[df['Leg'] == 'Rev']

    # Create Output Dir
    out_dir = os.path.join(sim_dir, "output_curves")
    os.makedirs(out_dir, exist_ok=True)

    # Setup Plot Style
    plt.style.use('default')
    
    # --- Plot 1: Id-Vg (Log Scale) ---
    plt.figure(figsize=(10, 8))
    plt.semilogy(fwd['Vg'], fwd['Id'], 'b-', linewidth=2, label='Forward Sweep (-6V -> +6V)')
    plt.semilogy(rev['Vg'], rev['Id'], 'r--', linewidth=2, label='Reverse Sweep (+6V -> -6V)')
    
    # Annotations
    plt.title(f"Run {run_id}: Id-Vg Characteristics (Log)", fontsize=16)
    plt.xlabel("Gate Voltage (V)", fontsize=14)
    plt.ylabel("Drain Current (A)", fontsize=14)
    plt.grid(True, which="both", ls="-", alpha=0.2)
    plt.legend(fontsize=12)
    
    # Add Parameter Text Box
    param_text = "\n".join([f"{k}: {v}" for k, v in params.items()])
    plt.text(0.05, 0.95, param_text, transform=plt.gca().transAxes, 
             fontsize=10, verticalalignment='top', 
             bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    
    plt.savefig(os.path.join(out_dir, f"run{run_id}_id_vg_log.png"), dpi=300)
    plt.close()

    # --- Plot 2: Id-Vg (Linear Scale) ---
    plt.figure(figsize=(10, 8))
    plt.plot(fwd['Vg'], fwd['Id'], 'b-', linewidth=2, label='Forward')
    plt.plot(rev['Vg'], rev['Id'], 'r--', linewidth=2, label='Reverse')
    
    plt.title(f"Run {run_id}: Id-Vg Characteristics (Linear)", fontsize=16)
    plt.xlabel("Gate Voltage (V)", fontsize=14)
    plt.ylabel("Drain Current (A)", fontsize=14)
    plt.grid(True, alpha=0.5)
    plt.legend(fontsize=12)
    
    plt.text(0.05, 0.95, param_text, transform=plt.gca().transAxes, 
             fontsize=10, verticalalignment='top', 
             bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))

    plt.savefig(os.path.join(out_dir, f"run{run_id}_id_vg_lin.png"), dpi=300)
    plt.close()

    # --- Plot 3: Polarization-Vg (Hysteresis Loop) ---
    plt.figure(figsize=(10, 8))
    # Convert Pol to uC/cm2
    plt.plot(fwd['Vg'], fwd['Pol']*1e6, 'g-', linewidth=2, label='Forward')
    plt.plot(rev['Vg'], rev['Pol']*1e6, 'm--', linewidth=2, label='Reverse')
    
    plt.title(f"Run {run_id}: Ferroelectric Polarization", fontsize=16)
    plt.xlabel("Gate Voltage (V)", fontsize=14)
    plt.ylabel("Polarization (uC/cm²)", fontsize=14)
    plt.grid(True, alpha=0.5)
    plt.legend(fontsize=12)
    
    plt.text(0.05, 0.95, param_text, transform=plt.gca().transAxes, 
             fontsize=10, verticalalignment='top', 
             bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))

    plt.savefig(os.path.join(out_dir, f"run{run_id}_pol_vg.png"), dpi=300)
    plt.close()
    
    print(f"Plots saved to {out_dir}")

if __name__ == "__main__":
    # Hardcoded parameters for Run 1
    params = {
        "Workfunction": "4.35 eV",
        "Fixed Charge": "5.15e12 cm-2",
        "Pr": "16 uC/cm2",
        "Ec": "1.2 MV/cm",
        "Vth (Fwd)": "124 mV",
        "Vth (Rev)": "-547 mV",
        "MW": "671 mV",
        "Ion": "588 uA"
    }
    
    sim_dir = "Simulations" if os.path.exists("Simulations") else "."
    generate_plots(sim_dir, "1", params)
