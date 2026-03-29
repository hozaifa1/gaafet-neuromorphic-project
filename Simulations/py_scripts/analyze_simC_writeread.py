"""
SimC v2 Analysis — Write-Then-Read LIF Fire Demonstration
==========================================================
Analyzes output from sdevice_simC_writeread.cmd.
Extracts ID at constant VGS_read=0.20V after each write pulse to
demonstrate integration→fire→reset at a single operating point.

Key improvement over analyze_simC_corrected.py:
- All current comparisons are at the SAME VGS (VGS_read=0.20V)
- Fire = ID at VGS_read crosses a threshold due to Vth shifting past VGS_read
- No bogus comparisons between different VGS operating points
"""

import re
import os
import sys
import numpy as np
import matplotlib.pyplot as plt

# ── Paths ─────────────────────────────────────────────────────────────────────
BASE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SIMC_DIR = os.path.join(BASE_DIR, "simC")
OUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ── SimC v2 reset voltage nodes ──────────────────────────────────────────────
SIMC_NODES = [
    {"vreset": -2.0, "tag": "n3", "dir": "n3(-2V)"},
    {"vreset": -3.0, "tag": "n4", "dir": "n4(-3V)"},
    {"vreset": -4.0, "tag": "n5", "dir": "n5(-4V)"},
]

# ── Constants ─────────────────────────────────────────────────────────────────
VGS_READ = 0.20       # V — constant read bias
VPULSE = 2.0          # V — write pulse amplitude
VTH_VIRGIN = 0.263    # V — from calibration
SS_MVDEC = 60.8       # mV/dec — subthreshold slope
N_PULSES = 10         # Number of write-then-read cycles
FIRE_RATIO = 2.0      # Fire threshold: ID > FIRE_RATIO * ID_baseline

# ── Column aliases ────────────────────────────────────────────────────────────
VGS_COL = "gate_contact OuterVoltage"
ID_COL = "drain_contact TotalCurrent"
TIME_COL = "time"
POLY_COL = "Pos(0,0.0145) Polarization/y"
EY_COL = "Pos(0,0.0145) ElectricField/y"

# ── Parser ────────────────────────────────────────────────────────────────────
def parse_plt(filepath):
    """Parse Sentaurus .plt file into dict of numpy arrays."""
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


def safe_parse(filepath):
    """Parse a .plt file, returning None if file not found."""
    if not os.path.exists(filepath):
        print(f"  [SKIP] File not found: {filepath}")
        return None
    try:
        return parse_plt(filepath)
    except Exception as e:
        print(f"  [ERROR] Failed to parse {filepath}: {e}")
        return None


def extract_steady_current(data):
    """Extract the final (steady-state) drain current from a read phase."""
    if data is None:
        return np.nan
    id_vals = data[ID_COL]
    return id_vals[-1]


def extract_mean_current(data):
    """Extract the mean drain current from a read phase (last 50%)."""
    if data is None:
        return np.nan
    id_vals = data[ID_COL]
    n = len(id_vals)
    return np.mean(id_vals[n//2:])


def extract_polarization(data):
    """Extract the final polarization value."""
    if data is None:
        return np.nan
    if POLY_COL not in data:
        return np.nan
    return data[POLY_COL][-1]


# ══════════════════════════════════════════════════════════════════════════════
#  MAIN ANALYSIS
# ══════════════════════════════════════════════════════════════════════════════
print("=" * 70)
print("SimC v2 — Write-Then-Read LIF Fire Analysis")
print("=" * 70)

all_results = {}

for node in SIMC_NODES:
    tag = node["tag"]
    vreset = node["vreset"]
    node_dir = os.path.join(SIMC_DIR, node["dir"])

    print(f"\n{'─'*60}")
    print(f"Node {tag} (Vreset = {vreset}V)")
    print(f"{'─'*60}")

    if not os.path.isdir(node_dir):
        print(f"  [SKIP] Directory not found: {node_dir}")
        continue

    # ── Parse baseline read ──────────────────────────────────────────────
    baseline_data = safe_parse(os.path.join(node_dir, f"baseline_read_{tag}_des.plt"))
    id_baseline = extract_steady_current(baseline_data)
    pol_baseline = extract_polarization(baseline_data)

    print(f"  Baseline ID at VGS_read={VGS_READ}V: {id_baseline*1e6:.3f} uA")
    print(f"  Baseline Polarization/y: {pol_baseline*1e6:.3f} uC/cm2")

    # ── Parse each pulse read phase ──────────────────────────────────────
    pulse_ids = []
    pulse_pols = []
    write_ids = []
    write_pols = []

    for p in range(1, N_PULSES + 1):
        prefix = f"p{p:02d}"

        # Read phase (ID at VGS_read after write pulse — KEY DATA)
        read_data = safe_parse(os.path.join(node_dir, f"{prefix}_read_{tag}_des.plt"))
        id_read = extract_steady_current(read_data)
        pol_read = extract_polarization(read_data)
        pulse_ids.append(id_read)
        pulse_pols.append(pol_read)

        # Write phase (ID during pulse hold at VGS=2V — secondary data)
        write_data = safe_parse(os.path.join(node_dir, f"{prefix}_write_{tag}_des.plt"))
        id_write = extract_steady_current(write_data)
        pol_write = extract_polarization(write_data)
        write_ids.append(id_write)
        write_pols.append(pol_write)

    pulse_ids = np.array(pulse_ids)
    pulse_pols = np.array(pulse_pols)
    write_ids = np.array(write_ids)
    write_pols = np.array(write_pols)

    # ── Parse leak gap ───────────────────────────────────────────────────
    leak_data = safe_parse(os.path.join(node_dir, f"leak_gap_{tag}_des.plt"))
    if leak_data is not None:
        leak_times = leak_data[TIME_COL]
        leak_currents = leak_data[ID_COL]
        id_leak_start = leak_currents[0]
        id_leak_end = leak_currents[-1]
        leak_duration = leak_times[-1] - leak_times[0]
        print(f"  Leak gap: ID {id_leak_start*1e6:.3f} -> {id_leak_end*1e6:.3f} uA "
              f"over {leak_duration*1e6:.2f} us")
        if leak_duration > 0:
            leak_rate = (id_leak_start - id_leak_end) / leak_duration
            print(f"  Leak rate: {leak_rate*1e6:.3f} uA/us")
    else:
        id_leak_start = np.nan
        id_leak_end = np.nan
        leak_rate = np.nan

    # ── Parse reset + post-reset read ────────────────────────────────────
    postreset_data = safe_parse(os.path.join(node_dir, f"postreset_read_{tag}_des.plt"))
    id_postreset = extract_steady_current(postreset_data)
    pol_postreset = extract_polarization(postreset_data)

    # ── Analysis ─────────────────────────────────────────────────────────

    # 1. Integration: ID at VGS_read should increase with each pulse
    print(f"\n  --- Integration (ID at VGS_read={VGS_READ}V) ---")
    print(f"  {'Pulse':>5s}  {'ID_read (uA)':>12s}  {'Ratio':>8s}  {'Pol/y (uC/cm2)':>14s}")
    print(f"  {'─'*45}")
    print(f"  {'base':>5s}  {id_baseline*1e6:12.3f}  {1.0:8.2f}  {pol_baseline*1e6:14.3f}")
    for p in range(N_PULSES):
        ratio = pulse_ids[p] / id_baseline if id_baseline != 0 else np.nan
        print(f"  {p+1:5d}  {pulse_ids[p]*1e6:12.3f}  {ratio:8.2f}  {pulse_pols[p]*1e6:14.3f}")

    # 2. Fire detection: when does ID exceed threshold?
    fire_threshold = FIRE_RATIO * id_baseline
    fire_pulse = None
    for p in range(N_PULSES):
        if pulse_ids[p] > fire_threshold:
            fire_pulse = p + 1
            break

    print(f"\n  --- Fire Detection ---")
    print(f"  Fire threshold: {fire_threshold*1e6:.3f} uA ({FIRE_RATIO}x baseline)")
    if fire_pulse is not None:
        print(f"  FIRE at pulse {fire_pulse}: "
              f"ID = {pulse_ids[fire_pulse-1]*1e6:.3f} uA "
              f"({pulse_ids[fire_pulse-1]/id_baseline:.2f}x baseline)")
    else:
        print(f"  NO FIRE detected in {N_PULSES} pulses")
        if len(pulse_ids) > 0 and not np.isnan(pulse_ids[-1]):
            print(f"  Max ratio achieved: {pulse_ids[-1]/id_baseline:.2f}x at pulse {N_PULSES}")

    # 3. Reset completeness
    if not np.isnan(id_postreset) and not np.isnan(id_baseline):
        reset_ratio = id_postreset / id_baseline
        reset_completeness = 1.0 - abs(reset_ratio - 1.0)
        print(f"\n  --- Reset ---")
        print(f"  Post-reset ID: {id_postreset*1e6:.3f} uA "
              f"(baseline: {id_baseline*1e6:.3f} uA)")
        print(f"  Reset completeness: {reset_completeness*100:.1f}%")
    else:
        reset_completeness = np.nan
        print(f"\n  --- Reset ---")
        print(f"  Data not available")

    # 4. ΔVth estimation from current ratio (using SS)
    print(f"\n  --- Estimated ΔVth from Current Ratios ---")
    for p in range(N_PULSES):
        if pulse_ids[p] > 0 and id_baseline > 0:
            ratio = pulse_ids[p] / id_baseline
            if ratio > 0:
                dvth_mv = SS_MVDEC * np.log10(ratio)
                print(f"  Pulse {p+1:2d}: ratio={ratio:.3f}x -> "
                      f"ΔVth ≈ {dvth_mv:.1f} mV")

    # Store results
    all_results[tag] = {
        "vreset": vreset,
        "id_baseline": id_baseline,
        "pulse_ids": pulse_ids,
        "pulse_pols": pulse_pols,
        "write_ids": write_ids,
        "write_pols": write_pols,
        "fire_pulse": fire_pulse,
        "fire_threshold": fire_threshold,
        "id_postreset": id_postreset,
        "reset_completeness": reset_completeness,
        "id_leak_start": id_leak_start if 'id_leak_start' in dir() else np.nan,
        "id_leak_end": id_leak_end if 'id_leak_end' in dir() else np.nan,
    }


# ══════════════════════════════════════════════════════════════════════════════
#  PLOTTING
# ══════════════════════════════════════════════════════════════════════════════

if not all_results:
    print("\nNo data found. Exiting.")
    sys.exit(0)

colors = {"n3": "tab:blue", "n4": "tab:orange", "n5": "tab:red"}

# ── Figure 1: ID at VGS_read vs Pulse Number (Integration + Fire) ────────
fig1, (ax1a, ax1b) = plt.subplots(1, 2, figsize=(14, 5))

for tag, res in all_results.items():
    if np.isnan(res["id_baseline"]):
        continue
    pulses = np.arange(0, N_PULSES + 1)
    ids_ua = np.concatenate([[res["id_baseline"]], res["pulse_ids"]]) * 1e6
    ratios = ids_ua / (res["id_baseline"] * 1e6)

    ax1a.plot(pulses, ids_ua, 'o-', color=colors.get(tag, 'k'),
              label=f'{tag} (Vreset={res["vreset"]}V)', markersize=5)
    ax1b.plot(pulses, ratios, 's-', color=colors.get(tag, 'k'),
              label=f'{tag}', markersize=5)

    if res["fire_pulse"] is not None:
        ax1a.axvline(res["fire_pulse"], color=colors.get(tag, 'k'),
                     ls='--', alpha=0.5)
        ax1b.axvline(res["fire_pulse"], color=colors.get(tag, 'k'),
                     ls='--', alpha=0.5)

# Fire threshold line
ax1b.axhline(FIRE_RATIO, color='gray', ls=':', label=f'Fire threshold ({FIRE_RATIO}x)')

ax1a.set_xlabel("Pulse Number")
ax1a.set_ylabel(f"ID at VGS_read={VGS_READ}V (µA)")
ax1a.set_title("Integration: Read Current vs Pulse Count")
ax1a.legend(fontsize=8)
ax1a.grid(True, alpha=0.3)

ax1b.set_xlabel("Pulse Number")
ax1b.set_ylabel("ID / ID_baseline")
ax1b.set_title("Fire Detection: Current Ratio at Constant VGS")
ax1b.legend(fontsize=8)
ax1b.grid(True, alpha=0.3)

fig1.tight_layout()
fig1.savefig(os.path.join(OUT_DIR, "simC_v2_fig1_integration_fire.png"), dpi=150)
print(f"\nSaved: simC_v2_fig1_integration_fire.png")

# ── Figure 2: Polarization Evolution + ΔVth Estimate ─────────────────────
fig2, (ax2a, ax2b) = plt.subplots(1, 2, figsize=(14, 5))

for tag, res in all_results.items():
    if np.isnan(res["pulse_pols"]).all():
        continue
    pulses = np.arange(1, N_PULSES + 1)

    # Read-phase polarization
    ax2a.plot(pulses, res["pulse_pols"] * 1e6, 'o-', color=colors.get(tag, 'k'),
              label=f'{tag} (read)', markersize=5)
    # Write-phase polarization
    ax2a.plot(pulses, res["write_pols"] * 1e6, 's--', color=colors.get(tag, 'k'),
              label=f'{tag} (write)', markersize=4, alpha=0.5)

    # ΔVth estimate from SS
    if res["id_baseline"] > 0:
        ratios = res["pulse_ids"] / res["id_baseline"]
        valid = ratios > 0
        dvth = np.full_like(ratios, np.nan)
        dvth[valid] = SS_MVDEC * np.log10(ratios[valid])
        ax2b.plot(pulses, dvth, 'o-', color=colors.get(tag, 'k'),
                  label=f'{tag}', markersize=5)

ax2a.set_xlabel("Pulse Number")
ax2a.set_ylabel("Polarization/y (µC/cm²)")
ax2a.set_title("Polarization Evolution During Integration")
ax2a.legend(fontsize=8)
ax2a.grid(True, alpha=0.3)

ax2b.set_xlabel("Pulse Number")
ax2b.set_ylabel("Estimated ΔVth (mV)")
ax2b.set_title("Threshold Voltage Shift (from SS extraction)")
ax2b.legend(fontsize=8)
ax2b.grid(True, alpha=0.3)

fig2.tight_layout()
fig2.savefig(os.path.join(OUT_DIR, "simC_v2_fig2_polarization_dvth.png"), dpi=150)
print(f"Saved: simC_v2_fig2_polarization_dvth.png")

# ── Figure 3: Reset + Leak ───────────────────────────────────────────────
fig3, (ax3a, ax3b) = plt.subplots(1, 2, figsize=(14, 5))

# Reset completeness bar chart
tags = []
completions = []
for tag, res in all_results.items():
    if not np.isnan(res["reset_completeness"]):
        tags.append(f'{tag}\n({res["vreset"]}V)')
        completions.append(res["reset_completeness"] * 100)

if tags:
    bars = ax3a.bar(tags, completions, color=[colors.get(t.split('\n')[0], 'k') for t in tags])
    ax3a.axhline(80, color='gray', ls=':', label='Target (80%)')
    ax3a.set_ylabel("Reset Completeness (%)")
    ax3a.set_title("Reset Performance by Vreset")
    ax3a.set_ylim(0, 110)
    ax3a.legend()
    for bar, val in zip(bars, completions):
        ax3a.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1,
                  f'{val:.1f}%', ha='center', fontsize=9)

# Leak gap current over time (if data available)
for tag, res in all_results.items():
    node_dir = os.path.join(SIMC_DIR, [n["dir"] for n in SIMC_NODES if n["tag"] == tag][0])
    leak_data = safe_parse(os.path.join(node_dir, f"leak_gap_{tag}_des.plt"))
    if leak_data is not None:
        t = (leak_data[TIME_COL] - leak_data[TIME_COL][0]) * 1e6  # relative time in µs
        i = leak_data[ID_COL] * 1e6  # µA
        ax3b.plot(t, i, '-', color=colors.get(tag, 'k'),
                  label=f'{tag} (Vreset={res["vreset"]}V)')

ax3b.set_xlabel("Time in gap (µs)")
ax3b.set_ylabel("ID at VGS_read (µA)")
ax3b.set_title("Leak Gap: Current Decay at Constant VGS_read")
ax3b.legend(fontsize=8)
ax3b.grid(True, alpha=0.3)

fig3.tight_layout()
fig3.savefig(os.path.join(OUT_DIR, "simC_v2_fig3_reset_leak.png"), dpi=150)
print(f"Saved: simC_v2_fig3_reset_leak.png")

# ── Figure 4: Summary Plot ───────────────────────────────────────────────
fig4, ax4 = plt.subplots(figsize=(8, 6))

for tag, res in all_results.items():
    if np.isnan(res["id_baseline"]) or len(res["pulse_ids"]) == 0:
        continue

    # Full sequence: baseline → 10 reads → post-reset
    all_ids = np.concatenate([[res["id_baseline"]], res["pulse_ids"],
                               [res["id_postreset"]]]) * 1e6
    labels = ["Base"] + [f"P{i}" for i in range(1, N_PULSES+1)] + ["Reset"]
    x = np.arange(len(all_ids))

    ax4.plot(x, all_ids, 'o-', color=colors.get(tag, 'k'),
             label=f'{tag} (Vreset={res["vreset"]}V)', markersize=6)

    # Mark fire point
    if res["fire_pulse"] is not None:
        fp = res["fire_pulse"]  # 1-indexed
        ax4.annotate(f'FIRE (P{fp})',
                     xy=(fp, all_ids[fp]),
                     xytext=(fp + 0.5, all_ids[fp] * 1.1),
                     arrowprops=dict(arrowstyle='->', color=colors.get(tag, 'k')),
                     fontsize=9, color=colors.get(tag, 'k'))

# Fire threshold
if all_results:
    first = list(all_results.values())[0]
    ax4.axhline(first["fire_threshold"] * 1e6, color='gray', ls=':',
                label=f'Fire threshold ({FIRE_RATIO}x)')

ax4.set_xticks(range(len(labels)))
ax4.set_xticklabels(labels, rotation=45, ha='right', fontsize=8)
ax4.set_ylabel(f"ID at VGS_read={VGS_READ}V (µA)")
ax4.set_title("Complete LIF Cycle: Integrate → Fire → Reset\n"
              "(All currents at constant read bias)")
ax4.legend(fontsize=8)
ax4.grid(True, alpha=0.3)

fig4.tight_layout()
fig4.savefig(os.path.join(OUT_DIR, "simC_v2_fig4_lif_cycle.png"), dpi=150)
print(f"Saved: simC_v2_fig4_lif_cycle.png")

# ══════════════════════════════════════════════════════════════════════════════
#  SUMMARY
# ══════════════════════════════════════════════════════════════════════════════
print(f"\n{'='*70}")
print("SUMMARY")
print(f"{'='*70}")

for tag, res in all_results.items():
    print(f"\n  Node {tag} (Vreset = {res['vreset']}V):")
    print(f"    Baseline ID:        {res['id_baseline']*1e6:.3f} uA")
    if not np.isnan(res['pulse_ids']).all():
        print(f"    Final read ID:      {res['pulse_ids'][-1]*1e6:.3f} uA "
              f"({res['pulse_ids'][-1]/res['id_baseline']:.2f}x)")
    if res['fire_pulse'] is not None:
        print(f"    Fire pulse:         {res['fire_pulse']}")
        print(f"    Fire ID:            {res['pulse_ids'][res['fire_pulse']-1]*1e6:.3f} uA")
    else:
        print(f"    Fire pulse:         NOT DETECTED")
    print(f"    Reset completeness: {res['reset_completeness']*100:.1f}%")
    print(f"    Post-reset ID:      {res['id_postreset']*1e6:.3f} uA")

print(f"\n{'='*70}")
print("VALIDATION")
print(f"{'='*70}")

any_fire = any(r["fire_pulse"] is not None for r in all_results.values())
all_reset = all(r["reset_completeness"] > 0.8 for r in all_results.values()
                if not np.isnan(r["reset_completeness"]))

print(f"  Fire demonstrated:    {'YES' if any_fire else 'NO'}")
print(f"  Reset >80% all nodes: {'YES' if all_reset else 'NO'}")

if any_fire and all_reset:
    print("\n  *** FULL LIF CYCLE VALIDATED ***")
    print("  Integration → Fire → Reset all demonstrated at constant VGS_read")
else:
    print("\n  *** PARTIAL VALIDATION ***")
    if not any_fire:
        print("  - Fire not detected: may need more pulses or lower VGS_read")
    if not all_reset:
        print("  - Reset incomplete: may need stronger Vreset")

print(f"\nAnalysis complete. Figures saved to {OUT_DIR}")
