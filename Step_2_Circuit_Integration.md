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

**Custom FeFET Neuron Class (with TCAD-extracted parameters):**
```python
class FeFET_LIF(nn.Module):
    def __init__(self):
        # --- VALIDATED parameters (from simA/simB/simC) ---
        self.Vth_virgin = 0.263      # V - from calibration (Run 16) ✅
        self.dVth_per_pulse = 11.36e-3  # V - from simB integration ✅
        self.tau_int = 1e-6          # s - from τ_E = 1µs ✅
        self.Vreset = -4.0           # V - from simC optimal reset ✅
        self.SS = 60.8e-3            # V/dec - from Run 6+7b ✅
        
        # --- PENDING parameters (need redesigned simC) ---
        self.VGS_read = 0.20         # V - proposed read bias (just below Vth_virgin)
        self.tau_leak = 1e-6         # s - PLACEHOLDER (need τ_P > 0 runs)
        self.E_spike = None          # J - PENDING (need actual fire transient)
        self.R_on = None             # Ω - PENDING (need read-bias fire measurement)
        self.R_off = None            # Ω - PENDING (need read-bias measurement)
        
        # Derived: fire occurs when Vth drops below VGS_read
        self.Vth_fire = self.VGS_read  # Fire threshold = read bias voltage
        
        # Internal state
        self.Vth_current = self.Vth_virgin
        self.membrane_potential = 0.0
    
    def forward(self, input_spikes, dt=1e-6):
        # Integration: each input spike shifts Vth by dVth_per_pulse
        for spike in input_spikes:
            if spike > 0:  # Input spike detected
                self.Vth_current -= self.dVth_per_pulse
                self.membrane_potential += spike * self.dVth_per_pulse
        
        # Leak: Vth drifts back toward Vth_virgin with time constant tau_leak
        # NOTE: tau_leak is PLACEHOLDER — real value needs τ_P > 0 TCAD runs
        leak_factor = np.exp(-dt / self.tau_leak)
        self.Vth_current = self.Vth_virgin + (self.Vth_current - self.Vth_virgin) * leak_factor
        
        # Fire: when Vth drops below VGS_read, channel goes from subthreshold
        # to above-threshold → ID jumps by orders of magnitude (SS=60.8 mV/dec)
        fire = (self.Vth_current < self.Vth_fire).float()
        
        if fire > 0:
            # Reset: negative gate pulse restores Vth (100% completeness at -4V)
            self.Vth_current = self.Vth_virgin
            self.membrane_potential = 0.0
        
        return fire, self.membrane_potential
```

**Key model features (TCAD-validated):**
- **Non-linear integration:** Sub-linear scaling (N^0.85) from simB saturation effects ✅
- **State-dependent leak:** τ_P dependent (PLACEHOLDER — needs characterization)
- **Stochastic firing:** Optional - domain nucleation randomness observed in simB
- **Hardware constraints:** Energy per spike and ON/OFF ratio PENDING (need redesigned simC with write-then-read)

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

### Phase A: Parameter Extraction (from TCAD Phase 1A/1B/1C)

**Status: PARTIALLY COMPLETE** — simA and simB validated; simC fire detection was invalid (corrected March 2026)

1. **Integration curve:** From simB → $V_{th}$ vs $N_{pulses}$ → **227.3 mV total shift over 20 pulses** ✅
   - Integration weight: **11.36 mV/pulse** (average)
   - Integration efficiency: **68.9%** (vs ideal linear)
   - Equation: $\Delta V_{th}(N) \approx 11.36 \cdot N^{0.85}$ mV (sub-linear due to partial saturation)

2. **Leak curve:** **NOT YET CHARACTERIZED** ❌
   - SimC gaps showed device settling (VGS=2V→0V transient), NOT FE relaxation
   - τ_P = 0 in all current runs — no controlled leak mechanism
   - **Required:** Re-run with τ_P > 0 and write-then-read protocol

3. **Fire threshold:** **NOT YET DEMONSTRATED** ❌
   - SimC's reported "6.8x fire ratio" was invalid — it compared I(VGS=2V) to I(VGS≈0.05V)
   - This is the device's normal transconductance, not a threshold-crossing fire event
   - **Required:** Redesigned simC with write-then-read protocol (see Step_1 §4F.5)
   - **Expected:** With VGS_read=0.20V and dVth≈11mV/pulse, fire around pulse 6-8

4. **Capacitance ($C_{gg}$):** **NOT YET EXTRACTED** ❌ — Need AC simulation

5. **ON/OFF resistance:** **NOT YET MEASURED** ❌
   - Previous R_on/R_off values (1.9kΩ/13kΩ) were derived from the invalid fire analysis
   - Must be re-extracted from the redesigned write-then-read simulation at VGS_read

6. **Energy per spike:** **NOT YET MEASURED** ❌
   - Previous 75 fJ estimate was meaningless (no actual spike occurred)
   - Must be extracted from a genuine fire transient

7. **Reset:** From simC → **100% Vth recovery** with Vreset = -4.0V ✅

### **VALIDATED PARAMETERS:**
| Parameter | Value | Unit | Source | Status |
|-----------|-------|------|--------|--------|
| Vth_virgin | 0.263 | V | Calibration Run 16 | ✅ Valid |
| Integration weight | 11.36 | mV/pulse | simB (20 pulses) | ✅ Valid |
| Reset voltage | -4.0 | V | simC (best completeness) | ✅ Valid |
| Reset completeness | 100.0 | % | simC (Vreset = -4V) | ✅ Valid |
| SS | 60.8 | mV/dec | Run 6+7b extraction | ✅ Valid |
| τ_E | 1.0 | µs | Switching time constant | ✅ Valid |

### **PENDING PARAMETERS (require redesigned simC):**
| Parameter | Status | What's Needed |
|-----------|--------|---------------|
| N_fire (pulses to fire) | ❌ Pending | Write-then-read simC |
| E_spike (energy/spike) | ❌ Pending | Actual fire transient |
| R_on / R_off | ❌ Pending | Read-bias measurement |
| τ_leak | ❌ Pending | τ_P > 0 simulation |
| C_gg | ❌ Pending | AC small-signal analysis |

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

---

## 5. SimC Results Summary and Validation

### 5.1 Experimental Results

**Date:** March 24, 2026  
**Simulation:** Phase 1C - Full LIF Cycle (simC)  
**Nodes:** 3 reset voltages (-2V, -3V, -4V)  
**Status:** ✅ PARTIAL SUCCESS

### 5.2 Key Findings (CORRECTED March 2026)

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| **Integration ΔVth** | 16.1 mV (5 pulses) | ~63 mV (to cross VGS_read) | ✅ On track (need more pulses) |
| **Reset Completeness** | 100% (Vreset = -4V) | >80% | ✅ Success |
| **Fire Detection** | **NOT demonstrated** | Threshold crossing at VGS_read | ❌ Needs redesigned simC |
| **Leak Rate** | Not measured (τ_P=0) | TBD | ❌ Needs τ_P > 0 |
| **Energy/Spike** | Not measured | <100 fJ | ❌ Needs actual fire transient |

### 5.3 What Was Wrong in Original Analysis

The original simC analysis (March 24) claimed "Fire detected at pulse 5 with 6.8x ratio." This was **invalid**:
- The 6.8x ratio compared drain current at VGS=2V (write pulse) to VGS≈0.05V (QS baseline)
- This is the device's normal transconductance response, NOT a threshold-crossing fire event
- A real fire must show ID increasing at a **constant read voltage** as Vth shifts past it
- See `simC_analysis_summary.md` for full correction details

### 5.4 Validated vs Pending Parameters

**Ready for use:**
```python
VALID_PARAMETERS = {
    "Vth_virgin": 0.263,        # V (from calibration) ✅
    "dVth_per_pulse": 11.36e-3, # V (from simB, 20 pulses) ✅
    "Vreset": -4.0,             # V (from simC reset test) ✅
    "reset_completeness": 1.0,  # fraction ✅
    "SS": 60.8e-3,              # V/dec ✅
    "tau_E": 1e-6,              # s ✅
}
```

**Pending (need redesigned simC with write-then-read protocol):**
```python
PENDING_PARAMETERS = {
    "N_fire": None,      # Pulses to fire (expected ~6-8 with VGS_read=0.20V)
    "E_spike": None,     # Energy per spike (from actual fire transient)
    "R_on": None,        # ON resistance at fire
    "R_off": None,       # OFF resistance at read bias
    "tau_leak": None,    # Leak time constant (requires τ_P > 0)
    "C_gg": None,        # Gate capacitance (requires AC simulation)
}
```

### 5.5 Next Steps

1. **Immediate:** Redesign simC with write-then-read protocol (new sdevice cmd file)
2. **Short-term:** Run redesigned simC, extract fire parameters
3. **Medium-term:** Set τ_P > 0 for leak characterization, AC analysis for C_gg
4. **Long-term:** Complete FeFET_LIF class and deploy in SNN

---

## 6. Conclusion

The GAA-FeFET LIF neuron has demonstrated **integration** and **reset** in TCAD simulation. The **fire** mechanism has not yet been demonstrated due to an incorrect measurement protocol in simC (comparing currents at different VGS values instead of monitoring at a constant read bias). A redesigned simulation with a write-then-read protocol is required.

**Validated so far:**
- Cumulative Vth shift (integration): 227.3 mV over 20 pulses ✅
- Reset completeness: 100% with Vreset = -4V ✅
- Sub-coercive partial switching mechanism confirmed ✅

**Pending:**
- Fire demonstration via write-then-read protocol
- Leak characterization with τ_P > 0
- Energy per spike, R_on/R_off from actual fire transient

**Key promise:** A **single transistor** (GAA-FeFET) to replace the CMOS LIF circuit (20+ transistors + capacitor). The integration mechanism is proven; fire demonstration is the critical next step.
