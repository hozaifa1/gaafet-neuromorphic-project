"""Analyze SimC v4 results: Vpulse sweep 1.5/2.0/2.5V, pw=1us, Vreset=-6V.
Generates publication-relevant plots from write-then-read LIF data.
Note: Directory names (n3(3V), n4(4V), n5(5V)) are from SWB — actual
Vpulse values are 1.5, 2.0, 2.5V respectively (verified from rise files)."""
import os
import re
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import AutoMinorLocator

# ── Config ──
BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "simC")
NODES = {
    "n3(3V)": {"tag": "n3", "Vpulse": 1.5},
    "n4(4V)": {"tag": "n4", "Vpulse": 2.0},
    "n5(5V)": {"tag": "n5", "Vpulse": 2.5},
}
N_PULSES = 10
VGS_READ = 0.20
VDS = 0.05
FIRE_RATIO = 2.0
SS_MVDEC = 61.0  # subthreshold slope mV/dec for dVth estimation
OUTDIR = os.path.dirname(os.path.abspath(__file__))

# ── PLT parser ──
def parse_plt(filepath):
    """Parse Sentaurus .plt file → dict of column arrays."""
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        text = f.read()
    # Extract dataset names
    ds_match = re.search(r'datasets\s*=\s*\[(.*?)\]', text, re.DOTALL)
    if not ds_match:
        return None
    names_raw = ds_match.group(1)
    names = re.findall(r'"([^"]+)"', names_raw)

    # Extract data block
    data_match = re.search(r'Data\s*\{(.*)\}', text, re.DOTALL)
    if not data_match:
        return None
    vals = [float(x) for x in data_match.group(1).split()]

    ncols = len(names)
    nrows = len(vals) // ncols
    if nrows == 0:
        return None
    arr = np.array(vals[:nrows * ncols]).reshape(nrows, ncols)
    return {n: arr[:, i] for i, n in enumerate(names)}


def get_steady_state(data):
    """Get last-point drain eCurrent and polarization-y from parsed data."""
    id_key = "drain_contact eCurrent"
    pol_key = "Pos(0,0.0145) Polarization/y"
    if data is None or id_key not in data:
        return None, None
    i_d = abs(data[id_key][-1])
    pol = data[pol_key][-1] if pol_key in data else None
    return i_d, pol


# ── Extract data for all nodes ──
results = {}
for dirname, info in NODES.items():
    tag = info["tag"]
    vp = info["Vpulse"]
    nodedir = os.path.join(BASE, dirname)

    # Baseline
    bl_file = os.path.join(nodedir, f"baseline_read_{tag}_des.plt")
    bl_data = parse_plt(bl_file)
    id_bl, pol_bl = get_steady_state(bl_data)

    # Per-pulse reads
    ids_read = []
    pols_read = []
    for p in range(1, N_PULSES + 1):
        rf = os.path.join(nodedir, f"p{p:02d}_read_{tag}_des.plt")
        rd = parse_plt(rf)
        i_d, pol = get_steady_state(rd)
        ids_read.append(i_d)
        pols_read.append(pol)

    # Post-reset
    pr_file = os.path.join(nodedir, f"postreset_read_{tag}_des.plt")
    pr_data = parse_plt(pr_file)
    id_pr, pol_pr = get_steady_state(pr_data)

    # Leak gap
    lg_file = os.path.join(nodedir, f"leak_gap_{tag}_des.plt")
    lg_data = parse_plt(lg_file)
    leak_id_key = "drain_contact eCurrent"
    leak_pol_key = "Pos(0,0.0145) Polarization/y"
    leak_time = lg_data["time"] if lg_data else None
    leak_id = np.abs(lg_data[leak_id_key]) if lg_data and leak_id_key in lg_data else None
    leak_pol = lg_data[leak_pol_key] if lg_data and leak_pol_key in lg_data else None

    results[dirname] = {
        "Vpulse": vp,
        "tag": tag,
        "id_baseline": id_bl,
        "pol_baseline": pol_bl,
        "ids_read": np.array(ids_read),
        "pols_read": np.array(pols_read),
        "id_postreset": id_pr,
        "pol_postreset": pol_pr,
        "leak_time": leak_time,
        "leak_id": leak_id,
        "leak_pol": leak_pol,
    }

# ── Print summary table ──
print("=" * 80)
print("SimC v4 Results Summary")
print("=" * 80)
print(f"{'Node':<10} {'Vpulse':>7} {'ID_base':>12} {'ID_P1':>12} {'P1_ratio':>10}"
      f" {'ID_P10':>12} {'P10_ratio':>10} {'ID_reset':>12} {'Reset%':>8}")
print("-" * 80)
for dirname, r in results.items():
    bl = r["id_baseline"]
    p1 = r["ids_read"][0]
    p10 = r["ids_read"][9]
    pr = r["id_postreset"]
    p1_ratio = p1 / bl if bl else 0
    p10_ratio = p10 / bl if bl else 0
    # Reset% = how much of (p10 - baseline) was reversed
    reset_pct = (1.0 - (pr - bl) / (p10 - bl)) * 100 if (p10 - bl) != 0 else 0
    print(f"{dirname:<10} {r['Vpulse']:>7.1f} {bl:>12.4e} {p1:>12.4e} {p1_ratio:>10.3f}"
          f" {p10:>12.4e} {p10_ratio:>10.3f} {pr:>12.4e} {reset_pct:>7.1f}%")
print()

# ── Styling ──
plt.rcParams.update({
    "font.size": 11,
    "axes.labelsize": 13,
    "axes.titlesize": 13,
    "legend.fontsize": 10,
    "figure.dpi": 150,
    "savefig.dpi": 300,
})
COLORS = {"n3(3V)": "#1f77b4", "n4(4V)": "#ff7f0e", "n5(5V)": "#2ca02c"}
LABELS = {"n3(3V)": r"$V_{pulse}$=1.5V", "n4(4V)": r"$V_{pulse}$=2.0V", "n5(5V)": r"$V_{pulse}$=2.5V"}

pulses = np.arange(1, N_PULSES + 1)

# =====================================================================
# PLOT 1: Integration & Fire Detection (ID_read/ID_baseline vs pulse #)
# =====================================================================
fig1, ax1 = plt.subplots(figsize=(7, 5))
for dirname, r in results.items():
    ratios = r["ids_read"] / r["id_baseline"]
    ax1.plot(pulses, ratios, "o-", color=COLORS[dirname], label=LABELS[dirname],
             markersize=6, linewidth=2)
ax1.axhline(y=FIRE_RATIO, color="red", linestyle="--", linewidth=1.5,
            label=f"Fire threshold ({FIRE_RATIO}×)")
ax1.set_xlabel("Pulse Number")
ax1.set_ylabel(r"$I_{D,read} / I_{D,baseline}$")
ax1.set_title(f"Integration: Read Current Ratio vs Pulse Number\n"
              f"(pw=1µs, $V_{{GS,read}}$={VGS_READ}V, $V_{{reset}}$=−6V)")
ax1.set_xlim(0.5, N_PULSES + 0.5)
ax1.set_xticks(pulses)
ax1.legend(loc="best")
ax1.grid(True, alpha=0.3)
ax1.xaxis.set_minor_locator(AutoMinorLocator())
ax1.yaxis.set_minor_locator(AutoMinorLocator())
fig1.savefig(os.path.join(OUTDIR, "simC_v4_fig1_integration_fire.png"))
print("Saved: simC_v4_fig1_integration_fire.png")

# =====================================================================
# PLOT 2: Polarization Evolution vs Pulse Number
# =====================================================================
fig2, ax2 = plt.subplots(figsize=(7, 5))
for dirname, r in results.items():
    pols = r["pols_read"] * 1e6  # convert to µC/cm²
    ax2.plot(pulses, pols, "s-", color=COLORS[dirname], label=LABELS[dirname],
             markersize=6, linewidth=2)
    # Add baseline as dashed
    ax2.axhline(y=r["pol_baseline"] * 1e6, color=COLORS[dirname],
                linestyle=":", alpha=0.5, linewidth=1)
ax2.set_xlabel("Pulse Number")
ax2.set_ylabel(r"Polarization $P_y$ (µC/cm²)")
ax2.set_title(f"Ferroelectric Polarization After Each Write Pulse\n"
              f"(pw=1µs, $\\tau_E$=1µs)")
ax2.set_xlim(0.5, N_PULSES + 0.5)
ax2.set_xticks(pulses)
ax2.legend(loc="best")
ax2.grid(True, alpha=0.3)
fig2.savefig(os.path.join(OUTDIR, "simC_v4_fig2_polarization.png"))
print("Saved: simC_v4_fig2_polarization.png")

# =====================================================================
# PLOT 3: ΔVth Estimation (from current ratio using SS)
# =====================================================================
fig3, ax3 = plt.subplots(figsize=(7, 5))
for dirname, r in results.items():
    ratios = r["ids_read"] / r["id_baseline"]
    # ΔVth = -SS * log10(ratio)  (negative because higher current = lower Vth)
    dvth = -SS_MVDEC * np.log10(ratios)  # in mV
    ax3.plot(pulses, dvth, "^-", color=COLORS[dirname], label=LABELS[dirname],
             markersize=6, linewidth=2)
ax3.set_xlabel("Pulse Number")
ax3.set_ylabel(r"$\Delta V_{th}$ (mV)")
ax3.set_title(f"Threshold Voltage Shift vs Pulse Number\n"
              f"(Estimated from SS≈{SS_MVDEC} mV/dec)")
ax3.set_xlim(0.5, N_PULSES + 0.5)
ax3.set_xticks(pulses)
ax3.legend(loc="best")
ax3.grid(True, alpha=0.3)
fig3.savefig(os.path.join(OUTDIR, "simC_v4_fig3_dvth.png"))
print("Saved: simC_v4_fig3_dvth.png")

# =====================================================================
# PLOT 4: Reset Completeness (bar chart)
# =====================================================================
fig4, (ax4a, ax4b) = plt.subplots(1, 2, figsize=(12, 5))

# 4a: Current comparison bars
x_pos = np.arange(len(NODES))
width = 0.25
labels_short = []
id_bl_vals, id_p10_vals, id_pr_vals = [], [], []
for dirname, r in results.items():
    labels_short.append(f"{r['Vpulse']:.1f}V")
    id_bl_vals.append(r["id_baseline"] * 1e6)  # µA
    id_p10_vals.append(r["ids_read"][9] * 1e6)
    id_pr_vals.append(r["id_postreset"] * 1e6)

ax4a.bar(x_pos - width, id_bl_vals, width, label="Baseline", color="#4CAF50", alpha=0.8)
ax4a.bar(x_pos, id_p10_vals, width, label="After P10", color="#F44336", alpha=0.8)
ax4a.bar(x_pos + width, id_pr_vals, width, label="Post-Reset", color="#2196F3", alpha=0.8)
ax4a.set_xlabel(r"$V_{pulse}$")
ax4a.set_ylabel(r"$I_D$ (µA)")
ax4a.set_title("Current: Baseline vs P10 vs Post-Reset")
ax4a.set_xticks(x_pos)
ax4a.set_xticklabels(labels_short)
ax4a.legend()
ax4a.grid(axis="y", alpha=0.3)

# 4b: Reset percentage
reset_pcts = []
for dirname, r in results.items():
    bl = r["id_baseline"]
    p10 = r["ids_read"][9]
    pr = r["id_postreset"]
    pct = (1.0 - (pr - bl) / (p10 - bl)) * 100
    reset_pcts.append(pct)

bars = ax4b.bar(x_pos, reset_pcts, 0.5, color=[COLORS[d] for d in NODES], alpha=0.8)
ax4b.set_xlabel(r"$V_{pulse}$")
ax4b.set_ylabel("Reset Completeness (%)")
ax4b.set_title(f"Reset Completeness ($V_{{reset}}$=−6V)")
ax4b.set_xticks(x_pos)
ax4b.set_xticklabels(labels_short)
ax4b.set_ylim(0, 110)
ax4b.axhline(y=100, color="gray", linestyle="--", alpha=0.5)
for bar, pct in zip(bars, reset_pcts):
    ax4b.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 2,
              f"{pct:.1f}%", ha="center", va="bottom", fontsize=10, fontweight="bold")
ax4b.grid(axis="y", alpha=0.3)

fig4.tight_layout()
fig4.savefig(os.path.join(OUTDIR, "simC_v4_fig4_reset.png"))
print("Saved: simC_v4_fig4_reset.png")

# =====================================================================
# PLOT 5: Leak Gap Analysis (current decay during 5µs gap after P5)
# =====================================================================
fig5, (ax5a, ax5b) = plt.subplots(1, 2, figsize=(12, 5))
for dirname, r in results.items():
    if r["leak_time"] is not None and r["leak_id"] is not None:
        t_rel = (r["leak_time"] - r["leak_time"][0]) * 1e6  # relative µs
        # Current
        ax5a.plot(t_rel, r["leak_id"] * 1e6, "-", color=COLORS[dirname],
                  label=LABELS[dirname], linewidth=1.5)
        # Polarization
        if r["leak_pol"] is not None:
            ax5b.plot(t_rel, r["leak_pol"] * 1e6, "-", color=COLORS[dirname],
                      label=LABELS[dirname], linewidth=1.5)

ax5a.set_xlabel("Time (µs)")
ax5a.set_ylabel(r"$|I_D|$ (µA)")
ax5a.set_title("Leak Gap: Drain Current Decay")
ax5a.legend()
ax5a.grid(True, alpha=0.3)

ax5b.set_xlabel("Time (µs)")
ax5b.set_ylabel(r"Polarization $P_y$ (µC/cm²)")
ax5b.set_title("Leak Gap: Polarization Stability")
ax5b.legend()
ax5b.grid(True, alpha=0.3)

fig5.tight_layout()
fig5.savefig(os.path.join(OUTDIR, "simC_v4_fig5_leak.png"))
print("Saved: simC_v4_fig5_leak.png")

# =====================================================================
# PLOT 6: Combined Summary — Integration + Polarization + Reset
# =====================================================================
fig6, axes = plt.subplots(2, 2, figsize=(12, 10))

# 6a: Integration curve
ax = axes[0, 0]
for dirname, r in results.items():
    ratios = r["ids_read"] / r["id_baseline"]
    ax.plot(pulses, ratios, "o-", color=COLORS[dirname], label=LABELS[dirname],
            markersize=5, linewidth=1.8)
ax.axhline(y=FIRE_RATIO, color="red", linestyle="--", linewidth=1.2, alpha=0.7)
ax.set_xlabel("Pulse #")
ax.set_ylabel(r"$I_{read}/I_{base}$")
ax.set_title("(a) Integration")
ax.set_xticks(pulses)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# 6b: Polarization
ax = axes[0, 1]
for dirname, r in results.items():
    pols = r["pols_read"] * 1e6
    ax.plot(pulses, pols, "s-", color=COLORS[dirname], label=LABELS[dirname],
            markersize=5, linewidth=1.8)
ax.set_xlabel("Pulse #")
ax.set_ylabel(r"$P_y$ (µC/cm²)")
ax.set_title("(b) Polarization")
ax.set_xticks(pulses)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# 6c: ΔVth
ax = axes[1, 0]
for dirname, r in results.items():
    ratios = r["ids_read"] / r["id_baseline"]
    dvth = -SS_MVDEC * np.log10(ratios)
    ax.plot(pulses, dvth, "^-", color=COLORS[dirname], label=LABELS[dirname],
            markersize=5, linewidth=1.8)
ax.set_xlabel("Pulse #")
ax.set_ylabel(r"$\Delta V_{th}$ (mV)")
ax.set_title(r"(c) $\Delta V_{th}$ (SS≈61 mV/dec)")
ax.set_xticks(pulses)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# 6d: Reset
ax = axes[1, 1]
for i, (dirname, r) in enumerate(results.items()):
    bl = r["id_baseline"]
    p10 = r["ids_read"][9]
    pr = r["id_postreset"]
    pct = (1.0 - (pr - bl) / (p10 - bl)) * 100
    bar = ax.bar(i, pct, 0.6, color=COLORS[dirname], alpha=0.8)
    ax.text(i, pct + 1, f"{pct:.1f}%", ha="center", fontsize=10, fontweight="bold")
ax.set_xlabel(r"$V_{pulse}$")
ax.set_ylabel("Reset %")
ax.set_title("(d) Reset Completeness")
ax.set_xticks(range(len(NODES)))
ax.set_xticklabels([f"{r['Vpulse']:.1f}V" for r in results.values()])
ax.set_ylim(0, 115)
ax.grid(axis="y", alpha=0.3)

fig6.suptitle("SimC v4: Write-Then-Read LIF — Vpulse Sweep (pw=1µs, τ_E=1µs)",
              fontsize=14, fontweight="bold", y=1.01)
fig6.tight_layout()
fig6.savefig(os.path.join(OUTDIR, "simC_v4_fig6_summary.png"))
print("Saved: simC_v4_fig6_summary.png")

plt.close("all")
print("\nAll plots generated successfully.")
