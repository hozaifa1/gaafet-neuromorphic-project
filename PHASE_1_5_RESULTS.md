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
| **RR-2** output family | ohmic at low V_DS for every analog state, r = 0.958–0.998; DIBL **59.5 mV/V** erased (see §6) |
| **RR-3** LTD | monotonic; depression depth 11650×; loop closes to **96.2 %** |
| **RR-3** 3 cycles | window 11650 → 4187 → 3577×, entirely from the floor rising |
| **RR-4** retention | settles in ~5 τ_P then flat to 0.62–0.96 % over 2.3 decades |
| **RR-6** 2D maps | 104 CSVs; window visible as 4.4 decades of channel carrier density |
| **RR-7** design space | all 25 cells; ≤30 ns does not program at any voltage |
| **RR-8** variability | all 14 level pairs overlap; **FixedCharge dominates, T_fe is negligible** |
| **RR-9** read disturb | **0.0000 %** over 9.9e5 equivalent reads |
| **RR-10** Areafactor sanity | rescale exact to **1.8e-16** (double-precision epsilon) |
| **RR-8b** cycle-to-cycle | **8 of 15 levels separable at 3σ** — the headline number |
| **RR-5** endurance | **not delivered** — see §6 |

### RR-1 validates the calibration
±1.96 V (= 2·F_c·T_fe, as the checklist specified) does **not** saturate a Preisach
loop — it gave P_s = 32.8, which reads as a 20 % calibration failure. Saturation
needs ~5·F_c, where the independent MFM capacitor reproduces the locked `cal_n16`
par to four significant figures. The amplitude series is kept as the evidence the
loop is saturated rather than an assertion that it is.

This also finally quantifies defect **C5**: the MFIS gate-stack loop reaches
0.55·F_c and 12 % of P_r, so the deck's "HZO P–E loop" is a *deep* minor loop, and
the voltage divider is the whole story.

### RR-8b — the analog depth is 8 levels open-loop, not 15
**Eleven** completed repeats of the same 15-pulse train on ONE device (`t17_c2c`;
the run hit the 2 h cap at 11 of the 20 queued repeats — `rr8b` keeps the complete
repeats and drops the partial one by name). Eleven is enough for a σ, but the σ
itself carries a relative standard error of ≈22 %, and **the repeat count must be
quoted next to the σ everywhere**, because the run was cut short.

Levels 1–8 are separable at 3σ. **Levels 9–15 are not.** The LTP curve
saturates, so 9–15 sit inside **0.114 decades** at the top of the range while the
c2c σ over those levels is **0.0131–0.0187 decades** (median σ across all 15
levels, **0.0215 decades**, is set by level 8). At level 15 the spacing is
**0.0085 decades** against a σ of **0.0131** — the levels are closer together
than the noise.

Both of these are defensible, but only one is currently claimed:

| protocol | levels | bits |
|---|---|---|
| open loop — n pulses, no verify (**what the LTP figure shows**) | **8** | 3.0 |
| closed loop — write-verify to placed targets | ~16 | 4.0 |

**Decision taken in Phase 7 — this is what the paper claims.** The two numbers are
answers to two different questions and the paper states both, in the same place,
each with its protocol attached:

| claim | number | basis |
|---|---|---|
| the device, open loop, no verify circuitry | **8 levels** | levels 9–15 span 0.114 dec; c2c σ 0.0131–0.0215 dec |
| the device, with write-verify | **~16 levels** | measured range 3.79 dec at 3σ placement |
| what the network was deployed on | **15 levels** | assumes a write-verify array |

The network result is stated as assuming a write-verify array, in both the device
section and the network section. This is not a concession: K3a shows write-verify
is unavoidable for this device regardless of level count — deploying onto the 20
corner devices without per-device calibration gives 0.243 accuracy, with it 0.8304,
which equals the nominal result to four decimals. The system pays for write-verify
either way, so the 15-level claim costs nothing extra.

The 3.79-decade range does support ~16 levels, but reaching them needs verify
circuitry and per-write iteration — a system cost the paper would have to own.
**"15 levels" is defensible only as a write-verify claim.** This is the number
Phase 6's K2/K3 must quantize to, and it is why c2c, not d2d, sets analog depth:
d2d shifts a device's whole ladder and write-verify recovers it, c2c blurs the
rungs of one device and nothing recovers it.

### RR-10 proves the Phase 1 rescale needed no re-simulation
Re-running one node at the geometrically correct `Areafactor = 0.045` and dividing
by the same node at 0.071 gives **0.633802816901** against an expected
0.633802816901 — a relative error of 1.8e-16, i.e. double-precision epsilon. That
is the methods-section answer to "why did you not re-run everything after changing
the normalization": Areafactor is a pure post-multiplier on contact quantities and
the correction is exact arithmetic.

### RR-8 — the variability is an interface-charge problem, not a thickness problem
All 20 corners in. At LTP level 8 the corner spread decomposes as:

| axis | perturbation | spread of group medians |
|---|---|---|
| **FixedCharge** | ±10 % | **1.31 decades** |
| Dit | ±20 % | 0.85 decades |
| T_fe | ±0.3 nm | **0.07 decades** |

This was the opposite of the expectation — HZO thickness sets the coercive
voltage, so it looked like the obvious lever — and it is the most directly
actionable result in the whole set: **analog level placement is set by interface
charge control, not by ferroelectric thickness control.** A ±0.3 nm HZO tolerance
costs 0.07 decades; ±10 % of fixed interface charge costs 1.31. An
order-of-magnitude check agrees: ΔQ_f = 0.7e12 cm⁻² over C_ox(1 nm) is ~32 mV of
V_t shift, roughly half a decade at 63 mV/dec, rising once the FE divider is
included.

What the overlap does and does not mean is in §5 of the analysis output: it
invalidates a *shared* quantization grid across devices, but each device stays
internally monotonic, so per-device write-verify recovers the levels. The
variation that would actually destroy analog depth is cycle-to-cycle, which this
ensemble does not measure.

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

**RR-5 endurance — not delivered, and why**
Three deck versions. Single 1 µs and single 5 µs pulses per polarity both failed
because one pulse never erases a programmed device (erase is opposed by the
depolarization field; RR-3 measures the first −2 V pulse moving the state 18 %).
The 15-pulse-train version is correct but hit the 2 h cap at cycle ~6, and the
previous run's cycle-10 files survived on the host and were silently combined
into one CSV. That data is deleted. RR-5 remains structurally incapable of
measuring fatigue anyway — the Preisach model has no fatigue, wake-up or imprint
term — so the honest options are to caption it as write repeatability or to omit
it. RR-3's 3-cycle run is the real cycling evidence.

**Running or queued**
- RR-5: `t14_end100` completed (2513 s). **`t14_end10` at the corrected protocol did NOT
  complete** — killed by the worker's 2 h cap on 2026-08-01 (`END t14_end10 rc=137 7200s
  plt=781`). It was progressing, not crawling: 781 `.plt` in 7200 s against `t14_end100`'s
  422 in 2513 s. The corrected 5 µs write protocol is simply much more expensive per cycle
  than the superseded single-pulse deck that finished in 307 s. **Reported as not run.**
  (The kill was clean — `csh` exec'd `sdevice`, so no orphan held the shared license.)
  `outputs/t14_end10/` now holds the **781 `.plt` of the truncated corrected-protocol run**
  — a later harvest pass (invoked with an explicit `--nodes` list, which bypasses the
  already-local skip) replaced the 55 `.plt` of the superseded 307 s single-pulse run. That
  is the *cleaner* of the two states, not a blend: the directory is one protocol throughout.
  No endurance CSV was regenerated — `rr5` declined the deck — so nothing downstream moved.
  **Anyone re-running `rr5` on this node must know it is an incomplete 2 h-capped run**, not
  a finished ten-cycle sweep.
- RR-2: `t11_dibl` requeued with the sweep extended to −1.5 V.
- `t14_end1000`: parked at the back of the queue. It needs ~8 h at the corrected
  5 µs write and will hit the 2 h job timeout. **If it does not complete it is
  reported as not run**, not silently dropped.

**Needs a decision or further work**
- **Phase 6 SNN re-quantization.** MW moved 0.336 → 0.387 V (+15 %) and `fire_ratio`
  30.6 → 18.4×, so the STE weight grid must be rebuilt. Outside Phases 1–5.
- ~~**DIBL is not reported.**~~ — **RESOLVED (Phase 7).** The requeued `t11_dibl`
  landed and `vth_cc(after_min=True)` fixed the sign inversion: the wide −1.5 V
  sweep has a V-shaped off state, and the naive search was reading a threshold off
  the ambipolar falling branch. At a fixed criterion I_cc = 6.338e-3 µA/µm (the
  lowest level crossed by all four curves) **both branches now give the same
  sign**:

  | branch | V_t @ V_DS = 0.05 V | V_t @ V_DS = 0.5 V | DIBL |
  |---|---|---|---|
  | erased | +0.0253 V | −0.0014 V | **59.5 mV/V** |
  | programmed | −0.3737 V | −0.5128 V | **309.0 mV/V** |

  **Report 59.5 mV/V as the device DIBL**, stating the criterion. It is a normal
  short-channel value for a 100 nm gate on a 5 nm body. The programmed branch is
  5× larger and is *not* explicable as electrostatic DIBL at this geometry; the
  likely cause is the drain field acting on the ferroelectric itself — a
  drain-induced polarization change. **That is a separate claim and this run does
  not establish it.** Report it, flag it as open, and name the measurement that
  would settle it (P_y probed at the drain end vs V_DS, or a non-ferroelectric
  control). Do not quietly report only the erased branch.
- ~~**Cycle-to-cycle variability is not measured.**~~ — **RESOLVED.** RR-8b
  (`t17_c2c`) measures it directly: 11 complete repeats of one 15-pulse train on
  one device, median σ 0.0215 decades. RR-8 remains device-to-device only.
- ~~**`metrics.py` MW = 1.218 V vs the documented 1.30 V** for `cal_n16`~~ —
  **RESOLVED (Phase 6).** Both are correct constant-current extractions on the same
  data, one decade apart in criterion: `pub_figure.py` uses 1e-8 A per nanosheet
  (MW = 1.296 V, V_t = −0.934 / +0.362), `metrics.py` uses 1e-7 A/µm ≈ 1e-9 A/sheet
  (MW = 1.218 V). `pub_figure.py` now **computes** its annotation from the plotted
  curves instead of asserting it, and prints the criterion on the figure. The rule
  generalizes the Phase-5 one: a window number must state its **extraction criterion**
  as well as its read delay.
- **RR-5 can never measure endurance.** The model has no fatigue, wake-up or
  imprint term. The run shows write repeatability and numerical cycle-stability;
  real endurance is a measurement, and the caption must say so.
- **RR-11** (3D GAA cross-check) not attempted — optional, 4–8 h.
