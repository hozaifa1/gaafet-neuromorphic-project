"""Overlay Liao 2022 Fig. 7 digitised I_D-V_G against the first-run TCAD output.

Reads:
  - digitzed_data.csv (concatenated post-ERS + post-PGM, ordered by digitiser clicks)
  - first_run_outputs/read_postERS_liao2022_des.plt  (Sentaurus DF-ISE)
  - first_run_outputs/read_postPGM_liao2022_des.plt

Produces (all under plots/):
  - liao_only.png         digitised reference, both branches
  - tcad_only.png         TCAD output, both branches
  - main_calibration.png  TCAD lines + Liao markers overlay (absolute |I_D|/W)
  - shape_comparison.png  V_t-aligned + I_on-normalised log overlay (R^2 in [-0.5, +0.5] V)
  - metrics_summary.txt   V_t, MW, SS, R^2, I_on per branch

Implements the Tier-1 acceptance pipeline from PLAN.md.
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import uniform_filter1d

ROOT = Path(__file__).resolve().parent
PLOTS = ROOT / "plots"
CSVS = ROOT / "csvs"

# device scaling --------------------------------------------------------------
# .plt drain current is total contact current for the 2D simulation slice scaled
# internally by AreaFactor=0.071.  To convert to A/um for overlay vs Liao's
# per-width current we divide by the effective channel width.
W_EFF_UM = 0.090
LEAK_FLOOR_A_PER_UM = 3e-9   # log-clip floor to keep log axis sensible
OVERDRIVE_V = 0.4            # I_on anchor (V_G - V_t)

# digitised CSV split: rows 1..57 = post-ERS branch, rows 58..75 = post-PGM
# branch.  Determined by inspection: at V_G ~ +1 V the second block sits ~3x
# above the first block in I_D, i.e. the low-V_t (post-PGM) branch.
ERS_ROWS_END_EXCLUSIVE = 57  # 0-indexed, so rows [0:57] = post-ERS


# ----------------------------------------------------------------------------- plt parsing
def parse_plt(path: Path) -> dict[str, np.ndarray]:
    """Return dict of dataset_name -> 1D array.  DF-ISE text plt loader."""
    text = path.read_text()
    head, _, body = text.partition("Data {")
    body = body.rsplit("}", 1)[0]

    names: list[str] = []
    in_datasets = False
    for line in head.splitlines():
        s = line.strip()
        if s.startswith("datasets"):
            in_datasets = True
            s = s.split("=", 1)[1].strip()
        if in_datasets:
            s = s.replace("[", "").replace("]", "")
            for tok in s.split('"'):
                tok = tok.strip()
                if tok and tok not in (",",):
                    names.append(tok)
            if "]" in line:
                break
    values = np.fromstring(body.replace("\n", " "), sep=" ")
    n_cols = len(names)
    if values.size % n_cols != 0:
        raise ValueError(f"{path}: {values.size} values not divisible by {n_cols} cols")
    arr = values.reshape(-1, n_cols)
    return {name: arr[:, i] for i, name in enumerate(names)}


def extract_id_vg(plt_data: dict[str, np.ndarray]) -> tuple[np.ndarray, np.ndarray]:
    """Pull V_G and |I_D| in A/um from a parsed plt."""
    vg = plt_data["gate_contact OuterVoltage"]
    id_a = np.abs(plt_data["drain_contact TotalCurrent"])
    return vg, id_a / W_EFF_UM


# ----------------------------------------------------------------------------- digitised parsing
def split_digitised(path: Path) -> tuple[tuple[np.ndarray, np.ndarray], tuple[np.ndarray, np.ndarray]]:
    arr = np.loadtxt(path, delimiter=",")
    ers = arr[:ERS_ROWS_END_EXCLUSIVE]
    pgm = arr[ERS_ROWS_END_EXCLUSIVE:]
    ers_sorted = ers[np.argsort(ers[:, 0])]
    pgm_sorted = pgm[np.argsort(pgm[:, 0])]
    return (ers_sorted[:, 0], ers_sorted[:, 1]), (pgm_sorted[:, 0], pgm_sorted[:, 1])


# ----------------------------------------------------------------------------- metric helpers
def vth_cc(v: np.ndarray, i_a_per_um: np.ndarray, iref_a_per_um: float) -> float:
    """Constant-current V_t at the given criterion (A/um), linear-interpolated."""
    for k in range(1, len(v)):
        a, b = i_a_per_um[k - 1], i_a_per_um[k]
        if (a < iref_a_per_um <= b) or (b < iref_a_per_um <= a):
            return v[k - 1] + (iref_a_per_um - a) * (v[k] - v[k - 1]) / (b - a)
    return float("nan")


def subthreshold_slope(v: np.ndarray, i_a_per_um: np.ndarray) -> float:
    """SS in mV/dec from the steepest local slope of log10(I) vs V."""
    log_i = np.log10(np.maximum(i_a_per_um, 1e-15))
    grads = np.gradient(log_i, v)
    grads_sm = uniform_filter1d(grads, 3)
    imax = int(np.argmax(np.abs(grads_sm)))
    lo = max(0, imax - 4)
    hi = min(len(v), imax + 5)
    if hi - lo < 3:
        return float("nan")
    p = np.polyfit(v[lo:hi], log_i[lo:hi], 1)
    return abs(1000.0 / p[0])


def smooth_log(v: np.ndarray, i_a_per_um: np.ndarray, window: int = 7, n: int = 200) -> tuple[np.ndarray, np.ndarray]:
    if len(v) < window:
        return v, i_a_per_um
    log_i = np.log10(np.maximum(i_a_per_um, 1e-15))
    log_sm = uniform_filter1d(log_i, window, mode="nearest")
    vg = np.linspace(v.min(), v.max(), n)
    return vg, 10.0 ** np.interp(vg, v, log_sm)


def i_at_overdrive(v: np.ndarray, i_a_per_um: np.ndarray, vt: float, overdrive: float) -> float:
    target_v = vt + overdrive
    target_v = min(max(target_v, v.min()), v.max())
    log_i = np.log10(np.maximum(i_a_per_um, 1e-15))
    return float(10.0 ** np.interp(target_v, v, log_i))


def r2_log_window(va: np.ndarray, ia: np.ndarray, vb: np.ndarray, ib: np.ndarray,
                  vlo: float, vhi: float) -> float:
    vlo = max(vlo, va.min(), vb.min())
    vhi = min(vhi, va.max(), vb.max())
    if vhi - vlo < 0.1:
        return float("nan")
    grid = np.linspace(vlo, vhi, 60)
    log_a = np.interp(grid, va, np.log10(np.maximum(ia, 1e-15)))
    log_b = np.interp(grid, vb, np.log10(np.maximum(ib, 1e-15)))
    ss_res = float(np.sum((log_a - log_b) ** 2))
    ss_tot = float(np.sum((log_b - log_b.mean()) ** 2))
    return 1.0 - ss_res / ss_tot if ss_tot > 0 else float("nan")


def clip_log(i: np.ndarray) -> np.ndarray:
    return np.clip(np.abs(i), LEAK_FLOOR_A_PER_UM, None)


# ----------------------------------------------------------------------------- main
@dataclass(frozen=True)
class Branch:
    name: str
    color: str
    v: np.ndarray
    i: np.ndarray
    vt: float
    ss: float
    ion: float


def main() -> None:
    PLOTS.mkdir(exist_ok=True)
    CSVS.mkdir(exist_ok=True)

    # ---- TCAD --------------------------------------------------------------
    # Override input via env: AUTOCAL_DIR (dir) + AUTOCAL_TAG (node tag).
    import os
    _dir = ROOT / os.environ.get("AUTOCAL_DIR", "first_run_outputs")
    _tag = os.environ.get("AUTOCAL_TAG", "liao2022")
    pgm_plt = parse_plt(_dir / f"read_postPGM_{_tag}_des.plt")
    ers_plt = parse_plt(_dir / f"read_postERS_{_tag}_des.plt")
    v_pgm_t, i_pgm_t = extract_id_vg(pgm_plt)
    v_ers_t, i_ers_t = extract_id_vg(ers_plt)

    # Sort by V_G (sweep was monotonic, but be safe)
    o = np.argsort(v_pgm_t); v_pgm_t, i_pgm_t = v_pgm_t[o], i_pgm_t[o]
    o = np.argsort(v_ers_t); v_ers_t, i_ers_t = v_ers_t[o], i_ers_t[o]

    # ---- Liao digitised ----------------------------------------------------
    (v_ers_d, i_ers_d), (v_pgm_d, i_pgm_d) = split_digitised(ROOT / "digitzed_data.csv")
    v_ers_dsm, i_ers_dsm = smooth_log(v_ers_d, i_ers_d, window=7)
    v_pgm_dsm, i_pgm_dsm = smooth_log(v_pgm_d, i_pgm_d, window=7)

    # ---- metrics -----------------------------------------------------------
    # V_t constant-current at 100 nA/um (n-channel standard for SS regime)
    IREF_TCAD = 1e-7   # 100 nA/um — both TCAD curves cross this in subthreshold
    IREF_LIAO = 1e-7   # same criterion for fair MW comparison

    vt_pgm_t = vth_cc(v_pgm_t, i_pgm_t, IREF_TCAD)
    vt_ers_t = vth_cc(v_ers_t, i_ers_t, IREF_TCAD)
    vt_pgm_d = vth_cc(v_pgm_dsm, i_pgm_dsm, IREF_LIAO)
    vt_ers_d = vth_cc(v_ers_dsm, i_ers_dsm, IREF_LIAO)
    mw_tcad = vt_ers_t - vt_pgm_t
    mw_liao = vt_ers_d - vt_pgm_d

    ss_pgm_t = subthreshold_slope(v_pgm_t, i_pgm_t)
    ss_ers_t = subthreshold_slope(v_ers_t, i_ers_t)
    ss_pgm_d = subthreshold_slope(v_pgm_dsm, i_pgm_dsm)
    ss_ers_d = subthreshold_slope(v_ers_dsm, i_ers_dsm)

    ion_pgm_t = i_at_overdrive(v_pgm_t, i_pgm_t, vt_pgm_t, OVERDRIVE_V)
    ion_ers_t = i_at_overdrive(v_ers_t, i_ers_t, vt_ers_t, OVERDRIVE_V)
    ion_pgm_d = i_at_overdrive(v_pgm_dsm, i_pgm_dsm, vt_pgm_d, OVERDRIVE_V)
    ion_ers_d = i_at_overdrive(v_ers_dsm, i_ers_dsm, vt_ers_d, OVERDRIVE_V)

    # shape comparison normalisation
    def normalise(v: np.ndarray, i: np.ndarray, vt: float, iref: float) -> tuple[np.ndarray, np.ndarray]:
        return v - vt, i / iref
    x_tcad_pgm, y_tcad_pgm = normalise(v_pgm_t, clip_log(i_pgm_t), vt_pgm_t, ion_pgm_t)
    x_tcad_ers, y_tcad_ers = normalise(v_ers_t, clip_log(i_ers_t), vt_ers_t, ion_ers_t)
    x_liao_pgm, y_liao_pgm = normalise(v_pgm_dsm, i_pgm_dsm, vt_pgm_d, ion_pgm_d)
    x_liao_ers, y_liao_ers = normalise(v_ers_dsm, i_ers_dsm, vt_ers_d, ion_ers_d)

    r2_pgm = r2_log_window(x_tcad_pgm, y_tcad_pgm, x_liao_pgm, y_liao_pgm, -0.5, 0.5)
    r2_ers = r2_log_window(x_tcad_ers, y_tcad_ers, x_liao_ers, y_liao_ers, -0.5, 0.5)

    # ---- plot styling ------------------------------------------------------
    plt.rcParams.update({"figure.dpi": 110, "font.size": 10, "axes.grid": True,
                         "grid.alpha": 0.3, "axes.axisbelow": True})

    # ---- liao_only ---------------------------------------------------------
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.semilogy(v_pgm_d, i_pgm_d, "ro", ms=4, alpha=0.4, label="post-PGM raw")
    ax.semilogy(v_ers_d, i_ers_d, "bs", ms=4, alpha=0.4, label="post-ERS raw")
    ax.semilogy(v_pgm_dsm, i_pgm_dsm, "r-", lw=1.6, label=f"post-PGM smoothed (V_t={vt_pgm_d:+.2f} V)")
    ax.semilogy(v_ers_dsm, i_ers_dsm, "b-", lw=1.6, label=f"post-ERS smoothed (V_t={vt_ers_d:+.2f} V)")
    ax.axhline(IREF_LIAO, color="gray", ls=":", lw=1, alpha=0.6, label=f"V_t criterion: {IREF_LIAO*1e9:.0f} nA/um")
    ax.set_xlabel("V_G (V)")
    ax.set_ylabel("|I_D| / W (A/um)")
    ax.set_title(f"Liao 2022 Fig. 7 — digitised\n"
                 f"MW = {mw_liao:.2f} V  (paper: 1.30 V),  SS_PGM = {ss_pgm_d:.0f},  SS_ERS = {ss_ers_d:.0f} mV/dec")
    ax.legend(loc="lower right", fontsize=8)
    ax.set_ylim(1e-14, 1e-4)
    fig.tight_layout()
    fig.savefig(PLOTS / "liao_only.png", dpi=140)
    plt.close(fig)

    # ---- tcad_only ---------------------------------------------------------
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.semilogy(v_pgm_t, clip_log(i_pgm_t), "r-", lw=1.8, label=f"post-PGM (V_t={vt_pgm_t:+.2f} V)")
    ax.semilogy(v_ers_t, clip_log(i_ers_t), "b-", lw=1.8, label=f"post-ERS (V_t={vt_ers_t:+.2f} V)")
    ax.axhline(IREF_TCAD, color="gray", ls=":", lw=1, alpha=0.6, label=f"V_t criterion: {IREF_TCAD*1e9:.0f} nA/um")
    ax.axvline(vt_pgm_t, color="r", ls=":", lw=0.8, alpha=0.4)
    ax.axvline(vt_ers_t, color="b", ls=":", lw=0.8, alpha=0.4)
    ax.set_xlabel("V_G (V)")
    ax.set_ylabel("|I_D| / W (A/um)")
    ax.set_title(f"TCAD first-run — V_DS = 0.2 V\n"
                 f"MW = {mw_tcad:.2f} V,  SS_PGM = {ss_pgm_t:.0f},  SS_ERS = {ss_ers_t:.0f} mV/dec")
    ax.legend(loc="lower right", fontsize=8)
    ax.set_ylim(1e-14, 1e-4)
    fig.tight_layout()
    fig.savefig(PLOTS / "tcad_only.png", dpi=140)
    plt.close(fig)

    # ---- main_calibration (absolute, side-by-side) -------------------------
    fig, ax = plt.subplots(figsize=(8, 6))
    ax.semilogy(v_pgm_t, clip_log(i_pgm_t), "r-", lw=2.2, label=f"TCAD post-PGM (V_t={vt_pgm_t:+.2f} V)")
    ax.semilogy(v_ers_t, clip_log(i_ers_t), "b-", lw=2.2, label=f"TCAD post-ERS (V_t={vt_ers_t:+.2f} V)")
    ax.semilogy(v_pgm_d, i_pgm_d, "ro", ms=7, mfc="white", mew=1.8,
                label=f"Liao post-PGM (V_t={vt_pgm_d:+.2f} V)")
    ax.semilogy(v_ers_d, i_ers_d, "bs", ms=7, mfc="white", mew=1.8,
                label=f"Liao post-ERS (V_t={vt_ers_d:+.2f} V)")
    ax.axhline(IREF_TCAD, color="gray", ls=":", lw=1, alpha=0.6)
    ax.annotate(f"MW_TCAD = {mw_tcad:.2f} V\nMW_Liao = {mw_liao:.2f} V (paper 1.30)",
                xy=(0.04, 0.96), xycoords="axes fraction", ha="left", va="top",
                fontsize=10, fontweight="bold",
                bbox=dict(boxstyle="round", fc="lightyellow", ec="orange"))
    ax.set_xlabel("V_G (V)")
    ax.set_ylabel("|I_D| / W (A/um)")
    ax.set_title("Calibration overlay — TCAD vs Liao 2022 Fig. 7 (absolute scale)")
    ax.legend(loc="lower right", fontsize=8)
    ax.set_xlim(-3.0, 3.5)
    ax.set_ylim(1e-14, 1e-4)
    fig.tight_layout()
    fig.savefig(PLOTS / "main_calibration.png", dpi=140)
    plt.close(fig)

    # ---- shape_comparison --------------------------------------------------
    fig, axes = plt.subplots(1, 2, figsize=(13, 5))
    ax = axes[0]
    ax.semilogy(x_tcad_pgm, y_tcad_pgm, "r-", lw=2.0, label="TCAD post-PGM")
    ax.semilogy(x_liao_pgm, y_liao_pgm, "ro", ms=6, mfc="white", mew=1.6, label="Liao post-PGM")
    ax.axvline(0, color="gray", ls=":", lw=1); ax.axhline(1, color="gray", ls=":", lw=1)
    ax.set_xlabel("V_G - V_t (V)")
    ax.set_ylabel(f"I / I_on  (anchor at V_G-V_t = +{OVERDRIVE_V} V)")
    ax.set_title(f"post-PGM shape match\nR^2 = {r2_pgm:.3f} (window [-0.5, +0.5] V),  "
                 f"SS_TCAD = {ss_pgm_t:.0f}, SS_Liao = {ss_pgm_d:.0f} mV/dec")
    ax.legend(loc="lower right", fontsize=9); ax.set_xlim(-1.0, 1.0); ax.set_ylim(1e-6, 5e0)

    ax = axes[1]
    ax.semilogy(x_tcad_ers, y_tcad_ers, "b-", lw=2.0, label="TCAD post-ERS")
    ax.semilogy(x_liao_ers, y_liao_ers, "bs", ms=6, mfc="white", mew=1.6, label="Liao post-ERS")
    ax.axvline(0, color="gray", ls=":", lw=1); ax.axhline(1, color="gray", ls=":", lw=1)
    ax.set_xlabel("V_G - V_t (V)")
    ax.set_ylabel(f"I / I_on  (anchor at V_G-V_t = +{OVERDRIVE_V} V)")
    ax.set_title(f"post-ERS shape match\nR^2 = {r2_ers:.3f} (window [-0.5, +0.5] V),  "
                 f"SS_TCAD = {ss_ers_t:.0f}, SS_Liao = {ss_ers_d:.0f} mV/dec")
    ax.legend(loc="lower right", fontsize=9); ax.set_xlim(-1.0, 1.0); ax.set_ylim(1e-6, 5e0)
    fig.suptitle("SHAPE COMPARISON — V_t-aligned + I_on-normalised", fontsize=11)
    fig.tight_layout()
    fig.savefig(PLOTS / "shape_comparison.png", dpi=140)
    plt.close(fig)

    # ---- metrics summary ---------------------------------------------------
    def grade(label: str, value: float, pass_lo: float, pass_hi: float,
              borderline_lo: float, borderline_hi: float) -> str:
        if pass_lo <= value <= pass_hi:
            verdict = "PASS"
        elif borderline_lo <= value <= borderline_hi:
            verdict = "BORDERLINE"
        else:
            verdict = "FAIL"
        return f"  {label:<22}{value:>10.3f}   [{verdict}]"

    mw_pass = (1.17, 1.43)
    mw_bord = (1.04, 1.56)
    r2_pass = (0.92, 1.01)
    r2_bord = (0.85, 1.01)

    lines = [
        "Tier-1 calibration metrics — Liao 2022 Fig. 7 vs TCAD first-run",
        "=" * 65,
        "",
        "Threshold voltages (constant-current criterion = 100 nA/um):",
        f"  V_t,PGM (TCAD)        {vt_pgm_t:+.3f} V",
        f"  V_t,ERS (TCAD)        {vt_ers_t:+.3f} V",
        f"  V_t,PGM (Liao)        {vt_pgm_d:+.3f} V",
        f"  V_t,ERS (Liao)        {vt_ers_d:+.3f} V",
        f"  Vt offset PGM         {vt_pgm_t - vt_pgm_d:+.3f} V  (TCAD - Liao)",
        f"  Vt offset ERS         {vt_ers_t - vt_ers_d:+.3f} V  (TCAD - Liao)",
        "",
        "Memory window:",
        f"  MW (TCAD)             {mw_tcad:.3f} V",
        f"  MW (Liao)             {mw_liao:.3f} V    (paper reports 1.30 V)",
        grade("MW match TCAD->paper", abs(mw_tcad - 1.30), 0, 0.13, 0, 0.26),
        "",
        "Subthreshold slope (mV/dec):",
        f"  SS_PGM (TCAD)         {ss_pgm_t:.1f}",
        f"  SS_ERS (TCAD)         {ss_ers_t:.1f}",
        f"  SS_PGM (Liao)         {ss_pgm_d:.1f}",
        f"  SS_ERS (Liao)         {ss_ers_d:.1f}",
        "",
        "On-current at V_G - V_t = +0.4 V (A/um):",
        f"  I_on,PGM (TCAD)       {ion_pgm_t:.3e}",
        f"  I_on,ERS (TCAD)       {ion_ers_t:.3e}",
        f"  I_on,PGM (Liao)       {ion_pgm_d:.3e}",
        f"  I_on,ERS (Liao)       {ion_ers_d:.3e}",
        "",
        "Shape-match R^2 (log10 I, V_G - V_t in [-0.5, +0.5] V):",
        grade("R^2 post-PGM", r2_pgm, *r2_pass, *r2_bord),
        grade("R^2 post-ERS", r2_ers, *r2_pass, *r2_bord),
        "",
        "PLAN.md Tier-1 gate (MW within +/-10% of 1.30, R^2 >= 0.92 both):",
        f"  MW gate:    {'PASS' if mw_pass[0] <= mw_tcad <= mw_pass[1] else ('BORDERLINE' if mw_bord[0] <= mw_tcad <= mw_bord[1] else 'FAIL')}",
        f"  R^2 PGM:    {'PASS' if r2_pgm >= 0.92 else ('BORDERLINE' if r2_pgm >= 0.85 else 'FAIL')}",
        f"  R^2 ERS:    {'PASS' if r2_ers >= 0.92 else ('BORDERLINE' if r2_ers >= 0.85 else 'FAIL')}",
    ]
    out = "\n".join(lines) + "\n"
    (PLOTS / "metrics_summary.txt").write_text(out, encoding="utf-8")
    print(out)

    # ---- raw csvs for record ----------------------------------------------
    np.savetxt(CSVS / "tcad_liao_postPGM.csv", np.column_stack([v_pgm_t, i_pgm_t]),
               header="V_G_V,I_D_A_per_um", delimiter=",", comments="")
    np.savetxt(CSVS / "tcad_liao_postERS.csv", np.column_stack([v_ers_t, i_ers_t]),
               header="V_G_V,I_D_A_per_um", delimiter=",", comments="")
    np.savetxt(CSVS / "Liao2022_MFMFS_PRG.csv", np.column_stack([v_pgm_d, i_pgm_d]),
               header="V_G_V,I_D_A_per_um", delimiter=",", comments="")
    np.savetxt(CSVS / "Liao2022_MFMFS_ERS.csv", np.column_stack([v_ers_d, i_ers_d]),
               header="V_G_V,I_D_A_per_um", delimiter=",", comments="")


if __name__ == "__main__":
    main()
