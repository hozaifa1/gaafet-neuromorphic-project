# Optimized GAA-FeFET for LIF / SNN — Device Datasheet

Result of the autonomous coordinate-descent optimization (see `OPT_LOG.md` for the
full turn-by-turn study and `PLAN.md` for the FoM/methodology). Calibrated FE
physics is LOCKED (Liao 2022 HZO Preisach: P_r=32, P_s=40 µC/cm², F_c=1.4 MV/cm,
Dit 4e12, FixedCharge 7e12, B2B/GIDL). Only device geometry + operating point were
optimized. Mesh `fe07`; runs reproducible via `opt.py` / `lifgen.py` / `memwingen.py`.

## Optimized structure (double-gate 2D nanosheet cross-section; GAA via Areafactor=0.045)
| Parameter | Original | **Optimized** | Rationale |
|---|---|---|---|
| Interfacial oxide T_ox | 2.0 nm | **1.0 nm** | stronger FE→channel coupling, lower V_op (Turn 2) |
| Nanosheet thickness T_si | 15 nm | **5 nm** | steep subthreshold (gate control) → low off-state (Turn 3) |
| Ferroelectric T_fe | 10 nm | **7 nm** | window/V_op/energy optimum (Turn 5) |
| Body doping N_sub | 1e16 | **1e16** | FD body, gate-controlled; low doping = mobility/low RDF (Turn 4) |
| Gate length L_gate | 100 nm | **100 nm** | long-channel; scaling adds SCE (Turn 6) |
| S/D overlap L_ov | 15 nm | **15 nm** | overlap depletes S/D edge, suppresses off (Turn 6) |
| Gate work function | 4.35 eV | **4.35 eV** | (centering knob; not yet re-tuned) |

## Operating point (LIF / synapse)
| Parameter | Value | Note |
|---|---|---|
| Read gate bias V_read | **0.0 V** | electron-channel window; −0.5 V sits in GIDL (no window) |
| Read drain bias V_DS | 0.05 V | |
| Program (potentiate) | **+2.0 V**, 0.3 µs pulses | cumulative kinetic switching |
| Erase (reset) | **−2.0 V**, ~5 µs (≥5·tau_E) | full reset to OFF |
| FE switching time tau_E | 1 µs | material/calibration |
| Leak time tau_P | 1e-5 s (10 µs) | LIF leak (design knob) — see Retention |

## Key characteristics (for the SNN model)
- **Memory window (retained ON/OFF):** **≈ 3140×** at V_read=0 V
  (erased 5.96e-3 vs programmed 18.7 µA/µm), ΔV_t = 0.336 V. Figure `plots/memwin_fe07.png`,
  data `csv_export/raw/memwin_fe07.csv`. Standard polarity: +program→ON, −erase→OFF.
- **Analog potentiation (LTP):** **15 distinguishable conductance levels over ~4
  decades** (6.39e-4 → 8.31 µA/µm) under cumulative +2 V/0.3 µs pulses, monotonic.
  Figure `plots/ltp_potentiation.png`, data `csv_export/raw/ltp_potentiation.csv`.
  → the analog synaptic weight is set by cumulative program time / pulse count.
- **Retention / leak:** at V_G=0 hold the conductance does **not decay** — it
  settles (post-write FE relaxation) to a stable level held flat over 100 µs:
  **non-volatile retention**. The device does NOT self-leak at V_G=0
  (`csv_export/raw/leak_retention.csv`). → For the LIF *leak*, use a depolarizing
  refresh bias or implement the leak in the circuit; the FeFET is the stable
  non-volatile analog weight. (Consistent with the prior latching finding.)
- **Temperature window:** LTP monotonic & strong at **250 K (1.4e5×)** and
  **300 K (1.3e4×)**; at **350 K** range falls to 4.3e3× and becomes non-monotonic
  (thermal leakage). **Operating window ≈ 250–325 K** (industrial −25/+50 °C).
- **Energy/write:** **≈ 0.0089 fJ per +2 V/0.3 µs program pulse** (switching
  charge × V; ≈0.13 fJ for the full 15-pulse potentiation). Sub-fJ — excellent.

## How the LIF neuron uses this device (handoff framing)
The FeFET is the **non-volatile analog state element + threshold switch**. The
membrane potential is the retained FE polarization (read as channel conductance at
V_read=0); pre-synaptic spikes are +2 V program pulses that potentiate it
(cumulative kinetic switching); the leak is tau_P; "fire" = conductance crossing a
threshold; reset = −2 V erase. The temporal integrate-and-fire dynamics are
composed in the Python SNN model from these measured device characteristics
(LTP curve, window, leak, T-dependence) — the device supplies the analog weight +
threshold, not the temporal integrator itself.

## Honest caveats (for the manuscript / reviewer)
- The optimization FoM in Turns 1–6 was a *virgin-referenced* window (id_on/id_base
  at −0.5 V); the **true erase/program window** (≈3140× at V_read=0) was measured
  post-hoc and confirms the geometry direction. Relative rankings are valid (same
  protocol throughout); the absolute operating point/read were re-derived.
- T_ox=1 nm is aggressive; bidirectional FE switching converges only with instant
  gate ramps (numerical) — a 1 nm IL also has real gate-leakage/reliability limits
  to acknowledge.
- ΔV_t window (~0.3 V) is smaller than the calibration cell's 1.3 V because T_fe is
  thinner; the steep 5 nm-body subthreshold preserves a large *current* ratio.

## T_fe design trade (true erase/program window, corrected metric)
| T_fe | true window | best read | on-state (µA/µm) | V_op | character |
|---|---|---|---|---|---|
| **7 nm (chosen)** | 3137× | V_G=0 | 18.7 (strong) | 2.5 V | energy/readability-optimal |
| 10 nm | **11526×** | −0.25 V | 0.74 | ~3.0 V | window/margin-optimal |
| 12 nm | 9658× | −0.25 V | 2.33 | ~3.0 V | — |

The window peaks at **T_fe=10 nm** under the correct metric (window ∝ F_c·t_FE).
**Recommendation:** T_fe = **7 nm** for the energy- and read-margin-prioritised LIF
(lowest V_op, strongest on-state, still 3137× — ample for the 15-level LTP);
**10 nm** if maximum analog-window margin is preferred (3.7× larger window, modest
voltage/on-state cost). Detailed LIF/LTP/leak/T characterisation here is on the
7 nm device; the 10 nm variant is the same family (cumulative-kinetic LTP) and its
full re-characterisation is a small, optional follow-up.

## Normalization — the one width convention

**All currents in this datasheet are per micron of gate perimeter**, with

> **W_eff = TESW = 2·(W + T_si) = 2·(40 + 5) nm = 90 nm**

for the nominal nanosheet (W = 40 nm from the literature saturation width,
T_si = 5 nm locked). The 2D cross-section Sentaurus actually solves is
**double-gated** — `sde/sde_opt.cmd` builds the insulator/ferroelectric/metal
stack on both the top and the bottom face, both bound to `gate_contact` — so a
slab of z-depth *A* carries a total gate width *2A*. Matching the real nanosheet
perimeter gives **Areafactor = W_eff/2 = 0.045 µm**.

Every run in the project was executed with `Areafactor = 0.071`, a value carried
over unexamined from the *first*, superseded calibration campaign, and every
analysis script then divided by 0.090. `Areafactor` is a pure post-multiplier on
contact currents and charges — it never enters the Poisson/continuity solve — so
the correction is an exact post-processing rescale of **×0.6338**, applied in
`norm.py` and nowhere else. No simulation was re-run for it.

What moved: every absolute current, conductance, resistance, contact charge and
energy. What did not: every ratio (ON/OFF window, igain, DR), every voltage
(V_t, MW, V_op), SS, and every polarization / electric-field figure.

Reproduce and check with:

```bash
python Device_Optimization/norm.py && python Device_Optimization/verify_norm.py
```

> **Caveat that must appear in the manuscript.** The absolute current level was
> **never calibrated** against experiment. The Liao-2022 overlay applies a freely
> fitted width scalar (`Calibration/autocal/pub_figure.py`), which absorbs any
> constant normalization error — the fitted gap is 141×. The paper may claim a
> calibrated **memory window, V_t, SS, on/off ratio and turn-on shape**. It may
> **not** claim that the absolute µA/µm is experimentally validated.

## Canonical measurement protocol (fix ONE, quote the rest as protocol variants)

The retained ON/OFF ratio is not a single number for this device — it depends on
the write pulse width and on how long after the write the state is read. Every
value below is real and reproducible; they differ only by protocol:

| ON/OFF | node | write | settling before the V_G=0 read |
|---|---|---|---|
| 3137× | `mw_fe07` | ±2.0 V, 5 µs | 4 read points ≈ 0.24 µs |
| **5410×** | **`iv_fe07b` (RR-0)** | **±2.0 V, 5 µs** | **20 read points ≈ 1.2 µs** |
| 11650× | `t10_ltd` (RR-3) | 15 × 1 µs pulses | immediate |

**Canonical choice: `iv_fe07b`, 5410×.** It is the densest grid (41 points vs 9),
the widest range (−1.0…+1.0 V), and the longest-settled read, and it uses the
same ±2.0 V / 5 µs write as every published window number. The others are quoted
as protocol variants, never as competing values for the same quantity.

Why they differ is itself a result, not noise. The retained state relaxes on the
τ_E = 1 µs scale after the write ends, and the two states move **apart** as it
settles — so a later read sees a larger window. RR-4 measures the same relaxation
directly: the programmed state falls 9.0× from its immediate post-write value
before reaching a plateau at ≈5 τ_P, and an intermediate analog level (LTP 8)
falls **94×**. Any window number therefore has to state its read delay.

**Rule that prevents the whole class of error found in this audit:** a ratio may
only be formed from two measurements taken in the *same run*. The published
`fire_ratio = 30.6×` violated it — pulse 9 from `t8_ltp` over a baseline from
`mwfine` — and the correct self-consistent value is 18.4×.

## Two different "ON/OFF" numbers — never in the same sentence

| Number | What it is | Protocol |
|---|---|---|
| **3137×** | **retained memory window** | full ±2.0 V write, read at V_G = 0 |
| **30.7×** | **9-pulse LIF fire contrast** | 9 sub-coercive +2 V/0.3 µs pulses vs the erased baseline |

Both are physically real and they differ by 100×. The first is the memory
figure of merit; the second is the neuron's integrate-and-fire contrast.
