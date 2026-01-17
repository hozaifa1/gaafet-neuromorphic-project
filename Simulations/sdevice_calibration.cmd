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
  { Name="source_contact"     Voltage= 0.0 }
  { Name="drain_contact"      Voltage= 0.0 }
  { Name="gate_contact"       Voltage= 0.0  Workfunction=4.35 }   * CALIBRATION: Increased to 4.35eV to compensate for FE shift (Target Vth ~0.25V)
}

*===================================================================
*== Block 3: PHYSICS
*===================================================================
* --- Physics models for Silicon (default material) ---
Physics {
  Temperature= 300
  Areafactor=0.071  * Calibrated for 600uA target (Run 03 Fine-tune)
  
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
    Polarization
}

* --- CALIBRATION: Fixed Charge to tune Vth ---
* Run 02: Reduced Fixed Charge (3.5e12) to shift Vth Positive.
* Workfunction kept at 4.35eV.
Physics(MaterialInterface="Silicon/SiO2") {
    Traps(
        (FixedCharge Conc=4e12 Level EnergyMid=0.0 fromMidBandGap)
    )
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
  Polarization/Vector
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
*== Block 5b: CURRENT PLOT
*== Purpose: Save specific internal variables to the .plt file.
*== Syntax: Following sat_loop_des.cmd using point probe (( x y ))
*== Location: Center of Top HZO (x=0, y=0.0145)
*===================================================================
CurrentPlot {
  Polarization/Vector (( 0 0.0145 ))
  ElectricField/Vector (( 0 0.0145 ))
}

*===================================================================
*== Block 6: SOLVE (CALIBRATION MODE)
*== Purpose: Execute the simulation sequence: 
*==          1. Ramp VDS to 1.0V
*==          2. Read DC I-V (Transient Hysteresis)
*===================================================================
Solve {
  * --- STEP 1: INITIALIZE (VDS=0V) ---
  Transient (
    InitialTime=0 FinalTime=1
  ) { Coupled (Iterations = 100) { Poisson } }

  * --- STEP 2: RAMP DRAIN BIAS (VDS -> 1.0V) ---
  NewCurrentPrefix="ramp_vds_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  * --- STEP 3: READ DC I-V (Hysteresis Loop) ---
  * Using Transient solver for Hysteresis
  
  * Segment 1: Initial Curve (0V -> -6.0V)
  NewCurrentPrefix="read_leg1_"
  Transient (
    InitialTime=0 FinalTime=1
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  Plot( FilePrefix="n@node@_leg1" )

  * Segment 2: Forward Sweep (-6.0V -> +6.0V)
  * Captures the "Turn ON" and positive polarization switching.
  NewCurrentPrefix="read_leg2_"
  Transient (
    InitialTime=1 FinalTime=2
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= 6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  Plot( FilePrefix="n@node@_leg2" )

  * Segment 3: Reverse Sweep (+6.0V -> -6.0V)
  * Captures the Hysteresis/Memory Window.
  NewCurrentPrefix="read_leg3_"
  Transient (
    InitialTime=2 FinalTime=3
    InitialStep=1e-2 MaxStep=0.05 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -6.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  Plot( FilePrefix="n@node@_leg3" )
}
