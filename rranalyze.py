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
    return bestA, best


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
            icc = 1e-2 * norm.CORR
            vt = {}
            for (st, j), g in out.groupby(["state", "vds_idx"]):
                vt[(st, round(float(g.Vds_V.iloc[0]), 3))] = vth_cc(g.Vg_V, g.Id_uA_um, icc)
            for k, v in vt.items():
                print(f"  V_t {k[0]} @ V_DS={k[1]} V : {v:+.4f} V")
            for st in ("ers", "pgm"):
                ks = sorted([k for k in vt if k[0] == st], key=lambda k: k[1])
                if len(ks) == 2 and np.isfinite(vt[ks[0]]) and np.isfinite(vt[ks[1]]):
                    dibl_mv = -(vt[ks[1]] - vt[ks[0]]) / (ks[1][1] - ks[0][1]) * 1000
                    print(f"  DIBL ({st}) = {dibl_mv:.1f} mV/V")


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
        a_ltp, _ = nonlinearity(ltp)
        a_ltd, _ = nonlinearity(ltd[::-1])
        mono = bool(np.all(np.diff(ltd) <= 0))
        print(f"  baseline (erased)  {norm.to_uA_per_um(abs(base[ID])):.4g} uA/um")
        print(f"  LTP  {ltp[0]:.4g} -> {ltp[-1]:.4g} uA/um   A_LTP = {a_ltp:+.3f}")
        print(f"  LTD  {ltd[0]:.4g} -> {ltd[-1]:.4g} uA/um   A_LTD = {a_ltd:+.3f}   "
              f"monotonic: {mono}")
        print(f"  asymmetry |A_LTP - A_LTD| = {abs(a_ltp - a_ltd):.3f}; "
              f"depression depth {ltp[-1] / max(ltd[-1], 1e-30):.1f}x")
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
    """Decade-spaced retention holds -> log-linear fit and the 10-year number."""
    frames, fits = [], []
    for node, temp, state in nodes:
        d = OUTPUTS / node
        if not d.exists():
            print(f"rr4: no data for {node} yet")
            continue
        segs = sorted(d.glob(f"h*_{node}_des.plt")) + sorted(d.glob(f"hold_d*_{node}_des.plt"))
        if not segs:
            continue
        parts = []
        for f in segs:
            x = parse_plt(f)
            parts.append(pd.DataFrame({"seg": f.name.split("_")[0], "t_s": x["time"].values,
                                       "G_uA_um": cond_uA(x)}))
        g = pd.concat(parts, ignore_index=True).sort_values("t_s")
        g["t_rel_s"] = g.t_s - g.t_s.iloc[0]
        g["node"], g["T_K"], g["state"] = node, temp, state
        frames.append(g)

        m = (g.t_rel_s > 1e-7) & (g.G_uA_um > 0)
        if m.sum() > 5:
            c = np.polyfit(np.log10(g.t_rel_s[m]), np.log10(g.G_uA_um[m]), 1)
            t10y = 10 * 365.25 * 24 * 3600
            g10 = 10 ** np.polyval(c, np.log10(t10y))
            g_end = float(g.G_uA_um[m].iloc[-1])
            fits.append({"node": node, "T_K": temp, "state": state,
                         "decades_per_decade": float(c[0]),
                         "G_end_uA_um": g_end, "G_10yr_uA_um": float(g10),
                         "retention_factor_10yr": float(g10 / g_end)})
    if frames:
        _emit(pd.concat(frames, ignore_index=True), RAW / "retention_long.csv",
              "RR-4 long retention")
    if fits:
        f = pd.DataFrame(fits)
        print(f.to_string(index=False))
        h = f[f.state == "programmed"]
        if {300, 400} <= set(h.T_K):
            r3 = float(h[h.T_K == 300].decades_per_decade.iloc[0])
            r4 = float(h[h.T_K == 400].decades_per_decade.iloc[0])
            if r3 and r4 and r4 / r3 > 0:
                k = 8.617e-5
                ea = np.log(abs(r4 / r3)) * k / (1 / 300 - 1 / 400)
                print(f"  retention activation energy E_a = {ea:.3f} eV "
                      f"(from the 300 K vs 400 K decay rates)")
        print("  -> replace the hardcoded 0.971 in "
              "PYTHON_Modelling_Fefet_Codes/*/robustness_eval.py with retention_factor_10yr")


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
    sig = pd.DataFrame({"level": range(1, len(cols) + 1),
                        "mean_uA_um": [out[c].mean() for c in cols],
                        "sigma_uA_um": [out[c].std() for c in cols],
                        "sigma_over_mean": [out[c].std() / out[c].mean() for c in cols],
                        "sigma_log10": [np.log10(out[c]).std() for c in cols]})
    _emit(sig, RAW / "variability_per_level.csv", "RR-8 per-level sigma (SNN d2d/c2c input)")
    print(sig.to_string(index=False))


# ------------------------------------------------------------------- RR-9
def rr9(node="t15_disturb"):
    d = OUTPUTS / node
    if not d.exists():
        print(f"rr9: no data for {node} yet")
        return
    parts = []
    for f in sorted(d.glob(f"read_d*_{node}_des.plt")):
        x = parse_plt(f)
        parts.append(pd.DataFrame({"t_s": x["time"].values, "G_uA_um": cond_uA(x)}))
    if not parts:
        return
    g = pd.concat(parts, ignore_index=True).sort_values("t_s")
    g["t_rel_s"] = g.t_s - g.t_s.iloc[0]
    g["equivalent_reads"] = g.t_rel_s / 100e-9
    _emit(g, RAW / "read_disturb.csv", "RR-9 read disturb")
    pre, post = last(node, "pre_pgm_"), last(node, "post_pgm_")
    off = last(node, "pre_ers_")
    if pre is not None and post is not None and off is not None:
        i_pre = norm.to_uA_per_um(abs(pre[ID]))
        i_post = norm.to_uA_per_um(abs(post[ID]))
        i_off = norm.to_uA_per_um(abs(off[ID]))
        print(f"  ON before {i_pre:.4g} -> after {i_post:.4g} uA/um "
              f"({(i_post / i_pre - 1) * 100:+.2f} %)")
        print(f"  window {i_pre / i_off:.0f}x -> {i_post / i_off:.0f}x after "
              f"{g.equivalent_reads.max():.3g} equivalent reads")


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
