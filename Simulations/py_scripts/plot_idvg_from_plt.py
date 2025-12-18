from __future__ import annotations

import argparse
from pathlib import Path
import re

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402


def parse_dfise_plt(path: Path) -> pd.DataFrame:
    """
    Parse a DF-ISE text .plt file into a DataFrame.

    Returns columns with the exact dataset names in the file.
    """
    text = path.read_text()
    m_ds = re.search(r"datasets\s*=\s*\[(.*?)\]", text, re.S)
    if not m_ds:
        raise ValueError(f"datasets block not found in {path}")
    dataset_block = m_ds.group(1)
    names = re.findall(r"\"([^\"]+)\"", dataset_block)
    if not names:
        raise ValueError(f"no dataset names found in {path}")

    m_data = re.search(r"Data\s*{(.*?)}", text, re.S)
    if not m_data:
        raise ValueError(f"Data block not found in {path}")

    tokens = m_data.group(1).split()
    values = np.array([float(tok) for tok in tokens], dtype=float)
    n_cols = len(names)
    if values.size % n_cols != 0:
        raise ValueError(
            f"value count {values.size} not divisible by column count {n_cols} for {path}"
        )
    data = values.reshape((-1, n_cols))
    return pd.DataFrame(data, columns=names)


def plot_curve(df: pd.DataFrame, x: str, y: str, out_path: Path, ylog: bool = False) -> None:
    if x not in df.columns:
        raise KeyError(f"x column '{x}' not found in datasets: {list(df.columns)}")
    if y not in df.columns:
        raise KeyError(f"y column '{y}' not found in datasets: {list(df.columns)}")

    fig, ax = plt.subplots(figsize=(6, 4))
    
    # Sort by x to avoid messy lines if time steps aren't monotonic in x (e.g. hysteresis loop)
    # But for hysteresis loops (forward and backward), sorting might break the loop visualization.
    # Usually we just plot as is.
    ax.plot(df[x], df[y], label=f"{y} vs {x}", linewidth=1.4)
    
    if ylog:
        ax.set_yscale("log")
        # Handle negative values if present (though current magnitude is usually what we care about in log)
        # Often absolute value is plotted for log I_d
        df[y] = df[y].abs()
        ax.clear() # Re-plot with abs values
        ax.plot(df[x], df[y], label=f"|{y}| vs {x}", linewidth=1.4)
        ax.set_yscale("log")

    ax.set_xlabel(x)
    ax.set_ylabel(y)
    ax.grid(True, which="both", linestyle="--", alpha=0.4)
    ax.legend()
    fig.tight_layout()

    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=300)
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Plot curves from DF-ISE .plt files produced by Sentaurus Device."
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("../n2_des.plt"),
        help="Path to the .plt file (default: ../n2_des.plt)",
    )
    parser.add_argument(
        "--x",
        default="gate_contact OuterVoltage",
        help="Dataset name for x-axis (default: gate_contact OuterVoltage)",
    )
    parser.add_argument(
        "--y",
        default="drain_contact TotalCurrent",
        help="Dataset name for y-axis (default: drain_contact TotalCurrent)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("../output_curves/n2_des_Id_vs_Vg.png"),
        help="Output image path (default: ../output_curves/n2_des_Id_vs_Vg.png)",
    )
    parser.add_argument(
        "--ylog",
        action="store_true",
        default=True,
        help="Use logarithmic scale for Y axis (default: True)",
    )
    args = parser.parse_args()

    df = parse_dfise_plt(args.input)
    plot_curve(df, args.x, args.y, args.output, args.ylog)
    print(f"Saved plot to {args.output}")


if __name__ == "__main__":
    main()
