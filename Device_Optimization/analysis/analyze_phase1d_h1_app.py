"""
Phase 1D - H1 V_pgm operating-point sweep analysis.

Reads SWB sweep nodes n2,n4,n5,n6,n7 from H1sweep_outputs/, each with:
  - baseline_pre_  (pre-train read at vg=0.2V, vds=0.05V)
  - p01_read_ ... p09_read_  (post-pulse read at vg=0.2V after each pulse)
  - p01_write_ ... p09_write_ (in-pulse polarization snapshots)

Extracts per-node:
  - ID_baseline, ID_p09 (end of pulse-9 read at vg=0.2V)
  - fire_ratio = ID_p09 / ID_baseline      (M2 target: >=1.5)
  - per-pulse ID-staircase + monotonicity flag
  - peak |Pol/y| during pulse 9 hold (saturation indicator)
  - peak |E/y| during pulse 9 hold      (compare vs F_c = 1.2 MV/cm)
  - cumulative gate charge over the entire train (analytical E_gate estimate)

Output:
  Simulations/phase1d_h1/h1_summary.csv  (one row per V_pgm node)
  Simulations/phase1d_h1/h1_staircase.png
  Simulations/phase1d_h1/h1_fire_ratio.png
  Simulations/phase1d_h1/h1_metrics.txt
"""
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import csv

ROOT = Path(__file__).resolve().parent.parent
H1   = ROOT / "Simulations" / "simH_optimize" / "H1sweep_app_outputs"
OUT  = ROOT / "Simulations" / "phase1d_h1_app"
OUT.mkdir(exist_ok=True)
W_eff_um = 0.090   # same effective width used in H0a v5

# SWB node -> V_pgm mapping (H1 v2, Goal-driven gate, 2026-05-11)
NODES = {
    "n2": ("V_pgm=1.0", 1.0),
    "n4": ("V_pgm=1.5", 1.5),
    "n5": ("V_pgm=2.0", 2.0),
    "n6": ("V_pgm=2.5", 2.5),
    "n8": ("V_pgm=3.0", 3.0),
    "n9": ("V_pgm=3.5", 3.5),
    "n10": ("V_pgm=4.0", 4.0),
    "n11": ("V_pgm=4.5", 4.5),
    "n12": ("V_pgm=5.0", 5.0),
    "n7": ("V_pgm=6.0", 6.0),
}

NCOLS = 29
COL_TIME   = 0
COL_VD     = 1
COL_ID     = 7    # drain_contact TotalCurrent
COL_VG     = 17   # gate_contact OuterVoltage
COL_QG     = 24   # gate_contact Charge
COL_POLY   = 26   # Pos(0,0.0145) Polarization/y  [uC/cm^2 per Sentaurus]
COL_EY     = 28   # Pos(0,0.0145) ElectricField/y [V/cm]


def parse_plt(fp):
    txt = fp.read_text()
    data = txt.split("Data {")[1].split("}")[0].strip()
    if not data:
        return np.empty((0, NCOLS))
    nums = np.array([float(x) for x in data.split()])
    return nums.reshape(-1, NCOLS)


def end_row(fp):
    """Return the LAST row (steady-state at end of phase)."""
    arr = parse_plt(fp)
    if len(arr) == 0:
        return None
    return arr[-1]


def collect_node(node):
    """Return dict of arrays/scalars for one SWB node."""
    out = {"node": node, "V_pgm": NODES[node][1]}

    # ID at end of baseline_pre  (final time row)
    base_fp = H1 / f"baseline_pre_{node}_des.plt"
    if not base_fp.exists():
        out["ok"] = False
        return out
    out["ID_baseline"] = abs(end_row(base_fp)[COL_ID]) * 1e6 / W_eff_um  # uA/um

    # ID at end of each post-pulse read
    id_per_pulse = []
    pol_at_write_end = []
    ey_at_write_end = []
    qg_at_write_end = []
    for k in range(1, 10):
        rfp = H1 / f"p{k:02d}_read_{node}_des.plt"
        wfp = H1 / f"p{k:02d}_write_{node}_des.plt"
        if not rfp.exists() or not wfp.exists():
            id_per_pulse.append(np.nan)
            pol_at_write_end.append(np.nan)
            ey_at_write_end.append(np.nan)
            qg_at_write_end.append(np.nan)
            continue
        er = end_row(rfp)
        ew = end_row(wfp)
        id_per_pulse.append(abs(er[COL_ID]) * 1e6 / W_eff_um)
        pol_at_write_end.append(ew[COL_POLY])
        ey_at_write_end.append(ew[COL_EY])
        qg_at_write_end.append(ew[COL_QG])

    out["ID_per_pulse"] = np.array(id_per_pulse)        # uA/um
    out["Pol_y_per_pulse"] = np.array(pol_at_write_end) # in raw Sentaurus units (C/cm^2)
    out["Ey_per_pulse"]  = np.array(ey_at_write_end)    # V/cm

    # fire_ratio + monotonicity
    out["fire_ratio"] = out["ID_per_pulse"][-1] / out["ID_baseline"]
    # monotonic if each successive ID >= previous (allow tiny noise)
    diffs = np.diff(out["ID_per_pulse"])
    out["monotonic"] = bool(np.all(diffs >= -1e-3 * np.max(np.abs(out["ID_per_pulse"]))))
    out["delta_ID_per_pulse"] = diffs

    # cumulative gate charge integrated across writes only (analytical E_gate)
    # Approximate: read Q_g at start vs end of train.
    # We don't currently capture Q_g at p01_write start; use baseline Q_g and p09_write end.
    out["Qg_baseline"] = end_row(base_fp)[COL_QG]
    out["Qg_p09"]      = qg_at_write_end[-1]

    out["ok"] = True
    return out


def main():
    rows = []
    for nd in NODES:
        rows.append(collect_node(nd))

    # ---- Print + write text report ----
    lines = ["=== Phase 1D H1 v3 — V_pgm sweep summary (sub-V_t read) ===\n",
             f"Effective W = {W_eff_um} um. Read level V_GS = -0.5 V (sub-V_t). Pulse train: 9 x 100 ns @ V_pgm.",
             ""]
    lines.append(f"{'Node':5s} {'V_pgm':>6s} {'ID_base':>10s} {'ID_p09':>10s} {'fire_ratio':>11s} {'dVth_eff':>10s} {'Pol_p09':>10s} {'|E|_p09':>11s} {'|E|/F_c':>9s} {'mono':>5s}")
    lines.append(f"{'':5s} {'(V)':>6s} {'(uA/um)':>10s} {'(uA/um)':>10s} {'':>11s} {'(mV)':>10s} {'(uC/cm2)':>10s} {'(MV/cm)':>11s} {'(F_c=1.4)':>9s} {'':>5s}")
    F_c = 1.4e6      # V/cm
    SS_PGM = 100.0   # mV/dec, H0a v5 post-PGM
    for r in rows:
        if not r.get("ok"):
            lines.append(f"{r['node']:5s} MISSING")
            continue
        pol_uc = r["Pol_y_per_pulse"][-1] * 1e6
        Ey_mv  = abs(r["Ey_per_pulse"][-1]) / 1e6
        # Convert ID staircase into a Vth-shift estimate using H0a SS=100 mV/dec.
        # In sub-Vt, dlog10(ID) * SS = -dVth. We're above-Vt here so this is an
        # over-estimate of the true Vt shift, but it gives a same-units quantity
        # to compare with the H0a MW=1.40 V anchor.
        ratio = r["ID_per_pulse"][-1] / r["ID_baseline"]
        dVth_mv = -SS_PGM * np.log10(ratio) if ratio > 0 else float("nan")
        r["dVth_eff_mV"] = dVth_mv
        lines.append(
            f"{r['node']:5s} {r['V_pgm']:6.2f} "
            f"{r['ID_baseline']:10.3g} {r['ID_per_pulse'][-1]:10.3g} "
            f"{r['fire_ratio']:11.3f} {dVth_mv:10.2f} "
            f"{pol_uc:10.3f} {Ey_mv:11.3f} {abs(r['Ey_per_pulse'][-1])/F_c:9.2f} "
            f"{str(r['monotonic']):>5s}"
        )
    lines.append("")

    # ID staircase per node
    lines.append("=== ID staircase (uA/um) per pulse ===")
    hdr = "Node  V_pgm  " + " ".join(f"p{k:02d}" for k in range(1, 10))
    lines.append(hdr)
    for r in rows:
        if not r.get("ok"):
            continue
        vals = " ".join(f"{x:8.3g}" for x in r["ID_per_pulse"])
        lines.append(f"{r['node']:5s} {r['V_pgm']:5.2f}  {vals}")
    lines.append("")

    # Pass/fail line per M2
    lines.append("=== M2 evaluation (fire_ratio >= 1.5) ===")
    for r in rows:
        if not r.get("ok"):
            continue
        status = "PASS" if r["fire_ratio"] >= 1.5 else "FAIL"
        lines.append(f"  V_pgm = {r['V_pgm']:.2f} V  fire_ratio = {r['fire_ratio']:.3f}  {status}")
    lines.append("")

    # Pass/fail line per M7 (V_pgm <= 2.0 V) AND M2
    passing = [r for r in rows if r.get("ok") and r["fire_ratio"] >= 1.5]
    if passing:
        v_opt = min(r["V_pgm"] for r in passing)
        lines.append(f"=== V_pgm_opt = lowest V_pgm meeting M2: {v_opt:.2f} V ===")
        lines.append(f"    M7 (V_pgm <= 2.0 V) {'PASS' if v_opt <= 2.0 else 'FAIL'}")
    else:
        lines.append("=== NO V_pgm meets fire_ratio >= 1.5 — operating-point search FAILED ===")
        lines.append("    Diagnostic: see staircase + |E|/F_c column above.")

    txt = "\n".join(lines)
    print(txt)
    (OUT / "h1_metrics.txt").write_text(txt)

    # ---- CSV ----
    with open(OUT / "h1_summary.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["node", "V_pgm_V", "ID_baseline_uA_per_um", "ID_p09_uA_per_um",
                    "fire_ratio", "monotonic", "Pol_y_p09_uC_per_cm2",
                    "Ey_p09_MV_per_cm", "Ey_over_Fc"])
        for r in rows:
            if not r.get("ok"):
                continue
            w.writerow([r["node"], r["V_pgm"], r["ID_baseline"], r["ID_per_pulse"][-1],
                        r["fire_ratio"], r["monotonic"],
                        r["Pol_y_per_pulse"][-1] * 1e6,
                        abs(r["Ey_per_pulse"][-1]) / 1e6,
                        abs(r["Ey_per_pulse"][-1]) / F_c])

    # ---- Plots ----
    fig, ax = plt.subplots(figsize=(7, 5))
    for r in rows:
        if not r.get("ok"):
            continue
        ax.plot(range(1, 10), r["ID_per_pulse"], "o-",
                label=f"V_pgm = {r['V_pgm']:.1f} V")
    ax.axhline(0, color="gray", lw=0.5)
    ax.set_xlabel("Pulse number")
    ax.set_ylabel("Post-pulse read ID  (µA/µm)")
    ax.set_title("Phase 1D H1 — ID staircase across V_pgm")
    ax.set_yscale("log")
    ax.legend(fontsize=9)
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(OUT / "h1_staircase.png", dpi=160)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(6, 4))
    vpgm = [r["V_pgm"] for r in rows if r.get("ok")]
    fr   = [r["fire_ratio"] for r in rows if r.get("ok")]
    ax.semilogy(vpgm, fr, "o-", color="C3")
    ax.axhline(1.5, color="green", ls="--", label="M2 target = 1.5")
    ax.axhline(1.0, color="gray",  ls=":",  label="no spike")
    ax.set_xlabel("V_pgm (V)")
    ax.set_ylabel("fire_ratio  ID(p9) / ID(baseline)")
    ax.set_title("Phase 1D H1 — fire_ratio vs V_pgm")
    ax.grid(alpha=0.3, which="both")
    ax.legend()
    fig.tight_layout()
    fig.savefig(OUT / "h1_fire_ratio.png", dpi=160)
    plt.close(fig)

    print(f"\nOutputs in {OUT}/")


if __name__ == "__main__":
    main()
