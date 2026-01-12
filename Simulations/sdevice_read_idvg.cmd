*===================================================================
*== STEP 2: READ DC I-V AT DIFFERENT VDS (Run for each VDS)
*== Purpose: Measure DC transfer curve with fixed FE state
*===================================================================
File {
    Grid = "@tdr@"
    Parameter = "sdevice_gaafet_lif.par"
    Plot = "@tdrdat@"
    Current = "@plot@"
    Output = "@log@"
}  

Electrode {
  { Name="source_contact"     Voltage= 0.0  DistResist=1.5e-8 }
  { Name="drain_contact"      Voltage= @Vds@  DistResist=1.5e-8 }
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
*== LOAD FE STATE and do DC QUASISTATIONARY sweep
*===================================================================
Solve {
  * Load the FE state from Step 1
  Load(FilePrefix="n_write_des")

  * Set drain to target VDS
  NewCurrentPrefix= "tmp"
  Quasistationary (
    InitialStep=1e-2 Increment=1.1
    MinStep=1e-6 MaxStep=0.05
    Goal { Name="drain_contact" Voltage= @Vds@ }
  ) { Coupled { Poisson Electron Hole eQuantumPotential hQuantumPotential } }

  * DC gate sweep from 0V to 2V (forward)
  NewCurrentPrefix= "idvg_fwd_"
  Quasistationary (
    DoZero
    InitialStep=1e-2 Increment=1.1
    MinStep=1e-6 MaxStep=0.05
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled { Poisson Electron Hole eQuantumPotential hQuantumPotential } }
  
  * DC gate sweep from 2V to 0V (reverse) 
  NewCurrentPrefix= "idvg_rev_"
  Quasistationary (
    DoZero
    InitialStep=1e-2 Increment=1.1
    MinStep=1e-6 MaxStep=0.05
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled { Poisson Electron Hole eQuantumPotential hQuantumPotential } }
}
