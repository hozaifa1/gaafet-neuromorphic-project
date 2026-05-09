*===================================================================
*== PHASE 1C — SIM F: MULTI-CYCLE ENDURANCE
*== 5 cycles of [9 pulses at 6.0V + reset at -5.0V].
*== Tracks per-cycle drift in baseline, fire current, post-reset state.
*== Each segment tagged cXX_ for per-cycle analysis.
*==
*== Use tau_P from simD result (set in sdevice_gaafet_lif.par).
*===================================================================

File {
    Grid = "@tdr@"
    Parameter = "sdevice_gaafet_lif.par"
    Plot = "@tdrdat@"
    Current = "@plot@"
    Output = "@log@"
}

Electrode {
  { Name="source_contact"     Voltage= 0.0 }
  { Name="drain_contact"      Voltage= 0.0 }
  { Name="gate_contact"       Voltage= 0.0  Workfunction=4.35 }
}

Physics {
  Temperature= 300
  Areafactor=0.071
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

  *=== STEP 1: SET DRAIN BIAS (VDS=0.05V) ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: SET GATE READ BIAS (VGS_read=0.2V) ===
  NewCurrentPrefix="gate_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *#################### CYCLE 1 of 5 ####################

  *=== Cycle 1: pre-cycle baseline read ===
  NewCurrentPrefix="c01_basepre_read_"
  Transient (
    InitialTime=0.0000e+00 FinalTime=1.0000e-07
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0.0000e+00 1.0000e-07) Intervals=20) )
  }

  *--- CYCLE 1 PULSE 1 ---
  NewCurrentPrefix="c01_p01_rise_"
  Transient (
    InitialTime=1.0000e-07 FinalTime=1.0100e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0000e-07 1.0100e-07) Intervals=5) )
  }
  NewCurrentPrefix="c01_p01_write_"
  Transient (
    InitialTime=1.0100e-07 FinalTime=2.0100e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0100e-07 2.0100e-07) Intervals=10) )
  }
  NewCurrentPrefix="c01_p01_fall_"
  Transient (
    InitialTime=2.0100e-07 FinalTime=2.0200e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0100e-07 2.0200e-07) Intervals=5) )
  }
  NewCurrentPrefix="c01_p01_read_"
  Transient (
    InitialTime=2.0200e-07 FinalTime=3.0200e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0200e-07 3.0200e-07) Intervals=20) )
  }

  *--- CYCLE 1 PULSE 2 ---
  NewCurrentPrefix="c01_p02_rise_"
  Transient (
    InitialTime=3.0200e-07 FinalTime=3.0300e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0200e-07 3.0300e-07) Intervals=5) )
  }
  NewCurrentPrefix="c01_p02_write_"
  Transient (
    InitialTime=3.0300e-07 FinalTime=4.0300e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0300e-07 4.0300e-07) Intervals=10) )
  }
  NewCurrentPrefix="c01_p02_fall_"
  Transient (
    InitialTime=4.0300e-07 FinalTime=4.0400e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0300e-07 4.0400e-07) Intervals=5) )
  }
  NewCurrentPrefix="c01_p02_read_"
  Transient (
    InitialTime=4.0400e-07 FinalTime=5.0400e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0400e-07 5.0400e-07) Intervals=20) )
  }

  *--- CYCLE 1 PULSE 3 ---
  NewCurrentPrefix="c01_p03_rise_"
  Transient (
    InitialTime=5.0400e-07 FinalTime=5.0500e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0400e-07 5.0500e-07) Intervals=5) )
  }
  NewCurrentPrefix="c01_p03_write_"
  Transient (
    InitialTime=5.0500e-07 FinalTime=6.0500e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0500e-07 6.0500e-07) Intervals=10) )
  }
  NewCurrentPrefix="c01_p03_fall_"
  Transient (
    InitialTime=6.0500e-07 FinalTime=6.0600e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0500e-07 6.0600e-07) Intervals=5) )
  }
  NewCurrentPrefix="c01_p03_read_"
  Transient (
    InitialTime=6.0600e-07 FinalTime=7.0600e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0600e-07 7.0600e-07) Intervals=20) )
  }

  *--- CYCLE 1 PULSE 4 ---
  NewCurrentPrefix="c01_p04_rise_"
  Transient (
    InitialTime=7.0600e-07 FinalTime=7.0700e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0600e-07 7.0700e-07) Intervals=5) )
  }
  NewCurrentPrefix="c01_p04_write_"
  Transient (
    InitialTime=7.0700e-07 FinalTime=8.0700e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0700e-07 8.0700e-07) Intervals=10) )
  }
  NewCurrentPrefix="c01_p04_fall_"
  Transient (
    InitialTime=8.0700e-07 FinalTime=8.0800e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0700e-07 8.0800e-07) Intervals=5) )
  }
  NewCurrentPrefix="c01_p04_read_"
  Transient (
    InitialTime=8.0800e-07 FinalTime=9.0800e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0800e-07 9.0800e-07) Intervals=20) )
  }

  *--- CYCLE 1 PULSE 5 ---
  NewCurrentPrefix="c01_p05_rise_"
  Transient (
    InitialTime=9.0800e-07 FinalTime=9.0900e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0800e-07 9.0900e-07) Intervals=5) )
  }
  NewCurrentPrefix="c01_p05_write_"
  Transient (
    InitialTime=9.0900e-07 FinalTime=1.0090e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0900e-07 1.0090e-06) Intervals=10) )
  }
  NewCurrentPrefix="c01_p05_fall_"
  Transient (
    InitialTime=1.0090e-06 FinalTime=1.0100e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0090e-06 1.0100e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_p05_read_"
  Transient (
    InitialTime=1.0100e-06 FinalTime=1.1100e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0100e-06 1.1100e-06) Intervals=20) )
  }

  *--- CYCLE 1 PULSE 6 ---
  NewCurrentPrefix="c01_p06_rise_"
  Transient (
    InitialTime=1.1100e-06 FinalTime=1.1110e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1100e-06 1.1110e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_p06_write_"
  Transient (
    InitialTime=1.1110e-06 FinalTime=1.2110e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1110e-06 1.2110e-06) Intervals=10) )
  }
  NewCurrentPrefix="c01_p06_fall_"
  Transient (
    InitialTime=1.2110e-06 FinalTime=1.2120e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2110e-06 1.2120e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_p06_read_"
  Transient (
    InitialTime=1.2120e-06 FinalTime=1.3120e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2120e-06 1.3120e-06) Intervals=20) )
  }

  *--- CYCLE 1 PULSE 7 ---
  NewCurrentPrefix="c01_p07_rise_"
  Transient (
    InitialTime=1.3120e-06 FinalTime=1.3130e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3120e-06 1.3130e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_p07_write_"
  Transient (
    InitialTime=1.3130e-06 FinalTime=1.4130e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3130e-06 1.4130e-06) Intervals=10) )
  }
  NewCurrentPrefix="c01_p07_fall_"
  Transient (
    InitialTime=1.4130e-06 FinalTime=1.4140e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4130e-06 1.4140e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_p07_read_"
  Transient (
    InitialTime=1.4140e-06 FinalTime=1.5140e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4140e-06 1.5140e-06) Intervals=20) )
  }

  *--- CYCLE 1 PULSE 8 ---
  NewCurrentPrefix="c01_p08_rise_"
  Transient (
    InitialTime=1.5140e-06 FinalTime=1.5150e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5140e-06 1.5150e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_p08_write_"
  Transient (
    InitialTime=1.5150e-06 FinalTime=1.6150e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5150e-06 1.6150e-06) Intervals=10) )
  }
  NewCurrentPrefix="c01_p08_fall_"
  Transient (
    InitialTime=1.6150e-06 FinalTime=1.6160e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6150e-06 1.6160e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_p08_read_"
  Transient (
    InitialTime=1.6160e-06 FinalTime=1.7160e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6160e-06 1.7160e-06) Intervals=20) )
  }

  *--- CYCLE 1 PULSE 9 ---
  NewCurrentPrefix="c01_p09_rise_"
  Transient (
    InitialTime=1.7160e-06 FinalTime=1.7170e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7160e-06 1.7170e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_p09_write_"
  Transient (
    InitialTime=1.7170e-06 FinalTime=1.8170e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7170e-06 1.8170e-06) Intervals=10) )
  }
  NewCurrentPrefix="c01_p09_fall_"
  Transient (
    InitialTime=1.8170e-06 FinalTime=1.8180e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.8170e-06 1.8180e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_p09_read_"
  Transient (
    InitialTime=1.8180e-06 FinalTime=1.9180e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.8180e-06 1.9180e-06) Intervals=20) )
  }

  *=== Cycle 1: reset (-5.0V) ===
  NewCurrentPrefix="c01_reset_rise_"
  Transient (
    InitialTime=1.9180e-06 FinalTime=1.9190e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -5.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.9180e-06 1.9190e-06) Intervals=5) )
  }
  NewCurrentPrefix="c01_reset_hold_"
  Transient (
    InitialTime=1.9190e-06 FinalTime=2.9190e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.9190e-06 2.9190e-06) Intervals=20) )
  }
  NewCurrentPrefix="c01_reset_fall_"
  Transient (
    InitialTime=2.9190e-06 FinalTime=2.9200e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.9190e-06 2.9200e-06) Intervals=5) )
  }

  *=== Cycle 1: post-reset read ===
  NewCurrentPrefix="c01_postreset_read_"
  Transient (
    InitialTime=2.9200e-06 FinalTime=3.0200e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.9200e-06 3.0200e-06) Intervals=20) )
  }

  *#################### CYCLE 2 of 5 ####################

  *=== Cycle 2: pre-cycle baseline read ===
  NewCurrentPrefix="c02_basepre_read_"
  Transient (
    InitialTime=3.0200e-06 FinalTime=3.1200e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0200e-06 3.1200e-06) Intervals=20) )
  }

  *--- CYCLE 2 PULSE 1 ---
  NewCurrentPrefix="c02_p01_rise_"
  Transient (
    InitialTime=3.1200e-06 FinalTime=3.1210e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.1200e-06 3.1210e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p01_write_"
  Transient (
    InitialTime=3.1210e-06 FinalTime=3.2210e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.1210e-06 3.2210e-06) Intervals=10) )
  }
  NewCurrentPrefix="c02_p01_fall_"
  Transient (
    InitialTime=3.2210e-06 FinalTime=3.2220e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2210e-06 3.2220e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p01_read_"
  Transient (
    InitialTime=3.2220e-06 FinalTime=3.3220e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.2220e-06 3.3220e-06) Intervals=20) )
  }

  *--- CYCLE 2 PULSE 2 ---
  NewCurrentPrefix="c02_p02_rise_"
  Transient (
    InitialTime=3.3220e-06 FinalTime=3.3230e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.3220e-06 3.3230e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p02_write_"
  Transient (
    InitialTime=3.3230e-06 FinalTime=3.4230e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.3230e-06 3.4230e-06) Intervals=10) )
  }
  NewCurrentPrefix="c02_p02_fall_"
  Transient (
    InitialTime=3.4230e-06 FinalTime=3.4240e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.4230e-06 3.4240e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p02_read_"
  Transient (
    InitialTime=3.4240e-06 FinalTime=3.5240e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.4240e-06 3.5240e-06) Intervals=20) )
  }

  *--- CYCLE 2 PULSE 3 ---
  NewCurrentPrefix="c02_p03_rise_"
  Transient (
    InitialTime=3.5240e-06 FinalTime=3.5250e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.5240e-06 3.5250e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p03_write_"
  Transient (
    InitialTime=3.5250e-06 FinalTime=3.6250e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.5250e-06 3.6250e-06) Intervals=10) )
  }
  NewCurrentPrefix="c02_p03_fall_"
  Transient (
    InitialTime=3.6250e-06 FinalTime=3.6260e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.6250e-06 3.6260e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p03_read_"
  Transient (
    InitialTime=3.6260e-06 FinalTime=3.7260e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.6260e-06 3.7260e-06) Intervals=20) )
  }

  *--- CYCLE 2 PULSE 4 ---
  NewCurrentPrefix="c02_p04_rise_"
  Transient (
    InitialTime=3.7260e-06 FinalTime=3.7270e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.7260e-06 3.7270e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p04_write_"
  Transient (
    InitialTime=3.7270e-06 FinalTime=3.8270e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.7270e-06 3.8270e-06) Intervals=10) )
  }
  NewCurrentPrefix="c02_p04_fall_"
  Transient (
    InitialTime=3.8270e-06 FinalTime=3.8280e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.8270e-06 3.8280e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p04_read_"
  Transient (
    InitialTime=3.8280e-06 FinalTime=3.9280e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.8280e-06 3.9280e-06) Intervals=20) )
  }

  *--- CYCLE 2 PULSE 5 ---
  NewCurrentPrefix="c02_p05_rise_"
  Transient (
    InitialTime=3.9280e-06 FinalTime=3.9290e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9280e-06 3.9290e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p05_write_"
  Transient (
    InitialTime=3.9290e-06 FinalTime=4.0290e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.9290e-06 4.0290e-06) Intervals=10) )
  }
  NewCurrentPrefix="c02_p05_fall_"
  Transient (
    InitialTime=4.0290e-06 FinalTime=4.0300e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0290e-06 4.0300e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p05_read_"
  Transient (
    InitialTime=4.0300e-06 FinalTime=4.1300e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0300e-06 4.1300e-06) Intervals=20) )
  }

  *--- CYCLE 2 PULSE 6 ---
  NewCurrentPrefix="c02_p06_rise_"
  Transient (
    InitialTime=4.1300e-06 FinalTime=4.1310e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1300e-06 4.1310e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p06_write_"
  Transient (
    InitialTime=4.1310e-06 FinalTime=4.2310e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1310e-06 4.2310e-06) Intervals=10) )
  }
  NewCurrentPrefix="c02_p06_fall_"
  Transient (
    InitialTime=4.2310e-06 FinalTime=4.2320e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.2310e-06 4.2320e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p06_read_"
  Transient (
    InitialTime=4.2320e-06 FinalTime=4.3320e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.2320e-06 4.3320e-06) Intervals=20) )
  }

  *--- CYCLE 2 PULSE 7 ---
  NewCurrentPrefix="c02_p07_rise_"
  Transient (
    InitialTime=4.3320e-06 FinalTime=4.3330e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.3320e-06 4.3330e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p07_write_"
  Transient (
    InitialTime=4.3330e-06 FinalTime=4.4330e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.3330e-06 4.4330e-06) Intervals=10) )
  }
  NewCurrentPrefix="c02_p07_fall_"
  Transient (
    InitialTime=4.4330e-06 FinalTime=4.4340e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.4330e-06 4.4340e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p07_read_"
  Transient (
    InitialTime=4.4340e-06 FinalTime=4.5340e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.4340e-06 4.5340e-06) Intervals=20) )
  }

  *--- CYCLE 2 PULSE 8 ---
  NewCurrentPrefix="c02_p08_rise_"
  Transient (
    InitialTime=4.5340e-06 FinalTime=4.5350e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.5340e-06 4.5350e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p08_write_"
  Transient (
    InitialTime=4.5350e-06 FinalTime=4.6350e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.5350e-06 4.6350e-06) Intervals=10) )
  }
  NewCurrentPrefix="c02_p08_fall_"
  Transient (
    InitialTime=4.6350e-06 FinalTime=4.6360e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.6350e-06 4.6360e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p08_read_"
  Transient (
    InitialTime=4.6360e-06 FinalTime=4.7360e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.6360e-06 4.7360e-06) Intervals=20) )
  }

  *--- CYCLE 2 PULSE 9 ---
  NewCurrentPrefix="c02_p09_rise_"
  Transient (
    InitialTime=4.7360e-06 FinalTime=4.7370e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.7360e-06 4.7370e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p09_write_"
  Transient (
    InitialTime=4.7370e-06 FinalTime=4.8370e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.7370e-06 4.8370e-06) Intervals=10) )
  }
  NewCurrentPrefix="c02_p09_fall_"
  Transient (
    InitialTime=4.8370e-06 FinalTime=4.8380e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8370e-06 4.8380e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_p09_read_"
  Transient (
    InitialTime=4.8380e-06 FinalTime=4.9380e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8380e-06 4.9380e-06) Intervals=20) )
  }

  *=== Cycle 2: reset (-5.0V) ===
  NewCurrentPrefix="c02_reset_rise_"
  Transient (
    InitialTime=4.9380e-06 FinalTime=4.9390e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -5.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9380e-06 4.9390e-06) Intervals=5) )
  }
  NewCurrentPrefix="c02_reset_hold_"
  Transient (
    InitialTime=4.9390e-06 FinalTime=5.9390e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.9390e-06 5.9390e-06) Intervals=20) )
  }
  NewCurrentPrefix="c02_reset_fall_"
  Transient (
    InitialTime=5.9390e-06 FinalTime=5.9400e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.9390e-06 5.9400e-06) Intervals=5) )
  }

  *=== Cycle 2: post-reset read ===
  NewCurrentPrefix="c02_postreset_read_"
  Transient (
    InitialTime=5.9400e-06 FinalTime=6.0400e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.9400e-06 6.0400e-06) Intervals=20) )
  }

  *#################### CYCLE 3 of 5 ####################

  *=== Cycle 3: pre-cycle baseline read ===
  NewCurrentPrefix="c03_basepre_read_"
  Transient (
    InitialTime=6.0400e-06 FinalTime=6.1400e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0400e-06 6.1400e-06) Intervals=20) )
  }

  *--- CYCLE 3 PULSE 1 ---
  NewCurrentPrefix="c03_p01_rise_"
  Transient (
    InitialTime=6.1400e-06 FinalTime=6.1410e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.1400e-06 6.1410e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p01_write_"
  Transient (
    InitialTime=6.1410e-06 FinalTime=6.2410e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.1410e-06 6.2410e-06) Intervals=10) )
  }
  NewCurrentPrefix="c03_p01_fall_"
  Transient (
    InitialTime=6.2410e-06 FinalTime=6.2420e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.2410e-06 6.2420e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p01_read_"
  Transient (
    InitialTime=6.2420e-06 FinalTime=6.3420e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.2420e-06 6.3420e-06) Intervals=20) )
  }

  *--- CYCLE 3 PULSE 2 ---
  NewCurrentPrefix="c03_p02_rise_"
  Transient (
    InitialTime=6.3420e-06 FinalTime=6.3430e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.3420e-06 6.3430e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p02_write_"
  Transient (
    InitialTime=6.3430e-06 FinalTime=6.4430e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.3430e-06 6.4430e-06) Intervals=10) )
  }
  NewCurrentPrefix="c03_p02_fall_"
  Transient (
    InitialTime=6.4430e-06 FinalTime=6.4440e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4430e-06 6.4440e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p02_read_"
  Transient (
    InitialTime=6.4440e-06 FinalTime=6.5440e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.4440e-06 6.5440e-06) Intervals=20) )
  }

  *--- CYCLE 3 PULSE 3 ---
  NewCurrentPrefix="c03_p03_rise_"
  Transient (
    InitialTime=6.5440e-06 FinalTime=6.5450e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5440e-06 6.5450e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p03_write_"
  Transient (
    InitialTime=6.5450e-06 FinalTime=6.6450e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.5450e-06 6.6450e-06) Intervals=10) )
  }
  NewCurrentPrefix="c03_p03_fall_"
  Transient (
    InitialTime=6.6450e-06 FinalTime=6.6460e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.6450e-06 6.6460e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p03_read_"
  Transient (
    InitialTime=6.6460e-06 FinalTime=6.7460e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.6460e-06 6.7460e-06) Intervals=20) )
  }

  *--- CYCLE 3 PULSE 4 ---
  NewCurrentPrefix="c03_p04_rise_"
  Transient (
    InitialTime=6.7460e-06 FinalTime=6.7470e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.7460e-06 6.7470e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p04_write_"
  Transient (
    InitialTime=6.7470e-06 FinalTime=6.8470e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.7470e-06 6.8470e-06) Intervals=10) )
  }
  NewCurrentPrefix="c03_p04_fall_"
  Transient (
    InitialTime=6.8470e-06 FinalTime=6.8480e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.8470e-06 6.8480e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p04_read_"
  Transient (
    InitialTime=6.8480e-06 FinalTime=6.9480e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.8480e-06 6.9480e-06) Intervals=20) )
  }

  *--- CYCLE 3 PULSE 5 ---
  NewCurrentPrefix="c03_p05_rise_"
  Transient (
    InitialTime=6.9480e-06 FinalTime=6.9490e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.9480e-06 6.9490e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p05_write_"
  Transient (
    InitialTime=6.9490e-06 FinalTime=7.0490e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.9490e-06 7.0490e-06) Intervals=10) )
  }
  NewCurrentPrefix="c03_p05_fall_"
  Transient (
    InitialTime=7.0490e-06 FinalTime=7.0500e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0490e-06 7.0500e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p05_read_"
  Transient (
    InitialTime=7.0500e-06 FinalTime=7.1500e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0500e-06 7.1500e-06) Intervals=20) )
  }

  *--- CYCLE 3 PULSE 6 ---
  NewCurrentPrefix="c03_p06_rise_"
  Transient (
    InitialTime=7.1500e-06 FinalTime=7.1510e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.1500e-06 7.1510e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p06_write_"
  Transient (
    InitialTime=7.1510e-06 FinalTime=7.2510e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.1510e-06 7.2510e-06) Intervals=10) )
  }
  NewCurrentPrefix="c03_p06_fall_"
  Transient (
    InitialTime=7.2510e-06 FinalTime=7.2520e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.2510e-06 7.2520e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p06_read_"
  Transient (
    InitialTime=7.2520e-06 FinalTime=7.3520e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.2520e-06 7.3520e-06) Intervals=20) )
  }

  *--- CYCLE 3 PULSE 7 ---
  NewCurrentPrefix="c03_p07_rise_"
  Transient (
    InitialTime=7.3520e-06 FinalTime=7.3530e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3520e-06 7.3530e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p07_write_"
  Transient (
    InitialTime=7.3530e-06 FinalTime=7.4530e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.3530e-06 7.4530e-06) Intervals=10) )
  }
  NewCurrentPrefix="c03_p07_fall_"
  Transient (
    InitialTime=7.4530e-06 FinalTime=7.4540e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.4530e-06 7.4540e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p07_read_"
  Transient (
    InitialTime=7.4540e-06 FinalTime=7.5540e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.4540e-06 7.5540e-06) Intervals=20) )
  }

  *--- CYCLE 3 PULSE 8 ---
  NewCurrentPrefix="c03_p08_rise_"
  Transient (
    InitialTime=7.5540e-06 FinalTime=7.5550e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.5540e-06 7.5550e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p08_write_"
  Transient (
    InitialTime=7.5550e-06 FinalTime=7.6550e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.5550e-06 7.6550e-06) Intervals=10) )
  }
  NewCurrentPrefix="c03_p08_fall_"
  Transient (
    InitialTime=7.6550e-06 FinalTime=7.6560e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.6550e-06 7.6560e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p08_read_"
  Transient (
    InitialTime=7.6560e-06 FinalTime=7.7560e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.6560e-06 7.7560e-06) Intervals=20) )
  }

  *--- CYCLE 3 PULSE 9 ---
  NewCurrentPrefix="c03_p09_rise_"
  Transient (
    InitialTime=7.7560e-06 FinalTime=7.7570e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.7560e-06 7.7570e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p09_write_"
  Transient (
    InitialTime=7.7570e-06 FinalTime=7.8570e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.7570e-06 7.8570e-06) Intervals=10) )
  }
  NewCurrentPrefix="c03_p09_fall_"
  Transient (
    InitialTime=7.8570e-06 FinalTime=7.8580e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.8570e-06 7.8580e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_p09_read_"
  Transient (
    InitialTime=7.8580e-06 FinalTime=7.9580e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.8580e-06 7.9580e-06) Intervals=20) )
  }

  *=== Cycle 3: reset (-5.0V) ===
  NewCurrentPrefix="c03_reset_rise_"
  Transient (
    InitialTime=7.9580e-06 FinalTime=7.9590e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -5.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.9580e-06 7.9590e-06) Intervals=5) )
  }
  NewCurrentPrefix="c03_reset_hold_"
  Transient (
    InitialTime=7.9590e-06 FinalTime=8.9590e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.9590e-06 8.9590e-06) Intervals=20) )
  }
  NewCurrentPrefix="c03_reset_fall_"
  Transient (
    InitialTime=8.9590e-06 FinalTime=8.9600e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9590e-06 8.9600e-06) Intervals=5) )
  }

  *=== Cycle 3: post-reset read ===
  NewCurrentPrefix="c03_postreset_read_"
  Transient (
    InitialTime=8.9600e-06 FinalTime=9.0600e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9600e-06 9.0600e-06) Intervals=20) )
  }

  *#################### CYCLE 4 of 5 ####################

  *=== Cycle 4: pre-cycle baseline read ===
  NewCurrentPrefix="c04_basepre_read_"
  Transient (
    InitialTime=9.0600e-06 FinalTime=9.1600e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0600e-06 9.1600e-06) Intervals=20) )
  }

  *--- CYCLE 4 PULSE 1 ---
  NewCurrentPrefix="c04_p01_rise_"
  Transient (
    InitialTime=9.1600e-06 FinalTime=9.1610e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1600e-06 9.1610e-06) Intervals=5) )
  }
  NewCurrentPrefix="c04_p01_write_"
  Transient (
    InitialTime=9.1610e-06 FinalTime=9.2610e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1610e-06 9.2610e-06) Intervals=10) )
  }
  NewCurrentPrefix="c04_p01_fall_"
  Transient (
    InitialTime=9.2610e-06 FinalTime=9.2620e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.2610e-06 9.2620e-06) Intervals=5) )
  }
  NewCurrentPrefix="c04_p01_read_"
  Transient (
    InitialTime=9.2620e-06 FinalTime=9.3620e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.2620e-06 9.3620e-06) Intervals=20) )
  }

  *--- CYCLE 4 PULSE 2 ---
  NewCurrentPrefix="c04_p02_rise_"
  Transient (
    InitialTime=9.3620e-06 FinalTime=9.3630e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.3620e-06 9.3630e-06) Intervals=5) )
  }
  NewCurrentPrefix="c04_p02_write_"
  Transient (
    InitialTime=9.3630e-06 FinalTime=9.4630e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.3630e-06 9.4630e-06) Intervals=10) )
  }
  NewCurrentPrefix="c04_p02_fall_"
  Transient (
    InitialTime=9.4630e-06 FinalTime=9.4640e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.4630e-06 9.4640e-06) Intervals=5) )
  }
  NewCurrentPrefix="c04_p02_read_"
  Transient (
    InitialTime=9.4640e-06 FinalTime=9.5640e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.4640e-06 9.5640e-06) Intervals=20) )
  }

  *--- CYCLE 4 PULSE 3 ---
  NewCurrentPrefix="c04_p03_rise_"
  Transient (
    InitialTime=9.5640e-06 FinalTime=9.5650e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.5640e-06 9.5650e-06) Intervals=5) )
  }
  NewCurrentPrefix="c04_p03_write_"
  Transient (
    InitialTime=9.5650e-06 FinalTime=9.6650e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.5650e-06 9.6650e-06) Intervals=10) )
  }
  NewCurrentPrefix="c04_p03_fall_"
  Transient (
    InitialTime=9.6650e-06 FinalTime=9.6660e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.6650e-06 9.6660e-06) Intervals=5) )
  }
  NewCurrentPrefix="c04_p03_read_"
  Transient (
    InitialTime=9.6660e-06 FinalTime=9.7660e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.6660e-06 9.7660e-06) Intervals=20) )
  }

  *--- CYCLE 4 PULSE 4 ---
  NewCurrentPrefix="c04_p04_rise_"
  Transient (
    InitialTime=9.7660e-06 FinalTime=9.7670e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7660e-06 9.7670e-06) Intervals=5) )
  }
  NewCurrentPrefix="c04_p04_write_"
  Transient (
    InitialTime=9.7670e-06 FinalTime=9.8670e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7670e-06 9.8670e-06) Intervals=10) )
  }
  NewCurrentPrefix="c04_p04_fall_"
  Transient (
    InitialTime=9.8670e-06 FinalTime=9.8680e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8670e-06 9.8680e-06) Intervals=5) )
  }
  NewCurrentPrefix="c04_p04_read_"
  Transient (
    InitialTime=9.8680e-06 FinalTime=9.9680e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8680e-06 9.9680e-06) Intervals=20) )
  }

  *--- CYCLE 4 PULSE 5 ---
  NewCurrentPrefix="c04_p05_rise_"
  Transient (
    InitialTime=9.9680e-06 FinalTime=9.9690e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.9680e-06 9.9690e-06) Intervals=5) )
  }
  NewCurrentPrefix="c04_p05_write_"
  Transient (
    InitialTime=9.9690e-06 FinalTime=1.0069e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.9690e-06 1.0069e-05) Intervals=10) )
  }
  NewCurrentPrefix="c04_p05_fall_"
  Transient (
    InitialTime=1.0069e-05 FinalTime=1.0070e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0069e-05 1.0070e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_p05_read_"
  Transient (
    InitialTime=1.0070e-05 FinalTime=1.0170e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0070e-05 1.0170e-05) Intervals=20) )
  }

  *--- CYCLE 4 PULSE 6 ---
  NewCurrentPrefix="c04_p06_rise_"
  Transient (
    InitialTime=1.0170e-05 FinalTime=1.0171e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0170e-05 1.0171e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_p06_write_"
  Transient (
    InitialTime=1.0171e-05 FinalTime=1.0271e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0171e-05 1.0271e-05) Intervals=10) )
  }
  NewCurrentPrefix="c04_p06_fall_"
  Transient (
    InitialTime=1.0271e-05 FinalTime=1.0272e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0271e-05 1.0272e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_p06_read_"
  Transient (
    InitialTime=1.0272e-05 FinalTime=1.0372e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0272e-05 1.0372e-05) Intervals=20) )
  }

  *--- CYCLE 4 PULSE 7 ---
  NewCurrentPrefix="c04_p07_rise_"
  Transient (
    InitialTime=1.0372e-05 FinalTime=1.0373e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0372e-05 1.0373e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_p07_write_"
  Transient (
    InitialTime=1.0373e-05 FinalTime=1.0473e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0373e-05 1.0473e-05) Intervals=10) )
  }
  NewCurrentPrefix="c04_p07_fall_"
  Transient (
    InitialTime=1.0473e-05 FinalTime=1.0474e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0473e-05 1.0474e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_p07_read_"
  Transient (
    InitialTime=1.0474e-05 FinalTime=1.0574e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0474e-05 1.0574e-05) Intervals=20) )
  }

  *--- CYCLE 4 PULSE 8 ---
  NewCurrentPrefix="c04_p08_rise_"
  Transient (
    InitialTime=1.0574e-05 FinalTime=1.0575e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0574e-05 1.0575e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_p08_write_"
  Transient (
    InitialTime=1.0575e-05 FinalTime=1.0675e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0575e-05 1.0675e-05) Intervals=10) )
  }
  NewCurrentPrefix="c04_p08_fall_"
  Transient (
    InitialTime=1.0675e-05 FinalTime=1.0676e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0675e-05 1.0676e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_p08_read_"
  Transient (
    InitialTime=1.0676e-05 FinalTime=1.0776e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0676e-05 1.0776e-05) Intervals=20) )
  }

  *--- CYCLE 4 PULSE 9 ---
  NewCurrentPrefix="c04_p09_rise_"
  Transient (
    InitialTime=1.0776e-05 FinalTime=1.0777e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0776e-05 1.0777e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_p09_write_"
  Transient (
    InitialTime=1.0777e-05 FinalTime=1.0877e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0777e-05 1.0877e-05) Intervals=10) )
  }
  NewCurrentPrefix="c04_p09_fall_"
  Transient (
    InitialTime=1.0877e-05 FinalTime=1.0878e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0877e-05 1.0878e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_p09_read_"
  Transient (
    InitialTime=1.0878e-05 FinalTime=1.0978e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0878e-05 1.0978e-05) Intervals=20) )
  }

  *=== Cycle 4: reset (-5.0V) ===
  NewCurrentPrefix="c04_reset_rise_"
  Transient (
    InitialTime=1.0978e-05 FinalTime=1.0979e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -5.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0978e-05 1.0979e-05) Intervals=5) )
  }
  NewCurrentPrefix="c04_reset_hold_"
  Transient (
    InitialTime=1.0979e-05 FinalTime=1.1979e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0979e-05 1.1979e-05) Intervals=20) )
  }
  NewCurrentPrefix="c04_reset_fall_"
  Transient (
    InitialTime=1.1979e-05 FinalTime=1.1980e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1979e-05 1.1980e-05) Intervals=5) )
  }

  *=== Cycle 4: post-reset read ===
  NewCurrentPrefix="c04_postreset_read_"
  Transient (
    InitialTime=1.1980e-05 FinalTime=1.2080e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1980e-05 1.2080e-05) Intervals=20) )
  }

  *#################### CYCLE 5 of 5 ####################

  *=== Cycle 5: pre-cycle baseline read ===
  NewCurrentPrefix="c05_basepre_read_"
  Transient (
    InitialTime=1.2080e-05 FinalTime=1.2180e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2080e-05 1.2180e-05) Intervals=20) )
  }

  *--- CYCLE 5 PULSE 1 ---
  NewCurrentPrefix="c05_p01_rise_"
  Transient (
    InitialTime=1.2180e-05 FinalTime=1.2181e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2180e-05 1.2181e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p01_write_"
  Transient (
    InitialTime=1.2181e-05 FinalTime=1.2281e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2181e-05 1.2281e-05) Intervals=10) )
  }
  NewCurrentPrefix="c05_p01_fall_"
  Transient (
    InitialTime=1.2281e-05 FinalTime=1.2282e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2281e-05 1.2282e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p01_read_"
  Transient (
    InitialTime=1.2282e-05 FinalTime=1.2382e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2282e-05 1.2382e-05) Intervals=20) )
  }

  *--- CYCLE 5 PULSE 2 ---
  NewCurrentPrefix="c05_p02_rise_"
  Transient (
    InitialTime=1.2382e-05 FinalTime=1.2383e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2382e-05 1.2383e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p02_write_"
  Transient (
    InitialTime=1.2383e-05 FinalTime=1.2483e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2383e-05 1.2483e-05) Intervals=10) )
  }
  NewCurrentPrefix="c05_p02_fall_"
  Transient (
    InitialTime=1.2483e-05 FinalTime=1.2484e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2483e-05 1.2484e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p02_read_"
  Transient (
    InitialTime=1.2484e-05 FinalTime=1.2584e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2484e-05 1.2584e-05) Intervals=20) )
  }

  *--- CYCLE 5 PULSE 3 ---
  NewCurrentPrefix="c05_p03_rise_"
  Transient (
    InitialTime=1.2584e-05 FinalTime=1.2585e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2584e-05 1.2585e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p03_write_"
  Transient (
    InitialTime=1.2585e-05 FinalTime=1.2685e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2585e-05 1.2685e-05) Intervals=10) )
  }
  NewCurrentPrefix="c05_p03_fall_"
  Transient (
    InitialTime=1.2685e-05 FinalTime=1.2686e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2685e-05 1.2686e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p03_read_"
  Transient (
    InitialTime=1.2686e-05 FinalTime=1.2786e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2686e-05 1.2786e-05) Intervals=20) )
  }

  *--- CYCLE 5 PULSE 4 ---
  NewCurrentPrefix="c05_p04_rise_"
  Transient (
    InitialTime=1.2786e-05 FinalTime=1.2787e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2786e-05 1.2787e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p04_write_"
  Transient (
    InitialTime=1.2787e-05 FinalTime=1.2887e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2787e-05 1.2887e-05) Intervals=10) )
  }
  NewCurrentPrefix="c05_p04_fall_"
  Transient (
    InitialTime=1.2887e-05 FinalTime=1.2888e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2887e-05 1.2888e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p04_read_"
  Transient (
    InitialTime=1.2888e-05 FinalTime=1.2988e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2888e-05 1.2988e-05) Intervals=20) )
  }

  *--- CYCLE 5 PULSE 5 ---
  NewCurrentPrefix="c05_p05_rise_"
  Transient (
    InitialTime=1.2988e-05 FinalTime=1.2989e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2988e-05 1.2989e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p05_write_"
  Transient (
    InitialTime=1.2989e-05 FinalTime=1.3089e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2989e-05 1.3089e-05) Intervals=10) )
  }
  NewCurrentPrefix="c05_p05_fall_"
  Transient (
    InitialTime=1.3089e-05 FinalTime=1.3090e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3089e-05 1.3090e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p05_read_"
  Transient (
    InitialTime=1.3090e-05 FinalTime=1.3190e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3090e-05 1.3190e-05) Intervals=20) )
  }

  *--- CYCLE 5 PULSE 6 ---
  NewCurrentPrefix="c05_p06_rise_"
  Transient (
    InitialTime=1.3190e-05 FinalTime=1.3191e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3190e-05 1.3191e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p06_write_"
  Transient (
    InitialTime=1.3191e-05 FinalTime=1.3291e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3191e-05 1.3291e-05) Intervals=10) )
  }
  NewCurrentPrefix="c05_p06_fall_"
  Transient (
    InitialTime=1.3291e-05 FinalTime=1.3292e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3291e-05 1.3292e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p06_read_"
  Transient (
    InitialTime=1.3292e-05 FinalTime=1.3392e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3292e-05 1.3392e-05) Intervals=20) )
  }

  *--- CYCLE 5 PULSE 7 ---
  NewCurrentPrefix="c05_p07_rise_"
  Transient (
    InitialTime=1.3392e-05 FinalTime=1.3393e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3392e-05 1.3393e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p07_write_"
  Transient (
    InitialTime=1.3393e-05 FinalTime=1.3493e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3393e-05 1.3493e-05) Intervals=10) )
  }
  NewCurrentPrefix="c05_p07_fall_"
  Transient (
    InitialTime=1.3493e-05 FinalTime=1.3494e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3493e-05 1.3494e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p07_read_"
  Transient (
    InitialTime=1.3494e-05 FinalTime=1.3594e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3494e-05 1.3594e-05) Intervals=20) )
  }

  *--- CYCLE 5 PULSE 8 ---
  NewCurrentPrefix="c05_p08_rise_"
  Transient (
    InitialTime=1.3594e-05 FinalTime=1.3595e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3594e-05 1.3595e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p08_write_"
  Transient (
    InitialTime=1.3595e-05 FinalTime=1.3695e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3595e-05 1.3695e-05) Intervals=10) )
  }
  NewCurrentPrefix="c05_p08_fall_"
  Transient (
    InitialTime=1.3695e-05 FinalTime=1.3696e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3695e-05 1.3696e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p08_read_"
  Transient (
    InitialTime=1.3696e-05 FinalTime=1.3796e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3696e-05 1.3796e-05) Intervals=20) )
  }

  *--- CYCLE 5 PULSE 9 ---
  NewCurrentPrefix="c05_p09_rise_"
  Transient (
    InitialTime=1.3796e-05 FinalTime=1.3797e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3796e-05 1.3797e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p09_write_"
  Transient (
    InitialTime=1.3797e-05 FinalTime=1.3897e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3797e-05 1.3897e-05) Intervals=10) )
  }
  NewCurrentPrefix="c05_p09_fall_"
  Transient (
    InitialTime=1.3897e-05 FinalTime=1.3898e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3897e-05 1.3898e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_p09_read_"
  Transient (
    InitialTime=1.3898e-05 FinalTime=1.3998e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3898e-05 1.3998e-05) Intervals=20) )
  }

  *=== Cycle 5: reset (-5.0V) ===
  NewCurrentPrefix="c05_reset_rise_"
  Transient (
    InitialTime=1.3998e-05 FinalTime=1.3999e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -5.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3998e-05 1.3999e-05) Intervals=5) )
  }
  NewCurrentPrefix="c05_reset_hold_"
  Transient (
    InitialTime=1.3999e-05 FinalTime=1.4999e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3999e-05 1.4999e-05) Intervals=20) )
  }
  NewCurrentPrefix="c05_reset_fall_"
  Transient (
    InitialTime=1.4999e-05 FinalTime=1.5000e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4999e-05 1.5000e-05) Intervals=5) )
  }

  *=== Cycle 5: post-reset read ===
  NewCurrentPrefix="c05_postreset_read_"
  Transient (
    InitialTime=1.5000e-05 FinalTime=1.5100e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5000e-05 1.5100e-05) Intervals=20) )
  }

}
