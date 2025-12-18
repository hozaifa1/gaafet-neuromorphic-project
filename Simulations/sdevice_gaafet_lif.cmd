*=====================================================================
*== GAA FeFET LIF Neuron - S-Device Command File
*== 
*== Device: 2D Double-Gate approximation of GAA Floating Nanosheet FET
*== Application: Leaky Integrate-and-Fire (LIF) Neuron
*== 
*== Key Physics: Ferroelectric (HZO), Impact Ionization (UniBo2),
*==              Floating Body Effect
*=====================================================================

*=====================================================================
*== Block 1: FILE I/O
*=====================================================================
File {
    Grid = "@tdr@"
    Parameter = "sdevice_gaafet_lif.par"
    Plot = "@tdrdat@"
    Current = "@plot@"
    Output = "@log@"
}

*=====================================================================
*== Block 2: ELECTRODE DEFINITIONS
*== Note: AreaFactor=0.09 applied globally for 90nm fin height scaling
*=====================================================================
Electrode {
    { Name="source_contact"  Voltage=0.0 }
    { Name="drain_contact"   Voltage=0.0 }
    { Name="gate_contact"    Voltage=0.0  Workfunction=4.6 }
}

*=====================================================================
*== Block 3: PHYSICS MODELS
*== Includes: Fermi statistics, mobility models, recombination,
*==           impact ionization (UniBo2), and ferroelectric polarization
*=====================================================================

* --- Global Physics Settings ---
Physics {
    Temperature=300
    AreaFactor=0.09    * Scale for 90nm fin height (90nm/1000nm default)
    
    Fermi
    EffectiveIntrinsicDensity(OldSlotboom)
    
    Mobility(
        DopingDep
        HighFieldSaturation
        Enormal
    )
    
    Recombination(
        SRH(DopingDependence TempDependence)
        Auger
        Avalanche(UniBo2)    * CRITICAL: Impact Ionization for LIF firing
    )
    
    Hydrodynamic
}

* --- Ferroelectric Physics for HZO Material ---
Physics(Material="HZO") {
    FEPolarization(direction="y")
}

*=====================================================================
*== Block 4: MATH SOLVER SETTINGS
*== Optimized for ferroelectric and impact ionization convergence
*=====================================================================
Math {
    Digits=5
    ErrRef(electron)=1.0
    ErrRef(hole)=1.0
    Iterations=50
    NotDamped=100
    RHSMin=1e-15
    Extrapolate
    Transient=BE
    
    ComputeGradQuasiFermiAtContacts=UseQuasiFermi
    RefDens_eGradQuasiFermi_ElectricField_HFS=1e12
    RefDens_hGradQuasiFermi_ElectricField_HFS=1e12
    
    Method=Blocked
    SubMethod=Super
    
    * Ferroelectric solver settings
    FEPolarizationIP=1.0
    Method=Bitlis(Restart=100, Tolerance=1e-5, Iterations=200)
}

*=====================================================================
*== Block 5: PLOT VARIABLES
*== Output quantities for analysis and visualization
*=====================================================================
Plot {
    * Carrier densities
    eDensity hDensity
    
    * Current and fields
    TotalCurrent/Vector
    eCurrent/Vector hCurrent/Vector
    ElectricField/Vector
    Potential
    
    * Band structure
    ConductionBand ValenceBand
    BandGap BandGapNarrowing
    eQuasiFermi hQuasiFermi
    
    * Doping and charge
    Doping DonorConcentration AcceptorConcentration
    SpaceCharge
    
    * Ferroelectric
    FEPolarization/Vector
    
    * Impact Ionization
    AvalancheGeneration
    eAvalanche hAvalanche
    
    * Mobility
    eMobility hMobility
    eVelocity hVelocity
}

*=====================================================================
*== Block 6: SOLVE SEQUENCE
*== Phase 1: Initialize ferroelectric state
*== Phase 2: Id-Vg sweep for device characterization
*== Phase 3: Transient simulation for LIF behavior (optional)
*=====================================================================
Solve {
    * --- Phase 1: Ferroelectric Initialization ---
    * Equilibrate FE polarization at zero bias
    Transient(
        InitialTime=0 FinalTime=1
    ) { 
        Coupled(Iterations=100) { Poisson FEPolarization } 
    }
    
    * --- Phase 2: Id-Vg Characterization ---
    * Set drain bias to operating voltage
    Transient(
        MaxStep=2.5e-3 InitialStep=1e-4 MinStep=1e-5
        InitialTime=1 FinalTime=2
        Goal { Name="drain_contact" Voltage=1.0 }
    ) { 
        Coupled(Iterations=100) { Poisson Electron Hole FEPolarization } 
    }
    
    * Forward gate sweep: 0V -> +2V (Program direction)
    NewCurrentFile="IdVg_Forward_"
    Quasistationary(
        InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
        Goal { Name="gate_contact" Voltage=2.0 }
    ) { 
        Coupled(Iterations=50) { Poisson Electron Hole FEPolarization } 
    }
    
    * Reverse gate sweep: +2V -> -2V (Erase direction)
    NewCurrentFile="IdVg_Reverse_"
    Quasistationary(
        InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
        Goal { Name="gate_contact" Voltage=-2.0 }
    ) { 
        Coupled(Iterations=50) { Poisson Electron Hole FEPolarization } 
    }
    
    * Return sweep: -2V -> 0V
    NewCurrentFile="IdVg_Return_"
    Quasistationary(
        InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
        Goal { Name="gate_contact" Voltage=0.0 }
    ) { 
        Coupled(Iterations=50) { Poisson Electron Hole FEPolarization } 
    }
}

*=====================================================================
*== END OF S-DEVICE COMMAND FILE
*=====================================================================
