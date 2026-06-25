"""Memory-window cmd generator: erase/program retained-state I-V via fixed-V_G
point reads (no sweep -> no capacitive artifact). Real par (app_opt.par).

CONVERGENCE (critical): gate-ramp legs use instant steps (InitialStep=1e-3
MaxStep=5e-2 MinStep=1e-7 -> 1-2 steps); fine-stepped ramps crawl to MinStep at
negative bias. Digits=5/Tol=1e-5. Writes 5 us = 5*tau_E (full switch), reads 50 ns
<< tau_E (frozen).  gen(mesh, py) -> cmd string.
"""
VGS = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]
RAMP = "InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7"   # instant gate transition

HEAD = """*== Memory-window I-V (memwingen.py): +/-write 5us, fixed-Vg 50ns reads.
File {{ Grid="{mesh}_msh.tdr" Parameter="app_opt.par"
  Plot="opt_outputs/mw_{mesh}_des.tdr" Current="opt_outputs/mw_{mesh}_des.plt" Output="opt_outputs/mw_{mesh}_des.log" }}
Electrode {{ {{Name="source_contact" Voltage=0.0}} {{Name="drain_contact" Voltage=0.0}} {{Name="gate_contact" Voltage=0.0 Workfunction={WF}}} }}
Physics {{ Temperature=300 Areafactor=0.071 Fermi EffectiveIntrinsicDensity(OldSlotboom)
  Mobility(PhuMob Enormal) Recombination(SRH(DopingDependence TempDependence) Auger Band2Band(Model=Hurkx)) }}
Physics(Material="HZO") {{ Polarization }}
Physics(MaterialInterface="Silicon/SiO2") {{ Traps(
  (FixedCharge Conc=7e12 Level EnergyMid=0.0 fromMidBandGap)
  (Acceptor Gaussian fromCondBand Conc=4e12 EnergyMid=0.45 EnergySig=0.30 eXsection=1e-15 hXsection=1e-15)) }}
Math {{ Extrapolate RelErrControl Digits=5 Notdamped=50 Iterations=50 Transient=BE FEPolarizationIP=1.0
  Method=Blocked SubMethod=ParDiSo GeometricDistances Derivative ComputeGradQuasiFermiAtContacts=UseQuasiFermi
  RefDens_eGradQuasiFermi_ElectricField_HFS=1.000e+12 RefDens_hGradQuasiFermi_ElectricField_HFS=1.000e+12
  Method=Bitlis(Restart=100, Tolerance=1e-5, Iterations=200) }}
Plot {{ eDensity hDensity TotalCurrent/Vector ElectricField/Vector Potential SpaceCharge ConductionBand ValenceBand Doping Polarization/Vector }}
CurrentPlot {{ Polarization/Vector (( 0 {py:.5f} )) ElectricField/Vector (( 0 {py:.5f} )) }}
Solve {{
  Transient ( InitialTime=0 FinalTime=1 ) {{ Coupled(Iterations=100) {{Poisson}} }}
  NewCurrentPrefix="drain_bias_"
  Quasistationary ( InitialStep=1e-2 MaxStep=0.1 MinStep=1e-6 Goal{{Name="drain_contact" Voltage={VDS}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}
"""


def _block(state, vwrite, t0, vgs=VGS):
    t1, t2 = t0 + 1e-8, t0 + 1e-8 + 5e-6
    s = (f'  NewCurrentPrefix="{state}_w_rise_"\n  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e} {RAMP}'
         f' Increment=1.4 Goal{{Name="gate_contact" Voltage={vwrite}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}\n'
         f'  NewCurrentPrefix="{state}_w_hold_"\n  Transient ( InitialTime={t1:.6e} FinalTime={t2:.6e}'
         f' InitialStep=1e-11 MaxStep=2e-7 MinStep=1e-15 Increment=1.4 ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}\n')
    t = t2
    for i, vg in enumerate(vgs):
        tr, th = t + 1e-8, t + 1e-8 + 5e-8
        s += (f'  NewCurrentPrefix="{state}_rset{i:02d}_"\n  Transient ( InitialTime={t:.6e} FinalTime={tr:.6e} {RAMP}'
              f' Increment=1.4 Goal{{Name="gate_contact" Voltage={vg}}} ) {{ Coupled(Iterations=100){{Poisson Electron Hole}} }}\n'
              f'  NewCurrentPrefix="{state}_r{i:02d}_"\n  Transient ( InitialTime={tr:.6e} FinalTime={th:.6e}'
              f' InitialStep=1e-11 MaxStep=5e-9 MinStep=1e-15 Increment=1.4 ) {{ Coupled(Iterations=100){{Poisson Electron Hole}}\n'
              f'      CurrentPlot( Time=(Range=({tr:.6e} {th:.6e}) Intervals=5) ) }}\n')
        t = th
    return s, t


def gen(mesh, py, WF=4.35, VE=-2.0, VP=2.0, VDS=0.05, vgs=None):
    vgs = VGS if vgs is None else vgs
    s = HEAD.format(mesh=mesh, py=py, WF=WF, VDS=VDS)
    b1, t = _block("ers", VE, 0.0, vgs)
    b2, _ = _block("pgm", VP, t, vgs)
    return s + b1 + b2 + "}\n"


if __name__ == "__main__":
    c = gen("fe07", 0.007)
    assert "@" not in c and c.count("NewCurrentPrefix") == 41
    print("memwingen OK", len(c), "chars, 41 blocks")
