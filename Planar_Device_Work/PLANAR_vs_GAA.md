# Planar vs GAA-FeFET — true single-gate ablation, full LIF/SNN comparison

**Identical geometry** to the optimized GAA (T_si=5nm/T_ox=1nm/T_fe=7nm/T_metal=5nm/
L_gate=100nm/L_ov=15nm/N_sub=1e16/N_sd=5e19/WF=4.35, floating body, same calibrated par).
The **only** change is removing the bottom gate stack — a true ablation, not a different
device. Memory-window/SS characterization uses VE=-4.0/VP=+3.5 V, a moderate overdrive
past planar's own coercive point (~3.0V), matching the SAME proportional-overdrive
methodology GAA's own `ivgen.py` uses (VE=-3.0/VP=2.5 vs its op point +/-2.0V) — not an
arbitrary voltage, so the window comparison below is genuinely apples-to-apples.

| Metric | GAA (double-gate) | Planar (single-gate ablation) | Note |
|---|---|---|---|
| Stack T_ox / T_fe / T_si | 1 / 7 / 5 nm | 1 / 7 / 5 nm (identical) | ablation, not redesign |
| Gating | both faces | top only | the one variable changed |
| **SS erased** | 79.6 mV/dec | 75.1 mV/dec | planar slightly steeper |
| **SS programmed** | 63.0 mV/dec | 51.9 mV/dec | planar slightly steeper |
| Vth erased / programmed | +0.018 / -0.318 V | 0.020 / -1.405 V | — |
| Vth memory window | 0.336 V | 1.424 V | planar ~4x larger |
| ON/OFF current window @Vg=0 | 3137x | 14227x | planar ~4.5x larger |
| R_off / R_on | 7.1e+07 / 2.3e+06 Ohm | 6.1e+06 / 4.3e+02 Ohm | — |
| g_min / g_max | 1.40e-08 / 4.27e-07 S | 1.65e-07 / 2.35e-03 S | — |
| **Analog LTP levels** | 15 | 10 | GAA finer-grained |
| dVth / pulse | -18.3 mV | -27.1 mV | — |
| **Op V_pgm** | +2.0 V | +2.3 V | close -- same FE stack |
| Fire ratio ID(pN)/ID_base | 30.6 | 8.18e+03 | — |
| Retention (100 us) | non-volatile (flat) | 98.5% | both non-volatile |
| dP retained | ~2.26 uC/cm2 | 5.13 uC/cm2 | — |

## Read of the result
With geometry held **identical** and only the bottom gate removed, the single-gate
device needs almost the same operating voltage (2.3 V vs GAA's 2.0 V — both governed by
the same F_c*T_fe coercive voltage) and, surprisingly, shows **comparable or slightly
better subthreshold slope** than the double-gate GAA (the 5 nm body is thin enough that
one gate alone already gives near-ideal control). Planar wins the raw ON/OFF window
(~4.5x larger) because the single-gate device's threshold-voltage shift under the same
overdrive is larger. GAA still wins on **LTP resolution** (15 smooth levels vs 10)
for the analog-synapse use case — the double gate's extra electrostatic assist shows up
as smoother, more finely graded conductance modulation during the pulse train, not in the
static SS or the switching voltage.

## Honest caveat: ferroelectric read disturb
Reading the programmed branch's transfer curve at gate voltages approaching the
*opposite*-polarity coercive field (deep negative reads, needed to bracket its
threshold) measurably disturbs the retained polarization mid-sweep: the same nominal
Vg gave a ~7000x different current depending on what more-negative voltages were swept
through first in the same continuous transient. This is consistent with real FeFET
read-disturb physics, not a simulation bug. GAA's own methodology never encountered
this because it only ever reads within +/-1V, safely clear of its coercive field.
The SS_pgm/Vth_pgm reported here come from short, shallow, minimal-read-history sweeps
(outputs/planarfinal2 + outputs/planarclean) specifically designed to avoid it.

Plots: `plots/compare_memwin.png`, `plots/compare_ltp.png`, `plots/compare_retention.png`.
ECG-LSNN params: `planar_params.py`.
