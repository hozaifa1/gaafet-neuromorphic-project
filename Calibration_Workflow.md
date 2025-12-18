# Calibration Workflow & To-Do List

This document outlines the step-by-step process to calibrate the GAAFET LIF neuron simulation against the reference design.

## 1. Analysis of Current Status vs. Target
**Current Simulation Results (`n2_des`):**
- **I_off:** ~1.95e-20 A (Likely too ideal/low compared to experiment).
- **I_on:** ~91.5 µA (Matches target range of 10-100 µA).
- **V_th:** ~0.43 V (at 94 nA).
- **Characteristics:** Standard MOSFET turn-on. "Kink" effect (LIF firing) needs verification in the logarithmic plot.

**Target Characteristics (from "Design of energy-efficient LIF neuron..." & Workflow):**
- **Firing Threshold (Kink):** Sharp increase in current at a specific Vg/Vds due to Floating Body Effect + Impact Ionization.
- **V_ds:** 1.0 V (Operating voltage).
- **Target I_th:** 94 nA.
- **Key Feature:** Hysteresis window (Memory Window) due to Ferroelectric HZO.

## 2. Hyper-Specific To-Do List

### Phase A: Curve Analysis & Validation
- [ ] **Verify Log-Plot:** Ensure `output_curves/n2_des_Id_vs_Vg.png` is plotted in Log-Linear scale. The "Kink" is often only visible in Log scale as a hump in the subthreshold or inversion region.
- [ ] **Identify "Kink" Presence:** Look for a sudden change in slope or a bump in the I_d curve. If absent, the Impact Ionization (II) rate is too low or the Body Effect is suppressed.
- [ ] **Check Hysteresis:** Run the sweep as `DoubleSweep` (0 -> Vg_max -> 0) or `Cyclic` to see the memory window. Current data appears to be a single sweep.

### Phase B: Sentaurus Workbench (SWB) Calibration Setup
- [ ] **Define Variables in SWB:**
    - Ensure the following parameters are parameterized in your input files (using `@parameter@` syntax):
        - `Workfunction` (Gate Metal)
        - `Doping_Channel` (Body Doping)
        - `Avalanche_d0` (Impact Ionization Coeff)
        - `Ferro_Pr` (Remnant Polarization)
        - `Ferro_Ec` (Coercive Field)
- [ ] **Create Parameter Sweeps (Clicking Guide):**
    - **Step 1:** In SWB, locate the "Parameters" list (usually on the left or top pane). Add new parameters if they don't exist as columns.
    - **Step 2:** Select the `sdevice` node (or `sde` node if changing geometry/doping).
    - **Step 3 (Tree Split):** Right-click the node > **Add** > **Split**. This creates two child branches.
    - **Step 4:** On the new branches, click inside the parameter column (e.g., `Workfunction`) and enter different values (e.g., `4.5` on Branch A, `4.6` on Branch B).
    - **Step 5:** Repeat for other variables. This creates a "Tree" of experiments.
    - **Step 6:** Select the root of the split and press **Ctrl+R** (or right-click > Run) to run all branches.

### Phase C: Parameter Tuning Strategy (Calibration)
Perform these sweeps in order to match the curve:

1.  **Match Threshold Voltage (V_th):**
    - **Parameter:** `Workfunction` (Gate Metal).
    - **Range:** 4.4 eV to 4.8 eV.
    - **Goal:** Shift curve horizontally to align V_th with ~0.4 - 0.5 V (or target from paper).

2.  **Match Off-Current (I_off):**
    - **Parameter:** `Doping_Channel` (P-type Boron).
    - **Range:** 1e15 to 1e17 cm^-3.
    - **Goal:** Adjust subthreshold floor. Higher doping = lower I_off but higher V_th.

3.  **Trigger the "Kink" (LIF Firing):**
    - **Parameter:** `Avalanche_Unibo2_d0` (Impact Ionization).
    - **Range:** 1e5, 1e6, 5e6, 1e7.
    - **Goal:** If the kink is missing, **increase** `d0`. The Workflow recommends `1.0e6`. Try higher (`5.0e6`) if no kink appears.
    - **Secondary Parameter:** `AreaFactor` (if 2D simulation current is too low to sustain FB effect).

4.  **Tune Hysteresis (Memory Window):**
    - **Parameter:** `Ferro_Pr` (Remnant Polarization).
    - **Range:** 15, 20, 25 uC/cm^2.
    - **Goal:** Widens the memory window.

### Phase D: Final Verification
- [ ] **Overlay Plot:** Create a Python script to overlay the Simulated Curve vs. Digitized Paper Curve (if data points available).
- [ ] **Extract Metrics:** Calculate Error % for V_th, SS, I_on.

## 3. Important Clicking Guide for SWB (v2023.12)
- **Parameterization:** To make a value sweepable, you MUST replace the hardcoded number in the `.cmd` file with `@VarName@`.
    - *Example:* Change `Workfunction = 4.6` to `Workfunction = @WF@`.
    - Then add `WF` as a parameter in the SWB project spreadsheet.
- **Visualizing Results:**
    - Select multiple finished nodes (hold Ctrl).
    - Right-click > **Inspect** > **Inspect Results**.
    - This overlays curves from multiple experiments.

## 4. Next Actions
1. **Modify `sdevice_gaafet_lif.par`**: Ensure `d0_e` and `d0_h` are parameterized or set to `1.0e6`.
2. **Modify `sdevice_gaafet_lif.cmd`**: Ensure the voltage sweep covers the full hysteresis range (-2V to +2V and back).
3. **Run Sweep:** Execute the variation of `Workfunction` to center the curve.
