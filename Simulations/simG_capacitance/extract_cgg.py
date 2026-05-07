"""extract_cgg.py — Extract C_gg(VGS) from simG ACExtract output.

Phase 1C deliverable #4 post-processor.

Sentaurus 2023.12 ACCoupled produces an .acplt file (passed via File ACExtract).
The .acplt is a text file containing the full small-signal admittance matrix
Y_ij(omega) at each VGS step. C_gg is extracted from the imaginary part of
the gate-gate admittance:
    C_gg(VGS) = Im(Y_gg(omega)) / omega

This script:
  1. Parses cv_virgin_*.acplt and cv_postfire_*.acplt (or whatever the
     ACExtract files were named by sdevice).
  2. Extracts C_gg(VGS) for both states.
  3. Prints peak C_gg, on/off ratio, and the Vth shift implied by the curve
     midpoint shift.
  4. Writes c_gg_summary.csv with columns: VGS, C_gg_virgin_F, C_gg_postfire_F.

Usage:
    python extract_cgg.py <results_dir>

If your installation produces .plt files instead of .acplt for AC output,
or uses a different column naming convention (e.g. "Y(gate,gate)" vs
"Y(gate_contact,gate_contact)"), edit COLUMN_PATTERNS below.
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


COLUMN_PATTERNS = {
    "vgs":     ["gate_contact OuterVoltage", "g OuterVoltage", "vg.dc"],
    "y_gg_im": ["Y(gate_contact,gate_contact) Im", "Y(g,g) Im", "Im(Y(g,g))"],
    "y_gg_re": ["Y(gate_contact,gate_contact) Re", "Y(g,g) Re"],
    "freq":    ["frequency", "Frequency"],
}


def read_acplt(path: str) -> tuple[list[str], np.ndarray]:
    """Read a Sentaurus .acplt or .plt file. Returns (header_names, data)."""
    with open(path, "r") as f:
        lines = f.readlines()
    headers: list[str] = []
    data_start = 0
    in_header = False
    for i, line in enumerate(lines):
        s = line.strip()
        if not s:
            continue
        if s.startswith("\"") and s.endswith("\""):
            in_header = True
            headers.append(s.strip("\""))
            continue
        if in_header:
            try:
                _ = float(s.split()[0])
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


def find_col(headers: list[str], patterns: list[str]) -> int | None:
    for pat in patterns:
        for i, h in enumerate(headers):
            if pat.lower() in h.lower():
                return i
    return None


def extract_cgg(path: str, default_freq_hz: float = 1.0e6) -> tuple[np.ndarray, np.ndarray]:
    """Return (vgs, c_gg_F) arrays from a single AC sweep file."""
    headers, data = read_acplt(path)
    if data.size == 0:
        raise RuntimeError(f"No data in {path}")
    vgs_idx = find_col(headers, COLUMN_PATTERNS["vgs"])
    yim_idx = find_col(headers, COLUMN_PATTERNS["y_gg_im"])
    f_idx = find_col(headers, COLUMN_PATTERNS["freq"])
    if vgs_idx is None or yim_idx is None:
        print(f"  available columns in {os.path.basename(path)}:")
        for h in headers:
            print(f"    {h}")
        raise RuntimeError(
            f"Could not find required columns in {path}. "
            "Edit COLUMN_PATTERNS to match this Sentaurus version's output."
        )
    vgs = data[:, vgs_idx]
    y_gg_im = data[:, yim_idx]
    if f_idx is not None:
        omega = 2.0 * np.pi * data[:, f_idx]
    else:
        omega = 2.0 * np.pi * default_freq_hz
    c_gg = y_gg_im / omega
    return vgs, c_gg


def find_acfile(results_dir: str, prefix: str) -> str | None:
    cands = sorted(
        glob(os.path.join(results_dir, f"{prefix}*.acplt")) +
        glob(os.path.join(results_dir, f"{prefix}*.plt")) +
        glob(os.path.join(results_dir, "**", f"{prefix}*.acplt"), recursive=True) +
        glob(os.path.join(results_dir, "**", f"{prefix}*.plt"), recursive=True)
    )
    return cands[0] if cands else None


def main() -> int:
    p = argparse.ArgumentParser(description="C_gg extraction from simG AC output")
    p.add_argument("results_dir", help="Directory containing cv_virgin_*.acplt and cv_postfire_*.acplt")
    p.add_argument("--out", default="c_gg_summary.csv", help="Output CSV path")
    p.add_argument("--virgin-prefix", default="cv_virgin_")
    p.add_argument("--postfire-prefix", default="cv_postfire_")
    args = p.parse_args()

    f_virgin = find_acfile(args.results_dir, args.virgin_prefix)
    f_post = find_acfile(args.results_dir, args.postfire_prefix)

    if not f_virgin:
        print(f"No virgin AC file found with prefix '{args.virgin_prefix}'")
        return 1
    if not f_post:
        print(f"No post-fire AC file found with prefix '{args.postfire_prefix}'")
        return 1

    print(f"Virgin AC file:    {f_virgin}")
    print(f"Post-fire AC file: {f_post}")

    vgs_v, c_v = extract_cgg(f_virgin)
    vgs_p, c_p = extract_cgg(f_post)

    # Resample post-fire onto virgin VGS grid for direct subtraction
    c_p_resamp = np.interp(vgs_v, vgs_p, c_p)

    out_path = args.out
    if not os.path.isabs(out_path):
        out_path = os.path.join(args.results_dir, out_path)
    with open(out_path, "w", newline="") as fout:
        fout.write("VGS_V,C_gg_virgin_F,C_gg_postfire_F,delta_C_F\n")
        for v, cv, cp in zip(vgs_v, c_v, c_p_resamp):
            fout.write(f"{v:.6e},{cv:.6e},{cp:.6e},{cp-cv:.6e}\n")

    c_v_peak = float(np.max(c_v))
    c_p_peak = float(np.max(c_p))
    c_v_min = float(np.min(c_v))
    c_p_min = float(np.min(c_p))

    # Vth shift estimate from CV midpoint shift
    half_v = 0.5 * (c_v_peak + c_v_min)
    half_p = 0.5 * (c_p_peak + c_p_min)
    try:
        vth_v = float(np.interp(half_v, c_v, vgs_v))
        vth_p = float(np.interp(half_p, c_p_resamp, vgs_v))
    except Exception:
        vth_v = vth_p = float("nan")

    # Natural FeFET tau from R_total * C_gg_peak
    R_total = 7830.0  # R_h + R_s from Step 2 v1
    tau_native = R_total * c_v_peak

    print(f"\n=== C_gg Summary ===")
    print(f"Virgin   peak C_gg: {c_v_peak*1e15:.3f} fF, min: {c_v_min*1e15:.3f} fF")
    print(f"PostFire peak C_gg: {c_p_peak*1e15:.3f} fF, min: {c_p_min*1e15:.3f} fF")
    print(f"Delta peak (post-virgin): {(c_p_peak - c_v_peak)*1e15:.3f} fF")
    print(f"Vth (CV midpoint) virgin: {vth_v:.4f} V")
    print(f"Vth (CV midpoint) post-fire: {vth_p:.4f} V")
    print(f"Vth shift: {(vth_p - vth_v)*1e3:.2f} mV")
    print(f"\nNative FeFET tau = R_total * C_gg_peak = "
          f"{R_total} Ohm * {c_v_peak*1e15:.3f} fF = {tau_native*1e9:.3f} ns")
    print(f"\nStep 2 v1 chose external C_mem = 1.419 uF for tau = 11.11 ms.")
    print(f"Ratio C_mem / C_gg_peak = {1.419e-6 / c_v_peak:.2e}")
    print(f"\nWrote: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
