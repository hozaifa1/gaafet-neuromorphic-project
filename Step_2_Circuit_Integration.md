# Paper 2: System-Level Evaluation of the Optimized GAA-FeFET LIF Neuron

## 1. Introduction and Circuit Theory

### 1.1 The Role of the Neuron in an SNN
In an SNN, information is transmitted via discrete voltage spikes rather than continuous analog values.
- **Synapses (Weights):** Convert incoming spikes into input voltage pulses applied to the neuron gate.
- **Neurons (LIF):** Accumulate these input pulses over time (Integrate). If the accumulated state exceeds a threshold, the neuron fires an output spike and resets.

### 1.2 How the FeFET Polarization-Based LIF Circuit Works
Unlike traditional CMOS LIF neurons that require dozens of transistors and bulky external capacitors, the FeFET-based LIF neuron is compact because the **ferroelectric polarization replaces the membrane capacitor**:

1. **Input Stage:** Presynaptic spikes are converted into sub-coercive voltage pulses applied to the FeFET gate.
2. **Integration Stage:** Each gate pulse partially switches FE domains in the HZO layer, progressively shifting $V_{th}$ lower. The accumulated polarization state IS the membrane potential — no external capacitor needed.
3. **Leak Stage:** Between pulses, partial domain relaxation (governed by $\tau_P$ and domain-domain interactions) causes $V_{th}$ to drift back up, emulating membrane leakage.
4. **Firing Stage:** When enough domains have switched that $V_{th}$ drops below the operating $V_{GS}$ (at constant $V_{DS}$), the channel abruptly turns ON → $I_D$ spikes. This is detected by the output circuit.
5. **Reset Stage:** A negative gate pulse resets polarization → $V_{th}$ returns to its initial high state. For the AFE variant ($Hf_{0.2}Zr_{0.8}O_2$), reset is spontaneous (volatile polarization).

### 1.3 Key Differences from Previous (II-Based) Approach

| Aspect | Old (Impact Ionization) | New (Polarization Switching) |
|---|---|---|
| Spiking mechanism | Avalanche at drain junction | FE domain switching at gate |
| Membrane potential | Floating body charge | FE polarization state |
| Input terminal | Drain (pulsed) | Gate (pulsed) |
| Read terminal | Drain current | Drain current (constant $V_{DS}$) |
| External capacitor | Not needed (floating body) | Not needed (FE layer) |
| Reset | Hole recombination | Negative gate pulse or AFE self-reset |
| Energy per spike | ~4.88 fJ (paper) | 37 fJ (AFeFET) / 0.58 aJ (FeTFET) |
| Literature support | 1 paper (Bhatawdekar) | Multiple (Frontiers, Nature Comms, Khanday) |

---

## 2. From TCAD to System: The Integration Pipeline

### 2.1 Mapping Device Parameters to Circuit Parameters

| TCAD Device Parameter | Python Circuit Parameter | Description |
|---|---|---|
| **Polarization state ($P$)** | Membrane potential ($u$) | The internal state that accumulates with input pulses |
| **Forward $V_{th}$ (at current $P$)** | Firing threshold ($v_{th}$) | Voltage at which neuron fires; shifts with $P$ |
| **$V_{th}$ at virgin $P$ state** | Resting potential ($v_{rest}$) | Baseline after reset |
| **$\tau_P$ (depolarization time)** | Leak time constant ($\tau_{leak}$) | Controls how fast membrane decays |
| **$\tau_E$ (switching speed)** | Integration time constant ($\tau_{int}$) | Controls how fast membrane charges |
| **$\Delta V_{th}$ per pulse** | Synaptic weight resolution | Minimum distinguishable input |
| **Number of pulses to fire** | Integration depth | Determines firing rate sensitivity |
| **Energy per spike** | $E_{spike}$ | $\int V_{DS} \cdot I_D \, dt$ during firing transient |
| **$I_D$ ON/OFF ratio** | Spike amplitude | Signal-to-noise of output spike |

### 2.2 Compact Model Extraction
Extract a physics-informed compact model from TCAD Phase 1A/1B results:

- **$V_{th}(N_{pulses})$ curve:** Maps number of input pulses to threshold voltage shift → defines integration dynamics
- **$V_{th}(t_{wait})$ curve:** Maps wait time to threshold recovery → defines leak dynamics
- **$I_D$ vs $V_{th}$ transfer:** Steep SS (60.8 mV/dec confirmed) → sharp firing transition
- **Reset characteristics:** Negative pulse amplitude/width required for full $V_{th}$ recovery
- **Energy per spike:** From transient $I_D$ waveform during firing event
- **Stochasticity:** Cycle-to-cycle variation in pulse count to fire (from domain nucleation randomness)

### 2.3 Python SNN Implementation (PyTorch / snnTorch)

**Custom FeFET Neuron Class:**
```python
class FeFET_LIF(nn.Module):
    def __init__(self, Vth_virgin, dVth_per_pulse, tau_leak, tau_int, Vth_fire):
        # Vth_virgin: initial threshold (from TCAD calibration)
        # dVth_per_pulse: threshold shift per input pulse (from Phase 1A Sweep 2)
        # tau_leak: depolarization time constant (from Phase 1A Sweep 3)
        # tau_int: integration speed (from tau_E)
        # Vth_fire: threshold at which ID spikes (from Phase 1A Sweep 4)
    
    def forward(self, input_spikes, dt):
        # Integration: each input spike shifts Vth by dVth_per_pulse
        # Leak: Vth drifts back toward Vth_virgin with time constant tau_leak
        # Fire: when Vth < Vth_fire, emit spike and reset
```

**Key model features:**
- Non-linear integration (domain switching is inherently non-linear, especially near saturation)
- State-dependent leak (relaxation rate depends on how many domains have switched — per Frontiers 2020)
- Stochastic firing (optional — domain nucleation randomness)
- Adaptive threshold (optional — partial reset leaves residual polarization)

---

## 3. System-Level Benchmarking

### 3.1 Task: ECG Arrhythmia Classification
- **Dataset:** MIT-BIH Arrhythmia Database
- **Encoding:** Delta-modulation or rate coding from physiological time-series to spike trains

### 3.2 Key Performance Indicators (KPIs)

| KPI | Metric | How Measured |
|---|---|---|
| **Energy efficiency** | Total spikes × $E_{spike}$ per inference | From TCAD energy extraction |
| **Classification accuracy** | % correct on MIT-BIH test set | Standard ML evaluation |
| **Latency** | Time to classify one ECG beat | From network simulation |
| **Area** | Transistor count per neuron | 1 FeFET vs. ~20 CMOS transistors |
| **Endurance** | Cycles before degradation | From FE cycling data (>10¹² for AFE) |

### 3.3 Benchmarking Targets

| Baseline | Our FeFET LIF | Source |
|---|---|---|
| CMOS LIF (20+ transistors) | 1 FeFET + 3 transistors (Frontiers) | Area reduction |
| VO2 memristor neuron | FeFET neuron | CMOS compatibility |
| Standard math LIF | Hardware-constrained LIF | Accuracy comparison |
| Capacitor-based LIF | Capacitor-free FeFET LIF | Integration density |

---

## 4. Algorithm for Circuit Integration (Workflow)

### Phase A: Parameter Extraction (from TCAD Phase 1A/1B)

1. **Integration curve:** From Phase 1A Sweep 2 → $V_{th}$ vs $N_{pulses}$ → fit to $\Delta V_{th}(N) = A \cdot (1 - e^{-N/\lambda})$ or piecewise linear
2. **Leak curve:** From Phase 1A Sweep 3 → $V_{th}$ vs $t_{wait}$ → fit exponential decay → extract $\tau_{leak}$
3. **Fire threshold:** From Phase 1A Sweep 4 → critical $N_{pulses}$ at which $I_D$ jumps
4. **Capacitance ($C_{gg}$):** AC simulation at 1 MHz, sweep $V_{GS}$ 0–2V → average subthreshold $C_{gg}$
5. **ON/OFF resistance:** From DC $I_D$-$V_{GS}$ → $R_{off} = V_{DS}/I_D$ at $V_{GS}=0V$, $R_{on}$ at $V_{GS}=2V$
6. **Energy per spike:** From transient firing waveform → $E = \int V_{DS} \cdot I_D \, dt$

### Phase B: Python Model Update & Single Neuron Verification

1. Build `FeFET_LIF` class with TCAD-extracted parameters
2. Single neuron pulse test: inject constant-rate input spikes → verify:
   - Gradual $V_{th}$ decrease (Integration)
   - Partial $V_{th}$ recovery during gaps (Leak)
   - Abrupt $I_D$ spike at threshold (Fire)
   - Full $V_{th}$ recovery after reset (Reset)
3. Sweep input spike rate → verify firing rate increases with input rate
4. Compare against ideal mathematical LIF to quantify hardware effects

### Phase C: Full Network Deployment & System Evaluation

1. Deploy FeFET LIF across hidden layer (e.g., 60 LIF + 40 ALIF neurons)
2. Train with Surrogate Gradient Descent (spikes are non-differentiable)
3. Apply hardware-aware regularization (energy budget, endurance limits)
4. Evaluate on MIT-BIH test set → report accuracy, energy, latency
5. Compare against CMOS-only and VO2-based SNN baselines
