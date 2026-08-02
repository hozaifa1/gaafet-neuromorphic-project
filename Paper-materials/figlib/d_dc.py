"""Chapter D -- DC device characteristics.

Both figures read node `iv_fe07b` / `t11_idvd`, the runs made after the original
`iv_fe07` node was found to be dead: it ran with tau_E = tau_P = 1e-4 s, so its
500 us write hold was five depolarization time constants and the model relaxed
back inside the same hold.  Its probe read P_y = +2.3267e-7 (erased) against
+2.3238e-7 C/cm2 (programmed) -- 0.1 % apart against a P_r of 3.2e-5 -- and the
two branches coincided above V_G = +0.2 V.  Nothing from that node is used here.

V_t and SS are extracted with `rranalyze`'s own functions rather than
reimplemented, so the figure and the analysis cannot disagree.
"""
from __future__ import annotations

import sys

import numpy as np
import pandas as pd

from ._common import (ACC, ERS, GREY, LEVELS, PGM, ROOT, bold_labels,
                      decade_ticks, figure, load_raw, new_ax, note)

sys.path.insert(0, str(ROOT))
from rranalyze import ss_mv_dec, vth_cc          # noqa: E402  the one extraction rule

I_CC_UA_UM = 1e-2      # constant-current threshold criterion, printed on the figure


@figure(
    "D1",
    claim="The retained transfer characteristic separates into two branches that stay apart "
          "at zero gate bias, giving a memory window of about 0.39 V and a retained on/off "
          "ratio of order five thousand at V_G = 0, with a subthreshold slope fitted over "
          "more than two decades rather than read off a single point.",
    source="raw/memory_window_iv.csv -- RR-0, node iv_fe07b: +/-2 V / 5 us write, then one "
           "continuous 500 ns read ramp, analysed on the CONDUCTION current (eCurrent + "
           "hCurrent) so the ramp's displacement term through the 15 nm gate-drain overlap "
           "is removed exactly. Both branches come from the same run.",
    convention="norm.to_uA_per_um applied upstream in rranalyze.rr0 (W_eff = 90 nm)",
)
def D1():
    """Retained I_D-V_GS, decorated: V_t, SS fits, the window, and the ambipolar tail."""
    d = load_raw("memory_window_iv").sort_values("Vg_V").reset_index(drop=True)
    vg = d["Vg_V"].to_numpy()
    i_ers = d["Id_erased_uA_um"].to_numpy()
    i_pgm = d["Id_programmed_uA_um"].to_numpy()

    vt_ers = vth_cc(vg, i_ers, I_CC_UA_UM)
    vt_pgm = vth_cc(vg, i_pgm, I_CC_UA_UM)
    mw = vt_ers - vt_pgm
    ss_ers = ss_mv_dec(vg, i_ers)
    ss_pgm = ss_mv_dec(vg, i_pgm)

    i0 = int(np.argmin(np.abs(vg)))
    onoff = i_pgm[i0] / i_ers[i0]
    vmin_ers = vg[int(np.argmin(i_ers))]
    vmin_pgm = vg[int(np.argmin(i_pgm))]

    fig, ax = new_ax(figsize=(8.6, 5.8))
    ax.set_yscale("log")
    ax.plot(vg, i_ers, "-", color=ERS, lw=3.0, label="erased")
    ax.plot(vg, i_pgm, "-", color=PGM, lw=3.0, label="programmed")

    ax.axhline(I_CC_UA_UM, color=GREY, lw=1.8, ls=":")
    for vt, colour in ((vt_ers, ERS), (vt_pgm, PGM)):
        ax.plot([vt], [I_CC_UA_UM], "v", color=colour, ms=13, mec="black", mew=1.6, zorder=5)
    ax.annotate("", xy=(vt_ers, I_CC_UA_UM), xytext=(vt_pgm, I_CC_UA_UM),
                arrowprops=dict(arrowstyle="<->", lw=2.4, color=ACC))
    ax.text((vt_ers + vt_pgm) / 2, I_CC_UA_UM * 2.4,
            f"$\\Delta$V$_t$ = {mw:.3f} V", ha="center", fontweight="bold",
            fontsize=13, color=ACC)

    # on/off at the read point
    ax.annotate("", xy=(vg[i0], i_pgm[i0]), xytext=(vg[i0], i_ers[i0]),
                arrowprops=dict(arrowstyle="<->", lw=2.4, color="black"))
    ax.text(vg[i0] + 0.03, np.sqrt(i_pgm[i0] * i_ers[i0]),
            f"{onoff:,.0f}$\\times$ at V$_G$ = 0", fontweight="bold", fontsize=13)

    # the ambipolar / GIDL upturn, named rather than cropped out
    for vm, colour in ((vmin_ers, ERS), (vmin_pgm, PGM)):
        ax.axvline(vm, color=colour, lw=1.4, ls="--", alpha=0.55)
    ax.text(min(vmin_ers, vmin_pgm) - 0.05, i_pgm.max() * 0.3,
            "ambipolar / GIDL\nminima", ha="right", fontweight="bold", fontsize=11)

    decade_ticks(ax)
    ax.set_ylim(min(i_ers.min(), i_pgm.min()) / 4, max(i_ers.max(), i_pgm.max()) * 30)
    bold_labels(ax, "V$_{GS}$ (V)", "I$_D$ ($\\mu$A/$\\mu$m)")
    note(ax, f"V$_t$ at I$_{{cc}}$ = {I_CC_UA_UM:g} $\\mu$A/$\\mu$m\n"
             f"SS = {ss_ers:.1f} / {ss_pgm:.1f} mV/dec (erased / programmed),\n"
             f"steepest fit spanning $\\geq$2 decades",
         xy=(0.03, 0.97), fontsize=11)
    ax.legend(loc="lower right", fontsize=12)

    out = pd.DataFrame({"Vg_V": vg, "Id_erased_uA_um": i_ers,
                        "Id_programmed_uA_um": i_pgm, "window_x": i_pgm / i_ers})
    return fig, out


@figure(
    "D2",
    claim="Every analog state of the ladder is a well-behaved transistor: the output "
          "characteristic is ohmic at low drain bias and saturates cleanly, so the stored "
          "polarization changes the channel conductance without changing the character of "
          "the device.",
    source="raw/output_char.csv -- RR-2, node t11_idvd: I_D-V_DS from 0 to 1.0 V after "
           "erase, after program, and at LTP levels 3, 6, 9, 12 and 15, at V_G = 0 and "
           "V_G = 0.2 V. One run per family.",
    convention="norm.to_uA_per_um applied upstream in rranalyze.rr2 (W_eff = 90 nm)",
)
def D2():
    """Output characteristics for the erased, programmed and intermediate analog states."""
    d = load_raw("output_char")
    order = ["ers", "ltp03", "ltp06", "ltp09", "ltp12", "ltp15", "pgm"]
    labels = {"ers": "erased", "pgm": "programmed"}
    vg_show = float(d["Vg_V"].max())               # the biased family reads more clearly
    s_all = d[np.isclose(d["Vg_V"], vg_show)]

    fig, ax = new_ax(figsize=(8.6, 5.6))
    rows, rvals = [], []
    for k, state in enumerate(order):
        s = s_all[s_all["state"] == state].sort_values("Vds_V")
        if s.empty:
            continue
        colour = LEVELS(k / (len(order) - 1))
        ax.plot(s.Vds_V, s.Id_uA_um, "-o", color=colour, lw=2.6, ms=5, mec="black",
                mew=0.8, label=labels.get(state, state.replace("ltp", "LTP ")))
        low = s[s.Vds_V <= 0.1]
        if len(low) > 2:
            rvals.append(float(np.corrcoef(low.Vds_V, low.Id_uA_um)[0, 1]))
        rows.append(s)

    ax.set_xlim(0, float(s_all.Vds_V.max()) * 1.02)
    bold_labels(ax, "V$_{DS}$ (V)", "I$_D$ ($\\mu$A/$\\mu$m)")
    ax.legend(loc="lower right", fontsize=11, ncol=2)
    note(ax, f"read at V$_G$ = {vg_show:g} V\n"
             f"linear-region correlation r = {min(rvals):.3f}$-${max(rvals):.3f} "
             f"over V$_{{DS}}$ $\\leq$ 0.1 V",
         xy=(0.42, 0.30), fontsize=12)

    ins = ax.inset_axes([0.09, 0.56, 0.32, 0.36])
    for k, state in enumerate(order):
        s = s_all[(s_all["state"] == state) & (s_all["Vds_V"] <= 0.1)].sort_values("Vds_V")
        if not s.empty:
            ins.plot(s.Vds_V, s.Id_uA_um, "-o", color=LEVELS(k / (len(order) - 1)),
                     lw=2.0, ms=4)
    ins.set_xlabel("V$_{DS}$ (V)", fontweight="bold", fontsize=10)
    ins.set_ylabel("I$_D$", fontweight="bold", fontsize=10)
    ins.tick_params(direction="in", labelsize=8, width=1.4)
    for sp in ins.spines.values():
        sp.set_linewidth(1.6)

    return fig, pd.concat(rows, ignore_index=True)
