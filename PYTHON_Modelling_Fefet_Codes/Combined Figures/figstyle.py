"""
Shared Origin-style figure formatting for the GAA-FeFET neuromorphic paper figures.
RULES (per supervisor):
  - left & bottom ticks INSIDE the axes; right & top spines shown but NO ticks
  - ALL text bold (axis titles, tick labels, legend, annotations)
  - NO plot title (the figure caption/name is supplied separately)
  - Origin-style: black axes, thick spines, inward major+minor ticks, clean
  - confusion matrix: GREEN/WHITE colormap, BOLD cell text, BOLD row/col separator lines
Each figure is saved as PNG; the caller also writes the CSV that reproduces it.
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import rcParams
from matplotlib.colors import LinearSegmentedColormap

# ---- global bold / Origin rcParams ----
rcParams.update({
    "font.family": "DejaVu Sans",
    "font.weight": "bold",
    "axes.labelweight": "bold",
    "axes.titleweight": "bold",
    "axes.linewidth": 2.5,
    "axes.edgecolor": "black",
    "xtick.direction": "in",
    "ytick.direction": "in",
    "xtick.major.width": 2.2,
    "ytick.major.width": 2.2,
    "xtick.minor.width": 1.5,
    "ytick.minor.width": 1.5,
    "xtick.major.size": 7.5,
    "ytick.major.size": 7.5,
    "xtick.minor.size": 4.0,
    "ytick.minor.size": 4.0,
    "xtick.top": True,      # ticks on top inward
    "ytick.right": True,    # ticks on right inward
    "font.size": 18,
    "axes.labelsize": 24,
    "xtick.labelsize": 20,
    "ytick.labelsize": 20,
    "legend.fontsize": 16,
    "legend.frameon": False,
    "savefig.dpi": 600,
    "figure.constrained_layout.use": False,
})

# green/white colormap for confusion matrices (white -> deep green)
GREEN_WHITE = LinearSegmentedColormap.from_list("green_white", ["#ffffff", "#2e8b57", "#0b3d1e"])


def new_ax(figsize=(8.0, 5.4)):
    """A styled axes: box on, inward L/B/T/R ticks, bold."""
    fig, ax = plt.subplots(figsize=figsize)
    for sp in ax.spines.values():
        sp.set_linewidth(2.5); sp.set_color("black")
    ax.tick_params(axis="both", which="both", direction="in",
                   top=True, right=True, labelsize=20, width=2.2)
    ax.minorticks_on()
    ax.tick_params(axis="both", which="minor", top=True, right=True, direction="in", width=1.5)
    for lbl in ax.get_xticklabels() + ax.get_yticklabels():
        lbl.set_fontweight("bold")
        lbl.set_fontsize(20)
    return fig, ax


def bold_labels(ax, xlabel=None, ylabel=None):
    if xlabel: ax.set_xlabel(xlabel, fontweight="bold", fontsize=24, labelpad=15)
    if ylabel: 
        ax.set_ylabel(ylabel, fontweight="bold", fontsize=24)
        ax.yaxis.set_label_coords(-0.25, 0.5)
    ax.tick_params(axis="both", which="major", pad=12)
    for lbl in ax.get_xticklabels() + ax.get_yticklabels():
        lbl.set_fontweight("bold")
        lbl.set_fontsize(20)


def finish(fig, path):
    # generous tight bbox => axis titles/ticklabels are never clipped
    fig.savefig(path, bbox_inches="tight", pad_inches=0.6)
    plt.close(fig)


def save_csv(path, header, rows):
    """Write a reproducible CSV: header list + rows (list of lists)."""
    import csv
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        for r in rows:
            w.writerow(r)


def confusion_fig(cm, classes, png_path, csv_path, sub=None):
    """Green/white confusion matrix: bold cell text, bold separator grid lines, no title.
    cm: 2D int array [true, pred]; classes: labels. sub: optional bold subtitle-less metric line
    is NOT drawn as title (rules: no title) — pass via xlabel if wanted."""
    cm = np.asarray(cm)
    n = len(classes)
    fig, ax = plt.subplots(figsize=(1.15 * n + 4.0, 1.15 * n + 3.4))
    vmax = cm.max() if cm.max() > 0 else 1
    ax.imshow(cm, cmap=GREEN_WHITE, vmin=0, vmax=vmax)
    # bold cell numbers
    for i in range(n):
        for j in range(n):
            ax.text(j, i, f"{cm[i, j]}", ha="center", va="center",
                    fontsize=16, fontweight="bold",
                    color="white" if cm[i, j] > 0.5 * vmax else "black")
    # bold separator grid lines
    for k in range(n + 1):
        ax.axhline(k - 0.5, color="black", lw=2.4)
        ax.axvline(k - 0.5, color="black", lw=2.4)
    ax.set_xticks(range(n)); ax.set_yticks(range(n))
    ax.set_xticklabels(classes, fontweight="bold", fontsize=13)
    ax.set_yticklabels(classes, fontweight="bold", fontsize=13)
    ax.set_xlabel("Predicted", fontweight="bold", fontsize=14)   # metrics go in the caption, not on-graph
    ax.set_ylabel("True", fontweight="bold", fontsize=14)
    ax.tick_params(length=0)                    # no ticks, labels only, for matrix
    ax.set_xlim(-0.5, n - 0.5); ax.set_ylim(n - 0.5, -0.5)
    for sp in ax.spines.values():
        sp.set_linewidth(2.4)
    fig.savefig(png_path, bbox_inches="tight", pad_inches=0.3); plt.close(fig)
    # CSV (true rows x pred cols)
    header = ["true\\pred"] + list(classes)
    rows = [[classes[i]] + [int(cm[i, j]) for j in range(n)] for i in range(n)]
    save_csv(csv_path, header, rows)
