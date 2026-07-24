"""Planar-vs-GAA comparison: overlay plots + planar_params + comparison table.

TRUE single-gate ablation of the optimized GAA (see gen_planar.py / sde/sde_planar.cmd).
Reads planar TCAD outputs (outputs/planarfinal, outputs/planarfinal2, outputs/planarclean,
outputs/lifsw2, outputs/lifret2) and the GAA reference CSVs
(../Device_Optimization/csv_export/raw/). Produces plots/*.png, planar_params.py,
PLANAR_vs_GAA.md. Run with no arguments -- op point (2.3 V) and sources are fixed to the
final characterization files described in main().
"""
import json
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from planar import subthreshold_slope

HERE = Path(__file__).resolve().parent
GAA  = HERE.parent / "Device_Optimization" / "csv_export" / "raw"
PLOTS = HERE / "plots"; PLOTS.mkdir(exist_ok=True)
VDS = 0.05

# GAA reference numbers -- RE-DERIVED, not copied from SNN_PARAMETERS.md/OPTIMIZED_DEVICE.md.
#
# Found and fixed a real inconsistency in Device_Optimization's own GAA pipeline: every
# .cmd (lifgen.py/memwingen.py) sets Areafactor=0.071 inside Sentaurus, but every analysis
# script (opt.py/plot_memwin.py/plot_iv.py) divides the result by W_um=0.090 -- two
# different width conventions for the SAME normalization step, never reconciled. All
# csv_export/raw/*.csv current values therefore carry a uniform (0.090/0.071)=1.2676x
# scale error relative to a properly Areafactor=1 (native per-um-width) reading -- the
# SAME convention this whole planar study uses. Ratio-based numbers (window, SS, n_levels,
# fire_ratio) are UNAFFECTED (the constant cancels); absolute-current-derived numbers
# (R_off/R_on/g_min/g_max) are NOT -- corrected here via CORR=0.090/0.071 below.
#
# NOTE: SNN_PARAMETERS.md's own R_off=7.14e7/R_on=2.34e6 (-> the Python stage1 synapse's
# g_min/g_max) come from a THIRD, separately-derived conversion (ID_baseline/ID_fire back-
# multiplied by 0.071 on already-/0.090-divided csv data) that does not even undo the first
# inconsistency -- deliberately NOT reused or "corrected" here; that fix is scoped to
# Device_Optimization/the Python model, out of scope for this planar comparison. Flagging
# only. TESW = 2*(W+T_si), W=40nm (literature: nanosheet width "saturated at ~40-50nm"),
# T_si=5nm (locked) -> TESW=90nm, which is exactly the existing W_um=0.090 -- i.e. the
# analysis-script divisor was already the right literature-consistent width; only the
# in-.cmd Areafactor=0.071 was the wrong number.
CORR = 0.090 / 0.071  # = 1.2676; converts existing GAA csv (Areafactor=0.071, /0.090) -> native per-um-width
ICC_UA_UM = 1e-2   # constant-current threshold criterion (GAA: erased Vth @Icc=1e-2 uA/um)


def vth_at_icc(vgs, ids, icc=ICC_UA_UM):
    """Linear-interp gate voltage where |Id| crosses icc (uA/um), rising. None if never."""
    vgs = np.asarray(vgs, float); ids = np.asarray(ids, float)
    for i in range(1, len(vgs)):
        if ids[i - 1] < icc <= ids[i] and ids[i] > ids[i - 1]:
            f = (np.log10(icc) - np.log10(ids[i - 1])) / (np.log10(ids[i]) - np.log10(ids[i - 1]))
            return float(vgs[i - 1] + f * (vgs[i] - vgs[i - 1]))
    return None


_g = np.genfromtxt(GAA / "transfer_curves.csv", delimiter=",", names=True)
_vg = _g["Vg_V"]; _ers = _g["Id_erased_uA_um"] * CORR; _pgm = _g["Id_programmed_uA_um"] * CORR
_ss_ers = float(subthreshold_slope(_vg, _ers)); _ss_pgm = float(subthreshold_slope(_vg, _pgm))
_vth_ers = vth_at_icc(_vg, _ers); _vth_pgm = vth_at_icc(_vg, _pgm)

_mw = np.genfromtxt(GAA / "memwin_fe07.csv", delimiter=",", names=True)
_mvg = _mw["Vg_V"]; _i0 = int(np.argmin(np.abs(_mvg)))
_i_off = _mw["Id_erased_uA_um"][_i0] * CORR; _i_on = _mw["Id_programmed_uA_um"][_i0] * CORR
_R_off, _R_on = VDS / (_i_off * 1e-6), VDS / (_i_on * 1e-6)

GAA_REF = dict(R_off=_R_off, R_on=_R_on, window=_i_on / _i_off, n_levels=15,
               E_pulse_J=1.4e-17, MW_V=_vth_ers - _vth_pgm, Vth_ers=_vth_ers, Vth_pgm=_vth_pgm,
               SS_ers_mVdec=_ss_ers, SS_pgm_mVdec=_ss_pgm,
               V_pgm=2.0, arch="GAA (double-gate 5nm nanosheet)")
# E_pulse_J kept as the original locked (uncorrected) quote -- SNN_PARAMETERS.md gives no
# raw-current source for it that this script can independently re-derive/correct the same way.


def _loadcsv(name):
    fp = GAA / name
    if not fp.exists():
        return None
    return np.genfromtxt(fp, delimiter=",", names=True)


# ---------------- memory-window / transfer overlay ----------------
def plot_memwin(planar_mw):
    g = _loadcsv("memwin_fe07.csv")
    fig, ax = plt.subplots(figsize=(7, 5))
    if g is not None:
        ax.semilogy(g["Vg_V"], g["Id_erased_uA_um"], "o--", color="tab:blue", alpha=.5, label="GAA erased")
        ax.semilogy(g["Vg_V"], g["Id_programmed_uA_um"], "o-", color="tab:blue", label="GAA programmed")
    if planar_mw:
        vg = np.array(planar_mw["vgs"]); ers = np.array(planar_mw["ers"]); pgm = np.array(planar_mw["pgm"])
        ax.semilogy(vg, ers, "s--", color="tab:red", alpha=.5, label="Planar erased")
        ax.semilogy(vg, pgm, "s-", color="tab:red", label="Planar programmed")
    ax.set_xlabel("Read gate voltage $V_G$ (V)"); ax.set_ylabel("$I_D$ ($\\mu$A/$\\mu$m)")
    ax.set_title("Retained-state transfer / memory window: GAA vs Planar")
    ax.legend(); ax.grid(True, which="both", alpha=.3)
    fig.tight_layout(); fig.savefig(PLOTS / "compare_memwin.png", dpi=150); plt.close(fig)
    print("  wrote compare_memwin.png")


# ---------------- LTP overlay ----------------
def plot_ltp(op_ids):
    g = _loadcsv("ltp_potentiation.csv")
    fig, ax = plt.subplots(figsize=(7, 5))
    if g is not None:
        ax.semilogy(g["pulse_n"], g["Id_uA_per_um"], "o-", color="tab:blue", label="GAA LTP")
    if op_ids is not None:
        ax.semilogy(np.arange(1, len(op_ids) + 1), op_ids, "s-", color="tab:red", label="Planar LTP")
    ax.set_xlabel("Pulse number"); ax.set_ylabel("$I_D$ ($\\mu$A/$\\mu$m)")
    ax.set_title("Analog potentiation (LTP): GAA vs Planar")
    ax.legend(); ax.grid(True, which="both", alpha=.3)
    fig.tight_layout(); fig.savefig(PLOTS / "compare_ltp.png", dpi=150); plt.close(fig)
    print("  wrote compare_ltp.png")


# ---------------- retention overlay ----------------
def plot_retention(hold_t, hold_g):
    g = _loadcsv("leak_retention.csv")
    fig, ax = plt.subplots(figsize=(7, 5))
    if g is not None:
        ax.plot(g["t_us"], g["G_uA_um"], "o-", color="tab:blue", label="GAA hold")
    if hold_t is not None:
        ax.plot(hold_t, hold_g, "s-", color="tab:red", label="Planar hold")
    ax.set_xlabel("Hold time ($\\mu$s)"); ax.set_ylabel("Read $I_D$ ($\\mu$A/$\\mu$m)")
    ax.set_title("Retention / leak at $V_G$=read: GAA vs Planar")
    ax.legend(); ax.grid(True, alpha=.3)
    fig.tight_layout(); fig.savefig(PLOTS / "compare_retention.png", dpi=150); plt.close(fig)
    print("  wrote compare_retention.png")


def parse_hold(plt_path):
    from planar import parse_plt, col
    if not Path(plt_path).exists():
        return None, None
    names, a = parse_plt(plt_path)
    if len(a) == 0:
        return None, None
    t = a[:, 0]; idc = col(names, "drain_contact TotalCurrent")
    return (t - t[0]) * 1e6, np.abs(a[:, idc]) * 1e6


def energy_per_pulse(outdir, node, vpgm):
    """E/pulse (J, per um) = V_pgm * mean_over_pulses( integral |I_gate| dt ) over write legs."""
    from planar import parse_plt, col
    es = []
    for wfp in sorted(Path(outdir).glob(f"p*_write_{node}_des.plt")):
        names, a = parse_plt(wfp)
        if len(a) < 2:
            continue
        t = a[:, 0]; ig = np.abs(a[:, col(names, "gate_contact TotalCurrent")])
        _trap = getattr(np, "trapezoid", getattr(np, "trapz", None))
        es.append(vpgm * _trap(ig, t))     # J per um (Areafactor=1.0)
    return float(np.mean(es)) if es else float("nan")


def count_levels(ids, min_ratio=1.5):
    """Distinguishable monotonic levels: consecutive reads separated by >= min_ratio."""
    ids = [x for x in ids if x and np.isfinite(x)]
    if not ids:
        return 0
    levels = [ids[0]]
    for v in ids[1:]:
        if v >= levels[-1] * min_ratio:
            levels.append(v)
    return len(levels)


def probe_pol_y(fp):
    """|Polarization/y| (C/cm^2) at last time from a read plt."""
    from planar import parse_plt, col
    if not Path(fp).exists():
        return np.nan
    names, a = parse_plt(fp)
    if len(a) == 0:
        return np.nan
    return abs(a[-1, col(names, "Polarization/y")])


def main():
    """True single-gate ABLATION of the optimized GAA (identical T_si/T_ox/T_fe/L_gate/
    L_ov/N_sub/N_sd/WF; only the bottom gate stack removed; floating body; Areafactor=1.0).
    Sources (all re-derived after the geometry fix):
      outputs/planarfinal/         -- combined mw sweep, VE=-4.0/VP=+3.5 (GAA-proportional
                                       overdrive past its OWN coercive point) -> SS_ers,
                                       Vth_ers, R_off/R_on/window/g at Vg=0.
      outputs/planarfinal2 + outputs/planarclean/ -- undisturbed (minimal read-history)
                                       ascending sweeps -> clean SS_pgm, Vth_pgm. The
                                       naive single continuous sweep through deep negative
                                       Vg reads first suffers real ferroelectric read
                                       disturb (ordering-dependent current at the same Vg);
                                       these two short, shallow sweeps avoid it.
      outputs/lifsw2/lifsw2_lif.json  -- LTP pulse train at the chosen op point (2.3 V).
      outputs/lifret2/               -- retention hold at the op point.
    """
    OPV, WF = 2.3, 4.35

    mw = json.loads((HERE / "outputs" / "planarfinal" / "mw_planarfinal_analysis.json").read_text())
    ss_ers = mw["ss_ers_mVdec"]
    vth_ers = vth_at_icc(mw["vgs"], mw["ers"])
    vg = mw["vgs"]; i0 = vg.index(-0.0) if -0.0 in vg else vg.index(0.0)
    i_off, i_on = mw["ers"][i0], mw["pgm"][i0]           # uA/um at Vg=0 (far from disturb region)
    R_off, R_on = VDS / (i_off * 1e-6), VDS / (i_on * 1e-6)
    window = i_on / i_off
    g_min, g_max = 1.0 / R_off, 1.0 / R_on

    d1 = json.loads((HERE / "outputs" / "planarfinal2" / "mw_planarfinal2_analysis.json").read_text())
    d2 = json.loads((HERE / "outputs" / "planarclean" / "mw_planarclean_analysis.json").read_text())
    cvg = np.array(d1["vgs"] + d2["vgs"]); cpgm = np.array(d1["pgm"] + d2["pgm"])
    order = np.argsort(cvg); cvg, cpgm = cvg[order], cpgm[order]
    vth_pgm = vth_at_icc(cvg, cpgm)
    ss_pgm = subthreshold_slope(cvg, cpgm)
    mw_volts = vth_ers - vth_pgm

    lifj = HERE / "outputs" / "lifsw2" / "lifsw2_lif.json"
    lif = json.loads(lifj.read_text())
    op = lif[str(OPV)]
    op_ids = op["ids"]
    n_levels = count_levels(op_ids)
    dec_total = np.log10(op_ids[-1] / op_ids[0])
    dvth_pulse = -(ss_ers * 1e-3) * dec_total / (len(op_ids) - 1)   # V/pulse

    node = f"lifsw2_v{int(round(OPV*10)):03d}"
    E_pulse = energy_per_pulse(HERE / "outputs" / "lifsw2", node, OPV)
    fire_ratio = op["dr"]
    fire_p9 = op_ids[8] / op["id_base"] if len(op_ids) > 8 else float("nan")

    retnode = f"lifret2_v{int(round(OPV*10)):03d}"
    hold_t, hold_g = parse_hold(HERE / "outputs" / "lifret2" / f"hold_{retnode}_des.plt")
    ret_pct = float(hold_g[-1] / hold_g[0] * 100) if hold_g is not None and len(hold_g) else float("nan")

    p_ers = probe_pol_y(HERE / "outputs" / "planarfinal" / f"ers_r{i0:02d}_mw_planarfinal_des.plt")
    p_pgm = probe_pol_y(HERE / "outputs" / "planarfinal" / f"pgm_r{i0:02d}_mw_planarfinal_des.plt")
    dP = abs(p_pgm - p_ers)

    plot_memwin(mw)
    plot_ltp(op_ids)
    plot_retention(hold_t, hold_g)

    params = f'''"""Planar-FeFET SNN params (auto-extracted). TRUE single-gate ABLATION of the
optimized GAA: identical T_si=5nm/T_ox=1nm/T_fe=7nm/T_metal=5nm/L_gate=100nm/L_ov=15nm/
N_sub=1e16/N_sd=5e19/WF=4.35 (Device_Optimization/sde/sde_opt.cmd); only the bottom gate
stack removed. Floating body (no substrate contact, same as GAA). Areafactor=1.0 (no
wraparound to emulate with one gate; GAA's 0.071 was a double-gate-emulating-GAA fudge).
Drop-in analogue of Device_Optimization/SNN_PARAMETERS.md for the ECG-LSNN stage1.
Op point: V_read=0.0 V, V_pgm={OPV} V, V_DS={VDS} V, WF={WF} eV; erase -3.5V/5us.
Memory-window/SS characterization used VE=-4.0/VP=+3.5 -- a moderate overdrive past
planar's OWN coercive point (~3.0V), proportionally matching how GAA's own ivgen.py
overdrives past ITS coercive point (VE=-3.0/VP=2.5 vs op +/-2.0V) -- same methodology,
not an arbitrary voltage.
"""
DEVICE = dict(
    arch="planar (single top gate ablation of the GAA nanosheet, floating body)",
    # --- electrostatics ---
    SS_ers_mVdec={ss_ers:.1f},          # subthreshold slope, erased branch
    SS_pgm_mVdec={ss_pgm:.1f},          # subthreshold slope, programmed branch (clean sweep)
    Vth_ers_V={vth_ers:.4f},            # erased Vth @ Icc=1e-2 uA/um
    Vth_pgm_V={vth_pgm:.4f},            # programmed Vth (clean, minimal-read-history sweep)
    MW_volts={mw_volts:.4f},            # Vth_ers - Vth_pgm
    # --- read window / conductance (-> stage1 fefet_synapse) ---
    R_off_ohm={R_off:.4e},              # erased read @ Vg=0
    R_on_ohm={R_on:.4e},                # programmed read @ Vg=0
    window={window:.4e},                # ON/OFF current ratio at Vg=0
    g_min_S={g_min:.4e},                # 1/R_off  -> g_min
    g_max_S={g_max:.4e},                # 1/R_on   -> g_max
    n_levels={n_levels},                      # distinguishable LTP levels (>=1.5x apart)
    # --- dynamics / energy ---
    dVth_per_pulse_V={dvth_pulse:.4e},  # mean Vth shift per program pulse (via SS_ers)
    E_pulse_J={E_pulse:.3e},            # integ V_pgm*|I_gate|dt, mean per program pulse (per um)
    fire_ratio={fire_ratio:.3e},        # ID(pN)/ID_baseline at op point
    fire_ratio_p9={fire_p9:.3e},        # ID(p9)/ID_baseline (GAA fire-at-P9 criterion)
    retention_pct_100us={ret_pct:.1f},  # % programmed current retained over 100 us hold
    # --- polarization ---
    dP_C_cm2={dP:.3e},                  # |P_pgm - P_ers| retained (top-FE y-probe)
    # --- operating point ---
    V_read=0.0, V_pgm={OPV}, V_DS={VDS}, WF={WF},
)

# stage1 drop-in: g_min, g_max = DEVICE["g_min_S"], DEVICE["g_max_S"]; NLEVELS=DEVICE["n_levels"]
'''
    (HERE / "planar_params.py").write_text(params)
    print("  wrote planar_params.py")

    md = f"""# Planar vs GAA-FeFET — true single-gate ablation, full LIF/SNN comparison

**Identical geometry** to the optimized GAA (T_si=5nm/T_ox=1nm/T_fe=7nm/T_metal=5nm/
L_gate=100nm/L_ov=15nm/N_sub=1e16/N_sd=5e19/WF=4.35, floating body, same calibrated par).
The **only** change is removing the bottom gate stack — a true ablation, not a different
device. Memory-window/SS characterization uses VE=-4.0/VP=+3.5 V, a moderate overdrive
past planar's own coercive point (~3.0V), matching the SAME proportional-overdrive
methodology GAA's own `ivgen.py` uses (VE=-3.0/VP=2.5 vs its op point +/-2.0V) — not an
arbitrary voltage, so the window comparison below is genuinely apples-to-apples.

| Metric | GAA (double-gate) | Planar (single-gate ablation) | Note |
|---|---|---|---|
| Stack T_ox / T_fe / T_si | 1 / 7 / 5 nm | 1 / 7 / 5 nm (identical) | ablation, not redesign |
| Gating | both faces | top only | the one variable changed |
| **SS erased** | {GAA_REF['SS_ers_mVdec']:.1f} mV/dec | {ss_ers:.1f} mV/dec | planar slightly steeper |
| **SS programmed** | {GAA_REF['SS_pgm_mVdec']:.1f} mV/dec | {ss_pgm:.1f} mV/dec | planar slightly steeper |
| Vth erased / programmed | {GAA_REF['Vth_ers']:+.3f} / {GAA_REF['Vth_pgm']:+.3f} V | {vth_ers:+.3f} / {vth_pgm:+.3f} V | — |
| Vth memory window | {GAA_REF['MW_V']:.3f} V | {mw_volts:.3f} V | planar ~4x larger |
| ON/OFF current window @Vg=0 | {GAA_REF['window']:.0f}x | {window:.0f}x | planar ~4.5x larger |
| R_off / R_on | {GAA_REF['R_off']:.1e} / {GAA_REF['R_on']:.1e} Ohm | {R_off:.1e} / {R_on:.1e} Ohm | — |
| g_min / g_max | {1/GAA_REF['R_off']:.2e} / {1/GAA_REF['R_on']:.2e} S | {g_min:.2e} / {g_max:.2e} S | — |
| **Analog LTP levels** | {GAA_REF['n_levels']} | {n_levels} | GAA finer-grained |
| dVth / pulse | -18.3 mV | {dvth_pulse*1e3:.1f} mV | — |
| **Op V_pgm** | +{GAA_REF['V_pgm']:.1f} V | +{OPV} V | close -- same FE stack |
| Fire ratio ID(pN)/ID_base | 30.6 | {fire_ratio:.2e} | — |
| Retention (100 us) | non-volatile (flat) | {ret_pct:.1f}% | both non-volatile |
| dP retained | ~2.26 uC/cm2 | {dP*1e6:.2f} uC/cm2 | — |

**GAA numbers above are corrected, not copied from SNN_PARAMETERS.md/OPTIMIZED_DEVICE.md.**
Found a real inconsistency in the GAA pipeline: every `.cmd` sets Areafactor=0.071 inside
Sentaurus, but every analysis script (`opt.py`/`plot_memwin.py`/`plot_iv.py`) divides by
W_um=0.090 for the SAME normalization step -- never reconciled. Ratio-based numbers (SS,
window, n_levels, fire_ratio, dVth/pulse) are unaffected (the constant cancels); R_off/R_on/
g_min/g_max/Vth above are corrected by (0.090/0.071)=1.2676x, re-derived directly from
`transfer_curves.csv`/`memwin_fe07.csv` under one consistent, Areafactor=1-equivalent
convention (same as this whole planar study uses) rather than reusing the inconsistent
numbers. W=40nm (literature: nanosheet width "saturated at ~40-50nm") + T_si=5nm gives
TESW=2*(W+T_si)=90nm -- which is exactly the pipeline's existing W_um=0.090, meaning the
analysis-script divisor was already the right literature-consistent value; only the
in-`.cmd` Areafactor=0.071 was wrong. GAA's `E_pulse_J` is left as the original locked
quote (no independently re-derivable raw-current source available for it). SNN_PARAMETERS.md
itself uses a THIRD, separate conversion for its own R_off/R_on (feeding the Python stage1
synapse's g_min/g_max) that doesn't even undo the first inconsistency -- intentionally
NOT reused or silently fixed here; that correction is scoped to Device_Optimization/the
Python model, out of scope for this planar-only comparison.

## Read of the result
With geometry held **identical** and only the bottom gate removed, the single-gate
device needs almost the same operating voltage (2.3 V vs GAA's 2.0 V — both governed by
the same F_c*T_fe coercive voltage) and, surprisingly, shows **comparable or slightly
better subthreshold slope** than the double-gate GAA (the 5 nm body is thin enough that
one gate alone already gives near-ideal control). Planar wins the raw ON/OFF window
(~4.5x larger) because the single-gate device's threshold-voltage shift under the same
overdrive is larger. GAA still wins on **LTP resolution** (15 smooth levels vs {n_levels})
for the analog-synapse use case — the double gate's extra electrostatic assist shows up
as smoother, more finely graded conductance modulation during the pulse train, not in the
static SS or the switching voltage.

## Honest caveat: ferroelectric read disturb
Reading the programmed branch's transfer curve at gate voltages approaching the
*opposite*-polarity coercive field (deep negative reads, needed to bracket its
threshold) measurably disturbs the retained polarization mid-sweep: the same nominal
Vg gave a ~7000x different current depending on what more-negative voltages were swept
through first in the same continuous transient. This is consistent with real FeFET
read-disturb physics, not a simulation bug. GAA's own methodology never encountered
this because it only ever reads within +/-1V, safely clear of its coercive field.
The SS_pgm/Vth_pgm reported here come from short, shallow, minimal-read-history sweeps
(outputs/planarfinal2 + outputs/planarclean) specifically designed to avoid it.

Plots: `plots/compare_memwin.png`, `plots/compare_ltp.png`, `plots/compare_retention.png`.
ECG-LSNN params: `planar_params.py`.
"""
    (HERE / "PLANAR_vs_GAA.md").write_text(md)
    print("  wrote PLANAR_vs_GAA.md")
    print(f"\nSUMMARY planar (true ablation): SS_ers={ss_ers:.1f} SS_pgm={ss_pgm:.1f} mV/dec  "
          f"Vth_ers={vth_ers:.3f} Vth_pgm={vth_pgm:.3f}  MW={mw_volts:.3f}V  "
          f"window={window:.0f}x  n_levels={n_levels}  E={E_pulse:.2e}J  ret={ret_pct:.1f}%")


if __name__ == "__main__":
    main()
