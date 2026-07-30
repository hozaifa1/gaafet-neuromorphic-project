"""
Assemble the CHB-MIT epilepsy EEG dataset into a single eeg.npz in the SAME
[n, T=1116, 37] spike-tensor layout the pipeline expects (matches DeltaTransformedEEG):

  - source: VO2-project CHB-MIT patient-1 clips (18 ch, 1000 steps, ~1.25 s), already
    delta-encoded to UP/DOWN spike trains (delta modulation ~= our generic encoder).
    up/down: [n, 18, 1000]  ->  interleave per channel [down_c, up_c] -> [n, 1000, 36]
  - append CUE window: 116 zero steps padded in time, + a 37th channel that is 0 for the
    first 1000 steps and 1 for the last 116 (the decision cue).  -> [n, 1116, 37]

  train = data_eeg_balanced_2530 (1265 N + 1265 E, balanced, non-contiguous)
  test  = data_eeg_contiguous    (2878 clips = 1 contiguous hour, only ~31 epileptic)

  labels: 0 = Normal (N), 1 = Epileptic (E).  Written as float32 X, int64 y.
Memory-careful: builds/saves train, frees, then test (each X ~0.4-0.5 GB).
"""
import os
import gc
import numpy as np

_HERE = os.path.dirname(os.path.abspath(__file__))
_SRC = os.path.join(_HERE, "data_eeg_src")
CUE = 116


def build_split(folder):
    up = np.load(os.path.join(folder, "up_compressed.npz"))["up"]       # [n,18,1000] f64
    down = np.load(os.path.join(folder, "down_compressed.npz"))["down"]  # [n,18,1000]
    lab = np.load(os.path.join(folder, "label_compressed.npz"))["label"].squeeze().astype(np.int64)
    n, ch, T = up.shape
    # interleave per channel: [..., ::2]=down, [..., 1::2]=up  (matches dataset.py)
    core = np.empty((n, T, 2 * ch), dtype=np.float32)
    core[..., 0::2] = np.transpose(down, (0, 2, 1)).astype(np.float32)
    core[..., 1::2] = np.transpose(up, (0, 2, 1)).astype(np.float32)
    del up, down; gc.collect()
    # append CUE: pad 116 zero steps on all 36 ch, then add a 37th cue channel
    X = np.zeros((n, T + CUE, 2 * ch + 1), dtype=np.float32)
    X[:, :T, :2 * ch] = core
    X[:, T:, 2 * ch] = 1.0            # cue channel = 1 during the decision window
    del core; gc.collect()
    return X, lab


if __name__ == "__main__":
    print("building EEG train (data_eeg_balanced_2530) ...", flush=True)
    Xtr, ytr = build_split(os.path.join(_SRC, "data_eeg_balanced_2530"))
    print(f"  train X {Xtr.shape} y {ytr.shape}  class counts {np.bincount(ytr).tolist()}", flush=True)
    print("building EEG test (data_eeg_contiguous) ...", flush=True)
    Xte, yte = build_split(os.path.join(_SRC, "data_eeg_contiguous"))
    print(f"  test  X {Xte.shape} y {yte.shape}  class counts {np.bincount(yte).tolist()}", flush=True)
    out = os.path.join(_HERE, "eeg.npz")
    np.savez_compressed(out, X_train=Xtr, y_train=ytr, X_test=Xte, y_test=yte)
    print(f"wrote {out}", flush=True)
