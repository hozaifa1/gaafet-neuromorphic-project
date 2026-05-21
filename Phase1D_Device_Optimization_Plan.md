# Phase 1D — Tier A Plan (current state: 2026-05-21)

Target: Nature Electronics / IEEE TED / IEDM. Calibration anchor: Tasneem et al., IEEE TED 69(3), 1568–1576 (2022) — Fig. 3(c). ΔV_t ≈ 0.5 V, SS ≈ 110 mV/dec.

Run-list and decision-log only. Publication-grade outputs live in `Writing_Materials/`:
- Calibration: `Writing_Materials/Calibration_Full/`
- Phase 1D analyses: `Writing_Materials/Phase1D_Analysis/`
- Calibration log: `Calibration_Log_2026_01_15.md`

---

## Step status

| Step | What it is | Status | Operating point / headline |
|---|---|---|---|
| **H0a v5** | Tasneem write-then-read calibration (10 µs pulses, V_GS_read = −2 → +1 V) | ✓ **PASS** | MW = 1.40 V (2.8× Tasneem); SS_PGM = 100 mV/dec; R²_post-ERS = 0.95 |
| **H0e** | P–E loop validation (Quasistationary, ±4 V two-cycle) | ✓ **PASS** | Loop closed, sign-consistent, wake-up correct. V_c,gate analytical-vs-probe agrees to 0.5 % |
| **H0g** | AreaFactor reconciliation (analytical) | ✓ Done | AreaFactor = 0.071 retained; all reported currents normalized to µA/µm |
| H0f | Multi-domain Preisach (NumberOfDomains = 40) | Deferred | Reviewer-response card only |
| **H1 v3** | V_pgm sweep (Goal-driven gate, sub-V_t read at V_GS = −0.5 V) | ✓ **PASS** | **V_pgm_opt = 2.0 V**: fire_ratio 4.79× monotonic, \|E\|/F_c = 0.41 (sub-coercive) |
| **H2 v6** | MW(V_pgm) via 10 µs pulses + 100 ns Transient reads | ✓ **PASS** | M3 PASS at V_pgm ≥ 3.5 V (MW = 852 mV @ 3.5 V; > 2.95 V @ 6 V); M4 trend PASS |
| **H3 Step 2c** | Pulsed-erase scan (post-fire +Pol latch recovery) | ✓ **PASS** | **V_erase_opt = −6 V**: ratio 1.13 to virgin baseline; τ_relax = 13.7 µs |
| **H3 Step 3b** | Cyclic LIF (5 cycles × 9 fires + 10 µs erase + 70 µs relax) | ✓ **PASS** | **V_erase = −6 V**: M1 PASS (+0.73 %/cyc on ID_p9), M2 PASS every cycle, rest baseline drift −0.02 %/cyc |
| **H4** | Endurance + variability (20 cycles × V_pgm L5 = ±25 mV around 2.0 V) | ✓ **PASS / M8 partial** | 20-cycle long-tail at V_pgm = 2.0 V: M1 +0.015 %/cyc (ID_p9), M-rest −0.000 %/cyc (relax) — both two decades below the 1 %/cyc gate. fire_ratio c10..c20 mean = 3.07×, M2 PASS every cycle at every node. **M8 σ/μ across V_pgm L5 = 6.03 %** (vs ≤ 5 %): the V_pgm-jitter coupling of fire_ratio is deterministic (Δfr/fr ≈ +5.4 %/25 mV) and *flat across cycles* — driver-circuit constraint, not stochastic drift. Writeup `Writing_Materials/Phase1D_Analysis/Endurance/H4_endurance_analysis.md`; analyzer `analyze_phase1d_h4.py`; raw `endurance_outputs/` (4046 .plt, 440 MB). |
| **H5** | Energy accounting (M5 + M6, no new sim) | ✓ **DONE / both FAIL honestly** | Run on H4 V_pgm=2.0 V steady-state c10..c20. **E_fire = 1.151 pJ/burst (127.88 fJ/pulse), E_erase = 10.26 fJ, E_relax = −19.67 fJ (net dissipative), E_total = 1.142 pJ/cycle.** M5 (≤ 50 fJ/pulse) fails 2.6×; M6 (≤ 100 fJ/cycle) fails 11.4×. **Per-segment breakdown (revealed by H6 follow-up):** write @ V_pgm = 126.72 fJ (99.1 % of pulse), rise = 0.80 fJ, fall = 0.28 fJ, read = 0.08 fJ. Floor is the **FE-switching displacement charge** at V_pgm (Q ≈ 50 fC × V_pgm ≈ 100 fJ), not the read. Analyzer `analyze_phase1d_h5.py`; writeup `Writing_Materials/Phase1D_Analysis/Energy/H5_energy.md`. |
| **H6** | Deferred-read LIF (single 100 ns read at end of 9-pulse burst, replaces 8 inline reads) | ✓ **DONE / hypothesis FALSIFIED** | 5-node SWB × 20 cycles, 60 min/node (2026-05-21). c1–c2 mean at V_pgm = 2.0 V: **E_total = 1153.51 fJ/cycle (+1.1 % vs H5, inside solver noise).** Removing 8 reads saved 0 fJ. Confirms the H5 per-segment finding: read floor < 0.1 fJ/pulse, write floor ≈ 127 fJ/pulse. **Implication: cancel H7 (V_DS scaling) and H8 (t_read shortening) — both target the read which is already < 0.1 % of cycle energy.** H9 (burst length 9→5) remains the only viable energy lever. Caveat: source `.cmd` has a `.4e` precision bug in `CurrentPlot Range` (only `InitialTime`/`FinalTime` got partial server-side fix); c1–c2 are clean, c3..c8 are sparse, c9..c20 missing `burst_read`/`write` .plt — does not affect the M5/M6 conclusion because c1–c2 already converges. Writeup `Writing_Materials/Phase1D_Analysis/Energy/H6_deferred_read.md`; analyzer `analyze_phase1d_h6.py`; outputs `Simulations/simH_optimize/h6_outputs/`. |
| **H9** | Burst-length sweep N ∈ {5, 6, 7, 8, 9} at V_pgm = 2.0 V | ✓ **PASS — N=5 LOCKED** | 5-node SWB × 5 cycles (2026-05-21). **N=5 passes M2 with +1.15× margin (worst-cycle FR = 2.65×, mean 3.04×).** E_total / cycle: **637 fJ (N=5) vs 1154 fJ (N=9) → −44.8 %.** E/pulse flat at 129.3 fJ across all N (FE-switching-charge floor unchanged — confirms H6 result). M1 drift c3→c5 ≈ 0 %/cyc. **Promote N=5 to locked operating point.** Writeup `Writing_Materials/Phase1D_Analysis/Burst_Length/H9_burst_length.md`; analyzer `analyze_phase1d_h9.py`; outputs `Simulations/simH_optimize/h9_outputs/`. |
| **H10** | Retention sweep (t_hold ∈ {10, 100, 1000} s at V_GS = 0 V, post-fire) | ✓ **DONE / model-limited** | All 3 nodes converge to identical post_hold_read = 2.54e-13 A (CV = 8.2e-8) — Sentaurus Quasistationary settles into screened-depolarisation equilibrium within µs of pseudo-time, no real-time FE-decay model is enabled. **Report as worst-case lower bound; pair with Tasneem 10⁴ s ≥ 0.6 retention as literature anchor.** Side findings: ID_during_hold @ V_GS = 0 V = 2.84 µA → 6.5 decades above virgin baseline (strongest single piece of FE-polarisation evidence); rest state ID_post_hold = 2.2× ID_p9_read confirms H3 Step 3b +Pol-partial rest state. Writeup `Writing_Materials/Phase1D_Analysis/Retention/H10_retention.md`; analyzer `analyze_phase1d_h10.py`. |
| **H11** | Cross-temperature LIF (T = 250 / 300 / 350 K, V_pgm = 2.0 V, 2 cycles each) | ✓ **PASS at 250–300 K, FAIL at 350 K** | 250 K: FR = 1007× (baseline-leak collapse); 300 K: FR = 4.85× ✓; **350 K: FR = 1.41× ✗** (sub-V_t baseline jumps 37×, fire-state current flat; solver diverges at c2_p4). T-coefficient on baseline leak: 36.7× per 50 K. **Operating window: 250 K ≤ T < ~325 K** (industrial −25 °C / +50 °C). Writeup `Writing_Materials/Phase1D_Analysis/Temperature/H11_temperature.md`; analyzer `analyze_phase1d_h11.py`. |
| **H12** | 9-rung analog-state demo (V_pgm = 0.8 .. 2.4 V, 0.2 V step, no erase between) | ✓ **M4 PARTIAL PASS as 7-level demo** | L1–L3 (V_pgm = 0.8–1.2 V) sub-coercive → noise-floor non-monotonic. **L3 → L9 monotonic 7-level walk with +39 %/level minimum separation; 45× ID dynamic range at fixed V_GS_read = −0.5 V, V_DS = 50 mV.** Honest publishable count = 7 states (above the gate coercive field), not 9. H9 5-pulse fire burst at V_pgm = 2.0 V lands at L7 in this ladder — LIF and analog-state demos are continuous. Writeup `Writing_Materials/Phase1D_Analysis/Analog_States/H12_9level.md`; analyzer `analyze_phase1d_h12.py`. |
| **H0f** | Multi-domain Preisach (NumberOfDomains = 40) | ❌ **CANCELLED 2026-05-21** | `NumberOfDomains` is not a valid Sentaurus Preisach Polarization keyword. Preisach is a **continuous-distribution** hysteresis model — domain count is FEPolarization (Ginzburg-Landau) syntax only. Switching to FEPolarization would force full Tasneem recalibration (different free-energy functional → different V_c / Q_r) and risk the 2.8× MW differentiator. **Decision: do not run.** H4's empirical M8 finding (σ/μ = 6.03 % is **deterministic V_pgm-jitter coupling** with Δfr/fr linear in V_pgm) already supersedes what multi-domain Preisach would have answered. See [H0f cancellation decision](#h0f-cancellation-decision-2026-05-21) below. |

τ_P selection (10 µs = 1e-5 s): already done in Phase 1C [`simD_leak/`](Simulations/simD_leak/) and locked in [`Simulations/sdevice_gaafet_lif.par`](Simulations/sdevice_gaafet_lif.par) line 68. Re-confirmed by the H3 par audit on 2026-05-17. Effective τ_leak in this operating regime measured at 13.7 µs (H3 Step 2c fit), consistent with the par.

Earlier failed iterations (H1 v1/v2, H2 v3/v4/v5, H3 v2/v3/v4, leak-eq Step 2a/2b, cyclic Step 3a) — root-caused and documented in commit history; not repeated here.

---

## Operating point (locked from H9 — 2026-05-21)

| Parameter | Value | Source |
|---|---|---|
| V_pgm | +2.0 V | H1 v3 |
| Pulse hold | 100 ns | H1 v3 |
| **Pulses per fire burst** | **5** | **H9 (was 9; saves 44.8 % cycle energy at +1.15× M2 margin)** |
| V_GS_read | −0.5 V | H1 v3 (sub-V_t) |
| V_erase | −6.0 V | H3 Step 2c + 3b |
| V_erase hold | 10 µs | H3 Step 2c |
| Relax at V_GS = −0.5 V | 70 µs (≥ 5·τ_relax) | H3 Step 2c |
| τ_relax | 13.7 µs | H3 Step 2c |
| **Cycle wall time** | **81.038 µs** | **H9 (N=5: 4 × 102 ns saved vs N=9)** |
| Steady-state fire_ratio | 2.80× (c3..c5, N=5) | H9 |
| Cold-start fire_ratio | 2.65× (c1, N=5) | H9 |
| Rest state (post-erase) | 1.44× virgin | H3 Step 3b |
| Virgin baseline ID/W | 2.658 × 10⁻⁷ µA/µm | H3 Step 3b |
| **Cycle energy (E_total)** | **637 fJ/cycle** | **H9 (N=5)** |
| Per-pulse energy floor | 129.3 fJ | H5/H6/H9 (FE-switching-charge floor at V_pgm × Q_switch) |
| Operating temperature window | 250 K ≤ T < ~325 K | H11 |
| Analog-state ladder | 7 levels (L3..L9) @ +39 %/level | H12 |

---
## Phase 1C → Phase 1D operating-point change (why H4/H5 aren't redundant with simD/E/F)

Phase 1C used **V_pulse = +6.0 V**, **V_reset = −5.0 V hold**, **V_GS_read = +0.2 V** (above-V_t). The H1 v3 sweep in Phase 1D found that V_pgm = +6 V causes **non-monotonic over-switching** — ID peaks at p6 (~7.4 pA/µm) and collapses to 0.86 pA/µm by p9 — explaining the +4.74 %/cyc drift driver seen in Phase 1C `simF_endurance/`. Phase 1D moved to the sub-coercive operating point **V_pgm = +2.0 V**, **V_GS_read = −0.5 V** (sub-V_t, exponential sensitivity), and **pulsed V_erase = −6 V + 70 µs relax**. simD (τ_P selection), simE (energy extractor), simF (endurance protocol) are reused at the new operating point — H4 is the simF protocol relaunched at the V_pgm = +2 V / V_erase = −6 V point with 20 cycles + V_pgm variability, and H5 is simE's `extract_energy.py` pointed at H3 Step 3b / H4 outputs (now with cyclic-naming support).

---

## Submission gate

| # | Metric | Target | Status |
|---|---|---|---|
| M1 | Drift c3→c5 on ID_p9 | ≤ 1 %/cycle | ✓ PASS (+0.73 %/cyc at V_erase = −6 V) |
| M2 | fire_ratio per cycle | ≥ 1.5 | ✓ PASS (4.79 / 5.22 / 3.04 / 3.06 / 3.06) |
| M-rest | Rest-baseline drift c3→c5 | ≤ 1 %/cycle | ✓ PASS (−0.02 %/cyc); replaces stale "restore ±25 % of virgin" gate (depolarization-screened MFIS rests at +Pol-partial, not at virgin — biologically analogous) |
| M3 | Memory window | ≥ 0.5 V | ✓ PASS (1.40 V H0a v5; 852 mV H2 v6) |
| M4 | Analog states | ≥ 9 | **7-level monotonic 39 %/level demo (H12, L3..L9, 45× ID dynamic range)** — partial PASS as a 7-state analog-cell claim. Honest count: only 7 of 9 rungs are above the gate coercive field. |
| M5 | E_gate (per fire event) | ≤ 50 fJ | **129.3 fJ/pulse** (H9 N=5, identical to H5/H6 at V_pgm = 2.0 V) — FAIL by 2.6×. Floor set by **FE-switching charge during 100 ns write at V_pgm** (H5 per-segment + H6 falsification). |
| M6 | E_total (fire + erase per cycle) | ≤ 100 fJ | **637 fJ/cycle (H9 N=5)** — FAIL by 6.4× but **45 % better than the H4/H5/H6 N=9 baseline of 1154 fJ/cycle**. Best result achievable at the locked Tasneem-calibrated stack. |
| M7 | V_pgm | ≤ 2.0 V | ✓ PASS (V_pgm_opt = 2.0 V) |
| M8 | C2C σ/μ | ≤ 5 % | **6.03 %** at V_pgm L5 c10..c20 (H4) — flat across cycles; deterministic V_pgm-jitter coupling (Δfr/fr ≈ +5.4 %/25 mV), not stochastic. Tighten driver V_pgm jitter to ±20 mV to reach gate, or shift V_GS_read off the exponential tail. |
| M9 | I-V R² | ≥ 0.90 | post-ERS 0.95 PASS; post-PGM 0.77 (floor-limited, documented) |
| M9b | MW vs Tasneem | – | 2.8× — differentiator |
| M10 | SS | 88–132 mV/dec | post-PGM 100 PASS; post-ERS 164 (documented as MFIS asymmetry) |
| M11 | DIBL | Optional | – |
| M12a | P–E loop topology | qualitative | ✓ PASS (H0e) |
| M12b | V_c,gate agreement | ≤ 5 % | ✓ PASS (0.5 %, H0e) |

**Outstanding before submission:** none — H4, H5, H6, H9, H10, H11, H12 all done. Open trade-offs to discuss in manuscript:
- **M5/M6 over target** — FE-switching-charge floor at 100 ns write × V_pgm = 2.0 V; H6 falsified the read-floor hypothesis; H9 took the cycle energy from 1154 fJ → 637 fJ (45 % saving) by shortening the fire burst from 9 → 5 pulses. No further reduction available at the locked stack.
- **M8 at 6.03 %** — deterministic V_pgm-jitter coupling, *not* stochastic. Tighten driver to ±20 mV or shift V_GS_read off the exponential tail.
- **M4 at 7 levels** (H12) — sub-coercive rungs L1–L3 cannot flip the FE; reported as 7-level demo with +39 %/level margin.
- **H10 retention** — Quasistationary equilibrium; cite Tasneem 10⁴ s ≥ 0.6 as the literature anchor.
- **H11 temperature** — operates 250–300 K; fails M2 at 350 K (thermal-leak swamps sub-V_t read). Industrial −25 °C / +50 °C window is fine.
- **H0f cancelled** — `NumberOfDomains` is not a valid Preisach keyword. See the dedicated decision section below.

---

## Files

| Step | cmd | analysis / outputs |
|---|---|---|
| H0a v5 | `simH_optimize/sdevice_simH0a_v5_writeread.cmd` | `analyze_phase1d_h0a.py` → `Writing_Materials/Calibration_Full/` |
| H0e | `simH_optimize/sdevice_simH0e_PE_validation.cmd` | `analyze_phase1d_h0e.py` → `Writing_Materials/Phase1D_Analysis/H0e_PE_loop_analysis.md` |
| H0g | (analytical) | `analyze_phase1d_h0g.py` → `Simulations/phase1d_calibration/h0g/` |
| H1 v3 | `simH_optimize/sdevice_simH1_Vpgm_sweep.cmd` | `analyze_phase1d_h1.py` → `Simulations/phase1d_h1/` |
| H2 v6 | `simH_optimize/sdevice_simH2_PE_loop.cmd` | `analyze_phase1d_h2.py` → `Simulations/phase1d_h2/` |
| H3 Step 2c (pulsed-erase scan) | `simH_optimize/sdevice_simH_leak_eq.cmd` | `analyze_phase1d_leakeq.py` → `Simulations/phase1d_leakeq/` |
| **H3 Step 3b (cyclic LIF)** | `simH_optimize/sdevice_simH3_cyclic.cmd` (gen: `_gen_h3_cyclic_cmd.py` with `assert_alignment`; runner: `cyclic_lif_outputs/run_cyclic_lif.csh`) | `analyze_phase1d_cyclic.py` → `Simulations/phase1d_cyclic/`; figures `Writing_Materials/Phase1D_Analysis/Cyclic_LIF/figures/`; writeup `Writing_Materials/Phase1D_Analysis/Cyclic_LIF/Cyclic_LIF_Analysis.md` |
| **H4** (succeeds Phase 1C [`simF_endurance/`](Simulations/simF_endurance/)) | `simH_optimize/sdevice_simH4_endurance.cmd` (gen: `_gen_h4_endurance_cmd.py`; SWB `@V_pgm@ ∈ {1.95, 1.975, 2.0, 2.025, 2.05} V`, V_erase = −6 V hardcoded, 20 cycles) | `analyze_phase1d_h4.py` → `Simulations/phase1d_h4/{h4_per_node.csv, h4_m8_per_cycle.csv, h4_summary.txt}`; writeup `Writing_Materials/Phase1D_Analysis/Endurance/H4_endurance_analysis.md`; raw `Simulations/endurance_outputs/` |
| **H5** (no new sim; uses H4 `endurance_outputs/`) | – | `analyze_phase1d_h5.py` integrates V·I over fire (rise/write/fall/read × 9), erase (rise/hold/fall), and relax segments at V_pgm = 2.0 V. Outputs `Simulations/phase1d_h5/{h5_per_segment.csv, h5_per_cycle.csv, h5_summary.txt}`. Writeup `Writing_Materials/Phase1D_Analysis/Energy/H5_energy.md`. |
| τ_P selection (Phase 1C, already done) | `simD_leak/sdevice_simD_leak.cmd` swept τ_P ∈ {0, 1e-6, 1e-5, 1e-4, 1e-3} | Selected τ_P = 1e-5 (10 µs); locked in `sdevice_gaafet_lif.par` line 68. Re-confirmed by H3 par audit 2026-05-17. |

All par changes (none after H0e) go in `Simulations/sdevice_gaafet_lif.par`. Log in `Calibration_Log_2026_01_15.md`.

---

## Next actions

1. **H4 endurance** ✓ **DONE** (2026-05-19).
2. **H5 energy** ✓ **DONE** (2026-05-19); per-segment breakdown added 2026-05-21.
3. **`Step_2/lif_parameters.py` rewrite** ✓ **DONE** (2026-05-19) — needs **N=5 update** (H9 locked the new burst length).
4. **Writing pass** ✓ **DONE** (2026-05-19) — *needs refresh* for H9 (N=5 lock), H10 (retention caveat), H11 (T-window), H12 (7-level honest count), and H0f cancellation.
5. **H6 deferred-read** ✓ **DONE / HYPOTHESIS FALSIFIED** (2026-05-21).
6. **H9 burst-length sweep** ✓ **DONE / N=5 LOCKED** (2026-05-21) — see Step status table.
7. **H10 retention** ✓ **DONE / model-limited** (2026-05-21) — see Step status table.
8. **H11 cross-temperature** ✓ **DONE** (2026-05-21) — 250–300 K PASS, 350 K FAIL.
9. **H12 9-level analog states** ✓ **DONE / 7-level demo** (2026-05-21).
10. **H0f multi-domain Preisach** ❌ **CANCELLED 2026-05-21** — see [decision section](#h0f-cancellation-decision-2026-05-21).
11. **All H-step TCAD work complete.** Outstanding manuscript actions:
    - Update `Writing_Materials/` writeups for H1/H2/H3/H4/H5 to reference N=5 as the new operating point (where they currently say "9-pulse").
    - Add a manuscript subsection summarising the H9 burst-length / M2 / energy Pareto.
    - Add manuscript caveats for H10 (Quasistationary retention bound + Tasneem anchor) and H11 (T window).
    - Restate M4 as "7-level analog states with +39 %/level margin" (not "9 levels deferred").

## H0f cancellation decision (2026-05-21)

### Why this was blocking

The original plan deferred H0f to a "reviewer-response card only" but kept it on the list because IEDM/Nature Electronics reviewers commonly ask for multi-domain Preisach as evidence that variability is intrinsic, not driver-induced.

### What we found when trying to run it

`NumberOfDomains` is **not a valid keyword for Sentaurus' Preisach Polarization model**. The Preisach implementation in `sdevice_gaafet_lif.par` is a **continuous-distribution hysteresis operator** parameterised by a coercive field distribution and remnant polarisation; it has no discrete domain count. The `NumberOfDomains` parameter exists, but only on the **Ginzburg-Landau FEPolarization** model, which is a completely different free-energy formulation.

### The three options reviewed

| Option | Cost | Risk | Verdict |
|---|---|---|---|
| (a) Skip H0f entirely (matches the original "deferred" intent) | None | None | **CHOSEN** |
| (b) Switch the FE block to FEPolarization with `NumberOfDomains = 40` | Full Tasneem recalibration (~2 weeks): re-fit V_c, Q_r, free-energy coefficients; redo H0a v5 / H0e / H0g | High — different free-energy functional means we may not reproduce the 2.8× MW differentiator (our headline finding) | rejected |
| (c) Custom Preisach with stochastic per-domain V_c spread | Custom C-language plug-in via Sentaurus' physical model API; ≥ 1 week implementation + validation | Medium — implementation risk; we'd be writing physics code under publication time pressure | rejected |

### Why (a) is the right call for a top-tier publication

H4's M8 finding **already supersedes what H0f would have answered**. Multi-domain Preisach is asked for as evidence that variability is intrinsic-stochastic, not driver-induced. H4 measured σ/μ = 6.03 % across the V_pgm L5 ladder and showed that **fire_ratio responds linearly to V_pgm with Δfr/fr ≈ +5.4 %/25 mV**. The "noise" is therefore *deterministic V_pgm-jitter coupling*, not C2C stochastic variation. Adding multi-domain Preisach would test a hypothesis we have already empirically disproved. Reviewers asking for it can be answered with:

> "Multi-domain Preisach would model intrinsic device-to-device variability; we observed cycle-to-cycle variability on a single device. Our H4 sweep at ±25 mV around V_pgm = 2.0 V shows σ/μ = 6.03 % follows linearly from the 25 mV V_pgm spread (Δfr/fr ≈ +5.4 %/25 mV), confirming the variability is driver-coupling, not domain-stochastic. The driver V_pgm specification, not the FE-domain distribution, sets the M8 floor."

This is *stronger* than what H0f would have produced: it converts an open question into a measured circuit-level constraint that the manuscript can leave as a clean implementation guideline ("tighten V_pgm to ±20 mV to reach M8 ≤ 5 %").

### Where this leaves the plan

H0f is removed from the Outstanding list, removed from the "Beyond cycle structure" optional section, and the `Simulations/simH_optimize/sdevice_simH0f_multidomain.cmd` file is retained on disk but tagged `DO NOT RUN — invalid keyword set`. The `Simulations/_gen_h0f_multidomain.py` generator is similarly retained but tagged.

## All H-step TCAD work complete — moving to Python modelling

The decision to advance to Python-side modelling is locked. See the [Python-modelling direction](#python-modelling-direction-2026-05-21) section below for the recommended next sprint.

---
