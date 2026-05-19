# Phase 1D — H4 endurance + V_pgm variability

**Status:** Run complete (2026-05-19). Acceptance gates M1 (long-tail), M-rest, M2 PASS at all five SWB L5 nodes. M8 lands at **6.03 %** vs the 5.0 % target — a deterministic V_pgm-sensitivity ceiling, not a stochastic-drift failure (rationale below).

Analyzer: [`Simulations/analyze_phase1d_h4.py`](../../../Simulations/analyze_phase1d_h4.py)
cmd: [`Simulations/simH_optimize/sdevice_simH4_endurance.cmd`](../../../Simulations/simH_optimize/sdevice_simH4_endurance.cmd) (generator `_gen_h4_endurance_cmd.py`)
Raw outputs: `Simulations/endurance_outputs/` (440 MB, 4046 `.plt` files)
CSV / summary copied to this folder: [`h4_per_node.csv`](h4_per_node.csv), [`h4_m8_per_cycle.csv`](h4_m8_per_cycle.csv), [`h4_summary.txt`](h4_summary.txt).

---

## Run configuration

| Parameter | Value |
|---|---|
| Operating point | locked from H3 Step 3b |
| Cycles | 20 |
| Pulses per fire burst | 9 (100 ns hold, 100 ns sub-V_t read) |
| V_pgm sweep (SWB L5) | **1.950, 1.975, 2.000, 2.025, 2.050 V** (±25 mV step around opt) |
| V_erase | −6.0 V (locked) |
| Erase hold / relax | 10 µs / 70 µs (V_GS = −0.5 V) |
| Per-cycle wall time | 81.838 µs |
| Total simulated time per node | 1.637 ms |

## Acceptance summary (long-tail c10 → c20)

| V_pgm (V) | drift ID_p9 / cyc | M1 | drift ID_relax / cyc | M-rest | min fire_ratio | M2 |
|---:|---:|:-:|---:|:-:|---:|:-:|
| 1.950 | +0.007 % | PASS | +0.000 % | PASS | 2.78× | PASS |
| 1.975 | −0.001 % | PASS | −0.000 % | PASS | 2.91× | PASS |
| 2.000 | +0.015 % | PASS | −0.000 % | PASS | 3.04× | PASS |
| 2.025 | −0.009 % | PASS | −0.000 % | PASS | 3.18× | PASS |
| 2.050 | +0.006 % | PASS | −0.000 % | PASS | 3.32× | PASS |

Long-tail drift on both the post-fire (p9) read and the post-erase rest baseline is **two orders of magnitude below** the 1 %/cycle gate at every operating point. Endurance over 20 cycles is essentially flat — the device reaches a stable C2C trajectory by cycle 3 and stays there.

## M8 — C2C variability across V_pgm L5

`σ/μ` of fire_ratio across the five V_pgm nodes, by cycle (steady-state band):

| Cycle | μ fire_ratio | σ | σ/μ |
|---:|---:|---:|---:|
| 10 | 3.106 | 0.188 | 6.06 % |
| 12 | 3.107 | 0.187 | 6.00 % |
| 14 | 3.106 | 0.189 | 6.07 % |
| 16 | 3.108 | 0.186 | 6.00 % |
| 18 | 3.107 | 0.186 | 6.00 % |
| 20 | 3.107 | 0.188 | 6.05 % |
| **c10..c20 mean** | — | — | **6.03 %** |

**Result:** σ/μ is **flat across cycles** (6.0 ± 0.05 %) with no monotonic drift, so the 6.03 % is the *deterministic* V_pgm-sensitivity of fire_ratio when V_pgm is jittered by ±1.25 % around the operating point — not a stochastic cycle-to-cycle process. The same σ/μ would persist at 200 cycles or 2000.

**Why it slightly exceeds 5 %:** fire_ratio ranges from 2.78× (V_pgm = 1.95 V) to 3.32× (V_pgm = 2.05 V), i.e. roughly **+10 % per +50 mV** of V_pgm in this regime. Over the ±25 mV L5 step the resulting σ ≈ 0.19. To hit M8 ≤ 5 % at the same fire_ratio target, the V_pgm jitter would have to be tightened to ≈ ±20 mV, *or* the operating point shifted into a flatter region of fire_ratio(V_pgm). Both are device-design / driver-circuit knobs, not a sub-V_t LIF physics limit.

The H3 Step 3b sub-V_t read (V_GS = −0.5 V) is intentionally on the **exponential** part of the I_D–V_G curve to maximise on/off contrast — that same exponential sensitivity is what produces the V_pgm coupling captured here. The trade-off is explicit and easy to defend in the manuscript: contrast vs. driver-precision.

## Figures

All saved at 160 DPI in [`figures/`](figures/):

| File | Content |
|---|---|
| `h4_id_p9_vs_cycle.png` | log-scale ID at the 9th pulse vs cycle, five V_pgm curves |
| `h4_id_relax_vs_cycle.png` | log-scale ID end-of-relax vs cycle, M-rest visualisation |
| `h4_fire_ratio_vs_cycle.png` | fire_ratio per cycle, M2 gate at 1.5× shown |
| `h4_m8_sigma_over_mu.png` | cross-node σ/μ vs cycle with the 5 % M8 line |
| `h4_staircase_v200_c1_c10_c20.png` | 9-pulse staircase at V_pgm = 2.0 V for cycles 1 / 10 / 20 — visual proof of stability |

## Headline numbers (for manuscript)

- **20-cycle long-tail drift, ID_p9, V_pgm = 2.0 V:** +0.015 %/cycle  (≤ 1 % target)
- **20-cycle long-tail drift, rest baseline, V_pgm = 2.0 V:** −0.000 %/cycle
- **fire_ratio at V_pgm = 2.0 V, c10..c20 mean:** 3.07× (target ≥ 1.5)
- **fire_ratio sensitivity to V_pgm:** Δ(fire_ratio) / fire_ratio ≈ +5.4 % per +25 mV V_pgm
- **M8 σ/μ across ±25 mV V_pgm jitter, c10..c20:** 6.03 % (slightly above 5 % target — deterministic, not stochastic)

## Implications / next steps

1. **Tighten V_pgm jitter ≤ ±20 mV in the driver-circuit spec** to bring M8 within 5 % at the present operating point. Document this as a peripheral-circuit constraint, not a device limit.
2. **Optional alternative:** characterise fire_ratio at V_GS_read = −0.3 V (less exponential) and see if M8 narrows naturally; weigh against on/off contrast.
3. M1 / M-rest / M2 are decisively closed by H4. The remaining 1D outstanding item is **H5 energy** (M5, M6).

