# 03 — Stage-1 integration (minimal diff to the recovered base model)

The base architecture is recovered:
`…\Signal_Classific_Neuromorph\NCOMMS-23-03137-main\Physiological signal processing system\VO2-based decision-making stage\model.py`
(defines `LPFilter`, `DelayedLinear`, `LinearDualRecurrentContainer`, `LIFVO2`, `ALIFVO2`,
`VO2LSNN`). **Confirmed:** synaptic weights are ordinary `DelayedLinear`/`nn.Linear` params; the
device was only the neuron's leak resistor `Rh+Rs`. So Stage-1 = **move the FeFET into the
weights** + **shrink the caps**. Both are small diffs, no architecture rewrite.

## Step 0 — get it runnable
Copy `model.py` (and confirm `surrogate.py`, `utils.py`, `dataset.py`) into
`PYTHON_Modelling_Fefet_Codes/` (the folder has `model_2 (1).py` but no `model.py`). Point the
dataset path at your local `data_ecg` (the `up/`,`down/` `*_guiyi.csv`). Verify the FP baseline
trains before changing anything.

## Step 1 — shrink the capacitors (kills C2; the FoM proof)
In the neuron construction (e.g. `VO2LSNN.__init__` args, or a thin subclass), change:
```
Cmem = 200e-9  -> 1e-12        # 1 pF compact membrane
Rh+Rs ≈ 101.5e3 -> 5e9         # 5 GΩ subthreshold-CMOS leak  => tau = Cmem*(Rh+Rs) = 5 ms
Ca   = 7e-6    -> 1e-12        # ALIF adaptation cap to pF (don't leave a hidden µF!)
input_scaling  -> retune       # so v reaches v_threshold with the new (Rh+Rs); see param table in 02
Ra             -> retune       # so tau_va = Ca*Ra stays in the adaptation range
```
The RC neuron equation is unchanged — it *is* a valid compact CMOS LIF; only the component
values move. Leak is now honestly a subthreshold CMOS device, not the (non-volatile) FeFET (kills C3).

## Step 2 — put the FeFET in the weights (kills C1; makes the device load-bearing)
FeFET-ize the weights of `fc1`, the recurrent `hidden.rc`, and `fc2`. Minimal diff using the
helper in `code/fefet_synapse.py` — transform the latent weight in `forward`, keep the Parameter
and the delay machinery intact:
```python
from fefet_synapse import log_levels, fefet_signed_map
# once: g_min, g_max = 1/71.4e6, 1/2.34e6 ; levels = log_levels(g_min, g_max, 15)

# inside DelayedLinear.forward (and fc2's forward), replace use of self.weight with:
w_dev = fefet_signed_map(self.weight, self.levels, self.g_min, self.g_max)
# ...then use w_dev exactly where self.weight was used.
```
The trainable parameter stays the **unbounded latent**; the 15-level device map is forward-only
via STE → gradients never die (the 76% fix, R3 §1). `differential` G⁺−G⁻ is implicit in the
signed map.

## Step 3 — evaluation (kills H1)
Replace accuracy-only eval with `code/metrics.py::ecg_report` and print `format_report`. Run
**two eval passes** each epoch/at best:
1. **FP latent** (comment out the `fefet_signed_map` call, or pass-through) — the upper bound.
2. **15-level device** (the helper active) — the real-device number.
Report the (1)→(2) gap; it is the Stage-1 device-faithfulness result. Then move the split to
**inter-patient DS1/DS2** (Stage 1.5) before any claim.

## Step 4 — budgets (the FoM headline)
Run `code/energy_ledger.py` (already parameterized for this net): **~306 pJ/beat, 1 pF/neuron**,
~10⁶× less cap and ~10⁷× less neuron energy than the old µF design. Update `spikes_per_neuron`
and `read_fraction` with the measured firing rate / event-driven sparsity from a real run.

## Step 5 — load-bearing ablation (G6)
Re-run Step 2 with `levels = log_levels(g_min, g_max, 2)` (binary) or a clamped 2× range. A
material macro-F1 drop vs the full 4-decade synapse = the device matters = C1 answered.

## What is NOT in Stage 1 (deferred to Stage 2, per the agreed scope)
C2C/D2D/read-noise injection, retention-drift + temperature sweeps, program-and-verify write
model, KD, calibration/ECE. All specced in `02_PLAN.md` Stage 2 and `research/R3`.

## Files
- `code/fefet_synapse.py` — log-domain 15-level STE synapse (`fefet_signed_map`, `FeFETSynapse`).
- `code/metrics.py` — macro-F1 / Se / +P / κ / confusion.
- `code/energy_ledger.py` — cap + energy/beat budget.
All three run standalone (`python <file>.py`) with self-checks — verified passing.
