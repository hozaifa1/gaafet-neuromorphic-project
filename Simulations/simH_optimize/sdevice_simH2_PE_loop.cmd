*===================================================================
*== PHASE 1D — SIM H2 v6: V_t SHIFT (MW + analog states) at V_pgm
*==
*== v1 INVALIDATED (2026-05-11): Vsource_pset/pwl pulse-delivery bug
*==   (same as H1 v1).
*== v2 INVALIDATED (2026-05-14): bare-Electrode + ACCoupled — fails
*==   at parse with "Cannot find AC node 'gate_contact'!" (ACCoupled
*==   needs circuit nodes from a System {} block).
*== v3 INVALIDATED (2026-05-15): Quasistationary V_G read sweeps
*==   overwrite the FE state via fictitious-time creep.
*== v4 PARTIAL (2026-05-15): Transient + Goal everywhere, 100 ns
*==   pulses → no MW, depolarization-screened ERS.
*== v5 PARTIAL (2026-05-15): 10 µs pulses confirm FE switches fully
*==   (Pol_y swings -6.82 → +3.84 µC/cm² at V_pgm=6V), but read sweep
*==   was still 100 µs long → FE responds to V_G ramp DURING the read
*==   → postpgm and posters branches converge to the same V_t state.
*==   This is the same read-overwrite failure mode as v3, just slower.
*==
*== v6 fix (Tier A, 2026-05-15): READ SWEEP DURATION = 100 ns.
*==   This matches H0a v5 exactly (which delivered MW = 1.40 V).
*==   At 100 ns ramp from V_G = -2 V → +1 V, dV/dt = 30 V/µs.  FE
*==   polarization dynamics CANNOT respond at that timescale because
*==   even saturated-state |E_y|/F_c ≈ 0.4 isn't enough to drive
*==   meaningful Preisach switching in 100 ns (we measured this in
*==   v4 — 100 ns pulses produce only ~100 mV V_t shifts).  The FE
*==   is therefore EFFECTIVELY FROZEN during the read, so the V_t
*==   measured reflects the polarization state set by the preceding
*==   10 µs PGM/ERS pulse — not whatever the read sweep imposed.
*==
*==   Cost: only 62-100 V_G samples per read (vs 100 µs's 100 samples).
*==   But H0a v5's 62-sample 100 ns reads gave R² = 0.95 (M9 PASS) so
*==   this is fully publication-grade.
*==
*== End-to-end Transient + Goal pattern preserved (only timing
*== changes from v5).  Plt filenames preserved → analyzer needs no
*== retargeting (just one tweak: drop V_G=-2V first-sample artifact).
*==
*== SWB parameter:  @V_pgm@  ∈ {1.5, 2.0, 2.5, 3.5, 6.0} V
*==   (For M4 9-level demo, expand to {1.5, 1.75, 2.0, 2.25, 2.5,
*==    2.75, 3.0, 3.5, 4.0} V — 9 nodes dense in the sub-coercive
*==    regime where V_t shift is monotonic.)
*==
*== Pulse cadence: 10 ns rise / 10 µs hold / 10 ns fall / 100 ns settle.
*==
*== Time anchors (seconds, absolute):
*==   0.0       → 1.0e-7   setup_virgin   (V_G → -2.0 V, 100 ns)
*==   1.0e-7    → 2.0e-7   idvg_virgin    (V_G → +1.0 V, 100 ns)  ← was 100 µs
*==   2.0e-7    → 3.0e-7   gate_to_0_preP (V_G → 0 V,    100 ns)
*==   3.0e-7    → 3.1e-7   pgm_rise       (V_G → V_pgm,  10 ns)
*==   3.1e-7    → 1.031e-5 pgm_hold       (10 µs)
*==   1.031e-5  → 1.032e-5 pgm_fall       (V_G → 0 V,    10 ns)
*==   1.032e-5  → 1.042e-5 pgm_settle     (100 ns)
*==   1.042e-5  → 1.052e-5 setup_postpgm  (V_G → -2.0 V, 100 ns)
*==   1.052e-5  → 1.062e-5 idvg_postpgm   (V_G → +1.0 V, 100 ns)
*==   1.062e-5  → 1.072e-5 gate_to_0_preE (V_G → 0 V,    100 ns)
*==   1.072e-5  → 1.073e-5 ers_rise       (V_G → -V_pgm, 10 ns)
*==   1.073e-5  → 2.073e-5 ers_hold       (10 µs)
*==   2.073e-5  → 2.074e-5 ers_fall       (V_G → 0 V,    10 ns)
*==   2.074e-5  → 2.084e-5 ers_settle     (100 ns)
*==   2.084e-5  → 2.094e-5 setup_posters  (V_G → -2.0 V, 100 ns)
*==   2.094e-5  → 2.104e-5 idvg_posters   (V_G → +1.0 V, 100 ns)
*==
*== Total: ~21 µs (vs v5 ~320 µs).  15× faster overall, 1000× faster
*==   for each of the 3 read sweeps.
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
  TotalCurrent/Vector ElectricField/Vector Potential SpaceCharge
  ConductionBand ValenceBand Doping Polarization/Vector
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

  *=== STEP 1: RAMP V_DS TO 0.05 V (QS, drain ramp doesn't perturb FE) ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: SETUP FOR VIRGIN READ — V_G → -2.0 V (Transient, 100 ns) ===
  NewCurrentPrefix="setup_virgin_"
  Transient (
    InitialTime=0 FinalTime=1.0e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 3: VIRGIN ID-VG READ — Transient + Goal, V_G -2 → +1 V over 100 ns ===
  *== Matches H0a v5 exactly.  Fast enough that FE polarization is
  *== frozen during the read (saturated-state |E_y|/F_c ≈ 0.4 cannot
  *== drive switching in 100 ns).
  NewCurrentPrefix="idvg_virgin_"
  Transient (
    InitialTime=1.0e-07 FinalTime=2.0e-07
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7
    Increment=1.2
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0e-07 2.0e-07) Intervals=60) )
  }

  *=== STEP 4: V_G → 0 V before PGM (Transient, 100 ns) ===
  NewCurrentPrefix="gate_to_0_preP_"
  Transient (
    InitialTime=2.0e-07 FinalTime=3.0e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 5: PGM PULSE (10 ns rise / 10 µs hold / 10 ns fall / 100 ns settle) ===
  NewCurrentPrefix="pgm_rise_"
  Transient (
    InitialTime=3.0e-07 FinalTime=3.1e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0e-07 3.1e-07) Intervals=10) )
  }
  NewCurrentPrefix="pgm_hold_"
  Transient (
    InitialTime=3.1e-07 FinalTime=1.031e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.1e-07 1.031e-05) Intervals=40) )
  }
  NewCurrentPrefix="pgm_fall_"
  Transient (
    InitialTime=1.031e-05 FinalTime=1.032e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.031e-05 1.032e-05) Intervals=10) )
  }
  NewCurrentPrefix="pgm_settle_"
  Transient (
    InitialTime=1.032e-05 FinalTime=1.042e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.032e-05 1.042e-05) Intervals=10) )
  }

  *=== STEP 6: SETUP FOR POST-PGM READ — V_G → -2.0 V (Transient, 100 ns) ===
  NewCurrentPrefix="setup_postpgm_"
  Transient (
    InitialTime=1.042e-05 FinalTime=1.052e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 7: POST-PGM ID-VG READ — Transient + Goal, V_G -2 → +1 V over 100 ns ===
  NewCurrentPrefix="idvg_postpgm_"
  Transient (
    InitialTime=1.052e-05 FinalTime=1.062e-05
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7
    Increment=1.2
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.052e-05 1.062e-05) Intervals=60) )
  }

  *=== STEP 8: V_G → 0 V before ERS (Transient, 100 ns) ===
  NewCurrentPrefix="gate_to_0_preE_"
  Transient (
    InitialTime=1.062e-05 FinalTime=1.072e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 9: ERS PULSE (10 ns rise / 10 µs hold / 10 ns fall / 100 ns settle) ===
  NewCurrentPrefix="ers_rise_"
  Transient (
    InitialTime=1.072e-05 FinalTime=1.073e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -@V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.072e-05 1.073e-05) Intervals=10) )
  }
  NewCurrentPrefix="ers_hold_"
  Transient (
    InitialTime=1.073e-05 FinalTime=2.073e-05
    InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.073e-05 2.073e-05) Intervals=40) )
  }
  NewCurrentPrefix="ers_fall_"
  Transient (
    InitialTime=2.073e-05 FinalTime=2.074e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 0.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.073e-05 2.074e-05) Intervals=10) )
  }
  NewCurrentPrefix="ers_settle_"
  Transient (
    InitialTime=2.074e-05 FinalTime=2.084e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.074e-05 2.084e-05) Intervals=10) )
  }

  *=== STEP 10: SETUP FOR POST-ERS READ — V_G → -2.0 V (Transient, 100 ns) ===
  NewCurrentPrefix="setup_posters_"
  Transient (
    InitialTime=2.084e-05 FinalTime=2.094e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 11: POST-ERS ID-VG READ — Transient + Goal, V_G -2 → +1 V over 100 ns ===
  NewCurrentPrefix="idvg_posters_"
  Transient (
    InitialTime=2.094e-05 FinalTime=2.104e-05
    InitialStep=1e-3 MaxStep=2e-2 MinStep=1e-7
    Increment=1.2
    Goal { Name="gate_contact" Voltage= 1.0 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.094e-05 2.104e-05) Intervals=60) )
  }

}

*===================================================================
*== SWB SETUP:
*==   Parameter:  @V_pgm@
*==   Sweep:      1.5  2.0  2.5  3.5  6.0    V  (M3 V_pgm-dependence)
*==
*== POST-PROCESSING (analyze_phase1d_h2.py with v6 first-sample skip):
*==   1. Extract V_t per branch via constant-current criterion at
*==      I_D/W = 1e-4 µA/µm (Tasneem 2022 Fig.3c).  Skip V_G=-2V first
*==      sample (displacement-current artifact from start-of-Transient).
*==   2. ΔV_t = V_t_posters − V_t_postpgm = memory window (M3 ≥ 0.5 V).
*==   3. Stack the three log(ID)-V_G read curves to demonstrate
*==      hysteresis closure (PGM and ERS branches separated, virgin
*==      between them).
*===================================================================
