# Phase 1D — Re-run at the CALIBRATED operating point (2026-06-21)

Status: **IN PROGRESS** (autonomous TCAD session). The Liao 2022 Fig.7
hysteresis calibration is locked (`cal_n16`, see `HYSTERESIS_CALIBRATION_RESULT.md`).
The prior Phase 1D (H1–H12, `Phase1D_Device_Optimization_Plan.md`) was executed on
the OLD Tasneem-era par (P_r=16, F_c=1.2 MV/cm, `sdevice_gaafet_lif.par`). Per the
Tier-2 decision, every H-experiment is being re-run at the calibrated operating
point on the **application device**.

## Application device (frozen for this re-run)

- **Par:** `New_cal/sdevice_gaafet_app.par` — calibrated FE material
  (P_r=32, P_s=40 µC/cm², F_c=1.4 MV/cm), B2B/GIDL (Agen=4e16, Bgen=1.9e7),
  **tau_E=1e-6, tau_P=1e-5** (LIF leaky depolarisation reverted from the eNVM
  tau_P=0 used in calibration).
- **Mesh:** `n2_msh.tdr` (from `autocal/sde_gidl.cmd`) — n⁺(5e19)/p(1e16)/n⁺ NMOS,
  15 nm gate–S/D overlap, double HZO/SiO2 gate stack. KEEP-list geometry.
- **Interface physics (carried in the cmd, calibrated):** FixedCharge 7e12 cm⁻²
  + Dit acceptor Gaussian 4e12 cm⁻² @ EnergyMid 0.45 eV (fromCondBand), σ=0.30.
- **LIF read protocol (unchanged from H1 v3):** V_DS=0.05 V, V_GS_read=−0.5 V
  (sub-V_t), WF=4.35 eV, Areafactor=0.071.

Templates/scripts (this session):
- `autocal/h1app_template.cmd` — H1 V_pgm sweep (tokens @tdr@ @par@ @node@ @V_pgm@).
- `autocal/runs/h12app_des.cmd` — H12 analog-states, fully resolved.
- `Simulations/analyze_phase1d_h1_app.py` — H1 analyzer (reads
  `Simulations/simH_optimize/H1sweep_app_outputs/`, F_c=1.4).
- Remote outputs: `~/Sentaurus-files/Sami_Hozaifa/GAAFet/h1app_outputs/`.

## H1 — V_pgm operating-point sweep (calibrated)

Nodes: n2=1.0, n4=1.5, n5=2.0, n6=2.5, n7=6.0 V. 9 pulses × 100 ns @ V_pgm,
fire_ratio = ID(p9_read)/ID(baseline_pre). M2 gate: fire_ratio ≥ 1.5.

### Result — coarse sweep (DONE 2026-06-21)

| Node | V_pgm (V) | ID_base (µA/µm) | ID_p9 (µA/µm) | fire_ratio | \|E\|/F_c | staircase | M2 (artifact) |
|---|---|---|---|---|---|---|---|
| n2 | 1.0 | 8.75e-5 | 1.59e-4 | 1.821 | 0.13 | flat | PASS* |
| n4 | 1.5 | 8.75e-5 | 1.59e-4 | 1.816 | 0.25 | flat | PASS* |
| n5 | 2.0 | 8.75e-5 | 1.58e-4 | 1.811 | 0.37 | flat | PASS* |
| n6 | 2.5 | 8.75e-5 | 1.60e-4 | 1.835 | 0.48 | flat | PASS* |
| n7 | 6.0 | 8.75e-5 | 2.06e-3 | **23.6** | 1.30 | **rising p5→p9** | real |

\* The ~1.8× fire_ratio at V_pgm 1.0–2.5 V is a **fixed transient/charge-redistribution
artifact, NOT FE switching** — it is identical (1.81–1.84×) regardless of V_pgm, the
staircases are flat/slightly decreasing, and |E|/F_c < 0.5 (sub-coercive). Visual
proof: `Simulations/phase1d_h1_app/h1_staircase.png` (V_pgm 1–2.5 overlap on the
floor; only 6 V rises). Real, V_pgm-graded LIF integration appears only at the
super-coercive 6 V node. The genuine switching onset lies in the 2.5–6 V gap.

**→ The OLD V_pgm = 2.0 V operating point does NOT transfer to the calibrated
device.** This is the central result of the re-run and exactly the Tier-2 risk the
handoff flagged.

### Result — refinement sweep (DONE 2026-06-21), full V_pgm curve

| Node | V_pgm (V) | ID_p9 (µA/µm) | fire_ratio | \|E\|/F_c | integration tail (p5→p9) |
|---|---|---|---|---|---|
| n8 | 3.0 | 1.68e-4 | 1.92 | 0.60 | onset (weak) |
| n9 | 3.5 | 1.86e-4 | 2.12 | 0.72 | clear |
| **n10** | **4.0** | **2.27e-4** | **2.59** | **0.84** | **clean graded** ← LIF op-point |
| n11 | 4.5 | 3.18e-4 | 3.64 | 0.95 | strong |
| n12 | 5.0 | 5.24e-4 | 5.99 | 1.07 | near-coercive |
| n7 | 6.0 | 2.06e-3 | 23.6 | 1.30 | super-coercive (digital) |

Figure `Simulations/phase1d_h1_app/h1_staircase.png`: a clean fan of graded
leaky-integrate-and-fire staircases emerging above the ~3 V switching onset,
monotonically ordered by V_pgm. **This is the operating-point figure for the paper.**

### NEW LIF operating point (locked this session)

**V_pgm = 4.0 V** — lowest voltage giving clean sub-coercive (|E|/F_c = 0.84,
partial-polarization = true analog) graded integration with a comfortable
fire_ratio (2.59 ≥ M2's 1.5) and a clear rising p5→p9 tail. (3.5 V is a borderline
lower-energy option; 4.5 V a higher-margin option; 6 V is super-coercive/digital,
not LIF-analog.)

**Trade-off introduced by calibration:** the operating V_pgm moved 2.0 → 4.0 V, so
the original **M7 gate (V_pgm ≤ 2.0 V) now FAILS** and per-pulse write energy rises
(≈ Q_switch × 4 V vs × 2 V). This is the honest energy cost of the realistic
stronger calibrated FE — to be carried into the H5 energy re-accounting and the
manuscript. Read-level (V_GS_read) re-tuning can improve contrast at 4 V but cannot
recover switching at lower V_pgm (the FE simply does not switch sub-coercively).

### H12 analog states at the OLD ladder (0.8–2.4 V) — DEAD (DONE 2026-06-21)

All 9 rungs collapse to 1.56–1.60e-4 µA/µm (level separation 0.994–0.998×, i.e.
indistinguishable and slightly *decreasing*); |E|/F_c = 0.12; polarization
*relaxes* (0.270→0.213 µC/cm²) instead of accumulating. The old analog-state
window is entirely sub-coercive on the calibrated device. A shifted ladder
(spanning the switching-onset window from the refinement sweep) is required.
Outputs: `Simulations/simH_optimize/H12_app_outputs/`.

### Key physics shift vs the old (Tasneem-par) H1

The calibrated FE is ~2× stronger (P_r 16→32, F_c 1.2→1.4) and the device carries
the calibrated interface charge (FixedCharge 7e12, Dit 4e12). Consequences seen at
V_pgm=2.0:
- **ID_base jumps from 2.66e-7 → 8.75e-5 µA/µm** — the sub-V_t baseline at
  V_GS=−0.5 V is much higher (V_t shifted by the stronger FE + interface charge).
- **Saturation in 1 pulse** (was a 9-pulse staircase): one 100 ns / 2 V pulse
  already drives the FE near saturation; tau_P=1e-5 leak over the 202 ns inter-pulse
  gap is small, so ID is flat p1→p9.
- **fire_ratio compresses 4.79 → 1.81** (still PASS M2) because the higher baseline
  eats the dynamic range at this read level.

Implication for the LIF design: the read level V_GS_read may need to move more
negative on the calibrated device to recover dynamic range, and the burst length
(H9) can be even shorter (saturation reached by pulse 1). To be settled by the
full sweep below.

### H12 analog states — shifted ladder (3.0–5.4 V accumulating), DONE 2026-06-21

The single-shot **accumulating** ladder (no erase between rungs) is
**depolarization-limited** on the calibrated device: polarization *decreases*
monotonically across rungs (+0.27 → −0.08 µC/cm²), ID dynamic range only 1.4×,
non-monotonic. Cause: the −0.5 V read bias over the ~2 µs cumulative train
depolarises the leaky FE (tau_P = 10 µs) faster than a single 100 ns write per rung
can durably program. Outputs: `Simulations/simH_optimize/H12shift_app_outputs/`.

**→ Analog multi-level is instead demonstrated by the H1 per-V_pgm retained-level
family** (each node = independent fresh write, read at −0.5 V):
V_pgm 3.0/3.5/4.0/4.5/5.0/6.0 V → retained ID 168/186/227/318/524/2060 nA/µm —
**6 distinguishable monotonic levels, ~12× range** at the calibrated point. For a
clean ≥9-level M4 demo, run an H1-style fine V_pgm sweep (≈0.25 V steps over
3.0–5.5 V, fresh device per node) OR an accumulating ladder with a **non-disturbing
read (V_GS_read = 0 V)** to stop the read-bias depolarisation. The latter is the
recommended single-shot analog demo for the calibrated device.

## Conclusions (this session)

1. **Operating point re-derived, not just re-run.** The calibrated stronger FE
   (P_r 16→32, F_c 1.2→1.4) + interface charge moved the LIF/analog window up
   ~2 V. Old V_pgm = 2.0 V is sub-coercive/dead; **new LIF operating point
   V_pgm = 4.0 V** (|E|/F_c = 0.84, fire_ratio 2.59).
2. **M7 (V_pgm ≤ 2.0 V) now fails** — honest energy cost of the realistic FE; feeds
   the H5 energy re-accounting.
3. **Clean LIF integration figure** (`h1_staircase.png`) and a 6-level analog family
   (H1) are publication-ready at the calibrated point.
4. Infrastructure (app par + n2 mesh + calibrated interface physics) validated
   across 12 clean sdevice runs; harness ready for H2–H11 re-runs.

## Remaining H-experiments — recipe (same 3 swaps as H1/H12), run at V_pgm = 4.0 V

Each prior `Simulations/simH_optimize/sdevice_simH*.cmd` becomes a calibrated app
run by: (1) `Parameter → sdevice_gaafet_app.par`; (2) interface Traps block →
`FixedCharge 7e12 + Dit acceptor 4e12 @0.45`; (3) `@tdr@ → n2_msh.tdr`. Read
protocol (V_DS=0.05, V_GS_read=−0.5) is already in those cmds. Drive via the
non-SWB csh-driver pattern (`autocal/runs/run_h1app_sweep.csh`), single license,
sequential.

| H | cmd | analyzer | gate |
|---|---|---|---|
| H1 V_pgm sweep | h1app_template.cmd | analyze_phase1d_h1_app.py | M2, M7 (this session) |
| H12 analog states | runs/h12app_des.cmd | analyze_phase1d_h12.py (repoint) | M4 (this session, queued) |
| H2 MW(V_pgm) | sdevice_simH2_PE_loop.cmd | analyze_phase1d_h2.py | M3 |
| H3 cyclic/erase | sdevice_simH3_cyclic.cmd | analyze_phase1d_cyclic.py | M1, M-rest |
| H4 endurance | sdevice_simH4_endurance.cmd (gen %.6e) | analyze_phase1d_h4.py | M1, M8 (expensive) |
| H5 energy | (no sim; on H4 outputs) | analyze_phase1d_h5.py | M5, M6 |
| H9 burst length | sdevice_simH9_burst_N{5..9}.cmd | analyze_phase1d_h9.py | M2 vs energy |
| H10 retention | sdevice_simH10_retention.cmd | analyze_phase1d_h10.py | (model-limited) |
| H11 temperature | sdevice_simH11_T{250,300,350}K.cmd | analyze_phase1d_h11.py | M2 window |
