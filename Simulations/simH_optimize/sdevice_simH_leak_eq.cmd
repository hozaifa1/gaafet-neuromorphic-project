*===================================================================
*== PHASE 1D — LEAK-EQUILIBRIUM CHARACTERIZATION
*==
*== Purpose: identify the gate voltage V_GS_neutral at which the
*==   post-fire leak equilibrium equals the virgin baseline current.
*==   That voltage will be used as the inter-burst rest phase in the
*==   cyclic LIF protocol.
*==
*== Par-file context (audited 2026-05-17):
*==   tau_E = (0, 1e-6, 0)   auxiliary-field relaxation 1 us
*==   tau_P = (0, 1e-5, 0)   polarization relaxation 10 us (leak)
*==   Effective channel-current relaxation tau_leak ~ 2.75 us
*==   (from H3 multi-cycle settle decay fits)
*==   No par change required for this experiment.
*==
*== Protocol per node:
*==   STEP 0  initialize at virgin (Poisson-only init)
*==   STEP 1  Quasistationary ramp V_DS to 0.05 V
*==   STEP 2  Quasistationary ramp V_G  to -0.5 V (sub-V_t baseline)
*==   STEP 3  100 ns baseline read at V_G = -0.5 V    (virgin ID)
*==   STEP 4  9-pulse fire burst at V_pgm = +2.0 V
*==              (1 ns rise / 100 ns hold / 1 ns fall / 100 ns read)
*==              per pulse, 202 ns x 9 = 1.818 us total
*==   STEP 5  Goal-ramp gate from -0.5 V to V_settle over 10 ns
*==   STEP 6  Hold gate at V_settle for 100 us with continuous
*==              CurrentPlot (~50 intervals)
*==
*== Time anchors (seconds):
*==   baseline_pre_       [-1.0e-7, 0.0]      virgin read
*==   p1..p9 (4 phases)   [0.0,    1.818e-6]  fire burst
*==   to_settle_          [1.818e-6, 1.828e-6] goal ramp
*==   hold_               [1.828e-6, 1.01828e-4] 100 us hold
*==
*== SWB sweep (set in SWB project):
*==   Parameter:  V_settle
*==   Sweep (L7): -0.5  -0.25  0.0  +0.25  +0.5  +0.75  +1.0    V
*==
*== Acceptance: at least one V_settle gives end-of-hold ID within
*==   +-20% of virgin baseline (2.13e-7 to 3.19e-7 uA/um).  That
*==   voltage is V_GS_neutral for the cyclic LIF protocol.
*==
*== Total wall time per node: ~102 us simulated (well below v4's
*==   64 us cycle-burst time x 5).
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

  *=== STEP 2: RAMP V_G TO -0.5 V (sub-V_t baseline) ===
  NewCurrentPrefix="gate_to_read_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 3: BASELINE READ (100 ns at V_G = -0.5 V) ===
  NewCurrentPrefix="baseline_pre_"
  Transient (
    InitialTime=-1.0e-07 FinalTime=0.0
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(-1.0e-07 0.0) Intervals=20) )
  }

  *====================================================================
  *== STEP 4: 9-PULSE FIRE BURST AT V_pgm = +2.0 V
  *====================================================================
  NewCurrentPrefix="p1_rise_"
  Transient (
    InitialTime=0.0000e+00 FinalTime=1.0000e-09
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p1_write_"
  Transient (
    InitialTime=1.0000e-09 FinalTime=1.0100e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0000e-09 1.0100e-07) Intervals=10) ) }
  NewCurrentPrefix="p1_fall_"
  Transient (
    InitialTime=1.0100e-07 FinalTime=1.0200e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p1_read_"
  Transient (
    InitialTime=1.0200e-07 FinalTime=2.0200e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0200e-07 2.0200e-07) Intervals=20) ) }
  NewCurrentPrefix="p2_rise_"
  Transient (
    InitialTime=2.0200e-07 FinalTime=2.0300e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p2_write_"
  Transient (
    InitialTime=2.0300e-07 FinalTime=3.0300e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0300e-07 3.0300e-07) Intervals=10) ) }
  NewCurrentPrefix="p2_fall_"
  Transient (
    InitialTime=3.0300e-07 FinalTime=3.0400e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p2_read_"
  Transient (
    InitialTime=3.0400e-07 FinalTime=4.0400e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0400e-07 4.0400e-07) Intervals=20) ) }
  NewCurrentPrefix="p3_rise_"
  Transient (
    InitialTime=4.0400e-07 FinalTime=4.0500e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p3_write_"
  Transient (
    InitialTime=4.0500e-07 FinalTime=5.0500e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0500e-07 5.0500e-07) Intervals=10) ) }
  NewCurrentPrefix="p3_fall_"
  Transient (
    InitialTime=5.0500e-07 FinalTime=5.0600e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p3_read_"
  Transient (
    InitialTime=5.0600e-07 FinalTime=6.0600e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0600e-07 6.0600e-07) Intervals=20) ) }
  NewCurrentPrefix="p4_rise_"
  Transient (
    InitialTime=6.0600e-07 FinalTime=6.0700e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p4_write_"
  Transient (
    InitialTime=6.0700e-07 FinalTime=7.0700e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0700e-07 7.0700e-07) Intervals=10) ) }
  NewCurrentPrefix="p4_fall_"
  Transient (
    InitialTime=7.0700e-07 FinalTime=7.0800e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p4_read_"
  Transient (
    InitialTime=7.0800e-07 FinalTime=8.0800e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0800e-07 8.0800e-07) Intervals=20) ) }
  NewCurrentPrefix="p5_rise_"
  Transient (
    InitialTime=8.0800e-07 FinalTime=8.0900e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p5_write_"
  Transient (
    InitialTime=8.0900e-07 FinalTime=9.0900e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0900e-07 9.0900e-07) Intervals=10) ) }
  NewCurrentPrefix="p5_fall_"
  Transient (
    InitialTime=9.0900e-07 FinalTime=9.1000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p5_read_"
  Transient (
    InitialTime=9.1000e-07 FinalTime=1.0100e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1000e-07 1.0100e-06) Intervals=20) ) }
  NewCurrentPrefix="p6_rise_"
  Transient (
    InitialTime=1.0100e-06 FinalTime=1.0110e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p6_write_"
  Transient (
    InitialTime=1.0110e-06 FinalTime=1.1110e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0110e-06 1.1110e-06) Intervals=10) ) }
  NewCurrentPrefix="p6_fall_"
  Transient (
    InitialTime=1.1110e-06 FinalTime=1.1120e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p6_read_"
  Transient (
    InitialTime=1.1120e-06 FinalTime=1.2120e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1120e-06 1.2120e-06) Intervals=20) ) }
  NewCurrentPrefix="p7_rise_"
  Transient (
    InitialTime=1.2120e-06 FinalTime=1.2130e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p7_write_"
  Transient (
    InitialTime=1.2130e-06 FinalTime=1.3130e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2130e-06 1.3130e-06) Intervals=10) ) }
  NewCurrentPrefix="p7_fall_"
  Transient (
    InitialTime=1.3130e-06 FinalTime=1.3140e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p7_read_"
  Transient (
    InitialTime=1.3140e-06 FinalTime=1.4140e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3140e-06 1.4140e-06) Intervals=20) ) }
  NewCurrentPrefix="p8_rise_"
  Transient (
    InitialTime=1.4140e-06 FinalTime=1.4150e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p8_write_"
  Transient (
    InitialTime=1.4150e-06 FinalTime=1.5150e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4150e-06 1.5150e-06) Intervals=10) ) }
  NewCurrentPrefix="p8_fall_"
  Transient (
    InitialTime=1.5150e-06 FinalTime=1.5160e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p8_read_"
  Transient (
    InitialTime=1.5160e-06 FinalTime=1.6160e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5160e-06 1.6160e-06) Intervals=20) ) }
  NewCurrentPrefix="p9_rise_"
  Transient (
    InitialTime=1.6160e-06 FinalTime=1.6170e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p9_write_"
  Transient (
    InitialTime=1.6170e-06 FinalTime=1.7170e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6170e-06 1.7170e-06) Intervals=10) ) }
  NewCurrentPrefix="p9_fall_"
  Transient (
    InitialTime=1.7170e-06 FinalTime=1.7180e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p9_read_"
  Transient (
    InitialTime=1.7180e-06 FinalTime=1.8180e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7180e-06 1.8180e-06) Intervals=20) ) }

  *====================================================================
  *== STEP 5: GOAL-RAMP GATE TO V_settle  (10 ns)
  *====================================================================
  NewCurrentPrefix="to_settle_"
  Transient (
    InitialTime=1.8180e-06 FinalTime=1.8280e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_settle@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *====================================================================
  *== STEP 6: HOLD AT V_settle FOR 100 us  (>= 10 * tau_P)
  *====================================================================
  NewCurrentPrefix="hold_"
  Transient (
    InitialTime=1.8280e-06 FinalTime=1.0183e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.8280e-06 1.0183e-04) Intervals=80) ) }

}

*===================================================================
*== SWB SETUP (set in SWB project, not in this file):
*==   Parameter:  V_settle
*==   Sweep (L7): -0.5  -0.25  0.0  +0.25  +0.5  +0.75  +1.0    V
*==
*== POST-PROCESSING (Simulations/analyze_phase1d_leakeq.py, to be written):
*==   1. Per node, extract:
*==      - ID_baseline_virgin = end of baseline_pre_
*==      - ID_p9              = end of p9_read_   (fire response)
*==      - ID_hold_decay      = ID(t) across hold_, sampled ~80 times
*==      - ID_end_of_hold     = end of hold_     (leak equilibrium)
*==   2. Fit ID_hold_decay to exponential -> tau_leak per V_settle
*==   3. Plot ID_end_of_hold vs V_settle, identify V_GS_neutral as the
*==      voltage where ID_end_of_hold returns to within +-20% of
*==      virgin baseline.
*==   4. If no V_settle achieves +-20%, extend the sweep range upward
*==      or add an active erase phase.
*===================================================================
