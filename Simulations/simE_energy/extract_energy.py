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


PLT_HEADER_RE = re.compile(r"^\s*\"(.+?)\"\s*$")
SEG_RE = re.compile(r"p(\d{2})_(rise|write|fall|read)_")


def read_plt(path: str) -> tuple[list[str], np.ndarray]:
    """Read a Sentaurus .plt file. Returns (header_names, data_array)."""
    with open(path, "r") as f:
        lines = f.readlines()

    # Sentaurus .plt format: data section starts after "DATA" or after the
    # header lines that look like quoted column names. We support the common
    # form where the first whitespace-only line of numbers begins the data.
    headers: list[str] = []
    data_start = 0
    in_header = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("\"") and stripped.endswith("\""):
            in_header = True
            headers.append(stripped.strip("\""))
            continue
        if in_header:
            # First non-quoted line after headers is data
            try:
                _ = float(stripped.split()[0])
                data_start = i
                break
            except ValueError:
                continue

    rows = []
    for line in lines[data_start:]:
        parts = line.split()
        if not parts:
            continue
        try:
            rows.append([float(x) for x in parts])
        except ValueError:
            break
    if not rows:
        return headers, np.empty((0, len(headers)))
    return headers, np.array(rows)


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
    return float(np.trapz(p, t))


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
    pulse = int(m.group(1)) if m else -1
    segment = m.group(2) if m else "unknown"
    return {
        "file": name,
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
    args = p.parse_args()

    pattern = os.path.join(args.results_dir, "p[0-9][0-9]_*_*.plt")
    files = sorted(glob(pattern))
    if not files:
        # Try one level deeper (SWB tdrdat output structure)
        pattern = os.path.join(args.results_dir, "**", "p[0-9][0-9]_*_*.plt")
        files = sorted(glob(pattern, recursive=True))
    if not files:
        print(f"No matching .plt files in {args.results_dir}")
        return 1

    rows = []
    for path in files:
        r = process_file(path)
        if r is not None:
            rows.append(r)

    rows.sort(key=lambda r: (r["pulse"], r["segment"]))

    out_path = args.out
    if not os.path.isabs(out_path):
        out_path = os.path.join(args.results_dir, out_path)
    with open(out_path, "w", newline="") as f:
        f.write("file,pulse,segment,t_start,t_end,E_gate_J,E_drain_J,E_total_J,n_samples\n")
        for r in rows:
            f.write(
                f"{r['file']},{r['pulse']},{r['segment']},{r['t_start']:.6e},"
                f"{r['t_end']:.6e},{r['E_gate_J']:.6e},{r['E_drain_J']:.6e},"
                f"{r['E_total_J']:.6e},{r['n_samples']}\n"
            )

    by_pulse: dict[int, dict[str, float]] = {}
    for r in rows:
        d = by_pulse.setdefault(r["pulse"], {"E_gate_J": 0.0, "E_drain_J": 0.0})
        d["E_gate_J"] += r["E_gate_J"]
        d["E_drain_J"] += r["E_drain_J"]

    print(f"Wrote: {out_path}")
    print(f"\nPer-pulse totals (gate + drain):")
    print(f"{'pulse':>6} {'E_gate (fJ)':>14} {'E_drain (fJ)':>14} {'E_total (fJ)':>14}")
    e_fire_total = 0.0
    for pulse in sorted(by_pulse):
        d = by_pulse[pulse]
        e_total = d["E_gate_J"] + d["E_drain_J"]
        e_fire_total += e_total
        print(
            f"{pulse:>6} {d['E_gate_J']*1e15:>14.3f} "
            f"{d['E_drain_J']*1e15:>14.3f} {e_total*1e15:>14.3f}"
        )
    print(
        f"\nE_fire_total = {e_fire_total*1e15:.3f} fJ "
        f"= {e_fire_total*1e12:.3f} pJ "
        f"(sum across all pulses to fire)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
