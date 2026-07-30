"""
EEG task figures (VO2-paper Fig-6 analogs + extras) into Combined Figures/eeg figures/.
Each figure: PNG (Origin style) + reproducing CSV. Uses the eeg_lastread ep14 checkpoint.
"""
import torch, os, sys, json
import numpy as np
_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "REDESIGN", "code"))
CF = os.path.join(_HERE, "..", "Combined Figures"); sys.path.insert(0, CF)
import figstyle as fs
import matplotlib.pyplot as plt
import eeg_postprocess as ep
import post_quantize as pq
from spikingjelly.clock_driven import functional

OUT = os.path.join(CF, "eeg figures"); os.makedirs(OUT, exist_ok=True)
def P(n): return os.path.join(OUT, n)
RUN = os.path.join(_HERE, "REDESIGN", "runs", "eeg_lastread")
CKPT = os.path.join(RUN, "eeg_lastread_best.ckpt")
CLS = ["Normal", "Epileptic"]; NLIF, NALIF = 24, 16; PP_WIN = 21


def raster(spk, fname, ylabel, csvname, color="#0b3d1e", figsize=(9.5, 5.0)):
    T, N = spk.shape
    fig, ax = fs.new_ax(figsize=figsize)
    ii, tt = np.where(spk.T > 0.5)
    ax.scatter(tt, ii, s=4, c=color, marker="|", linewidths=1.1)
    fs.bold_labels(ax, "Timestep", ylabel); ax.set_xlim(0, T); ax.set_ylim(-0.5, N - 0.5)
    fs.finish(fig, P(fname)); fs.save_csv(P(csvname), ["timestep", "index"], [[int(t), int(n)] for t, n in zip(tt, ii)])


def best_thr(probs, y, w):
    sm = ep.moving_average(probs, w); best = (-1, 0.5)
    for thr in np.arange(0.3, 0.9, 0.025):
        _, _, g, _ = ep.metrics((sm >= thr).astype(int), y)
        if g > best[0]: best = (g, thr)
    return sm, best[1]


def main():
    dev = torch.device("cpu")
    d = np.load(os.path.join(_HERE, "eeg.npz")); X, y = d["X_test"], d["y_test"].astype(int)

    # ---- single epileptic clip, recorded states ----
    m = ep.build_eeg(dev, 3.3e-3)
    st = torch.load(CKPT, map_location=dev, weights_only=False); m.load_state_dict(st["net"]); m.eval()
    epi = int(np.where(y == 1)[0][len(np.where(y==1)[0])//2])  # a mid epileptic clip
    clip = torch.from_numpy(X[epi:epi+1]).float()
    with torch.no_grad(): out = m(clip)
    spk = m.spike.cpu().numpy(); vth = m.v_threshold.cpu().numpy()
    prob = torch.softmax(out.squeeze(1), -1).cpu().numpy(); inp = X[epi]
    functional.reset_net(m)

    raster((inp > 0.5).astype(int), "eegA_input_raster.png", "Input channel (0-35 UP/DOWN, 36 CUE)",
           "eegA_input_raster.csv", color="#1f4e79", figsize=(10, 5.0))
    raster(spk[:, :NLIF], "eegB_LIF_raster.png", "LIF neuron index", "eegB_LIF_raster.csv")
    raster(spk[:, NLIF:], "eegC_ALIF_raster.png", "ALIF neuron index", "eegC_ALIF_raster.csv", color="#b8860b")

    fig, ax = fs.new_ax(figsize=(9.5, 5.0)); T = vth.shape[0]
    cols = ["#0b3d1e", "#2e8b57", "#1f4e79", "#b8860b", "#8b1a1a"]
    for k in range(min(5, vth.shape[1])): ax.plot(range(T), vth[:, k], lw=2.0, color=cols[k], label=f"ALIF {k}")
    ax.legend(prop={"weight": "bold", "size": 9}, ncol=2); fs.bold_labels(ax, "Timestep", "Adaptation Vg (V)")
    fs.finish(fig, P("eegD_Vg_evolution.png"))
    fs.save_csv(P("eegD_Vg_evolution.csv"), ["timestep"] + [f"ALIF{k}" for k in range(5)],
                [[t] + [vth[t, k] for k in range(min(5, vth.shape[1]))] for t in range(T)])

    fig, ax = fs.new_ax(figsize=(9.5, 5.0))
    for c in range(2): ax.plot(range(prob.shape[0]), prob[:, c], lw=2.2, color=cols[c], label=CLS[c])
    ax.legend(prop={"weight": "bold", "size": 10}); fs.bold_labels(ax, "Timestep", "Output probability"); ax.set_ylim(0, 1)
    fs.finish(fig, P("eegE_output_prob.png"))
    fs.save_csv(P("eegE_output_prob.csv"), ["timestep"] + CLS, [[t] + list(prob[t]) for t in range(prob.shape[0])])

    # ---- probabilities over the contiguous test stream (software + device) ----
    probs_fp = ep.infer_probs(m, X, dev, rmode="last")
    pq.quantize_(m, pq.achievable_diff_values(15))
    probs_dev = ep.infer_probs(m, X, dev, rmode="last")
    t = np.arange(len(y))

    # target labels
    fig, ax = fs.new_ax(figsize=(12, 3.6)); ax.fill_between(t, 0, y, color="#8b1a1a", step="mid")
    fs.bold_labels(ax, "Contiguous clip (time →)", "True label"); ax.set_ylim(-0.05, 1.1); ax.set_yticks([0, 1])
    fs.finish(fig, P("eegF_target_labels.png")); fs.save_csv(P("eegF_target_labels.csv"), ["clip", "label"], list(zip(t, y)))

    sm_dev, thr = best_thr(probs_dev, y, PP_WIN)
    # raw device stream
    fig, ax = fs.new_ax(figsize=(12, 4.6))
    ax.plot(t, probs_dev, lw=0.7, color="#2e8b57"); ax.fill_between(t, 0, 1, where=(y == 1), color="#8b1a1a", alpha=.2)
    fs.bold_labels(ax, "Contiguous clip (time →)", "P(epileptic) raw"); ax.set_ylim(0, 1)
    fs.finish(fig, P("eegG_contiguous_raw.png")); fs.save_csv(P("eegG_contiguous_raw.csv"), ["clip", "p_raw", "label"], list(zip(t, probs_dev, y)))
    # after moving average
    fig, ax = fs.new_ax(figsize=(12, 4.6))
    ax.plot(t, sm_dev, lw=1.6, color="#0b3d1e"); ax.axhline(thr, ls="--", color="gray", lw=1.6)
    ax.fill_between(t, 0, 1, where=(y == 1), color="#8b1a1a", alpha=.2)
    fs.bold_labels(ax, "Contiguous clip (time →)", f"P moving-avg (w={PP_WIN})"); ax.set_ylim(0, 1)
    fs.finish(fig, P("eegH_contiguous_movavg.png")); fs.save_csv(P("eegH_contiguous_movavg.csv"), ["clip", "p_smoothed", "label"], list(zip(t, sm_dev, y)))
    # after threshold (final binary)
    finalpred = (sm_dev >= thr).astype(int)
    fig, ax = fs.new_ax(figsize=(12, 3.6))
    ax.fill_between(t, 0, finalpred, color="#2e8b57", step="mid", label="predicted")
    ax.plot(t, y * 1.05, color="#8b1a1a", lw=1.4, label="true")
    ax.legend(prop={"weight": "bold", "size": 9}); fs.bold_labels(ax, "Contiguous clip (time →)", "Final decision")
    ax.set_ylim(-0.05, 1.15); ax.set_yticks([0, 1])
    fs.finish(fig, P("eegI_contiguous_final.png")); fs.save_csv(P("eegI_contiguous_final.csv"), ["clip", "predicted", "true"], list(zip(t, finalpred, y)))
    # zoom on the true-positive episode
    z0, z1 = max(0, int(np.where(y == 1)[0][0]) - 60), int(np.where(y == 1)[0][-1]) + 60
    fig, ax = fs.new_ax(figsize=(8, 4.6))
    ax.plot(t[z0:z1], probs_dev[z0:z1], lw=0.8, color="#2e8b57", label="raw")
    ax.plot(t[z0:z1], sm_dev[z0:z1], lw=2.0, color="#0b3d1e", label="smoothed")
    ax.axhline(thr, ls="--", color="gray", lw=1.6); ax.fill_between(t[z0:z1], 0, 1, where=(y[z0:z1] == 1), color="#8b1a1a", alpha=.2)
    ax.legend(prop={"weight": "bold", "size": 9}); fs.bold_labels(ax, "Clip (zoom on seizure)", "P(epileptic)"); ax.set_ylim(0, 1)
    fs.finish(fig, P("eegJ_zoom_true_positive.png")); fs.save_csv(P("eegJ_zoom_true_positive.csv"), ["clip", "p_raw", "p_smoothed", "label"], list(zip(t[z0:z1], probs_dev[z0:z1], sm_dev[z0:z1], y[z0:z1])))

    # ---- confusion matrices: software, device raw, device post-proc ----
    def conf(probs, w, name, sub_pp=True, fixed_thr=None):
        if sub_pp:
            sm = ep.moving_average(probs, w)
            th = fixed_thr if fixed_thr is not None else best_thr(probs, y, w)[1]
            pred = (sm >= th).astype(int)
        else:
            pred = (probs >= 0.5).astype(int)
        s, sp, g, (tp, tn, fp, fn) = ep.metrics(pred, y)
        cm = np.array([[tn, fp], [fn, tp]])
        fs.confusion_fig(cm, CLS, P(name + ".png"), P(name + ".csv"))
    conf(probs_fp, PP_WIN, "eegK_confusion_software", True)              # software: best threshold
    conf(probs_dev, PP_WIN, "eegL_confusion_device_raw", False)
    conf(probs_dev, PP_WIN, "eegM_confusion_device_postproc", True, fixed_thr=0.5)  # device: natural theta=0.5

    # ---- training curves ----
    h = json.load(open(os.path.join(RUN, "eeg_lastread_history.json")))
    epn = [e["epoch"] for e in h]; gm = [e["device"].get("g_mean", 0) for e in h]
    se = [e["device"].get("sensitivity", 0) for e in h]; spc = [e["device"].get("specificity", 0) for e in h]
    loss = [e["loss"] for e in h]; frr = [e["fr_hz"] for e in h]
    fig, ax = fs.new_ax()
    ax.plot(epn, gm, "-o", ms=3, lw=2, color="#0b3d1e", label="G-mean")
    ax.plot(epn, se, "-", lw=2, color="#8b1a1a", label="Sensitivity")
    ax.plot(epn, spc, "-", lw=2, color="#1f4e79", label="Specificity")
    ax.legend(prop={"weight": "bold", "size": 10}); fs.bold_labels(ax, "Epoch", "Test metric")
    fs.finish(fig, P("eegN_training_metrics.png"))
    fs.save_csv(P("eegN_training_metrics.csv"), ["epoch", "g_mean", "sensitivity", "specificity"], list(zip(epn, gm, se, spc)))
    fig, ax = fs.new_ax(); ax.plot(epn, loss, "-o", ms=3, color="#8b1a1a", lw=2); fs.bold_labels(ax, "Epoch", "Training loss")
    fs.finish(fig, P("eegO_loss.png")); fs.save_csv(P("eegO_loss.csv"), ["epoch", "loss"], list(zip(epn, loss)))
    fig, ax = fs.new_ax(); ax.plot(epn, frr, "-o", ms=3, color="#2e8b57", lw=2); fs.bold_labels(ax, "Epoch", "Mean firing rate (Hz)")
    fs.finish(fig, P("eegP_firing_rate.png")); fs.save_csv(P("eegP_firing_rate.csv"), ["epoch", "fr_hz"], list(zip(epn, frr)))

    # ---- faithfulness / ablation bar (from eeg_results.json) ----
    r = json.load(open(os.path.join(_HERE, "eeg_results.json")))
    labels = ["Software", "On-device\n15 levels", "Ablation\n2 levels"]
    raw = [r["fp_raw"], r["dev15_raw"], r["dev2_raw"]]; ppv = [r["fp_pp"], r["dev15_pp"], r["dev2_pp"]]
    x = np.arange(3); w = 0.38
    fig, ax = fs.new_ax()
    ax.bar(x - w/2, raw, w, color="#a8d5b5", edgecolor="black", lw=2, label="raw G-mean")
    ax.bar(x + w/2, ppv, w, color="#2e8b57", edgecolor="black", lw=2, label="post-proc G-mean")
    ax.set_xticks(x); ax.set_xticklabels(labels, fontweight="bold"); ax.legend(prop={"weight": "bold", "size": 11})
    fs.bold_labels(ax, None, "G-mean"); ax.set_ylim(0, 1.05)
    fs.finish(fig, P("eegQ_faithfulness_ablation.png"))
    fs.save_csv(P("eegQ_faithfulness_ablation.csv"), ["config", "raw_gmean", "postproc_gmean"],
                [[labels[i].replace("\n", " "), raw[i], ppv[i]] for i in range(3)])

    print("EEG figures done ->", OUT)


if __name__ == "__main__":
    main()
