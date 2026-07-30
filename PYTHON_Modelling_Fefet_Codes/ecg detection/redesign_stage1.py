"""
REDESIGN Stage-1 — real-device FeFET-SNN baseline (the "auto research method").
================================================================================
Polarization-switching FeFET as the SYNAPSE (device role locked by the user), in the
proven VO2-paper LSNN (which reaches 95.83% on this exact random 1664/336 split), with
compact pF neurons and reviewer-grade metrics for an IEEE-TED submission.

Synapse = differential FeFET (config A): each weight = gain*(G+ - G-), G+ and G- each
snapped to one of the 15 MEASURED LTP conductance levels (fefet_device.measured_levels)
via a full-range log map + straight-through estimator. Differential form gives signed
weights + true zero and uses the whole 4-decade range (fixes the earlier half-range bug).
Readout fc2 is kept full-precision (analog array on-device, readout in CMOS periphery).

Training follows the proven recipe: plain cross-entropy + spike regularization (focal /
class-weighting are opt-in, off by default). Two eval passes (FP-continuous vs 15-level
quantized) give the device-faithfulness gap; energy_ledger gives the FoM.

Run:
    python redesign_stage1.py --quick            # ~15 min learnability check (subset)
    python redesign_stage1.py --epochs 40        # full Stage-1 run
    python redesign_stage1.py --probe            # init firing rate vs synaptic gain
    python redesign_stage1.py --levels 2         # device-load-bearing ablation (G6)
"""
import os
os.environ.setdefault("OMP_NUM_THREADS", "4")
os.environ.setdefault("MKL_NUM_THREADS", "4")
import sys
try:
    sys.stdout.reconfigure(encoding="utf-8")   # Windows console is cp1252 by default
except Exception:
    pass
import math
import json
import time
import gc
import argparse
import numpy as np
import torch
import torch.nn as nn
import torch.nn.init as init
import torch.nn.functional as F
import torch.utils.data as data
from spikingjelly.clock_driven import neuron, functional

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "REDESIGN", "code"))

from surrogate import ScaledPiecewiseQuadratic
from utils import absId
from dataset import DeltaTransformedECG, loader
from model import LPFilter, DelayedLinear, LinearDualRecurrentContainer, VO2LSNN
from fefet_synapse import log_levels, ste_quantize
from fefet_device import measured_levels
from metrics import ecg_report, format_report
import energy_ledger

torch.set_num_threads(4)


# ------------------------------------------------------------------ device map
class DeviceMap:
    """Latent weights -> MEASURED 15-level FeFET conductance (partial polarization
    switching). map_g: one unbounded latent -> conductance in (0, g_max], full range,
    STE-snapped to a measured level. differential: signed weight = gain*(G+ - G-)/g_max.

    quant=False -> continuous conductance (FP upper-bound eval pass).
    n_levels!=15 -> geomspace over the measured span (load-bearing ablation, G6).
    """
    def __init__(self, n_levels=15, gain=6.0):
        self.n_levels = n_levels
        lv, g_min, g_max = measured_levels()
        self.g_min, self.g_max = g_min, g_max
        self.levels = lv if n_levels == lv.numel() else log_levels(g_min, g_max, n_levels)
        self.quant = True
        self.gain = gain

    def map_g(self, w):
        frac = torch.sigmoid(w)                        # full (0,1) -> whole level range
        g = self.g_min * (self.g_max / self.g_min) ** frac
        if self.quant:
            g = ste_quantize(g, self.levels.to(w.device))
        return g / self.g_max                          # normalized (0, 1]

    def differential(self, w_pos, w_neg):
        return self.gain * (self.map_g(w_pos) - self.map_g(w_neg))   # signed, ~[-gain, gain]


DEV = DeviceMap()   # module-global so eval can flip DEV.quant for the two passes


# ------------------------------------------------------------- FeFET synapse layer
class FeFETDiffDelayedLinear(DelayedLinear):
    """DelayedLinear whose weight is a differential FeFET conductance pair (G+ - G-).
    Adds a second latent (weight_neg); the delay machinery is untouched."""
    def __init__(self, *a, **k):
        super().__init__(*a, **k)
        self.weight_neg = nn.Parameter(torch.empty_like(self.weight))
        with torch.no_grad():
            init.normal_(self.weight_neg, mean=0.0, std=1.0 / math.sqrt(self.in_features))
            self.weight_neg.mul_(self.delay_mask.to(self.weight_neg.dtype))  # mirror delay stacking

    def forward(self, x):
        w_eff = DEV.differential(self.weight, self.weight_neg)
        delay_masked_weight = torch.transpose(
            torch.where(self.delay_mask, w_eff, torch.zeros_like(w_eff)), dim0=0, dim1=1)
        self.out_buf = self.out_buf + self.einsum_bi_ijk_bjk(x, delay_masked_weight)
        out = self.out_buf[:, :, 0]
        self.roll()
        return out


# ------------------------------------------------------------- FeFET neurons
# Effective-parameter reparam of the proven eLIFVO2/ALIFVO2 dynamics (numerically
# identical), expressed so the physical caps are 1 pF and the time constants come from
# a subthreshold CMOS leak (G_leak = C/tau), not the non-volatile FeFET. (REDESIGN/03.)
class FeFETLIF(neuron.BaseNode):
    def __init__(self, tau_mem, g_in, dt, refractory,
                 v_threshold, v_reset, surrogate_function):
        super().__init__(v_threshold, v_reset, surrogate_function, detach_reset=False)
        self.factor = float(np.exp(-dt / tau_mem))          # python float -> device-agnostic
        self.g_in = g_in
        self.dt = dt
        self.refractory = refractory
        self.v = 0.
        self.register_memory('spike', 0)
        self.register_memory('spike_countdown', None)
        self.register_memory('is_refractory', 0)

    def neuronal_charge(self, x):
        x = torch.relu(x)
        v = self.factor * self.v + (1 - self.factor) * (self.g_in * x)
        self.v = torch.where(self.is_refractory, self.v, v)

    def neuronal_fire(self):
        spike = self.surrogate_function((self.v - self.v_threshold) / self.v_threshold)
        with torch.no_grad():
            if self.spike_countdown is None:
                shape = list(spike.shape); shape.append(max(self.refractory, 1))
                self.spike_countdown = torch.zeros(shape, device=spike.device)
        spike = torch.where(self.is_refractory, torch.zeros_like(spike), spike)
        self.spike = spike
        self.spike_countdown = torch.cat(
            [self.spike_countdown[:, :, 1:], torch.unsqueeze(spike, dim=-1)], dim=-1)
        return self.spike

    def neuronal_reset(self, spike):
        self.v = (1. - spike) * self.v + spike * self.v_reset

    def forward(self, x):
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
        self.is_refractory = (torch.gt(torch.amax(self.spike_countdown[..., -self.refractory:], dim=-1), 0)
                              if self.refractory > 0 else torch.zeros_like(self.v, dtype=torch.bool))
        return new_spike


class FeFETALIF(neuron.BaseNode):
    def __init__(self, tau_mem, tau_va, g_in, g_adapt, r_adapt, dt, refractory,
                 v_threshold, v_reset, vtn, vtp, kappa_n, kappa_p,
                 wl_ratio_n, wl_ratio_p, Vdd, surrogate_function):
        super().__init__(v_threshold, v_reset, surrogate_function, detach_reset=False)
        self.factor = float(np.exp(-dt / tau_mem))          # python float -> device-agnostic
        self.factor_va = float(np.exp(-dt / tau_va))
        self.g_in = g_in
        self.g_adapt = g_adapt
        self.r_adapt = r_adapt
        self.dt = dt
        self.refractory = refractory
        self.vtn, self.vtp = vtn, vtp
        self.kappa_n, self.kappa_p = kappa_n, kappa_p
        self.wl_ratio_n, self.wl_ratio_p = wl_ratio_n, wl_ratio_p
        self.Vdd = Vdd
        self.v = 0.
        self.register_memory('va', 0.)
        self.register_memory('spike', 0)
        self.register_memory('spike_countdown', None)
        self.register_memory('is_refractory', 0)

    def neuronal_charge(self, x):
        x = torch.relu(x)
        Il = absId(kappa=self.kappa_n, w_over_l=self.wl_ratio_n, vgs=self.va,
                   vth=self.vtn, vds=self.v)
        v = self.factor * self.v + (1 - self.factor) * (self.g_in * x - self.g_adapt * Il)
        self.v = torch.where(self.is_refractory, self.v, v)

    def neuronal_fire(self):
        spike = self.surrogate_function((self.v - self.v_threshold) / self.v_threshold)
        with torch.no_grad():
            if self.spike_countdown is None:
                shape = list(spike.shape); shape.append(max(self.refractory, 1))
                self.spike_countdown = torch.zeros(shape, device=spike.device)
        spike = torch.where(self.is_refractory, torch.zeros_like(spike), spike)
        self.spike = spike
        self.spike_countdown = torch.cat(
            [self.spike_countdown[:, :, 1:], torch.unsqueeze(spike, dim=-1)], dim=-1)
        return self.spike

    def neuronal_reset(self, spike):
        self.v = (1. - spike) * self.v + spike * self.v_reset

    def neuronal_adapt(self, spike):
        Ia = absId(kappa=self.kappa_p, w_over_l=self.wl_ratio_p, vgs=(self.Vdd * spike),
                   vth=self.vtp, vds=(self.Vdd - self.va))
        self.va = self.factor_va * self.va + (1 - self.factor_va) * self.r_adapt * Ia

    def forward(self, x):
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
        self.is_refractory = (torch.gt(torch.amax(self.spike_countdown[..., -self.refractory:], dim=-1), 0)
                              if self.refractory > 0 else torch.zeros_like(self.v, dtype=torch.bool))
        return new_spike


# ------------------------------------------------------------- Stage-1 network
class Stage1LSNN(nn.Module):
    """Input -> FeFET DelayedFC -> recurrent[FeFET-LIF | FeFET-ALIF] (FeFET rc) -> LP -> readout.
    Bulk synapses (fc1, recurrent rc) are on-device differential FeFET; readout fc2 is CMOS FP."""
    def __init__(self, num_in, num_lif, num_alif, num_out, tau_lp,
                 tau_mem, tau_va, g_in, g_adapt, r_adapt,
                 v_threshold, v_reset, vtn, vtp, kappa_n, kappa_p,
                 wl_ratio_n, wl_ratio_p, Vdd, dt, max_delay, refractory, device,
                 alpha0=1.0, synapse="fefet"):
        super().__init__()
        surr = lambda: ScaledPiecewiseQuadratic(alpha=alpha0, gamma=0.3)
        Lin = FeFETDiffDelayedLinear if synapse == "fefet" else DelayedLinear
        self.synapse = synapse
        self.fc1 = Lin(num_in, num_lif + num_alif, bias=False, max_delay=max_delay)
        self.hidden = LinearDualRecurrentContainer(
            sub_module_1=FeFETLIF(tau_mem=tau_mem, g_in=g_in, dt=dt, refractory=refractory,
                                  v_threshold=v_threshold, v_reset=v_reset, surrogate_function=surr()),
            sub_module_2=FeFETALIF(tau_mem=tau_mem, tau_va=tau_va, g_in=g_in, g_adapt=g_adapt,
                                   r_adapt=r_adapt, dt=dt, refractory=refractory,
                                   v_threshold=v_threshold, v_reset=v_reset,
                                   vtn=vtn, vtp=vtp, kappa_n=kappa_n, kappa_p=kappa_p,
                                   wl_ratio_n=wl_ratio_n, wl_ratio_p=wl_ratio_p, Vdd=Vdd,
                                   surrogate_function=surr()),
            in_features=(num_lif + num_alif), out_features_1=num_lif, out_features_2=num_alif,
            bias=False, max_delay=max_delay)
        # FeFET-ize the recurrent connection too (same delay machinery, diag-disconnected)
        if synapse == "fefet":
            self.hidden.rc = FeFETDiffDelayedLinear(num_lif + num_alif, num_lif + num_alif,
                                                    bias=False, max_delay=max_delay, diag_disconnect=True)
        self.lp = LPFilter(tau=tau_lp, dt=dt)
        self.fc2 = nn.Linear(num_lif + num_alif, num_out, bias=False)   # CMOS full-precision readout
        self.num_lif, self.num_alif = num_lif, num_alif
        self.dt = dt
        self.device = device
        self.spike_for_reg = None

    def set_surrogate_alpha(self, alpha):
        for m in self.modules():
            if isinstance(m, (FeFETLIF, FeFETALIF)):
                m.surrogate_function.alpha = alpha

    def spike_regularization(self, target_f=15.0, lambda_f=5e-7):
        average = torch.mean(self.spike_for_reg, dim=(0, 1)) / self.dt
        return torch.sum(torch.square(average - target_f)) * lambda_f

    def forward(self, x):
        self.spike_for_reg = torch.empty(
            [x.shape[0], x.shape[1], self.num_lif + self.num_alif], device=self.device)
        y_seq = []
        x = x.permute(1, 0, 2)
        for t in range(x.shape[0]):
            y = self.fc1(x[t])
            y = self.hidden(y)
            self.spike_for_reg[:, t] = y
            y = self.lp(y)
            y_seq.append(self.fc2(y).unsqueeze(0))
        return torch.cat(y_seq, 0)


# ------------------------------------------------------------- loss / eval
def readout(seq, mode, k):
    """seq: [times, batch, num_out]. 'last' = final timestep (original); 'meancue' = mean over
    the last k (decision-window) steps; 'meanall' = mean over all steps. Mean-pooling gives the
    classifier integrated class evidence and a much stronger gradient than a single decayed step."""
    if mode == "meancue":
        return seq[-k:].mean(0)
    if mode == "meanall":
        return seq.mean(0)
    return seq[-1]


def focal_loss(logits, target, weight, gamma=2.0):
    logp = F.log_softmax(logits, dim=1)
    ce = F.nll_loss(logp, target, weight=weight, reduction='none')
    pt = logp.gather(1, target.unsqueeze(1)).squeeze(1).exp()
    return ((1.0 - pt) ** gamma * ce).mean()


@torch.no_grad()
def evaluate(model, test_loader, device, quant, rmode="last", k=116):
    DEV.quant = quant
    model.eval()
    y_true, y_pred = [], []
    for ecg, label in loader(test_loader, device):
        out = readout(model(ecg.float()), rmode, k)
        functional.reset_net(model)
        y_pred.extend(out.max(1)[1].cpu().numpy().tolist())
        y_true.extend(label.cpu().numpy().tolist())
    return ecg_report(y_true, y_pred, classes=["N", "F", "SVEB", "VEB"])


# ------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--epochs", type=int, default=40)
    ap.add_argument("--levels", type=int, default=15, help="FeFET levels (2 = ablation)")
    ap.add_argument("--gain", type=float, default=6.0, help="synaptic readout gain")
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--sched_epochs", type=int, default=0,
                    help="cosine LR decay horizon in epochs (0=use --epochs); extra epochs run at eta_min")
    ap.add_argument("--warmup", type=int, default=0, help="linear LR warmup epochs (0->lr) before cosine")
    ap.add_argument("--eta_ratio", type=float, default=1e-2, help="LR floor as fraction of peak lr (held after decay)")
    ap.add_argument("--spike_lambda", type=float, default=5e-7, help="spike-rate regularization strength")
    ap.add_argument("--spike_target", type=float, default=15.0, help="target firing rate (Hz) for reg")
    ap.add_argument("--batch", type=int, default=128, help="batch size (lower = less memory)")
    ap.add_argument("--num_lif", type=int, default=60)
    ap.add_argument("--num_alif", type=int, default=40)
    ap.add_argument("--max_delay", type=int, default=10)
    ap.add_argument("--loss", choices=["ce", "focal"], default="ce")
    ap.add_argument("--classweight", action="store_true", help="class-balanced loss weighting")
    ap.add_argument("--balance", dest="balance", action="store_true", help="balanced batch sampling (default on)")
    ap.add_argument("--no-balance", dest="balance", action="store_false")
    ap.set_defaults(balance=True)
    ap.add_argument("--anneal", action="store_true", help="anneal surrogate width wide->narrow")
    ap.add_argument("--fp_warmup", type=int, default=0,
                    help="epochs of continuous (FP) training before enabling 15-level STE quantization")
    ap.add_argument("--synapse", choices=["fefet", "plain"], default="fefet",
                    help="plain = original DelayedLinear weights (diagnostic baseline)")
    ap.add_argument("--model", choices=["stage1", "orig"], default="stage1",
                    help="orig = proven VO2LSNN (model.py) with original RC neurons, refractory=5")
    ap.add_argument("--data", choices=["intra", "interpatient", "intra2lead", "inter2lead", "intra1lead"],
                    default="intra",
                    help="npz datasets: interpatient (1-lead VO2), intra2lead/inter2lead/intra1lead (delta, ALLDEVICE)")
    ap.add_argument("--quick", action="store_true", help="~15 min learnability check on a subset")
    ap.add_argument("--probe", action="store_true", help="report init firing rate vs gain, then exit")
    ap.add_argument("--overfit", type=int, default=0,
                    help="train N gradient steps on ONE fixed batch (sanity: can the model learn at all?)")
    ap.add_argument("--readout", choices=["last", "meancue", "meanall"], default="meancue",
                    help="output pooling: last timestep, mean over decision window, or mean over all")
    ap.add_argument("--tag", type=str, default="stage1")
    args = ap.parse_args()

    global DEV
    DEV = DeviceMap(n_levels=args.levels, gain=args.gain)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"[device] {device}" + (f" ({torch.cuda.get_device_name(0)})" if device.type == "cuda" else " (no GPU — slow)"))
    torch.manual_seed(100)

    F_ = dict(num_in=3, num_lif=args.num_lif, num_alif=args.num_alif, num_out=4,
              max_delay=args.max_delay, refractory=0,
              dt=5.556e-4, tau_lp=11.11e-3,
              tau_mem=11.11e-3, tau_va=0.7, g_in=77.5, g_adapt=7830.0, r_adapt=100e3,
              v_threshold=3.6, v_reset=1.5,
              vtn=0.745, vtp=0.973, kappa_n=29e-6, kappa_p=18e-6,
              wl_ratio_n=16, wl_ratio_p=8, Vdd=5.0,
              spike_reg_lambda=5e-7, spike_reg_target_f=15.0, focal_gamma=2.0,
              grad_clip=1.0, batch_size=args.batch, out_cue=116,
              alpha_start=1.0, alpha_end=2.0)

    data_dir = os.path.join(_HERE, "data_ecg")
    out_dir = os.path.join(_HERE, "REDESIGN", "runs", args.tag)
    os.makedirs(out_dir, exist_ok=True)

    from sklearn.utils.class_weight import compute_class_weight
    NPZ = {"interpatient": os.path.join(_HERE, "interpatient_data.npz"),
           "intra2lead": os.path.join(_HERE, "ALLDEVICE", "intra_2lead.npz"),
           "inter2lead": os.path.join(_HERE, "ALLDEVICE", "inter_2lead.npz"),
           "intra1lead": os.path.join(_HERE, "ALLDEVICE", "intra_1lead.npz")}
    if args.data in NPZ:
        npz = np.load(NPZ[args.data])
        F_["num_in"] = int(npz["X_train"].shape[-1])          # auto: 3 (1-lead) or 5 (2-lead)
        print(f"[data] {args.data} npz | {npz['X_train'].shape[-1]} input channels")
        train_ds = data.TensorDataset(torch.from_numpy(npz["X_train"]).float(),
                                      torch.from_numpy(npz["y_train"]).long())
        test_ds = data.TensorDataset(torch.from_numpy(npz["X_test"]).float(),
                                     torch.from_numpy(npz["y_test"]).long())
        train_ds.labels = torch.from_numpy(npz["y_train"]).long()
        test_ds.labels = torch.from_numpy(npz["y_test"]).long()
        cw = torch.Tensor(compute_class_weight('balanced', classes=np.arange(4),
                          y=npz["y_train"])).to(device)
    else:
        print(f"[data] loading {data_dir}")
        ds = DeltaTransformedECG(path=data_dir, output_cue_length=F_["out_cue"], n_class=4)
        train_ds, test_ds = data.random_split(ds, [1664, 336],
                                              generator=torch.Generator().manual_seed(100))
        cw = torch.Tensor(compute_class_weight('balanced', classes=ds.get_classes(),
                          y=train_ds.dataset.labels[train_ds.indices].numpy())).to(device)
    loss_weight = cw if args.classweight else None

    epochs = args.epochs
    if args.quick:
        epochs = 4
        train_ds = data.Subset(train_ds, list(range(384)))   # 3 batches
        test_ds = data.Subset(test_ds, list(range(128)))
    def resolve_labels(subds):
        if isinstance(subds, data.Subset):
            return resolve_labels(subds.dataset)[np.asarray(subds.indices)]
        return subds.labels.numpy()

    bs = F_["batch_size"]
    if args.balance:
        tl = resolve_labels(train_ds).astype(int)
        counts = np.bincount(tl, minlength=F_["num_out"]).astype(float)
        per_sample_w = 1.0 / counts[tl]
        sampler = data.WeightedRandomSampler(torch.as_tensor(per_sample_w, dtype=torch.double),
                                             num_samples=len(train_ds), replacement=True)
        train_loader = data.DataLoader(train_ds, batch_size=bs, sampler=sampler, drop_last=True)
    else:
        train_loader = data.DataLoader(train_ds, batch_size=bs, shuffle=True, drop_last=True)
    test_loader = data.DataLoader(test_ds, batch_size=bs, shuffle=False, drop_last=False)
    print(f"[data] {len(train_ds)} train / {len(test_ds)} test | loss={args.loss} "
          f"balance={args.balance} classweight={args.classweight} | train class counts="
          f"{np.bincount(resolve_labels(train_ds).astype(int), minlength=F_['num_out'])}")

    if args.model == "orig":
        # Proven RC VO2LSNN (model.py). eLIFVO2 needs refractory>0, so use 5.
        model = VO2LSNN(
            num_in=F_["num_in"], num_lif=F_["num_lif"], num_alif=F_["num_alif"], num_out=F_["num_out"],
            tau=F_["tau_mem"], tau_lp=F_["tau_lp"], Rh=5250., Rs=2580., Ra=F_["r_adapt"],
            Cmem=1.419e-6, Ca=5556e-9, v_threshold=F_["v_threshold"], v_reset=F_["v_reset"],
            vtn=F_["vtn"], vtp=F_["vtp"], kappa_n=F_["kappa_n"], kappa_p=F_["kappa_p"],
            wl_ratio_n=F_["wl_ratio_n"], wl_ratio_p=F_["wl_ratio_p"], Vdd=F_["Vdd"],
            input_scaling=9900e-6, dt=F_["dt"], max_delay=F_["max_delay"], refractory=5,
            device=device).to(device)
    else:
        model = Stage1LSNN(
            num_in=F_["num_in"], num_lif=F_["num_lif"], num_alif=F_["num_alif"], num_out=F_["num_out"],
            tau_lp=F_["tau_lp"], tau_mem=F_["tau_mem"], tau_va=F_["tau_va"], g_in=F_["g_in"],
            g_adapt=F_["g_adapt"], r_adapt=F_["r_adapt"], v_threshold=F_["v_threshold"],
            v_reset=F_["v_reset"], vtn=F_["vtn"], vtp=F_["vtp"], kappa_n=F_["kappa_n"],
            kappa_p=F_["kappa_p"], wl_ratio_n=F_["wl_ratio_n"], wl_ratio_p=F_["wl_ratio_p"],
            Vdd=F_["Vdd"], dt=F_["dt"], max_delay=F_["max_delay"], refractory=F_["refractory"],
            device=device, alpha0=(F_["alpha_start"] if args.anneal else 1.0),
            synapse=args.synapse).to(device)
    n_params = sum(p.numel() for p in model.parameters())
    print(f"[model] {args.model} | {n_params:,} params | FeFET levels={args.levels} | gain={args.gain}")

    if args.probe:
        model.eval()
        ecg, _ = next(iter(loader(train_loader, device)))
        print("[probe] init firing rate vs synaptic gain (target ~10-50 Hz):")
        for gain in [1.0, 3.0, 6.0, 10.0, 16.0, 24.0, 40.0]:
            DEV.gain = gain
            with torch.no_grad():
                model(ecg.float()); fr = model.spike_for_reg.mean().item() / F_["dt"]
                functional.reset_net(model)
            print(f"  gain={gain:5.1f} -> init FR = {fr:8.1f} Hz")
        return

    if args.overfit > 0:
        # Can the model fit ONE fixed batch? If not -> concrete bug in model/loop.
        ecg, label = next(iter(train_loader))
        ecg, label = ecg.to(device).float(), label.to(device)
        print(f"[overfit] one fixed batch, labels={np.bincount(label.cpu().numpy(), minlength=4)}")
        opt = torch.optim.Adam(model.parameters(), lr=args.lr)
        DEV.quant = (args.fp_warmup == 0)
        for step in range(args.overfit):
            opt.zero_grad()
            out = readout(model(ecg), args.readout, F_["out_cue"])
            loss = F.cross_entropy(out, label)
            loss.backward()
            gnorm = torch.nn.utils.clip_grad_norm_(model.parameters(), F_["grad_clip"]).item()
            # per-layer grad norms (are gradients reaching fc1/rc, or only fc2?)
            g = {n: (p.grad.norm().item() if p.grad is not None else 0.0)
                 for n, p in model.named_parameters()}
            gfc1 = sum(v for k, v in g.items() if "fc1" in k)
            grc = sum(v for k, v in g.items() if ".rc." in k or "hidden.rc" in k)
            gfc2 = sum(v for k, v in g.items() if "fc2" in k)
            opt.step()
            functional.reset_net(model)
            with torch.no_grad():
                acc = (out.max(1)[1] == label).float().mean().item()
                logit_std = out.std().item()
            print(f"  step {step:3d}: loss={loss.item():.4f} acc={acc:.4f} logit_std={logit_std:.3f} "
                  f"|g|={gnorm:.3e} (fc1={gfc1:.2e} rc={grc:.2e} fc2={gfc2:.2e})")
        return

    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)
    train_batches = max(len(train_loader), 1)
    horizon = args.sched_epochs if args.sched_epochs > 0 else epochs
    warmup_steps = args.warmup * train_batches
    cos_total = max(horizon * train_batches - warmup_steps, 1)
    eta_ratio = args.eta_ratio                             # min LR = lr * eta_ratio (held after decay)
    def lr_lambda(step):
        if step < warmup_steps:                            # linear warmup 0 -> lr
            return (step + 1) / max(warmup_steps, 1)
        prog = min((step - warmup_steps) / cos_total, 1.0) # cosine, then frozen at floor (no rebound)
        return eta_ratio + (1 - eta_ratio) * 0.5 * (1 + math.cos(math.pi * prog))
    scheduler = torch.optim.lr_scheduler.LambdaLR(optimizer, lr_lambda)

    history = []
    best_macro_f1 = -1.0
    t0 = time.time()
    for epoch in range(epochs):
        if args.anneal and hasattr(model, "set_surrogate_alpha"):
            alpha = F_["alpha_start"] + (F_["alpha_end"] - F_["alpha_start"]) * epoch / max(epochs - 1, 1)
            model.set_surrogate_alpha(alpha)
        else:
            alpha = 1.0
        model.train()
        quant_on = epoch >= args.fp_warmup            # FP-continuous warmup, then 15-level STE
        DEV.quant = quant_on
        phase = "quant" if quant_on else "FP-warmup"
        seen = tr_correct = tr_total = 0
        ep_loss = ep_fr = 0.0
        for ecg, label in loader(train_loader, device):
            optimizer.zero_grad()
            out = readout(model(ecg.float()), args.readout, F_["out_cue"])
            if args.loss == "focal":
                loss = focal_loss(out, label, loss_weight, gamma=F_["focal_gamma"])
            else:
                loss = F.cross_entropy(out, label, weight=loss_weight)
            loss = loss + model.spike_regularization(args.spike_target, args.spike_lambda)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), F_["grad_clip"])
            optimizer.step()
            scheduler.step()
            with torch.no_grad():
                ep_fr += model.spike_for_reg.mean().item() / F_["dt"]
                tr_correct += (out.max(1)[1] == label).sum().item()
                tr_total += label.numel()
            functional.reset_net(model)
            ep_loss += loss.item()
            seen += 1
            del out, loss                              # free the BPTT graph + activations promptly
        gc.collect()                                   # curb fragmentation (5.9 GB box OOM'd at ep28)
        train_acc = tr_correct / max(tr_total, 1)

        rep_dev = evaluate(model, test_loader, device, quant=True, rmode=args.readout, k=F_["out_cue"])
        last = (epoch == epochs - 1)
        rep_fp = evaluate(model, test_loader, device, quant=False, rmode=args.readout, k=F_["out_cue"]) if last else None
        dt_min = (time.time() - t0) / 60
        print(f"\n=== epoch {epoch} [{phase}] | a={alpha:.2f} | loss={ep_loss/max(seen,1):.4f} "
              f"| train_acc={train_acc:.4f} | FR={ep_fr/max(seen,1):.1f}Hz | {dt_min:.1f}min ===")
        print("[15-level device]  " + format_report(rep_dev))
        if rep_fp is not None:
            print("[FP  continuous ]  acc=%.4f macro_F1=%.4f kappa=%.4f"
                  % (rep_fp["accuracy"], rep_fp["macro_f1"], rep_fp["kappa"]))
            print("  device-faithfulness gap (FP->quant) macro_F1: %.4f -> %.4f (delta=%.4f)"
                  % (rep_fp["macro_f1"], rep_dev["macro_f1"], rep_fp["macro_f1"] - rep_dev["macro_f1"]))
        history.append({"epoch": epoch, "loss": ep_loss/max(seen,1), "train_acc": train_acc,
                        "fr_hz": ep_fr/max(seen,1), "device": rep_dev, "fp": rep_fp})
        if rep_dev["macro_f1"] >= best_macro_f1:
            best_macro_f1 = rep_dev["macro_f1"]
            torch.save({"net": model.state_dict(), "epoch": epoch, "report": rep_dev},
                       os.path.join(out_dir, f"{args.tag}_best.ckpt"))
        with open(os.path.join(out_dir, f"{args.tag}_history.json"), "w") as fp:
            json.dump(history, fp, indent=2)

    # ---- FoM budget (the headline) ----
    fr = history[-1]["fr_hz"] if history else 15.0
    spikes_per_neuron = max(fr * F_["dt"] * energy_ledger.T_STEPS, 0.1)
    L = energy_ledger.budget(spikes_per_neuron=spikes_per_neuron, read_fraction=1.0)
    best_acc = max((h["device"]["accuracy"] for h in history), default=0.0)
    print(f"\n{'='*64}\nSTAGE-1 SUMMARY ({args.tag}, {args.levels}-level)")
    print(f"  best device accuracy : {best_acc:.4f}")
    print(f"  best device macro-F1 : {best_macro_f1:.4f}")
    print(f"  energy / beat        : {energy_ledger._fmt(L.total_J,'J')}  (gate < 10 nJ)")
    print(f"  cap total / neuron   : {energy_ledger._fmt(L.total_cap_F,'F')} / "
          f"{energy_ledger._fmt(energy_ledger.C_MEM,'F')}  (gate < 1 nF)")
    print(f"{'='*64}")
    with open(os.path.join(out_dir, f"{args.tag}_summary.json"), "w") as fp:
        json.dump({"best_accuracy": best_acc, "best_macro_f1": best_macro_f1,
                   "energy_J_per_beat": L.total_J, "cap_total_F": L.total_cap_F,
                   "levels": args.levels, "gain": args.gain}, fp, indent=2)


if __name__ == "__main__":
    main()
