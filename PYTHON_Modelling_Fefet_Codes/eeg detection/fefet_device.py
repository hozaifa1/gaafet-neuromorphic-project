"""
Physics-based FeFET synapse device model built from MEASURED data (Phase 1).
=============================================================================
The 15 analog conductance levels come directly from the device's measured
long-term-potentiation (LTP) curve — i.e. the partial ferroelectric
POLARIZATION-SWITCHING states — not from an invented sigmoid. This is what makes
the device model traceable to measurement (project rule) and IEEE-TED defensible.

Source: Device_Optimization/csv_export/raw/ltp_potentiation.csv
        (pulse_n, Id_uA_per_um) — 15 pulses, ~4-decade span of drain current at a
        fixed sub-threshold read bias => proportional to the retained conductance.
Temperature variants (250/300/350 K) live in ltp_vs_temperature.csv for Phase-5
hardware-aware robustness.
"""
from __future__ import annotations
import os
import torch          # MUST precede numpy/pandas on Windows, else pandas' runtime DLLs
import numpy as np    # break torch's c10.dll initialization (WinError 1114).
import pandas as pd

_HERE = os.path.dirname(os.path.abspath(__file__))
# Prefer the device CSVs bundled inside this self-contained folder; fall back to the
# original repo location (../Device_Optimization) so this file also works in-place.
_LOCAL_RAW = os.path.join(_HERE, "Device_Optimization", "csv_export", "raw")
_PARENT_RAW = os.path.join(_HERE, "..", "Device_Optimization", "csv_export", "raw")
_RAW = _LOCAL_RAW if os.path.isdir(_LOCAL_RAW) else _PARENT_RAW
V_READ = 0.05   # V, sub-threshold read bias (SNN_PARAMETERS / energy_ledger)


def measured_levels(csv_path: str | None = None, v_read: float = V_READ):
    """Return (levels[S], g_min, g_max) from the measured LTP potentiation curve.

    Conductance is taken proportional to the measured read current at fixed V_read
    (G = I / V_read). Only the relative spacing matters downstream (weights are
    normalized by g_max), so per-um vs absolute geometry is irrelevant here.
    """
    if csv_path is None:
        csv_path = os.path.join(_RAW, "ltp_potentiation.csv")
    df = pd.read_csv(csv_path)
    ide = df["Id_uA_per_um"].to_numpy(dtype=float) * 1e-6    # A/um
    g = np.sort(ide / v_read)                                 # S/um, ascending
    return torch.from_numpy(g).float(), float(g[0]), float(g[-1])


def measured_levels_at_temperature(temp_key: str = "G_300K_uA_um", v_read: float = V_READ):
    """Levels from ltp_vs_temperature.csv for T in {250,300,350} K (Phase-5 robustness)."""
    df = pd.read_csv(os.path.join(_RAW, "ltp_vs_temperature.csv"))
    g = np.sort(df[temp_key].to_numpy(dtype=float) * 1e-6 / v_read)
    return torch.from_numpy(g).float(), float(g[0]), float(g[-1])


if __name__ == "__main__":
    lv, gmin, gmax = measured_levels()
    print(f"measured LTP levels: n={lv.numel()}")
    print(f"  G span: {gmin:.3e} .. {gmax:.3e} S  (dynamic range {gmax/gmin:.0f}x, "
          f"{np.log10(gmax/gmin):.2f} decades)")
    print(f"  R span: {1/gmax:.3e} .. {1/gmin:.3e} ohm-um")
    # spacing between successive levels (log10 step) — shows the real LTP non-uniformity
    steps = np.diff(np.log10(lv.numpy()))
    print(f"  log10 step per level: min={steps.min():.3f} max={steps.max():.3f} "
          f"mean={steps.mean():.3f}  (uniform-log would be constant)")
