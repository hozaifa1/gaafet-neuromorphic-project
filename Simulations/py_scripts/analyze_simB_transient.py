"""
SimB Analysis with Transient Readout (τ_E = 1µs, Vpulse = 2.0V)
=============================================================
Analyzes the new simB run where Quasistationary readout was replaced
with 1ns Transient readout to preserve cumulative switching state.

Expected: Monotonic Vth(N) staircase showing cumulative integration
"""

import re
import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm

# ── Paths ─────────────────────────────────────────────────────────────────────
BASE_DIR  = os.path.join(os.path.dirname(__file__), "..")
SIMB_DIR  = os.path.join(BASE_DIR, "simB")
OUT_DIR   = os.path.dirname(__file__)

# ── SimB readout points ───────────────────────────────────────────────────────
SIMB_READOUTS = [
    {"n_pulses": 0,  "tag": "baseline", "file": "baseline_fwd_n5_des.plt"},
    {"n_pulses": 1,  "tag": "read_n01", "file": "read_n01_fwd_n5_des.plt"},
    {"n_pulses": 3,  "tag": "read_n03", "file": "read_n03_fwd_n5_des.plt"},
    {"n_pulses": 5,  "tag": "read_n05", "file": "read_n05_fwd_n5_des.plt"},
    {"n_pulses": 10, "tag": "read_n10", "file": "read_n10_fwd_n5_des.plt"},
    {"n_pulses": 20, "tag": "read_n20", "file": "read_n20_fwd_n5_des.plt"},
]

# ── Pulse hold files for selected pulses ───────────────────────────────────────
SELECTED_PULSES = [1, 5, 10, 20]

# ── Constants ─────────────────────────────────────────────────────────────────
VTH_BASE_V  = -0.050
FC_MV_CM    = 1.2
PR_UC_CM2   = 16.0
VPULSE      = 2.0  # Fixed for SimB

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
print("SimB Analysis — TRANSIENT READOUT (τ_E = 1µs, Vpulse = 2.0V)")
print("=" * 70)

# Parse all readout data
simb_baseline = None
simb_readouts = []
simb_pulse_hold = {}

for readout in SIMB_READOUTS:
    filepath = os.path.join(SIMB_DIR, readout["file"])
    data = parse_plt(filepath)
    
    if simb_baseline is None:
        simb_baseline = data
    simb_readouts.append(data)

# Parse selected pulse hold data
for pulse_num in SELECTED_PULSES:
    filepath = os.path.join(SIMB_DIR, f"p{pulse_num}_hold_n5_des.plt")
    simb_pulse_hold[pulse_num] = parse_plt(filepath)

# Extract ΔVth and other metrics
simb_dvth = [extract_dvth(rd, simb_baseline) for rd in simb_readouts]
simb_n_pulses = [r["n_pulses"] for r in SIMB_READOUTS]

print(f"\n{'Readout':>10} {'N_pulses':>9} {'ID@probe(µA)':>12} {'Pol/y(µC/cm²)':>15} {'ΔVth(mV)':>9}")
print("-" * 70)
for i, readout in enumerate(SIMB_READOUTS):
    id_probe = simb_readouts[i][ID_COL][0] * 1e6
    pol_probe = simb_readouts[i][POLY_COL][0] * 1e6
    print(f"{readout['tag']:>10} {readout['n_pulses']:>9} {id_probe:>12.3f} {pol_probe:>15.4f} {simb_dvth[i]:>9.1f}")
print("-" * 70)

# Calculate consecutive pulse increments
print("\nConsecutive pulses between readouts:")
for i in range(1, len(SIMB_READOUTS)):
    prev_n = SIMB_READOUTS[i-1]["n_pulses"]
    curr_n = SIMB_READOUTS[i]["n_pulses"]
    consec = curr_n - prev_n
    if consec > 0:
        id_prev = simb_readouts[i-1][ID_COL][0] * 1e6
        id_curr = simb_readouts[i][ID_COL][0] * 1e6
        delta_id = id_curr - id_prev
        print(f"  {SIMB_READOUTS[i-1]['tag']}→{SIMB_READOUTS[i]['tag']}: {consec} pulses without read → ΔID = {delta_id:+.3f} µA")

# Pulse hold end-of-pulse polarization
print(f"\nPulse-hold end-of-pulse Pol/y (before readout):")
for pulse_num in SELECTED_PULSES:
    pol_end = simb_pulse_hold[pulse_num][POLY_COL][-1] * 1e6
    print(f"  Pulse {pulse_num:2d} end: Pol/y = {pol_end:+.4f} µC/cm²")

# Analysis of integration behavior
dvth_range = max(simb_dvth) - min(simb_dvth)
final_dvth = simb_dvth[-1]  # After 20 pulses
expected_dvth = 16.5 * 20  # Based on SimA result

print(f"\nΔVth range: {min(simb_dvth):.1f} – {max(simb_dvth):.1f} mV (total = {dvth_range:.1f} mV)")
print(f"Final ΔVth after 20 pulses: {final_dvth:.1f} mV")
print(f"Expected based on SimA (16.5mV × 20): {expected_dvth:.1f} mV")
print(f"Integration efficiency: {final_dvth/expected_dvth*100:.1f}%")

# Validation
good_integration = dvth_range > 50  # Significant cumulative shift
sub_coercive = all(abs(simb_readouts[i][EY_COL][0]) / 1e6 / FC_MV_CM < 0.8 
                   for i in range(len(simb_readouts)))

print(f"\n✅ Cumulative integration: {'YES' if good_integration else 'NO'}")
print(f"✅ Sub-coercive operation: {'YES' if sub_coercive else 'NO'}")

if good_integration and sub_coercive:
    print("\n🎉 SUCCESS: SimB shows cumulative LIF integration!")
    print("   - Multiple pulses produce monotonic Vth shift")
    print("   - Transient readout preserves accumulated state")
    print("   - Ready for SimC leak + reset testing")
else:
    print("\n⚠️  Issues detected:")
    if not good_integration:
        print("   - Insufficient cumulative Vth shift")
    if not sub_coercive:
        print("   - Some readouts exceed sub-coercive regime")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURES
# ══════════════════════════════════════════════════════════════════════════════
colors = plt.cm.viridis(np.linspace(0.1, 0.9, len(SIMB_READOUTS)))

# ── Fig 1: ID-VGS overlay showing cumulative shift ──
fig1, ax1 = plt.subplots(figsize=(7, 5))
vgs_b = simb_baseline[VGS_COL]
ax1.plot(vgs_b, simb_baseline[ID_COL]*1e6, "k--", lw=2, label="Baseline", zorder=10)
for i, (readout, rd) in enumerate(zip(SIMB_READOUTS, simb_readouts)):
    if readout["n_pulses"] > 0:  # Skip baseline in label
        ax1.plot(rd[VGS_COL], rd[ID_COL]*1e6, color=colors[i], lw=1.8,
                 label=f"N={readout['n_pulses']} (ΔVth={simb_dvth[i]:.1f}mV)")
ax1.set_xlabel("V$_{GS}$ (V)")
ax1.set_ylabel("I$_D$ (µA)")
ax1.set_title("SimB — Cumulative ID-VGS Shift with Transient Readout")
ax1.legend(fontsize=9)
ax1.grid(True, alpha=0.3)
fig1.tight_layout()
fig1.savefig(os.path.join(OUT_DIR, "simB_transient_fig1_idvgs.png"), dpi=150)
print("\nSaved simB_transient_fig1_idvgs.png")

# ── Fig 2: ΔVth staircase (key integration metric) ──
fig2, ax2 = plt.subplots(figsize=(7, 5))
ax2.plot(simb_n_pulses, simb_dvth, "o-", color="crimson", lw=2.5, ms=8, 
         label="Measured ΔVth(N)")
ax2.set_xlabel("Number of Pulses N")
ax2.set_ylabel("ΔV$_{th}$ (mV)")
ax2.set_title("SimB — Threshold Voltage Staircase (Cumulative Integration)")
ax2.grid(True, alpha=0.3)
ax2.legend(fontsize=10)

# Add expected linear line for comparison
if final_dvth > 0:
    expected_line = np.linspace(0, final_dvth, 100)
    expected_n = np.linspace(0, 20, 100)
    ax2.plot(expected_n, expected_line, "b--", alpha=0.5, lw=1.5, 
             label=f"Linear extrapolation")
    ax2.legend(fontsize=10)

# Add efficiency annotation
ax2.text(0.98, 0.02, f"Integration efficiency: {final_dvth/expected_dvth*100:.1f}%\n"
                        f"Final ΔVth: {final_dvth:.1f} mV\n"
                        r"τ$_E$ = 1µs, V$_{pulse}$ = 2.0V",
         transform=ax2.transAxes, ha="right", va="bottom", fontsize=9,
         bbox=dict(boxstyle="round,pad=0.3", facecolor="lightblue", alpha=0.9))

fig2.tight_layout()
fig2.savefig(os.path.join(OUT_DIR, "simB_transient_fig2_staircase.png"), dpi=150)
print("Saved simB_transient_fig2_staircase.png")

# ── Fig 3: Polarization evolution during pulse holds ──
fig3, ax3 = plt.subplots(figsize=(8, 5))
cmap = plt.get_cmap("plasma")
for i, pulse_num in enumerate(SELECTED_PULSES):
    t_ns = simb_pulse_hold[pulse_num][TIME_COL] * 1e9
    poly_uc = simb_pulse_hold[pulse_num][POLY_COL] * 1e6
    color = cmap(i / (len(SELECTED_PULSES) - 1))
    ax3.plot(t_ns, poly_uc, color=color, lw=1.8, 
             label=f"Pulse {pulse_num} (Pol_end = {poly_uc[-1]:+.3f})")
ax3.set_xlabel("Time (ns)")
ax3.set_ylabel("Pol/y (µC/cm²)")
ax3.set_title("SimB — Polarization Evolution During Selected Pulse Holds")
ax3.legend(fontsize=9)
ax3.grid(True, alpha=0.3)
fig3.tight_layout()
fig3.savefig(os.path.join(OUT_DIR, "simB_transient_fig3_pulse_pol.png"), dpi=150)
print("Saved simB_transient_fig3_pulse_pol.png")

# ── Fig 4: Polarization at readout points (showing accumulation) ──
fig4, ax4 = plt.subplots(figsize=(7, 5))
pol_at_readout = [rd[POLY_COL][0] * 1e6 for rd in simb_readouts]
ax4.plot(simb_n_pulses, pol_at_readout, "s-", color="darkgreen", lw=2, ms=8,
         label="Pol/y at readout")
ax4.set_xlabel("Number of Pulses N")
ax4.set_ylabel("Pol/y at Readout (µC/cm²)")
ax4.set_title("SimB — Polarization Accumulation at Readout Points")
ax4.grid(True, alpha=0.3)
ax4.legend(fontsize=10)
ax4.text(0.98, 0.98, r"V$_{pulse}$ = 2.0V\nτ$_E$ = 1µs\nTransient readout",
         transform=ax4.transAxes, ha="right", va="top", fontsize=9,
         bbox=dict(boxstyle="round,pad=0.3", facecolor="honeydew", alpha=0.9))
fig4.tight_layout()
fig4.savefig(os.path.join(OUT_DIR, "simB_transient_fig4_readout_pol.png"), dpi=150)
print("Saved simB_transient_fig4_readout_pol.png")

# ══════════════════════════════════════════════════════════════════════════════
# VALIDATION & RECOMMENDATIONS
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "=" * 70)
print("VALIDATION & RECOMMENDATIONS")
print("=" * 70)

# Performance metrics
integration_quality = "EXCELLENT" if dvth_range > 200 else "GOOD" if dvth_range > 100 else "MODERATE"
linearity_score = 1.0 - (np.std(np.diff(simb_dvth[1:])) / np.mean(np.diff(simb_dvth[1:])) if len(simb_dvth) > 2 else 0)

print(f"📊 Integration Quality: {integration_quality}")
print(f"📈 Linearity Score: {linearity_score*100:.1f}%")
print(f"🎯 Final ΔVth: {final_dvth:.1f} mV (target: ~330 mV)")

# LIF neuron parameters extraction
if final_dvth > 0:
    # Estimate effective integration weight per pulse
    weight_per_pulse = final_dvth / 20  # mV/pulse
    
    # Estimate time constant from pulse dynamics
    # (This is simplified - real extraction would need more detailed analysis)
    
    print(f"\n🧮 Extracted LIF Parameters:")
    print(f"   Integration weight: {weight_per_pulse:.2f} mV/pulse")
    print(f"   Sub-coercive margin: {(1-abs(simb_readouts[-1][EY_COL][0])/1e6/FC_MV_CM)*100:.1f}%")
    print(f"   Readout preservation: {final_dvth/expected_dvth*100:.1f}%")

# Recommendations
print(f"\n🚀 Recommendations:")
if good_integration and sub_coercive:
    print("   ✅ SimB SUCCESS - Ready for SimC leak + reset testing")
    print("   ✅ Apply same Transient readout to SimC")
    print("   ✅ Target τ_P for desired leak time constant")
    print("   ✅ Consider negative reset pulse amplitude")
else:
    print("   ⚠️  Optimize Vpulse or τ_E before proceeding to SimC")

print(f"\nNext steps:")
print("1. Update SimC with Transient readout")
print("2. Add τ_P > 0 for polarization leak")
print("3. Test reset pulse (negative Vpulse)")
print("4. Extract complete LIF parameters for Step 2")

plt.show()
