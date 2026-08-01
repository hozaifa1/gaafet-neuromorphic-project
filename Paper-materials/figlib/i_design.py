"""Chapter I -- design space.

Ratio metrics (window, dynamic range, igain) are invariant to the width
convention; absolute currents are not.  Every absolute current here is already
in the one convention, and nothing in this module forms a ratio across nodes.
"""
from __future__ import annotations

import numpy as np
import pandas as pd

from ._common import (ACC, ERS, GREY, PGM, bold_labels, decade_ticks, figure,
                      load_raw, load_sweep, new_ax, note)


@figure(
    "I1",
    claim="The device was reached by coordinate descent over six parameters rather than by "
          "guessing: the retained window improves by four orders of magnitude across the "
          "search, and the last two turns change nothing, which is what termination looks like.",
    source="sweeps/optimization_trajectory.csv -- one row per turn of the coordinate "
           "descent in Device_Optimization/opt.py",
    convention="window is a ratio -- invariant to the width convention",
)
def I1():
    """Coordinate-descent trajectory: retained window against optimization turn."""
    d = load_sweep("optimization_trajectory").sort_values("turn").reset_index(drop=True)
    turn = d["turn"].to_numpy()
    win = d["window"].to_numpy()

    fig, ax = new_ax(figsize=(8.6, 5.6))
    ax.set_yscale("log")
    ax.step(turn, win, where="post", color=GREY, lw=1.6, ls="--")
    ax.plot(turn, win, "-o", color=PGM, lw=3.0, ms=11, mec="black", mew=1.6, zorder=3)
    decade_ticks(ax)

    span = win.max() / win.min()
    for i, r in d.iterrows():
        above = i % 2 == 0
        ax.annotate(f"{r.parameter}\n{r.chosen_value}",
                    xy=(r.turn, r.window),
                    xytext=(0, 26 if above else -46), textcoords="offset points",
                    ha="center", va="bottom" if above else "top",
                    fontsize=11, fontweight="bold",
                    bbox=dict(boxstyle="round,pad=0.28", fc="white", ec=ACC, lw=1.6))

    ax.set_xlim(turn.min() - 0.6, turn.max() + 0.6)
    ax.set_xticks(turn)
    ax.set_ylim(win.min() / 6, win.max() * 40)
    bold_labels(ax, "Coordinate-descent turn", "Retained ON/OFF window ($\\times$)")
    note(ax, f"window improves {span:,.0f}$\\times$ over {len(turn)} turns;\n"
             f"turns {int(turn[-2])} and {int(turn[-1])} change nothing")

    return fig, d


@figure(
    "I2",
    claim="Interfacial oxide thickness sets a direct trade between retained window and "
          "off-current, and the trade is the same in both evaluation contexts: 1 nm is the "
          "best available compromise, and 1.5 nm costs almost two orders of magnitude of window.",
    source="sweeps/tox_sweep.csv -- T_ox in {0.5, 1.0, 1.5, 2.0} nm, evaluated both at a "
           "fixed 4 V write (`fixed4V`) and at each thickness's own sub-coercive operating "
           "point (`subcoercive`)",
    convention="window is a ratio; off-current is norm.to_uA_per_um (W_eff = 90 nm)",
)
def I2():
    """T_ox: retained window and off-current on a shared axis, both evaluation contexts."""
    d = load_sweep("tox_sweep")

    fig, ax = new_ax(figsize=(8.4, 5.6))
    ax2 = ax.twinx()
    ax2.tick_params(axis="y", direction="in", width=2.0, labelsize=12)
    for lbl in ax2.get_yticklabels():
        lbl.set_fontweight("bold")
    ax.set_yscale("log")
    ax2.set_yscale("log")

    styles = {"subcoercive": ("-", "o", "sub-coercive operating point"),
              "fixed4V": ("--", "s", "fixed 4 V write")}
    for ev, (ls, mk, lab) in styles.items():
        s = d[d["eval"] == ev].sort_values("t_ox_nm")
        ax.plot(s.t_ox_nm, s.window, ls, marker=mk, color=PGM, lw=3.0, ms=10,
                mec="black", mew=1.4, label=f"window, {lab}")
        ax2.plot(s.t_ox_nm, s.id_off_uA_um, ls, marker=mk, color=ERS, lw=2.4, ms=9,
                 mfc="white", mec=ERS, mew=2.0, label=f"I$_{{off}}$, {lab}")

    chosen = d[(d["eval"] == "subcoercive") & (d["t_ox_nm"] == 1.0)].iloc[0]
    ax.axvline(chosen.t_ox_nm, color=ACC, lw=2.2, ls=":")
    ax.annotate(f"chosen: {chosen.t_ox_nm:g} nm",
                xy=(chosen.t_ox_nm, chosen.window), xytext=(14, -6),
                textcoords="offset points", fontsize=12, fontweight="bold", color=ACC)

    bold_labels(ax, "Interfacial oxide thickness T$_{ox}$ (nm)",
                "Retained ON/OFF window ($\\times$)")
    ax.yaxis.label.set_color(PGM)
    ax2.set_ylabel("I$_{off}$ ($\\mu$A/$\\mu$m)", fontweight="bold", fontsize=17,
                   labelpad=10, color=ERS)
    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax.legend(h1 + h2, l1 + l2, loc="lower left", fontsize=10)

    sub = d[d["eval"] == "subcoercive"].sort_values("t_ox_nm")
    penalty = float(sub[sub.t_ox_nm == 1.0].window.iloc[0] / sub[sub.t_ox_nm == 1.5].window.iloc[0])
    note(ax, f"1.0 nm buys {penalty:.0f}$\\times$ more window than 1.5 nm",
         xy=(0.03, 0.10), fontsize=12)

    return fig, d


@figure(
    "I3",
    claim="Ferroelectric thickness is a Pareto choice, not an optimum: 7 nm gives the largest "
          "retained window of the set while keeping the operating voltage at its lowest value "
          "and the gate charge -- the energy proxy -- at its smallest, so the window-optimal "
          "thickness is also the cheapest one to write.",
    source="sweeps/tfe_sweep.csv -- T_fe in {5, 7, 10, 12} nm, each at its own sub-coercive "
           "operating point",
    convention="window is a ratio; V_op is a voltage; gate charge scales with Areafactor but "
               "is used here only as a relative marker area",
)
def I3():
    """T_fe Pareto: window against operating voltage, marker area = gate charge."""
    d = load_sweep("tfe_sweep").sort_values("t_fe_nm").reset_index(drop=True)
    q = d["qg_C"].to_numpy()
    area = 420.0 * q / q.max()

    fig, ax = new_ax(figsize=(8.2, 5.6))
    ax.set_yscale("log")
    best = int(d["window"].idxmax())
    colours = [ACC if i == best else ERS for i in range(len(d))]
    ax.scatter(d["v_op_V"], d["window"], s=area, c=colours, edgecolors="black",
               linewidths=2.0, zorder=3, alpha=0.9)

    for i, r in d.iterrows():
        ax.annotate(f"{r.t_fe_nm:g} nm", xy=(r.v_op_V, r.window),
                    xytext=(0, 22 + 6 * (i % 2)), textcoords="offset points",
                    ha="center", fontsize=13, fontweight="bold")
    decade_ticks(ax)

    chosen = d.iloc[best]
    worst_v = d[d.v_op_V > chosen.v_op_V]
    gain = float(chosen.window / worst_v.window.max()) if len(worst_v) else float("nan")
    ax.set_xlim(d.v_op_V.min() - 0.35, d.v_op_V.max() + 0.35)
    ax.set_ylim(d.window.min() / 4, d.window.max() * 12)
    bold_labels(ax, "Operating voltage V$_{op}$ (V)", "Retained ON/OFF window ($\\times$)")
    note(ax, f"marker area $\\propto$ gate charge\n"
             f"{chosen.t_fe_nm:g} nm: {gain:.1f}$\\times$ the window of the best "
             f"higher-voltage point,\nat {chosen.v_op_V:g} V and the smallest gate charge "
             f"({chosen.qg_C / q.max():.2f} of the largest)")

    return fig, d


@figure(
    "I5",
    claim="Read bias is a design variable, and zero is the right choice: the retained window "
          "is largest near V_G = 0 while the rest current is at its floor, and the gate-induced "
          "drain leakage that reopens at negative read bias is what the earlier "
          "virgin-referenced dynamic range was actually measuring.",
    source="raw/memory_window_iv.csv (RR-0, node iv_fe07b) for the true retained window and "
           "rest current -- both branches read in the SAME run, so the ratio is legitimate. "
           "The superseded virgin-referenced `dr` column is overlaid from "
           "sweeps/vread_sweep.csv and is a DIFFERENT measurement; the two are drawn "
           "together to document the disagreement, and no quantity is formed from both.",
    convention="window is a ratio; rest current is norm.to_uA_per_um (W_eff = 90 nm)",
)
def I5():
    """Read-bias design map -- and the correction to the superseded deck figure."""
    iv = load_raw("memory_window_iv").sort_values("Vg_V").reset_index(drop=True)
    vg = iv["Vg_V"].to_numpy()
    i_ers = iv["Id_erased_uA_um"].to_numpy()          # conduction current, not TotalCurrent
    i_pgm = iv["Id_programmed_uA_um"].to_numpy()
    window = i_pgm / i_ers

    old = load_sweep("vread_sweep").sort_values("vread_V")

    fig, ax = new_ax(figsize=(8.6, 5.6))
    ax2 = ax.twinx()
    ax2.tick_params(axis="y", direction="in", width=2.0, labelsize=12)
    for lbl in ax2.get_yticklabels():
        lbl.set_fontweight("bold")
    ax.set_yscale("log")
    ax2.set_yscale("log")

    # the GIDL / ambipolar region: negative V_G where the erased branch turns back up
    imin = int(np.argmin(i_ers))
    ax.axvspan(vg.min(), vg[imin], color=GREY, alpha=0.20, lw=0)

    ax.plot(vg, window, "-", color=PGM, lw=3.2, label="true retained window")
    ax.plot(old.vread_V, old.dr, "--", color=GREY, lw=2.2, marker="x", ms=9, mew=2.5,
            label="superseded virgin-referenced DR")
    ax2.plot(vg, i_ers, "-", color=ERS, lw=2.4, label="rest current (erased)")

    i0 = int(np.argmin(np.abs(vg)))
    ax.plot([vg[i0]], [window[i0]], "o", color=ACC, ms=14, mec="black", mew=2.0, zorder=5)
    ax.annotate(f"V$_{{read}}$ = 0: {window[i0]:,.0f}$\\times$",
                xy=(vg[i0], window[i0]), xytext=(10, 16), textcoords="offset points",
                fontsize=13, fontweight="bold", color=ACC)
    decade_ticks(ax)

    bold_labels(ax, "Read gate bias V$_{read}$ (V)", "Retained ON/OFF window ($\\times$)")
    ax.yaxis.label.set_color(PGM)
    ax2.set_ylabel("Rest current ($\\mu$A/$\\mu$m)", fontweight="bold", fontsize=17,
                   labelpad=10, color=ERS)
    ax.annotate("GIDL / ambipolar", xy=((vg.min() + vg[imin]) / 2, window.max() * 0.4),
                ha="center", fontsize=12, fontweight="bold")
    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax.legend(h1 + h2, l1 + l2, loc="lower right", fontsize=10)

    out = pd.DataFrame({"Vg_V": vg, "Id_erased_uA_um": i_ers,
                        "Id_programmed_uA_um": i_pgm, "true_window_x": window})
    return fig, out
