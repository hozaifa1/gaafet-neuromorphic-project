# Phases 1–5 — results, corrections, and what is still open

Session of 2026-07-31 → 08-01. Branch `paper/gap-fix`.
Every number below is reproducible from the repo: `rranalyze.py <rrN>` regenerates
the CSV and reprints the analysis.

---

## 1. The short version

Phases 1–4 are complete. Phase 5 is substantially complete: 7 of 9 sub-parts have
landed and been analysed, and what remains is listed in §6.

The work found **nine** errors. Four were pre-existing; five I introduced and then
caught. Three of the five would have put a *fabricated failure* in the paper — a
retention collapse, a read-disturb collapse, and an endurance collapse — each of
which looked like responsible bad news and would likely have survived review.

---

## 2. Phase 1 — one width convention

`Device_Optimization/norm.py` is now the only place in the repository that defines
a width, an Areafactor or a current scale. Fourteen scripts import it.

The 2D cross-section is double-gated, so a slab of z-depth *A* carries gate width
*2A*; matching the nanosheet perimeter `TESW = 2(W+T_si) = 90 nm` gives
`Areafactor = 0.045`, not the 0.071 every run actually used. Areafactor is a pure
post-multiplier on contact quantities, so the correction is an exact rescale of
**×0.6338** — nothing was re-simulated.

| quantity | published | corrected |
|---|---|---|
| ON @ V_G=0 | 29.5 µA/µm | **18.7** |
| OFF @ V_G=0 | 9.41e-3 | **5.96e-3** |
| LTP level 15 / 1 | 13.1 / 1.01e-3 | **8.31 / 6.39e-4** |
| R_off / R_on | 7.14e7 / 2.34e6 Ω | **1.13e8 / 3.68e6** |
| energy per pulse | 0.014 fJ | **0.0089** |
| window, SS, MW | 3137×, 62.3 mV/dec, 0.336 V | unchanged (ratios and voltages) |

`verify_norm.py` re-derives all nine headline numbers and passes. It deliberately
pins the *pre-RR-0* dataset — it is a fixture test for normalization regressions,
not a statement of the paper's current values.

The nine raw CSVs had **no generator at all** before this; `rebuild_raw.py` now
regenerates each from its source `.plt` with the provenance recorded.

## 3. Phase 4 — the unexported nodes

483 `.plt` across 12 dead run nodes converted; CSVs **894 → 1377**. (PLOT_PLAN
estimated ~580 files / ~1450 CSVs; the real counts are above.) All 29 columns are
present, so the previously unreachable quantities — gate charge, displacement
current, the eCurrent/hCurrent split, source-contact balance — are now available.

## 4. Phases 2, 3, 5 — the re-runs

| run | result |
|---|---|
| **RR-0** retained I–V | MW **0.387 V**, SS **63.5 mV/dec**, ON/OFF **5410×**, ΔP = −2.57e-6 C/cm² |
| **RR-1** MFM P–E | at 5.1·F_c: P_s **39.99**, P_r **31.99**, F_c **1.400** vs targets 40 / 32 / 1.4 |
| **RR-2** output family | ohmic at low V_DS for every analog state, r = 0.958–0.998 |
| **RR-3** LTD | monotonic; depression depth 11650×; loop closes to **96.2 %** |
| **RR-3** 3 cycles | window 11650 → 4187 → 3577×, entirely from the floor rising |
| **RR-4** retention | settles in ~5 τ_P then flat to 0.62–0.96 % over 2.3 decades |
| **RR-6** 2D maps | 104 CSVs; window visible as 4.4 decades of channel carrier density |
| **RR-7** design space | all 25 cells; ≤30 ns does not program at any voltage |
| **RR-8** variability | all 14 adjacent level pairs overlap across the corner box |
| **RR-9** read disturb | **0.0000 %** over 9.9e5 equivalent reads |

### RR-1 validates the calibration
±1.96 V (= 2·F_c·T_fe, as the checklist specified) does **not** saturate a Preisach
loop — it gave P_s = 32.8, which reads as a 20 % calibration failure. Saturation
needs ~5·F_c, where the independent MFM capacitor reproduces the locked `cal_n16`
par to four significant figures. The amplitude series is kept as the evidence the
loop is saturated rather than an assertion that it is.

This also finally quantifies defect **C5**: the MFIS gate-stack loop reaches
0.55·F_c and 12 % of P_r, so the deck's "HZO P–E loop" is a *deep* minor loop, and
the voltage divider is the whole story.

### C2 is resolved, and was never an inconsistency
The three "erased at V_G = 0" values differ by post-write settling time:

| node | reads before V_G=0 | erased | programmed |
|---|---|---|---|
| mw_fe07 | 4 (0.24 µs) | 5.96e-3 | 18.70 |
| mwfine | 8 (0.48 µs) | 4.92e-3 | 20.95 |
| **iv_fe07b** | 20 (1.20 µs) | **4.50e-3** | **24.37** |

The states move *apart* as the state relaxes on the τ_E scale, so the
longest-settled read is the truest. `OPTIMIZED_DEVICE.md` now fixes **iv_fe07b's
5410×** as canonical and quotes the others as protocol variants.

---

## 5. The nine errors

**Pre-existing (4)**
1. **Areafactor** — three conflicting width conventions, none derived from geometry (§2).
2. **`fire_ratio = 30.6×`** — pulse 9 from `t8_ltp` over a baseline from `mwfine`.
   Self-consistent value: **18.4×**. `R_off`/`g_min` mixed nodes the same way.
3. **The `iv_fe07` node was dead.** `app_frozen.par` has τ_P = τ_E = 1e-4, so its
   500 µs write hold is five depolarization constants — the probe read
   P_y = +2.33e-7 C/cm² in *both* states. Figure D1 descended from it.
4. **PLOT_PLAN C1 was wrong** about `transfer_curves.csv`'s provenance (it comes
   from `mwfine`/`app_opt.par`, so there is no τ protocol split).

**Mine, caught before they reached the paper (5)**
5. **Non-converging read sweeps.** `RelErrControl` walks the timestep to `MinStep`
   and never recovers: a deck *crawls* rather than failing. Three decks hit it
   (71 MB, 143 MB, 344 MB logs). Fixed structurally — instant hops instead of
   finely stepped Goal ramps, `MinStep` floors proportional to `MaxStep`, a 2 h
   per-job timeout, and the MFM on Synopsys's own reference timing.
6. **`%.6e` timestamps.** Seven significant digits, so past ~10 ms a 1 ns rise
   rounds away and Sentaurus aborts on duplicate stamps. Killed `t12_ret15`; would
   have killed every endurance deck. Now 12 digits, verified before upload.
7. **RR-4 retention.** Fitting one power law across both the settling transient and
   the plateau returned "retention factor 1.5e-3 at 10 years" — total data loss
   from a provably flat signal — and E_a = −0.254 eV, unphysical.
8. **RR-9 read disturb.** Measuring from the immediate post-write value gave
   "−84.7 %, window 3702 → 568×". That drop is the τ_P transient. From the settled
   state: **0.0000 %**.
9. **RR-5 endurance.** Reported the window collapsing 539× → 1.5× in ten cycles.
   The ceiling never moved; the erased floor climbed 0.042 → 22.1 µA/µm because a
   single 1 µs pulse per polarity does not fully switch the device. The Preisach
   model has no fatigue term, so apparent degradation *had* to be protocol.

**Errors 7, 8 and 9 are the same mistake three times**: comparing an unsettled
post-write value against a settled one. Two rules are now written into the code
and belong in the methods section:

> A ratio may only be formed from two measurements taken in the **same run**.
> A retained-state value must be read **after settling** (≥ 5 τ_P), and any window
> number must state its read delay.

---

## 6. Still open

**Running or queued**
- RR-8: 15 of 20 corner runs still to land.
- RR-5: `t14_end10` / `t14_end100` requeued at the corrected protocol.
- RR-2: `t11_dibl` requeued with the sweep extended to −1.5 V.
- RR-10: `t16_af045` Areafactor sanity check.
- `t14_end1000`: parked at the back of the queue. It needs ~8 h at the corrected
  5 µs write and will hit the 2 h job timeout. **If it does not complete it is
  reported as not run**, not silently dropped.

**Needs a decision or further work**
- **Phase 6 SNN re-quantization.** MW moved 0.336 → 0.387 V (+15 %) and `fire_ratio`
  30.6 → 18.4×, so the STE weight grid must be rebuilt. Outside Phases 1–5.
- **DIBL is not reported.** The two extraction criteria disagree in sign, which
  means V_t is being read outside a clean subthreshold region. The requeued run
  should settle it; until then no DIBL number should be quoted.
- **Cycle-to-cycle variability is not measured.** RR-8 is device-to-device only.
  C2C is the variation that would actually destroy analog depth, and RR-3's
  3-cycle run is the only evidence (it shows the floor moving, not levels blurring).
- **`metrics.py` MW = 1.218 V vs the documented 1.30 V** for `cal_n16` — two
  different extractions, both predating this work. Reconcile before the methods
  section.
- **RR-5 can never measure endurance.** The model has no fatigue, wake-up or
  imprint term. The run shows write repeatability and numerical cycle-stability;
  real endurance is a measurement, and the caption must say so.
- **RR-11** (3D GAA cross-check) not attempted — optional, 4–8 h.
