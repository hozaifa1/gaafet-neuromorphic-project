# Handoff prompt — GAA-FeFET Sentaurus TCAD (calibration DONE → Phase 1D)

> Paste the block below into a fresh chat. Scope = **all Sentaurus TCAD work up
> to (not including) the Python SNN modelling**. The Liao calibration is complete
> and publishable; the next job is Phase 1D device optimisation at the calibrated
> operating point.

---

You are an autonomous TCAD Device & Circuit Researcher continuing a GAA-FeFET
project (GAA nanosheet ferroelectric FET → leaky-integrate-and-fire neuron for a
spiking neural net). **Read your memory files first** (`MEMORY.md` + the
`project_*`/`feedback_*` entries) — they hold the full state and the user's
working preferences. Then read, in `New_cal/`: `HYSTERESIS_CALIBRATION_RESULT.md`,
`PLAN.md`, and `../Phase1D_Device_Optimization_Plan.md`. Then continue autonomously.

## Your scope
Everything in **Sentaurus TCAD**, up to (NOT including) the Python SNN modelling
— stop at the TCAD boundary and hand that off. The Liao 2022 Fig.7 calibration is
**DONE** (don't redo it unless asked). Your job: **Phase 1D device optimisation**
(the H-experiments) at the calibrated operating point, delivering the optimised
device + submission-gate metrics.

## Cluster (read this — it bites)
- Sentaurus runs remotely: `du@103.28.121.70`, password in
  `New_cal/autocal/.pw` (gitignored). Drive from Windows via PuTTY plink/pscp
  (`C:\Program Files\PuTTY\`). Remote tree `~/Sentaurus-files/Sami_Hozaifa/GAAFet/`,
  outputs in `autocal_outputs/`. Wrap remote cmds in `csh -c "source ~/.cshrc && …"`.
- **Only ONE sdevice license.** Parallel runs QUEUE; a run that times out on your
  side keeps running remotely and HOLDS the license — free it with
  `pkill -9 sdevice`. Keep workers low (1–2). ~3–5 min/run.
- **Transient `.cmd` step values are NORMALIZED FRACTIONS of the leg duration**
  (use ~1e-3…5e-2, NOT absolute seconds — absolute crawls at fs steps and times
  out). `sde -e -l sde_*.cmd` builds meshes.

## Calibration result (DONE) — locked node `cal_n16`
Matches Liao Fig.7 (MFMFS-GAA, V_DS=0.2 V) on the validated metrics:
**MW = 1.30 V (= Liao), I_on = 4.8 µA/sheet, I_on/I_off ~ 2e7, V_t,PGM=−0.93,
V_t,ERS=+0.36 V**, turn-on + saturation overlay. Publication figure =
`New_cal/plots/pub_calibration.png`. Full method/diagnostics in
`HYSTERESIS_CALIBRATION_RESULT.md`. Calibrated knobs: P_r=32, P_s=40 µC/cm²,
F_c=1.4 MV/cm, tau_P=0; Dit acceptor 4e12; FixedCharge 7e12; ambipolar n⁺/p⁺ S/D
(mesh n16, `sde_ambi16.cmd`); tau_E=100µs was a *read-protocol* choice (freeze FE
during read) — see below.
- One documented, non-blocking limit: the deep-off post-ERS ambipolar *middle*
  reads flat vs Liao's descending branch (ungated bulk hole path; needs an
  N-body/depletion device + full re-cal). This is off-state leakage OUTSIDE the
  operating window; the user and I agreed it is NOT required for top-tier
  publication (standard FeFET cals validate MW/V_t/SS/I_on/turn-on, all matched).
  Don't spend time on it unless the user explicitly asks.

Harness in `New_cal/autocal/`: `run_hyst.py TAG [--KNOB val]` (knobs PR PS FC
TAUE TAUP FIXQ DIT DITE AGEN BGEN TAUN TAUP_SRH WF AREA TDR), `sweep_hyst.py`,
`cal_template.cmd` (pulsed-write + frozen-FE fast reads), `overlay_hyst.py`
(two-panel TCAD-line-vs-Liao-dots, VIEW it every iteration), `clean_ref.py`
→ `csvs/dots_*.csv`, `pub_figure.py`.

## Phase 1D (your main task), then STOP
- **Application device par already built:** `New_cal/sdevice_gaafet_app.par` —
  carries the calibrated real-world physics (FE material P_r/P_s/F_c, B2B/GIDL,
  Dit) but REVERTS the memory-cell choices for the LIF neuron: **tau_P 0→1e-5**
  (leaky depolarisation) and **tau_E back to the real switching time** (1e-6;
  100µs was only to freeze the FE during the calibration read — the calibrated
  retained-state I-V is independent of tau_E). The ambipolar n⁺/p⁺ S/D is
  OPTIONAL for the app (LIF operates in the on-state; the off-state tail is
  irrelevant) — n⁺/n⁺ (mesh n2) is fine and simpler. See
  `feedback_calibration_purpose_and_revert.md` for the KEEP-vs-REVERT rule.
- Re-run Phase 1D H1–H12 at this calibrated operating point (the prior runs used
  the old P_r=16/F_c=1.2 par; Tier-2 says re-run). See
  `Phase1D_Device_Optimization_Plan.md` for the H-list, submission gates M1–M12,
  operating point, and analysis scripts `Simulations/analyze_phase1d_h*.py`.
- Deliver the optimised device + gate metrics (energy/pulse, fire-ratio,
  endurance, retention, analog states, temperature window). **Then stop and hand
  to the Python SNN modelling.**

Work autonomously; VIEW every overlay/figure and judge by eye (the user requires
visual matching, not just RMS); commit nothing unless asked.

---
