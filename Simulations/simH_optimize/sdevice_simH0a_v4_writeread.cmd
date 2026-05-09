*===================================================================
*== PHASE 1D — SIM H0a v4: TASNEEM-PROTOCOL I_D-V_G READ
*== Reference: Tasneem 2022 IEEE TED Fig 3(b)/(c)
*== Target: dV_t ~ 0.5 V, SS_post-write ~ 110 mV/dec
*==
*== v4 changes vs v3 (2026-05-09 run gave MW = 40 mV, target = 500 mV):
*==   - Pulse hold: 1 us -> 10 us (matches Tasneem spec exactly;
*==     pw/tau_E = 10, drives FE to full saturation)
*==   - Pulse magnitude: ±4 V (unchanged)
*==   - Read window: -1.5 V -> +1.0 V (unchanged)
*==
*== If v4 still gives MW < 200 mV, escalate v5: pulse magnitude
*== ±4 V -> ±6 V (matches simC v6 / closer to Tasneem's drive
*== overhead of 5 V vs V_c,gate = 1.91 V).
*==
*== Sequence (timestamps shifted to accommodate longer holds):
*==   0. Init Poisson
*==   1. Ramp V_DS to 0.05 V at V_G = 0
*==   2. Baseline read at V_G = 0
*==   3. ERS pulse: 0 -> -4 V (1 ns) + hold 10 us + -> 0 (1 ns)
*==   4. Pre-read setup: ramp V_G to -1.5 V
*==   5. Read 1 (post-ERS): V_G sweep -1.5 -> +1.0 V (100 ns)
*==   6. Pre-pulse setup: ramp V_G to 0
*==   7. PGM pulse: 0 -> +4 V + hold 10 us + -> 0
*==   8. Pre-read setup: ramp V_G to -1.5 V
*==   9. Read 2 (post-PGM): V_G sweep -1.5 -> +1.0 V
*===================================================================

File {
    Grid       = "@tdr@"
    Parameter  = "sdevice_gaafet_lif.par"
    Plot       = "@tdrdat@"
    Current    = "@plot@"
    Output     = "@log@"
}

Electrode {
  { Name="source_contact"  Voltage= 0.0 }
  { Name="drain_contact"   Voltage= 0.0 }
  { Name="gate_contact"    Voltage= 0.0  Workfunction=4.35 }
}

Physics {
  Temperature= 300
  Areafactor= 0.071
  Fermi
  EffectiveIntrinsicDensity( OldSlotboom )
  Mobility( PhuMob Enormal )
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

Math {
   Extrapolate
   RelErrControl
   Digits=5
   Notdamped=50
   Iterations=50
   Transient=BE
   FEPolarizationIP=1.0
   Method=Blocked
   SubMethod=ParDiSo
   GeometricDistances
   Derivative
   ComputeGradQuasiFermiAtContacts= UseQuasiFermi
   RefDens_eGradQuasiFermi_ElectricField_HFS= 1.000e+12
   RefDens_hGradQuasiFermi_ElectricField_HFS= 1.000e+12
   Method = Bitlis (Restart=100, Tolerance=1e-5, Iterations=200)
}

Plot {
  eDensity hDensity
  TotalCurrent/Vector ElectricField/Vector Potential SpaceCharge
  ConductionBand ValenceBand Doping Polarization/Vector
  BandGap SRHRecombination AugerRecombination eMobility hMobility
}

CurrentPlot {
  Polarization/Vector (( 0 0.0145 ))
  ElectricField/Vector (( 0 0.0145 ))
}

Solve {

  *=== STEP 0: INITIALIZE ===
  Transient (
    InitialTime=0 FinalTime=1
  ) { Coupled (Iterations = 100) { Poisson } }

  *=== STEP 1: RAMP V_DS TO 0.05 V ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: BASELINE READ AT V_G=0 ===
  NewCurrentPrefix="baseline_"
  Transient (
    InitialTime=0 FinalTime=1.0000e-07
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 3: ERS PULSE — 10 us hold ===
  NewCurrentPrefix="ers_rise_"
  Transient (
    InitialTime=1.0000e-07 FinalTime=1.0100e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -4.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="ers_hold_"
  Transient (
    InitialTime=1.0100e-07 FinalTime=1.0010e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="ers_fall_"
  Transient (
    InitialTime=1.0010e-05 FinalTime=1.0011e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 4: RAMP V_G TO -1.5 V FOR READ START ===
  NewCurrentPrefix="setup_readERS_"
  Transient (
    InitialTime=1.0011e-05 FinalTime=1.0012e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -1.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 5: READ 1 — POST-ERS SWEEP -1.5 V -> +1.0 V ===
  NewCurrentPrefix="read_postERS_"
  Transient (
    InitialTime=1.0012e-05 FinalTime=1.0112e-05
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7
    Increment=1.2
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 6: RAMP V_G BACK TO 0 BEFORE PGM ===
  NewCurrentPrefix="ret0_preP_"
  Transient (
    InitialTime=1.0112e-05 FinalTime=1.0113e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 7: PGM PULSE — 10 us hold ===
  NewCurrentPrefix="pgm_rise_"
  Transient (
    InitialTime=1.0113e-05 FinalTime=1.0114e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 4.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="pgm_hold_"
  Transient (
    InitialTime=1.0114e-05 FinalTime=2.0114e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="pgm_fall_"
  Transient (
    InitialTime=2.0114e-05 FinalTime=2.0115e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 8: RAMP V_G TO -1.5 V FOR SECOND READ ===
  NewCurrentPrefix="setup_readPGM_"
  Transient (
    InitialTime=2.0115e-05 FinalTime=2.0116e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -1.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 9: READ 2 — POST-PGM SWEEP -1.5 V -> +1.0 V ===
  NewCurrentPrefix="read_postPGM_"
  Transient (
    InitialTime=2.0116e-05 FinalTime=2.0216e-05
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7
    Increment=1.2
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

}
