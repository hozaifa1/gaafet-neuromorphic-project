# Paper 1: Novel GAA-FeFET Structural Optimization for High-Performance LIF Neurons

## 1. Introduction and Fundamental Theory

### 1.1 The Higher Purpose: Why Build a FeFET Neuron?

Biological neurons process information through **integrate-and-fire** dynamics: they accumulate small input signals over time, and when a threshold is crossed, they emit a spike and reset. Spiking Neural Networks (SNNs) replicate this in hardware, but conventional CMOS implementations require 20+ transistors and external capacitors per neuron, limiting density and energy efficiency.

**Our goal:** Replace the entire CMOS LIF neuron circuit with a **single GAA-FeFET transistor** where the ferroelectric layer's polarization state naturally performs integration, leaking, and threshold-based firing — all within the physics of one device. This eliminates the need for external capacitors (the FE layer IS the capacitor) and complex reset circuitry.

**Why this matters for the thesis:**
- **Paper 1 (this document):** Prove through TCAD simulation that the GAA-FeFET device physics can reproduce all four LIF behaviors (integrate, leak, fire, reset), then optimize the device structure.
- **Paper 2 (`Step_2_Circuit_Integration.md`):** Extract the device parameters from TCAD and deploy them in a Python-based SNN to classify real biomedical signals (ECG), demonstrating a complete device-to-system pipeline.

### 1.2 How a GAA-FeFET Works — The Physical Picture

A **Gate-All-Around FET** wraps the gate electrode completely around silicon nanosheet channels, providing the strongest possible electrostatic control. Adding an **HZO ferroelectric layer** ($Hf_{0.5}Zr_{0.5}O_2$) to the gate stack creates a FeFET whose threshold voltage ($V_{th}$) depends on the **polarization state** of the ferroelectric:

- **Polarization UP** (positive charge facing channel) → surface potential increases → $V_{th}$ decreases → device turns ON more easily
- **Polarization DOWN** (negative charge facing channel) → surface potential decreases → $V_{th}$ increases → device is harder to turn ON

This polarization-$V_{th}$ coupling is the fundamental mechanism that enables the FeFET to act as a neuron.

### 1.3 The LIF Neuron Analogy — Why Each Physical Quantity Matters

| Biological Neuron | FeFET Device Physics | Why It Matters |
|---|---|---|
| **Membrane potential** | Ferroelectric polarization state ($P$) | The "memory" that accumulates input — as more domains switch, $P$ changes, shifting $V_{th}$ |
| **Synaptic input** | Sub-coercive gate voltage pulse | Each pulse nudges some domains to switch — this is one "input spike" being received |
| **Integration** | Cumulative polarization switching (multiple pulses) | Each pulse adds to what previous pulses did — $V_{th}$ drops progressively |
| **Leak** | Domain relaxation ($\tau_P$) | Between pulses, unstable domains relax back → $V_{th}$ drifts up → neuron "forgets" |
| **Firing threshold** | $V_{th}$ crosses below operating $V_{GS}$ | When enough domains switch, $V_{th}$ drops low enough that the channel turns ON abruptly → $I_D$ spikes |
| **Reset** | Negative gate pulse reverses polarization | Domains switch back → $V_{th}$ returns to initial high state → neuron is ready for next cycle |

### 1.4 What "Sub-Coercive" Means and Why It's Critical

The ferroelectric HZO layer has a **coercive field** $F_c$ = 1.2 MV/cm — the electric field needed to fully switch all domains from one polarization state to the other. When we apply gate voltages:

- **At or above coercive field:** ALL domains switch simultaneously → binary, all-or-nothing → useful for memory (0/1), but NOT for analog integration
- **Below coercive field (sub-coercive):** Only SOME domains switch — how many depends on the field strength and duration → this gives **gradual, analog control** over the polarization state

**Sub-coercive operation is essential for LIF behavior** because:
1. Each input pulse should cause a **small, incremental** polarization change (not a full switch)
2. Multiple pulses must **accumulate** — pulse N starts from where pulse N-1 left off
3. The amount of switching per pulse must be **rate-limited** by $\tau_E$ (the domain switching time constant) — if switching is too fast, the device reaches equilibrium on the first pulse and subsequent pulses have no additional effect

**Key parameter relationship:** For cumulative integration, $\tau_E$ (switching time) must be **much larger** than the pulse width. This ensures each pulse only partially switches the available domains, leaving room for the next pulse to continue the process.

### 1.5 What $\Delta V_{th}$ Physically Signifies

$\Delta V_{th}$ (threshold voltage shift) is the **primary observable** that tells us integration is working:

- **$\Delta V_{th}$ per pulse** = how much "membrane potential" changes per input spike = **synaptic weight resolution** in the SNN
- **$\Delta V_{th}$ vs pulse count** = the **integration curve** — should be a rising staircase, showing cumulative memory
- **Total $\Delta V_{th}$ before firing** = the **integration depth** = how many input spikes are needed to trigger a fire event
- **$\Delta V_{th}$ vs pulse amplitude** = the **voltage sensitivity** — higher amplitude = stronger synapse = more $V_{th}$ shift per pulse

In the SNN context: if $\Delta V_{th}$ per pulse = 15 mV and the total shift needed to fire = 300 mV, then 20 input spikes are needed → this defines the neuron's **integration depth** and **firing rate sensitivity**.

### 1.6 Why Not Impact Ionization?

The Bhatawdekar et al. reference paper uses Impact Ionization (II) in a standard GAA-FET (no FE layer). Our device adds HZO, which screens the drain junction field below the avalanche threshold. Runs 8a/8b/8c confirmed II generates zero carriers (see `spiking_simulation_debugging_log_v2.md`). All FeFET LIF neurons in literature use polarization switching, not II.

### 1.7 Literature Support

- **Frontiers (2020), Jerry et al.:** 28nm FeFET — sub-coercive domain switching → $V_{th}$ staircase → fire. First demonstration of FeFET LIF.
- **Nature Comms (2022), Cao et al.:** AFeFET — volatile polarization = natural leak + self-reset, 37 fJ/spike. No external capacitor or reset circuit.
- **Khanday et al. (2024):** DG-FE-TFET — BTBT + FE gate, 0.58 aJ/spike, 344 GHz spiking frequency.

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

## 4A. Sim A Results & Analysis (Completed)

### 4A.1 Summary

**Status: SUCCESS — Partial polarization switching confirmed.** All 5 Vpulse nodes produced monotonically increasing ΔVth and polarization shifts, validating the sub-coercive switching mechanism.

**Recommended Vpulse for Sim B: 2.0V**

### 4A.2 ΔVth Extraction — τ_E = 1µs Run (UPDATED)

> **Note:** Previous SimA data (τ_E = 1ns) showed differentiated ΔVth (26–160 mV). Those values reflected equilibrium polarization switching, not partial switching. With τ_E = 1µs, each 100ns pulse shifts P by only ~10% of equilibrium. The table below shows the re-run results.

| Node | Vpulse (V) | Baseline ID (μA) | Post-pulse ID (μA) | ΔVth (mV) |
|------|-----------|-------------------|---------------------|-----------|
| n3 | 1.0 | 2.422 | 3.288 | 21.5 |
| n4 | 1.5 | 2.422 | 3.289 | 21.5 |
| n5 | 2.0 | 2.422 | 3.289 | 21.5 |
| n6 | 2.5 | 2.422 | 3.290 | 21.5 |
| n7 | 3.0 | 2.422 | 3.290 | 21.5 |

**Result: FLAT.** ΔVth spread is only 0.03 mV across the full 1–3V range. See §4A.4 for root cause.

### 4A.3 Polarization During Pulse Hold — τ_E = 1µs (DIFFERENTIATED)

Despite the flat ΔVth readout, the **pulse hold data shows clear differentiation**:

| Vpulse (V) | Pol/y end (μC/cm²) | E/F_c (%) | P/P_r (%) |
|-----------|---------------------|-----------|-----------|
| 1.0 | −0.045 | 9.6 | 0.3 |
| 1.5 | −0.058 | 23.9 | 0.4 |
| 2.0 | −0.071 | 38.2 | 0.4 |
| 2.5 | −0.084 | 52.6 | 0.5 |
| 3.0 | −0.098 | 67.1 | 0.6 |

**Key:** The pulse DOES shift P differently per Vpulse. The values are ~10% of the old τ_E=1ns equilibrium values, exactly as predicted by pw/τ_E = 0.1. But the Quasistationary readout erases these small differences (see §4A.4).

### 4A.4 Root Cause: Quasistationary Readout Erases Polarization State

**This is the critical finding from the τ_E = 1µs re-run.**

The `Quasistationary` solver computes the steady-state solution at each VGS bias step. This means the ferroelectric polarization reaches its equilibrium value for the applied E-field at every step, regardless of what state the transient pulse left it in.

With τ_E = 1µs and pw = 100ns, each pulse shifts P by only ~0.05–0.10 µC/cm² (tiny fraction of P_r = 16 µC/cm²). When the Quasistationary readout sweep then evolves P to equilibrium at each VGS step, these tiny pulse-induced differences are completely erased.

**Evidence:** All 5 post-pulse ID-VGS curves are identical to 4+ significant figures, despite clearly different pulse-hold P values.

**This does NOT mean τ_E = 1µs is wrong.** It means the readout method is incompatible with partial-switching measurement. See §4C for the fix.

### 4A.5 Vpulse Selection (Tentative)

Since the readout issue masks the per-pulse ΔVth, the Vpulse recommendation must come from the **pulse hold polarization data** (§4A.3) rather than the readout ΔVth. Based on E/F_c ratio and sub-coercive margin:

**Tentative: Vpulse = 2.0V** (E/F_c ≈ 38%, good sub-coercive headroom). To be confirmed after readout fix.

---

## 4B. Sim B Results & Analysis — τ_E = 1µs (UPDATED)

### 4B.1 Summary

**Status: PARTIAL SUCCESS.** Integration IS occurring but the Quasistationary readout resets polarization between measurement points. Readouts at N=1,3,5 show ~zero ΔVth, but N=10 and N=20 show growing ΔVth because 5–10 consecutive pulses accumulate enough ΔP to partially survive the readout.

### 4B.2 Readout Data (Vpulse=2V, τ_E=1µs)

| Read Point | N (pulses) | Consec. pulses since last read | ID @VGS=0.003V (µA) | ΔVth (mV) | Pol/y at readout (µC/cm²) |
|------------|-----------|-------------------------------|----------------------|-----------|--------------------------|
| Baseline | 0 | — | 2.163 | 0.0 | +0.129 |
| read_n01 | 1 | 1 | 2.163 | 0.0 | +0.129 |
| read_n03 | 3 | 2 | 2.164 | 0.0 | +0.129 |
| read_n05 | 5 | 2 | 2.164 | 0.0 | +0.129 |
| read_n10 | 10 | 5 | 3.266 | 27.0 | −0.068 |
| read_n20 | 20 | 10 | 4.462 | 56.3 | −0.265 |

### 4B.3 Pulse-Hold Polarization (Before Readout)

| Pulse # | End-of-hold Pol/y (µC/cm²) | Note |
|---------|---------------------------|------|
| P1 | +0.0815 | 1 pulse from virgin |
| P5 | +0.0349 | 2 pulses from read_n03 reset |
| P6 | **+0.0815** | **Identical to P1 — proof readout resets P** |
| P10 | −0.3376 | 5 consecutive pulses (no read between P6–P10) |
| P20 | −0.6985 | 10 consecutive pulses (no read between P11–P20) |

### 4B.4 Smoking Gun: P6 = P1

Pulse 6 end-of-hold Pol/y (+0.0815 µC/cm²) is **byte-identical** to Pulse 1 (+0.0815 µC/cm²). This proves the Quasistationary readout after N=5 completely resets P back to the virgin state. The 5 pulses of accumulated switching are erased.

### 4B.5 Consecutive-Pulse Integration IS Working

Between readout points where multiple pulses fire consecutively:
- **N=5→N=10 (5 pulses, no read):** ΔID = +1.102 µA, Pol/y swings from +0.129 to −0.068 µC/cm²
- **N=10→N=20 (10 pulses, no read):** ΔID = +1.196 µA, Pol/y swings from −0.068 to −0.265 µC/cm²

This is cumulative integration — exactly what we need for LIF behavior. The mechanism works; only the measurement method is flawed.

### 4B.6 Why τ_E = 1ns Was NOT Better

The old τ_E = 1ns gave "nicer" SimA curves (differentiated ΔVth) but **fundamentally cannot support cumulative integration**:
- With τ_E = 1ns, each 100ns pulse fully equilibrates P (pw/τ_E = 100)
- Every pulse reaches the same equilibrium → no room for accumulation
- SimB with τ_E = 1ns showed flat ΔVth(N) ≈ 97.4 mV for all N

With τ_E = 1µs:
- Each pulse partially switches P (~10% of equilibrium)
- Consecutive pulses accumulate → P grows monotonically (proven by P1→P10→P20 data)
- **τ_E = 1µs is the CORRECT value for LIF integration**

### 4B.7 Plots

See `Simulations/py_scripts/`:
- `analysis_fig1_simA_idvgs_flat.png` — SimA: all post-pulse curves overlap (flat)
- `analysis_fig2_simA_dvth_flat.png` — SimA: ΔVth bar chart (all ≈21.5 mV)
- `analysis_fig3_simA_hold_differentiated.png` — SimA: pulse-hold P IS differentiated
- `analysis_fig4_simB_idvgs.png` — SimB: ID-VGS overlay for all readout points
- `analysis_fig5_simB_staircase.png` — SimB: ΔVth staircase (flat N=1–5, rising N=10–20)
- `analysis_fig6_simB_pulse_pol_evolution.png` — SimB: sawtooth P evolution (smoking gun)

---

## 4C. The Fix: Transient Readout (Next Step)

### 4C.1 Problem Statement

The `Quasistationary` solver used for ID-VGS readout sweeps allows polarization to reach equilibrium at each bias point. This erases the small partial-switching state set by the transient gate pulse. With τ_E = 1µs and pw = 100ns, each pulse shifts P by only ~10% of equilibrium — too small to survive QS readout.

### 4C.2 Solution: Fast Transient Readout

Replace all `Quasistationary` readout blocks with `Transient` readout that completes in a time **much shorter than τ_E**:

- **Readout duration:** 1 ns (1000× shorter than τ_E = 1µs)
- **VGS range:** 0 → 0.3V (unchanged)
- **Mechanism:** The Transient solver enforces real-time evolution. In 1 ns, the polarization has time to move only 0.1% (1ns / 1µs) — effectively frozen during readout.

**Syntax change** in `sdevice_phase1a_simA.cmd` and `sdevice_phase1a_simB.cmd`:

```
*== OLD (Quasistationary — erases P): ==
Quasistationary (
  InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
  Goal { Name="gate_contact" Voltage= 0.3 }
) { Coupled (Iterations = 100) {Poisson Electron Hole} }

*== NEW (Transient — preserves P): ==
Transient (
  InitialTime=<T_current> FinalTime=<T_current + 1e-9>
  InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
  Increment=1.4
  Goal { Name="gate_contact" Voltage= 0.3 }
) {
  Coupled (Iterations = 100) {Poisson Electron Hole}
  CurrentPlot( Time = (Range=(<T_current> <T_current + 1e-9>) Intervals=50) )
}
```

### 4C.3 Expected Outcome

With Transient readout:
- **SimA:** ΔVth should show monotonic increase with Vpulse (differentiated, matching pulse-hold P data)
- **SimB:** ΔVth(N) should show a proper staircase — each pulse contributing ~equal increment
- The sawtooth P-reset pattern (Fig 6) should disappear

### 4C.4 Corrected Workflow

1. **Modify `sdevice_phase1a_simA.cmd`:** Replace QS readout with Transient readout (1ns sweep)
2. **Re-run SimA** → confirm differentiated ΔVth, select final Vpulse
3. **Modify `sdevice_phase1a_simB.cmd`:** Same Transient readout fix
4. **Re-run SimB** → confirm cumulative Vth(N) staircase
5. **Run SimC** with τ_P > 0 → observe leak + reset
6. Extract all parameters for Step 2 circuit model

---

## 4D. SimA Results — TRANSIENT READOUT SUCCESS (τ_E = 1µs)

### 4D.1 Summary

**Status: COMPLETE SUCCESS.** The Transient readout fix (1ns sweep) perfectly preserves the partial-switching state. ΔVth now shows clear monotonic increase from 7.4mV to 26.4mV across 1–3V pulse amplitudes.

### 4D.2 Results Table (Transient Readout)

| Vpulse (V) | ΔVth (mV) | ID_base (µA) | ID_post (µA) | Pol_end (µC/cm²) | E/F_c (%) |
|-----------|-----------|--------------|--------------|------------------|-----------|
| 1.0 | 7.4 | 2.055 | 2.361 | +0.107 | 12.5 |
| 1.5 | 11.8 | 2.055 | 2.542 | +0.095 | 26.7 |
| 2.0 | 16.5 | 2.055 | 2.733 | +0.081 | 41.0 |
| 2.5 | 21.3 | 2.055 | 2.933 | +0.068 | 55.4 |
| 3.0 | 26.4 | 2.055 | 3.142 | +0.054 | 69.9 |

**Key metrics:**
- **ΔVth range:** 19.0 mV (clear differentiation vs 0.03 mV with QS)
- **Linearity:** Excellent monotonic increase
- **Sub-coercive:** All nodes E/F_c < 70% (well below saturation)

### 4D.3 Validation Against Expectations

✅ **Partial switching preserved:** Transient readout (1ns << τ_E=1µs) freezes P state  
✅ **Voltage-dependent response:** Clear ΔVth(Vpulse) trend  
✅ **Sub-coercive operation:** Maximum E/F_c = 69.9% (still below 100% saturation)  
✅ **Reasonable signal:** ΔVth per pulse 7–26 mV (measurable, not overwhelming)  

### 4D.4 Vpulse Recommendation for SimB

**Selected: Vpulse = 2.0V** (balanced choice)

| Criterion | Value | Assessment |
|-----------|-------|------------|
| ΔVth per pulse | 16.5 mV | Good signal, room for 20-pulse accumulation |
| E/F_c ratio | 41.0% | Well within sub-coercive (good headroom) |
| Pol shift | +0.081 µC/cm² | ~0.5% of P_r (appropriate partial switching) |
| Expected 20-pulse ΔVth | ~330 mV | Comparable to calibration MW/2 |
| CMOS compatibility | 2.0V | Standard I/O voltage |

**Alternative:** Vpulse = 2.5V (ΔVth = 21.3 mV, E/F_c = 55.4%) if stronger signal needed.

### 4D.5 Plots

See `Simulations/py_scripts/`:
- `simA_transient_fig1_idvgs.png` — Clear separation of ID-VGS curves
- `simA_transient_fig2_dvth.png` — Differentiated ΔVth bar chart (SUCCESS)
- `simA_transient_fig3_hold.png` — Pulse-hold polarization dynamics
- `simA_transient_fig4_comparison.png` — Transient vs QS readout comparison

### 4D.6 Physics Confirmation

The results confirm the fundamental design principle:
- **τ_E = 1µs** enables partial switching (pw/τ_E = 0.1)
- **Transient readout** preserves the small P shifts during measurement
- **Cumulative integration** is now physically achievable in SimB

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
