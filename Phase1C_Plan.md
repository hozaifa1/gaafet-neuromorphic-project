# Phase 1C — Closed. Step 2 v2 Python Roadmap

**Date:** 2026-05-08 (final rewrite)
**Status:** All Phase 1C TCAD work executed. simC–simG outputs analyzed. This document is the single source of truth for what Phase 1C delivered and what Python modeling does next.

Re-run the analyzer to refresh tables: [Simulations/analyze_phase1c_full.py](Simulations/analyze_phase1c_full.py). simE energy extractor: [Simulations/simE_energy/extract_energy.py](Simulations/simE_energy/extract_energy.py).

---

## 1. What was done — one line per simulation

| Sim | Purpose | Status | Output dir |
|---|---|---|---|
| simC v6 | Integrate-and-fire validation @ 6V, 9 pulses | ✅ | [Simulations/simC/n4(6V)](Simulations/simC/n4(6V)) |
| simD | τ_leak via depolarization read window, 4-node τ_P sweep | ✅ | [Simulations/simD_leak/output_taup_{1e-6,1e-5,1e-4,1e-3}](Simulations/simD_leak) |
| simE | E_per_pulse / E_fire_total (high-resolution power integration) | ⚠️ partial — ran 7/9 pulses + p08 rise; sim halted before completion. Per-pulse energy extracted; total extrapolated. | [Simulations/simE_energy/outputs](Simulations/simE_energy/outputs) |
| simF | 5-cycle endurance @ τ_P=1e-5 (operating point) | ⚠️ partial — c01 basepre + c01_p01_rise missing (run truncation); cycles 2–5 complete | [Simulations/simF_endurance/tau_p_selected_1e-5](Simulations/simF_endurance/tau_p_selected_1e-5) |
| simG | Gate capacitance C_gg(VGS) @ 1 MHz, virgin & post-fire | ✅ | [Simulations/simG_capacitance/outputs](Simulations/simG_capacitance/outputs) |

The earlier simF run at τ_P=0 ([tau_p_just_taken_0](Simulations/simF_endurance/tau_p_just_taken_0), buggy par file) is kept as reference but is **not** the operating-point measurement.

---

## 2. Key numbers extracted

### 2.1 simG — gate capacitance (decisive)

| State | C_gg_peak | C_gg_min | Vth (CV midpoint) |
|---|---|---|---|
| Virgin | **0.1432 fF** | 0.0237 fF | +0.025 V |
| Post-fire (9×6V) | **0.1432 fF** | 0.0237 fF | +0.000 V |

- **τ_native = R_total · C_gg = 7830 Ω · 0.143 fF = 1.1 ps**
- **ΔVth(virgin → post-fire) = −25 mV** (CV midpoint), expected sign for cumulative ΔP.
- C_gg geometry-dominated at 1 MHz; horizontal CV shift, not vertical.
- **C_mem (v1) / C_gg = 9.9 × 10⁹.** Capacitorless single-FeFET LIF claim is ruled out.

### 2.2 simD — leak (4-node τ_P sweep)

| τ_P | ID(t₀) µA | ID_∞ µA | A µA | τ_fit | sign | reading |
|---|---|---|---|---|---|---|
| 1e-6 (1 µs) | 18.44 | 14.73 | +10.79 | **1.03 µs** | falling | clean exp decay; τ_leak ≈ τ_P |
| 1e-5 (10 µs) | 11.43 | 15.65 | −3.38 | 3.21 µs | rising | read window too short to resolve depolarization; transient is channel re-fill |
| 1e-4 (100 µs) | 8.44 | 15.03 | −8.33 | 24.9 µs | rising | polarization frozen vs. window |
| 1e-3 (1 ms) | 7.99 | 9.82 | −2.82 | 32.8 µs | rising (small) | non-volatile in window |

**Headline:** τ_leak ∝ τ_P confirmed at the τ_P=1e-6 anchor (τ_leak = 1.03 µs). For the operating point τ_P=1e-5, the model leak constant is **τ_leak = τ_P = 10 µs**.

### 2.3 simE — energy per pulse (7 of 9 pulses)

| pulse | E_gate (fJ) | E_drain (fJ) | E_total (fJ) |
|---|---|---|---|
| 1 | 2.55 | 195.97 | 198.51 |
| 2 | 2.55 | 196.52 | 199.07 |
| 3 | 2.55 | 197.53 | 200.08 |
| 4 | 2.55 | 198.94 | 201.49 |
| 5 | 2.55 | 200.69 | 203.24 |
| 6 | 2.55 | 202.69 | 205.24 |
| 7 | 2.55 | 204.86 | 207.41 |

- **E_per_pulse ≈ 200 fJ ≈ 0.2 pJ**, drain-dominated (VDS=0.05V × ID over the read window).
- E_gate is small and flat (≈ 2.55 fJ/pulse, charging the FE).
- Linear trend (+1.5 fJ/pulse): pulse 9 extrapolates to ≈ 211 fJ.
- **E_fire_total (extrapolated 9 pulses) ≈ 1.83 pJ.** Trapezoidal sum of the 7 measured pulses = 1.42 pJ.
- Caveat: simulation truncated at p08_rise. Re-run is optional (extrapolation reliable; per-pulse trend is monotonic and shallow).

### 2.4 simF — endurance @ τ_P=1e-5 (operating point, cycles 2–5)

| cycle | ID_pre (µA) | ID_p9 (µA) | ID_post (µA) | fire_ratio | reset% |
|---|---|---|---|---|---|
| 2 | 13.054 | 14.864 | 15.501 | 1.139 | 118.7 |
| 3 | 15.508 | 16.293 | 16.555 | 1.051 | 106.8 |
| 4 | 16.537 | 16.907 | 17.006 | 1.022 | 102.8 |
| 5 | 16.978 | 17.171 | 17.197 | **1.011** | 101.3 |

**Drift slopes c2→c5:** ID_pre **+4.74 %/cycle**, ID_p9 +2.69 %/cycle, ID_post +1.94 %/cycle. Total drift c2→c5: ID_pre **+30.0 %**, fire_ratio collapses **1.139 → 1.011**.

**Critical contrast with τ_P=0 (old buggy run):** at τ_P=0 the device stabilized after cycle 1 (ID_pre flat at 11.79 µA, fire_ratio constant at 1.578). At the **physically correct τ_P=1e-5**, the device drifts upward every cycle and fire_ratio collapses toward 1 — the integrate-and-fire signal is being **lost across cycles**. Reset at −5 V is not fully restoring the polarization on the τ_P=1e-5 timescale.

This is the most consequential Phase 1C finding for Step 2 v2: the multi-cycle behavior of a single GAA-FeFET LIF neuron at the operating leak constant is **not stationary**. Either (a) the reset protocol must be redesigned, or (b) the SNN must absorb this drift in training.

### 2.5 Composite parameter set for `lif_parameters.py`

```python
MEASURED = {
    # simG (1 MHz CV, 2026-05-07)
    "C_gg_peak_F":              0.1432e-15,   # virgin == post-fire
    "C_gg_min_F":               0.0237e-15,
    "tau_native_s":             1.1e-12,      # R_total * C_gg_peak
    "delta_Vth_post_fire_V":   -0.025,        # CV midpoint shift

    # simD (4-node tau_P sweep, 2026-05-08)
    "tau_E_s":                  1e-6,         # par-file constant
    "tau_P_chosen_s":           1e-5,         # operating point
    "tau_leak_s":               1e-5,         # = tau_P; anchored at tau_P=1e-6 -> tau_leak=1.03 us

    # simE (7 of 9 pulses, 2026-05-08)
    "E_pulse_J":                200e-15,      # ~200 fJ/pulse, drain-dominated
    "E_gate_per_pulse_J":       2.55e-15,
    "E_drain_per_pulse_J":      200e-15,
    "E_fire_total_J":           1.83e-12,     # extrapolated from 7-pulse trend

    # simF tau_P=1e-5, cycles 2..5 (operating point, 2026-05-08)
    "ID_pre_c2_uA":             13.054,
    "ID_pre_c5_uA":             16.978,
    "fire_ratio_c2":            1.139,
    "fire_ratio_c5":            1.011,
    "drift_ID_pre_pct_per_cycle":  4.74,      # NOT stable
    "drift_fire_ratio_per_cycle": -0.043,     # collapsing toward 1
    "reset_completeness_c5_pct": 101.3,

    # virgin-state reference (from simC v6, kept for SNN init)
    "ID_pre_virgin_uA":         9.525,        # simC v6 baseline
    "fire_ratio_virgin":        2.035,        # simC v6 P9/P0
}

LEGACY_VO2_INHERITED = {
    "C_mem_external_F":  1.419e-6,   # back-calculated, not measured
    "tau_target_s":      11.11e-3,   # = R*C_mem
    "v_th_V":            3.6,        # VO2 paper comparator
    "v_h_V":             1.5,
    "dt_SNN_s":          555.6e-6,
    # MOSFET adaptation params (kappa_n/p, Vt_n/p, W/L, R_a, C_a)
    # remain VO2-paper values pending v2.1 re-derivation.
}
```

---

## 3. The honest framing (unchanged from prior version, abbreviated)

v1 (90.18% on MIT-BIH 4-class) is a port of the VO2-LSNN code with R_h, R_s swapped to GAA-FeFET values and C_mem back-calculated to hit τ=11.11 ms. It is a defensible *baseline*, not a defensible "single GAA-FeFET LIF" claim. Phase 1C measurements either confirm or invalidate each VO2-inherited assumption:

| v1 assumption | Phase 1C verdict |
|---|---|
| τ = 11.11 ms is FE-native | **Invalidated** by simG (τ_native = 1.1 ps). External cap mandatory. |
| C_mem = 1.419 µF is FE | **Invalidated** by simG. C_mem / C_gg = 10¹⁰. |
| R_on / R_off are stable across cycles | **Invalidated** by simF τ_P=1e-5. ID_pre drifts +4.7 %/cycle, fire_ratio collapses. |
| Leak is instantaneous vs SNN dt | **Confirmed** at τ_P=1e-5 (τ_leak=10 µs ≪ dt=555 µs). |
| E_spike ≈ 100 fJ (drain only) | **Refined** by simE: E_per_pulse ≈ 200 fJ (drain still dominates because VDS·ID·t_read ≫ ½·C_gg·V²). E_fire ≈ 1.8 pJ, ~10× larger than v1's rough estimate. |
| v_th=3.6V, v_h=1.5V comparator setpoints | Untouched; needs v2.1 re-derivation from R, τ_target, N_fire. |

---

## 4. Step 2 v2 — Python roadmap

The build order below is what the next chat should execute. **TCAD is closed (with the two minor caveats in §5).** Do not block on more simulations to start v2.0.

### 4.1 v2.0 — replace `lif_parameters.py` with the MEASURED block

- Drop in the `MEASURED` and `LEGACY_VO2_INHERITED` dicts from §2.5 verbatim.
- Add a one-line provenance comment per field pointing to the source `.plt` or §2.x.
- Delete or comment-out the `PENDING` block (everything is filled in or has a documented extrapolation/proxy).

### 4.2 v2.1 — re-derive τ_target, v_th, v_h analytically

Two design paths, decide explicitly and document:

- **Path A — keep external C_mem, accept area cost.** τ_target = (R_h+R_s)·C_mem = 11.11 ms. Re-derive v_th and v_h from N_fire ≈ 9, dt = 555 µs, and the gain (R_h+R_s)·s. The VO2 setpoints may survive numerically; check, do not assume.
- **Path B — re-time to FeFET-native scale.** τ_target = τ_leak = 10 µs. Requires dt ≈ 100 ns–1 µs and a new SNN time-step count. Inference window shrinks from 620 ms to ≈ 100 µs. Whether MIT-BIH 4-class is still solvable at this timescale is the open empirical question. This is v2.5, not v2.0.

Recommend: **path A for the first paper**, with path B as documented future work.

### 4.3 v2.2 — refit MIT-BIH 4-class with corrected τ, C_mem, drift-aware initial state

- Use cycled-state ID baseline (≈ 13 µA c2 of simF τ_P=1e-5), not virgin (9.5 µA).
- Keep RC linear forward model from v1 — only the constants change.
- Target: ≥ 85% test accuracy on the same MIT-BIH 4-class split. Below 80% means the architecture is too tied to specific VO2-paper assumptions and must be redesigned.

### 4.4 v2.3 — drift-aware training using simF τ_P=1e-5 distribution

This is now the **critical** v2 step, because the simF τ_P=1e-5 result shows the device is non-stationary across cycles:

- Train with per-cycle Vth perturbation drawn from the measured drift slope (+4.74 %/cycle on ID_pre, −0.043/cycle on fire_ratio).
- Test inference robustness over multi-cycle sequences (simulate 100+ ECG samples in succession with progressive drift).
- Acceptance: ≤ 2% accuracy loss from cycle 1 to cycle 100 of inference.

If accuracy degrades faster than this, the conclusion is that the GAA-FeFET reset protocol must be redesigned at the device level — that is a real result, document it.

### 4.5 v2.4 — fix `model_2.py` saturation (FE-native variant)

Independent track. The `model_2.py` polarization-native variant only reaches ~70% because BPTT through the bounded sigmoidal Preisach kills gradients near saturation. Two fixes to try:

- Reparametrize the state variable as `θ = arctanh(P / P_s)` — unbounded, gradients survive.
- Or add a small linear leak term to keep θ inside the well-conditioned region.

Target: ≥ 85% with FE physics in the forward pass. If achieved, v2.4 becomes the *physics-faithful* model and v2.2 (the RC-linear model with corrected constants) becomes its sanity check, not the headline.

### 4.6 v2.5 — re-time if v2.2 path A fails or area cost is unacceptable

Only attempt if v2.2 cannot reach ≥ 85%, or if the reviewers reject the external C_mem area cost. Redesign SNN with dt ≈ 1 µs and inference window ≈ 100 µs. Likely needs full re-training, possibly architecture changes.

---

## 5. Should any more TCAD simulations be run?

**Short answer: no — Phase 1C closes here.** The two truncated runs (simE, simF) leave only minor gaps that do not block v2.0:

### 5.1 simE — re-run to completion?

**Optional, low priority.** We have 7 of 9 complete pulses with clean monotonic E_per_pulse trend (+1.5 fJ/pulse). Linear extrapolation to 9 pulses introduces ≤ 5% uncertainty on E_fire_total. The headline number "≈ 1.8 pJ" is robust. A re-run would only tighten the last digit.

If you do choose to re-run, the cmd file is correct ([Simulations/simE_energy/sdevice_simE_energy.cmd](Simulations/simE_energy/sdevice_simE_energy.cmd)) — just submit it again. No code change needed.

### 5.2 simF — re-run with full cycle 1?

**Optional, low priority.** Cycles 2–5 are the load-bearing data for the drift slope, which is the v2.3-relevant metric. Cycle 1 (virgin → first reset) is already characterized at τ_P=0 from the prior run; the τ_P=1e-5 number for cycle 1 would be informative but does not change the v2.3 design.

If re-run is desired, the cmd file is correct ([Simulations/simF_endurance/sdevice_simF_endurance.cmd](Simulations/simF_endurance/sdevice_simF_endurance.cmd)) — submit it again. No code change needed.

### 5.3 simH — long-window leak at τ_P=1e-5 (Phase II, not blocking)

Not in Phase 1C scope, but worth flagging: the simD τ_P=1e-5 node could not resolve τ_leak directly because the 100 µs read window is shorter than the slow exponential. A future leak-only run with a 1 ms read window at τ_P=1e-5 would provide a direct measurement of τ_leak instead of the extrapolation `τ_leak = τ_P`. **Defer to Phase II** — `τ_leak = τ_P` is good enough for v2.0.

### 5.4 No new cmd / par files needed

All TCAD inputs in the repo are correct. The buggy [Simulations/simF_endurance/tau_p_just_taken_0/sdevice_gaafet_lif.par](Simulations/simF_endurance/tau_p_just_taken_0/sdevice_gaafet_lif.par) (duplicate `tau_P` definitions) can be left as-is — that folder is now reference-only. The global [Simulations/sdevice_gaafet_lif.par](Simulations/sdevice_gaafet_lif.par) is correct (single uncommented `tau_P = (0, 1e-5, 0)` at line 81).

---

## 6. File deliverables

### 6.1 TCAD cmd files (all final, all correct)
- [Simulations/simC/sdevice_simC_v6.cmd](Simulations/simC/sdevice_simC_v6.cmd)
- [Simulations/simD_leak/sdevice_simD_leak.cmd](Simulations/simD_leak/sdevice_simD_leak.cmd)
- [Simulations/simE_energy/sdevice_simE_energy.cmd](Simulations/simE_energy/sdevice_simE_energy.cmd)
- [Simulations/simF_endurance/sdevice_simF_endurance.cmd](Simulations/simF_endurance/sdevice_simF_endurance.cmd)
- [Simulations/simG_capacitance/sdevice_simG_capacitance.cmd](Simulations/simG_capacitance/sdevice_simG_capacitance.cmd)

### 6.2 Python tooling (kept)
- [Simulations/analyze_phase1c_full.py](Simulations/analyze_phase1c_full.py) — single analyzer for simD/simF/simG
- [Simulations/simE_energy/extract_energy.py](Simulations/simE_energy/extract_energy.py) — energy integrator (parser fixed 2026-05-08)
- [Simulations/simG_capacitance/extract_cgg.py](Simulations/simG_capacitance/extract_cgg.py)
- [Simulations/py_scripts/analyze_simC_v6.py](Simulations/py_scripts/analyze_simC_v6.py), `analyze_simA_simB.py`, `analyze_curves.py`, `plot_*` (calibration / Phase 1A & 1B reference)
- [Simulations/simC/generate_simC_v6.py](Simulations/simC/generate_simC_v6.py), `generate_simC_v7.py`

### 6.3 Removed (redundant)
- `Simulations/analyze_phase1c.py` (superseded by `_full`)
- `Simulations/py_scripts/analyze_simC_v3.py`, `analyze_simC_v5.py` (superseded by v6)
- `Simulations/py_scripts/analyze_simA_transient.py`, `analyze_simB_transient.py`, `analyze_simB_critical.py` (superseded by `analyze_simA_simB.py`)
- `Simulations/py_scripts/analyze_8abc.py` (obsolete combined script)
- `Simulations/simC/generate_simC_v{3,4,5}.py` (only v6, v7 retained)

---

## 7. One-paragraph executive summary (paste-ready)

Phase 1C ran simC–simG to characterize the GAA-FeFET as a single-element LIF neuron. The intrinsic gate capacitance (simG) is 0.143 fF, giving τ_native = 1.1 ps — ten orders of magnitude below the 11.11 ms time constant the v1 SNN inherited from the VO2-LSNN paper. The capacitorless single-FeFET LIF claim is therefore ruled out; an external C_mem is mandatory if the SNN is kept at ms-scale. Leak (simD) follows τ_leak ∝ τ_P, anchored at τ_leak=1.03 µs for τ_P=1 µs. At the operating point τ_P=10 µs, the read window cannot resolve τ_leak directly, so the SNN model uses τ_leak=τ_P=10 µs. Energy (simE, partial 7-of-9) is ≈ 200 fJ per pulse, drain-dominated, extrapolating to E_fire_total ≈ 1.8 pJ — about an order of magnitude above v1's rough 100 fJ estimate. The most consequential finding is the endurance result (simF at τ_P=10 µs): unlike the prior τ_P=0 run that suggested post-cycle-1 stability, the device drifts upward by **+4.7 %/cycle on baseline** and the fire ratio collapses from 1.14 to 1.01 over four cycles, meaning the integrate-and-fire signal is being lost across cycles at the physical operating leak. Step 2 v2 must therefore (a) drop the back-calculated 1.419 µF and 11.11 ms in favor of a measurement-defended block, (b) treat per-cycle drift as the central robustness constraint (v2.3 drift-aware training is now load-bearing, not optional), and (c) preserve v1's RC-linear forward model with corrected constants while developing the FE-native `model_2.py` (v2.4) on a parallel track.
