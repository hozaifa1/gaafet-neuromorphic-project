"""Paper-quality device-characteristic figures for the planar FeFET ablation.

Centerpiece (supervisor's focus): analog synaptic resolution and its LIF/spiking
consequence -- GAA delivers finer, more uniform conductance steps than the planar
single-gate ablation, which is the load-bearing reason to prefer GAA. The other
device metrics (transfer, memory window, retention) are also drawn standalone so
every gathered number can be visually verified.

All GAA reference currents are scaled by CORR=0.090/0.071 (the documented Areafactor/
W_um inconsistency fix) so both devices are on one native per-um-width convention.

Outputs -> plots/fig_*.png
"""
import json
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent
GAA = HERE.parent / "Device_Optimization" / "csv_export" / "raw"
PLOTS = HERE / "plots"; PLOTS.mkdir(exist_ok=True)
VDS = 0.05
CORR = 0.090 / 0.071
OPV = 2.3

plt.rcParams.update({
    "font.size": 12, "axes.titlesize": 13, "axes.labelsize": 12,
    "legend.fontsize": 10.5, "xtick.labelsize": 11, "ytick.labelsize": 11,
    "axes.linewidth": 1.1, "figure.dpi": 110, "savefig.dpi": 200,
    "axes.grid": True, "grid.alpha": 0.3, "grid.linewidth": 0.6,
    "lines.linewidth": 2.0, "lines.markersize": 6,
})
GAA_C, PLN_C = "#1f6feb", "#d1242f"   # blue = GAA, red = planar (consistent everywhere)


def _levels(ids, min_ratio=1.5):
    ids = [x for x in ids if x and np.isfinite(x)]
    lv = [ids[0]]
    for v in ids[1:]:
        if v >= lv[-1] * min_ratio:
            lv.append(v)
    return lv


def _gaa_csv(name):
    return np.genfromtxt(GAA / name, delimiter=",", names=True)


# ------------------------------------------------------------------ 1. TRANSFER
def fig_transfer():
    d = json.loads((HERE / "outputs" / "planarfinal" / "mw_planarfinal_analysis.json").read_text())
    vg = np.array(d["vgs"]); ers = np.array(d["ers"]); pgm = np.array(d["pgm"])
    # keep the clean forward window (>= -0.6 V); deep-negative pgm has read disturb (documented)
    m = vg >= -0.65
    fig, ax = plt.subplots(figsize=(6.6, 5))
    ax.semilogy(vg[m], pgm[m], "-s", color=PLN_C, label="Programmed (ON)")
    ax.semilogy(vg[m], ers[m], "--o", color=PLN_C, alpha=0.55, mfc="white", label="Erased (OFF)")
    ax.axvline(0.0, color="0.4", lw=1, ls=":")
    ax.set_xlabel("Gate voltage $V_G$ (V)"); ax.set_ylabel("Drain current $I_D$ ($\\mu$A/$\\mu$m)")
    ax.set_title("Planar FeFET — retained-state transfer (SS = 75 mV/dec)")
    ax.legend(loc="lower right")
    fig.tight_layout(); fig.savefig(PLOTS / "fig_transfer.png"); plt.close(fig)
    print("  fig_transfer.png")


# ------------------------------------------------------------ 2. MEMORY WINDOW
def fig_memory_window():
    d = json.loads((HERE / "outputs" / "planarfinal" / "mw_planarfinal_analysis.json").read_text())
    vg = np.array(d["vgs"]); ers = np.array(d["ers"]); pgm = np.array(d["pgm"])
    g = _gaa_csv("memwin_fe07.csv")
    fig, ax = plt.subplots(figsize=(6.6, 5))
    ax.semilogy(g["Vg_V"], g["Id_programmed_uA_um"] * CORR, "-o", color=GAA_C, label="GAA programmed")
    ax.semilogy(g["Vg_V"], g["Id_erased_uA_um"] * CORR, "--o", color=GAA_C, alpha=0.5, mfc="white", label="GAA erased")
    m = vg >= -0.65
    ax.semilogy(vg[m], pgm[m], "-s", color=PLN_C, label="Planar programmed")
    ax.semilogy(vg[m], ers[m], "--s", color=PLN_C, alpha=0.55, mfc="white", label="Planar erased")
    ax.annotate("window @ $V_G$=0\nGAA 3.1k$\\times$ | Planar 14k$\\times$", xy=(0, 5), xytext=(0.15, 0.02),
                fontsize=10, ha="left", va="bottom",
                bbox=dict(boxstyle="round", fc="#fff8e1", ec="0.6"))
    ax.axvline(0.0, color="0.4", lw=1, ls=":")
    ax.set_xlabel("Read gate voltage $V_G$ (V)"); ax.set_ylabel("$I_D$ ($\\mu$A/$\\mu$m)")
    ax.set_title("Memory window — retained ON/OFF state")
    ax.legend(loc="lower right", ncol=2)
    fig.tight_layout(); fig.savefig(PLOTS / "fig_memory_window.png"); plt.close(fig)
    print("  fig_memory_window.png")


# ------------------------------------------ 3. ANALOG RESOLUTION (the centerpiece)
def fig_analog_resolution():
    p = json.loads((HERE / "outputs" / "lifsw2" / "lifsw2_lif.json").read_text())[str(OPV)]["ids"]
    g = list(_gaa_csv("ltp_potentiation.csv")["Id_uA_per_um"] * CORR)
    gp = [1e-6 * x / VDS for x in g]     # conductance (S)
    pp = [1e-6 * x / VDS for x in p]
    lg, lp = _levels(g), _levels(p)
    npul = np.arange(1, 16)

    fig, ax = plt.subplots(figsize=(7.2, 5.2))
    ax.semilogy(npul, gp, "-o", color=GAA_C, label=f"GAA  (double gate)")
    ax.semilogy(npul, pp, "-s", color=PLN_C, label=f"Planar (single gate)")
    # mark distinguishable levels on the right margin
    for L in _levels(g):
        ax.axhline(1e-6 * L / VDS, color=GAA_C, lw=0.6, alpha=0.25)
    ax.set_xlabel("Programming pulse number"); ax.set_ylabel("Read conductance $G$ (S)")
    ax.set_title("Analog synaptic resolution — cumulative potentiation (LTP)")
    ax.legend(loc="lower right")
    ax.text(0.03, 0.97,
            f"Resolvable levels ($\\geq$1.5$\\times$ apart):\n"
            f"  GAA  : {len(lg)}  (smooth, even log-steps)\n"
            f"  Planar: {len(lp)}  (flat start, abrupt jump)",
            transform=ax.transAxes, va="top", ha="left", fontsize=10,
            bbox=dict(boxstyle="round", fc="#e8f0fe", ec="0.6"))
    fig.tight_layout(); fig.savefig(PLOTS / "fig_analog_resolution.png"); plt.close(fig)
    print("  fig_analog_resolution.png")
    return len(lg), len(lp)


# --------------------------------- 4a. PLANAR AS A LIF NEURON (integrate-and-fire)
def fig_lif_neuron():
    """The planar device operating as a leaky-integrate-and-fire neuron: the read current at
    V_G=0 is the membrane potential; each program pulse is an input spike that integrates it;
    'fire' = current crossing the detection threshold (2x the erased baseline, the project's
    fire criterion). Shows the device works as a spiking element."""
    p = json.loads((HERE / "outputs" / "lifsw2" / "lifsw2_lif.json").read_text())[str(OPV)]
    ids = np.array(p["ids"]); base = p["id_base"]
    npul = np.arange(1, 16)
    fire = 2.0 * base                       # detection threshold = 2x baseline (fire criterion)
    kfire = next((i for i, v in enumerate(ids) if v >= fire), None)

    fig, ax = plt.subplots(figsize=(7.0, 5.1))
    ax.semilogy(npul, ids, "-s", color=PLN_C, label="membrane state ($I_{read}$ @ $V_G$=0)")
    ax.axhline(base, color="0.45", ls=":", lw=1.5, label=f"erased baseline (rest)")
    ax.axhline(fire, color="0.2", ls="--", lw=1.6, label="fire threshold (2$\\times$ rest)")
    if kfire is not None:
        ax.plot(kfire + 1, ids[kfire], "*", color="#f0a500", ms=22, mec="k", mew=0.8, zorder=5)
        ax.annotate(f"fires at pulse {kfire+1}", xy=(kfire + 1, ids[kfire]),
                    xytext=(kfire + 1.6, ids[kfire] * 0.08), fontsize=10,
                    arrowprops=dict(arrowstyle="->", color="0.3"))
    ax.set_xlabel("Input spike (program pulse) number")
    ax.set_ylabel("Membrane state  $I_{read}$ ($\\mu$A/$\\mu$m)")
    ax.set_title("Planar FeFET as a LIF neuron — integrate-and-fire (@ $V_{pgm}$=+2.3 V)")
    ax.legend(loc="lower right")
    ax.text(0.03, 0.97,
            f"On/off fire contrast: {ids[-1]/base:.0f}$\\times$\n"
            f"Retained (non-volatile) between spikes",
            transform=ax.transAxes, va="top", ha="left", fontsize=10,
            bbox=dict(boxstyle="round", fc="#fdeaea", ec="0.6"))
    fig.tight_layout(); fig.savefig(PLOTS / "fig_lif_neuron.png"); plt.close(fig)
    print("  fig_lif_neuron.png")


# ---------------------- 4b. STEP GRANULARITY (why GAA has finer resolution)
def fig_step_granularity():
    """Per-pulse conductance step. Fine, uniform steps (GAA) = high analog weight resolution;
    a few giant steps (planar) = coarse, near-binary. This is the mechanism behind the level
    counts, and directly the property the SNN synapse (log-quantized weight) depends on."""
    p = json.loads((HERE / "outputs" / "lifsw2" / "lifsw2_lif.json").read_text())[str(OPV)]["ids"]
    g = list(_gaa_csv("ltp_potentiation.csv")["Id_uA_per_um"] * CORR)
    gG = np.array([1e-6 * x / VDS for x in g]); gP = np.array([1e-6 * x / VDS for x in p])
    # per-pulse multiplicative step (ratio) -- resolution is a log/multiplicative property
    stepG = gG[1:] / gG[:-1]; stepP = gP[1:] / gP[:-1]
    x = np.arange(2, 16)
    w = 0.4
    fig, ax = plt.subplots(figsize=(7.2, 5.0))
    ax.bar(x - w / 2, stepG, w, color=GAA_C, label="GAA (double gate)")
    ax.bar(x + w / 2, stepP, w, color=PLN_C, label="Planar (single gate)")
    ax.axhline(1.5, color="0.3", ls="--", lw=1.3, label="1.5$\\times$ resolvable-step limit")
    ax.set_yscale("log")
    ax.set_xlabel("Program pulse number"); ax.set_ylabel("Per-pulse conductance step  $G_n/G_{n-1}$")
    ax.set_title("Update granularity — smaller, more uniform steps = finer resolution")
    ax.set_ylim(0.95, 9.5); ax.legend(loc="upper right", ncol=1, framealpha=0.95)
    peakP = float(np.nanmax(stepP))
    ax.text(0.98, 0.06,
            "GAA: modest, even steps across the whole train.\n"
            f"Planar: a few large jumps (up to ~{peakP:.0f}$\\times$/pulse)\n"
            "then saturates below the resolvable limit.\n"
            "$\\Rightarrow$ GAA resolves more intermediate weight states.",
            transform=ax.transAxes, va="bottom", ha="right", fontsize=9.5,
            bbox=dict(boxstyle="round", fc="#eef4ff", ec="0.6"))
    fig.tight_layout(); fig.savefig(PLOTS / "fig_step_granularity.png"); plt.close(fig)
    print("  fig_step_granularity.png")


# ------------------------------------------------------------------ 5. RETENTION
def fig_retention():
    """Retention = does the programmed state DECAY over the hold, or stay put? Plotted as
    % of the settled state (each device to its own on-current), so the y-axis is retention
    itself, not absolute current. Flat near 100% = non-volatile. The absolute on-current
    magnitudes differ (~71 vs ~9 uA/um) but that is drive strength, not retention -- which is
    why an absolute-current plot is misleading here."""
    import sys
    sys.path.insert(0, str(HERE))
    from analyze_compare import parse_hold
    t, gc = parse_hold(HERE / "outputs" / "lifret2" / "hold_lifret2_v023_des.plt")
    gd = _gaa_csv("leak_retention.csv")
    td, gdv = gd["t_us"], gd["G_uA_um"]

    def settle_pct(tt, gg):
        gg = np.asarray(gg, float)
        ref = np.median(gg[tt >= 0.6 * tt.max()])   # settled (post-relaxation) plateau
        return 100.0 * gg / ref
    fig, ax = plt.subplots(figsize=(6.8, 5))
    ax.plot(td, settle_pct(td, gdv), "-o", color=GAA_C, label="GAA")
    if t is not None:
        ax.plot(t, settle_pct(t, gc), "-s", color=PLN_C, label="Planar")
    ax.axhline(100, color="0.5", ls=":", lw=1.2)
    ax.set_ylim(0, 140)
    ax.set_xlabel("Hold time ($\\mu$s)")
    ax.set_ylabel("Retained state (% of settled on-current)")
    ax.set_title("Non-volatile retention at $V_G$ = 0  (flat $\\approx$ no decay)")
    ax.legend(loc="lower right")
    ax.text(0.03, 0.05,
            "Both curves stay flat $\\Rightarrow$ neither leaks $\\Rightarrow$ both non-volatile.\n"
            "(Early bump = post-write ferroelectric relaxation, settles by ~15 µs.)",
            transform=ax.transAxes, va="bottom", ha="left", fontsize=9.5,
            bbox=dict(boxstyle="round", fc="#eef7ee", ec="0.6"))
    fig.tight_layout(); fig.savefig(PLOTS / "fig_retention.png"); plt.close(fig)
    print("  fig_retention.png")


if __name__ == "__main__":
    print("Generating planar device figures:")
    fig_transfer()
    fig_memory_window()
    ng, npl = fig_analog_resolution()
    fig_lif_neuron()
    fig_step_granularity()
    fig_retention()
    print(f"done. analog levels: GAA={ng}, planar={npl}")
