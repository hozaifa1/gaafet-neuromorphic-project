*===================================================================
*== PHASE 1D — SIM H2: P-E LOOP + CV at the H1-chosen V_pgm
*==
*== Goal: extract memory window (CV midpoint shift virgin → post-pgm)
*==   for each Polarization-block edit of the canonical par file:
*==   baseline (P_r=16, F_c=1.2), H2A (Lizzit 20, 1.1),
*==   H2B (pushPr 22, 1.1), H2C (lowEc 20, 0.9).
*==
*== Run-order: edit the par file, run this cmd, archive the output
*==   dir under a per-variant label, edit again, repeat.
*==
*== V_pgm is SWB-sweepable as @V_pgm@ ∈ {1.5, 2.0, 2.5, 3.5, 6.0} V
*==   so that within each par variant we also get a V_pgm dependence.
*==   Set V_pgm = 6.0 for the variant that re-runs the Phase 1C
*==   baseline condition (a sanity check that the new par still
*==   reproduces the −25 mV CV shift Phase 1C measured).
*==
*== Workfunction is fixed at the value chosen from H1 — paste the
*==   chosen WF into the @WF@ field below or leave as @WF@ and
*==   carry the choice forward as a SWB project parameter.
*===================================================================

File {
    Grid       = "@tdr@"
    Parameter  = "sdevice_gaafet_lif.par"
    Plot       = "@tdrdat@"
    Current    = "@plot@"
    ACExtract  = "@acplot@"
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

System {
   GAAFeFET fefet (gate_contact=g drain_contact=d source_contact=s)

   * vg.dc handles all DC ramps and CV sweeps.
   * pwl carries the program/erase pulse train (deviation from dc=0.2V read level).
   * Total gate voltage = vg.dc + pwl(t).
   * Pulse train: one program pulse at +V_pgm (10 ns rise, 100 ns hold,
   *   10 ns fall), then 100 ns settle, then one erase pulse at −V_pgm.
   *   Two pulses are enough to define the full P-E loop.
   Vsource_pset vg(g 0) {
     dc = 0
     pwl = (
        0          0
        1.0e-08    @V_pgm@
        1.1e-07    @V_pgm@
        1.2e-07    0
        2.2e-07    0
        2.3e-07   -@V_pgm@
        3.3e-07   -@V_pgm@
        3.4e-07    0
        4.4e-07    0
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

  *=== STEP 2: RAMP GATE TO VGS_LOW = -1 V (start of virgin CV) ===
  NewCurrentPrefix="gate_init_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vg.dc Voltage= -1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE A: VIRGIN CV SWEEP (-1 V → +1 V at f=1 MHz) ===
  *== Same ACCoupled pattern as simG.  Used to extract C_gg(VGS)
  *== and the CV-midpoint V_th_virgin.
  NewCurrentPrefix="cv_virgin_"
  Quasistationary (
    DoZero
    InitialStep=1e-2 Increment=1.5
    MinStep=1e-5 MaxStep=0.04
    Goal { Parameter=vg.dc Voltage= 1.0 }
  ) { ACCoupled (
        StartFrequency= 1e+06 EndFrequency= 1e+06 NumberOfPoints= 1 Decade
        Node(g d s) Exclude(vg vd vs)
        ACCompute (Time= (Range=(0 1) Intervals=80))
      ) { Poisson Electron Hole }
  }

  *=== STEP 3: RETURN TO VGS_READ = 0.2 V FOR PULSE TRAIN ===
  NewCurrentPrefix="gate_to_read_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vg.dc Voltage= 0.2 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE B PRECONDITION: PROGRAM PULSE at +V_pgm (via pwl) ===
  *== No Goal in Transient (debug log lesson §2).
  NewCurrentPrefix="pgm_rise_"
  Transient (
    InitialTime=0.0e+00 FinalTime=1.0e-08
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0.0 1.0e-08) Intervals=10) )
  }
  NewCurrentPrefix="pgm_hold_"
  Transient (
    InitialTime=1.0e-08 FinalTime=1.1e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0e-08 1.1e-07) Intervals=20) )
  }
  NewCurrentPrefix="pgm_fall_"
  Transient (
    InitialTime=1.1e-07 FinalTime=1.2e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1e-07 1.2e-07) Intervals=10) )
  }
  NewCurrentPrefix="pgm_settle_"
  Transient (
    InitialTime=1.2e-07 FinalTime=2.2e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2e-07 2.2e-07) Intervals=10) )
  }

  *=== STEP 4: RAMP TO -1 V FOR POST-PGM CV ===
  NewCurrentPrefix="gate_init_postpgm_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vg.dc Voltage= -1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE B: POST-PROGRAM CV SWEEP ===
  NewCurrentPrefix="cv_postpgm_"
  Quasistationary (
    DoZero
    InitialStep=1e-2 Increment=1.5
    MinStep=1e-5 MaxStep=0.04
    Goal { Parameter=vg.dc Voltage= 1.0 }
  ) { ACCoupled (
        StartFrequency= 1e+06 EndFrequency= 1e+06 NumberOfPoints= 1 Decade
        Node(g d s) Exclude(vg vd vs)
        ACCompute (Time= (Range=(0 1) Intervals=80))
      ) { Poisson Electron Hole }
  }

  *=== PHASE C PRECONDITION: ERASE PULSE at -V_pgm (via pwl) ===
  *== Drives pwl branch from 2.3e-07 → 4.4e-07 in the System block.
  NewCurrentPrefix="ers_rise_"
  Transient (
    InitialTime=2.2e-07 FinalTime=2.3e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.2e-07 2.3e-07) Intervals=10) )
  }
  NewCurrentPrefix="ers_hold_"
  Transient (
    InitialTime=2.3e-07 FinalTime=3.3e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.3e-07 3.3e-07) Intervals=20) )
  }
  NewCurrentPrefix="ers_fall_"
  Transient (
    InitialTime=3.3e-07 FinalTime=3.4e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.3e-07 3.4e-07) Intervals=10) )
  }
  NewCurrentPrefix="ers_settle_"
  Transient (
    InitialTime=3.4e-07 FinalTime=4.4e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.4e-07 4.4e-07) Intervals=10) )
  }

  *=== STEP 5: RAMP TO -1 V FOR POST-ERASE CV ===
  NewCurrentPrefix="gate_init_posters_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vg.dc Voltage= -1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE C: POST-ERASE CV SWEEP (closes the loop) ===
  NewCurrentPrefix="cv_posters_"
  Quasistationary (
    DoZero
    InitialStep=1e-2 Increment=1.5
    MinStep=1e-5 MaxStep=0.04
    Goal { Parameter=vg.dc Voltage= 1.0 }
  ) { ACCoupled (
        StartFrequency= 1e+06 EndFrequency= 1e+06 NumberOfPoints= 1 Decade
        Node(g d s) Exclude(vg vd vs)
        ACCompute (Time= (Range=(0 1) Intervals=80))
      ) { Poisson Electron Hole }
  }

}
