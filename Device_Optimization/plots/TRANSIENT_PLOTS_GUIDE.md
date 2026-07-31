# GAA-FeFET Comprehensive Plotting Guide

This guide details exactly which CSV files to load, which columns to plot on the X and Y axes, any required mathematical scalings, and how to structure the 12 key plots to match the data grounding and physical details of the publication slides.

---

## Part A: Synaptic Physics & Device Characteristics

### Plot 1: Retained-State Memory Window ($I_{DS}$-$V_{GS}$)
*   **Source File:** [`csv_export/raw/memory_window_iv.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/raw/memory_window_iv.csv)
*   **X-Axis:** `Vg_V` (Gate voltage swept from $-1.5\text{ V}$ to $+1.5\text{ V}$)
*   **Y-Axis:** Plot two curves: `Id_erased_uA_um` (OFF state) and `Id_programmed_uA_um` (ON state)
*   **Y-Scale:** Logarithmic (e.g., `semilogy`)
*   **Scaling:** None (units are already in $\mu\text{A}/\mu\text{m}$)
*   **Details:** Displays the stable memory window shift ($\Delta V_{th} \approx 0.3\text{ V}$) and highlights the $3140\times$ ON/OFF ratio at $V_{GS} = 0\text{ V}$.

### Plot 2: Analog Synaptic Weight LTP Potentiation
*   **Source File:** [`csv_export/raw/ltp_potentiation.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/raw/ltp_potentiation.csv)
*   **X-Axis:** `pulse_n` (Discrete pulse number, $1$ to $15$)
*   **Y-Axis:** `Id_uA_per_um` (Read current at $V_{GS} = 0\text{ V}$)
*   **Scaling:** None (conductance in $\mu\text{A}/\mu\text{m}$)
*   **Details:** Shows the 15 distinct, monotonic conductance states programmed under cumulative $+2.0\text{ V}$, $0.3\text{ }\mu\text{s}$ spikes.

### Plot 3: Synaptic LTP Temperature Stability
*   **Source File:** [`csv_export/raw/ltp_vs_temperature.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/raw/ltp_vs_temperature.csv)
*   **X-Axis:** `pulse_n` (Pulse number, $1$ to $15$)
*   **Y-Axis:** Plot three curves: `G_250K_uA_um` (250 K), `G_300K_uA_um` (300 K), and `G_350K_uA_um` (350 K)
*   **Scaling:** None (units are in $\mu\text{A}/\mu\text{m}$)
*   **Details:** Demonstrates the thermal robustness of cumulative programming.

### Plot 4: Non-Volatile State Retention Hold
*   **Source File:** [`csv_export/raw/leak_retention.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/raw/leak_retention.csv)
*   **X-Axis:** `t_us` (Hold time in microseconds, $0$ to $100\text{ }\mu\text{s}$)
*   **Y-Axis:** `G_uA_um` (Channel conductance in $\mu\text{A}/\mu\text{m}$)
*   **Scaling:** None
*   **Details:** Shows the post-write relaxation stability of the programmed ON state at $V_{GS} = 0\text{ V}$.

---

## Part B: Parameter Optimization & Co-Design Sweeps

### Plot 5: Memory Window vs. Ferroelectric Thickness ($T_{FE}$)
*   **Source File:** [`csv_export/sweeps/tfe_sweep.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/sweeps/tfe_sweep.csv)
*   **X-Axis:** `t_fe_nm` (FE thickness swept: $5$, $7$, $10$, $12\text{ nm}$)
*   **Y-Axis:** `window` (ON/OFF ratio)
*   **Scaling:** None
*   **Details:** Illustrates how the memory window ratio peaks around 7–10 nm.

### Plot 6: Operating Voltage ($V_{op}$) vs. Ferroelectric Thickness ($T_{FE}$)
*   **Source File:** [`csv_export/sweeps/tfe_sweep.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/sweeps/tfe_sweep.csv)
*   **X-Axis:** `t_fe_nm` (FE thickness swept: $5$, $7$, $10$, $12\text{ nm}$)
*   **Y-Axis:** `v_op_V` (Operating programming voltage in Volts)
*   **Scaling:** None
*   **Details:** Shows the drop in programming voltage ($3.0\text{ V} \rightarrow 2.5\text{ V}$) as the FE layer is thinned, reducing spike energy.

### Plot 7: OFF-State Leakage Current vs. Interfacial Layer Thickness ($T_{OX}$)
*   **Source File:** [`csv_export/sweeps/tox_sweep.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/sweeps/tox_sweep.csv)
*   **Filter Condition:** Filter rows where `eval` equals `fixed4V`
*   **X-Axis:** `t_ox_nm` (IL oxide thickness: $0.5$, $1.0$, $1.5$, $2.0\text{ nm}$)
*   **Y-Axis:** `id_off_uA_um` (OFF current in $\mu\text{A}/\mu\text{m}$)
*   **Scaling:** None
*   **Details:** Illustrates that thinning the oxide down to $1\text{ nm}$ suppresses the OFF current by $3000\times$ due to stronger FE-to-channel coupling.

### Plot 8: Memory Window vs. Interfacial Layer Thickness ($T_{OX}$)
*   **Source File:** [`csv_export/sweeps/tox_sweep.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/sweeps/tox_sweep.csv)
*   **Filter Condition:** Filter rows where `eval` equals `fixed4V`
*   **X-Axis:** `t_ox_nm` (IL oxide thickness: $0.5$, $1.0$, $1.5$, $2.0\text{ nm}$)
*   **Y-Axis:** `window` (ON/OFF ratio)
*   **Scaling:** None
*   **Details:** Shows that the window peaks at $T_{OX} = 1.0\text{ nm}$ and degrades below that.

### Plot 9: Memory Window vs. Nanosheet Body Thickness ($T_{SI}$)
*   **Source File:** [`csv_export/sweeps/tsi_sweep.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/sweeps/tsi_sweep.csv)
*   **X-Axis:** `t_si_nm` (Nanosheet thickness: $5$, $8$, $10$, $12$, $15\text{ nm}$)
*   **Y-Axis:** `window` (ON/OFF ratio)
*   **Scaling:** None
*   **Details:** Shows the 8× window enhancement as the body is thinned, showing better gate electrostatic control.

### Plot 10: Discrimination Ratio ($DR$) vs. Read Gate Bias ($V_{READ}$)
*   **Source File:** [`csv_export/sweeps/vread_sweep.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/sweeps/vread_sweep.csv)
*   **X-Axis:** `vread_V` (Read bias swept from $-1.3\text{ V}$ to $-0.3\text{ V}$)
*   **Y-Axis:** `dr` (nominal ON/OFF discrimination ratio)
*   **Scaling:** None
*   **Details:** Shows the inflation of the nominal window at deeper negative read voltages.

### Plot 11: OFF-State Current vs. Read Gate Bias ($V_{READ}$)
*   **Source File:** [`csv_export/sweeps/vread_sweep.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/sweeps/vread_sweep.csv)
*   **X-Axis:** `vread_V` (Read bias swept from $-1.3\text{ V}$ to $-0.3\text{ V}$)
*   **Y-Axis:** `id_off_uA_um` (OFF current in $\mu\text{A}/\mu\text{m}$)
*   **Scaling:** None
*   **Details:** Highlights the read-disturb depolarization and GIDL leakage onset.

---

## Part C: High-Resolution Time-Domain Transients

### Plot 12: Transient Write Polarization & Switching Currents (All 9 pulses)
*   **Source Folder:** [`csv_export/iv_curves/t5_fe07/`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Device_Optimization/csv_export/iv_curves/t5_fe07)
*   **Files to load:** Load files `p01_write_t5_fe07_v025_des.csv` through `p09_write_t5_fe07_v025_des.csv` (101 time-steps per file)
*   **Variables to Plot:**
    1.  **FE Polarization ($P_y$):** Plot column `Pos(0,0.007) Polarization/y`. 
        *   *Scaling:* Multiply values by `1e6` to convert C/cm² to $\mu\text{C/cm}^2$.
    2.  **Gate Current ($I_G$):** Plot column `gate_contact TotalCurrent`.
        *   *Scaling:* Compute `abs(gate_contact TotalCurrent) * 1e6 / 0.090` to convert Amperes to $\mu\text{A}/\mu\text{m}$ (where channel width $W = 0.090\text{ }\mu\text{m}$).
*   **How to plot (Overlaid vs. Stitched):**
    *   **Method A (Overlaid transients):** For each of the 9 files, subtract the initial timestamp value from the `time` column:
        $$t_{\text{plot}} = (time - time_0) \times 10^9 \quad \text{(X-axis in ns)}$$
        Plot all 9 curves on top of each other. This highlights the change in switching speed and peak current from Pulse 1 to Pulse 9.
    *   **Method B (Stitched cumulative staircase):** Stitch the 9 curves back-to-back chronologically. Shift the `time` column of the $X$-th pulse by adding the cumulative time delay:
        $$t_{\text{stitched}} = [time + (X - 1) \times t_{\text{pulse\_period}}] \times 10^6 \quad \text{(X-axis in }\mu\text{s)}$$
        Plot them as a single continuous time-series. This highlights the staircase step-up of polarization ($P_y$) and the sequence of current spikes.
