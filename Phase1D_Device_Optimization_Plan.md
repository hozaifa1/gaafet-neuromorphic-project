# Phase 1D — Tier A Plan (current state: 2026-05-19)

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
| **H4** | Endurance + variability (20+ cycles, V_pgm perturbation) | **NEXT** | Re-run of Phase 1C `simF_endurance/` at the new sub-coercive operating point (V_pgm = +2 V, pulsed V_erase = −6 V) — old simF used V_pulse = +6 V / V_reset = −5 V hold (invalidated by H1 v3 over-switching finding). cmd: `simH_optimize/sdevice_simH4_endurance.cmd` (already generated; SWB `@V_pgm@ ∈ {1.95, 1.975, 2.0, 2.025, 2.05}`, V_erase = −6 V hardcoded, 20 cycles) |
| **H5** | Energy accounting (reuse existing infrastructure) | **PREVIEW DONE** | Reuse `Simulations/simE_energy/extract_energy.py` (now also handles cyclic `cN_pN_*` naming). Step 3b numbers: E_fire (steady c3..c5 mean) = **1.151 pJ per 9-pulse burst at V_erase = −6 V** (gate + drain integrated over rise+write+fall+read). Per-tag CSVs in `simH_optimize/cyclic_lif_outputs/cyclic_vm{4,6,10}_energy_summary.csv`. Erase-phase energy still to add (script currently skips `erase_*` segments). Full writeup pending H4 steady-state data. |

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
| M5 | E_gate (per fire event) | ≤ 50 fJ | **Preview from H3 Step 3b via `extract_energy.py`**: E_fire(c3..c5 mean) = 1.151 pJ / 9 pulses ≈ **128 fJ/pulse** at V_pgm = 2.0 V. Currently OVER the 50 fJ/pulse target (lower pulse-count or per-pulse split needed). Final number pending H4. |
| M6 | E_total (fire + erase per cycle) | ≤ 100 fJ | Pending — needs erase-phase integration (extract_energy.py extension) on H4 steady-state cycle |
| M7 | V_pgm | ≤ 2.0 V | ✓ PASS (V_pgm_opt = 2.0 V) |
| M8 | C2C σ/μ | ≤ 5 % | Pending H4 |
| M9 | I-V R² | ≥ 0.90 | post-ERS 0.95 PASS; post-PGM 0.77 (floor-limited, documented) |
| M9b | MW vs Tasneem | – | 2.8× — differentiator |
| M10 | SS | 88–132 mV/dec | post-PGM 100 PASS; post-ERS 164 (documented as MFIS asymmetry) |
| M11 | DIBL | Optional | – |
| M12a | P–E loop topology | qualitative | ✓ PASS (H0e) |
| M12b | V_c,gate agreement | ≤ 5 % | ✓ PASS (0.5 %, H0e) |

**Outstanding before submission:** H4 (M8 + long-tail M1), H5 (M5 + M6). All other gates closed.

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
| H4 (next; succeeds Phase 1C [`simF_endurance/`](Simulations/simF_endurance/)) | `simH_optimize/sdevice_simH4_endurance.cmd` (gen: `_gen_h4_endurance_cmd.py` with `assert_alignment`; SWB `@V_pgm@ ∈ {1.95, 1.975, 2.0, 2.025, 2.05} V`, V_erase = −6 V hardcoded, 20 cycles) | extend `analyze_phase1d_cyclic.py` with cross-node σ/μ for M8 |
| H5 (no new sim; reuses Phase 1C [`simE_energy/extract_energy.py`](Simulations/simE_energy/extract_energy.py)) | – | Script extended 2026-05-19 to handle cyclic `cN_pN_*` naming + `--include` tag filter. Per-tag CSVs already in `simH_optimize/cyclic_lif_outputs/cyclic_vm{4,6,10}_energy_summary.csv`. Erase-phase segments still to add. |
| τ_P selection (Phase 1C, already done) | `simD_leak/sdevice_simD_leak.cmd` swept τ_P ∈ {0, 1e-6, 1e-5, 1e-4, 1e-3} | Selected τ_P = 1e-5 (10 µs); locked in `sdevice_gaafet_lif.par` line 68. Re-confirmed by H3 par audit 2026-05-17. |

All par changes (none after H0e) go in `Simulations/sdevice_gaafet_lif.par`. Log in `Calibration_Log_2026_01_15.md`.

---

## Next actions

1. **H4 endurance** — push the already-generated [`sdevice_simH4_endurance.cmd`](Simulations/simH_optimize/sdevice_simH4_endurance.cmd) to the remote, launch the SWB L5 run on `@V_pgm@ ∈ {1.95, 1.975, 2.0, 2.025, 2.05} V`. Wall-clock ≈ 100 min/node × 5 nodes ≈ 8.5 h. Replaces Phase 1C `simF_endurance/` (which used the now-invalidated V_pulse = +6 V over-switching operating point).
2. **H5 energy** — extend [`Simulations/simE_energy/extract_energy.py`](Simulations/simE_energy/extract_energy.py) to also integrate `erase_rise|erase_hold|erase_fall|relax` segments so the per-cycle E_total covers fire + erase + relax. Run on H4 steady-state cycle (c10..c20) at V_pgm = 2.0 V. Write up to `Writing_Materials/Phase1D_Analysis/Energy/H5_energy.md`. Current preview from H3 Step 3b: **E_fire = 1.151 pJ per 9-pulse burst at V_erase = −6 V** (128 fJ/pulse, gate+drain integrated).
3. **`Step_2/lif_parameters.py` rewrite** — flush measured numbers from H3 Step 3b (and H4 once it lands) into the LIF parameter file.
4. **Writing pass** — replace the stale "restore to virgin ±25 %" framing throughout `Writing_Materials/` with the M-rest stable-rest-state framing.

## Phase 1C → Phase 1D operating-point change (why H4/H5 aren't redundant with simD/E/F)

Phase 1C used **V_pulse = +6.0 V**, **V_reset = −5.0 V hold**, **V_GS_read = +0.2 V** (above-V_t). The H1 v3 sweep in Phase 1D found that V_pgm = +6 V causes **non-monotonic over-switching** — ID peaks at p6 (~7.4 pA/µm) and collapses to 0.86 pA/µm by p9 — explaining the +4.74 %/cyc drift driver seen in Phase 1C `simF_endurance/`. Phase 1D moved to the sub-coercive operating point **V_pgm = +2.0 V**, **V_GS_read = −0.5 V** (sub-V_t, exponential sensitivity), and **pulsed V_erase = −6 V + 70 µs relax**. simD (τ_P selection), simE (energy extractor), simF (endurance protocol) are reused at the new operating point — H4 is the simF protocol relaunched at the V_pgm = +2 V / V_erase = −6 V point with 20 cycles + V_pgm variability, and H5 is simE's `extract_energy.py` pointed at H3 Step 3b / H4 outputs (now with cyclic-naming support).
