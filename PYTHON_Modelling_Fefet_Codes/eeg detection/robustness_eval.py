"""
Stage-2 hardware-aware robustness (the IEEE-TED credibility layer).
===================================================================
Loads a full-precision-trained LSNN checkpoint, deploys it on the FeFET synapse by
post-training quantization to the measured levels, and re-evaluates under on-chip-realistic
non-idealities, reporting the full metric set and the drop vs the nominal 300 K device.

Conditions
  full_precision : as trained (upper bound)
  nominal_300K   : weights snapped to the measured 300 K 15-level differential set (the device)
  T=250K / T=350K: snapped to the MEASURED temperature level sets
                   (Device_Optimization/csv_export/raw/ltp_vs_temperature.csv)   <- real data
  D2D sigma      : frozen per-weight log-normal conductance variation
  C2C sigma      : resampled (per-eval) log-normal read noise
  retention      : multiplicative conductance drift

Run (after training):
    python robustness_eval.py --ckpt REDESIGN/runs/paper/paper_best.ckpt
"""
import torch                       # MUST precede numpy/pandas (Windows c10.dll init)
import os
import sys
import json
import argparse
import numpy as np

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "REDESIGN", "code"))

import redesign_stage1 as rs
import post_quantize as pq
from fefet_device import measured_levels, measured_levels_at_temperature
from fefet_synapse import log_levels
from metrics import ecg_report, format_report


def achievable_from_levels(lv, g_max):
    ln = (lv / g_max).numpy()
    vals = sorted({round(float(a - b), 12) for a in ln for b in ln})
    return torch.tensor(vals, dtype=torch.float32)


def load_fp_state(ckpt, device):
    m = pq.build_orig(device)
    st = torch.load(ckpt, map_location=device, weights_only=False)
    m.load_state_dict(st["net"])
    return m, {k: v.clone() for k, v in m.state_dict().items()}


def quantize_with_noise(model, fp_state, achievable, d2d=0.0, c2c=0.0, retention=1.0, seed=0):
    """Restore FP weights, snap to `achievable`, then apply conductance-referred noise/drift."""
    model.load_state_dict(fp_state)
    edges = (achievable[:-1] + achievable[1:]) / 2.0
    gen = torch.Generator().manual_seed(seed)
    with torch.no_grad():
        for name, p in model.named_parameters():
            if not name.endswith("weight"):
                continue
            s = p.abs().max().clamp(min=1e-8)
            wn = (p / s).flatten()
            idx = torch.bucketize(wn, edges).clamp(0, achievable.numel() - 1)
            wq = achievable[idx].reshape(p.shape)
            wq = wq * retention
            if d2d > 0:
                wq = wq * torch.exp(d2d * torch.randn(wq.shape, generator=gen))
            if c2c > 0:
                wq = wq * torch.exp(c2c * torch.randn(wq.shape))
            p.copy_(wq * s)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ckpt", required=True)
    ap.add_argument("--d2d", type=float, default=0.10, help="D2D log-normal sigma (representative)")
    ap.add_argument("--c2c", type=float, default=0.10, help="C2C log-normal sigma (representative)")
    ap.add_argument("--readout", default="meancue")
    ap.add_argument("--data", choices=["intra", "interpatient", "intra2lead", "inter2lead"], default="intra")
    ap.add_argument("--num_in", type=int, default=0)
    ap.add_argument("--tag", default="robust")
    args = ap.parse_args()

    pq.ARCH["num_in"] = args.num_in if args.num_in > 0 else (5 if "2lead" in args.data else 3)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    torch.manual_seed(100)
    test_loader = pq.build_test_loader(device, args.data)
    k = pq.ARCH["out_cue"]
    model, fp_state = load_fp_state(args.ckpt, device)
    print(f"[robust] loaded {args.ckpt}")

    lv300, _, gmax300 = measured_levels()
    lv250, _, gmax250 = measured_levels_at_temperature("G_250K_uA_um")
    lv350, _, gmax350 = measured_levels_at_temperature("G_350K_uA_um")
    a300 = achievable_from_levels(lv300, gmax300)
    a250 = achievable_from_levels(lv250, gmax250)
    a350 = achievable_from_levels(lv350, gmax350)

    def ev():
        return rs.evaluate(model, test_loader, device, quant=False, rmode=args.readout, k=k)

    results = {}
    # full precision
    model.load_state_dict(fp_state)
    results["full_precision"] = ev()
    # device conditions
    conds = [
        ("nominal_300K", lambda: quantize_with_noise(model, fp_state, a300)),
        ("T=250K",       lambda: quantize_with_noise(model, fp_state, a250)),
        ("T=350K",       lambda: quantize_with_noise(model, fp_state, a350)),
        (f"D2D_s{args.d2d}", lambda: quantize_with_noise(model, fp_state, a300, d2d=args.d2d)),
        (f"C2C_s{args.c2c}", lambda: quantize_with_noise(model, fp_state, a300, c2c=args.c2c)),
        ("D2D+C2C",      lambda: quantize_with_noise(model, fp_state, a300, d2d=args.d2d, c2c=args.c2c)),
        ("retention_-10pct", lambda: quantize_with_noise(model, fp_state, a300, retention=0.90)),
    ]
    for name, setup in conds:
        setup()
        results[name] = ev()

    base = results["nominal_300K"]["macro_f1"]
    print("\n=== hardware-aware robustness (macro-F1 / accuracy / kappa) ===")
    for name, rep in results.items():
        d = rep["macro_f1"] - base
        print(f"  {name:18s}  F1={rep['macro_f1']:.4f}  acc={rep['accuracy']:.4f}  "
              f"k={rep['kappa']:.4f}  (dF1 vs device {d:+.4f})")
    out = os.path.join(_HERE, "REDESIGN", "runs", f"{args.tag}.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    json.dump(results, open(out, "w"), indent=2)
    print(f"\n[robust] wrote {out}")


if __name__ == "__main__":
    main()
