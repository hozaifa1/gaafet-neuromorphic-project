"""Publication-quality curve plotter for Sentaurus TCAD CSV data.

Reads CSV files produced by plt2csv.py (converted from DF-ISE .plt format)
and generates plots that exactly match the reference publication style:
  - Bold axis labels with subscript notation (I_DS, V_DS, V_GS)
  - Thick lines (2.5 pt), specific color cycle
  - White background with thick black border (no grid)
  - 2-column legend inside upper-left
  - Bold tick labels, 14 pt font

Usage examples:
  # Plot all read CSVs from a sweep directory (one curve per file)
  python plot_curves.py --dir csv_export/iv_curves/t5_fe07 --pattern "p*_read_*_v025_des.csv"

  # Plot specific CSV files
  python plot_curves.py --files file1.csv file2.csv file3.csv

  # Auto-discover & plot all sweeps mentioned in the README
  python plot_curves.py --auto

  # Customise axes
  python plot_curves.py --dir some_dir --xcol "gate_contact OuterVoltage" \
      --ycol "drain_contact TotalCurrent" --xlabel "V_GS (V)" --ylabel "I_DS (µA)"
"""
from __future__ import annotations

import argparse
import glob
import os
import re
import sys
from pathlib import Path

import matplotlib
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np
import pandas as pd

# ═══════════════════════════════════════════════════════════════════════
# PUBLICATION STYLE — matches the reference image exactly
# ═══════════════════════════════════════════════════════════════════════

# Color cycle: red, blue, gold/orange, green, purple, gray
# (matches the 6-curve V_GS output characteristics image)
PUB_COLORS = [
    "#C0392B",  # red
    "#2471A3",  # blue
    "#D4AC0D",  # gold / dark yellow
    "#1E8449",  # green
    "#6C3483",  # purple
    "#808080",  # gray
]

# Extended palette for > 6 curves
PUB_COLORS_EXT = PUB_COLORS + [
    "#E67E22",  # orange
    "#2ECC71",  # emerald
    "#3498DB",  # light blue
    "#E74C3C",  # bright red
    "#1ABC9C",  # teal
    "#34495E",  # dark slate
]


def apply_pub_style():
    """Set matplotlib rcParams to match the reference publication style."""
    plt.rcParams.update({
        # Font
        "font.family":       "serif",
        "font.serif":        ["Times New Roman", "DejaVu Serif", "serif"],
        "mathtext.fontset":  "dejavuserif",

        # Font sizes — large, bold for publication
        "font.size":         14,
        "axes.labelsize":    16,
        "axes.titlesize":    16,
        "legend.fontsize":   12,
        "xtick.labelsize":   14,
        "ytick.labelsize":   14,

        # Bold labels
        "axes.labelweight":  "bold",
        "axes.titleweight":  "bold",

        # Thick axes frame (matches the heavy black border in the image)
        "axes.linewidth":    2.0,

        # Thick lines
        "lines.linewidth":   2.5,

        # Ticks — inward, both sides, matching the reference
        "xtick.direction":   "in",
        "ytick.direction":   "in",
        "xtick.major.size":  6,
        "ytick.major.size":  6,
        "xtick.minor.size":  3,
        "ytick.minor.size":  3,
        "xtick.major.width": 1.5,
        "ytick.major.width": 1.5,
        "xtick.minor.width": 1.0,
        "ytick.minor.width": 1.0,
        "xtick.top":         True,
        "ytick.right":       True,

        # No grid (clean white background like the reference)
        "axes.grid":         False,

        # White background
        "figure.facecolor":  "white",
        "axes.facecolor":    "white",
        "savefig.facecolor": "white",

        # High-res output
        "savefig.dpi":       600,
        "figure.dpi":        150,

        # Tight layout by default
        "figure.autolayout": True,
    })


# ═══════════════════════════════════════════════════════════════════════
# DATA LOADING
# ═══════════════════════════════════════════════════════════════════════

# Common Sentaurus column names for auto-detection
DRAIN_VOLTAGE_COLS = [
    "drain_contact OuterVoltage",
    "drain OuterVoltage",
    "DrainVoltage",
]
GATE_VOLTAGE_COLS = [
    "gate_contact OuterVoltage",
    "gate OuterVoltage",
    "GateVoltage",
]
DRAIN_CURRENT_COLS = [
    "drain_contact TotalCurrent",
    "drain_contact eCurrent",
    "drain TotalCurrent",
    "DrainCurrent",
]


def find_column(df: pd.DataFrame, candidates: list[str]) -> str | None:
    """Return the first matching column name from candidates, or None."""
    for c in candidates:
        if c in df.columns:
            return c
    return None


def load_csv(path: str | Path) -> pd.DataFrame:
    """Load a CSV, stripping any trailing blank rows."""
    df = pd.read_csv(path)
    df = df.dropna(how="all")
    return df


def extract_label_from_filename(fname: str) -> str:
    """Try to extract a human-readable label from a Sentaurus CSV filename.

    Examples:
        p09_read_t5_fe07_v025_des.csv  ->  "V = 2.5V (p09)"
        baseline_pre_t5_fe07_v025_des  ->  "V = 2.5V (baseline)"
    """
    name = Path(fname).stem

    # Try to find voltage suffix like v025, v040, etc.
    m = re.search(r"_v(\d{2,3})_", name)
    if m:
        v_raw = m.group(1)
        voltage = int(v_raw) / 10.0  # v025 -> 2.5, v040 -> 4.0
        # Extract pulse tag (p01, p09, baseline_pre, etc.)
        pulse = name.split("_")[0]
        if pulse.startswith("p"):
            pulse_num = pulse.replace("p", "pulse ")
        elif "baseline" in pulse:
            pulse_num = "baseline"
        else:
            pulse_num = pulse
        return f"V = {voltage:.1f}V ({pulse_num})"

    # Fallback: use the full stem
    return name


def extract_vgs_from_row(df: pd.DataFrame) -> float | None:
    """Extract the gate voltage from the first row (constant V_GS during read)."""
    col = find_column(df, GATE_VOLTAGE_COLS)
    if col is None:
        return None
    vals = df[col].dropna().unique()
    # Gate voltage should be constant during a read sweep
    if len(vals) == 1:
        return float(vals[0])
    # Return the most common value
    return float(df[col].mode().iloc[0])


# ═══════════════════════════════════════════════════════════════════════
# PLOTTING ENGINE
# ═══════════════════════════════════════════════════════════════════════

def plot_curves(
    data_list: list[tuple[np.ndarray, np.ndarray, str]],
    xlabel: str = r"$\mathbf{V_{DS}}$ $\mathbf{(V)}$",
    ylabel: str = r"$\mathbf{I_{DS}}$ $\mathbf{(\mu A)}$",
    title: str = "",
    y_scale: float = 1e6,        # multiply y-data by this (A -> µA)
    x_scale: float = 1.0,
    figsize: tuple = (6.5, 5.5),
    legend_ncol: int = 2,
    legend_loc: str = "upper left",
    outfile: str | None = None,
    show: bool = True,
    xlim: tuple | None = None,
    ylim: tuple | None = None,
):
    """Plot publication-quality curves.

    Parameters
    ----------
    data_list : list of (x_array, y_array, label_string)
    xlabel, ylabel : axis labels (LaTeX OK)
    y_scale : multiplier for y-axis (e.g. 1e6 to convert A -> µA)
    outfile : if given, save PNG/PDF/SVG to this path
    """
    apply_pub_style()

    fig, ax = plt.subplots(figsize=figsize)

    colors = PUB_COLORS_EXT if len(data_list) > 6 else PUB_COLORS

    for i, (x, y, label) in enumerate(data_list):
        color = colors[i % len(colors)]
        ax.plot(x * x_scale, y * y_scale, color=color, linewidth=2.5, label=label)

    # Axis labels — bold, with subscripts
    ax.set_xlabel(xlabel, fontsize=16, fontweight="bold")
    ax.set_ylabel(ylabel, fontsize=16, fontweight="bold")

    if title:
        ax.set_title(title, fontsize=16, fontweight="bold")

    # Axis limits
    if xlim is not None:
        ax.set_xlim(xlim)
    if ylim is not None:
        ax.set_ylim(ylim)

    # Bold tick labels
    for label in ax.get_xticklabels() + ax.get_yticklabels():
        label.set_fontweight("bold")

    # Legend — matches the 2-column style in the reference image
    if any(lbl for _, _, lbl in data_list):
        leg = ax.legend(
            loc=legend_loc,
            ncol=legend_ncol,
            frameon=True,
            edgecolor="black",
            framealpha=1.0,
            fancybox=False,
            fontsize=12,
            handlelength=2.0,
            columnspacing=1.0,
        )
        leg.get_frame().set_linewidth(1.5)

    fig.tight_layout()

    if outfile:
        out_path = Path(outfile)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(str(out_path), dpi=600, bbox_inches="tight",
                    facecolor="white", edgecolor="none")
        print(f"Saved: {out_path}")

    if show:
        plt.show()
    else:
        plt.close(fig)

    return fig, ax


# ═══════════════════════════════════════════════════════════════════════
# CLI COMMANDS
# ═══════════════════════════════════════════════════════════════════════

def cmd_files(args):
    """Plot specific CSV files, one curve per file."""
    xcol = args.xcol
    ycol = args.ycol
    data_list = []

    for fpath in args.files:
        df = load_csv(fpath)
        # Auto-detect columns if not specified
        xc = xcol or find_column(df, DRAIN_VOLTAGE_COLS) or df.columns[1]
        yc = ycol or find_column(df, DRAIN_CURRENT_COLS) or df.columns[7]

        x = df[xc].values.astype(float)
        y = df[yc].values.astype(float)

        label = args.labels.pop(0) if args.labels else extract_label_from_filename(fpath)
        data_list.append((x, y, label))

    xlim = None
    if args.xlim:
        xlim = tuple(map(float, args.xlim.split(",")))
    ylim = None
    if args.ylim:
        ylim = tuple(map(float, args.ylim.split(",")))

    plot_curves(
        data_list,
        xlabel=args.xlabel,
        ylabel=args.ylabel,
        title=args.title or "",
        y_scale=float(args.yscale),
        x_scale=float(args.xscale),
        outfile=args.output,
        show=not args.no_show,
        legend_ncol=args.legend_ncol,
        xlim=xlim,
        ylim=ylim,
    )


def cmd_dir(args):
    """Plot all matching CSVs in a directory, one curve per file."""
    pattern = args.pattern or "*.csv"
    search = os.path.join(args.dir, pattern)
    files = sorted(glob.glob(search))

    if not files:
        print(f"No files matching '{search}'")
        sys.exit(1)

    print(f"Found {len(files)} files matching '{pattern}'")

    xcol = args.xcol
    ycol = args.ycol
    data_list = []

    for fpath in files:
        df = load_csv(fpath)
        xc = xcol or find_column(df, DRAIN_VOLTAGE_COLS) or df.columns[1]
        yc = ycol or find_column(df, DRAIN_CURRENT_COLS) or df.columns[7]

        x = df[xc].values.astype(float)
        y = df[yc].values.astype(float)

        # Try to extract VGS for the legend
        vgs = extract_vgs_from_row(df)
        if vgs is not None:
            label = f"$V_{{GS}}$ = {vgs:.1f}V"
        else:
            label = extract_label_from_filename(fpath)

        data_list.append((x, y, label))

    xlim = None
    if args.xlim:
        xlim = tuple(map(float, args.xlim.split(",")))
    ylim = None
    if args.ylim:
        ylim = tuple(map(float, args.ylim.split(",")))

    plot_curves(
        data_list,
        xlabel=args.xlabel,
        ylabel=args.ylabel,
        title=args.title or "",
        y_scale=float(args.yscale),
        x_scale=float(args.xscale),
        outfile=args.output,
        show=not args.no_show,
        legend_ncol=args.legend_ncol,
        xlim=xlim,
        ylim=ylim,
    )


def cmd_auto(args):
    """Auto-discover the sweep data from the README and plot all figures.

    The read-phase CSVs are time-domain transients at fixed V_DS = 0.05 V.
    X-axis = time (converted to ns); Y-axis = drain TotalCurrent (A -> µA).
    One curve per device variant, overlaid to compare sweep parameters.
    """
    ROOT = Path(r"F:\RESEARCH\FeFET x ML\TCAD Files\GAAFet\Device_Optimization")
    CSV_ROOT = ROOT / "csv_export" / "iv_curves"
    OUT_DIR = ROOT / "csv_export" / "publication_plots"
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Define the sweeps to plot based on README
    sweep_configs = [
        {
            "name": "tfe_sweep",
            "title": r"$\mathbf{T_{FE}}$ Sweep — Read Current",
            "dirs": ["t5_fe05", "t5_fe07", "t5_fe10", "t5_fe12"],
            "labels": [
                r"$T_{FE}$ = 5 nm",
                r"$T_{FE}$ = 7 nm",
                r"$T_{FE}$ = 10 nm",
                r"$T_{FE}$ = 12 nm",
            ],
        },
        {
            "name": "tox_sweep",
            "title": r"$\mathbf{T_{OX}}$ Sweep — Read Current",
            "dirs": ["t2_tox05", "t2_tox10", "t2_tox15"],
            "labels": [
                r"$T_{OX}$ = 0.5 nm",
                r"$T_{OX}$ = 1.0 nm",
                r"$T_{OX}$ = 1.5 nm",
            ],
        },
        {
            "name": "tsi_sweep",
            "title": r"$\mathbf{T_{SI}}$ Sweep — Read Current",
            "dirs": ["t3_si05", "t3_si08", "t3_si10", "t3_si12"],
            "labels": [
                r"$T_{SI}$ = 5 nm",
                r"$T_{SI}$ = 8 nm",
                r"$T_{SI}$ = 10 nm",
                r"$T_{SI}$ = 12 nm",
            ],
        },
        {
            "name": "vread_sweep",
            "title": r"$\mathbf{V_{READ}}$ Sweep — Read Current",
            "dirs": ["t1_vr03", "t1_vr07", "t1_vr09", "t1_vr11", "t1_vr13"],
            "labels": [
                r"$V_{READ}$ = −0.3V",
                r"$V_{READ}$ = −0.7V",
                r"$V_{READ}$ = −0.9V",
                r"$V_{READ}$ = −1.1V",
                r"$V_{READ}$ = −1.3V",
            ],
        },
        {
            "name": "nsub_sweep",
            "title": r"$\mathbf{N_{SUB}}$ Sweep — Read Current",
            "dirs": ["t4_nsub15", "t4_nsub17", "t4_nsub5e17"],
            "labels": [
                r"$N_{SUB}$ = $10^{15}$ cm$^{-3}$",
                r"$N_{SUB}$ = $10^{17}$ cm$^{-3}$",
                r"$N_{SUB}$ = $5\times10^{17}$ cm$^{-3}$",
            ],
        },
        {
            "name": "lscaling",
            "title": "Gate Length Scaling — Read Current",
            "dirs": ["t6_lg50", "t6_lov0"],
            "labels": [
                r"$L_G$ = 50 nm",
                r"$L_{OV}$ = 0 nm",
            ],
        },
    ]

    for cfg in sweep_configs:
        print(f"\n{'='*60}")
        print(f"  Plotting: {cfg['name']}")
        print(f"{'='*60}")

        data_list = []
        for subdir, label in zip(cfg["dirs"], cfg["labels"]):
            csv_dir = CSV_ROOT / subdir

            if not csv_dir.exists():
                print(f"  SKIP: {csv_dir} not found")
                continue

            # Try to find a representative read file
            # Priority: p09_read at sub-coercive V, then baseline_pre
            candidates = sorted(csv_dir.glob("p09_read_*.csv"))
            if not candidates:
                candidates = sorted(csv_dir.glob("baseline_pre_*.csv"))
            if not candidates:
                candidates = sorted(csv_dir.glob("*.csv"))

            if not candidates:
                print(f"  SKIP: no CSVs in {csv_dir}")
                continue

            # Use the first available file
            fpath = candidates[0]
            print(f"  Loading: {fpath.name}")

            df = load_csv(fpath)

            # X-axis: time (s -> ns for readability)
            xcol = "time"
            ycol = find_column(df, DRAIN_CURRENT_COLS) or df.columns[7]

            x = df[xcol].values.astype(float)
            if len(x) > 0:
                x = x - x[0]  # Shift to start at 0
            y = df[ycol].values.astype(float)

            data_list.append((x, y, label))

        if not data_list:
            print(f"  No data found for {cfg['name']}, skipping.")
            continue

        xlim = (0.0, 20.0)
        if args.xlim:
            xlim = tuple(map(float, args.xlim.split(",")))
        elif args.xlim == "":
            xlim = None
        ylim = None
        if args.ylim:
            ylim = tuple(map(float, args.ylim.split(",")))

        outfile = OUT_DIR / f"{cfg['name']}.png"
        plot_curves(
            data_list,
            xlabel=r"$\mathbf{Time}$ $\mathbf{(ns)}$",
            ylabel=r"$\mathbf{I_{DS}}$ $\mathbf{(\mu A)}$",
            title=cfg.get("title", ""),
            y_scale=1e6,   # A -> µA
            x_scale=1e9,   # s -> ns
            outfile=str(outfile),
            show=False,
            legend_ncol=2,
            xlim=xlim,
            ylim=ylim,
        )

    print(f"\nAll plots saved to: {OUT_DIR}")


# ═══════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(
        description="Publication-quality curve plotter for Sentaurus TCAD CSV data.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="cmd")

    # --- files subcommand ---
    pf = sub.add_parser("files", help="Plot specific CSV files")
    pf.add_argument("files", nargs="+", help="CSV file paths")
    pf.add_argument("--labels", nargs="*", default=[], help="Legend labels (one per file)")
    pf.set_defaults(func=cmd_files)

    # --- dir subcommand ---
    pd_ = sub.add_parser("dir", help="Plot all matching CSVs in a directory")
    pd_.add_argument("dir", help="Directory containing CSVs")
    pd_.add_argument("--pattern", default="*.csv", help="Glob pattern (default: *.csv)")
    pd_.set_defaults(func=cmd_dir)

    # --- auto subcommand ---
    pa = sub.add_parser("auto", help="Auto-discover and plot all sweep figures")
    pa.set_defaults(func=cmd_auto)

    # Common options for all subcommands
    for p in [pf, pd_, pa]:
        p.add_argument("--xcol", default=None, help="X-axis column name")
        p.add_argument("--ycol", default=None, help="Y-axis column name")
        p.add_argument("--xlabel", default=r"$\mathbf{V_{DS}}$ $\mathbf{(V)}$",
                       help="X-axis label")
        p.add_argument("--ylabel", default=r"$\mathbf{I_{DS}}$ $\mathbf{(\mu A)}$",
                       help="Y-axis label")
        p.add_argument("--title", default="", help="Plot title")
        p.add_argument("--yscale", default="1e6", help="Y-axis multiplier (default: 1e6 for A->µA)")
        p.add_argument("--xscale", default="1.0", help="X-axis multiplier")
        p.add_argument("-o", "--output", default=None, help="Output file path (PNG/PDF/SVG)")
        p.add_argument("--no-show", action="store_true", help="Don't show interactive window")
        p.add_argument("--legend-ncol", type=int, default=2, help="Legend columns (default: 2)")
        p.add_argument("--xlim", default=None, help="X-axis limits as min,max (e.g. 0,20)")
        p.add_argument("--ylim", default=None, help="Y-axis limits as min,max")

    args = parser.parse_args()
    if not args.cmd:
        parser.print_help()
        sys.exit(1)
    args.func(args)


if __name__ == "__main__":
    main()
