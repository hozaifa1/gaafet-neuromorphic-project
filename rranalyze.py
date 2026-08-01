"""Analysis + export for every PLOT_PLAN re-run.  One function per output CSV.

    python rranalyze.py rr0        RR-0  retained I-V           -> raw/memory_window_iv.csv
    python rranalyze.py rr1        RR-1  MFM P-E loop           -> Calibration/csvs/mfm_pe_loop.csv
    python rranalyze.py rr2        RR-2  output family + DIBL   -> raw/output_char.csv
    python rranalyze.py rr3        RR-3  LTD + LTP/LTD cycles   -> raw/ltd_depression.csv, raw/ltp_ltd_cycles.csv
    python rranalyze.py rr4        RR-4  long retention         -> raw/retention_long.csv
    python rranalyze.py rr5        RR-5  endurance              -> raw/endurance.csv
    python rranalyze.py rr7        RR-7  V_pgm x t_p grid       -> sweeps/vpgm_tp_grid.csv
    python rranalyze.py rr8        RR-8  variability ensemble   -> raw/variability_ensemble.csv
    python rranalyze.py rr9        RR-9  read disturb           -> raw/read_disturb.csv
    python rranalyze.py rr10       RR-10 Areafactor sanity      -> prints the exactness check
    python rranalyze.py all        everything whose data is on disk

Currents are reported through norm.to_uA_per_um -- the one width convention.
Where a fast voltage ramp is involved the CONDUCTION current (eCurrent +
hCurrent) is used, not TotalCurrent, so the dV/dt displacement term through the
gate-drain overlap is removed exactly instead of being argued away.
"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent
DEVOPT = ROOT / "Device_Optimization"
sys.path.insert(0, str(DEVOPT))
import norm                       # noqa: E402
from plt2csv import parse_plt     # noqa: E402

OUTPUTS = DEVOPT / "outputs"
RAW = DEVOPT / "csv_export" / "raw"
SWEEPS = DEVOPT / "csv_export" / "sweeps"
CALCSV = ROOT / "Calibration" / "csvs"

ID = "drain_contact TotalCurrent"
IE = "drain_contact eCurrent"
IH = "drain_contact hCurrent"
VG = "gate_contact OuterVoltage"
VD = "drain_contact OuterVoltage"
QG = "gate_contact Charge"
VDS_READ = 0.05


# ------------------------------------------------------------------ helpers
def _probe(df, kind):
    """The Pos(...) probe column name varies with the probe coordinates."""
    for c in df.columns:
        if c.startswith("Pos(") and c.endswith(kind):
            return c
    raise KeyError(f"no probe column ending in {kind}: {list(df.columns)}")


def cond_uA(df):
    """Conduction current in uA/um -- drops the displacement term."""
    if IE in df.columns and IH in df.columns:
        return norm.to_uA_per_um(np.abs(df[IE].values + df[IH].values))
    return norm.to_uA_per_um(np.abs(df[ID].values))


def total_uA(df):
    return norm.to_uA_per_um(np.abs(df[ID].values))


def last(node, prefix):
    fp = OUTPUTS / node / f"{prefix}{node}_des.plt"
    return parse_plt(fp).iloc[-1] if fp.exists() else None


def series(node, prefix):
    fp = OUTPUTS / node / f"{prefix}{node}_des.plt"
    return parse_plt(fp) if fp.exists() else None


def have(node, *prefixes):
    return all((OUTPUTS / node / f"{p}{node}_des.plt").exists() for p in prefixes)


def vth_cc(vg, idd, icc):
    vg, idd = np.asarray(vg, float), np.asarray(idd, float)
    for k in range(1, len(vg)):
        if idd[k - 1] < icc <= idd[k] and idd[k] > idd[k - 1]:
            f = ((np.log10(icc) - np.log10(idd[k - 1]))
                 / (np.log10(idd[k]) - np.log10(idd[k - 1])))
            return float(vg[k - 1] + f * (vg[k] - vg[k - 1]))
    return float("nan")


def ss_mv_dec(vg, idd, min_decades=2.0, guard_decades=1.0):
    """SS in mV/dec from a straight-line fit over the clean subthreshold region.

    NOT the steepest adjacent pair.  On a 50 mV grid a single pair spans a whole
    decade, so one glitchy point fakes a sub-thermal slope: the RR-0 programmed
    branch has a non-monotonic point at V_G = -0.55 V (3.3e-6 uA/um between
    9.4e-6 and 4.2e-5) that alone reported SS = 45 mV/dec, i.e. below the 60
    mV/dec Boltzmann limit.  Claiming sub-thermal switching off a numerical
    glitch is exactly the kind of thing a reviewer catches.

    Instead: over every strictly-increasing window that spans at least
    `min_decades`, fit log10(I) vs V_G and keep the STEEPEST fit.  Requiring two
    decades means no single point can carry the answer; taking the steepest
    (rather than the widest) window keeps the fit inside the subthreshold region
    instead of dragging it up into saturation.
    """
    vg, idd = np.asarray(vg, float), np.asarray(idd, float)
    li = np.log10(np.maximum(idd, 1e-30))
    # An n-FeFET's off state is an ambipolar V: the hole branch falls, hits a
    # minimum, then the electron branch rises.  The first points out of that
    # minimum are a branch crossover, not subthreshold conduction, and they read
    # artificially steep.  Require the fit to start at least `guard_decades`
    # above the minimum so the crossover cannot set the answer.
    floor = float(np.min(li)) + guard_decades
    best = np.inf
    i = 0
    while i < len(vg) - 1:                       # walk maximal increasing runs
        j = i
        while j < len(vg) - 1 and li[j + 1] > li[j]:
            j += 1
        for a in range(i, j):
            if li[a] < floor:
                continue
            for b in range(a + 2, j + 1):        # >= 3 points in the fit
                if li[b] - li[a] < min_decades:
                    continue
                p = np.polyfit(vg[a:b + 1], li[a:b + 1], 1)
                if p[0] > 0:
                    best = min(best, abs(1000.0 / p[0]))
        i = max(j, i + 1)
    return float(best) if np.isfinite(best) else float("nan")


def nonlinearity(g):
    """Fit G_n = (1 - exp(-nA)) / (1 - exp(-NA)) to a normalized train; return A.

    A -> 0 is a perfectly linear synapse; large A is a strongly saturating one.
    Scanned rather than optimized: one parameter, a smooth objective, and no
    dependency worth adding for it.
    """
    g = np.asarray(g, float)
    gn = (g - g.min()) / (g.max() - g.min())
    n = np.arange(1, len(g) + 1)
    N = len(g)
    best, bestA = np.inf, np.nan
    for A in np.concatenate([-np.geomspace(1e-3, 10, 400)[::-1], np.geomspace(1e-3, 10, 400)]):
        model = (1 - np.exp(-n * A)) / (1 - np.exp(-N * A))
        r = float(np.sum((model - gn) ** 2))
        if r < best:
            best, bestA = r, float(A)
    ss_tot = float(np.sum((gn - gn.mean()) ** 2))
    r2 = 1.0 - best / ss_tot if ss_tot > 0 else float("nan")
    return bestA, r2


def pulse_span(g, lo=0.1, hi=0.9):
    """Pulses needed to cross lo..hi of the normalized range.

    A model-free companion to A: it does not assume the curve is a saturating
    exponential, which matters because these trains are not. Both branches show
    an incubation delay -- the first two or three 1 us pulses move the state
    almost not at all, then it swings four decades in three pulses -- so the
    curve is sigmoidal and the one-parameter exponential cannot represent it.
    """
    g = np.asarray(g, float)
    gn = (g - g.min()) / (g.max() - g.min())
    if gn[-1] < gn[0]:
        gn = gn[::-1]
    n = np.arange(1, len(gn) + 1)
    return float(np.interp(hi, gn, n) - np.interp(lo, gn, n))


def _emit(df, path, label):
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False, float_format="%.6e")
    print(f"  -> {path.relative_to(ROOT)}  ({len(df)} rows)  [{label}]")


# ------------------------------------------------------------------- RR-0
def rr0(node="iv_fe07b"):
    """Retained I-V on the 41-point fixed-V_G grid -> the corrected figure D1.

    One .plt per read point (ers_rNN_ / pgm_rNN_), each a short frozen hold, so
    the settled last row of each file is the measurement.  Supersedes both the
    dead frozen-par iv_fe07 node and the 9-point mw_fe07 grid.
    """
    import re as _re
    d = OUTPUTS / node
    # memwingen names the instant hop legs <state>_rsetNN_ and the reads
    # <state>_rNN_; a "*_r*" glob matches both, so match the read files exactly.
    read_re = _re.compile(rf"^(ers|pgm)_r(\d\d)_{node}_des\.plt$")
    if not d.exists() or not any(read_re.match(f.name) for f in d.glob("*.plt")):
        print(f"rr0: no data for {node} yet")
        return
    rows = {}
    for state in ("ers", "pgm"):
        vg, idd, tot, py = [], [], [], []
        for f in sorted(f for f in d.glob("*.plt")
                        if (m := read_re.match(f.name)) and m.group(1) == state):
            x = parse_plt(f)
            if not len(x):
                continue
            r = x.iloc[[-1]]
            vg.append(float(r[VG].iloc[0]))
            idd.append(float(cond_uA(r)[0]))
            tot.append(float(total_uA(r)[0]))
            py.append(float(r[_probe(x, "Polarization/y")].iloc[0]))
        o = np.argsort(vg)
        rows[state] = (np.array(vg)[o], np.array(idd)[o], np.array(tot)[o], np.array(py)[o])

    ve, ie, te, pye = rows["ers"]
    vp, ip, tp, pyp = rows["pgm"]
    n = min(len(ve), len(vp))
    out = pd.DataFrame({
        "Vg_V": ve[:n],
        "Id_erased_uA_um": ie[:n], "Id_programmed_uA_um": ip[:n],
        "Id_erased_total_uA_um": te[:n], "Id_programmed_total_uA_um": tp[:n],
        "Py_erased_C_cm2": pye[:n], "Py_programmed_C_cm2": pyp[:n],
    })
    _emit(out, RAW / "memory_window_iv.csv", "RR-0 retained I-V, 41-point grid")

    icc = 1e-2 * norm.CORR
    vt_e = vth_cc(out.Vg_V, out.Id_erased_uA_um, icc)
    vt_p = vth_cc(out.Vg_V, out.Id_programmed_uA_um, icc)
    i0 = int(np.argmin(np.abs(out.Vg_V)))
    ion, ioff = out.Id_programmed_uA_um[i0], out.Id_erased_uA_um[i0]
    print(f"  V_t,ers = {vt_e:+.4f} V   V_t,pgm = {vt_p:+.4f} V   MW = {vt_e - vt_p:.4f} V")
    print(f"  SS(pgm) = {ss_mv_dec(out.Vg_V, out.Id_programmed_uA_um):.1f} mV/dec   "
          f"SS(ers) = {ss_mv_dec(out.Vg_V, out.Id_erased_uA_um):.1f} mV/dec")
    print(f"  @V_G=0  ON {ion:.4g}  OFF {ioff:.4g} uA/um  ->  {ion / ioff:.0f}x")
    print(f"  retained P_y @V_G=0: erased {out.Py_erased_C_cm2[i0]:+.4e}  programmed "
          f"{out.Py_programmed_C_cm2[i0]:+.4e} C/cm2")
    print(f"     dP = {out.Py_programmed_C_cm2[i0] - out.Py_erased_C_cm2[i0]:+.4e} C/cm2 "
          f"(the dead frozen-par node had both states at +2.33e-7, dP = 3e-10)")


# ------------------------------------------------------------------- RR-1
def rr1(nodes=("mfm_pe196", "mfm_pe300", "mfm_pe500")):
    """MFM P-E loop amplitude series -> the real P_r / P_s / F_c.

    Three amplitudes, because 2*F_c*T_fe does NOT saturate a Preisach loop --
    it approaches P_s asymptotically, so +-1.96 V returns a large minor loop
    (P_s 32.8 against a nominal 40) and would have looked like a calibration
    failure. Driving to ~5 F_c reproduces the locked par to four significant
    figures. The series is kept, not just the saturated point: it is the
    evidence that the loop IS saturated rather than an assertion that it is.
    """
    frames = []
    for node in nodes:
        if not have(node, "down_", "up_"):
            print(f"rr1: no data for {node} yet")
            continue
        for branch in ("down", "up"):
            d = series(node, f"{branch}_")
            pcol, ecol = _probe(d, "Polarization/y"), _probe(d, "ElectricField/y")
            frames.append(pd.DataFrame({
                "node": node,
                "vmax_V": float(np.abs(d["top_metal OuterVoltage"]).max()),
                "branch": branch,
                "t_s": d["time"].values,
                "V_V": d["top_metal OuterVoltage"].values,
                "P_uC_cm2": d[pcol].values * 1e6,
                "E_MV_cm": d[ecol].values * 1e-6,
            }))
    if not frames:
        return
    out = pd.concat(frames, ignore_index=True)
    _emit(out, CALCSV / "mfm_pe_loop.csv", "RR-1 MFM P-E")

    print("  node        branch   P_s        P_r(E=0)   F_c(P=0)")
    for (node, branch), g in out.groupby(["node", "branch"], sort=False):
        e, p = g.E_MV_cm.values, g.P_uC_cm2.values
        o = np.argsort(e)
        p_r = float(np.interp(0.0, e[o], p[o]))
        # coercive field: where P crosses zero along the branch
        f_c = float("nan")
        for k in range(1, len(p)):
            if (p[k - 1] < 0 <= p[k]) or (p[k - 1] > 0 >= p[k]):
                f_c = float(e[k - 1] + (0 - p[k - 1]) * (e[k] - e[k - 1]) / (p[k] - p[k - 1]))
                break
        print(f"  {node:11s} {branch:6s} {np.abs(p).max():8.2f}   {p_r:+8.2f}   {f_c:+8.3f}")
    print("  targets: P_s 40, |P_r| 32 uC/cm2, |F_c| 1.4 MV/cm (the locked cal_n16 par).")
    print("  The par is never tuned to match this run -- the run validates the par.")


# ------------------------------------------------------------------- RR-2
def rr2(node="t11_idvd", dnode="t11_dibl"):
    """I_D-V_DS output family and the DIBL pair.

    Both are point sweeps (instant hop -> short hold -> one .plt per point), so
    each file contributes its settled last row rather than a whole curve.
    File names are <state>_g<i>d<NNN>_<node>_des.plt for the output family and
    <state><j>_g<NNN>_<node>_des.plt for the DIBL transfer pair.
    """
    import re as _re
    rows = []
    pat = _re.compile(rf"^(?P<state>.+)_g(?P<gi>\d)d(?P<pt>\d{{3}})_{node}_des\.plt$")
    if (OUTPUTS / node).exists():
        for f in sorted((OUTPUTS / node).glob(f"*_{node}_des.plt")):
            m = pat.match(f.name)
            if not m:
                continue
            r = parse_plt(f).iloc[[-1]]
            rows.append({"state": m["state"], "vg_idx": int(m["gi"]),
                         "point": int(m["pt"]), "Vg_V": float(r[VG].iloc[0]),
                         "Vds_V": float(r[VD].iloc[0]),
                         "Id_uA_um": float(cond_uA(r)[0])})
    if rows:
        out = pd.DataFrame(rows).sort_values(["state", "vg_idx", "point"])
        _emit(out, RAW / "output_char.csv", "RR-2 output characteristics")
        print("  ohmic check (I_D at low V_DS should be linear in V_DS):")
        for (st, vi), g in out.groupby(["state", "vg_idx"]):
            m = (g.Vds_V > 0) & (g.Vds_V < 0.15)
            if m.sum() > 3:
                r = np.corrcoef(g.Vds_V[m], g.Id_uA_um[m])[0, 1]
                print(f"    {st:12s} vg{vi}  r(V_DS, I_D) = {r:.4f} over 0..0.15 V")
    else:
        print(f"rr2: no data for {node} yet")

    dd = OUTPUTS / dnode
    if dd.exists():
        rows = []
        dpat = _re.compile(rf"^(?P<state>ers|pgm)(?P<j>\d)_g(?P<pt>\d{{3}})_{dnode}_des\.plt$")
        for f in sorted(dd.glob(f"*_{dnode}_des.plt")):
            m = dpat.match(f.name)
            if not m:
                continue
            r = parse_plt(f).iloc[[-1]]
            rows.append({"state": m["state"], "vds_idx": int(m["j"]), "point": int(m["pt"]),
                         "Vds_V": float(r[VD].iloc[0]), "Vg_V": float(r[VG].iloc[0]),
                         "Id_uA_um": float(cond_uA(r)[0])})
        if rows:
            out = pd.DataFrame(rows).sort_values(["state", "vds_idx", "point"])
            _emit(out, RAW / "dibl_transfer.csv", "RR-2 DIBL transfer pair")

            # DIBL needs ONE criterion that all four curves actually cross. The
            # default I_cc = 6.34e-3 uA/um does not work here: the programmed
            # branch at V_DS = 0.5 V never falls below 2.7e-2 uA/um anywhere in
            # the -0.5..+1.0 V window, so its V_t is simply not defined at that
            # level and the extraction returns NaN. Pick the lowest decade that
            # every curve crosses instead, and say which one was used.
            groups = {k: g.sort_values("Vg_V") for k, g in out.groupby(["state", "vds_idx"])}
            icc = None
            for cand in (1e-2 * norm.CORR, 1e-2, 1e-1, 1e0):
                if all(g.Id_uA_um.min() < cand < g.Id_uA_um.max() for g in groups.values()):
                    icc = cand
                    break
            if icc is None:
                print("  no common V_t criterion crosses all four curves -- widen the sweep")
                return
            print(f"  V_t criterion I_cc = {icc:.4g} uA/um "
                  f"(lowest level crossed by all four curves)")
            vt = {}
            for (st, j), g in groups.items():
                vt[(st, round(float(g.Vds_V.iloc[0]), 3))] = vth_cc(g.Vg_V, g.Id_uA_um, icc)
            for k, v in sorted(vt.items()):
                print(f"    V_t {k[0]} @ V_DS={k[1]} V : {v:+.4f} V")
            # A fixed-current criterion is confounded across two V_DS values: in the
            # linear region I_D itself scales with V_DS, so the crossing moves by
            # about SS*log10(V_DS2/V_DS1) with no electrostatics involved at all
            # (~64 mV here for SS = 63.5 mV/dec and a 10x V_DS ratio). Scaling the
            # criterion with V_DS -- i.e. a constant-CONDUCTANCE criterion --
            # removes that term. Both are reported; the scaled one is the DIBL.
            vt_s = {}
            for (st, j), g in groups.items():
                vds = float(g.Vds_V.iloc[0])
                vt_s[(st, round(vds, 3))] = vth_cc(g.Vg_V, g.Id_uA_um, icc * vds / 0.05)
            for st in ("ers", "pgm"):
                ks = sorted([k for k in vt if k[0] == st], key=lambda k: k[1])
                if len(ks) != 2:
                    continue
                raw = sc = float("nan")
                if np.isfinite(vt[ks[0]]) and np.isfinite(vt[ks[1]]):
                    raw = -(vt[ks[1]] - vt[ks[0]]) / (ks[1][1] - ks[0][1]) * 1000
                if np.isfinite(vt_s[ks[0]]) and np.isfinite(vt_s[ks[1]]):
                    sc = -(vt_s[ks[1]] - vt_s[ks[0]]) / (ks[1][1] - ks[0][1]) * 1000
                print(f"  DIBL ({st}): {sc:7.1f} mV/V  [constant-conductance criterion]"
                      f"   {raw:7.1f} mV/V  [fixed-current, drive-confounded]")
                bad = (not np.isfinite(sc) or not np.isfinite(raw)
                       or sc * raw < 0 or abs(sc - raw) > 0.5 * max(abs(sc), abs(raw)))
                if bad:
                    print(f"    ^ NOT TRUSTWORTHY. The two criteria disagree in sign or by")
                    print(f"      more than 50 %, which means V_t is being read outside a")
                    print(f"      clean subthreshold region on at least one curve. The sweep")
                    print(f"      only reaches V_G = -0.5 V; at V_DS = 0.5 V neither state is")
                    print(f"      properly off there (the programmed branch never drops below")
                    print(f"      2.7e-2 uA/um at all). Do not quote a DIBL from this run --")
                    print(f"      re-run t11_dibl with the sweep extended to V_G = -1.5 V.")


# ------------------------------------------------------------------- RR-3
def rr3(node="t10_ltd", cnode="t10_cyc"):
    """LTD branch and the 3-cycle symmetric loop."""
    if have(node, "p01_read_"):
        base = last(node, "baseline_pre_")
        ltp = [norm.to_uA_per_um(abs(last(node, f"p{k:02d}_read_")[ID])) for k in range(1, 16)]
        ltd = [norm.to_uA_per_um(abs(last(node, f"d{k:02d}_read_")[ID])) for k in range(1, 16)]
        out = pd.DataFrame({"pulse_n": range(1, 16),
                            "G_ltp_uA_um": ltp, "G_ltd_uA_um": ltd})
        _emit(out, RAW / "ltd_depression.csv", "RR-3 LTP + LTD")
        a_ltp, r2_ltp = nonlinearity(ltp)
        a_ltd, r2_ltd = nonlinearity(ltd[::-1])
        mono = bool(np.all(np.diff(ltd) <= 0))
        i_base = norm.to_uA_per_um(abs(base[ID]))
        print(f"  baseline (erased)  {i_base:.4g} uA/um")
        print(f"  LTP  {ltp[0]:.4g} -> {ltp[-1]:.4g} uA/um   "
              f"A_LTP = {a_ltp:+.3f} (fit R2 {r2_ltp:.3f})   "
              f"10-90 % span {pulse_span(ltp):.1f} pulses")
        print(f"  LTD  {ltd[0]:.4g} -> {ltd[-1]:.4g} uA/um   "
              f"A_LTD = {a_ltd:+.3f} (fit R2 {r2_ltd:.3f})   "
              f"10-90 % span {pulse_span(ltd):.1f} pulses   monotonic: {mono}")
        print(f"  asymmetry |A_LTP - A_LTD| = {abs(a_ltp - a_ltd):.3f}; "
              f"depression depth {ltp[-1] / max(ltd[-1], 1e-30):.1f}x")
        print(f"  loop closure: LTD endpoint is {100 * ltd[-1] / i_base:.1f} % of the "
              f"erased baseline (100 % = a perfectly closing loop)")
        if min(r2_ltp, r2_ltd) < 0.95:
            print("  NOTE: the exponential nonlinearity model fits poorly (R2 above). These")
            print("  trains are SIGMOIDAL -- an incubation delay of 2-3 pulses, then a fast")
            print("  swing -- so A is not a faithful descriptor and the 10-90 % pulse span")
            print("  should be quoted alongside it.")
        if not mono:
            print("  LTD is NOT monotonic -- raise t_p to 2 us and re-run (screening).")
    else:
        print(f"rr3: no data for {node} yet")

    if have(cnode, "p01_read_"):
        rows = []
        for c in range(3):
            for k in range(1, 16):
                rp = last(cnode, f"p{1 + c * 15 + k - 1:02d}_read_")
                rd = last(cnode, f"d{1 + c * 15 + k - 1:02d}_read_")
                if rp is None or rd is None:
                    continue
                rows.append({"cycle": c + 1, "pulse_n": k,
                             "G_ltp_uA_um": norm.to_uA_per_um(abs(rp[ID])),
                             "G_ltd_uA_um": norm.to_uA_per_um(abs(rd[ID]))})
        if rows:
            out = pd.DataFrame(rows)
            _emit(out, RAW / "ltp_ltd_cycles.csv", "RR-3 3 cycles")
            for c, g in out.groupby("cycle"):
                print(f"  cycle {c}: G_max {g.G_ltp_uA_um.max():.4g}  "
                      f"G_min {g.G_ltd_uA_um.min():.4g} uA/um")
    else:
        print(f"rr3: no cycle data for {cnode} yet")


# ------------------------------------------------------------------- RR-4
def rr4(nodes=(("t12_ret", 300, "programmed"), ("t12_ret400", 400, "programmed"),
               ("t12_ret_l8", 300, "ltp_level_8"), ("t12_ret15", 300, "levels_1_15"))):
    """Decade-spaced retention holds.

    WHAT THE DATA ACTUALLY DOES, and why the obvious analysis is wrong.  A
    retention hold here has two distinct phases:

      1. post-write settling.  The state leaves the write in a kinetic
         condition and relaxes with tau_P = 10 us.  At 300 K the programmed
         read runs 14.9 -> 21.0 -> 2.48 uA/um, an 8.4x fall, complete by about
         0.2 ms (~20 tau_P).
      2. a plateau.  From 0.28 ms to 10 ms the value is 2.4833 uA/um at EVERY
         sample -- not approximately, identically.

    Fitting one power law across both phases mixes a decaying transient with a
    flat line and returns a slope that describes neither; doing that here gave
    "retention factor 1.5e-3 at 10 years", i.e. total data loss, from a signal
    that is provably not decaying.  So the two phases are separated and only
    the plateau is used for the retention statement.

    The 10-year extrapolation is deliberately NOT reported as a number.  The
    measurement spans 10 ms; 10 years is 11 decades beyond it, and the plateau
    is flat to the solver's own resolution, so any extrapolation would be
    reporting the fit's noise floor as physics.  What can honestly be stated is
    a BOUND: no decay resolvable above X % across the last measured decade.

    An activation energy is likewise NOT extracted.  Both temperatures settle to
    flat plateaus, so the "decay rates" being compared are both zero, and the
    plateau LEVELS differ mostly because drain current is itself strongly
    temperature dependent -- that is carrier statistics, not polarization
    retention.  The Preisach model contains no thermally activated
    retention-loss term, so an E_a simply is not in it; it has to be measured.
    """
    frames, rows = [], []
    for node, temp, state in nodes:
        d = OUTPUTS / node
        if not d.exists():
            print(f"rr4: no data for {node} yet")
            continue
        segs = sorted(d.glob(f"hold_d*_{node}_des.plt")) + sorted(d.glob(f"h*_{node}_des.plt"))
        parts = []
        for f in segs:
            try:
                x = parse_plt(f)
            except Exception:                                  # noqa: BLE001
                continue
            if len(x):
                parts.append(pd.DataFrame({"seg": f.name.split("_")[0],
                                           "t_s": x["time"].values, "G_uA_um": cond_uA(x)}))
        if not parts:
            continue
        g = pd.concat(parts, ignore_index=True).sort_values("t_s")
        g["t_rel_s"] = g.t_s - g.t_s.iloc[0]
        g["node"], g["T_K"], g["state"] = node, temp, state
        frames.append(g)

        if state == "levels_1_15":
            # 15 separate holds, one per analog level -- a single fit across them
            # is a category error, so each hold is reported on its own.
            print(f"  {node}: {g.seg.nunique()} per-level holds, analysed individually:")
            for seg, h in g.groupby("seg", sort=True):
                h = h.sort_values("t_rel_s")
                if len(h) < 3:
                    continue
                drift = (h.G_uA_um.iloc[-1] / h.G_uA_um.iloc[0] - 1) * 100
                print(f"     {seg}: G {h.G_uA_um.iloc[0]:.4g} -> {h.G_uA_um.iloc[-1]:.4g} "
                      f"uA/um over {h.t_rel_s.iloc[-1] - h.t_rel_s.iloc[0]:.3g} s ({drift:+.2f} %)")
            continue

        # split settling from plateau: the plateau is the tail over which the
        # value varies by less than 1 % of its final value
        gv = g[g.t_rel_s > 0].reset_index(drop=True)
        gf = float(gv.G_uA_um.iloc[-1])
        flat = np.abs(gv.G_uA_um - gf) <= 0.01 * abs(gf)
        i0 = int(np.argmax(flat.values)) if flat.any() else len(gv) - 1
        t_settle = float(gv.t_rel_s.iloc[i0])
        tail = gv.iloc[i0:]
        spread = float((tail.G_uA_um.max() - tail.G_uA_um.min()) / abs(gf) * 100)
        rows.append({"node": node, "T_K": temp, "state": state,
                     "G_peak_uA_um": float(gv.G_uA_um.max()),
                     "G_plateau_uA_um": gf,
                     "settling_drop_x": float(gv.G_uA_um.max() / gf),
                     "t_settle_s": t_settle,
                     "t_settle_over_tauP": t_settle / 1e-5,
                     "plateau_decades": float(np.log10(gv.t_rel_s.iloc[-1] / max(t_settle, 1e-12))),
                     "plateau_spread_pct": spread})
    if frames:
        _emit(pd.concat(frames, ignore_index=True), RAW / "retention_long.csv",
              "RR-4 long retention")
    if rows:
        f = pd.DataFrame(rows)
        print(f.to_string(index=False))
        print()
        print("  Reading: the state settles in ~2e4 x tau_P and is then FLAT to within")
        print("  the spread above, over the stated number of decades.  Quote that bound,")
        print("  not a 10-year extrapolation -- the data stops at 10 ms.")
        print("  No E_a is extracted: both temperatures reach flat plateaus, and the")
        print("  plateau levels differ through the temperature dependence of the drain")
        print("  current, not through polarization loss.  The model has no thermally")
        print("  activated retention term; E_a must come from measurement.")
        best = f[f.state == "programmed"]
        if len(best):
            worst = float(best.plateau_spread_pct.max())
            print(f"  -> robustness_eval.py's hardcoded retention=0.971 should become "
                  f"{1 - worst / 100:.4f} (measured plateau bound), not a fitted decay.")


# ------------------------------------------------------------------- RR-5
def rr5(nodes=("t14_end10", "t14_end100", "t14_end1000")):
    rows = []
    for node in nodes:
        d = OUTPUTS / node
        if not d.exists():
            print(f"rr5: no data for {node} yet")
            continue
        for f in sorted(d.glob(f"w*_ers_{node}_des.plt")):
            c = int(f.name.split("_")[0][1:])
            on = last(node, f"w{c}_on_")
            if on is None:
                continue
            i_off = norm.to_uA_per_um(abs(parse_plt(f).iloc[-1][ID]))
            i_on = norm.to_uA_per_um(abs(on[ID]))
            rows.append({"node": node, "cycle": c, "I_off_uA_um": i_off,
                         "I_on_uA_um": i_on, "window": i_on / max(i_off, 1e-30)})
    if rows:
        out = pd.DataFrame(rows).sort_values("cycle")
        _emit(out, RAW / "endurance.csv", "RR-5 endurance")
        print(out.to_string(index=False))
        print("  CAPTION CAVEAT: the Preisach model has no fatigue, wake-up or imprint")
        print("  term, so a flat window here is a property of the model, not evidence")
        print("  that the device does not degrade.  What it does show is numerical")
        print("  cycle-stability and a reproducible switched charge per cycle.")


# ------------------------------------------------------------------- RR-7
def rr7():
    rows = []
    for d in sorted(OUTPUTS.glob("g_v*_t*")):
        node = d.name
        base = last(node, "baseline_pre_")
        if base is None:
            continue
        reads = sorted(d.glob(f"p*_read_{node}_des.plt"))
        ids = [norm.to_uA_per_um(abs(parse_plt(f).iloc[-1][ID])) for f in reads]
        if not ids:
            continue
        w = last(node, f"p{len(ids):02d}_write_")
        ey = abs(w[_probe(parse_plt(OUTPUTS / node / f"p{len(ids):02d}_write_{node}_des.plt"),
                          "ElectricField/y")]) if w is not None else np.nan
        i_base = norm.to_uA_per_um(abs(base[ID]))
        rows.append({"node": node,
                     "v_pgm_V": int(node.split("_")[1][1:]) / 10.0,
                     "t_p_ns": int(node.split("_")[2][1:]),
                     "id_base_uA_um": i_base, "id_last_uA_um": ids[-1],
                     "window": ids[-1] / max(i_base, 1e-30),
                     "igain": ids[-1] / max(ids[0], 1e-30),
                     "E_over_Fc": float(ey) / 1.4e6 if np.isfinite(ey) else np.nan})
    if rows:
        out = pd.DataFrame(rows).sort_values(["v_pgm_V", "t_p_ns"])
        _emit(out, SWEEPS / "vpgm_tp_grid.csv", "RR-7 programming design space")
        print(out.to_string(index=False))
    else:
        print("rr7: no grid data yet")


# ------------------------------------------------------------------- RR-8
def rr8():
    """Variability ensemble -> per-level spread, and whether the levels survive it.

    IMPORTANT about what this number is.  The 20 runs are deliberately chosen
    CORNERS of the (Dit, FixedCharge, T_fe) box -- every combination with at
    least two axes off nominal -- not a random sample from a distribution.  So
    the spread below is a corner envelope, an upper bound on device-to-device
    variation, and it is NOT a Gaussian sigma.  Quoting it as "sigma" would
    overstate the variation of a real population and imply a normal distribution
    that was never sampled.  It is reported as a range and a log-spread, and the
    SNN should take it as a worst case.

    The metric that decides whether the analog levels are usable is not the
    spread alone but the spread RELATIVE to the level spacing: adjacent LTP
    levels sit about 0.3 decades apart, so a comparable log-spread means
    neighbouring levels overlap across the corner box.
    """
    rows = []
    for d in sorted(OUTPUTS.glob("v_[0-9][0-9]")):
        node = d.name
        base = last(node, "baseline_pre_")
        if base is None:
            continue
        reads = sorted(d.glob(f"p*_read_{node}_des.plt"))
        ids = [norm.to_uA_per_um(abs(parse_plt(f).iloc[-1][ID])) for f in reads]
        if not ids:
            continue
        r = {"node": node, "id_base_uA_um": norm.to_uA_per_um(abs(base[ID]))}
        r.update({f"G{k}_uA_um": v for k, v in enumerate(ids, 1)})
        rows.append(r)
    if not rows:
        print("rr8: no ensemble data yet")
        return
    out = pd.DataFrame(rows)
    _emit(out, RAW / "variability_ensemble.csv", "RR-8 variability")

    cols = [c for c in out.columns if c.startswith("G")]
    lg = {c: np.log10(np.maximum(out[c].values, 1e-30)) for c in cols}
    sp = pd.DataFrame({
        "level": range(1, len(cols) + 1),
        "median_uA_um": [float(np.median(out[c])) for c in cols],
        "min_uA_um": [float(out[c].min()) for c in cols],
        "max_uA_um": [float(out[c].max()) for c in cols],
        "log10_range": [float(lg[c].max() - lg[c].min()) for c in cols],
    })
    sp["log10_halfspread"] = sp.log10_range / 2
    med = sp.median_uA_um.values
    spacing = np.full(len(med), np.nan)
    spacing[1:] = np.log10(med[1:] / np.maximum(med[:-1], 1e-30))
    sp["log10_spacing_to_prev"] = spacing
    sp["overlaps_prev"] = sp.log10_halfspread > np.where(np.isnan(spacing), np.inf,
                                                         spacing / 2)
    _emit(sp, RAW / "variability_per_level.csv",
          "RR-8 per-level corner envelope (SNN d2d input)")
    print(sp.to_string(index=False))
    # Which axis dominates?  The ensemble is a 3x3x3 corner design, so the effect
    # of each parameter can be read off directly by grouping.  This is the
    # actionable part: if one axis carries the spread, the manufacturing spec has
    # one line in it rather than three.
    import itertools
    dits = [3.2e12, 4.0e12, 4.8e12]
    fixqs = [6.3e12, 7.0e12, 7.7e12]
    tfes = [6.7, 7.0, 7.3]
    combos = [c for c in itertools.product(range(3), repeat=3) if c != (1, 1, 1)]
    combos = [c for c in combos if sum(1 for x in c if x != 1) >= 2][:20]
    lbl = {f"v_{i:02d}": c for i, c in enumerate(combos, start=1)}
    if set(out.node) <= set(lbl):
        mid = cols[len(cols) // 2]                     # a representative mid level
        o = out.copy()
        o["Dit"] = [dits[lbl[n][0]] for n in o.node]
        o["Qf"] = [fixqs[lbl[n][1]] for n in o.node]
        o["T_fe_nm"] = [tfes[lbl[n][2]] for n in o.node]
        print()
        print(f"  dominant-axis decomposition at level {mid[1:].split('_')[0]} "
              f"(log10 spread of the group medians):")
        for ax in ("Dit", "Qf", "T_fe_nm"):
            med = o.groupby(ax)[mid].median()
            rng = float(np.log10(med.max() / med.min()))
            detail = "  ".join(f"{k:g}:{v:.3g}" for k, v in med.items())
            print(f"    {ax:8s} {rng:5.2f} dec   {detail}")
        print("    (compare with the full corner half-spread "
              f"{float(sp.log10_halfspread.iloc[len(cols) // 2]):.2f} dec)")

    n_ov = int(sp.overlaps_prev.sum())
    print()
    print(f"  {len(out)} of 20 corner runs analysed.")
    print(f"  {n_ov} of {len(cols) - 1} adjacent level pairs OVERLAP across the corner box.")
    print("  This is a corner envelope, NOT a sigma: the runs are the corners of the")
    print("  (Dit +-20 %, FixedCharge +-10 %, T_fe +-0.3 nm) box, so treat it as a worst")
    print("  case and do not feed it to the SNN as a Gaussian d2d sigma.")
    if n_ov:
        print("  Level overlap at the corners is real, and it says something specific:")
        print("   * a SHARED 15-level quantization grid across devices is not valid --")
        print("     one fixed set of conductance targets cannot address every device in")
        print("     the corner box, because adjacent targets are closer together than")
        print("     the device-to-device spread.")
        print("   * it does NOT say the device has fewer than 15 levels. Each device is")
        print("     internally monotonic across all 15 pulses, so per-device programming")
        print("     (write-verify, or training on the deployed array) recovers them. D2D")
        print("     variation shifts a device's whole ladder; it does not merge its rungs.")
        print("   * the variation that WOULD destroy analog depth is cycle-to-cycle on one")
        print("     device, and this ensemble does not measure it. RR-3's 3-cycle run is")
        print("     the only c2c evidence so far and it shows the floor moving, not the")
        print("     levels blurring. A dedicated c2c run is the honest follow-up.")


# ------------------------------------------------------------------- RR-9
def rr9(node="t15_disturb", t_settled=1e-3):
    """Read disturb: window before and after ~1e6 equivalent reads at V_G = 0.

    MEASURED FROM THE SETTLED STATE, not from the immediate post-write value.
    This is the third place in this audit where the same trap appeared, so it is
    worth naming: the retained state relaxes with tau_P = 10 us after a write
    (RR-4 measures a 9x fall for the saturated state), so any "before" reading
    taken within a few tens of microseconds of the write is a transient value.
    Comparing it against a "after" reading taken 100 ms later charges the whole
    settling transient to read disturb.

    Doing exactly that here reported ON 15.98 -> 2.45 uA/um, "-84.7 % disturb"
    and a window collapsing 3702x -> 568x, which would have been a fabricated
    reliability failure. Measured from t >= 1 ms, once tau_P has fully acted, the
    answer is that there is no disturb at all.
    """
    d = OUTPUTS / node
    if not d.exists():
        print(f"rr9: no data for {node} yet")
        return
    parts = []
    for f in sorted(d.glob(f"read_d*_{node}_des.plt")):
        x = parse_plt(f)
        if len(x):
            parts.append(pd.DataFrame({"t_s": x["time"].values, "G_uA_um": cond_uA(x)}))
    if not parts:
        return
    g = pd.concat(parts, ignore_index=True).sort_values("t_s")
    g["t_rel_s"] = g.t_s - g.t_s.iloc[0]
    g["equivalent_reads"] = g.t_rel_s / 100e-9
    _emit(g, RAW / "read_disturb.csv", "RR-9 read disturb")

    off = last(node, "pre_ers_")
    i_off = norm.to_uA_per_um(abs(off[ID])) if off is not None else float("nan")
    s = g[g.t_rel_s >= t_settled]
    if len(s) < 2:
        print("  not enough settled samples")
        return
    g0, g1 = float(s.G_uA_um.iloc[0]), float(s.G_uA_um.iloc[-1])
    n0, n1 = float(s.equivalent_reads.iloc[0]), float(s.equivalent_reads.iloc[-1])
    print(f"  settling transient (tau_P, NOT disturb -- see RR-4): peak "
          f"{g.G_uA_um.max():.4g} -> settled {g0:.4g} uA/um")
    print(f"  READ DISTURB, settled state only:")
    print(f"    G {g0:.4f} uA/um at {n0:.3g} reads  ->  {g1:.4f} at {n1:.3g} reads")
    print(f"    change {100 * (g1 / g0 - 1):+.4f} % over {n1 - n0:.3g} equivalent reads")
    if np.isfinite(i_off):
        print(f"    window {g0 / i_off:.0f}x -> {g1 / i_off:.0f}x  (erased floor "
              f"{i_off:.4g} uA/um)")
    print("    a 0 % change here is a real result: at V_G = 0 the read bias does no")
    print("    work on the ferroelectric, so there is no mechanism for it to disturb.")


# ------------------------------------------------------------------ RR-10
def rr10(a="t13_tdr", b="t16_af045"):
    """The same deck at Areafactor 0.071 vs 0.045: the rescale must be exact."""
    for pref in ("ers_settle_", "pgm_settle_"):
        ra, rb = last(a, pref), last(b, pref)
        if ra is None or rb is None:
            print(f"rr10: need both {a} and {b} ({pref})")
            return
        got = float(abs(rb[ID]) / abs(ra[ID]))
        want = norm.AREAFACTOR_CORRECT / norm.AREAFACTOR_USED
        print(f"  {pref:14s} I(0.045)/I(0.071) = {got:.12f}  expected {want:.12f}  "
              f"rel err {abs(got - want) / want:.2e}")


ALL = {"rr0": rr0, "rr1": rr1, "rr2": rr2, "rr3": rr3, "rr4": rr4,
       "rr5": rr5, "rr7": rr7, "rr8": rr8, "rr9": rr9, "rr10": rr10}

if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    for k, fn in ALL.items():
        if what in ("all", k):
            print(f"\n=== {k} ===")
            try:
                fn()
            except Exception as exc:                      # noqa: BLE001
                print(f"  {k} FAILED: {type(exc).__name__}: {exc}")
