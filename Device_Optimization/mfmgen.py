"""RR-1: MFM capacitor P-E loop cmd generator (TiN / HZO 7 nm / TiN).

Produces the SATURATED material loop that the paper's P_r = 32 uC/cm2,
P_s = 40 uC/cm2, F_c = 1.4 MV/cm claim needs.  The existing
Calibration/csvs/pe_loop_{up,down}.csv are MFIS loops read through the FeFET
gate stack, where the 1 nm SiO2 and the depleted silicon form a capacitive
divider: a +-4 V gate sweep delivers only ~0.77 MV/cm to the HZO, so the loop is
an unsaturated minor loop peaking near 2 uC/cm2.  This run removes the divider.

Design notes
------------
* Transient + Goal only, never Quasistationary.  Quasistationary advances in
  fictitious time, and a Preisach ferroelectric integrates its state in REAL
  time -- a QS ramp either freezes the state or creep-overwrites it depending on
  the step size, and neither is a P-E loop.
* Quasi-static in the physical sense instead: a quarter period of 10 us = 10
  tau_E, so the loop is rate-independent (tau_E = 1e-6 s).
* tau_P = 0, the CALIBRATED material value (cal_n16), NOT the application par's
  1e-5.  tau_P = 1e-5 is a deliberate application choice -- the LIF leakiness
  the device work wants -- and on a quasi-static loop a 10 us relaxation time
  bleeds P_r away between coercive crossings and understates the material.  The
  par is rendered separately as runs/app_mfm.par.
* 2 wake-up cycles before the measured one.  A fresh Preisach model starts
  depolarized and its first loop is not representative.  The model has no
  fatigue term, so unlike real HZO two cycles is already the steady loop.
* Step floor, not step freedom.  The first attempt used MinStep = MaxStep/1e4
  and RelErrControl drove it straight to the floor: 217,080 solver steps to
  cover 3.2 us of a 425 us ramp, and a 143 MB log.  MinStep is now MaxStep/20,
  so the solver either keeps up or fails loudly instead of crawling.
* Two amplitudes: +-1.96 V = 2*F_c*T_fe (the smallest drive that guarantees full
  reversal) and +-3.0 V for saturation margin.  If the two loops do not
  superimpose in P_r, the loop is not saturated.

The measured cycle writes prefixes `down_` (+Vmax -> -Vmax) and `up_`
(-Vmax -> +Vmax).

  gen(vmax, node, par) -> cmd string
"""
import norm

HEAD = """*== RR-1 MFM P-E loop (mfmgen.py): TiN / HZO {tfe_nm:g} nm / TiN, +/-{vmax} V, {ncyc} wake-up cycles.
File {{ Grid="mfm_msh.tdr" Parameter="{par}"
  Plot="opt_outputs/{node}_des.tdr" Current="opt_outputs/{node}_des.plt" Output="opt_outputs/{node}_des.log" }}
Electrode {{ {{Name="top_metal" Voltage=0.0}} {{Name="bot_metal" Voltage=0.0}} }}
Physics {{ Temperature=300 Areafactor=1.0 }}
Physics(Material="HZO") {{ Polarization }}
Math {{ Extrapolate RelErrControl Digits=5 Notdamped=50 Iterations=50 Transient=BE
  FEPolarizationIP=1.0 Method=Blocked SubMethod=ParDiSo GeometricDistances Derivative }}
Plot {{ Polarization/Vector ElectricField/Vector Potential SpaceCharge DisplacementCurrent }}
CurrentPlot {{
  Polarization/Vector (( {xmid:.5f} {ymid:.5f} ))
  ElectricField/Vector (( {xmid:.5f} {ymid:.5f} ))
}}
Solve {{
  Poisson
"""

LEG = """  NewCurrentPrefix="{prefix}"
  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e}
    InitialStep={dt:.6e} MaxStep={dt:.6e} MinStep={dtmin:.6e} Increment=2.0
    Goal{{ Name="top_metal" Voltage={v} }} ) {{ Coupled(Iterations=100) {{ Poisson }}{plot} }}
"""


def gen(vmax=1.96, node="mfm_pe196", par="app_mfm.par", t_quarter=10e-6,
        n_wakeup=2, npts=200, t_fe_um=0.007, l_cap_um=0.100):
    """Triangular P-E loop: 0 -> +V, n_wakeup full cycles, then one measured cycle."""
    dt = t_quarter / 25.0            # 25 solver steps per quarter on the wake-up legs
    dt_meas = 2 * t_quarter / npts   # finer on the measured half-cycles
    s = HEAD.format(tfe_nm=t_fe_um * 1e3, vmax=vmax, ncyc=n_wakeup, par=par, node=node,
                    xmid=l_cap_um / 2.0, ymid=t_fe_um / 2.0)

    t = 0.0
    # rise from the virgin state to +Vmax (a quarter period)
    s += LEG.format(prefix="rise_", t0=t, t1=t + t_quarter, dt=dt, dtmin=dt / 20.0,
                    v=vmax, plot="")
    t += t_quarter

    for k in range(n_wakeup):        # wake-up cycles, not recorded densely
        s += LEG.format(prefix=f"wake{k + 1}d_", t0=t, t1=t + 2 * t_quarter, dt=dt,
                        dtmin=dt / 20.0, v=-vmax, plot="")
        t += 2 * t_quarter
        s += LEG.format(prefix=f"wake{k + 1}u_", t0=t, t1=t + 2 * t_quarter, dt=dt,
                        dtmin=dt / 20.0, v=vmax, plot="")
        t += 2 * t_quarter

    # the measured cycle
    for prefix, v in (("down_", -vmax), ("up_", vmax)):
        t1 = t + 2 * t_quarter
        plot = (f"\n      CurrentPlot( Time=(Range=({t:.6e} {t1:.6e}) Intervals={npts}) )")
        s += LEG.format(prefix=prefix, t0=t, t1=t1, dt=dt_meas, dtmin=dt_meas / 20.0,
                        v=v, plot=plot)
        t = t1

    return s + "}\n"


if __name__ == "__main__":
    for vm, node in ((1.96, "mfm_pe196"), (3.0, "mfm_pe300")):
        c = gen(vm, node)
        assert "@" not in c, "stray @ would break SWB token substitution"
        assert "Quasistationary" not in c, "QS runs in fictitious time -- never for a FE loop"
        assert c.count("NewCurrentPrefix") == 1 + 2 * 2 + 2
        print(f"mfmgen OK  {node}: {len(c)} chars, {c.count('NewCurrentPrefix')} legs, "
              f"E_max = {vm / (0.007e-4) / 1e6:.2f} MV/cm = {vm / (0.007e-4) / 1e6 / 1.4:.2f} F_c")
    print(f"(Areafactor is 1.0 here: P and E come from the mid-FE probe and are "
          f"intensive.  Device convention lives in norm.py, W_eff={norm.W_EFF_UM} um.)")
