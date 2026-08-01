"""Chapter G -- integrate-and-fire operation.

Two nodes are available and they are NOT interchangeable: `t7c_lif` reads at
V_G = -0.5 V and sweeps V_pgm over 0.6-1.2 V in fifteen pulses, `t8_lif0` reads
at V_G = 0 and sweeps 1.0-2.5 V in twelve.  They are drawn as separate panels
and no quantity is formed across them.

Every ratio here is taken against that amplitude's OWN `baseline_pre` read from
the same node.  The published fire ratio of 30.6x came from dividing this
project's pulse-9 read by a different run's baseline; against its own baseline
the same measurement is 18.4x.
"""
from __future__ import annotations

import re

import numpy as np
import pandas as pd

from ._common import (ACC, ERS, GREY, LEVELS, PGM, bold_labels, decade_ticks,
                      figure, id_uA_um, new_ax, node_files, note, parse_plt, plt)

PY = "Pos(0,0.007) Polarization/y"
VG = "gate_contact OuterVoltage"

NODES = [("t7c_lif", -0.5), ("t8_lif0", 0.0)]
FIRE_DECADES = 1.0        # a "fire" is one decade above that device's own rest current


def _amp(name: str) -> float:
    return int(re.search(r"_v(\d{3})_", name).group(1)) / 100.0


def _ladder(node: str) -> pd.DataFrame:
    """Settled read current after each pulse, per programming amplitude, one node."""
    rows = []
    for f in node_files(node, r"^baseline_pre_"):
        rows.append({"node": node, "V_pgm": _amp(f.name), "pulse": 0,
                     "I_uA_um": float(id_uA_um(parse_plt(f))[-1])})
    for f in node_files(node, r"^p\d\d_read_"):
        rows.append({"node": node, "V_pgm": _amp(f.name), "pulse": int(f.name[1:3]),
                     "I_uA_um": float(id_uA_um(parse_plt(f))[-1])})
    d = pd.DataFrame(rows).sort_values(["V_pgm", "pulse"]).reset_index(drop=True)
    base = d[d.pulse == 0].set_index("V_pgm").I_uA_um
    d["baseline_uA_um"] = d.V_pgm.map(base)
    d["ratio_to_own_baseline"] = d.I_uA_um / d.baseline_uA_um
    d["fired"] = d.ratio_to_own_baseline >= 10.0 ** FIRE_DECADES
    return d


def _n_fire(g: pd.DataFrame) -> float:
    hit = g[(g.pulse > 0) & g.fired]
    return float(hit.pulse.min()) if len(hit) else np.nan


@figure(
    "G1",
    claim="Identical sub-coercive gate pulses accumulate on the ferroelectric until the "
          "channel current crosses a read threshold, and how many pulses that takes is set "
          "by the pulse amplitude -- the device integrates its input and then fires.",
    source="Device_Optimization/outputs/t7c_lif (15 pulses, read at V_G = -0.5 V) and "
           "t8_lif0 (12 pulses, read at V_G = 0). Separate panels because the read bias "
           "differs; every ratio is against that amplitude's own baseline_pre in its own node.",
    convention="norm.to_uA_per_um via _common.id_uA_um (conduction current, W_eff = 90 nm)",
)
def G1():
    """Count-to-fire families, one panel per node."""
    fig, axes = plt.subplots(1, 2, figsize=(13.2, 5.4))
    for ax in axes:
        for sp in ax.spines.values():
            sp.set_linewidth(2.0)
        ax.tick_params(axis="both", which="both", direction="in", top=False, right=False,
                       width=2.0, labelsize=12)
        ax.minorticks_on()
        for lbl in ax.get_xticklabels() + ax.get_yticklabels():
            lbl.set_fontweight("bold")

    frames = []
    for ax, (node, v_read) in zip(axes, NODES):
        d = _ladder(node)
        frames.append(d)
        ax.set_yscale("log")
        amps = sorted(d.V_pgm.unique())
        for k, a in enumerate(amps):
            s = d[(d.V_pgm == a) & (d.pulse > 0)]
            ax.plot(s.pulse, s.ratio_to_own_baseline, "-o",
                    color=LEVELS(k / max(len(amps) - 1, 1)), lw=2.6, ms=7,
                    mec="black", mew=1.0, label=f"{a:.2f} V")
        ax.axhline(10.0 ** FIRE_DECADES, color=ACC, lw=2.4, ls="--")
        decade_ticks(ax)
        bold_labels(ax, "Pulse number", "I$_D$ / own rest current")
        ax.legend(loc="upper left", fontsize=11, title=f"V$_{{pgm}}$",
                  title_fontproperties={"weight": "bold", "size": 11})
        ax.text(0.97, 0.05,
                f"{node},  read at V$_G$ = {v_read:g} V\n"
                f"fire threshold: {10.0 ** FIRE_DECADES:.0f}$\\times$ rest",
                transform=ax.transAxes, ha="right", va="bottom",
                fontweight="bold", fontsize=11)

    return fig, pd.concat(frames, ignore_index=True)


@figure(
    "G2",
    claim="The number of pulses needed to fire falls monotonically with pulse amplitude, "
          "which is the rate-coding transfer function of an integrate-and-fire neuron: the "
          "same device is a slow integrator at low drive and a fast one at high drive.",
    source="Derived from the same reads as G1, per node. Amplitudes that never reach the "
           "threshold within the pulses that were run are drawn as open markers at the top "
           "of the axis rather than dropped.",
    convention="a pulse count -- dimensionless",
)
def G2():
    """Pulses-to-fire against programming amplitude."""
    fig, ax = new_ax(figsize=(8.4, 5.4))
    rows = []
    for (node, v_read), colour, mk in zip(NODES, (ERS, PGM), ("s", "o")):
        d = _ladder(node)
        amps = sorted(d.V_pgm.unique())
        n_max = int(d.pulse.max())
        nf = [_n_fire(d[d.V_pgm == a]) for a in amps]
        rows.append(pd.DataFrame({"node": node, "V_read_V": v_read, "V_pgm_V": amps,
                                  "N_fire": nf, "pulses_available": n_max}))
        fired = [(a, n) for a, n in zip(amps, nf) if np.isfinite(n)]
        never = [a for a, n in zip(amps, nf) if not np.isfinite(n)]
        if fired:
            ax.plot([a for a, _ in fired], [n for _, n in fired], "-", marker=mk,
                    color=colour, lw=2.8, ms=11, mec="black", mew=1.4,
                    label=f"{node} (read {v_read:g} V)")
        for a in never:
            ax.plot([a], [n_max + 1], marker=mk, color=colour, mfc="white", mew=2.2,
                    ms=12)
            ax.annotate("", xy=(a, n_max + 2.4), xytext=(a, n_max + 1.2),
                        arrowprops=dict(arrowstyle="->", lw=2.2, color=colour))

    out = pd.concat(rows, ignore_index=True)
    ax.set_ylim(0, float(out.pulses_available.max()) + 3.4)
    bold_labels(ax, "Programming amplitude V$_{pgm}$ (V)", "Pulses to fire, N$_{fire}$")
    ax.legend(loc="upper right", fontsize=11)
    note(ax, f"fire = {10.0 ** FIRE_DECADES:.0f}$\\times$ that device's own rest current\n"
             f"open markers with an arrow: never fired within the\n"
             f"pulses that were run",
         xy=(0.03, 0.30), fontsize=11)
    return fig, out


@figure(
    "G3",
    claim="The stored polarization is the membrane state: a train of identical gate pulses "
          "steps the polarization monotonically, and the read current follows it until it "
          "crosses threshold. With the depolarization time constant used here the device "
          "holds its state after firing instead of leaking back, so what is demonstrated is "
          "a single-shot integrate-and-fire event, not a repeating leaky cycle.",
    source="Device_Optimization/outputs/t8_lif0, one programming amplitude, write and read "
           "segments concatenated on the solver's absolute time axis. One node, one amplitude.",
    convention="norm.to_uA_per_um via _common.id_uA_um; polarization is Areafactor-independent",
)
def G3():
    """Spike-train waveform: gate drive, polarization state, and read current."""
    node = "t8_lif0"
    amps = sorted({_amp(f.name) for f in node_files(node, r"^p\d\d_")})
    a = amps[-2] if len(amps) > 1 else amps[0]          # a mid-high amplitude that fires
    tag = f"v{int(round(a * 100)):03d}"

    segs = []
    for kind in ("write", "read"):
        for f in node_files(node, rf"^p\d\d_{kind}_"):
            if tag not in f.name:
                continue
            d = parse_plt(f)
            segs.append(d.assign(phase=kind, pulse=int(f.name[1:3])))
    d = pd.concat(segs, ignore_index=True).sort_values("time").reset_index(drop=True)

    t_us = (d["time"].to_numpy() - d["time"].iloc[0]) * 1e6
    vg = d[VG].to_numpy()
    py = d[PY].to_numpy() * 1e6
    idd = id_uA_um(d)

    lad = _ladder(node)
    lad = lad[lad.V_pgm == a]
    thr = float(lad.baseline_uA_um.iloc[0]) * 10.0 ** FIRE_DECADES
    nf = _n_fire(lad)

    fig, axes = plt.subplots(3, 1, figsize=(9.2, 8.0), sharex=True)
    for ax in axes:
        for sp in ax.spines.values():
            sp.set_linewidth(2.0)
        ax.tick_params(axis="both", which="both", direction="in", top=False, right=False,
                       width=2.0, labelsize=12)
        ax.minorticks_on()
        for lbl in ax.get_xticklabels() + ax.get_yticklabels():
            lbl.set_fontweight("bold")
        ax.fill_between(t_us, 0, 1, where=(d["phase"] == "write"),
                        transform=ax.get_xaxis_transform(), color=ACC, alpha=0.12, lw=0)

    axes[0].plot(t_us, vg, "-", color=GREY, lw=2.4)
    axes[0].set_ylabel("V$_G$ (V)", fontweight="bold", fontsize=15, labelpad=8)

    axes[1].plot(t_us, py, "-", color=PGM, lw=2.6)
    axes[1].set_ylabel("P$_y$ ($\\mu$C/cm$^2$)", fontweight="bold", fontsize=15, labelpad=8)

    axes[2].set_yscale("log")
    axes[2].plot(t_us, idd, "-", color=ERS, lw=2.4)
    axes[2].axhline(thr, color=ACC, lw=2.4, ls="--")
    decade_ticks(axes[2])
    bold_labels(axes[2], "Time ($\\mu$s)", "I$_D$ ($\\mu$A/$\\mu$m)")
    axes[2].text(0.02, 0.92,
                 (f"fires on pulse {nf:.0f}" if np.isfinite(nf) else "does not fire")
                 + f" at V$_{{pgm}}$ = {a:g} V;  threshold = "
                   f"{10.0 ** FIRE_DECADES:.0f}$\\times$ rest",
                 transform=axes[2].transAxes, va="top", fontweight="bold", fontsize=11)

    fig.subplots_adjust(hspace=0.08)
    out = pd.DataFrame({"t_us": t_us, "phase": d["phase"], "pulse": d["pulse"],
                        "Vg_V": vg, "Py_uC_cm2": py, "Id_uA_um": idd,
                        "V_pgm_V": a, "threshold_uA_um": thr})
    return fig, out
