# Planar FeFET Device Work — Supervisor Meeting Briefing & Q&A Package

This document serves as your complete briefing packet for the upcoming supervisor meeting. It details the **Planar FeFET device structure**, **simulation methodology**, **extracted parameters**, **comparative performance (Planar vs. GAA Nanosheet FeFET)**, **honest caveats**, **specific items requiring supervisor approval**, and **targeted questions to ask**.

---

## 1. Executive Summary & Core Conclusion

- **Device Purpose:** A **bulk planar NMOS FeFET** constructed as a baseline comparison device against the optimized **Gate-All-Around (GAA) 5 nm Nanosheet FeFET** for leaky integrate-and-fire (LIF) neuromorphic SNN applications.
- **Physics Calibration:** **No re-calibration was performed.** The planar device inherits the locked, calibrated HZO Preisach ferroelectric model and interface parameters from the Liao 2022 HZO calibration verbatim (`app_planar.par`). The difference between GAA and Planar is **strictly geometrical**.
- **Core Finding / Takeaway:**
  - **Planar FeFET = Exceptional Binary Memory.** It achieves a massive ON/OFF memory window ratio ($5.91 \times 10^6 \times$) and latches fully ON across the entire read range due to strong ferroelectric charge accumulation in the bulk channel.
  - **GAA FeFET = Superior Analog Neuromorphic Synapse/Neuron.** GAA offers 15 fine, log-linear LTP conductance levels (vs. 8 abrupt levels in Planar), lower subthreshold swing ($79.6$ vs. $98.4\text{ mV/dec}$), $3\times$ lower programming voltage ($+2.0\text{ V}$ vs. $+4.5\text{ V}$), and significantly lower switching energy.

---

## 2. Planar Device Architecture & Parameters

### A. Physical Geometry & Stack Specs
| Parameter | Value | Description / Note |
|---|---|---|
| **Architecture** | Bulk Planar NMOS FeFET | Single top MFIS (Metal-Ferroelectric-Insulator-Semiconductor) gate |
| **Gate Length ($L_{\text{gate}}$)** | $100\text{ nm}$ ($0.100\ \mu\text{m}$) | Channel length |
| **S/D Overlap ($L_{\text{ov}}$)** | $15\text{ nm}$ ($0.015\ \mu\text{m}$) | Gate-to-Source/Drain extension on each side |
| **S/D Contact Length ($L_{\text{sd}}$)** | $50\text{ nm}$ ($0.050\ \mu\text{m}$) | Exposed S/D region length |
| **Interfacial Oxide ($T_{\text{ox}}$)** | $2.0\text{ nm}$ | $\text{SiO}_2$ |
| **Ferroelectric Layer ($T_{\text{fe}}$)** | $10.0\text{ nm}$ | HZO ($\text{Hf}_{0.5}\text{Zr}_{0.5}\text{O}_2$) — window-optimal thickness |
| **Gate Metal ($T_{\text{metal}}$)** | $5.0\text{ nm}$ | TiN (Work Function = $4.35\text{ eV}$) |
| **Body Depth ($T_{\text{body}}$)** | $50.0\text{ nm}$ | Bulk p-type Silicon ($N_{\text{sub}} = 5 \times 10^{17}\text{ cm}^{-3}$ Boron) |
| **S/D Junction ($T_{\text{jun}}$)** | $25.0\text{ nm}$ | $\text{n}^+$ Arsenic doping ($N_{\text{sd}} = 5 \times 10^{19}\text{ cm}^{-3}$) |
| **Electrode Setup** | 4 Terminal | Source, Drain, Top Gate, Grounded Substrate (0 V bottom body) |
| **Width Normalization** | $\text{Areafactor} = 1.0$ | Per-$\mu\text{m}$-width scaling (vs. GAA $\text{Areafactor} = 0.071$) |

### B. Material & Calibration Physics (Locked from Liao 2022 HZO Preisach Model)
- **Ferroelectric (HZO):** Remanent polarization $P_r = 32\ \mu\text{C/cm}^2$, Saturation polarization $P_s = 40\ \mu\text{C/cm}^2$, Coercive field $E_c = 1.4\text{ MV/cm}$, Dielectric constant $\epsilon_r = 33$.
- **Interface Traps ($\text{Si/SiO}_2$):** Fixed Charge Conc = $7 \times 10^{12}\text{ cm}^{-2}$, Acceptor Gaussian Trap Conc = $4 \times 10^{12}\text{ cm}^{-2}$ ($E_{\text{mid}} = 0.45\text{ eV}$ above mid-gap, $\sigma = 0.30\text{ eV}$).
- **Transport & Recombination:** Fermi statistics, OldSlotboom intrinsic density, PhuMob (doping + normal field dependence), Hurkx Band-to-Band Tunneling (B2B), SRH recombination.

---

## 3. Extracted Characterization Results & Operating Point

### A. Operating Point Derivation
- **Read Gate Voltage ($V_{\text{read}}$):** $0.0\text{ V}$ (Read in erased/latched state at zero gate bias).
- **Read Drain Bias ($V_{\text{DS}}$):** $0.05\text{ V}$ ($50\text{ mV}$).
- **Program Voltage Pulse ($V_{\text{pgm}}$):** **$+4.5\text{ V}$, $0.3\ \mu\text{s}$ pulse width**.
  - *Selection Basis:* Evaluated a $V_{\text{pgm}}$ sweep over $\{3.5\text{ V}, 4.5\text{ V}, 5.5\text{ V}\}$.
  - $3.5\text{ V}$ was too gradual (sub-coercive, delayed firing).
  - $5.5\text{ V}$ was too abrupt (fired prematurely at pulse 7).
  - **$+4.5\text{ V}$** yielded clean graded integration from pulse 1 to 8, firing at pulse 9 ($p9$), perfectly matching the GAA "fire-at-$P9$" criterion.
- **Erase / Reset Pulse:** **$-6.0\text{ V}$, $5.0\ \mu\text{s}$** (achieves full reset to deep erased state).

### B. Summary of Extracted Parameters
| Metric | Planar FeFET Extracted Value | Physical Interpretation / Note |
|---|---|---|
| **Subthreshold Swing ($SS_{\text{ers}}$)** | **$98.4\text{ mV/dec}$** | Erased branch (steeper branch) |
| **Erased Threshold Voltage ($V_{\text{th,ers}}$)** | **$0.943\text{ V}$** | Constant-current criterion @ $I_{\text{cc}} = 0.01\ \mu\text{A}/\mu\text{m}$ |
| **Programmed $V_{\text{th}}$ ($V_{\text{th,pgm}}$)** | **$< -1.0\text{ V}$ (Latched fully ON)** | Never crosses $I_{\text{cc}}$ floor down to $V_G = -1.0\text{ V}$ |
| **Memory Window ($MW_{\text{volts}}$)** | **$> 1.94\text{ V}$** | Lower bound ($V_{\text{th,ers}} - V_G^{\text{min}}$); true window is larger |
| **Off Resistance ($R_{\text{off}}$)** | **$1.22 \times 10^9\ \Omega$** ($1.22\text{ G}\Omega$) | Erased state read at $V_G = 0.0\text{ V}$ ($I_{\text{off}} = 4.11 \times 10^{-5}\ \mu\text{A}/\mu\text{m}$) |
| **On Resistance ($R_{\text{on}}$)** | **$205.8\ \Omega$** | Programmed state read at $V_G = 0.0\text{ V}$ ($I_{\text{on}} = 242.9\ \mu\text{A}/\mu\text{m}$) |
| **ON/OFF Current Ratio ($MW_{\text{ratio}}$)** | **$5.91 \times 10^6 \times$** | Read at $V_G = 0.0\text{ V}$, $V_{\text{DS}} = 0.05\text{ V}$ |
| **Minimum Conductance ($g_{\text{min}}$)** | **$8.22 \times 10^{-10}\text{ S}$** | $1 / R_{\text{off}}$ (SNN stage1 model input) |
| **Maximum Conductance ($g_{\text{max}}$)** | **$4.86 \times 10^{-3}\text{ S}$** | $1 / R_{\text{on}}$ (SNN stage1 model input) |
| **Analog LTP Levels** | **8 Levels** | Distinguishable monotonic steps ($\ge 1.5\times$ separation) |
| **Mean $V_{\text{th}}$ Shift per Pulse ($\Delta V_{\text{th}}$)** | **$-46.0\text{ mV/pulse}$** | Graded threshold reduction during potentiation |
| **Energy per Program Pulse ($E_{\text{pulse}}$)** | **$6.85 \times 10^{-13}\text{ J/\mu m}$** | Calculated via $\int V_G \cdot |I_G|\ dt$ over pulse duration |
| **Fire Ratio ($I_D(p9) / I_{\text{baseline}}$)** | **$1.02 \times 10^5 \times$** | Conductance jump at spike fire ($p9$ vs baseline) |
| **Retention (100 $\mu\text{s}$ Hold)** | **$67.8\%$ Retained ($105\ \mu\text{A}/\mu\text{m}$)** | Post-write transient settles to non-volatile plateau by $40\ \mu\text{s}$ |
| **Retained Polarization Change ($\Delta P$)** | **$3.89\ \mu\text{C/cm}^2$** | Retained top FE polarization difference $|P_{\text{pgm}} - P_{\text{ers}}|$ |

---

## 4. Planar vs. Gate-All-Around (GAA) Comparative Analysis

Below is the side-by-side comparison table to present during the meeting:

| Metric / Feature | GAA (5 nm Nanosheet, Double Gate) | Bulk Planar (50 nm Body, Single Top Gate) | Comparison / Winner |
|---|---|---|---|
| **Gate Oxide / FE Thickness** | $1.0\text{ nm } \text{SiO}_2\ /\ 7.0\text{ nm HZO}$ | $2.0\text{ nm } \text{SiO}_2\ /\ 10.0\text{ nm HZO}$ | Planar uses standard planar FE thickness |
| **Subthreshold Swing ($SS_{\text{ers}}$)** | **$79.6\text{ mV/dec}$** | **$98.4\text{ mV/dec}$** | **GAA wins** (superior electrostatics & gate control) |
| **$V_{\text{th}}$ Memory Window (V)** | $0.336\text{ V}$ | **$> 1.94\text{ V}$** | **Planar wins** (much larger absolute $V_{\text{th}}$ shift) |
| **ON/OFF Current Ratio (@$V_G=0$)** | $3,137\times$ | **$5,914,400\times$** ($5.91\times 10^6\times$) | **Planar wins** (massive binary ON/OFF separation) |
| **$R_{\text{off}}$ / $R_{\text{on}}$ Range** | $7.14\times 10^7\ \Omega\ /\ 2.34\times 10^6\ \Omega$ | $1.22\times 10^9\ \Omega\ /\ 2.06\times 10^2\ \Omega$ | Planar spans wider dynamical range |
| **Conductance Range ($g_{\text{min}} \rightarrow g_{\text{max}}$)** | $1.40\times 10^{-8}\text{ S} \rightarrow 4.27\times 10^{-7}\text{ S}$ | $8.22\times 10^{-10}\text{ S} \rightarrow 4.86\times 10^{-3}\text{ S}$ | Planar has lower $g_{\text{min}}$ and much higher $g_{\text{max}}$ |
| **Analog LTP Resolution** | **15 Levels** (Smooth, log-linear) | **8 Levels** (Abrupt turn-on $p8 \rightarrow p15$) | **GAA wins** (finer weight updating for SNNs) |
| **$\Delta V_{\text{th}}$ per Pulse** | $-18.3\text{ mV}$ | $-46.0\text{ mV}$ | Planar shifts more per pulse |
| **Operating Program Voltage ($V_{\text{pgm}}$)** | **$+2.0\text{ V}$** | **$+4.5\text{ V}$** | **GAA wins** (lower voltage operation) |
| **Pulse Switching Energy** | $\sim 1.4 \times 10^{-17}\text{ J}$* | $6.85 \times 10^{-13}\text{ J/\mu m}$* | **GAA wins** (lower energy consumption) |
| **Fire Ratio ($I_D(p9)/I_{\text{base}}$)** | $30.6\times$ | $101,900\times$ | Planar exhibits near-digital firing jump |
| **Retention (@ $100\ \mu\text{s}$)** | Non-volatile (Flat) | $67.8\%$ of peak ($105\ \mu\text{A}/\mu\text{m}$ plateau) | Both non-volatile; planar shows relaxation transient |
| **Retained Polarization ($\Delta P$)** | $\sim 2.26\ \mu\text{C/cm}^2$ | $3.89\ \mu\text{C/cm}^2$ | Planar retains higher polarization difference |

> [!IMPORTANT]
> **Energy Comparison Caveat to Mention:**
> The absolute energy values between GAA ($\sim 1.4 \times 10^{-17}\text{ J}$) and Planar ($6.85 \times 10^{-13}\text{ J}$) reflect both physical differences ($3\times$ higher voltage, thicker FE stack) and extraction methodology differences ($\text{Areafactor} = 0.071$ vs $1.0$, $Q_{\text{switch}} \cdot V$ vs $\int V \cdot I\ dt$). Highlight to the supervisor that while Planar is directionally higher in energy, a unified re-extraction will be presented in the final manuscript.

---

## 5. Items to Present for Supervisor Approval

1. **Geometry & Stack Selection Approval:**
   - Confirm approval of the chosen planar geometry: $L_{\text{gate}} = 100\text{ nm}$, $T_{\text{ox}} = 2\text{ nm}$, $T_{\text{fe}} = 10\text{ nm}$, bulk body $T_{\text{body}} = 50\text{ nm}$ ($N_{\text{sub}} = 5\times 10^{17}\text{ cm}^{-3}$).
   - Inform him that keeping the identical calibrated physics/parameters (`app_planar.par`) provides a clean **geometry-only comparison** against GAA.
2. **Operating Point Selection Approval:**
   - Present the chosen operating point ($V_{\text{read}} = 0.0\text{ V}$, $V_{\text{DS}} = 0.05\text{ V}$, $V_{\text{pgm}} = +4.5\text{ V}$ / $0.3\ \mu\text{s}$, $V_{\text{ers}} = -6.0\text{ V}$ / $5\ \mu\text{s}$).
   - Explain that $+4.5\text{ V}$ was chosen because it achieves firing at pulse 9 ($p9$), matching the exact LIF spiking benchmark used for GAA.
3. **Neuromorphic Narrative Approval:**
   - Present the main scientific conclusion: **Bulk Planar FeFET excels as a high-density digital memory (large window, latching), but GAA FeFET is vastly superior as an analog neuromorphic synapse/LIF neuron due to finer turn-on linearity, lower program voltage ($2.0\text{ V}$ vs $4.5\text{ V}$), and steeper electrostatics ($SS=79.6\text{ vs }98.4\text{ mV/dec}$).**
4. **SNN Model Integration Approval:**
   - Confirm that the extracted planar parameters ($g_{\text{min}} = 8.22\times 10^{-10}\text{ S}$, $g_{\text{max}} = 4.86\times 10^{-3}\text{ S}$, $n_{\text{levels}} = 8$) have been formatted in `planar_params.py` as a drop-in substitute for the stage-1 ECG-LSNN SNN model.

---

## 6. Specific Questions to Ask the Supervisor

During the meeting, ask the supervisor the following specific questions to guide next steps:

1. **On Geometry & Physics Alignment:**
   - *"Is the baseline planar geometry ($L_G = 100\text{ nm}$, $T_{ox} = 2\text{ nm}$, $T_{fe} = 10\text{ nm}$, $50\text{ nm}$ bulk body) acceptable for our comparison baseline, or would you prefer us to scale $L_G$ down to match the short-channel dimensions of the GAA device (e.g. $L_G = 30\text{ nm}$ or $12\text{ nm}$)?"*
2. **On Calibration Strategy:**
   - *"We intentionally kept the exact calibrated FE and interface parameters (Liao 2022 Preisach model) locked without re-tuning for planar, so that the comparison isolates purely geometrical effects. Do you agree with this locked-parameter protocol for the paper?"*
3. **On Operating Point & Firing Criterion:**
   - *"We tuned $V_{\text{pgm}}$ to $+4.5\text{ V}$ so the planar neuron fires at pulse 9 ($p9$), matching our GAA firing criterion. Does this fire-at-$p9$ alignment satisfy your requirements for a fair LIF comparison, or should we align them at identical program voltages (e.g. comparing both at $V_{\text{pgm}} = +2.0\text{ V}$ where planar does not switch)?"*
4. **On Energy Extraction Methodology:**
   - *"For energy per pulse, we integrated $V_G \cdot |I_G| dt$ over the gate transient for planar, while using $Q_{\text{switch}} \cdot V$ for GAA. Should we standardize both devices to the full transient integral method ($\int V \cdot I dt$) for the manuscript figures?"*
5. **On Paper Presentation & SNN Benchmarking:**
   - *"When presenting the SNN classification results on the ECG-LSNN pipeline, should we emphasize Planar's digital ON/OFF nature as an intentional contrast to GAA's analog resolution, or should we include a multi-pulse averaging scheme for planar to artificially improve its level count?"*

---

## 7. Quick Reference: Key Plots & Data Files

| Artifact / Description | File Location |
|---|---|
| **Planar Device Datasheet** | [PLANAR_DEVICE.md](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Planar_Device_Work/PLANAR_DEVICE.md) |
| **GAA vs Planar Comparison Table** | [PLANAR_vs_GAA.md](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Planar_Device_Work/PLANAR_vs_GAA.md) |
| **Extracted SNN Parameters** | [planar_params.py](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Planar_Device_Work/planar_params.py) |
| **Memory Window Overlay Plot** | [compare_memwin.png](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Planar_Device_Work/plots/compare_memwin.png) |
| **Analog LTP Comparison Plot** | [compare_ltp.png](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Planar_Device_Work/plots/compare_ltp.png) |
| **Retention / Leak Comparison Plot** | [compare_retention.png](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Planar_Device_Work/plots/compare_retention.png) |
| **Sentaurus SDE Mesh Command** | [sde_planar.cmd](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Planar_Device_Work/sde/sde_planar.cmd) |
| **Comparison Analysis Script** | [analyze_compare.py](file:///f:/RESEARCH/FeFET%20x%20ML/TCAD%20Files/GAAFet/Planar_Device_Work/analyze_compare.py) |

