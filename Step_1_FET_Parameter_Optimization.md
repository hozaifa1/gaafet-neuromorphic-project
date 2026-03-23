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

### 4A.2 ΔVth Extraction (Constant-Current at VGS=0.01V)

Threshold voltage shift extracted from drain current ratio at VGS=0.01V (VDS=0.05V) using linear-regime approximation with estimated baseline Vth ≈ −50 mV:

| Node | Vpulse (V) | Baseline ID (μA) | Post-pulse ID (μA) | Ratio | ΔVth (mV) |
|------|-----------|-------------------|---------------------|-------|-----------|
| n3 | 1.0 | 2.128 | 3.044 | 1.43 | ~26 |
| n4 | 1.5 | 2.128 | 4.353 | 2.05 | ~63 |
| n5 | 2.0 | 2.128 | 5.627 | 2.64 | ~99 |
| n6 | 2.5 | 2.128 | 6.784 | 3.19 | ~131 |
| n7 | 3.0 | 2.128 | 7.803 | 3.67 | ~160 |

**Trend:** Monotonic increase — each 0.5V increment adds ~30–35 mV of ΔVth. Excellent linearity.

### 4A.3 Polarization State After 100ns Pulse Hold

| Vpulse (V) | Pol/y end (μC/cm²) | E/y end (MV/cm) | E/F_c (%) | P/P_r (%) |
|-----------|---------------------|-----------------|-----------|-----------|
| 1.0 | −0.260 | −0.067 | 5.6 | 1.6 |
| 1.5 | −0.641 | −0.156 | 13.0 | 4.0 |
| 2.0 | −1.051 | −0.241 | 20.1 | 6.6 |
| 2.5 | −1.484 | −0.321 | 26.8 | 9.3 |
| 3.0 | −1.938 | −0.398 | 33.2 | 12.1 |

**Key:** All nodes operate well within the sub-coercive regime (E < 33% of F_c). Even at Vpulse=3.0V, only 12% of P_r is switched — large headroom for cumulative multi-pulse integration.

### 4A.4 Read Disturb Issue (Design Caveat)

The baseline and postpulse ID-VGS sweeps (0→1V) cause polarization evolution during readout because `Physics(Material="HZO") { Polarization }` is active globally and the `Quasistationary` solver equilibrates P at each VGS step.

**Evidence:**
- Baseline Pol/y shifts from +0.128 to −0.260 μC/cm² during the 0→1V sweep (Δ = −0.388 μC/cm²)
- For n3 (1V pulse): postpulse Pol/y converges to baseline at VGS=1.0V → **readout erases the pulse effect**
- For n7 (3V pulse): postpulse Pol/y remains distinct at VGS=1.0V (−1.103 vs −0.260 μC/cm²) → **state partially retained**

**Impact:** Lower Vpulse states are more vulnerable to read disturb. The ΔVth values above (extracted at VGS=0.01V, first data point) are minimally contaminated, but the full sweep curves are affected.

**Mitigation for Sim B:**
1. Reduce readout sweep range to 0→0.3V (enough to extract Vth without erasing stored state)
2. Or use single-point current measurement at fixed VGS (e.g., 0.1V)

### 4A.5 SimA vs Calibration Comparison

| Feature | Calibration (worked, MW=683mV) | SimA | Issue? |
|---------|-------------------------------|------|--------|
| Gate sweep | ±6.0V (Transient) | 0→1V (Quasistationary) | Intentional: different purpose |
| VDS | 1.0V (saturation) | 0.05V (linear readout) | Intentional |
| FEPolarizationIP | 1.0 | Missing | ⚠️ Add for consistency |
| Method | Bitlis (Restart=100) | Blocked/ParDiSo | ⚠️ Bitlis more robust |
| Digits/Iterations | 5 / 50 | 4 / 20 | Minor |
| Avalanche | UniBo2 | Removed | Intentional |
| Hydrodynamic | Yes | Removed | Intentional |

**Conclusion:** All critical differences are intentional (calibration measures full hysteresis; simA measures partial switching). The missing `FEPolarizationIP=1.0` and weaker solver settings should be added to SimB for robustness.

### 4A.6 Vpulse Recommendation for Sim B

**Selected: Vpulse = 2.0V**

| Criterion | Value | Assessment |
|-----------|-------|------------|
| ΔVth per pulse | ~99 mV | Clear, measurable signal |
| E_HZO / F_c | 20.1% | Well within sub-coercive |
| P / P_r | 6.6% | Large headroom for accumulation |
| 5-pulse projected ΔVth | ~300–500 mV | Comparable to calibration MW/2 |
| CMOS compatibility | 2.0V | Standard I/O voltage |
| Read disturb resilience | Moderate | Better than 1.0/1.5V |

**Fallback:** If Sim B shows weak accumulation at 2.0V, repeat with Vpulse=2.5V.

### 4A.7 Sim B Setup Adjustments (Based on SimA Findings)

Changes to apply to `sdevice_phase1a_simB.cmd` before running:
1. **Add to Math block:** `FEPolarizationIP=1.0` and `Method = Bitlis (Restart=100, Tolerance=1e-5, Iterations=200)`
2. **Reduce readout sweep:** Change post-pulse gate sweep from 0→1.0V to 0→0.3V to minimize read disturb
3. **Set Vpulse:** Use `@Vpulse@ = 2.0` (single value, not a sweep)
4. **Npulses sweep:** `@Npulses@` = 1, 3, 5, 10, 20

---

## 4B. Sim B Results & Analysis (Completed — Integration Failed, Diagnosed & Fixed)

### 4B.1 Summary

**Status: NO CUMULATIVE INTEGRATION.** All 20 pulses at Vpulse=2.0V produced identical drain current and polarization state. The Vth(N) "staircase" is a flat line — pulse 1 and pulse 20 are indistinguishable.

**Root cause identified and fixed.** See 4B.3 below.

### 4B.2 Data — Flat Vth(N) Curve

| Read Point | N (pulses) | ID @VGS=0.003V (µA) | ΔVth (mV) | Pol/y hold end (µC/cm²) |
|------------|-----------|----------------------|-----------|------------------------|
| Baseline | 0 | 1.886 | 0 | — |
| read_n01 | 1 | 5.353 | 97.4 | −1.0507 |
| read_n03 | 3 | 5.356 | 97.5 | −1.0507 |
| read_n05 | 5 | 5.353 | 97.4 | −1.0507 |
| read_n10 | 10 | 5.353 | 97.4 | −1.0507 |
| read_n20 | 20 | 5.353 | 97.4 | −1.0507 |

**Key observation:** ΔVth is constant at ~97.4 mV regardless of pulse count. Polarization is identical to 11 significant digits across P1, P5, P10, P20.

### 4B.3 Root Cause: $\tau_E$ << Pulse Width

**The problem:** $\tau_E$ = 1 ns (domain switching time), pulse width = 100 ns → ratio = 100:1.

**What happens physically:**
1. Pulse 1 arrives (VGS=2V). The electric field across HZO drives polarization toward the equilibrium value for that field strength.
2. Because $\tau_E$ (1 ns) is 100× shorter than the pulse duration (100 ns), polarization **fully equilibrates** within the first ~5 ns of the pulse.
3. For the remaining 95 ns, polarization sits at steady state — no further switching occurs.
4. When VGS returns to 0V, polarization relaxes to whatever state corresponds to zero gate bias.
5. Pulse 2 arrives at the same VGS=2V → drives P to the **exact same equilibrium** → no additional switching.

**In biological terms:** It's like a neuron whose membrane capacitor charges fully on the first input spike and then can't accumulate any further — each subsequent spike sees the capacitor already charged to the maximum for that input voltage.

### 4B.4 The Fix: Increase $\tau_E$

For cumulative integration, each pulse must only **partially** switch the domains, leaving room for subsequent pulses to continue the switching process. This requires $\tau_E$ >> pulse width:

| $\tau_E$ | pw/$\tau_E$ | Switching per pulse | Pulses for 90% total | Assessment |
|----------|------------|--------------------|-----------------------|------------|
| 1 ns (old) | 100 | 100% (saturated) | 1 | ❌ No integration |
| 100 ns | 1.0 | ~63% | ~2-3 | ❌ Too fast, saturates quickly |
| 500 ns | 0.2 | ~18% | ~11 | ⚠️ Borderline |
| **1 µs** | **0.1** | **~10%** | **~22** | **✅ Good for 20-pulse staircase** |
| 5 µs | 0.02 | ~2% | ~115 | ⚠️ Very slow, may need many pulses |

**Selected: $\tau_E$ = 1 µs (1e-6 s)**. Updated in `sdevice_gaafet_lif.par`.

### 4B.5 Impact on SimA Results

SimA was run with $\tau_E$ = 1 ns. Those results (Section 4A) demonstrated that **different Vpulse values produce different equilibrium polarization states** — this is valid and physically meaningful. It confirmed sub-coercive operation and voltage-dependent switching.

However, with $\tau_E$ = 1 µs, SimA results will change: each 100ns pulse will only achieve ~10% of the equilibrium shift. The ΔVth values will be smaller but the voltage-dependent trend will remain. **SimA should be re-run after the tau_E fix** to get corrected ΔVth values for the new parameter set.

### 4B.6 Corrected Workflow (After tau_E Fix)

1. **Re-run SimA** with $\tau_E$ = 1 µs → get new ΔVth(Vpulse) curve (smaller values expected)
2. **Re-run SimB** with $\tau_E$ = 1 µs → expect cumulative Vth(N) staircase
3. **Run SimC** with $\tau_E$ = 1 µs + $\tau_P$ > 0 → observe leak between pulses + reset
4. Extract all parameters for Step 2 circuit model

### 4B.7 Plots

See `Simulations/py_scripts/`:
- `simB_fig1_idvgs_overlay.png` — All intermediate reads overlap (no integration)
- `simB_fig2_dvth_vs_N.png` — Flat red line (measured) vs expected blue staircase
- `simB_fig3_pol_vs_pulse.png` — Constant polarization across all pulses

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
