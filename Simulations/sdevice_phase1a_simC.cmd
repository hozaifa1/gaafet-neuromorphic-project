*===================================================================
*== PHASE 1A — SIM C: FULL LIF CYCLE (Integrate-Leak-Fire-Reset)
*== Purpose: Demonstrate complete LIF neuron behavior in one run.
*== Uses best Vpulse from Sim A, applies pulse train with gaps,
*== observes ID throughout, then resets with negative pulse.
*== SWB Sweep: @Vreset@ = -2.0, -3.0, -4.0 (3 runs)
*== Fixed: Vpulse from Sim A, VDS=0.05V, pw=100ns, 10 pulses,
*==        inter-pulse gap=1us (to observe leak between pulses)
*== Output: ID vs time showing integration steps, leak decay,
*==         fire event, and reset recovery
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

  *=== PULSE TRAIN: 5 pulses with 1us gaps (Integrate + Leak) ===
  * Each cycle: 1ns rise + 100ns hold + 1ns fall + 1us gap = ~1.1us
  * Total 5 cycles: ~5.5us
  * @Vpulse@ = fixed from Sim A result

  *--- PULSE 1 ---
  NewCurrentPrefix="lif_p1r_"
  Transient (
    InitialTime=0 FinalTime=1e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0 1e-9) Intervals=10) )
  }
  NewCurrentPrefix="lif_p1h_"
  Transient (
    InitialTime=1e-9 FinalTime=101e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1e-9 101e-9) Intervals=20) )
  }
  NewCurrentPrefix="lif_p1f_"
  Transient (
    InitialTime=101e-9 FinalTime=102e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(101e-9 102e-9) Intervals=10) )
  }
  * Gap 1 (1us leak observation)
  NewCurrentPrefix="lif_gap1_"
  Transient (
    InitialTime=102e-9 FinalTime=1.102e-6
    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(102e-9 1.102e-6) Intervals=50) )
  }

  *--- PULSE 2 ---
  NewCurrentPrefix="lif_p2r_"
  Transient (
    InitialTime=1.102e-6 FinalTime=1.103e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.102e-6 1.103e-6) Intervals=10) )
  }
  NewCurrentPrefix="lif_p2h_"
  Transient (
    InitialTime=1.103e-6 FinalTime=1.203e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.103e-6 1.203e-6) Intervals=20) )
  }
  NewCurrentPrefix="lif_p2f_"
  Transient (
    InitialTime=1.203e-6 FinalTime=1.204e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.203e-6 1.204e-6) Intervals=10) )
  }
  NewCurrentPrefix="lif_gap2_"
  Transient (
    InitialTime=1.204e-6 FinalTime=2.204e-6
    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.204e-6 2.204e-6) Intervals=50) )
  }

  *--- PULSE 3 ---
  NewCurrentPrefix="lif_p3r_"
  Transient (
    InitialTime=2.204e-6 FinalTime=2.205e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.204e-6 2.205e-6) Intervals=10) )
  }
  NewCurrentPrefix="lif_p3h_"
  Transient (
    InitialTime=2.205e-6 FinalTime=2.305e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.205e-6 2.305e-6) Intervals=20) )
  }
  NewCurrentPrefix="lif_p3f_"
  Transient (
    InitialTime=2.305e-6 FinalTime=2.306e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.305e-6 2.306e-6) Intervals=10) )
  }
  NewCurrentPrefix="lif_gap3_"
  Transient (
    InitialTime=2.306e-6 FinalTime=3.306e-6
    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.306e-6 3.306e-6) Intervals=50) )
  }

  *--- PULSE 4 ---
  NewCurrentPrefix="lif_p4r_"
  Transient (
    InitialTime=3.306e-6 FinalTime=3.307e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.306e-6 3.307e-6) Intervals=10) )
  }
  NewCurrentPrefix="lif_p4h_"
  Transient (
    InitialTime=3.307e-6 FinalTime=3.407e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.307e-6 3.407e-6) Intervals=20) )
  }
  NewCurrentPrefix="lif_p4f_"
  Transient (
    InitialTime=3.407e-6 FinalTime=3.408e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.407e-6 3.408e-6) Intervals=10) )
  }
  NewCurrentPrefix="lif_gap4_"
  Transient (
    InitialTime=3.408e-6 FinalTime=4.408e-6
    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.408e-6 4.408e-6) Intervals=50) )
  }

  *--- PULSE 5 ---
  NewCurrentPrefix="lif_p5r_"
  Transient (
    InitialTime=4.408e-6 FinalTime=4.409e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.408e-6 4.409e-6) Intervals=10) )
  }
  NewCurrentPrefix="lif_p5h_"
  Transient (
    InitialTime=4.409e-6 FinalTime=4.509e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.409e-6 4.509e-6) Intervals=20) )
  }
  NewCurrentPrefix="lif_p5f_"
  Transient (
    InitialTime=4.509e-6 FinalTime=4.510e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.509e-6 4.510e-6) Intervals=10) )
  }

  *=== RESET PULSE ===
  * @Vreset@ swept via SWB: -2.0, -3.0, -4.0
  NewCurrentPrefix="reset_rise_"
  Transient (
    InitialTime=4.510e-6 FinalTime=4.511e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vreset@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.510e-6 4.511e-6) Intervals=10) )
  }
  NewCurrentPrefix="reset_hold_"
  Transient (
    InitialTime=4.511e-6 FinalTime=4.611e-6
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.511e-6 4.611e-6) Intervals=50) )
  }
  NewCurrentPrefix="reset_fall_"
  Transient (
    InitialTime=4.611e-6 FinalTime=4.612e-6
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.611e-6 4.612e-6) Intervals=10) )
  }

  *=== POST-RESET READ: Verify Vth recovered ===
  NewCurrentPrefix="postreset_fwd_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  NewCurrentPrefix="postreset_rev_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

}
