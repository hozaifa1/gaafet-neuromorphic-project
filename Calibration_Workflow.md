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

---

## 2. PHASE A COMPLETE: ANALYSIS OF CURRENT SIMULATION

### 2.1 Simulation Results (`n2_des.plt`)

| Metric | Measured Value | Target Value | Status |
|--------|----------------|--------------|--------|
| V_g Range | -2.0 V to +2.0 V | -0.5 V to 0 V (V_SG) | ✅ Acceptable |
| **V_D (Drain Bias)** | **0.05 V** | **1.0 V** | ❌ **CRITICAL ERROR** |
| I_off | 1.95×10^-20 A | ~1×10^-9 A | ⚠️ Too ideal |
| I_on | 91.5 µA | ~100 µA | ✅ Close |
| V_th (@ 94nA) | +0.43 V | -0.244 V | ⚠️ Polarity convention |
| Kink Effect | **NOT VISIBLE** | Sharp jump in I_D | ❌ **MISSING** |
| Hysteresis | Not present | ~2V window | ❌ Single sweep |

### 2.2 ROOT CAUSE IDENTIFICATION

**PRIMARY ISSUE: V_D = 0.05 V (Line 21 of `sdevice_gaafet_lif.cmd`)**

The simulation was run with drain voltage **V_D = 0.05 V**, but the paper requires **V_D = 1.0 V**.

**Why this breaks the LIF neuron behavior:**
1. Impact Ionization requires high electric field at drain-channel junction
2. At V_D = 0.05 V, the field is ~20× too weak
3. No avalanche generation → No hole accumulation → No floating body effect
4. Result: Standard MOSFET curve with no neuromorphic "kink"

**SECONDARY ISSUES:**
- Hysteresis requires a double-sweep (forward + backward) which was not configured
- The polarity convention uses V_G (gate-to-ground) instead of V_SG (source-to-gate)

---

## 3. EXACT PARAMETER CHANGES REQUIRED

### 3.1 CRITICAL FIX: Drain Voltage

**File:** `Simulations/sdevice_gaafet_lif.cmd`  
**Line:** 21  
**Current:** `{ Name="drain_contact" Voltage= 0.05 }`  
**Change to:** `{ Name="drain_contact" Voltage= 1.0 }`

This single change is the most important fix. Without V_D = 1.0 V, the LIF neuron cannot function.

### 3.2 Sweep Configuration for Hysteresis

**File:** `Simulations/sdevice_gaafet_lif.cmd`  
**Section:** Solve block (Lines 105-122)

Replace the current sweep with a proper V_SG sweep:
```
Solve {
  * Initial equilibrium
  Coupled { Poisson Electron Hole FEPolarization }
  
  * Forward sweep: V_SG from 0 to -0.5V
  Quasistationary (
    InitialStep=0.01 MaxStep=0.02 MinStep=1e-5
    Goal { Name="source_contact" Voltage=-0.5 }
  ) { Coupled { Poisson Electron Hole FEPolarization } }
  
  * Backward sweep: V_SG from -0.5V to 0V (for hysteresis)
  Quasistationary (
    InitialStep=0.01 MaxStep=0.02 MinStep=1e-5
    Goal { Name="source_contact" Voltage=0 }
  ) { Coupled { Poisson Electron Hole FEPolarization } }
}
```

### 3.3 Impact Ionization Parameters (Already Correct)

**File:** `Simulations/sdevice_gaafet_lif.par`  
**Status:** ✅ `a_0 = 1.0e6` and `a_1 = 1.0e6` are already set correctly.

---

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

**Step 1: Fix V_D First (No Sweep Needed)**
- Change V_D from 0.05V to 1.0V
- Run single simulation
- Verify kink effect appears

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

## 5. IMMEDIATE NEXT ACTIONS

- [x] **Phase A Complete:** Identified target curve (Fig. 7 from Bhatawdekar et al.)
- [x] **Root Cause Found:** V_D = 0.05V instead of 1.0V
- [ ] **Action 1:** Edit `sdevice_gaafet_lif.cmd` Line 21: Change `Voltage= 0.05` to `Voltage= 1.0`
- [ ] **Action 2:** Re-run simulation with corrected V_D
- [ ] **Action 3:** Generate new log-scale I_D vs V_G plot
- [ ] **Action 4:** Verify kink effect is now visible
- [ ] **Action 5:** If kink is weak, sweep d0 values (1e5 to 5e6)
