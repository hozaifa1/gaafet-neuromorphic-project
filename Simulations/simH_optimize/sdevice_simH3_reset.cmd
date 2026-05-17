*===================================================================
*== PHASE 1D — SIM H3 v3: RESET PROTOCOL OPTIMIZATION (kills drift)
*==
*== v1 INVALIDATED (2026-05-11): Device{Electrode}+System/Vsource_pset/pwl
*==   silent-gate-drive bug.
*== v2 RAN, FAILED on intent (2026-05-17): V_reset ∈ {-3,-5,-7} V at
*==   t_reset = 10 µs over-drove the FE past virgin into the opposite
*==   polarization rail.  Post-settle ID sat at 3x / 32x / 76x the
*==   virgin baseline; subsequent +2 V "fire" pulses then partial-
*==   switched the FE *back toward* virgin, reversing the fire
*==   direction (fire_ratio_p1→p3 = 0.33x at V_reset=-5V c3).
*==   Root cause: 10 µs hold at sub-/near-coercive walks across the
*==   depolarization-screened |E| field all the way to the opposite
*==   saturation rail.  See Phase1D_Device_Optimization_Plan.md → H3.
*==
*== v3 fixes (2026-05-17):
*==   1. V_reset sweep narrowed and dropped:
*==        V_reset in {-1.0, -1.5, -2.0, -2.5} V  (L4)
*==      Sub-coercive at the FE for ALL nodes; symmetric/asymmetric
*==      to V_pgm = +2.0 V.  Set these values in SWB for V_reset.
*==   2. t_reset 10 µs → 1 µs hardcoded.  Sits between "100 ns =
*==      depolarization-screened to near zero" (H2 v4) and "10 µs =
*==      over-flips past virgin" (H3 v2).
*==   3. 3 → 5 cycles.  Cycle 1 is wake-up (FE starts at virgin,
*==      post-reset steady-state is a different polarization state —
*==      confirmed in H0e and H3 v2).  M1 drift fit uses cycles 3–5.
*==
*== V_pgm = +2.0 V hardcoded (V_pgm_opt from H1 v3: fire_ratio 4.79x,
*==   ΔV_t_eff = -68 mV, |E|/F_c = 0.41 sub-coercive, monotonic).
*== Read level V_GS = -0.5 V (H1 v3 sub-V_t convention).
*==
*== Cycle anatomy (per cycle):
*==   3 fire pulses (1 ns rise / 100 ns hold at +2.0 V / 1 ns fall /
*==                  100 ns read at -0.5 V)  = 606 ns
*==   reset (10 ns rise / 1 µs hold at V_reset / 10 ns fall)
*==                                          = 1020 ns
*==   settle (10 µs at V_GS = -0.5 V)        = 10000 ns
*==   ─────────────────────────────────────────────────
*==   Per-cycle total = 11.626 µs
*==
*== Absolute cycle anchors:
*==   c1 [   0.000 µs →  11.626 µs]
*==   c2 [  11.626 µs →  23.252 µs]
*==   c3 [  23.252 µs →  34.878 µs]
*==   c4 [  34.878 µs →  46.504 µs]
*==   c5 [  46.504 µs →  58.130 µs]
*==
*== Goal: |drift_per_cycle| ≤ 1.0 %/cycle (M1) fit across c3→c5
*==   steady-state, AND ID_settle_c5 within ±3x of virgin baseline
*==   (proves reset is RESTORING, not over-flipping), AND within-
*==   cycle fire_ratio_p1→p3 ≥ 1.5 against the same cycle's
*==   ID_settle (proves the fire is in the correct direction).
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

  *=== STEP 1: RAMP V_DS TO 0.05 V ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: RAMP V_G TO -0.5 V (sub-V_t read, matches H1 v3) ===
  NewCurrentPrefix="gate_to_read_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 3: BASELINE READ (pre-cycle 1, 100 ns at V_G = -0.5 V) ===
  NewCurrentPrefix="baseline_pre_"
  Transient (
    InitialTime=-1.0e-07 FinalTime=0.0
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(-1.0e-07 0.0) Intervals=20) )
  }

  *====================================================================
  *== CYCLE 1 (cycle base time = 0.0)
  *====================================================================
  NewCurrentPrefix="c1_p1_rise_"
  Transient (
    InitialTime=0.0 FinalTime=1.0e-09
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p1_write_"
  Transient (
    InitialTime=1.0e-09 FinalTime=1.01e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0e-09 1.01e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p1_fall_"
  Transient (
    InitialTime=1.01e-07 FinalTime=1.02e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p1_read_"
  Transient (
    InitialTime=1.02e-07 FinalTime=2.02e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.02e-07 2.02e-07) Intervals=20) ) }

  NewCurrentPrefix="c1_p2_rise_"
  Transient (
    InitialTime=2.02e-07 FinalTime=2.03e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p2_write_"
  Transient (
    InitialTime=2.03e-07 FinalTime=3.03e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.03e-07 3.03e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p2_fall_"
  Transient (
    InitialTime=3.03e-07 FinalTime=3.04e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p2_read_"
  Transient (
    InitialTime=3.04e-07 FinalTime=4.04e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.04e-07 4.04e-07) Intervals=20) ) }

  NewCurrentPrefix="c1_p3_rise_"
  Transient (
    InitialTime=4.04e-07 FinalTime=4.05e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p3_write_"
  Transient (
    InitialTime=4.05e-07 FinalTime=5.05e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.05e-07 5.05e-07) Intervals=10) ) }
  NewCurrentPrefix="c1_p3_fall_"
  Transient (
    InitialTime=5.05e-07 FinalTime=5.06e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_p3_read_"
  Transient (
    InitialTime=5.06e-07 FinalTime=6.06e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.06e-07 6.06e-07) Intervals=20) ) }

  *--- CYCLE 1 RESET (rise / 1 µs hold / fall) ---
  NewCurrentPrefix="c1_reset_rise_"
  Transient (
    InitialTime=6.06e-07 FinalTime=6.16e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_reset_hold_"
  Transient (
    InitialTime=6.16e-07 FinalTime=1.616e-06
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.16e-07 1.616e-06) Intervals=40) ) }
  NewCurrentPrefix="c1_reset_fall_"
  Transient (
    InitialTime=1.616e-06 FinalTime=1.626e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_settle_"
  Transient (
    InitialTime=1.626e-06 FinalTime=1.1626e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.626e-06 1.1626e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 2 (cycle base time = 1.1626e-05)
  *====================================================================
  NewCurrentPrefix="c2_p1_rise_"
  Transient (
    InitialTime=1.1626e-05 FinalTime=1.1627e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_write_"
  Transient (
    InitialTime=1.1627e-05 FinalTime=1.1727e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1627e-05 1.1727e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p1_fall_"
  Transient (
    InitialTime=1.1727e-05 FinalTime=1.1728e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_read_"
  Transient (
    InitialTime=1.1728e-05 FinalTime=1.1828e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1728e-05 1.1828e-05) Intervals=20) ) }

  NewCurrentPrefix="c2_p2_rise_"
  Transient (
    InitialTime=1.1828e-05 FinalTime=1.1829e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_write_"
  Transient (
    InitialTime=1.1829e-05 FinalTime=1.1929e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1829e-05 1.1929e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p2_fall_"
  Transient (
    InitialTime=1.1929e-05 FinalTime=1.1930e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_read_"
  Transient (
    InitialTime=1.1930e-05 FinalTime=1.2030e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1930e-05 1.2030e-05) Intervals=20) ) }

  NewCurrentPrefix="c2_p3_rise_"
  Transient (
    InitialTime=1.2030e-05 FinalTime=1.2031e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_write_"
  Transient (
    InitialTime=1.2031e-05 FinalTime=1.2131e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2031e-05 1.2131e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p3_fall_"
  Transient (
    InitialTime=1.2131e-05 FinalTime=1.2132e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_read_"
  Transient (
    InitialTime=1.2132e-05 FinalTime=1.2232e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2132e-05 1.2232e-05) Intervals=20) ) }

  NewCurrentPrefix="c2_reset_rise_"
  Transient (
    InitialTime=1.2232e-05 FinalTime=1.2242e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_reset_hold_"
  Transient (
    InitialTime=1.2242e-05 FinalTime=1.3242e-05
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2242e-05 1.3242e-05) Intervals=40) ) }
  NewCurrentPrefix="c2_reset_fall_"
  Transient (
    InitialTime=1.3242e-05 FinalTime=1.3252e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_settle_"
  Transient (
    InitialTime=1.3252e-05 FinalTime=2.3252e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3252e-05 2.3252e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 3 (cycle base time = 2.3252e-05)
  *====================================================================
  NewCurrentPrefix="c3_p1_rise_"
  Transient (
    InitialTime=2.3252e-05 FinalTime=2.3253e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_write_"
  Transient (
    InitialTime=2.3253e-05 FinalTime=2.3353e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3253e-05 2.3353e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p1_fall_"
  Transient (
    InitialTime=2.3353e-05 FinalTime=2.3354e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_read_"
  Transient (
    InitialTime=2.3354e-05 FinalTime=2.3454e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3354e-05 2.3454e-05) Intervals=20) ) }

  NewCurrentPrefix="c3_p2_rise_"
  Transient (
    InitialTime=2.3454e-05 FinalTime=2.3455e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_write_"
  Transient (
    InitialTime=2.3455e-05 FinalTime=2.3555e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3455e-05 2.3555e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p2_fall_"
  Transient (
    InitialTime=2.3555e-05 FinalTime=2.3556e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_read_"
  Transient (
    InitialTime=2.3556e-05 FinalTime=2.3656e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3556e-05 2.3656e-05) Intervals=20) ) }

  NewCurrentPrefix="c3_p3_rise_"
  Transient (
    InitialTime=2.3656e-05 FinalTime=2.3657e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_write_"
  Transient (
    InitialTime=2.3657e-05 FinalTime=2.3757e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3657e-05 2.3757e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p3_fall_"
  Transient (
    InitialTime=2.3757e-05 FinalTime=2.3758e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_read_"
  Transient (
    InitialTime=2.3758e-05 FinalTime=2.3858e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3758e-05 2.3858e-05) Intervals=20) ) }

  NewCurrentPrefix="c3_reset_rise_"
  Transient (
    InitialTime=2.3858e-05 FinalTime=2.3868e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_reset_hold_"
  Transient (
    InitialTime=2.3868e-05 FinalTime=2.4868e-05
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3868e-05 2.4868e-05) Intervals=40) ) }
  NewCurrentPrefix="c3_reset_fall_"
  Transient (
    InitialTime=2.4868e-05 FinalTime=2.4878e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_settle_"
  Transient (
    InitialTime=2.4878e-05 FinalTime=3.4878e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.4878e-05 3.4878e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 4 (cycle base time = 3.4878e-05)
  *====================================================================
  NewCurrentPrefix="c4_p1_rise_"
  Transient (
    InitialTime=3.4878e-05 FinalTime=3.4879e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p1_write_"
  Transient (
    InitialTime=3.4879e-05 FinalTime=3.4979e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.4879e-05 3.4979e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p1_fall_"
  Transient (
    InitialTime=3.4979e-05 FinalTime=3.4980e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p1_read_"
  Transient (
    InitialTime=3.4980e-05 FinalTime=3.5080e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.4980e-05 3.5080e-05) Intervals=20) ) }

  NewCurrentPrefix="c4_p2_rise_"
  Transient (
    InitialTime=3.5080e-05 FinalTime=3.5081e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_write_"
  Transient (
    InitialTime=3.5081e-05 FinalTime=3.5181e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.5081e-05 3.5181e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p2_fall_"
  Transient (
    InitialTime=3.5181e-05 FinalTime=3.5182e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p2_read_"
  Transient (
    InitialTime=3.5182e-05 FinalTime=3.5282e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.5182e-05 3.5282e-05) Intervals=20) ) }

  NewCurrentPrefix="c4_p3_rise_"
  Transient (
    InitialTime=3.5282e-05 FinalTime=3.5283e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_write_"
  Transient (
    InitialTime=3.5283e-05 FinalTime=3.5383e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.5283e-05 3.5383e-05) Intervals=10) ) }
  NewCurrentPrefix="c4_p3_fall_"
  Transient (
    InitialTime=3.5383e-05 FinalTime=3.5384e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_p3_read_"
  Transient (
    InitialTime=3.5384e-05 FinalTime=3.5484e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.5384e-05 3.5484e-05) Intervals=20) ) }

  NewCurrentPrefix="c4_reset_rise_"
  Transient (
    InitialTime=3.5484e-05 FinalTime=3.5494e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_reset_hold_"
  Transient (
    InitialTime=3.5494e-05 FinalTime=3.6494e-05
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.5494e-05 3.6494e-05) Intervals=40) ) }
  NewCurrentPrefix="c4_reset_fall_"
  Transient (
    InitialTime=3.6494e-05 FinalTime=3.6504e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c4_settle_"
  Transient (
    InitialTime=3.6504e-05 FinalTime=4.6504e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.6504e-05 4.6504e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 5 (cycle base time = 4.6504e-05)
  *====================================================================
  NewCurrentPrefix="c5_p1_rise_"
  Transient (
    InitialTime=4.6504e-05 FinalTime=4.6505e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p1_write_"
  Transient (
    InitialTime=4.6505e-05 FinalTime=4.6605e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.6505e-05 4.6605e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p1_fall_"
  Transient (
    InitialTime=4.6605e-05 FinalTime=4.6606e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p1_read_"
  Transient (
    InitialTime=4.6606e-05 FinalTime=4.6706e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.6606e-05 4.6706e-05) Intervals=20) ) }

  NewCurrentPrefix="c5_p2_rise_"
  Transient (
    InitialTime=4.6706e-05 FinalTime=4.6707e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_write_"
  Transient (
    InitialTime=4.6707e-05 FinalTime=4.6807e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.6707e-05 4.6807e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p2_fall_"
  Transient (
    InitialTime=4.6807e-05 FinalTime=4.6808e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p2_read_"
  Transient (
    InitialTime=4.6808e-05 FinalTime=4.6908e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.6808e-05 4.6908e-05) Intervals=20) ) }

  NewCurrentPrefix="c5_p3_rise_"
  Transient (
    InitialTime=4.6908e-05 FinalTime=4.6909e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_write_"
  Transient (
    InitialTime=4.6909e-05 FinalTime=4.7009e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.6909e-05 4.7009e-05) Intervals=10) ) }
  NewCurrentPrefix="c5_p3_fall_"
  Transient (
    InitialTime=4.7009e-05 FinalTime=4.7010e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_p3_read_"
  Transient (
    InitialTime=4.7010e-05 FinalTime=4.7110e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.7010e-05 4.7110e-05) Intervals=20) ) }

  NewCurrentPrefix="c5_reset_rise_"
  Transient (
    InitialTime=4.7110e-05 FinalTime=4.7120e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_reset_hold_"
  Transient (
    InitialTime=4.7120e-05 FinalTime=4.8120e-05
    InitialStep=1e-11 MaxStep=2e-8 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.7120e-05 4.8120e-05) Intervals=40) ) }
  NewCurrentPrefix="c5_reset_fall_"
  Transient (
    InitialTime=4.8120e-05 FinalTime=4.8130e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c5_settle_"
  Transient (
    InitialTime=4.8130e-05 FinalTime=5.8130e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.8130e-05 5.8130e-05) Intervals=40) ) }

}

*===================================================================
*== SWB SETUP (set in SWB project, not in this file):
*==   Parameter:  V_reset
*==   Sweep (L4): -1.0  -1.5  -2.0  -2.5    V
*==
*== POST-PROCESSING (`Simulations/analyze_phase1d_h3.py`):
*==   1. For each node extract ID at end of c{N}_settle_ for N ∈ 1..5
*==      (these are the steady-state baselines the next train sees).
*==   2. Steady-state drift fit across c3 → c5:
*==        drift_per_cycle = (ID_settle_c5 − ID_settle_c3) / ID_settle_c3 / 2
*==      M1 PASS: |drift| ≤ 1.0 %/cycle.
*==      Cycle 1 = wake-up (FE starts at virgin); cycle 2 = transition.
*==      Both excluded from the fit.
*==   3. Within-cycle fire_ratio = ID_cN_p3 / ID_settle_cN-1 for
*==      N ∈ 3..5.  Must be ≥ 1.5 (fire direction must be correct,
*==      and magnitude must clear M2).
*==   4. Baseline-restore check: ID_settle_c5 within ±3x of virgin
*==      ID_baseline (proves reset is RESTORING, not over-flipping).
*==   5. Pick the V_reset that passes (2)+(3)+(4) and minimizes
*==      |drift|.  This is V_reset_opt for H4.
*===================================================================
