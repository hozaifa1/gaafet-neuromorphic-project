"""
FeFET post-training quantization (the device result).
======================================================
Takes a full-precision-trained LSNN checkpoint and snaps every synaptic weight onto a
DIFFERENTIAL FeFET conductance set built from the 15 MEASURED LTP polarization-switching
levels: achievable weight = (G_i - G_j)/g_max for level pairs (i,j). Per-layer scaling
(an analog readout gain) maps the trained weight range onto [-1,1]. Reports full-precision
vs on-device metrics and the faithfulness gap. `--levels 2` = binary-synapse ablation (G6).

Run (after a training run has saved a checkpoint):
    python post_quantize.py --ckpt REDESIGN/runs/orig_v2/orig_v2_best.ckpt
"""
import torch                       # MUST precede numpy/pandas (Windows c10.dll init)
import os
import sys
import argparse
import numpy as np

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "REDESIGN", "code"))

import torch.utils.data as data
import redesign_stage1 as rs
from model import VO2LSNN
from dataset import DeltaTransformedECG
from fefet_device import measured_levels
from fefet_synapse import log_levels
from metrics import ecg_report, format_report

ARCH = dict(num_in=3, num_lif=100, num_alif=60, num_out=4, max_delay=10,
            dt=5.556e-4, tau_lp=11.11e-3, out_cue=116, batch_size=128)


def build_orig(device):
    a = ARCH
    return VO2LSNN(
        num_in=a["num_in"], num_lif=a["num_lif"], num_alif=a["num_alif"], num_out=a["num_out"],
        tau=11.11e-3, tau_lp=a["tau_lp"], Rh=5250., Rs=2580., Ra=100e3, Cmem=1.419e-6, Ca=5556e-9,
        v_threshold=3.6, v_reset=1.5, vtn=0.745, vtp=0.973, kappa_n=29e-6, kappa_p=18e-6,
        wl_ratio_n=16, wl_ratio_p=8, Vdd=5.0, input_scaling=9900e-6, dt=a["dt"],
        max_delay=a["max_delay"], refractory=5, device=device).to(device)


_NPZ = {"interpatient": "interpatient_data.npz",
        "intra2lead": os.path.join("ALLDEVICE", "intra_2lead.npz"),
        "inter2lead": os.path.join("ALLDEVICE", "inter_2lead.npz")}


def build_test_loader(device, data_kind="intra"):
    if data_kind in _NPZ:
        npz = np.load(os.path.join(_HERE, _NPZ[data_kind]))
        test_ds = data.TensorDataset(torch.from_numpy(npz["X_test"]).float(),
                                     torch.from_numpy(npz["y_test"]).long())
        return data.DataLoader(test_ds, batch_size=ARCH["batch_size"], shuffle=False, drop_last=False)
    ds = DeltaTransformedECG(path=os.path.join(_HERE, "data_ecg"),
                             output_cue_length=ARCH["out_cue"], n_class=4)
    _, test_ds = data.random_split(ds, [1664, 336],
                                   generator=torch.Generator().manual_seed(100))
    return data.DataLoader(test_ds, batch_size=ARCH["batch_size"], shuffle=False, drop_last=False)


def achievable_diff_values(n_levels):
    """Sorted set of achievable normalized differential weights (G_i-G_j)/g_max."""
    lv, g_min, g_max = measured_levels()
    if n_levels != lv.numel():
        lv = log_levels(g_min, g_max, n_levels)          # ablation: coarser measured-span grid
    ln = (lv / g_max).numpy()
    vals = sorted({round(float(a - b), 12) for a in ln for b in ln})
    return torch.tensor(vals, dtype=torch.float32)


def quantize_(model, achievable):
    """In-place: snap each *.weight to the nearest achievable differential value, per-layer scaled."""
    edges = (achievable[:-1] + achievable[1:]) / 2.0
    with torch.no_grad():
        for name, p in model.named_parameters():
            if not name.endswith("weight"):
                continue
            s = p.abs().max().clamp(min=1e-8)
            wn = (p / s).flatten()
            idx = torch.bucketize(wn, edges).clamp(0, achievable.numel() - 1)
            p.copy_((achievable[idx].reshape(p.shape)) * s)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ckpt", required=True)
    ap.add_argument("--levels", type=int, default=15, help="FeFET levels (2 = binary ablation)")
    ap.add_argument("--readout", default="meancue")
    ap.add_argument("--data", choices=["intra", "interpatient", "intra2lead", "inter2lead"], default="intra")
    ap.add_argument("--num_in", type=int, default=0, help="input channels (0=auto: 5 for 2-lead, else 3)")
    args = ap.parse_args()

    ARCH["num_in"] = args.num_in if args.num_in > 0 else (5 if "2lead" in args.data else 3)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    torch.manual_seed(100)
    test_loader = build_test_loader(device, args.data)

    model = build_orig(device)
    state = torch.load(args.ckpt, map_location=device, weights_only=False)
    model.load_state_dict(state["net"])
    print(f"[post-quant] loaded {args.ckpt} (epoch {state.get('epoch','?')})")

    # 1) full-precision (as trained)
    rep_fp = rs.evaluate(model, test_loader, device, quant=False, rmode=args.readout, k=ARCH["out_cue"])
    print("\n[full-precision]\n  " + format_report(rep_fp).replace("\n", "\n  "))

    # 2) on-device: weights snapped to measured FeFET differential levels
    ach = achievable_diff_values(args.levels)
    print(f"\n[device] {args.levels}-level differential set: {ach.numel()} achievable weights "
          f"in [{ach.min():.3f}, {ach.max():.3f}]")
    quantize_(model, ach)
    rep_dev = rs.evaluate(model, test_loader, device, quant=False, rmode=args.readout, k=ARCH["out_cue"])
    print("[on-device FeFET]\n  " + format_report(rep_dev).replace("\n", "\n  "))

    print(f"\n=== device faithfulness ({args.levels}-level) ===")
    print(f"  accuracy  FP {rep_fp['accuracy']:.4f} -> device {rep_dev['accuracy']:.4f} "
          f"(drop {rep_fp['accuracy']-rep_dev['accuracy']:+.4f})")
    print(f"  macro-F1  FP {rep_fp['macro_f1']:.4f} -> device {rep_dev['macro_f1']:.4f} "
          f"(drop {rep_fp['macro_f1']-rep_dev['macro_f1']:+.4f})")
    print(f"  kappa     FP {rep_fp['kappa']:.4f} -> device {rep_dev['kappa']:.4f}")


if __name__ == "__main__":
    main()
