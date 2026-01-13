# VDS Bug - Systematic Investigation & Testing Tracker

**Date Started**: Jan 10, 2026  
**Bug**: VDS=1.5V shows 36.7% LOWER current than VDS=1.0V (physically impossible)

## 🚨 URGENT UPDATE (Jan 11, 2026)

**BUG IS SYSTEMATIC - AFFECTS ALL VDS LEVELS**:
- Current **decreases** as VDS increases (opposite of physics)
- VDS=0.4V → 0.8V → 1.0V shows monotonic current **reduction**
- VDS=1.4V fails to converge (RHS > 1e15)

**FIX IMPLEMENTED**:
- Finer timesteps: `MaxStep=1e-3` → `1e-4` (10x finer)
- Tighter MinStep: `1e-6` → `1e-7`
- Should resolve both convergence and physics accuracy issues

**STATUS**: ✅ ROOT CAUSE IDENTIFIED - Methodology Error (Transient vs Quasistationary)

**Test 2 Results (Jan 12, 2026)**: Finer timesteps did NOT fix the bug.
- VDS=0.4V: 135.45 µA | VDS=0.8V: 103.73 µA | VDS=1.0V: 88.58 µA
- VDS=1.2V: 74.33 µA | VDS=1.4V: 61.73 µA
- Current still decreases monotonically with increasing VDS ❌

**SOLUTION**: Use Quasistationary (not Transient) for DC I-V sweeps

---

## Problem Statement

**Observed**:
- VDS=1.0V: 87.07 µA @ VSG=-0.5V ✓ **WORKS PERFECTLY**
- VDS=1.5V: 55.12 µA @ VSG=-0.5V ✗ **PHYSICALLY WRONG**

**Expected** (from Figure 7b):
- Paper shows VD=0.6V to 1.4V with **monotonic increase**
- VD=1.4V → ~115 µA (highest)
- VD=1.0V → ~85 µA
- Higher VDS must give higher current due to impact ionization

**User's Correct Insight**:
> "Transient works perfectly at VDS=1.0V → method is fine, problem is VDS-SPECIFIC"

---

## Log Analysis Summary

✅ **1v_logs.log** (VDS=1.0V):
- Converges normally, factor=1.00
- No warnings, no RHS issues
- Source current: -1.585E-02 A during solve

✅ **1_5v_logs.log** (VDS=1.5V):  
- Also converges normally, factor=1.00
- No convergence failures
- Source current: -1.586E-02 A during solve

**KEY FINDING**: Both simulations converge successfully. Problem is in the **physics/results**, not numerical convergence.

---

## Test Plan & Results

### ✅ Test 1: Try VDS=1.4V (Paper's Maximum)
**Rationale**: Paper only tests up to 1.4V. If 1.4V works → 1.5V exceeds valid range.  
**Status**: **COMPLETED - CRITICAL FAILURE**  
**Action**: Set drain voltage to 1.4V, run simulation  
**Expected**: Should show ~115 µA @ VSG=-0.5V  
**Result**: **CONVERGENCE FAILURE**
- Simulation failed at iteration 10: `|RHS| > 1e15`
- Then failed with "Step-size is too small" when trying smaller timesteps
- **Root cause**: Higher VDS creates faster carrier dynamics → MaxStep=1e-3 too coarse

**Additional Discovery - SYSTEMATIC BUG ACROSS ALL VOLTAGES**:
Analyzed existing simulation data (0.4V, 0.8V, 1.0V):
- VDS=0.4V: 133.41 µA @ VSG=-0.5V ✓
- VDS=0.8V: 102.03 µA @ VSG=-0.5V ❌ (23.5% LOWER)
- VDS=1.0V: 87.07 µA @ VSG=-0.5V ❌ (14.7% LOWER than 0.8V)
- VDS=1.4V: Convergence failure

**CRITICAL**: Current **DECREASES** monotonically as VDS increases - physically impossible! 

---

### ✅ Test 2: Finer Timesteps (10x finer resolution) - COMPLETED
**Rationale**: Higher VDS has faster dynamics, may need finer temporal resolution.  
**Status**: **COMPLETED - BUG PERSISTS**  
**Action**: Changed `MaxStep=1e-3` to `MaxStep=1e-4` (10x finer) + `MinStep=1e-6` to `1e-7`  

**Results (Jan 12, 2026)**:
| VDS | Current @ VSG=-0.5V | Change from Previous |
|-----|---------------------|---------------------|
| 0.4V | 135.45 µA | baseline |
| 0.8V | 103.73 µA | **-23.4%** ❌ |
| 1.0V | 88.58 µA | **-14.6%** ❌ |
| 1.2V | 74.33 µA | **-16.1%** ❌ |
| 1.4V | 61.73 µA | **-16.9%** ❌ |

**Conclusion**: 
✅ Convergence fixed (VDS=1.4V now completes)
❌ Bug STILL present - finer timesteps did NOT resolve the issue
→ **Problem is NOT temporal resolution**
→ **Problem is METHODOLOGY** (see Test 3) 

---

### ❌ Test 2 Results (Jan 13 2026)
*   **Observation**:
    *   VDS=0.4V: Id = 26.22 µA (Works)
    *   VDS=0.8V: Id = 0.01 µA (Failed)
    *   VDS=1.0V+: Id = 0.00 µA (Dead)
*   **Analysis**: The "bug" has worsened to complete device failure at high VDS.
*   **Root Cause Discovered**: **Write Disturb / Depolarization**.
    *   The previous simulation setup kept `Drain Voltage = @Vds@` during the **Write** phase.
    *   At high VDS (e.g., 1.4V), the potential in the channel near the drain is high.
    *   When Gate goes to 2.0V, the effective voltage drop across the HZO near the drain is $V_{GS} - V_{channel} \approx 2.0 - 1.4 = 0.6V$.
    *   This 0.6V is **insufficient to switch the ferroelectric polarization** (Coercive voltage is likely > 1V).
    *   Result: The drain side of the channel remains in the High-Vt (OFF) state, blocking all current.
*   **Conclusion**: The methodology was still flawed. We must **Write at VDS=0V** (standard memory operation) and *then* **Read at VDS=@Vds@**.

### 🎯 Test 3: GROUNDED DRAIN WRITE (The Real Fix)
**Rationale**: Ensure uniform polarization switching by grounding the drain during the Write pulse, then ramp VDS for the Read sweep.

**Plan**:
1.  **Electrode Section**: Set default Drain Voltage to `0.0` (not `@Vds@`).
2.  **Solve Section**:
    *   **Init**: VDS=0, VGS=0.
    *   **Write**: VDS=0, VGS 0->2->0.
    *   **Ramp**: Ramp Drain 0 -> `@Vds@`.
    *   **Read**: VGS Sweep 0->2 (at constant VDS).

**Expected Result**:
Current should remain high (~26-80 µA) for all VDS values and increase with VDS.

---

### ☐ Test 4: Check Avalanche Generation Output
**Rationale**: Verify if impact ionization actually activates at VDS=1.5V.  
**Status**: PENDING  
**Action**: Compare `AvalancheGeneration` from .plt files  
**Expected**: VDS=1.5V should show MORE II than 1.0V  
**Result**: 

---

### ☐ Test 5: Disable Band2Band Tunneling
**Rationale**: BTBT may compete/interfere with II at high VDS.  
**Status**: PENDING  
**Action**: Comment out `Band2Band(Model=Hurkx)` temporarily  
**Expected**: Isolate pure II behavior  
**Result**: 

---

### ☐ Test 6: Different VDS Ramp Order
**Rationale**: FE polarization may be path-dependent.  
**Status**: PENDING  
**Action**: Try starting from VDS=1.5V instead of ramping from 1.0V  
**Expected**: If initialization issue → different result  
**Result**: 

---

## Hypotheses

1. ⚠️ **VDS=1.5V exceeds model validity** - Paper stops at 1.4V intentionally
2. ⏱️ **Timestep too coarse** - Missing fast transients at high fields
3. 🔥 **Hydrodynamic breakdown** - Carrier temp equations fail at high VDS
4. ⚡ **Impact ionization saturation** - UniBo2 model field limits
5. 🧲 **FE polarization coupling** - Path-dependent solution
6. 🌉 **BTBT interference** - Tunneling dominates at high VDS

---

## Next Immediate Action

**START WITH TEST 1**: Try VDS=1.4V (paper's validated maximum)

