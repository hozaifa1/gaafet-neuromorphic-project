*===================================================================
*== PHASE 1D - H6 DEFERRED-READ LIF ENDURANCE
*==
*== Cuts the inline 100 ns sub-V_t read after pulses 1..8 of each
*== fire burst.  One 100 ns burst_read after p9, then erase + relax.
*== Expected per-pulse-equivalent energy ~15-25 fJ (was 128 fJ).
*==
*== Per cycle = 81.038 us  |  Total 20 cycles = 1620.760 us
*== SWB sweep: 2.000 in {1.95, 1.975, 2.0, 2.025, 2.05} V
*===================================================================

File {
    Grid       = "n1_msh.tdr"
    Parameter  = "sdevice_gaafet_lif.par"
    Plot       = "h6_outputs/h6_vpgm2.000_des.tdr"
    Current    = "h6_outputs/h6_vpgm2.000_des.plt"
    Output     = "h6_outputs/h6_vpgm2.000_des.log"
}

Electrode {
  { Name="source_contact"  Voltage= 0.0 }
  { Name="drain_contact"   Voltage= 0.0 }
  { Name="gate_contact"    Voltage= 0.0  Workfunction=4.35 }
}

Physics {
  Temperature= 300.0
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
    InitialTime=0.000000e+00 FinalTime=1.000000e+00
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

  *=== STEP 3: BASELINE READ (pre-cycle 1, 100 ns) ===
  NewCurrentPrefix="baseline_pre_"
  Transient (
    InitialTime=-1.000000e-07 FinalTime=0.000000e+00
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(-1.0000e-07 0.0) Intervals=20) )
  }

  *====================================================================
  *== CYCLE 1 (cycle base time = 0.0000e+00)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c1_p1_rise_"
  Transient (
    InitialTime=0.000000e+00 FinalTime=1.000000e-09
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p1_write_"
  Transient (
    InitialTime=1.000000e-09 FinalTime=1.010000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0000e-09 1.0100e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p1_fall_"
  Transient (
    InitialTime=1.010000e-07 FinalTime=1.020000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p2_rise_"
  Transient (
    InitialTime=1.020000e-07 FinalTime=1.030000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p2_write_"
  Transient (
    InitialTime=1.030000e-07 FinalTime=2.030000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0300e-07 2.0300e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p2_fall_"
  Transient (
    InitialTime=2.030000e-07 FinalTime=2.040000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p3_rise_"
  Transient (
    InitialTime=2.040000e-07 FinalTime=2.050000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p3_write_"
  Transient (
    InitialTime=2.050000e-07 FinalTime=3.050000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0500e-07 3.0500e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p3_fall_"
  Transient (
    InitialTime=3.050000e-07 FinalTime=3.060000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p4_rise_"
  Transient (
    InitialTime=3.060000e-07 FinalTime=3.070000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p4_write_"
  Transient (
    InitialTime=3.070000e-07 FinalTime=4.070000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0700e-07 4.0700e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p4_fall_"
  Transient (
    InitialTime=4.070000e-07 FinalTime=4.080000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p5_rise_"
  Transient (
    InitialTime=4.080000e-07 FinalTime=4.090000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p5_write_"
  Transient (
    InitialTime=4.090000e-07 FinalTime=5.090000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0900e-07 5.0900e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p5_fall_"
  Transient (
    InitialTime=5.090000e-07 FinalTime=5.100000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p6_rise_"
  Transient (
    InitialTime=5.100000e-07 FinalTime=5.110000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p6_write_"
  Transient (
    InitialTime=5.110000e-07 FinalTime=6.110000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.1100e-07 6.1100e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p6_fall_"
  Transient (
    InitialTime=6.110000e-07 FinalTime=6.120000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p7_rise_"
  Transient (
    InitialTime=6.120000e-07 FinalTime=6.130000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p7_write_"
  Transient (
    InitialTime=6.130000e-07 FinalTime=7.130000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.1300e-07 7.1300e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p7_fall_"
  Transient (
    InitialTime=7.130000e-07 FinalTime=7.140000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p8_rise_"
  Transient (
    InitialTime=7.140000e-07 FinalTime=7.150000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p8_write_"
  Transient (
    InitialTime=7.150000e-07 FinalTime=8.150000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.1500e-07 8.1500e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p8_fall_"
  Transient (
    InitialTime=8.150000e-07 FinalTime=8.160000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p9_rise_"
  Transient (
    InitialTime=8.160000e-07 FinalTime=8.170000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p9_write_"
  Transient (
    InitialTime=8.170000e-07 FinalTime=9.170000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1700e-07 9.1700e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p9_fall_"
  Transient (
    InitialTime=9.170000e-07 FinalTime=9.180000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_burst_read_"
  Transient (
    InitialTime=9.180000e-07 FinalTime=1.018000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1800e-07 1.0180e-06) Intervals=20) ) }
  *--- CYCLE 1 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c1_erase_rise_"
  Transient (
    InitialTime=1.018000e-06 FinalTime=1.028000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_erase_hold_"
  Transient (
    InitialTime=1.028000e-06 FinalTime=1.102800e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0280e-06 1.1028e-05) Intervals=40) ) }
  NewCurrentPrefix="c1_erase_fall_"
  Transient (
    InitialTime=1.102800e-05 FinalTime=1.103800e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 1 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c1_relax_"
  Transient (
    InitialTime=1.103800e-05 FinalTime=8.103800e-05
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1038e-05 8.1038e-05) Intervals=70) ) }

  *====================================================================
  *== CYCLE 2 (cycle base time = 8.1038e-05)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c2_p1_rise_"
  Transient (
    InitialTime=8.103800e-05 FinalTime=8.103900e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_write_"
  Transient (
    InitialTime=8.103900e-05 FinalTime=8.113900e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1039e-05 8.1139e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p1_fall_"
  Transient (
    InitialTime=8.113900e-05 FinalTime=8.114000e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_rise_"
  Transient (
    InitialTime=8.114000e-05 FinalTime=8.114100e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_write_"
  Transient (
    InitialTime=8.114100e-05 FinalTime=8.124100e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1141e-05 8.1241e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p2_fall_"
  Transient (
    InitialTime=8.124100e-05 FinalTime=8.124200e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_rise_"
  Transient (
    InitialTime=8.124200e-05 FinalTime=8.124300e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_write_"
  Transient (
    InitialTime=8.124300e-05 FinalTime=8.134300e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1243e-05 8.1343e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p3_fall_"
  Transient (
    InitialTime=8.134300e-05 FinalTime=8.134400e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p4_rise_"
  Transient (
    InitialTime=8.134400e-05 FinalTime=8.134500e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p4_write_"
  Transient (
    InitialTime=8.134500e-05 FinalTime=8.144500e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1345e-05 8.1445e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p4_fall_"
  Transient (
    InitialTime=8.144500e-05 FinalTime=8.144600e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p5_rise_"
  Transient (
    InitialTime=8.144600e-05 FinalTime=8.144700e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p5_write_"
  Transient (
    InitialTime=8.144700e-05 FinalTime=8.154700e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1447e-05 8.1547e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p5_fall_"
  Transient (
    InitialTime=8.154700e-05 FinalTime=8.154800e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p6_rise_"
  Transient (
    InitialTime=8.154800e-05 FinalTime=8.154900e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p6_write_"
  Transient (
    InitialTime=8.154900e-05 FinalTime=8.164900e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1549e-05 8.1649e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p6_fall_"
  Transient (
    InitialTime=8.164900e-05 FinalTime=8.165000e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p7_rise_"
  Transient (
    InitialTime=8.165000e-05 FinalTime=8.165100e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p7_write_"
  Transient (
    InitialTime=8.165100e-05 FinalTime=8.175100e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1651e-05 8.1751e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p7_fall_"
  Transient (
    InitialTime=8.175100e-05 FinalTime=8.175200e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p8_rise_"
  Transient (
    InitialTime=8.175200e-05 FinalTime=8.175300e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p8_write_"
  Transient (
    InitialTime=8.175300e-05 FinalTime=8.185300e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1753e-05 8.1853e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p8_fall_"
  Transient (
    InitialTime=8.185300e-05 FinalTime=8.185400e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p9_rise_"
  Transient (
    InitialTime=8.185400e-05 FinalTime=8.185500e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p9_write_"
  Transient (
    InitialTime=8.185500e-05 FinalTime=8.195500e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1855e-05 8.1955e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p9_fall_"
  Transient (
    InitialTime=8.195500e-05 FinalTime=8.195600e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_burst_read_"
  Transient (
    InitialTime=8.195600e-05 FinalTime=8.205600e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1956e-05 8.2056e-05) Intervals=20) ) }
  *--- CYCLE 2 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c2_erase_rise_"
  Transient (
    InitialTime=8.205600e-05 FinalTime=8.206600e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_erase_hold_"
  Transient (
    InitialTime=8.206600e-05 FinalTime=9.206600e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2066e-05 9.2066e-05) Intervals=40) ) }
  NewCurrentPrefix="c2_erase_fall_"
  Transient (
    InitialTime=9.206600e-05 FinalTime=9.207600e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 2 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c2_relax_"
  Transient (
    InitialTime=9.207600e-05 FinalTime=1.620800e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.2076e-05 1.6208e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 3 (cycle base time = 1.6208e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c3_p1_rise_"
  Transient (
    InitialTime=1.620800e-04 FinalTime=1.620810e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_write_"
  Transient (
    InitialTime=1.620810e-04 FinalTime=1.621810e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6208e-04 1.6218e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p1_fall_"
  Transient (
    InitialTime=1.621810e-04 FinalTime=1.621820e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_rise_"
  Transient (
    InitialTime=1.621820e-04 FinalTime=1.621830e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_write_"
  Transient (
    InitialTime=1.621830e-04 FinalTime=1.622830e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6218e-04 1.6228e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p2_fall_"
  Transient (
    InitialTime=1.622830e-04 FinalTime=1.622840e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_rise_"
  Transient (
    InitialTime=1.622840e-04 FinalTime=1.622850e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_write_"
  Transient (
    InitialTime=1.622850e-04 FinalTime=1.623850e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6228e-04 1.6238e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p3_fall_"
  Transient (
    InitialTime=1.623850e-04 FinalTime=1.623860e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p4_rise_"
  Transient (
    InitialTime=1.623860e-04 FinalTime=1.623870e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p4_write_"
  Transient (
    InitialTime=1.623870e-04 FinalTime=1.624870e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6238e-04 1.6248e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p4_fall_"
  Transient (
    InitialTime=1.624870e-04 FinalTime=1.624880e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p5_rise_"
  Transient (
    InitialTime=1.624880e-04 FinalTime=1.624890e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p5_write_"
  Transient (
    InitialTime=1.624890e-04 FinalTime=1.625890e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6248e-04 1.6258e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p5_fall_"
  Transient (
    InitialTime=1.625890e-04 FinalTime=1.625990e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p6_rise_"
  Transient (
    InitialTime=1.625990e-04 FinalTime=1.626000e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p6_write_"
  Transient (
    InitialTime=1.626000e-04 FinalTime=1.627000e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6259e-04 1.6269e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p6_fall_"
  Transient (
    InitialTime=1.627000e-04 FinalTime=1.627010e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p7_rise_"
  Transient (
    InitialTime=1.627010e-04 FinalTime=1.627020e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p7_write_"
  Transient (
    InitialTime=1.627020e-04 FinalTime=1.628020e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6269e-04 1.6279e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p7_fall_"
  Transient (
    InitialTime=1.628020e-04 FinalTime=1.628030e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p8_rise_"
  Transient (
    InitialTime=1.628030e-04 FinalTime=1.628040e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p8_write_"
  Transient (
    InitialTime=1.628040e-04 FinalTime=1.629040e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6279e-04 1.6289e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p8_fall_"
  Transient (
    InitialTime=1.629040e-04 FinalTime=1.629050e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p9_rise_"
  Transient (
    InitialTime=1.629050e-04 FinalTime=1.629060e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p9_write_"
  Transient (
    InitialTime=1.629060e-04 FinalTime=1.630060e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6289e-04 1.6299e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p9_fall_"
  Transient (
    InitialTime=1.630060e-04 FinalTime=1.630070e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_burst_read_"
  Transient (
    InitialTime=1.630070e-04 FinalTime=1.631070e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6299e-04 1.6309e-04) Intervals=20) ) }
  *--- CYCLE 3 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c3_erase_rise_"
  Transient (
    InitialTime=1.631070e-04 FinalTime=1.631170e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_erase_hold_"
  Transient (
    InitialTime=1.631170e-04 FinalTime=1.731170e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6310e-04 1.7310e-04) Intervals=40) ) }
  NewCurrentPrefix="c3_erase_fall_"
  Transient (
    InitialTime=1.731170e-04 FinalTime=1.731270e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 3 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c3_relax_"
  Transient (
    InitialTime=1.731270e-04 FinalTime=2.431270e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7311e-04 2.4311e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 4 (cycle base time = 2.4311e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c4_p1_rise_"
  Transient (
    InitialTime=2.431270e-04 FinalTime=2.431280e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p1_write_"
  Transient (
    InitialTime=2.431280e-04 FinalTime=2.432280e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4311e-04 2.4321e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p1_fall_"
  Transient (
    InitialTime=2.432280e-04 FinalTime=2.432380e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_rise_"
  Transient (
    InitialTime=2.432380e-04 FinalTime=2.432390e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_write_"
  Transient (
    InitialTime=2.432390e-04 FinalTime=2.433390e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4322e-04 2.4332e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p2_fall_"
  Transient (
    InitialTime=2.433390e-04 FinalTime=2.433400e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_rise_"
  Transient (
    InitialTime=2.433400e-04 FinalTime=2.433410e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_write_"
  Transient (
    InitialTime=2.433410e-04 FinalTime=2.434410e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4332e-04 2.4342e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p3_fall_"
  Transient (
    InitialTime=2.434410e-04 FinalTime=2.434420e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p4_rise_"
  Transient (
    InitialTime=2.434420e-04 FinalTime=2.434430e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p4_write_"
  Transient (
    InitialTime=2.434430e-04 FinalTime=2.435430e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4342e-04 2.4352e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p4_fall_"
  Transient (
    InitialTime=2.435430e-04 FinalTime=2.435440e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p5_rise_"
  Transient (
    InitialTime=2.435440e-04 FinalTime=2.435450e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p5_write_"
  Transient (
    InitialTime=2.435450e-04 FinalTime=2.436450e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4352e-04 2.4362e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p5_fall_"
  Transient (
    InitialTime=2.436450e-04 FinalTime=2.436460e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p6_rise_"
  Transient (
    InitialTime=2.436460e-04 FinalTime=2.436470e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p6_write_"
  Transient (
    InitialTime=2.436470e-04 FinalTime=2.437470e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4362e-04 2.4372e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p6_fall_"
  Transient (
    InitialTime=2.437470e-04 FinalTime=2.437570e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p7_rise_"
  Transient (
    InitialTime=2.437570e-04 FinalTime=2.437580e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p7_write_"
  Transient (
    InitialTime=2.437580e-04 FinalTime=2.438580e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4373e-04 2.4383e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p7_fall_"
  Transient (
    InitialTime=2.438580e-04 FinalTime=2.438590e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p8_rise_"
  Transient (
    InitialTime=2.438590e-04 FinalTime=2.438600e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p8_write_"
  Transient (
    InitialTime=2.438600e-04 FinalTime=2.439600e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4383e-04 2.4393e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p8_fall_"
  Transient (
    InitialTime=2.439600e-04 FinalTime=2.439610e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p9_rise_"
  Transient (
    InitialTime=2.439610e-04 FinalTime=2.439620e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p9_write_"
  Transient (
    InitialTime=2.439620e-04 FinalTime=2.440620e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4393e-04 2.4403e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p9_fall_"
  Transient (
    InitialTime=2.440620e-04 FinalTime=2.440630e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_burst_read_"
  Transient (
    InitialTime=2.440630e-04 FinalTime=2.441630e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4403e-04 2.4413e-04) Intervals=20) ) }
  *--- CYCLE 4 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c4_erase_rise_"
  Transient (
    InitialTime=2.441630e-04 FinalTime=2.441730e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_erase_hold_"
  Transient (
    InitialTime=2.441730e-04 FinalTime=2.541730e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4414e-04 2.5414e-04) Intervals=40) ) }
  NewCurrentPrefix="c4_erase_fall_"
  Transient (
    InitialTime=2.541730e-04 FinalTime=2.541830e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 4 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c4_relax_"
  Transient (
    InitialTime=2.541830e-04 FinalTime=3.241830e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.5415e-04 3.2415e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 5 (cycle base time = 3.2415e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c5_p1_rise_"
  Transient (
    InitialTime=3.241830e-04 FinalTime=3.241840e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p1_write_"
  Transient (
    InitialTime=3.241840e-04 FinalTime=3.242840e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2415e-04 3.2425e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p1_fall_"
  Transient (
    InitialTime=3.242840e-04 FinalTime=3.242850e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_rise_"
  Transient (
    InitialTime=3.242850e-04 FinalTime=3.242860e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_write_"
  Transient (
    InitialTime=3.242860e-04 FinalTime=3.243860e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2425e-04 3.2435e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p2_fall_"
  Transient (
    InitialTime=3.243860e-04 FinalTime=3.243960e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_rise_"
  Transient (
    InitialTime=3.243960e-04 FinalTime=3.243970e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_write_"
  Transient (
    InitialTime=3.243970e-04 FinalTime=3.244970e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2436e-04 3.2446e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p3_fall_"
  Transient (
    InitialTime=3.244970e-04 FinalTime=3.244980e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p4_rise_"
  Transient (
    InitialTime=3.244980e-04 FinalTime=3.244990e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p4_write_"
  Transient (
    InitialTime=3.244990e-04 FinalTime=3.245990e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2446e-04 3.2456e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p4_fall_"
  Transient (
    InitialTime=3.245990e-04 FinalTime=3.246000e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p5_rise_"
  Transient (
    InitialTime=3.246000e-04 FinalTime=3.246010e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p5_write_"
  Transient (
    InitialTime=3.246010e-04 FinalTime=3.247010e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2456e-04 3.2466e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p5_fall_"
  Transient (
    InitialTime=3.247010e-04 FinalTime=3.247020e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p6_rise_"
  Transient (
    InitialTime=3.247020e-04 FinalTime=3.247030e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p6_write_"
  Transient (
    InitialTime=3.247030e-04 FinalTime=3.248030e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2466e-04 3.2476e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p6_fall_"
  Transient (
    InitialTime=3.248030e-04 FinalTime=3.248040e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p7_rise_"
  Transient (
    InitialTime=3.248040e-04 FinalTime=3.248050e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p7_write_"
  Transient (
    InitialTime=3.248050e-04 FinalTime=3.249050e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2476e-04 3.2486e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p7_fall_"
  Transient (
    InitialTime=3.249050e-04 FinalTime=3.249150e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p8_rise_"
  Transient (
    InitialTime=3.249150e-04 FinalTime=3.249160e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p8_write_"
  Transient (
    InitialTime=3.249160e-04 FinalTime=3.250160e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2487e-04 3.2497e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p8_fall_"
  Transient (
    InitialTime=3.250160e-04 FinalTime=3.250170e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p9_rise_"
  Transient (
    InitialTime=3.250170e-04 FinalTime=3.250180e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p9_write_"
  Transient (
    InitialTime=3.250180e-04 FinalTime=3.251180e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2497e-04 3.2507e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p9_fall_"
  Transient (
    InitialTime=3.251180e-04 FinalTime=3.251190e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_burst_read_"
  Transient (
    InitialTime=3.251190e-04 FinalTime=3.252190e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2507e-04 3.2517e-04) Intervals=20) ) }
  *--- CYCLE 5 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c5_erase_rise_"
  Transient (
    InitialTime=3.252190e-04 FinalTime=3.252290e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_erase_hold_"
  Transient (
    InitialTime=3.252290e-04 FinalTime=3.352290e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2518e-04 3.3518e-04) Intervals=40) ) }
  NewCurrentPrefix="c5_erase_fall_"
  Transient (
    InitialTime=3.352290e-04 FinalTime=3.352390e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 5 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c5_relax_"
  Transient (
    InitialTime=3.352390e-04 FinalTime=4.052390e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.3519e-04 4.0519e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 6 (cycle base time = 4.0519e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c6_p1_rise_"
  Transient (
    InitialTime=4.052390e-04 FinalTime=4.052400e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p1_write_"
  Transient (
    InitialTime=4.052400e-04 FinalTime=4.053400e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0519e-04 4.0529e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p1_fall_"
  Transient (
    InitialTime=4.053400e-04 FinalTime=4.053410e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p2_rise_"
  Transient (
    InitialTime=4.053410e-04 FinalTime=4.053420e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p2_write_"
  Transient (
    InitialTime=4.053420e-04 FinalTime=4.054420e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0529e-04 4.0539e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p2_fall_"
  Transient (
    InitialTime=4.054420e-04 FinalTime=4.054430e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p3_rise_"
  Transient (
    InitialTime=4.054430e-04 FinalTime=4.054440e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p3_write_"
  Transient (
    InitialTime=4.054440e-04 FinalTime=4.055440e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0539e-04 4.0549e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p3_fall_"
  Transient (
    InitialTime=4.055440e-04 FinalTime=4.055540e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p4_rise_"
  Transient (
    InitialTime=4.055540e-04 FinalTime=4.055550e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p4_write_"
  Transient (
    InitialTime=4.055550e-04 FinalTime=4.056550e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0550e-04 4.0560e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p4_fall_"
  Transient (
    InitialTime=4.056550e-04 FinalTime=4.056560e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p5_rise_"
  Transient (
    InitialTime=4.056560e-04 FinalTime=4.056570e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p5_write_"
  Transient (
    InitialTime=4.056570e-04 FinalTime=4.057570e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0560e-04 4.0570e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p5_fall_"
  Transient (
    InitialTime=4.057570e-04 FinalTime=4.057580e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p6_rise_"
  Transient (
    InitialTime=4.057580e-04 FinalTime=4.057590e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p6_write_"
  Transient (
    InitialTime=4.057590e-04 FinalTime=4.058590e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0570e-04 4.0580e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p6_fall_"
  Transient (
    InitialTime=4.058590e-04 FinalTime=4.058600e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p7_rise_"
  Transient (
    InitialTime=4.058600e-04 FinalTime=4.058610e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p7_write_"
  Transient (
    InitialTime=4.058610e-04 FinalTime=4.059610e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0580e-04 4.0590e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p7_fall_"
  Transient (
    InitialTime=4.059610e-04 FinalTime=4.059620e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p8_rise_"
  Transient (
    InitialTime=4.059620e-04 FinalTime=4.059630e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p8_write_"
  Transient (
    InitialTime=4.059630e-04 FinalTime=4.060630e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0590e-04 4.0600e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p8_fall_"
  Transient (
    InitialTime=4.060630e-04 FinalTime=4.060730e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p9_rise_"
  Transient (
    InitialTime=4.060730e-04 FinalTime=4.060740e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p9_write_"
  Transient (
    InitialTime=4.060740e-04 FinalTime=4.061740e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0601e-04 4.0611e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p9_fall_"
  Transient (
    InitialTime=4.061740e-04 FinalTime=4.061750e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_burst_read_"
  Transient (
    InitialTime=4.061750e-04 FinalTime=4.062750e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0611e-04 4.0621e-04) Intervals=20) ) }
  *--- CYCLE 6 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c6_erase_rise_"
  Transient (
    InitialTime=4.062750e-04 FinalTime=4.062850e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_erase_hold_"
  Transient (
    InitialTime=4.062850e-04 FinalTime=4.162850e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0622e-04 4.1622e-04) Intervals=40) ) }
  NewCurrentPrefix="c6_erase_fall_"
  Transient (
    InitialTime=4.162850e-04 FinalTime=4.162950e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 6 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c6_relax_"
  Transient (
    InitialTime=4.162950e-04 FinalTime=4.862950e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1623e-04 4.8623e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 7 (cycle base time = 4.8623e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c7_p1_rise_"
  Transient (
    InitialTime=4.862950e-04 FinalTime=4.862960e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p1_write_"
  Transient (
    InitialTime=4.862960e-04 FinalTime=4.863960e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8623e-04 4.8633e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p1_fall_"
  Transient (
    InitialTime=4.863960e-04 FinalTime=4.863970e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p2_rise_"
  Transient (
    InitialTime=4.863970e-04 FinalTime=4.863980e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p2_write_"
  Transient (
    InitialTime=4.863980e-04 FinalTime=4.864980e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8633e-04 4.8643e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p2_fall_"
  Transient (
    InitialTime=4.864980e-04 FinalTime=4.864990e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p3_rise_"
  Transient (
    InitialTime=4.864990e-04 FinalTime=4.865000e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p3_write_"
  Transient (
    InitialTime=4.865000e-04 FinalTime=4.866000e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8643e-04 4.8653e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p3_fall_"
  Transient (
    InitialTime=4.866000e-04 FinalTime=4.866010e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p4_rise_"
  Transient (
    InitialTime=4.866010e-04 FinalTime=4.866020e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p4_write_"
  Transient (
    InitialTime=4.866020e-04 FinalTime=4.867020e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8653e-04 4.8663e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p4_fall_"
  Transient (
    InitialTime=4.867020e-04 FinalTime=4.867120e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p5_rise_"
  Transient (
    InitialTime=4.867120e-04 FinalTime=4.867130e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p5_write_"
  Transient (
    InitialTime=4.867130e-04 FinalTime=4.868130e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8664e-04 4.8674e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p5_fall_"
  Transient (
    InitialTime=4.868130e-04 FinalTime=4.868140e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p6_rise_"
  Transient (
    InitialTime=4.868140e-04 FinalTime=4.868150e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p6_write_"
  Transient (
    InitialTime=4.868150e-04 FinalTime=4.869150e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8674e-04 4.8684e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p6_fall_"
  Transient (
    InitialTime=4.869150e-04 FinalTime=4.869160e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p7_rise_"
  Transient (
    InitialTime=4.869160e-04 FinalTime=4.869170e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p7_write_"
  Transient (
    InitialTime=4.869170e-04 FinalTime=4.870170e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8684e-04 4.8694e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p7_fall_"
  Transient (
    InitialTime=4.870170e-04 FinalTime=4.870180e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p8_rise_"
  Transient (
    InitialTime=4.870180e-04 FinalTime=4.870190e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p8_write_"
  Transient (
    InitialTime=4.870190e-04 FinalTime=4.871190e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8694e-04 4.8704e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p8_fall_"
  Transient (
    InitialTime=4.871190e-04 FinalTime=4.871200e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p9_rise_"
  Transient (
    InitialTime=4.871200e-04 FinalTime=4.871210e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p9_write_"
  Transient (
    InitialTime=4.871210e-04 FinalTime=4.872210e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8704e-04 4.8714e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p9_fall_"
  Transient (
    InitialTime=4.872210e-04 FinalTime=4.872310e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_burst_read_"
  Transient (
    InitialTime=4.872310e-04 FinalTime=4.873310e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8715e-04 4.8725e-04) Intervals=20) ) }
  *--- CYCLE 7 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c7_erase_rise_"
  Transient (
    InitialTime=4.873310e-04 FinalTime=4.873410e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_erase_hold_"
  Transient (
    InitialTime=4.873410e-04 FinalTime=4.973410e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8726e-04 4.9726e-04) Intervals=40) ) }
  NewCurrentPrefix="c7_erase_fall_"
  Transient (
    InitialTime=4.973410e-04 FinalTime=4.973510e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 7 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c7_relax_"
  Transient (
    InitialTime=4.973510e-04 FinalTime=5.673510e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9727e-04 5.6727e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 8 (cycle base time = 5.6727e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c8_p1_rise_"
  Transient (
    InitialTime=5.673510e-04 FinalTime=5.673520e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p1_write_"
  Transient (
    InitialTime=5.673520e-04 FinalTime=5.674520e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6727e-04 5.6737e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p1_fall_"
  Transient (
    InitialTime=5.674520e-04 FinalTime=5.674530e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p2_rise_"
  Transient (
    InitialTime=5.674530e-04 FinalTime=5.674540e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p2_write_"
  Transient (
    InitialTime=5.674540e-04 FinalTime=5.675540e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6737e-04 5.6747e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p2_fall_"
  Transient (
    InitialTime=5.675540e-04 FinalTime=5.675550e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p3_rise_"
  Transient (
    InitialTime=5.675550e-04 FinalTime=5.675560e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p3_write_"
  Transient (
    InitialTime=5.675560e-04 FinalTime=5.676560e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6747e-04 5.6757e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p3_fall_"
  Transient (
    InitialTime=5.676560e-04 FinalTime=5.676570e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p4_rise_"
  Transient (
    InitialTime=5.676570e-04 FinalTime=5.676580e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p4_write_"
  Transient (
    InitialTime=5.676580e-04 FinalTime=5.677580e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6757e-04 5.6767e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p4_fall_"
  Transient (
    InitialTime=5.677580e-04 FinalTime=5.677590e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p5_rise_"
  Transient (
    InitialTime=5.677590e-04 FinalTime=5.677690e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p5_write_"
  Transient (
    InitialTime=5.677690e-04 FinalTime=5.678590e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6768e-04 5.6777e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p5_fall_"
  Transient (
    InitialTime=5.678590e-04 FinalTime=5.678690e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p6_rise_"
  Transient (
    InitialTime=5.678690e-04 FinalTime=5.678700e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p6_write_"
  Transient (
    InitialTime=5.678700e-04 FinalTime=5.679700e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6778e-04 5.6788e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p6_fall_"
  Transient (
    InitialTime=5.679700e-04 FinalTime=5.679710e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p7_rise_"
  Transient (
    InitialTime=5.679710e-04 FinalTime=5.679720e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p7_write_"
  Transient (
    InitialTime=5.679720e-04 FinalTime=5.680720e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6788e-04 5.6798e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p7_fall_"
  Transient (
    InitialTime=5.680720e-04 FinalTime=5.680730e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p8_rise_"
  Transient (
    InitialTime=5.680730e-04 FinalTime=5.680740e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p8_write_"
  Transient (
    InitialTime=5.680740e-04 FinalTime=5.681740e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6798e-04 5.6808e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p8_fall_"
  Transient (
    InitialTime=5.681740e-04 FinalTime=5.681750e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p9_rise_"
  Transient (
    InitialTime=5.681750e-04 FinalTime=5.681760e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p9_write_"
  Transient (
    InitialTime=5.681760e-04 FinalTime=5.682760e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6808e-04 5.6818e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p9_fall_"
  Transient (
    InitialTime=5.682760e-04 FinalTime=5.682770e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_burst_read_"
  Transient (
    InitialTime=5.682770e-04 FinalTime=5.683770e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6818e-04 5.6828e-04) Intervals=20) ) }
  *--- CYCLE 8 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c8_erase_rise_"
  Transient (
    InitialTime=5.683770e-04 FinalTime=5.683870e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_erase_hold_"
  Transient (
    InitialTime=5.683870e-04 FinalTime=5.783870e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6829e-04 5.7829e-04) Intervals=40) ) }
  NewCurrentPrefix="c8_erase_fall_"
  Transient (
    InitialTime=5.783870e-04 FinalTime=5.783970e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 8 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c8_relax_"
  Transient (
    InitialTime=5.783970e-04 FinalTime=6.483970e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7830e-04 6.4830e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 9 (cycle base time = 6.4830e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c9_p1_rise_"
  Transient (
    InitialTime=6.483970e-04 FinalTime=6.483980e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p1_write_"
  Transient (
    InitialTime=6.483980e-04 FinalTime=6.484980e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4830e-04 6.4840e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p1_fall_"
  Transient (
    InitialTime=6.484980e-04 FinalTime=6.485080e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p2_rise_"
  Transient (
    InitialTime=6.485080e-04 FinalTime=6.485090e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p2_write_"
  Transient (
    InitialTime=6.485090e-04 FinalTime=6.486090e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4841e-04 6.4851e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p2_fall_"
  Transient (
    InitialTime=6.486090e-04 FinalTime=6.486100e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p3_rise_"
  Transient (
    InitialTime=6.486100e-04 FinalTime=6.486110e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p3_write_"
  Transient (
    InitialTime=6.486110e-04 FinalTime=6.487110e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4851e-04 6.4861e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p3_fall_"
  Transient (
    InitialTime=6.487110e-04 FinalTime=6.487120e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p4_rise_"
  Transient (
    InitialTime=6.487120e-04 FinalTime=6.487130e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p4_write_"
  Transient (
    InitialTime=6.487130e-04 FinalTime=6.488130e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4861e-04 6.4871e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p4_fall_"
  Transient (
    InitialTime=6.488130e-04 FinalTime=6.488140e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p5_rise_"
  Transient (
    InitialTime=6.488140e-04 FinalTime=6.488150e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p5_write_"
  Transient (
    InitialTime=6.488150e-04 FinalTime=6.489150e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4871e-04 6.4881e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p5_fall_"
  Transient (
    InitialTime=6.489150e-04 FinalTime=6.489160e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p6_rise_"
  Transient (
    InitialTime=6.489160e-04 FinalTime=6.489170e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p6_write_"
  Transient (
    InitialTime=6.489170e-04 FinalTime=6.490170e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4881e-04 6.4891e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p6_fall_"
  Transient (
    InitialTime=6.490170e-04 FinalTime=6.490270e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p7_rise_"
  Transient (
    InitialTime=6.490270e-04 FinalTime=6.490280e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p7_write_"
  Transient (
    InitialTime=6.490280e-04 FinalTime=6.491280e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4892e-04 6.4902e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p7_fall_"
  Transient (
    InitialTime=6.491280e-04 FinalTime=6.491290e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p8_rise_"
  Transient (
    InitialTime=6.491290e-04 FinalTime=6.491300e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p8_write_"
  Transient (
    InitialTime=6.491300e-04 FinalTime=6.492300e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4902e-04 6.4912e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p8_fall_"
  Transient (
    InitialTime=6.492300e-04 FinalTime=6.492310e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p9_rise_"
  Transient (
    InitialTime=6.492310e-04 FinalTime=6.492320e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p9_write_"
  Transient (
    InitialTime=6.492320e-04 FinalTime=6.493320e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4912e-04 6.4922e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p9_fall_"
  Transient (
    InitialTime=6.493320e-04 FinalTime=6.493330e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_burst_read_"
  Transient (
    InitialTime=6.493330e-04 FinalTime=6.494330e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4922e-04 6.4932e-04) Intervals=20) ) }
  *--- CYCLE 9 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c9_erase_rise_"
  Transient (
    InitialTime=6.494330e-04 FinalTime=6.494430e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_erase_hold_"
  Transient (
    InitialTime=6.494430e-04 FinalTime=6.594430e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4933e-04 6.5933e-04) Intervals=40) ) }
  NewCurrentPrefix="c9_erase_fall_"
  Transient (
    InitialTime=6.594430e-04 FinalTime=6.594530e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 9 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c9_relax_"
  Transient (
    InitialTime=6.594530e-04 FinalTime=7.294530e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5934e-04 7.2934e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 10 (cycle base time = 7.2934e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c10_p1_rise_"
  Transient (
    InitialTime=7.294530e-04 FinalTime=7.294540e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p1_write_"
  Transient (
    InitialTime=7.294540e-04 FinalTime=7.295540e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.2934e-04 7.2944e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p1_fall_"
  Transient (
    InitialTime=7.295540e-04 FinalTime=7.295550e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p2_rise_"
  Transient (
    InitialTime=7.295550e-04 FinalTime=7.295560e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p2_write_"
  Transient (
    InitialTime=7.295560e-04 FinalTime=7.296560e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.2944e-04 7.2954e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p2_fall_"
  Transient (
    InitialTime=7.296560e-04 FinalTime=7.296660e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p3_rise_"
  Transient (
    InitialTime=7.296660e-04 FinalTime=7.296670e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p3_write_"
  Transient (
    InitialTime=7.296670e-04 FinalTime=7.297670e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.2955e-04 7.2965e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p3_fall_"
  Transient (
    InitialTime=7.297670e-04 FinalTime=7.297680e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p4_rise_"
  Transient (
    InitialTime=7.297680e-04 FinalTime=7.297690e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p4_write_"
  Transient (
    InitialTime=7.297690e-04 FinalTime=7.298690e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.2965e-04 7.2975e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p4_fall_"
  Transient (
    InitialTime=7.298690e-04 FinalTime=7.298700e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p5_rise_"
  Transient (
    InitialTime=7.298700e-04 FinalTime=7.298710e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p5_write_"
  Transient (
    InitialTime=7.298710e-04 FinalTime=7.299710e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.2975e-04 7.2985e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p5_fall_"
  Transient (
    InitialTime=7.299710e-04 FinalTime=7.299720e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p6_rise_"
  Transient (
    InitialTime=7.299720e-04 FinalTime=7.299730e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p6_write_"
  Transient (
    InitialTime=7.299730e-04 FinalTime=7.300730e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.2985e-04 7.2995e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p6_fall_"
  Transient (
    InitialTime=7.300730e-04 FinalTime=7.300740e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p7_rise_"
  Transient (
    InitialTime=7.300740e-04 FinalTime=7.300750e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p7_write_"
  Transient (
    InitialTime=7.300750e-04 FinalTime=7.301750e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.2995e-04 7.3005e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p7_fall_"
  Transient (
    InitialTime=7.301750e-04 FinalTime=7.301850e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p8_rise_"
  Transient (
    InitialTime=7.301850e-04 FinalTime=7.301860e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p8_write_"
  Transient (
    InitialTime=7.301860e-04 FinalTime=7.302860e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3006e-04 7.3016e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p8_fall_"
  Transient (
    InitialTime=7.302860e-04 FinalTime=7.302870e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p9_rise_"
  Transient (
    InitialTime=7.302870e-04 FinalTime=7.302880e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p9_write_"
  Transient (
    InitialTime=7.302880e-04 FinalTime=7.303880e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3016e-04 7.3026e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p9_fall_"
  Transient (
    InitialTime=7.303880e-04 FinalTime=7.303890e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_burst_read_"
  Transient (
    InitialTime=7.303890e-04 FinalTime=7.304890e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3026e-04 7.3036e-04) Intervals=20) ) }
  *--- CYCLE 10 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c10_erase_rise_"
  Transient (
    InitialTime=7.304890e-04 FinalTime=7.304990e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_erase_hold_"
  Transient (
    InitialTime=7.304990e-04 FinalTime=7.404990e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3037e-04 7.4037e-04) Intervals=40) ) }
  NewCurrentPrefix="c10_erase_fall_"
  Transient (
    InitialTime=7.404990e-04 FinalTime=7.405090e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 10 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c10_relax_"
  Transient (
    InitialTime=7.405090e-04 FinalTime=8.105090e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.4038e-04 8.1038e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 11 (cycle base time = 8.1038e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c11_p1_rise_"
  Transient (
    InitialTime=8.105090e-04 FinalTime=8.105100e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p1_write_"
  Transient (
    InitialTime=8.105100e-04 FinalTime=8.106100e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1038e-04 8.1048e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p1_fall_"
  Transient (
    InitialTime=8.106100e-04 FinalTime=8.106110e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p2_rise_"
  Transient (
    InitialTime=8.106110e-04 FinalTime=8.106120e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p2_write_"
  Transient (
    InitialTime=8.106120e-04 FinalTime=8.107120e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1048e-04 8.1058e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p2_fall_"
  Transient (
    InitialTime=8.107120e-04 FinalTime=8.107130e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p3_rise_"
  Transient (
    InitialTime=8.107130e-04 FinalTime=8.107140e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p3_write_"
  Transient (
    InitialTime=8.107140e-04 FinalTime=8.108140e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1058e-04 8.1068e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p3_fall_"
  Transient (
    InitialTime=8.108140e-04 FinalTime=8.108240e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p4_rise_"
  Transient (
    InitialTime=8.108240e-04 FinalTime=8.108250e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p4_write_"
  Transient (
    InitialTime=8.108250e-04 FinalTime=8.109250e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1069e-04 8.1079e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p4_fall_"
  Transient (
    InitialTime=8.109250e-04 FinalTime=8.109260e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p5_rise_"
  Transient (
    InitialTime=8.109260e-04 FinalTime=8.109270e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p5_write_"
  Transient (
    InitialTime=8.109270e-04 FinalTime=8.110270e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1079e-04 8.1089e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p5_fall_"
  Transient (
    InitialTime=8.110270e-04 FinalTime=8.110280e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p6_rise_"
  Transient (
    InitialTime=8.110280e-04 FinalTime=8.110290e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p6_write_"
  Transient (
    InitialTime=8.110290e-04 FinalTime=8.111290e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1089e-04 8.1099e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p6_fall_"
  Transient (
    InitialTime=8.111290e-04 FinalTime=8.111300e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p7_rise_"
  Transient (
    InitialTime=8.111300e-04 FinalTime=8.111310e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p7_write_"
  Transient (
    InitialTime=8.111310e-04 FinalTime=8.112310e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1099e-04 8.1109e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p7_fall_"
  Transient (
    InitialTime=8.112310e-04 FinalTime=8.112320e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p8_rise_"
  Transient (
    InitialTime=8.112320e-04 FinalTime=8.112330e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p8_write_"
  Transient (
    InitialTime=8.112330e-04 FinalTime=8.113330e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1109e-04 8.1119e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p8_fall_"
  Transient (
    InitialTime=8.113330e-04 FinalTime=8.113430e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p9_rise_"
  Transient (
    InitialTime=8.113430e-04 FinalTime=8.113440e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p9_write_"
  Transient (
    InitialTime=8.113440e-04 FinalTime=8.114440e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1120e-04 8.1130e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p9_fall_"
  Transient (
    InitialTime=8.114440e-04 FinalTime=8.114450e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_burst_read_"
  Transient (
    InitialTime=8.114450e-04 FinalTime=8.115450e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1130e-04 8.1140e-04) Intervals=20) ) }
  *--- CYCLE 11 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c11_erase_rise_"
  Transient (
    InitialTime=8.115450e-04 FinalTime=8.115550e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_erase_hold_"
  Transient (
    InitialTime=8.115550e-04 FinalTime=8.215550e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1141e-04 8.2141e-04) Intervals=40) ) }
  NewCurrentPrefix="c11_erase_fall_"
  Transient (
    InitialTime=8.215550e-04 FinalTime=8.215650e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 11 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c11_relax_"
  Transient (
    InitialTime=8.215650e-04 FinalTime=8.915650e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2142e-04 8.9142e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 12 (cycle base time = 8.9142e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c12_p1_rise_"
  Transient (
    InitialTime=8.915650e-04 FinalTime=8.915660e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p1_write_"
  Transient (
    InitialTime=8.915660e-04 FinalTime=8.916660e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9142e-04 8.9152e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p1_fall_"
  Transient (
    InitialTime=8.916660e-04 FinalTime=8.916670e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p2_rise_"
  Transient (
    InitialTime=8.916670e-04 FinalTime=8.916680e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p2_write_"
  Transient (
    InitialTime=8.916680e-04 FinalTime=8.917680e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9152e-04 8.9162e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p2_fall_"
  Transient (
    InitialTime=8.917680e-04 FinalTime=8.917690e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p3_rise_"
  Transient (
    InitialTime=8.917690e-04 FinalTime=8.917700e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p3_write_"
  Transient (
    InitialTime=8.917700e-04 FinalTime=8.918700e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9162e-04 8.9172e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p3_fall_"
  Transient (
    InitialTime=8.918700e-04 FinalTime=8.918710e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p4_rise_"
  Transient (
    InitialTime=8.918710e-04 FinalTime=8.918810e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p4_write_"
  Transient (
    InitialTime=8.918810e-04 FinalTime=8.919710e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9173e-04 8.9182e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p4_fall_"
  Transient (
    InitialTime=8.919710e-04 FinalTime=8.919810e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p5_rise_"
  Transient (
    InitialTime=8.919810e-04 FinalTime=8.919820e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p5_write_"
  Transient (
    InitialTime=8.919820e-04 FinalTime=8.920820e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9183e-04 8.9193e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p5_fall_"
  Transient (
    InitialTime=8.920820e-04 FinalTime=8.920830e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p6_rise_"
  Transient (
    InitialTime=8.920830e-04 FinalTime=8.920840e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p6_write_"
  Transient (
    InitialTime=8.920840e-04 FinalTime=8.921840e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9193e-04 8.9203e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p6_fall_"
  Transient (
    InitialTime=8.921840e-04 FinalTime=8.921850e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p7_rise_"
  Transient (
    InitialTime=8.921850e-04 FinalTime=8.921860e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p7_write_"
  Transient (
    InitialTime=8.921860e-04 FinalTime=8.922860e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9203e-04 8.9213e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p7_fall_"
  Transient (
    InitialTime=8.922860e-04 FinalTime=8.922870e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p8_rise_"
  Transient (
    InitialTime=8.922870e-04 FinalTime=8.922880e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p8_write_"
  Transient (
    InitialTime=8.922880e-04 FinalTime=8.923880e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9213e-04 8.9223e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p8_fall_"
  Transient (
    InitialTime=8.923880e-04 FinalTime=8.923890e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p9_rise_"
  Transient (
    InitialTime=8.923890e-04 FinalTime=8.923900e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p9_write_"
  Transient (
    InitialTime=8.923900e-04 FinalTime=8.924900e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9223e-04 8.9233e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p9_fall_"
  Transient (
    InitialTime=8.924900e-04 FinalTime=8.925000e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_burst_read_"
  Transient (
    InitialTime=8.925000e-04 FinalTime=8.926000e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9234e-04 8.9244e-04) Intervals=20) ) }
  *--- CYCLE 12 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c12_erase_rise_"
  Transient (
    InitialTime=8.926000e-04 FinalTime=8.926100e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_erase_hold_"
  Transient (
    InitialTime=8.926100e-04 FinalTime=9.026100e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9245e-04 9.0245e-04) Intervals=40) ) }
  NewCurrentPrefix="c12_erase_fall_"
  Transient (
    InitialTime=9.026100e-04 FinalTime=9.026200e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 12 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c12_relax_"
  Transient (
    InitialTime=9.026200e-04 FinalTime=9.726200e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0246e-04 9.7246e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 13 (cycle base time = 9.7246e-04)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c13_p1_rise_"
  Transient (
    InitialTime=9.726200e-04 FinalTime=9.726210e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p1_write_"
  Transient (
    InitialTime=9.726210e-04 FinalTime=9.727210e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7246e-04 9.7256e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p1_fall_"
  Transient (
    InitialTime=9.727210e-04 FinalTime=9.727220e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p2_rise_"
  Transient (
    InitialTime=9.727220e-04 FinalTime=9.727230e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p2_write_"
  Transient (
    InitialTime=9.727230e-04 FinalTime=9.728230e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7256e-04 9.7266e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p2_fall_"
  Transient (
    InitialTime=9.728230e-04 FinalTime=9.728240e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p3_rise_"
  Transient (
    InitialTime=9.728240e-04 FinalTime=9.728250e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p3_write_"
  Transient (
    InitialTime=9.728250e-04 FinalTime=9.729250e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7266e-04 9.7276e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p3_fall_"
  Transient (
    InitialTime=9.729250e-04 FinalTime=9.729260e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p4_rise_"
  Transient (
    InitialTime=9.729260e-04 FinalTime=9.729270e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p4_write_"
  Transient (
    InitialTime=9.729270e-04 FinalTime=9.730270e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7276e-04 9.7286e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p4_fall_"
  Transient (
    InitialTime=9.730270e-04 FinalTime=9.730280e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p5_rise_"
  Transient (
    InitialTime=9.730280e-04 FinalTime=9.730290e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p5_write_"
  Transient (
    InitialTime=9.730290e-04 FinalTime=9.731290e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7286e-04 9.7296e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p5_fall_"
  Transient (
    InitialTime=9.731290e-04 FinalTime=9.731390e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p6_rise_"
  Transient (
    InitialTime=9.731390e-04 FinalTime=9.731400e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p6_write_"
  Transient (
    InitialTime=9.731400e-04 FinalTime=9.732400e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7297e-04 9.7307e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p6_fall_"
  Transient (
    InitialTime=9.732400e-04 FinalTime=9.732410e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p7_rise_"
  Transient (
    InitialTime=9.732410e-04 FinalTime=9.732420e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p7_write_"
  Transient (
    InitialTime=9.732420e-04 FinalTime=9.733420e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7307e-04 9.7317e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p7_fall_"
  Transient (
    InitialTime=9.733420e-04 FinalTime=9.733430e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p8_rise_"
  Transient (
    InitialTime=9.733430e-04 FinalTime=9.733440e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p8_write_"
  Transient (
    InitialTime=9.733440e-04 FinalTime=9.734440e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7317e-04 9.7327e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p8_fall_"
  Transient (
    InitialTime=9.734440e-04 FinalTime=9.734450e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p9_rise_"
  Transient (
    InitialTime=9.734450e-04 FinalTime=9.734460e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p9_write_"
  Transient (
    InitialTime=9.734460e-04 FinalTime=9.735460e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7327e-04 9.7337e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p9_fall_"
  Transient (
    InitialTime=9.735460e-04 FinalTime=9.735470e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_burst_read_"
  Transient (
    InitialTime=9.735470e-04 FinalTime=9.736470e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7337e-04 9.7347e-04) Intervals=20) ) }
  *--- CYCLE 13 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c13_erase_rise_"
  Transient (
    InitialTime=9.736470e-04 FinalTime=9.736570e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_erase_hold_"
  Transient (
    InitialTime=9.736570e-04 FinalTime=9.836570e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7348e-04 9.8348e-04) Intervals=40) ) }
  NewCurrentPrefix="c13_erase_fall_"
  Transient (
    InitialTime=9.836570e-04 FinalTime=9.836670e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 13 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c13_relax_"
  Transient (
    InitialTime=9.836670e-04 FinalTime=1.053677e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8349e-04 1.0535e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 14 (cycle base time = 1.0535e-03)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c14_p1_rise_"
  Transient (
    InitialTime=1.053677e-03 FinalTime=1.053678e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p1_write_"
  Transient (
    InitialTime=1.053678e-03 FinalTime=1.053778e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0535e-03 1.0536e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p1_fall_"
  Transient (
    InitialTime=1.053778e-03 FinalTime=1.053779e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p2_rise_"
  Transient (
    InitialTime=1.053779e-03 FinalTime=1.053780e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p2_write_"
  Transient (
    InitialTime=1.053780e-03 FinalTime=1.053880e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0536e-03 1.0537e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p2_fall_"
  Transient (
    InitialTime=1.053880e-03 FinalTime=1.053881e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p3_rise_"
  Transient (
    InitialTime=1.053881e-03 FinalTime=1.053882e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p3_write_"
  Transient (
    InitialTime=1.053882e-03 FinalTime=1.053982e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0537e-03 1.0538e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p3_fall_"
  Transient (
    InitialTime=1.053982e-03 FinalTime=1.053983e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p4_rise_"
  Transient (
    InitialTime=1.053983e-03 FinalTime=1.053984e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p4_write_"
  Transient (
    InitialTime=1.053984e-03 FinalTime=1.054084e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0538e-03 1.0539e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p4_fall_"
  Transient (
    InitialTime=1.054084e-03 FinalTime=1.054085e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p5_rise_"
  Transient (
    InitialTime=1.054085e-03 FinalTime=1.054086e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p5_write_"
  Transient (
    InitialTime=1.054086e-03 FinalTime=1.054186e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0539e-03 1.0540e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p5_fall_"
  Transient (
    InitialTime=1.054186e-03 FinalTime=1.054187e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p6_rise_"
  Transient (
    InitialTime=1.054187e-03 FinalTime=1.054188e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p6_write_"
  Transient (
    InitialTime=1.054188e-03 FinalTime=1.054288e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0540e-03 1.0541e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p6_fall_"
  Transient (
    InitialTime=1.054288e-03 FinalTime=1.054289e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p7_rise_"
  Transient (
    InitialTime=1.054289e-03 FinalTime=1.054290e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p7_write_"
  Transient (
    InitialTime=1.054290e-03 FinalTime=1.054390e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0541e-03 1.0542e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p7_fall_"
  Transient (
    InitialTime=1.054390e-03 FinalTime=1.054391e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p8_rise_"
  Transient (
    InitialTime=1.054391e-03 FinalTime=1.054392e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p8_write_"
  Transient (
    InitialTime=1.054392e-03 FinalTime=1.054492e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0542e-03 1.0543e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p8_fall_"
  Transient (
    InitialTime=1.054492e-03 FinalTime=1.054493e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p9_rise_"
  Transient (
    InitialTime=1.054493e-03 FinalTime=1.054494e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p9_write_"
  Transient (
    InitialTime=1.054494e-03 FinalTime=1.054594e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0543e-03 1.0544e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p9_fall_"
  Transient (
    InitialTime=1.054594e-03 FinalTime=1.054595e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_burst_read_"
  Transient (
    InitialTime=1.054595e-03 FinalTime=1.054695e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0544e-03 1.0545e-03) Intervals=20) ) }
  *--- CYCLE 14 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c14_erase_rise_"
  Transient (
    InitialTime=1.054695e-03 FinalTime=1.054696e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_erase_hold_"
  Transient (
    InitialTime=1.054696e-03 FinalTime=1.064696e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0545e-03 1.0645e-03) Intervals=40) ) }
  NewCurrentPrefix="c14_erase_fall_"
  Transient (
    InitialTime=1.064696e-03 FinalTime=1.064697e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 14 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c14_relax_"
  Transient (
    InitialTime=1.064697e-03 FinalTime=1.134697e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0645e-03 1.1345e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 15 (cycle base time = 1.1345e-03)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c15_p1_rise_"
  Transient (
    InitialTime=1.134697e-03 FinalTime=1.134698e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p1_write_"
  Transient (
    InitialTime=1.134698e-03 FinalTime=1.134798e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1345e-03 1.1346e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p1_fall_"
  Transient (
    InitialTime=1.134798e-03 FinalTime=1.134799e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p2_rise_"
  Transient (
    InitialTime=1.134799e-03 FinalTime=1.134800e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p2_write_"
  Transient (
    InitialTime=1.134800e-03 FinalTime=1.134900e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1346e-03 1.1347e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p2_fall_"
  Transient (
    InitialTime=1.134900e-03 FinalTime=1.134901e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p3_rise_"
  Transient (
    InitialTime=1.134901e-03 FinalTime=1.134902e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p3_write_"
  Transient (
    InitialTime=1.134902e-03 FinalTime=1.135002e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1347e-03 1.1348e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p3_fall_"
  Transient (
    InitialTime=1.135002e-03 FinalTime=1.135003e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p4_rise_"
  Transient (
    InitialTime=1.135003e-03 FinalTime=1.135004e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p4_write_"
  Transient (
    InitialTime=1.135004e-03 FinalTime=1.135104e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1348e-03 1.1349e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p4_fall_"
  Transient (
    InitialTime=1.135104e-03 FinalTime=1.135105e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p5_rise_"
  Transient (
    InitialTime=1.135105e-03 FinalTime=1.135106e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p5_write_"
  Transient (
    InitialTime=1.135106e-03 FinalTime=1.135206e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1349e-03 1.1350e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p5_fall_"
  Transient (
    InitialTime=1.135206e-03 FinalTime=1.135207e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p6_rise_"
  Transient (
    InitialTime=1.135207e-03 FinalTime=1.135208e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p6_write_"
  Transient (
    InitialTime=1.135208e-03 FinalTime=1.135308e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1350e-03 1.1351e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p6_fall_"
  Transient (
    InitialTime=1.135308e-03 FinalTime=1.135309e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p7_rise_"
  Transient (
    InitialTime=1.135309e-03 FinalTime=1.135310e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p7_write_"
  Transient (
    InitialTime=1.135310e-03 FinalTime=1.135410e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1351e-03 1.1352e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p7_fall_"
  Transient (
    InitialTime=1.135410e-03 FinalTime=1.135411e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p8_rise_"
  Transient (
    InitialTime=1.135411e-03 FinalTime=1.135412e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p8_write_"
  Transient (
    InitialTime=1.135412e-03 FinalTime=1.135512e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1352e-03 1.1353e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p8_fall_"
  Transient (
    InitialTime=1.135512e-03 FinalTime=1.135513e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p9_rise_"
  Transient (
    InitialTime=1.135513e-03 FinalTime=1.135514e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p9_write_"
  Transient (
    InitialTime=1.135514e-03 FinalTime=1.135614e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1353e-03 1.1354e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p9_fall_"
  Transient (
    InitialTime=1.135614e-03 FinalTime=1.135615e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_burst_read_"
  Transient (
    InitialTime=1.135615e-03 FinalTime=1.135715e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1354e-03 1.1355e-03) Intervals=20) ) }
  *--- CYCLE 15 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c15_erase_rise_"
  Transient (
    InitialTime=1.135715e-03 FinalTime=1.135815e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_erase_hold_"
  Transient (
    InitialTime=1.135815e-03 FinalTime=1.145815e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1356e-03 1.1456e-03) Intervals=40) ) }
  NewCurrentPrefix="c15_erase_fall_"
  Transient (
    InitialTime=1.145815e-03 FinalTime=1.145816e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 15 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c15_relax_"
  Transient (
    InitialTime=1.145816e-03 FinalTime=1.215816e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1456e-03 1.2156e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 16 (cycle base time = 1.2156e-03)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c16_p1_rise_"
  Transient (
    InitialTime=1.215816e-03 FinalTime=1.215817e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p1_write_"
  Transient (
    InitialTime=1.215817e-03 FinalTime=1.215917e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2156e-03 1.2157e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p1_fall_"
  Transient (
    InitialTime=1.215917e-03 FinalTime=1.215918e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p2_rise_"
  Transient (
    InitialTime=1.215918e-03 FinalTime=1.215919e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p2_write_"
  Transient (
    InitialTime=1.215919e-03 FinalTime=1.216019e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2157e-03 1.2158e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p2_fall_"
  Transient (
    InitialTime=1.216019e-03 FinalTime=1.216020e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p3_rise_"
  Transient (
    InitialTime=1.216020e-03 FinalTime=1.216021e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p3_write_"
  Transient (
    InitialTime=1.216021e-03 FinalTime=1.216121e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2158e-03 1.2159e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p3_fall_"
  Transient (
    InitialTime=1.216121e-03 FinalTime=1.216122e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p4_rise_"
  Transient (
    InitialTime=1.216122e-03 FinalTime=1.216123e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p4_write_"
  Transient (
    InitialTime=1.216123e-03 FinalTime=1.216223e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2159e-03 1.2160e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p4_fall_"
  Transient (
    InitialTime=1.216223e-03 FinalTime=1.216224e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p5_rise_"
  Transient (
    InitialTime=1.216224e-03 FinalTime=1.216225e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p5_write_"
  Transient (
    InitialTime=1.216225e-03 FinalTime=1.216325e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2160e-03 1.2161e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p5_fall_"
  Transient (
    InitialTime=1.216325e-03 FinalTime=1.216326e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p6_rise_"
  Transient (
    InitialTime=1.216326e-03 FinalTime=1.216327e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p6_write_"
  Transient (
    InitialTime=1.216327e-03 FinalTime=1.216427e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2161e-03 1.2162e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p6_fall_"
  Transient (
    InitialTime=1.216427e-03 FinalTime=1.216428e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p7_rise_"
  Transient (
    InitialTime=1.216428e-03 FinalTime=1.216429e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p7_write_"
  Transient (
    InitialTime=1.216429e-03 FinalTime=1.216529e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2162e-03 1.2163e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p7_fall_"
  Transient (
    InitialTime=1.216529e-03 FinalTime=1.216530e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p8_rise_"
  Transient (
    InitialTime=1.216530e-03 FinalTime=1.216531e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p8_write_"
  Transient (
    InitialTime=1.216531e-03 FinalTime=1.216631e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2163e-03 1.2164e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p8_fall_"
  Transient (
    InitialTime=1.216631e-03 FinalTime=1.216632e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p9_rise_"
  Transient (
    InitialTime=1.216632e-03 FinalTime=1.216633e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p9_write_"
  Transient (
    InitialTime=1.216633e-03 FinalTime=1.216733e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2164e-03 1.2165e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p9_fall_"
  Transient (
    InitialTime=1.216733e-03 FinalTime=1.216734e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_burst_read_"
  Transient (
    InitialTime=1.216734e-03 FinalTime=1.216834e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2165e-03 1.2166e-03) Intervals=20) ) }
  *--- CYCLE 16 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c16_erase_rise_"
  Transient (
    InitialTime=1.216834e-03 FinalTime=1.216835e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_erase_hold_"
  Transient (
    InitialTime=1.216835e-03 FinalTime=1.226835e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2166e-03 1.2266e-03) Intervals=40) ) }
  NewCurrentPrefix="c16_erase_fall_"
  Transient (
    InitialTime=1.226835e-03 FinalTime=1.226836e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 16 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c16_relax_"
  Transient (
    InitialTime=1.226836e-03 FinalTime=1.296836e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2266e-03 1.2966e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 17 (cycle base time = 1.2966e-03)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c17_p1_rise_"
  Transient (
    InitialTime=1.296836e-03 FinalTime=1.296837e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p1_write_"
  Transient (
    InitialTime=1.296837e-03 FinalTime=1.296937e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2966e-03 1.2967e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p1_fall_"
  Transient (
    InitialTime=1.296937e-03 FinalTime=1.296938e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p2_rise_"
  Transient (
    InitialTime=1.296938e-03 FinalTime=1.296939e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p2_write_"
  Transient (
    InitialTime=1.296939e-03 FinalTime=1.297039e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2967e-03 1.2968e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p2_fall_"
  Transient (
    InitialTime=1.297039e-03 FinalTime=1.297040e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p3_rise_"
  Transient (
    InitialTime=1.297040e-03 FinalTime=1.297041e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p3_write_"
  Transient (
    InitialTime=1.297041e-03 FinalTime=1.297141e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2968e-03 1.2969e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p3_fall_"
  Transient (
    InitialTime=1.297141e-03 FinalTime=1.297142e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p4_rise_"
  Transient (
    InitialTime=1.297142e-03 FinalTime=1.297143e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p4_write_"
  Transient (
    InitialTime=1.297143e-03 FinalTime=1.297243e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2969e-03 1.2970e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p4_fall_"
  Transient (
    InitialTime=1.297243e-03 FinalTime=1.297244e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p5_rise_"
  Transient (
    InitialTime=1.297244e-03 FinalTime=1.297245e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p5_write_"
  Transient (
    InitialTime=1.297245e-03 FinalTime=1.297345e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2970e-03 1.2971e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p5_fall_"
  Transient (
    InitialTime=1.297345e-03 FinalTime=1.297346e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p6_rise_"
  Transient (
    InitialTime=1.297346e-03 FinalTime=1.297347e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p6_write_"
  Transient (
    InitialTime=1.297347e-03 FinalTime=1.297447e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2971e-03 1.2972e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p6_fall_"
  Transient (
    InitialTime=1.297447e-03 FinalTime=1.297448e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p7_rise_"
  Transient (
    InitialTime=1.297448e-03 FinalTime=1.297449e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p7_write_"
  Transient (
    InitialTime=1.297449e-03 FinalTime=1.297549e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2972e-03 1.2973e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p7_fall_"
  Transient (
    InitialTime=1.297549e-03 FinalTime=1.297550e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p8_rise_"
  Transient (
    InitialTime=1.297550e-03 FinalTime=1.297551e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p8_write_"
  Transient (
    InitialTime=1.297551e-03 FinalTime=1.297651e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2973e-03 1.2974e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p8_fall_"
  Transient (
    InitialTime=1.297651e-03 FinalTime=1.297652e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p9_rise_"
  Transient (
    InitialTime=1.297652e-03 FinalTime=1.297653e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p9_write_"
  Transient (
    InitialTime=1.297653e-03 FinalTime=1.297753e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2974e-03 1.2975e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p9_fall_"
  Transient (
    InitialTime=1.297753e-03 FinalTime=1.297754e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_burst_read_"
  Transient (
    InitialTime=1.297754e-03 FinalTime=1.297854e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2975e-03 1.2976e-03) Intervals=20) ) }
  *--- CYCLE 17 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c17_erase_rise_"
  Transient (
    InitialTime=1.297854e-03 FinalTime=1.297855e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_erase_hold_"
  Transient (
    InitialTime=1.297855e-03 FinalTime=1.307855e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2976e-03 1.3076e-03) Intervals=40) ) }
  NewCurrentPrefix="c17_erase_fall_"
  Transient (
    InitialTime=1.307855e-03 FinalTime=1.307856e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 17 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c17_relax_"
  Transient (
    InitialTime=1.307856e-03 FinalTime=1.377856e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3076e-03 1.3776e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 18 (cycle base time = 1.3776e-03)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c18_p1_rise_"
  Transient (
    InitialTime=1.377856e-03 FinalTime=1.377857e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p1_write_"
  Transient (
    InitialTime=1.377857e-03 FinalTime=1.377957e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3776e-03 1.3777e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p1_fall_"
  Transient (
    InitialTime=1.377957e-03 FinalTime=1.377958e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p2_rise_"
  Transient (
    InitialTime=1.377958e-03 FinalTime=1.377959e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p2_write_"
  Transient (
    InitialTime=1.377959e-03 FinalTime=1.378059e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3777e-03 1.3778e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p2_fall_"
  Transient (
    InitialTime=1.378059e-03 FinalTime=1.378060e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p3_rise_"
  Transient (
    InitialTime=1.378060e-03 FinalTime=1.378160e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p3_write_"
  Transient (
    InitialTime=1.378160e-03 FinalTime=1.378260e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3779e-03 1.3780e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p3_fall_"
  Transient (
    InitialTime=1.378260e-03 FinalTime=1.378261e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p4_rise_"
  Transient (
    InitialTime=1.378261e-03 FinalTime=1.378262e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p4_write_"
  Transient (
    InitialTime=1.378262e-03 FinalTime=1.378362e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3780e-03 1.3781e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p4_fall_"
  Transient (
    InitialTime=1.378362e-03 FinalTime=1.378363e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p5_rise_"
  Transient (
    InitialTime=1.378363e-03 FinalTime=1.378364e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p5_write_"
  Transient (
    InitialTime=1.378364e-03 FinalTime=1.378464e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3781e-03 1.3782e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p5_fall_"
  Transient (
    InitialTime=1.378464e-03 FinalTime=1.378465e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p6_rise_"
  Transient (
    InitialTime=1.378465e-03 FinalTime=1.378466e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p6_write_"
  Transient (
    InitialTime=1.378466e-03 FinalTime=1.378566e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3782e-03 1.3783e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p6_fall_"
  Transient (
    InitialTime=1.378566e-03 FinalTime=1.378567e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p7_rise_"
  Transient (
    InitialTime=1.378567e-03 FinalTime=1.378568e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p7_write_"
  Transient (
    InitialTime=1.378568e-03 FinalTime=1.378668e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3783e-03 1.3784e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p7_fall_"
  Transient (
    InitialTime=1.378668e-03 FinalTime=1.378669e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p8_rise_"
  Transient (
    InitialTime=1.378669e-03 FinalTime=1.378670e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p8_write_"
  Transient (
    InitialTime=1.378670e-03 FinalTime=1.378770e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3784e-03 1.3785e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p8_fall_"
  Transient (
    InitialTime=1.378770e-03 FinalTime=1.378771e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p9_rise_"
  Transient (
    InitialTime=1.378771e-03 FinalTime=1.378772e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p9_write_"
  Transient (
    InitialTime=1.378772e-03 FinalTime=1.378872e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3785e-03 1.3786e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p9_fall_"
  Transient (
    InitialTime=1.378872e-03 FinalTime=1.378873e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_burst_read_"
  Transient (
    InitialTime=1.378873e-03 FinalTime=1.378973e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3786e-03 1.3787e-03) Intervals=20) ) }
  *--- CYCLE 18 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c18_erase_rise_"
  Transient (
    InitialTime=1.378973e-03 FinalTime=1.378974e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_erase_hold_"
  Transient (
    InitialTime=1.378974e-03 FinalTime=1.388974e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3787e-03 1.3887e-03) Intervals=40) ) }
  NewCurrentPrefix="c18_erase_fall_"
  Transient (
    InitialTime=1.388974e-03 FinalTime=1.388975e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 18 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c18_relax_"
  Transient (
    InitialTime=1.388975e-03 FinalTime=1.458975e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3887e-03 1.4587e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 19 (cycle base time = 1.4587e-03)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c19_p1_rise_"
  Transient (
    InitialTime=1.458975e-03 FinalTime=1.458976e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p1_write_"
  Transient (
    InitialTime=1.458976e-03 FinalTime=1.459076e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4587e-03 1.4588e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p1_fall_"
  Transient (
    InitialTime=1.459076e-03 FinalTime=1.459077e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p2_rise_"
  Transient (
    InitialTime=1.459077e-03 FinalTime=1.459078e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p2_write_"
  Transient (
    InitialTime=1.459078e-03 FinalTime=1.459178e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4588e-03 1.4589e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p2_fall_"
  Transient (
    InitialTime=1.459178e-03 FinalTime=1.459179e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p3_rise_"
  Transient (
    InitialTime=1.459179e-03 FinalTime=1.459180e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p3_write_"
  Transient (
    InitialTime=1.459180e-03 FinalTime=1.459280e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4589e-03 1.4590e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p3_fall_"
  Transient (
    InitialTime=1.459280e-03 FinalTime=1.459281e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p4_rise_"
  Transient (
    InitialTime=1.459281e-03 FinalTime=1.459282e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p4_write_"
  Transient (
    InitialTime=1.459282e-03 FinalTime=1.459382e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4590e-03 1.4591e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p4_fall_"
  Transient (
    InitialTime=1.459382e-03 FinalTime=1.459383e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p5_rise_"
  Transient (
    InitialTime=1.459383e-03 FinalTime=1.459384e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p5_write_"
  Transient (
    InitialTime=1.459384e-03 FinalTime=1.459484e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4591e-03 1.4592e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p5_fall_"
  Transient (
    InitialTime=1.459484e-03 FinalTime=1.459485e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p6_rise_"
  Transient (
    InitialTime=1.459485e-03 FinalTime=1.459486e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p6_write_"
  Transient (
    InitialTime=1.459486e-03 FinalTime=1.459586e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4592e-03 1.4593e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p6_fall_"
  Transient (
    InitialTime=1.459586e-03 FinalTime=1.459587e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p7_rise_"
  Transient (
    InitialTime=1.459587e-03 FinalTime=1.459588e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p7_write_"
  Transient (
    InitialTime=1.459588e-03 FinalTime=1.459688e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4593e-03 1.4594e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p7_fall_"
  Transient (
    InitialTime=1.459688e-03 FinalTime=1.459689e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p8_rise_"
  Transient (
    InitialTime=1.459689e-03 FinalTime=1.459690e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p8_write_"
  Transient (
    InitialTime=1.459690e-03 FinalTime=1.459790e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4594e-03 1.4595e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p8_fall_"
  Transient (
    InitialTime=1.459790e-03 FinalTime=1.459791e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p9_rise_"
  Transient (
    InitialTime=1.459791e-03 FinalTime=1.459792e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p9_write_"
  Transient (
    InitialTime=1.459792e-03 FinalTime=1.459892e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4595e-03 1.4596e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p9_fall_"
  Transient (
    InitialTime=1.459892e-03 FinalTime=1.459893e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_burst_read_"
  Transient (
    InitialTime=1.459893e-03 FinalTime=1.459993e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4596e-03 1.4597e-03) Intervals=20) ) }
  *--- CYCLE 19 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c19_erase_rise_"
  Transient (
    InitialTime=1.459993e-03 FinalTime=1.459994e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_erase_hold_"
  Transient (
    InitialTime=1.459994e-03 FinalTime=1.469994e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4597e-03 1.4697e-03) Intervals=40) ) }
  NewCurrentPrefix="c19_erase_fall_"
  Transient (
    InitialTime=1.469994e-03 FinalTime=1.469995e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 19 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c19_relax_"
  Transient (
    InitialTime=1.469995e-03 FinalTime=1.539995e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4697e-03 1.5397e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 20 (cycle base time = 1.5397e-03)  --- DEFERRED READ ---
  *====================================================================
  NewCurrentPrefix="c20_p1_rise_"
  Transient (
    InitialTime=1.539995e-03 FinalTime=1.539996e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p1_write_"
  Transient (
    InitialTime=1.539996e-03 FinalTime=1.540096e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5397e-03 1.5398e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p1_fall_"
  Transient (
    InitialTime=1.540096e-03 FinalTime=1.540097e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p2_rise_"
  Transient (
    InitialTime=1.540097e-03 FinalTime=1.540098e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p2_write_"
  Transient (
    InitialTime=1.540098e-03 FinalTime=1.540198e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5398e-03 1.5399e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p2_fall_"
  Transient (
    InitialTime=1.540198e-03 FinalTime=1.540199e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p3_rise_"
  Transient (
    InitialTime=1.540199e-03 FinalTime=1.540200e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p3_write_"
  Transient (
    InitialTime=1.540200e-03 FinalTime=1.540300e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5399e-03 1.5400e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p3_fall_"
  Transient (
    InitialTime=1.540300e-03 FinalTime=1.540301e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p4_rise_"
  Transient (
    InitialTime=1.540301e-03 FinalTime=1.540302e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p4_write_"
  Transient (
    InitialTime=1.540302e-03 FinalTime=1.540402e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5400e-03 1.5401e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p4_fall_"
  Transient (
    InitialTime=1.540402e-03 FinalTime=1.540403e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p5_rise_"
  Transient (
    InitialTime=1.540403e-03 FinalTime=1.540404e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p5_write_"
  Transient (
    InitialTime=1.540404e-03 FinalTime=1.540504e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5401e-03 1.5402e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p5_fall_"
  Transient (
    InitialTime=1.540504e-03 FinalTime=1.540505e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p6_rise_"
  Transient (
    InitialTime=1.540505e-03 FinalTime=1.540506e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p6_write_"
  Transient (
    InitialTime=1.540506e-03 FinalTime=1.540606e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5402e-03 1.5403e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p6_fall_"
  Transient (
    InitialTime=1.540606e-03 FinalTime=1.540607e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p7_rise_"
  Transient (
    InitialTime=1.540607e-03 FinalTime=1.540608e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p7_write_"
  Transient (
    InitialTime=1.540608e-03 FinalTime=1.540708e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5403e-03 1.5404e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p7_fall_"
  Transient (
    InitialTime=1.540708e-03 FinalTime=1.540709e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p8_rise_"
  Transient (
    InitialTime=1.540709e-03 FinalTime=1.540710e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p8_write_"
  Transient (
    InitialTime=1.540710e-03 FinalTime=1.540810e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5404e-03 1.5405e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p8_fall_"
  Transient (
    InitialTime=1.540810e-03 FinalTime=1.540811e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p9_rise_"
  Transient (
    InitialTime=1.540811e-03 FinalTime=1.540812e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.000 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p9_write_"
  Transient (
    InitialTime=1.540812e-03 FinalTime=1.540912e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5405e-03 1.5406e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p9_fall_"
  Transient (
    InitialTime=1.540912e-03 FinalTime=1.540913e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_burst_read_"
  Transient (
    InitialTime=1.540913e-03 FinalTime=1.541013e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5406e-03 1.5407e-03) Intervals=20) ) }
  *--- CYCLE 20 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c20_erase_rise_"
  Transient (
    InitialTime=1.541013e-03 FinalTime=1.541014e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_erase_hold_"
  Transient (
    InitialTime=1.541014e-03 FinalTime=1.551014e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5407e-03 1.5507e-03) Intervals=40) ) }
  NewCurrentPrefix="c20_erase_fall_"
  Transient (
    InitialTime=1.551014e-03 FinalTime=1.551114e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 20 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c20_relax_"
  Transient (
    InitialTime=1.551114e-03 FinalTime=1.621114e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5508e-03 1.6208e-03) Intervals=70) ) }

}

*===================================================================
*== POST-PROCESSING (extend analyze_phase1d_h4.py):
*==   per cycle: ID_burst_read_cN  (single read instead of 9)
*==   fire_ratio_cN = ID_burst_read_cN / ID_baseline_pre or relax_(N-1)
*==   E_per_pulse_eq = E_burst / N_FIRES (gate+drain integrated over
*==                    every cN_*_endurance_des.plt at V_pgm=2.0 V node)
*===================================================================
