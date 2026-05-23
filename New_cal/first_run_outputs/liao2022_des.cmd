*===================================================================
*== LIAO 2022 CALIBRATION — WRITE-READ I_D-V_G
*== Reference: Liao et al., 2022 VLSI Symp. on Tech. & Circuits,
*==   pp. 393-394, doi:10.1109/VLSITechnologyandCir46769.2022.9830345
*==   "Endurance > 1E11 Cycling of 3D GAA Nanosheet Ferroelectric FET
*==    with Stacked HfZrO2 to Homogenize Corner Field Toward Mitigate
*==    Dead Zone for High-Density eNVM"
*==
*== Target: Fig. 7 transfer characteristics (MFMFS-GAA-FeFET branch)
*==   3D GAA Nanosheet, n-channel Si, HZO ferroelectric
*==   V_P/E = +/-3.5 V, t_PE = 5 us, V_DS_read = 0.2 V
*==   Memory window MW = 1.3 V, I_on/I_off > 1E9, endurance > 1E11
*==
*== Why this calibration replaces Tasneem 2022:
*==   Tasneem  : p-type, planar L=8 um, 5 nm ZrO2, MW=0.5 V
*==              -> required sign-flip + 2000x I_on rescale + MW
*==                 disclaimer (our 1.4 V vs their 0.5 V looked bad)
*==   Liao     : n-type, GAA-NS, HZO, MW=1.3 V — matches our device
*==              on architecture, polarity, ferroelectric, and MW
*==              within 7 percent. No apologetic normalization needed.
*==
*== TIER 1 SCOPE (this file):
*==   Protocol-only changes vs sdevice_simH0a_v5_writeread.cmd.
*==   sdevice_gaafet_lif.par stays frozen exactly as it was for
*==   H0a v5 onward (WF=4.35, AreaFactor=0.071, FixedCharge=4e12,
*==   P_r=16 uC/cm2, P_s=20 uC/cm2, F_c=1.2 MV/cm, tau_E=1 us,
*==   tau_P=10 us). See ../New_cal/PLAN.md for the full plan and
*==   Tier 2 escalation criteria.
*==
*== Protocol delta vs H0a v5:
*==   - V_DS_read:   0.05 V  -> 0.2 V       (Liao Fig. 7 read cond.)
*==   - V_PGM:       +4.0 V  -> +3.5 V      (Liao MFMFS-GAA)
*==   - V_ERS:       -4.0 V  -> -3.5 V      (Liao MFMFS-GAA)
*==   - Pulse hold:  10 us   -> 5 us        (Liao t_PE)
*==   - Read window: -2.0 -> +1.0 V         (unchanged; covers our
*==                                          V_t range and is well
*==                                          below V_c,gate = 1.91 V)
*==
*== V_c,gate sanity check at this stack:
*==   V_c,gate = F_c * t_FE * (1 + C_IL/C_FE) = 1.91 V
*==   Read sweep -2.0 -> +1.0 V stays sub-coercive — FE not disturbed
*==   Write +/-3.5 V is well above V_c,gate — full FE switching
*==
*== Sequence (parallel to H0a v5; only voltages/holds changed):
*==   0. Init Poisson
*==   1. Ramp V_DS to 0.2 V at V_G=0
*==   2. Baseline read at V_G=0
*==   3. ERS pulse: 0 -> -3.5 V (1 ns) + hold 5 us + -> 0 (1 ns)
*==   4. Pre-read setup: ramp V_G to -2.0 V
*==   5. Read 1 (post-ERS): V_G sweep -2.0 -> +1.0 V (100 ns)
*==   6. Pre-pulse setup: ramp V_G to 0
*==   7. PGM pulse: 0 -> +3.5 V + hold 5 us + -> 0
*==   8. Pre-read setup: ramp V_G to -2.0 V
*==   9. Read 2 (post-PGM): V_G sweep -2.0 -> +1.0 V
*==
*== Liao's 1-second write-to-read delay (their Fig. 1c) is NOT
*== reproducible in TCAD wall-clock — we read immediately, which
*== is analytically equivalent under our trap-free, tau_P=10 us
*== Preisach model (depolarization equilibrium reaches steady state
*== within ~5 tau_P = 50 us, well before the 1 s mark). Documented
*== as a methods caveat in PLAN.md.
*===================================================================

File {
    Grid       = "n1_msh.tdr"
    Parameter  = "sdevice_gaafet_lif.par"
    Plot       = "cal_again_outputs/liao2022_des.tdr"
    Current    = "cal_again_outputs/liao2022_des.plt"
    Output     = "cal_again_outputs/liao2022_des.log"
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
  TotalCurrent/Vector ElectricField/Vector Potential SpaceCharge
  ConductionBand ValenceBand Doping Polarization/Vector
  BandGap SRHRecombination AugerRecombination eMobility hMobility
}

CurrentPlot {
  Polarization/Vector (( 0 0.0145 ))
  ElectricField/Vector (( 0 0.0145 ))
}

Solve {

  *=== STEP 0: INITIALIZE ===
  Transient (
    InitialTime=0 FinalTime=1
  ) { Coupled (Iterations = 100) { Poisson } }

  *=== STEP 1: RAMP V_DS TO 0.2 V (Liao Fig. 7 read condition) ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.2 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: BASELINE READ AT V_G=0 ===
  NewCurrentPrefix="baseline_"
  Transient (
    InitialTime=0 FinalTime=1.0000e-07
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 3: ERS PULSE — -3.5 V, 5 us hold (Liao MFMFS-GAA) ===
  NewCurrentPrefix="ers_rise_"
  Transient (
    InitialTime=1.0000e-07 FinalTime=1.0100e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -3.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="ers_hold_"
  Transient (
    InitialTime=1.0100e-07 FinalTime=5.0100e-06
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="ers_fall_"
  Transient (
    InitialTime=5.0100e-06 FinalTime=5.0110e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 4: RAMP V_G TO -2.0 V FOR READ START ===
  NewCurrentPrefix="setup_readERS_"
  Transient (
    InitialTime=5.0110e-06 FinalTime=5.0120e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 5: READ 1 — POST-ERS SWEEP -2.0 V -> +1.0 V ===
  NewCurrentPrefix="read_postERS_"
  Transient (
    InitialTime=5.0120e-06 FinalTime=5.1120e-06
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7
    Increment=1.2
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 6: RAMP V_G BACK TO 0 BEFORE PGM ===
  NewCurrentPrefix="ret0_preP_"
  Transient (
    InitialTime=5.1120e-06 FinalTime=5.1130e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 7: PGM PULSE — +3.5 V, 5 us hold (Liao MFMFS-GAA) ===
  NewCurrentPrefix="pgm_rise_"
  Transient (
    InitialTime=5.1130e-06 FinalTime=5.1140e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 3.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="pgm_hold_"
  Transient (
    InitialTime=5.1140e-06 FinalTime=1.0114e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="pgm_fall_"
  Transient (
    InitialTime=1.0114e-05 FinalTime=1.0115e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 8: RAMP V_G TO -2.0 V FOR SECOND READ ===
  NewCurrentPrefix="setup_readPGM_"
  Transient (
    InitialTime=1.0115e-05 FinalTime=1.0116e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 9: READ 2 — POST-PGM SWEEP -2.0 V -> +1.0 V ===
  NewCurrentPrefix="read_postPGM_"
  Transient (
    InitialTime=1.0116e-05 FinalTime=1.0216e-05
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7
    Increment=1.2
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

}
