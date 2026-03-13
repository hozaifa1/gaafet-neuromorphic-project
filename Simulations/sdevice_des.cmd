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
  { Name="source_contact"     Voltage= -0.25 }   * LIF: Negative source bias per paper line 210
  { Name="drain_contact"      Voltage= -0.25 }   * MUST equal source initially so V_DS = 0V
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
   RelErrControl
   Digits=4
   Notdamped=50
   Iterations=20
   Transient=BE
   Method=Blocked
   SubMethod=ParDiSo
   
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
*== Paper Biasing (Bhatawdekar Fig.4):
*==   - VSG is set FIRST as constant DC bias ("synaptic weight")
*==   - VD is PULSED to trigger Impact Ionization buildup
*== Our Sequence (matching paper):
*==   1. Initialize Poisson
*==   2. Ramp Gate to 0.3V (Quasistationary, VDS=0V) -> set weight
*==   3. Pulse Drain 0V -> 1.0V (Transient, 10ns rise) -> trigger II
*==   4. Hold (5us) -> observe integration -> fire
*== WHY: If drain is set first, device immediately reaches steady-state
*==       with no room for gradual II buildup. Paper pulses drain AFTER
*==       gate bias is set, so current starts near 0 and builds via II.
*===================================================================
Solve {
  * --- STEP 1: INITIALIZE ---
  Transient (
    InitialTime=0 FinalTime=1
  ) { Coupled (Iterations = 100) { Poisson } }

  * --- STEP 2: SET GATE BIAS (VGS -> Target) [VDS still 0V] ---
  * This is the "synaptic weight" input. Applied BEFORE drain pulse.
  * RUN 8: Using TWO transient data points to extrapolate correct V_GS:
  *   Run 6: V_GS=-0.32V -> I_D=74pA | Run 7b: V_GS=-0.20V -> I_D=6.95nA
  *   SS = 0.12V / log10(6.95e-9/74e-12) = 60.8 mV/dec
  *   For target ~200nA: V_GS = -0.20 + 0.0608*log10(200/6.95) = -0.111V
  *   V_G = V_S + V_GS = -0.25 + (-0.111) = -0.361V -> round to -0.36V
  * At V_D = -0.25V and V_S = -0.25V, V_DS = 0V. No initial drain current.
  NewCurrentPrefix="gate_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -0.36 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  * --- STEP 3: FIRE (Drain Pulse -0.25V -> 1.0V) ---
  * Paper: VD pulse triggers II at the drain-channel junction.
  * Current starts near 0, then II generates holes -> accumulate in
  * floating body -> positive feedback -> gradual current rise -> spike.
  
  * 3a. Rise (0 -> 10ns) - Drain ramp -0.25V -> 1.0V
  * CRITICAL: Transient+Goal uses NORMALIZED step sizes (fractions 0-1).
  * InitialStep=1e-3 -> 1e-3 * 10ns = 10ps effective
  * MaxStep=5e-2    -> 5e-2 * 10ns = 500ps effective
  * MinStep=1e-7    -> 1e-7 * 10ns = 1fs effective
  NewCurrentPrefix="fire_rise_"
  Transient (
    InitialTime=0 FinalTime=10e-9
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="drain_contact" Voltage= 1.0 }
  ) { 
      Coupled (Iterations = 100) {Poisson Electron Hole} 
      CurrentPlot( Time = (Range=(0 10e-9) Intervals=200) )
  }

  * 3b. Hold (10ns -> 5us) - Observe LIF integration and firing
  * No Goal needed: drain stays at 1.0V, gate at 0.3V.
  * Without Goal, step sizes are ABSOLUTE seconds.
  NewCurrentPrefix="fire_hold_"
  Transient (
    InitialTime=10e-9 FinalTime=5e-6
    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15
    Increment=1.4
  ) { 
      Coupled (Iterations = 100) {Poisson Electron Hole} 
      CurrentPlot( Time = (Range=(10e-9 5e-6) Intervals=2000) )
  }
}
