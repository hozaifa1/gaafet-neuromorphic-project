"""True memory-window I-V from fixed-V_G point reads (mw_*.cmd output).
Erased vs programmed retained current at each V_G -> window + best read point."""
import sys, csv
import numpy as np
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path

HERE = Path(__file__).resolve().parent
NCOLS, COL_ID, COL_VG = 29, 7, 17
W_um = 0.090
VGS = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]


def last(fp):
    t = Path(fp).read_text().split("Data {")[1].split("}")[0].strip()
    a = np.array([float(x) for x in t.split()]).reshape(-1, NCOLS)
    return a[-1]


def state_curve(d, mesh, state):
    vg, idd = [], []
    for i in range(len(VGS)):
        fp = d / f"{state}_r{i:02d}_mw_{mesh}_des.plt"
        if not fp.exists():
            continue
        r = last(fp)
        vg.append(r[COL_VG]); idd.append(abs(r[COL_ID]) * 1e6 / W_um)
    return np.array(vg), np.array(idd)


def main(d, mesh="fe07"):
    d = Path(d)
    vge, ide = state_curve(d, mesh, "ers")
    vgp, idp = state_curve(d, mesh, "pgm")
    # window = |log ratio| at each common Vg; pick best read (max separation, erased low)
    ratio = idp / np.maximum(ide, 1e-30)
    # for an n-FeFET LIF: "fired/programmed" should be the ON state; report max |ratio or 1/ratio|
    sep = np.maximum(ratio, 1.0 / np.maximum(ratio, 1e-30))
    kb = int(np.argmax(sep))
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.semilogy(vge, ide, "o-", label="erased")
    ax.semilogy(vgp, idp, "s-", label="programmed")
    ax.axvline(VGS[kb], color="g", ls="--", label=f"best read {VGS[kb]:+.2f} V (sep {sep[kb]:.0f}x)")
    ax.set_xlabel("V_G (V)"); ax.set_ylabel("retained |I_D| (µA/µm)")
    ax.set_title(f"{mesh}: true memory window (fixed-Vg reads, real par)")
    ax.legend(fontsize=9); ax.grid(alpha=0.3, which="both")
    fig.tight_layout()
    out = HERE / "plots" / f"memwin_{mesh}.png"; out.parent.mkdir(exist_ok=True)
    fig.savefig(out, dpi=160); plt.close(fig)
    cdir = HERE / "csv_export" / "raw"; cdir.mkdir(parents=True, exist_ok=True)
    with open(cdir / f"memwin_{mesh}.csv", "w", newline="") as f:
        w = csv.writer(f); w.writerow(["Vg_V", "Id_erased_uA_um", "Id_programmed_uA_um"])
        for a, b, c in zip(vge, ide, idp):
            w.writerow([f"{a:.3f}", f"{b:.6e}", f"{c:.6e}"])
    print(f"erased Id:    {np.array2string(ide, formatter={'float':lambda x:f'{x:.2e}'})}")
    print(f"programmed:   {np.array2string(idp, formatter={'float':lambda x:f'{x:.2e}'})}")
    print(f"BEST READ V_G = {VGS[kb]:+.2f} V, separation = {sep[kb]:.1f}x")
    print(f"  erased={ide[kb]:.3e}, programmed={idp[kb]:.3e} uA/um -> {out.name}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else str(HERE / "outputs" / "mw_fe07"))
