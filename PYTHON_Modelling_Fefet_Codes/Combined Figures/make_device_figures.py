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


def fig_retention():
    d = pd.read_csv(os.path.join(RAW, "leak_retention.csv"))
    t = d["t_us"].to_numpy(); g = d["G_uA_um"].to_numpy()
    fig, ax = fs.new_ax()
    ax.plot(t, g, "-o", color="#0b3d1e", mfc="#2e8b57", mec="black", ms=6, lw=2.3, mew=1.2)
    peak = g[np.argmax(g)]
    ax.axhline(peak, ls="--", color="gray", lw=1.6)
    ax.text(t[-1]*0.55, peak*0.9, f"drift {100*(g[-1]-peak)/peak:.1f}% @100µs",
            fontweight="bold", fontsize=11)
    fs.bold_labels(ax, "Time (µs)", "Conductance (µA/µm @ Vread)")
    fs.finish(fig, P("dev3_retention.png"))
    fs.save_csv(P("dev3_retention.csv"), ["t_us", "G_uA_um"], list(zip(t, g)))


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
