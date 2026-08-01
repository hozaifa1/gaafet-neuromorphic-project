"""
Figure K2 — ECG accuracy vs number of FeFET conductance levels.
==============================================================
Post-training quantization of the locked paper150b checkpoint onto an n-level
differential FeFET grid. No retraining; only the deployment grid changes.

Two grid constructions, because they answer different questions and they do not agree:

  measured subset  n levels taken from the MEASURED LTP ladder (endpoints kept, evenly
                   spaced in pulse index). These are states the device demonstrably
                   reaches. This is the honest "how many levels do I need" curve.
  log-spaced       n levels geometrically spaced over the same measured span
                   (fefet_synapse.log_levels) -- an idealized designed grid, and the
                   construction the previously published 2-level ablation used.

They coincide at n = 2 and n = 15. The two constructions track each other closely
everywhere else too, which is the point of plotting both: the striking feature of this
sweep -- accuracy is NOT monotonic in n below 8 levels -- is not an artifact of how the
coarse grid was built.

The mechanism is the differential encoding on a 4.11-decade ladder. Because
|G_i - G_j| is dominated by max(i,j), the achievable weight set is approximately
{0, +-G_k/g_max}, i.e. geometrically spaced: dense near 0 and very sparse near +-1. Which
weights the coarse grid can and cannot represent therefore changes discontinuously with n,
and post-training quantization has no opportunity to compensate. `--spread` quantifies
that sensitivity by re-drawing the interior levels.

The claim the figure supports is a threshold, not a point-by-point ranking: below 8 levels
the classifier collapses and behaves erratically; from 8 levels up it recovers to within
the grid-choice spread of the measured 15-level device.

    python fig_k2_levels.py            # the sweep
    python fig_k2_levels.py --spread   # grid-choice spread at fixed n (adds the band)
    python fig_k2_levels.py --replot   # redraw from the saved JSON, no re-evaluation
"""
import kfig_common as kc          # first: sets sys.path and imports torch before pandas
import os, sys, json
import numpy as np
import torch

import figstyle as fs
from fefet_device import measured_levels
from fefet_synapse import log_levels

LEVELS = [2, 3, 4, 5, 6, 8, 10, 12, 15]


JSON = os.path.join(kc.RUNS, "k2_level_ablation.json")
SPREAD_JSON = os.path.join(kc.RUNS, "k2_grid_spread.json")
SPREAD_LEVELS = [4, 5, 6, 8, 10, 12]
SPREAD_DRAWS = 4


def spread():
    """Same n, different interior levels: how much of K2's jitter is grid choice?

    Endpoints are always kept -- g_min and g_max define the normalization -- so only the
    interior of the measured ladder is redrawn.
    """
    model, fp_state, ev = kc.setup()
    lv, _, g_max = measured_levels()
    rows = []
    for n in SPREAD_LEVELS:
        for d in range(SPREAD_DRAWS):
            rng = np.random.default_rng(d)
            interior = np.sort(rng.choice(np.arange(1, lv.numel() - 1), n - 2, replace=False))
            idx = np.concatenate([[0], interior, [lv.numel() - 1]])
            kc.deploy(model, fp_state, kc.diff_set(lv[torch.from_numpy(idx)], g_max))
            r = ev()
            rows.append([n, d, idx.tolist(), r["accuracy"], r["macro_f1"]])
            print(f"[K2-spread] n={n:2d} draw={d}  idx={idx.tolist()}  "
                  f"acc={r['accuracy']:.4f} F1={r['macro_f1']:.4f}", flush=True)
    json.dump(rows, open(SPREAD_JSON, "w"), indent=2)
    fs.save_csv(os.path.join(kc.OUT, "K2_grid_spread.csv"),
                ["n_levels", "draw", "level_indices", "accuracy", "macro_f1"],
                [[r[0], r[1], "|".join(map(str, r[2])), r[3], r[4]] for r in rows])
    d = json.load(open(JSON))
    plot(d["full_precision"], d["rows"], rows)
    print("[K2-spread] wrote", kc.OUT)


def main(replot: bool = False):
    if replot:                       # re-draw from the saved sweep, no re-evaluation
        d = json.load(open(JSON))
        sp = json.load(open(SPREAD_JSON)) if os.path.exists(SPREAD_JSON) else None
        return plot(d["full_precision"], d["rows"], sp)

    model, fp_state, ev = kc.setup()
    lv, g_min, g_max = measured_levels()

    rep_fp = ev()
    print(f"[K2] full precision: acc={rep_fp['accuracy']:.4f} F1={rep_fp['macro_f1']:.4f}",
          flush=True)

    rows = []
    for n in LEVELS:
        for kind in ("measured_subset", "log_spaced"):
            grid = (kc.subsample_measured(lv, n) if kind == "measured_subset"
                    else log_levels(g_min, g_max, n))
            ach = kc.diff_set(grid, g_max)
            kc.deploy(model, fp_state, ach)
            r = ev()
            rows.append([kind, n, int(ach.numel()), r["accuracy"], r["macro_f1"], r["kappa"]])
            print(f"[K2] {kind:15s} n={n:2d}  weights={ach.numel():4d}  "
                  f"acc={r['accuracy']:.4f} F1={r['macro_f1']:.4f} k={r['kappa']:.4f}",
                  flush=True)

    json.dump({"full_precision": {k: rep_fp[k] for k in ("accuracy", "macro_f1", "kappa")},
               "rows": rows}, open(JSON, "w"), indent=2)
    plot(rep_fp, rows)


def plot(rep_fp, rows, spread_rows=None):
    def series(kind, col):
        s = [r for r in rows if r[0] == kind]
        return [r[1] for r in s], [r[col] for r in s]

    fig, ax = fs.new_ax()
    if spread_rows:
        ns = sorted({r[0] for r in spread_rows})
        lo = [min(r[3] for r in spread_rows if r[0] == n) for n in ns]
        hi = [max(r[3] for r in spread_rows if r[0] == n) for n in ns]
        ax.fill_between(ns, lo, hi, color="#0b3d1e", alpha=0.16, lw=0, zorder=0,
                        label="Accuracy — grid-choice spread")
    ax.axhline(rep_fp["accuracy"], ls="--", lw=2.0, color="#2e8b57")
    ax.axhline(rep_fp["macro_f1"], ls=":", lw=2.0, color="#b8860b")
    x, y = series("measured_subset", 3); ax.plot(x, y, "-o", ms=8, lw=2.6, color="#0b3d1e",
                                                 label="Accuracy — measured subset")
    x, y = series("measured_subset", 4); ax.plot(x, y, "-s", ms=8, lw=2.6, color="#8b6508",
                                                 label="macro-F1 — measured subset")
    x, y = series("log_spaced", 3); ax.plot(x, y, "--o", ms=7, mfc="white", lw=2.2,
                                            color="#1f4e79", label="Accuracy — log-spaced grid")
    x, y = series("log_spaced", 4); ax.plot(x, y, "--s", ms=7, mfc="white", lw=2.2,
                                            color="#8b1a1a", label="macro-F1 — log-spaced grid")
    ax.text(15, rep_fp["accuracy"] + 0.015, "software (FP)", ha="right",
            fontweight="bold", fontsize=12, color="#2e8b57")
    ax.set_xscale("log", base=2)
    ax.set_xticks(LEVELS); ax.set_xticklabels([str(v) for v in LEVELS])
    ax.minorticks_off()
    ax.set_ylim(0, 1.0)
    ax.legend(prop={"weight": "bold", "size": 10}, loc="center left",
              bbox_to_anchor=(0.02, 0.72), ncol=1)
    fs.bold_labels(ax, "FeFET conductance levels per synapse", "Test score")
    fs.finish(fig, os.path.join(kc.OUT, "K2_accuracy_vs_levels.png"))
    fs.save_csv(os.path.join(kc.OUT, "K2_accuracy_vs_levels.csv"),
                ["grid", "n_levels", "n_achievable_diff_weights", "accuracy", "macro_f1", "kappa"],
                rows)
    print("[K2] wrote", kc.OUT)


if __name__ == "__main__":
    if "--spread" in sys.argv:
        spread()
    else:
        main(replot="--replot" in sys.argv)
