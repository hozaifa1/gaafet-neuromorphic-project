"""
Stage-1 FeFET LSNN (configs A / B / C).  REDESIGN/01_CONFIG_MENU.md + 03_INTEGRATION.md.

Two independent changes over the proven VO2-RC network (which reached ~90% on this ECG
task):

1. NEURON -> compact CMOS.  The membrane + adaptation are realised with 1 pF caps and
   GOhm subthreshold leaks instead of the 1.419 uF benchtop cap (kills C2/C3).  This is an
   EXACT reparameterization of the proven neuron: tau and every circuit gain are invariant
   to the cap value, so the dynamics are identical to the 90% teacher while the
   energy/area ledger collapses by ~1e6-1e7x.  Derivation (verified algebraically):
       alpha = Cmem_old/Cmem_new ;  beta = Ca_old/Ca_new
       Rh+Rs       *= alpha ,  input_scaling /= alpha ,  kappa_n /= alpha   (membrane)
       Ra          *= beta  ,  kappa_p       /= beta                        (adaptation)
   -> factor, factor_va, (Rh+Rs)*input_scaling, (Rh+Rs)*Il and Ra*Ia all unchanged.

2. SYNAPSE -> FeFET.  fc1 / recurrent / fc2 weights pass through the 15-level device map
   (fefet_layers), STE backward.  This makes the device load-bearing (kills C1) and is the
   only admitted Stage-1 non-ideality.

config A: signed (differential G+-G-) synapse, 1 pF membrane.
config B: unsigned (single 1FeFET-1R + offset) synapse, 1 pF membrane.
config C: signed synapse, cap-free clocked neuron (same dynamics, ledger cap = 0).
"""
from __future__ import annotations
import torch
import torch.nn as nn

from model import LIFVO2, ALIFVO2, LPFilter, LinearDualRecurrentContainer
from surrogate import ScaledPiecewiseQuadratic
from fefet_layers import DelayedLinearFeFET, LinearFeFET

# ---- proven VO2-RC teacher neuron (the ~90% operating point) ----
_OLD = dict(Rh=5250.0, Rs=2580.0, Cmem=1.419e-6, input_scaling=9900e-6,
            Ra=100e3, Ca=5556e-9, kappa_n=29e-6, kappa_p=18e-6,
            v_threshold=3.6, v_reset=1.5, vtn=0.745, vtp=0.973,
            wl_ratio_n=16.0, wl_ratio_p=8.0, Vdd=5.0)
_DEV = dict(g_min=1.0 / 71.4e6, g_max=1.0 / 2.34e6)   # calibrated device (R_off / R_on)


def compact_neuron_params(c_mem: float = 1e-12, c_a: float = 1e-12) -> dict:
    """Exact pF reparameterization of the proven neuron (see module docstring)."""
    alpha = _OLD["Cmem"] / c_mem
    beta = _OLD["Ca"] / c_a
    return dict(
        Rh=(_OLD["Rh"] + _OLD["Rs"]) * alpha, Rs=0.0, Cmem=c_mem,
        input_scaling=_OLD["input_scaling"] / alpha,
        kappa_n=_OLD["kappa_n"] / alpha,
        Ra=_OLD["Ra"] * beta, Ca=c_a, kappa_p=_OLD["kappa_p"] / beta,
        vtn=_OLD["vtn"], vtp=_OLD["vtp"],
        wl_ratio_n=_OLD["wl_ratio_n"], wl_ratio_p=_OLD["wl_ratio_p"], Vdd=_OLD["Vdd"],
    )


class FeFETDualRecurrentContainer(LinearDualRecurrentContainer):
    """Recurrent container whose recurrent weight matrix is a FeFET synapse."""
    def __init__(self, sub_module_1, sub_module_2, in_features, out_features_1,
                 out_features_2, max_delay=10, g_min=_DEV["g_min"], g_max=_DEV["g_max"],
                 n_levels=15, synapse="signed"):
        super().__init__(sub_module_1, sub_module_2, in_features, out_features_1,
                         out_features_2, bias=False, max_delay=max_delay)
        self.rc = DelayedLinearFeFET(self.out_features_total, in_features, bias=False,
                                     max_delay=max_delay, diag_disconnect=True,
                                     g_min=g_min, g_max=g_max, n_levels=n_levels,
                                     synapse=synapse)


class FeFETLSNN(nn.Module):
    def __init__(self, num_in=3, num_lif=60, num_alif=40, num_out=4,
                 tau_lp=11.11e-3, dt=5.556e-4, max_delay=10, refractory=0,
                 c_mem=1e-12, c_a=1e-12, cap_free=False,
                 v_threshold=3.6, v_reset=1.5, input_scaling=None,
                 n_levels=15, synapse="signed",
                 g_min=_DEV["g_min"], g_max=_DEV["g_max"],
                 surrogate_alpha=1.0, surrogate_gamma=0.3, device="cpu"):
        super().__init__()
        np_ = compact_neuron_params(c_mem, c_a)
        if input_scaling is not None:
            np_["input_scaling"] = input_scaling   # primary tunable (FeFET weights shift it)

        def mk_surrogate():
            return ScaledPiecewiseQuadratic(alpha=surrogate_alpha, gamma=surrogate_gamma)

        lif = LIFVO2(Rh=np_["Rh"], Rs=np_["Rs"], Cmem=np_["Cmem"],
                     v_threshold=v_threshold, v_reset=v_reset, Vdd=np_["Vdd"],
                     input_scaling=np_["input_scaling"], dt=dt, refractory=refractory,
                     surrogate_function=mk_surrogate())
        alif = ALIFVO2(Rh=np_["Rh"], Rs=np_["Rs"], Ra=np_["Ra"], Cmem=np_["Cmem"], Ca=np_["Ca"],
                       v_threshold=v_threshold, v_reset=v_reset,
                       vtn=np_["vtn"], vtp=np_["vtp"], kappa_n=np_["kappa_n"], kappa_p=np_["kappa_p"],
                       wl_ratio_n=np_["wl_ratio_n"], wl_ratio_p=np_["wl_ratio_p"], Vdd=np_["Vdd"],
                       input_scaling=np_["input_scaling"], dt=dt, refractory=refractory,
                       surrogate_function=mk_surrogate())

        syn = dict(g_min=g_min, g_max=g_max, n_levels=n_levels, synapse=synapse)
        self.fc1 = DelayedLinearFeFET(num_in, num_lif + num_alif, bias=False,
                                      max_delay=max_delay, **syn)
        self.hidden = FeFETDualRecurrentContainer(
            lif, alif, in_features=(num_lif + num_alif),
            out_features_1=num_lif, out_features_2=num_alif, max_delay=max_delay, **syn)
        self.lp = LPFilter(tau=tau_lp, dt=dt)
        self.fc2 = LinearFeFET(num_lif + num_alif, num_out, bias=False, **syn)

        self.num_lif, self.num_alif, self.dt, self.device = num_lif, num_alif, dt, device
        self.cap_free, self.c_mem, self.c_a = cap_free, c_mem, c_a
        self.spike_for_reg = None
        self._neurons = (lif, alif)

    def set_surrogate_alpha(self, alpha: float) -> None:
        for n in self._neurons:
            n.surrogate_function.alpha = alpha

    def spike_regularization(self, target_f=15.0, lambda_f=5e-7):
        average = torch.mean(self.spike_for_reg, dim=(0, 1)) / self.dt
        return torch.sum(torch.square(average - target_f)) * lambda_f

    def forward(self, x: torch.Tensor):
        # x: [batch, times, features]
        self.spike_for_reg = torch.empty(
            [x.shape[0], x.shape[1], (self.num_lif + self.num_alif)], device=self.device)
        x = x.permute(1, 0, 2)                       # [times, batch, features]
        y_seq = []
        for t in range(x.shape[0]):
            y = self.fc1(x[t])
            y = self.hidden(y)
            self.spike_for_reg[:, t] = y
            y = self.lp(y)
            y_seq.append(self.fc2(y).unsqueeze(0))
        return torch.cat(y_seq, 0)


def build(config: str, **kw) -> FeFETLSNN:
    """config in {A, B, C}."""
    cfg = config.upper()
    if cfg == "A":
        return FeFETLSNN(synapse="signed", cap_free=False, **kw)
    if cfg == "B":
        return FeFETLSNN(synapse="unsigned", cap_free=False, **kw)
    if cfg == "C":
        return FeFETLSNN(synapse="signed", cap_free=True, **kw)
    raise ValueError(f"unknown config {config!r} (use A/B/C)")
