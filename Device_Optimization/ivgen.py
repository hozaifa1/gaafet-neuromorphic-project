"""Continuous retained-state I_D-V_GS generator (RR-0).

WHY THIS FILE WAS REWRITTEN (2026-07-31)
----------------------------------------
The original version wrote its .cmd against `app_frozen.par` (tau_E = tau_P =
1e-4) and used a 500 us write hold, on the reasoning "hold >> tau_E gives a full
switch, read << tau_E keeps it frozen".  The switching half of that is right; the
retention half is not.  `app_frozen.par` also sets **tau_P = 1e-4**, so a 500 us
hold is 5 depolarization time constants: whatever the field switches, the model
relaxes back inside the same hold.  The `iv_fe07` node it produced is measurably
dead -- the FE-midpoint probe reads

    Pos(0,0.007) Polarization/y = +2.3267e-07 C/cm2 (erased)
                                = +2.3238e-07 C/cm2 (programmed)

i.e. the two states differ by 0.1 %, and the two I-V branches lie on top of each
other above V_G = +0.2 V.  Every number derived from that node is meaningless,
including csv_export/raw/memory_window_iv.csv (figure D1).

The fix is not a different tau.  tau_E must be short for the write to switch and
tau_P must be long relative to the write for the state to survive, so tau_E <<
tau_P: exactly `app.par` (tau_E = 1e-6, tau_P = 1e-5).  The read must then be
fast compared with tau_E, which is what the working `mw_*` / `mwfine` nodes do
with 50 ns fixed-V_G point reads.

This generator keeps the *write* protocol of memwingen.py verbatim (+-2.0 V,
10 ns ramp, 5 us hold -- the protocol every published window number came from)
and replaces the 19 point reads with ONE continuous 500 ns V_G ramp sampled at
250 points, so the result is a smooth curve rather than a scatter of points.

Two details that make the fast ramp legitimate:
  * 500 ns = 0.5 tau_E, but the whole read window is sub-coercive (at V_G = +1 V
    the probe sees |E| well under F_c), and Preisach switching below F_c is
    strongly suppressed, so the state creeps far less than 0.5 tau_E would
    suggest.  The same argument is what makes `mwfine` valid.
  * a 2 V swing in 500 ns injects a gate-to-drain displacement current of order
    5e-4 uA/um through the 15 nm overlap, which is not negligible against the
    ~6e-3 uA/um off-state.  The .plt records `drain_contact DisplacementCurrent`
    separately, so the analysis reads the CONDUCTION current, eCurrent+hCurrent,
    and the artifact is removed exactly rather than argued away.

Also saves a .tdr snapshot of each retained state (erased / programmed) for the
2D maps (RR-6): polarization, carrier density, field, bands.

  gen(mesh, py, node=..., par=...) -> cmd string
"""
import norm

HEAD = """*== Continuous retained-state I-V (ivgen.py, RR-0): +/-2 V 5us writes, 500ns frozen sweep.
File {{ Grid="{mesh}_msh.tdr" Parameter="{par}"
  Plot="opt_outputs/{node}_des.tdr" Current="opt_outputs/{node}_des.plt" Output="opt_outputs/{node}_des.log" }}
Electrode {{ {{Name="source_contact" Voltage=0.0}} {{Name="drain_contact" Voltage=0.0}} {{Name="gate_contact" Voltage=0.0 Workfunction={WF}}} }}
Physics {{ Temperature=300 Areafactor={AREA} Fermi EffectiveIntrinsicDensity(OldSlotboom)
  Mobility(PhuMob Enormal) Recombination(SRH(DopingDependence TempDependence) Auger Band2Band(Model=Hurkx)) }}
Physics(Material="HZO") {{ Polarization }}
Physics(MaterialInterface="Silicon/SiO2") {{ Traps(
  (FixedCharge Conc=7e12 Level EnergyMid=0.0 fromMidBandGap)
  (Acceptor Gaussian fromCondBand Conc=4e12 EnergyMid=0.45 EnergySig=0.30 eXsection=1e-15 hXsection=1e-15)) }}
Math {{ Extrapolate RelErrControl Digits=5 Notdamped=50 Iterations=50 Transient=BE FEPolarizationIP=1.0
  Method=Blocked SubMethod=ParDiSo GeometricDistances Derivative ComputeGradQuasiFermiAtContacts=UseQuasiFermi
  RefDens_eGradQuasiFermi_ElectricField_HFS=1.000e+12 RefDens_hGradQuasiFermi_ElectricField_HFS=1.000e+12
  Method=Bitlis(Restart=100, Tolerance=1e-5, Iterations=200) }}
Plot {{ eDensity hDensity eCurrent hCurrent TotalCurrent/Vector ElectricField/Vector Potential
  SpaceCharge ConductionBand ValenceBand Doping
  eQuasiFermiPotential hQuasiFermiPotential Polarization/Vector SRHRecombination eMobility }}
CurrentPlot {{ Polarization/Vector (( 0 {py:.5f} )) ElectricField/Vector (( 0 {py:.5f} )) }}
Solve {{
  Transient ( InitialTime=0 FinalTime=1 ) {{ Coupled(Iterations=100) {{Poisson}} }}
  NewCurrentPrefix="drain_bias_"
  Quasistationary ( InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6 Goal{{Name="drain_contact" Voltage={VDS}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
"""

RAMP = "InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7"   # instant gate transition (memwingen recipe)


def _state(state, vwrite, t0, vlo, vhi, node, t_hold=5e-6, t_sweep=5e-7, npts=250):
    """One write + one continuous read sweep.  Returns (cmd_text, end_time)."""
    t1 = t0 + 1e-8                 # gate ramp to the write level
    t2 = t1 + t_hold               # write hold (5 us = 5*tau_E, 0.5*tau_P)
    t3 = t2 + 1e-8                 # drop back to the sweep start
    t4 = t3 + t_sweep              # the read sweep itself
    return (
        f'  NewCurrentPrefix="{state}_w_rise_"\n'
        f'  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e} {RAMP} Increment=1.4'
        f' Goal{{Name="gate_contact" Voltage={vwrite}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}\n'
        f'  NewCurrentPrefix="{state}_w_hold_"\n'
        f'  Transient ( InitialTime={t1:.6e} FinalTime={t2:.6e}'
        f' InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15 Increment=1.4 ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}\n'
        f'  NewCurrentPrefix="{state}_set_"\n'
        f'  Transient ( InitialTime={t2:.6e} FinalTime={t3:.6e} {RAMP} Increment=1.4'
        f' Goal{{Name="gate_contact" Voltage={vlo}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}\n'
        f'  Save ( FilePrefix="opt_outputs/state_{state}_{node}" )\n'
        f'  NewCurrentPrefix="{state}_"\n'
        f'  Transient ( InitialTime={t3:.6e} FinalTime={t4:.6e}'
        f' InitialStep=1e-12 MaxStep={t_sweep / npts:.6e} MinStep=1e-16 Increment=1.2'
        f' Goal{{Name="gate_contact" Voltage={vhi}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}}\n'
        f'      CurrentPlot( Time=(Range=({t3:.6e} {t4:.6e}) Intervals={npts}) ) }}\n',
        t4)


def gen(mesh, py, node=None, par="app_opt.par", WF=4.35, VE=-2.0, VP=2.0,
        VLO=-1.0, VHI=1.0, VDS=0.05, t_hold=5e-6, t_sweep=5e-7, npts=250):
    node = node or f"iv_{mesh}"
    s = HEAD.format(mesh=mesh, py=py, node=node, par=par, WF=WF, VDS=VDS,
                    AREA=norm.AREAFACTOR_USED)
    b1, t = _state("ers", VE, 0.0, VLO, VHI, node, t_hold, t_sweep, npts)
    b2, _ = _state("pgm", VP, t, VLO, VHI, node, t_hold, t_sweep, npts)
    return s + b1 + b2 + "}\n"


if __name__ == "__main__":
    import re

    c = gen("fe07", 0.007, node="iv_fe07b")
    assert "@" not in c, "stray @ would break SWB token substitution"
    assert c.count("NewCurrentPrefix") == 9, c.count("NewCurrentPrefix")
    assert c.count('Save ( FilePrefix') == 2
    assert "app_opt.par" in c and "app_frozen" not in c
    pairs = re.findall(r"InitialTime=([0-9.e+-]+) FinalTime=([0-9.e+-]+)", c)
    last = -1.0
    for a, b in pairs[1:]:            # skip the t=0..1 Poisson-only init
        a, b = float(a), float(b)
        assert a >= last - 1e-18 and b > a, (a, b, last)
        last = b
    print(f"ivgen OK  {len(c)} chars, 9 prefixes, 2 tdr saves, t_end={last:.4e} s")
