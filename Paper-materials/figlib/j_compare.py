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
    ax.tick_params(axis="x", pad=26)          # keep labels clear of the outer ring
    ax.set_ylim(0, 1.02)
    ax.set_yticks([0.25, 0.5, 0.75, 1.0])
    ax.set_yticklabels(["0.25", "0.50", "0.75", "1.0"], fontweight="bold", fontsize=10)
    ax.legend(loc="lower center", bbox_to_anchor=(0.5, -0.10), ncol=2, fontsize=12)
    fig.text(0.5, 0.075,
             "each axis normalized to the better of the two devices; outward is better",
             ha="center", fontweight="bold", fontsize=11)
    fig.text(0.5, 0.005,
             f"the level axis uses one shared readout-separation rule "
             f"($\\geq${SEP:g}$\\times$) so the two devices are comparable;\n"
             f"this device's headline open-loop count under its own measured "
             f"cycle-to-cycle noise is smaller (figure F1)",
             ha="center", va="bottom", fontsize=10, fontweight="bold")
    fig.subplots_adjust(bottom=0.26, top=0.90, left=0.16, right=0.84)

    df["GAA_normalized"] = ga
    df["planar_normalized"] = pa
    return fig, df


@figure(
    "J5",
    claim="Against a survey of recent ferroelectric analog-memory devices this device sits at "
          "the low-energy end of what is reported, and the survey also shows how rarely "
          "energy per programming pulse is reported at all: most papers state a level count "
          "and no energy, so the comparison a reader wants cannot be made for most of them.",
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

    both = lit.dropna(subset=["n_levels", "energy_per_pulse_pJ"])
    only_n = lit[lit["n_levels"].notna() & lit["energy_per_pulse_pJ"].isna()]

    fig, ax = new_ax(figsize=(8.8, 5.8))
    ax.set_xscale("log")
    ax.set_yscale("log")

    for _, r in both.iterrows():
        hi = str(r["confidence"]).strip() == "high"
        ax.plot([r["energy_per_pulse_pJ"]], [r["n_levels"]], "o", ms=12,
                color=GREY, mfc=GREY if hi else "white", mew=2.0, mec=GREY, zorder=3)
        ax.annotate(str(r["label"]).split("_")[0], xy=(r["energy_per_pulse_pJ"], r["n_levels"]),
                    xytext=(0, 14), textcoords="offset points", ha="center",
                    fontsize=10, fontweight="bold", color=GREY)

    # devices that report a level count but no energy: a rug along the top
    y_rug = float(lit["n_levels"].max()) * 2.2
    for _, r in only_n.iterrows():
        hi = str(r["confidence"]).strip() == "high"
        ax.plot([e_pj * 40], [r["n_levels"]], "<", ms=10, color=GREY,
                mfc=GREY if hi else "white", mew=1.8, mec=GREY, alpha=0.85, zorder=2)

    ax.plot([e_pj], [n_open], "*", ms=26, color=PGM, mec="black", mew=1.6, zorder=6)
    ax.plot([e_pj], [n_ver], "*", ms=20, color=ACC, mfc="white", mec=ACC, mew=2.6, zorder=6)
    ax.annotate("", xy=(e_pj, n_ver), xytext=(e_pj, n_open),
                arrowprops=dict(arrowstyle="->", lw=2.6, color=ACC))
    ax.annotate(f"this work, open loop\n{n_open} levels, {e_pj * 1e6:.1f} aJ/pulse "
                f"at {v_pgm:g} V",
                xy=(e_pj, n_open), xytext=(16, -30), textcoords="offset points",
                fontsize=11, fontweight="bold", color=PGM)
    ax.annotate(f"with write-verify: {n_ver}", xy=(e_pj, n_ver), xytext=(16, 6),
                textcoords="offset points", fontsize=11, fontweight="bold", color=ACC)

    decade_ticks(ax, "x")
    decade_ticks(ax, "y")
    ax.set_ylim(min(n_open, float(lit["n_levels"].min())) / 2.2, y_rug)
    bold_labels(ax, "Energy per programming pulse (pJ)", "Analog levels reported")
    fig.text(0.5, -0.10,
             f"{len(both)} of {len(lit)} surveyed devices report both quantities; "
             f"{len(only_n)} report a level count only (left-pointing markers, placed at an "
             f"arbitrary energy).\nOpen markers: the source number could not be confirmed "
             f"in the paper text.",
             ha="center", fontweight="bold", fontsize=10)

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
