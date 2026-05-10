*===================================================================
*== PHASE 1D — SIM H0e: P-E LOOP VALIDATION vs MFM ANCHOR (v2)
*== Reference anchors (independent of Tasneem 2022 I-V):
*==   Park et al. 2020 APL — MFM on HZO 10 nm
*==   Müller et al. 2012 IEDM — P-E baseline
*== Targets: P_r ±10% of 16 µC/cm^2; P_s ±10% of 20; E_c ±15% of 1.2 MV/cm
*==
*== v2 fix vs v1 (which hung on submit, 2026-05-10):
*==   v1 used Transient+Goal with absolute-style step values
*==   (MaxStep=2e-5 etc.). Per spiking_simulation_debugging_log_v2 §2,
*==   Transient+Goal step sizes are NORMALIZED FRACTIONS of the time
*==   delta — so MaxStep=2e-5 caps at 32 ns per step over a 1.6 ms leg
*==   = 50000+ steps → solver hang. v2 replaces Transient+Goal with
*==   Quasistationary (same pattern as the working simH2_PE_loop.cmd).
*==   This is correct because sweep×τ_E = 2.5 V/ms × 1 µs ≈ 0 — the
*==   loop is quasi-static for our domain dynamics.
*==
*== Protocol: pure FE drive, no V_DS, no current.
*==   Triangular V_G ±4 V, two cycles (1: wake-up, 2: reported).
*==   Polarization & E logged at HZO mid-point each QS step.
*===================================================================

File {
    Grid       = "@tdr@"
    Parameter  = "sdevice_gaafet_lif.par"
    Plot       = "@tdrdat@"
    Current    = "@plot@"
    Output     = "@log@"
}

Electrode {
  { Name="source_contact"  Voltage= 0.0 }
  { Name="drain_contact"   Voltage= 0.0 }
  { Name="gate_contact"    Voltage= 0.0  Workfunction=4.35 }
}

Physics {
  Temperature= 300
  Areafactor= 0.071
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
   Iterations=50
   Transient=BE
   FEPolarizationIP=1.0
   Method=Blocked
   SubMethod=ParDiSo
   GeometricDistances
   Derivative
   ComputeGradQuasiFermiAtContacts= UseQuasiFermi
   RefDens_eGradQuasiFermi_ElectricField_HFS= 1.000e+12
   RefDens_hGradQuasiFermi_ElectricField_HFS= 1.000e+12
   Method = Bitlis (Restart=100, Tolerance=1e-5, Iterations=200)
}

Plot {
  eDensity hDensity
  ElectricField/Vector Potential SpaceCharge Polarization/Vector
}

CurrentPlot {
  Polarization/Vector  (( 0 0.0145 ))
  ElectricField/Vector (( 0 0.0145 ))
}

Solve {

  *=== STEP 0: INITIALIZE ===
  Coupled (Iterations= 100 LineSearchDamping= 1e-8) { Poisson }
  Coupled { Poisson Electron Hole }

  *=== CYCLE 1 — WAKE-UP ===
  *== 1A: 0 → +4 V
  NewCurrentPrefix="c1_up1_"
  Quasistationary (
    DoZero
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7 Increment=1.4
    Goal { Name="gate_contact" Voltage= 4.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(0 1) Intervals=80) )
  }

  *== 1B: +4 → -4 V
  NewCurrentPrefix="c1_down_"
  Quasistationary (
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7 Increment=1.4
    Goal { Name="gate_contact" Voltage= -4.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(0 1) Intervals=160) )
  }

  *== 1C: -4 → +4 V (closes cycle 1)
  NewCurrentPrefix="c1_up2_"
  Quasistationary (
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7 Increment=1.4
    Goal { Name="gate_contact" Voltage= 4.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(0 1) Intervals=160) )
  }

  *=== CYCLE 2 — STEADY-STATE LOOP (reported) ===
  *== 2A: +4 → -4 V
  NewCurrentPrefix="c2_down_"
  Quasistationary (
    InitialStep=1e-3 MaxStep=1e-2 MinStep=1e-7 Increment=1.4
    Goal { Name="gate_contact" Voltage= -4.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(0 1) Intervals=320) )
  }

  *== 2B: -4 → +4 V (closes cycle 2)
  NewCurrentPrefix="c2_up_"
  Quasistationary (
    InitialStep=1e-3 MaxStep=1e-2 MinStep=1e-7 Increment=1.4
    Goal { Name="gate_contact" Voltage= 4.0 }
  ) {
    Coupled (Iterations = 100) {Poisson Electron Hole}
    CurrentPlot( Time = (Range=(0 1) Intervals=320) )
  }

}
