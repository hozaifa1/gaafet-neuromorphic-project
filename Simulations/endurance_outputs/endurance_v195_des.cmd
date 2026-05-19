*===================================================================
*== PHASE 1D - H4 ENDURANCE: 20-cycle LIF + V_pgm variability sweep
*==
*== Per-cycle phases (identical to H3 Step 3b):
*==   (a) 9 program pulses at V_pgm=1.95 V (100ns hold, 100ns sub-Vt read)
*==   (b) 10ns ramp gate -> V_erase = -6.0 V (locked from Step 3b)
*==   (c) 10us hold at V_erase
*==   (d) 10ns ramp gate -> V_GS = -0.5 V
*==   (e) 70us relax at V_GS = -0.5 V
*==
*== Per-cycle wall time:
*==   9 fires (9 * 202 ns)                   = 1818 ns
*==   erase (10 ns rise / 10 us hold / fall) = 10020 ns
*==   relax (70 us at V_GS = -0.5 V)         = 70000 ns
*==   ---------------------------------------------------
*==   Per cycle = 81.838 us  |  Total 20 cycles = 1636.760 us
*==
*== SWB sweep: V_pgm in {1.95, 1.975, 2.0, 2.025, 2.05} V  (L5, 25 mV step)
*==
*== Acceptance:
*==   (M1)     |drift_c10->c20| <= 1.0 percent/cycle on ID_p9 (long-tail)
*==   (M2)     fire_ratio_cN = ID_p9_cN / ID_pre_cN >= 1.5 for every N
*==   (M-rest) |drift_c10->c20| <= 1.0 percent/cycle on ID_end_relax
*==   (M8)     sigma/mu of fire_ratio across V_pgm nodes (c10..c20) <= 5 percent
*===================================================================

File {
    Grid       = "n1_msh.tdr"
    Parameter  = "sdevice_gaafet_lif.par"
    Plot       = "endurance_outputs/endurance_v195_des.tdr"
    Current    = "endurance_outputs/endurance_v195_des.plt"
    Output     = "endurance_outputs/endurance_v195_des.log"
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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
    Goal { Name="gate_contact" Voltage= 1.95 }
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

  *====================================================================
  *== CYCLE 6 (cycle base time = 4.091900e-04)
  *====================================================================
  NewCurrentPrefix="c6_p1_rise_"
  Transient (
    InitialTime=4.091900e-04 FinalTime=4.091910e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p1_write_"
  Transient (
    InitialTime=4.091910e-04 FinalTime=4.092910e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.091910e-04 4.092910e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p1_fall_"
  Transient (
    InitialTime=4.092910e-04 FinalTime=4.092920e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p1_read_"
  Transient (
    InitialTime=4.092920e-04 FinalTime=4.093920e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.092920e-04 4.093920e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p2_rise_"
  Transient (
    InitialTime=4.093920e-04 FinalTime=4.093930e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p2_write_"
  Transient (
    InitialTime=4.093930e-04 FinalTime=4.094930e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.093930e-04 4.094930e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p2_fall_"
  Transient (
    InitialTime=4.094930e-04 FinalTime=4.094940e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p2_read_"
  Transient (
    InitialTime=4.094940e-04 FinalTime=4.095940e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.094940e-04 4.095940e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p3_rise_"
  Transient (
    InitialTime=4.095940e-04 FinalTime=4.095950e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p3_write_"
  Transient (
    InitialTime=4.095950e-04 FinalTime=4.096950e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.095950e-04 4.096950e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p3_fall_"
  Transient (
    InitialTime=4.096950e-04 FinalTime=4.096960e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p3_read_"
  Transient (
    InitialTime=4.096960e-04 FinalTime=4.097960e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.096960e-04 4.097960e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p4_rise_"
  Transient (
    InitialTime=4.097960e-04 FinalTime=4.097970e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p4_write_"
  Transient (
    InitialTime=4.097970e-04 FinalTime=4.098970e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.097970e-04 4.098970e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p4_fall_"
  Transient (
    InitialTime=4.098970e-04 FinalTime=4.098980e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p4_read_"
  Transient (
    InitialTime=4.098980e-04 FinalTime=4.099980e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.098980e-04 4.099980e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p5_rise_"
  Transient (
    InitialTime=4.099980e-04 FinalTime=4.099990e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p5_write_"
  Transient (
    InitialTime=4.099990e-04 FinalTime=4.100990e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.099990e-04 4.100990e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p5_fall_"
  Transient (
    InitialTime=4.100990e-04 FinalTime=4.101000e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p5_read_"
  Transient (
    InitialTime=4.101000e-04 FinalTime=4.102000e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.101000e-04 4.102000e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p6_rise_"
  Transient (
    InitialTime=4.102000e-04 FinalTime=4.102010e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p6_write_"
  Transient (
    InitialTime=4.102010e-04 FinalTime=4.103010e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.102010e-04 4.103010e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p6_fall_"
  Transient (
    InitialTime=4.103010e-04 FinalTime=4.103020e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p6_read_"
  Transient (
    InitialTime=4.103020e-04 FinalTime=4.104020e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.103020e-04 4.104020e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p7_rise_"
  Transient (
    InitialTime=4.104020e-04 FinalTime=4.104030e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p7_write_"
  Transient (
    InitialTime=4.104030e-04 FinalTime=4.105030e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.104030e-04 4.105030e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p7_fall_"
  Transient (
    InitialTime=4.105030e-04 FinalTime=4.105040e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p7_read_"
  Transient (
    InitialTime=4.105040e-04 FinalTime=4.106040e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.105040e-04 4.106040e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p8_rise_"
  Transient (
    InitialTime=4.106040e-04 FinalTime=4.106050e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p8_write_"
  Transient (
    InitialTime=4.106050e-04 FinalTime=4.107050e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.106050e-04 4.107050e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p8_fall_"
  Transient (
    InitialTime=4.107050e-04 FinalTime=4.107060e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p8_read_"
  Transient (
    InitialTime=4.107060e-04 FinalTime=4.108060e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.107060e-04 4.108060e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p9_rise_"
  Transient (
    InitialTime=4.108060e-04 FinalTime=4.108070e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p9_write_"
  Transient (
    InitialTime=4.108070e-04 FinalTime=4.109070e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.108070e-04 4.109070e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p9_fall_"
  Transient (
    InitialTime=4.109070e-04 FinalTime=4.109080e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p9_read_"
  Transient (
    InitialTime=4.109080e-04 FinalTime=4.110080e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.109080e-04 4.110080e-04) Intervals=20) ) }
  *--- CYCLE 6 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c6_erase_rise_"
  Transient (
    InitialTime=4.110080e-04 FinalTime=4.110180e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_erase_hold_"
  Transient (
    InitialTime=4.110180e-04 FinalTime=4.210180e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.110180e-04 4.210180e-04) Intervals=40) ) }
  NewCurrentPrefix="c6_erase_fall_"
  Transient (
    InitialTime=4.210180e-04 FinalTime=4.210280e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 6 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c6_relax_"
  Transient (
    InitialTime=4.210280e-04 FinalTime=4.910280e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.210280e-04 4.910280e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 7 (cycle base time = 4.910280e-04)
  *====================================================================
  NewCurrentPrefix="c7_p1_rise_"
  Transient (
    InitialTime=4.910280e-04 FinalTime=4.910290e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p1_write_"
  Transient (
    InitialTime=4.910290e-04 FinalTime=4.911290e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.910290e-04 4.911290e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p1_fall_"
  Transient (
    InitialTime=4.911290e-04 FinalTime=4.911300e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p1_read_"
  Transient (
    InitialTime=4.911300e-04 FinalTime=4.912300e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.911300e-04 4.912300e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p2_rise_"
  Transient (
    InitialTime=4.912300e-04 FinalTime=4.912310e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p2_write_"
  Transient (
    InitialTime=4.912310e-04 FinalTime=4.913310e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.912310e-04 4.913310e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p2_fall_"
  Transient (
    InitialTime=4.913310e-04 FinalTime=4.913320e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p2_read_"
  Transient (
    InitialTime=4.913320e-04 FinalTime=4.914320e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.913320e-04 4.914320e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p3_rise_"
  Transient (
    InitialTime=4.914320e-04 FinalTime=4.914330e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p3_write_"
  Transient (
    InitialTime=4.914330e-04 FinalTime=4.915330e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.914330e-04 4.915330e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p3_fall_"
  Transient (
    InitialTime=4.915330e-04 FinalTime=4.915340e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p3_read_"
  Transient (
    InitialTime=4.915340e-04 FinalTime=4.916340e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.915340e-04 4.916340e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p4_rise_"
  Transient (
    InitialTime=4.916340e-04 FinalTime=4.916350e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p4_write_"
  Transient (
    InitialTime=4.916350e-04 FinalTime=4.917350e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.916350e-04 4.917350e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p4_fall_"
  Transient (
    InitialTime=4.917350e-04 FinalTime=4.917360e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p4_read_"
  Transient (
    InitialTime=4.917360e-04 FinalTime=4.918360e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.917360e-04 4.918360e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p5_rise_"
  Transient (
    InitialTime=4.918360e-04 FinalTime=4.918370e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p5_write_"
  Transient (
    InitialTime=4.918370e-04 FinalTime=4.919370e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.918370e-04 4.919370e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p5_fall_"
  Transient (
    InitialTime=4.919370e-04 FinalTime=4.919380e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p5_read_"
  Transient (
    InitialTime=4.919380e-04 FinalTime=4.920380e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.919380e-04 4.920380e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p6_rise_"
  Transient (
    InitialTime=4.920380e-04 FinalTime=4.920390e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p6_write_"
  Transient (
    InitialTime=4.920390e-04 FinalTime=4.921390e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.920390e-04 4.921390e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p6_fall_"
  Transient (
    InitialTime=4.921390e-04 FinalTime=4.921400e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p6_read_"
  Transient (
    InitialTime=4.921400e-04 FinalTime=4.922400e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.921400e-04 4.922400e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p7_rise_"
  Transient (
    InitialTime=4.922400e-04 FinalTime=4.922410e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p7_write_"
  Transient (
    InitialTime=4.922410e-04 FinalTime=4.923410e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.922410e-04 4.923410e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p7_fall_"
  Transient (
    InitialTime=4.923410e-04 FinalTime=4.923420e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p7_read_"
  Transient (
    InitialTime=4.923420e-04 FinalTime=4.924420e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.923420e-04 4.924420e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p8_rise_"
  Transient (
    InitialTime=4.924420e-04 FinalTime=4.924430e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p8_write_"
  Transient (
    InitialTime=4.924430e-04 FinalTime=4.925430e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.924430e-04 4.925430e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p8_fall_"
  Transient (
    InitialTime=4.925430e-04 FinalTime=4.925440e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p8_read_"
  Transient (
    InitialTime=4.925440e-04 FinalTime=4.926440e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.925440e-04 4.926440e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p9_rise_"
  Transient (
    InitialTime=4.926440e-04 FinalTime=4.926450e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p9_write_"
  Transient (
    InitialTime=4.926450e-04 FinalTime=4.927450e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.926450e-04 4.927450e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p9_fall_"
  Transient (
    InitialTime=4.927450e-04 FinalTime=4.927460e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p9_read_"
  Transient (
    InitialTime=4.927460e-04 FinalTime=4.928460e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.927460e-04 4.928460e-04) Intervals=20) ) }
  *--- CYCLE 7 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c7_erase_rise_"
  Transient (
    InitialTime=4.928460e-04 FinalTime=4.928560e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_erase_hold_"
  Transient (
    InitialTime=4.928560e-04 FinalTime=5.028560e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.928560e-04 5.028560e-04) Intervals=40) ) }
  NewCurrentPrefix="c7_erase_fall_"
  Transient (
    InitialTime=5.028560e-04 FinalTime=5.028660e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 7 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c7_relax_"
  Transient (
    InitialTime=5.028660e-04 FinalTime=5.728660e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.028660e-04 5.728660e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 8 (cycle base time = 5.728660e-04)
  *====================================================================
  NewCurrentPrefix="c8_p1_rise_"
  Transient (
    InitialTime=5.728660e-04 FinalTime=5.728670e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p1_write_"
  Transient (
    InitialTime=5.728670e-04 FinalTime=5.729670e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.728670e-04 5.729670e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p1_fall_"
  Transient (
    InitialTime=5.729670e-04 FinalTime=5.729680e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p1_read_"
  Transient (
    InitialTime=5.729680e-04 FinalTime=5.730680e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.729680e-04 5.730680e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p2_rise_"
  Transient (
    InitialTime=5.730680e-04 FinalTime=5.730690e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p2_write_"
  Transient (
    InitialTime=5.730690e-04 FinalTime=5.731690e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.730690e-04 5.731690e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p2_fall_"
  Transient (
    InitialTime=5.731690e-04 FinalTime=5.731700e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p2_read_"
  Transient (
    InitialTime=5.731700e-04 FinalTime=5.732700e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.731700e-04 5.732700e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p3_rise_"
  Transient (
    InitialTime=5.732700e-04 FinalTime=5.732710e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p3_write_"
  Transient (
    InitialTime=5.732710e-04 FinalTime=5.733710e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.732710e-04 5.733710e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p3_fall_"
  Transient (
    InitialTime=5.733710e-04 FinalTime=5.733720e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p3_read_"
  Transient (
    InitialTime=5.733720e-04 FinalTime=5.734720e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.733720e-04 5.734720e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p4_rise_"
  Transient (
    InitialTime=5.734720e-04 FinalTime=5.734730e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p4_write_"
  Transient (
    InitialTime=5.734730e-04 FinalTime=5.735730e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.734730e-04 5.735730e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p4_fall_"
  Transient (
    InitialTime=5.735730e-04 FinalTime=5.735740e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p4_read_"
  Transient (
    InitialTime=5.735740e-04 FinalTime=5.736740e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.735740e-04 5.736740e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p5_rise_"
  Transient (
    InitialTime=5.736740e-04 FinalTime=5.736750e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p5_write_"
  Transient (
    InitialTime=5.736750e-04 FinalTime=5.737750e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.736750e-04 5.737750e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p5_fall_"
  Transient (
    InitialTime=5.737750e-04 FinalTime=5.737760e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p5_read_"
  Transient (
    InitialTime=5.737760e-04 FinalTime=5.738760e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.737760e-04 5.738760e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p6_rise_"
  Transient (
    InitialTime=5.738760e-04 FinalTime=5.738770e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p6_write_"
  Transient (
    InitialTime=5.738770e-04 FinalTime=5.739770e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.738770e-04 5.739770e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p6_fall_"
  Transient (
    InitialTime=5.739770e-04 FinalTime=5.739780e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p6_read_"
  Transient (
    InitialTime=5.739780e-04 FinalTime=5.740780e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.739780e-04 5.740780e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p7_rise_"
  Transient (
    InitialTime=5.740780e-04 FinalTime=5.740790e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p7_write_"
  Transient (
    InitialTime=5.740790e-04 FinalTime=5.741790e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.740790e-04 5.741790e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p7_fall_"
  Transient (
    InitialTime=5.741790e-04 FinalTime=5.741800e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p7_read_"
  Transient (
    InitialTime=5.741800e-04 FinalTime=5.742800e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.741800e-04 5.742800e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p8_rise_"
  Transient (
    InitialTime=5.742800e-04 FinalTime=5.742810e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p8_write_"
  Transient (
    InitialTime=5.742810e-04 FinalTime=5.743810e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.742810e-04 5.743810e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p8_fall_"
  Transient (
    InitialTime=5.743810e-04 FinalTime=5.743820e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p8_read_"
  Transient (
    InitialTime=5.743820e-04 FinalTime=5.744820e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.743820e-04 5.744820e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p9_rise_"
  Transient (
    InitialTime=5.744820e-04 FinalTime=5.744830e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p9_write_"
  Transient (
    InitialTime=5.744830e-04 FinalTime=5.745830e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.744830e-04 5.745830e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p9_fall_"
  Transient (
    InitialTime=5.745830e-04 FinalTime=5.745840e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p9_read_"
  Transient (
    InitialTime=5.745840e-04 FinalTime=5.746840e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.745840e-04 5.746840e-04) Intervals=20) ) }
  *--- CYCLE 8 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c8_erase_rise_"
  Transient (
    InitialTime=5.746840e-04 FinalTime=5.746940e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_erase_hold_"
  Transient (
    InitialTime=5.746940e-04 FinalTime=5.846940e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.746940e-04 5.846940e-04) Intervals=40) ) }
  NewCurrentPrefix="c8_erase_fall_"
  Transient (
    InitialTime=5.846940e-04 FinalTime=5.847040e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 8 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c8_relax_"
  Transient (
    InitialTime=5.847040e-04 FinalTime=6.547040e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.847040e-04 6.547040e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 9 (cycle base time = 6.547040e-04)
  *====================================================================
  NewCurrentPrefix="c9_p1_rise_"
  Transient (
    InitialTime=6.547040e-04 FinalTime=6.547050e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p1_write_"
  Transient (
    InitialTime=6.547050e-04 FinalTime=6.548050e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.547050e-04 6.548050e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p1_fall_"
  Transient (
    InitialTime=6.548050e-04 FinalTime=6.548060e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p1_read_"
  Transient (
    InitialTime=6.548060e-04 FinalTime=6.549060e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.548060e-04 6.549060e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p2_rise_"
  Transient (
    InitialTime=6.549060e-04 FinalTime=6.549070e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p2_write_"
  Transient (
    InitialTime=6.549070e-04 FinalTime=6.550070e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.549070e-04 6.550070e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p2_fall_"
  Transient (
    InitialTime=6.550070e-04 FinalTime=6.550080e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p2_read_"
  Transient (
    InitialTime=6.550080e-04 FinalTime=6.551080e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.550080e-04 6.551080e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p3_rise_"
  Transient (
    InitialTime=6.551080e-04 FinalTime=6.551090e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p3_write_"
  Transient (
    InitialTime=6.551090e-04 FinalTime=6.552090e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.551090e-04 6.552090e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p3_fall_"
  Transient (
    InitialTime=6.552090e-04 FinalTime=6.552100e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p3_read_"
  Transient (
    InitialTime=6.552100e-04 FinalTime=6.553100e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.552100e-04 6.553100e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p4_rise_"
  Transient (
    InitialTime=6.553100e-04 FinalTime=6.553110e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p4_write_"
  Transient (
    InitialTime=6.553110e-04 FinalTime=6.554110e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.553110e-04 6.554110e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p4_fall_"
  Transient (
    InitialTime=6.554110e-04 FinalTime=6.554120e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p4_read_"
  Transient (
    InitialTime=6.554120e-04 FinalTime=6.555120e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.554120e-04 6.555120e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p5_rise_"
  Transient (
    InitialTime=6.555120e-04 FinalTime=6.555130e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p5_write_"
  Transient (
    InitialTime=6.555130e-04 FinalTime=6.556130e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.555130e-04 6.556130e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p5_fall_"
  Transient (
    InitialTime=6.556130e-04 FinalTime=6.556140e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p5_read_"
  Transient (
    InitialTime=6.556140e-04 FinalTime=6.557140e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.556140e-04 6.557140e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p6_rise_"
  Transient (
    InitialTime=6.557140e-04 FinalTime=6.557150e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p6_write_"
  Transient (
    InitialTime=6.557150e-04 FinalTime=6.558150e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.557150e-04 6.558150e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p6_fall_"
  Transient (
    InitialTime=6.558150e-04 FinalTime=6.558160e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p6_read_"
  Transient (
    InitialTime=6.558160e-04 FinalTime=6.559160e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.558160e-04 6.559160e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p7_rise_"
  Transient (
    InitialTime=6.559160e-04 FinalTime=6.559170e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p7_write_"
  Transient (
    InitialTime=6.559170e-04 FinalTime=6.560170e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.559170e-04 6.560170e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p7_fall_"
  Transient (
    InitialTime=6.560170e-04 FinalTime=6.560180e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p7_read_"
  Transient (
    InitialTime=6.560180e-04 FinalTime=6.561180e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.560180e-04 6.561180e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p8_rise_"
  Transient (
    InitialTime=6.561180e-04 FinalTime=6.561190e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p8_write_"
  Transient (
    InitialTime=6.561190e-04 FinalTime=6.562190e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.561190e-04 6.562190e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p8_fall_"
  Transient (
    InitialTime=6.562190e-04 FinalTime=6.562200e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p8_read_"
  Transient (
    InitialTime=6.562200e-04 FinalTime=6.563200e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.562200e-04 6.563200e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p9_rise_"
  Transient (
    InitialTime=6.563200e-04 FinalTime=6.563210e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p9_write_"
  Transient (
    InitialTime=6.563210e-04 FinalTime=6.564210e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.563210e-04 6.564210e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p9_fall_"
  Transient (
    InitialTime=6.564210e-04 FinalTime=6.564220e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p9_read_"
  Transient (
    InitialTime=6.564220e-04 FinalTime=6.565220e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.564220e-04 6.565220e-04) Intervals=20) ) }
  *--- CYCLE 9 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c9_erase_rise_"
  Transient (
    InitialTime=6.565220e-04 FinalTime=6.565320e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_erase_hold_"
  Transient (
    InitialTime=6.565320e-04 FinalTime=6.665320e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.565320e-04 6.665320e-04) Intervals=40) ) }
  NewCurrentPrefix="c9_erase_fall_"
  Transient (
    InitialTime=6.665320e-04 FinalTime=6.665420e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 9 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c9_relax_"
  Transient (
    InitialTime=6.665420e-04 FinalTime=7.365420e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.665420e-04 7.365420e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 10 (cycle base time = 7.365420e-04)
  *====================================================================
  NewCurrentPrefix="c10_p1_rise_"
  Transient (
    InitialTime=7.365420e-04 FinalTime=7.365430e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p1_write_"
  Transient (
    InitialTime=7.365430e-04 FinalTime=7.366430e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.365430e-04 7.366430e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p1_fall_"
  Transient (
    InitialTime=7.366430e-04 FinalTime=7.366440e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p1_read_"
  Transient (
    InitialTime=7.366440e-04 FinalTime=7.367440e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.366440e-04 7.367440e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p2_rise_"
  Transient (
    InitialTime=7.367440e-04 FinalTime=7.367450e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p2_write_"
  Transient (
    InitialTime=7.367450e-04 FinalTime=7.368450e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.367450e-04 7.368450e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p2_fall_"
  Transient (
    InitialTime=7.368450e-04 FinalTime=7.368460e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p2_read_"
  Transient (
    InitialTime=7.368460e-04 FinalTime=7.369460e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.368460e-04 7.369460e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p3_rise_"
  Transient (
    InitialTime=7.369460e-04 FinalTime=7.369470e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p3_write_"
  Transient (
    InitialTime=7.369470e-04 FinalTime=7.370470e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.369470e-04 7.370470e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p3_fall_"
  Transient (
    InitialTime=7.370470e-04 FinalTime=7.370480e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p3_read_"
  Transient (
    InitialTime=7.370480e-04 FinalTime=7.371480e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.370480e-04 7.371480e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p4_rise_"
  Transient (
    InitialTime=7.371480e-04 FinalTime=7.371490e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p4_write_"
  Transient (
    InitialTime=7.371490e-04 FinalTime=7.372490e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.371490e-04 7.372490e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p4_fall_"
  Transient (
    InitialTime=7.372490e-04 FinalTime=7.372500e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p4_read_"
  Transient (
    InitialTime=7.372500e-04 FinalTime=7.373500e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.372500e-04 7.373500e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p5_rise_"
  Transient (
    InitialTime=7.373500e-04 FinalTime=7.373510e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p5_write_"
  Transient (
    InitialTime=7.373510e-04 FinalTime=7.374510e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.373510e-04 7.374510e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p5_fall_"
  Transient (
    InitialTime=7.374510e-04 FinalTime=7.374520e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p5_read_"
  Transient (
    InitialTime=7.374520e-04 FinalTime=7.375520e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.374520e-04 7.375520e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p6_rise_"
  Transient (
    InitialTime=7.375520e-04 FinalTime=7.375530e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p6_write_"
  Transient (
    InitialTime=7.375530e-04 FinalTime=7.376530e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.375530e-04 7.376530e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p6_fall_"
  Transient (
    InitialTime=7.376530e-04 FinalTime=7.376540e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p6_read_"
  Transient (
    InitialTime=7.376540e-04 FinalTime=7.377540e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.376540e-04 7.377540e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p7_rise_"
  Transient (
    InitialTime=7.377540e-04 FinalTime=7.377550e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p7_write_"
  Transient (
    InitialTime=7.377550e-04 FinalTime=7.378550e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.377550e-04 7.378550e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p7_fall_"
  Transient (
    InitialTime=7.378550e-04 FinalTime=7.378560e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p7_read_"
  Transient (
    InitialTime=7.378560e-04 FinalTime=7.379560e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.378560e-04 7.379560e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p8_rise_"
  Transient (
    InitialTime=7.379560e-04 FinalTime=7.379570e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p8_write_"
  Transient (
    InitialTime=7.379570e-04 FinalTime=7.380570e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.379570e-04 7.380570e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p8_fall_"
  Transient (
    InitialTime=7.380570e-04 FinalTime=7.380580e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p8_read_"
  Transient (
    InitialTime=7.380580e-04 FinalTime=7.381580e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.380580e-04 7.381580e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p9_rise_"
  Transient (
    InitialTime=7.381580e-04 FinalTime=7.381590e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p9_write_"
  Transient (
    InitialTime=7.381590e-04 FinalTime=7.382590e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.381590e-04 7.382590e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p9_fall_"
  Transient (
    InitialTime=7.382590e-04 FinalTime=7.382600e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p9_read_"
  Transient (
    InitialTime=7.382600e-04 FinalTime=7.383600e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.382600e-04 7.383600e-04) Intervals=20) ) }
  *--- CYCLE 10 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c10_erase_rise_"
  Transient (
    InitialTime=7.383600e-04 FinalTime=7.383700e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_erase_hold_"
  Transient (
    InitialTime=7.383700e-04 FinalTime=7.483700e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.383700e-04 7.483700e-04) Intervals=40) ) }
  NewCurrentPrefix="c10_erase_fall_"
  Transient (
    InitialTime=7.483700e-04 FinalTime=7.483800e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 10 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c10_relax_"
  Transient (
    InitialTime=7.483800e-04 FinalTime=8.183800e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.483800e-04 8.183800e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 11 (cycle base time = 8.183800e-04)
  *====================================================================
  NewCurrentPrefix="c11_p1_rise_"
  Transient (
    InitialTime=8.183800e-04 FinalTime=8.183810e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p1_write_"
  Transient (
    InitialTime=8.183810e-04 FinalTime=8.184810e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.183810e-04 8.184810e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p1_fall_"
  Transient (
    InitialTime=8.184810e-04 FinalTime=8.184820e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p1_read_"
  Transient (
    InitialTime=8.184820e-04 FinalTime=8.185820e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.184820e-04 8.185820e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p2_rise_"
  Transient (
    InitialTime=8.185820e-04 FinalTime=8.185830e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p2_write_"
  Transient (
    InitialTime=8.185830e-04 FinalTime=8.186830e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.185830e-04 8.186830e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p2_fall_"
  Transient (
    InitialTime=8.186830e-04 FinalTime=8.186840e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p2_read_"
  Transient (
    InitialTime=8.186840e-04 FinalTime=8.187840e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.186840e-04 8.187840e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p3_rise_"
  Transient (
    InitialTime=8.187840e-04 FinalTime=8.187850e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p3_write_"
  Transient (
    InitialTime=8.187850e-04 FinalTime=8.188850e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.187850e-04 8.188850e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p3_fall_"
  Transient (
    InitialTime=8.188850e-04 FinalTime=8.188860e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p3_read_"
  Transient (
    InitialTime=8.188860e-04 FinalTime=8.189860e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.188860e-04 8.189860e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p4_rise_"
  Transient (
    InitialTime=8.189860e-04 FinalTime=8.189870e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p4_write_"
  Transient (
    InitialTime=8.189870e-04 FinalTime=8.190870e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.189870e-04 8.190870e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p4_fall_"
  Transient (
    InitialTime=8.190870e-04 FinalTime=8.190880e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p4_read_"
  Transient (
    InitialTime=8.190880e-04 FinalTime=8.191880e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.190880e-04 8.191880e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p5_rise_"
  Transient (
    InitialTime=8.191880e-04 FinalTime=8.191890e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p5_write_"
  Transient (
    InitialTime=8.191890e-04 FinalTime=8.192890e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.191890e-04 8.192890e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p5_fall_"
  Transient (
    InitialTime=8.192890e-04 FinalTime=8.192900e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p5_read_"
  Transient (
    InitialTime=8.192900e-04 FinalTime=8.193900e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.192900e-04 8.193900e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p6_rise_"
  Transient (
    InitialTime=8.193900e-04 FinalTime=8.193910e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p6_write_"
  Transient (
    InitialTime=8.193910e-04 FinalTime=8.194910e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.193910e-04 8.194910e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p6_fall_"
  Transient (
    InitialTime=8.194910e-04 FinalTime=8.194920e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p6_read_"
  Transient (
    InitialTime=8.194920e-04 FinalTime=8.195920e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.194920e-04 8.195920e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p7_rise_"
  Transient (
    InitialTime=8.195920e-04 FinalTime=8.195930e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p7_write_"
  Transient (
    InitialTime=8.195930e-04 FinalTime=8.196930e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.195930e-04 8.196930e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p7_fall_"
  Transient (
    InitialTime=8.196930e-04 FinalTime=8.196940e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p7_read_"
  Transient (
    InitialTime=8.196940e-04 FinalTime=8.197940e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.196940e-04 8.197940e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p8_rise_"
  Transient (
    InitialTime=8.197940e-04 FinalTime=8.197950e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p8_write_"
  Transient (
    InitialTime=8.197950e-04 FinalTime=8.198950e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.197950e-04 8.198950e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p8_fall_"
  Transient (
    InitialTime=8.198950e-04 FinalTime=8.198960e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p8_read_"
  Transient (
    InitialTime=8.198960e-04 FinalTime=8.199960e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.198960e-04 8.199960e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p9_rise_"
  Transient (
    InitialTime=8.199960e-04 FinalTime=8.199970e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p9_write_"
  Transient (
    InitialTime=8.199970e-04 FinalTime=8.200970e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.199970e-04 8.200970e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p9_fall_"
  Transient (
    InitialTime=8.200970e-04 FinalTime=8.200980e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p9_read_"
  Transient (
    InitialTime=8.200980e-04 FinalTime=8.201980e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.200980e-04 8.201980e-04) Intervals=20) ) }
  *--- CYCLE 11 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c11_erase_rise_"
  Transient (
    InitialTime=8.201980e-04 FinalTime=8.202080e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_erase_hold_"
  Transient (
    InitialTime=8.202080e-04 FinalTime=8.302080e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.202080e-04 8.302080e-04) Intervals=40) ) }
  NewCurrentPrefix="c11_erase_fall_"
  Transient (
    InitialTime=8.302080e-04 FinalTime=8.302180e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 11 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c11_relax_"
  Transient (
    InitialTime=8.302180e-04 FinalTime=9.002180e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.302180e-04 9.002180e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 12 (cycle base time = 9.002180e-04)
  *====================================================================
  NewCurrentPrefix="c12_p1_rise_"
  Transient (
    InitialTime=9.002180e-04 FinalTime=9.002190e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p1_write_"
  Transient (
    InitialTime=9.002190e-04 FinalTime=9.003190e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.002190e-04 9.003190e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p1_fall_"
  Transient (
    InitialTime=9.003190e-04 FinalTime=9.003200e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p1_read_"
  Transient (
    InitialTime=9.003200e-04 FinalTime=9.004200e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.003200e-04 9.004200e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p2_rise_"
  Transient (
    InitialTime=9.004200e-04 FinalTime=9.004210e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p2_write_"
  Transient (
    InitialTime=9.004210e-04 FinalTime=9.005210e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.004210e-04 9.005210e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p2_fall_"
  Transient (
    InitialTime=9.005210e-04 FinalTime=9.005220e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p2_read_"
  Transient (
    InitialTime=9.005220e-04 FinalTime=9.006220e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.005220e-04 9.006220e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p3_rise_"
  Transient (
    InitialTime=9.006220e-04 FinalTime=9.006230e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p3_write_"
  Transient (
    InitialTime=9.006230e-04 FinalTime=9.007230e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.006230e-04 9.007230e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p3_fall_"
  Transient (
    InitialTime=9.007230e-04 FinalTime=9.007240e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p3_read_"
  Transient (
    InitialTime=9.007240e-04 FinalTime=9.008240e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.007240e-04 9.008240e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p4_rise_"
  Transient (
    InitialTime=9.008240e-04 FinalTime=9.008250e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p4_write_"
  Transient (
    InitialTime=9.008250e-04 FinalTime=9.009250e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.008250e-04 9.009250e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p4_fall_"
  Transient (
    InitialTime=9.009250e-04 FinalTime=9.009260e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p4_read_"
  Transient (
    InitialTime=9.009260e-04 FinalTime=9.010260e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.009260e-04 9.010260e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p5_rise_"
  Transient (
    InitialTime=9.010260e-04 FinalTime=9.010270e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p5_write_"
  Transient (
    InitialTime=9.010270e-04 FinalTime=9.011270e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.010270e-04 9.011270e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p5_fall_"
  Transient (
    InitialTime=9.011270e-04 FinalTime=9.011280e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p5_read_"
  Transient (
    InitialTime=9.011280e-04 FinalTime=9.012280e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.011280e-04 9.012280e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p6_rise_"
  Transient (
    InitialTime=9.012280e-04 FinalTime=9.012290e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p6_write_"
  Transient (
    InitialTime=9.012290e-04 FinalTime=9.013290e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.012290e-04 9.013290e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p6_fall_"
  Transient (
    InitialTime=9.013290e-04 FinalTime=9.013300e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p6_read_"
  Transient (
    InitialTime=9.013300e-04 FinalTime=9.014300e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.013300e-04 9.014300e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p7_rise_"
  Transient (
    InitialTime=9.014300e-04 FinalTime=9.014310e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p7_write_"
  Transient (
    InitialTime=9.014310e-04 FinalTime=9.015310e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.014310e-04 9.015310e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p7_fall_"
  Transient (
    InitialTime=9.015310e-04 FinalTime=9.015320e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p7_read_"
  Transient (
    InitialTime=9.015320e-04 FinalTime=9.016320e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.015320e-04 9.016320e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p8_rise_"
  Transient (
    InitialTime=9.016320e-04 FinalTime=9.016330e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p8_write_"
  Transient (
    InitialTime=9.016330e-04 FinalTime=9.017330e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.016330e-04 9.017330e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p8_fall_"
  Transient (
    InitialTime=9.017330e-04 FinalTime=9.017340e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p8_read_"
  Transient (
    InitialTime=9.017340e-04 FinalTime=9.018340e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.017340e-04 9.018340e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p9_rise_"
  Transient (
    InitialTime=9.018340e-04 FinalTime=9.018350e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p9_write_"
  Transient (
    InitialTime=9.018350e-04 FinalTime=9.019350e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.018350e-04 9.019350e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p9_fall_"
  Transient (
    InitialTime=9.019350e-04 FinalTime=9.019360e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p9_read_"
  Transient (
    InitialTime=9.019360e-04 FinalTime=9.020360e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.019360e-04 9.020360e-04) Intervals=20) ) }
  *--- CYCLE 12 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c12_erase_rise_"
  Transient (
    InitialTime=9.020360e-04 FinalTime=9.020460e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_erase_hold_"
  Transient (
    InitialTime=9.020460e-04 FinalTime=9.120460e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.020460e-04 9.120460e-04) Intervals=40) ) }
  NewCurrentPrefix="c12_erase_fall_"
  Transient (
    InitialTime=9.120460e-04 FinalTime=9.120560e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 12 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c12_relax_"
  Transient (
    InitialTime=9.120560e-04 FinalTime=9.820560e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.120560e-04 9.820560e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 13 (cycle base time = 9.820560e-04)
  *====================================================================
  NewCurrentPrefix="c13_p1_rise_"
  Transient (
    InitialTime=9.820560e-04 FinalTime=9.820570e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p1_write_"
  Transient (
    InitialTime=9.820570e-04 FinalTime=9.821570e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.820570e-04 9.821570e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p1_fall_"
  Transient (
    InitialTime=9.821570e-04 FinalTime=9.821580e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p1_read_"
  Transient (
    InitialTime=9.821580e-04 FinalTime=9.822580e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.821580e-04 9.822580e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p2_rise_"
  Transient (
    InitialTime=9.822580e-04 FinalTime=9.822590e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p2_write_"
  Transient (
    InitialTime=9.822590e-04 FinalTime=9.823590e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.822590e-04 9.823590e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p2_fall_"
  Transient (
    InitialTime=9.823590e-04 FinalTime=9.823600e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p2_read_"
  Transient (
    InitialTime=9.823600e-04 FinalTime=9.824600e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.823600e-04 9.824600e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p3_rise_"
  Transient (
    InitialTime=9.824600e-04 FinalTime=9.824610e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p3_write_"
  Transient (
    InitialTime=9.824610e-04 FinalTime=9.825610e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.824610e-04 9.825610e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p3_fall_"
  Transient (
    InitialTime=9.825610e-04 FinalTime=9.825620e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p3_read_"
  Transient (
    InitialTime=9.825620e-04 FinalTime=9.826620e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.825620e-04 9.826620e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p4_rise_"
  Transient (
    InitialTime=9.826620e-04 FinalTime=9.826630e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p4_write_"
  Transient (
    InitialTime=9.826630e-04 FinalTime=9.827630e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.826630e-04 9.827630e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p4_fall_"
  Transient (
    InitialTime=9.827630e-04 FinalTime=9.827640e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p4_read_"
  Transient (
    InitialTime=9.827640e-04 FinalTime=9.828640e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.827640e-04 9.828640e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p5_rise_"
  Transient (
    InitialTime=9.828640e-04 FinalTime=9.828650e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p5_write_"
  Transient (
    InitialTime=9.828650e-04 FinalTime=9.829650e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.828650e-04 9.829650e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p5_fall_"
  Transient (
    InitialTime=9.829650e-04 FinalTime=9.829660e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p5_read_"
  Transient (
    InitialTime=9.829660e-04 FinalTime=9.830660e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.829660e-04 9.830660e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p6_rise_"
  Transient (
    InitialTime=9.830660e-04 FinalTime=9.830670e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p6_write_"
  Transient (
    InitialTime=9.830670e-04 FinalTime=9.831670e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.830670e-04 9.831670e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p6_fall_"
  Transient (
    InitialTime=9.831670e-04 FinalTime=9.831680e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p6_read_"
  Transient (
    InitialTime=9.831680e-04 FinalTime=9.832680e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.831680e-04 9.832680e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p7_rise_"
  Transient (
    InitialTime=9.832680e-04 FinalTime=9.832690e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p7_write_"
  Transient (
    InitialTime=9.832690e-04 FinalTime=9.833690e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.832690e-04 9.833690e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p7_fall_"
  Transient (
    InitialTime=9.833690e-04 FinalTime=9.833700e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p7_read_"
  Transient (
    InitialTime=9.833700e-04 FinalTime=9.834700e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.833700e-04 9.834700e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p8_rise_"
  Transient (
    InitialTime=9.834700e-04 FinalTime=9.834710e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p8_write_"
  Transient (
    InitialTime=9.834710e-04 FinalTime=9.835710e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.834710e-04 9.835710e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p8_fall_"
  Transient (
    InitialTime=9.835710e-04 FinalTime=9.835720e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p8_read_"
  Transient (
    InitialTime=9.835720e-04 FinalTime=9.836720e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.835720e-04 9.836720e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p9_rise_"
  Transient (
    InitialTime=9.836720e-04 FinalTime=9.836730e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p9_write_"
  Transient (
    InitialTime=9.836730e-04 FinalTime=9.837730e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.836730e-04 9.837730e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p9_fall_"
  Transient (
    InitialTime=9.837730e-04 FinalTime=9.837740e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p9_read_"
  Transient (
    InitialTime=9.837740e-04 FinalTime=9.838740e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.837740e-04 9.838740e-04) Intervals=20) ) }
  *--- CYCLE 13 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c13_erase_rise_"
  Transient (
    InitialTime=9.838740e-04 FinalTime=9.838840e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_erase_hold_"
  Transient (
    InitialTime=9.838840e-04 FinalTime=9.938840e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.838840e-04 9.938840e-04) Intervals=40) ) }
  NewCurrentPrefix="c13_erase_fall_"
  Transient (
    InitialTime=9.938840e-04 FinalTime=9.938940e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 13 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c13_relax_"
  Transient (
    InitialTime=9.938940e-04 FinalTime=1.063894e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.938940e-04 1.063894e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 14 (cycle base time = 1.063894e-03)
  *====================================================================
  NewCurrentPrefix="c14_p1_rise_"
  Transient (
    InitialTime=1.063894e-03 FinalTime=1.063895e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p1_write_"
  Transient (
    InitialTime=1.063895e-03 FinalTime=1.063995e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.063895e-03 1.063995e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p1_fall_"
  Transient (
    InitialTime=1.063995e-03 FinalTime=1.063996e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p1_read_"
  Transient (
    InitialTime=1.063996e-03 FinalTime=1.064096e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.063996e-03 1.064096e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p2_rise_"
  Transient (
    InitialTime=1.064096e-03 FinalTime=1.064097e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p2_write_"
  Transient (
    InitialTime=1.064097e-03 FinalTime=1.064197e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.064097e-03 1.064197e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p2_fall_"
  Transient (
    InitialTime=1.064197e-03 FinalTime=1.064198e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p2_read_"
  Transient (
    InitialTime=1.064198e-03 FinalTime=1.064298e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.064198e-03 1.064298e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p3_rise_"
  Transient (
    InitialTime=1.064298e-03 FinalTime=1.064299e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p3_write_"
  Transient (
    InitialTime=1.064299e-03 FinalTime=1.064399e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.064299e-03 1.064399e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p3_fall_"
  Transient (
    InitialTime=1.064399e-03 FinalTime=1.064400e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p3_read_"
  Transient (
    InitialTime=1.064400e-03 FinalTime=1.064500e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.064400e-03 1.064500e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p4_rise_"
  Transient (
    InitialTime=1.064500e-03 FinalTime=1.064501e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p4_write_"
  Transient (
    InitialTime=1.064501e-03 FinalTime=1.064601e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.064501e-03 1.064601e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p4_fall_"
  Transient (
    InitialTime=1.064601e-03 FinalTime=1.064602e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p4_read_"
  Transient (
    InitialTime=1.064602e-03 FinalTime=1.064702e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.064602e-03 1.064702e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p5_rise_"
  Transient (
    InitialTime=1.064702e-03 FinalTime=1.064703e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p5_write_"
  Transient (
    InitialTime=1.064703e-03 FinalTime=1.064803e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.064703e-03 1.064803e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p5_fall_"
  Transient (
    InitialTime=1.064803e-03 FinalTime=1.064804e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p5_read_"
  Transient (
    InitialTime=1.064804e-03 FinalTime=1.064904e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.064804e-03 1.064904e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p6_rise_"
  Transient (
    InitialTime=1.064904e-03 FinalTime=1.064905e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p6_write_"
  Transient (
    InitialTime=1.064905e-03 FinalTime=1.065005e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.064905e-03 1.065005e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p6_fall_"
  Transient (
    InitialTime=1.065005e-03 FinalTime=1.065006e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p6_read_"
  Transient (
    InitialTime=1.065006e-03 FinalTime=1.065106e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.065006e-03 1.065106e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p7_rise_"
  Transient (
    InitialTime=1.065106e-03 FinalTime=1.065107e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p7_write_"
  Transient (
    InitialTime=1.065107e-03 FinalTime=1.065207e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.065107e-03 1.065207e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p7_fall_"
  Transient (
    InitialTime=1.065207e-03 FinalTime=1.065208e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p7_read_"
  Transient (
    InitialTime=1.065208e-03 FinalTime=1.065308e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.065208e-03 1.065308e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p8_rise_"
  Transient (
    InitialTime=1.065308e-03 FinalTime=1.065309e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p8_write_"
  Transient (
    InitialTime=1.065309e-03 FinalTime=1.065409e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.065309e-03 1.065409e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p8_fall_"
  Transient (
    InitialTime=1.065409e-03 FinalTime=1.065410e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p8_read_"
  Transient (
    InitialTime=1.065410e-03 FinalTime=1.065510e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.065410e-03 1.065510e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p9_rise_"
  Transient (
    InitialTime=1.065510e-03 FinalTime=1.065511e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p9_write_"
  Transient (
    InitialTime=1.065511e-03 FinalTime=1.065611e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.065511e-03 1.065611e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p9_fall_"
  Transient (
    InitialTime=1.065611e-03 FinalTime=1.065612e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p9_read_"
  Transient (
    InitialTime=1.065612e-03 FinalTime=1.065712e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.065612e-03 1.065712e-03) Intervals=20) ) }
  *--- CYCLE 14 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c14_erase_rise_"
  Transient (
    InitialTime=1.065712e-03 FinalTime=1.065722e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_erase_hold_"
  Transient (
    InitialTime=1.065722e-03 FinalTime=1.075722e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.065722e-03 1.075722e-03) Intervals=40) ) }
  NewCurrentPrefix="c14_erase_fall_"
  Transient (
    InitialTime=1.075722e-03 FinalTime=1.075732e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 14 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c14_relax_"
  Transient (
    InitialTime=1.075732e-03 FinalTime=1.145732e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.075732e-03 1.145732e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 15 (cycle base time = 1.145732e-03)
  *====================================================================
  NewCurrentPrefix="c15_p1_rise_"
  Transient (
    InitialTime=1.145732e-03 FinalTime=1.145733e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p1_write_"
  Transient (
    InitialTime=1.145733e-03 FinalTime=1.145833e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.145733e-03 1.145833e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p1_fall_"
  Transient (
    InitialTime=1.145833e-03 FinalTime=1.145834e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p1_read_"
  Transient (
    InitialTime=1.145834e-03 FinalTime=1.145934e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.145834e-03 1.145934e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p2_rise_"
  Transient (
    InitialTime=1.145934e-03 FinalTime=1.145935e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p2_write_"
  Transient (
    InitialTime=1.145935e-03 FinalTime=1.146035e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.145935e-03 1.146035e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p2_fall_"
  Transient (
    InitialTime=1.146035e-03 FinalTime=1.146036e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p2_read_"
  Transient (
    InitialTime=1.146036e-03 FinalTime=1.146136e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146036e-03 1.146136e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p3_rise_"
  Transient (
    InitialTime=1.146136e-03 FinalTime=1.146137e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p3_write_"
  Transient (
    InitialTime=1.146137e-03 FinalTime=1.146237e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146137e-03 1.146237e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p3_fall_"
  Transient (
    InitialTime=1.146237e-03 FinalTime=1.146238e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p3_read_"
  Transient (
    InitialTime=1.146238e-03 FinalTime=1.146338e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146238e-03 1.146338e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p4_rise_"
  Transient (
    InitialTime=1.146338e-03 FinalTime=1.146339e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p4_write_"
  Transient (
    InitialTime=1.146339e-03 FinalTime=1.146439e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146339e-03 1.146439e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p4_fall_"
  Transient (
    InitialTime=1.146439e-03 FinalTime=1.146440e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p4_read_"
  Transient (
    InitialTime=1.146440e-03 FinalTime=1.146540e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146440e-03 1.146540e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p5_rise_"
  Transient (
    InitialTime=1.146540e-03 FinalTime=1.146541e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p5_write_"
  Transient (
    InitialTime=1.146541e-03 FinalTime=1.146641e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146541e-03 1.146641e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p5_fall_"
  Transient (
    InitialTime=1.146641e-03 FinalTime=1.146642e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p5_read_"
  Transient (
    InitialTime=1.146642e-03 FinalTime=1.146742e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146642e-03 1.146742e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p6_rise_"
  Transient (
    InitialTime=1.146742e-03 FinalTime=1.146743e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p6_write_"
  Transient (
    InitialTime=1.146743e-03 FinalTime=1.146843e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146743e-03 1.146843e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p6_fall_"
  Transient (
    InitialTime=1.146843e-03 FinalTime=1.146844e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p6_read_"
  Transient (
    InitialTime=1.146844e-03 FinalTime=1.146944e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146844e-03 1.146944e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p7_rise_"
  Transient (
    InitialTime=1.146944e-03 FinalTime=1.146945e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p7_write_"
  Transient (
    InitialTime=1.146945e-03 FinalTime=1.147045e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.146945e-03 1.147045e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p7_fall_"
  Transient (
    InitialTime=1.147045e-03 FinalTime=1.147046e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p7_read_"
  Transient (
    InitialTime=1.147046e-03 FinalTime=1.147146e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.147046e-03 1.147146e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p8_rise_"
  Transient (
    InitialTime=1.147146e-03 FinalTime=1.147147e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p8_write_"
  Transient (
    InitialTime=1.147147e-03 FinalTime=1.147247e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.147147e-03 1.147247e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p8_fall_"
  Transient (
    InitialTime=1.147247e-03 FinalTime=1.147248e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p8_read_"
  Transient (
    InitialTime=1.147248e-03 FinalTime=1.147348e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.147248e-03 1.147348e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p9_rise_"
  Transient (
    InitialTime=1.147348e-03 FinalTime=1.147349e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p9_write_"
  Transient (
    InitialTime=1.147349e-03 FinalTime=1.147449e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.147349e-03 1.147449e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p9_fall_"
  Transient (
    InitialTime=1.147449e-03 FinalTime=1.147450e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p9_read_"
  Transient (
    InitialTime=1.147450e-03 FinalTime=1.147550e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.147450e-03 1.147550e-03) Intervals=20) ) }
  *--- CYCLE 15 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c15_erase_rise_"
  Transient (
    InitialTime=1.147550e-03 FinalTime=1.147560e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_erase_hold_"
  Transient (
    InitialTime=1.147560e-03 FinalTime=1.157560e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.147560e-03 1.157560e-03) Intervals=40) ) }
  NewCurrentPrefix="c15_erase_fall_"
  Transient (
    InitialTime=1.157560e-03 FinalTime=1.157570e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 15 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c15_relax_"
  Transient (
    InitialTime=1.157570e-03 FinalTime=1.227570e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.157570e-03 1.227570e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 16 (cycle base time = 1.227570e-03)
  *====================================================================
  NewCurrentPrefix="c16_p1_rise_"
  Transient (
    InitialTime=1.227570e-03 FinalTime=1.227571e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p1_write_"
  Transient (
    InitialTime=1.227571e-03 FinalTime=1.227671e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.227571e-03 1.227671e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p1_fall_"
  Transient (
    InitialTime=1.227671e-03 FinalTime=1.227672e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p1_read_"
  Transient (
    InitialTime=1.227672e-03 FinalTime=1.227772e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.227672e-03 1.227772e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p2_rise_"
  Transient (
    InitialTime=1.227772e-03 FinalTime=1.227773e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p2_write_"
  Transient (
    InitialTime=1.227773e-03 FinalTime=1.227873e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.227773e-03 1.227873e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p2_fall_"
  Transient (
    InitialTime=1.227873e-03 FinalTime=1.227874e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p2_read_"
  Transient (
    InitialTime=1.227874e-03 FinalTime=1.227974e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.227874e-03 1.227974e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p3_rise_"
  Transient (
    InitialTime=1.227974e-03 FinalTime=1.227975e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p3_write_"
  Transient (
    InitialTime=1.227975e-03 FinalTime=1.228075e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.227975e-03 1.228075e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p3_fall_"
  Transient (
    InitialTime=1.228075e-03 FinalTime=1.228076e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p3_read_"
  Transient (
    InitialTime=1.228076e-03 FinalTime=1.228176e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228076e-03 1.228176e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p4_rise_"
  Transient (
    InitialTime=1.228176e-03 FinalTime=1.228177e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p4_write_"
  Transient (
    InitialTime=1.228177e-03 FinalTime=1.228277e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228177e-03 1.228277e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p4_fall_"
  Transient (
    InitialTime=1.228277e-03 FinalTime=1.228278e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p4_read_"
  Transient (
    InitialTime=1.228278e-03 FinalTime=1.228378e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228278e-03 1.228378e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p5_rise_"
  Transient (
    InitialTime=1.228378e-03 FinalTime=1.228379e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p5_write_"
  Transient (
    InitialTime=1.228379e-03 FinalTime=1.228479e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228379e-03 1.228479e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p5_fall_"
  Transient (
    InitialTime=1.228479e-03 FinalTime=1.228480e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p5_read_"
  Transient (
    InitialTime=1.228480e-03 FinalTime=1.228580e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228480e-03 1.228580e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p6_rise_"
  Transient (
    InitialTime=1.228580e-03 FinalTime=1.228581e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p6_write_"
  Transient (
    InitialTime=1.228581e-03 FinalTime=1.228681e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228581e-03 1.228681e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p6_fall_"
  Transient (
    InitialTime=1.228681e-03 FinalTime=1.228682e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p6_read_"
  Transient (
    InitialTime=1.228682e-03 FinalTime=1.228782e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228682e-03 1.228782e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p7_rise_"
  Transient (
    InitialTime=1.228782e-03 FinalTime=1.228783e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p7_write_"
  Transient (
    InitialTime=1.228783e-03 FinalTime=1.228883e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228783e-03 1.228883e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p7_fall_"
  Transient (
    InitialTime=1.228883e-03 FinalTime=1.228884e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p7_read_"
  Transient (
    InitialTime=1.228884e-03 FinalTime=1.228984e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228884e-03 1.228984e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p8_rise_"
  Transient (
    InitialTime=1.228984e-03 FinalTime=1.228985e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p8_write_"
  Transient (
    InitialTime=1.228985e-03 FinalTime=1.229085e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.228985e-03 1.229085e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p8_fall_"
  Transient (
    InitialTime=1.229085e-03 FinalTime=1.229086e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p8_read_"
  Transient (
    InitialTime=1.229086e-03 FinalTime=1.229186e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.229086e-03 1.229186e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p9_rise_"
  Transient (
    InitialTime=1.229186e-03 FinalTime=1.229187e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p9_write_"
  Transient (
    InitialTime=1.229187e-03 FinalTime=1.229287e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.229187e-03 1.229287e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p9_fall_"
  Transient (
    InitialTime=1.229287e-03 FinalTime=1.229288e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p9_read_"
  Transient (
    InitialTime=1.229288e-03 FinalTime=1.229388e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.229288e-03 1.229388e-03) Intervals=20) ) }
  *--- CYCLE 16 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c16_erase_rise_"
  Transient (
    InitialTime=1.229388e-03 FinalTime=1.229398e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_erase_hold_"
  Transient (
    InitialTime=1.229398e-03 FinalTime=1.239398e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.229398e-03 1.239398e-03) Intervals=40) ) }
  NewCurrentPrefix="c16_erase_fall_"
  Transient (
    InitialTime=1.239398e-03 FinalTime=1.239408e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 16 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c16_relax_"
  Transient (
    InitialTime=1.239408e-03 FinalTime=1.309408e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.239408e-03 1.309408e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 17 (cycle base time = 1.309408e-03)
  *====================================================================
  NewCurrentPrefix="c17_p1_rise_"
  Transient (
    InitialTime=1.309408e-03 FinalTime=1.309409e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p1_write_"
  Transient (
    InitialTime=1.309409e-03 FinalTime=1.309509e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.309409e-03 1.309509e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p1_fall_"
  Transient (
    InitialTime=1.309509e-03 FinalTime=1.309510e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p1_read_"
  Transient (
    InitialTime=1.309510e-03 FinalTime=1.309610e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.309510e-03 1.309610e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p2_rise_"
  Transient (
    InitialTime=1.309610e-03 FinalTime=1.309611e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p2_write_"
  Transient (
    InitialTime=1.309611e-03 FinalTime=1.309711e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.309611e-03 1.309711e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p2_fall_"
  Transient (
    InitialTime=1.309711e-03 FinalTime=1.309712e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p2_read_"
  Transient (
    InitialTime=1.309712e-03 FinalTime=1.309812e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.309712e-03 1.309812e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p3_rise_"
  Transient (
    InitialTime=1.309812e-03 FinalTime=1.309813e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p3_write_"
  Transient (
    InitialTime=1.309813e-03 FinalTime=1.309913e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.309813e-03 1.309913e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p3_fall_"
  Transient (
    InitialTime=1.309913e-03 FinalTime=1.309914e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p3_read_"
  Transient (
    InitialTime=1.309914e-03 FinalTime=1.310014e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.309914e-03 1.310014e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p4_rise_"
  Transient (
    InitialTime=1.310014e-03 FinalTime=1.310015e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p4_write_"
  Transient (
    InitialTime=1.310015e-03 FinalTime=1.310115e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310015e-03 1.310115e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p4_fall_"
  Transient (
    InitialTime=1.310115e-03 FinalTime=1.310116e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p4_read_"
  Transient (
    InitialTime=1.310116e-03 FinalTime=1.310216e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310116e-03 1.310216e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p5_rise_"
  Transient (
    InitialTime=1.310216e-03 FinalTime=1.310217e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p5_write_"
  Transient (
    InitialTime=1.310217e-03 FinalTime=1.310317e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310217e-03 1.310317e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p5_fall_"
  Transient (
    InitialTime=1.310317e-03 FinalTime=1.310318e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p5_read_"
  Transient (
    InitialTime=1.310318e-03 FinalTime=1.310418e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310318e-03 1.310418e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p6_rise_"
  Transient (
    InitialTime=1.310418e-03 FinalTime=1.310419e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p6_write_"
  Transient (
    InitialTime=1.310419e-03 FinalTime=1.310519e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310419e-03 1.310519e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p6_fall_"
  Transient (
    InitialTime=1.310519e-03 FinalTime=1.310520e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p6_read_"
  Transient (
    InitialTime=1.310520e-03 FinalTime=1.310620e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310520e-03 1.310620e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p7_rise_"
  Transient (
    InitialTime=1.310620e-03 FinalTime=1.310621e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p7_write_"
  Transient (
    InitialTime=1.310621e-03 FinalTime=1.310721e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310621e-03 1.310721e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p7_fall_"
  Transient (
    InitialTime=1.310721e-03 FinalTime=1.310722e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p7_read_"
  Transient (
    InitialTime=1.310722e-03 FinalTime=1.310822e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310722e-03 1.310822e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p8_rise_"
  Transient (
    InitialTime=1.310822e-03 FinalTime=1.310823e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p8_write_"
  Transient (
    InitialTime=1.310823e-03 FinalTime=1.310923e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310823e-03 1.310923e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p8_fall_"
  Transient (
    InitialTime=1.310923e-03 FinalTime=1.310924e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p8_read_"
  Transient (
    InitialTime=1.310924e-03 FinalTime=1.311024e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.310924e-03 1.311024e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p9_rise_"
  Transient (
    InitialTime=1.311024e-03 FinalTime=1.311025e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p9_write_"
  Transient (
    InitialTime=1.311025e-03 FinalTime=1.311125e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.311025e-03 1.311125e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p9_fall_"
  Transient (
    InitialTime=1.311125e-03 FinalTime=1.311126e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p9_read_"
  Transient (
    InitialTime=1.311126e-03 FinalTime=1.311226e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.311126e-03 1.311226e-03) Intervals=20) ) }
  *--- CYCLE 17 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c17_erase_rise_"
  Transient (
    InitialTime=1.311226e-03 FinalTime=1.311236e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_erase_hold_"
  Transient (
    InitialTime=1.311236e-03 FinalTime=1.321236e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.311236e-03 1.321236e-03) Intervals=40) ) }
  NewCurrentPrefix="c17_erase_fall_"
  Transient (
    InitialTime=1.321236e-03 FinalTime=1.321246e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 17 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c17_relax_"
  Transient (
    InitialTime=1.321246e-03 FinalTime=1.391246e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.321246e-03 1.391246e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 18 (cycle base time = 1.391246e-03)
  *====================================================================
  NewCurrentPrefix="c18_p1_rise_"
  Transient (
    InitialTime=1.391246e-03 FinalTime=1.391247e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p1_write_"
  Transient (
    InitialTime=1.391247e-03 FinalTime=1.391347e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.391247e-03 1.391347e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p1_fall_"
  Transient (
    InitialTime=1.391347e-03 FinalTime=1.391348e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p1_read_"
  Transient (
    InitialTime=1.391348e-03 FinalTime=1.391448e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.391348e-03 1.391448e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p2_rise_"
  Transient (
    InitialTime=1.391448e-03 FinalTime=1.391449e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p2_write_"
  Transient (
    InitialTime=1.391449e-03 FinalTime=1.391549e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.391449e-03 1.391549e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p2_fall_"
  Transient (
    InitialTime=1.391549e-03 FinalTime=1.391550e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p2_read_"
  Transient (
    InitialTime=1.391550e-03 FinalTime=1.391650e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.391550e-03 1.391650e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p3_rise_"
  Transient (
    InitialTime=1.391650e-03 FinalTime=1.391651e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p3_write_"
  Transient (
    InitialTime=1.391651e-03 FinalTime=1.391751e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.391651e-03 1.391751e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p3_fall_"
  Transient (
    InitialTime=1.391751e-03 FinalTime=1.391752e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p3_read_"
  Transient (
    InitialTime=1.391752e-03 FinalTime=1.391852e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.391752e-03 1.391852e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p4_rise_"
  Transient (
    InitialTime=1.391852e-03 FinalTime=1.391853e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p4_write_"
  Transient (
    InitialTime=1.391853e-03 FinalTime=1.391953e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.391853e-03 1.391953e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p4_fall_"
  Transient (
    InitialTime=1.391953e-03 FinalTime=1.391954e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p4_read_"
  Transient (
    InitialTime=1.391954e-03 FinalTime=1.392054e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.391954e-03 1.392054e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p5_rise_"
  Transient (
    InitialTime=1.392054e-03 FinalTime=1.392055e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p5_write_"
  Transient (
    InitialTime=1.392055e-03 FinalTime=1.392155e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392055e-03 1.392155e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p5_fall_"
  Transient (
    InitialTime=1.392155e-03 FinalTime=1.392156e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p5_read_"
  Transient (
    InitialTime=1.392156e-03 FinalTime=1.392256e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392156e-03 1.392256e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p6_rise_"
  Transient (
    InitialTime=1.392256e-03 FinalTime=1.392257e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p6_write_"
  Transient (
    InitialTime=1.392257e-03 FinalTime=1.392357e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392257e-03 1.392357e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p6_fall_"
  Transient (
    InitialTime=1.392357e-03 FinalTime=1.392358e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p6_read_"
  Transient (
    InitialTime=1.392358e-03 FinalTime=1.392458e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392358e-03 1.392458e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p7_rise_"
  Transient (
    InitialTime=1.392458e-03 FinalTime=1.392459e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p7_write_"
  Transient (
    InitialTime=1.392459e-03 FinalTime=1.392559e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392459e-03 1.392559e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p7_fall_"
  Transient (
    InitialTime=1.392559e-03 FinalTime=1.392560e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p7_read_"
  Transient (
    InitialTime=1.392560e-03 FinalTime=1.392660e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392560e-03 1.392660e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p8_rise_"
  Transient (
    InitialTime=1.392660e-03 FinalTime=1.392661e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p8_write_"
  Transient (
    InitialTime=1.392661e-03 FinalTime=1.392761e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392661e-03 1.392761e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p8_fall_"
  Transient (
    InitialTime=1.392761e-03 FinalTime=1.392762e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p8_read_"
  Transient (
    InitialTime=1.392762e-03 FinalTime=1.392862e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392762e-03 1.392862e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p9_rise_"
  Transient (
    InitialTime=1.392862e-03 FinalTime=1.392863e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p9_write_"
  Transient (
    InitialTime=1.392863e-03 FinalTime=1.392963e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392863e-03 1.392963e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p9_fall_"
  Transient (
    InitialTime=1.392963e-03 FinalTime=1.392964e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p9_read_"
  Transient (
    InitialTime=1.392964e-03 FinalTime=1.393064e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.392964e-03 1.393064e-03) Intervals=20) ) }
  *--- CYCLE 18 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c18_erase_rise_"
  Transient (
    InitialTime=1.393064e-03 FinalTime=1.393074e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_erase_hold_"
  Transient (
    InitialTime=1.393074e-03 FinalTime=1.403074e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.393074e-03 1.403074e-03) Intervals=40) ) }
  NewCurrentPrefix="c18_erase_fall_"
  Transient (
    InitialTime=1.403074e-03 FinalTime=1.403084e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 18 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c18_relax_"
  Transient (
    InitialTime=1.403084e-03 FinalTime=1.473084e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.403084e-03 1.473084e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 19 (cycle base time = 1.473084e-03)
  *====================================================================
  NewCurrentPrefix="c19_p1_rise_"
  Transient (
    InitialTime=1.473084e-03 FinalTime=1.473085e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p1_write_"
  Transient (
    InitialTime=1.473085e-03 FinalTime=1.473185e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473085e-03 1.473185e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p1_fall_"
  Transient (
    InitialTime=1.473185e-03 FinalTime=1.473186e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p1_read_"
  Transient (
    InitialTime=1.473186e-03 FinalTime=1.473286e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473186e-03 1.473286e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p2_rise_"
  Transient (
    InitialTime=1.473286e-03 FinalTime=1.473287e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p2_write_"
  Transient (
    InitialTime=1.473287e-03 FinalTime=1.473387e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473287e-03 1.473387e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p2_fall_"
  Transient (
    InitialTime=1.473387e-03 FinalTime=1.473388e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p2_read_"
  Transient (
    InitialTime=1.473388e-03 FinalTime=1.473488e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473388e-03 1.473488e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p3_rise_"
  Transient (
    InitialTime=1.473488e-03 FinalTime=1.473489e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p3_write_"
  Transient (
    InitialTime=1.473489e-03 FinalTime=1.473589e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473489e-03 1.473589e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p3_fall_"
  Transient (
    InitialTime=1.473589e-03 FinalTime=1.473590e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p3_read_"
  Transient (
    InitialTime=1.473590e-03 FinalTime=1.473690e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473590e-03 1.473690e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p4_rise_"
  Transient (
    InitialTime=1.473690e-03 FinalTime=1.473691e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p4_write_"
  Transient (
    InitialTime=1.473691e-03 FinalTime=1.473791e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473691e-03 1.473791e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p4_fall_"
  Transient (
    InitialTime=1.473791e-03 FinalTime=1.473792e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p4_read_"
  Transient (
    InitialTime=1.473792e-03 FinalTime=1.473892e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473792e-03 1.473892e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p5_rise_"
  Transient (
    InitialTime=1.473892e-03 FinalTime=1.473893e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p5_write_"
  Transient (
    InitialTime=1.473893e-03 FinalTime=1.473993e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473893e-03 1.473993e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p5_fall_"
  Transient (
    InitialTime=1.473993e-03 FinalTime=1.473994e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p5_read_"
  Transient (
    InitialTime=1.473994e-03 FinalTime=1.474094e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.473994e-03 1.474094e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p6_rise_"
  Transient (
    InitialTime=1.474094e-03 FinalTime=1.474095e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p6_write_"
  Transient (
    InitialTime=1.474095e-03 FinalTime=1.474195e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.474095e-03 1.474195e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p6_fall_"
  Transient (
    InitialTime=1.474195e-03 FinalTime=1.474196e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p6_read_"
  Transient (
    InitialTime=1.474196e-03 FinalTime=1.474296e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.474196e-03 1.474296e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p7_rise_"
  Transient (
    InitialTime=1.474296e-03 FinalTime=1.474297e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p7_write_"
  Transient (
    InitialTime=1.474297e-03 FinalTime=1.474397e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.474297e-03 1.474397e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p7_fall_"
  Transient (
    InitialTime=1.474397e-03 FinalTime=1.474398e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p7_read_"
  Transient (
    InitialTime=1.474398e-03 FinalTime=1.474498e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.474398e-03 1.474498e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p8_rise_"
  Transient (
    InitialTime=1.474498e-03 FinalTime=1.474499e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p8_write_"
  Transient (
    InitialTime=1.474499e-03 FinalTime=1.474599e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.474499e-03 1.474599e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p8_fall_"
  Transient (
    InitialTime=1.474599e-03 FinalTime=1.474600e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p8_read_"
  Transient (
    InitialTime=1.474600e-03 FinalTime=1.474700e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.474600e-03 1.474700e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p9_rise_"
  Transient (
    InitialTime=1.474700e-03 FinalTime=1.474701e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p9_write_"
  Transient (
    InitialTime=1.474701e-03 FinalTime=1.474801e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.474701e-03 1.474801e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p9_fall_"
  Transient (
    InitialTime=1.474801e-03 FinalTime=1.474802e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p9_read_"
  Transient (
    InitialTime=1.474802e-03 FinalTime=1.474902e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.474802e-03 1.474902e-03) Intervals=20) ) }
  *--- CYCLE 19 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c19_erase_rise_"
  Transient (
    InitialTime=1.474902e-03 FinalTime=1.474912e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_erase_hold_"
  Transient (
    InitialTime=1.474912e-03 FinalTime=1.484912e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.474912e-03 1.484912e-03) Intervals=40) ) }
  NewCurrentPrefix="c19_erase_fall_"
  Transient (
    InitialTime=1.484912e-03 FinalTime=1.484922e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 19 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c19_relax_"
  Transient (
    InitialTime=1.484922e-03 FinalTime=1.554922e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.484922e-03 1.554922e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 20 (cycle base time = 1.554922e-03)
  *====================================================================
  NewCurrentPrefix="c20_p1_rise_"
  Transient (
    InitialTime=1.554922e-03 FinalTime=1.554923e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p1_write_"
  Transient (
    InitialTime=1.554923e-03 FinalTime=1.555023e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.554923e-03 1.555023e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p1_fall_"
  Transient (
    InitialTime=1.555023e-03 FinalTime=1.555024e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p1_read_"
  Transient (
    InitialTime=1.555024e-03 FinalTime=1.555124e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555024e-03 1.555124e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p2_rise_"
  Transient (
    InitialTime=1.555124e-03 FinalTime=1.555125e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p2_write_"
  Transient (
    InitialTime=1.555125e-03 FinalTime=1.555225e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555125e-03 1.555225e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p2_fall_"
  Transient (
    InitialTime=1.555225e-03 FinalTime=1.555226e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p2_read_"
  Transient (
    InitialTime=1.555226e-03 FinalTime=1.555326e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555226e-03 1.555326e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p3_rise_"
  Transient (
    InitialTime=1.555326e-03 FinalTime=1.555327e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p3_write_"
  Transient (
    InitialTime=1.555327e-03 FinalTime=1.555427e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555327e-03 1.555427e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p3_fall_"
  Transient (
    InitialTime=1.555427e-03 FinalTime=1.555428e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p3_read_"
  Transient (
    InitialTime=1.555428e-03 FinalTime=1.555528e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555428e-03 1.555528e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p4_rise_"
  Transient (
    InitialTime=1.555528e-03 FinalTime=1.555529e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p4_write_"
  Transient (
    InitialTime=1.555529e-03 FinalTime=1.555629e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555529e-03 1.555629e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p4_fall_"
  Transient (
    InitialTime=1.555629e-03 FinalTime=1.555630e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p4_read_"
  Transient (
    InitialTime=1.555630e-03 FinalTime=1.555730e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555630e-03 1.555730e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p5_rise_"
  Transient (
    InitialTime=1.555730e-03 FinalTime=1.555731e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p5_write_"
  Transient (
    InitialTime=1.555731e-03 FinalTime=1.555831e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555731e-03 1.555831e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p5_fall_"
  Transient (
    InitialTime=1.555831e-03 FinalTime=1.555832e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p5_read_"
  Transient (
    InitialTime=1.555832e-03 FinalTime=1.555932e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555832e-03 1.555932e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p6_rise_"
  Transient (
    InitialTime=1.555932e-03 FinalTime=1.555933e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p6_write_"
  Transient (
    InitialTime=1.555933e-03 FinalTime=1.556033e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.555933e-03 1.556033e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p6_fall_"
  Transient (
    InitialTime=1.556033e-03 FinalTime=1.556034e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p6_read_"
  Transient (
    InitialTime=1.556034e-03 FinalTime=1.556134e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.556034e-03 1.556134e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p7_rise_"
  Transient (
    InitialTime=1.556134e-03 FinalTime=1.556135e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p7_write_"
  Transient (
    InitialTime=1.556135e-03 FinalTime=1.556235e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.556135e-03 1.556235e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p7_fall_"
  Transient (
    InitialTime=1.556235e-03 FinalTime=1.556236e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p7_read_"
  Transient (
    InitialTime=1.556236e-03 FinalTime=1.556336e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.556236e-03 1.556336e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p8_rise_"
  Transient (
    InitialTime=1.556336e-03 FinalTime=1.556337e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p8_write_"
  Transient (
    InitialTime=1.556337e-03 FinalTime=1.556437e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.556337e-03 1.556437e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p8_fall_"
  Transient (
    InitialTime=1.556437e-03 FinalTime=1.556438e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p8_read_"
  Transient (
    InitialTime=1.556438e-03 FinalTime=1.556538e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.556438e-03 1.556538e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p9_rise_"
  Transient (
    InitialTime=1.556538e-03 FinalTime=1.556539e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 1.95 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p9_write_"
  Transient (
    InitialTime=1.556539e-03 FinalTime=1.556639e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.556539e-03 1.556639e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p9_fall_"
  Transient (
    InitialTime=1.556639e-03 FinalTime=1.556640e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p9_read_"
  Transient (
    InitialTime=1.556640e-03 FinalTime=1.556740e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.556640e-03 1.556740e-03) Intervals=20) ) }
  *--- CYCLE 20 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c20_erase_rise_"
  Transient (
    InitialTime=1.556740e-03 FinalTime=1.556750e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_erase_hold_"
  Transient (
    InitialTime=1.556750e-03 FinalTime=1.566750e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.556750e-03 1.566750e-03) Intervals=40) ) }
  NewCurrentPrefix="c20_erase_fall_"
  Transient (
    InitialTime=1.566750e-03 FinalTime=1.566760e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 20 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c20_relax_"
  Transient (
    InitialTime=1.566760e-03 FinalTime=1.636760e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.566760e-03 1.636760e-03) Intervals=70) ) }

}

*===================================================================
*== SWB SETUP (set in SWB project, not in this file):
*==   Parameter:  V_pgm
*==   Sweep (L5): 1.95  1.975  2.0  2.025  2.05    V
*==
*== POST-PROCESSING (Simulations/analyze_phase1d_cyclic.py, H4 update):
*==   Per node:
*==     1. ID_pre_cN, ID_p9_cN, fire_ratio_cN, ID_end_relax_cN for N=1..20
*==     2. drift_c10->c20 on ID_p9 and on ID_end_relax (long-tail M1, M-rest)
*==     3. Monotonicity check pulses 2..9 every cycle
*==   Across nodes:
*==     4. sigma(fire_ratio_cN) / mean(fire_ratio_cN) for c10..c20  -> M8
*==
*== Endurance run wall-clock estimate (Step 3b ran ~25 min/node @ 5 cycles):
*==   ~100 min/node @ 20 cycles  *  5 nodes  =  ~8.5 hours total
*===================================================================
