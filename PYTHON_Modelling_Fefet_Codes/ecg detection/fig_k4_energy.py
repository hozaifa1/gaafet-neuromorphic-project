"""
Figure K4 — energy per ECG inference: device write vs device read vs peripheral.
================================================================================
Every count in this figure is MEASURED on the deployed network (locked paper150b
checkpoint, 15 measured FeFET levels, 336-beat test set) rather than assumed:

  synapse count   numel() of every *.weight in the model, x2 for the differential pair
  spike counts    mean per-beat input and hidden spikes, from the actual forward pass
  read counts     dense (fully clocked crossbar) AND event-driven (a row is read only
                  when its presynaptic line spiked); the readout layer sees the analog
                  low-pass state, so it is dense in both cases

Device numbers come from gaafefet_params_optimized.py via REDESIGN/code/energy_ledger.py:
E_write = 0.0089 fJ per +2 V/0.3 us pulse (the corrected value; 0.014 fJ was pre-Areafactor),
R_on = 3.68 MOhm and R_off = 67.7 MOhm both from node t8_ltp.

The ADC term is the one ASSUMPTION in the figure (1 pJ/conversion, one conversion per
crossbar column per timestep). It is included precisely because it dominates: the FeFET
array is not the energy bottleneck of a real system, and a device paper that reported only
its own contribution would be overclaiming.

    python fig_k4_energy.py
"""
import kfig_common as kc          # first: sets sys.path and imports torch before pandas
import os, sys, json
import numpy as np
import torch

import figstyle as fs
import energy_ledger as el
from fefet_device import measured_levels

E_ADC = el.E_ADC_CONV          # J per conversion (assumption)
T_STEPS = 1116
AMORTIZE_OVER = [1, 1e3, 1e6]  # inferences a single programming pass is spread over
JSON = os.path.join(kc.RUNS, "k4_energy.json")


def main():
    model, fp_state, ev = kc.setup()
    lv, _, gmax = measured_levels()
    kc.deploy(model, fp_state, kc.diff_set(lv, gmax))

    # ---- synapse inventory (measured from the model, not assumed) ----
    weights = {n: p for n, p in model.named_parameters() if n.endswith("weight")}
    n_syn = sum(p.numel() for p in weights.values())
    n_dev = n_syn * 2                      # differential pair
    for n, p in weights.items():
        print(f"[K4] {n:28s} {tuple(p.shape)}  {p.numel()} weights")
    print(f"[K4] {n_syn} weights -> {n_dev} FeFETs", flush=True)

    # ---- measured activity over the test set ----
    import torch.utils.data as data
    import post_quantize as pq
    loader = pq.build_test_loader(torch.device("cpu"), "intra")
    from spikingjelly.clock_driven import functional
    in_spk = hid_spk = 0.0
    n_beats = 0
    with torch.no_grad():
        for x, _ in loader:
            model(x.float())
            in_spk += float((x > 0.5).sum())
            hid_spk += float(model.spike_for_reg.sum())
            n_beats += x.shape[0]
            functional.reset_net(model)
    in_spk /= n_beats
    hid_spk /= n_beats
    n_in, n_hid = 3, model.num_lif + model.num_alif
    act_in = in_spk / (T_STEPS * n_in)
    act_hid = hid_spk / (T_STEPS * n_hid)
    print(f"[K4] per beat: {in_spk:.1f} input spikes ({act_in*100:.2f} % line activity), "
          f"{hid_spk:.1f} hidden spikes ({act_hid*100:.2f} %), "
          f"{hid_spk/n_hid:.2f} spikes/neuron", flush=True)

    # ---- read energy ----
    e_read = el.V_READ ** 2 * el.G_REPR * el.T_READ        # J per representative read
    per_layer = []
    for name, p in weights.items():
        dense = T_STEPS * p.numel()
        if name.startswith("fc1"):
            frac = act_in
        elif name.startswith("fc2"):
            frac = 1.0                                     # analog LP state, always read
        else:
            frac = act_hid
        per_layer.append((name, dense, dense * frac))
    reads_dense = sum(d for _, d, _ in per_layer)
    reads_event = sum(e for _, _, e in per_layer)
    E_read_dense = reads_dense * e_read
    E_read_event = reads_event * e_read

    # ---- neuron membrane events ----
    E_neuron = hid_spk * 0.5 * el.C_MEM * el.V_SWING ** 2

    # ---- peripheral (assumption) ----
    n_col = n_hid + 4                                      # analog summation into shared columns
    E_periph = T_STEPS * n_col * E_ADC

    # ---- one-time programming, amortized ----
    E_write_total = n_dev * el.N_WRITE_PULSES * el.E_WRITE_PULSE

    rows = [["device write (whole array, ONE-TIME)", E_write_total],
            ["device read (event-driven)", E_read_event],
            ["device read (fully clocked)", E_read_dense],
            ["neuron membrane", E_neuron],
            ["peripheral ADC (assumed 1 pJ/conv)", E_periph]]
    core = E_read_event + E_neuron
    print(f"[K4] core (event read + neuron) = {core*1e12:.2f} pJ/beat; "
          f"peripheral = {E_periph*1e9:.2f} nJ/beat ({E_periph/core:.0f}x core)")
    for k in AMORTIZE_OVER:
        print(f"[K4] write amortized over {k:>9.0f} inferences: "
              f"{E_write_total/k*1e12:.4f} pJ/beat")

    json.dump({"n_weights": n_syn, "n_fefets": n_dev,
               "input_spikes_per_beat": in_spk, "hidden_spikes_per_beat": hid_spk,
               "line_activity_input": act_in, "line_activity_hidden": act_hid,
               "reads_dense": reads_dense, "reads_event": reads_event,
               "E_read_dense_J": E_read_dense, "E_read_event_J": E_read_event,
               "E_neuron_J": E_neuron, "E_peripheral_J": E_periph,
               "E_write_total_J": E_write_total, "E_core_event_J": core,
               "rows": rows,
               "assumptions": {"E_ADC_per_conversion_J": E_ADC, "n_columns": n_col,
                               "t_read_s": el.T_READ, "V_read_V": el.V_READ,
                               "C_mem_F": el.C_MEM, "V_swing_V": el.V_SWING,
                               "E_write_per_pulse_J": el.E_WRITE_PULSE,
                               "write_pulses_per_device": el.N_WRITE_PULSES}},
              open(JSON, "w"), indent=2)
    plot(rows, core)


def plot(rows, core):
    labels = ["Device write\nWHOLE ARRAY\n(one-time)", "Device read\n(event-driven)",
              "Device read\n(clocked)", "Neuron\nmembrane", "Peripheral\nADC"]
    vals = [r[1] for r in rows]
    colors = ["#b8860b", "#0b3d1e", "#2e8b57", "#1f4e79", "#8b1a1a"]
    fig, ax = fs.new_ax(figsize=(9.2, 5.6))
    bars = ax.bar(np.arange(len(vals)), vals, 0.62, color=colors, edgecolor="black", lw=2)
    ax.set_yscale("log")
    ax.set_ylim(min(vals) / 12, max(vals) * 40)
    for b, v in zip(bars, vals):
        ax.text(b.get_x() + b.get_width() / 2, v * 1.5, _si(v),
                ha="center", fontweight="bold", fontsize=11)
    ax.axhline(core, ls="--", lw=2.0, color="#333333")
    ax.text(-0.42, core * 1.2, f"core compute = {_si(core)} / inference", ha="left",
            fontweight="bold", fontsize=11, color="#333333")
    ax.set_xticks(np.arange(len(vals))); ax.set_xticklabels(labels, fontweight="bold", fontsize=10)
    ax.minorticks_off()
    fs.bold_labels(ax, None, "Energy (J)")
    fs.finish(fig, os.path.join(kc.OUT, "K4_energy_per_inference.png"))
    fs.save_csv(os.path.join(kc.OUT, "K4_energy_per_inference.csv"),
                ["component", "energy_J"], rows)
    print("[K4] wrote", kc.OUT)


def _si(x):
    for p, s in [(1e-15, "f"), (1e-12, "p"), (1e-9, "n"), (1e-6, "u")]:
        if abs(x) < p * 1000:
            return f"{x/p:.2f} {s}J"
    return f"{x:.2e} J"


if __name__ == "__main__":
    if "--replot" in sys.argv:
        d = json.load(open(JSON))
        plot(d["rows"], d["E_core_event_J"])
    else:
        main()
