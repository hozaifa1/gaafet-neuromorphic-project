import pandas as pd
import matplotlib.pyplot as plt
import os

def main():
    base_dir = r"f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations\calibration outputs"
    
    # Plot 1: Polarization vs Voltage
    pol_file = os.path.join(base_dir, "polarization_vs_voltage.csv")
    if os.path.exists(pol_file):
        df_pol = pd.read_csv(pol_file)
        plt.figure(figsize=(8, 6))
        plt.plot(df_pol["Voltage"], df_pol["Polarization"], label="Polarization", color='b')
        plt.xlabel("Voltage (V)")
        plt.ylabel("Polarization (uC/cm^2)")
        plt.title("Polarization vs Voltage")
        plt.grid(True)
        plt.legend()
        out_path = os.path.join(base_dir, "plot_polarization.png")
        plt.savefig(out_path)
        print(f"Saved {out_path}")
        plt.close()
    else:
        print(f"File not found: {pol_file}")

    # Plot 2: Hysteresis (Id vs Vg)
    hyst_file = os.path.join(base_dir, "hysteresis_id_vg.csv")
    if os.path.exists(hyst_file):
        df_hyst = pd.read_csv(hyst_file)
        plt.figure(figsize=(8, 6))
        
        # Id-Vg is usually semilog y
        # Filter out negative or zero currents for log plot just in case, though physical currents shouldn't be zero in simulation usually unless strictly 0.
        # But let's plot absolute value of current just in case of sign flips.
        
        plt.semilogy(df_hyst["Gate Voltage"], df_hyst["Drain Current"].abs(), label="Drain Current", color='r')
        plt.xlabel("Gate Voltage (V)")
        plt.ylabel("Drain Current (A)")
        plt.title("Hysteresis (Id vs Vg)")
        plt.grid(True, which="both", ls="-")
        plt.legend()
        out_path = os.path.join(base_dir, "plot_hysteresis.png")
        plt.savefig(out_path)
        print(f"Saved {out_path}")
        plt.close()
    else:
        print(f"File not found: {hyst_file}")

if __name__ == "__main__":
    main()
