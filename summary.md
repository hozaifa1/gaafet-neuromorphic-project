# 🚀 GAA-FeFET Neuromorphic LIF Neuron: Master Workflow & Status

**Project Scope:** Full device-to-system implementation of a GAA-FeFET-based Leaky Integrate-and-Fire (LIF) neuron for ECG Arrhythmia Classification (MIT-BIH database).
**Current Status:** DC/Hysteresis Calibration Complete. **Stuck at Transient Spike Simulation.**

---

## 1️⃣ Phase 1: Transistor Architecture & Baseline Calibration (COMPLETED)

The foundational device physics have been successfully tuned across 16 rigorous TCAD runs to match the target envelope ($L_g=100nm$, $V_{th} \approx 0.25V$, $I_{on} \approx 600\mu A$) required for the neuromorphic SNN.

**Golden Calibration Parameters (Run 16 Locked Values):**
| Parameter | Calibrated Value | Justification / Physical Meaning |
| :--- | :--- | :--- |
| **Workfunction (WF)** | `4.35 eV` | Required to positively shift and center the Ferroelectric Hysteresis loop. |
| **Fixed Oxide Charge** | `4.0e12 cm⁻²` | Fine-tunes the Forward $V_{th}$ to the strict 0.25V threshold. |
| **AreaFactor (AF)** | `0.071` | Recalibrated for the Transient solver to scale $I_{on}$ precisely to ~600 $\mu A$. |
| **Dimensions** | $L_g=100nm$, $T_{si}=15nm$| Matches the target LIF CMOS-compatible design criteria. |

**Achieved Metrics:**

* $V_{th} (Forward)$: **0.263 V** ✅ (Target: 0.25V)
* $I_{peak}$: **604 $\mu A$** ✅ (Target: 600 $\mu A$)
* Memory Window ($MW$): **0.68 V** ✅ (Counter-Clockwise Loop Confirmed)

---

## 2️⃣ Phase 2: SNN Parameter Extraction (IN PROGRESS)

To bridge the Sentaurus TCAD physics into the PyTorch/Python LSNN decision network, 8 specific parameters must be extracted to replace the original VO₂ memristor logic.

### ✅ Extracted / Known Parameters

1. **Positive Threshold ($V_{th\_pos}$):** `~0.263 V` (From Run 16 Forward Sweep).
2. **On-Resistance ($R_{on}$):** Extractable from Run 16 DC sweep at $V_g = V_{dd}$ (linear region).
3. **Off-Resistance ($R_{off}$):** Extractable from Run 16 DC sweep at $V_g = 0V$.

### ⏳ Pending Extraction (Blocked by Transient Simulation)

4. **Negative Threshold ($V_{th\_neg}$):** Needs to be locked from the backward hysteresis sweep.
5. **Gate Capacitance ($C_{mem}$):** Requires an AC C-V simulation (Frequency = 1e6) to extract $C_{gg}$ at the operating point.
6. **Holding/Reset Voltage ($v_h$ / $V_{reset}$):** Requires a successful Transient pulse to observe the voltage drop after polarization switching.
7. **Spike Scaling ($input\_scaling$ / $R_s$):** Requires transient current data to match the targeted biological spike rate.
8. **Adaptation Params ($R_a$, $C_a$):** Requires a long pulse train (100 spikes) to measure polarization relaxation and depolarization time constants for the ALIF neurons.

---

## 3️⃣ Phase 3: Current Roadblock — The Transient Spike (STUCK)

The workflow is currently halted at the **Transient Pulse Setup** (Step 3.1) required to generate the latency extraction lookup tables and extract the dynamic parameters (6, 7, and 8 above).

**The Core Issue:**
Injecting a rapid 50ps voltage spike ($0.0 \to 1.0V$) into the GAA-FeFET causes a "physics shock" in the Sentaurus solver.

* **Symptoms:** The solver hits an infinite loop at $t \approx 1\times10^{-15}s$. The Local Truncation Error (LTE) checker panics at the rapid ramp, forcing the time step ($\Delta t$) to collapse to $\approx 1\times10^{-22}s$. This caused `.plt` files to explode in size and `.log` files to run indefinitely without simulation progress.

**The Implemented Fix (Pending Validation):**
You have deployed the **"Nuclear Option"** in `sdevice_des.cmd` by completely disabling LTE for all complex variables, forcing the system to rely strictly on Newton convergence.

```sentaurus
Math {
   * NUCLEAR OPTION: Disable LTE completely.
   ErrRef(Poisson)= 1e30
   ErrRef(Electron)= 1e30
   ErrRef(Hole)= 1e30
   ErrRef(FEPolarization)= 1e30
   ErrRef(eQuantumPotential)= 1e30
   ErrRef(hQuantumPotential)= 1e30
   ...
}

```

*Current Status:* Testing this fix is currently blocked by a **Sentaurus License Error**.

---

## 4️⃣ Phase 4: Next Steps & Python Integration

Once the license server is restored, the immediate execution protocol is:

1. **Clear the Cache:** Delete all bloated `.log` and `.out` files from the `spiking_runs` directory to prevent storage-based crashes.
2. **Validate the Transient Spike:** Run node 5 with the "Nuclear" Math block. If it clears the 50ps ramp, immediately extract the time-to-spike ($I > I_{th}$) for the lookup table.
3. **Run the AC Simulation:** Create and run the C-V deck to extract $C_{mem}$.
4. **Update the Python LSNN:**
* Open `vo2_encoder.py`: Inject $V_{th\_pos}$, $V_{th\_neg}$, $R_{on}$, and $R_{off}$. Update the $\delta$ formula.
* Open `model.py`: Update `v_threshold`, `v_reset`, and $C_{mem}$ to reflect the GAA-FeFET dynamics.
* Open `main_ecg.py`: Update the `FLAGS` dictionary with the final hardware metrics.



---