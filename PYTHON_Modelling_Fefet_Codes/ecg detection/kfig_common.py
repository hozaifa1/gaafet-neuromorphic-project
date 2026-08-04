"""
Shared harness for the K-series device->SNN figures (K2 levels, K3 variability, K4 energy).

One place that knows how to: load the locked checkpoint, evaluate it, and deploy it onto an
arbitrary conductance ladder. Nothing here retrains anything.
"""
import torch, os, sys
import numpy as np
import torch.utils.data as data

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "REDESIGN", "code"))
CF = os.path.join(_HERE, "..", "Combined Figures")
sys.path.insert(0, CF)

import redesign_stage1 as rs           # noqa: E402
import post_quantize as pq             # noqa: E402

CKPT = os.path.join(_HERE, "REDESIGN", "runs", "paper150b", "paper150b_best.ckpt")
OUT = os.path.join(CF, "ecg figures")
RUNS = os.path.join(_HERE, "REDESIGN", "runs")


def setup(threads: int = 4):
    """Return (model, fp_state, eval_fn). CPU-only, 4 threads = 4 physical cores."""
    torch.set_num_threads(threads)
    os.makedirs(OUT, exist_ok=True); os.makedirs(RUNS, exist_ok=True)
    dev = torch.device("cpu")
    pq.ARCH["num_in"] = 3
    torch.manual_seed(100)
    loader = pq.build_test_loader(dev, "intra")
    model = pq.build_orig(dev)
    state = torch.load(CKPT, map_location=dev, weights_only=False)
    fp_state = {k: v.clone() for k, v in state["net"].items()}
    model.load_state_dict(fp_state)

    def ev():
        return rs.evaluate(model, loader, dev, quant=False, rmode="meancue", k=116)

    return model, fp_state, ev


def diff_set(levels: torch.Tensor, g_max: float) -> torch.Tensor:
    """Sorted unique achievable differential weights (G_i - G_j)/g_max."""
    ln = (levels / g_max).numpy()
    return torch.tensor(sorted({round(float(a - b), 12) for a in ln for b in ln}),
                        dtype=torch.float32)


def paired_diff_sets(lv_target: torch.Tensor, gmax_target: float,
                     lv_real: torch.Tensor, gmax_real: float):
    """Targets the network is quantized to, and the values the device REALLY produces.

    Used for the uncalibrated-deployment case: the compiler picks a level pair (i, j) from
    the nominal ladder, but the physical device's own ladder sits somewhere else, so the
    realized weight is (G_i^dev - G_j^dev) / g_max^dev-as-assumed. Returns (target, real)
    tensors of equal length, sorted by target.
    """
    n = lv_target.numel()
    t = (lv_target / gmax_target).numpy()
    r = (lv_real / gmax_real).numpy()
    seen = {}
    for i in range(n):
        for j in range(n):
            key = round(float(t[i] - t[j]), 12)
            if key not in seen:
                seen[key] = float(r[i] - r[j])
    keys = sorted(seen)
    return (torch.tensor(keys, dtype=torch.float32),
            torch.tensor([seen[k] for k in keys], dtype=torch.float32))


def paired_branches(levels: torch.Tensor, g_max: float):
    """(targets, g_plus, g_minus): the two conductances that realize each achievable weight.

    Needed for cycle-to-cycle noise. c2c is a property of each PROGRAMMED CONDUCTANCE, not
    of the weight, so the two branches of a differential pair must be perturbed
    independently; injecting the noise on the difference instead would silently understate
    it for near-zero weights, where G+ ~ G- and the difference is small but each branch's
    absolute jitter is not. Where several (i, j) realize the same weight the lowest-index
    pair is kept -- the lowest-current pair that hits the target, which is what a real
    compiler would program.

    Measured on this device's 15-level ladder, the noise amplification (G+ + G-)/|w| is
    1.03 at the median -- most weights are one large conductance minus a negligible one --
    but reaches 2.2 at p90 and 4.8 at worst. The measured ladder's top levels are widely
    spaced (0.197, 0.381, 0.656, 1.000 normalized), so mid-upper weights have no
    low-conductance representation: w = +-0.344 can ONLY be built as 1.000 - 0.656, and
    independent jitter on each branch hits that weight ~5x harder than it hits either
    conductance. A weight-level noise model hides this entirely.
    """
    n = levels.numel()
    ln = (levels / g_max).numpy()
    seen = {}
    for i in range(n):
        for j in range(n):
            key = round(float(ln[i] - ln[j]), 12)
            if key not in seen:
                seen[key] = (float(ln[i]), float(ln[j]))
    keys = sorted(seen)
    return (torch.tensor(keys, dtype=torch.float32),
            torch.tensor([seen[k][0] for k in keys], dtype=torch.float32),
            torch.tensor([seen[k][1] for k in keys], dtype=torch.float32))


def deploy(model, fp_state, target: torch.Tensor, real: torch.Tensor | None = None,
           c2c: float = 0.0, retention: float = 1.0, seed: int = 0,
           branches: tuple[torch.Tensor, torch.Tensor] | None = None):
    """Restore FP weights, snap to `target`, write `real` (default: target itself).

    c2c: log-normal cycle-to-cycle sigma in ln-conductance, resampled per call. If
    `branches` = (g_plus, g_minus) is given the noise is applied to each branch
    independently and `real` is ignored; otherwise it is applied to the weight.
    """
    if real is None:
        real = target
    edges = (target[:-1] + target[1:]) / 2.0
    gen = torch.Generator().manual_seed(seed)
    model.load_state_dict(fp_state)
    with torch.no_grad():
        for name, p in model.named_parameters():
            if not name.endswith("weight"):
                continue
            s = p.abs().max().clamp(min=1e-8)
            idx = torch.bucketize((p / s).flatten(), edges).clamp(0, target.numel() - 1)
            if branches is not None and c2c > 0:
                gp = branches[0][idx].reshape(p.shape)
                gn = branches[1][idx].reshape(p.shape)
                gp = gp * torch.exp(c2c * torch.randn(gp.shape, generator=gen))
                gn = gn * torch.exp(c2c * torch.randn(gn.shape, generator=gen))
                w = (gp - gn) * retention
            else:
                w = real[idx].reshape(p.shape) * retention
                if c2c > 0:
                    w = w * torch.exp(c2c * torch.randn(w.shape, generator=gen))
            p.copy_(w * s)


def subsample_measured(levels: torch.Tensor, n: int) -> torch.Tensor:
    """n levels drawn from the MEASURED ladder (endpoints kept, evenly spaced in index)."""
    idx = np.unique(np.round(np.linspace(0, levels.numel() - 1, n)).astype(int))
    return levels[torch.from_numpy(idx)]
