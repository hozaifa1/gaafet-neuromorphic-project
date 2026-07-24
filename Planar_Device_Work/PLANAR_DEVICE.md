# Planar FeFET — True Single-Gate Ablation Datasheet

Comparison device for the GAA-vs-planar LIF study. **A true ablation**, not a redesign:
identical geometry, doping, work function, and calibrated `.par` to the optimized GAA
nanosheet (`Device_Optimization/sde/sde_opt.cmd`) — the *only* change is deleting the
bottom gate stack. No calibration change. Mesh `planar_msh.tdr`; reproducible via
`planar.py` (`mesh` / `mw` / `lif` / `iv`) + `gen_planar.py`.

## Structure (single top-gate ablation of the GAA nanosheet)
| Parameter | GAA (double-gate) | Planar (this device) |
|---|---|---|
| Interfacial oxide T_ox | 1.0 nm | **1.0 nm (identical)** |
| Nanosheet/body thickness T_si | 5 nm | **5 nm (identical)** |
| Ferroelectric T_fe | 7 nm | **7 nm (identical)** |
| Gate metal T_metal | 5 nm | **5 nm (identical)** |
| Gate length L_gate | 100 nm | **100 nm (identical)** |
| S/D overlap L_ov | 15 nm | **15 nm (identical)** |
| Body doping N_sub | 1e16 | **1e16 (identical)** |
| S/D doping N_sd | 5e19 | **5e19 (identical)** |
| Gate work function | 4.35 eV | **4.35 eV (identical)** |
| Body | floating (no substrate contact) | **floating (identical)** |
| Gating | top AND bottom stack, tied to one gate_contact | **top only** — the ablation |
| Areafactor | 0.071 (double-gate-emulating-GAA-wraparound fudge) | **1.0** (no wraparound to emulate with one gate) |

Earlier iterations of this device (now superseded) used a bulk 50nm body, T_ox=2nm,
T_fe=10nm, and a grounded substrate contact — that was a *different device*, not an
ablation, and its results have been fully replaced.

## Operating point (re-derived for the single-gate electrostatics)
| Parameter | Value | Note |
|---|---|---|
| Read gate V_read | **0.0 V** | same convention as GAA |
| Read drain V_DS | 0.05 V | |
| Program (potentiate) | **+2.3 V**, 0.3 µs pulses | lowest V in the clean-graded-LTP set {2.3,2.6,2.9}; matches GAA's own "lowest V wins" rule |
| Erase (reset) | **−3.5 V**, ~5 µs | full reset |
| FE switching tau_E | 1 µs | material/calibration (locked) |

Removing the bottom gate needs only slightly more program voltage than GAA (2.3 V vs
2.0 V) — expected, since both devices share the identical F_c·T_fe coercive-voltage
requirement; the single gate alone must supply the entire depletion/inversion charge
without the bottom-gate assist.

## Key characteristics (mesh `planar`)
- **Subthreshold slope:** erased **75.1 mV/dec**, programmed **51.9 mV/dec** (clean,
  minimal-read-history sweep) — both *slightly steeper* than GAA (79.6 / 63.0 mV/dec).
  The 5 nm floating body is thin enough that single-gate control is already
  near-ideal; the second gate doesn't buy much static subthreshold slope here.
- **Threshold-voltage memory window:** Vth_ers = +0.020 V, Vth_pgm = −1.405 V →
  **MW = 1.42 V** (vs GAA's 0.336 V) — planar's larger single-gate-driven Vt shift
  under a proportionally-matched overdrive (VE=−4.0/VP=+3.5 V, the same "moderate
  overdrive past its own coercive point" methodology GAA's own `ivgen.py` uses).
- **ON/OFF current window @ V_read=0:** **≈ 14,227×** (erased 8.2e-3 vs programmed
  117.3 µA/µm) — vs GAA's 3137×, a genuine ~4.5× advantage under matched methodology
  (earlier, wrong ±5V characterization had wrongly inflated this to 5.9×10⁶×).
- **Analog potentiation (LTP):** **10 distinguishable levels** over a ~5-decade
  smooth log-linear ramp across 15 pulses at V_pgm=+2.3 V — qualitatively very similar
  shape to GAA's own 15-level ramp (see `plots/fig_analog_resolution.png`), just fewer
  resolvable levels (planar's larger per-pulse ΔVth means fewer 1.5×-separated steps
  fit in the same current range).
- **Retention:** **98.5%** of the post-write current retained over 100 µs hold
  (settles to a flat non-volatile plateau after an initial relaxation peak) — even
  better than GAA's, consistent with a clean floating body and no extra leakage path.
- **Energy/write:** ≈ 3.0×10⁻¹³ J per +2.3 V/0.3 µs program pulse (∫V·I dt, per µm,
  Areafactor=1.0) — not directly comparable to GAA's charge×V/Areafactor=0.071 number
  without re-extracting both identically (methods and per-width normalization differ).

## SNN parameters (drop-in for the ECG-LSNN stage1)
See `planar_params.py`. Core coupling to `fefet_synapse.py`:
`g_min = 1.65e-7 S`, `g_max = 2.35e-3 S`, `n_levels = 10`.

## Important methodological finding: ferroelectric read disturb
Sweeping the programmed branch's transfer curve through gate voltages approaching the
*opposite*-polarity coercive field (needed to bracket Vth_pgm, since planar's Vth_pgm
sits near −1.4 V while GAA never needed to read past ±1 V) measurably **disturbs the
retained polarization mid-sweep**: the same nominal V_g gave a ~7000× different read
current depending on what deeper-negative voltages were swept through first in the
same continuous transient. This is consistent with genuine FeFET read-disturb
physics (well documented in the literature), not a simulation artifact — but it means
a naive single continuous multi-point sweep is NOT a reliable way to characterize a
threshold that sits close to the coercive field. The SS_pgm/Vth_pgm reported here
come from short, shallow, minimal-read-history sweeps (`outputs/planarfinal2` +
`outputs/planarclean`) specifically designed to avoid it; the contaminated combined
sweep (`outputs/planarfinal`) is kept only for the Vg=0 window/SS_ers extraction,
which sits far from the disturb-sensitive region.

## Honest caveats (for the manuscript / reviewer)
- Energy comparison to GAA mixes Areafactor (1.0 vs 0.071) and, in earlier drafts,
  extraction method; re-extract identically before quoting an energy ratio.
- Single-domain Preisach, 2D cross-section — same modeling envelope as the GAA study.
- The read-disturb finding above is itself a reportable result about FeFET reliability
  near the coercive field, not just a methodology footnote.

## Figure set (paper-quality, generated by `plot_planar.py`)
- **`plots/fig_analog_resolution.png`** — KEY: GAA vs planar analog conductance-level
  resolution. GAA spreads its 15 pulses smoothly over ~4 decades (finer, even log-steps);
  planar is flat-then-abrupt (coarser). This is the load-bearing reason to prefer GAA.
- **`plots/fig_lif_neuron.png`** — the planar device operating as a LIF integrate-and-fire
  neuron: read current = membrane potential, program pulses = input spikes, fire = crossing
  2x the erased baseline.
- **`plots/fig_step_granularity.png`** — per-pulse conductance step; the mechanism behind
  the resolution difference (GAA small uniform steps, planar few large jumps).
- **`plots/fig_transfer.png`** — planar retained-state transfer (SS extraction).
- **`plots/fig_memory_window.png`** — GAA vs planar retained ON/OFF window.
- **`plots/fig_retention.png`** — non-volatile retention (% of settled state; flat = no decay
  for both; the absolute-current height difference is drive strength, not retention).
