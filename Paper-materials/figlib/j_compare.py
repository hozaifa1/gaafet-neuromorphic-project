"""Chapter J -- comparison and benchmarking.

J1 is an ablation, not a competition: the planar device is the SAME stack with
the bottom gate removed, so the two differ in gate control and nothing else.
Its raw memory window is far larger than the nanosheet's; that is reported at
face value rather than normalized away.

J5 is the only figure in this paper whose data is other people's.  Each point is
traceable to a row of `Paper-materials/literature_benchmark.csv`, which carries
the DOI and the sentence the number was read from, and to
`literature_benchmark_notes.md`, which says which rows are weak.
"""
from __future__ import annotations

import re
import sys

import numpy as np
import pandas as pd

from ._common import (ACC, ERS, GREY, HERE, PGM, PLANAR, ROOT, bold_labels,
                      decade_ticks, figure, id_uA_um, load_raw, new_ax,
                      node_files, norm, note, parse_plt, plt)

SEP = 1.5      # adjacent analog levels count as separate if they differ by this factor
LIT = HERE / "literature_benchmark.csv"


def _params() -> tuple[dict, dict, dict]:
    sys.path.insert(0, str(PLANAR))
    sys.path.insert(0, str(ROOT / "Device_Optimization"))
    import planar_params                                 # noqa: PLC0415
    import gaafefet_params_optimized as gaa              # noqa: PLC0415
    return gaa.DEVICE, planar_params.DEVICE, gaa.OPERATING


def _levels_at(ratio: float, g: np.ndarray) -> int:
    """How many ladder stops survive a 'separated by >= ratio' rule, walking upward."""
    n, last = 1, float(g[0])
    for x in g[1:]:
        if x / last >= ratio:
            n += 1
            last = float(x)
    return n


@figure(
    "J1",
    claim="Removing the second gate from the identical stack buys a much larger raw memory "
          "window but costs the properties this application needs: the nanosheet switches at "
          "a lower programming voltage, resolves more analog levels at the same separation "
          "criterion, and holds a steeper subthreshold slope, so the planar device wins the "
          "headline number and loses the useful ones.",
    source="Planar_Device_Work/planar_params.py against "
           "Device_Optimization/gaafefet_params_optimized.py -- both auto-extracted from "
           "their own runs. The level count for BOTH devices is recomputed here under one "
           "shared criterion (adjacent stops separated by at least 1.5x) so the axis is "
           "like-for-like; the planar file's own count uses the same rule.",
    convention="norm.CORR_PLANAR_COMPARE = 1.0 -- the planar deck runs at Areafactor 1.0 "
               "per um of single-gate width, the GAA CSVs are per um of gate perimeter, "
               "so the two are already the same physical normalization",
)
def J1():
    """GAA versus its planar ablation, on the axes a synapse is judged by."""
    gaa, pl, op = _params()
    ladder = load_raw("ltp_potentiation")["Id_uA_per_um"].to_numpy()
    n_gaa = _levels_at(SEP, ladder) * norm.CORR_PLANAR_COMPARE
    n_pl = float(pl["n_levels"])
    # Retained on/off at the read point, taken from the retained I-V itself rather
    # than from the parameter file: both branches then come from one run.  (The
    # parameter file's ID_fire carried a factor-1000 typo, found by this figure and
    # since corrected; reading the CSV is what makes such a thing impossible.)
    iv = load_raw("memory_window_iv")
    k0 = int(np.abs(iv.Vg_V).idxmin())
    onoff_gaa = float(iv.Id_programmed_uA_um[k0] / iv.Id_erased_uA_um[k0])

    # Retention is deliberately NOT an axis: the planar figure is a 100 us hold and
    # the nanosheet's 100 us window sits inside its own post-write settling
    # transient, so the two numbers are not measurements of the same thing.
    axes_spec = [
        ("Subthreshold\nslope", 1.0 / (gaa["SS"] * 1e3), 1.0 / pl["SS_pgm_mVdec"],
         "1 / (mV/dec)"),
        ("Memory\nwindow", gaa["MW"], pl["MW_volts"], "V"),
        ("Retained\nON/OFF", onoff_gaa, pl["window"], "x"),
        ("Analog levels\n($\\geq$1.5$\\times$ apart)", n_gaa, n_pl, "count"),
        ("Low programming\nvoltage", 1.0 / op["Vpulse_optimal"], 1.0 / pl["V_pgm"],
         "1 / V"),
    ]
    rows = []
    for name, a, b, unit in axes_spec:
        rows.append({"axis": name.replace("\n", " "), "GAA": a, "planar": b, "unit": unit})
    df = pd.DataFrame(rows).dropna(subset=["GAA", "planar"])

    ref = np.maximum(df.GAA.to_numpy(), df.planar.to_numpy())
    ga = df.GAA.to_numpy() / ref
    pa = df.planar.to_numpy() / ref
    labels = [r["axis"] for _, r in df.iterrows()]

    ang = np.linspace(0, 2 * np.pi, len(df), endpoint=False)
    close = np.r_[ang, ang[:1]]
    fig, ax = plt.subplots(figsize=(8.8, 8.0), subplot_kw={"projection": "polar"})
    ax.plot(close, np.r_[ga, ga[:1]], "-o", color=PGM, lw=3.0, ms=9, label="GAA nanosheet")
    ax.fill(close, np.r_[ga, ga[:1]], color=PGM, alpha=0.18)
    ax.plot(close, np.r_[pa, pa[:1]], "-s", color=ERS, lw=3.0, ms=9,
            label="planar ablation")
    ax.fill(close, np.r_[pa, pa[:1]], color=ERS, alpha=0.14)

    ax.set_xticks(ang)
    ax.set_xticklabels([lab.replace(" ", "\n", 1) for lab in labels],
                       fontweight="bold", fontsize=11)
    ax.tick_params(axis="x", pad=44)          # keep labels clear of the outer ring
    ax.set_ylim(0, 1.02)
    ax.set_yticks([0.25, 0.5, 0.75, 1.0])
    ax.set_yticklabels(["0.25", "0.50", "0.75", "1.0"], fontweight="bold", fontsize=10)
    ax.legend(loc="lower center", bbox_to_anchor=(0.5, -0.13), ncol=2, fontsize=12,
              frameon=False)
    note(ax, "Each axis is normalized to the better of the two devices, so "
             "outward is better. The level axis uses one shared "
             f"readout-separation rule ($\\geq${SEP:g}$\\times$) so the two "
             "devices are comparable; this device's headline open-loop count "
             "under its own measured cycle-to-cycle noise is smaller (see F1).")
    fig.subplots_adjust(bottom=0.13, top=0.80, left=0.23, right=0.77)

    df["GAA_normalized"] = ga
    df["planar_normalized"] = pa
    return fig, df


@figure(
    "J5",
    claim="Recent ferroelectric analog memories report level counts from 16 to 140, and this "
          "device's open-loop count sits at the low end of that range -- but the counts are "
          "not measured under a common criterion, and only two of fifteen surveyed papers "
          "report energy per programming pulse at all, so the comparison a reader wants "
          "cannot be made from the published record.",
    source="Paper-materials/literature_benchmark.csv -- 15 published ferroelectric devices, "
           "each row carrying its DOI and the sentence the number was read from; weak rows "
           "are listed in literature_benchmark_notes.md. This work's point is computed here "
           "from Device_Optimization/outputs/t8_ltp (energy) and raw/c2c_per_level.csv "
           "(levels), not taken from the CSV.",
    convention="this work: gate charge via norm.to_device_amps; literature as published",
)
def J5():
    """Analog levels against energy per programming pulse, with this work marked."""
    lit = pd.read_csv(LIT)

    # --- this work, computed, not quoted -------------------------------------
    e_j = []
    v_pgm = None
    for f in node_files("t8_ltp", r"^p\d\d_write_"):
        d = parse_plt(f)
        v_pgm = int(re.search(r"_v(\d{3})_", f.name).group(1)) / 10.0
        q = norm.to_device_amps(d["gate_contact Charge"].to_numpy())
        e_j.append(v_pgm * (q[-1] - q[0]))
    e_pj = float(np.mean(e_j)) * 1e12

    c2c = load_raw("c2c_per_level")
    n_open = int(c2c["separable_from_prev"].astype(bool)[1:].sum()) + 1
    lg = np.log10(c2c["median_uA_um"].to_numpy())
    sig = c2c["sigma_log10"].to_numpy()
    n_ver, x = 1, float(lg[0])
    while True:
        x += 3.0 * float(np.interp(x, lg, sig))
        if x > lg[-1]:
            break
        n_ver += 1

    # A levels-against-energy scatter is the figure this comparison wants, and the
    # survey will not support one: only 2 of 15 recent papers report energy per
    # programming pulse at all.  Plotting it anyway would put a single comparable
    # marker on the page and let the empty axis imply a lead that was never
    # measured.  So the figure is drawn on the quantity the field does report --
    # the level count -- and the energy comparison is made in the text, where two
    # points can be quoted as two points.
    n_energy = int(lit["energy_per_pulse_pJ"].notna().sum())
    d = lit.dropna(subset=["n_levels"]).sort_values("n_levels").reset_index(drop=True)

    fig, ax = new_ax(figsize=(9.0, 6.4))
    ax.set_xscale("log")

    y = np.arange(len(d), dtype=float)
    for k, r in d.iterrows():
        hi = str(r["confidence"]).strip() == "high"
        ax.plot([1, r["n_levels"]], [y[k]] * 2, "-", color=GREY, lw=1.6, alpha=0.55,
                zorder=1)
        ax.plot([r["n_levels"]], [y[k]], "o", ms=12, mfc=GREY if hi else "white",
                mew=2.0, mec=GREY, zorder=3)

    y_open, y_ver = len(d) + 0.6, len(d) + 1.6
    for yy, n_lev, colour, fill, lab in (
            (y_open, n_open, PGM, PGM, f"this work, open loop ({n_open})"),
            (y_ver, n_ver, ACC, "white", f"this work, write-verify ({n_ver})")):
        ax.plot([1, n_lev], [yy] * 2, "-", color=colour, lw=2.4, zorder=2)
        ax.plot([n_lev], [yy], "*", ms=24, mfc=fill, mec=colour, mew=2.4, zorder=5)

    ax.set_yticks(np.r_[y, y_open, y_ver])
    ax.set_yticklabels([str(s).replace("_", " ") for s in d["label"]]
                       + ["THIS WORK, open loop", "THIS WORK, write-verify"],
                       fontsize=10)
    for lbl, colour in zip(ax.get_yticklabels(), [GREY] * len(d) + [PGM, ACC]):
        lbl.set_color(colour)
        lbl.set_fontweight("bold")
    ax.set_ylim(-0.8, y_ver + 0.8)
    ax.set_xlim(4, float(d["n_levels"].max()) * 2.4)
    decade_ticks(ax, "x")
    bold_labels(ax, "Analog levels reported", None)
    note(ax, f"Devices reporting a level count, from a survey of {len(lit)} recent "
             f"ferroelectric analog memories; {len(d)} of them state one, and every "
             f"plotted count was confirmed directly against its paper's text. Only "
             f"{n_energy} of {len(lit)} report energy per programming pulse, which is "
             f"why the comparison is drawn on level count; this device switches at "
             f"{e_pj * 1e6:.1f} aJ per pulse at {v_pgm:g} V. The counts here are "
             f"reported values under each paper's own criterion, which is the point: "
             f"this work's {n_open} is an open-loop count under its own measured "
             f"cycle-to-cycle noise, and Section V shows level count does not predict "
             f"network accuracy.")

    out = pd.concat([
        lit.assign(series="literature"),
        pd.DataFrame([{"label": "This work (open loop)", "device_type": "GAA HZO FeFET",
                       "n_levels": n_open, "energy_per_pulse_pJ": e_pj,
                       "v_program_V": v_pgm, "confidence": "computed",
                       "series": "this work"},
                      {"label": "This work (write-verify)", "device_type": "GAA HZO FeFET",
                       "n_levels": n_ver, "energy_per_pulse_pJ": e_pj,
                       "v_program_V": v_pgm, "confidence": "computed",
                       "series": "this work"}]),
    ], ignore_index=True)
    return fig, out
