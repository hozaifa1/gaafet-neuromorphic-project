"""Convert Sentaurus DF-ISE ".plt" current-plot files into tidy CSVs.

The .plt format (text):
  DF-ISE text
  Info { ... datasets = [ "name1" "name2" ... ] ... }
  Data { <whitespace-separated floats, row-major, N per row> }

Column names are read from the header (never hardcoded) because probe names
embed geometry-dependent coordinates, e.g. "Pos(0,0.0145) ElectricField/y".
The Data block may be empty -> returns an empty DataFrame with the right columns.

CLI:
  python plt2csv.py file <path.plt> [-o out.csv]
  python plt2csv.py dir <input_dir> <output_dir>
  python plt2csv.py --selftest
"""
import argparse
import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd


def _extract_block(text, keyword):
    """Return the substring inside the first `keyword { ... }` block (brace-matched)."""
    start = text.find(keyword)
    if start == -1:
        raise ValueError(f"missing '{keyword}' block")
    open_brace = text.find("{", start)
    if open_brace == -1:
        raise ValueError(f"'{keyword}' has no opening brace")
    depth = 0
    for i in range(open_brace, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[open_brace + 1 : i]
    raise ValueError(f"'{keyword}' block not closed")


def _parse_dataset_names(info_block):
    """Pull the quoted names out of `datasets = [ ... ]`."""
    m = re.search(r"datasets\s*=\s*\[(.*?)\]", info_block, re.DOTALL)
    if not m:
        raise ValueError("no 'datasets = [ ... ]' in Info block")
    return re.findall(r'"([^"]*)"', m.group(1))


def parse_plt(path):
    """Parse one .plt file into a DataFrame (columns = dataset names, in order)."""
    text = Path(path).read_text()
    if "DF-ISE" not in text.splitlines()[0]:
        raise ValueError(f"{path}: not a DF-ISE text file")

    names = _parse_dataset_names(_extract_block(text, "Info"))
    ncols = len(names)
    if ncols == 0:
        raise ValueError(f"{path}: empty datasets list")

    data_block = _extract_block(text, "Data")
    values = np.fromstring(data_block, sep=" ")

    if values.size == 0:
        return pd.DataFrame(columns=names)
    if values.size % ncols != 0:
        raise ValueError(
            f"{path}: {values.size} values not divisible by {ncols} columns"
        )

    df = pd.DataFrame(values.reshape(-1, ncols), columns=names)
    df.index.name = "row"
    return df


def convert_file(src, dst):
    """Parse one .plt and write a CSV; return the DataFrame for summary use."""
    df = parse_plt(src)
    Path(dst).parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(dst, index=False)
    return df


def _summary(name, df):
    print(f"{name}: {len(df)} rows, {df.shape[1]} cols")


def cmd_file(args):
    src = Path(args.path)
    dst = Path(args.out) if args.out else src.with_suffix(".csv")
    df = convert_file(src, dst)
    _summary(dst.name, df)


def cmd_dir(args):
    in_dir, out_dir = Path(args.input_dir), Path(args.output_dir)
    plts = sorted(in_dir.rglob("*.plt"))
    if not plts:
        print(f"no .plt files under {in_dir}")
        return
    for src in plts:
        dst = out_dir / src.relative_to(in_dir).with_suffix(".csv")
        df = convert_file(src, dst)
        _summary(str(src.relative_to(in_dir)), df)


def selftest():
    sample = Path(__file__).with_name("baseline") / "H1sweep_app_outputs" / "p09_read_n5_des.plt"
    df = parse_plt(sample)
    assert df.shape[1] == 29, f"expected 29 cols, got {df.shape[1]}"
    assert 19 <= len(df) <= 23, f"expected ~21 rows, got {len(df)}"
    assert "time" in df.columns, "missing 'time' column"
    assert any(c.endswith("TotalCurrent") for c in df.columns), "no *TotalCurrent column"
    print(f"selftest OK: {df.shape[1]} cols, {len(df)} rows")


def main(argv=None):
    p = argparse.ArgumentParser(description="Convert Sentaurus DF-ISE .plt files to CSV.")
    p.add_argument("--selftest", action="store_true", help="run built-in self-check and exit")
    sub = p.add_subparsers(dest="cmd")

    pf = sub.add_parser("file", help="convert one .plt")
    pf.add_argument("path")
    pf.add_argument("-o", "--out", help="output CSV path (default: same name .csv)")
    pf.set_defaults(func=cmd_file)

    pd_ = sub.add_parser("dir", help="recursively convert a directory of .plt files")
    pd_.add_argument("input_dir")
    pd_.add_argument("output_dir")
    pd_.set_defaults(func=cmd_dir)

    args = p.parse_args(argv)
    if args.selftest:
        selftest()
        return
    if not args.cmd:
        p.print_help()
        sys.exit(1)
    args.func(args)


if __name__ == "__main__":
    main()
