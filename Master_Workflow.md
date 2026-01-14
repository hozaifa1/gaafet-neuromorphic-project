# 🧠 Master Workflow: GAA-FeFET LIF Neuron & SNN Implementation

**Objective**: Calibrate a TCAD GAA-FeFET to match the "Design of energy-efficient LIF neuron" paper ($V_{th} \approx -0.244V$, $V_{DS}=1.0V$) and implement it in a Python SNN for ECG classification.

---

## 📊 Phase 1: Device Calibration (TCAD)
**Goal**: Match physical device characteristics to the reference paper.

### 1.1 Threshold Voltage ($V_{th}$) Calibration [CURRENT STEP]
**Target**: $V_{th} \approx +0.25V$ (Enhancement Mode).
**Constraint**: $I_{OFF}$ at 0V (Low), $I_{ON}$ at 0.5V (High).
**Current Status**: Workfunction 3.9eV gives $V_{th} \approx 0.65V$. (Too high, turns on late).
*   [x] **Fix VDS Bug**: Implemented "Grounded Drain Write" (Resolved).
*   [x] **Calibration Pass 1**: Workfunction 4.15eV $\rightarrow$ $V_{th} \approx 0.6V$.
*   [x] **Calibration Pass 2**: Workfunction 3.9eV $\rightarrow$ $V_{th} \approx 0.65V$.
*   [ ] **Final Calibration**: Add **Fixed Oxide Charge** ($Q_f$).
    *   *Correction*: Target is Enhancement Mode ($V_{th} > 0$), not Depletion.
    *   *Action*: Add `Charge(Pos = 4.2e12)` to shift $V_{th}$ by -0.4V.
    *   *Action*: Adjust `AreaFactor` to 0.85 to match current magnitude.
    *   *Success Criteria*: High current at $V_{GS} = 0.5V$, near zero at $V_{GS} = 0V$.

### 1.2 Time-Domain Verification (Pulse Simulation)
**Goal**: Verify "Integrate and Fire" behavior (LIF).
**Target**: Delayed spiking under constant voltage pulse.
*   [ ] **Setup Pulse Input**:
    *   Modify `sdevice_des.cmd`: Change Gate source from Ramp to `Pulse` (e.g., 0V $\rightarrow$ 1.0V).
*   [ ] **Run Transient Simulation**:
    *   *Check*: Does current stay low (Integration) then spike (Firing)?
    *   *Tuning*: If response is instant (no delay), increase `AreaFactor` (Floating Body volume) or adjust `Avalanche` coefficients ($d0$).

---

## 🐍 Phase 2: The "Bridge" to Python
**Goal**: Extract the behavioral lookup table for the SNN.

### 2.1 The "Step 3" Sweep
**Procedure**: Run the **Pulse Simulation** at 3 distinct Gate Voltages.
*   [ ] **Run 1**: $V_{GS} = 0.8V$ $\rightarrow$ Measure Latency ($t_{spike}$).
*   [ ] **Run 2**: $V_{GS} = 1.0V$ $\rightarrow$ Measure Latency ($t_{spike}$).
*   [ ] **Run 3**: $V_{GS} = 1.2V$ $\rightarrow$ Measure Latency ($t_{spike}$).

### 2.2 Generate Data Artifact
*   [ ] Create `device_data.csv`:
    ```csv
    Voltage_V, Latency_ns, Peak_Current_uA
    0.8, [Value], [Value]
    1.0, [Value], [Value]
    1.2, [Value], [Value]
    ```
*   [ ] Extract **Leakage Decay** ($\tau_{leak}$): Measure current drop rate when gate is turned off.

---

## 🤖 Phase 3: Python SNN Implementation
**Goal**: Build and train the ECG Classifier.

### 3.1 Custom Neuron Model (PyTorch)
*   [ ] Create `GAALIFNeuron` class inheriting from `torch.nn.Module`.
*   [ ] Implement `forward()` method using the **Latency Lookup Table** from Phase 2.
    *   *Logic*: `if input_voltage > v_th: time_to_spike = lookup(input_voltage)`

### 3.2 System Integration
*   [ ] **Data Pipeline**: Pre-process MIT-BIH ECG database (Spike Encoder).
*   [ ] **Network Architecture**: 1FeFET-1T1C Relaxation Oscillator Logic.
*   [ ] **Training**: Train for Arrhythmia Classification.
*   [ ] **Validation**: Compare accuracy/energy against "report.md" targets.

---

## 📝 Reference Parameters (From Paper)
| Parameter | Value | Source |
| :--- | :--- | :--- |
| **Gate Length ($L_g$)** | 100 nm | Paper |
| **Drain Voltage ($V_{DS}$)** | 1.0 V | Paper (Energy Efficient) |
| **Threshold ($V_{th}$)** | -0.244 V | Paper (Fig 7b) |
| **Firing Current ($I_{th}$)** | 94 nA | Paper |
| **Energy/Spike** | 4.88 fJ | Paper |
| **Frequency** | ~19.3 MHz | Paper |

