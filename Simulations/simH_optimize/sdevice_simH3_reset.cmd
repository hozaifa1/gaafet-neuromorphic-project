*===================================================================
*== PHASE 1D — SIM H3 v4: RESET PROTOCOL OPTIMIZATION (M2-fix)
*==
*== v1 INVALIDATED (2026-05-11): gate-drive bug.
*== v2 RAN, FAIL (2026-05-17): 10 µs reset over-flipped FE past virgin.
*== v3 RAN, M1 PASS / M2 FAIL (2026-05-17): drift killed by 1 µs reset
*==   (every node), restore PASS at V_reset in {-1.0, -1.5} V, but
*==   3 x 100 ns fires/cycle never escape the wake-up dip - within-
*==   cycle staircase is dip-dip-partial-recover, p3 < pre-cycle
*==   baseline, fire reverses direction from c2 onward.  See
*==   Phase1D_Device_Optimization_Plan.md -> H3 v3.
*==
*== v4 fix (2026-05-17): 3 fires/cycle -> 9 fires/cycle.
*==   H1 v3 already PROVED 9 x 100 ns +2 V fires from virgin give
*==   fire_ratio = 4.79x with monotonic staircase.  v4 wraps the H1 v3
*==   burst inside the v3 reset machinery for multi-cycle drift.
*==
*== Everything else UNCHANGED from v3:
*==   V_pgm = +2.0 V (100 ns hold, 1 ns rise/fall, 100 ns sub-V_t read)
*==   V_reset SWB sweep:  V_reset in {-1.0, -1.5, -2.0, -2.5} V (L4)
*==   t_reset  = 1 microsecond hold
*==   t_settle = 10 microseconds hold
*==   5 cycles (c1 wake-up + c2 transition + c3-5 M1/M2 fit)
*==   top-level Electrode + Transient + Goal everywhere
*==
*== Per-cycle wall time:
*==   9 fires (9 * 202 ns)                          = 1818 ns
*==   reset (10 ns rise / 1 us hold / 10 ns fall)   = 1020 ns
*==   settle (10 us at V_GS = -0.5 V)               = 10000 ns
*==   --------------------------------------------------------
*==   Per cycle = 12.838 us  |  Total 5 cycles = 64.190 us
*==
*== Cycle anchors:
*==   c1 [  0.000 us -> 12.838 us]
*==   c2 [ 12.838 us -> 25.676 us]
*==   c3 [ 25.676 us -> 38.514 us]
*==   c4 [ 38.514 us -> 51.352 us]
*==   c5 [ 51.352 us -> 64.190 us]
*==
*== Goal: all three pass on cycles 3-5:
*==   (a) restore_c5 within +-3x of virgin baseline
*==   (b) |drift_c3->c5| <= 1.0 percent/cycle  (M1)
*==   (c) fire_ratio_p9_cN >= 1.5 against pre-cycle ID_settle (M2)
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

  *=== STEP 2: RAMP V_G TO -0.5 V (sub-V_t read, matches H1 v3) ===
  NewCurrentPrefix="gate_to_read_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 3: BASELINE READ (pre-cycle 1, 100 ns at V_G = -0.5 V) ===
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
  *== CYCLE 1 (cycle base time = 0.0000e+00)
  *====================================================================
  NewCurrentPrefix="c1_p1_rise_"
  Transient (
    InitialTime=0.0000e+00 FinalTime=1.0000e-09
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p1_write_"
  Transient (
    InitialTime=1.0000e-09 FinalTime=1.0100e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0000e-09 1.0100e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p1_fall_"
  Transient (
    InitialTime=1.0100e-07 FinalTime=1.0200e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p1_read_"
  Transient (
    InitialTime=1.0200e-07 FinalTime=2.0200e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0200e-07 2.0200e-07) Intervals=20) ) }
  NewCurrentPrefix="c1_p2_rise_"
  Transient (
    InitialTime=2.0200e-07 FinalTime=2.0300e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p2_write_"
  Transient (
    InitialTime=2.0300e-07 FinalTime=3.0300e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0300e-07 3.0300e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p2_fall_"
  Transient (
    InitialTime=3.0300e-07 FinalTime=3.0400e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p2_read_"
  Transient (
    InitialTime=3.0400e-07 FinalTime=4.0400e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0400e-07 4.0400e-07) Intervals=20) ) }
  NewCurrentPrefix="c1_p3_rise_"
  Transient (
    InitialTime=4.0400e-07 FinalTime=4.0500e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p3_write_"
  Transient (
    InitialTime=4.0500e-07 FinalTime=5.0500e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0500e-07 5.0500e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p3_fall_"
  Transient (
    InitialTime=5.0500e-07 FinalTime=5.0600e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p3_read_"
  Transient (
    InitialTime=5.0600e-07 FinalTime=6.0600e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0600e-07 6.0600e-07) Intervals=20) ) }
  NewCurrentPrefix="c1_p4_rise_"
  Transient (
    InitialTime=6.0600e-07 FinalTime=6.0700e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p4_write_"
  Transient (
    InitialTime=6.0700e-07 FinalTime=7.0700e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0700e-07 7.0700e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p4_fall_"
  Transient (
    InitialTime=7.0700e-07 FinalTime=7.0800e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p4_read_"
  Transient (
    InitialTime=7.0800e-07 FinalTime=8.0800e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0800e-07 8.0800e-07) Intervals=20) ) }
  NewCurrentPrefix="c1_p5_rise_"
  Transient (
    InitialTime=8.0800e-07 FinalTime=8.0900e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p5_write_"
  Transient (
    InitialTime=8.0900e-07 FinalTime=9.0900e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0900e-07 9.0900e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p5_fall_"
  Transient (
    InitialTime=9.0900e-07 FinalTime=9.1000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p5_read_"
  Transient (
    InitialTime=9.1000e-07 FinalTime=1.0100e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1000e-07 1.0100e-06) Intervals=20) ) }
  NewCurrentPrefix="c1_p6_rise_"
  Transient (
    InitialTime=1.0100e-06 FinalTime=1.0110e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p6_write_"
  Transient (
    InitialTime=1.0110e-06 FinalTime=1.1110e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0110e-06 1.1110e-06) Intervals=10) ) }
  NewCurrentPrefix="c1_p6_fall_"
  Transient (
    InitialTime=1.1110e-06 FinalTime=1.1120e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p6_read_"
  Transient (
    InitialTime=1.1120e-06 FinalTime=1.2120e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1120e-06 1.2120e-06) Intervals=20) ) }
  NewCurrentPrefix="c1_p7_rise_"
  Transient (
    InitialTime=1.2120e-06 FinalTime=1.2130e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p7_write_"
  Transient (
    InitialTime=1.2130e-06 FinalTime=1.3130e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2130e-06 1.3130e-06) Intervals=10) ) }
  NewCurrentPrefix="c1_p7_fall_"
  Transient (
    InitialTime=1.3130e-06 FinalTime=1.3140e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p7_read_"
  Transient (
    InitialTime=1.3140e-06 FinalTime=1.4140e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3140e-06 1.4140e-06) Intervals=20) ) }
  NewCurrentPrefix="c1_p8_rise_"
  Transient (
    InitialTime=1.4140e-06 FinalTime=1.4150e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p8_write_"
  Transient (
    InitialTime=1.4150e-06 FinalTime=1.5150e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4150e-06 1.5150e-06) Intervals=10) ) }
  NewCurrentPrefix="c1_p8_fall_"
  Transient (
    InitialTime=1.5150e-06 FinalTime=1.5160e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p8_read_"
  Transient (
    InitialTime=1.5160e-06 FinalTime=1.6160e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5160e-06 1.6160e-06) Intervals=20) ) }
  NewCurrentPrefix="c1_p9_rise_"
  Transient (
    InitialTime=1.6160e-06 FinalTime=1.6170e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p9_write_"
  Transient (
    InitialTime=1.6170e-06 FinalTime=1.7170e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6170e-06 1.7170e-06) Intervals=10) ) }
  NewCurrentPrefix="c1_p9_fall_"
  Transient (
    InitialTime=1.7170e-06 FinalTime=1.7180e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p9_read_"
  Transient (
    InitialTime=1.7180e-06 FinalTime=1.8180e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7180e-06 1.8180e-06) Intervals=20) ) }
  *--- CYCLE 1 RESET (rise / 1 us hold / fall) ---
  NewCurrentPrefix="c1_reset_rise_"
  Transient (
    InitialTime=1.8180e-06 FinalTime=1.8280e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_reset_hold_"
  Transient (
    InitialTime=1.8280e-06 FinalTime=2.8280e-06
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.8280e-06 2.8280e-06) Intervals=40) ) }
  NewCurrentPrefix="c1_reset_fall_"
  Transient (
    InitialTime=2.8280e-06 FinalTime=2.8380e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_settle_"
  Transient (
    InitialTime=2.8380e-06 FinalTime=1.2838e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.8380e-06 1.2838e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 2 (cycle base time = 1.2838e-05)
  *====================================================================
  NewCurrentPrefix="c2_p1_rise_"
  Transient (
    InitialTime=1.2838e-05 FinalTime=1.2839e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_write_"
  Transient (
    InitialTime=1.2839e-05 FinalTime=1.2939e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2839e-05 1.2939e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p1_fall_"
  Transient (
    InitialTime=1.2939e-05 FinalTime=1.2940e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_read_"
  Transient (
    InitialTime=1.2940e-05 FinalTime=1.3040e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2940e-05 1.3040e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p2_rise_"
  Transient (
    InitialTime=1.3040e-05 FinalTime=1.3041e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_write_"
  Transient (
    InitialTime=1.3041e-05 FinalTime=1.3141e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3041e-05 1.3141e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p2_fall_"
  Transient (
    InitialTime=1.3141e-05 FinalTime=1.3142e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_read_"
  Transient (
    InitialTime=1.3142e-05 FinalTime=1.3242e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3142e-05 1.3242e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p3_rise_"
  Transient (
    InitialTime=1.3242e-05 FinalTime=1.3243e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_write_"
  Transient (
    InitialTime=1.3243e-05 FinalTime=1.3343e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3243e-05 1.3343e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p3_fall_"
  Transient (
    InitialTime=1.3343e-05 FinalTime=1.3344e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_read_"
  Transient (
    InitialTime=1.3344e-05 FinalTime=1.3444e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3344e-05 1.3444e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p4_rise_"
  Transient (
    InitialTime=1.3444e-05 FinalTime=1.3445e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p4_write_"
  Transient (
    InitialTime=1.3445e-05 FinalTime=1.3545e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3445e-05 1.3545e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p4_fall_"
  Transient (
    InitialTime=1.3545e-05 FinalTime=1.3546e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p4_read_"
  Transient (
    InitialTime=1.3546e-05 FinalTime=1.3646e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3546e-05 1.3646e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p5_rise_"
  Transient (
    InitialTime=1.3646e-05 FinalTime=1.3647e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p5_write_"
  Transient (
    InitialTime=1.3647e-05 FinalTime=1.3747e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3647e-05 1.3747e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p5_fall_"
  Transient (
    InitialTime=1.3747e-05 FinalTime=1.3748e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p5_read_"
  Transient (
    InitialTime=1.3748e-05 FinalTime=1.3848e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3748e-05 1.3848e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p6_rise_"
  Transient (
    InitialTime=1.3848e-05 FinalTime=1.3849e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p6_write_"
  Transient (
    InitialTime=1.3849e-05 FinalTime=1.3949e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3849e-05 1.3949e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p6_fall_"
  Transient (
    InitialTime=1.3949e-05 FinalTime=1.3950e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p6_read_"
  Transient (
    InitialTime=1.3950e-05 FinalTime=1.4050e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3950e-05 1.4050e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p7_rise_"
  Transient (
    InitialTime=1.4050e-05 FinalTime=1.4051e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p7_write_"
  Transient (
    InitialTime=1.4051e-05 FinalTime=1.4151e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4051e-05 1.4151e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p7_fall_"
  Transient (
    InitialTime=1.4151e-05 FinalTime=1.4152e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p7_read_"
  Transient (
    InitialTime=1.4152e-05 FinalTime=1.4252e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4152e-05 1.4252e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p8_rise_"
  Transient (
    InitialTime=1.4252e-05 FinalTime=1.4253e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p8_write_"
  Transient (
    InitialTime=1.4253e-05 FinalTime=1.4353e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4253e-05 1.4353e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p8_fall_"
  Transient (
    InitialTime=1.4353e-05 FinalTime=1.4354e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p8_read_"
  Transient (
    InitialTime=1.4354e-05 FinalTime=1.4454e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4354e-05 1.4454e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p9_rise_"
  Transient (
    InitialTime=1.4454e-05 FinalTime=1.4455e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p9_write_"
  Transient (
    InitialTime=1.4455e-05 FinalTime=1.4555e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4455e-05 1.4555e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p9_fall_"
  Transient (
    InitialTime=1.4555e-05 FinalTime=1.4556e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p9_read_"
  Transient (
    InitialTime=1.4556e-05 FinalTime=1.4656e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4556e-05 1.4656e-05) Intervals=20) ) }
  *--- CYCLE 2 RESET (rise / 1 us hold / fall) ---
  NewCurrentPrefix="c2_reset_rise_"
  Transient (
    InitialTime=1.4656e-05 FinalTime=1.4666e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_reset_hold_"
  Transient (
    InitialTime=1.4666e-05 FinalTime=1.5666e-05
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4666e-05 1.5666e-05) Intervals=40) ) }
  NewCurrentPrefix="c2_reset_fall_"
  Transient (
    InitialTime=1.5666e-05 FinalTime=1.5676e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_settle_"
  Transient (
    InitialTime=1.5676e-05 FinalTime=2.5676e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5676e-05 2.5676e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 3 (cycle base time = 2.5676e-05)
  *====================================================================
  NewCurrentPrefix="c3_p1_rise_"
  Transient (
    InitialTime=2.5676e-05 FinalTime=2.5677e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_write_"
  Transient (
    InitialTime=2.5677e-05 FinalTime=2.5777e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.5677e-05 2.5777e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p1_fall_"
  Transient (
    InitialTime=2.5777e-05 FinalTime=2.5778e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_read_"
  Transient (
    InitialTime=2.5778e-05 FinalTime=2.5878e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.5778e-05 2.5878e-05) Intervals=20) ) }
  NewCurrentPrefix="c3_p2_rise_"
  Transient (
    InitialTime=2.5878e-05 FinalTime=2.5879e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_write_"
  Transient (
    InitialTime=2.5879e-05 FinalTime=2.5979e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.5879e-05 2.5979e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p2_fall_"
  Transient (
    InitialTime=2.5979e-05 FinalTime=2.5980e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_read_"
  Transient (
    InitialTime=2.5980e-05 FinalTime=2.6080e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.5980e-05 2.6080e-05) Intervals=20) ) }
  NewCurrentPrefix="c3_p3_rise_"
  Transient (
    InitialTime=2.6080e-05 FinalTime=2.6081e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_write_"
  Transient (
    InitialTime=2.6081e-05 FinalTime=2.6181e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6081e-05 2.6181e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p3_fall_"
  Transient (
    InitialTime=2.6181e-05 FinalTime=2.6182e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_read_"
  Transient (
    InitialTime=2.6182e-05 FinalTime=2.6282e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6182e-05 2.6282e-05) Intervals=20) ) }
  NewCurrentPrefix="c3_p4_rise_"
  Transient (
    InitialTime=2.6282e-05 FinalTime=2.6283e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p4_write_"
  Transient (
    InitialTime=2.6283e-05 FinalTime=2.6383e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6283e-05 2.6383e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p4_fall_"
  Transient (
    InitialTime=2.6383e-05 FinalTime=2.6384e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p4_read_"
  Transient (
    InitialTime=2.6384e-05 FinalTime=2.6484e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6384e-05 2.6484e-05) Intervals=20) ) }
  NewCurrentPrefix="c3_p5_rise_"
  Transient (
    InitialTime=2.6484e-05 FinalTime=2.6485e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p5_write_"
  Transient (
    InitialTime=2.6485e-05 FinalTime=2.6585e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6485e-05 2.6585e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p5_fall_"
  Transient (
    InitialTime=2.6585e-05 FinalTime=2.6586e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p5_read_"
  Transient (
    InitialTime=2.6586e-05 FinalTime=2.6686e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6586e-05 2.6686e-05) Intervals=20) ) }
  NewCurrentPrefix="c3_p6_rise_"
  Transient (
    InitialTime=2.6686e-05 FinalTime=2.6687e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p6_write_"
  Transient (
    InitialTime=2.6687e-05 FinalTime=2.6787e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6687e-05 2.6787e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p6_fall_"
  Transient (
    InitialTime=2.6787e-05 FinalTime=2.6788e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p6_read_"
  Transient (
    InitialTime=2.6788e-05 FinalTime=2.6888e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6788e-05 2.6888e-05) Intervals=20) ) }
  NewCurrentPrefix="c3_p7_rise_"
  Transient (
    InitialTime=2.6888e-05 FinalTime=2.6889e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p7_write_"
  Transient (
    InitialTime=2.6889e-05 FinalTime=2.6989e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6889e-05 2.6989e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p7_fall_"
  Transient (
    InitialTime=2.6989e-05 FinalTime=2.6990e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p7_read_"
  Transient (
    InitialTime=2.6990e-05 FinalTime=2.7090e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6990e-05 2.7090e-05) Intervals=20) ) }
  NewCurrentPrefix="c3_p8_rise_"
  Transient (
    InitialTime=2.7090e-05 FinalTime=2.7091e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p8_write_"
  Transient (
    InitialTime=2.7091e-05 FinalTime=2.7191e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.7091e-05 2.7191e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p8_fall_"
  Transient (
    InitialTime=2.7191e-05 FinalTime=2.7192e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p8_read_"
  Transient (
    InitialTime=2.7192e-05 FinalTime=2.7292e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.7192e-05 2.7292e-05) Intervals=20) ) }
  NewCurrentPrefix="c3_p9_rise_"
  Transient (
    InitialTime=2.7292e-05 FinalTime=2.7293e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p9_write_"
  Transient (
    InitialTime=2.7293e-05 FinalTime=2.7393e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.7293e-05 2.7393e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p9_fall_"
  Transient (
    InitialTime=2.7393e-05 FinalTime=2.7394e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p9_read_"
  Transient (
    InitialTime=2.7394e-05 FinalTime=2.7494e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.7394e-05 2.7494e-05) Intervals=20) ) }
  *--- CYCLE 3 RESET (rise / 1 us hold / fall) ---
  NewCurrentPrefix="c3_reset_rise_"
  Transient (
    InitialTime=2.7494e-05 FinalTime=2.7504e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_reset_hold_"
  Transient (
    InitialTime=2.7504e-05 FinalTime=2.8504e-05
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.7504e-05 2.8504e-05) Intervals=40) ) }
  NewCurrentPrefix="c3_reset_fall_"
  Transient (
    InitialTime=2.8504e-05 FinalTime=2.8514e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_settle_"
  Transient (
    InitialTime=2.8514e-05 FinalTime=3.8514e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.8514e-05 3.8514e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 4 (cycle base time = 3.8514e-05)
  *====================================================================
  NewCurrentPrefix="c4_p1_rise_"
  Transient (
    InitialTime=3.8514e-05 FinalTime=3.8515e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p1_write_"
  Transient (
    InitialTime=3.8515e-05 FinalTime=3.8615e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.8515e-05 3.8615e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p1_fall_"
  Transient (
    InitialTime=3.8615e-05 FinalTime=3.8616e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p1_read_"
  Transient (
    InitialTime=3.8616e-05 FinalTime=3.8716e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.8616e-05 3.8716e-05) Intervals=20) ) }
  NewCurrentPrefix="c4_p2_rise_"
  Transient (
    InitialTime=3.8716e-05 FinalTime=3.8717e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_write_"
  Transient (
    InitialTime=3.8717e-05 FinalTime=3.8817e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.8717e-05 3.8817e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p2_fall_"
  Transient (
    InitialTime=3.8817e-05 FinalTime=3.8818e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_read_"
  Transient (
    InitialTime=3.8818e-05 FinalTime=3.8918e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.8818e-05 3.8918e-05) Intervals=20) ) }
  NewCurrentPrefix="c4_p3_rise_"
  Transient (
    InitialTime=3.8918e-05 FinalTime=3.8919e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_write_"
  Transient (
    InitialTime=3.8919e-05 FinalTime=3.9019e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.8919e-05 3.9019e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p3_fall_"
  Transient (
    InitialTime=3.9019e-05 FinalTime=3.9020e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_read_"
  Transient (
    InitialTime=3.9020e-05 FinalTime=3.9120e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9020e-05 3.9120e-05) Intervals=20) ) }
  NewCurrentPrefix="c4_p4_rise_"
  Transient (
    InitialTime=3.9120e-05 FinalTime=3.9121e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p4_write_"
  Transient (
    InitialTime=3.9121e-05 FinalTime=3.9221e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9121e-05 3.9221e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p4_fall_"
  Transient (
    InitialTime=3.9221e-05 FinalTime=3.9222e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p4_read_"
  Transient (
    InitialTime=3.9222e-05 FinalTime=3.9322e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9222e-05 3.9322e-05) Intervals=20) ) }
  NewCurrentPrefix="c4_p5_rise_"
  Transient (
    InitialTime=3.9322e-05 FinalTime=3.9323e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p5_write_"
  Transient (
    InitialTime=3.9323e-05 FinalTime=3.9423e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9323e-05 3.9423e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p5_fall_"
  Transient (
    InitialTime=3.9423e-05 FinalTime=3.9424e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p5_read_"
  Transient (
    InitialTime=3.9424e-05 FinalTime=3.9524e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9424e-05 3.9524e-05) Intervals=20) ) }
  NewCurrentPrefix="c4_p6_rise_"
  Transient (
    InitialTime=3.9524e-05 FinalTime=3.9525e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p6_write_"
  Transient (
    InitialTime=3.9525e-05 FinalTime=3.9625e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9525e-05 3.9625e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p6_fall_"
  Transient (
    InitialTime=3.9625e-05 FinalTime=3.9626e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p6_read_"
  Transient (
    InitialTime=3.9626e-05 FinalTime=3.9726e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9626e-05 3.9726e-05) Intervals=20) ) }
  NewCurrentPrefix="c4_p7_rise_"
  Transient (
    InitialTime=3.9726e-05 FinalTime=3.9727e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p7_write_"
  Transient (
    InitialTime=3.9727e-05 FinalTime=3.9827e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9727e-05 3.9827e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p7_fall_"
  Transient (
    InitialTime=3.9827e-05 FinalTime=3.9828e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p7_read_"
  Transient (
    InitialTime=3.9828e-05 FinalTime=3.9928e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9828e-05 3.9928e-05) Intervals=20) ) }
  NewCurrentPrefix="c4_p8_rise_"
  Transient (
    InitialTime=3.9928e-05 FinalTime=3.9929e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p8_write_"
  Transient (
    InitialTime=3.9929e-05 FinalTime=4.0029e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9929e-05 4.0029e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p8_fall_"
  Transient (
    InitialTime=4.0029e-05 FinalTime=4.0030e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p8_read_"
  Transient (
    InitialTime=4.0030e-05 FinalTime=4.0130e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0030e-05 4.0130e-05) Intervals=20) ) }
  NewCurrentPrefix="c4_p9_rise_"
  Transient (
    InitialTime=4.0130e-05 FinalTime=4.0131e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p9_write_"
  Transient (
    InitialTime=4.0131e-05 FinalTime=4.0231e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0131e-05 4.0231e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p9_fall_"
  Transient (
    InitialTime=4.0231e-05 FinalTime=4.0232e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p9_read_"
  Transient (
    InitialTime=4.0232e-05 FinalTime=4.0332e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0232e-05 4.0332e-05) Intervals=20) ) }
  *--- CYCLE 4 RESET (rise / 1 us hold / fall) ---
  NewCurrentPrefix="c4_reset_rise_"
  Transient (
    InitialTime=4.0332e-05 FinalTime=4.0342e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_reset_hold_"
  Transient (
    InitialTime=4.0342e-05 FinalTime=4.1342e-05
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0342e-05 4.1342e-05) Intervals=40) ) }
  NewCurrentPrefix="c4_reset_fall_"
  Transient (
    InitialTime=4.1342e-05 FinalTime=4.1352e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_settle_"
  Transient (
    InitialTime=4.1352e-05 FinalTime=5.1352e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1352e-05 5.1352e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 5 (cycle base time = 5.1352e-05)
  *====================================================================
  NewCurrentPrefix="c5_p1_rise_"
  Transient (
    InitialTime=5.1352e-05 FinalTime=5.1353e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p1_write_"
  Transient (
    InitialTime=5.1353e-05 FinalTime=5.1453e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.1353e-05 5.1453e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p1_fall_"
  Transient (
    InitialTime=5.1453e-05 FinalTime=5.1454e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p1_read_"
  Transient (
    InitialTime=5.1454e-05 FinalTime=5.1554e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.1454e-05 5.1554e-05) Intervals=20) ) }
  NewCurrentPrefix="c5_p2_rise_"
  Transient (
    InitialTime=5.1554e-05 FinalTime=5.1555e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_write_"
  Transient (
    InitialTime=5.1555e-05 FinalTime=5.1655e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.1555e-05 5.1655e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p2_fall_"
  Transient (
    InitialTime=5.1655e-05 FinalTime=5.1656e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_read_"
  Transient (
    InitialTime=5.1656e-05 FinalTime=5.1756e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.1656e-05 5.1756e-05) Intervals=20) ) }
  NewCurrentPrefix="c5_p3_rise_"
  Transient (
    InitialTime=5.1756e-05 FinalTime=5.1757e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_write_"
  Transient (
    InitialTime=5.1757e-05 FinalTime=5.1857e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.1757e-05 5.1857e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p3_fall_"
  Transient (
    InitialTime=5.1857e-05 FinalTime=5.1858e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_read_"
  Transient (
    InitialTime=5.1858e-05 FinalTime=5.1958e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.1858e-05 5.1958e-05) Intervals=20) ) }
  NewCurrentPrefix="c5_p4_rise_"
  Transient (
    InitialTime=5.1958e-05 FinalTime=5.1959e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p4_write_"
  Transient (
    InitialTime=5.1959e-05 FinalTime=5.2059e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.1959e-05 5.2059e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p4_fall_"
  Transient (
    InitialTime=5.2059e-05 FinalTime=5.2060e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p4_read_"
  Transient (
    InitialTime=5.2060e-05 FinalTime=5.2160e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2060e-05 5.2160e-05) Intervals=20) ) }
  NewCurrentPrefix="c5_p5_rise_"
  Transient (
    InitialTime=5.2160e-05 FinalTime=5.2161e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p5_write_"
  Transient (
    InitialTime=5.2161e-05 FinalTime=5.2261e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2161e-05 5.2261e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p5_fall_"
  Transient (
    InitialTime=5.2261e-05 FinalTime=5.2262e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p5_read_"
  Transient (
    InitialTime=5.2262e-05 FinalTime=5.2362e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2262e-05 5.2362e-05) Intervals=20) ) }
  NewCurrentPrefix="c5_p6_rise_"
  Transient (
    InitialTime=5.2362e-05 FinalTime=5.2363e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p6_write_"
  Transient (
    InitialTime=5.2363e-05 FinalTime=5.2463e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2363e-05 5.2463e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p6_fall_"
  Transient (
    InitialTime=5.2463e-05 FinalTime=5.2464e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p6_read_"
  Transient (
    InitialTime=5.2464e-05 FinalTime=5.2564e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2464e-05 5.2564e-05) Intervals=20) ) }
  NewCurrentPrefix="c5_p7_rise_"
  Transient (
    InitialTime=5.2564e-05 FinalTime=5.2565e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p7_write_"
  Transient (
    InitialTime=5.2565e-05 FinalTime=5.2665e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2565e-05 5.2665e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p7_fall_"
  Transient (
    InitialTime=5.2665e-05 FinalTime=5.2666e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p7_read_"
  Transient (
    InitialTime=5.2666e-05 FinalTime=5.2766e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2666e-05 5.2766e-05) Intervals=20) ) }
  NewCurrentPrefix="c5_p8_rise_"
  Transient (
    InitialTime=5.2766e-05 FinalTime=5.2767e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p8_write_"
  Transient (
    InitialTime=5.2767e-05 FinalTime=5.2867e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2767e-05 5.2867e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p8_fall_"
  Transient (
    InitialTime=5.2867e-05 FinalTime=5.2868e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p8_read_"
  Transient (
    InitialTime=5.2868e-05 FinalTime=5.2968e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2868e-05 5.2968e-05) Intervals=20) ) }
  NewCurrentPrefix="c5_p9_rise_"
  Transient (
    InitialTime=5.2968e-05 FinalTime=5.2969e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p9_write_"
  Transient (
    InitialTime=5.2969e-05 FinalTime=5.3069e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.2969e-05 5.3069e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p9_fall_"
  Transient (
    InitialTime=5.3069e-05 FinalTime=5.3070e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p9_read_"
  Transient (
    InitialTime=5.3070e-05 FinalTime=5.3170e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.3070e-05 5.3170e-05) Intervals=20) ) }
  *--- CYCLE 5 RESET (rise / 1 us hold / fall) ---
  NewCurrentPrefix="c5_reset_rise_"
  Transient (
    InitialTime=5.3170e-05 FinalTime=5.3180e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_reset_hold_"
  Transient (
    InitialTime=5.3180e-05 FinalTime=5.4180e-05
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.3180e-05 5.4180e-05) Intervals=40) ) }
  NewCurrentPrefix="c5_reset_fall_"
  Transient (
    InitialTime=5.4180e-05 FinalTime=5.4190e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_settle_"
  Transient (
    InitialTime=5.4190e-05 FinalTime=6.4190e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.4190e-05 6.4190e-05) Intervals=40) ) }

}

*===================================================================
*== SWB SETUP (set in SWB project, not in this file):
*==   Parameter:  V_reset
*==   Sweep (L4): -1.0  -1.5  -2.0  -2.5    V
*==
*== POST-PROCESSING (Simulations/analyze_phase1d_h3.py, v4 update):
*==   1. Per node, extract ID at end of c{N}_settle_ for N in 1..5
*==      (= pre-cycle baseline for cycle N+1).
*==   2. Per cycle, extract ID at end of c{N}_p{k}_read_ for k in 1..9.
*==   3. Steady-state drift (M1):
*==        drift_per_cycle = (ID_settle_c5 - ID_settle_c3) / ID_settle_c3 / 2
*==      PASS: |drift| <= 1.0 percent/cycle.
*==   4. In-cycle fire ratio (M2):
*==        fire_ratio_cN = ID_cN_p9 / pre_cN_baseline
*==      pre_c1_baseline = ID_baseline_virgin; pre_cN = ID_settle_c(N-1).
*==      PASS: fire_ratio_cN >= 1.5 for N in 3..5.
*==   5. Monotonicity check: flag any cN (N in 3..5) where the
*==      9-pulse staircase is not monotonic (p_k > p_{k+1}).
*==   6. Restore: ID_settle_c5 / ID_baseline_virgin in [1/3, 3].
*==   Pick V_reset that passes (3)+(4)+(5)+(6).  This is V_reset_opt for H4.
*===================================================================
