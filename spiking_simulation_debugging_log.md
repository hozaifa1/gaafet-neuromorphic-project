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

### Status: TESTED — RUN 4 FAILED

---

## 11. Run 4 Analysis (Negative Source Bias) & V_DS Discovery

### Run 4 Results (V_S = -0.25V, V_G = 0.05V)
| Metric | Value |
|---|---|
| ID at start (V_D=0) | **46.17 μA** (Expected ~nA) |
| ID at end of rise | 69.46 μA |
| ID at end of hold | 69.34 μA |
| Spiking | None |

### Root Cause: V_DS was not zero initially!
In Run 4, I set the source to `-0.25V` and left the drain at `0.0V` initially.
- V_DS = V_D - V_S = 0.0V - (-0.25V) = **+0.25V**
- With V_GS = 0.3V and V_DS = 0.25V, the device immediately conducted **46 μA** of current before the drain pulse even began.
- The device was not in the off/low-current state required for gradual II buildup.

**The Fix:**
The drain electrode must initially be biased to the **same voltage as the source** to maintain V_DS = 0V.
- Initial state: V_S = -0.25V, **V_D = -0.25V** → V_DS = 0V (Current = 0)
- Drain Pulse: Ramp V_D from **-0.25V to +1.0V**

### Secondary Issue: AreaFactor & Current Levels
The paper's target threshold current is **94 nA**. The paper's effective area is **0.033 μm²**.
Our device has an AreaFactor of **0.071** (calibrated to hit 600 μA for logic operation).
- Ratio: 0.071 / 0.033 = 2.15x larger
- Scaled threshold current should be: 94 nA * 2.15 ≈ **202 nA**

Even considering AreaFactor, our current is jumping to ~69,000 nA. The primary issue is still the biasing/operating point, specifically ensuring V_DS starts at 0V so the integration process can occur.

### Fix Applied (Run 5 Configuration)
Modified `sdevice_des.cmd`:
1. **Electrodes:** `drain_contact Voltage = -0.25` (matches source)
2. **Goal:** Transient pulse ramps drain from `-0.25V` to `1.0V`

### Status: TESTED — V_DS FIX SUCCESSFUL, BUT DEVICE IS TOO "ON"

---

## 12. Run 5 Analysis (Zero Initial V_DS) & Subthreshold Operating Point Fix

### Run 5 Results (V_S = -0.25V, V_D(init) = -0.25V, V_G = 0.05V)
| Metric | Value |
|---|---|
| ID at start (t=0, V_D=-0.25V) | **0.00 μA** (Expected! Fix worked) |
| ID at end of rise (V_D=1.0V) | **73.06 μA** |
| ID at end of hold | 72.88 μA |
| Spiking | None (immediate jump to high current) |

### Analysis: Initial Leakage Fixed, but Operating Point is Wrong
The fix to set initial $V_D = V_S$ worked perfectly. The device started with **0.0 A** of drain current.
However, as soon as the drain was pulsed to $1.0V$, the current immediately jumped to $73 \mu A$, which is orders of magnitude above the target threshold current.

**Why? We are operating in strong inversion.**
1. The paper's device has a threshold $V_{SG} = -0.244V$. When they apply $V_S = -0.25V$, their required $V_G$ is around $0V$.
2. **Our calibrated device is different.** We achieved $V_{th} = +0.26V$ for a logic target ($I_{on} = 600\mu A$).
3. The paper's target subthreshold current for the LIF neuron is $I_{th} = 94nA$.
4. Since our device area (AreaFactor=0.071) is ~2.15x larger than the paper's area (0.033 $\mu m^2$), our scaled target threshold current is **$\approx 202 nA$**.

Looking closely at our calibration data (`hysteresis_id_vg.csv`):
- At $V_{GS} = +0.30V$ (the setting in Run 5), the static drain current is $\approx 11.4 \mu A$. (In transient with $V_D=1.0V$ and no equilibrium, it hit $73 \mu A$).
- To reach the target subthreshold current of **202 nA**, our $V_{GS}$ needs to be **$-0.32V$**.

### The Fix (Run 6 Configuration)
We must bias the gate so that $V_{GS} \approx -0.32V$.
Given that $V_S = -0.25V$:
$V_G = V_S + V_{GS} = -0.25V + (-0.32V) = \mathbf{-0.57V}$

Modified `sdevice_des.cmd`:
- **Step 2 (Gate Bias):** Ramps $V_G$ to **$-0.57V$** (was $0.05V$)
- $V_S$ remains at $-0.25V$.
- Initial $V_D$ remains at $-0.25V$.
- Drain pulse ramps from $-0.25V \rightarrow 1.0V$.

**Expected Behavior:** The device will now start deeply in the subthreshold regime. When the drain pulses to $1.0V$, the initial current will be extremely small ($\ll 1\mu A$). The high electric field at the drain will trigger Impact Ionization, generating holes that accumulate and gradually raise the potential, eventually causing the current to spike near $200nA$.

### Status: FIX APPLIED, PENDING RE-RUN

---

## 13. Run 6 Analysis (V_GS = -0.32V, V_G = -0.57V) — Too Deep in Subthreshold

### Run 6 Results (V_S = -0.25V, V_D(init) = -0.25V, V_G = -0.57V)
| Metric | Value |
|---|---|
| V_GS | **-0.32V** (confirmed from PLT) |
| V_DS at end of rise | **1.25V** (V_D=1.0V, V_S=-0.25V) |
| I_D at start (V_DS=0V) | **~0 A** ✅ |
| I_D at end of rise (t=10ns) | **1.6 nA** (but ~1.53 nA is gate leakage/displacement; actual channel current ~78 pA) |
| I_D steady-state (hold, t=2.5μs) | **74 pA** (flat, no change) |
| I_D at end of hold (t=5μs) | **74 pA** (flat, no change) |
| Source hole current (t=5μs) | **0.29 pA** (negligible — no Impact Ionization) |
| Spiking | **None** — current is flat at 74 pA for the entire 5μs hold |
| FE Polarization (Pol_y) | **~0.14 μC/cm²** (essentially zero; remnant Pr ≈ 22 μC/cm²) |

### Root Cause: V_GS Calculation Was Based on Wrong FE State

**The previous V_GS = -0.32V calculation (Section 12) was fundamentally flawed.**

The calibration CSV (`hysteresis_id_vg.csv`) was generated from a full ±6V hysteresis sweep. When we looked up "V_GS = -0.32V gives 202 nA", that data point came from a specific ferroelectric polarization state — the FE had been partially programmed by the sweep history. **In the transient simulation, the FE is in its VIRGIN (unpolarized) state** (confirmed by Pol_y ≈ 0.14 μC/cm² vs Pr ≈ 22 μC/cm²).

**Proof from calibration CSV initial sweep (virgin-like FE state, V_S=0V so V_G = V_GS):**
| Calibration V_G (= V_GS) | I_D | Notes |
|---|---|---|
| -0.06V | 7.36 μA | Just above threshold |
| -0.18V | 494 nA | **Near our 202 nA target!** |
| -0.42V | 80 pA | Deep subthreshold |
| -0.57V | 2.1 pA | Very deep subthreshold |

Our Run 6 used V_GS = -0.32V, which interpolates to ~3 nA on the initial sweep. The transient observation of 74 pA (at V_DS = 1.25V) is consistent with being deep in subthreshold. **At 74 pA, the channel current is ~2700x below the 202 nA target.** Impact Ionization cannot activate because:
1. II generation rate is proportional to drain current × ionization coefficient
2. At 74 pA, even with high ionization coefficients, the generated hole current is negligible (observed: 0.29 pA)
3. This is insufficient for the positive feedback loop (hole accumulation → body potential rise → current increase)

### The Fix (Run 7 Configuration)

**The correct V_GS must be derived from the INITIAL sweep of the calibration data** (which represents the virgin FE state matching our transient conditions).

From calibration initial sweep:
- V_GS = -0.18V → I_D = 494 nA (too high)
- V_GS = -0.42V → I_D = 80 pA (too low)
- **Target: I_D ≈ 200 nA → V_GS ≈ -0.20V** (log-interpolation)

Converting to transient V_G (where V_S = -0.25V):
$V_G = V_S + V_{GS} = -0.25V + (-0.20V) = \mathbf{-0.45V}$

However, DC calibration and transient conditions differ (V_DS, FE dynamics). **Recommended approach: V_GS sweep.**

| Run | V_GS | V_G (with V_S=-0.25V) | Expected I_D (from cal.) |
|---|---|---|---|
| 7a | -0.15V | -0.40V | ~1-5 μA (may be too high) |
| **7b** | **-0.20V** | **-0.45V** | **~100-500 nA (target range)** |
| 7c | -0.25V | -0.50V | ~10-50 nA (may be too low for II) |

**Start with Run 7b (V_G = -0.45V).** If current is in the ~100-500 nA range, II should have a chance to generate meaningful hole accumulation. If no spiking, adjust V_G up or down.

### Important Note on FE Pre-Programming
The paper's FeFET LIF neuron uses the ferroelectric polarization state as the "synaptic weight" — different FE states shift $V_{th}$, changing the firing threshold. For a complete FeFET LIF demonstration, a **WRITE step** (large V_G pulse to set FE state) should precede the LIF transient. However, for initial II/spiking verification, adjusting V_GS to match the virgin-state threshold is simpler and faster.

### Why This Is NOT an Impact Ionization Parameter Issue
The II parameters (d0_e = d0_h = 1e6) are NOT the problem. The problem is that at 74 pA of channel current, there is simply not enough carrier flow for II to generate a meaningful number of electron-hole pairs. Once the operating point is corrected to ~200 nA, the II mechanism should engage. If it doesn't, THEN we tune d0_e/d0_h.

### Status: OPERATING POINT ERROR IDENTIFIED — V_GS SWEEP NEEDED

---

## 14. Run 7b Analysis (V_GS = -0.20V, V_G = -0.45V) — II Active but Too Weak

### Run 7b Results (V_S = -0.25V, V_D(init) = -0.25V, V_G = -0.45V)
| Metric | Value |
|---|---|
| V_GS | **-0.20V** (confirmed from PLT: V_G = -0.45V) |
| V_DS at end of rise | **1.25V** (V_D=1.0V, V_S=-0.25V) |
| I_D at start (V_DS=0V) | **~0 A** ✅ |
| I_D at end of rise (t=10ns) | **8.52 nA** (drain total; channel current = 6.99 nA, gate leakage = 1.53 nA) |
| I_D steady-state (hold) | **6.95 nA** (flat from ~50ns onward) |
| Source hole current (t=10ns) | **-4.3 fA** |
| Source hole current (t=20ns) | **-44.1 fA** (rapid initial growth) |
| Source hole current (t=5μs) | **-65.0 fA** (saturated — no further growth) |
| II Multiplication Factor M | **9.35 × 10⁻⁶** (= 65 fA / 6.95 nA) |
| Spiking | **None** — current flat at 6.95 nA for entire 5μs |

### Key Finding: Impact Ionization IS Active, but Far Too Weak

Unlike Run 6 (where II was essentially zero), **Run 7b shows clear II activity:**
- Source hole current grew from 4.3 fA → 65 fA (15× increase) within the first ~100ns
- This proves II is generating electron-hole pairs at the drain junction
- However, the hole current **saturated at 65 fA** — generation = removal (recombination + leakage)
- There is **no net hole accumulation** in the floating body → no positive feedback → no spiking

### Subthreshold Swing Extraction (Two Transient Data Points)

Using Run 6 and Run 7b as calibration points for the **actual transient virgin FE state**:
| Run | V_GS | V_G | I_D (steady-state) |
|---|---|---|---|
| 6 | -0.32V | -0.57V | 74 pA |
| 7b | -0.20V | -0.45V | 6.95 nA |

$$SS = \frac{V_{GS2} - V_{GS1}}{\log_{10}(I_{D2}/I_{D1})} = \frac{0.12}{\log_{10}(93.9)} = \frac{0.12}{1.973} = \mathbf{60.8 \text{ mV/dec}}$$

This is essentially the Boltzmann limit (60 mV/dec), confirming excellent gate control. We can now **precisely calculate** V_GS for any target current:

| Target I_D | V_GS | V_G (V_S=-0.25V) |
|---|---|---|
| 50 nA | -0.147V | -0.397V |
| **200 nA** | **-0.111V** | **-0.361V** |
| 500 nA | -0.087V | -0.337V |
| 1 μA | -0.069V | -0.319V |

### Quantitative II Analysis: Why Spiking Doesn't Occur

**II Multiplication factor M = 9.35 × 10⁻⁶** (this depends on E-field at drain, NOT on channel current).

At the target 200 nA:
- I_hole = M × I_channel = 9.35e-6 × 200 nA = **1.87 pA**
- For a body capacitance C_body ≈ 0.01-0.1 fF:
  - dV_body/dt = 1.87 pA / 0.01 fF = 187,000 V/s → **60 mV in 0.32 μs** (could spike!)
  - dV_body/dt = 1.87 pA / 0.1 fF = 18,700 V/s → **60 mV in 3.2 μs** (marginal)

**Conclusion:** At 200 nA, spiking is **possible** if C_body is small enough. At 6.95 nA (Run 7b), the hole current was only 65 fA — insufficient even with the smallest body capacitance.

### Reference: Paper's II Parameters vs Ours vs Sentaurus Defaults

| Parameter | Paper (Bhatawdekar) | Our Value | Sentaurus Si Default |
|---|---|---|---|
| d0_e | 1×10⁶ | 1×10⁶ | **7.10×10⁵** |
| d0_h | 1×10⁶ | 1×10⁶ | **2.08×10⁶** |

Our d0_e is **1.41× higher** than the Sentaurus default for silicon, meaning we are **slightly suppressing** electron-initiated II compared to the physically calibrated value. The paper uses the same d0=1e6, but their device (no FE layer, different field distribution) achieves spiking at I_th=94 nA.

### The Fix (Run 8 — Two-Pronged Approach)

**1. Operating Point Fix (PRIMARY):** V_G = -0.36V (V_GS = -0.111V, target ~200 nA)
- At ~200 nA, hole generation increases ~30× (from 65 fA → ~1.9 pA)
- This may be sufficient to tip the balance toward net hole accumulation

**2. If Run 8 Shows No Spiking → II Parameter Tuning (SECONDARY):**
The paper (Section 2.3) swept d0_e/d0_h from 1e5 to 9e6. Our FeFET may need different values due to the HZO layer affecting field distribution. Iterative guide:

| Step | d0_e | d0_h | Rationale |
|---|---|---|---|
| 8a | 1e6 | 1e6 | Current (paper's value). Test with corrected V_GS first. |
| 8b | 7.1e5 | 2.08e6 | Sentaurus Si default. Increases electron II by ~1.4×. |
| 8c | 5e5 | 5e5 | Moderate increase. Both carriers enhanced. |
| 8d | 1e5 | 1e5 | Strong II enhancement. Paper's lower sweep bound. |

**Tuning rules (to preserve calibration):**
- d0_e/d0_h only affect II generation, which is negligible in DC I_D-V_G sweeps at low V_DS
- Changing d0 does **NOT** affect V_th, I_on, MW, or any calibration parameters
- The calibration (Step A+B) used `Quasistationary` at V_DS ≤ 1V where II is minimal
- Therefore, **d0 tuning cannot break existing calibration** ✅
- Do NOT change AreaFactor, Workfunction, FixedCharge, or FE parameters

### Status: OPERATING POINT + II ANALYSIS COMPLETE — RUN 8 READY

---

## 15. Run 8 Analysis (V_GS = -0.11V, V_G = -0.36V) — Operating Point Hit, but II Collapsed

### Run 8 Results (V_S = -0.25V, V_D(init) = -0.25V, V_G = -0.36V)
| Metric | Value |
|---|---|
| V_GS | **-0.11V** (confirmed from PLT: V_G = -0.36V) |
| V_DS at end of rise | **1.25V** (V_D=1.0V, V_S=-0.25V) |
| I_D at start (V_DS=0V) | **~0 A** ✅ |
| I_D at end of rise (t=10ns) | **184.95 nA** (drain total; channel current = 183.41 nA, gate leakage = 1.54 nA) |
| I_D steady-state (hold) | **182.59 nA** (flat from ~15ns onward) — **within 9% of 200 nA target** ✅ |
| Source hole current (t=10ns) | **-5.74 fA** |
| Source hole current (t=20ns) | **-9.15 fA** |
| Source hole current (t=5μs) | **-9.15 fA** (immediately saturated) |
| II Multiplication Factor M | **4.99 × 10⁻⁸** (= 9.15 fA / 183.4 nA) |
| Spiking | **None** — current flat at 182.6 nA for entire 5μs |

### Critical Finding: Impact Ionization Collapsed Despite Correct Operating Point

**Comparison across runs:**

| Run | V_GS | I_D (steady) | I_hole (source) | II Multiplication M |
|---|---|---|---|---|
| 6 | -0.32V | 74 pA | negligible | ~0 |
| 7b | -0.20V | 6.95 nA | 65 fA | **9.35 × 10⁻⁶** |
| 8 | -0.11V | 183.4 nA | 9.15 fA | **4.99 × 10⁻⁸** |

**The paradox:**
- Run 7b → Run 8: Channel current increased **26.4×** (6.95 nA → 183.4 nA) ✅
- But II multiplication **dropped 530×** (9.35e-6 → 4.99e-8) ✗

This is the opposite of what we expected. Higher channel current should provide more carriers for II, not less.

### Root Cause: Gate Control Kills Drain-Body Reverse Bias

**Physics mechanism:**
1. At V_GS = -0.20V (Run 7b), the gate is weakly ON. The body potential is largely determined by the floating body charge balance.
2. At V_GS = -0.11V (Run 8), the gate pulls the body potential **up** (less negative).
3. Higher body potential → **reduced drain-body reverse bias** → lower E-field at drain junction → drastically reduced II.
4. The II generation rate is exponentially dependent on the electric field: $\alpha \propto \exp(-d/E)$.

**Quantitative estimate:**
- M dropped by 530× → implies E-field dropped by roughly 10-15% (due to exponential dependence)
- This small field reduction is exactly what we'd expect from a ~0.09V increase in body potential (V_GS: -0.20V → -0.11V)

### Why the Paper Achieves Spiking at 94 nA and We Cannot at 183 nA

The Bhatawdekar paper (no FE layer):
- I_th = 94 nA
- d0_e = d0_h = 1e6
- Device spikes successfully

Our FeFET (with HZO layer):
- I_D = 183.4 nA (2× higher)
- d0_e = d0_h = 1e6 (same as paper)
- M = 4.99e-8 → I_hole = 9.15 fA → **cannot spike**

**The difference:** The HZO ferroelectric layer creates a **different electrostatic field distribution** compared to a standard SiO₂ gate dielectric. The capacitive voltage divider effect (C_ox vs C_fe) affects how V_GS translates to body potential, changing the drain-body junction bias. Our device requires **stronger II parameters** to compensate.

### The Fix: Impact Ionization Parameter Tuning (Calibration-Safe)

**Operating point is now correct.** Further V_GS adjustment will not help — it's a field distribution issue, not a current issue.

**Solution:** Reduce d0_e/d0_h to enhance II generation. Lower d0 → higher ionization coefficient α → more electron-hole pair generation at the same E-field.

**Why this is calibration-safe:**
- The calibration (Step A: electrostatic baseline, Step B: hysteresis) used `Quasistationary` sweeps at **V_DS ≤ 1V**
- At low V_DS, drain E-field is weak → II is negligible (generates <1 pA even with d0=1e5)
- Therefore, d0_e/d0_h have **zero effect** on V_th, I_on, I_off, or Memory Window
- **d0 tuning cannot break existing calibration** ✅

### Run 8a Plan: Sentaurus Silicon Defaults

Update `sdevice_gaafet_lif.par`:
```
d0_e = 7.1e5   (was 1e6 → 1.41× II boost)
d0_h = 2.08e6  (was 1e6 → 2.08× II boost)
```

These are the **physically calibrated default values for silicon** from the Sentaurus library (verified in Power/IGBT examples).

**Expected outcome:**
- Electron II: 1.41× stronger → e-h pair generation increases
- Hole II: 2.08× stronger → hole current feedback increases
- Combined effect: M should increase by 1.5-3× (approximate, nonlinear)
- If M reaches ~1.5e-7, I_hole = 27 fA → still marginal
- If insufficient, proceed to Run 8b (d0 = 5e5) or 8c (d0 = 1e5)

### Status: II PARAMETER TUNING INITIATED — RUN 8a READY

---

## 16. Run 8a/8b/8c Analysis — Impact Ionization Parameter Sweep FAILED

### Configuration
All three runs used V_G = -0.36V, V_S = -0.25V, V_D pulsed from -0.25V → 1.0V (identical to Run 8).
Only the II parameters (d0_e, d0_h) in `sdevice_gaafet_lif.par` were changed:

| Run | d0_e | d0_h | II Boost Factor |
|---|---|---|---|
| 8 (baseline) | 1×10⁶ | 1×10⁶ | 1× (paper value) |
| **8a** | **7.1×10⁵** | **2.08×10⁶** | **1.4× e / 2.1× h (Si defaults)** |
| **8b** | **5×10⁵** | **5×10⁵** | **2× e / 2× h (moderate boost)** |
| **8c** | **1×10⁵** | **1×10⁵** | **10× e / 10× h (strong boost, paper lower bound)** |

**Verification:** d0 values confirmed loaded correctly from each run's `n5_des.log` file (line ~1067-1068).

### Results: ALL THREE RUNS ARE BYTE-IDENTICAL

| Metric | Run 8a | Run 8b | Run 8c |
|---|---|---|---|
| I_D steady-state | 182.59 nA | 182.59 nA | 182.59 nA |
| Source hole current | 9.15 fA | 9.15 fA | 9.15 fA |
| M (II mult) | 5.01×10⁻⁸ | 5.01×10⁻⁸ | 5.01×10⁻⁸ |
| Spiking | None | None | None |
| **File MD5 hash** | **5CFC848B...** | **5CFC848B...** | **5CFC848B...** |

**MD5 hash verification:** All `fire_hold_n5_des.plt` files have identical hash `5CFC848B059430956949BD878146652B`. The outputs are not just "similar" — they are **byte-for-byte identical** despite d0 varying by 7× (from 7.1e5 to 1e5).

File timestamps confirm separate simulation runs (8c: 11:28, 8b: 11:52, 8a: 12:02 on Mar 23).

### Root Cause: Impact Ionization Generates ZERO Carriers

Changing d0 by 7× produced zero change in output. This is physically possible only when:

$$\alpha(F, T) = \frac{F_{ava}}{a(T) + b(T) \cdot \exp\left[\frac{d(T)}{F_{ava} + c(T)}\right]}$$

If $F_{ava}$ (the driving electric field at the drain junction) is **far below** the critical field for any d0 value, then $\alpha \approx 0$ for all d0 → II generation = 0 → changing d0 has no effect.

**The 9.15 fA of source hole current is NOT from Impact Ionization.** It comes from **Band2Band tunneling** (Hurkx model), whose parameters (Agen=4e14, Bgen=1.9e7, Pgen=2.5) were unchanged across all runs. This explains the byte-identical output.

### Why the Drain Junction Field Is Too Low

The Bhatawdekar paper uses a **standard GAA FNSFET** (no ferroelectric layer):
- Gate stack: Metal (WF=4.6eV) / SiO₂ (2nm) / Si channel
- VDS directly creates a strong reverse-bias field at the drain-body junction
- The paper shows clear kink effect in output characteristics (Fig 5)

Our device is a **GAA-FeFET** with HZO layer:
- Gate stack: Metal (WF=4.35eV) / HZO / SiO₂ / Si channel
- The HZO layer changes the capacitive voltage divider
- The gate-all-around geometry provides excellent electrostatic control (by design — this is good for logic, bad for II)
- The strong gate coupling **screens** the drain field from the body
- The drain-body junction field is insufficient to trigger avalanche generation at any d0

### Critical Missing Step: Output Characteristics Were Never Verified

**The paper (Bhatawdekar, Fig 5 and Fig 7) explicitly shows ID-VDS output characteristics with a visible kink effect.** This kink IS the Impact Ionization signature. The paper:
1. First verified the kink exists in DC output curves
2. Then optimized d0 parameters to control the kink onset
3. Only then ran transient spiking simulations

**We never ran output characteristics (ID-VDS sweep).** We went directly from hysteresis calibration (ID-VGS) to transient spiking. Without verifying the kink exists in DC, there was no reason to expect spiking in transient.

### Conclusion: Spiking Debugging Path Was Incorrect from Run 5 Onwards

From Run 5 onwards, we attempted to find the correct operating point by adjusting voltages. While each individual fix was valid (correct biasing order, zero initial VDS, correct VGS for target current), the **underlying assumption — that our device can produce Impact Ionization — was never verified.**

The entire debugging effort was adjusting operating parameters for a mechanism that doesn't exist in our current device structure. The correct first step should have been:
1. Run output characteristics (ID-VDS) at multiple VGS
2. Verify kink effect exists
3. Only then proceed to transient spiking

### Status: ❌ II PARAMETER TUNING FAILED — FUNDAMENTAL DEVICE ISSUE CONFIRMED

---

## 17. Comprehensive Calibration & Methodology Review

### What the Paper (Bhatawdekar) Did for Calibration

From Section 2.2: *"The simulation framework utilized in this research is **thoroughly calibrated** against the work of N. Loubet et al., achieving a close match through careful adjustments of **velocity saturation, mobility, source/drain resistances, and metal work function**, as illustrated in Fig. 2(d)."*

Paper's calibration procedure:
1. **Full ID-VGS curve match** against Loubet experimental data (Fig 2d) — not just 2 points
2. Calibrated: velocity saturation, mobility, S/D resistances, work function
3. Verified SS, DIBL at Lg=12nm (SSat=75 mV/dec, DIBL=32mV)
4. Ran **output characteristics (ID-VDS)** at multiple VGS (Fig 5) — verified kink effect
5. **Swept d0** from 1e5 to 9e6 (Fig 7a) — selected d0=1e6 for biological current levels
6. Verified kink onset at VD=1.0V
7. Set Ith=94nA from kink analysis in ID-VGS at VDS=1.0V (Fig 7b)
8. THEN ran transient spiking simulations (Fig 8, Fig 9)

### What Our Calibration Actually Did

From `Calibration_Log_2026_01_15.md`:

**Stage 1 (DC — Runs 1-5):** Swept FixedCharge and AreaFactor to match Vth=0.25V and Ion=600μA.
- Only matched 2 numbers at a single point
- Did NOT match full ID-VGS curve shape
- Did NOT verify SS, DIBL, Ioff

**Stage 2 (Hysteresis — Runs 6-13):** Activated FE, switched to Transient solver, recalibrated AreaFactor.
- Successfully achieved CCW hysteresis loop
- But lost DC calibration, required WF shift

**Stage 3 (Final — Runs 14-16):** Re-tuned WF=4.35eV, FixedCharge=4e12, AreaFactor=0.071.
- Matched Vth(Fwd)=0.263V and Ion=604μA
- MW=0.68V (good)

**What was NOT done:**
- ❌ Full ID-VGS curve shape matching (only 2 points)
- ❌ Output characteristics (ID-VDS) verification — **CRITICAL OMISSION**
- ❌ Kink effect verification
- ❌ Subthreshold swing verification at calibration stage
- ❌ DIBL verification
- ❌ Velocity saturation calibration
- ❌ S/D resistance calibration
- ❌ Par file modification during calibration (par file was fixed throughout)
- ❌ Comparison against Loubet experimental data

### Specific Parameter Discrepancies

| Parameter | Paper (Bhatawdekar) | Our Value | Issue |
|---|---|---|---|
| Workfunction | 4.6 eV | 4.35 eV | 0.25 eV discrepancy |
| Gate Oxide | SiO₂ (2nm) | SiO₂ + HZO (ferroelectric) | Fundamentally different stack |
| FixedCharge | Not specified | 4×10¹² cm⁻² | Very high — compensating for structural mismatch |
| AreaFactor | 0.033 μm² effective | 0.071 | 2.15× discrepancy |
| Mobility (e⁻) | Calibrated (Lombardi + PhuMob) | Fixed at 300 cm²/Vs | Not calibrated |
| S/D Resistance | Calibrated (7 Ω·μm²) | Not explicitly set | Not calibrated |
| Contact Resist | 7 Ω·μm² | Not set | Missing |

### Assessment: Calibration Was Insufficient for LIF Neuron Operation

The calibration successfully achieved the hysteresis targets (Vth, Ion, MW) which are sufficient for **memory/synaptic weight** operation. However, it is **fundamentally insufficient** for **LIF neuron** operation because:

1. LIF operation requires Impact Ionization, which depends on the **drain junction electric field**
2. The drain field depends on output characteristics (ID-VDS), which were never verified
3. The HZO layer changes the electrostatic coupling between gate and drain, potentially killing II
4. Without output characteristics verification, there's no evidence our device can support II

---

## 18. Corrected Path Forward

### Phase 1A: Verify II Capability (IMMEDIATE — MUST DO FIRST)

**Goal:** Determine if our GAA-FeFET structure can produce Impact Ionization at all.

**Action:** Run output characteristics (ID-VDS sweep) at multiple VGS values.

Modify `sdevice_des.cmd` for a DC output characteristics sweep:
1. Set VGS = 0.3V (above Vth), VGS = 0.5V, VGS = 1.0V
2. Sweep VDS from 0V to 2.0V (Quasistationary)
3. Look for kink (sudden slope change) in ID-VDS curve
4. Use d0_e = d0_h = 1e5 (maximum II) for this test

**Expected outcomes:**
- **If kink observed:** Device supports II → problem was transient biasing/operating point → proceed to Phase 1B
- **If NO kink at any VGS up to VDS=2.0V:** Device structure cannot support II → proceed to Phase 1C

### Phase 1B: If Kink Observed — Transient Spiking with Corrected Biasing

Re-run transient spiking with the VGS/VDS that produced the kink.

### Phase 1C: If No Kink — Structural Root Cause Isolation

Run the **same output characteristics** but with FE physics DISABLED:
```
* Physics(Material="HZO") {
*     Polarization
* }
```

- **If kink appears without FE:** The HZO layer is screening the drain field → need to either remove FE for LIF or re-engineer the stack
- **If no kink even without FE:** The base GAA structure doesn't support II with current dimensions/doping → need structural changes (doping profile, channel thickness, etc.)

### Phase 1D: Proper Calibration (If Structural Changes Needed)

1. Match full ID-VGS curve against Loubet data (if available) or paper data
2. Calibrate velocity saturation, S/D resistance
3. Verify output characteristics with kink
4. Then re-enable FE and verify hysteresis + kink coexist
