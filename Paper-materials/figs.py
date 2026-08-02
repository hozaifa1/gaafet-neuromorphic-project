"""The one figure generator for the GAA-FeFET paper.

    python figs.py --list                 what exists, and whether it is drawn
    python figs.py --fig D2               draw one figure
    python figs.py --all                  draw every registered figure
    python figs.py --panel 4              compose one main-text panel
    python figs.py --panels               compose all ten main-text panels
    python figs.py --manifest             (re)write figures_manifest.csv
    python figs.py --lint                 refuse hardcoded numbers in annotations

WHY THIS FILE EXISTS
--------------------
Before it, 57 images lived in four folders and were drawn by six scripts.  Four
of them were silently showing pre-correction data (1.578x too large) and a fifth
was plotting a settling transient and calling it retention.  Nothing checked
that a figure still matched the data it claimed to show.

So the rules are enforced here, not remembered:

1. A figure function returns ``(fig, DataFrame)``.  The DataFrame is *exactly*
   what was plotted, and it is written next to the image.  A figure that cannot
   hand back its own numbers does not get saved.
2. Every current scaling comes from ``Device_Optimization/norm.py``.  No figure
   module may define a width, an Areafactor or a scale factor.  ``--lint``
   enforces this.
3. No figure may print a number it did not compute from the data on screen.
   Annotations must be f-strings built from the plotted arrays.  ``--lint``
   flags string literals containing digits inside text()/annotate() calls.
4. Every figure declares the claim it supports.  ``--manifest`` turns those
   declarations into ``figures_manifest.csv``.

Figure functions live in ``figlib/`` (one module per chapter) so that the file
stays under a readable length; ``figs.py`` is still the only entry point, the
only style block and the only registry.
"""
from __future__ import annotations

import argparse
import importlib
import pkgutil
import re
import sys
import traceback
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

import pandas as pd

# --- paths ---------------------------------------------------------------
HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
DEVOPT = ROOT / "Device_Optimization"
RAW = DEVOPT / "csv_export" / "raw"
SWEEPS = DEVOPT / "csv_export" / "sweeps"
OUTPUTS = DEVOPT / "outputs"
CALCSV = ROOT / "Calibration" / "csvs"
AUTOCAL = ROOT / "Calibration" / "autocal"
PLANAR = ROOT / "Planar_Device_Work"
SNNFIG = ROOT / "PYTHON_Modelling_Fefet_Codes" / "ecg detection"
OUTDIR = HERE / "figures"
PANELDIR = HERE / "panels"

sys.path.insert(0, str(DEVOPT))
sys.path.insert(0, str(ROOT / "PYTHON_Modelling_Fefet_Codes" / "Combined Figures"))

import norm                                        # noqa: E402  the one width convention
from plt2csv import parse_plt                      # noqa: E402
import figstyle                                    # noqa: E402  the supervisor's style rules
from figstyle import new_ax, bold_labels           # noqa: E402,F401  re-exported to figlib

import matplotlib                                  # noqa: E402
matplotlib.use("Agg")
import matplotlib.pyplot as plt                    # noqa: E402
from matplotlib import rcParams                    # noqa: E402

# figstyle targets screen dpi; the paper wants 600 and a vector twin.
rcParams["savefig.dpi"] = 600
rcParams["pdf.fonttype"] = 42        # editable text in the vector PDF, not outlines
rcParams["ps.fonttype"] = 42

DPI = 600


# --- registry ------------------------------------------------------------
@dataclass
class Fig:
    fid: str
    fn: Callable
    claim: str
    source: str
    convention: str
    module: str = field(default="")

    @property
    def func_path(self) -> str:
        return f"{self.module}.{self.fn.__name__}"


REGISTRY: dict[str, Fig] = {}

# Main-text panel composition.  PLOT_PLAN 5.1, with panel 9 changed from
# H1+H4+H5 to H1+H4+H8: H5 is endurance and the Preisach model carries no
# fatigue term, so more cycling cannot produce an endurance result.  H8 (read
# disturb, 0.0000 % over 9.9e5 equivalent reads) is evidence about the device.
PANELS: dict[int, tuple[str, list[str], tuple[int, int]]] = {
    1: ("Structure and 2D-to-nanosheet mapping", ["A1", "A5"], (1, 2)),
    2: ("Calibration against Liao 2022", ["B1", "B3", "B5"], (1, 3)),
    3: ("Ferroelectric material and electrostatics", ["C1", "C2"], (1, 2)),
    4: ("DC device characteristics", ["D1", "D2"], (1, 2)),
    5: ("Synaptic behaviour", ["F1", "F2", "F5"], (1, 3)),
    6: ("Write transients and energy", ["E1", "E2", "E6"], (1, 3)),
    7: ("LIF neuron operation", ["G1", "G2", "G3"], (1, 3)),
    8: ("Design space", ["I1", "I2", "I3", "I5"], (2, 2)),
    9: ("Retention and reliability", ["H1", "H4", "H8"], (1, 3)),
    10: ("Comparison and benchmark", ["J1", "J5"], (1, 2)),
}


def figure(fid: str, *, claim: str, source: str, convention: str = "norm.to_uA_per_um (W_eff = 90 nm)"):
    """Register a figure function.

    claim       the sentence in the paper this figure is evidence for
    source      the .plt node or CSV the numbers came from
    convention  which normalization was applied, or 'ratio only' / 'voltage only'
    """
    def deco(fn: Callable) -> Callable:
        if fid in REGISTRY:
            raise RuntimeError(f"figure {fid} registered twice -- that is how the last set drifted")
        REGISTRY[fid] = Fig(fid, fn, claim, source, convention, module=fn.__module__)
        return fn
    return deco


def _load_figlib() -> None:
    """Import every module in figlib/ so its decorators run."""
    # Run as a script this file is __main__; figlib imports it as `figs`, which
    # would give the decorators a second, empty REGISTRY.  Alias it first.
    sys.modules.setdefault("figs", sys.modules[__name__])
    sys.path.insert(0, str(HERE))
    import figlib
    for m in pkgutil.iter_modules(figlib.__path__):
        importlib.import_module(f"figlib.{m.name}")


# --- drawing -------------------------------------------------------------
def draw(fid: str) -> tuple[Path, int]:
    """Run one figure function and write PNG + PDF + CSV.  Returns (png, n_rows)."""
    if fid not in REGISTRY:
        raise KeyError(f"no such figure: {fid}.  --list shows what is registered.")
    spec = REGISTRY[fid]
    OUTDIR.mkdir(parents=True, exist_ok=True)

    result = spec.fn()
    if not (isinstance(result, tuple) and len(result) == 2):
        raise TypeError(f"{fid}: a figure function must return (fig, DataFrame), got {type(result)}")
    fig, df = result
    if not isinstance(df, pd.DataFrame):
        raise TypeError(f"{fid}: second return value must be a DataFrame of the plotted numbers")
    if df.empty:
        raise ValueError(f"{fid}: returned an empty DataFrame -- a figure must hand back its own numbers")

    png = OUTDIR / f"{fid}.png"
    pdf = OUTDIR / f"{fid}.pdf"
    csv = OUTDIR / f"{fid}.csv"
    fig.savefig(png, dpi=DPI, bbox_inches="tight", pad_inches=0.3)
    fig.savefig(pdf, bbox_inches="tight", pad_inches=0.3)
    plt.close(fig)
    df.to_csv(csv, index=False)
    return png, len(df)


def compose_panel(n: int) -> Path:
    """Lay the panel's figures out as one image, lettered (a), (b), ...

    Composed from the 600 dpi PNGs rather than re-drawing into shared axes:
    IEEE accepts 600 dpi raster for line art, each sub-figure keeps its own
    vector PDF for the supplementary set, and no figure gets a second code path
    that could drift from the first.
    """
    title, fids, (nrow, ncol) = PANELS[n]
    PANELDIR.mkdir(parents=True, exist_ok=True)
    missing = [f for f in fids if not (OUTDIR / f"{f}.png").exists()]
    if missing:
        raise FileNotFoundError(f"panel {n} needs {missing}; draw them first")

    imgs = [plt.imread(OUTDIR / f"{f}.png") for f in fids]
    # normalize every sub-figure to the same displayed height
    heights = [im.shape[0] for im in imgs]
    widths = [im.shape[1] * min(heights) / im.shape[0] for im in imgs]
    cell_w = max(widths) / min(heights)          # aspect of the widest cell

    fig, axes = plt.subplots(nrow, ncol, figsize=(5.0 * cell_w * ncol, 5.0 * nrow))
    axes = [axes] if nrow * ncol == 1 else list(axes.ravel())
    for ax, im, fid, letter in zip(axes, imgs, fids, "abcdefgh"):
        ax.imshow(im)
        ax.set_axis_off()
        ax.text(-0.02, 1.02, f"({letter})", transform=ax.transAxes,
                fontsize=26, fontweight="bold", ha="right", va="bottom")
    for ax in axes[len(imgs):]:
        ax.set_axis_off()
    fig.subplots_adjust(wspace=0.02, hspace=0.02, left=0.02, right=0.99, top=0.97, bottom=0.01)

    out = PANELDIR / f"panel{n:02d}.png"
    fig.savefig(out, dpi=DPI, bbox_inches="tight", pad_inches=0.15)
    fig.savefig(out.with_suffix(".pdf"), bbox_inches="tight", pad_inches=0.15)
    plt.close(fig)
    return out


# Figures produced by the network pipeline rather than by this generator.  They
# are listed so the manifest covers every figure in the paper; they are NOT
# re-implemented here, because two scripts drawing the same figure is how the
# last set drifted.  Their PNG and reproducing CSV live beside them at the
# source path and are copied into figures/ unchanged.
EXTERNAL: dict[str, tuple[str, str, str]] = {
    "K2": ("PYTHON_Modelling_Fefet_Codes/ecg detection/fig_k2_levels.py",
           "Deployed accuracy depends on where the conductance levels sit, not on how "
           "many there are: at 8 levels four placements span 0.336-0.491 while even "
           "spacing gives 0.804.",
           "normalized by g_max -- a global current scale cancels exactly"),
    "K3a": ("PYTHON_Modelling_Fefet_Codes/ecg detection/fig_k3_variability.py d2d",
            "Per-device calibration is not optional: median accuracy over the 20 corner "
            "devices is 0.243 with none, 0.777 with a gain trim, 0.830 with full "
            "write-verify.",
            "normalized by each device's own g_max"),
    "K3b": ("PYTHON_Modelling_Fefet_Codes/ecg detection/fig_k3_variability.py c2c",
            "At the measured cycle-to-cycle sigma the 15-level deployment loses 0.001 "
            "accuracy; quantizing to the 8 separable levels instead costs 0.036.",
            "noise injected per conductance branch, not per weight"),
    "K3c": ("PYTHON_Modelling_Fefet_Codes/ecg detection/fig_k3_variability.py ladder",
            "What predicts accuracy after a gain trim is worst-level misplacement "
            "(Spearman -0.85), not any readout-overlap statistic.",
            "log-conductance residuals -- dimensionless"),
    "K4": ("PYTHON_Modelling_Fefet_Codes/ecg detection/fig_k4_energy.py",
           "The core costs 535.8 pJ/beat and the whole array is written once for "
           "69.6 pJ, but the assumed ADC term is 183 nJ/beat -- 342x the core.",
           "energies via norm.to_device_amps; ADC assumes 1 pJ/conversion"),
}


# --- manifest ------------------------------------------------------------
def write_manifest() -> Path:
    panel_of = {f: n for n, (_, fids, _) in PANELS.items() for f in fids}
    rows = []
    for fid, (script, claim, conv) in EXTERNAL.items():
        rows.append({
            "figure_id": fid,
            "main_text_panel": "standalone",
            "source_data": script,
            "draw_function": "external -- not drawn by figs.py",
            "claim_supported": claim,
            "normalization": conv,
            "png": f"figures/{fid}_*.png" if list(OUTDIR.glob(f"{fid}_*.png"))
                   else "NOT COPIED",
        })
    for fid in sorted(REGISTRY):
        s = REGISTRY[fid]
        rows.append({
            "figure_id": fid,
            "main_text_panel": panel_of.get(fid, ""),
            "source_data": s.source,
            "draw_function": s.func_path,
            "claim_supported": s.claim,
            "normalization": s.convention,
            "png": f"figures/{fid}.png" if (OUTDIR / f"{fid}.png").exists() else "NOT DRAWN",
        })
    out = HERE / "figures_manifest.csv"
    pd.DataFrame(rows).to_csv(out, index=False)
    return out


# --- lint ----------------------------------------------------------------
_TEXTCALL = re.compile(r"\.(?:text|annotate|set_title|set_xlabel|set_ylabel)\s*\(")
_BADSTR = re.compile(r"""(?<![f])(['"])((?:[^'"\\]|\\.)*?\d(?:[^'"\\]|\\.)*?)\1""")
_WIDTH = re.compile(r"\b(0\.071|0\.045|0\.090|W_EFF|AREAFACTOR|1\.5778|0\.6338)\b")
# digits that are legitimately part of a label rather than a measured value
_ALLOWED = re.compile(r"^[^0-9]*(?:10|2|3|4)?[^0-9]*$|C/cm|A/µm|µA/µm|mV/dec|"
                      r"log₁₀|10\^|\{-?\d\}|\$|^\(?[a-h]\)?$|nm|V_?G|V_?DS|V_?read")


def lint() -> int:
    """Flag the two failure modes that actually happened in this project."""
    bad = 0
    for path in sorted((HERE / "figlib").glob("*.py")):
        src = path.read_text(encoding="utf-8")
        for i, line in enumerate(src.splitlines(), 1):
            if _WIDTH.search(line) and "norm." not in line and not line.lstrip().startswith("#"):
                print(f"{path.name}:{i}: hardcoded width/scale -- import it from norm.py\n    {line.strip()}")
                bad += 1
            if _TEXTCALL.search(line):
                for _, lit in _BADSTR.findall(line):
                    if _ALLOWED.search(lit):
                        continue
                    print(f"{path.name}:{i}: literal number in an annotation -- "
                          f"compute it from the plotted data\n    {line.strip()}")
                    bad += 1
    print("lint: clean" if not bad else f"lint: {bad} problem(s)")
    return bad


# --- cli -----------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--fig", nargs="+", metavar="ID")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--panel", type=int, nargs="+")
    ap.add_argument("--panels", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--manifest", action="store_true")
    ap.add_argument("--lint", action="store_true")
    a = ap.parse_args()

    _load_figlib()

    if a.lint:
        return 1 if lint() else 0

    if a.list:
        panel_of = {f: n for n, (_, fids, _) in PANELS.items() for f in fids}
        want = sorted({f for _, fids, _ in PANELS.values() for f in fids})
        for fid in sorted(set(REGISTRY) | set(want)):
            state = "ok  " if (OUTDIR / f"{fid}.png").exists() else (
                "todo" if fid in REGISTRY else "MISS")
            p = f"panel {panel_of[fid]}" if fid in panel_of else "-"
            claim = REGISTRY[fid].claim if fid in REGISTRY else "not registered"
            print(f"  [{state}] {fid:4s} {p:8s} {claim[:78]}")
        return 0

    failed = []
    if a.fig or a.all:
        ids = sorted(REGISTRY) if a.all else a.fig
        for fid in ids:
            try:
                png, n = draw(fid)
                print(f"  [ok]   {fid:4s} -> {png.name}  ({n} rows)")
            except Exception as exc:
                failed.append(fid)
                print(f"  [FAIL] {fid:4s} {type(exc).__name__}: {exc}")
                if not a.all:
                    traceback.print_exc()

    if a.panel or a.panels:
        for n in (sorted(PANELS) if a.panels else a.panel):
            try:
                print(f"  [ok]   panel {n} -> {compose_panel(n).name}")
            except Exception as exc:
                failed.append(f"panel{n}")
                print(f"  [FAIL] panel {n}: {exc}")

    if a.manifest or a.all:
        print(f"  manifest -> {write_manifest().name}")

    if failed:
        print(f"\n{len(failed)} failed: {' '.join(failed)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
