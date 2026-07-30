"""
Head-to-head EEG deployment: the SAME locked eeg_lastread checkpoint quantized onto the
GAA-15 vs the planar-10 measured conductance ladders. Device is the ONLY variable.
=====================================================================================
Rigorous equal comparison (device isolated): identical software network (eeg_lastread,
epoch 14, last-timestep readout), identical CMOS neuron, 37->[24 LIF+16 ALIF]->2 arch,
delta encoder, contiguous 2878-clip test stream. Only the deployment conductance level-set
differs. Both raw (thr 0.5) and the paper's fixed post-processing (moving average w=21,
threshold theta=0.5) are reported. Reuses the locked eeg detection/ modules read-only.
"""
import os, sys, json
import numpy as np
import torch

HERE = os.path.dirname(os.path.abspath(__file__))
EEG = os.path.join(HERE, "..", "eeg detection")
sys.path.insert(0, os.path.join(EEG, "REDESIGN", "code"))
sys.path.insert(0, EEG)
sys.path.insert(0, HERE)

import eeg_postprocess as ep          # build_eeg, infer_probs, moving_average, metrics
import post_quantize as pq
import planar_device

CKPT = os.path.join(EEG, "REDESIGN", "runs", "eeg_lastread", "eeg_lastread_best.ckpt")
INPUT_SCALING = 3.3e-3
W, THR = 21, 0.5                       # the paper's fixed post-processing operating point


def load_model(dev):
    m = ep.build_eeg(dev, INPUT_SCALING)
    st = torch.load(CKPT, map_location=dev, weights_only=False)
    m.load_state_dict(st["net"])
    return m


def diff_set_from_levels(lv, gmax):
    ln = (lv / gmax).numpy()
    vals = sorted({round(float(a - b), 12) for a in ln for b in ln})
    return torch.tensor(vals, dtype=torch.float32)


def planar_achievable(distinguishable=True):
    lv, gmin, gmax = planar_device.measured_levels(distinguishable=distinguishable)
    return diff_set_from_levels(lv, gmax)


def eval_probs(dev, X, achievable):
    m = load_model(dev)
    n_w = None
    if achievable is not None:
        pq.quantize_(m, achievable)
        n_w = int(achievable.numel())
    return ep.infer_probs(m, X, dev, rmode="last"), n_w


def report(probs, y, w=W, thr=THR):
    s0, sp0, g0, cm0 = ep.metrics((probs >= 0.5).astype(int), y)          # raw, thr 0.5, no smoothing
    sm = ep.moving_average(probs, w)
    s, sp, g, cm = ep.metrics((sm >= thr).astype(int), y)                 # post-processed
    return dict(raw=dict(sens=s0, spec=sp0, gmean=g0, FP=cm0[2]),
                pp=dict(sens=s, spec=sp, gmean=g, FP=cm[2]))


def main():
    dev = torch.device("cpu")
    torch.manual_seed(100)
    d = np.load(os.path.join(EEG, "eeg.npz"))
    X, y = d["X_test"], d["y_test"].astype(int)
    print(f"test: {len(y)} contiguous clips, {int((y == 1).sum())} epileptic, {int((y == 0).sum())} normal")

    cfgs = [
        ("software_FP",   None,                            "Software (full precision)"),
        ("GAA_15",        pq.achievable_diff_values(15),   "GAA on-device (15 levels)"),
        ("planar_10",     planar_achievable(True),         "Planar on-device (10 levels)"),
        ("planar_15raw",  planar_achievable(False),        "Planar on-device (15 raw, optimistic)"),
    ]

    results = {}
    hdr = f"{'config':<40}{'nw':>6}{'raw G':>8}{'pp G':>8}{'pp sens':>9}{'pp spec':>9}{'pp FP':>7}"
    print("\n" + hdr)
    for key, ach, label in cfgs:
        probs, n_w = eval_probs(dev, X, ach)
        r = report(probs, y)
        results[key] = dict(label=label, n_weights=n_w, **r)
        print(f"{label:<40}{(n_w if n_w else '-'):>6}{r['raw']['gmean']:>8.4f}"
              f"{r['pp']['gmean']:>8.4f}{r['pp']['sens']:>9.4f}{r['pp']['spec']:>9.4f}{r['pp']['FP']:>7d}")

    json.dump(results, open(os.path.join(HERE, "results_planar_vs_gaa_eeg.json"), "w"), indent=2, default=float)
    print("\nwrote results_planar_vs_gaa_eeg.json")


if __name__ == "__main__":
    main()
