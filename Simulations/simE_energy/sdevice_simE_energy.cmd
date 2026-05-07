*===================================================================
*== PHASE 1C — SIM E: HIGH-RESOLUTION ENERGY EXTRACTION
*== 9 pulses at Vpulse=6.0V, dense sampling for power integration.
*== Intervals: rise=20 write=100 fall=20 read=50
*== Post-process with extract_energy.py for E_pulse and E_fire_total.
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

  *=== BASELINE READ (high-res for energy reference) ===
  NewCurrentPrefix="baseline_read_"
  Transient (
    InitialTime=0 FinalTime=1.0000e-07
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0 1.0000e-07) Intervals=50) )
  }

  *=== 9 write-then-read pulses, dense sampling ===

  *--- PULSE 1 ---
  NewCurrentPrefix="p01_rise_"
  Transient (
    InitialTime=1.0000e-07 FinalTime=1.0100e-07
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0000e-07 1.0100e-07) Intervals=20) )
  }
  NewCurrentPrefix="p01_write_"
  Transient (
    InitialTime=1.0100e-07 FinalTime=2.0100e-07
    InitialStep=1e-12 MaxStep=1e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0100e-07 2.0100e-07) Intervals=100) )
  }
  NewCurrentPrefix="p01_fall_"
  Transient (
    InitialTime=2.0100e-07 FinalTime=2.0200e-07
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0100e-07 2.0200e-07) Intervals=20) )
  }
  NewCurrentPrefix="p01_read_"
  Transient (
    InitialTime=2.0200e-07 FinalTime=3.0200e-07
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0200e-07 3.0200e-07) Intervals=50) )
  }

  *--- PULSE 2 ---
  NewCurrentPrefix="p02_rise_"
  Transient (
    InitialTime=3.0200e-07 FinalTime=3.0300e-07
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0200e-07 3.0300e-07) Intervals=20) )
  }
  NewCurrentPrefix="p02_write_"
  Transient (
    InitialTime=3.0300e-07 FinalTime=4.0300e-07
    InitialStep=1e-12 MaxStep=1e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0300e-07 4.0300e-07) Intervals=100) )
  }
  NewCurrentPrefix="p02_fall_"
  Transient (
    InitialTime=4.0300e-07 FinalTime=4.0400e-07
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0300e-07 4.0400e-07) Intervals=20) )
  }
  NewCurrentPrefix="p02_read_"
  Transient (
    InitialTime=4.0400e-07 FinalTime=5.0400e-07
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0400e-07 5.0400e-07) Intervals=50) )
  }

  *--- PULSE 3 ---
  NewCurrentPrefix="p03_rise_"
  Transient (
    InitialTime=5.0400e-07 FinalTime=5.0500e-07
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0400e-07 5.0500e-07) Intervals=20) )
  }
  NewCurrentPrefix="p03_write_"
  Transient (
    InitialTime=5.0500e-07 FinalTime=6.0500e-07
    InitialStep=1e-12 MaxStep=1e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0500e-07 6.0500e-07) Intervals=100) )
  }
  NewCurrentPrefix="p03_fall_"
  Transient (
    InitialTime=6.0500e-07 FinalTime=6.0600e-07
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0500e-07 6.0600e-07) Intervals=20) )
  }
  NewCurrentPrefix="p03_read_"
  Transient (
    InitialTime=6.0600e-07 FinalTime=7.0600e-07
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0600e-07 7.0600e-07) Intervals=50) )
  }

  *--- PULSE 4 ---
  NewCurrentPrefix="p04_rise_"
  Transient (
    InitialTime=7.0600e-07 FinalTime=7.0700e-07
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0600e-07 7.0700e-07) Intervals=20) )
  }
  NewCurrentPrefix="p04_write_"
  Transient (
    InitialTime=7.0700e-07 FinalTime=8.0700e-07
    InitialStep=1e-12 MaxStep=1e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0700e-07 8.0700e-07) Intervals=100) )
  }
  NewCurrentPrefix="p04_fall_"
  Transient (
    InitialTime=8.0700e-07 FinalTime=8.0800e-07
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0700e-07 8.0800e-07) Intervals=20) )
  }
  NewCurrentPrefix="p04_read_"
  Transient (
    InitialTime=8.0800e-07 FinalTime=9.0800e-07
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0800e-07 9.0800e-07) Intervals=50) )
  }

  *--- PULSE 5 ---
  NewCurrentPrefix="p05_rise_"
  Transient (
    InitialTime=9.0800e-07 FinalTime=9.0900e-07
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0800e-07 9.0900e-07) Intervals=20) )
  }
  NewCurrentPrefix="p05_write_"
  Transient (
    InitialTime=9.0900e-07 FinalTime=1.0090e-06
    InitialStep=1e-12 MaxStep=1e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0900e-07 1.0090e-06) Intervals=100) )
  }
  NewCurrentPrefix="p05_fall_"
  Transient (
    InitialTime=1.0090e-06 FinalTime=1.0100e-06
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0090e-06 1.0100e-06) Intervals=20) )
  }
  NewCurrentPrefix="p05_read_"
  Transient (
    InitialTime=1.0100e-06 FinalTime=1.1100e-06
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0100e-06 1.1100e-06) Intervals=50) )
  }

  *--- PULSE 6 ---
  NewCurrentPrefix="p06_rise_"
  Transient (
    InitialTime=1.1100e-06 FinalTime=1.1110e-06
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1100e-06 1.1110e-06) Intervals=20) )
  }
  NewCurrentPrefix="p06_write_"
  Transient (
    InitialTime=1.1110e-06 FinalTime=1.2110e-06
    InitialStep=1e-12 MaxStep=1e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1110e-06 1.2110e-06) Intervals=100) )
  }
  NewCurrentPrefix="p06_fall_"
  Transient (
    InitialTime=1.2110e-06 FinalTime=1.2120e-06
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2110e-06 1.2120e-06) Intervals=20) )
  }
  NewCurrentPrefix="p06_read_"
  Transient (
    InitialTime=1.2120e-06 FinalTime=1.3120e-06
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2120e-06 1.3120e-06) Intervals=50) )
  }

  *--- PULSE 7 ---
  NewCurrentPrefix="p07_rise_"
  Transient (
    InitialTime=1.3120e-06 FinalTime=1.3130e-06
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3120e-06 1.3130e-06) Intervals=20) )
  }
  NewCurrentPrefix="p07_write_"
  Transient (
    InitialTime=1.3130e-06 FinalTime=1.4130e-06
    InitialStep=1e-12 MaxStep=1e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3130e-06 1.4130e-06) Intervals=100) )
  }
  NewCurrentPrefix="p07_fall_"
  Transient (
    InitialTime=1.4130e-06 FinalTime=1.4140e-06
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4130e-06 1.4140e-06) Intervals=20) )
  }
  NewCurrentPrefix="p07_read_"
  Transient (
    InitialTime=1.4140e-06 FinalTime=1.5140e-06
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4140e-06 1.5140e-06) Intervals=50) )
  }

  *--- PULSE 8 ---
  NewCurrentPrefix="p08_rise_"
  Transient (
    InitialTime=1.5140e-06 FinalTime=1.5150e-06
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5140e-06 1.5150e-06) Intervals=20) )
  }
  NewCurrentPrefix="p08_write_"
  Transient (
    InitialTime=1.5150e-06 FinalTime=1.6150e-06
    InitialStep=1e-12 MaxStep=1e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5150e-06 1.6150e-06) Intervals=100) )
  }
  NewCurrentPrefix="p08_fall_"
  Transient (
    InitialTime=1.6150e-06 FinalTime=1.6160e-06
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6150e-06 1.6160e-06) Intervals=20) )
  }
  NewCurrentPrefix="p08_read_"
  Transient (
    InitialTime=1.6160e-06 FinalTime=1.7160e-06
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6160e-06 1.7160e-06) Intervals=50) )
  }

  *--- PULSE 9 ---
  NewCurrentPrefix="p09_rise_"
  Transient (
    InitialTime=1.7160e-06 FinalTime=1.7170e-06
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7160e-06 1.7170e-06) Intervals=20) )
  }
  NewCurrentPrefix="p09_write_"
  Transient (
    InitialTime=1.7170e-06 FinalTime=1.8170e-06
    InitialStep=1e-12 MaxStep=1e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7170e-06 1.8170e-06) Intervals=100) )
  }
  NewCurrentPrefix="p09_fall_"
  Transient (
    InitialTime=1.8170e-06 FinalTime=1.8180e-06
    InitialStep=1e-12 MaxStep=5e-11 MinStep=1e-15
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.8170e-06 1.8180e-06) Intervals=20) )
  }
  NewCurrentPrefix="p09_read_"
  Transient (
    InitialTime=1.8180e-06 FinalTime=1.9180e-06
    InitialStep=1e-11 MaxStep=2e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.8180e-06 1.9180e-06) Intervals=50) )
  }

}
