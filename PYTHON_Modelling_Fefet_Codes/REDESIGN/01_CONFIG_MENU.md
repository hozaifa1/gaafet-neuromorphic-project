# 01 — Circuit / code configuration menu

Grounded in `research/R2_fefet_circuits.md` (22 cites) and our calibrated device
(`Device_Optimization/OPTIMIZED_DEVICE.md`). Read `00_CRITICAL_REVIEW_AND_FACTORS.md` first
for *why* these choices. The build order is in `02_PLAN.md`.

## 0. What stays fixed (not the novelty, don't re-litigate)
- **Task/topology:** keep the LSNN that already works on this ECG task — `Input → DelayedLinear
  → recurrent[LIF + ALIF] → low-pass → linear readout`, BPTT + surrogate (SpikingJelly). The
  contribution is the **device-faithful synapse + compact neuron + rigorous protocol**, not a
  new topology. (Same modality also makes any later KD teacher legal — see R3 §4.)
- **Device:** the calibrated GAA-HZO FeFET. We exploit its real strengths — **non-volatile,
  multi-level (15 levels / ~4 decades) analog conductance, 0.014 fJ/pulse, SS ≈ 62 mV/dec, 3140×
  retained window** — as a **synapse**, never as a leak resistor.

## 1. The capacitor / leak resolution (the C2 + C3 fix, settled)
τ = R·C is a trap only if R is the device's fixed ~MΩ channel (forces µF for ms → 0.71 µJ/spike).
**Decouple τ from the device:** set the membrane time constant from a **subthreshold leak
transistor** (G_leak ≈ C_mem/τ), not from the FeFET.

```
C_mem = 1 pF, τ_mem = 5 ms  →  G_leak = C/τ = 1e-12 / 5e-3 = 0.2 nS  →  R_leak = 5 GΩ
```
A 5 GΩ path is trivial as a biased subthreshold transistor, impossible as a channel R. Energy
per membrane event ≈ ½·C·ΔV² ≈ **10–50 fJ** (C_mem 0.5–2 pF, sub-1 V swing) — vs the old
**0.71 µJ**. That is a **~10⁷× energy reduction** and the headline efficiency result. The FeFET
stays **non-volatile** (zero standby) and the leak is honestly attributed to CMOS, not the device.

## 2. Configuration menu

`★` = Stage-1 build target. Energy/density figures are the competitive 2025–26 bars from R2.

| ID | Synapse | Neuron / leak | C_mem | Pros | Cons / risk | Use as |
|----|---------|---------------|-------|------|-------------|--------|
| **A ★** | **Differential GAA-FeFET pair (G⁺−G⁻)**, 15 log-levels | Compact CMOS LIF, subthreshold leak | 0.5–2 pF | signed weights, both rails silicon-proven (R2 C2+C10), kills µF cap, device load-bearing | two FeFETs/weight (2× area) | **primary** |
| B | **Single 1FeFET-1R MLC**, 15 levels, offset for sign | Compact CMOS LIF, subthreshold leak | 0.5–2 pF | half the devices of A; simplest credible build | unsigned → needs bias/offset, lower weight SNR | simplest fallback |
| C | Differential FeFET pair | **CMOS LIF, clocked/digital leak** (cap-free) | 0 | removes cap entirely; deterministic τ | needs a clock; less "analog neuromorphic" | cap-budget stress test |
| D | Differential FeFET pair | **AFE/depolarization FeFET neuron** (cap-free, self-reset) | 0 | highest novelty (single device class, R2 C5/C6); 37 fJ/spike class | needs AFE/engineered-HZO variant we haven't calibrated | novelty stretch (later) |
| E | Bit-sliced single FeFET (no DAC) | Compact CMOS LIF | 0.5–2 pF | DAC-free read, high TOPS/W (R2 C4) | bit-slicing control overhead | efficiency variant |

**Recommended:** build **A** first (it directly satisfies every hard gate in `00 §4.2`). Keep **B**
as the minimal-area fallback to run if A's training is fiddly. **C** is a cheap ablation that
proves the cap budget. **D** is the high-novelty option to pursue *after* the FoMs are proven —
it needs device data we don't have yet (an AFE/depolarization HZO variant), so it is explicitly
not Stage 1.

## 3. How the FeFET becomes the weight (config A, the synapse model)
- Each trainable weight `w` is stored as a **differential conductance** `ΔG = G⁺ − G⁻`, with G⁺,
  G⁻ each one of the **15 measured LTP levels** (log-spaced over ~4 decades, from
  `csv_export/raw/ltp_potentiation.csv`).
- **Training (ex-situ, the credible path — R3 §3):** train an **unbounded latent** real weight,
  map to the 15-level conductance in the **forward** pass (log-domain), pass the quantizer with a
  **straight-through estimator** in the backward pass. Never train the bounded polarization
  directly — that is the 76%-ceiling trap (R3 §1).
- **Deployment:** **program-and-verify** write (pulse→read→compare). P&V masks the LTP
  nonlinearity and the abrupt erase entirely, so we never need graded LTD.

## 4. What each gate buys (traceability to `00 §4.2`)
- **G1 cap ≤ few pF** → §1 (1 pF, 5 GΩ leak).
- **G2 energy** → §1 neuron 10–50 fJ/spike + sub-fJ synaptic reads; full ledger in
  `energy_ledger.py`, target ≤ nJ/inference.
- **G3 CMOS/BEOL** → HZO FeFET + standard CMOS periphery only (configs A/B/C).
- **G4 latency** → event-driven over the ~0.6 s beat window; classify within one beat.
- **G5 robustness** → **Stage 2** (inject 15-level quant already in Stage 1; C2C/D2D/drift/T later).
- **G6 device load-bearing** → ablation: full 4-decade synapse vs clamped/binary synapse must
  measurably drop macro-F1 (cheap, run in Stage 1).

## 5. Distinguishing claim (what makes it publishable, from R1 + R2)
- **First GAA-FeFET ECG-SNN** evaluated under the **inter-patient AAMI** protocol with
  **macro-F1 / per-class Se,+P / κ** (the literature gap R1 found).
- Lead the device story on **4-decade dynamic range / 30× read window / 62 mV/dec SS → high MAC
  SNR**, not on the level count (15 is modest; the range is the differentiator — R2).
