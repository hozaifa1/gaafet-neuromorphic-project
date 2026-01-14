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
  { Name="drain_contact"      Voltage= 0.0  DistResist=1.5e-8 }  * Start at 0V for Writing
  { Name="gate_contact"       Voltage= 0.0  Workfunction=3.9 }   * CALIBRATION: Lowered to 3.9eV (Band-edge) to force Normally-ON (Depletion Mode)
}

*===================================================================
*== Block 3: PHYSICS
*== Purpose: Define the physical models for the simulation.
*===================================================================
* --- Physics models for Silicon (default material) ---
Physics {
  Temperature= 300
  Areafactor=0.85  * Calibrated to match Paper's current magnitude (~100uA range)

  Fermi
	EffectiveIntrinsicDensity( OldSlotboom )
  
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

* --- CALIBRATION: Fixed Charge for Exact Vth Alignment ---
* Goal: Shift Vth from 0.65V to 0.25V (Delta = -0.4V)
* Q = Cox * 0.4V = 1.7e-6 * 0.4 = 6.8e-7 -> ~4.2e12 cm-2
Physics(MaterialInterface="Silicon/SiO2") {
    Charge(Pos=4.2e12)
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
*== Purpose: Execute the simulation sequence: 
*==          1. Write FE State (Transient)
*==          2. Read DC I-V (Quasistationary)
*===================================================================
Solve {
  * --- STEP 1: INITIALIZE (VDS=0V) ---
  Transient (
    InitialTime=0 FinalTime=1
  ) { Coupled (Iterations = 100) { Poisson FEPolarization } }

  * --- STEP 2: WRITE FE STATE (VDS=0V) ---
  * We write with Drain=0V to ensure full polarization switching
  * without "drain disturb" (reduced field near drain).
  NewCurrentPrefix="write_"
  Transient (
    MaxStep=1e-3 InitialStep=1e-5 MinStep=1e-6
    InitialTime=1 FinalTime=2 
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole FEPolarization} }

  Transient (
    MaxStep=1e-3 InitialStep=1e-5 MinStep=1e-6
    InitialTime=2 FinalTime=3 
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole FEPolarization} }

  * --- STEP 3: RAMP TO TARGET VDS ---
  * Now we assume the FE state is "frozen" or follows hysteresis.
  * Ramp drain to the target voltage for this node.
  NewCurrentPrefix="ramp_vds_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= @Vds@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole FEPolarization} }

  * --- STEP 4: READ DC I-V (Quasistationary) ---
  * Measure I-V at the constant Target VDS.
  * Sweep from -1.0V to 2.0V to capture negative Vth behavior
  NewCurrentPrefix="read_"
  Quasistationary (
    DoZero
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  Quasistationary (
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
}
