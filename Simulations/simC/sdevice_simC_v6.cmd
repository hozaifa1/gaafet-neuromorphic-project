*===================================================================
*== PHASE 1B — SIM C v6: HIGHER VPULSE TO PUSH PAST FIRE THRESHOLD
*== v5 showed 5V peaks at 1.87x with pw/tau_E=0.1 — just below 2x.
*== v6: Vpulse=5/6/7V to access more switchable polarization.
*== Sweep: @Vpulse@ = 5.0, 6.0, 7.0 V  (SWB nodes)
*== Fixed: VGS_read=0.2V, VDS=0.05V, Vreset=-5.0V, pw=100ns
*== Protocol: 30 write-then-read cycles, 5us leak gap after P15
*== Each cycle: 1ns rise + 100ns write + 1ns fall + 100ns read
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

  *=== BASELINE READ ===
  NewCurrentPrefix="baseline_read_"
  Transient (
    InitialTime=0 FinalTime=1.0000e-07
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0 1.0000e-07) Intervals=20) )
  }

  *=== PULSE TRAIN: 30 write-then-read cycles ===
  * pw=100ns, Vpulse=@Vpulse@, VGS_read=0.2V
  * 5us leak gap after pulse 15

  *--- PULSE 1 ---
  NewCurrentPrefix="p01_rise_"
  Transient (
    InitialTime=1.0000e-07 FinalTime=1.0100e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0000e-07 1.0100e-07) Intervals=5) )
  }
  NewCurrentPrefix="p01_write_"
  Transient (
    InitialTime=1.0100e-07 FinalTime=2.0100e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0100e-07 2.0100e-07) Intervals=10) )
  }
  NewCurrentPrefix="p01_fall_"
  Transient (
    InitialTime=2.0100e-07 FinalTime=2.0200e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0100e-07 2.0200e-07) Intervals=5) )
  }
  NewCurrentPrefix="p01_read_"
  Transient (
    InitialTime=2.0200e-07 FinalTime=3.0200e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0200e-07 3.0200e-07) Intervals=20) )
  }

  *--- PULSE 2 ---
  NewCurrentPrefix="p02_rise_"
  Transient (
    InitialTime=3.0200e-07 FinalTime=3.0300e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0200e-07 3.0300e-07) Intervals=5) )
  }
  NewCurrentPrefix="p02_write_"
  Transient (
    InitialTime=3.0300e-07 FinalTime=4.0300e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0300e-07 4.0300e-07) Intervals=10) )
  }
  NewCurrentPrefix="p02_fall_"
  Transient (
    InitialTime=4.0300e-07 FinalTime=4.0400e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0300e-07 4.0400e-07) Intervals=5) )
  }
  NewCurrentPrefix="p02_read_"
  Transient (
    InitialTime=4.0400e-07 FinalTime=5.0400e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0400e-07 5.0400e-07) Intervals=20) )
  }

  *--- PULSE 3 ---
  NewCurrentPrefix="p03_rise_"
  Transient (
    InitialTime=5.0400e-07 FinalTime=5.0500e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0400e-07 5.0500e-07) Intervals=5) )
  }
  NewCurrentPrefix="p03_write_"
  Transient (
    InitialTime=5.0500e-07 FinalTime=6.0500e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0500e-07 6.0500e-07) Intervals=10) )
  }
  NewCurrentPrefix="p03_fall_"
  Transient (
    InitialTime=6.0500e-07 FinalTime=6.0600e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0500e-07 6.0600e-07) Intervals=5) )
  }
  NewCurrentPrefix="p03_read_"
  Transient (
    InitialTime=6.0600e-07 FinalTime=7.0600e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0600e-07 7.0600e-07) Intervals=20) )
  }

  *--- PULSE 4 ---
  NewCurrentPrefix="p04_rise_"
  Transient (
    InitialTime=7.0600e-07 FinalTime=7.0700e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0600e-07 7.0700e-07) Intervals=5) )
  }
  NewCurrentPrefix="p04_write_"
  Transient (
    InitialTime=7.0700e-07 FinalTime=8.0700e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0700e-07 8.0700e-07) Intervals=10) )
  }
  NewCurrentPrefix="p04_fall_"
  Transient (
    InitialTime=8.0700e-07 FinalTime=8.0800e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0700e-07 8.0800e-07) Intervals=5) )
  }
  NewCurrentPrefix="p04_read_"
  Transient (
    InitialTime=8.0800e-07 FinalTime=9.0800e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0800e-07 9.0800e-07) Intervals=20) )
  }

  *--- PULSE 5 ---
  NewCurrentPrefix="p05_rise_"
  Transient (
    InitialTime=9.0800e-07 FinalTime=9.0900e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0800e-07 9.0900e-07) Intervals=5) )
  }
  NewCurrentPrefix="p05_write_"
  Transient (
    InitialTime=9.0900e-07 FinalTime=1.0090e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0900e-07 1.0090e-06) Intervals=10) )
  }
  NewCurrentPrefix="p05_fall_"
  Transient (
    InitialTime=1.0090e-06 FinalTime=1.0100e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0090e-06 1.0100e-06) Intervals=5) )
  }
  NewCurrentPrefix="p05_read_"
  Transient (
    InitialTime=1.0100e-06 FinalTime=1.1100e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0100e-06 1.1100e-06) Intervals=20) )
  }

  *--- PULSE 6 ---
  NewCurrentPrefix="p06_rise_"
  Transient (
    InitialTime=1.1100e-06 FinalTime=1.1110e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1100e-06 1.1110e-06) Intervals=5) )
  }
  NewCurrentPrefix="p06_write_"
  Transient (
    InitialTime=1.1110e-06 FinalTime=1.2110e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1110e-06 1.2110e-06) Intervals=10) )
  }
  NewCurrentPrefix="p06_fall_"
  Transient (
    InitialTime=1.2110e-06 FinalTime=1.2120e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2110e-06 1.2120e-06) Intervals=5) )
  }
  NewCurrentPrefix="p06_read_"
  Transient (
    InitialTime=1.2120e-06 FinalTime=1.3120e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2120e-06 1.3120e-06) Intervals=20) )
  }

  *--- PULSE 7 ---
  NewCurrentPrefix="p07_rise_"
  Transient (
    InitialTime=1.3120e-06 FinalTime=1.3130e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3120e-06 1.3130e-06) Intervals=5) )
  }
  NewCurrentPrefix="p07_write_"
  Transient (
    InitialTime=1.3130e-06 FinalTime=1.4130e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3130e-06 1.4130e-06) Intervals=10) )
  }
  NewCurrentPrefix="p07_fall_"
  Transient (
    InitialTime=1.4130e-06 FinalTime=1.4140e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4130e-06 1.4140e-06) Intervals=5) )
  }
  NewCurrentPrefix="p07_read_"
  Transient (
    InitialTime=1.4140e-06 FinalTime=1.5140e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4140e-06 1.5140e-06) Intervals=20) )
  }

  *--- PULSE 8 ---
  NewCurrentPrefix="p08_rise_"
  Transient (
    InitialTime=1.5140e-06 FinalTime=1.5150e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5140e-06 1.5150e-06) Intervals=5) )
  }
  NewCurrentPrefix="p08_write_"
  Transient (
    InitialTime=1.5150e-06 FinalTime=1.6150e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5150e-06 1.6150e-06) Intervals=10) )
  }
  NewCurrentPrefix="p08_fall_"
  Transient (
    InitialTime=1.6150e-06 FinalTime=1.6160e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6150e-06 1.6160e-06) Intervals=5) )
  }
  NewCurrentPrefix="p08_read_"
  Transient (
    InitialTime=1.6160e-06 FinalTime=1.7160e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6160e-06 1.7160e-06) Intervals=20) )
  }

  *--- PULSE 9 ---
  NewCurrentPrefix="p09_rise_"
  Transient (
    InitialTime=1.7160e-06 FinalTime=1.7170e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7160e-06 1.7170e-06) Intervals=5) )
  }
  NewCurrentPrefix="p09_write_"
  Transient (
    InitialTime=1.7170e-06 FinalTime=1.8170e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7170e-06 1.8170e-06) Intervals=10) )
  }
  NewCurrentPrefix="p09_fall_"
  Transient (
    InitialTime=1.8170e-06 FinalTime=1.8180e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.8170e-06 1.8180e-06) Intervals=5) )
  }
  NewCurrentPrefix="p09_read_"
  Transient (
    InitialTime=1.8180e-06 FinalTime=1.9180e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.8180e-06 1.9180e-06) Intervals=20) )
  }

  *--- PULSE 10 ---
  NewCurrentPrefix="p10_rise_"
  Transient (
    InitialTime=1.9180e-06 FinalTime=1.9190e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.9180e-06 1.9190e-06) Intervals=5) )
  }
  NewCurrentPrefix="p10_write_"
  Transient (
    InitialTime=1.9190e-06 FinalTime=2.0190e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.9190e-06 2.0190e-06) Intervals=10) )
  }
  NewCurrentPrefix="p10_fall_"
  Transient (
    InitialTime=2.0190e-06 FinalTime=2.0200e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0190e-06 2.0200e-06) Intervals=5) )
  }
  NewCurrentPrefix="p10_read_"
  Transient (
    InitialTime=2.0200e-06 FinalTime=2.1200e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0200e-06 2.1200e-06) Intervals=20) )
  }

  *--- PULSE 11 ---
  NewCurrentPrefix="p11_rise_"
  Transient (
    InitialTime=2.1200e-06 FinalTime=2.1210e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.1200e-06 2.1210e-06) Intervals=5) )
  }
  NewCurrentPrefix="p11_write_"
  Transient (
    InitialTime=2.1210e-06 FinalTime=2.2210e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.1210e-06 2.2210e-06) Intervals=10) )
  }
  NewCurrentPrefix="p11_fall_"
  Transient (
    InitialTime=2.2210e-06 FinalTime=2.2220e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.2210e-06 2.2220e-06) Intervals=5) )
  }
  NewCurrentPrefix="p11_read_"
  Transient (
    InitialTime=2.2220e-06 FinalTime=2.3220e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.2220e-06 2.3220e-06) Intervals=20) )
  }

  *--- PULSE 12 ---
  NewCurrentPrefix="p12_rise_"
  Transient (
    InitialTime=2.3220e-06 FinalTime=2.3230e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3220e-06 2.3230e-06) Intervals=5) )
  }
  NewCurrentPrefix="p12_write_"
  Transient (
    InitialTime=2.3230e-06 FinalTime=2.4230e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3230e-06 2.4230e-06) Intervals=10) )
  }
  NewCurrentPrefix="p12_fall_"
  Transient (
    InitialTime=2.4230e-06 FinalTime=2.4240e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4230e-06 2.4240e-06) Intervals=5) )
  }
  NewCurrentPrefix="p12_read_"
  Transient (
    InitialTime=2.4240e-06 FinalTime=2.5240e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4240e-06 2.5240e-06) Intervals=20) )
  }

  *--- PULSE 13 ---
  NewCurrentPrefix="p13_rise_"
  Transient (
    InitialTime=2.5240e-06 FinalTime=2.5250e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.5240e-06 2.5250e-06) Intervals=5) )
  }
  NewCurrentPrefix="p13_write_"
  Transient (
    InitialTime=2.5250e-06 FinalTime=2.6250e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.5250e-06 2.6250e-06) Intervals=10) )
  }
  NewCurrentPrefix="p13_fall_"
  Transient (
    InitialTime=2.6250e-06 FinalTime=2.6260e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6250e-06 2.6260e-06) Intervals=5) )
  }
  NewCurrentPrefix="p13_read_"
  Transient (
    InitialTime=2.6260e-06 FinalTime=2.7260e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.6260e-06 2.7260e-06) Intervals=20) )
  }

  *--- PULSE 14 ---
  NewCurrentPrefix="p14_rise_"
  Transient (
    InitialTime=2.7260e-06 FinalTime=2.7270e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.7260e-06 2.7270e-06) Intervals=5) )
  }
  NewCurrentPrefix="p14_write_"
  Transient (
    InitialTime=2.7270e-06 FinalTime=2.8270e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.7270e-06 2.8270e-06) Intervals=10) )
  }
  NewCurrentPrefix="p14_fall_"
  Transient (
    InitialTime=2.8270e-06 FinalTime=2.8280e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.8270e-06 2.8280e-06) Intervals=5) )
  }
  NewCurrentPrefix="p14_read_"
  Transient (
    InitialTime=2.8280e-06 FinalTime=2.9280e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.8280e-06 2.9280e-06) Intervals=20) )
  }

  *--- PULSE 15 ---
  NewCurrentPrefix="p15_rise_"
  Transient (
    InitialTime=2.9280e-06 FinalTime=2.9290e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.9280e-06 2.9290e-06) Intervals=5) )
  }
  NewCurrentPrefix="p15_write_"
  Transient (
    InitialTime=2.9290e-06 FinalTime=3.0290e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.9290e-06 3.0290e-06) Intervals=10) )
  }
  NewCurrentPrefix="p15_fall_"
  Transient (
    InitialTime=3.0290e-06 FinalTime=3.0300e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0290e-06 3.0300e-06) Intervals=5) )
  }
  NewCurrentPrefix="p15_read_"
  Transient (
    InitialTime=3.0300e-06 FinalTime=3.1300e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0300e-06 3.1300e-06) Intervals=20) )
  }

  *=== LEAK GAP: 5us at VGS_read=0.2V ===
  NewCurrentPrefix="leak_gap_"
  Transient (
    InitialTime=3.1300e-06 FinalTime=8.1300e-06
    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.1300e-06 8.1300e-06) Intervals=50) )
  }

  *--- PULSE 16 ---
  NewCurrentPrefix="p16_rise_"
  Transient (
    InitialTime=8.1300e-06 FinalTime=8.1310e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1300e-06 8.1310e-06) Intervals=5) )
  }
  NewCurrentPrefix="p16_write_"
  Transient (
    InitialTime=8.1310e-06 FinalTime=8.2310e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.1310e-06 8.2310e-06) Intervals=10) )
  }
  NewCurrentPrefix="p16_fall_"
  Transient (
    InitialTime=8.2310e-06 FinalTime=8.2320e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2310e-06 8.2320e-06) Intervals=5) )
  }
  NewCurrentPrefix="p16_read_"
  Transient (
    InitialTime=8.2320e-06 FinalTime=8.3320e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.2320e-06 8.3320e-06) Intervals=20) )
  }

  *--- PULSE 17 ---
  NewCurrentPrefix="p17_rise_"
  Transient (
    InitialTime=8.3320e-06 FinalTime=8.3330e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3320e-06 8.3330e-06) Intervals=5) )
  }
  NewCurrentPrefix="p17_write_"
  Transient (
    InitialTime=8.3330e-06 FinalTime=8.4330e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.3330e-06 8.4330e-06) Intervals=10) )
  }
  NewCurrentPrefix="p17_fall_"
  Transient (
    InitialTime=8.4330e-06 FinalTime=8.4340e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.4330e-06 8.4340e-06) Intervals=5) )
  }
  NewCurrentPrefix="p17_read_"
  Transient (
    InitialTime=8.4340e-06 FinalTime=8.5340e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.4340e-06 8.5340e-06) Intervals=20) )
  }

  *--- PULSE 18 ---
  NewCurrentPrefix="p18_rise_"
  Transient (
    InitialTime=8.5340e-06 FinalTime=8.5350e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.5340e-06 8.5350e-06) Intervals=5) )
  }
  NewCurrentPrefix="p18_write_"
  Transient (
    InitialTime=8.5350e-06 FinalTime=8.6350e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.5350e-06 8.6350e-06) Intervals=10) )
  }
  NewCurrentPrefix="p18_fall_"
  Transient (
    InitialTime=8.6350e-06 FinalTime=8.6360e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.6350e-06 8.6360e-06) Intervals=5) )
  }
  NewCurrentPrefix="p18_read_"
  Transient (
    InitialTime=8.6360e-06 FinalTime=8.7360e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.6360e-06 8.7360e-06) Intervals=20) )
  }

  *--- PULSE 19 ---
  NewCurrentPrefix="p19_rise_"
  Transient (
    InitialTime=8.7360e-06 FinalTime=8.7370e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.7360e-06 8.7370e-06) Intervals=5) )
  }
  NewCurrentPrefix="p19_write_"
  Transient (
    InitialTime=8.7370e-06 FinalTime=8.8370e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.7370e-06 8.8370e-06) Intervals=10) )
  }
  NewCurrentPrefix="p19_fall_"
  Transient (
    InitialTime=8.8370e-06 FinalTime=8.8380e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.8370e-06 8.8380e-06) Intervals=5) )
  }
  NewCurrentPrefix="p19_read_"
  Transient (
    InitialTime=8.8380e-06 FinalTime=8.9380e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.8380e-06 8.9380e-06) Intervals=20) )
  }

  *--- PULSE 20 ---
  NewCurrentPrefix="p20_rise_"
  Transient (
    InitialTime=8.9380e-06 FinalTime=8.9390e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9380e-06 8.9390e-06) Intervals=5) )
  }
  NewCurrentPrefix="p20_write_"
  Transient (
    InitialTime=8.9390e-06 FinalTime=9.0390e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.9390e-06 9.0390e-06) Intervals=10) )
  }
  NewCurrentPrefix="p20_fall_"
  Transient (
    InitialTime=9.0390e-06 FinalTime=9.0400e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0390e-06 9.0400e-06) Intervals=5) )
  }
  NewCurrentPrefix="p20_read_"
  Transient (
    InitialTime=9.0400e-06 FinalTime=9.1400e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0400e-06 9.1400e-06) Intervals=20) )
  }

  *--- PULSE 21 ---
  NewCurrentPrefix="p21_rise_"
  Transient (
    InitialTime=9.1400e-06 FinalTime=9.1410e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1400e-06 9.1410e-06) Intervals=5) )
  }
  NewCurrentPrefix="p21_write_"
  Transient (
    InitialTime=9.1410e-06 FinalTime=9.2410e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1410e-06 9.2410e-06) Intervals=10) )
  }
  NewCurrentPrefix="p21_fall_"
  Transient (
    InitialTime=9.2410e-06 FinalTime=9.2420e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.2410e-06 9.2420e-06) Intervals=5) )
  }
  NewCurrentPrefix="p21_read_"
  Transient (
    InitialTime=9.2420e-06 FinalTime=9.3420e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.2420e-06 9.3420e-06) Intervals=20) )
  }

  *--- PULSE 22 ---
  NewCurrentPrefix="p22_rise_"
  Transient (
    InitialTime=9.3420e-06 FinalTime=9.3430e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.3420e-06 9.3430e-06) Intervals=5) )
  }
  NewCurrentPrefix="p22_write_"
  Transient (
    InitialTime=9.3430e-06 FinalTime=9.4430e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.3430e-06 9.4430e-06) Intervals=10) )
  }
  NewCurrentPrefix="p22_fall_"
  Transient (
    InitialTime=9.4430e-06 FinalTime=9.4440e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.4430e-06 9.4440e-06) Intervals=5) )
  }
  NewCurrentPrefix="p22_read_"
  Transient (
    InitialTime=9.4440e-06 FinalTime=9.5440e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.4440e-06 9.5440e-06) Intervals=20) )
  }

  *--- PULSE 23 ---
  NewCurrentPrefix="p23_rise_"
  Transient (
    InitialTime=9.5440e-06 FinalTime=9.5450e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.5440e-06 9.5450e-06) Intervals=5) )
  }
  NewCurrentPrefix="p23_write_"
  Transient (
    InitialTime=9.5450e-06 FinalTime=9.6450e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.5450e-06 9.6450e-06) Intervals=10) )
  }
  NewCurrentPrefix="p23_fall_"
  Transient (
    InitialTime=9.6450e-06 FinalTime=9.6460e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.6450e-06 9.6460e-06) Intervals=5) )
  }
  NewCurrentPrefix="p23_read_"
  Transient (
    InitialTime=9.6460e-06 FinalTime=9.7460e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.6460e-06 9.7460e-06) Intervals=20) )
  }

  *--- PULSE 24 ---
  NewCurrentPrefix="p24_rise_"
  Transient (
    InitialTime=9.7460e-06 FinalTime=9.7470e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7460e-06 9.7470e-06) Intervals=5) )
  }
  NewCurrentPrefix="p24_write_"
  Transient (
    InitialTime=9.7470e-06 FinalTime=9.8470e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.7470e-06 9.8470e-06) Intervals=10) )
  }
  NewCurrentPrefix="p24_fall_"
  Transient (
    InitialTime=9.8470e-06 FinalTime=9.8480e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8470e-06 9.8480e-06) Intervals=5) )
  }
  NewCurrentPrefix="p24_read_"
  Transient (
    InitialTime=9.8480e-06 FinalTime=9.9480e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.8480e-06 9.9480e-06) Intervals=20) )
  }

  *--- PULSE 25 ---
  NewCurrentPrefix="p25_rise_"
  Transient (
    InitialTime=9.9480e-06 FinalTime=9.9490e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.9480e-06 9.9490e-06) Intervals=5) )
  }
  NewCurrentPrefix="p25_write_"
  Transient (
    InitialTime=9.9490e-06 FinalTime=1.0049e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.9490e-06 1.0049e-05) Intervals=10) )
  }
  NewCurrentPrefix="p25_fall_"
  Transient (
    InitialTime=1.0049e-05 FinalTime=1.0050e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0049e-05 1.0050e-05) Intervals=5) )
  }
  NewCurrentPrefix="p25_read_"
  Transient (
    InitialTime=1.0050e-05 FinalTime=1.0150e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0050e-05 1.0150e-05) Intervals=20) )
  }

  *--- PULSE 26 ---
  NewCurrentPrefix="p26_rise_"
  Transient (
    InitialTime=1.0150e-05 FinalTime=1.0151e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0150e-05 1.0151e-05) Intervals=5) )
  }
  NewCurrentPrefix="p26_write_"
  Transient (
    InitialTime=1.0151e-05 FinalTime=1.0251e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0151e-05 1.0251e-05) Intervals=10) )
  }
  NewCurrentPrefix="p26_fall_"
  Transient (
    InitialTime=1.0251e-05 FinalTime=1.0252e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0251e-05 1.0252e-05) Intervals=5) )
  }
  NewCurrentPrefix="p26_read_"
  Transient (
    InitialTime=1.0252e-05 FinalTime=1.0352e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0252e-05 1.0352e-05) Intervals=20) )
  }

  *--- PULSE 27 ---
  NewCurrentPrefix="p27_rise_"
  Transient (
    InitialTime=1.0352e-05 FinalTime=1.0353e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0352e-05 1.0353e-05) Intervals=5) )
  }
  NewCurrentPrefix="p27_write_"
  Transient (
    InitialTime=1.0353e-05 FinalTime=1.0453e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0353e-05 1.0453e-05) Intervals=10) )
  }
  NewCurrentPrefix="p27_fall_"
  Transient (
    InitialTime=1.0453e-05 FinalTime=1.0454e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0453e-05 1.0454e-05) Intervals=5) )
  }
  NewCurrentPrefix="p27_read_"
  Transient (
    InitialTime=1.0454e-05 FinalTime=1.0554e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0454e-05 1.0554e-05) Intervals=20) )
  }

  *--- PULSE 28 ---
  NewCurrentPrefix="p28_rise_"
  Transient (
    InitialTime=1.0554e-05 FinalTime=1.0555e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0554e-05 1.0555e-05) Intervals=5) )
  }
  NewCurrentPrefix="p28_write_"
  Transient (
    InitialTime=1.0555e-05 FinalTime=1.0655e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0555e-05 1.0655e-05) Intervals=10) )
  }
  NewCurrentPrefix="p28_fall_"
  Transient (
    InitialTime=1.0655e-05 FinalTime=1.0656e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0655e-05 1.0656e-05) Intervals=5) )
  }
  NewCurrentPrefix="p28_read_"
  Transient (
    InitialTime=1.0656e-05 FinalTime=1.0756e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0656e-05 1.0756e-05) Intervals=20) )
  }

  *--- PULSE 29 ---
  NewCurrentPrefix="p29_rise_"
  Transient (
    InitialTime=1.0756e-05 FinalTime=1.0757e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0756e-05 1.0757e-05) Intervals=5) )
  }
  NewCurrentPrefix="p29_write_"
  Transient (
    InitialTime=1.0757e-05 FinalTime=1.0857e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0757e-05 1.0857e-05) Intervals=10) )
  }
  NewCurrentPrefix="p29_fall_"
  Transient (
    InitialTime=1.0857e-05 FinalTime=1.0858e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0857e-05 1.0858e-05) Intervals=5) )
  }
  NewCurrentPrefix="p29_read_"
  Transient (
    InitialTime=1.0858e-05 FinalTime=1.0958e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0858e-05 1.0958e-05) Intervals=20) )
  }

  *--- PULSE 30 ---
  NewCurrentPrefix="p30_rise_"
  Transient (
    InitialTime=1.0958e-05 FinalTime=1.0959e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0958e-05 1.0959e-05) Intervals=5) )
  }
  NewCurrentPrefix="p30_write_"
  Transient (
    InitialTime=1.0959e-05 FinalTime=1.1059e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0959e-05 1.1059e-05) Intervals=10) )
  }
  NewCurrentPrefix="p30_fall_"
  Transient (
    InitialTime=1.1059e-05 FinalTime=1.1060e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1059e-05 1.1060e-05) Intervals=5) )
  }
  NewCurrentPrefix="p30_read_"
  Transient (
    InitialTime=1.1060e-05 FinalTime=1.1160e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1060e-05 1.1160e-05) Intervals=20) )
  }

  *=== RESET PULSE (Vreset=-5.0V) ===
  NewCurrentPrefix="reset_rise_"
  Transient (
    InitialTime=1.1160e-05 FinalTime=1.1161e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -5.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1160e-05 1.1161e-05) Intervals=5) )
  }
  NewCurrentPrefix="reset_hold_"
  Transient (
    InitialTime=1.1161e-05 FinalTime=1.2161e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1161e-05 1.2161e-05) Intervals=20) )
  }
  NewCurrentPrefix="reset_fall_"
  Transient (
    InitialTime=1.2161e-05 FinalTime=1.2162e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2161e-05 1.2162e-05) Intervals=5) )
  }

  *=== POST-RESET READ ===
  NewCurrentPrefix="postreset_read_"
  Transient (
    InitialTime=1.2162e-05 FinalTime=1.2262e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2162e-05 1.2262e-05) Intervals=20) )
  }

}
