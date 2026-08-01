"""
Figure K3 — ECG accuracy under measured FeFET variability.
==========================================================
Two panels, from two DIFFERENT measurements, because they are not the same quantity and
conflating them is the easy mistake here.

K3a  device-to-device (RR-8, `raw/variability_ensemble.csv`).
     20 runs at the CORNERS of the (Dit +-20 %, FixedCharge +-10 %, T_fe +-0.3 nm) box.
     That is a worst-case ENVELOPE, not a sigma, so it is never fed to the network as a
     Gaussian. It is used the only way it legitimately can be -- deploy the locked network
     onto each corner device under three amounts of per-device calibration:
        none   the compiler targets the NOMINAL ladder and the nominal readout gain; the
               corner device realizes its own conductances instead.     median 0.2426
        gain   one scalar per device: normalize by that device's own g_max, leave the
               ladder SHAPE at nominal (a transimpedance trim).          median 0.7768
        full   per-level write-verify: target that device's own measured ladder. 0.8304
     The full-calibration median equals the nominal device's accuracy to four decimals.

     All 14 adjacent level pairs overlap across the box, which invalidates a SHARED
     15-level grid. It does not mean the device has fewer than 15 levels: each corner is
     internally monotonic, so d2d shifts a device's whole ladder rather than merging its
     rungs. Note also that ensemble overlap does NOT predict accuracy -- 13 of the 14 pairs
     still overlap after a gain trim (`ladder`), yet several of those corners sit at
     nominal. What predicts accuracy is the PER-DEVICE residual (`shape`, K3c).

K3c  what the gain trim leaves. Each corner ladder is a near-rigid log-shift of nominal
     (mean offset up to +-1.0 decade, median 0.51) plus a residual shape error. The shift
     is free to remove; the residual is not. Accuracy after a gain trim tracks the worst
     single-level residual with Spearman -0.85, holding ~0.78-0.83 out to ~0.6 decades and
     collapsing to ~0.25 at ~0.9. Full write-verify is flat against the same axis. That is
     a level-placement spec rather than a restatement of "the levels overlap".

K3b  cycle-to-cycle (RR-8b, `raw/c2c_per_level.csv`).
     The SAME device, the SAME 15-pulse train, 20 repeats. That IS a sigma, so it is the
     legitimate stochastic input. Accuracy vs injected c2c sigma, with the MEASURED sigma
     marked, and a second series quantized only to the levels that pass the 3-sigma
     separability criterion -- levels failing it cannot be rescued by write-verify,
     because c2c blurs the rungs instead of shifting the ladder.

    python fig_k3_variability.py d2d     # K3a: 20 corners, no calibration vs write-verify
    python fig_k3_variability.py gain    # K3a: adds the gain-trim condition
    python fig_k3_variability.py ladder  # ladder-shift statistics (no network evaluation)
    python fig_k3_variability.py shape   # K3c: accuracy vs residual misplacement
    python fig_k3_variability.py c2c     # K3b: the measured cycle-to-cycle sweep
    python fig_k3_variability.py replot  # redraw K3a from saved JSON
"""
import kfig_common as kc          # first: sets sys.path and imports torch before pandas
import os, sys, json
import numpy as np
import pandas as pd
import torch

import figstyle as fs
from fefet_device import measured_levels, V_READ, _RAW as RAW

C2C_SIGMAS = [0.0, 0.05, 0.10, 0.20, 0.30, 0.50]
D2D_JSON = os.path.join(kc.RUNS, "k3a_d2d.json")
GAIN_JSON = os.path.join(kc.RUNS, "k3a_gain.json")


def _lv(u_a_um):
    """uA/um -> conductance tensor in the same units measured_levels() returns."""
    g = np.sort(np.asarray(u_a_um, dtype=float) * 1e-6 / V_READ)
    return torch.from_numpy(g).float()


# ------------------------------------------------------------------ K3a (d2d)
def d2d():
    ens = pd.read_csv(os.path.join(RAW, "variability_ensemble.csv"))
    cols = [f"G{i}_uA_um" for i in range(1, 16)]
    model, fp_state, ev = kc.setup()
    lv_nom, _, gmax_nom = measured_levels()

    kc.deploy(model, fp_state, kc.diff_set(lv_nom, gmax_nom))
    rep_nom = ev()
    print(f"[K3a] nominal device: acc={rep_nom['accuracy']:.4f} "
          f"F1={rep_nom['macro_f1']:.4f}", flush=True)

    rows = []
    for _, r in ens.iterrows():
        lv_d = _lv(r[cols].values)
        gmax_d = float(lv_d[-1])

        tgt, real = kc.paired_diff_sets(lv_nom, gmax_nom, lv_d, gmax_nom)
        kc.deploy(model, fp_state, tgt, real)
        unc = ev()

        kc.deploy(model, fp_state, kc.diff_set(lv_d, gmax_d))
        cal = ev()

        rows.append([r["node"], gmax_d / gmax_nom,
                     unc["accuracy"], unc["macro_f1"], cal["accuracy"], cal["macro_f1"]])
        print(f"[K3a] {r['node']}  g_max/g_max_nom={gmax_d/gmax_nom:6.3f}  "
              f"uncal acc={unc['accuracy']:.4f} F1={unc['macro_f1']:.4f}  |  "
              f"cal acc={cal['accuracy']:.4f} F1={cal['macro_f1']:.4f}", flush=True)

    df = pd.DataFrame(rows, columns=["node", "gmax_ratio", "uncal_acc", "uncal_f1",
                                     "cal_acc", "cal_f1"])
    json.dump({"nominal": {k: rep_nom[k] for k in ("accuracy", "macro_f1", "kappa")},
               "rows": df.to_dict("records")}, open(D2D_JSON, "w"), indent=2)
    print(f"[K3a] uncalibrated acc median {np.median(df.uncal_acc):.4f}  "
          f"calibrated acc median {np.median(df.cal_acc):.4f}")
    plot_d2d(rep_nom, df, _load_gain())


def gain():
    """Middle condition: fix the readout GAIN per device, leave the ladder SHAPE nominal.

    Splits the uncalibrated failure into its two causes. A corner device's g_max is up to
    2x off nominal, so some of the collapse is a trivial gain error that any transimpedance
    trim removes. What is left after the gain is corrected is level MISPLACEMENT, which is
    the part RR-8 attributes to interface charge (FixedCharge +-10 % -> 1.31 decades,
    T_fe +-0.3 nm -> 0.07) and the part that actually needs write-verify.
    """
    ens = pd.read_csv(os.path.join(RAW, "variability_ensemble.csv"))
    cols = [f"G{i}_uA_um" for i in range(1, 16)]
    model, fp_state, ev = kc.setup()
    lv_nom, _, gmax_nom = measured_levels()
    rows = []
    for _, r in ens.iterrows():
        lv_d = _lv(r[cols].values)
        tgt, real = kc.paired_diff_sets(lv_nom, gmax_nom, lv_d, float(lv_d[-1]))
        kc.deploy(model, fp_state, tgt, real)
        g = ev()
        rows.append({"node": r["node"], "gain_acc": g["accuracy"], "gain_f1": g["macro_f1"]})
        print(f"[K3a-gain] {r['node']}  acc={g['accuracy']:.4f} F1={g['macro_f1']:.4f}",
              flush=True)
    json.dump(rows, open(GAIN_JSON, "w"), indent=2)
    d = json.load(open(D2D_JSON))
    plot_d2d(d["nominal"], pd.DataFrame(d["rows"]), rows)
    print(f"[K3a-gain] gain-only acc median "
          f"{np.median([r['gain_acc'] for r in rows]):.4f}")


def ladder():
    """Is a corner ladder a RIGID log-shift of the nominal one, or a different shape?

    This is what decides whether one scalar per device is enough. Reports, per corner, the
    mean log-offset from the nominal ladder and the residual scatter around that offset;
    then, after normalizing every device by its own g_max (i.e. after a gain trim), the
    per-level spread across the ensemble against the level spacing. No network evaluation.
    """
    ens = pd.read_csv(os.path.join(RAW, "variability_ensemble.csv"))
    nom = pd.read_csv(os.path.join(RAW, "ltp_potentiation.csv"))["Id_uA_per_um"].to_numpy()
    cols = [f"G{i}_uA_um" for i in range(1, 16)]
    L = np.log10(ens[cols].to_numpy(dtype=float))
    d = L - np.log10(nom)
    # Anchored residual: the deviation from nominal after both ladders are referred to
    # their own top level, which is exactly what a g_max gain trim leaves. The s.d. is
    # unchanged by the anchor (subtracting a per-device constant), so anchored_sd ==
    # residual_sd by construction; the anchor matters for the MAX, which is the worst
    # single-level error the `gain` condition actually presents to the network.
    a = d - d[:, [14]]
    per_dev = [[n, float(x.mean()), float(x.std(ddof=1)), float(x.max() - x.min()),
                float(y.std(ddof=1)), float(np.abs(y).max())]
               for n, x, y in zip(ens["node"], d, a)]
    fs.save_csv(os.path.join(kc.OUT, "K3a_ladder_shift.csv"),
                ["node", "mean_shift_decades", "residual_sd_decades", "residual_range_decades",
                 "anchored_sd_decades", "anchored_max_decades"], per_dev)

    Ln = L - L[:, [14]]                       # each device normalized by its own g_max
    mean = Ln.mean(0); half = (Ln.max(0) - Ln.min(0)) / 2
    sp = np.diff(mean)
    rows, ov = [], 0
    for i in range(15):
        s = float(sp[i - 1]) if i else float("nan")
        o = bool(i and half[i] + half[i - 1] > sp[i - 1])
        ov += o
        rows.append([i + 1, float(mean[i]), float(half[i]), s, o])
    fs.save_csv(os.path.join(kc.OUT, "K3a_overlap_after_gain_trim.csv"),
                ["level", "mean_log10_G_over_Gmax", "half_spread_decades",
                 "spacing_to_prev_decades", "overlaps_prev"], rows)
    sd = np.median([r[2] for r in per_dev])
    print(f"[K3a-ladder] median |mean shift| {np.median([abs(r[1]) for r in per_dev]):.3f} dec, "
          f"median residual sd {sd:.3f} dec")
    print(f"[K3a-ladder] after a per-device gain trim, {ov} of 14 adjacent pairs still "
          f"overlap across the ensemble (half-spread ~{np.median(half[:-1]):.2f} dec vs "
          f"spacing ~{np.median(sp):.2f} dec)")
    print("[K3a-ladder] wrote", kc.OUT)


def shape():
    """K3c: what a per-device gain trim leaves behind, and how much of it the network takes.

    x is the residual ladder-SHAPE error of each corner -- the scatter of its per-level
    log-offset from nominal, after the mean offset (which a gain trim removes) is taken
    out. y is the accuracy that corner delivers with a gain trim only, against the accuracy
    it delivers with full per-level write-verify. Requires `ladder`, `d2d` and `gain`.

    This is the panel that turns RR-8 into a placement spec. Ensemble level overlap does
    not predict accuracy -- 13 of 14 adjacent pairs still overlap after a gain trim, yet
    several of those corners sit at nominal. The per-device residual does predict it.
    """
    sh = pd.read_csv(os.path.join(kc.OUT, "K3a_ladder_shift.csv")).set_index("node")
    gr = pd.DataFrame(json.load(open(GAIN_JSON))).set_index("node")
    d = json.load(open(D2D_JSON))
    dr = pd.DataFrame(d["rows"]).set_index("node")
    j = sh.join(gr).join(dr)

    x = j.anchored_max_decades          # worst single-level misplacement left by the trim
    fig, ax = fs.new_ax(figsize=(8.6, 5.4))
    ax.axhline(d["nominal"]["accuracy"], ls="--", lw=2.0, color="#2e8b57")
    ax.text(x.max(), d["nominal"]["accuracy"] + 0.015, "nominal device",
            ha="right", fontweight="bold", fontsize=12, color="#2e8b57")
    ax.scatter(x, j.cal_acc, s=80, facecolor="#0b3d1e",
               edgecolor="black", lw=1.4, zorder=3, label="Full per-level write-verify")
    ax.scatter(x, j.gain_acc, s=80, marker="s", facecolor="#b8860b",
               edgecolor="black", lw=1.4, zorder=3, label="Gain trim only")
    ax.scatter(x, j.uncal_acc, s=70, marker="v", facecolor="#8b1a1a",
               edgecolor="black", lw=1.4, zorder=3, label="No calibration")
    ax.set_ylim(0, 1.0)
    ax.legend(prop={"weight": "bold", "size": 10}, loc="lower left")
    fs.bold_labels(ax, "Worst-level misplacement after gain trim (dec)",
                   "Test accuracy")
    fs.finish(fig, os.path.join(kc.OUT, "K3c_accuracy_vs_shape_error.png"))
    fs.save_csv(os.path.join(kc.OUT, "K3c_accuracy_vs_shape_error.csv"),
                ["node", "anchored_max_decades", "anchored_sd_decades", "mean_shift_decades",
                 "uncal_acc", "gain_acc", "cal_acc"],
                [[n, r.anchored_max_decades, r.anchored_sd_decades, r.mean_shift_decades,
                  r.uncal_acc, r.gain_acc, r.cal_acc] for n, r in j.iterrows()])
    for c in ("anchored_max_decades", "anchored_sd_decades", "mean_shift_decades"):
        print(f"[K3c] Spearman |{c}| vs gain-trim accuracy: "
              f"{j[c].abs().corr(j.gain_acc, method='spearman'):+.3f}")
    print(f"[K3c] gain trim median {j.gain_acc.median():.4f}, "
          f"write-verify median {j.cal_acc.median():.4f} "
          f"(spread {j.cal_acc.min():.3f}-{j.cal_acc.max():.3f}, independent of x)")
    print("[K3c] wrote", kc.OUT)


def _load_gain():
    return json.load(open(GAIN_JSON)) if os.path.exists(GAIN_JSON) else None


def plot_d2d(rep_nom, df, gain_rows=None):
    conds = [(df["uncal_acc"].values, "#8b1a1a", "Shared nominal grid\n(no calibration)"),
             (df["cal_acc"].values, "#0b3d1e", "Per-device write-verify\n(own ladder + gain)")]
    if gain_rows:
        conds.insert(1, (np.array([r["gain_acc"] for r in gain_rows]), "#b8860b",
                         "Gain trim only\n(nominal ladder shape)"))
    n = len(conds)
    fig, ax = fs.new_ax(figsize=(4.2 + 2.1 * n, 5.4))
    ax.axhline(rep_nom["accuracy"], ls="--", lw=2.0, color="#2e8b57")
    ax.text(0.45, rep_nom["accuracy"] + 0.015, "nominal device", ha="left",
            fontweight="bold", fontsize=12, color="#2e8b57")
    rng = np.random.default_rng(0)
    for i, (y, c, lab) in enumerate(conds, start=1):
        ax.scatter(i + rng.uniform(-0.13, 0.13, len(y)), y, s=70, facecolor=c,
                   edgecolor="black", lw=1.4, zorder=3)
        ax.boxplot([y], positions=[i], widths=0.5, showfliers=False,
                   medianprops=dict(color="black", lw=2.5),
                   boxprops=dict(lw=2.0), whiskerprops=dict(lw=2.0), capprops=dict(lw=2.0))
        ax.text(i, 0.945, lab, ha="center", va="top", fontweight="bold", fontsize=10)
    ax.set_xlim(0.4, n + 0.6); ax.set_ylim(0, 1.0)
    ax.set_xticks(range(1, n + 1))
    ax.set_xticklabels(["none", "gain", "full"][:n] if n == 3 else ["none", "full"])
    ax.minorticks_off()
    fs.bold_labels(ax, "Per-device calibration applied (20 RR-8 corner devices)",
                   "Test accuracy")
    fs.finish(fig, os.path.join(kc.OUT, "K3a_accuracy_vs_calibration.png"))
    out = df.copy()
    if gain_rows:
        out["gain_acc"] = [r["gain_acc"] for r in gain_rows]
        out["gain_f1"] = [r["gain_f1"] for r in gain_rows]
    fs.save_csv(os.path.join(kc.OUT, "K3a_accuracy_vs_calibration.csv"),
                list(out.columns), out.values.tolist())
    print("[K3a] wrote", kc.OUT)


# ------------------------------------------------------------------ K3b (c2c)
def c2c():
    p = os.path.join(RAW, "c2c_per_level.csv")
    if not os.path.exists(p):
        sys.exit(f"K3b needs {p}. Harvest node t17_c2c first:\n"
                 "    python harvest.py && python rranalyze.py rr8b")
    per = pd.read_csv(p)
    sigma_meas = float(np.median(per["sigma_log10"]))          # log10 units
    n_usable = int(per["separable_from_prev"].iloc[1:].sum()) + 1
    print(f"[K3b] measured c2c: median sigma = {sigma_meas:.4f} decades, "
          f"usable levels at 3-sigma = {n_usable}/{len(per)}", flush=True)

    model, fp_state, ev = kc.setup()
    lv_nom, _, gmax_nom = measured_levels()
    # branch-resolved: c2c is a property of each programmed conductance, so G+ and G- are
    # perturbed independently (see kfig_common.paired_branches).
    full = kc.paired_branches(lv_nom, gmax_nom)
    usable = kc.paired_branches(kc.subsample_measured(lv_nom, n_usable), gmax_nom)

    sig = sorted(set(C2C_SIGMAS + [round(sigma_meas, 4)]))
    rows = []
    for s in sig:
        s_ln = s * np.log(10.0)                                 # decades -> natural log
        for kind, (tgt, gp, gn) in (("15_level", full),
                                    (f"{n_usable}_level_usable", usable)):
            accs, f1s = [], []
            for seed in range(3):                               # 3 noise draws per point
                kc.deploy(model, fp_state, tgt, c2c=s_ln, seed=seed, branches=(gp, gn))
                r = ev()
                accs.append(r["accuracy"]); f1s.append(r["macro_f1"])
                if s == 0.0:
                    break                                       # deterministic
            rows.append([kind, s, float(np.mean(accs)), float(np.std(accs)),
                         float(np.mean(f1s)), float(np.std(f1s))])
            print(f"[K3b] {kind:20s} sigma={s:.4f} dec  acc={np.mean(accs):.4f}"
                  f"+-{np.std(accs):.4f}  F1={np.mean(f1s):.4f}", flush=True)

    fig, ax = fs.new_ax()
    for kind, c, m in ((f"{n_usable}_level_usable", "#0b3d1e", "o"),
                       ("15_level", "#8b1a1a", "s")):
        sub = [r for r in rows if r[0] == kind]
        x = [r[1] for r in sub]; y = [r[2] for r in sub]; e = [r[3] for r in sub]
        ax.errorbar(x, y, yerr=e, fmt=f"-{m}", ms=8, lw=2.6, capsize=5, color=c,
                    label=kind.replace("_", " "))
    ax.axvline(sigma_meas, ls="--", lw=2.2, color="#1f4e79")
    ax.text(sigma_meas, 0.06, f" measured c2c\n {sigma_meas:.3f} dec",
            fontweight="bold", fontsize=11, color="#1f4e79")
    ax.set_ylim(0, 1.0)
    ax.legend(prop={"weight": "bold", "size": 11}, loc="lower left")
    fs.bold_labels(ax, "Injected cycle-to-cycle sigma (decades of G)", "Test accuracy")
    fs.finish(fig, os.path.join(kc.OUT, "K3b_accuracy_vs_c2c.png"))
    fs.save_csv(os.path.join(kc.OUT, "K3b_accuracy_vs_c2c.csv"),
                ["grid", "sigma_log10", "accuracy_mean", "accuracy_std",
                 "macro_f1_mean", "macro_f1_std"], rows)
    json.dump({"sigma_measured_log10": sigma_meas, "n_usable_levels": n_usable,
               "rows": rows}, open(os.path.join(kc.RUNS, "k3b_c2c.json"), "w"), indent=2)
    print("[K3b] wrote", kc.OUT)


if __name__ == "__main__":
    {"d2d": d2d, "gain": gain, "c2c": c2c, "ladder": ladder, "shape": shape,
     "replot": lambda: plot_d2d(json.load(open(D2D_JSON))["nominal"],
                                pd.DataFrame(json.load(open(D2D_JSON))["rows"]),
                                _load_gain()),
     }[sys.argv[1] if len(sys.argv) > 1 else "d2d"]()
