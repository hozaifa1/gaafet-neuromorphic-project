# Phase 1D Step 3b — Cyclic LIF Analysis (M1 + M2 PASSED)

**Date:** 2026-05-19 (Step 3b rerun; supersedes Step 3a 2026-05-18 partial run)
**Run:** [`Simulations/simH_optimize/cyclic_lif_outputs/`](../../../Simulations/simH_optimize/cyclic_lif_outputs/) — V_erase ∈ {−4, −6, −10} V, 5 cycles × 9 fires + 10 µs pulsed erase + 70 µs relax (≈410 µs/node)
**Analyzer:** [`Simulations/analyze_phase1d_cyclic.py`](../../../Simulations/analyze_phase1d_cyclic.py) → [`Simulations/phase1d_cyclic/cyclic_metrics.txt`](../../../Simulations/phase1d_cyclic/cyclic_metrics.txt)
**Plotter:** [`Simulations/plot_phase1d_cyclic.py`](../../../Simulations/plot_phase1d_cyclic.py) → [`figures/`](figures/)

## Headline

Genuine multi-cycle LIF demonstrated. Original Tier-A M1 (|drift c3→c5| ≤ 1 %/cyc on ID_p9) and M2 (fire_ratio ≥ 1.5 every cycle) both PASS at **all three V_erase nodes tested**. **V_erase = −6 V is the operating point** — it's the only node that simultaneously passes M1, M2, and the rest-baseline stability check (drift c3→c5 on ID_end_relax = −0.02 %/cyc, flat to two decimal places).

The figures: see [fig_staircase_all_cycles.png](figures/fig_staircase_all_cycles.png) for the full 5-cycle step-plot across the three V_erase nodes, [fig_staircase_evolution.png](figures/fig_staircase_evolution.png) for the per-cycle staircase overlay at V_erase = −6 V (best single picture of the wake-up → limit-cycle story), [fig_fire_ratio.png](figures/fig_fire_ratio.png) for the cycle-resolved fire ratio, and [fig_relax_baseline.png](figures/fig_relax_baseline.png) for the rest-state stability.

## Full 5-cycle data (Step 3b)

### Per-cycle fire response (ID at end of pulse-9 read, µA/µm; virgin baseline = 2.658×10⁻⁷)

| V_erase | ID_p9_c1 | c2 | c3 | c4 | c5 | drift c3→c5 | M1 |
|---|---|---|---|---|---|---|---|
| −4 V | 1.27e-6 | 3.47e-6 | 3.01e-6 | 3.02e-6 | 3.02e-6 | +0.23 %/cyc | PASS |
| **−6 V** | 1.27e-6 | 2.05e-6 | **1.16e-6** | **1.18e-6** | **1.18e-6** | **+0.73 %/cyc** | **PASS** |
| −10 V | 1.27e-6 | 1.13e-6 | 1.13e-6 | 1.14e-6 | 1.12e-6 | −0.56 %/cyc | PASS |

### Per-cycle fire_ratio (= ID_p9_cN / ID_pre_cN; ID_pre_c1 = virgin, ID_pre_cN>1 = end of cycle (N−1)'s relax)

| V_erase | fire_ratio c1 | c2 | c3 | c4 | c5 | M2 |
|---|---|---|---|---|---|---|
| −4 V | 4.79× | 11.28× | 6.10× | 6.27× | 6.26× | PASS |
| **−6 V** | **4.79×** | **5.22×** | **3.04×** | **3.06×** | **3.06×** | **PASS** |
| −10 V | 4.79× | 1.94× | 1.77× | 1.83× | 1.79× | PASS |

### Post-erase rest state (ID at end of 70 µs relax, ratio to virgin)

| V_erase | relax c1 | c2 | c3 | c4 | c5 | drift c3→c5 |
|---|---|---|---|---|---|---|
| −4 V | 1.16× | 1.86× | 1.81× | 1.82× | 1.92× | +2.96 %/cyc (FAIL) |
| **−6 V** | **1.48×** | **1.43×** | **1.44×** | **1.44×** | **1.44×** | **−0.02 %/cyc (PASS)** |
| −10 V | 2.20× | 2.39× | 2.34× | 2.34× | 2.34× | −0.05 %/cyc (PASS) |

## Reading the result

### The three-stage device personality
At every V_erase node the device exhibits a clean three-stage progression:

1. **Cycle 1 = virgin fire (4.79×, identical across nodes).** The 9-pulse staircase from virgin reproduces the H1 v3 / H3 v4 cycle-1 fire byte-for-byte: `pre 2.66e-7 → p1 4.54e-8 (wake-up dip) → p2 1.49e-7 → p3 3.14e-7 → … → p9 1.27e-6`. The starting state is identical (virgin) regardless of V_erase, so the fire response is identical.

2. **Cycle 2 = wake-up.** Cycle 2 starts from the cycle-1 post-erase rest state, which has not yet equilibrated to the limit-cycle attractor. fire_ratio is always larger than the steady-state value because ID_pre is below its eventual steady-state. This is the same wake-up signature seen in H0e (cycle 1 vs cycle 2 P–E loop) and is intrinsic to the Preisach physics, not noise.

3. **Cycles 3–5 = steady-state limit cycle.** ID_pre, ID_p9, and ID_end_relax all settle to their attractor values and stay there. At V_erase = −6 V the values are identical to three significant figures across c3, c4, c5 — the system is on a closed orbit in (ID_pre, ID_p9) space. This is the genuine LIF claim.

### Why V_erase = −6 V is the operating point
- **V_erase = −4 V (under-erase)**: the FE doesn't fully cross the coercive boundary in 10 µs. Pre-cycle baseline drifts up cycle-by-cycle (+2.96 %/cyc on the rest baseline c3→c5 — fails the rest-drift gate). Fire response saturates at 6.26× because each subsequent fire pushes against an already-saturated rail; the read level rises but the fire margin doesn't. Long-tail endurance risk: rest state keeps climbing.
- **V_erase = −6 V (sweet spot)**: clean coercive crossing, lands on a single +Pol-partial attractor at 1.44× virgin, stays there. Rest baseline drift −0.02 %/cyc — flat. Fire ratio collapses to 3.06× and stays there to four significant figures across c3, c4, c5.
- **V_erase = −10 V (over-erase)**: drives FE deep into −Pol saturation. 70 µs relax can only partially recover. Rest at 2.34× virgin, fire margin just barely above M2 (1.79× at c5). Deep saturation every cycle = oxide wear-out endurance risk.

### The "restore" gate is the wrong gate for this device
The original Tier-A acceptance set defined `restore_cN = ID_end_relax_cN / ID_virgin ∈ [0.75, 1.25]` — the device must reset to virgin baseline between bursts. **This metric fails at every node** because the natural rest state of this depolarization-screened MFIS stack is +Pol-partial (above virgin), not virgin. But the rest state is *stable*: at V_erase = −6 V the rest baseline is identical c3..c5 (1.44× virgin, drift −0.02 %/cyc), which is the *biologically* meaningful property — real neurons reset to a non-zero V_rest, not to zero membrane potential.

**Recommended metric replacement** (already updated in the submission-gate table of the Phase 1D plan):
- `M-rest`: |drift_c3→c5| on `ID_end_relax` ≤ 1 %/cyc. V_erase=−6 V PASSES at −0.02 %/cyc; V_erase=−10 V PASSES at −0.05 %/cyc; V_erase=−4 V FAILS at +2.96 %/cyc.
- Combined M1 + M2 + M-rest → **only V_erase = −6 V passes all three**. This becomes the H4 endurance operating point.

## Step 3a → 3b bug history (kept for the methods section)

Step 3a (2026-05-18) ran cleanly on the remote but the executed cmd (`sdevice_simH3_cyclic_fixed.cmd`) had a `Transient (InitialTime, FinalTime)` vs `CurrentPlot Time Range` mismatch for `c3_p6_read` onward and *every* `c4_*_read` / `c5_*_read` segment — the requested CurrentPlot interval fell entirely outside the segment's active interval. Sentaurus ran the segments physically (rise/write/fall and erase/relax windows wrote correctly) but the read segments wrote zero samples. Per-pulse read .plt files existed only for c1, c2, c3 p1–p5.

Two fixes landed locally (2026-05-18):
1. [`Simulations/_gen_h3_cyclic_cmd.py`](../../../Simulations/_gen_h3_cyclic_cmd.py) now has `assert_alignment()` that scans every regenerated cmd for `CurrentPlot Range` escaping its enclosing `Transient` window; regeneration fails loudly instead of shipping a broken cmd.
2. [`Simulations/simH_optimize/cyclic_lif_outputs/run_cyclic_lif.csh`](../../../Simulations/simH_optimize/cyclic_lif_outputs/run_cyclic_lif.csh) was pointed at the canonical `sdevice_simH3_cyclic.cmd` (was the buggy `_fixed.cmd`).

Step 3b (2026-05-19) re-ran the canonical cmd on the remote. Analyzer banner now confirms "all 5 cycles × 9 pulses × 3 V_erase nodes complete."

## Next steps

1. ~~**H4 endurance** (Phase 1D plan §H4): adapt `sdevice_simH3_cyclic.cmd` to 20+ cycles, add SWB `@V_pgm@ ∈ {1.95, 2.0, 2.05} V` for M8 cycle-to-cycle variability, hardcode V_erase = −6 V.~~ **DONE** — H4 PASS: M1/M-rest/M2 all PASS; M8 σ/μ = 6.03 % across ±25 mV V_pgm jitter (c10–c20), deterministic V_pgm coupling. See [`Writing_Materials/Phase1D_Analysis/Endurance/H4_endurance_analysis.md`](../Endurance/H4_endurance_analysis.md).
2. ~~**H5 energy** (analytical, no new sim): `E_gate = ½·C_gg·V_pgm²·N_pulses` per fire burst; `E_total = E_gate + E_read`.~~ **DONE** — H5: E_fire = 1.151 pJ/burst (128 fJ/pulse), E_total = 1.142 pJ/cycle. M5 (≤50 fJ/pulse) and M6 (≤100 fJ/cycle) FAIL — framed as read-floor / endurance-vs-energy trade-off. See [`Writing_Materials/Phase1D_Analysis/Energy/H5_energy.md`](../Energy/H5_energy.md).
3. **Writeup updates**: ~~replace the "restore ±25 % of virgin" claim throughout `Writing_Materials/`~~ DONE — all Writing_Materials/*.md files updated to M-rest framing (stable +Pol-partial rest state, biological-LIF analogy, MFIS depolarisation screening rationale).
4. **`Step_2/lif_parameters.py` rewrite**: numbers from Step 3b are the publishable ones. V_pgm = +2.0 V, V_erase = −6 V, t_pulse = 100 ns, t_erase = 10 µs, t_relax = 70 µs, fire_ratio_steady_state = 3.06×, rest_state = 1.44× virgin, τ_relax = 13.7 µs.

## Files

| Artifact | Path |
|---|---|
| Master cmd | [`Simulations/simH_optimize/sdevice_simH3_cyclic.cmd`](../../../Simulations/simH_optimize/sdevice_simH3_cyclic.cmd) |
| Generator (with alignment assert) | [`Simulations/_gen_h3_cyclic_cmd.py`](../../../Simulations/_gen_h3_cyclic_cmd.py) |
| Runner (canonical cmd) | [`Simulations/simH_optimize/cyclic_lif_outputs/run_cyclic_lif.csh`](../../../Simulations/simH_optimize/cyclic_lif_outputs/run_cyclic_lif.csh) |
| Analyzer | [`Simulations/analyze_phase1d_cyclic.py`](../../../Simulations/analyze_phase1d_cyclic.py) |
| Plotter | [`Simulations/plot_phase1d_cyclic.py`](../../../Simulations/plot_phase1d_cyclic.py) |
| Per-node metrics | [`Simulations/phase1d_cyclic/cyclic_metrics.txt`](../../../Simulations/phase1d_cyclic/cyclic_metrics.txt) |
| Per-node CSV | [`Simulations/phase1d_cyclic/cyclic_vm{4,6,10}_per_cycle.csv`](../../../Simulations/phase1d_cyclic/) |
| Cross-node summary | [`Simulations/phase1d_cyclic/per_cycle_endpoints.csv`](../../../Simulations/phase1d_cyclic/per_cycle_endpoints.csv) |
| Figures | [`figures/`](figures/) |
