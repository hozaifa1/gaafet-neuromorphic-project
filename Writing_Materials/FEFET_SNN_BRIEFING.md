# FeFET SNN — Python Modelling Briefing (single source of truth)

**Goal:** ECG-arrhythmia classification (MIT-BIH 4-class N / F / SVEB / VEB) on a spiking neural network whose LIF dynamics are grounded in the **measured** Phase 1D GAA-FeFET response — not back-ported from the VO2 LSNN paper (`ecg_gaafefet_2.pdf`).

> **Current best result (as of v8d_pure_ce):** 76.49 % test accuracy on MIT-BIH 4-class.
> **Target for top-tier publication:** ≥ 85 % under H4-measured drift and jitter, at 637 fJ per LIF cycle (H9 N=5 lock).
> **Gap:** 8–9 percentage points. This document explains why the gap exists, what's wrong with the current code, and what to change.

---

## PART A — Audit of the actual Python code (current state)

### A.1 File inventory and verdict

| File | Lines | Verdict |
|---|---|---|
| `gaafefet_params (1).py` | 139 | **Stale — Phase 1C / SimC v6 operating point. Rewrite required.** |
| `surrogate (1).py` | 46 | Keep. Standard `ScaledPiecewiseQuadratic` (Bellec-LSNN family). Cite Neftci 2019. |
| `utils (1).py` | 54 | Keep. `absId` MOSFET model + raster plot helper. |
| `vo2_encoder (1).py` | 53 | **Rename + decouple.** It's a generic LC delta-modulator, not VO2-specific. |
| `model_2 (1).py` | 398 | **Keep architecture, fix physics constants and reset law.** |
| `dataset (1).py` | 176 | Keep ECG path; remove EEG; parameterise dataset path. |
| `main_ecg_8c_warmup (1).py` | 371 | **Delete the KD branch.** v8c confirmed KD destroys the FeFET student. |
| `main_ecg_8d_pure_ce_resume (1).py` | 291 | **Promote to canonical training entrypoint.** Pure CE is the right recipe. |

The duplicated `(1).py` suffix in every filename indicates these were re-attached via the file-picker — please rename to drop the suffix.

---

### A.2 `gaafefet_params.py` — stale by an entire phase

The file is anchored to **Phase 1C / SimC v6**. Phase 1D explicitly invalidated those numbers:

| Field | Current value | Phase 1D ground truth | Reason it must change |
|---|---|---|---|
| `Vpulse_optimal` | 6.0 V | **2.0 V** | H1 v3: V_pgm = 6 V drives non-monotonic over-switching (ID collapses at p6→p9) |
| `VGS_read` | +0.20 V (above V_t) | **−0.5 V** (sub-V_t) | H1 v3: sub-V_t exponential sensitivity is the LIF read modality |
| `N_fire` | 9 | **5** | **H9 lock — saves 44.8 % cycle energy** |
| `fire_ratio` | 2.035× (Phase 1C P9) | **3.04×** (H9 c3..c5 mean at N=5) | H4/H9 |
| `SS` | 60.8 mV/dec | post-PGM 100, post-ERS 164 mV/dec | H0a v5 (M10 with documented MFIS asymmetry) |
| `MW` | 0.681 V | **1.40 V** (10 µs writes) | H0a v5 (2.8× Tasneem differentiator) |
| `Vth_virgin` | 0.263 V | **V_t post-ERS = +0.16 V; V_t post-PGM = −1.24 V** | H0a v5 |
| `reset_completeness` | 77.2 % | **rest = +1.44× virgin (NOT restore-to-virgin)** | H3 Step 3b; M-rest drift ≈ 0 %/cyc |
| `tau_leak` | None (PENDING) | **τ_P = 10 µs (par); τ_relax = 13.7 µs (H3 fit)** | Phase 1C simD + Phase 1D H3 Step 2c |
| `E_spike` | 97 fJ (ROUGH) | **129.3 fJ/pulse, FE-switching floor** | H5/H6/H9 |

**Why this matters:** the model itself in `model_2.py` doesn't actually import these constants — they're decorative. So the staleness is "only" a documentation defect *for now*, but the moment a reviewer compares the published params against the device characterisation, every line of `gaafefet_params.py` is a discrepancy. **Rewrite this file from §B below.**

---

### A.3 `model_2.py` — the LIF kernel: solid skeleton, wrong dials

**The skeleton is fine.** `FeFETLIFNeuron` implements a Preisach-like saturating switching kinetic:

```
P_decayed = exp(-dt/tau_leak) · P
drive     = K_switch · sigmoid((V_FE - Vc) / V_scale)
P_new     = P_decayed + (1 − P_decayed) · drive       # bounded growth toward 1
self.v    = P_new                                      # P is the state variable
```

This is physically defensible (a continuous Preisach soft-saturation law) and the surrogate-gradient backward path is standard. But the **constants are wrong and the reset law is wrong**:

| Knob | Code default | What Phase 1D says |
|---|---|---|
| `Vc` | 1.2 V | **1.2 V** ✓ (matches H0e gate coercive voltage) |
| `V_max` | 7.0 V | **2.4 V** (H12 highest analog rung; never need >2.4 V in LIF) |
| `K_switch` | 0.10 | **fit from H9 per-pulse trajectory** — currently a free hyperparameter |
| `V_scale` | 0.5 V | **fit from H0a v5 SS** — should be ≈ kT/q × SS_decades_per_volt |
| `tau_leak` (model) | 50 ms | **OK as SNN-time leak**, but please document it is not τ_P=10 µs (the FE leak) — these live in different time domains |
| `reset_completeness` | 0.772 | **0.0** (M-rest rests at +1.44× virgin, not at 0). Replace multiplicative reset with **additive rest-state offset**. |
| `weight_to_Vpulse_slope` | 1.0–1.15 | re-derive from H1 v3 mapping (synapse weight ↔ V_pgm in 1.2–2.4 V window) |
| `P_threshold` (v_threshold) | 0.45–0.5 | **set so that crossing corresponds to fire_ratio ≥ 1.5×** (H9 M2 gate) |

**The reset law is the most consequential physics bug.** H3 Step 3b found the device does **not** return toward virgin after the erase + 70 µs relax — it settles at +1.44× virgin baseline, **stably**, with M-rest drift ≈ 0 %/cyc (H4). The biological analogue is a refractory floor above resting, not a hard reset. The current code does:

```python
self.v = self.v * (1.0 - spike_d * self.reset_completeness)   # multiplicative collapse
```

This drags P toward 0 on every spike — wrong direction, wrong dynamics. Replace with:

```python
self.v = torch.where(spike_d > 0, self.rest_offset, self.v)   # snap to rest baseline on fire
# rest_offset ≈ 0.20  (calibrated so that ID(rest_offset) ≈ 1.44 × ID_virgin per H3 Step 3b)
```

Then add a slow inter-cycle drift sample from H4 (+0.015 %/cyc on ID_p_last, ≈ 0 %/cyc on rest):

```python
self.v = self.v * (1.0 + drift_per_cycle * torch.randn_like(self.v) * 0.5)   # bounded jitter
```

---

### A.4 `main_ecg_8c_warmup.py` — KD branch must die

The v8d header documents the empirical finding:

> Phase 1 (pure CE, no KD, no SR) reached **76.49 %** at epoch 5 — best ever for the polarization-physics model.
> Phase 2+3 (with KD) catastrophically collapsed the network to 50.89 %.
> Diagnosis: KD pushes the polarization student to match RC-teacher representations that are physically incompatible.

This is correct, and is itself a publishable methodological observation: *RC-derived teachers cannot distil into polarization-physics students because their hidden-state geometries differ.* But for paper #1, **delete the KD code path entirely**. v8d (pure CE, no KD) is the canonical recipe; v8c is now archival.

---

### A.5 `vo2_encoder.py` — generic LC delta-modulator mislabelled

This file is a Level-Crossing (LC) delta-modulator: it takes a continuous ECG voltage and emits up/down spike events when the derivative crosses ±V_th/(β·factor). The V_th = 3.4 V, R_off = 14 kΩ are VO2 device parameters from the source paper, but **the circuit is a generic comparator — nothing here is VO2-specific.**

Two clean options:
- **(a) rename to `lc_encoder.py`, parameterise thresholds**, ship it as the standard LC front-end (citing the original VO2 paper as the source of the recipe). This is the low-risk path.
- **(b) replace with a FeFET-native charge-domain encoder** that uses the H12 7-level analog-synapse to do the level crossing on-device. This would be a publishable result on its own ("the same FeFET does the front-end ADC and the LIF") but is a paper-grade project, not a refactor.

Recommendation: **(a) for paper #1**, document (b) as future work.

---

### A.6 `dataset.py` — fine, with caveats

- Loads pre-encoded `up_*_guiyi.csv` / `down_*_guiyi.csv` files from the VO2-paper's preprocessing pipeline. Adds a 120-sample cue. 4-class ECG-AAMI split (N / F / SVEB / VEB). 1664 train / 336 test by seed-100 split.
- Hard-coded Windows absolute dataset path in `main_ecg_8*.py`. Parameterise via env var or CLI arg.
- `DeltaTransformedEEG` is dead code in the ECG pipeline — remove or split to a separate module.
- The "delta encoding" upstream is from the VO2 paper. **The encoded files are not in this repo.** Confirm they exist and version-pin the preprocessing script (it is not currently versioned with this code).

---

### A.7 `surrogate.py` + `utils.py` — keep as-is

`ScaledPiecewiseQuadratic` with α=1, γ=0.3 is a standard surrogate (Neftci 2019 *Surrogate Gradient Learning in Spiking Neural Networks*, IEEE SPM). Cite. `absId` is a textbook MOSFET saturation/linear model used by the ALIF adaptation circuit — fine.

---

## PART B — The canonical parameter set (rewrite `gaafefet_params.py` from this)

### B.1 Device physics — H0a v5 + H0e

| Parameter | Value | Source |
|---|---|---|
| V_t post-ERS | +0.16 V | H0a v5 |
| V_t post-PGM | −1.24 V | H0a v5 |
| Memory window (10 µs writes) | 1.40 V (2.8× Tasneem) | H0a v5 |
| SS post-PGM | 100 mV/dec | H0a v5 |
| SS post-ERS | 164 mV/dec (MFIS asymmetry) | H0a v5 |
| Gate coercive voltage V_c,gate | 1.2 V | H0e |
| Coercive field F_c | 1.2 MV/cm | H0e |
| AreaFactor | 0.071 | H0g |
| Effective gate width W_eff | 90 nm | H0g |
| Virgin ID/W @ V_GS = −0.5 V | 2.658 × 10⁻⁷ µA/µm | H3 Step 3b |
| Virgin ID (absolute, total fin) | 2.39 × 10⁻¹⁴ A | H9 baseline |

### B.2 Locked operating point — H1 v3 + H3 Step 2c/3b + **H9 (N=5)**

| Parameter | Value | Source |
|---|---|---|
| V_pgm | +2.0 V | H1 v3 |
| V_GS_read | −0.5 V (sub-V_t) | H1 v3 |
| V_DS_read | 50 mV | H1 v3 |
| V_erase | −6.0 V | H3 Step 2c/3b |
| Fire pulse hold | 100 ns | H1 v3 |
| Inline read | 100 ns | H1 v3 |
| Pulse period (rise + write + fall + read) | 202 ns | H1 v3 |
| **Pulses per fire burst N** | **5** | **H9** |
| Erase ramp + hold + fall | 10 µs | H3 Step 2c |
| Relax (V_GS = −0.5 V) | 70 µs (≥ 5·τ_relax) | H3 Step 2c |
| τ_relax (fit) | 13.7 µs | H3 Step 2c |
| τ_P (Preisach par-file) | 10 µs | Phase 1C simD |
| Cycle wall-clock | 81.038 µs | H9 |
| E / F_c at V_pgm = 2 V | 0.41 (sub-coercive) | H1 v3 |

### B.3 LIF response — H9 + H4

| Quantity | Value | Source |
|---|---|---|
| ID baseline (pre-fire) | 2.39 × 10⁻¹⁴ A | H9 baseline |
| ID after N=5 pulses (steady c3..c5) | ≈ 6.70 × 10⁻¹⁴ A | H9 per-cycle |
| fire_ratio cold-start (c1) | 2.65× | H9 |
| fire_ratio steady (mean c3..c5) | 3.04× (worst 2.65, best 4.15) | H9 |
| fire_ratio long-tail (c10..c20 mean, N=9 H4) | 3.07× | H4 |
| Rest state vs virgin | +1.44× | H3 Step 3b |
| Drift on ID_p_last (c10..c20) | +0.015 %/cyc (M1 PASS) | H4 |
| Drift on rest state | ≈ 0 %/cyc (M-rest PASS) | H4 |
| C2C σ/µ across V_pgm L5 (±25 mV) | 6.03 % | H4 / M8 |
| Sensitivity dfr/fr per 25 mV V_pgm | +5.4 % | H4 / M8 |
| Operating T window | 250 K ≤ T < ~325 K | H11 |
| Subthreshold-leak T coefficient | ×36.7 per +50 K | H11 |

The H9 per-pulse trajectory ID(n) for n ∈ {0..5} is the **canonical LIF forward kernel.** Interpolate; do not re-derive analytically.

### B.4 Energy — H9 N=5

| Quantity | N=5 (LOCKED) | N=9 (legacy) |
|---|---|---|
| E_fire | 646 fJ | 1151 fJ |
| E_erase | 10.3 fJ | 10.3 fJ |
| E_relax | −19.6 fJ | −19.7 fJ |
| **E_total / cycle** | **637 fJ** | 1142 fJ |
| E / pulse (FE-switching floor) | 129.3 fJ | 127.9 fJ |
| Savings vs N=9 | **−44.8 %** | — |

### B.5 Analog states — H12 (7-level synapse)

L3..L9 at V_pgm = 1.2 → 2.4 V (0.2 V step), +39 %/level minimum, 45× dynamic range at V_GS_read = −0.5 V, V_DS = 50 mV. **Report as a 7-state analog synapse, not 9.** This is what the SNN's weight quantisation should snap to in the device-aware variant.

### B.6 Retention — H10 (model-bounded)

Quasistationary equilibrium (no charge-trap / phonon-backswitching modelled). Use as **worst-case lower bound**; pair with Tasneem 10⁴ s ≥ 0.6 as the experimental anchor.

---

## PART C — Concrete change list (in order)

### C.1 — Rewrite `gaafefet_params.py` from §B.1–B.6

Frozen dataclasses, full provenance comments. **And wire the constants into `FeFETDevice` in `model_2.py` so the model actually uses them.** Currently, `model_2.py`'s defaults are decoupled from `gaafefet_params.py` — that's a bug.

```python
from gaafefet_params import FEFET
device_params = FeFETDevice(
    Vc=FEFET.device.V_c_gate_V,
    V_max=FEFET.operating.V_pgm_V + 0.4,        # 2.4 V — H12 top rung
    V_scale=FEFET.device.SS_post_PGM_mV_dec * 1e-3 / 0.434,   # ln(10)/SS
    K_switch=FEFET.lif_kernel.K_switch_fit,     # fit to H9 per-pulse table
    rest_offset=FEFET.lif.rest_state_vs_virgin_rel,   # 1.44 (NOT 0.772)
    reset_law="snap_to_rest",                   # not "multiplicative"
    drift_per_cycle=FEFET.lif.drift_p_last_pct_per_cyc / 100,
    jitter_sigma=FEFET.lif.M8_sigma_over_mu_pct / 100,
    tau_leak_snn=50e-3,                         # SNN-domain leak; document distinction from τ_P
)
```

### C.2 — Fix the reset law in `FeFETLIFNeuron.neuronal_reset`

Replace multiplicative collapse with snap-to-rest-offset, plus inter-cycle drift sampling. See §A.3.

### C.3 — Inject H4 drift + jitter into the training loop

In `main_ecg_8d_pure_ce_resume.py`, per batch:

```python
with torch.no_grad():
    # apply per-cycle drift to weight_to_Vpulse_slope or v_threshold
    drift = 1.0 + epoch * FEFET.lif.drift_p_last_pct_per_cyc / 100
    jitter = 1.0 + torch.randn(1).item() * FEFET.lif.M8_sigma_over_mu_pct / 100
    student.adjust_drive(drift * jitter)
```

This is the v2.3 step from `Phase1C_Plan.md §4.4` — load-bearing for top-tier publication.

### C.4 — Replace the H9 forward kernel with table interpolation

In `FeFETLIFNeuron.neuronal_charge`, after the Preisach sigmoid step, **gate the output by the measured H9 trajectory** loaded from `Writing_Materials/Phase1D_Analysis/Burst_Length/h9_per_cycle.csv`:

```python
# Snap P_new to the measured H9 per-pulse trajectory at the current n_pulses_in_burst
P_target = self.h9_table.lookup(n_pulses_in_burst, V_pgm_eff)
P_new = 0.7 * P_new + 0.3 * P_target   # soft anchor — keeps gradients flowing
```

This is the central change that converts the model from "Preisach-shaped fit" to "measurement-grounded LIF". It is the single biggest lever for crossing 85 % and for reviewer acceptance.

### C.5 — Delete `main_ecg_8c_warmup` KD branch

Keep the file in `archive/` for the methodological observation (KD with incompatible teachers fails). The canonical training script is `main_ecg_8d_pure_ce_resume.py` — rename to `train.py`.

### C.6 — Rename `vo2_encoder.py → lc_encoder.py`, parameterise Vth

Decouple from the VO2-specific 3.4 V threshold. Cite the VO2 paper as the source of the LC recipe.

### C.7 — Parameterise the dataset path

Replace the hard-coded `E:\Signal_Classific_Neuromorph\...` with an env var (`ECG_DATA_DIR`) or CLI arg.

### C.8 — Drop `(1)` suffixes from filenames

`gaafefet_params (1).py → gaafefet_params.py` etc.

---

## PART D — Methodology validation for top-tier publication

| Reviewer concern | Our answer | Status |
|---|---|---|
| Calibration against published device? | Tasneem 2022 Fig. 3(c); 2.8× MW differentiator | ✓ H0a v5 |
| P–E loop topology / V_c agreement | Loop closed; 0.5 % | ✓ H0e |
| Endurance to 20+ cycles | M1 +0.015 %/cyc, M-rest ≈ 0 %/cyc | ✓ H4 |
| C2C variability framing | Deterministic V_pgm-jitter coupling, not stochastic | ✓ H4 |
| Energy / pulse | 129.3 fJ FE-switching floor; H6 falsified read-floor | ⚠ trade-off |
| Multi-level analog states | 7 monotonic, +39 %/level | ⚠ trend PASS |
| Retention | model-bound + Tasneem anchor | ⚠ caveat |
| Temperature window | 250–300 K PASS, 350 K FAIL | ⚠ window declared |
| **SNN dynamics tied to measurement (H9 kernel)** | **C.4 above** | **open — Python work** |
| **Drift- and variation-aware training** | **C.3 above** | **open — Python work** |
| **Per-inference energy from H9 E_total** | needs `report.py` to multiply (active cycles) × 637 fJ | **open — Python work** |
| KD methodological observation | v8c failure shows RC→Polarization KD is unstable | publishable as a side note in the supplementary |

---

## PART E — References to pull (needs WebSearch / Exa authorisation)

**Already in `Papers/`:**
- Tasneem 2022 (calibration anchor)
- HZO physical modelling (Preisach physics)
- FTJ spiking neuron (direct competitor)
- VO2 LSNN paper (methodological starting point — cite as the inheritance we move past)
- Multi-level FeFET memristor (H12 analog-state precedent)
- CMOS LIF energy-efficient design (circuit context)

**Still need:**
- Neftci 2019 *Surrogate Gradient Learning in SNNs* (IEEE SPM) — citation for `surrogate.py`
- Bellec et al. 2018 *Long Short-Term Memory and Learning-to-Learn in Networks of Spiking Neurons* — LSNN architecture (the basis of the `LinearDualRecurrentContainer` pattern)
- MIT-BIH 4-class SNN SOTA 2024–2025 (positioning)
- Variation- / drift-aware training for memristive / FeFET SNNs (Nature / NPJ 2023–2025) — needed to justify C.3
- HZO experimental retention (1 yr / 10⁴ s) — anchor for H10 caveat

---

## PART F — Submission claim, restated

> A measurement-grounded FeFET LIF neuron drives a spiking network that classifies MIT-BIH 4-class arrhythmias at ≥ 85 % accuracy under H4-measured drift (+0.015 %/cyc) and H4-measured M8 jitter (6.03 %, deterministic V_pgm-coupled), at 637 fJ per LIF cycle (H9 N=5 lock, 44.8 % below the unlocked baseline), using a 7-state analog-synapse cell (H12). All device parameters are calibrated to Tasneem 2022 with a 2.8× memory-window differentiator; the SNN inherits its LIF forward kernel from the measured H9 per-pulse trajectory, not from the VO2 LSNN baseline.

The current 76.49 % ceiling stems from a Preisach-shaped fit that is decoupled from `gaafefet_params.py` and uses a multiplicative reset that contradicts H3 Step 3b. The five-step change list in PART C is the path from 76.49 % to ≥ 85 % — and from a tuned model to a publishable one.
