# Spiking Simulation Debugging Log (Compressed)
**Date Range:** Jan 23 – Mar 23, 2026

## 1. Original Goal
Demonstrate LIF spiking in GAA-FeFET using Impact Ionization (Bhatawdekar paper approach). All runs used `Simulations/sdevice_des.cmd` and `sdevice_gaafet_lif.par`.

---

## 2. Solver Issues (Runs Pre-1 through Pre-6) — RESOLVED

**Problem:** Transient simulation stuck in infinite loop, time step collapsed to ~1e-22s.

**6 failed attempts** targeted solver controls (LTE, ErrRef, tolerances). None worked because the root cause was physics parameters, not solver settings.

### Root Cause 1: Missing `tau_E` in Preisach Model
- `Polarization` keyword without `tau_E` defaults to instantaneous P-E response (tau=0)
- Creates infinitely stiff system — no timescale for solver
- **Fix:** Added `tau_E = (0, 1e-9, 0)` to HZO section in `.par` file
- Official FeFET_CAM example uses `tau_E = 1e-9`

### Root Cause 2: Normalized Step Sizes in Transient+Goal
- When `Transient` has a `Goal`, step sizes are **normalized fractions (0-1)**, NOT absolute seconds
- `InitialStep=1e-11` with `FinalTime=10e-9` → effective step = 1e-19s (0.1 attoseconds)
- Without `Goal`, step sizes ARE absolute seconds
- Calibration was invisible because `FinalTime=1s` made fractions = absolute values
- **Fix:** Rise phase (with Goal): `InitialStep=1e-3`, `MaxStep=5e-2`. Hold phase: removed Goal, absolute steps.

---

## 3. Biasing & Operating Point Runs (Runs 1-8)

### Run 1 (VGS=1.2V): Strong inversion, ID=391μA, flat. **Misstep:** Way above Vth.
### Run 2 (VGS=0.3V): ID=67.5μA, flat. **Misstep:** Still too high, wrong bias order.
### Run 3 (Gate first, then drain pulsed): ID=68μA, flat. **Discovery:** Need negative source bias per paper.
### Run 4 (VS=-0.25V, VD=0V): ID=46μA at t=0. **Discovery:** VD must equal VS initially (VDS=0).
### Run 5 (VS=VD=-0.25V, VG=0.05V): ID starts at 0A ✅ but jumps to 73μA. **Discovery:** VGS must use virgin FE state calibration, not hysteresis-swept data.

### Run 6 (VGS=-0.32V): ID=74pA. Too deep in subthreshold. II negligible.
### Run 7b (VGS=-0.20V): ID=6.95nA. **II first detected:** source holes=65fA, M=9.35e-6. But saturated — no spiking.

**SS extraction (Run 6 + 7b):** SS = 60.8 mV/dec (Boltzmann limit). Used to calculate target VGS.

### Run 8 (VGS=-0.11V, target 200nA): ID=183nA ✅ but **M collapsed to 4.99e-8** (530× weaker than Run 7b).
- **Paradox:** Higher VGS pulls body potential up → reduces drain-body reverse bias → E-field drops → II collapses exponentially
- Source hole current = 9.15 fA (entirely from Band2Band tunneling, not II)

---

## 4. d0 Parameter Sweep (Runs 8a/8b/8c) — FAILED

| Run | d0_e | d0_h | Result |
|---|---|---|---|
| 8a | 7.1e5 | 2.08e6 | **Byte-identical to 8b/8c** |
| 8b | 5e5 | 5e5 | **Byte-identical** (MD5: 5CFC848B...) |
| 8c | 1e5 | 1e5 | **Byte-identical** |

d0 swept 7× with zero effect. The drain junction field (F_ava) is so far below the critical field that α≈0 for ANY d0 value. The 9.15 fA hole current comes from Hurkx BTBT, not II.

---

## 5. Conclusions

### Why Impact Ionization Cannot Work in Our GAA-FeFET
1. GAA geometry provides excellent gate coupling → screens drain field from body
2. HZO layer adds capacitive voltage divider → further reduces field at drain junction
3. At any VGS that gives ~200nA channel current, the body potential is too high for reverse bias
4. F_ava << critical field → α ≈ 0 → no avalanche generation regardless of d0

### Critical Missing Step
**Output characteristics (ID-VDS) were never run.** The paper verified kink effect (II signature) in DC output curves BEFORE transient spiking. We went directly from hysteresis calibration to transient — skipping the fundamental prerequisite.

### Calibration Gaps (vs Paper Methodology)
- ❌ Full ID-VGS curve shape matching (only 2 points matched)
- ❌ Output characteristics (ID-VDS) — kink never verified
- ❌ SS/DIBL verification during calibration
- ❌ Velocity saturation, S/D resistance, contact resistance calibration
- ❌ Workfunction: paper 4.6eV vs ours 4.35eV (0.25eV gap)

### Valid Lessons Retained
- Biasing order: gate FIRST, then drain pulsed
- Initial VDS must be 0V (VD = VS)
- Negative source bias required (VS = -0.25V)
- Transient+Goal = normalized steps; Transient without Goal = absolute steps
- tau_E required for Preisach model transient stability
- Virgin FE state ≠ hysteresis-swept state for VGS lookup

---

## 6. Paradigm Shift: Abandon Impact Ionization

**Literature review (Mar 23, 2026) revealed:** FeFET-based LIF neurons in the literature do NOT use Impact Ionization. They use **ferroelectric polarization switching** as the spiking mechanism:

- **Frontiers (2020):** 28nm FeFET — sub-coercive gate pulses gradually switch FE domains → Vth shifts → abrupt ID change = "fire"
- **Nature Comms (2022):** AFeFET — polarization/depolarization of Hf0.2Zr0.8O2 = integrate/leak, 37 fJ/spike
- **Khanday (2024):** DG-FE-TFET — tunneling + FE gate, 0.58 aJ/spike, no II

**The Bhatawdekar paper uses a standard GAA FET (no FE layer).** Their II mechanism is incompatible with FeFET gate stacks. Our device should use the FE polarization dynamics that it already has.

### New Approach: Polarization-Based LIF
1. **Integrate:** Sub-coercive gate pulses partially switch FE domains → Vth decreases gradually
2. **Leak:** Domain relaxation (tau_P, depolarization) → Vth drifts back
3. **Fire:** When enough domains switch, Vth < operating VGS → ID spikes abruptly
4. **Reset:** Negative gate pulse resets polarization → Vth returns to high state

Our device already has everything needed: HZO with Preisach model, tau_E, calibrated hysteresis.

---

## 7. Phase 1A Implementation: SWB-Based Characterization (Mar 23, 2026)

### New Workflow: Three Focused Simulations

Instead of one monolithic `sdevice_des.cmd` with commented sweeps, created **three optimized `.cmd` files** for Sentaurus Workbench (SWB) parameter sweeping:

#### **Sim A: Single Pulse Amplitude** (`sdevice_phase1a_simA.cmd`)
- Sweeps `@Vpulse@` = 1.0, 1.5, 2.0, 2.5, 3.0 V (5 runs)
- Measures ΔVth per amplitude → finds optimal pulse for partial switching
- Extracts partial P-E loop from Polarization(y) CurrentPlot

#### **Sim B: Multi-Pulse Integration** (`sdevice_phase1a_simB.cmd`)
- Applies N identical pulses (N=1,3,5,10,20) with best Vpulse from Sim A
- Demonstrates cumulative Vth shift = "integration" behavior
- Extracts Vth(N) staircase curve

#### **Sim C: Full LIF Cycle** (`sdevice_phase1a_simC.cmd`)
- 5 pulses with 1μs gaps (observe leak), then reset pulse
- Sweeps `@Vreset@` = -2.0, -3.0, -4.0 V (3 runs)
- Demonstrates integrate → leak → fire → reset in one run
- Extracts ID vs time waveform + reset completeness

### Progressive Sweep Strategy

**Total: ~12–15 runs instead of 100+**
1. Sim A (5 runs) → pick best Vpulse
2. Sim B (1 run) → confirm integration
3. Sim C (3 runs) → sweep Vreset
4. tau_P manual (3–4 runs) → characterize leak time constant
5. tau_E manual (2–3 runs, optional) → validate switching speed

Each run: 5–15 min. Total time: ~2–3 hours.

### Expected Outputs Table

| Sim | Parameter | Extract | Desired Output | Paper | Purpose |
|---|---|---|---|---|---|
| A | Vpulse | baseline vs postpulse ID-VGS | ΔVth vs Vpulse curve | Frontiers 2020 Fig.3 | Find optimal amplitude |
| A | Vpulse | pulse_hold Polarization(y) | Partial P-E loop | HZO modeling | Confirm sub-coercive |
| B | Npulses | postpulse_fwd Vth | Vth(N) staircase | Frontiers 2020 Fig.5 | Demonstrate integration |
| B | — | pN_hold ID segments | Stepwise ID increase | AFeFET Nature Comms | Show cumulative switching |
| C | Vreset | Full lif_* ID vs time | LIF waveform | Khanday DG-FE-TFET Fig.7 | Full cycle demo |
| C | Vreset | postreset vs baseline Vth | Vth recovery | AFeFET paper | Quantify reset |
| C | — | lif_gap* Polarization(y) | P decay during gaps | HZO modeling | Demonstrate leak |
| .par | tau_P | Re-run simC, gap decay | Leak time constant τ_m | AFeFET paper | Map to Python SNN |
| .par | tau_E | Re-run simA, P settling | Switching speed | FeFET_CAM | Validate insensitivity |

### SWB Setup (Brief)

**Sim A:** Add sdevice tool → cmd=`sdevice_phase1a_simA.cmd` → parameter `Vpulse` sweep `1.0 1.5 2.0 2.5 3.0` → run 5 nodes

**Sim B:** Add sdevice tool → cmd=`sdevice_phase1a_simB.cmd` → parameter `Vpulse`=(best from A) → run 1 node

**Sim C:** Add sdevice tool → cmd=`sdevice_phase1a_simC.cmd` → parameters `Vpulse`=(from A), `Vreset` sweep `-2.0 -3.0 -4.0` → run 3 nodes

**tau_P:** Edit `.par` → change `tau_P` to `(0, 1e-6, 0)` → re-run Sim C (1 node) → repeat for `1e-5`, `1e-4`

**tau_E (optional):** Edit `.par` → change `tau_E` to `1e-10` or `1e-8` → re-run Sim A (1 node)

See `Step_1_FET_Parameter_Optimization.md` Section 4 for full details.

---

## 8. Sim A Results (Apr 2026) — SUCCESS

### Outcome
All 5 Vpulse nodes (1.0–3.0V) completed successfully. Partial polarization switching confirmed with monotonic ΔVth increase.

### Data Summary

| Vpulse | ΔVth (mV) | Pol/y end (μC/cm²) | E/F_c (%) | P/P_r (%) |
|--------|-----------|---------------------|-----------|-----------|
| 1.0V | ~26 | −0.260 | 5.6 | 1.6 |
| 1.5V | ~63 | −0.641 | 13.0 | 4.0 |
| 2.0V | ~99 | −1.051 | 20.1 | 6.6 |
| 2.5V | ~131 | −1.484 | 26.8 | 9.3 |
| 3.0V | ~160 | −1.938 | 33.2 | 12.1 |

### Key Finding: Read Disturb
The 0→1V Quasistationary readout sweep evolves Pol/y during measurement. For n3 (1V pulse), the postpulse P state converges to baseline at VGS=1V (full erasure). For n7 (3V pulse), the state persists. **Sim B must reduce readout range to 0→0.3V.**

### Decision
**Vpulse = 2.0V selected for Sim B** — 99 mV/pulse, 20% of F_c, 6.6% of P_r, large headroom for cumulative integration.

### Next Steps
1. ~~Apply Sim B adjustments~~ ✅
2. ~~Run Sim B~~ ✅
3. ~~Extract Vth(N) staircase~~ ✅ → **FLAT LINE (no integration)**

---

## 9. Sim B Results (Apr 2026) — NO INTEGRATION (Diagnosed)

### Outcome
20 pulses at Vpulse=2.0V. All intermediate reads (N=1,3,5,10,20) show identical ΔVth ≈ 97.4 mV and Pol/y = −1.0507 µC/cm². No cumulative staircase.

### Root Cause
**τ_E (1 ns) << pulse width (100 ns).** Polarization fully equilibrates to the 2V steady-state within ~5 ns of pulse 1. Subsequent pulses find P already at equilibrium → zero additional switching. Identical to a capacitor that charges fully on the first pulse.

### Fix Applied
Changed `tau_E` in `.par` file: **1 ns → 1 µs (1e-6 s)**. This gives pw/τ_E = 0.1 → each pulse switches ~10% of remaining P → cumulative staircase over 20 pulses.

Also updated SimC `.cmd`: FEPolarizationIP=1.0, Digits=5, Iterations=50, readout sweep 0→0.3V.

### Corrected Workflow
1. Re-run SimA with τ_E = 1µs (ΔVth values will be smaller, trend preserved)
2. Re-run SimB with τ_E = 1µs (expect Vth staircase)
3. Run SimC with τ_E = 1µs + τ_P > 0 (leak + reset)
4. Extract Step 2 circuit parameters
