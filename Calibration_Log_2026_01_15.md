# 📜 Project Calibration History Log
**Date:** Jan 15, 2026 - Present  
**Scope:** Full Device Calibration (DC, Hysteresis, & Transient)  
**Total Runs:** 16 (Calibration Complete)

---

## 🚀 Executive Summary
This document tracks the complete evolution of the GAA-FeFET calibration from a clean slate to the final "Golden" LIF Neuron configuration.
*   **Target:** $L_g=100nm$, $V_{th}=0.25V$, $I_{on}=600\mu A$.
*   **Status:** **CALIBRATED** (Run 16).

---

## 1️⃣ Stage 1: Initial DC Calibration (Quasistationary)
*Focus: Matching the static I-V envelope (Vth, Ion) using a simple DC solver.*

### **Run 01: The Baseline**
*   **Config:** `WF=3.9eV`, `FixedCharge=0`, `AreaFactor=0.21`.
*   **Result:** $V_{th} = 0.68V$ (High), $I_{peak} = 8.8mA$ (Excessive).
*   **Diagnosis:** Device is "too clean". High mobility yields excessive current. High positive $V_{th}$ implies we need negative shift (Positive Oxide Charge).

### **Run 02: The Scattering Test**
*   **Config:** Added `FixedCharge=2.7e12`. Reduced `AreaFactor=0.0142` (Artificial).
*   **Result:** $V_{th} = 0.55V$, $I_{peak} = 36.4\mu A$ (Too Low).
*   **Insight:** Interface traps introduced Coulomb scattering, naturally degrading mobility. The artificial AreaFactor reduction killed the current.

### **Run 03: The Overshoot**
*   **Config:** Increased `FixedCharge=9.5e12`. Restored `AreaFactor=0.234`.
*   **Result:** $V_{th} = 0.053V$ (Too Low), $I_{peak} = 651\mu A$ (Good).
*   **Insight:** We bracketed the target. $V_{th}$ sensitivity established.

### **Run 04: Interpolation**
*   **Config:** `FixedCharge=6.0e12`, `AreaFactor=0.220`.
*   **Result:** $V_{th} = 0.210V$ (Close), $I_{peak} = 597\mu A$.

### **Run 05: DC Golden Run**
*   **Config:** `FixedCharge=5.15e12`, `AreaFactor=0.224`, `WF=3.9eV`.
*   **Result:** $V_{th} = 0.256V$ ✅, $I_{peak} = 600\mu A$ ✅.
*   **Status:** **DC CALIBRATION COMPLETE.**

---

## 2️⃣ Stage 2: Hysteresis & Transient Integration
*Focus: Activating the Ferroelectric Loop and switching to Transient Solvers.*

### **Run 06: The "Paper Match" Attempt**
*   **Goal:** Switch to LIF Paper specs ($WF=4.6eV$) + Contact Resistance.
*   **Result:** **FAILED**. $V_{th} \approx 0V$, High Leakage ($I_{off} \approx 0.3\mu A$).
*   **Decision:** Reverted. The paper's parameters don't match our calibrated stack physics.

### **Run 07: Revert to Baseline**
*   **Config:** Restored Run 05 parameters ($WF=3.9eV$, $Charge=5.15e12$).
*   **Change:** Switched Solver from `Quasistationary` to `Transient` (Required for Hysteresis).
*   **Result:** Simulation converged, but results drifted.

### **Run 08 & 09: The Transient Anomaly**
*   **Result:** $V_{th} \approx 0.237V$, $I_{peak} \approx 1950\mu A$ (Huge Jump), **No Hysteresis** ($MW \approx 30mV$).
*   **Diagnosis:** 
    1.  Transient solver calculates current differently (displacement + particle), requiring AreaFactor recalibration.
    2.  Voltage Divider: $V_{fe}$ was not exceeding Coercive Voltage ($V_c$).

### **Run 10: Loop Expansion**
*   **Config:** `AreaFactor` recalibrated to **0.069**. Sweep range increased to $\pm 6.0V$.
*   **Result:** Current scale fixed. Still struggling with Loop Centering.

### **Run 11: Zero Charge Debug**
*   **Config:** `FixedCharge=0.0`.
*   **Result:** $V_{th} \approx -0.2V$. Large shift confirming the strong impact of the 5.15e12 charge.

### **Run 12 & 13: Parameter Exploration**
*   **Actions:** Varied Doping and Workfunction to find a new stable point for the Hysteresis loop.
*   **Outcome:** Determined that `WF=3.9eV` was insufficient to center the loop properly with the required Fixed Charge.

---

## 3️⃣ Stage 3: Final Hysteresis Calibration ("The Reset")
*Focus: Re-calibrating Vth and Ion specifically for the Hysteresis Loop (Forward Sweep).*

### **Run 14: The New Baseline**
*   **Config:** `WF=3.9eV`, `FixedCharge=5.15e12`, `AreaFactor=0.069`.
*   **Result:** $V_{th} (Fwd) \approx -0.2V$ (Too Negative).
*   **Analysis:** The loop logic shifts the "Forward" Vth significantly compared to DC. We need a massive positive shift.

### **Run 15: Workfunction Correction**
*   **Config:** Increased `WF` to **4.35 eV** (+0.45V shift). Reduced `FixedCharge` to **3.5e12** (to fine tune).
*   **Result:** $V_{th} (Fwd) = 0.30V$.
*   **Status:** Overshot the 0.25V target, but in the right zone.

### **Run 16: The Golden Calibration (Current Best)**
*   **Config:** 
    *   **Workfunction:** `4.35 eV`
    *   **Fixed Charge:** `4.0e12 cm⁻²` (Increased to lower Vth slightly)
    *   **AreaFactor:** `0.071` (Tuned for Ion)
*   **Result:**
    *   $V_{th} (Fwd)$: **0.263 V** (Target 0.25V) ✅
    *   $I_{peak}$: **604 \mu A** (Target 600uA) ✅
    *   $MW$: **0.68 V** (Counter-Clockwise Loop) ✅
*   **Status:** **PERFECT CALIBRATION.**

---

## 🏆 Final Calibrated Parameters (Run 16)
These are the locked values for the physics files:
| Parameter | Value | Reason |
| :--- | :--- | :--- |
| **Workfunction** | **4.35 eV** | Centers the Hysteresis Loop |
| **Fixed Charge** | **4.0e12 cm⁻²** | Fine-tunes $V_{th}$ to 0.25V |
| **AreaFactor** | **0.071** | Scales $I_{on}$ to 600uA (Transient Mode) |
| **Lg / Tsi** | **100nm / 15nm** | Matches Design Paper (Bhatawdekar) |
