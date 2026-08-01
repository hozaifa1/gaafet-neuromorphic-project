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
import sys
import torch          # MUST precede numpy/pandas on Windows, else pandas' runtime DLLs
import numpy as np    # break torch's c10.dll initialization (WinError 1114).
import pandas as pd

_HERE = os.path.dirname(os.path.abspath(__file__))
# ONE source of truth: the repo's canonical raw export. A bundled copy used to be
# preferred here and silently went stale -- it held the pre-Phase-1 currents, i.e.
# every absolute number 1/0.6338 = 1.578x too high (the Areafactor correction).
# Accuracy was unaffected (weights normalize by g_max) but g_min/g_max/R/energy
# were not. Resolving to exactly one path makes a missing export fail loudly
# instead of resolving to stale data.
# (the old fallback pointed one level too shallow, which is why the bundle was never
# bypassed; walk up to the repo root instead of hardcoding the depth.)
def _find_raw(start: str) -> str:
    d = start
    while True:
        cand = os.path.join(d, "Device_Optimization", "csv_export", "raw")
        if os.path.isdir(cand):
            return cand
        parent = os.path.dirname(d)
        if parent == d:
            raise FileNotFoundError("Device_Optimization/csv_export/raw not found above " + start)
        d = parent


_RAW = _find_raw(_HERE)
_DEVOPT = os.path.dirname(os.path.dirname(_RAW))
V_READ = 0.05   # V, sub-threshold read bias (SNN_PARAMETERS / energy_ledger)

# Provenance guard: post-Phase-1 LTP top level, Device_Optimization/norm.py convention.
_P15_UA_UM = 8.316845
_W_EFF_UM = 0.09        # gate perimeter TESW = 2*(W+T_si); norm.py Areafactor = W_eff/2


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
    if csv_path.endswith("ltp_potentiation.csv"):
        top = float(df["Id_uA_per_um"].max())
        if abs(top / _P15_UA_UM - 1.0) > 1e-4:
            raise ValueError(
                f"{csv_path} top LTP level is {top:.6e} uA/um, expected {_P15_UA_UM:.6e}. "
                f"ratio {top/_P15_UA_UM:.4f} (1.5778 = the pre-Phase-1 Areafactor). "
                "Refusing stale device data.")
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
    # cross-check the absolute top level against the device parameter file
    sys.path.insert(0, _DEVOPT)
    from gaafefet_params_optimized import LIF
    g_p15_abs = gmax * _W_EFF_UM
    print(f"  absolute (x W_eff={_W_EFF_UM*1e3:.0f} nm): g_p15 = {g_p15_abs:.4e} S "
          f"vs params g_max_p15 = {LIF['g_max_p15']:.4e} S  "
          f"(ratio {g_p15_abs/LIF['g_max_p15']:.6f})")
    assert abs(g_p15_abs / LIF["g_max_p15"] - 1.0) < 1e-3, "LTP top level disagrees with params"
    print("  OK: reads the canonical post-Phase-1 export.")
