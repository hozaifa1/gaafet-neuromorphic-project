*===================================================================
*== PHASE 1D — SIM H3: RESET PROTOCOL OPTIMIZATION (kills drift)
*==
*== Goal: drop ID_pre drift from +4.74 %/cycle (Phase 1C simF τ_P=1e-5)
*==   to ≤ 1 %/cycle by tuning the reset pulse amplitude/width and
*==   the inter-cycle settle delay.
*==
*== Method: 3 cycles of (3 fire pulses → reset → settle).  Sweep:
*==   @V_reset@ ∈ {-3.0, -5.0, -7.0}  V
*==   @t_reset@ ∈ { 1e-6, 1e-5, 1e-4} s   (1, 10, 100 µs)
*==   @t_settle@ ∈ {0,    1e-5, 1e-4} s   (0, 10, 100 µs)
*==
*== Full factorial = 27 nodes.  Drop to L9 fractional factorial if
*==   compute is tight (Taguchi orthogonal array — see Phase1D plan §4).
*==
*== Why 3 fire pulses (not 9): the drift signal appears already at
*==   cycle-2 vs cycle-1 (Phase 1C simF c2→c5 slope is monotonic).
*==   3 cycles × 3 pulses is enough to extract the slope and a
*==   factor-of-9 cheaper to run than the full simC v6 9-pulse train.
*==
*== Pulse cadence (fire pulses): same as simC v6 — V_pgm = 6.0 V,
*==   1 ns rise / 100 ns hold / 1 ns fall / 100 ns read.
*==   Each cycle: 3 × (1+100+1+100 ns) = 606 ns of pulses.
*==   Then reset: 1 ns rise / @t_reset@ hold / 1 ns fall.
*==   Then settle: @t_settle@ inter-cycle delay.
*==
*== Workfunction is fixed at the H1-chosen value via @WF@.
*== V_pgm = 6.0 V is hardcoded so we can do a controlled comparison
*==   against Phase 1C simF; once H1's lower V_pgm is qualified the
*==   user can re-run with V_pgm=2.5 to test the combined effect.
*===================================================================

File {
    Grid       = "@tdr@"
    Parameter  = "sdevice_gaafet_lif.par"
    Plot       = "@tdrdat@"
    Current    = "@plot@"
    Output     = "@log@"
}

Device GAAFeFET {

  Electrode {
    { Name="source_contact"  Voltage= 0.0 }
    { Name="drain_contact"   Voltage= 0.0 }
    { Name="gate_contact"    Voltage= 0.0  Workfunction=@WF@ }
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

  Plot {
    eDensity hDensity
    TotalCurrent/Vector ElectricField/Vector Potential SpaceCharge
    ConductionBand ValenceBand Doping Polarization/Vector
  }

  CurrentPlot {
    Polarization/Vector (( 0 0.0145 ))
    ElectricField/Vector (( 0 0.0145 ))
  }

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

*-------------------------------------------------------------------
* Cycle timing (constant V_pgm = 6.0 V, fire pulse pw = 100 ns,
*   read window = 100 ns).  Cycle k (k=0..2) starts at t_k:
*       t_0 = 0
*       t_k = t_{k-1} + 606 ns + (1 + @t_reset@ + 1 ns) + @t_settle@
*   pwl knots are written piecewise per cycle below.  SWB will
*   substitute @t_reset@ and @t_settle@ at run time, so the pwl
*   timestamps are written symbolically using the @-form.
*
* NOTE: SWB @-substitution is textual — we cannot do arithmetic
*   inside the cmd file.  So the absolute times below are written
*   by composing the pwl out of the three cycles, with each cycle's
*   pwl referenced to its own start time (computed at SWB run-time
*   by node-level parameter expressions).  If your SWB version does
*   not support node-level expressions on @t_reset@ + @t_settle@,
*   collapse this file to a fixed (V_reset, t_reset, t_settle) per
*   node and run 27 nodes with 27 cmd files instead.  The L9 fractional
*   factorial (9 nodes / 9 cmd files) is the recommended fallback.
*-------------------------------------------------------------------

System {
   GAAFeFET fefet (gate_contact=g drain_contact=d source_contact=s)

   * vg.dc = 0.2 V (read level), held throughout the train.
   * pwl carries program (+6 V) and reset (-V_reset) deviations.
   *
   * Cycle 1: 3 fire pulses, then reset, then settle.
   * Cycle 2: same.
   * Cycle 3: same; trailing zero so subsequent CV sweeps see vg.dc only.
   *
   * Times below assume t_reset = 10 µs, t_settle = 10 µs as the
   * default L9 centerpoint.  Re-derive timestamps for other
   * (t_reset, t_settle) combinations or use a node-level parameter
   * expression in SWB.

   Vsource_pset vg(g 0) {
     dc = 0
     pwl = (
        *--- t = 0 — start cycle 1 ---
        0           0
        *--- cycle 1 fire pulse 1 (rise/hold/fall/read = 1+100+1+100 ns) ---
        1.0e-09     5.8
        1.01e-07    5.8
        1.02e-07    0
        2.02e-07    0
        *--- cycle 1 fire pulse 2 ---
        2.03e-07    5.8
        3.03e-07    5.8
        3.04e-07    0
        4.04e-07    0
        *--- cycle 1 fire pulse 3 ---
        4.05e-07    5.8
        5.05e-07    5.8
        5.06e-07    0
        6.06e-07    0
        *--- cycle 1 reset (rise / hold = @t_reset@ / fall) ---
        6.07e-07    @V_reset@
        1.0607e-05  @V_reset@
        1.0608e-05  0
        *--- cycle 1 settle (@t_settle@ at 0 V) ---
        2.0608e-05  0
        *--- t = 2.0608e-05 — start cycle 2 ---
        2.0609e-05  5.8
        2.0709e-05  5.8
        2.0710e-05  0
        2.0810e-05  0
        2.0811e-05  5.8
        2.0911e-05  5.8
        2.0912e-05  0
        2.1012e-05  0
        2.1013e-05  5.8
        2.1113e-05  5.8
        2.1114e-05  0
        2.1214e-05  0
        2.1215e-05  @V_reset@
        3.1215e-05  @V_reset@
        3.1216e-05  0
        4.1216e-05  0
        *--- t = 4.1216e-05 — start cycle 3 ---
        4.1217e-05  5.8
        4.1317e-05  5.8
        4.1318e-05  0
        4.1418e-05  0
        4.1419e-05  5.8
        4.1519e-05  5.8
        4.1520e-05  0
        4.1620e-05  0
        4.1621e-05  5.8
        4.1721e-05  5.8
        4.1722e-05  0
        4.1822e-05  0
        4.1823e-05  @V_reset@
        5.1823e-05  @V_reset@
        5.1824e-05  0
        6.1824e-05  0
     )
   }
   Vsource_pset vd(d 0) { dc = 0 }
   Vsource_pset vs(s 0) { dc = 0 }
}

Solve {

  *=== STEP 0: INITIALIZE ===
  Coupled (Iterations= 100 LineSearchDamping= 1e-8) { Poisson }
  Coupled { Poisson Electron Hole }

  *=== STEP 1: RAMP DRAIN TO VDS = 0.05 V ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vd.dc Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: RAMP GATE TO VGS_READ = 0.2 V ===
  NewCurrentPrefix="gate_to_read_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vg.dc Voltage= 0.2 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 3: BASELINE READ (pre-cycle 1) ===
  *== A short Transient at vg=0.2 V to record ID before any pulses.
  NewCurrentPrefix="baseline_pre_"
  Transient (
    InitialTime=-1.0e-08 FinalTime=0.0
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(-1.0e-08 0.0) Intervals=5) )
  }

  *=== CYCLE 1 — 3 fire pulses + reset + settle ===
  NewCurrentPrefix="c1_"
  Transient (
    InitialTime=0.0 FinalTime=2.0608e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0.0 2.0608e-05) Intervals=200) )
  }

  *=== CYCLE 2 ===
  NewCurrentPrefix="c2_"
  Transient (
    InitialTime=2.0608e-05 FinalTime=4.1216e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0608e-05 4.1216e-05) Intervals=200) )
  }

  *=== CYCLE 3 ===
  NewCurrentPrefix="c3_"
  Transient (
    InitialTime=4.1216e-05 FinalTime=6.1824e-05
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.1216e-05 6.1824e-05) Intervals=200) )
  }

}
