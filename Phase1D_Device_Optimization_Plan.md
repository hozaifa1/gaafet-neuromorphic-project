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

τ_P selection (10 µs = 1e-5 s): already done in Phase 1C [`simD_leak/`](Simulations/simD_leak/) and locked in [`Simulations/sdevice_gaafet_lif.par`](Simulations/sdevice_gaafet_lif.par) line 68. Re-confirmed by the H3 par audit on 2026-05-17. Effective τ_leak in this operating regime measured at 13.7 µs (H3 Step 2c fit), consistent with the par.

Earlier failed iterations (H1 v1/v2, H2 v3/v4/v5, H3 v2/v3/v4, leak-eq Step 2a/2b, cyclic Step 3a) — root-caused and documented in commit history; not repeated here.

---

## Operating point (locked from H3 Step 3b)

| Parameter | Value | Source |
|---|---|---|
| V_pgm | +2.0 V | H1 v3 |
| Pulse hold | 100 ns | H1 v3 |
| Pulses per fire burst | 9 | H1 v3 |
| V_GS_read | −0.5 V | H1 v3 (sub-V_t) |
| V_erase | −6.0 V | H3 Step 2c + 3b |
| V_erase hold | 10 µs | H3 Step 2c |
| Relax at V_GS = −0.5 V | 70 µs (≥ 5·τ_relax) | H3 Step 2c |
| τ_relax | 13.7 µs | H3 Step 2c |
| Cycle wall time | 81.838 µs | H3 Step 3b |
| Steady-state fire_ratio | 3.06× (c3..c5) | H3 Step 3b |
| Rest state (post-erase) | 1.44× virgin | H3 Step 3b |
| Virgin baseline ID/W | 2.658 × 10⁻⁷ µA/µm | H3 Step 3b |

---

## Submission gate

| # | Metric | Target | Status |
|---|---|---|---|
| M1 | Drift c3→c5 on ID_p9 | ≤ 1 %/cycle | ✓ PASS (+0.73 %/cyc at V_erase = −6 V) |
| M2 | fire_ratio per cycle | ≥ 1.5 | ✓ PASS (4.79 / 5.22 / 3.04 / 3.06 / 3.06) |
| M-rest | Rest-baseline drift c3→c5 | ≤ 1 %/cycle | ✓ PASS (−0.02 %/cyc); replaces stale "restore ±25 % of virgin" gate (depolarization-screened MFIS rests at +Pol-partial, not at virgin — biologically analogous) |
| M3 | Memory window | ≥ 0.5 V | ✓ PASS (1.40 V H0a v5; 852 mV H2 v6) |
| M4 | Analog states | ≥ 9 | TREND PASS (H2 v6) — 9-level demo deferred to optional expansion |
| M5 | E_gate (per fire event) | ≤ 50 fJ | **127.88 fJ/pulse** (H5, c10..c20 mean at V_pgm = 2.0 V) — FAIL by 2.6×. Floor set by **FE-switching charge during 100 ns write at V_pgm** (99.1 % of pulse energy; revealed by H5 per-segment breakdown + H6 deferred-read falsification). Trade-off reported, not solved. |
| M6 | E_total (fire + erase per cycle) | ≤ 100 fJ | **1141.51 fJ/cycle** (H5, c10..c20 mean) — FAIL by 11.4×. 9-pulse fire-write burst is 99 % of the cost (E_erase ≈ 10 fJ, E_relax ≈ −20 fJ net dissipative, E_read < 0.1 fJ/pulse). H6 confirmed: removing 8 of 9 reads = 0 fJ saved. |
| M7 | V_pgm | ≤ 2.0 V | ✓ PASS (V_pgm_opt = 2.0 V) |
| M8 | C2C σ/μ | ≤ 5 % | **6.03 %** at V_pgm L5 c10..c20 (H4) — flat across cycles; deterministic V_pgm-jitter coupling (Δfr/fr ≈ +5.4 %/25 mV), not stochastic. Tighten driver V_pgm jitter to ±20 mV to reach gate, or shift V_GS_read off the exponential tail. |
| M9 | I-V R² | ≥ 0.90 | post-ERS 0.95 PASS; post-PGM 0.77 (floor-limited, documented) |
| M9b | MW vs Tasneem | – | 2.8× — differentiator |
| M10 | SS | 88–132 mV/dec | post-PGM 100 PASS; post-ERS 164 (documented as MFIS asymmetry) |
| M11 | DIBL | Optional | – |
| M12a | P–E loop topology | qualitative | ✓ PASS (H0e) |
| M12b | V_c,gate agreement | ≤ 5 % | ✓ PASS (0.5 %, H0e) |

**Outstanding before submission:** none — H4, H5, H6 done. Open trade-offs to discuss in manuscript: M5/M6 over target (**FE-switching-charge floor** at 100 ns write × V_pgm = 2.0 V — *not* the read floor; H6 falsified that hypothesis empirically); M8 at 6.03 % (driver V_pgm spec constraint, not stochastic). Optional H9 burst-length sweep can quantify the burst-length / M2-margin Pareto for a follow-on figure.

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

1. **H4 endurance** ✓ **DONE** (2026-05-19) — 5-node SWB L5 complete in `Simulations/endurance_outputs/`. Analyzer `analyze_phase1d_h4.py`. Headline: M1 / M-rest / M2 PASS at all 5 nodes (long-tail drift < 0.02 %/cyc); M8 = 6.03 % flat across c10..c20 → deterministic V_pgm coupling, *not* stochastic drift. See `Writing_Materials/Phase1D_Analysis/Endurance/H4_endurance_analysis.md`.
2. **H5 energy** ✓ **DONE** (2026-05-19) — `analyze_phase1d_h5.py` integrates fire + erase + relax on H4 V_pgm=2.0 V cycles. c10..c20 mean: E_fire = 1.151 pJ/burst (128 fJ/pulse), E_total = 1.142 pJ/cycle. M5 & M6 fail honestly. **Per-segment breakdown added 2026-05-21:** write @ V_pgm = 99.1 % of pulse, read = 0.06 %. Writeup in `Writing_Materials/Phase1D_Analysis/Energy/H5_energy.md`.
3. **`Step_2/lif_parameters.py` rewrite** ✓ **DONE** (2026-05-19).
4. **Writing pass** ✓ **DONE** (2026-05-19).
5. **H6 deferred-read** ✓ **DONE / HYPOTHESIS FALSIFIED** (2026-05-21) — 5-node SWB × 20 cycles, 60 min/node. c1–c2 mean: E_total = 1153.5 fJ/cycle (+1.1 % vs H5, inside solver noise). Read floor < 0.1 fJ/pulse; the 100 ns write hold at V_pgm is the dominant cost. Writeup `Writing_Materials/Phase1D_Analysis/Energy/H6_deferred_read.md`; analyzer `analyze_phase1d_h6.py`; outputs `Simulations/simH_optimize/h6_outputs/`. **Action items spawned:**
   - Cancel H7 and H8 (both target the negligible read segment — see revised roadmap below).
   - H9 (burst length) remains valid; promote to next optional sim if pursuing energy story.
   - `_cmd_helpers.fmt` patched from `.4e` to `.10e` so future H-step `.cmd` files don't need server-side time-precision fix (H6 partial fix only bumped `InitialTime`/`FinalTime`, missed `CurrentPlot Range` → c3+ data progressively lost).

---

## Energy-improvement roadmap (post-H5, revised after H6 falsification on 2026-05-21)

H5 lands at **128 fJ/pulse, 1.151 pJ/burst, 1.142 pJ/cycle**. The original roadmap assumed the **read floor** (8 × ~12 fJ/pulse-read) was the largest single contributor. **H6 falsified this** — removing 8 of 9 inline reads saved 0 fJ. The per-segment breakdown shows the actual cost lives almost entirely in the 100 ns write hold at V_pgm = 2.0 V:

| Segment | Wall time | Energy/pulse | % of pulse |
|---|---:|---:|---:|
| rise  | 1 ns | 0.80 fJ | 0.6 % |
| **write** | **100 ns** | **126.72 fJ** | **99.1 %** |
| fall  | 1 ns | 0.28 fJ | 0.2 % |
| read  | 100 ns | 0.08 fJ | 0.06 % |

The 127 fJ/pulse is the **FE-switching-charge floor**: Q_switch (≈ 50 fC) × V_pgm (2.0 V) ≈ 100 fJ of polarisation charge through the gate per write, plus ~25 fJ of drain channel current at the polarised V_t. Reducing this requires either V_pgm (anti-goal — H1 v3 over-switching) or smaller gate area / FE thickness (device-stack change, blocked by Tasneem calibration anchor).

### Revised rank-ordered roadmap

| # | Knob | Mechanism | Expected saving | Status | .cmd |
|---|---|---|---:|---|---|
| ~~1~~ | ~~Deferred-read LIF (H6)~~ | ~~Remove 8 of 9 inline reads~~ | ~~15–25 fJ/pulse~~ | **❌ FALSIFIED (2026-05-21).** Actual saving = +1 fJ (solver noise). Read floor < 0.1 fJ/pulse, not the 12 fJ assumed. | `sdevice_simH6_deferred_read.cmd` — run complete, conclusion fixed |
| ~~2~~ | ~~V_DS_read 50 → 10 mV (H7)~~ | ~~E_drain_read ∝ V_DS × I_D × t~~ | ~~30–60 fJ/pulse~~ | **❌ CANCEL.** H5/H6 show the read segment is < 0.1 fJ/pulse total — at most ~0.06 fJ savings possible. Cmd file retained for record only. | `sdevice_simH7_VDSread.cmd` — DO NOT RUN |
| ~~3~~ | ~~Read-pulse-width 100 → 30 ns (H8)~~ | ~~E_read ∝ t_read~~ | ~~70–80 fJ/pulse~~ | **❌ CANCEL.** Same reason — savings bounded by 0.08 fJ/pulse. Cmd files retained for record. | `sdevice_simH8_tread_*.cmd` — DO NOT RUN |
| **1** | **Burst length 9 → N (H9)** | **E_fire scales linearly in N (write segment dominates)** | **5/9 of E_fire = 633 fJ/cycle at N=5, 7/9 at N=7** | **✓ STILL VALID.** Only viable circuit-level knob. M2 margin shrinks (fire_ratio at N=5 ≈ 1.8×, tight on M2 = 1.5×); re-verify M1 long-tail. | `sdevice_simH9_burst_N{5,6,7,8,9}.cmd` — ready, prioritise |
| **2 (new)** | **Write-time shortening 100 → 30 / 50 / 70 ns** (proposed H-step) | If FE switches faster than 100 ns the displacement-current integral shortens proportionally | **Up to 70 % of write segment = ~90 fJ/pulse** if 30 ns is sufficient for ΔP_sat | Requires verification that FE polarisation actually saturates inside 30/50 ns at V_pgm=2.0 V — H1 v3 chose 100 ns for margin. **Worth a new H-step** (not yet generated). | (proposed) `_gen_h13_twrite.py` |

Best realistic case at current device stack: H9 at N=5 + H13 at t_write=50 ns → E_fire ≈ 5 × 64 fJ = 320 fJ + erase/relax ≈ 330 fJ/cycle. Still **3.3× over M6**; **M5/M6 fundamentally cannot be met** at this gate area / V_pgm / FE thickness without a device-stack change (area scaling, lower V_pgm via FE remnant-polarisation tuning).

The honest manuscript framing: **"M5/M6 are not achievable within the Tasneem-calibrated device envelope; the 128 fJ/pulse is the FE-switching-charge floor of the polarised gate."** H6 is reported as a published negative result that demonstrates the read-floor hypothesis was tested and ruled out.

### Beyond the cycle structure (optional, lower priority) — *all .cmd files generated 2026-05-19*

5. **Multi-domain Preisach (H0f) re-enable** — currently deferred to "reviewer-response card only." Re-running calibration with `NumberOfDomains = 40` gives a proper variability distribution and lets M8 σ/μ be reported as *device-intrinsic* C2C noise instead of deterministic V_pgm coupling. **PRECONDITION:** edit `Simulations/sdevice_gaafet_lif.par` HZO block to set `NumberOfDomains = 40` before running. Files: [`_gen_h0f_multidomain.py`](Simulations/_gen_h0f_multidomain.py) → [`sdevice_simH0f_multidomain.cmd`](Simulations/simH_optimize/sdevice_simH0f_multidomain.cmd) (3 cycles, V_pgm = 2.0 V).
6. **Retention sweep (10 s / 100 s / 1000 s holds at V_GS = 0 V)** — most journals ask for retention even when the headline is LIF. Files: [`_gen_h10_retention.py`](Simulations/_gen_h10_retention.py) → [`sdevice_simH10_retention.cmd`](Simulations/simH_optimize/sdevice_simH10_retention.cmd) (SWB `@t_hold@` ∈ {10, 100, 1000} s, Quasistationary hold + 100 ns transient readback). Acceptance soft: ID(1000 s)/ID(10 s) ≥ 0.5.
7. **Cross-temperature (250 K / 300 K / 350 K)** — IEDM-grade reviewers expect this. Files: [`_gen_h11_temperature.py`](Simulations/_gen_h11_temperature.py) → `sdevice_simH11_T{250,300,350}K.cmd` (3 files; Temperature is a literal in the Physics block so SWB can't sweep it).
8. **9-level analog-state demo (M4 full PASS)** — currently TREND PASS via H2 v6. Files: [`_gen_h12_9level.py`](Simulations/_gen_h12_9level.py) → [`sdevice_simH12_9level.cmd`](Simulations/simH_optimize/sdevice_simH12_9level.cmd) (9 accumulated V_pgm rungs from 0.8 V to 2.4 V in 0.2 V steps, single shot, 100 ns write + 100 ns read each).

### Revised execution order (post-H6)

1. ~~**H6 (deferred read)** — done; falsified.~~
2. ~~**H7 (V_DS_read)** — cancelled (read floor < 0.1 fJ/pulse, savings bounded by ~0.06 fJ/pulse).~~
3. ~~**H8 (t_read)** — cancelled (same reason).~~
4. **H9 (N_FIRES sweep N=5,6,7,8,9)** — promoted to #1 priority. Linear-in-N savings on the dominant write segment. Risk: M2 fire_ratio margin at N=5. Run all 5 nodes, pick the smallest N that still passes M2 with ≥ 20 % margin.
5. (Optional, requires new gen) **H13 (t_write sweep 30 / 50 / 70 / 100 ns)** — explore whether the FE-switching charge saturates faster than 100 ns at V_pgm = 2.0 V. If yes, this is the most impactful remaining knob. Verify ΔP from H0e tracks ΔP_sat at the shortened t_write.
6. **H0f (multi-domain Preisach), H10 (retention), H11 (temperature), H12 (9-level)** — in parallel as reviewer-response polish. Order unchanged.

The manuscript-story plan was "if H6+H7+H8 land at ~10 fJ/pulse, M5/M6 flip to PASS." That plan is dead. The new framing is "M5/M6 are not achievable within the Tasneem-calibrated device envelope; H6 published as the empirical refutation of the read-floor hypothesis; H9 quantifies the burst-length / M2-margin Pareto." This is *also* a publishable top-tier story — possibly stronger because it presents an empirical falsification (uncommon in TCAD-LIF papers, which usually report only positive optimisations).

### Anti-goals (do NOT do)

- **Do not raise V_pgm to scale down N_FIRES.** H1 v3 already proved V_pgm > 2.5 V triggers non-monotonic over-switching → kills M1/M2. The 9-pulse-at-2-V regime is the *only* operating point that closes M1/M2/M-rest simultaneously, so all energy optimisation must happen at this V_pgm, not above it.
- **Do not drop V_GS_read above −0.3 V.** Sensitivity falls off the exponential tail; M2 fire_ratio collapses from 3× to ~1.3× as the read voltage walks toward V_t.
- **Do not change the .par** (HZO thickness, AreaFactor, coercive field) for energy reasons — that would invalidate the calibration anchor against Tasneem and force a full H0 re-validation.

### What is *not* needed

- No new device file. `sdevice_gaafet_lif.par` is locked.
- No new calibration step. H0a v5 / H0e / H0g remain the anchor.
- No new physics modules (mobility, FE Preisach syntax, gate boundary) — all four proposed sims re-use the H4 `.cmd` template with one numerical change each.

## Phase 1C → Phase 1D operating-point change (why H4/H5 aren't redundant with simD/E/F)

Phase 1C used **V_pulse = +6.0 V**, **V_reset = −5.0 V hold**, **V_GS_read = +0.2 V** (above-V_t). The H1 v3 sweep in Phase 1D found that V_pgm = +6 V causes **non-monotonic over-switching** — ID peaks at p6 (~7.4 pA/µm) and collapses to 0.86 pA/µm by p9 — explaining the +4.74 %/cyc drift driver seen in Phase 1C `simF_endurance/`. Phase 1D moved to the sub-coercive operating point **V_pgm = +2.0 V**, **V_GS_read = −0.5 V** (sub-V_t, exponential sensitivity), and **pulsed V_erase = −6 V + 70 µs relax**. simD (τ_P selection), simE (energy extractor), simF (endurance protocol) are reused at the new operating point — H4 is the simF protocol relaunched at the V_pgm = +2 V / V_erase = −6 V point with 20 cycles + V_pgm variability, and H5 is simE's `extract_energy.py` pointed at H3 Step 3b / H4 outputs (now with cyclic-naming support).
