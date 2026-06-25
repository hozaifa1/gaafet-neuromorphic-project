# 00 — Critical review of the prior work + what we must optimize for

**Role I am taking:** the harshest reviewer your device paper will ever see (IEEE TED /
Nature Electronics desk). The goal of this document is *not* to make the old result look
good. It is to find every reason a reviewer rejects it, and to fix the framing before we
write a single new line of model code.

Inputs reviewed:
- `PYTHON_Modelling_Fefet_Codes/` (the existing code: `model_2.py`, `main_ecg_8c/8d`,
  `dataset.py`, `surrogate.py`, `utils.py`, `gaafefet_params.py`, `vo2_encoder.py`).
- `ecg_gaafefet_simplified.pdf` and `ecg_gaafefet_2.pdf` (the prior write-up of the
  "bad device" run).
- `Device_Optimization/OPTIMIZED_DEVICE.md`, `SNN_PARAMETERS.md` (the **new** calibrated
  device — this is what we actually build on now).

---

## 1. What the prior work actually did (so we critique the real thing)

- **Task:** ECG arrhythmia, 4 AAMI-ish classes (N, F, SVEB/S, VEB/V). 2000 beats,
  **1664 train / 336 test**, delta-modulated to 3 spike channels (up, down, cue),
  1116 time-steps, `dt = 0.556 ms`.
- **Network:** a port of the Nature Communications 2023 VO₂ paper (NCOMMS-23-03137):
  `Input → DelayedLinear → recurrent[60 LIF + 40 ALIF] → low-pass filter → linear readout`.
  Trained with BPTT + surrogate gradient (SpikingJelly).
- **Two device models were tried:**
  1. **RC abstraction** (`model.py`, the "working" one): the FeFET is a **2-state
     resistor** (R_off = 5250 Ω, R_on = 2580 Ω) feeding an **external capacitor
     `C_mem = 1.419 µF` per neuron**; τ = RC = 11.11 ms. **Result: 90.18%.**
  2. **Polarization physics** (`model_2.py`): neuron state = bounded polarization
     `P ∈ [0,1]`, Preisach-like saturating switching. **Result: stalled at 76.49%**;
     knowledge distillation from the RC teacher collapsed it to 50.89% (majority class).
  3. Baseline: the original VO₂ design = 89.58% on the same split.

So the headline was *"FeFET RC model 90.18% > VO₂ 89.58%."*

---

## 2. Why this gets rejected — the teardown

### CRITICAL — C1. The device is not the source of the result.
The 90.18% model uses **R_off/R_on ≈ 2.04×**. A 2× resistance modulation on the leak
resistor of an RC neuron is a *weak* perturbation; the integration, the memory, and the
discriminative power all live in (a) the external capacitor and (b) the **trained
synaptic weights / delays** — which are the VO₂ paper's architecture, not the FeFET.
**Falsification test a reviewer will run in their head:** swap the FeFET for *any* 2-state
resistor (or a fixed resistor) and the accuracy barely moves. The paper's central claim —
"the GAA-FeFET enables this" — is therefore unsupported by its own working model. This
alone is a reject.

### CRITICAL — C2. A 1.419 µF capacitor *per neuron* annihilates the neuromorphic claim.
On-chip MIM/MOS capacitor density is ~5–10 fF/µm². `C_mem = 1.419 µF` ≈ **0.15–0.3 m² of
capacitor area for ONE neuron**, and the network has 100 neurons (~142 µF total). This is
a benchtop RC circuit, not a chip. Every "low power / compact / brain-like" sentence in
the paper is contradicted by this one number. This is exactly the failure mode you flagged:
the capacitor makes the circuit so big/inefficient that the entire advantage of
neuromorphic + GAAFET evaporates.

### CRITICAL — C3. The "leak" is physically incoherent for this device.
The RC model's leak is the external-capacitor discharge through the FeFET resistor. But the
**calibrated device is non-volatile — it does not self-leak at V_G = 0** (stable over
100 µs). So the leak the model relies on is *not a property of the FeFET*. The model
conflates "device retention" with "neuron membrane leak." A device paper cannot claim the
FeFET provides the LIF dynamics when the FeFET measurement says the opposite.

### HIGH — H1. Evaluation protocol will not survive ECG peer review.
- **336 test beats** is tiny; a 1–2 beat swing moves accuracy ~0.5 pp.
- **Class imbalance:** N dominates. Top-1 accuracy near ~90% can be close to the
  majority-class prior. **Accuracy alone is not acceptable** for AAMI ECG in 2025.
  Reviewers require **macro-F1, per-class sensitivity/+P (precision), and Cohen's κ**.
- **Patient split:** if this is an *intra-patient* split (beats from the same patient in
  train and test), the number is inflated and non-comparable to the AAMI **inter-patient**
  standard. We must confirm and, ideally, move to inter-patient. *(Being verified by the
  SOTA research agent — see `research/R1_sota_ecg_snn.md`.)*

### HIGH — H2. The 76% "honest ceiling" is a training artifact, not a device limit.
The polarization model stalls because BPTT gradients **die at the saturation boundaries**
of a bounded `P ∈ [0,1]` Preisach sigmoid, and KD from a physically-incompatible RC teacher
collapses it. These are well-understood, fixable ML pathologies (surrogate width
scheduling, log-/unbounded-latent reparameterization, gradient rescaling, drop bad KD).
Presenting 76% as the device's ceiling is wrong and concedes the paper's whole thesis.

### MEDIUM — M1. Energy accounting is apples-to-oranges.
`gaafefet_params.py` mixes a **97 fJ read estimate** (old) with a **0.014 fJ program**
(new) and never builds a per-inference budget. We need one clean energy ledger:
synaptic MACs + neuron updates + capacitor charge/discharge + readout/ADC, per beat.

### MEDIUM — M2. No co-design; it's a port.
The architecture is inherited verbatim from the VO₂ paper. Your explicit requirement is
"not a copy and not a patch." A port that swaps the resistor value is exactly the thing to
avoid. The redesign must make the **FeFET's distinctive capability** (non-volatile,
15-level analog weight, sub-fJ program, 3140× window) *load-bearing* for the result.

---

## 3. The reframe — use the device for what it actually is

The prior work used the FeFET as the neuron's **leak resistor** (a volatile-dynamics role)
and kept the weights in software. That is backwards for this device. The calibrated device
is a **non-volatile, multi-level analog memory + steep switch**:

| Measured capability | Right role | Wrong role (prior) |
|---|---|---|
| 15 analog levels, 4 decades, monotone LTP | **synaptic weight** (in-memory MAC) | (unused) |
| 3140× retained ON/OFF, ΔV_t ≈ 0.3 V | weight dynamic range / steep readout | 2× leak modulation |
| Non-volatile, no self-leak | **zero standby power** weight storage | (mis)used as leak ✗ |
| 0.014 fJ/pulse program, SS 62 mV/dec | sub-fJ weight update, sharp transfer | — |

**Design thesis for the redesign:** the FeFET is the **synapse** (and optionally the
threshold element), and the small amount of *temporal* leaky-integration the LIF needs is
done by a **compact CMOS membrane (fF–pF), not a microfarad cap** — or is removed entirely
in a non-leaky / clocked formulation. This makes the device load-bearing (kills C1),
deletes the giant capacitor (kills C2), and stops pretending the FeFET leaks (kills C3).

The concrete circuit options that implement this thesis are enumerated in
`01_CONFIG_MENU.md` (informed by `research/R2_fefet_circuits.md`).

---

## 4. What we optimize for — the factor list and figure of merit (decided)

You asked me to decide the exact factor set first. Answer: **it is not one thing — it is a
primary objective plus hard constraints that, if violated, void the neuromorphic/GAAFET
story.** Optimizing accuracy while blowing the capacitor budget (the prior mistake) is
worthless. So:

### 4.1 Primary objective (what we maximize)
- **Predictive quality on ECG, reported the way reviewers demand:**
  **macro-F1 first**, then accuracy, then Cohen's κ and per-class Se/+P — under the
  **AAMI inter-patient** protocol. Beating SOTA on accuracy *and* macro-F1 under the
  credible protocol is the headline. (Target number set in `R1_sota_ecg_snn.md`.)

### 4.2 Hard constraints (gates — a config that fails any of these is disqualified)
These encode "don't undermine the advantage of neuromorphic + GAAFET":

| # | Constraint | Threshold (working target, refine with R2) | Why |
|---|---|---|---|
| G1 | **Membrane capacitance / neuron** | ≤ a few pF (on-chip realistic); ideally cap-free | the C2 killer; must stay integrable on-die |
| G2 | **Energy / inference (per beat)** | ≤ ~nJ-class, with sub-fJ synaptic ops | the "low power" claim must be real, end-to-end |
| G3 | **CMOS / BEOL compatibility** | HZO FeFET + standard CMOS periphery only; no exotic parts | manufacturability |
| G4 | **Latency / throughput** | classify within one beat window (~0.6–1 s); real-time | it's a real-time biosignal task |
| G5 | **Robustness** | accuracy/macro-F1 retained under injected device variability, 15-level quantization, retention drift, and 250–325 K temperature | a device paper must show on-chip-realistic numbers, not ideal-only |
| G6 | **Device is load-bearing** | ablation (replace FeFET with ideal/2-state element) must *measurably* degrade the result | directly answers C1 — the reviewer's first attack |

### 4.3 Secondary figure of merit (to rank configs that all pass the gates)
A single scalar to compare the surviving configurations, EDAP-style:

```
FoM  =  macro_F1  /  ( E_inference  ×  Area  ×  Latency )      (higher = better)
```
with Area dominated by **(capacitor area + FeFET-array area + CMOS-neuron area)** and
E_inference the full per-beat ledger from M1. We also track a robustness margin
(Δmacro-F1 between ideal and hardware-aware-noisy) as a tiebreaker — a slightly lower but
far more robust config wins for a device paper.

### 4.4 Ranked priority (when they conflict)
1. **macro-F1 under inter-patient AAMI** (beat SOTA credibly) —
2. **G6 device-is-load-bearing** (no paper without this) —
3. **G1 capacitor + G2 energy** (the neuromorphic claim) —
4. **G5 robustness** (the device-paper credibility) —
5. **G3/G4 CMOS + latency** (table stakes) —
6. **secondary FoM** to pick among survivors.

---

## 5. Immediate consequences for the code
- Stop treating the FeFET as a leak resistor; stop using `C_mem` in the µF range.
- The new device's R is ~10⁴× higher (R_off ≈ 71 MΩ). If any RC time constant survives in a
  config, the cap drops to ~pF for the same τ — but prefer designs that don't need it.
- Build a **device behavioural model from the measured curves** (LTP 15-level, window,
  retention, T-dependence) as the synapse, not a hand-set sigmoid.
- Evaluation harness must emit macro-F1 / per-class Se,+P / κ / confusion every run, and
  support an inter-patient split + a hardware-aware (noisy/quantized) eval pass.

> Sections that depend on the live literature — the **benchmark target** (`R1`), the
> **circuit config menu** (`R2`), and the **training recipe that breaks the 76% ceiling**
> (`R3`) — are completed in `01_CONFIG_MENU.md` and `02_PLAN.md` once the three research
> agents return.
