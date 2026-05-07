*===================================================================
*== PHASE 1C — SIM G: GATE CAPACITANCE C_gg (AC small-signal)
*== Sweep VGS=-1.0V to +1.0V at f=1 MHz.
*== Phase A: virgin state.   Phase B: post-fire (9 pulses at 6V).
*==
*== Architecture notes (why this file looks the way it does):
*==   1) ACCoupled needs circuit nodes (g d s), so we MUST use
*==      System+Vsource_pset.  Bare-Electrode + ACCoupled fails with
*==      "Cannot find AC node 'gate_contact'!".
*==   2) Goal{Parameter=vg.dc ...} is ONLY valid in Quasistationary,
*==      not in Transient (-> "specified goal item is not supported
*==      in transient").  So the pulse train cannot use Goal at all.
*==   3) Solution: drive the pulse train with a pwl signal on vg.
*==      pwl carries the time-domain deviation from vg.dc.
*==        - vg.dc = 0.2 V (read level) is set by the Quasistationary
*==          ramp before the train and held throughout it.
*==        - pwl(t) = 0 during read phases, +5.8 V during write phases
*==          (so vg.dc + pwl = 6.0 V), with 1 ns linear ramps.
*==      After the train pwl ends at 0 V; subsequent Quasistationary
*==      sweeps of vg.dc work normally.
*===================================================================

File {
    Grid = "@tdr@"
    Parameter = "sdevice_gaafet_lif.par"
    Plot = "@tdrdat@"
    Current = "@plot@"
    ACExtract = "@acplot@"
    Output = "@log@"
}

Device GAAFeFET {

  Electrode {
    { Name="source_contact"     Voltage= 0.0 }
    { Name="drain_contact"      Voltage= 0.0 }
    { Name="gate_contact"       Voltage= 0.0  Workfunction=4.35 }
  }

  Physics {
    Temperature= 300
    Areafactor=0.071
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
    BandGap SRHRecombination AugerRecombination eMobility hMobility
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

   * vg drives gate.  dc is swept by Quasistationary blocks for CV.
   * pwl carries the 9-pulse train (deviation from dc=0.2V read level).
   * Total gate voltage at time t = vg.dc + pwl(t).
   Vsource_pset vg(g 0) {
     dc = 0
     pwl = (
        0          0
        1.0000e-09 5.8
        1.0100e-07 5.8
        1.0200e-07 0
        2.0200e-07 0
        2.0300e-07 5.8
        3.0300e-07 5.8
        3.0400e-07 0
        4.0400e-07 0
        4.0500e-07 5.8
        5.0500e-07 5.8
        5.0600e-07 0
        6.0600e-07 0
        6.0700e-07 5.8
        7.0700e-07 5.8
        7.0800e-07 0
        8.0800e-07 0
        8.0900e-07 5.8
        9.0900e-07 5.8
        9.1000e-07 0
        1.0100e-06 0
        1.0110e-06 5.8
        1.1110e-06 5.8
        1.1120e-06 0
        1.2120e-06 0
        1.2130e-06 5.8
        1.3130e-06 5.8
        1.3140e-06 0
        1.4140e-06 0
        1.4150e-06 5.8
        1.5150e-06 5.8
        1.5160e-06 0
        1.6160e-06 0
        1.6170e-06 5.8
        1.7170e-06 5.8
        1.7180e-06 0
        1.8180e-06 0
     )
   }
   Vsource_pset vd(d 0) { dc = 0 }
   Vsource_pset vs(s 0) { dc = 0 }
}

Solve {

  *=== STEP 0: INITIALIZE ===
  Coupled (Iterations= 100 LineSearchDamping= 1e-8) { Poisson }
  Coupled { Poisson Electron Hole }

  *=== STEP 1: RAMP DRAIN TO VDS=0.05V ===
  NewCurrentPrefix="drain_bias_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vd.dc Voltage= 0.05 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== STEP 2: RAMP GATE TO VGS_LOW=-1.0V (start of CV sweep) ===
  NewCurrentPrefix="gate_init_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vg.dc Voltage= -1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE A: VIRGIN STATE CV SWEEP (-1V -> +1V, AC at 1 MHz) ===
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

  *=== STEP 3: RETURN TO VGS_READ=0.2V FOR PULSING ===
  *== After this, vg.dc=0.2 stays fixed; pwl drives the train.
  NewCurrentPrefix="gate_to_read_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vg.dc Voltage= 0.2 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE B PRECONDITION: 9 pulses at Vpulse=6.0V via pwl on vg ===
  *== No Goal in Transient — pwl drives gate.  vg.dc stays at 0.2 V.

  *--- PULSE 1 ---
  NewCurrentPrefix="p01_rise_"
  Transient (
    InitialTime=0.0000e+00 FinalTime=1.0000e-09
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(0.0000e+00 1.0000e-09) Intervals=5) )
  }
  NewCurrentPrefix="p01_write_"
  Transient (
    InitialTime=1.0000e-09 FinalTime=1.0100e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0000e-09 1.0100e-07) Intervals=10) )
  }
  NewCurrentPrefix="p01_fall_"
  Transient (
    InitialTime=1.0100e-07 FinalTime=1.0200e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0100e-07 1.0200e-07) Intervals=5) )
  }
  NewCurrentPrefix="p01_read_"
  Transient (
    InitialTime=1.0200e-07 FinalTime=2.0200e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0200e-07 2.0200e-07) Intervals=20) )
  }

  *--- PULSE 2 ---
  NewCurrentPrefix="p02_rise_"
  Transient (
    InitialTime=2.0200e-07 FinalTime=2.0300e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0200e-07 2.0300e-07) Intervals=5) )
  }
  NewCurrentPrefix="p02_write_"
  Transient (
    InitialTime=2.0300e-07 FinalTime=3.0300e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(2.0300e-07 3.0300e-07) Intervals=10) )
  }
  NewCurrentPrefix="p02_fall_"
  Transient (
    InitialTime=3.0300e-07 FinalTime=3.0400e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0300e-07 3.0400e-07) Intervals=5) )
  }
  NewCurrentPrefix="p02_read_"
  Transient (
    InitialTime=3.0400e-07 FinalTime=4.0400e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(3.0400e-07 4.0400e-07) Intervals=20) )
  }

  *--- PULSE 3 ---
  NewCurrentPrefix="p03_rise_"
  Transient (
    InitialTime=4.0400e-07 FinalTime=4.0500e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0400e-07 4.0500e-07) Intervals=5) )
  }
  NewCurrentPrefix="p03_write_"
  Transient (
    InitialTime=4.0500e-07 FinalTime=5.0500e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(4.0500e-07 5.0500e-07) Intervals=10) )
  }
  NewCurrentPrefix="p03_fall_"
  Transient (
    InitialTime=5.0500e-07 FinalTime=5.0600e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0500e-07 5.0600e-07) Intervals=5) )
  }
  NewCurrentPrefix="p03_read_"
  Transient (
    InitialTime=5.0600e-07 FinalTime=6.0600e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(5.0600e-07 6.0600e-07) Intervals=20) )
  }

  *--- PULSE 4 ---
  NewCurrentPrefix="p04_rise_"
  Transient (
    InitialTime=6.0600e-07 FinalTime=6.0700e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0600e-07 6.0700e-07) Intervals=5) )
  }
  NewCurrentPrefix="p04_write_"
  Transient (
    InitialTime=6.0700e-07 FinalTime=7.0700e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(6.0700e-07 7.0700e-07) Intervals=10) )
  }
  NewCurrentPrefix="p04_fall_"
  Transient (
    InitialTime=7.0700e-07 FinalTime=7.0800e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0700e-07 7.0800e-07) Intervals=5) )
  }
  NewCurrentPrefix="p04_read_"
  Transient (
    InitialTime=7.0800e-07 FinalTime=8.0800e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(7.0800e-07 8.0800e-07) Intervals=20) )
  }

  *--- PULSE 5 ---
  NewCurrentPrefix="p05_rise_"
  Transient (
    InitialTime=8.0800e-07 FinalTime=8.0900e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0800e-07 8.0900e-07) Intervals=5) )
  }
  NewCurrentPrefix="p05_write_"
  Transient (
    InitialTime=8.0900e-07 FinalTime=9.0900e-07
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(8.0900e-07 9.0900e-07) Intervals=10) )
  }
  NewCurrentPrefix="p05_fall_"
  Transient (
    InitialTime=9.0900e-07 FinalTime=9.1000e-07
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.0900e-07 9.1000e-07) Intervals=5) )
  }
  NewCurrentPrefix="p05_read_"
  Transient (
    InitialTime=9.1000e-07 FinalTime=1.0100e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(9.1000e-07 1.0100e-06) Intervals=20) )
  }

  *--- PULSE 6 ---
  NewCurrentPrefix="p06_rise_"
  Transient (
    InitialTime=1.0100e-06 FinalTime=1.0110e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0100e-06 1.0110e-06) Intervals=5) )
  }
  NewCurrentPrefix="p06_write_"
  Transient (
    InitialTime=1.0110e-06 FinalTime=1.1110e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.0110e-06 1.1110e-06) Intervals=10) )
  }
  NewCurrentPrefix="p06_fall_"
  Transient (
    InitialTime=1.1110e-06 FinalTime=1.1120e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1110e-06 1.1120e-06) Intervals=5) )
  }
  NewCurrentPrefix="p06_read_"
  Transient (
    InitialTime=1.1120e-06 FinalTime=1.2120e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.1120e-06 1.2120e-06) Intervals=20) )
  }

  *--- PULSE 7 ---
  NewCurrentPrefix="p07_rise_"
  Transient (
    InitialTime=1.2120e-06 FinalTime=1.2130e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2120e-06 1.2130e-06) Intervals=5) )
  }
  NewCurrentPrefix="p07_write_"
  Transient (
    InitialTime=1.2130e-06 FinalTime=1.3130e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.2130e-06 1.3130e-06) Intervals=10) )
  }
  NewCurrentPrefix="p07_fall_"
  Transient (
    InitialTime=1.3130e-06 FinalTime=1.3140e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3130e-06 1.3140e-06) Intervals=5) )
  }
  NewCurrentPrefix="p07_read_"
  Transient (
    InitialTime=1.3140e-06 FinalTime=1.4140e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.3140e-06 1.4140e-06) Intervals=20) )
  }

  *--- PULSE 8 ---
  NewCurrentPrefix="p08_rise_"
  Transient (
    InitialTime=1.4140e-06 FinalTime=1.4150e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4140e-06 1.4150e-06) Intervals=5) )
  }
  NewCurrentPrefix="p08_write_"
  Transient (
    InitialTime=1.4150e-06 FinalTime=1.5150e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.4150e-06 1.5150e-06) Intervals=10) )
  }
  NewCurrentPrefix="p08_fall_"
  Transient (
    InitialTime=1.5150e-06 FinalTime=1.5160e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5150e-06 1.5160e-06) Intervals=5) )
  }
  NewCurrentPrefix="p08_read_"
  Transient (
    InitialTime=1.5160e-06 FinalTime=1.6160e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.5160e-06 1.6160e-06) Intervals=20) )
  }

  *--- PULSE 9 ---
  NewCurrentPrefix="p09_rise_"
  Transient (
    InitialTime=1.6160e-06 FinalTime=1.6170e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6160e-06 1.6170e-06) Intervals=5) )
  }
  NewCurrentPrefix="p09_write_"
  Transient (
    InitialTime=1.6170e-06 FinalTime=1.7170e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.6170e-06 1.7170e-06) Intervals=10) )
  }
  NewCurrentPrefix="p09_fall_"
  Transient (
    InitialTime=1.7170e-06 FinalTime=1.7180e-06
    InitialStep=1e-11 MaxStep=2e-10 MinStep=1e-13
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7170e-06 1.7180e-06) Intervals=5) )
  }
  NewCurrentPrefix="p09_read_"
  Transient (
    InitialTime=1.7180e-06 FinalTime=1.8180e-06
    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15
    Increment=1.4
  ) {
      Coupled (Iterations = 100) {Poisson Electron Hole}
      CurrentPlot( Time = (Range=(1.7180e-06 1.8180e-06) Intervals=20) )
  }

  *=== STEP 4: RAMP GATE TO VGS_LOW=-1.0V (start of post-fire CV sweep) ===
  *== pwl is now at 0 (last knot), so vg.dc fully controls gate.
  NewCurrentPrefix="gate_init_postfire_"
  Quasistationary (
    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal { Parameter=vg.dc Voltage= -1.0 }
  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }

  *=== PHASE B: POST-FIRE STATE CV SWEEP (-1V -> +1V, AC at 1 MHz) ===
  NewCurrentPrefix="cv_postfire_"
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
