# GAA-FeFET LIF Neuron — Device Optimization Campaign

**Goal:** find the device structure + operating point that maximises LIF/SNN
performance, **without touching any calibrated real-world parameter**. Every
decision is made to satisfy a critical top-tier reviewer (IEEE TED / Nature
Electronics / IEDM): physically grounded, fab-realistic, no fitting fudges.

Methodology: **autoresearch coordinate descent** — optimise one knob per turn,
keep the change only if the figure-of-merit (FoM) improves at no cost to the
constraint metrics (Pareto-sane), else revert. Log every candidate in
`results.tsv` (keep/discard/crash), exactly like the autoresearch loop.

---

## LOCKED — calibrated real-world constraints (NEVER change)

These came from the Liao 2022 Fig.7 hysteresis calibration (`cal_n16`) and
represent the real HZO material + real fab interface. Changing them = inventing a
material → instant reviewer rejection.

| Locked | Value | Why locked |
|---|---|---|
| FE remnant/sat polarisation P_r / P_s | 32 / 40 µC/cm² | calibrated HZO Preisach |
| FE coercive **field** F_c | 1.4 MV/cm | calibrated HZO Preisach |
| FE permittivity ε_HZO | 33 | calibrated |
| HZO bandgap / χ | 5.2 / 2.0 eV | material |
| Band-to-band/GIDL Agen/Bgen | 4e16 / 1.9e7 | calibrated real leakage |
| Interface trap Dit (acceptor) | 4e12 cm⁻² @0.45 eV | real fab interface |
| Interface FixedCharge | 7e12 cm⁻² | calibrated (V_t anchor — tune V_t via WF, NOT this) |
| tau_E (FE switching time) | 1e-6 s | material/calibration |

Note F_c is a **field**, not a voltage. Geometry (T_fe, T_ox) legitimately changes
the switching *voltage* V_c via the MFIS capacitor divider while F_c stays fixed —
this is the core, fully-legitimate FeFET design freedom.

---

## FREE — device design + operating knobs (optimise these)

**Block A — operating point (cmd-only, no remesh, fast ~5 min/run):**
| Knob | Baseline | Search range | Lever |
|---|---|---|---|
| V_GS_read | −0.5 V | −0.3 … −1.5 V | rest-current depth → dynamic range |
| Gate work function WF | 4.35 eV | 4.2 … 4.9 eV | V_t recentre → low-V operation |
| V_pgm (operating) | 4.0 V | re-derived per device | drive strength |
| Pulse width t_p | 100 ns | 20 … 200 ns | energy vs switching |
| tau_P (leak) | 1e-5 s | 1e-6 … 1e-3 s | LIF leak time-constant (SNN match) |
| Burst length N | 9 | 3 … 9 | energy/cycle |

**Block B — device geometry/doping (needs sde remesh, ~6 min/run):**
| Knob | Baseline | Search range | Lever |
|---|---|---|---|
| Interfacial oxide T_ox | 2.0 nm | 0.5 … 2.0 nm | depolarisation field → window + retention |
| Ferroelectric T_fe | 10 nm | 5 … 12 nm | V_c / memory window |
| Nanosheet thickness T_si | 15 nm | 5 … 15 nm | gate control → SS, DIBL, rest current |
| Channel/body doping N_sub | 1e16 | 1e15 … 5e17 | V_t, SS, rest current |
| Gate length L_gate | 100 nm | 40 … 100 nm | short-channel vs drive |
| S/D overlap L_ov | 15 nm | 0 … 15 nm | GIDL leakage |

All ranges are fab-realistic for HZO GAA nanosheet FeFETs (reviewer-defensible).

---

## Figure of Merit (FoM)

The device is a **leaky-integrate-and-fire neuron**: gate spikes (V_pgm, t_p)
accumulate FE polarisation → V_t shift → retained read-current ("membrane
potential"); tau_P leaks it; "fire" = read current crossing threshold.

**Per-candidate evaluation** = a sub-coercive LIF pulse-train characterisation
(9 × t_p pulses at V_pgm, post-pulse reads at V_GS_read), run over a small V_pgm
set so the candidate's *own* operating point emerges. Extracted:

- **DR — dynamic range** = ID(p9) / ID(baseline) at the operating point  ← PRIMARY
- **V_op** — lowest V_pgm giving clean sub-coercive graded integration
  (|E_FE|/F_c ∈ [0.7, 0.95], monotone-rising p5→p9)
- **E_spike** — gate write energy per pulse (∫ V·I dt)  ← minimise
- **ID_rest** — baseline read current (static leak)  ← minimise
- **|E|/F_c** — confirm sub-coercive (LIF-analog, not digital)

**Primary objective:** maximise DR. **Constraints / co-objectives (reviewer
priorities):** lower V_op, lower E_spike, lower ID_rest, clean graded integration,
sub-coercive operation. A change is **kept** if it improves DR without worsening
V_op/E_spike (or improves those at equal DR) — a Pareto improvement. Ties broken
by "what would the toughest reviewer prefer": lower energy + lower voltage at
adequate DR (≥ ~10× enables clean multi-level) wins.

Robustness gates (run on the final optimised device, not per-candidate):
endurance drift, retention, C2C variability, temperature window, analog levels.

---

## Optimisation order (cheap → expensive, decoupled first)

1. **V_GS_read** — biggest cheap DR lever (no remesh).
2. **WF** — recentre V_t for low-V operation (no remesh).
3. **T_ox** — depolarisation/retention (remesh).
4. **T_fe** — V_c / window (remesh).
5. **T_si** — electrostatics / rest current (remesh).
6. **N_sub** — V_t / SS / rest current (remesh).
7. **L_gate**, **L_ov** — SCE / GIDL (remesh).
8. **t_p / tau_P / N** — electrical fine-tune on the winner.
9. **Re-derive operating point + robustness gates** on the optimised device.

After each block, re-check couplings (re-run an earlier cheap knob if a geometry
change moved its optimum). Final device = the kept-everything configuration.

## Harness

- `sde/sde_opt.cmd` — parametric GAA geometry (tokens @T_SI@ @T_OX@ @T_FE@
  @T_METAL@ @L_GATE@ @L_SD@ @L_OV@ @N_SUB@ @N_SD@ @NODE@).
- `lif_eval.cmd` — LIF pulse-train characterisation (tokens @TDR@ @PAR@ @NODE@
  @WF@ @VREAD@ @VPGM@ @TP@ ...).
- `par/app.par` — calibrated par (token @TAU_P@ only).
- `opt.py` — driver: render → upload → sde mesh → sdevice → download → analyse →
  FoM. `results.tsv` — keep/discard log.
- Remote: `du@103.28.121.70:~/Sentaurus-files/Sami_Hozaifa/GAAFet/`, single
  sdevice license (serial), drive via plink/pscp.
