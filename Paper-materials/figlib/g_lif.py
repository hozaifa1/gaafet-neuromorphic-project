"""Chapter G -- integrate-and-fire operation.

WHICH NODES ARE USABLE, AND WHY MOST ARE NOT.  This project ran two dedicated
count-to-fire sweeps, `t7c_lif` (124 files) and `t8_lif0` (100 files), and
neither can support a figure:

* both write with **20 ns** pulses.  The programming-window study (panel 8)
  already shows that pulses of 30 ns and shorter do not program at any
  amplitude, and the polarization traces agree -- across twelve pulses the probe
  moves from 3.144e-7 to 3.181e-7 C/cm2, about 0.01 % of the remanent
  polarization.  The runs completed cleanly and produced a flat ladder.
* `t7c_lif`, and the amplitude families in `t5_fe07` and `t7b_grad`, read at
  **V_G = -0.5 V**, which is inside the gate-induced-drain-leakage branch.  That
  current is set by band-to-band generation at the drain edge and is almost
  insensitive to the stored polarization, so those reads are blind to the state
  by construction.  This is the same result panel 8(d) reports from the other
  direction.

What is left is `t8_ltp`: 15 x 2.0 V, 100 ns writes, read at V_G = 0.  G1 and G3
are that node.  G2 measures the state variable itself -- polarization during the
write -- on `t5_fe07`, whose reads are unusable but whose writes are 100 ns at
five amplitudes.  No quantity is formed across the two nodes.
"""
from __future__ import annotations

import re

import numpy as np
import pandas as pd

from ._common import (ACC, ERS, GREY, LEVELS, PGM, bold_labels, decade_ticks,
                      figure, id_uA_um, load_raw, new_ax, node_files, note,
                      parse_plt, plt)

PY = "Pos(0,0.007) Polarization/y"
VG = "gate_contact OuterVoltage"

I_FIRE_UA_UM = 0.10     # read-current threshold; a design choice, stated on the figure
DP_FIRE = 0.05          # |dP| threshold in uC/cm2 for the state-variable view


def _amp(name: str) -> float:
    """v020 -> 2.0 V.  The token is in units of 0.1 V."""
    return int(re.search(r"_v(\d{3})_", name).group(1)) / 10.0


def _read_ladder(node: str) -> pd.DataFrame:
    """Settled read current after each pulse, plus the run's own pre-train baseline."""
    rows = []
    for f in node_files(node, r"^baseline_pre_"):
        rows.append({"V_pgm": _amp(f.name), "pulse": 0,
                     "I_uA_um": float(id_uA_um(parse_plt(f))[-1])})
    for f in node_files(node, r"^p\d\d_read_"):
        rows.append({"V_pgm": _amp(f.name), "pulse": int(f.name[1:3]),
                     "I_uA_um": float(id_uA_um(parse_plt(f))[-1])})
    d = pd.DataFrame(rows).sort_values(["V_pgm", "pulse"]).reset_index(drop=True)
    base = d[d.pulse == 0].set_index("V_pgm").I_uA_um
    d["baseline_uA_um"] = d.V_pgm.map(base)
    d["ratio_to_own_baseline"] = d.I_uA_um / d.baseline_uA_um
    return d


@figure(
    "G1",
    claim="Identical sub-coercive pulses accumulate on the ferroelectric and the zero-bias "
          "read current rises monotonically with pulse number, crossing a fixed read "
          "threshold on the ninth pulse at a contrast of about eighteen times the rest "
          "current: the device integrates its input and then fires.",
    source="Device_Optimization/outputs/t8_ltp -- one 15 x 2.0 V / 100 ns train read at "
           "V_G = 0. The contrast is taken against this run's OWN baseline_pre; against a "
           "different run's baseline the same measurement reads 30.6x instead of 18.4x, "
           "which is why cross-run ratios are not formed anywhere in this paper.",
    convention="norm.to_uA_per_um via _common.id_uA_um (conduction current, W_eff = 90 nm)",
)
def G1():
    """Count-to-fire: read current against pulse number, with the threshold marked."""
    d = _read_ladder("t8_ltp")
    v = float(d.V_pgm.iloc[0])
    s = d[d.pulse > 0]
    base = float(d.baseline_uA_um.iloc[0])
    crossed = s[s.I_uA_um >= I_FIRE_UA_UM]
    n_fire = int(crossed.pulse.min()) if len(crossed) else None
    contrast = float(crossed.ratio_to_own_baseline.iloc[0]) if n_fire else float("nan")

    fig, ax = new_ax(figsize=(8.6, 5.6))
    fig.subplots_adjust(left=0.16, right=0.95, top=0.94, bottom=0.14)
    ax.set_yscale("log")
    ax.axhline(base, color=GREY, lw=2.0, ls=":")
    ax.axhline(I_FIRE_UA_UM, color=ACC, lw=2.6, ls="--")
    below = s[s.pulse < (n_fire or 99)]
    above = s[s.pulse >= (n_fire or 99)]
    ax.plot(s.pulse, s.I_uA_um, "-", color=PGM, lw=2.8, zorder=2)
    ax.plot(below.pulse, below.I_uA_um, "o", color="white", mec=PGM, mew=2.4, ms=9,
            zorder=3, label="integrating")
    ax.plot(above.pulse, above.I_uA_um, "o", color=PGM, mec="black", mew=1.4, ms=10,
            zorder=3, label="above threshold")

    if n_fire:
        ax.axvline(n_fire, color=ACC, lw=1.8, ls=":")
        ax.annotate(f"fires on pulse {n_fire}", xy=(n_fire, I_FIRE_UA_UM),
                    xytext=(14, -34), textcoords="offset points",
                    fontsize=13, fontweight="bold", color=ACC,
                    arrowprops=dict(arrowstyle="->", lw=2.0, color=ACC))

    decade_ticks(ax)
    ax.set_xlim(0.4, s.pulse.max() + 0.6)
    ax.set_ylim(min(base, s.I_uA_um.min()) / 6, s.I_uA_um.max() * 8)
    bold_labels(ax, "Pulse number", "Read current at V$_G$ = 0 ($\\mu$A/$\\mu$m)")
    ax.legend(loc="lower right", fontsize=11, frameon=True, facecolor="white", framealpha=0.9, edgecolor="black")
    note(ax, f"V$_{{pgm}}$ = {v:g} V, 100 ns pulses\n"
             f"rest current {base:.3g} $\\mu$A/$\\mu$m (dotted)\n"
             f"threshold {I_FIRE_UA_UM:g} $\\mu$A/$\\mu$m (dashed), a design choice\n"
             f"contrast at fire: {contrast:.1f}$\\times$ rest",
         xy=(0.03, 0.97), fontsize=11)

    out = d.copy()
    out["threshold_uA_um"] = I_FIRE_UA_UM
    out["N_fire"] = n_fire
    return fig, out


@figure(
    "G2",
    claim="Pulse amplitude sets how fast the membrane state accumulates: the polarization "
          "moved per pulse grows steeply with amplitude, so the same device integrates over "
          "many pulses at low drive and over a few at high drive, which is the rate-coding "
          "transfer function an integrate-and-fire element needs.",
    source="Device_Optimization/outputs/t5_fe07 -- five programming amplitudes, nine 100 ns "
           "pulses each, one node. Measured on the polarization probe during the write "
           "rather than on the read, because this node's reads are taken at V_G = -0.5 V, "
           "inside the leakage branch, where the current does not track the stored state.",
    convention="polarization is Areafactor-independent",
)
def G2():
    """Membrane-state accumulation against pulse number, for five drive amplitudes."""
    node = "t5_fe07"
    segs = {}
    for f in node_files(node, r"^p\d\d_write_"):
        segs.setdefault(_amp(f.name), []).append(f)
    amps = sorted(segs)

    fig, axes = plt.subplots(1, 2, figsize=(12.0, 5.2))
    fig.subplots_adjust(wspace=0.34, left=0.15, right=0.96, top=0.92, bottom=0.14)
    for ax in axes:
        for sp in ax.spines.values():
            sp.set_linewidth(2.2)
        ax.tick_params(axis="both", which="both", direction="in", top=True, right=True,
                       width=2.0, labelsize=16, pad=6)
        ax.minorticks_on()
        for lbl in ax.get_xticklabels() + ax.get_yticklabels():
            lbl.set_fontweight("bold")
            lbl.set_fontsize(16)

    rows, reach = [], []
    for k, a in enumerate(amps):
        files = sorted(segs[a])
        p0 = None
        pulses, dp = [], []
        for f in files:
            d = parse_plt(f)
            p = d[PY].to_numpy() * 1e6
            if p0 is None:
                p0 = float(p[0])
            pulses.append(int(f.name[1:3]))
            dp.append(float(p[-1]) - p0)
        pulses, dp = np.array(pulses), np.abs(np.array(dp))
        axes[0].plot(pulses, dp, "-o", color=LEVELS(k / (len(amps) - 1)), lw=2.8, ms=8,
                     mec="black", mew=1.1, label=f"{a:g} V")
        hit = pulses[dp >= DP_FIRE]
        reach.append((a, float(hit.min()) if len(hit) else np.nan, int(pulses.max())))
        rows.append(pd.DataFrame({"V_pgm_V": a, "pulse": pulses, "abs_dPy_uC_cm2": dp}))

    axes[0].axhline(DP_FIRE, color=ACC, lw=2.4, ls="--")
    bold_labels(axes[0], "Pulse number",
                "|$\\Delta$P$_y$| since the start of the train ($\\mu$C/cm$^2$)")
    axes[0].legend(loc="upper left", fontsize=11, title="V$_{pgm}$", frameon=True, facecolor="white", framealpha=0.9, edgecolor="black")

    ax = axes[1]
    n_max = max(r[2] for r in reach)
    fired = [(a, n) for a, n, _ in reach if np.isfinite(n)]
    never = [a for a, n, _ in reach if not np.isfinite(n)]
    if fired:
        ax.plot([a for a, _ in fired], [n for _, n in fired], "-o", color=PGM, lw=3.0,
                ms=12, mec="black", mew=1.5)
    for a in never:
        ax.plot([a], [n_max + 1], "o", color=PGM, mfc="white", mew=2.4, ms=12)
        ax.annotate("", xy=(a, n_max + 2.2), xytext=(a, n_max + 1.2),
                    arrowprops=dict(arrowstyle="->", lw=2.2, color=PGM))
    ax.set_ylim(0, n_max + 3.0)
    bold_labels(ax, "Programming amplitude V$_{pgm}$ (V)", "Pulses to reach threshold")
    note(ax, "An open marker with an arrow means the threshold was not reached "
             "within the pulses that were run.")

    out = pd.concat(rows, ignore_index=True)
    out = out.merge(pd.DataFrame({"V_pgm_V": [r[0] for r in reach],
                                  "pulses_to_threshold": [r[1] for r in reach],
                                  "pulses_available": [r[2] for r in reach]}),
                    on="V_pgm_V")
    return fig, out


@figure(
    "G3",
    claim="The stored polarization is the state variable: a train of identical gate pulses "
          "steps it monotonically and the zero-bias read current follows it until threshold "
          "is crossed. With the depolarization time constant used here the device holds its "
          "state after firing rather than leaking back, so what is demonstrated is a "
          "single-shot integrate-and-fire event and not a repeating leaky cycle.",
    source="Device_Optimization/outputs/t8_ltp -- write and read segments of one "
           "15 x 2.0 V / 100 ns train, concatenated on the solver's absolute time axis. "
           "One node, one amplitude.",
    convention="norm.to_uA_per_um via _common.id_uA_um; polarization is Areafactor-independent",
)
def G3():
    """Spike-train waveform: gate drive, polarization state, and read current."""
    segs = []
    for kind in ("write", "read"):
        for f in node_files("t8_ltp", rf"^p\d\d_{kind}_"):
            segs.append(parse_plt(f).assign(phase=kind, pulse=int(f.name[1:3]),
                                            V_pgm=_amp(f.name)))
    d = pd.concat(segs, ignore_index=True).sort_values("time").reset_index(drop=True)

    t_us = (d["time"].to_numpy() - d["time"].iloc[0]) * 1e6
    vg = d[VG].to_numpy()
    py = d[PY].to_numpy() * 1e6
    idd = id_uA_um(d)
    a = float(d.V_pgm.iloc[0])

    lad = _read_ladder("t8_ltp")
    crossed = lad[(lad.pulse > 0) & (lad.I_uA_um >= I_FIRE_UA_UM)]
    n_fire = int(crossed.pulse.min()) if len(crossed) else None

    fig, axes = plt.subplots(3, 1, figsize=(8.6, 8.2), sharex=True)
    fig.subplots_adjust(hspace=0.12, left=0.18, right=0.95, top=0.95, bottom=0.10)
    for ax in axes:
        for sp in ax.spines.values():
            sp.set_linewidth(2.2)
        ax.tick_params(axis="both", which="both", direction="in", top=False, right=False,
                       width=2.0, labelsize=16, pad=6)
        ax.minorticks_on()
        for lbl in ax.get_xticklabels() + ax.get_yticklabels():
            lbl.set_fontweight("bold")
            lbl.set_fontsize(16)
        ax.fill_between(t_us, 0, 1, where=(d["phase"] == "write"),
                        transform=ax.get_xaxis_transform(), color=ACC, alpha=0.12, lw=0)

    axes[0].plot(t_us, vg, "-", color=GREY, lw=2.4)
    axes[0].set_ylabel("V$_G$ (V)", fontweight="bold", fontsize=20, labelpad=8)
    axes[0].set_ylim(-0.4, a + 0.6)

    axes[1].plot(t_us, py, "-", color=PGM, lw=2.6)
    axes[1].set_ylabel("P$_y$ ($\\mu$C/cm$^2$)", fontweight="bold", fontsize=20, labelpad=8)

    axes[2].set_yscale("log")
    axes[2].plot(t_us, idd, "-", color=ERS, lw=2.2)
    axes[2].axhline(I_FIRE_UA_UM, color=ACC, lw=2.4, ls="--")
    decade_ticks(axes[2])
    bold_labels(axes[2], "Time ($\\mu$s)", "I$_D$ ($\\mu$A/$\\mu$m)")
    note(axes[2],
         (f"Crosses threshold on pulse {n_fire}" if n_fire else "Does not fire")
         + f" at V$_{{pgm}}$ = {a:g} V; the dashed line is the "
           f"{I_FIRE_UA_UM:g} $\\mu$A/$\\mu$m read threshold.")

    fig.subplots_adjust(hspace=0.08)
    out = pd.DataFrame({"t_us": t_us, "phase": d["phase"], "pulse": d["pulse"],
                        "Vg_V": vg, "Py_uC_cm2": py, "Id_uA_um": idd,
                        "V_pgm_V": a, "threshold_uA_um": I_FIRE_UA_UM})
    return fig, out
