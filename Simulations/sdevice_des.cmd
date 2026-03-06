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
   Extrapolate
   Digits=5
   Notdamped=50
   Iterations=20
   Transient=BE
   Method=Blocked
   SubMethod=ParDiSo
   
   * NUCLEAR OPTION: Disable LTE completely. Trust Newton convergence only.
   ErrRef(Poisson)= 1e30
   ErrRef(Electron)= 1e30
   ErrRef(Hole)= 1e30
   ErrRef(FEPolarization)= 1e30
   ErrRef(eQuantumPotential)= 1e30
   ErrRef(hQuantumPotential)= 1e30
   ErrRef(LatticeTemperature)= 1e30
   ErrRef(eTemperature)= 1e30
   ErrRef(hTemperature)= 1e30
   
   * Required for quantum models
   GeometricDistances
   Derivative
   
   ComputeGradQuasiFermiAtContacts= UseQuasiFermi
   RefDens_eGradQuasiFermi_ElectricField_HFS= 1.000e+12
   RefDens_hGradQuasiFermi_ElectricField_HFS= 1.000e+12
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
*== Block 6: SOLVE (PHASE 3: LIF TRANSIENT FIRING)
*== Purpose: Test Integrate-and-Fire behavior.
*== Sequence:
*==   1. Ramp Drain to 1.0V (Bias)
*==   2. Step Gate to 1.2V (Input Spike)
*==   3. Transient Hold (Observe Switching/Firing)
*===================================================================
Solve {
  * --- STEP 1: INITIALIZE (VDS=0V) ---
  Transient (
    InitialTime=0 FinalTime=1
  ) { Coupled (Iterations = 100) { Poisson } }

  * --- STEP 2: RAMP DRAIN BIAS (VDS -> 1.0V) ---
  NewCurrentPrefix="init_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  * --- STEP 3: FIRE (Gate Step 0V -> 1.2V) ---
  * Split into Rise and Hold phases (Standard Sentaurus Syntax)
  
  * 3a. Rise (0 -> 50ps)
  NewCurrentPrefix="fire_rise_"
  Transient (
    InitialTime=0 FinalTime=50e-12
    InitialStep=1e-13 MaxStep=1e-12 MinStep=1e-15
    Increment=1.41
    Goal { Name="gate_contact" Voltage= 1.2 }
  ) { 
      Coupled (Iterations = 100) {Poisson Electron Hole} 
      CurrentPlot( Time = (Range=(0 50e-12) Intervals=200) )
  }

  * 3b. Hold (50ps -> 100ns)
  NewCurrentPrefix="fire_hold_"
  Transient (
    InitialTime=50e-12 FinalTime=100e-9
    InitialStep=1e-12 MaxStep=10e-12 MinStep=1e-15
    Increment=1.41
    Goal { Name="gate_contact" Voltage= 1.2 }
  ) { 
      Coupled (Iterations = 100) {Poisson Electron Hole} 
      CurrentPlot( Time = (Range=(50e-12 100e-9) Intervals=5000) )
  }
  
  * Plot( FilePrefix="n@node@_fire" ) -> Removed as we use segment prefixes
}

* --- OLD CALIBRATION SOLVE BLOCK (Preserved) ---
* Solve {
*   * --- STEP 1: INITIALIZE (VDS=0V) ---
*   Transient (
*     InitialTime=0 FinalTime=1
*   ) { Coupled (Iterations = 100) { Poisson } }
* ... (Hysteresis Logic commented out)
* }
