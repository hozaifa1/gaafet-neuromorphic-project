"""RR-0: retained-state I_D-V_GS on a dense fixed-V_G read grid.

WHY THIS FILE WAS REWRITTEN (2026-08-01)
----------------------------------------
Round 1.  The original generator wrote its .cmd against `app_frozen.par`
(tau_E = tau_P = 1e-4) with a 500 us write hold, on the reasoning "hold >> tau_E
gives a full switch, read << tau_E keeps it frozen".  The switching half is
right; the retention half is not.  tau_P = 1e-4 means that hold is five
depolarization time constants, so whatever the field switches, the model relaxes
back inside the same hold.  The `iv_fe07` node it produced is measurably dead --
the FE-midpoint probe reads

    Pos(0,0.007) Polarization/y = +2.3267e-07 C/cm2 (erased)
                                = +2.3238e-07 C/cm2 (programmed)

0.1 % apart, and the two I-V branches coincide above V_G = +0.2 V.  Everything
derived from it, including csv_export/raw/memory_window_iv.csv (figure D1), was
meaningless.  tau_E must be short to switch and tau_P long to retain, so
tau_E << tau_P: exactly `app.par` (1e-6 / 1e-5).

Round 2.  The first replacement read the retained state with ONE continuous
500 ns V_G ramp driven by Transient+Goal.  It does not converge.  The solver
collapsed to MinStep 100 ps into the sweep and sat at 1e-15 s steps until the log
reached 71 MB; the job would never have finished.  This is precisely the failure
memwingen.py's docstring already warns about -- "fine-stepped ramps crawl to
MinStep at negative bias" -- and the reason every working node in this project
uses INSTANT gate transitions (InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7, i.e.
one or two steps) between short fixed-V_G holds.

So RR-0 is now memwingen's proven protocol on a denser grid: the same +-2.0 V /
5 us writes, the same instant hops, the same 50 ns frozen reads -- just 41 read
points from -1.0 to +1.0 V in 50 mV steps instead of mwfine's 19, plus a .tdr
snapshot of each retained state for the 2D maps (RR-6).  It supersedes both the
dead frozen-par node and the 9-point mw_fe07 grid, and it is measured with the
identical physics that produced every published window number.

The cost of point reads is that the state creeps slightly across the sweep: 41
reads x 60 ns = 2.5 us of elapsed bias, about 2.5 tau_E.  That is the same
regime mwfine already operates in, and it is why mwfine and mw_fe07 disagree by
21 % at V_G = 0 -- a real, documented property of the read protocol, not an
error.  A continuous sweep would avoid it but does not converge, and a sweep the
solver cannot finish is worth less than a 21 % protocol offset that can be
stated.

  gen(mesh, py, node=..., par=...) -> cmd string
"""
import memwingen

# -1.0 .. +1.0 V in 50 mV steps: 41 points, vs mwfine's 19 over -0.4..+0.5 V.
VGS = [round(-1.0 + 0.05 * i, 3) for i in range(41)]


def gen(mesh, py, node=None, par="app_opt.par", WF=4.35, VE=-2.0, VP=2.0,
        VDS=0.05, vgs=None):
    return memwingen.gen(mesh, py, WF=WF, VE=VE, VP=VP, VDS=VDS,
                         vgs=vgs or VGS, par=par, node=node or f"iv_{mesh}",
                         save_states=True)


if __name__ == "__main__":
    import re

    c = gen("fe07", 0.007, node="iv_fe07b", par="app_iv_fe07b.par")
    assert "@" not in c, "stray @ would break SWB token substitution"
    assert "app_frozen" not in c
    assert c.count("Save ( FilePrefix") == 2
    # 1 drain_bias_ + per state (w_rise, w_hold) + per state per read point (rset, read)
    assert c.count("NewCurrentPrefix") == 1 + 2 * (2 + 2 * len(VGS)), c.count("NewCurrentPrefix")
    # no fine-stepped Goal ramp may survive: every gate transition is instant
    assert "MinStep=1e-16" not in c and "MinStep=1e-17" not in c
    pairs = re.findall(r"InitialTime=([0-9.e+-]+) FinalTime=([0-9.e+-]+)", c)
    last = -1.0
    for a, b in pairs[1:]:
        a, b = float(a), float(b)
        assert a >= last - 1e-18 and b > a, (a, b, last)
        last = b
    print(f"ivgen OK  {len(c)} chars, {len(VGS)} read points/branch, "
          f"2 tdr saves, t_end={last:.4e} s")
