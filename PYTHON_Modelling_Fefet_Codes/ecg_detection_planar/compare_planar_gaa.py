"""
Head-to-head ECG deployment: the SAME locked software checkpoint quantized onto the
GAA-15 vs the planar-10 measured conductance ladders. The device is the ONLY variable.
========================================================================================
Rigorous equal comparison (device isolated): identical software network (paper150b),
identical CMOS neuron, architecture, delta encoder, test set and readout; only the
deployment conductance level-set differs. Reuses the locked ecg detection/ modules
read-only; writes results to results_planar_vs_gaa.json.
"""
import os, sys, json
import numpy as np
import torch
import torch.utils.data as data

HERE = os.path.dirname(os.path.abspath(__file__))
ECG = os.path.join(HERE, "..", "ecg detection")
sys.path.insert(0, os.path.join(ECG, "REDESIGN", "code"))
sys.path.insert(0, ECG)
sys.path.insert(0, HERE)

import redesign_stage1 as rs
import post_quantize as pq
from dataset import DeltaTransformedECG
import planar_device

CKPT = os.path.join(ECG, "REDESIGN", "runs", "paper150b", "paper150b_best.ckpt")
CLASSES = ["N", "F", "SVEB", "VEB"]
K = 116


def load_model(dev):
    pq.ARCH["num_in"] = 3
    m = pq.build_orig(dev)
    st = torch.load(CKPT, map_location=dev, weights_only=False)
    m.load_state_dict(st["net"])
    return m


def get_test_loader(dev):
    ds = DeltaTransformedECG(path=os.path.join(ECG, "data_ecg"), output_cue_length=K, n_class=4)
    _, test = data.random_split(ds, [1664, 336], generator=torch.Generator().manual_seed(100))
    return data.DataLoader(data.Subset(ds, test.indices), batch_size=128, shuffle=False)


def diff_set_from_levels(lv, gmax):
    """Achievable differential weights (G_i - G_j)/g_max from an explicit conductance ladder."""
    ln = (lv / gmax).numpy()
    vals = sorted({round(float(a - b), 12) for a in ln for b in ln})
    return torch.tensor(vals, dtype=torch.float32)


def planar_achievable(distinguishable=True):
    lv, gmin, gmax = planar_device.measured_levels(distinguishable=distinguishable)
    return diff_set_from_levels(lv, gmax)


def eval_cfg(dev, loader, achievable):
    m = load_model(dev)
    n_w = None
    if achievable is not None:
        pq.quantize_(m, achievable)
        n_w = int(achievable.numel())
    rep = rs.evaluate(m, loader, dev, quant=False, rmode="meancue", k=K)
    return rep, n_w


def main():
    dev = torch.device("cpu")
    torch.manual_seed(100)
    loader = get_test_loader(dev)

    cfgs = [
        ("software_FP",   None,                              "Software (full precision)"),
        ("GAA_15",        pq.achievable_diff_values(15),     "GAA on-device (15 measured levels)"),
        ("planar_10",     planar_achievable(True),           "Planar on-device (10 distinguishable)"),
        ("planar_15raw",  planar_achievable(False),          "Planar on-device (15 raw pulses, optimistic)"),
        ("GAA_2_abl",     pq.achievable_diff_values(2),      "GAA 2-level ablation (reference)"),
    ]

    results = {}
    print(f"{'config':<40}{'n_weights':>10}{'acc':>9}{'macroF1':>10}{'kappa':>9}")
    for key, ach, label in cfgs:
        rep, n_w = eval_cfg(dev, loader, ach)
        results[key] = dict(label=label, n_weights=n_w,
                            accuracy=rep["accuracy"], macro_f1=rep["macro_f1"], kappa=rep["kappa"],
                            per_class={c: {k: rep["per_class"][c][k] for k in ("Se", "+P", "F1")} for c in CLASSES},
                            confusion=[[int(x) for x in row] for row in rep["confusion"]])
        print(f"{label:<40}{(n_w if n_w else '-'):>10}{rep['accuracy']:>9.4f}{rep['macro_f1']:>10.4f}{rep['kappa']:>9.4f}")

    # faithfulness gaps vs software
    fp = results["software_FP"]
    print("\n=== faithfulness (drop from software) ===")
    for key in ("GAA_15", "planar_10", "planar_15raw"):
        r = results[key]
        r["acc_drop"] = fp["accuracy"] - r["accuracy"]
        r["f1_drop"] = fp["macro_f1"] - r["macro_f1"]
        print(f"  {r['label']:<40} acc {r['acc_drop']:+.4f}   macro-F1 {r['f1_drop']:+.4f}")

    out = os.path.join(HERE, "results_planar_vs_gaa.json")
    json.dump(results, open(out, "w"), indent=2)
    print(f"\nwrote {out}")


if __name__ == "__main__":
    main()
