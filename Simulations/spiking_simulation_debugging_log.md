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

## 4. Next Steps
The debugging process was halted due to a **Sentaurus License Error**.
Once the license issue is resolved:
1.  **Delete** old log/output files in `spiking_runs`.
2.  **Run** the simulation with the current `sdevice_des.cmd`.
3.  **Verify** that the "Nuclear Option" successfully allows the simulation to complete the 50ps transient.
