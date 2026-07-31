"""Download every finished queue node and run its analysis.

    python harvest.py            fetch whatever QUEUE.log says has finished, then analyse
    python harvest.py --list     just show what has finished and what is still pending
    python harvest.py --nodes a b c

Reads opt_outputs/QUEUE.log on the host, downloads the .plt (and .tdr) of every
node that logged an END line and is not already local, then runs the matching
rranalyze function.  Safe to run repeatedly; it skips what it already has.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DEVOPT = ROOT / "Device_Optimization"
sys.path.insert(0, str(DEVOPT))
import runjob                                    # noqa: E402
import rranalyze                                 # noqa: E402

OUTPUTS = DEVOPT / "outputs"

# node-name prefix -> the rranalyze entry point that consumes it
ANALYSIS = [
    ("iv_fe07b", "rr0"), ("mfm_pe", "rr1"), ("t11_", "rr2"), ("t10_", "rr3"),
    ("t12_", "rr4"), ("t14_", "rr5"), ("g_v", "rr7"), ("v_", "rr8"),
    ("t15_", "rr9"), ("t16_", "rr10"), ("t13_", "rr10"),
]


def finished_nodes():
    out, _, _ = runjob.sh(
        f"cat ~/{runjob.REMOTE}/{runjob.OUTDIR}/QUEUE.log 2>/dev/null", timeout=300)
    done, failed = [], []
    for m in re.finditer(r"END\s+(\S+)\s+rc=(\d+)\s+(\d+)s\s+plt=(\d+)", out):
        node, rc, secs, nplt = m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4))
        (done if nplt > 0 else failed).append((node, rc, secs, nplt))
    pend, _, _ = runjob.sh(
        f"cat ~/{runjob.REMOTE}/{runjob.OUTDIR}/QUEUE.txt 2>/dev/null", timeout=300)
    return done, failed, [x for x in pend.split() if x]


def fetch(node):
    d = OUTPUTS / node
    d.mkdir(parents=True, exist_ok=True)
    runjob.down(f"{runjob.OUTDIR}/*{node}_des.plt", d)
    n = len(list(d.glob("*.plt")))
    print(f"  fetched {node}: {n} plt")
    return n


def main():
    done, failed, pending = finished_nodes()
    print(f"finished: {len(done)}   failed/empty: {len(failed)}   pending: {len(pending)}")
    for node, rc, secs, nplt in done:
        print(f"  OK   {node:14s} rc={rc} {secs:5d}s  {nplt:4d} plt")
    for node, rc, secs, nplt in failed:
        print(f"  FAIL {node:14s} rc={rc} {secs:5d}s  {nplt:4d} plt")
    if pending:
        print(f"  pending: {' '.join(pending[:12])}{' ...' if len(pending) > 12 else ''}")
    if "--list" in sys.argv:
        return

    want = sys.argv[sys.argv.index("--nodes") + 1:] if "--nodes" in sys.argv else \
        [n for n, _, _, _ in done]
    got = set()
    for node in want:
        local = len(list((OUTPUTS / node).glob("*.plt"))) if (OUTPUTS / node).exists() else 0
        if local == 0:
            if fetch(node):
                got.add(node)
        else:
            got.add(node)

    ran = set()
    for node in sorted(got):
        for prefix, fn in ANALYSIS:
            if node.startswith(prefix) and fn not in ran:
                ran.add(fn)
                print(f"\n=== {fn}  (triggered by {node}) ===")
                try:
                    rranalyze.ALL[fn]()
                except Exception as exc:                  # noqa: BLE001
                    print(f"  {fn} FAILED: {type(exc).__name__}: {exc}")
                break


if __name__ == "__main__":
    main()
