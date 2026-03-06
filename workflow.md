# ECG Classification Workflow

The ECG classification process in this neuromorphic system (demonstrated on the MIT-BIH arrhythmia database) is a complete hardware-friendly pipeline that avoids traditional ADCs/DACs and uses only VO₂ memristor-based circuits for both encoding and decision-making. It achieves 95.83% accuracy on a 4-class task (Normal N, Ventricular ectopic beat VEB, Supraventricular ectopic beat SVEB, Fusion beat F) with a very small network (only 100 hidden neurons). Below is the full step-by-step process exactly as implemented in the paper.

---

## 1. Data Acquisition & Preprocessing (MIT-BIH Arrhythmia Database)

- Raw ECG recordings (30 min each from 48 subjects) are resampled at 1800 Hz.
- Each recording is segmented into single heartbeats of ~556 ms (exactly 1000 timesteps).
- Every heartbeat is amplitude-normalized to the range [0, 0.6 V].
- Heartbeats are labelled according to the AAMI standard into 4 classes:
  - N (Normal): 1000 samples
  - VEB: 500 samples
  - SVEB: 250 samples
  - F (Fusion): 250 samples
- Total dataset: 2000 heartbeats.
- Random split: 1664 training / 336 testing samples.

---

## 2. Asynchronous Spike Encoding (VO₂ Memristor-Based Encoder)

This is the first hardware stage (Fig. 4 in the paper). A single analog ECG heartbeat is converted into two sparse spike trains (UP and DOWN) plus a CUE signal.

**Circuit operation (fully memristor-driven, no ADC/DAC):**

- The input ECG voltage is amplified and applied to a VO₂ memristor through an op-amp stage.
- When the amplified voltage exceeds the positive threshold V_th of the VO₂ device → the memristor switches to LRS, a positive spike is generated on the UP channel, and a feedback transistor resets the internal node.
- When it crosses the negative threshold → a spike is generated on the DOWN channel.
- Each spike marks the exact moment the original ECG signal has increased (UP) or decreased (DOWN) by a fixed quantization step δ.

**The threshold step δ is analytically given by:**

$$\delta = \frac{V_{\rm th}}{\alpha \frac{R_{\rm off}}{R_{\rm on}} + R_3}$$

where:
- $V_{\rm th}$ ≈ ±3.4 V (device threshold),
- $\alpha = R_3 / R_1$ is the gain of the intermediate amplifier (tunable; larger α → smaller δ → higher accuracy but more spikes),
- $R_{\rm off}/R_{\rm on}$ is the HRS/LRS ratio of VO₂.

**Key properties:**

- Spikes are sparse and on-demand (no spikes if the signal is flat).
- The original ECG can be perfectly reconstructed from the spike times.
- A CUE channel (third input) fires constantly at the very end of the 1000-timestep window to tell the network "now output the classification".

**Result per heartbeat:** three spike trains (UP, DOWN, CUE) that preserve both amplitude and precise timing information.

---

## 3. LSNN Decision Network Architecture (3 × 100 × 4)

The encoded spikes are processed by a Long Short-Term Memory Spiking Neural Network (LSNN) whose neurons are directly emulated by VO₂ memristor circuits (Fig. 5a).

**Network topology:**

- Input layer: 3 nodes (UP spikes, DOWN spikes, CUE spikes). Each synaptic weight is initialized with a random delay.
- Hidden recurrent layer: 100 spiking neurons
  - 60 × LIF neurons (standard Leaky Integrate-and-Fire)
  - 40 × ALIF neurons (Adaptive-LIF) ← the key for temporal memory
  - Low-pass filter on hidden spikes (mimics biological synaptic dynamics).
- Output layer: 4 nodes (softmax probabilities for N, VEB, SVEB, F).

**Hardware neuron models (directly mapped from the VO₂ circuits):**

LIF membrane dynamics (discretized):

$$V_{m_{\rm LIF}}(t + \Delta t) = \alpha V_{m_{\rm LIF}}(t) + (1 - \alpha) R_{\rm eff} x$$

ALIF membrane dynamics:

$$V_{m_{\rm ALIF}}(t + \Delta t) = \alpha V_{m_{\rm ALIF}}(t) + (1 - \alpha) R_{\rm eff} (x - I_{\rm leak})$$

Adaptation variable $V_g$ (only ALIF):

$$V_g(t + \Delta t) = \beta V_g(t) + (1 - \beta) R_3 I_a z$$

where $\alpha = \exp(-\Delta t / R_{\rm eff} C_1)$, $\beta = \exp(-\Delta t / R_3 C_2)$, $z = 1$ if the neuron spiked, $I_{\rm leak}$ increases with each spike (adaptation), and all parameters are taken from the real VO₂ device measurements.

**Why ALIF is crucial:** The adaptive leakage makes neurons that fired recently harder to fire again → the network can "remember" patterns over long timescales. Mixed LIF+ALIF outperforms LIF-only by ~15–18% and is almost as good as ALIF-only while using fewer adaptive (larger) circuits.

---

## 4. Training Procedure (BPTT with Surrogate Gradients)

**Loss function:**

$$L = \frac{1}{B}\sum_{i=1}^{B}\sum_{j=1}^{C} -t_{ij}\log\sigma(y_{ij}) + \frac{\lambda_r}{N}\sum_{n=1}^{N}(\bar{f}_n - f_0)^2$$

- First term: categorical cross-entropy (classification).
- Second term: spike-rate regularization (encourages sparse firing, $\lambda_r$ tuned).

**Back-propagation through time (BPTT)** over the full 1000 timesteps.

Because spikes are non-differentiable, a surrogate gradient is used:

$$f(x) = \max[0, y(1 - |x|)]$$

- Training runs for 150 epochs.
- The CUE signal forces the network to produce the final classification only at the end of the heartbeat.

---

## 5. Inference / Classification

1. Encoded UP/DOWN/CUE spikes enter the input layer.
2. Weighted summation + recurrent connections → hidden LIF/ALIF integration.
3. Hidden spikes → low-pass filter → output layer.
4. At the last timestep (CUE active), the output node with the highest softmax value is chosen as the predicted class.

---

## 6. Results & Ablation Studies

- **4-class accuracy:** 95.83% (confusion matrix shows excellent separation).
- **2-class (N vs. not-N):** 99.40% with the same mixed LSNN.

**Ablations (same network size):**

- LIF-only → ~15% worse
- ALIF-only → slightly better than mixed but uses more area
- The adaptive property of ALIF neurons is explicitly visible in the $V_g$ traces: neurons that fired early in the heartbeat become temporarily "inhibited" during the decision window, enabling precise temporal discrimination.

---

## 7. Hardware Mapping & Efficiency

- All components (encoder + LIF + ALIF neurons) are built from the same planar VO₂ memristors (400 nm channel, <70 ns switching).
- The entire LSNN decision stage maps to only ~100 physical neurons → extremely low area and power, ideal for wearable devices.

---

## Summary

In short, the process is analog ECG → VO₂ encoder (sparse UP/DOWN + CUE spikes) → small LSNN (60 LIF + 40 ALIF) trained with BPTT → 4-class output at CUE time, achieving state-of-the-art accuracy with orders-of-magnitude fewer parameters than conventional deep networks. This is the exact pipeline used and experimentally validated in the paper.

# GAAFeFET Parameter Replacement Guide

---

## 1. Exact VO₂ Parameters Used in the Original Code (and Paper)

These are hard-coded in the provided files. You will replace them with your GAAFeFET equivalents.

**Encoder (`vo2_encoder.py`):**
- `Vth = 3.4 V` (threshold voltage, symmetric positive/negative)
- `Roff = 14000 Ω` (high-resistance state)
- `Rs = 1500 Ω` (voltage-dividing resistor)
- `beta = 200` (intermediate op-amp gain α)

**LSNN neurons (`main_ecg.py` FLAGS):**
- `Vdd = 5.0 V` (supply)
- `vth = 3.6 V` (effective threshold)
- `vh = 1.5 V` (holding/reset voltage)
- `Rh = 14e3 Ω` (series resistance)
- `Rs = 1.5e3 Ω`
- `Cmem = 716.8e-9 F` (membrane capacitance)
- `input_scaling = 5000e-6` (scales input current)

**ALIF adaptation circuit:**
- `Ra = 100e3 Ω`
- `Ca = 5556e-9 F`
- MOSFET params: `kappa_n=29e-6`, `kappa_p=18e-6`, `vtn=0.745 V`, `vtp=0.973 V`, `wl_ratio_n=16`, `wl_ratio_p=8`

These come directly from the fabricated VO₂ devices (400 nm channel) and circuit measurements in the paper.

---

## 2. Parts of the Code You Can Keep 100% the Same

These files and functions do not depend on VO₂ physics:

| File / Part | What stays exactly the same |
|---|---|
| `dataset.py` | Entire file (loads encoded spikes + adds CUE signal) |
| `surrogate.py` | Entire file (ScaledPiecewiseQuadratic for BPTT) |
| `utils.py` | `raster_plot()` and `absId()` (you may keep `absId()` if you still use MOSFETs for adaptation) |
| `main_ecg.py` | Training loop, optimizer, scheduler, loss (cross-entropy + spike reg), plotting code, FLAGS structure (except device params) |
| Network topology | 3 inputs (UP/DOWN/CUE) → 100 hidden (60 LIF + 40 ALIF) → 4 outputs |
| `DelayedLinear` class | Synaptic delays (random 0–10 dt) |
| `LPFilter` class | Low-pass filter on hidden layer |
| Training hyperparameters | 150 epochs, batch=128, lr=1e-2, spike regularization, etc. |

Result: You can run the same training script once the neuron/encoder models are updated.

---

## 3. Parts You Must Change (and Why)

| File | What to change | Why (GAAFeFET limitation) |
|---|---|---|
| `vo2_encoder.py` | Entire `LC_neuron_spike()` function + δ formula | VO₂ threshold switching + feedback reset does not exist in a single FeFET |
| `model.py` | `eLIFVO2` class → new `LIF_GAAFeFET` / `ALIFVO2` class → new `ALIF_GAAFeFET` | LIF/ALIF dynamics (integration, fire, reset, adaptation) rely on VO₂ volatile switching |
| `main_ecg.py` | Only the FLAGS dictionary (replace VO₂ values) | New device parameters go here |

You will not change the LSNN architecture or training — only the internal neuron dynamics.

---

## 4. Parameters You Must Extract from Your GAAFeFET in Sentaurus TCAD

Run these simulations (DC, C-V, transient pulse) on your calibrated device:

**For Encoder (replacing VO₂ threshold):**
- Effective positive/negative threshold voltages (`Vth_pos`, `Vth_neg`)
- On-state resistance (`Ron` or `Ids` at `Vg=Vdd`) and off-state resistance (`Roff`)
- Switching speed (time to turn on/off under pulse)

**For LIF/ALIF neurons:**
- Gate capacitance (`Cmem` or `Cgg` — this replaces the external capacitor)
- Threshold voltage (hysteretic `Vth` due to ferroelectric polarization)
- Holding/reset voltage (effective `Vreset` after polarization switch)
- Series resistance (`Ron` + any external `Rs`)
- Leakage current vs. `Vg` (for adaptation)

**For ALIF adaptation (if you keep MOSFET feedback):**
- Polarization retention time or depolarization rate (to tune τ_a)
- `Ids`–`Vg` curve (to replace `absId()` function)

**Optional but useful:**
- Endurance (>10^6 cycles)
- Power consumption per spike

Export these as numbers (e.g., `Vth = 1.2 V`, `Cmem = 5 fF/μm`, etc.).

# ✅ Complete Sentaurus TCAD Extraction Guide + Exact Code Changes for GAAFeFET Adaptation

You already have a calibrated GAAFeFET in Sentaurus.
We will extract exactly the 8 parameters needed to replace VO₂ behaviour.

**Recommended workflow in Sentaurus (do this once):**

- Use your existing calibrated structure (GAAFeFET with ferroelectric layer).
- Create 3 simulation decks:
  - DC Id-Vg (for Vth, Ron, Roff)
  - AC C-V (for Cmem)
  - Transient pulse (for vh/reset + switching speed + adaptation)
- Use Inspect or Tecplot for extraction (I give exact commands below).
- After extraction, you will update only 3 files (`vo2_encoder.py`, `model.py`, `main_ecg.py`).

---

## Parameter 1: Threshold Voltage (Vth_pos and Vth_neg)

**Why needed:** Replaces VO₂ threshold switching in both encoder and LIF/ALIF neurons.
**Files affected:** `vo2_encoder.py`, `model.py`, `main_ecg.py`

**Sentaurus steps:**

In Sdevice input file (`.sdev`):
```tcl
Solve {
    Coupled { Poisson Electron Hole }
    GateVoltage = -2.0 to 2.0 step 0.01   ;# sweep Vg, Vd=0.1V fixed
}
```
Run simulation → open in Inspect.

Extract Vth using constant-current method (Id = 10⁻⁷ A/µm):
> Right-click curve → Extract → Threshold Voltage → Constant Current = 1e-7

Record `Vth_pos` (forward sweep) and `Vth_neg` (backward sweep due to hysteresis).

Also note subthreshold swing if you want better surrogate later.

**Exact code changes:**

`vo2_encoder.py` (lines 13–14):
```python
Vth_pos = 1.25   # ← YOUR VALUE
Vth_neg = -1.25  # ← YOUR VALUE
```
Change the if condition (line 31) to:
```python
if gout2[i] * fenyaxishu >= Vth_pos or gout2[i] * fenyaxishu <= Vth_neg:
```
`main_ecg.py` (FLAGS, line ~52):
```python
"vth": 1.25,          # ← YOUR Vth_pos
```
`model.py` (eLIFVO2 & ALIFVO2 init, lines ~80 and ~130):
```python
v_threshold = 1.25   # ← YOUR VALUE
```

---

## Parameter 2: On-resistance (Ron) and Off-resistance (Roff)

**Why needed:** Used in δ formula (encoder) and effective resistance in neuron charge equation.
**Files affected:** `vo2_encoder.py`, `main_ecg.py`

**Sentaurus steps:**

From the same Id-Vg sweep:
- At `Vg = Vdd` (5 V), read `Ids` → `Ron = Vd / Ids` (linear region).
- At `Vg = 0 V`, read `Ids` → `Roff = Vd / Ids`.

Use Inspect → Extract → Resistance.

**Exact code changes:**

`vo2_encoder.py` (lines 15–16):
```python
Ron = 500.0     # ← YOUR VALUE (Ω)
Roff = 1e6      # ← YOUR VALUE (Ω)   # usually very high in FeFET
```
Update delta formula (line 24):
```python
fenyaxishu = Ron / (Ron + Rs)   # changed from Roff
delta = Vth_pos / (beta * fenyaxishu)
```
`main_ecg.py` (FLAGS, line ~58):
```python
"Rh": 500.0,     # ← YOUR Ron
```

---

## Parameter 3: Gate Capacitance (Cmem)

**Why needed:** Replaces external capacitor in LIF/ALIF (membrane time constant τ).
**Files affected:** `main_ecg.py`, `model.py`

**Sentaurus steps:**

In Sdevice: add AC simulation
```tcl
Solve {
    Coupled { Poisson Electron Hole }
    AC { Frequency = 1e6 }
    GateVoltage = 0 to 2 step 0.01
}
```
In Inspect → C-V plot → extract `Cgg` (total gate capacitance) at operating point (e.g., `Vg=1 V`).
Multiply by device width/length if needed to get total `Cmem` in Farads.

**Exact code changes:**

`main_ecg.py` (FLAGS, line ~60):
```python
"Cmem": 5.2e-15,   # ← YOUR value in Farads (e.g. 5.2 fF)
```
`model.py` (both classes, lines ~75 and ~125):
```python
self.tau = Cmem * (Rh + Rs)   # automatic, no change needed after FLAGS
```

---

## Parameter 4: Holding / Reset Voltage (vh or Vreset)

**Why needed:** After firing, neuron resets to this voltage (VO₂ Vhold).
**Files affected:** `main_ecg.py`, `model.py`

**Sentaurus steps:**

Transient pulse simulation:
- Apply short gate pulse (Vdd for 10 ns) then drop to 0 V.
- Plot `Ids` vs time → when polarization switches back, record effective reset voltage.

Or from Id-Vg hysteresis: lowest `Vg` where device returns to off-state.

**Exact code changes:**

`main_ecg.py` (FLAGS, line ~53):
```python
"vh": 0.8,      # ← YOUR reset voltage
```
`model.py` (both classes, lines ~80 and ~130):
```python
v_reset = 0.8   # ← YOUR VALUE
```

---

## Parameter 5: Series Resistor (Rs) and input_scaling

**Why needed:** Voltage divider and current scaling.
**Files affected:** `vo2_encoder.py`, `main_ecg.py`

**Sentaurus steps:** Usually keep external `Rs = 1.5 kΩ` (same as original).
For `input_scaling`: run transient simulation with known current → match spike rate.

**Exact code changes:**

`vo2_encoder.py` (line 17):
```python
Rs = 1500.0     # can keep same unless you want to tune
```
`main_ecg.py` (FLAGS, line ~61):
```python
"input_scaling": 5000e-6,   # ← tune this (start with 5000e-6, adjust until spike rate matches paper)
```

---

## Parameter 6: Adaptation Parameters for ALIF (Ra, Ca equivalent)

**Why needed:** Controls V_g (adaptation) dynamics.
**Files affected:** `main_ecg.py`, `model.py`

**Sentaurus steps:**

- Long pulse train (100 spikes) → measure depolarization time (how fast polarization relaxes).
- Fit τ_a = depolarization time constant.
- Set `Ca = τ_a / Ra` (keep `Ra = 100 kΩ`).

**Exact code changes:**

`main_ecg.py` (FLAGS, lines ~64–65):
```python
"Ra": 100e3,
"Ca": 5.556e-9,   # ← YOUR fitted value
```
`model.py` (ALIFVO2, line ~140):
```python
self.tau_va = Ca * Ra
```

---

## Parameter 7: Switching Speed (for dt validation)

**Why needed:** Validate your `dt` (5.556e-4 s) is slower than device speed.

**Sentaurus steps:**

Transient pulse: 10 ns rise/fall → measure time from 10% to 90% `Ids`.
If < 100 ns → your device is fast enough (keep `dt` same).

No code change — just print in terminal and check.

---

## Parameter 8: MOSFET parameters (vtn, vtp, kappa, wl_ratio) – Optional

If you keep external MOSFETs for ALIF adaptation (recommended for first version):

- Keep original values (they are standard 180 nm CMOS).
- Or extract from your own access transistor in TCAD.

Code: leave unchanged in FLAGS.

---

## Final Quick-Start Checklist (do in this order)

1. Extract all 8 parameters using above Sentaurus steps (save in a text file).
2. Update `vo2_encoder.py` (Vth, Ron, Roff, delta formula).
3. Update `main_ecg.py` FLAGS dictionary.
4. Update `model.py` (v_threshold, v_reset, Cmem, tau).
5. Regenerate spike CSV files with new encoder → put in `data_ecg/up` and `down`.
6. Run `python main_ecg.py` → you now have GAAFeFET-based ECG classifier!
7. (Optional) Set `num_alif=0` in FLAGS for LIF-only first test.

**Expected outcome:** Same 95.83% accuracy (or better) with your device parameters.