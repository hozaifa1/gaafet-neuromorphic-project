*===================================================================
*== PHASE 1D - H4 ENDURANCE: 20-cycle LIF + V_pgm variability sweep
*==
*== Per-cycle phases (identical to H3 Step 3b):
*==   (a) 9 program pulses at V_pgm=@V_pgm@ V (100ns hold, 100ns sub-Vt read)
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
*==   (M8)     sigma/mu of fire_ratio across V_pgm nodes (c10..c20) <= 5 %
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
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
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
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
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
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
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
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
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
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
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
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
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
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
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
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
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
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
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
  *--- CYCLE 1 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c1_erase_rise_"
  Transient (
    InitialTime=1.8180e-06 FinalTime=1.8280e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_erase_hold_"
  Transient (
    InitialTime=1.8280e-06 FinalTime=1.1828e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.8280e-06 1.1828e-05) Intervals=40) ) }
  NewCurrentPrefix="c1_erase_fall_"
  Transient (
    InitialTime=1.1828e-05 FinalTime=1.1838e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 1 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c1_relax_"
  Transient (
    InitialTime=1.1838e-05 FinalTime=8.1838e-05
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1838e-05 8.1838e-05) Intervals=70) ) }

  *====================================================================
  *== CYCLE 2 (cycle base time = 8.1838e-05)
  *====================================================================
  NewCurrentPrefix="c2_p1_rise_"
  Transient (
    InitialTime=8.1838e-05 FinalTime=8.1839e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_write_"
  Transient (
    InitialTime=8.1839e-05 FinalTime=8.1939e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1839e-05 8.1939e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p1_fall_"
  Transient (
    InitialTime=8.1939e-05 FinalTime=8.1940e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_read_"
  Transient (
    InitialTime=8.1940e-05 FinalTime=8.2040e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1940e-05 8.2040e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p2_rise_"
  Transient (
    InitialTime=8.2040e-05 FinalTime=8.2041e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_write_"
  Transient (
    InitialTime=8.2041e-05 FinalTime=8.2141e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2041e-05 8.2141e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p2_fall_"
  Transient (
    InitialTime=8.2141e-05 FinalTime=8.2142e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_read_"
  Transient (
    InitialTime=8.2142e-05 FinalTime=8.2242e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2142e-05 8.2242e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p3_rise_"
  Transient (
    InitialTime=8.2242e-05 FinalTime=8.2243e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_write_"
  Transient (
    InitialTime=8.2243e-05 FinalTime=8.2343e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2243e-05 8.2343e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p3_fall_"
  Transient (
    InitialTime=8.2343e-05 FinalTime=8.2344e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_read_"
  Transient (
    InitialTime=8.2344e-05 FinalTime=8.2444e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2344e-05 8.2444e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p4_rise_"
  Transient (
    InitialTime=8.2444e-05 FinalTime=8.2445e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p4_write_"
  Transient (
    InitialTime=8.2445e-05 FinalTime=8.2545e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2445e-05 8.2545e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p4_fall_"
  Transient (
    InitialTime=8.2545e-05 FinalTime=8.2546e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p4_read_"
  Transient (
    InitialTime=8.2546e-05 FinalTime=8.2646e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2546e-05 8.2646e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p5_rise_"
  Transient (
    InitialTime=8.2646e-05 FinalTime=8.2647e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p5_write_"
  Transient (
    InitialTime=8.2647e-05 FinalTime=8.2747e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2647e-05 8.2747e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p5_fall_"
  Transient (
    InitialTime=8.2747e-05 FinalTime=8.2748e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p5_read_"
  Transient (
    InitialTime=8.2748e-05 FinalTime=8.2848e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2748e-05 8.2848e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p6_rise_"
  Transient (
    InitialTime=8.2848e-05 FinalTime=8.2849e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p6_write_"
  Transient (
    InitialTime=8.2849e-05 FinalTime=8.2949e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2849e-05 8.2949e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p6_fall_"
  Transient (
    InitialTime=8.2949e-05 FinalTime=8.2950e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p6_read_"
  Transient (
    InitialTime=8.2950e-05 FinalTime=8.3050e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2950e-05 8.3050e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p7_rise_"
  Transient (
    InitialTime=8.3050e-05 FinalTime=8.3051e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p7_write_"
  Transient (
    InitialTime=8.3051e-05 FinalTime=8.3151e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3051e-05 8.3151e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p7_fall_"
  Transient (
    InitialTime=8.3151e-05 FinalTime=8.3152e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p7_read_"
  Transient (
    InitialTime=8.3152e-05 FinalTime=8.3252e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3152e-05 8.3252e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p8_rise_"
  Transient (
    InitialTime=8.3252e-05 FinalTime=8.3253e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p8_write_"
  Transient (
    InitialTime=8.3253e-05 FinalTime=8.3353e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3253e-05 8.3353e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p8_fall_"
  Transient (
    InitialTime=8.3353e-05 FinalTime=8.3354e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p8_read_"
  Transient (
    InitialTime=8.3354e-05 FinalTime=8.3454e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3354e-05 8.3454e-05) Intervals=20) ) }
  NewCurrentPrefix="c2_p9_rise_"
  Transient (
    InitialTime=8.3454e-05 FinalTime=8.3455e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p9_write_"
  Transient (
    InitialTime=8.3455e-05 FinalTime=8.3555e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3455e-05 8.3555e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p9_fall_"
  Transient (
    InitialTime=8.3555e-05 FinalTime=8.3556e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p9_read_"
  Transient (
    InitialTime=8.3556e-05 FinalTime=8.3656e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3556e-05 8.3656e-05) Intervals=20) ) }
  *--- CYCLE 2 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c2_erase_rise_"
  Transient (
    InitialTime=8.3656e-05 FinalTime=8.3666e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_erase_hold_"
  Transient (
    InitialTime=8.3666e-05 FinalTime=9.3666e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3666e-05 9.3666e-05) Intervals=40) ) }
  NewCurrentPrefix="c2_erase_fall_"
  Transient (
    InitialTime=9.3666e-05 FinalTime=9.3676e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 2 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c2_relax_"
  Transient (
    InitialTime=9.3676e-05 FinalTime=1.6368e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.3676e-05 1.6368e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 3 (cycle base time = 1.6368e-04)
  *====================================================================
  NewCurrentPrefix="c3_p1_rise_"
  Transient (
    InitialTime=1.6368e-04 FinalTime=1.6368e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_write_"
  Transient (
    InitialTime=1.6368e-04 FinalTime=1.6378e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6368e-04 1.6378e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p1_fall_"
  Transient (
    InitialTime=1.6378e-04 FinalTime=1.6378e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_read_"
  Transient (
    InitialTime=1.6378e-04 FinalTime=1.6388e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6378e-04 1.6388e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p2_rise_"
  Transient (
    InitialTime=1.6388e-04 FinalTime=1.6388e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_write_"
  Transient (
    InitialTime=1.6388e-04 FinalTime=1.6398e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6388e-04 1.6398e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p2_fall_"
  Transient (
    InitialTime=1.6398e-04 FinalTime=1.6398e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_read_"
  Transient (
    InitialTime=1.6398e-04 FinalTime=1.6408e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6398e-04 1.6408e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p3_rise_"
  Transient (
    InitialTime=1.6408e-04 FinalTime=1.6408e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_write_"
  Transient (
    InitialTime=1.6408e-04 FinalTime=1.6418e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6408e-04 1.6418e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p3_fall_"
  Transient (
    InitialTime=1.6418e-04 FinalTime=1.6418e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_read_"
  Transient (
    InitialTime=1.6418e-04 FinalTime=1.6428e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6418e-04 1.6428e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p4_rise_"
  Transient (
    InitialTime=1.6428e-04 FinalTime=1.6428e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p4_write_"
  Transient (
    InitialTime=1.6428e-04 FinalTime=1.6438e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6428e-04 1.6438e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p4_fall_"
  Transient (
    InitialTime=1.6438e-04 FinalTime=1.6438e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p4_read_"
  Transient (
    InitialTime=1.6438e-04 FinalTime=1.6448e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6438e-04 1.6448e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p5_rise_"
  Transient (
    InitialTime=1.6448e-04 FinalTime=1.6448e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p5_write_"
  Transient (
    InitialTime=1.6448e-04 FinalTime=1.6458e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6448e-04 1.6458e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p5_fall_"
  Transient (
    InitialTime=1.6458e-04 FinalTime=1.6459e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p5_read_"
  Transient (
    InitialTime=1.6459e-04 FinalTime=1.6469e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6459e-04 1.6469e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p6_rise_"
  Transient (
    InitialTime=1.6469e-04 FinalTime=1.6469e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p6_write_"
  Transient (
    InitialTime=1.6469e-04 FinalTime=1.6479e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6469e-04 1.6479e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p6_fall_"
  Transient (
    InitialTime=1.6479e-04 FinalTime=1.6479e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p6_read_"
  Transient (
    InitialTime=1.6479e-04 FinalTime=1.6489e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6479e-04 1.6489e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p7_rise_"
  Transient (
    InitialTime=1.6489e-04 FinalTime=1.6489e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p7_write_"
  Transient (
    InitialTime=1.6489e-04 FinalTime=1.6499e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6489e-04 1.6499e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p7_fall_"
  Transient (
    InitialTime=1.6499e-04 FinalTime=1.6499e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p7_read_"
  Transient (
    InitialTime=1.6499e-04 FinalTime=1.6509e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6499e-04 1.6509e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p8_rise_"
  Transient (
    InitialTime=1.6509e-04 FinalTime=1.6509e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p8_write_"
  Transient (
    InitialTime=1.6509e-04 FinalTime=1.6519e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6509e-04 1.6519e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p8_fall_"
  Transient (
    InitialTime=1.6519e-04 FinalTime=1.6519e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p8_read_"
  Transient (
    InitialTime=1.6519e-04 FinalTime=1.6529e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6519e-04 1.6529e-04) Intervals=20) ) }
  NewCurrentPrefix="c3_p9_rise_"
  Transient (
    InitialTime=1.6529e-04 FinalTime=1.6529e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p9_write_"
  Transient (
    InitialTime=1.6529e-04 FinalTime=1.6539e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6529e-04 1.6539e-04) Intervals=10) ) }
  NewCurrentPrefix="c3_p9_fall_"
  Transient (
    InitialTime=1.6539e-04 FinalTime=1.6539e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p9_read_"
  Transient (
    InitialTime=1.6539e-04 FinalTime=1.6549e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6539e-04 1.6549e-04) Intervals=20) ) }
  *--- CYCLE 3 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c3_erase_rise_"
  Transient (
    InitialTime=1.6549e-04 FinalTime=1.6550e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_erase_hold_"
  Transient (
    InitialTime=1.6550e-04 FinalTime=1.7550e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6550e-04 1.7550e-04) Intervals=40) ) }
  NewCurrentPrefix="c3_erase_fall_"
  Transient (
    InitialTime=1.7550e-04 FinalTime=1.7551e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 3 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c3_relax_"
  Transient (
    InitialTime=1.7551e-04 FinalTime=2.4551e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7551e-04 2.4551e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 4 (cycle base time = 2.4551e-04)
  *====================================================================
  NewCurrentPrefix="c4_p1_rise_"
  Transient (
    InitialTime=2.4551e-04 FinalTime=2.4552e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p1_write_"
  Transient (
    InitialTime=2.4552e-04 FinalTime=2.4562e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4552e-04 2.4562e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p1_fall_"
  Transient (
    InitialTime=2.4562e-04 FinalTime=2.4562e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p1_read_"
  Transient (
    InitialTime=2.4562e-04 FinalTime=2.4572e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4562e-04 2.4572e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p2_rise_"
  Transient (
    InitialTime=2.4572e-04 FinalTime=2.4572e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_write_"
  Transient (
    InitialTime=2.4572e-04 FinalTime=2.4582e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4572e-04 2.4582e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p2_fall_"
  Transient (
    InitialTime=2.4582e-04 FinalTime=2.4582e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_read_"
  Transient (
    InitialTime=2.4582e-04 FinalTime=2.4592e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4582e-04 2.4592e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p3_rise_"
  Transient (
    InitialTime=2.4592e-04 FinalTime=2.4592e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_write_"
  Transient (
    InitialTime=2.4592e-04 FinalTime=2.4602e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4592e-04 2.4602e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p3_fall_"
  Transient (
    InitialTime=2.4602e-04 FinalTime=2.4602e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_read_"
  Transient (
    InitialTime=2.4602e-04 FinalTime=2.4612e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4602e-04 2.4612e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p4_rise_"
  Transient (
    InitialTime=2.4612e-04 FinalTime=2.4612e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p4_write_"
  Transient (
    InitialTime=2.4612e-04 FinalTime=2.4622e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4612e-04 2.4622e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p4_fall_"
  Transient (
    InitialTime=2.4622e-04 FinalTime=2.4622e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p4_read_"
  Transient (
    InitialTime=2.4622e-04 FinalTime=2.4632e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4622e-04 2.4632e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p5_rise_"
  Transient (
    InitialTime=2.4632e-04 FinalTime=2.4632e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p5_write_"
  Transient (
    InitialTime=2.4632e-04 FinalTime=2.4642e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4632e-04 2.4642e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p5_fall_"
  Transient (
    InitialTime=2.4642e-04 FinalTime=2.4642e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p5_read_"
  Transient (
    InitialTime=2.4642e-04 FinalTime=2.4652e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4642e-04 2.4652e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p6_rise_"
  Transient (
    InitialTime=2.4652e-04 FinalTime=2.4653e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p6_write_"
  Transient (
    InitialTime=2.4653e-04 FinalTime=2.4663e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4653e-04 2.4663e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p6_fall_"
  Transient (
    InitialTime=2.4663e-04 FinalTime=2.4663e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p6_read_"
  Transient (
    InitialTime=2.4663e-04 FinalTime=2.4673e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4663e-04 2.4673e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p7_rise_"
  Transient (
    InitialTime=2.4673e-04 FinalTime=2.4673e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p7_write_"
  Transient (
    InitialTime=2.4673e-04 FinalTime=2.4683e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4673e-04 2.4683e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p7_fall_"
  Transient (
    InitialTime=2.4683e-04 FinalTime=2.4683e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p7_read_"
  Transient (
    InitialTime=2.4683e-04 FinalTime=2.4693e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4683e-04 2.4693e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p8_rise_"
  Transient (
    InitialTime=2.4693e-04 FinalTime=2.4693e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p8_write_"
  Transient (
    InitialTime=2.4693e-04 FinalTime=2.4703e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4693e-04 2.4703e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p8_fall_"
  Transient (
    InitialTime=2.4703e-04 FinalTime=2.4703e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p8_read_"
  Transient (
    InitialTime=2.4703e-04 FinalTime=2.4713e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4703e-04 2.4713e-04) Intervals=20) ) }
  NewCurrentPrefix="c4_p9_rise_"
  Transient (
    InitialTime=2.4713e-04 FinalTime=2.4713e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p9_write_"
  Transient (
    InitialTime=2.4713e-04 FinalTime=2.4723e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4713e-04 2.4723e-04) Intervals=10) ) }
  NewCurrentPrefix="c4_p9_fall_"
  Transient (
    InitialTime=2.4723e-04 FinalTime=2.4723e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p9_read_"
  Transient (
    InitialTime=2.4723e-04 FinalTime=2.4733e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4723e-04 2.4733e-04) Intervals=20) ) }
  *--- CYCLE 4 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c4_erase_rise_"
  Transient (
    InitialTime=2.4733e-04 FinalTime=2.4734e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_erase_hold_"
  Transient (
    InitialTime=2.4734e-04 FinalTime=2.5734e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4734e-04 2.5734e-04) Intervals=40) ) }
  NewCurrentPrefix="c4_erase_fall_"
  Transient (
    InitialTime=2.5734e-04 FinalTime=2.5735e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 4 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c4_relax_"
  Transient (
    InitialTime=2.5735e-04 FinalTime=3.2735e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.5735e-04 3.2735e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 5 (cycle base time = 3.2735e-04)
  *====================================================================
  NewCurrentPrefix="c5_p1_rise_"
  Transient (
    InitialTime=3.2735e-04 FinalTime=3.2735e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p1_write_"
  Transient (
    InitialTime=3.2735e-04 FinalTime=3.2745e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2735e-04 3.2745e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p1_fall_"
  Transient (
    InitialTime=3.2745e-04 FinalTime=3.2745e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p1_read_"
  Transient (
    InitialTime=3.2745e-04 FinalTime=3.2755e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2745e-04 3.2755e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p2_rise_"
  Transient (
    InitialTime=3.2755e-04 FinalTime=3.2755e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_write_"
  Transient (
    InitialTime=3.2755e-04 FinalTime=3.2765e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2755e-04 3.2765e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p2_fall_"
  Transient (
    InitialTime=3.2765e-04 FinalTime=3.2766e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_read_"
  Transient (
    InitialTime=3.2766e-04 FinalTime=3.2776e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2766e-04 3.2776e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p3_rise_"
  Transient (
    InitialTime=3.2776e-04 FinalTime=3.2776e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_write_"
  Transient (
    InitialTime=3.2776e-04 FinalTime=3.2786e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2776e-04 3.2786e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p3_fall_"
  Transient (
    InitialTime=3.2786e-04 FinalTime=3.2786e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_read_"
  Transient (
    InitialTime=3.2786e-04 FinalTime=3.2796e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2786e-04 3.2796e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p4_rise_"
  Transient (
    InitialTime=3.2796e-04 FinalTime=3.2796e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p4_write_"
  Transient (
    InitialTime=3.2796e-04 FinalTime=3.2806e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2796e-04 3.2806e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p4_fall_"
  Transient (
    InitialTime=3.2806e-04 FinalTime=3.2806e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p4_read_"
  Transient (
    InitialTime=3.2806e-04 FinalTime=3.2816e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2806e-04 3.2816e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p5_rise_"
  Transient (
    InitialTime=3.2816e-04 FinalTime=3.2816e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p5_write_"
  Transient (
    InitialTime=3.2816e-04 FinalTime=3.2826e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2816e-04 3.2826e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p5_fall_"
  Transient (
    InitialTime=3.2826e-04 FinalTime=3.2826e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p5_read_"
  Transient (
    InitialTime=3.2826e-04 FinalTime=3.2836e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2826e-04 3.2836e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p6_rise_"
  Transient (
    InitialTime=3.2836e-04 FinalTime=3.2836e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p6_write_"
  Transient (
    InitialTime=3.2836e-04 FinalTime=3.2846e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2836e-04 3.2846e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p6_fall_"
  Transient (
    InitialTime=3.2846e-04 FinalTime=3.2846e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p6_read_"
  Transient (
    InitialTime=3.2846e-04 FinalTime=3.2856e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2846e-04 3.2856e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p7_rise_"
  Transient (
    InitialTime=3.2856e-04 FinalTime=3.2857e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p7_write_"
  Transient (
    InitialTime=3.2857e-04 FinalTime=3.2867e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2857e-04 3.2867e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p7_fall_"
  Transient (
    InitialTime=3.2867e-04 FinalTime=3.2867e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p7_read_"
  Transient (
    InitialTime=3.2867e-04 FinalTime=3.2877e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2867e-04 3.2877e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p8_rise_"
  Transient (
    InitialTime=3.2877e-04 FinalTime=3.2877e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p8_write_"
  Transient (
    InitialTime=3.2877e-04 FinalTime=3.2887e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2877e-04 3.2887e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p8_fall_"
  Transient (
    InitialTime=3.2887e-04 FinalTime=3.2887e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p8_read_"
  Transient (
    InitialTime=3.2887e-04 FinalTime=3.2897e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2887e-04 3.2897e-04) Intervals=20) ) }
  NewCurrentPrefix="c5_p9_rise_"
  Transient (
    InitialTime=3.2897e-04 FinalTime=3.2897e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p9_write_"
  Transient (
    InitialTime=3.2897e-04 FinalTime=3.2907e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2897e-04 3.2907e-04) Intervals=10) ) }
  NewCurrentPrefix="c5_p9_fall_"
  Transient (
    InitialTime=3.2907e-04 FinalTime=3.2907e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p9_read_"
  Transient (
    InitialTime=3.2907e-04 FinalTime=3.2917e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2907e-04 3.2917e-04) Intervals=20) ) }
  *--- CYCLE 5 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c5_erase_rise_"
  Transient (
    InitialTime=3.2917e-04 FinalTime=3.2918e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_erase_hold_"
  Transient (
    InitialTime=3.2918e-04 FinalTime=3.3918e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2918e-04 3.3918e-04) Intervals=40) ) }
  NewCurrentPrefix="c5_erase_fall_"
  Transient (
    InitialTime=3.3918e-04 FinalTime=3.3919e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 5 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c5_relax_"
  Transient (
    InitialTime=3.3919e-04 FinalTime=4.0919e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.3919e-04 4.0919e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 6 (cycle base time = 4.0919e-04)
  *====================================================================
  NewCurrentPrefix="c6_p1_rise_"
  Transient (
    InitialTime=4.0919e-04 FinalTime=4.0919e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p1_write_"
  Transient (
    InitialTime=4.0919e-04 FinalTime=4.0929e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0919e-04 4.0929e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p1_fall_"
  Transient (
    InitialTime=4.0929e-04 FinalTime=4.0929e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p1_read_"
  Transient (
    InitialTime=4.0929e-04 FinalTime=4.0939e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0929e-04 4.0939e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p2_rise_"
  Transient (
    InitialTime=4.0939e-04 FinalTime=4.0939e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p2_write_"
  Transient (
    InitialTime=4.0939e-04 FinalTime=4.0949e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0939e-04 4.0949e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p2_fall_"
  Transient (
    InitialTime=4.0949e-04 FinalTime=4.0949e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p2_read_"
  Transient (
    InitialTime=4.0949e-04 FinalTime=4.0959e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0949e-04 4.0959e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p3_rise_"
  Transient (
    InitialTime=4.0959e-04 FinalTime=4.0960e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p3_write_"
  Transient (
    InitialTime=4.0960e-04 FinalTime=4.0970e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0960e-04 4.0970e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p3_fall_"
  Transient (
    InitialTime=4.0970e-04 FinalTime=4.0970e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p3_read_"
  Transient (
    InitialTime=4.0970e-04 FinalTime=4.0980e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0970e-04 4.0980e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p4_rise_"
  Transient (
    InitialTime=4.0980e-04 FinalTime=4.0980e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p4_write_"
  Transient (
    InitialTime=4.0980e-04 FinalTime=4.0990e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0980e-04 4.0990e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p4_fall_"
  Transient (
    InitialTime=4.0990e-04 FinalTime=4.0990e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p4_read_"
  Transient (
    InitialTime=4.0990e-04 FinalTime=4.1000e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0990e-04 4.1000e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p5_rise_"
  Transient (
    InitialTime=4.1000e-04 FinalTime=4.1000e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p5_write_"
  Transient (
    InitialTime=4.1000e-04 FinalTime=4.1010e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1000e-04 4.1010e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p5_fall_"
  Transient (
    InitialTime=4.1010e-04 FinalTime=4.1010e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p5_read_"
  Transient (
    InitialTime=4.1010e-04 FinalTime=4.1020e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1010e-04 4.1020e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p6_rise_"
  Transient (
    InitialTime=4.1020e-04 FinalTime=4.1020e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p6_write_"
  Transient (
    InitialTime=4.1020e-04 FinalTime=4.1030e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1020e-04 4.1030e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p6_fall_"
  Transient (
    InitialTime=4.1030e-04 FinalTime=4.1030e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p6_read_"
  Transient (
    InitialTime=4.1030e-04 FinalTime=4.1040e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1030e-04 4.1040e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p7_rise_"
  Transient (
    InitialTime=4.1040e-04 FinalTime=4.1040e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p7_write_"
  Transient (
    InitialTime=4.1040e-04 FinalTime=4.1050e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1040e-04 4.1050e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p7_fall_"
  Transient (
    InitialTime=4.1050e-04 FinalTime=4.1050e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p7_read_"
  Transient (
    InitialTime=4.1050e-04 FinalTime=4.1060e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1050e-04 4.1060e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p8_rise_"
  Transient (
    InitialTime=4.1060e-04 FinalTime=4.1060e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p8_write_"
  Transient (
    InitialTime=4.1060e-04 FinalTime=4.1070e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1060e-04 4.1070e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p8_fall_"
  Transient (
    InitialTime=4.1070e-04 FinalTime=4.1071e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p8_read_"
  Transient (
    InitialTime=4.1071e-04 FinalTime=4.1081e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1071e-04 4.1081e-04) Intervals=20) ) }
  NewCurrentPrefix="c6_p9_rise_"
  Transient (
    InitialTime=4.1081e-04 FinalTime=4.1081e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p9_write_"
  Transient (
    InitialTime=4.1081e-04 FinalTime=4.1091e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1081e-04 4.1091e-04) Intervals=10) ) }
  NewCurrentPrefix="c6_p9_fall_"
  Transient (
    InitialTime=4.1091e-04 FinalTime=4.1091e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_p9_read_"
  Transient (
    InitialTime=4.1091e-04 FinalTime=4.1101e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1091e-04 4.1101e-04) Intervals=20) ) }
  *--- CYCLE 6 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c6_erase_rise_"
  Transient (
    InitialTime=4.1101e-04 FinalTime=4.1102e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c6_erase_hold_"
  Transient (
    InitialTime=4.1102e-04 FinalTime=4.2102e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1102e-04 4.2102e-04) Intervals=40) ) }
  NewCurrentPrefix="c6_erase_fall_"
  Transient (
    InitialTime=4.2102e-04 FinalTime=4.2103e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 6 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c6_relax_"
  Transient (
    InitialTime=4.2103e-04 FinalTime=4.9103e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.2103e-04 4.9103e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 7 (cycle base time = 4.9103e-04)
  *====================================================================
  NewCurrentPrefix="c7_p1_rise_"
  Transient (
    InitialTime=4.9103e-04 FinalTime=4.9103e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p1_write_"
  Transient (
    InitialTime=4.9103e-04 FinalTime=4.9113e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9103e-04 4.9113e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p1_fall_"
  Transient (
    InitialTime=4.9113e-04 FinalTime=4.9113e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p1_read_"
  Transient (
    InitialTime=4.9113e-04 FinalTime=4.9123e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9113e-04 4.9123e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p2_rise_"
  Transient (
    InitialTime=4.9123e-04 FinalTime=4.9123e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p2_write_"
  Transient (
    InitialTime=4.9123e-04 FinalTime=4.9133e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9123e-04 4.9133e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p2_fall_"
  Transient (
    InitialTime=4.9133e-04 FinalTime=4.9133e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p2_read_"
  Transient (
    InitialTime=4.9133e-04 FinalTime=4.9143e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9133e-04 4.9143e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p3_rise_"
  Transient (
    InitialTime=4.9143e-04 FinalTime=4.9143e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p3_write_"
  Transient (
    InitialTime=4.9143e-04 FinalTime=4.9153e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9143e-04 4.9153e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p3_fall_"
  Transient (
    InitialTime=4.9153e-04 FinalTime=4.9153e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p3_read_"
  Transient (
    InitialTime=4.9153e-04 FinalTime=4.9163e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9153e-04 4.9163e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p4_rise_"
  Transient (
    InitialTime=4.9163e-04 FinalTime=4.9164e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p4_write_"
  Transient (
    InitialTime=4.9164e-04 FinalTime=4.9173e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9164e-04 4.9173e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p4_fall_"
  Transient (
    InitialTime=4.9173e-04 FinalTime=4.9174e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p4_read_"
  Transient (
    InitialTime=4.9174e-04 FinalTime=4.9184e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9174e-04 4.9184e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p5_rise_"
  Transient (
    InitialTime=4.9184e-04 FinalTime=4.9184e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p5_write_"
  Transient (
    InitialTime=4.9184e-04 FinalTime=4.9194e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9184e-04 4.9194e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p5_fall_"
  Transient (
    InitialTime=4.9194e-04 FinalTime=4.9194e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p5_read_"
  Transient (
    InitialTime=4.9194e-04 FinalTime=4.9204e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9194e-04 4.9204e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p6_rise_"
  Transient (
    InitialTime=4.9204e-04 FinalTime=4.9204e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p6_write_"
  Transient (
    InitialTime=4.9204e-04 FinalTime=4.9214e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9204e-04 4.9214e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p6_fall_"
  Transient (
    InitialTime=4.9214e-04 FinalTime=4.9214e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p6_read_"
  Transient (
    InitialTime=4.9214e-04 FinalTime=4.9224e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9214e-04 4.9224e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p7_rise_"
  Transient (
    InitialTime=4.9224e-04 FinalTime=4.9224e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p7_write_"
  Transient (
    InitialTime=4.9224e-04 FinalTime=4.9234e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9224e-04 4.9234e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p7_fall_"
  Transient (
    InitialTime=4.9234e-04 FinalTime=4.9234e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p7_read_"
  Transient (
    InitialTime=4.9234e-04 FinalTime=4.9244e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9234e-04 4.9244e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p8_rise_"
  Transient (
    InitialTime=4.9244e-04 FinalTime=4.9244e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p8_write_"
  Transient (
    InitialTime=4.9244e-04 FinalTime=4.9254e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9244e-04 4.9254e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p8_fall_"
  Transient (
    InitialTime=4.9254e-04 FinalTime=4.9254e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p8_read_"
  Transient (
    InitialTime=4.9254e-04 FinalTime=4.9264e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9254e-04 4.9264e-04) Intervals=20) ) }
  NewCurrentPrefix="c7_p9_rise_"
  Transient (
    InitialTime=4.9264e-04 FinalTime=4.9264e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p9_write_"
  Transient (
    InitialTime=4.9264e-04 FinalTime=4.9274e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9264e-04 4.9274e-04) Intervals=10) ) }
  NewCurrentPrefix="c7_p9_fall_"
  Transient (
    InitialTime=4.9274e-04 FinalTime=4.9275e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_p9_read_"
  Transient (
    InitialTime=4.9275e-04 FinalTime=4.9285e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9275e-04 4.9285e-04) Intervals=20) ) }
  *--- CYCLE 7 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c7_erase_rise_"
  Transient (
    InitialTime=4.9285e-04 FinalTime=4.9286e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c7_erase_hold_"
  Transient (
    InitialTime=4.9286e-04 FinalTime=5.0286e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9286e-04 5.0286e-04) Intervals=40) ) }
  NewCurrentPrefix="c7_erase_fall_"
  Transient (
    InitialTime=5.0286e-04 FinalTime=5.0287e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 7 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c7_relax_"
  Transient (
    InitialTime=5.0287e-04 FinalTime=5.7287e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0287e-04 5.7287e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 8 (cycle base time = 5.7287e-04)
  *====================================================================
  NewCurrentPrefix="c8_p1_rise_"
  Transient (
    InitialTime=5.7287e-04 FinalTime=5.7287e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p1_write_"
  Transient (
    InitialTime=5.7287e-04 FinalTime=5.7297e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7287e-04 5.7297e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p1_fall_"
  Transient (
    InitialTime=5.7297e-04 FinalTime=5.7297e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p1_read_"
  Transient (
    InitialTime=5.7297e-04 FinalTime=5.7307e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7297e-04 5.7307e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p2_rise_"
  Transient (
    InitialTime=5.7307e-04 FinalTime=5.7307e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p2_write_"
  Transient (
    InitialTime=5.7307e-04 FinalTime=5.7317e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7307e-04 5.7317e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p2_fall_"
  Transient (
    InitialTime=5.7317e-04 FinalTime=5.7317e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p2_read_"
  Transient (
    InitialTime=5.7317e-04 FinalTime=5.7327e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7317e-04 5.7327e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p3_rise_"
  Transient (
    InitialTime=5.7327e-04 FinalTime=5.7327e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p3_write_"
  Transient (
    InitialTime=5.7327e-04 FinalTime=5.7337e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7327e-04 5.7337e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p3_fall_"
  Transient (
    InitialTime=5.7337e-04 FinalTime=5.7337e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p3_read_"
  Transient (
    InitialTime=5.7337e-04 FinalTime=5.7347e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7337e-04 5.7347e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p4_rise_"
  Transient (
    InitialTime=5.7347e-04 FinalTime=5.7347e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p4_write_"
  Transient (
    InitialTime=5.7347e-04 FinalTime=5.7357e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7347e-04 5.7357e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p4_fall_"
  Transient (
    InitialTime=5.7357e-04 FinalTime=5.7357e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p4_read_"
  Transient (
    InitialTime=5.7357e-04 FinalTime=5.7367e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7357e-04 5.7367e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p5_rise_"
  Transient (
    InitialTime=5.7367e-04 FinalTime=5.7368e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p5_write_"
  Transient (
    InitialTime=5.7368e-04 FinalTime=5.7378e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7368e-04 5.7378e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p5_fall_"
  Transient (
    InitialTime=5.7378e-04 FinalTime=5.7378e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p5_read_"
  Transient (
    InitialTime=5.7378e-04 FinalTime=5.7388e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7378e-04 5.7388e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p6_rise_"
  Transient (
    InitialTime=5.7388e-04 FinalTime=5.7388e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p6_write_"
  Transient (
    InitialTime=5.7388e-04 FinalTime=5.7398e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7388e-04 5.7398e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p6_fall_"
  Transient (
    InitialTime=5.7398e-04 FinalTime=5.7398e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p6_read_"
  Transient (
    InitialTime=5.7398e-04 FinalTime=5.7408e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7398e-04 5.7408e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p7_rise_"
  Transient (
    InitialTime=5.7408e-04 FinalTime=5.7408e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p7_write_"
  Transient (
    InitialTime=5.7408e-04 FinalTime=5.7418e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7408e-04 5.7418e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p7_fall_"
  Transient (
    InitialTime=5.7418e-04 FinalTime=5.7418e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p7_read_"
  Transient (
    InitialTime=5.7418e-04 FinalTime=5.7428e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7418e-04 5.7428e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p8_rise_"
  Transient (
    InitialTime=5.7428e-04 FinalTime=5.7428e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p8_write_"
  Transient (
    InitialTime=5.7428e-04 FinalTime=5.7438e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7428e-04 5.7438e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p8_fall_"
  Transient (
    InitialTime=5.7438e-04 FinalTime=5.7438e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p8_read_"
  Transient (
    InitialTime=5.7438e-04 FinalTime=5.7448e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7438e-04 5.7448e-04) Intervals=20) ) }
  NewCurrentPrefix="c8_p9_rise_"
  Transient (
    InitialTime=5.7448e-04 FinalTime=5.7448e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p9_write_"
  Transient (
    InitialTime=5.7448e-04 FinalTime=5.7458e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7448e-04 5.7458e-04) Intervals=10) ) }
  NewCurrentPrefix="c8_p9_fall_"
  Transient (
    InitialTime=5.7458e-04 FinalTime=5.7458e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_p9_read_"
  Transient (
    InitialTime=5.7458e-04 FinalTime=5.7468e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7458e-04 5.7468e-04) Intervals=20) ) }
  *--- CYCLE 8 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c8_erase_rise_"
  Transient (
    InitialTime=5.7468e-04 FinalTime=5.7469e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c8_erase_hold_"
  Transient (
    InitialTime=5.7469e-04 FinalTime=5.8469e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.7469e-04 5.8469e-04) Intervals=40) ) }
  NewCurrentPrefix="c8_erase_fall_"
  Transient (
    InitialTime=5.8469e-04 FinalTime=5.8470e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 8 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c8_relax_"
  Transient (
    InitialTime=5.8470e-04 FinalTime=6.5470e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.8470e-04 6.5470e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 9 (cycle base time = 6.5470e-04)
  *====================================================================
  NewCurrentPrefix="c9_p1_rise_"
  Transient (
    InitialTime=6.5470e-04 FinalTime=6.5471e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p1_write_"
  Transient (
    InitialTime=6.5471e-04 FinalTime=6.5480e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5471e-04 6.5480e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p1_fall_"
  Transient (
    InitialTime=6.5480e-04 FinalTime=6.5481e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p1_read_"
  Transient (
    InitialTime=6.5481e-04 FinalTime=6.5491e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5481e-04 6.5491e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p2_rise_"
  Transient (
    InitialTime=6.5491e-04 FinalTime=6.5491e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p2_write_"
  Transient (
    InitialTime=6.5491e-04 FinalTime=6.5501e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5491e-04 6.5501e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p2_fall_"
  Transient (
    InitialTime=6.5501e-04 FinalTime=6.5501e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p2_read_"
  Transient (
    InitialTime=6.5501e-04 FinalTime=6.5511e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5501e-04 6.5511e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p3_rise_"
  Transient (
    InitialTime=6.5511e-04 FinalTime=6.5511e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p3_write_"
  Transient (
    InitialTime=6.5511e-04 FinalTime=6.5521e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5511e-04 6.5521e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p3_fall_"
  Transient (
    InitialTime=6.5521e-04 FinalTime=6.5521e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p3_read_"
  Transient (
    InitialTime=6.5521e-04 FinalTime=6.5531e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5521e-04 6.5531e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p4_rise_"
  Transient (
    InitialTime=6.5531e-04 FinalTime=6.5531e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p4_write_"
  Transient (
    InitialTime=6.5531e-04 FinalTime=6.5541e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5531e-04 6.5541e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p4_fall_"
  Transient (
    InitialTime=6.5541e-04 FinalTime=6.5541e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p4_read_"
  Transient (
    InitialTime=6.5541e-04 FinalTime=6.5551e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5541e-04 6.5551e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p5_rise_"
  Transient (
    InitialTime=6.5551e-04 FinalTime=6.5551e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p5_write_"
  Transient (
    InitialTime=6.5551e-04 FinalTime=6.5561e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5551e-04 6.5561e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p5_fall_"
  Transient (
    InitialTime=6.5561e-04 FinalTime=6.5561e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p5_read_"
  Transient (
    InitialTime=6.5561e-04 FinalTime=6.5571e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5561e-04 6.5571e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p6_rise_"
  Transient (
    InitialTime=6.5571e-04 FinalTime=6.5571e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p6_write_"
  Transient (
    InitialTime=6.5571e-04 FinalTime=6.5581e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5571e-04 6.5581e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p6_fall_"
  Transient (
    InitialTime=6.5581e-04 FinalTime=6.5582e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p6_read_"
  Transient (
    InitialTime=6.5582e-04 FinalTime=6.5592e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5582e-04 6.5592e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p7_rise_"
  Transient (
    InitialTime=6.5592e-04 FinalTime=6.5592e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p7_write_"
  Transient (
    InitialTime=6.5592e-04 FinalTime=6.5602e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5592e-04 6.5602e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p7_fall_"
  Transient (
    InitialTime=6.5602e-04 FinalTime=6.5602e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p7_read_"
  Transient (
    InitialTime=6.5602e-04 FinalTime=6.5612e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5602e-04 6.5612e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p8_rise_"
  Transient (
    InitialTime=6.5612e-04 FinalTime=6.5612e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p8_write_"
  Transient (
    InitialTime=6.5612e-04 FinalTime=6.5622e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5612e-04 6.5622e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p8_fall_"
  Transient (
    InitialTime=6.5622e-04 FinalTime=6.5622e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p8_read_"
  Transient (
    InitialTime=6.5622e-04 FinalTime=6.5632e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5622e-04 6.5632e-04) Intervals=20) ) }
  NewCurrentPrefix="c9_p9_rise_"
  Transient (
    InitialTime=6.5632e-04 FinalTime=6.5632e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p9_write_"
  Transient (
    InitialTime=6.5632e-04 FinalTime=6.5642e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5632e-04 6.5642e-04) Intervals=10) ) }
  NewCurrentPrefix="c9_p9_fall_"
  Transient (
    InitialTime=6.5642e-04 FinalTime=6.5642e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_p9_read_"
  Transient (
    InitialTime=6.5642e-04 FinalTime=6.5652e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5642e-04 6.5652e-04) Intervals=20) ) }
  *--- CYCLE 9 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c9_erase_rise_"
  Transient (
    InitialTime=6.5652e-04 FinalTime=6.5653e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c9_erase_hold_"
  Transient (
    InitialTime=6.5653e-04 FinalTime=6.6653e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5653e-04 6.6653e-04) Intervals=40) ) }
  NewCurrentPrefix="c9_erase_fall_"
  Transient (
    InitialTime=6.6653e-04 FinalTime=6.6654e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 9 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c9_relax_"
  Transient (
    InitialTime=6.6654e-04 FinalTime=7.3654e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.6654e-04 7.3654e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 10 (cycle base time = 7.3654e-04)
  *====================================================================
  NewCurrentPrefix="c10_p1_rise_"
  Transient (
    InitialTime=7.3654e-04 FinalTime=7.3654e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p1_write_"
  Transient (
    InitialTime=7.3654e-04 FinalTime=7.3664e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3654e-04 7.3664e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p1_fall_"
  Transient (
    InitialTime=7.3664e-04 FinalTime=7.3664e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p1_read_"
  Transient (
    InitialTime=7.3664e-04 FinalTime=7.3674e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3664e-04 7.3674e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p2_rise_"
  Transient (
    InitialTime=7.3674e-04 FinalTime=7.3675e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p2_write_"
  Transient (
    InitialTime=7.3675e-04 FinalTime=7.3684e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3675e-04 7.3684e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p2_fall_"
  Transient (
    InitialTime=7.3684e-04 FinalTime=7.3685e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p2_read_"
  Transient (
    InitialTime=7.3685e-04 FinalTime=7.3695e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3685e-04 7.3695e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p3_rise_"
  Transient (
    InitialTime=7.3695e-04 FinalTime=7.3695e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p3_write_"
  Transient (
    InitialTime=7.3695e-04 FinalTime=7.3705e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3695e-04 7.3705e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p3_fall_"
  Transient (
    InitialTime=7.3705e-04 FinalTime=7.3705e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p3_read_"
  Transient (
    InitialTime=7.3705e-04 FinalTime=7.3715e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3705e-04 7.3715e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p4_rise_"
  Transient (
    InitialTime=7.3715e-04 FinalTime=7.3715e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p4_write_"
  Transient (
    InitialTime=7.3715e-04 FinalTime=7.3725e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3715e-04 7.3725e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p4_fall_"
  Transient (
    InitialTime=7.3725e-04 FinalTime=7.3725e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p4_read_"
  Transient (
    InitialTime=7.3725e-04 FinalTime=7.3735e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3725e-04 7.3735e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p5_rise_"
  Transient (
    InitialTime=7.3735e-04 FinalTime=7.3735e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p5_write_"
  Transient (
    InitialTime=7.3735e-04 FinalTime=7.3745e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3735e-04 7.3745e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p5_fall_"
  Transient (
    InitialTime=7.3745e-04 FinalTime=7.3745e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p5_read_"
  Transient (
    InitialTime=7.3745e-04 FinalTime=7.3755e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3745e-04 7.3755e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p6_rise_"
  Transient (
    InitialTime=7.3755e-04 FinalTime=7.3755e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p6_write_"
  Transient (
    InitialTime=7.3755e-04 FinalTime=7.3765e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3755e-04 7.3765e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p6_fall_"
  Transient (
    InitialTime=7.3765e-04 FinalTime=7.3765e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p6_read_"
  Transient (
    InitialTime=7.3765e-04 FinalTime=7.3775e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3765e-04 7.3775e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p7_rise_"
  Transient (
    InitialTime=7.3775e-04 FinalTime=7.3775e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p7_write_"
  Transient (
    InitialTime=7.3775e-04 FinalTime=7.3785e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3775e-04 7.3785e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p7_fall_"
  Transient (
    InitialTime=7.3785e-04 FinalTime=7.3786e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p7_read_"
  Transient (
    InitialTime=7.3786e-04 FinalTime=7.3796e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3786e-04 7.3796e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p8_rise_"
  Transient (
    InitialTime=7.3796e-04 FinalTime=7.3796e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p8_write_"
  Transient (
    InitialTime=7.3796e-04 FinalTime=7.3806e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3796e-04 7.3806e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p8_fall_"
  Transient (
    InitialTime=7.3806e-04 FinalTime=7.3806e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p8_read_"
  Transient (
    InitialTime=7.3806e-04 FinalTime=7.3816e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3806e-04 7.3816e-04) Intervals=20) ) }
  NewCurrentPrefix="c10_p9_rise_"
  Transient (
    InitialTime=7.3816e-04 FinalTime=7.3816e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p9_write_"
  Transient (
    InitialTime=7.3816e-04 FinalTime=7.3826e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3816e-04 7.3826e-04) Intervals=10) ) }
  NewCurrentPrefix="c10_p9_fall_"
  Transient (
    InitialTime=7.3826e-04 FinalTime=7.3826e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_p9_read_"
  Transient (
    InitialTime=7.3826e-04 FinalTime=7.3836e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3826e-04 7.3836e-04) Intervals=20) ) }
  *--- CYCLE 10 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c10_erase_rise_"
  Transient (
    InitialTime=7.3836e-04 FinalTime=7.3837e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c10_erase_hold_"
  Transient (
    InitialTime=7.3837e-04 FinalTime=7.4837e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3837e-04 7.4837e-04) Intervals=40) ) }
  NewCurrentPrefix="c10_erase_fall_"
  Transient (
    InitialTime=7.4837e-04 FinalTime=7.4838e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 10 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c10_relax_"
  Transient (
    InitialTime=7.4838e-04 FinalTime=8.1838e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.4838e-04 8.1838e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 11 (cycle base time = 8.1838e-04)
  *====================================================================
  NewCurrentPrefix="c11_p1_rise_"
  Transient (
    InitialTime=8.1838e-04 FinalTime=8.1838e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p1_write_"
  Transient (
    InitialTime=8.1838e-04 FinalTime=8.1848e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1838e-04 8.1848e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p1_fall_"
  Transient (
    InitialTime=8.1848e-04 FinalTime=8.1848e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p1_read_"
  Transient (
    InitialTime=8.1848e-04 FinalTime=8.1858e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1848e-04 8.1858e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p2_rise_"
  Transient (
    InitialTime=8.1858e-04 FinalTime=8.1858e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p2_write_"
  Transient (
    InitialTime=8.1858e-04 FinalTime=8.1868e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1858e-04 8.1868e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p2_fall_"
  Transient (
    InitialTime=8.1868e-04 FinalTime=8.1868e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p2_read_"
  Transient (
    InitialTime=8.1868e-04 FinalTime=8.1878e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1868e-04 8.1878e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p3_rise_"
  Transient (
    InitialTime=8.1878e-04 FinalTime=8.1878e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p3_write_"
  Transient (
    InitialTime=8.1878e-04 FinalTime=8.1888e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1878e-04 8.1888e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p3_fall_"
  Transient (
    InitialTime=8.1888e-04 FinalTime=8.1889e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p3_read_"
  Transient (
    InitialTime=8.1889e-04 FinalTime=8.1899e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1889e-04 8.1899e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p4_rise_"
  Transient (
    InitialTime=8.1899e-04 FinalTime=8.1899e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p4_write_"
  Transient (
    InitialTime=8.1899e-04 FinalTime=8.1909e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1899e-04 8.1909e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p4_fall_"
  Transient (
    InitialTime=8.1909e-04 FinalTime=8.1909e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p4_read_"
  Transient (
    InitialTime=8.1909e-04 FinalTime=8.1919e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1909e-04 8.1919e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p5_rise_"
  Transient (
    InitialTime=8.1919e-04 FinalTime=8.1919e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p5_write_"
  Transient (
    InitialTime=8.1919e-04 FinalTime=8.1929e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1919e-04 8.1929e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p5_fall_"
  Transient (
    InitialTime=8.1929e-04 FinalTime=8.1929e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p5_read_"
  Transient (
    InitialTime=8.1929e-04 FinalTime=8.1939e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1929e-04 8.1939e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p6_rise_"
  Transient (
    InitialTime=8.1939e-04 FinalTime=8.1939e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p6_write_"
  Transient (
    InitialTime=8.1939e-04 FinalTime=8.1949e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1939e-04 8.1949e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p6_fall_"
  Transient (
    InitialTime=8.1949e-04 FinalTime=8.1949e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p6_read_"
  Transient (
    InitialTime=8.1949e-04 FinalTime=8.1959e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1949e-04 8.1959e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p7_rise_"
  Transient (
    InitialTime=8.1959e-04 FinalTime=8.1959e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p7_write_"
  Transient (
    InitialTime=8.1959e-04 FinalTime=8.1969e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1959e-04 8.1969e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p7_fall_"
  Transient (
    InitialTime=8.1969e-04 FinalTime=8.1969e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p7_read_"
  Transient (
    InitialTime=8.1969e-04 FinalTime=8.1979e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1969e-04 8.1979e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p8_rise_"
  Transient (
    InitialTime=8.1979e-04 FinalTime=8.1980e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p8_write_"
  Transient (
    InitialTime=8.1980e-04 FinalTime=8.1989e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1980e-04 8.1989e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p8_fall_"
  Transient (
    InitialTime=8.1989e-04 FinalTime=8.1990e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p8_read_"
  Transient (
    InitialTime=8.1990e-04 FinalTime=8.2000e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1990e-04 8.2000e-04) Intervals=20) ) }
  NewCurrentPrefix="c11_p9_rise_"
  Transient (
    InitialTime=8.2000e-04 FinalTime=8.2000e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p9_write_"
  Transient (
    InitialTime=8.2000e-04 FinalTime=8.2010e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2000e-04 8.2010e-04) Intervals=10) ) }
  NewCurrentPrefix="c11_p9_fall_"
  Transient (
    InitialTime=8.2010e-04 FinalTime=8.2010e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_p9_read_"
  Transient (
    InitialTime=8.2010e-04 FinalTime=8.2020e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2010e-04 8.2020e-04) Intervals=20) ) }
  *--- CYCLE 11 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c11_erase_rise_"
  Transient (
    InitialTime=8.2020e-04 FinalTime=8.2021e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c11_erase_hold_"
  Transient (
    InitialTime=8.2021e-04 FinalTime=8.3021e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2021e-04 8.3021e-04) Intervals=40) ) }
  NewCurrentPrefix="c11_erase_fall_"
  Transient (
    InitialTime=8.3021e-04 FinalTime=8.3022e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 11 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c11_relax_"
  Transient (
    InitialTime=8.3022e-04 FinalTime=9.0022e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3022e-04 9.0022e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 12 (cycle base time = 9.0022e-04)
  *====================================================================
  NewCurrentPrefix="c12_p1_rise_"
  Transient (
    InitialTime=9.0022e-04 FinalTime=9.0022e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p1_write_"
  Transient (
    InitialTime=9.0022e-04 FinalTime=9.0032e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0022e-04 9.0032e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p1_fall_"
  Transient (
    InitialTime=9.0032e-04 FinalTime=9.0032e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p1_read_"
  Transient (
    InitialTime=9.0032e-04 FinalTime=9.0042e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0032e-04 9.0042e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p2_rise_"
  Transient (
    InitialTime=9.0042e-04 FinalTime=9.0042e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p2_write_"
  Transient (
    InitialTime=9.0042e-04 FinalTime=9.0052e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0042e-04 9.0052e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p2_fall_"
  Transient (
    InitialTime=9.0052e-04 FinalTime=9.0052e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p2_read_"
  Transient (
    InitialTime=9.0052e-04 FinalTime=9.0062e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0052e-04 9.0062e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p3_rise_"
  Transient (
    InitialTime=9.0062e-04 FinalTime=9.0062e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p3_write_"
  Transient (
    InitialTime=9.0062e-04 FinalTime=9.0072e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0062e-04 9.0072e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p3_fall_"
  Transient (
    InitialTime=9.0072e-04 FinalTime=9.0072e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p3_read_"
  Transient (
    InitialTime=9.0072e-04 FinalTime=9.0082e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0072e-04 9.0082e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p4_rise_"
  Transient (
    InitialTime=9.0082e-04 FinalTime=9.0082e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p4_write_"
  Transient (
    InitialTime=9.0082e-04 FinalTime=9.0092e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0082e-04 9.0092e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p4_fall_"
  Transient (
    InitialTime=9.0092e-04 FinalTime=9.0093e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p4_read_"
  Transient (
    InitialTime=9.0093e-04 FinalTime=9.0103e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0093e-04 9.0103e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p5_rise_"
  Transient (
    InitialTime=9.0103e-04 FinalTime=9.0103e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p5_write_"
  Transient (
    InitialTime=9.0103e-04 FinalTime=9.0113e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0103e-04 9.0113e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p5_fall_"
  Transient (
    InitialTime=9.0113e-04 FinalTime=9.0113e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p5_read_"
  Transient (
    InitialTime=9.0113e-04 FinalTime=9.0123e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0113e-04 9.0123e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p6_rise_"
  Transient (
    InitialTime=9.0123e-04 FinalTime=9.0123e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p6_write_"
  Transient (
    InitialTime=9.0123e-04 FinalTime=9.0133e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0123e-04 9.0133e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p6_fall_"
  Transient (
    InitialTime=9.0133e-04 FinalTime=9.0133e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p6_read_"
  Transient (
    InitialTime=9.0133e-04 FinalTime=9.0143e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0133e-04 9.0143e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p7_rise_"
  Transient (
    InitialTime=9.0143e-04 FinalTime=9.0143e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p7_write_"
  Transient (
    InitialTime=9.0143e-04 FinalTime=9.0153e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0143e-04 9.0153e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p7_fall_"
  Transient (
    InitialTime=9.0153e-04 FinalTime=9.0153e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p7_read_"
  Transient (
    InitialTime=9.0153e-04 FinalTime=9.0163e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0153e-04 9.0163e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p8_rise_"
  Transient (
    InitialTime=9.0163e-04 FinalTime=9.0163e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p8_write_"
  Transient (
    InitialTime=9.0163e-04 FinalTime=9.0173e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0163e-04 9.0173e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p8_fall_"
  Transient (
    InitialTime=9.0173e-04 FinalTime=9.0173e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p8_read_"
  Transient (
    InitialTime=9.0173e-04 FinalTime=9.0183e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0173e-04 9.0183e-04) Intervals=20) ) }
  NewCurrentPrefix="c12_p9_rise_"
  Transient (
    InitialTime=9.0183e-04 FinalTime=9.0183e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p9_write_"
  Transient (
    InitialTime=9.0183e-04 FinalTime=9.0193e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0183e-04 9.0193e-04) Intervals=10) ) }
  NewCurrentPrefix="c12_p9_fall_"
  Transient (
    InitialTime=9.0193e-04 FinalTime=9.0194e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_p9_read_"
  Transient (
    InitialTime=9.0194e-04 FinalTime=9.0204e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0194e-04 9.0204e-04) Intervals=20) ) }
  *--- CYCLE 12 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c12_erase_rise_"
  Transient (
    InitialTime=9.0204e-04 FinalTime=9.0205e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c12_erase_hold_"
  Transient (
    InitialTime=9.0205e-04 FinalTime=9.1205e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0205e-04 9.1205e-04) Intervals=40) ) }
  NewCurrentPrefix="c12_erase_fall_"
  Transient (
    InitialTime=9.1205e-04 FinalTime=9.1206e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 12 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c12_relax_"
  Transient (
    InitialTime=9.1206e-04 FinalTime=9.8206e-04
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1206e-04 9.8206e-04) Intervals=70) ) }

  *====================================================================
  *== CYCLE 13 (cycle base time = 9.8206e-04)
  *====================================================================
  NewCurrentPrefix="c13_p1_rise_"
  Transient (
    InitialTime=9.8206e-04 FinalTime=9.8206e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p1_write_"
  Transient (
    InitialTime=9.8206e-04 FinalTime=9.8216e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8206e-04 9.8216e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p1_fall_"
  Transient (
    InitialTime=9.8216e-04 FinalTime=9.8216e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p1_read_"
  Transient (
    InitialTime=9.8216e-04 FinalTime=9.8226e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8216e-04 9.8226e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p2_rise_"
  Transient (
    InitialTime=9.8226e-04 FinalTime=9.8226e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p2_write_"
  Transient (
    InitialTime=9.8226e-04 FinalTime=9.8236e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8226e-04 9.8236e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p2_fall_"
  Transient (
    InitialTime=9.8236e-04 FinalTime=9.8236e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p2_read_"
  Transient (
    InitialTime=9.8236e-04 FinalTime=9.8246e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8236e-04 9.8246e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p3_rise_"
  Transient (
    InitialTime=9.8246e-04 FinalTime=9.8246e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p3_write_"
  Transient (
    InitialTime=9.8246e-04 FinalTime=9.8256e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8246e-04 9.8256e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p3_fall_"
  Transient (
    InitialTime=9.8256e-04 FinalTime=9.8256e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p3_read_"
  Transient (
    InitialTime=9.8256e-04 FinalTime=9.8266e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8256e-04 9.8266e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p4_rise_"
  Transient (
    InitialTime=9.8266e-04 FinalTime=9.8266e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p4_write_"
  Transient (
    InitialTime=9.8266e-04 FinalTime=9.8276e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8266e-04 9.8276e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p4_fall_"
  Transient (
    InitialTime=9.8276e-04 FinalTime=9.8276e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p4_read_"
  Transient (
    InitialTime=9.8276e-04 FinalTime=9.8286e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8276e-04 9.8286e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p5_rise_"
  Transient (
    InitialTime=9.8286e-04 FinalTime=9.8286e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p5_write_"
  Transient (
    InitialTime=9.8286e-04 FinalTime=9.8296e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8286e-04 9.8296e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p5_fall_"
  Transient (
    InitialTime=9.8296e-04 FinalTime=9.8297e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p5_read_"
  Transient (
    InitialTime=9.8297e-04 FinalTime=9.8307e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8297e-04 9.8307e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p6_rise_"
  Transient (
    InitialTime=9.8307e-04 FinalTime=9.8307e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p6_write_"
  Transient (
    InitialTime=9.8307e-04 FinalTime=9.8317e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8307e-04 9.8317e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p6_fall_"
  Transient (
    InitialTime=9.8317e-04 FinalTime=9.8317e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p6_read_"
  Transient (
    InitialTime=9.8317e-04 FinalTime=9.8327e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8317e-04 9.8327e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p7_rise_"
  Transient (
    InitialTime=9.8327e-04 FinalTime=9.8327e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p7_write_"
  Transient (
    InitialTime=9.8327e-04 FinalTime=9.8337e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8327e-04 9.8337e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p7_fall_"
  Transient (
    InitialTime=9.8337e-04 FinalTime=9.8337e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p7_read_"
  Transient (
    InitialTime=9.8337e-04 FinalTime=9.8347e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8337e-04 9.8347e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p8_rise_"
  Transient (
    InitialTime=9.8347e-04 FinalTime=9.8347e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p8_write_"
  Transient (
    InitialTime=9.8347e-04 FinalTime=9.8357e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8347e-04 9.8357e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p8_fall_"
  Transient (
    InitialTime=9.8357e-04 FinalTime=9.8357e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p8_read_"
  Transient (
    InitialTime=9.8357e-04 FinalTime=9.8367e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8357e-04 9.8367e-04) Intervals=20) ) }
  NewCurrentPrefix="c13_p9_rise_"
  Transient (
    InitialTime=9.8367e-04 FinalTime=9.8367e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p9_write_"
  Transient (
    InitialTime=9.8367e-04 FinalTime=9.8377e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8367e-04 9.8377e-04) Intervals=10) ) }
  NewCurrentPrefix="c13_p9_fall_"
  Transient (
    InitialTime=9.8377e-04 FinalTime=9.8377e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_p9_read_"
  Transient (
    InitialTime=9.8377e-04 FinalTime=9.8387e-04
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8377e-04 9.8387e-04) Intervals=20) ) }
  *--- CYCLE 13 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c13_erase_rise_"
  Transient (
    InitialTime=9.8387e-04 FinalTime=9.8388e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c13_erase_hold_"
  Transient (
    InitialTime=9.8388e-04 FinalTime=9.9388e-04
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8388e-04 9.9388e-04) Intervals=40) ) }
  NewCurrentPrefix="c13_erase_fall_"
  Transient (
    InitialTime=9.9388e-04 FinalTime=9.9389e-04
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 13 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c13_relax_"
  Transient (
    InitialTime=9.9389e-04 FinalTime=1.0639e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.9389e-04 1.0639e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 14 (cycle base time = 1.0639e-03)
  *====================================================================
  NewCurrentPrefix="c14_p1_rise_"
  Transient (
    InitialTime=1.0639e-03 FinalTime=1.0639e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p1_write_"
  Transient (
    InitialTime=1.0639e-03 FinalTime=1.0640e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0639e-03 1.0640e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p1_fall_"
  Transient (
    InitialTime=1.0640e-03 FinalTime=1.0640e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p1_read_"
  Transient (
    InitialTime=1.0640e-03 FinalTime=1.0641e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0640e-03 1.0641e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p2_rise_"
  Transient (
    InitialTime=1.0641e-03 FinalTime=1.0641e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p2_write_"
  Transient (
    InitialTime=1.0641e-03 FinalTime=1.0642e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0641e-03 1.0642e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p2_fall_"
  Transient (
    InitialTime=1.0642e-03 FinalTime=1.0642e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p2_read_"
  Transient (
    InitialTime=1.0642e-03 FinalTime=1.0643e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0642e-03 1.0643e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p3_rise_"
  Transient (
    InitialTime=1.0643e-03 FinalTime=1.0643e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p3_write_"
  Transient (
    InitialTime=1.0643e-03 FinalTime=1.0644e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0643e-03 1.0644e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p3_fall_"
  Transient (
    InitialTime=1.0644e-03 FinalTime=1.0644e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p3_read_"
  Transient (
    InitialTime=1.0644e-03 FinalTime=1.0645e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0644e-03 1.0645e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p4_rise_"
  Transient (
    InitialTime=1.0645e-03 FinalTime=1.0645e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p4_write_"
  Transient (
    InitialTime=1.0645e-03 FinalTime=1.0646e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0645e-03 1.0646e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p4_fall_"
  Transient (
    InitialTime=1.0646e-03 FinalTime=1.0646e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p4_read_"
  Transient (
    InitialTime=1.0646e-03 FinalTime=1.0647e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0646e-03 1.0647e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p5_rise_"
  Transient (
    InitialTime=1.0647e-03 FinalTime=1.0647e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p5_write_"
  Transient (
    InitialTime=1.0647e-03 FinalTime=1.0648e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0647e-03 1.0648e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p5_fall_"
  Transient (
    InitialTime=1.0648e-03 FinalTime=1.0648e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p5_read_"
  Transient (
    InitialTime=1.0648e-03 FinalTime=1.0649e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0648e-03 1.0649e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p6_rise_"
  Transient (
    InitialTime=1.0649e-03 FinalTime=1.0649e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p6_write_"
  Transient (
    InitialTime=1.0649e-03 FinalTime=1.0650e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0649e-03 1.0650e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p6_fall_"
  Transient (
    InitialTime=1.0650e-03 FinalTime=1.0650e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p6_read_"
  Transient (
    InitialTime=1.0650e-03 FinalTime=1.0651e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0650e-03 1.0651e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p7_rise_"
  Transient (
    InitialTime=1.0651e-03 FinalTime=1.0651e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p7_write_"
  Transient (
    InitialTime=1.0651e-03 FinalTime=1.0652e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0651e-03 1.0652e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p7_fall_"
  Transient (
    InitialTime=1.0652e-03 FinalTime=1.0652e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p7_read_"
  Transient (
    InitialTime=1.0652e-03 FinalTime=1.0653e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0652e-03 1.0653e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p8_rise_"
  Transient (
    InitialTime=1.0653e-03 FinalTime=1.0653e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p8_write_"
  Transient (
    InitialTime=1.0653e-03 FinalTime=1.0654e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0653e-03 1.0654e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p8_fall_"
  Transient (
    InitialTime=1.0654e-03 FinalTime=1.0654e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p8_read_"
  Transient (
    InitialTime=1.0654e-03 FinalTime=1.0655e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0654e-03 1.0655e-03) Intervals=20) ) }
  NewCurrentPrefix="c14_p9_rise_"
  Transient (
    InitialTime=1.0655e-03 FinalTime=1.0655e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p9_write_"
  Transient (
    InitialTime=1.0655e-03 FinalTime=1.0656e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0655e-03 1.0656e-03) Intervals=10) ) }
  NewCurrentPrefix="c14_p9_fall_"
  Transient (
    InitialTime=1.0656e-03 FinalTime=1.0656e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_p9_read_"
  Transient (
    InitialTime=1.0656e-03 FinalTime=1.0657e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0656e-03 1.0657e-03) Intervals=20) ) }
  *--- CYCLE 14 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c14_erase_rise_"
  Transient (
    InitialTime=1.0657e-03 FinalTime=1.0657e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c14_erase_hold_"
  Transient (
    InitialTime=1.0657e-03 FinalTime=1.0757e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0657e-03 1.0757e-03) Intervals=40) ) }
  NewCurrentPrefix="c14_erase_fall_"
  Transient (
    InitialTime=1.0757e-03 FinalTime=1.0757e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 14 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c14_relax_"
  Transient (
    InitialTime=1.0757e-03 FinalTime=1.1457e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0757e-03 1.1457e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 15 (cycle base time = 1.1457e-03)
  *====================================================================
  NewCurrentPrefix="c15_p1_rise_"
  Transient (
    InitialTime=1.1457e-03 FinalTime=1.1457e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p1_write_"
  Transient (
    InitialTime=1.1457e-03 FinalTime=1.1458e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1457e-03 1.1458e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p1_fall_"
  Transient (
    InitialTime=1.1458e-03 FinalTime=1.1458e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p1_read_"
  Transient (
    InitialTime=1.1458e-03 FinalTime=1.1459e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1458e-03 1.1459e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p2_rise_"
  Transient (
    InitialTime=1.1459e-03 FinalTime=1.1459e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p2_write_"
  Transient (
    InitialTime=1.1459e-03 FinalTime=1.1460e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1459e-03 1.1460e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p2_fall_"
  Transient (
    InitialTime=1.1460e-03 FinalTime=1.1460e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p2_read_"
  Transient (
    InitialTime=1.1460e-03 FinalTime=1.1461e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1460e-03 1.1461e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p3_rise_"
  Transient (
    InitialTime=1.1461e-03 FinalTime=1.1461e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p3_write_"
  Transient (
    InitialTime=1.1461e-03 FinalTime=1.1462e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1461e-03 1.1462e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p3_fall_"
  Transient (
    InitialTime=1.1462e-03 FinalTime=1.1462e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p3_read_"
  Transient (
    InitialTime=1.1462e-03 FinalTime=1.1463e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1462e-03 1.1463e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p4_rise_"
  Transient (
    InitialTime=1.1463e-03 FinalTime=1.1463e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p4_write_"
  Transient (
    InitialTime=1.1463e-03 FinalTime=1.1464e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1463e-03 1.1464e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p4_fall_"
  Transient (
    InitialTime=1.1464e-03 FinalTime=1.1464e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p4_read_"
  Transient (
    InitialTime=1.1464e-03 FinalTime=1.1465e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1464e-03 1.1465e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p5_rise_"
  Transient (
    InitialTime=1.1465e-03 FinalTime=1.1465e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p5_write_"
  Transient (
    InitialTime=1.1465e-03 FinalTime=1.1466e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1465e-03 1.1466e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p5_fall_"
  Transient (
    InitialTime=1.1466e-03 FinalTime=1.1466e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p5_read_"
  Transient (
    InitialTime=1.1466e-03 FinalTime=1.1467e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1466e-03 1.1467e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p6_rise_"
  Transient (
    InitialTime=1.1467e-03 FinalTime=1.1467e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p6_write_"
  Transient (
    InitialTime=1.1467e-03 FinalTime=1.1468e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1467e-03 1.1468e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p6_fall_"
  Transient (
    InitialTime=1.1468e-03 FinalTime=1.1468e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p6_read_"
  Transient (
    InitialTime=1.1468e-03 FinalTime=1.1469e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1468e-03 1.1469e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p7_rise_"
  Transient (
    InitialTime=1.1469e-03 FinalTime=1.1469e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p7_write_"
  Transient (
    InitialTime=1.1469e-03 FinalTime=1.1470e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1469e-03 1.1470e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p7_fall_"
  Transient (
    InitialTime=1.1470e-03 FinalTime=1.1470e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p7_read_"
  Transient (
    InitialTime=1.1470e-03 FinalTime=1.1471e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1470e-03 1.1471e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p8_rise_"
  Transient (
    InitialTime=1.1471e-03 FinalTime=1.1471e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p8_write_"
  Transient (
    InitialTime=1.1471e-03 FinalTime=1.1472e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1471e-03 1.1472e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p8_fall_"
  Transient (
    InitialTime=1.1472e-03 FinalTime=1.1472e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p8_read_"
  Transient (
    InitialTime=1.1472e-03 FinalTime=1.1473e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1472e-03 1.1473e-03) Intervals=20) ) }
  NewCurrentPrefix="c15_p9_rise_"
  Transient (
    InitialTime=1.1473e-03 FinalTime=1.1473e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p9_write_"
  Transient (
    InitialTime=1.1473e-03 FinalTime=1.1474e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1473e-03 1.1474e-03) Intervals=10) ) }
  NewCurrentPrefix="c15_p9_fall_"
  Transient (
    InitialTime=1.1474e-03 FinalTime=1.1474e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_p9_read_"
  Transient (
    InitialTime=1.1474e-03 FinalTime=1.1476e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1474e-03 1.1476e-03) Intervals=20) ) }
  *--- CYCLE 15 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c15_erase_rise_"
  Transient (
    InitialTime=1.1476e-03 FinalTime=1.1476e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c15_erase_hold_"
  Transient (
    InitialTime=1.1476e-03 FinalTime=1.1576e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1476e-03 1.1576e-03) Intervals=40) ) }
  NewCurrentPrefix="c15_erase_fall_"
  Transient (
    InitialTime=1.1576e-03 FinalTime=1.1576e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 15 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c15_relax_"
  Transient (
    InitialTime=1.1576e-03 FinalTime=1.2276e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1576e-03 1.2276e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 16 (cycle base time = 1.2276e-03)
  *====================================================================
  NewCurrentPrefix="c16_p1_rise_"
  Transient (
    InitialTime=1.2276e-03 FinalTime=1.2276e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p1_write_"
  Transient (
    InitialTime=1.2276e-03 FinalTime=1.2277e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2276e-03 1.2277e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p1_fall_"
  Transient (
    InitialTime=1.2277e-03 FinalTime=1.2277e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p1_read_"
  Transient (
    InitialTime=1.2277e-03 FinalTime=1.2278e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2277e-03 1.2278e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p2_rise_"
  Transient (
    InitialTime=1.2278e-03 FinalTime=1.2278e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p2_write_"
  Transient (
    InitialTime=1.2278e-03 FinalTime=1.2279e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2278e-03 1.2279e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p2_fall_"
  Transient (
    InitialTime=1.2279e-03 FinalTime=1.2279e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p2_read_"
  Transient (
    InitialTime=1.2279e-03 FinalTime=1.2280e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2279e-03 1.2280e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p3_rise_"
  Transient (
    InitialTime=1.2280e-03 FinalTime=1.2280e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p3_write_"
  Transient (
    InitialTime=1.2280e-03 FinalTime=1.2281e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2280e-03 1.2281e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p3_fall_"
  Transient (
    InitialTime=1.2281e-03 FinalTime=1.2281e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p3_read_"
  Transient (
    InitialTime=1.2281e-03 FinalTime=1.2282e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2281e-03 1.2282e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p4_rise_"
  Transient (
    InitialTime=1.2282e-03 FinalTime=1.2282e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p4_write_"
  Transient (
    InitialTime=1.2282e-03 FinalTime=1.2283e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2282e-03 1.2283e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p4_fall_"
  Transient (
    InitialTime=1.2283e-03 FinalTime=1.2283e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p4_read_"
  Transient (
    InitialTime=1.2283e-03 FinalTime=1.2284e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2283e-03 1.2284e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p5_rise_"
  Transient (
    InitialTime=1.2284e-03 FinalTime=1.2284e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p5_write_"
  Transient (
    InitialTime=1.2284e-03 FinalTime=1.2285e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2284e-03 1.2285e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p5_fall_"
  Transient (
    InitialTime=1.2285e-03 FinalTime=1.2285e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p5_read_"
  Transient (
    InitialTime=1.2285e-03 FinalTime=1.2286e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2285e-03 1.2286e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p6_rise_"
  Transient (
    InitialTime=1.2286e-03 FinalTime=1.2286e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p6_write_"
  Transient (
    InitialTime=1.2286e-03 FinalTime=1.2287e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2286e-03 1.2287e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p6_fall_"
  Transient (
    InitialTime=1.2287e-03 FinalTime=1.2287e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p6_read_"
  Transient (
    InitialTime=1.2287e-03 FinalTime=1.2288e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2287e-03 1.2288e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p7_rise_"
  Transient (
    InitialTime=1.2288e-03 FinalTime=1.2288e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p7_write_"
  Transient (
    InitialTime=1.2288e-03 FinalTime=1.2289e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2288e-03 1.2289e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p7_fall_"
  Transient (
    InitialTime=1.2289e-03 FinalTime=1.2289e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p7_read_"
  Transient (
    InitialTime=1.2289e-03 FinalTime=1.2290e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2289e-03 1.2290e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p8_rise_"
  Transient (
    InitialTime=1.2290e-03 FinalTime=1.2290e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p8_write_"
  Transient (
    InitialTime=1.2290e-03 FinalTime=1.2291e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2290e-03 1.2291e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p8_fall_"
  Transient (
    InitialTime=1.2291e-03 FinalTime=1.2291e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p8_read_"
  Transient (
    InitialTime=1.2291e-03 FinalTime=1.2292e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2291e-03 1.2292e-03) Intervals=20) ) }
  NewCurrentPrefix="c16_p9_rise_"
  Transient (
    InitialTime=1.2292e-03 FinalTime=1.2292e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p9_write_"
  Transient (
    InitialTime=1.2292e-03 FinalTime=1.2293e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2292e-03 1.2293e-03) Intervals=10) ) }
  NewCurrentPrefix="c16_p9_fall_"
  Transient (
    InitialTime=1.2293e-03 FinalTime=1.2293e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_p9_read_"
  Transient (
    InitialTime=1.2293e-03 FinalTime=1.2294e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2293e-03 1.2294e-03) Intervals=20) ) }
  *--- CYCLE 16 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c16_erase_rise_"
  Transient (
    InitialTime=1.2294e-03 FinalTime=1.2294e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c16_erase_hold_"
  Transient (
    InitialTime=1.2294e-03 FinalTime=1.2394e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2294e-03 1.2394e-03) Intervals=40) ) }
  NewCurrentPrefix="c16_erase_fall_"
  Transient (
    InitialTime=1.2394e-03 FinalTime=1.2394e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 16 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c16_relax_"
  Transient (
    InitialTime=1.2394e-03 FinalTime=1.3094e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2394e-03 1.3094e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 17 (cycle base time = 1.3094e-03)
  *====================================================================
  NewCurrentPrefix="c17_p1_rise_"
  Transient (
    InitialTime=1.3094e-03 FinalTime=1.3094e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p1_write_"
  Transient (
    InitialTime=1.3094e-03 FinalTime=1.3095e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3094e-03 1.3095e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p1_fall_"
  Transient (
    InitialTime=1.3095e-03 FinalTime=1.3095e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p1_read_"
  Transient (
    InitialTime=1.3095e-03 FinalTime=1.3096e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3095e-03 1.3096e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p2_rise_"
  Transient (
    InitialTime=1.3096e-03 FinalTime=1.3096e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p2_write_"
  Transient (
    InitialTime=1.3096e-03 FinalTime=1.3097e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3096e-03 1.3097e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p2_fall_"
  Transient (
    InitialTime=1.3097e-03 FinalTime=1.3097e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p2_read_"
  Transient (
    InitialTime=1.3097e-03 FinalTime=1.3098e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3097e-03 1.3098e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p3_rise_"
  Transient (
    InitialTime=1.3098e-03 FinalTime=1.3098e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p3_write_"
  Transient (
    InitialTime=1.3098e-03 FinalTime=1.3099e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3098e-03 1.3099e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p3_fall_"
  Transient (
    InitialTime=1.3099e-03 FinalTime=1.3099e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p3_read_"
  Transient (
    InitialTime=1.3099e-03 FinalTime=1.3100e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3099e-03 1.3100e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p4_rise_"
  Transient (
    InitialTime=1.3100e-03 FinalTime=1.3100e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p4_write_"
  Transient (
    InitialTime=1.3100e-03 FinalTime=1.3101e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3100e-03 1.3101e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p4_fall_"
  Transient (
    InitialTime=1.3101e-03 FinalTime=1.3101e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p4_read_"
  Transient (
    InitialTime=1.3101e-03 FinalTime=1.3102e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3101e-03 1.3102e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p5_rise_"
  Transient (
    InitialTime=1.3102e-03 FinalTime=1.3102e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p5_write_"
  Transient (
    InitialTime=1.3102e-03 FinalTime=1.3103e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3102e-03 1.3103e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p5_fall_"
  Transient (
    InitialTime=1.3103e-03 FinalTime=1.3103e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p5_read_"
  Transient (
    InitialTime=1.3103e-03 FinalTime=1.3104e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3103e-03 1.3104e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p6_rise_"
  Transient (
    InitialTime=1.3104e-03 FinalTime=1.3104e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p6_write_"
  Transient (
    InitialTime=1.3104e-03 FinalTime=1.3105e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3104e-03 1.3105e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p6_fall_"
  Transient (
    InitialTime=1.3105e-03 FinalTime=1.3105e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p6_read_"
  Transient (
    InitialTime=1.3105e-03 FinalTime=1.3106e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3105e-03 1.3106e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p7_rise_"
  Transient (
    InitialTime=1.3106e-03 FinalTime=1.3106e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p7_write_"
  Transient (
    InitialTime=1.3106e-03 FinalTime=1.3107e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3106e-03 1.3107e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p7_fall_"
  Transient (
    InitialTime=1.3107e-03 FinalTime=1.3107e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p7_read_"
  Transient (
    InitialTime=1.3107e-03 FinalTime=1.3108e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3107e-03 1.3108e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p8_rise_"
  Transient (
    InitialTime=1.3108e-03 FinalTime=1.3108e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p8_write_"
  Transient (
    InitialTime=1.3108e-03 FinalTime=1.3109e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3108e-03 1.3109e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p8_fall_"
  Transient (
    InitialTime=1.3109e-03 FinalTime=1.3109e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p8_read_"
  Transient (
    InitialTime=1.3109e-03 FinalTime=1.3110e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3109e-03 1.3110e-03) Intervals=20) ) }
  NewCurrentPrefix="c17_p9_rise_"
  Transient (
    InitialTime=1.3110e-03 FinalTime=1.3110e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p9_write_"
  Transient (
    InitialTime=1.3110e-03 FinalTime=1.3111e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3110e-03 1.3111e-03) Intervals=10) ) }
  NewCurrentPrefix="c17_p9_fall_"
  Transient (
    InitialTime=1.3111e-03 FinalTime=1.3111e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_p9_read_"
  Transient (
    InitialTime=1.3111e-03 FinalTime=1.3112e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3111e-03 1.3112e-03) Intervals=20) ) }
  *--- CYCLE 17 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c17_erase_rise_"
  Transient (
    InitialTime=1.3112e-03 FinalTime=1.3112e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c17_erase_hold_"
  Transient (
    InitialTime=1.3112e-03 FinalTime=1.3212e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3112e-03 1.3212e-03) Intervals=40) ) }
  NewCurrentPrefix="c17_erase_fall_"
  Transient (
    InitialTime=1.3212e-03 FinalTime=1.3212e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 17 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c17_relax_"
  Transient (
    InitialTime=1.3212e-03 FinalTime=1.3912e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3212e-03 1.3912e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 18 (cycle base time = 1.3912e-03)
  *====================================================================
  NewCurrentPrefix="c18_p1_rise_"
  Transient (
    InitialTime=1.3912e-03 FinalTime=1.3912e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p1_write_"
  Transient (
    InitialTime=1.3912e-03 FinalTime=1.3913e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3912e-03 1.3913e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p1_fall_"
  Transient (
    InitialTime=1.3913e-03 FinalTime=1.3913e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p1_read_"
  Transient (
    InitialTime=1.3913e-03 FinalTime=1.3914e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3913e-03 1.3914e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p2_rise_"
  Transient (
    InitialTime=1.3914e-03 FinalTime=1.3914e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p2_write_"
  Transient (
    InitialTime=1.3914e-03 FinalTime=1.3915e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3914e-03 1.3915e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p2_fall_"
  Transient (
    InitialTime=1.3915e-03 FinalTime=1.3915e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p2_read_"
  Transient (
    InitialTime=1.3915e-03 FinalTime=1.3916e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3915e-03 1.3916e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p3_rise_"
  Transient (
    InitialTime=1.3917e-03 FinalTime=1.3917e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p3_write_"
  Transient (
    InitialTime=1.3917e-03 FinalTime=1.3918e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3917e-03 1.3918e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p3_fall_"
  Transient (
    InitialTime=1.3918e-03 FinalTime=1.3918e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p3_read_"
  Transient (
    InitialTime=1.3918e-03 FinalTime=1.3919e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3918e-03 1.3919e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p4_rise_"
  Transient (
    InitialTime=1.3919e-03 FinalTime=1.3919e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p4_write_"
  Transient (
    InitialTime=1.3919e-03 FinalTime=1.3920e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3919e-03 1.3920e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p4_fall_"
  Transient (
    InitialTime=1.3920e-03 FinalTime=1.3920e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p4_read_"
  Transient (
    InitialTime=1.3920e-03 FinalTime=1.3921e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3920e-03 1.3921e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p5_rise_"
  Transient (
    InitialTime=1.3921e-03 FinalTime=1.3921e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p5_write_"
  Transient (
    InitialTime=1.3921e-03 FinalTime=1.3922e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3921e-03 1.3922e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p5_fall_"
  Transient (
    InitialTime=1.3922e-03 FinalTime=1.3922e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p5_read_"
  Transient (
    InitialTime=1.3922e-03 FinalTime=1.3923e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3922e-03 1.3923e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p6_rise_"
  Transient (
    InitialTime=1.3923e-03 FinalTime=1.3923e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p6_write_"
  Transient (
    InitialTime=1.3923e-03 FinalTime=1.3924e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3923e-03 1.3924e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p6_fall_"
  Transient (
    InitialTime=1.3924e-03 FinalTime=1.3924e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p6_read_"
  Transient (
    InitialTime=1.3924e-03 FinalTime=1.3925e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3924e-03 1.3925e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p7_rise_"
  Transient (
    InitialTime=1.3925e-03 FinalTime=1.3925e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p7_write_"
  Transient (
    InitialTime=1.3925e-03 FinalTime=1.3926e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3925e-03 1.3926e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p7_fall_"
  Transient (
    InitialTime=1.3926e-03 FinalTime=1.3926e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p7_read_"
  Transient (
    InitialTime=1.3926e-03 FinalTime=1.3927e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3926e-03 1.3927e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p8_rise_"
  Transient (
    InitialTime=1.3927e-03 FinalTime=1.3927e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p8_write_"
  Transient (
    InitialTime=1.3927e-03 FinalTime=1.3928e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3927e-03 1.3928e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p8_fall_"
  Transient (
    InitialTime=1.3928e-03 FinalTime=1.3928e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p8_read_"
  Transient (
    InitialTime=1.3928e-03 FinalTime=1.3929e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3928e-03 1.3929e-03) Intervals=20) ) }
  NewCurrentPrefix="c18_p9_rise_"
  Transient (
    InitialTime=1.3929e-03 FinalTime=1.3929e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p9_write_"
  Transient (
    InitialTime=1.3929e-03 FinalTime=1.3930e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3929e-03 1.3930e-03) Intervals=10) ) }
  NewCurrentPrefix="c18_p9_fall_"
  Transient (
    InitialTime=1.3930e-03 FinalTime=1.3930e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_p9_read_"
  Transient (
    InitialTime=1.3930e-03 FinalTime=1.3931e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3930e-03 1.3931e-03) Intervals=20) ) }
  *--- CYCLE 18 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c18_erase_rise_"
  Transient (
    InitialTime=1.3931e-03 FinalTime=1.3931e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c18_erase_hold_"
  Transient (
    InitialTime=1.3931e-03 FinalTime=1.4031e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3931e-03 1.4031e-03) Intervals=40) ) }
  NewCurrentPrefix="c18_erase_fall_"
  Transient (
    InitialTime=1.4031e-03 FinalTime=1.4031e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 18 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c18_relax_"
  Transient (
    InitialTime=1.4031e-03 FinalTime=1.4731e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4031e-03 1.4731e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 19 (cycle base time = 1.4731e-03)
  *====================================================================
  NewCurrentPrefix="c19_p1_rise_"
  Transient (
    InitialTime=1.4731e-03 FinalTime=1.4731e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p1_write_"
  Transient (
    InitialTime=1.4731e-03 FinalTime=1.4732e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4731e-03 1.4732e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p1_fall_"
  Transient (
    InitialTime=1.4732e-03 FinalTime=1.4732e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p1_read_"
  Transient (
    InitialTime=1.4732e-03 FinalTime=1.4733e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4732e-03 1.4733e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p2_rise_"
  Transient (
    InitialTime=1.4733e-03 FinalTime=1.4733e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p2_write_"
  Transient (
    InitialTime=1.4733e-03 FinalTime=1.4734e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4733e-03 1.4734e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p2_fall_"
  Transient (
    InitialTime=1.4734e-03 FinalTime=1.4734e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p2_read_"
  Transient (
    InitialTime=1.4734e-03 FinalTime=1.4735e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4734e-03 1.4735e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p3_rise_"
  Transient (
    InitialTime=1.4735e-03 FinalTime=1.4735e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p3_write_"
  Transient (
    InitialTime=1.4735e-03 FinalTime=1.4736e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4735e-03 1.4736e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p3_fall_"
  Transient (
    InitialTime=1.4736e-03 FinalTime=1.4736e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p3_read_"
  Transient (
    InitialTime=1.4736e-03 FinalTime=1.4737e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4736e-03 1.4737e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p4_rise_"
  Transient (
    InitialTime=1.4737e-03 FinalTime=1.4737e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p4_write_"
  Transient (
    InitialTime=1.4737e-03 FinalTime=1.4738e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4737e-03 1.4738e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p4_fall_"
  Transient (
    InitialTime=1.4738e-03 FinalTime=1.4738e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p4_read_"
  Transient (
    InitialTime=1.4738e-03 FinalTime=1.4739e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4738e-03 1.4739e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p5_rise_"
  Transient (
    InitialTime=1.4739e-03 FinalTime=1.4739e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p5_write_"
  Transient (
    InitialTime=1.4739e-03 FinalTime=1.4740e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4739e-03 1.4740e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p5_fall_"
  Transient (
    InitialTime=1.4740e-03 FinalTime=1.4740e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p5_read_"
  Transient (
    InitialTime=1.4740e-03 FinalTime=1.4741e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4740e-03 1.4741e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p6_rise_"
  Transient (
    InitialTime=1.4741e-03 FinalTime=1.4741e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p6_write_"
  Transient (
    InitialTime=1.4741e-03 FinalTime=1.4742e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4741e-03 1.4742e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p6_fall_"
  Transient (
    InitialTime=1.4742e-03 FinalTime=1.4742e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p6_read_"
  Transient (
    InitialTime=1.4742e-03 FinalTime=1.4743e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4742e-03 1.4743e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p7_rise_"
  Transient (
    InitialTime=1.4743e-03 FinalTime=1.4743e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p7_write_"
  Transient (
    InitialTime=1.4743e-03 FinalTime=1.4744e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4743e-03 1.4744e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p7_fall_"
  Transient (
    InitialTime=1.4744e-03 FinalTime=1.4744e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p7_read_"
  Transient (
    InitialTime=1.4744e-03 FinalTime=1.4745e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4744e-03 1.4745e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p8_rise_"
  Transient (
    InitialTime=1.4745e-03 FinalTime=1.4745e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p8_write_"
  Transient (
    InitialTime=1.4745e-03 FinalTime=1.4746e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4745e-03 1.4746e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p8_fall_"
  Transient (
    InitialTime=1.4746e-03 FinalTime=1.4746e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p8_read_"
  Transient (
    InitialTime=1.4746e-03 FinalTime=1.4747e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4746e-03 1.4747e-03) Intervals=20) ) }
  NewCurrentPrefix="c19_p9_rise_"
  Transient (
    InitialTime=1.4747e-03 FinalTime=1.4747e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p9_write_"
  Transient (
    InitialTime=1.4747e-03 FinalTime=1.4748e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4747e-03 1.4748e-03) Intervals=10) ) }
  NewCurrentPrefix="c19_p9_fall_"
  Transient (
    InitialTime=1.4748e-03 FinalTime=1.4748e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_p9_read_"
  Transient (
    InitialTime=1.4748e-03 FinalTime=1.4749e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4748e-03 1.4749e-03) Intervals=20) ) }
  *--- CYCLE 19 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c19_erase_rise_"
  Transient (
    InitialTime=1.4749e-03 FinalTime=1.4749e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c19_erase_hold_"
  Transient (
    InitialTime=1.4749e-03 FinalTime=1.4849e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4749e-03 1.4849e-03) Intervals=40) ) }
  NewCurrentPrefix="c19_erase_fall_"
  Transient (
    InitialTime=1.4849e-03 FinalTime=1.4849e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 19 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c19_relax_"
  Transient (
    InitialTime=1.4849e-03 FinalTime=1.5549e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4849e-03 1.5549e-03) Intervals=70) ) }

  *====================================================================
  *== CYCLE 20 (cycle base time = 1.5549e-03)
  *====================================================================
  NewCurrentPrefix="c20_p1_rise_"
  Transient (
    InitialTime=1.5549e-03 FinalTime=1.5549e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p1_write_"
  Transient (
    InitialTime=1.5549e-03 FinalTime=1.5550e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5549e-03 1.5550e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p1_fall_"
  Transient (
    InitialTime=1.5550e-03 FinalTime=1.5550e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p1_read_"
  Transient (
    InitialTime=1.5550e-03 FinalTime=1.5551e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5550e-03 1.5551e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p2_rise_"
  Transient (
    InitialTime=1.5551e-03 FinalTime=1.5551e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p2_write_"
  Transient (
    InitialTime=1.5551e-03 FinalTime=1.5552e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5551e-03 1.5552e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p2_fall_"
  Transient (
    InitialTime=1.5552e-03 FinalTime=1.5552e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p2_read_"
  Transient (
    InitialTime=1.5552e-03 FinalTime=1.5553e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5552e-03 1.5553e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p3_rise_"
  Transient (
    InitialTime=1.5553e-03 FinalTime=1.5553e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p3_write_"
  Transient (
    InitialTime=1.5553e-03 FinalTime=1.5554e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5553e-03 1.5554e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p3_fall_"
  Transient (
    InitialTime=1.5554e-03 FinalTime=1.5554e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p3_read_"
  Transient (
    InitialTime=1.5554e-03 FinalTime=1.5555e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5554e-03 1.5555e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p4_rise_"
  Transient (
    InitialTime=1.5555e-03 FinalTime=1.5555e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p4_write_"
  Transient (
    InitialTime=1.5555e-03 FinalTime=1.5556e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5555e-03 1.5556e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p4_fall_"
  Transient (
    InitialTime=1.5556e-03 FinalTime=1.5556e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p4_read_"
  Transient (
    InitialTime=1.5556e-03 FinalTime=1.5557e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5556e-03 1.5557e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p5_rise_"
  Transient (
    InitialTime=1.5557e-03 FinalTime=1.5557e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p5_write_"
  Transient (
    InitialTime=1.5557e-03 FinalTime=1.5558e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5557e-03 1.5558e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p5_fall_"
  Transient (
    InitialTime=1.5558e-03 FinalTime=1.5558e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p5_read_"
  Transient (
    InitialTime=1.5558e-03 FinalTime=1.5559e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5558e-03 1.5559e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p6_rise_"
  Transient (
    InitialTime=1.5559e-03 FinalTime=1.5559e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p6_write_"
  Transient (
    InitialTime=1.5559e-03 FinalTime=1.5560e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5559e-03 1.5560e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p6_fall_"
  Transient (
    InitialTime=1.5560e-03 FinalTime=1.5560e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p6_read_"
  Transient (
    InitialTime=1.5560e-03 FinalTime=1.5561e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5560e-03 1.5561e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p7_rise_"
  Transient (
    InitialTime=1.5561e-03 FinalTime=1.5561e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p7_write_"
  Transient (
    InitialTime=1.5561e-03 FinalTime=1.5562e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5561e-03 1.5562e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p7_fall_"
  Transient (
    InitialTime=1.5562e-03 FinalTime=1.5562e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p7_read_"
  Transient (
    InitialTime=1.5562e-03 FinalTime=1.5563e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5562e-03 1.5563e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p8_rise_"
  Transient (
    InitialTime=1.5563e-03 FinalTime=1.5563e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p8_write_"
  Transient (
    InitialTime=1.5563e-03 FinalTime=1.5564e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5563e-03 1.5564e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p8_fall_"
  Transient (
    InitialTime=1.5564e-03 FinalTime=1.5564e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p8_read_"
  Transient (
    InitialTime=1.5564e-03 FinalTime=1.5565e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5564e-03 1.5565e-03) Intervals=20) ) }
  NewCurrentPrefix="c20_p9_rise_"
  Transient (
    InitialTime=1.5565e-03 FinalTime=1.5565e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p9_write_"
  Transient (
    InitialTime=1.5565e-03 FinalTime=1.5566e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5565e-03 1.5566e-03) Intervals=10) ) }
  NewCurrentPrefix="c20_p9_fall_"
  Transient (
    InitialTime=1.5566e-03 FinalTime=1.5566e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_p9_read_"
  Transient (
    InitialTime=1.5566e-03 FinalTime=1.5567e-03
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5566e-03 1.5567e-03) Intervals=20) ) }
  *--- CYCLE 20 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c20_erase_rise_"
  Transient (
    InitialTime=1.5567e-03 FinalTime=1.5567e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c20_erase_hold_"
  Transient (
    InitialTime=1.5567e-03 FinalTime=1.5668e-03
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5567e-03 1.5668e-03) Intervals=40) ) }
  NewCurrentPrefix="c20_erase_fall_"
  Transient (
    InitialTime=1.5668e-03 FinalTime=1.5668e-03
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  *--- CYCLE 20 RELAX (70 us at V_GS = -0.5 V) ---
  NewCurrentPrefix="c20_relax_"
  Transient (
    InitialTime=1.5668e-03 FinalTime=1.6368e-03
    InitialStep=1e-11 MaxStep=2e-6 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5668e-03 1.6368e-03) Intervals=70) ) }

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
