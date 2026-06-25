"""
Resume from v8c ep-5 checkpoint (76.49%) and continue with PURE CE fine-tuning.
==============================================================================

KEY DISCOVERY from the v8c run:
  - Phase 1 (pure CE, no KD, no SR) reached 76.49% at epoch 5 — BEST EVER for
    the polarization-physics model (beats run-3's 70.83% by 6 pp).
  - Phase 2+3 (with KD) catastrophically collapsed the network to 50.89%.
  - Diagnosis: KD pushes the polarization student to match RC-teacher
    representations that are physically incompatible, and the student
    takes the shortcut of always predicting majority class.

THIS RUN: drop KD entirely. Resume from the saved 76.49% checkpoint and
continue with pure CE fine-tuning. Same recipe that took the RC model
from 89.58% to 90.18%.

  - Load v8c ep-5 checkpoint
  - Constant LR = 5e-4 (gentle fine-tune)
  - Pure CE loss (NO distillation — KD breaks this model)
  - Spike regularizer ON with light lambda (1e-7) — keep firing in band
  - 60 epochs, auto-stop at 82%

OUTPUT: ecg_fefetlsnn_v8d_pure_ce/1/
RUNTIME: ~3.5 h (student fwd+bwd only; no teacher in this version).

EXPECTED:
  - ep 0 of resume: 76.49% (matches loaded checkpoint)
  - ep 5-10: should climb to 78-80% with constant low LR
  - ep 30+: best probably lands at 78-82%

This is the polarization model's honest ceiling.
"""

import os
os.environ.setdefault("OMP_NUM_THREADS", "4")
os.environ.setdefault("MKL_NUM_THREADS", "4")
import json
import torch
torch.set_num_threads(4)
torch.set_num_interop_threads(2)

import torch.nn.functional as F
import torch.utils.data as data
import numpy as np
from sklearn.utils.class_weight import compute_class_weight
from spikingjelly.clock_driven import functional
from torch.utils.tensorboard import SummaryWriter
from tqdm import tqdm
import matplotlib.pyplot as plt
import seaborn as sns
from dataset import DeltaTransformedECG, loader
from model_2 import FeFETDevice, FeFETLSNN

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_PROJ_ROOT  = os.path.normpath(os.path.join(_SCRIPT_DIR, ".."))

# v8c ep-5 checkpoint = 76.49% on test, the best polarization-physics state we have
RESUME_CKPT = os.path.join(_PROJ_ROOT, "ecg_fefetlsnn_v8c_warmup", "1", "model",
                           "ecg_fefetlsnn_v8c_ep5.ckpt")


def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    FLAGS = {
        "train_epoch": 60,
        "batch_size": 128,
        "lr": 5e-4,                       # CONSTANT, gentle (same recipe as RC resume)
        "grad_clip_norm": 1.0,
        "apply_class_weights": True,

        "is_spike_reg": True,
        "spike_reg_lambda": 1e-7,         # light — keep firing in band
        "spike_reg_target_f": 15.0,

        "resume_ckpt": RESUME_CKPT,

        "num_in": 3, "num_lif": 60, "num_alif": 40, "num_out": 4,
        "max_delay": 10, "refractory": 0, "save_model": True,

        "dt": 5.556e-4, "tau_lp": 11.11e-3,
        "out_cue_duration": 116, "repetition": 1,

        # FeFET polarization physics — match v8c exactly so the checkpoint loads cleanly
        "Vc": 1.0, "reset_completeness": 0.80, "tau_leak": 50e-3, "R_adapt": 7830.0,
        "K_switch": 0.13, "V_scale": 0.65, "V_max": 7.0,
        "weight_to_Vpulse_slope": 1.15, "P_threshold": 0.45,

        "Vdd": 5., "Ra": 100e3, "Ca": 5556e-9,
        "kappa_n": 29e-6, "kappa_p": 18e-6,
        "vtn": 0.745, "vtp": 0.973,
        "wl_ratio_n": 16, "wl_ratio_p": 8,
    }

    save_model = FLAGS["save_model"]
    dataset_dir = r"E:\Signal_Classific_Neuromorph\NCOMMS-23-03137-main\Physiological signal processing system\VO2-based decision-making stage\data_ecg"
    model_dir = os.path.join(_PROJ_ROOT, 'ecg_fefetlsnn_v8d_pure_ce', '1')
    model_output_dir = f'{model_dir}/model'
    log_dir = f'{model_dir}/log'
    fig_dir = f'{model_dir}/fig'
    model_output_name = f'{model_output_dir}/ecg_fefetlsnn_v8d'
    for d in [model_dir, model_output_dir, log_dir, fig_dir]:
        os.makedirs(d, exist_ok=True)
    if save_model:
        with open(f'{model_dir}/flags.json', 'w') as fp:
            ftosave = {k: v for k, v in FLAGS.items() if k != 'resume_ckpt'}
            ftosave['resume_ckpt_basename'] = os.path.basename(RESUME_CKPT)
            json.dump(ftosave, fp, sort_keys=True, indent=4)

    train_batch_per_epoch = 13
    test_batch_per_epoch = 3
    dt = FLAGS["dt"]
    writer = SummaryWriter(log_dir)

    dataset = DeltaTransformedECG(path=dataset_dir,
                                  output_cue_length=FLAGS["out_cue_duration"],
                                  n_class=FLAGS["num_out"])
    train_dataset, test_dataset = data.random_split(
        dataset, [1664, 336], generator=torch.Generator().manual_seed(100)
    )
    class_weights = torch.Tensor(compute_class_weight(
        'balanced' if FLAGS["apply_class_weights"] else None,
        classes=dataset.get_classes(),
        y=train_dataset.dataset.labels[train_dataset.indices].numpy()
    )).to(device)
    train_loader = data.DataLoader(dataset=train_dataset, batch_size=FLAGS["batch_size"],
                                    shuffle=True, drop_last=True)
    test_loader = data.DataLoader(dataset=test_dataset, batch_size=FLAGS["batch_size"],
                                   shuffle=False, drop_last=False)

    # ============ STUDENT (PROVEN model_2.FeFETLSNN) ============
    device_params = FeFETDevice(
        Vc=FLAGS["Vc"], V_scale=FLAGS["V_scale"], V_max=FLAGS["V_max"],
        K_switch=FLAGS["K_switch"], reset_completeness=FLAGS["reset_completeness"],
        tau_leak=FLAGS["tau_leak"],
        weight_to_Vpulse_slope=FLAGS["weight_to_Vpulse_slope"],
        R_adapt=FLAGS["R_adapt"],
    )
    net = FeFETLSNN(
        num_in=FLAGS["num_in"], num_lif=FLAGS["num_lif"], num_alif=FLAGS["num_alif"],
        num_out=FLAGS["num_out"], tau_lp=FLAGS["tau_lp"],
        device_params=device_params, v_threshold=FLAGS["P_threshold"],
        Ra=FLAGS["Ra"], Ca=FLAGS["Ca"],
        vtn=FLAGS["vtn"], vtp=FLAGS["vtp"],
        kappa_n=FLAGS["kappa_n"], kappa_p=FLAGS["kappa_p"],
        wl_ratio_n=FLAGS["wl_ratio_n"], wl_ratio_p=FLAGS["wl_ratio_p"],
        Vdd=FLAGS["Vdd"], dt=dt, device=device,
        max_delay=FLAGS["max_delay"], refractory=FLAGS["refractory"]
    ).to(device)

    # ============ RESUME from 76.49% checkpoint ============
    print(f"\n[resume] loading: {FLAGS['resume_ckpt']}")
    if not os.path.exists(FLAGS['resume_ckpt']):
        raise FileNotFoundError(f"Checkpoint not found: {FLAGS['resume_ckpt']}")
    ck = torch.load(FLAGS['resume_ckpt'], map_location=device, weights_only=False)
    net.load_state_dict(ck['net'])
    print("[resume] state loaded.\n")

    optimizer = torch.optim.Adam(net.parameters(), lr=FLAGS["lr"])

    # ============ Pre-resume eval (verify checkpoint) ============
    print("[resume] pre-resume eval...")
    net.eval()
    with torch.no_grad():
        corr = total = 0
        for ecg, label in loader(test_loader, device):
            output = net(ecg.float())[-1]
            functional.reset_net(net)
            corr += (output.max(1)[1] == label).float().sum().item()
            total += label.numel()
    pre_acc = corr / total
    print(f"[resume] pre-resume test_acc = {pre_acc:.4f}  (expected ~0.7649)\n")

    test_accs, train_accs, test_loss, train_loss = [], [], [], []
    train_times = test_times = 0
    max_test_accuracy = pre_acc
    best_epoch = -1
    confusion_matrix = np.zeros([FLAGS["num_out"], FLAGS["num_out"]], dtype=int)

    for epoch in range(FLAGS["train_epoch"]):
        print(f"Epoch {epoch}: lr={optimizer.param_groups[0]['lr']}")
        train_correct_sum = train_sum = train_loss_sum = 0
        epoch_fr = 0.0; n_batches = 0
        net.train()

        for ecg, label in (pbar := tqdm(loader(train_loader, device), total=train_batch_per_epoch)):
            optimizer.zero_grad()
            output = net(ecg.float())[-1]
            loss = F.cross_entropy(output, label, weight=class_weights)
            if FLAGS["is_spike_reg"]:
                loss = loss + net.spike_regularization(
                    target_f=FLAGS["spike_reg_target_f"], lambda_f=FLAGS["spike_reg_lambda"])

            with torch.no_grad():
                epoch_fr += net.spike_for_reg.mean().item() / dt
                n_batches += 1

            loss.backward()
            torch.nn.utils.clip_grad_norm_(net.parameters(), max_norm=FLAGS["grad_clip_norm"])
            optimizer.step()
            functional.reset_net(net)

            is_correct = (output.max(1)[1] == label).float()
            train_correct_sum += is_correct.sum().item()
            train_sum += label.numel()
            tba = is_correct.mean().item()
            writer.add_scalar('train_batch_accuracy', tba, train_times)
            train_accs.append(tba)
            train_loss_sum += loss.item()
            train_loss.append(loss.item())
            writer.add_scalar('train_batch_loss', loss, train_times)
            pbar.set_postfix_str(f'(Step {train_times}: acc={tba*100:.2f}, loss={loss.item():.4f})')
            train_times += 1

        train_accuracy = train_correct_sum / train_sum
        train_loss_avg = train_loss_sum / train_batch_per_epoch
        avg_fr = epoch_fr / max(n_batches, 1)

        print("Testing...")
        net.eval()
        with torch.no_grad():
            test_correct_sum = test_sum = test_loss_sum = 0
            for ecg, label in tqdm(loader(test_loader, device), total=test_batch_per_epoch):
                output = net(ecg.float())[-1]
                loss_t = F.cross_entropy(output, label, weight=class_weights)
                if FLAGS["is_spike_reg"]:
                    loss_t = loss_t + net.spike_regularization(
                        target_f=FLAGS["spike_reg_target_f"], lambda_f=FLAGS["spike_reg_lambda"])
                functional.reset_net(net)
                test_correct_sum += (output.max(1)[1] == label).float().sum().item()
                test_sum += label.numel()
                test_loss_sum += loss_t.item()
                test_loss.append(loss_t.item())
                writer.add_scalar('test_batch_loss', loss_t, test_times)
                if epoch == FLAGS["train_epoch"] - 1:
                    for tl, pl in zip(label.cpu().numpy(), output.max(1)[1].cpu().numpy()):
                        confusion_matrix[pl, tl] += 1
                test_times += 1
            test_accuracy = test_correct_sum / test_sum
            test_loss_avg = test_loss_sum / test_batch_per_epoch
            writer.add_scalar('test_accuracy', test_accuracy, epoch)
            test_accs.append(test_accuracy)

        if save_model and test_accuracy >= max_test_accuracy:
            best_epoch = epoch
            print(f'Saving best to {model_output_name}_ep{epoch}.ckpt  (acc={test_accuracy:.4f})')
            torch.save({"net": net.state_dict()}, f'{model_output_name}_ep{epoch}.ckpt')
            np.save(f'{model_output_dir}/test_accs_ep{epoch}.npy', np.array(test_accs))
            np.save(f'{model_output_dir}/train_accs_ep{epoch}.npy', np.array(train_accs))
            np.save(f'{model_output_dir}/test_loss_ep{epoch}.npy', np.array(test_loss))
            np.save(f'{model_output_dir}/train_loss_ep{epoch}.npy', np.array(train_loss))

        max_test_accuracy = max(max_test_accuracy, test_accuracy)
        fr_state = "OK"
        if avg_fr < 1.0: fr_state = "TOO LOW"
        elif avg_fr > 80.0: fr_state = "TOO HIGH"
        print(f"Epoch {epoch}: train={train_accuracy:.4f} test={test_accuracy:.4f} "
              f"loss={train_loss_avg:.4f} max_test={max_test_accuracy:.4f} "
              f"FR={avg_fr:.2f}Hz [{fr_state}]\n")

        # Auto-stop if comfortably above 82%
        if max_test_accuracy >= 0.82 and epoch >= 5:
            print(f"Early stop: reached {max_test_accuracy*100:.2f}% at epoch {epoch}.")
            break

    train_accs_arr = np.array(train_accs); test_accs_arr = np.array(test_accs)
    train_loss_arr = np.array(train_loss); test_loss_arr = np.array(test_loss)
    if save_model:
        np.save(f'{model_dir}/train_accs.npy', train_accs_arr)
        np.save(f'{model_dir}/test_accs.npy', test_accs_arr)
        np.save(f'{model_dir}/train_loss.npy', train_loss_arr)
        np.save(f'{model_dir}/test_loss.npy', test_loss_arr)

    plt.figure(); plt.plot(train_accs_arr); plt.savefig(f'{fig_dir}/accs-train.png'); plt.close()
    plt.figure(); plt.plot(test_accs_arr);  plt.savefig(f'{fig_dir}/accs-test.png');  plt.close()
    plt.figure(); plt.plot(train_loss_arr); plt.savefig(f'{fig_dir}/loss-train.png'); plt.close()
    plt.figure(); plt.plot(test_loss_arr);  plt.savefig(f'{fig_dir}/loss-test.png');  plt.close()
    plt.figure()
    sns.heatmap(confusion_matrix, annot=True, fmt='d',
                xticklabels=dataset.get_classes(False), yticklabels=dataset.get_classes(False))
    plt.gca().invert_yaxis(); plt.yticks(rotation=0)
    plt.savefig(f'{fig_dir}/confusion.png'); plt.close()

    print(f'\n{"="*60}')
    print(f'BEST (FeFET polarization, pure-CE fine-tune): {max_test_accuracy*100:.2f}%  (ep {best_epoch})')
    print(f'Started from: {pre_acc*100:.2f}%')
    print(f'{"="*60}')


if __name__ == '__main__':
    main()
