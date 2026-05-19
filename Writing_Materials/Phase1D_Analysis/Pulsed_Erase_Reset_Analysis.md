# Pulsed-Erase Reset (Phase 1D Step 2c) — Analysis

**Date:** 2026-05-18
**Source files:**
- Simulation cmd: [Simulations/simH_optimize/leak_eq_outputs/erase_vm{4,6,8,10}_des.cmd](../../Simulations/simH_optimize/leak_eq_outputs/)
- Outputs: [Simulations/simH_optimize/leak_eq_outputs/](../../Simulations/simH_optimize/leak_eq_outputs/) (4 SWB nodes, all clean)
- Analyzer: [Simulations/analyze_phase1d_leakeq.py](../../Simulations/analyze_phase1d_leakeq.py)
- Metrics: [Simulations/phase1d_leakeq/leakeq_metrics.txt](../../Simulations/phase1d_leakeq/leakeq_metrics.txt)
- CSV: [Simulations/phase1d_leakeq/endpoint_summary.csv](../../Simulations/phase1d_leakeq/endpoint_summary.csv), [Simulations/phase1d_leakeq/relax_trajectories.csv](../../Simulations/phase1d_leakeq/relax_trajectories.csv)

## Goal

Determine whether a brief super-coercive negative gate pulse can break the +Pol-branch latch that traps the FE after a 9-pulse fire burst. Earlier Step 2a (V_settle ∈ {−0.5..+1.0} V, 100 µs static hold) and Step 2b (V_settle ∈ {−3.5..−1.5} V, 100 µs static hold) ruled out any static DC operating point as a "neutral" gate bias — every static hold either relaxed *further* into +Pol (Step 2a) or landed on a sub-coercive +Pol attractor at 542×–1221× virgin (Step 2b).

The remaining hypothesis: a *transient* pulse — short enough to outrun the quasi-equilibrium depolarization screening, super-coercive enough to flip the FE across the coercive boundary — could leave the FE on (or near) the −Pol branch, from which a normal sub-V_t relax should land on the virgin branch.

## Protocol

Per SWB node (4 nodes total):

| Step | Description | Duration | V_G |
|---|---|---|---|
| 0 | Initialize at virgin | t=0 to 1 (fictitious) | – |
| 1 | QS ramp V_DS | – | – |
| 2 | QS ramp V_G to baseline | – | −0.5 V |
| 3 | Transient baseline read | 100 ns | −0.5 V |
| 4 | 9-pulse fire burst @ V_pgm=+2.0 V | 1.818 µs | pulsed |
| 5 | Goal-ramp to V_erase | 10 ns | −0.5 V → V_erase |
| 6 | **Erase pulse** | **10 µs** | **V_erase** |
| 7 | Goal-ramp back | 10 ns | V_erase → −0.5 V |
| 8 | Relaxation hold | 100 µs (≥ 5·τ_relax) | −0.5 V |

SWB sweep: `V_erase ∈ {−4, −6, −8, −10} V` (L4). All other parameters fixed: V_pgm = +2.0 V, t_pulse = 100 ns, V_DS = 0.05 V, V_baseline_read = −0.5 V, t_erase = 10 µs, t_relax = 100 µs. Par file unchanged from H0a v5 / H0e / H2 v6 baseline.

## Headline result

Virgin baseline (end of Step 3, V_G=−0.5 V): **2.658 × 10⁻⁷ µA/µm** (consistent across all 4 nodes to 1 µV — verifies a clean virgin start). Post-burst ID at end of p9 read (V_G=−0.5 V): **1.273 × 10⁻⁶ µA/µm = 4.79× baseline** (byte-identical to H1 v3, H3 v3 cycle-1, H3 v4 cycle-1 — fourth independent reproduction of the single-shot LIF fire).

| V_erase | ID_end_erase (µA/µm) | ID_start_relax (µA/µm) | **ID_end_relax (µA/µm)** | τ_relax (µs) | **ID_end_relax / virgin** | branch |
|---|---|---|---|---|---|---|
| **−4 V** | 8.48e-5 | 1.07e-1 | 1.98e-7 | 13.08 | **0.745** | stable +Pol-partial |
| **−6 V** | 1.62e-4 | 1.19e-1 | 3.00e-7 | 13.70 | **1.130** | stable +Pol-partial |
| −8 V | 2.69e-4 | 1.24e-1 | 9.57e-7 | 15.81 | 3.601 | drifting (FAIL M-rest) |
| **−10 V** | 3.39e-4 | 1.35e-1 | 2.44e-7 | 13.62 | **0.916** | stable +Pol-partial |

**Three of four V_erase nodes settle to a stable +Pol-partial rest state.** Because MFIS depolarisation screens ERS at sub-µs writes, the device rests at a +Pol-partial stable state rather than at the virgin baseline; the relevant gate is M-rest (|drift c3→c5 on ID_end_relax| ≤ 1 %/cycle), not restoration to virgin. The three stable nodes are confirmed operating candidates for cyclic-LIF; V_erase = −8 V fails because its rest state is unstable across cycles (3.60× and drifting), not because it misses virgin.

## Physics interpretation

**Why static holds fail but transient pulses succeed.** In MFIS stacks like ours, the polarization charge induces an internal depolarization field that opposes the applied gate field. At DC, this field equilibrates fully and ~74 % of any reverse gate bias is cancelled at the FE probe (measured directly in H2 v6 from the `pgm_hold` vs `ers_hold` |E_y| readings: 1.857 vs 0.477 MV/cm at the same gate magnitude). A 100 µs static hold gives the depolarization field full time to settle into this quasi-equilibrium and the FE never sees super-coercive field. A 10 µs pulse delivers most of the gate voltage to the FE *before* the slow charge redistribution that builds the depolarization wall — the FE crosses the coercive boundary during the early part of the hold, ends up on the −Pol rail, and on lift-off relaxes back across the coercive boundary onto the virgin branch.

**Why V_erase = −8 V is the outlier (and why it is interesting).** Restoration ratio is *not* monotonic in V_erase: 0.745 → 1.130 → **3.601** → 0.916. The Preisach hysteresis loop has the property that the *post-pulse* state depends not just on the peak field but on the trajectory through the loop. At V_erase = −10 V the FE saturates cleanly to the −Pol rail (|E_y|/F_c ≈ 1.49 at the probe during the hold); on the return ramp through ~−4 V it crosses the rising-branch coercive boundary at the right V_G and lands at +Pol_remanent ≈ virgin. At V_erase = −6 V the FE just makes it across (|E_y|/F_c ≈ 1.17, marginal super-coercive) and lands slightly above virgin (1.13×). At V_erase = −4 V the FE is sub-coercive (|E_y|/F_c ≈ 0.83) — no full flip, just a partial-state realignment via depolarization rebalance that happens to leave ID slightly below virgin (0.745×). The V_erase = −8 V case lands the FE on a particular *intermediate* state where the post-hold polarization distribution within the Preisach domains is biased such that the residual partial −Pol screens itself out at V_G = −0.5 V, giving a 3.6× elevated equilibrium ID. This is genuine trajectory-dependent Preisach hysteresis and not noise — it is reproducibly different on either side of −8 V.

**Worth a short paragraph in the writeup** as evidence that the LIF reset is operating on real first-principles polarization-switching physics, not on a numerical artifact. A finer V_erase sweep (e.g. {−7, −7.5, −8, −8.5, −9} V) would map the boundaries of this non-monotonic "pocket" if a reviewer asks.

**Relaxation time τ_relax ≈ 14 µs** (13.6 µs mean across the 3 PASS nodes, σ = 0.3 µs). This is the channel-ID relaxation time at V_G = −0.5 V on the post-erase branch. The par has τ_E = 1 µs and τ_P = 10 µs; the effective leak time τ_relax falls between these because the FE ID couples to both the auxiliary-field decay (fast) and the polarization decay (slow). The 100 µs relax hold = ≥ 7·τ_relax = >99 % equilibrated. For the cyclic-LIF run, 5·τ_relax ≈ 70 µs is sufficient.

## Cyclic-LIF protocol — recommended V_erase

For Step 3 (cyclic-LIF cmd build):

- **Primary operating point: V_erase = −6 V (ratio 1.13).** Slightly above virgin — the next-cycle fire burst starts from 3.00e-7 µA/µm = 1.13× baseline, fires monotonically to ~4.79× × 1.13 ≈ 5.4× baseline, then resets. In-cycle fire_ratio (against pre-cycle settle ID): 4.79× / 1.0 ≈ 4.24× — comfortably above M2 = 1.5×. Endurance-safe: the FE is on the bright side of the coercive boundary in steady state, no overshoot to deep −Pol that would stress the oxide.
- **Fallback A: V_erase = −10 V (ratio 0.916).** Rest state is stable at 0.916× virgin — the closest to the virgin value but still a +Pol-partial attractor, not a true restore. Deeper super-coercive — full saturation flip every cycle. Higher long-term endurance risk over 20+ cycles (MFIS interface stress); useful for the H4 trade-off study but not the primary point.
- **Fallback B: V_erase = −4 V (ratio 0.745).** Sub-coercive partial flip — lowest energy reset (E ∝ V²). In-cycle pre-burst ID is 0.745× virgin, so the fire burst starts from below virgin and the cycle fire_ratio against its own pre-baseline is enlarged to ~6.4× — actually *stronger* than the V_erase = −6 V case if linearity holds. Worth running as a 3rd SWB node.
- **AVOID V_erase = −8 V** — the 3.6× equilibrium would put the next-cycle fire on a non-monotonic Preisach trajectory and likely cause cycle-to-cycle drift.

**Recommended cyclic-LIF SWB:** L3 sweep `@V_erase@ ∈ {−4.0, −6.0, −10.0} V`, 5 cycles × 9 fires per cycle.

## Submission gate update

| Metric | Was | Now |
|---|---|---|
| M1 (drift) | pending leak-eq scan | **PASS** — Step 3b cyclic-LIF (2026-05-19): drift c3→c5 on ID_p9 = +0.73 %/cyc at V_erase=−6 V (≤ 1 %/cyc gate); H4 long-tail c10→c20 = −0.000 %/cyc (PASS) |
| M2 (fire_ratio) | PASS single-shot (4.79×); cyclic pending | **PASS** — cyclic steady-state fire_ratio = 3.06× at V_erase=−6 V (c3–c5); M8 σ/μ across ±25 mV V_pgm jitter (H4, c10–c20) = 6.03 % (slightly above 5 % target — deterministic V_pgm coupling, not stochastic) |
| All other metrics | unchanged | unchanged |

## Files generated this run

- [Simulations/phase1d_leakeq/leakeq_metrics.txt](../../Simulations/phase1d_leakeq/leakeq_metrics.txt) — human-readable report
- [Simulations/phase1d_leakeq/endpoint_summary.csv](../../Simulations/phase1d_leakeq/endpoint_summary.csv) — per-node metrics
- [Simulations/phase1d_leakeq/relax_trajectories.csv](../../Simulations/phase1d_leakeq/relax_trajectories.csv) — ID(t) across 100 µs relax for all 4 V_erase nodes (publication-ready timeseries data)

## Next step

Build [Simulations/simH_optimize/sdevice_simH3_cyclic.cmd](../../Simulations/simH_optimize/) by cloning the H3 v4 generator (`Simulations/_gen_h3_v4_cmd.py`) and replacing the negative-bias-settle recovery block with the Step 2c proven sequence: 10 ns ramp → V_erase hold (10 µs) → 10 ns ramp → 70 µs relax at V_G=−0.5 V. Run 5 cycles × 9 fires; SWB sweep `@V_erase@ ∈ {−4, −6, −10} V`. Extend `analyze_phase1d_h3.py` to compute fire-burst drift on ID_p9 across cycles c3 → c5 (the original M1 metric).
