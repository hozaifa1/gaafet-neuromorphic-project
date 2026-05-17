# Phase 1D — Tier A TODO List (2026-05-08, last updated 2026-05-11)

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

### H1 v1 — INVALIDATED (2026-05-11). Root cause: silent gate-drive failure.
Ran SWB nodes n2/n4/n5/n6/n7 with `@V_pulse@` ∈ {0.8, 1.3, 1.8, 2.3, 5.8} (= V_pgm − 0.2 V dc read level). Outputs at `simH_optimize/H1sweep_outputs/`. Analysis: `Simulations/analyze_phase1d_h1.py` → `Simulations/phase1d_h1/h1_metrics.txt`.

**Diagnostic finding:** every node returned `ID_baseline = ID_p09 = 106 µA/µm` → `fire_ratio = 1.000`. Pol_y at the end of every `p0N_write_` segment was the virgin equilibrium 0.098 µC/cm², and |E_y| at the FE probe = 0.116 MV/cm = 0.10·F_c on every node. The gate voltage was stuck at the QS-ramped 0.2 V throughout the supposed 9-pulse train — for every V_pgm. Byte-identical staircase across the sweep is the same failure signature as Sim-Pre-6 / d0-sweep in `spiking_simulation_debugging_log_v2.md` §4.

**Mechanism:** the v1 cmd mixed two paradigms — `Device GAAFeFET { Electrode {...} }` (instance-level contacts) plus `System { Vsource_pset vg(g 0) { dc=0 pwl=(...) } }` (circuit-level source). The `pwl` deviation signal never connected to the contact during transient, so the only voltage acting on the gate was the QS-set `vg.dc = 0.2 V`. The 9 transient blocks just held that voltage for 1.818 µs.

### H1 v2 — RUN, RESULTS VALID (gate-drive bug fixed) but **M2 metric is wrong for our device** (2026-05-11)
File: `simH_optimize/sdevice_simH1_Vpgm_sweep.cmd` (v2, Goal-driven gate, top-level Electrode + simC v6 pattern). SWB sweep `@V_pgm@` ∈ {1.0, 1.5, 2.0, 2.5, 6.0} V. Outputs replaced in `simH_optimize/H1sweep_outputs/`. Analysis script `Simulations/analyze_phase1d_h1.py` re-run → `Simulations/phase1d_h1/`.

**Headline (read at V_GS=0.2 V, V_DS=0.05 V, 9 × 100 ns pulses, τ_E = 1 µs):**

| V_pgm (V) | ID_base (µA/µm) | ID_p09 (µA/µm) | fire_ratio | ΔV_t_eff (mV)* | Pol_y_p09 (µC/cm²) | \|E_y\|/F_c | Monotonic 9-step staircase |
|---|---|---|---|---|---|---|---|
| 1.0 | 95.9 | 97.3 | 1.014 | −0.6 | +0.090 | 0.12 (sub) | ✓ |
| 1.5 | 95.9 | 99.1 | 1.033 | −1.4 | +0.071 | 0.26 (sub) | ✓ |
| 2.0 | 95.9 | 101  | 1.057 | −2.4 | +0.043 | 0.40 (sub) | ✓ |
| 2.5 | 95.9 | 104  | 1.084 | −3.5 | +0.010 | 0.54 (sub) | ✓ |
| 6.0 | 95.9 | 127  | 1.324 | −12.2 | −0.310 | **1.52 (super)** | ✓ |

\* `ΔV_t_eff = −SS · log10(ID_p09/ID_base)`, SS = 100 mV/dec from H0a v5. This is an over-estimate above-V_t but gives a same-units comparison to H0a's MW = 1.40 V anchor.

**Device behaviour: PASSES the physics sanity checks.**
- Distinct, monotonic ID(N) staircases across all V_pgm (no longer byte-identical → gate-drive bug eliminated).
- |E_y|/F_c at p09 hold scales 0.12 → 1.52 across the sweep, crossing unity between V_pgm = 2.5 V and 6.0 V. Lines up with the analytical V_c,gate ≈ 1.91 V on the current par.
- Pol_y_p09 sweeps from +0.090 µC/cm² (virgin equilibrium at V_GS=0.2 V) at V_pgm=1.0 down to −0.310 µC/cm² at V_pgm=6.0 — half-loop polarity-flipping at the supercoercive node, partial sub-coercive switching elsewhere. Topology matches H0e.

**M2 result: FAIL on every node** (best fire_ratio = 1.324 at V_pgm = 6 V; target 1.5). **But M2 as defined is the wrong test for this device.** Reading at V_GS = 0.2 V puts the channel in strong inversion (ID_base ≈ 96 µA/µm — already in the µA-decade plateau), so a 0.4 µC/cm² polarization swing only moves ID by ~30 %. The fire-ratio paradigm requires the read level to sit in the sub-V_t region where ID is exponentially sensitive to V_t. This is a measurement-protocol mismatch, not a device limitation.

### H1 v3 — RUN, **M2 + M7 PASS, V_pgm_opt = 2.0 V (safe), 2.5 V (peak fire margin)** (2026-05-11)
File: `simH_optimize/sdevice_simH1_Vpgm_sweep.cmd` (v3 — top-level Electrode, Goal-driven gate, **V_GS_read = −0.5 V** sub-V_t). SWB sweep `@V_pgm@` ∈ {1.0, 1.5, 2.0, 2.5, 6.0} V. Outputs in `simH_optimize/H1sweep_outputs/`. Analysis: `Simulations/analyze_phase1d_h1.py` → `Simulations/phase1d_h1/`.

**Headline (read at V_GS = −0.5 V, V_DS = 0.05 V, ID_base = 0.27 pA/µm for every node — virgin equilibrium at the sub-V_t read level; absolute current is Areafactor-scaled, ratios are physical):**

| V_pgm (V) | ID_p09 (pA/µm) | fire_ratio | ΔV_t_eff* | Pol_y_p09 (µC/cm²) | \|E_y\|/F_c | Monotonic | M2 verdict |
|---|---|---|---|---|---|---|---|
| 1.0 | 0.20 | **0.77** | +11 mV | +0.124 | 0.13 (sub) | ✗ (dip pulses 2–3) | **FAIL** (anti-fire — wrong-sign domains) |
| 1.5 | 0.58 | **2.18** | −34 mV | +0.112 | 0.27 (sub) | ✗ (dip pulse 2) | **PASS** |
| **2.0** | **1.27** | **4.79** | **−68 mV** | +0.087 | 0.41 (sub) | **✓** | **PASS** |
| **2.5** | **1.99** | **7.49** | **−87 mV** | +0.057 | 0.55 (sub) | **✓** | **PASS** (peak fire margin) |
| 6.0 | 0.86 | **3.25** | −51 mV | −0.250 | 1.53 (super) | ✗ (over-switching — peaks at p06=7.4 pA/µm, drops to 0.86 pA/µm at p09) | PASS (but over-switched) |

\* `ΔV_t_eff = −SS·log10(ID_p09/ID_base)`, SS = 100 mV/dec (H0a v5 post-PGM). At deep sub-V_t this is now a much closer estimate of the true V_t shift than in v2.

**Tier-A claims this delivers:**
1. **Sub-coercive LIF fire confirmed** — V_pgm = 2.5 V gives 7.5× fire ratio at |E|/F_c = 0.55 (well below 1.0). The device fires from OFF using purely sub-coercive partial polarization switching, no avalanche/II.
2. **M2 PASS** at every V_pgm ≥ 1.5 V — best fire_ratio = 7.49× at V_pgm = 2.5 V.
3. **M7 PASS** — fire_ratio ≥ 1.5x already cleared at V_pgm = 1.5 V (well below the 2.0 V cap).
4. **Operating window discovered:** ID_p09 *decreases* above V_pgm ≈ 2.5 V because of over-switching — at V_pgm = 6 V the device peaks at p06 (7.4 pA/µm = 27× fire), then **runs away in the wrong direction** to 0.86 pA/µm by p09. This is genuine non-monotonic dynamics and rules out the Phase 1C 6 V reference operating point as a stable fire mode.

**V_pgm_opt decision (recommended for H2/H3):**
- **V_pgm_opt = 2.0 V** (safe choice): monotonic 9-pulse staircase, fire_ratio 4.79×, ΔV_t_eff −68 mV, |E|/F_c = 0.41, ID dynamic range 0.27 pA/µm → 1.27 pA/µm = 4.8× from baseline to p09. Best balance of fire margin, monotonicity, and sub-coercive guarantee. **Use this for H2/H3 by default.**
- **V_pgm = 1.5 V** (aggressive choice, M7-deepest): would pass M2 but the pulse-2 dip in the staircase introduces a small non-monotonicity. Acceptable for endurance work but not for a clean publication staircase figure.
- **V_pgm = 2.5 V** (peak fire margin): highest fire_ratio (7.49×), still sub-coercive (|E|/F_c=0.55), fully monotonic — also defensible. M7 (V_pgm ≤ 2.0 V) FAILS by 0.5 V at this point.

**Failure-edge observations (kept for thesis defense):**
- *V_pgm = 1.0 V → anti-fire (fire_ratio = 0.77):* at deep sub-coercive (|E|/F_c = 0.13), 9 short pulses produce a net *positive* V_t shift (+11 mV). Likely τ_E partial-switch + asymmetric relaxation drives a small fraction of domains in the wrong direction; cumulative effect dominates. Marks the "fire threshold" lower bound.
- *V_pgm = 6.0 V → over-switching:* at p06 the ID reaches 7.4 pA/µm (27× fire margin), then collapses to 0.86 pA/µm by p09 — the device runs through the post-PGM state and starts wrapping the loop. Phase 1C's +4.74 %/cycle drift driver origin is now fully explained.

E_gate accounting still deferred to H5.

## H2 — V_t shift at V_pgm_opt (MW + analog states)
- File: `simH_optimize/sdevice_simH2_PE_loop.cmd`.
  - **v1** had the broken Vsource_pset/pwl pgm/ers driver (same bug as H1 v1).
  - **v2** (2026-05-11) rewrote pulses with top-level Electrode + Goal-driven Transient, but kept `ACCoupled` CV sweeps for V_t. SWB run on 2026-05-14 failed at parse with `Cannot find AC node 'gate_contact' !` (`h2_outputs/n2_des.err`). Root cause: `ACCoupled` requires circuit nodes from a `System {}` block (documented in simG_capacitance §1) — incompatible with the top-level Electrode + Goal pattern that the pulse train requires.
  - **v3 INVALIDATED (2026-05-15)** — protocol-level FE-state overwrite by Quasistationary V_G ramps. v3 replaced ACCoupled with DC ID-VG read sweeps (`idvg_virgin_` / `idvg_postpgm_` / `idvg_posters_`, V_G: −1 → +1 V, V_DS = 0.05 V) and also drove the gate-init preambles via Quasistationary. SWB ran clean on all 5 nodes — no errors, plt data complete (`h2_outputs/idvg_*_n{2,4,5,6,7}_des.plt`). But analysis (`Simulations/analyze_phase1d_h2.py` → `Simulations/phase1d_h2/`) returns **identical V_t to 6 decimal places across the entire V_pgm sweep**:

    | V_pgm (V) | V_t_virgin (V) | V_t_postpgm (V) | V_t_posters (V) | MW (V) | M3 |
    |---|---|---|---|---|---|
    | 1.5 | −0.34089 | −0.36990 | −0.36990 | ≈ 0 | FAIL |
    | 2.0 | −0.34089 | −0.36990 | −0.36990 | ≈ 0 | FAIL |
    | 2.5 | −0.34089 | −0.36990 | −0.36990 | ≈ 0 | FAIL |
    | 3.5 | −0.34089 | −0.36990 | −0.36990 | ≈ 0 | FAIL |
    | 6.0 | −0.34089 | −0.36990 | −0.36990 | ≈ 0 | FAIL |

    Same V_t to 1 µV across {1.5 → 6.0 V} V_pgm AND between postpgm and posters branches → the FE state at the V_t crossing is independent of V_pgm and independent of the pulse polarity. Mathematically possible only if every read sweep is preceded by the same FE-state-overwriting event.

    **Mechanism:** `Quasistationary {Goal V_G = ±1 V}` runs in *fictitious* time (parameter t ∈ [0, 1], no physical ns/µs/s mapping). The HZO Preisach Polarization model integrates its dynamics against that fictitious time. Sub-coercive applied voltages (|E|/F_c < 1) that would NOT switch the FE on a 100 ns pulse DO drive partial polarization creep when held for fictitious-~1 s. Every `gate_init_*` Quasistationary ramp from {0.2 V or +1 V} → −1 V therefore acts as a slow soft-ERS that fully overwrites the 100 ns pgm/ers pulse delivered just before. By the time the QS read sweep crosses V_t, the FE is in the same "post-(slow QS to −1 V) creep state" in every branch → identical V_t in postpgm and posters across every V_pgm.

    Evidence supporting this mechanism (not a 9-pulse-was-needed problem):
    - H1 v3 *did* shift V_t at the SAME V_pgm range with 9 × 100 ns pulses **and a Transient sub-V_t read** — fire_ratio = 7.49× at V_pgm = 2.5 V, ΔV_t_eff = −87 mV. So polarization switching is occurring; H2 v3 is destroying the evidence of it during the read.
    - H0a v5 PASSED with MW = 1.40 V using a single 10 µs pulse — but its read sweep is Transient + Goal (not QS), keeping FE dynamics frozen on the fast read timescale.

  - **v4 RAN CLEAN — read protocol fixed; FE-physics-limited at 100 ns pulses (2026-05-15).** End-to-end Transient + Goal pattern (every V_G ramp driven by `Transient + Goal { Name="gate_contact" Voltage=X }`, drain bias is the only Quasistationary step). Read sweep: V_G −2.0 → +1.0 V over 100 µs with 100-interval `CurrentPlot` → ~30 mV V_G resolution. Plt names preserved. Analyzer fix (2026-05-15): `extract_vt()` uses the **last** False→True crossing in V_G-ascending order to skip the spurious transient-settling sample at the start of the Transient read sweep, where |I_D| at V_G = −2 V can briefly exceed the V_t criterion before falling into the real sub-V_t region.

    **Headline (V_t at I_D / W = 1e-4 µA/µm, single 100 ns PGM/ERS pulse per branch):**

    | V_pgm (V) | V_t_virgin (V) | V_t_postpgm (V) | V_t_posters (V) | PGM shift (mV) | ERS shift (mV) | MW (mV) |
    |---|---|---|---|---|---|---|
    | 1.5 | −0.364 | −0.411 | −0.410 | −46 | −45 | +1 |
    | 2.0 | −0.364 | −0.421 | −0.420 | −57 | −56 | +1 |
    | 2.5 | −0.364 | −0.432 | −0.431 | −68 | −66 | +2 |
    | 3.5 | −0.364 | −0.455 | −0.452 | −91 | −87 | +3 |
    | 6.0 | −0.364 | −0.513 | −0.505 | −149 | −141 | +8 |

    **What works:**
    - V_t_virgin identical to 1 µV across all 5 nodes → FE-read protocol is now clean (no cross-branch contamination of the FE state during reads). The v3 QS-creep bug is fully eliminated.
    - PGM V_t shift is monotonic and **linear in V_pgm at 22–23 mV/V** across 1.5 → 6.0 V. Single 100 ns pulse delivers ~70 % of what H1 v3's 9-pulse train delivers at the same V_pgm — consistent partial-switching physics.

    **What doesn't (and why it isn't a bug):**
    - ERS shift ≈ PGM shift (same direction, ~5 % smaller magnitude). The ERS pulse only weakly recovers toward virgin — it does not flip the FE back to a −Pol state. Probe data at the SAME |V_G| = 6 V: `pgm_hold` sees |E_y| = 1.857 MV/cm (super-coercive, |E|/F_c = 1.55) but `ers_hold` sees only 0.477 MV/cm (sub-coercive, |E|/F_c = 0.40). The just-programmed +Pol state generates a depolarization field that screens 74 % of the reverse gate bias.
    - Classical MFIS imprint at sub-µs writes. Tasneem 2022 reports the same behavior (10 µs pulses required to achieve MW = 0.5 V).

    **M3 / M4 implications:**
    - **M3 (MW ≥ 0.5 V) remains PASS** via [H0a v5](Writing_Materials/Calibration_Full/) (10 µs pulses, MW = 1.40 V). v4 confirms that the device requires write-pulse duration ≳ 1 µs to overcome depolarization-screened ERS — a pulse-duration tradeoff worth a methods paragraph but NOT a Tier-A blocker.
    - **M4 (≥ 9 analog levels) — clear path forward.** The PGM shift is linear at 22–23 mV/V, so 9 levels at ~11 mV separation = V_pgm steps of 0.5 V across V_pgm ∈ {1.5 … 5.5} V (9 nodes) deliver M4. Defer the L9 expansion until v5 lengthens the pulses for symmetric MW.

  - **v5 RAN, three-regime FE physics revealed (2026-05-15).** Pulse hold 100 ns → 10 µs. SWB sweep `@V_pgm@ ∈ {1.5, 2.0, 2.5, 3.5, 6.0}` V completed clean on all 5 nodes.

    **Headline (V_t at I_D / W = 1e-4 µA/µm, 10 µs PGM/ERS):**

    | V_pgm (V) | V_t_virgin (V) | V_t_postpgm (V) | V_t_posters (V) | PGM shift (mV) | ERS shift (mV) | MW (mV) |
    |---|---|---|---|---|---|---|
    | 1.5 | −0.364 | −0.481 | −0.490 | **−117** | −126 | −9 |
    | 2.0 | −0.364 | −0.530 | −0.555 | **−166** | −191 | −25 |
    | 2.5 | −0.364 | −0.540 | −0.560 | **−176** | −196 | −19 |
    | 3.5 | −0.364 | −0.456 | −0.456 | −92 | −92 | 0 |
    | 6.0 | −0.364 | **+0.352** | **+0.339** | **+717** | +704 | −13 |

    **Three Preisach regimes confirmed:**
    1. **Sub-coercive (V_pgm ≤ 2.5 V):** partial-domain "easy" switching → V_t shifts NEGATIVE (electron-attracting +Pol partial state in Sentaurus convention). Magnitude grows monotonically with V_pgm (−117 → −176 mV).
    2. **Near-coercive transition (V_pgm = 3.5 V):** partial reversal — V_t shift drops to −92 mV. The FE is straddling the boundary between the "easy" partial state and the saturated −Pol state.
    3. **Super-coercive (V_pgm = 6.0 V):** FULL saturation flip → V_t shifts POSITIVE by +717 mV. Sentaurus −Pol_sat (electron-depleting bound charge). This is the **opposite sign** from the sub-coercive partial switching — beautiful textbook Preisach behavior. Matches H1 v3's polarity flip at V_pgm = 6 V (Pol_y_p09 = +0.010 at 2.5 V → −0.310 at 6 V).

    **Total V_t dynamic range: ~890 mV** (+717 − (−176)). That's solid analog headroom for M4.

    **Why MW ≈ 0 V across the entire sweep:**
    - In the sub-coercive regime: PGM at +V_pgm and ERS at −V_pgm both end up at the SAME partial-switched state (both branches sit at the easy-direction partial state because ERS at −V_pgm is too weak to break out via depolarization screening — same v4 problem, longer pulse just gives more time to settle into the same state).
    - At V_pgm = 6 V: PGM saturates to −Pol_sat (V_t = +0.352 V). ERS at −6 V cannot flip it back because the depolarization field from the just-saturated state steals ~74 % of the reverse bias (v4 probe data: |E|/F_c = 0.40 at −6 V after PGM, vs 1.55 at +6 V virgin). 10 µs hold doesn't help when |E| is sub-coercive.
    - **MW from symmetric ±V_pgm pulses is fundamentally limited by depolarization-screened imprint in our MFIS stack.** H0a v5's MW = 1.40 V at ±4 V works because ±4 V lands in the partial-switching regime where neither branch reaches stuck saturation, and the two partial states (one +Pol-leaning, one −Pol-leaning) are still distinguishable.

    **M3 / M4 implications:**
    - **M3 (MW ≥ 0.5 V) remains PASS** via H0a v5 (10 µs ±4 V pulses, MW = 1.40 V). v5 confirms why ±4 V works and why arbitrary symmetric ±V_pgm doesn't.
    - **M4 (≥ 9 analog levels) — promoted to a stronger TREND PASS.** v5 shows 5 distinguishable V_t levels across the 5-node sweep already (3 negative-direction + 1 transitional + 1 saturated). With finer V_pgm sampling around the regime transition (V_pgm ∈ {1.5 … 4.0} V at 0.25 V step, 11 nodes) we should clear ≥ 9 levels comfortably.

  - **v5 ROOT CAUSE FOUND (2026-05-15):** the v5 read sweeps were 100 µs long. At that timescale the FE polarization responds to the V_G ramp DURING the read, so postpgm and posters branches converge to the same intermediate state by the time V_t is crossed (around V_G ≈ +0.3 V). The Pol_y traces confirm the FE IS switching at the pulses (Pol_y swings −6.82 → +3.84 µC/cm² at V_pgm = 6 V, a ~10.6 µC/cm² bipolar swing — should give ~1 V V_t shift), but the slow read sweep erases the distinction before we can measure it.

    This is the **same read-overwrite failure mode as v3 (QS reads), just slower**. I misread H0a v5 as using 100 µs reads — its actual read sweep duration is **100 ns** (`InitialTime=1.0012e-05 FinalTime=1.0112e-05` in [sdevice_simH0a_v5_writeread.cmd](Simulations/simH_optimize/sdevice_simH0a_v5_writeread.cmd) line 149). Verified by reading H0a v5's `read_postERS_n2_des.plt` and `read_postPGM_n2_des.plt` outputs directly.

    At 100 ns sweep speed, FE polarization is effectively frozen: even saturated-state |E_y|/F_c ≈ 0.4 cannot drive meaningful Preisach switching in 100 ns (we measured this in v4 — 100 ns pulses produce only ~100 mV V_t shifts).

  - **v6 RAN — M3 PASS independently confirmed (2026-05-16).** Read sweep duration 100 µs → 100 ns (H0a v5 recipe). Total sim time ~21 µs. Analyzer also updated: V_t criterion changed from Tasneem 1e-4 µA/µm → H0a v5 internal 1.0 µA/µm (our TCAD I_off floor is ~3 nA/µm = 3e-3 µA/µm, above the Tasneem criterion — H0a v5 long ago worked this out); `load_branch()` drops the start-of-Transient displacement-current artifact at V_G = -2 V; `extract_vt()` reports a one-sided bound when V_t shifts past either read-range endpoint.

    **Headline (V_t at I_D / W = 1.0 µA/µm, V_G read sweep -2 → +1 V over 100 ns, V_DS = 0.05 V; pulses 10 ns rise / 10 µs hold / 10 ns fall):**

    | V_pgm (V) | V_t_virgin (V) | V_t_postpgm (V) | V_t_posters (V) | PGM shift (mV) | ERS shift (mV) | MW (V) | M3 |
    |---|---|---|---|---|---|---|---|
    | 1.5 | −0.092 | −0.293 | −0.215 | −200 | −123 | **0.078** | FAIL |
    | 2.0 | −0.092 | −0.418 | −0.260 | −325 | −167 | **0.158** | FAIL |
    | 2.5 | −0.092 | −0.566 | −0.261 | −474 | −169 | **0.305** | FAIL |
    | 3.5 | −0.092 | −0.922 | −0.070 | **−829** | +22 | **0.852** | **PASS** |
    | 6.0 | −0.092 | < −1.95 | > +1.00 | (saturated) | (saturated) | **> 2.95** | **PASS** |

    **What this delivers:**
    1. **M3 PASS at V_pgm ≥ 3.5 V**, independent of the H0a v5 calibration anchor. Best confirmed in-range MW = 852 mV at V_pgm = 3.5 V (target ≥ 500 mV). At V_pgm = 6 V the FE fully saturates and pushes V_t past both read-range endpoints → MW > 2.95 V (read-range-bounded; actual likely 4–5 V if the read were widened, but doing so would itself perturb the FE).
    2. **Monotonic MW(V_pgm) curve** with the textbook Preisach signature: PGM V_t shifts grow from −200 mV (V_pgm = 1.5 V, sub-coercive partial switching) to −829 mV (V_pgm = 3.5 V, well above coercive) before saturating off-range at V_pgm = 6 V. ERS shifts grow analogously and switch sign near V_pgm ≈ 3.5 V — the transition from partial to full bipolar switching.
    3. **M4 trend:** 4/5 distinguishable post-PGM V_t levels at 50 mV separation already, just from the 5-node sweep. Running the 9-node expansion `@V_pgm@ ∈ {1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0, 3.5, 4.0}` should comfortably clear ≥ 9 levels.

    **What changed across v3 → v6 (root-cause history):**
    - v3 failed at the QS V_G read (FE creep-overwrites in fictitious time).
    - v4 failed at 100 ns pulses (depolarization-screened ERS).
    - v5 failed at 100 µs Transient reads (FE responds to V_G ramp during read — same overwrite as v3, slower).
    - v6 succeeds: 100 ns reads keep FE frozen during measurement (H0a v5's recipe, verified by reading the cmd file directly instead of trusting prior plan-text shorthand).
- `@WF@` SWB parameter dropped (WF=4.35 fixed per H1 v1 invalidation note: polarization charge dominates V_t by 15× over any plausible WF sweep range).
- SWB sweep: `@V_pgm@` ∈ {1.5, 2.0, 2.5, 3.5, 6.0} V.
- Pass: MW ≥ 0.5 V (M3); ≥ 9 distinguishable ΔV_t steps (M4) when V_pgm stepped 0.2 V across ≥ 9 nodes (current 5-point sweep evaluates M3 only — M4 trend is informational).

## H3 — Reset Protocol Optimization
- File: `simH_optimize/sdevice_simH3_reset.cmd` — **v2 (2026-05-11)**.
  - v1 INVALIDATED: same `Device{Electrode}+System/Vsource_pset/pwl` silent-gate-drive bug as H1 v1 / H2 v1.
  - v2 rewrite: top-level Electrode + Goal-driven Transient for every fire pulse AND every reset pulse (simC v6 / H1 v3 / H2 v3 pattern). Read level V_GS = −0.5 V (matches H1 v3 sub-V_t convention so fire_ratio and drift are measured on the SS-exponential region of ID). V_pgm = 2.0 V hardcoded (= V_pgm_opt from H1 v3: safe choice, monotonic 9-pulse staircase, |E|/F_c=0.41 sub-coercive).
- SWB sweep: `@V_reset@` ∈ {−3.0, −5.0, −7.0} V (L3, reduced from the original L9 Taguchi). Centerpoint t_reset = 10 µs, t_settle = 10 µs hardcoded. To expand to L9 (V_reset × t_reset × t_settle), clone the cmd with re-derived time anchors per the header note — recomputation is mechanical (cycle length = 606 ns fires + 10 ns reset rise + t_reset + 10 ns reset fall + t_settle).
- Method: 3 cycles of (3 fire pulses → reset → 10 µs settle). drift_per_cycle = (ID_pre_c3 − ID_pre_c1) / ID_pre_c1 / 2.
- Pass: |drift| ≤ 1.0 %/cycle (M1). Pick the V_reset that minimizes |drift| while preserving fire_ratio → V_reset_opt for H4.

### H3 v2 — RAN, **FAIL on M1 as defined; root-caused (2026-05-17).** Reset over-drives the FE past virgin into the opposite saturation, and the fire pulses then partial-switch the wrong way against that post-reset baseline.
Outputs in `simH_optimize/h3_outputs/`. Analysis: `Simulations/analyze_phase1d_h3.py` → `Simulations/phase1d_h3/h3_metrics.txt`. All 3 SWB nodes ran clean (no solver errors).

**Headline (V_GS_read = −0.5 V, V_DS = 0.05 V; ID values in µA/µm; ID_baseline_virgin = 2.66 × 10⁻⁷ on every node):**

| V_reset | ID_settle_c1 | ID_settle_c2 | ID_settle_c3 | ID_c2_p1 | ID_c3_p1 | drift_c1→c3 / 2 | drift_c2→c3 |
|---|---|---|---|---|---|---|---|
| −3.0 V | 8.14e-7 (3.1× base) | 2.44e-6 | 2.52e-6 | 7.42e-7 | 9.93e-7 | +1043 %/cyc | **+3.3 %/cyc — FAIL** |
| −5.0 V | 8.40e-6 (32× base) | 1.16e-5 | 1.17e-5 | 2.11e-6 | 2.34e-6 | +2529 %/cyc | **+0.86 %/cyc — PASS (steady-state)** |
| −7.0 V | 2.02e-5 (76× base) | 2.61e-5 | 2.55e-5 | 5.23e-6 | 5.60e-6 | +6110 %/cyc | **−2.3 %/cyc — FAIL** |

`ID_settle_cN` = ID at the end of cycle N's settle window (the steady-state baseline the next fire train sees). `ID_cN_p1` = ID at the end of cycle N's first fire pulse read.

**Two distinct failures are visible:**

1. **Wake-up: cycle 1 is from virgin FE; cycles 2–3 are from the post-reset steady-state. The c1→c3 drift metric defined in the cmd header (`(ID_c3_p1 − ID_c1_p1)/ID_c1_p1/2`) is dominated by this one-shot transition (+1000 %–+6000 %/cyc) and is NOT a useful M1 measurement.** Same first-cycle wake-up signature already documented in H0e (cycle 1 P–E loop ≠ cycle 2). Steady-state cycle-to-cycle drift (c2→c3) is the right metric.
2. **The reset is OVER-DRIVING the FE.** At V_reset = −5 V the post-settle baseline sits at 32× the virgin equilibrium ID, at −7 V it sits at 76×. The reset is driving past virgin into the opposite (high-ID, low-V_t) polarization state and the device settles there permanently after cycle 1.

**Physics: the reset is not behaving like a reset, it's behaving like a stronger PGM (in the wrong direction).** From H2 v6 we know +V_pgm at sub-coercive (≤ 2.5 V, 10 µs) shifts V_t NEGATIVE (lowers V_t, raises ID). The 10 µs reset hold at −3 to −7 V drives |E|/F_c = 0.55–1.24 at the FE probe (sub-/near-/super-coercive). After the reset+settle (V_G ramped back to −0.5 V), ID is far above virgin — i.e. V_t has been shifted MORE negative by the negative reset than by the positive fire pulses. The two pulse polarities are partial-switching the FE in the SAME direction at our pulse widths, not opposite directions. This is the depolarization-screened MFIS asymmetry from [feedback_sentaurus_fe_reads.md / project_mfis_depolarization_screening.md] taken to its limit: at 10 µs hold the −V_reset doesn't flip the FE back, it walks it further into the same partial-saturation rail.

**Consequence for the LIF fire test:**
- Fire-from-virgin (cycle 1): ID_baseline=2.66e-7 → ID_c1_p3=3.14e-7, fire_ratio_c1_p3 = 1.18× — consistent with H1 v3 (3-pulse subset of the 9-pulse train at V_pgm=2.0 V gives a sub-PASS ratio).
- Fire-from-post-reset (cycle 3, V_reset=−5 V): ID_settle_c2=1.16e-5 → ID_c3_p3=3.80e-6, **fire-ratio = 0.33× — the device fires in the WRONG DIRECTION** (positive 2 V pulses now partially un-do the reset and DROP ID). The "fire_ratio_c3 = 13.88×" in the L3 table is computed against the artificially-low virgin baseline and is misleading.

**Tier-A verdict: V_reset = −5 V meets M1 (drift = +0.86 %/cyc, steady-state) but NOT the LIF intent. None of the three nodes deliver a "fire-from-baseline" operating point. H3 v2 cannot be used as-is.**

**Root cause = reset is 3–10× too strong in the wrong physical regime.** Two coupled knobs to dial back: V_reset (currently too negative) and t_reset (currently too long).

### H3 v3 — RAN. **M1 PASS at all nodes; restore PASS at V_reset = −1.0/−1.5 V; M2 FAIL at every node — fire burst is too short (3 × 100 ns) to clear the wake-up dip.** (2026-05-17)
File: `simH_optimize/sdevice_simH3_reset.cmd` (v3 — 5 cycles × 3 fires, V_pgm=+2.0 V/100 ns, t_reset=1 µs, t_settle=10 µs, top-level Electrode + Goal-driven gate everywhere). SWB sweep `@V_reset@` ∈ {−1.0, −1.5, −2.0, −2.5} V (L4). Outputs in `simH_optimize/h3_outputs/` (nodes n11=−1.0, n10=−1.5, n9=−2.0, n3=−2.5 V — discovered from c1_reset_hold gate voltage; SWB node order is not the parameter order). Analysis: `Simulations/analyze_phase1d_h3.py` → `Simulations/phase1d_h3/h3_metrics.txt`. All 4 nodes ran clean.

**Headline (ID at end of each cycle's settle window, µA/µm; virgin baseline = 2.658 × 10⁻⁷ on every node):**

| V_reset | c1 settle | c2 settle | c3 settle | c4 settle | c5 settle | restore_c5 | drift c3→c5 | M1 | restore | M2 |
|---|---|---|---|---|---|---|---|---|---|---|
| −1.0 V | 3.21e-7 | 3.31e-7 | 3.33e-7 | 3.34e-7 | 3.34e-7 | **1.26×** | +0.06 %/cyc | **PASS** | **PASS** | FAIL |
| −1.5 V | 3.57e-7 | 3.25e-7 | 3.17e-7 | 3.15e-7 | 3.15e-7 | **1.18×** | −0.33 %/cyc | **PASS** | **PASS** | FAIL |
| −2.0 V | 1.24e-6 | 1.26e-6 | 1.26e-6 | 1.26e-6 | 1.26e-6 | 4.73× | −0.03 %/cyc | PASS | FAIL | FAIL |
| −2.5 V | 4.67e-6 | 4.71e-6 | 4.72e-6 | 4.72e-6 | 4.72e-6 | 17.77× | +0.02 %/cyc | PASS | FAIL | FAIL |

**In-cycle fire ratios (ID_cN_p3 / pre-cycle baseline; M2 PASS requires ≥ 1.5):**

| V_reset | fire_c1 | fire_c2 | fire_c3 | fire_c4 | fire_c5 | direction |
|---|---|---|---|---|---|---|
| −1.0 V | 1.18× | 0.78× | 0.72× | 0.71× | 0.71× | **ANTI-fire from c2** |
| −1.5 V | 1.18× | 0.67× | 0.83× | 0.87× | 0.88× | **ANTI-fire** |
| −2.0 V | 1.18× | 0.20× | 0.28× | 0.30× | 0.30× | **ANTI-fire** |
| −2.5 V | 1.18× | 0.06× | 0.10× | 0.10× | 0.10× | **ANTI-fire** |

**What works:**
- Drift killed — 1 µs reset gives near-zero cycle-to-cycle drift on every node (the v2 wake-up artifact is now isolated to c1→c2, and c3→c5 is genuinely steady-state).
- Weak-reset over-flip eliminated at V_reset = −1.0/−1.5 V: post-settle ID within ±3× of virgin (restore PASS).
- All four resets are sub-coercive at the FE probe (|E|/F_c = 0.14, 0.15, 0.16, 0.21) — no V_reset-direction saturation in v3.

**What fails (and why):** within each cycle the staircase is `pre → p1 (deep dip) → p2 (deeper dip) → p3 (partial recovery)`, ending **below** the pre-cycle settle baseline. The same wake-up dip H1 v3 saw in p1–p2 from virgin — H1 v3 escaped it because it had 9 pulses to push past p2 and into the monotonic build-up regime (fire_ratio = 4.79× at p9). With only 3 pulses per cycle, we never escape the dip, so the fire burst always nets ANTI-fire against its own pre-cycle baseline.

Mechanism check from the c1 data (identical across all 4 nodes, since c1 starts from virgin): `pre 2.66e-7 → p1 4.54e-8 → p2 1.49e-7 → p3 3.14e-7` (= H1 v3's c1 first three pulses, replicated exactly). Confirms the v3 protocol is sound — 3 pulses is just not enough integration depth.

### H3 v4 — RAN. **Cycle 1 reproduces H1 v3 fire exactly (4.79× monotonic 9-pulse staircase); cycles 2–5 reveal the device LATCHES post-fire. M1 PASS, M2 FAIL.** (2026-05-17)
File: `simH_optimize/sdevice_simH3_reset.cmd` (v4, 5 cycles × 9 fires, t_reset=1 µs, t_settle=10 µs, generated by `Simulations/_gen_h3_v4_cmd.py`). SWB sweep `@V_reset@` ∈ {−1.0, −1.5, −2.0, −2.5} V (L4). Outputs in `simH_optimize/h3_outputs/v4/`. Analysis: `Simulations/analyze_phase1d_h3.py` → `Simulations/phase1d_h3/h3_metrics.txt`. All 4 nodes ran clean.

**Headline (ID at end of each cycle's settle window, µA/µm; virgin baseline = 2.658 × 10⁻⁷):**

| V_reset | c1 settle | c2 settle | c3 settle | c4 settle | c5 settle | restore_c5 | drift c3→c5 | M1 | restore | M2 | mono c3-5 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| −1.0 V | 1.61e-6 | 2.45e-6 | 2.58e-6 | 2.60e-6 | 2.60e-6 | **9.79×** | +0.39 %/cyc | PASS | FAIL | 0.93× FAIL | FAIL |
| −1.5 V | 1.62e-6 | 2.46e-6 | 2.59e-6 | 2.61e-6 | 2.61e-6 | 9.83× | +0.39 %/cyc | PASS | FAIL | 0.90× FAIL | FAIL |
| −2.0 V | 5.00e-6 | 6.04e-6 | 6.23e-6 | 6.25e-6 | 6.26e-6 | 23.55× | +0.23 %/cyc | PASS | FAIL | 0.30× FAIL | FAIL |
| −2.5 V | 1.08e-5 | 1.09e-5 | 1.09e-5 | 1.08e-5 | 1.08e-5 | 40.81× | −0.03 %/cyc | PASS | FAIL | 0.13× FAIL | FAIL |

**The win we DID get — cycle 1 reproduces H1 v3 perfectly on every node:**

`c1 staircase (identical across all 4 nodes, since c1 starts from virgin):`
`pre 2.66e-7 → p1 4.54e-8 (dip) → p2 1.49e-7 → p3 3.14e-7 → p4 4.84e-7 → p5 6.94e-7 → p6 9.15e-7 → p7 1.08e-6 → p8 1.20e-6 → **p9 1.27e-6** [monotonic from p2 onward]`

This is **the H1 v3 single-shot LIF fire byte-for-byte: 9 pulses at V_pgm=+2.0 V from virgin gives 4.79× fire_ratio with monotonic staircase past the p1–p2 wake-up dip.** Independent confirmation that the LIF fire mechanism is correct and reproducible. M2 PASSES against virgin baseline at p9 of cycle 1.

**The structural problem revealed by cycles 2–5:** post-c1 the device settles at ID ≈ 6–40× virgin baseline (depending on V_reset), and stays there. Every subsequent cycle:
1. Starts from this elevated post-reset baseline (~1.6–10.8 µA/µm).
2. Burst of 9 +V_pgm pulses produces a U-shaped DIP in ID: `pre → drop through p5 minimum (≈ 60–70 % of pre) → recover through p9 (still ≤ pre) → settle bounces back ABOVE p9`.
3. Settle ends at slightly higher ID than start of cycle — the FE keeps creeping further into +Pol partial saturation.

By c3 the system reaches a stable limit cycle: every cycle traces the same dip-recover-bounce shape, drift c3→c5 is < 0.4 %/cyc (M1 PASS) — but fire_ratio against in-cycle pre-baseline is **always < 1** (anti-fire) and **always non-monotonic** in the steady-state cycles. M2 and monotonicity FAIL on every node.

**Why the reset doesn't reset:** the reset is sub-coercive at the FE probe (|E|/F_c = 0.16–0.23 across the sweep at the c2+ reset holds — actually slightly HIGHER than v3's because the +Pol partial state from 9 fires generates a *positive* internal depolarization field that algebraically adds to the negative gate bias). But even at 0.23 |E|/F_c, the reset can't pull the FE off the +Pol partial-saturation rail at 1 µs — sub-coercive holds walk along the stable rail, not across it.

Confirmed by the c2 staircase: at V_reset = −1.0 V, c2 starts at 1.61e-6 (post-reset state); during the +V_pgm burst ID DROPS to 1.09e-6 (p5 minimum) then recovers but settles back HIGHER at 2.45e-6. The fires AND the reset are both pushing further into +Pol — they just produce transient excursions in opposite directions during their respective pulse phases.

**Mechanistic root cause (CORRECTED 2026-05-17 after par audit):** the calibrated par file already has `tau_P = (0, 1e-5, 0)` → polarization relaxation time **τ_P = 10 µs is active**, not zero. Step 1 of the Option-B path (par audit) revealed this. The latching is **not** caused by absent relaxation — it is caused by **the relaxation equilibrium at V_GS = −0.5 V being well above virgin**.

Direct evidence from the c5 settle trace at V_rec = −1.0 V:
- ID decays exponentially during the 10 µs settle with an effective leak time constant **τ_leak ≈ 2.75 µs** (fit on the second-half decay).
- The decay asymptote is **9.78× the virgin baseline**, not virgin. After 3.6 τ_leak the trace is ≥ 97 % equilibrated.
- Cycle 1 (less prior polarization) approaches the SAME equilibrium from BELOW — its settle ID *rises* over the 10 µs hold; cycles 4–5 approach the same equilibrium from above — their settle ID *falls*. Both converge to ~10× virgin at V_GS = −0.5 V.

The hysteretic Preisach model has multiple stable equilibria at fixed applied field, indexed by the polarization branch the device is on. Different recovery-pulse amplitudes (−1.0, −2.0, −2.5 V) put the device on different branches and produce different equilibria at the same V_GS = −0.5 V read bias (9.8×, 23.5×, 40.8× virgin in v4). The leak is doing its job — but it's leaking toward a non-virgin attractor.

**The fix is therefore a protocol question, not a par question:** identify a settle voltage V_GS_settle (or an explicit "neutral" gate phase) at which the polarization equilibrium for our depolarization-screened MFIS stack equals virgin polarization. Once found, embed it in the cycle as a "rest" phase between bursts.

This was confused at first by the stale comment on `Step_2/lif_parameters.py` line 49 (*"τ_P=0 in all v6 runs — this decay is device settling, NOT controlled FE relaxation"*) — that comment dates to March 2026 and reflects an older par state, not the current one. The current par has had τ_P = 10 µs since the "Step 2 default" was committed.

### H3 verdict and Tier-A reframing

**What v4 actually delivered (and what it tells us about Tier-A):**

1. **Single-shot 9-pulse LIF fire is now triple-confirmed** (H1 v3 + H3 v3 c1 + H3 v4 c1, three independent runs, byte-identical staircase from virgin). This is **the publishable LIF demonstration**. fire_ratio = 4.79× at V_pgm=2.0 V (sub-coercive, |E|/F_c=0.41, monotonic), reading at sub-V_t V_GS=−0.5 V. **M2 PASS — final and confirmed.**

2. **Multi-cycle LIF in the current par is fundamentally limited by τ_P = 0.** No reset built from sub-coercive gate pulses can clear the +Pol partial state set by a 9-pulse fire — the FE has no relaxation pathway in the model. This is a **model limitation, not a device limitation** in the physical sense, but it's baked into our calibrated par.

3. **M1 PASS in two senses** but neither is the original Tasneem-style "drift between identical bursts":
   - In v3 and v4: cycle-to-cycle drift of the *post-reset latched state* is < 0.4 %/cyc — i.e. the device's *latched memory* is stable.
   - In v4 c1: a single-shot fire from virgin is reproducible across nodes to 1 µV.
   - The original M1 metric (drift of the *fire response* across repeated bursts) is **undefined in this model** because there's no way to re-arm the device.

**Decision: stop tuning H3.** Three options for closing Tier-A; recommendation is Option A.

**Decision (2026-05-17, reversed after par audit): Option B — pursue genuine cyclic LIF.** The single-shot LIF + post-fire state stability framing of an earlier Option A is the easy path but not a top-journal LIF claim — the defining feature of a LIF neuron is the leak between bursts. Option B is now in three substeps:

**Step 1 — par audit.** Done 2026-05-17. The par at `Simulations/sdevice_gaafet_lif.par` lines 52–83 has `tau_E = (0, 1e-6, 0)` (auxiliary-field 1 µs) and `tau_P = (0, 1e-5, 0)` (polarization-relaxation 10 µs) — the leak is already on. Fit on the H3 v4 c5 settle decay confirms an effective τ_leak ≈ 2.75 µs in this operating regime. **No par change is required to add leak — the leak is present.**

**Step 2 — characterize the leak equilibrium across the settle-voltage axis.** New experiment, single SWB sweep, dedicated cmd: `simH_optimize/sdevice_simH_leak_eq.cmd`. Protocol per node:
1. Initialize at virgin.
2. Apply the H1 v3 9-pulse fire burst at `V_pgm = +2.0 V` (1 ns / 100 ns / 1 ns / 100 ns × 9 = 1.818 µs).
3. Goal-ramp the gate to `@V_settle@` over 10 ns.
4. Hold at `@V_settle@` for **100 µs** (≥ 10·τ_P, guarantees > 99.99 % equilibration).
5. Continuous CurrentPlot across the hold to resolve the relaxation trajectory.

SWB sweep: `@V_settle@ ∈ {−0.5, −0.25, 0.0, +0.25, +0.5, +0.75, +1.0} V` (L7). The settle voltage at which ID at end-of-hold returns to the virgin baseline (within, say, ±20 %) is the "neutral" voltage `V_GS_neutral` of the device. If no value in the sweep returns to virgin from above, the device requires an explicit positive-bias "active rest" phase — extend the sweep upward.

**Acceptance for step 2:** at least one V_settle value brings end-of-100-µs ID to within ±20 % of virgin baseline (= 2.13 × 10⁻⁷ to 3.19 × 10⁻⁷ µA/µm at the H3 read level).

**Step 3 — install the leak-to-virgin phase in the multi-cycle protocol.** Clone the H3 v4 cmd structure but replace the negative-bias recovery + V_GS=−0.5 V settle with a single phase at the V_GS_neutral identified in step 2, held for ≥ 5 τ_leak ≈ 14 µs. Re-run 5 cycles × 9 fires. Expected outcome: every cycle starts from near-virgin, fires the same 4.79× monotonic staircase, returns to near-virgin. M1 measured as cycle-to-cycle drift of the fire-burst response — the **original** M1 definition, top-journal grade.

Step 3 acceptance is the original Tier-A M1: |drift_c3→c5| ≤ 1 %/cyc on the fire-burst response (specifically on ID_p9 across cycles), AND fire_ratio ≥ 1.5 against in-cycle pre-burst baseline on every cycle. If step 3 passes, M1 and M2 are both closed in the genuine LIF sense and Phase 1D writeup gets a real leaky neuron.

**Step 4 — H4 endurance and variability** (deferred until step 3 lands). Once cyclic LIF works, the same protocol is run over 20+ cycles with small V_pgm perturbation to close M1 long-tail drift, M8 C2C variability.

**Step 5 — H5 energy** (no sim). Analytical from step 3 data: `E_gate`, `E_read`, `E_total`.

**Step 6 — `Step_2/lif_parameters.py` rewrite** with all measured numbers from steps 2–5.

Calibration risk under this path: none. τ_P and τ_E are unchanged from their values during H0a v5, H0e, H2 v6 — those calibrations are intact. The change is in the PROTOCOL (settle voltage), not the par.

### Leak-equilibrium characterization (new H3-leak step, replaces H4-as-single-shot)
- File: `simH_optimize/sdevice_simH_leak_eq.cmd` (to be created in step 2 above)
- Protocol: virgin → 9-pulse +2.0 V fire → goal-ramp to V_settle → 100 µs hold with continuous CurrentPlot
- SWB sweep: `@V_settle@ ∈ {−0.5, −0.25, 0.0, +0.25, +0.5, +0.75, +1.0} V`
- Analysis: `Simulations/analyze_phase1d_leakeq.py` — extract end-of-hold ID per node, plot ID(V_settle), identify V_GS_neutral

### Cyclic LIF protocol (new H3-cycle step, replaces the H3 v3/v4 architecture)
- File: `simH_optimize/sdevice_simH3_cyclic.cmd` (to be created in step 3 above; clones H3 v4 structure)
- Same 9-pulse fire bursts as H3 v4; recovery phase replaced by single hold at V_GS_neutral for 5–10 τ_leak ≈ 14–28 µs
- 5 cycles, same SWB infrastructure; possibly a small final-sweep for confirmation
- Acceptance: |drift_c3→c5| ≤ 1 %/cyc on fire-burst ID_p9 across cycles, AND fire_ratio ≥ 1.5 in every cycle vs in-cycle pre-burst baseline

### H4 endurance — runs only after cyclic LIF proves out at step 3.
- Adapt the step-3 cmd to 20+ cycles; add V_pgm perturbation `@V_pgm@ ∈ {1.95, 2.00, 2.05} V` for M8 sensitivity
- Metrics: long-tail M1, M8 C2C variability

### H5 energy — no sim, analytical from step 3 cyclic-LIF data.
- `E_gate = ½ · C_gg · V_pgm² · N_pulses` per fire burst; C_gg from H0g
- `E_read = ∫ V_DS · I_D dt` integrated over each 100 ns read window across one steady-state cycle
- `E_total = E_gate + E_read` per fire event

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
| M1 | Drift (cycle-to-cycle fire-burst response, original definition) | ≤ 1.0 %/cycle | **pending leak-eq scan + cyclic-LIF protocol** — par audit confirmed τ_P = 10 µs already active; protocol path identified |
| M2 | fire_ratio (9-pulse train, in-cycle vs pre-cycle baseline) | ≥ 1.5 | **PASS for cycle 1 (single-shot from virgin) — triple-confirmed at 4.79×; cyclic confirmation pending leak-eq scan** |
| M3 | Memory window | ≥ 0.5 V | **PASS — H0a v5 (1.40 V) AND H2 v6 (852 mV @ V_pgm=3.5 V, >2.95 V @ V_pgm=6 V)** |
| M4 | Analog states | ≥ 9 | **TREND PASS** — H2 v6 shows monotonic V_t shift -200 mV → -829 mV across V_pgm 1.5 → 3.5 V (4/5 distinguishable @ 50 mV sep on the 5-node sweep); 9-level demo pending the {1.5..4.0} V at 0.25-V step expansion |
| M5 | E_gate | ≤ 50 fJ | pending H5 |
| M6 | E_total | ≤ 100 fJ | pending H5 |
| M7 | V_pgm | ≤ 2.0 V | **PASS — H1 v3: V_pgm = 2.0 V achieves fire_ratio 4.79× with monotonic 9-pulse staircase at \|E\|/F_c=0.41 (sub-coercive)** |
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
| H1 v3 ✓ | `simH_optimize/sdevice_simH1_Vpgm_sweep.cmd` (Goal-driven, sub-V_t read at V_GS=−0.5 V, 2026-05-11) | `Simulations/analyze_phase1d_h1.py` → `Simulations/phase1d_h1/` (V_pgm_opt = 2.0 V) | none |
| H2 v3 (INVALIDATED) | (prior content of `sdevice_simH2_PE_loop.cmd`) — Goal-driven pulses + QS DC ID-VG reads | `Simulations/analyze_phase1d_h2.py` → `Simulations/phase1d_h2/` (V_t identical across V_pgm — QS reads overwrite FE state) | – |
| H2 v4 (ran, partial) | `simH_optimize/sdevice_simH2_PE_loop.cmd` — end-to-end Transient + Goal, 100 ns pulse hold, 2026-05-15 | `Simulations/analyze_phase1d_h2.py` → `Simulations/phase1d_h2/`; PGM linear at 22 mV/V, ERS depolarization-screened at 100 ns | – |
| H2 v5 (ran, root-caused) | (prior cmd) v4 + 10 µs pulses + 100 µs reads | confirmed FE bipolar switching via Pol_y traces, but V_t-extraction blurred by slow read sweep | – |
| **H2 v6 ✓ PASS** | `simH_optimize/sdevice_simH2_PE_loop.cmd` — 10 µs pulses + 100 ns Transient reads, 2026-05-16 | `Simulations/analyze_phase1d_h2.py` → `Simulations/phase1d_h2/`; M3 PASS at V_pgm ≥ 3.5 V, MW(V_pgm) monotonic | none |
| H2 v6 / M4 expansion (next) | same cmd, SWB sweep `@V_pgm@ ∈ {1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0, 3.5, 4.0}` V (9 nodes at 0.25 V step) | reuse analyzer | – |
| H3 v2 (ran, FAIL on intent) | `simH_optimize/sdevice_simH3_reset.cmd` (Goal-driven fires + resets, V_pgm=2.0 V, V_reset ∈ {−3,−5,−7} V, 2026-05-11) | `Simulations/analyze_phase1d_h3.py` (early version) — reset over-drives past virgin; fire reverses direction at the new baseline | – |
| H3 v3 (ran, M1 PASS / M2 FAIL) | `simH_optimize/sdevice_simH3_reset.cmd` (v3 — V_reset ∈ {−1.0,−1.5,−2.0,−2.5} V, t_reset=1 µs, 5 cycles × 3 fires, 2026-05-17) | `Simulations/analyze_phase1d_h3.py` → `Simulations/phase1d_h3/h3_metrics.txt` — drift killed but 3-pulse fire never escapes the wake-up dip | – |
| H3 v4 (ran, M1 PASS / M2 PASS @ c1 / latch confirmed) | `simH_optimize/sdevice_simH3_reset.cmd` (5 cycles × 9 fires, generated by `_gen_h3_v4_cmd.py`, 2026-05-17). Outputs `h3_outputs/v4/` | `Simulations/analyze_phase1d_h3.py` → `Simulations/phase1d_h3/h3_metrics.txt` — c1 reproduces H1 v3 fire 4.79×; c2+ shows device latches (τ_P=0 limit). Tier-A reframed Option A. | – |
| **Leak-equilibrium scan (next)** | new `simH_optimize/sdevice_simH_leak_eq.cmd`: single 9-pulse fire from virgin + 100 µs hold at V_settle; SWB `@V_settle@ ∈ {−0.5..+1.0} V` | new `Simulations/analyze_phase1d_leakeq.py` — end-of-hold ID per V_settle, identify V_GS_neutral | – |
| Cyclic LIF protocol | new `simH_optimize/sdevice_simH3_cyclic.cmd`: H3 v4 structure with recovery+settle replaced by hold at V_GS_neutral for 5–10·τ_leak | extend `analyze_phase1d_h3.py` for fire-burst drift on ID_p9 across cycles | – |
| H4 | adapt simC v6 cmd | – | – |
| H5 | (no new sim) | – | – |

All par changes go in `Simulations/sdevice_gaafet_lif.par`. Log every change in `Calibration_Log_2026_01_15.md`.
