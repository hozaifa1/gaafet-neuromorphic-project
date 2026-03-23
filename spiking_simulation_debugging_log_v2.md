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

Our device already has everything needed: HZO with Preisach model, tau_E, calibrated hysteresis. See `Step_1_FET_Parameter_Optimization.md` for the new workflow.
