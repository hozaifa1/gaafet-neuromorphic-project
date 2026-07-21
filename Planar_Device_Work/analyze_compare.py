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
GAA_REF = dict(R_off=7.14e7, R_on=2.34e6, window=3137.0, n_levels=15,
               E_pulse_J=1.4e-17, MW_V=0.336, SS_mVdec=62.3, arch="GAA (double-gate 5nm nanosheet)")


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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--optag", default="lifsw")   # LTP/op-point sweep tag
    ap.add_argument("--opv", type=float, required=True)  # chosen V_pgm
    ap.add_argument("--rettag", default="lifret")  # retention-hold run tag
    ap.add_argument("--wf", type=float, default=4.35)
    a = ap.parse_args()

    mwj = HERE / "outputs" / "planar" / "mw_planar_analysis.json"
    planar_mw = json.loads(mwj.read_text()) if mwj.exists() else None

    lifj = HERE / "outputs" / a.optag / f"{a.optag}_lif.json"
    lif = json.loads(lifj.read_text()) if lifj.exists() else {}
    opv_key = str(a.opv) if str(a.opv) in lif else str(int(a.opv)) if str(int(a.opv)) in lif else None
    op = lif.get(opv_key) if opv_key else None
    op_ids = op["ids"] if op else None

    node = f"{a.optag}_v{int(round(a.opv*10)):03d}"
    retnode = f"{a.rettag}_v{int(round(a.opv*10)):03d}"
    hold_t, hold_g = parse_hold(HERE / "outputs" / a.rettag / f"hold_{retnode}_des.plt")

    plot_memwin(planar_mw)
    plot_ltp(op_ids)
    plot_retention(hold_t, hold_g)

    # ---- planar params ----
    if planar_mw:
        vg = planar_mw["vgs"]; i0 = vg.index(0.0)
        i_off = planar_mw["ers"][i0]; i_on = planar_mw["pgm"][i0]   # uA/um at Vg=0
        R_off = VDS / (i_off * 1e-6); R_on = VDS / (i_on * 1e-6)
        window = i_on / i_off
    else:
        R_off = R_on = window = float("nan")
    g_min, g_max = 1.0 / R_off, 1.0 / R_on
    n_levels = count_levels(op_ids) if op_ids else 0
    E_pulse = energy_per_pulse(HERE / "outputs" / a.optag, node, a.opv)
    fire_ratio = op["dr"] if op else float("nan")
    fire_p9 = (op["ids"][8] / op["id_base"]) if op and op["id_base"] else float("nan")
    # retention: drop from first to last hold sample (fraction retained)
    ret_pct = float(hold_g[-1] / hold_g[0] * 100) if hold_g is not None and len(hold_g) and hold_g[0] else float("nan")

    params = f'''"""Planar-FeFET SNN params (auto-extracted, geometry-only diff vs GAA; same calibrated par).
Drop-in analogue of Device_Optimization/SNN_PARAMETERS.md for the ECG-LSNN stage1.
Device = bulk planar NMOS FeFET, single top MFIS gate SiO2 2nm/HZO 10nm/TiN, p-body 5e17.
Op point: V_read=0.0 V, V_pgm={a.opv} V, V_DS={VDS} V, WF={a.wf} eV.
"""
DEVICE = dict(
    arch="planar (bulk, single top gate)",
    R_off_ohm={R_off:.4e},          # erased read @ Vg=0
    R_on_ohm={R_on:.4e},            # programmed read @ Vg=0
    window={window:.1f},               # ON/OFF ratio at Vg=0
    g_min_S={g_min:.4e},            # 1/R_off  -> stage1 fefet_synapse g_min
    g_max_S={g_max:.4e},            # 1/R_on   -> stage1 fefet_synapse g_max
    n_levels={n_levels},                  # distinguishable LTP levels (>=1.5x apart)
    E_pulse_J={E_pulse:.3e},        # integ V_pgm*|I_gate|dt, mean over write pulses (per um)
    fire_ratio={fire_ratio:.3e},         # ID(pN)/ID_baseline at op point
    fire_ratio_p9={fire_p9:.3e},         # ID(p9)/ID_baseline  (GAA fire-at-P9 criterion)
    retention_pct_100us={ret_pct:.1f},   # % of programmed current retained over 100 us hold
    V_read=0.0, V_pgm={a.opv}, V_DS={VDS}, WF={a.wf},
)

# stage1 drop-in: g_min, g_max = DEVICE["g_min_S"], DEVICE["g_max_S"]; NLEVELS=DEVICE["n_levels"]
'''
    (HERE / "planar_params.py").write_text(params)
    print("  wrote planar_params.py")

    # ---- comparison table ----
    md = f"""# Planar vs GAA-FeFET — LIF/SNN characteristic comparison

Same calibrated FE/interface physics (Liao HZO Preisach P_r=32/P_s=40, F_c=1.4 MV/cm,
Dit 4e12, FixedCharge 7e12, GIDL). **Geometry-only** difference.

| Metric | GAA (double-gate 5nm nanosheet) | Planar (bulk, single top gate) |
|---|---|---|
| Stack T_ox / T_fe | 1 nm / 7 nm | 2 nm / 10 nm |
| Body | 5 nm nanosheet, double-gate | 50 nm bulk, single top gate |
| ON/OFF window @Vg=0 | {GAA_REF['window']:.0f}x | {window:.1f}x |
| R_off | {GAA_REF['R_off']:.2e} ohm | {R_off:.2e} ohm |
| R_on | {GAA_REF['R_on']:.2e} ohm | {R_on:.2e} ohm |
| g_min = 1/R_off | {1/GAA_REF['R_off']:.3e} S | {g_min:.3e} S |
| g_max = 1/R_on | {1/GAA_REF['R_on']:.3e} S | {g_max:.3e} S |
| Analog LTP levels | {GAA_REF['n_levels']} | {n_levels} |
| Op V_pgm | +2.0 V | +{a.opv} V |
| E / program pulse (per um) | ~{GAA_REF['E_pulse_J']:.1e} J | {E_pulse:.2e} J |
| Fire ratio ID(p9)/ID_base | 30.6 | {fire_p9:.2e} |
| Retention (100 us hold) | non-volatile (~flat) | {ret_pct:.0f}% |

Plots: `plots/compare_memwin.png`, `plots/compare_ltp.png`, `plots/compare_retention.png`.
Params for the ECG-LSNN: `planar_params.py` (g_min/g_max/n_levels/energy).
"""
    (HERE / "PLANAR_vs_GAA.md").write_text(md)
    print("  wrote PLANAR_vs_GAA.md")
    print(f"\nSUMMARY  planar window={window:.1f}x  R_off={R_off:.2e}  R_on={R_on:.2e}  "
          f"n_levels={n_levels}  E_pulse={E_pulse:.2e}J  fire_ratio={fire_ratio:.2f}")


if __name__ == "__main__":
    main()
