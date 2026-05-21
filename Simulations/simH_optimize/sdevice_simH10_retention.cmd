*===================================================================
*== PHASE 1D - H10 RETENTION SWEEP (@t_hold@ at V_GS = 0 V)
*==
*== Single 9-pulse fire burst at V_pgm = 2.0 V, then hold at V_GS = 0 V
*== for @t_hold@ seconds (Quasistationary -> Sentaurus pseudo-time).
*== Final 100 ns transient read at V_GS = -0.5 V to capture retained ID.
*==
*== SWB sweep: @t_hold@ in {10, 100, 1000} s (3 nodes).
*==
*== Acceptance (publication-soft):
*==   ID(t_hold=1000s) / ID(t_hold=10s) >= 0.5   (50% retention at 1ks)
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

  *=== 9-pulse fire burst at V_pgm = 2.0 V ===
  NewCurrentPrefix="p1_rise_"
  Transient (
    InitialTime=0.0000000000e+00 FinalTime=1.0000000000e-09
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p1_write_"
  Transient (
    InitialTime=1.0000000000e-09 FinalTime=1.0100000000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0000000000e-09 1.0100000000e-07) Intervals=10) ) }
  NewCurrentPrefix="p1_fall_"
  Transient (
    InitialTime=1.0100000000e-07 FinalTime=1.0200000000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p1_read_"
  Transient (
    InitialTime=1.0200000000e-07 FinalTime=2.0200000000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0200000000e-07 2.0200000000e-07) Intervals=20) ) }
  NewCurrentPrefix="p2_rise_"
  Transient (
    InitialTime=2.0200000000e-07 FinalTime=2.0300000000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p2_write_"
  Transient (
    InitialTime=2.0300000000e-07 FinalTime=3.0300000000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0300000000e-07 3.0300000000e-07) Intervals=10) ) }
  NewCurrentPrefix="p2_fall_"
  Transient (
    InitialTime=3.0300000000e-07 FinalTime=3.0400000000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p2_read_"
  Transient (
    InitialTime=3.0400000000e-07 FinalTime=4.0400000000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0400000000e-07 4.0400000000e-07) Intervals=20) ) }
  NewCurrentPrefix="p3_rise_"
  Transient (
    InitialTime=4.0400000000e-07 FinalTime=4.0500000000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p3_write_"
  Transient (
    InitialTime=4.0500000000e-07 FinalTime=5.0500000000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0500000000e-07 5.0500000000e-07) Intervals=10) ) }
  NewCurrentPrefix="p3_fall_"
  Transient (
    InitialTime=5.0500000000e-07 FinalTime=5.0600000000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p3_read_"
  Transient (
    InitialTime=5.0600000000e-07 FinalTime=6.0600000000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0600000000e-07 6.0600000000e-07) Intervals=20) ) }
  NewCurrentPrefix="p4_rise_"
  Transient (
    InitialTime=6.0600000000e-07 FinalTime=6.0700000000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p4_write_"
  Transient (
    InitialTime=6.0700000000e-07 FinalTime=7.0700000000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0700000000e-07 7.0700000000e-07) Intervals=10) ) }
  NewCurrentPrefix="p4_fall_"
  Transient (
    InitialTime=7.0700000000e-07 FinalTime=7.0800000000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p4_read_"
  Transient (
    InitialTime=7.0800000000e-07 FinalTime=8.0800000000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0800000000e-07 8.0800000000e-07) Intervals=20) ) }
  NewCurrentPrefix="p5_rise_"
  Transient (
    InitialTime=8.0800000000e-07 FinalTime=8.0900000000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p5_write_"
  Transient (
    InitialTime=8.0900000000e-07 FinalTime=9.0900000000e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0900000000e-07 9.0900000000e-07) Intervals=10) ) }
  NewCurrentPrefix="p5_fall_"
  Transient (
    InitialTime=9.0900000000e-07 FinalTime=9.1000000000e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p5_read_"
  Transient (
    InitialTime=9.1000000000e-07 FinalTime=1.0100000000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1000000000e-07 1.0100000000e-06) Intervals=20) ) }
  NewCurrentPrefix="p6_rise_"
  Transient (
    InitialTime=1.0100000000e-06 FinalTime=1.0110000000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p6_write_"
  Transient (
    InitialTime=1.0110000000e-06 FinalTime=1.1110000000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0110000000e-06 1.1110000000e-06) Intervals=10) ) }
  NewCurrentPrefix="p6_fall_"
  Transient (
    InitialTime=1.1110000000e-06 FinalTime=1.1120000000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p6_read_"
  Transient (
    InitialTime=1.1120000000e-06 FinalTime=1.2120000000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1120000000e-06 1.2120000000e-06) Intervals=20) ) }
  NewCurrentPrefix="p7_rise_"
  Transient (
    InitialTime=1.2120000000e-06 FinalTime=1.2130000000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p7_write_"
  Transient (
    InitialTime=1.2130000000e-06 FinalTime=1.3130000000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2130000000e-06 1.3130000000e-06) Intervals=10) ) }
  NewCurrentPrefix="p7_fall_"
  Transient (
    InitialTime=1.3130000000e-06 FinalTime=1.3140000000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p7_read_"
  Transient (
    InitialTime=1.3140000000e-06 FinalTime=1.4140000000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3140000000e-06 1.4140000000e-06) Intervals=20) ) }
  NewCurrentPrefix="p8_rise_"
  Transient (
    InitialTime=1.4140000000e-06 FinalTime=1.4150000000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p8_write_"
  Transient (
    InitialTime=1.4150000000e-06 FinalTime=1.5150000000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4150000000e-06 1.5150000000e-06) Intervals=10) ) }
  NewCurrentPrefix="p8_fall_"
  Transient (
    InitialTime=1.5150000000e-06 FinalTime=1.5160000000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p8_read_"
  Transient (
    InitialTime=1.5160000000e-06 FinalTime=1.6160000000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5160000000e-06 1.6160000000e-06) Intervals=20) ) }
  NewCurrentPrefix="p9_rise_"
  Transient (
    InitialTime=1.6160000000e-06 FinalTime=1.6170000000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p9_write_"
  Transient (
    InitialTime=1.6170000000e-06 FinalTime=1.7170000000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6170000000e-06 1.7170000000e-06) Intervals=10) ) }
  NewCurrentPrefix="p9_fall_"
  Transient (
    InitialTime=1.7170000000e-06 FinalTime=1.7180000000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="p9_read_"
  Transient (
    InitialTime=1.7180000000e-06 FinalTime=1.8180000000e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7180000000e-06 1.8180000000e-06) Intervals=20) ) }
  NewCurrentPrefix="ramp_to_hold_"
  Transient (
    InitialTime=1.8180000000e-06 FinalTime=1.8280000000e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== HOLD at V_GS = 0 V for @t_hold@ s (Quasistationary) ===
  NewCurrentPrefix="retention_hold_"
  Quasistationary (
    InitialStep=1e-3 MaxStep=0.05 MinStep=1e-7
    Goal { Parameter=time Value= @t_hold@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="post_hold_ramp_"
  Transient (
    InitialTime=1.0000018280e+00 FinalTime=1.0000018380e+00
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="post_hold_read_"
  Transient (
    InitialTime=1.0000018380e+00 FinalTime=1.0000019380e+00
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0000018380e+00 1.0000019380e+00) Intervals=20) ) }

}
