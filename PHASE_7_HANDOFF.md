# Phase 7 handoff — figure production and paper writing

Paste everything below the line into a fresh session. It is self-contained.

Scope: **produce the 79-figure catalog and write the paper.** No new device physics is
required. EEG remains dropped — do not touch `PYTHON_Modelling_Fefet_Codes/eeg detection/`.

---

## Context

Repo: `F:\RESEARCH\FeFET x ML\TCAD Files\GAAFet`, branch `paper/gap-fix`.

Read these three, in this order. They are the ground truth and they are short:
1. [PHASE_1_5_RESULTS.md](PHASE_1_5_RESULTS.md) — every device number and how it was checked.
2. [PHASE_6_RESULTS.md](PHASE_6_RESULTS.md) — the SNN deployment, K2/K3/K4, and five errors
   found by counting things that had been assumed.
3. [PLOT_PLAN.md](PLOT_PLAN.md) — the 79-figure catalog (Part III), the re-run list
   (Part IV) and the phased TODO (Part V).

**State of the work.** Data is complete: 109 run nodes on disk, 1377 CSVs, every re-run
RR-0…RR-10 landed and analysed. Phase 6 (device→SNN) is complete. What is left is figure
production and prose.

---

## Settle these three before drafting anything

### S1 — the analog-depth claim (BLOCKING, no simulation needed)

There is a live contradiction between two documents in the repo, and it is the paper's
headline device number.

`PHASE_1_5_RESULTS.md` §4 says the analog depth is **8 levels open-loop, not 15**, and that
"15 levels" is defensible only as a write-verify claim — concluding that K2/K3 should
quantize to 8.

`PHASE_6_RESULTS.md` §6.4c measured exactly that and found the opposite for *deployment*:
at the measured c2c σ, keeping all 15 levels costs **0.001** accuracy, while restricting to
the 8 separable levels costs **0.036**.

**These reconcile, and the reconciliation is the paper's story — but it must be stated
explicitly, not left implicit:**

| claim | value | rests on |
|---|---|---|
| device, open loop (n pulses, no verify) | **8 levels** | RR-8b: levels 9–15 sit inside 0.11 decades while c2c σ ≈ 0.013–0.022 decades |
| device, closed loop (write-verify to placed targets) | **~16 levels** | the 3.79-decade measured range |
| SNN deployment | **15 levels** | *presupposes write-verify* |

The SNN's 15-level deployment is legitimate **only** if the paper says it assumes a
write-verify array. That assumption is not a concession: K3a shows write-verify is
**already mandatory** for device-to-device — uncalibrated deployment onto the RR-8 corners
collapses to 0.243 median, and per-device write-verify restores 0.8304, the nominal result
to four decimals. So the system the paper describes needs write-verify regardless, and the
15-level claim comes free with it.

Write it that way, in the device section and again in the SNN section. A reviewer who spots
"8 levels" in the characterization and "15 levels" in the deployment without that bridge
will treat it as an inconsistency.

### S2 — a factual conflict in the RR-8b numbers (15 minutes)

`PHASE_1_5_RESULTS.md` says RR-8b delivered **9** complete repeats with σ ≈ 0.015 decades.
The committed data (`Device_Optimization/csv_export/raw/c2c_ensemble.csv`) has **11**
complete repeats, median σ = **0.0215** decades, s.e. ≈ 22 %.

Both were produced during the same afternoon as `t17_c2c` downloaded incrementally — one
document is stale. Re-run `python rranalyze.py rr8b`, take whatever the current data gives,
and make both documents agree. Do not average them, and do not quote either without the
repeat count: the run was **capped at 2 h (rc=137), it did not complete its 20 repeats**,
and every quotation of σ must carry that.

### S3 — DIBL (in flight, cheap, no new simulation)

DIBL is still **not reported**: the two extraction criteria disagreed in sign. A fix was in
progress at the end of Phase 6 — `rranalyze.vth_cc` gained an `after_min=True` argument that
starts the constant-current search at the ambipolar minimum, because on the extended −1.5 V
sweep a naive scan finds the hole/GIDL branch first and returns a threshold from the wrong
carrier (that produced the −241 mV/V erased DIBL). `t11_dibl` has completed and its data is
on disk. Finish that, or explicitly decide DIBL stays unreported.

---

## Task 7.1 — `figs.py`, and why it comes first

PLOT_PLAN item **0.7 was never done**, and it is the keystone of this phase. Right now 57
PNGs exist across four directories, produced by half a dozen ad-hoc scripts
(`make_device_figures.py`, `make_ecg_figures.py`, `make_extra_figures.py`,
`Calibration/autocal/pub_figure.py`, …). Nothing guarantees a figure matches the data it
claims to show — and Phase 6 found **four** figures that had silently drifted from their own
source data (`dev1`, `dev2`, `dev4`, `dev5` were pre-Phase-1 *and* pre-RR-0; `dev3` plotted
a settling transient and captioned it as retention).

Write `Paper-materials/figs.py`:

- one function per figure ID (`def A1(): ...`, `def D2(): ...`), CLI `python figs.py --fig D2`
  and `--all`;
- one shared style block — reuse `PYTHON_Modelling_Fefet_Codes/Combined Figures/figstyle.py`,
  which already encodes the supervisor's Origin rules (bold everything, ticks inside on
  left/bottom only, no title, thick spines);
- every figure emits **600 dpi PNG + vector PDF + the tidy CSV it consumed**;
- every figure reads through `Device_Optimization/norm.py` — the single width convention —
  and never hardcodes a width, Areafactor or current scale;
- **no figure may assert a number in its annotation.** Compute it from the plotted data and
  print it. Phase 6 found a publication calibration figure whose "MW = 1.30 V" was a
  hardcoded string; it happened to match, but it could never have caught a drift.

Port the existing generators into it rather than leaving both alive; delete what you port.

## Task 7.2 — PLOT_PLAN Phase 1: fix the existing deck (~1 day)

Items 1.1–1.7. These are figures that already exist and are wrong or weak: the P–V/P–E sign
flip and recaption (C2), DR vs V_read (I5) replacing deck Fig 8, LTP to semilogy with level
bands (F1), temperature + Arrhenius (F9), the retained I–V decoration (D1), the T_ox/T_fe
merges (I2, I3), retention (H1 — note `dev3_retention` has already been rebuilt correctly in
Phase 6; use it as the template for what "read after settling" looks like in a figure).

## Task 7.3 — PLOT_PLAN Phase 2: harvest what is on disk (~3 days, the bulk)

Items 2.1–2.10, roughly 60 figures, **all from data already present**. Chapters E (write
transients), G (LIF neuron, 224 currently-unused files), D5–D10, C3–C8 (field/divider),
F2–F11 (synaptic), I1–I10 (design space), B1–B9 (calibration, including B6/B7 from the
57-node `Calibration/autocal/results.csv`), A1/A4/A5/A6 (drawn), J1–J4 (planar comparison),
H2/G7.

No simulation. If a figure appears to need a run, check `Device_Optimization/outputs/`
first — there are 109 nodes and Phase 4 of the earlier work converted 483 previously dead
`.plt` files.

## Task 7.4 — PLOT_PLAN Phase 5: assemble

- **5.1** the 10 main-text composites (the grouping is already specified in PLOT_PLAN);
  remaining ~50 figures become supplementary.
- **5.2** `figures_manifest.csv`: figure ID → source `.plt`/CSV → `figs.py` function → **the
  exact claim it supports** → the normalization convention used. This kills the whole
  "where did this number come from" class of problem permanently.
- **5.3** the methods paragraph. It must cover, at minimum:
  - the 2D↔GAA Areafactor mapping and the honest statement that absolute current is **not**
    experimentally calibrated (window, V_t, SS, on/off and turn-on shape are);
  - the τ_E/τ_P protocol used per figure;
  - the two distinct ON/OFF definitions (retained window 5410× vs 9-pulse LIF contrast
    18.4×) — never adjacent, always labelled;
  - **the rules below**, which are methods-section material, not lab hygiene.

## Task 7.5 — the writing

Target venue is IEEE TED (the existing `METHODOLOGY.md` is drafted for it). The
device→SNN→system arc is already written up across `METHODOLOGY.md`, `README.md` and
`PHASE_6_RESULTS.md`; the paper is an editing job over those plus the figure catalog, not a
blank page.

The three findings that are genuinely novel and should carry the paper:

1. **Analog level *placement*, not level count, is the figure of merit.** At n = 8, four
   random level placements score 0.336–0.491 while the evenly-spaced one scores 0.804 (K2).
   Independently, accuracy after a per-device gain trim tracks the worst single-level
   misplacement at Spearman −0.85, holding 0.78–0.83 out to ≈0.6 decades and collapsing at
   ≈0.9 (K3c). Two different analyses, same conclusion.
2. **Level placement is an interface-charge problem, not a thickness problem.**
   FixedCharge ±10 % → 1.31 decades; Dit ±20 % → 0.85; T_fe ±0.3 nm → **0.07** (RR-8). This
   is the most directly actionable result in the whole set and it was the opposite of the
   expectation.
3. **Distinguishability statistics do not predict accuracy.** Three independent ones —
   RR-8's ensemble overlap, the post-gain-trim overlap, RR-8b's 3σ separability — all
   describe whether levels can be told apart *on readout*. None predicts accuracy.
   Deployed-weight error does.

And the honest scope statement, which belongs in the abstract's last line, not buried: the
core compute is 535.8 pJ/beat, and the **assumed** column ADCs are 183 nJ/beat — 342× that.
The device is not the bottleneck of a full system and the paper should say so before a
reviewer does.

---

## Rules carried forward from Phases 1–6

These produced nine caught errors between them. They are not style preferences.

1. **A ratio may only be formed from two measurements taken in the same run.** Three
   published numbers violated this (`fire_ratio`, `R_off`, `g_min`).
2. **A retained-state value must be read after settling (≥5 τ_P), and any window number must
   state its read delay.** Reading unsettled state fabricated three separate failures.
3. **A window number must also state its extraction criterion.** `cal_n16` read 1.218 V at
   1e-7 A/µm and 1.296 V at 1e-8 A/sheet — both correct, one decade apart, neither
   meaningful unbadged.
4. **`rc=0` is not a result.** Two MFM runs exited clean with zero field everywhere.
5. **A result that flatters the story deserves the same scrutiny as one that doesn't.**
6. **Count things; do not assume them.** `N_SYN` was wrong by 24× because nobody counted the
   delay taps. Every count in K4 is taken from `model.named_parameters()`.
7. **No figure asserts a number it did not compute.**

## Do not

- Do not touch `PYTHON_Modelling_Fefet_Codes/eeg detection/` — dropped. `build_defense_pdf.py`
  contains EEG sections annotated as pre-RR-4; leave them annotated, do not re-run.
- Do not retrain the locked ECG model (`paper150b_best.ckpt`).
- Do not "update" `Device_Optimization/verify_norm.py` to current numbers. It deliberately
  pins the pre-RR-0 dataset; changing it destroys its only ability.
- Do not quote RR-8b's σ without its repeat count and the fact that the run was capped.
- Do not re-harvest `t14_end10` expecting a finished run — it is a 2 h-capped partial.

## Open items

**Worth running (optional, in parallel with writing)**
- **RR-11 — 3D GAA cross-check, 4–8 h. The one run with real reviewer value.** Every
  simulation here is a 2D double-gate cross-section mapped to a nanosheet by an Areafactor.
  RR-10 proved that mapping is arithmetically exact to 1.8e-16 — but that is an identity,
  not evidence that the 2D→GAA *physics* holds (corner fields, wrapped-gate electrostatic
  control, the ambipolar branch). The paper's title claim is "gate-all-around". Expect to be
  asked; right now the answer is arithmetic.

**Not worth running**
- **RR-5 endurance.** The Preisach model has no fatigue, wake-up or imprint term, so more
  cycles produce an analytically flat line. `t14_end10` timed out at the corrected protocol
  (rc=137, 7200 s, 781 plt) and is **reported as not run**. Caption whatever exists as write
  repeatability and numerical cycle-stability, or drop H5. Do not spend host hours here.
- **`t17_c2c` to 20 repeats.** Would tighten σ from ±22 % to ±16 %; the conclusion does not
  move. Only if the queue is idle anyway.

**Needs a decision, not a run**
- S1, S2, S3 above.
- `metrics.py` MW vs the documented value: **resolved** in Phase 6 (criterion mismatch), no
  action beyond keeping the criterion stated.
- `Combined Figures/eeg figures/dev1..dev6` are stale copies of the device figures. They are
  referenced by nothing. Delete them or leave them; do not silently refresh them.
