"""Chapter H -- retention and read disturb.

The rule this chapter exists to obey: **wait for the device to settle before
reading it, and say how long you waited.**  Reading too early manufactured three
separate fabricated failures in this project -- a retention collapse, a
read-disturb collapse and an endurance collapse -- each of which looked like
honest bad news.  Every figure here therefore SHOWS the post-write settling
transient and measures only on the plateau after it, with the wait time printed.

Endurance is deliberately absent.  The Preisach ferroelectric model carries no
fatigue, wake-up or imprint term, so cycling it produces a flat line because the
equations say so, not because the device is good.
"""
from __future__ import annotations

import numpy as np
import pandas as pd

from ._common import (ACC, ERS, GREY, PGM, bold_labels, decade_ticks, figure,
                      load_raw, new_ax, note)

TAU_P_S = 1e-5          # app.par depolarization time constant; 5 tau_P is "settled"


def _split_settling(t: np.ndarray, g: np.ndarray) -> tuple[int, float, float]:
    """Index where the plateau starts, the plateau value, and its spread in %.

    Identical rule to ``rranalyze.rr4``: the plateau is the tail over which the
    value stays within 1 % of its final value.  Kept identical so the figure and
    the analysis can never quote different settling times.
    """
    gf = float(g[-1])
    flat = np.abs(g - gf) <= 0.01 * abs(gf)
    i0 = int(np.argmax(flat)) if flat.any() else len(g) - 1
    tail = g[i0:]
    return i0, gf, float((tail.max() - tail.min()) / abs(gf) * 100.0)


@figure(
    "H1",
    claim="The post-write state relaxes on the depolarization time constant and then holds: "
          "the first decade of the hold is settling, not loss, and only the plateau after it "
          "is a retention measurement.",
    source="raw/leak_retention.csv -- node t9_leak, single 100 us hold after a 15-pulse "
           "potentiation train. Single node; no cross-run ratio is formed.",
    convention="norm.to_uA_per_um applied upstream in rebuild_raw.py (W_eff = 90 nm)",
)
def H1():
    """The short retention hold, with settling and plateau separated on a log-time axis."""
    d = load_raw("leak_retention").sort_values("t_us").reset_index(drop=True)
    t_us = d["t_us"].to_numpy()
    g = d["G_uA_um"].to_numpy()

    # log axis cannot show t = 0; drop it and say so rather than silently shifting
    keep = t_us > 0
    t_us, g = t_us[keep], g[keep]
    i0, g_plateau, spread = _split_settling(t_us, g)
    t_settle = t_us[i0]
    drift = (g[-1] / g[i0] - 1.0) * 100.0

    fig, ax = new_ax(figsize=(8.0, 5.4))
    ax.set_xscale("log")
    ax.axvspan(t_us[0], t_settle, color=GREY, alpha=0.22, lw=0)
    ax.axhspan(g_plateau * 0.99, g_plateau * 1.01, color=ACC, alpha=0.28, lw=0)
    ax.plot(t_us, g, "-o", color=PGM, lw=2.6, ms=6, mec="black", mew=1.0)
    ax.axhline(g_plateau, color=ACC, lw=2.2, ls="--")

    ax.set_ylim(0, max(g) * 1.12)
    bold_labels(ax, "Hold time ($\\mu$s)", "I$_D$ ($\\mu$A/$\\mu$m)")
    note(ax, f"settling: t < {t_settle:.0f} $\\mu$s = {t_settle * 1e-6 / TAU_P_S:.0f} "
             f"$\\tau_P$\nplateau {g_plateau:.3g} $\\mu$A/$\\mu$m $\\pm$1 % band\n"
             f"drift on the plateau {drift:+.2f} %",
         xy=(0.40, 0.94))
    ax.annotate("post-write settling", xy=(np.sqrt(t_us[0] * t_settle), max(g) * 0.55),
                ha="center", fontweight="bold", fontsize=12, color="black")

    out = pd.DataFrame({"t_us": t_us, "G_uA_um": g,
                        "phase": np.where(np.arange(len(g)) < i0, "settling", "plateau")})
    return fig, out


@figure(
    "H4",
    claim="After the depolarization transient the retained state is flat to better than "
          "1 % across the last two decades of a 10 ms hold, at 300 K and 400 K and for a "
          "mid-ladder analog state as well as the fully programmed one; no decay is "
          "resolvable, so a bound is reported rather than a ten-year extrapolation.",
    source="raw/retention_long.csv -- RR-4 nodes t12_ret (300 K, programmed), t12_ret400 "
           "(400 K, programmed) and t12_ret_l8 (300 K, LTP level 8). Each series is one "
           "node; nothing is divided across nodes.",
    convention="norm.to_uA_per_um applied upstream in rranalyze.rr4 (W_eff = 90 nm)",
)
def H4():
    """Long retention at two temperatures and two stored states, normalized to the plateau.

    Deliberately NOT extrapolated to ten years.  The measurement spans 10 ms; ten
    years is eleven decades beyond it and the plateau is flat to the solver's own
    resolution, so an extrapolation would be reporting a fit's noise floor as
    physics.  No activation energy is extracted either: both temperatures reach
    flat plateaus, the plateau LEVELS differ through the temperature dependence of
    the drain current rather than through polarization loss, and the Preisach model
    contains no thermally activated retention term.
    """
    d = load_raw("retention_long")
    d = d[d["seg"].astype(str).str.startswith("hold")]      # drop the per-level settling holds

    series = [("t12_ret", 300, "programmed", PGM, "o", "300 K, programmed"),
              ("t12_ret400", 400, "programmed", "#e07b00", "s", "400 K, programmed"),
              ("t12_ret_l8", 300, "ltp_level_8", ERS, "^", "300 K, LTP level 8")]

    fig, ax = new_ax(figsize=(8.4, 5.6))
    ax.set_xscale("log")
    rows, notes = [], []
    for node, T, state, colour, mk, label in series:
        s = d[d["node"] == node].sort_values("t_rel_s")
        t = s["t_rel_s"].to_numpy()
        g = s["G_uA_um"].to_numpy()
        keep = t > 0
        t, g = t[keep], g[keep]
        i0, g_plateau, spread = _split_settling(t, g)
        dec = np.log10(t[-1] / max(t[i0], 1e-12))

        ax.plot(t[:i0 + 1] * 1e3, g[:i0 + 1] / g_plateau, "-", color=colour, lw=1.8,
                alpha=0.40)
        ax.plot(t[i0:] * 1e3, g[i0:] / g_plateau, "-", color=colour, lw=2.8, marker=mk,
                ms=5, markevery=12, mec="black", mew=0.8, label=label)
        notes.append(f"{label}: settled at {t[i0] * 1e6:.0f} $\\mu$s "
                     f"= {t[i0] / TAU_P_S:.0f} $\\tau_P$, flat to {spread:.2f} % "
                     f"over {dec:.1f} decades")
        rows.append(pd.DataFrame({"node": node, "T_K": T, "state": state,
                                  "t_rel_s": t, "G_uA_um": g,
                                  "G_over_plateau": g / g_plateau,
                                  "phase": np.where(np.arange(len(g)) < i0,
                                                    "settling", "plateau"),
                                  "plateau_uA_um": g_plateau,
                                  "plateau_spread_pct": spread}))

    ax.axhspan(0.99, 1.01, color=ACC, alpha=0.25, lw=0)
    # the post-write overshoot runs to roughly 9x the plateau; on a linear
    # axis it is clipped off the top, and the overshoot is the point of the
    # figure -- it is what makes reading too early look like data loss
    ax.set_yscale("log")
    decade_ticks(ax)
    bold_labels(ax, "Hold time (ms)", "I$_D$ / plateau value")
    note(ax, "\n".join(notes), xy=(0.03, 0.97), fontsize=11)
    # the retention traces run flat across the top of the axes, so an
    # upper-corner legend sits on them
    # on a log axis the settled plateau runs along the bottom and the
    # overshoot along the left, leaving the upper right clear
    ax.legend(loc="upper right", fontsize=10)

    return fig, pd.concat(rows, ignore_index=True)


@figure(
    "H8",
    claim="A zero-gate-bias read does no work on the ferroelectric, and the retained state "
          "is unchanged to the solver's resolution over nine hundred and ninety thousand "
          "equivalent reads.",
    source="raw/read_disturb.csv -- RR-9 node t15_disturb, 1e6 reads at V_read = 0. "
           "Before and after are the same run.",
    convention="norm.to_uA_per_um applied upstream in rranalyze.rr9 (W_eff = 90 nm)",
)
def H8():
    """Read disturb, measured from the settled state -- with the transient still shown.

    Measured from the immediate post-write value this run reads -84.7 % and a
    window collapse from 3702x to 568x.  That drop is the depolarization
    transient, not disturb.  Both are drawn here so the distinction is visible
    rather than asserted.
    """
    d = load_raw("read_disturb").sort_values("equivalent_reads").reset_index(drop=True)
    n = d["equivalent_reads"].to_numpy()
    g = d["G_uA_um"].to_numpy()

    keep = n > 0
    n, g = n[keep], g[keep]
    # Settled window taken at 1e4 equivalent reads, matching rranalyze.rr9's
    # t_settled: 1e4 reads at 100 ns each is 1 ms, a hundred depolarization time
    # constants.  Letting the generic 1 % rule pick the boundary here would start
    # the measurement inside the tail of the transient and report its remainder
    # as disturb.
    N_SETTLED = 1e4
    i0 = int(np.argmax(n >= N_SETTLED))
    g_plateau = float(g[i0])
    drift = (g[-1] / g[i0] - 1.0) * 100.0
    peak = float(g.max())

    fig, ax = new_ax(figsize=(8.2, 5.4))
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.axvspan(n[0], n[i0], color=GREY, alpha=0.22, lw=0)
    ax.plot(n[:i0 + 1], g[:i0 + 1], "-", color=GREY, lw=2.4)
    ax.plot(n[i0:], g[i0:], "-o", color=PGM, lw=3.0, ms=6, mec="black", mew=1.0)
    ax.set_ylim(g.min() / 3.0, g.max() * 3.0)
    ax.axhline(g_plateau, color=ACC, lw=2.0, ls="--")
    decade_ticks(ax, "y")

    bold_labels(ax, "Equivalent reads at V$_{read}$ = 0",
                "I$_D$ ($\\mu$A/$\\mu$m)")
    note(ax, f"measured from {n[i0]:.0g} reads onward\n"
             f"{drift:+.4f} % over {n[-1] - n[i0]:.1e} reads\n"
             f"apparent loss if read unsettled: "
             f"{(g_plateau / peak - 1) * 100:+.1f} % ($\\tau_P$ transient, not disturb)",
         xy=(0.30, 0.42), fontsize=11)

    out = pd.DataFrame({"equivalent_reads": n, "G_uA_um": g,
                        "phase": np.where(np.arange(len(g)) < i0, "settling", "plateau")})
    return fig, out
