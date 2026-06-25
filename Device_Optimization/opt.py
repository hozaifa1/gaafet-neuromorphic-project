"""GAA-FeFET LIF device-optimization driver (autoresearch coordinate descent).

Two sub-commands:
  mesh  <meshtag> --T_SI .. --T_OX .. --T_FE .. --T_METAL .. --L_GATE .. \
                  --L_SD .. --L_OV .. --N_SUB .. --N_SD ..
      Render parametric sde, upload, build mesh <meshtag>_msh.tdr on the cluster.

  run   <tag> --mesh <meshtag> --WF .. --VREAD .. --TAU_P .. --VPGM 2.5,3.5,4.5,5.5
      Render lif_eval.cmd per V_pgm, run sdevice (serial, single license),
      download reads, analyze -> FoM. Appends one row to results.tsv.

Outputs: runs/ (rendered cmds), outputs/<tag>/ (downloaded plts), results.tsv.
Remote: du@103.28.121.70 : ~/Sentaurus-files/Sami_Hozaifa/GAAFet  (single sdevice license).
"""
import argparse, subprocess, sys, re, json
from pathlib import Path
import numpy as np
import lifgen

HERE   = Path(__file__).resolve().parent
ROOT   = HERE.parent
PW     = (ROOT / "New_cal" / "autocal" / ".pw").read_text().strip()
HOST   = "du@103.28.121.70"
REMOTE = "Sentaurus-files/Sami_Hozaifa/GAAFet"
PLINK  = r"C:\Program Files\PuTTY\plink.exe"
PSCP   = r"C:\Program Files\PuTTY\pscp.exe"

# plt parsing (lif_eval.cmd: 3 electrodes + Pol/E probes -> 29 cols, like h1app)
NCOLS, COL_ID, COL_QG, COL_POLY, COL_EY = 29, 7, 24, 26, 28
W_um, F_c = 0.090, 1.4e6

DEF_GEOM = dict(T_SI=0.015, T_OX=0.002, T_FE=0.010, T_METAL=0.005,
                L_GATE=0.100, L_SD=0.050, L_OV=0.015, N_SUB=1e16, N_SD=5e19)
DEF_ELEC = dict(WF=4.35, VREAD=-0.5, TAU_P=1e-5, TEMP=300)


import time

def _retry(fn, tries=3, wait=10):
    """Run fn(); on exception/transient SSH drop, wait and retry (network is flaky)."""
    for i in range(tries):
        try:
            return fn()
        except Exception as e:
            if i == tries - 1:
                raise
            print(f"  [retry {i+1}/{tries}] {e}", flush=True)
            time.sleep(wait)

def plink(cmd, timeout=2000):
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

def render(tpl, subs):
    s = Path(tpl).read_text()
    for k, v in subs.items():
        s = s.replace(f"@{k}@", str(v))
    left = re.findall(r"@[A-Za-z_]+@", s)
    if left: raise RuntimeError(f"unrendered tokens in {tpl}: {set(left)}")
    return s


def build_mesh(meshtag, geom):
    g = {**DEF_GEOM, **geom, "NODE": meshtag}
    sde = render(HERE / "sde" / "sde_opt.cmd", g)
    f = HERE / "runs" / f"sde_{meshtag}.cmd"; f.write_text(sde)
    (HERE / "runs" / f"mesh_{meshtag}.json").write_text(json.dumps(g))  # geom sidecar
    up(f, f"{REMOTE}/sde_{meshtag}.cmd")
    print(f"[mesh] building {meshtag} ...", flush=True)
    r = plink(f'cd ~/{REMOTE} && csh -c "source ~/.cshrc && sde -e -l sde_{meshtag}.cmd" '
              f'>& sde_{meshtag}.log; tail -2 sde_{meshtag}.log; ls -la {meshtag}_msh.tdr')
    print(r.stdout[-400:], r.stderr[-200:])
    ok = plink(f'ls ~/{REMOTE}/{meshtag}_msh.tdr').returncode == 0
    print(f"[mesh] {meshtag} {'OK' if ok else 'FAILED'}", flush=True)
    return ok


def parse(fp):
    t = Path(fp).read_text().split("Data {")[1].split("}")[0].strip()
    return np.array([float(x) for x in t.split()]).reshape(-1, NCOLS) if t else np.empty((0, NCOLS))

def endrow(fp):
    a = parse(fp); return a[-1] if len(a) else None


def probe_y(meshtag):
    """FE-midpoint y (um) from the mesh's geometry sidecar; falls back to baseline."""
    jf = HERE / "runs" / f"mesh_{meshtag}.json"
    if not jf.exists():
        return 0.0145
    g = json.loads(jf.read_text())
    return g["T_SI"] / 2.0 + g["T_OX"] + g["T_FE"] / 2.0


def run_lif(tag, meshtag, elec, vpgm_list, N=9, t_p=100e-9, t_read=100e-9, t_hold=0.0,
            v_erase=0.0, t_erase=0.0, digits=5, tol=1e-5):
    outdir = HERE / "outputs" / tag
    plink(f'mkdir -p ~/{REMOTE}/opt_outputs')
    py = probe_y(meshtag)
    gen = (N != 9 or abs(t_p - 100e-9) > 1e-15 or abs(t_read - 100e-9) > 1e-15
           or t_hold > 0 or t_erase > 0 or digits != 5)
    rows = {}
    for vp in vpgm_list:
        node = f"{tag}_v{int(round(vp*10)):03d}"
        if gen:
            cmd = lifgen.gen(f"{meshtag}_msh.tdr", "app_opt.par", node, elec["WF"],
                             elec["VREAD"], vp, f"{py:.5f}", N=N, t_p=t_p, t_read=t_read,
                             TEMP=elec.get("TEMP", 300), t_hold=t_hold,
                             V_erase=v_erase, t_erase=t_erase, DIGITS=digits, TOL=tol)
        else:
            subs = {**DEF_ELEC, **elec, "V_pgm": vp, "node": node, "PROBEY": f"{py:.5f}",
                    "tdr": f"{meshtag}_msh.tdr", "par": "app_opt.par"}
            cmd = render(HERE / "lif_eval.cmd", subs)
        f = HERE / "runs" / f"{node}_des.cmd"; f.write_text(cmd)
        up(f, f"{REMOTE}/{node}_des.cmd")
        print(f"[run] {node} (V_pgm={vp}) ...", flush=True)
        r = plink(f'cd ~/{REMOTE} && csh -c "source ~/.cshrc && sdevice {node}_des.cmd" '
                  f'>& opt_outputs/{node}_runlog.txt; tail -1 opt_outputs/{node}_runlog.txt')
        down(f"{REMOTE}/opt_outputs/baseline_pre_{node}_des.plt", outdir)
        down(f"{REMOTE}/opt_outputs/p*_read_{node}_des.plt", outdir)
        down(f"{REMOTE}/opt_outputs/p*_write_{node}_des.plt", outdir)
        if t_hold > 0:
            down(f"{REMOTE}/opt_outputs/hold_{node}_des.plt", outdir)
        rows[vp] = analyze_vp(outdir, node)
        print(f"[run] {node}: {rows[vp]}", flush=True)
    return rows


def analyze_vp(outdir, node):
    base = endrow(Path(outdir) / f"baseline_pre_{node}_des.plt")
    if base is None: return None
    id_base = abs(base[COL_ID]) * 1e6 / W_um
    reads = sorted(Path(outdir).glob(f"p*_read_{node}_des.plt"))
    ids = [abs(endrow(fp)[COL_ID]) * 1e6 / W_um for fp in reads]
    if not ids: return None
    lastk = max(int(fp.name[1:3]) for fp in reads)
    w9 = Path(outdir) / f"p{lastk:02d}_write_{node}_des.plt"
    ew = endrow(w9)
    ey = abs(ew[COL_EY]) / F_c if ew is not None else np.nan
    qg = abs(ew[COL_QG]) if ew is not None else np.nan
    igain = ids[-1] / ids[0] if ids[0] else float("nan")  # integration fidelity p9/p1
    id_on = float(np.nanmax(ids))                          # saturated programmed state
    return dict(id_base=id_base, ids=ids, id_p1=ids[0], id_p9=ids[-1], id_on=id_on,
                dr=ids[-1] / id_base, window=id_on / id_base, igain=igain,
                rising=bool(ids[-1] > ids[0]),  # true graded integration p1->p9
                ey_over_fc=ey, qg_p9=qg)


def pick_op(rows):
    """Operating point = lowest V_pgm in the sub-coercive band |E|/Fc in [0.70,0.98]
    (probe tracks geometry). Fallback: V_pgm with the largest window."""
    good = [(vp, r) for vp, r in sorted(rows.items())
            if r and 0.70 <= r["ey_over_fc"] <= 0.98]
    if good:
        return good[0]
    valid = [(vp, r) for vp, r in rows.items() if r]
    if not valid:
        return min(rows.items())
    return max(valid, key=lambda kr: kr[1]["window"])


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("mesh"); m.add_argument("meshtag")
    for k, v in DEF_GEOM.items(): m.add_argument(f"--{k}", type=float, default=v)
    r = sub.add_parser("run"); r.add_argument("tag")
    r.add_argument("--mesh", required=True)
    r.add_argument("--VPGM", default="2.5,3.5,4.5,5.5")
    r.add_argument("--N", type=int, default=9)
    r.add_argument("--TP", type=float, default=100e-9)
    r.add_argument("--TREAD", type=float, default=100e-9)
    r.add_argument("--THOLD", type=float, default=0.0)
    r.add_argument("--VERASE", type=float, default=0.0)
    r.add_argument("--TERASE", type=float, default=0.0)
    r.add_argument("--DIGITS", type=int, default=5)
    r.add_argument("--TOL", type=float, default=1e-5)
    r.add_argument("--note", default="")
    for k, v in DEF_ELEC.items(): r.add_argument(f"--{k}", type=float, default=v)
    a = ap.parse_args()

    if a.cmd == "mesh":
        geom = {k: getattr(a, k) for k in DEF_GEOM}
        ok = build_mesh(a.meshtag, geom)
        sys.exit(0 if ok else 1)

    if a.cmd == "run":
        elec = {k: getattr(a, k) for k in DEF_ELEC}
        # upload candidate par (tau_P rendered)
        par = render(HERE / "par" / "app.par", {"TAU_P": elec["TAU_P"]})
        pf = HERE / "runs" / f"app_{a.tag}.par"; pf.write_text(par)
        up(pf, f"{REMOTE}/app_opt.par")
        vpgm = [float(x) for x in a.VPGM.split(",")]
        rows = run_lif(a.tag, a.mesh, elec, vpgm, N=a.N, t_p=a.TP, t_read=a.TREAD,
                       t_hold=a.THOLD, v_erase=a.VERASE, t_erase=a.TERASE,
                       digits=a.DIGITS, tol=a.TOL)
        vop, ro = pick_op(rows)
        line = (f"{a.tag}\t{a.mesh}\tWF={elec['WF']}\tVREAD={elec['VREAD']}\t"
                f"TAU_P={elec['TAU_P']:.0e}\tVop={vop}\tWIN={ro['window']:.1f}\t"
                f"DR={ro['dr']:.1f}\tigain={ro['igain']:.3f}\tIDrest={ro['id_base']:.3e}\t"
                f"IDon={ro['id_on']:.3e}\tEyFc={ro['ey_over_fc']:.2f}\t"
                f"Qg={ro['qg_p9']:.3e}\t{a.note}")
        print("\n=== FoM ===\n" + line)
        tsv = HERE / "results.tsv"
        if not tsv.exists():
            tsv.write_text("tag\tmesh\tWF\tVREAD\tTAU_P\tVop\tWIN\tDR\tigain\tIDrest\tIDon\tEyFc\tQg\tnote\n")
        with tsv.open("a") as fh: fh.write(line + "\n")


if __name__ == "__main__":
    main()
