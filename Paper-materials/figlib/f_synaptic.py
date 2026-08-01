"""Chapter F -- synaptic behaviour.

F1 is the reference implementation for every other figure module: load, plot,
compute the annotation from the plotted arrays, return (fig, plotted_df).
"""
from __future__ import annotations

import numpy as np

from ._common import (ACC, ERS, GREY, PGM, bold_labels, decade_ticks, figure,
                      load_raw, new_ax, note)


def _verify_levels(log_g: np.ndarray, sigma: np.ndarray) -> int:
    """How many levels write-verify could place, given the measured range and noise.

    The train's own stops are not the only option: with a verify loop you place
    targets where you like, so the ceiling is set by the range and the local
    cycle-to-cycle sigma.  Greedy placement from the bottom, each target 3 sigma
    above the last.  This is `rranalyze.rr8b`'s definition, kept identical so the
    figure and the analysis can never quote different numbers.
    """
    lo, hi = float(log_g[0]), float(log_g[-1])
    n, x = 1, lo
    while True:
        x += 3.0 * float(np.interp(x, log_g, sigma))
        if x > hi:
            return n
        n += 1


@figure(
    "F1",
    claim="Fifteen identical sub-coercive pulses move the channel current monotonically "
          "over 3.79 decades; at a 3-sigma cycle-to-cycle criterion 8 of the 15 stops are "
          "separable open-loop, while write-verify placement over the same range and the "
          "same measured noise would support about 16.",
    source="raw/c2c_per_level.csv -- node t17_c2c, 11 complete repeats of one "
           "15 x 2.0 V / 100 ns train on ONE device.  Level medians and their sigma "
           "come from the same run, so no cross-run ratio is formed.",
    convention="norm.to_uA_per_um applied upstream in rranalyze.rr8b (W_eff = 90 nm)",
)
def F1():
    """LTP staircase on a log axis, with the measured cycle-to-cycle band per level."""
    c2c = load_raw("c2c_per_level")

    n = c2c["level"].to_numpy()
    g = c2c["median_uA_um"].to_numpy()
    sigma = c2c["sigma_log10"].to_numpy()
    sep = c2c["separable_from_prev"].to_numpy().astype(bool)

    # +-3 sigma read band around each level, in decades, from this same run
    lo = g * 10.0 ** (-3.0 * sigma)
    hi = g * 10.0 ** (+3.0 * sigma)

    n_sep = int(np.sum(sep[1:])) + 1            # level 1 has no predecessor to separate from
    span = np.log10(g.max() / g.min())
    bits_open = np.log2(n_sep)
    n_verify = _verify_levels(np.log10(g), sigma)

    fig, ax = new_ax(figsize=(8.2, 5.6))
    ax.set_yscale("log")

    for i in range(len(n)):
        ax.fill_between([n[i] - 0.42, n[i] + 0.42], lo[i], hi[i],
                        color=(ACC if (i == 0 or sep[i]) else GREY),
                        alpha=0.30, lw=0, zorder=1)
    ax.plot(n, g, "-", color=PGM, lw=2.6, zorder=3)
    ax.plot(n[sep | (n == 1)], g[sep | (n == 1)], "o", color=PGM, ms=9,
            mec="black", mew=1.6, zorder=4, label="separable at 3$\\sigma$")
    ax.plot(n[~sep & (n != 1)], g[~sep & (n != 1)], "s", color="white", ms=8,
            mec=ERS, mew=2.0, zorder=4, label="below the 3$\\sigma$ floor")

    ax.set_xlim(0.3, len(n) + 0.7)
    ax.set_xticks(range(1, len(n) + 1, 2))
    decade_ticks(ax)
    bold_labels(ax, "Pulse number", "I$_D$ ($\\mu$A/$\\mu$m)")
    note(ax, f"{len(n)} pulses, {span:.2f} decades\n"
             f"{n_sep} separable open-loop ({bits_open:.1f} bit)\n"
             f"$\\approx${n_verify} with write-verify ({np.log2(n_verify):.1f} bit)")
    ax.legend(loc="lower right")

    out = c2c.copy()
    out["band_lo_uA_um"] = lo
    out["band_hi_uA_um"] = hi
    return fig, out
