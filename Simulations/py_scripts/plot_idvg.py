import argparse
from pathlib import Path
from typing import Tuple

import matplotlib.pyplot as plt
import numpy as np


SAMPLES_PER_STEP = 25  # time + 3 contacts * 8 quantities


def parse_plt_file(path: Path) -> Tuple[np.ndarray, np.ndarray]:
    """Return VGS and Id arrays extracted from a Sentaurus DF-ISE PLT file."""
    values = []
    records = []
    data_started = False

    with path.open("r", errors="ignore") as handle:
        for raw_line in handle:
            line = raw_line.strip()

            if not data_started:
                if line.startswith("Data"):
                    data_started = True
                continue

            if not line:
                continue

            if line.startswith("}"):
                break

            for token in line.split():
                try:
                    values.append(float(token))
                except ValueError:
                    continue

            while len(values) >= SAMPLES_PER_STEP:
                records.append(values[:SAMPLES_PER_STEP])
                values = values[SAMPLES_PER_STEP:]

    if not records:
        raise ValueError(f"No data records found in {path}")

    data = np.array(records)
    gate_voltage = data[:, 17]
    source_voltage = data[:, 9]
    drain_current = np.abs(data[:, 7])

    vgs = gate_voltage - source_voltage
    return vgs, drain_current


def plot_idvg(vgs: np.ndarray,
              ids: np.ndarray,
              output_path: Path,
              title: str) -> None:
    """Generate Id–VSG plots, clamping to [-0.5, 0] VSG."""
    vsg = -vgs  # Convert NMOS convention (VGS = -VSG)
    mask = (-0.5 <= vsg) & (vsg <= 0.0)
    if not mask.any():
        raise ValueError("No samples within VSG window [-0.5, 0] V.")

    vsg_roi = vsg[mask]
    ids_roi = ids[mask]
    order = np.argsort(vsg_roi)
    vsg_sorted = vsg_roi[order]
    ids_sorted = ids_roi[order]

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.plot(vsg_sorted, ids_sorted, marker="o", color="#1f77b4")
    ax.set_xlabel(r"$V_{SG}$ (V)")
    ax.set_ylabel(r"$|I_D|$ (A)")
    ax.set_title(title)
    ax.grid(True, alpha=0.3)
    fig.tight_layout()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=200, bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Plot Id–VSG characteristics from a Sentaurus PLT file.")
    parser.add_argument("plt_file", type=Path, help="Path to PLT file")
    parser.add_argument(
        "--output",
        type=Path,
        help="Output image path (default: output_curves/<plt_name>_idvg.png)")
    args = parser.parse_args()

    vgs, ids = parse_plt_file(args.plt_file)

    output = args.output
    if output is None:
        output = (Path("..") / "output_curves" /
                  f"{args.plt_file.stem}_idvg.png").resolve()

    title = f"Id–VSG from {args.plt_file.name}"
    plot_idvg(vgs, ids, output, title)
    print(f"Saved plot to {output}")


if __name__ == "__main__":
    main()
