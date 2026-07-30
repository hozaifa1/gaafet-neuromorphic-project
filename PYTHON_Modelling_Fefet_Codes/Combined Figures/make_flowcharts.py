"""
Methodology flowcharts for ECG and EEG detection (BIG bold boxes, BIG bold text, bold arrows).
Saved into each task's figure folder. No LaTeX needed (drawn in matplotlib).
"""
import os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
_HERE = os.path.dirname(os.path.abspath(__file__))

GREEN = "#2e8b57"; DGREEN = "#0b3d1e"; BLUE = "#1f4e79"; GOLD = "#b8860b"; RED = "#8b1a1a"

# big boxes + big text per supervisor request
FS = 15.5           # box text font size
LW_BOX = 4.0        # box border width (bold)
LW_ARR = 3.6        # arrow width


def box(ax, xy, w, h, text, fc="#eafaf0", ec="black", tc="black", fs=FS):
    x, y = xy
    p = FancyBboxPatch((x - w/2, y - h/2), w, h, boxstyle="round,pad=0.02,rounding_size=0.08",
                       linewidth=LW_BOX, edgecolor=ec, facecolor=fc, mutation_aspect=1)
    ax.add_patch(p)
    ax.text(x, y, text, ha="center", va="center", fontsize=fs, fontweight="bold", color=tc)


def arrow(ax, p0, p1):
    a = FancyArrowPatch(p0, p1, arrowstyle="-|>", mutation_scale=30, lw=LW_ARR, color="black",
                        shrinkA=2, shrinkB=2)
    ax.add_patch(a)


def flowchart(task):
    fig, ax = plt.subplots(figsize=(9.0, 13.0))
    ax.set_xlim(0, 10); ax.set_ylim(0, 20); ax.axis("off")
    if task == "ecg":
        nodes = [
            (5, 19.0, 9.0, 1.5, "Analog ECG heartbeat\n(MIT-BIH, ~556 ms, single lead)", "#dbeafe", BLUE),
            (5, 16.4, 9.0, 1.5, "Delta / level-crossing encoder\n→ UP / DOWN spike trains + CUE (3 channels)", "#eafaf0", GREEN),
            (5, 13.6, 9.4, 1.9, "GAA-FeFET synapse LSNN\nweights = 15 measured conductance levels\n(differential G⁺−G⁻, in-memory MAC)", "#d7f0df", DGREEN),
            (5, 10.9, 9.0, 1.6, "Recurrent hidden layer\n100 LIF + 60 ALIF  (CMOS neurons)", "#fff4d6", GOLD),
            (5, 8.5, 7.4, 1.3, "Low-pass filter + linear readout", "#eafaf0", GREEN),
            (5, 6.1, 7.6, 1.5, "Mean-cue pooling → argmax\n4 classes: N / F / SVEB / VEB", "#dbeafe", BLUE),
            (5, 3.3, 9.4, 1.9, "Deploy on device: post-quantize\nto 15 FeFET levels → faithfulness,\nload-bearing ablation, robustness", "#d7f0df", DGREEN),
            (5, 1.0, 6.2, 1.2, "Arrhythmia class", "#f6d5d5", RED),
        ]
    else:
        nodes = [
            (5, 19.0, 9.0, 1.5, "Analog EEG clip\n(CHB-MIT, 18 channels, ~1.25 s)", "#dbeafe", BLUE),
            (5, 16.4, 9.2, 1.5, "Delta encoder per channel\n→ 18 UP + 18 DOWN + CUE (37 channels)", "#eafaf0", GREEN),
            (5, 13.6, 9.4, 1.9, "GAA-FeFET synapse LSNN\nweights = 15 measured conductance levels\n(differential G⁺−G⁻, in-memory MAC)", "#d7f0df", DGREEN),
            (5, 10.9, 9.0, 1.6, "Recurrent hidden layer\n24 LIF + 16 ALIF  (CMOS neurons)", "#fff4d6", GOLD),
            (5, 8.5, 7.4, 1.3, "Low-pass filter + linear readout", "#eafaf0", GREEN),
            (5, 6.1, 7.8, 1.5, "Last-timestep readout → argmax\nbinary: Normal / Epileptic", "#dbeafe", BLUE),
            (5, 3.3, 9.4, 1.9, "Decoupled post-processing:\nmoving average (w = 21) + threshold θ\n(on the contiguous hour-long stream)", "#fdeecb", GOLD),
            (5, 1.0, 6.2, 1.2, "Seizure decision", "#f6d5d5", RED),
        ]
    pts = []
    for (x, y, w, h, t, fc, ec) in nodes:
        box(ax, (x, y), w, h, t, fc=fc, ec=ec, tc="black", fs=FS)
        pts.append((x, y, h))
    for i in range(len(pts) - 1):
        x0, y0, h0 = pts[i]; x1, y1, h1 = pts[i + 1]
        arrow(ax, (x0, y0 - h0/2), (x1, y1 + h1/2))
    out = os.path.join(_HERE, f"{task} figures", f"{task}0_methodology_flowchart.png")
    fig.savefig(out, dpi=200, bbox_inches="tight", pad_inches=0.15); plt.close(fig)
    print("wrote", out)


if __name__ == "__main__":
    flowchart("ecg"); flowchart("eeg")
