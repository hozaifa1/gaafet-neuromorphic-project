"""Analyze SimC v6 results: Vpulse sweep 5/6/7V, pw=100ns, Vreset=-5V, N=30.
Generates publication-relevant plots from write-then-read LIF data.
Key achievement from v6: FIRE CONFIRMED at 6V and 7V.
"""
import os
import re
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import AutoMinorLocator

# ── Config ──
BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "simC")
NODES = {
    "n3(5V)": {"tag": "n3", "Vpulse": 5.0},
    "n4(6V)": {"tag": "n4", "Vpulse": 6.0},
    "n5(7V)": {"tag": "n5", "Vpulse": 7.0},
}
N_PULSES = 30
LEAK_AFTER = 15
VGS_READ = 0.20
VDS = 0.05
VRESET = -5.0
PW_NS = 100  # pulse width in ns
TAU_E_US = 1.0  # relaxation time in µs
FIRE_RATIO = 2.0
SS_MVDEC = 61.0  # subthreshold slope mV/dec for dVth estimation
OUTDIR = os.path.dirname(os.path.abspath(__file__))

# ── PLT parser ──
def parse_plt(filepath):
    """Parse Sentaurus .plt file -> dict of column arrays."""
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        text = f.read()
    ds_match = re.search(r'datasets\s*=\s*\[(.*?)\]', text, re.DOTALL)
    if not ds_match:
        return None
    names_raw = ds_match.group(1)
    names = re.findall(r'"([^"]+)"', names_raw)

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
print("=" * 100)
print("SimC v6 Results Summary  (pw=100ns, tau_E=1us, pw/tau_E=0.1)")
print("=" * 100)
print(f"{'Node':<10} {'Vpulse':>7} {'ID_base':>12} {'ID_P1':>12} {'P1_ratio':>10}"
      f" {'ID_P15':>12} {'P15_rat':>8} {'ID_P30':>12} {'P30_rat':>8}")
print("-" * 100)
for dirname, r in results.items():
    bl = r["id_baseline"]
    p1 = r["ids_read"][0]
    p15 = r["ids_read"][14]
    p30 = r["ids_read"][29]
    print(f"{dirname:<10} {r['Vpulse']:>7.1f} {bl:>12.4e} {p1:>12.4e} {p1/bl:>10.4f}"
          f" {p15:>12.4e} {p15/bl:>8.4f} {p30:>12.4e} {p30/bl:>8.4f}")

print()
print(f"{'Node':<10} {'ID_reset':>12} {'Reset%':>8} {'Fire?':>8} {'FirePulse':>10} {'MaxRatio':>10}")
print("-" * 70)
for dirname, r in results.items():
    bl = r["id_baseline"]
    p30 = r["ids_read"][29]
    pr = r["id_postreset"]
    reset_pct = (1.0 - (pr - bl) / (p30 - bl)) * 100 if (p30 - bl) != 0 else 0
    # Check fire
    ratios = r["ids_read"] / bl
    max_ratio = np.max(ratios)
    fire_idx = np.where(ratios >= FIRE_RATIO)[0]
    fire_str = "No"
    fire_pulse = "-"
    if len(fire_idx) > 0:
        fire_str = "YES"
        fire_pulse = f"P{fire_idx[0]+1}"
    print(f"{dirname:<10} {pr:>12.4e} {reset_pct:>7.1f}% {fire_str:>8} {fire_pulse:>10} {max_ratio:>10.3f}x")

# Per-pulse incremental ratios
print()
print("Per-pulse incremental current ratios (ID_Pn / ID_P(n-1)):")
print("-" * 70)
for dirname, r in results.items():
    bl = r["id_baseline"]
    ids = r["ids_read"]
    prev = bl
    increments = []
    for i in range(N_PULSES):
        inc = ids[i] / prev if prev > 0 else 0
        increments.append(inc)
        prev = ids[i]
    inc_str = " ".join([f"{x:.4f}" for x in increments[:10]])
    inc_str2 = " ".join([f"{x:.4f}" for x in increments[10:15]])
    inc_str3 = " ".join([f"{x:.4f}" for x in increments[15:20]])
    inc_str4 = " ".join([f"{x:.4f}" for x in increments[20:]])
    print(f"  {r['Vpulse']:.0f}V P1-10:   {inc_str}")
    print(f"  {r['Vpulse']:.0f}V P11-15:  {inc_str2}")
    print(f"  {r['Vpulse']:.0f}V P16-20:  {inc_str3}")
    print(f"  {r['Vpulse']:.0f}V P21-30:  {inc_str4}")
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
COLORS = {"n3(5V)": "#1f77b4", "n4(6V)": "#ff7f0e", "n5(7V)": "#2ca02c"}
LABELS = {
    "n3(5V)": r"$V_{pulse}$=5.0V",
    "n4(6V)": r"$V_{pulse}$=6.0V (FIRE!)",
    "n5(7V)": r"$V_{pulse}$=7.0V (FIRE!)",
}

pulses = np.arange(1, N_PULSES + 1)

# =====================================================================
# PLOT 1: Integration & Fire Detection (ID_read/ID_baseline vs pulse #)
# =====================================================================
fig1, ax1 = plt.subplots(figsize=(10, 6))
for dirname, r in results.items():
    ratios = r["ids_read"] / r["id_baseline"]
    ax1.plot(pulses, ratios, "o-", color=COLORS[dirname], label=LABELS[dirname],
             markersize=5, linewidth=2)
    # Mark fire point if it occurs
    fire_idx = np.where(ratios >= FIRE_RATIO)[0]
    if len(fire_idx) > 0:
        idx = fire_idx[0]
        ax1.scatter([pulses[idx]], [ratios[idx]], color=COLORS[dirname], s=150, 
                   marker='*', zorder=5, edgecolors='black', linewidths=1)
ax1.axhline(y=FIRE_RATIO, color="red", linestyle="--", linewidth=1.5,
            label=f"Fire threshold ({FIRE_RATIO}×)")
ax1.axvline(x=LEAK_AFTER + 0.5, color="gray", linestyle=":", linewidth=1,
            alpha=0.5, label=f"Leak gap (after P{LEAK_AFTER})")
ax1.set_xlabel("Pulse Number")
ax1.set_ylabel(r"$I_{D,read} / I_{D,baseline}$")
ax1.set_title(f"Integration: Read Current Ratio vs Pulse Number\n"
              f"(pw={PW_NS}ns, $V_{{GS,read}}$={VGS_READ}V, "
              f"$V_{{reset}}$={VRESET}V, pw/$\\tau_E$=0.1)")
ax1.set_xlim(0.5, N_PULSES + 0.5)
ax1.set_xticks(range(1, N_PULSES + 1, 2))
ax1.legend(loc="upper left")
ax1.grid(True, alpha=0.3)
ax1.xaxis.set_minor_locator(AutoMinorLocator())
ax1.yaxis.set_minor_locator(AutoMinorLocator())
fig1.tight_layout()
fig1.savefig(os.path.join(OUTDIR, "simC_v6_fig1_integration_fire.png"))
print("Saved: simC_v6_fig1_integration_fire.png")

# =====================================================================
# PLOT 2: Polarization Evolution vs Pulse Number
# =====================================================================
fig2, ax2 = plt.subplots(figsize=(10, 6))
for dirname, r in results.items():
    pols = r["pols_read"] * 1e6  # convert to µC/cm²
    ax2.plot(pulses, pols, "s-", color=COLORS[dirname], label=LABELS[dirname],
             markersize=5, linewidth=2)
    ax2.axhline(y=r["pol_baseline"] * 1e6, color=COLORS[dirname],
                linestyle=":", alpha=0.5, linewidth=1)
ax2.axvline(x=LEAK_AFTER + 0.5, color="gray", linestyle=":", linewidth=1, alpha=0.5)
ax2.set_xlabel("Pulse Number")
ax2.set_ylabel(r"Polarization $P_y$ (µC/cm²)")
ax2.set_title(f"Ferroelectric Polarization After Each Write Pulse\n"
              f"(pw={PW_NS}ns, $\\tau_E$={TAU_E_US}µs)")
ax2.set_xlim(0.5, N_PULSES + 0.5)
ax2.set_xticks(range(1, N_PULSES + 1, 2))
ax2.legend(loc="best")
ax2.grid(True, alpha=0.3)
fig2.tight_layout()
fig2.savefig(os.path.join(OUTDIR, "simC_v6_fig2_polarization.png"))
print("Saved: simC_v6_fig2_polarization.png")

# =====================================================================
# PLOT 3: ΔVth Estimation (from current ratio using SS)
# =====================================================================
fig3, ax3 = plt.subplots(figsize=(10, 6))
for dirname, r in results.items():
    ratios = r["ids_read"] / r["id_baseline"]
    dvth = -SS_MVDEC * np.log10(ratios)  # in mV
    ax3.plot(pulses, dvth, "^-", color=COLORS[dirname], label=LABELS[dirname],
             markersize=5, linewidth=2)
ax3.axvline(x=LEAK_AFTER + 0.5, color="gray", linestyle=":", linewidth=1, alpha=0.5)
ax3.set_xlabel("Pulse Number")
ax3.set_ylabel(r"$\Delta V_{th}$ (mV)")
ax3.set_title(f"Threshold Voltage Shift vs Pulse Number\n"
              f"(Estimated from SS≈{SS_MVDEC} mV/dec)")
ax3.set_xlim(0.5, N_PULSES + 0.5)
ax3.set_xticks(range(1, N_PULSES + 1, 2))
ax3.legend(loc="best")
ax3.grid(True, alpha=0.3)
fig3.tight_layout()
fig3.savefig(os.path.join(OUTDIR, "simC_v6_fig3_dvth.png"))
print("Saved: simC_v6_fig3_dvth.png")

# =====================================================================
# PLOT 4: Reset Completeness (bar chart)
# =====================================================================
fig4, (ax4a, ax4b) = plt.subplots(1, 2, figsize=(12, 5))

# 4a: Current comparison bars
x_pos = np.arange(len(NODES))
width = 0.25
labels_short = []
id_bl_vals, id_p30_vals, id_pr_vals = [], [], []
for dirname, r in results.items():
    labels_short.append(f"{r['Vpulse']:.0f}V")
    id_bl_vals.append(r["id_baseline"] * 1e6)
    id_p30_vals.append(r["ids_read"][29] * 1e6)
    id_pr_vals.append(r["id_postreset"] * 1e6)

ax4a.bar(x_pos - width, id_bl_vals, width, label="Baseline", color="#4CAF50", alpha=0.8)
ax4a.bar(x_pos, id_p30_vals, width, label="After P30", color="#F44336", alpha=0.8)
ax4a.bar(x_pos + width, id_pr_vals, width, label="Post-Reset", color="#2196F3", alpha=0.8)
ax4a.set_xlabel(r"$V_{pulse}$")
ax4a.set_ylabel(r"$I_D$ (µA)")
ax4a.set_title("Current: Baseline vs P30 vs Post-Reset")
ax4a.set_xticks(x_pos)
ax4a.set_xticklabels(labels_short)
ax4a.legend()
ax4a.grid(axis="y", alpha=0.3)

# 4b: Reset percentage
reset_pcts = []
for dirname, r in results.items():
    bl = r["id_baseline"]
    p30 = r["ids_read"][29]
    pr = r["id_postreset"]
    pct = (1.0 - (pr - bl) / (p30 - bl)) * 100
    reset_pcts.append(pct)

bars = ax4b.bar(x_pos, reset_pcts, 0.5, color=[COLORS[d] for d in NODES], alpha=0.8)
ax4b.set_xlabel(r"$V_{pulse}$")
ax4b.set_ylabel("Reset Completeness (%)")
ax4b.set_title(f"Reset Completeness ($V_{{reset}}$={VRESET}V)")
ax4b.set_xticks(x_pos)
ax4b.set_xticklabels(labels_short)
ax4b.set_ylim(0, max(max(reset_pcts) + 15, 115))
ax4b.axhline(y=100, color="gray", linestyle="--", alpha=0.5)
for bar, pct in zip(bars, reset_pcts):
    ax4b.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 2,
              f"{pct:.1f}%", ha="center", va="bottom", fontsize=10, fontweight="bold")
ax4b.grid(axis="y", alpha=0.3)

fig4.tight_layout()
fig4.savefig(os.path.join(OUTDIR, "simC_v6_fig4_reset.png"))
print("Saved: simC_v6_fig4_reset.png")

# =====================================================================
# PLOT 5: Leak Gap Analysis (current & polarization during gap after P15)
# =====================================================================
fig5, (ax5a, ax5b) = plt.subplots(1, 2, figsize=(12, 5))
for dirname, r in results.items():
    if r["leak_time"] is not None and r["leak_id"] is not None:
        t_rel = (r["leak_time"] - r["leak_time"][0]) * 1e6  # relative µs
        ax5a.plot(t_rel, r["leak_id"] * 1e6, "-", color=COLORS[dirname],
                  label=LABELS[dirname], linewidth=1.5)
        if r["leak_pol"] is not None:
            ax5b.plot(t_rel, r["leak_pol"] * 1e6, "-", color=COLORS[dirname],
                      label=LABELS[dirname], linewidth=1.5)

ax5a.set_xlabel("Time (µs)")
ax5a.set_ylabel(r"$|I_D|$ (µA)")
ax5a.set_title(f"Leak Gap: Drain Current Decay (after P{LEAK_AFTER})")
ax5a.legend()
ax5a.grid(True, alpha=0.3)

ax5b.set_xlabel("Time (µs)")
ax5b.set_ylabel(r"Polarization $P_y$ (µC/cm²)")
ax5b.set_title(f"Leak Gap: Polarization Stability (after P{LEAK_AFTER})")
ax5b.legend()
ax5b.grid(True, alpha=0.3)

fig5.tight_layout()
fig5.savefig(os.path.join(OUTDIR, "simC_v6_fig5_leak.png"))
print("Saved: simC_v6_fig5_leak.png")

# =====================================================================
# PLOT 6: Combined Summary — 2x2
# =====================================================================
fig6, axes = plt.subplots(2, 2, figsize=(14, 10))

# 6a: Integration curve
ax = axes[0, 0]
for dirname, r in results.items():
    ratios = r["ids_read"] / r["id_baseline"]
    ax.plot(pulses, ratios, "o-", color=COLORS[dirname], label=LABELS[dirname],
            markersize=4, linewidth=1.8)
    # Mark fire point
    fire_idx = np.where(ratios >= FIRE_RATIO)[0]
    if len(fire_idx) > 0:
        idx = fire_idx[0]
        ax.scatter([pulses[idx]], [ratios[idx]], color=COLORS[dirname], s=120,
                  marker='*', zorder=5, edgecolors='black', linewidths=0.5)
ax.axhline(y=FIRE_RATIO, color="red", linestyle="--", linewidth=1.2, alpha=0.7)
ax.axvline(x=LEAK_AFTER + 0.5, color="gray", linestyle=":", linewidth=1, alpha=0.5)
ax.set_xlabel("Pulse #")
ax.set_ylabel(r"$I_{read}/I_{base}$")
ax.set_title("(a) Integration (FIRE confirmed at 6V/7V)")
ax.set_xticks(range(1, N_PULSES + 1, 5))
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# 6b: Polarization
ax = axes[0, 1]
for dirname, r in results.items():
    pols = r["pols_read"] * 1e6
    ax.plot(pulses, pols, "s-", color=COLORS[dirname], label=LABELS[dirname],
            markersize=4, linewidth=1.8)
ax.axvline(x=LEAK_AFTER + 0.5, color="gray", linestyle=":", linewidth=1, alpha=0.5)
ax.set_xlabel("Pulse #")
ax.set_ylabel(r"$P_y$ (µC/cm²)")
ax.set_title("(b) Polarization")
ax.set_xticks(range(1, N_PULSES + 1, 5))
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# 6c: ΔVth
ax = axes[1, 0]
for dirname, r in results.items():
    ratios = r["ids_read"] / r["id_baseline"]
    dvth = -SS_MVDEC * np.log10(ratios)
    ax.plot(pulses, dvth, "^-", color=COLORS[dirname], label=LABELS[dirname],
            markersize=4, linewidth=1.8)
ax.axvline(x=LEAK_AFTER + 0.5, color="gray", linestyle=":", linewidth=1, alpha=0.5)
ax.set_xlabel("Pulse #")
ax.set_ylabel(r"$\Delta V_{th}$ (mV)")
ax.set_title(r"(c) $\Delta V_{th}$ (SS≈61 mV/dec)")
ax.set_xticks(range(1, N_PULSES + 1, 5))
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# 6d: Reset
ax = axes[1, 1]
for i, (dirname, r) in enumerate(results.items()):
    bl = r["id_baseline"]
    p30 = r["ids_read"][29]
    pr = r["id_postreset"]
    pct = (1.0 - (pr - bl) / (p30 - bl)) * 100
    ax.bar(i, pct, 0.6, color=COLORS[dirname], alpha=0.8)
    ax.text(i, pct + 1, f"{pct:.1f}%", ha="center", fontsize=10, fontweight="bold")
ax.set_xlabel(r"$V_{pulse}$")
ax.set_ylabel("Reset %")
ax.set_title(f"(d) Reset Completeness ($V_{{reset}}$={VRESET}V)")
ax.set_xticks(range(len(NODES)))
ax.set_xticklabels([f"{r['Vpulse']:.0f}V" for r in results.values()])
ax.set_ylim(0, max(max(reset_pcts) + 15, 115))
ax.axhline(y=100, color="gray", linestyle="--", alpha=0.5)
ax.grid(axis="y", alpha=0.3)

fig6.suptitle(f"SimC v6: Write-Then-Read LIF — Vpulse Sweep 5/6/7V "
              f"(pw={PW_NS}ns, τ_E={TAU_E_US}µs, pw/τ_E=0.1, FIRE CONFIRMED!)",
              fontsize=14, fontweight="bold", y=1.01)
fig6.tight_layout()
fig6.savefig(os.path.join(OUTDIR, "simC_v6_fig6_summary.png"))
print("Saved: simC_v6_fig6_summary.png")

plt.close("all")
print("\nAll v6 plots generated successfully.")
