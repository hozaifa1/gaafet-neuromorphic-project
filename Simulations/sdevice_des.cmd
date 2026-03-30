*===================================================================
*== Block 1: FILE I/O
*===================================================================
File {
    Grid = "@tdr@"
    Parameter = "sdevice_gaafet_lif.par"
    Plot = "@tdrdat@"
    Current = "@plot@"
    Output = "@log@"
}  

*===================================================================
*== Block 2: ELECTRODES
*== Note: Source grounded, drain at small read bias.
*==       Gate receives pulse train for polarization switching.
*===================================================================
Electrode {
  { Name="source_contact"     Voltage= 0.0 }
  { Name="drain_contact"      Voltage= 0.0 }
  { Name="gate_contact"       Voltage= 0.0  Workfunction=4.35 }
}

*===================================================================
*== Block 3: PHYSICS
*== Simplified for polarization-based LIF (no II needed).
*== Avalanche and Hydrodynamic removed — not relevant.
*===================================================================
Physics {
  Temperature= 300
  Areafactor=0.071

  Fermi
  EffectiveIntrinsicDensity( OldSlotboom )

  Mobility(
    PhuMob
    Enormal
  )
  Recombination(
    SRH (DopingDependence TempDependence)
    Auger
    Band2Band(Model=Hurkx)
  )
}

Physics(Material="HZO") {
    Polarization
}

Physics(MaterialInterface="Silicon/SiO2") {
    Traps(
        (FixedCharge Conc=4e12 Level EnergyMid=0.0 fromMidBandGap)
    )
}

*===================================================================
*== Block 4: MATH
*===================================================================
Math {
   Extrapolate
   RelErrControl
   Digits=4
   Notdamped=50
   Iterations=20
   Transient=BE
   Method=Blocked
   SubMethod=ParDiSo

   GeometricDistances
   Derivative

   ComputeGradQuasiFermiAtContacts= UseQuasiFermi
   RefDens_eGradQuasiFermi_ElectricField_HFS= 1.000e+12
   RefDens_hGradQuasiFermi_ElectricField_HFS= 1.000e+12
}

*===================================================================
*== Block 5: PLOT
*===================================================================
Plot {
  eDensity hDensity
  TotalCurrent/Vector
  ElectricField/Vector
  Potential
  SpaceCharge
  ConductionBand
  ValenceBand
  Doping
  Polarization/Vector
  BandGap
  SRHRecombination AugerRecombination
  eMobility hMobility
}

*===================================================================
*== Block 5b: CURRENT PLOT
*== Probe at center of top HZO (x=0, y=0.0145)
*===================================================================
CurrentPlot {
  Polarization/Vector (( 0 0.0145 ))
  ElectricField/Vector (( 0 0.0145 ))
}

*===================================================================
*== Block 6: SOLVE — PHASE 1A PROTOTYPE (SUPERSEDED)
*==
*== STATUS (March 30, 2026): This file is the ORIGINAL Phase 1A
*== prototype with single-pulse characterization. It has been
*== SUPERSEDED by the dedicated simulation files:
*==
*==   SimA: simA/sdevice_phase1a_simA_transient.cmd  (single pulse)
*==   SimB: simB/sdevice_phase1a_simB_transient.cmd  (multi-pulse)
*==   SimC: simC/sdevice_simC_v6.cmd                 (FINAL: LIF cycle, FIRE!)
*==
*== PHASE 1 RESULT: Fire demonstrated at Vpulse=6V, pulse 9.
*== Optimal: pw=100ns, tau_E=1us, pw/tau_E=0.1, Vreset=-5V.
*==
*== STEP 2 NEXT ACTIONS (tau_P characterization):
*==   1. Use simC/sdevice_simC_v6.cmd as the base
*==   2. Change tau_P in .par file: 1e-6, 1e-5, 1e-4 s (one at a time)
*==   3. Re-run v6 for each tau_P value (6V node only)
*==   4. Compare leak gap decay rates to extract tau_leak for SNN model
*==   5. Feed tau_leak into Step_2/lif_parameters.py
*==
*== ORIGINAL SWEEP PARAMETERS (retained for reference):
*==   Gate pulse amplitude:  0.5V, 1.0V, 1.5V, 2.0V, 2.5V, 3.0V
*==   Gate pulse width:      10ns, 100ns, 1us, 10us, 100us
*==   Number of pulses:      1, 5, 10, 20, 50
*==   Inter-pulse interval:  100ns, 1us, 10us, 100us
*==   V_DS (read bias):      0.05V, 0.5V, 1.0V
*==   Reset pulse amplitude: -1.0V, -2.0V, -3.0V, -4.0V
*==   tau_E (in .par file):  0.1ns, 1ns, 10ns
*==   tau_P (in .par file):  0, 1us, 10us, 100us
*===================================================================

Solve {

  *=== STEP 0: INITIALIZE ===
  Transient (
    InitialTime=0 FinalTime=1
  ) { Coupled (Iterations = 100) { Poisson } }

  *=== STEP 1: SET DRAIN READ BIAS ===
  * Constant V_DS during entire pulse train.
  * SWEEP: 0.05V (linear), 0.5V (moderate), 1.0V (saturation)
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.05 }
    * Goal { Name="drain_contact" Voltage= 0.5 }
    * Goal { Name="drain_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: GATE PULSE #1 (Sub-coercive — Integration) ===
  * Rise: ramp gate from 0V to pulse amplitude
  * SWEEP amplitude: 0.5V, 1.0V, 1.5V, 2.0V, 2.5V, 3.0V
  * SWEEP pulse width: 10ns, 100ns, 1us, 10us, 100us
  * NOTE: Transient+Goal uses NORMALIZED step sizes (fractions 0-1)

  * --- Pulse 1 Rise ---
  NewCurrentPrefix="pulse1_rise_"
  Transient (
    InitialTime=0 FinalTime=1e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.5 }
    * Goal { Name="gate_contact" Voltage= 0.5 }
    * Goal { Name="gate_contact" Voltage= 1.0 }
    * Goal { Name="gate_contact" Voltage= 2.0 }
    * Goal { Name="gate_contact" Voltage= 2.5 }
    * Goal { Name="gate_contact" Voltage= 3.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0 1e-9) Intervals=100) )
  }

  * --- Pulse 1 Hold (at pulse amplitude) ---
  * Duration = pulse width. SWEEP: 10ns, 100ns, 1us, 10us
  * No Goal -> step sizes are ABSOLUTE seconds.
  NewCurrentPrefix="pulse1_hold_"
  Transient (
    InitialTime=1e-9 FinalTime=101e-9
    * InitialTime=1e-9 FinalTime=11e-9       * 10ns pulse
    * InitialTime=1e-9 FinalTime=1.001e-6    * 1us pulse
    * InitialTime=1e-9 FinalTime=10.001e-6   * 10us pulse
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1e-9 101e-9) Intervals=200) )
  }

  * --- Pulse 1 Fall (return gate to 0V) ---
  NewCurrentPrefix="pulse1_fall_"
  Transient (
    InitialTime=101e-9 FinalTime=102e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(101e-9 102e-9) Intervals=100) )
  }

  *=== STEP 3: INTER-PULSE INTERVAL (Leak observation) ===
  * Wait with gate at 0V. Monitor Vth relaxation via ID.
  * SWEEP interval: 100ns, 1us, 10us, 100us
  NewCurrentPrefix="wait1_"
  Transient (
    InitialTime=102e-9 FinalTime=1.102e-6
    * InitialTime=102e-9 FinalTime=202e-9       * 100ns wait
    * InitialTime=102e-9 FinalTime=10.102e-6    * 10us wait
    * InitialTime=102e-9 FinalTime=100.102e-6   * 100us wait
    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(102e-9 1.102e-6) Intervals=500) )
  }

  *=== STEP 4: READ AFTER PULSE 1 ===
  * Quick ID-VGS sweep to extract Vth shift from single pulse.
  * Sweep VGS from -0.5V to +1.0V at fixed VDS.
  NewCurrentPrefix="read1_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  Quasistationary (
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  * Return gate to 0V for next pulse
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 5: ADDITIONAL PULSES (Copy pulse 1 block N times) ===
  * For multi-pulse integration test, duplicate Steps 2-4 above
  * with updated InitialTime/FinalTime for pulses 2, 3, ... N.
  * Track cumulative Vth shift after each pulse.
  *
  * For initial characterization, start with 1 pulse (above),
  * then extend to 5, 10, 20, 50 pulses programmatically or
  * via Sentaurus Workbench parameter sweep.

  *=== STEP 6: RESET VERIFICATION ===
  * After N pulses, apply negative gate pulse to reset FE.
  * SWEEP reset amplitude: -1.0V, -2.0V, -3.0V, -4.0V
  * SWEEP reset width: 10ns, 100ns, 1us
  *
  * NewCurrentPrefix="reset_rise_"
  * Transient (
  *   InitialTime=<after_last_pulse> FinalTime=<+1ns>
  *   InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
  *   Increment=1.4
  *   Goal { Name="gate_contact" Voltage= -3.0 }
  *   * Goal { Name="gate_contact" Voltage= -1.0 }
  *   * Goal { Name="gate_contact" Voltage= -2.0 }
  *   * Goal { Name="gate_contact" Voltage= -4.0 }
  * ) {
  *     Coupled (Iterations = 100) {Poisson Electron Hole}
  *     CurrentPlot( Time = (Range=(<start> <end>) Intervals=100) )
  * }
  *
  * NewCurrentPrefix="reset_hold_"
  * Transient (
  *   InitialTime=<+1ns> FinalTime=<+101ns>
  *   InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
  *   Increment=1.4
  * ) {
  *     Coupled (Iterations = 100) {Poisson Electron Hole}
  *     CurrentPlot( Time = (Range=(<start> <end>) Intervals=200) )
  * }
  *
  * NewCurrentPrefix="reset_fall_"
  * Transient (
  *   InitialTime=<+101ns> FinalTime=<+102ns>
  *   InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
  *   Increment=1.4
  *   Goal { Name="gate_contact" Voltage= 0.0 }
  * ) {
  *     Coupled (Iterations = 100) {Poisson Electron Hole}
  * }
  *
  * Then re-run ID-VGS read sweep to verify Vth recovered.

}
