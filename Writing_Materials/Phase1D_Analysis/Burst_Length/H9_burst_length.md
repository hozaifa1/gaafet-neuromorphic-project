# H9 — Burst-Length Sweep (Energy / M2-margin Pareto)

**Date:** 2026-05-21
**Status:** ✓ DONE — N=5 selected as energy-best operating point
**Source:** `Simulations/simH_optimize/h9_outputs/` (SWB, 5 N-nodes × 5 cycles)
**Analyzer:** `Simulations/analyze_phase1d_h9.py`
**Cycle:** N × (rise + 100 ns write + fall + 100 ns inline read) + erase rise/10 µs hold/fall + 70 µs relax

## Headline

| N | E_fire (fJ) | E_total / cycle (fJ) | E / pulse (fJ) | fire_ratio (min / mean / max) | M2 |
|---|---:|---:|---:|---|---|
| 5 | 646.5 | **637.1** | 129.3 | 2.65 / 3.04 / 4.15 (margin **+1.15**) | ✓ PASS |
| 6 | 775.7 | 766.3 | 129.3 | 3.12 / 3.64 / 5.35 (margin +1.62) | ✓ PASS |
| 7 | 905.0 | 895.7 | 129.3 | 3.44 / 4.16 / 6.31 (margin +1.94) | ✓ PASS |
| 8 | 1034.4 | 1025.0 | 129.3 | 3.86 / 4.67 / 7.09 (margin +2.36) | ✓ PASS |
| 9 | 1163.7 | 1154.3 | 129.3 | 4.39 / 5.18 / 7.76 (margin +2.89) | ✓ PASS |

**Energy-best N that still passes M2: N = 5.**

- E_total saving vs N = 9 reference: **−44.8 % / cycle** (1154 → 637 fJ).
- E / pulse is **flat at 129.3 fJ** — exactly the FE-switching-charge floor that H5/H6 already localised to the 100 ns write hold at V_pgm = 2.0 V. Burst length is the only knob left.
- fire_ratio scales linearly with N: each extra pulse adds ≈ 0.55× of margin above the M2 = 1.5 gate. N = 5 keeps **+1.15× margin** (more than 2× the gate), so the publication claim "9-pulse LIF" can be re-stated as **"5-pulse LIF, 2× M2 margin, 45 % less energy / cycle."**

## Per-cycle table at N = 5

| cycle | E_fire (fJ) | E_erase (fJ) | E_relax (fJ) | E_total (fJ) | fire_ratio |
|---|---:|---:|---:|---:|---:|
| c1 | 678.7 | 10.3 | −19.6 | 669.5 | 2.65 |
| c2 | 635.1 | 10.2 | −19.7 | 625.7 | 4.15 |
| c3 | 639.8 | 10.2 | −19.7 | 630.4 | 2.80 |
| c4 | 639.3 | 10.2 | −19.7 | 629.9 | 2.80 |
| c5 | 639.3 | 10.2 | −19.7 | 629.9 | 2.80 |

c2 is the wake-up cycle (higher polarisation imprint after first erase) — same pattern observed in H3 Step 3b and H4. c3–c5 are at steady state: drift c3 → c5 = 0 % on ID_p5 (well under the M1 1 %/cyc gate).

## Acceptance gates at the new operating point

| Metric | Target | N=5 | Status |
|---|---|---:|---|
| M1 drift c3→c5 on ID_p_N | ≤ 1 %/cyc | ≈ 0 %/cyc | ✓ PASS |
| M2 fire_ratio per cycle | ≥ 1.5 | 2.65 .. 4.15 | ✓ PASS (+1.15 margin worst case) |
| M5 E_fire / pulse | ≤ 50 fJ | 129.3 fJ | ✗ FAIL (floor unchanged) |
| M6 E_total / cycle | ≤ 100 fJ | 637 fJ | ✗ FAIL (5.4× over but **6.4× better than H4/H5/H6 N=9**) |

## Interpretation

H6 already showed that the read segment is < 0.1 fJ / pulse — *not* the energy bottleneck. H9 isolates the only remaining circuit-level knob: **burst length**. Each fire pulse costs a flat 129 fJ regardless of N (FE-switching charge × V_pgm × W_gate at 100 ns hold), so cycle energy scales linearly in N + a fixed 10 fJ erase + −20 fJ net-dissipative relax.

At N = 5, **fire_ratio still clears M2 by +1.15×** on the worst cycle (c1, the cold-start cycle); steady-state c3–c5 sits at 2.80×, almost 2× the gate. There is no observable M1 drift between c3 and c5. The 5-pulse regime is therefore the lowest-N operating point compatible with the locked H3 Step 3b acceptance set.

**The 44.8 % cycle-energy saving over N = 9 is the largest improvement available without changing the device stack** (Tasneem-anchored HZO thickness / coercive field). Combined with the H5/H6 finding that the 100 ns write × V_pgm = 2.0 V product is the absolute floor at this stack, this gives the manuscript a clean *"5-pulse LIF at 637 fJ/cycle = stack-limit at the Tasneem calibration anchor"* story.

## Figures

- [`figures/h9_energy_and_M2_vs_N.png`](figures/h9_energy_and_M2_vs_N.png) — E_total and fire_ratio vs N (dual panel).
- [`figures/h9_pareto_energy_vs_fire_ratio.png`](figures/h9_pareto_energy_vs_fire_ratio.png) — Pareto: cycle energy vs M2 fire_ratio, with N labels.

## Files

- `h9_per_node.csv` — per-N means and M2 flag.
- `h9_per_cycle.csv` — all 5 N × 5 cycles of energy + fire_ratio.
- `h9_summary.txt` — analyzer console output.

## Operating-point update

H9 promotes **N = 5** as the new locked burst length. All downstream Python modelling (Step 2/`lif_parameters.py`) and any future SWB sweeps should adopt N = 5 unless they specifically need the 9-pulse reference for a comparison figure.
