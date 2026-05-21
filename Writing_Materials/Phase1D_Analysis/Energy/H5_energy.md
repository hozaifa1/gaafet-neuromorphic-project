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

## Per-segment breakdown — what the cost actually is

Re-binning the same H5 dataset by *segment* (averaged across c10..c20 × 9 pulses = 99 samples) reveals the dominant contributor unambiguously:

| Segment | Wall time | Energy/pulse | % of pulse |
|---|---:|---:|---:|
| `rise`  | 1 ns   | 0.80 fJ   | 0.6 % |
| `write` | 100 ns | **126.72 fJ** | **99.1 %** |
| `fall`  | 1 ns   | 0.28 fJ   | 0.2 % |
| `read`  | 100 ns | **0.08 fJ**   | 0.06 % |
| **Total** | 202 ns | **127.88 fJ** | 100 % |

The 100 ns sub-V_t read at V_GS = −0.5 V draws ~16 pA × 50 mV × 100 ns = 0.08 fJ — three orders of magnitude below the write segment. The 100 ns hold at V_pgm = 2.0 V is **the entire cost**.

## Why M5 / M6 fail and what unlocks the gate

1. **Per-pulse floor is set by the FE-switching displacement current.** The 100 ns hold at V_pgm = 2.0 V passes the polarisation-switching charge Q ≈ 50 fC through the gate (E ≈ Q·V_pgm ≈ 100 fJ) plus ~25 fJ of drain channel current under the polarised V_t. The sub-V_t read at the end of each pulse is **not** the contributor — it adds < 0.1 fJ (see segment table above). This was confirmed empirically by [`H6_deferred_read.md`](H6_deferred_read.md), where removing 8 of 9 reads cut **0 fJ** off the cycle.
2. **9-pulse burst multiplies the per-pulse cost.** A 5-pulse burst at the same V_pgm would land near 71 fJ/pulse on a cycle basis (still over M5 per-pulse, but M6 would be ≈ 633 fJ/cycle). This is the only viable circuit knob — see H9.
3. **V_pgm = 2.0 V is sub-coercive on purpose** (H1 v3 result). Switching to a higher-V_pgm / fewer-pulses regime trades energy for non-monotonic over-switching (cycles failing M2). M5 / M6 vs M1 / M2 / M3 is the *real* trade-off, and the H1 sweep already committed to the integration-friendly side.
4. **M5 / M6 targets were inherited from low-V_DD CMOS-LIF benchmarks** that don't include the FE-switching-charge floor of a polarisation-coupled gate. The honest report is the 128 fJ/pulse / 1.14 pJ/cycle number, with the trade-off articulated in the discussion.

**Manuscript framing:**
> *Per-cycle energy in this design is dominated by the 9-pulse integration burst (1.151 pJ steady-state, V_pgm = 2.0 V). Decomposed by segment, > 99 % of the per-pulse cost is the 100 ns hold at V_pgm — the FE polarisation-switching charge passing through the gate (E ≈ Q_switch · V_pgm). The sub-V_t read contributes < 0.1 % and is not a useful optimisation target (verified empirically in H6, which removed 8 of 9 reads and saved 0 fJ). Reset (10 fJ) and relax (−20 fJ — net dissipative polarisation discharge) are negligible. The M5 / M6 targets, set from low-V_DD CMOS-LIF benchmarks, are not met in absolute terms; reaching them within this device stack would require a shorter write duration (sub-100 ns FE switching) or a smaller burst (5–7 pulses, weakening M1 / M2 margin). The 128 fJ/pulse number is the FE-switching-charge floor for this gate area at this V_pgm and should be reported as such.*

## Figures

| File | Content |
|---|---|
| [`figures/h5_per_cycle_stacked.png`](figures/h5_per_cycle_stacked.png) | Stacked-bar energy per cycle (fire / erase / relax) with M6 100 fJ line. Visually shows fire dominates and steady-state is flat from c3. |
| [`figures/h5_per_pulse_fire.png`](figures/h5_per_pulse_fire.png) | Per-pulse fire energy in c10..c20 with error bars (1 σ across cycles) and M5 50 fJ line. Roughly uniform across the 9 pulses. |

## M5 / M6 acceptance — final position

| Gate | Result | Treatment in manuscript |
|---|---|---|
| **M5** ≤ 50 fJ/pulse | **FAIL** (127.88 fJ) | Reported honestly; framed as **FE-switching-charge floor** of the polarised gate (not a read-floor; H6 falsified the read-floor hypothesis). |
| **M6** ≤ 100 fJ/cycle | **FAIL** (1141.51 fJ) | Same. The 9-pulse write burst is the floor (99 % per-pulse); erase / relax are negligible; read is < 0.1 %. |

Combined with H4 (M1 / M-rest / M2 PASS, M8 = 6.03 % deterministic) the Phase 1D message is: **endurance and analog-fidelity gates close cleanly; the energy budget is the principal trade-off** and should be reported as such.

