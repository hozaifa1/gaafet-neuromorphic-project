"""Chapter B -- calibration against the Liao 2022 MFMFS gate-all-around FeFET.

THE CAVEAT THIS CHAPTER MUST CARRY, because every other number in the paper
leans on it: the ABSOLUTE current level was never calibrated.  The overlay
applies a freely fitted width scalar -- TCAD saturation is 2.150e-4 A/um against
the measurement's 1.523e-6 A/um, a 141x gap, and that scalar absorbs all of it.
What is calibrated is the memory window, the threshold voltages, the
subthreshold slope, the on/off ratio and the turn-on SHAPE.  The y-axes here are
therefore drawn after the fitted scalar and labelled as such, and B3 removes the
level entirely by normalizing.

And any window number states its extraction criterion: the same node gives
MW = 1.296 V at 1e-8 A per nanosheet and 1.218 V at 1e-7 A/um (about 1e-9
A/sheet, a decade deeper in subthreshold).  Both are correct; neither means
anything on its own.
"""
from __future__ import annotations

import sys

import numpy as np
import pandas as pd

from ._common import (ACC, ERS, GREY, PGM, ROOT, bold_labels, decade_ticks,
                      figure, load_cal, new_ax, note, plt)

sys.path.insert(0, str(ROOT))
from rranalyze import vth_cc                      # noqa: E402  the one extraction rule

LIAO_SAT_A = 4.8e-6      # measured saturation current per nanosheet, Liao 2022 Fig. 7
FIT_FROM_V = 2.5         # the overdrive above which saturation is averaged for the fit
I_CC_SHEET = 1e-8        # constant-current criterion, per nanosheet
VT_CC_SHEET = 1e-7 * 0.090   # 100 nA/um on the per-sheet axis, for the B3 alignment


def _tcad() -> tuple[pd.DataFrame, pd.DataFrame, float]:
    """The two calibrated branches on the per-nanosheet axis, with the fitted scalar.

    The scalar is the same free width fit `Calibration/autocal/pub_figure.py`
    applies: one number, set so the erased branch's saturation matches the
    measurement's.  Reproduced here rather than invented, so the published
    overlay and this figure cannot diverge.
    """
    ers = load_cal("tcad_cal_n16_postERS").sort_values("Vg_V").reset_index(drop=True)
    pgm = load_cal("tcad_cal_n16_postPGM").sort_values("Vg_V").reset_index(drop=True)
    scale = LIAO_SAT_A / float(np.median(ers.Id_A_um[ers.Vg_V >= FIT_FROM_V]))
    ers["I_A"] = ers.Id_A_um * scale
    pgm["I_A"] = pgm.Id_A_um * scale
    return ers, pgm, scale


def _rising(v: np.ndarray, i: np.ndarray) -> np.ndarray:
    """Mask everything below the ambipolar minimum, so no clip line is drawn."""
    j = int(np.argmin(i))
    return np.where(np.arange(len(i)) >= j, i, np.nan)


@figure(
    "B1",
    claim="The calibrated deck reproduces the measured turn-on and the measured memory window "
          "of a published gate-all-around ferroelectric FET across the operating region, once "
          "a single free width scalar is fitted; the window and the threshold voltages are "
          "calibrated, the absolute current level is not.",
    source="Calibration/csvs/tcad_cal_n16_post{ERS,PGM}.csv (locked node cal_n16) against "
           "dots_{ERS,PGM}.csv, the digitized measurement points. One fitted width scalar, "
           "set on the erased branch's saturation, is applied to both TCAD branches.",
    convention="FITTED width scalar, not norm.py -- the absolute level is not calibrated",
)
def B1():
    """Overlay of the calibrated branches on the measurement, operating region."""
    ers, pgm, scale = _tcad()
    d_ers = load_cal("dots_ERS")
    d_pgm = load_cal("dots_PGM")

    vt_ers = vth_cc(ers.Vg_V.to_numpy(), ers.I_A.to_numpy(), I_CC_SHEET)
    vt_pgm = vth_cc(pgm.Vg_V.to_numpy(), pgm.I_A.to_numpy(), I_CC_SHEET)
    mw = vt_ers - vt_pgm

    fig, ax = new_ax(figsize=(8.4, 5.8))
    ax.set_yscale("log")
    ax.plot(pgm.Vg_V, _rising(pgm.Vg_V.to_numpy(), pgm.I_A.to_numpy()), "-",
            color=PGM, lw=3.0, label="TCAD, programmed")
    ax.plot(ers.Vg_V, _rising(ers.Vg_V.to_numpy(), ers.I_A.to_numpy()), "-",
            color=ERS, lw=3.0, label="TCAD, erased")
    ax.plot(d_pgm.iloc[:, 0], d_pgm.iloc[:, 1], "o", color=PGM, mfc="white", mew=2.0,
            ms=9, label="Liao 2022, programmed")
    ax.plot(d_ers.iloc[:, 0], d_ers.iloc[:, 1], "s", color=ERS, mfc="white", mew=2.0,
            ms=9, label="Liao 2022, erased")

    ax.axhline(I_CC_SHEET, color=GREY, lw=1.8, ls=":")
    ax.annotate("", xy=(vt_ers, I_CC_SHEET), xytext=(vt_pgm, I_CC_SHEET),
                arrowprops=dict(arrowstyle="<->", lw=2.4, color=ACC))
    ax.text((vt_ers + vt_pgm) / 2, I_CC_SHEET * 2.2, f"MW = {mw:.3f} V",
            ha="center", fontweight="bold", fontsize=13, color=ACC)

    ax.set_xlim(-1.3, 3.6)
    ax.set_ylim(1e-9, 3e-5)
    decade_ticks(ax)
    bold_labels(ax, "V$_G$ (V)", "I$_D$ (A / nanosheet, fitted width)")
    note(ax, f"V$_t$ at I$_{{cc}}$ = {I_CC_SHEET:.0e} A/sheet:\n"
             f"{vt_ers:+.3f} V erased, {vt_pgm:+.3f} V programmed\n"
             f"one free width scalar ({scale:.3g}) fitted on\n"
             f"the erased saturation above {FIT_FROM_V:g} V",
         xy=(0.03, 0.97), fontsize=11)
    ax.legend(loc="lower right", fontsize=10)

    out = pd.concat([
        ers.assign(state="erased", series="TCAD")[["Vg_V", "I_A", "state", "series"]],
        pgm.assign(state="programmed", series="TCAD")[["Vg_V", "I_A", "state", "series"]],
        pd.DataFrame({"Vg_V": d_ers.iloc[:, 0], "I_A": d_ers.iloc[:, 1],
                      "state": "erased", "series": "Liao2022"}),
        pd.DataFrame({"Vg_V": d_pgm.iloc[:, 0], "I_A": d_pgm.iloc[:, 1],
                      "state": "programmed", "series": "Liao2022"}),
    ], ignore_index=True)
    return fig, out


@figure(
    "B3",
    claim="With the memory window and the absolute current level both removed, the simulated "
          "turn-on shape still follows the measurement: the calibration reproduces the "
          "device's gate control, not just two fitted numbers.",
    source="Same four series as B1. Each curve is shifted by its own constant-current "
           "threshold and divided by its own on-current, so neither the window nor the "
           "fitted width scalar can contribute.",
    convention="normalized -- both the window and the absolute level are divided out",
)
def B3():
    """Overdrive-aligned shape comparison: x = V_G - V_t, y = I / I_on."""
    ers, pgm, _ = _tcad()
    series = [("TCAD, erased", ers.Vg_V.to_numpy(), ers.I_A.to_numpy(), ERS, "-", None),
              ("TCAD, programmed", pgm.Vg_V.to_numpy(), pgm.I_A.to_numpy(), PGM, "-", None)]
    for name, csv, colour, mk in (("Liao 2022, erased", "dots_ERS", ERS, "s"),
                                  ("Liao 2022, programmed", "dots_PGM", PGM, "o")):
        d = load_cal(csv).sort_values(d_col := load_cal(csv).columns[0])
        series.append((name, d.iloc[:, 0].to_numpy(), d.iloc[:, 1].to_numpy(),
                       colour, "none", mk))

    OVERDRIVE = 0.4
    fig, ax = new_ax(figsize=(8.4, 5.6))
    ax.set_yscale("log")
    rows = []
    for name, v, i, colour, ls, mk in series:
        vt = vth_cc(v, i, VT_CC_SHEET)
        if not np.isfinite(vt):
            continue
        i_on = float(np.interp(vt + OVERDRIVE, v, i))
        x, y = v - vt, _rising(v, i) / i_on
        if mk is None:
            ax.plot(x, y, ls, color=colour, lw=3.0, label=name)
        else:
            ax.plot(x, y, marker=mk, ls="none", color=colour, mfc="white", mew=2.0,
                    ms=9, label=name)
        rows.append(pd.DataFrame({"series": name, "overdrive_V": x,
                                  "I_over_Ion": y, "Vt_V": vt, "Ion_A": i_on}))

    ax.axvline(0, color=GREY, lw=1.6, ls=":")
    ax.axvline(OVERDRIVE, color=ACC, lw=1.8, ls="--")
    ax.set_xlim(-0.8, 1.8)
    ax.set_ylim(1e-4, 1e2)
    decade_ticks(ax)
    bold_labels(ax, "Gate overdrive V$_G$ $-$ V$_t$ (V)", "I$_D$ / I$_{on}$")
    note(ax, f"V$_t$ at {VT_CC_SHEET / 0.090 * 1e9:.0f} nA/$\\mu$m; "
             f"I$_{{on}}$ at {OVERDRIVE:g} V overdrive",
         xy=(0.03, 0.97), fontsize=12)
    ax.legend(loc="lower right", fontsize=10)

    return fig, pd.concat(rows, ignore_index=True)


@figure(
    "B5",
    claim="Across the operating region the simulated current sits within about a third of a "
          "decade of the measurement on both branches, and the residual is unbiased rather "
          "than a systematic offset.",
    source="Same series as B1. TCAD is interpolated onto the measurement's gate voltages -- "
           "the sparse set -- rather than the other way round.",
    convention="FITTED width scalar, as B1; the residual is a log ratio",
)
def B5():
    """Calibration residual, log10(I_TCAD / I_measured), with a 0.3-decade band."""
    ers, pgm, _ = _tcad()
    BAND = 0.3

    fig, ax = new_ax(figsize=(8.4, 5.4))
    rows, notes = [], []
    for name, tc, csv, colour, mk in (("erased", ers, "dots_ERS", ERS, "s"),
                                      ("programmed", pgm, "dots_PGM", PGM, "o")):
        d = load_cal(csv).sort_values(load_cal(csv).columns[0])
        v, i = d.iloc[:, 0].to_numpy(), d.iloc[:, 1].to_numpy()
        # only where the measurement is inside the plotted operating region
        m = (i > 1e-9) & (v >= tc.Vg_V.min()) & (v <= tc.Vg_V.max())
        v, i = v[m], i[m]
        i_t = np.interp(v, tc.Vg_V.to_numpy(), tc.I_A.to_numpy())
        r = np.log10(i_t) - np.log10(i)
        ax.plot(v, r, "-", marker=mk, color=colour, lw=2.4, ms=9, mfc="white", mew=2.0,
                label=name)
        notes.append(f"{name}: RMS {np.sqrt(np.mean(r ** 2)):.3f} dec, "
                     f"median {np.median(r):+.3f}, n = {len(r)}")
        rows.append(pd.DataFrame({"branch": name, "Vg_V": v, "I_measured_A": i,
                                  "I_tcad_A": i_t, "residual_decades": r}))

    ax.axhspan(-BAND, BAND, color=ACC, alpha=0.22, lw=0)
    ax.axhline(0, color="black", lw=2.0)
    bold_labels(ax, "V$_G$ (V)", "log$_{10}$(I$_{TCAD}$ / I$_{measured}$)")
    note(ax, "\n".join(notes) + f"\nshaded: $\\pm${BAND:g} decade",
         xy=(0.03, 0.97), fontsize=12)
    ax.legend(loc="lower right", fontsize=12)

    return fig, pd.concat(rows, ignore_index=True)
