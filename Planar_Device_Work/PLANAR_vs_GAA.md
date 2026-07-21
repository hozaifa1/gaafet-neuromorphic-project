# Planar vs GAA FeFET — LIF / SNN characteristic comparison

Both devices use the **identical calibrated FE + interface physics** (Liao 2022 HZO
Preisach: P_r=32 / P_s=40 µC/cm², F_c=1.4 MV/cm, ε_HZO=33, Dit 4e12, FixedCharge
7e12, Band2Band/GIDL). **No re-calibration** — the planar simply inherits the locked
`.par`. The only difference is **device architecture + geometry**, so every gap below
is attributable to electrostatics, not material fitting.

## Structure

| | GAA (double-gate nanosheet) | Planar (bulk, single top gate) |
|---|---|---|
| Gate | wrap-around (2D double-gate, Areafactor=0.071) | single **top** gate only |
| Body | 5 nm nanosheet (both sides gated) | 50 nm **bulk** p-body (5e17), grounded substrate |
| IL SiO2 / HZO | 1 nm / 7 nm | 2 nm / 10 nm |
| L_gate / S-D | 100 nm / n+ 5e19 | 100 nm / n+ 5e19 |

## Characteristics (both at their own re-derived operating point)

| Metric | GAA | Planar | Winner |
|---|---|---|---|
| Operating V_pgm | **+2.0 V** | +4.5 V | **GAA** (2.25× lower drive) |
| ON/OFF memory window @Vg=0 | 3 137× | **5.9×10⁶×** | Planar (raw window) |
| R_off (erased read) | 7.14×10⁷ Ω | 1.22×10⁹ Ω | — |
| R_on (programmed read) | 2.34×10⁶ Ω | 2.06×10² Ω | — |
| g_min = 1/R_off | 1.40×10⁻⁸ S | 8.22×10⁻¹⁰ S | — |
| g_max = 1/R_on | 4.27×10⁻⁷ S | 4.86×10⁻³ S | — |
| **Analog LTP levels** | **15** (smooth log) | 8 (abrupt) | **GAA** (2× finer analog) |
| LTP character | gradual, log-linear over all 15 pulses | dead 7 pulses → near-digital snap | **GAA** |
| Energy / program pulse (per µm)† | ~1.4×10⁻¹⁷ J* | 6.85×10⁻¹³ J | **GAA** |
| Fire ratio ID(p9)/ID_base | 30.6 | 1.0×10⁵ | Planar (deep-off floor) |
| Retention (100 µs hold) | non-volatile plateau | non-volatile plateau (settles to 68% of peak) | tie (both latch) |
| Gate-controllability of ON state | ON switches off within read window | **latched** (stays ON to Vg=−1 V) | **GAA** |

## Interpretation

The comparison is **not** one-sided — it splits cleanly along the memory-vs-analog axis:

- **Planar wins raw non-volatile window** (5.9×10⁶× vs 3 137×). Thicker HZO (10 nm →
  larger switched charge → larger ΔV_t) on a **deep-off bulk body** gives an enormous
  erase/program ratio. But the programmed branch is **latched ON across the entire
  read window** (still 154 µA/µm at V_G=−1 V) — a great *digital memory*, a poor
  *analog transistor*.

- **GAA wins every neuromorphic-relevant axis.** Its superior wrap-around electrostatics
  give (1) **2.25× lower operating voltage** (2 V vs 4.5 V), (2) a **smooth 15-level
  log-linear LTP** vs the planar's dead-then-snap quasi-digital transfer (see
  `plots/compare_ltp.png`), (3) far lower per-pulse energy, and (4) a fully
  **gate-controllable** ON state. For a leaky-integrate-and-fire synapse — where the
  value is *graded* analog potentiation at low voltage/energy — the GAA is decisively
  better.

**Bottom line for the ECG-LSNN:** the GAA's 15 finely-spaced conductance levels at 2 V
are what the STE-quantized synapse wants; the planar delivers only ~8 abrupt levels and
needs 4.5 V. The planar's giant window does not translate into analog resolution.

## Caveats

- †**Energy method differs.** Planar E is a rigorous ∫V·I dt over each write pulse;
  the GAA number (\*) is the earlier `Q_switch × V` order-estimate from
  `SNN_PARAMETERS.md`. Also GAA reports with Areafactor=0.071 vs planar 1.0. Absolute
  energies are therefore method- and area-scaled; the **direction** (planar >> GAA per
  pulse, driven by 4.5 V vs 2 V) is robust. Ratios (window, fire, levels) are
  Areafactor-invariant and directly comparable.
- Planar operating point re-derived independently (V_read=0, V_pgm sweep 3.5/4.5/5.5 →
  4.5 V picked for clean graded integration + fire-at-p9, matching the GAA criterion).

## Files
- Plots: `plots/compare_memwin.png`, `plots/compare_ltp.png`, `plots/compare_retention.png`
- ECG-LSNN drop-in params: `planar_params.py` (g_min / g_max / n_levels / energy)
- Full planar datasheet: `PLANAR_DEVICE.md`
- Raw TCAD: `outputs/planar/` (memwin), `outputs/lifsw/` (LTP sweep), `outputs/lifret/` (retention)
