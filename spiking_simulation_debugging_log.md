# Spiking Simulation Debugging Log
**Date:** Jan 23, 2026
**Subject:** Debugging "Infinite Loop" and "Exploding File Size" in Sentaurus Device Transient Simulation for GAA-FeFET LIF Neuron.

## 1. Problem Statement
The transient simulation (`sdevice_des.cmd`) intended to model a Leaky Integrate-and-Fire (LIF) spiking neuron was failing to complete.
*   **Symptoms:**
    *   Simulation wall-time was excessive (running for hours without advancing simulation time).
    *   **Infinite Loop:** The solver got stuck at $t \approx 1\times10^{-15}s$ (start of the voltage spike).
    *   **Time Step Collapse:** The time step ($\Delta t$) collapsed to $\approx 1\times10^{-22}s$ or smaller.
    *   **Exploding Files:**
        *   `.plt` files grew to GBs (initially).
        *   `.log` and `.out` files grew infinitely as the solver printed convergence reports for quadrillions of tiny time steps.

## 2. Debugging Chronology & Attempts

### Attempt 1: Capping Output File Size
**Diagnosis:** The `.plt` files were growing because the solver was writing data for every single one of the millions of tiny time steps.
**Strategy:** Limit the writing frequency using `CurrentPlot` output controls.
**Implementation:**
```sentaurus
Transient (...) {
    ...
    CurrentPlot( Time = (Range=(Start Stop) Intervals=100) )
}
```
**Outcome:** **Partial Success.** The `.plt` files stopped growing (capped at ~2000 bytes), but the simulation itself remained stuck in the infinite loop, causing the `.log` files to continue growing.

---

### Attempt 2: Relaxing Basic Solver Tolerances
**Diagnosis:** Suspected that the default `Digits=5` (precision) was too strict for the fast 50ps transient.
**Strategy:** Relax numerical precision to allow easier convergence.
**Implementation:**
*   Reduced `Digits` from 5 to 4.
*   Reduced `RHSMin` (Residual minimum) requirements.
**Outcome:** **Failed.** The solver still collapsed to $10^{-22}s$ steps. The issue was not Newton convergence (which was succeeding in 1 iteration) but Time Step selection (LTE).

---

### Attempt 3: Explicit Physics Coupling
**Diagnosis:** The Ferroelectric Polarization might have been "shocked" at the start of the transient if it wasn't solved for in the previous steps.
**Strategy:** Explicitly couple `FEPolarization` in the Initialization and Drain Ramp phases.
**Implementation:**
```sentaurus
Quasistationary (...) {
    Coupled { Poisson Electron Hole FEPolarization }
}
```
**Outcome:** **Failed.** The infinite loop persisted at the start of the `fire_rise` phase.

---

### Attempt 4: Disabling LTE (Partial)
**Diagnosis:** The **Local Truncation Error (LTE)** checker was detecting the fast voltage ramp and forcing the time step to zero to maintain "perfect" accuracy.
**Strategy:** Disable LTE for standard transport equations.
**Implementation:**
```sentaurus
Math {
    ErrRef(Poisson) = 1e10
    ErrRef(Electron) = 1e10
    ErrRef(Hole) = 1e10
}
```
**Outcome:** **Failed.**
*   **Analysis:** The log file revealed that while Poisson/Electron/Hole were relaxed, other variables were still enforcing strict defaults:
    *   `FEPolarization` : `0.025`
    *   `eQuantumPotential` : `0.025`
    *   `TrapPDE` : `1e-5`

---

### Attempt 5: "Gold Standard" Configuration (Official Example)
**Diagnosis:** Maybe the entire Math block was ill-suited for FeFETs.
**Strategy:** Copy the exact Math block from the official Sentaurus `FeFET_CAM` example (`common_des.cmd`).
**Implementation:**
*   Used `RelErrControl`.
*   Switched to `Method=Blocked`, `SubMethod=ParDiSo`.
**Outcome:** **Failed.** The infinite loop persisted. The official example uses a different pulse definition method (`TurningPoints`) which naturally limits step sizes differently than our manual `Transient` blocks.

---

### Attempt 6: The "Nuclear Option" (Total Deregulation)
**Diagnosis:** The solver cannot handle the "physics shock" of a 50ps ramp with *any* active error checking on the complex variables (Polarization, Quantum Potential).
**Strategy:** Completely disable LTE for **ALL** active variables, forcing the solver to rely solely on Newton convergence (which was working fine).
**Implementation:**
```sentaurus
Math {
   * NUCLEAR OPTION: Disable LTE completely.
   ErrRef(Poisson)= 1e30
   ErrRef(Electron)= 1e30
   ErrRef(Hole)= 1e30
   ErrRef(FEPolarization)= 1e30
   ErrRef(eQuantumPotential)= 1e30
   ErrRef(hQuantumPotential)= 1e30
}
```
**Correction:** Initially included `ErrRef(FEPolarizationX/Y/Z)` which caused a syntax error. These were removed in the final fix.

**Status:** **Pending Verification.** This is the current state of the file. It theoretically *must* fix the loop because the mechanism forcing the small steps (LTE) has been turned off.

---

## 3. Current Configuration (Ready for Testing)

**File:** `f:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Simulations\sdevice_des.cmd`

### Math Block (Final)
```sentaurus
Math {
   Extrapolate
   Digits=5
   Notdamped=50
   Iterations=20
   Transient=BE
   Method=Blocked
   SubMethod=ParDiSo
   
   * NUCLEAR OPTION: Disable LTE completely. Trust Newton convergence only.
   ErrRef(Poisson)= 1e30
   ErrRef(Electron)= 1e30
   ErrRef(Hole)= 1e30
   ErrRef(FEPolarization)= 1e30
   ErrRef(eQuantumPotential)= 1e30
   ErrRef(hQuantumPotential)= 1e30
   ErrRef(LatticeTemperature)= 1e30
   ErrRef(eTemperature)= 1e30
   ErrRef(hTemperature)= 1e30
   
   * Required for quantum models
   GeometricDistances
   Derivative
   
   ComputeGradQuasiFermiAtContacts= UseQuasiFermi
   RefDens_eGradQuasiFermi_ElectricField_HFS= 1.000e+12
   RefDens_hGradQuasiFermi_ElectricField_HFS= 1.000e+12
}
```

### Solve Block (Final)
Includes strict manual step control to ensure data fidelity despite disabled LTE.
```sentaurus
  * 3a. Rise (0 -> 50ps)
  NewCurrentPrefix="fire_rise_"
  Transient (
    InitialTime=0 FinalTime=50e-12
    InitialStep=1e-13 MaxStep=1e-12 MinStep=1e-15
    Increment=1.41
    Goal { Name="gate_contact" Voltage= 1.2 }
  ) { 
      Coupled (Iterations = 100) {Poisson Electron Hole} 
      CurrentPlot( Time = (Range=(0 50e-12) Intervals=200) )
  }
```

## 4. Resolution & Final Status

### Attempt 6 Result
**Status:** The "Nuclear Option" method (Attempt 6) was implemented and tested.
**Outcome:** **Same Issue Observed** - The infinite loop and time step collapse persisted despite completely disabling LTE for all variables. This confirmed the root cause is NOT the LTE checker.

---

## 5. Root Cause Analysis (Post-Mortem)

### The Actual Root Cause: Missing `tau_E` in the Polarization Parameter File

The `Polarization` keyword activates the **Preisach-based analytic model**. Its transient dynamics are governed by two relaxation equations:
*   `dF_aux/dt = (F - F_aux) / tau_E` (auxiliary field relaxation)
*   `dP/dt = (P_aux - P) / tau_P` (polarization relaxation)

**When `tau_E` and `tau_P` are not specified, they default to 0** (instantaneous response). Every voltage change causes an instant E-field → instant P switch → instant Poisson update feedback loop. This creates an **infinitely stiff system with no characteristic timescale** for the solver to work with.

**Evidence from Official Sentaurus Examples:**
*   The **FeFET_CAM** application (the ONLY official fast-transient FeFET example) uses `tau_E = 1e-9` (1 ns) in its parameter file (`gtree.dat`).
*   The **sat_loop** example works without `tau_E` because it's quasi-static (1 second time span, 10 V/s ramp rate).
*   Our hysteresis calibration worked without `tau_E` for the same reason (quasi-static sweeps).
*   Our spiking simulation ramps 1.2V in 50ps = **24 GV/s** (4 billion times faster) — numerically catastrophic without `tau_E`.

### Secondary Issues
*   **50ps rise time** was 200x faster than the 10ns used in the official FeFET_CAM example.
*   **ErrRef=1e30** removed the solver's ability to manage accuracy.
*   **Hydrodynamic equations** not included in the Coupled block (decoupled stiffness).

### Why All 6 Attempts Failed
All attempts focused on **solver controls** (LTE, ErrRef, tolerances, solver methods). None addressed the **physics parameters**. The Preisach model's internal dynamics were instantaneous regardless of solver settings.

---

## 6. Fix Applied

### Parameter File (`sdevice_gaafet_lif.par`)
Added transient relaxation times to the HZO Polarization section:
```
tau_E = (0, 1e-9, 0)    * Auxiliary field relaxation time [s]
tau_P = (0, 0, 0)       * Polarization relaxation time [s]
kn = (0, 0, 0)          * Nonlinear coupling constant [cm*s/V]
```

### Command File (`sdevice_des.cmd`)
*   Rise time increased from 50ps to 10ns (matching FeFET_CAM official example).
*   Math block restored to proper settings: `RelErrControl`, `Digits=4`, no ErrRef overrides.
*   Step sizes adjusted for the 10ns timescale.

**Status: PENDING TEST.**

## 7. Second Root Cause: Normalized Step Sizes in Transient+Goal

### Discovery
After running with the tau_E fix, the simulation **still** exhibited time step collapse. Analysis of `n5_des.log` (42MB) revealed:

**Log line 2293-2295:**
```sentaurus
Transient (
      Initial step : 1.0000e-19 s,  Minimum step : 1.0000e-23 s, Maximum step : 5.0000e-18 s,
      Initial time : 0.0000e+00 s, Final time : 1.0000e-08 s,
```

**What we specified vs what the solver parsed:**
| Parameter | Code Value | Solver Parsed | Scale Factor |
|---|---|---|---|
| `InitialStep` | `1e-11` | `1e-19 s` | `1e-8 = FinalTime` |
| `MaxStep` | `5e-10` | `5e-18 s` | `1e-8 = FinalTime` |
| `MinStep` | `1e-15` | `1e-23 s` | `1e-8 = FinalTime` |

### Root Cause
When `Transient` is used with a `Goal` keyword, the `InitialStep`, `MaxStep`, and `MinStep` parameters are **normalized fractions (0 to 1)** of the sweep — identical to `Quasistationary`. They are NOT absolute time in seconds.

Effective time step = fraction × (FinalTime − InitialTime)

So `InitialStep=1e-11` with `FinalTime=10e-9` gives: `1e-11 × 10e-9 = 1e-19 s` (0.1 attoseconds!)

This is why the MaxStep was only 5e-18 s (5 attoseconds), requiring **2 billion steps** for 10ns.

**Note:** Without `Goal`, step sizes ARE absolute seconds (confirmed by the initialization Transient in the same log).

### Why Previous Calibration Worked
The hysteresis calibration used `Transient` with `Goal` and `FinalTime=1` (1 second). With FinalTime=1, the normalized fractions equal the absolute values, so the bug was invisible.

### Fix Applied
1. **fire_rise (with Goal):** Changed to normalized fractions: `InitialStep=1e-3` (→10ps), `MaxStep=5e-2` (→500ps), `MinStep=1e-7` (→1fs)
2. **fire_hold (without Goal):** Removed Goal (gate stays at 1.2V from rise phase), kept absolute step sizes in seconds.

**Status: ✅ SIMULATION COMPLETED — NO SPIKING.**

---

## 8. Simulation Results (Post-Fix)

### Numerical Summary
| Metric | Value |
|---|---|
| Rise phase | 0 → 10 ns (201 data points) |
| Hold phase | 10 ns → 5 μs (2001 data points) |
| VGS at end of rise | 1.2000 V |
| ID at start (VGS=0V) | 3.52 μA |
| ID at end of rise | 390.57 μA |
| ID at end of hold (5μs) | 392.66 μA |
| ID change during 5μs hold | 2.09 μA (0.5%) |
| Polarization at end | −9.64e-8 C/cm² |
| Fraction of P_r switched | 0.6% |

### Observation
**No spiking behavior.** The drain current jumps to ~391 μA during the 10ns gate ramp and is completely flat for the entire 5μs hold. No integration, no fire, no reset.

### Root Cause: Wrong Operating Point
VGS = 1.2V is far above Vth = 0.263V (overdrive = 0.937V). The device is deeply in strong inversion and immediately reaches steady state. The Bhatawdekar paper operates near threshold (VSG ≈ −0.244V → VGS ≈ +0.244V) where impact ionization slowly builds up over microseconds.

### Plot Bug Fixed
Original `plot_spiking.py` included `init_bias_n5_des.plt` (Quasistationary) whose "time" is the normalized parameter (0→1), not seconds. Fixed by excluding init_bias.

### Next Step (Attempted)
Re-ran with VGS=0.3V (near Vth=0.263V). Result: ID still flat at 67.5 μA. No spiking.

---

## 9. Run 2 Analysis (VGS=0.3V) & Root Cause Discovery

### Run 2 Results
| Metric | Value |
|---|---|
| VGS | 0.3V (overdrive = 0.037V) |
| ID at end of rise | 67.50 μA |
| ID at end of hold (5μs) | 67.76 μA |
| ID change during hold | 0.26 μA (0.4%) |
| Spiking | None |

### Physics Models Verified
Checked the simulation log — ALL models are active:
- `eAvalanche/UniBo2 (BandgapDependence = 1)` ✅
- `hAvalanche/UniBo2 (BandgapDependence = 1)` ✅
- `UniBo2: d0_h = 1e+06` ✅
- `UniBo2: d0_e = 1e+06` ✅
- `SRHRecombination` ✅
- `AugerRecombination` ✅
- `Band2BandTunneling (Hurkx)` ✅
- `Hydrodynamic` ✅

**The physics models are NOT the problem.**

### Root Cause: WRONG BIASING SEQUENCE

Reading the paper carefully (Bhatawdekar, Section 2.3, Fig.4):
- **Paper biasing:** VSG is set FIRST as constant DC bias ("synaptic weight"), then VD is PULSED from 0→1.0V to trigger Impact Ionization.
- **Our biasing (WRONG):** VDS was ramped to 1.0V FIRST (Quasistationary, with VGS=0V), then VGS was ramped to 0.3V.

**Why this matters:**
1. In the paper: When VD is pulsed, device starts with zero drain current (VDS=0). As VDS ramps, the electric field at the drain builds gradually. Impact ionization starts generating electron-hole pairs. Holes accumulate in the floating body over ~1μs (integration). Positive feedback → current spike (fire).
2. In our simulation: VDS is already at 1.0V when VGS is applied. The device immediately enters strong inversion with full drain bias. The current jumps to steady state (including II equilibrium) within the 10ns gate ramp. There is no gradual II buildup because the device never starts in the low-current state.

**The order of bias application determines whether the device enters the low-current (pre-kink) or high-current (post-kink) state.** The II mechanism creates a bistable behavior — the device must start from VDS=0 to allow gradual hole accumulation.

### Fix Applied
Reversed the Solve block in `sdevice_des.cmd`:
1. Step 2: Ramp VGS to 0.3V (Quasistationary, VDS=0V) → sets synaptic weight
2. Step 3a: Pulse VDS 0→1.0V (Transient, 10ns rise) → triggers II
3. Step 3b: Hold (5μs) → observe integration → fire

### Status: TESTED — STILL NO SPIKING

---

## 10. Run 3 Analysis (Corrected Biasing Order) & Source Bias Discovery

### Run 3 Results (Gate First, Drain Pulsed)
| Metric | Value |
|---|---|
| Biasing | Gate set to 0.3V first (V_S=0V), then drain pulsed 0→1.0V |
| V_SG | 0V - 0.3V = -0.3V |
| ID at end of rise (10ns) | 68.43 μA |
| ID at end of hold (5μs) | 68.28 μA |
| ID change during hold | -0.15 μA (flat) |
| Spiking | **None** |
| Current vs paper | 68 μA / 94 nA = **720× too high** |

### Analysis: Biasing order was correct, but still missing critical element

The corrected biasing sequence (gate first, drain pulsed) did not produce spiking. Current is still 720× higher than paper and completely flat.

### Second Root Cause: MISSING NEGATIVE SOURCE BIAS

Re-reading the paper carefully (Bhatawdekar, Section 2.3, line 210):

> **"To replicate the neuron model, a small negative voltage is applied to the source."**

**Our simulation had source grounded at 0V. This is WRONG.**

**Paper's biasing configuration:**
- **V_S = small negative voltage** (e.g., -0.2V to -0.3V)
- V_G = positive relative to source
- V_SG = V_S - V_G (e.g., -0.25V - 0.05V = -0.30V ≈ paper's -0.244V)
- V_D pulsed from 0V to 1.0V

**Why negative source bias is critical:**
1. **Reverse-biases source-channel junction:** Reduces initial electron injection from source
2. **Sets low-current initial state:** Device starts well below threshold (pre-kink)
3. **Enables gradual II buildup:** As V_D ramps, E-field at drain gradually builds
4. **Creates integration window:** Holes accumulate over ~1μs before firing

**Our incorrect config:**
- V_S = 0V (grounded)
- V_G = 0.3V
- V_SG = 0V - 0.3V = -0.3V (voltage difference is correct, but absolute potentials are wrong)

The issue is that with source at 0V and gate at 0.3V, the source-channel barrier is too low. The device injects too many electrons immediately, leading to high steady-state current (68 μA) with no room for gradual buildup.

### Fix Applied (Run 4 Configuration)
Modified `sdevice_des.cmd`:
1. **Source electrode:** V_S = -0.25V (negative bias per paper)
2. **Gate voltage:** V_G = 0.05V (to achieve V_SG ≈ -0.30V near paper's -0.244V)
3. **Drain:** Pulsed from 0V → 1.0V (unchanged)

**Expected behavior:** With negative source bias, initial current should be very low (~nA range). As drain is pulsed, II gradually builds up holes in the channel, creating positive feedback → spike.

### Secondary Issue: AreaFactor Scaling

Paper's effective area: **0.033 μm²**
Our AreaFactor: **0.071** (calibrated for 600 μA strong inversion)

Current discrepancy: 68 μA vs 94 nA = 720× too high

This suggests the paper's device has a much smaller effective channel area OR our AreaFactor needs adjustment for subthreshold operation. However, fixing the source bias should address the operating point first.

### Status: FIX APPLIED, PENDING RE-RUN
