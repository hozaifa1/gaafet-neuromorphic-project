"""Plot retained-state memory-window I-V (erased vs programmed) for the optimized device.
Reads ers_*.plt and pgm_*.plt; plots |I_D| (log) vs V_G; reports the read window."""
import sys
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path

HERE = Path(__file__).resolve().parent
NCOLS, COL_ID, COL_VG = 29, 7, 17
W_um = 0.090


def curve(fp):
    t = Path(fp).read_text().split("Data {")[1].split("}")[0].strip()
    a = np.array([float(x) for x in t.split()]).reshape(-1, NCOLS)
    vg = a[:, COL_VG]
    idd = np.abs(a[:, COL_ID]) * 1e6 / W_um  # uA/um
    return vg, idd


def main(outdir, tag="iv_fe07"):
    d = Path(outdir)
    vg_e, id_e = curve(d / f"ers_{tag}_des.plt")
    vg_p, id_p = curve(d / f"pgm_{tag}_des.plt")

    # read window: at each V_G (interp pgm onto ers grid), ratio pgm/ers
    grid = np.linspace(max(vg_e.min(), vg_p.min()), min(vg_e.max(), vg_p.max()), 200)
    ie = np.interp(grid, vg_e, id_e)
    ip = np.interp(grid, vg_p, id_p)
    ratio = ip / np.maximum(ie, 1e-30)
    kbest = int(np.argmax(ratio))
    vbest, rbest = grid[kbest], ratio[kbest]

    fig, ax = plt.subplots(figsize=(7, 5))
    ax.semilogy(vg_e, id_e, "o-", ms=3, label="erased (reset)")
    ax.semilogy(vg_p, id_p, "s-", ms=3, label="programmed (fired)")
    ax.axvline(vbest, color="g", ls="--", lw=1, label=f"best read V_G={vbest:.2f} V (ratio {rbest:.0f})")
    ax.set_xlabel("V_G (V)"); ax.set_ylabel("|I_D|  (µA/µm)")
    ax.set_title("Optimized GAA-FeFET — retained-state memory window (frozen FE)")
    ax.legend(fontsize=9); ax.grid(alpha=0.3, which="both")
    fig.tight_layout()
    out = HERE / "plots" / "memory_window_iv.png"
    out.parent.mkdir(exist_ok=True)
    fig.savefig(out, dpi=160); plt.close(fig)

    # also dump CSV for the paper
    import csv
    cdir = HERE / "csv_export" / "raw"; cdir.mkdir(parents=True, exist_ok=True)
    with open(cdir / "memory_window_iv.csv", "w", newline="") as f:
        w = csv.writer(f); w.writerow(["Vg_V", "Id_erased_uA_um", "Id_programmed_uA_um"])
        for v, a, b in zip(grid, ie, ip):
            w.writerow([f"{v:.4f}", f"{a:.6e}", f"{b:.6e}"])

    print(f"erased: V_t-region onset; min Id={id_e.min():.2e}, max={id_e.max():.2e}")
    print(f"programmed: min Id={id_p.min():.2e}, max={id_p.max():.2e}")
    print(f"BEST READ V_G = {vbest:.3f} V, pgm/ers ratio = {rbest:.1f}")
    print(f"  at that V_G: erased={np.interp(vbest,grid,ie):.3e}, programmed={np.interp(vbest,grid,ip):.3e} uA/um")
    print(f"figure -> {out}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else str(HERE / "outputs" / "iv_fe07"))
