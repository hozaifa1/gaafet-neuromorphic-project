"""
Stage-1 trainer/eval for the FeFET ECG-LSNN (configs A/B/C).  The single file the
autoresearch loop edits.  REDESIGN/02_PLAN.md s1 + 03_INTEGRATION.md.

Goal = maximize macro-F1 (device-quantized) while the FoM gates hold (analytic, see
energy_ledger).  No KD, no noise injection (Stage 1).  Reports BOTH eval passes
(FP-latent upper bound vs 15-level device) -> the gap is the device-faithfulness result.

Run:
  MODE=calib  CONFIG=A python train_stage1.py     # sweep input_scaling, 1 short epoch, print FR
  MODE=train  CONFIG=A EPOCHS=30 python train_stage1.py
env knobs: CONFIG{A,B,C} MODE{calib,train,smoke} EPOCHS NLEVELS DATA_DIR OUT_DIR SEED
"""
import os
os.environ.setdefault("OMP_NUM_THREADS", "4")
os.environ.setdefault("MKL_NUM_THREADS", "4")
import json
import time
import numpy as np
import torch
import torch.nn.functional as F
import torch.utils.data as data
torch.set_num_threads(int(os.environ.get("OMP_NUM_THREADS", "4")))

from sklearn.utils.class_weight import compute_class_weight
from spikingjelly.clock_driven import functional

from dataset import DeltaTransformedECG
from fefet_lsnn import build
from fefet_layers import set_quantize
from metrics import ecg_report, format_report
import energy_ledger as EL

# ---------------- FLAGS (autoresearch edits these) ----------------
FLAGS = dict(
    num_in=3, num_lif=60, num_alif=40, num_out=4, max_delay=10, refractory=0,
    out_cue_duration=116, dt=5.556e-4, tau_lp=11.11e-3,
    batch_size=128, lr=1e-3, grad_clip_norm=1.0, weight_decay=0.0,
    focal_gamma=2.0, apply_class_weights=True,
    spike_reg=True, spike_reg_lambda=5e-7, spike_reg_target_f=15.0,
    # surrogate width anneal: wide (small alpha) -> narrow (large alpha) over epochs (R3 s1.2)
    surrogate_alpha_start=0.5, surrogate_alpha_end=1.5, surrogate_gamma=0.3,
    # compact-neuron operating point (primary tunables; FeFET weights shift firing)
    c_mem=1e-12, c_a=1e-12, v_threshold=3.6, v_reset=1.5, input_scaling=2.3e-9,
)
CONFIG = os.environ.get("CONFIG", "A").upper()
MODE = os.environ.get("MODE", "train")
EPOCHS = int(os.environ.get("EPOCHS", "30"))
N_LEVELS = int(os.environ.get("NLEVELS", "15"))     # 2 = binary ablation (G6)
SEED = int(os.environ.get("SEED", "100"))
DATA_DIR = os.environ.get("DATA_DIR", os.path.join(os.path.dirname(__file__), "data_ecg"))
OUT_DIR = os.environ.get("OUT_DIR", os.path.join(os.path.dirname(__file__), "outputs"))
os.makedirs(OUT_DIR, exist_ok=True)


def make_model(device, input_scaling=None, n_levels=None):
    return build(
        CONFIG, num_in=FLAGS["num_in"], num_lif=FLAGS["num_lif"], num_alif=FLAGS["num_alif"],
        num_out=FLAGS["num_out"], tau_lp=FLAGS["tau_lp"], dt=FLAGS["dt"],
        max_delay=FLAGS["max_delay"], refractory=FLAGS["refractory"],
        c_mem=FLAGS["c_mem"], c_a=FLAGS["c_a"], v_threshold=FLAGS["v_threshold"],
        v_reset=FLAGS["v_reset"],
        input_scaling=FLAGS["input_scaling"] if input_scaling is None else input_scaling,
        n_levels=N_LEVELS if n_levels is None else n_levels,
        surrogate_alpha=FLAGS["surrogate_alpha_start"], surrogate_gamma=FLAGS["surrogate_gamma"],
        device=device,
    ).to(device)


def load_data(device):
    ds = DeltaTransformedECG(path=DATA_DIR, output_cue_length=FLAGS["out_cue_duration"],
                             n_class=FLAGS["num_out"])
    n = len(ds); n_test = 336 if n >= 2000 else max(1, n // 6)
    train_ds, test_ds = data.random_split(
        ds, [n - n_test, n_test], generator=torch.Generator().manual_seed(SEED))
    y_train = train_ds.dataset.labels[train_ds.indices].numpy()
    cw = torch.Tensor(compute_class_weight(
        "balanced" if FLAGS["apply_class_weights"] else None,
        classes=ds.get_classes(), y=y_train)).to(device)
    bs = FLAGS["batch_size"]
    tl = data.DataLoader(train_ds, batch_size=bs, shuffle=True, drop_last=True)
    vl = data.DataLoader(test_ds, batch_size=bs, shuffle=False, drop_last=False)
    return ds, tl, vl, cw


def focal_loss(logits, target, weight, gamma):
    logp = F.log_softmax(logits, dim=-1)
    ce = F.nll_loss(logp, target, weight=weight, reduction="none")   # class-weighted
    pt = logp.gather(1, target.unsqueeze(1)).squeeze(1).exp()
    return ((1.0 - pt) ** gamma * ce).mean()


@torch.no_grad()
def evaluate(model, loader, device, quantize):
    set_quantize(quantize)
    model.eval()
    y_true, y_pred = [], []
    spk_per_neuron = 0.0; nb = 0
    for ecg, label in loader:
        ecg, label = ecg.float().to(device), label.to(device)
        out = model(ecg)[-1]
        functional.reset_net(model)
        y_pred.extend(out.max(1)[1].cpu().tolist()); y_true.extend(label.cpu().tolist())
        spk_per_neuron += model.spike_for_reg.sum(dim=1).mean().item(); nb += 1
    set_quantize(True)
    return y_true, y_pred, spk_per_neuron / max(nb, 1)


def compute_ledger(spikes_per_neuron):
    """config-aware cap/energy ledger (device-quantized op point)."""
    n_neuron = FLAGS["num_lif"] + FLAGS["num_alif"]
    n_syn = (FLAGS["num_in"] * n_neuron + n_neuron * n_neuron + n_neuron * FLAGS["num_out"])
    differential = (CONFIG != "B")
    c_mem = 0.0 if CONFIG == "C" else FLAGS["c_mem"]
    e_read = EL.V_READ ** 2 * EL.G_REPR * EL.T_READ
    t_steps = EL.T_STEPS
    syn_E = t_steps * n_syn * e_read
    e_event = 0.5 * c_mem * EL.V_SWING ** 2
    neuron_E = n_neuron * spikes_per_neuron * e_event
    total_cap = n_neuron * c_mem
    latency_s = t_steps * FLAGS["dt"]
    return dict(n_devices=n_syn * (2 if differential else 1), n_syn=n_syn,
                syn_E_J=syn_E, neuron_E_J=neuron_E, total_J=syn_E + neuron_E,
                total_cap_F=total_cap, c_mem_F=c_mem, latency_s=latency_s)


def run_calib(device):
    _, tl, _, cw = load_data(device)
    cands = [float(x) for x in os.environ.get(
        "ISCALE_LIST", "1e-9,3e-9,6.976e-9,1.5e-8,5e-8").split(",")]
    print(f"[calib] CONFIG={CONFIG} sweeping input_scaling over {cands}")
    for isc in cands:
        torch.manual_seed(SEED)
        model = make_model(device, input_scaling=isc)
        opt = torch.optim.Adam(model.parameters(), lr=FLAGS["lr"])
        model.train(); fr = 0.0; nb = 0; correct = 0; total = 0
        t0 = time.time()
        for i, (ecg, label) in enumerate(tl):
            if i >= 2:
                break
            ecg, label = ecg.float().to(device), label.to(device)
            opt.zero_grad()
            out = model(ecg)[-1]
            loss = focal_loss(out, label, cw, FLAGS["focal_gamma"])
            loss.backward(); opt.step(); functional.reset_net(model)
            fr += model.spike_for_reg.mean().item() / FLAGS["dt"]; nb += 1
            correct += (out.max(1)[1] == label).sum().item(); total += label.numel()
        dt_batch = (time.time() - t0) / max(nb, 1)
        print(f"  input_scaling={isc:.3e}  FR={fr/max(nb,1):7.2f} Hz  "
              f"train_acc={correct/max(total,1):.3f}  loss={loss.item():.3f}  "
              f"{dt_batch:.1f}s/batch")


def run_train(device):
    ds, tl, vl, cw = load_data(device)
    torch.manual_seed(SEED)
    model = make_model(device)
    n_params = sum(p.numel() for p in model.parameters())
    opt = torch.optim.Adam(model.parameters(), lr=FLAGS["lr"], weight_decay=FLAGS["weight_decay"])
    sched = torch.optim.lr_scheduler.CosineAnnealingLR(opt, T_max=EPOCHS, eta_min=FLAGS["lr"] * 1e-2)
    print(f"[train] CONFIG={CONFIG} levels={N_LEVELS} epochs={EPOCHS} params={n_params:,} "
          f"v_th={FLAGS['v_threshold']} iscale={FLAGS['input_scaling']:.3e}")

    best = dict(macro_f1=-1.0)
    a0, a1 = FLAGS["surrogate_alpha_start"], FLAGS["surrogate_alpha_end"]
    for epoch in range(EPOCHS):
        alpha = a0 + (a1 - a0) * epoch / max(EPOCHS - 1, 1)
        model.set_surrogate_alpha(alpha)
        set_quantize(True); model.train()
        t0 = time.time(); ls = 0.0; nb = 0
        for ecg, label in tl:
            ecg, label = ecg.float().to(device), label.to(device)
            opt.zero_grad()
            out = model(ecg)[-1]
            loss = focal_loss(out, label, cw, FLAGS["focal_gamma"])
            if FLAGS["spike_reg"]:
                loss = loss + model.spike_regularization(
                    target_f=FLAGS["spike_reg_target_f"], lambda_f=FLAGS["spike_reg_lambda"])
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), FLAGS["grad_clip_norm"])
            opt.step(); functional.reset_net(model)
            ls += loss.item(); nb += 1
        sched.step()
        yt, yp, spk = evaluate(model, vl, device, quantize=True)
        rep = ecg_report(yt, yp, classes=["N", "F", "S", "V"])
        print(f"ep{epoch:02d} a={alpha:.2f} loss={ls/max(nb,1):.3f} "
              f"dev: acc={rep['accuracy']:.3f} macroF1={rep['macro_f1']:.3f} "
              f"kappa={rep['kappa']:.3f} spk/neuron={spk:.1f} ({time.time()-t0:.0f}s)")
        if rep["macro_f1"] > best["macro_f1"]:
            best = dict(macro_f1=rep["macro_f1"], epoch=epoch, report=rep, spk=spk)
            torch.save({"net": model.state_dict(), "flags": FLAGS, "config": CONFIG},
                       os.path.join(OUT_DIR, f"best_{CONFIG}_L{N_LEVELS}.ckpt"))

    # ---- final: both eval passes on the best-by-dev model ----
    model.load_state_dict(torch.load(
        os.path.join(OUT_DIR, f"best_{CONFIG}_L{N_LEVELS}.ckpt"), map_location=device)["net"])
    yt, yp, spk = evaluate(model, vl, device, quantize=True)
    rep_dev = ecg_report(yt, yp, classes=["N", "F", "S", "V"])
    yt2, yp2, _ = evaluate(model, vl, device, quantize=False)
    rep_fp = ecg_report(yt2, yp2, classes=["N", "F", "S", "V"])
    led = compute_ledger(spk)

    out = dict(config=CONFIG, n_levels=N_LEVELS, epochs=EPOCHS, best_epoch=best["epoch"],
               macro_f1_dev=rep_dev["macro_f1"], macro_f1_fp=rep_fp["macro_f1"],
               accuracy_dev=rep_dev["accuracy"], kappa_dev=rep_dev["kappa"],
               quant_gap=rep_fp["macro_f1"] - rep_dev["macro_f1"],
               spikes_per_neuron=spk, ledger=led, report_dev=rep_dev, report_fp=rep_fp,
               flags=FLAGS)
    with open(os.path.join(OUT_DIR, f"metrics_{CONFIG}_L{N_LEVELS}.json"), "w") as f:
        json.dump(out, f, indent=2)

    print("\n=== DEVICE (15-level) ===\n" + format_report(rep_dev))
    print("\n=== FP latent (upper bound) ===\n" + format_report(rep_fp))
    print("\n" + "-" * 60)
    print(f"SUMMARY config={CONFIG} levels={N_LEVELS}")
    print(f"macro_f1_dev:   {rep_dev['macro_f1']:.4f}")
    print(f"macro_f1_fp:    {rep_fp['macro_f1']:.4f}")
    print(f"quant_gap:      {out['quant_gap']:.4f}")
    print(f"accuracy_dev:   {rep_dev['accuracy']:.4f}")
    print(f"kappa_dev:      {rep_dev['kappa']:.4f}")
    print(f"spikes_neuron:  {spk:.2f}")
    print(f"total_cap_F:    {led['total_cap_F']:.3e}")
    print(f"energy_J_beat:  {led['total_J']:.3e}")
    print(f"latency_s:      {led['latency_s']:.4f}")
    print(f"n_devices:      {led['n_devices']}")
    print("-" * 60)


def run_smoke(device):
    _, tl, vl, cw = load_data(device)
    model = make_model(device)
    print(f"[smoke] CONFIG={CONFIG} params={sum(p.numel() for p in model.parameters()):,}")
    model.train()
    for i, (ecg, label) in enumerate(tl):
        if i >= 2:
            break
        ecg, label = ecg.float().to(device), label.to(device)
        t0 = time.time()
        out = model(ecg)[-1]
        loss = focal_loss(out, label, cw, FLAGS["focal_gamma"])
        loss.backward(); functional.reset_net(model)
        print(f"  batch{i} fwd+bwd {time.time()-t0:.1f}s loss={loss.item():.3f} "
              f"FR={model.spike_for_reg.mean().item()/FLAGS['dt']:.1f}Hz out={tuple(out.shape)}")
    print("[smoke] OK")


if __name__ == "__main__":
    dev = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    {"calib": run_calib, "train": run_train, "smoke": run_smoke}[MODE](dev)
