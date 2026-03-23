*===================================================================
*== PHASE 1A — SIM B: MULTI-PULSE INTEGRATION
*== Purpose: Apply N identical gate pulses, read ID-VGS after each.
*==          Shows cumulative Vth shift = "integration" behavior.
*== SWB Sweep: @Npulses@ = 1, 3, 5, 10, 20 (5 runs)
*== Fixed: Vpulse from Sim A best result, VDS=0.05V, pw=100ns
*== NOTE: @Vpulse@ should be set to the best amplitude from Sim A.
*==        Set it as a fixed SWB parameter (not swept here).
*== Output: ID-VGS after N pulses -> Vth(N) integration curve
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
   Digits=4
   Notdamped=50
   Iterations=20
   Transient=BE
   Method=Blocked
   SubMethod=ParDiSo
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

  *=== PULSE 1 ===
  NewCurrentPrefix="p1_rise_"
  Transient (
    InitialTime=0 FinalTime=1e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0 1e-9) Intervals=20) )
  }
  NewCurrentPrefix="p1_hold_"
  Transient (
    InitialTime=1e-9 FinalTime=101e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1e-9 101e-9) Intervals=50) )
  }
  NewCurrentPrefix="p1_fall_"
  Transient (
    InitialTime=101e-9 FinalTime=102e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(101e-9 102e-9) Intervals=20) )
  }

  *=== PULSE 2 ===
  NewCurrentPrefix="p2_rise_"
  Transient (
    InitialTime=102e-9 FinalTime=103e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(102e-9 103e-9) Intervals=20) )
  }
  NewCurrentPrefix="p2_hold_"
  Transient (
    InitialTime=103e-9 FinalTime=203e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(103e-9 203e-9) Intervals=50) )
  }
  NewCurrentPrefix="p2_fall_"
  Transient (
    InitialTime=203e-9 FinalTime=204e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(203e-9 204e-9) Intervals=20) )
  }

  *=== PULSE 3 ===
  NewCurrentPrefix="p3_rise_"
  Transient (
    InitialTime=204e-9 FinalTime=205e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(204e-9 205e-9) Intervals=20) )
  }
  NewCurrentPrefix="p3_hold_"
  Transient (
    InitialTime=205e-9 FinalTime=305e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(205e-9 305e-9) Intervals=50) )
  }
  NewCurrentPrefix="p3_fall_"
  Transient (
    InitialTime=305e-9 FinalTime=306e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(305e-9 306e-9) Intervals=20) )
  }

  *=== PULSE 4 ===
  NewCurrentPrefix="p4_rise_"
  Transient (
    InitialTime=306e-9 FinalTime=307e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(306e-9 307e-9) Intervals=20) )
  }
  NewCurrentPrefix="p4_hold_"
  Transient (
    InitialTime=307e-9 FinalTime=407e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(307e-9 407e-9) Intervals=50) )
  }
  NewCurrentPrefix="p4_fall_"
  Transient (
    InitialTime=407e-9 FinalTime=408e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(407e-9 408e-9) Intervals=20) )
  }

  *=== PULSE 5 ===
  NewCurrentPrefix="p5_rise_"
  Transient (
    InitialTime=408e-9 FinalTime=409e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(408e-9 409e-9) Intervals=20) )
  }
  NewCurrentPrefix="p5_hold_"
  Transient (
    InitialTime=409e-9 FinalTime=509e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(409e-9 509e-9) Intervals=50) )
  }
  NewCurrentPrefix="p5_fall_"
  Transient (
    InitialTime=509e-9 FinalTime=510e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(509e-9 510e-9) Intervals=20) )
  }

  *=== PULSE 6-10 (only runs if @Npulses@ >= 10) ===
  * Pulses 6-10 follow the same pattern as 1-5.
  * Time continues from 510e-9.
  * Each pulse: 1ns rise + 100ns hold + 1ns fall = 102ns per pulse

  NewCurrentPrefix="p6_rise_"
  Transient (
    InitialTime=510e-9 FinalTime=511e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(510e-9 511e-9) Intervals=20) )
  }
  NewCurrentPrefix="p6_hold_"
  Transient (
    InitialTime=511e-9 FinalTime=611e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(511e-9 611e-9) Intervals=50) )
  }
  NewCurrentPrefix="p6_fall_"
  Transient (
    InitialTime=611e-9 FinalTime=612e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(611e-9 612e-9) Intervals=20) )
  }

  NewCurrentPrefix="p7_rise_"
  Transient (
    InitialTime=612e-9 FinalTime=613e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(612e-9 613e-9) Intervals=20) )
  }
  NewCurrentPrefix="p7_hold_"
  Transient (
    InitialTime=613e-9 FinalTime=713e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(613e-9 713e-9) Intervals=50) )
  }
  NewCurrentPrefix="p7_fall_"
  Transient (
    InitialTime=713e-9 FinalTime=714e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(713e-9 714e-9) Intervals=20) )
  }

  NewCurrentPrefix="p8_rise_"
  Transient (
    InitialTime=714e-9 FinalTime=715e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(714e-9 715e-9) Intervals=20) )
  }
  NewCurrentPrefix="p8_hold_"
  Transient (
    InitialTime=715e-9 FinalTime=815e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(715e-9 815e-9) Intervals=50) )
  }
  NewCurrentPrefix="p8_fall_"
  Transient (
    InitialTime=815e-9 FinalTime=816e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(815e-9 816e-9) Intervals=20) )
  }

  NewCurrentPrefix="p9_rise_"
  Transient (
    InitialTime=816e-9 FinalTime=817e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(816e-9 817e-9) Intervals=20) )
  }
  NewCurrentPrefix="p9_hold_"
  Transient (
    InitialTime=817e-9 FinalTime=917e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(817e-9 917e-9) Intervals=50) )
  }
  NewCurrentPrefix="p9_fall_"
  Transient (
    InitialTime=917e-9 FinalTime=918e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(917e-9 918e-9) Intervals=20) )
  }

  NewCurrentPrefix="p10_rise_"
  Transient (
    InitialTime=918e-9 FinalTime=919e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(918e-9 919e-9) Intervals=20) )
  }
  NewCurrentPrefix="p10_hold_"
  Transient (
    InitialTime=919e-9 FinalTime=1019e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(919e-9 1019e-9) Intervals=50) )
  }
  NewCurrentPrefix="p10_fall_"
  Transient (
    InitialTime=1019e-9 FinalTime=1020e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1019e-9 1020e-9) Intervals=20) )
  }

  *=== POST-PULSE READ: ID-VGS sweep to extract final Vth ===
  NewCurrentPrefix="postpulse_fwd_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  NewCurrentPrefix="postpulse_rev_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

}
