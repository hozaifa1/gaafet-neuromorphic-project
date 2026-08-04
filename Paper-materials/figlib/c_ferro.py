"""Chapter C -- ferroelectric material and gate-stack electrostatics.

These two figures sit in one panel because the contrast between them IS the
result: the same HZO gives a full material loop in a metal-ferroelectric-metal
capacitor and a deep minor loop in the gate stack, and the difference is the
MFIS voltage divider.

Polarization and electric field are untouched by the width convention --
Areafactor scales contact currents and charges only, never the field solve --
so nothing here needs `norm`.
"""
from __future__ import annotations

import numpy as np
import pandas as pd

from ._common import (ACC, CALCSV, ERS, GREY, PGM, bold_labels, figure,
                      load_cal, new_ax, note, plt)

AREAFACTOR_FREE = "polarization / field: Areafactor-independent"


def _zero_cross(x: np.ndarray, y: np.ndarray) -> list[float]:
    """Every x where y changes sign, linearly interpolated."""
    out = []
    for k in range(1, len(y)):
        if y[k - 1] == 0.0:
            out.append(float(x[k - 1]))
        elif y[k - 1] * y[k] < 0:
            f = -y[k - 1] / (y[k] - y[k - 1])
            out.append(float(x[k - 1] + f * (x[k] - x[k - 1])))
    return out


@figure(
    "C1",
    claim="A standalone metal-ferroelectric-metal capacitor reproduces the calibrated HZO "
          "parameters once the sweep amplitude is large enough to saturate the loop; a sweep "
          "to twice the coercive voltage does not saturate it, so the amplitude series is "
          "evidence that the reported loop is saturated rather than an assertion that it is.",
    source="Calibration/csvs/mfm_pe_loop.csv -- RR-1, standalone TiN/HZO(7 nm)/TiN nodes "
           "mfm_pe196, mfm_pe300 and mfm_pe500 (sweep amplitudes 1.96, 3.00 and 5.00 V). "
           "No semiconductor in the structure, so this measures the material.",
    convention=AREAFACTOR_FREE,
)
def C1():
    """Saturated MFM P-E loop, with the unsaturated amplitudes kept as the control."""
    d = load_cal("mfm_pe_loop")
    amps = sorted(d["vmax_V"].unique())
    sat = max(amps)

    fig, ax = new_ax(figsize=(8.4, 5.8))
    rows, ext = [], {}
    for k, v in enumerate(amps):
        s = d[d["vmax_V"] == v]
        saturated = np.isclose(v, sat)
        colour = PGM if saturated else ("#4d4d4d" if k == 0 else "#a6a6a6")
        dash = "-" if saturated else (":" if k == 0 else "--")
        for br in ("up", "down"):
            b = s[s["branch"] == br].sort_values("t_s")
            if b.empty:
                continue
            ax.plot(b.E_MV_cm, b.P_uC_cm2, dash, color=colour,
                    lw=3.2 if saturated else 2.2,
                    alpha=1.0,
                    label=(f"$\\pm${v:.2f} V" if br == "up" else None))
            rows.append(b)
            if saturated:
                e = b.E_MV_cm.to_numpy()
                p = b.P_uC_cm2.to_numpy()
                # np.interp REQUIRES increasing x and does not check: the up branch
                # sweeps E downward, so interpolating it as-is silently returned the
                # saturation value instead of the remanent one and put |P_r| at
                # 35.99 instead of 31.99.  Sort first.
                o = np.argsort(e)
                ext.setdefault("Pr", []).append(abs(float(np.interp(0.0, e[o], p[o]))))
                ext.setdefault("Fc", []).extend(abs(c) for c in _zero_cross(e, p))
                ext.setdefault("Ps", []).append(float(np.abs(p).max()))

    p_r = float(np.mean(ext["Pr"]))
    f_c = float(np.mean(ext["Fc"]))
    p_s = float(np.max(ext["Ps"]))

    ax.axhline(0, color="black", lw=1.4)
    ax.axvline(0, color="black", lw=1.4)
    for sign in (-1, 1):
        ax.axvline(sign * f_c, color=ACC, lw=2.0, ls="--")
        ax.plot([0], [sign * p_r], "o", color=ACC, ms=11, mec="black", mew=1.6, zorder=5)

    bold_labels(ax, "Electric field E (MV/cm)", "Polarization P ($\\mu$C/cm$^2$)")
    ax.legend(loc="upper left", fontsize=12, title="sweep amplitude",
              title_fontproperties={"weight": "bold", "size": 11})
    note(ax, f"saturated loop ($\\pm${sat:.2f} V):\n"
             f"P$_s$ = {p_s:.2f}, |P$_r$| = {p_r:.2f} $\\mu$C/cm$^2$, "
             f"F$_c$ = {f_c:.3f} MV/cm",
         xy=(0.35, 0.20), fontsize=12)

    out = pd.concat(rows, ignore_index=True)
    return fig, out


@figure(
    "C2",
    claim="The polarization loop measured through the gate stack is a deep minor loop, not the "
          "HZO material loop: a four-volt gate sweep delivers only about half the coercive "
          "field to the ferroelectric, so the MFIS voltage divider -- not the material -- sets "
          "what the gate can switch.",
    source="Calibration/csvs/pe_loop_{up,down}_signed.csv -- the gate-stack sweep, "
           "sign-corrected. The raw pe_loop_{up,down}.csv are inverted because the "
           "top-stack probe's +y axis points away from the channel; the *_signed files "
           "carry the correction and are the ones used here.",
    convention=AREAFACTOR_FREE,
)
def C2():
    """MFIS minor loop, sign-corrected, against the material coercive field."""
    up = pd.read_csv(CALCSV / "pe_loop_up_signed.csv")
    dn = pd.read_csv(CALCSV / "pe_loop_down_signed.csv")

    mfm = load_cal("mfm_pe_loop")
    sat = mfm[mfm["vmax_V"] == mfm["vmax_V"].max()]
    f_c = float(np.mean([abs(c) for br in ("up", "down")
                         for c in _zero_cross(
                             sat[sat.branch == br].sort_values("t_s").E_MV_cm.to_numpy(),
                             sat[sat.branch == br].sort_values("t_s").P_uC_cm2.to_numpy())]))

    fig, axes = plt.subplots(1, 2, figsize=(13.0, 5.4))
    for ax in axes:
        for sp in ax.spines.values():
            sp.set_linewidth(2.0)
        ax.tick_params(axis="both", which="both", direction="in", top=False, right=False,
                       width=2.0, labelsize=12)
        ax.minorticks_on()
        for lbl in ax.get_xticklabels() + ax.get_yticklabels():
            lbl.set_fontweight("bold")
        ax.axhline(0, color="black", lw=1.2)
        ax.axvline(0, color="black", lw=1.2)

    ax = axes[0]
    ax.plot(up.Vg_V, up.P_uC_cm2, "-", color=PGM, lw=3.0, label="forward")
    ax.plot(dn.Vg_V, dn.P_uC_cm2, "-", color=ERS, lw=3.0, label="reverse")
    bold_labels(ax, "Gate voltage V$_G$ (V)", "Polarization P ($\\mu$C/cm$^2$)")
    ax.legend(loc="upper left", fontsize=12)

    ax = axes[1]
    e_all = np.r_[up.E_MV_cm.to_numpy(), dn.E_MV_cm.to_numpy()]
    reach = float(np.abs(e_all).max())
    ax.plot(up.E_MV_cm, up.P_uC_cm2, "-", color=PGM, lw=3.0)
    ax.plot(dn.E_MV_cm, dn.P_uC_cm2, "-", color=ERS, lw=3.0)
    for sign in (-1, 1):
        ax.axvline(sign * f_c, color=ACC, lw=2.4, ls="--")
    ax.axvspan(-reach, reach, color=GREY, alpha=0.18, lw=0)
    ax.set_xlim(-1.25 * f_c, 1.25 * f_c)
    bold_labels(ax, "Field in the HZO, E$_{FE}$ (MV/cm)",
                "Polarization P ($\\mu$C/cm$^2$)")
    note(ax, f"The $\\pm$4 V gate sweep reaches {reach:.3f} MV/cm, "
             f"{reach / f_c:.2f} of the material coercive field "
             f"F$_c$ = {f_c:.3f} MV/cm measured in C1.")
    ax.annotate("F$_c$", xy=(f_c, ax.get_ylim()[1] * 0.75), xytext=(6, 0),
                textcoords="offset points", fontweight="bold", fontsize=14, color=ACC)

    out = pd.concat([up.assign(branch="forward"), dn.assign(branch="reverse")],
                    ignore_index=True)
    return fig, out
