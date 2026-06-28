# GAA-FeFET Calibration Plots Guide

This guide details exactly which CSV files to load, which columns to plot on the X and Y axes, any required mathematical scalings, and how to structure the key calibration figures to match the data grounding and physical details of the publication slides.

---

## Part A: Hysteresis Loop & Material Validation

### Plot 1: Polarization-Voltage (P-V) Hysteresis Loop
*   **Source Files:** 
    *   Down-Sweep branch: [`Calibration/csvs/pe_loop_down.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Calibration/csvs/pe_loop_down.csv)
    *   Up-Sweep branch: [`Calibration/csvs/pe_loop_up.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Calibration/csvs/pe_loop_up.csv)
*   **X-Axis:** `Vg_V` (Gate voltage swept: $+4.0\text{ V} \rightarrow -4.0\text{ V}$ and $-4.0\text{ V} \rightarrow +4.0\text{ V}$)
*   **Y-Axis:** `P_uC_cm2` (HZO ferroelectric polarization)
*   **Scaling:** None (units are already in $\mu\text{C/cm}^2$)
*   **Details:** Stitch the two sweep branches back-to-back to form a closed, symmetric loop. Displays the remanent polarization ($P_r \approx 32\text{ }\mu\text{C/cm}^2$) and coercive voltage ($V_c \approx 1.2\text{ V}$).

### Plot 2: Polarization-Electric Field (P-E) Loop
*   **Source Files:** 
    *   Down-Sweep branch: [`Calibration/csvs/pe_loop_down.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Calibration/csvs/pe_loop_down.csv)
    *   Up-Sweep branch: [`Calibration/csvs/pe_loop_up.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Calibration/csvs/pe_loop_up.csv)
*   **X-Axis:** `E_MV_cm` (Internal electric field in the HZO layer in $\text{MV/cm}$)
*   **Y-Axis:** `P_uC_cm2` (HZO ferroelectric polarization)
*   **Scaling:** None (units are already in $\text{MV/cm}$ and $\mu\text{C/cm}^2$)
*   **Details:** Stitch both sweep branches together. This shows the polarization directly against the internal oxide field, highlighting the coercive field ($F_c \approx 1.4\text{ MV/cm}$) and showing the pinched hysteresis shape due to the series voltage-divider of the SiO2 interfacial layer.

---

## Part B: Device-Level Calibration Overlay (Liao 2022 Fig. 7)

### Plot 3: Gate-Transfer Calibration Overlay ($I_{DS}$-$V_{GS}$)
*   **Source Files:**
    *   TCAD Post-Erase (ERS) sweep: [`Calibration/csvs/tcad_cal_n16_postERS.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Calibration/csvs/tcad_cal_n16_postERS.csv)
    *   TCAD Post-Program (PGM) sweep: [`Calibration/csvs/tcad_cal_n16_postPGM.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Calibration/csvs/tcad_cal_n16_postPGM.csv)
    *   Liao Fig. 7 ERS dots: [`Calibration/csvs/dots_ERS.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Calibration/csvs/dots_ERS.csv)
    *   Liao Fig. 7 PGM dots: [`Calibration/csvs/dots_PGM.csv`](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Calibration/csvs/dots_PGM.csv)
*   **X-Axis:** `Vg_V` (Gate voltage from $-3.0\text{ V}$ to $+3.5\text{ V}$)
*   **Y-Axis:** Plot 4 curves on the same plot:
    1.  TCAD post-ERS: `Id_A_um` (from `tcad_cal_n16_postERS.csv` scaled by `scale`)
    2.  TCAD post-PGM: `Id_A_um` (from `tcad_cal_n16_postPGM.csv` scaled by `scale`)
    3.  Liao post-ERS dots: `I_D_A_per_um` (from `dots_ERS.csv`)
    4.  Liao post-PGM dots: `I_D_A_per_um` (from `dots_PGM.csv`)
*   **Y-Scale:** Logarithmic (e.g., `semilogy`)
*   **Scaling:**
    *   Liao dots are plotted as-is (units in $\text{A}/\mu\text{m}$).
    *   Scale the TCAD current by a single physical width factor to match the experimental sheet current:
        $$\text{scale} = \frac{I_{\text{Liao, sat}}}{\text{median}(I_{\text{TCAD, ERS}}\text{ at } V_G \ge 2.5\text{ V})} \quad \text{where } I_{\text{Liao, sat}} = 4.8\times 10^{-6}\text{ A}/\mu\text{m}$$
        $$\text{scaled\_Id} = \text{Id\_A\_um} \times \text{scale}$$
*   **Details:** Displays the excellent overlay matching the $1.30\text{ V}$ memory window (measured at $10^{-7}\text{ A/um}$) and the $3140\times$ ON/OFF dynamic range. Plot Liao data as open markers and TCAD as solid lines.

### Plot 4: Overdrive-Aligned Shape Comparison
*   **Source Files:** Same as Plot 3.
*   **X-Axis:** Normalised gate overdrive voltage:
    $$V_{\text{overdrive}} = V_G - V_t \quad \text{(V)}$$
    *   where $V_t$ is determined by a constant-current criterion of $100\text{ nA/um}$ ($10^{-7}\text{ A/um}$) on each branch.
*   **Y-Axis:** Normalised channel current:
    $$\frac{I}{I_{\text{on}}}$$
    *   where $I_{\text{on}}$ is the current at $V_{\text{overdrive}} = +0.4\text{ V}$ for each branch.
*   **Y-Scale:** Logarithmic
*   **Scaling:** Align the X-axis for each branch by subtracting its respective $V_t$; normalize the Y-axis by dividing by its respective $I_{\text{on}}$ value.
*   **Details:** Compares subthreshold slope and electrostatic control directly by removing rigid voltage/current offsets. Highlights the sub-thermal subthreshold swing ($45\text{ mV/dec}$) at room temperature due to negative capacitance.
