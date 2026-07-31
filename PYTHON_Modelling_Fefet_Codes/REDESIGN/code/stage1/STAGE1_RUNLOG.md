# Stage-1 autoresearch run log

Goal (REDESIGN/02_PLAN.md): prove the Stage-1 FoMs for configs **A / B / C** —
macro-F1 (device-quantized) credible vs FP upper bound, while the hard gates hold.
Methodology: autoresearch (edit `train_stage1.py` → run → keep/discard on macro-F1).

## Setup
- Branch `autoresearch/jun26-stage1`. Baseline commit `86f2854`.
- Local PC (i5, 4 threads): ~65 s/batch → full 30-epoch run ≈ 7 h ⇒ **training on Camber**.
  Calibration / self-checks / smoke run **locally**.
- Camber: `camber.bat` = `wsl -d Ubuntu bash -lc "camber %*"`; PowerShell `%*` strips inner
  quotes, so **launch jobs via direct `wsl ... bash -lc '...'`**. Output via `camber job logs <id>`.
  Node (xxsmall) = 16 CPU, py3.11, has numpy/pandas/matplotlib; **pip-install torch(cpu)+sklearn+
  spikingjelly in-job** (run.py). Input files copied to `/home/camber/workdir`; outputs NOT synced
  back — read results from logs.
- Stash: `stash://hozaifa/gaafet-stage1/` (code + data_ecg + run.py).

## Device / neuron facts used
- Calibrated FeFET: g_min=1/71.4 MΩ, g_max=1/2.34 MΩ (~30× window), 15 log levels.
- Compact neuron = EXACT pF reparameterization of the proven VO2-RC neuron (τ, gains
  cap-invariant): C_mem=C_a=1 pF, R_h+R_s=11.1 GΩ, R_a=556 GΩ (subthreshold), τ_mem=11.11 ms.
- Operating point (calib sweep, config A): FR≈3.75 Hz @1.5e-9, 46 Hz @3e-9, 254 Hz @6.976e-9.
  **input_scaling = 2.3e-9** (~18 Hz, in trainable band; spike-reg target 15 Hz).

## FoM gates (analytic, from energy_ledger — already PASS for A)
- G1 cap: 100 pF total (1 pF/neuron) ≪ 1 nF.   [old design 142 µF]
- G2 energy: ~306 pJ/beat ≪ 10 nJ.   [≈1e6× cap, 2e7× neuron-energy vs old]
- G4 latency: 1116·dt = 0.62 s ≤ one beat.
- C config: C_mem=0 (cap-free) → cap gate trivially passes.

## Runs
| job | config | epochs | levels | macro_f1_dev | macro_f1_fp | acc | κ | status |
|-----|--------|--------|--------|--------------|-------------|-----|---|--------|
| 22910 | A | 3 | 15 | (validation — pipeline check) | | | | running |

## Planned matrix (after validation)
- A/B/C @ EPOCHS=30, levels=15 → primary macro-F1 + FP→device gap.
- A @ levels=2 (binary) → G6 load-bearing ablation (expect macro-F1 drop).
