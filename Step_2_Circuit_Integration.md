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

**Status: MOSTLY COMPLETE** — SimC v6 demonstrated fire (6V, P9). Leak characterization pending (τ_P=0).

1. **Integration curve:** From simC v6 → gradual integration P1→P9 at 6V ✅
   - Integration weight: **6.7 mV/pulse** (average over P1-P9, write-then-read at VGS_read=0.20V)
   - Note: SimB gave 11.36 mV/pulse at Vpulse=2V — different operating point
   - Equation: sub-linear (partial saturation at higher N)

2. **Leak curve:** **PARTIALLY OBSERVED, NOT CHARACTERIZED** ⚠️
   - SimC v6 gap (P15→P16) shows 20-23% current drop in 5µs
   - **CAVEAT:** τ_P = 0 in all runs — observed decay is device settling, NOT controlled FE relaxation
   - **Required:** Re-run v6 with τ_P > 0 (1e-6, 1e-5, 1e-4 s) to extract true τ_leak

3. **Fire threshold:** **DEMONSTRATED** ✅ (SimC v6)
   - 6V fires at P9 (ID ratio = 2.035× baseline at VGS_read = 0.20V)
   - 7V fires at P5 (too early for useful temporal encoding)
   - 5V saturates at 1.89× (doesn't fire)
   - Fire criterion: ID_read/ID_baseline > 2.0× (arbitrary but functional)

4. **Capacitance ($C_{gg}$):** **NOT YET EXTRACTED** ❌ — Need AC simulation

5. **ON/OFF resistance:** Derivable from v6 data ⚠️
   - R_off ≈ VDS/ID_baseline = 0.05V / 9.525µA ≈ 5.25 kΩ (at VGS_read, pre-fire)
   - R_on ≈ VDS/ID_fire = 0.05V / 19.38µA ≈ 2.58 kΩ (at VGS_read, post-fire)
   - R_on/R_off ≈ 2.0 (modest, limited by sub-coercive switching range)

6. **Energy per spike:** **NOT YET MEASURED** ❌
   - Requires integration of VDS × ID during fire transient
   - Rough estimate: E ≈ VDS × ID_fire × pw = 0.05V × 19.4µA × 100ns ≈ 97 fJ

7. **Reset:** From simC v6 → **77.2% recovery** with Vreset = -5.0V ✅
   - Multi-cycle drift not tested

### **VALIDATED PARAMETERS (Updated March 30, 2026):**
| Parameter | Value | Unit | Source | Status |
|-----------|-------|------|--------|--------|
| Vth_virgin | 0.263 | V | Calibration Run 16 | ✅ Valid |
| N_fire | 9 | pulses | simC v6 (6V node) | ✅ Valid |
| fire_ratio | 2.035 | × | simC v6 (6V P9) | ✅ Valid |
| dVth_per_pulse | 6.7 | mV/pulse | simC v6 (P1-P9 avg) | ✅ Valid |
| Vpulse_optimal | 6.0 | V | simC v6 | ✅ Valid |
| pw | 100 | ns | simC v5/v6 | ✅ Valid |
| Vreset | -5.0 | V | simC v6 | ✅ Valid |
| Reset completeness | 77.2 | % | simC v6 (6V) | ✅ Valid |
| SS | 60.8 | mV/dec | Run 6+7b extraction | ✅ Valid |
| τ_E | 1.0 | µs | Switching time constant | ✅ Valid |
| pw/τ_E | 0.1 | — | Optimal integration ratio | ✅ Valid |
| R_on (estimated) | 2.58 | kΩ | v6 VDS/ID_fire | ⚠️ Estimate |
| R_off (estimated) | 5.25 | kΩ | v6 VDS/ID_baseline | ⚠️ Estimate |

### **PENDING PARAMETERS:**
| Parameter | Status | What's Needed |
|-----------|--------|---------------|
| τ_leak | ⚠️ Placeholder | τ_P > 0 simulation (CRITICAL for SNN leak dynamics) |
| E_spike | ❌ Pending | Transient power integration during fire |
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

## 5. SimC Results Summary and Validation (Updated March 30, 2026)

### 5.1 Experimental Results

**SimC v6 (FINAL):** pw=100ns, Vpulse=5/6/7V, Vreset=-5V, N=30 pulses, write-then-read protocol  
**Status:** FIRE ACHIEVED at 6V (P9) and 7V (P5)

### 5.2 Key Findings

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| **Integration** | Gradual P1→P9 at 6V (2.035×) | Monotonic increase | ✅ Success |
| **Fire** | 6V at P9, 7V at P5 | Ratio > 2.0× | ✅ Success |
| **Leak** | 20-23% current drop in 5µs gap | Observable decay | ⚠️ Observed (but τ_P=0 caveat) |
| **Reset** | 77.2% at Vreset=-5V (6V node) | >70% | ✅ Success |
| **Energy/Spike** | ~97 fJ (rough estimate) | <100 fJ | ⚠️ Estimate only |

### 5.3 Historical Note: Original simC Bug

The original simC (March 24) incorrectly claimed fire by comparing I(VGS=2V) to I(VGS=0.05V). This was the device's transconductance, not a threshold-crossing event. The write-then-read protocol (v3-v6) fixed this by reading at constant VGS_read=0.20V. See `simC_analysis_summary.md` for full history.

### 5.4 Final Parameter Set

```python
# === VALIDATED (from simC v6, 6V node) ===
VALID_PARAMETERS = {
    "Vth_virgin": 0.263,          # V (calibration Run 16)
    "N_fire": 9,                  # pulses (6V, write-then-read)
    "fire_ratio": 2.035,          # ID_fire / ID_baseline
    "dVth_per_pulse": -6.7e-3,    # V/pulse (avg P1-P9 at 6V)
    "Vpulse_optimal": 6.0,        # V
    "pw": 100e-9,                 # s
    "Vreset": -5.0,               # V
    "reset_completeness": 0.772,  # fraction
    "SS": 60.8e-3,                # V/dec
    "tau_E": 1e-6,                # s
    "VGS_read": 0.20,             # V
    "ID_baseline": 9.525e-6,      # A
}

# === PENDING ===
PENDING_PARAMETERS = {
    "tau_leak": None,    # CRITICAL: needs τ_P > 0 simulation
    "E_spike": None,     # Needs transient power integration
    "C_gg": None,        # Needs AC small-signal analysis
}
```

### 5.5 Next Steps

1. **Parallel with Step 2 Python:** Run τ_P > 0 characterization (tau_P = 1e-6, 1e-5, 1e-4 s)
2. **Optional:** Energy extraction from fire transient, multi-cycle endurance
3. **Step 2:** Build Python FeFET_LIF neuron class and SNN pipeline

---

## 6. Conclusion (Updated March 30, 2026)

The GAA-FeFET LIF neuron has demonstrated **integration**, **fire**, and **reset** in TCAD simulation using the write-then-read protocol (SimC v6). The **leak** mechanism has been observed (20-23% current drop in 5µs gap) but not yet controlled (τ_P = 0 in all runs).

**Validated:**
- Gradual multi-pulse integration (P1→P9 at 6V) ✅
- Fire at pulse 9 (2.035× current ratio) ✅
- Reset: 77.2% recovery at Vreset = -5V ✅
- Sub-coercive partial switching mechanism confirmed ✅
- pw/τ_E = 0.1 enables gradual integration ✅

**Pending:**
- Leak characterization with τ_P > 0 (CRITICAL for SNN tau_leak)
- Energy per spike from actual power integration
- Multi-cycle endurance testing
- C_gg (gate capacitance) from AC small-signal analysis — NEW (added 2026-05-03)

**Key result:** A **single GAA-FeFET transistor** demonstrates all four LIF behaviors through ferroelectric polarization switching. The device replaces the CMOS LIF circuit (20+ transistors + capacitor). Parameters are extracted and ready for Step 2 Python SNN implementation.

**See:** `Phase1_Plot_Compilation.md` for complete visual documentation. `simC_analysis_summary.md` for detailed v3-v6 progression and critical caveats. **`Phase1C_Plan.md`** for the four remaining TCAD deliverables and the Python v2 roadmap.

---

## 9. Step 2 v1 — Trained Model Results (Updated 2026-05-03)

### 9.1 Headline result

A recurrent spiking neural network (LSNN) using the GAA-FeFET as the active integration element of every neuron achieves **90.18% test accuracy** on the MIT-BIH 4-class ECG arrhythmia subset, exceeding the published VO2-memristor baseline (89.58%) on the same task. Source: `ecg_gaafefet_2.pdf` and `ecg_gaafefet_simplified.pdf` in repo root.

### 9.2 Architecture as actually implemented

| Layer | Spec |
|---|---|
| Input | 3 spike channels (delta-modulated ECG, +/-/cue) |
| fc1: DelayedLinear | 3 → 100, max_delay=10 SNN time-steps |
| Hidden recurrent | 60 LIF (eLIFVO2) + 40 ALIF (ALIFVO2) |
| Recurrent self-conn | DelayedLinear 100→100, max_delay=10 |
| lp: LPFilter | low-pass on spike output |
| fc2 | 100 → 4 logits, no bias |
| Decoder | argmax of last-time-step logits |

Time-step `dt = 0.5556 ms`, T=1116 (1000 ECG + 116 cue). Training: Adam, peak LR 1e-2, cosine annealing to 1e-4 over 150 epochs (stage 1: `main_ecg_6_polished.py`), then constant LR 5e-4 with spike-rate regulariser disabled for 2 epochs (stage 2: `main_ecg_7_resume.py`). BPTT + ScaledPiecewiseQuadratic surrogate gradient. Class-balanced cross-entropy.

### 9.3 How the GAA FeFET enters the model

The LIF membrane equation is RC integrate-and-fire:
```
v_{t+1} = e^{-dt/τ} v_t + (1 - e^{-dt/τ}) (R_h + R_s) s x_t
```
with:
- **R_h ≡ R_off = 5250 Ω** ← `LIF.R_off_estimate` (V_DS / I_D,baseline)
- **R_s ≡ R_on = 2580 Ω** ← `LIF.R_on_estimate` (V_DS / I_D,fire)
- **τ = 11.11 ms** chosen for ECG timescale; back-calculates **C_mem = 1.419 µF** (external)
- **gain = (R_h + R_s) · s = 77.5** with s = 9.9e-3 V/A
- **v_th = 3.6 V**, **v_h = 1.5 V** ← from VO2 paper comparator design (NOT from the FeFET)

ALIF adds a CMOS spike-feedback adaptation circuit (κ_n, κ_p, V_tn, V_tp, W/L_n, W/L_p, R_a, C_a) using the operating-conditions block of `gaafefet_params.py`.

### 9.4 What the v1 model abstracts away (honest disclosure)

- **FeFET = 2-state resistor.** The model only consumes R_on/R_off; the partial-switching staircase, the leak, and the polarization kinetics are not in the forward pass.
- **C_mem is external.** 1.419 µF is *not* the FeFET's intrinsic gate capacitance. It is a fudge factor chosen to give τ=11.11 ms. The "single-FeFET capacitorless LIF" narrative is therefore **not yet defensible from v1**; it requires C_gg from simG (Phase 1C).
- **dt >> pw.** The SNN time-step (555 µs) is 5500× larger than the write pulse (100 ns), so pulse-level dynamics never enter the model.
- **`model_2.py` (FE-native, polarization-as-state) tops out at ~70%.** BPTT struggles with the bounded sigmoidal Preisach saturation. v1 abstraction was a deliberate trainability trade-off, not a physics simplification of convenience.

### 9.5 Confusion matrix highlights

Per-class accuracy from stage-2 confusion: N ~95%, F ~78%, SVEB ~80%, VEB ~93%. Dominant remaining errors are the F↔SVEB pair (morphological overlap, also the failure mode of every classifier on this dataset).

### 9.6 What v1 validates vs what it doesn't

| Claim | v1 evidence | Verdict |
|---|---|---|
| GAA-FeFET R_on/R_off can drive ECG-scale RC integration | 90.18% with R-mapped τ | **Validated** |
| Memory-window memory is sufficient for 4-class arrhythmia | Yes (303/336) | **Validated** |
| Single-FeFET LIF with no external cap | C_mem=1.419 µF is external | **NOT validated** — needs simG |
| FeFET kinetics native model trains | model_2.py at 70% | **Open** — v2c reparametrization is the next attempt |
| Hardware drift survives | endurance untested | **Open** — needs simF |
| Energy advantage vs CMOS | rough 97 fJ estimate from Phase 1B | **Open** — needs simE |

### 9.7 What's next (Step 2 v2 roadmap)

**Important framing.** v1 is a *port* of the VO2-paper LSNN code (Yin et al., NCOMMS 2023) with R_h/R_s swapped to FeFET values. The CMOS adaptation parameters, comparator setpoints (v_th, v_h), τ choice, and external C_mem all come from VO2-paper inheritance, not from our device. The 90.18% number therefore depends on a chain of assumptions that have not been verified for the GAA-FeFET. Phase 1C measures those assumptions; v2 is a rebuild, not a patch.

See `Phase1C_Plan.md` §0 (honest framing) and §5 (build order) for the full plan. Summary:

1. **TCAD first.** Run simG/simD/simE/simF to replace the v1 placeholders with measurements. simG is decisive — it tells us whether the FeFET-only τ is ms-scale (v1 framework survives) or ns-scale (re-timing required).
2. **v2.0:** rewrite `lif_parameters.py` with a `MEASURED` block. Move VO2-inherited numbers to `LEGACY_VO2_INHERITED` clearly marked.
3. **v2.1:** re-derive τ, v_th, v_h *analytically* from the new measurements. Do not carry VO2 setpoints forward.
4. **v2.2:** refit the same MIT-BIH 4-class task with the corrected forward model. If accuracy stays ≥ 85% the architecture port survives the rebuild. If it drops below 80%, the architecture itself was over-fit to VO2-paper choices and must be redesigned. Either outcome is a real result.
5. **v2.3:** drift-aware training using simF.
6. **v2.4:** fix `model_2.py` (FE-native polarisation model) by reparametrising P → arctanh(P/P_s) so BPTT gradients survive the boundary saturation.
7. **Iterate** v2.0 ↔ v2.4 as needed.

**Publication recommendation:** do not ship v1 as a standalone GAA-FeFET claim. Either publish a Phase-1B-only device paper (calibration + fire demonstration) without an SNN deployment, or wait for v2 and publish a single SNN paper with measured numbers. v1's 90.18% appears in v2 as a benchmark reference, not as the headline.

