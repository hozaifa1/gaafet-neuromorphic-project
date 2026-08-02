"""Chapter F -- synaptic behaviour.

F1 is the reference implementation for every other figure module: load, plot,
compute the annotation from the plotted arrays, return (fig, plotted_df).
"""
from __future__ import annotations

import numpy as np
import pandas as pd

from ._common import (ACC, ERS, GREY, LEVELS, PGM, bold_labels, decade_ticks,
                      figure, load_raw, new_ax, note, plt)


def _verify_levels(log_g: np.ndarray, sigma: np.ndarray) -> int:
    """How many levels write-verify could place, given the measured range and noise.

    The train's own stops are not the only option: with a verify loop you place
    targets where you like, so the ceiling is set by the range and the local
    cycle-to-cycle sigma.  Greedy placement from the bottom, each target 3 sigma
    above the last.  This is `rranalyze.rr8b`'s definition, kept identical so the
    figure and the analysis can never quote different numbers.
    """
    lo, hi = float(log_g[0]), float(log_g[-1])
    n, x = 1, lo
    while True:
        x += 3.0 * float(np.interp(x, log_g, sigma))
        if x > hi:
            return n
        n += 1


@figure(
    "F1",
    claim="Fifteen identical sub-coercive pulses move the channel current monotonically "
          "over 3.79 decades; at a 3-sigma cycle-to-cycle criterion 8 of the 15 stops are "
          "separable open-loop, while write-verify placement over the same range and the "
          "same measured noise would support about 16.",
    source="raw/c2c_per_level.csv -- node t17_c2c, 11 complete repeats of one "
           "15 x 2.0 V / 100 ns train on ONE device.  Level medians and their sigma "
           "come from the same run, so no cross-run ratio is formed.",
    convention="norm.to_uA_per_um applied upstream in rranalyze.rr8b (W_eff = 90 nm)",
)
def F1():
    """LTP staircase on a log axis, with the measured cycle-to-cycle band per level."""
    c2c = load_raw("c2c_per_level")

    n = c2c["level"].to_numpy()
    g = c2c["median_uA_um"].to_numpy()
    sigma = c2c["sigma_log10"].to_numpy()
    sep = c2c["separable_from_prev"].to_numpy().astype(bool)

    # +-3 sigma read band around each level, in decades, from this same run
    lo = g * 10.0 ** (-3.0 * sigma)
    hi = g * 10.0 ** (+3.0 * sigma)

    n_sep = int(np.sum(sep[1:])) + 1            # level 1 has no predecessor to separate from
    span = np.log10(g.max() / g.min())
    bits_open = np.log2(n_sep)
    n_verify = _verify_levels(np.log10(g), sigma)

    fig, ax = new_ax(figsize=(8.2, 5.6))
    ax.set_yscale("log")

    for i in range(len(n)):
        ax.fill_between([n[i] - 0.42, n[i] + 0.42], lo[i], hi[i],
                        color=(ACC if (i == 0 or sep[i]) else GREY),
                        alpha=0.30, lw=0, zorder=1)
    ax.plot(n, g, "-", color=PGM, lw=2.6, zorder=3)
    ax.plot(n[sep | (n == 1)], g[sep | (n == 1)], "o", color=PGM, ms=9,
            mec="black", mew=1.6, zorder=4, label="separable at 3$\\sigma$")
    ax.plot(n[~sep & (n != 1)], g[~sep & (n != 1)], "s", color="white", ms=8,
            mec=ERS, mew=2.0, zorder=4, label="below the 3$\\sigma$ floor")

    ax.set_xlim(0.3, len(n) + 0.7)
    ax.set_xticks(range(1, len(n) + 1, 2))
    decade_ticks(ax)
    bold_labels(ax, "Pulse number", "I$_D$ ($\\mu$A/$\\mu$m)")
    note(ax, f"{len(n)} pulses, {span:.2f} decades\n"
             f"{n_sep} separable open-loop ({bits_open:.1f} bit)\n"
             f"$\\approx${n_verify} with write-verify ({np.log2(n_verify):.1f} bit)")
    ax.legend(loc="lower right")

    out = c2c.copy()
    out["band_lo_uA_um"] = lo
    out["band_hi_uA_um"] = hi
    return fig, out


def _nl_model(n, A, N):
    """The conventional synaptic nonlinearity form, G normalized to [0, 1]."""
    return (1.0 - np.exp(-n * A)) / (1.0 - np.exp(-N * A))


@figure(
    "F2",
    claim="The potentiation ladder is not described by the conventional exponential-saturation "
          "nonlinearity model: fitted on the normalized linear scale the residual is systematic "
          "and one-sided, because this device's response is close to exponential in pulse number "
          "rather than saturating from the first pulse.",
    source="raw/ltp_potentiation.csv -- node t8_ltp, one 15 x 2.0 V / 100 ns train. Single node.",
    convention="normalized conductance -- a ratio, invariant to the width convention",
)
def F2():
    """LTP nonlinearity fit, with the residual shown rather than hidden."""
    from scipy.optimize import curve_fit

    d = load_raw("ltp_potentiation")
    n = d["pulse_n"].to_numpy(dtype=float)
    g = d["Id_uA_per_um"].to_numpy()
    gn = (g - g.min()) / (g.max() - g.min())
    N = float(n.max())

    popt, _ = curve_fit(lambda x, A: _nl_model(x, A, N), n, gn, p0=[-0.3], maxfev=20000)
    A = float(popt[0])
    fit = _nl_model(n, A, N)
    resid = gn - fit
    ss = 1.0 - np.sum(resid ** 2) / np.sum((gn - gn.mean()) ** 2)

    fig, ax = new_ax(figsize=(8.2, 5.6))
    nn = np.linspace(n.min(), n.max(), 300)
    ax.plot(nn, _nl_model(nn, A, N), "-", color=GREY, lw=2.6,
            label="$(1-e^{-nA})/(1-e^{-NA})$ fit")
    ax.plot(n, gn, "o", color=PGM, ms=11, mec="black", mew=1.6, label="measured")
    bold_labels(ax, "Pulse number", "Normalized conductance")
    # The train is sigmoidal -- an incubation delay of two to three pulses, then a
    # fast swing -- so the 10-90 % pulse span is quoted alongside A, which on its
    # own is not a faithful descriptor of this shape.
    lo = float(np.interp(0.1, gn, n))
    hi = float(np.interp(0.9, gn, n))
    ax.set_ylim(-0.10, 1.28)
    ax.legend(loc="lower right")
    note(ax, f"A$_{{LTP}}$ = {A:.3f},  R$^2$ = {ss:.3f}\n"
             f"10--90 % span = {hi - lo:.1f} pulses\n"
             f"max residual {np.abs(resid).max():.3f}, "
             f"{int(np.sum(resid < 0))} of {len(n)} points below the fit",
         xy=(0.30, 0.40), fontsize=12)

    ins = ax.inset_axes([0.10, 0.56, 0.31, 0.28])
    ins.axhline(0, color="black", lw=1.6)
    ins.bar(n, resid, color=ACC, edgecolor="black", lw=1.0)
    ins.set_xlabel("n", fontweight="bold", fontsize=11)
    ins.set_ylabel("residual", fontweight="bold", fontsize=10)
    ins.tick_params(direction="in", labelsize=9, width=1.4)
    for sp in ins.spines.values():
        sp.set_linewidth(1.6)

    out = d.copy()
    out["G_normalized"] = gn
    out["fit"] = fit
    out["residual"] = resid
    return fig, out


@figure(
    "F5",
    claim="Potentiation and depression close into a repeatable loop over three cycles, and the "
          "window lost between cycles is lost almost entirely at the erased floor while the "
          "potentiated ceiling barely moves -- a single erase pulse does not fully switch a "
          "programmed device, because erase is opposed by the depolarization field.",
    source="raw/ltp_ltd_cycles.csv -- RR-3, three alternating 15-pulse potentiation / "
           "15-pulse depression trains on one device, one node.",
    convention="norm.to_uA_per_um applied upstream in rranalyze.rr3 (W_eff = 90 nm)",
)
def F5():
    """LTP + LTD loop, three cycles, log axis.

    This is WRITE REPEATABILITY, not endurance.  The Preisach ferroelectric model
    used here carries no fatigue, wake-up or imprint term, so it is structurally
    incapable of measuring endurance; a flat cycling curve would be a property of
    the equations rather than evidence about the device.
    """
    d = load_raw("ltp_ltd_cycles")
    npulse = int(d["pulse_n"].max())

    fig, ax = new_ax(figsize=(8.8, 5.6))
    ax.set_yscale("log")
    rows = []
    for c, s in d.groupby("cycle"):
        s = s.sort_values("pulse_n")
        col = LEVELS(0.10 + 0.38 * (c - 1))
        x_up = s.pulse_n.to_numpy(dtype=float)
        x_dn = npulse + s.pulse_n.to_numpy(dtype=float)
        ax.plot(x_up, s.G_ltp_uA_um, "-o", color=col, lw=2.6, ms=6, mec="black", mew=0.9,
                label=f"cycle {int(c)}")
        ax.plot(x_dn, s.G_ltd_uA_um, "--s", color=col, lw=2.6, ms=6, mec="black", mew=0.9)
        rows.append(pd.DataFrame({"cycle": c, "cumulative_pulse": np.r_[x_up, x_dn],
                                  "phase": ["LTP"] * npulse + ["LTD"] * npulse,
                                  "G_uA_um": np.r_[s.G_ltp_uA_um, s.G_ltd_uA_um]}))

    out = pd.concat(rows, ignore_index=True)
    # Window per cycle is the potentiated ceiling over the DEPRESSED floor, which is
    # rranalyze.rr3's definition.  Taking the minimum over both phases would use the
    # start of potentiation instead -- a different, larger number for a different thing.
    stat = pd.DataFrame({
        "max": out[out.phase == "LTP"].groupby("cycle").G_uA_um.max(),
        "min": out[out.phase == "LTD"].groupby("cycle").G_uA_um.min(),
    })
    stat["window_x"] = stat["max"] / stat["min"]
    for _, r in stat.iterrows():
        ax.plot([0.4, 2 * npulse + 0.6], [r["min"]] * 2, ":", color=GREY, lw=1.4)

    ax.axvline(npulse + 0.5, color="black", lw=1.6, alpha=0.5)
    ax.set_xlim(0.4, 2 * npulse + 0.6)
    ax.set_xticks(list(range(5, 2 * npulse + 1, 5)))
    ax.set_ylim(out.G_uA_um.min() / 6, out.G_uA_um.max() * 60)
    decade_ticks(ax)
    bold_labels(ax, "Cumulative pulse number  (potentiate $\\rightarrow$ depress)",
                "I$_D$ ($\\mu$A/$\\mu$m)")
    ax.legend(loc="lower left", ncol=3, fontsize=11)
    note(ax, "window per cycle: " +
             ", ".join(f"{r.window_x:,.0f}$\\times$" for _, r in stat.iterrows()) +
             f"\nceiling moves {stat['max'].iloc[-1] / stat['max'].iloc[0]:.2f}$\\times$, "
             f"floor moves {stat['min'].iloc[-1] / stat['min'].iloc[0]:.1f}$\\times$",
         xy=(0.03, 0.97), fontsize=12)

    return fig, out


@figure(
    "F9",
    claim="The potentiation ladder is strongly temperature dependent and the dependence is not "
          "monotonic: at the top of the ladder 350 K sits about six times BELOW 300 K while "
          "250 K sits slightly above it, so no activation energy can be extracted from these "
          "three points and none is claimed.",
    source="raw/ltp_vs_temperature.csv -- nodes t9_t250 / t8_ltp / t9_t350, the same "
           "15 x 2.0 V train at 250, 300 and 350 K. Three temperatures only.",
    convention="norm.to_uA_per_um applied upstream in rebuild_raw.py (W_eff = 90 nm)",
)
def F9():
    """LTP against temperature on a log axis, plus the ratio to 300 K.

    The conventional second panel here would be an Arrhenius plot.  It is not
    drawn, because the trend across the three available temperatures is not
    monotonic: a straight line through log(G) vs 1/T would be fitting a sign
    change.  The ratio panel carries the same information without implying a
    thermally activated law the data does not support.
    """
    d = load_raw("ltp_vs_temperature")
    n = d["pulse_n"].to_numpy()
    temps = [(250, "G_250K_uA_um", ERS, "o"),
             (300, "G_300K_uA_um", PGM, "s"),
             (350, "G_350K_uA_um", "#e07b00", "^")]

    fig, axes = plt.subplots(1, 2, figsize=(13.0, 5.4))
    for ax in axes:
        for sp in ax.spines.values():
            sp.set_linewidth(2.0)
        ax.tick_params(axis="both", which="both", direction="in", top=False, right=False,
                       width=2.0, labelsize=12)
        ax.minorticks_on()
        for lbl in ax.get_xticklabels() + ax.get_yticklabels():
            lbl.set_fontweight("bold")

    ax = axes[0]
    ax.set_yscale("log")
    for T, col, colour, mk in temps:
        ax.plot(n, d[col], "-", marker=mk, color=colour, lw=2.6, ms=7, mec="black",
                mew=1.0, label=f"{T} K")
    decade_ticks(ax)
    bold_labels(ax, "Pulse number", "I$_D$ ($\\mu$A/$\\mu$m)")
    ax.legend(loc="upper left", fontsize=12)

    ax = axes[1]
    ax.set_yscale("log")
    ref = d["G_300K_uA_um"].to_numpy()
    for T, col, colour, mk in temps:
        if T == 300:
            continue
        ax.plot(n, d[col].to_numpy() / ref, "-", marker=mk, color=colour, lw=2.6, ms=7,
                mec="black", mew=1.0, label=f"{T} K / 300 K")
    ax.axhline(1.0, color="black", lw=2.0, ls="--")
    decade_ticks(ax)
    bold_labels(ax, "Pulse number", "I$_D$ / I$_D$(300 K)")
    ax.legend(loc="lower left", fontsize=12)
    top = d.iloc[-1]
    fig.text(0.5, -0.03,
             f"at the top level 350 K is "
             f"{ref[-1] / top['G_350K_uA_um']:.1f}$\\times$ below 300 K while "
             f"250 K is {top['G_250K_uA_um'] / ref[-1]:.2f}$\\times$ it "
             f"-- the ladder is not monotonic in temperature, so no activation energy "
             f"is extracted",
             ha="center", fontweight="bold", fontsize=11)

    out = d.copy()
    out["ratio_250_over_300"] = d["G_250K_uA_um"] / ref
    out["ratio_350_over_300"] = d["G_350K_uA_um"] / ref
    return fig, out
