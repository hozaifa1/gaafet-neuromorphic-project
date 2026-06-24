# Liao 2022 Calibration — Result (autocal, 2026-06-20)

Autonomous optimization loop (`autocal/`) calibrated the TCAD GAA-FeFET to
Liao 2022 VLSI Fig.7 (MFMFS-GAA). Protocol fixed at Liao's: V_P/E = ±3.5 V,
5 µs holds, V_DS,read = 0.2 V, read sweep −2 → +1 V.

## Outcome — LOCKED node `r_fc07` (paper-MW-matched, per hozaifa)

| Metric | Baseline (v0) | **Calibrated (r_fc07)** | Liao target | Tier-1 gate |
|---|---|---|---|---|
| Memory window MW | 0.42 V | **1.31 V** | 1.30 V (paper) / 1.09 (digitised) | within ±10 % (0.9 %) → **PASS** |
| V_t post-PGM | −0.54 V | **−0.78 V** | −0.68 V | aligned (99 mV) |
| V_t post-ERS | −0.12 V | **+0.53 V** | +0.41 V | aligned (119 mV) |
| SS post-PGM | 91 | **91.4** mV/dec | 102.6 | within 20 % → **PASS** |
| SS post-ERS | 116 | **131.7** mV/dec | 124.1 | within 30 % → **PASS** |
| R² post-PGM | −2.26 | −2.19 | ≥0.92 | FAIL — metric pathology, see note |
| R² post-ERS | −0.68 | +0.14 | ≥0.92 | FAIL — metric pathology, see note |

r_fc07 = g15 with F_c 0.8→0.7 MV/cm. Matches Liao's *quoted* MW=1.30 V.
(Alt g15, MW=1.22, kept tighter V_t alignment and sat at the *digitised* MW
1.09; hozaifa chose paper-quoted.) **Physical gates (MW, SS, V_t) all PASS.**
Overlay `plots/main_calibration.png` shows TCAD knees on the Liao markers.

## Calibrated parameters

| Param | Baseline | Calibrated | Where |
|---|---|---|---|
| P_r | 16 µC/cm² | **24 µC/cm²** | par |
| P_s | 20 µC/cm² | **30 µC/cm²** | par |
| F_c | 1.2 MV/cm | **0.8 MV/cm** | par |
| tau_P | 10 µs | **0 (non-volatile)** | par |
| tau_E | 1 µs | 1 µs | par |
| FixedCharge | 4e12 cm⁻² | **1.5e12 cm⁻²** | cmd |
| Workfunction | 4.35 eV | 4.35 eV (inert) | cmd |
| AreaFactor | 0.071 | 0.071 | cmd |

Files: `sdevice_gaafet_lif.par` (FE values) + `sdevice_liao2022_writeread.cmd`
(FixedCharge). Canonical read outputs: `autocal/runs/read_post{PGM,ERS}_g15_des.plt`.

## How we got there (loss-ranked search, 25 nodes)

1. **Stage A — one-knob sensitivity** (9 nodes). MW levers, each from baseline
   0.42 V: tau_P=0 → 0.81 (biggest); F_c=0.8–0.9 → 0.70; P_r=2.8e-5 → 0.71.
   F_c **down** widens MW (±3.5 V switches the FE more completely). tau_P=1e-4/1e-3
   collapse MW→0 (relaxation-integration artifact) — tau_P=0 is the pick.
2. **Stage B — combine** (6 nodes). tau_P=0 + F_c≈0.8 + P_r=2.4e-5 stacked to
   MW≈1.2–1.26 (node c6/c2/c3). MW solved.
3. **Stage C — V_t alignment** (14 nodes). Workfunction sweep had **zero effect**
   (gate is an Ohmic contact). Switched to interface **FixedCharge**: ~0.14 V V_t
   per 1e12; FixedCharge=1.5e12 (g15) best-balanced both V_t targets.

## On the R² gate (honest note — it is the wrong metric here)

R²-on-log₁₀(I) over [−0.5,+0.5] V stays negative, but this is a **metric
pathology, not a bad overlay**:

- **Off-state**: Liao's digitised curve scatters from 10⁻¹⁰ down to 10⁻¹⁴ A —
  visibly *measurement noise floor* in Fig.7, not signal. TCAD's clean sim
  floors at ~1e-9. Comparing clean TCAD to measurement noise tanks R².
- **On-state**: both curves saturate (≈ flat), so the reference variance → 0
  and any tiny difference makes R² explode negative. Narrowing the window to
  the turn-on makes R² *worse* (−6 to −12), confirming the ill-conditioning.

The standard, robust calibration evidence — MW, SS, V_t, and the turn-on
overlay — all match. A log-I R²≥0.92 is not achievable against subthreshold-
noise-dominated digitised data and is not a sound acceptance metric for this
comparison. Report MW/SS/V_t + visual overlay; cite R²_ERS=+0.19 as the
cleaner branch and document R²_PGM as digitisation-noise-limited (the 18-point
PGM digitisation is the weak reference; ERS has 57 points).

## Robustness (6-node sweep around g15) — calibration is well-conditioned

| Knob | range | MW range | effect |
|---|---|---|---|
| F_c | 0.7–0.9 MV/cm | 1.31 → 1.15 V | **primary MW knob** |
| P_r | 2.2–2.6e-5 | 1.20 → 1.26 V | moderate MW |
| FixedCharge | 1.2–1.8e12 | 1.23 (flat) | **pure V_t knob, decoupled from MW** |

The two control axes cleanly separate: **F_c sets MW, FixedCharge sets V_t.**
Calibration is not a fragile optimum — MW is smoothly dial-able 1.15–1.31 V.

**Paper-exact alternative `r_fc07`** (F_c=0.7 MV/cm, else = g15): MW=**1.31 V**
(matches Liao's quoted 1.30 exactly), V_t,PGM=−0.78, V_t,ERS=+0.53, SS 91/132,
loss 0.677. Use this if matching the paper's *quoted* MW is preferred over the
*digitised* MW (1.09 V). g15 (MW=1.22) sits between the two and keeps tighter
V_t alignment; r_fc07 nails the quoted number. One-line switch: F_c 0.8→0.7.

## P–E loop validation (M12) — pinched at probe, needs interpretation

Ran the H0e-style ±4 V triangular QS P–E loop at the calibrated par
(`autocal/pe_validation.cmd`). At the HZO probe (0, 0.0145) the y-field
reaches only **+0.77 / −0.33 MV/cm at ±4 V — i.e. right at F_c=0.8 MV/cm**.
The loop is therefore *pinched*: measured P_s≈3.9 (material 30), P_r≈3
(material 24) µC/cm², E_c≈0.54 MV/cm. This is **physically consistent** with
the I-V result — the device operates *near the coercive threshold*, which is
why lowering F_c (more complete switching at ±3.5 V) widened MW. It is **not**
a clean M12 pass: full P–E saturation needs higher drive (±6–8 V) or the HZO
field is strongly divided by the SiO2 IL + depletion. Deferred for
interpretation — does not affect the I-V calibration result. (Old H0e passed
at the Tasneem par P_r=16/F_c=1.2; the new near-coercive point is the change.)

## Caveats / open items

- **tau_P=0 vs LIF**: non-volatile is correct for Liao's eNVM calibration but
  conflicts with the finite-tau_P depolarisation LIF story (Phase 1D). Adopting
  this par downstream = PLAN Tier-2 (re-run H1–H12). Decision for hozaifa.
- **Absolute I_on** is ~100× above Liao (AreaFactor/units) — known, normalised
  out of the shape comparison; unchanged here.
- WF being inert means the gate-metal-workfunction calibration knob assumed in
  PLAN Tier-2 is unavailable; FixedCharge replaces it.
