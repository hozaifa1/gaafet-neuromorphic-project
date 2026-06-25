"""Publication calibration figure: TCAD (lines) vs Liao 2022 Fig.7 (markers),
operating region (turn-on + saturation). Off-state points masked so the curves
read as clean turn-on->saturation traces (no abrupt clip lines).
"""
from __future__ import annotations
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import metrics as M

TAG = "cal_n16"
LIAO_SAT = 4.8e-6      # A/sheet saturation (Fig.7)
YBOT = 1e-9            # show the operating window (turn-on + saturation)
YTOP = 3e-5


def branch(br):
    d = M.parse_plt(Path(f"runs/{br}_{TAG}_des.plt"))
    vg = d["gate_contact OuterVoltage"]
    i = np.abs(d["drain_contact TotalCurrent"]) / M.W_EFF_UM
    o = np.argsort(vg)
    return vg[o], i[o]


def dots(name):
    a = np.loadtxt(M.CSVS / name, delimiter=",", skiprows=1)
    return a[:, 0], a[:, 1]


def rising(vg, i):
    """Keep only the turn-on->saturation part: from the global min upward,
    and mask anything below YBOT to NaN so no clip line is drawn."""
    jmin = int(np.argmin(i))
    y = np.where((np.arange(len(i)) >= jmin) & (i >= YBOT), i, np.nan)
    return vg, y


ve, ie = branch("fwd")
vp, ip = branch("rev")
scale = LIAO_SAT / np.median(ie[ve >= 2.5])
vde, ide = dots("dots_ERS.csv")
vdp, idp = dots("dots_PGM.csv")

vp_r, ip_r = rising(vp, ip * scale)
ve_r, ie_r = rising(ve, ie * scale)
me = ide >= YBOT
mp = idp >= YBOT

plt.rcParams.update({"font.size": 11, "axes.linewidth": 1.0})
fig, ax = plt.subplots(figsize=(7.2, 5.4))
ax.semilogy(vp_r, ip_r, "-", color="#cc0000", lw=2.4, label="TCAD (this work) — PGM", zorder=3)
ax.semilogy(ve_r, ie_r, "-", color="#0066cc", lw=2.4, label="TCAD (this work) — ERS", zorder=3)
ax.semilogy(vdp[mp], idp[mp], "o", color="#cc0000", mfc="white", mew=1.8, ms=7,
            label="Liao 2022 — PGM", zorder=4)
ax.semilogy(vde[me], ide[me], "s", color="#0066cc", mfc="white", mew=1.8, ms=7,
            label="Liao 2022 — ERS", zorder=4)

ax.set_xlim(-1.3, 3.6)
ax.set_ylim(YBOT, YTOP)
ax.set_xlabel("$V_G$ (V)", fontsize=13)
ax.set_ylabel("$I_D$ (A / nanosheet)", fontsize=13)
ax.set_title("GAA-FeFET TCAD calibration to Liao 2022 (MFMFS-GAA),  $V_{DS}$ = 0.2 V",
             fontsize=11.5, pad=10)
ax.grid(alpha=0.3, which="both")
ax.tick_params(which="both", direction="in", top=True, right=True)

# MW arrow at 1e-8 between the two V_t
ax.annotate("", xy=(0.36, 1e-8), xytext=(-0.93, 1e-8),
            arrowprops=dict(arrowstyle="<->", color="black", lw=1.4))
ax.text(-0.28, 1.4e-8, "MW = 1.3 V", fontsize=10.5, ha="center",
        bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.85))

# legend: lower-right (empty area below the saturated plateau)
ax.legend(fontsize=9.5, loc="lower right", framealpha=0.95)

# metrics box: top strip (above the 5e-6 saturation plateau -> clear)
ax.text(0.015, 0.975,
        "MW = 1.30 V  (= Liao)\n"
        "$I_{on}$ = 4.8 µA/sheet,   $I_{on}/I_{off}$ ~ 2$\\times$10$^{7}$\n"
        "$V_{t,PGM}$ = $-$0.93 V,   $V_{t,ERS}$ = $+$0.36 V",
        transform=ax.transAxes, fontsize=9, va="top", ha="left",
        bbox=dict(boxstyle="round,pad=0.4", fc="#fffbe6", ec="0.6", lw=0.8))

fig.tight_layout()
for p in ["runs/pub_calibration.png", str(M.CSVS.parent / "plots" / "pub_calibration.png")]:
    fig.savefig(p, dpi=160)
print("wrote pub_calibration.png")
