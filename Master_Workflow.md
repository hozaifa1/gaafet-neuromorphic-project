# 🧪 Hyperspecific Calibration Protocol: GAA-FeFET LIF Neuron

**Objective**: Calibrate TCAD model to match *Neurocomputing 659 (2026)* data strictly.
**Device State**: NMOS ($N_A=1e16$, $N_D=1e20$), $L_g=100nm$.
**Target Behavior**: Enhancement Mode ($V_{th} \approx +0.25V$), Kink @ ~1.0V.

---

## 🛠️ Phase 1: Physical Baseline (The "Clean" Run)
**Goal**: Establish the device's true behavior with physical dimensions and band-edge workfunction.

### Step 1.1: Configure Simulation
*   **Action**: Edit `Simulations/sdevice_des.cmd`
*   **Parameters**:
    *   `Workfunction = 3.9` (eV) [Band-edge limit for N-type]
    *   `Areafactor = 0.21` [Physical: $W_{eff} \approx 2(90+15)nm = 0.21\mu m$]
    *   `Charge` = **None** (Comment out any fixed charge)
    *   `Avalanche` = `UniBo2` (Enabled)

### Step 1.2: Run Baseline Simulation
*   **Command**: Run Node 5 in Sentaurus Workbench.
*   **Voltage Context**: $V_{DS} = 1.0V$.

### Step 1.3: Extract Metrics
*   **Command**: `python Simulations/analyze_metrics.py`
*   **Data to Record**:
    | Metric | Simulation Value | Target Value | Deviation |
    | :--- | :--- | :--- | :--- |
    | **$V_{th}$** | `_______` V | **+0.25 V** | `_______` |
    | **$I_{off}$ (0V)** | `_______` A | **< 1e-7 A** | `_______` |
    | **$I_{on}$ (0.5V)** | `_______` A | **> 1e-6 A** | `_______` |
    | **$I_{peak}$ (2.0V)**| `_______` A | **~600 uA** | `_______` |

---

## 🔧 Phase 2: Iterative Calibration Logic
**Execute these steps in order. Do not skip.**

### Decision Block A: Threshold Voltage ($V_{th}$)
*   **Condition**: If Sim $V_{th}$ > Target (+0.25V):
    *   *Diagnosis*: Device turns on too late. Need negative shift.
    *   *Action*: Add **Fixed Positive Oxide Charge** (Interface States).
    *   *Calculation*: $\Delta V = V_{th,sim} - 0.25$.
    *   *Charge*: $Q = C_{ox} \times \Delta V \approx 1.7 \times 10^{-6} \times \Delta V$.
    *   *Value*: $N_{int} = Q / 1.6e-19$.
    *   *Edit*: Add `Physics(MaterialInterface="Silicon/SiO2") { Charge(Pos=...) }`.
*   **Condition**: If Sim $V_{th}$ < Target (+0.25V):
    *   *Diagnosis*: Device is Depletion Mode (Always ON).
    *   *Action*: Increase Workfunction (e.g., 4.1eV, 4.3eV).

### Decision Block B: On-Current Magnitude ($I_{on}$)
*   **Condition**: If $I_{peak}$ (2.0V) < 400 uA (and $V_{th}$ is correct):
    *   *Diagnosis*: Mobility or Area scaling is underestimated.
    *   *Action*: Increase `AreaFactor`.
    *   *Formula*: $AF_{new} = AF_{old} \times (Target / Sim)$.
*   **Condition**: If $I_{peak}$ (2.0V) > 800 uA:
    *   *Action*: Decrease `AreaFactor`.

### Decision Block C: Kink Effect (Firing)
*   **Condition**: No sharp current jump around $V_{GS} = 1.0V$.
    *   *Diagnosis*: Impact Ionization too weak.
    *   *Action*: Increase `UniBo2` coefficients.
    *   *Edit*: `sdevice_gaafet_lif.par` -> `UniBo2 { d0_e = [Higher], d0_h = [Higher] }`.
    *   *Range*: Try $1e6 \to 5e6 \to 1e7$.

---

## 🐍 Phase 3: Python Bridge (Data Generation)
**Goal**: Generate the Lookup Table for the SNN.
*Prerequisite*: Phase 2 Complete (All Metrics within 10% of Target).

### Step 3.1: Transient Pulse Setup
*   **Action**: Edit `sdevice_des.cmd`.
*   **Change**: Replace Gate `Quasistationary` with `Transient` Pulse.
    *   `Voltage = 0.0` at $t=0$.
    *   `Voltage = 1.0` at $t=10ps$ (Step).

### Step 3.2: Latency Extraction Sweep
*   **Command**: Run Simulation for $V_{input} = [0.8V, 1.0V, 1.2V]$.
*   **Analysis**: Measure time from Step to Current Spike ($I > I_{th}$).

### Step 3.3: Export
*   **Action**: Save `device_data.csv`.

---

## 📝 Execution Log
*   [x] **Run 1**: Baseline (3.9eV, AF=0.21). Result: $V_{th} \approx -0.2V$ (Too Negative), Loop Direction Correct (CCW).
*   [x] **Run 2**: Vth Correction (FixedCharge=3.5e12). Result: $V_{th} = 0.30V$ (High), $I_{peak} = 587\mu A$.
*   [x] **Run 3**: Fine-Tuning (FixedCharge=4.0e12, AF=0.071). Result: $V_{th} = 0.263V$, $I_{peak} = 604\mu A$, $MW = 0.68V$. **Golden Calibration.**

---

## 🔍 Design Verification (Sanity Check)
*   **Reference Paper**: *Design of energy-efficient LIF neuron using CMOS compatible...* (Bhatawdekar et al.)
*   **Fabrication Base**: *Stacked Nanosheet Device Design...* (Loubet et al.)
*   **Decision**: We strictly follow the **LIF Paper (Table 1)** dimensions:
    *   $L_g = 100 \text{ nm}$ (Crucial for Impact Ionization/Floating Body).
    *   $T_{si} = 15 \text{ nm}$.
    *   *Note*: The Fabrication Paper targets 12nm Logic; we are building a 100nm Neuron. **Workflow is Correct.**
