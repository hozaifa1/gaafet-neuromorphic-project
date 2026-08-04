"""Regression check for the single width convention (PLOT_PLAN.md Phase 1D).

Re-derives every headline device number straight from csv_export/raw/*.csv and
asserts it against the corrected target in PLOT_PLAN.md Part I.4.  Run this after
any change to norm.py, rebuild_raw.py, or the raw CSVs.

    python verify_norm.py

THESE ARE NOT THE PAPER'S NUMBERS, and that is deliberate.  This file is a
FIXTURE test: it pins the pre-RR-0 dataset (mw_fe07 / mwfine) so that the
x0.6338 rescale can be shown to have changed nothing but the axis.  It checks
3137x, SS 62.3 mV/dec (steepest-pair) and MW 0.336 V because those are the
values that dataset had before the rescale.

The paper's canonical values come from RR-0 (node iv_fe07b) and are different
measurements, not different arithmetic: 5410x, SS 63.5 mV/dec (>=2-decade fit)
and MW 0.387 V, read after a longer post-write settling time.  See the
"Canonical measurement protocol" section of OPTIMIZED_DEVICE.md.  If this file
is ever updated to the RR-0 numbers it stops being able to detect a
normalization regression, which is its only job.
"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import norm  # noqa: E402

RAW = HERE / "csv_export" / "raw"
VDS = 0.05          # V, the read drain bias used in every retained-state read
ICC_UA_UM = 1e-2    # constant-current V_t criterion, uA/um


def vth_cc(vg, idd, icc=ICC_UA_UM):
    """Rising constant-current V_t, log-interpolated."""
    vg, idd = np.asarray(vg, float), np.asarray(idd, float)
    for k in range(1, len(vg)):
        if idd[k - 1] < icc <= idd[k] and idd[k] > idd[k - 1]:
            f = ((np.log10(icc) - np.log10(idd[k - 1]))
                 / (np.log10(idd[k]) - np.log10(idd[k - 1])))
            return float(vg[k - 1] + f * (vg[k] - vg[k - 1]))
    return float("nan")


def ss_mv_dec(vg, idd):
    """SS = the steepest adjacent-point slope, dV_G / dlog10(I), in mV/dec.

    This is how the published 62.3 mV/dec was obtained (programmed branch, the
    -0.35 -> -0.30 V pair of the fine transfer curve).  It is exactly invariant
    under any uniform current rescale, which is the point of checking it here.
    """
    vg, idd = np.asarray(vg, float), np.asarray(idd, float)
    d = np.diff(vg) / np.diff(np.log10(idd))
    d = d[np.isfinite(d) & (d > 0)]
    return float(np.min(d) * 1000.0) if d.size else float("nan")


def check(label, got, want, tol_rel=0.02, unit=""):
    ok = np.isfinite(got) and abs(got - want) <= tol_rel * abs(want)
    print(f"  [{'OK ' if ok else 'FAIL'}] {label:44s} {got:12.4g} {unit:8s} "
          f"(target {want:.4g})")
    return ok


def main():
    print(f"verify_norm.py  --  W_eff={norm.W_EFF_UM*1e3:.0f} nm, CORR={norm.CORR:.6f}\n")
    ok = True

    # ---- retained memory window at V_G = 0 (mw_fe07, full +-2.0 V write) -----
    mw = pd.read_csv(RAW / "memwin_fe07.csv")
    i0 = int(np.argmin(np.abs(mw.Vg_V)))
    i_on, i_off = mw.Id_programmed_uA_um[i0], mw.Id_erased_uA_um[i0]
    ok &= check("ON current @ V_G=0, programmed", i_on, 18.7, 0.01, "uA/um")
    ok &= check("OFF current @ V_G=0, erased", i_off, 5.96e-3, 0.01, "uA/um")
    ok &= check("ON/OFF retained memory window", i_on / i_off, 3137, 0.01, "x")

    # ---- fine transfer curve: V_t, SS, MW ----------------------------------
    tc = pd.read_csv(RAW / "transfer_curves.csv")
    ok &= check("SS, programmed branch (steepest pair)",
                ss_mv_dec(tc.Vg_V, tc.Id_programmed_uA_um), 62.3, 0.01, "mV/dec")

    # V_t is a constant-current extraction, so it only stays put if the criterion
    # tracks the axis.  Held at the same PHYSICAL current, dV_t must be exactly
    # unchanged -- that is the real invariance test.
    icc_same_physical = ICC_UA_UM * norm.CORR
    vt_ers = vth_cc(tc.Vg_V, tc.Id_erased_uA_um, icc_same_physical)
    vt_pgm = vth_cc(tc.Vg_V, tc.Id_programmed_uA_um, icc_same_physical)
    ok &= check("dV_t at the unchanged physical I_cc", vt_ers - vt_pgm,
                0.336, 0.01, "V")
    print(f"         at I_cc = {icc_same_physical:.3e} uA/um (= the legacy 1e-2 criterion "
          f"read on the corrected axis):\n"
          f"           V_t,ers = {vt_ers:+.4f} V   V_t,pgm = {vt_pgm:+.4f} V   "
          f"MW = {vt_ers - vt_pgm:.4f} V   [unchanged, as it must be]")
    v2e = vth_cc(tc.Vg_V, tc.Id_erased_uA_um)
    v2p = vth_cc(tc.Vg_V, tc.Id_programmed_uA_um)
    print(f"         at a round I_cc = {ICC_UA_UM:g} uA/um on the NEW axis:\n"
          f"           V_t,ers = {v2e:+.4f} V   V_t,pgm = {v2p:+.4f} V   "
          f"MW = {v2e - v2p:.4f} V   [criterion sensitivity, not a physics change:\n"
          f"           the erased branch crosses inside its ambipolar recovery, where its\n"
          f"           local slope is ~159 mV/dec, so its V_t is criterion-sensitive]")

    # ---- LTP levels ---------------------------------------------------------
    ltp = pd.read_csv(RAW / "ltp_potentiation.csv")
    ok &= check("LTP level 15", ltp.Id_uA_per_um.iloc[14], 8.31, 0.01, "uA/um")
    ok &= check("LTP level 1", ltp.Id_uA_per_um.iloc[0], 6.39e-4, 0.01, "uA/um")

    # ---- resistances and energy, in true device units -----------------------
    # ID_baseline is the SNN model's erased read current, and it has always come
    # from the fine transfer curve (mwfine), NOT from memwin_fe07 -- the two
    # differ by 21 % (contradiction C2).  Keep that provenance.
    i_off_tc = float(tc.Id_erased_uA_um[np.argmin(np.abs(tc.Vg_V))])
    id_base_A = i_off_tc * 1e-6 * norm.W_EFF_UM                    # A, one nanosheet
    id_fire_A = ltp.Id_uA_per_um.iloc[8] * 1e-6 * norm.W_EFF_UM    # pulse 9 = fire
    ok &= check("R_off = V_DS / I_erased (fine I-V)", VDS / id_base_A, 1.13e8, 0.02, "ohm")
    ok &= check("R_on  = V_DS / I_fire(p9)", VDS / id_fire_A, 3.69e6, 0.02, "ohm")
    ok &= check("energy per program pulse", norm.rescale_legacy(1.4e-17) * 1e15,
                0.0089, 0.02, "fJ")

    print(f"\n  derived device values: ID_baseline = {id_base_A:.4g} A, "
          f"ID_fire = {id_fire_A:.4g} A")
    print("\n" + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
