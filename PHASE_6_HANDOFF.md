# Phase 6 handoff — SNN re-quantization against the corrected device

Paste everything below the line into a fresh session. It is self-contained.

Scope note: **ECG only. The EEG task is dropped** — do not touch
`PYTHON_Modelling_Fefet_Codes/eeg detection/`, do not re-run it, do not report it.

---

## Context

Repo: `F:\RESEARCH\FeFET x ML\TCAD Files\GAAFet`, branch `paper/gap-fix`.
Read [PHASE_1_5_RESULTS.md](PHASE_1_5_RESULTS.md) first — it is one page and it is
the ground truth for every device number.

Phases 1–5 rebuilt the device characterization. Two things changed that invalidate
the current SNN quantization, and one thing is silently wrong in the SNN itself.

### What changed in the device

| quantity | old | new | source |
|---|---|---|---|
| memory window | 0.336 V | **0.387 V** (+15 %) | RR-0, node `iv_fe07b` |
| SS | 62.3 mV/dec | **63.5 mV/dec** | RR-0, ≥2-decade fit |
| retained ON/OFF @ V_G=0 | 3137× | **5410×** | RR-0 (canonical) |
| `fire_ratio` | 30.6× | **18.4×** | self-consistent, `t8_ltp` only |
| R_off / R_on | 7.14e7 / 2.34e6 Ω | **6.767e7 / 3.680e6 Ω** | `t8_ltp` only |
| g_min / g_max | 8.86e-9 / 2.72e-7 S | **1.478e-8 / 2.718e-7 S** | `t8_ltp` only |
| retention factor | 0.971 (hardcoded) | **0.9904** (measured) | RR-4 |
| every absolute current | — | **× 0.6338** | Phase 1, exact to 1.8e-16 |

`fire_ratio = 30.6×` was pulse 9 from `t8_ltp` divided by a baseline from `mwfine`
— two different nodes, so two different post-write settling times. The rule that
prevents the whole class: **a ratio may only be formed from two measurements taken
in the same run.**

### The bug to fix first

`PYTHON_Modelling_Fefet_Codes/ecg detection/fefet_device.py` prefers a **bundled
copy** of the device CSVs:

```python
_LOCAL_RAW  = os.path.join(_HERE, "Device_Optimization", "csv_export", "raw")
_PARENT_RAW = os.path.join(_HERE, "..", "Device_Optimization", "csv_export", "raw")
_RAW = _LOCAL_RAW if os.path.isdir(_LOCAL_RAW) else _PARENT_RAW
```

That local copy exists and is **stale — it is the pre-Phase-1 data**:

```
bundled   p1 = 1.0073e-03   p15 = 1.3122e+01  uA/um
canonical p1 = 6.3844e-04   p15 = 8.3168e+00  uA/um
ratio 1.5778 = 1 / 0.6338   <- exactly the Areafactor correction
```

Consequence, stated precisely so it is neither over- nor under-claimed:
- **Accuracy is NOT affected.** `measured_levels()` returns G = I/V_read and
  downstream weights are normalized by `g_max`, so a global scale cancels. The
  locked 0.830 on-device accuracy stands.
- **Every absolute number IS affected** — g_min, g_max, R_on, R_off, energy per
  spike, energy per inference — all currently 1.578× too high.

Fix by deleting the stale bundle and letting it resolve to the canonical path, or
by pointing `_RAW` at the repo copy. Then re-verify: `python fefet_device.py`
should print `g_max/g_min` matching `gaafefet_params_optimized.py`.

## Tasks

**6.1 — Re-point the device data (do this first)**
- Remove or re-point the stale bundled `Device_Optimization/csv_export/raw/`.
- Confirm `fefet_device.py` now reads the corrected `ltp_potentiation.csv`
  (p15 = 8.3168 µA/µm) and `ltp_vs_temperature.csv`.
- Re-run `python fefet_device.py` and check the printed span against
  `Device_Optimization/gaafefet_params_optimized.py`.

**6.2 — Re-quantize**
- Re-run `post_quantize.py` against the corrected levels.
- Re-run the level ablation (2 / 4 / 8 / 15) → figure **K2**.
- Expect accuracy to be unchanged (see above). **If it moves, stop and find out
  why** — a global rescale mathematically cannot change it, so any change means
  something else moved too.

**6.3 — Update the absolute numbers**
- Energy per inference: `REDESIGN/code/energy_ledger.py`. Device write energy is
  now **0.0089 fJ/pulse**, not 0.014.
- Any R_on/R_off/g_min/g_max quoted in `README.md`, `METHODOLOGY.md`,
  `defense_prep.md` → the table above.
- `robustness_eval.py` retention is already patched to 0.9904; verify it took.

**6.4 — Variability, done honestly (figure K3)**
RR-8 ran 20 corner runs of (Dit ±20 %, FixedCharge ±10 %, T_fe ±0.3 nm).
Data: `Device_Optimization/csv_export/raw/variability_ensemble.csv` and
`variability_per_level.csv`.

Three things must not be got wrong here:
1. **It is a corner envelope, not a σ.** The runs are box corners with ≥2 axes
   off-nominal. Do not feed it to the SNN as a Gaussian d2d sigma. Use it as a
   worst case, and say so in the caption.
2. **All 14 adjacent level pairs overlap** across the box (half-spread 1.12
   decades vs 0.35 decades of spacing at level 8). This invalidates a **shared**
   15-level quantization grid across devices — which is what the SNN currently
   assumes. It does **not** mean the device has fewer than 15 levels: each device
   stays internally monotonic, so d2d variation shifts a device's whole ladder
   rather than merging its rungs, and per-device write-verify recovers them.
   The correct K3 is therefore *accuracy vs per-device calibration*, not
   *accuracy vs a blurred shared grid*.
3. **Cycle-to-cycle variability is not measured.** C2C is the variation that would
   actually destroy analog depth. RR-3's 3-cycle run is the only evidence and it
   shows the floor rising, not the levels blurring. State this as a limitation;
   do not model c2c from the d2d ensemble.

Also usable: RR-8 decomposes by axis — FixedCharge ±10 % gives 1.31 decades, Dit
±20 % gives 0.85, T_fe ±0.3 nm gives **0.07**. Level placement is an
interface-charge problem, not a thickness problem. That belongs in the paper.

**6.5 — Energy per inference (figure K4)**
Device write vs read vs peripheral, using the corrected 0.0089 fJ/pulse and the
SNN's actual spike counts.

## Rules that came out of Phases 1–5 — apply them here

1. **A ratio may only be formed from two measurements taken in the same run.**
   Three published numbers violated this.
2. **A retained-state value must be read after settling (≥5 τ_P), and any window
   number must state its read delay.** Reading unsettled state produced three
   separate fabricated failures (a retention collapse, a read-disturb collapse,
   an endurance collapse), each of which looked like responsible bad news.
3. **`rc=0` is not a result.** Two MFM runs exited clean with zero field
   everywhere. Look at the numbers.
4. **A result that flatters the story deserves the same scrutiny as one that
   doesn't.** `A_LTP = +0.045` looked like a near-ideal linear synapse and was a
   bad fit (R² 0.89) to a curve the model cannot represent.

## Do not

- Do not touch `eeg detection/` — dropped.
- Do not retrain the locked ECG model. Re-quantization only, unless 6.2 shows an
  accuracy change, which would itself be the finding.
- Do not "update" `Device_Optimization/verify_norm.py` to the new RR-0 numbers.
  It is a fixture test pinning the pre-RR-0 dataset; changing it destroys its
  only ability, which is detecting a normalization regression.

## Open device-side items (not blocking Phase 6)

- `t11_dibl`, `t12_ret15`, `t11_idvd`, `t14_end10` may still be in the Sentaurus
  queue. Check with `python runjob.py queue`; harvest with `python harvest.py`.
- DIBL is **not reported** — the two extraction criteria disagreed in sign on the
  old sweep. The requeued run should settle it.
- RR-5 endurance cannot measure fatigue: the Preisach model has no fatigue,
  wake-up or imprint term. Caption it as write repeatability.
- `metrics.py` extracts MW = 1.218 V for `cal_n16` where the docs say 1.30 V —
  two different extractions, both predating this work. Reconcile before methods.
