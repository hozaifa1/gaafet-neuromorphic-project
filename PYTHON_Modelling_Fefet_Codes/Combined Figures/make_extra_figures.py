"""
Extra figures: robustness bar (per task) + weight distribution before/after 15-level
quantization (per task). Run: python make_extra_figures.py {ecg|eeg}
"""
import os, sys, json
import numpy as np
import torch
_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _HERE)
import figstyle as fs
import matplotlib.pyplot as plt

TASK = sys.argv[1] if len(sys.argv) > 1 else "ecg"
ROOT = os.path.join(_HERE, "..")


def P(name):
    return os.path.join(_HERE, f"{TASK} figures", name)


def load_model_and_weights():
    if TASK == "ecg":
        d = os.path.join(ROOT, "ecg detection"); sys.path.insert(0, d); sys.path.insert(0, os.path.join(d, "REDESIGN", "code"))
        import post_quantize as pq
        pq.ARCH["num_in"] = 3
        m = pq.build_orig(torch.device("cpu"))
        st = torch.load(os.path.join(d, "REDESIGN/runs/paper150b/paper150b_best.ckpt"), map_location="cpu", weights_only=False)
        m.load_state_dict(st["net"])
        return m, pq
    else:
        d = os.path.join(ROOT, "eeg detection"); sys.path.insert(0, d); sys.path.insert(0, os.path.join(d, "REDESIGN", "code"))
        import eeg_postprocess as ep, post_quantize as pq
        m = ep.build_eeg(torch.device("cpu"), 3.3e-3)
        st = torch.load(os.path.join(d, "REDESIGN/runs/eeg_lastread/eeg_lastread_best.ckpt"), map_location="cpu", weights_only=False)
        m.load_state_dict(st["net"])
        return m, pq


def weight_distribution():
    m, pq = load_model_and_weights()
    w_fp = np.concatenate([p.detach().flatten().numpy() for n, p in m.named_parameters() if n.endswith("weight")])
    # per-layer normalized (as deployed) then quantized
    pq.quantize_(m, pq.achievable_diff_values(15))
    w_q = np.concatenate([p.detach().flatten().numpy() for n, p in m.named_parameters() if n.endswith("weight")])
    # normalize both by max|w_fp| for a comparable [-1,1] view
    s = np.abs(w_fp).max()
    fig, ax = fs.new_ax()
    ax.hist(w_fp / s, bins=60, color="#a8d5b5", edgecolor="black", lw=1.2, alpha=0.85, label="Full precision")
    ax.hist(w_q / s, bins=60, color="#0b3d1e", edgecolor="black", lw=1.0, histtype="step", label="15-level FeFET")
    ax.legend(prop={"weight": "bold", "size": 11})
    fs.bold_labels(ax, "Normalized weight", "Count")
    fs.finish(fig, P(f"{TASK}X_weight_distribution.png"))
    # CSV: histogram bin centers + counts for both
    hf, e = np.histogram(w_fp / s, bins=60); hq, _ = np.histogram(w_q / s, bins=60)
    ctr = 0.5 * (e[:-1] + e[1:])
    fs.save_csv(P(f"{TASK}X_weight_distribution.csv"), ["bin_center", "count_FP", "count_15level"],
                list(zip(ctr, hf, hq)))
    print("weight distribution ok")


def robustness_bar():
    if TASK == "ecg":
        # robust_final.json = the 2026-08-01 re-run against the corrected device export,
        # with the MEASURED RR-4 retention plateau (-0.96 %) replacing the old -2.9 %,
        # which had been read from inside the post-write settling transient.
        j = json.load(open(os.path.join(ROOT, "ecg detection", "REDESIGN/runs/robust_final.json")))
        order = ["nominal_300K", "T=250K", "T=350K", "D2D_s0.1", "C2C_s0.1", "D2D+C2C",
                 "retention_MEASURED_-0.96pct", "retention_stress_-10pct"]
        labels = ["Nominal", "250 K", "350 K", "D2D", "C2C", "D2D+C2C", "Ret −0.96%", "Ret −10%"]
        vals = [j[k]["macro_f1"] for k in order]; ylab = "macro-F1"
    else:
        j = json.load(open(os.path.join(ROOT, "eeg detection", "REDESIGN/runs/eeg_lastread/eeg_robust.json")))
        order = ["nominal_300K", "T=250K", "T=350K", "D2D_s0.1", "C2C_s0.1", "D2D+C2C",
                 "retention_MEASURED_-2.9pct", "retention_stress_-10pct"]
        labels = ["Nominal", "250 K", "350 K", "D2D", "C2C", "D2D+C2C", "Ret −2.9%", "Ret −10%"]
        vals = [j[k][1][0] for k in order]; ylab = "post-proc G-mean"   # [1]=post-proc tuple, [0]=g-mean
    x = np.arange(len(vals))
    fig, ax = fs.new_ax(figsize=(9.5, 5.2))
    cols = ["#0b3d1e"] + ["#2e8b57"] * 5 + ["#b8860b", "#8b1a1a"]
    ax.bar(x, vals, color=cols, edgecolor="black", lw=2)
    ax.set_xticks(x); ax.set_xticklabels(labels, fontweight="bold", rotation=30, ha="right")
    fs.bold_labels(ax, None, ylab); ax.set_ylim(0, 1.0)
    fs.finish(fig, P(f"{TASK}Y_robustness_bar.png"))
    fs.save_csv(P(f"{TASK}Y_robustness_bar.csv"), ["condition", ylab.replace(" ", "_")], list(zip(labels, vals)))
    print("robustness bar ok")


if __name__ == "__main__":
    print("extras for", TASK)
    weight_distribution()
    robustness_bar()
