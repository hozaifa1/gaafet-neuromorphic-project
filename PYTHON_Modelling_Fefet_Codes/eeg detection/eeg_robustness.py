"""
EEG hardware-aware robustness (device pass, part 3).
====================================================
Re-evaluate the deployed EEG LSNN (best ckpt, readout=last) under measured/realistic device
non-idealities, reporting G-mean raw and with a FIXED post-processing (window=21, thr=0.5 —
the baseline on-device setting; NOT re-tuned per condition, so degradation is honest):

  nominal 300K (15 measured levels) | T=250K / T=350K (MEASURED ladders)
  D2D sigma (frozen log-normal) | C2C sigma (resampled) | D2D+C2C | retention -10%

Reuses robustness_eval.quantize_with_noise + fefet_device measured temperature levels, and
eeg_postprocess.build_eeg / infer_probs (37-ch, input_scaling 3.3e-3, num_out 2).
"""
import torch
import os
import sys
import json
import numpy as np

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "REDESIGN", "code"))
from fefet_device import measured_levels, measured_levels_at_temperature
from robustness_eval import achievable_from_levels, quantize_with_noise
import eeg_postprocess as ep

PP_WIN, PP_THR = 21, 0.5   # fixed post-processing (baseline on-device setting), applied to ALL conditions


def gmean_raw_and_pp(model, X, y):
    probs = ep.infer_probs(model, X, torch.device("cpu"), rmode="last")
    s, sp, g, _ = ep.metrics((probs >= 0.5).astype(int), y)
    sm = ep.moving_average(probs, PP_WIN)
    s2, sp2, g2, _ = ep.metrics((sm >= PP_THR).astype(int), y)
    return (round(g, 4), round(s, 4), round(sp, 4)), (round(g2, 4), round(s2, 4), round(sp2, 4))


def main():
    device = torch.device("cpu")
    torch.manual_seed(100)
    d = np.load(os.path.join(_HERE, "eeg.npz"))
    X, y = d["X_test"], d["y_test"].astype(int)
    model = ep.build_eeg(device, 3.3e-3)
    st = torch.load(os.path.join(_HERE, "REDESIGN/runs/eeg_lastread/eeg_lastread_best.ckpt"),
                    map_location=device, weights_only=False)
    model.load_state_dict(st["net"])
    fp_state = {k: v.clone() for k, v in model.state_dict().items()}
    print(f"[eeg-robust] loaded best ckpt (epoch {st.get('epoch','?')}); fixed post-proc w={PP_WIN} thr={PP_THR}")

    lv300, _, gmax300 = measured_levels()
    lv250, _, gmax250 = measured_levels_at_temperature("G_250K_uA_um")
    lv350, _, gmax350 = measured_levels_at_temperature("G_350K_uA_um")
    a300 = achievable_from_levels(lv300, gmax300)
    a250 = achievable_from_levels(lv250, gmax250)
    a350 = achievable_from_levels(lv350, gmax350)

    conds = [
        ("nominal_300K", lambda: quantize_with_noise(model, fp_state, a300)),
        ("T=250K",       lambda: quantize_with_noise(model, fp_state, a250)),
        ("T=350K",       lambda: quantize_with_noise(model, fp_state, a350)),
        ("D2D_s0.1",     lambda: quantize_with_noise(model, fp_state, a300, d2d=0.10)),
        ("C2C_s0.1",     lambda: quantize_with_noise(model, fp_state, a300, c2c=0.10)),
        ("D2D+C2C",      lambda: quantize_with_noise(model, fp_state, a300, d2d=0.10, c2c=0.10)),
        # MEASURED retention: leak_retention.csv drifts -2.94% from peak (17.5us) to 100us -> factor 0.971
        ("retention_MEASURED_-2.9pct", lambda: quantize_with_noise(model, fp_state, a300, retention=0.971)),
        # pessimistic long-term extrapolation stress case (retention beyond the 100us characterized window)
        ("retention_stress_-10pct", lambda: quantize_with_noise(model, fp_state, a300, retention=0.90)),
    ]
    results = {}
    # full precision reference
    model.load_state_dict(fp_state)
    results["full_precision"] = gmean_raw_and_pp(model, X, y)
    for name, fn in conds:
        fn()
        results[name] = gmean_raw_and_pp(model, X, y)
        raw, pp = results[name]
        print(f"  {name:18s}  raw G-mean {raw[0]:.4f} (se {raw[1]:.3f}/sp {raw[2]:.3f})   "
              f"post-proc {pp[0]:.4f} (se {pp[1]:.3f}/sp {pp[2]:.3f})", flush=True)
    json.dump(results, open(os.path.join(_HERE, "REDESIGN/runs/eeg_lastread/eeg_robust.json"), "w"), indent=2)
    print("wrote eeg_robust.json")


if __name__ == "__main__":
    main()
