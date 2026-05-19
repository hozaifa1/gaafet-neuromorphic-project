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
  *--- CYCLE 1 ERASE (rise / 10 us hold / fall) ---
  NewCurrentPrefix="c1_erase_rise_"
  Transient (
    InitialTime=1.8180e-06 FinalTime=1.8280e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_erase@ }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= @V_erase@ }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= @V_erase@ }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= @V_erase@ }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= 2.0 }
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
    Goal { Name="gate_contact" Voltage= @V_erase@ }
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
