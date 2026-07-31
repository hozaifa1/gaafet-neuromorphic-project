"""Parametric LIF pulse-train cmd generator (with optional erase-reset + leaky hold).

A proper LIF cycle: ERASE (reset membrane -> deep off) -> baseline read ->
N sub-coercive integrate pulses (read after each) -> optional leaky hold.
All-transient; time stamps %.6e. Physics/Math identical to the calibrated app
device (FixedCharge 7e12 + Dit acceptor 4e12).

gen(...) -> cmd string (tokens resolved).

Areafactor comes from norm.AREAFACTOR_USED so that no .cmd generator carries its
own width number; the correction to the geometric value is applied in analysis
(norm.to_uA_per_um) -- Areafactor is a pure post-multiplier, so this is exact.
"""
import norm

HEAD = """*== PARAMETRIC LIF cmd (Device_Optimization/lifgen.py)
File {{
    Grid       = "{tdr}"
    Parameter  = "{par}"
    Plot       = "opt_outputs/{node}_des.tdr"
    Current    = "opt_outputs/{node}_des.plt"
    Output     = "opt_outputs/{node}_des.log"
}}
Electrode {{
  {{ Name="source_contact"  Voltage= 0.0 }}
  {{ Name="drain_contact"   Voltage= 0.0 }}
  {{ Name="gate_contact"    Voltage= 0.0  Workfunction={WF} }}
}}
Physics {{
  Temperature= {TEMP}
  Areafactor= {AREA}
  Fermi
  EffectiveIntrinsicDensity( OldSlotboom )
  Mobility( PhuMob Enormal )
  Recombination( SRH (DopingDependence TempDependence) Auger Band2Band(Model=Hurkx) )
}}
Physics(Material="HZO") {{ Polarization }}
Physics(MaterialInterface="Silicon/SiO2") {{
    Traps(
        (FixedCharge Conc=7e12 Level EnergyMid=0.0 fromMidBandGap)
        (Acceptor Gaussian fromCondBand Conc=4e12 EnergyMid=0.45 EnergySig=0.30
                  eXsection=1e-15 hXsection=1e-15)
    )
}}
Math {{
   Extrapolate RelErrControl Digits={DIGITS} Notdamped=50 Iterations=50 Transient=BE
   FEPolarizationIP=1.0 Method=Blocked SubMethod=ParDiSo GeometricDistances Derivative
   ComputeGradQuasiFermiAtContacts= UseQuasiFermi
   RefDens_eGradQuasiFermi_ElectricField_HFS= 1.000e+12
   RefDens_hGradQuasiFermi_ElectricField_HFS= 1.000e+12
   Method = Bitlis (Restart=100, Tolerance={TOL}, Iterations=200)
}}
Plot {{ eDensity hDensity TotalCurrent/Vector ElectricField/Vector Potential
  SpaceCharge ConductionBand ValenceBand Doping Polarization/Vector }}
CurrentPlot {{
  Polarization/Vector (( 0 {PROBEY} ))
  ElectricField/Vector (( 0 {PROBEY} ))
}}
Solve {{
  Transient ( InitialTime=0 FinalTime=1 ) {{ Coupled (Iterations=100) {{ Poisson }} }}
  NewCurrentPrefix="drain_bias_"
  Quasistationary ( InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal {{ Name="drain_contact" Voltage= {VDS} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="gate_to_read_"
  Quasistationary ( InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal {{ Name="gate_contact" Voltage= {VREAD} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
"""

ERASE = """  NewCurrentPrefix="erase_rise_"
  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e}
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7 Increment=1.4
    Goal {{ Name="gate_contact" Voltage= {VERASE} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="erase_hold_"
  Transient ( InitialTime={t1:.6e} FinalTime={t2:.6e}
    InitialStep=1e-11 MaxStep={emax:.3e} MinStep=1e-15 Increment=1.4 ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="erase_fall_"
  Transient ( InitialTime={t2:.6e} FinalTime={t3:.6e}
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7 Increment=1.4
    Goal {{ Name="gate_contact" Voltage= {VREAD} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
"""

BASE = """  NewCurrentPrefix="baseline_pre_"
  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e}
    InitialStep=1e-10 MaxStep={rmax:.3e} MinStep=1e-15 Increment=1.4 ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=({t0:.6e} {t1:.6e}) Intervals=15) ) }}
"""

LEG = """  NewCurrentPrefix="p{k:02d}_rise_"
  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e}
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7 Increment=1.4
    Goal {{ Name="gate_contact" Voltage= {VPGM} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="p{k:02d}_write_"
  Transient ( InitialTime={t1:.6e} FinalTime={t2:.6e}
    InitialStep=1e-11 MaxStep={tp_max:.3e} MinStep=1e-15 Increment=1.4 ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=({t1:.6e} {t2:.6e}) Intervals=6) ) }}
  NewCurrentPrefix="p{k:02d}_fall_"
  Transient ( InitialTime={t2:.6e} FinalTime={t3:.6e}
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7 Increment=1.4
    Goal {{ Name="gate_contact" Voltage= {VREAD} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="p{k:02d}_read_"
  Transient ( InitialTime={t3:.6e} FinalTime={t4:.6e}
    InitialStep=1e-11 MaxStep={tread_max:.3e} MinStep=1e-15 Increment=1.4 ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=({t3:.6e} {t4:.6e}) Intervals=12) ) }}
"""

HOLD = """  NewCurrentPrefix="hold_"
  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e}
    InitialStep=1e-9 MaxStep={hmax:.3e} MinStep=1e-15 Increment=1.4 ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=({t0:.6e} {t1:.6e}) Intervals={hint}) ) }}
"""


def gen(tdr, par, node, WF, VREAD, VPGM, PROBEY, N=9, t_p=100e-9, t_read=100e-9,
        t_rise=1e-9, VDS=0.05, TEMP=300, t_hold=0.0, hold_int=40,
        V_erase=0.0, t_erase=0.0, DIGITS=5, TOL=1e-5):
    s = HEAD.format(tdr=tdr, par=par, node=node, WF=WF, VREAD=VREAD, PROBEY=PROBEY,
                    VDS=VDS, TEMP=TEMP, DIGITS=DIGITS, TOL=TOL,
                    AREA=norm.AREAFACTOR_USED)
    t = 0.0
    if t_erase > 0:  # ERASE/RESET: drive gate to V_erase, hold, return -> deep off
        t0 = t; t1 = t0 + t_rise; t2 = t1 + t_erase; t3 = t2 + t_rise
        s += ERASE.format(t0=t0, t1=t1, t2=t2, t3=t3, VERASE=V_erase, VREAD=VREAD,
                          emax=max(t_erase / 10, 1e-10))
        t = t3
    s += BASE.format(t0=t, t1=t + t_read, rmax=max(t_read / 10, 1e-10))
    t += t_read
    for k in range(1, N + 1):
        t0 = t; t1 = t0 + t_rise; t2 = t1 + t_p; t3 = t2 + t_rise; t4 = t3 + t_read
        s += LEG.format(k=k, t0=t0, t1=t1, t2=t2, t3=t3, t4=t4, VPGM=VPGM, VREAD=VREAD,
                        tp_max=max(t_p / 10, 1e-10), tread_max=max(t_read / 10, 1e-10))
        t = t4
    if t_hold > 0:
        s += HOLD.format(t0=t, t1=t + t_hold, hmax=t_hold / hold_int, hint=hold_int)
    return s + "}\n"


if __name__ == "__main__":  # self-check
    import re
    c = gen("m.tdr", "p.par", "x", 4.35, -0.5, 1.0, 0.0085, N=10, t_p=20e-9,
            V_erase=-2.0, t_erase=1e-6, t_hold=50e-6)
    assert "@" not in c
    train = c.split('baseline_pre_')[1]
    ts = [float(x) for x in re.findall(r"(?:Initial|Final)Time=([0-9.e+-]+)", train)]
    assert all(b >= a for a, b in zip(ts, ts[1:])), "non-monotone post-baseline time"
    assert "erase_rise_" in c and "hold_" in c
    print("lifgen self-check OK:", len(c), "chars, erase+10 legs+hold, monotone")
