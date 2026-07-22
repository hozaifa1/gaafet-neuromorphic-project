"""Planar-FeFET remote driver: mesh + memory-window + LIF characterization.

Self-contained (does NOT reuse opt.py's stale New_cal path). Drives sde/sdevice on
du@103.28.121.70 via plink/pscp. Robust .plt parser reads variable names from the
header (handles the 4-electrode planar layout, any column order).

Subcommands:
  mesh                          build planar_msh.tdr from sde/sde_planar.cmd
  mw   <node> [--WF --VE --VP]  memory-window I-V (retained transfer both branches)
  lif  <tag> --VPGM a,b,c ...   LIF pulse-train sweep (erase/baseline/N pulses/hold)
"""
import argparse, subprocess, sys, re, json, time
from pathlib import Path
import numpy as np
import gen_planar as G

HERE   = Path(__file__).resolve().parent
ROOT   = HERE.parent
PW     = (ROOT / "Calibration" / "autocal" / ".pw").read_text().strip()
HOST   = "du@103.28.121.70"
REMOTE = "Sentaurus-files/Sami_Hozaifa/GAAFet"
PLINK  = r"C:\Program Files\PuTTY\plink.exe"
PSCP   = r"C:\Program Files\PuTTY\pscp.exe"
F_c    = 1.4e6          # V/cm coercive field (probe |Ey|/F_c -> sub-coercive check)
W_um   = 1.0           # Areafactor=1.0 -> plt current already per-um; report I*1e6 uA/um


def _retry(fn, tries=3, wait=10):
    for i in range(tries):
        try:
            return fn()
        except Exception as e:
            if i == tries - 1:
                raise
            print(f"  [retry {i+1}/{tries}] {e}", flush=True)
            time.sleep(wait)

def plink(cmd, timeout=3000):
    return _retry(lambda: subprocess.run([PLINK, "-batch", "-ssh", "-pw", PW, HOST, cmd],
                  capture_output=True, text=True, timeout=timeout))

def up(local, remote):
    def _do():
        r = subprocess.run([PSCP, "-batch", "-pw", PW, str(local), f"{HOST}:{remote}"],
                           capture_output=True, text=True, timeout=300)
        if r.returncode:
            raise RuntimeError(f"upload {local} failed: {r.stderr}")
    _retry(_do)

def down(remote_glob, localdir):
    Path(localdir).mkdir(parents=True, exist_ok=True)
    _retry(lambda: subprocess.run([PSCP, "-batch", "-pw", PW, f"{HOST}:{remote_glob}",
                   str(localdir)], capture_output=True, text=True, timeout=600))

def render(text, subs):
    for k, v in subs.items():
        text = text.replace(f"@{k}@", str(v))
    left = re.findall(r"@[A-Za-z_]+@", text)
    if left:
        raise RuntimeError(f"unrendered tokens: {set(left)}")
    return text


# ---------------- robust .plt parser (name -> column) ----------------
def parse_plt(fp):
    txt = Path(fp).read_text()
    ds = txt.split("datasets", 1)[1].split("[", 1)[1].split("]", 1)[0]
    names = re.findall(r'"([^"]+)"', ds)
    data = txt.split("Data {", 1)[1].rsplit("}", 1)[0].strip()
    if not data:
        return names, np.empty((0, len(names)))
    arr = np.array([float(x) for x in data.split()]).reshape(-1, len(names))
    return names, arr

def col(names, key):
    for i, n in enumerate(names):
        if key in n:
            return i
    raise KeyError(f"{key} not in {names}")

def endrow(fp):
    names, a = parse_plt(fp)
    return (names, a[-1]) if len(a) else (names, None)

def read_id(fp):
    """|drain TotalCurrent| at last time, in uA/um."""
    names, r = endrow(fp)
    if r is None:
        return None
    return abs(r[col(names, "drain_contact TotalCurrent")]) * 1e6 / W_um


# ---------------- mesh ----------------
def build_mesh(node="planar"):
    sde = render((HERE / "sde" / "sde_planar.cmd").read_text(), {"NODE": node})
    f = HERE / "runs" / f"sde_{node}.cmd"; f.write_text(sde)
    up(f, f"{REMOTE}/sde_{node}.cmd")
    print(f"[mesh] building {node} ...", flush=True)
    r = plink(f'cd ~/{REMOTE} && csh -c "source ~/.cshrc && sde -e -l sde_{node}.cmd" '
              f'>& sde_{node}.log; tail -3 sde_{node}.log; ls -la {node}_msh.tdr')
    print(r.stdout[-600:], r.stderr[-300:])
    ok = plink(f'ls ~/{REMOTE}/{node}_msh.tdr').returncode == 0
    print(f"[mesh] {node} {'OK' if ok else 'FAILED'}", flush=True)
    return ok


def upload_par(tau_p=1e-5):
    par = render((HERE / "par" / "app_planar.par").read_text(), {"TAU_P": tau_p})
    pf = HERE / "runs" / "app_planar_r.par"; pf.write_text(par)
    up(pf, f"{REMOTE}/app_planar.par")


def _run_sdevice(node, cmd_text, dl_prefixes, outdir):
    f = HERE / "runs" / f"{node}_des.cmd"; f.write_text(cmd_text)
    if re.search(r"@[A-Za-z_]+@", cmd_text):
        raise RuntimeError(f"{node}: unrendered tokens {set(re.findall(r'@[A-Za-z_]+@', cmd_text))}")
    up(f, f"{REMOTE}/{node}_des.cmd")
    plink(f'mkdir -p ~/{REMOTE}/planar_outputs')
    print(f"[run] {node} ...", flush=True)
    r = plink(f'cd ~/{REMOTE} && csh -c "source ~/.cshrc && sdevice {node}_des.cmd" '
              f'>& planar_outputs/{node}_runlog.txt; tail -1 planar_outputs/{node}_runlog.txt')
    print("   ", r.stdout.strip()[-200:], flush=True)
    for pfx in dl_prefixes:
        down(f"{REMOTE}/planar_outputs/{pfx}", outdir)


# ---------------- memory-window ----------------
def run_mw(node, WF=4.35, VE=-4.0, VP=4.0, tau_p=1e-5, vgs=None):
    upload_par(tau_p)
    outdir = HERE / "outputs" / node
    cmd = G.mw_gen(f"planar_msh.tdr", "app_planar.par", node, WF, VE=VE, VP=VP, vgs=vgs)
    _run_sdevice(f"mw_{node}", cmd, [f"ers_r*_mw_{node}_des.plt", f"pgm_r*_mw_{node}_des.plt",
                                     f"mw_{node}_des.plt"], outdir)
    analyze_mw(outdir, node, vgs=vgs)


def analyze_mw(outdir, node, vgs=None):
    outdir = Path(outdir)
    vgs = G._VGS if vgs is None else vgs
    def branch(state):
        ids = []
        for i in range(len(vgs)):
            fp = outdir / f"{state}_r{i:02d}_mw_{node}_des.plt"
            ids.append(read_id(fp) if fp.exists() else np.nan)
        return np.array(ids)
    ers, pgm = branch("ers"), branch("pgm")
    res = dict(vgs=vgs, ers=ers.tolist(), pgm=pgm.tolist())
    # ON/OFF window at each Vg (pgm is the ON/low-Vt branch for +program)
    with np.errstate(divide="ignore", invalid="ignore"):
        ratio = pgm / ers
    res["window_ratio"] = np.nanmax(ratio) if np.isfinite(ratio).any() else np.nan
    res["window_vg"] = vgs[int(np.nanargmax(ratio))] if np.isfinite(ratio).any() else None
    res["ss_ers_mVdec"] = subthreshold_slope(np.array(vgs, float), ers)  # erased/OFF turn-on
    (outdir / f"mw_{node}_analysis.json").write_text(json.dumps(res, indent=2))
    print(f"[mw] {node}  Vg: {vgs}")
    print(f"[mw] ERS uA/um: {[f'{x:.2e}' for x in ers]}")
    print(f"[mw] PGM uA/um: {[f'{x:.2e}' for x in pgm]}")
    print(f"[mw] max ON/OFF ratio = {res['window_ratio']:.1f} at Vg={res['window_vg']}")
    print(f"[mw] SS(erased) = {res['ss_ers_mVdec']:.1f} mV/dec")
    return res


# ---------------- transfer curve / subthreshold slope ----------------
def upload_frozen_par():
    up(HERE / "par" / "app_planar_frozen.par", f"{REMOTE}/app_planar_frozen.par")


def run_iv(node="planar", WF=4.35, VE=-6.0, VP=4.5, VLO=-1.5, VHI=2.0):
    upload_frozen_par()
    outdir = HERE / "outputs" / node
    cmd = G.iv_gen("planar_msh.tdr", "app_planar_frozen.par", node, WF=WF, VE=VE,
                   VP=VP, VLO=VLO, VHI=VHI)
    _run_sdevice(f"iv_{node}", cmd, [f"ers_iv_{node}_des.plt", f"pgm_iv_{node}_des.plt"], outdir)
    return analyze_iv(outdir, node)


def _sweep_vg_id(fp):
    """(Vg terminal, |Id| uA/um) arrays from a transfer-sweep plt."""
    names, a = parse_plt(fp)
    if len(a) == 0:
        return None, None
    vg = a[:, col(names, "gate_contact OuterVoltage")]
    idd = np.abs(a[:, col(names, "drain_contact TotalCurrent")]) * 1e6 / W_um
    return vg, idd


def subthreshold_slope(vg, idd):
    """Min (steepest) SS in mV/dec over the rising subthreshold band [10*floor, 0.1*max]."""
    if vg is None:
        return np.nan
    floor = np.nanmin(idd[idd > 0]) if np.any(idd > 0) else np.nan
    top = np.nanmax(idd)
    lo, hi = 10 * floor, 0.1 * top
    ss = []
    for i in range(1, len(vg)):
        d_id = idd[i], idd[i - 1]
        if d_id[0] > d_id[1] > 0 and lo <= d_id[1] <= hi and lo <= d_id[0] <= hi:
            dv = (vg[i] - vg[i - 1]) * 1e3          # mV
            ddec = np.log10(d_id[0] / d_id[1])
            if ddec > 0:
                ss.append(dv / ddec)
    return float(np.nanmin(ss)) if ss else np.nan


def analyze_iv(outdir, node):
    outdir = Path(outdir)
    ve, ie = _sweep_vg_id(outdir / f"ers_iv_{node}_des.plt")
    vp, ip = _sweep_vg_id(outdir / f"pgm_iv_{node}_des.plt")
    ss_ers = subthreshold_slope(ve, ie)
    ss_pgm = subthreshold_slope(vp, ip)
    res = dict(ss_ers_mVdec=ss_ers, ss_pgm_mVdec=ss_pgm,
               vg_ers=ve.tolist() if ve is not None else [], id_ers=ie.tolist() if ie is not None else [],
               vg_pgm=vp.tolist() if vp is not None else [], id_pgm=ip.tolist() if ip is not None else [])
    (outdir / f"iv_{node}_analysis.json").write_text(json.dumps(res, indent=2))
    print(f"[iv] {node}  SS(erased) = {ss_ers:.1f} mV/dec   SS(programmed) = {ss_pgm:.1f} mV/dec")
    return res


# ---------------- LIF pulse-train ----------------
def run_lif(tag, vpgm_list, WF=4.35, VREAD=0.0, N=9, t_p=100e-9, t_read=100e-9,
            t_hold=0.0, V_erase=0.0, t_erase=0.0, tau_p=1e-5):
    upload_par(tau_p)
    outdir = HERE / "outputs" / tag
    rows = {}
    for vp in vpgm_list:
        node = f"{tag}_v{int(round(vp*10)):03d}"
        cmd = G.lif_gen("planar_msh.tdr", "app_planar.par", node, WF, VREAD, vp,
                        N=N, t_p=t_p, t_read=t_read, t_hold=t_hold,
                        V_erase=V_erase, t_erase=t_erase)
        dl = [f"baseline_pre_{node}_des.plt", f"p*_read_{node}_des.plt", f"p*_write_{node}_des.plt"]
        if t_hold > 0:
            dl.append(f"hold_{node}_des.plt")
        _run_sdevice(node, cmd, dl, outdir)
        rows[vp] = analyze_lif(outdir, node)
        print(f"[lif] {node}: {rows[vp]}", flush=True)
    (outdir / f"{tag}_lif.json").write_text(json.dumps({str(k): v for k, v in rows.items()}, indent=2))
    return rows


def analyze_lif(outdir, node):
    outdir = Path(outdir)
    bfp = outdir / f"baseline_pre_{node}_des.plt"
    if not bfp.exists():
        return None
    id_base = read_id(bfp)
    reads = sorted(outdir.glob(f"p*_read_{node}_des.plt"))
    ids = [read_id(fp) for fp in reads]
    if not ids:
        return None
    lastk = max(int(fp.name[1:3]) for fp in reads)
    wfp = outdir / f"p{lastk:02d}_write_{node}_des.plt"
    ey = qg = np.nan
    if wfp.exists():
        names, ew = endrow(wfp)
        if ew is not None:
            ey = abs(ew[col(names, "ElectricField/y")]) / F_c
            qg = abs(ew[col(names, "gate_contact Charge")])
    return dict(id_base=id_base, ids=ids, id_p1=ids[0], id_pN=ids[-1],
                id_on=float(np.nanmax(ids)), dr=ids[-1] / id_base if id_base else np.nan,
                window=float(np.nanmax(ids)) / id_base if id_base else np.nan,
                igain=ids[-1] / ids[0] if ids[0] else np.nan,
                rising=bool(ids[-1] > ids[0]), ey_over_fc=ey, qg_pN=qg)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("mesh")
    m = sub.add_parser("mw"); m.add_argument("node"); m.add_argument("--WF", type=float, default=4.35)
    m.add_argument("--VE", type=float, default=-4.0); m.add_argument("--VP", type=float, default=4.0)
    m.add_argument("--TAUP", type=float, default=1e-5)
    iv = sub.add_parser("iv"); iv.add_argument("--node", default="planar")
    iv.add_argument("--WF", type=float, default=4.35); iv.add_argument("--VE", type=float, default=-6.0)
    iv.add_argument("--VP", type=float, default=4.5); iv.add_argument("--VLO", type=float, default=-1.5)
    iv.add_argument("--VHI", type=float, default=2.0)
    l = sub.add_parser("lif"); l.add_argument("tag"); l.add_argument("--VPGM", default="2.5,3.5,4.5,5.5")
    l.add_argument("--WF", type=float, default=4.35); l.add_argument("--VREAD", type=float, default=0.0)
    l.add_argument("--N", type=int, default=9); l.add_argument("--TP", type=float, default=100e-9)
    l.add_argument("--TREAD", type=float, default=100e-9); l.add_argument("--THOLD", type=float, default=0.0)
    l.add_argument("--VERASE", type=float, default=0.0); l.add_argument("--TERASE", type=float, default=0.0)
    l.add_argument("--TAUP", type=float, default=1e-5)
    a = ap.parse_args()

    if a.cmd == "mesh":
        sys.exit(0 if build_mesh() else 1)
    if a.cmd == "mw":
        run_mw(a.node, WF=a.WF, VE=a.VE, VP=a.VP, tau_p=a.TAUP)
    if a.cmd == "iv":
        run_iv(a.node, WF=a.WF, VE=a.VE, VP=a.VP, VLO=a.VLO, VHI=a.VHI)
    if a.cmd == "lif":
        vpgm = [float(x) for x in a.VPGM.split(",")]
        run_lif(a.tag, vpgm, WF=a.WF, VREAD=a.VREAD, N=a.N, t_p=a.TP, t_read=a.TREAD,
                t_hold=a.THOLD, V_erase=a.VERASE, t_erase=a.TERASE, tau_p=a.TAUP)


if __name__ == "__main__":
    main()
