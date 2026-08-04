"""Rebuild every csv_export/raw/*.csv from the source .plt files, under norm.py.

Before this script existed the nine raw CSVs had no generator in the repository
-- they were produced ad hoc and their provenance was recorded only in prose (and
in one case, wrongly: see transfer_curves.csv below).  Every figure and every
device parameter in the paper descends from these files, so they get one script.

Provenance (verified numerically against the pre-norm.py files, which this script
reproduces exactly when CORR is set to 1):

  memory_window_iv.csv    outputs/iv_fe07      continuous +-1.5 V retained I-V,
                                               200-point interpolated grid
  memwin_fe07.csv         outputs/mw_fe07      fixed-V_G point reads, 9 points
  memwin_tfe7.csv         outputs/mw_fe07      (same node; T_fe = 7 nm)
  memwin_tfe10.csv        outputs/mw_si05      T_si-sweep baseline, T_fe = 10 nm
  memwin_tfe12.csv        outputs/mw_fe12      T_fe = 12 nm
  transfer_curves.csv     outputs/mwfine       19-point fine sweep, -0.4..+0.5 V
  ltp_potentiation.csv    outputs/t8_ltp       15-pulse LTP train, reads p01..p15
  ltp_vs_temperature.csv  outputs/t9_t250, outputs/t8_ltp, outputs/t9_t350
  leak_retention.csv      outputs/t9_leak      the hold_ segment

PROVENANCE CORRECTION (2026-07-31): PLOT_PLAN.md Part II C1 states that
transfer_curves.csv came from the `iv_fe07` node and therefore inherited
`app_frozen.par` (tau_E = tau_P = 1e-4).  That is wrong.  transfer_curves.csv is
reproduced bit-for-bit from the `mwfine` node, which ran `app_opt.par`
(tau_E=1e-6, tau_P=1e-5) like every other figure -- see runs/mwfine_fe07_des.cmd.
So there is no tau protocol split behind Vth_virgin / Vth_fire / SS / MW, and the
21 % "erased at V_G=0" gap between transfer_curves.csv (7.766e-3) and
memwin_fe07.csv (9.407e-3) is not a par difference: it is two runs of the same
protocol with different read-point schedules (mwfine walks 19 read points, mw_fe07
walks 9), so the retained state creeps by a different amount between them.

Usage:
  python rebuild_raw.py            rebuild all nine
  python rebuild_raw.py --verify   rebuild, then assert each == legacy * norm.CORR
"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
DEVOPT = HERE.parent
sys.path.insert(0, str(DEVOPT))
import norm                       # noqa: E402  the one width convention
from plt2csv import parse_plt     # noqa: E402

OUTPUTS = DEVOPT / "outputs"
RAW = HERE / "raw"
LEGACY = HERE / "raw_PREFIX_BACKUP"   # pre-norm.py snapshot, for --verify

COL_ID = "drain_contact TotalCurrent"
COL_VG = "gate_contact OuterVoltage"


def _last(fp):
    return parse_plt(fp).iloc[-1]


def _uA(x):
    return norm.to_uA_per_um(abs(np.asarray(x, float)))


def _write(name, df):
    RAW.mkdir(parents=True, exist_ok=True)
    df.to_csv(RAW / name, index=False, float_format="%.6e")
    print(f"  {name:26s} {len(df):4d} rows")


# ----------------------------------------------------------------- point-read memory window
def point_reads(node, mesh, n=9):
    """Fixed-V_G point reads: one ers_rNN / pgm_rNN plt pair per read voltage."""
    d = OUTPUTS / node
    vg, ie, ip = [], [], []
    for i in range(n):
        fe = d / f"ers_r{i:02d}_mw_{mesh}_des.plt"
        fp = d / f"pgm_r{i:02d}_mw_{mesh}_des.plt"
        if not fe.exists():
            continue
        re_, rp = _last(fe), _last(fp)
        vg.append(re_[COL_VG])
        ie.append(_uA(re_[COL_ID]))
        ip.append(_uA(rp[COL_ID]))
    return pd.DataFrame({"Vg_V": np.round(vg, 3),
                         "Id_erased_uA_um": ie, "Id_programmed_uA_um": ip})


def fine_reads(node="mwfine", mesh="mwfine_fe07"):
    d = OUTPUTS / node
    vg, ie, ip = [], [], []
    for fe in sorted(d.glob(f"ers_r*_{mesh}_des.plt")):
        idx = fe.name.split("_")[1]
        rp = _last(d / f"pgm_{idx}_{mesh}_des.plt")
        re_ = _last(fe)
        vg.append(re_[COL_VG])
        ie.append(_uA(re_[COL_ID]))
        ip.append(_uA(rp[COL_ID]))
    return pd.DataFrame({"Vg_V": np.round(vg, 3),
                         "Id_erased_uA_um": ie, "Id_programmed_uA_um": ip})


# ----------------------------------------------------------------- continuous retained I-V
def continuous_iv(node="iv_fe07", tag="iv_fe07", n_grid=200):
    d = OUTPUTS / node
    e, p = parse_plt(d / f"ers_{tag}_des.plt"), parse_plt(d / f"pgm_{tag}_des.plt")
    ve, ie = e[COL_VG].values, _uA(e[COL_ID].values)
    vp, ip = p[COL_VG].values, _uA(p[COL_ID].values)
    grid = np.linspace(max(ve.min(), vp.min()), min(ve.max(), vp.max()), n_grid)
    return pd.DataFrame({"Vg_V": grid,
                         "Id_erased_uA_um": np.interp(grid, ve, ie),
                         "Id_programmed_uA_um": np.interp(grid, vp, ip)})


# ----------------------------------------------------------------- pulse trains
def ltp_train(node, n=15):
    d = OUTPUTS / node
    return [_uA(_last(d / f"p{k:02d}_read_{node}_v020_des.plt")[COL_ID]) for k in range(1, n + 1)]


def retention_hold(node="t9_leak"):
    h = parse_plt(OUTPUTS / node / f"hold_{node}_v020_des.plt")
    t = h["time"].values
    return pd.DataFrame({"t_us": (t - t[0]) * 1e6, "G_uA_um": _uA(h[COL_ID].values)})


# ----------------------------------------------------------------- driver
def rebuild():
    print("rebuilding csv_export/raw/ under norm.py "
          f"(W_eff={norm.W_EFF_UM*1e3:.0f} nm, CORR={norm.CORR:.6f})")

    mw07 = point_reads("mw_fe07", "fe07")
    _write("memwin_fe07.csv", mw07)
    _write("memwin_tfe7.csv", mw07)
    _write("memwin_tfe10.csv", point_reads("mw_si05", "si05"))
    _write("memwin_tfe12.csv", point_reads("mw_fe12", "fe12"))
    _write("transfer_curves.csv", fine_reads())
    _write("memory_window_iv.csv", continuous_iv())

    _write("ltp_potentiation.csv",
           pd.DataFrame({"pulse_n": range(1, 16), "Id_uA_per_um": ltp_train("t8_ltp")}))
    _write("ltp_vs_temperature.csv",
           pd.DataFrame({"pulse_n": range(1, 16),
                         "G_250K_uA_um": ltp_train("t9_t250"),
                         "G_300K_uA_um": ltp_train("t8_ltp"),
                         "G_350K_uA_um": ltp_train("t9_t350")}))
    _write("leak_retention.csv", retention_hold())


def verify():
    """Every rebuilt current column must equal the legacy column times exactly CORR."""
    ok = True
    for f in sorted(RAW.glob("*.csv")):
        old_fp = LEGACY / f.name
        if not old_fp.exists():
            print(f"  {f.name:26s} SKIP (no legacy snapshot)")
            continue
        new, old = pd.read_csv(f), pd.read_csv(old_fp)
        if new.shape != old.shape:
            print(f"  {f.name:26s} FAIL shape {new.shape} vs {old.shape}")
            ok = False
            continue
        worst = 0.0
        for c in new.columns:
            if c in ("Vg_V", "pulse_n", "t_us"):     # not currents -- must be identical
                # atol=2e-4: the legacy files printed Vg with "%.4f", so agreement
                # is only asserted to their own print precision.
                if not np.allclose(new[c], old[c], rtol=1e-6, atol=2e-4):
                    print(f"  {f.name:26s} FAIL axis column {c} moved")
                    ok = False
                continue
            ratio = new[c].values / old[c].values
            worst = max(worst, float(np.nanmax(np.abs(ratio - norm.CORR))))
        status = "OK" if worst < 1e-6 else "FAIL"
        ok &= worst < 1e-6
        print(f"  {f.name:26s} {status}  max|ratio-CORR| = {worst:.2e}")
    print("VERIFY", "PASS" if ok else "FAIL")
    return ok


if __name__ == "__main__":
    rebuild()
    if "--verify" in sys.argv:
        print("\nverifying against raw_PREFIX_BACKUP (legacy) * CORR:")
        sys.exit(0 if verify() else 1)
