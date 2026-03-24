*===================================================================
*== PHASE 1A — SIM B: MULTI-PULSE INTEGRATION (TRANSIENT READOUT)
*== Purpose: Apply N identical gate pulses, read ID-VGS after each.
*==          Shows cumulative Vth shift = "integration" behavior.
*== DESIGN: 20 pulses total + intermediate reads at N=1,3,5,10,20.
*== Fixed: @Vpulse@ = 2.0V (from Sim A), VDS=0.05V, pw=100ns, tau_E=1µs
*== KEY: Transient readout (1ns) preserves partial-switching state
*== Output: read_nXX_fwd .plt -> Vth(N) integration staircase
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
   Iterations=200
   Transient=BE
   FEPolarizationIP=1.0
   Method=Bitlis
   SubMethod=ParDiSo
   Restart=100
   Tolerance=1e-5
   GeometricDistances
   Derivative
   ComputeGradQuasiFermiAtContacts= UseQuasiFermi
   RefDens_eGradQuasiFermi_ElectricField_HFS= 1.000e+12
   RefDens_hGradQuasiFermi_ElectricField_HFS= 1.000e+12
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

  *=== STEP 1: SET DRAIN READ BIAS ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== BASELINE ID-VGS (virgin FE state, gate 0->0.3->0V) ===
  NewCurrentPrefix="baseline_fwd_"
  Transient (
    InitialTime=0 FinalTime=1e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.3 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(0 1e-9) Intervals=50) )
  }
  NewCurrentPrefix="baseline_ret_"
  Transient (
    InitialTime=1e-9 FinalTime=2e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(1e-9 2e-9) Intervals=50) )
  }

  *=== PULSE 1 ===
  NewCurrentPrefix="p1_rise_"
  Transient (
    InitialTime=2e-9 FinalTime=3e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2e-9 3e-9) Intervals=20) )
  }
  NewCurrentPrefix="p1_hold_"
  Transient (
    InitialTime=3e-9 FinalTime=103e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3e-9 103e-9) Intervals=50) )
  }
  NewCurrentPrefix="p1_fall_"
  Transient (
    InitialTime=103e-9 FinalTime=104e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(103e-9 104e-9) Intervals=20) )
  }

  *=== READ N=1: ID-VGS (gate 0->0.3->0V) ===
  NewCurrentPrefix="read_n01_fwd_"
  Transient (
    InitialTime=104e-9 FinalTime=105e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.3 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(104e-9 105e-9) Intervals=50) )
  }
  NewCurrentPrefix="read_n01_ret_"
  Transient (
    InitialTime=105e-9 FinalTime=106e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(105e-9 106e-9) Intervals=50) )
  }

  *=== PULSE 2 ===
  NewCurrentPrefix="p2_rise_"
  Transient (
    InitialTime=106e-9 FinalTime=107e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(106e-9 107e-9) Intervals=20) )
  }
  NewCurrentPrefix="p2_hold_"
  Transient (
    InitialTime=107e-9 FinalTime=207e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(107e-9 207e-9) Intervals=50) )
  }
  NewCurrentPrefix="p2_fall_"
  Transient (
    InitialTime=207e-9 FinalTime=208e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(207e-9 208e-9) Intervals=20) )
  }

  *=== PULSE 3 ===
  NewCurrentPrefix="p3_rise_"
  Transient (
    InitialTime=208e-9 FinalTime=209e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(208e-9 209e-9) Intervals=20) )
  }
  NewCurrentPrefix="p3_hold_"
  Transient (
    InitialTime=209e-9 FinalTime=309e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(209e-9 309e-9) Intervals=50) )
  }
  NewCurrentPrefix="p3_fall_"
  Transient (
    InitialTime=309e-9 FinalTime=310e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(309e-9 310e-9) Intervals=20) )
  }

  *=== READ N=3: ID-VGS (gate 0->0.3->0V) ===
  NewCurrentPrefix="read_n03_fwd_"
  Transient (
    InitialTime=310e-9 FinalTime=311e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.3 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(310e-9 311e-9) Intervals=50) )
  }
  NewCurrentPrefix="read_n03_ret_"
  Transient (
    InitialTime=311e-9 FinalTime=312e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(311e-9 312e-9) Intervals=50) )
  }

  *=== PULSE 4 ===
  NewCurrentPrefix="p4_rise_"
  Transient (
    InitialTime=312e-9 FinalTime=313e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(312e-9 313e-9) Intervals=20) )
  }
  NewCurrentPrefix="p4_hold_"
  Transient (
    InitialTime=313e-9 FinalTime=413e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(313e-9 413e-9) Intervals=50) )
  }
  NewCurrentPrefix="p4_fall_"
  Transient (
    InitialTime=413e-9 FinalTime=414e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(413e-9 414e-9) Intervals=20) )
  }

  *=== PULSE 5 ===
  NewCurrentPrefix="p5_rise_"
  Transient (
    InitialTime=414e-9 FinalTime=415e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(414e-9 415e-9) Intervals=20) )
  }
  NewCurrentPrefix="p5_hold_"
  Transient (
    InitialTime=415e-9 FinalTime=515e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(415e-9 515e-9) Intervals=50) )
  }
  NewCurrentPrefix="p5_fall_"
  Transient (
    InitialTime=515e-9 FinalTime=516e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(515e-9 516e-9) Intervals=20) )
  }

  *=== READ N=5: ID-VGS (gate 0->0.3->0V) ===
  NewCurrentPrefix="read_n05_fwd_"
  Transient (
    InitialTime=516e-9 FinalTime=517e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.3 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(516e-9 517e-9) Intervals=50) )
  }
  NewCurrentPrefix="read_n05_ret_"
  Transient (
    InitialTime=517e-9 FinalTime=518e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(517e-9 518e-9) Intervals=50) )
  }

  *=== PULSE 6 ===
  NewCurrentPrefix="p6_rise_"
  Transient (
    InitialTime=518e-9 FinalTime=519e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(518e-9 519e-9) Intervals=20) )
  }
  NewCurrentPrefix="p6_hold_"
  Transient (
    InitialTime=519e-9 FinalTime=619e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(519e-9 619e-9) Intervals=50) )
  }
  NewCurrentPrefix="p6_fall_"
  Transient (
    InitialTime=619e-9 FinalTime=620e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(619e-9 620e-9) Intervals=20) )
  }

  *=== PULSE 7 ===
  NewCurrentPrefix="p7_rise_"
  Transient (
    InitialTime=620e-9 FinalTime=621e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(620e-9 621e-9) Intervals=20) )
  }
  NewCurrentPrefix="p7_hold_"
  Transient (
    InitialTime=621e-9 FinalTime=721e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(621e-9 721e-9) Intervals=50) )
  }
  NewCurrentPrefix="p7_fall_"
  Transient (
    InitialTime=721e-9 FinalTime=722e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(721e-9 722e-9) Intervals=20) )
  }

  *=== PULSE 8 ===
  NewCurrentPrefix="p8_rise_"
  Transient (
    InitialTime=722e-9 FinalTime=723e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(722e-9 723e-9) Intervals=20) )
  }
  NewCurrentPrefix="p8_hold_"
  Transient (
    InitialTime=723e-9 FinalTime=823e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(723e-9 823e-9) Intervals=50) )
  }
  NewCurrentPrefix="p8_fall_"
  Transient (
    InitialTime=823e-9 FinalTime=824e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(823e-9 824e-9) Intervals=20) )
  }

  *=== PULSE 9 ===
  NewCurrentPrefix="p9_rise_"
  Transient (
    InitialTime=824e-9 FinalTime=825e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(824e-9 825e-9) Intervals=20) )
  }
  NewCurrentPrefix="p9_hold_"
  Transient (
    InitialTime=825e-9 FinalTime=925e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(825e-9 925e-9) Intervals=50) )
  }
  NewCurrentPrefix="p9_fall_"
  Transient (
    InitialTime=925e-9 FinalTime=926e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(925e-9 926e-9) Intervals=20) )
  }

  *=== PULSE 10 ===
  NewCurrentPrefix="p10_rise_"
  Transient (
    InitialTime=926e-9 FinalTime=927e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(926e-9 927e-9) Intervals=20) )
  }
  NewCurrentPrefix="p10_hold_"
  Transient (
    InitialTime=927e-9 FinalTime=1.027e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(927e-9 1.027e-6) Intervals=50) )
  }
  NewCurrentPrefix="p10_fall_"
  Transient (
    InitialTime=1.027e-6 FinalTime=1.028e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.027e-6 1.028e-6) Intervals=20) )
  }

  *=== READ N=10: ID-VGS (gate 0->0.3->0V) ===
  NewCurrentPrefix="read_n10_fwd_"
  Transient (
    InitialTime=1.028e-6 FinalTime=1.029e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.3 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(1.028e-6 1.029e-6) Intervals=50) )
  }
  NewCurrentPrefix="read_n10_ret_"
  Transient (
    InitialTime=1.029e-6 FinalTime=1.030e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(1.029e-6 1.030e-6) Intervals=50) )
  }

  *=== PULSE 11-20 (consecutive, no intermediate reads) ===
  *=== PULSE 11 ===
  NewCurrentPrefix="p11_rise_"
  Transient (
    InitialTime=1.030e-6 FinalTime=1.031e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.030e-6 1.031e-6) Intervals=20) )
  }
  NewCurrentPrefix="p11_hold_"
  Transient (
    InitialTime=1.031e-6 FinalTime=1.131e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.031e-6 1.131e-6) Intervals=50) )
  }
  NewCurrentPrefix="p11_fall_"
  Transient (
    InitialTime=1.131e-6 FinalTime=1.132e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.131e-6 1.132e-6) Intervals=20) )
  }

  *=== PULSE 12 ===
  NewCurrentPrefix="p12_rise_"
  Transient (
    InitialTime=1.132e-6 FinalTime=1.133e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.132e-6 1.133e-6) Intervals=20) )
  }
  NewCurrentPrefix="p12_hold_"
  Transient (
    InitialTime=1.133e-6 FinalTime=1.233e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.133e-6 1.233e-6) Intervals=50) )
  }
  NewCurrentPrefix="p12_fall_"
  Transient (
    InitialTime=1.233e-6 FinalTime=1.234e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.233e-6 1.234e-6) Intervals=20) )
  }

  *=== PULSE 13 ===
  NewCurrentPrefix="p13_rise_"
  Transient (
    InitialTime=1.234e-6 FinalTime=1.235e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.234e-6 1.235e-6) Intervals=20) )
  }
  NewCurrentPrefix="p13_hold_"
  Transient (
    InitialTime=1.235e-6 FinalTime=1.335e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.235e-6 1.335e-6) Intervals=50) )
  }
  NewCurrentPrefix="p13_fall_"
  Transient (
    InitialTime=1.335e-6 FinalTime=1.336e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.335e-6 1.336e-6) Intervals=20) )
  }

  *=== PULSE 14 ===
  NewCurrentPrefix="p14_rise_"
  Transient (
    InitialTime=1.336e-6 FinalTime=1.337e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.336e-6 1.337e-6) Intervals=20) )
  }
  NewCurrentPrefix="p14_hold_"
  Transient (
    InitialTime=1.337e-6 FinalTime=1.437e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.337e-6 1.437e-6) Intervals=50) )
  }
  NewCurrentPrefix="p14_fall_"
  Transient (
    InitialTime=1.437e-6 FinalTime=1.438e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.437e-6 1.438e-6) Intervals=20) )
  }

  *=== PULSE 15 ===
  NewCurrentPrefix="p15_rise_"
  Transient (
    InitialTime=1.438e-6 FinalTime=1.439e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.438e-6 1.439e-6) Intervals=20) )
  }
  NewCurrentPrefix="p15_hold_"
  Transient (
    InitialTime=1.439e-6 FinalTime=1.539e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.439e-6 1.539e-6) Intervals=50) )
  }
  NewCurrentPrefix="p15_fall_"
  Transient (
    InitialTime=1.539e-6 FinalTime=1.540e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.539e-6 1.540e-6) Intervals=20) )
  }

  *=== PULSE 16 ===
  NewCurrentPrefix="p16_rise_"
  Transient (
    InitialTime=1.540e-6 FinalTime=1.541e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.540e-6 1.541e-6) Intervals=20) )
  }
  NewCurrentPrefix="p16_hold_"
  Transient (
    InitialTime=1.541e-6 FinalTime=1.641e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.541e-6 1.641e-6) Intervals=50) )
  }
  NewCurrentPrefix="p16_fall_"
  Transient (
    InitialTime=1.641e-6 FinalTime=1.642e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.641e-6 1.642e-6) Intervals=20) )
  }

  *=== PULSE 17 ===
  NewCurrentPrefix="p17_rise_"
  Transient (
    InitialTime=1.642e-6 FinalTime=1.643e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.642e-6 1.643e-6) Intervals=20) )
  }
  NewCurrentPrefix="p17_hold_"
  Transient (
    InitialTime=1.643e-6 FinalTime=1.743e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.643e-6 1.743e-6) Intervals=50) )
  }
  NewCurrentPrefix="p17_fall_"
  Transient (
    InitialTime=1.743e-6 FinalTime=1.744e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.743e-6 1.744e-6) Intervals=20) )
  }

  *=== PULSE 18 ===
  NewCurrentPrefix="p18_rise_"
  Transient (
    InitialTime=1.744e-6 FinalTime=1.745e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.744e-6 1.745e-6) Intervals=20) )
  }
  NewCurrentPrefix="p18_hold_"
  Transient (
    InitialTime=1.745e-6 FinalTime=1.845e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.745e-6 1.845e-6) Intervals=50) )
  }
  NewCurrentPrefix="p18_fall_"
  Transient (
    InitialTime=1.845e-6 FinalTime=1.846e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.845e-6 1.846e-6) Intervals=20) )
  }

  *=== PULSE 19 ===
  NewCurrentPrefix="p19_rise_"
  Transient (
    InitialTime=1.846e-6 FinalTime=1.847e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.846e-6 1.847e-6) Intervals=20) )
  }
  NewCurrentPrefix="p19_hold_"
  Transient (
    InitialTime=1.847e-6 FinalTime=1.947e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.847e-6 1.947e-6) Intervals=50) )
  }
  NewCurrentPrefix="p19_fall_"
  Transient (
    InitialTime=1.947e-6 FinalTime=1.948e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.947e-6 1.948e-6) Intervals=20) )
  }

  *=== PULSE 20 ===
  NewCurrentPrefix="p20_rise_"
  Transient (
    InitialTime=1.948e-6 FinalTime=1.949e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.948e-6 1.949e-6) Intervals=20) )
  }
  NewCurrentPrefix="p20_hold_"
  Transient (
    InitialTime=1.949e-6 FinalTime=2.049e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.949e-6 2.049e-6) Intervals=50) )
  }
  NewCurrentPrefix="p20_fall_"
  Transient (
    InitialTime=2.049e-6 FinalTime=2.050e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.049e-6 2.050e-6) Intervals=20) )
  }

  *=== READ N=20: ID-VGS (gate 0->0.3->0V) ===
  NewCurrentPrefix="read_n20_fwd_"
  Transient (
    InitialTime=2.050e-6 FinalTime=2.051e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.3 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(2.050e-6 2.051e-6) Intervals=50) )
  }
  NewCurrentPrefix="read_n20_ret_"
  Transient (
    InitialTime=2.051e-6 FinalTime=2.052e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(2.051e-6 2.052e-6) Intervals=50) )
  }

}
