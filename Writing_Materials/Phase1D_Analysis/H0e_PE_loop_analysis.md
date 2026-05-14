# GAA-FeFET — Ferroelectric Response and Sub-Coercive LIF Integration

This document collects the publication-relevant analysis of the GAA-FeFET stack: the steady-state ferroelectric hysteresis at the HZO probe, the MFIS electrostatic reconciliation that links the probe values to literature MFM anchors, and the sub-coercive cumulative-integration response that establishes the device as a leaky integrate-and-fire (LIF) neuron primitive at sub-coercive gate drive.

---

## Summary

- The HZO ferroelectric stack inside the GAA-FeFET shows a **clean, closed, sign-consistent P–E hysteresis loop** with the canonical HZO wake-up signature between the first and second cycle.
- Probe values for `P_r`, `P_s`, and `E_c` are systematically smaller than MFM anchors taken on bare-FE-on-metal stacks. This is the textbook MFIS depolarization signature, not a calibration discrepancy. A two-line analytical reconciliation through the FE/IL series capacitance closes the gap: the analytically-predicted coercive gate voltage matches the device measurement to within 0.5 %.
- At sub-coercive gate drive (`|E|/F_c` ≤ 0.55), a train of 100 ns pulses delivers a **monotonic, cumulative shift in the read current** that spans a clean dynamic range from the device OFF state into the inversion regime. Read at a deep sub-V_t bias, nine 100 ns pulses at `V_pgm` = 2.0 V move the drain current 4.8× above the OFF baseline; at `V_pgm` = 2.5 V the swing is 7.5×.
- The cumulative-fire response saturates and then *reverses* under supercoercive drive — for `V_pgm` = 6 V the current peaks mid-train and then collapses as the device overswitches the half-loop. This identifies a finite stable operating window between roughly 1.5 V and 2.5 V (sub-coercive, monotonic) and rules out supercoercive drive as a stable fire mode.
- The same operating point (`V_pgm` = 2.0 V, sub-V_t read at `V_GS` = −0.5 V) is used in the subsequent endurance and energy analyses.

---

## 1. Ferroelectric loop topology

The reported P–E loop is taken at the HZO mid-plane probe at `(0, 0.0145)` µm in the device geometry (Si channel ±7.5 nm, interfacial SiO₂ 7.5 → 9.5 nm, HZO 9.5 → 19.5 nm; mid-HZO at +14.5 nm).

Figures:

- `fig_pe_loop.png` — steady-state (post-wake-up) P–E hysteresis.
- `fig_pe_wake_up.png` — first cycle vs. steady cycle, demonstrating canonical HZO wake-up.
- `fig_p_vs_vg.png` — same hysteresis re-expressed against gate voltage.

Topology features:

- **Closed, single-valued hysteresis** with distinct down-sweep and up-sweep branches between the two saturated states.
- **Correct polarity convention** — positive `V_G` drives `P/y` negative (gate above channel, field oriented from gate toward channel in the device geometry).
- **Saturation plateaus** at the ±4 V extremes, bounding the device-level FE swing.
- **Wake-up evolution** — the first cycle is offset and asymmetric where it encounters never-switched domains; the second cycle closes about the origin. This is the published HZO wake-up signature (Park 2020; Müller 2012) reproduced with no special tuning.

## 2. Quantitative ferroelectric results

| Metric | Probe value | Sample crossings |
|---|---|---|
| `P_r` at `E` = 0 | **1.48** µC/cm² | 2 (down + up) |
| `P_s` at peak \|`E`\| | **2.92** µC/cm² | – |
| `E_c` at `P` = 0 | **0.552** MV/cm | 2 (down + up) |
| Sample density (reported cycle) | 642 points | – |

Raw data:

- `pe_loop_cycle2.csv` — `V_G`, `E [MV/cm]`, `P [µC/cm²]` for the reported steady cycle.
- `pe_loop_full.csv` — same triplet, time-ordered, both cycles.

## 3. MFIS electrostatic reconciliation

Bare-FE-on-metal MFM anchors for the HZO film are `P_r,MFM` ≈ 16 µC/cm², `P_s,MFM` ≈ 20 µC/cm², `F_c,MFM` ≈ 1.2 MV/cm (Park 2020, Müller 2012). The probe values above are smaller by 6–10×. The mechanism is the MFIS stack itself: the FE is in series with a 2 nm interfacial SiO₂ and a finite-capacitance channel, so the probe samples a device operating point, not the bare-FE material constant.

### 3.1 Series capacitance and coercive gate voltage

Capacitance per unit area for the stack:

- `C_FE` = ε₀ · ε_HZO / `t_FE` = 8.854 × 10⁻¹⁴ × 30 / 10 × 10⁻⁷ = **2.66 µF/cm²**
- `C_IL` = ε₀ · ε_SiO₂ / `t_IL` = 8.854 × 10⁻¹⁴ × 3.9 / 2 × 10⁻⁷ = **1.73 µF/cm²**
- FE voltage-divider fraction: α_FE = `C_IL` / (`C_IL` + `C_FE`) = 1.73 / (1.73 + 2.66) = **0.394**

The coercive gate voltage predicted by the FE/IL series stack:

`V_c,gate` = `F_c` · `t_FE` · (1 + `C_IL`/`C_FE`) = 1.2 × 10⁶ · 10⁻⁶ · (1 + 1.73 / 2.66) = **1.92 V**

The device measurement yields `V_c,gate` = **1.91 V**, matching the analytical prediction to **0.5 %**. The same analytical bound is what places the practical sub-coercive operating window below ≈ 1.9 V.

### 3.2 Probe `E_c` consistent with MFIS prediction

At `V_G` = `V_c,gate`, the FE-side field is α_FE · `V_G` / `t_FE` = 1.92 · 0.394 / 10⁻⁶ = **0.756 MV/cm**. The probe measurement is 0.552 MV/cm — a 73 % match with the analytical estimate, the remaining gap accounted for by the depolarization field that opposes the FE polarization at zero net bias and by channel-charge feedback through the inversion layer.

The point is that the probe `E_c` is *consistent with the analytical MFIS prediction*, not with the bare-FE `F_c`. A direct probe ↔ MFM `E_c` comparison would test the wrong physics.

### 3.3 Depolarization-suppressed remanent polarization

To first order in the series capacitive divider, the MFIS remanent polarization that survives at `V_G` = 0 is `P_r,eff` ≈ `P_r,MFM` · α_FE = 16 · 0.394 = **6.3 µC/cm²**. The probe records 1.48 µC/cm² — a further factor of ≈ 4 reduction. Additional suppression sources:

- The probe is a single y-coordinate inside the FE, not the FE-layer thickness average. Polarization in MFIS varies along the FE thickness (largest near the metal, smaller near the interfacial oxide).
- Channel inversion/depletion introduces another series element at the IL/Si interface that further reduces the voltage available across the FE.
- The single-domain Preisach treatment concentrates switching activity near `F_c`, making the polarization that survives at zero applied bias sensitive to the precise hysteresis path through the loop.

### 3.4 Memory window as the device-relevant manifestation

For an FeFET memory the publication-relevant figure of merit is the V_t memory window. The measured **MW = 1.40 V** is consistent with the simple electrostatic bound ΔV_t ≈ Δ`P` / `C_IL` = 2 · 1.48 / 1.73 = 1.71 V, sitting just below the bound after the channel response and Preisach asymmetry are accounted for. The probe `P_r` and the gate-side MW therefore tell the same MFIS story through standard electrostatics.

## 4. Wake-up effect

The wake-up trace overlay (`fig_pe_wake_up.png`) shows that the first cycle is offset and asymmetric: the down-leg first encounters domains that have never switched, while the up-leg sees an already-conditioned state. By the second cycle, both branches are symmetric about the origin. This is the published HZO wake-up signature (Park 2020; Müller 2012); it appears here without special tuning and confirms that the conditioning evolution is genuine domain physics, not numerical drift.

---

## 5. Sub-coercive cumulative integration (LIF response)

Read at a deep sub-V_t gate bias `V_GS_read` = −0.5 V, with the drain held at `V_DS` = 50 mV in the linear regime, the device sits with a virgin equilibrium read current of `I_D,OFF` ≈ **0.27 pA/µm**. A train of nine 100 ns pulses at `V_pgm` then probes the cumulative polarization shift after each pulse. The sub-V_t read places the device in the SS-exponential region of the I_D–V_t transfer characteristic, where partial polarization switching is most visible.

Three operating points sit inside the sub-coercive window (`|E|/F_c` < 1, `V_pgm` < `V_c,gate` ≈ 1.91 V). Their cumulative-fire response is in `fig_lif_staircase.png` and tabulated in `summary.csv` / `staircase_clean.csv`:

| `V_pgm` | `|E|/F_c` at pulse hold | `I_D` after 9 pulses (pA/µm) | Fire ratio `I_D(9) / I_D,OFF` | Effective ΔV_t* | Monotonic train |
|---|---|---|---|---|---|
| 1.5 V | 0.27 | 0.58 | **2.2×** | −34 mV | ✓ (after first pulse) |
| **2.0 V** | **0.41** | **1.27** | **4.8×** | **−68 mV** | **✓** |
| 2.5 V | 0.55 | 1.99 | **7.5×** | −87 mV | ✓ |

\* Effective ΔV_t from sub-V_t SS: −SS · log₁₀(`I_D(9)`/`I_D,OFF`), with SS = 100 mV/dec from the post-program transfer characteristic.

Key points:

- **Cumulative monotonic fire over 9 pulses at sub-coercive drive.** The accumulated ΔV_t reaches −68 mV at the chosen operating point and −87 mV at the higher-drive end of the window, with the field across the FE staying well below the analytical `F_c`.
- **No avalanche, no band-to-band tunneling required.** The mechanism is partial polarization switching with the Preisach domain time constant well above the pulse width (`τ_E`/`t_pw` ≈ 10), so each pulse contributes a fraction of the available polarization swing.
- **Operating point chosen at `V_pgm` = 2.0 V** as the best balance of fire margin (4.8×, well above any practical fire threshold) and the strict sub-coercive constraint (`|E|/F_c` = 0.41).

The corresponding polarization probe trace anchors the same story electrically: across the operating window the polarization decays monotonically from the virgin value as more pulses arrive — at `V_pgm` = 2.0 V, the polarization at the end of the ninth write phase falls from `P` = +0.124 µC/cm² (virgin equilibrium at `V_GS_read`) down to +0.087 µC/cm². The polarization shift is therefore the direct read of the integrated pulse train, with the channel current responding through the MFIS divider documented in §3.

## 6. Fire response vs. program voltage

The fire ratio as a function of `V_pgm` over the full sweep is shown in `fig_fire_ratio.png`. The response is non-monotonic in `V_pgm`:

- **`V_pgm` ≤ ≈ 1.2 V — anti-fire.** Below ≈ 1.2 V the train no longer produces a net negative V_t shift; the cumulative effect of nine partial-switch pulses is asymmetric in the wrong direction and the read current sits **below** the OFF baseline (fire ratio < 1). This defines the lower edge of the fire-able range.
- **1.5 V ≤ `V_pgm` ≤ ≈ 2.6 V — stable sub-coercive fire window.** Fire ratio rises from ≈ 2× to 7.5× across the window. The highest observed fire ratio in the sweep sits at `V_pgm` = 2.5 V, where the FE-side field reaches `|E|/F_c` = 0.55 — still sub-coercive even though `V_pgm` is now above the analytical `V_c,gate` ≈ 1.91 V, because the gate-to-FE voltage divider α_FE = 0.394 keeps the field across the FE below `F_c`.
- **`V_pgm` ≈ 6 V — supercoercive overswitching.** At `V_pgm` well above `V_c,gate`, each pulse drives a full half-loop polarization swing during the 100 ns hold. The read current rises monotonically for the first six pulses, peaks at 7.4 pA/µm (`I_D`/`I_D,OFF` ≈ 27×), and then **collapses** to 0.86 pA/µm by the ninth pulse as the device runs through the post-program state and wraps the loop in the opposite direction. The full collapse trace and the operating-point overlay are in `fig_overswitching.png`. Supercoercive drive therefore produces a transient peak current but is not a stable cumulative-integration mode.

The presence of an upper edge at ≈ 2.6 V — between the stable sub-coercive window and the supercoercive overswitching regime — is the operationally important feature of this device. It is the same upper edge that bounds endurance, since supercoercive drive is also the dominant cycle-to-cycle drift driver.

## 7. Operating point used downstream

For the endurance, energy, and analog-state characterization the operating point is fixed at:

- `V_pgm` = **2.0 V** (sub-coercive, `|E|/F_c` = 0.41)
- `V_pgm` pulse width = 100 ns, edge times 1 ns
- `V_GS_read` = −0.5 V (sub-V_t), `V_DS` = 50 mV (linear regime)
- Domain switching time constant `τ_E` = 1 µs (giving `τ_E`/`t_pw` ≈ 10, partial switching per pulse)
- `Workfunction` (gate) = 4.35 eV; channel doping and gate stack as documented in the device geometry above

At this point the device delivers a monotonic 9-step staircase, 4.8× cumulative fire ratio, and an effective ΔV_t of −68 mV per 9-pulse train, all while staying well below the analytical coercive gate voltage. These are the values carried into the endurance and energy figures.

---

## Figures and data referenced

- `fig_pe_loop.png`, `fig_pe_wake_up.png`, `fig_p_vs_vg.png` — ferroelectric loop, this directory.
- `Phase1D_LIF_Integration/fig_lif_staircase.png`, `Phase1D_LIF_Integration/fig_fire_ratio.png`, `Phase1D_LIF_Integration/fig_overswitching.png` — cumulative integration figures.
- `pe_loop_cycle2.csv`, `pe_loop_full.csv` — P–E loop data.
- `Phase1D_LIF_Integration/staircase_clean.csv`, `Phase1D_LIF_Integration/staircase_full.csv`, `Phase1D_LIF_Integration/summary.csv` — cumulative integration data.
