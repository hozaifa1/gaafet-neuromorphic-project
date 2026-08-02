"""Loaders and small helpers shared by every figure module.

THE CONTRACT every figure function obeys
----------------------------------------
    @figure("D2", claim="...", source="...", convention="...")
    def D2():
        df = load_raw("output_char")          # or parse_plt(...) for node data
        fig, ax = new_ax()
        ax.plot(df.Vds_V, df.Id_uA_um)
        bold_labels(ax, "V$_{DS}$ (V)", "I$_D$ ($\\mu$A/$\\mu$m)")
        return fig, df                        # df == exactly what was plotted

- return ``(fig, DataFrame)``; the DataFrame is written beside the image
- never hardcode a width, Areafactor or scale -- call ``norm.*``
- never type a measured number into an annotation -- build it with an f-string
  from the arrays you just plotted (``--lint`` enforces both)
"""
from __future__ import annotations

import re
from pathlib import Path

import numpy as np
import pandas as pd

from figs import (AUTOCAL, CALCSV, OUTPUTS, PLANAR, RAW, SNNFIG, SWEEPS,  # noqa: F401
                  HERE, ROOT, bold_labels, figure, new_ax, norm, parse_plt)

import matplotlib.pyplot as plt                                          # noqa: F401,E402
from matplotlib.ticker import LogLocator, NullFormatter                  # noqa: F401,E402

# One colour vocabulary for the whole paper.
ERS = "#1f4e79"      # erased / low-conductance state
PGM = "#c00000"      # programmed / high-conductance state
ACC = "#2e8b57"      # third series, annotations that carry meaning
GREY = "#7f7f7f"
LEVELS = plt.get_cmap("viridis")


def load_raw(name: str) -> pd.DataFrame:
    return pd.read_csv(RAW / f"{name}.csv")


def load_sweep(name: str) -> pd.DataFrame:
    return pd.read_csv(SWEEPS / f"{name}.csv")


def load_cal(name: str) -> pd.DataFrame:
    return pd.read_csv(CALCSV / f"{name}.csv")


def node_files(node: str, pattern: str) -> list[Path]:
    """Every .plt in a run node matching a regex, sorted by name.

    e.g. node_files("t8_ltp", r"^p\\d\\d_write_")  ->  the 15 write transients
    """
    d = OUTPUTS / node
    if not d.is_dir():
        raise FileNotFoundError(f"no such run node: {d}")
    rx = re.compile(pattern)
    hits = sorted(p for p in d.glob("*.plt") if rx.search(p.name))
    if not hits:
        raise FileNotFoundError(f"{node}: nothing matches {pattern!r}")
    return hits


def id_uA_um(df: pd.DataFrame, contact: str = "drain_contact") -> np.ndarray:
    """Contact current from a parsed .plt, in the paper's one convention.

    Uses the CONDUCTION current (eCurrent + hCurrent) where the split exists, so
    a fast voltage ramp's displacement term through the gate-drain overlap is
    removed exactly instead of argued away.
    """
    e, h = f"{contact} eCurrent", f"{contact} hCurrent"
    if e in df.columns and h in df.columns:
        return norm.to_uA_per_um(df[e].to_numpy() + df[h].to_numpy())
    return norm.to_uA_per_um(df[f"{contact} TotalCurrent"].to_numpy())


def decade_ticks(ax, axis: str = "y") -> None:
    """Origin-style log decade ticks with minor ticks, no minor labels."""
    a = ax.yaxis if axis == "y" else ax.xaxis
    a.set_major_locator(LogLocator(base=10))
    a.set_minor_locator(LogLocator(base=10, subs=tuple(np.arange(2, 10) * 0.1), numticks=100))
    a.set_minor_formatter(NullFormatter())


def note(ax, text: str, xy=None, **kw) -> None:
    """A bold caption strip UNDER the axes.  The caller builds `text` with an f-string.

    Deliberately not drawn inside the axes.  An audit of the first full draw found
    the same defect in fifteen of twenty-eight figures: a computed annotation
    sitting on top of the curve, the legend or a marker.  Putting the numbers in a
    strip below the frame cannot collide with data, and a reader looking for "what
    does this figure say" finds them in the same place on every figure.

    `xy` is accepted and ignored so that existing call sites keep working; pass
    `inside=True` for the rare case that genuinely needs an in-axes label.
    """
    inside = kw.pop("inside", False)
    kw.setdefault("fontsize", 12)
    if inside:
        kw.setdefault("ha", "left")
        kw.setdefault("va", "top")
        ax.text(*(xy or (0.04, 0.94)), text, transform=ax.transAxes,
                fontweight="bold", **kw)
        return
    kw.setdefault("ha", "center")
    kw.setdefault("va", "top")
    ax.annotate(text, xy=(0.5, -0.19), xycoords="axes fraction",
                fontweight="bold", annotation_clip=False, **kw)
