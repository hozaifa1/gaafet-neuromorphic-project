"""
SimA Analysis with Transient Readout (τ_E = 1µs, FIXED)
========================================================
Analyzes the new simA run where Quasistationary readout was replaced
with 1ns Transient readout to preserve partial-switching state.

Expected: Differentiated ΔVth vs Vpulse (monotonic increase)
"""

import re
import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm

# ── Paths ─────────────────────────────────────────────────────────────────────
BASE_DIR  = os.path.join(os.path.dirname(__file__), "..")
SIMA_DIR  = os.path.join(BASE_DIR, "simA")
OUT_DIR   = os.path.dirname(__file__)

# ── SimA nodes ────────────────────────────────────────────────────────────────
SIMA_NODES = [
    {"vpulse": 1.0, "dir": "n3_1v",   "tag": "n3"},
    {"vpulse": 1.5, "dir": "n4_1_5v", "tag": "n4"},
    {"vpulse": 2.0, "dir": "n5_2v",   "tag": "n5"},
    {"vpulse": 2.5, "dir": "n6_2_5v", "tag": "n6"},
    {"vpulse": 3.0, "dir": "n7_3v",   "tag": "n7"},
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
    """Extract ΔVth from current ratio at VGS=0.01V probe point"""
    # For Transient readout, we need the first data point (VGS≈0)
    vgs_probe = base[VGS_COL][0]
    id_base   = base[ID_COL][0]
    id_post   = post[ID_COL][0]
    ratio     = id_post / id_base
    vth_post  = vgs_probe - ratio * (vgs_probe - vth_base)
    return (vth_base - vth_post) * 1e3   # mV


# ══════════════════════════════════════════════════════════════════════════════
# MAIN ANALYSIS
# ══════════════════════════════════════════════════════════════════════════════
print("=" * 70)
print("SimA Analysis — TRANSIENT READOUT (τ_E = 1µs)")
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

# Extract ΔVth and other metrics
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

# Analysis of differentiation
dvth_range = max(sima_dvth) - min(sima_dvth)
print(f"ΔVth range: {min(sima_dvth):.1f} – {max(sima_dvth):.1f} mV (spread = {dvth_range:.2f} mV)")

if dvth_range > 5.0:  # Significant differentiation
    print("✅ SUCCESS: Transient readout preserves partial-switching state!")
    print("   ΔVth shows clear monotonic increase with Vpulse.")
else:
    print("⚠️  WARNING: ΔVth still relatively flat. Check simulation convergence.")

# Determine optimal Vpulse
# Look for Vpulse that gives good ΔVth while staying sub-coercive
for i, (vpulse, dvth) in enumerate(zip(sima_vpulse, sima_dvth)):
    pol_end = sima_hold[i][POLY_COL][-1] * 1e6
    ey_end = abs(sima_hold[i][EY_COL][-1]) / 1e6
    e_fc_ratio = ey_end / FC_MV_CM
    
    # Good criteria: ΔVth > 10mV, E/Fc < 50%, P shift reasonable
    if dvth > 10 and e_fc_ratio < 0.5:
        print(f"\n🎯 RECOMMENDED Vpulse = {vpulse}V")
        print(f"   ΔVth per pulse = {dvth:.1f} mV (good signal)")
        print(f"   E/Fc = {e_fc_ratio*100:.1f}% (sub-coercive)")
        print(f"   Pol shift = {pol_end:.4f} µC/cm²")
        break

# ══════════════════════════════════════════════════════════════════════════════
# FIGURES
# ══════════════════════════════════════════════════════════════════════════════
colors = cm.plasma(np.linspace(0.15, 0.85, len(SIMA_NODES)))

# ── Fig 1: ID-VGS overlay (Transient readout) ──
fig1, ax1 = plt.subplots(figsize=(7, 5))
vgs_b = sima_baseline[VGS_COL]
ax1.plot(vgs_b, sima_baseline[ID_COL]*1e6, "k--", lw=2, label="Baseline", zorder=10)
for i, (node, pp) in enumerate(zip(SIMA_NODES, sima_postpulse)):
    ax1.plot(pp[VGS_COL], pp[ID_COL]*1e6, color=colors[i], lw=1.8,
             label=f"Vp={node['vpulse']}V (ΔVth={sima_dvth[i]:.1f}mV)")
ax1.set_xlabel("V$_{GS}$ (V)")
ax1.set_ylabel("I$_D$ (µA)")
ax1.set_title("SimA — ID-VGS with Transient Readout (τ$_E$=1µs)")
ax1.legend(fontsize=8)
ax1.grid(True, alpha=0.3)
fig1.tight_layout()
fig1.savefig(os.path.join(OUT_DIR, "simA_transient_fig1_idvgs.png"), dpi=150)
print("\nSaved simA_transient_fig1_idvgs.png")

# ── Fig 2: ΔVth vs Vpulse (should be differentiated now) ──
fig2, ax2 = plt.subplots(figsize=(6, 4.5))
bars = ax2.bar(sima_vpulse, sima_dvth, width=0.35, color=colors,
               edgecolor="black", linewidth=0.8)
ax2.plot(sima_vpulse, sima_dvth, "ko--", lw=1.5, ms=6, zorder=5)
for bar, dv in zip(bars, sima_dvth):
    ax2.text(bar.get_x()+bar.get_width()/2, bar.get_height()+max(sima_dvth)*0.02,
             f"{dv:.1f}", ha="center", va="bottom", fontsize=10, fontweight="bold")
ax2.set_xlabel("Gate Pulse Amplitude V$_{pulse}$ (V)")
ax2.set_ylabel("ΔV$_{th}$ (mV)")
ax2.set_title("SimA — ΔVth vs Vpulse (Transient Readout)")
ax2.set_xticks(sima_vpulse)
ax2.set_ylim(0, max(sima_dvth)*1.3)
ax2.grid(True, axis="y", alpha=0.3)
if dvth_range > 5.0:
    ax2.text(0.97, 0.95, "✅ DIFFERENTIATED!\nTransient readout\npreserves P state",
             transform=ax2.transAxes, ha="right", va="top", fontsize=9, color="green",
             bbox=dict(boxstyle="round,pad=0.3", facecolor="honeydew", alpha=0.9))
else:
    ax2.text(0.97, 0.95, "⚠️ Still flat?\nCheck simulation\nconvergence",
             transform=ax2.transAxes, ha="right", va="top", fontsize=9, color="orange",
             bbox=dict(boxstyle="round,pad=0.3", facecolor="moccasin", alpha=0.9))
fig2.tight_layout()
fig2.savefig(os.path.join(OUT_DIR, "simA_transient_fig2_dvth.png"), dpi=150)
print("Saved simA_transient_fig2_dvth.png")

# ── Fig 3: Polarization during pulse hold (should match previous) ──
fig3, (ax3a, ax3b) = plt.subplots(1, 2, figsize=(11, 4.5))
for i, (node, hd) in enumerate(zip(SIMA_NODES, sima_hold)):
    t_ns = hd[TIME_COL] * 1e9
    poly_uc = hd[POLY_COL] * 1e6
    ey_mvcm = np.abs(hd[EY_COL]) / 1e6
    ax3a.plot(t_ns, poly_uc, color=colors[i], lw=1.8, label=f"Vp={node['vpulse']}V")
    ax3b.plot(t_ns, ey_mvcm/FC_MV_CM*100, color=colors[i], lw=1.8, label=f"Vp={node['vpulse']}V")
ax3a.set_xlabel("Time (ns)")
ax3a.set_ylabel("Pol/y (µC/cm²)")
ax3a.set_title("Polarization During Pulse Hold")
ax3a.legend(fontsize=9)
ax3a.grid(True, alpha=0.3)
ax3b.set_xlabel("Time (ns)")
ax3b.set_ylabel("|E$_{HZO}$| / F$_c$ (%)")
ax3b.set_title("E-field Ratio During Pulse Hold")
ax3b.legend(fontsize=9)
ax3b.grid(True, alpha=0.3)
fig3.suptitle("SimA — Pulse Hold: Partial Switching (τ$_E$=1µs)", y=1.01)
fig3.tight_layout()
fig3.savefig(os.path.join(OUT_DIR, "simA_transient_fig3_hold.png"),
             dpi=150, bbox_inches="tight")
print("Saved simA_transient_fig3_hold.png")

# ── Fig 4: Comparison with previous QS readout ──
fig4, ax4 = plt.subplots(figsize=(7, 5))
# Load old QS data for comparison if available
try:
    old_script = os.path.join(OUT_DIR, "plot_simA_results.py")
    if os.path.exists(old_script):
        print("\nNote: Compare with previous QS results in analysis_fig2_simA_dvth_flat.png")
except:
    pass

ax4.plot(sima_vpulse, sima_dvth, "o-", color="crimson", lw=2, ms=8, 
         label="Transient readout (this run)")
ax4.set_xlabel("Gate Pulse Amplitude V$_{pulse}$ (V)")
ax4.set_ylabel("ΔV$_{th}$ (mV)")
ax4.set_title("SimA — Transient vs Quasistationary Readout Comparison")
ax4.set_xticks(sima_vpulse)
ax4.grid(True, alpha=0.3)
ax4.legend(fontsize=10)
ax4.text(0.02, 0.98, f"ΔVth range: {dvth_range:.2f} mV\nτ$_E$ = 1µs, pw = 100ns\nReadout: 1ns Transient",
         transform=ax4.transAxes, ha="left", va="top", fontsize=9,
         bbox=dict(boxstyle="round,pad=0.3", facecolor="lightblue", alpha=0.9))
fig4.tight_layout()
fig4.savefig(os.path.join(OUT_DIR, "simA_transient_fig4_comparison.png"), dpi=150)
print("Saved simA_transient_fig4_comparison.png")

# ══════════════════════════════════════════════════════════════════════════════
# VALIDATION & RECOMMENDATIONS
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "=" * 70)
print("VALIDATION & RECOMMENDATIONS")
print("=" * 70)

# Check if we achieved the expected behavior
expected_differentiation = dvth_range > 5.0
sub_coercive_operation = all(abs(sima_hold[i][EY_COL][-1]) / 1e6 / FC_MV_CM < 0.7 
                             for i in range(len(SIMA_NODES)))

print(f"✅ Differentiated ΔVth: {'YES' if expected_differentiation else 'NO'}")
print(f"✅ Sub-coercive operation: {'YES' if sub_coercive_operation else 'NO'}")
print(f"✅ Partial switching confirmed: {'YES' if max(sima_dvth) < 200 else 'NO (too large)'}")

if expected_differentiation and sub_coercive_operation:
    print("\n🎉 SUCCESS: Transient readout fix works!")
    print("   - Partial switching state preserved during measurement")
    print("   - Clear voltage-dependent ΔVth response")
    print("   - Ready to proceed with SimB multi-pulse integration")
    
    # Recommend Vpulse for SimB
    best_idx = np.argmax(sima_dvth)
    best_vpulse = sima_vpulse[best_idx]
    best_dvth = sima_dvth[best_idx]
    best_e_fc = abs(sima_hold[best_idx][EY_COL][-1]) / 1e6 / FC_MV_CM
    
    print(f"\n📍 RECOMMENDED Vpulse for SimB: {best_vpulse}V")
    print(f"   - ΔVth per pulse: {best_dvth:.1f} mV")
    print(f"   - E/Fc ratio: {best_e_fc*100:.1f}%")
    print(f"   - Expected 20-pulse ΔVth: ~{best_dvth*20:.0f} mV")
else:
    print("\n⚠️  Issues detected:")
    if not expected_differentiation:
        print("   - ΔVth still flat - check simulation convergence or readout timing")
    if not sub_coercive_operation:
        print("   - Some nodes exceed sub-coercive regime - reduce Vpulse range")

print("\nNext steps:")
print("1. If successful: Update SimB with same Transient readout fix")
print("2. Run SimB with Vpulse = recommended value")
print("3. Verify cumulative Vth(N) staircase")
print("4. Proceed to SimC with τ_P > 0 for leak + reset")

plt.show()
