"""Generators for the remaining PLOT_PLAN re-runs (RR-2, RR-4, RR-5, RR-6, RR-9).

All share lifgen.py's HEAD (identical physics, Math and probes) so that every new
figure is measured with exactly the physics that produced the existing deck.

  tdr_states  RR-6  erased / programmed .tdr snapshots at V_G = 0 (2D maps)
  idvd        RR-2  I_D-V_DS output family: ERS, PGM and 5 LTP states
  dibl        RR-2  transfer curves at V_DS = 0.05 and 0.5 V
  retention   RR-4  decade-spaced holds out to 10 ms, any state, any temperature
  ret_levels  RR-4  15 LTP levels each held 1 ms (multi-level retention)
  endurance   RR-5  N program/erase cycles with a window read after each decade
  disturb     RR-9  continuous read bias equivalent to 1e6 back-to-back reads
"""
import norm
from lifgen import BASE, ERASE, HEAD

RAMP = "InitialStep=1e-3 MaxStep=5e-2 MinStep=1e-7"   # instant gate transition


def head(node, tdr="fe07_msh.tdr", par="app_opt.par", WF=4.35, VREAD=0.0,
         PROBEY="0.00700", VDS=0.05, TEMP=300, DIGITS=5, TOL=1e-5):
    return HEAD.format(tdr=tdr, par=par, node=node, WF=WF, VREAD=VREAD,
                       PROBEY=PROBEY, VDS=VDS, TEMP=TEMP, DIGITS=DIGITS, TOL=TOL,
                       AREA=norm.AREAFACTOR_USED)


def _goal(prefix, t0, t1, electrode, v, extra=""):
    return (f'  NewCurrentPrefix="{prefix}"\n'
            f'  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e} {RAMP} Increment=1.4'
            f' Goal {{ Name="{electrode}" Voltage= {v} }} ) {{'
            f' Coupled (Iterations=100) {{Poisson Electron Hole}}{extra} }}\n')


def _hold(prefix, t0, t1, intervals=0, maxstep=None):
    """Fixed-bias hold.

    MinStep is a FLOOR at MaxStep/1e4, not an absolute 1e-16.  With
    RelErrControl the solver will happily walk the step size down to whatever
    floor it is given and never come back up -- the first MFM attempt burned
    217,080 steps covering 3.2 us of a 425 us ramp that way, and the first RR-0
    read sweep did the same.  A floor proportional to MaxStep means a 10 ms
    retention hold cannot end up taking 1e-16 s steps; if it genuinely cannot
    converge at that floor it fails loudly instead of crawling for two hours.
    """
    ms = maxstep if maxstep is not None else max((t1 - t0) / 10, 1e-12)
    plot = (f'\n      CurrentPlot( Time = (Range=({t0:.6e} {t1:.6e}) Intervals={intervals}) )'
            if intervals else "")
    return (f'  NewCurrentPrefix="{prefix}"\n'
            f'  Transient ( InitialTime={t0:.6e} FinalTime={t1:.6e}'
            f' InitialStep={ms / 100:.3e} MaxStep={ms:.3e} MinStep={ms / 1e4:.3e}'
            f' Increment=2.0 ) {{'
            f' Coupled (Iterations=100) {{Poisson Electron Hole}}{plot} }}\n')


def _ptsweep(prefix, t0, electrode, values, t_hold=50e-9, hop=1e-8):
    """A sweep built from INSTANT hops between short fixed-bias holds.

    Not a continuous Transient+Goal ramp.  A finely stepped Goal ramp does not
    converge on this device -- the first attempt at RR-0 collapsed to MinStep
    100 ps into a 500 ns gate ramp and sat at 1e-15 s steps until its log hit
    71 MB.  memwingen.py's docstring already records the rule ("fine-stepped
    ramps crawl to MinStep at negative bias"); every node in this project that
    actually completes uses instant hops.  Each hold is short compared with
    tau_E so the ferroelectric state stays frozen across the point.

    Returns (text, end_time).  One .plt per point: <prefix><i:03d>_.
    """
    s, t = "", t0
    for i, v in enumerate(values):
        s += (f'  NewCurrentPrefix="{prefix}s{i:03d}_"\n'
              f'  Transient ( InitialTime={t:.6e} FinalTime={t + hop:.6e} {RAMP}'
              f' Increment=1.4 Goal {{ Name="{electrode}" Voltage= {v} }} ) {{'
              f' Coupled (Iterations=100) {{Poisson Electron Hole}} }}\n')
        t += hop
        s += (f'  NewCurrentPrefix="{prefix}{i:03d}_"\n'
              f'  Transient ( InitialTime={t:.6e} FinalTime={t + t_hold:.6e}'
              f' InitialStep=1e-11 MaxStep={t_hold / 10:.3e} MinStep=1e-15 Increment=1.4 ) {{'
              f' Coupled (Iterations=100) {{Poisson Electron Hole}}\n'
              f'      CurrentPlot( Time = (Range=({t:.6e} {t + t_hold:.6e}) Intervals=5) ) }}\n')
        t += t_hold
    return s, t


def _write(prefix, t, v, t_hold, VREAD, t_rise=1e-9):
    """Ramp to v, hold t_hold, ramp back to VREAD.  Returns (text, end_time)."""
    t1, t2, t3 = t + t_rise, t + t_rise + t_hold, t + 2 * t_rise + t_hold
    s = (_goal(f"{prefix}rise_", t, t1, "gate_contact", v)
         + _hold(f"{prefix}hold_", t1, t2, intervals=8, maxstep=max(t_hold / 12, 1e-12))
         + _goal(f"{prefix}fall_", t2, t3, "gate_contact", VREAD))
    return s, t3


# ------------------------------------------------------------------ RR-6: 2D maps
def tdr_states(node="t13_tdr", V_ers=-2.0, V_pgm=2.0, t_w=5e-6, VREAD=0.0, **kw):
    """Erase, settle at V_G=0, save .tdr; program, settle at V_G=0, save .tdr.

    The Plot block inherited from lifgen already requests eDensity, hDensity,
    ElectricField/Vector, Potential, ConductionBand, ValenceBand, SpaceCharge,
    Doping and Polarization/Vector, so both snapshots carry everything the 2D
    map / band-diagram / vertical-cut figures need.  No .tdr exists anywhere in
    the project today, so this is the cheapest large visual win in the plan.
    """
    s = head(node, VREAD=VREAD, **kw)
    t = 0.0
    a, t = _write("ers_w_", t, V_ers, t_w, VREAD)
    s += a
    s += _hold("ers_settle_", t, t + 100e-9, intervals=10)
    t += 100e-9
    s += f'  Plot ( FilePrefix="opt_outputs/state_erased_{node}" )\n'
    b, t = _write("pgm_w_", t, V_pgm, t_w, VREAD)
    s += b
    s += _hold("pgm_settle_", t, t + 100e-9, intervals=10)
    t += 100e-9
    s += f'  Plot ( FilePrefix="opt_outputs/state_programmed_{node}" )\n'
    return s + "}\n"


# ------------------------------------------------------- RR-2: output characteristics
VDS_GRID = [round(0.05 * i, 3) for i in range(21)]      # 0 .. 1.0 V in 50 mV steps


def idvd(node="t11_idvd", vg_list=(0.0, 0.2), ltp_at=(3, 6, 9, 12, 15),
         V_ers=-2.0, V_pgm=2.0, t_w=5e-6, t_p=0.3e-6, vds_grid=None,
         VREAD=0.0, **kw):
    """I_D-V_DS families: erased, fully programmed, then 5 analog LTP states.

    Every device paper has an output characteristic and this project has none.
    The drain is stepped in instant hops between 50 ns holds (see _ptsweep) --
    a continuous ramp does not converge here.  Holding 21 points costs ~1.3 us
    per family, well under tau_P = 10 us, so the retained state survives a sweep.
    The analysis reads the conduction current (eCurrent + hCurrent), so the
    dV_DS/dt displacement term through the overlap is removed exactly.

    t_p = 0.3 us, NOT 1 us.  It must match the canonical LTP train (t8_ltp,
    +2.0 V / 0.3 us) or the "5 analog states" in this figure are not the analog
    states in the LTP figure.  A first version used 1 us and put level 15 at
    25.3 uA/um against the LTP curve's 8.32 -- a three-fold discrepancy that is
    purely protocol, and exactly the kind of cross-figure mismatch this whole
    audit exists to remove.
    """
    vds_grid = vds_grid or VDS_GRID
    s = head(node, VREAD=VREAD, **kw)
    t = 0.0

    def family(tag, t):
        out = ""
        for i, vg in enumerate(vg_list):
            out += _goal(f"{tag}_g{i}set_", t, t + 1e-9, "gate_contact", vg)
            t += 1e-9
            blk, t = _ptsweep(f"{tag}_g{i}d", t, "drain_contact", vds_grid)
            out += blk
            out += _goal(f"{tag}_g{i}rst_", t, t + 1e-9, "drain_contact", 0.05)
            t += 1e-9
            out += _goal(f"{tag}_g{i}g0_", t, t + 1e-9, "gate_contact", VREAD)
            t += 1e-9
        return out, t

    a, t = _write("ers_w_", t, V_ers, t_w, VREAD)
    s += a
    b, t = family("ers", t)
    s += b
    a, t = _write("pgmfull_w_", t, V_pgm, t_w, VREAD)
    s += a
    b, t = family("pgm", t)
    s += b

    # analog family: re-erase, then walk the LTP train, sweeping at the chosen pulses
    a, t = _write("re_ers_", t, V_ers, t_w, VREAD)
    s += a
    for k in range(1, max(ltp_at) + 1):
        a, t = _write(f"l{k:02d}_", t, V_pgm, t_p, VREAD)
        s += a
        s += _hold(f"l{k:02d}_read_", t, t + 100e-9, intervals=10)
        t += 100e-9
        if k in ltp_at:
            b, t = family(f"ltp{k:02d}", t)
            s += b
    return s + "}\n"


VG_GRID = [round(-0.5 + 0.05 * i, 3) for i in range(31)]   # -0.5 .. +1.0 V


def dibl(node="t11_dibl", vds_list=(0.05, 0.5), vg_grid=None,
         V_ers=-2.0, V_pgm=2.0, t_w=5e-6, VREAD=0.0, **kw):
    """Transfer curves at two V_DS, both retained states -> DIBL = -dV_t/dV_DS.

    The state is rewritten before each of the four sweeps, so no sweep inherits
    the creep of the one before it.
    """
    vg_grid = vg_grid or VG_GRID
    s = head(node, VREAD=VREAD, **kw)
    t = 0.0
    for tag, vw in (("ers", V_ers), ("pgm", V_pgm)):
        for j, vds in enumerate(vds_list):
            a, t = _write(f"{tag}{j}_w_", t, vw, t_w, VREAD)
            s += a
            s += _goal(f"{tag}{j}_vdset_", t, t + 1e-9, "drain_contact", vds)
            t += 1e-9
            blk, t = _ptsweep(f"{tag}{j}_g", t, "gate_contact", vg_grid)
            s += blk
            s += _goal(f"{tag}{j}_rst_", t, t + 1e-9, "gate_contact", VREAD)
            t += 1e-9
            s += _goal(f"{tag}{j}_vdrst_", t, t + 1e-9, "drain_contact", 0.05)
            t += 1e-9
    return s + "}\n"


# ---------------------------------------------------------------- RR-4: retention
DECADES = [(1e-7, 1e-6), (1e-6, 1e-5), (1e-5, 1e-4), (1e-4, 1e-3), (1e-3, 1e-2)]


def retention(node="t12_ret", t_max=1e-2, n_pulse=0, V_pgm=2.0, V_ers=-2.0,
              t_w=5e-6, t_p=1e-6, VREAD=0.0, per_decade=20, **kw):
    """Erase, write the target state, then hold at V_G = 0 out to t_max.

    n_pulse = 0 writes the FULLY programmed state (one 5 us +2 V write);
    n_pulse = k writes LTP level k (k sub-coercive 1 us pulses) instead, which is
    the mid-state retention reviewers actually doubt.

    CurrentPlot is decade-spaced rather than linear: a linear grid over 10 ms
    puts every sample in the last decade and completely misses the fast
    depolarization transient, which is where all the physics is.
    """
    s = head(node, VREAD=VREAD, **kw)
    t = 0.0
    a, t = _write("ers_w_", t, V_ers, t_w, VREAD)
    s += a
    if n_pulse == 0:
        a, t = _write("pgm_w_", t, V_pgm, t_w, VREAD)
        s += a
    else:
        for k in range(1, n_pulse + 1):
            a, t = _write(f"p{k:02d}_", t, V_pgm, t_p, VREAD)
            s += a
    t0 = t
    s += _hold("hold_d0_", t, t + 1e-7, intervals=per_decade, maxstep=1e-8)
    t += 1e-7
    for i, (lo, hi) in enumerate(DECADES, start=1):
        if lo >= t_max:
            break
        hi = min(hi, t_max)
        s += _hold(f"hold_d{i}_", t, t0 + hi, intervals=per_decade, maxstep=hi / 20)
        t = t0 + hi
    return s + "}\n"


def ret_levels(node="t12_ret15", n_lvl=15, t_hold=1e-3, V_pgm=2.0, V_ers=-2.0,
               t_w=5e-6, t_p=1e-6, VREAD=0.0, **kw):
    """Multi-level retention: each LTP level is held t_hold before the next pulse.

    CAVEAT to state in the caption: the levels share one cumulative history, so
    level k is "level k, aged t_hold, on top of k-1 previously aged levels".
    Fifteen independent runs would isolate them; that is 15 licenses-hours on a
    contended single-license host, and the cumulative form is what an actual
    analog write-then-wait workload looks like anyway.
    """
    s = head(node, VREAD=VREAD, **kw)
    t = 0.0
    a, t = _write("ers_w_", t, V_ers, t_w, VREAD)
    s += a
    for k in range(1, n_lvl + 1):
        a, t = _write(f"p{k:02d}_", t, V_pgm, t_p, VREAD)
        s += a
        s += _hold(f"h{k:02d}_", t, t + t_hold, intervals=30, maxstep=t_hold / 40)
        t += t_hold
    return s + "}\n"


# ---------------------------------------------------------------- RR-5: endurance
def endurance(node="t14_end10", n_cycles=10, V_pgm=2.0, V_ers=-2.0, t_p=1e-6,
              VREAD=0.0, read_at=(1, 10, 100, 1000, 10000), **kw):
    """n_cycles of +-2.0 V / 1 us program-erase, with a retained window read at
    each decade.

    HONEST CAVEAT, and it must go in the caption: the Sentaurus Preisach model
    has no fatigue, no wake-up and no imprint term.  Cycling it cannot produce
    window closure -- any flatness here is a property of the model, not evidence
    that the device is immune to degradation.  What this run legitimately shows
    is that the *numerics* are cycle-stable (no drift, no accumulation of solver
    error) and that the switched charge per cycle is reproducible.  Real
    endurance is a measurement, not a TCAD result.
    """
    s = head(node, VREAD=VREAD, **kw)
    t = 0.0
    for c in range(1, n_cycles + 1):
        t1, t2 = t + 1e-9, t + 1e-9 + t_p
        s += _goal(f"c{c}p_", t, t1, "gate_contact", V_pgm)
        s += _hold(f"c{c}ph_", t1, t2, intervals=0, maxstep=t_p / 4)
        t3, t4 = t2 + 1e-9, t2 + 1e-9 + t_p
        s += _goal(f"c{c}e_", t2, t3, "gate_contact", V_ers)
        s += _hold(f"c{c}eh_", t3, t4, intervals=0, maxstep=t_p / 4)
        t = t4
        if c in read_at:
            # window read: erased level, then program, then programmed level
            s += _goal(f"w{c}_g0a_", t, t + 1e-9, "gate_contact", VREAD)
            t += 1e-9
            s += _hold(f"w{c}_ers_", t, t + 100e-9, intervals=8)
            t += 100e-9
            a, t = _write(f"w{c}_pgm_", t, V_pgm, t_p * 5, VREAD)
            s += a
            s += _hold(f"w{c}_on_", t, t + 100e-9, intervals=8)
            t += 100e-9
    return s + "}\n"


# -------------------------------------------------------------- RR-9: read disturb
def disturb(node="t15_disturb", n_reads=1_000_000, t_read=100e-9, V_pgm=2.0,
            V_ers=-2.0, t_w=5e-6, VREAD=0.0, **kw):
    """Window before and after a continuous read bias equal to n_reads x t_read.

    1e6 back-to-back 100 ns reads is 100 ms of uninterrupted V_G = 0 / V_DS =
    0.05 V bias.  Simulating them as one continuous hold is exactly equivalent
    for a model whose only read-side dynamics are depolarization and trapping,
    and it is 1e6 times cheaper than writing out a million read legs.
    """
    t_total = n_reads * t_read
    s = head(node, VREAD=VREAD, **kw)
    t = 0.0
    a, t = _write("ers_w_", t, V_ers, t_w, VREAD)
    s += a
    s += _hold("pre_ers_", t, t + 100e-9, intervals=8)
    t += 100e-9
    a, t = _write("pgm_w_", t, V_pgm, t_w, VREAD)
    s += a
    s += _hold("pre_pgm_", t, t + 100e-9, intervals=8)
    t += 100e-9
    t0 = t
    s += _hold("read_d0_", t, t + 1e-7, intervals=20, maxstep=1e-8)
    t += 1e-7
    for i, (lo, hi) in enumerate([(1e-7, 1e-6), (1e-6, 1e-5), (1e-5, 1e-4),
                                  (1e-4, 1e-3), (1e-3, 1e-2), (1e-2, 1e-1)], start=1):
        if lo >= t_total:
            break
        hi = min(hi, t_total)
        s += _hold(f"read_d{i}_", t, t0 + hi, intervals=20, maxstep=hi / 20)
        t = t0 + hi
    s += _hold("post_pgm_", t, t + 100e-9, intervals=8)
    t += 100e-9
    return s + "}\n"


if __name__ == "__main__":
    import re

    cases = [
        ("tdr_states", tdr_states()),
        ("idvd", idvd()),
        ("dibl", dibl()),
        ("retention 10ms", retention()),
        ("retention lvl8", retention(node="t12_ret_l8", n_pulse=8, t_max=1e-3)),
        ("ret_levels", ret_levels()),
        ("endurance 100", endurance(node="t14_end100", n_cycles=100)),
        ("disturb 1e6", disturb()),
    ]
    for name, c in cases:
        assert "@" not in c, f"{name}: stray @ would break SWB token substitution"
        # Only the two DC-setup ramps in HEAD may be Quasistationary; everything
        # that touches the ferroelectric state must be Transient (QS advances in
        # fictitious time and creep-overwrites a Preisach state).
        assert c.count("Quasistationary") == 2, f"{name}: unexpected Quasistationary"
        body = "NewCurrentPrefix".join(c.split("NewCurrentPrefix")[3:])
        ts = [float(x) for x in re.findall(r"(?:Initial|Final)Time=([0-9.e+-]+)", body)]
        assert all(b >= a - 1e-18 for a, b in zip(ts, ts[1:])), f"{name}: non-monotone time"
        print(f"rrgen OK  {name:16s} {len(c):8d} chars  {c.count('NewCurrentPrefix'):5d} legs  "
              f"t_end = {ts[-1]:.4e} s")
