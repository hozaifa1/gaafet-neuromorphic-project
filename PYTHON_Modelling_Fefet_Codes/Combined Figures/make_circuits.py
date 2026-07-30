"""
Two circuit schematics (bold, no LaTeX): (1) FeFET differential-pair crossbar in-memory MAC,
(2) CMOS LIF/ALIF neuron. Saved into ecg figures/ (shared device circuits).
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Circle, Rectangle, FancyArrowPatch, Polygon
_HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(_HERE, "ecg figures")
GREEN = "#2e8b57"; DGREEN = "#0b3d1e"; BLUE = "#1f4e79"; GOLD = "#b8860b"; RED = "#8b1a1a"


def fefet_cell(ax, x, y, sign, color):
    """Draw a small FeFET (transistor-with-FE-gate) symbol as a rounded box."""
    b = FancyBboxPatch((x-0.32, y-0.24), 0.64, 0.48, boxstyle="round,pad=0.01,rounding_size=0.05",
                       lw=2.4, edgecolor=color, facecolor="#eafaf0")
    ax.add_patch(b)
    ax.text(x, y, sign, ha="center", va="center", fontsize=12, fontweight="bold", color=color)


def crossbar():
    fig, ax = plt.subplots(figsize=(9.5, 7.2)); ax.axis("off")
    ax.set_xlim(0, 12); ax.set_ylim(0, 9)
    rows = [6.8, 5.2, 3.6]; cols = [4.2, 7.0, 9.8]
    rlab = ["V₁ (x₁)", "V₂ (x₂)", "V₃ (xₙ)"]
    # input rows (read voltages from spikes)
    for i, y in enumerate(rows):
        ax.plot([1.6, 11.2], [y, y], color="black", lw=3)
        ax.text(1.3, y, rlab[i], ha="right", va="center", fontsize=12, fontweight="bold", color=BLUE)
    # output columns (differential -> current sum)
    for j, x in enumerate(cols):
        ax.plot([x, x], [2.2, 7.4], color="black", lw=3)
        ax.plot([x+0.5, x+0.5], [2.2, 7.4], color="#888", lw=2, ls=(0, (4, 3)))
    # differential FeFET pairs at each crosspoint (G+ on the column line, G- on the shadow line)
    for y in rows:
        for x in cols:
            fefet_cell(ax, x, y, "G⁺", DGREEN)
            fefet_cell(ax, x+0.5, y, "G⁻", GOLD)
    # column current summation nodes
    for j, x in enumerate(cols):
        ax.add_patch(Circle((x+0.25, 1.9), 0.16, color="black"))
        ax.text(x+0.25, 1.35, f"I{['ⱼ','ⱼ','ⱼ'][j]}", ha="center", va="top", fontsize=13, fontweight="bold", color=RED)
        a = FancyArrowPatch((x+0.25, 2.15), (x+0.25, 1.6), arrowstyle="-|>", mutation_scale=18, lw=2.5, color=RED)
        ax.add_patch(a)
    ax.text(6.0, 8.4, "GAA-FeFET differential-pair crossbar  (in-memory MAC)",
            ha="center", fontsize=13, fontweight="bold", color=DGREEN)
    ax.text(6.0, 0.7, r"$I_j=\sum_i (G^{+}_{ij}-G^{-}_{ij})\,V_i \ \propto\ \sum_i w_{ij}x_i$",
            ha="center", fontsize=15, fontweight="bold")
    fig.tight_layout(); fig.savefig(os.path.join(OUT, "circ1_fefet_crossbar_MAC.png"), dpi=200, bbox_inches="tight")
    plt.close(fig); print("wrote circ1_fefet_crossbar_MAC.png")


def neuron():
    fig, ax = plt.subplots(figsize=(10, 6.4)); ax.axis("off")
    ax.set_xlim(0, 14); ax.set_ylim(0, 9)
    def box(x, y, w, h, t, ec, fc="#eafaf0", fs=11):
        ax.add_patch(FancyBboxPatch((x-w/2, y-h/2), w, h, boxstyle="round,pad=0.02,rounding_size=0.06",
                                    lw=3, edgecolor=ec, facecolor=fc))
        ax.text(x, y, t, ha="center", va="center", fontsize=fs, fontweight="bold")
    def arr(p0, p1, c="black"):
        ax.add_patch(FancyArrowPatch(p0, p1, arrowstyle="-|>", mutation_scale=20, lw=2.8, color=c))
    # input current (column current from crossbar)
    ax.text(0.6, 6.5, "I_in\n(MAC)", ha="center", va="center", fontsize=11, fontweight="bold", color=RED)
    arr((1.4, 6.5), (2.6, 6.5))
    # membrane node: Cmem + Rleak
    box(4.2, 6.5, 3.0, 1.4, "Membrane node\nC_mem (1 pF) ∥ R_leak", GREEN)
    ax.text(4.2, 5.2, "τ = R·C = 11.11 ms", ha="center", fontsize=9.5, fontweight="bold", color="#555")
    arr((5.7, 6.5), (7.0, 6.5))
    # comparator (threshold)
    ax.add_patch(Polygon([[7.2, 7.4], [7.2, 5.6], [9.0, 6.5]], closed=True, lw=3, edgecolor=BLUE, facecolor="#dbeafe"))
    ax.text(7.7, 6.5, "cmp", ha="center", va="center", fontsize=10, fontweight="bold")
    ax.text(7.6, 5.2, "v > v_th ?", ha="center", fontsize=9.5, fontweight="bold", color="#555")
    arr((9.0, 6.5), (10.4, 6.5))
    # spike + reset
    box(11.6, 6.5, 2.4, 1.3, "Spike s[t]\n→ reset v=v_reset", BLUE)
    # adaptation branch (ALIF)
    box(7.7, 2.4, 3.6, 1.5, "Adaptation (ALIF)\nspike → charge v_a (C_a,R_a)\n→ leak I_l subtracts from I_in", GOLD)
    arr((11.6, 5.85), (9.4, 3.0), GOLD)                # spike feeds adaptation
    arr((6.9, 2.9), (4.2, 5.8), GOLD)                  # adaptation subtracts at membrane
    ax.text(6.0, 8.3, "Compact CMOS LIF / ALIF neuron", ha="center", fontsize=13, fontweight="bold", color=DGREEN)
    fig.tight_layout(); fig.savefig(os.path.join(OUT, "circ2_cmos_neuron.png"), dpi=200, bbox_inches="tight")
    plt.close(fig); print("wrote circ2_cmos_neuron.png")


if __name__ == "__main__":
    crossbar(); neuron()
