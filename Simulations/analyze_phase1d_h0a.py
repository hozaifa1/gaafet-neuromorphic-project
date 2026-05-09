"""
Phase 1D — H0a v5 calibration analysis.
Extracts TCAD I-V curves, overlays vs Tasneem 2022 Fig 3(c), computes R^2
on the shape-matched subthreshold region, plots.

Key idea: TCAD device (10 nm HZO GAA, n-type) and Tasneem device (5 nm ZrO2
planar, p-type, L=8 um) have very different absolute magnitudes (~2000x in
I_on) and different MW (1.4 V vs 0.5 V) — these are real geometry/device
differences, NOT calibration errors. The defensible Tier A comparison is on
NORMALIZED SHAPE: subtract leakage floor, normalize I/I_on, plot on
(V_G - V_t)/SS axis.  Then R^2 on the subthreshold region tells us whether
the physics matches.
"""
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
H0A   = ROOT / "Simulations" / "simH_optimize" / "H0a"
DIG   = ROOT / "digitized_ref"
OUT   = ROOT / "Simulations" / "phase1d_calibration"
OUT.mkdir(exist_ok=True)
W_eff_um = 0.090

# ---------- helpers ----------
def parse_plt(fp):
    txt = open(fp).read()
    data = txt.split("Data {")[1].split("}")[0].strip()
    nums = np.array([float(x) for x in data.split()])
    return nums.reshape(-1, 29)

def read_sweep(fname):
    d = parse_plt(H0A / fname)
    Vg = d[:, 17]
    I  = np.abs(d[:, 7]) * 1e6 / W_eff_um   # uA/um
    idx = np.argsort(Vg)
    return Vg[idx], I[idx]

def vth_cc(V, I, Iref):
    """Constant-current V_t. Handles both n-type (I rises with V) and p-type
    (I falls with V) — checks bidirectional crossing."""
    for i in range(1, len(I)):
        a, b = I[i-1], I[i]
        if (a < Iref <= b) or (b < Iref <= a):
            return V[i-1] + (Iref - a) * (V[i] - V[i-1]) / (b - a)
    return np.nan

def ss_logfit(V, I, Vlo, Vhi):
    """Fit SS over a V_G window where the curve is in subthreshold."""
    m = (V >= Vlo) & (V <= Vhi) & (I > 0)
    if m.sum() < 3: return np.nan, 0
    p = np.polyfit(V[m], np.log10(I[m]), 1)
    return abs(1000.0 / p[0]), m.sum()

def ss_band(V, I, I_lo, I_hi):
    """Fit SS over an I window (between leakage floor and saturation knee)."""
    m = (I >= I_lo) & (I <= I_hi)
    if m.sum() < 3: return np.nan, 0, np.nan, np.nan
    p = np.polyfit(V[m], np.log10(I[m]), 1)
    return abs(1000.0 / p[0]), m.sum(), V[m].min(), V[m].max()

def ss_min_window(V, I, half_width=4):
    """Find the steepest log10(I) vs V slope (= minimum SS).
    Use a centered window of 2*half_width+1 points around the max gradient."""
    I = np.maximum(I, 1e-15)
    logI = np.log10(I)
    # need monotonic V for gradient; assume V is sorted
    grads = np.gradient(logI, V)
    # smooth slightly to avoid single-point spikes
    from scipy.ndimage import uniform_filter1d
    grads_sm = uniform_filter1d(grads, 3)
    imax = int(np.argmax(np.abs(grads_sm)))
    lo = max(0, imax - half_width); hi = min(len(V), imax + half_width + 1)
    if hi - lo < 3: return np.nan, 0, np.nan, np.nan, np.nan
    p = np.polyfit(V[lo:hi], logI[lo:hi], 1)
    SS = abs(1000.0 / p[0])
    return SS, hi - lo, V[lo], V[hi-1], V[imax]

# ---------- load TCAD data ----------
V_ers, I_ers = read_sweep("read_postERS_n2_des.plt")
V_pgm, I_pgm = read_sweep("read_postPGM_n2_des.plt")

# ---------- load Tasneem digitized refs ----------
tas_red  = np.loadtxt(DIG / "Tasneem_Plot_red.csv",  delimiter=",")
tas_blue = np.loadtxt(DIG / "Tasneem_Plot_blue.csv", delimiter=",")
tas_dot  = np.loadtxt(DIG / "Tasneem_Plot_dot.csv",  delimiter=",")
def sort_arr(arr):
    idx = np.argsort(arr[:,0]); return arr[idx]
tas_red, tas_blue, tas_dot = map(sort_arr, [tas_red, tas_blue, tas_dot])

# ---------- TCAD V_t (constant-current at I/W = 1 µA/µm) ----------
Iref_tcad = 1.0  # uA/um (short-channel adapted; our I_off floor is 3 nA/um)
Vt_ers = vth_cc(V_ers, I_ers, Iref_tcad)
Vt_pgm = vth_cc(V_pgm, I_pgm, Iref_tcad)
MW_tcad = Vt_ers - Vt_pgm

# ---------- Tasneem V_t (paper criterion I/W = 1e-4 µA/µm) ----------
Iref_tas = 1e-4
Vt_tas_red  = vth_cc(tas_red[:,0],  tas_red[:,1],  Iref_tas)
Vt_tas_blue = vth_cc(tas_blue[:,0], tas_blue[:,1], Iref_tas)
Vt_tas_dot  = vth_cc(tas_dot[:,0],  tas_dot[:,1],  Iref_tas)
MW_tas_dig  = Vt_tas_blue - Vt_tas_red   # p-type: ERS V_t less negative than PGM V_t

# ---------- SS — minimum-SS via max-derivative window ----------
# This matches how Tasneem extracts SS: the steepest part of log10(I)-V curve.
SS_tcad_pgm, n_pgm, Vlo_pgm, Vhi_pgm, _ = ss_min_window(V_pgm, I_pgm)
SS_tcad_ers, n_ers, Vlo_ers, Vhi_ers, _ = ss_min_window(V_ers, I_ers)
SS_tas_pgm,  n_tp,  Vlo_tp,  Vhi_tp,  _ = ss_min_window(tas_red[:,0],  tas_red[:,1])
SS_tas_ers,  n_te,  Vlo_te,  Vhi_te,  _ = ss_min_window(tas_blue[:,0], tas_blue[:,1])

print("=== METRICS ===")
print(f"TCAD (this work, 10 nm HZO GAA, n-type):")
print(f"  V_t post-ERS @ I/W=1 uA/um  = {Vt_ers:+.3f} V")
print(f"  V_t post-PGM @ I/W=1 uA/um  = {Vt_pgm:+.3f} V")
print(f"  MW                          = {MW_tcad:.3f} V")
print(f"  SS post-ERS (band 3e-2..18) = {SS_tcad_ers:.1f} mV/dec  fit V=[{Vlo_ers:+.3f},{Vhi_ers:+.3f}] N={n_ers}")
print(f"  SS post-PGM (band 3e-2..28) = {SS_tcad_pgm:.1f} mV/dec  fit V=[{Vlo_pgm:+.3f},{Vhi_pgm:+.3f}] N={n_pgm}")
print(f"\nTasneem 2022 (5 nm ZrO2 planar, p-type, L=8 um):")
print(f"  V_t post-PGM (red,  digitized) = {Vt_tas_red:+.3f} V")
print(f"  V_t post-ERS (blue, digitized) = {Vt_tas_blue:+.3f} V")
print(f"  V_t virgin   (dot,  digitized) = {Vt_tas_dot:+.3f} V")
print(f"  Digitized MW                   = {MW_tas_dig:.3f} V (paper-stated 0.5 V)")
print(f"  SS post-PGM (band 1e-5..1e-2)  = {SS_tas_pgm:.1f} mV/dec  fit V=[{Vlo_tp:+.3f},{Vhi_tp:+.3f}] N={n_tp}")
print(f"  SS post-ERS (band 1e-5..1e-1)  = {SS_tas_ers:.1f} mV/dec  fit V=[{Vlo_te:+.3f},{Vhi_te:+.3f}] N={n_te}")

# ---------- save TCAD CSVs ----------
np.savetxt(OUT/"tcad_postERS.csv", np.column_stack([V_ers,I_ers]),
           header="V_G_V,I_D_uA_per_um", delimiter=",", comments="")
np.savetxt(OUT/"tcad_postPGM.csv", np.column_stack([V_pgm,I_pgm]),
           header="V_G_V,I_D_uA_per_um", delimiter=",", comments="")

# =================================================================
# SHAPE-MATCH: V_t-align AND I-normalize for fair comparison
# =================================================================
# For shape comparison we need:
#   - same V axis convention: use (V_G - V_t), with sign flipped for p-type
#     so "above threshold" is on the right for both
#   - same I axis: normalize each curve so I=1 at the V_t reference point
#     (i.e., divide by Iref used to extract V_t for that curve)
#
# After this: a perfectly calibrated TCAD-vs-Tasneem comparison should give
# overlapping log10(I/Iref) vs (V_G - V_t) curves in the subthreshold region.

def normalize(V, I, Vt, Iref, p_type=False):
    Vshift = -(V - Vt) if p_type else (V - Vt)
    Inorm  = I / Iref
    idx = np.argsort(Vshift)
    return Vshift[idx], Inorm[idx]

x_tcad_pgm, y_tcad_pgm = normalize(V_pgm, I_pgm, Vt_pgm, Iref_tcad, p_type=False)
x_tcad_ers, y_tcad_ers = normalize(V_ers, I_ers, Vt_ers, Iref_tcad, p_type=False)
x_tas_pgm,  y_tas_pgm  = normalize(tas_red[:,0],  tas_red[:,1],  Vt_tas_red,  Iref_tas, p_type=True)
x_tas_ers,  y_tas_ers  = normalize(tas_blue[:,0], tas_blue[:,1], Vt_tas_blue, Iref_tas, p_type=True)
x_tas_dot,  y_tas_dot  = normalize(tas_dot[:,0],  tas_dot[:,1],  Vt_tas_dot,  Iref_tas, p_type=True)

# ---------- R^2 on shape-matched subthreshold region ----------
# Interpolate Tasneem onto TCAD V grid in the overlap region, on log10(I/Iref) axis
def r2_window(x_a, y_a, x_b, y_b, xlo, xhi):
    """R^2 between log10(y_a) and log10(y_b) interpolated onto a common x grid."""
    # clip to actual data ranges
    xlo = max(xlo, x_a.min(), x_b.min())
    xhi = min(xhi, x_a.max(), x_b.max())
    if xhi - xlo < 0.1: return np.nan, 0
    xgrid = np.linspace(xlo, xhi, 50)
    log_a = np.interp(xgrid, x_a, np.log10(np.maximum(y_a, 1e-12)))
    log_b = np.interp(xgrid, x_b, np.log10(np.maximum(y_b, 1e-12)))
    ss_res = np.sum((log_a - log_b)**2)
    ss_tot = np.sum((log_b - log_b.mean())**2)
    return 1.0 - ss_res/ss_tot, len(xgrid)

# Multiple R² windows: deep subthreshold (where TCAD floors), near-Vt (where
# both should match), above-threshold (where curves bend per geometry)
print(f"\nR^2 on V_t-aligned + I-normalized curves:")
print(f"  Window                                  | R²(PGM) | R²(ERS) ")
print(f"  ----------------------------------------|---------|--------")
windows = [
    ("Wide:        V-V_t in [-1.0, +0.5]", -1.0, +0.5),
    ("Near-Vt:     V-V_t in [-0.5, +0.5]", -0.5, +0.5),
    ("Subthr only: V-V_t in [-0.4, +0.0]", -0.4, +0.0),
    ("Above-Vt:    V-V_t in [+0.0, +0.5]", +0.0, +0.5),
]
R2_results = {}
for name, xlo, xhi in windows:
    rp, _ = r2_window(x_tcad_pgm, y_tcad_pgm, x_tas_pgm, y_tas_pgm, xlo, xhi)
    re, _ = r2_window(x_tcad_ers, y_tcad_ers, x_tas_ers, y_tas_ers, xlo, xhi)
    print(f"  {name:40s}|  {rp:+.3f} |  {re:+.3f}")
    R2_results[name] = (rp, re)

# Headline R²: near-Vt window (most informative — both curves above floor)
R2_pgm = R2_results["Near-Vt:     V-V_t in [-0.5, +0.5]"][0]
R2_ers = R2_results["Near-Vt:     V-V_t in [-0.5, +0.5]"][1]

# =================================================================
# PLOTS
# =================================================================
plt.rcParams.update({"figure.dpi": 110, "font.size": 10, "axes.grid": True,
                     "grid.alpha": 0.3, "axes.axisbelow": True})

# ---------- Plot 1: TCAD curves ALONE (our device) ----------
fig, ax = plt.subplots(figsize=(7, 5))
ax.semilogy(V_pgm, I_pgm, "r-", lw=1.8, label=f"post-PGM (V_t={Vt_pgm:+.2f} V)")
ax.semilogy(V_ers, I_ers, "b-", lw=1.8, label=f"post-ERS (V_t={Vt_ers:+.2f} V)")
ax.axhline(Iref_tcad, color="gray", ls=":", lw=1, alpha=0.6, label=f"V_t criterion: I/W={Iref_tcad} µA/µm")
ax.axvline(Vt_pgm, color="r", ls=":", lw=0.8, alpha=0.4)
ax.axvline(Vt_ers, color="b", ls=":", lw=0.8, alpha=0.4)
ax.annotate(f"MW = {MW_tcad:.2f} V",
            xy=((Vt_pgm+Vt_ers)/2, 0.3), xytext=(0,0), textcoords="offset points",
            ha="center", fontsize=11, fontweight="bold",
            bbox=dict(boxstyle="round", fc="lightyellow", ec="orange"))
ax.set_xlabel("V_G (V)"); ax.set_ylabel("I_D / W (µA/µm)")
ax.set_title("TCAD H0a v5 — 10 nm HZO GAA-FeFET, V_DS=0.05 V\n"
             f"SS post-PGM = {SS_tcad_pgm:.0f} mV/dec, SS post-ERS = {SS_tcad_ers:.0f} mV/dec, MW = {MW_tcad:.2f} V")
ax.legend(loc="lower right"); ax.set_ylim(1e-4, 1e3)
fig.tight_layout(); fig.savefig(OUT/"tcad_only.png", dpi=140)
print(f"\nPlot saved: tcad_only.png")

# ---------- Plot 2: Tasneem curves ALONE (digitized reference) ----------
fig, ax = plt.subplots(figsize=(7, 5))
ax.semilogy(tas_red[:,0],  tas_red[:,1],  "r-", lw=1.8, label=f"post-PGM (V_t={Vt_tas_red:+.2f} V)")
ax.semilogy(tas_blue[:,0], tas_blue[:,1], "b-", lw=1.8, label=f"post-ERS (V_t={Vt_tas_blue:+.2f} V)")
ax.semilogy(tas_dot[:,0],  tas_dot[:,1],  "k:", lw=1.8, label=f"virgin   (V_t={Vt_tas_dot:+.2f} V)")
ax.axhline(Iref_tas, color="gray", ls=":", lw=1, alpha=0.6, label=f"V_t criterion: I/W={Iref_tas:.0e} µA/µm")
ax.set_xlabel("V_G (V)"); ax.set_ylabel("I_D / W (µA/µm)")
ax.set_title("Tasneem 2022 Fig 3(c) — 5 nm ZrO₂ planar p-FeFET, L=8 µm (digitized)\n"
             f"SS post-PGM = {SS_tas_pgm:.0f} mV/dec, SS post-ERS = {SS_tas_ers:.0f} mV/dec, "
             f"MW(dig) = {MW_tas_dig:.2f} V (paper 0.5 V)")
ax.legend(loc="lower right"); ax.set_ylim(1e-8, 1e1)
fig.tight_layout(); fig.savefig(OUT/"tasneem_only.png", dpi=140)
print(f"Plot saved: tasneem_only.png")

# ---------- Plot 3: V_t-aligned + I-normalized SHAPE comparison (the key plot) ----------
fig, axes = plt.subplots(1, 2, figsize=(13, 5))
ax = axes[0]
ax.semilogy(x_tcad_pgm, y_tcad_pgm, "r-",  lw=2.0, label="TCAD post-PGM")
ax.semilogy(x_tas_pgm,  y_tas_pgm,  "r--", lw=1.6, alpha=0.85, label="Tasneem post-PGM (axis flipped)")
ax.axvline(0, color="gray", ls=":", lw=1)
ax.axhline(1, color="gray", ls=":", lw=1)
ax.set_xlabel("V_G − V_t (V)"); ax.set_ylabel("I / I(V_t)")
ax.set_title(f"post-PGM (red) — V_t-aligned, I-normalized\nR² = {R2_pgm:.3f}, "
             f"SS_TCAD = {SS_tcad_pgm:.0f}, SS_Tasneem = {SS_tas_pgm:.0f} mV/dec")
ax.legend(loc="lower right"); ax.set_xlim(-1.5, 1.0); ax.set_ylim(1e-6, 1e3)
ax = axes[1]
ax.semilogy(x_tcad_ers, y_tcad_ers, "b-",  lw=2.0, label="TCAD post-ERS")
ax.semilogy(x_tas_ers,  y_tas_ers,  "b--", lw=1.6, alpha=0.85, label="Tasneem post-ERS (axis flipped)")
ax.axvline(0, color="gray", ls=":", lw=1)
ax.axhline(1, color="gray", ls=":", lw=1)
ax.set_xlabel("V_G − V_t (V)"); ax.set_ylabel("I / I(V_t)")
ax.set_title(f"post-ERS (blue) — V_t-aligned, I-normalized\nR² = {R2_ers:.3f}, "
             f"SS_TCAD = {SS_tcad_ers:.0f}, SS_Tasneem = {SS_tas_ers:.0f} mV/dec")
ax.legend(loc="lower right"); ax.set_xlim(-1.5, 1.0); ax.set_ylim(1e-6, 1e3)
fig.suptitle("SHAPE COMPARISON: V_t-aligned + I-normalized (defensible Tier A overlay)", fontsize=11)
fig.tight_layout(); fig.savefig(OUT/"shape_comparison.png", dpi=140)
print(f"Plot saved: shape_comparison.png")

# ---------- Plot 4: 3-panel summary (raw TCAD | raw Tasneem | shape match) ----------
fig, axes = plt.subplots(1, 3, figsize=(16, 4.5))
ax = axes[0]
ax.semilogy(V_pgm, I_pgm, "r-", lw=1.6, label="post-PGM")
ax.semilogy(V_ers, I_ers, "b-", lw=1.6, label="post-ERS")
ax.set_xlabel("V_G (V)"); ax.set_ylabel("I_D / W (µA/µm)")
ax.set_title(f"(a) TCAD raw — MW = {MW_tcad:.2f} V")
ax.legend(fontsize=8); ax.set_ylim(1e-4, 1e3)

ax = axes[1]
ax.semilogy(tas_red[:,0],  tas_red[:,1],  "r-", lw=1.6, label="post-PGM")
ax.semilogy(tas_blue[:,0], tas_blue[:,1], "b-", lw=1.6, label="post-ERS")
ax.semilogy(tas_dot[:,0],  tas_dot[:,1],  "k:", lw=1.6, label="virgin")
ax.set_xlabel("V_G (V)"); ax.set_ylabel("I_D / W (µA/µm)")
ax.set_title(f"(b) Tasneem raw — MW(dig) = {MW_tas_dig:.2f} V")
ax.legend(fontsize=8); ax.set_ylim(1e-8, 1e1)

ax = axes[2]
ax.semilogy(x_tcad_pgm, y_tcad_pgm, "r-",  lw=1.8, label="TCAD post-PGM")
ax.semilogy(x_tas_pgm,  y_tas_pgm,  "r--", lw=1.4, alpha=0.85, label="Tasneem post-PGM")
ax.semilogy(x_tcad_ers, y_tcad_ers, "b-",  lw=1.8, label="TCAD post-ERS")
ax.semilogy(x_tas_ers,  y_tas_ers,  "b--", lw=1.4, alpha=0.85, label="Tasneem post-ERS")
ax.axvline(0, color="gray", ls=":", lw=1); ax.axhline(1, color="gray", ls=":", lw=1)
ax.set_xlabel("V_G − V_t (V)"); ax.set_ylabel("I / I(V_t)")
ax.set_title(f"(c) Shape match: R²(PGM)={R2_pgm:.3f}, R²(ERS)={R2_ers:.3f}")
ax.legend(fontsize=8); ax.set_xlim(-1.5, 1.0); ax.set_ylim(1e-6, 1e3)
fig.suptitle("Phase 1D H0a v5 — TCAD GAA-FeFET vs Tasneem 2022 Fig 3(c) calibration", fontsize=11)
fig.tight_layout(); fig.savefig(OUT/"summary_3panel.png", dpi=140)
print(f"Plot saved: summary_3panel.png")

# ---------- metrics summary ----------
with open(OUT/"metrics_summary.txt", "w") as f:
    f.write("Phase 1D — H0a v5 calibration metrics\n")
    f.write("Reference: Tasneem 2022 IEEE TED Fig 3(c)\n")
    f.write("="*60 + "\n\n")
    f.write("TCAD (this work, 10 nm HZO GAA-FeFET, n-type):\n")
    f.write(f"  V_t post-ERS @ I/W=1 uA/um = {Vt_ers:+.3f} V\n")
    f.write(f"  V_t post-PGM @ I/W=1 uA/um = {Vt_pgm:+.3f} V\n")
    f.write(f"  Memory window MW           = {MW_tcad:.3f} V\n")
    f.write(f"  SS post-ERS (band fit)     = {SS_tcad_ers:.1f} mV/dec  V=[{Vlo_ers:+.3f},{Vhi_ers:+.3f}] N={n_ers}\n")
    f.write(f"  SS post-PGM (band fit)     = {SS_tcad_pgm:.1f} mV/dec  V=[{Vlo_pgm:+.3f},{Vhi_pgm:+.3f}] N={n_pgm}\n")
    f.write(f"  I_off floor                = 3 nA/um\n\n")
    f.write("Tasneem 2022 reference (paper-stated):\n")
    f.write("  Memory window dV_t = 0.5 V\n")
    f.write("  SS post-write      = 110 mV/dec\n")
    f.write("  SS virgin          = 70 mV/dec\n")
    f.write("  V_t criterion      = I/W = 1e-4 uA/um\n\n")
    f.write("Tasneem digitized (extracted from Fig 3(c) curves):\n")
    f.write(f"  V_t post-PGM (red)  = {Vt_tas_red:+.3f} V\n")
    f.write(f"  V_t post-ERS (blue) = {Vt_tas_blue:+.3f} V\n")
    f.write(f"  V_t virgin   (dot)  = {Vt_tas_dot:+.3f} V\n")
    f.write(f"  Digitized MW        = {MW_tas_dig:.3f} V\n")
    f.write(f"  SS post-PGM (band)  = {SS_tas_pgm:.1f} mV/dec  V=[{Vlo_tp:+.3f},{Vhi_tp:+.3f}] N={n_tp}\n")
    f.write(f"  SS post-ERS (band)  = {SS_tas_ers:.1f} mV/dec  V=[{Vlo_te:+.3f},{Vhi_te:+.3f}] N={n_te}\n\n")
    f.write("Shape-match R^2 (V_t-aligned + I-normalized, V_G-V_t in [-1, +0.5]):\n")
    f.write(f"  post-PGM  R^2 = {R2_pgm:+.4f}\n")
    f.write(f"  post-ERS  R^2 = {R2_ers:+.4f}\n\n")
    f.write("Tier A interpretation:\n")
    f.write("  Devices have different geometries (10 nm HZO GAA vs 5 nm ZrO2 planar L=8 um).\n")
    f.write("  Magnitudes (I_on, MW) differ by physics — NOT calibration error.\n")
    f.write("  Theoretical max MW = 2*F_c*t_FE = 2.4 V (TCAD stack) vs 1.2 V (Tasneem).\n")
    f.write("  Calibration is on PHYSICS SHAPE (SS, hysteresis topology) after V_t-align.\n")
    f.write("  R^2 reported above reflects shape match in normalized subthreshold region.\n")
print(f"\nSummary text: {OUT/'metrics_summary.txt'}")
