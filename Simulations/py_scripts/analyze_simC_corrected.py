"""
SimC Analysis — CORRECTED Full LIF Cycle Analysis
================================================
Fixed version that properly extracts ΔVth from transient sweeps by
finding the same VGS point in baseline and post-pulse curves.

Key fix: Extract current at VGS=0.05V (drain bias) for both curves
"""

import re
import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm

# ── Paths ─────────────────────────────────────────────────────────────────────
BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
SIMC_DIR = os.path.join(BASE_DIR, "simC")
OUT_DIR = os.path.dirname(__file__)

# ── SimC reset voltage nodes ───────────────────────────────────────────────────
SIMC_NODES = [
    {"vreset": -2.0, "tag": "n3", "dir": "n3(-2V)"},
    {"vreset": -3.0, "tag": "n4", "dir": "n4(-3V)"},
    {"vreset": -4.0, "tag": "n5", "dir": "n5(-4V)"},
]

# ── Constants ─────────────────────────────────────────────────────────────────
VTH_BASE_V = -0.050
FC_MV_CM = 1.2
PR_UC_CM2 = 16.0
VPULSE = 2.0
VGS_PROBE = 0.05  # Extract current at this VGS value

# ── Column aliases ────────────────────────────────────────────────────────────
VGS_COL = "gate_contact OuterVoltage"
ID_COL = "drain_contact TotalCurrent"
TIME_COL = "time"
POLY_COL = "Pos(0,0.0145) Polarization/y"
EY_COL = "Pos(0,0.0145) ElectricField/y"

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

def extract_current_at_vgs(data, vgs_target=VGS_PROBE):
    """Extract drain current at specific VGS value from transient sweep"""
    vgs_vals = data[VGS_COL]
    id_vals = data[ID_COL]
    
    # Find closest VGS value
    idx = np.argmin(np.abs(vgs_vals - vgs_target))
    return id_vals[idx], vgs_vals[idx]

def extract_dvth_transient(post, base, vgs_probe=VGS_PROBE, vth_base=VTH_BASE_V):
    """Extract ΔVth from current ratio at specific VGS point"""
    id_base, vgs_base_actual = extract_current_at_vgs(base, vgs_probe)
    id_post, vgs_post_actual = extract_current_at_vgs(post, vgs_probe)
    
    # Use actual VGS value (should be very close to target)
    vgs_actual = vgs_base_actual
    
    ratio = id_post / id_base
    vth_post = vgs_actual - ratio * (vgs_actual - vth_base)
    return (vth_base - vth_post) * 1e3   # mV

# ══════════════════════════════════════════════════════════════════════════════
# MAIN ANALYSIS
# ══════════════════════════════════════════════════════════════════════════════
print("=" * 80)
print("SimC Analysis — CORRECTED LIF CYCLE (τ_E = 1µs, Vpulse = 2.0V)")
print("=" * 80)

# Parse all SimC nodes
simc_data = {}
for node in SIMC_NODES:
    node_dir = os.path.join(SIMC_DIR, node["dir"])
    node_data = {}
    
    print(f"\nParsing {node['tag']} (Vreset = {node['vreset']}V)...")
    
    # Key files for LIF analysis
    key_files = [
        "baseline_fwd", "postpulse_fwd", "postreset_fwd", "postreset_ret",
        "lif_p1h", "lif_p2h", "lif_p3h", "lif_p4h", "lif_p5h",
        "lif_gap1", "lif_gap2", "lif_gap3", "lif_gap4"
    ]
    
    for file_name in key_files:
        filepath = os.path.join(node_dir, f"{file_name}_{node['tag']}_des.plt")
        if os.path.exists(filepath):
            try:
                node_data[file_name] = parse_plt(filepath)
            except Exception as e:
                print(f"  Warning: Could not parse {file_name}: {e}")
                node_data[file_name] = None
        else:
            node_data[file_name] = None
    
    simc_data[node["tag"]] = {
        "vreset": node["vreset"],
        "data": node_data
    }

# ── ANALYSIS 1: Integration and Reset Analysis (CORRECTED) ─────────────────────
print("\n" + "=" * 80)
print("ANALYSIS 1: INTEGRATION AND RESET (CORRECTED)")
print("=" * 80)

integration_analysis = []
for node_tag, node_info in simc_data.items():
    vreset = node_info["vreset"]
    data = node_info["data"]
    
    baseline = data.get("baseline_fwd")
    postpulse = data.get("postpulse_fwd")
    postreset = data.get("postreset_fwd")
    
    if baseline and postpulse and postreset:
        # Extract currents at VGS=0.05V
        id_base, vgs_actual = extract_current_at_vgs(baseline, VGS_PROBE)
        id_post, _ = extract_current_at_vgs(postpulse, VGS_PROBE)
        id_reset, _ = extract_current_at_vgs(postreset, VGS_PROBE)
        
        # Calculate ΔVth properly
        dvth_integration = extract_dvth_transient(postpulse, baseline, VGS_PROBE)
        dvth_reset = extract_dvth_transient(postreset, baseline, VGS_PROBE)
        
        # Reset completeness
        reset_completeness = (1 - dvth_reset/dvth_integration) * 100 if dvth_integration > 0 else 0
        
        # Current ratios
        current_ratio_integration = id_post / id_base
        current_ratio_reset = id_reset / id_base
        
        integration_analysis.append({
            "vreset": vreset,
            "tag": node_tag,
            "id_base": id_base * 1e6,  # µA
            "id_post": id_post * 1e6,  # µA
            "id_reset": id_reset * 1e6,  # µA
            "dvth_integration": dvth_integration,
            "dvth_reset": dvth_reset,
            "reset_completeness": reset_completeness,
            "current_ratio_integration": current_ratio_integration,
            "current_ratio_reset": current_ratio_reset
        })
        
        print(f"{node_tag:>3} (Vreset={vreset:4.1f}V):")
        print(f"  ID_base: {id_base*1e6:.3f} µA, ID_post: {id_post*1e6:.3f} µA, ID_reset: {id_reset*1e6:.3f} µA")
        print(f"  ΔVth_integration: {dvth_integration:.1f} mV")
        print(f"  ΔVth_reset: {dvth_reset:.1f} mV")
        print(f"  Reset completeness: {reset_completeness:.1f}%")
        print(f"  Current ratio: {current_ratio_integration:.1f}x integration, {current_ratio_reset:.1f}x reset")

# ── ANALYSIS 2: Pulse-by-Pulse Integration Dynamics ─────────────────────────
print("\n" + "=" * 80)
print("ANALYSIS 2: PULSE-BY-PULSE INTEGRATION DYNAMICS")
print("=" * 80)

pulse_dynamics = {}
for node_tag, node_info in simc_data.items():
    data = node_info["data"]
    
    pulse_currents = []
    pulse_pols = []
    
    for i in range(1, 6):
        pulse_key = f"lif_p{i}h"
        if pulse_key in data and data[pulse_key]:
            pulse_data = data[pulse_key]
            
            # Extract current and polarization at end of pulse
            id_end = pulse_data[ID_COL][-1] * 1e6  # µA
            pol_end = pulse_data[POLY_COL][-1] * 1e6  # µC/cm²
            
            pulse_currents.append(id_end)
            pulse_pols.append(pol_end)
    
    pulse_dynamics[node_tag] = {
        "pulse_currents": pulse_currents,
        "pulse_pols": pulse_pols
    }
    
    print(f"\n{node_tag} Pulse Dynamics:")
    print(f"  Pulse currents (µA): {[f'{c:.3f}' for c in pulse_currents]}")
    print(f"  Pulse polarization (µC/cm²): {[f'{p:+.3f}' for p in pulse_pols]}")
    
    if len(pulse_currents) > 1:
        current_growth = (pulse_currents[-1] - pulse_currents[0]) / pulse_currents[0] * 100
        pol_shift = pulse_pols[-1] - pulse_pols[0]
        print(f"  Current growth: {current_growth:.1f}%")
        print(f"  Total polarization shift: {pol_shift:+.3f} µC/cm²")

# ── ANALYSIS 3: Leak Dynamics During Gaps ─────────────────────────────────────
print("\n" + "=" * 80)
print("ANALYSIS 3: LEAK DYNAMICS DURING GAPS")
print("=" * 80)

leak_analysis = {}
for node_tag, node_info in simc_data.items():
    data = node_info["data"]
    
    leak_rates = []
    
    for i in range(1, 5):  # Gaps 1-4
        gap_key = f"lif_gap{i}"
        if gap_key in data and data[gap_key]:
            gap_data = data[gap_key]
            
            # Extract leak rate
            id_start = gap_data[ID_COL][0] * 1e6  # µA
            id_end = gap_data[ID_COL][-1] * 1e6  # µA
            time_start = gap_data[TIME_COL][0] * 1e9  # ns
            time_end = gap_data[TIME_COL][-1] * 1e9  # ns
            
            duration_us = (time_end - time_start) / 1000  # µs
            leak_current = id_start - id_end  # µA decrease
            leak_rate = leak_current / duration_us if duration_us > 0 else 0  # µA/µs
            
            leak_rates.append(leak_rate)
    
    leak_analysis[node_tag] = leak_rates
    avg_leak = np.mean(leak_rates) if leak_rates else 0
    
    print(f"{node_tag} Leak Analysis:")
    print(f"  Leak rates (µA/µs): {[f'{r:.3f}' for r in leak_rates]}")
    print(f"  Average leak rate: {avg_leak:.3f} µA/µs")

# ── ANALYSIS 4: Fire Event Characterization ─────────────────────────────────────
print("\n" + "=" * 80)
print("ANALYSIS 4: FIRE EVENT CHARACTERIZATION")
print("=" * 80)

fire_analysis = {}
for node_tag, node_info in simc_data.items():
    data = node_info["data"]
    
    baseline = data.get("baseline_fwd")
    if baseline:
        # Get baseline current at operating point
        id_base, _ = extract_current_at_vgs(baseline, VGS_PROBE)
        id_base_ua = id_base * 1e6
        
        # Find maximum current in pulse sequence
        max_current = id_base_ua
        fire_pulse = None
        
        for i in range(1, 6):
            pulse_key = f"lif_p{i}h"
            if pulse_key in data and data[pulse_key]:
                pulse_data = data[pulse_key]
                pulse_max = np.max(pulse_data[ID_COL]) * 1e6
                
                if pulse_max > max_current:
                    max_current = pulse_max
                    fire_pulse = i
        
        # Fire detection criteria
        fire_detected = max_current > 2 * id_base_ua
        current_ratio = max_current / id_base_ua
        
        fire_analysis[node_tag] = {
            "baseline_current": id_base_ua,
            "max_current": max_current,
            "fire_detected": fire_detected,
            "fire_pulse": fire_pulse,
            "current_ratio": current_ratio
        }
        
        print(f"{node_tag}:")
        print(f"  Baseline: {id_base_ua:.3f} µA")
        print(f"  Maximum: {max_current:.3f} µA")
        print(f"  Fire: {'YES' if fire_detected else 'NO'} (pulse {fire_pulse}, ratio={current_ratio:.1f}x)")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURES
# ══════════════════════════════════════════════════════════════════════════════
colors = plt.cm.plasma(np.linspace(0.1, 0.9, len(SIMC_NODES)))

# ── Fig 1: Corrected Integration and Reset Analysis ──
fig1, (ax1a, ax1b) = plt.subplots(1, 2, figsize=(14, 6))

# Panel A: ΔVth Integration vs Reset
node_tags = [ia["tag"] for ia in integration_analysis]
dvth_int = [ia["dvth_integration"] for ia in integration_analysis]
dvth_reset = [ia["dvth_reset"] for ia in integration_analysis]

x = np.arange(len(node_tags))
width = 0.35

ax1a.bar(x - width/2, dvth_int, width, label='ΔVth after Integration', color='green', alpha=0.7)
ax1a.bar(x + width/2, dvth_reset, width, label='ΔVth after Reset', color='orange', alpha=0.7)
ax1a.set_xlabel('Node (Vreset)')
ax1a.set_ylabel('ΔVth (mV)')
ax1a.set_title('Integration vs Reset ΔVth (CORRECTED)')
ax1a.set_xticks(x)
ax1a.set_xticklabels([f'{tag}\n({simc_data[tag]["vreset"]}V)' for tag in node_tags])
ax1a.legend()
ax1a.grid(True, alpha=0.3)

# Panel B: Current Ratios
current_ratios_int = [ia["current_ratio_integration"] for ia in integration_analysis]
current_ratios_reset = [ia["current_ratio_reset"] for ia in integration_analysis]

ax1b.bar(x - width/2, current_ratios_int, width, label='Integration Ratio', color='blue', alpha=0.7)
ax1b.bar(x + width/2, current_ratios_reset, width, label='Reset Ratio', color='red', alpha=0.7)
ax1b.set_xlabel('Node (Vreset)')
ax1b.set_ylabel('Current Ratio (I/I_base)')
ax1b.set_title('Current Ratios at VGS=0.05V')
ax1b.set_xticks(x)
ax1b.set_xticklabels([f'{tag}\n({simc_data[tag]["vreset"]}V)' for tag in node_tags])
ax1b.legend()
ax1b.grid(True, alpha=0.3)

fig1.tight_layout()
fig1.savefig(os.path.join(OUT_DIR, "simC_corrected_fig1_integration_reset.png"), dpi=150)
print("\nSaved simC_corrected_fig1_integration_reset.png")

# ── Fig 2: Pulse-by-Pulse Integration Dynamics ──
fig2, (ax2a, ax2b) = plt.subplots(1, 2, figsize=(14, 6))

# Panel A: Current Evolution
for i, (node_tag, dynamics) in enumerate(pulse_dynamics.items()):
    pulse_nums = list(range(1, len(dynamics["pulse_currents"]) + 1))
    ax2a.plot(pulse_nums, dynamics["pulse_currents"], 'o-', 
             color=colors[i], lw=2, ms=8, label=f'{node_tag} (Vreset={simc_data[node_tag]["vreset"]}V)')

ax2a.set_xlabel('Pulse Number')
ax2a.set_ylabel('End-of-Pulse Current (µA)')
ax2a.set_title('Current Evolution During Integration')
ax2a.legend(fontsize=9)
ax2a.grid(True, alpha=0.3)

# Panel B: Polarization Evolution
for i, (node_tag, dynamics) in enumerate(pulse_dynamics.items()):
    pulse_nums = list(range(1, len(dynamics["pulse_pols"]) + 1))
    ax2b.plot(pulse_nums, dynamics["pulse_pols"], 's-', 
             color=colors[i], lw=2, ms=8, label=f'{node_tag}')

ax2b.set_xlabel('Pulse Number')
ax2b.set_ylabel('End-of-Pulse Polarization (µC/cm²)')
ax2b.set_title('Polarization Evolution During Integration')
ax2b.legend(fontsize=9)
ax2b.grid(True, alpha=0.3)
ax2b.axhline(y=0, color='black', linestyle='--', alpha=0.3)

fig2.tight_layout()
fig2.savefig(os.path.join(OUT_DIR, "simC_corrected_fig2_pulse_dynamics.png"), dpi=150)
print("Saved simC_corrected_fig2_pulse_dynamics.png")

# ── Fig 3: Leak Dynamics and Fire Events ──
fig3, (ax3a, ax3b) = plt.subplots(1, 2, figsize=(14, 6))

# Panel A: Leak Rates
for i, (node_tag, leak_rates) in enumerate(leak_analysis.items()):
    gap_nums = list(range(1, len(leak_rates) + 1))
    ax3a.plot(gap_nums, leak_rates, 'o-', color=colors[i], lw=2, ms=8,
             label=f'{node_tag} (avg={np.mean(leak_rates):.3f} µA/µs)')

ax3a.set_xlabel('Gap Number')
ax3a.set_ylabel('Leak Rate (µA/µs)')
ax3a.set_title('Leak Dynamics During Inter-Pulse Gaps')
ax3a.legend(fontsize=9)
ax3a.grid(True, alpha=0.3)

# Panel B: Fire Detection
fire_nodes = list(fire_analysis.keys())
fire_ratios = [fire_analysis[tag]["current_ratio"] for tag in fire_nodes]
fire_colors = ['red' if fire_analysis[tag]["fire_detected"] else 'blue' for tag in fire_nodes]

bars = ax3b.bar(fire_nodes, fire_ratios, color=fire_colors, alpha=0.7, edgecolor='black', linewidth=2)
ax3b.set_xlabel('Node (Vreset)')
ax3b.set_ylabel('Current Ratio (Max/Baseline)')
ax3b.set_title('Fire Event Detection')
ax3b.grid(True, alpha=0.3, axis='y')

# Add fire detection labels
for bar, tag in zip(bars, fire_nodes):
    height = bar.get_height()
    fire_status = "FIRE" if fire_analysis[tag]["fire_detected"] else "NO FIRE"
    pulse_info = f" (P{fire_analysis[tag]['fire_pulse']})" if fire_analysis[tag]["fire_detected"] else ""
    ax3b.text(bar.get_x() + bar.get_width()/2., height + 0.5,
             f'{fire_status}{pulse_info}', ha='center', va='bottom', fontsize=9, fontweight='bold')

ax3b.axhline(y=2, color='red', linestyle='--', alpha=0.5, label='Fire Threshold (2x)')
ax3b.legend()
ax3b.set_xticklabels([f'{tag}\n({simc_data[tag]["vreset"]}V)' for tag in fire_nodes])

fig3.tight_layout()
fig3.savefig(os.path.join(OUT_DIR, "simC_corrected_fig3_leak_fire.png"), dpi=150)
print("Saved simC_corrected_fig3_leak_fire.png")

# ── Fig 4: Complete LIF Cycle Summary ──
fig4, ax4 = plt.subplots(figsize=(10, 6))

# Create summary metrics for each node
summary_metrics = []
for node_tag in node_tags:
    ia = next(item for item in integration_analysis if item["tag"] == node_tag)
    fa = fire_analysis[node_tag]
    la = leak_analysis[node_tag]
    
    summary_metrics.append({
        "tag": node_tag,
        "vreset": ia["vreset"],
        "integration_dvth": ia["dvth_integration"],
        "reset_completeness": ia["reset_completeness"],
        "fire_ratio": fa["current_ratio"],
        "avg_leak": np.mean(la) if la else 0
    })

# Plot integration ΔVth vs reset completeness
for i, metric in enumerate(summary_metrics):
    ax4.scatter(metric["reset_completeness"], metric["integration_dvth"], 
               s=200, c=colors[i], alpha=0.7, edgecolor='black', linewidth=2,
               label=f'{metric["tag"]} ({metric["vreset"]}V)')
    
    # Add fire ratio as text
    ax4.text(metric["reset_completeness"], metric["integration_dvth"] + 5,
             f'Fire: {metric["fire_ratio"]:.1f}x', ha='center', fontsize=9)

ax4.set_xlabel('Reset Completeness (%)')
ax4.set_ylabel('Integration ΔVth (mV)')
ax4.set_title('LIF Cycle Performance Summary')
ax4.legend(fontsize=10)
ax4.grid(True, alpha=0.3)

# Add performance regions
ax4.axhline(y=50, color='green', linestyle='--', alpha=0.3, label='Target Integration')
ax4.axvline(x=80, color='blue', linestyle='--', alpha=0.3, label='Target Reset')
ax4.legend(fontsize=9)

fig4.tight_layout()
fig4.savefig(os.path.join(OUT_DIR, "simC_corrected_fig4_summary.png"), dpi=150)
print("Saved simC_corrected_fig4_summary.png")

# ══════════════════════════════════════════════════════════════════════════════
# VALIDATION & RECOMMENDATIONS
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "=" * 80)
print("VALIDATION & RECOMMENDATIONS")
print("=" * 80)

# Find best performing node
best_node = max(integration_analysis, key=lambda x: x["dvth_integration"]) if integration_analysis else None

if best_node:
    print(f"\n🎯 Best Integration: Node {best_node['tag']} (Vreset = {best_node['vreset']}V)")
    print(f"   Integration ΔVth: {best_node['dvth_integration']:.1f} mV")
    print(f"   Reset completeness: {best_node['reset_completeness']:.1f}%")
    print(f"   Current ratio: {best_node['current_ratio_integration']:.1f}x")

# Check fire events
fire_nodes = [tag for tag, info in fire_analysis.items() if info["fire_detected"]]
print(f"\n🔥 Fire Events: {len(fire_nodes)}/{len(fire_analysis)} nodes show fire behavior")

# Overall validation
good_integration = any(ia["dvth_integration"] > 50 for ia in integration_analysis)
good_reset = any(ia["reset_completeness"] > 80 for ia in integration_analysis)
fire_detected = len(fire_nodes) > 0

print(f"\n✅ SimC Validation Results:")
print(f"   Integration (>50mV): {'SUCCESS' if good_integration else 'FAILED'}")
print(f"   Reset (>80%): {'SUCCESS' if good_reset else 'NEEDS OPTIMIZATION'}")
print(f"   Fire detection: {'SUCCESS' if fire_detected else 'FAILED'}")

# Extract LIF parameters for Step 2
if best_node and good_integration:
    print(f"\n🧮 Extracted LIF Parameters for Step_2_Circuit_Integration.md:")
    
    # Integration parameters
    avg_dvth_per_pulse = best_node["dvth_integration"] / 5  # 5 pulses
    print(f"   Integration weight: {avg_dvth_per_pulse:.2f} mV/pulse")
    
    # Reset parameters
    best_reset_node = max(integration_analysis, key=lambda x: x["reset_completeness"])
    print(f"   Optimal reset voltage: {best_reset_node['vreset']}V")
    print(f"   Reset completeness: {best_reset_node['reset_completeness']:.1f}%")
    
    # Fire parameters
    if fire_nodes:
        fire_node = fire_nodes[0]
        fire_info = fire_analysis[fire_node]
        print(f"   Fire threshold current: {fire_info['max_current']:.3f} µA")
        print(f"   Fire ratio: {fire_info['current_ratio']:.1f}x baseline")
    
    # Leak parameters
    if best_node["tag"] in leak_analysis:
        avg_leak = np.mean(leak_analysis[best_node["tag"]]) if leak_analysis[best_node["tag"]] else 0
        print(f"   Average leak rate: {avg_leak:.3f} µA/µs")
    
    # Time constant estimation (if τ_P > 0 in future runs)
    print(f"   Note: τ_P not characterized (set to 0 in current runs)")

print(f"\n🚀 Recommendations for Step 2:")
if good_integration and fire_detected:
    print("   ✅ SimC demonstrates partial LIF behavior")
    print("   ✅ Use extracted parameters for circuit model")
    print("   ⚠️  Integration ΔVth lower than expected - consider:")
    print("      - Increasing pulse amplitude (>2.0V)")
    print("      - Increasing pulse count (>5 pulses)")
    print("      - Reducing τ_E for faster switching")
else:
    print("   ⚠️  Optimize simC parameters before proceeding:")
    if not good_integration:
        print("   ⚠️  Increase Vpulse or pulse count for larger ΔVth")
    if not fire_detected:
        print("   ⚠️  Check fire threshold criteria")
    if not good_reset:
        print("   ⚠️  Use more negative reset voltage")

print(f"\nNext steps:")
print("1. Update Step_2_Circuit_Integration.md with corrected parameters")
print("2. Implement τ_P > 0 for controlled leak dynamics")
print("3. Consider re-running simC with optimized parameters")
print("4. Validate complete circuit model in Python SNN")

plt.show()
