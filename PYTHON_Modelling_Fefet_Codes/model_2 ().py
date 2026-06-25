"""
Physics-faithful GAA FeFET LSNN model for ECG arrhythmia classification.
=========================================================================

Replaces the VO2 RC integrate-and-fire dynamics of model.py with a
ferroelectric polarization-switching model derived from the GAA FeFET
device characterization in gaafefet_params.py (HZO ferroelectric layer,
SimC v6 6V node, fire at P9).

Key differences from model.eLIFVO2 / model.ALIFVO2:
  - State variable is the normalized polarization P ∈ [0,1] of the HZO
    layer, NOT a membrane voltage. self.v is overloaded to store P so
    that the existing main_ecg.py-style plotting/probing still works.
  - Integration uses a saturating Preisach-like switching kinetic:
        P_decayed = exp(-dt/tau_leak) · P
        ΔP        = (1 - P_decayed) · K_switch · σ((V_FE - Vc)/V_scale)
        P_new     = P_decayed + ΔP
    where V_FE is the ferroelectric layer voltage produced by mapping
    the weighted SNN drive x through weight_to_Vpulse_slope.
  - Spiking is driven by the normalized polarization error
        (P - P_threshold)/P_threshold
    using the same ScaledPiecewiseQuadratic surrogate as the original.
  - Reset is partial multiplicative (matches reset_completeness=77.2%
    from the device measurement):
        P ← P · (1 - reset_completeness · spike)
  - The ALIF variant retains the MOSFET frequency-adaptation circuit
    (CMOS peripheral, unchanged). To keep the MOSFETs in their native
    voltage operating range we apply Option-A-with-rescaling:
        v_effective = P · Vdd       (used as the nMOS leak vds)
    The leak current Il is converted back to a voltage subtraction on
    V_FE via R_adapt, preserving the input/leak balance of the original.

Architectural primitives (LPFilter, DelayedLinear,
LinearDualRecurrentContainer) are imported unchanged from model.py.

Calibration anchors (from gaafefet_params.py):
  Vc                = 1.2  V          (POLARIZATION.Ec_estimate)
  V_max             = 7.0  V          (above OPERATING.Vpulse_optimal=6V)
  reset_completeness= 0.772           (LIF.reset_completeness)
  weight_to_Vpulse_slope = 1.0        (SNN-domain rescaling of 0.5 default)
  tau_leak          = 50 ms           (slow polarization relaxation; tunable)
  K_switch          = 0.10            (per-step switching rate; tunable)
  V_scale           = 0.5  V          (sigmoid sharpness around Vc)
  P_threshold       = 0.5             (fire when P reaches half saturation)
"""

import math
import torch
import torch.nn as nn
from typing import Callable
from spikingjelly.clock_driven import neuron, base
from surrogate import ScaledPiecewiseQuadratic
from utils import absId
# Reuse architecture primitives from the original model unchanged
from model import LPFilter, DelayedLinear, LinearDualRecurrentContainer


class FeFETDevice:
    """
    Container for GAA FeFET device-physics parameters used by the spiking neurons.
    Centralizes the constants so the LIF and ALIF variants share an identical device.
    """
    def __init__(self,
                 Vc: float = 1.2,                 # coercive voltage (POLARIZATION.Ec_estimate)
                 V_scale: float = 0.5,            # sigmoid sharpness around Vc (V)
                 V_max: float = 7.0,              # safe clamp on V_FE (above 6V optimal)
                 K_switch: float = 0.10,          # per-step switching rate (tunable)
                 reset_completeness: float = 0.772,  # fraction of P removed by spike-reset
                 tau_leak: float = 50e-3,         # polarization relaxation time-constant (s)
                 weight_to_Vpulse_slope: float = 1.0,  # SNN drive → V_FE gain (V per drive unit)
                 R_adapt: float = 7830.0):        # current→voltage gain for MOSFET leak (Ω)
        self.Vc = Vc
        self.V_scale = V_scale
        self.V_max = V_max
        self.K_switch = K_switch
        self.reset_completeness = reset_completeness
        self.tau_leak = tau_leak
        self.weight_to_Vpulse_slope = weight_to_Vpulse_slope
        self.R_adapt = R_adapt


class FeFETLIFNeuron(neuron.BaseNode):
    """
    Polarization-switching LIF neuron based on GAA FeFET (HZO) device physics.
    State self.v stores the normalized polarization P ∈ [0,1].
    """
    def __init__(self,
                 device_params: FeFETDevice = None,
                 v_threshold: float = 0.5,             # P_threshold (dimensionless)
                 dt: float = 5.556e-4,
                 refractory: int = 0,
                 surrogate_function: Callable = neuron.surrogate.Sigmoid(),
                 detach_reset: bool = False):
        # v_reset is set to 0 but unused — reset is multiplicative (see neuronal_reset)
        super().__init__(v_threshold, 0.0, surrogate_function, detach_reset)
        if device_params is None:
            device_params = FeFETDevice()
        self.device_params = device_params
        # Cache device parameters as plain Python scalars
        self.Vc = device_params.Vc
        self.V_scale = device_params.V_scale
        self.V_max = device_params.V_max
        self.K_switch = device_params.K_switch
        self.reset_completeness = device_params.reset_completeness
        self.weight_to_Vpulse_slope = device_params.weight_to_Vpulse_slope
        self.tau_leak = device_params.tau_leak
        self.dt = dt
        # Pre-compute leak factor exp(-dt/tau_leak) once
        self.factor_leak = torch.exp(torch.tensor(-dt / self.tau_leak))
        self.refractory = refractory

        self.v = 0.   # holds polarization P
        self.register_memory('spike', 0)
        self.register_memory('spike_countdown', None)
        self.register_memory('is_refractory', 0)

    def neuronal_charge(self, x: torch.Tensor):
        # FeFET write path is unipolar — negative drive does not switch FE polarization
        x = torch.relu(x)
        # Map weighted SNN drive to ferroelectric layer voltage; clamp to safe operating range
        V_FE = torch.clamp(self.weight_to_Vpulse_slope * x, max=self.V_max)
        # Polarization leak (slow relaxation toward 0)
        P_decayed = self.factor_leak * self.v
        # Saturating Preisach-like switching kinetics around the coercive voltage Vc
        drive = self.K_switch * torch.sigmoid((V_FE - self.Vc) / self.V_scale)
        # Polarization grows toward saturation at rate (1 - P) · drive
        P_new = P_decayed + (1.0 - P_decayed) * drive
        self.v = torch.where(self.is_refractory, self.v, P_new)

    def neuronal_fire(self):
        # Heaviside in forward pass, ScaledPiecewiseQuadratic surrogate in backward pass
        spike = self.surrogate_function((self.v - self.v_threshold) / self.v_threshold)

        with torch.no_grad():
            if self.spike_countdown is None:
                shape = list(spike.shape)
                shape.append(self.refractory)
                self.spike_countdown = torch.zeros(shape, device=spike.device)

        spike = torch.where(self.is_refractory, torch.zeros_like(spike), spike)
        self.spike = spike
        self.spike_countdown = torch.cat(
            [self.spike_countdown[:, :, 1:], torch.unsqueeze(spike, dim=-1)], dim=-1
        )
        return self.spike

    def neuronal_reset(self, spike):
        # Partial multiplicative reset: P ← P · (1 - reset_completeness · spike)
        # Matches the LIF.reset_completeness=77.2% measured on the device.
        if self.detach_reset:
            spike_d = spike.detach()
        else:
            spike_d = spike
        self.v = self.v * (1.0 - spike_d * self.reset_completeness)

    def forward(self, x: torch.Tensor):
        with torch.no_grad():
            if not isinstance(self.spike, torch.Tensor):
                self.spike = torch.zeros(x.shape, device=x.device)
            if not isinstance(self.v, torch.Tensor):
                self.v = torch.zeros(x.shape, device=x.device)
            if not isinstance(self.is_refractory, torch.Tensor):
                self.is_refractory = torch.zeros(x.shape, device=x.device, dtype=torch.bool)

        self.neuronal_reset(self.spike)
        self.neuronal_charge(x)
        new_spike = self.neuronal_fire()
        self.is_refractory = torch.gt(
            torch.amax(self.spike_countdown[..., -self.refractory:], dim=-1), 0
        )
        return new_spike


class FeFETALIFNeuron(neuron.BaseNode):
    """
    Adaptive polarization-switching neuron: FeFET integrate-and-fire +
    MOSFET frequency-adaptation circuit (CMOS peripheral, unchanged).

    Adaptation flow:
      - Each spike charges va via pMOS Ia (neuronal_adapt) — same as ALIFVO2
      - va drives nMOS leak Il (neuronal_charge); Il is referenced against
        v_effective = P · Vdd so the nMOS sees a vds in its native range
      - Il is converted to a voltage subtraction on V_FE via R_adapt
        (preserves the input/leak balance of the original RC formulation)
    """
    def __init__(self,
                 device_params: FeFETDevice = None,
                 v_threshold: float = 0.5,             # P_threshold (dimensionless)
                 Ra: float = 100e3, Ca: float = 5556e-9,
                 vtn: float = 0.745, vtp: float = 0.973,
                 kappa_n: float = 29e-6, kappa_p: float = 18e-6,
                 wl_ratio_n: float = 16., wl_ratio_p: float = 8.,
                 Vdd: float = 5.,
                 dt: float = 5.556e-4,
                 refractory: int = 0,
                 surrogate_function: Callable = neuron.surrogate.Sigmoid(),
                 detach_reset: bool = False):
        super().__init__(v_threshold, 0.0, surrogate_function, detach_reset)
        if device_params is None:
            device_params = FeFETDevice()
        self.device_params = device_params
        # FeFET device parameters
        self.Vc = device_params.Vc
        self.V_scale = device_params.V_scale
        self.V_max = device_params.V_max
        self.K_switch = device_params.K_switch
        self.reset_completeness = device_params.reset_completeness
        self.weight_to_Vpulse_slope = device_params.weight_to_Vpulse_slope
        self.tau_leak = device_params.tau_leak
        self.R_adapt = device_params.R_adapt
        self.dt = dt
        self.factor_leak = torch.exp(torch.tensor(-dt / self.tau_leak))
        self.refractory = refractory
        # MOSFET adaptation circuit parameters (peripheral CMOS, unchanged)
        self.Ra = Ra
        self.Ca = Ca
        self.tau_va = Ca * Ra
        self.factor_va = torch.exp(torch.tensor(-dt / self.tau_va))
        self.Vdd = Vdd
        self.vtn = vtn
        self.vtp = vtp
        self.kappa_n = kappa_n
        self.kappa_p = kappa_p
        self.wl_ratio_n = wl_ratio_n
        self.wl_ratio_p = wl_ratio_p

        self.v = 0.   # holds polarization P
        self.register_memory('va', 0.)
        self.register_memory('spike', 0)
        self.register_memory('spike_countdown', None)
        self.register_memory('is_refractory', 0)

    def neuronal_charge(self, x: torch.Tensor):
        # Unipolar drive (FeFET writes only on positive polarity)
        x = torch.relu(x)
        # SNN drive → ferroelectric layer voltage, clamped
        V_FE = torch.clamp(self.weight_to_Vpulse_slope * x, max=self.V_max)
        # Option A with rescaling: feed v_effective = P · Vdd into the MOSFET adaptation
        # circuit so its vds operates in the native CMOS voltage range (0–Vdd).
        v_effective = self.v * self.Vdd
        # nMOS leak current driven by adaptation voltage va
        Il = absId(kappa=self.kappa_n, w_over_l=self.wl_ratio_n, vgs=self.va,
                   vth=self.vtn, vds=v_effective)
        # Convert leak current to a voltage subtraction on V_FE (R_adapt = R_off+R_on for consistency)
        V_FE_eff = torch.clamp(V_FE - self.R_adapt * Il, min=0.0)
        # Polarization leak + saturating switching kinetics
        P_decayed = self.factor_leak * self.v
        drive = self.K_switch * torch.sigmoid((V_FE_eff - self.Vc) / self.V_scale)
        P_new = P_decayed + (1.0 - P_decayed) * drive
        self.v = torch.where(self.is_refractory, self.v, P_new)

    def neuronal_fire(self):
        spike = self.surrogate_function((self.v - self.v_threshold) / self.v_threshold)

        with torch.no_grad():
            if self.spike_countdown is None:
                shape = list(spike.shape)
                shape.append(self.refractory)
                self.spike_countdown = torch.zeros(shape, device=spike.device)

        spike = torch.where(self.is_refractory, torch.zeros_like(spike), spike)
        self.spike = spike
        self.spike_countdown = torch.cat(
            [self.spike_countdown[:, :, 1:], torch.unsqueeze(spike, dim=-1)], dim=-1
        )
        return self.spike

    def neuronal_reset(self, spike):
        if self.detach_reset:
            spike_d = spike.detach()
        else:
            spike_d = spike
        self.v = self.v * (1.0 - spike_d * self.reset_completeness)

    def neuronal_adapt(self, spike):
        # pMOS-driven charging of the adaptation node — identical to the original ALIFVO2
        Ia = absId(kappa=self.kappa_p, w_over_l=self.wl_ratio_p, vgs=(self.Vdd * spike),
                   vth=self.vtp, vds=(self.Vdd - self.va))
        self.va = self.factor_va * self.va + (1 - self.factor_va) * self.Ra * Ia

    def forward(self, x: torch.Tensor):
        with torch.no_grad():
            if not isinstance(self.spike, torch.Tensor):
                self.spike = torch.zeros(x.shape, device=x.device)
            if not isinstance(self.v, torch.Tensor):
                self.v = torch.zeros(x.shape, device=x.device)
            if not isinstance(self.va, torch.Tensor):
                self.va = torch.zeros(x.shape, device=x.device)
            if not isinstance(self.is_refractory, torch.Tensor):
                self.is_refractory = torch.zeros(x.shape, device=x.device, dtype=torch.bool)

        self.neuronal_reset(self.spike)
        self.neuronal_adapt(self.spike)
        self.neuronal_charge(x)
        new_spike = self.neuronal_fire()
        self.is_refractory = torch.gt(
            torch.amax(self.spike_countdown[..., -self.refractory:], dim=-1), 0
        )
        return new_spike


class FeFETLSNN(nn.Module):
    """
    LSNN with GAA FeFET polarization-switching neurons (LIF + ALIF) and
    MOSFET-based frequency adaptation. Top-level architecture and tensor
    shapes are identical to VO2LSNN so main_ecg_2.py mirrors main_ecg.py.

    Architecture:
        Input → DelayedLinear → Recurrent[FeFET-LIF | FeFET-ALIF] → LPFilter → Linear → Output
    """
    def __init__(self, num_in, num_lif, num_alif, num_out,
                 tau_lp,
                 device_params: FeFETDevice,
                 v_threshold,
                 Ra, Ca,
                 vtn, vtp, kappa_n, kappa_p, wl_ratio_n, wl_ratio_p,
                 Vdd,
                 dt, max_delay, refractory, device):
        super(FeFETLSNN, self).__init__()
        self.fc1 = DelayedLinear(num_in, num_lif + num_alif, bias=False, max_delay=max_delay)
        self.hidden = LinearDualRecurrentContainer(
            sub_module_1=FeFETLIFNeuron(
                device_params=device_params,
                v_threshold=v_threshold,
                dt=dt, refractory=refractory,
                surrogate_function=ScaledPiecewiseQuadratic()
            ),
            sub_module_2=FeFETALIFNeuron(
                device_params=device_params,
                v_threshold=v_threshold,
                Ra=Ra, Ca=Ca,
                vtn=vtn, vtp=vtp, kappa_n=kappa_n, kappa_p=kappa_p,
                wl_ratio_n=wl_ratio_n, wl_ratio_p=wl_ratio_p,
                Vdd=Vdd,
                dt=dt, refractory=refractory,
                surrogate_function=ScaledPiecewiseQuadratic()
            ),
            in_features=(num_lif + num_alif), out_features_1=num_lif, out_features_2=num_alif, bias=False,
            max_delay=max_delay
        )
        self.lp = LPFilter(tau=tau_lp, dt=dt)
        self.fc2 = nn.Linear(num_lif + num_alif, num_out, bias=False)

        # Probe buffers (only populated when forward batch is 1, as in main_ecg.py plotting)
        self.v = None
        self.v_threshold = None
        self.spike = None
        self.spike_for_reg = None

        self.num_lif = num_lif
        self.num_alif = num_alif
        self.dt = dt
        self.device = device

    def spike_regularization(self, target_f=10, lambda_f=1e-7):
        average = torch.mean(self.spike_for_reg, dim=(0, 1)) / self.dt
        return torch.sum(torch.square(average - target_f)) * lambda_f

    def forward(self, x: torch.Tensor):
        # x.shape = [batch, times, features]
        self.spike_for_reg = torch.empty(
            [x.shape[0], x.shape[1], (self.num_lif + self.num_alif)], device=self.device
        )

        if x.shape[0] == 1:
            self.v = torch.empty([x.shape[1], (self.num_lif + self.num_alif)])
            self.v_threshold = torch.empty([x.shape[1], self.num_alif])
            self.spike = torch.empty([x.shape[1], (self.num_lif + self.num_alif)])

        y_seq = []
        x = x.permute(1, 0, 2)  # [times, batch, features]

        for t in range(x.shape[0]):
            y = self.fc1(x[t])
            y = self.hidden(y)
            self.spike_for_reg[:, t] = y
            y = self.lp(y)
            y_seq.append(self.fc2(y).unsqueeze(0))

            if x.shape[1] == 1:
                if self.num_alif == 0:
                    self.v[t] = self.hidden.sub_module_1.v
                    self.v_threshold[t] = self.hidden.sub_module_2.va
                    self.spike[t] = self.hidden.sub_module_1.spike
                elif self.num_lif == 0:
                    self.v[t] = self.hidden.sub_module_2.v
                    self.v_threshold[t] = self.hidden.sub_module_2.va
                    self.spike[t] = self.hidden.sub_module_2.spike
                else:
                    self.v[t] = torch.cat(
                        [self.hidden.sub_module_1.v, self.hidden.sub_module_2.v], -1
                    )
                    self.v_threshold[t] = self.hidden.sub_module_2.va
                    self.spike[t] = torch.cat(
                        [self.hidden.sub_module_1.spike, self.hidden.sub_module_2.spike], -1
                    )

        return torch.cat(y_seq, 0)
