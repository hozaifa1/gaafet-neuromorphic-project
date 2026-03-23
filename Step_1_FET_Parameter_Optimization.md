# Paper 1: Novel GAA-FeFET Structural Optimization for High-Performance LIF Neurons

## 1. Introduction and Fundamental Theory

### 1.1 How a GAA-FeFET Works
A GAA-FET consists of silicon nanosheets surrounded by a gate stack for ultimate electrostatic control. Adding an HZO ferroelectric layer creates a FeFET whose polarization modulates $V_{th}$, enabling non-volatile memory and integration.

### 1.2 The LIF Neuron Analogy — Polarization-Based Mechanism
Our GAA-FeFET uses **ferroelectric polarization switching dynamics** as the spiking mechanism — NOT Impact Ionization:

- **Integration:** Sub-coercive gate voltage pulses partially switch FE domains → each pulse shifts $V_{th}$ lower. The ferroelectric polarization state IS the membrane potential.
- **Leak:** Between pulses, domain relaxation (governed by $\tau_P$ and domain-domain interaction) causes partial depolarization → $V_{th}$ drifts back up.
- **Fire:** When enough domains have switched that $V_{th}$ drops below the operating $V_{GS}$ (with constant $V_{DS}$), the channel abruptly turns ON → $I_D$ spikes.
- **Reset:** A negative gate pulse resets polarization to the initial state → $V_{th}$ returns to high state.

### 1.3 Why Not Impact Ionization?
The Bhatawdekar et al. reference paper uses a **standard GAA FNSFET** (no FE layer) with Impact Ionization + floating body for spiking. Our device adds an HZO ferroelectric layer, which:
1. Changes the capacitive voltage divider → screens the drain junction field
2. GAA geometry provides strong gate coupling → further suppresses drain-body reverse bias
3. Result: $F_{ava}$ is far below critical field → II generates zero carriers (confirmed in Runs 8a/8b/8c — see `spiking_simulation_debugging_log_v2.md`)

**Literature confirms this:** FeFET-based LIF neurons universally use polarization switching, not II:
- **Frontiers (2020), Jerry et al.:** 28nm FeFET — sub-coercive pulses → domain switching → $V_{th}$ shift → $I_D$ spike. No II.
- **Nature Comms (2022), Cao et al.:** AFeFET — inherent polarization/depolarization = integrate/leak, 37 fJ/spike. No II, no external capacitor, no reset circuit.
- **Khanday et al. (2024):** DG-FE-TFET — BTBT + FE gate, 0.58 aJ/spike. No II.

### 1.4 Advantages of Polarization-Based LIF
- **No external capacitor:** FE polarization replaces membrane capacitance
- **No reset circuitry** (for AFeFET variant) or simple negative pulse reset
- **CMOS-compatible:** HZO is standard BEOL-compatible material
- **Multi-level integration:** Gradual domain switching provides analog accumulation
- **Programmable threshold:** Different FE states = different synaptic weights = different $V_{th}$
- **Ultra-low energy:** 37 fJ/spike (AFeFET) demonstrated experimentally

---

## 2. Calibration Work Completed

### 2.1 Summary
All details in `Calibration_Log_2026_01_15.md`. Total: 16 runs across 3 stages.

- **Stage 1 (DC, Runs 1-5):** Swept FixedCharge and AreaFactor for $V_{th}=0.25V$, $I_{on}=600\mu A$.
- **Stage 2 (Hysteresis, Runs 6-13):** Activated `Polarization` (Preisach model), recalibrated AreaFactor, increased sweep to $\pm 6.0V$.
- **Stage 3 (Final, Runs 14-16):** Re-tuned WF=4.35eV, FixedCharge=4e12, AreaFactor=0.071.

### 2.2 Final Calibrated Parameters (Run 16 — "Golden")

| Parameter | Value |
|---|---|
| Workfunction | 4.35 eV |
| Fixed Charge | 4.0×10¹² cm⁻² |
| AreaFactor | 0.071 |
| $V_{th}$ (Fwd) | 0.263 V |
| $I_{peak}$ | 604 μA |
| Memory Window | 0.681 V (CCW) |
| $P_r$ / $P_s$ / $F_c$ | 16 μC/cm² / 20 μC/cm² / 1.2 MV/cm |
| $\tau_E$ | 1 ns |

### 2.3 Calibration Sufficiency Assessment

The existing calibration is **sufficient for polarization-based LIF** because:
- ✅ Hysteresis loop verified (CCW, MW=0.681V)
- ✅ $V_{th}$ and $I_{on}$ matched
- ✅ Preisach model active with $\tau_E$ for transient dynamics
- ✅ SS = 60.8 mV/dec confirmed (Boltzmann limit — excellent gate control)

**Not yet verified (needed for Phase 1A):**
- Partial polarization switching response to sub-coercive pulses
- Domain-by-domain $V_{th}$ modulation curve
- Depolarization dynamics ($\tau_P$ characterization)
- Pulse amplitude/width/number dependence of $V_{th}$ shift

---

## 3. Impact Ionization Investigation Summary

Full details in `spiking_simulation_debugging_log_v2.md`.

### 3.1 Key Technical Lessons (Retained)
- **Transient+Goal uses normalized step sizes** (fractions 0-1), not absolute seconds
- **$\tau_E$ required** in Preisach model for transient stability (default=0 → infinite stiffness)
- **SS = 60.8 mV/dec** from two-point extraction (Run 6 + 7b)
- **Initial $V_{DS}$ must be 0V** when probing transient behavior

### 3.2 II Failure Conclusion
Runs 8a/8b/8c (d0 swept from 7.1e5 to 1e5) produced byte-identical output. II generates zero carriers. The HZO + GAA combination screens the drain junction field below the avalanche threshold. **Impact Ionization is not a viable spiking mechanism for this device.**

---

## 4. Phase 1A: Polarization Switching Characterization (CURRENT PRIORITY)

### 4.1 Objective
Characterize the GAA-FeFET's ferroelectric polarization switching dynamics to validate the polarization-based LIF mechanism in TCAD.

### 4.2 Simulation Plan

**Sweep 1: Transfer Characteristics (Baseline)**
- Standard $I_D$-$V_{GS}$ at $V_{DS}$ = 50mV and 1.0V
- Verify SS, DIBL, $I_{off}$, full curve shape
- Compare virgin state vs. programmed state

**Sweep 2: Partial Polarization Switching (Sub-Coercive Pulses)**
- Apply gate pulse train: amplitude below $V_c$ (e.g., 0.5V–2.0V in steps)
- Pulse width: 100ns, 1μs, 10μs
- After each pulse, read $I_D$ at fixed $V_{GS}$ and $V_{DS}$ = 50mV
- Map: number of pulses → $\Delta V_{th}$ → $\Delta I_D$
- This is the "integration" characterization

**Sweep 3: Depolarization Dynamics (Leak Characterization)**
- Program device to a known FE state (partial or full)
- Remove gate bias, wait variable time (1μs to 1s)
- Read $V_{th}$ after each wait interval
- Extract $\tau_{leak}$ (depolarization time constant)
- This is the "leak" characterization

**Sweep 4: Firing Threshold Identification**
- Apply increasing number of sub-coercive pulses
- Monitor $I_D$ at constant $V_{DS}$
- Identify the pulse count at which $I_D$ jumps abruptly (= "fire")
- Characterize the sharpness of the transition (analog vs. abrupt)

**Sweep 5: Reset Verification**
- After firing, apply negative gate pulse (amplitude, width sweep)
- Verify $V_{th}$ returns to initial state
- Measure reset energy

### 4.3 Parameters to Sweep (in `sdevice_des.cmd`)

| Parameter | Range | Purpose |
|---|---|---|
| Gate pulse amplitude | 0.5V – 3.0V (step 0.5V) | Find sub-coercive sweet spot |
| Gate pulse width | 10ns – 100μs | Speed vs. switching trade-off |
| Number of pulses | 1 – 50 | Integration depth |
| Inter-pulse interval | 100ns – 100μs | Leak rate characterization |
| $V_{DS}$ (read) | 50mV, 0.5V, 1.0V | Sensitivity to drain bias |
| Reset pulse amplitude | -1V to -4V | Reset completeness |
| $\tau_E$ | 0.1ns, 1ns, 10ns | Switching speed tuning |
| $\tau_P$ | 0, 1μs, 10μs, 100μs | Leak rate tuning |

---

## 5. Phase 1B: LIF Transient Demonstration

### 5.1 Objective
Demonstrate a complete Integrate → Leak → Fire → Reset cycle in a single TCAD transient simulation.

### 5.2 Simulation Sequence
1. **Initialize:** Set $V_{DS}$ = constant (e.g., 0.5V), $V_{GS}$ = 0V (device OFF, high-$V_{th}$ state)
2. **Integrate:** Apply N sub-coercive gate pulses (amplitude, width from Phase 1A results)
3. **Observe Fire:** After N pulses, $V_{th}$ should drop → $I_D$ spikes
4. **Leak Test:** Insert wait periods between pulse groups → verify $I_D$ partially decays
5. **Reset:** Apply negative gate pulse → verify $V_{th}$ recovers

### 5.3 Success Criteria
- $I_D$ shows clear step-wise increase with each pulse (integration) ✅
- $I_D$ partially decays during inter-pulse gaps (leak) ✅
- $I_D$ jumps abruptly after sufficient pulses (fire) ✅
- Negative pulse resets device (reset) ✅

---

## 6. Phase II: Novel Device Engineering

### 6.1 Multi-Domain Preisach Optimization
- Enable domain-by-domain switching in TCAD (domain dispersion in $F_c$)
- Tune domain count and distribution for gradual (analog) integration
- Target: linear $\Delta V_{th}$ vs pulse count relationship

### 6.2 Ferroelectric Stack Engineering
- Sweep HZO thickness ($T_{fe}$: 5–15nm) for optimal sub-coercive switching window
- Sweep interfacial SiO₂ thickness ($T_{ox}$: 0.5–2nm) for capacitive divider optimization
- Trade-off: thinner HZO → lower $V_c$ → easier switching, but less $P_r$ → smaller MW

### 6.3 Anti-Ferroelectric Variant (Self-Resetting Neuron)
- Replace HZO (x=0.5) with Zr-rich $Hf_xZr_{1-x}O_2$ (x=0.2) for AFE behavior
- AFE provides: volatile polarization → natural self-reset → no external reset circuit
- Per Nature Comms (2022): 37 fJ/spike, >10¹² endurance
- TCAD: model using double-hysteresis Preisach parameters

### 6.4 Asymmetric Gate Stack (Optional Enhancement)
- Non-uniform FE thickness along channel for spatially graded switching
- Could create position-dependent $V_{th}$ for richer integration dynamics

---

## 7. File Reference

| File | Location | Purpose |
|---|---|---|
| Calibration Log | `Calibration_Log_2026_01_15.md` | Full 16-run calibration history |
| Spiking Debug Log | `spiking_simulation_debugging_log_v2.md` | Compressed: solver fixes, II failure, paradigm shift |
| Calibration CMD | `Simulations/calibration data/sdevice_calibration.cmd` | Hysteresis sweep command file |
| Phase 1A CMD | `Simulations/sdevice_des.cmd` | Polarization switching characterization |
| Parameter File | `Simulations/sdevice_gaafet_lif.par` | Material parameters (FE, mobility) |
| Calibration Data | `Simulations/calibration data/` | CSV outputs, PLT files, plots |
| Spiking Outputs | `Simulations/spiking_runs/` | Historical II-based transient runs |
| Analysis Scripts | `Simulations/py_scripts/` | Plotting and analysis tools |
