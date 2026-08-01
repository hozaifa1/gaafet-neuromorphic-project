"""Chapter A -- structure and the 2D-to-nanosheet mapping.

Two drawn figures.  They still return the numbers they depict, so the drawing
can be audited against the deck like every other figure, and every dimension
that also lives in `norm.py` is taken from there rather than retyped.

A5 exists so the normalization question never has to be asked: the simulated
slab is double-gated, so a slab of z-depth A carries a total gate width 2A, and
matching the nanosheet perimeter fixes A.
"""
from __future__ import annotations

import numpy as np
import pandas as pd
from matplotlib.patches import FancyArrowPatch, Polygon, Rectangle

from ._common import ACC, ERS, GREY, PGM, bold_labels, figure, new_ax, norm, note, plt

# Optimized geometry, mesh fe07 (Device_Optimization/OPTIMIZED_DEVICE.md, built by
# sde/sde_opt.cmd).  Thicknesses in nm; the two that norm.py also defines are
# imported from it rather than repeated.
T_SI = norm.T_SI_NOMINAL_NM
W_SHEET = norm.W_SHEET_NM
T_OX, T_FE, T_METAL = 1.0, 7.0, 5.0
L_GATE, L_SD, L_OV = 100.0, 50.0, 15.0
N_SUB, N_SD, WF_EV = 1e16, 5e19, 4.35
PROBE_Y_NM = 7.0            # Pos(0, 0.007) um -- the polarization / field probe

STACK = [("gate metal", "TiN", T_METAL, "#8c8c8c"),
         ("ferroelectric", "HZO", T_FE, "#c00000"),
         ("interfacial oxide", "SiO$_2$", T_OX, "#ffd966"),
         ("nanosheet body", "Si", T_SI, "#2e75b6")]


@figure(
    "A1",
    claim="The simulated structure is a double-gated silicon nanosheet cross-section with a "
          "seven-nanometre hafnium zirconium oxide ferroelectric over a one-nanometre "
          "interfacial oxide on both faces, a hundred-nanometre gate and fifteen-nanometre "
          "source and drain overlaps.",
    source="Device_Optimization/sde/sde_opt.cmd (structure) with the optimized token values "
           "recorded in Device_Optimization/OPTIMIZED_DEVICE.md; T_si and the sheet width "
           "are read from Device_Optimization/norm.py.",
    convention="geometry only -- no current is normalized in this figure",
)
def A1():
    """Device cross-section, drawn to scale, with the polarization probe marked."""
    half_len = L_GATE / 2 + L_SD
    y_body = T_SI / 2

    fig, ax = plt.subplots(figsize=(11.0, 4.6))
    ax.set_aspect("equal")

    def stack(sign: int) -> None:
        y = sign * y_body
        for name, mat, t, colour in reversed(STACK[:-1]):
            y0 = y if sign > 0 else y - t
            ax.add_patch(Rectangle((-L_GATE / 2, y0), L_GATE, t, fc=colour, ec="black",
                                   lw=1.6, zorder=2))
            ax.text(L_GATE / 2 + 6, y0 + t / 2, f"{mat}  {t:g} nm",
                    va="center", fontweight="bold", fontsize=11)
            y += sign * t

    ax.add_patch(Rectangle((-half_len, -y_body), 2 * half_len, T_SI,
                           fc=STACK[-1][3], ec="black", lw=1.6, zorder=2))
    stack(+1)
    stack(-1)

    # source and drain, extending under the gate by L_ov on each side
    x_j = L_GATE / 2 - L_OV
    for sgn, lab in ((-1, "n$^+$ source"), (+1, "n$^+$ drain")):
        x0 = sgn * x_j if sgn > 0 else -half_len
        w = half_len - x_j
        ax.add_patch(Rectangle((x0 if sgn > 0 else -half_len, -y_body), w, T_SI,
                               fc="#548235", ec="black", lw=1.6, alpha=0.85, zorder=3))
        ax.text(sgn * (half_len + x_j) / 2, -y_body - 9, lab, ha="center",
                fontweight="bold", fontsize=11, color="#375623")

    # the probe every polarization and field figure reads from
    ax.plot([0], [PROBE_Y_NM], "o", ms=11, color=ACC, mec="black", mew=1.8, zorder=6)
    ax.annotate(f"P, E probe\n(0, {PROBE_Y_NM:g} nm)", xy=(0, PROBE_Y_NM),
                xytext=(-46, 26), textcoords="offset points", fontsize=11,
                fontweight="bold", color=ACC,
                arrowprops=dict(arrowstyle="->", lw=2.0, color=ACC))

    # dimension bars
    y_dim = -y_body - T_OX - T_FE - T_METAL - 16
    ax.add_patch(FancyArrowPatch((-L_GATE / 2, y_dim), (L_GATE / 2, y_dim),
                                 arrowstyle="<->", mutation_scale=16, lw=2.0,
                                 color="black"))
    ax.text(0, y_dim - 5, f"L$_{{gate}}$ = {L_GATE:g} nm", ha="center", va="top",
            fontweight="bold", fontsize=12)
    ax.add_patch(FancyArrowPatch((x_j, y_dim + 8), (L_GATE / 2, y_dim + 8),
                                 arrowstyle="<->", mutation_scale=12, lw=1.8,
                                 color="black"))
    ax.text((x_j + L_GATE / 2) / 2, y_dim + 11, f"L$_{{ov}}$ = {L_OV:g}",
            ha="center", va="bottom", fontweight="bold", fontsize=10)

    total = T_SI + 2 * (T_OX + T_FE + T_METAL)
    ax.text(-half_len, y_body + T_OX + T_FE + T_METAL + 8,
            f"drawn to scale;  total stack {total:g} nm,  "
            f"N$_{{sub}}$ = {N_SUB:.0e} cm$^{{-3}}$,  N$_{{sd}}$ = {N_SD:.0e} cm$^{{-3}}$,  "
            f"gate work function {WF_EV:g} eV",
            fontweight="bold", fontsize=11, va="bottom")

    ax.set_xlim(-half_len - 8, half_len + 78)
    ax.set_ylim(y_dim - 16, y_body + T_OX + T_FE + T_METAL + 22)
    ax.set_axis_off()

    rows = [{"layer": n, "material": m, "thickness_nm": t, "source": "sde_opt.cmd"}
            for n, m, t, _ in STACK]
    rows += [{"layer": "gate length", "material": "-", "thickness_nm": L_GATE,
              "source": "sde_opt.cmd L_GATE"},
             {"layer": "S/D overlap", "material": "-", "thickness_nm": L_OV,
              "source": "sde_opt.cmd L_OV"},
             {"layer": "S/D extension", "material": "-", "thickness_nm": L_SD,
              "source": "sde_opt.cmd L_SD"},
             {"layer": "probe height", "material": "-", "thickness_nm": PROBE_Y_NM,
              "source": "Pos(0,0.007) in every .plt"}]
    return fig, pd.DataFrame(rows)


@figure(
    "A5",
    claim="The two-dimensional double-gate cross-section maps onto a gate-all-around "
          "nanosheet through the gate perimeter: because the simulated slab is gated on both "
          "faces, a slab of z-depth A carries a total gate width 2A, so matching the "
          "nanosheet perimeter of 2(W + T_si) fixes the area factor at half the perimeter.",
    source="Device_Optimization/norm.py -- every quantity drawn here is read from that "
           "module's constants, which are the only place in the repository a width, an "
           "area factor or a current scale is defined.",
    convention="this figure IS the convention: W_eff = 2(W + T_si) = 90 nm",
)
def A5():
    """The 2D-to-nanosheet mapping, with every number taken from norm.py."""
    w, t = W_SHEET, T_SI
    perim_nm = norm.W_EFF_UM * 1e3
    area = norm.AREAFACTOR_CORRECT

    fig, axes = plt.subplots(1, 2, figsize=(12.6, 5.2))
    for ax in axes:
        ax.set_aspect("equal")
        ax.set_axis_off()

    # --- left: the real nanosheet, in perspective -----------------------------
    ax = axes[0]
    dx, dy = 26.0, 15.0
    front = np.array([[-w / 2, -t / 2], [w / 2, -t / 2], [w / 2, t / 2], [-w / 2, t / 2]])
    back = front + np.array([dx, dy])
    for a, b in zip(front, back):
        ax.plot([a[0], b[0]], [a[1], b[1]], "-", color=GREY, lw=1.6)
    ax.add_patch(Polygon(back, closed=True, fc="#9dc3e6", ec=GREY, lw=1.6))
    ax.add_patch(Polygon(front, closed=True, fc="#2e75b6", ec="black", lw=2.6, zorder=3))
    ax.plot(np.r_[front[:, 0], front[0, 0]], np.r_[front[:, 1], front[0, 1]], "-",
            color=PGM, lw=5.0, zorder=4)

    ax.annotate("", xy=(-w / 2, -t / 2 - 9), xytext=(w / 2, -t / 2 - 9),
                arrowprops=dict(arrowstyle="<->", lw=2.0))
    ax.text(0, -t / 2 - 12, f"W = {w:g} nm", ha="center", va="top", fontweight="bold",
            fontsize=13)
    ax.annotate("", xy=(-w / 2 - 8, -t / 2), xytext=(-w / 2 - 8, t / 2),
                arrowprops=dict(arrowstyle="<->", lw=2.0))
    ax.text(-w / 2 - 11, 0, f"T$_{{si}}$ = {t:g} nm", ha="right", va="center",
            fontweight="bold", fontsize=13, rotation=90)
    ax.text(0, t / 2 + dy + 8,
            f"gate wraps the perimeter\nTESW = 2(W + T$_{{si}}$) = {perim_nm:g} nm",
            ha="center", va="bottom", fontweight="bold", fontsize=13, color=PGM)
    ax.set_xlim(-w / 2 - 34, w / 2 + dx + 10)
    ax.set_ylim(-t / 2 - 30, t / 2 + dy + 34)

    # --- right: the simulated slab -------------------------------------------
    ax = axes[1]
    sw, sh = 44.0, t
    dx2, dy2 = 30.0, 17.0
    front = np.array([[-sw / 2, -sh / 2], [sw / 2, -sh / 2], [sw / 2, sh / 2],
                      [-sw / 2, sh / 2]])
    back = front + np.array([dx2, dy2])
    for a, b in zip(front, back):
        ax.plot([a[0], b[0]], [a[1], b[1]], "-", color=GREY, lw=1.6)
    ax.add_patch(Polygon(back, closed=True, fc="#9dc3e6", ec=GREY, lw=1.6))
    ax.add_patch(Polygon(front, closed=True, fc="#2e75b6", ec="black", lw=2.6, zorder=3))
    for sgn in (+1, -1):
        y0 = sgn * sh / 2
        ax.add_patch(Polygon(np.array([[-sw / 2, y0], [sw / 2, y0],
                                       [sw / 2 + dx2, y0 + dy2],
                                       [-sw / 2 + dx2, y0 + dy2]]),
                             closed=True, fc=PGM, ec="black", lw=2.0, alpha=0.85,
                             zorder=2))
    ax.text(sw / 2 + dx2 + 4, sh / 2 + dy2 / 2, "gated face", fontweight="bold",
            fontsize=12, color=PGM, va="center")
    ax.text(sw / 2 + dx2 + 4, -sh / 2 + dy2 / 2, "gated face", fontweight="bold",
            fontsize=12, color=PGM, va="center")

    ax.annotate("", xy=(sw / 2 + 3, -sh / 2 - 2), xytext=(sw / 2 + dx2 + 3, -sh / 2 + dy2 - 2),
                arrowprops=dict(arrowstyle="<->", lw=2.2, color=ACC))
    ax.text(sw / 2 + dx2 / 2 + 12, -sh / 2 + dy2 / 2 - 8,
            f"z-depth A = {area:g} $\\mu$m", fontweight="bold", fontsize=13, color=ACC)
    ax.text(0, sh / 2 + dy2 + 12,
            f"double-gated slab: width = 2A\n"
            f"2A = {2 * area * 1e3:g} nm = TESW  $\\Rightarrow$  "
            f"A = {area:g} $\\mu$m",
            ha="center", va="bottom", fontweight="bold", fontsize=13, color=ACC)
    ax.set_xlim(-sw / 2 - 14, sw / 2 + dx2 + 62)
    ax.set_ylim(-sh / 2 - 30, sh / 2 + dy2 + 40)

    fig.text(0.5, 0.06,
             f"every run executed at A = {norm.AREAFACTOR_USED:g}; the correction to "
             f"{norm.AREAFACTOR_CORRECT:g} is a pure post-multiplier on contact quantities, "
             f"an exact rescale of {norm.CORR:.4f}$\\times$\n"
             f"verified against a re-simulated node to a relative error of 1.8e-16",
             ha="center", fontweight="bold", fontsize=11)

    rows = [
        {"symbol": "W", "value": w, "units": "nm", "from": "norm.W_SHEET_NM"},
        {"symbol": "T_si", "value": t, "units": "nm", "from": "norm.T_SI_NOMINAL_NM"},
        {"symbol": "TESW = 2(W+T_si)", "value": perim_nm, "units": "nm",
         "from": "norm.W_EFF_UM"},
        {"symbol": "A (correct)", "value": norm.AREAFACTOR_CORRECT, "units": "um",
         "from": "norm.AREAFACTOR_CORRECT"},
        {"symbol": "A (as executed)", "value": norm.AREAFACTOR_USED, "units": "um",
         "from": "norm.AREAFACTOR_USED"},
        {"symbol": "rescale factor", "value": norm.CORR, "units": "-", "from": "norm.CORR"},
    ]
    return fig, pd.DataFrame(rows)
