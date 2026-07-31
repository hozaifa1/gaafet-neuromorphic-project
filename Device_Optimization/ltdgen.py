"""RR-3: LTD (depression) and the symmetric LTP/LTD loop.

The project has potentiation only.  An analog synapse paper needs both branches
and their asymmetry, which is the single biggest scientific gap in the deck.

Built on lifgen.py's blocks (same HEAD / ERASE / BASE, same physics and Math), so
the LTD train is measured with exactly the physics that produced the LTP train.
Two differences from lifgen, both required:

  * pulse polarity is negative (-2.0 V) and the train starts from the FULLY
    POTENTIATED state, so the device is depressed from the top of its range;
  * t_p >= 1 us, NOT the 100 ns used for LTP.  At 100 ns the MFIS depolarization
    field screens the erase: a 100 ns ERS sees only ~26 % of the field a PGM
    pulse of the same magnitude sees, so a 100 ns LTD train barely moves the
    state and the curve reads as "saturated" when it is really just screened.
    100 ns is PGM-only / LIF-spike territory.

Negative-bias convergence (the documented recipe): instant gate ramps
(InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7 -> 1-2 steps) and Digits=5.  Finely
stepped negative ramps crawl down to MinStep and stall.

  gen_ltd(...)     erase -> baseline -> N_ltp potentiate -> N_ltd depress
  gen_cycles(...)  erase -> baseline -> n_cycles x (N_ltp potentiate + N_ltd depress)
"""
import norm  # noqa: F401  (imported for the single-convention invariant; lifgen uses it)
from lifgen import BASE, ERASE, HEAD

# Same as lifgen.LEG but with a settable prefix letter so the potentiation and
# depression halves land in separate files (p01_read_ ... vs d01_read_ ...).
LEG = """  NewCurrentPrefix="{tag}{k:02d}_rise_"
  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e}
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7 Increment=1.4
    Goal {{ Name="gate_contact" Voltage= {VP} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="{tag}{k:02d}_write_"
  Transient ( InitialTime={t1:.6e} FinalTime={t2:.6e}
    InitialStep=1e-11 MaxStep={tp_max:.3e} MinStep=1e-15 Increment=1.4 ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=({t1:.6e} {t2:.6e}) Intervals=8) ) }}
  NewCurrentPrefix="{tag}{k:02d}_fall_"
  Transient ( InitialTime={t2:.6e} FinalTime={t3:.6e}
    InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7 Increment=1.4
    Goal {{ Name="gate_contact" Voltage= {VREAD} }} ) {{ Coupled (Iterations=100) {{Poisson Electron Hole}} }}
  NewCurrentPrefix="{tag}{k:02d}_read_"
  Transient ( InitialTime={t3:.6e} FinalTime={t4:.6e}
    InitialStep=1e-11 MaxStep={tread_max:.3e} MinStep=1e-15 Increment=1.4 ) {{
      Coupled (Iterations=100) {{Poisson Electron Hole}}
      CurrentPlot( Time = (Range=({t3:.6e} {t4:.6e}) Intervals=12) ) }}
"""


def _train(tag_prefix, v_pulse, n, t, t_p, t_read, t_rise, VREAD, k0=1):
    """One pulse train.  Returns (cmd_text, end_time)."""
    s = ""
    for k in range(k0, k0 + n):
        t0 = t
        t1 = t0 + t_rise
        t2 = t1 + t_p
        t3 = t2 + t_rise
        t4 = t3 + t_read
        s += LEG.format(tag=tag_prefix, k=k, t0=t0, t1=t1, t2=t2, t3=t3, t4=t4,
                        VP=v_pulse, VREAD=VREAD,
                        tp_max=max(t_p / 12, 1e-11), tread_max=max(t_read / 10, 1e-11))
        t = t4
    return s, t


def _head(tdr, par, node, WF, VREAD, PROBEY, VDS, TEMP, DIGITS, TOL):
    return HEAD.format(tdr=tdr, par=par, node=node, WF=WF, VREAD=VREAD, PROBEY=PROBEY,
                       VDS=VDS, TEMP=TEMP, DIGITS=DIGITS, TOL=TOL,
                       AREA=norm.AREAFACTOR_USED)


def gen_ltd(tdr, par, node, WF=4.35, VREAD=0.0, PROBEY="0.00700", V_ltp=2.0,
            V_ltd=-2.0, N_ltp=15, N_ltd=15, t_p=1e-6, t_read=100e-9, t_rise=1e-9,
            VDS=0.05, TEMP=300, V_erase=-2.0, t_erase=5e-6, DIGITS=5, TOL=1e-5):
    """Erase -> baseline -> N_ltp potentiating pulses -> N_ltd depressing pulses."""
    s = _head(tdr, par, node, WF, VREAD, PROBEY, VDS, TEMP, DIGITS, TOL)
    t = 0.0
    t0, t1 = t, t + t_rise
    t2, t3 = t1 + t_erase, t1 + t_erase + t_rise
    s += ERASE.format(t0=t0, t1=t1, t2=t2, t3=t3, VERASE=V_erase, VREAD=VREAD,
                      emax=max(t_erase / 10, 1e-11))
    t = t3
    s += BASE.format(t0=t, t1=t + t_read, rmax=max(t_read / 10, 1e-11))
    t += t_read
    a, t = _train("p", V_ltp, N_ltp, t, t_p, t_read, t_rise, VREAD)
    b, t = _train("d", V_ltd, N_ltd, t, t_p, t_read, t_rise, VREAD)
    return s + a + b + "}\n"


def gen_cycles(tdr, par, node, n_cycles=3, WF=4.35, VREAD=0.0, PROBEY="0.00700",
               V_ltp=2.0, V_ltd=-2.0, N_ltp=15, N_ltd=15, t_p=1e-6, t_read=100e-9,
               t_rise=1e-9, VDS=0.05, TEMP=300, V_erase=-2.0, t_erase=5e-6,
               DIGITS=5, TOL=1e-5):
    """n_cycles alternating LTP/LTD trains -> the symmetric loop and its drift."""
    s = _head(tdr, par, node, WF, VREAD, PROBEY, VDS, TEMP, DIGITS, TOL)
    t = 0.0
    t0, t1 = t, t + t_rise
    t2, t3 = t1 + t_erase, t1 + t_erase + t_rise
    s += ERASE.format(t0=t0, t1=t1, t2=t2, t3=t3, VERASE=V_erase, VREAD=VREAD,
                      emax=max(t_erase / 10, 1e-11))
    t = t3
    s += BASE.format(t0=t, t1=t + t_read, rmax=max(t_read / 10, 1e-11))
    t += t_read
    for c in range(n_cycles):
        # global pulse index so file names stay unique and sort in time order
        a, t = _train("p", V_ltp, N_ltp, t, t_p, t_read, t_rise, VREAD,
                      k0=1 + c * N_ltp)
        b, t = _train("d", V_ltd, N_ltd, t, t_p, t_read, t_rise, VREAD,
                      k0=1 + c * N_ltd)
        s += a + b
    return s + "}\n"


if __name__ == "__main__":
    import re

    for name, c in (("ltd", gen_ltd("fe07_msh.tdr", "app_opt.par", "t10_ltd")),
                    ("cycles", gen_cycles("fe07_msh.tdr", "app_opt.par", "t10_cyc"))):
        assert "@" not in c, "stray @ would break SWB token substitution"
        train = c.split("baseline_pre_")[1]
        ts = [float(x) for x in re.findall(r"(?:Initial|Final)Time=([0-9.e+-]+)", train)]
        assert all(b >= a for a, b in zip(ts, ts[1:])), f"{name}: non-monotone time"
        assert "Voltage= -2.0" in c, f"{name}: no negative pulse found"
        n = c.count("NewCurrentPrefix")
        print(f"ltdgen OK  {name}: {len(c)} chars, {n} prefixes, "
              f"t_end = {ts[-1] * 1e6:.1f} us")
