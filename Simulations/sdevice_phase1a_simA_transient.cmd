*===================================================================
*== PHASE 1A — SIM A: SINGLE PULSE Vth SHIFT (TRANSIENT READOUT)
*== Purpose: Apply ONE gate pulse, then read ID-VGS to measure dVth.
*== SWB Sweep: @Vpulse@ = 1.0, 1.5, 2.0, 2.5, 3.0 (5 runs)
*== Fixed: VDS=0.05V, pulse_width=100ns, tau_E=1µs (in .par)
*== Key: Transient readout (1ns) preserves partial-switching state
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
   Method=Bitlis
   SubMethod=ParDiSo
   Restart=100
   Tolerance=1e-5
   FEPolarizationIP=1.0
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

  *=== STEP 1: BASELINE ID-VGS (virgin FE state) ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

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

  NewCurrentPrefix="baseline_rev_"
  Transient (
    InitialTime=1e-9 FinalTime=2e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(1e-9 2e-9) Intervals=50) )
  }

  *=== STEP 2: GATE PULSE (Rise -> Hold -> Fall) ===
  * @Vpulse@ is swept via SWB: 1.0, 1.5, 2.0, 2.5, 3.0

  NewCurrentPrefix="pulse_rise_"
  Transient (
    InitialTime=2e-9 FinalTime=3e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @Vpulse@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2e-9 3e-9) Intervals=50) )
  }

  NewCurrentPrefix="pulse_hold_"
  Transient (
    InitialTime=3e-9 FinalTime=103e-9
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3e-9 103e-9) Intervals=100) )
  }

  NewCurrentPrefix="pulse_fall_"
  Transient (
    InitialTime=103e-9 FinalTime=104e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(103e-9 104e-9) Intervals=50) )
  }

  *=== STEP 3: POST-PULSE ID-VGS (measure Vth shift) ===
  NewCurrentPrefix="postpulse_fwd_"
  Transient (
    InitialTime=104e-9 FinalTime=105e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.3 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(104e-9 105e-9) Intervals=50) )
  }

  NewCurrentPrefix="postpulse_rev_"
  Transient (
    InitialTime=105e-9 FinalTime=106e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(105e-9 106e-9) Intervals=50) )
  }

}
