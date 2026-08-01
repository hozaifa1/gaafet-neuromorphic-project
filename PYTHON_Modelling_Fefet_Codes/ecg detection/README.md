# ECG Detection — LOCKED FINAL RESULT (GAA-FeFET synapse SNN)

Self-contained snapshot of the pipeline that produced our **final, locked-in ECG
arrhythmia-detection result** for the IEEE TED paper. The classifier is a spiking
neural network whose **synapses are our measured GAA-HZO FeFET** (ferroelectric
polarization-switching → 15 non-volatile conductance levels = trained weights). The
device physics is the contribution: we adopt the reference VO2-memristor LSNN pipeline
(its curated MIT-BIH dataset, level-crossing spike encoding, LSNN architecture and LIF/ALIF
neuron parameters) and replace the reference's **software** synapses with our measured
GAA-FeFET **hardware synapse** — the only characterized device we contribute. The encoder
is the reference's level-crossing (delta) encoding and the neuron is generic CMOS.

Status: **FROZEN. Do not retrain.** Verified reproducible (checkpoint load → deploy →
ablation all pass).

---

## Result (MIT-BIH, 4 AAMI classes N/SVEB/VEB/F, intra-patient)

| Configuration | Accuracy | macro-F1 | κ |
|---|---:|---:|---:|
| Software (full precision) | **0.857** | **0.793** | 0.782 |
| On-device — 15 measured FeFET levels (300 K) | **0.830** | **0.754** | 0.742 |
| Ablation — 2 levels (binary synapse) | 0.563 | 0.286 | 0.290 |

Device faithfulness gap: −2.7 % acc / −3.9 % macro-F1 (near-lossless). Binary-synapse
ablation collapses the model → **the multilevel polarization range is load-bearing.**
Robustness (measured 250/350 K ladders, device-to-device / cycle-to-cycle variation,
retention drift) all degrade only gracefully — see METHODOLOGY.md §7.

Phase 6 (2026-08-01) adds three figures, all reproducible from this folder:

| script | figure | claim |
|---|---|---|
| `fig_k2_levels.py` | **K2** accuracy vs level count | level *count* is not the figure of merit — at fixed n, accuracy swings with where the levels sit (n=8: 0.34–0.80); ~10–12 levels are needed for placement-robust operation |
| `fig_k3_variability.py` | **K3a/K3b** accuracy vs variability | device-to-device shifts a device's ladder and per-device write-verify recovers it; cycle-to-cycle blurs the rungs and sets the usable level count |
| `fig_k4_energy.py` | **K4** energy per inference | core compute 535.8 pJ/beat; whole-array programming 69.6 pJ **one-time**; the assumed column ADCs are 342× the core |

Per-class on-device (Se / +P / F1): N 0.906/0.969/0.937 · F 0.868/0.589/0.702 ·
SVEB 0.475/0.760/0.585 · VEB 0.828/0.758/0.791.

## Provenance / honesty notes

- Result = checkpoint `paper150b_best.ckpt`, **best-validation checkpoint at epoch 57**
  of a scheduled run (the run OOM'd at epoch 74; the test metric had already plateaued by
  ~epoch 40, so nothing was lost). 0.857/0.793 is a favorable single-epoch peak; the
  converged plateau is ~0.82–0.83 acc / ~0.75 F1, and the on-device 0.830/0.754 sits right
  on that plateau — i.e. a representative number.
- Protocol is **intra-patient** (random 1664/336 split of the curated `data_ecg`
  2000-beat set). Report it as such.
- The reference study (Yuan et al., *Nat. Commun.* 14:3695, 2023) reports 95.83 % on the
  **same** MIT-BIH 4-class task and the **same** LSNN architecture, but with their
  VO2-memristor encoder and neurons and **software synapses**; our contribution is the
  **hardware device-synapse** (FeFET weights) and the device-physics demonstration, not
  matching that raw accuracy. See METHODOLOGY.md for the comparison.
- `data_ecg` is the **reference's** pre-encoded beat set (the `*_guiyi.csv` UP/DOWN spike
  trains); the encoding is a level-crossing (delta) modulation adopted from the reference,
  not an independent encoder of ours.

## Reproduce (run from inside this folder)

```
# on-device deployment + faithfulness + binary-synapse ablation
python post_quantize.py --ckpt REDESIGN/runs/paper150b/paper150b_best.ckpt --levels 15
python post_quantize.py --ckpt REDESIGN/runs/paper150b/paper150b_best.ckpt --levels 2

# hardware-aware robustness (measured temperature + device/cycle variation + retention)
python robustness_eval.py --ckpt REDESIGN/runs/paper150b/paper150b_best.ckpt --tag robust_final

# regenerate all ECG paper figures (+ their CSVs) into ../Combined Figures/ecg figures/
python make_ecg_figures.py

# (retrain from scratch — NOT needed, the checkpoint is locked; kept for reference)
python -u redesign_stage1.py --model orig --readout meancue --lr 1e-2 --warmup 5 \
  --epochs 150 --sched_epochs 30 --eta_ratio 0.1 --spike_lambda 5e-6 --spike_target 20 \
  --num_lif 100 --num_alif 60 --max_delay 10 --batch 64 --tag paper150b
```

Environment: CPU-only, torch 2.x+cpu, spikingjelly 0.0.0.0.14, **numpy < 2** (1.26.4).

---

## Contents — what each file and folder does

### Python scripts (this folder)

| File | Role |
|---|---|
| `redesign_stage1.py` | **Training script.** Builds and trains the spiking LSNN in software with surrogate-gradient back-propagation-through-time. `--model orig` selects the VO2LSNN architecture; `--readout meancue` selects mean-cue pooling. Produces the checkpoint. (The final checkpoint is already provided — retraining is not needed.) |
| `model.py` | **Network definition.** The LSNN (`VO2LSNN`): delayed fully-connected input → recurrent hidden layer of LIF + adaptive-LIF neurons (`eLIFVO2`) → low-pass filter → linear readout. The neuron parameters (time constant, thresholds) are adopted from the reference study. |
| `dataset.py` | **Data loader** (`DeltaTransformedECG`). Reads the delta-encoded UP/DOWN spike trains + CUE channel from `data_ecg/` and provides the train/test split. |
| `surrogate.py` | **Surrogate gradient** (`ScaledPiecewiseQuadratic`) — lets gradients flow through the non-differentiable spike during training. |
| `utils.py` | Small helper utilities used by the model/training. |
| `fefet_device.py` | **THE DEVICE MODEL — this is where our measured device enters.** Loads the measured 15-level LTP conductance ladder from `Device_Optimization/csv_export/raw/ltp_potentiation.csv`, plus the 250/300/350 K temperature variants. Conductance = read current / read voltage. |
| `post_quantize.py` | **Deployment.** Snaps the trained weights onto the 15 measured differential FeFET conductance levels (post-training quantization) and reports software-vs-on-device faithfulness. `--levels 2` runs the binary-synapse ablation. |
| `robustness_eval.py` | **Hardware-aware robustness.** Re-evaluates the deployed model under the measured 250/350 K conductance ladders, device-to-device and cycle-to-cycle conductance variation, and retention drift (measured −0.96 %, RR-4). |
| `make_ecg_figures.py` | **Figure generator.** Regenerates all ECG paper figures (input/LIF/ALIF rasters, adaptation Vg, output probability, training curves, software/device confusion matrices, per-class bars, faithfulness/ablation) in Origin style, writing each PNG + its reproducing CSV into `../Combined Figures/ecg figures/`. |

### Shared modules — `REDESIGN/code/`

| File | Role |
|---|---|
| `metrics.py` | ECG metrics: accuracy, macro-F1, Cohen's κ, per-class sensitivity / positive-predictivity / F1, and the confusion matrix. |
| `fefet_synapse.py` | FeFET-synapse conductance helpers (e.g. the log-spaced level grid used for the 2-level ablation). |
| `energy_ledger.py` | Energy figure-of-merit bookkeeping (core-compute nJ per beat). |

### Data, results, and docs

| Path | Contents |
|---|---|
| `data_ecg/{up,down}/` | The curated, delta-encoded MIT-BIH beat set — UP and DOWN spike-train CSVs per class (N/F/SVEB/VEB). These two subdirs are the only ones the 4-class loader reads. |
| `../../Device_Optimization/csv_export/raw/` | The **measured device data** (repo-level, single source of truth): `ltp_potentiation.csv` (the 15-level conductance ladder) and `ltp_vs_temperature.csv` (250/300/350 K variants). |
| `REDESIGN/runs/paper150b/` | The **locked result**: `paper150b_best.ckpt` (the trained network, epoch 57) + `paper150b_history.json` (training curves). |
| `REDESIGN/runs/robust_measured.json` | Saved output of the robustness evaluation. |
| `METHODOLOGY.md` | Full device-physics + methods write-up (IEEE TED draft). |
| `VO2_reference_paper.pdf` | The reference study (Yuan et al., *Nat. Commun.* 14:3695, 2023) whose LSNN architecture, neuron parameters and dataset we adopt; cited for those and for the CMOS-neuron parameters. |

> Note: `fefet_device.py` resolves `Device_Optimization/csv_export/raw/` by walking up to the
> repo root — **one** source of truth, no bundled copy. A bundled copy used to be preferred
> here and went stale at the pre-Phase-1 normalization, making every absolute number
> (g_min/g_max, R_on/R_off, energy) 1.578× too high while accuracy was unaffected (weights
> normalize by `g_max`, so a global scale cancels). `measured_levels()` now refuses any
> `ltp_potentiation.csv` whose top level is not 8.316845 µA/µm.
