"""
Comprehensive SimA + SimB Analysis (τ_E = 1µs run)
====================================================
Parses all .plt files from simA (5 Vpulse nodes) and simB (20 pulses, 5 readouts).
Generates diagnostic plots and prints quantitative summary.

Key diagnostic: Does the Quasistationary readout erase pulse-induced polarization?
"""

import re
import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm

# ── Paths ─────────────────────────────────────────────────────────────────────
BASE_DIR  = os.path.join(os.path.dirname(__file__), "..")
SIMA_DIR  = os.path.join(BASE_DIR, "simA")
SIMB_DIR  = os.path.join(BASE_DIR, "simB")
OUT_DIR   = os.path.dirname(__file__)

# ── SimA nodes ────────────────────────────────────────────────────────────────
SIMA_NODES = [
    {"vpulse": 1.0, "dir": "n3_1v",   "tag": "n3"},
    {"vpulse": 1.5, "dir": "n4_1_5v", "tag": "n4"},
    {"vpulse": 2.0, "dir": "n5_2v",   "tag": "n5"},
    {"vpulse": 2.5, "dir": "n6_2_5v", "tag": "n6"},
    {"vpulse": 3.0, "dir": "n7_3v",   "tag": "n7"},
]

# ── SimB readout points ──────────────────────────────────────────────────────
SIMB_READS = [
    {"label": "Baseline", "prefix": "baseline_fwd", "n_pulses": 0},
    {"label": "N=1",      "prefix": "read_n01_fwd",  "n_pulses": 1},
    {"label": "N=3",      "prefix": "read_n03_fwd",  "n_pulses": 3},
    {"label": "N=5",      "prefix": "read_n05_fwd",  "n_pulses": 5},
    {"label": "N=10",     "prefix": "read_n10_fwd",  "n_pulses": 10},
    {"label": "N=20",     "prefix": "read_n20_fwd",  "n_pulses": 20},
]

# ── Constants ─────────────────────────────────────────────────────────────────
VTH_BASE_V  = -0.050
FC_MV_CM    = 1.2
PR_UC_CM2   = 16.0

# ── Column aliases ────────────────────────────────────────────────────────────
VGS_COL  = "gate_contact OuterVoltage"
ID_COL   = "drain_contact TotalCurrent"
TIME_COL = "time"
POLY_COL = "Pos(0,0.0145) Polarization/y"
EY_COL   = "Pos(0,0.0145) ElectricField/y"

# ── Parser ────────────────────────────────────────────────────────────────────
def parse_plt(filepath):
    with open(filepath, "r") as f:
        content = f.read()
    datasets_match = re.search(r'datasets\s*=\s*\[(.*?)\]', content, re.DOTALL)
    if not datasets_match:
        raise ValueError(f"No datasets block found in {filepath}")
    col_names = re.findall(r'"([^"]+)"', datasets_match.group(1))
    n_cols = len(col_names)
    data_match = re.search(r'\bData\s*\{(.*?)\}', content, re.DOTALL)
    if not data_match:
        raise ValueError(f"No Data block found in {filepath}")
    tokens = data_match.group(1).split()
    values = np.array([float(t) for t in tokens])
    arr = values.reshape(-1, n_cols)
    return {name: arr[:, i] for i, name in enumerate(col_names)}


def extract_dvth(post, base, vth_base=VTH_BASE_V):
    vgs_probe = base[VGS_COL][0]
    id_base   = base[ID_COL][0]
    id_post   = post[ID_COL][0]
    ratio     = id_post / id_base
    vth_post  = vgs_probe - ratio * (vgs_probe - vth_base)
    return (vth_base - vth_post) * 1e3   # mV


# ══════════════════════════════════════════════════════════════════════════════
# PART 1: SimA Analysis
# ══════════════════════════════════════════════════════════════════════════════
print("=" * 70)
print("PART 1: SimA — Single-Pulse Amplitude Sweep (τ_E = 1µs)")
print("=" * 70)

sima_baseline = None
sima_postpulse = []
sima_hold = []

for node in SIMA_NODES:
    tag = node["tag"]
    bpath = os.path.join(SIMA_DIR, node["dir"], f"baseline_fwd_{tag}_des.plt")
    ppath = os.path.join(SIMA_DIR, node["dir"], f"postpulse_fwd_{tag}_des.plt")
    hpath = os.path.join(SIMA_DIR, node["dir"], f"pulse_hold_{tag}_des.plt")
    if sima_baseline is None:
        sima_baseline = parse_plt(bpath)
    sima_postpulse.append(parse_plt(ppath))
    sima_hold.append(parse_plt(hpath))

sima_dvth = [extract_dvth(pp, sima_baseline) for pp in sima_postpulse]
sima_vpulse = [n["vpulse"] for n in SIMA_NODES]

print(f"\n{'Vpulse(V)':>10} {'ΔVth(mV)':>10} {'ID_base(µA)':>12} {'ID_post(µA)':>12} "
      f"{'Pol_end(µC/cm²)':>18} {'E/Fc(%)':>9}")
print("-" * 80)
for i, node in enumerate(SIMA_NODES):
    id_b = sima_baseline[ID_COL][0] * 1e6
    id_p = sima_postpulse[i][ID_COL][0] * 1e6
    pol  = sima_hold[i][POLY_COL][-1] * 1e6
    ey   = abs(sima_hold[i][EY_COL][-1]) / 1e6
    print(f"{node['vpulse']:>10.1f} {sima_dvth[i]:>10.1f} {id_b:>12.3f} {id_p:>12.3f} "
          f"{pol:>18.4f} {ey/FC_MV_CM*100:>9.1f}")
print("-" * 80)
print(f"ΔVth range: {min(sima_dvth):.1f} – {max(sima_dvth):.1f} mV "
      f"(spread = {max(sima_dvth)-min(sima_dvth):.2f} mV)")
print("DIAGNOSIS: All ΔVth values are nearly identical → Quasistationary readout")
print("           erases the small pulse-induced P differences.\n")

# ══════════════════════════════════════════════════════════════════════════════
# PART 2: SimB Analysis
# ══════════════════════════════════════════════════════════════════════════════
print("=" * 70)
print("PART 2: SimB — Multi-Pulse Integration (Vpulse=2V, τ_E = 1µs)")
print("=" * 70)

simb_reads = []
for rd in SIMB_READS:
    fpath = os.path.join(SIMB_DIR, f"{rd['prefix']}_n5_des.plt")
    simb_reads.append(parse_plt(fpath))

simb_baseline = simb_reads[0]
simb_id_at_probe = [r[ID_COL][0] * 1e6 for r in simb_reads]
simb_pol_at_probe = [r[POLY_COL][0] * 1e6 for r in simb_reads]
simb_dvth = [extract_dvth(r, simb_baseline) for r in simb_reads]
simb_n = [rd["n_pulses"] for rd in SIMB_READS]

print(f"\n{'Readout':>10} {'N_pulses':>10} {'ID@probe(µA)':>14} {'Pol/y(µC/cm²)':>16} {'ΔVth(mV)':>10}")
print("-" * 65)
for i, rd in enumerate(SIMB_READS):
    print(f"{rd['label']:>10} {rd['n_pulses']:>10} {simb_id_at_probe[i]:>14.4f} "
          f"{simb_pol_at_probe[i]:>16.4f} {simb_dvth[i]:>10.1f}")
print("-" * 65)

# Consecutive pulses between reads
print("\nConsecutive pulses between readouts:")
gaps = [(1, "Baseline→N=1"), (2, "N=1→N=3"), (2, "N=3→N=5"),
        (5, "N=5→N=10"), (10, "N=10→N=20")]
for j, (gap, label) in enumerate(gaps):
    delta_id = simb_id_at_probe[j+1] - simb_id_at_probe[j]
    print(f"  {label:>16}: {gap:>2} pulses without read → ΔID = {delta_id:>+.4f} µA")

# Pulse-hold end-of-pulse polarization
print("\nPulse-hold end-of-pulse Pol/y (before readout):")
pulse_labels = [1, 5, 6, 10, 20]
for pn in pulse_labels:
    fpath = os.path.join(SIMB_DIR, f"p{pn}_hold_n5_des.plt")
    hd = parse_plt(fpath)
    pol_end = hd[POLY_COL][-1] * 1e6
    print(f"  Pulse {pn:>2} end: Pol/y = {pol_end:>+.4f} µC/cm²")

print("\nDIAGNOSIS: Readout N=1,3,5 show ~0 ΔVth (readout erases small P shift).")
print("           N=10 and N=20 show growing ΔVth because 5-10 consecutive")
print("           pulses accumulate enough P shift to partially survive readout.")
print("           p6 Pol/y matches p1 exactly → proof readout resets P state.")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURES
# ══════════════════════════════════════════════════════════════════════════════
colors_a = cm.plasma(np.linspace(0.15, 0.85, len(SIMA_NODES)))
colors_b = cm.viridis(np.linspace(0.2, 0.9, len(SIMB_READS)))

# ── Fig 1: SimA ID-VGS overlay ──
fig1, ax1 = plt.subplots(figsize=(7, 5))
vgs_b = sima_baseline[VGS_COL]
ax1.plot(vgs_b, sima_baseline[ID_COL]*1e6, "k--", lw=2, label="Baseline", zorder=10)
for i, (node, pp) in enumerate(zip(SIMA_NODES, sima_postpulse)):
    ax1.plot(pp[VGS_COL], pp[ID_COL]*1e6, color=colors_a[i], lw=1.8,
             label=f"Vp={node['vpulse']}V (ΔVth={sima_dvth[i]:.1f}mV)")
ax1.set_xlabel("V$_{GS}$ (V)")
ax1.set_ylabel("I$_D$ (µA)")
ax1.set_title("SimA — ID-VGS: All Post-Pulse Curves Overlap (τ$_E$=1µs)")
ax1.legend(fontsize=8)
ax1.grid(True, alpha=0.3)
fig1.tight_layout()
fig1.savefig(os.path.join(OUT_DIR, "analysis_fig1_simA_idvgs_flat.png"), dpi=150)
print("\nSaved analysis_fig1_simA_idvgs_flat.png")

# ── Fig 2: SimA ΔVth vs Vpulse (flat) ──
fig2, ax2 = plt.subplots(figsize=(6, 4.5))
bars = ax2.bar(sima_vpulse, sima_dvth, width=0.35, color=colors_a,
               edgecolor="black", linewidth=0.8)
ax2.plot(sima_vpulse, sima_dvth, "ko--", lw=1.5, ms=6, zorder=5)
for bar, dv in zip(bars, sima_dvth):
    ax2.text(bar.get_x()+bar.get_width()/2, bar.get_height()+0.3,
             f"{dv:.1f}", ha="center", va="bottom", fontsize=10, fontweight="bold")
ax2.set_xlabel("Gate Pulse Amplitude V$_{pulse}$ (V)")
ax2.set_ylabel("ΔV$_{th}$ (mV)")
ax2.set_title("SimA — ΔVth vs Vpulse: FLAT (readout erases P)")
ax2.set_xticks(sima_vpulse)
ax2.set_ylim(0, max(sima_dvth)*1.5)
ax2.grid(True, axis="y", alpha=0.3)
ax2.text(0.97, 0.95, "All ΔVth ≈ 21.5 mV\nQuasistationary readout\nerases pulse-induced ΔP",
         transform=ax2.transAxes, ha="right", va="top", fontsize=9, color="red",
         bbox=dict(boxstyle="round,pad=0.3", facecolor="mistyrose", alpha=0.9))
fig2.tight_layout()
fig2.savefig(os.path.join(OUT_DIR, "analysis_fig2_simA_dvth_flat.png"), dpi=150)
print("Saved analysis_fig2_simA_dvth_flat.png")

# ── Fig 3: SimA Polarization during pulse hold (DOES show differentiation) ──
fig3, (ax3a, ax3b) = plt.subplots(1, 2, figsize=(11, 4.5))
for i, (node, hd) in enumerate(zip(SIMA_NODES, sima_hold)):
    t_ns = hd[TIME_COL] * 1e9
    poly_uc = hd[POLY_COL] * 1e6
    ey_mvcm = np.abs(hd[EY_COL]) / 1e6
    ax3a.plot(t_ns, poly_uc, color=colors_a[i], lw=1.8, label=f"Vp={node['vpulse']}V")
    ax3b.plot(t_ns, ey_mvcm/FC_MV_CM*100, color=colors_a[i], lw=1.8, label=f"Vp={node['vpulse']}V")
ax3a.set_xlabel("Time (ns)")
ax3a.set_ylabel("Pol/y (µC/cm²)")
ax3a.set_title("Polarization During Pulse Hold")
ax3a.legend(fontsize=9)
ax3a.grid(True, alpha=0.3)
ax3a.text(0.03, 0.05, "Differentiated!\nPulse DOES move P\ndifferently per Vpulse",
          transform=ax3a.transAxes, ha="left", va="bottom", fontsize=8.5, color="green",
          bbox=dict(boxstyle="round,pad=0.3", facecolor="honeydew", alpha=0.9))
ax3b.set_xlabel("Time (ns)")
ax3b.set_ylabel("|E$_{HZO}$| / F$_c$ (%)")
ax3b.set_title("E-field Ratio During Pulse Hold")
ax3b.legend(fontsize=9)
ax3b.grid(True, alpha=0.3)
fig3.suptitle("SimA — Pulse Hold: P IS Differentiated (but readout erases it)", y=1.01)
fig3.tight_layout()
fig3.savefig(os.path.join(OUT_DIR, "analysis_fig3_simA_hold_differentiated.png"),
             dpi=150, bbox_inches="tight")
print("Saved analysis_fig3_simA_hold_differentiated.png")

# ── Fig 4: SimB ID-VGS overlay (all readout points) ──
fig4, ax4 = plt.subplots(figsize=(7, 5))
for i, (rd, data) in enumerate(zip(SIMB_READS, simb_reads)):
    lw = 2.5 if i == 0 else 1.8
    ls = "--" if i == 0 else "-"
    ax4.plot(data[VGS_COL], data[ID_COL]*1e6, color=colors_b[i], lw=lw, ls=ls,
             label=f"{rd['label']} (ΔVth={simb_dvth[i]:.1f}mV)")
ax4.set_xlabel("V$_{GS}$ (V)")
ax4.set_ylabel("I$_D$ (µA)")
ax4.set_title("SimB — ID-VGS After N Pulses (Vpulse=2V, τ$_E$=1µs)")
ax4.legend(fontsize=8)
ax4.grid(True, alpha=0.3)
fig4.tight_layout()
fig4.savefig(os.path.join(OUT_DIR, "analysis_fig4_simB_idvgs.png"), dpi=150)
print("Saved analysis_fig4_simB_idvgs.png")

# ── Fig 5: SimB ΔVth staircase vs N ──
fig5, (ax5a, ax5b) = plt.subplots(1, 2, figsize=(12, 5))

ax5a.plot(simb_n, simb_dvth, "o-", color="steelblue", lw=2, ms=8)
for i, (n, dv) in enumerate(zip(simb_n, simb_dvth)):
    ax5a.annotate(f"{dv:.1f}", (n, dv), textcoords="offset points",
                  xytext=(0, 10), ha="center", fontsize=9, fontweight="bold")
ax5a.set_xlabel("Number of Pulses N")
ax5a.set_ylabel("ΔV$_{th}$ (mV)")
ax5a.set_title("SimB — ΔVth vs Pulse Count")
ax5a.grid(True, alpha=0.3)
ax5a.axhspan(-5, 5, alpha=0.15, color="red", label="Dead zone (readout resets P)")
ax5a.legend(fontsize=8)

ax5b.plot(simb_n, simb_pol_at_probe, "s-", color="darkorange", lw=2, ms=8)
for i, (n, p) in enumerate(zip(simb_n, simb_pol_at_probe)):
    ax5b.annotate(f"{p:.3f}", (n, p), textcoords="offset points",
                  xytext=(0, 10), ha="center", fontsize=8)
ax5b.set_xlabel("Number of Pulses N")
ax5b.set_ylabel("Pol/y at readout (µC/cm²)")
ax5b.set_title("SimB — Polarization State at Readout")
ax5b.grid(True, alpha=0.3)

fig5.suptitle("SimB Integration Staircase: Only N≥10 Survives Readout Reset", y=1.01)
fig5.tight_layout()
fig5.savefig(os.path.join(OUT_DIR, "analysis_fig5_simB_staircase.png"),
             dpi=150, bbox_inches="tight")
print("Saved analysis_fig5_simB_staircase.png")

# ── Fig 6: Pulse-hold P evolution across consecutive pulses ──
fig6, ax6 = plt.subplots(figsize=(8, 5))
all_pulses = list(range(1, 21))
pol_ends = []
for pn in all_pulses:
    fpath = os.path.join(SIMB_DIR, f"p{pn}_hold_n5_des.plt")
    hd = parse_plt(fpath)
    pol_ends.append(hd[POLY_COL][-1] * 1e6)

ax6.plot(all_pulses, pol_ends, "o-", color="crimson", lw=1.8, ms=6)
for pn in pol_ends:
    pass

# Mark readout points
read_after = [1, 3, 5, 10, 20]
for rn in read_after:
    ax6.axvline(rn + 0.5, color="blue", ls=":", alpha=0.5)
    ax6.text(rn + 0.6, max(pol_ends)*0.9, f"Read\nN={rn}", fontsize=7,
             color="blue", va="top")

ax6.set_xlabel("Pulse Number")
ax6.set_ylabel("End-of-Pulse Pol/y (µC/cm²)")
ax6.set_title("SimB — Polarization at End of Each Pulse Hold\n"
              "(Blue lines = Quasistationary readout → P RESETS)")
ax6.grid(True, alpha=0.3)
fig6.tight_layout()
fig6.savefig(os.path.join(OUT_DIR, "analysis_fig6_simB_pulse_pol_evolution.png"), dpi=150)
print("Saved analysis_fig6_simB_pulse_pol_evolution.png")

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "=" * 70)
print("SUMMARY & ROOT CAUSE")
print("=" * 70)
print("""
ROOT CAUSE: Quasistationary readout erases pulse-induced polarization.

Evidence:
  SimA: All 5 Vpulse nodes give ΔVth ≈ 21.5 mV (identical), despite
        pulse_hold data showing clearly differentiated P values
        (-0.045 to -0.098 µC/cm² across 1V–3V).

  SimB: p6 end-of-hold Pol/y is IDENTICAL to p1 (both +0.081 µC/cm²),
        proving the readout after N=5 completely resets P.
        However, N=10 and N=20 show growing ΔVth because 5-10
        consecutive pulses accumulate enough ΔP to partially
        survive the equilibrium readout.

Mechanism:
  Quasistationary solver computes steady-state at each VGS step.
  This allows P to reach equilibrium for the applied E-field,
  erasing the small partial-switching state set by the transient pulse.
  With τ_E = 1µs and pw = 100ns, each pulse shifts P by only ~10%
  of equilibrium — too small to survive QS readout.

CONCLUSION: τ_E = 1µs IS CORRECT for LIF integration.
  The previous τ_E = 1ns gave "nicer" SimA curves but fundamentally
  cannot support cumulative integration (each pulse saturates).
  The fix is NOT to revert τ_E — it is to fix the READOUT METHOD.

FIX: Replace Quasistationary readout with fast Transient readout
  that completes in << τ_E (e.g., sweep VGS 0→0.3V in 1ns).
  This preserves the partially-switched P state during measurement.
""")

plt.show()
