*===================================================================
*== PHASE 1D — SIM H1: V_pgm OPERATING-POINT SWEEP
*==
*== Goal: find the lowest V_pgm at which 9 sub-coercive pulses still
*==   produce a fire (ID_post / ID_pre >= 1.5x) AND ΔVth-per-pulse
*==   is monotonic.  This eliminates the +4.74 %/cycle drift driver
*==   identified in Phase 1C simF, which was V_pgm = 6 V being 3.1×
*==   supercoercive (V_c,gate = F_c · t_FE · (1 + C_IL/C_FE) ≈ 1.91 V
*==   on the current par; lower if H2 lowers F_c).
*==
*== This is the canonical sub-coercive operating mode used by:
*==   - Frontiers 2020 (Jerry et al. 28-nm FeFET LIF)
*==   - AFeFET Nature Comms 2022 (Cao et al.)
*==   - Lizzit 2023 (HSO 10 nm Si-channel FeFET)
*==
*== Replaces v1 simH1 workfunction sweep, which was invalidated:
*==   in an MFIS with P_r = 16 µC/cm², polarization charge dominates
*==   V_th by 15× over the WF sweep range, so WF cannot move V_th
*==   appreciably (user-confirmed empirically in calibration logs).
*==
*== Method: SWB-sweep @V_pulse@ ∈ {0.8, 1.3, 1.8, 2.3, 5.8} V where
*==   V_pulse = V_pgm − 0.2 (the dc read level).  Mapping:
*==     @V_pulse@ = 0.8  →  V_pgm = 1.0 V  (sub-coercive, 0.5× V_c,gate)
*==     @V_pulse@ = 1.3  →  V_pgm = 1.5 V  (sub-coercive, 0.8× V_c,gate)
*==     @V_pulse@ = 1.8  →  V_pgm = 2.0 V  (just-coercive, 1.0× V_c,gate)
*==     @V_pulse@ = 2.3  →  V_pgm = 2.5 V  (slightly super, 1.3× V_c,gate)
*==     @V_pulse@ = 5.8  →  V_pgm = 6.0 V  (Phase 1C reference, 3.1×)
*==
*== Pulse train structure: same 9-pulse cadence as simC v6 (and
*==   verified by simG capacitance).  Each pulse: 1 ns rise + 100 ns
*==   hold + 1 ns fall + 100 ns read at vg.dc = 0.2 V.  Total train
*==   duration: 9 × 202 ns ≈ 1.82 µs.  No reset in this file —
*==   reset/multi-cycle drift comes in Stage H3.
*==
*== After H1 picks a winning V_pulse, Stage H3 re-runs the same
*==   pulse train pattern with reset cycles bolted on, sweeping
*==   reset parameters.
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
* End of Device

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

System {
   GAAFeFET fefet (gate_contact=g drain_contact=d source_contact=s)

   * vg.dc = 0.2 V (read level), held throughout the pulse train.
   * pwl carries the 9-pulse train deviation.  pulse height =
   * @V_pulse@ on top of dc=0.2V → V_pgm at gate = @V_pulse@ + 0.2 V.
   * Pulse cadence: 1 ns rise, 100 ns hold, 1 ns fall, 100 ns read.
   * Same timing as simC v6 / simG.

   Vsource_pset vg(g 0) {
     dc = 0
     pwl = (
        0           0
        *--- pulse 1 ---
        1.0e-09     @V_pulse@
        1.01e-07    @V_pulse@
        1.02e-07    0
        2.02e-07    0
        *--- pulse 2 ---
        2.03e-07    @V_pulse@
        3.03e-07    @V_pulse@
        3.04e-07    0
        4.04e-07    0
        *--- pulse 3 ---
        4.05e-07    @V_pulse@
        5.05e-07    @V_pulse@
        5.06e-07    0
        6.06e-07    0
        *--- pulse 4 ---
        6.07e-07    @V_pulse@
        7.07e-07    @V_pulse@
        7.08e-07    0
        8.08e-07    0
        *--- pulse 5 ---
        8.09e-07    @V_pulse@
        9.09e-07    @V_pulse@
        9.10e-07    0
        1.010e-06   0
        *--- pulse 6 ---
        1.011e-06   @V_pulse@
        1.111e-06   @V_pulse@
        1.112e-06   0
        1.212e-06   0
        *--- pulse 7 ---
        1.213e-06   @V_pulse@
        1.313e-06   @V_pulse@
        1.314e-06   0
        1.414e-06   0
        *--- pulse 8 ---
        1.415e-06   @V_pulse@
        1.515e-06   @V_pulse@
        1.516e-06   0
        1.616e-06   0
        *--- pulse 9 ---
        1.617e-06   @V_pulse@
        1.717e-06   @V_pulse@
        1.718e-06   0
        1.818e-06   0
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

  *=== STEP 3: BASELINE READ (pre-train ID at vg=0.2V) ===
  NewCurrentPrefix="baseline_pre_"
  Transient (
    InitialTime=-1.0e-08 FinalTime=0.0
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(-1.0e-08 0.0) Intervals=10) )
  }

  *=== PULSE TRAIN: 9 pulses, each with rise / hold / fall / read ===
  *== One Transient block per phase per pulse, following simC v6
  *== syntax exactly.  No Goal in any Transient (per debug log §2).

  *--- PULSE 1 ---
  NewCurrentPrefix="p01_rise_"
  Transient (
    InitialTime=0.0 FinalTime=1.0e-09
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0.0 1.0e-09) Intervals=5) )
  }
  NewCurrentPrefix="p01_write_"
  Transient (
    InitialTime=1.0e-09 FinalTime=1.01e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0e-09 1.01e-07) Intervals=10) )
  }
  NewCurrentPrefix="p01_fall_"
  Transient (
    InitialTime=1.01e-07 FinalTime=1.02e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.01e-07 1.02e-07) Intervals=5) )
  }
  NewCurrentPrefix="p01_read_"
  Transient (
    InitialTime=1.02e-07 FinalTime=2.02e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.02e-07 2.02e-07) Intervals=20) )
  }

  *--- PULSE 2 ---
  NewCurrentPrefix="p02_rise_"
  Transient (
    InitialTime=2.02e-07 FinalTime=2.03e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.02e-07 2.03e-07) Intervals=5) )
  }
  NewCurrentPrefix="p02_write_"
  Transient (
    InitialTime=2.03e-07 FinalTime=3.03e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.03e-07 3.03e-07) Intervals=10) )
  }
  NewCurrentPrefix="p02_fall_"
  Transient (
    InitialTime=3.03e-07 FinalTime=3.04e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.03e-07 3.04e-07) Intervals=5) )
  }
  NewCurrentPrefix="p02_read_"
  Transient (
    InitialTime=3.04e-07 FinalTime=4.04e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.04e-07 4.04e-07) Intervals=20) )
  }

  *--- PULSE 3 ---
  NewCurrentPrefix="p03_rise_"
  Transient (
    InitialTime=4.04e-07 FinalTime=4.05e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.04e-07 4.05e-07) Intervals=5) )
  }
  NewCurrentPrefix="p03_write_"
  Transient (
    InitialTime=4.05e-07 FinalTime=5.05e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.05e-07 5.05e-07) Intervals=10) )
  }
  NewCurrentPrefix="p03_fall_"
  Transient (
    InitialTime=5.05e-07 FinalTime=5.06e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.05e-07 5.06e-07) Intervals=5) )
  }
  NewCurrentPrefix="p03_read_"
  Transient (
    InitialTime=5.06e-07 FinalTime=6.06e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.06e-07 6.06e-07) Intervals=20) )
  }

  *--- PULSE 4 ---
  NewCurrentPrefix="p04_rise_"
  Transient (
    InitialTime=6.06e-07 FinalTime=6.07e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.06e-07 6.07e-07) Intervals=5) )
  }
  NewCurrentPrefix="p04_write_"
  Transient (
    InitialTime=6.07e-07 FinalTime=7.07e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.07e-07 7.07e-07) Intervals=10) )
  }
  NewCurrentPrefix="p04_fall_"
  Transient (
    InitialTime=7.07e-07 FinalTime=7.08e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.07e-07 7.08e-07) Intervals=5) )
  }
  NewCurrentPrefix="p04_read_"
  Transient (
    InitialTime=7.08e-07 FinalTime=8.08e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.08e-07 8.08e-07) Intervals=20) )
  }

  *--- PULSE 5 ---
  NewCurrentPrefix="p05_rise_"
  Transient (
    InitialTime=8.08e-07 FinalTime=8.09e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.08e-07 8.09e-07) Intervals=5) )
  }
  NewCurrentPrefix="p05_write_"
  Transient (
    InitialTime=8.09e-07 FinalTime=9.09e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.09e-07 9.09e-07) Intervals=10) )
  }
  NewCurrentPrefix="p05_fall_"
  Transient (
    InitialTime=9.09e-07 FinalTime=9.10e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.09e-07 9.10e-07) Intervals=5) )
  }
  NewCurrentPrefix="p05_read_"
  Transient (
    InitialTime=9.10e-07 FinalTime=1.010e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.10e-07 1.010e-06) Intervals=20) )
  }

  *--- PULSE 6 ---
  NewCurrentPrefix="p06_rise_"
  Transient (
    InitialTime=1.010e-06 FinalTime=1.011e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.010e-06 1.011e-06) Intervals=5) )
  }
  NewCurrentPrefix="p06_write_"
  Transient (
    InitialTime=1.011e-06 FinalTime=1.111e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.011e-06 1.111e-06) Intervals=10) )
  }
  NewCurrentPrefix="p06_fall_"
  Transient (
    InitialTime=1.111e-06 FinalTime=1.112e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.111e-06 1.112e-06) Intervals=5) )
  }
  NewCurrentPrefix="p06_read_"
  Transient (
    InitialTime=1.112e-06 FinalTime=1.212e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.112e-06 1.212e-06) Intervals=20) )
  }

  *--- PULSE 7 ---
  NewCurrentPrefix="p07_rise_"
  Transient (
    InitialTime=1.212e-06 FinalTime=1.213e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.212e-06 1.213e-06) Intervals=5) )
  }
  NewCurrentPrefix="p07_write_"
  Transient (
    InitialTime=1.213e-06 FinalTime=1.313e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.213e-06 1.313e-06) Intervals=10) )
  }
  NewCurrentPrefix="p07_fall_"
  Transient (
    InitialTime=1.313e-06 FinalTime=1.314e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.313e-06 1.314e-06) Intervals=5) )
  }
  NewCurrentPrefix="p07_read_"
  Transient (
    InitialTime=1.314e-06 FinalTime=1.414e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.314e-06 1.414e-06) Intervals=20) )
  }

  *--- PULSE 8 ---
  NewCurrentPrefix="p08_rise_"
  Transient (
    InitialTime=1.414e-06 FinalTime=1.415e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.414e-06 1.415e-06) Intervals=5) )
  }
  NewCurrentPrefix="p08_write_"
  Transient (
    InitialTime=1.415e-06 FinalTime=1.515e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.415e-06 1.515e-06) Intervals=10) )
  }
  NewCurrentPrefix="p08_fall_"
  Transient (
    InitialTime=1.515e-06 FinalTime=1.516e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.515e-06 1.516e-06) Intervals=5) )
  }
  NewCurrentPrefix="p08_read_"
  Transient (
    InitialTime=1.516e-06 FinalTime=1.616e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.516e-06 1.616e-06) Intervals=20) )
  }

  *--- PULSE 9 ---
  NewCurrentPrefix="p09_rise_"
  Transient (
    InitialTime=1.616e-06 FinalTime=1.617e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.616e-06 1.617e-06) Intervals=5) )
  }
  NewCurrentPrefix="p09_write_"
  Transient (
    InitialTime=1.617e-06 FinalTime=1.717e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.617e-06 1.717e-06) Intervals=10) )
  }
  NewCurrentPrefix="p09_fall_"
  Transient (
    InitialTime=1.717e-06 FinalTime=1.718e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.717e-06 1.718e-06) Intervals=5) )
  }
  NewCurrentPrefix="p09_read_"
  Transient (
    InitialTime=1.718e-06 FinalTime=1.818e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.718e-06 1.818e-06) Intervals=20) )
  }

}

*===================================================================
*== POST-PROCESSING (Python, not in this file):
*==   1. For each @V_pulse@ node, extract per-pulse ID at end of
*==      each "p0N_read_" segment.  Plot ID(N) staircase.
*==   2. fire_ratio = ID_p09_read_end / ID_baseline_pre.  Pass if
*==      fire_ratio >= 1.5x (M2 target).
*==   3. ΔVth-per-pulse staircase: convert ΔID per pulse to ΔVth
*==      using the H0a-extracted I-V slope (gm at 0.2 V).  Pass if
*==      monotonic across all 9 pulses (no early plateau).
*==   4. Pick the LOWEST V_pgm node passing both criteria as the
*==      operating point for H2 / H3.
*==   5. If only V_pgm = 6 V passes, the multi-domain model from H0e
*==      is missing — loop back to H0e before continuing.
*===================================================================
