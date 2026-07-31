"""
Stage-1 FeFET synapse: unbounded latent weight -> log-domain map -> 15-level
device conductance with a straight-through estimator (STE).

This is the core fix for the 76% saturating-physics ceiling (see REDESIGN/02_PLAN
section 1.2 and research/R3): train an UNBOUNDED latent w in R; the device's
discrete/saturating behaviour lives ONLY in the forward pass; gradients flow
through the latent via STE so they never die at the device rails.

Self-contained (torch only). No SpikingJelly dependency.
"""
from __future__ import annotations
import numpy as np
import torch
import torch.nn as nn


def log_levels(g_min: float, g_max: float, n: int = 15) -> torch.Tensor:
    """15 log-spaced conductance levels over the measured ~4-decade LTP range."""
    return torch.from_numpy(np.geomspace(g_min, g_max, n)).float()


class _STEQuantize(torch.autograd.Function):
    """Snap each conductance to the nearest device level forward; identity backward."""
    @staticmethod
    def forward(ctx, g: torch.Tensor, levels: torch.Tensor) -> torch.Tensor:
        edges = (levels[:-1] + levels[1:]) / 2.0           # midpoints between levels
        idx = torch.bucketize(g, edges)                    # -> nearest level index
        return levels[idx.clamp(0, levels.numel() - 1)]

    @staticmethod
    def backward(ctx, grad_out):
        return grad_out, None                              # STE: pass gradient through


def ste_quantize(g: torch.Tensor, levels: torch.Tensor) -> torch.Tensor:
    return _STEQuantize.apply(g, levels)


def fefet_signed_map(w: torch.Tensor, levels: torch.Tensor,
                     g_min: float, g_max: float) -> torch.Tensor:
    """
    Minimal-diff FeFET-ization of an EXISTING latent weight tensor (any shape).
    Single unbounded latent -> signed differential 15-level conductance weight in
    ~[-1, 1]: magnitude is log-mapped to the device range and STE-snapped to a level;
    sign picks the G+ vs G- branch. Use inside a layer's forward:
        F.linear(x, fefet_signed_map(self.weight, levels, g_min, g_max))
    Keeps the model's existing Parameters/delays intact (the 76% fix still applies:
    the latent stays unbounded, device discreteness is forward-only via STE).
    """
    frac = torch.sigmoid(w.abs())                       # (0,1), unbounded latent in
    g = g_min * (g_max / g_min) ** frac
    g = ste_quantize(g, levels)
    return torch.sign(w) * (g / g_max)                  # signed, ~[-1, 1]


class FeFETSynapse(nn.Module):
    """
    Differential (G+ - G-) FeFET synapse layer. Trainable parameter is the
    unbounded latent; conductance and quantization are forward-only.

    weight_eff = (G+ - G-) / G_max, in [-1, 1]  (normalized so it drops into a
    standard Linear-style matmul). Set differential=False for the 1FeFET-1R
    single-ended fallback (config B).
    """
    def __init__(self, in_features: int, out_features: int,
                 g_min: float, g_max: float, n_levels: int = 15,
                 differential: bool = True):
        super().__init__()
        self.differential = differential
        self.register_buffer("levels", log_levels(g_min, g_max, n_levels))
        self.g_min, self.g_max = float(g_min), float(g_max)
        # latent ~ N(0, .) -> sigmoid -> spans the log range; start near mid-range
        self.w_pos = nn.Parameter(torch.randn(out_features, in_features) * 0.5)
        if differential:
            self.w_neg = nn.Parameter(torch.randn(out_features, in_features) * 0.5)

    def _latent_to_g(self, w: torch.Tensor) -> torch.Tensor:
        # log-domain map: sigmoid(w) in (0,1) -> G in [g_min, g_max], then STE-snap.
        frac = torch.sigmoid(w)
        g = self.g_min * (self.g_max / self.g_min) ** frac
        return ste_quantize(g, self.levels)

    def effective_weight(self) -> torch.Tensor:
        gp = self._latent_to_g(self.w_pos)
        if self.differential:
            gn = self._latent_to_g(self.w_neg)
            return (gp - gn) / self.g_max          # signed, ~[-1, 1]
        return gp / self.g_max                      # unsigned, (0, 1]

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: [batch, in_features] -> [batch, out_features]
        return x @ self.effective_weight().t()


def _selfcheck():
    torch.manual_seed(0)
    # device numbers from SNN_PARAMETERS.md: G_off=1/71.4MΩ, G_on=1/2.34MΩ
    g_min, g_max = 1.0 / 1.129e8, 1.0 / 3.68e6   # norm.py convention (2026-07-31)
    syn = FeFETSynapse(8, 4, g_min, g_max, n_levels=15, differential=True)

    # 1) forward conductances must land exactly on the 15 device levels
    g = syn._latent_to_g(syn.w_pos)
    lv = syn.levels
    on_grid = torch.min(torch.abs(g.unsqueeze(-1) - lv), dim=-1).values.max().item()
    assert on_grid < 1e-12, f"quantized G not on device levels: {on_grid}"

    # 2) STE must deliver a non-zero gradient to the unbounded latent (the 76% fix)
    x = torch.randn(5, 8)
    loss = syn(x).pow(2).mean()
    loss.backward()
    assert syn.w_pos.grad is not None and syn.w_pos.grad.abs().sum() > 0, "STE killed gradient"

    # 3) effective weight stays in [-1, 1]
    w = syn.effective_weight()
    assert w.abs().max() <= 1.0 + 1e-6, "differential weight out of range"
    print("fefet_synapse self-check OK  | 15 levels, STE gradient alive, signed weight in [-1,1]")


if __name__ == "__main__":
    _selfcheck()
