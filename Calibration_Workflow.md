# Calibration Workflow & To-Do List

This document outlines the step-by-step process to calibrate the GAAFET LIF neuron simulation against the reference design.

---

## 1. TARGET CURVE IDENTIFICATION

**Primary Reference Paper:**  
"Design of energy-efficient LIF neuron using CMOS compatible gate-all-around floating nanosheet FET"  
*Neurocomputing 659 (2026) 131814*  
Authors: Bhatawdekar et al.

**Target Curves to Replicate:**
- **Figure 7(a):** I_D vs V_SG showing Impact Ionization parameter sweep (d0 = 1×10^5 to 9×10^6)
- **Figure 7(b):** I_D vs V_SG at different V_D values (0.4V to 1.4V), with and without II model
- **Figure 8:** Transient I_D vs Time showing threshold firing at I_th = 94 nA

**Target Parameters (EXACT from Paper Table 1 & Section 3):**

| Parameter | Symbol | Target Value | Source |
|-----------|--------|--------------|--------|
| Threshold Voltage | V_th | **-0.244 V** | Fig. 7, Table 2 |
| Threshold Current | I_th | **94 nA** | Fig. 7(b), Fig. 8 |
| Drain Voltage | V_D | **1.0 V** | Section 3, Fig. 7(b) |
| Impact Ionization d0 | d0_e, d0_h | **1×10^6** | Fig. 7(a), Section 2.3 |
| Gate Length | L_g | 100 nm | Table 1 |
| Fin Height | H_FNS | 90 nm | Table 1 |
| Fin Thickness | T_FNS | 15 nm | Table 1 |
| Gate Workfunction | WF | 4.6 eV | Table 1 |
| Channel Doping | N_ch | 1×10^16 /cm³ (Boron) | Table 1 |
| S/D Doping | N_sd | 1×10^20 /cm³ (Arsenic) | Table 1 |

--
## 4. SENTAURUS WORKBENCH PARAMETER SWEEP GUIDE (v2023.12)

### 4.1 How to Create a Parameter Sweep (Step-by-Step Clicking Guide)

1. **Open SWB Project:**
   - Launch Sentaurus Workbench
   - Open your project file (.swb)

2. **Define a Variable in Your Input File:**
   - Open `sdevice_gaafet_lif.cmd`
   - Replace hardcoded value with `@VarName@` syntax
   - Example: Change `Voltage= 1.0` to `Voltage= @VD@`

3. **Add Variable Column in SWB:**
   - In SWB main window, look at the spreadsheet-like interface
   - Right-click on any column header → **Insert Column**
   - Name it exactly as in your file (e.g., `VD`)
   - Set the value in the cell (e.g., `1.0`)

4. **Create Split for Sweep:**
   - Select the tool node (e.g., `sdevice`)
   - Right-click → **Experiments** → **Add Split**
   - This creates multiple branches
   - Enter different values in each branch's parameter cell:
     - Branch 1: `VD = 0.8`
     - Branch 2: `VD = 1.0`
     - Branch 3: `VD = 1.2`

5. **Run All Experiments:**
   - Select parent node
   - Press **Ctrl+R** or right-click → **Run**

6. **Compare Results:**
   - Select multiple completed nodes (Ctrl+Click)
   - Right-click → **Inspect** → **Inspect Results**
   - Curves will overlay automatically

### 4.2 Recommended Sweep Sequence


**Step 2: Sweep V_D to Match Paper Figure 7(b)**
| Experiment | V_D Value |
|------------|----------|
| 1 | 0.8 V |
| 2 | 1.0 V |
| 3 | 1.2 V |
| 4 | 1.4 V |

**Step 3: Sweep d0 to Match Paper Figure 7(a)**
| Experiment | d0_e, d0_h Value |
|------------|------------------|
| 1 | 1×10^5 |
| 2 | 5×10^5 |
| 3 | 1×10^6 (target) |
| 4 | 5×10^6 |

**Step 4: Fine-tune Workfunction (if V_th is off)**
| Experiment | Workfunction (eV) |
|------------|------------------|
| 1 | 4.5 |
| 2 | 4.55 |
| 3 | 4.6 (baseline) |
| 4 | 4.65 |

---

## 5. MASTER CHECKLIST

### Phase A: Analysis & Code Fixes ✅ COMPLETE
- [x] Identify target curve from paper (Fig. 7 from Bhatawdekar et al.)
- [x] Analyze current simulation results (`n2_des.plt`)
- [x] Identify root cause (V_D = 0.05V instead of 1.0V)
- [x] Fix 3.1: Change drain voltage to 1.0V in `sdevice_gaafet_lif.cmd`
- [x] Verify 3.2: Transient sweep is correct (no change needed)
- [x] Verify 3.3: Impact Ionization params already correct

### Phase B: Simulation & Validation ✅ COMPLETE
- [x] Re-run simulation in Sentaurus with corrected V_D = 1.0V
- [x] Generate new `.plt` output file (`n2_des.plt`)
- [x] Run `python Simulations/py_scripts/plot_idvg_from_plt.py` with `--ylog` flag
- [x] Analyze log-scale plot for kink effect

**Phase B Results (2024-12-18):**

| Metric | Measured | Target | Status |
|--------|----------|--------|--------|
| V_D | 1.0 V | 1.0 V | ✅ |
| V_G Range | -2V to +2V | — | ✅ OK |
| I_off | ~10^-16 A | ~10^-9 A | ⚠️ Too ideal |
| I_on | 1.37 mA | ~100 µA | ✅ |
| V_th (@ 94nA) | 0.45 V | 0.244 V | ❌ +0.2V shift |
| **Kink Effect** | **NOT VISIBLE** | Sharp jump | ❌ **MISSING** |
| Hysteresis | Not detected | ~2V window | ❌ |

**Diagnosis:** Impact Ionization is NOT firing despite V_D = 1.0V and d0 = 1e6.

### Phase C: Calibration Sweeps (NEXT STEP)

**Priority 1: Fix Missing Kink Effect**
- [ ] Sweep d0 values to trigger Impact Ionization:
  | Experiment | d0_e, d0_h | Expected Effect |
  |------------|------------|----------------|
  | C1 | 5×10^6 | Stronger II, earlier kink |
  | C2 | 1×10^7 | Even stronger II |
  | C3 | 2×10^6 | Moderate increase |

**Priority 2: Fix V_th Shift (after kink appears)**
- [ ] Sweep Workfunction if V_th is still off:
  | Experiment | WF (eV) | Expected Shift |
  |------------|---------|---------------|
  | C4 | 4.5 | V_th ↓ ~0.1V |
  | C5 | 4.55 | V_th ↓ ~0.05V |

**Priority 3: Fix Hysteresis (after kink and V_th)**
- [ ] If no hysteresis, check FE polarization parameters

---

## 6. IMMEDIATE NEXT ACTION

**You need to sweep d0 parameter to trigger Impact Ionization.**

In `sdevice_gaafet_lif.par`, change:
```
Avalanche_UniBo {
    a_0 = 5.0e6    * Increase from 1.0e6
    a_1 = 5.0e6    * Increase from 1.0e6
}
```

Or use SWB parameter sweep (Section 4) to test multiple values simultaneously.
