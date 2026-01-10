# VDS Bug - Systematic Investigation & Testing Tracker

**Date Started**: Jan 10, 2026  
**Bug**: VDS=1.5V shows 36.7% LOWER current than VDS=1.0V (physically impossible)

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

### ☐ Test 1: Try VDS=1.4V (Paper's Maximum)
**Rationale**: Paper only tests up to 1.4V. If 1.4V works → 1.5V exceeds valid range.  
**Status**: PENDING  
**Action**: Set drain voltage to 1.4V, run simulation  
**Expected**: Should show ~115 µA @ VSG=-0.5V  
**Result**: 

---

### ☐ Test 2: Finer Timesteps for VDS=1.5V
**Rationale**: Higher VDS has faster dynamics, may need finer temporal resolution.  
**Status**: PENDING  
**Action**: Change `MaxStep=1e-3` to `MaxStep=1e-4` (10x finer)  
**Expected**: If timestep issue → current should increase  
**Result**: 

---

### ☐ Test 3: Disable Hydrodynamic (Use Drift-Diffusion Only)
**Rationale**: Carrier temperature equations may fail at high drain fields.  
**Status**: PENDING  
**Action**: Comment out `Hydrodynamic(eTemperature hTemperature)` in Physics  
**Expected**: If HD is problem → DD should work correctly  
**Result**: 

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

