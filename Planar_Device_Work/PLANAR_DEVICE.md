# Bulk Planar FeFET — LIF / SNN Device Datasheet

Comparison device for the GAA-vs-planar LIF study. **No calibration** — inherits the
locked calibrated FE + interface `.par` verbatim (`par/app_planar.par`, from the Liao
2022 HZO Preisach cal). Geometry-only difference vs the optimized GAA nanosheet.
Mesh `planar_msh.tdr`; reproducible via `planar.py` (`mesh` / `mw` / `lif`) +
`gen_planar.py`.

## Structure (bulk planar NMOS FeFET, single top MFIS gate)
| Parameter | Value | Note |
|---|---|---|
| Interfacial oxide T_ox | 2.0 nm | SiO2 |
| Ferroelectric T_fe | 10 nm | HZO (window-optimal thickness) |
| Gate metal T_metal | 5 nm | TiN |
| Body | 50 nm **bulk** p-Si | boron N_sub = 5e17 cm⁻³ |
| Substrate contact | grounded (0 V) | bottom body electrode |
| S/D | n+ arsenic 5e19 | 25 nm junction depth, 15 nm gate overlap |
| Gate length L_gate | 100 nm | |
| Gate work function | 4.35 eV | |
| Areafactor | 1.0 | per-µm-width (vs GAA 0.071) |

## Operating point (re-derived for planar)
| Parameter | Value | Note |
|---|---|---|
| Read gate V_read | **0.0 V** | erased deep-off at Vg=0 |
| Read drain V_DS | 0.05 V | |
| Program (potentiate) | **+4.5 V**, 0.3 µs pulses | sub-coercive graded integration, fire ~p9 |
| Erase (reset) | **−6.0 V**, ~5 µs | full reset to deep-off |
| FE switching tau_E | 1 µs | material/calibration (locked) |
| Leak tau_P | 1e-5 s | LIF leak (design knob, same as GAA) |

Op point chosen from a V_pgm sweep {3.5, 4.5, 5.5} V: 3.5 V too gradual (fires late),
5.5 V too abrupt (fires ~p7), **4.5 V** gives clean graded p1→p8 integration then
fire at p9 — matching the GAA fire-at-P9 criterion.

## Key characteristics (mesh planar)
- **Memory window (retained ON/OFF) @Vg=0:** **≈ 5.9×10⁶×** (erased 4.1×10⁻⁵ vs
  programmed 243 µA/µm). The programmed branch is **latched ON across the whole read
  window** (154 µA/µm even at Vg=−1 V) → non-volatile, quasi-digital. Data
  `outputs/planar/mw_planar_analysis.json`, plot `plots/compare_memwin.png`.
- **Analog potentiation (LTP):** **8 distinguishable levels**; dead for pulses 1–7
  (sub-coercive, no accumulation) then a sharp near-digital turn-on p8→p15
  (1.7×10⁻³ → 156 µA/µm). Much more abrupt than the GAA's smooth 15-level log-linear
  ramp. Plot `plots/compare_ltp.png`, data `outputs/lifsw/lifsw_lif.json`.
- **Retention / leak:** post-write FE relaxation transient peaks ~176 µA/µm at 2.5 µs,
  then settles to a **stable non-volatile plateau ~105 µA/µm** by ~40 µs (≈68% of
  peak), flat to 100 µs → non-volatile. Plot `plots/compare_retention.png`,
  data `outputs/lifret/hold_lifret_v045_des.plt`.
- **Energy / write:** **≈ 6.85×10⁻¹³ J per +4.5 V/0.3 µs pulse** (∫V·I dt over the
  gate, mean over 15 write pulses, per µm). Higher than the GAA (lower voltage +
  thinner stack) — see energy caveat in `PLANAR_vs_GAA.md`.

## SNN parameters (drop-in for the ECG-LSNN stage1)
See `planar_params.py`. Core coupling to `fefet_synapse.py`:
`g_min = 8.22×10⁻¹⁰ S`, `g_max = 4.86×10⁻³ S`, `n_levels = 8`.

## Honest caveats (for the manuscript / reviewer)
- The huge window is real but is a **digital-memory** trait, not analog resolution:
  the programmed device cannot be turned off by the read gate in [−1, +1] V.
- Energy comparison to GAA mixes methods (∫V·I dt here vs Q_switch×V for GAA) and
  Areafactor (1.0 vs 0.071); treat absolute energy as order-of-magnitude, ratios as
  exact. See `PLANAR_vs_GAA.md`.
- Single-domain Preisach, 2D cross-section, T_ox=2 nm gate-leak/reliability not
  modeled — same modeling envelope as the GAA study (fair comparison).
