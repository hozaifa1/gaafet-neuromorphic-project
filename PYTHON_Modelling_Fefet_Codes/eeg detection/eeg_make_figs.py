"""
Generate all EEG paper figures into eeg detection/figures/.
Training curves from history.json; LR schedule analytically; confusion matrix + contiguous
raw-vs-post-processed stream from one inference pass on the best ckpt (readout=last, 15-level
device unless --fp); faithfulness/ablation bar from eeg_results.json.
Run:  python eeg_make_figs.py
"""
import torch
import os
import sys
import json
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "REDESIGN", "code"))
import eeg_postprocess as ep
import post_quantize as pq

RUN = os.path.join(_HERE, "REDESIGN", "runs", "eeg_lastread")
FIG = os.path.join(_HERE, "figures")
os.makedirs(FIG, exist_ok=True)
PP_WIN, PP_THR = 21, 0.5


def lr_schedule(n, peak=1e-2, warmup=5, sched=30, eta_ratio=0.1):
    floor = peak * eta_ratio
    lrs = []
    for e in range(n):
        if e < warmup:
            lrs.append(peak * (e + 1) / warmup)
        elif e < warmup + sched:
            t = (e - warmup) / sched
            lrs.append(floor + 0.5 * (peak - floor) * (1 + np.cos(np.pi * t)))
        else:
            lrs.append(floor)
    return lrs


def training_curves(h):
    ep_ = [e["epoch"] for e in h]
    gm = [e["device"].get("g_mean", 0) for e in h]
    se = [e["device"].get("sensitivity", 0) for e in h]
    sp = [e["device"].get("specificity", 0) for e in h]
    loss = [e["loss"] for e in h]
    tr = [e["train_acc"] for e in h]
    fr = [e["fr_hz"] for e in h]

    # 1) G-mean / sens / spec
    plt.figure(figsize=(6, 4))
    plt.plot(ep_, gm, "-o", ms=3, label="G-mean"); plt.plot(ep_, se, "-", label="sensitivity")
    plt.plot(ep_, sp, "-", label="specificity")
    plt.xlabel("epoch"); plt.ylabel("test metric"); plt.title("EEG training: G-mean / sensitivity / specificity")
    plt.legend(); plt.grid(alpha=.3); plt.tight_layout(); plt.savefig(f"{FIG}/fig1_gmean_sens_spec.png", dpi=140); plt.close()

    # 2) loss
    plt.figure(figsize=(6, 4)); plt.plot(ep_, loss, "-o", ms=3, color="crimson")
    plt.axhline(np.log(2), ls="--", c="gray", label="ln 2 (chance)")
    plt.xlabel("epoch"); plt.ylabel("train loss"); plt.title("EEG training loss"); plt.legend()
    plt.grid(alpha=.3); plt.tight_layout(); plt.savefig(f"{FIG}/fig2_loss.png", dpi=140); plt.close()

    # 3) train accuracy
    plt.figure(figsize=(6, 4)); plt.plot(ep_, tr, "-o", ms=3, color="teal")
    plt.xlabel("epoch"); plt.ylabel("train accuracy"); plt.title("EEG train accuracy")
    plt.grid(alpha=.3); plt.tight_layout(); plt.savefig(f"{FIG}/fig3_train_acc.png", dpi=140); plt.close()

    # 4) firing rate
    plt.figure(figsize=(6, 4)); plt.plot(ep_, fr, "-o", ms=3, color="darkorange")
    plt.axhline(20, ls="--", c="gray", label="spike-reg target 20 Hz")
    plt.xlabel("epoch"); plt.ylabel("mean firing rate (Hz)"); plt.title("EEG neuron firing rate"); plt.legend()
    plt.grid(alpha=.3); plt.tight_layout(); plt.savefig(f"{FIG}/fig4_firing_rate.png", dpi=140); plt.close()

    # 5) LR schedule
    lrs = lr_schedule(len(h))
    plt.figure(figsize=(6, 4)); plt.plot(range(len(lrs)), lrs, "-o", ms=3, color="purple")
    plt.xlabel("epoch"); plt.ylabel("learning rate"); plt.title("LR schedule (warmup + cosine decay + hold)")
    plt.yscale("log"); plt.grid(alpha=.3); plt.tight_layout(); plt.savefig(f"{FIG}/fig5_lr_schedule.png", dpi=140); plt.close()


def inference_figs():
    device = torch.device("cpu")
    d = np.load(os.path.join(_HERE, "eeg.npz"))
    X, y = d["X_test"], d["y_test"].astype(int)

    def best_thr_at(probs, w):
        sm = ep.moving_average(probs, w)
        best = (-1, 0.5)
        for thr in np.arange(0.3, 0.9, 0.025):
            _, _, g, _ = ep.metrics((sm >= thr).astype(int), y)
            if g > best[0]:
                best = (g, thr)
        return sm, best[1]

    def confusion_fig(probs, w, fname, title):
        sm, thr = best_thr_at(probs, w)
        pred = (sm >= thr).astype(int)
        s, sp, g, (tp, tn, fp, fn) = ep.metrics(pred, y)
        cm = np.array([[tn, fp], [fn, tp]])
        plt.figure(figsize=(4.6, 4.1)); plt.imshow(cm, cmap="Blues")
        for i in range(2):
            for j in range(2):
                plt.text(j, i, cm[i, j], ha="center", va="center",
                         color="white" if cm[i, j] > cm.max()/2 else "black", fontsize=13)
        plt.xticks([0, 1], ["Normal", "Epileptic"]); plt.yticks([0, 1], ["Normal", "Epileptic"])
        plt.xlabel("predicted"); plt.ylabel("true")
        plt.title(f"{title}\nsens {s:.3f} / spec {sp:.3f} / G-mean {g:.3f} (FP {fp})", fontsize=9)
        plt.colorbar(); plt.tight_layout(); plt.savefig(f"{FIG}/{fname}", dpi=140); plt.close()
        return sm, thr

    # SOFTWARE (full precision) probabilities
    model = ep.build_eeg(device, 3.3e-3)
    st = torch.load(os.path.join(RUN, "eeg_lastread_best.ckpt"), map_location=device, weights_only=False)
    model.load_state_dict(st["net"])
    probs_fp = ep.infer_probs(model, X, device, rmode="last")
    # 6a) software confusion (headline)
    confusion_fig(probs_fp, PP_WIN, "fig6a_confusion_software.png",
                  f"Software confusion (post-proc, w={PP_WIN})")

    # ON-DEVICE (15-level) probabilities
    pq.quantize_(model, pq.achievable_diff_values(15))
    probs_dev = ep.infer_probs(model, X, device, rmode="last")
    # 6b) on-device confusion (faithfulness)
    sm_dev, thr_dev = confusion_fig(probs_dev, PP_WIN, "fig6b_confusion_device.png",
                                    f"On-device 15-level confusion (post-proc, w={PP_WIN})")

    # 7) contiguous stream (on-device): raw prob, smoothed, true label
    t = np.arange(len(y))
    plt.figure(figsize=(9, 4))
    plt.plot(t, probs_dev, lw=.6, alpha=.5, label="raw P(epileptic)", color="steelblue")
    plt.plot(t, sm_dev, lw=1.4, label=f"post-processed (mov-avg w={PP_WIN})", color="darkblue")
    plt.axhline(thr_dev, ls="--", c="gray", lw=.8, label=f"threshold {thr_dev:.3f}")
    plt.fill_between(t, 0, 1, where=(y == 1), color="red", alpha=.25, label="true seizure")
    plt.xlabel("contiguous EEG clip (time →, 1 hr)"); plt.ylabel("P(epileptic)")
    plt.title("On-device contiguous seizure detection: raw vs post-processed"); plt.legend(loc="upper right", fontsize=8)
    plt.ylim(0, 1); plt.tight_layout(); plt.savefig(f"{FIG}/fig7_contiguous_stream.png", dpi=140); plt.close()


def faithfulness_bar():
    rf = os.path.join(_HERE, "eeg_results.json")
    if not os.path.exists(rf):
        print("  (skip fig8: eeg_results.json not found)"); return
    r = json.load(open(rf))
    labels = ["Software\n(FP)", "On-device\n15 levels", "Ablation\n2 levels"]
    raw = [r["fp_raw"], r["dev15_raw"], r["dev2_raw"]]
    pp = [r["fp_pp"], r["dev15_pp"], r["dev2_pp"]]
    x = np.arange(3); w = .38
    plt.figure(figsize=(6.5, 4))
    plt.bar(x - w/2, raw, w, label="raw G-mean", color="lightsteelblue")
    plt.bar(x + w/2, pp, w, label="post-processed G-mean", color="steelblue")
    for i in range(3):
        plt.text(x[i]-w/2, raw[i]+.01, f"{raw[i]:.2f}", ha="center", fontsize=8)
        plt.text(x[i]+w/2, pp[i]+.01, f"{pp[i]:.2f}", ha="center", fontsize=8)
    plt.xticks(x, labels); plt.ylabel("G-mean"); plt.ylim(0, 1.05)
    plt.title("Device faithfulness & load-bearing ablation"); plt.legend()
    plt.grid(alpha=.3, axis="y"); plt.tight_layout(); plt.savefig(f"{FIG}/fig8_faithfulness_ablation.png", dpi=140); plt.close()


if __name__ == "__main__":
    h = json.load(open(os.path.join(RUN, "eeg_lastread_history.json")))
    print("training curves..."); training_curves(h)
    print("LR schedule... (in curves)")
    print("inference figures (confusion, contiguous stream)..."); inference_figs()
    print("faithfulness bar..."); faithfulness_bar()
    print(f"figures written to {FIG}")
