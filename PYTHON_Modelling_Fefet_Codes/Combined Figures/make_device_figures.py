"""
Device-physics figures (shared by ECG and EEG) from MEASURED GAA-FeFET data.
Writes PNG + reproducing CSV into a target output folder (run once per task folder).
Figures: LTP conductance ladder, temperature ladders (250/300/350 K), retention,
transfer curves, memory-window I-V, differential achievable-weight map.
Usage: python make_device_figures.py "<out_dir>"
"""
import os, sys
import numpy as np
import pandas as pd
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import figstyle as fs
import matplotlib.pyplot as plt

_HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(_HERE, "..", "..", "Device_Optimization", "csv_export", "raw")
V_READ = 0.05
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(_HERE, "ecg figures")
os.makedirs(OUT, exist_ok=True)
def P(name): return os.path.join(OUT, name)


def fig_ltp():
    d = pd.read_csv(os.path.join(RAW, "ltp_potentiation.csv"))
    n = d["pulse_n"].to_numpy(); g = d["Id_uA_per_um"].to_numpy() * 1e-6 / V_READ  # S/um
    fig, ax = fs.new_ax()
    ax.semilogy(n, g, "-o", color="#0b3d1e", mfc="#2e8b57", mec="black", ms=8, lw=2.5, mew=1.5)
    fs.bold_labels(ax, "Pulse number", "Conductance G (S/µm)")
    fs.finish(fig, P("dev1_LTP_ladder.png"))
    fs.save_csv(P("dev1_LTP_ladder.csv"), ["pulse_n", "G_S_per_um"], list(zip(n, g)))


def fig_temperature():
    d = pd.read_csv(os.path.join(RAW, "ltp_vs_temperature.csv"))
    n = d["pulse_n"].to_numpy()
    fig, ax = fs.new_ax()
    cols = [("G_250K_uA_um", "250 K", "#1f4e79"), ("G_300K_uA_um", "300 K", "#2e8b57"),
            ("G_350K_uA_um", "350 K", "#b8860b")]
    rows = [["pulse_n"] + [c[0].replace("_uA_um", "_S_per_um") for c in cols]]
    G = {}
    for key, lab, col in cols:
        g = d[key].to_numpy() * 1e-6 / V_READ
        G[key] = g
        ax.semilogy(n, g, "-o", color=col, ms=6, lw=2.2, mec="black", mew=1.2, label=lab)
    ax.legend(prop={"weight": "bold", "size": 11})
    fs.bold_labels(ax, "Pulse number", "Conductance G (S/µm)")
    fs.finish(fig, P("dev2_temperature_ladders.png"))
    rowvals = [[n[i]] + [G[c[0]][i] for c in cols] for i in range(len(n))]
    fs.save_csv(P("dev2_temperature_ladders.csv"),
                ["pulse_n", "G_250K", "G_300K", "G_350K"], rowvals)


TAU_P_S = 1e-5          # depolarization constant of the retained state (app.par)
SETTLE_S = 5 * TAU_P_S  # the state is not "retained" until ~5 tau_P after the write ends


def fig_retention():
    """RR-4 retention, out to 10 ms -- NOT the 100 us window.

    This figure used to plot leak_retention.csv (17.5 -> 100 us) and label its -2.9 % as
    retention drift. That window sits INSIDE the post-write settling transient, which
    relaxes with tau_P = 10 us; reading it as retention is the same mistake that produced
    three fabricated failures in Phase 5 (a retention collapse, a read-disturb collapse and
    an endurance collapse). Measured out to 10 ms the state settles by ~5 tau_P and is then
    flat, so the honest retention number is the PLATEAU drift and the transient is shaded
    rather than fitted.
    """
    d = pd.read_csv(os.path.join(RAW, "retention_long.csv"))
    d = d[(d.node == "t12_ret") & (d.seg == "hold")].sort_values("t_rel_s")
    t = d["t_rel_s"].to_numpy(); g = d["G_uA_um"].to_numpy()
    pl = t >= SETTLE_S
    drift = 100 * (g[pl][-1] / g[pl][0] - 1)

    fig, ax = fs.new_ax()
    m = t > 0
    ax.axvspan(t[m].min() * 1e6, SETTLE_S * 1e6, color="#d9d9d9", alpha=0.55, lw=0)
    ax.plot(t[m] * 1e6, g[m], "-o", color="#0b3d1e", mfc="#2e8b57", mec="black",
            ms=5, lw=2.3, mew=1.0)
    ax.axhline(g[pl][0], ls="--", color="gray", lw=1.6)
    ax.set_xscale("log")
    ax.text(SETTLE_S * 1e6 * 0.55, g.max() * 0.62, "post-write\nsettling\n(5 $\\tau_P$)",
            ha="right", fontweight="bold", fontsize=11, color="#555555")
    ax.text(t.max() * 1e6, g[pl][0] * 2.0, f"retained plateau: {drift:+.2f} % over "
            f"{np.log10(t.max()/SETTLE_S):.1f} decades",
            ha="right", fontweight="bold", fontsize=11)
    fs.bold_labels(ax, "Time after write (µs)", "Conductance (µA/µm @ Vread)")
    fs.finish(fig, P("dev3_retention.png"))
    fs.save_csv(P("dev3_retention.csv"), ["t_us", "G_uA_um", "in_plateau"],
                [[t[i] * 1e6, g[i], bool(pl[i])] for i in range(len(t))])
    print(f"retention: settles by {SETTLE_S*1e6:.0f} us, plateau drift {drift:+.2f} %")


def fig_transfer():
    d = pd.read_csv(os.path.join(RAW, "transfer_curves.csv"))
    vg = d["Vg_V"].to_numpy()
    fig, ax = fs.new_ax()
    ax.semilogy(vg, d["Id_erased_uA_um"].to_numpy(), "-o", color="#1f4e79", ms=5, lw=2.2,
                mec="black", mew=1.0, label="Erased (LRS→HRS)")
    ax.semilogy(vg, d["Id_programmed_uA_um"].to_numpy(), "-s", color="#2e8b57", ms=5, lw=2.2,
                mec="black", mew=1.0, label="Programmed")
    ax.legend(prop={"weight": "bold", "size": 11})
    fs.bold_labels(ax, "Gate voltage Vg (V)", "Drain current Id (µA/µm)")
    fs.finish(fig, P("dev4_transfer_curves.png"))
    fs.save_csv(P("dev4_transfer_curves.csv"), ["Vg_V", "Id_erased_uA_um", "Id_programmed_uA_um"],
                list(zip(vg, d["Id_erased_uA_um"], d["Id_programmed_uA_um"])))


def fig_memwindow():
    d = pd.read_csv(os.path.join(RAW, "memory_window_iv.csv"))
    vg = d["Vg_V"].to_numpy()
    fig, ax = fs.new_ax()
    ax.semilogy(vg, d["Id_erased_uA_um"].to_numpy(), color="#1f4e79", lw=2.6, label="Erased")
    ax.semilogy(vg, d["Id_programmed_uA_um"].to_numpy(), color="#2e8b57", lw=2.6, label="Programmed")
    ax.legend(prop={"weight": "bold", "size": 11})
    fs.bold_labels(ax, "Gate voltage Vg (V)", "Drain current Id (µA/µm)")
    fs.finish(fig, P("dev5_memory_window.png"))
    fs.save_csv(P("dev5_memory_window.csv"), ["Vg_V", "Id_erased_uA_um", "Id_programmed_uA_um"],
                list(zip(vg, d["Id_erased_uA_um"], d["Id_programmed_uA_um"])))


def fig_diffmap():
    d = pd.read_csv(os.path.join(RAW, "ltp_potentiation.csv"))
    g = np.sort(d["Id_uA_per_um"].to_numpy() * 1e-6 / V_READ)
    gmax = g[-1]
    vals = sorted({round(float(a - b) / gmax, 6) for a in g for b in g})
    vals = np.array(vals)
    fig, ax = fs.new_ax()
    ax.plot(range(len(vals)), vals, "-", color="#0b3d1e", lw=1.6)
    ax.plot(range(len(vals)), vals, ".", color="#2e8b57", ms=4)
    ax.axhline(0, color="gray", lw=1.2, ls="--")
    fs.bold_labels(ax, "Achievable weight index (sorted)", "Differential weight (G⁺−G⁻)/Gmax")
    ax.text(0.05, 0.9, f"{len(vals)} achievable levels", transform=ax.transAxes,
            fontweight="bold", fontsize=11)
    fs.finish(fig, P("dev6_differential_weight_map.png"))
    fs.save_csv(P("dev6_differential_weight_map.csv"), ["index", "differential_weight"],
                list(zip(range(len(vals)), vals)))


if __name__ == "__main__":
    print("device figures ->", OUT)
    for fn in [fig_ltp, fig_temperature, fig_retention, fig_transfer, fig_memwindow, fig_diffmap]:
        fn(); print("  ok:", fn.__name__)
