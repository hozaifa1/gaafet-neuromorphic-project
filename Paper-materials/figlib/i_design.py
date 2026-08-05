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
    note(ax, f"The window improves {span:,.0f}$\\times$ over {len(turn)} turns; "
             f"turns {int(turn[-2])} and {int(turn[-1])} change nothing.")

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
    ax2.tick_params(axis="y", direction="in", width=2.0, labelsize=16, pad=6)
    for lbl in ax2.get_yticklabels():
        lbl.set_fontweight("bold")
        lbl.set_fontsize(16)
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
    # the window peaks at the chosen thickness, so a callout placed at the peak
    # lands under the legend; hang it off the bottom of the marker line instead
    ax.annotate(f"chosen: {chosen.t_ox_nm:g} nm",
                xy=(chosen.t_ox_nm, ax.get_ylim()[0]), xytext=(10, 26),
                textcoords="offset points", fontsize=12, fontweight="bold", color=ACC)

    bold_labels(ax, "Interfacial oxide thickness T$_{ox}$ (nm)",
                "Retained ON/OFF window ($\\times$)")
    ax.yaxis.label.set_color(PGM)
    ax2.set_ylabel("I$_{off}$ ($\\mu$A/$\\mu$m)", fontweight="bold", fontsize=20,
                   labelpad=8, color=ERS)
    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax.legend(h1 + h2, l1 + l2, loc="upper right", fontsize=9, frameon=True, facecolor="white", framealpha=0.9, edgecolor="black")

    sub = d[d["eval"] == "subcoercive"].sort_values("t_ox_nm")
    penalty = float(sub[sub.t_ox_nm == 1.0].window.iloc[0] / sub[sub.t_ox_nm == 1.5].window.iloc[0])
    note(ax, f"1.0 nm buys {penalty:.0f}$\\times$ more window than 1.5 nm",
         xy=(0.30, 0.32), fontsize=12)

    return fig, d


@figure(
    "I3",
    claim="Ferroelectric thickness is a Pareto choice, not an optimum: 7 nm gives the largest "
          "retained window of the set while keeping the operating voltage at its lowest value "
          "and the gate charge -- the energy proxy -- at its smallest, so the window-optimal "
          "thickness is also the cheapest one to write.",
    source="sweeps/tfe_sweep.csv -- T_fe in {5, 7, 10, 12} nm, each at its own sub-coercive "
           "operating point",
    convention="window is a ratio; V_pgm in V; Q_gate in fC/um",
)
def I3():
    """T_fe: 3-subplot panel showing window, V_pgm and Q_gate against T_fe."""
    d = load_sweep("tfe_sweep").sort_values("t_fe_nm")
    chosen = d[d.t_fe_nm == 7.0].iloc[0]

    fig, axes = plt.subplots(1, 3, figsize=(12.0, 5.2))
    fig.subplots_adjust(wspace=0.32, left=0.10, right=0.96, top=0.92, bottom=0.14)
    for ax in axes:
        for sp in ax.spines.values():
            sp.set_linewidth(2.2)
        ax.tick_params(axis="both", which="both", direction="in", top=True, right=True,
                       width=2.0, labelsize=16, pad=6)
        ax.minorticks_on()
        for lbl in ax.get_xticklabels() + ax.get_yticklabels():
            lbl.set_fontweight("bold")
            lbl.set_fontsize(16)

    ax = axes[0]
    ax.set_yscale("log")
    ax.plot(d.t_fe_nm, d.window, "-o", color=PGM, lw=3.0, ms=10, mec="black", mew=1.4)
    ax.axvline(chosen.t_fe_nm, color=ACC, lw=2.2, ls=":")
    bold_labels(ax, "T$_{fe}$ (nm)", "Retained window ($\\times$)")
    decade_ticks(ax)

    ax = axes[1]
    ax.plot(d.t_fe_nm, d.v_pgm_V, "-s", color=ERS, lw=3.0, ms=10, mec="black", mew=1.4)
    ax.axvline(chosen.t_fe_nm, color=ACC, lw=2.2, ls=":")
    bold_labels(ax, "T$_{fe}$ (nm)", "V$_{pgm}$ (V)")

    ax = axes[2]
    ax.plot(d.t_fe_nm, d.q_gate_fC_um, "-^", color="#7b1fa2", lw=3.0, ms=10,
            mec="black", mew=1.4)
    ax.axvline(chosen.t_fe_nm, color=ACC, lw=2.2, ls=":")
    bold_labels(ax, "T$_{fe}$ (nm)", "Q$_{gate}$ (fC/$\\mu$m)")

    for ax in axes:
        ax.set_xticks(d.t_fe_nm)

    note(axes[0], f"7 nm gives peak window ({chosen.window:,.0f}$\\times$)\n"
                  f"at lowest V$_{{pgm}}$ ({chosen.v_pgm_V:g} V)",
         xy=(0.04, 0.96), fontsize=11)

    return fig, d


@figure(
    "I5",
    claim="Reading at zero gate bias achieves >5,000x retained window while avoiding the "
          "ambipolar/GIDL leakage region at negative V_G entirely. V_read = 0 V is optimal.",
    source="sweeps/vread_sweep.csv combined with raw/idvg_fine.csv",
    convention="window is a ratio; rest current in uA/um",
)
def I5():
    """V_read choice: window and rest current as a function of read gate bias."""
    d = load_raw("idvg_fine")
    vg = d["V_G_V"].to_numpy()
    i_ers = d["I_D_erased_uA_um"].to_numpy()
    i_pgm = d["I_D_programmed_uA_um"].to_numpy()
    window = i_pgm / i_ers

    old = load_sweep("vread_sweep").sort_values("vread_V")

    fig, ax = new_ax(figsize=(8.6, 5.6))
    ax2 = ax.twinx()
    ax2.tick_params(axis="y", direction="in", width=2.0, labelsize=16, pad=6)
    for lbl in ax2.get_yticklabels():
        lbl.set_fontweight("bold")
        lbl.set_fontsize(16)
    ax.set_yscale("log")
    ax2.set_yscale("log")

    # the GIDL / ambipolar region: negative V_G where the erased branch turns back up
    imin = int(np.argmin(i_ers))
    ax.axvspan(vg.min(), vg[imin], color=GREY, alpha=0.20, lw=0)

    ax.plot(vg, window, "-", color=PGM, lw=3.2, label="true retained window")
    keep = old.vread_V >= vg.min()
    ax.plot(old.vread_V[keep], old.dr[keep], "--", color=GREY, lw=2.2, marker="x",
            ms=9, mew=2.5, label="superseded virgin-referenced DR")
    ax2.plot(vg, i_ers, "-", color=ERS, lw=2.4, label="rest current (erased)")

    i0 = int(np.argmin(np.abs(vg)))
    ax.plot([vg[i0]], [window[i0]], "o", color=ACC, ms=14, mec="black", mew=2.0, zorder=5)
    ax.annotate(f"V$_{{read}}$ = 0: {window[i0]:,.0f}$\\times$",
                xy=(vg[i0], window[i0]), xytext=(-110, 25),
                textcoords="offset points", fontsize=13, fontweight="bold",
                color=ACC,
                arrowprops=dict(arrowstyle="->", lw=2.0, color=ACC))
    decade_ticks(ax)

    bold_labels(ax, "Read gate bias V$_{read}$ (V)", "Retained ON/OFF window ($\\times$)")
    ax.yaxis.label.set_color(PGM)
    ax2.set_ylabel("Rest current ($\\mu$A/$\\mu$m)", fontweight="bold", fontsize=20,
                   labelpad=8, color=ERS)
    ax.annotate("GIDL / ambipolar", xy=((vg.min() + vg[imin]) / 2, window.max() * 0.7),
                ha="center", fontsize=12, fontweight="bold")
    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax.legend(h1 + h2, l1 + l2, loc="lower right", fontsize=10, frameon=True, facecolor="white", framealpha=0.9, edgecolor="black")

    out = pd.DataFrame({"Vg_V": vg, "Id_erased_uA_um": i_ers,
                        "Id_programmed_uA_um": i_pgm, "true_window_x": window})
    return fig, out
