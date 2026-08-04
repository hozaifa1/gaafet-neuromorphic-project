"""Paper-quality device-characteristic figures for the planar FeFET ablation.

Centerpiece (supervisor's focus): analog synaptic resolution and its LIF/spiking
consequence -- GAA delivers finer, more uniform conductance steps than the planar
single-gate ablation, which is the load-bearing reason to prefer GAA. The other
device metrics (transfer, memory window, retention) are also drawn standalone so
every gathered number can be visually verified.

Both devices are read on ONE width convention: current per micron of gate width
(planar Areafactor=1 -> per um of its single gate; GAA per um of gate perimeter,
W_eff=2(W+T_si)=90 nm).  The GAA side is defined in Device_Optimization/norm.py.

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
import sys
sys.path.insert(0, str(HERE.parent / "Device_Optimization"))
import norm                      # the one width convention
CORR = norm.CORR_PLANAR_COMPARE  # = 1.0; GAA CSVs are already per-um-of-gate-width
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


# --------------------------------- 4c. ACTUAL SPIKE-TRAIN WAVEFORM (vs time)
def _lif_waveform(base, node, W, corr):
    """Extract the temporal LIF waveform from a run's transient legs:
       spikes[(t_start,t_end) us], mem_t[us], mem_i[uA/um], rest, Vhi. Times shifted to t0."""
    from planar import parse_plt, col

    def leg(tag):
        names, a = parse_plt(Path(base) / f"{tag}_{node}_des.plt")
        return (a[:, 0], a[:, col(names, "gate_contact OuterVoltage")],
                np.abs(a[:, col(names, "drain_contact TotalCurrent")]) * 1e6 / W * corr)
    tb, _, idb = leg("baseline_pre")
    t0 = tb[0]; rest = idb[-1]
    spikes, mem_t, mem_i = [], [(tb[-1] - t0) * 1e6], [rest]
    Vhi = 0.0
    for k in range(1, 16):
        tw, vw, _ = leg(f"p{k:02d}_write")
        spikes.append(((tw[0] - t0) * 1e6, (tw[-1] - t0) * 1e6)); Vhi = max(Vhi, float(np.max(vw)))
        tr, _, ir = leg(f"p{k:02d}_read")
        mem_t.append((tr[-1] - t0) * 1e6); mem_i.append(ir[-1])
    return spikes, mem_t, mem_i, rest, Vhi


# Raw-.plt readers: planar runs Areafactor=1 (already per um); the GAA .plt needs the
# full norm.py conversion (W_eff = gate perimeter, Areafactor 0.071 -> 0.045).
_PLN = dict(base=HERE / "outputs" / "lifret2", node="lifret2_v023", W=1.0, corr=1.0, vpgm=2.3)
_GAA = dict(base=HERE.parent / "Device_Optimization" / "outputs" / "t8_ltp",
            node="t8_ltp_v020", W=norm.W_EFF_UM, corr=norm.CORR, vpgm=2.0)


def _spike_panel(dev, color, title, fname):
    """The device is a NON-VOLATILE ANALOG SYNAPSE, not a self-resetting neuron: each spike
    potentiates the retained conductance (= SNN weight); the state holds between and after
    spikes (no leak); reset needs an explicit erase pulse. Finer conductance resolution ->
    better LIF-SNN weight fidelity (the load-bearing GAA advantage)."""
    sp, mt, mi, rest, Vhi = _lif_waveform(dev["base"], dev["node"], dev["W"], dev["corr"])
    fig, (axv, axm) = plt.subplots(2, 1, figsize=(8.2, 6.4), sharex=True,
                                   gridspec_kw={"height_ratios": [1, 1.6]})
    for (ts, te) in sp:
        axv.plot([ts, ts, te, te], [0, Vhi, Vhi, 0], color=color, lw=1.8)
    axv.axhline(0, color="0.6", lw=0.8)
    axv.set_ylabel("Input spike\n$V_G$ (V)"); axv.set_ylim(-0.3, Vhi * 1.3)
    axv.set_title(title)
    axv.text(0.01, 0.9, f"15 potentiating spikes  (+{dev['vpgm']} V, 0.3 µs each)",
             transform=axv.transAxes, va="top", fontsize=10, color=color)
    axm.semilogy(mt, mi, "-s", color=color, ms=6, label="synaptic weight ($I_{read}$ @ $V_G$=0)")
    axm.axhline(rest, color="0.45", ls=":", lw=1.5, label="erased (reset) level")
    axm.set_xlabel("Time (µs)"); axm.set_ylabel("Synaptic weight  $I_{read}$ ($\\mu$A/$\\mu$m)")
    axm.set_xlim(-0.2, mt[-1] * 1.02); axm.legend(loc="lower right", fontsize=9.5)
    axm.text(0.015, 0.97,
             "Non-volatile: weight holds between & after spikes (no leak).\n"
             "Saturates when the FE fully switches. Reset = explicit erase\n"
             f"pulse (−{3.5 if dev is _PLN else 2.0} V), not automatic.",
             transform=axm.transAxes, va="top", ha="left", fontsize=9,
             bbox=dict(boxstyle="round", fc="#f4f4f4", ec="0.6"))
    fig.tight_layout(); fig.savefig(PLOTS / fname); plt.close(fig)
    print(f"  {fname}")


def fig_spike_train():
    _spike_panel(_PLN, PLN_C, "Planar FeFET — non-volatile analog synapse potentiation",
                 "fig_spike_train_planar.png")
    _spike_panel(_GAA, GAA_C, "GAA FeFET — non-volatile analog synapse potentiation",
                 "fig_spike_train_gaa.png")
    _fig_spike_compare()


def _fig_spike_compare():
    """Both devices' conductance (synaptic weight) trajectories on one time axis under the
    15-spike potentiating train. GAA climbs in finer, more graded steps; planar is flatter
    then leaps -- the analog-resolution difference that sets the SNN weight fidelity."""
    spg, mtg, mig, restg, Vhg = _lif_waveform(_GAA["base"], _GAA["node"], _GAA["W"], _GAA["corr"])
    spp, mtp, mip, restp, Vhp = _lif_waveform(_PLN["base"], _PLN["node"], _PLN["W"], _PLN["corr"])
    fig, (axv, axm) = plt.subplots(2, 1, figsize=(8.4, 6.4), sharex=True,
                                   gridspec_kw={"height_ratios": [0.7, 2.0]})
    for (ts, te) in spp:
        axv.plot([ts, ts, te, te], [0, 1, 1, 0], color="0.35", lw=1.6)
    axv.set_ylabel("Input\nspikes"); axv.set_yticks([]); axv.set_ylim(-0.2, 1.35)
    axv.set_title("Analog synapse potentiation under a spike train — GAA vs Planar")
    axv.text(0.01, 0.92, "15 potentiating spikes (0.3 µs each)", transform=axv.transAxes,
             va="top", fontsize=9.5, color="0.3")
    axm.semilogy(mtg, mig, "-o", color=GAA_C, label="GAA weight (finer, graded climb)")
    axm.semilogy(mtp, mip, "-s", color=PLN_C, label="Planar weight (flat then leaps)")
    axm.set_xlabel("Time (µs)"); axm.set_ylabel("Synaptic weight  $I_{read}$ ($\\mu$A/$\\mu$m)")
    axm.legend(loc="lower right", fontsize=9.5)
    axm.text(0.015, 0.97,
             "GAA passes through more resolvable conductance states\n"
             "$\\Rightarrow$ finer synaptic-weight resolution for the LIF-SNN.\n"
             "Both non-volatile (hold after the train); reset = erase.",
             transform=axm.transAxes, va="top", ha="left", fontsize=9.5,
             bbox=dict(boxstyle="round", fc="#eef4ff", ec="0.6"))
    fig.tight_layout(); fig.savefig(PLOTS / "fig_spike_train_compare.png"); plt.close(fig)
    print("  fig_spike_train_compare.png")


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
    fig_step_granularity()
    fig_spike_train()
    fig_retention()
    print(f"done. analog levels: GAA={ng}, planar={npl}")
