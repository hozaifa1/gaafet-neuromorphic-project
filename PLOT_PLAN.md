# GAA-FeFET Paper — Normalization Audit + Master Figure Plan

Supersedes `Paper-materials/PLOT_PLAN.md`.

Two parts:
- **Part I–II** — code-level audit of `Calibration/` and `Device_Optimization/`
  (Areafactor / width normalization, and everything else that disagrees).
  Every claim below is traced to a line of `.cmd`, `.par`, or `.py` — **no `.md`
  file was trusted as a source**; several are shown to be wrong.
- **Part III–V** — the comprehensive figure catalog (79 figures), the re-run list,
  and the phased TODO.

Device: optimized GAA-FeFET, mesh `fe07` — T_ox=1 nm / T_fe=7 nm HZO / T_si=5 nm /
T_metal=5 nm / L_gate=100 nm / L_ov=15 nm / N_sub=1e16 / N_sd=5e19 / WF=4.35 eV.
2D double-gate nanosheet cross-section (`Device_Optimization/sde/sde_opt.cmd`).


---

# ERRATA — corrections found while executing Phases 1–5 (2026-08-01)

Three claims in Parts I–II were checked against the data and did not survive.
They are corrected here; the body below is left as written so the audit trail is
intact.

**E1 — C1 is wrong about `transfer_curves.csv`.** It does NOT come from the
`iv_fe07` node and therefore never inherited `app_frozen.par`. It is reproduced
bit-for-bit from the **`mwfine`** node (19 fixed-V_G point reads, −0.4…+0.5 V),
and `runs/mwfine_fe07_des.cmd` uses `app_opt.par` like everything else. So there
is **no τ protocol split** behind `Vth_virgin`, `Vth_fire`, `SS` or `MW`, and the
21 % "erased at V_G=0" gap in C2 is not a par difference — it is two runs of the
same protocol with different read-point schedules (`mwfine` walks 19 read points,
`mw_fe07` walks 9), so the retained state creeps by a different amount between
them. Verified in `csv_export/rebuild_raw.py`, which regenerates every raw CSV
from its source `.plt`.

**E2 — the `iv_fe07` node is not merely "run under a different par", it is dead.**
`app_frozen.par` sets τ_E = τ_P = 1e-4, so `ivgen.py`'s 500 µs write hold is *five
depolarization time constants*: whatever the field switches, the model relaxes
back inside the same hold. The probe reads

```
Pos(0,0.007) Polarization/y = +2.3267e-07 C/cm²  (erased)
                            = +2.3238e-07 C/cm²  (programmed)
```

— 0.1 % apart, against a P_r of 3.2e-5 — and the two I–V branches coincide above
V_G = +0.2 V. `raw/memory_window_iv.csv` (figure **D1**) descends entirely from
that node and was meaningless. RR-0 is therefore not a tidy-up, it is a repair.
The replacement (`ivgen.py`, rewritten; node `iv_fe07b`) keeps `memwingen`'s
proven ±2 V / 5 µs write and reads with one continuous 500 ns ramp, analysed on
the **conduction** current (eCurrent + hCurrent) so the fast ramp's displacement
term through the 15 nm overlap is removed exactly rather than argued away.
`par/app_frozen.par` is renamed `app_frozen.CALIBRATION_PROTOCOL_ONLY.par` with
the reason on its first line.

**E3 — RR-5 cannot measure endurance, and the caption must say so.** The
Sentaurus Preisach model has no fatigue, no wake-up and no imprint term. Cycling
it 10⁴ times cannot close the window: a flat curve is a property of the model,
not evidence about the device. What the run legitimately demonstrates is
numerical cycle-stability and a reproducible switched charge per cycle. It is run
at 10 / 10² / 10³ cycles; 10⁴ was dropped because it costs hours of a contended
single-license host to produce an analytically flat line.

**E4 — normalization side-effects.** ΔV_t is only invariant if the constant-current
criterion tracks the axis. At the unchanged *physical* criterion (I_cc = 6.34e-3
µA/µm on the corrected axis) MW = 0.336 V exactly, as Part I predicts. At a round
I_cc = 1e-2 µA/µm read on the *new* axis it is 0.355 V, because the erased branch
crosses inside its ambipolar recovery where its local slope is ~159 mV/dec. That
is a criterion choice, not a physics change, and the paper should state which one
it uses. SS (62.3 mV/dec, programmed branch) is exactly invariant either way.

**E5 — data-audit counts.** C6 said the 12 unexported nodes hold ~580 files; the
actual count is **483**, and the CSV total went 894 → **1377**, not ~1450.

---
---

# PART I — Areafactor / width-normalization audit

## I.1 The question, answered directly

> Is there a contradiction in the Areafactor values between `Calibration/` and
> `Device_Optimization/`?

**Between the two directories: NO.** They are byte-identical in convention —
both set `Areafactor = 0.071` in the `.cmd` and both divide by `0.090` in Python.
Verified in code:

| Where | File : line | Value |
|---|---|---|
| Cal — sdevice template | `Calibration/autocal/cal_template.cmd:28` | `Areafactor= @AREA@` |
| Cal — token default | `Calibration/autocal/run.py:35` | `AREA="0.071"` |
| Cal — every rendered run | `Calibration/autocal/runs/*_des.cmd:24,28` | `0.071` (204 files) |
| Cal — PE validation | `Calibration/autocal/pe_validation.cmd:25` | `0.071` |
| Cal — Phase1D template | `Calibration/autocal/h1app_template.cmd:28` | `0.071` |
| Cal — analysis divisor | `Calibration/autocal/metrics.py:26` | `W_EFF_UM = 0.090` |
| Cal — analysis divisor | `Calibration/replot_calibration_liao.py:35` | `W_EFF_UM = 0.090` |
| DevOpt — LIF eval cmd | `Device_Optimization/lif_eval.cmd:28` | `Areafactor= 0.071` |
| DevOpt — I-V generator | `Device_Optimization/ivgen.py:24` (git) | `Areafactor=0.071` |
| DevOpt — MW generator | `Device_Optimization/memwingen.py:16` | `Areafactor=0.071` |
| DevOpt — analysis divisor | `Device_Optimization/opt.py:30` (git) | `W_um = 0.090` |
| DevOpt — analysis divisor | `Device_Optimization/plot_memwin.py:11` (git) | `W_um = 0.090` |
| DevOpt — analysis divisor | `Device_Optimization/plot_iv.py:12` (git) | `W_um = 0.090` |
| DevOpt — Phase1D analysis | `Device_Optimization/analysis/analyze_phase1d_h1_app.py:32` | `W_eff_um = 0.090` |

**The contradiction is internal to each directory, not between them — and there are
FOUR conventions in the repo, not two.**

| # | Convention | Where | Effective normalization |
|---|---|---|---|
| 1 | `Areafactor=0.071` in cmd, `/0.090` in py | `Calibration/`, `Device_Optimization/` | reported = 0.7889 × I₂D |
| 2 | `Areafactor=1.0` in cmd, `/1.0` in py | `Planar_Device_Work/gen_planar.py:21`, `planar.py:25` | reported = 1.000 × I₂D |
| 3 | `CORR = 0.090/0.071` applied on top of #1 | `Planar_Device_Work/analyze_compare.py:44`, `plot_planar.py:25` | reported = 1.000 × I₂D |
| 4 | take #1's µA/µm CSV and multiply **back** by 0.090 | `Device_Optimization/gaafefet_params_optimized.py` | reported = raw `.plt` amps |

Convention 4 verified numerically: `csv_export/raw/transfer_curves.csv` at V_G=0 gives
erased 7.766e-3 µA/µm = 7.766e-9 A/µm; × 0.090 = **6.99e-10 A** = the
`DEVICE["ID_baseline"] = 7.0e-10` in `gaafefet_params_optimized.py`. So the SNN model's
`ID_baseline`, `ID_fire`, `R_on_estimate`, `R_off_estimate` are the **raw simulated
current of a 71 nm-deep device**, labelled "A", while the same file declares
`"AreaFactor": 0.071` as if it still needed applying. `ID_fire = 2.14e-8 A` likewise
= `ltp_potentiation.csv` pulse 9 (2.382e-1 µA/µm) × 0.090. Round-trip confirmed.

## I.2 The deeper problem: 0.071 is not geometrically right, and neither is 0.090

Sentaurus solves the 2D cross-section per unit z-depth. `Areafactor = A` means "this
2D slab is A µm deep in z"; `I_plt = I₂D × A`. It is a **pure post-multiplier on
contact currents and charges** — it does not enter the Poisson/continuity solve.

The simulated slab is **double-gated** (`sde_opt.cmd` builds `insulator_top` +
`ferroelectric_top` + `gate_metal_top` **and** the mirrored `_bottom` set, both bound
to `gate_contact`). So a slab of depth A has **total gate width 2A**.

The real GAA nanosheet has gate perimeter
`TESW = 2·(W + T_si) = 2·(40 + 5) nm = 90 nm`.

Matching → `2A = 0.090` → **A = 0.045 µm**.

- `A = 0.071` models a device with **142 nm** of gate width — **1.58× the real GAA
  perimeter**.
- `A = 0.090` would model **180 nm** — 2× too much.
- Neither number was ever derived from the geometry.

**Where 0.071 came from:** it is a leftover from the *first* calibration campaign.
`Calibration/first_run_outputs/liao2022_runlog.txt:388` (`DeviceAreaFactor = 0.071`)
and `Calibration/PLAN.md:190`, which quotes it inside a draft manuscript sentence
alongside `P_r = 16 µC/cm², P_s = 20, F_c = 1.2 MV/cm, FixedCharge = 4e12` — **all of
which are superseded** (final: 32 / 40 / 1.4 / 7e12). It was carried forward unchanged
through 204 `.cmd` files and never re-derived when the geometry changed
(`CALIBRATION_RESULT.md:35` lists it as "0.071 → 0.071, unchanged").

**Second-order error:** `TESW` depends on `T_si`, but `Areafactor` is held at 0.071
across the entire T_si sweep (5, 8, 10, 12, 15 nm). True TESW runs 90 → 110 nm, a
**22 % spread** that the constant Areafactor does not capture. Ratio metrics (`window`,
`DR`, `igain`) cancel it; the `id_on_uA_um` / `id_off_uA_um` columns in
`csv_export/sweeps/tsi_sweep.csv` do not.

## I.3 What is and is not damaged

**NOT damaged — the calibration itself is immune.**
The overlay applies a *free fitted* width factor:

```
Calibration/autocal/pub_figure.py:42   scale = LIAO_SAT / np.median(ie[ve >= 2.5])
Calibration/autocal/overlay_hyst.py:63 return sat(vde, ide) / sat(ve, ie)
```

Any constant normalization error is absorbed into that one scalar. So the calibrated
**P_r = 32, P_s = 40 µC/cm², F_c = 1.4 MV/cm, ε = 33, Dit = 4e12, FixedCharge = 7e12,
Agen = 4e16 are unaffected by the Areafactor choice.** Same for MW, V_t, SS, and the
on/off ratio — all shape/ratio quantities.

**The corollary is the honest caveat that must go in the paper:** the absolute current
level was **never calibrated**. `Calibration/plots/metrics_summary.txt` records
I_on,PGM TCAD = 2.150e-04 A/µm vs Liao = 1.523e-06 A/µm — a **141× gap**, entirely
absorbed by the fitted scale. The paper may claim calibrated *window / V_t / SS /
on-off ratio / turn-on shape*. It may **not** claim the absolute µA/µm is
experimentally validated.

**NOT damaged — every polarization and electric-field figure.**
Areafactor scales only contact currents and charges. The `Pos(0,0.007)
Polarization/{x,y}` and `ElectricField/{x,y}` probe columns are untouched. All P–V,
P–E, |E|/F_c, and depolarization-field figures are safe as-is.

**DAMAGED — every absolute current, conductance, resistance, charge, and energy number.**
That includes: `ID_baseline`, `ID_fire`, `R_on_estimate`, `R_off_estimate`, `g_min`,
`g_max`, `E_spike`, `E_per_pulse`, the `qg_C` column in every sweep CSV, all µA/µm axes,
and the "≈0.01–0.04 fJ per pulse" claim.

## I.4 The fix — no re-run required

Because Areafactor is a post-multiplier and these are single-device (not mixed-mode)
runs, the correction is an **exact post-processing rescale**. Present CSV values are
`0.7889 × I₂D`. Pick one target and apply one factor:

| Target convention | Meaning | I_reported | **× on present CSVs** |
|---|---|---|---|
| **(a) per µm of gate perimeter** ← recommended | W_eff,GAA = TESW = 90 nm; equivalent to setting `Areafactor = 0.045` | I₂D / 2 | **× 0.634** |
| (b) per µm of z-depth | what `Planar_Device_Work` already uses (`CORR = 1.2676`); makes GAA directly comparable to the planar ablation | I₂D | × 1.268 |
| (c) absolute per nanosheet | one physical device, W=40 nm, T_si=5 nm | I₂D × 0.045 A | × 0.0570 → A |

(a) and (c) are the same convention, normalized vs absolute. Resistances scale by
the reciprocal (× 1.578 for (a)). Energies and charges take the same factor as currents.

**Recommendation:** adopt **(a)** as the paper's convention, quote `W_eff = 2(W+T_si)
= 90 nm` explicitly in the methods, and derive the planar comparison with
`W_eff,planar = W = 40 nm` (single gate over the top face only). State in one sentence
that the 2D double-gate slab maps to the GAA via `Areafactor = W_eff/2 = 0.045 µm`.
Draw it as **Figure A5** and the reviewer question never gets asked.

Corrected headline numbers under (a):

| Quantity | Present (published) | Corrected (a) |
|---|---|---|
| ON current @ V_G=0, programmed | 29.5 µA/µm | **18.7 µA/µm** |
| OFF current @ V_G=0, erased | 9.41e-3 µA/µm | **5.96e-3 µA/µm** |
| ON/OFF window | 3137× | **3137×** (unchanged — ratio) |
| LTP level 15 | 13.1 µA/µm | **8.31 µA/µm** |
| LTP level 1 | 1.007e-3 µA/µm | **6.39e-4 µA/µm** |
| Energy per program pulse | ~0.014 fJ | **~0.0089 fJ** |
| R_off / R_on | 7.14e7 / 2.34e6 Ω | **1.13e8 / 3.69e6 Ω** |
| 15 analog levels | 15 | **15** (unchanged) |
| Memory window ΔV_t | 0.336 V | **0.336 V** (unchanged) |
| SS | 62.3 mV/dec | **62.3 mV/dec** (unchanged) |

Every headline *claim* survives. Only the absolute-current axes move by 0.634×.

---
---

# PART II — Other contradictions found in the same audit

## C1 — `transfer_curves.csv` was simulated with a different `.par` than everything else
**Severity: HIGH. Undocumented anywhere.**

```
Device_Optimization/runs/iv_fe07_des.cmd        Parameter = "app_frozen.par"
Device_Optimization/runs/mw_fe07_des.cmd        Parameter = "app_opt.par"
Device_Optimization/runs/mwfine_fe07_des.cmd    Parameter = "app_opt.par"
Device_Optimization/runs/t8_ltp_v020_des.cmd    Parameter = "app_opt.par"
Device_Optimization/runs/t9_leak_v020_des.cmd   Parameter = "app_opt.par"
Device_Optimization/runs/t9_t250_v020_des.cmd   Parameter = "app_opt.par"
Device_Optimization/runs/t5_fe07_v025_des.cmd   Parameter = "app_opt.par"
```

```
par/app.par         tau_E = 1e-6    tau_P = @TAU_P@ (rendered 1e-5 in all 37 runs/app_*.par)
par/app_frozen.par  tau_E = 1e-4    tau_P = 1e-4
```

So the `iv_fe07` run — the sole source of `csv_export/raw/transfer_curves.csv`, and
therefore of `Vth_virgin`, `Vth_fire`, `SS`, `MW = 0.336 V`, `ID_baseline`, and
`ID_fire` in **both** `SNN_PARAMETERS.md` and `gaafefet_params_optimized.py` — ran with
a **100× longer FE switching time and 10× longer depolarization time** than every other
figure in the deck.

This is defensible in itself (it is the deliberate "freeze the FE during the read"
protocol inherited from calibration node `cal_n16`, which also has `tau_E = 1e-4`, and
the retained-state I–V is in principle tau-independent). But:
1. `OPTIMIZED_DEVICE.md` and `SNN_PARAMETERS.md` both state `tau_E = 1e-6, tau_P = 1e-5`
   with no mention of the frozen variant. Both are **wrong** for those rows.
2. It explains a discrepancy nobody has reconciled: the erased current at V_G = 0 is
   **7.766e-3 µA/µm** in `transfer_curves.csv` but **9.407e-3 µA/µm** in
   `memwin_fe07.csv` — 21 % apart, both labelled "erased read at V_G=0".
3. A reviewer asking "what τ_P did you use?" gets two answers from one paper.

**Action:** either re-run `iv_fe07` under `app.par` (τ_E=1e-6, τ_P=1e-5) — ~10 min,
see RR-0 — or document the two-protocol split explicitly in the methods. Re-running
is cleaner and removes the discrepancy.

**Also: my earlier plan told you to use `par/app_frozen.par` for the re-runs. That was
wrong. Use `par/app.par` with `@TAU_P@` rendered to `1e-5`.**

## C2 — Two mutually inconsistent "erased at V_G=0" and two "ON/OFF at V_G=0"
| Quantity | Source | Value |
|---|---|---|
| I_erased @ V_G=0 | `transfer_curves.csv` (frozen par) | 7.766e-3 µA/µm |
| I_erased @ V_G=0 | `memwin_fe07.csv` (app_opt par) | 9.407e-3 µA/µm |
| ON/OFF @ V_G=0 | `memwin_fe07.csv`, full ±2.5 V write | **3137×** |
| ON/OFF @ V_G=0 | `SNN_PARAMETERS.md` `fire_ratio` = LTP p9 / transfer erased | **30.6×** |

Both ON/OFF numbers are physically real (a full program vs 9 sub-coercive pulses) but
they differ by 100× and the paper currently quotes both without distinguishing them.
Fix the labels: `3137×` = **retained memory window**; `30.6×` = **9-pulse LIF fire
contrast**. Never in the same sentence.

## C3 — Two "calibrated" parameter sets in `Calibration/`, only one superseded in writing
| File | P_r | P_s | F_c | FixedCharge | Agen | τ_E | τ_P |
|---|---|---|---|---|---|---|---|
| `sdevice_gaafet_lif.par` | 2.4e-5 | 3.0e-5 | 0.7e6 | 1.5e12 | 4.0e14 | 1e-6 | 0 |
| `final_outputs/g15.par`, `r_fc07.par` | 2.4e-5 | — | 0.7–0.8e6 | — | 4.0e14 | 1e-6 | 0 |
| `CALIBRATION_RESULT.md` (table) | 24 | 30 | 0.8 | 1.5e12 | — | — | 0 |
| **`autocal/runs/cal_n16.par` (FINAL, locked)** | **3.2e-5** | 4.0e-5 | **1.4e6** | 7e12 | **4e16** | 1e-4 | 0 |
| **`sdevice_gaafet_app.par` = `Device_Optimization/par/app.par`** | **3.2e-5** | 4.0e-5 | **1.4e6** | 7e12 | **4e16** | 1e-6 | 1e-5 |

`sdevice_gaafet_lif.par` is a **dead file** from the superseded write-read campaign.
`CALIBRATION_RESULT.md` documents that dead lineage with **no supersede banner** —
`HYSTERESIS_CALIBRATION_RESULT.md` supersedes it but the older file doesn't say so.
The canonical par for all application work is **`sdevice_gaafet_app.par`**, and it does
correctly inherit `cal_n16` (P_r/P_s/F_c/FixedCharge/Agen all match; only τ_E and τ_P
are deliberately reverted per the documented KEEP/REVERT rule). **No Agen contradiction
— 4e16 in both.** The 4.0e14 values belong exclusively to the dead lineage.

**Action:** add a `> SUPERSEDED by HYSTERESIS_CALIBRATION_RESULT.md` banner to
`CALIBRATION_RESULT.md`, and either delete `sdevice_gaafet_lif.par` or rename it
`sdevice_gaafet_lif.SUPERSEDED.par`. Do not cite `PLAN.md:190`'s draft manuscript
sentence anywhere — every number in it is stale.

## C4 — The 14 deck figures were built from 9 CSVs; six generating scripts are deleted
`ivgen.py`, `lifgen.py`, `plot_curves.py`, `plot_iv.py`, `plot_memwin.py`,
`plt2csv.py` are deleted in the working tree, alive in git. Nothing in this plan runs
until they are restored.

```bash
git restore Device_Optimization/ivgen.py Device_Optimization/lifgen.py Device_Optimization/plot_curves.py Device_Optimization/plot_iv.py Device_Optimization/plot_memwin.py Device_Optimization/plt2csv.py
```

## C5 — P–E / P–V figures are unsaturated minor loops
`Calibration/csvs/pe_loop_{up,down}.csv` spans P = **−3.91 … +2.07 µC/cm²** and
E = **−0.333 … +0.773 MV/cm**, against claimed P_r = 32 and F_c = 1.4 MV/cm. The ±4 V
sweep delivers only **55 % of F_c** to the HZO. P–V also has negative slope (top-stack
probe's +y points away from the channel). Deck Figures 12/13 are captioned as the HZO
material loop; they are not. Fix = sign flip + recaption as the MFIS
divider/depolarization result, plus a standalone MFM capacitor run for the real loop
(RR-1).

## C6 — Data audit: 1402 `.plt`, 869 CSVs, 12 run nodes never exported
| Node | files | Contents |
|---|---|---|
| `t7c_lif` | 124 | count-to-fire, V_pgm = 0.6/0.8/1.0/1.2 V |
| `t8_lif0` | 100 | LIF demo at V_read=0, V_pgm = 1.0/1.5/2.0/2.5 V |
| `mw_fe07` | 41 | memory-window sweep, T_fe=7 nm |
| `mwfine` | 38 | fine ERS/PGM I–V, 19 pts/branch |
| `t8_ltp` | 31 | **the 15-pulse LTP run** (only its endpoint reached CSV) |
| `t9_t250`, `t9_t350` | 31 each | 250 K / 350 K LTP trains |
| `t7d_test` | 31 | erase-protocol test |
| `t9_leak` | 18 | retention hold + its pulse train |
| `mw_fe12`, `mw_si05` | 18 each | memory-window per geometry |
| `iv_fe07` | 2 | full ±1.5 V I–V (the frozen-par run, see C1) |

Every `.plt` has **29 columns**. Never plotted anywhere in the project:
`gate_contact Charge`, `*_contact DisplacementCurrent`, `eCurrent`/`hCurrent` split,
`source_contact` anything, `InnerVoltage`, and the full `ElectricField/{x,y}` traces.

**No `.tdr` files exist locally** — only `.plt`. Zero 2D maps are possible without a
re-run, even though `lif_eval.cmd`'s `Plot { }` block already requests eDensity,
hDensity, ElectricField/Vector, Potential, ConductionBand, ValenceBand,
Polarization/Vector, SRHRecombination, eMobility.

## C7 — Unused calibration search data
`Calibration/autocal/results.csv` — **57 rows**, each with `loss, MW, Vt_pgm, Vt_ers,
SS_pgm, SS_ers, R2_pgm, R2_ers, Ion_pgm, Ion_ers` plus the full parameter dict
`{PR;PS;FC;TAUE;TAUP;WF;AREA;FIXQ;VPGM;VERS}`. Never plotted. This is a complete
parameter-sensitivity dataset (P_r 1.6–2.8e-5, F_c 0.35–1.8e6, τ_P 0–1e-3, Dit, S/D
doping). The later hysteresis campaign's 17 `cal_n*` nodes have no results table, but
`fwd_/rev_cal_n*_des.plt` all exist in `autocal/runs/` and
`final_outputs/hyst_cal/`, so their metrics are recomputable with `overlay_hyst.py`.

---
---

# PART III — Master figure catalog (79 figures)

Grouped by chapter. **Status**: `HAVE` = data on disk, plot it; `EXPORT` = data on disk
but the node needs `plt2csv.py` first; `RR-n` = needs the re-run in Part IV;
`DECK` = already in `graphs.pptx`.

## A · Structure, method, and normalization (6)

| ID | Figure | Source | Status |
|---|---|---|---|
| A1 | Device cross-section to scale — TiN/HZO 7nm/SiO2 1nm/Si 5nm/SiO2/HZO/TiN, L_gate=100, L_ov=15, probe point marked | `sde/sde_opt.cmd` geometry | HAVE (draw) |
| A2 | Mesh density map, channel refinement 0.5 nm | `.tdr` | RR-6 |
| A3 | Equilibrium band diagram through the gate stack (TiN→HZO→SiO2→Si), erased vs programmed | `.tdr` cut | RR-6 |
| A4 | LIF measurement protocol timing diagram — V_G(t) and V_DS(t) for baseline / 9×(rise-hold-fall-read) | `lif_eval.cmd` Solve block | HAVE (draw) |
| A5 | **GAA ↔ 2D mapping diagram** — nanosheet perimeter TESW = 2(W+T_si) = 90 nm ↔ double-gate slab of depth 0.045 µm | Part I.2 | HAVE (draw) |
| A6 | Simulation flow chart: sde → sdevice → plt → metrics → FoM → keep/discard | `opt.py` | HAVE (draw) |

## B · Calibration against Liao 2022 (9)

| ID | Figure | Source | Status |
|---|---|---|---|
| B1 | **Liao Fig.7 overlay, operating region** — TCAD lines on Liao markers, MW=1.30 V annotated, semilogy | `csvs/tcad_cal_n16_post{ERS,PGM}.csv` + `dots_{ERS,PGM}.csv`; scale = 4.8e-6/median(I_ERS, V_G≥2.5) | HAVE |
| B2 | Full-range two-panel diagnostic (PGM / ERS), incl. ambipolar tails and deep minimum | same + `clean_{ERS,PRG}.csv` | HAVE |
| B3 | Overdrive-aligned shape comparison: x = V_G−V_t (V_t at 100 nA/µm), y = I/I_on (I_on at +0.4 V overdrive) | same | HAVE |
| B4 | **SS vs V_G, both branches, TCAD vs Liao** — d(V_G)/d(log I); shows 45–75 mV/dec sub-thermal NC steepening | same, numerical derivative | HAVE |
| B5 | **Calibration residual** — log₁₀(I_TCAD) − log₁₀(I_Liao) vs V_G, ±0.3 dec band | same | HAVE |
| B6 | **Parameter sensitivity: loss vs P_r, loss vs F_c, loss vs τ_P** — 57-node search | `autocal/results.csv` | HAVE |
| B7 | **Calibration convergence** — loss vs node index, campaign stages coloured, best-so-far envelope | `autocal/results.csv` | HAVE |
| B8 | Hysteresis-stage node comparison — MW / RMS per `cal_n*` node (n3 → n10 → n16) | `autocal/runs/{fwd,rev}_cal_n*_des.plt` via `overlay_hyst.py` | EXPORT |
| B9 | Ambipolar S/D ablation — n⁺/n⁺ vs n⁺/p⁺ ERS branch, showing the hole branch appearing | `cal_n3` vs `cal_n10`/`cal_n16` plt | EXPORT |

## C · Ferroelectric material & electrostatics (8)

| ID | Figure | Source | Status |
|---|---|---|---|
| C1 | **Saturated MFM P–E loop** — TiN/HZO(7nm)/TiN, ±2·F_c·T_fe; proves P_r=32, P_s=40, F_c=1.4 | — | **RR-1** |
| C2 | **MFIS minor loop, corrected** — 2 panels: P vs V_G and P vs E_HZO, both sign-flipped, F_c line drawn to show the ±4 V sweep only reaches 0.77 MV/cm | `Calibration/csvs/pe_loop_{up,down}.csv` | HAVE (fix C5) |
| C3 | E_FE/F_c vs V_G at the probe — the sub-coercive operating band [0.7, 0.95] shaded | `Pos(0,0.007) ElectricField/y` in any write plt | HAVE |
| C4 | Depolarization field vs T_ox — |E_FE| at V_G=0 after program, 0.5/1.0/1.5/2.0 nm | `t2*_tox*` plt E-field column | EXPORT |
| C5 | MFIS voltage divider — V_FE/V_G vs T_ox and vs T_fe, analytic curve + TCAD probe points | `t2*`, `t5_fe*` plt | EXPORT |
| C6 | **2D polarization map** P_y across the stack, erased vs programmed | `.tdr` | **RR-6** |
| C7 | Switching fraction vs \|E\|/F_c — every run's `EyFc` vs its achieved window; Preisach kinetics validation | `docs/turn*.tsv` + `results.tsv` | HAVE |
| C8 | Coercive voltage vs T_fe — V_c = F_c·T_fe line vs measured V_op (5/7/10/12 nm) | `sweeps/tfe_sweep.csv` | HAVE |

## D · DC device characteristics (10)

| ID | Figure | Source | Status |
|---|---|---|---|
| D1 | **Retained I_D–V_GS, decorated** — both states, V_t markers at I_cc=1e-2 µA/µm, SS fit lines, ON/OFF arrow at V_G=0, GIDL upturn labelled | `raw/memory_window_iv.csv` (201 pts) | DECK (redo) |
| D2 | **Output characteristics I_D–V_DS** — ERS/PGM family + 5 LTP states, 0→1.0 V | — | **RR-2** |
| D3 | SS vs I_D, both states (SS is not a single number — show its I-dependence) | `raw/memory_window_iv.csv` | HAVE |
| D4 | Transconductance g_m vs V_G and g_m/I_D vs I_D | same | HAVE |
| D5 | V_t vs geometry — extracted V_t,ERS and V_t,PGM vs T_ox / T_fe / T_si on one 3-panel | `mw_*` nodes | EXPORT |
| D6 | DIBL — I–V at V_DS = 0.05 and 0.5 V | — | RR-2 |
| D7 | **Carrier-resolved off-state** — `eCurrent` vs `hCurrent` vs V_G; attributes the ambipolar/GIDL tail | `drain_contact eCurrent/hCurrent` in `mwfine` | EXPORT |
| D8 | **Gate leakage I_G vs V_G** — the T_ox=1 nm reliability question, answered with data | `gate_contact TotalCurrent` in `mwfine` | EXPORT |
| D9 | Source–drain current balance \|I_D + I_S\| / I_D vs V_G — numerical-integrity sanity figure (supplementary) | `source_contact` vs `drain_contact` | EXPORT |
| D10 | Fine memory-window sweep, 19 pts/branch — supersedes the 9-point `memwin_fe07` | `mwfine` node | EXPORT |

## E · Write transients & switching kinetics (9)

| ID | Figure | Source | Status |
|---|---|---|---|
| E1 | **Stitched write staircase** — 2 panels on one time axis: P_y (µC/cm²) and \|I_G\| (µA/µm), 9 pulses; `t = (time + (n−1)·t_period)·1e6` | `iv_curves/t5_fe07/p01..09_write_*v025*` | HAVE |
| E2 | **Overlaid per-pulse transients** P1→P9, colour-graded, `t = (time − time₀)·1e9` ns; shows switching slowing as the FE saturates | same | HAVE |
| E3 | Displacement current only — separates pure FE switching from conduction | `gate_contact DisplacementCurrent` | HAVE |
| E4 | Gate charge Q_G(t) staircase across the 9 pulses | `gate_contact Charge` | HAVE |
| E5 | **Switched charge per pulse ΔQ_n** vs n | `gate_contact Charge` deltas | HAVE |
| E6 | **Measured energy per pulse** E_n = V_pgm·ΔQ_n, bar + cumulative line, 15 pulses | `t8_ltp` `gate_contact Charge` | EXPORT |
| E7 | Switching-time extraction — t₅₀ (time to 50 % of the pulse's ΔP) vs pulse index | write plt P_y traces | HAVE |
| E8 | **Read-disturb check** — read transient I_D(t) over the 100 ns read window, all 9 reads overlaid; flat = non-disturbing | `p*_read_*` files | HAVE |
| E9 | Write transients vs V_pgm — E1 repeated for 1.5/2.0/2.5/3.0/3.5 V | `t5_fe07` v015…v035 | HAVE |

## F · Synaptic behaviour (11)

| ID | Figure | Source | Status |
|---|---|---|---|
| F1 | **LTP staircase on log axis** with 15 level bands ± read-noise width; annotate "15 levels ≈ 3.9 bits" | `raw/ltp_potentiation.csv` | DECK (redo — currently linear, hides 10 of 15 levels) |
| F2 | **LTP nonlinearity fit** — G_n normalized, fit `G=(1−e^{−nA})/(1−e^{−NA})`, report A_LTP | same | HAVE |
| F3 | ΔG per pulse vs n | same | HAVE |
| F4 | **LTD (depression) curve** — 15 erase pulses at −2.0 V, **t_p ≥ 1 µs** | — | **RR-3** |
| F5 | **LTP + LTD symmetric loop**, 3 cycles | — | **RR-3** |
| F6 | Conductance-level separation histogram — level overlap / distinguishability | `raw/ltp_potentiation.csv` (+ RR-8 for spread) | HAVE |
| F7 | **LTP family vs V_pgm** — 12 pulses × 4 V_pgm and 9 pulses × 5 V_pgm | `t7b_grad` (v015/018/020/022), `t5_fe07` (v015…v035) | HAVE |
| F8 | **LTP vs pulse width** t_p = 10/20/50 ns — window flat, igain 0.974→0.997 | `t7_tp{10,20,50}` + `docs/turn7_tp.tsv` | HAVE |
| F9 | LTP vs temperature, **log axis** + Arrhenius panel log(G₁₅) vs 1000/T | `raw/ltp_vs_temperature.csv` | DECK (redo) |
| F10 | A_LTP (nonlinearity) vs V_pgm — derived from F7 | F7 fits | HAVE |
| F11 | Programming granularity — ΔV_t per pulse vs V_pgm and vs t_p | F7, F8 | HAVE |

## G · LIF neuron operation (7)

| ID | Figure | Source | Status |
|---|---|---|---|
| G1 | **Count-to-fire family** — read current vs pulse index for 8 V_pgm values, fire threshold line | `t7c_lif` (124 files) + `t8_lif0` (100 files) | EXPORT |
| G2 | **N_fire vs V_pgm** — the neuron's rate-coding transfer function | G1 | EXPORT |
| G3 | **Spike-train waveform, 3 stacked panels** — V_G(t) input spikes / P_y(t) membrane state / I_D(t) readout with threshold | `t8_lif0` write+read stitched | EXPORT |
| G4 | Membrane-potential analogue — P_y vs read current, parametric in pulse number (proves the state variable is the polarization) | `t8_ltp` | EXPORT |
| G5 | Fire-threshold margin vs V_read — separation between p8 and p9 currents | `mwfine` + `t8_ltp` | EXPORT |
| G6 | Energy per spike vs V_pgm | `t7c_lif`/`t8_lif0` gate charge | EXPORT |
| G7 | Post-fire latching — extended hold after fire, showing τ_P=0 behaviour; the honest single-shot caveat as a figure | `t9_leak/hold_*` | EXPORT |

## H · Retention & reliability (8)

| ID | Figure | Source | Status |
|---|---|---|---|
| H1 | Retention hold, decorated — log-time x, settled level ±1 % band | `raw/leak_retention.csv` | DECK (redo) |
| H2 | **Depolarization-field decay during hold** — E_y and P_y vs time, twin axis; explains *why* H1 plateaus | `t9_leak/hold_*.plt` | EXPORT |
| H3 | Multi-level retention — all 15 LTP states held; mid-state retention is what reviewers doubt | — | **RR-4** |
| H4 | Retention extrapolated to 10 years, log-linear, 300 K + 400 K | — | **RR-4** |
| H5 | **Endurance** — window vs cycle count, 10¹…10⁴ | — | **RR-5** |
| H6 | C2C / D2D variability — LTP curve cloud + level-overlap histogram | — | RR-8 |
| H7 | Retention Arrhenius — activation energy from the 300/400 K decay rates | — | RR-4 |
| H8 | Read-disturb accumulation — window after 10⁶ reads at V_read=0 | — | RR-9 |

## I · Design-space optimization (11)

| ID | Figure | Source | Status |
|---|---|---|---|
| I1 | **Coordinate-descent trajectory** — window vs turn (log y), chosen value annotated per turn | `sweeps/optimization_trajectory.csv` | HAVE |
| I2 | **T_ox: window ∧ I_off dual axis**, both eval contexts (`fixed4V`, `subcoercive`) — merges deck Figs 9/10/14 | `sweeps/tox_sweep.csv` | DECK (merge) |
| I3 | **T_fe Pareto** — window vs V_op, marker size = Q_g, labelled 5/7/10/12 nm — replaces deck Figs 5+6 and shows *why* 7 nm over the window-optimal 10 nm | `sweeps/tfe_sweep.csv` | DECK (merge) |
| I4 | T_si: window + I_off + igain | `sweeps/tsi_sweep.csv` | DECK (extend) |
| I5 | **Read-bias design map** — true window (left axis) and I_rest (right axis) vs V_read; GIDL region shaded; V_read=0 marked; old virgin-referenced `dr` overlaid as a faint dashed line with the disagreement explained in the caption | `mwfine` + `sweeps/vread_sweep.csv` | EXPORT (replaces deck Fig 8) |
| I6 | N_sub null result — fully-depleted 5 nm body is doping-insensitive | `sweeps/nsub_sweep.csv` | HAVE |
| I7 | L-scaling null result — L_gate 50 nm and L_ov 0 nm both ~6× worse | `sweeps/lscaling.csv` | HAVE |
| I8 | Pulse-width: window flat, igain rising | `docs/turn7_tp.tsv` | HAVE |
| I9 | **`igain` across every sweep** — grouped bars; per-pulse monotonicity matters as much as the window for an analog synapse, and it is free in every sweep CSV | all `sweeps/*.csv` `igain` column | HAVE |
| I10 | Gate charge Q_g across every sweep — the energy proxy | all `sweeps/*.csv` `qg_C` column | HAVE |
| I11 | **V_pgm × t_p programming heatmap** — colour = window, sub-coercive band \|E\|/F_c ∈ [0.7,0.95] overlaid | — | **RR-7** |

## J · Comparison & benchmarking (6)

| ID | Figure | Source | Status |
|---|---|---|---|
| J1 | **GAA vs planar ablation radar** — SS, ΔV_t, ON/OFF, LTP levels (15 vs 10), V_pgm, retention | `Planar_Device_Work/PLANAR_vs_GAA.md` | HAVE |
| J2 | GAA vs planar LTP overlay, both normalized | `Planar_Device_Work/plots/` + `raw/ltp_potentiation.csv` | HAVE |
| J3 | GAA vs planar transfer overlay | `Planar_Device_Work/outputs/` + `raw/memory_window_iv.csv` | HAVE |
| J4 | GAA vs planar spike train, side by side | `Planar_Device_Work/plots/fig_spike_train_*.png` + G3 | EXPORT |
| J5 | **Literature benchmark: analog levels vs energy/pulse**, this work highlighted | lit pull | NEW |
| J6 | Literature benchmark: memory window vs operating voltage | lit pull | NEW |

## K · Device → SNN handoff (4)

| ID | Figure | Source | Status |
|---|---|---|---|
| K1 | Device-to-synapse mapping — 15 measured G levels → quantized STE weight grid | `raw/ltp_potentiation.csv` + `gaafefet_params_optimized.py` | HAVE (after Part I fix) |
| K2 | SNN accuracy vs number of conductance levels (2/4/8/15) | `PYTHON_Modelling_Fefet_Codes/` | NEW (sim) |
| K3 | SNN accuracy vs device variability | K2 + RR-8 | NEW (sim) |
| K4 | Energy per inference breakdown — device write vs read vs peripheral | E6 + SNN spike counts | NEW |

**Total: 79 figures.** 46 need no new simulation; 21 need only `plt2csv.py` on existing
`.plt` files; 12 need a re-run.

---
---

# PART IV — Sentaurus re-run list

All on mesh `fe07`, **`Device_Optimization/par/app.par` with `@TAU_P@ = 1e-5`** (NOT
`app_frozen.par` — see C1), driven through `opt.py`. Ordered by
(reviewer value) / (sim cost).

| ID | Run | Cost | Feeds | Why |
|---|---|---|---|---|
| **RR-0** | **Re-run `iv_fe07` under `app.par`** (τ_E=1e-6, τ_P=1e-5) instead of `app_frozen.par` | ~10 min | D1, D3, D4, C2-fix | Removes contradiction C1; makes every V_t / SS / MW number come from the same physics as every other figure |
| **RR-1** | **MFM capacitor P–E** — standalone TiN/HZO(7nm)/TiN, no semiconductor, triangular sweep to ±2·F_c·T_fe = ±1.96 V then ±3 V. **Transient + Goal, never Quasistationary** (QS runs in fictitious time and creep-overwrites the FE state) | ~10 min | C1 | Fixes the reviewer-fatal defect C5; publishes the true P_r=32 / F_c=1.4 loop |
| **RR-6** | **Re-run erased + programmed states and download the `.tdr`** — the `Plot { }` block in `lif_eval.cmd` already requests everything | ~15 min | A2, A3, C6, plus band/carrier/field cuts | Cheapest big visual win; currently zero 2D maps exist |
| **RR-2** | **I_D–V_DS output family** — after ERS, after PGM, and at 5 LTP states; V_DS 0→1.0 V at V_G=0; also at V_DS=0.5 V for DIBL | ~20 min | D2, D6 | Every device paper has one; this project has none |
| **RR-3** | **LTD pulse train** — from the potentiated state, 15 erase pulses at −2.0 V, **t_p ≥ 1 µs** (100 ns sees only ~26 % of the field PGM sees — depolarization screening). Then a 3-cycle alternating 15-LTP / 15-LTD run. Use instant gate ramps + `Digits=5` for negative-bias convergence; launch detached and poll (avoid license-holding orphans) | ~30 min | F4, F5 | Biggest scientific gap — you have potentiation only |
| **RR-4** | **Long retention** — extend `t9_leak`'s hold 100 µs → 10 ms, log-spaced `CurrentPlot` intervals, at 300 K and 400 K, for the fully-programmed state **and** LTP level 8 | ~40 min | H3, H4, H7 | Mid-state retention is what reviewers actually doubt |
| **RR-7** | **V_pgm × t_p heatmap** — grid V_pgm ∈ {1.0,1.5,2.0,2.5,3.0} × t_p ∈ {10,30,100,300,1000} ns, 9 pulses each | ~2 h | I11 | Defines the analog operating region in one image |
| **RR-5** | **Endurance** — 10/10²/10³/10⁴ PGM/ERS cycles (±2.0 V, 1 µs), window read after each decade | ~1–2 h | H5 | A degradation curve is more credible than silence |
| **RR-9** | Read disturb — 10⁶ reads at V_read=0, window before/after | ~1 h | H8 | Answers "does your 0 V read disturb the state?" |
| **RR-8** | Variability ensemble — 20 runs perturbing Dit (4e12 ±20 %), FixedCharge (7e12 ±10 %), T_fe (7 ±0.3 nm) | ~3 h | H6, K3 | Only if a reviewer demands it, or for the SNN-under-variability story |
| **RR-10** | *(optional)* Areafactor sanity — one run at `Areafactor = 0.045` to confirm the post-hoc rescale is exact | ~5 min | Part I | Cheap proof for the methods section; the rescale should match to machine precision |
| **RR-11** | *(optional)* 3D GAA cross-check — one full 3D nanosheet at the operating point vs the 2D+Areafactor result | ~4–8 h | Part I | Closes the "is the 2D mapping valid?" question definitively. Only if the reviewer pushes |

---
---

# PART V — Phased TODO

## Phase 0 — Unblock and settle the numbers (~1 day)
- [ ] **0.1** `git restore` the six deleted scripts (C4).
- [ ] **0.2** **Settle the normalization.** Create `Device_Optimization/norm.py` holding
      exactly one definition: `W_EFF_UM = 0.090`, `AREAFACTOR_USED = 0.071`,
      `AREAFACTOR_CORRECT = 0.045`, `CORR = 0.634`, plus one documented
      `to_uA_per_um(I_plt)` function. Make `opt.py`, `plot_iv.py`, `plot_memwin.py`,
      `analyze_phase1d_h1_app.py`, `metrics.py`, and `plot_planar.py` all import it.
      No other file may define a width.
- [ ] **0.3** Re-derive every absolute number under convention (a) and update
      `SNN_PARAMETERS.md`, `OPTIMIZED_DEVICE.md`, `gaafefet_params_optimized.py`,
      and the SNN model's `g_min`/`g_max`/`R_on`/`R_off`/`E_spike`. Delete the
      `"AreaFactor": 0.071` key from the params dict — it is applied upstream and
      re-applying it is convention 4.
- [ ] **0.4** Fix the labels in C2: `3137×` = retained memory window;
      `30.6×` = 9-pulse LIF fire contrast. Never adjacent.
- [ ] **0.5** Add the supersede banner to `CALIBRATION_RESULT.md`; rename
      `Calibration/sdevice_gaafet_lif.par` → `*.SUPERSEDED.par` (C3).
- [ ] **0.6** Run `plt2csv.py` over the 12 unexported nodes (C6). ~580 new CSVs.
- [ ] **0.7** Write `Paper-materials/figs.py` — one script, one function per figure ID,
      one shared Origin-matching style block (bold sans, thick lines, ticks in, no
      grid), `--fig A1` CLI, emitting 600 dpi PNG + vector PDF **and** the tidy CSV
      each figure consumed, so the deck and the data can never drift again.
- [ ] **0.8** Launch **RR-0** and **RR-1** (both ~10 min) while Phase 1 proceeds.

## Phase 1 — Fix the existing deck (~1 day)
- [ ] **1.1** C2 → **C2 figure**: sign-flip and recaption the P–V / P–E loops.
- [ ] **1.2** **I5** replaces deck Fig 8 (DR vs V_read).
- [ ] **1.3** **F1** — LTP to semilogy with level bands.
- [ ] **1.4** **F9** — temperature to semilogy + Arrhenius panel.
- [ ] **1.5** **D1** — decorate the retained I–V.
- [ ] **1.6** **I2**, **I3** — merge the T_ox trio and the T_fe pair.
- [ ] **1.7** **H1** — decorate retention.

## Phase 2 — Harvest what is already on disk (~3 days)
- [ ] **2.1** Chapter E (9 figures) — all from `t5_fe07` and `t8_ltp` write transients.
- [ ] **2.2** Chapter G (7 figures) — from `t7c_lif` + `t8_lif0`, 224 currently-unused files.
- [ ] **2.3** D5, D7, D8, D9, D10 — from `mwfine` and `mw_*`.
- [ ] **2.4** C3, C4, C5, C7, C8 — the field/divider figures.
- [ ] **2.5** F2, F3, F6, F7, F8, F10, F11 — the synaptic analysis set.
- [ ] **2.6** I1, I4, I6, I7, I8, I9, I10 — the design-space set.
- [ ] **2.7** B1–B9 — the calibration chapter, including B6/B7 from the
      57-node `autocal/results.csv` and B8/B9 recomputed via `overlay_hyst.py`.
- [ ] **2.8** A1, A4, A5, A6 — the four drawn figures.
- [ ] **2.9** J1, J2, J3, J4 — the planar comparison.
- [ ] **2.10** H2, G7 — from `t9_leak/hold_*`.

## Phase 3 — Re-runs (~2 days of sim, batched)
- [ ] **3.1** RR-6 → A2, A3, C6.  **3.2** RR-2 → D2, D6.  **3.3** RR-3 → F4, F5.
- [ ] **3.4** RR-4 → H3, H4, H7.  **3.5** RR-7 → I11.  **3.6** RR-5 → H5.
- [ ] **3.7** RR-9 → H8.  **3.8** RR-8 → H6, K3 *(optional)*.
- [ ] **3.9** RR-10, RR-11 *(optional, methods-section armor)*.

## Phase 4 — Benchmark & system (~2 days)
- [ ] **4.1** J5, J6 — literature pull and benchmark scatters.
- [ ] **4.2** K1–K4 — device→SNN handoff, accuracy vs levels, accuracy vs variability,
      energy per inference.

## Phase 5 — Assemble
- [ ] **5.1** Multi-panel composition for the main text (10 composite figures):
      (1) A1+A5 structure & mapping · (2) B1+B3+B5 calibration · (3) C1+C2 ferroelectric ·
      (4) D1+D2 DC characteristics · (5) F1+F2+F5 synaptic · (6) E1+E2+E6 transients &
      energy · (7) G1+G2+G3 LIF neuron · (8) I1+I2+I3+I5 design space ·
      (9) H1+H4+H5 reliability · (10) J1+J5 comparison & benchmark.
      Remaining ~50 figures → supplementary.
- [ ] **5.2** `figures_manifest.csv`: figure ID → source `.plt`/CSV → `figs.py`
      function → the exact claim it supports → the normalization convention used.
      Kills both "where did this number come from" and the whole C1/C2/Part-I class of
      drift.
- [ ] **5.3** Methods paragraph covering: the 2D↔GAA Areafactor mapping (Part I.2),
      the honest statement that absolute current was not calibrated (Part I.3), the
      τ_E/τ_P protocol used per figure, and the two distinct ON/OFF definitions (C2).

---

# Priority if time is short

Eight figures carry the paper:

1. **C1** — saturated MFM P–E loop *(fixes the fatal defect)*
2. **B1** — Liao calibration overlay *(licenses every other number)*
3. **F5** — LTP + LTD symmetric loop *(the missing neuromorphic figure)*
4. **F1** — LTP on log axis with level bands *(the headline: 15 levels)*
5. **C6** — 2D polarization map *(visual proof it is a real device)*
6. **G3** — spike-train waveform *(the neuromorphic story in one picture)*
7. **D2** — I_D–V_DS output family *(the missing textbook figure)*
8. **A5** — GAA↔2D mapping diagram *(pre-empts the normalization question entirely)*

And before any of them: **Phase 0.2 + 0.3**. Nothing is publishable until the repo has
exactly one width convention.
