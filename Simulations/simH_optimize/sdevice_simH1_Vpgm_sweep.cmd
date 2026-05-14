*===================================================================
*== PHASE 1D — SIM H1 v3: V_pgm OPERATING-POINT SWEEP (Tier A)
*==
*== v1 INVALIDATED (2026-05-11) — gate-drive paradigm bug (see history below).
*== v2 RAN clean (2026-05-11) but read level V_GS = 0.2 V was in strong
*==   inversion (ID_base = 96 µA/µm) so the fire_ratio paradigm was
*==   blind to large ΔV_t.  Best fire_ratio = 1.32× at V_pgm = 6 V.
*==
*== v3 fix (Tier A): change read level from V_GS = 0.2 V (above-V_t,
*==   linear regime) → V_GS = -0.5 V (deep sub-V_t).  V_t_virgin ≈
*==   +0.16 V from H1 v2 linear-region reverse-calc, so V_GS = -0.5 V
*==   sits ~660 mV sub-V_t = ~6 decades below the µA inversion plateau
*==   on the H0a v5 SS = 100 mV/dec slope.  ID_base lands near or at
*==   the H0a v5 I_off floor (3 nA/µm).  Each fire pulse drives V_t
*==   negative; once V_t < -0.5 V the device climbs onto the inversion
*==   plateau → fire_ratio ≥ 1.5x readily.  This is the Frontiers
*==   2020 / Khanday 2024 LIF read paradigm.
*==
*== All 9 pulse fall-back Goals now ramp gate back to -0.5 V (was 0.2 V).
*==
*== ─── v1 → v2 history (kept for context) ───
*==   v1: Device{Electrode}+System{Vsource_pset pwl} → silent gate-drive
*==     failure (byte-identical .plt files across SWB sweep).
*==   v2: top-level Electrode + Goal-driven gate (simC v6 / H0a v5
*==     pattern).  Bug eliminated, but M2 paradigm-mismatched at the
*==     V_GS = 0.2 V read level.
*==   v3 = v2 + sub-V_t read level for Tier-A LIF demo.
*==
*== SWB sweep:  @V_pgm@  ∈ {1.0, 1.5, 2.0, 2.5, 6.0} V (unchanged).
*==
*== Pulse cadence (unchanged, simC v6): 1 ns rise / 100 ns hold /
*==   1 ns fall / 100 ns read at V_G = -0.5 V.  Train: 9 × 202 ns
*==   = 1.818 µs.  No reset — reset comes in Stage H3.
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

  *=== STEP 1: SET DRAIN BIAS (V_DS = 0.05 V) ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="drain_contact" Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: SET GATE READ BIAS (V_GS_read = -0.5 V, sub-V_t) ===
  *== v3 (2026-05-11) — Tier-A "LIF fires from OFF" demo:
  *==   v2 read at V_GS = 0.2 V was in strong inversion (ID_base = 96
  *==   µA/µm, above-V_t plateau) → fire_ratio capped at 1.32x because
  *==   ID lost exponential sensitivity to V_t.  V_GS = -0.5 V places
  *==   the device deep sub-V_t (V_t_virgin ≈ +0.16 V from H1 v2
  *==   linear-region reverse-calc) so the same Pol-induced ΔV_t now
  *==   lands in the SS-exponential region of ID.  After enough pulses
  *==   ΔV_t can push V_t below -0.5 V → device climbs onto inversion
  *==   plateau → fire_ratio >> 1.5.  H0a v5 I_off floor is 3 nA/µm;
  *==   ID_base at V_GS = -0.5 V is expected near that floor.
  NewCurrentPrefix="gate_to_read_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 3: BASELINE READ (100 ns at V_G = -0.5 V) ===
  NewCurrentPrefix="baseline_pre_"
  Transient (
    InitialTime=0 FinalTime=1.0e-07
    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0 1.0e-07) Intervals=20) )
  }

  *=== PULSE TRAIN: 9 pulses, each = rise(1ns) + hold(100ns) + fall(1ns) + read(100ns) ===
  *== Goal-based gate drive (simC v6 pattern).  Rise/fall: Transient+Goal
  *== with normalized step sizes per debug-log §2 Root Cause 2.
  *== Hold/read: bare Transient with absolute step sizes.

  *--- PULSE 1 ---  (peak: 1.00e-7 → 2.01e-7)
  NewCurrentPrefix="p01_rise_"
  Transient (
    InitialTime=1.0e-07 FinalTime=1.01e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0e-07 1.01e-07) Intervals=5) )
  }
  NewCurrentPrefix="p01_write_"
  Transient (
    InitialTime=1.01e-07 FinalTime=2.01e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.01e-07 2.01e-07) Intervals=10) )
  }
  NewCurrentPrefix="p01_fall_"
  Transient (
    InitialTime=2.01e-07 FinalTime=2.02e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.01e-07 2.02e-07) Intervals=5) )
  }
  NewCurrentPrefix="p01_read_"
  Transient (
    InitialTime=2.02e-07 FinalTime=3.02e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.02e-07 3.02e-07) Intervals=20) )
  }

  *--- PULSE 2 ---  (3.02e-7 → 5.04e-7)
  NewCurrentPrefix="p02_rise_"
  Transient (
    InitialTime=3.02e-07 FinalTime=3.03e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.02e-07 3.03e-07) Intervals=5) )
  }
  NewCurrentPrefix="p02_write_"
  Transient (
    InitialTime=3.03e-07 FinalTime=4.03e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.03e-07 4.03e-07) Intervals=10) )
  }
  NewCurrentPrefix="p02_fall_"
  Transient (
    InitialTime=4.03e-07 FinalTime=4.04e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.03e-07 4.04e-07) Intervals=5) )
  }
  NewCurrentPrefix="p02_read_"
  Transient (
    InitialTime=4.04e-07 FinalTime=5.04e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.04e-07 5.04e-07) Intervals=20) )
  }

  *--- PULSE 3 ---  (5.04e-7 → 7.06e-7)
  NewCurrentPrefix="p03_rise_"
  Transient (
    InitialTime=5.04e-07 FinalTime=5.05e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.04e-07 5.05e-07) Intervals=5) )
  }
  NewCurrentPrefix="p03_write_"
  Transient (
    InitialTime=5.05e-07 FinalTime=6.05e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.05e-07 6.05e-07) Intervals=10) )
  }
  NewCurrentPrefix="p03_fall_"
  Transient (
    InitialTime=6.05e-07 FinalTime=6.06e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.05e-07 6.06e-07) Intervals=5) )
  }
  NewCurrentPrefix="p03_read_"
  Transient (
    InitialTime=6.06e-07 FinalTime=7.06e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.06e-07 7.06e-07) Intervals=20) )
  }

  *--- PULSE 4 ---  (7.06e-7 → 9.08e-7)
  NewCurrentPrefix="p04_rise_"
  Transient (
    InitialTime=7.06e-07 FinalTime=7.07e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.06e-07 7.07e-07) Intervals=5) )
  }
  NewCurrentPrefix="p04_write_"
  Transient (
    InitialTime=7.07e-07 FinalTime=8.07e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.07e-07 8.07e-07) Intervals=10) )
  }
  NewCurrentPrefix="p04_fall_"
  Transient (
    InitialTime=8.07e-07 FinalTime=8.08e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.07e-07 8.08e-07) Intervals=5) )
  }
  NewCurrentPrefix="p04_read_"
  Transient (
    InitialTime=8.08e-07 FinalTime=9.08e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.08e-07 9.08e-07) Intervals=20) )
  }

  *--- PULSE 5 ---  (9.08e-7 → 1.110e-6)
  NewCurrentPrefix="p05_rise_"
  Transient (
    InitialTime=9.08e-07 FinalTime=9.09e-07
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.08e-07 9.09e-07) Intervals=5) )
  }
  NewCurrentPrefix="p05_write_"
  Transient (
    InitialTime=9.09e-07 FinalTime=1.009e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.09e-07 1.009e-06) Intervals=10) )
  }
  NewCurrentPrefix="p05_fall_"
  Transient (
    InitialTime=1.009e-06 FinalTime=1.010e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.009e-06 1.010e-06) Intervals=5) )
  }
  NewCurrentPrefix="p05_read_"
  Transient (
    InitialTime=1.010e-06 FinalTime=1.110e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.010e-06 1.110e-06) Intervals=20) )
  }

  *--- PULSE 6 ---  (1.110e-6 → 1.312e-6)
  NewCurrentPrefix="p06_rise_"
  Transient (
    InitialTime=1.110e-06 FinalTime=1.111e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.110e-06 1.111e-06) Intervals=5) )
  }
  NewCurrentPrefix="p06_write_"
  Transient (
    InitialTime=1.111e-06 FinalTime=1.211e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.111e-06 1.211e-06) Intervals=10) )
  }
  NewCurrentPrefix="p06_fall_"
  Transient (
    InitialTime=1.211e-06 FinalTime=1.212e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.211e-06 1.212e-06) Intervals=5) )
  }
  NewCurrentPrefix="p06_read_"
  Transient (
    InitialTime=1.212e-06 FinalTime=1.312e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.212e-06 1.312e-06) Intervals=20) )
  }

  *--- PULSE 7 ---  (1.312e-6 → 1.514e-6)
  NewCurrentPrefix="p07_rise_"
  Transient (
    InitialTime=1.312e-06 FinalTime=1.313e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.312e-06 1.313e-06) Intervals=5) )
  }
  NewCurrentPrefix="p07_write_"
  Transient (
    InitialTime=1.313e-06 FinalTime=1.413e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.313e-06 1.413e-06) Intervals=10) )
  }
  NewCurrentPrefix="p07_fall_"
  Transient (
    InitialTime=1.413e-06 FinalTime=1.414e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.413e-06 1.414e-06) Intervals=5) )
  }
  NewCurrentPrefix="p07_read_"
  Transient (
    InitialTime=1.414e-06 FinalTime=1.514e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.414e-06 1.514e-06) Intervals=20) )
  }

  *--- PULSE 8 ---  (1.514e-6 → 1.716e-6)
  NewCurrentPrefix="p08_rise_"
  Transient (
    InitialTime=1.514e-06 FinalTime=1.515e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.514e-06 1.515e-06) Intervals=5) )
  }
  NewCurrentPrefix="p08_write_"
  Transient (
    InitialTime=1.515e-06 FinalTime=1.615e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.515e-06 1.615e-06) Intervals=10) )
  }
  NewCurrentPrefix="p08_fall_"
  Transient (
    InitialTime=1.615e-06 FinalTime=1.616e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.615e-06 1.616e-06) Intervals=5) )
  }
  NewCurrentPrefix="p08_read_"
  Transient (
    InitialTime=1.616e-06 FinalTime=1.716e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.616e-06 1.716e-06) Intervals=20) )
  }

  *--- PULSE 9 ---  (1.716e-6 → 1.918e-6)
  NewCurrentPrefix="p09_rise_"
  Transient (
    InitialTime=1.716e-06 FinalTime=1.717e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= @V_pgm@ }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.716e-06 1.717e-06) Intervals=5) )
  }
  NewCurrentPrefix="p09_write_"
  Transient (
    InitialTime=1.717e-06 FinalTime=1.817e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.717e-06 1.817e-06) Intervals=10) )
  }
  NewCurrentPrefix="p09_fall_"
  Transient (
    InitialTime=1.817e-06 FinalTime=1.818e-06
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7
    Increment=1.4
    Goal { Name="gate_contact" Voltage= -0.5 }
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.817e-06 1.818e-06) Intervals=5) )
  }
  NewCurrentPrefix="p09_read_"
  Transient (
    InitialTime=1.818e-06 FinalTime=1.918e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.818e-06 1.918e-06) Intervals=20) )
  }

}

*===================================================================
*== SWB SETUP (re-create the H1 node set with the new param name)
*==   Parameter:  @V_pgm@
*==   Sweep:      1.0   1.5   2.0   2.5   6.0     V
*==
*== POST-PROCESSING (analyze_phase1d_h1.py, already in place):
*==   - fire_ratio = ID_p09_read_end / ID_baseline_pre  → M2 (>=1.5)
*==   - ID(N) staircase monotonicity per node
*==   - |E_y| at end of p09_write vs F_c → confirms sub-coercive vs super
*==   - Pick the LOWEST V_pgm passing M2 for H2/H3.
*===================================================================
