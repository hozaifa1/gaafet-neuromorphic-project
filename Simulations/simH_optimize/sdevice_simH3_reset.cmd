*===================================================================
*== PHASE 1D — SIM H3 v2: RESET PROTOCOL OPTIMIZATION (kills drift)
*==
*== v1 INVALIDATED (2026-05-11): same Device{Electrode}+System/Vsource_pset/pwl
*==   gate-drive bug as H1 v1 / H2 v1.  Pulses never reach the gate.
*==
*== v2 fix (2026-05-11): top-level Electrode + Goal-driven Transient
*==   for every fire pulse and every reset pulse (simC v6 / H1 v3
*==   pattern).  Read level V_GS = -0.5 V (sub-V_t) — same as H1 v3,
*==   so fire_ratio and drift are measured on the SS-exponential
*==   region of ID where ΔV_t is most visible.
*==
*== V_pgm = 2.0 V hardcoded (= V_pgm_opt from H1 v3): fire_ratio 4.79x,
*==   ΔV_t_eff = -68 mV, |E|/F_c = 0.41 (sub-coercive), fully monotonic
*==   9-pulse staircase.  This is the publication operating point.
*==
*== Goal: drop cycle-to-cycle ID drift below 1.0 %/cycle (M1).
*==
*== Sweep — V_reset only (L3 reduced) in this single cmd file:
*==   @V_reset@ ∈ {-3.0, -5.0, -7.0} V
*==
*== Reset pulse cadence (hardcoded centerpoint):
*==   t_reset = 10 µs  (FE saturation hold)
*==   t_settle = 10 µs (post-reset relaxation window)
*==
*== To expand to L9 (V_reset × t_reset × t_settle) make 9 copies of
*==   this cmd file with the four absolute time anchors (cycle starts,
*==   reset rise/hold/fall/settle endpoints) re-derived for each
*==   (t_reset, t_settle) pair.  The recomputation is mechanical —
*==   each cycle's length = 606 ns (3 fires) + 10 ns (reset rise)
*==   + t_reset + 10 ns (reset fall) + t_settle.
*==
*== Method: 3 cycles of (3 fire pulses → reset → settle).  Measure
*==   ID at the end of each cycle's first read.  drift_per_cycle
*==   = (ID_pre_c3 − ID_pre_c1) / ID_pre_c1 / 2.  Pass: drift ≤ 1.0 %.
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

*-------------------------------------------------------------------
* Time anchors (in seconds; centerpoint t_reset = t_settle = 10 µs):
*   t = 0.0       cycle 1 begins (fire pulse 1 rise)
*   t = 6.06e-7   end of cycle 1 fire pulses; reset rise begins
*   t = 6.16e-7   reset hold begins (rise = 10 ns)
*   t = 1.0616e-5 reset hold ends (10 µs hold)
*   t = 1.0626e-5 reset fall ends; settle begins
*   t = 2.0626e-5 cycle 1 ends; cycle 2 fire pulse 1 begins
*   t = 4.1252e-5 cycle 2 ends; cycle 3 fire pulse 1 begins
*   t = 6.1878e-5 cycle 3 ends
* Per-cycle = 606 ns fires + 10+10000+10 ns reset + 10000 ns settle
*           = 20626 ns = 20.626 µs.
*-------------------------------------------------------------------

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
  *== CYCLE 1: 3 fire pulses @ V_pgm=2.0 V, then reset @ @V_reset@
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

  *--- CYCLE 1 RESET (rise / 10 µs hold / fall) ---
  NewCurrentPrefix="c1_reset_rise_"
  Transient (
    InitialTime=6.06e-07 FinalTime=6.16e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_reset_hold_"
  Transient (
    InitialTime=6.16e-07 FinalTime=1.0616e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.16e-07 1.0616e-05) Intervals=40) ) }
  NewCurrentPrefix="c1_reset_fall_"
  Transient (
    InitialTime=1.0616e-05 FinalTime=1.0626e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c1_settle_"
  Transient (
    InitialTime=1.0626e-05 FinalTime=2.0626e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0626e-05 2.0626e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 2 (cycle base time = 2.0626e-05)
  *====================================================================
  NewCurrentPrefix="c2_p1_rise_"
  Transient (
    InitialTime=2.0626e-05 FinalTime=2.0627e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_write_"
  Transient (
    InitialTime=2.0627e-05 FinalTime=2.0727e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0627e-05 2.0727e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p1_fall_"
  Transient (
    InitialTime=2.0727e-05 FinalTime=2.0728e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p1_read_"
  Transient (
    InitialTime=2.0728e-05 FinalTime=2.0828e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0728e-05 2.0828e-05) Intervals=20) ) }

  NewCurrentPrefix="c2_p2_rise_"
  Transient (
    InitialTime=2.0828e-05 FinalTime=2.0829e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_write_"
  Transient (
    InitialTime=2.0829e-05 FinalTime=2.0929e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0829e-05 2.0929e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p2_fall_"
  Transient (
    InitialTime=2.0929e-05 FinalTime=2.0930e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p2_read_"
  Transient (
    InitialTime=2.0930e-05 FinalTime=2.1030e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0930e-05 2.1030e-05) Intervals=20) ) }

  NewCurrentPrefix="c2_p3_rise_"
  Transient (
    InitialTime=2.1030e-05 FinalTime=2.1031e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_write_"
  Transient (
    InitialTime=2.1031e-05 FinalTime=2.1131e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.1031e-05 2.1131e-05) Intervals=10) ) }
  NewCurrentPrefix="c2_p3_fall_"
  Transient (
    InitialTime=2.1131e-05 FinalTime=2.1132e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_p3_read_"
  Transient (
    InitialTime=2.1132e-05 FinalTime=2.1232e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.1132e-05 2.1232e-05) Intervals=20) ) }

  NewCurrentPrefix="c2_reset_rise_"
  Transient (
    InitialTime=2.1232e-05 FinalTime=2.1242e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_reset_hold_"
  Transient (
    InitialTime=2.1242e-05 FinalTime=3.1242e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.1242e-05 3.1242e-05) Intervals=40) ) }
  NewCurrentPrefix="c2_reset_fall_"
  Transient (
    InitialTime=3.1242e-05 FinalTime=3.1252e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c2_settle_"
  Transient (
    InitialTime=3.1252e-05 FinalTime=4.1252e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.1252e-05 4.1252e-05) Intervals=40) ) }

  *====================================================================
  *== CYCLE 3 (cycle base time = 4.1252e-05)
  *====================================================================
  NewCurrentPrefix="c3_p1_rise_"
  Transient (
    InitialTime=4.1252e-05 FinalTime=4.1253e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_write_"
  Transient (
    InitialTime=4.1253e-05 FinalTime=4.1353e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1253e-05 4.1353e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p1_fall_"
  Transient (
    InitialTime=4.1353e-05 FinalTime=4.1354e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p1_read_"
  Transient (
    InitialTime=4.1354e-05 FinalTime=4.1454e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1354e-05 4.1454e-05) Intervals=20) ) }

  NewCurrentPrefix="c3_p2_rise_"
  Transient (
    InitialTime=4.1454e-05 FinalTime=4.1455e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_write_"
  Transient (
    InitialTime=4.1455e-05 FinalTime=4.1555e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1455e-05 4.1555e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p2_fall_"
  Transient (
    InitialTime=4.1555e-05 FinalTime=4.1556e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p2_read_"
  Transient (
    InitialTime=4.1556e-05 FinalTime=4.1656e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1556e-05 4.1656e-05) Intervals=20) ) }

  NewCurrentPrefix="c3_p3_rise_"
  Transient (
    InitialTime=4.1656e-05 FinalTime=4.1657e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= 2.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_write_"
  Transient (
    InitialTime=4.1657e-05 FinalTime=4.1757e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1657e-05 4.1757e-05) Intervals=10) ) }
  NewCurrentPrefix="c3_p3_fall_"
  Transient (
    InitialTime=4.1757e-05 FinalTime=4.1758e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_p3_read_"
  Transient (
    InitialTime=4.1758e-05 FinalTime=4.1858e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1758e-05 4.1858e-05) Intervals=20) ) }

  NewCurrentPrefix="c3_reset_rise_"
  Transient (
    InitialTime=4.1858e-05 FinalTime=4.1868e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_reset@ }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_reset_hold_"
  Transient (
    InitialTime=4.1868e-05 FinalTime=5.1868e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1868e-05 5.1868e-05) Intervals=40) ) }
  NewCurrentPrefix="c3_reset_fall_"
  Transient (
    InitialTime=5.1868e-05 FinalTime=5.1878e-05
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }
  NewCurrentPrefix="c3_settle_"
  Transient (
    InitialTime=5.1878e-05 FinalTime=6.1878e-05
    InitialStep=1e-11 MaxStep=1e-7 MinStep=1e-15
    Increment=1.4
  ) { Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.1878e-05 6.1878e-05) Intervals=40) ) }

}

*===================================================================
*== SWB SETUP:
*==   Parameter:  @V_reset@
*==   Sweep:      -3.0  -5.0  -7.0    V
*==
*== POST-PROCESSING:
*==   1. For each node: extract ID at end of c1_p1_read_, c2_p1_read_,
*==      c3_p1_read_.  These are ID_pre_c1, ID_pre_c2, ID_pre_c3.
*==   2. drift_per_cycle = (ID_pre_c3 − ID_pre_c1) / ID_pre_c1 / 2.
*==      M1 pass: |drift| ≤ 1.0 %/cycle.
*==   3. Also extract fire_ratio_cN = ID_cN_p3_read_end / ID_baseline_pre.
*==      Should be approximately constant across cycles (reset working).
*==   4. Pick the V_reset that minimizes |drift| while preserving
*==      fire_ratio.  This is V_reset_opt for H4.
*===================================================================
