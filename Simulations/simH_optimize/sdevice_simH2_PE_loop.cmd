*===================================================================
*== PHASE 1D — SIM H2 v2: P-E LOOP + CV at the H1-chosen V_pgm
*==
*== v1 INVALIDATED (2026-05-11): same System/Vsource_pset/pwl
*==   pulse-delivery bug as H1 v1 — the pgm/ers transient pulses
*==   would silently fail to drive the gate.  Rewritten with the
*==   simC v6 / H0a v5 pattern: top-level Electrode block,
*==   Goal-driven Transient for the program & erase pulses.
*==
*== v1 also used @WF@ as a SWB parameter, but the WF sweep was
*==   invalidated in the H1 v1 header comments (polarization charge
*==   dominates V_th by 15× over the WF sweep range).  v2 fixes
*==   WF = 4.35 to match the rest of the project.
*==
*== Goal: extract memory window (CV midpoint shift virgin → post-pgm
*==   → post-ers) at the H1-chosen V_pgm, and report ≥9 distinguishable
*==   ΔV_t steps when V_pgm is stepped 0.2 V (M3, M4).
*==
*== SWB parameter:  @V_pgm@  ∈ {1.5, 2.0, 2.5, 3.5, 6.0} V
*==   (Set V_pgm = 6.0 V on one node as a Phase-1C-reference sanity
*==   check that the new par still reproduces the −25 mV CV shift.)
*==
*== Cadence: pgm pulse = 10 ns rise / 100 ns hold / 10 ns fall +
*==   100 ns settle; then erase pulse with opposite sign at same
*==   timings.  Each CV sweep is a Quasistationary V_G sweep −1 → +1 V
*==   with ACCoupled @ 1 MHz (same as simG).
*===================================================================

File {
    Grid       = "@tdr@"
    Parameter  = "sdevice_gaafet_lif.par"
    Plot       = "@tdrdat@"
    Current    = "@plot@"
    ACExtract  = "@acplot@"
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

  *=== STEP 2: RAMP V_G TO -1 V (start of virgin CV) ===
  NewCurrentPrefix="gate_init_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE A: VIRGIN CV SWEEP (-1 V → +1 V at f=1 MHz) ===
  *== Same ACCoupled pattern as simG.  Used to extract C_gg(V_GS)
  *== and the CV-midpoint V_th_virgin.
  NewCurrentPrefix="cv_virgin_"
  Quasistationary (
    DoZero
    InitialStep=1e-2 Increment=1.5
    MinStep=1e-5 MaxStep=0.04
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { ACCoupled (
        StartFrequency= 1e+06 EndFrequency= 1e+06 NumberOfPoints= 1 Decade
        Node(gate_contact drain_contact source_contact)
        Exclude(gate_contact drain_contact source_contact)
        ACCompute (Time= (Range=(0 1) Intervals=80))
      ) { Poisson Electron Hole }
  }

  *=== STEP 3: RETURN TO V_G = 0.2 V before the program pulse ===
  NewCurrentPrefix="gate_to_read_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE B PRECONDITION: PROGRAM PULSE at +V_pgm (Goal-driven) ===
  *== Rise/fall: Transient + Goal with normalized step sizes
  *==   (debug-log §2 Root Cause 2).
  *== Hold/settle: bare Transient with absolute step sizes.
  NewCurrentPrefix="pgm_rise_"
  Transient (
    InitialTime=0 FinalTime=1.0e-08
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0 1.0e-08) Intervals=10) )
  }
  NewCurrentPrefix="pgm_hold_"
  Transient (
    InitialTime=1.0e-08 FinalTime=1.1e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0e-08 1.1e-07) Intervals=20) )
  }
  NewCurrentPrefix="pgm_fall_"
  Transient (
    InitialTime=1.1e-07 FinalTime=1.2e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1e-07 1.2e-07) Intervals=10) )
  }
  NewCurrentPrefix="pgm_settle_"
  Transient (
    InitialTime=1.2e-07 FinalTime=2.2e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2e-07 2.2e-07) Intervals=10) )
  }

  *=== STEP 4: RAMP TO -1 V FOR POST-PGM CV ===
  NewCurrentPrefix="gate_init_postpgm_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE B: POST-PROGRAM CV SWEEP ===
  NewCurrentPrefix="cv_postpgm_"
  Quasistationary (
    DoZero
    InitialStep=1e-2 Increment=1.5
    MinStep=1e-5 MaxStep=0.04
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { ACCoupled (
        StartFrequency= 1e+06 EndFrequency= 1e+06 NumberOfPoints= 1 Decade
        Node(gate_contact drain_contact source_contact)
        Exclude(gate_contact drain_contact source_contact)
        ACCompute (Time= (Range=(0 1) Intervals=80))
      ) { Poisson Electron Hole }
  }

  *=== STEP 5: RAMP TO 0.2 V BEFORE THE ERASE PULSE ===
  NewCurrentPrefix="gate_to_read_pre_ers_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE C PRECONDITION: ERASE PULSE at -V_pgm (Goal-driven) ===
  NewCurrentPrefix="ers_rise_"
  Transient (
    InitialTime=2.2e-07 FinalTime=2.3e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -@V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.2e-07 2.3e-07) Intervals=10) )
  }
  NewCurrentPrefix="ers_hold_"
  Transient (
    InitialTime=2.3e-07 FinalTime=3.3e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3e-07 3.3e-07) Intervals=20) )
  }
  NewCurrentPrefix="ers_fall_"
  Transient (
    InitialTime=3.3e-07 FinalTime=3.4e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.3e-07 3.4e-07) Intervals=10) )
  }
  NewCurrentPrefix="ers_settle_"
  Transient (
    InitialTime=3.4e-07 FinalTime=4.4e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.4e-07 4.4e-07) Intervals=10) )
  }

  *=== STEP 6: RAMP TO -1 V FOR POST-ERASE CV ===
  NewCurrentPrefix="gate_init_posters_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE C: POST-ERASE CV SWEEP (closes the loop) ===
  NewCurrentPrefix="cv_posters_"
  Quasistationary (
    DoZero
    InitialStep=1e-2 Increment=1.5
    MinStep=1e-5 MaxStep=0.04
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { ACCoupled (
        StartFrequency= 1e+06 EndFrequency= 1e+06 NumberOfPoints= 1 Decade
        Node(gate_contact drain_contact source_contact)
        Exclude(gate_contact drain_contact source_contact)
        ACCompute (Time= (Range=(0 1) Intervals=80))
      ) { Poisson Electron Hole }
  }

}

*===================================================================
*== SWB SETUP:
*==   Parameter:  @V_pgm@
*==   Sweep:      1.5  2.0  2.5  3.5  6.0    V
*==
*== POST-PROCESSING:
*==   1. From cv_virgin_, cv_postpgm_, cv_posters_  → extract C_gg(V_G)
*==      and CV-midpoint V_t for each branch.  ΔV_t = V_t_ers − V_t_pgm
*==      = memory window (M3, target ≥ 0.5 V).
*==   2. Stack the three CV curves to demonstrate hysteresis closure.
*==   3. Step V_pgm 0.2 V over the sweep nodes and count distinguishable
*==      ΔV_t levels (M4, target ≥ 9).
*===================================================================
