"""
Per-inference energy + capacitance budget (fixes C2 + M1 in 00_CRITICAL_REVIEW).
Proves the core FoMs: pF-class capacitance and nJ-class energy per ECG beat, vs the
old 1.419 uF / sub-mJ design.

All numbers are first-order analytic estimates with explicit assumptions — replace the
spike-count and read-count assumptions with measured values from a real run when available.
Pure python; self-check at bottom.
"""
from __future__ import annotations
from dataclasses import dataclass

# ---- device + circuit constants (from SNN_PARAMETERS.md / Device_Optimization) ----
R_ON = 2.34e6          # ohm, programmed
R_OFF = 7.14e7         # ohm, erased
V_READ = 0.05          # V, drain read bias
T_READ = 100e-9        # s, per-read integration window (assumption)
G_REPR = (1.0 / R_ON * 1.0 / R_OFF) ** 0.5   # geometric-mean conductance (representative read)

C_MEM = 1e-12          # F, compact membrane cap (Stage-1 target)
V_SWING = 0.5          # V, membrane charge/discharge swing per event (assumption)

# network size (the kept LSNN: 3 in, 60 LIF + 40 ALIF, 4 out)
N_SYN = 3 * 100 + 100 * 100 + 100 * 4   # = 10700 synaptic weights
DIFFERENTIAL = True                      # config A: 2 FeFETs / weight
N_NEURON = 100
T_STEPS = 1116                           # delta-modulated beat window


@dataclass
class Ledger:
    n_syn: int
    n_devices: int
    syn_energy_J: float
    neuron_energy_J: float
    total_J: float
    total_cap_F: float


def budget(spikes_per_neuron: float = 6.0, read_fraction: float = 1.0) -> Ledger:
    """
    spikes_per_neuron: avg output spikes/neuron over the beat (firing_rate * window).
    read_fraction: fraction of (T_STEPS * N_SYN) synaptic reads actually performed
                   (1.0 = fully clocked crossbar; event-driven sparsity makes it lower).
    """
    n_dev = N_SYN * (2 if DIFFERENTIAL else 1)
    e_read = V_READ * V_READ * G_REPR * T_READ          # J per representative synaptic read
    n_reads = T_STEPS * N_SYN * read_fraction
    syn_E = n_reads * e_read

    e_event = 0.5 * C_MEM * V_SWING * V_SWING            # J per membrane event
    neuron_E = N_NEURON * spikes_per_neuron * e_event

    total_cap = N_NEURON * C_MEM                         # membrane caps only (FeFET is cap-free)
    return Ledger(N_SYN, n_dev, syn_E, neuron_E, syn_E + neuron_E, total_cap)


def old_design_compare() -> dict:
    """The prior 1.419 uF/neuron RC design, for the headline ratio."""
    c_old = 1.419e-6
    v_old = 2.0                                          # ~v_threshold swing
    e_event_old = 0.5 * c_old * v_old * v_old
    spikes = 6.0
    return {"cap_per_neuron_F": c_old,
            "total_cap_F": N_NEURON * c_old,
            "neuron_energy_J": N_NEURON * spikes * e_event_old}


def _fmt(x, u):  # human units
    for p, s in [(1e-12, "p"), (1e-9, "n"), (1e-6, "u"), (1e-3, "m"), (1, "")]:
        if abs(x) < p * 1000:
            return f"{x/p:.2f} {s}{u}"
    return f"{x:.2e} {u}"


def _selfcheck():
    L = budget()
    old = old_design_compare()
    # core FoM gates from 00 section 4.2
    assert L.total_cap_F < 1e-9, "G1: total cap must be sub-nF (pF/neuron)"
    assert L.total_J < 1e-8, "G2: energy must be nJ-class per beat"
    cap_gain = old["total_cap_F"] / L.total_cap_F
    e_gain = old["neuron_energy_J"] / L.neuron_energy_J
    assert cap_gain > 1e5 and e_gain > 1e5, "must beat old design by orders of magnitude"
    print("energy_ledger self-check OK")
    print(f"  devices: {L.n_devices} FeFETs ({L.n_syn} weights, differential={DIFFERENTIAL})")
    print(f"  synaptic E/beat : {_fmt(L.syn_energy_J,'J')}")
    print(f"  neuron   E/beat : {_fmt(L.neuron_energy_J,'J')}")
    print(f"  TOTAL    E/beat : {_fmt(L.total_J,'J')}   (gate: < 10 nJ)")
    print(f"  total cap       : {_fmt(L.total_cap_F,'F')} ({_fmt(C_MEM,'F')}/neuron)   (gate: < 1 nF)")
    print(f"  vs OLD 1.419uF design: cap {cap_gain:.0e}x smaller, neuron energy {e_gain:.0e}x lower")


if __name__ == "__main__":
    _selfcheck()
