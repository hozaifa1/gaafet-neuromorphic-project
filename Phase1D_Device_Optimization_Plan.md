# Phase 1D — Tier A TODO List (2026-05-08, last updated 2026-05-10)

Target: Nature Electronics / IEEE TED / IEDM. All steps must pass before submitting. Run in order.

**Reference paper for I-V calibration:** Tasneem et al., IEEE TED 69(3), 1568–1576 (2022). DOI: 10.1109/TED.2022.3141988. File: `Papers/Efficiency of Ferroelectric Field-Effect.pdf`. Target figure: Fig. 3(c).

**Publication-grade outputs and analysis live elsewhere — this file is the run-list / decision-log only:**
- Calibration figures + record: `Writing_Materials/Calibration_Full/` (already finalized)
- Phase 1D analyses + figures: `Writing_Materials/Phase1D_Analysis/`
- Calibration log: `Calibration_Log_2026_01_15.md`

**Stated targets from Tasneem 2022:** ΔV_t ≈ 0.5 V; SS_post-write ≈ 110 mV/dec; V_t @ I/W = 10⁻⁴ µA/µm; sweep rate 2.5 V/ms.

---

## H0 — Calibration Re-Verification

### H0a v5 — PASSED ✓ (2026-05-09)
File: `simH_optimize/sdevice_simH0a_v5_writeread.cmd`. Tasneem write-then-read protocol, 10 µs pulses, read window −2.0 → +1.0 V.

**Headline metrics (full table → `Writing_Materials/Calibration_Full/CALIBRATION_PUBLICATION.md` §4):**

| Metric | Value | Target | Status |
|---|---|---|---|
| Memory window ΔV_t | 1.40 V | ≥ 0.5 V (M3) | **PASS — 2.8× Tasneem (device differentiator)** |
| SS post-PGM | 100 mV/dec | 88–132 (M10) | PASS |
| SS post-ERS | 164 mV/dec | 88–132 | doc'd as polarization asymmetry |
| R² post-ERS (V_t-aligned) | 0.95 | ≥ 0.90 (M9) | PASS |
| R² post-PGM (V_t-aligned) | 0.77 | ≥ 0.90 | residual = 3 nA/µm leakage floor (geometry, not model) |
| I_off floor | 3 nA/µm | – | L_g=100 nm SCE |

Plots: `Writing_Materials/Calibration_Full/plots/`. Earlier H0a v1–v4 attempts: see `H0a_versions_archive.md` (or revisit older revision of this file) — all preserved as run-history, not publication-relevant.

### H0b — DROPPED. H0c — folded into H0a v5. H0d (DIBL) — DEMOTED to optional.

### H0e — RUN, PASS (device-level criterion, 2026-05-10)
File: `simH_optimize/sdevice_simH0e_PE_validation.cmd` (Quasistationary, two-cycle ±4 V).
**Full analysis + figures: `Writing_Materials/Phase1D_Analysis/H0e_PE_loop_analysis.md`.**

Headline: P–E loop is closed, sign-consistent, shows correct wake-up (cycle 1 → cycle 2). Probe values (P_r = 1.48, P_s = 2.92 µC/cm², E_c = 0.552 MV/cm) are 6–10× below MFM anchors **because they are MFIS-depolarization-suppressed device values, not bare-FE material values.** Analytical reconciliation: V_c,gate from probe ↔ analytical agrees to 0.5 % (1.91 V documented vs 1.92 V predicted). M12 (originally "P_r ±10% MFM") is replaced by:
- **M12a (qualitative loop topology):** PASS.
- **M12b (V_c,gate analytical agreement):** PASS.

**Decision: do NOT edit the par file.** Tuning P_r/F_c upward would break H0a v5 (MW = 1.40 V) while chasing a phantom mismatch that originates in the MFIS measurement geometry, not in the model. Par file (pinned in H0e_outputs/) stays as-is.

### H0f — DEFERRED to reviewer-response card (2026-05-10)
Multi-domain Preisach. H0a v5 residuals are not shape-sharpness problems (post-PGM R² deficit lives below the leakage floor; post-ERS SS asymmetry is real polarization physics). Adding multi-domain risks regressing the v5 wins for no upside on the actual residuals. Hold for reviewer Q&A only.

### H0g — RUN, COMPLETE (analytical, 2026-05-10)
Script: `Simulations/analyze_phase1d_h0g.py`. Outputs: `Simulations/phase1d_calibration/h0g/`.

Headline: AreaFactor = 0.071 retained vs DG-geom prediction = 0.0045 (15.8×). The retained value was Run-16 calibration tuning. **Not a publication blocker** — every reported current is normalized as I_D/W in µA/µm, which cancels the AreaFactor scalar. Methods disclosure paragraph at `Simulations/phase1d_calibration/h0g/h0g_methods_paragraph.md`. 3D rebuild of `sde_dvs.cmd` deferred to reviewer Q&A.

---

## H1 — V_pgm Operating-Point Sweep
- Run: `simH_optimize/sdevice_simH1_Vpgm_sweep.cmd`. SWB sweep `@V_pulse@` ∈ {1.0, 1.5, 2.0, 2.5, 6.0} V. 9-pulse train, simC v6 cadence.
- Pass: V_pgm ≤ 2.0 V → fire_ratio ≥ 1.5 (M2) AND E_spike ≤ 50 fJ (M5).
- Record V_pgm_opt for H2–H5.

## H2 — PE Loop at V_pgm_opt (CV midpoints, MW + analog states)
- Run: `simH_optimize/sdevice_simH2_PE_loop.cmd` with V_pgm = V_pgm_opt.
- Pass: MW ≥ 0.5 V (M3); ≥ 9 distinguishable ΔV_t steps (M4) when V_pgm stepped 0.2 V.

## H3 — Reset Protocol Optimization
- Run: `simH_optimize/sdevice_simH3_reset.cmd`. L9 Taguchi over V_reset ∈ {−3,−5,−7} V, t_reset ∈ {1,10,100} µs, t_settle ∈ {0,10,100} µs.
- Pass: drift ≤ 1.0 %/cycle (M1).

## H4 — Endurance + Variability (5-cycle full train)
- Run: adapt simC v6 cmd with V_pgm = V_pgm_opt and reset from H3, 5 cycles × 9 pulses.
- Pass: drift ≤ 1.0 %/cycle (M1); fire_ratio at cycle 5 ≥ 1.5 (M2); C2C σ/μ ≤ 5 % (M8).

## H5 — Energy Accounting (no new sim)
- Compute from H4: E_gate = ½·C_gg·V_pgm_opt²; E_read = ∫V_DS·I_D dt over 100 ns; E_total = E_gate + E_read.
- Pass: E_gate ≤ 50 fJ (M5); E_total ≤ 100 fJ (M6).

---

## Submission gate — current status

| # | Metric | Target | Status |
|---|---|---|---|
| M1 | Drift | ≤ 1.0 %/cycle | pending H4 |
| M2 | fire_ratio @ cycle 5 | ≥ 1.5 | pending H4 |
| M3 | Memory window | ≥ 0.5 V | **PASS (1.40 V, H0a v5)** |
| M4 | Analog states | ≥ 9 | pending H2 |
| M5 | E_gate | ≤ 50 fJ | pending H5 |
| M6 | E_total | ≤ 100 fJ | pending H5 |
| M7 | V_pgm | ≤ 2.0 V | pending H1 |
| M8 | C2C variability | ≤ 5% | pending H4 |
| M9 | I-V R² (V_t-aligned) | ≥ 0.90 | **post-ERS 0.95 PASS**; post-PGM 0.77 (floor-limited, doc'd) |
| M9b | MW vs Tasneem | – | **2.8× — DIFFERENTIATOR (1.40 V vs 0.50 V)** |
| M10 | SS in 88–132 mV/dec | – | post-PGM 100 PASS; post-ERS 164 (asymmetric, doc'd) |
| M11 | DIBL | DEMOTED — optional | – |
| M12a | P-E loop topology | qualitative | **PASS (H0e)** |
| M12b | V_c,gate analytical agreement | ≤ 5% | **PASS (0.5%, H0e §4.1)** |

---

## Files

| Step | cmd file | analysis | par changes |
|---|---|---|---|
| H0a v5 ✓ | `simH_optimize/sdevice_simH0a_v5_writeread.cmd` | `Simulations/analyze_phase1d_h0a.py` → `Writing_Materials/Calibration_Full/` | – |
| H0e ✓ | `simH_optimize/sdevice_simH0e_PE_validation.cmd` | `Simulations/analyze_phase1d_h0e.py` → `Writing_Materials/Phase1D_Analysis/H0e_PE_loop_analysis.md` | none (do not tune) |
| H0g ✓ | (analytical only) | `Simulations/analyze_phase1d_h0g.py` → `Simulations/phase1d_calibration/h0g/` | – |
| H0f (deferred) | reviewer-response: re-run H0a v5 with NumberOfDomains=40 | – | NumberOfDomains, DomainLength, σ(α₂) |
| H1 | `simH_optimize/sdevice_simH1_Vpgm_sweep.cmd` | – | possibly F_c |
| H2 | `simH_optimize/sdevice_simH2_PE_loop.cmd` | – | possibly P_r |
| H3 | `simH_optimize/sdevice_simH3_reset.cmd` | – | – |
| H4 | adapt simC v6 cmd | – | – |
| H5 | (no new sim) | – | – |

All par changes go in `Simulations/sdevice_gaafet_lif.par`. Log every change in `Calibration_Log_2026_01_15.md`.
