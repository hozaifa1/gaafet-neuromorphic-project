*===================================================================
*== PHASE 1D - CYCLIC LIF: 9-pulse fire + pulsed erase + leak-to-read
*==
*== Per-cycle phases:
*==   (a) 9 program pulses at V_pgm=+2.0V (100ns hold, 100ns sub-Vt read each)
*==   (b) 10ns ramp gate -> V_erase
*==   (c) 10us hold at V_erase  (super-coercive negative pulse)
*==   (d) 10ns ramp gate -> V_GS=-0.5V
*==   (e) 70us relax at V_GS=-0.5V  (>= 5 * tau_relax = 5 * 14us)
*==
*== Per-cycle wall time:
*==   9 fires (9 * 202 ns)                   = 1818 ns
*==   erase (10 ns rise / 10 us hold / fall) = 10020 ns
*==   relax (70 us at V_GS = -0.5 V)         = 70000 ns
*==   ---------------------------------------------------
*==   Per cycle = 81.838 us  |  Total 5 cycles = 409.190 us
*==
*== Drive: top-level Electrode + Transient+Goal everywhere.  Pulse and
*== read structure is byte-identical to H1 v3 / H3 v4 cycle-1 fire so
*== cycle-1 numerically reproduces the 4.79x single-shot fire from virgin.
*==
*== Acceptance:
*==   (M1) |drift_c3->c5| <= 1.0 percent/cycle on ID_p9 across cycles
*==   (M2) fire_ratio_cN = ID_p9_cN / ID_pre_cN >= 1.5 for every cycle N
*==   (restore) ID at end of every relax phase within +-25 percent of virgin
*===================================================================

File {
    Grid       = "n1_msh.tdr"
    Parameter  = "sdevice_gaafet_lif.par"
    Plot       = "cyclic_lif_outputs/cyclic_vm6_des.tdr"
    Current    = "cyclic_lif_outputs/cyclic_vm6_des.plt"
    Output     = "cyclic_lif_outputs/cyclic_vm6_des.log"
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
  *== CYCLE 1 (cycle base time = 0.000000e+00)
  *====================================================================
  NewCurrentPrefix="c1_p1_rise_"
  Transient (
    InitialTime=0.000000e+00 FinalTime=1.000000e-09
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p1_write_"
  Transient (
    InitialTime=1.000000e-09 FinalTime=1.010000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.000000e-09 1.010000e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p1_fall_"
  Transient (
    InitialTime=1.010000e-07 FinalTime=1.020000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p1_read_"
  Transient (
    InitialTime=1.020000e-07 FinalTime=2.020000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.020000e-07 2.020000e-07) Intervals=20) ) }
  NewCurrentPrefix="c1_p2_rise_"
  Transient (
    InitialTime=2.020000e-07 FinalTime=2.030000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p2_write_"
  Transient (
    InitialTime=2.030000e-07 FinalTime=3.030000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.030000e-07 3.030000e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p2_fall_"
  Transient (
    InitialTime=3.030000e-07 FinalTime=3.040000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p2_read_"
  Transient (
    InitialTime=3.040000e-07 FinalTime=4.040000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.040000e-07 4.040000e-07) Intervals=20) ) }
  NewCurrentPrefix="c1_p3_rise_"
  Transient (
    InitialTime=4.040000e-07 FinalTime=4.050000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p3_write_"
  Transient (
    InitialTime=4.050000e-07 FinalTime=5.050000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.050000e-07 5.050000e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p3_fall_"
  Transient (
    InitialTime=5.050000e-07 FinalTime=5.060000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p3_read_"
  Transient (
    InitialTime=5.060000e-07 FinalTime=6.060000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.060000e-07 6.060000e-07) Intervals=20) ) }
  NewCurrentPrefix="c1_p4_rise_"
  Transient (
    InitialTime=6.060000e-07 FinalTime=6.070000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p4_write_"
  Transient (
    InitialTime=6.070000e-07 FinalTime=7.070000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.070000e-07 7.070000e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p4_fall_"
  Transient (
    InitialTime=7.070000e-07 FinalTime=7.080000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p4_read_"
  Transient (
    InitialTime=7.080000e-07 FinalTime=8.080000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.080000e-07 8.080000e-07) Intervals=20) ) }
  NewCurrentPrefix="c1_p5_rise_"
  Transient (
    InitialTime=8.080000e-07 FinalTime=8.090000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p5_write_"
  Transient (
    InitialTime=8.090000e-07 FinalTime=9.090000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.090000e-07 9.090000e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p5_fall_"
  Transient (
    InitialTime=9.090000e-07 FinalTime=9.100000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p5_read_"
  Transient (
    InitialTime=9.100000e-07 FinalTime=1.010000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.100000e-07 1.010000e-06) Intervals=20) ) }
  NewCurrentPrefix="c1_p6_rise_"
  Transient (
    InitialTime=1.010000e-06 FinalTime=1.011000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p6_write_"
  Transient (
    InitialTime=1.011000e-06 FinalTime=1.111000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.011000e-06 1.111000e-06) Intervals=10) ) }
  NewCurrentPrefix="c1_p6_fall_"
  Transient (
    InitialTime=1.111000e-06 FinalTime=1.112000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p6_read_"
  Transient (
    InitialTime=1.112000e-06 FinalTime=1.212000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.112000e-06 1.212000e-06) Intervals=20) ) }
  NewCurrentPrefix="c1_p7_rise_"
  Transient (
    InitialTime=1.212000e-06 FinalTime=1.213000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p7_write_"
  Transient (
    InitialTime=1.213000e-06 FinalTime=1.313000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.213000e-06 1.313000e-06) Intervals=10) ) }
  NewCurrentPrefix="c1_p7_fall_"
  Transient (
    InitialTime=1.313000e-06 FinalTime=1.314000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p7_read_"
  Transient (
    InitialTime=1.314000e-06 FinalTime=1.414000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.314000e-06 1.414000e-06) Intervals=20) ) }
  NewCurrentPrefix="c1_p8_rise_"
  Transient (
    InitialTime=1.414000e-06 FinalTime=1.415000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p8_write_"
  Transient (
    InitialTime=1.415000e-06 FinalTime=1.515000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.415000e-06 1.515000e-06) Intervals=10) ) }
  NewCurrentPrefix="c1_p8_fall_"
  Transient (
    InitialTime=1.515000e-06 FinalTime=1.516000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p8_read_"
  Transient (
    InitialTime=1.516000e-06 FinalTime=1.616000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.516000e-06 1.616000e-06) Intervals=20) ) }
  NewCurrentPrefix="c1_p9_rise_"
  Transient (
    InitialTime=1.616000e-06 FinalTime=1.617000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p9_write_"
  Transient (
    InitialTime=1.617000e-06 FinalTime=1.717000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.617000e-06 1.717000e-06) Intervals=10) ) }
  NewCurrentPrefix="c1_p9_fall_"
  Transient (
    InitialTime=1.717000e-06 FinalTime=1.718000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p9_read_"
  Transient (
    InitialTime=1.718000e-06 FinalTime=1.818000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.718000e-06 1.818000e-06) Intervals=20) ) }
  *--- CYCLE 1 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c1_erase_rise_"
  Transient (
    InitialTime=1.818000e-06 FinalTime=1.828000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_erase_hold_"
  Transient (
    InitialTime=1.828000e-06 FinalTime=1.182800e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.828000e-06 1.182800e-05) Intervals=40) ) }
  NewCurrentPrefix="c1_erase_fall_"
  Transient (
    InitialTime=1.182800e-05 FinalTime=1.183800e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 1 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c1_relax_"
  Transient (
    InitialTime=1.183800e-05 FinalTime=8.183800e-05
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.183800e-05 8.183800e-05) Intervals=70) ) }

  *====================================================================
  *== CYCLE 2 (cycle base time = 8.183800e-05)
  *====================================================================
  NewCurrentPrefix="c2_p1_rise_"
  Transient (
    InitialTime=8.183800e-05 FinalTime=8.183900e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_write_"
  Transient (
    InitialTime=8.183900e-05 FinalTime=8.193900e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.183900e-05 8.193900e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p1_fall_"
  Transient (
    InitialTime=8.193900e-05 FinalTime=8.194000e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_read_"
  Transient (
    InitialTime=8.194000e-05 FinalTime=8.204000e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.194000e-05 8.204000e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p2_rise_"
  Transient (
    InitialTime=8.204000e-05 FinalTime=8.204100e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_write_"
  Transient (
    InitialTime=8.204100e-05 FinalTime=8.214100e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.204100e-05 8.214100e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p2_fall_"
  Transient (
    InitialTime=8.214100e-05 FinalTime=8.214200e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_read_"
  Transient (
    InitialTime=8.214200e-05 FinalTime=8.224200e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.214200e-05 8.224200e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p3_rise_"
  Transient (
    InitialTime=8.224200e-05 FinalTime=8.224300e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_write_"
  Transient (
    InitialTime=8.224300e-05 FinalTime=8.234300e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.224300e-05 8.234300e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p3_fall_"
  Transient (
    InitialTime=8.234300e-05 FinalTime=8.234400e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_read_"
  Transient (
    InitialTime=8.234400e-05 FinalTime=8.244400e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.234400e-05 8.244400e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p4_rise_"
  Transient (
    InitialTime=8.244400e-05 FinalTime=8.244500e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p4_write_"
  Transient (
    InitialTime=8.244500e-05 FinalTime=8.254500e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.244500e-05 8.254500e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p4_fall_"
  Transient (
    InitialTime=8.254500e-05 FinalTime=8.254600e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p4_read_"
  Transient (
    InitialTime=8.254600e-05 FinalTime=8.264600e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.254600e-05 8.264600e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p5_rise_"
  Transient (
    InitialTime=8.264600e-05 FinalTime=8.264700e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p5_write_"
  Transient (
    InitialTime=8.264700e-05 FinalTime=8.274700e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.264700e-05 8.274700e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p5_fall_"
  Transient (
    InitialTime=8.274700e-05 FinalTime=8.274800e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p5_read_"
  Transient (
    InitialTime=8.274800e-05 FinalTime=8.284800e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.274800e-05 8.284800e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p6_rise_"
  Transient (
    InitialTime=8.284800e-05 FinalTime=8.284900e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p6_write_"
  Transient (
    InitialTime=8.284900e-05 FinalTime=8.294900e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.284900e-05 8.294900e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p6_fall_"
  Transient (
    InitialTime=8.294900e-05 FinalTime=8.295000e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p6_read_"
  Transient (
    InitialTime=8.295000e-05 FinalTime=8.305000e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.295000e-05 8.305000e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p7_rise_"
  Transient (
    InitialTime=8.305000e-05 FinalTime=8.305100e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p7_write_"
  Transient (
    InitialTime=8.305100e-05 FinalTime=8.315100e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.305100e-05 8.315100e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p7_fall_"
  Transient (
    InitialTime=8.315100e-05 FinalTime=8.315200e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p7_read_"
  Transient (
    InitialTime=8.315200e-05 FinalTime=8.325200e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.315200e-05 8.325200e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p8_rise_"
  Transient (
    InitialTime=8.325200e-05 FinalTime=8.325300e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p8_write_"
  Transient (
    InitialTime=8.325300e-05 FinalTime=8.335300e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.325300e-05 8.335300e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p8_fall_"
  Transient (
    InitialTime=8.335300e-05 FinalTime=8.335400e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p8_read_"
  Transient (
    InitialTime=8.335400e-05 FinalTime=8.345400e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.335400e-05 8.345400e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p9_rise_"
  Transient (
    InitialTime=8.345400e-05 FinalTime=8.345500e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p9_write_"
  Transient (
    InitialTime=8.345500e-05 FinalTime=8.355500e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.345500e-05 8.355500e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p9_fall_"
  Transient (
    InitialTime=8.355500e-05 FinalTime=8.355600e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p9_read_"
  Transient (
    InitialTime=8.355600e-05 FinalTime=8.365600e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.355600e-05 8.365600e-05) Intervals=20) ) }
  *--- CYCLE 2 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c2_erase_rise_"
  Transient (
    InitialTime=8.365600e-05 FinalTime=8.366600e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_erase_hold_"
  Transient (
    InitialTime=8.366600e-05 FinalTime=9.366600e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.366600e-05 9.366600e-05) Intervals=40) ) }
  NewCurrentPrefix="c2_erase_fall_"
  Transient (
    InitialTime=9.366600e-05 FinalTime=9.367600e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 2 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c2_relax_"
  Transient (
    InitialTime=9.367600e-05 FinalTime=1.636760e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.367600e-05 1.636760e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 3 (cycle base time = 1.636760e-04)
  *====================================================================
  NewCurrentPrefix="c3_p1_rise_"
  Transient (
    InitialTime=1.636760e-04 FinalTime=1.636770e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_write_"
  Transient (
    InitialTime=1.636770e-04 FinalTime=1.637770e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.636770e-04 1.637770e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p1_fall_"
  Transient (
    InitialTime=1.637770e-04 FinalTime=1.637780e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_read_"
  Transient (
    InitialTime=1.637780e-04 FinalTime=1.638780e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.637780e-04 1.638780e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p2_rise_"
  Transient (
    InitialTime=1.638780e-04 FinalTime=1.638790e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_write_"
  Transient (
    InitialTime=1.638790e-04 FinalTime=1.639790e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.638790e-04 1.639790e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p2_fall_"
  Transient (
    InitialTime=1.639790e-04 FinalTime=1.639800e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_read_"
  Transient (
    InitialTime=1.639800e-04 FinalTime=1.640800e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.639800e-04 1.640800e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p3_rise_"
  Transient (
    InitialTime=1.640800e-04 FinalTime=1.640810e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_write_"
  Transient (
    InitialTime=1.640810e-04 FinalTime=1.641810e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.640810e-04 1.641810e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p3_fall_"
  Transient (
    InitialTime=1.641810e-04 FinalTime=1.641820e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_read_"
  Transient (
    InitialTime=1.641820e-04 FinalTime=1.642820e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.641820e-04 1.642820e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p4_rise_"
  Transient (
    InitialTime=1.642820e-04 FinalTime=1.642830e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p4_write_"
  Transient (
    InitialTime=1.642830e-04 FinalTime=1.643830e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.642830e-04 1.643830e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p4_fall_"
  Transient (
    InitialTime=1.643830e-04 FinalTime=1.643840e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p4_read_"
  Transient (
    InitialTime=1.643840e-04 FinalTime=1.644840e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.643840e-04 1.644840e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p5_rise_"
  Transient (
    InitialTime=1.644840e-04 FinalTime=1.644850e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p5_write_"
  Transient (
    InitialTime=1.644850e-04 FinalTime=1.645850e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.644850e-04 1.645850e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p5_fall_"
  Transient (
    InitialTime=1.645850e-04 FinalTime=1.645860e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p5_read_"
  Transient (
    InitialTime=1.645860e-04 FinalTime=1.646860e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.645860e-04 1.646860e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p6_rise_"
  Transient (
    InitialTime=1.646860e-04 FinalTime=1.646870e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p6_write_"
  Transient (
    InitialTime=1.646870e-04 FinalTime=1.647870e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.646870e-04 1.647870e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p6_fall_"
  Transient (
    InitialTime=1.647870e-04 FinalTime=1.647880e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p6_read_"
  Transient (
    InitialTime=1.647880e-04 FinalTime=1.648880e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.647880e-04 1.648880e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p7_rise_"
  Transient (
    InitialTime=1.648880e-04 FinalTime=1.648890e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p7_write_"
  Transient (
    InitialTime=1.648890e-04 FinalTime=1.649890e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.648890e-04 1.649890e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p7_fall_"
  Transient (
    InitialTime=1.649890e-04 FinalTime=1.649900e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p7_read_"
  Transient (
    InitialTime=1.649900e-04 FinalTime=1.650900e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.649900e-04 1.650900e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p8_rise_"
  Transient (
    InitialTime=1.650900e-04 FinalTime=1.650910e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p8_write_"
  Transient (
    InitialTime=1.650910e-04 FinalTime=1.651910e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.650910e-04 1.651910e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p8_fall_"
  Transient (
    InitialTime=1.651910e-04 FinalTime=1.651920e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p8_read_"
  Transient (
    InitialTime=1.651920e-04 FinalTime=1.652920e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.651920e-04 1.652920e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p9_rise_"
  Transient (
    InitialTime=1.652920e-04 FinalTime=1.652930e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p9_write_"
  Transient (
    InitialTime=1.652930e-04 FinalTime=1.653930e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.652930e-04 1.653930e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p9_fall_"
  Transient (
    InitialTime=1.653930e-04 FinalTime=1.653940e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p9_read_"
  Transient (
    InitialTime=1.653940e-04 FinalTime=1.654940e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.653940e-04 1.654940e-04) Intervals=20) ) }
  *--- CYCLE 3 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c3_erase_rise_"
  Transient (
    InitialTime=1.654940e-04 FinalTime=1.655040e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_erase_hold_"
  Transient (
    InitialTime=1.655040e-04 FinalTime=1.755040e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.655040e-04 1.755040e-04) Intervals=40) ) }
  NewCurrentPrefix="c3_erase_fall_"
  Transient (
    InitialTime=1.755040e-04 FinalTime=1.755140e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 3 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c3_relax_"
  Transient (
    InitialTime=1.755140e-04 FinalTime=2.455140e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.755140e-04 2.455140e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 4 (cycle base time = 2.455140e-04)
  *====================================================================
  NewCurrentPrefix="c4_p1_rise_"
  Transient (
    InitialTime=2.455140e-04 FinalTime=2.455150e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p1_write_"
  Transient (
    InitialTime=2.455150e-04 FinalTime=2.456150e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.455150e-04 2.456150e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p1_fall_"
  Transient (
    InitialTime=2.456150e-04 FinalTime=2.456160e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p1_read_"
  Transient (
    InitialTime=2.456160e-04 FinalTime=2.457160e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.456160e-04 2.457160e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p2_rise_"
  Transient (
    InitialTime=2.457160e-04 FinalTime=2.457170e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_write_"
  Transient (
    InitialTime=2.457170e-04 FinalTime=2.458170e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.457170e-04 2.458170e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p2_fall_"
  Transient (
    InitialTime=2.458170e-04 FinalTime=2.458180e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_read_"
  Transient (
    InitialTime=2.458180e-04 FinalTime=2.459180e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.458180e-04 2.459180e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p3_rise_"
  Transient (
    InitialTime=2.459180e-04 FinalTime=2.459190e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_write_"
  Transient (
    InitialTime=2.459190e-04 FinalTime=2.460190e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.459190e-04 2.460190e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p3_fall_"
  Transient (
    InitialTime=2.460190e-04 FinalTime=2.460200e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_read_"
  Transient (
    InitialTime=2.460200e-04 FinalTime=2.461200e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.460200e-04 2.461200e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p4_rise_"
  Transient (
    InitialTime=2.461200e-04 FinalTime=2.461210e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p4_write_"
  Transient (
    InitialTime=2.461210e-04 FinalTime=2.462210e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.461210e-04 2.462210e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p4_fall_"
  Transient (
    InitialTime=2.462210e-04 FinalTime=2.462220e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p4_read_"
  Transient (
    InitialTime=2.462220e-04 FinalTime=2.463220e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.462220e-04 2.463220e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p5_rise_"
  Transient (
    InitialTime=2.463220e-04 FinalTime=2.463230e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p5_write_"
  Transient (
    InitialTime=2.463230e-04 FinalTime=2.464230e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.463230e-04 2.464230e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p5_fall_"
  Transient (
    InitialTime=2.464230e-04 FinalTime=2.464240e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p5_read_"
  Transient (
    InitialTime=2.464240e-04 FinalTime=2.465240e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.464240e-04 2.465240e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p6_rise_"
  Transient (
    InitialTime=2.465240e-04 FinalTime=2.465250e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p6_write_"
  Transient (
    InitialTime=2.465250e-04 FinalTime=2.466250e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.465250e-04 2.466250e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p6_fall_"
  Transient (
    InitialTime=2.466250e-04 FinalTime=2.466260e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p6_read_"
  Transient (
    InitialTime=2.466260e-04 FinalTime=2.467260e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.466260e-04 2.467260e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p7_rise_"
  Transient (
    InitialTime=2.467260e-04 FinalTime=2.467270e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p7_write_"
  Transient (
    InitialTime=2.467270e-04 FinalTime=2.468270e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.467270e-04 2.468270e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p7_fall_"
  Transient (
    InitialTime=2.468270e-04 FinalTime=2.468280e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p7_read_"
  Transient (
    InitialTime=2.468280e-04 FinalTime=2.469280e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.468280e-04 2.469280e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p8_rise_"
  Transient (
    InitialTime=2.469280e-04 FinalTime=2.469290e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p8_write_"
  Transient (
    InitialTime=2.469290e-04 FinalTime=2.470290e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.469290e-04 2.470290e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p8_fall_"
  Transient (
    InitialTime=2.470290e-04 FinalTime=2.470300e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p8_read_"
  Transient (
    InitialTime=2.470300e-04 FinalTime=2.471300e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.470300e-04 2.471300e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p9_rise_"
  Transient (
    InitialTime=2.471300e-04 FinalTime=2.471310e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p9_write_"
  Transient (
    InitialTime=2.471310e-04 FinalTime=2.472310e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.471310e-04 2.472310e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p9_fall_"
  Transient (
    InitialTime=2.472310e-04 FinalTime=2.472320e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p9_read_"
  Transient (
    InitialTime=2.472320e-04 FinalTime=2.473320e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.472320e-04 2.473320e-04) Intervals=20) ) }
  *--- CYCLE 4 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c4_erase_rise_"
  Transient (
    InitialTime=2.473320e-04 FinalTime=2.473420e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_erase_hold_"
  Transient (
    InitialTime=2.473420e-04 FinalTime=2.573420e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.473420e-04 2.573420e-04) Intervals=40) ) }
  NewCurrentPrefix="c4_erase_fall_"
  Transient (
    InitialTime=2.573420e-04 FinalTime=2.573520e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 4 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c4_relax_"
  Transient (
    InitialTime=2.573520e-04 FinalTime=3.273520e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.573520e-04 3.273520e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 5 (cycle base time = 3.273520e-04)
  *====================================================================
  NewCurrentPrefix="c5_p1_rise_"
  Transient (
    InitialTime=3.273520e-04 FinalTime=3.273530e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p1_write_"
  Transient (
    InitialTime=3.273530e-04 FinalTime=3.274530e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.273530e-04 3.274530e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p1_fall_"
  Transient (
    InitialTime=3.274530e-04 FinalTime=3.274540e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p1_read_"
  Transient (
    InitialTime=3.274540e-04 FinalTime=3.275540e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.274540e-04 3.275540e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p2_rise_"
  Transient (
    InitialTime=3.275540e-04 FinalTime=3.275550e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_write_"
  Transient (
    InitialTime=3.275550e-04 FinalTime=3.276550e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.275550e-04 3.276550e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p2_fall_"
  Transient (
    InitialTime=3.276550e-04 FinalTime=3.276560e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_read_"
  Transient (
    InitialTime=3.276560e-04 FinalTime=3.277560e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.276560e-04 3.277560e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p3_rise_"
  Transient (
    InitialTime=3.277560e-04 FinalTime=3.277570e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_write_"
  Transient (
    InitialTime=3.277570e-04 FinalTime=3.278570e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.277570e-04 3.278570e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p3_fall_"
  Transient (
    InitialTime=3.278570e-04 FinalTime=3.278580e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_read_"
  Transient (
    InitialTime=3.278580e-04 FinalTime=3.279580e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.278580e-04 3.279580e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p4_rise_"
  Transient (
    InitialTime=3.279580e-04 FinalTime=3.279590e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p4_write_"
  Transient (
    InitialTime=3.279590e-04 FinalTime=3.280590e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.279590e-04 3.280590e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p4_fall_"
  Transient (
    InitialTime=3.280590e-04 FinalTime=3.280600e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p4_read_"
  Transient (
    InitialTime=3.280600e-04 FinalTime=3.281600e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.280600e-04 3.281600e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p5_rise_"
  Transient (
    InitialTime=3.281600e-04 FinalTime=3.281610e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p5_write_"
  Transient (
    InitialTime=3.281610e-04 FinalTime=3.282610e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.281610e-04 3.282610e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p5_fall_"
  Transient (
    InitialTime=3.282610e-04 FinalTime=3.282620e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p5_read_"
  Transient (
    InitialTime=3.282620e-04 FinalTime=3.283620e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.282620e-04 3.283620e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p6_rise_"
  Transient (
    InitialTime=3.283620e-04 FinalTime=3.283630e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p6_write_"
  Transient (
    InitialTime=3.283630e-04 FinalTime=3.284630e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.283630e-04 3.284630e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p6_fall_"
  Transient (
    InitialTime=3.284630e-04 FinalTime=3.284640e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p6_read_"
  Transient (
    InitialTime=3.284640e-04 FinalTime=3.285640e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.284640e-04 3.285640e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p7_rise_"
  Transient (
    InitialTime=3.285640e-04 FinalTime=3.285650e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p7_write_"
  Transient (
    InitialTime=3.285650e-04 FinalTime=3.286650e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.285650e-04 3.286650e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p7_fall_"
  Transient (
    InitialTime=3.286650e-04 FinalTime=3.286660e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p7_read_"
  Transient (
    InitialTime=3.286660e-04 FinalTime=3.287660e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.286660e-04 3.287660e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p8_rise_"
  Transient (
    InitialTime=3.287660e-04 FinalTime=3.287670e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p8_write_"
  Transient (
    InitialTime=3.287670e-04 FinalTime=3.288670e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.287670e-04 3.288670e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p8_fall_"
  Transient (
    InitialTime=3.288670e-04 FinalTime=3.288680e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p8_read_"
  Transient (
    InitialTime=3.288680e-04 FinalTime=3.289680e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.288680e-04 3.289680e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p9_rise_"
  Transient (
    InitialTime=3.289680e-04 FinalTime=3.289690e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p9_write_"
  Transient (
    InitialTime=3.289690e-04 FinalTime=3.290690e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.289690e-04 3.290690e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p9_fall_"
  Transient (
    InitialTime=3.290690e-04 FinalTime=3.290700e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p9_read_"
  Transient (
    InitialTime=3.290700e-04 FinalTime=3.291700e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.290700e-04 3.291700e-04) Intervals=20) ) }
  *--- CYCLE 5 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c5_erase_rise_"
  Transient (
    InitialTime=3.291700e-04 FinalTime=3.291800e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_erase_hold_"
  Transient (
    InitialTime=3.291800e-04 FinalTime=3.391800e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.291800e-04 3.391800e-04) Intervals=40) ) }
  NewCurrentPrefix="c5_erase_fall_"
  Transient (
    InitialTime=3.391800e-04 FinalTime=3.391900e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 5 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c5_relax_"
  Transient (
    InitialTime=3.391900e-04 FinalTime=4.091900e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.391900e-04 4.091900e-04) Intervals=70) ) }

}

*===================================================================
*== SWB SETUP (set in SWB project, not in this file):
*==   Parameter:  V_erase
*==   Sweep (L3): -4.0  -6.0  -10.0    V
*==
*== POST-PROCESSING (Simulations/analyze_phase1d_h3.py, cyclic update):
*==   Per node:
*==     1. ID_pre_cN  = ID at end of pre-cycle baseline read
*==                     (cycle 1: baseline_pre_, cycle N>1: c{N-1}_relax_)
*==     2. ID_p9_cN   = ID at end of c{N}_p9_read_
*==     3. fire_ratio_cN = ID_p9_cN / ID_pre_cN
*==     4. drift_per_cycle = (ID_p9_c5 - ID_p9_c3) / ID_p9_c3 / 2
*==        PASS (M1): |drift| <= 1.0 percent/cycle
*==        PASS (M2): fire_ratio_cN >= 1.5 for every cycle N in 1..5
*==        PASS (restore): ID_end_relax_cN / ID_baseline_virgin in [0.75, 1.25]
*==     5. Monotonicity: flag any cN where the 9-pulse staircase
*==        is not monotonic (p_k > p_{k+1}) for k >= 2.
*==     Pick V_erase that passes all four.  This is V_erase_opt for H4.
*===================================================================
