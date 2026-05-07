# Phase 1C — Closing the Remaining TCAD Gaps & Step 2 v2 Roadmap

**Date:** 2026-05-03 (updated 2026-05-07)
**Status:** Phase 1B complete. Phase 1C **partially complete**: simG (capacitance) and simF (endurance) measured; simD (leak) one node done (τ_P=1e-6), three nodes remaining; simE (energy) pending. Step 2 v1 achieves 90.18% test accuracy on MIT-BIH 4-class (303/336).

This document is the single source of truth for what TCAD work is still owed and what the Python side should do next. It supersedes the "next steps" sections in `Step_2_Circuit_Integration.md` and `simC_analysis_summary.md`.

---

## 0. The honest framing — read this first

The 90.18% v1 result is not a clean GAA-FeFET demonstration. It is a port of the published **VO2-memristor LSNN code** (Yin et al., NCOMMS 2023) in which:

1. R_h and R_s were swapped from VO2 values to GAA-FeFET values (5250 Ω and 2580 Ω from simC v6).
2. The MOSFET adaptation circuit parameters (κ_n, κ_p, Vtn, Vtp, W/L_n, W/L_p, R_a, C_a) were **kept as the VO2-paper values** — they describe a peripheral CMOS process, not our GAA technology.
3. C_mem = 1.419 µF was **back-calculated** to make τ = R_h+R_s × C_mem = 11.11 ms — the same time-constant the VO2 paper used. This is a knob the author turned, not a measurement.
4. Comparator setpoints v_th = 3.6 V and v_h = 1.5 V are **circuit-design choices from the VO2 paper**, kept verbatim.
5. The forward model (linear RC integrate-and-fire) does not include any FeFET-specific physics — it is the same form the VO2 paper used.

So: the v1 number says "if you reduce a GAA-FeFET to its on/off resistance pair and plug it into the VO2 paper's exact LSNN, you get 90.18%". It does **not** say:
- the FeFET's intrinsic capacitance is large enough to support τ = 11.11 ms (very likely it isn't — see simG below),
- the leak time-constant of the FE depolarisation matches the leak the VO2 model assumes,
- the per-cycle drift of partial polarization switching survives 1116 SNN time-steps without accuracy loss,
- the energy advantage versus VO2 actually exists (we have a back-of-envelope estimate, not a measurement),
- the CMOS adaptation circuit numbers carry over to whatever process the GAA-FeFET will actually be co-integrated in.

Phase 1C exists to replace those assumptions with measurements, **before** Step 2 v2 is rebuilt from the ground up against numbers we trust. The v1 result remains useful as a sanity check ("if all our assumptions held, accuracy is at least 90%"), not as a publication-grade claim.

---

## 1. State of play (what is known, what is shaky)

### 1.1 Achieved — defended by data

| Item | Source | Result |
|---|---|---|
| Calibration | Run 16 | Vth=0.263V, Ion=604µA, MW=0.681V, SS=60.8 mV/dec |
| Sub-coercive integration | simA transient | ΔVth 7.4–26.4 mV across 1–3V Vpulse |
| Multi-pulse staircase | simB transient | ΔVth 0→227 mV over 20 pulses (Vpulse=2V) |
| Gradual integration → fire | simC v6 (6V node) | Fire at P9, ratio 2.035× |
| Reset capability | simC v6 (Vreset=−5V) | 77.2% reset on 6V node |
| Step 2 SNN v1 | `main_ecg_6/7.py` | 90.18% on MIT-BIH 4-class, beats VO2 baseline (89.58%) |
| **C_gg (virgin, 1 MHz)** | **simG** | **0.143 fF peak (143 aF); min 0.024 fF; τ_native = 1.1 ps** |
| **C_gg (post-fire, 1 MHz)** | **simG** | **0.143 fF peak; Vth shift virgin→post-fire ≈ 25 mV** |
| **τ_leak (τ_P=1e-6 node)** | **simD partial** | **802.6 ns (0.80 µs); ID drops 19.11→14.02 µA over 100 µs** |
| **Multi-cycle endurance** | **simF (τ_P=1e-6)** | **Cycle 1 fire_ratio=2.01→stabilises at 1.578 c2–c5; drift <0.5%/cycle after break-in** |

### 1.2 Open issues — currently unsupported assertions

| Issue | Why it matters | Current state |
|---|---|---|
| **τ_leak** | Sets neuron leak time-constant in any physics-faithful SNN. | simD τ_P=1e-6 node: τ_leak = **802.6 ns** (fitted from 201-point leak_monitor). Three remaining τ_P nodes (1e-5, 1e-4, 1e-3) still needed to map τ_P → τ_leak over the full range. `lif_parameters.py PENDING.tau_leak` not yet populated — awaiting τ_P sweep completion. |
| **E_spike** | Headline energy claim of the thesis. | `lif_parameters.py PENDING.E_spike = 97e-15` (rough); simE ran infinitely — cmd needs a rewrite (separate task). |
| **Endurance / drift** | Residual P per cycle could integrate into systematic Vth shift over 1116-step inference. | **MEASURED** (simF, τ_P=1e-6): one-cycle break-in (virgin→post-cycle-1 ID_pre shifts 9.53→11.67 µA), then stable. Cycles 2–5: drift <0.5%/cycle on all metrics. Reset completeness 99.2%. **Drift concern is resolved at τ_P=1e-6.** Needs re-confirmation with the correct τ_P once simD sweep is done. |
| **C_gg (gate capacitance)** | Determines whether "capacitorless LIF neuron" claim is defensible. | **MEASURED** (simG): C_gg_peak = **0.143 fF (143 aF)**. τ_native = R_total × C_gg = 7830 Ω × 0.143 fF = **1.1 ps**. C_mem required = 1.419 µF / 0.143 fF = **~10¹⁰ × intrinsic cap**. Capacitorless claim is **not defensible**. |

### 1.3 Why these four, and only these four

These are the parameters the project-guide (`.windsurf/rules/project-guide.md`) and `Step_2_Circuit_Integration.md` §2.2 explicitly list as needed for the device-to-system mapping. Everything else (R_on/R_off, dVth/pulse, N_fire, fire ratio, reset %, MW, SS, Vth_virgin) is already in `lif_parameters.py` with a defensible source. Adding more (multi-domain Preisach sweep, AFE variant, asymmetric stack) is Phase II and is out of scope until Phase 1C closes.

---

## 2. Critical evaluation of the Step 2 v1 model

### 2.1 What v1 actually models

From `ecg_gaafefet_2.pdf` §4–5 and `ecg_gaafefet_simplified.pdf`:

```
v_{t+1} = exp(-dt/τ) v_t + (1 - exp(-dt/τ)) (R_h + R_s) s x_t       (LIF eq.1)
spike   = Heaviside((v - v_th)/v_th),  v_th = 3.6 V
reset   = v ← v_h = 1.5 V                                            (hard reset)
```

with `R_h = R_off = 5250 Ω`, `R_s = R_on = 2580 Ω`, `C_mem = 1.419 µF` (external), `τ = 11.11 ms`, `s = 9.9e-3 V/A`, `dt = 0.5556 ms`. ALIF variant adds a CMOS adaptation circuit driven by κ_n/κ_p/Vtn/Vtp parameters.

### 2.2 What v1 hides

| Hidden simplification | Honest status |
|---|---|
| FeFET = 2-state resistor | Step 2 v1 reuses only the on/off resistance pair from the device — not the FE switching kinetics, not the partial-switching staircase, not the leak. |
| C_mem is external 1.419 µF | The single-FeFET neuron has no such cap — the FE layer is supposed to *be* the cap. This was a design choice for BPTT trainability; v1 is therefore an *FeFET-modulated CMOS LIF*, not a pure FeFET LIF. |
| dt = 555 µs vs pw = 100 ns | The SNN time-step is 5500× slower than the pulse, so the integration time constant from the pulse-level dynamics never enters the model. Each SNN time-step is "many pulses in aggregate." |
| `model_2.py` (polarization-native) only reaches ~70% | BPTT through the bounded sigmoidal Preisach saturation kills gradients near 0 and 1. This is the real reason v1 abstracts. |
| τ_leak placeholder | Doesn't matter for v1 because the C-set time constant is τ=R·C, not the FE depolarization. But this means v1's τ tells us *nothing* about whether the FeFET can actually leak that fast on its own. |

### 2.3 What v1 still validates

- The **two-state resistance memory window** is real and characterized.
- The integration depth (N_fire=9) and dVth/pulse are consistent with the network's effective receptive field (1116 SNN steps × N_avg pulses per step).
- The gain `(R_h + R_s)·s ≈ 77.5` and τ=11.11 ms are derived numbers; if R values shift in a redesigned device, the model rescales without retraining.

**Verdict:** v1 is a defensible *first* publication of a GAA-FeFET-based ECG SNN. It is not a defensible claim that "a single GAA-FeFET acts as a complete LIF neuron". To make the latter claim, Step 2 v2 is needed (see §5).

---

## 3. Next-step decisions: simulation side (Phase 1C deliverables)

### 3.1 Decision tree

```
 Phase 1C
  ├── simD: Leak characterization (τ_P > 0)               ─── HIGHEST priority
  │   └── outputs τ_leak in seconds → goes into PENDING.tau_leak
  ├── simE: Energy per spike (high-resolution power)      ─── HIGH priority (paper claim)
  │   └── outputs E_pulse, E_fire_total in J
  ├── simF: Multi-cycle endurance (5 cycles)              ─── MEDIUM priority
  │   └── outputs ΔVth_drift_per_cycle, residual_P_drift
  └── simG: Capacitance C_gg (AC small-signal)            ─── HIGH priority
       └── outputs C_gg(VGS) curves @ virgin and @ post-fire states
```

### 3.2 simD — leak characterization

**Status (2026-05-07):** τ_P=1e-6 node **DONE**. τ_leak = 802.6 ns (0.80 µs) fitted from ID(t) decay over 100 µs window (201 data points, ID: 19.11 µA → 14.02 µA, A = 7.45 µA). Cmd file had a bug (reset_rise/reset_fall had InitialTime=FinalTime); fixed 2026-05-07 — add 1 ns duration to each ramp, shift subsequent times by 1 ns. **Remaining:** run nodes τ_P=1e-5, 1e-4, 1e-3 with the fixed cmd; do NOT re-run τ_P=1e-6. Output directory: `simD_leak/output_taup_1e-6/`.

**Goal.** Replace `tau_leak = None` with a measured value by re-running the v6 protocol with τ_P > 0 and observing the controlled FE relaxation in the long gap.

**Design.**
1. Run baseline read (100 ns at VGS_read=0.20 V).
2. Apply 9 pulses at Vpulse=6V (the established "fire-just-reached" condition).
3. **Long monitoring window:** 100 µs at VGS_read with dense (200-point) sampling. With τ_P from 1 µs to 100 µs, the polarization decays exponentially and ID(t) follows; fitting `ID(t) = ID_∞ + (ID_fire − ID_∞) exp(−t/τ_leak)` extracts τ_leak. 100 µs is ≥ 10×τ_P at the slowest case, ≥ 100×τ_P at the fastest — covers the full decay.
4. Apply reset and read.

**Sweep.** τ_P is in `sdevice_gaafet_lif.par` Polarization block. Sweep manually over 4 nodes:
- τ_P = 1e-6 s (fast leak, τ_P = τ_E)
- τ_P = 1e-5 s (moderate — the **default in current par file**)
- τ_P = 1e-4 s (slow leak)
- τ_P = 1e-3 s (very slow)

Each requires editing the .par file before SWB run; or use SWB to sweep `@tauP@` if the par file is parameterised. We follow the existing project pattern (manual edit per run).

**Output.** Fit τ_leak from each run's `leak_monitor_*.plt`. Plot ID(t) decay vs τ_P; populate `PENDING.tau_leak` with the value matching SimC v6's observed 20% drop in 5 µs ≈ τ_P ≈ 22 µs (rough sanity check).

**Files:** `Simulations/simD_leak/generate_simD_leak.py` → `sdevice_simD_leak.cmd`.

### 3.3 simE — energy per spike

**Goal.** Replace the `E_spike = 97 fJ` rough estimate with `E_spike = ∫_t (V_g·I_g + V_d·I_d) dt` over the full fire transient.

**Design.**
1. Run baseline read.
2. Apply 9 pulses at 6V — same as v6, but with `Intervals=100` (10× denser sampling) on the rise/write/fall segments to resolve the gate-charging current spike accurately.
3. Stop after P9 (fire reached) — no extra pulses, no leak gap, no reset. The reduction relative to v6 keeps the file small and the dense sampling tractable.
4. Each `pXX_*.plt` file contains time-resolved `gate_contact OuterVoltage`, `gate_contact TotalCurrent`, `drain_contact OuterVoltage`, `drain_contact TotalCurrent`. Trapezoidal integration in Python yields per-pulse energy, summed gives total fire energy.

**Numeric expectation.** From cap-divider `V_HZO ≈ 1.73 V` at Vpulse=6V and rough gate cap ~ ε₀ ε_HZO A / t_HZO, expect E_pulse ~ pJ. Drain energy at VDS=0.05V is a few orders smaller. Total fire energy should be in the **pJ range, not fJ** — the 97 fJ estimate was based on drain energy alone, ignoring the dominant gate-charging energy.

**Files:** `Simulations/simE_energy/generate_simE_energy.py` → `sdevice_simE_energy.cmd`. Post-processor: `Simulations/simE_energy/extract_energy.py`.

### 3.4 simF — multi-cycle endurance

**Status (2026-05-07): COMPLETE** (at τ_P=1e-6; re-run warranted after simD sweep identifies correct τ_P).

| Cycle | ID_pre (µA) | ID_p9 (µA) | ID_post (µA) | fire_ratio |
|---|---|---|---|---|
| 1 (virgin) | 9.525 | 19.174 | 11.570 | **2.013** |
| 2 | 11.675 | 18.764 | 11.789 | 1.607 |
| 3 | 11.886 | 18.762 | 11.790 | 1.579 |
| 4 | 11.887 | 18.762 | 11.790 | 1.578 |
| 5 | 11.887 | 18.762 | 11.790 | **1.578** |

Drift slopes (c2–c5, after break-in): ID_pre +0.000%/cycle, ID_p9 −0.000%/cycle (flat to 4 significant figures). Reset completeness c5 = ID_post/ID_pre = 99.2%. **Interpretation:** one-cycle virgin→cycled break-in; thereafter device locks to a new stable operating point with zero measurable drift. The previously-feared 22.8% residual P drift is not manifesting as progressive degradation — cycles 2–5 are identical. Fire ratio drops from 2.01 (virgin) → 1.578 (post-break-in), which is the metric to track for SNN accuracy.

**Python modeling implication:** No per-cycle drift regularisation needed in v2.3 (drift is below 0.5%/cycle after cycle 1). Instead, model the one-time break-in offset: effective R_on and R_off in the cycled state differ from the virgin state values used in v1. Specifically, ID_pre shifts from 9.53 µA (virgin) to 11.79 µA (cycled), so the effective "resting" conductance is ~24% higher than the virgin-state value in `lif_parameters.py`. v2.0 should use the cycled-state values, not virgin.

**Goal.** Quantify drift in baseline read, fire ratio, and reset completeness across N integrate-fire-reset cycles.

**Design.**
- 5 full cycles. Each cycle: 9 write pulses at 6V → reset at −5V → 100 ns post-reset read.
- Total simulation time ≈ 5 × (9·202 ns + 1.002 µs + 100 ns) ≈ 19 µs.
- Use τ_P from the simD-extracted "real" value (or τ_P=1e-5 default if simD pending).

**Why 5 cycles, not 100?** Each cycle generates ~30 .plt segments. 5 cycles = ~150 segments — comparable to v6's 30-pulse scan. Extending to 100 cycles is computationally heavy on a single TCAD run; 5 is enough to extrapolate a per-cycle drift slope, which is the metric needed.

**Output.** Per-cycle table of (ID_baseline_pre, ID_fire@P9, ID_postreset, Py_postreset). Slopes vs cycle index quantify drift.

**Files:** `Simulations/simF_endurance/generate_simF_endurance.py` → `sdevice_simF_endurance.cmd`.

### 3.5 simG — gate capacitance C_gg

**Status (2026-05-07): COMPLETE.**

| State | C_gg_peak | C_gg_min | Vth proxy (max dC/dV) |
|---|---|---|---|
| Virgin | **0.1432 fF (143.2 aF)** | 0.0237 fF | −0.025 V |
| Post-fire (9×6V pulses) | **0.1432 fF (143.2 aF)** | 0.0237 fF | −0.050 V |

Key derived numbers:
- **τ_native = R_total × C_gg_peak = 7830 Ω × 0.143 fF = 1.1 ps** (eleven orders below v1's 11.11 ms)
- **C_mem / C_gg_peak = 9.91 × 10⁹** (v1's external capacitor is 10 billion times the intrinsic cap)
- Vth shift virgin → post-fire from CV midpoint: ≈ 25 mV (expected direction; consistent with 9-pulse programming)
- ΔC_gg peak (post-fire − virgin) ≈ 0 fF — no measurable change in peak capacitance. This is expected: the FE polarisation changes the inversion charge, not the geometric gate-oxide capacitance dominant at 1 MHz. The CV curve shifts horizontally (Vth shift), not vertically.

**Python modeling implication:** The "capacitorless single-FeFET LIF neuron" claim is **definitively ruled out by measurement**. τ_native ≈ 1 ps means any membrane integration time longer than a few nanoseconds requires an external capacitor. For v2, two paths:
- **(a) Accept external C_mem, quote area cost**: a 1.419 µF cap in standard CMOS (e.g., MIM at 10 fF/µm²) occupies ~0.14 mm² — significant but quotable. v2 is an FeFET-modulated CMOS LIF, not FeFET-only.
- **(b) Re-time to FeFET-native scale**: operate the SNN with dt ≈ 1 ns, inference window ≈ 1–10 µs. Requires redesign of the ECG classification front-end (not just re-training). This is v2.5.
The paper should use path (a) as the primary result and acknowledge path (b) as future work.

**Goal.** Measure the FeFET's intrinsic gate capacitance to determine whether the SNN's externally-imposed C_mem = 1.419 µF is physically defensible, or whether v2 must use a different (smaller, FeFET-only) C.

**Design.** AC small-signal sweep on top of a slow VGS ramp, following the official pattern in `Sentaurus/.../CMOS_180nm/CV_des.cmd` (System block + Vsource_pset for the gate, ACCoupled inside Quasistationary).
- Frequency: 1 MHz (standard CV test condition).
- VGS sweep: −1 V to +1 V (covers virgin Vth and post-fire Vth).
- Two pre-conditions: (a) virgin state (no pulses); (b) post-fire state (after 9 pulses at 6V).

**Numeric expectation.** With AreaFactor=0.071, channel L≈12 nm, W_eff per nanosheet ≈ 15 nm, n_sheets=3, t_HZO=10 nm, ε_HZO=33: estimated C_gg ≈ 33·ε₀·(area)/t_HZO ≈ a few **fF** (femto-Farad). Compare to the SNN's required C_mem=1.419 µF: nine orders of magnitude apart. This is the central question: the natural FeFET-only τ would be R_eff · C_gg ≈ 7830 Ω × 5 fF = 39 ps, *not* 11 ms. The Step 2 v1 time constant is therefore not natively achievable by the FeFET alone — confirming v1 is FeFET-modulated, not FeFET-only.

**Implication for the paper.** Either (a) acknowledge external C_mem is required and quote the area cost of including it, or (b) redesign v2 to operate at the natural FeFET timescale (sub-µs) by retiming the SNN — a much faster network that still solves ECG by relying on the FeFET's intrinsic dynamics.

**Files:** `Simulations/simG_capacitance/generate_simG_capacitance.py` → `sdevice_simG_capacitance.cmd`. Post-processor: `Simulations/simG_capacitance/extract_cgg.py`.

---

## 5. Step 2 v2 — the Python roadmap (rebuild against measured numbers)

The v2 path is **TCAD first, Python rebuild second, iterate**. v1 is preserved as a baseline reference but is not the foundation v2 builds on. The new numbers from Phase 1C will likely invalidate several v1 design choices, and that's expected.

### 5.1 What v1 inherited from the VO2 paper that must be re-examined

Each item below is something v1 took as a given. Each must be checked against Phase 1C measurements before v2 keeps it.

| v1 inherited choice | Source in v1 | What Phase 1C shows |
|---|---|---|
| τ = 11.11 ms | back-calculation in v1 | **MEASURED (simG):** τ_native = 1.1 ps. 11.11 ms is unphysical without external C_mem — confirmed. |
| C_mem = 1.419 µF (external) | knob picked to hit 11.11 ms | **MEASURED (simG):** External cap is required. C_mem / C_gg = ~10¹⁰. If targeting 11.11 ms, external cap dominates completely; FeFET contributes no meaningful capacitance. For v2: explicitly label C_mem as "external CMOS capacitor" rather than FE membrane cap. |
| v_th = 3.6 V, v_h = 1.5 V | comparator design from VO2 paper | Still inherited from VO2; not yet re-derived. Once τ is re-chosen (and dt restructured for v2.5), these must be re-derived from (R_h+R_s), τ_target, and N_fire ≈ 9. |
| R_h and R_s as the only device features | v1 model | **MEASURED (simF):** R_on/R_off are stable after one break-in cycle. Effective ID_pre (resting) is 11.79 µA (cycled) vs 9.53 µA (virgin) — v2.0 must use cycled-state resistance values, not virgin. simE still pending for gate-charging energy. |
| MOSFET adaptation params (κ, V_t, W/L, R_a, C_a) | VO2-paper CMOS process | Unchanged — still VO2-paper CMOS numbers. v2 must drop the ALIF branch or replace these with GAA co-integration process parameters. |
| Linear RC forward model | VO2-paper LSNN | **MEASURED (simD partial):** τ_leak = 802.6 ns at τ_P=1e-6. The RC model's 11.11 ms τ is externally imposed; actual FE leak is ~4 orders faster. For v2: if using external C_mem, the RC model holds but τ is set by R·C_mem, not the FE. FE-native model (v2.4) must use τ_leak from the τ_P sweep as the decay timescale. |
| dt = 555 µs SNN time-step | VO2-paper inheritance | **CONFIRMED problematic (simG):** τ_native = 1.1 ps, so at dt=555 µs the FeFET integrates nothing natively. The SNN time-step is 5×10⁸ × τ_native. v2.5 (re-timing) is the correct fix if the external-C approach is rejected. |

### 5.2 What we must measure first (TCAD), then decide (Python)

**Sequence:**

1. **Run simG (capacitance) — decides almost everything.** ✅ DONE (2026-05-07)
   - **Result:** C_gg_peak = 0.143 fF → τ_native = 1.1 ps. Branch taken: *C_gg is sub-fF → τ_native is ps-scale → v1's 11.11 ms is unphysical without external cap.* v2 must accept and quote the area cost of an external cap (path a) OR re-time the SNN to ps/ns timescales (v2.5, path b).

2. **Run simD (leak) at the τ_P sweep — fixes the leak time-constant.** 🔄 IN PROGRESS
   - τ_P=1e-6 node done: τ_leak = 802.6 ns. **Three nodes remaining (1e-5, 1e-4, 1e-3). Run with the fixed cmd (reset_rise/fall bug fixed).**
   - Decision awaiting: which τ_P is physically appropriate for HZO? Literature suggests µs–ms range. The sweep result will populate `PENDING.tau_leak` in `lif_parameters.py`.
   - Note: at τ_leak=802 ns, τ_leak ≪ SNN dt=555 µs by 3 orders. So for v1's time-step, the FE leak is instantaneous relative to dt. This is consistent with v1 not modelling it explicitly, but means the FE cannot hold polarisation state across a single SNN step without external C.

3. **Run simE (energy) — anchors the energy claim.** ⚠️ BLOCKED
   - simE ran infinitely (2+ hours). Root cause unknown (likely infinite-loop in time-step adaptation). Needs cmd rewrite before re-running. Separate task.
   - Estimate: E_pulse ~ ½ · C_gg · V² = ½ × 0.143e-15 × 6² ≈ **2.6 aJ per gate-charging event**. This is even smaller than the original 97 fJ drain estimate — because C_gg is ~100× smaller than estimated. The dominant energy is now expected to be leakage current through the HZO during the pulse, not capacitive charging. simE is still needed for the honest measurement.

4. **Run simF (endurance) — quantifies the drift.** ✅ DONE (provisional, τ_P=1e-6)
   - **Result:** Zero drift after cycle-1 break-in. No v2.3 drift regularisation needed. Re-run with correct τ_P once simD sweep completes, but result unlikely to change qualitatively.

5. **Then rebuild Python.** The sequence is now clear enough to begin v2.0 without waiting for all simD nodes.

### 5.3 v2 build order

**v2.0 — replace `lif_parameters.py` with measured numbers.**
- Plug in: τ_leak (simD), E_spike per pulse (simE), C_gg(virgin) and C_gg(post-fire) (simG), per-cycle drift slope (simF).
- Drop placeholders. Add a `MEASURED` block; relegate the back-calculated 1.419 µF and the VO2-paper comparator setpoints to a `LEGACY_VO2_INHERITED` block clearly marked as not-yet-validated for the GAA-FeFET.

**v2.1 — re-derive the time-constant the model uses.**
- Compute τ_target as min(τ_leak, R_total·C_gg, dt × N_pulses_per_step). If this is ms-scale, no external cap needed; if ns-scale, re-time the SNN.
- Re-decide v_th and v_h analytically from the new τ_target, the SS=60.8 mV/dec characteristic, and the desired N_fire ≈ 9. Don't carry the VO2 numbers forward.

**v2.2 — reproduce v1's 90.18% with the corrected parameters.**
- This is a sanity check. If the corrected τ and C_mem still give ≥ 88% on the same MIT-BIH split, the architecture port survives the parameter rebuild.
- If accuracy drops below 80%, the architecture itself is too tied to VO2-paper-specific assumptions and must be redesigned (likely smaller hidden layer, different recurrence depth, no DelayedLinear) — accept that as a real outcome.

**v2.3 — drift-aware training using simF data.**
- Add a per-cycle Vth perturbation drawn from the measured drift distribution as a training-time noise. Test the model's robustness over multiple inferences (simulated drift across many ECG samples in sequence).

**v2.4 — fix `model_2.py`'s saturation.** The native-polarization variant only reached ~70% because BPTT through the bounded sigmoidal Preisach kills gradients at the saturation boundaries. Fix:
- Reparametrise: state variable `θ = arctanh(P / P_s)` is unbounded; gradients don't vanish.
- Or: add a small linear leak term to keep θ inside the well-conditioned region.
- Target: ≥ 85% with FE physics in the forward pass. Achievable since the MIT-BIH 4-class task is not the bottleneck; the optimisation pathology is.

**v2.5 — re-time if simG demands it.** If C_gg is fF-scale and an external C is rejected as unphysical for the "single-FeFET LIF" claim, redesign the SNN to operate on a sub-µs total inference window with ns-scale dt. Retraining may be needed; the dataset is small enough to make this tractable.

**v2.6 — multi-iteration loop.** v2.0 → v2.5 is one pass. Expect to revisit:
- v2.0 if simF reveals drift that the regulariser in v2.3 can't absorb without accuracy loss > 2%.
- v2.4 if the reparametrisation works on ECG but fails on a harder dataset (say MNIST or NMNIST), suggesting the FE-native model has narrower applicability than the RC abstraction.
- v2.5 if re-timing breaks ALIF (the adaptation circuit timescale is set by R_a·C_a from CMOS, not the FeFET).

### 5.4 What the Python codebase needs in tooling, not just modelling

- A unified `run_v2.py` that takes a `params.json` (the measured Phase 1C numbers) and produces a model — replaces the hard-coded constants in `main_ecg_6_polished.py` and `main_ecg_7_resume.py`.
- A `compare_v1_v2.py` that runs both and produces a side-by-side accuracy + energy + drift-survival report. This is the document that will appear in the paper as "Why we chose v2".
- Unit tests on the LIF dynamics: e.g. assert that with no input, v decays from v_th to v_h with measured τ_leak; assert that with constant input matching v1's drive, v1 and v2 agree to within 1% on the first few time-steps.

### 5.5 Decision: should we publish v1?

Recommendation: **do not** publish v1 as a standalone GAA-FeFET claim. The 90.18% number depends on inherited VO2 parameters that we have not validated. v1 is acceptable as a **bench-mark reference** within the v2 paper ("the prior approach, mechanically ported, would give 90.18% if its inherited assumptions held; here is what changes when we measure the device honestly").

If a Phase-1B-only paper is needed earlier (e.g. for a conference), it should be a **device paper** (calibration + simC v6 fire demonstration + Phase 1C measurements) without an SNN deployment claim. The SNN deployment becomes the second paper, after v2 is rebuilt and benchmarked against v1.

---

## 6. Files delivered with this plan

### 6.1 Documentation
- `Phase1C_Plan.md` (this file)
- `Step_2_Circuit_Integration.md` (updated §9 with v1 results from PDFs)

### 6.2 TCAD generators + cmd files
- `Simulations/simD_leak/generate_simD_leak.py` → `sdevice_simD_leak.cmd`
- `Simulations/simE_energy/generate_simE_energy.py` → `sdevice_simE_energy.cmd`
- `Simulations/simF_endurance/generate_simF_endurance.py` → `sdevice_simF_endurance.cmd`
- `Simulations/simG_capacitance/generate_simG_capacitance.py` → `sdevice_simG_capacitance.cmd`

### 6.3 Post-processors (Python)
- `Simulations/simE_energy/extract_energy.py`
- `Simulations/simG_capacitance/extract_cgg.py`

### 6.4 Parameter file changes
- `Simulations/sdevice_gaafet_lif.par`: τ_P sweep instructions already present in the comments. Set τ_P to the desired value before each simD run.

---

## 7. Run order on the Sentaurus server, then on the Python side

### 7.1 TCAD (Sentaurus, in this order)

1. **simG (capacitance)** first — fastest (~5 min), gives the most decisive number (C_gg in fF), and decides whether v2 even needs to revisit τ.
2. **simD (leak)** next — sets τ_leak honestly. Run 4 nodes (τ_P = 1e-6, 1e-5, 1e-4, 1e-3) by editing `sdevice_gaafet_lif.par` between runs (or via SWB `@tauP@` if you parameterise it).
3. **simE (energy)** in parallel with simD — independent, just denser sampling. Post-process with `extract_energy.py`.
4. **simF (endurance)** last — uses τ_P from simD result. Set τ_P in `.par` to the simD-fitted value before running.

Total wall-clock estimate on a single Sentaurus thread: simG ~5 min, simD ~20 min × 4 = 80 min, simE ~15 min, simF ~25 min. Total ≈ 2 hours sequential, ~30 min if parallelised across SWB nodes.

### 7.2 Python (in this order, only after §7.1 completes)

1. **Update `lif_parameters.py`** with the Phase 1C measurements (new `MEASURED` block; old v1 numbers move to `LEGACY_VO2_INHERITED`).
2. **v2.0 — re-derive τ, v_th, v_h** analytically from the new numbers. Don't keep VO2 setpoints unless the math says they survive.
3. **v2.2 — refit MIT-BIH 4-class** with the corrected forward model (still RC, but with measured τ, C, and dropping or rebuilding the ALIF branch). Compare to v1's 90.18%. **If <80%, accept the architecture must be rebuilt** — that is a real result, not a failure.
4. **v2.3 — drift training** using simF distribution.
5. **v2.4 — FE-native model** (`model_2.py` reparametrisation). Independent branch; do not abandon v2.2 path.
6. **Iterate** v2.0 ↔ v2.4 as new measurements come in or as v2 reveals where the architecture is over-fit to VO2 paper assumptions.

### 7.3 What success looks like at the end of Phase 1C + v2

- Every device-side number in `lif_parameters.py` has a TCAD source (a .plt or .acplt file path) instead of a placeholder or back-calculation.
- The Python forward model has no constant inherited from the VO2 paper that we cannot independently justify for our process.
- The accuracy figure quoted in the paper is one of: (a) v2.2 result with measured τ if it stays ≥ 85% , or (b) v2.4 result if v2.2 drops too far. Either way, the headline is **a number we earned**, not a number borrowed.
