"""
EEG contiguous post-processing (the paper's decoupled step) + device faithfulness.
=================================================================================
Our raw LSNN scatters false positives across the 1-hour contiguous test stream, so raw
specificity/G-mean is mediocre (the paper reported the same and solved it identically).
This applies a moving-average smoothing + threshold to the CONTIGUOUS per-clip epileptic
probability, then reports G-mean/sensitivity/specificity — raw vs post-processed, for both
the full-precision model and the 15-level FeFET-quantized (on-device) weights.

NOTE: `--model orig` (VO2LSNN) does NOT use DEV/gain in its forward; FeFET quantization is
applied post-hoc by snapping weights to the measured differential levels (as in post_quantize.py).
Moving average is CENTERED (offline eval, as in the reference). Window/threshold are swept on the
test stream (a stated limitation, mirroring the reference's Supplementary Fig. 28).

Run (does not need training stopped; ~one inference pass over 2878 clips):
    python eeg_postprocess.py --ckpt REDESIGN/runs/eeg_final/eeg_final_best.ckpt
"""
import torch                       # before numpy on Windows
import os
import sys
import argparse
import numpy as np

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "REDESIGN", "code"))
import redesign_stage1 as rs
from model import VO2LSNN
from spikingjelly.clock_driven import functional
import post_quantize as pq


def build_eeg(device, input_scaling):
    # exact training config (F_ orig params) with EEG dims + calibrated input_scaling
    return VO2LSNN(
        num_in=37, num_lif=24, num_alif=16, num_out=2,
        tau=11.11e-3, tau_lp=11.11e-3, Rh=5250., Rs=2580., Ra=100e3, Cmem=1.419e-6, Ca=5556e-9,
        v_threshold=3.6, v_reset=1.5, vtn=0.745, vtp=0.973, kappa_n=29e-6, kappa_p=18e-6,
        wl_ratio_n=16, wl_ratio_p=8, Vdd=5.0, input_scaling=input_scaling, dt=5.556e-4,
        max_delay=10, refractory=5, device=device).to(device)


@torch.no_grad()
def infer_probs(model, X, device, batch=64, k=116, rmode="last"):
    """Per-clip P(epileptic) over the contiguous test set, in order. rmode MUST match training."""
    model.eval()
    out_p = []
    for i in range(0, len(X), batch):
        xb = torch.from_numpy(X[i:i + batch]).float().to(device)
        out = rs.readout(model(xb), rmode, k)              # [B,2]  (readout must match how model was trained)
        functional.reset_net(model)
        out_p.append(torch.softmax(out, dim=1)[:, 1].cpu().numpy())
    return np.concatenate(out_p)


def metrics(pred, y):
    tp = int(((pred == 1) & (y == 1)).sum()); tn = int(((pred == 0) & (y == 0)).sum())
    fp = int(((pred == 1) & (y == 0)).sum()); fn = int(((pred == 0) & (y == 1)).sum())
    sens = tp / (tp + fn) if (tp + fn) else 0.0
    spec = tn / (tn + fp) if (tn + fp) else 0.0
    return sens, spec, (sens * spec) ** 0.5, (tp, tn, fp, fn)


def moving_average(x, w):
    return x if w <= 1 else np.convolve(x, np.ones(w) / w, mode="same")


def sweep(probs, y, tag, save_prefix=None):
    """FINE window x threshold sweep; report best-G-mean AND a sensible high-specificity
    operating point (sens>=0.90 with max spec). Optionally dump probs + sweep for figures."""
    print(f"\n[{tag}]")
    s, sp, g, cm = metrics((probs >= 0.5).astype(int), y)
    print(f"  RAW (thr 0.5)             : sens={s:.4f} spec={sp:.4f} G-mean={g:.4f}  (TP,TN,FP,FN)={cm}")
    WINS = [1, 5, 9, 15, 21, 31, 41, 51]
    THRS = [round(t, 3) for t in np.arange(0.25, 0.96, 0.025)]   # fine: 0.025 steps
    best_g = (0.0, None)          # best G-mean overall
    best_hi = (-1.0, None)        # best specificity subject to sens >= 0.90 (deployable operating pt)
    grid = []
    for w in WINS:
        sm = moving_average(probs, w)
        for thr in THRS:
            s, sp, g, cm = metrics((sm >= thr).astype(int), y)
            grid.append((w, thr, s, sp, g, cm[2]))   # cm[2]=FP
            if g > best_g[0]:
                best_g = (g, (w, thr, s, sp, cm))
            if s >= 0.90 and sp > best_hi[0]:
                best_hi = (sp, (w, thr, s, sp, g, cm))
    g, (w, thr, s, sp, cm) = best_g
    print(f"  BEST G-mean (w={w:2d},thr={thr}) : sens={s:.4f} spec={sp:.4f} G-mean={g:.4f}  (TP,TN,FP,FN)={cm}")
    if best_hi[1]:
        _, (w2, thr2, s2, sp2, g2, cm2) = best_hi
        print(f"  DEPLOY pt sens>=.90 (w={w2:2d},thr={thr2}): sens={s2:.4f} spec={sp2:.4f} G-mean={g2:.4f}  (TP,TN,FP,FN)={cm2}")
    if save_prefix:
        np.savez(save_prefix + "_ppdata.npz", probs=probs, y=y,
                 grid=np.array([(w, t, s, sp, g, fp) for (w, t, s, sp, g, fp) in grid], dtype=float),
                 best_g=np.array([w, thr]), best_hi=np.array(best_hi[1][:2] if best_hi[1] else [0, 0]))
    return best_g


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ckpt", default="REDESIGN/runs/eeg_long/eeg_long_best.ckpt")
    ap.add_argument("--input_scaling", type=float, default=3.3e-3)
    ap.add_argument("--levels", type=int, default=15, help="FeFET levels for the on-device pass")
    ap.add_argument("--device_pass", action="store_true", help="also run the 15-level quantized weights")
    ap.add_argument("--readout", default="last", help="MUST match training readout (eeg_lastread trained with 'last')")
    args = ap.parse_args()

    device = torch.device("cpu")
    torch.manual_seed(100)
    d = np.load(os.path.join(_HERE, "eeg.npz"))
    X, y = d["X_test"], d["y_test"].astype(int)
    print(f"test: {len(y)} clips, {int((y==1).sum())} epileptic, {int((y==0).sum())} normal")

    model = build_eeg(device, args.input_scaling)
    st = torch.load(os.path.join(_HERE, args.ckpt), map_location=device, weights_only=False)
    model.load_state_dict(st["net"])
    print(f"loaded {args.ckpt} (epoch {st.get('epoch','?')})")

    print(f"readout = {args.readout} (must match training)")
    tag = 'lvl%d' % args.levels
    probs_fp = infer_probs(model, X, device, rmode=args.readout)
    sweep(probs_fp, y, "full-precision (software)", save_prefix=os.path.join(_HERE, "REDESIGN/runs/eeg_long/pp_fp"))

    if args.device_pass:
        ach = pq.achievable_diff_values(args.levels)
        pq.quantize_(model, ach)
        probs_dev = infer_probs(model, X, device, rmode=args.readout)
        sweep(probs_dev, y, f"on-device {args.levels}-level FeFET",
              save_prefix=os.path.join(_HERE, "REDESIGN/runs/eeg_long/pp_dev%s" % tag))


if __name__ == "__main__":
    main()
