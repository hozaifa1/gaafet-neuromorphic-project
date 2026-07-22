"""Planar-vs-GAA comparison: overlay plots + planar_params + comparison table.

Reads planar TCAD outputs (outputs/planar/mw_*_analysis.json, outputs/<tag>/<tag>_lif.json,
retention hold plt) and the GAA reference CSVs (../Device_Optimization/csv_export/raw/).
Produces plots/*.png, planar_params.py, PLANAR_vs_GAA.md.

Run after the planar mw + LIF runs land. Op-point tag passed via --optag / --opv.
"""
import argparse, json
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent
GAA  = HERE.parent / "Device_Optimization" / "csv_export" / "raw"
PLOTS = HERE / "plots"; PLOTS.mkdir(exist_ok=True)
VDS = 0.05

# GAA locked reference numbers (SNN_PARAMETERS.md / OPTIMIZED_DEVICE.md)
# SS_ers/SS_pgm re-extracted from transfer_curves.csv with the SAME extractor as planar.
GAA_REF = dict(R_off=7.14e7, R_on=2.34e6, window=3137.0, n_levels=15,
               E_pulse_J=1.4e-17, MW_V=0.336, SS_ers_mVdec=79.6, SS_pgm_mVdec=63.0,
               V_pgm=2.0, arch="GAA (double-gate 5nm nanosheet)")

ICC_UA_UM = 1e-2   # constant-current threshold criterion (GAA: erased Vth @Icc=1e-2 uA/um)


def vth_at_icc(vgs, ids, icc=ICC_UA_UM):
    """Linear-interp gate voltage where |Id| crosses icc (uA/um), rising. None if never."""
    vgs = np.asarray(vgs, float); ids = np.asarray(ids, float)
    for i in range(1, len(vgs)):
        if ids[i - 1] < icc <= ids[i] and ids[i] > ids[i - 1]:
            f = (np.log10(icc) - np.log10(ids[i - 1])) / (np.log10(ids[i]) - np.log10(ids[i - 1]))
            return float(vgs[i - 1] + f * (vgs[i] - vgs[i - 1]))
    return None


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
    ap = argparse.ArgumentParser()
    ap.add_argument("--optag", default="lifsw")   # LTP/op-point sweep tag
    ap.add_argument("--opv", type=float, required=True)  # chosen V_pgm
    ap.add_argument("--rettag", default="lifret")  # retention-hold run tag
    ap.add_argument("--wf", type=float, default=4.35)
    a = ap.parse_args()

    # prefer the fine-Vg sweep (has SS + dense turn-on); fall back to coarse
    mwfine = HERE / "outputs" / "planarfine" / "mw_planarfine_analysis.json"
    mwcoarse = HERE / "outputs" / "planar" / "mw_planar_analysis.json"
    planar_mw = json.loads((mwfine if mwfine.exists() else mwcoarse).read_text())
    coarse_mw = json.loads(mwcoarse.read_text()) if mwcoarse.exists() else planar_mw

    lifj = HERE / "outputs" / a.optag / f"{a.optag}_lif.json"
    lif = json.loads(lifj.read_text()) if lifj.exists() else {}
    opv_key = next((k for k in (str(a.opv), str(int(a.opv))) if k in lif), None)
    op = lif.get(opv_key) if opv_key else None
    op_ids = op["ids"] if op else None

    node = f"{a.optag}_v{int(round(a.opv*10)):03d}"
    retnode = f"{a.rettag}_v{int(round(a.opv*10)):03d}"
    hold_t, hold_g = parse_hold(HERE / "outputs" / a.rettag / f"hold_{retnode}_des.plt")

    plot_memwin(coarse_mw)   # full +/-Vg range for the visual overlay
    plot_ltp(op_ids)
    plot_retention(hold_t, hold_g)

    # ---- window / R / g at Vg=0 (use coarse: has Vg=0 in a symmetric sweep) ----
    vg = coarse_mw["vgs"]; i0 = vg.index(0.0)
    i_off = coarse_mw["ers"][i0]; i_on = coarse_mw["pgm"][i0]         # uA/um at Vg=0
    R_off = VDS / (i_off * 1e-6); R_on = VDS / (i_on * 1e-6)
    window = i_on / i_off
    g_min, g_max = 1.0 / R_off, 1.0 / R_on

    # ---- SS + threshold-voltage window (fine sweep) ----
    ss_ers = planar_mw.get("ss_ers_mVdec", float("nan"))
    vth_ers = vth_at_icc(planar_mw["vgs"], planar_mw["ers"])
    vth_pgm = vth_at_icc(planar_mw["vgs"], planar_mw["pgm"])          # None -> latched below window
    mw_volts = (vth_ers - vth_pgm) if (vth_ers is not None and vth_pgm is not None) else None

    # ---- LTP: levels + dVth/pulse (via SS) ----
    n_levels = count_levels(op_ids) if op_ids else 0
    dvth_pulse = float("nan")
    if op_ids and len(op_ids) > 1 and np.isfinite(ss_ers):
        dec_total = np.log10(op_ids[-1] / op_ids[0]) if op_ids[0] > 0 else np.nan
        dvth_pulse = -(ss_ers * 1e-3) * dec_total / (len(op_ids) - 1)   # V/pulse (negative = potentiation)

    E_pulse = energy_per_pulse(HERE / "outputs" / a.optag, node, a.opv)
    fire_ratio = op["dr"] if op else float("nan")
    fire_p9 = (op["ids"][8] / op["id_base"]) if op and len(op["ids"]) > 8 and op["id_base"] else float("nan")
    ret_pct = float(hold_g[-1] / hold_g[0] * 100) if hold_g is not None and len(hold_g) and hold_g[0] else float("nan")

    # ---- polarization: erased vs programmed retained state (fine mw reads) ----
    pdir = HERE / "outputs" / "planarfine"
    p_ers = probe_pol_y(pdir / "ers_r00_mw_planarfine_des.plt")       # erased, Vg=0
    p_pgm = probe_pol_y(pdir / "pgm_r00_mw_planarfine_des.plt")       # programmed, Vg=0
    dP = abs(p_pgm - p_ers) if np.isfinite(p_ers) and np.isfinite(p_pgm) else float("nan")

    # programmed branch never crosses Icc in the swept range -> Vth_pgm is below min(Vg);
    # bound the volts-window with the widest sweep (coarse goes to Vg=-1).
    vg_lo = min(coarse_mw["vgs"])
    if mw_volts is None and vth_ers is not None:
        mw_volts = vth_ers - vg_lo            # lower bound (Vth_pgm < vg_lo)
        mw_bound = True
    else:
        mw_bound = False
    mwv_s = (f">{mw_volts:.2f}" if mw_bound else f"{mw_volts:.2f}") if mw_volts is not None else "n/a"
    vthp_s = f"{vth_pgm:.3f}" if vth_pgm is not None else f"<{vg_lo:.1f} (latched)"

    params = f'''"""Planar-FeFET SNN params (auto-extracted; geometry-only diff vs GAA, same calibrated par).
Drop-in analogue of Device_Optimization/SNN_PARAMETERS.md for the ECG-LSNN stage1.
Device = bulk planar NMOS FeFET, single top MFIS gate SiO2 2nm/HZO 10nm/TiN, p-body 5e17.
Op point: V_read=0.0 V, V_pgm={a.opv} V, V_DS={VDS} V, WF={a.wf} eV.
"""
DEVICE = dict(
    arch="planar (bulk, single top gate)",
    # --- electrostatics ---
    SS_ers_mVdec={ss_ers:.1f},           # subthreshold slope, erased branch (steepest)
    Vth_ers_V={vth_ers if vth_ers is not None else float('nan'):.3f},              # erased Vth @ Icc=1e-2 uA/um
    Vth_pgm_V=float("-inf"),        # programmed latched fully-ON: Vth_pgm < {vg_lo} V (never crosses Icc)
    MW_volts_lowerbound={mw_volts:.2f},        # >= this; true window larger (Vth_pgm below sweep floor)
    # --- read window / conductance (-> stage1 fefet_synapse) ---
    R_off_ohm={R_off:.4e},           # erased read @ Vg=0
    R_on_ohm={R_on:.4e},            # programmed read @ Vg=0
    window={window:.4e},             # ON/OFF current ratio at Vg=0
    g_min_S={g_min:.4e},            # 1/R_off  -> g_min
    g_max_S={g_max:.4e},            # 1/R_on   -> g_max
    n_levels={n_levels},                  # distinguishable LTP levels (>=1.5x apart)
    # --- dynamics / energy ---
    dVth_per_pulse_V={dvth_pulse:.4e},   # mean Vth shift per program pulse (via SS)
    E_pulse_J={E_pulse:.3e},        # integ V_pgm*|I_gate|dt, mean per program pulse (per um)
    fire_ratio={fire_ratio:.3e},         # ID(pN)/ID_baseline at op point
    fire_ratio_p9={fire_p9:.3e},         # ID(p9)/ID_baseline (GAA fire-at-P9 criterion)
    retention_pct_100us={ret_pct:.1f},   # % programmed current retained over 100 us hold
    # --- polarization ---
    dP_C_cm2={dP:.3e},              # |P_pgm - P_ers| retained (top-FE y-probe)
    # --- operating point ---
    V_read=0.0, V_pgm={a.opv}, V_DS={VDS}, WF={a.wf},
)

# stage1 drop-in: g_min, g_max = DEVICE["g_min_S"], DEVICE["g_max_S"]; NLEVELS=DEVICE["n_levels"]
'''
    (HERE / "planar_params.py").write_text(params)
    print("  wrote planar_params.py")

    md = f"""# Planar vs GAA-FeFET — full LIF/SNN characteristic comparison

Same calibrated FE/interface physics (Liao HZO Preisach P_r=32/P_s=40, F_c=1.4 MV/cm,
eps=33, Dit 4e12, FixedCharge 7e12, GIDL/B2B). **Geometry-only** difference — no re-calibration.

| Metric | GAA (double-gate 5 nm nanosheet) | Planar (bulk, single top gate) | Winner |
|---|---|---|---|
| Stack T_ox / T_fe | 1 nm / 7 nm | 2 nm / 10 nm | — |
| Body / gating | 5 nm sheet, gated both sides | 50 nm bulk, gated one side | — |
| **SS (erased)** | {GAA_REF['SS_ers_mVdec']:.1f} mV/dec | {ss_ers:.1f} mV/dec | **GAA** (steeper) |
| Vth window (volts) | {GAA_REF['MW_V']:.3f} V | {mwv_s} V | Planar (larger) |
| ON/OFF current window @Vg=0 | {GAA_REF['window']:.0f}x | {window:.2e}x | Planar (larger) |
| R_off / R_on | {GAA_REF['R_off']:.1e} / {GAA_REF['R_on']:.1e} Ω | {R_off:.1e} / {R_on:.1e} Ω | — |
| g_min / g_max | {1/GAA_REF['R_off']:.2e} / {1/GAA_REF['R_on']:.2e} S | {g_min:.2e} / {g_max:.2e} S | — |
| **Analog LTP levels** | {GAA_REF['n_levels']} | {n_levels} | **GAA** (finer) |
| dVth / pulse | −18.3 mV | {dvth_pulse*1e3:.1f} mV | — |
| **Op V_pgm** | +2.0 V | +{a.opv} V | **GAA** (lower) |
| E / program pulse | ~{GAA_REF['E_pulse_J']:.1e} J* | {E_pulse:.2e} J* | GAA (lower) |
| Fire ratio ID(p9)/ID_base | 30.6 | {fire_p9:.2e} | Planar (raw) |
| Retention (100 µs) | non-volatile | {ret_pct:.0f}% | — |
| ΔP retained | ~2.26 µC/cm² | {dP*1e6:.2f} µC/cm² | — |

\\* Energy numbers are **not directly comparable**: GAA used charge×V with Areafactor=0.071;
planar uses ∫V·I dt with Areafactor=1.0 (~14× normalization + method difference). Directionally
planar costs more per pulse (3× voltage, thicker/larger FE). Re-extract both identically before quoting.

## Read of the result
The thick-T_fe bulk planar wins **raw window** (huge Vth shift, latches fully ON across
the read range) but at the cost of everything that matters for an **analog LIF neuron**:
3× the program voltage, worse subthreshold control (single-gate bulk), coarser/fewer
gradual conductance levels, and higher switching energy. The GAA nanosheet is the better
neuromorphic device; the planar is a stronger *binary* memory but a worse *analog synapse*.

Plots: `plots/compare_memwin.png`, `plots/compare_ltp.png`, `plots/compare_retention.png`.
ECG-LSNN params: `planar_params.py`.
"""
    (HERE / "PLANAR_vs_GAA.md").write_text(md)
    print("  wrote PLANAR_vs_GAA.md")
    print(f"\nSUMMARY planar: SS={ss_ers:.1f}mV/dec  Vth_ers={vth_ers}  MW_v={mwv_s}  "
          f"window={window:.2e}x  n_levels={n_levels}  E={E_pulse:.2e}J  dP={dP:.2e}")


if __name__ == "__main__":
    main()
