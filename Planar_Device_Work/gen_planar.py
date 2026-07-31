"""Planar-FeFET cmd generators (LIF pulse-train + memory-window I-V).

TRUE single-gate ABLATION of the optimized GAA: identical T_si=5nm/T_ox=1nm/T_fe=7nm/
T_metal=5nm/L_gate=100nm/L_ov=15nm/N_sub=1e16/N_sd=5e19/WF=4.35 (Device_Optimization/
sde/sde_opt.cmd), only the bottom gate stack removed. 3 electrodes (gate/source/drain),
floating body -- no substrate contact, exactly like GAA has none.
  - Areafactor = 1.0  (per-um-width; GAA's 0.071 was a double-gate-emulating-GAA-
    wraparound-perimeter fudge that does not apply once there is no wraparound)
  - probe_y = T_si/2 + T_ox + T_fe/2 = 0.0025+0.001+0.0035 = 0.007 um (HZO midpoint
    above the Si top surface, same convention as opt.py's probe_y())
Same calibrated Physics/Math (FixedCharge 7e12 + Dit acceptor 4e12, Bitlis, BE).
"""

AF = "1.0"
T_SI, T_OX, T_FE = 0.005, 0.001, 0.007
PROBEY_DEF = T_SI / 2.0 + T_OX + T_FE / 2.0   # = 0.007

# ---- shared physics/math body (Areafactor=1.0, 4 electrodes) ----
_PHYS = """Physics {{
  Temperature= {TEMP}
  Areafactor= """ + AF + """
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
                  eXsection=1e-15 hXsection=1e-15) )
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
"""

_ELEC = """Electrode {{
  {{ Name="source_contact"     Voltage= 0.0 }}
  {{ Name="drain_contact"      Voltage= 0.0 }}
  {{ Name="gate_contact"       Voltage= 0.0  Workfunction={WF} }}
}}
"""

# =====================================================================
# LIF pulse-train (erase -> baseline -> N pulses+reads -> optional hold)
# =====================================================================
_LIF_HEAD = """*== PLANAR LIF cmd (gen_planar.lif_gen)
File {{
    Grid       = "{tdr}"
    Parameter  = "{par}"
    Plot       = "planar_outputs/{node}_des.tdr"
    Current    = "planar_outputs/{node}_des.plt"
    Output     = "planar_outputs/{node}_des.log"
}}
""" + _ELEC + _PHYS + """Solve {{
  Transient ( InitialTime=0 FinalTime=1 ) {{ Coupled (Iterations=100) {{ Poisson }} }}
  NewCurrentPrefix="drain_bias_"
  Quasistationary ( InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal {{ Name="drain_contact" Voltage= {VDS} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="gate_to_read_"
  Quasistationary ( InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6
    Goal {{ Name="gate_contact" Voltage= {VREAD} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
"""

_ERASE = """  NewCurrentPrefix="erase_rise_"
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

_BASE = """  NewCurrentPrefix="baseline_pre_"
  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e}
    InitialStep=1e-10 MaxStep={rmax:.3e} MinStep=1e-15 Increment=1.4 ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=({t0:.6e} {t1:.6e}) Intervals=15) ) }}
"""

_LEG = """  NewCurrentPrefix="p{k:02d}_rise_"
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

_HOLD = """  NewCurrentPrefix="hold_"
  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e}
    InitialStep=1e-9 MaxStep={hmax:.3e} MinStep=1e-15 Increment=1.4 ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=({t0:.6e} {t1:.6e}) Intervals={hint}) ) }}
"""


def lif_gen(tdr, par, node, WF, VREAD, VPGM, PROBEY=PROBEY_DEF, N=9, t_p=100e-9,
            t_read=100e-9, t_rise=1e-9, VDS=0.05, TEMP=300, t_hold=0.0, hold_int=40,
            V_erase=0.0, t_erase=0.0, DIGITS=5, TOL=1e-5):
    s = _LIF_HEAD.format(tdr=tdr, par=par, node=node, WF=WF, VREAD=VREAD, PROBEY=PROBEY,
                         VDS=VDS, TEMP=TEMP, DIGITS=DIGITS, TOL=TOL)
    t = 0.0
    if t_erase > 0:
        t0 = t; t1 = t0 + t_rise; t2 = t1 + t_erase; t3 = t2 + t_rise
        s += _ERASE.format(t0=t0, t1=t1, t2=t2, t3=t3, VERASE=V_erase, VREAD=VREAD,
                           emax=max(t_erase / 10, 1e-10))
        t = t3
    s += _BASE.format(t0=t, t1=t + t_read, rmax=max(t_read / 10, 1e-10))
    t += t_read
    for k in range(1, N + 1):
        t0 = t; t1 = t0 + t_rise; t2 = t1 + t_p; t3 = t2 + t_rise; t4 = t3 + t_read
        s += _LEG.format(k=k, t0=t0, t1=t1, t2=t2, t3=t3, t4=t4, VPGM=VPGM, VREAD=VREAD,
                         tp_max=max(t_p / 10, 1e-10), tread_max=max(t_read / 10, 1e-10))
        t = t4
    if t_hold > 0:
        s += _HOLD.format(t0=t, t1=t + t_hold, hmax=t_hold / hold_int, hint=hold_int)
    return s + "}\n"


# =====================================================================
# Memory-window I-V: erase/program retained-state via fixed-Vg point reads
# =====================================================================
_VGS = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]
_RAMP = "InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7"

_MW_HEAD = """*== PLANAR memory-window I-V (gen_planar.mw_gen): +/-write 5us, fixed-Vg 50ns reads.
File {{ Grid="{tdr}" Parameter="{par}"
  Plot="planar_outputs/mw_{node}_des.tdr" Current="planar_outputs/mw_{node}_des.plt" Output="planar_outputs/mw_{node}_des.log" }}
""" + _ELEC + _PHYS + """Solve {{
  Transient ( InitialTime=0 FinalTime=1 ) {{ Coupled(Iterations=100) {{Poisson}} }}
  NewCurrentPrefix="drain_bias_"
  Quasistationary ( InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6 Goal{{Name="drain_contact" Voltage={VDS}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
"""


def _mw_block(state, vwrite, t0, vgs):
    t1, t2 = t0 + 1e-8, t0 + 1e-8 + 5e-6
    s = (f'  NewCurrentPrefix="{state}_w_rise_"\n  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e} {_RAMP}'
         f' Increment=1.4 Goal{{Name="gate_contact" Voltage={vwrite}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}\n'
         f'  NewCurrentPrefix="{state}_w_hold_"\n  Transient ( InitialTime={t1:.6e} FinalTime={t2:.6e}'
         f' InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15 Increment=1.4 ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}\n')
    t = t2
    for i, vg in enumerate(vgs):
        tr, th = t + 1e-8, t + 1e-8 + 5e-8
        s += (f'  NewCurrentPrefix="{state}_rset{i:02d}_"\n  Transient ( InitialTime={t:.6e} FinalTime={tr:.6e} {_RAMP}'
              f' Increment=1.4 Goal{{Name="gate_contact" Voltage={vg}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}\n'
              f'  NewCurrentPrefix="{state}_r{i:02d}_"\n  Transient ( InitialTime={tr:.6e} FinalTime={th:.6e}'
              f' InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15 Increment=1.4 ) {{ Coupled(Iterations=100){{Poisson Electron Hole}}\n'
              f'      CurrentPlot( Time=(Range=({tr:.6e} {th:.6e}) Intervals=5) ) }}\n')
        t = th
    return s, t


def mw_gen(tdr, par, node, WF, VE=-4.0, VP=4.0, VDS=0.05, PROBEY=PROBEY_DEF, vgs=None,
           TEMP=300, DIGITS=5, TOL=1e-5):
    vgs = _VGS if vgs is None else vgs
    s = _MW_HEAD.format(tdr=tdr, par=par, node=node, WF=WF, VDS=VDS, PROBEY=PROBEY,
                        TEMP=TEMP, DIGITS=DIGITS, TOL=TOL)
    b1, t = _mw_block("ers", VE, 0.0, vgs)
    b2, _ = _mw_block("pgm", VP, t, vgs)
    return s + b1 + b2 + "}\n"


# =====================================================================
# Transfer-curve / SS sweep: frozen-FE erase -> fine Vg sweep, program -> sweep
# (replicates Device_Optimization/ivgen.py; use the frozen par tau_E=100us)
# =====================================================================
_IV_HEAD = """*== PLANAR transfer/SS sweep (gen_planar.iv_gen): 500us frozen writes, fine Vg sweep.
File {{ Grid="{tdr}" Parameter="{par}"
  Plot="planar_outputs/iv_{node}_des.tdr" Current="planar_outputs/iv_{node}_des.plt" Output="planar_outputs/iv_{node}_des.log" }}
""" + _ELEC + _PHYS + """Solve {{
  Transient ( InitialTime=0 FinalTime=1 ) {{ Coupled(Iterations=100){{Poisson}} }}
  NewCurrentPrefix="drain_bias_"
  Quasistationary ( InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6 Goal{{Name="drain_contact" Voltage={VDS}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
  NewCurrentPrefix="ers_rise_"
  Transient ( InitialTime=0 FinalTime=1.0e-08 InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-9 Increment=1.4
    Goal{{Name="gate_contact" Voltage={VE}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
  NewCurrentPrefix="ers_hold_"
  Transient ( InitialTime=1.0e-08 FinalTime=5.0e-04 InitialStep=1e-9 MaxStep=2e-5 MinStep=1e-13 Increment=1.4 ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
  NewCurrentPrefix="ers_set_"
  Transient ( InitialTime=5.0e-04 FinalTime=5.0001e-04 InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-9 Increment=1.4
    Goal{{Name="gate_contact" Voltage={VLO}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
  NewCurrentPrefix="ers_"
  Transient ( InitialTime=5.0001e-04 FinalTime=5.0501e-04 InitialStep=1e-9 MaxStep=5e-8 MinStep=1e-12 Increment=1.2
    Goal{{Name="gate_contact" Voltage={VHI}}} ) {{
      Coupled(Iterations=100){{Poisson Electron Hole}}
      CurrentPlot( Time=(Range=(5.0001e-04 5.0501e-04) Intervals=100) ) }}
  NewCurrentPrefix="pgm_rise_"
  Transient ( InitialTime=5.0501e-04 FinalTime=5.0502e-04 InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-9 Increment=1.4
    Goal{{Name="gate_contact" Voltage={VP}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
  NewCurrentPrefix="pgm_hold_"
  Transient ( InitialTime=5.0502e-04 FinalTime=1.00502e-03 InitialStep=1e-9 MaxStep=2e-5 MinStep=1e-13 Increment=1.4 ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
  NewCurrentPrefix="pgm_set_"
  Transient ( InitialTime=1.00502e-03 FinalTime=1.00503e-03 InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-9 Increment=1.4
    Goal{{Name="gate_contact" Voltage={VLO}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
  NewCurrentPrefix="pgm_"
  Transient ( InitialTime=1.00503e-03 FinalTime=1.01003e-03 InitialStep=1e-9 MaxStep=5e-8 MinStep=1e-12 Increment=1.2
    Goal{{Name="gate_contact" Voltage={VHI}}} ) {{
      Coupled(Iterations=100){{Poisson Electron Hole}}
      CurrentPlot( Time=(Range=(1.00503e-03 1.01003e-03) Intervals=100) ) }}
}}
"""


def iv_gen(tdr, par, node, WF=4.35, VE=-6.0, VP=4.5, VLO=-1.5, VHI=2.0, VDS=0.05,
           PROBEY=PROBEY_DEF, TEMP=300, DIGITS=5, TOL=1e-5):
    return _IV_HEAD.format(tdr=tdr, par=par, node=node, WF=WF, VE=VE, VP=VP,
                           VLO=VLO, VHI=VHI, VDS=VDS, PROBEY=PROBEY, TEMP=TEMP,
                           DIGITS=DIGITS, TOL=TOL)


if __name__ == "__main__":
    import re
    c = lif_gen("m.tdr", "p.par", "x", 4.35, 0.0, 4.0, N=15, t_p=300e-9,
                V_erase=-4.0, t_erase=5e-6, t_hold=100e-6)
    assert "@" not in c and "substrate_contact" not in c and "Areafactor= 1.0" in c
    train = c.split("baseline_pre_")[1]
    ts = [float(x) for x in re.findall(r"(?:Initial|Final)Time=([0-9.e+-]+)", train)]
    assert all(b >= a for a, b in zip(ts, ts[1:])), "non-monotone time"
    m = mw_gen("m.tdr", "p.par", "y", 4.35)
    assert "@" not in m and m.count("NewCurrentPrefix") == 41 and "substrate_contact" not in m
    iv = iv_gen("m.tdr", "p.par", "z")
    assert "@" not in iv and iv.count("NewCurrentPrefix") == 9 and "substrate_contact" not in iv
    print("gen_planar self-check OK:", len(c), "LIF /", len(m), "MW /", len(iv), "IV chars")
