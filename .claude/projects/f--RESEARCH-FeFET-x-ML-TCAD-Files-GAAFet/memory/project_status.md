---
name: Project status (as of 2026-05-03)
description: Current state of GAA-FeFET LIF neuron thesis. Phase 1B complete; Step 2 SNN v1 reached 90.18% on MIT-BIH 4-class. Phase 1C in progress.
type: project
---

**Phase 1A (TCAD device characterization):** DONE. simA/simB transient-readout protocol confirmed partial polarization switching, dVth_per_pulse ≈ 11.36 mV at Vpulse=2V (simB).

**Phase 1B (TCAD LIF demonstration):** DONE. simC v6 (Vpulse=5/6/7V, pw=100ns, Vreset=-5V) achieved fire at P9 (6V) with ratio 2.035×. Reset 77.2%. Plots in `Simulations/py_scripts/simC_v6_fig*.png`. Optimal point: 6V/100ns/-5V/τ_E=1µs.

**Step 2 (Python SNN, MIT-BIH ECG 4-class):** v1 reports 90.18% test accuracy (303/336), exceeds VO2 baseline (89.58%). **CRITICAL CAVEAT:** v1 is a *port* of the VO2-memristor LSNN code from Yin et al. NCOMMS 2023, with only R_h/R_s swapped to GAA-FeFET values. The CMOS adaptation params (κ, V_t, W/L, R_a, C_a), comparator setpoints (v_th=3.6V, v_h=1.5V), τ=11.11ms target, and the back-calculated external C_mem=1.419µF are **all inherited from the VO2 paper**, not derived from our device. So 90.18% rests on unverified assumptions that Phase 1C must validate.
- Architecture: VO2LSNN (Bellec et al. NeurIPS 2018) with 60 LIF + 40 ALIF, DelayedLinear layers, max_delay=10.
- Files: `main_ecg_6_polished.py` (150 epochs cosine LR), `main_ecg_7_resume.py` (2-epoch fine-tune at constant LR with regularizer off).
- Native polarization-switching variant `model_2.py` only reaches ~70% — BPTT struggles with bounded saturation, so the linear-RC abstraction is the working model.
- **Do not treat 90.18% as a defended GAA-FeFET claim.** It is a sanity check on a borrowed architecture.

**Phase 1C (TCAD remaining work — current):** Pending parameters needed for the paper:
1. tau_leak via tau_P > 0 simulation (CRITICAL — currently a placeholder in Step 2)
2. E_spike via transient power integration during fire (currently rough estimate 97 fJ)
3. Multi-cycle endurance — does the 22.8% residual P per cycle drift over many cycles?
4. C_gg (gate capacitance) via AC small-signal — needed to validate that the FeFET's intrinsic capacitance can support the chosen τ without an external 1.419µF.

**Why:** Reason (1)–(3) are listed in `Step_2_Circuit_Integration.md` §6 as pending. (4) was added because Step 2 v1 used an external C_mem of 1.419µF — this is unphysical for an actual single-FeFET LIF neuron (the whole point of the device is "no external capacitor"). Validating the intrinsic C_gg lets us either justify the external cap or rescale the model to native dynamics.

**How to apply:** When the user asks about next steps, default to Phase 1C deliverables; do not propose new device geometry sweeps until Phase 1C completes. When discussing the SNN, treat 90.18% as the established v1 baseline; further work must justify itself against that.
