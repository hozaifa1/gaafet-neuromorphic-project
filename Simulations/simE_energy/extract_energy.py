"""extract_energy.py — Compute E_pulse and E_fire_total from simE .plt files.

Phase 1C deliverable #2 post-processor.

Reads each pXX_<seg>_*.plt file, integrates V(t) * I(t) over time for both
gate and drain contacts, and reports per-pulse energy plus the total energy
through the 9-pulse fire sequence.

Usage:
    python extract_energy.py <path_to_sim_results_dir>

The results directory should contain the .plt files produced by sdevice
running sdevice_simE_energy.cmd. .plt files are space-separated text with
a header listing the columns (typical Sentaurus output).

Output:
    energy_summary.csv with columns
      pulse, segment, t_start, t_end, E_gate_J, E_drain_J, E_total_J
    plus a printed summary of E_fire_total_J (sum across all 9 pulses).
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from glob import glob

try:
    import numpy as np
except ImportError:
    print("numpy is required. pip install numpy")
    sys.exit(1)


SEG_RE = re.compile(r"(?:c(\d+)_)?p(\d+)_(rise|write|fall|read)_")


def read_plt(path: str) -> tuple[list[str], np.ndarray]:
    """Parse a Sentaurus DF-ISE xyplot .plt with datasets=[...] header."""
    with open(path, "r") as f:
        txt = f.read()
    m = re.search(r"datasets\s*=\s*\[(.*?)\]", txt, re.S)
    if not m:
        return [], np.empty((0, 0))
    headers = re.findall(r'"([^"]+)"', m.group(1))
    n_cols = len(headers)
    m2 = re.search(r"Data\s*\{(.*)", txt, re.S)
    if not m2:
        return headers, np.empty((0, n_cols))
    body = m2.group(1)
    end = body.rfind("}")
    if end >= 0:
        body = body[:end]
    nums = re.findall(r"-?\d+\.\d+E[+-]\d+|-?\d+\.\d+|-?\d+", body)
    if n_cols == 0 or not nums:
        return headers, np.empty((0, n_cols))
    if len(nums) % n_cols != 0:
        nums = nums[: (len(nums) // n_cols) * n_cols]
    arr = np.array([float(x) for x in nums]).reshape(-1, n_cols)
    return headers, arr


def find_col(headers: list[str], *patterns: str) -> int | None:
    """Return the index of the first header that matches any of the patterns."""
    for pat in patterns:
        for i, h in enumerate(headers):
            if pat.lower() in h.lower():
                return i
    return None


def integrate_segment(t: np.ndarray, v: np.ndarray, i: np.ndarray) -> float:
    """Trapezoidal integral of v*i over t."""
    if len(t) < 2:
        return 0.0
    p = v * i
    return float(np.trapezoid(p, t))


def process_file(path: str) -> dict | None:
    """Extract energy from one segment .plt file."""
    headers, data = read_plt(path)
    if data.size == 0:
        return None
    t_idx = find_col(headers, "time")
    vg_idx = find_col(headers, "gate_contact OuterVoltage", "gate OuterVoltage")
    ig_idx = find_col(headers, "gate_contact TotalCurrent", "gate TotalCurrent")
    vd_idx = find_col(headers, "drain_contact OuterVoltage", "drain OuterVoltage")
    id_idx = find_col(headers, "drain_contact TotalCurrent", "drain TotalCurrent")
    if any(x is None for x in (t_idx, vg_idx, ig_idx, vd_idx, id_idx)):
        return None
    t = data[:, t_idx]
    e_gate = integrate_segment(t, data[:, vg_idx], data[:, ig_idx])
    e_drain = integrate_segment(t, data[:, vd_idx], data[:, id_idx])
    name = os.path.basename(path)
    m = SEG_RE.search(name)
    cycle = int(m.group(1)) if (m and m.group(1)) else 0  # 0 = no cycle prefix (legacy single-burst)
    pulse = int(m.group(2)) if m else -1
    segment = m.group(3) if m else "unknown"
    return {
        "file": name,
        "cycle": cycle,
        "pulse": pulse,
        "segment": segment,
        "t_start": float(t[0]),
        "t_end": float(t[-1]),
        "E_gate_J": e_gate,
        "E_drain_J": e_drain,
        "E_total_J": e_gate + e_drain,
        "n_samples": len(t),
    }


def main() -> int:
    p = argparse.ArgumentParser(description="Energy extraction from simE .plt files")
    p.add_argument("results_dir", help="Directory containing pXX_*.plt files")
    p.add_argument("--out", default="energy_summary.csv", help="Output CSV path")
    p.add_argument(
        "--include",
        default="",
        help="Substring that must appear in the filename (e.g. 'cyclic_vm6' to "
        "scope a multi-node SWB output dir to one V_erase tag).",
    )
    args = p.parse_args()

    # Match both legacy single-burst (pXX_*) and cyclic (cN_pN_*) naming.
    patterns = [
        os.path.join(args.results_dir, "p[0-9]*_*_*.plt"),
        os.path.join(args.results_dir, "c[0-9]*_p[0-9]*_*_*.plt"),
        os.path.join(args.results_dir, "**", "p[0-9]*_*_*.plt"),
        os.path.join(args.results_dir, "**", "c[0-9]*_p[0-9]*_*_*.plt"),
    ]
    files: list[str] = []
    for pat in patterns:
        files.extend(glob(pat, recursive=True))
    files = sorted(set(files))
    if args.include:
        files = [f for f in files if args.include in os.path.basename(f)]
    if not files:
        print(f"No matching .plt files in {args.results_dir}")
        return 1

    rows = []
    for path in files:
        r = process_file(path)
        if r is not None:
            rows.append(r)

    rows.sort(key=lambda r: (r["cycle"], r["pulse"], r["segment"]))

    out_path = args.out
    if not os.path.isabs(out_path):
        out_path = os.path.join(args.results_dir, out_path)
    with open(out_path, "w", newline="") as f:
        f.write(
            "file,cycle,pulse,segment,t_start,t_end,E_gate_J,E_drain_J,E_total_J,n_samples\n"
        )
        for r in rows:
            f.write(
                f"{r['file']},{r['cycle']},{r['pulse']},{r['segment']},"
                f"{r['t_start']:.6e},{r['t_end']:.6e},{r['E_gate_J']:.6e},"
                f"{r['E_drain_J']:.6e},{r['E_total_J']:.6e},{r['n_samples']}\n"
            )

    by_pulse: dict[tuple[int, int], dict[str, float]] = {}
    for r in rows:
        d = by_pulse.setdefault(
            (r["cycle"], r["pulse"]),
            {"E_gate_J": 0.0, "E_drain_J": 0.0},
        )
        d["E_gate_J"] += r["E_gate_J"]
        d["E_drain_J"] += r["E_drain_J"]

    print(f"Wrote: {out_path}")
    by_cycle: dict[int, float] = {}
    for (cycle, _pulse), d in by_pulse.items():
        by_cycle[cycle] = by_cycle.get(cycle, 0.0) + d["E_gate_J"] + d["E_drain_J"]

    if set(by_cycle) == {0}:
        # Legacy single-burst (no cycle prefix): emit per-pulse table.
        print(f"\nPer-pulse totals (gate + drain):")
        print(f"{'pulse':>6} {'E_gate (fJ)':>14} {'E_drain (fJ)':>14} {'E_total (fJ)':>14}")
        e_fire_total = 0.0
        for (_cycle, pulse) in sorted(by_pulse):
            d = by_pulse[(_cycle, pulse)]
            e_total = d["E_gate_J"] + d["E_drain_J"]
            e_fire_total += e_total
            print(
                f"{pulse:>6} {d['E_gate_J']*1e15:>14.3f} "
                f"{d['E_drain_J']*1e15:>14.3f} {e_total*1e15:>14.3f}"
            )
        print(
            f"\nE_fire_total = {e_fire_total*1e15:.3f} fJ "
            f"= {e_fire_total*1e12:.3f} pJ (sum across all pulses to fire)"
        )
    else:
        # Cyclic LIF: emit per-cycle summary (sum across 9 pulses per cycle).
        print(f"\nPer-cycle fire-burst energy (sum of 9-pulse gate + drain):")
        print(f"{'cycle':>6} {'E_fire (fJ)':>14}")
        for cycle in sorted(by_cycle):
            print(f"{cycle:>6} {by_cycle[cycle]*1e15:>14.3f}")
        e_steady = (
            np.mean([by_cycle[c] for c in by_cycle if c >= 3])
            if any(c >= 3 for c in by_cycle)
            else float("nan")
        )
        print(
            f"\nE_fire (steady-state, mean c3..) = {e_steady*1e15:.3f} fJ per 9-pulse burst"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
