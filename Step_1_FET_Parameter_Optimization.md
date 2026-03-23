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
Characterize the GAA-FeFET's ferroelectric polarization switching dynamics to validate the polarization-based LIF mechanism in TCAD using Sentaurus Workbench (SWB) parameter sweeping.

### 4.2 SWB-Based Simulation Structure

Three focused `.cmd` files replace the monolithic `sdevice_des.cmd`. Each is optimized for SWB `@variable@` parameter sweeping:

#### **Sim A: Single Pulse Amplitude Sweep** (`sdevice_phase1a_simA.cmd`)
- **Purpose:** Find optimal gate pulse amplitude for partial (sub-coercive) switching
- **SWB Parameter:** `@Vpulse@` = 1.0, 1.5, 2.0, 2.5, 3.0 V (5 runs)
- **Fixed:** VDS=0.05V, pulse width=100ns, tau_E=1ns (in .par)
- **Sequence:**
  1. Baseline ID-VGS sweep (virgin FE state)
  2. Single gate pulse (rise → hold → fall)
  3. Post-pulse ID-VGS sweep
- **Extract:** ΔVth per amplitude → identify best Vpulse for partial switching

#### **Sim B: Multi-Pulse Integration** (`sdevice_phase1a_simB.cmd`)
- **Purpose:** Demonstrate cumulative Vth shift = "integration" behavior
- **SWB Parameter:** `@Npulses@` = 1, 3, 5, 10, 20 (5 runs, or use fixed best Vpulse from Sim A)
- **Fixed:** Vpulse from Sim A result, VDS=0.05V, pw=100ns
- **Sequence:** Apply N identical pulses with 100ns spacing, read ID-VGS after all pulses
- **Extract:** Vth(N) staircase → integration curve

#### **Sim C: Full LIF Cycle** (`sdevice_phase1a_simC.cmd`)
- **Purpose:** Demonstrate complete Integrate → Leak → Fire → Reset cycle
- **SWB Parameter:** `@Vreset@` = -2.0, -3.0, -4.0 V (3 runs)
- **Fixed:** Vpulse from Sim A, VDS=0.05V, 5 pulses with 1μs gaps
- **Sequence:**
  1. 5 gate pulses (integrate)
  2. 1μs gaps between pulses (observe leak decay in ID)
  3. Negative reset pulse (reset)
  4. Post-reset ID-VGS sweep (verify recovery)
- **Extract:** ID vs time waveform, reset completeness per Vreset

### 4.3 Expected Outputs & Extraction Methods

| Sim | Parameter | Sweep | Extract From .plt | Desired Output | Paper Ref | Purpose |
|---|---|---|---|---|---|---|
| A | Vpulse | 1.0–3.0V | baseline_fwd vs postpulse_fwd ID-VGS | ΔVth vs Vpulse curve | Frontiers 2020 Fig.3 | Find optimal amplitude |
| A | Vpulse | (same) | pulse_hold Polarization(y) | Partial P-E loop | HZO modeling paper | Confirm sub-coercive switching |
| B | Npulses | 1,3,5,10,20 | postpulse_fwd Vth after all pulses | Vth(N) staircase | Frontiers 2020 Fig.5 | Demonstrate integration |
| B | — | — | pN_hold ID segments | Stepwise ID increase | AFeFET Nature Comms Fig.2 | Show cumulative switching |
| C | Vreset | -2.0 to -4.0V | Full lif_* sequence ID vs time | LIF waveform: integrate→leak→fire | Khanday DG-FE-TFET Fig.7 | Full cycle demonstration |
| C | Vreset | (same) | postreset_fwd vs baseline Vth | Vth recovery per Vreset | AFeFET paper | Quantify reset completeness |
| C | — | — | lif_gap* Polarization(y) | P decay during gaps | HZO modeling paper | Demonstrate leak mechanism |
| .par | tau_P | 0, 1μs, 10μs, 100μs | Re-run simC, compare gap decay | Leak time constant τ_m | AFeFET paper | Map to Python SNN model |
| .par | tau_E | 0.1ns, 1ns, 10ns | Re-run simA, compare P settling | Switching speed | FeFET_CAM example | Validate insensitivity |

### 4.4 Progressive Sweep Strategy (Efficiency Optimization)

**Total: ~12–15 runs instead of 100+**

1. **Sim A first** (5 runs) → Find best Vpulse
2. **Sim B next** (1 run with best Vpulse) → Confirm integration
3. **Sim C last** (3 runs) → Sweep Vreset, find complete reset
4. **tau_P manual** (3–4 runs of simC) → Only if simC works, characterize leak
5. **tau_E manual** (2–3 runs of simA) → Optional, validate switching speed

Each run takes ~5–15 min on Sentaurus server. Total time: ~2–3 hours.

### 4.5 SWB Setup Instructions

**Sim A:**
1. Create SWB project → add sdevice tool → set cmd file to `sdevice_phase1a_simA.cmd`
2. Add parameter `Vpulse`: sweep values `1.0  1.5  2.0  2.5  3.0`
3. Connect mesh TDR to `@tdr@` input
4. Run 5 nodes
5. Extract: Open each node's `.plt` → compare `baseline_fwd` and `postpulse_fwd` curves → extract Vth at ID=100nA

**Sim B:**
1. Add new sdevice tool → cmd file = `sdevice_phase1a_simB.cmd`
2. Add parameter `Vpulse` = (single best value from Sim A)
3. Run 1 node
4. Extract: Plot ID vs time across all `pN_hold` segments; compare `postpulse_fwd` Vth vs Sim A baseline

**Sim C:**
1. Add new sdevice tool → cmd file = `sdevice_phase1a_simC.cmd`
2. Add parameters: `Vpulse` = (from Sim A), `Vreset` = sweep `-2.0  -3.0  -4.0`
3. Run 3 nodes
4. Extract: Plot full ID vs time; compare `postreset_fwd` Vth vs baseline

**tau_P Manual:**
1. Edit `.par` → change `tau_P` line to `(0, 1e-6, 0)`
2. Re-run Sim C (best Vreset only, 1 node)
3. Repeat for `tau_P = 1e-5` and `1e-4`
4. Compare gap decay rates across 3 runs

**tau_E Manual (optional):**
1. Edit `.par` → change `tau_E` to `1e-10` or `1e-8`
2. Re-run Sim A (best Vpulse only, 1 node)
3. Compare polarization settling speed

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
