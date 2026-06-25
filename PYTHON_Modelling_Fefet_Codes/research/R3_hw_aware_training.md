# R3 — Hardware-Aware / Noise-Aware Training for a Multi-Level HZO FeFET SNN (ECG)

Scope: how to train a BPTT + surrogate-gradient SNN (SpikingJelly) whose synapse/neuron is a
15-level, ~4-decade, cumulative-kinetic (Preisach-saturating) HZO FeFET with D2D + C2C
variation, retention drift and 250–325 K temperature dependence — while (a) escaping the
~76% saturating-physics ceiling and (b) keeping the device physics in the loop instead of
abstracting it to a resistor. Target venues: IEEE TED / Nature Electronics.

Search date: June 2026. Priority on 2024–2026 top-venue work.

---

## 0. TL;DR diagnosis of the two prior failures

**Failure 1 — physics-faithful neuron stuck at ~76%.** The state is the bounded saturating
polarization P ∈ [0,1] (sigmoid/Preisach). The surrogate gradient and the device's own
dP/dV both go to ~0 near P→0 and P→1. Stacking a bounded surrogate on top of a bounded
device-physics map multiplies two near-zero derivatives → gradient vanishing that is *worse*
than ordinary SNN gradient death, and it pins weights at the boundaries (where Preisach
saturation lives). This is exactly the bounded-surrogate gradient-vanishing mechanism
formalized in Guo & Chen, "Take A Shortcut Back" (arXiv:2401.04486): *"since the firing
function is a bounded function, all these surrogate functions are bounded too, whose gradient
would be 0 or close to 0 in most intervals, thus the gradient of the SNN would be reduced
quickly as it passes from output to input."*

**Failure 2 — abstracted device away (plain resistor).** Lost the realism that a device paper
must claim. The fix is *not* to drop physics; it is to keep physics in the **forward** pass
while giving the **backward** pass a healthy, unbounded latent to flow through (latent
reparameterization + STE). This is the standard analog-IMC pattern and the explicit recipe in
the most on-point 2026 reference below.

---

## 1. Surrogate-gradient / training fixes for SATURATING, BOUNDED device dynamics

The core problem is gradient vanishing at the saturation boundaries. Five fixes, in priority
order, with the first three being the actual cure for the 76% ceiling.

### 1.1 Unbounded latent reparameterization of conductance (THE primary fix)
Do **not** make the trainable parameter the bounded polarization P ∈ [0,1] or the bounded
conductance G ∈ [G_min, G_max]. Train an **unbounded latent** `w ∈ ℝ` and map it to the device:

- Forward: `G = G_min · (G_max/G_min)^σ(w)` — a **log-domain** (4-decade) map through the
  Preisach saturating curve. The ~4 decades of your device make log-domain mandatory: a
  linear G-latent spends almost all its dynamic range in one decade and saturates the rest.
- Backward: use a **straight-through / rescaled** gradient so the latent `w` keeps a healthy
  derivative even when `G` is pinned at a rail. The quantization-to-15-levels step is also
  passed with a straight-through estimator (STE): quantize in the forward pass, identity (or
  clipped-identity) in the backward pass.

This is the mechanism behind every working analog-IMC trainer: QS4D (Siegel et al.,
*Advanced Intelligent Systems* 2026 / arXiv:2507.06079) trains TaOx analog-IMC SSMs by
applying quantization in the forward pass only ("straight-through estimator") and shows it is
what makes very-low-bit and noisy analog deployment recover accuracy. The IBM AIHWKit
hardware-aware-training docs (aihwkit.readthedocs.io) use exactly this: a digital
floating-point "latent" weight that is mapped/noised to analog conductance in the forward
pass, gradients flow through the latent.

> Concrete: parameterize each synapse as a latent real weight; map to one of 15 conductance
> levels via log-domain quantizer in forward, STE in backward. The device saturation now lives
> only in the forward map; the optimizer never sees a dead gradient.

### 1.2 Surrogate-width / scale scheduling (anneal the boundary, don't sit on it)
A *fixed* narrow surrogate guarantees most neurons have zero gradient. Recent direct-training
SNN work makes the surrogate width adaptive to the membrane-potential distribution so that a
useful fraction of neurons always carry gradient:
- **LSG — Learnable Surrogate Gradient** (Lian et al., IJCAI 2023): width learned per layer to
  keep enough neurons in the gradient-available interval; directly targets gradient vanishing
  in deep SNNs.
- **MPD-SGR — Membrane-Potential-Distribution-driven Surrogate Gradient Regularization**
  (arXiv:2511.12199, 2025) and **Adaptive Gradient Learning** (arXiv:2505.11863, 2025): add a
  regularizer that pushes the membrane-potential distribution to overlap the surrogate's
  high-gradient region, and/or threshold-robust surrogates (arXiv:2511.08708, 2025).

Practical schedule: start with a **wide** surrogate (e.g. sigmoid-derivative / atan with small
β or large temperature) so gradient flows through the saturating region, then **anneal width
down** over epochs so the final model matches the hard spike. Mirror the same temperature
anneal on the Preisach/P-sigmoid map.

### 1.3 Shortcut / auxiliary backprop paths (cure for deep gradient death)
Guo & Chen, "Take A Shortcut Back" (arXiv:2401.04486): add auxiliary shortcut branches from
intermediate layers straight to the loss so shallow layers receive gradient directly,
bypassing the chain of bounded derivatives. Branches are removed at inference (zero hardware
cost). For a shallow ECG SNN (typically 2–4 layers) this is cheap insurance; pair it with a
per-layer balance coefficient annealed over epochs (their "evolutionary" schedule).

### 1.4 Gradient rescaling / normalization through the device map
Because dG/dw collapses at the rails, normalize the per-layer gradient (or clip latent
updates) so updates don't stall. In practice: gradient-norm clipping + per-parameter
**gradient rescaling by 1/σ'(w)** (undo the saturating Jacobian, i.e. natural-gradient-lite),
or simply rely on Adam's per-parameter second-moment normalization which already partially
compensates a vanishing Jacobian. Adam + latent reparameterization is the pragmatic combo.

### 1.5 BPTT-through-device-model best practices
- Keep the device model **differentiable and in the forward graph** (don't `detach()` it) but
  route the non-differentiable bits (15-level quantization, abrupt erase) through STE.
- Use **surrogate gradient only for the spike**, STE for the device quantizer — keep them
  separate so you can tune each.
- Detach the *noise* sample (treat injected device noise as a constant per forward pass, like
  dropout) — you want robustness, not gradient through the noise.
- Truncated BPTT if sequences are long; ECG beats are short so full BPTT over the window is fine.

---

## 2. Hardware-aware / noise-aware training for multi-level + variable FeFET synapses

How top 2024–26 work injects device non-idealities **during training** and how much accuracy
survives.

### What to inject in the forward pass (every step):
1. **Quantization to 15 levels** — log-spaced over the 4 decades, STE backward (§1.1).
2. **C2C (cycle-to-cycle) variation** — additive/multiplicative Gaussian on G *resampled each
   forward pass* (write noise). Modeled in 28 nm HKMG FeFET work as a C2C conductance std
   extracted from measurement (Soliman/probabilistic-FeFET, arXiv:2312.15444 / OSTI 2341283).
3. **D2D (device-to-device) variation** — a *fixed-per-device* offset/gain sampled once per
   device and held across the epoch (spatially random, temporally fixed). This distinction
   matters: D2D is frozen (it's a fab offset), C2C is resampled (it's write noise). The MTJ
   on-chip-training-free paper (Science Advances 2024, sciadv.adp3710) exploits exactly this
   "spatially random yet temporally fixed" structure with off-chip adaptive quantization.
4. **Read noise** — small Gaussian on the readout current (PhuMob-level thermal/shot noise).
5. **Retention drift** — apply a conductance-decay model `G(t) = G0·(t/t0)^(-ν)` (or your
   measured Preisach relaxation) as a forward perturbation at a sampled elapsed time; train
   across a distribution of drift times so inference is drift-robust.
6. **Temperature (250–325 K)** — sample T per batch and apply your measured G(T) shift; this
   trains a single model robust across the spec'd window rather than one model per T.

### Mechanism & tooling:
- **IBM AIHWKit** (github.com/IBM/aihwkit; Rasch et al., *APL Machine Learning* 2023) is the
  reference implementation: floating-point latent weights, forward pass injects programming
  error + read noise (ξ Gaussian) + drift; backward through latent. Their large-scale study
  (Nature Communications, Rasch et al.) shows convnets/RNNs/transformers retrained this way
  reach **iso-accuracy with FP32** under analog noise. SpikingJelly + a custom AIHWKit-style
  forward hook is the cleanest path for your SNN.
- **QS4D** (arXiv:2507.06079, 2026): QAT + noise injection on real TaOx/180 nm CMOS analog-IMC;
  demonstrates QAT *increases noise resilience* vs post-training quantization, especially at
  low bit-width — directly supports your 15-level (≈4-bit) case.
- **Variation-aware / probabilistic FeFET** (arXiv:2312.15444): Bayesian-NN treatment of C2C+D2D
  from measured 28 nm HKMG FeFET; variation-resilient IMC.
- **Nonideality-aware training** (Joksas et al., arXiv:2112.06887) and the
  **regularization-based quant/fault/variability-aware framework** (arXiv:2503.01297, 2025):
  add the non-idealities as training-time regularizers.

### Quantified accuracy retained (cite these numbers):
- 28 nm FeFET MLP, hybrid-precision training **with C2C+D2D present → up to 95% inference
  accuracy** (arXiv:2202.10912, variation-aware hybrid-precision FeFET).
- AIHWKit / IBM hardware-aware training: **iso-accuracy with FP32** across diverse DNNs under
  injected analog noise (Nature Communications, IBM Research).
- General rule from the literature: *without* noise-aware training, multi-level analog
  inference loses tens of % (often collapses below random for >4-bit-equivalent tasks);
  *with* it, the gap to FP closes to ~1–3 pts. Report your own ideal-vs-injected delta as the
  headline robustness figure — reviewers expect "X% ideal → Y% under full device model".

> Recommended claim structure for the paper: train with full device model in-loop, then report
> (i) ideal/FP SNN accuracy, (ii) accuracy with 15-level quant only, (iii) + C2C+D2D, (iv) +
> drift+T sweep. The monotone-small degradation from (i)→(iv) IS the device-faithfulness result.

---

## 3. Asymmetric/nonlinear LTP + abrupt erase: weight-update mapping (in-situ vs ex-situ)

Your device is non-volatile with cumulative-kinetic (saturating) LTP and an **abrupt erase**
(no graded LTD). This is the classic "good LTP, awful LTD" asymmetry. Two regimes:

### Ex-situ (off-chip) training + program-verify — the credible path for a DEVICE paper.
The asymmetry/nonlinearity only matters for *online/in-situ* gradient updates; for ex-situ you
train in software (full precision / latent) and then **write** the final weights with
**program-and-verify (P&V)**: pulse → read → compare to target → repeat until within tolerance.
P&V *masks* nonlinearity and asymmetry entirely because you close the loop on the measured
conductance, not on an assumed update rule. Literature support:
- *"for offline training the nonlinearity could be masked by iterative processes"* and
  *"when multi-week retention is reported, it pertains to off-chip-trained weights written via
  program-and-verify"* (memristor in-situ training review, ScienceDirect S0957417424030720;
  MTJ Science Advances 2024).
- MTJ on-chip-training-free IMC (Science Advances 2024, sciadv.adp3710): off-chip training +
  off-chip adaptive quantization → software accuracy with **no on-chip training**.

**Recommendation:** make ex-situ + P&V your primary claim. It is the standard, reviewable
story for an emerging-device paper and it sidesteps your abrupt-erase problem entirely (you
never do graded LTD — you erase-to-min then P&V up to target with LTP pulses only).

### In-situ (on-chip) training — only if you want an adaptation claim.
If you must show on-chip learning (e.g. personalization), use the **mixed-precision /
thresholded-update** scheme — the single most on-point recipe for your exact device:
- **Garg, Song, Plessnig, Savoia, Bégon-Lours, "Personalized SNNs with Ferroelectric Synapses
  for EEG"** (*APL Machine Learning* 2026, arXiv:2601.00020). They deploy a conv-recurrent SNN
  on fabricated HZO ferroelectric synapses and:
  1. **Accumulate gradient updates digitally** and convert to a **discrete programming event
     only when a threshold is exceeded** (Tile/mixed-precision rule) → handles finite levels,
     endurance and energy.
  2. Make the write **device-aware**: account for the **nonlinear, state-dependent programming
     dynamics** (i.e. don't assume linear ΔG per pulse).
  3. Alternatively, **transfer software-trained weights + low-overhead on-device re-tuning**
     (retrain only final layers) → improves subject-specific accuracy. This is the ex-situ +
     partial-in-situ hybrid and is the most defensible "adaptation" claim.
- The accompanying device paper, **Baigol … Bégon-Lours, "Analog Weight Update Rule in
  Ferroelectric Hafnia using picoJoule Pulses"** (arXiv:2601.01186, 2026), gives a critical
  device fact for your update model: with short (20 ns, ≤3 pJ) pulses the **final conductance
  is set by pulse amplitude, independent of the initial state**. That means an
  **amplitude-coded, absolute-set write** (not incremental ΔG accumulation) is the physically
  honest mapping for fast HZO — which is essentially a one-shot P&V-friendly write and dovetails
  with ex-situ programming.

> Bottom line: ex-situ + program-verify is the credible path; cite Garg 2026 for the
> mixed-precision in-situ option and Baigol 2026 for the amplitude-set write rule that makes
> your abrupt/non-volatile device behave well under P&V.

---

## 4. Knowledge distillation done RIGHT for a device-constrained SNN student

Why naive KD collapsed you to majority-class (50%): an RC teacher's **continuous** outputs were
element-wise matched onto a **sparse, discrete** SNN student under a quantized/saturating
weight space. The distribution mismatch + a too-strong KD term let the student minimize KD loss
by predicting the majority class (the lowest-energy degenerate solution), especially with your
imbalanced AAMI classes. This exact "ANN-continuous vs SNN-sparse/discrete mismatch" is the
named failure mode in **Liu et al., "A Closer Look at KD in SNN Training"**
(arXiv:2511.06902, 2025). Fixes (use all four):

1. **Don't distill raw features element-wise.** Use **saliency/attention-map matching** (their
   SAMD): align the student's spike-activation *saliency map* with the teacher's class-activation
   map — semantically consistent, distribution-robust. Generic equivalent: attention-transfer KD.
2. **Smooth the student logits before matching** (their NLD = Noise-smoothed Logit
   Distillation): add Gaussian noise to the sparse SNN logits so they align with the teacher's
   continuous logits. Cheap and directly fixes the discreteness mismatch.
3. **Temperature + balanced KD.** Use a moderate softmax temperature (T≈2–4) and **down-weight
   KD relative to a class-balanced hard-label CE/focal loss** (KD weight α≈0.3–0.5, not ≥0.9).
   The hard-label term anchored to class weights is what prevents majority-class collapse.
   Head-Tail-Aware KL (arXiv:2504.20445, 2025) specifically reweights KL on tail classes — use
   it given your S/F minority classes.
4. **Staged / feature-then-logit, and pick a SAME-modality teacher.** Distill features first,
   logits later (staged). Critically, **don't use an RC-resistor teacher that abstracts the
   device** — use a *full-precision SNN* (same spiking modality, no device constraints) as the
   teacher, then distill to the quantized device-constrained SNN student. Same-modality KD
   avoids the continuous→sparse gap that broke you. (ANN-guided rate-feature alignment:
   arXiv:2503.16572, 2025; self-distillation for SNNs: arXiv:2510.06254 / 2406 Neural Networks.)

> The single highest-leverage KD change: **teacher = unconstrained FP-SNN (not RC), student =
> device-constrained SNN, KD weight ≤0.5 under class-balanced focal CE, logits noise-smoothed.**

---

## 5. Concrete, citable training recipe (claim BOTH accuracy AND device-faithfulness)

Designed to survive IEEE TED / Nature Electronics review.

**Data / task (AAMI N, S, V, F):**
- MIT-BIH, **inter-patient (AAMI) split** — DS1 train / DS2 test. Reviewers reject intra-patient
  splits; the systematic review (arXiv:2503.07276, 2025) flags this as the #1 fairness failure.
- Spike encoding: delta/threshold or Gaussian-receptive-field over the beat window.

**Architecture:**
- Small LIF SNN (2–4 layers), SpikingJelly, **BPTT + surrogate gradient**. Optional **axonal
  delays** (Robust ECG SNN with axonal delays, Neurocomputing 2025, S0925231225029315) for
  temporal features.

**Forward device model in-loop (the faithfulness engine):**
- Latent real weights → **log-domain map to 15 levels** (STE backward) → inject **C2C** (resample)
  + **D2D** (frozen) + read noise + sampled **retention drift** + sampled **T∈[250,325]K**.

**Surrogate / gradient (the 76% fix):**
- **Wide→narrow surrogate width anneal**; **shortcut-back** auxiliary branches (removed at
  inference); **gradient-norm clip**; **Adam**. Train the unbounded latent, never the bounded P.

**Loss / regularizers:**
- **Class-balanced focal loss** (γ≈2) over N/S/V/F (focal loss is the established AAMI-imbalance
  fix — CAM-SNN ECG, MDPI Electronics 2022; review arXiv:2503.07276).
- **Spike-rate regularizer** (L2 on firing rate) for energy/sparsity claim.
- **Variability regularizer** (penalize accuracy variance across sampled D2D/drift draws) —
  nonideality-aware regularization (arXiv:2503.01297, 2025).
- Optional **KD** from FP-SNN teacher with SAMD + noise-smoothed logits, α≤0.5 (§4).

**Calibration (required for a medical-leaning claim):**
- Report **temperature scaling / ECE** on the held-out patients; reviewers increasingly expect
  calibrated probabilities for arrhythmia, not just accuracy/F1.

**Deployment / weights-to-device:**
- **Ex-situ train → program-and-verify write** (primary). Cite amplitude-set write rule
  (Baigol 2026, arXiv:2601.01186) for the physical write model.
- Optional **on-device re-tune of final layer only** via mixed-precision thresholded updates
  (Garg 2026, arXiv:2601.00020) for the adaptation/personalization claim.

**Evaluation table to report (this is the device-faithfulness proof):**
| Config | Acc / macro-F1 |
|---|---|
| FP32 SNN (ideal) | baseline |
| + 15-level quant (STE) | ~baseline |
| + C2C + D2D | small drop |
| + retention drift + T sweep | small drop |
| Ex-situ + program-verify (measured) | matches "+drift+T" |
Plus per-class (N/S/V/F) F1, confusion matrix, ECE, energy/inference (fJ/spike × spikes), and a
robustness curve (accuracy vs injected-noise σ).

---

## Key citations (most load-bearing first)

1. **Garg, Song, Plessnig, Savoia, Bégon-Lours**, "Personalized SNNs with Ferroelectric
   Synapses for EEG Signal Processing," *APL Machine Learning* 2026, arXiv:2601.00020 —
   **closest analog**: SNN on real HZO ferroelectric synapses, mixed-precision thresholded
   in-situ updates, device-aware nonlinear write, ex-situ transfer + final-layer re-tune.
2. **Baigol, Garg, …, Bégon-Lours**, "Analog Weight Update Rule in Ferroelectric Hafnia using
   picoJoule Pulses," arXiv:2601.01186 (2026) — 20 ns / 3 pJ HZO write; **final G set by pulse
   amplitude, independent of initial state** → amplitude-set / P&V write model.
3. **Guo & Chen**, "Take A Shortcut Back: Mitigating the Gradient Vanishing for Training SNNs,"
   arXiv:2401.04486 — formalizes bounded-surrogate gradient vanishing (the 76% mechanism) +
   shortcut-back fix.
4. **Siegel et al. (QS4D)**, "Quantization-Aware Training for Efficient Hardware Deployment of
   Structured State-Space Models," *Advanced Intelligent Systems* 2026 / arXiv:2507.06079 —
   STE + QAT on real analog-IMC; QAT raises noise resilience at low bit-width.
5. **Liu, Xia, Zhou, Xu, Guo**, "A Closer Look at KD in SNN Training," arXiv:2511.06902 (2025) —
   SAMD (saliency-map distill) + NLD (noise-smoothed logits); names the continuous-vs-sparse
   mismatch that collapses naive KD. Code: github.com/SinoLeu/CKDSNN.
6. **Lian et al.**, "Learnable Surrogate Gradient (LSG)," IJCAI 2023 — adaptive surrogate width
   vs membrane-potential dynamics; anti-gradient-vanishing.
7. **MPD-SGR** (arXiv:2511.12199, 2025); **Adaptive Gradient Learning** (arXiv:2505.11863, 2025);
   **threshold-robust surrogate** (arXiv:2511.08708, 2025) — membrane-distribution-aware
   surrogate scheduling/regularization.
8. **Soliman et al.**, "Variation-Resilient FeFET-Based IMC via Probabilistic Deep Learning,"
   arXiv:2312.15444 / OSTI 2341283 — measured 28 nm HKMG C2C+D2D, Bayesian/variation-aware.
9. **Variation-aware hybrid-precision FeFET MLP**, arXiv:2202.10912 — **up to 95% with C2C+D2D**.
10. **Rasch et al. (IBM AIHWKit)**, *APL Machine Learning* 1(4):041102 (2023) +
    aihwkit.readthedocs.io HWA-training docs + IBM Nature Communications large-scale HWA study —
    latent-weight + forward-noise injection; iso-accuracy with FP32. github.com/IBM/aihwkit.
11. **MTJ on-chip-training-free IMC**, *Science Advances* 2024, sciadv.adp3710 — ex-situ +
    off-chip adaptive quantization (spatially-random/temporally-fixed); software accuracy, no
    on-chip training.
12. **Nonideality-aware training** (Joksas, arXiv:2112.06887); **regularization-based
    quant/fault/variability-aware** (arXiv:2503.01297, 2025).
13. **Head-Tail-Aware KL for SNN KD**, arXiv:2504.20445 (2025) — tail-class reweighting (S/F).
14. ECG-SNN task refs: **CAM-SNN ECG** (MDPI Electronics 11(12):1889, 2022, focal loss for
    AAMI imbalance); **Robust ECG SNN with axonal delays** (Neurocomputing 2025,
    S0925231225029315); **AAMI fairness systematic review** (arXiv:2503.07276, 2025).
15. **In-situ memristor training review** (ScienceDirect S0957417424030720, 2024) —
    nonlinearity/asymmetry masked by offline iterative (P&V) processes.
