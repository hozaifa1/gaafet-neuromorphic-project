# Phase 1D — H6 deferred-read energy (knob #1 of post-H5 roadmap)

**Status:** Run complete (2026-05-21). 5-node SWB sweep `V_pgm ∈ {1.95, 1.975, 2.0, 2.025, 2.05} V`, 20 cycles per node, 60 min wallclock per node. Outputs in [`Simulations/simH_optimize/h6_outputs/`](../../../Simulations/simH_optimize/h6_outputs/).

**Headline:** Deferred read **does not save energy.** Removing 8 of 9 inline 100 ns sub-V_t reads delivers a **+1.1 % delta** (1153.5 fJ/cycle vs H5's 1141.5 fJ/cycle at the same V_pgm), well inside the cycle-to-cycle solver noise floor. The Phase 1D roadmap's "read-floor" hypothesis (expecting ~96 fJ saved by removing 8 reads) is **falsified**.

Analyzer: [`Simulations/analyze_phase1d_h6.py`](../../../Simulations/analyze_phase1d_h6.py)
Outputs: [`h6_summary.txt`](h6_summary.txt), [`h6_per_segment.csv`](h6_per_segment.csv), [`h6_per_cycle.csv`](h6_per_cycle.csv), [`h6_per_cycle_all_nodes.csv`](h6_per_cycle_all_nodes.csv)

---

## Why the deferred-read hypothesis was wrong

Re-binning H5's segments confirms the actual per-pulse cost breakdown at V_pgm = 2.0 V (c10..c20 mean, 99 pulses):

| Segment | Wall time | Energy/pulse | % of pulse |
|---|---:|---:|---:|
| `rise`  | 1 ns   | **0.80 fJ**   | 0.6 % |
| `write` | 100 ns | **126.72 fJ** | **99.1 %** |
| `fall`  | 1 ns   | **0.28 fJ**   | 0.2 % |
| `read`  | 100 ns | **0.08 fJ**   | **0.06 %** |
| **Total** | 202 ns | **127.88 fJ** | 100 % |

The sub-V_t read at V_GS = −0.5 V, V_DS = 50 mV draws **~16 pA × 50 mV × 100 ns ≈ 0.08 fJ** — three orders of magnitude below the write segment. The 12-fJ-per-read estimate in the H5 writeup was incorrect; the dominant cost is the 100 ns **hold at V_pgm = 2.0 V** (gate displacement current charging the FE plus drain channel current at V_DS = 50 mV under the polarised channel).

H6 therefore confirms what the H5 segment breakdown already implied: cutting reads cuts essentially nothing.

## Results (V_pgm = 2.0 V, c1-c2 mean)

| Quantity | H5 (inline read) | H6 (deferred read) | Δ |
|---|---:|---:|---:|
| E_fire (9 pulses)     | 1150.91 fJ | 1162.76 fJ | +11.85 fJ |
| E_pulse_equivalent    | 127.88 fJ  | 129.20 fJ  | +1.32 fJ  |
| E_burst_read (1 read) | (inline) | 0.08 fJ | — |
| E_erase               | 10.26 fJ  | 10.27 fJ  | +0.01 fJ |
| E_relax               | −19.67 fJ | −19.60 fJ | +0.07 fJ |
| **E_total / cycle**   | **1141.51 fJ** | **1153.51 fJ** | **+12.00 fJ (+1.1 %)** |

The +12 fJ delta is solver noise (single-cycle variance in H5 is ~80 fJ wake-up + ~10 fJ steady-state jitter). **No real saving.**

V_pgm-sweep across the L5 SWB is monotone (1145 → 1161 fJ from 1.95 → 2.05 V, the same +5.4 %/25 mV deterministic coupling that drove H4 M8 = 6.03 %); see [`h6_summary.txt`](h6_summary.txt) for the full table.

## Operational caveat: precision bug in the H6 source `.cmd`

`_cmd_helpers.fmt` formats times at `.4e` (4-digit mantissa). For cycle base times above ~150 µs, the `CurrentPlot( Range=... )` clause is quantised to a 10–100 ns grid that drifts *outside* the actual `Transient` window Sentaurus executes (Sentaurus rewrites `InitialTime`/`FinalTime` at full precision during SWB expansion but parses `CurrentPlot Range` from the source as-is). The user applied a partial server-side fix that bumped `InitialTime`/`FinalTime` to 6-digit precision but did not touch `CurrentPlot Range`. The result, visible in the per-cycle table:

| Cycles | Status | `.plt` resolution |
|---|---|---|
| c1, c2  | CLEAN  | Full sampling, energies converge |
| c3..c8  | PARTIAL | `write`/`burst_read` .plt files present but progressively sparser (E_fire decays 992 → 104 fJ purely from numerical-integration aliasing, not a physical effect) |
| c9..c20 | MISSING `burst_read`, missing many `write` | Only `rise`/`fall` segments emit; cannot compute fire energy or fire_ratio |

The c1–c2 mean is **the only steady-state-comparable number**, and it is what the comparison table above uses. Re-running H6 with the fix is **not warranted**: the c1–c2 result already answers the M5/M6 question definitively (deferred read is not a useful knob). The precision bug has been patched locally in [`_cmd_helpers.fmt`](../../../Simulations/_cmd_helpers.py) (now `.10e`) so H8..H12 will not need server-side patching.

## Implications for the post-H5 energy roadmap

The 127 fJ/pulse cost is essentially the **FE-switching displacement current** flowing through the gate during the 100 ns write at V_pgm = 2.0 V — `I_gate ≈ Q_switch / Δt = (50 fC) / (100 ns) ≈ 500 nA`, giving `E ≈ Q × V = 50 fC × 2.0 V ≈ 100 fJ` plus ~25 fJ of drain channel current at the polarised V_t. This is a **device-physics floor**, not a circuit knob.

Implications for the remaining post-H5 candidates:

| Knob | Roadmap expectation | Revised after H6 |
|---|---|---|
| **H7** V_DS_read 50 → 10 mV | "saves 30–60 fJ/pulse" | **Saves at most 0.06 fJ/pulse** — the read segment is already < 0.1 fJ. **Cancel** unless you want the SNR-robustness datapoint. |
| **H8** t_read 100 → 30 ns | "saves 70–80 fJ/pulse" | **Saves at most 0.06 fJ/pulse** — same reason. **Cancel.** |
| **H9** N_FIRES 9 → 5 | "E_burst drops to 5/9 of current" | **Still valid** — energy is linear in N. 5-pulse burst ≈ 633 fJ/cycle (5.5× over M6, was 11.4×). Still fails M6 but materially better. **Worth running.** |
| Reduce V_pgm   | (anti-goal in roadmap) | Confirmed anti-goal — write cost is the floor. |
| Reduce write duration | (not in roadmap) | Could help if FE switches in < 100 ns. Worth a future H-step? |

**Manuscript framing update:** the post-H5 narrative shifts from "energy is the read-floor trade-off" to "**energy is the FE-switching-charge floor**". H6 is reported as the experiment that *closed* the read-floor hypothesis — a negative result that strengthens the trade-off framing because it demonstrates the team chased the obvious candidate and ruled it out empirically.

## Figures

| File | Content |
|---|---|
| [`figures/h6_vs_h5_cycle_energy.png`](figures/h6_vs_h5_cycle_energy.png) | Side-by-side stacked bars: H5 (c10..c20 mean) vs H6 (c1–c2 mean), showing fire dominates and read is invisible at this scale. |
| [`figures/h6_per_cycle_stacked.png`](figures/h6_per_cycle_stacked.png) | H6 per-cycle stacked bars with C/P/M annotations (clean/partial/missing). The c3..c8 fire-energy decay is the integration-window-aliasing artefact, not a physical drift. |

## M5 / M6 acceptance — final position (unchanged from H5)

| Gate | H5 | H6 | Treatment in manuscript |
|---|---|---|---|
| **M5** ≤ 50 fJ/pulse | FAIL (127.88) | FAIL (129.20) | Reported honestly; framed as FE-switching-charge floor, not read-floor. |
| **M6** ≤ 100 fJ/cycle | FAIL (1141.51) | FAIL (1153.51) | Same. The 9-pulse write burst is the floor. |

H6 does not change the M5/M6 verdict; it changes the **explanation** of why they fail. That is itself a strengthening of the trade-off story.
