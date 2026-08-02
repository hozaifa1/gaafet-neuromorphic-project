"""Chapter E -- write transients, switching kinetics and measured write energy.

All three figures read node `t8_ltp` -- the 15 x 2.0 V / 100 ns potentiation
train -- so the staircase, the per-pulse kinetics and the energy per pulse are
the same fifteen pulses rather than three different runs.

A NOTE ON HOW THE ENERGY IS MEASURED, because the obvious method fails here.
The gate current during a write is a switching spike followed by a flat
2.3e-11 A conduction floor, and the transient plot samples at 50 ns, so the
spike is one sample wide and its width is set by the sampler rather than by the
device.  Integrating V_G I_G dt over that grid returns about 20 fJ per pulse,
which is the sampler's guess at the spike, not the device's energy.  The
solver's own `gate_contact Charge` trace is the time-integral done properly, so
the energy per pulse is V_pgm dQ_G taken from that trace.  The two disagree by
three orders of magnitude and only one of them is a measurement.
"""
from __future__ import annotations

import re

import numpy as np
import pandas as pd

from ._common import (ACC, ERS, GREY, LEVELS, PGM, bold_labels, decade_ticks,
                      figure, new_ax, node_files, norm, note, parse_plt, plt)

NODE = "t8_ltp"
PY = "Pos(0,0.007) Polarization/y"
QG = "gate_contact Charge"
VG = "gate_contact OuterVoltage"
IG = "gate_contact TotalCurrent"


def _vpgm(name: str) -> float:
    """Programming amplitude out of the node's filename token, e.g. v020 -> 2.0 V."""
    m = re.search(r"_v(\d{3})_", name)
    if not m:
        raise ValueError(f"no amplitude token in {name}")
    return int(m.group(1)) / 10.0


def _train(kind: str) -> list[pd.DataFrame]:
    """Every pulse segment of one kind ('write' or 'read'), in pulse order."""
    out = []
    for f in node_files(NODE, rf"^p\d\d_{kind}_"):
        d = parse_plt(f)
        d = d.assign(pulse=int(f.name[1:3]), phase=kind, src=f.name)
        out.append(d)
    return out


@figure(
    "E1",
    claim="Fifteen identical sub-coercive gate pulses walk the ferroelectric polarization "
          "down a staircase, one step per pulse, and the gate conduction current between "
          "pulses stays at the tens-of-picoampere level, so a one-nanometre interfacial "
          "oxide does not leak the stored state away between writes.",
    source="Device_Optimization/outputs/t8_ltp -- the write and read segments of one "
           "15 x 2.0 V / 100 ns train, concatenated on the solver's own absolute time "
           "axis (the segments do not restart their clocks). One node throughout.",
    convention="polarization is Areafactor-independent; gate charge via norm.to_device_amps",
)
def E1():
    """Stitched write staircase: polarization and gate charge on one time axis."""
    segs = _train("write") + _train("read")
    d = pd.concat(segs, ignore_index=True).sort_values("time").reset_index(drop=True)
    t_us = (d["time"].to_numpy() - d["time"].iloc[0]) * 1e6
    py = d[PY].to_numpy() * 1e6                      # C/cm2 -> uC/cm2
    qg = norm.to_device_amps(d[QG].to_numpy()) * 1e15    # C -> fC per nanosheet
    vg = d[VG].to_numpy()
    ig = np.abs(norm.to_device_amps(d[IG].to_numpy()))

    fig, axes = plt.subplots(2, 1, figsize=(9.2, 6.6), sharex=True)
    for ax in axes:
        for sp in ax.spines.values():
            sp.set_linewidth(2.0)
        ax.tick_params(axis="both", which="both", direction="in", top=False, right=False,
                       width=2.0, labelsize=12)
        ax.minorticks_on()
        for lbl in ax.get_xticklabels() + ax.get_yticklabels():
            lbl.set_fontweight("bold")

    writing = d["phase"].to_numpy() == "write"
    for ax in axes:
        ax.fill_between(t_us, 0, 1, where=writing, transform=ax.get_xaxis_transform(),
                        color=ACC, alpha=0.13, lw=0)

    axes[0].plot(t_us, py, "-", color=PGM, lw=2.6)
    axes[0].set_ylabel("P$_y$ ($\\mu$C/cm$^2$)", fontweight="bold", fontsize=16, labelpad=8)
    dP = py[-1] - py[0]
    axes[0].text(0.03, 0.10, f"$\\Delta$P over the train = {dP:+.3f} $\\mu$C/cm$^2$\n"
                             f"shaded: V$_G$ = {vg.max():g} V write windows",
                 transform=axes[0].transAxes, fontweight="bold", fontsize=12, va="bottom")

    axes[1].plot(t_us, qg, "-", color=ERS, lw=2.6)
    bold_labels(axes[1], "Time ($\\mu$s)", "Q$_G$ (fC / nanosheet)")
    leak = float(np.median(ig[~writing]))
    fig.text(0.5, -0.01, f"gate conduction between pulses: {leak * 1e12:.1f} pA median",
             ha="center", fontweight="bold", fontsize=12)

    fig.subplots_adjust(hspace=0.08)
    out = pd.DataFrame({"t_us": t_us, "phase": d["phase"], "pulse": d["pulse"],
                        "Vg_V": vg, "Py_uC_cm2": py, "Qg_fC": qg,
                        "abs_Ig_A": ig})
    return fig, out


@figure(
    "E2",
    claim="Switching slows as the ferroelectric saturates: successive identical pulses move "
          "the polarization by a smaller amount each time after the middle of the train, so "
          "the ladder's compression at the top is a kinetic property of the material rather "
          "than a limit of the read.",
    source="Device_Optimization/outputs/t8_ltp -- the fifteen write segments of one train, "
           "each re-referenced to its own start. One node.",
    convention="polarization is Areafactor-independent",
)
def E2():
    """Per-pulse polarization transients, overlaid and colour-graded by pulse index."""
    segs = _train("write")
    n = len(segs)

    fig, axes = plt.subplots(1, 2, figsize=(13.0, 5.2))
    for ax in axes:
        for sp in ax.spines.values():
            sp.set_linewidth(2.0)
        ax.tick_params(axis="both", which="both", direction="in", top=False, right=False,
                       width=2.0, labelsize=12)
        ax.minorticks_on()
        for lbl in ax.get_xticklabels() + ax.get_yticklabels():
            lbl.set_fontweight("bold")

    rows, dps = [], []
    for k, s in enumerate(segs):
        t_ns = (s["time"].to_numpy() - s["time"].iloc[0]) * 1e9
        p = s[PY].to_numpy() * 1e6
        axes[0].plot(t_ns, p - p[0], "-o", color=LEVELS(k / (n - 1)), lw=2.2, ms=4,
                     mec="none")
        dps.append(p[-1] - p[0])
        rows.append(pd.DataFrame({"pulse": int(s["pulse"].iloc[0]), "t_ns": t_ns,
                                  "dPy_uC_cm2": p - p[0]}))

    bold_labels(axes[0], "Time within the pulse (ns)",
                "$\\Delta$P$_y$ within the pulse ($\\mu$C/cm$^2$)")
    sm = plt.cm.ScalarMappable(cmap=LEVELS, norm=plt.Normalize(1, n))
    cb = fig.colorbar(sm, ax=axes[0], pad=0.02)
    cb.set_label("pulse number", fontweight="bold", fontsize=13)
    cb.ax.tick_params(labelsize=11, width=1.6)

    dps = np.array(dps)
    idx = np.arange(1, n + 1)
    axes[1].bar(idx, np.abs(dps), color=[LEVELS(k / (n - 1)) for k in range(n)],
                edgecolor="black", lw=1.2)
    bold_labels(axes[1], "Pulse number",
                "|$\\Delta$P$_y$| per pulse ($\\mu$C/cm$^2$)")
    peak = int(idx[np.argmax(np.abs(dps))])
    fig.text(0.5, -0.02,
             f"switching per pulse peaks at pulse {peak}, then falls to "
             f"{np.abs(dps)[-1] / np.abs(dps).max():.2f} of the peak by pulse {n}",
             ha="center", fontweight="bold", fontsize=12)

    out = pd.concat(rows, ignore_index=True)
    out = out.merge(pd.DataFrame({"pulse": idx, "dPy_total_uC_cm2": dps}), on="pulse")
    return fig, out


@figure(
    "E6",
    claim="Each programming pulse costs of order ten attojoules of switching energy at the "
          "gate, the cost per pulse peaks in the middle of the train and falls as the "
          "ferroelectric saturates, and the whole fifteen-level write costs about a tenth "
          "of a femtojoule.",
    source="Device_Optimization/outputs/t8_ltp -- energy per pulse taken as V_pgm times the "
           "change in the solver's gate-charge trace across each write window, on one node. "
           "V_pgm is parsed from the node's own filename token. NOT the V_G I_G integral: "
           "the switching spike is one 50 ns sample wide, so that integral would report the "
           "sampling grid rather than the device.",
    convention="gate charge via norm.to_device_amps (Areafactor 0.071 -> 0.045)",
)
def E6():
    """Measured switching energy per pulse, and the cumulative cost of the train."""
    segs = _train("write")
    v_pgm = _vpgm(segs[0]["src"].iloc[0])

    idx, e_fj = [], []
    for s in segs:
        q = norm.to_device_amps(s[QG].to_numpy())
        idx.append(int(s["pulse"].iloc[0]))
        e_fj.append(v_pgm * (q[-1] - q[0]) * 1e15)
    idx = np.array(idx)
    e_fj = np.array(e_fj)
    cum = np.cumsum(e_fj)

    fig, ax = new_ax(figsize=(8.6, 5.6))
    ax2 = ax.twinx()
    ax2.tick_params(axis="y", direction="in", width=2.0, labelsize=12)
    for lbl in ax2.get_yticklabels():
        lbl.set_fontweight("bold")

    ax.bar(idx, e_fj * 1e3, color=[LEVELS(k / (len(idx) - 1)) for k in range(len(idx))],
           edgecolor="black", lw=1.3, zorder=2)
    ax2.plot(idx, cum * 1e3, "-o", color=PGM, lw=3.0, ms=8, mec="black", mew=1.4,
             zorder=3, label="cumulative")

    ax.axhline(0, color="black", lw=1.4)
    ax.set_xticks(idx[::2])
    bold_labels(ax, "Pulse number", "Switching energy per pulse (aJ)")
    ax2.set_ylabel("Cumulative energy (aJ)", fontweight="bold", fontsize=17,
                   labelpad=10, color=PGM)
    peak = int(idx[np.argmax(e_fj)])
    note(ax, f"V$_{{pgm}}$ = {v_pgm:g} V, {len(idx)} pulses\n"
             f"peak {e_fj.max() * 1e3:.1f} aJ at pulse {peak}, "
             f"last pulse {e_fj[-1] * 1e3:.1f} aJ\n"
             f"whole train {cum[-1] * 1e3:.1f} aJ = {cum[-1]:.4f} fJ",
         xy=(0.03, 0.97), fontsize=12)

    out = pd.DataFrame({"pulse": idx, "V_pgm_V": v_pgm,
                        "energy_fJ": e_fj, "energy_aJ": e_fj * 1e3,
                        "cumulative_fJ": cum})
    return fig, out
