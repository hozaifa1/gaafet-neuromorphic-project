# Paper 1: Novel GAA-FeFET Structural Optimization for High-Performance LIF Neurons

## 1. Introduction and Fundamental Theory
To build an energy-efficient Spiking Neural Network (SNN), the core computational unit—the Leaky Integrate-and-Fire (LIF) neuron—must be carefully designed. In this project, we are utilizing a **Gate-All-Around Ferroelectric Field-Effect Transistor (GAA-FeFET)** to emulate this biological behavior.

### 1.1 How a GAA-FeFET Works
A conventional GAA-FET consists of silicon nanosheets surrounded completely by a gate stack, offering ultimate electrostatic control over the channel. By introducing a **Ferroelectric (FE)** layer (such as Hafnium Zirconium Oxide, HZO) into the gate stack, we create a FeFET. The FE layer exhibits a spontaneous electric polarization that can be reversed by an external electric field. This polarization modulates the threshold voltage ($V_{th}$) of the underlying transistor, allowing it to act as a non-volatile memory or an integrator.

### 1.2 The LIF Neuron Analogy in FeFETs
Biological neurons possess a cell membrane with capacitance, ion channels that act as resistors, and a mechanism to fire a spike when a threshold is reached. In our GAA-FeFET:
- **Integration (Membrane Capacitance):** The gate capacitance ($C_{gg}$) acts as the membrane capacitor. Incoming voltage/current pulses from pre-synaptic neurons accumulate charge on the gate, gradually increasing the gate voltage ($V_{GS}$) and shifting the ferroelectric polarization.
- **Leakage (Membrane Resistance):** Subthreshold leakage currents or natural depolarization of the FE layer act as the "leak," causing the accumulated potential to decay over time if no input is received.
- **Fire (Action Potential):** When the integrated gate potential exceeds the threshold voltage ($V_{th}$), the transistor abruptly turns ON. In our specific design, we leverage the **Impact Ionization (Kink Effect)** at a specific drain bias ($V_{DS}$) to create an abrupt, sharp spike in drain current ($I_{D}$), representing the neuron firing.
- **Reset (Refractory Period):** After firing, an external circuit or intrinsic polarization reset brings the membrane potential back to its resting state.

---

## 2. Phase I: Baseline Replication & Foundation Setup
Before innovating, we must first replicate the baseline behavior from foundational literature (e.g., Bhatawdekar et al. for the LIF neuron platform and Loubet et al. for GAA dimensions). 

### 2.1 Key Baseline Parameters
1. **Gate Length ($L_g$):** $100$ nm. A longer channel ensures robust impact ionization and charge storage (floating body effect) compared to logic-scaled 12nm nodes.
2. **Nanosheet Thickness ($T_{si}$):** $15$ nm. Thicker sheets provide a robust vertical electric field distribution, highly beneficial for impact ionization.
3. **Gate Workfunction (WF):** Tuned to center the hysteresis loop and achieve a target baseline $V_{th}$ (e.g., $+0.25$ V) ensuring the neuron is neither always-ON nor too hard to trigger.
4. **Ferroelectric Layer ($T_{fe}$):** Carefully matched with $T_{ox}$ to form a capacitive voltage divider $C_{stack} = (C_{ox} \cdot C_{fe}) / (C_{ox} + C_{fe})$ that ensures the FE layer receives sufficient voltage ($> V_c$) during operation.

### 2.2 Algorithm & Current Status of Baseline
The baseline replication is divided into stages. Here is the explicit breakdown of what has been achieved and what is failing:

**Step A: Electrostatic Baseline (The "Vanilla" FET)**
- **Action Done:** Disabled FE models. Swept $L_g$, $T_{si}$, Doping, and Workfunction.
- **Status:** ✅ **COMPLETED** (Refer to `Calibration_Log_2026_01_15.md`, Run 16).
- **Result:** We achieved a perfect calibration with $L_g=100nm$, $T_{si}=15nm$, WF=4.35 eV, Fixed Charge=4.0e12 cm⁻², AreaFactor=0.071. Target $V_{th}$ of 0.263 V was hit with a clean OFF state.

**Step B: Ferroelectric Integration & Hysteresis**
- **Action Done:** Enabled FE physics. Ran slow transient sweeps (quasistationary equivalent) to trace the $I_D-V_{GS}$ hysteresis loop.
- **Status:** ✅ **COMPLETED**.
- **Result:** Achieved a stable, counter-clockwise Memory Window (MW) of 0.681 V. 
- **Code Context:** The output data is successfully saved in `Simulations/calibration outputs/hysteresis_id_vg.csv` and plotted using the working `plot_data.py` script.

**Step C: Firing Mechanism & Transient Stability**
- **Status:** ⚠️ **RUN 3 (Corrected Biasing): STILL FLAT — 68.3 μA, NO SPIKING**.
- **Progress:**
  - ✅ Run 1 (VGS=1.2V): Failed due to wrong operating point (too far above Vth)
  - ✅ Run 2 (VGS=0.3V, drain first): Fixed operating point but wrong biasing order
  - ✅ Run 3 (Gate first, drain pulsed): Correct biasing order but **missing negative source bias**
- **Physics models confirmed active:** UniBo2 II (d0_e=d0_h=1e6), SRH, Auger, Band2Band, Hydrodynamic — all present.
- **Root Cause 1 (BIASING SEQUENCE - FIXED):** Gate must be set FIRST, then drain pulsed (not reversed).
- **Root Cause 2 (MISSING SOURCE BIAS - FOUND):** Paper explicitly states (line 210): **"a small negative voltage is applied to the source"**. Our V_S=0V was wrong. Negative source bias reverse-biases the source-channel junction, creating the low-current initial state needed for gradual II buildup.
- **Fix Applied (Run 4):** 
  - V_S = **-0.25V** (negative bias per paper)
  - V_G = **0.05V** (to achieve V_SG ≈ -0.30V near paper's -0.244V threshold)
  - V_D pulsed 0→1.0V (10ns rise, 5μs hold)
- **Expected:** Initial current ~nA range → gradual II buildup → spike at I_th ≈ 94 nA
- **Code Context:** Output in `Simulations/spiking_runs/`, plots in `Simulations/py_scripts/`.

---

## 3. Phase II: Novel Device Engineering (The Core Innovation)
*Note: This phase will commence immediately after resolving the transient simulation blockage in Phase I.*

The goal of this phase is not merely to replicate existing FeFET designs, but to introduce **novel structural and material optimizations** that maximize the device's performance specifically as a Leaky Integrate-and-Fire (LIF) neuron. Standard GAA-FETs are optimized for logic (high $I_{on}/I_{off}$, low SS). However, a LIF neuron requires distinct characteristics: rapid impact ionization at low voltages (low-energy spiking), controlled charge retention (integration), and tunable leakage. 

### 3.1 Asymmetric Junction Engineering for Low-Voltage Firing
- **Current Approach:** Symmetric highly doped Source/Drain regions ($10^{20} \text{ cm}^{-3}$).
- **Innovative Approach:** Engineer an asymmetric drain doping profile or incorporate a lightly doped drain (LDD) extension specifically tuned to maximize the local electric field near the drain at low $V_{DS}$. 
- **TCAD Action:** Introduce a spatial doping gradient in `sdevice` structure generation. Sweep the length and concentration of this transition region.
- **Impact:** This will trigger the Kink Effect at a significantly lower drain voltage than conventional designs, translating to a massive reduction in the **Energy per Spike**.

### 3.2 Floating Body and Volume Inversion Optimization
- **Current Approach:** Standard 15nm thickness.
- **Innovative Approach:** Intentionally "de-scale" and fine-tune dimensions for neuromorphic utility. Optimize a thicker nanosheet ($T_{si} \approx 15-25$ nm) to maximize the hole-storage capacity (Floating Body Effect) within the channel.
- **TCAD Action:** Run transient multi-pulse simulations varying $T_{si}$ to observe which thickness retains the generated holes the longest before recombination.
- **Impact:** Enhances the integration phase of the LIF neuron, allowing for stable accumulation of membrane potential and a more pronounced firing spike.

### 3.3 Ferroelectric Stack Engineering for Analog Integration
- **Current Approach:** Binary polarization switching aimed at maximizing the Memory Window.
- **Innovative Approach:** Tune the Hafnium Zirconium Oxide (HZO) thickness ($T_{fe}$) and interfacial layer ($T_{ox}$) to promote multi-domain, gradual polarization switching rather than abrupt macroscopic switching.
- **TCAD Action:** Enable the multi-domain Preisach model. Sweep $T_{fe}$ and $T_{ox}$ to find the "sweet spot" where the capacitive voltage divider allows partial polarization switching for every small step in gate voltage.
- **Impact:** Converts the FeFET into a highly linear, multi-state integrator, mimicking biological membrane capacitance charging much more accurately.

---

## 4. Hyper-Specific Next Steps & Workflow

1. **Run with Negative Source Bias (Immediate Priority):**
   - **Critical fix applied:** Source bias set to -0.25V (paper line 210: "a small negative voltage is applied to the source")
   - Gate voltage adjusted to 0.05V to achieve V_SG ≈ -0.30V (near paper's -0.244V threshold)
   - **Next action:** 
     1. Upload updated `sdevice_des.cmd` to server
     2. Run: `nohup sdevice sdevice_des.cmd &`
     3. Analyze new `fire_rise_n5_des.plt` and `fire_hold_n5_des.plt`
     4. Run `plot_spiking.py` to visualize
   - **Expected behavior:** Initial ID ~nA → gradual rise over ~1μs via II → spike when ID reaches I_th ≈ 94 nA → reset
   - If spiking is observed, sweep V_G from 0.0V to 0.1V (varying V_SG from -0.25V to -0.35V) to characterize frequency vs input
   - **Note:** AreaFactor (0.071) may need adjustment after confirming spiking behavior. Current is 720× too high, suggesting device area mismatch.
2. **Execute Phase II Optimization Sweep:**
   - Once the single transient spike works, create a Python automation script to modify the `.cmd` files, run `sdevice`, and extract the peak $I_D$ and $V_{DS}$ for the Asymmetric Junction sweep (Section 3.1).
3. **Data Extraction for Step 2:**
   - After finalized optimization, extract the $I_{spike}$, $V_{th\_effective}$, and integration time constants to be passed into the Python SNN models.
