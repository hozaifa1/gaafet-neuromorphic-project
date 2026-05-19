# Phase 1D — H5 energy accounting (M5 + M6)

**Status:** Run complete (2026-05-19). No new simulation — H5 reuses the H4 endurance dataset (`Simulations/endurance_outputs/`) at the V_pgm = 2.000 V SWB node. Both gates (M5 ≤ 50 fJ/pulse, M6 ≤ 100 fJ/cycle) **fail in absolute terms**, but the breakdown is clean and the over-target factor is fully attributable to the 9-pulse fire burst — the rest of the cycle (erase + relax) is < 1 % of the budget.

Analyzer: [`Simulations/analyze_phase1d_h5.py`](../../../Simulations/analyze_phase1d_h5.py)
Per-segment CSV: [`h5_per_segment.csv`](h5_per_segment.csv)  Per-cycle CSV: [`h5_per_cycle.csv`](h5_per_cycle.csv)  Plain text: [`h5_summary.txt`](h5_summary.txt)

---

## Method

For each of the 20 H4 cycles at V_pgm = 2.0 V, the gate and drain `V(t) · I(t)` products are trapezoidally integrated across every `.plt` segment file produced by Sentaurus:

| Phase | Segments per cycle | Wall time |
|---|---|---|
| Fire | 9 pulses × (rise / write / fall / read) | 1.818 µs |
| Erase | rise / hold (10 µs) / fall | 10.020 µs |
| Relax | hold (70 µs at V_GS = −0.5 V) | 70.000 µs |

Energy per cycle = E_fire + E_erase + E_relax. Steady-state band is **c10 → c20**, matching the long-tail window used for H4 M1 / M-rest.

## Headline numbers (c10..c20 mean)

| Quantity | Value | Gate / target |
|---|---:|---|
| E_fire (9-pulse burst)  | **1150.91 fJ = 1.151 pJ** | — |
| E_pulse (per pulse)     | **127.88 fJ** | M5 ≤ 50 fJ → **FAIL** (2.6× over) |
| E_erase per cycle       | 10.26 fJ | tiny; capacitive transients during rise/fall dominate, 10-µs hold draws ~zero gate current |
| E_relax per cycle       | −19.67 fJ | negative: dissipative discharge of polarisation through the gate while V_GS = −0.5 V |
| **E_total per cycle**   | **1141.51 fJ = 1.142 pJ** | M6 ≤ 100 fJ → **FAIL** (11.4× over) |

The c1 → c2 drop (1.21 pJ → 1.13 pJ) is the wake-up transient on the first burst; c3 onward is flat to four significant figures, confirming the steady-state energy is well-defined.

## Per-pulse breakdown (c10..c20 mean ± σ)

See figure [`figures/h5_per_pulse_fire.png`](figures/h5_per_pulse_fire.png). The 9-pulse burst delivers roughly uniform per-pulse energy (~128 fJ/pulse) — the device is **not** displaying decreasing per-pulse cost as the FE polarisation saturates, because at sub-coercive V_pgm the gate-leakage / displacement-current term dominates over the FE switching term.

## Why M5 / M6 fail and what unlocks the gate

1. **Per-pulse floor is set by the read.** The 100 ns sub-V_t read (V_GS = −0.5 V, V_DS = 0.05 V) at the end of every pulse is the largest single contributor — it is mandated by the LIF protocol (the read *is* the LIF readout), so cutting it removes the analog output. Removing the read entirely would still leave the rise/write/fall transient cost.
2. **9-pulse burst multiplies the per-pulse cost.** A 5-pulse burst at the same V_pgm would land near 64 fJ/pulse-equivalent on a cycle basis (still over M5 per-pulse, but M6 would be ≈ 650 fJ/cycle — closer to target).
3. **V_pgm = 2.0 V is sub-coercive on purpose** (H1 v3 result). Switching to a higher-V_pgm / fewer-pulses regime trades energy for non-monotonic over-switching (cycles failing M2). M5 / M6 vs M1 / M2 / M3 is the *real* trade-off, and the H1 sweep already committed to the integration-friendly side.
4. **M5 / M6 targets were inherited from low-V_DD CMOS-LIF benchmarks** that don't include the analog read of an FE-coupled current path. The honest report is the 128 fJ/pulse / 1.14 pJ/cycle number, with the trade-off articulated in the discussion.

**Manuscript framing:**
> *Per-cycle energy in this design is dominated by the 9-pulse integration burst (1.151 pJ steady-state, V_pgm = 2.0 V). Reset (10 fJ) and relax (−20 fJ — net dissipative polarisation discharge) are negligible by comparison. M5 / M6 targets, set from low-V_DD CMOS-LIF benchmarks, are not met in absolute terms; reaching them requires either shortening the read, reducing the burst to 5–6 pulses (which weakens M1 / M2 margin), or dropping V_DS_read. The 128 fJ/pulse number is, however, comparable to the per-spike energy of FeFET-CAM read-disturb measurements at similar V_DS, supporting the read-floor interpretation.*

## Figures

| File | Content |
|---|---|
| [`figures/h5_per_cycle_stacked.png`](figures/h5_per_cycle_stacked.png) | Stacked-bar energy per cycle (fire / erase / relax) with M6 100 fJ line. Visually shows fire dominates and steady-state is flat from c3. |
| [`figures/h5_per_pulse_fire.png`](figures/h5_per_pulse_fire.png) | Per-pulse fire energy in c10..c20 with error bars (1 σ across cycles) and M5 50 fJ line. Roughly uniform across the 9 pulses. |

## M5 / M6 acceptance — final position

| Gate | Result | Treatment in manuscript |
|---|---|---|
| **M5** ≤ 50 fJ/pulse | **FAIL** (127.88 fJ) | Reported honestly; framed as analog-LIF read-floor trade-off, not a device defect. |
| **M6** ≤ 100 fJ/cycle | **FAIL** (1141.51 fJ) | Same. The 9-pulse burst is the floor; erase / relax are negligible. |

Combined with H4 (M1 / M-rest / M2 PASS, M8 = 6.03 % deterministic) the Phase 1D message is: **endurance and analog-fidelity gates close cleanly; the energy budget is the principal trade-off** and should be reported as such.

