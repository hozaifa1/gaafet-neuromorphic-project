# Current vs Target Curve Analysis (Dec 30 2025)

**Simulation files:** `vds_1v.plt`, `vds_5v.plt`  
**Reference:** Bhatawdekar et al., Fig. 7(a)-(b)

---

## 1. Automated Measurements

| Metric | VDS = 1.0 V (sim, Phase A run) | VDS = 1.5 V (sim, Phase A run) | Paper target (VDS = 1.0 V) |
|--------|------------------------------|---------------------------------|----------------------------|
| Max |I_D| @ VSG = −0.5 V | **5.40 µA** | **3.50 µA** | **≈85 µA** |
| VSG where |I_D| = 94 nA | **−0.390 V** | **−0.405 V** | **−0.244 V** |
| |I_D| at VSG = −0.244 V | **0.267 nA** | **0.148 nA** | **94 nA** |
| Kink location | ≈0 V | ≈0 V | −0.30 V to −0.40 V |
| Kink jump ratio | 1.75×10^8 (tiny baseline) | 3.9×10^8 | 10–100× with finite baseline |

**Takeaways**
1. Phase A edits (Areafactor = 1.0, mobility upgrade) boosted |I_D|max from 0.57 µA → 5.4 µA (~9.5×), but currents remain **16–24× too low** vs the paper.
2. VDS = 1.5 V still produces less current than VDS = 1.0 V → **drain-bias setup remains suspect** or avalanche still off near 1.5 V.
3. VSG@94 nA improved from −0.448 V → −0.391 V, yet remains 0.15 V away from −0.244 V.
4. Kink continues to appear only at VSG ≈ 0 V, confirming BandgapDependence alone is insufficient until avalanching gains magnitude earlier.

---

## 1.1 Phase A Run Notes
- Changes applied: `Areafactor=1.0`, `Mobility(DopingDependence HighFieldSaturation Enormal)`, `Avalanche(UniBo2 BandgapDependence)`. Contact resistivity unchanged (no param available in current SDE deck).
- Result: |I_D|max improved to 5.4 µA (Goal: ≥10 µA).  
- VSG offset to hit 94 nA shrank from 0.203 V → 0.147 V (Goal: ≤0.05 V).  
- Still missing: additional current gain (≈15×) and correct kink placement; VDS=1.5 V still misbehaves.

---

## 2. Syntax Research: Contact Resistivity & Biasing

### 2.1 Contact Resistivity in `sdevice`
The correct parameter for distributed contact resistivity ($\Omega \cdot \text{cm}^2$) in `sdevice` is `DistResist`, placed directly inside the `Electrode` section.

**Syntax:**
```cmd
Electrode {
  { Name="source_contact" Voltage=0.0 DistResist=7e-8 }
  { Name="drain_contact"  Voltage=1.0 DistResist=7e-8 }
}
```
- **Unit:** $\Omega \cdot \text{cm}^2$.
- **Target:** $7\,\Omega \cdot \mu\text{m}^2 = 7 \times 10^{-8}\,\Omega \cdot \text{cm}^2$.

### 2.2 Fixing the VDS Anomaly
The lower current at 1.5 V was likely due to the `Solve` block sweeping Gate voltage while Drain was still ramping or inconsistent.

**New Solve Strategy:**
1. **Initialize** at 0 V.
2. **Ramp Drain** to target voltage (1.0 V or 1.5 V) while Gate is 0 V.
3. **Sweep Gate** only after Drain is stable.

---

## 3. Implemented Fixes (Phase B Start)

I have updated your simulation files with the following:

### `sdevice_des.cmd`
- **Fixed Electrode section:** Replaced invalid `Contact` block with `DistResist=7e-8` inside the `Electrode` definitions.
- **Restructured `Solve` block:** Now ramps Drain to 1.0 V before sweeping Gate.
- **Cleaned Physics:** Simplified `Avalanche` comments for better readability.

### `sdevice_gaafet_lif.par`
- **Increased `UniBo2` coefficients:** `d0_e` and `d0_h` bumped from $10^5 \to 10^6$ to match the paper's calibration for early kink.

---

## 4. Phase B Action Plan

### Step 1: Re-run VDS = 1.0 V
1. Run `sdevice` with the updated files.
2. Check if current reaches **>10 µA** (the extra boost from low contact resistance should help).

### Step 2: Re-run VDS = 1.5 V
1. **Edit** `sdevice_des.cmd`:
   - `Electrode { ... { Name="drain_contact" Voltage=1.5 } ... }`
   - `Solve { ... Goal { Name="drain_contact" Voltage=1.5 } ... }`
2. Run `sdevice`.
3. **Verification:** Confirm this run now has HIGHER current than the 1.0 V run.

### Step 3: Automated Verification
Run the analysis script to see if the kink has moved:
```powershell
py py_scripts/analyze_curves.py vds_1v.plt vds_1_5v.plt
```

> **Goal after Phase B:** |I_D|max ≥ 20 µA and a sharp kink visible at VSG ≈ −0.35 V.

### Phase C — Final Alignment
6. **Threshold tuning**  
   - Sweep gate workfunction (4.5…4.65 eV) until |I_D| = 94 nA occurs at VSG = −0.244 V.
7. **Kink sharpness sweep**  
   - Adjust `d0_e/d0_h` to overlay Fig. 7(a) families.  
   - Capture plots for VD = {0.4…1.4 V} both with & without II.

---

## 4. Execution Checklist

1. [ ] Update `sdevice_des.cmd`: area factor + mobility + avalanche flag.  
2. [ ] Update `.par`: confirm UniBo2 coefficients.  
3. [ ] Update SDE contacts + regenerate mesh.  
4. [ ] Run VDS = 1.0/1.2/1.5 V sweeps → use `plot_idvg.py` for curves, `analyze_curves.py` for metrics.  
5. [ ] Document |I_D|@−0.5 V, VSG@94 nA, kink voltage for each run directly in this file.  
6. [ ] Iterate workfunction & d0 sweeps until Table targets match.

---

## 5. Tooling Summary

- `plot_idvg.py <plt>` → Generates publication-style Id–VSG plot in `output_curves/`.  
- `analyze_curves.py` → Prints all metrics above (current magnitudes, kink detection, target deltas).

Use these scripts after every Sentaurus run to keep the log consistent with paper targets.
