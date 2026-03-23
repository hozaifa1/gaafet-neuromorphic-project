"""
SimB Results Diagnostic Plotter
Parses Sentaurus .plt files from SimB (20 pulses at Vpulse=2.0V)
Generates:
  Fig 1 — ID-VGS: baseline vs all 5 intermediate reads (N=1,3,5,10,20)
  Fig 2 — ΔVth vs N (expected staircase → actual flat line)
  Fig 3 — Pol/y at end of hold phase for P1, P5, P10, P20
  Console — Diagnostic summary with root-cause explanation
"""

import re
import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm

# ── Config ─────────────────────────────────────────────────────────────────────
SIMB_DIR = os.path.join(os.path.dirname(__file__), "..", "simB")
OUT_DIR  = os.path.dirname(__file__)

VTH_BASE_V = -0.050
VDS_READ   = 0.050
FC_MV_CM   = 1.2
PR_UC_CM2  = 16.0

READS = [
    {"n": 0,  "file": "baseline_fwd_n5_des.plt", "label": "Baseline"},
    {"n": 1,  "file": "read_n01_fwd_n5_des.plt", "label": "N=1"},
    {"n": 3,  "file": "read_n03_fwd_n5_des.plt", "label": "N=3"},
    {"n": 5,  "file": "read_n05_fwd_n5_des.plt", "label": "N=5"},
    {"n": 10, "file": "read_n10_fwd_n5_des.plt", "label": "N=10"},
    {"n": 20, "file": "read_n20_fwd_n5_des.plt", "label": "N=20"},
]

HOLDS = [
    {"n": 1,  "file": "p1_hold_n5_des.plt"},
    {"n": 5,  "file": "p5_hold_n5_des.plt"},
    {"n": 10, "file": "p10_hold_n5_des.plt"},
    {"n": 20, "file": "p20_hold_n5_des.plt"},
]

VGS_COL  = "gate_contact OuterVoltage"
ID_COL   = "drain_contact TotalCurrent"
TIME_COL = "time"
POLY_COL = "Pos(0,0.0145) Polarization/y"
EY_COL   = "Pos(0,0.0145) ElectricField/y"

# ── Parser ─────────────────────────────────────────────────────────────────────
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

# ── Load data ──────────────────────────────────────────────────────────────────
read_data = {}
for r in READS:
    read_data[r["n"]] = parse_plt(os.path.join(SIMB_DIR, r["file"]))

hold_data = {}
for h in HOLDS:
    hold_data[h["n"]] = parse_plt(os.path.join(SIMB_DIR, h["file"]))

# ── ΔVth extraction ───────────────────────────────────────────────────────────
baseline = read_data[0]

def extract_dvth(post):
    vgs_probe = baseline[VGS_COL][0]
    id_base   = baseline[ID_COL][0]
    id_post   = post[ID_COL][0]
    ratio = id_post / id_base
    vth_post = vgs_probe - ratio * (vgs_probe - VTH_BASE_V)
    return (VTH_BASE_V - vth_post) * 1e3

n_values = [1, 3, 5, 10, 20]
dvth_values = [extract_dvth(read_data[n]) for n in n_values]

colors = cm.viridis(np.linspace(0.2, 0.9, len(READS)))

# ══════════════════════════════════════════════════════════════════════════════
# FIGURE 1: ID-VGS overlay — baseline + all reads
# ══════════════════════════════════════════════════════════════════════════════
fig1, ax1 = plt.subplots(figsize=(7, 5))

for i, r in enumerate(READS):
    d = read_data[r["n"]]
    vgs = d[VGS_COL]
    id_ua = d[ID_COL] * 1e6
    style = "k--" if r["n"] == 0 else None
    lw = 2.0 if r["n"] == 0 else 1.5
    c = "black" if r["n"] == 0 else colors[i]
    ax1.plot(vgs, id_ua, color=c, linewidth=lw, linestyle="--" if r["n"] == 0 else "-",
             label=f'{r["label"]}  (ΔVth≈{extract_dvth(d) if r["n"]>0 else 0:.0f}mV)')

ax1.set_xlabel("V$_{GS}$ (V)", fontsize=12)
ax1.set_ylabel("I$_D$ (µA)", fontsize=12)
ax1.set_title("SimB — ID-VGS After N Pulses (Vpulse=2.0V, pw=100ns)", fontsize=12)
ax1.legend(fontsize=9, loc="upper left")
ax1.set_xlim(0, 0.3)
ax1.grid(True, alpha=0.3)

ax1.text(0.97, 0.15,
         "⚠ ALL post-pulse curves overlap\n→ NO cumulative integration\n"
         "Root cause: τ_E (1ns) << pw (100ns)\n→ P equilibrates on pulse 1",
         transform=ax1.transAxes, ha="right", va="bottom", fontsize=9,
         color="red", fontweight="bold",
         bbox=dict(boxstyle="round,pad=0.4", facecolor="lightyellow", edgecolor="red"))

fig1.tight_layout()
fig1.savefig(os.path.join(OUT_DIR, "simB_fig1_idvgs_overlay.png"), dpi=150)
print("Saved simB_fig1_idvgs_overlay.png")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURE 2: ΔVth vs N — expected staircase vs actual flat line
# ══════════════════════════════════════════════════════════════════════════════
fig2, ax2 = plt.subplots(figsize=(7, 5))

ax2.plot(n_values, dvth_values, "ro-", linewidth=2, markersize=8, label="Measured (τ_E=1ns)")

# Expected staircase (if integration worked: ~99mV per pulse, saturating)
n_expected = np.array([1, 3, 5, 10, 20])
# For rate-limited switching with tau_E >> pw: ΔVth(N) ≈ ΔVth_max × (1 - exp(-N×pw/tau_E))
tau_e_fixed = 1e-6  # proposed fix: 1µs
pw = 100e-9
dvth_max = 160  # mV (from SimA at 3V, approx max)
dvth_expected = dvth_max * (1 - np.exp(-n_expected * pw / tau_e_fixed))
ax2.plot(n_expected, dvth_expected, "b--s", linewidth=1.5, markersize=6,
         label=f"Expected (τ_E=1µs, rate-limited)")

for i, (n, dv) in enumerate(zip(n_values, dvth_values)):
    ax2.annotate(f"{dv:.1f}", (n, dv), textcoords="offset points", xytext=(10, 5),
                 fontsize=9, color="red")

ax2.set_xlabel("Number of Pulses (N)", fontsize=12)
ax2.set_ylabel("ΔV$_{th}$ (mV)", fontsize=12)
ax2.set_title("SimB — Cumulative ΔVth vs Pulse Count (DIAGNOSIS)", fontsize=12)
ax2.legend(fontsize=10)
ax2.set_ylim(0, max(max(dvth_values), max(dvth_expected)) * 1.3)
ax2.grid(True, alpha=0.3)

ax2.text(0.5, 0.5,
         "FLAT LINE = No Integration\n"
         "Fix: increase τ_E so each pulse\n"
         "only partially switches domains",
         transform=ax2.transAxes, ha="center", va="center", fontsize=11,
         color="darkred",
         bbox=dict(boxstyle="round,pad=0.5", facecolor="mistyrose", edgecolor="darkred", alpha=0.9))

fig2.tight_layout()
fig2.savefig(os.path.join(OUT_DIR, "simB_fig2_dvth_vs_N.png"), dpi=150)
print("Saved simB_fig2_dvth_vs_N.png")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURE 3: Pol/y at end of hold phase for each pulse
# ══════════════════════════════════════════════════════════════════════════════
fig3, ax3 = plt.subplots(figsize=(7, 4.5))

hold_ns = []
hold_poly_end = []
for h in HOLDS:
    d = hold_data[h["n"]]
    poly_end = d[POLY_COL][-1] * 1e6  # C/cm² → µC/cm²
    hold_ns.append(h["n"])
    hold_poly_end.append(poly_end)

ax3.plot(hold_ns, hold_poly_end, "rs-", linewidth=2, markersize=10)
for n, p in zip(hold_ns, hold_poly_end):
    ax3.annotate(f"{p:.4f}", (n, p), textcoords="offset points", xytext=(10, 10),
                 fontsize=9, color="red")

ax3.set_xlabel("Pulse Number", fontsize=12)
ax3.set_ylabel("Pol/y at Hold End (µC/cm²)", fontsize=12)
ax3.set_title("SimB — Polarization State After Each Pulse Hold (Vpulse=2.0V)", fontsize=12)
ax3.grid(True, alpha=0.3)
ax3.axhline(hold_poly_end[0], color="gray", linestyle=":", linewidth=1,
            label=f"Constant: {hold_poly_end[0]:.4f} µC/cm²")
ax3.legend(fontsize=10)

ax3.text(0.5, 0.15,
         "Identical P state across all pulses\n→ τ_E too small → full equilibrium per pulse",
         transform=ax3.transAxes, ha="center", va="bottom", fontsize=10,
         color="darkred",
         bbox=dict(boxstyle="round,pad=0.4", facecolor="mistyrose", edgecolor="darkred", alpha=0.9))

fig3.tight_layout()
fig3.savefig(os.path.join(OUT_DIR, "simB_fig3_pol_vs_pulse.png"), dpi=150)
print("Saved simB_fig3_pol_vs_pulse.png")

# ══════════════════════════════════════════════════════════════════════════════
# Console diagnostic
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "="*70)
print("  SimB DIAGNOSTIC SUMMARY")
print("="*70)
print(f"\nBaseline ID @VGS=0.003V: {baseline[ID_COL][0]*1e6:.3f} µA")
print(f"\nIntermediate reads (ID @VGS=0.003V):")
for n in n_values:
    d = read_data[n]
    print(f"  N={n:>2}: ID = {d[ID_COL][0]*1e6:.3f} µA  ΔVth = {extract_dvth(d):.1f} mV")

print(f"\nPolarization at end of hold (Pol/y in µC/cm²):")
for h in HOLDS:
    d = hold_data[h["n"]]
    print(f"  P{h['n']:>2} hold end: {d[POLY_COL][-1]*1e6:.6f} µC/cm²")

print(f"\n{'='*70}")
print("  ROOT CAUSE: tau_E (1ns) << pulse_width (100ns)")
print("  → Polarization reaches FULL EQUILIBRIUM during pulse 1")
print("  → Subsequent pulses at same Vpulse find P already at equilibrium")
print("  → No incremental switching = no integration")
print(f"\n  FIX: Increase tau_E to ~1µs (1e-6 s)")
print(f"  → pw/tau_E = 0.1 → each pulse switches ~10% of remaining P")
print(f"  → After 20 pulses: ~87% total switching (cumulative staircase)")
print(f"{'='*70}")

plt.show()
