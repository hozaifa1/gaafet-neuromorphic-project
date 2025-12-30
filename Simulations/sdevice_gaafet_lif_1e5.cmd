*===================================================================
*== Block 1: FILE I/O
*== Purpose: Define input/output files for the FeFET simulation.
*===================================================================
File {
    Grid = "@tdr@"
    Parameter = "sdevice_gaafet_lif_1e5.par"
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
  { Name="source_contact"     Voltage= 0.0 }
  { Name="drain_contact"      Voltage= 1.0 }
  { Name="gate_contact"   Voltage= 0.0 Workfunction=4.6 }
}

*===================================================================
*== Block 3: PHYSICS
*== Purpose: Define the physical models for the simulation.
*===================================================================
* --- Physics models for Silicon (default material) ---
Physics {
  Temperature= 300
  Areafactor=0.09  * Scale for 90nm fin height (H_FNS/1000nm default)

  Fermi
	EffectiveIntrinsicDensity( OldSlotboom )
  Mobility(
    ConstantMobility
    HighFieldSaturation
    Enormal
  )
  Recombination(
    SRH (DopingDependence TempDependence)
    Auger
    Avalanche(UniBo2 CarrierTempDrive)  * Hydrodynamic needed for convergence
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
	Extrapolate
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
*== Purpose: Execute the simulation sequence to trace the Id-Vg
*==          hysteresis loop.
*===================================================================
Solve {
 Transient (
	InitialTime=0 FinalTime=1
	) { Coupled (Iterations = 100) { Poisson FEPolarization } }	
Transient (
	MaxStep=1e-3 InitialStep=1e-5 MinStep=1e-6
	InitialTime=1 FinalTime=2 
	Goal { Name="gate_contact" Voltage= 2.0 }
	) { Coupled (Iterations = 100) {Poisson Electron Hole FEPolarization} }

Transient (
	MaxStep=1e-3 InitialStep=1e-5 MinStep=1e-6
	InitialTime=1 FinalTime=2 
	Goal { Name="gate_contact" Voltage= 0 }
	) { Coupled (Iterations = 100) {Poisson Electron Hole FEPolarization} }


}
