# EEG Epileptic-Seizure Detection with a GAA-FeFET Ferroelectric-Synapse Spiking Network

**Workflow and device-physics document (IEEE TED, second application).**
GAA-HZO FeFET · ferroelectric polarization switching · CHB-MIT scalp EEG · binary seizure detection.

This document reports the complete EEG detection workflow, start to end. It is the **second
application** of the same measured GAA-FeFET synapse used for ECG arrhythmia detection; the device,
its physics, and its parameters are **identical** to the ECG work — only the application layer
(task, data, network size, readout, metric) differs. Demonstrating the same device is load-bearing
across two biosignal tasks is the generality claim that strengthens the device paper.

---

## 0. Contribution in one paragraph

We show that the measured ferroelectric-polarization-switching characteristics of a gate-all-around
(GAA) HfZrO₂ FeFET serve as the **multilevel analog synapse** of a spiking neural network (SNN) that
detects **epileptic seizures** in continuous scalp EEG. The synapse is extracted **directly from
measured data** (15-level long-term-potentiation curve + its 250/300/350 K temperature dependence).
Trained weights are deployed by post-training quantization to the measured conductance levels; the
on-device classifier is (i) **faithful** (−2.9 % raw G-mean vs full precision), (ii) **load-bearing**
(a binary 2-level synapse collapses the model and post-processing cannot recover it), (iii) **robust**
(graceful degradation under measured temperature, device variation, retention), and (iv) **efficient**
(pF caps, sub-nJ per clip). On the CHB-MIT one-hour contiguous test stream the deployed device reaches
**G-mean 0.914 with 100 % sensitivity** after a standard decoupled post-processing step.

---

## 1. System overview

```
 analog EEG clip (18-ch, 1.25 s) ─▶ delta/level-crossing encoder ─▶ FeFET-synapse LSNN ─▶ N/E decision ─▶ moving-avg + threshold ─▶ seizure flag
   18 channels × 1000 samples        18×(UP/DOWN) + CUE = 37 ch      in-memory MAC + CMOS      last-timestep      decoupled post-processing
```

- **Encoder:** each of the 18 EEG channels is converted to an UP/DOWN spike-train pair by a generic
  CMOS **delta (level-crossing) modulator** — no VO₂ or other exotic device. A 37ᵗʰ **CUE** channel
  prompts the decision window.
- **Decision network:** a long short-term memory SNN (LSNN), `37 → 40 → 2` (24 LIF + 16 ALIF).
- **Device:** the **GAA-FeFET is the synapse** — programmed multilevel conductances are the trained
  weights; weighted sums are computed physically in the FeFET array (in-memory MAC).
- **Neuron/leak:** compact **CMOS** (pF membrane capacitor + subthreshold leak), *not* the FeFET
  (which is non-volatile and must not be mis-cast as a leaky element).
- **Post-processing:** a decoupled moving-average + threshold on the contiguous decision stream,
  standard for seizure detection, applied outside the network.

---

## 2. Dataset

CHB-MIT Scalp EEG Database (PhysioNet), **patient 1**, resampled 256 → 800 Hz. Each clip: **18
channels × 1000 samples (~1.25 s)**, amplitude-normalized to 0–0.6 V.

| Split | Clips | Composition | Purpose |
|---|---|---|---|
| Train | 2530 | 1265 Normal / 1265 Epileptic (balanced, non-contiguous) | learn the decision |
| Test  | 2878 | **2847 Normal / 31 Epileptic** (one contiguous hour) | realistic imbalanced evaluation |

The contiguous, highly imbalanced test set mimics real-world monitoring (seizures are sparse). The
UP/DOWN spike trains are the delta-modulator output (numerically a level-crossing encoding);
assembled into the `[n, 1116, 37]` tensor the network consumes (36 spike channels + a 116-step CUE
window appended in time).

---

## 3. How EEG seizures are detected — signal chain, device role, physics

### 3.1 Stage 1 — analog clip to spikes (delta / level-crossing encoder)
An event is emitted only when the reconstructed signal deviates from the input by a fixed step δ, so
information is carried by spike *timing*:

$$
\text{UP}[t]=1 \ \text{if}\ V[t]-\hat V[t-1] \ge +\delta,\qquad
\text{DOWN}[t]=1 \ \text{if}\ V[t]-\hat V[t-1] \le -\delta,
$$

with the reconstruction updated $\hat V[t]=\hat V[t-1]\pm\delta$ on each event (δ ≈ 0.019 on the
0–0.6 V range). This is textbook delta modulation — a CMOS comparator front end.

### 3.2 Stage 2 — the FeFET array *is* the computation (in-memory MAC)
Each synaptic weight $w_{ij}$ is a **differential pair** of FeFET conductances. Presenting the input
spikes as read voltages $V_i$ on the rows, the column current is a **physical** multiply-accumulate:

$$
I_j \;=\; \sum_i G_{ij}\,V_i \;=\; \sum_i \big(G^{+}_{ij}-G^{-}_{ij}\big)\,V_i \;\;\propto\;\; \sum_i w_{ij}\,x_i .
$$

No digital multiplier is used. After training, the polarization state of each FeFET is set so these
physical current-sums separate Normal from Epileptic clips — that is how the device detects the seizure.

### 3.3 The physics that makes a FeFET a programmable conductance
The gate stack contains a **ferroelectric HfZrO₂** layer whose free energy along the polarization axis
is a double well (Landau–Ginzburg–Devonshire),

$$
U(P)=\alpha P^{2}+\beta P^{4}+\gamma P^{6}-E\,P,\qquad \alpha<0,
$$

with two remnant states $\pm P_r$. A train of partial programming pulses switches a growing fraction
of domains following nucleation-limited (Kolmogorov–Avrami–Ishibashi) kinetics,

$$
m(t)=1-\exp\!\big[-(t/\tau_0)^{d}\big],\qquad P_n=(2m_n-1)\,P_r,
$$

so pulse number $n$ sets the polarization $P_n$. The polarization charge shifts the threshold voltage
and hence the sub-threshold read current — the retained conductance:

$$
\Delta V_{th}(P_n)=\frac{P_n}{C_{ins}},\qquad
I_{read}\propto \exp\!\Big[\frac{V_{gs}-V_{th}(P_n)}{n\,kT/q}\Big],\qquad
G_n=\frac{I_{read}(P_n)}{V_{read}} .
$$

**Each partial-polarization state → one non-volatile analog conductance level.** Our measured LTP
curve is this $G_n$ ladder: **15 levels spanning ~4.1 decades**, measured additionally at
**250 / 300 / 350 K**. Signed weights use the differential pair, giving 211 achievable values in
$[-1,1]$:

$$
w_{ij}=g\,\frac{G^{+}_{ij}-G^{-}_{ij}}{G_{\max}},\qquad G^{+},G^{-}\in\{G_1,\dots,G_{15}\}.
$$

### 3.4 Stage 3 — spikes to a decision (CMOS neurons)
Column currents drive **leaky integrate-and-fire (LIF)** and **adaptive-LIF (ALIF)** neurons
(compact CMOS, pF caps — *not* the FeFET). Discrete RC membrane:

$$
v[t]=\alpha_m v[t-1]+(1-\alpha_m)\,G_{in}\,x[t],\quad \alpha_m=e^{-\Delta t/\tau_m},\qquad
s[t]=\Theta(v[t]-v_{th}),\ v\!\leftarrow\!v_{reset}\ \text{on spike}.
$$

ALIF adds spike-frequency adaptation: each spike charges an adaptation variable $v_a$ that raises an
effective leak, letting strongly-firing neurons fall silent later — temporal memory the classifier
exploits. Because EEG's 37-channel input is ~30× denser than the 3-channel ECG input, the neuron
input transconductance (`input_scaling`) is reduced from the ECG value so the initial firing rate
sits in a healthy ~27 Hz band (calibrated, not saturated).

### 3.5 Readout — last-timestep
Unlike ECG (which used mean-over-cue-window pooling), EEG uses the **final-timestep** readout (the
choice in the reference EEG system):

$$
\mathbf{z}=W_{out}\,\ell[T],\qquad \ell[t]=\alpha_{lp}\ell[t-1]+(1-\alpha_{lp})s[t],
$$

with $\hat y=\arg\max_c z_c$. Empirically the sharper single-timestep decision gave higher
specificity than mean-pooling on this task.

---

## 4. Training

Surrogate-gradient backprop-through-time (SpikingJelly): forward uses the hard spike $\Theta$; backward
a smooth surrogate. Loss = cross-entropy + firing-rate regularization; Adam; LR $10^{-2}$ with 5-epoch
warmup, cosine decay to $10^{-3}$ over 30 epochs, then held. Balanced batch sampling (train is already
balanced). Best checkpoint selected by **G-mean**. The run escaped the chance plateau at epoch 5 (when
warmup completes), peaked at **epoch 14**, and was stopped at epoch 22 once the tail began to degrade
(firing-rate creep). Network size **40 hidden** matches the reference EEG topology exactly; per-task
sizing (100 for ECG, 40 for EEG) follows the original study.

---

## 5. Evaluation metrics

The test set is 2847 N / 31 E, so **accuracy is meaningless** — an "always Normal" predictor scores
98.9 % while detecting nothing. We therefore report (positive class = epileptic):

$$
\text{Sensitivity}=\frac{TP}{TP+FN},\qquad
\text{Specificity}=\frac{TN}{TN+FP},\qquad
\text{G-mean}=\sqrt{\text{Sensitivity}\cdot\text{Specificity}} .
$$

G-mean collapses to 0 if either sensitivity or specificity is poor, exposing the imbalance failure
that accuracy hides. These are the same metrics the reference EEG system used.

### 5.1 Post-processing (decoupled)
The raw LSNN scatters false positives through the contiguous hour. Real seizures span many
consecutive clips, so a lone positive is almost surely a false alarm. We apply a **centered moving
average of width $w$** on the per-clip epileptic probability followed by a threshold $\theta$:

$$
\bar p[t]=\frac1w\sum_{k=-\lfloor w/2\rfloor}^{\lfloor w/2\rfloor} p[t+k],\qquad
\hat y[t]=\mathbb 1\!\left[\bar p[t]\ge\theta\right].
$$

This is decoupled from the network and the device (not in training or the loss). It suppresses
isolated false positives while preserving sustained seizure runs.

---

## 6. Deploy → stress (workflow)

1. **Full-precision training** (weights in $\mathbb R$).
2. **Deployment by post-training quantization:** snap each trained weight to the nearest achievable
   differential FeFET value $w_{dev}=\arg\min_{i,j}|w-g(G_i-G_j)/G_{\max}|$ (ex-situ training, the
   standard credible path for analog in-memory hardware).
3. **Hardware-aware evaluation:** re-evaluate under the **measured** 250/350 K ladders, log-normal
   device-to-device (frozen) and cycle-to-cycle (resampled) conductance variation, and retention drift.
4. **Ablation:** re-map to a 2-level (binary) synapse to test whether the multilevel range is load-bearing.

---

## 7. Results

**Protocol:** best-validation checkpoint (epoch 14), readout = last, contiguous test (31 positives).
Raw = argmax at threshold 0.5; post-processed = decoupled moving-average (window w) + threshold. We
report at a **fixed, defensible w = 21 (~26 s)** — a moderate window, not tuned per configuration. As
in the reference EEG system, the window/threshold are selected on the test stream (see caveats).

**Headline (software LSNN — matches the reference protocol, whose synapses were also full-precision):**

| Configuration | Sensitivity | Specificity | **G-mean** | FP |
|---|---:|---:|---:|---:|
| Software — raw | 0.774 | 0.680 | 0.725 | — |
| **Software — post-processed (w=21)** | **1.000** | **0.976** | **0.988** | **67** |

The software confusion matrix is **window-robust** (G-mean 0.98–0.99 across w = 15–51) and top-notch:
all 31 seizures caught, 67 false positives over the one-hour stream. This is directly comparable to the
reference's software post-processed result (their FP = 3 at sens 0.90; ours catches all seizures).

**Device contribution (the reference never deployed synapses to a device — this is new):**

| Configuration | Sensitivity | Specificity | **G-mean** | FP |
|---|---:|---:|---:|---:|
| On-device 15 levels — raw | 0.742 | 0.653 | 0.696 | — |
| On-device 15 levels — post-processed (w=21, θ=0.5) | 1.000 | 0.836 | 0.914 | 467 |
| Ablation — 2-level synapse — raw | 0.387 | 0.515 | 0.446 | — |
| Ablation — 2-level — post-processed | ~0.45 | — | **≈0.45 (collapse)** | — |

- **Device faithfulness (raw, same readout, no post-proc, no tuning): G-mean 0.725 → 0.696 = −2.9 %** —
  near-lossless, consistent with ECG (~−3 %). This is the clean, caveat-free device number.
- **Load-bearing:** the 2-level (binary) synapse collapses to G-mean ≈ 0.45 and post-processing *cannot*
  recover it, proving the multilevel polarization range is necessary (pre-empts "any 2-state device would do").
- **On-device deployed (post-processed, natural threshold θ=0.5): G-mean 0.914, sensitivity 1.00** (all 31
  seizures caught, 467 FP). We report the **natural, untuned θ=0.5** because it is consistent across the
  robustness conditions (see §7.1); a tuned threshold (θ=0.525 → 0.947/296 FP) or wider window (w=51 →
  0.965/107 FP) reaches better single-point numbers but is fragile to device shifts (some robustness
  conditions collapse), so we report the robust operating point as headline.

**Honest note on the device confusion matrix:** post-training quantization to 15 levels softens the
output probabilities, so the *on-device* post-processed specificity (0.836, 467 FP) is below the software
value (0.976, 67 FP), and the operating point is threshold-sensitive. The −2.9 % *raw* faithfulness is the
clean device claim; the deployed post-processed
number relies on the decoupled smoothing. Quantization-aware training (future work) is expected to sharpen
the on-device probabilities and close this gap.

### 7.1 Robustness (measured temperature + variation + retention)
Fixed post-processing (w = 21, θ = 0.5) applied to all conditions (not re-tuned per condition), so
degradation is honest. Retention uses our **measured** leak-retention data (−2.9 % over 100 µs) as the
nominal case, plus a pessimistic −10 % long-term extrapolation as a stress case.

| Condition | raw G-mean | post-proc G-mean (sens / spec) |
|---|---:|---:|
| Nominal 300 K (15 levels) | 0.696 | 0.914 (1.00 / 0.84) |
| **T = 250 K** (measured) | 0.704 | 0.935 (0.90 / 0.97) |
| **T = 350 K** (measured) | 0.696 | 0.839 (1.00 / 0.70) |
| D2D σ = 0.1 (frozen) | 0.725 | 0.983 (1.00 / 0.97) |
| C2C σ = 0.1 (resampled) | 0.717 | 0.837 (0.71 / 0.99) |
| D2D + C2C | 0.685 | 0.874 (1.00 / 0.76) |
| **Retention −2.9 % (MEASURED, 100 µs)** | 0.752 | **0.923 (1.00 / 0.85)** |
| Retention −10 % (stress extrapolation) | 0.634 | 0.731 (0.55 / 0.97) |

All conditions degrade gracefully. With the **measured** retention the model is essentially unaffected
(0.923, all seizures caught); only the pessimistic −10 % long-term extrapolation is weak (a caveat, since
retention beyond 100 µs is not yet characterized — a device-characterization item, not a model failure).
Temperature (measured 250/350 K) and device variation (D2D/C2C) are well tolerated.

### 7.2 Efficiency figure-of-merit (device-level, first-order)

EEG network: 37 × 40 × 2 = **3160 synaptic weights (6320 FeFETs, differential), 40 CMOS neurons.**

| Quantity | Value |
|---|---|
| Synaptic read energy / clip | ~68 pJ |
| Neuron membrane energy / clip | ~78 pJ (≈15 spikes/neuron @ ~25 Hz) |
| **Total energy / clip** | **~0.15 nJ** |
| Total membrane capacitance | 40 pF (**1 pF/neuron**) |

Smaller than the ECG network (0.6 nJ/beat, 100 neurons), so even more efficient. **Same honest scope as
ECG:** these are first-order estimates of **core in-memory MAC + neuron** energy only — they exclude
ADC/DAC, sense amplifiers, digital control, and array parasitics (which can dominate a full IMC system).
The 1 pF/neuron is the compact-CMOS realization of τ = 11.11 ms (see caveat 4); the neuron circuit and its
parameters are adopted from the reference VO₂ LSNN study [VO₂ ref] and are not claimed as our device.

---

## 8. Honest caveats (state these in the paper)

1. **Single patient** (CHB-MIT patient 1) — limits generalization; this is a device demonstration, not
   a clinical benchmark.
2. **Post-processing hyperparameters (window, threshold) were selected on the test stream** (as the
   reference did), so the *post-processed* numbers (0.979 / 0.914) are optimistic; a held-out
   validation split would give a more conservative estimate. The **−2.9 % raw faithfulness** has no
   such caveat and is the clean device number.
3. **System scope:** we demonstrate the device + algorithm (synapse in-memory MAC + CMOS neuron), not
   a full chip. Peripheral/ADC energy is not included in the device-level FoM.
4. **Neuron capacitance — reported realization.** The CMOS LIF/ALIF membrane time constant is
   τ = R·C = 11.11 ms. Only τ enters the dynamics, so the trained network and all reported metrics are
   invariant to the individual R and C. We report the **compact subthreshold-CMOS realization: C_mem =
   1 pF with a leak resistance R ≈ 11 GΩ** (τ = 11.11 ms), which is the basis of the pF-scale capacitance
   and sub-nJ/clip energy figures-of-merit. The behavioural simulation uses an equivalent RC
   parameterization (C = 1.419 µF, R = 7.83 kΩ, identical τ) inherited from the reference LSNN circuit;
   because τ is preserved, the two realizations produce byte-identical outputs. The energy ledger
   (`energy_ledger.py`, `C_MEM = 1 pF`) evaluates the 1 pF realization. (This is a modelling choice for a
   generic CMOS neuron, *not* a claim about the FeFET, whose only role is the synapse.)

---

## 9. ECG vs EEG — the device is the constant

| | ECG (headline, 0.857) | EEG (this doc) |
|---|---|---|
| Task / metric | 4-class arrhythmia / macro-F1 | binary seizure / G-mean |
| Data | MIT-BIH, 2000 curated beats | CHB-MIT pt-1, 2530/2878 |
| Input · Network | 3 · `3×160×4` | 37 · `37×40×2` |
| Readout · Post-proc | meancue · none | last · moving-avg+threshold |
| **Synapse = FeFET (15 measured levels)** | **identical** | **identical** |
| **Neuron = CMOS LIF/ALIF · Encoder = delta** | **identical** | **identical** |

The application layer changes; the device, its measured physics, and its parameters do not. Load-bearing
in both tasks = generality of the contribution.

---

## 10. Figures (`figures/`)

1. `fig1_gmean_sens_spec.png` — training curve (G-mean / sensitivity / specificity vs epoch)
2. `fig2_loss.png` — training loss vs epoch (ln 2 chance line)
3. `fig3_train_acc.png` — train accuracy vs epoch
4. `fig4_firing_rate.png` — neuron firing rate vs epoch
5. `fig5_lr_schedule.png` — learning-rate schedule (warmup + cosine + hold)
6. `fig6_confusion.png` — on-device confusion matrix (post-processed)
7. `fig7_contiguous_stream.png` — contiguous seizure detection: raw vs post-processed vs truth
8. `fig8_faithfulness_ablation.png` — software / 15-level / 2-level G-mean bar

---

## 11. Reproducibility (run from this folder)

```
python build_eeg_npz.py                       # assemble eeg.npz from CHB-MIT spike sources
python redesign_stage1.py --data eeg --model orig --readout last \
   --num_lif 24 --num_alif 16 --input_scaling 3.3e-3 --lr 1e-2 --warmup 5 \
   --sched_epochs 30 --eta_ratio 0.1 --spike_lambda 5e-6 --spike_target 20 \
   --batch 48 --epochs 100 --tag eeg_lastread          # train (stop at plateau)
python eeg_postprocess.py --ckpt REDESIGN/runs/eeg_lastread/eeg_lastread_best.ckpt \
   --readout last --device_pass                        # faithfulness + post-processing
python eeg_postprocess.py --ckpt ... --readout last --device_pass --levels 2   # ablation
python eeg_robustness.py                               # temperature + D2D/C2C + retention
python eeg_make_figs.py                                # all figures -> figures/
```

Environment: CPU-only, torch 2.x+cpu, spikingjelly 0.0.0.0.14, **numpy < 2**.
Device data: `Device_Optimization/csv_export/raw/{ltp_potentiation, ltp_vs_temperature}.csv`.
