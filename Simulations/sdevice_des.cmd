*===================================================================
*== Block 1: FILE I/O
*== Purpose: Define input/output files for the FeFET simulation.
*===================================================================
File {
    Grid = "@tdr@"
    Parameter = "sdevice_gaafet_lif.par"
    Plot = "@tdrdat@"
    Current = "@plot@"
    Output = "@log@"
}  

*===================================================================
*== Block 2: ELECTRODES
*== Purpose: Define contacts and their properties.
*== Note:    The top and bottom gates are combined into a single
*==          electrode for simultaneous biasing.
*===================================================================
Electrode {
  { Name="source_contact"     Voltage= 0.0  DistResist=1.5e-8 }
  { Name="drain_contact"      Voltage= 1    DistResist=1.5e-8 }
  { Name="gate_contact"       Voltage= 0.0  Workfunction=4.525 }
}

*===================================================================
*== Block 3: PHYSICS
*== Purpose: Define the physical models for the simulation.
*===================================================================
* --- Physics models for Silicon (default material) ---
Physics {
  Temperature= 300
  Areafactor=4.0  * Calibrated to achieve 87 µA @ VSG=-0.5V, VDS=1.0V

  Fermi
	EffectiveIntrinsicDensity( OldSlotboom )
  
  * Quantum confinement (critical for nanoscale GAA)
  eQuantumPotential(AutoOrientation Density)
  hQuantumPotential(AutoOrientation Density)
  
  Mobility(
    PhuMob  * Philips unified mobility model for thin channels
    Enormal
  )
  Recombination(
    SRH (DopingDependence TempDependence)
    Auger
    Avalanche(UniBo2 BandgapDependence)  * Paper uses BandgapDependence for d0 to affect d(T)
    Band2Band(Model=Hurkx)  * Critical for nanoscale BTBT current
  )
	Hydrodynamic(eTemperature hTemperature)

}

* --- Physics model for the Ferroelectric material ---
Physics(Material="HZO") {
		FEPolarization ( direction="y")
	}

*===================================================================
*== Block 4: MATH
*== Purpose: Set numerical solver parameters for convergence.
*===================================================================
Math {
	Digits= 5
	ErrRef(electron)= 1.000e+00
	ErrRef(hole)= 1.000e+00
	Iterations= 50
	NotDamped= 100
	RHSMin= 1.000e-15
	
	* Required for quantum models
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


*===================================================================
*== Block 5: PLOT
*== Purpose: Specify variables to save in the output TDR file.
*===================================================================
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
*== Block 6: SOLVE
*== Purpose: Execute DC transfer characteristics (Id-Vg) simulation.
*== Method: Quasistationary for steady-state DC I-V sweeps
*===================================================================
Solve {

* Step 1: Initialize with Poisson-only equilibrium
Coupled(Iterations=100) { Poisson }

* Step 2: Add carriers at equilibrium
Coupled(Iterations=100) { Poisson Electron Hole }

* Step 3: Initialize FE polarization at equilibrium (short transient)
Transient (
	InitialTime=0 FinalTime=1e-6
	MaxStep=1e-7 InitialStep=1e-9
) { Coupled (Iterations=100) { Poisson FEPolarization } }

* Step 4: Couple FE polarization with carriers at equilibrium
Coupled(Iterations=100) { Poisson Electron Hole FEPolarization }

* Step 5: DC I-V sweep - Gate from 0V to 2.0V (QUASISTATIONARY for DC)
* This obtains steady-state transfer characteristics as in Paper Figure 7b
Quasistationary (
	DoZero
	InitialStep=1e-2 Increment=1.1
	MinStep=1e-6 MaxStep=0.05
	Goal { Name="gate_contact" Voltage=2.0 }
) { Coupled(Iterations=100) { Poisson Electron Hole FEPolarization eQuantumPotential hQuantumPotential } }

* Step 6: Reverse sweep - Gate from 2.0V back to 0V (hysteresis)
Quasistationary (
	InitialStep=1e-2 Increment=1.1
	MinStep=1e-6 MaxStep=0.05
	Goal { Name="gate_contact" Voltage=0.0 }
) { Coupled(Iterations=100) { Poisson Electron Hole FEPolarization eQuantumPotential hQuantumPotential } }

}
