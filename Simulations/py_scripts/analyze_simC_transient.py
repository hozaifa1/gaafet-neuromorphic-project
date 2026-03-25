"""
SimC Analysis — Full LIF Cycle Demonstration (τ_E = 1µs, Vpulse = 2.0V)
========================================================================
Analyzes simC runs with different reset voltages (-2V, -3V, -4V) to
demonstrate complete Integrate → Leak → Fire → Reset cycle.

Expected: 
1. Integration during 5 gate pulses
2. Leak during 1µs gaps between pulses  
3. Fire event after sufficient integration
4. Reset completeness vs Vreset amplitude
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

# ── LIF sequence files for each node ───────────────────────────────────────────
LIF_SEQUENCE = [
    "baseline_fwd",
    "lif_p1h", "lif_gap1", "lif_p2h", "lif_gap2", 
    "lif_p3h", "lif_gap3", "lif_p4h", "lif_gap4", "lif_p5h",
    "postpulse_fwd",
    "reset_fall", "reset_hold", "reset_rise",
    "postreset_fwd", "postreset_ret"
]

# ── Constants ─────────────────────────────────────────────────────────────────
VTH_BASE_V = -0.050
FC_MV_CM = 1.2
PR_UC_CM2 = 16.0
VPULSE = 2.0
VDS_READ = 0.05

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

def extract_dvth(post, base, vth_base=VTH_BASE_V):
    """Extract ΔVth from current ratio at VGS=0.003V probe point"""
    vgs_probe = base[VGS_COL][0]
    id_base = base[ID_COL][0]
    id_post = post[ID_COL][0]
    ratio = id_post / id_base
    vth_post = vgs_probe - ratio * (vgs_probe - vth_base)
    return (vth_base - vth_post) * 1e3   # mV

# ══════════════════════════════════════════════════════════════════════════════
# MAIN ANALYSIS
# ══════════════════════════════════════════════════════════════════════════════
print("=" * 80)
print("SimC Analysis — FULL LIF CYCLE (τ_E = 1µs, Vpulse = 2.0V)")
print("=" * 80)

# Parse all SimC nodes
simc_data = {}
for node in SIMC_NODES:
    node_dir = os.path.join(SIMC_DIR, node["dir"])
    node_data = {}
    
    print(f"\nParsing {node['tag']} (Vreset = {node['vreset']}V)...")
    
    for seq_name in LIF_SEQUENCE:
        filepath = os.path.join(node_dir, f"{seq_name}_{node['tag']}_des.plt")
        if os.path.exists(filepath):
            try:
                node_data[seq_name] = parse_plt(filepath)
            except Exception as e:
                print(f"  Warning: Could not parse {seq_name}: {e}")
                node_data[seq_name] = None
        else:
            print(f"  Missing: {seq_name}")
            node_data[seq_name] = None
    
    simc_data[node["tag"]] = {
        "vreset": node["vreset"],
        "data": node_data
    }

# ── ANALYSIS 1: Reset Completeness vs Vreset ───────────────────────────────────
print("\n" + "=" * 80)
print("ANALYSIS 1: RESET COMPLETENESS vs VRESET")
print("=" * 80)

reset_analysis = []
for node_tag, node_info in simc_data.items():
    vreset = node_info["vreset"]
    data = node_info["data"]
    
    baseline = data.get("baseline_fwd")
    postpulse = data.get("postpulse_fwd")
    postreset_fwd = data.get("postreset_fwd")
    postreset_ret = data.get("postreset_ret")
    
    if baseline and postpulse and postreset_fwd:
        # Calculate integration achieved
        dvth_integration = extract_dvth(postpulse, baseline)
        
        # Calculate reset recovery
        dvth_reset = extract_dvth(postreset_fwd, baseline)
        reset_completeness = (1 - dvth_reset/dvth_integration) * 100 if dvth_integration > 0 else 0
        
        # Get polarization values
        pol_baseline = baseline[POLY_COL][0] * 1e6 if baseline else np.nan
        pol_postpulse = postpulse[POLY_COL][0] * 1e6 if postpulse else np.nan
        pol_postreset = postreset_fwd[POLY_COL][0] * 1e6 if postreset_fwd else np.nan
        
        reset_analysis.append({
            "vreset": vreset,
            "tag": node_tag,
            "dvth_integration": dvth_integration,
            "dvth_reset": dvth_reset,
            "reset_completeness": reset_completeness,
            "pol_baseline": pol_baseline,
            "pol_postpulse": pol_postpulse,
            "pol_postreset": pol_postreset
        })
        
        print(f"{node_tag:>3} (Vreset={vreset:4.1f}V): "
              f"ΔVth_int={dvth_integration:6.1f}mV, "
              f"ΔVth_reset={dvth_reset:6.1f}mV, "
              f"Reset={reset_completeness:5.1f}%")

# ── ANALYSIS 2: LIF Waveform Analysis (Integration + Leak) ───────────────────
print("\n" + "=" * 80)
print("ANALYSIS 2: LIF WAVEFORM ANALYSIS (INTEGRATION + LEAK)")
print("=" * 80)

waveform_analysis = {}
for node_tag, node_info in simc_data.items():
    data = node_info["data"]
    
    # Extract pulse and gap data
    pulse_currents = []
    gap_currents = []
    pulse_times = []
    gap_times = []
    
    for i in range(1, 6):  # Pulses 1-5
        pulse_key = f"lif_p{i}h"
        gap_key = f"lif_gap{i}" if i < 5 else None
        
        if pulse_key in data and data[pulse_key] is not None:
            pulse_data = data[pulse_key]
            # Get current at end of pulse
            pulse_current = pulse_data[ID_COL][-1] * 1e6  # µA
            pulse_time = pulse_data[TIME_COL][-1] * 1e9   # ns
            pulse_currents.append(pulse_current)
            pulse_times.append(pulse_time)
        
        if gap_key and gap_key in data and data[gap_key] is not None:
            gap_data = data[gap_key]
            # Get current at start and end of gap
            gap_start = gap_data[ID_COL][0] * 1e6
            gap_end = gap_data[ID_COL][-1] * 1e6
            gap_duration = (gap_data[TIME_COL][-1] - gap_data[TIME_COL][0]) * 1e9  # ns
            leak_rate = (gap_start - gap_end) / gap_duration * 1e3  # µA/µs
            
            gap_currents.append({
                "start": gap_start,
                "end": gap_end,
                "leak_rate": leak_rate,
                "duration": gap_duration
            })
    
    waveform_analysis[node_tag] = {
        "pulse_currents": pulse_currents,
        "gap_currents": gap_currents,
        "pulse_times": pulse_times
    }
    
    print(f"\n{node_tag} Waveform:")
    print(f"  Pulse currents (µA): {[f'{c:.3f}' for c in pulse_currents]}")
    if gap_currents:
        avg_leak = np.mean([g["leak_rate"] for g in gap_currents])
        print(f"  Average leak rate: {avg_leak:.3f} µA/µs")

# ── ANALYSIS 3: Fire Event Detection ─────────────────────────────────────────
print("\n" + "=" * 80)
print("ANALYSIS 3: FIRE EVENT DETECTION")
print("=" * 80)

fire_analysis = {}
for node_tag, node_info in simc_data.items():
    data = node_info["data"]
    
    baseline = data.get("baseline_fwd")
    
    if baseline:
        # Get baseline current at operating point
        baseline_current = baseline[ID_COL][0] * 1e6  # µA
        
        # Look for current jumps in pulse sequence
        max_current = baseline_current
        fire_detected = False
        fire_pulse = None
        
        for i in range(1, 6):
            pulse_key = f"lif_p{i}h"
            if pulse_key in data and data[pulse_key] is not None:
                pulse_data = data[pulse_key]
                pulse_max = np.max(pulse_data[ID_COL]) * 1e6
                
                # Check for significant current jump (>2x baseline)
                if pulse_max > 2 * baseline_current:
                    fire_detected = True
                    fire_pulse = i
                    max_current = pulse_max
                    break
        
        fire_analysis[node_tag] = {
            "baseline_current": baseline_current,
            "max_current": max_current,
            "fire_detected": fire_detected,
            "fire_pulse": fire_pulse,
            "current_ratio": max_current / baseline_current
        }
        
        print(f"{node_tag}: Baseline={baseline_current:.3f}µA, "
              f"Max={max_current:.3f}µA, "
              f"Fire={'YES' if fire_detected else 'NO'} "
              + f"(pulse {fire_pulse})" if fire_detected else "")

# ── ANALYSIS 4: Polarization Dynamics ───────────────────────────────────────────
print("\n" + "=" * 80)
print("ANALYSIS 4: POLARIZATION DYNAMICS")
print("=" * 80)

pol_analysis = {}
for node_tag, node_info in simc_data.items():
    data = node_info["data"]
    
    baseline = data.get("baseline_fwd")
    postpulse = data.get("postpulse_fwd")
    postreset = data.get("postreset_fwd")
    
    if baseline and postpulse and postreset:
        pol_baseline = baseline[POLY_COL][0] * 1e6
        pol_postpulse = postpulse[POLY_COL][0] * 1e6
        pol_postreset = postreset[POLY_COL][0] * 1e6
        
        pol_shift_integration = pol_postpulse - pol_baseline
        pol_shift_reset = pol_postreset - pol_baseline
        pol_recovery = (1 - pol_shift_reset/pol_shift_integration) * 100 if pol_shift_integration != 0 else 0
        
        pol_analysis[node_tag] = {
            "baseline": pol_baseline,
            "postpulse": pol_postpulse,
            "postreset": pol_postreset,
            "integration_shift": pol_shift_integration,
            "reset_shift": pol_shift_reset,
            "recovery": pol_recovery
        }
        
        print(f"{node_tag}: Pol_baseline={pol_baseline:+.3f}, "
              f"Pol_postpulse={pol_postpulse:+.3f}, "
              f"Pol_postreset={pol_postreset:+.3f} µC/cm²")
        print(f"  Integration shift: {pol_shift_integration:+.3f} µC/cm²")
        print(f"  Recovery: {pol_recovery:.1f}%")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURES
# ══════════════════════════════════════════════════════════════════════════════
colors = plt.cm.plasma(np.linspace(0.1, 0.9, len(SIMC_NODES)))

# ── Fig 1: Reset Completeness vs Vreset ──
fig1, ax1 = plt.subplots(figsize=(8, 6))
vreset_vals = [ra["vreset"] for ra in reset_analysis]
reset_comp = [ra["reset_completeness"] for ra in reset_analysis]

bars = ax1.bar(vreset_vals, reset_comp, color=colors, alpha=0.7, edgecolor='black', linewidth=2)
ax1.set_xlabel("Reset Voltage Vreset (V)")
ax1.set_ylabel("Reset Completeness (%)")
ax1.set_title("SimC — Reset Completeness vs Reset Voltage")
ax1.grid(True, alpha=0.3, axis='y')

# Add value labels on bars
for bar, val in zip(bars, reset_comp):
    height = bar.get_height()
    ax1.text(bar.get_x() + bar.get_width()/2., height + 1,
             f'{val:.1f}%', ha='center', va='bottom', fontsize=10, fontweight='bold')

ax1.set_ylim(0, max(reset_comp) * 1.2 if reset_comp else 100)
fig1.tight_layout()
fig1.savefig(os.path.join(OUT_DIR, "simC_fig1_reset_completeness.png"), dpi=150)
print("\nSaved simC_fig1_reset_completeness.png")

# ── Fig 2: Full LIF Waveform (for best reset voltage) ──
best_node = max(reset_analysis, key=lambda x: x["reset_completeness"])["tag"]
fig2, ax2 = plt.subplots(figsize=(12, 6))

data_best = simc_data[best_node]["data"]
time_full = []
current_full = []

# Construct full timeline
current_time = 0
for i in range(1, 6):
    # Pulse
    pulse_key = f"lif_p{i}h"
    if pulse_key in data_best and data_best[pulse_key] is not None:
        pulse_data = data_best[pulse_key]
        t_pulse = pulse_data[TIME_COL] * 1e9
        i_pulse = pulse_data[ID_COL] * 1e6
        
        time_full.extend(current_time + t_pulse - t_pulse[0])
        current_full.extend(i_pulse)
        current_time = time_full[-1]
    
    # Gap (except after last pulse)
    if i < 5:
        gap_key = f"lif_gap{i}"
        if gap_key in data_best and data_best[gap_key] is not None:
            gap_data = data_best[gap_key]
            t_gap = gap_data[TIME_COL] * 1e9
            i_gap = gap_data[ID_COL] * 1e6
            
            time_full.extend(current_time + t_gap - t_gap[0])
            current_full.extend(i_gap)
            current_time = time_full[-1]

ax2.plot(time_full, current_full, 'b-', lw=2, label=f'LIF waveform ({best_node}, Vreset={simc_data[best_node]["vreset"]}V)')
ax2.set_xlabel("Time (ns)")
ax2.set_ylabel("I$_D$ (µA)")
ax2.set_title("SimC — Full LIF Waveform (Integration + Leak)")
ax2.grid(True, alpha=0.3)
ax2.legend(fontsize=10)

# Add annotations for key events
for i in range(1, 6):
    if i-1 < len(waveform_analysis[best_node]["pulse_times"]):
        pulse_time = waveform_analysis[best_node]["pulse_times"][i-1]
        ax2.axvline(x=pulse_time, color='red', alpha=0.3, linestyle='--')
        ax2.text(pulse_time, max(current_full)*0.9, f'P{i}', ha='center', fontsize=9)

fig2.tight_layout()
fig2.savefig(os.path.join(OUT_DIR, "simC_fig2_lif_waveform.png"), dpi=150)
print("Saved simC_fig2_lif_waveform.png")

# ── Fig 3: Integration and Reset Comparison ──
fig3, (ax3a, ax3b) = plt.subplots(1, 2, figsize=(14, 6))

# Panel A: ΔVth Integration vs Reset
node_tags = [ra["tag"] for ra in reset_analysis]
dvth_int = [ra["dvth_integration"] for ra in reset_analysis]
dvth_reset = [ra["dvth_reset"] for ra in reset_analysis]

x = np.arange(len(node_tags))
width = 0.35

ax3a.bar(x - width/2, dvth_int, width, label='ΔVth after Integration', color='green', alpha=0.7)
ax3a.bar(x + width/2, dvth_reset, width, label='ΔVth after Reset', color='orange', alpha=0.7)
ax3a.set_xlabel('Node (Vreset)')
ax3a.set_ylabel('ΔVth (mV)')
ax3a.set_title('Integration vs Reset ΔVth')
ax3a.set_xticks(x)
ax3a.set_xticklabels([f'{tag}\n({simc_data[tag]["vreset"]}V)' for tag in node_tags])
ax3a.legend()
ax3a.grid(True, alpha=0.3)

# Panel B: Polarization recovery
pol_recovery = [pol_analysis[tag]["recovery"] for tag in node_tags]
ax3b.bar(node_tags, pol_recovery, color=colors, alpha=0.7, edgecolor='black')
ax3b.set_xlabel('Node (Vreset)')
ax3b.set_ylabel('Polarization Recovery (%)')
ax3b.set_title('Polarization Recovery After Reset')
ax3b.set_xticks(node_tags)
ax3b.set_xticklabels([f'{tag}\n({simc_data[tag]["vreset"]}V)' for tag in node_tags])
ax3b.grid(True, alpha=0.3, axis='y')

fig3.tight_layout()
fig3.savefig(os.path.join(OUT_DIR, "simC_fig3_integration_reset.png"), dpi=150)
print("Saved simC_fig3_integration_reset.png")

# ── Fig 4: Fire Event Analysis ──
fig4, ax4 = plt.subplots(figsize=(8, 6))

fire_nodes = list(fire_analysis.keys())
current_ratios = [fire_analysis[tag]["current_ratio"] for tag in fire_nodes]
fire_colors = ['red' if fire_analysis[tag]["fire_detected"] else 'blue' for tag in fire_nodes]

bars = ax4.bar(fire_nodes, current_ratios, color=fire_colors, alpha=0.7, edgecolor='black', linewidth=2)
ax4.set_xlabel('Node (Vreset)')
ax4.set_ylabel('Current Ratio (Max/Baseline)')
ax4.set_title('SimC — Fire Event Detection')
ax4.grid(True, alpha=0.3, axis='y')

# Add fire detection labels
for bar, tag in zip(bars, fire_nodes):
    height = bar.get_height()
    fire_status = "FIRE" if fire_analysis[tag]["fire_detected"] else "NO FIRE"
    pulse_info = f" (P{fire_analysis[tag]['fire_pulse']})" if fire_analysis[tag]["fire_detected"] else ""
    ax4.text(bar.get_x() + bar.get_width()/2., height + 0.1,
             f'{fire_status}{pulse_info}', ha='center', va='bottom', fontsize=9, fontweight='bold')

ax4.axhline(y=2, color='red', linestyle='--', alpha=0.5, label='Fire Threshold (2x)')
ax4.legend()
fig4.tight_layout()
fig4.savefig(os.path.join(OUT_DIR, "simC_fig4_fire_detection.png"), dpi=150)
print("Saved simC_fig4_fire_detection.png")

# ══════════════════════════════════════════════════════════════════════════════
# VALIDATION & RECOMMENDATIONS
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "=" * 80)
print("VALIDATION & RECOMMENDATIONS")
print("=" * 80)

# Find best reset voltage
best_reset = max(reset_analysis, key=lambda x: x["reset_completeness"]) if reset_analysis else None

if best_reset:
    print(f"\n🎯 Best Reset Voltage: {best_reset['vreset']}V (Node {best_reset['tag']})")
    print(f"   Reset Completeness: {best_reset['reset_completeness']:.1f}%")
    print(f"   Integration ΔVth: {best_reset['dvth_integration']:.1f} mV")
    print(f"   Post-reset ΔVth: {best_reset['dvth_reset']:.1f} mV")

# Check fire events
fire_nodes = [tag for tag, info in fire_analysis.items() if info["fire_detected"]]
print(f"\n🔥 Fire Events Detected: {len(fire_nodes)}/{len(fire_analysis)} nodes")
for tag in fire_nodes:
    info = fire_analysis[tag]
    print(f"   {tag}: Pulse {info['fire_pulse']}, Ratio = {info['current_ratio']:.1f}x")

# Overall validation
good_reset = best_reset and best_reset["reset_completeness"] > 80
fire_detected = len(fire_nodes) > 0
integration_works = any(ra["dvth_integration"] > 50 for ra in reset_analysis)

print(f"\n✅ Validation Results:")
print(f"   Reset Mechanism: {'SUCCESS' if good_reset else 'NEEDS OPTIMIZATION'}")
print(f"   Fire Detection: {'SUCCESS' if fire_detected else 'FAILED'}")
print(f"   Integration: {'SUCCESS' if integration_works else 'FAILED'}")

# Extract LIF parameters for Step 2
if best_reset and integration_works:
    print(f"\n🧮 Extracted LIF Parameters (for Step 2):")
    
    # Integration parameters
    avg_dvth_per_pulse = best_reset["dvth_integration"] / 5  # 5 pulses
    print(f"   Integration weight: {avg_dvth_per_pulse:.2f} mV/pulse")
    
    # Reset parameters
    vreset_optimal = best_reset["vreset"]
    print(f"   Reset voltage: {vreset_optimal}V")
    print(f"   Reset completeness: {best_reset['reset_completeness']:.1f}%")
    
    # Time constants (from leak analysis)
    if best_node in waveform_analysis and waveform_analysis[best_node]["gap_currents"]:
        avg_leak = np.mean([g["leak_rate"] for g in waveform_analysis[best_node]["gap_currents"]])
        print(f"   Leak rate: {avg_leak:.3f} µA/µs")
    
    # Fire threshold
    if fire_nodes:
        fire_node = fire_nodes[0]
        fire_current = fire_analysis[fire_node]["max_current"]
        baseline_current = fire_analysis[fire_node]["baseline_current"]
        print(f"   Fire threshold: {fire_current:.3f} µA")
        print(f"   Fire ratio: {fire_current/baseline_current:.1f}x baseline")

print(f"\n🚀 Recommendations for Step 2:")
if good_reset and fire_detected and integration_works:
    print("   ✅ SimC SUCCESS - Full LIF cycle demonstrated")
    print("   ✅ Extract parameters above for Step_2_Circuit_Integration.md")
    print("   ✅ Consider τ_P tuning for desired leak time constant")
else:
    print("   ⚠️  Optimize reset voltage or pulse parameters")
    if not good_reset:
        print("   ⚠️  Try more negative reset voltage or longer reset duration")
    if not fire_detected:
        print("   ⚠️  Increase pulse amplitude or count for fire threshold")

print(f"\nNext steps:")
print("1. Update Step_2_Circuit_Integration.md with extracted parameters")
print("2. Implement τ_P > 0 for controlled leak dynamics")
print("3. Validate circuit model in Python SNN")
print("4. Test with ECG biomedical signals")

plt.show()
