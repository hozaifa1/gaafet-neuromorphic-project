*===================================================================
*== STEP 1: WRITE FERROELECTRIC STATE (Run this ONCE)
*== Purpose: Initialize FE polarization via hysteresis loop
*===================================================================
File {
    Grid = "@tdr@"
    Parameter = "sdevice_gaafet_lif.par"
    Plot = "n_write_des.tdr"
    Current = "write_fe.plt"
    Output = "write_fe.log"
}  

Electrode {
  { Name="source_contact"     Voltage= 0.0  DistResist=1.5e-8 }
  { Name="drain_contact"      Voltage= 0.05  DistResist=1.5e-8 }
  { Name="gate_contact"       Voltage= 0.0  Workfunction=4.525 }
}

Physics {
  Temperature= 300
  Areafactor=4.0

  Fermi
  EffectiveIntrinsicDensity( OldSlotboom )
  
  eQuantumPotential(AutoOrientation Density)
  hQuantumPotential(AutoOrientation Density)
  
  Mobility(
    PhuMob
    Enormal
  )
  Recombination(
    SRH (DopingDependence TempDependence)
    Auger
    Avalanche(UniBo2 BandgapDependence)
    Band2Band(Model=Hurkx)
  )
  Hydrodynamic(eTemperature hTemperature)
}

Physics(Material="HZO") {
  FEPolarization ( direction="y")
}

Math {
  Digits= 5
  ErrRef(electron)= 1.000e+00
  ErrRef(hole)= 1.000e+00
  Iterations= 50
  NotDamped= 100
  RHSMin= 1.000e-15
  
  GeometricDistances
  Extrapolate
  Derivative
  
  Transient= BE
  ComputeGradQuasiFermiAtContacts= UseQuasiFermi
  RefDens_eGradQuasiFermi_ElectricField_HFS= 1.000e+12
  RefDens_hGradQuasiFermi_ElectricField_HFS= 1.000e+12
  Method= Blocked
  SubMethod= Super
  
  FEPolarizationIP=1.0
  Method = Bitlis (Restart=100, Tolerance=1e-5, Iterations=200)
}

Plot {
  eDensity hDensity
  TotalCurrent/Vector
  ElectricField/Vector
  Potential
  SpaceCharge
  ConductionBand
  ValenceBand
  Doping
  FEPolarization/Vector
  BandGap
  BandGapNarrowing
  eTrappedCharge
  hTrappedCharge
  eBarrierTunneling hBarrierTunneling 
  eDirectTunnel hDirectTunnel
  AvalancheGeneration eAvalancheGeneration hAvalancheGeneration
  SRHRecombination AugerRecombination
  eMobility hMobility
  eVelocity hVelocity
}

*===================================================================
*== WRITE FE STATE via hysteresis loop at LOW VDS
*===================================================================
Solve {
  * Initialize FE polarization
  Transient (
    InitialTime=0 FinalTime=1
  ) { Coupled (Iterations = 100) { Poisson FEPolarization } }

  * Forward sweep: 0V → +2V
  Transient (
    MaxStep=1e-4 InitialStep=1e-6 MinStep=1e-7
    InitialTime=1 FinalTime=2 
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole FEPolarization} }

  * Reverse sweep: +2V → 0V (sets remanent polarization state)
  Transient (
    MaxStep=1e-4 InitialStep=1e-6 MinStep=1e-7
    InitialTime=2 FinalTime=3 
    Goal { Name="gate_contact" Voltage= 0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole FEPolarization} }
}
