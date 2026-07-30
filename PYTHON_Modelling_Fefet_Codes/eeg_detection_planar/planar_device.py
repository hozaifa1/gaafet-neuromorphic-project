"""
Planar-FeFET device model (single top-gate ablation of the optimized GAA nanosheet).
=====================================================================================
The analog conductance levels come from the planar device's MEASURED LTP pulse train
(Planar_Device_Work/outputs/lifsw2/lifsw2_lif.json, V_pgm = 2.3 V op point) — the read
current per programming pulse at a fixed sub-threshold read bias, converted to conductance
(G = I / V_read), exactly the same convention as the GAA `fefet_device.py`.

By the same 1.5x distinguishability rule used in the planar datasheet (PLANAR_DEVICE.md /
analyze_compare.py), the 15 programming pulses resolve into **10 distinguishable levels**
(the LTP is an S-curve: a flat bottom and a saturated top collapse ~5 readings into their
neighbours). Only the RELATIVE spacing matters downstream (weights are normalized by g_max),
so per-um vs absolute geometry is irrelevant here — identical treatment to the GAA ladder.
"""
import os, json
import numpy as np
import torch

_HERE = os.path.dirname(os.path.abspath(__file__))
_PLANAR_JSON = os.path.join(_HERE, "..", "Planar_Device_Work", "outputs", "lifsw2", "lifsw2_lif.json")
V_READ = 0.05          # V, sub-threshold read bias (same as GAA fefet_device.V_READ)
OP = "2.3"             # program-voltage op point (lowest clean-graded-LTP voltage; matches GAA "lowest V wins")


def _raw_currents():
    """15 measured LTP read currents (uA/um), one per programming pulse, at the 2.3 V op point."""
    lif = json.load(open(_PLANAR_JSON))
    return np.asarray(lif[OP]["ids"], dtype=float)


def _distinguishable(ids, min_ratio=1.5):
    """Greedy 1.5x-apart level count (identical rule to analyze_compare.count_levels)."""
    keep = [ids[0]]
    for v in ids[1:]:
        if v >= keep[-1] * min_ratio:
            keep.append(v)
    return np.asarray(keep)


def measured_levels(distinguishable=True, v_read=V_READ):
    """Return (levels[S], g_min, g_max) from the measured planar LTP curve.

    distinguishable=True  -> the honest 10 resolvable levels (>=1.5x apart)   [DEFAULT]
    distinguishable=False -> all 15 raw pulse-currents (optimistic sensitivity check)
    Conductance is proportional to read current at fixed V_read (G = I / V_read).
    """
    ids = _raw_currents()
    lv = _distinguishable(ids) if distinguishable else ids
    g = np.sort(ids_to_g(lv, v_read))
    return torch.from_numpy(g).float(), float(g[0]), float(g[-1])


def ids_to_g(ids_ua_um, v_read=V_READ):
    return (np.asarray(ids_ua_um, float) * 1e-6) / v_read     # A/um / V = S/um


if __name__ == "__main__":
    for dist in (True, False):
        lv, gmin, gmax = measured_levels(distinguishable=dist)
        tag = "10 distinguishable" if dist else "15 raw pulses"
        print(f"planar LTP levels ({tag}): n={lv.numel()}  "
              f"span={gmax/gmin:.0f}x ({np.log10(gmax/gmin):.2f} decades)")
