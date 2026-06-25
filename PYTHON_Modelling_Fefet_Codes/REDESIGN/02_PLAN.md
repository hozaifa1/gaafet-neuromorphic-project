# 02 — The plan (staged)

Build order, parameters, calculations, iteration loop. Reads on top of `00` (why) and `01`
(what config). Backed by `research/R1_sota_ecg_snn.md`, `R2_fefet_circuits.md`,
`R3_hw_aware_training.md`.

**Guiding decision (per your steer):** prove the *main FoMs work* with the simplest fully-credible
real-device baseline FIRST. Add the fancy robustness machinery only after Stage 1 is green.

---

## STAGE 1 — Simple, credible, real-device baseline (prove the FoMs)

**Goal:** show that an SNN built from the *real* device (15-level non-volatile FeFET synapse +
compact pF-cap CMOS LIF) classifies ECG at a credible accuracy/macro-F1 **while** meeting the
capacitance + energy + CMOS + latency gates and being device-load-bearing. No noise/temperature
injection yet.

### 1.1 Config
**Config A** from `01` (differential FeFET synapse + compact CMOS LIF), LSNN topology kept.

### 1.2 Synapse model (the device, in the forward graph)
- Latent real weight `w ∈ ℝ` → log-domain map to one of **15 conductance levels** spanning the
  measured LTP range (`ltp_potentiation.csv`, ~4 decades) → **STE** backward (R3 §1.1).
- Differential `ΔG = G⁺ − G⁻` for signed weights.
- **Stage-1 simplification (ponytail):** quantize only — **no** C2C/D2D/drift/T noise. The single
  device non-ideality we admit now is the **15-level discreteness + finite range**. That alone is
  the minimum that makes the number "real-device".

### 1.3 Neuron model (compact CMOS LIF)
- Membrane: `C_mem = 1 pF`, leak `G_leak = C_mem/τ_mem` (subthreshold transistor), `τ_mem ≈ 5 ms`
  → `G_leak ≈ 0.2 nS` (5 GΩ). Leak is **CMOS, not the FeFET** (device is non-volatile).
- Keep the ALIF adaptation sub-circuit (it helped on this task) but **re-derive its caps to pF** —
  the old `C_a = 5.56 µF` is the same C2 disease; replace with a pF-scale or clocked equivalent.
- Surrogate: **wide→narrow width anneal** over epochs (R3 §1.2) to keep gradient alive.

### 1.4 Training (ex-situ, simple)
- BPTT + surrogate (SpikingJelly), **Adam**, grad-norm clip.
- Loss: **class-balanced focal loss** (γ≈2) over N/S/V/F (R3 §5) — fixes imbalance without KD.
- **No knowledge distillation** in Stage 1 (it broke the prior run; only revisit in Stage 2 with
  the FP-SNN-teacher + SAMD/NLD recipe if needed).
- Light spike-rate regularizer for the sparsity/energy claim.

### 1.5 Evaluation (report these every run — fixes H1)
- **macro-F1** (primary), accuracy, **Cohen's κ**, **per-class Se/+P (AAMI)**, confusion matrix.
- Two eval passes: **(i) FP latent** and **(ii) 15-level quantized device**. The (i)→(ii) gap is
  the Stage-1 device-faithfulness result.
- Start on the existing 4-class split to get running fast; **add inter-patient DS1/DS2 before any
  claim** (Stage 1.5 below).

### 1.6 Budgets to compute and report (the FoM proof — fixes C2/M1)
- **Capacitor:** total C across the net (target: pF/neuron, ≪ the old 142 µF).
- **Energy/inference ledger** (`energy_ledger.py`): synaptic reads (V_read·I·t, sub-fJ each) +
  neuron events (½C_mem·ΔV², 10–50 fJ each) + readout. Target **≤ nJ/beat**.
- **Latency:** integration window vs one beat (~0.6–1 s) — must classify within it.

### 1.7 Device-load-bearing ablation (fixes C1, cheap)
Re-run Stage 1 with the synapse **clamped to binary / 2× range** instead of the full 4 decades.
If macro-F1 drops materially → the device's dynamic range is load-bearing → C1 answered.

### 1.8 Stage-1 success criteria (gates from `00 §4.2`)
- macro-F1 within a few points of the FP baseline after 15-level quantization.
- C_mem ≤ few pF/neuron; energy ≤ nJ/beat; latency < one beat. ← the "main FoMs work" check.
- Ablation shows the device matters.
> Hitting these = the paper's backbone exists. Then, and only then, Stage 2.

### 1.9 Stage 1.5 — credibility bridge (do before writing claims)
Swap the data split to **inter-patient AAMI DS1/DS2** (R1: the #1 reviewer requirement). Re-report
1.5 metrics. Expect lower numbers than intra-patient; that is the *honest* baseline to beat.
Target (R1): **acc ≥ 97%, macro-F1 ≥ 0.88, SVEB-F1 ≥ 0.80, κ ≥ 0.85** — aspirational ceiling;
Stage 1 just needs to be credible and improving toward it.

---

## STAGE 2 — Robustness + faithfulness (the "fancy" layer, deferred)
Only after Stage 1 is green. Each item is additive; keep the Stage-1 eval table and watch the
degradation stay small (R3 §2 — that monotone-small drop *is* the result).
1. **Noise-aware training:** inject **C2C** (resampled), **D2D** (frozen), read noise in forward
   (AIHWKit-style hooks). Report ideal → +quant → +C2C/D2D delta.
2. **Retention drift + temperature (250–325 K)** sampled in forward (R3 §2).
3. **Program-and-verify** write model (amplitude-set, Baigol 2026) for the deployment claim.
4. **Optional KD** done right: FP-SNN teacher (same modality), SAMD + noise-smoothed logits,
   α ≤ 0.5 under focal CE (R3 §4) — only if it adds macro-F1.
5. **Calibration:** temperature scaling / ECE on held-out patients.
6. **Variation Monte Carlo** + robustness curve (accuracy vs injected σ).

---

## Parameters / hyperparameters to tune (and where)
**Device-mapping (from CSVs — fixed, not tuned):** 15 level conductances, G_min/G_max, V_read,
program pulse. **Tunable:**

| Group | Param | Stage-1 start | Search range | Notes |
|---|---|---|---|---|
| Neuron | `C_mem` | 1 pF | 0.5–2 pF | G1 budget |
| Neuron | `τ_mem` | 5 ms | 2–15 ms | sets G_leak; match beat timescale |
| Neuron | `v_threshold` | tune | — | firing-rate target |
| Synapse | latent→G map slope | log-domain | — | keep log; don't linearize (R3 §1.1) |
| Train | LR (Adam) | 1e-3 | 1e-4–3e-3 | cosine anneal |
| Train | focal γ | 2 | 1–3 | imbalance |
| Train | surrogate width schedule | wide→narrow | — | the 76% fix |
| Train | spike-reg λ | small | 1e-8–1e-6 | sparsity/energy |
| Arch | `num_lif/num_alif` | 60/40 | keep first | only retune if needed |
| Arch | `max_delay` | 10 | 5–20 | temporal features |

## Iteration loop (per your point 9 — optimize params via runs, not up front)
1. Implement Config A modules (`02 §1.2–1.3`), wire into the LSNN.
2. Train FP latent → confirm it learns (macro-F1 climbing). If gradients stall → widen surrogate /
   check log-domain map (R3 §1).
3. Turn on 15-level STE quantization → measure the (i)→(ii) gap.
4. Compute budgets (cap/energy/latency) → confirm gates.
5. Run the load-bearing ablation.
6. Move to inter-patient split (1.5). Tune the table above to recover macro-F1.
7. Freeze Stage-1 result → start Stage 2 additively.

## Risks / watch-items
- **Inter-patient drop** (R1): expect it; it's the honest number. Don't panic-tune back to
  intra-patient.
- **STE instability** if the log-map is mis-scaled → keep latent unbounded, map in forward only.
- **ALIF caps** — make sure the µF→pF fix is applied to `C_a` too, not just `C_mem` (silent C2 leak).
- **Missing `model.py`** — the existing folder imports `model.py` (LPFilter/DelayedLinear/
  LinearDualRecurrentContainer) but it is **not present**. Recover it from the original VO₂ repo
  or reimplement these three primitives before anything runs. Starter modules in `code/` are
  self-contained where possible and flag this dependency.

## Deliverables produced here
- `00_CRITICAL_REVIEW_AND_FACTORS.md`, `01_CONFIG_MENU.md`, this plan.
- `research/R1..R3*.md` (literature, with citations).
- Starter code in `REDESIGN/code/` (Stage-1 synapse, neuron, metrics, energy ledger) — next.
