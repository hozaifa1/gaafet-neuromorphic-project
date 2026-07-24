# Planar FeFET Dimension Update & Simulation Re-run Plan

## 1. Overview & Motivation

The initial Planar FeFET baseline was constructed using a **$100\text{ nm}$ gate length ($L_{\text{gate}}$)** and a **$10\text{ nm}$ HZO ferroelectric layer**. While this established a strong reference, the **$100\text{ nm}$ dimension will not work for the final manuscript comparison** because:

1. **Unfair Dimension Mismatch:** The optimized GAA Nanosheet FeFET uses a scaled channel length ($L_{\text{gate}} = 30\text{ nm}$) and a thinner ferroelectric layer ($T_{\text{fe}} = 7\text{ nm}$, $T_{\text{ox}} = 1\text{ nm}$). Comparing a long-channel ($100\text{ nm}$) Planar device against a short-channel ($30\text{ nm}$) GAA device introduces artificial technological bias.
2. **Artificial Memory Window Expansion:** The $100\text{ nm}$ Planar device exhibits an artificially large memory window ($>1.94\text{ V}$) and an inflated ON/OFF ratio ($5.91 \times 10^6 \times$) primarily because it completely avoids Short-Channel Effects (SCE) and benefits from a thicker $10\text{ nm}$ ferroelectric switching layer.
3. **Apples-to-Apples Validity:** To publish a rigorous geometry-only comparison in the manuscript, the Planar device **must be re-simulated with identical gate stack and channel length dimensions** as the GAA FeFET.

---

## 2. Targeted Dimensional Changes for Re-simulation

| Dimension / Parameter | Previous (Current) Planar | New Scaled Planar (To Run) | GAA Target Baseline | Rationale |
|---|---|---|---|---|
| **Gate Length ($L_{\text{gate}}$)** | $100\text{ nm}$ ($0.100\ \mu\text{m}$) | **$30\text{ nm}$** ($0.030\ \mu\text{m}$) | $30\text{ nm}$ | Matches short-channel scaling of GAA node |
| **Ferroelectric Thickness ($T_{\text{fe}}$)** | $10\text{ nm}$ | **$7\text{ nm}$** | $7\text{ nm}$ HZO | Identical ferroelectric volume & coercive voltage drop |
| **Interfacial Oxide ($T_{\text{ox}}$)** | $2.0\text{ nm}$ | **$1.0\text{ nm}$** | $1.0\text{ nm}$ $\text{SiO}_2$ | Equal capacitive voltage divider ratio |
| **S/D Overlap ($L_{\text{ov}}$)** | $15\text{ nm}$ | **$5\text{ nm}$** | $5\text{ nm}$ | Scaled extension overlap for $30\text{ nm}$ channel |
| **Bulk Body Depth ($T_{\text{body}}$)** | $50\text{ nm}$ | **$30\text{ nm}$** | — | Scaled p-body depth to suppress subsurface leakage |
| **Gate Work Function ($WF$)** | $4.35\text{ eV}$ | **$4.35\text{ eV}$** | $4.35\text{ eV}$ | Unchanged (same TiN electrode) |
| **Calibrated Physics (`.par`)** | Liao 2022 HZO | Liao 2022 HZO | Liao 2022 HZO | Unchanged locked physics |

---

## 3. Expected Physical Effects of Dimension Scaling

1. **Increased Short-Channel Leakage ($I_{\text{off}}$):** Shrinking $L_{\text{gate}}$ from $100\text{ nm}$ to $30\text{ nm}$ will introduce Drain-Induced Barrier Lowering (DIBL) and subthreshold leakage, raising $I_{\text{off}}$ and reducing the inflated $5.9 \times 10^6 \times$ ON/OFF ratio to a realistic short-channel level.
2. **Reduced Memory Window ($MW_{\text{volts}}$):** Thinning HZO from $10\text{ nm}$ to $7\text{ nm}$ reduces the total available polarization charge ($\Delta V_{\text{th}} \approx 2 E_c T_{\text{fe}}$), bringing the threshold voltage memory window down from $>1.94\text{ V}$ closer to GAA's $0.336\text{ V}$ range.
3. **Lower Switching Voltage ($V_{\text{pgm}}$):** With a thinner $7\text{ nm}$ FE and $1\text{ nm}$ oxide, less gate voltage is required to reach the coercive electric field ($E_c = 1.4\text{ MV/cm}$), allowing the operating program voltage to drop from $+4.5\text{ V}$ down towards the $+2.0\text{ V}$ - $+3.0\text{ V}$ regime.

---

## 4. Execution Workflow / Action Items

1. **Update Sentaurus SDE Command (`sde/sde_planar.cmd`):**
   - Update `L_gate` to `0.030`, `T_fe` to `0.007`, `T_ox` to `0.001`, `L_ov` to `0.005`.
   - Refine mesh controls near the channel interface (`mesh_min_channel = 0.0002`).
2. **Re-generate Mesh & Device (`planar.py mesh`):**
   - Build new `planar_msh.tdr` remotely on the TCAD server (`du@103.28.121.70`).
3. **Re-run Memory Window Sweep (`planar.py mw`):**
   - Sweep $V_G \in [-1.5\text{ V}, +1.5\text{ V}]$ at $V_{\text{DS}} = 0.05\text{ V}$ for both erased and programmed branches.
4. **Re-run LIF Pulse-Train Sweeps (`planar.py lif`):**
   - Perform $V_{\text{pgm}}$ pulse train sweep over $\{2.0\text{ V}, 2.5\text{ V}, 3.0\text{ V}, 3.5\text{ V}\}$ ($0.3\ \mu\text{s}$ pulses) to find the new fire-at-$P9$ operating point.
5. **Re-run Parameter Extraction & Comparison (`analyze_compare.py`):**
   - Regenerate `planar_params.py`, `PLANAR_vs_GAA.md`, and updated comparison plots (`compare_memwin.png`, `compare_ltp.png`, `compare_retention.png`).

---

*Document generated on 2026-07-24 for the FeFET x ML research project.*
