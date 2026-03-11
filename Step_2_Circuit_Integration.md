# Paper 2: System-Level Evaluation of the Optimized GAA-FeFET LIF Neuron

## 1. Introduction and Circuit Theory
Once the highly optimized, novel GAA-FeFET structure is finalized in Phase 1 (Paper 1), this second phase focuses on extracting its behavior and evaluating it within a full-scale Spiking Neural Network (SNN). 

### 1.1 The Role of the Neuron in an SNN
In an SNN, information is transmitted via discrete voltage spikes rather than continuous analog values. 
- **Synapses (Weights):** Convert incoming spikes from previous layers into a continuous input current.
- **Neurons (LIF):** Accumulate these input currents over time (Integrate). If the accumulated potential exceeds a threshold, the neuron fires an output spike and resets.

### 1.2 How the FeFET Circuit Works
Unlike traditional CMOS LIF neurons that require dozens of transistors and bulky external capacitors, the FeFET-based LIF neuron is highly compact:
1. **Input Stage:** Presynaptic spikes are converted into an input current ($I_{in}$) that flows into the gate terminal of the FeFET.
2. **Integration Stage:** The intrinsic gate capacitance ($C_{mem} = C_{gg}$) of the FeFET integrates this current, causing the gate-to-source voltage ($V_{GS}$, the "membrane potential") to rise.
3. **Firing Stage:** When $V_{GS}$ reaches the FeFET's threshold voltage ($V_{th}$), combined with a constant drain bias ($V_{DS}$), the channel inverts. Due to the optimized Impact Ionization (Kink effect) developed in Phase 1, a massive, sudden drain current ($I_{D}$) is generated at a very low $V_{DS}$.
4. **Output and Reset Stage:** This sharp $I_{D}$ is detected by a simple output circuit (e.g., a comparator or a pull-down network), which registers the "spike." Simultaneously, a feedback loop applies a reset voltage (e.g., pulling the gate to ground) to deplete the channel and reset the polarization, preparing the neuron for the next cycle.

---

## 2. From TCAD to System: The Integration Pipeline

### 2.1 Mapping Device Parameters to Circuit Parameters
To accurately simulate the SNN using a Python framework (like PyTorch or the custom LSNN codebase), we must extract the optimized TCAD parameters and map them to their circuit equivalents.

| TCAD Device Parameter | Python Circuit Parameter | Description & Function in Circuit |
| :--- | :--- | :--- |
| **Total Gate Capacitance ($C_{gg}$)** | Membrane Capacitance ($C_{mem}$) | Determines how much input current is required to raise the membrane potential. A larger $C_{mem}$ means slower integration. |
| **Forward Threshold Voltage ($V_{th}$)** | Firing Threshold ($v_{th}$) | The voltage at which the neuron evaluates the decision to spike. |
| **Reset/Holding Voltage** | Reset Voltage ($v_{reset}$ / $v_{h}$) | The baseline voltage the neuron returns to after a spike occurs. |
| **OFF-State Resistance ($R_{off}$)** | Leaky Resistance ($R_{mem}$) | Controls the "Leak." Determines how fast the membrane potential decays. |
| **ON-State Resistance ($R_{on}$)** | Series Resistance ($R_{h}$) | Governs the maximum current flow during the firing phase. |
| **Polarization Relaxation Time** | Adaptation Time Constant ($\tau_a$) | For Adaptive LIF (ALIF) neurons, the time it takes for the FE layer's partial polarization to relax back. |

### 2.2 Compact Model Extraction (Bridging the Gap)
Instead of relying on idealized mathematical LIF equations, we will extract a physics-informed compact model directly from our Sentaurus TCAD simulations.
- **Parameters to Extract:**
  - $V_{th\_effective}$ (modulating with polarization state).
  - $I_{spike}$ (peak current from the engineered impact ionization).
  - Membrane Capacitance ($C_{mem}$) derived from the optimized $C_{ox}$ and $C_{fe}$ stack.
  - Leakage Time Constant ($\tau_{leak}$) derived from the optimized floating-body recombination rates.
  - Energy per Spike (calculated from $\int V_{DS} \cdot I_D \, dt$ during the firing transient).

### 2.3 Python SNN Implementation (PyTorch / snnTorch)
We will modify standard SNN neuron models to incorporate the extracted hardware constraints.
- **Custom Neuron Class:** Build a Python class that closely mimics the non-linear integration and abrupt firing characteristics of our specific GAA-FeFET.
- **Multi-Domain Behavior:** Implement the gradual threshold shift observed in our Phase 1 multi-domain ferroelectric optimization, modeling it as a state-dependent capacitance or adaptive threshold.

---

## 3. System-Level Benchmarking (The Value Proposition)

### 3.1 Task: ECG Arrhythmia Classification
- **Dataset:** MIT-BIH Arrhythmia Database.
- **Encoding:** Convert physiological time-series data into asynchronous spike trains using delta-modulation or rate coding.

### 3.2 Key Performance Indicators (KPIs)
To prove the value of the Phase 1 innovations, we will benchmark our SNN against standard hardware implementations (e.g., CMOS-only LIF, standard FinFET LIF).
1. **System Energy Efficiency:** Multiply the network's total spike count for a classification inference by the TCAD-derived Energy per Spike. Our asymmetric junction optimization should dramatically lower this.
2. **Classification Accuracy:** Evaluate if the multi-domain, non-linear integration of our optimized FeFET improves the network's ability to recognize complex temporal patterns in ECGs compared to a rigid, standard mathematical LIF.
3. **Latency:** Determine how fast the network can confidently classify an ECG beat, leveraging the newly engineered high-frequency spiking capability of the device.

---

## 4. Algorithm for Circuit Integration (Hyper-Specific Workflow)

### Phase A: Parameter Extraction (from TCAD)
1. **Capacitance Extraction ($C_{mem}$):**
   - Run a Small-Signal AC simulation in TCAD. Sweep $V_{GS}$ from 0 to 2V at a high frequency (e.g., 1 MHz). Extract the $C_{gg}$ curve and record the average value in the subthreshold region.
2. **Resistance Extraction ($R_{on}$, $R_{off}$):**
   - Run a standard DC $I_{D}-V_{GS}$ sweep. Calculate $R_{off} = V_{DS} / I_{D}$ at $V_{GS} = 0\text{V}$, and $R_{on}$ at $V_{GS} = 2.0\text{V}$.
3. **Threshold and Reset Extraction ($v_{th}$, $v_{reset}$):**
   - Run a Transient Hysteresis loop. Extract the point where $I_{D}$ suddenly spikes (Forward $V_{th}$) and drops (Reverse $V_{th}$).
4. **Transient Pulse Extraction:**
   - Apply transient voltage pulses (e.g., 10$\mu$s) to observe multi-state resistance transitions for the multi-domain behavior.

### Phase B: Python Model Update & Single Neuron Verification
1. **Locate Target Scripts:** Open the existing SNN scripts (e.g., `main_ecg.py`, `model.py`, `vo2_encoder.py`).
2. **Update Hardcoded Values:** Replace the legacy VO2 memristor parameters with the newly extracted FeFET parameters.
   - Example: Change `Vth = 3.4 V` to `v_threshold = 0.25 V` (or the optimized TCAD value).
   - Example: Update the membrane time constant equation to use the new $C_{mem}$ and $R_{off}$.
3. **Adjust Input Scaling:** Scale down input weights/currents to match the new, highly efficient $v_{th}$.
4. **Pulse Testing:** Before running the full ECG dataset, write a simple Python script to inject a series of constant current pulses into a single isolated FeFET LIF model. Verify gradual charging (Integration), slight decay (Leak), and immediate reset upon crossing $v_{th}$ (Fire).

### Phase C: Full Network Deployment & System Evaluation
1. **Network Integration:** Deploy the custom FeFET LIF model across the entire hidden layer (e.g., 60 LIF + 40 ALIF neurons).
2. **Training:** Train the network using Surrogate Gradient Descent (since spikes are non-differentiable). Apply regularization to keep the network within hardware thermal/power constraints.
3. **Publication Result:** Run the trained model on the unseen test set. Calculate total system power, area, and accuracy to comprehensively demonstrate that bottom-up device engineering (Paper 1) yields a globally optimal neuromorphic system (Paper 2).
