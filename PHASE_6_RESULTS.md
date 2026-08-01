# Phase 6 — SNN re-quantization against the corrected device (ECG only)

Branch `paper/gap-fix`. Session of 2026-08-01, following
[PHASE_1_5_RESULTS.md](PHASE_1_5_RESULTS.md) and [PHASE_6_HANDOFF.md](PHASE_6_HANDOFF.md).
The EEG task is dropped and was not touched.

---

## The short version

Phase 6 is complete. The locked ECG result **did not move**: 0.8304 / 0.7536 / 0.7417,
reproduced to four decimals after the device export was corrected — which is exactly what
had to happen, since deployment normalizes by `g_max` and a global current scale cancels.

Four errors were found beyond the two the handoff named, and one instruction in the handoff
turned out to be wrong:

| | |
|---|---|
| `N_SYN = 10 700` | actually **261 440** weights / 522 880 FeFETs — the hidden layer is 160 not 100, and both delayed layers store 10 taps per connection (§6.5) |
| `dev1/2/4/5` figures | still pre-Phase-1 **and** pre-RR-0; the published memory-window figure was the superseded sweep |
| `dev3_retention` | plotted the 17.5–100 µs settling transient and captioned it as retention drift — Phase-5 error #7 baked into a figure |
| K3b noise model | mine: c2c was multiplying the weight instead of each conductance branch |
| handoff §6.4 point 3 | "quantize to the separable-level count, not 15" costs **0.42–0.48 accuracy**; the measured c2c costs 0.002 (§6.4c) |

And `cal_n16`'s MW = 1.218 vs 1.30 V was resolved as a **criterion** mismatch, not a
fabrication (§"Also fixed on the way past").

**The one result that ties the phase together:** three independent analyses — RR-8's
ensemble level overlap, the post-gain-trim overlap, and RR-8b's 3σ separability — all
describe whether levels can be *told apart on readout*, and **none of them predicts
accuracy**. What predicts accuracy is deployed-weight error: per-device level misplacement
(K3c, Spearman −0.85) and where the levels sit (K2). Level *count* and level
*distinguishability* are both the wrong figures of merit for this network.

---

## 6.1 The stale device bundle

`PYTHON_Modelling_Fefet_Codes/ecg detection/` carried its own copy of
`Device_Optimization/csv_export/raw/{ltp_potentiation,ltp_vs_temperature}.csv` and
`fefet_device.py` **preferred** it. That copy was the pre-Phase-1 export: every current in
it is `1/0.6338 = 1.5778×` the canonical value, exactly the Areafactor correction.

The fallback path (`../Device_Optimization`) was one level too shallow — the repo root is
two levels up — so the bundle was never actually bypassed and the staleness could not
surface on its own.

Fixed three ways, because a silent wrong number is worse than a loud missing one:

1. the bundle is deleted (`git rm`), so there is one source of truth;
2. `_RAW` is resolved by walking up to the first directory containing
   `Device_Optimization/csv_export/raw`, so depth is no longer hardcoded;
3. `measured_levels()` **refuses** any `ltp_potentiation.csv` whose top level is not
   8.316845 µA/µm, naming the 1.5778 ratio in the error message.

Verification (`python fefet_device.py`):

```
measured LTP levels: n=15
  G span: 1.277e-08 .. 1.663e-04 S  (dynamic range 13027x, 4.11 decades)
  absolute (x W_eff=90 nm): g_p15 = 1.4970e-05 S vs params g_max_p15 = 1.4970e-05 S
  OK: reads the canonical post-Phase-1 export.
```

### What this did and did not change

**Accuracy is unchanged.** `measured_levels()` returns `G = I/V_read` and every downstream
weight is `(G_i − G_j)/g_max`, so a global scale on `I` cancels exactly. Re-running
`post_quantize.py --levels 15` on the locked `paper150b` checkpoint reproduces the locked
result to four decimals: **0.8304 accuracy / 0.7536 macro-F1 / 0.7417 κ**, against
0.8571 / 0.7925 / 0.7819 full precision. This was the predicted outcome, and it is the
check that the correction was a normalization and not a physics change.

**Every absolute number did change**, and those are in §6.3.

---

## 6.2 Level ablation — figure K2

`fig_k2_levels.py` sweeps n ∈ {2, 3, 4, 5, 6, 8, 10, 12, 15} on the locked checkpoint, in
**two** grid constructions, because one on its own would not be believable:

- **measured subset** — n levels taken from the measured LTP ladder (endpoints kept);
  states the device demonstrably reaches;
- **log-spaced** — n levels geometrically spaced over the same span; the idealized
  designed grid, and the construction the published 2-level ablation used.

| n | measured subset acc / F1 | log-spaced acc / F1 |
|---:|---|---|
| 2 | 0.5625 / 0.2857 | 0.5625 / 0.2857 |
| 3 | 0.5625 / 0.2857 | 0.5595 / 0.2823 |
| 4 | 0.3631 / 0.2384 | 0.3423 / 0.2308 |
| 5 | 0.5060 / 0.4714 | 0.4911 / 0.4541 |
| 6 | 0.3512 / 0.1978 | 0.2292 / 0.2713 |
| 8 | 0.8036 / 0.7155 | 0.7768 / 0.7002 |
| 10 | 0.7619 / 0.6387 | 0.7976 / 0.7230 |
| 12 | **0.8452 / 0.7628** | 0.7946 / 0.6995 |
| 15 | **0.8304 / 0.7536** | 0.8274 / 0.7372 |

**Accuracy is not monotonic in n below 8 levels**, and the two constructions agree, so it is
not an artifact of how the coarse grid was built.

`fig_k2_levels.py --spread` then re-draws the **interior** levels at fixed n (endpoints
kept, 4 draws each) and shows what is really going on:

| n | random placement | evenly spaced |
|---:|---|---:|
| 4 | 0.298 – 0.562 | 0.363 |
| 6 | 0.226 – 0.777 | 0.351 |
| 8 | 0.336 – 0.491 | **0.804** |
| 10 | 0.714 – 0.810 | 0.762 |
| 12 | 0.804 – 0.851 | 0.845 |

The mechanism is the differential encoding on a 4.11-decade ladder: `|G_i − G_j|` is
dominated by `max(i, j)`, so the achievable weight set is approximately `{0, ±G_k/g_max}` —
dense near 0, very sparse near ±1. A grid that spends its levels at the bottom of the
ladder buys almost no usable weight resolution, and post-training quantization gets no
opportunity to compensate.

So the claim the figure supports is about **placement, not count**. *Level count alone is
not the figure of merit.* With arbitrary placement the classifier needs ~10–12 levels to
reach the software neighbourhood reliably; the evenly-spaced 8-level grid that scores 0.804
is a good placement, not a typical one — all four random 8-level draws scored below 0.50.

I had written the opposite ("≥8 levels is a threshold") before the spread run existed. The
spread data does not support it, and the figure now plots the individual draws as whiskers
rather than a filled envelope, since four draws per n do not justify a continuous band.

This is the same conclusion K3c reaches from the variability side, which is the reason to
trust it: **what matters is where the levels sit, not how many there are.**

---

## 6.3 The absolute numbers

| quantity | was | now | why |
|---|---|---|---|
| `R_OFF` (`energy_ledger.py`, `fefet_synapse.py`) | 1.129e8 Ω | **6.767e7 Ω** | the old value divided `t8_ltp`'s pulse-9 read by `mwfine`'s baseline — two nodes, two post-write settling times |
| `R_ON` | 3.68e6 Ω | 3.680e6 Ω | unchanged |
| read window (`R_off/R_on`) | 30.6× | **18.4×** | follows from the above |
| `g_min` / `g_max` | 8.86e-9 / 2.72e-7 S | **1.478e-8 / 2.718e-7 S** | 1/R, both from `t8_ltp` |
| write energy | 0.014 fJ/pulse | **0.0089 fJ/pulse** | Areafactor |
| retention (nominal) | 0.971 hardcoded | **0.9904 measured** | RR-4 plateau |
| synaptic weights | 10 700 | **261 440** | see §6.5 |
| LTP ladder resistance span | quoted as `R_on = 2.34 MΩ → R_off = 71.4 MΩ` | **66.8 kΩ → 870 MΩ** | the old sentence quoted the *fire-window* pair while claiming the *ladder* ratio (13 027×); they are two different measurements |

The last row was a live inconsistency in `METHODOLOGY.md` §2.4 rather than a stale number:
13 027× and 71.4/2.34 = 30.5× cannot both describe the same pair. The ladder span (level 1
→ level 15 of the potentiation train) and the LIF read window (erased baseline → read after
9 pulses) are now stated separately, with the rule that produced the confusion written
underneath.

`robustness_eval.py`'s retention patch was verified numerically, not just by reading the
source. Re-run against the corrected export (`REDESIGN/runs/robust_final.json`):

| condition | acc | macro-F1 | κ |
|---|---:|---:|---:|
| full precision | 0.857 | 0.793 | 0.782 |
| nominal 300 K (device) | 0.830 | 0.754 | 0.742 |
| 250 K (measured ladder) | 0.821 | 0.739 | 0.729 |
| 350 K (measured ladder) | 0.839 | 0.766 | 0.753 |
| D2D σ=0.1 (generic) | 0.813 | 0.724 | 0.715 |
| C2C σ=0.1 (generic) | 0.807 | 0.729 | 0.708 |
| D2D + C2C | 0.798 | 0.724 | 0.696 |
| **retention −0.96 % (measured)** | 0.821 | 0.721 | 0.728 |
| retention −10 % (stress) | 0.819 | 0.740 | 0.725 |

Two things about this table deserve saying out loud rather than being left for a reviewer
to find. **−0.96 % scores marginally below −10 %.** Both sit ≈0.03 macro-F1 under nominal
and the ordering is not meaningful: a retention factor is a uniform multiplicative gain
applied *after* quantization, and a spiking classifier with fixed thresholds responds to a
small uniform gain piecewise, through discrete spike-count changes, not smoothly. And the
D2D/C2C rows are **generic σ = 0.1 log-normal stand-ins** kept for continuity with the
earlier table — the measured variability is figure K3, and it is not a single σ.

Individual conditions also moved by ≤4 beats out of 336 versus the pre-correction run
(e.g. C2C 0.810 → 0.807). That is float32 rounding at quantization boundaries: the levels
are identical after normalization by `g_max`, but they are not bit-identical, so a handful
of weights land on the other side of a bucket edge. Worth knowing that the deployment is
boundary-sensitive at the one-beat level; not worth reading anything into.

---

## 6.4a Device-to-device variability — figure K3a

RR-8's 20 runs are the **corners** of the (Dit ±20 %, FixedCharge ±10 %, T_fe ±0.3 nm)
box: ≥2 axes off-nominal at once. That is a worst-case envelope, not a σ, so it is never
fed to the network as a Gaussian. It is used the only way it legitimately can be —
deploy the locked network onto each corner device and vary how much per-device
calibration is allowed:

- **none** — the compiler targets the nominal ladder and the nominal readout gain; the
  corner device realizes its own conductances instead;
- **gain** — one scalar per device: normalize by that device's own `g_max`, leave the
  ladder *shape* at nominal. A transimpedance trim, essentially free;
- **full write-verify** — target that device's own measured ladder per level.

| calibration | median accuracy | range |
|---|---:|---|
| none | **0.2426** | 0.069 – 0.771 |
| gain trim only | **0.7768** | 0.244 – 0.830 |
| full write-verify | **0.8304** | 0.798 – 0.860 |

**The full-calibration median is 0.8304 — the nominal device's result to four decimals**,
and every corner lands in 0.798–0.860. A gain trim alone recovers about two thirds of the
gap; the last ≈0.054 needs per-level placement.

This is the precise statement RR-8 supports, and it is narrower than "the levels overlap
so the device has fewer than 15 levels". All 14 adjacent level pairs *do* overlap across
the corner box, and that invalidates a **shared** 15-level quantization grid — which is
what the SNN previously assumed. It does not reduce any individual device's level count:
each corner stays internally monotonic, so d2d shifts a device's whole ladder rather than
merging its rungs, and per-device write-verify puts it back.

## 6.4b The overlap statistic does not predict accuracy — figure K3c

`fig_k3_variability.py ladder` decomposes each corner ladder into a rigid log-shift plus a
residual shape error (no network evaluation, pure arithmetic on the ensemble):

- mean shift from nominal: up to ±1.0 decade, median |shift| **0.51 decades**;
- residual scatter about that shift: median **0.178 decades** s.d.

The shift is what the gain trim removes. What is left is level misplacement, and **that**
is what accuracy tracks: against the worst single-level residual, gain-trim accuracy has
Spearman **−0.85** (vs −0.79 against the residual s.d. and −0.71 against the mean shift).
It holds 0.78–0.83 out to ≈0.6 decades of misplacement and collapses to ≈0.25 at ≈0.9.
Full write-verify is flat against the same axis, as it must be.

The corollary matters for how RR-8 is reported. After a per-device gain trim, **13 of 14
adjacent pairs still overlap** across the ensemble (half-spread ≈0.36 decades vs spacing
≈0.28) — and yet several of those corners deliver nominal accuracy. Ensemble overlap says
a shared grid cannot uniquely *address* a level; it does not say the deployed weight is
wrong enough to matter. The quantity that predicts accuracy is the **per-device** residual.

That turns RR-8 into a placement spec rather than a restatement, and it connects to RR-8's
axis decomposition: level placement is set by **interface charge** (FixedCharge ±10 % →
1.31 decades) and essentially not by ferroelectric thickness (T_fe ±0.3 nm → 0.07). If
per-level write-verify is available, d2d is a non-issue on this device. If only a gain trim
is affordable, interface-charge control has to hold worst-level placement inside ≈0.6
decades.

---

## 6.4c Cycle-to-cycle variability — figure K3b

RR-8b repeats the **same** 15-pulse train on **one** device, so unlike RR-8 it is a genuine
σ and is the legitimate stochastic input. The run was **capped, not completed**: the worker
killed it at 7200 s (`END t17_c2c rc=137 7200s plt=1270`) after 4 complete repeats of the
20 queued, plus a partial fifth that `rr8b` dropped by name. Reported as 4 repeats, not 20.

| | |
|---|---|
| median σ | **0.0358 decades** |
| complete repeats | **4** of 20 → relative s.e. of σ ≈ **41 %** |
| usable levels at 3σ | **6** of 15 (band 5–8 across the σ uncertainty) |

| injected σ (dec) | 0 | **0.0358** | 0.05 | 0.10 | 0.20 | 0.30 |
|---|---:|---:|---:|---:|---:|---:|
| 15-level grid | 0.8304 | **0.8284** | 0.8175 | 0.7728 | 0.3919 | 0.1657 |
| 6-level "usable" grid | 0.3512 | 0.4077 | 0.3879 | 0.4395 | 0.4435 | 0.3165 |

**At the measured σ the full 15-level grid loses 0.002 accuracy.** The knee is at
σ ≈ 0.1–0.2 decades, so the device sits 3–6× below it. That conclusion survives the thin
statistics: at 0.05 (≈ +1 s.e. on σ) accuracy is still 0.8175, and it only collapses at
0.20, which is ≈4.4 s.e. above the measurement.

### The handoff's prescription for this figure is wrong, and the data says so

The handoff instructed: *"`c2c_per_level.csv` carries a `separable_from_prev` column at a
3-sigma criterion and the analysis prints the usable level count — **that count, not 15, is
what K3 should quantize to**."*

Quantizing to that count costs **0.42–0.48 accuracy** (0.8304 → 0.3512 at σ = 0; 0.8284 →
0.4077 at the measured σ). Keeping all 15 levels under the measured noise costs 0.002.
Following the instruction would have made the reported result dramatically worse and would
have blamed the device for it.

The reason is that separability and accuracy are different questions. A 3σ criterion asks
whether a level can be **told apart from its neighbour on readout**. The network never asks
that: it needs the realized weight to sit near the target, and levels that overlap under
noise are still monotonic and still carry weight information. Discarding nine of them
throws away resolution the classifier was using, and the noise that "justified" discarding
them costs almost nothing.

This is the **third** time in Phase 6 that a level-distinguishability statistic failed to
predict accuracy — after RR-8's ensemble overlap (§6.4a) and the post-gain-trim overlap
(§6.4b). The consistent finding across all three: **overlap and separability describe
readout addressing, not deployed-weight error, and only the latter moves the classifier.**

One detail worth not over-reading: the 6-level series is *non-monotonic* in σ (0.351 →
0.408 → 0.388 → 0.440 → 0.444). Noise dithers a grid too coarse to represent the weights,
which occasionally helps — the same erratic sub-8-level behaviour K2 found, and not a
result to build on.

**Caveat carried into the paper:** 4 repeats is thin, and σ is known only to ±41 %. The
claim being made is bounded — *at and around the measured σ, cycle-to-cycle costs
essentially nothing* — not a precise σ. A completed 20-repeat run would tighten σ but
cannot change that conclusion unless the true σ is ~3× the measured one.

---

## 6.5 Energy per inference — figure K4

`fig_k4_energy.py` counts everything on the deployed network instead of assuming it, and
the count immediately found a **second pre-existing error**.

`energy_ledger.py` had `N_SYN = 3*100 + 100*100 + 100*4 = 10700`. That is wrong twice: the
recurrent layer is 160 neurons (100 LIF + 60 ALIF), not 100, and **both** the input and
recurrent layers are `DelayedLinear` with `max_delay = 10`, so every connection is ten
independently programmed taps. From `model.named_parameters()`:

```
fc1.weight        (160, 3, 10)     4 800
hidden.rc.weight  (160, 160, 10) 256 000
fc2.weight        (4, 160)           640
                            = 261 440 weights -> 522 880 FeFETs
```

24× the published count. Same class of error as the Areafactor one — a number that was
never derived from the thing it describes.

| component | energy |
|---|---:|
| device write, whole array, **one-time** | **69.6 pJ** |
| device read, event-driven | 103.9 pJ / beat |
| device read, fully clocked | 4.62 nJ / beat |
| neuron membrane | 432.0 pJ / beat |
| **core compute (event read + neuron)** | **535.8 pJ / beat** |
| peripheral ADC *(assumed 1 pJ/conv × 164 col × 1116 steps)* | **183.0 nJ / beat** |

Measured activity: 196.1 input spikes/beat (**5.86 %** line activity) and 3 455.7 hidden
spikes/beat (**1.94 %**, 21.6 spikes/neuron).

Two results are worth stating plainly:

1. **Programming the entire array costs 0.13× a single inference.** Non-volatility means it
   is paid once and never again — the concrete argument for a ferroelectric weight.
2. **The assumed ADC term is 342× the core compute.** The FeFET array is not the bottleneck
   of a real system. Reporting only the core number would overclaim, so the peripheral bar
   is in the figure rather than in a caveat. The 1 pJ/conversion figure is the single
   assumption in K4 and is labelled as such on the axis.

The previously published "~0.6 nJ per beat" survives: the measured core is 0.536 nJ.

---

## Also fixed on the way past

**`dev3_retention.png` was Phase-5 error #7 baked into a figure.** It plotted
`leak_retention.csv` (17.5 → 100 µs) and captioned the −2.9 % across that window as
retention drift. That window sits *inside* the post-write settling transient, which relaxes
with τ_P = 10 µs. Rebuilt from `retention_long.csv` out to 10 ms on a log time axis: the
transient — a 9× overshoot decaying away by 50 µs = 5 τ_P — is shaded and labelled as
settling, and the retained plateau is **−0.62 % over 2.3 decades**. The figure is now the
visual justification for the "read after settling" rule rather than a counterexample to it.

`build_defense_pdf.py` captions, its robustness table and its energy paragraph follow. The
**EEG** robustness paragraph still cites −2.9 % because that run genuinely used it; rather
than leave one document asserting two values for the same measurement, it is annotated
in place as pre-RR-4 and pessimistic. Nothing under `eeg detection/` was touched or re-run.

**The device figures in the paper package were pre-Phase-1 and pre-RR-0.**
`make_device_figures.py` reads the canonical repo-level export, so the *script* was right —
the PNGs and CSVs had simply never been rebuilt. `dev1_LTP_ladder.csv` held
p1 = 2.0146e-08, p15 = 2.6244e-04 S/µm against the canonical 1.2769e-08 / 1.6634e-04:
ratio 1.5778, the Areafactor factor again, one directory over from the bundle in §6.1.

Rebuilding also pulled RR-0 through for the first time. `dev5_memory_window` went from the
superseded 200-point sweep to the canonical 41-point retained I–V (`iv_fe07b`, −1.0…+1.0 V
at 50 mV): erased 4.504e-3 and programmed 24.37 µA/µm at V_G = 0, MW = 0.39 V, with the
ambipolar minima at V_G ≈ −0.25 V (erased) and −0.55 V (programmed) now visible. The
published memory-window figure had been the pre-RR-0 one.

Affected and now regenerated: `dev1`, `dev2`, `dev4`, `dev5`. `dev6` (the differential
weight map) moved only in float rounding, as it must — it is normalized by `g_max`.

`Combined Figures/eeg figures/dev1..dev6` hold the same stale copies and were **left
alone**: EEG is dropped, and `build_defense_pdf.py` references only the ECG set, so no
document shows two values for one measured ladder. They are dead artifacts — flagged here
rather than edited, so a future session does not mistake them for current.

**The `cal_n16` memory-window discrepancy is resolved, and it was not a fabrication.**
`metrics.py` reported MW = 1.218 V where the calibration docs and the publication figure
said 1.30 V. Both are correct constant-current extractions on the same data, one decade
apart in criterion:

| extraction | criterion | V_t,ERS | V_t,PGM | MW |
|---|---|---:|---:|---:|
| `pub_figure.py` (the published overlay) | 1e-8 A / nanosheet | +0.362 | −0.934 | **1.296 V** |
| `autocal/metrics.py` (the calibration loss) | 1e-7 A/µm ≈ 1e-9 A/sheet | −0.556 | −1.774 | **1.218 V** |

The figure's annotation reproduced its own data to three decimals — but it was a
**hardcoded string**, so it could not have caught a drift, and neither document said which
criterion it meant. `pub_figure.py` now computes MW, both V_t, I_on and I_on/I_off from the
plotted curves and prints the criterion on the figure. The rule generalizes the Phase-5
one: *a window number must state its extraction criterion as well as its read delay.*

**K3b's noise model was wrong before it ran.** Cycle-to-cycle was multiplying the *weight*.
c2c is a property of each programmed conductance, so `G⁺` and `G⁻` must be perturbed
independently — `kfig_common.paired_branches` now carries the branch provenance of every
achievable weight. The weight-level form silently understates the noise for near-zero
weights, where `G⁺ ≈ G⁻` and the difference is small but each branch's jitter is not.

---

## Reproducing

```
cd "PYTHON_Modelling_Fefet_Codes/ecg detection"
python fefet_device.py                      # device export guard + span cross-check
python post_quantize.py --ckpt REDESIGN/runs/paper150b/paper150b_best.ckpt --levels 15
python robustness_eval.py --ckpt REDESIGN/runs/paper150b/paper150b_best.ckpt --tag robust_final
python fig_k2_levels.py                     # K2   (+ --spread, --replot)
python fig_k3_variability.py d2d            # K3a  (+ gain, replot)
python fig_k3_variability.py c2c            # K3b  (needs raw/c2c_per_level.csv)
python fig_k4_energy.py                     # K4   (+ --replot)
cd "../Combined Figures" && python make_extra_figures.py ecg && python build_defense_pdf.py
```

Every figure writes its PNG, its reproducing CSV, and a JSON of the underlying sweep into
`REDESIGN/runs/`, so all four can be re-plotted without re-evaluating the network.
