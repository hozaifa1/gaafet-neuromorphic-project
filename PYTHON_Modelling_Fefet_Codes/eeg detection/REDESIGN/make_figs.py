"""Generate paper figures from a training run's history JSON. Usage:
   python make_figs.py <run_dir>   (defaults to runs/paper150b)"""
import os
import sys
import json
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
run = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "runs", "paper150b")
tag = os.path.basename(run)
hist = json.load(open(os.path.join(run, f"{tag}_history.json")))

ep = [h["epoch"] for h in hist]
acc = [h["device"]["accuracy"] for h in hist]
f1 = [h["device"]["macro_f1"] for h in hist]
loss = [h["loss"] for h in hist]
fr = [h["fr_hz"] for h in hist]
train = [h["train_acc"] for h in hist]
best_i = int(np.argmax([h["device"]["macro_f1"] for h in hist]))

plt.rcParams.update({"font.size": 12, "axes.grid": True, "grid.alpha": 0.3, "figure.dpi": 150})
TEAL, AMBER, INK = "#0d8b9a", "#c1852a", "#333333"

# (a) accuracy + macro-F1 vs epoch
fig, ax = plt.subplots(figsize=(7, 4.2))
ax.plot(ep, acc, color=TEAL, lw=2, label="Test accuracy")
ax.plot(ep, f1, color=AMBER, lw=2, label="Macro-F1")
ax.plot(ep, train, color=INK, lw=1, ls="--", alpha=0.6, label="Train accuracy")
ax.scatter([ep[best_i]], [acc[best_i]], color=TEAL, zorder=5, s=45,
           label=f"Best: acc={acc[best_i]:.3f}, F1={f1[best_i]:.3f} @ep{ep[best_i]}")
ax.set_xlabel("Epoch"); ax.set_ylabel("Score"); ax.set_ylim(0, 1)
ax.set_title("GAA-FeFET SNN — ECG 4-class: accuracy & macro-F1 vs epoch")
ax.legend(loc="lower right", fontsize=9)
fig.tight_layout(); fig.savefig(os.path.join(run, "fig_accuracy.png")); plt.close(fig)

# (b) loss vs epoch
fig, ax = plt.subplots(figsize=(7, 3.6))
ax.plot(ep, loss, color=TEAL, lw=2)
ax.set_xlabel("Epoch"); ax.set_ylabel("Training loss (CE + spike-reg)")
ax.set_title("Training loss vs epoch")
fig.tight_layout(); fig.savefig(os.path.join(run, "fig_loss.png")); plt.close(fig)

# (c) firing rate vs epoch
fig, ax = plt.subplots(figsize=(7, 3.6))
ax.plot(ep, fr, color=AMBER, lw=2)
ax.axhline(20, color=INK, ls="--", alpha=0.5, label="target 20 Hz")
ax.set_xlabel("Epoch"); ax.set_ylabel("Mean firing rate (Hz)")
ax.set_title("Neuron firing rate vs epoch (regularized)"); ax.legend(fontsize=9)
fig.tight_layout(); fig.savefig(os.path.join(run, "fig_fr.png")); plt.close(fig)

# (d) confusion at best epoch
cm = np.array(hist[best_i]["device"]["confusion"])
classes = ["N", "F", "SVEB", "VEB"]
fig, ax = plt.subplots(figsize=(4.8, 4.4))
im = ax.imshow(cm, cmap="BuGn")
ax.set_xticks(range(4)); ax.set_xticklabels(classes)
ax.set_yticks(range(4)); ax.set_yticklabels(classes)
ax.set_xlabel("Predicted"); ax.set_ylabel("True")
ax.set_title(f"Confusion @ best epoch {ep[best_i]} (acc {acc[best_i]:.3f})")
for i in range(4):
    for j in range(4):
        ax.text(j, i, str(cm[i, j]), ha="center", va="center",
                color="white" if cm[i, j] > cm.max() * 0.5 else "black", fontsize=11)
fig.tight_layout(); fig.savefig(os.path.join(run, "fig_confusion.png")); plt.close(fig)

print(f"wrote 4 figures to {run}")
print(f"  best: epoch {ep[best_i]}  acc={acc[best_i]:.4f}  macroF1={f1[best_i]:.4f}  ({len(ep)} epochs logged)")
