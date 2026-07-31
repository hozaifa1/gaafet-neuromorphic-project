"""Detached Sentaurus job runner for the paper re-runs (RR-0 .. RR-11).

opt.py runs sdevice in the FOREGROUND over ssh.  That is fine for a 2-minute LIF
node but wrong for anything longer: if the ssh channel drops, the remote sdevice
is orphaned and keeps holding the single license until someone kills it by hand.
Everything in PLOT_PLAN Part IV is minutes-to-hours, so those jobs are launched
detached (nohup, stdin closed) and polled instead.

  python runjob.py submit <node> [--upload f1 f2 ...]   upload + launch detached
  python runjob.py status <node> [<node> ...]           running? + log tail
  python runjob.py wait   <node> [--timeout S]          block until it exits
  python runjob.py fetch  <node> --out DIR [--glob G]   download results
  python runjob.py kill   <node>                        stop a runaway job
  python runjob.py ps                                   every sdevice on the host

`submit` expects runs/<node>_des.cmd to exist locally.
"""
import argparse
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
PW = (ROOT / "Calibration" / "autocal" / ".pw").read_text().strip()
HOST = "du@103.28.121.70"
REMOTE = "Sentaurus-files/Sami_Hozaifa/GAAFet"
OUTDIR = "opt_outputs"
PLINK = r"C:\Program Files\PuTTY\plink.exe"
PSCP = r"C:\Program Files\PuTTY\pscp.exe"


def _retry(fn, tries=4, wait=15):
    for i in range(tries):
        try:
            return fn()
        except Exception as e:                        # noqa: BLE001 -- network is flaky
            if i == tries - 1:
                raise
            print(f"  [retry {i + 1}/{tries}] {e}", flush=True)
            time.sleep(wait)


def sh(cmd, timeout=300):
    r = _retry(lambda: subprocess.run(
        [PLINK, "-batch", "-ssh", "-pw", PW, HOST, cmd],
        capture_output=True, text=True, timeout=timeout))
    return r.stdout.strip(), r.stderr.strip(), r.returncode


def up(local, remote_name=None):
    local = Path(local)
    remote_name = remote_name or local.name

    def _do():
        r = subprocess.run([PSCP, "-batch", "-pw", PW, str(local),
                            f"{HOST}:{REMOTE}/{remote_name}"],
                           capture_output=True, text=True, timeout=600)
        if r.returncode:
            raise RuntimeError(f"upload {local} failed: {r.stderr}")
    _retry(_do)
    print(f"  up  {local.name} -> {remote_name}")


def down(remote_glob, localdir):
    Path(localdir).mkdir(parents=True, exist_ok=True)
    r = _retry(lambda: subprocess.run(
        [PSCP, "-batch", "-pw", PW, f"{HOST}:{REMOTE}/{remote_glob}", str(localdir)],
        capture_output=True, text=True, timeout=1800))
    return r


def check_no_at(path):
    """SWB substitutes tokens on '*'-commented lines too, so a stray '@' anywhere is fatal."""
    bad = [(i, ln) for i, ln in enumerate(Path(path).read_text().splitlines(), 1) if "@" in ln]
    if bad:
        raise SystemExit(f"{path}: '@' found on line(s) {[i for i, _ in bad]} -- SWB will error out")


def submit(node, uploads=()):
    """Upload and launch ONE detached sdevice.

    The launch is deliberately NOT retried and NOT wrapped in _retry: it is not
    idempotent, and an earlier version that retried on ssh timeout ended up with
    four identical jobs queued on a single-license host, all writing the same
    output files.  plink often does not return promptly even though the remote
    launch succeeded, so a timeout here is treated as "probably launched" and
    verified with pgrep instead.
    """
    cmdfile = HERE / "runs" / f"{node}_des.cmd"
    if not cmdfile.exists():
        raise SystemExit(f"missing {cmdfile}")
    check_no_at(cmdfile)
    if _running(node):
        raise SystemExit(f"[submit] {node} is ALREADY running on the host -- refusing to double-launch")
    sh(f"mkdir -p ~/{REMOTE}/{OUTDIR}")
    for f in uploads:
        up(f)
    up(cmdfile)
    log = f"{OUTDIR}/{node}_runlog.txt"
    launch = (f'cd ~/{REMOTE} && rm -f {log} && '
              f'setsid csh -c "source ~/.cshrc && sdevice {node}_des.cmd" '
              f'> {log} 2>&1 < /dev/null &')
    try:
        subprocess.run([PLINK, "-batch", "-ssh", "-pw", PW, HOST, launch],
                       capture_output=True, text=True, timeout=45)
    except subprocess.TimeoutExpired:
        pass                      # expected: plink holds the channel open
    time.sleep(5)
    running = _running(node)
    print(f"[submit] {node} {'launched' if running else 'NOT SEEN -- check status'}")
    if running:
        print("   " + running.splitlines()[-1][:120])


def _running(node):
    out, _, _ = sh(f'pgrep -fa "sdevice {node}_des.cmd" | grep -v pgrep || true', timeout=120)
    return out


def status(nodes, tail=6):
    for node in nodes:
        run = _running(node)
        out, _, _ = sh(f'tail -{tail} ~/{REMOTE}/{OUTDIR}/{node}_runlog.txt 2>/dev/null || '
                       f'echo "(no log yet)"', timeout=180)
        state = "RUNNING" if run else "not running"
        print(f"=== {node}: {state}")
        for ln in out.splitlines():
            print(f"    {ln}")
    return 0


def wait(node, timeout=7200, interval=60):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if not _running(node):
            print(f"[wait] {node} finished after {time.time() - t0:.0f}s")
            return 0
        time.sleep(interval)
    print(f"[wait] {node} still running after {timeout}s")
    return 1


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("submit"); s.add_argument("node"); s.add_argument("--upload", nargs="*", default=[])
    t = sub.add_parser("status"); t.add_argument("node", nargs="+"); t.add_argument("--tail", type=int, default=6)
    w = sub.add_parser("wait"); w.add_argument("node"); w.add_argument("--timeout", type=int, default=7200)
    f = sub.add_parser("fetch"); f.add_argument("node"); f.add_argument("--out", required=True)
    f.add_argument("--glob", default=None)
    k = sub.add_parser("kill"); k.add_argument("node")
    sub.add_parser("ps")
    a = ap.parse_args()

    if a.cmd == "submit":
        submit(a.node, a.upload)
    elif a.cmd == "status":
        status(a.node, a.tail)
    elif a.cmd == "wait":
        sys.exit(wait(a.node, a.timeout))
    elif a.cmd == "fetch":
        g = a.glob or f"{OUTDIR}/*{a.node}_des.plt"
        down(g, a.out)
        got = sorted(Path(a.out).glob("*"))
        print(f"[fetch] {len(got)} files -> {a.out}")
    elif a.cmd == "kill":
        print(sh(f'pkill -f "sdevice {a.node}_des.cmd" ; echo killed')[0])
    elif a.cmd == "ps":
        print(sh('pgrep -fa sdevice | grep -v pgrep || echo "no sdevice running"')[0])


if __name__ == "__main__":
    main()
