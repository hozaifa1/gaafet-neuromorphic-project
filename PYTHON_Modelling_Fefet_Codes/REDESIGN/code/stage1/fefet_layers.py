"""
FeFET-ized weight layers for the Stage-1 LSNN (configs A/B/C).

Minimal diff over the recovered base model (REDESIGN/03_INTEGRATION.md):
the trainable Parameter stays the UNBOUNDED latent; the 15-level device map is
forward-only via STE so gradients never die (the 76% fix, research/R3 s1).

- signed_map   : config A/C  -> differential G+-G- implicit, signed weight in [-1, 1]
- unsigned_map : config B    -> single 1FeFET-1R, unsigned conductance + fixed offset

A global toggle switches the two reviewer eval passes (03_INTEGRATION.md Step 3):
  quantize ON  -> snap to the 15 measured device levels   (the REAL-device number)
  quantize OFF -> continuous log map                       (FP-latent upper bound)
The (OFF -> ON) gap is the Stage-1 device-faithfulness result. Training keeps it ON
(device-aware STE training).
"""
from __future__ import annotations
import torch
import torch.nn as nn
import torch.nn.functional as F

from model import DelayedLinear
from fefet_synapse import log_levels, ste_quantize

# ---- global eval toggle (device-quantized vs continuous FP upper bound) ----
_QUANTIZE = True


def set_quantize(flag: bool) -> None:
    global _QUANTIZE
    _QUANTIZE = flag


def get_quantize() -> bool:
    return _QUANTIZE


def _latent_to_g(frac: torch.Tensor, g_min: float, g_max: float,
                 levels: torch.Tensor) -> torch.Tensor:
    g = g_min * (g_max / g_min) ** frac
    if _QUANTIZE:
        g = ste_quantize(g, levels)
    return g


def signed_map(w: torch.Tensor, levels: torch.Tensor, g_min: float, g_max: float) -> torch.Tensor:
    """Config A/C: magnitude log-mapped to the device range, sign picks G+ vs G- rail."""
    frac = torch.sigmoid(w.abs())
    g = _latent_to_g(frac, g_min, g_max, levels)
    return torch.sign(w) * (g / g_max)               # signed, ~[-1, 1]


def unsigned_map(w: torch.Tensor, levels: torch.Tensor, g_min: float, g_max: float,
                 offset: float = 0.5) -> torch.Tensor:
    """Config B: single unsigned conductance in (0,1], fixed offset column gives sign."""
    frac = torch.sigmoid(w)
    g = _latent_to_g(frac, g_min, g_max, levels)
    return g / g_max - offset                         # signed via offset, ~(-offset, 1-offset]


def _map(w, synapse, levels, g_min, g_max):
    if synapse == "signed":
        return signed_map(w, levels, g_min, g_max)
    return unsigned_map(w, levels, g_min, g_max)


class DelayedLinearFeFET(DelayedLinear):
    """DelayedLinear with the weight routed through the FeFET device map in forward."""
    def __init__(self, in_features: int, out_features: int, bias: bool = True,
                 max_delay: int = 10, diag_disconnect: bool = False,
                 g_min: float = 1.0 / 71.4e6, g_max: float = 1.0 / 2.34e6,
                 n_levels: int = 15, synapse: str = "signed"):
        super().__init__(in_features, out_features, bias, max_delay, diag_disconnect)
        self.register_buffer("levels", log_levels(g_min, g_max, n_levels))
        self.g_min, self.g_max, self.synapse = float(g_min), float(g_max), synapse

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        w_dev = _map(self.weight, self.synapse, self.levels, self.g_min, self.g_max)
        delay_masked_weight = torch.transpose(
            torch.where(self.delay_mask, w_dev, torch.zeros_like(w_dev)), dim0=0, dim1=1)
        self.out_buf += self.einsum_bi_ijk_bjk(x, delay_masked_weight)
        out = self.out_buf[:, :, 0]
        self.roll()
        return out


class LinearFeFET(nn.Linear):
    """nn.Linear readout with the weight routed through the FeFET device map."""
    def __init__(self, in_features: int, out_features: int, bias: bool = False,
                 g_min: float = 1.0 / 71.4e6, g_max: float = 1.0 / 2.34e6,
                 n_levels: int = 15, synapse: str = "signed"):
        super().__init__(in_features, out_features, bias)
        self.register_buffer("levels", log_levels(g_min, g_max, n_levels))
        self.g_min, self.g_max, self.synapse = float(g_min), float(g_max), synapse

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        w = _map(self.weight, self.synapse, self.levels, self.g_min, self.g_max)
        return F.linear(x, w, self.bias)


def _selfcheck():
    torch.manual_seed(0)
    lin = DelayedLinearFeFET(3, 5, bias=False, max_delay=4, synapse="signed")
    x = torch.randn(7, 3)
    set_quantize(True)
    y_dev = lin(x); lin.reset()
    set_quantize(False)
    y_fp = lin(x); lin.reset()
    assert y_dev.shape == (7, 5)
    loss = y_dev.pow(2).mean(); loss.backward()
    assert lin.weight.grad.abs().sum() > 0, "STE killed gradient through DelayedLinearFeFET"
    print("fefet_layers self-check OK | DelayedLinearFeFET fwd/bwd, fp!=dev gap = %.4f"
          % (y_fp - y_dev).abs().mean().item())


if __name__ == "__main__":
    _selfcheck()
