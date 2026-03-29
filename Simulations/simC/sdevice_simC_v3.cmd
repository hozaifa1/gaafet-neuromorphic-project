*===================================================================
*== PHASE 1B — SIM C v3: STRONGER WRITE-THEN-READ LIF FIRE
*== Fix: Vpulse swept higher (3-5V) + pw=1us (10x v2)
*== Sweep: @Vpulse@ = 3.0, 4.0, 5.0 V  (SWB nodes)
*== Fixed: VGS_read=0.2V, VDS=0.05V, Vreset=-6.0V
*== Protocol: 10 write-then-read cycles, 5us leak gap after P5
*== Each cycle: 1ns rise + 1us write + 1ns fall + 100ns read
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

  *=== PULSE TRAIN: 10 write-then-read cycles ===
  * pw=1us, Vpulse=@Vpulse@, VGS_read=0.2V
  * 5us leak gap after pulse 5

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
    InitialTime=1.0100e-07 FinalTime=1.1010e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0100e-07 1.1010e-06) Intervals=10) )
  }
  NewCurrentPrefix="p01_fall_"
  Transient (
    InitialTime=1.1010e-06 FinalTime=1.1020e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1010e-06 1.1020e-06) Intervals=5) )
  }
  NewCurrentPrefix="p01_read_"
  Transient (
    InitialTime=1.1020e-06 FinalTime=1.2020e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1020e-06 1.2020e-06) Intervals=20) )
  }

  *--- PULSE 2 ---
  NewCurrentPrefix="p02_rise_"
  Transient (
    InitialTime=1.2020e-06 FinalTime=1.2030e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2020e-06 1.2030e-06) Intervals=5) )
  }
  NewCurrentPrefix="p02_write_"
  Transient (
    InitialTime=1.2030e-06 FinalTime=2.2030e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2030e-06 2.2030e-06) Intervals=10) )
  }
  NewCurrentPrefix="p02_fall_"
  Transient (
    InitialTime=2.2030e-06 FinalTime=2.2040e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.2030e-06 2.2040e-06) Intervals=5) )
  }
  NewCurrentPrefix="p02_read_"
  Transient (
    InitialTime=2.2040e-06 FinalTime=2.3040e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.2040e-06 2.3040e-06) Intervals=20) )
  }

  *--- PULSE 3 ---
  NewCurrentPrefix="p03_rise_"
  Transient (
    InitialTime=2.3040e-06 FinalTime=2.3050e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3040e-06 2.3050e-06) Intervals=5) )
  }
  NewCurrentPrefix="p03_write_"
  Transient (
    InitialTime=2.3050e-06 FinalTime=3.3050e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3050e-06 3.3050e-06) Intervals=10) )
  }
  NewCurrentPrefix="p03_fall_"
  Transient (
    InitialTime=3.3050e-06 FinalTime=3.3060e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.3050e-06 3.3060e-06) Intervals=5) )
  }
  NewCurrentPrefix="p03_read_"
  Transient (
    InitialTime=3.3060e-06 FinalTime=3.4060e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.3060e-06 3.4060e-06) Intervals=20) )
  }

  *--- PULSE 4 ---
  NewCurrentPrefix="p04_rise_"
  Transient (
    InitialTime=3.4060e-06 FinalTime=3.4070e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.4060e-06 3.4070e-06) Intervals=5) )
  }
  NewCurrentPrefix="p04_write_"
  Transient (
    InitialTime=3.4070e-06 FinalTime=4.4070e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.4070e-06 4.4070e-06) Intervals=10) )
  }
  NewCurrentPrefix="p04_fall_"
  Transient (
    InitialTime=4.4070e-06 FinalTime=4.4080e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.4070e-06 4.4080e-06) Intervals=5) )
  }
  NewCurrentPrefix="p04_read_"
  Transient (
    InitialTime=4.4080e-06 FinalTime=4.5080e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.4080e-06 4.5080e-06) Intervals=20) )
  }

  *--- PULSE 5 ---
  NewCurrentPrefix="p05_rise_"
  Transient (
    InitialTime=4.5080e-06 FinalTime=4.5090e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.5080e-06 4.5090e-06) Intervals=5) )
  }
  NewCurrentPrefix="p05_write_"
  Transient (
    InitialTime=4.5090e-06 FinalTime=5.5090e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.5090e-06 5.5090e-06) Intervals=10) )
  }
  NewCurrentPrefix="p05_fall_"
  Transient (
    InitialTime=5.5090e-06 FinalTime=5.5100e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.5090e-06 5.5100e-06) Intervals=5) )
  }
  NewCurrentPrefix="p05_read_"
  Transient (
    InitialTime=5.5100e-06 FinalTime=5.6100e-06
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.5100e-06 5.6100e-06) Intervals=20) )
  }

  *=== LEAK GAP: 5us at VGS_read=0.2V ===
  NewCurrentPrefix="leak_gap_"
  Transient (
    InitialTime=5.6100e-06 FinalTime=1.0610e-05
    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.6100e-06 1.0610e-05) Intervals=50) )
  }

  *--- PULSE 6 ---
  NewCurrentPrefix="p06_rise_"
  Transient (
    InitialTime=1.0610e-05 FinalTime=1.0611e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0610e-05 1.0611e-05) Intervals=5) )
  }
  NewCurrentPrefix="p06_write_"
  Transient (
    InitialTime=1.0611e-05 FinalTime=1.1611e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0611e-05 1.1611e-05) Intervals=10) )
  }
  NewCurrentPrefix="p06_fall_"
  Transient (
    InitialTime=1.1611e-05 FinalTime=1.1612e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1611e-05 1.1612e-05) Intervals=5) )
  }
  NewCurrentPrefix="p06_read_"
  Transient (
    InitialTime=1.1612e-05 FinalTime=1.1712e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1612e-05 1.1712e-05) Intervals=20) )
  }

  *--- PULSE 7 ---
  NewCurrentPrefix="p07_rise_"
  Transient (
    InitialTime=1.1712e-05 FinalTime=1.1713e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1712e-05 1.1713e-05) Intervals=5) )
  }
  NewCurrentPrefix="p07_write_"
  Transient (
    InitialTime=1.1713e-05 FinalTime=1.2713e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1713e-05 1.2713e-05) Intervals=10) )
  }
  NewCurrentPrefix="p07_fall_"
  Transient (
    InitialTime=1.2713e-05 FinalTime=1.2714e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2713e-05 1.2714e-05) Intervals=5) )
  }
  NewCurrentPrefix="p07_read_"
  Transient (
    InitialTime=1.2714e-05 FinalTime=1.2814e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2714e-05 1.2814e-05) Intervals=20) )
  }

  *--- PULSE 8 ---
  NewCurrentPrefix="p08_rise_"
  Transient (
    InitialTime=1.2814e-05 FinalTime=1.2815e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2814e-05 1.2815e-05) Intervals=5) )
  }
  NewCurrentPrefix="p08_write_"
  Transient (
    InitialTime=1.2815e-05 FinalTime=1.3815e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2815e-05 1.3815e-05) Intervals=10) )
  }
  NewCurrentPrefix="p08_fall_"
  Transient (
    InitialTime=1.3815e-05 FinalTime=1.3816e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3815e-05 1.3816e-05) Intervals=5) )
  }
  NewCurrentPrefix="p08_read_"
  Transient (
    InitialTime=1.3816e-05 FinalTime=1.3916e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3816e-05 1.3916e-05) Intervals=20) )
  }

  *--- PULSE 9 ---
  NewCurrentPrefix="p09_rise_"
  Transient (
    InitialTime=1.3916e-05 FinalTime=1.3917e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3916e-05 1.3917e-05) Intervals=5) )
  }
  NewCurrentPrefix="p09_write_"
  Transient (
    InitialTime=1.3917e-05 FinalTime=1.4917e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3917e-05 1.4917e-05) Intervals=10) )
  }
  NewCurrentPrefix="p09_fall_"
  Transient (
    InitialTime=1.4917e-05 FinalTime=1.4918e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4917e-05 1.4918e-05) Intervals=5) )
  }
  NewCurrentPrefix="p09_read_"
  Transient (
    InitialTime=1.4918e-05 FinalTime=1.5018e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4918e-05 1.5018e-05) Intervals=20) )
  }

  *--- PULSE 10 ---
  NewCurrentPrefix="p10_rise_"
  Transient (
    InitialTime=1.5018e-05 FinalTime=1.5019e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5018e-05 1.5019e-05) Intervals=5) )
  }
  NewCurrentPrefix="p10_write_"
  Transient (
    InitialTime=1.5019e-05 FinalTime=1.6019e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5019e-05 1.6019e-05) Intervals=10) )
  }
  NewCurrentPrefix="p10_fall_"
  Transient (
    InitialTime=1.6019e-05 FinalTime=1.6020e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6019e-05 1.6020e-05) Intervals=5) )
  }
  NewCurrentPrefix="p10_read_"
  Transient (
    InitialTime=1.6020e-05 FinalTime=1.6120e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6020e-05 1.6120e-05) Intervals=20) )
  }

  *=== RESET PULSE (Vreset=-6.0V) ===
  NewCurrentPrefix="reset_rise_"
  Transient (
    InitialTime=1.6120e-05 FinalTime=1.6121e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6120e-05 1.6121e-05) Intervals=5) )
  }
  NewCurrentPrefix="reset_hold_"
  Transient (
    InitialTime=1.6121e-05 FinalTime=1.7121e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6121e-05 1.7121e-05) Intervals=20) )
  }
  NewCurrentPrefix="reset_fall_"
  Transient (
    InitialTime=1.7121e-05 FinalTime=1.7122e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.2 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7121e-05 1.7122e-05) Intervals=5) )
  }

  *=== POST-RESET READ ===
  NewCurrentPrefix="postreset_read_"
  Transient (
    InitialTime=1.7122e-05 FinalTime=1.7222e-05
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7122e-05 1.7222e-05) Intervals=20) )
  }

}
