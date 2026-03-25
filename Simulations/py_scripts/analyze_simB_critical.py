"""
SimB CRITICAL Analysis - Questioning the "Success"
===============================================
Taking a hard look at whether SimB actually shows proper LIF integration.
The "staircase" appears to be a smooth curve, not discrete steps.
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
    vgs_probe = base[VGS_COL][0]
    id_base   = base[ID_COL][0]
    id_post   = post[ID_COL][0]
    ratio     = id_post / id_base
    vth_post  = vgs_probe - ratio * (vgs_probe - vth_base)
    return (vth_base - vth_post) * 1e3   # mV


# ══════════════════════════════════════════════════════════════════════════════
# CRITICAL ANALYSIS
# ══════════════════════════════════════════════════════════════════════════════
print("=" * 80)
print("SimB CRITICAL Analysis - Is this really LIF integration?")
print("=" * 80)

# Parse all readout data
simb_baseline = None
simb_readouts = []

for readout in SIMB_READOUTS:
    filepath = os.path.join(SIMB_DIR, readout["file"])
    data = parse_plt(filepath)
    if simb_baseline is None:
        simb_baseline = data
    simb_readouts.append(data)

# Extract metrics
simb_dvth = [extract_dvth(rd, simb_baseline) for rd in simb_readouts]
simb_n_pulses = [r["n_pulses"] for r in SIMB_READOUTS]

print(f"\n{'Readout':>10} {'N_pulses':>9} {'ID@probe(µA)':>12} {'ΔVth(mV)':>9} {'ΔVth/pulse':>11}")
print("-" * 70)
for i, readout in enumerate(SIMB_READOUTS):
    id_probe = simb_readouts[i][ID_COL][0] * 1e6
    if readout["n_pulses"] > 0:
        dvth_per_pulse = simb_dvth[i] / readout["n_pulses"]
    else:
        dvth_per_pulse = 0
    print(f"{readout['tag']:>10} {readout['n_pulses']:>9} {id_probe:>12.3f} {simb_dvth[i]:>9.1f} {dvth_per_pulse:>11.2f}")
print("-" * 70)

# Critical analysis of linearity and step behavior
print(f"\n🔍 CRITICAL EXAMINATION:")
print(f"ΔVth range: {min(simb_dvth):.1f} – {max(simb_dvth):.1f} mV")

# Check if this is really a staircase or just a curve
dvth_diffs = np.diff(simb_dvth[1:])  # Skip baseline
pulse_diffs = np.diff(simb_n_pulses[1:])

print(f"\nStep analysis (ΔVth per consecutive pulses):")
for i in range(len(dvth_diffs)):
    n_pulses = pulse_diffs[i]
    if n_pulses > 0:
        dvth_per_pulse = dvth_diffs[i] / n_pulses
        print(f"  {SIMB_READOUTS[i+1]['tag']}: {dvth_per_pulse:.2f} mV/pulse ({n_pulses} pulses)")

# Linearity test
if len(simb_n_pulses) > 2:
    # Fit linear regression
    coeffs = np.polyfit(simb_n_pulses, simb_dvth, 1)
    linear_fit = np.polyval(coeffs, simb_n_pulses)
    r_squared = 1 - np.sum((np.array(simb_dvth) - linear_fit)**2) / np.sum((np.array(simb_dvth) - np.mean(simb_dvth))**2)
    
    print(f"\n📊 Linearity Analysis:")
    print(f"Linear fit: ΔVth = {coeffs[0]:.2f} × N + {coeffs[1]:.1f}")
    print(f"R² = {r_squared:.4f} (1.0 = perfect linear)")
    
    if r_squared > 0.95:
        print("⚠️  WARNING: This is essentially LINEAR behavior, not discrete steps!")
    elif r_squared > 0.8:
        print("⚠️  CAUTION: Mostly linear with some deviation")
    else:
        print("✅ Good non-linearity - possible staircase behavior")

# Check for actual step-like behavior
step_like = False
for i in range(1, len(simb_dvth)):
    expected_linear = simb_dvth[0] + (simb_dvth[-1] - simb_dvth[0]) * simb_n_pulses[i] / simb_n_pulses[-1]
    deviation = abs(simb_dvth[i] - expected_linear)
    if deviation > 10:  # More than 10mV deviation from linear
        step_like = True

print(f"\n🔍 Step-like behavior: {'DETECTED' if step_like else 'NOT DETECTED'}")

# Compare with expected discrete steps
expected_per_pulse = 16.5  # From SimA
print(f"\n📈 Expected vs Actual:")
print(f"Expected per pulse (SimA): {expected_per_pulse:.1f} mV")
actual_per_pulse = simb_dvth[-1] / 20
print(f"Actual average per pulse: {actual_per_pulse:.1f} mV")
print(f"Efficiency: {actual_per_pulse/expected_per_pulse*100:.1f}%")

# ══════════════════════════════════════════════════════════════════════════════
# REVISED FIGURES - More Critical Visualization
# ══════════════════════════════════════════════════════════════════════════════
colors = plt.cm.viridis(np.linspace(0.1, 0.9, len(SIMB_READOUTS)))

# ── Fig 1: ΔVth with CRITICAL analysis ──
fig1, ax1 = plt.subplots(figsize=(8, 6))

# Plot actual data
ax1.plot(simb_n_pulses, simb_dvth, 'ro-', lw=2.5, ms=10, label='Measured data', zorder=5)

# Plot linear fit
if len(simb_n_pulses) > 2:
    linear_fit = np.polyval(coeffs, simb_n_pulses)
    ax1.plot(simb_n_pulses, linear_fit, 'b--', lw=2, alpha=0.7, label=f'Linear fit (R²={r_squared:.3f})')

# Plot expected ideal staircase
ideal_staircase = []
cumulative = 0
for n in simb_n_pulses:
    cumulative = n * expected_per_pulse
    ideal_staircase.append(cumulative)
ax1.plot(simb_n_pulses, ideal_staircase, 'g:', lw=2, alpha=0.7, label='Ideal staircase (16.5mV/pulse)')

ax1.set_xlabel("Number of Pulses N", fontsize=12)
ax1.set_ylabel("ΔV$_{th}$ (mV)", fontsize=12)
ax1.set_title("SimB ΔVth Analysis: Staircase or Just a Curve?", fontsize=14, fontweight='bold')
ax1.grid(True, alpha=0.3)
ax1.legend(fontsize=10)

# Add critical annotation
if r_squared > 0.95:
    conclusion = "⚠️ ESSENTIALLY LINEAR - Not true staircase!"
    color = 'orange'
elif r_squared > 0.8:
    conclusion = "🤔 MOSTLY LINEAR - Questionable staircase"
    color = 'goldenrod'
else:
    conclusion = "✅ NON-LINEAR - Possible staircase behavior"
    color = 'green'

ax1.text(0.02, 0.98, conclusion, transform=ax1.transAxes, ha="left", va="top", 
         fontsize=11, fontweight='bold', color=color,
         bbox=dict(boxstyle="round,pad=0.5", facecolor="white", alpha=0.9, edgecolor=color))

ax1.text(0.02, 0.85, f"R² = {r_squared:.3f}\nEfficiency = {actual_per_pulse/expected_per_pulse*100:.1f}%\n"
                          f"Final ΔVth = {simb_dvth[-1]:.1f} mV", 
         transform=ax1.transAxes, ha="left", va="top", fontsize=9,
         bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgray", alpha=0.9))

fig1.tight_layout()
fig1.savefig(os.path.join(OUT_DIR, "simB_critical_fig1_dvth_analysis.png"), dpi=150)
print("\nSaved simB_critical_fig1_dvth_analysis.png")

# ── Fig 2: Pulse-by-Pulse Analysis ──
fig2, (ax2a, ax2b) = plt.subplots(1, 2, figsize=(12, 5))

# Left: Incremental ΔVth per pulse segment
incremental_dvth = []
incremental_pulses = []
labels = []

for i in range(1, len(simb_dvth)):
    delta_dvth = simb_dvth[i] - simb_dvth[i-1]
    delta_n = simb_n_pulses[i] - simb_n_pulses[i-1]
    if delta_n > 0:
        per_pulse = delta_dvth / delta_n
        incremental_dvth.append(per_pulse)
        incremental_pulses.append(delta_n)
        labels.append(f"{SIMB_READOUTS[i-1]['tag']}→{SIMB_READOUTS[i]['tag']}")

bars = ax2a.bar(range(len(incremental_dvth)), incremental_dvth, color=colors[1:len(incremental_dvth)+1])
ax2a.set_xlabel("Pulse Segment")
ax2a.set_ylabel("ΔVth per Pulse (mV)")
ax2a.set_title("Incremental Analysis: Is each pulse contributing equally?")
ax2a.set_xticks(range(len(labels)))
ax2a.set_xticklabels(labels, rotation=45, ha='right')
ax2a.grid(True, alpha=0.3, axis='y')

# Add reference line
ax2a.axhline(y=expected_per_pulse, color='red', linestyle='--', alpha=0.7, label=f'Expected ({expected_per_pulse:.1f} mV)')
ax2a.legend(fontsize=9)

# Right: Deviation from linearity
deviation_from_linear = np.array(simb_dvth) - linear_fit
ax2b.plot(simb_n_pulses, deviation_from_linear, 'ko-', lw=2, ms=8)
ax2b.axhline(y=0, color='red', linestyle='--', alpha=0.5)
ax2b.set_xlabel("Number of Pulses N")
ax2b.set_ylabel("Deviation from Linear (mV)")
ax2b.set_title("Non-linearity Analysis")
ax2b.grid(True, alpha=0.3)

# Add significance bands
ax2b.fill_between(simb_n_pulses, -5, 5, alpha=0.2, color='green', label='±5mV (noise level)')
ax2b.fill_between(simb_n_pulses, -10, 10, alpha=0.1, color='orange', label='±10mV (minor deviation)')
ax2b.legend(fontsize=9)

fig2.tight_layout()
fig2.savefig(os.path.join(OUT_DIR, "simB_critical_fig2_incremental.png"), dpi=150)
print("Saved simB_critical_fig2_incremental.png")

# ── Fig 3: Better Pulse Hold Visualization ──
fig3, ax3 = plt.subplots(figsize=(10, 6))

# Load ALL pulse hold data for better comparison
all_pulse_data = {}
for pulse_num in range(1, 21):  # Load all 20 pulses
    filepath = os.path.join(SIMB_DIR, f"p{pulse_num}_hold_n5_des.plt")
    if os.path.exists(filepath):
        all_pulse_data[pulse_num] = parse_plt(filepath)

# Plot with better color mapping
cmap = plt.get_cmap("plasma")
for pulse_num in [1, 5, 10, 15, 20]:  # Key pulses
    if pulse_num in all_pulse_data:
        t_ns = all_pulse_data[pulse_num][TIME_COL] * 1e9
        poly_uc = all_pulse_data[pulse_num][POLY_COL] * 1e6
        
        # Normalize color based on pulse number
        color = cmap((pulse_num - 1) / 19)
        
        # Plot with better styling
        ax3.plot(t_ns, poly_uc, color=color, lw=2, alpha=0.8,
                label=f"Pulse {pulse_num:2d} (end = {poly_uc[-1]:+.3f})")

ax3.set_xlabel("Time During Pulse Hold (ns)", fontsize=12)
ax3.set_ylabel("Polarization Pol/y (µC/cm²)", fontsize=12)
ax3.set_title("Pulse Hold Evolution: Are the pulses really different?", fontsize=14, fontweight='bold')
ax3.legend(fontsize=10, loc='best')
ax3.grid(True, alpha=0.3)

# Add zoom-in of the end region
ax3in = ax3.inset_axes([0.65, 0.45, 0.3, 0.4])
for pulse_num in [1, 5, 10, 15, 20]:
    if pulse_num in all_pulse_data:
        t_ns = all_pulse_data[pulse_num][TIME_COL] * 1e9
        poly_uc = all_pulse_data[pulse_num][POLY_COL] * 1e6
        color = cmap((pulse_num - 1) / 19)
        ax3in.plot(t_ns[-20:], poly_uc[-20:], color=color, lw=2, alpha=0.8)

ax3in.set_xlabel("Time (ns)", fontsize=9)
ax3in.set_ylabel("Pol/y (µC/cm²)", fontsize=9)
ax3in.set_title("End of pulse (zoom)", fontsize=10)
ax3in.grid(True, alpha=0.3)

fig3.tight_layout()
fig3.savefig(os.path.join(OUT_DIR, "simB_critical_fig3_pulse_hold.png"), dpi=150)
print("Saved simB_critical_fig3_pulse_hold.png")

# ══════════════════════════════════════════════════════════════════════════════
# CRITICAL CONCLUSION
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "=" * 80)
print("CRITICAL CONCLUSION")
print("=" * 80)

if r_squared > 0.95:
    print("🚨 VERDICT: NOT TRUE STAIRCASE BEHAVIOR")
    print("   The ΔVth vs N relationship is essentially linear (R² > 0.95)")
    print("   This suggests continuous charging rather than discrete integration")
    print("   Question: Is this really LIF behavior or just gradual polarization drift?")
    
elif r_squared > 0.8:
    print("⚠️  VERDICT: QUESTIONABLE STAIRCASE")
    print("   Mostly linear with some non-linearity")
    print("   May represent weak integration or measurement artifacts")
    
else:
    print("✅ VERDICT: POTENTIAL STAIRCASE")
    print("   Significant non-linearity suggests discrete integration steps")

print(f"\n📊 Key metrics for evaluation:")
print(f"   Linearity (R²): {r_squared:.3f} ({'Linear' if r_squared > 0.95 else 'Non-linear'})")
print(f"   Integration efficiency: {actual_per_pulse/expected_per_pulse*100:.1f}%")
print(f"   Final ΔVth: {simb_dvth[-1]:.1f} mV")
print(f"   Deviation from ideal: {abs(simb_dvth[-1] - 20*expected_per_pulse):.1f} mV")

print(f"\n🤔 Questions to consider:")
print(f"   1. Is the 'integration' just continuous polarization drift?")
print(f"   2. Are we measuring true discrete switching or gradual domain evolution?")
print(f"   3. Should we expect perfect staircase behavior in a real device?")
print(f"   4. Is the 68.9% efficiency due to physics or measurement limitations?")

print(f"\n📝 Recommendation:")
if r_squared > 0.95:
    print("   ⚠️  Re-examine the simulation setup and measurement methodology")
    print("   ⚠️  Consider whether τ_E = 1µs is too fast for discrete integration")
    print("   ⚠️  May need to adjust pulse parameters or measurement approach")
else:
    print("   ✅ Results show promise for LIF integration")
    print("   ✅ Proceed to SimC with leak and reset testing")

plt.show()
