"""
ECG task figures (VO2-paper Fig-5 analogs + extras) into Combined Figures/ecg figures/.
Each figure: PNG (Origin style) + reproducing CSV. Uses the locked paper150b checkpoint.
"""
import torch, os, sys, json
import numpy as np
import torch.utils.data as data
_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "REDESIGN", "code"))
CF = os.path.join(_HERE, "..", "Combined Figures")
sys.path.insert(0, CF)
import figstyle as fs
import matplotlib.pyplot as plt
import redesign_stage1 as rs
import post_quantize as pq
from dataset import DeltaTransformedECG
from metrics import ecg_report

OUT = os.path.join(CF, "ecg figures"); os.makedirs(OUT, exist_ok=True)
def P(n): return os.path.join(OUT, n)
CKPT = "REDESIGN/runs/paper150b/paper150b_best.ckpt"
CLASSES = ["N", "F", "SVEB", "VEB"]
NLIF, NALIF = 100, 60


def load_model(device, quant=False):
    pq.ARCH["num_in"] = 3
    m = pq.build_orig(device)
    st = torch.load(os.path.join(_HERE, CKPT), map_location=device, weights_only=False)
    m.load_state_dict(st["net"])
    if quant:
        pq.quantize_(m, pq.achievable_diff_values(15))
    return m


def get_beats(device):
    ds = DeltaTransformedECG(path=os.path.join(_HERE, "data_ecg"), output_cue_length=116, n_class=4)
    _, test = data.random_split(ds, [1664, 336], generator=torch.Generator().manual_seed(100))
    # pick one VEB (label 3) beat for illustration
    for i in test.indices:
        if int(ds.labels[i]) == 3:
            return ds.data[i:i+1].to(device), test, ds
    return ds.data[test.indices[0]:test.indices[0]+1].to(device), test, ds


def raster(spikes, fname, ylabel, csvname, color="#0b3d1e"):
    # spikes: [T, N] binary
    T, N = spikes.shape
    fig, ax = fs.new_ax(figsize=(9.5, 5.0))
    ii, tt = np.where(spikes.T > 0.5)  # neuron idx, time
    ax.scatter(tt, ii, s=4, c=color, marker="|", linewidths=1.2)
    fs.bold_labels(ax, "Timestep", ylabel)
    ax.set_xlim(0, T); ax.set_ylim(-0.5, N - 0.5)
    fs.finish(fig, P(fname))
    rows = [[int(t), int(n)] for t, n in zip(tt, ii)]
    fs.save_csv(P(csvname), ["timestep", "neuron_index"], rows)


def main():
    dev = torch.device("cpu")
    beat, test, ds = get_beats(dev)

    # ---- single-beat forward with recorded internal states (batch==1) ----
    m = load_model(dev, quant=False); m.eval()
    from spikingjelly.clock_driven import functional
    with torch.no_grad():
        out = m(beat.float())               # [T,1,4]
    spk = m.spike.cpu().numpy()             # [T, NLIF+NALIF]
    vth = m.v_threshold.cpu().numpy()       # [T, NALIF]  (ALIF adaptation Vg)
    prob = torch.softmax(out.squeeze(1), -1).cpu().numpy()  # [T,4]
    inp = beat.squeeze(0).cpu().numpy()     # [T, 3]  (up,down,cue)
    functional.reset_net(m)

    # Fig: input spike raster (up/down/cue)
    raster((inp > 0.5).astype(int), "ecgA_input_raster.png", "Input channel (0=UP,1=DOWN,2=CUE)",
           "ecgA_input_raster.csv", color="#1f4e79")
    # Fig: LIF raster
    raster(spk[:, :NLIF], "ecgB_LIF_raster.png", "LIF neuron index", "ecgB_LIF_raster.csv")
    # Fig: ALIF raster
    raster(spk[:, NLIF:], "ecgC_ALIF_raster.png", "ALIF neuron index", "ecgC_ALIF_raster.csv", color="#b8860b")

    # Fig: Vg evolution of 5 ALIF neurons
    fig, ax = fs.new_ax(figsize=(9.5, 5.0))
    T = vth.shape[0]; cols = ["#0b3d1e", "#2e8b57", "#1f4e79", "#b8860b", "#8b1a1a"]
    for k in range(min(5, vth.shape[1])):
        ax.plot(range(T), vth[:, k], lw=2.0, color=cols[k], label=f"ALIF {k}")
    ax.legend(prop={"weight": "bold", "size": 9}, ncol=2)
    fs.bold_labels(ax, "Timestep", "Adaptation Vg (V)")
    fs.finish(fig, P("ecgD_Vg_evolution.png"))
    fs.save_csv(P("ecgD_Vg_evolution.csv"), ["timestep"] + [f"ALIF{k}" for k in range(5)],
                [[t] + [vth[t, k] for k in range(min(5, vth.shape[1]))] for t in range(T)])

    # Fig: output probability evolution
    fig, ax = fs.new_ax(figsize=(9.5, 5.0))
    for c in range(4):
        ax.plot(range(prob.shape[0]), prob[:, c], lw=2.2, color=cols[c], label=CLASSES[c])
    ax.legend(prop={"weight": "bold", "size": 10}, ncol=2)
    fs.bold_labels(ax, "Timestep", "Output probability")
    ax.set_ylim(0, 1)
    fs.finish(fig, P("ecgE_output_prob.png"))
    fs.save_csv(P("ecgE_output_prob.csv"), ["timestep"] + CLASSES,
                [[t] + list(prob[t]) for t in range(prob.shape[0])])

    # ---- training curves ----
    h = json.load(open(os.path.join(_HERE, "REDESIGN/runs/paper150b/paper150b_history.json")))
    ep = [e["epoch"] for e in h]; acc = [e["device"]["accuracy"] for e in h]
    f1 = [e["device"]["macro_f1"] for e in h]; loss = [e["loss"] for e in h]; frr = [e["fr_hz"] for e in h]
    fig, ax = fs.new_ax()
    ax.plot(ep, acc, "-o", ms=3, color="#0b3d1e", lw=2.0, label="Accuracy")
    ax.plot(ep, f1, "-s", ms=3, color="#b8860b", lw=2.0, label="macro-F1")
    ax.legend(prop={"weight": "bold", "size": 11}); fs.bold_labels(ax, "Epoch", "Test metric")
    fs.finish(fig, P("ecgF_training_metrics.png"))
    fs.save_csv(P("ecgF_training_metrics.csv"), ["epoch", "accuracy", "macro_f1"], list(zip(ep, acc, f1)))
    fig, ax = fs.new_ax(); ax.plot(ep, loss, "-o", ms=3, color="#8b1a1a", lw=2.0)
    fs.bold_labels(ax, "Epoch", "Training loss"); fs.finish(fig, P("ecgG_loss.png"))
    fs.save_csv(P("ecgG_loss.csv"), ["epoch", "loss"], list(zip(ep, loss)))
    fig, ax = fs.new_ax(); ax.plot(ep, frr, "-o", ms=3, color="#2e8b57", lw=2.0)
    fs.bold_labels(ax, "Epoch", "Mean firing rate (Hz)"); fs.finish(fig, P("ecgH_firing_rate.png"))
    fs.save_csv(P("ecgH_firing_rate.csv"), ["epoch", "fr_hz"], list(zip(ep, frr)))

    # ---- confusion matrices (software + device) ----
    test_loader = data.DataLoader(data.Subset(ds, test.indices), batch_size=128, shuffle=False)
    def confusion(quant, name):
        m2 = load_model(dev, quant=quant)
        rep = rs.evaluate(m2, test_loader, dev, quant=False, rmode="meancue", k=116)
        cm = np.array(rep["confusion"])
        acc_, f1_ = rep["accuracy"], rep["macro_f1"]
        fs.confusion_fig(cm, CLASSES, P(name + ".png"), P(name + ".csv"),
                         sub=f"acc {acc_:.3f} / macro-F1 {f1_:.3f}")
        return rep
    rep_sw = confusion(False, "ecgI_confusion_software")
    rep_dev = confusion(True, "ecgJ_confusion_device_15level")

    # ---- faithfulness + ablation bar (software / 15-level / 2-level) ----
    m3 = load_model(dev, quant=False)
    pq.quantize_(m3, pq.achievable_diff_values(2))
    rep_abl = rs.evaluate(m3, test_loader, dev, quant=False, rmode="meancue", k=116)
    labels = ["Software\n(FP)", "On-device\n15 levels", "Ablation\n2 levels"]
    accs = [rep_sw["accuracy"], rep_dev["accuracy"], rep_abl["accuracy"]]
    f1s = [rep_sw["macro_f1"], rep_dev["macro_f1"], rep_abl["macro_f1"]]
    x = np.arange(3); w = 0.38
    fig, ax = fs.new_ax()
    ax.bar(x - w/2, accs, w, color="#2e8b57", edgecolor="black", lw=2, label="Accuracy")
    ax.bar(x + w/2, f1s, w, color="#b8860b", edgecolor="black", lw=2, label="macro-F1")
    ax.set_xticks(x); ax.set_xticklabels(labels, fontweight="bold")
    ax.legend(prop={"weight": "bold", "size": 11}); fs.bold_labels(ax, None, "Score"); ax.set_ylim(0, 1)
    fs.finish(fig, P("ecgK_faithfulness_ablation.png"))
    fs.save_csv(P("ecgK_faithfulness_ablation.csv"), ["config", "accuracy", "macro_f1"],
                [[labels[i].replace("\n", " "), accs[i], f1s[i]] for i in range(3)])

    # ---- per-class Se/+P/F1 (on-device) ----
    pc = rep_dev["per_class"]; metrics3 = ["Se", "+P", "F1"]; colors3 = ["#0b3d1e", "#2e8b57", "#b8860b"]
    x = np.arange(4); w = 0.26
    fig, ax = fs.new_ax()
    for j, mkey in enumerate(metrics3):
        ax.bar(x + (j-1)*w, [pc[c][mkey] for c in CLASSES], w, color=colors3[j], edgecolor="black", lw=1.6, label=mkey)
    ax.set_xticks(x); ax.set_xticklabels(CLASSES, fontweight="bold")
    ax.legend(prop={"weight": "bold", "size": 11}); fs.bold_labels(ax, "Class", "Score"); ax.set_ylim(0, 1)
    fs.finish(fig, P("ecgL_per_class.png"))
    fs.save_csv(P("ecgL_per_class.csv"), ["class", "Se", "+P", "F1"],
                [[c, pc[c]["Se"], pc[c]["+P"], pc[c]["F1"]] for c in CLASSES])

    print("ECG figures done ->", OUT)


if __name__ == "__main__":
    main()
