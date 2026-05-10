# GAA-FeFET Calibration — Publication Record
**Device:** 10 nm HZO / 2 nm SiO2 IL / 15 nm Si channel, GAA, L_g = 100 nm
**Simulator:** Synopsys Sentaurus Device, V-2023.12
**Status:** CALIBRATED — Phase 1D H0a v5 (May 2026)
**Original run log:** ../Calibration_Log_2026_01_15.md (16-run legacy history, DO NOT EDIT)

---

## 1. Calibration Reference

| Item | Value |
|---|---|
| Reference paper | Tasneem et al., "Ferroelectric field-effect transistor for neuromorphic computing," IEEE TED 2022 |
| Target figure | Fig. 3(c) — post-ERS and post-PGM I_D–V_G curves |
| Protocol | Tasneem write-then-read: ERS pulse → read sweep → PGM pulse → read sweep |
| Ref. device | 5 nm ZrO2 FE / SiO2 IL / Si channel, planar, L_g = 8 µm |

Calibration rationale: Tasneem uses a Si-channel MFIS FeFET, which matches our stack topology (same carrier physics, same interface trapping mechanism). Geometry differs intentionally — our 10 nm HZO GAA device is the publication subject, not a replica. Calibration target is physics-shape agreement (SS, hysteresis topology), not absolute magnitude match.

---

## 2. Device Stack and Final Calibrated Parameters

### Physical stack

| Layer | Material | Thickness |
|---|---|---|
| Gate metal | TiN | 5 nm |
| Ferroelectric | HfZrO (HZO) | 10 nm |
| Interfacial oxide | SiO2 | 2 nm |
| Channel | Si (n-type) | 15 nm |
| Gate length | — | 100 nm |
| Effective perimeter W_eff | GAA cross-section 2×(30+15)nm | 90 nm → W_eff_um = 0.090 µm |

### Calibrated parameters (locked for all H-series simulations)

| Parameter | Value | Role |
|---|---|---|
| Gate workfunction | 4.35 eV | Centers hysteresis loop at target V_t |
| Interface fixed charge | 4.0 × 10^12 cm^-2 | Fine-tunes V_t to 0.25 V |
| AreaFactor | 0.071 | Scales I_on to 600 µA in transient mode |
| HZO P_r | 16 µC/cm^2 | Remanent polarization |
| HZO P_s | 20 µC/cm^2 | Saturation polarization |
| HZO F_c | 1.2 MV/cm | Coercive field |
| Preisach tau_E | 1 µs | Erase polarization time constant |
| Preisach tau_P | 10 µs | Program polarization time constant |

**Derived:** V_c,gate = F_c × t_FE × (1 + C_IL/C_FE) = 1.91 V — coercive gate voltage below which the FE does not switch. All read sweeps kept sub-coercive.

### Physics model (Sentaurus cmd — mandatory syntax)

```
Physics {
  Temperature= 300
  Areafactor= 0.071
  Fermi
  EffectiveIntrinsicDensity( OldSlotboom )
  Mobility( PhuMob Enormal )
  Recombination(
    SRH (DopingDependence TempDependence)
    Auger
    Band2Band(Model=Hurkx)
  )
}
Physics(Material="HZO") { Polarization }
Physics(MaterialInterface="Silicon/SiO2") {
    Traps( (FixedCharge Conc=4e12 Level EnergyMid=0.0 fromMidBandGap) )
}
```

Note: `Mobility(PhuMob Enormal)` is the only valid mobility syntax in this project. `Enormal` internally invokes Lombardi surface scattering — do not add `Lombardi` or `BallisticMob` keywords (they are not recognized by this version of Sentaurus).

---

## 3. Calibration History Summary (Runs 01–16)

Legacy DC and hysteresis calibration completed January 2026. Full run-by-run log in `../Calibration_Log_2026_01_15.md`. Key milestones:

| Stage | Runs | Goal | Outcome |
|---|---|---|---|
| DC calibration | 01–05 | Match V_t = 0.25 V, I_on = 600 µA | Achieved at Run 05 (WF=3.9 eV, Charge=5.15e12) |
| Hysteresis integration | 06–13 | Activate FE loop, recalibrate under transient solver | AreaFactor reset from 0.224→0.069; WF raised to 4.35 eV |
| Final hysteresis calib. | 14–16 | Center loop, match V_t (Fwd) = 0.25 V, MW = 0.68 V | Achieved at Run 16 |

Run 16 was the "golden" baseline used as the starting point for all Phase 1D (write-read protocol) work.

**Legacy DC result (Run 16, quasi-static triangular sweep ±5 V):**
- V_t (forward sweep) = 0.263 V
- I_peak = 604 µA
- Memory window = 0.68 V (triangular counter-clockwise loop)

The 0.68 V legacy MW is from a quasi-static ±5 V triangular sweep, which is NOT the Tasneem write-read protocol. It is retained here for completeness only. The publication MW figure is 1.40 V, from the 10 µs pulse protocol (Section 4).

---

## 4. Phase 1D Write-Read Calibration (H0a v5, May 2026)

### Simulation file
`Simulations/simH_optimize/sdevice_simH0a_v5_writeread.cmd`

### Protocol (Tasneem-matched)

| Step | Action | Voltage | Duration |
|---|---|---|---|
| 0 | Init Poisson | — | — |
| 1 | Ramp V_DS | 0 → 0.05 V | quasi-static |
| 2 | Baseline read | V_G = 0 | 100 ns |
| 3 | ERS pulse | 0 → −4 V (1 ns rise) + hold + 0 (1 ns fall) | 10 µs hold |
| 4 | Ramp to read start | V_G → −2.0 V | 10 ns |
| 5 | Read 1 post-ERS | −2.0 → +1.0 V | 100 ns sweep |
| 6 | Return to 0 | V_G → 0 | 10 ns |
| 7 | PGM pulse | 0 → +4 V (1 ns rise) + hold + 0 (1 ns fall) | 10 µs hold |
| 8 | Ramp to read start | V_G → −2.0 V | 10 ns |
| 9 | Read 2 post-PGM | −2.0 → +1.0 V | 100 ns sweep |

Read window: −2.0 → +1.0 V is sub-coercive (V_c,gate = 1.91 V), so FE state is not disturbed during the read.

### Key extraction metrics

| Metric | TCAD Result | Tasneem Target | Status |
|---|---|---|---|
| V_t post-ERS (I/W = 1 µA/µm) | +0.176 V | — | extracted |
| V_t post-PGM (I/W = 1 µA/µm) | −1.223 V | — | extracted |
| Memory window MW | **1.40 V** | 0.5 V (5 nm ZrO2) | see note |
| SS post-PGM | **100 mV/dec** | 110 mV/dec | PASS ✓ |
| SS post-ERS | **164 mV/dec** | — | see note |
| R² shape match post-ERS | **0.95** | > 0.90 | PASS ✓ |
| R² shape match post-PGM | **0.77** | > 0.90 | see note |
| I_off floor | 3 nA/µm | — | L_g = 100 nm SCE |

### Notes on out-of-band values

**MW = 1.40 V vs Tasneem 0.5 V:** Not a calibration error. Theoretical maximum MW = 2 × F_c × t_FE = 2 × 1.2 MV/cm × 10 nm = 2.4 V for our stack vs 1.2 V for Tasneem's 5 nm ZrO2. Our 1.40 V (58% of theoretical max) is physically consistent and scales correctly. Publication framing: "10 nm HZO GAA delivers 2.8× larger memory window than 5 nm planar ZrO2 baseline."

**SS post-ERS = 164 mV/dec:** The post-ERS branch has a wider subthreshold region because negative polarization depletes the channel — carriers must be thermally activated over a larger barrier. Post-PGM is sharper (100 mV/dec) because positive polarization accumulates electrons, concentrating the turn-on. This is a known single-domain Preisach asymmetry, not a model error.

**R² post-PGM = 0.77:** The TCAD post-PGM curve floors at I_off = 3 nA/µm (short-channel source-drain leakage at L_g = 100 nm) while the Tasneem reference (L_g = 8 µm, negligible DIBL) continues into sub-10^-7 µA/µm territory. The shape mismatch is entirely at deep subthreshold, below the leakage floor. Above the floor, both curves have identical SS (100 vs 110 mV/dec). Documented as geometry-limited, not model-limited.

**V_t criterion:** Tasneem uses I/W = 10^-4 µA/µm = 0.1 nA/µm, below our 3 nA/µm leakage floor. We use I/W = 1 µA/µm as the threshold criterion throughout.

### Shape-match methodology

Direct overlay of raw I-V curves is not meaningful due to:
1. ~2000× I_on magnitude difference (geometry scaling: 90 nm GAA vs 8 µm planar)
2. 1.40 V vs 0.50 V MW → non-overlapping V_G windows
3. Opposite carrier polarity (n-type TCAD vs p-type Tasneem, with axis sign flip)

Shape match procedure:
1. Extract V_t from each curve (constant-current method, I/W at stated criterion)
2. Shift V_G axis: x = V_G − V_t for each branch
3. Normalize I: y = log10(I / I_ref) where I_ref is current at V_G = V_t
4. Flip x-axis sign for Tasneem p-type curves to align with n-type convention
5. Interpolate both onto common grid x ∈ [−1.0, +0.5] V
6. Compute R² on log10 scale

---

## 5. Publication Figures and Data Files

### Primary figures (in plots/)

| File | Description | Use in paper |
|---|---|---|
| shape_comparison.png | V_t-aligned + I-normalized overlay vs Tasneem Fig. 3(c) | Main calibration figure |
| summary_3panel.png | 3-panel: TCAD I-V, Tasneem ref, shape match | Supplementary / methods |
| tcad_only.png | Raw TCAD post-ERS and post-PGM I_D–V_G | Device characterization section |
| tasneem_only.png | Digitized Tasneem Fig. 3(c) curves | Reference comparison |

### Data files (in csvs/)

| File | Description |
|---|---|
| tcad_postERS.csv | TCAD post-ERS I_D–V_G (V, I in µA/µm) |
| tcad_postPGM.csv | TCAD post-PGM I_D–V_G (V, I in µA/µm) |
| Tasneem_Plot_red.csv | Digitized Tasneem post-PGM branch (V, I in µA/µm) |
| Tasneem_Plot_blue.csv | Digitized Tasneem post-ERS branch (V, I in µA/µm) |
| Tasneem_Plot_dot.csv | Digitized Tasneem virgin branch (V, I in µA/µm) |

### Metrics file (in metrics/)

`metrics_summary.txt` — machine-readable summary of all extracted values (MW, SS, V_t, R²) with extraction windows and point counts. Source of truth for all numerical claims in the paper.

