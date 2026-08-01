# A GAA-FeFET Ferroelectric-Synapse Spiking Neural Network for ECG Arrhythmia Detection

**Methodology and device-physics document (IEEE TED draft).**
GAA-HZO FeFET · ferroelectric polarization switching · MIT-BIH 4-class arrhythmia.

---

## 0. Contribution in one paragraph

We demonstrate that the measured ferroelectric-polarization-switching characteristics of a
gate-all-around (GAA) HfZrO₂ FeFET can serve as the **multilevel analog synapse** of a spiking
neural network (SNN) that performs electrocardiogram (ECG) arrhythmia detection. The synaptic
device model is extracted **directly from measured data** (15-level long-term-potentiation curve
and its temperature dependence). Trained network weights are deployed onto the device by
post-training quantization to the measured conductance levels; the resulting on-device classifier
is shown to be (i) **faithful** — near-lossless versus full precision, (ii) **load-bearing** — the
multilevel range is necessary (a binary synapse collapses the model), (iii) **robust** — accuracy
degrades only gracefully under measured temperature, device variation and retention drift, and
(iv) **efficient** — pF-scale membrane capacitance and sub-nJ energy per beat. We **adopt the reference
VO₂-memristor LSNN pipeline** (its curated MIT-BIH dataset, level-crossing spike encoding, LSNN
architecture and LIF/ALIF neuron parameters) and replace its **software** synapses with our measured
GAA-FeFET **hardware synapse**. The goal is *not* to beat prior ECG accuracy records, but to establish
that our device physics **aligns with and enables** a neuromorphic biosignal-processing function.

---

## 1. System overview

```
 analog ECG beat  ─▶  level-crossing (delta) encoder  ─▶  FeFET-synapse LSNN  ─▶  class (N/SVEB/VEB/F)
   (556 ms)            UP / DOWN / CUE events        in-memory MAC + CMOS       arrhythmia label
                                                     LIF/ALIF neurons
```

- **Encoder:** an asynchronous level-crossing (delta) modulator — adopted from the reference [VO₂ ref],
  which realized it with a VO₂ memristor — converts each analog channel into UP/DOWN spike trains
  (event-driven, sparse). We do not fabricate this encoder; we use the reference's pre-encoded spikes.
- **Decision network:** a long short-term memory SNN (LSNN): `Input → delayed FC → recurrent
  [100 LIF + 60 ALIF] → low-pass filter → linear readout`.
- **Device:** the **GAA-FeFET is the synapse** — its programmed multilevel conductances are the
  trained weights, and the weighted sums are computed physically in the FeFET array (in-memory MAC).
- **Neuron/leak:** compact CMOS (pF membrane capacitor + subthreshold leak), *not* the FeFET, because
  the FeFET is non-volatile and must not be mis-cast as a leaky element.

---

## 2. How ECG signals are detected — the signal chain, the device's role, and the physics

*(This is the central mechanism section.)*

### 2.1 What "detection" means here
Clinical ECG screening flags abnormal heartbeats. Each beat is assigned to one of the AAMI-style
classes **N** (normal), **SVEB** (supraventricular ectopic), **VEB** (ventricular ectopic), **F**
(fusion). Detecting an arrhythmia = correctly classifying the ectopic beats. The morphological
differences that distinguish these classes (QRS width, P-wave presence, premature timing) are
encoded in the spatiotemporal spike pattern and must be *learned*.

### 2.2 Stage 1 — analog beat to spikes (level-crossing / delta encoder, adopted from the reference)
The encoder (adopted from the reference [VO₂ ref], which realized it in a VO₂ memristor) emits an event
only when the reconstructed signal deviates from the input by a fixed step δ, so information is carried
by spike *timing*, not clocked samples:

$$
\text{UP}[t]=1 \ \text{if}\ \beta\,(V[t]-V[t-1]) \ge +V_{th}^{enc},\qquad
\text{DOWN}[t]=1 \ \text{if}\ \beta\,(V[t]-V[t-1]) \le -V_{th}^{enc}
$$

with amplifier gain $\beta$ and step $\delta = V_{th}^{enc}/(\beta\,f)$. A third **CUE** channel fires
during the output window to prompt a decision. Output: a 3-channel × 1116-step spike tensor per beat
(~3.6 % activity — sparse, event-driven).

### 2.3 Stage 2 — the FeFET array *is* the computation (in-memory MAC)
This is where the device performs the detection. Each synaptic weight $w_{ij}$ is stored as a pair of
FeFET conductances (a differential cell), so the synaptic layer is a conductance matrix. Presenting
the input spikes as read voltages $V_i$ on the rows, the column current is a **physical**
multiply-accumulate by Ohm's and Kirchhoff's laws:

$$
I_j \;=\; \sum_i G_{ij}\,V_i \;=\; \sum_i \big(G^{+}_{ij}-G^{-}_{ij}\big)\,V_i \;\;\propto\;\; \sum_i w_{ij}\,x_i
$$

No digital multiplier is used — the weighted sum that drives neuron $j$ is the summed read current of
a column of FeFETs. The **discriminative power lives in the programmed conductances**: after training,
the polarization state of each FeFET is set so that these physical current-sums separate the four beat
classes. *That is how the device detects the arrhythmia.*

### 2.4 The physics that makes a FeFET a programmable conductance
The gate stack contains a **ferroelectric HfZrO₂** layer. Along the polarization axis its free energy
is a double well (Landau–Ginzburg–Devonshire),

$$
U(P)=\alpha P^{2}+\beta P^{4}+\gamma P^{6}-E\,P,\qquad \alpha<0,
$$

giving two stable remnant states $\pm P_r$ separated by the coercive field $E_c$. A **train of partial
programming pulses** switches a growing *fraction* of ferroelectric domains; the switched fraction
follows nucleation-limited (Kolmogorov–Avrami–Ishibashi) kinetics,

$$
m(t)=1-\exp\!\big[-(t/\tau_0)^{d}\big],\qquad P_n=(2m_n-1)\,P_r,
$$

so pulse number $n$ sets the polarization $P_n$. The polarization charge shifts the transistor
threshold voltage, which shifts the sub-threshold read current — i.e. the retained conductance:

$$
\Delta V_{th}(P_n)=\frac{P_n}{C_{ins}},\qquad
I_{read}\propto \exp\!\Big[\frac{V_{gs}-V_{th}(P_n)}{n\,kT/q}\Big],\qquad
G_n=\frac{I_{read}(P_n)}{V_{read}} .
$$

**Each partial-polarization state → one non-volatile analog conductance level.** Our measured
long-term-potentiation curve is exactly this $G_n$ ladder: **15 levels spanning 4.11 decades**
(13,027×; $R_{15}=66.8\ \mathrm{k\Omega}\to R_{1}=870\ \mathrm{M\Omega}$ for one nanosheet at
$W_{\text{eff}}=90$ nm), with non-uniform log spacing (0.04–0.41 per level). We additionally
measured the ladder at **250 K / 300 K / 350 K**.

Two resistance pairs appear in this work and they are **not** interchangeable. The ladder span
above is level 1 → level 15 of the potentiation train. The *LIF read window* is a different
measurement — the erased baseline against the read after 9 pulses, both from node `t8_ltp`:
$R_{off}=67.7\ \mathrm{M\Omega}\to R_{on}=3.68\ \mathrm{M\Omega}$, i.e. **18.4×**. The 30.6×
quoted previously divided `t8_ltp`'s pulse-9 read by a baseline taken from a different node
(`mwfine`) at a different post-write settling time; a ratio is only formed from two
measurements taken in the same run.

### 2.5 Stage 3 — spikes to a decision (the neurons)
The column currents (§2.3) drive leaky integrate-and-fire (LIF) and adaptive-LIF (ALIF) neurons whose
recurrent, delayed connectivity gives the network temporal memory over the beat. A low-pass filter and
a linear readout convert the late-window spiking into class scores (§4). The **arrhythmia label is the
arg-max** of those scores.

### 2.6 Why the division of labor is physically honest
- The FeFET is **non-volatile** → it stores *weights* (zero standby power), and its multilevel
  polarization range gives *weight resolution*. It does **not** provide the membrane leak.
- The **temporal dynamics** (integration, leak, adaptation) are done by compact CMOS (pF caps,
  subthreshold leak). This avoids the physically impossible µF-per-neuron capacitor of prior RC designs
  and keeps every claimed function attributable to a real physical element.

---

## 3. Device → synapse model

Signed weights use a **differential pair** (2 FeFETs/weight), normalized by the top level:

$$
w_{ij}\;=\;g\,\frac{G^{+}_{ij}-G^{-}_{ij}}{G_{\max}},\qquad G^{+},G^{-}\in\{G_1,\dots,G_{15}\}.
$$

The achievable weight set is $\{(G_i-G_j)/G_{\max}\}$ → **211 distinct signed values in $[-1,1]$**,
including ≈0 (when $G^{+}\!\approx\!G^{-}$). $g$ is a per-layer transimpedance/readout gain (a CMOS
constant). Synaptic read energy is sub-fJ: $E_{read}=V_{read}^2\,G\,t_{read}$.

---

## 4. Neuron and network model

Topology: `Input(3) → DelayedLinear → recurrent[100 LIF + 60 ALIF] → LP filter → Linear(4)`;
timestep $dt=0.556$ ms, 1116 steps/beat. The LSNN architecture follows Bellec et al. 2018 and the
reference [VO₂ ref] (same LSNN family); the compact **CMOS LIF/ALIF neuron circuit and its parameters**
($v_{th}$, $v_{reset}$, MOSFET $\kappa_{n,p}$, $V_{tn}$, $V_{tp}$, $V_{dd}$) are **adopted from the reference
VO₂-memristor LSNN study** [VO₂ ref] — modelled as a generic CMOS neuron here (the reference realized these
neurons as VO₂-memristor RC circuits), distinct from and independent of our FeFET synapse (our only
characterized device). We do not claim these neuron parameters as measured from our device.

**LIF membrane (discrete RC):**
$$
v[t]=\alpha_m v[t-1]+(1-\alpha_m)\,G_{in}\,x[t],\quad \alpha_m=e^{-dt/\tau_m},\ \tau_m=C_{mem}R_{leak}
$$
$$
s[t]=\Theta(v[t]-v_{th}),\qquad v\leftarrow v_{reset}\ \text{on spike}.
$$
With $C_{mem}=1$ pF and $\tau_m\approx11$ ms, $R_{leak}\approx5$–$11\ \mathrm{G\Omega}$ (a subthreshold
CMOS device — not the FeFET).

**ALIF (spike-frequency adaptation):**
$$
v[t]=\alpha_m v[t-1]+(1-\alpha_m)\big(G_{in}x[t]-G_a I_l(v_a)\big),\qquad
v_a[t]=\alpha_a v_a[t-1]+(1-\alpha_a)R_a I_a(s[t]),
$$
with MOSFET currents $I=\tfrac12\kappa\frac{W}{L}(V_{gs}-V_{th})^2$ (saturation). Adaptation lets
neurons that fire strongly during the QRS complex fall silent during the decision window — a temporal
feature the classifier exploits.

**Readout (mean-cue pooling):**
$$
\ell[t]=\alpha_{lp}\ell[t-1]+(1-\alpha_{lp})s[t],\qquad
\mathbf{z}=W_{out}\,\operatorname*{mean}_{t\in\text{cue}}\ell[t].
$$
Pooling over the decision window (rather than a single decayed timestep) is essential for a usable
training gradient.

**Training — surrogate-gradient BPTT.** Forward uses the hard spike $\Theta$; backward uses a smooth
surrogate so gradients flow through spikes:
$$
\frac{\partial s}{\partial u}\approx \gamma\max\!\big(0,\ \alpha-\alpha^2|u|\big),\quad u=\tfrac{v-v_{th}}{v_{th}}.
$$
Loss = cross-entropy with **balanced batch sampling** for class imbalance; Adam, LR $10^{-2}$
cosine-decayed then held, gradient-norm clip 1.0.

---

## 5. Train → deploy → stress (the workflow)

1. **Full-precision training** (weights in $\mathbb{R}$) with the recipe above.
2. **Deployment by post-training quantization:** each trained weight is snapped to the nearest
   achievable differential FeFET value,
   $w_{dev}=\arg\min_{i,j}\big|\,w-g\,(G_i-G_j)/G_{\max}\big|$ (straight-through for any fine-tuning).
   This is *ex-situ* training, the standard credible path for analog in-memory hardware.
3. **Hardware-aware evaluation:** re-evaluate the deployed weights under (i) the **measured** 250 K /
   350 K conductance ladders, (ii) log-normal device-to-device (D2D, frozen) and cycle-to-cycle (C2C,
   resampled) conductance variation, (iii) retention drift.
4. **Energy/area ledger:** $E_{beat}=\sum V_{read}^2 G\,t_{read}\ (\text{reads})+\sum \tfrac12 C_{mem}\Delta V^2\ (\text{neuron events})+\text{readout}$.

---

## 6. Physics–architecture alignment (why this device fits this network)

| Measured device property | Architectural role it enables |
|---|---|
| Non-volatile retention (>100 µs @ 0 V) | Fixed synaptic weight; **zero standby power** |
| 15-level, 4-decade analog conductance (partial polarization) | High-resolution **analog synaptic weight** |
| Steep switching, sub-fJ program | Efficient weight write; sharp transfer |
| Characterized 18.4× read window, 250–350 K ladders | Robust, quantifiable in-memory MAC |
| *(cannot self-leak)* | Leak delegated to CMOS → honest LIF, no µF cap |

The **ablation** (§7) turns this qualitative alignment into a quantitative claim: remove the multilevel
range and the classifier collapses, so the polarization physics is load-bearing.

---

## 7. Evaluation methodology and results

**Protocol.** MIT-BIH, 2000 beats (N/VEB/SVEB/F = 1000/500/250/250), random 1664/336 split (matching
the reference preprocessing — *intra-patient*; an inter-patient AAMI DS1/DS2 split is scaffolded for
when record-tagged data is available). **Metrics:** accuracy, **macro-F1** (primary, for imbalance),
Cohen's κ, per-class sensitivity/positive-predictivity, confusion.

| Configuration | Accuracy | macro-F1 | κ |
|---|---:|---:|---:|
| **Software (full precision)** | **0.857** | **0.793** | **0.782** |
| **On-device — 15 measured levels (300 K)** | **0.830** | **0.754** | 0.742 |
| Ablation — 2 levels (binary synapse) | 0.563 | 0.286 | 0.290 |
| Temperature 250 K (measured) | 0.821 | 0.739 | 0.729 |
| Temperature 350 K (measured) | 0.839 | 0.766 | 0.753 |
| D2D σ=0.1 (generic log-normal) | 0.813 | 0.724 | 0.715 |
| C2C σ=0.1 (generic log-normal) | 0.807 | 0.729 | 0.708 |
| D2D + C2C | 0.798 | 0.724 | 0.696 |
| **Retention −0.96 % (MEASURED, RR-4 plateau)** | **0.821** | **0.721** | 0.728 |
| Retention −10 % (stress extrapolation) | 0.819 | 0.740 | 0.725 |

*(Re-verified 2026-08-01 on the paper150b checkpoint against the corrected device export. Retention is the
**measured** RR-4 plateau, −0.96 % — not the −2.9 % reported previously, which was read from
`leak_retention.csv` between 17.5 µs and 100 µs, a window sitting **inside** the post-write settling
transient that relaxes with τ_P = 10 µs and is not retention loss at all. Measured out to 10 ms the state
settles by ≈5 τ_P and is then flat to 0.62–0.96 % over the remaining 2.3 decades.*

*Two honest notes on this table. First, −0.96 % scores marginally **below** −10 %; both sit ≈0.03 macro-F1
under nominal and the ordering is not meaningful. A retention factor is a uniform multiplicative gain
applied after quantization, and a spiking classifier with fixed thresholds responds to a small uniform gain
piecewise, through discrete spike-count changes, not smoothly. Second, the D2D/C2C rows here are **generic**
σ = 0.1 log-normal stand-ins, retained for continuity with the earlier table. The measured variability —
which is not a single σ, and for which the device-to-device and cycle-to-cycle halves must be handled
differently — is figure K3.)*

**How many levels, and where — figure K2.** Sweeping the deployment grid from 2 to 15
levels in two constructions (a subset of the measured ladder, and a log-spaced grid over
the same span) gives an accuracy that is **not monotonic in the level count** below 8
levels, identically in both constructions. Re-drawing the interior levels at fixed n
explains it: at n = 8 four random placements score 0.336–0.491 while the evenly-spaced
placement scores 0.804. The cause is the differential encoding on a 4.11-decade ladder —
$|G_i-G_j|$ is dominated by $\max(i,j)$, so the achievable weight set is roughly
$\{0,\pm G_k/G_{\max}\}$, dense near zero and sparse near $\pm1$, and a grid that spends
its levels low on the ladder buys almost no weight resolution. **Level count alone is
therefore not the figure of merit**: with arbitrary placement the classifier needs ~10–12
levels to reach the software neighbourhood reliably. This is the same conclusion the
variability analysis reaches independently (K3c), where accuracy tracks per-device level
*misplacement* rather than the ensemble level-overlap statistic.

**Variability — figures K3a/K3c.** RR-8's 20 runs are box **corners**, a worst-case
envelope rather than a σ, so they are never injected as a Gaussian. Deployed onto each
corner, the locked network scores a median 0.243 with no per-device calibration, 0.777
with a single readout-gain trim, and **0.830 — nominal to four decimals — with per-level
write-verify**. Each corner ladder is a near-rigid log-shift of nominal (median |shift|
0.51 decades) plus a residual; gain-trim accuracy tracks the worst residual level
misplacement at Spearman −0.85, holding 0.78–0.83 out to ≈0.6 decades and collapsing at
≈0.9. Note that after a gain trim 13 of 14 adjacent level pairs still overlap *across the
ensemble* while several of those corners deliver nominal accuracy: ensemble overlap says a
shared grid cannot uniquely address a level, not that the deployed weight is wrong enough
to matter.

Per-class on-device (Se / +P / F1): **N 0.906 / 0.969 / 0.937**, F 0.868 / 0.589 / 0.702,
SVEB 0.475 / 0.760 / 0.585, VEB 0.828 / 0.758 / 0.791.

*(Optimized run: 100 LIF + 60 ALIF, mean-cue readout, firing-rate regularization, warmup + fast-decay-then-hold
LR schedule (1e-2→1e-3), balanced sampling; best at epoch 57. Per-epoch accuracy / macro-F1 / loss /
firing-rate curves + confusion are regenerated by `make_ecg_figures.py` into `../Combined Figures/ecg figures/`.
The device-faithfulness, ablation, robustness and efficiency conclusions are the core contribution and are
stable across accuracy. The reference's 95.83% figure is on the **same LSNN architecture and the same 4-class
task**, using its VO₂-memristor encoder and RC-based LIF/ALIF neurons with **software** synapses; matching that
raw accuracy is not the target here — our contribution is that GAA-FeFET polarization-switching physics
realizes and is load-bearing for the same neuromorphic ECG classifier, as the **hardware synapse**.)*

**Efficiency FoM (device-level, first-order) — figure K4.** The neuron membrane time constant
τ = R·C = 11.11 ms enters the dynamics; only τ matters, so the network is invariant to the individual R
and C. We report the **compact subthreshold-CMOS realization: C_mem = 1 pF with R_leak ≈ 11 GΩ**
(τ = 11.11 ms). Every count below is measured on the deployed network rather than assumed
(`fig_k4_energy.py`):

| quantity | value |
|---|---|
| synaptic weights | **261 440** → **522 880 FeFETs** (differential) |
| | `fc1` (160, 3, 10) = 4 800 · `hidden.rc` (160, 160, 10) = 256 000 · `fc2` (4, 160) = 640 |
| input line activity | 196.1 spikes/beat = **5.86 %** |
| hidden line activity | 3 455.7 spikes/beat = **1.94 %** (21.6 spikes/neuron) |
| device read, event-driven | **103.9 pJ/beat** |
| device read, fully clocked | 4.62 nJ/beat |
| neuron membrane | **432.0 pJ/beat** |
| **core compute (event-driven read + neuron)** | **535.8 pJ/beat** |
| peripheral ADC *(assumption: 1 pJ/conversion × 164 columns × 1116 steps)* | **183.0 nJ/beat** |
| device write, whole array, **one-time** | **69.6 pJ** (0.0089 fJ × 15 pulses × 522 880) |

Both delayed layers store `max_delay = 10` independently programmed taps per connection, so the array is
24× larger than a naive `in × out` count suggests; the count above comes from
`model.named_parameters()`. Two results are worth stating plainly. **Programming the entire array costs
0.13× a single inference** — non-volatility means that cost is paid once and then never again, which is
the whole argument for a ferroelectric weight. And **the assumed ADC term is 342× the core compute**: the
FeFET array is not the bottleneck of a real system, and quoting only the core number would overclaim.
That is why the peripheral bar is in the figure rather than in a caveat.
The behavioural simulation uses an equivalent RC (C = 1.419 µF, R = 7.83 kΩ, identical τ) inherited from
the reference LSNN neuron circuit [VO₂ ref]; because τ is preserved the two realizations give identical
outputs. Adopting the pF realization is compatible with standard compact CMOS neurons and avoids the
µF-scale capacitor of the reference RC design.

**Scope of the FoM (stated honestly).** These are first-order estimates of the **core compute + neuron**
energy only. They do **not** include ADC/DAC, sense amplifiers, digital control, or array parasitics
(IR-drop, sneak paths), which can dominate a full in-memory-computing system; full-system energy is out of
scope for this device-level demonstration. Read-window (t_read = 100 ns), read bias (V_read = 50 mV), and
membrane swing (0.5 V) are assumed first-order values. Weights are written once (ex-situ inference), so
programming/endurance overhead is amortized and not included.

---

## 8. IEEE TED positioning

TED rewards device physics with a rigorously characterized, load-bearing demonstration — not ML
leaderboard scores. Our claims map onto that expectation:

1. **Novelty** — first GAA-nanosheet HZO-FeFET used as a multilevel analog synapse in a spiking network
   for a real biomedical task, with the synapse extracted from **measured** LTP + temperature data.
2. **Device is load-bearing** (ablation) — pre-empts the "any 2-state element would do" rejection.
3. **Device is faithful** (post-quantization near-lossless on the measured ladder).
4. **Hardware-realistic** (measured-temperature + variation + retention).
5. **Real neuromorphic FoM** (pF caps, sub-nJ/beat, non-volatile zero-standby weights).
6. **Reviewer-grade metrics** under a stated protocol.

Accuracy is framed as *sufficient to demonstrate neuromorphic ECG discrimination on the device* — the
contribution is the device physics and its alignment with the architecture. We adopt the reference's LSNN,
encoding, dataset and neuron parameters and contribute the **hardware FeFET synapse**; the reference used
the same LSNN but kept its synapses in software.

---

## 9. Reproducibility

Code (this directory):
- `redesign_stage1.py` — training (`--model orig --readout meancue --lr 1e-2 --balance`).
- `fefet_device.py` — measured-level device model (LTP + temperature CSVs).
- `post_quantize.py` — deployment to the measured FeFET differential levels (+ `--levels 2` ablation).
- `robustness_eval.py` — measured-temperature + D2D/C2C + retention.
- `REDESIGN/code/{energy_ledger,metrics,fefet_synapse}.py` — FoM, metrics, synapse primitives.

Data:
- `data_ecg/{up,down}/*_guiyi.csv` — encoded ECG beats.
- `../../Device_Optimization/csv_export/raw/{ltp_potentiation,ltp_vs_temperature}.csv` — measured device
  (repo-level; `fefet_device.py` resolves it by walking up, and rejects any copy that is not the
  post-Phase-1 export).

Commands:
```
python post_quantize.py   --ckpt REDESIGN/runs/paper150b/paper150b_best.ckpt --levels 15
python post_quantize.py   --ckpt REDESIGN/runs/paper150b/paper150b_best.ckpt --levels 2
python robustness_eval.py --ckpt REDESIGN/runs/paper150b/paper150b_best.ckpt --tag robust_final
python make_ecg_figures.py    # regenerates figures + CSVs into ../Combined Figures/ecg figures/
# (retrain from scratch — NOT needed, the checkpoint is locked)
python redesign_stage1.py --model orig --readout meancue --lr 1e-2 --warmup 5 --epochs 150 \
  --sched_epochs 30 --eta_ratio 0.1 --spike_lambda 5e-6 --spike_target 20 --num_lif 100 --num_alif 60 \
  --max_delay 10 --batch 64 --tag paper150b
```
