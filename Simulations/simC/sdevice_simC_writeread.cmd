*===================================================================
*== PHASE 1B — SIM C v2: WRITE-THEN-READ LIF FIRE DEMONSTRATION
*== Purpose: Demonstrate fire event via constant read-bias monitoring.
*==          After each write pulse, ID is monitored at VGS_read=0.20V.
*==          Fire = when cumulative Vth shift drops Vth below VGS_read,
*==          causing ID at VGS_read to jump (subthreshold → inversion).
*== Protocol: Write pulse (VGS_read→2V→VGS_read) + Read (hold VGS_read)
*== SWB Sweep: @Vreset@ = -2.0, -3.0, -4.0 (3 runs)
*== Fixed: Vpulse=2.0V, VDS=0.05V, VGS_read=0.20V, pw=100ns, 10 pulses
*==        1us leak gap after pulse 5 (for future tau_P characterization)
*== Output: ID vs time at constant VGS_read showing integration steps,
*==         fire threshold crossing, and reset recovery
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

  *=== STEP 1: SET DRAIN READ BIAS (VDS=0.05V) ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: SET GATE READ BIAS (VGS_read=0.20V) ===
  NewCurrentPrefix="gate_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== BASELINE READ: Record ID at VGS_read before any write pulses ===
  NewCurrentPrefix="baseline_read_"
  Transient (
    InitialTime=0 FinalTime=1e-7
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0 1e-7) Intervals=20) )
  }

  *=== PULSE TRAIN: 10 write-then-read cycles ===
  * Each cycle: 1ns rise + 100ns write + 1ns fall + 100ns read = 202ns
  * Vpulse = 2.0V (from SimA), VGS_read = 0.20V
  * 1us leak gap inserted after pulse 5

  *--- PULSE 1 ---
  NewCurrentPrefix="p01_rise_"
  Transient (
    InitialTime=1.00e-7 FinalTime=1.01e-7
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.00e-7 1.01e-7) Intervals=5) )
  }
  NewCurrentPrefix="p01_write_"
  Transient (
    InitialTime=1.01e-7 FinalTime=2.01e-7
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.01e-7 2.01e-7) Intervals=10) )
  }
  NewCurrentPrefix="p01_fall_"
  Transient (
    InitialTime=2.01e-7 FinalTime=2.02e-7
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.01e-7 2.02e-7) Intervals=5) )
  }
  NewCurrentPrefix="p01_read_"
  Transient (
    InitialTime=2.02e-7 FinalTime=3.02e-7
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.02e-7 3.02e-7) Intervals=20) )
  }

  *--- PULSE 2 ---
  NewCurrentPrefix="p02_rise_"
  Transient (
    InitialTime=3.02e-7 FinalTime=3.03e-7
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.02e-7 3.03e-7) Intervals=5) )
  }
  NewCurrentPrefix="p02_write_"
  Transient (
    InitialTime=3.03e-7 FinalTime=4.03e-7
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.03e-7 4.03e-7) Intervals=10) )
  }
  NewCurrentPrefix="p02_fall_"
  Transient (
    InitialTime=4.03e-7 FinalTime=4.04e-7
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.03e-7 4.04e-7) Intervals=5) )
  }
  NewCurrentPrefix="p02_read_"
  Transient (
    InitialTime=4.04e-7 FinalTime=5.04e-7
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.04e-7 5.04e-7) Intervals=20) )
  }

  *--- PULSE 3 ---
  NewCurrentPrefix="p03_rise_"
  Transient (
    InitialTime=5.04e-7 FinalTime=5.05e-7
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.04e-7 5.05e-7) Intervals=5) )
  }
  NewCurrentPrefix="p03_write_"
  Transient (
    InitialTime=5.05e-7 FinalTime=6.05e-7
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.05e-7 6.05e-7) Intervals=10) )
  }
  NewCurrentPrefix="p03_fall_"
  Transient (
    InitialTime=6.05e-7 FinalTime=6.06e-7
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.05e-7 6.06e-7) Intervals=5) )
  }
  NewCurrentPrefix="p03_read_"
  Transient (
    InitialTime=6.06e-7 FinalTime=7.06e-7
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.06e-7 7.06e-7) Intervals=20) )
  }

  *--- PULSE 4 ---
  NewCurrentPrefix="p04_rise_"
  Transient (
    InitialTime=7.06e-7 FinalTime=7.07e-7
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.06e-7 7.07e-7) Intervals=5) )
  }
  NewCurrentPrefix="p04_write_"
  Transient (
    InitialTime=7.07e-7 FinalTime=8.07e-7
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.07e-7 8.07e-7) Intervals=10) )
  }
  NewCurrentPrefix="p04_fall_"
  Transient (
    InitialTime=8.07e-7 FinalTime=8.08e-7
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.07e-7 8.08e-7) Intervals=5) )
  }
  NewCurrentPrefix="p04_read_"
  Transient (
    InitialTime=8.08e-7 FinalTime=9.08e-7
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.08e-7 9.08e-7) Intervals=20) )
  }

  *--- PULSE 5 ---
  NewCurrentPrefix="p05_rise_"
  Transient (
    InitialTime=9.08e-7 FinalTime=9.09e-7
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.08e-7 9.09e-7) Intervals=5) )
  }
  NewCurrentPrefix="p05_write_"
  Transient (
    InitialTime=9.09e-7 FinalTime=1.009e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.09e-7 1.009e-6) Intervals=10) )
  }
  NewCurrentPrefix="p05_fall_"
  Transient (
    InitialTime=1.009e-6 FinalTime=1.010e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.009e-6 1.010e-6) Intervals=5) )
  }
  NewCurrentPrefix="p05_read_"
  Transient (
    InitialTime=1.010e-6 FinalTime=1.110e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.010e-6 1.110e-6) Intervals=20) )
  }

  *=== LEAK GAP: 1us hold at VGS_read (for tau_P characterization) ===
  NewCurrentPrefix="leak_gap_"
  Transient (
    InitialTime=1.110e-6 FinalTime=2.110e-6
    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.110e-6 2.110e-6) Intervals=50) )
  }

  *--- PULSE 6 ---
  NewCurrentPrefix="p06_rise_"
  Transient (
    InitialTime=2.110e-6 FinalTime=2.111e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.110e-6 2.111e-6) Intervals=5) )
  }
  NewCurrentPrefix="p06_write_"
  Transient (
    InitialTime=2.111e-6 FinalTime=2.211e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.111e-6 2.211e-6) Intervals=10) )
  }
  NewCurrentPrefix="p06_fall_"
  Transient (
    InitialTime=2.211e-6 FinalTime=2.212e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.211e-6 2.212e-6) Intervals=5) )
  }
  NewCurrentPrefix="p06_read_"
  Transient (
    InitialTime=2.212e-6 FinalTime=2.312e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.212e-6 2.312e-6) Intervals=20) )
  }

  *--- PULSE 7 ---
  NewCurrentPrefix="p07_rise_"
  Transient (
    InitialTime=2.312e-6 FinalTime=2.313e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.312e-6 2.313e-6) Intervals=5) )
  }
  NewCurrentPrefix="p07_write_"
  Transient (
    InitialTime=2.313e-6 FinalTime=2.413e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.313e-6 2.413e-6) Intervals=10) )
  }
  NewCurrentPrefix="p07_fall_"
  Transient (
    InitialTime=2.413e-6 FinalTime=2.414e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.413e-6 2.414e-6) Intervals=5) )
  }
  NewCurrentPrefix="p07_read_"
  Transient (
    InitialTime=2.414e-6 FinalTime=2.514e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.414e-6 2.514e-6) Intervals=20) )
  }

  *--- PULSE 8 ---
  NewCurrentPrefix="p08_rise_"
  Transient (
    InitialTime=2.514e-6 FinalTime=2.515e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.514e-6 2.515e-6) Intervals=5) )
  }
  NewCurrentPrefix="p08_write_"
  Transient (
    InitialTime=2.515e-6 FinalTime=2.615e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.515e-6 2.615e-6) Intervals=10) )
  }
  NewCurrentPrefix="p08_fall_"
  Transient (
    InitialTime=2.615e-6 FinalTime=2.616e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.615e-6 2.616e-6) Intervals=5) )
  }
  NewCurrentPrefix="p08_read_"
  Transient (
    InitialTime=2.616e-6 FinalTime=2.716e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.616e-6 2.716e-6) Intervals=20) )
  }

  *--- PULSE 9 ---
  NewCurrentPrefix="p09_rise_"
  Transient (
    InitialTime=2.716e-6 FinalTime=2.717e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.716e-6 2.717e-6) Intervals=5) )
  }
  NewCurrentPrefix="p09_write_"
  Transient (
    InitialTime=2.717e-6 FinalTime=2.817e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.717e-6 2.817e-6) Intervals=10) )
  }
  NewCurrentPrefix="p09_fall_"
  Transient (
    InitialTime=2.817e-6 FinalTime=2.818e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.817e-6 2.818e-6) Intervals=5) )
  }
  NewCurrentPrefix="p09_read_"
  Transient (
    InitialTime=2.818e-6 FinalTime=2.918e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.818e-6 2.918e-6) Intervals=20) )
  }

  *--- PULSE 10 ---
  NewCurrentPrefix="p10_rise_"
  Transient (
    InitialTime=2.918e-6 FinalTime=2.919e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.918e-6 2.919e-6) Intervals=5) )
  }
  NewCurrentPrefix="p10_write_"
  Transient (
    InitialTime=2.919e-6 FinalTime=3.019e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.919e-6 3.019e-6) Intervals=10) )
  }
  NewCurrentPrefix="p10_fall_"
  Transient (
    InitialTime=3.019e-6 FinalTime=3.020e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.019e-6 3.020e-6) Intervals=5) )
  }
  NewCurrentPrefix="p10_read_"
  Transient (
    InitialTime=3.020e-6 FinalTime=3.120e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.020e-6 3.120e-6) Intervals=20) )
  }

  *=== RESET PULSE ===
  * @Vreset@ swept via SWB: -2.0, -3.0, -4.0
  NewCurrentPrefix="reset_rise_"
  Transient (
    InitialTime=3.120e-6 FinalTime=3.121e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vreset@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.120e-6 3.121e-6) Intervals=5) )
  }
  NewCurrentPrefix="reset_hold_"
  Transient (
    InitialTime=3.121e-6 FinalTime=3.221e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.121e-6 3.221e-6) Intervals=20) )
  }
  NewCurrentPrefix="reset_fall_"
  Transient (
    InitialTime=3.221e-6 FinalTime=3.222e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.20 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.221e-6 3.222e-6) Intervals=5) )
  }

  *=== POST-RESET READ: Verify ID returned to baseline at VGS_read ===
  NewCurrentPrefix="postreset_read_"
  Transient (
    InitialTime=3.222e-6 FinalTime=3.322e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.222e-6 3.322e-6) Intervals=20) )
  }

}
