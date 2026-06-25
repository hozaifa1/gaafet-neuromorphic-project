"""
FeFET-physics LSNN with WARMUP-then-distill schedule.
======================================================

Diagnosis from v8b failure:
  - At epoch 0, the random student gets a strong KD gradient pulling it
    toward the teacher's confident predictions. With no representations
    yet, the easiest way for the student to satisfy KD is to collapse to
    the teacher's most-frequent class (N). It locks in there within
    batch 1 and the gradient afterward is too weak to escape.
  - Same shortcut is reinforced by class-weighted CE on imbalanced data.

THIS VERSION fixes that with a 3-phase schedule:

  Phase 1 (ep 0-10): PURE CE only. No distillation, no spike regularizer.
                     Lets the student build its own representations
                     (this is essentially the proven run-3 setup that
                     reached 70.83%).

  Phase 2 (ep 10-30): CE + KD with alpha=0.7 (CE-heavy). Spike reg ON.
                      Now the student has a representation; KD can refine
                      it without hijacking the optimizer.

  Phase 3 (ep 30+):   CE + KD with alpha=0.5 (equal weight). Cosine LR
                      cools, refinement.

Everything else is identical to run-3 / v8b: model_2.FeFETLSNN
(multiplicative reset, ScaledPiecewiseQuadratic), run-3 dynamics, 80 epochs,
auto-stop at 85%.

OUTPUT: ecg_fefetlsnn_v8c_warmup/1/
RUNTIME: ~3.5-4.5 h.
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
from model import VO2LSNN
from model_2 import FeFETDevice, FeFETLSNN

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_PROJ_ROOT  = os.path.normpath(os.path.join(_SCRIPT_DIR, ".."))
TEACHER_CKPT = os.path.join(_PROJ_ROOT, "ecg_fefetlsnn_resume", "1", "model",
                            "ecg_fefetlsnn_resume_ep1.ckpt")


def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    FLAGS = {
        # ---------- training ----------
        "train_epoch": 80,
        "batch_size": 128,
        "lr": 3e-3,
        "grad_clip_norm": 1.0,
        "apply_class_weights": True,

        # ---------- 3-PHASE schedule ----------
        "phase1_end": 10,                 # ep 0-10: pure CE, no KD, no SR
        "phase2_end": 30,                 # ep 10-30: CE + KD with alpha=0.7, SR on
                                          # ep 30+:   CE + KD with alpha=0.5, SR on
        "kd_temperature": 4.0,
        "kd_alpha_phase2": 0.7,           # CE-heavy
        "kd_alpha_phase3": 0.5,           # equal

        # ---------- spike regularization (only used after phase 1) ----------
        "is_spike_reg": True,
        "spike_reg_lambda": 5e-7,
        "spike_reg_target_f": 15.0,

        # ---------- ARCHITECTURE (matches teacher) ----------
        "num_in": 3, "num_lif": 60, "num_alif": 40, "num_out": 4,
        "max_delay": 10, "refractory": 0, "save_model": True,

        # ---------- timing ----------
        "dt": 5.556e-4, "tau_lp": 11.11e-3,
        "out_cue_duration": 116, "repetition": 1,

        # ---------- DEVICE-PHYSICAL (run-3 conservative, Sentaurus-feasible) ----------
        "Vc": 1.0, "reset_completeness": 0.80, "tau_leak": 50e-3, "R_adapt": 7830.0,

        # ---------- SNN-MAPPING (proven from run-3) ----------
        "K_switch": 0.13, "V_scale": 0.65, "V_max": 7.0,
        "weight_to_Vpulse_slope": 1.15, "P_threshold": 0.45,

        # ---------- MOSFET adaptation ----------
        "Vdd": 5., "Ra": 100e3, "Ca": 5556e-9,
        "kappa_n": 29e-6, "kappa_p": 18e-6,
        "vtn": 0.745, "vtp": 0.973,
        "wl_ratio_n": 16, "wl_ratio_p": 8,

        # ---------- TEACHER ----------
        "teacher_ckpt": TEACHER_CKPT,
        "teacher_tau": 11.11e-3,
        "teacher_Rh": 5250., "teacher_Rs": 2580., "teacher_Cmem": 1.419e-6,
        "teacher_input_scaling": 9900e-6,
        "teacher_vth": 3.6, "teacher_vh": 1.5,
    }

    save_model = FLAGS["save_model"]
    dataset_dir = r"E:\Signal_Classific_Neuromorph\NCOMMS-23-03137-main\Physiological signal processing system\VO2-based decision-making stage\data_ecg"
    model_dir = os.path.join(_PROJ_ROOT, 'ecg_fefetlsnn_v8c_warmup', '1')
    model_output_dir = f'{model_dir}/model'
    log_dir = f'{model_dir}/log'
    fig_dir = f'{model_dir}/fig'
    model_output_name = f'{model_output_dir}/ecg_fefetlsnn_v8c'
    for d in [model_dir, model_output_dir, log_dir, fig_dir]:
        os.makedirs(d, exist_ok=True)
    if save_model:
        with open(f'{model_dir}/flags.json', 'w') as fp:
            ftosave = {k: v for k, v in FLAGS.items() if k != 'teacher_ckpt'}
            ftosave['teacher_ckpt_basename'] = os.path.basename(TEACHER_CKPT)
            json.dump(ftosave, fp, sort_keys=True, indent=4)

    train_batch_per_epoch = 13
    test_batch_per_epoch = 3
    train_epoch = FLAGS["train_epoch"]
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

    # ============ TEACHER ============
    print(f"\n[teacher] loading: {FLAGS['teacher_ckpt']}")
    if not os.path.exists(FLAGS['teacher_ckpt']):
        raise FileNotFoundError(f"Teacher not found: {FLAGS['teacher_ckpt']}")
    teacher = VO2LSNN(
        num_in=FLAGS["num_in"], num_lif=FLAGS["num_lif"], num_alif=FLAGS["num_alif"],
        num_out=FLAGS["num_out"], tau=FLAGS["teacher_tau"], tau_lp=FLAGS["tau_lp"],
        Rh=FLAGS["teacher_Rh"], Rs=FLAGS["teacher_Rs"], Ra=FLAGS["Ra"],
        Cmem=FLAGS["teacher_Cmem"], Ca=FLAGS["Ca"],
        v_threshold=FLAGS["teacher_vth"], v_reset=FLAGS["teacher_vh"],
        vtn=FLAGS["vtn"], vtp=FLAGS["vtp"],
        kappa_n=FLAGS["kappa_n"], kappa_p=FLAGS["kappa_p"],
        wl_ratio_n=FLAGS["wl_ratio_n"], wl_ratio_p=FLAGS["wl_ratio_p"],
        Vdd=FLAGS["Vdd"], input_scaling=FLAGS["teacher_input_scaling"],
        dt=dt, device=device,
        max_delay=FLAGS["max_delay"], refractory=FLAGS["refractory"]
    ).to(device)
    teacher.load_state_dict(torch.load(FLAGS['teacher_ckpt'], map_location=device,
                                       weights_only=False)['net'])
    teacher.eval()
    for p in teacher.parameters():
        p.requires_grad_(False)
    print("[teacher] verifying...")
    with torch.no_grad():
        corr = total = 0
        for ecg, label in loader(test_loader, device):
            output = teacher(ecg.float())[-1]
            functional.reset_net(teacher)
            corr += (output.max(1)[1] == label).float().sum().item()
            total += label.numel()
    teacher_acc = corr / total
    print(f"[teacher] test_acc = {teacher_acc:.4f}\n")

    # ============ STUDENT (PROVEN model_2.FeFETLSNN) ============
    device_params = FeFETDevice(
        Vc=FLAGS["Vc"], V_scale=FLAGS["V_scale"], V_max=FLAGS["V_max"],
        K_switch=FLAGS["K_switch"], reset_completeness=FLAGS["reset_completeness"],
        tau_leak=FLAGS["tau_leak"],
        weight_to_Vpulse_slope=FLAGS["weight_to_Vpulse_slope"],
        R_adapt=FLAGS["R_adapt"],
    )
    student = FeFETLSNN(
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

    optimizer = torch.optim.Adam(student.parameters(), lr=FLAGS["lr"])
    T_max = train_epoch * train_batch_per_epoch
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer, T_max=T_max, eta_min=FLAGS["lr"] * 1e-2
    )

    n_params = sum(p.numel() for p in student.parameters())
    print(f"Student params: {n_params:,}\n")

    def make_loss(student_logits, teacher_logits, label, phase):
        """3-phase loss schedule.
        phase 1: pure CE (no KD, no SR)
        phase 2: CE + KD (alpha=0.7) + SR
        phase 3: CE + KD (alpha=0.5) + SR
        Returns (total_loss, ce_val, kd_val, sr_val).
        """
        ce = F.cross_entropy(student_logits, label, weight=class_weights)
        if phase == 1:
            return ce, ce.item(), 0.0, 0.0
        # phase 2 or 3: add KD
        T = FLAGS["kd_temperature"]
        alpha = FLAGS["kd_alpha_phase2"] if phase == 2 else FLAGS["kd_alpha_phase3"]
        student_log_soft = F.log_softmax(student_logits / T, dim=-1)
        teacher_soft = F.softmax(teacher_logits / T, dim=-1)
        kd = F.kl_div(student_log_soft, teacher_soft, reduction='batchmean') * (T * T)
        loss = alpha * ce + (1.0 - alpha) * kd
        return loss, ce.item(), kd.item(), 0.0

    test_accs, train_accs, test_loss, train_loss = [], [], [], []
    train_times = test_times = 0
    max_test_accuracy = 0.0
    best_epoch = -1
    confusion_matrix = np.zeros([FLAGS["num_out"], FLAGS["num_out"]], dtype=int)

    for epoch in range(train_epoch):
        # Determine phase
        if epoch < FLAGS["phase1_end"]:
            phase = 1; phase_str = "phase1 (pure CE, no KD, no SR)"
        elif epoch < FLAGS["phase2_end"]:
            phase = 2; phase_str = f"phase2 (CE + KD alpha={FLAGS['kd_alpha_phase2']} + SR)"
        else:
            phase = 3; phase_str = f"phase3 (CE + KD alpha={FLAGS['kd_alpha_phase3']} + SR)"

        sr_active = (phase != 1) and FLAGS["is_spike_reg"]

        print(f"Epoch {epoch}: lr={scheduler.get_last_lr()[0]:.2e}  [{phase_str}]")
        train_correct_sum = train_sum = train_loss_sum = 0
        epoch_fr = 0.0; n_batches = 0
        ce_sum = kd_sum = 0.0
        student.train()

        for ecg, label in (pbar := tqdm(loader(train_loader, device), total=train_batch_per_epoch)):
            optimizer.zero_grad()

            # Teacher forward (only used in phase 2+)
            if phase >= 2:
                with torch.no_grad():
                    teacher_output = teacher(ecg.float())[-1]
                    functional.reset_net(teacher)
            else:
                teacher_output = None

            student_output = student(ecg.float())[-1]
            loss, ce_val, kd_val, _ = make_loss(student_output, teacher_output, label, phase)

            if sr_active:
                loss = loss + student.spike_regularization(
                    target_f=FLAGS["spike_reg_target_f"], lambda_f=FLAGS["spike_reg_lambda"])

            with torch.no_grad():
                epoch_fr += student.spike_for_reg.mean().item() / dt
                n_batches += 1

            loss.backward()
            torch.nn.utils.clip_grad_norm_(student.parameters(), max_norm=FLAGS["grad_clip_norm"])
            optimizer.step()
            scheduler.step()
            functional.reset_net(student)

            is_correct = (student_output.max(1)[1] == label).float()
            train_correct_sum += is_correct.sum().item()
            train_sum += label.numel()
            tba = is_correct.mean().item()
            writer.add_scalar('train_batch_accuracy', tba, train_times)
            train_accs.append(tba)
            train_loss_sum += loss.item()
            ce_sum += ce_val; kd_sum += kd_val
            train_loss.append(loss.item())
            writer.add_scalar('train_batch_loss', loss, train_times)
            pbar.set_postfix_str(f'(acc={tba*100:.2f}, ce={ce_val:.3f}, kd={kd_val:.3f})')
            train_times += 1

        train_accuracy = train_correct_sum / train_sum
        train_loss_avg = train_loss_sum / train_batch_per_epoch
        avg_fr = epoch_fr / max(n_batches, 1)
        ce_avg = ce_sum / train_batch_per_epoch
        kd_avg = kd_sum / train_batch_per_epoch

        print("Testing...")
        student.eval()
        with torch.no_grad():
            test_correct_sum = test_sum = test_loss_sum = 0
            for ecg, label in tqdm(loader(test_loader, device), total=test_batch_per_epoch):
                student_output = student(ecg.float())[-1]
                loss_t = F.cross_entropy(student_output, label, weight=class_weights)
                functional.reset_net(student)
                test_correct_sum += (student_output.max(1)[1] == label).float().sum().item()
                test_sum += label.numel()
                test_loss_sum += loss_t.item()
                test_loss.append(loss_t.item())
                writer.add_scalar('test_batch_loss', loss_t, test_times)
                if epoch == train_epoch - 1:
                    for tl, pl in zip(label.cpu().numpy(), student_output.max(1)[1].cpu().numpy()):
                        confusion_matrix[pl, tl] += 1
                test_times += 1
            test_accuracy = test_correct_sum / test_sum
            test_loss_avg = test_loss_sum / test_batch_per_epoch
            writer.add_scalar('test_accuracy', test_accuracy, epoch)
            test_accs.append(test_accuracy)

        if save_model and test_accuracy >= max_test_accuracy:
            best_epoch = epoch
            print(f'Saving best to {model_output_name}_ep{epoch}.ckpt  (acc={test_accuracy:.4f})')
            torch.save({"net": student.state_dict()}, f'{model_output_name}_ep{epoch}.ckpt')
            np.save(f'{model_output_dir}/test_accs_ep{epoch}.npy', np.array(test_accs))
            np.save(f'{model_output_dir}/train_accs_ep{epoch}.npy', np.array(train_accs))
            np.save(f'{model_output_dir}/test_loss_ep{epoch}.npy', np.array(test_loss))
            np.save(f'{model_output_dir}/train_loss_ep{epoch}.npy', np.array(train_loss))

        max_test_accuracy = max(max_test_accuracy, test_accuracy)
        fr_state = "OK"
        if avg_fr < 1.0: fr_state = "TOO LOW"
        elif avg_fr > 80.0: fr_state = "TOO HIGH"
        print(f"Epoch {epoch}: train={train_accuracy:.4f} test={test_accuracy:.4f} "
              f"loss={train_loss_avg:.4f} (ce={ce_avg:.3f} kd={kd_avg:.3f}) "
              f"max_test={max_test_accuracy:.4f} FR={avg_fr:.2f}Hz [{fr_state}]\n")

        if max_test_accuracy >= 0.85 and epoch >= 15:
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
    print(f'STUDENT (FeFET polarization, warmup-then-distill): {max_test_accuracy*100:.2f}%  (ep {best_epoch})')
    print(f'TEACHER (VO2-RC, FeFET R): {teacher_acc*100:.2f}%')
    print(f'{"="*60}')


if __name__ == '__main__':
    main()
