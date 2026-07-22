# Planar vs GAA-FeFET — full LIF/SNN characteristic comparison

Same calibrated FE/interface physics (Liao HZO Preisach P_r=32/P_s=40, F_c=1.4 MV/cm,
eps=33, Dit 4e12, FixedCharge 7e12, GIDL/B2B). **Geometry-only** difference — no re-calibration.

| Metric | GAA (double-gate 5 nm nanosheet) | Planar (bulk, single top gate) | Winner |
|---|---|---|---|
| Stack T_ox / T_fe | 1 nm / 7 nm | 2 nm / 10 nm | — |
| Body / gating | 5 nm sheet, gated both sides | 50 nm bulk, gated one side | — |
| **SS (erased)** | 79.6 mV/dec | 98.4 mV/dec | **GAA** (steeper) |
| Vth window (volts) | 0.336 V | >1.94 V | Planar (larger) |
| ON/OFF current window @Vg=0 | 3137x | 5.91e+06x | Planar (larger) |
| R_off / R_on | 7.1e+07 / 2.3e+06 Ω | 1.2e+09 / 2.1e+02 Ω | — |
| g_min / g_max | 1.40e-08 / 4.27e-07 S | 8.22e-10 / 4.86e-03 S | — |
| **Analog LTP levels** | 15 | 8 | **GAA** (finer) |
| dVth / pulse | −18.3 mV | -46.0 mV | — |
| **Op V_pgm** | +2.0 V | +4.5 V | **GAA** (lower) |
| E / program pulse | ~1.4e-17 J* | 6.85e-13 J* | GAA (lower) |
| Fire ratio ID(p9)/ID_base | 30.6 | 1.02e+05 | Planar (raw) |
| Retention (100 µs) | non-volatile | 68% | — |
| ΔP retained | ~2.26 µC/cm² | 3.89 µC/cm² | — |

\* Energy numbers are **not directly comparable**: GAA used charge×V with Areafactor=0.071;
planar uses ∫V·I dt with Areafactor=1.0 (~14× normalization + method difference). Directionally
planar costs more per pulse (3× voltage, thicker/larger FE). Re-extract both identically before quoting.

## Read of the result
The thick-T_fe bulk planar wins **raw window** (huge Vth shift, latches fully ON across
the read range) but at the cost of everything that matters for an **analog LIF neuron**:
3× the program voltage, worse subthreshold control (single-gate bulk), coarser/fewer
gradual conductance levels, and higher switching energy. The GAA nanosheet is the better
neuromorphic device; the planar is a stronger *binary* memory but a worse *analog synapse*.

Plots: `plots/compare_memwin.png`, `plots/compare_ltp.png`, `plots/compare_retention.png`.
ECG-LSNN params: `planar_params.py`.
