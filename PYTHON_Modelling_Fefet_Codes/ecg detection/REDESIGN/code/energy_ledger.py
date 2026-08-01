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

# ---- device + circuit constants (from gaafefet_params_optimized.py / Device_Optimization) ----
# Corrected 2026-07-31 for the single width convention (Device_Optimization/norm.py,
# W_eff = 90 nm gate perimeter).  Corrected again 2026-08-01: R_OFF was 1.129e8, which
# divided t8_ltp's pulse-9 read by *mwfine's* baseline -- two nodes, two post-write
# settling times.  Both ends now come from t8_ltp alone (LIF.R_off_estimate /
# LIF.R_on_estimate), so the read window is 18.4x, not the published 30.6x.
R_ON = 3.680e6         # ohm, programmed (V_DS / ID_p9,           ID = 1.359e-8 A)
R_OFF = 6.767e7        # ohm, erased     (V_DS / ID_baseline_ltp, ID = 7.389e-10 A)
V_READ = 0.05          # V, drain read bias
T_READ = 100e-9        # s, per-read integration window (assumption)
G_REPR = (1.0 / R_ON * 1.0 / R_OFF) ** 0.5   # geometric-mean conductance (representative read)

# Write (programming) energy per +2 V / 0.3 us gate pulse, measured on the optimized
# device: PENDING.E_spike in gaafefet_params_optimized.py.  0.0089 fJ, not the 0.014 fJ
# published before the Areafactor correction.
E_WRITE_PULSE = 8.87e-18   # J per program pulse
N_WRITE_PULSES = 15        # pulses to place a weight on the top level (worst case)

C_MEM = 1e-12          # F, compact membrane cap (Stage-1 target)
V_SWING = 0.5          # V, membrane charge/discharge swing per event (assumption)

# Network size. CORRECTED 2026-08-01: this used to read 3*100 + 100*100 + 100*4 = 10700,
# which was wrong twice over. The kept LSNN is 3 in, 100 LIF + 60 ALIF (= 160 recurrent
# neurons, not 100), 4 out -- and BOTH the input and the recurrent layer are DelayedLinear
# with max_delay = 10, so each connection is 10 independently programmed taps. The true
# weight count is 24x larger, verified against model.named_parameters() in fig_k4_energy.py:
#   fc1        (160, 3, 10)   =   4 800
#   hidden.rc  (160, 160, 10) = 256 000
#   fc2        (4, 160)       =     640
N_LIF, N_ALIF, N_IN, N_OUT, MAX_DELAY = 100, 60, 3, 4, 10
N_NEURON = N_LIF + N_ALIF                            # 160
N_SYN = (N_IN * N_NEURON + N_NEURON * N_NEURON) * MAX_DELAY + N_NEURON * N_OUT   # 261 440
DIFFERENTIAL = True                      # config A: 2 FeFETs / weight
T_STEPS = 1116                           # delta-modulated beat window


# ---- peripheral (stated assumption, not measured here) ----
# One current-mode ADC conversion per crossbar column per timestep. 1 pJ/conversion is a
# mid-range value for an 8-bit SAR ADC in a scaled CMOS node; it is an ASSUMPTION and the
# point of reporting it is that it dominates, not that it is exact.
E_ADC_CONV = 1e-12     # J per conversion
N_COLUMNS = N_NEURON + N_OUT   # 164: fc1 and the recurrent array sum in the analog domain
                               # into the same 160 dendritic columns, plus the 4 readouts.


@dataclass
class Ledger:
    n_syn: int
    n_devices: int
    syn_energy_J: float
    neuron_energy_J: float
    total_J: float
    total_cap_F: float
    peripheral_energy_J: float = 0.0
    write_energy_J: float = 0.0


def budget(spikes_per_neuron: float = 6.0, read_fraction: float = 1.0,
           t_steps: int = T_STEPS, e_adc: float = E_ADC_CONV) -> Ledger:
    """
    spikes_per_neuron: avg output spikes/neuron over the beat (firing_rate * window).
    read_fraction: fraction of (t_steps * N_SYN) synaptic reads actually performed
                   (1.0 = fully clocked crossbar; event-driven sparsity makes it lower).
    """
    n_dev = N_SYN * (2 if DIFFERENTIAL else 1)
    e_read = V_READ * V_READ * G_REPR * T_READ          # J per representative synaptic read
    n_reads = t_steps * N_SYN * read_fraction
    syn_E = n_reads * e_read

    e_event = 0.5 * C_MEM * V_SWING * V_SWING            # J per membrane event
    neuron_E = N_NEURON * spikes_per_neuron * e_event

    periph_E = t_steps * N_COLUMNS * e_adc
    write_E = n_dev * N_WRITE_PULSES * E_WRITE_PULSE     # one-time deployment, amortized

    total_cap = N_NEURON * C_MEM                         # membrane caps only (FeFET is cap-free)
    return Ledger(N_SYN, n_dev, syn_E, neuron_E, syn_E + neuron_E, total_cap,
                  peripheral_energy_J=periph_E, write_energy_J=write_E)


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
    print(f"  peripheral (ADC): {_fmt(L.peripheral_energy_J,'J')}  [assumption: "
          f"{_fmt(E_ADC_CONV,'J')}/conv x {N_COLUMNS} cols x {T_STEPS} steps]")
    print(f"  one-time write  : {_fmt(L.write_energy_J,'J')} for all {L.n_devices} devices "
          f"({E_WRITE_PULSE*1e15:.4f} fJ/pulse x {N_WRITE_PULSES})")
    assert L.write_energy_J / L.total_J < 1.0, "write should amortize below one inference"


if __name__ == "__main__":
    _selfcheck()
