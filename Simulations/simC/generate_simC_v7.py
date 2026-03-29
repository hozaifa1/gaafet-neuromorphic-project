"""Generate sdevice_simC_v7.cmd — fine-tuning around 6V for optimal fire timing.

v6 Results (pw=100ns, tau_E=1us, pw/tau_E=0.1):
  Vpulse=5V → P1=1.18x, P15=1.89x, P30=1.88x (no fire, saturates ~1.9x)
  Vpulse=6V → P1=1.26x, P9=2.03x (FIRE at P9!), P30=2.03x — sweet spot
  Vpulse=7V → P1=1.32x, P5=2.16x (FIRE at P5!), P30=2.16x — fires too early

Key findings:
  - 6V fires at P9: gives sufficient integration time (~9 pulses of temporal info)
  - 7V fires at P5: rapid saturation leaves less room for computation
  - 5V saturates at 1.89x: just 6% short of fire threshold
  - Vreset=-5V gives 72-86% reset — could be optimized

v7 Plan:
  Vpulse = 5.5, 6.0, 6.5V (fine-tune around sweet spot)
  pw = 100ns (same — gradual integration confirmed optimal)
  N_PULSES = 25 (enough for fire + post-fire observation)
  Vreset = -6V (stronger reset for higher Vpulse nodes)
  LEAK_AFTER = 12 (earlier gap to see pre-fire decay)
"""
import os

# ── Parameters ──
VPULSE_VAR = "@Vpulse@"   # SWB sweep: 5.5, 6.0, 6.5 V
VRESET = -6.0              # Stronger reset for 6.5V node
VGS_READ = 0.20
VDS = 0.05
PW = 1.0e-7               # 100ns write pulse
TR = 1.0e-9               # 1ns rise
TF = 1.0e-9               # 1ns fall
T_READ = 1.0e-7           # 100ns read hold
N_PULSES = 25              # Optimal for fire observation
LEAK_AFTER = 12            # Insert leak gap after pulse 12
LEAK_DUR = 5.0e-6          # 5us leak gap
RESET_HOLD = 1.0e-6        # 1us reset hold

CYCLE = TR + PW + TF + T_READ  # ~202ns per pulse

out = []
def w(s=""): out.append(s)

# ── Header ──
w("*===================================================================")
w("*== PHASE 1B — SIM C v7: FINE-TUNING AROUND 6V SWEET SPOT")
w("*== v6 showed 6V fires at P9 (optimal), 7V fires at P5 (too early).")
w("*== v7: Vpulse=5.5/6.0/6.5V to optimize fire timing and reset.")
w(f"*== Sweep: {VPULSE_VAR} = 5.5, 6.0, 6.5 V  (SWB nodes)")
w(f"*== Fixed: VGS_read={VGS_READ}V, VDS={VDS}V, Vreset={VRESET}V, pw={PW*1e9:.0f}ns")
w(f"*== Protocol: {N_PULSES} write-then-read cycles, {LEAK_DUR*1e6:.0f}us leak gap after P{LEAK_AFTER}")
w(f"*== Each cycle: {TR*1e9:.0f}ns rise + {PW*1e9:.0f}ns write + {TF*1e9:.0f}ns fall + {T_READ*1e9:.0f}ns read")
w("*===================================================================")
w()


# ── File ──
w("File {")
w('    Grid = "@tdr@"')
w('    Parameter = "sdevice_gaafet_lif.par"')
w('    Plot = "@tdrdat@"')
w('    Current = "@plot@"')
w('    Output = "@log@"')
w("}")
w()


# ── Electrode ──
w("Electrode {")
w('  { Name="source_contact"     Voltage= 0.0 }')
w('  { Name="drain_contact"      Voltage= 0.0 }')
w('  { Name="gate_contact"       Voltage= 0.0  Workfunction=4.35 }')
w("}")
w()


# ── Physics ──
w("Physics {")
w("  Temperature= 300")
w("  Areafactor=0.071")
w("  Fermi")
w("  EffectiveIntrinsicDensity( OldSlotboom )")
w("  Mobility( PhuMob Enormal )")
w("  Recombination(")
w("    SRH (DopingDependence TempDependence)")
w("    Auger")
w("    Band2Band(Model=Hurkx)")
w("  )")
w("}")
w()
w('Physics(Material="HZO") {')
w("    Polarization")
w("}")
w()
w('Physics(MaterialInterface="Silicon/SiO2") {')
w("    Traps(")
w("        (FixedCharge Conc=4e12 Level EnergyMid=0.0 fromMidBandGap)")
w("    )")
w("}")
w()


# ── Math ──
w("Math {")
w("   Extrapolate")
w("   RelErrControl")
w("   Digits=5")
w("   Notdamped=50")
w("   Iterations=50")
w("   Transient=BE")
w("   FEPolarizationIP=1.0")
w("   Method=Blocked")
w("   SubMethod=ParDiSo")
w("   GeometricDistances")
w("   Derivative")
w("   ComputeGradQuasiFermiAtContacts= UseQuasiFermi")
w("   RefDens_eGradQuasiFermi_ElectricField_HFS= 1.000e+12")
w("   RefDens_hGradQuasiFermi_ElectricField_HFS= 1.000e+12")
w("   Method = Bitlis (Restart=100, Tolerance=1e-5, Iterations=200)")
w("}")
w()

# ── Plot ──
w("Plot {")
w("  eDensity hDensity")
w("  TotalCurrent/Vector ElectricField/Vector Potential SpaceCharge")
w("  ConductionBand ValenceBand Doping Polarization/Vector")
w("  BandGap SRHRecombination AugerRecombination eMobility hMobility")
w("}")
w()
w("CurrentPlot {")
w("  Polarization/Vector (( 0 0.0145 ))")
w("  ElectricField/Vector (( 0 0.0145 ))")
w("}")
w()

# ── Solve ──
w("Solve {")
w()
w("  *=== STEP 0: INITIALIZE ===")
w("  Transient (")
w("    InitialTime=0 FinalTime=1")
w("  ) { Coupled (Iterations = 100) { Poisson } }")
w()
w(f"  *=== STEP 1: SET DRAIN BIAS (VDS={VDS}V) ===")
w('  NewCurrentPrefix="drain_bias_"')
w("  Quasistationary (")
w("    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6")
w(f"    Goal {{ Name=\"drain_contact\" Voltage= {VDS} }}")
w("  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }")
w()
w(f"  *=== STEP 2: SET GATE READ BIAS (VGS_read={VGS_READ}V) ===")
w('  NewCurrentPrefix="gate_bias_"')
w("  Quasistationary (")
w("    InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6")
w(f"    Goal {{ Name=\"gate_contact\" Voltage= {VGS_READ} }}")
w("  ) { Coupled (Iterations = 100) {Poisson Electron Hole} }")
w()
w("  *=== BASELINE READ ===")
w('  NewCurrentPrefix="baseline_read_"')
w("  Transient (")
w(f"    InitialTime=0 FinalTime={T_READ:.4e}")
w("    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15")
w("    Increment=1.4")
w("  ) {")
w("      Coupled (Iterations = 100) {Poisson Electron Hole}")
w(f"      CurrentPlot( Time = (Range=(0 {T_READ:.4e}) Intervals=20) )")
w("  }")
w()

# ── Generate pulse blocks ──
t = T_READ  # current time after baseline read

def fmt(val):
    """Format time value in scientific notation."""
    return f"{val:.4e}"

def write_pulse(p, t_start):
    t_rise_end = t_start + TR
    t_write_end = t_rise_end + PW
    t_fall_end = t_write_end + TF
    t_read_end = t_fall_end + T_READ

    w(f"  *--- PULSE {p} ---")
    # Rise
    w(f'  NewCurrentPrefix="p{p:02d}_rise_"')
    w(f"  Transient (")
    w(f"    InitialTime={fmt(t_start)} FinalTime={fmt(t_rise_end)}")
    w(f"    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7")
    w(f"    Increment=1.4")
    w(f"    Goal {{ Name=\"gate_contact\" Voltage= {VPULSE_VAR} }}")
    w(f"  ) {{")
    w(f"      Coupled (Iterations = 100) {{Poisson Electron Hole}}")
    w(f"      CurrentPlot( Time = (Range=({fmt(t_start)} {fmt(t_rise_end)}) Intervals=5) )")
    w(f"  }}")

    # Write hold
    w(f'  NewCurrentPrefix="p{p:02d}_write_"')
    w(f"  Transient (")
    w(f"    InitialTime={fmt(t_rise_end)} FinalTime={fmt(t_write_end)}")
    w(f"    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15")
    w(f"    Increment=1.4")
    w(f"  ) {{")
    w(f"      Coupled (Iterations = 100) {{Poisson Electron Hole}}")
    w(f"      CurrentPlot( Time = (Range=({fmt(t_rise_end)} {fmt(t_write_end)}) Intervals=10) )")
    w(f"  }}")

    # Fall
    w(f'  NewCurrentPrefix="p{p:02d}_fall_"')
    w(f"  Transient (")
    w(f"    InitialTime={fmt(t_write_end)} FinalTime={fmt(t_fall_end)}")
    w(f"    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7")
    w(f"    Increment=1.4")
    w(f"    Goal {{ Name=\"gate_contact\" Voltage= {VGS_READ} }}")
    w(f"  ) {{")
    w(f"      Coupled (Iterations = 100) {{Poisson Electron Hole}}")
    w(f"      CurrentPlot( Time = (Range=({fmt(t_write_end)} {fmt(t_fall_end)}) Intervals=5) )")
    w(f"  }}")

    # Read hold
    w(f'  NewCurrentPrefix="p{p:02d}_read_"')
    w(f"  Transient (")
    w(f"    InitialTime={fmt(t_fall_end)} FinalTime={fmt(t_read_end)}")
    w(f"    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15")
    w(f"    Increment=1.4")
    w(f"  ) {{")
    w(f"      Coupled (Iterations = 100) {{Poisson Electron Hole}}")
    w(f"      CurrentPlot( Time = (Range=({fmt(t_fall_end)} {fmt(t_read_end)}) Intervals=20) )")
    w(f"  }}")
    w()

    return t_read_end

# Pulses 1 to LEAK_AFTER
w(f"  *=== PULSE TRAIN: {N_PULSES} write-then-read cycles ===")
w(f"  * pw={PW*1e9:.0f}ns, Vpulse={VPULSE_VAR}, VGS_read={VGS_READ}V")
w(f"  * {LEAK_DUR*1e6:.0f}us leak gap after pulse {LEAK_AFTER}")
w()

for p in range(1, LEAK_AFTER + 1):
    t = write_pulse(p, t)

# Leak gap
w(f"  *=== LEAK GAP: {LEAK_DUR*1e6:.0f}us at VGS_read={VGS_READ}V ===")
t_leak_end = t + LEAK_DUR
w(f'  NewCurrentPrefix="leak_gap_"')
w(f"  Transient (")
w(f"    InitialTime={fmt(t)} FinalTime={fmt(t_leak_end)}")
w(f"    InitialStep=1e-10 MaxStep=50e-9 MinStep=1e-15")
w(f"    Increment=1.4")
w(f"  ) {{")
w(f"      Coupled (Iterations = 100) {{Poisson Electron Hole}}")
w(f"      CurrentPlot( Time = (Range=({fmt(t)} {fmt(t_leak_end)}) Intervals=50) )")
w(f"  }}")
w()
t = t_leak_end

# Pulses LEAK_AFTER+1 to N_PULSES
for p in range(LEAK_AFTER + 1, N_PULSES + 1):
    t = write_pulse(p, t)

# Reset
w(f"  *=== RESET PULSE (Vreset={VRESET}V) ===")
t_reset_rise_end = t + TR
t_reset_hold_end = t_reset_rise_end + RESET_HOLD
t_reset_fall_end = t_reset_hold_end + TF
t_postread_end = t_reset_fall_end + T_READ

w(f'  NewCurrentPrefix="reset_rise_"')
w(f"  Transient (")
w(f"    InitialTime={fmt(t)} FinalTime={fmt(t_reset_rise_end)}")
w(f"    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7")
w(f"    Increment=1.4")
w(f"    Goal {{ Name=\"gate_contact\" Voltage= {VRESET} }}")
w(f"  ) {{")
w(f"      Coupled (Iterations = 100) {{Poisson Electron Hole}}")
w(f"      CurrentPlot( Time = (Range=({fmt(t)} {fmt(t_reset_rise_end)}) Intervals=5) )")
w(f"  }}")

w(f'  NewCurrentPrefix="reset_hold_"')
w(f"  Transient (")
w(f"    InitialTime={fmt(t_reset_rise_end)} FinalTime={fmt(t_reset_hold_end)}")
w(f"    InitialStep=1e-10 MaxStep=10e-9 MinStep=1e-15")
w(f"    Increment=1.4")
w(f"  ) {{")
w(f"      Coupled (Iterations = 100) {{Poisson Electron Hole}}")
w(f"      CurrentPlot( Time = (Range=({fmt(t_reset_rise_end)} {fmt(t_reset_hold_end)}) Intervals=20) )")
w(f"  }}")

w(f'  NewCurrentPrefix="reset_fall_"')
w(f"  Transient (")
w(f"    InitialTime={fmt(t_reset_hold_end)} FinalTime={fmt(t_reset_fall_end)}")
w(f"    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7")
w(f"    Increment=1.4")
w(f"    Goal {{ Name=\"gate_contact\" Voltage= {VGS_READ} }}")
w(f"  ) {{")
w(f"      Coupled (Iterations = 100) {{Poisson Electron Hole}}")
w(f"      CurrentPlot( Time = (Range=({fmt(t_reset_hold_end)} {fmt(t_reset_fall_end)}) Intervals=5) )")
w(f"  }}")
w()

w(f"  *=== POST-RESET READ ===")
w(f'  NewCurrentPrefix="postreset_read_"')
w(f"  Transient (")
w(f"    InitialTime={fmt(t_reset_fall_end)} FinalTime={fmt(t_postread_end)}")
w(f"    InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15")
w(f"    Increment=1.4")
w(f"  ) {{")
w(f"      Coupled (Iterations = 100) {{Poisson Electron Hole}}")
w(f"      CurrentPlot( Time = (Range=({fmt(t_reset_fall_end)} {fmt(t_postread_end)}) Intervals=20) )")
w(f"  }}")
w()
w("}")
w()

# Write output
outpath = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sdevice_simC_v7.cmd")
with open(outpath, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(out))
print(f"Generated: {outpath}")
print(f"Total lines: {len(out)}")
print(f"Total sim time: {t_postread_end*1e6:.2f} us")
print(f"Pulses: {N_PULSES}, pw={PW*1e9:.0f}ns, Vreset={VRESET}V")
