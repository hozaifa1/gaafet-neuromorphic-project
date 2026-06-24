---
name: Project status (as of 2026-05-30)
description: Current state of GAA-FeFET LIF neuron thesis. Calibration shifted to Liao 2022. Phase 1C and 1D TCAD complete. SNN training resumed with pure CE.
type: project
---

## 1. Device Calibration Shift (New_cal)
* **Calibration Reference:** Shifted from Tasneem 2022 to **Liao et al. (VLSI 2022) Fig. 7** MFMFS-GAA curves to match the n-channel GAA Nanosheet architecture and operating window.
* **Tier-1 Calibration Status:** **FAILED** (MW = 0.421 V vs. target 1.094 V / 1.30 V; shape-match $R^2$ = -2.242 post-PGM / -0.611 post-ERS).
* **Diagnosis:** Absolute threshold voltage ($V_t$) mismatch of ~1.9 V stemming from workfunction differences between TSMC's process and our nominal 4.35 eV.
* **Tier-2 Plan:** Retune gate electrode workfunction in `New_cal/sdevice_liao2022_writeread.cmd` (sweeping in range `[4.35, 4.5, 4.65, 4.8, 4.95] eV`) to shift $V_{t,PGM}$ into alignment.

## 2. Phase 1C (Remaining Characterization) — DONE
* **Capacitance (simG):** Intrinsic gate capacitance $C_{gg} = 0.143\text{ fF}$, giving $\tau_{native} = 1.1\text{ ps}$. Rule out capacitorless single-FeFET LIF; external $C_{mem}$ is mandatory.
* **Leakage (simD):** Confirmed $\tau_{leak} \propto \tau_P$. Locked $\tau_{leak} = 10\ \mu\text{s}$ at the $\tau_P = 10\ \mu\text{s}$ operating point.
* **Energy (simE):** $E_{pulse} \approx 200\text{ fJ}$ (drain-dominated), total burst energy $E_{fire} \approx 1.8\text{ pJ}$.
* **Endurance (simF):** Physically correct $\tau_P=10\ \mu\text{s}$ causes non-stationary drift (+4.7%/cycle on baseline) and fire-ratio collapse (integrate-and-fire signal lost over cycles).

## 3. Phase 1D (Operating Point & Optimizations) — DONE
* **Locked Operating Point (from H9 - 2026-05-21):**
  * $V_{pgm} = +2.0\text{ V}$ (100 ns pulses, sub-coercive)
  * **Pulses per fire burst: 5** (N=5 locked; saves 44.8% energy: 637 fJ/cycle vs. 1154 fJ/cycle)
  * $V_{GS,read} = -0.5\text{ V}$ (sub-threshold read)
  * $V_{erase} = -6.0\text{ V}$ (10 $\mu$s pulse)
  * Relaxation: $70\ \mu\text{s}$ at $V_{GS} = -0.5\text{ V}$
  * Steady-state fire ratio: 2.80× (c3-c5, N=5)
  * Cycle energy: **637 fJ/cycle** (reaches 45% savings from H4 baseline)
  * Analog cell: Monotonic 7-level walk (L3-L9) with +39%/level separation.
* **Metric Gates:** SS_PGM (100 mV/dec) and $R^2$ post-ERS (0.95) passed. SS_ERS (164 mV/dec) and post-PGM $R^2$ (0.77) are model-limited (leakage floor). $E_{fire}$ fails M5/M6 gates due to FE-switching charge.

## 4. Step 2 (Python SNN, MIT-BIH ECG 4-class)
* **KD Failure Discovery (main_ecg_8c):** Knowledge Distillation from the RC-teacher to the FeFET student failed, causing representational collapse to the majority class (accuracy ~50.89%). KD was dropped entirely.
* **Pure CE Warmup (main_ecg_8c):** Phase 1 pure Cross Entropy training reached **76.49%** accuracy at epoch 5 — the best polarization-physics network performance to date.
* **Resume Fine-tuning (main_ecg_8d_pure_ce_resume.py):** Resumes from epoch 5 checkpoint at a constant low LR = 5e-4 with a light spike regularizer ($\lambda = 1e-7$) to push accuracy past 76.49% toward the 78-82% target.
