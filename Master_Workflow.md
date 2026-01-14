# 🧠 Master Workflow: GAA-FeFET LIF Neuron Calibration & SNN Implementation

**Objective**: Rigorously calibrate the GAA-FeFET TCAD model to match the reference paper ("Design of energy-efficient LIF neuron...") before bridging to Python.

**Paper Reference**: *Neurocomputing 659 (2026) 131814*
**Device Polarity**: NMOS (p-Si channel, n-As S/D).
**Control Mechanism**: Gate-Source Voltage ($V_{GS}$).

---

## 📊 Phase 1: Comprehensive Device Calibration (TCAD)
**Goal**: Match ALL key physical characteristics. Do NOT proceed to Python until these are met.

### 1.1 Geometric Scaling & Current Magnitude ($I_{on}$)
**Theory**: 2D TCAD simulates a 1 $\mu m$ deep slice. The real device is a nanosheet ($L_g=100nm, H=90nm, T=15nm$).
**Target**: $I_{on} \approx 600 - 800 \mu A$ at $V_{GS}=2.0V, V_{DS}=1.0V$ (Source: Fig 5a/b).
**Action**:
*   [ ] Set `AreaFactor` to match physical width.
    *   $W_{eff} \approx 2 \times (H_{FNS} + T_{FNS}) = 2 \times (90 + 15) = 210 nm = 0.21 \mu m$.
    *   Target `AreaFactor = 0.21`.
*   [ ] **Verification Run**: Run Node 5 and check Peak Current.

### 1.2 Threshold Voltage ($V_{th}$) Calibration
**Target**:
*   $V_{GS} = 0.0V \rightarrow I_D \approx 0$ (OFF / Subthreshold).
*   $V_{GS} = 0.5V \rightarrow I_D > 1 \mu A$ (ON).
*   $V_{th} \approx +0.25V$ (Source: Fig 7b interpreted as Enhancement Mode).
**Tuning Knobs** (In order):
1.  **Workfunction**: Lower to 3.9eV (Band-edge). [Current State]
2.  **Doping Profiles**: Check Channel Doping ($N_A$) vs Source/Drain Doping ($N_D$).
3.  **Fixed Charge**: *Only if above fail*.

### 1.3 Kink Effect (Firing Mechanism)
**Target**: Sharp increase in current (Impact Ionization) around $V_{GS} \approx 1.0V$ (Fig 5b).
**Tuning Knobs**:
*   `Avalanche (UniBo2)` Parameters: `d0_e`, `d0_h`.
*   Paper values: $d0 \in [1e5, 9e6]$. Target firing current $I_{th} \approx 94 nA$.

### 1.4 Leakage & Subthreshold ($I_{off}$)
**Target**: $I_{off} < 1 \mu A$ (Low leakage for integration).
**Tuning Knobs**:
*   `Band2Band (Hurkx)`: Controls GIDL / Leakage at low Vg.

---

## 🐍 Phase 2: Python Bridge (Data Generation)
*Only proceed after Phase 1 is marked COMPLETE.*

1.  **Generate Lookup Table**: $t_{spike}$ vs $V_{input}$.
2.  **Extract Leakage Time Constant**: $\tau_{leak}$.
3.  **Export `device_data.csv`**.

---

## 📝 Current To-Do List
1.  **Set AreaFactor = 0.21** (Geometric Correction).
2.  **RE-RUN Node 5** (Workfunction=3.9eV, Clean).
3.  **Compare Results**:
    *   Is $I_{peak} \approx 600 \mu A$?
    *   Is $V_{th} \approx 0.25V$?
    *   Is there a Kink?

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

