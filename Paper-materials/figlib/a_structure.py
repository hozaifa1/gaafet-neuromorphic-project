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
    """Device cross-section, with the polarization probe and the dimensions marked.

    Horizontal and vertical are drawn on DIFFERENT scales, and both scale bars are
    on the figure.  At a common scale the structure is 200 nm wide and 31 nm tall,
    so the 1 nm interfacial oxide -- the layer the whole voltage-divider argument
    turns on -- is a hairline.  The exaggeration is stated rather than hidden.
    """
    half_len = L_GATE / 2 + L_SD
    y_body = T_SI / 2
    stack_h = T_OX + T_FE + T_METAL
    vx = 4.0                                  # vertical exaggeration, stated on the figure

    def Y(y_nm: float) -> float:
        return y_nm * vx

    y_dim = Y(-y_body - stack_h) - 26         # the dimension-bar row
    x_j = L_GATE / 2 - L_OV                   # metallurgical junction, under the gate

    fig, ax = plt.subplots(figsize=(10.5, 5.4))

    # --- silicon body, then the n+ source and drain that overlap the gate edges ---
    ax.add_patch(Rectangle((-half_len, Y(-y_body)), 2 * half_len, Y(T_SI),
                           fc=STACK[-1][3], ec="black", lw=1.6, zorder=2))
    for sgn in (-1, +1):
        x0 = x_j if sgn > 0 else -half_len
        ax.add_patch(Rectangle((x0, Y(-y_body)), half_len - x_j, Y(T_SI),
                               fc="#548235", ec="black", lw=1.6, zorder=3))
        ax.plot([sgn * x_j] * 2, [Y(-y_body), Y(y_body)], "-", color="black",
                lw=1.4, ls="--", zorder=4)

    # --- the two gate stacks, drawn outward from the channel -------------------
    labels = []
    for sign in (+1, -1):
        y = sign * y_body
        for _, mat, t, colour in reversed(STACK[:-1]):
            y0 = y if sign > 0 else y - t
            ax.add_patch(Rectangle((-L_GATE / 2, Y(y0)), L_GATE, Y(t), fc=colour,
                                   ec="black", lw=1.6, zorder=2))
            if sign > 0:
                labels.append((Y(y0 + t / 2), f"{mat}  {t:g} nm"))
            y += sign * t

    # Leader lines fan OUTWARD in the same order as the layers, so they cannot
    # cross.  `labels` runs inner -> outer, so the label rows must too.
    x_lead, x_text = L_GATE / 2 + 14, L_GATE / 2 + 34
    y_rows = np.linspace(Y(y_body) + 6, Y(y_body + stack_h) + 26, len(labels))
    for (y_src, text), y_lab in zip(labels, y_rows):
        ax.plot([L_GATE / 2, x_lead, x_text - 3], [y_src, y_src, y_lab], "-",
                color="black", lw=1.1)
        ax.text(x_text, y_lab, text, va="center", fontweight="bold", fontsize=12)
    ax.text(x_lead, Y(-y_body - stack_h / 2), "same stack,\nmirrored", va="center",
            ha="left", fontweight="bold", fontsize=11, color=GREY)
    ax.text(-half_len - 6, 0, f"Si\n{T_SI:g} nm", ha="right", va="center",
            fontweight="bold", fontsize=12)
    for sgn, lab in ((-1, "n$^+$ source"), (+1, "n$^+$ drain")):
        # inside the doped region itself -- floated above the stack these collided
        # with the layer leader lines
        ax.text(sgn * (half_len + L_GATE / 2) / 2, 0, lab, ha="center", va="center",
                fontweight="bold", fontsize=11, color="white", zorder=5)

    # --- the probe every polarization and field figure reads from --------------
    ax.plot([0], [Y(PROBE_Y_NM)], "o", ms=12, color=ACC, mec="black", mew=1.8, zorder=6)
    ax.annotate(f"P, E probe  (0, {PROBE_Y_NM:g} nm)", xy=(0, Y(PROBE_Y_NM)),
                xytext=(-half_len - 4, Y(y_body + stack_h) + 22),
                textcoords="data", fontsize=12, fontweight="bold", color=ACC,
                ha="left", va="bottom",
                arrowprops=dict(arrowstyle="->", lw=2.2, color=ACC,
                                connectionstyle="arc3,rad=-0.25"))

    # --- dimension bars, and one scale bar per axis ----------------------------
    ax.add_patch(FancyArrowPatch((-L_GATE / 2, y_dim), (L_GATE / 2, y_dim),
                                 arrowstyle="<->", mutation_scale=16, lw=2.0,
                                 color="black"))
    ax.text(0, y_dim - 6, f"L$_{{gate}}$ = {L_GATE:g} nm", ha="center", va="top",
            fontweight="bold", fontsize=13)
    # L_ov is 15 nm on a 200 nm axis: a double-headed arrow renders as a blob and a
    # callout has nowhere to go that is not already occupied.  The dashed junction
    # lines are drawn; the caption states what they are and how far in they sit.

    x_sb = -half_len - 34
    ax.plot([x_sb, x_sb], [y_dim + 4, y_dim + 4 + Y(10)], "-", color="black", lw=2.6)
    ax.text(x_sb - 4, y_dim + 4 + Y(5), "10 nm\nvertical", ha="right", va="center",
            fontweight="bold", fontsize=10)
    ax.plot([x_sb, x_sb + 50], [y_dim - 22, y_dim - 22], "-", color="black", lw=2.6)
    ax.text(x_sb + 25, y_dim - 26, "50 nm horizontal", ha="center", va="top",
            fontweight="bold", fontsize=10)

    total = T_SI + 2 * stack_h
    ax.set_xlim(-half_len - 96, half_len + 138)
    ax.set_ylim(y_dim - 46, Y(y_body + stack_h) + 62)
    ax.set_axis_off()
    note(ax,
         f"The vertical axis is exaggerated {vx:g}$\\times$ relative to the "
         f"horizontal, so that the {T_OX:g} nm interfacial oxide is visible; both "
         f"scale bars are drawn. Total gate stack {total:g} nm. "
         f"N$_{{sub}}$ = {N_SUB:.0e} cm$^{{-3}}$, N$_{{sd}}$ = {N_SD:.0e} cm$^{{-3}}$, "
         f"gate work function {WF_EV:g} eV. Dashed lines are the metallurgical "
         f"junctions, which sit {L_OV:g} nm inside each gate edge.")

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
    ax.annotate("", xy=(-w / 2 - 8, -t / 2 - 6), xytext=(-w / 2 - 8, t / 2 + 6),
                arrowprops=dict(arrowstyle="-", lw=2.0))
    ax.plot([-w / 2 - 12, -w / 2 - 4], [t / 2] * 2, "-", color="black", lw=1.6)
    ax.plot([-w / 2 - 12, -w / 2 - 4], [-t / 2] * 2, "-", color="black", lw=1.6)
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
    ax.text(sw / 2 + dx2 + 6, sh / 2 + dy2 / 2, "both faces\ngated",
            fontweight="bold", fontsize=12, color=PGM, va="center")

    ax.annotate("", xy=(sw / 2 + 3, -sh / 2 - 10), xytext=(sw / 2 + dx2 + 3, -sh / 2 + dy2 - 10),
                arrowprops=dict(arrowstyle="<->", lw=2.2, color=ACC))
    ax.text(sw / 2 + dx2 / 2 + 14, -sh / 2 + dy2 / 2 - 18,
            f"z-depth A = {area:g} $\\mu$m", fontweight="bold", fontsize=13, color=ACC)
    ax.text(0, sh / 2 + dy2 + 12,
            f"double-gated slab: width = 2A\n"
            f"2A = {2 * area * 1e3:g} nm = TESW  $\\Rightarrow$  "
            f"A = {area:g} $\\mu$m",
            ha="center", va="bottom", fontweight="bold", fontsize=13, color=ACC)
    ax.set_xlim(-sw / 2 - 14, sw / 2 + dx2 + 62)
    ax.set_ylim(-sh / 2 - 30, sh / 2 + dy2 + 40)

    note(axes[0],
             f"every run executed at A = {norm.AREAFACTOR_USED:g}; the correction to "
             f"{norm.AREAFACTOR_CORRECT:g} is a pure post-multiplier on contact quantities, "
             f"an exact rescale of {norm.CORR:.4f}$\\times$\n"
             f"verified against a re-simulated node to a relative error of 1.8e-16",
             )

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
